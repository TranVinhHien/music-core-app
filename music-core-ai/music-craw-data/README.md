# ⚡ Hermes Autonomous Music Ingestion Agent

Hệ thống **Hermes Music Agent** cào và nạp dữ liệu âm nhạc thông minh dựa trên kiến trúc **Hermes Agent Pattern**:
1. **Lập Kế Hoạch & Phân Rã Mục Tiêu (Goal Decomposition & Strategic Planner)**:
   - Khi nhận các yêu cầu dữ liệu quy mô lớn (ví dụ: *1000 bài hát Việt Nam nổi tiếng*), Agent không bao giờ dồn 1000 bài vào một prompt duy nhất (tránh lỗi cạn token LLM và hiện tượng "lười" khiến chỉ cào được ~50 bài).
   - Thay vào đó, **Hermes Planner** tự động phân rã mục tiêu 1000 bài thành một **Execution Checklist** gồm các nhiệm vụ chuyên sâu cân đối (ví dụ: 10 Subtasks x 100 bài qua các thể loại, thời kỳ, playlist tiêu biểu).
2. **Execution Checklist Trực Quan Trước Khi Thực Thi**:
   - Trước khi bắt đầu cào bất kỳ bài hát nào, Agent hiển thị bảng **HERMES AGENT EXECUTION CHECKLIST** với trạng thái từng việc: `[⏳ PENDING]`, `[▶ IN PROGRESS]`, `[✓ COMPLETED]`, `[✗ FAILED]`.
   - Lưu trữ snapshot trạng thái vào `.hermes/plans/<plan_id>.json`.
3. **Vòng Lặp Thực Thi Bền Bỉ (Checklist-Driven Autonomous Execution Loop)**:
   - Agent tự động duyệt tuần tự từng nhiệm vụ trong Checklist, thu thập ứng viên theo mini-batch và thực thi liên tục cho đến khi đạt đủ 100% chỉ tiêu (1000/1000 bài).
   - **Global Deduplication Engine**: Tự động lọc trùng lặp tên bài và ca sĩ trên toàn bộ các Subtasks, đảm bảo 1000 bài hoàn toàn độc nhất.
4. **Hỗ Trợ Khôi Phục Phiên (Persistence & Resumption)**:
   - Nếu quá trình cào bị gián đoạn (Ctrl+C, mất mạng...), toàn bộ tiến độ đã được checkpoint trên đĩa. Người dùng có thể tiếp tục chạy từ vị trí đang dở dang với lệnh `python main.py --resume <Plan ID>`.
5. **Bảo Toàn Trọn Vẹn 6 Bộ Công Cụ Hạ Tầng Đang Dùng**:
   - `MetadataService`: iTunes API (Cover Art HD 1400x1400) + Deezer API.
   - `DownloaderService`: Tải stream audio qua `yt-dlp` và transcode sang MP3 320kbps chuẩn hóa.
   - `StorageService`: Upload file audio & ảnh bìa lên AWS S3.
   - `ArtistParser`: Bóc tách đa nghệ sĩ (`PRIMARY` / `FEAT`) chính xác với các tiền tố `&`, `feat.`, `ft.`, `x`.
   - `CatalogService`: Đồng bộ Artist, Album và Track vào NestJS Catalog Microservice (:3002).
   - `AudioAnalyzerService`: Phân tích âm học nâng cao (BPM, Key, Camelot, Cue-in/out, Energy, LUFS) và sync trực tiếp lên API.
   - **3-tier Retry Strategy**: Tự động chuyển đổi 3 chiến lược tìm kiếm trước khi báo lỗi cho từng bài.

---

## 🏗️ Cấu trúc thư mục mới

```
music-craw-data/
├── config.yaml               # Cấu hình Azure OpenAI, Catalog API, AWS S3
├── requirements.txt          # Thư viện Python (openai, mutagen, yt-dlp, boto3, librosa, rich...)
├── hermes/                   # Hermes Agent Core Architecture
│   ├── __init__.py           # Export Hermes Agent components
│   ├── models.py             # Pydantic models (HermesPlan, ChecklistTask, TaskStatus)
│   ├── checklist_manager.py  # Quản lý checklist, render Rich table, persist JSON checkpoint
│   ├── planner.py            # Hermes Planner: Phân rã mục tiêu lớn (1000 bài) thành Checklist
│   ├── candidate_collector.py# Thu thập & làm giàu ứng viên theo mini-batch + deduplication
│   ├── executor.py           # Pipeline 5 bước thực thi (Metadata -> S3 -> Catalog -> Audio Analysis)
│   └── agent.py              # HermesMusicAgent (Điều phối toàn bộ vòng lặp thực thi)
├── workflow.py               # Wrapper tương thích ngược cho AutoWorkflowEngine
├── agent.py                  # Wrapper tương thích ngược cho InteractiveMusicAgent
├── main.py                   # Điểm khởi chạy CLI (Interactive, Prompt, Resume, List Plans)
├── mcp_server.py             # MCP Server JSON-RPC 2.0 stdio
├── services/                 # 6 Core Services hạ tầng
│   ├── artist_parser.py
│   ├── metadata_service.py
│   ├── downloader_service.py
│   ├── storage_service.py
│   ├── catalog_service.py
│   └── audio_analyzer_service.py
├── .hermes/plans/            # Thư mục lưu checkpoint các Execution Plans
└── downloads/                # Nơi lưu file MP3 tạm thời
```

---

## 🚀 Hướng dẫn khởi chạy

### 1. Kích hoạt môi trường
```bash
cd /Users/hienlazada/music-core-app/music-core-ai/music-craw-data
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Chạy Hermes Agent ở chế độ tương tác
```bash
python main.py
```

**Ví dụ lệnh:**
* *"Cào 1000 bài hát Việt Nam nổi tiếng"*
  -> Agent phân tích mục tiêu thành 10 Subtasks (mỗi task 100 bài) đại diện cho các thời kỳ và thể loại.
  -> In ra **Execution Checklist** với trạng thái `[⏳ PENDING]`.
  -> Tự động chạy tuần tự từng việc trong checklist từ bài 1 đến bài 1000 mà không dừng lại ở bài 50!
* *"Tải toàn bộ album HVL của MCK"*
  -> Agent tạo 1 task Album, lấy trọn vẹn 30 bài từ iTunes Lookup.
* *"plans"* hoặc *"list"*
  -> Hiển thị các Plan ID đã lưu.

### 3. Tiếp tục chạy lại một Kế hoạch dở dang (Resume Mode)
```bash
python main.py --resume hermes_plan_a1b2c3d4
```

### 4. Chạy trực tiếp qua dòng lệnh
```bash
python main.py --prompt "50 bài ballad buồn hay nhất"
```
```bash
python main.py --album "HVL" --artist "MCK"
```
```bash
python main.py --list-plans
```
