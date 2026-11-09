#!/usr/bin/env python3
"""
Music Crawler & Catalog MCP Server.
Implements Model Context Protocol (MCP) standard over standard I/O (JSON-RPC 2.0).
Allows any AI Agent or IDE to invoke these tools directly.
"""

import sys
import json
import yaml
import os
from typing import Dict, Any

from services.metadata_service import MetadataService
from services.downloader_service import DownloaderService
from services.storage_service import StorageService
from services.catalog_service import CatalogService
from services.audio_analyzer_service import AudioAnalyzerService

def load_config():
    cfg_path = os.path.join(os.path.dirname(__file__), "config.yaml")
    if os.path.exists(cfg_path):
        with open(cfg_path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    return {}

config = load_config()
downloader = DownloaderService(download_dir=config.get("storage", {}).get("download_dir", "./downloads"))
storage = StorageService(config)
catalog = CatalogService(base_url=config.get("backend", {}).get("catalog_api_url", "http://localhost:3002/api/v1/catalog"))
audio_analyzer = AudioAnalyzerService()


TOOLS_SCHEMA = [
    {
        "name": "search_music_online",
        "description": "Searches for track / artist / album candidates online via iTunes and Deezer.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Song title or artist name."},
                "limit": {"type": "integer", "description": "Maximum number of results", "default": 5}
            },
            "required": ["query"]
        }
    },
    {
        "name": "get_album_tracks",
        "description": "Fetches complete tracklist for an album from iTunes/Deezer.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "album_name": {"type": "string", "description": "Album title."},
                "artist_name": {"type": "string", "description": "Primary artist name."}
            },
            "required": ["album_name"]
        }
    },
    {
        "name": "get_song_metadata",
        "description": "Fetches standard canonical metadata (Title, Artist, Album, Cover Art, Year, Duration).",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Song title and artist name."}
            },
            "required": ["query"]
        }
    },
    {
        "name": "download_and_tag_song",
        "description": "Downloads audio stream via yt-dlp and embeds ID3 tags + cover art.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "search_query": {"type": "string", "description": "Audio search query."},
                "metadata": {"type": "object", "description": "Track metadata details."}
            },
            "required": ["search_query", "metadata"]
        }
    },
    {
        "name": "upload_audio_to_storage",
        "description": "Uploads audio file to S3/Storage to obtain persistent URL.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "local_file_path": {"type": "string", "description": "Local audio file path."}
            },
            "required": ["local_file_path"]
        }
    },
    {
        "name": "register_track_to_catalog",
        "description": "Registers track with automated multi-artist parsing (PRIMARY & FEAT) and album in Catalog Microservice.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "title": {"type": "string", "description": "Track title."},
                "artist_name": {"type": "string", "description": "Artist string (supports &, feat, ft, etc.)."},
                "album_title": {"type": "string", "description": "Album title."},
                "file_url": {"type": "string", "description": "Audio asset URL."},
                "cover_image_url": {"type": "string", "description": "Cover art URL."},
                "duration_ms": {"type": "integer", "description": "Duration in milliseconds."}
            },
            "required": ["title", "artist_name", "file_url"]
        }
    },
    {
        "name": "pipeline_crawl_and_register",
        "description": "Executes full pipeline: Search -> Download & Tag -> Upload S3 -> Register Catalog API.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "song_title": {"type": "string", "description": "Track title."},
                "artist_name": {"type": "string", "description": "Artist name."}
            },
            "required": ["song_title"]
        }
    }
]

