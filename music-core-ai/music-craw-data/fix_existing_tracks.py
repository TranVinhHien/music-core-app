#!/usr/bin/env python3
"""
Batch correction script for previously downloaded tracks with timescale/duration issues (2x / 3x).
Workflow:
1. Scan .m4a files in downloads/ directory.
2. Transcode to standard MP3 320kbps via FFmpeg (fixes timescale/metadata issues).
3. Read ID3 metadata and Cover Art, then tag new MP3 file.
4. Upload MP3 to S3 and update fileUrl + durationMs in Catalog API.
"""

import os
import subprocess
import requests
import yaml
from mutagen.mp4 import MP4
from mutagen.mp3 import MP3
from mutagen.easyid3 import EasyID3
from mutagen.id3 import ID3, APIC
from rich.console import Console
from rich.table import Table

from services.downloader_service import DownloaderService
from services.storage_service import StorageService

console = Console()

def load_config():
    with open("config.yaml", "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def fix_tracks():
    config = load_config()
    storage = StorageService(config)
    downloader = DownloaderService("downloads")
    ffmpeg_exe = downloader.ffmpeg_path
    catalog_base_url = config.get("backend", {}).get("catalog_api_url", "http://localhost:3002/api/v1/catalog").rstrip("/")

    if not ffmpeg_exe:
        console.print("[red]✗ Không tìm thấy FFmpeg để sửa file![/red]")
        return

    console.print(f"[bold cyan]🔧 Bắt đầu sửa lỗi thời lượng audio bằng FFmpeg ({ffmpeg_exe})...[/bold cyan]\n")

    # Fetch catalog track list for mapping
    catalog_tracks = []
    try:
        resp = requests.get(f"{catalog_base_url}/tracks", params={"limit": 100}, timeout=10)
        if resp.status_code == 200:
            catalog_tracks = resp.json().get("data", {}).get("items", [])
    except Exception as e:
        console.print(f"[yellow]⚠️ Failed to fetch tracks from Catalog API: {e}[/yellow]")

    downloads_dir = "downloads"
    m4a_files = [f for f in os.listdir(downloads_dir) if f.endswith(".m4a")]

    if not m4a_files:
        console.print("[yellow]No .m4a files found in downloads/ to fix.[/yellow]")
        return

    console.print(f"Found [bold green]{len(m4a_files)}[/bold green] .m4a files to normalize.\n")

    table = Table(title="Normalized Tracks Duration", title_style="bold green")
    table.add_column("#", width=4)
    table.add_column("Original Filename", style="dim")
    table.add_column("Old Duration", style="yellow")
    table.add_column("Normalized Duration", style="green")
    table.add_column("Catalog Status", style="cyan")

    for idx, fname in enumerate(m4a_files, 1):
        in_path = os.path.join(downloads_dir, fname)
        base_name = os.path.splitext(fname)[0]
        out_mp3_path = os.path.join(downloads_dir, f"{base_name}.mp3")

        try:
            # 1. Read legacy metadata from m4a
            mp4_audio = MP4(in_path)
            old_dur_sec = mp4_audio.info.length
            title = mp4_audio.get("\xa9nam", [base_name])[0]
            artist = mp4_audio.get("\xa9ART", [""])[0]
            album = mp4_audio.get("\xa9alb", [""])[0]
            cover_data = None
            if "covr" in mp4_audio and len(mp4_audio["covr"]) > 0:
                cover_data = bytes(mp4_audio["covr"][0])

            # 2. Transcode to MP3 320kbps via FFmpeg (resolves timescale defect)
            cmd = [
                ffmpeg_exe, "-y",
                "-i", in_path,
                "-vn",
                "-ar", "44100",
                "-ac", "2",
                "-b:a", "320k",
                out_mp3_path
            ]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

            # 3. Write ID3 tags into normalized MP3
            try:
                audio = EasyID3(out_mp3_path)
            except Exception:
                audio = EasyID3()
                audio.save(out_mp3_path)
                audio = EasyID3(out_mp3_path)

            if title: audio["title"] = title
            if artist: audio["artist"] = artist
            if album: audio["album"] = album
            audio.save()

            if cover_data:
                id3 = ID3(out_mp3_path)
                id3.add(APIC(encoding=3, mime="image/jpeg", type=3, desc="Cover", data=cover_data))
                id3.save()

            # 4. Measure accurate duration of the new MP3
            mp3_audio = MP3(out_mp3_path)
            new_dur_sec = mp3_audio.info.length
            new_dur_ms = int(new_dur_sec * 1000)

            # 5. Upload new MP3 to S3
            up_res = storage.upload_file(out_mp3_path, folder="tracks")
            new_file_url = up_res["url"]

            # 6. Update Catalog API if matching track found
            cat_status = "ID Mismatch"
            for t in catalog_tracks:
                if t.get("title", "").strip().lower() == title.strip().lower() or fname in t.get("fileUrl", ""):
                    track_id = t.get("id")
                    patch_resp = requests.put(
                        f"{catalog_base_url}/tracks/{track_id}",
                        headers={"Content-Type": "application/json", "X-User-Roles": "admin"},
                        json={
                            "fileUrl": new_file_url,
                            "durationMs": new_dur_ms
                        },
                        timeout=5
                    )
                    if patch_resp.status_code in [200, 204]:
                        cat_status = f"✓ Đã cập nhật ({track_id[:8]}...)"
                    else:
                        cat_status = f"Lỗi {patch_resp.status_code}"
                    break

            old_str = f"{int(old_dur_sec//60)}m{int(old_dur_sec%60):02d}s"
            new_str = f"{int(new_dur_sec//60)}m{int(new_dur_sec%60):02d}s"
            table.add_row(str(idx), fname[:35] + "...", old_str, new_str, cat_status)

        except Exception as e:
            table.add_row(str(idx), fname[:35] + "...", "Lỗi", str(e)[:20], "Thất bại")

    console.print(table)
    console.print("\n[bold green]✓ Đã hoàn tất sửa chữa và chuẩn hóa toàn bộ file âm thanh![/bold green]")

if __name__ == "__main__":
    fix_tracks()
