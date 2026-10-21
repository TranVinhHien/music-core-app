# Music Core Bruno API Collection

Bộ sưu tập kiểm thử API cho hệ thống microservices Music Core App thông qua Bruno API Client.

## Cấu trúc thư mục

- `auth/`: Đăng ký, đăng nhập, cấp lại token (User Service).
- `user/`: Quản lý thông tin hồ sơ người dùng (User Service).
- `media/`: Tải lên tài sản truyền thông, avatar (User Service).
- `catalog/`: Quản lý danh mục âm nhạc (Catalog Service).
  - `artists/`: CRUD Nghệ sĩ (Create, List, Details, Update, Delete).
  - `albums/`: CRUD Album và quan hệ nghệ sĩ.
  - `tracks/`: CRUD Bài hát, liên kết nghệ sĩ, thể loại, nguồn nhạc.
  - `genres/`: CRUD Thể loại âm nhạc theo dạng cây cha-con.
- `library/`: Quản lý thư viện cá nhân người dùng (Library Service).
  - `playlists/`: CRUD Playlist, thêm/xóa bài hát vào playlist, tự động enrich metadata từ Catalog.
  - `favorites/`: Thêm/xóa bài hát yêu thích, lấy danh sách kèm metadata từ Catalog.
- `listening-events/`: Thu thập sự kiện nghe nhạc thời gian thực (Listening Event Service).
  - `Health Check.bru`: Kiểm tra trạng thái service.
  - `Ingest Batch - Playback Events.bru`: Batch sự kiện playback (`TRACK_STARTED`, `TRACK_PAUSED`, `TRACK_COMPLETED`).
  - `Ingest Batch - Discovery & Search.bru`: Batch sự kiện tìm kiếm (`SEARCH_PERFORMED`).
  - `Ingest Batch - Library & Playlist.bru`: Batch sự kiện thư viện & playlist (`TRACK_FAVORITED`, `TRACK_ADDED_TO_PLAYLIST`, `PLAYLIST_PLAYED`).
  - `Ingest Single Event.bru`: Gửi sự kiện đơn lẻ.

## Hướng dẫn sử dụng

1. Mở thư mục này trong ứng dụng **Bruno**.
2. Chọn Environment: **Local**.
3. Cấu hình biến môi trường (`environments/Local.bru`):
   - `base_url`: `http://localhost:8000` (URL qua API Gateway).
   - `catalog_direct_url`: `http://localhost:3002` (URL kết nối trực tiếp Catalog Service).
   - `library_direct_url`: `http://localhost:3003` (URL kết nối trực tiếp Library Service).
   - `listening_events_direct_url`: `http://localhost:3004` (URL kết nối trực tiếp Listening Event Service).
   - `token`: Bearer access token (lấy từ request login trong thư mục `auth`).