def handle_call_tool(name: str, arguments: Dict[str, Any]) -> Any:
    if name == "search_music_online":
        return MetadataService.search_candidates(arguments.get("query", ""), arguments.get("limit", 5))

    elif name == "get_album_tracks":
        return MetadataService.get_album_tracks(arguments.get("album_name", ""), arguments.get("artist_name", ""))

    elif name == "get_song_metadata":
        return MetadataService.get_metadata(arguments.get("query", ""))

    elif name == "download_and_tag_song":
        return downloader.search_and_download(arguments.get("search_query", ""), arguments.get("metadata", {}))

    elif name == "upload_audio_to_storage":
        return storage.upload_file(arguments.get("local_file_path", ""))

    elif name == "register_track_to_catalog":
        return catalog.register_track_full(
            raw_title=arguments.get("title", ""),
            raw_artist=arguments.get("artist_name", ""),
            file_url=arguments.get("file_url", ""),
            album_title=arguments.get("album_title"),
            cover_image_url=arguments.get("cover_image_url"),
            duration_ms=arguments.get("duration_ms")
        )

    elif name == "pipeline_crawl_and_register":
        song = arguments.get("song_title", "")
        artist = arguments.get("artist_name", "")
        query = f"{song} {artist}".strip()
        meta = MetadataService.get_metadata(query) or {
            "title": song,
            "artist": artist or "Unknown Artist",
            "album": "Single",
            "cover_url": "",
            "duration_ms": 0
        }
        dl = downloader.search_and_download(f"{meta['title']} {meta['artist']} Official Audio", meta)
        up = storage.upload_file(dl["file_path"], folder="tracks")
        
        sources = [{
            "source": "YOUTUBE",
            "externalId": dl.get("source_url", "").split("v=")[-1] if "v=" in dl.get("source_url", "") else "stream",
            "externalUrl": dl.get("source_url", "")
        }]

        cat = catalog.register_track_full(
            raw_title=meta["title"],
            raw_artist=meta["artist"],
            file_url=up["url"],
            album_title=meta.get("album"),
            cover_image_url=meta.get("cover_url"),
            duration_ms=dl.get("actual_duration_ms") or meta.get("duration_ms"),
            release_date=meta.get("release_date"),
            track_number=meta.get("track_number"),
            disc_number=meta.get("disc_number"),
            sources=sources
        )

        audio_analysis = None
        if cat.get("catalog_id") and os.path.exists(dl["file_path"]):
            try:
                analysis = audio_analyzer.analyze_audio(dl["file_path"], track_id=cat["catalog_id"])
                catalog.update_audio_analysis(cat["catalog_id"], analysis["payload"])
                audio_analysis = analysis["summary"]
            except Exception as ae:
                fail_payload = audio_analyzer.build_failed_payload(error_message=str(ae))
                catalog.update_audio_analysis(cat["catalog_id"], fail_payload)

        return {"metadata": meta, "storage": up, "catalog": cat, "audio_analysis": audio_analysis}


    raise ValueError(f"Unknown tool: {name}")

def main():
    """JSON-RPC 2.0 stdio server loop for MCP."""
    for line in sys.stdin:
        if not line.strip():
            continue
        try:
            req = json.loads(line)
            req_id = req.get("id")
            method = req.get("method")

            if method == "tools/list":
                res = {"jsonrpc": "2.0", "id": req_id, "result": {"tools": TOOLS_SCHEMA}}
            elif method == "tools/call":
                params = req.get("params", {})
                tool_name = params.get("name")
                tool_args = params.get("arguments", {})
                tool_output = handle_call_tool(tool_name, tool_args)
                res = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "content": [{"type": "text", "text": json.dumps(tool_output, ensure_ascii=False, indent=2)}]
                    }
                }
            elif method == "initialize":
                res = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "protocolVersion": "2024-11-05",
                        "serverInfo": {"name": "music-crawler-mcp", "version": "1.0.0"},
                        "capabilities": {"tools": {}}
                    }
                }
            else:
                res = {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32601, "message": f"Method {method} not found"}}

            sys.stdout.write(json.dumps(res) + "\n")
            sys.stdout.flush()
        except Exception as e:
            err_res = {"jsonrpc": "2.0", "id": None, "error": {"code": -32000, "message": str(e)}}
            sys.stdout.write(json.dumps(err_res) + "\n")
            sys.stdout.flush()

if __name__ == "__main__":
    main()
