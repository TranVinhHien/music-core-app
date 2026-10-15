# 🎵 Personal Music App — Tổng hợp chức năng

## 🌟 1. Tổng quan

Ứng dụng nghe nhạc cá nhân, ưu tiên **nghe nhạc offline** và quản lý thư viện nhạc riêng của người dùng.

Ứng dụng có 4 cấp chức năng:

1. 🎵 **Cấp 1 — Cơ bản:** nghe và quản lý nhạc.
2. 🧠 **Cấp 2 — Cá nhân hóa:** kết nối Internet, tải nhạc và xây dựng thư viện theo sở thích.
3. 🚀 **Cấp 3 — Nâng cao / Thông minh:** tự động lựa chọn, sắp xếp và chuyển bài để tạo trải nghiệm nghe nhạc liền mạch.
4. 🤖 **AI Talk — Trợ lý AI:** người dùng nói hoặc chat với AI để thực hiện các chức năng trong ứng dụng.

---

# 🎵 2. Cấp 1 — Chức năng cơ bản

## ▶️ 2.1. Trình phát nhạc

Các chức năng cơ bản để nghe nhạc:

- ▶️ Phát / Tạm dừng
- ⏭️ Bài tiếp theo / Bài trước
- ⏩ Tua đến vị trí bất kỳ
- 🔊 Điều chỉnh âm lượng
- 🔀 Phát ngẫu nhiên
- 🔁 Lặp lại bài hát / danh sách

## 📋 2.2. Danh sách chờ

Quản lý các bài hát sẽ phát tiếp theo:

- 👀 Xem danh sách chờ
- ➕ Thêm bài vào hàng đợi
- ⏭️ Phát bài tiếp theo
- ❌ Xóa bài khỏi hàng đợi
- ↕️ Thay đổi thứ tự bài hát

## 📚 2.3. Thư viện nhạc

Tổ chức toàn bộ nhạc trên thiết bị:

- 🎵 Bài hát
- 🎤 Nghệ sĩ
- 💿 Album
- 🎸 Thể loại
- ❤️ Bài hát yêu thích

## 🎼 2.4. Playlist

Người dùng có thể tự tạo danh sách nhạc:

- ➕ Tạo playlist
- ✏️ Đổi tên playlist
- ➕ Thêm bài hát
- ❌ Xóa bài hát
- 🗑️ Xóa playlist
- ▶️ Phát toàn bộ playlist

## 🔍 2.5. Tìm kiếm

Tìm kiếm nhanh trong thư viện theo:

- 🎵 Tên bài hát
- 🎤 Nghệ sĩ
- 💿 Album
- 🎸 Thể loại

## ❤️ 2.6. Yêu thích

Đánh dấu bài hát yêu thích để dễ dàng tìm và nghe lại.

## 🕘 2.7. Lịch sử nghe

Lưu lại các bài đã nghe:

- 🕘 Bài nghe gần đây
- 🔢 Số lần phát
- 📅 Thời điểm nghe gần nhất

## 📥 2.8. Nghe offline

Sau khi nhạc đã có trên thiết bị, người dùng có thể nghe mà không cần Internet.

## 💾 2.9. Quản lý bộ nhớ

Quản lý dung lượng nhạc:

- 📊 Dung lượng thư viện
- 📦 Dung lượng từng bài / album
- 🗑️ Xóa bài đã tải
- 🧹 Xóa dữ liệu không cần thiết

---

# 🧠 3. Cấp 2 — Cá nhân hóa

## 🌐 3.1. Tìm kiếm nhạc trên Internet

Kết nối với nguồn nhạc bên ngoài để tìm kiếm các bài hát chưa có trong thư viện.

Ví dụ:

- 🔍 Tìm bài hát
- 🎤 Tìm nghệ sĩ
- 💿 Tìm album
- ▶️ Xem kết quả từ YouTube

## 📥 3.2. Tải nhạc

Tải bài hát về thiết bị để nghe offline.

