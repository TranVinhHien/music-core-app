import os
import sys
import argparse
from dotenv import load_dotenv
from rich.console import Console
from rich.panel import Panel

from agent import InteractiveMusicAgent
from services.metadata_service import MetadataService
from services.downloader_service import DownloaderService
from services.storage_service import StorageService
from services.catalog_service import CatalogService

load_dotenv()
console = Console()

def run_agent_interactive():
    console.print(Panel.fit(
        "[bold cyan]🎵 MUSIC CRAWLER & CATALOG AGENT[/bold cyan]\n"
        "[white]• Tự động lên kế hoạch & tương tác hai chiều.[/white]\n"
        "[white]• Tải audio, nhúng ID3 Tag + Cover Art HD.[/white]\n"
        "[white]• Upload S3 & tự động đồng bộ vào NestJS Catalog API.[/white]\n"
        "[dim]Nhập 'exit' hoặc 'quit' để kết thúc.[/dim]",
        border_style="cyan"
    ))

    agent = InteractiveMusicAgent("config.yaml")

    while True:
        try:
            prompt = console.input("\n[bold green]Bạn:[/bold green] ").strip()
            if not prompt:
                continue
            if prompt.lower() in ["exit", "quit", "q"]:
                console.print("[yellow]Tạm biệt![/yellow]")
                break
            
            with console.status("[bold green]Agent đang suy nghĩ và lập kế hoạch...[/bold green]", spinner="dots"):
                reply = agent.chat(prompt)

            console.print(f"\n[bold blue]🤖 Agent:[/bold blue]")
            console.print(reply)

        except KeyboardInterrupt:
            console.print("\n[yellow]Đã ngắt phiên làm việc.[/yellow]")
            break
        except Exception as e:
            console.print(f"\n[red]Lỗi thực thi:[/red] {e}")

def run_direct_pipeline(song_title: str, artist_name: str = ""):
    """Chạy trực tiếp toàn bộ chuỗi pipeline không cần LLM"""
    console.print(Panel(f"[bold]Chạy trực tiếp Pipeline cho:[/bold] {song_title} {artist_name}", style="magenta"))
    
    agent = InteractiveMusicAgent("config.yaml")
    res = agent._execute_tool("crawl_and_ingest_full_pipeline", {
        "song_title": song_title,
        "artist_name": artist_name
    })
    console.print(Panel(res, title="Kết quả Pipeline", border_style="green"))

def main():
    parser = argparse.ArgumentParser(description="Interactive Music Ingestion Agent")
    parser.add_argument("--crawl", "-c", type=str, help="Cào 1 bài hát trực tiếp (VD: --crawl 'Waiting For You' --artist 'MONO')")
    parser.add_argument("--artist", "-a", type=str, default="", help="Tên nghệ sĩ đi kèm khi dùng --crawl")
    parser.add_argument("--prompt", "-p", type=str, help="Gửi một prompt trực tiếp cho Agent")
    args = parser.parse_args()

    if args.crawl:
        run_direct_pipeline(args.crawl, args.artist)
    elif args.prompt:
        agent = InteractiveMusicAgent("config.yaml")
        reply = agent.chat(args.prompt)
        console.print(f"\n[bold blue]Agent:[/bold blue]\n{reply}")
    else:
        run_agent_interactive()

if __name__ == "__main__":
    main()
