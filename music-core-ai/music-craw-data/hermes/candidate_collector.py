import os
import json
import yaml
from typing import Dict, Any, List, Set, Optional
from openai import AzureOpenAI
from rich.console import Console

from services.metadata_service import MetadataService
from hermes.models import ChecklistTask
from hermes.checklist_manager import HermesChecklistManager

console = Console()

class HermesCandidateCollector:
    """
    Candidate track collector and metadata enrichment engine:
    - Provides target track candidates according to each checklist task.
    - Partitions collection into mini-batches (30-50 tracks) to avoid truncation or context window exhaustion.
    - Integrates with iTunes Search & Deezer API to enrich canonical metadata (HD Cover, Album, Year).
    - Automatically deduplicates against global seen tracks cache.
    """

    def __init__(self, config_or_path: Any = "config.yaml"):
        if isinstance(config_or_path, str):
            self.config = self._load_config(config_or_path)
        else:
            self.config = config_or_path or {}

        azure_cfg = self.config.get("azure_openai", {})
        endpoint = azure_cfg.get("endpoint")
        api_key = os.environ.get("AZURE_OPENAI_API_KEY") or azure_cfg.get("api_key")
        api_version = azure_cfg.get("gpt4o_version", "2024-08-01-preview")
        self.deployment_name = azure_cfg.get("gpt4o_deployment", "gpt-4o-vision")

        self.client = AzureOpenAI(
            azure_endpoint=endpoint,
            api_key=api_key or "DUMMY_KEY",
            api_version=api_version,
        )

    def _load_config(self, config_path: str) -> Dict[str, Any]:
        if os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        return {}

    def collect_for_task(self, task: ChecklistTask, seen_keys: Set[str]) -> List[Dict[str, Any]]:
        """
        Collects and enriches tracks for a specific checklist task.
        Guarantees deduplication against seen_keys and aims to reach task.target_count.
        """
        target_count = task.target_count
        console.print(f"[dim cyan]🔍 [Collector] Collecting {target_count} tracks for task: '{task.title}'...[/dim cyan]")

        raw_candidates: List[Dict[str, str]] = []

        # 1. Specific Album task
        if task.intent_type == "ALBUM" and task.album_name:
            console.print(f"[dim]Resolving Album tracklist: '{task.album_name}' ({task.artist_name or ''})...[/dim]")
            album_tracks = MetadataService.get_album_tracks(task.album_name, task.artist_name or "")
            for t in album_tracks:
                title = t.get("title", "")
                artist = t.get("artist", "")
                if not HermesChecklistManager.normalize_track_key(title, artist) in seen_keys:
                    raw_candidates.append({"title": title, "artist": artist})
            # If all tracks are found via iTunes, return directly after deduplication
            if raw_candidates:
                return self._enrich_metadata_list(raw_candidates[:target_count], task)

        # 2. Artist Top tracks task
        elif task.intent_type == "ARTIST_TOP" and task.artist_name:
            limit = min(50, target_count)
            results = MetadataService.search_candidates(task.artist_name, limit=limit)
            for r in results:
                title = r.get("title", "")
                artist = r.get("artist", "")
                if not HermesChecklistManager.normalize_track_key(title, artist) in seen_keys:
                    raw_candidates.append({"title": title, "artist": artist})

        # 3. Curated Batch / Genre / Broad Theme: Use mini-batching to ensure completeness
        batch_size = 40  # Safe size for GPT-4o output without hitting generation limits
        collected_in_task: List[Dict[str, str]] = []
        
        # Start with pre-collected candidates
        for item in raw_candidates:
            key = HermesChecklistManager.normalize_track_key(item["title"], item["artist"])
            if key not in seen_keys and all(HermesChecklistManager.normalize_track_key(x["title"], x["artist"]) != key for x in collected_in_task):
                collected_in_task.append(item)

        attempts = 0
        max_attempts = 4

        while len(collected_in_task) < target_count and attempts < max_attempts:
            attempts += 1
            needed = target_count - len(collected_in_task)
            current_ask = min(batch_size, needed)

            console.print(f"[dim]⚡ [LLM Batch {attempts}] Curating {current_ask} more tracks for '{task.title}' ({len(collected_in_task)}/{target_count} ready)...[/dim]")

            # Sample of existing tracks to avoid LLM duplication
            sample_existing = [f"{t['title']} ({t['artist']})" for t in collected_in_task[-20:]]

            llm_candidates = self._ask_llm_for_candidates(
                task_title=task.title,
                task_desc=task.description,
                category=task.category,
                query_hints=task.query_hints,
                count=current_ask,
                existing_sample=sample_existing
            )

            new_added = 0
            for cand in llm_candidates:
                t_name = cand.get("title", "").strip()
                a_name = cand.get("artist", "").strip()
                if not t_name:
                    continue
                key = HermesChecklistManager.normalize_track_key(t_name, a_name)
                if key not in seen_keys and all(HermesChecklistManager.normalize_track_key(x["title"], x["artist"]) != key for x in collected_in_task):
                    collected_in_task.append({"title": t_name, "artist": a_name})
                    new_added += 1
                    if len(collected_in_task) >= target_count:
                        break

            if new_added == 0:
                # If LLM yields no new candidates, fallback to query hints via iTunes
                for hint in task.query_hints:
                    if len(collected_in_task) >= target_count:
                        break
                    api_res = MetadataService.search_candidates(hint, limit=10)
                    for r in api_res:
                        t_name = r.get("title", "").strip()
                        a_name = r.get("artist", "").strip()
                        key = HermesChecklistManager.normalize_track_key(t_name, a_name)
                        if key not in seen_keys and all(HermesChecklistManager.normalize_track_key(x["title"], x["artist"]) != key for x in collected_in_task):
                            collected_in_task.append({"title": t_name, "artist": a_name})
                            if len(collected_in_task) >= target_count:
                                break
                break

        # 4. Canonical Metadata Enrichment
        final_list = self._enrich_metadata_list(collected_in_task[:target_count], task)
        console.print(f"[green]✓ [Collector] Prepared {len(final_list)}/{target_count} high-quality candidates for '{task.title}'.[/green]")
        return final_list

    def _ask_llm_for_candidates(
        self,
        task_title: str,
        task_desc: str,
        category: str,
        query_hints: List[str],
        count: int,
        existing_sample: List[str]
    ) -> List[Dict[str, str]]:
        """Calls LLM to curate tracks for a specific mini-batch."""
        hints_str = ", ".join(query_hints) if query_hints else task_title
        avoid_str = "; ".join(existing_sample) if existing_sample else "None"

        prompt = (
            f"You are an expert music curator.\n"
            f"Please curate exactly {count} top, most representative songs for the theme:\n"
            f"• Title: {task_title}\n"
            f"• Description: {task_desc}\n"
            f"• Category: {category}\n"
            f"• Query Hints: {hints_str}\n"
            f"• ALREADY CURATED (DO NOT REPEAT): {avoid_str}\n\n"
            f"Requirements:\n"
            f"- Return a list of exactly {count} songs with accurate titles and artists.\n"
            f"- Return ONLY JSON conforming to the following structure:\n"
            f'{{"tracks": [{{"title": "Song Title", "artist": "Artist Name"}}]}}'
        )

        try:
            resp = self.client.chat.completions.create(
                model=self.deployment_name,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
                response_format={"type": "json_object"}
            )
            content = resp.choices[0].message.content or "{}"
            parsed = json.loads(content)
            return parsed.get("tracks", [])
        except Exception as e:
            console.print(f"[yellow]⚠️ Mini-batch LLM error: {e}[/yellow]")
            return []

    def _enrich_metadata_list(self, candidates: List[Dict[str, str]], task: ChecklistTask) -> List[Dict[str, Any]]:
        """Queries iTunes & Deezer for HD Cover Art 1400x1400, Album, Year, Track number."""
        enriched: List[Dict[str, Any]] = []

        for item in candidates:
            title = item.get("title", "").strip()
            artist = item.get("artist", "").strip()
            if not title:
                continue

            meta = None
            search_queries = [
                f"{title} {artist}".strip(),
                f"{title.split('(')[0].strip()} {artist}".strip(),
                title.split('(')[0].strip()
            ]

            for q in search_queries:
                meta = MetadataService.get_metadata(q)
                if meta:
                    break

            if meta:
                # Supplement missing album name if available in task
                if not meta.get("album") and task.album_name:
                    meta["album"] = task.album_name
                enriched.append(meta)
            else:
                # Fallback normalization if not found on iTunes
                enriched.append({
                    "source": "curated_hermes",
                    "title": title,
                    "artist": artist or task.artist_name or "Unknown Artist",
                    "album": task.album_name or task.category or "Single",
                    "cover_url": "",
                    "year": "",
                    "release_date": "",
                    "duration_ms": 0,
                    "track_number": 1,
                    "disc_number": 1
                })

        return enriched

