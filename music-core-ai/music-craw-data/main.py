import os
import sys
import argparse
import glob
from dotenv import load_dotenv
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from hermes import HermesMusicAgent
from workflow import AutoWorkflowEngine

load_dotenv()
console = Console()

def list_existing_plans(storage_dir: str = ".hermes/plans"):
    """Hiển thị danh sách các kế hoạch Hermes đã lưu"""
    plan_files = glob.glob(os.path.join(storage_dir, "*.json"))
    if not plan_files:
        console.print("[yellow]Chưa có kế hoạch Hermes nào được lưu trong .hermes/plans/[/yellow]")
        return

    table = Table(title="📁 DANH SÁCH CÁC KẾ HOẠCH HERMES (PLANS)", title_style="bold yellow")
    table.add_column("Plan ID", style="cyan")
    table.add_column("File", style="dim")
    table.add_column("Dung lượng (KB)", justify="right")

    for pf in plan_files:
        p_id = os.path.splitext(os.path.basename(pf))[0]
        size_kb = round(os.path.getsize(pf) / 1024, 1)
        table.add_row(p_id, pf, str(size_kb))

    console.print(table)
    console.print("[dim]Để tiếp tục chạy lại một kế hoạch: python main.py --resume <Plan ID>[/dim]\n")

def run_hermes_interactive():
    console.print(Panel.fit(
        "[bold yellow]⚡ HERMES AUTONOMOUS MUSIC INGESTION AGENT[/bold yellow]\n"
        "[white]• Thiết kế theo kiến trúc Hermes Agent: Tự động phân rã & Lập Checklist trước khi chạy.[/white]\n"
        "[white]• Hỗ trợ cào dữ liệu quy mô lớn (500 - 1000 bài) bằng cơ chế chia nhỏ Subtask cân đối.[/white]\n"
        "[white]• Quản lý trạng thái từng việc: [dim]⏳ PENDING[/dim] -> [cyan]▶ IN PROGRESS[/cyan] -> [green]✓ COMPLETED[/green].[/white]\n"
        "[white]• Bền bỉ (Persistent): Lưu checkpoint tự động, có thể Resume bất cứ lúc nào.[/white]\n"
        "[white]• Tự động trích xuất âm học (BPM, Key, Camelot, Cues, LUFS) và sync Catalog API.[/white]\n"
        "[dim]Nhập 'exit' hoặc 'quit' để kết thúc. Nhập 'plans' để xem danh sách checkpoints.[/dim]",
        border_style="yellow"
    ))

    agent = HermesMusicAgent("config.yaml")

    while True:
        try:
            prompt = console.input("\n[bold green]Bạn:[/bold green] ").strip()
            if not prompt:
                continue
            if prompt.lower() in ["exit", "quit", "q"]:
                console.print("[yellow]Tạm biệt![/yellow]")
                break
            if prompt.lower() in ["plans", "list"]:
                list_existing_plans()
                continue
            
            agent.run(prompt)

        except KeyboardInterrupt:
            console.print("\n[yellow]Đã ngắt phiên làm việc. Kế hoạch hiện tại đã được lưu vào .hermes/plans/[/yellow]")
            break
        except Exception as e:
            console.print(f"\n[red]Lỗi thực thi:[/red] {e}")

def run_direct_album(album_name: str, artist_name: str = ""):
    """Chạy trực tiếp toàn bộ 1 Album qua Hermes Agent"""
    prompt = f"Tải toàn bộ album {album_name}" + (f" của ca sĩ {artist_name}" if artist_name else "")
    console.print(Panel(f"[bold]Khởi chạy Hermes Agent cho Album:[/bold] {album_name} ({artist_name})", style="magenta"))
    agent = HermesMusicAgent("config.yaml")
    agent.run(prompt)

def main():
    parser = argparse.ArgumentParser(description="Hermes Autonomous Music Ingestion Agent")
    parser.add_argument("--album", type=str, help="Tải toàn bộ 1 album (VD: --album 'HVL' --artist 'MCK')")
    parser.add_argument("--artist", type=str, default="", help="Tên nghệ sĩ đi kèm khi dùng --album")
    parser.add_argument("--prompt", "-p", type=str, help="Gửi một prompt trực tiếp cho Hermes Agent")
    parser.add_argument("--resume", "-r", type=str, help="Tiếp tục thực thi kế hoạch theo Plan ID đã lưu (VD: --resume hermes_plan_abc123)")
    parser.add_argument("--list-plans", action="store_true", help="Liệt kê các kế hoạch đã lưu trong .hermes/plans/")
    args = parser.parse_args()

    if args.list_plans:
        list_existing_plans()
    elif args.resume:
        agent = HermesMusicAgent("config.yaml")
        agent.run("", resume_plan_id=args.resume)
    elif args.album:
        run_direct_album(args.album, args.artist)
    elif args.prompt:
        agent = HermesMusicAgent("config.yaml")
        agent.run(args.prompt)
    else:
        run_hermes_interactive()

if __name__ == "__main__":
    main()
