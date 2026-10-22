import os
import json
import yaml
import time
from typing import Dict, Any, List, Optional
from openai import AzureOpenAI
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn

from services.metadata_service import MetadataService
from services.downloader_service import DownloaderService
from services.storage_service import StorageService
from services.catalog_service import CatalogService
from services.artist_parser import ArtistParser

console = Console()

class AutoWorkflowEngine:
    """
    Auto Workflow Engine:
    1. Nhận yêu cầu ngôn ngữ tự nhiên từ người dùng.
    2. Dùng Azure OpenAI phân tích ý định (Intent Analysis) thành cấu trúc rõ ràng.
    3. Tự động thu thập 100% bài hát (không bị giới hạn 5 hay 10 bài như agent cũ).
    4. Tự động chạy tuần tự quy trình tải -> gắn tag đa nghệ sĩ -> upload S3 -> catalog API.
    5. Báo cáo tiến độ và bảng tổng hợp chi tiết.
    """

    def __init__(self, config_path: str = "config.yaml"):
        self.config = self._load_config(config_path)
        azure_cfg = self.config.get("azure_openai", {})
        
        endpoint = azure_cfg.get("endpoint")
        api_key = os.environ.get("AZURE_OPENAI_API_KEY") or azure_cfg.get("api_key")
        api_version = azure_cfg.get("gpt4o_version", "2024-08-01-preview")
        self.deployment_name = azure_cfg.get("gpt4o_deployment", "gpt-4o-vision")

        self.client = AzureOpenAI(
            azure_endpoint=endpoint,
            api_key=api_key or "DUMMY_KEY",
            api_version=api_version,
        )

        storage_cfg = self.config.get("storage", {})
        download_dir = storage_cfg.get("download_dir", "./downloads")
        self.downloader = DownloaderService(download_dir=download_dir)
        self.storage = StorageService(self.config)
        
        backend_cfg = self.config.get("backend", {})
        catalog_url = backend_cfg.get("catalog_api_url", "http://localhost:3002/api/v1/catalog")
        self.catalog = CatalogService(base_url=catalog_url)

    def _load_config(self, config_path: str) -> Dict[str, Any]:
        if os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        return {}

    def analyze_user_intent(self, user_prompt: str) -> Dict[str, Any]:
        """
        Dùng LLM (GPT-4o) làm Chuyên gia Giám tuyển & Phân tích Âm nhạc:
        - Tự động sửa lỗi chính tả, teencode (nhạc trả -> nhạc trẻ, vide -> vibe, sưa -> xưa).
        - Nhận diện yêu cầu Album, Top nghệ sĩ, hoặc Yêu cầu theo Vibe / Thể loại / Chủ đề / Danh sách tùy biến.
        - Tự động tuyển chọn chính xác danh sách bài hát (candidate_tracks) khớp phong cách và đủ số lượng.
        """
        system_prompt = (
            "Bạn là Chuyên gia Tuyển chọn & Giám tuyển Âm nhạc (Music Curator & Intent Analyzer) thông minh bậc nhất.\n"
            "Nhiệm vụ của bạn là hiểu sâu sắc mọi yêu cầu của người dùng về âm nhạc dù câu hỏi có viết tắt, sai chính tả hay mơ hồ.\n\n"
            "CÁC DẠNG YÊU CẦU PHỔ BIẾN:\n"
            "1. Yêu cầu toàn bộ một Album cụ thể (VD: 'Tải album HVL của MCK', 'Toàn bộ album 99%'):\n"
            "   -> intent_type: 'ALBUM', album_name, artist_name, requested_count: 'ALL'.\n\n"
            "2. Yêu cầu Top bài hát của 1 nghệ sĩ (VD: 'Top 15 bài của Vũ', 'Bài hát hay nhất của Sơn Tùng'):\n"
            "   -> intent_type: 'ARTIST_TOP', artist_name, requested_count: <số_lượng>.\n\n"
            "3. Yêu cầu theo Vibe, Thể loại, Hoài niệm, Phong cách, Tuyển tập nhiều ca sĩ hoặc Danh sách mở:\n"
            "   (VD: '30 bài nhạc trẻ vibe xưa như Tuấn Hưng, Duy Mạnh, Đan Trường', 'nhạc rap old school', 'nhạc ballad buồn', 'các bài hit 2000s'):\n"
            "   -> intent_type: 'CURATED_LIST'\n"
            "   -> BẮT BUỘC: Bạn hãy đóng vai chuyên gia âm nhạc, tự tuyển chọn ĐẦY ĐỦ và CHÍNH XÁC danh sách 'candidate_tracks' gồm các bài hát hay nhất, kinh điển nhất đúng phong cách và ĐỦ SỐ LƯỢNG người dùng yêu cầu (ví dụ yêu cầu 30 bài thì tạo đúng 30 bài).\n\n"
            "QUY TẮC:\n"
            "- Tự động sửa lỗi chính tả tiếng Việt hoặc teencode của người dùng (ví dụ: 'nhạc trả' -> 'nhạc trẻ', 'vide' -> 'vibe', 'sưa sưa' -> 'xưa xưa', 'đang trường' -> 'Đan Trường').\n"
            "- Ca sĩ kết hợp (&, ft, feat, x, vs) biểu thị nhiều ca sĩ.\n"
            "- CHỈ TRẢ VỀ JSON DUY NHẤT theo định dạng:\n"
            "{\n"
            '  "intent_type": "ALBUM" | "ARTIST_TOP" | "CURATED_LIST",\n'
            '  "album_name": "Tên album hoặc null",\n'
            '  "artist_name": "Tên nghệ sĩ hoặc null",\n'
            '  "requested_count": 30 | "ALL",\n'
            '  "description": "Mô tả ngắn gọn yêu cầu đã chuẩn hóa bằng tiếng Việt",\n'
            '  "candidate_tracks": [\n'
            '    {"title": "Tên bài hát", "artist": "Tên ca sĩ"}\n'
            '  ]\n'
            "}"
        )

        response = self.client.chat.completions.create(
            model=self.deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.3,
            response_format={"type": "json_object"}
        )

        content = response.choices[0].message.content or "{}"
        try:
            return json.loads(content)
        except Exception:
            return {
                "intent_type": "CURATED_LIST",
                "candidate_tracks": [{"title": user_prompt, "artist": ""}],
                "requested_count": 1,
                "description": user_prompt
            }

    def resolve_tracks(self, intent: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Tìm kiếm và thu thập 100% danh sách bài hát dựa trên kết quả phân tích:
        - Nếu là Album: Tra cứu toàn bộ tracklist của Album từ iTunes/Deezer.
        - Nếu là Vibe / Tuyển tập / Danh sách: Lấy từ candidate_tracks do LLM tuyển chọn,
          sau đó làm giàu metadata từ iTunes/Deezer (Cover HD 1400x1400, Album, Năm)
          mà không bao giờ bỏ sót bài nào!
        """
        intent_type = intent.get("intent_type", "CURATED_LIST")
        album_name = intent.get("album_name")
        artist_name = intent.get("artist_name") or ""
        requested_count = intent.get("requested_count", "ALL")
        candidates = intent.get("candidate_tracks", [])

        tracks: List[Dict[str, Any]] = []

        # 1. Trường hợp Album
        if intent_type == "ALBUM" and album_name:
            console.print(f"[dim]Tra cứu toàn bộ Album '{album_name}' của '{artist_name}'...[/dim]")
            tracks = MetadataService.get_album_tracks(album_name, artist_name)
            if requested_count != "ALL" and isinstance(requested_count, int) and requested_count > 0:
                tracks = tracks[:requested_count]

        # 2. Trường hợp Artist Top
        elif intent_type == "ARTIST_TOP" and artist_name:
            limit = 20 if requested_count == "ALL" else int(requested_count)
            console.print(f"[dim]Tra cứu top {limit} bài hát của nghệ sĩ '{artist_name}'...[/dim]")
            tracks = MetadataService.search_candidates(artist_name, limit=limit)

        # 3. Trường hợp Tuyển tập theo Vibe, Phong cách, Danh sách nhiều bài hoặc Fallback
        if not tracks and candidates:
            console.print(f"[dim]Đang làm giàu metadata chuẩn cho {len(candidates)} bài hát tuyển chọn...[/dim]")
            for item in candidates:
                song_title = item.get("title", "").strip()
                song_artist = item.get("artist", "").strip()
                if not song_title:
                    continue

                meta = None
                # Thử tối đa 3 cách tra cứu metadata chuẩn trên iTunes/Deezer
                meta_strategies = [
                    f"{song_title} {song_artist}".strip(),
                    f"{song_title.split('(')[0].strip()} {song_artist}".strip(),
                    song_title.split('(')[0].strip()
                ]
                for m_query in meta_strategies:
                    meta = MetadataService.get_metadata(m_query)
                    if meta:
                        break
                
                if meta:
                    tracks.append(meta)
                else:
                    # Nếu cả 3 cách tra cứu metadata đều không có trên iTunes,
                    # giữ nguyên tên bài và ca sĩ để yt-dlp tải trực tiếp từ YouTube
                    tracks.append({
                        "source": "curated",
                        "title": song_title,
                        "artist": song_artist or artist_name or "V-Pop",
                        "album": "Tuyển tập",
                        "cover_url": "",
                        "year": "",
                        "release_date": "",
                        "duration_ms": 0,
                        "track_number": 1,
                        "disc_number": 1
                    })

        # 4. Fallback tối thượng nếu vẫn rỗng: tìm kiếm thẳng từ khóa mô tả
        if not tracks:
            desc = intent.get("description", "")
            if desc:
                console.print(f"[dim]Tìm kiếm dự phòng theo mô tả: '{desc}'...[/dim]")
                tracks = MetadataService.search_candidates(desc, limit=10)

        return tracks

    def process_single_track(self, track_meta: Dict[str, Any]) -> Dict[str, Any]:
        """
        Thực thi tự động chuỗi pipeline cho 1 bài hát với cơ chế Retry & Đổi phương án (Tối đa 3 lần):
        - Lần 1: Chiến lược tiêu chuẩn (Standard: Tải audio theo metadata đầy đủ, Upload S3, Catalog đầy đủ).
        - Lần 2: Chiến lược dự phòng (Alternative 1: Làm sạch tiêu đề bài hát, thử lại S3 và Catalog).
        - Lần 3: Chiến lược tối giản (Alternative 2: Tải nguồn nới lỏng, fallback lưu trữ, đăng ký tối giản).
        """
        title = track_meta.get("title", "")
        artist = track_meta.get("artist", "")
        album = track_meta.get("album", "")
        cover_url = track_meta.get("cover_url", "")
        release_date = track_meta.get("release_date", "")
        duration_ms = track_meta.get("duration_ms", 0)
        track_number = track_meta.get("track_number")
        disc_number = track_meta.get("disc_number")

        MAX_ATTEMPTS = 3
        last_exception = None

        for attempt in range(1, MAX_ATTEMPTS + 1):
            try:
                if attempt > 1:
                    console.print(f"[yellow]🔄 (Lần thử {attempt}/{MAX_ATTEMPTS}) Đang đổi cách thực hiện cho: '{title}'...[/yellow]")

                # Chiến lược tìm kiếm tương ứng từng lần
                if attempt == 1:
                    search_query = f"{title} {artist} Official Audio"
                elif attempt == 2:
                    # Lược bỏ ký tự đặc biệt / ngoặc đơn
                    clean_t = title.split("(")[0].split("-")[0].strip()
                    search_query = f"{clean_t} {artist}"
                else:
                    clean_t = title.split("(")[0].strip()
                    search_query = clean_t

                # 1. Download stream audio & tag ID3
                dl_res = self.downloader.search_and_download(search_query, track_meta)
                local_file_path = dl_res["file_path"]

                # 2. Upload lên Storage (S3 hoặc Local fallback)
                upload_res = self.storage.upload_file(local_file_path, folder="tracks")
                file_url = upload_res["url"]

                # 3. Nguồn track YouTube
                sources = [{
                    "source": "YOUTUBE",
                    "externalId": dl_res.get("source_url", "").split("v=")[-1] if "v=" in dl_res.get("source_url", "") else "stream",
                    "externalUrl": dl_res.get("source_url", "")
                }]

                # 4. Đẩy vào Catalog Microservice với phân tách đa nghệ sĩ
                catalog_res = self.catalog.register_track_full(
                    raw_title=title,
                    raw_artist=artist,
                    file_url=file_url,
                    album_title=album if attempt < 3 else None,  # Lần 3 bỏ album nếu album gây lỗi
                    cover_image_url=cover_url,
                    duration_ms=duration_ms,
                    release_date=release_date,
                    track_number=track_number,
                    disc_number=disc_number,
                    sources=sources
                )

                return {
                    "title": title,
                    "artist": artist,
                    "album": album,
                    "file_url": file_url,
                    "size_mb": dl_res.get("file_size_mb"),
                    "catalog_id": catalog_res.get("catalog_id"),
                    "parsed_artists": catalog_res.get("parsed_artists", []),
                    "attempts_used": attempt
                }

            except Exception as e:
                last_exception = e
                console.print(f"[dim yellow]⚠️ Cách {attempt} gặp trở ngại: {e}[/dim yellow]")
                time.sleep(1)

        raise RuntimeError(f"Đã cố gắng thực hiện lại 3 lần bằng 3 phương án khác nhau nhưng không thành công cho '{title}'. Lỗi cuối: {last_exception}")

    def execute_workflow(self, user_prompt: str) -> str:
        """
        Toàn bộ luồng Auto Workflow từ lúc nhận yêu cầu đến khi hoàn tất
        """
        console.print(Panel(f"[bold cyan]Yêu cầu:[/bold cyan] {user_prompt}", border_style="cyan"))

        # Giai đoạn 1: Phân tích yêu cầu với LLM
        with console.status("[bold green]Bước 1: Phân tích yêu cầu & lập cấu trúc thực thi...[/bold green]"):
            intent = self.analyze_user_intent(user_prompt)

        console.print(f"[bold yellow]🎯 Kế hoạch phân tích:[/bold yellow] {intent.get('description')}")
        console.print(f"• Loại yêu cầu: [bold]{intent.get('intent_type')}[/bold] | Ca sĩ: [bold]{intent.get('artist_name')}[/bold] | Album: [bold]{intent.get('album_name')}[/bold] | Số lượng: [bold]{intent.get('requested_count')}[/bold]\n")

        # Giai đoạn 2: Khám phá đầy đủ danh sách bài hát
        with console.status("[bold green]Bước 2: Tìm kiếm và trích xuất danh sách bài hát chuẩn...[/bold green]"):
            tracks = self.resolve_tracks(intent)

        if not tracks:
            msg = "❌ Không tìm thấy bài hát nào phù hợp với yêu cầu."
            console.print(f"[red]{msg}[/red]")
            return msg

        # Hiển thị bảng danh sách bài hát cần xử lý
        plan_table = Table(title=f"📋 DANH SÁCH BÀI HÁT TÌM THẤY ({len(tracks)} bài)", title_style="bold green")
        plan_table.add_column("#", style="dim", width=4)
        plan_table.add_column("Tên bài hát", style="white")
        plan_table.add_column("Nghệ sĩ", style="cyan")
        plan_table.add_column("Album", style="magenta")
        plan_table.add_column("Thời lượng", style="yellow")

        for idx, t in enumerate(tracks, 1):
            dur_str = f"{t.get('duration_ms', 0) // 60000}:{(t.get('duration_ms', 0) % 60000) // 1000:02d}" if t.get('duration_ms') else "N/A"
            plan_table.add_row(str(idx), t.get("title", ""), t.get("artist", ""), t.get("album", ""), dur_str)
        console.print(plan_table)

        # Giai đoạn 3: Thực thi Auto Workflow tự động lần lượt
        console.print(f"\n[bold magenta]🚀 Bắt đầu Auto Workflow tải và đồng bộ {len(tracks)} bài hát vào hệ sinh thái...[/bold magenta]\n")

        results = []
        for idx, track_meta in enumerate(tracks, 1):
            song_name = track_meta.get("title", "")
            art_name = track_meta.get("artist", "")
            console.print(f"[bold cyan]▶ [{idx}/{len(tracks)}] Đang xử lý: '{song_name}' - {art_name}...[/bold cyan]")
            try:
                res = self.process_single_track(track_meta)
                results.append(res)
                artists_str = ", ".join([f"{a['name']} ({a['role']})" for a in res.get("parsed_artists", [])])
                console.print(f"[green]✓ Hoàn thành [{idx}/{len(tracks)}]: Đã upload S3 & Catalog (Nghệ sĩ: {artists_str})[/green]\n")
            except Exception as e:
                console.print(f"[red]✗ Lỗi tải bài '{song_name}': {e}[/red]\n")

        # Giai đoạn 4: Báo cáo tổng kết
        report_table = Table(title=f"🎉 BÁO CÁO KẾT QUẢ AUTO WORKFLOW ({len(results)}/{len(tracks)} bài thành công)", title_style="bold green")
        report_table.add_column("#", style="dim", width=4)
        report_table.add_column("Bài hát", style="white")
        report_table.add_column("Nghệ sĩ (Phân loại)", style="cyan")
        report_table.add_column("Album", style="magenta")
        report_table.add_column("Catalog ID", style="dim")
        report_table.add_column("S3 Storage Link", style="blue")

        for idx, r in enumerate(results, 1):
            art_label = ", ".join([f"{a['name']} ({a['role']})" for a in r.get("parsed_artists", [])])
            report_table.add_row(
                str(idx),
                r["title"],
                art_label,
                r["album"] or "",
                str(r["catalog_id"])[:8] + "...",
                r["file_url"]
            )
        console.print(report_table)

        summary_msg = f"Đã hoàn thành cào và đẩy thành công {len(results)}/{len(tracks)} bài hát vào Catalog Microservice & AWS S3."
        return summary_msg
