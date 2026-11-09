# Music Listening - Audio Transition Analyzer (AI Engine)

Module phân tích âm học và điểm chuyển bài (Transition & Cue Points) phục vụ cho hệ thống nghe nhạc thông minh (Auto DJ / Smart Crossfade) thuộc Cấp 3 của Personal Music App.

## Tính năng
- **Silence Trimming & Cue Points**: Tự động phát hiện và cắt bỏ khoảng lặng đầu/cuối bài, tính toán `cue_in_ms` (thời điểm nhạc bắt đầu) và `cue_out_ms` (thời điểm chuyển tiếp sang bài mới).
- **Rhythm & Beat Matching**: Đo `bpm`, mốc phách 1 đầu tiên (`first_downbeat_ms`) và danh sách các downbeat (`downbeats`) giúp trình phát nhảy bài đúng nhịp.
- **Harmonic Mixing**: Phân tích tông nhạc (`key`, `scale`) và tự động ánh xạ sang mã vòng tròn Camelot (`camelot_key`, ví dụ: `8A`, `3A`) giúp hòa âm không bị chói tai.
- **Dynamic Normalization**: Ước tính mức năng lượng (`energy` từ 0.0 đến 1.0) và độ lớn âm thanh theo chuẩn EBU R128 (`loudness_lufs`).
- **Transition Strategy**: Đề xuất kiểu chuyển tiếp (`recommended_transition`) và thời lượng crossfade lý tưởng (`recommended_crossfade_ms`).
- **Đa định dạng âm thanh**: Tương thích tốt với `.mp3`, `.m4a`, `.aac`, `.wav`, `.flac` nhờ cơ chế fallback thông minh (sử dụng CoreAudio `afconvert` trên macOS hoặc `ffmpeg`).

## Cài đặt môi trường

```bash
cd music-core-ai/music-listening
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Cách sử dụng (CLI)

### 1. Phân tích 1 bài và in JSON ra màn hình:
```bash
python main.py --file "/path/to/song.m4a" --track-id "111"
```

### 2. Thu gọn danh sách downbeats (chỉ lấy các chỉ số cốt lõi):
```bash
python main.py --file "/path/to/song.m4a" --track-id "111" --omit-downbeats
```

### 3. Lưu kết quả ra file JSON:
```bash
python main.py --file "/path/to/song.m4a" --track-id "111" --output "/path/to/result.json"
```

### 4. Đồng bộ tự động với Catalog Service (Sync Worker):
Worker sẽ tự động gọi API `GET /api/v1/catalog/tracks?analysisStatus=PENDING` lấy các bài hát chưa phân tích, tải audio, phân tích các chỉ số và gọi `PUT /api/v1/catalog/tracks/:id/audio-analysis` để cập nhật lại vào cơ sở dữ liệu:

```bash
# Phân tích một lượt (batch) 5 bài:
python sync_worker.py --limit 5

# Chạy dạng daemon lắng nghe liên tục:
python sync_worker.py --loop --interval 15
```

## Cấu trúc dữ liệu JSON đầu ra

```json
{
  "track_id": "111",
  "file_path": "/path/to/song.m4a",
  "duration_ms": 204519,
  "cue_in_ms": 812,
  "cue_out_ms": 198623,
  "bpm": 172.3,
  "first_downbeat_ms": 812,
  "key": "A#",
  "scale": "Minor",
  "camelot_key": "3A",
  "energy": 0.41,
  "loudness_lufs": -14.4,
  "recommended_transition": "SMOOTH_FADE",
  "recommended_crossfade_ms": 5896,
  "analyzed_at": "2026-10-22T13:10:36.041709+00:00"
}
```
