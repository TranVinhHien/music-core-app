import os
import json
import yaml
from typing import Dict, Any, List, Optional
from openai import AzureOpenAI
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn

from services.metadata_service import MetadataService
from services.downloader_service import DownloaderService
from services.storage_service import StorageService
from services.catalog_service import CatalogService

console = Console()

class InteractiveMusicAgent:
    """
    Agent thông minh:
    - Nhận yêu cầu của người dùng, tự động phân tích và lên kế hoạch (Planning).
    - Tự động thực thi từng bước trong quy trình:
      [Tìm kiếm Metadata] -> [Tải & Gắn Tag Audio] -> [Upload S3 Storage] -> [Đăng ký Catalog API].
    - Tương tác hai chiều, giải thích hành động và báo cáo tiến độ chi tiết.
    """

    def __init__(self, config_path: str = "config.yaml"):
        self.config = self._load_config(config_path)
        azure_cfg = self.config.get("azure_openai", {})
        
        endpoint = azure_cfg.get("endpoint")
        api_key = os.environ.get("AZURE_OPENAI_API_KEY") or azure_cfg.get("api_key")
        api_version = azure_cfg.get("gpt4o_version", "2024-08-01-preview")
        self.deployment_name = azure_cfg.get("gpt4o_deployment", "gpt-4o-vision")

        if not api_key:
            console.print("[yellow]⚠️ Cảnh báo: Chưa tìm thấy AZURE_OPENAI_API_KEY. Vui lòng cập nhật config.yaml hoặc biến môi trường.[/yellow]")

        self.client = AzureOpenAI(
            azure_endpoint=endpoint,
            api_key=api_key or "DUMMY_KEY",
            api_version=api_version,
        )

        # Khởi tạo các services hạ tầng
        storage_cfg = self.config.get("storage", {})
        download_dir = storage_cfg.get("download_dir", "./downloads")
        self.downloader = DownloaderService(download_dir=download_dir)
        self.storage = StorageService(self.config)
        
        backend_cfg = self.config.get("backend", {})
        catalog_url = backend_cfg.get("catalog_api_url", "http://localhost:3002/api/v1/catalog")
        self.catalog = CatalogService(base_url=catalog_url)

        # Lịch sử hội thoại
        self.conversation_history: List[Dict[str, Any]] = [
            {
                "role": "system",
                "content": (
                    "Bạn là Trợ lý AI Chuyên gia Crawl và Quản trị Dữ liệu Âm nhạc (Music Ingestion Agent).\n"
                    "Nhiệm vụ của bạn là nhận yêu cầu của người dùng, phân tích và lên kế hoạch rõ ràng, sau đó điều phối các tools để:\n"
                    "1. Lên kế hoạch (Plan): Trình bày các bước thực hiện cho người dùng.\n"
                    "2. Tìm kiếm và cào metadata bài hát chính xác (Tên bài, Ca sĩ, Album, Cover Art, Năm phát hành, Thời lượng).\n"
                    "3. Tải stream audio từ YouTube/SoundCloud, nhúng ID3 tag chuẩn và Cover Art vào file MP3.\n"
                    "4. Upload file audio lên hệ thống lưu trữ (S3 / Storage Service) để lấy liên kết lưu trữ công khai (file_url).\n"
                    "5. Đẩy metadata và file_url vào hệ thống Catalog Microservice (POST /artists, POST /albums, POST /tracks).\n"
                    "6. Báo cáo kết quả rõ ràng, thân thiện cho người dùng.\n\n"
                    "QUAN TRỌNG: Với mỗi bài hát cần cào, bạn PHẢI tự động hoàn thành trọn vẹn chuỗi: "
                    "[Metadata] -> [Download & Tag] -> [Upload S3 Storage] -> [Catalog API]. "
                    "Hãy luôn giải thích tiến trình và trạng thái các bước."
                )
            }
        ]

        # Khởi tạo công cụ (Tools definition)
        self.tools = self._init_tools()

    def _load_config(self, config_path: str) -> Dict[str, Any]:
        if os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        return {}

    def _init_tools(self) -> List[Dict[str, Any]]:
        return [
            {
                "type": "function",
                "function": {
                    "name": "plan_workflow",
                    "description": "Lập kế hoạch các bước sẽ thực hiện dựa trên yêu cầu của người dùng trước khi tiến hành.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "goal": {"type": "string", "description": "Mục tiêu tổng quan cần đạt được."},
                            "steps": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "Danh sách các bước cụ thể sẽ thực hiện."
                            }
                        },
                        "required": ["goal", "steps"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "search_online_candidates",
                    "description": "Tìm kiếm danh sách bài hát hoặc album từ iTunes/Deezer để chọn bài cào dữ liệu.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string", "description": "Từ khóa tìm kiếm (VD: 'Sơn Tùng M-TP', 'Waiting For You', v.v.)."},
                            "limit": {"type": "integer", "description": "Số lượng bài hát cần gợi ý (mặc định 5)."}
                        },
                        "required": ["query"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_song_metadata",
                    "description": "Lấy chi tiết metadata chuẩn mực của một bài hát cụ thể (Title, Artist, Album, Cover Art URL, Year, Duration).",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string", "description": "Tên bài hát và nghệ sĩ."}
                        },
                        "required": ["query"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "download_and_tag_audio",
                    "description": "Tải audio từ YouTube qua yt-dlp, nhúng metadata và album cover art vào file.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "search_query": {"type": "string", "description": "Từ khóa tìm kiếm trên YouTube."},
                            "metadata": {"type": "object", "description": "Thông tin metadata đầy đủ của bài hát."}
                        },
                        "required": ["search_query", "metadata"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "upload_audio_to_storage",
                    "description": "Upload file âm thanh (và ảnh cover) lên S3/Storage để nhận URL lưu trữ chính thức.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "local_file_path": {"type": "string", "description": "Đường dẫn file cục bộ đã tải."},
                            "folder": {"type": "string", "description": "Thư mục đích trên storage (mặc định 'tracks')."}
                        },
                        "required": ["local_file_path"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "register_to_catalog",
                    "description": "Tự động đăng ký Artist, Album và gắn Track mới vào hệ thống Catalog Microservice.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "title": {"type": "string", "description": "Tên bài hát."},
                            "artist_name": {"type": "string", "description": "Tên ca sĩ / nghệ sĩ."},
                            "album_title": {"type": "string", "description": "Tên album (nếu có)."},
                            "file_url": {"type": "string", "description": "URL lưu trữ của file âm thanh (từ upload_audio_to_storage)."},
                            "cover_image_url": {"type": "string", "description": "URL ảnh bìa."},
                            "duration_ms": {"type": "integer", "description": "Thời lượng bài hát tính bằng milliseconds."},
                            "release_date": {"type": "string", "description": "Ngày phát hành định dạng YYYY-MM-DD."},
                            "source_url": {"type": "string", "description": "URL nguồn gốc (YouTube video link)."}
                        },
                        "required": ["title", "artist_name", "file_url"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "crawl_and_ingest_full_pipeline",
                    "description": "Thực hiện trọn gói toàn bộ pipeline cho 1 bài hát: Tìm metadata -> Tải & Gắn Tag -> Upload S3 -> Đăng ký Catalog API.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "song_title": {"type": "string", "description": "Tên bài hát."},
                            "artist_name": {"type": "string", "description": "Tên ca sĩ."}
                        },
                        "required": ["song_title"]
                    }
                }
            }
        ]

    def _execute_tool(self, name: str, args: Dict[str, Any]) -> str:
        console.print(f"\n[bold cyan]🛠️ [Tool Invoked]: {name}[/bold cyan]")

        if name == "plan_workflow":
            goal = args.get("goal", "")
            steps = args.get("steps", [])
            table = Table(title=f"📋 KẾ HOẠCH THỰC THI: {goal}", title_style="bold yellow")
            table.add_column("STT", style="cyan", width=6)
            table.add_column("Bước thực hiện", style="white")
            for idx, step in enumerate(steps, 1):
                table.add_row(str(idx), step)
            console.print(table)
            return json.dumps({"status": "plan_registered", "goal": goal, "total_steps": len(steps)}, ensure_ascii=False)

        elif name == "search_online_candidates":
            query = args.get("query", "")
            limit = args.get("limit", 5)
            console.print(f"[dim]Tìm kiếm bài hát trực tuyến cho: '{query}' (tối đa {limit} kết quả)...[/dim]")
            candidates = MetadataService.search_candidates(query, limit=limit)
            return json.dumps({"status": "success", "count": len(candidates), "candidates": candidates}, ensure_ascii=False)

        elif name == "get_song_metadata":
            query = args.get("query", "")
            console.print(f"[dim]Trích xuất metadata chuẩn cho: '{query}'...[/dim]")
            meta = MetadataService.get_metadata(query)
            if not meta:
                return json.dumps({"status": "not_found", "message": f"Không tìm thấy metadata cho '{query}'"})
            console.print(f"[green]✓ Đã tìm thấy: {meta.get('title')} - {meta.get('artist')} (Album: {meta.get('album')})[/green]")
            return json.dumps({"status": "success", "metadata": meta}, ensure_ascii=False)

        elif name == "download_and_tag_audio":
            search_query = args.get("search_query", "")
            metadata = args.get("metadata", {})
            console.print(f"[dim]Bắt đầu tải stream audio và gắn tag: '{search_query}'...[/dim]")
            try:
                res = self.downloader.search_and_download(search_query, metadata)
                console.print(f"[green]✓ Tải thành công: {res['file_name']} ({res['file_size_mb']} MB)[/green]")
                return json.dumps({"status": "success", "data": res}, ensure_ascii=False)
            except Exception as e:
                console.print(f"[red]✗ Lỗi tải file: {e}[/red]")
                return json.dumps({"status": "error", "message": str(e)})

        elif name == "upload_audio_to_storage":
            local_path = args.get("local_file_path", "")
            folder = args.get("folder", "tracks")
            console.print(f"[dim]Đang đẩy file {local_path} lên Storage/S3...[/dim]")
            try:
                upload_res = self.storage.upload_file(local_path, folder=folder)
                console.print(f"[green]✓ Upload hoàn tất! URL: {upload_res['url']}[/green]")
                return json.dumps({"status": "success", "data": upload_res}, ensure_ascii=False)
            except Exception as e:
                console.print(f"[red]✗ Lỗi upload: {e}[/red]")
                return json.dumps({"status": "error", "message": str(e)})

        elif name == "register_to_catalog":
            title = args.get("title", "")
            artist_name = args.get("artist_name", "")
            album_title = args.get("album_title")
            file_url = args.get("file_url", "")
            cover_image_url = args.get("cover_image_url")
            duration_ms = args.get("duration_ms")
            release_date = args.get("release_date")
            source_url = args.get("source_url")

            console.print(f"[dim]Đang liên kết dữ liệu với Catalog Microservice: '{title}'...[/dim]")

            # 1. Tìm hoặc tạo Artist
            artist_rec = self.catalog.find_or_create_artist(artist_name, image_url=cover_image_url)
            artist_id = artist_rec.get("id") if artist_rec else None

            # 2. Tìm hoặc tạo Album nếu có
            album_id = None
            if album_title:
                album_rec = self.catalog.find_or_create_album(album_title, artist_id=artist_id, release_date=release_date, cover_image_url=cover_image_url)
                album_id = album_rec.get("id") if album_rec else None

            # 3. Nguồn track
            sources = []
            if source_url:
                sources.append({
                    "source": "YOUTUBE",
                    "externalId": source_url.split("v=")[-1] if "v=" in source_url else "external",
                    "externalUrl": source_url
                })

            # 4. Tạo Track
            track_res = self.catalog.create_track(
                title=title,
                file_url=file_url,
                cover_image_url=cover_image_url,
                duration_ms=duration_ms,
                release_date=release_date,
                artist_id=artist_id,
                album_id=album_id,
                sources=sources
            )
            return json.dumps(track_res, ensure_ascii=False)

        elif name == "crawl_and_ingest_full_pipeline":
            song_title = args.get("song_title", "")
            artist_name = args.get("artist_name", "")
            full_query = f"{song_title} {artist_name}".strip()

            console.print(f"\n[bold magenta]🚀 BẮT ĐẦU PIPELINE TRỌN GÓI CHO: {full_query}[/bold magenta]")

            # Bước 1: Metadata
            meta = MetadataService.get_metadata(full_query)
            if not meta:
                meta = {
                    "title": song_title,
                    "artist": artist_name or "Unknown Artist",
                    "album": "Single",
                    "year": "",
                    "cover_url": "",
                    "duration_ms": 0
                }

            # Bước 2: Download & Tag
            search_yt = f"{meta['title']} {meta['artist']} Official Audio"
            dl_res = self.downloader.search_and_download(search_yt, meta)

            # Bước 3: Upload Storage
            upload_res = self.storage.upload_file(dl_res["file_path"], folder="tracks")
            file_url = upload_res["url"]

            # Bước 4: Catalog Sync
            artist_rec = self.catalog.find_or_create_artist(meta["artist"], image_url=meta.get("cover_url"))
            artist_id = artist_rec.get("id") if artist_rec else None

            album_id = None
            if meta.get("album"):
                album_rec = self.catalog.find_or_create_album(meta["album"], artist_id=artist_id, release_date=meta.get("release_date"), cover_image_url=meta.get("cover_url"))
                album_id = album_rec.get("id") if album_rec else None

            sources = [{
                "source": "YOUTUBE",
                "externalId": dl_res.get("source_url", "").split("v=")[-1] if "v=" in dl_res.get("source_url", "") else "stream",
                "externalUrl": dl_res.get("source_url", "")
            }]

            catalog_res = self.catalog.create_track(
                title=meta["title"],
                file_url=file_url,
                cover_image_url=meta.get("cover_url"),
                duration_ms=meta.get("duration_ms"),
                release_date=meta.get("release_date"),
                artist_id=artist_id,
                album_id=album_id,
                sources=sources
            )

            summary = {
                "success": True,
                "title": meta["title"],
                "artist": meta["artist"],
                "album": meta.get("album"),
                "file_path": dl_res["file_path"],
                "storage_url": file_url,
                "catalog_status": catalog_res
            }
            return json.dumps(summary, ensure_ascii=False)

        return json.dumps({"status": "unknown_tool"})

    def chat(self, user_input: str) -> str:
        """
        Nhận tương tác từ người dùng, thực hiện chu trình Reasoning -> Tool Calling -> Output.
        """
        self.conversation_history.append({"role": "user", "content": user_input})

        while True:
            response = self.client.chat.completions.create(
                model=self.deployment_name,
                messages=self.conversation_history,
                tools=self.tools,
                tool_choice="auto",
                temperature=0.2
            )

            msg = response.choices[0].message
            self.conversation_history.append(msg)

            if not msg.tool_calls:
                return msg.content or ""

            for tool_call in msg.tool_calls:
                func_name = tool_call.function.name
                func_args = json.loads(tool_call.function.arguments)

                # Thực thi tool
                tool_res = self._execute_tool(func_name, func_args)

                # Đưa kết quả tool vào hội thoại
                self.conversation_history.append({
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": tool_res
                })
