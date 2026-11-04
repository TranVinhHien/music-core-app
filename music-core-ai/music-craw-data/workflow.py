import os
import json
import yaml
from typing import Dict, Any, List, Optional
from rich.console import Console

from hermes import HermesMusicAgent, HermesPlan
from services.metadata_service import MetadataService
from services.downloader_service import DownloaderService
from services.storage_service import StorageService
from services.catalog_service import CatalogService
from services.artist_parser import ArtistParser
from services.audio_analyzer_service import AudioAnalyzerService

console = Console()

class AutoWorkflowEngine:
    """
    Auto Workflow Engine (Refactored to Hermes Agent Architecture):
    - Tự động lập Checklist danh sách việc làm trước khi thực thi.
    - Chia nhỏ các yêu cầu lớn (ví dụ 1000 bài) thành các Subtask cân đối, không bị giới hạn token.
    - Chạy tuần tự và tự động cho đến khi hoàn thành toàn bộ chỉ tiêu.
    - Giữ trọn vẹn bộ 6 công cụ hạ tầng và khả năng trích xuất âm học.
    """

    def __init__(self, config_path: str = "config.yaml"):
        self.config_path = config_path
        self.hermes = HermesMusicAgent(config_path=config_path)

        # Giữ lại các thuộc tính cũ để tương thích với bất kỳ mã ngoài nào truy cập
        self.config = self.hermes.config
        self.downloader = self.hermes.executor.downloader
        self.storage = self.hermes.executor.storage
        self.catalog = self.hermes.executor.catalog
        self.audio_analyzer = self.hermes.executor.audio_analyzer

    def analyze_user_intent(self, user_prompt: str) -> Dict[str, Any]:
        """Tương thích ngược: Phân tích mục tiêu bằng Hermes Planner"""
        plan = self.hermes.planner.create_plan(user_prompt)
        return {
            "intent_type": "HERMES_PLAN",
            "goal": plan.goal,
            "total_target_count": plan.total_target_count,
            "tasks": [t.model_dump() for t in plan.tasks]
        }

    def process_single_track(self, track_meta: Dict[str, Any]) -> Dict[str, Any]:
        """Tương thích ngược: Xử lý 1 bài hát thông qua Hermes Executor"""
        res = self.hermes.executor.process_track(track_meta)
        return {
            "title": res.title,
            "artist": res.artist,
            "album": res.album,
            "file_url": res.file_url,
            "catalog_id": res.catalog_id,
            "parsed_artists": res.parsed_artists,
            "audio_analysis": res.audio_analysis,
            "size_mb": res.size_mb,
            "attempts_used": res.attempts_used,
            "success": res.success
        }

    def execute_workflow(self, user_prompt: str, resume_plan_id: Optional[str] = None) -> str:
        """
        Khởi chạy toàn bộ luồng Hermes Agent:
        Checklist Generation -> Autonomous Execution Loop -> Summary Report
        """
        plan = self.hermes.run(user_prompt, resume_plan_id=resume_plan_id)
        return (
            f"Hermes Agent đã hoàn thành kế hoạch '{plan.goal}'. "
            f"Đã xử lý và đẩy thành công {plan.total_crawled_count}/{plan.total_target_count} bài hát "
            f"vào Catalog Microservice & AWS S3."
        )
