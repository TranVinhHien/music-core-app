# 🎵 Music Auto Workflow & Catalog Ingestion Engine

Hệ thống **Auto Workflow Engine** cào dữ liệu âm nhạc thông minh:
1. **Phân tích yêu cầu tự nhiên (Intent Analysis)**: Dùng Azure OpenAI (GPT-4o) để bóc tách loại yêu cầu (`ALBUM`, `ARTIST_TOP`, `SONG_LIST`), tên ca sĩ, tên album và số lượng cần tải.
2. **Khám phá trọn vẹn 100% Tracklist**: Sử dụng iTunes Lookup API & Deezer API để trích xuất toàn bộ bài hát trong album (ví dụ trọn vẹn 30 bài của album *HVL*), không bị giới hạn cố định 5-10 bài.
3. **Bóc tách đa nghệ sĩ (PRIMARY & FEAT)**: Nhận diện chính xác các ca sĩ hợp tác (`&`, `,`, `feat.`, `ft.`, `x`, `vs`). Tự động tạo bản ghi riêng cho từng nghệ sĩ trong PostgreSQL và liên kết với vai trò `PRIMARY` hoặc `FEAT`.
4. **Quy trình tự động hóa liên tục (Autonomous Ingestion Pipeline)**:
   - Tải audio stream qua `yt-dlp` -> convert/tag ID3 + Cover Art HD 1400x1400 bằng `mutagen`.
   - Upload file âm thanh lên AWS S3 (`travel-app-dev-123125345634`) -> lấy `file_url`.
   - Tự động tạo / gắn Album và Track vào Catalog Microservice backend (:3002).
5. **Cơ chế Thử lại & Đổi phương án (Tối đa 3 lần)**: Nếu gặp lỗi tải, thiếu metadata hoặc lỗi mạng, hệ thống tự động đổi chiến lược tìm kiếm và retry tối đa 3 lần bằng các phương án dự phòng khác nhau trước khi bỏ cuộc.
6. **Hiển thị tiến độ trực quan**: Bảng Kế hoạch chi tiết trước khi tải, thanh tiến độ từng bài và Bảng Báo cáo tổng kết.

---

## 🏗️ Cấu trúc thư mục

```
music-craw-data/
├── config.yaml               # Cấu hình Azure OpenAI, Catalog API, AWS S3
├── requirements.txt          # Thư viện Python
├── workflow.py               # Auto Workflow Engine (Phân tích intent & điều phối tự động)
├── main.py                   # Điểm khởi chạy CLI (Interactive & Direct mode)
├── mcp_server.py             # Máy chủ Model Context Protocol (MCP) qua stdio
├── services/
│   ├── artist_parser.py      # Bóc tách đa ca sĩ & phân loại PRIMARY / FEAT
│   ├── metadata_service.py   # Tra cứu full tracklist của Album và metadata chuẩn
│   ├── downloader_service.py # Tải audio & nhúng ID3 tag + cover art
│   ├── storage_service.py    # Upload file lên AWS S3
│   └── catalog_service.py    # Đăng ký Artist, Album, Track vào NestJS Catalog API
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

### 2. Chạy Auto Workflow tương tác tự nhiên
```bash
python main.py
```

**Ví dụ lệnh:**
* *"Tải cho tôi toàn bộ album HVL của ca sĩ rapper MCK. Album này có bao nhiêu tải hết cho tôi"*
  -> Engine sẽ tự tìm ra **toàn bộ 30 bài hát** trong album HVL, hiển thị bảng kế hoạch và tự động chạy từ bài 1 đến bài 30 mà không bị dừng hay ngắt quãng.
* *"Tải bài Giấc Mơ Trưa của Ánh Minh & Thùy Hương"*
  -> Engine sẽ tự tách `Ánh Minh` (PRIMARY) và `Thùy Hương` (PRIMARY), tạo 2 Artist riêng và gắn vào Track.
* *"Tải bài Huh của RPT MCK feat. RPT Orijinn & Thành Draw"*
  -> Engine sẽ tách `RPT MCK` (PRIMARY), `RPT Orijinn` (FEAT), `Thành Draw` (FEAT).

### 3. Chạy trực tiếp 1 Album qua cờ CLI
```bash
python main.py --album "HVL" --artist "MCK"
```
