# 🎵 Music Crawler & Catalog Ingestion Agent

Hệ thống **Interactive AI Agent** kết hợp **MCP (Model Context Protocol)** chuyên xử lý:
1. Nhận yêu cầu từ người dùng bằng ngôn ngữ tự nhiên và **tự động lập kế hoạch (Planning)**.
2. Tìm kiếm và cào metadata bài hát chuẩn mực (iTunes / Deezer).
3. Tìm nguồn audio stream (YouTube / SoundCloud), tải và convert sang MP3 320kbps.
4. Gắn thẻ ID3 metadata (Title, Artist, Album, Year, Genre) và nhúng **Album Cover Art HD**.
5. **Upload file âm thanh lên hệ thống lưu trữ (AWS S3)** để nhận URL lưu trữ vĩnh viễn (`file_url`).
6. **Đồng bộ tự động vào Backend Catalog Microservice** (`music-catalog-service`): Tạo Artist, Album và gắn Track mới.

---

## 🏗️ Kiến trúc & Luồng xử lý (Workflow)

```
[User Yêu Cầu] ──> (Agent Phân Tích & Lập Plan)
                            │
        ┌───────────────────┴───────────────────┐
        ▼                                       ▼
1. Metadata Tool (iTunes/Deezer)        2. Audio Stream (YouTube / yt-dlp)
- Lấy thông tin chuẩn mực               - Tải audio & convert MP3 320kbps
- Ảnh bìa HD 1400x1400                  - Nhúng ID3 tags + Cover Art (mutagen)
        └───────────────────┬───────────────────┘
                            ▼
3. Storage Tool (AWS S3 / MinIO)
- Upload file MP3 + Cover Art lên Bucket
- Nhận URL lưu trữ công khai (`file_url`)
                            ▼
4. Catalog Sync Tool (NestJS API :3002)
- Kiểm tra / Tạo Artist (`POST /api/v1/catalog/artists`)
- Kiểm tra / Tạo Album (`POST /api/v1/catalog/albums`)
- Đăng ký Track (`POST /api/v1/catalog/tracks`)
                            ▼
(Agent Báo Cáo Kết Quả & Tiếp Tục Hội Thoại)
```

---

## 📁 Cấu trúc thư mục

```
music-craw-data/
├── config.yaml               # Cấu hình Azure OpenAI, Catalog API URL, AWS S3
├── requirements.txt          # Danh sách thư viện Python
├── agent.py                  # AI Agent tương tác, lập kế hoạch và điều phối Tool
├── main.py                   # Giao diện dòng lệnh (CLI Interactive với Rich UI)
├── mcp_server.py             # Máy chủ MCP (Model Context Protocol qua stdio)
├── services/
│   ├── metadata_service.py   # Tìm kiếm bài hát và metadata chuẩn
│   ├── downloader_service.py # Tải audio stream và nhúng ID3/Cover
│   ├── storage_service.py    # Upload file lên AWS S3 / Local
│   └── catalog_service.py    # Giao tiếp với API Catalog Microservice
└── downloads/                # Thư mục chứa file MP3 cục bộ
```

---

## ⚙️ Cấu hình (`config.yaml`)

```yaml
azure_openai:
  endpoint: "https://svhc-ai-foundry-staging.cognitiveservices.azure.com"
  api_key: "" # Điền key hoặc export AZURE_OPENAI_API_KEY
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

## 🚀 Hướng dẫn khởi chạy

### 1. Cài đặt môi trường
```bash
cd /Users/hienlazada/music-core-app/music-core-ai/music-craw-data
source .venv/bin/activate
pip install -r requirements.txt
```

*(Khuyến nghị cài `brew install ffmpeg` để convert MP3 320kbps)*

---

### 2. Chạy Agent tương tác thông minh (Chat & Plan)
```bash
python main.py
```
**Ví dụ tương tác:**
> **Bạn:** *"Tôi muốn thêm 2 bài hát 'Nơi này có anh' của Sơn Tùng M-TP và 'Waiting For You' của MONO vào catalog hệ thống."*
>
> **Agent:**
> 1. Trình bày bảng Kế hoạch thực thi (Plan).
> 2. Tự động cào metadata từng bài.
> 3. Tự động tải audio và nhúng ID3 tag + Cover Art.
> 4. Tự động upload lên S3 lấy link `file_url`.
> 5. Tự động gọi API `music-catalog-service` tạo Artist, Album, Track.
> 6. Thông báo kết quả và hỏi bạn có cần tải thêm bài nào không.

---

### 3. Chạy Pipeline trực tiếp một bài hát (Không tốn token LLM)
```bash
python main.py --crawl "Waiting For You" --artist "MONO"
```

---

### 4. Tích hợp như một MCP Server
File `mcp_server.py` tuân thủ chuẩn JSON-RPC 2.0 stdio của Model Context Protocol. Bạn có thể thêm vào cấu hình IDE / Agent Client:

```json
{
  "mcpServers": {
    "music-crawler": {
      "command": "python",
      "args": ["/Users/hienlazada/music-core-app/music-core-ai/music-craw-data/mcp_server.py"]
    }
  }
}
```
Các tool MCP được expose:
- `search_music_online`
- `get_song_metadata`
- `download_and_tag_song`
- `upload_audio_to_storage`
- `register_track_to_catalog`
- `pipeline_crawl_and_register`