```text
🔍 Tìm kiếm
    ↓
🎵 Chọn bài hát
    ↓
📥 Tải xuống
    ↓
💾 Lưu vào thiết bị
    ↓
📚 Thêm vào thư viện
```

> ⚠️ Việc tải nội dung từ nguồn bên ngoài cần tuân thủ quyền sử dụng và điều khoản của nguồn đó.

## 📚 3.3. Tự động thêm vào thư viện

Sau khi tải một bài hát, ứng dụng tự động đưa bài hát vào thư viện.

Người dùng không cần tự tạo folder hoặc nhập lại thông tin.

## 🏷️ 3.4. Tự động nhận diện thông tin bài hát

Sau khi tải, ứng dụng cố gắng xác định:

- 🎵 Tên bài hát
- 🎤 Nghệ sĩ
- 💿 Album
- 🎸 Thể loại
- 📅 Năm phát hành
- 🖼️ Ảnh album

Mục đích là tự động tổ chức thư viện.

## 📌 3.5. Tự động thêm vào Playlist

Người dùng có thể chọn playlist mặc định.

Ví dụ:

```text
📥 Bài mới tải
      ↓
📌 Tự động thêm vào
"My Music"
```

Nếu không chọn playlist cố định, bài hát vẫn được lưu trong thư viện.

## 🧩 3.6. Playlist thông minh

Playlist tự động cập nhật dựa trên điều kiện.

Ví dụ:

- ❤️ Nhạc yêu thích
- 🆕 Nhạc mới tải
- 🔥 Nhạc nghe nhiều
- ❓ Nhạc chưa nghe
- 🕘 Nhạc nghe gần đây

## 😊 3.7. Phân loại theo tâm trạng

Gắn nhãn tâm trạng cho bài hát:

- 😊 Vui
- 😢 Buồn
- 😌 Thư giãn
- 🧠 Tập trung
- 🔥 Năng lượng
- ❤️ Lãng mạn
- 🌙 Ban đêm

Một bài hát có thể thuộc nhiều tâm trạng.

## 🎭 3.8. Chế độ nghe theo tâm trạng

Người dùng chọn tâm trạng hiện tại:

```text
😊 Vui
😢 Buồn
😌 Thư giãn
🧠 Tập trung
🔥 Năng lượng
🌙 Ban đêm
```

Ứng dụng chọn các bài phù hợp từ thư viện.

## 🎯 3.9. Gợi ý bài hát

Dựa trên hành vi nghe nhạc để gợi ý:

- 🔥 Bài thường nghe
- 🎤 Nghệ sĩ yêu thích
- 🎸 Thể loại yêu thích
- 🎵 Bài tương tự
- 📥 Bài đã tải nhưng chưa nghe
- 🔄 Bài lâu rồi chưa nghe

## 🧠 3.10. Hồ sơ sở thích âm nhạc

Ứng dụng dần hiểu gu nghe nhạc dựa trên:

- ▶️ Bài thường nghe
- ⏭️ Bài bỏ qua
- 🔁 Bài nghe lại nhiều lần
- ❤️ Bài yêu thích
- 📋 Playlist
- 🎸 Thể loại
- 🎤 Nghệ sĩ
- 😊 Tâm trạng thường chọn

## 📊 3.11. Thống kê nghe nhạc

Cung cấp:

- ⏱️ Tổng thời gian nghe
- 🎵 Số bài đã nghe
- 🎤 Nghệ sĩ nghe nhiều nhất
- 🎸 Thể loại nghe nhiều nhất
- 🔥 Bài hát nghe nhiều nhất
- 📅 Lịch sử nghe theo ngày / tuần / tháng

---

# 🚀 4. Cấp 3 — Chức năng nâng cao / Thông minh

Cấp 3 tập trung vào việc để ứng dụng **tự hiểu bài hát và tự tạo trải nghiệm nghe**.

## 🎚️ 4.1. Phát nhạc liền mạch

Chuyển từ bài này sang bài khác mà không tạo khoảng im lặng khó chịu.

