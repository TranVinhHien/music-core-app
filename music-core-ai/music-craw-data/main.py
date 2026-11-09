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
    """Displays list of saved Hermes plans."""
    plan_files = glob.glob(os.path.join(storage_dir, "*.json"))
    if not plan_files:
        console.print("[yellow]No Hermes plans saved in .hermes/plans/[/yellow]")
        return

    table = Table(title="📁 SAVED HERMES PLANS", title_style="bold yellow")
    table.add_column("Plan ID", style="cyan")
    table.add_column("File", style="dim")
    table.add_column("Size (KB)", justify="right")

    for pf in plan_files:
        p_id = os.path.splitext(os.path.basename(pf))[0]
        size_kb = round(os.path.getsize(pf) / 1024, 1)
        table.add_row(p_id, pf, str(size_kb))

    console.print(table)
    console.print("[dim]To resume a plan: python main.py --resume <Plan ID>[/dim]\n")

def run_hermes_interactive():
    console.print(Panel.fit(
        "[bold yellow]⚡ HERMES AUTONOMOUS MUSIC INGESTION AGENT[/bold yellow]\n"
        "[white]• Built on the Hermes Agent Pattern: Goal decomposition & Execution Checklist prior to execution.[/white]\n"
        "[white]• High-volume ingestion support (500 - 1000 tracks) via balanced mini-batch subtasks.[/white]\n"
        "[white]• Live state tracking: [dim]⏳ PENDING[/dim] -> [cyan]▶ IN PROGRESS[/cyan] -> [green]✓ COMPLETED[/green].[/white]\n"
        "[white]• Persistent: Automatic checkpointing with resume capability anytime.[/white]\n"
        "[white]• Automatic acoustic feature extraction (BPM, Key, Camelot, Cues, LUFS) and Catalog API sync.[/white]\n"
        "[dim]Enter 'exit' or 'quit' to quit. Enter 'plans' to list checkpoints.[/dim]",
        border_style="yellow"
    ))

    agent = HermesMusicAgent("config.yaml")

    while True:
        try:
            prompt = console.input("\n[bold green]You:[/bold green] ").strip()
            if not prompt:
                continue
            if prompt.lower() in ["exit", "quit", "q"]:
                console.print("[yellow]Goodbye![/yellow]")
                break
            if prompt.lower() in ["plans", "list"]:
                list_existing_plans()
                continue
            
            agent.run(prompt)

        except KeyboardInterrupt:
            console.print("\n[yellow]Session interrupted. Current plan saved to .hermes/plans/[/yellow]")
            break
        except Exception as e:
            console.print(f"\n[red]Execution error:[/red] {e}")

def run_direct_album(album_name: str, artist_name: str = ""):
    """Directly crawls an entire Album via Hermes Agent"""
    prompt = f"Download full album {album_name}" + (f" by artist {artist_name}" if artist_name else "")
    console.print(Panel(f"[bold]Launching Hermes Agent for Album:[/bold] {album_name} ({artist_name})", style="magenta"))
    agent = HermesMusicAgent("config.yaml")
    agent.run(prompt)

def main():
    parser = argparse.ArgumentParser(description="Hermes Autonomous Music Ingestion Agent")
    parser.add_argument("--album", type=str, help="Download an entire album (e.g. --album 'HVL' --artist 'MCK')")
    parser.add_argument("--artist", type=str, default="", help="Artist name used with --album")
    parser.add_argument("--prompt", "-p", type=str, help="Send a direct prompt to Hermes Agent")
    parser.add_argument("--resume", "-r", type=str, help="Resume execution from saved Plan ID (e.g. --resume hermes_plan_abc123)")
    parser.add_argument("--list-plans", action="store_true", help="List all saved plans in .hermes/plans/")
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
