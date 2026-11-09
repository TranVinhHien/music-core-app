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
        "[white]• Automated planning & conversational interaction.[/white]\n"
        "[white]• Audio streaming, ID3 Tagging + HD Cover Art embedding.[/white]\n"
        "[white]• S3 Storage upload & automated sync with NestJS Catalog API.[/white]\n"
        "[dim]Type 'exit' or 'quit' to quit.[/dim]",
        border_style="cyan"
    ))

    agent = InteractiveMusicAgent("config.yaml")

    while True:
        try:
            prompt = console.input("\n[bold green]You:[/bold green] ").strip()
            if not prompt:
                continue
            if prompt.lower() in ["exit", "quit", "q"]:
                console.print("[yellow]Goodbye![/yellow]")
                break
            
            with console.status("[bold green]Agent thinking and planning...[/bold green]", spinner="dots"):
                reply = agent.chat(prompt)

            console.print(f"\n[bold blue]🤖 Agent:[/bold blue]")
            console.print(reply)

        except KeyboardInterrupt:
            console.print("\n[yellow]Session interrupted.[/yellow]")
            break
        except Exception as e:
            console.print(f"\n[red]Execution error:[/red] {e}")

def run_direct_pipeline(song_title: str, artist_name: str = ""):
    """Runs entire ingestion pipeline directly without LLM reasoning"""
    console.print(Panel(f"[bold]Direct Pipeline Execution for:[/bold] {song_title} {artist_name}", style="magenta"))
    
    agent = InteractiveMusicAgent("config.yaml")
    res = agent._execute_tool("crawl_and_ingest_full_pipeline", {
        "song_title": song_title,
        "artist_name": artist_name
    })
    console.print(Panel(res, title="Pipeline Result", border_style="green"))

def main():
    parser = argparse.ArgumentParser(description="Interactive Music Ingestion Agent")
    parser.add_argument("--crawl", "-c", type=str, help="Crawl a track directly (e.g. --crawl 'Waiting For You' --artist 'MONO')")
    parser.add_argument("--artist", "-a", type=str, default="", help="Artist name used with --crawl")
    parser.add_argument("--prompt", "-p", type=str, help="Send direct prompt to Agent")
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
