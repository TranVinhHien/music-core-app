import os
import yaml
from typing import Dict, Any, Optional
from rich.console import Console
from rich.panel import Panel

from hermes.models import HermesPlan, TaskStatus
from hermes.checklist_manager import HermesChecklistManager
from hermes.planner import HermesPlanner
from hermes.candidate_collector import HermesCandidateCollector
from hermes.executor import HermesExecutor

console = Console()

class HermesMusicAgent:
    """
    Hermes Music Agent:
    Agent cào dữ liệu âm nhạc thông minh dựa trên kiến trúc Hermes Agent:
    - Nhận yêu cầu và lập tức phân rã thành một Execution Checklist với đầy đủ các đầu việc cần làm.
    - Hiển thị bảng Checklist trực quan trước khi thực hiện.
    - Duyệt tuần tự và thực thi từng nhiệm vụ trong Checklist cho đến khi hoàn thành 100% mục tiêu.
    - Bền bỉ (Persistent), tự động ghi nhận checkpoint và hỗ trợ Resume mọi lúc.
    - Duy trì và phát huy trọn vẹn sức mạnh của 6 bộ công cụ hạ tầng hiện có.
    """

    def __init__(self, config_path: str = "config.yaml"):
        self.config_path = config_path
        self.config = self._load_config(config_path)

        self.checklist_mgr = HermesChecklistManager(storage_dir=".hermes/plans")
        self.planner = HermesPlanner(self.config)
        self.collector = HermesCandidateCollector(self.config)
        self.executor = HermesExecutor(self.config)

    def _load_config(self, config_path: str) -> Dict[str, Any]:
        if os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        return {}

    def run(self, user_prompt: str, resume_plan_id: Optional[str] = None) -> HermesPlan:
        """
        Khởi chạy chu trình Hermes Agent hoàn chỉnh:
        Plan & Checklist -> Checklist-driven Loop Execution -> Final Report
        """
        console.print(Panel(
            f"[bold cyan]Mục tiêu người dùng:[/bold cyan] {user_prompt}",
            title="⚡ [bold yellow]HERMES AGENT KÍCH HOẠT[/bold yellow]",
            border_style="yellow"
        ))

        # Bước 1: Khởi tạo hoặc Tải Plan Checklist
        if resume_plan_id:
            console.print(f"[bold green]🔄 Đang khôi phục phiên làm việc (Resume) từ Plan ID: {resume_plan_id}...[/bold green]")
            plan = self.checklist_mgr.load_plan(resume_plan_id)
        else:
            with console.status("[bold green]Bước 1: Phân tích & Lập Execution Checklist...[/bold green]"):
                plan = self.planner.create_plan(user_prompt)
            self.checklist_mgr.init_plan(plan)

        # Hiển thị Checklist ban đầu trước khi bắt đầu thực thi
        self.checklist_mgr.display_checklist(subtitle="Kế hoạch thực thi đã được thiết lập. Chuẩn bị chạy tuần tự từng việc...")

        total_tasks = len(plan.tasks)
        console.print(f"\n[bold magenta]🚀 Bắt đầu vòng lặp thực thi Checklist ({total_tasks} nhiệm vụ, tổng chỉ tiêu: {plan.total_target_count} bài)...[/bold magenta]\n")

        # Bước 2: Vòng lặp thực thi tự động qua từng việc trong Checklist
        while not self.checklist_mgr.is_all_completed():
            task = self.checklist_mgr.get_next_pending_task()
            if not task:
                break

            console.print(f"\n[bold cyan]═══════════════════════════════════════════════════════════════════[/bold cyan]")
            console.print(f"[bold yellow]▶ ĐANG THỰC HIỆN CHECKLIST #{task.index}/{total_tasks}:[/bold yellow] [bold white]{task.title}[/bold white] ({task.category})")
            console.print(f"[dim]Chỉ tiêu: {task.target_count} bài | {task.description}[/dim]")
            console.print(f"[bold cyan]═══════════════════════════════════════════════════════════════════[/bold cyan]\n")

            self.checklist_mgr.mark_task_status(task.id, TaskStatus.IN_PROGRESS)

            # 2.1 Thu thập ứng viên cho task này
            candidates = self.collector.collect_for_task(task, self.checklist_mgr.seen_keys)

            if not candidates:
                console.print(f"[red]⚠️ Không thu thập được ứng viên nào cho nhiệm vụ '{task.title}'![/red]")
                self.checklist_mgr.mark_task_status(task.id, TaskStatus.FAILED, error="Không tìm thấy ứng viên")
                continue

            # 2.2 Thực thi từng bài hát trong task
            for idx, track_meta in enumerate(candidates, 1):
                if self.checklist_mgr.is_target_reached():
                    console.print("[bold green]🎉 Đã đạt đủ tổng chỉ tiêu toàn cục! Dừng vòng lặp các bài còn lại.[/bold green]")
                    break

                t_name = track_meta.get("title", "")
                a_name = track_meta.get("artist", "")
                console.print(f"\n[bold blue]━━━ [Task {task.index} - Bài {idx}/{len(candidates)}] Đang xử lý: '{t_name}' - {a_name} ━━━[/bold blue]")

                result = self.executor.process_track(track_meta)
                self.checklist_mgr.record_track_result(task.id, result)

                if result.success:
                    console.print(f"[green]✓ Thành công: {result.title} | S3: {result.file_url}[/green]")
                else:
                    console.print(f"[red]✗ Lỗi: {result.title} ({result.error_message})[/red]")

            # 2.3 Cập nhật trạng thái hoàn thành task
            if task.crawled_count >= task.target_count or task.crawled_count > 0:
                self.checklist_mgr.mark_task_status(task.id, TaskStatus.COMPLETED)
            else:
                self.checklist_mgr.mark_task_status(task.id, TaskStatus.FAILED)

            # Cập nhật và hiển thị lại bảng Checklist
            self.checklist_mgr.display_checklist(subtitle=f"Đã hoàn thành Task #{task.index}: {task.title}")

        # Bước 3: Tổng kết báo cáo
        if self.checklist_mgr.plan:
            if self.checklist_mgr.plan.total_crawled_count >= self.checklist_mgr.plan.total_target_count:
                self.checklist_mgr.plan.status = "COMPLETED"
            else:
                self.checklist_mgr.plan.status = "PARTIALLY_COMPLETED"
            self.checklist_mgr.save_plan()

        self.checklist_mgr.display_final_summary()
        return self.checklist_mgr.plan or plan

