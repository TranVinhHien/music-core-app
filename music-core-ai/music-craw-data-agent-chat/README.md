# 🎵 Music Crawler & Catalog Ingestion Agent

An **Interactive AI Agent** powered by **MCP (Model Context Protocol)** designed for:
1. Processing natural language user requests and **autonomous plan execution (Planning)**.
2. Standardized music metadata retrieval and scraping (iTunes / Deezer).
3. Audio stream resolution (YouTube / SoundCloud), downloading, and conversion to 320kbps MP3.
4. ID3 tag writing (Title, Artist, Album, Year, Genre) and embedding **HD Album Cover Art**.
5. **Uploading audio assets to cloud storage (AWS S3)** to obtain persistent storage URLs (`file_url`).
6. **Automated synchronization with Backend Catalog Microservice** (`music-catalog-service`): Creates Artists, Albums, and registers Tracks.

---

## 🏗️ Architecture & Processing Workflow

```text
[User Request] ──> (Agent Reasoning & Planning)
                           │
       ┌───────────────────┴───────────────────┐
       ▼                                       ▼
1. Metadata Tool (iTunes/Deezer)        2. Audio Stream (YouTube / yt-dlp)
- Fetch standard metadata               - Download audio & convert to 320kbps MP3
- HD Cover Art 1400x1400                - Embed ID3 tags + Cover Art (mutagen)
       └───────────────────┬───────────────────┘
                           ▼
3. Storage Tool (AWS S3 / MinIO)
- Upload MP3 audio file & Cover Art to Bucket
- Retrieve public asset storage URL (`file_url`)
                           ▼
4. Catalog Sync Tool (NestJS API :3002)
- Check / Create Artist (`POST /api/v1/catalog/artists`)
- Check / Create Album (`POST /api/v1/catalog/albums`)
- Register Track (`POST /api/v1/catalog/tracks`)
                           ▼
(Agent Reports Results & Continues Conversation)
```

---

## 📁 Directory Structure

```text
music-craw-data-agent-chat/
├── config.yaml               # Azure OpenAI, Catalog API URL, AWS S3 configuration
├── requirements.txt          # Python dependencies
├── agent.py                  # Interactive AI Agent, planning and tool orchestrator
├── main.py                   # Command-line interface (Interactive CLI with Rich UI)
├── mcp_server.py             # Model Context Protocol (MCP) server over stdio
├── services/
│   ├── metadata_service.py   # Song search and standardized metadata
│   ├── downloader_service.py # Audio stream downloading, tagging, and cover art
│   ├── storage_service.py    # AWS S3 / Local storage upload
│   └── catalog_service.py    # Integration with Catalog Microservice API
└── downloads/                # Local cache directory for audio files
```

---

## ⚙️ Configuration (`config.yaml`)

```yaml
azure_openai:
  endpoint: "https://svhc-ai-foundry-staging.cognitiveservices.azure.com"
  api_key: "" # Provide key or export AZURE_OPENAI_API_KEY
  gpt4o_version: "2024-08-01-preview"
  gpt4o_deployment: "gpt-4o-vision"

backend:
  catalog_api_url: "http://localhost:3002/api/v1/catalog"

storage:
  download_dir: "./downloads"
  use_s3: true
  aws:
    region: ""
    access_key_id: ""
    secret_access_key: ""
    bucket_name: ""
```

---

## 🚀 Getting Started

### 1. Environment Setup
```bash
cd music-core-ai/music-craw-data-agent-chat
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

*(Installing `ffmpeg` via package manager is recommended for 320kbps MP3 conversion)*

---

### 2. Run Interactive Agent (Chat & Plan Mode)
```bash
python main.py
```
**Example Interaction:**
> **User:** *"I want to add the songs 'Noi Nay Co Anh' by Son Tung M-TP and 'Waiting For You' by MONO to the system catalog."*
>
> **Agent:**
> 1. Displays execution checklist and plan.
> 2. Scrapes canonical metadata for each song.
> 3. Downloads audio stream and embeds ID3 tags + Cover Art.
> 4. Uploads to S3 to obtain `file_url`.
> 5. Calls `music-catalog-service` to create Artist, Album, and Track records.
> 6. Summarizes results and prompts for subsequent actions.

---

### 3. Run Pipeline Directly for a Single Track (Zero LLM Tokens)
```bash
python main.py --crawl "Waiting For You" --artist "MONO"
```

---

### 4. Integration as an MCP Server
The `mcp_server.py` implements JSON-RPC 2.0 stdio Model Context Protocol. You can add it to your IDE or Agent Client configuration:

```json
{
  "mcpServers": {
    "music-crawler": {
      "command": "python",
      "args": ["music-core-ai/music-craw-data-agent-chat/mcp_server.py"]
    }
  }
}
```
Exposed MCP tools:
- `search_music_online`
- `get_song_metadata`
- `download_and_tag_song`
- `upload_audio_to_storage`
- `register_track_to_catalog`
- `pipeline_crawl_and_register`
