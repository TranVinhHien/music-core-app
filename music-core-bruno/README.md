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

## Hướng dẫn sử dụng

1. Mở thư mục này trong ứng dụng **Bruno**.
2. Chọn Environment: **Local**.
3. Cấu hình biến môi trường (`environments/Local.bru`):
   - `base_url`: `http://localhost:8000` (URL qua API Gateway).
   - `catalog_direct_url`: `http://localhost:3002` (URL kết nối trực tiếp Catalog Service).
   - `library_direct_url`: `http://localhost:3003` (URL kết nối trực tiếp Library Service).
   - `token`: Bearer access token (lấy từ request login trong thư mục `auth`).