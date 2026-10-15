# Music App — Backend Services

## 1. Tổng quan

Backend của ứng dụng âm nhạc được chia thành các service theo nghiệp vụ. Mỗi service chịu trách nhiệm rõ ràng cho miền dữ liệu và logic của mình; không tự ý lặp lại nghiệp vụ thuộc service khác.

| Service | Công nghệ định hướng | Trách nhiệm chính |
|---|---|---|
| `music-api-gateway` | Go | Cổng API cho client; xác thực/ủy quyền ở lớp gateway, định tuyến request, rate limit, request ID và logging kỹ thuật. |
| `music-user-service` | NestJS | Tài khoản người dùng, hồ sơ, thiết lập và tùy chọn cá nhân. |
| `music-catalog-service` | NestJS | Metadata bài hát, nghệ sĩ, album, thể loại và thông tin nguồn nhạc. |
| `music-library-service` | NestJS | Thư viện cá nhân, playlist, yêu thích và dữ liệu thư viện cần đồng bộ giữa thiết bị. |
| `music-listening-event-service` | Go | Tiếp nhận và lưu sự kiện/hành vi nghe nhạc; hỗ trợ gửi theo batch, retry và chống ghi trùng. |
| `music-audio-service` | Go | Xử lý tác vụ nền liên quan đến file nhạc: tải từ nguồn được phép, kiểm tra file, trích xuất metadata và phân tích audio khi cần. |

> Công nghệ trong bảng là định hướng kiến trúc hiện tại. Không tự đổi ngôn ngữ/framework hoặc tạo service mới nếu chưa được yêu cầu.

## 2. Trách nhiệm chi tiết

### `music-api-gateway` — Go

**Mục đích:** Cung cấp một entry point cho các client.

- Nhận request từ Flutter và định tuyến đến service tương ứng.
- Thực hiện các concern ở tầng gateway như xác thực token, rate limiting, request ID, logging và timeout.
- Có thể tổng hợp response đơn giản nếu cần.
- Không chứa logic nghiệp vụ sâu của user, catalog, library hay listening events.
- Không proxy luồng dữ liệu audio lớn nếu client có thể truy cập Object Storage/CDN trực tiếp bằng URL có thời hạn.

### `music-user-service` — NestJS

**Mục đích:** Quản lý danh tính và thông tin cá nhân của người dùng.

- Tạo và quản lý hồ sơ người dùng.
- Quản lý thiết lập và tùy chọn cá nhân.
- Cung cấp API để các service/client lấy thông tin user cần thiết theo quyền hạn.
- Là nguồn dữ liệu chính cho thông tin người dùng.
- Không quản lý playlist, catalog bài hát hoặc lịch sử nghe chi tiết.

### `music-catalog-service` — NestJS

**Mục đích:** Quản lý dữ liệu mô tả nội dung âm nhạc.

- Quản lý bài hát, nghệ sĩ, album, thể loại và metadata liên quan.
- Lưu thông tin nguồn/định danh nội dung và tham chiếu đến vị trí lưu file nếu có.
- Cung cấp API tìm kiếm và tra cứu catalog ở phạm vi đã triển khai.
- Phối hợp với `music-audio-service` khi cần xử lý file hoặc cập nhật metadata kỹ thuật.
- Không sở hữu playlist cá nhân hoặc lịch sử hành vi nghe của user.

### `music-library-service` — NestJS

**Mục đích:** Quản lý thư viện âm nhạc riêng của từng người dùng.

- Quản lý playlist và các bài hát trong playlist.
- Quản lý bài hát yêu thích và các mục được người dùng thêm vào thư viện.
- Quản lý dữ liệu thư viện cần đồng bộ giữa các thiết bị.
- Áp dụng quyền sở hữu và quy tắc nghiệp vụ cho dữ liệu cá nhân.
- Tham chiếu đến bài hát trong catalog thay vì tạo bản sao metadata catalog.
- Không trực tiếp xử lý file audio hoặc lưu toàn bộ lịch sử sự kiện nghe.

### `music-listening-event-service` — Go

**Mục đích:** Tiếp nhận và lưu lại hành vi của người dùng trong quá trình sử dụng ứng dụng.

Ví dụ event có thể gồm:

- `PLAY_STARTED`, `PLAY_COMPLETED`
- `PAUSE`, `RESUME`, `SKIP`, `SEEK`, `REPLAY`
- Các sự kiện nghe nhạc khác được định nghĩa trong event schema.

Trách nhiệm:

