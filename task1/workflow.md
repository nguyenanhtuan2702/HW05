# Ghi nhận API và thiết kế phép đo

| Thao tác | Quan sát từ DevTools | Cần xác minh |
|---|---|---|
| Đăng nhập | POST http://localhost:3000/api/login, HTTP 200, body có email và password | Cách frontend duy trì phiên và gửi thông tin xác thực |
| Đọc đơn | Request hiển thị tên orders, phản hồi là danh sách có id và status | Method, URL đầy đủ |
| Xác nhận | Đã quan sát pending, confirmed, shipping, delivered trong phản hồi | Chụp Headers và Payload của request cập nhật pending → confirmed |
| Đọc lại | Đối chiếu orderId và status của cùng một phần tử | Ghi id trước và sau khi tải lại, chụp phản hồi |

Mỗi vòng lấy một orderId riêng trong data/orders.csv. Chuẩn bị đơn pending trước khi đo. Dùng lại bộ dữ liệu sau khi đã phục hồi trạng thái ban đầu. Nếu login thất bại, dừng lượt đó. Nếu bị khóa sau 3 lần sai, ghi cách reset giữa các lần chạy.

| Kịch bản | Thread / ramp-up / thời lượng / think-time | Lý do chọn | Report view |
|---|---|---|---|
| Load | | | |
| Stress | | | |
| Spike | | | |
| Soak | Duy trì 10–15 phút | Xác minh mức tải ổn định | |

Lưu JMX ở plans/. Với mỗi lần chạy, lưu raw JTL và thư mục HTML trong results/<kịch bản>/. Ghi lại đề xuất ban đầu của AI, điểm tự sửa và lý do trước khi đo.