**Ý nghĩa:** tạo cảm giác một phiên nghe liên tục.

## 🔄 4.2. Chuyển bài mượt

Hai bài được chuyển tiếp với nhau thay vì kết thúc đột ngột rồi bắt đầu bài mới.

**Ý nghĩa:** giống cách DJ chuyển giữa các bài.

## 🥁 4.3. Phân tích nhịp điệu

Phân tích BPM, nhịp và tiết tấu của bài hát.

**Ý nghĩa:** giúp tìm các bài có tốc độ phù hợp để chuyển tiếp.

## 🎼 4.4. Phân tích tông nhạc

Nhận diện tông của bài hát.

**Ý nghĩa:** ưu tiên các bài có tông phù hợp để việc chuyển bài nghe tự nhiên hơn.

## 🔥 4.5. Phân tích năng lượng

Đánh giá mức năng lượng của bài hát.

```text
😴 Thấp → 🙂 Trung bình → 🔥 Cao
```

**Ý nghĩa:** tránh chuyển đột ngột giữa hai bài có mức năng lượng quá khác nhau.

## 🎧 4.6. Chuyển bài thông minh

Ứng dụng tự xác định:

- ⏱️ Khi nào nên chuyển bài
- 🎯 Chuyển tại đoạn nào
- ▶️ Bài tiếp theo nên bắt đầu ở đâu

**Ý nghĩa:** không nhất thiết phải chờ bài A kết thúc hoàn toàn rồi mới phát bài B.

## 🎼 4.7. Chuyển bài theo giai điệu

Phân tích giai điệu / nốt / đoạn nhạc ở cuối bài hiện tại và tìm đoạn phù hợp trong bài tiếp theo.

```text
🎵 Bài A
   Cuối bài: 🎼 Giai điệu X
             ↓
          🔍 Tìm kiếm
             ↓
🎵 Bài B
   Đoạn phù hợp với X
```

**Ý nghĩa:** tạo cảm giác hai bài thực sự nối tiếp nhau về mặt âm nhạc.

## 📈 4.8. Điều chỉnh mạch năng lượng

Sắp xếp bài hát theo một đường năng lượng hợp lý:

```text
🌱 Khởi động
      ↓
📈 Tăng dần
      ↓
🔥 Cao trào
      ↓
📉 Giảm dần
      ↓
😌 Thư giãn
```

**Ý nghĩa:** tạo một trải nghiệm nghe có diễn biến thay vì danh sách bài ngẫu nhiên.

## 🎛️ 4.9. Tự động tạo phiên nghe

Tự chọn và sắp xếp một nhóm bài phù hợp với mục đích nghe.

Ví dụ:

- 🧘 30 phút thư giãn
- 🏋️ 60 phút tập gym
- 💻 2 giờ làm việc
- 🌙 Một đêm nghe nhạc

**Ý nghĩa:** người dùng chỉ cần chọn mục đích, ứng dụng tự tạo danh sách.

## 🤖 4.10. DJ tự động

Kết hợp các chức năng thông minh:

```text
🧠 Gu nghe nhạc
       +
😊 Tâm trạng
       +
🎯 Mục đích
       +
🥁 BPM
       +
🎼 Tông nhạc
       +
🔥 Năng lượng
       ↓
    🤖 Auto DJ
       ↓
🎵 Chọn bài
       ↓
📋 Sắp xếp bài
       ↓
🎧 Chuyển bài mượt
```

**Ý nghĩa:** ứng dụng hoạt động giống một DJ cá nhân, tự tạo và duy trì một phiên nghe nhạc.

## 🧠 4.11. DJ cá nhân hóa

Auto DJ sử dụng chính dữ liệu của người dùng để tạo trải nghiệm riêng.

Ứng dụng học:

- ❤️ Nghệ sĩ yêu thích
- 🎸 Thể loại yêu thích
- ⏭️ Bài thường bỏ qua
- 🕘 Thời điểm thường nghe
- 🔥 Mức năng lượng yêu thích
- 😊 Tâm trạng thường chọn

