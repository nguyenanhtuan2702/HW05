# HW05 · Báo cáo tổng hợp ba Task

**MSSV:** 23120184 · **SUT:** EShop REST API · **Phạm vi:** kiểm thử hiệu năng, rà soát phân tích AI và đề xuất kiểm thử liên tục.

## Tóm tắt điều hành

Task 1 thực thi bốn kịch bản trên cùng luồng quản trị xác nhận đơn. Toàn bộ 5.994 request nhận HTTP 200 và được JMeter đánh dấu thành công; không có lỗi assertion trong các lượt chạy. Kết quả không chứng minh giới hạn tải tối đa: Stress chỉ thử đến 20 người dùng ảo (VU), còn các kịch bản có kích thước dữ liệu và hồ sơ tải khác nhau.

Phát hiện cần theo dõi là năm request Spike chậm hơn 1 giây sau khi nhóm tải đột biến đã kết thúc. Trong Soak, working set của backend tăng qua ba ảnh chụp nhưng dữ liệu thưa, chưa đủ kết luận có memory leak. Task 2 xác nhận số đếm chính, bổ sung throughput theo workflow và làm rõ khác biệt percentile giữa cách nội suy của phân tích AI và JMeter Dashboard. Task 3 đề xuất cách đưa kiểm thử vào CI; đây là thiết kế, chưa phải pipeline đã triển khai.

## 1. Môi trường và luồng nghiệp vụ

| Thành phần | Cấu hình |
|---|---|
| Máy chạy | Windows 11 Home Single Language 64-bit, Intel Core i7-1355U (10 nhân, 12 luồng), RAM 15,69 GB |
| SUT | EShop backend Node.js trên `localhost:3000` |
| Công cụ | Apache JMeter 5.6.3, Java 25.0.2 (heap tối đa 1 GB), Windows Task Manager |
| Bố trí | JMeter và backend cùng chạy trên một máy; có thể cạnh tranh CPU/RAM |

Một workflow gồm bốn request: **01** `POST /api/login`, **02** `GET /api/admin/orders`, **03** `PUT /api/admin/orders/{orderId}/status`, **04** đọc lại danh sách để xác nhận chính đơn đó đã chuyển từ `pending` sang `confirmed`. Mỗi lượt dùng dữ liệu CSV với các mã đơn riêng; hai bước đọc có JMESPath assertion kiểm tra trạng thái đúng `orderId`, không chỉ tìm từ khóa trong toàn bộ danh sách. Think-time trước thao tác xác nhận là 2–4 giây.

## 2. Thiết kế và kết quả Task 1

| Kịch bản | Cấu hình tải | Thời lượng đo | Samples / workflow hoàn tất | Request/s · workflow/s | P95 toàn lượt (ms) | Lỗi |
|---|---|---:|---:|---:|---:|---:|
| Load | 5 VU, ramp-up 10 s, 10 vòng/VU | 38,902 s | 200 / 50 | 5,14 · 1,285 | 16,95 | 0 |
| Stress | 20 VU, ramp-up 30 s, 20 vòng/VU | 89,316 s | 1.600 / 400 | 17,91 · 4,478 | 17,00 | 0 |
| Spike | 2 VU nền, tăng lên 20 VU (18 VU bổ sung) | 65,794 s | 304 / 76 | 4,62 · 1,155 | 32,75 | 0 |
| Soak | 5 VU, ramp-up 10 s, 610 s | 609,651 s | 3.890 / 970 | 6,38 · 1,591 | 59,00 | 0 |

P95 trong bảng lấy từ JMeter Dashboard và mô tả **toàn bộ request của kịch bản**, không phải riêng endpoint. Soak dừng khi còn năm workflow chưa hoàn tất; do đó không lấy `3.890 / 4` làm số workflow hoàn tất. Ở Stress, 26,8 request/s là đỉnh quan sát ngắn hạn, không phải throughput bền vững hay giới hạn capacity.

**Spike và độ trễ đuôi:** có năm mẫu thành công vượt 1.000 ms — bốn lần xác nhận đơn và một lần đọc lại — với mức cao nhất 1.653 ms. Chúng xuất hiện sau cửa sổ high-concurrency; JTL ghi `Connect=0`, nhưng không có số đo SQL, event loop hay tài nguyên đủ đồng bộ để xác định nguyên nhân.

