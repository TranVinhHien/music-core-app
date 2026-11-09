import os
import yaml
from typing import Dict, Any, Optional, List
from rich.console import Console

from hermes import HermesMusicAgent, HermesPlan

console = Console()

class InteractiveMusicAgent:
    """
    Backward-compatible wrapper for legacy interface:
    Delegates all requests to the HermesMusicAgent architecture with Checklist planning,
    task decomposition, and persistent execution until 100% quota is reached.
    """

    def __init__(self, config_path: str = "config.yaml"):
        self.config_path = config_path
        self.hermes = HermesMusicAgent(config_path=config_path)

    def chat(self, user_input: str) -> str:
        """Executes via Hermes Agent Engine and returns summary report."""
        plan = self.hermes.run(user_input)
        return (
            f"Completed plan '{plan.goal}'. "
            f"Total tracks processed successfully: {plan.total_crawled_count}/{plan.total_target_count}."
        )

# Re-export HermesMusicAgent as standard
__all__ = ["HermesMusicAgent", "InteractiveMusicAgent", "HermesPlan"]
