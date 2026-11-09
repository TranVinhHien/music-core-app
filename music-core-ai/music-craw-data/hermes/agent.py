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
    Autonomous music ingestion agent based on the Hermes Agent Pattern:
    - Parses goals and promptly breaks them down into an Execution Checklist of granular subtasks.
    - Displays a live visual Checklist table before executing.
    - Sequentially executes each task until 100% of the target quota is achieved.
    - Persistent checkpointing with seamless resume capability at any time.
    - Leverages all 6 core infrastructure tools and acoustic analysis capabilities.
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
        Executes full Hermes Agent lifecycle:
        Plan & Checklist -> Checklist-driven Loop Execution -> Final Report
        """
        console.print(Panel(
            f"[bold cyan]User Target:[/bold cyan] {user_prompt}",
            title="⚡ [bold yellow]HERMES AGENT ACTIVATED[/bold yellow]",
            border_style="yellow"
        ))

        # Step 1: Initialize or Load Plan Checklist
        if resume_plan_id:
            console.print(f"[bold green]🔄 Resuming execution from Plan ID: {resume_plan_id}...[/bold green]")
            plan = self.checklist_mgr.load_plan(resume_plan_id)
        else:
            with console.status("[bold green]Step 1: Analyzing & Generating Execution Checklist...[/bold green]"):
                plan = self.planner.create_plan(user_prompt)
            self.checklist_mgr.init_plan(plan)

        # Display initial checklist prior to execution
        self.checklist_mgr.display_checklist(subtitle="Execution plan initialized. Preparing sequential execution...")

        total_tasks = len(plan.tasks)
        console.print(f"\n[bold magenta]🚀 Starting Checklist execution loop ({total_tasks} tasks, target: {plan.total_target_count} tracks)...[/bold magenta]\n")

        # Step 2: Autonomous execution loop over checklist tasks
        while not self.checklist_mgr.is_all_completed():
            task = self.checklist_mgr.get_next_pending_task()
            if not task:
                break

            console.print(f"\n[bold cyan]═══════════════════════════════════════════════════════════════════[/bold cyan]")
            console.print(f"[bold yellow]▶ EXECUTING CHECKLIST #{task.index}/{total_tasks}:[/bold yellow] [bold white]{task.title}[/bold white] ({task.category})")
            console.print(f"[dim]Target: {task.target_count} tracks | {task.description}[/dim]")
            console.print(f"[bold cyan]═══════════════════════════════════════════════════════════════════[/bold cyan]\n")

            self.checklist_mgr.mark_task_status(task.id, TaskStatus.IN_PROGRESS)

            # 2.1 Collect candidates for this task
            candidates = self.collector.collect_for_task(task, self.checklist_mgr.seen_keys)

            if not candidates:
                console.print(f"[red]⚠️ No candidates collected for task '{task.title}'![/red]")
                self.checklist_mgr.mark_task_status(task.id, TaskStatus.FAILED, error="No candidates found")
                continue

            # 2.2 Process each track in task
            for idx, track_meta in enumerate(candidates, 1):
                if self.checklist_mgr.is_target_reached():
                    console.print("[bold green]🎉 Total global target reached! Stopping remaining track loops.[/bold green]")
                    break

                t_name = track_meta.get("title", "")
                a_name = track_meta.get("artist", "")
                console.print(f"\n[bold blue]━━━ [Task {task.index} - Track {idx}/{len(candidates)}] Processing: '{t_name}' - {a_name} ━━━[/bold blue]")

                result = self.executor.process_track(track_meta)
                self.checklist_mgr.record_track_result(task.id, result)

                if result.success:
                    console.print(f"[green]✓ Succeeded: {result.title} | S3: {result.file_url}[/green]")
                else:
                    console.print(f"[red]✗ Error: {result.title} ({result.error_message})[/red]")

            # 2.3 Update task completion status
            if task.crawled_count >= task.target_count or task.crawled_count > 0:
                self.checklist_mgr.mark_task_status(task.id, TaskStatus.COMPLETED)
            else:
                self.checklist_mgr.mark_task_status(task.id, TaskStatus.FAILED)

            # Re-render Checklist table
            self.checklist_mgr.display_checklist(subtitle=f"Completed Task #{task.index}: {task.title}")

        # Step 3: Summary report
        if self.checklist_mgr.plan:
            if self.checklist_mgr.plan.total_crawled_count >= self.checklist_mgr.plan.total_target_count:
                self.checklist_mgr.plan.status = "COMPLETED"
            else:
                self.checklist_mgr.plan.status = "PARTIALLY_COMPLETED"
            self.checklist_mgr.save_plan()

        self.checklist_mgr.display_final_summary()
        return self.checklist_mgr.plan or plan

