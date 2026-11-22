# HW05 Task 1 · Ba GitHub Issue về hiệu năng EShop

## [Performance] GET /api/admin/orders trả toàn bộ danh sách khi chỉ cần kiểm tra một đơn

### Hiện tượng và ảnh hưởng

Trong luồng quản trị xác nhận đơn, bước 02 và 04 đều gọi `GET /api/admin/orders` để kiểm tra trạng thái của một `orderId`. Cả hai lần API đều trả danh sách đầy đủ. Khi dữ liệu tăng, quản trị viên phải tải và lọc ngày càng nhiều bản ghi để kiểm tra cùng một thao tác.

| Kịch bản | Load | Stress | Spike | Soak |
|---|---:|---:|---:|---:|
| Kích thước phản hồi GET xấp xỉ, theo cột `bytes` của JMeter (KB) | 8,7 | 68,1 | 81,4 | 352,3 |

Ở lần Soak, hai lượt đọc tiêu tốn khoảng 705 KB mỗi vòng xác nhận đơn. Các lần chạy có quy mô dữ liệu và tải khác nhau. Bảng này mô tả lượng dữ liệu truyền, chưa xác định riêng ảnh hưởng của phân trang đến độ trễ.

### Cách kiểm tra

1. Trên EShop cục bộ, đăng nhập bằng tài khoản quản trị và mở danh sách đơn hàng. Trong Network, ghi số bản ghi và kích thước phản hồi của request `orders`.
2. Bổ sung đơn thử nghiệm rồi tải lại danh sách trong cùng điều kiện, lấy phản hồi HTTP 200 và so sánh số bản ghi, kích thước.
3. Xác nhận một đơn, sau đó xem phản hồi đọc lại để đối chiếu số đơn được trả với số đơn cần kiểm tra.

### Kết quả mong đợi

Quản trị viên có thể tải danh sách theo trang với giới hạn kích thước. Khi kiểm tra một đơn cụ thể, có thể tra cứu theo ID với quyền quản trị phù hợp. Kiểm tra lại trên cùng bộ dữ liệu để xác nhận số bản ghi trả về nằm trong giới hạn trang và trạng thái đơn vẫn chính xác.

**Minh chứng** — Báo cáo mục 7.5 và 10. Đối chiếu cột `bytes` của hai sampler 02, 04 trong `load.jtl`, `stress.jtl`, `spike.jtl`, `soak.jtl`. Ảnh `evidence/T109-before.png` và `evidence/T109.png` minh họa cùng danh sách khi xác nhận một đơn.

## [Performance] Năm request mất 1,28–1,65 giây sau khi tải Spike đã trở về 2 người dùng

### Hiện tượng

Trong lần Spike ngày 21/11/2026, cả 304 request đều thành công. Ở giây 49,7–56,1 tính từ đầu lượt chạy, JMeter ghi nhận bốn request `PUT /api/admin/orders/{id}/status` và một request `GET /api/admin/orders` mất 1.281–1.653 ms. Cả năm thuộc nhóm hai người dùng nền. Trong cửa sổ đột biến, thời gian lớn nhất ghi nhận là 40 ms. P95 toàn lượt là 32,75 ms, nhưng P99 đạt 1.324,30 ms.

### Cách kiểm tra

1. Chuẩn bị 76 đơn `pending` với ID riêng và cập nhật CSV. Dùng plan `23120184_Spike_20261121.jmx` với 2 người dùng nền và 18 người dùng bổ sung ở giây 15.
2. Với lần chạy đã lưu, lọc `spike.jtl` theo `elapsed >= 1000`. Đối chiếu `timeStamp`, `threadName`, `label`, `allThreads` và `success` của năm mẫu.
3. Chạy lặp với dữ liệu tương đương. Đối chiếu thời điểm mẫu chậm với log backend và tài nguyên máy chạy chung JMeter/EShop.

### Tiêu chí hoàn tất điều tra

Ghi nhận tần suất tái hiện, số request có thời gian đáp ứng từ 1.000 ms trở lên và độ trễ lớn nhất sau mỗi đợt Spike. Nếu tái hiện, xác định thành phần gây chậm bằng số đo cùng thời điểm. Hiện tượng mới được ghi nhận trong một lượt chạy. Mốc 1.000 ms dùng để tìm lại năm mẫu trong log.

**Minh chứng** — `results/spike/20261121_091902/spike.jtl`, `evidence/flotActiveThreadsOverTime.png`, `evidence/flotResponseTimesOverTime.png`. Báo cáo mục 7.4.

## [Performance] Working set của backend Node.js tăng từ 25,5 lên 60,9 MiB trong lần Soak 10 phút

### Hiện tượng

EShop và JMeter chạy chung máy Windows 11. Trong lần Soak với 5 người dùng ảo, Task Manager ghi nhận ba mốc cho cùng tiến trình backend `node.exe`, PID 11180.

| Thời gian đã chạy | Bộ nhớ hiển thị | Ảnh |
|---|---:|---|
| 01:00 | 26.136 K | `evidence/soak1.png` |
| 04:59 | 42.320 K | `evidence/soak5.png` |
| 10:10, kết thúc | 62.348 K | `evidence/soak9.png` |

Chênh lệch giữa mốc đầu và cuối khoảng 35,4 MiB. JMeter hoàn tất 3.890 request, 0 lỗi, P95 59 ms. Ba ảnh ghi nhận mức tăng trong thời gian có tải. Chưa có dữ liệu sau khi ngừng tải để xác định bộ nhớ có được thu hồi hay có rò rỉ.

### Cách kiểm tra và tiêu chí hoàn tất

1. Chuẩn bị dữ liệu `pending` và chạy plan `23120184_Soak_20261121.jmx` với 5 người dùng, ramp-up 10 giây, thời lượng 610 giây, think-time 2–4 giây. Xác định PID backend đang lắng nghe cổng 3000 cho lượt chạy mới.
2. Ghi bộ nhớ trước, trong và sau khi ngừng tải theo khoảng thời gian cố định. Theo dõi working set của tiến trình, cùng RSS và `heapUsed` của Node.js nếu có thể.
3. Lặp lại với cùng quy mô dữ liệu. Đính kèm chuỗi số đo và kết luận liệu bộ nhớ ổn định, giảm sau khi nghỉ hay tiếp tục tăng qua các chu kỳ tải.

**Minh chứng** — Ba ảnh trong bảng và `results/soak/20261121_094256/soak.jtl`. Báo cáo mục 8.1–8.2. Tệp `soak9.png` ghi mốc thực tế 10:10.