- Nhận event từ client, hỗ trợ batch upload.
- Kiểm tra schema cơ bản, thời gian event, user/device context và `event_id`.
- Lưu event và chống ghi trùng khi client retry.
- Hỗ trợ đồng bộ offline: client lưu event cục bộ khi mất mạng rồi gửi lên khi kết nối trở lại.
- Không chạy phân tích audio trong luồng nhận event.
- Không trực tiếp quyết định recommendation; các tác vụ phân tích/đề xuất có thể tiêu thụ dữ liệu này sau đó.

### `music-audio-service` — Go

**Mục đích:** Xử lý tác vụ nền liên quan đến file âm thanh, tách khỏi request API cần phản hồi nhanh.

- Quản lý hoặc thực thi job tải file từ nguồn mà ứng dụng được phép truy cập và lưu trữ.
- Kiểm tra tính hợp lệ, định dạng và khả năng đọc của file.
- Trích xuất metadata kỹ thuật như thời lượng, codec, bitrate.
- Khi tính năng cần đến, phân tích BPM, key và energy.
- Chuyển mã audio khi có yêu cầu sản phẩm cụ thể.
- Cập nhật trạng thái job và metadata xử lý vào nơi lưu dữ liệu phù hợp.
- File audio nên nằm trong Object Storage/local storage; database lưu metadata, trạng thái và tham chiếu file, không lưu binary audio lớn trực tiếp.
- Không quản lý playlist, hồ sơ user hoặc lịch sử nghe nhạc.

## 3. Quy ước dữ liệu và tích hợp

- **PostgreSQL:** dữ liệu nghiệp vụ có cấu trúc như user, catalog, playlist và trạng thái job.
- **MongoDB:** có thể dùng làm nơi lưu listening events nếu được chọn trong cấu hình triển khai.
- **Neo4j:** chỉ dùng khi triển khai các truy vấn quan hệ đồ thị cho phân tích/recommendation; chưa mặc định service riêng trong danh sách hiện tại.
- **Redis:** cache dữ liệu có thể tái tạo; không dùng làm nguồn dữ liệu chính.
- **Object Storage:** lưu file audio lớn; PostgreSQL giữ metadata và tham chiếu.
- **Flutter + Drift:** playback, queue và dữ liệu offline cục bộ. Client lưu event vào outbox cục bộ khi offline rồi đồng bộ lên backend.

Các lựa chọn database trên là ranh giới định hướng. Khi triển khai một service, hãy xác nhận database thực tế đã cấu hình trong repository thay vì tự giả định rằng mọi database đều đã được tích hợp.

## 4. Quy tắc dành cho AI khi tạo/sửa code

1. Đọc README này cùng cấu trúc và convention hiện có của repository trước khi sửa code.
2. Chỉ triển khai nghiệp vụ thuộc service đang làm việc; nếu cần nghiệp vụ của service khác, dùng API/event contract rõ ràng thay vì truy cập trực tiếp database của service đó.
3. Không tự tạo service mới, database mới, message broker hoặc framework mới nếu chưa được yêu cầu.
4. Không tự suy đoán API contract, tên bảng, schema, biến môi trường hoặc thư viện đã cài. Kiểm tra code hiện có; nếu chưa được xác định, nêu giả định rõ ràng.
5. Ưu tiên thay đổi nhỏ, đúng phạm vi; không refactor phần không liên quan.
6. Xử lý lỗi, timeout, retry và idempotency ở các luồng có thể được gọi lại hoặc đồng bộ offline.
7. Với listening events, dùng ID duy nhất để chống ghi trùng; không giả định event luôn đến đúng thứ tự.
8. Với audio jobs, lưu trạng thái job và xử lý retry an toàn; không tải hoặc lưu nội dung từ nguồn không được phép.
9. Bổ sung hoặc cập nhật test cho hành vi thay đổi.
10. Nếu yêu cầu làm mờ ranh giới nghiệp vụ hoặc mâu thuẫn với README, hãy nêu điểm chưa rõ trước khi thực hiện thay đổi lớn.

## 5. Những phần chưa mặc định có service riêng

Các nghiệp vụ sau có thể được triển khai bên trong service hiện có hoặc bổ sung sau khi nhu cầu rõ ràng:

- **Recommendation:** chưa có service riêng trong danh sách hiện tại. Ban đầu có thể là module độc lập; dữ liệu listening events và audio analysis là đầu vào, không đồng nghĩa hai service đó phải chứa logic recommendation.
- **AI Talk:** chưa có service riêng trong danh sách hiện tại.
- **Download:** trước mắt thuộc phạm vi job của `music-audio-service` nếu backend thực sự cần tải file. Nếu Flutter chỉ tải trực tiếp về thiết bị, không cần tạo backend download service riêng.
- **Graph synchronization:** chỉ bổ sung khi có use case Neo4j cụ thể.