**Ý nghĩa:** càng sử dụng lâu, phiên nghe càng phù hợp với cá nhân người dùng.

## ⏰ 4.12. Gợi ý theo thời điểm và hoạt động

Ứng dụng học mối quan hệ giữa thời gian, hoạt động và âm nhạc.

Ví dụ:

```text
🌅 08:00 → 🧠 Tập trung
🌆 18:00 → 🔥 Năng lượng
🌙 22:00 → 😌 Thư giãn
```

**Ý nghĩa:** ứng dụng chủ động đưa ra lựa chọn phù hợp với hoàn cảnh hiện tại.

---

# 🤖 5. AI Talk — Trợ lý AI cá nhân

## 💬 5.1. Tổng quan

AI Talk là một **trợ lý AI bên trong ứng dụng**, cho phép người dùng nói chuyện hoặc nhập yêu cầu bằng ngôn ngữ tự nhiên.

AI không chỉ trả lời câu hỏi mà có thể **thực hiện các chức năng có sẵn trong ứng dụng thay cho người dùng**.

```text
👤 Người dùng
      ↓
💬 AI Talk
      ↓
🧠 Hiểu yêu cầu
      ↓
🛠️ Thực hiện chức năng trong App
      ↓
🎵 Trả kết quả / Thay đổi App
```

## 🎯 5.2. Điều khiển trình phát nhạc

Người dùng có thể yêu cầu AI:

- ▶️ Phát nhạc
- ⏸️ Tạm dừng
- ⏭️ Chuyển bài
- 🔁 Bật lặp
- 🔀 Bật shuffle
- 🎚️ Điều chỉnh cách phát

Ví dụ:

> "Phát bài tiếp theo."

> "Cho bài này lặp lại."

## 🔍 5.3. Tìm kiếm nhạc

AI có thể thực hiện tìm kiếm thay cho người dùng.

Ví dụ:

> "Tìm cho tôi nhạc của Bruno Mars."

> "Tìm những bài giống bài này."

## 📥 5.4. Tải nhạc

AI có thể thực hiện quy trình tải nhạc trong phạm vi chức năng ứng dụng hỗ trợ.

Ví dụ:

> "Tải bài này về."

> "Tải 5 bài này vào thư viện."

## 📚 5.5. Quản lý thư viện

AI có thể:

- ➕ Thêm bài vào playlist
- ❌ Xóa bài khỏi playlist
- ❤️ Thêm / bỏ yêu thích
- 📌 Đưa bài vào playlist mặc định
- 🗂️ Tổ chức thư viện
- 🔍 Tìm bài trong thư viện

Ví dụ:

> "Thêm bài này vào playlist Workout."

> "Tìm tất cả bài của Taylor Swift."

## 😊 5.6. Tạo nhạc theo tâm trạng

Người dùng không cần tự chọn filter.

Ví dụ:

> "Tôi đang muốn thư giãn."

AI có thể:

```text
😊 Hiểu mood
      ↓
🧠 Phân tích thư viện
      ↓
🎵 Chọn bài phù hợp
      ↓
📋 Tạo / cập nhật queue
      ↓
▶️ Bắt đầu phát
```

## 🎯 5.7. Tạo phiên nghe

Người dùng có thể yêu cầu:

> "Cho tôi một playlist 1 tiếng để tập trung."

> "Tạo cho tôi nhạc tập gym."

> "Cho tôi nghe nhạc nhẹ trước khi ngủ."

AI sử dụng các chức năng Recommendation + Mood + Context + Auto DJ để thực hiện.

## 🧠 5.8. Hỏi về thư viện nhạc cá nhân

AI có thể trả lời dựa trên dữ liệu trong app.

Ví dụ:

> "Tôi có bao nhiêu bài Pop?"

> "Tháng này tôi nghe nghệ sĩ nào nhiều nhất?"

