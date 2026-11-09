import os
import json
import re
import datetime
from typing import Optional, List, Dict, Any, Set
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import BarColumn

from hermes.models import HermesPlan, ChecklistTask, TaskStatus, TrackExecutionResult

console = Console()

class HermesChecklistManager:
    """
    Quản lý danh sách việc làm (Checklist), trạng thái tiến độ và độ bền vững (Persistence)
    theo chuẩn kiến trúc Hermes Agent.
    """

    def __init__(self, storage_dir: str = ".hermes/plans"):
        self.storage_dir = storage_dir
        os.makedirs(self.storage_dir, exist_ok=True)
        self.plan: Optional[HermesPlan] = None
        self.seen_keys: Set[str] = set()

    @staticmethod
    def normalize_track_key(title: str, artist: str) -> str:
        """Tạo khóa định danh duy nhất để tránh cào trùng bài hát giữa các batch"""
        clean_title = re.sub(r'[\(\[\{].*?[\)\]\}]', '', title).lower().strip()
        clean_title = re.sub(r'[^\w\s]', '', clean_title)
        clean_artist = artist.lower().split("&")[0].split("feat")[0].split("ft")[0].strip()
        clean_artist = re.sub(r'[^\w\s]', '', clean_artist)
        return f"{clean_title}::{clean_artist}"

    def init_plan(self, plan: HermesPlan) -> None:
        """Khởi tạo plan và đăng ký các bài hát đã có (nếu resume)"""
        self.plan = plan
        self.seen_keys.clear()
        for task in self.plan.tasks:
            for t in task.completed_tracks:
                key = self.normalize_track_key(t.get("title", ""), t.get("artist", ""))
                self.seen_keys.add(key)
        self.save_plan()

    def save_plan(self) -> str:
        """Lưu snapshot của plan vào disk để theo dõi và hỗ trợ resume"""
        if not self.plan:
            return ""
        self.plan.updated_at = datetime.datetime.now().isoformat()
        filepath = os.path.join(self.storage_dir, f"{self.plan.plan_id}.json")
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(self.plan.model_dump_json(indent=2))
        return filepath

    def load_plan(self, plan_id_or_path: str) -> HermesPlan:
        """Tải một plan đã lưu từ disk để resume quá trình cào"""
        if os.path.exists(plan_id_or_path):
            filepath = plan_id_or_path
        else:
            filepath = os.path.join(self.storage_dir, f"{plan_id_or_path}.json")
        
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"Không tìm thấy plan file: {filepath}")

        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
        plan = HermesPlan.model_validate(data)
        self.init_plan(plan)
        return plan

    def is_seen(self, title: str, artist: str) -> bool:
        """Kiểm tra bài hát đã được xử lý hoặc đã có trong danh sách chưa"""
        return self.normalize_track_key(title, artist) in self.seen_keys

    def mark_seen(self, title: str, artist: str) -> None:
        self.seen_keys.add(self.normalize_track_key(title, artist))

    def get_next_pending_task(self) -> Optional[ChecklistTask]:
        """Lấy task tiếp theo chưa hoàn thành trong checklist"""
        if not self.plan:
            return None
        for task in self.plan.tasks:
            if task.status in [TaskStatus.PENDING, TaskStatus.IN_PROGRESS]:
                return task
        return None

    def mark_task_status(self, task_id: str, status: TaskStatus, error: Optional[str] = None) -> None:
        """Cập nhật trạng thái của một task trong checklist"""
        if not self.plan:
            return
        for task in self.plan.tasks:
            if task.id == task_id:
                task.status = status
                if error:
                    task.errors.append(error)
                break
        self.save_plan()

    def record_track_result(self, task_id: str, result: TrackExecutionResult) -> None:
        """Ghi nhận kết quả của 1 bài hát vào task tương ứng và cập nhật tổng số"""
        if not self.plan:
            return
        for task in self.plan.tasks:
            if task.id == task_id:
                if result.success:
                    task.crawled_count += 1
                    self.plan.total_crawled_count += 1
                    task.completed_tracks.append(result.model_dump())
                    self.mark_seen(result.title, result.artist)
                else:
                    if result.error_message:
                        task.errors.append(f"{result.title}: {result.error_message}")
                break
        self.save_plan()

    def is_target_reached(self) -> bool:
        """Kiểm tra xem đã đạt đủ tổng số lượng yêu cầu hay chưa"""
        if not self.plan:
            return False
        return self.plan.total_crawled_count >= self.plan.total_target_count

    def is_all_completed(self) -> bool:
        """Kiểm tra toàn bộ checklist đã hoàn thành hay chưa"""
        if not self.plan:
            return True
        if self.is_target_reached():
            return True
        return all(t.status in [TaskStatus.COMPLETED, TaskStatus.SKIPPED] for t in self.plan.tasks)

    def display_checklist(self, subtitle: str = "") -> None:
        """Hiển thị bảng Checklist trực quan, phản ánh chính xác trạng thái từng đầu việc"""
        if not self.plan:
            return

        total_target = self.plan.total_target_count
        total_crawled = self.plan.total_crawled_count
        percent = (total_crawled / total_target * 100) if total_target > 0 else 100.0

        header_text = (
            f"[bold cyan]🎯 Mục tiêu:[/bold cyan] {self.plan.goal}\n"
            f"[bold white]📊 Tiến độ toàn cục:[/bold white] [bold green]{total_crawled}/{total_target} bài ({percent:.1f}%)[/bold green]"
        )
        if subtitle:
            header_text += f"\n[dim italic]{subtitle}[/dim italic]"

        console.print(Panel(header_text, title="📋 [bold yellow]HERMES AGENT EXECUTION CHECKLIST[/bold yellow]", border_style="yellow"))

        table = Table(show_header=True, header_style="bold magenta")
        table.add_column("STT", justify="center")
        table.add_column("Trạng thái", justify="center")
        table.add_column("Thể loại", style="cyan")
        table.add_column("Nhiệm vụ (Checklist Item)", style="white")
        table.add_column("Chỉ tiêu", justify="center")
        table.add_column("Tiến độ", justify="center")

        status_icons = {
            TaskStatus.PENDING: "[dim]⏳ PENDING[/dim]",
            TaskStatus.IN_PROGRESS: "[bold cyan]▶ IN PROGRESS[/bold cyan]",
            TaskStatus.COMPLETED: "[bold green]✓ COMPLETED[/bold green]",
            TaskStatus.FAILED: "[bold red]✗ FAILED[/bold red]",
            TaskStatus.SKIPPED: "[yellow]⏭ SKIPPED[/yellow]"
        }

        for task in self.plan.tasks:
            stat_str = status_icons.get(task.status, str(task.status))
            prog_ratio = f"{task.crawled_count}/{task.target_count}"
            prog_bar = ""
            if task.target_count > 0:
                p = min(1.0, task.crawled_count / task.target_count)
                bar_len = 8
                filled = int(p * bar_len)
                prog_bar = f"[{'=' * filled}{'-' * (bar_len - filled)}] {int(p*100)}%"

            table.add_row(
                str(task.index),
                stat_str,
                task.category,
                task.title,
                f"{task.crawled_count}/{task.target_count}",
                prog_bar or prog_ratio
            )

        console.print(table)
        console.print()

    def display_final_summary(self) -> None:
        """In bảng báo cáo tổng kết chi tiết sau khi toàn bộ quy trình hoàn tất"""
        if not self.plan:
            return

        all_completed: List[Dict[str, Any]] = []
        for task in self.plan.tasks:
            all_completed.extend(task.completed_tracks)

        report_table = Table(
            title=f"🎉 BÁO CÁO TỔNG KẾT HERMES AGENT ({len(all_completed)}/{self.plan.total_target_count} bài thành công)",
            title_style="bold green",
            expand=True
        )
        report_table.add_column("#", style="dim", width=4)
        report_table.add_column("Bài hát", style="white")
        report_table.add_column("Nghệ sĩ (Primary / Feat)", style="cyan")
        report_table.add_column("Album", style="magenta")
        report_table.add_column("Thông số Âm học (BPM / Camelot / LUFS)", style="yellow")
        report_table.add_column("Catalog ID", style="dim", width=10)
        report_table.add_column("S3 Audio URL", style="blue")

        for idx, t in enumerate(all_completed, 1):
            parsed_artists = t.get("parsed_artists", [])
            art_label = ", ".join([f"{a['name']} ({a.get('role', 'PRIMARY')})" for a in parsed_artists]) if parsed_artists else t.get("artist", "")
            aa = t.get("audio_analysis")
            if aa:
                aa_label = f"BPM {aa.get('bpm')} | {aa.get('camelot')} | {aa.get('lufs')} LUFS"
            else:
                aa_label = "N/A"

            cat_id = str(t.get("catalog_id", ""))
            cat_short = cat_id[:8] + "..." if len(cat_id) > 8 else cat_id

            report_table.add_row(
                str(idx),
                t.get("title", ""),
                art_label,
                t.get("album") or "",
                aa_label,
                cat_short,
                t.get("file_url") or ""
            )

        console.print(report_table)
        console.print(
            Panel.fit(
                f"[bold green]✓ Hoàn thành toàn diện nhiệm vụ Hermes Agent![/bold green]\n"
                f"• Tổng số bài đã xử lý thành công: [bold cyan]{len(all_completed)}/{self.plan.total_target_count}[/bold cyan]\n"
                f"• Snapshot kế hoạch đã lưu tại: [dim]{os.path.join(self.storage_dir, f'{self.plan.plan_id}.json')}[/dim]",
                border_style="green"
            )
        )
