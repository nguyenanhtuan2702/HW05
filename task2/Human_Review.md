# HW05 · Task 2 — Human Review

**MSSV 23120184 · EShop · Luồng quản trị xác nhận đơn hàng**

**Kết luận.** AI đếm đúng 5.994 request thành công. Hai điểm làm thay đổi cách đọc kết quả là đơn vị throughput và phạm vi áp dụng ngưỡng độ trễ. Trong Soak, 6,38 request/giây tương ứng 1,59 đơn được xác nhận và kiểm tra lại mỗi giây. Trong Spike, P95 toàn lượt đạt 32 ms theo cách tính của AI, nhưng riêng thao tác xác nhận đơn có P95 là 347,25 ms theo chính cách tính đó. Vì vậy, dùng số tổng hợp để mô tả trải nghiệm xác nhận đơn sẽ bỏ qua những lần chờ lâu nhất.

## 1. Đối chiếu phân tích AI với dữ liệu gốc

Đối tượng rà soát là [AI_Analysis.md](AI_Analysis.md), [AI_Recommendations.md](AI_Recommendations.md) và các phép đối chiếu trong [Misinterpretation_Hunt.md](Misinterpretation_Hunt.md). Mỗi dòng JTL sau tiêu đề là một request. Khoảng đo bắt đầu từ thời điểm gửi request đầu tiên và kết thúc khi request cuối cùng hoàn tất. Một vòng nghiệp vụ hoàn tất khi người dùng ảo đi qua bốn bước 01–04 và bước 04 kiểm tra thành công trạng thái của đơn sau khi cập nhật.

| Log gốc | Khoảng đo (s) | HTTP 200 và thành công / tổng | Vòng hoàn tất | Request/s | Vòng hoàn tất/s |
|---|---:|---:|---:|---:|---:|
| [Load](../task1/results/load/20261120_195907/load.jtl) | 38,902 | 200/200 | 50 | 5,14 | 1,285 |
| [Stress](../task1/results/stress/20261121_084816/stress.jtl) | 89,316 | 1.600/1.600 | 400 | 17,91 | 4,478 |
| [Spike](../task1/results/spike/20261121_091902/spike.jtl) | 65,794 | 304/304 | 76 | 4,62 | 1,155 |
| [Soak](../task1/results/soak/20261121_094256/soak.jtl) | 609,651 | 3.890/3.890 | 970 | 6,38 | 1,591 |

### 1.1. Throughput và tính đúng của giao dịch

**Giữ số request/s của AI, bổ sung số vòng hoàn tất/s.** Bốn nhãn trong Soak lần lượt có 975, 975, 970 và 970 mẫu. Có năm lượt đã đăng nhập và đọc danh sách nhưng chưa tới bước xác nhận khi lượt đo kết thúc. Lấy 3.890 chia 4 sẽ cho 972,5, trong khi số vòng thực sự đi đến bước 04 là 970. Ở 5 người dùng ảo, kết quả quan sát được là 970 / 609,651 = 1,591 vòng/giây. Con số này mô tả tải đã thực hiện với think-time 2–4 giây. Muốn xác định công suất tối đa cần đo ở nhiều mức tải hơn.

**Bổ sung phần kiểm tra nghiệp vụ mà phân tích AI bỏ sót.** Mã HTTP 200 cho biết request được xử lý thành công ở tầng HTTP. Hai JMESPath Assertion còn kiểm tra đúng mã đơn lấy từ CSV, với trạng thái kỳ vọng là `pending` ở bước 02 và `confirmed` ở bước 04. Vì thế, 970 mẫu bước 04 thành công trong Soak cung cấp bằng chứng về trạng thái sau ghi cho 970 vòng đã hoàn tất. Phạm vi kết luận dừng ở các trường mà assertion kiểm tra. [Cấu hình Soak](../task1/plans/23120184_Soak_20261121.jmx)

### 1.2. Spike — vì sao cùng dữ liệu lại có hai giá trị P95?

Trong 76 mẫu riêng của bước 03, thời gian ở các vị trí 72, 73 và 74 sau khi sắp tăng dần là **36, 1.281 và 1.292 ms** (đếm vị trí từ 1). Khoảng nhảy từ 36 lên 1.281 ms khiến kết quả nhạy với cách nội suy.

