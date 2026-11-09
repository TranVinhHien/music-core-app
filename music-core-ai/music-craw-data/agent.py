import os
import yaml
from typing import Dict, Any, Optional, List
from rich.console import Console

from hermes import HermesMusicAgent, HermesPlan

console = Console()

class InteractiveMusicAgent:
    """
    Tương thích ngược với interface cũ:
    Chuyển tiếp mọi yêu cầu sang kiến trúc HermesMusicAgent với khả năng lập Checklist,
    chia nhỏ tác vụ và chạy bền bỉ đến khi hoàn tất 100% mục tiêu.
    """

    def __init__(self, config_path: str = "config.yaml"):
        self.config_path = config_path
        self.hermes = HermesMusicAgent(config_path=config_path)

    def chat(self, user_input: str) -> str:
        """Thực thi thông qua Hermes Agent Engine và trả về báo cáo kết quả"""
        plan = self.hermes.run(user_input)
        return (
            f"Đã hoàn tất kế hoạch '{plan.goal}'. "
            f"Tổng số bài hát đã xử lý thành công: {plan.total_crawled_count}/{plan.total_target_count}."
        )

# Re-export HermesMusicAgent as standard
__all__ = ["HermesMusicAgent", "InteractiveMusicAgent", "HermesPlan"]
