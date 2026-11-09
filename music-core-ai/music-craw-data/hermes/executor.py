import os
import time
from typing import Dict, Any, Optional
from rich.console import Console

from services.downloader_service import DownloaderService
from services.storage_service import StorageService
from services.catalog_service import CatalogService
from services.audio_analyzer_service import AudioAnalyzerService
from hermes.models import TrackExecutionResult

console = Console()

class HermesExecutor:
    """
    Hermes Executor:
    Coordinates the complete processing pipeline for each track:
    [Download Audio & Embed ID3 Tag] -> [Upload S3 Storage] -> [Register Catalog API multi-artist] -> [Extract Acoustics & Sync API].
    Integrates 3-tier fallback and retry strategies.
    """

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        
        storage_cfg = self.config.get("storage", {})
        download_dir = storage_cfg.get("download_dir", "./downloads")
        self.downloader = DownloaderService(download_dir=download_dir)
        self.storage = StorageService(self.config)

        backend_cfg = self.config.get("backend", {})
        catalog_url = backend_cfg.get("catalog_api_url", "http://localhost:3002/api/v1/catalog")
        self.catalog = CatalogService(base_url=catalog_url)
        self.audio_analyzer = AudioAnalyzerService()

    def process_track(self, track_meta: Dict[str, Any]) -> TrackExecutionResult:
        """
        Executes the 5-step pipeline for a track with 3 fallback search strategies.
        """
        title = track_meta.get("title", "")
        artist = track_meta.get("artist", "")
        album = track_meta.get("album", "")
        cover_url = track_meta.get("cover_url", "")
        release_date = track_meta.get("release_date", "")
        track_number = track_meta.get("track_number")
        disc_number = track_meta.get("disc_number")

        MAX_ATTEMPTS = 3
        last_exception = None

        for attempt in range(1, MAX_ATTEMPTS + 1):
            try:
                if attempt > 1:
                    console.print(f"[yellow]🔄 (Attempt {attempt}/{MAX_ATTEMPTS}) Switching search query strategy for: '{title}'...[/yellow]")

                # Step-by-step query fallback strategy
                if attempt == 1:
                    search_query = f"{title} {artist} Official Audio"
                elif attempt == 2:
                    clean_t = title.split("(")[0].split("-")[0].strip()
                    search_query = f"{clean_t} {artist}"
                else:
                    clean_t = title.split("(")[0].strip()
                    search_query = clean_t

                # Step 1: Download audio stream and embed ID3 tag + Cover Art
                dl_res = self.downloader.search_and_download(search_query, track_meta)
                local_file_path = dl_res["file_path"]

                # Step 2: Upload to S3 Storage (or local fallback)
                upload_res = self.storage.upload_file(local_file_path, folder="tracks")
                file_url = upload_res["url"]

                # Step 3: External source reference
                sources = [{
                    "source": "YOUTUBE",
                    "externalId": dl_res.get("source_url", "").split("v=")[-1] if "v=" in dl_res.get("source_url", "") else "stream",
                    "externalUrl": dl_res.get("source_url", "")
                }]

                # Accurate duration
                effective_duration_ms = (
                    dl_res.get("actual_duration_ms") or 
                    track_meta.get("duration_ms") or 
                    (int(dl_res.get("source_duration_s", 0) * 1000) if dl_res.get("source_duration_s") else 0)
                )

                # Step 4: Register with Catalog API via ArtistParser (PRIMARY / FEAT)
                catalog_res = self.catalog.register_track_full(
                    raw_title=title,
                    raw_artist=artist,
                    file_url=file_url,
                    album_title=album if attempt < 3 else None,
                    cover_image_url=cover_url,
                    duration_ms=effective_duration_ms,
                    release_date=release_date,
                    track_number=track_number,
                    disc_number=disc_number,
                    sources=sources
                )

                catalog_id = catalog_res.get("catalog_id")
                parsed_artists = catalog_res.get("parsed_artists", [])

                # Step 5: Extract acoustic features (BPM, Key, Camelot, Cues, LUFS) & Sync API
                audio_analysis_result = None
                if catalog_id and os.path.exists(local_file_path):
                    try:
                        console.print(f"[dim]🎵 Extracting acoustic features for '{title}'...[/dim]")
                        analysis = self.audio_analyzer.analyze_audio(local_file_path, track_id=catalog_id)
                        analysis_payload = analysis["payload"]
                        audio_analysis_result = analysis["summary"]

                        update_res = self.catalog.update_audio_analysis(catalog_id, analysis_payload)
                        if update_res.get("success"):
                            console.print(
                                f"[green]✓ Acoustics: BPM={audio_analysis_result['bpm']} | "
                                f"Key={audio_analysis_result['camelot']} ({audio_analysis_result['key_scale']}) | "
                                f"LUFS={audio_analysis_result['lufs']}[/green]"
                            )
                        else:
                            console.print(f"[yellow]⚠️ Error syncing Audio Analysis to API: {update_res.get('error')}[/yellow]")
                    except Exception as ae:
                        console.print(f"[yellow]⚠️ Acoustic analysis error for '{title}': {ae}[/yellow]")
                        try:
                            fail_payload = self.audio_analyzer.build_failed_payload(
                                duration_ms=effective_duration_ms,
                                error_message=str(ae)
                            )
                            self.catalog.update_audio_analysis(catalog_id, fail_payload)
                        except Exception:
                            pass

                return TrackExecutionResult(
                    title=title,
                    artist=artist,
                    album=album,
                    file_url=file_url,
                    catalog_id=catalog_id,
                    parsed_artists=parsed_artists,
                    audio_analysis=audio_analysis_result,
                    size_mb=dl_res.get("file_size_mb"),
                    attempts_used=attempt,
                    success=True
                )

            except Exception as e:
                last_exception = e
                console.print(f"[dim yellow]⚠️ Strategy {attempt} failed: {e}[/dim yellow]")
                time.sleep(1)

        console.print(f"[red]✗ Failed after 3 attempts for: '{title}' ({last_exception})[/red]")
        return TrackExecutionResult(
            title=title,
            artist=artist,
            album=album,
            attempts_used=MAX_ATTEMPTS,
            success=False,
            error_message=str(last_exception)
        )

