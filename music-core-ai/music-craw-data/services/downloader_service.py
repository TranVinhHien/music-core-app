import os
import shutil
import requests
from typing import Dict, Any, Optional
from yt_dlp import YoutubeDL
from mutagen.easyid3 import EasyID3
from mutagen.id3 import ID3, APIC, TIT2, TPE1, TALB, TCON, TDRC
from mutagen.mp4 import MP4, MP4Cover

class DownloaderService:
    """
    Downloads audio streams from YouTube / SoundCloud using yt-dlp,
    transcodes audio to 320kbps MP3 (normalizing timescales to prevent duration defects),
    and embeds metadata plus album cover art via mutagen.
    """

    def __init__(self, download_dir: str = "./downloads"):
        self.download_dir = download_dir
        os.makedirs(self.download_dir, exist_ok=True)
        self.ffmpeg_path = self._find_ffmpeg()
        self.has_ffmpeg = self.ffmpeg_path is not None
        if self.has_ffmpeg:
            print(f"[Downloader] ✓ Found FFmpeg at: {self.ffmpeg_path}")
        else:
            print("[Downloader] ⚠️ WARNING: FFmpeg not found. YouTube DASH streams may exhibit duration anomalies!")

    def _find_ffmpeg(self) -> Optional[str]:
        """
        Discovers FFmpeg across candidate locations:
        1. System PATH
        2. macOS Homebrew (/opt/homebrew/bin/ffmpeg, /usr/local/bin/ffmpeg)
        3. imageio-ffmpeg bundle
        """
        sys_ffmpeg = shutil.which("ffmpeg")
        if sys_ffmpeg:
            return sys_ffmpeg

        for p in ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"]:
            if os.path.exists(p) and os.access(p, os.X_OK):
                return p

        try:
            import imageio_ffmpeg
            exe = imageio_ffmpeg.get_ffmpeg_exe()
            if exe and os.path.exists(exe):
                return exe
        except Exception:
            pass

        return None

    def search_and_download(self, search_query: str, metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Searches for best matching audio and downloads to destination directory.
        Automatically converts to standard 320kbps MP3 to avoid timeline/duration defects.
        """
        clean_title = metadata.get("title", search_query) if metadata else search_query
        clean_artist = metadata.get("artist", "") if metadata else ""
        
        safe_name = f"{clean_artist} - {clean_title}".strip(" -").replace("/", "_").replace("\\", "_")
        target_template = os.path.join(self.download_dir, f"{safe_name}.%(ext)s")

        ydl_opts: Dict[str, Any] = {
            "default_search": "ytsearch1",
            "noplaylist": True,
            "quiet": True,
            "no_warnings": True,
            "outtmpl": target_template,
        }

        if self.has_ffmpeg:
            ydl_opts["ffmpeg_location"] = self.ffmpeg_path
            ydl_opts["format"] = "bestaudio/best"
            ydl_opts["postprocessors"] = [{
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": "320",
            }]
            expected_ext = "mp3"
        else:
            ydl_opts["format"] = "bestaudio[ext=m4a]/bestaudio/best"
            expected_ext = None

        # 3 distinct search strategies if errors or no results
        strategies = [
            f"ytsearch1:{clean_title} {clean_artist} Official Audio",
            f"ytsearch1:{clean_title} {clean_artist}",
            f"ytsearch1:{clean_title}"
        ]

        last_error = None
        info = None
        video_info = None
        downloaded_file = None

        for attempt, query_str in enumerate(strategies, 1):
            try:
                print(f"[Downloader] (Strategy {attempt}/3) Searching audio source: '{query_str}'...")
                with YoutubeDL(ydl_opts) as ydl:
                    info = ydl.extract_info(query_str, download=True)
                    if info and "entries" in info and len(info["entries"]) > 0:
                        video_info = info["entries"][0]
                        downloaded_file = ydl.prepare_filename(video_info)
                        break
                    else:
                        raise RuntimeError(f"No results found for '{query_str}'")
            except Exception as e:
                last_error = e
                print(f"[Downloader] ⚠️ Strategy {attempt} failed: {e}. Switching strategy...")

        if not video_info or not downloaded_file:
            raise RuntimeError(f"All 3 search attempts failed for '{clean_title}'. Last error: {last_error}")

        # Resolve actual file path created on disk
        final_file_path = None
        if self.has_ffmpeg:
            # File name after ffmpeg conversion to mp3
            base, _ = os.path.splitext(downloaded_file)
            final_file_path = f"{base}.mp3"
        else:
            final_file_path = downloaded_file

        if not os.path.exists(final_file_path):
            base_name = os.path.basename(target_template).split(".")[0]
            for f in os.listdir(self.download_dir):
                if f.startswith(base_name):
                    final_file_path = os.path.join(self.download_dir, f)
                    break

        if not final_file_path or not os.path.exists(final_file_path):
            raise FileNotFoundError(f"Downloaded file not found: {final_file_path}")

        # Tag metadata if provided
        if metadata:
            self.tag_file(final_file_path, metadata)

        # Measure accurate duration from final audio file
        actual_duration_ms = None
        try:
            ext = os.path.splitext(final_file_path)[1].lower()
            if ext == ".mp3":
                from mutagen.mp3 import MP3
                actual_duration_ms = int(MP3(final_file_path).info.length * 1000)
            elif ext in [".m4a", ".mp4"]:
                from mutagen.mp4 import MP4
                actual_duration_ms = int(MP4(final_file_path).info.length * 1000)
        except Exception as e:
            print(f"[Downloader] Lỗi đọc duration file: {e}")

        return {
            "success": True,
            "file_path": os.path.abspath(final_file_path),
            "file_name": os.path.basename(final_file_path),
            "file_size_mb": round(os.path.getsize(final_file_path) / (1024 * 1024), 2),
            "source_title": video_info.get("title"),
            "source_url": video_info.get("webpage_url"),
            "source_duration_s": video_info.get("duration"),
            "actual_duration_ms": actual_duration_ms,
            "has_ffmpeg_used": self.has_ffmpeg
        }

    def tag_file(self, file_path: str, metadata: Dict[str, Any]):
        """
        Embeds ID3 tags and Album Art into audio file (supports MP3 and MP4/M4A).
        """
        ext = os.path.splitext(file_path)[1].lower()
        title = metadata.get("title", "")
        artist = metadata.get("artist", "")
        album = metadata.get("album", "")
        genre = metadata.get("genre", "")
        year = str(metadata.get("year", ""))
        cover_url = metadata.get("cover_url")

        cover_bytes = None
        if cover_url:
            try:
                c_resp = requests.get(cover_url, timeout=10)
                if c_resp.status_code == 200:
                    cover_bytes = c_resp.content
            except Exception as e:
                print(f"[Downloader] Failed to download cover art: {e}")

        if ext == ".mp3":
            try:
                try:
                    audio = EasyID3(file_path)
                except Exception:
                    audio = EasyID3()
                    audio.save(file_path)
                    audio = EasyID3(file_path)

                if title: audio["title"] = title
                if artist: audio["artist"] = artist
                if album: audio["album"] = album
                if genre: audio["genre"] = genre
                if year: audio["date"] = year
                audio.save()

                if cover_bytes:
                    id3 = ID3(file_path)
                    id3.add(APIC(
                        encoding=3,
                        mime="image/jpeg",
                        type=3,  # Cover (front)
                        desc="Cover",
                        data=cover_bytes
                    ))
                    id3.save()
                print(f"[Downloader] ✓ Embedded ID3 tag and Cover Art into {file_path}")
            except Exception as e:
                print(f"[Downloader] Error tagging MP3: {e}")

        elif ext in [".m4a", ".mp4"]:
            try:
                mp4 = MP4(file_path)
                if title: mp4["\xa9nam"] = [title]
                if artist: mp4["\xa9ART"] = [artist]
                if album: mp4["\xa9alb"] = [album]
                if genre: mp4["\xa9gen"] = [genre]
                if year: mp4["\xa9day"] = [year]

                if cover_bytes:
                    mp4["covr"] = [MP4Cover(cover_bytes, imageformat=MP4Cover.FORMAT_JPEG)]
                mp4.save()
                print(f"[Downloader] ✓ Embedded MP4 tag and Cover Art into {file_path}")
            except Exception as e:
                print(f"[Downloader] Error tagging M4A: {e}")