**Soak và tài nguyên:** cấu hình 5 VU duy trì 609,651 giây với 6,38 request/s, P95 59 ms và không có lỗi trên 3.890 request; 970 workflow hoàn tất (1,591 workflow/s). Đây là mức tải ổn định đã quan sát trong cấu hình thử, không phải RPS tối đa hay giới hạn capacity. P95 theo cửa sổ một phút tăng tạm thời ở khoảng giây 420–480 rồi giảm. Working set ghi nhận qua ba snapshot tăng từ 26.136 K ở phút 1 lên 42.320 K ở phút 5 và 62.348 K ở phút 10. 62.348 K là mức cao nhất trong các snapshot, không phải memory ceiling; dữ liệu rời rạc không chứng minh xu hướng tăng liên tục hoặc memory leak. CPU cũng chỉ được chụp tại thời điểm, không phải telemetry liên tục.

### Dashboard và dữ liệu thô

| Kịch bản | JMeter HTML Dashboard | JTL |
|---|---|---|
| Load | [Mở dashboard](../task1/results/load/20261120_195907/html/index.html) | [load.jtl](../task1/results/load/20261120_195907/load.jtl) |
| Stress | [Mở dashboard](../task1/results/stress/20261121_084816/html/index.html) | [stress.jtl](../task1/results/stress/20261121_084816/stress.jtl) |
| Spike | [Mở dashboard](../task1/results/spike/20261121_091902/html/index.html) | [spike.jtl](../task1/results/spike/20261121_091902/spike.jtl) |
| Soak | [Mở dashboard](../task1/results/soak/20261121_094256/html/index.html) | [soak.jtl](../task1/results/soak/20261121_094256/soak.jtl) |

## 3. Task 2 — phân tích AI và human review

Phân tích AI đếm đúng 5.994 mẫu thành công và mô tả đúng các outlier Spike cùng dao động Soak. Human review bổ sung hai điểm quan trọng:

1. **Phân biệt throughput request và throughput nghiệp vụ.** Soak đạt 6,38 request/s nhưng chỉ có 970 workflow hoàn tất, tương đương 1,591 workflow/s.
2. **Nêu rõ cách tính và phạm vi P95.** Với 76 mẫu bước 03 của Spike, P95 là 347,25 ms theo linear interpolation dùng trong phân tích AI và 1.282,65 ms theo JMeter Dashboard. P95 toàn Spike chỉ khoảng 32–32,75 ms. Đây là khác biệt phương pháp và phạm vi; không nên dùng P95 toàn kịch bản để mô tả riêng trải nghiệm xác nhận đơn.

Các ngưỡng trong phân tích AI là đề xuất ban đầu, không phải SLA đã được phê duyệt. JTL không chứa CPU/RAM, và HTTP 200 tự nó không chứng minh toàn bộ tính đúng nghiệp vụ; cần đọc kèm assertion và dữ liệu gốc.

### Khuyến nghị tối ưu theo mức độ bằng chứng

| Ưu tiên | Khuyến nghị | Cơ sở và giới hạn |
|---|---|---|
| Cao | Phân trang `GET /api/admin/orders`; giữ thứ tự ổn định và hỗ trợ tìm đúng đơn | Endpoint hiện trả toàn bộ danh sách. Mean response bytes tăng từ khoảng 8.706 ở Load lên 352.330 ở Soak; đo lại với cùng dữ liệu trước/sau. |
| Cao | Bổ sung telemetry theo request và truy vấn; lặp lại Spike/Soak có kiểm soát | Cần phân biệt ứng dụng, SQLite, event loop và tranh chấp tài nguyên; JTL hiện tại không xác định nguyên nhân năm mẫu chậm. |
| Vừa | Trả DTO chỉ gồm trường UI cần, kiểm tra mọi consumer | Có thể giảm payload, nhưng cần bảo đảm không làm hỏng giao diện hoặc consumer khác. |
| Có điều kiện | Đo riêng lịch sử đơn khách hàng trước khi thêm index; thử nén khi có client từ xa; đánh giá cập nhật trạng thái có điều kiện | Các lượt JMeter hiện tại không chứng minh trực tiếp lợi ích của index customer-history, nén qua mạng, hay việc hai lệnh SQL gây ra outlier. |
| Chẩn đoán trước | Đo thời gian chờ/khóa SQLite trước khi đổi pool, WAL hoặc busy timeout | Không có bằng chứng hiện tại để khẳng định SQLite lock là nguyên nhân; thay đổi có thể làm tăng thời gian chờ hoặc contention. |