> "Bài nào tôi nghe nhiều nhất?"

> "Tìm những bài tôi tải nhưng chưa nghe."

## 🎛️ 5.9. Điều khiển chức năng nâng cao

AI có thể kích hoạt các tính năng nâng cao khi người dùng yêu cầu.

Ví dụ:

> "Tạo một phiên nhạc chuyển bài thật mượt."

> "Cho tôi một session nhạc có năng lượng tăng dần."

> "Tạo một Auto DJ cho 2 tiếng."

## 🔮 5.10. AI làm người điều phối

AI Talk có thể trở thành lớp điều phối phía trên toàn bộ ứng dụng:

```text
                     🤖 AI TALK
                         │
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
      🎵 Player       📚 Library      🔍 Search
          ↓              ↓              ↓
      📋 Playlist     📥 Download    🧠 Recommend
          ↓              ↓              ↓
       😊 Mood        🎧 Auto DJ     🎼 Transition
```

**Ý nghĩa:** người dùng không cần nhớ vị trí từng chức năng trong ứng dụng. Chỉ cần nói điều mình muốn, AI sẽ tìm và thực hiện bằng các chức năng có sẵn.

### ⚠️ Nguyên tắc của AI Talk

AI Talk **không phải một AI tự do muốn làm gì cũng được**.

AI chỉ được phép thực hiện các **thao tác mà ứng dụng cung cấp**.

Ví dụ:

```text
👤 "Phát nhạc thư giãn"
       ↓
🤖 AI
       ↓
🎯 Gọi chức năng tạo Mood Session
       ↓
🎵 Queue được cập nhật
       ↓
▶️ Bắt đầu phát
```

Điều này giúp AI dễ kiểm soát, dễ phát triển và an toàn hơn.

---

# 🏗️ 6. Tổng quan sản phẩm

```text
                    🎵 PERSONAL MUSIC APP
                             │
       ┌─────────────────────┼─────────────────────┐
       │                     │                     │
       🎵 CẤP 1             🧠 CẤP 2             🚀 CẤP 3
       CƠ BẢN             CÁ NHÂN HÓA          THÔNG MINH
       │                     │                     │
       ▶️ Player             🌐 Search             🎚️ Seamless
       📚 Library            📥 Download           🔄 Transition
       📋 Playlist           🏷️ Metadata           🥁 BPM
       🔀 Queue              😊 Mood               🎼 Key
       ❤️ Favorite           🎯 Recommendation     🔥 Energy
       📥 Offline            🧩 Smart Playlist     🎵 Melody
       📊 History            🧠 User Profile       🤖 Auto DJ
       💾 Storage             📈 Statistics          🎯 Context
       │                     │                     │
       └─────────────────────┼─────────────────────┘
                             │
                             ↓
                       🤖 AI TALK
                             │
              "Tôi muốn nghe nhạc thư giãn"
                             │
                             ↓
                     🧠 AI hiểu yêu cầu
                             │
                             ↓
                🛠️ Gọi chức năng trong App
                             │
                             ↓
                       🎧 Kết quả
```

## 🎯 Định hướng chính

### 🎵 Cấp 1 — Tôi có thể nghe nhạc.

Ứng dụng thay thế một music player thông thường và quản lý thư viện nhạc offline.

### 🧠 Cấp 2 — Ứng dụng hiểu gu nghe nhạc của tôi.

Ứng dụng biết tôi nghe gì, thích gì, tải gì và có thể đề xuất nhạc phù hợp.

### 🚀 Cấp 3 — Ứng dụng tự tạo trải nghiệm nghe nhạc.

Ứng dụng tự chọn bài, sắp xếp bài và chuyển bài dựa trên đặc điểm âm nhạc.

### 🤖 AI Talk — Tôi chỉ cần nói điều mình muốn.

AI trở thành **lớp giao tiếp tự nhiên** giúp người dùng điều khiển và sử dụng toàn bộ các chức năng của ứng dụng mà không cần thao tác thủ công.
