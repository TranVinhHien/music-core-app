# ⚡ Hermes Autonomous Music Ingestion Agent

The **Hermes Music Agent** is an autonomous music ingestion and catalog curation system built on the **Hermes Agent Pattern**:
1. **Goal Decomposition & Strategic Planner**:
   - For high-volume music ingestion targets (e.g., *1,000 famous songs*), the Agent never packs 1,000 items into a single LLM prompt (preventing context window depletion and truncation errors).
   - Instead, the **Hermes Planner** breaks down the target into a structured **Execution Checklist** consisting of balanced subtasks (e.g., 10 Subtasks x 100 tracks spanning distinct genres, decades, and playlists).
2. **Visual Pre-Execution Checklist**:
   - Before executing any download tasks, the Agent renders the **HERMES AGENT EXECUTION CHECKLIST** in the terminal with live task statuses: `[⏳ PENDING]`, `[▶ IN PROGRESS]`, `[✓ COMPLETED]`, `[✗ FAILED]`.
   - Persists state snapshots to `.hermes/plans/<plan_id>.json`.
3. **Checklist-Driven Autonomous Execution Loop**:
   - Sequentially iterates through checklist tasks, collects candidates in mini-batches, and executes end-to-end ingestion until 100% of the target quota is achieved.
   - **Global Deduplication Engine**: Automatically filters duplicate title and artist pairs across all subtasks, ensuring 100% unique tracks.
4. **Session Persistence & Resumption**:
   - If an ingestion session is interrupted (Ctrl+C, network timeout, etc.), all progress is safely checkpointed to disk. Resume anytime using `python main.py --resume <Plan ID>`.
5. **Integrated Infrastructure Services**:
   - `MetadataService`: iTunes API (HD Cover Art 1400x1400) + Deezer API.
   - `DownloaderService`: Streams audio via `yt-dlp` and transcodes to standard 320kbps MP3.
   - `StorageService`: Uploads audio assets and cover art to AWS S3.
   - `ArtistParser`: Multi-artist extraction (`PRIMARY` / `FEAT`) supporting prefixes `&`, `feat.`, `ft.`, `x`.
   - `CatalogService`: Synchronizes Artists, Albums, and Tracks with NestJS Catalog Microservice (:3002).
   - `AudioAnalyzerService`: Advanced acoustic feature extraction (BPM, Key, Camelot, Cue-in/out, Energy, LUFS) with direct API synchronization.
   - **3-tier Search Fallback**: Automatically tries 3 fallback query strategies before marking a candidate failed.

---

## 🏗️ Directory Structure

```text
music-craw-data/
├── config.yaml               # Azure OpenAI, Catalog API, AWS S3 configuration
├── requirements.txt          # Python dependencies (openai, mutagen, yt-dlp, boto3, librosa, rich...)
├── hermes/                   # Hermes Agent Core Architecture
│   ├── __init__.py           # Export Hermes Agent components
│   ├── models.py             # Pydantic models (HermesPlan, ChecklistTask, TaskStatus)
│   ├── checklist_manager.py  # Checklist management, Rich table rendering, JSON checkpoints
│   ├── planner.py            # Hermes Planner: Goal decomposition into Checklist tasks
│   ├── candidate_collector.py# Mini-batch candidate collection & deduplication
│   ├── executor.py           # 5-step execution pipeline (Metadata -> S3 -> Catalog -> Audio Analysis)
│   └── agent.py              # HermesMusicAgent (Coordinates full execution loop)
├── workflow.py               # Backward-compatible wrapper for AutoWorkflowEngine
├── agent.py                  # Backward-compatible wrapper for InteractiveMusicAgent
├── main.py                   # CLI entry point (Interactive, Prompt, Resume, List Plans)
├── mcp_server.py             # MCP Server JSON-RPC 2.0 stdio
├── services/                 # 6 Core infrastructure services
│   ├── artist_parser.py
│   ├── metadata_service.py
│   ├── downloader_service.py
│   ├── storage_service.py
│   ├── catalog_service.py
│   └── audio_analyzer_service.py
├── .hermes/plans/            # Execution plan checkpoint storage
└── downloads/                # Temporary local MP3 cache directory
```

---

## 🚀 Getting Started

### 1. Environment Setup
```bash
cd music-core-ai/music-craw-data
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Run Hermes Agent in Interactive Mode
```bash
python main.py
```

**Example Commands:**
* *"Crawl 1000 popular pop songs"*
  -> Agent breaks down the goal into 10 Subtasks (100 tracks each) spanning various eras and subgenres.
  -> Displays the **Execution Checklist** with `[⏳ PENDING]` statuses.
  -> Automatically executes all tasks from track 1 to 1000 without hitting token limits.
* *"Download entire album HVL by MCK"*
  -> Agent creates a single Album task and fetches all 30 tracks via iTunes Lookup.
* *"plans"* or *"list"*
  -> Displays all saved plan IDs.

### 3. Resume an Interrupted Plan (Resume Mode)
```bash
python main.py --resume hermes_plan_a1b2c3d4
```

### 4. Run Directly via CLI
```bash
python main.py --prompt "Top 50 acoustic songs"
```
```bash
python main.py --album "HVL" --artist "MCK"
```
```bash
python main.py --list-plans
```
