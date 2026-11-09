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
    Dịch vụ tải stream âm thanh từ YouTube / SoundCloud bằng yt-dlp,
    chuyển đổi audio và gắn metadata + album cover art qua mutagen.
    """

    def __init__(self, download_dir: str = "./downloads"):
        self.download_dir = download_dir
        os.makedirs(self.download_dir, exist_ok=True)
        self.has_ffmpeg = shutil.which("ffmpeg") is not None

    def search_and_download(self, search_query: str, metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Tìm kiếm video khớp nhất và tải âm thanh về thư mục downloads.
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
            # Fallback nếu máy chưa cài ffmpeg: tải định dạng m4a / webm trực tiếp
            ydl_opts["format"] = "bestaudio[ext=m4a]/bestaudio/best"
            expected_ext = None  # Sẽ kiểm tra sau khi tải

        print(f"[Downloader] Đang tìm kiếm và tải nguồn nhạc: {search_query}...")
        with YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(f"ytsearch1:{search_query}", download=True)
            if not info or "entries" not in info or len(info["entries"]) == 0:
                raise RuntimeError(f"Không tìm thấy kết quả tải cho: {search_query}")
            
            video_info = info["entries"][0]
            downloaded_file = ydl.prepare_filename(video_info)

        # Xác định file thực tế tạo ra
        final_file_path = None
        if self.has_ffmpeg:
            # Tên file sau khi ffmpeg convert thành mp3
            base, _ = os.path.splitext(downloaded_file)
            final_file_path = f"{base}.mp3"
        else:
            final_file_path = downloaded_file

        if not os.path.exists(final_file_path):
            # Thử tìm file tương ứng trong folder
            base_name = os.path.basename(target_template).split(".")[0]
            for f in os.listdir(self.download_dir):
                if f.startswith(base_name):
                    final_file_path = os.path.join(self.download_dir, f)
                    break

        if not final_file_path or not os.path.exists(final_file_path):
            raise FileNotFoundError(f"File sau khi tải không tồn tại: {final_file_path}")

        # Gắn thẻ metadata nếu có
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
        Nhúng ID3 tags và Album Art vào file (hỗ trợ MP3 và MP4/M4A).
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
                print(f"[Downloader] Không thể tải ảnh bìa: {e}")

        if ext == ".mp3":
            try:
                # Cập nhật thông tin cơ bản
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

                # Gắn ảnh bìa
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
                print(f"[Downloader] Đã gắn ID3 tag và Cover Art vào {file_path}")
            except Exception as e:
                print(f"[Downloader] Lỗi gắn tag MP3: {e}")

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
                print(f"[Downloader] Đã gắn MP4 tag và Cover Art vào {file_path}")
            except Exception as e:
                print(f"[Downloader] Lỗi gắn tag M4A: {e}")