| Cách tính | Vị trí P95 trong 76 mẫu | Phép đối chiếu | P95 |
|---|---:|---|---:|
| AI, nội suy tuyến tính | 1 + 75 × 0,95 = 72,25 | 36 + 0,25 × (1.281 − 36) | 347,25 ms |
| Cách nội suy khớp dashboard của lượt chạy | 77 × 0,95 = 73,15 | 1.281 + 0,15 × (1.292 − 1.281) | 1.282,65 ms |

**Phán quyết.** Cả hai giá trị đều tái tạo được. Thiếu sót có ảnh hưởng là AI chỉ đối chiếu ngưỡng ở mức toàn kịch bản. Nếu áp ngưỡng P95 đề xuất 250 ms cho thao tác xác nhận đơn, cả hai cách tính đều vượt ngưỡng này. Nếu áp cho toàn bộ 304 request, P95 chỉ là 32 ms theo AI hoặc 32,75 ms theo dashboard. Nên ghi rõ đối tượng của ngưỡng trước khi đánh giá đạt hay trượt. Mốc 250 ms là đề xuất của AI, chưa có SLA được phê duyệt trong hồ sơ. [Raw Spike](../task1/results/spike/20261121_091902/spike.jtl) · [Dashboard statistics](../task1/results/spike/20261121_091902/html/statistics.json)

