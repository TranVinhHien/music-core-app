import os
import sys
import argparse
from dotenv import load_dotenv
from rich.console import Console
from rich.panel import Panel

from workflow import AutoWorkflowEngine
from services.metadata_service import MetadataService
from services.downloader_service import DownloaderService
from services.storage_service import StorageService
from services.catalog_service import CatalogService

load_dotenv()
console = Console()

def run_workflow_interactive():
    console.print(Panel.fit(
        "[bold cyan]🎵 MUSIC AUTO WORKFLOW & CATALOG INGESTION[/bold cyan]\n"
        "[white]• Tự động phân tích yêu cầu bằng Azure OpenAI (GPT-4o).[/white]\n"
        "[white]• Tự động tìm kiếm đầy đủ 100% bài hát (không giới hạn số lượng cố định).[/white]\n"
        "[white]• Nhận diện chính xác nhiều ca sĩ (PRIMARY & FEAT: &, ft, feat, x).[/white]\n"
        "[white]• Tự động tải, nhúng Cover Art, upload AWS S3 và đăng ký Catalog Microservice.[/white]\n"
        "[dim]Nhập 'exit' hoặc 'quit' để kết thúc.[/dim]",
        border_style="cyan"
    ))

    engine = AutoWorkflowEngine("config.yaml")

    while True:
        try:
            prompt = console.input("\n[bold green]Bạn:[/bold green] ").strip()
            if not prompt:
                continue
            if prompt.lower() in ["exit", "quit", "q"]:
                console.print("[yellow]Tạm biệt![/yellow]")
                break
            
            engine.execute_workflow(prompt)

        except KeyboardInterrupt:
            console.print("\n[yellow]Đã ngắt phiên làm việc.[/yellow]")
            break
        except Exception as e:
            console.print(f"\n[red]Lỗi thực thi:[/red] {e}")

def run_direct_album(album_name: str, artist_name: str = ""):
    """Chạy trực tiếp toàn bộ 1 Album không cần LLM"""
    console.print(Panel(f"[bold]Khởi chạy Auto Workflow cho Album:[/bold] {album_name} ({artist_name})", style="magenta"))
    engine = AutoWorkflowEngine("config.yaml")
    engine.execute_workflow(f"Tải toàn bộ album {album_name} của {artist_name}")

def main():
    parser = argparse.ArgumentParser(description="Autonomous Music Workflow & Ingestion Engine")
    parser.add_argument("--album", type=str, help="Tải toàn bộ 1 album (VD: --album 'HVL' --artist 'MCK')")
    parser.add_argument("--artist", type=str, default="", help="Tên nghệ sĩ đi kèm khi dùng --album")
    parser.add_argument("--prompt", "-p", type=str, help="Gửi một prompt trực tiếp cho Auto Workflow")
    args = parser.parse_args()

    if args.album:
        run_direct_album(args.album, args.artist)
    elif args.prompt:
        engine = AutoWorkflowEngine("config.yaml")
        engine.execute_workflow(args.prompt)
    else:
        run_workflow_interactive()

if __name__ == "__main__":
    main()
