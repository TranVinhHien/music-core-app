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
    Audio stream downloading service via yt-dlp,
    transcodes audio and embeds metadata + cover art via mutagen.
    """

    def __init__(self, download_dir: str = "./downloads"):
        self.download_dir = download_dir
        os.makedirs(self.download_dir, exist_ok=True)
        self.has_ffmpeg = shutil.which("ffmpeg") is not None

    def search_and_download(self, search_query: str, metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Searches best matching video and downloads audio stream to downloads directory.
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
            ydl_opts["format"] = "bestaudio/best"
            ydl_opts["postprocessors"] = [{
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": "320",
            }]
            expected_ext = "mp3"
        else:
            # Fallback if ffmpeg is not installed: download m4a / webm directly
            ydl_opts["format"] = "bestaudio[ext=m4a]/bestaudio/best"
            expected_ext = None

        print(f"[Downloader] Searching and downloading audio stream: {search_query}...")
        with YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(f"ytsearch1:{search_query}", download=True)
            if not info or "entries" not in info or len(info["entries"]) == 0:
                raise RuntimeError(f"No download results found for: {search_query}")
            
            video_info = info["entries"][0]
            downloaded_file = ydl.prepare_filename(video_info)

        # Resolve actual file created on disk
        final_file_path = None
        if self.has_ffmpeg:
            # File name after ffmpeg conversion to mp3
            base, _ = os.path.splitext(downloaded_file)
            final_file_path = f"{base}.mp3"
        else:
            final_file_path = downloaded_file

        if not os.path.exists(final_file_path):
            # Attempt to find matching file in folder
            base_name = os.path.basename(target_template).split(".")[0]
            for f in os.listdir(self.download_dir):
                if f.startswith(base_name):
                    final_file_path = os.path.join(self.download_dir, f)
                    break

        if not final_file_path or not os.path.exists(final_file_path):
            raise FileNotFoundError(f"Downloaded file not found: {final_file_path}")

        # Embed metadata if provided
        if metadata:
            self.tag_file(final_file_path, metadata)

        return {
            "success": True,
            "file_path": os.path.abspath(final_file_path),
            "file_name": os.path.basename(final_file_path),
            "file_size_mb": round(os.path.getsize(final_file_path) / (1024 * 1024), 2),
            "source_title": video_info.get("title"),
            "source_url": video_info.get("webpage_url"),
            "source_duration_s": video_info.get("duration"),
            "has_ffmpeg_used": self.has_ffmpeg
        }

    def tag_file(self, file_path: str, metadata: Dict[str, Any]):
        """
        Embeds ID3 tags and Album Art into file (supports MP3 and MP4/M4A).
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
                # Update basic tags
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

                # Attach cover art
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
                print(f"[Downloader] Embedded ID3 tag and Cover Art into {file_path}")
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
                print(f"[Downloader] Embedded MP4 tag and Cover Art into {file_path}")
            except Exception as e:
                print(f"[Downloader] Error tagging M4A: {e}")
