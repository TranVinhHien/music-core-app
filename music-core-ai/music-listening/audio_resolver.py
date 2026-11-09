import os
import re
import tempfile
import urllib.parse
from typing import Optional, Tuple
import requests


DOWNLOADS_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../music-craw-data/downloads")
)
CACHE_DIR = os.path.join(tempfile.gettempdir(), "music_listening_cache")


def resolve_audio_file(file_url: Optional[str], track_title: Optional[str] = None) -> Tuple[str, bool]:
    """
    Resolve audio file path from fileUrl or track title.
    Returns: (file_path, is_temporary)
    If is_temporary is True, caller should delete file after analysis.
    """
    if not file_url:
        raise ValueError("file_url is empty")

    # 1. Direct local path check
    if os.path.isfile(file_url):
        return file_url, False

    # 2. Check in local downloads folder
    # URL decode filename
    parsed_path = urllib.parse.unquote(file_url)
    filename = os.path.basename(parsed_path).strip()

    # Strip hash prefix if present, e.g. "5446ddaa_Song Title.m4a" -> "Song Title.m4a"
    clean_name = re.sub(r"^[0-9a-fA-F]{8}_", "", filename)

    if os.path.isdir(DOWNLOADS_DIR):
        # Exact clean filename match
        candidate1 = os.path.join(DOWNLOADS_DIR, clean_name)
        if os.path.isfile(candidate1):
            return candidate1, False

        # Raw filename match
        candidate2 = os.path.join(DOWNLOADS_DIR, filename)
        if os.path.isfile(candidate2):
            return candidate2, False

        # Match by track title
        if track_title:
            normalized_title = track_title.lower().strip()
            for fname in os.listdir(DOWNLOADS_DIR):
                if normalized_title in fname.lower():
                    return os.path.join(DOWNLOADS_DIR, fname), False

    # 3. Remote URL download (S3, HTTP, HTTPS)
    if file_url.startswith("http://") or file_url.startswith("https://"):
        os.makedirs(CACHE_DIR, exist_ok=True)
        ext = os.path.splitext(filename)[1] or ".m4a"
        temp_dest = os.path.join(CACHE_DIR, f"track_dl_{os.getpid()}_{clean_name}")
        
        response = requests.get(file_url.strip(), stream=True, timeout=30)
        response.raise_for_status()
        with open(temp_dest, "wb") as f:
            for chunk in response.iter_content(chunk_size=65536):
                if chunk:
                    f.write(chunk)
        return temp_dest, True

    raise FileNotFoundError(f"Could not locate audio file for URL: {file_url}")