**Giữ nhận định về thời điểm xuất hiện mẫu chậm.** Các dòng 274, 278, 282, 283 của Spike ghi nhận bốn lần xác nhận mất 1.281, 1.517, 1.292 và 1.653 ms. Dòng 284 ghi nhận lần đọc lại mất 1.326 ms. Cả năm đều có `allThreads=2`, `Connect=0`, HTTP 200 và `success=true`. Khi đó nhóm 18 người dùng bổ sung đã kết thúc. `Connect=0` chỉ loại thời gian thiết lập kết nối khỏi phần chậm được JMeter ghi nhận. Chưa có phép đo truy vấn SQL hay thời gian chờ trong Node.js để quy nguyên nhân cho một tầng cụ thể. [Năm mẫu từ dòng 274](../task1/results/spike/20261121_091902/spike.jtl#L274)

### 1.3. Soak — xu hướng độ trễ và bộ nhớ

P95 theo cửa sổ 60 giây tăng lên **97,2 ms ở giây 420–480**, giảm còn **60,4 ms ở giây 480–540** và **27 ms ở giây 540–600**. Mẫu lớn nhất toàn lượt, 391 ms, nằm ở cửa sổ giữa. AI nhận xét đúng rằng độ trễ tăng tạm thời rồi giảm. Khi trình bày nên dùng khoảng giây, vì “bin 7” tính từ 0 tương ứng phút thứ 8. [Log Soak, mẫu 391 ms](../task1/results/soak/20261121_094256/soak.jtl#L3148)

Working set của cùng tiến trình backend tăng từ **26.136 K** ở 01:00 lên **42.320 K** ở 04:59 và **62.348 K** ở 10:10. Đây là ba ảnh Task Manager nằm ngoài JTL. Chúng xác nhận mức bộ nhớ cao hơn tại từng thời điểm chụp. Khoảng trống giữa các ảnh và việc thiếu số đo sau khi ngừng tải khiến tiêu chí “tăng liên tục, không ổn định trở lại” chưa thể đánh giá. JMeter và backend cùng chạy trên một máy, nên độ trễ quan sát cũng có thể chịu tác động từ cả hai tiến trình. [Phút 1](../task1/evidence/soak1.png) · [Phút 5](../task1/evidence/soak5.png) · [Kết thúc](../task1/evidence/soak9.png)

## 2. Đánh giá từng khuyến nghị tối ưu

Cột phán quyết đánh giá liệu có đủ cơ sở kỹ thuật để **thử** đề xuất. Số liệu request và kích thước phản hồi lấy từ JTL. Chi tiết kiến trúc, truy vấn và trường hiển thị dựa trên các vị trí mã nguồn được dẫn trong [AI_Recommendations.md](AI_Recommendations.md). Các lượt hiện có đều đo phiên bản trước tối ưu.

| # | Đề xuất của AI | Phán quyết | Lý do và cách kiểm chứng |
|---|---|---|---|
| 1 | Phân trang danh sách đơn quản trị theo con trỏ ID | **Khả thi · ưu tiên đầu** | Bước 02 nhận trung bình 8.706 byte ở Load và 352.330 byte ở Soak. Hai lần đọc danh sách trong mỗi vòng làm chi phí này lặp lại. Giới hạn số dòng theo trang có tác động trực tiếp đến lượng dữ liệu trả về. So sánh trước/sau trên cùng tập đơn, đo byte và P95. Kiểm tra chuyển trang và khả năng tra đúng đơn ở trang sau, vì assertion hiện tìm ID trong phản hồi danh sách. |
| 2 | Chỉ trả trường cần thiết cho danh sách đơn | **Khả thi** | Truy vấn được mô tả dùng `orders.*`, còn bảng quản trị dùng ID, tên người mua, tổng tiền, địa chỉ và trạng thái. Rà các nơi đọc API trước khi bỏ trường. Trên cùng một trang và cùng số bản ghi, đo byte giảm được và kiểm tra giao diện vẫn hiển thị đủ dữ liệu. |
| 3 | Thêm chỉ mục `(user_id, id DESC)` cho lịch sử đơn khách hàng | **Khả thi có điều kiện · ngoài luồng đã đo** | `GET /api/orders/my-orders` lọc theo khách hàng, còn hai request đọc trong JMeter gọi `/api/admin/orders`. Thời gian ở bước 02/04 không chứng minh lợi ích của chỉ mục này. Muốn chấp nhận thay đổi, cần đối chiếu kế hoạch truy vấn và đo riêng lịch sử đơn ở nhiều quy mô dữ liệu. |
| 4 | Nén HTTP cho khách truy cập từ xa | **Khả thi có điều kiện** | JSON danh sách lớn tạo cơ hội giảm byte truyền. Các JTL hiện tại đo qua localhost, cột `bytes` chưa cho biết mức tiết kiệm khi bật nén. Thử cùng dữ liệu từ một máy khách khác, xác nhận phản hồi được nén và so sánh byte thực truyền, CPU và P95. |
| 5 | Dùng một lệnh cập nhật có điều kiện để chuyển trạng thái | **Khả thi** | Có thể ràng buộc ID và trạng thái hiện tại ngay trong câu lệnh ghi. Bốn mẫu PUT chậm là lý do để đo thêm. Chưa có thời gian từng lệnh SQL để quy kết cách cập nhật hiện tại gây chậm. Kiểm tra hai yêu cầu đồng thời cho cùng đơn, chuyển trạng thái sai và ID không tồn tại trước khi so độ trễ. |
| 6 | Đo chờ SQLite trước khi thay đổi số kết nối hoặc thử WAL | **Khả thi ở bước chẩn đoán** | `Connect` của JMeter đo kết nối HTTP. Năm giá trị 0 ms không cho biết SQLite có chờ khóa hay không. Theo dõi thời gian từ khi gửi truy vấn đến callback và lỗi busy/locked. Chỉ thử riêng WAL hoặc busy timeout nếu phép đo cho thấy tranh chấp có thể tái hiện. AI không tuyên bố đã tìm thấy lỗi pool hay khóa. |
| 7 | Gắn số đo theo request và tiến trình, chạy lại Spike/Soak | **Khả thi · ưu tiên cho điều tra** | Gắn mã tương quan cho request và truy vấn, ghi event-loop delay, RSS và heap theo cùng trục thời gian. Lặp Spike trên cùng quy mô đơn để xem năm mẫu chậm có tái hiện. Với Soak, tiếp tục ghi sau khi ngừng tải để quan sát thu hồi bộ nhớ. Cách này cung cấp bằng chứng về nguyên nhân trước khi thay mã. |

**Kết luận phân loại.** Cả bảy đề xuất đều khả thi trong phạm vi hoặc điều kiện đã nêu. Chưa phát hiện đề xuất nào bịa ra một thành phần bắt buộc của hệ thống hoặc khẳng định mức cải thiện đã đo được. Phân trang có căn cứ trực tiếp nhất từ lượng dữ liệu trả về. Với năm mẫu Spike chậm và xu hướng working set, bước có giá trị nhất là thu thập số đo đồng bộ trước khi quyết định tối ưu backend.

*Nguồn và vai trò rà soát: đây là bản đối chiếu có AI hỗ trợ. Phần Human Review của bài tập yêu cầu sinh viên kiểm tra các phép tính và tự xác nhận phán quyết cuối cùng.*
