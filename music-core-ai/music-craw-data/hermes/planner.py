import os
import json
import uuid
import yaml
from typing import Dict, Any, List, Optional
from openai import AzureOpenAI
from rich.console import Console

from hermes.models import HermesPlan, ChecklistTask, TaskStatus

console = Console()

class HermesPlanner:
    """
    Hermes Planner:
    Chuyên gia phân tích và lập kế hoạch chiến lược:
    - Phân tích mục tiêu người dùng (kể cả quy mô cực lớn như 1000 bài hát).
    - Phân rã mục tiêu (Goal Decomposition) thành danh sách các đầu việc (Checklist Tasks)
      rõ ràng, cân đối về số lượng và phong phú về thể loại/chủ đề.
    - Đảm bảo không bao giờ bị nghẽn token của LLM bằng cách chia nhỏ thành các batch khả thi.
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

    def create_plan(self, user_prompt: str) -> HermesPlan:
        """
        Phân tích prompt của người dùng và tạo ra 1 HermesPlan chứa Checklist các việc cần làm.
        """
        console.print("[dim]🧠 [Hermes Planner] Đang phân tích mục tiêu & thiết kế Checklist chiến lược...[/dim]")

        system_prompt = (
            "Bạn là Hermes Master Planner - Kiến trúc sư lập kế hoạch crawl và giám tuyển âm nhạc hàng đầu.\n"
            "Nhiệm vụ của bạn là nhận yêu cầu của người dùng, phân tích quy mô mục tiêu, và phân rã (decompose) "
            "thành một KẾ HOẠCH CHECKLIST (Execution Checklist) gồm các đầu việc cụ thể.\n\n"
            "QUY TẮC PHÂN RÃ THEO QUY MÔ (SCALE DECOMPOSITION):\n"
            "1. Nếu người dùng yêu cầu số lượng lớn (VD: 1000 bài, 500 bài, 200 bài, 100 bài):\n"
            "   - TUYỆT ĐỐI KHÔNG sinh tên 1000 bài hát trong 1 lượt (sẽ bị lỗi token và đứt quãng).\n"
            "   - THAY VÀO ĐÓ: Phân rã mục tiêu thành các NHIỆM VỤ CHECKLIST (Tasks) chuyên đề, thể loại, "
            "thập niên, hoặc nhóm nghệ sĩ (mỗi task chứa từ 50 đến 100 bài, tổng các task bằng đúng số lượng yêu cầu).\n"
            "   - Ví dụ với 1000 bài hát Việt Nam nổi tiếng: Hãy chia thành 10 tasks (mỗi task 100 bài) bao gồm:\n"
            "     + Task 1: Top Hits V-Pop Hiện Đại & Trending (2020-2026)\n"
            "     + Task 2: V-Pop Giai Đoạn Vàng & Ballad Quốc Dân (2010-2019)\n"
            "     + Task 3: Làn Sóng Xanh & Nhạc Trẻ Hoài Niệm (2000-2009)\n"
            "     + Task 4: Rap Việt & Hip-Hop Kinh Điển Đến Hiện Đại\n"
            "     + Task 5: Indie & Acoustic Healing Việt Nam\n"
            "     + Task 6: Tình Ca Bất Hủ & Nhạc Trịnh (Trịnh Công Sơn, Ngô Thụy Miên...)\n"
            "     + Task 7: Tuyển Tập Bolero & Nhạc Vàng Đi Cùng Năm Tháng\n"
            "     + Task 8: Top Hits Nghệ Sĩ Quốc Dân (Sơn Tùng, Đen Vâu, Mỹ Tâm, Vũ, Soobin, Hà Anh Tuấn...)\n"
            "     + Task 9: EDM & Vinahouse Việt Nam Sôi Động\n"
            "     + Task 10: Nhạc Phim OST & Giai Điệu Quen Thuộc Mọi Thời Đại\n\n"
            "2. Nếu yêu cầu là Album (VD: 'Tải album HVL của MCK', 'Album 99%'):\n"
            "   - Tạo 1 task duy nhất với intent_type: 'ALBUM', album_name, artist_name, target_count: 30 (hoặc số bài ước tính).\n\n"
            "3. Nếu yêu cầu là Top nghệ sĩ hoặc danh sách nhỏ (VD: '15 bài của Vũ'):\n"
            "   - Tạo 1 task với target_count = 15, intent_type: 'ARTIST_TOP'.\n\n"
            "CHỈ TRẢ VỀ DUY NHẤT 1 ĐỐI TƯỢNG JSON chuẩn định dạng sau:\n"
            "{\n"
            '  "goal": "Mô tả mục tiêu tổng thể chuẩn hóa",\n'
            '  "total_target_count": 1000,\n'
            '  "tasks": [\n'
            "    {\n"
            '      "index": 1,\n'
            '      "title": "Tên nhiệm vụ checklist cụ thể",\n'
            '      "category": "Tên thể loại hoặc chủ đề",\n'
            '      "description": "Mô tả chi tiết nội dung cần cào trong task này",\n'
            '      "intent_type": "CURATED_BATCH" | "ALBUM" | "ARTIST_TOP",\n'
            '      "target_count": 100,\n'
            '      "album_name": "Tên album nếu có hoặc null",\n'
            '      "artist_name": "Tên nghệ sĩ nếu có hoặc null",\n'
            '      "query_hints": ["từ khóa 1", "từ khóa 2", "từ khóa 3"]\n'
            "    }\n"
            "  ]\n"
            "}"
        )

        try:
            response = self.client.chat.completions.create(
                model=self.deployment_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.2,
                response_format={"type": "json_object"}
            )
            raw_content = response.choices[0].message.content or "{}"
            parsed = json.loads(raw_content)
        except Exception as e:
            console.print(f"[yellow]⚠️ Lỗi khi gọi LLM Planner: {e}. Áp dụng Fallback Planner...[/yellow]")
            parsed = self._build_fallback_plan_dict(user_prompt)

        plan_id = f"hermes_plan_{uuid.uuid4().hex[:8]}"
        goal = parsed.get("goal") or user_prompt
        total_target = parsed.get("total_target_count", 1)
        tasks_data = parsed.get("tasks", [])

        # Kiểm tra và điều chỉnh target_count nếu tổng task không khớp
        if not tasks_data:
            tasks_data = [
                {
                    "index": 1,
                    "title": f"Cào dữ liệu: {user_prompt}",
                    "category": "General",
                    "description": user_prompt,
                    "intent_type": "CURATED_BATCH",
                    "target_count": total_target if isinstance(total_target, int) and total_target > 0 else 10,
                    "query_hints": [user_prompt]
                }
            ]

        # Khởi tạo models
        checklist_tasks: List[ChecklistTask] = []
        for idx, t in enumerate(tasks_data, 1):
            target = t.get("target_count", 1)
            if target == "ALL" or not isinstance(target, int) or target <= 0:
                target = 25
            task_obj = ChecklistTask(
                id=f"task_{idx}",
                index=idx,
                title=t.get("title", f"Task {idx}"),
                category=t.get("category", "General"),
                description=t.get("description", ""),
                intent_type=t.get("intent_type", "CURATED_BATCH"),
                target_count=target,
                status=TaskStatus.PENDING,
                query_hints=t.get("query_hints", []),
                album_name=t.get("album_name"),
                artist_name=t.get("artist_name")
            )
            checklist_tasks.append(task_obj)

        actual_total = sum(t.target_count for t in checklist_tasks)
        if total_target != actual_total:
            total_target = actual_total

        return HermesPlan(
            plan_id=plan_id,
            goal=goal,
            user_prompt=user_prompt,
            total_target_count=total_target,
            tasks=checklist_tasks
        )

    def _build_fallback_plan_dict(self, prompt: str) -> Dict[str, Any]:
        """Tạo kế hoạch dự phòng nếu LLM gặp sự cố"""
        lower = prompt.lower()
        if "1000" in lower:
            target = 1000
            tasks = []
            categories = [
                ("Top Hits V-Pop Hiện Đại (2020-2026)", "V-Pop Modern", ["V-Pop 2024", "Nhạc trẻ hot"]),
                ("V-Pop Giai Đoạn Vàng (2010-2019)", "V-Pop 2010s", ["Nhạc trẻ 2015", "Hit V-Pop 2010s"]),
                ("Làn Sóng Xanh & Hoài Niệm (2000-2009)", "V-Pop 2000s", ["Nhạc trẻ 2000", "Làn Sóng Xanh"]),
                ("Rap Việt & Underground", "Rap Việt", ["Rap Việt", "Underground Việt"]),
                ("Indie & Acoustic Việt Nam", "Indie / Acoustic", ["Indie Việt", "Acoustic Việt"]),
                ("Nhạc Trịnh & Tình Ca Bất Hủ", "Tình Ca", ["Nhạc Trịnh Công Sơn", "Tình ca bất hủ"]),
                ("Tuyển Tập Bolero & Trữ Tình", "Bolero", ["Tuyển tập Bolero", "Nhạc trữ tình"]),
                ("Top Hits Nghệ Sĩ Quốc Dân", "Top Artists", ["Sơn Tùng M-TP", "Đen Vâu", "Vũ"]),
                ("EDM & Vinahouse Việt Nam", "EDM / Vinahouse", ["Vinahouse hay nhất", "EDM Việt"]),
                ("Nhạc Phim & OST Bất Hủ", "OST", ["Nhạc phim Việt Nam", "OST phim hay"])
            ]
            for idx, (title, cat, hints) in enumerate(categories, 1):
                tasks.append({
                    "index": idx,
                    "title": title,
                    "category": cat,
                    "description": f"Cào 100 bài thuộc chuyên mục {title}",
                    "intent_type": "CURATED_BATCH",
                    "target_count": 100,
                    "query_hints": hints
                })
            return {
                "goal": "Cào 1000 bài hát Việt Nam nổi tiếng đa thể loại",
                "total_target_count": 1000,
                "tasks": tasks
            }
        else:
            return {
                "goal": prompt,
                "total_target_count": 20,
                "tasks": [
                    {
                        "index": 1,
                        "title": prompt,
                        "category": "Curated",
                        "description": prompt,
                        "intent_type": "CURATED_BATCH",
                        "target_count": 20,
                        "query_hints": [prompt]
                    }
                ]
            }

