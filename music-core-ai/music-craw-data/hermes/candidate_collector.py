import os
import json
import yaml
from typing import Dict, Any, List, Set, Optional
from openai import AzureOpenAI
from rich.console import Console

from services.metadata_service import MetadataService
from hermes.models import ChecklistTask
from hermes.checklist_manager import HermesChecklistManager

console = Console()

class HermesCandidateCollector:
    """
    Bộ thu thập và làm giàu ứng viên bài hát (Candidate Collector):
    - Đảm nhận việc cung cấp đủ số lượng bài hát theo yêu cầu của từng task trong Checklist.
    - Chia nhỏ việc thu thập thành các mini-batch (30-50 bài) để LLM không bao giờ bị cắt ngắn hoặc cạn token.
    - Kết hợp chặt chẽ với iTunes Search & Deezer API để bổ sung và làm giàu Metadata chuẩn (Cover HD, Album, Năm).
    - Tự động deduplicate (loại bỏ bài trùng) dựa trên danh sách toàn cục.
    """

    def __init__(self, config_or_path: Any = "config.yaml"):
        if isinstance(config_or_path, str):
            self.config = self._load_config(config_or_path)
        else:
            self.config = config_or_path or {}

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

    def _load_config(self, config_path: str) -> Dict[str, Any]:
        if os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        return {}

    def collect_for_task(self, task: ChecklistTask, seen_keys: Set[str]) -> List[Dict[str, Any]]:
        """
        Thu thập và làm giàu danh sách bài hát cho 1 task cụ thể.
        Đảm bảo không lấy trùng bài trong seen_keys và cố gắng đạt đủ task.target_count.
        """
        target_count = task.target_count
        console.print(f"[dim cyan]🔍 [Collector] Đang thu thập {target_count} bài hát cho nhiệm vụ: '{task.title}'...[/dim cyan]")

        raw_candidates: List[Dict[str, str]] = []

        # 1. Nếu là nhiệm vụ Album cụ thể
        if task.intent_type == "ALBUM" and task.album_name:
            console.print(f"[dim]Tra cứu toàn bộ Album: '{task.album_name}' ({task.artist_name or ''})...[/dim]")
            album_tracks = MetadataService.get_album_tracks(task.album_name, task.artist_name or "")
            for t in album_tracks:
                title = t.get("title", "")
                artist = t.get("artist", "")
                if not HermesChecklistManager.normalize_track_key(title, artist) in seen_keys:
                    raw_candidates.append({"title": title, "artist": artist})
            # Nếu đã có đầy đủ từ iTunes, trả về luôn sau khi lọc
            if raw_candidates:
                return self._enrich_metadata_list(raw_candidates[:target_count], task)

        # 2. Nếu là Artist Top
        elif task.intent_type == "ARTIST_TOP" and task.artist_name:
            limit = min(50, target_count)
            results = MetadataService.search_candidates(task.artist_name, limit=limit)
            for r in results:
                title = r.get("title", "")
                artist = r.get("artist", "")
                if not HermesChecklistManager.normalize_track_key(title, artist) in seen_keys:
                    raw_candidates.append({"title": title, "artist": artist})

        # 3. Với Curated Batch / Genre / Đại trà: Dùng LLM theo Mini-batch để không bao giờ bị thiếu
        batch_size = 40  # Kích thước an toàn để GPT-4o trả về đầy đủ không bị lazy
        collected_in_task: List[Dict[str, str]] = []
        
        # Bắt đầu với những gì đã tìm được
        for item in raw_candidates:
            key = HermesChecklistManager.normalize_track_key(item["title"], item["artist"])
            if key not in seen_keys and all(HermesChecklistManager.normalize_track_key(x["title"], x["artist"]) != key for x in collected_in_task):
                collected_in_task.append(item)

        attempts = 0
        max_attempts = 4

        while len(collected_in_task) < target_count and attempts < max_attempts:
            attempts += 1
            needed = target_count - len(collected_in_task)
            current_ask = min(batch_size, needed)

            console.print(f"[dim]⚡ [LLM Batch {attempts}] Tuyển chọn thêm {current_ask} bài cho '{task.title}' (Hiện có {len(collected_in_task)}/{target_count})...[/dim]")

            # Mẫu bài đã có để LLM tránh sinh trùng
            sample_existing = [f"{t['title']} ({t['artist']})" for t in collected_in_task[-20:]]

            llm_candidates = self._ask_llm_for_candidates(
                task_title=task.title,
                task_desc=task.description,
                category=task.category,
                query_hints=task.query_hints,
                count=current_ask,
                existing_sample=sample_existing
            )

            new_added = 0
            for cand in llm_candidates:
                t_name = cand.get("title", "").strip()
                a_name = cand.get("artist", "").strip()
                if not t_name:
                    continue
                key = HermesChecklistManager.normalize_track_key(t_name, a_name)
                if key not in seen_keys and all(HermesChecklistManager.normalize_track_key(x["title"], x["artist"]) != key for x in collected_in_task):
                    collected_in_task.append({"title": t_name, "artist": a_name})
                    new_added += 1
                    if len(collected_in_task) >= target_count:
                        break

            if new_added == 0:
                # Nếu LLM không sinh thêm được bài mới, dùng fallback query hints qua iTunes
                for hint in task.query_hints:
                    if len(collected_in_task) >= target_count:
                        break
                    api_res = MetadataService.search_candidates(hint, limit=10)
                    for r in api_res:
                        t_name = r.get("title", "").strip()
                        a_name = r.get("artist", "").strip()
                        key = HermesChecklistManager.normalize_track_key(t_name, a_name)
                        if key not in seen_keys and all(HermesChecklistManager.normalize_track_key(x["title"], x["artist"]) != key for x in collected_in_task):
                            collected_in_task.append({"title": t_name, "artist": a_name})
                            if len(collected_in_task) >= target_count:
                                break
                break

        # 4. Làm giàu Metadata (Canonical Metadata Enrichment)
        final_list = self._enrich_metadata_list(collected_in_task[:target_count], task)
        console.print(f"[green]✓ [Collector] Đã chuẩn bị xong {len(final_list)}/{target_count} bài hát chất lượng cao cho '{task.title}'.[/green]")
        return final_list

    def _ask_llm_for_candidates(
        self,
        task_title: str,
        task_desc: str,
        category: str,
        query_hints: List[str],
        count: int,
        existing_sample: List[str]
    ) -> List[Dict[str, str]]:
        """Gọi LLM tuyển chọn bài hát cho 1 mini-batch cụ thể"""
        hints_str = ", ".join(query_hints) if query_hints else task_title
        avoid_str = "; ".join(existing_sample) if existing_sample else "Chưa có"

        prompt = (
            f"Bạn là chuyên gia giám tuyển âm nhạc Việt Nam.\n"
            f"Hãy tuyển chọn chính xác {count} bài hát hay nhất, nổi tiếng nhất và tiêu biểu nhất cho chủ đề:\n"
            f"• Tiêu đề chuyên mục: {task_title}\n"
            f"• Mô tả yêu cầu: {task_desc}\n"
            f"• Phân loại: {category}\n"
            f"• Từ khóa gợi ý: {hints_str}\n"
            f"• CÁC BÀI ĐÃ CÓ (KHÔNG ĐƯỢC LẶP LẠI): {avoid_str}\n\n"
            f"Yêu cầu:\n"
            f"- Trả về danh sách gồm đúng {count} bài hát (không viết tắt sai ca sĩ).\n"
            f"- Đảm bảo bài hát đúng thực tế, có ca sĩ rõ ràng.\n"
            f"- CHỈ TRẢ VỀ JSON theo cấu trúc:\n"
            f'{{"tracks": [{{"title": "Tên bài hát", "artist": "Tên ca sĩ"}}]}}'
        )

        try:
            resp = self.client.chat.completions.create(
                model=self.deployment_name,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
                response_format={"type": "json_object"}
            )
            content = resp.choices[0].message.content or "{}"
            parsed = json.loads(content)
            return parsed.get("tracks", [])
        except Exception as e:
            console.print(f"[yellow]⚠️ Lỗi mini-batch LLM: {e}[/yellow]")
            return []

    def _enrich_metadata_list(self, candidates: List[Dict[str, str]], task: ChecklistTask) -> List[Dict[str, Any]]:
        """Tra cứu iTunes & Deezer để lấy Cover Art HD 1400x1400, Album, Năm, Track number"""
        enriched: List[Dict[str, Any]] = []

        for item in candidates:
            title = item.get("title", "").strip()
            artist = item.get("artist", "").strip()
            if not title:
                continue

            meta = None
            search_queries = [
                f"{title} {artist}".strip(),
                f"{title.split('(')[0].strip()} {artist}".strip(),
                title.split('(')[0].strip()
            ]

            for q in search_queries:
                meta = MetadataService.get_metadata(q)
                if meta:
                    break

            if meta:
                # Bổ sung thông tin nếu thiếu
                if not meta.get("album") and task.album_name:
                    meta["album"] = task.album_name
                enriched.append(meta)
            else:
                # Fallback chuẩn hóa nếu không tìm thấy trên iTunes
                enriched.append({
                    "source": "curated_hermes",
                    "title": title,
                    "artist": artist or task.artist_name or "V-Pop",
                    "album": task.album_name or task.category or "Single",
                    "cover_url": "",
                    "year": "",
                    "release_date": "",
                    "duration_ms": 0,
                    "track_number": 1,
                    "disc_number": 1
                })

        return enriched