Ba vấn đề đã được ghi nhận tại repo EShop: [nguyenanhtuan2702/eshop-sut#201](https://github.com/nguyenanhtuan2702/eshop-sut/issues/201) (phân trang danh sách), [nguyenanhtuan2702/eshop-sut#202](https://github.com/nguyenanhtuan2702/eshop-sut/issues/202) (Spike outlier), và [nguyenanhtuan2702/eshop-sut#203](https://github.com/nguyenanhtuan2702/eshop-sut/issues/203) (working-set snapshots). Đây là vấn đề cần điều tra, không phải kết luận nguyên nhân đã được chứng minh.

## 4. Task 3 — đề xuất kiểm thử hiệu năng liên tục

Đề xuất chọn kịch bản theo loại thay đổi: bỏ qua thay đổi chỉ tài liệu; chạy Load khi sửa API/auth/backend hoặc khi chưa phân loại được; chạy thêm Stress và Spike khi sửa truy vấn, schema hay xử lý đồng thời; chạy Soak định kỳ cho commit backend mới. Đây là workflow đề xuất, chưa được triển khai vào CI.

**So sánh hồi quy:** dùng baseline là trung vị P95 của ba lượt tham chiếu đã duyệt cho từng cặp *kịch bản × bước*. Giữ đồng nhất phiên bản JMeter, máy chạy, think-time, cách tính percentile và snapshot dữ liệu `pending`. Lấy P95 từ `pct2ResTime` của Dashboard. Với baseline B và commit mới C, điều kiện cảnh báo thử nghiệm là `C > 1,20 × B` **và** `C − B ≥ 5 ms`; nếu vượt, chạy xác nhận lại trên cùng commit và dữ liệu. Chỉ cảnh báo hồi quy khi cùng bước tiếp tục vượt điều kiện ở lượt hợp lệ tiếp theo. Lượt thiếu mẫu hoặc lỗi assertion cần báo riêng, không dùng để so percentile.

Ngưỡng 20% + 5 ms là đề xuất cần hiệu chỉnh bằng lịch sử chạy, không phải SLO. Chạy nối tiếp cả bốn kịch bản theo thời lượng đo Task 1 tốn khoảng 13 phút 24 giây, chưa tính chuẩn bị dữ liệu và tạo báo cáo. Rerun xác nhận giúp giảm nhiễu nhưng tăng thời gian CI và vẫn có thể bỏ sót lỗi chập chờn.

## 5. Kết luận

Trong tải đã thử, cả bốn kịch bản không ghi nhận lỗi; Load và Stress có P95 toàn lượt lần lượt 16,95 ms và 17,00 ms. Spike cho thấy tail latency cần được tái hiện và đo thêm; Soak chưa đủ dữ liệu để kết luận về bộ nhớ. Ưu tiên hợp lý là kiểm soát kích thước danh sách đơn, chuẩn hóa dữ liệu/cách tính khi so sánh, và bổ sung telemetry trước khi quy nguyên nhân hoặc triển khai tối ưu chưa được kiểm chứng.

### Video và tài liệu nguồn

- **Agent demo:** [Xem video trên YouTube](https://www.youtube.com/watch?v=LC_F-cynYG8)
- [Báo cáo chi tiết Task 1](../task1/23120184_HW05_Task1_Report.md)
- Task 2: [AI analysis](../task2/AI_Analysis.md), [recommendations](../task2/AI_Recommendations.md), [human review](../task2/Human_Review.md), [independent analysis](../task2/Independent_Analysis.md), [misinterpretation review](../task2/Misinterpretation_Hunt.md)
- [Đề xuất Task 3](../task3/proposal.md)
- Phụ lục: [AI audit](../ai/AI_AUDIT.md) · [AI critique](../ai/AI_Critique.md)
