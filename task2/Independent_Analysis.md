# Phân tích độc lập và kiểm chứng kết quả – HW05 Task 2

**MSSV:** 23120184  
**SUT:** EShop – Backend REST API  
**Phạm vi:** Kiểm chứng độc lập kết quả AI từ bốn file JMeter `.jtl`, đối chiếu với JMeter HTML Dashboard, Test Plan `.jmx` và các minh chứng ở Task 1.

## 1. Mục đích và phạm vi phân tích

Tài liệu này ghi lại quá trình tính toán độc lập các chỉ số hiệu năng và rà soát những nhận định trong `AI_Analysis.md`. Mục tiêu không phải tìm lỗi bằng mọi giá, mà xác định nhận định nào đúng, nhận định nào chưa đầy đủ, khác biệt nào đến từ phương pháp tính và kết luận nào chưa đủ bằng chứng.

Các phép tính được thực hiện trên dữ liệu thô trong bốn file JTL. Kết quả được đối chiếu thêm với `statistics.json` trong HTML Dashboard của JMeter và cấu hình JMX. Các file JTL gốc không bị chỉnh sửa.

## 2. Dữ liệu đầu vào và phương pháp tính

### 2.1. Phạm vi dữ liệu

| Kịch bản | File JTL | Khoảng thời gian mẫu (UTC) | Thời lượng đo | Số mẫu |
|---|---|---|---:|---:|
| Load | [`load.jtl`](../task1/results/load/20261120_195907/load.jtl) | 20/11/2026 12:59:10.736 – 12:59:49.638 | 38.902 s | 200 |
| Stress | [`stress.jtl`](../task1/results/stress/20261121_084816/stress.jtl) | 21/11/2026 01:48:20.253 – 01:49:49.569 | 89.316 s | 1,600 |
| Spike | [`spike.jtl`](../task1/results/spike/20261121_091902/spike.jtl) | 21/11/2026 02:19:05.195 – 02:20:10.989 | 65.794 s | 304 |
| Soak | [`soak.jtl`](../task1/results/soak/20261121_094256/soak.jtl) | 21/11/2026 02:43:01.186 – 02:53:10.837 | 609.651 s | 3,890 |

Các nhãn request được giữ nguyên theo cột `label` của JTL:

- `01 - Admin login`
- `02 - Đọc danh sách đơn hàng`
- `03 - Xác nhận đơn`
- `04 - Kiểm tra trạng thái đơn`

### 2.2. Cấu trúc JTL

Cả bốn file có cùng header gồm 17 cột: `timeStamp`, `elapsed`, `label`, `responseCode`, `responseMessage`, `threadName`, `dataType`, `success`, `failureMessage`, `bytes`, `sentBytes`, `grpThreads`, `allThreads`, `URL`, `Latency`, `IdleTime` và `Connect`.

| Nhóm cột | Kiểu dữ liệu được sử dụng | Ý nghĩa trong phân tích |
|---|---|---|
| `timeStamp` | Số nguyên | Thời điểm bắt đầu sample, epoch milliseconds |
| `elapsed`, `Latency`, `IdleTime`, `Connect` | Số nguyên | Thời gian, đơn vị milliseconds |
| `bytes`, `sentBytes` | Số nguyên | Số byte phản hồi và request theo JMeter ghi nhận |
| `grpThreads`, `allThreads` | Số nguyên | Số thread đang hoạt động tại thời điểm sample |
| `success` | Boolean | Trạng thái thành công/thất bại của sample trong JMeter |
| `label`, `responseCode`, `responseMessage`, `threadName`, `dataType`, `failureMessage`, `URL` | Chuỗi | Nhãn request và thông tin phản hồi/ngữ cảnh |

Không có trường CPU, RAM, heap, garbage collection, thời gian truy vấn SQL hoặc event-loop delay trong các file JTL. Vì vậy, không thể lấy riêng JTL để kết luận mức sử dụng CPU/RAM, memory leak hoặc nguyên nhân chính xác của một request chậm.

### 2.3. Quy ước tính toán

- **Request throughput (samples/s):** tổng số sample chia cho khoảng đo. Khoảng đo được tính từ `min(timeStamp)` đến `max(timeStamp + elapsed)`.
- **Completed workflow throughput (workflows/s):** số workflow hoàn tất chia cho cùng khoảng đo. Một workflow hoàn tất khi cùng một virtual user thực hiện đủ bốn bước theo thứ tự `01 → 02 → 03 → 04`. Với các kịch bản này, có thể đếm số sample của nhãn bước cuối `04` để xác định số workflow hoàn tất.
- **Response-time statistics:** tính trên cột `elapsed`; bảng theo endpoint được nhóm theo `label`.
- **Percentile theo cách tính của AI:** dùng linear interpolation với vị trí zero-based `h = (n - 1) × p`. Hai phần tử ở vị trí `floor(h)` và `ceil(h)` được nội suy.
- **Percentile trong JMeter Dashboard:** lấy các giá trị `pct1ResTime`, `pct2ResTime`, `pct3ResTime` trong `statistics.json`, lần lượt tương ứng P90, P95 và P99. Đây là giá trị được Dashboard của các lần chạy này xuất ra; khi so sánh phải nêu rõ nguồn/phương pháp.
- **Response bytes:** cột `bytes` là số byte phản hồi được JMeter ghi nhận, không đồng nghĩa với tổng lưu lượng truyền trên mạng hoặc số byte sau nén thực tế.
- **Latency và Connect:** lần lượt lấy từ hai cột `Latency` và `Connect`, đơn vị milliseconds.

## 3. Kiểm tra tính toàn vẹn và thống kê tổng quan

### 3.1. Số lượng sample và HTTP response code

| Kịch bản | Tổng sample | Login | Đọc danh sách đơn | Xác nhận đơn | Kiểm tra trạng thái | Thành công | Thất bại | Error rate | HTTP response code |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Load | 200 | 50 | 50 | 50 | 50 | 200 | 0 | 0% | 200: 200 |
| Stress | 1,600 | 400 | 400 | 400 | 400 | 1,600 | 0 | 0% | 200: 1,600 |
| Spike | 304 | 76 | 76 | 76 | 76 | 304 | 0 | 0% | 200: 304 |
| Soak | 3,890 | 975 | 975 | 970 | 970 | 3,890 | 0 | 0% | 200: 3,890 |
| **Tổng** | **5,994** | **1,501** | **1,501** | **1,496** | **1,496** | **5,994** | **0** | **0%** | **200: 5,994** |

Kết quả được đếm từ toàn bộ data rows của từng JTL, không tính dòng header. Cả 5,994 sample đều có `success=true`, `responseCode=200` và `failureMessage` rỗng.

### 3.2. Request throughput và completed workflow throughput

| Kịch bản | Khoảng đo | Request throughput (samples/s) | Workflow hoàn tất | Workflow throughput (workflows/s) |
|---|---:|---:|---:|---:|
| Load | 38.902 s | 5.14 | 50 | 1.285 |
| Stress | 89.316 s | 17.91 | 400 | 4.478 |
| Spike | 65.794 s | 4.62 | 76 | 1.155 |
| Soak | 609.651 s | 6.38 | 970 | 1.591 |

Trong Soak, có 975 sample đăng nhập và 975 sample đọc danh sách, nhưng chỉ có 970 sample xác nhận và 970 sample kiểm tra trạng thái. Như vậy có năm workflow chưa đi hết bốn bước tại thời điểm bài kiểm thử kết thúc. Không nên lấy `3,890 / 4 = 972.5` làm số workflow hoàn tất; số thực tế hoàn tất là 970.

Hai đại lượng throughput có ý nghĩa khác nhau: request throughput đếm số HTTP sample mỗi giây, trong khi workflow throughput đếm số quy trình nghiệp vụ đi hết bốn bước mỗi giây. Khi trình bày khả năng xử lý nghiệp vụ, cần báo cáo workflow throughput cùng request throughput.

## 4. Đối chiếu độc lập các chỉ số hiệu năng

### 4.1. Average, median, percentile và min/max

| Kịch bản | Samples | Average (ms) | Median (ms) | P90 – AI linear (ms) | P95 – AI linear (ms) | P99 – AI linear (ms) | P95 – Dashboard (ms) | P99 – Dashboard (ms) | Min / Max (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Load | 200 | 7.86 | 6 | 14 | 16.05 | 21.07 | 16.95 | 27.93 | 3 / 62 |
| Stress | 1,600 | 8.43 | 8 | 14 | 17.00 | 31.00 | 17.00 | 31.00 | 0 / 60 |
| Spike | 304 | 35.45 | 11 | 23 | 32.00 | 1,291.67 | 32.75 | 1,324.30 | 2 / 1,653 |
| Soak | 3,890 | 21.42 | 15 | 47 | 59.00 | 91.22 | 59.00 | 93.09 | 0 / 391 |

Các số percentile của AI được tái tạo theo công thức `(n - 1) × p` đã nêu trong `AI_Analysis.md`. Giá trị trong cột Dashboard lấy từ `statistics.json` của từng lần chạy. Sự khác nhau không tự động có nghĩa là AI tính sai; đây là khác biệt về quy ước percentile và ảnh hưởng rõ hơn ở nhóm mẫu nhỏ hoặc phân phối có đuôi chậm.

Ví dụ, với 76 sample của request `03 - Xác nhận đơn` trong Spike, P95 theo linear interpolation là 347.25 ms; JMeter Dashboard ghi 1,282.65 ms. Trong dãy đã sắp xếp, giá trị ở vị trí 72 là 36 ms và vị trí 73 là 1,281 ms. Cả hai cách tính đều nhạy với bước nhảy lớn giữa hai giá trị này. Vì vậy, khi so sánh cần giữ nhất quán một convention và báo thêm số lượng/giá trị outlier thay vì chỉ dựa vào một percentile.

### 4.2. Response bytes theo từng request label

Mean `bytes` của từng endpoint được tính từ cột `bytes`, thay vì chỉ dùng một giá trị trung bình trộn bốn loại request.

| Kịch bản | Admin login (B) | Đọc danh sách đơn (B) | Xác nhận đơn (B) | Kiểm tra trạng thái (B) |
|---|---:|---:|---:|---:|
| Load | 640 | 8,706.08 | 301 | 8,715.00 |
| Stress | 640 | 68,133.75 | 301 | 68,167.08 |
| Spike | 640 | 81,392.11 | 301 | 81,411.08 |
| Soak | 640 | 352,330.19 | 301 | 352,335.04 |

Trong `AI_Analysis.md`, response bytes trung bình theo toàn bộ sample của mỗi kịch bản lần lượt khoảng 4,591; 34,310; 40,936 và 176,402 bytes. Các giá trị này là trung bình hợp lệ trên tập sample hỗn hợp, nhưng không đại diện cho riêng endpoint đọc danh sách đơn. Để phân tích payload hoặc so sánh endpoint, cần nhóm theo label như bảng trên.

### 4.3. Latency và Connect

| Kịch bản | Latency average / P95 / max (ms) | Connect average / P95 / max (ms) |
|---|---:|---:|
| Load | 7.72 / 16.05 / 62 | 0.27 / 0 / 44 |
| Stress | 7.85 / 15 / 59 | 0.07 / 0 / 34 |
| Spike | 33.60 / 19 / 1,653 | 0.40 / 3 / 23 |
| Soak | 19.49 / 48 / 391 | 0.04 / 0 / 30 |

Đây là thống kê gộp trên tất cả label của từng kịch bản. Đặc biệt, năm sample Spike trên 1,000 ms có `Connect=0`; độ trễ được ghi nhận không đến từ thời gian thiết lập kết nối TCP trong các sample đó. Điều này chưa đủ để xác định chính xác thời gian bị tiêu tốn ở tầng nào.

## 5. Phân tích các điểm cần xem lại trong AI_Analysis.md

### 5.1. Tổng sample và HTTP status – nhận định đúng

AI báo tổng 5,994 sample, tất cả `success=true`, HTTP 200 và Error Rate 0%. Kết quả này khớp với việc đếm từng dòng dữ liệu trong bốn file JTL và phân nhóm theo `success`, `responseCode`.

**Kết luận:** Không phát hiện sai số đếm hoặc sai HTTP response code ở nhận định này.

### 5.2. Throughput Load và Stress – phép tính đúng, cần diễn giải cẩn thận

Request throughput của cả lần chạy là 5.14 samples/s ở Load và 17.91 samples/s ở Stress. Tỷ lệ `17.91 / 5.14 ≈ 3.48` là phép chia đúng trên toàn bộ khoảng đo.

Tuy nhiên, hai lần chạy có cấu hình khác nhau: Load dùng 5 VU, ramp-up 10 giây, 10 vòng/VU; Stress dùng 20 VU, ramp-up 30 giây, 20 vòng/VU. Ramp-up chiếm tỷ lệ đáng kể trong tổng thời lượng mỗi lần chạy, nên throughput trung bình của toàn file không phản ánh riêng giai đoạn đủ tải.

Có thể quan sát các cửa sổ sau ramp-up: Load từ giây 10–30 đạt khoảng 6.60 samples/s; Stress từ giây 30–60 đạt khoảng 26.43 samples/s. Tỷ lệ trong hai cửa sổ được chọn xấp xỉ 4 lần, tương ứng với tỷ lệ VU 20/5. Đây là phép so sánh mô tả theo các cửa sổ tải ổn định đã chọn, không phải phép thử kiểm soát hoàn toàn mọi biến.

Think-time 2–4 giây và số VU ảnh hưởng trực tiếp đến lượng request được phát ra. Vì vậy, throughput quan sát được không nên được diễn giải như năng lực tối đa của server. Với 0 lỗi và độ trễ thấp ở Stress, dữ liệu chưa cho thấy server đã bão hòa; nhưng cũng chưa đủ để xác định trần công suất.

**Phân loại:** Phép tính throughput toàn lần chạy đúng; phần diễn giải cần bổ sung ảnh hưởng của ramp-up, think-time và số VU. Không kết luận rằng server đạt giới hạn.

### 5.3. Percentile và P95 của request xác nhận đơn trong Spike

AI dùng linear interpolation `(n - 1) × p`. Với 76 sample `03 - Xác nhận đơn`, hai giá trị quanh vị trí P95 là 36 ms và 1,281 ms, nên kết quả P95 nội suy là 347.25 ms. JMeter Dashboard ghi 1,282.65 ms theo percentile convention của Dashboard.

Bốn sample xác nhận đơn có thời gian trên 1,000 ms là 1,281; 1,292; 1,517 và 1,653 ms. Theo nearest-rank, P95 của nhóm 76 sample là 1,281 ms. Các cách tính cho ra kết quả khác nhau nhưng đều cho thấy đuôi chậm đáng chú ý. Không nên kết luận 347.25 ms là lỗi số học nếu công thức linear interpolation đã được nêu rõ.

Điểm còn thiếu trong diễn giải threshold là phạm vi áp dụng. AI đề xuất P95 warning >120 ms và failure >250 ms, đồng thời nhận xét P95 gộp theo kịch bản đều thấp hơn ngưỡng warning. Nhưng nếu dùng cùng ngưỡng cho từng request label, P95 của `03 - Xác nhận đơn` theo cách tính AI là 347.25 ms, vẫn vượt 250 ms; theo Dashboard là 1,282.65 ms. Vì vậy, báo cáo nên nêu rõ threshold áp dụng theo toàn kịch bản hay theo từng endpoint. Với trải nghiệm nghiệp vụ, không nên chỉ dựa vào P95 gộp để che khuất một endpoint có đuôi chậm.

**Phân loại:** Khác biệt phương pháp tính percentile; thiếu sót ở việc không áp threshold theo từng request label. Không xác nhận lỗi tính toán percentile của AI.

### 5.4. Spike: bất thường xuất hiện sau cửa sổ concurrency cao

Các bản ghi có `allThreads >= 18` xuất hiện trong khoảng 02:19:20.871–02:19:25.656 UTC, tương đương khoảng 4.785 giây; số bản ghi trong cửa sổ này là 100 và concurrency quan sát được đạt 20 thread.

Nhóm `Spike_Dot_18_users` trong JMX được cấu hình `duration=60` giây nhưng `LoopController.loops=2` ([Spike JMX, dòng 287–298](../task1/plans/23120184_Spike_20261121.jmx#L287)). Vì số vòng lặp hữu hạn kết thúc trước khi hết scheduler duration, nhóm spike hoàn tất sớm hơn 60 giây. Thực tế, records của nhóm này trải từ khoảng 02:19:20.034 đến 02:19:28.436 UTC; cửa sổ `allThreads >=18` còn ngắn hơn.

Năm sample trên 1,000 ms xảy ra muộn hơn, trong khi `allThreads=2`, `Connect=0`, `success=true` và HTTP 200:

| Dòng JTL | Timestamp UTC | Request label | Elapsed (ms) | allThreads | Connect (ms) | Thread group |
|---:|---|---|---:|---:|---:|---|
| 274 | 02:19:54.941 | `03 - Xác nhận đơn` | 1,281 | 2 | 0 | `Spike_Nen_2_users` |
| 278 | 02:19:56.482 | `03 - Xác nhận đơn` | 1,517 | 2 | 0 | `Spike_Nen_2_users` |
| 282 | 02:20:00.053 | `03 - Xác nhận đơn` | 1,292 | 2 | 0 | `Spike_Nen_2_users` |
| 283 | 02:20:01.013 | `03 - Xác nhận đơn` | 1,653 | 2 | 0 | `Spike_Nen_2_users` |
| 284 | 02:20:01.344 | `04 - Kiểm tra trạng thái đơn` | 1,326 | 2 | 0 | `Spike_Nen_2_users` |

Các sample này xuất hiện khoảng 29–36 giây sau record cuối có `allThreads >=18`. Hai thread nền đều có sample chậm trong cùng khoảng thời gian. Đây là dấu hiệu cần điều tra ở backend hoặc máy kiểm thử, nhưng chưa xác định được nguyên nhân. Không thể quy kết cho SQLite, truy vấn SQL hoặc tranh chấp tài nguyên chỉ từ JTL.

**Phân loại:** AI nhận diện đúng đuôi chậm và giới hạn của cấu hình Spike. Cần nhấn mạnh rằng lần chạy này chưa duy trì concurrency cao trong đủ 60 giây như dự kiến.

### 5.5. Soak: độ trễ dao động, không suy giảm đơn điệu

Dưới đây là số liệu theo các cửa sổ 60 giây tính từ thời điểm sample đầu tiên. Bin cuối là khoảng thời gian chưa đủ 60 giây.

| Khoảng elapsed (s) | Samples | Average (ms) | P95 (ms) | Max (ms) |
|---:|---:|---:|---:|---:|
| 0–60 | 366 | 18.34 | 46.00 | 74 |
| 60–120 | 368 | 23.61 | 59.00 | 118 |
| 120–180 | 376 | 23.35 | 54.00 | 87 |
| 180–240 | 384 | 17.60 | 52.70 | 77 |
| 240–300 | 380 | 18.54 | 44.05 | 71 |
| 300–360 | 380 | 21.09 | 57.05 | 95 |
| 360–420 | 384 | 25.62 | 66.85 | 94 |
| 420–480 | 397 | 34.47 | 97.20 | 253 |
| 480–540 | 387 | 21.76 | 60.40 | 391 |
| 540–600 | 396 | 11.27 | 27.00 | 53 |
| 600–609.651 (partial) | 72 | 12.86 | 28.90 | 44 |

Khoảng 420–480 giây có Average và P95 cao nhất. Khoảng 480–540 giây có một sample lớn nhất 391 ms, nhưng Average và P95 đã giảm so với khoảng trước. Từ 540 giây trở đi, các chỉ số giảm thêm. Vì vậy, cách diễn đạt chính xác là Soak có một giai đoạn tăng độ trễ cục bộ, kèm một outlier muộn, sau đó hồi phục; không có xu hướng suy giảm tăng dần trong toàn bộ lần chạy.

AI đã nêu đúng xu hướng tổng thể không đơn điệu. Tuy nhiên, cụm “minutes 7–8” nên được làm rõ bằng khoảng elapsed cụ thể để tránh hiểu rằng cả hai cửa sổ liên tiếp đều suy giảm như nhau. Bin 7 theo chỉ số zero-based là 420–480 giây; bin 8 là 480–540 giây.

### 5.6. Response bytes trong Soak: quan sát được tương quan, chưa đủ chứng minh nguyên nhân

Một phản hồi danh sách đơn ở đầu Soak có 351,364 bytes, trong khi phản hồi ở cuối có 353,304 bytes; chênh lệch là 1,940 bytes. Con số này bằng `2 × 970`, tương ứng với hai byte chênh lệch giữa độ dài chuỗi `pending` (7 ký tự) và `confirmed` (9 ký tự), nhân với 970 lần cập nhật thành công.

Mẫu hình này phù hợp với giả thuyết response JSON dài thêm khi trạng thái đơn chuyển từ `pending` sang `confirmed`. Tuy nhiên, cột `bytes` chỉ ghi kích thước phản hồi, không ghi body JSON. Vì vậy, nếu chỉ dựa vào JTL thì đây là một tương quan có cơ sở, chưa phải bằng chứng trực tiếp về nội dung từng response. Muốn khẳng định nguyên nhân, cần đối chiếu response body hoặc mã nguồn tạo JSON.

Chênh lệch tổng 1,940 bytes tương đương khoảng 0.55% so với phản hồi đầu, không đủ để tự giải thích đợt tăng response time tại khoảng 420–540 giây.

### 5.7. JMeter Assertions và ý nghĩa của `success=true`

AI lưu ý rằng `success=true` và HTTP 200 tự thân không chứng minh toàn bộ nội dung nghiệp vụ. Cảnh báo này đúng nếu chỉ nhìn raw JTL mà không biết Test Plan đã cấu hình assertion nào.

Khi đối chiếu thêm các file JMX, hai request GET ở bước 02 và bước 04 có JMESPath Assertion kiểm tra đúng `orderId` và trạng thái kỳ vọng. Ví dụ trong Load JMX: assertion trước khi xác nhận kiểm tra `${initialStatus}` tại [dòng 83–90](../task1/plans/23120184_Load_20261120.jmx#L83), assertion sau khi xác nhận kiểm tra `${targetStatus}` tại [dòng 155–162](../task1/plans/23120184_Load_20261120.jmx#L155). Các sample tương ứng đều được JMeter đánh dấu thành công.

Do đó, 1,501 sample GET ở bước 02 và 1,496 sample GET ở bước 04 đã vượt qua các assertion được cấu hình cho hai bước đọc. Tuy nhiên, bước login và PUT không có assertion response-body tương đương; kết quả chuyển trạng thái được xác nhận gián tiếp bằng GET ở bước 04. Không nên mở rộng kết luận vượt quá phạm vi các điều kiện assertion hiện có.

### 5.8. Tài nguyên máy: dữ liệu ngoài JTL

Báo cáo Task 1 ghi nhận working set của tiến trình `node.exe` tại ba thời điểm Soak:

| Thời điểm chụp | Working set |
|---|---:|
| Khoảng phút 1 | 26,136 K |
| Khoảng phút 5 | 42,320 K |
| Khoảng phút 10 | 62,348 K |

Từ phút 1 đến phút 10, working set tăng 36,212 K, tương đương khoảng 138.6% so với điểm đầu. Từ phút 5 đến phút 10 tăng 20,028 K, tương đương khoảng 47.3% so với điểm phút 5. Đây là các snapshot Task Manager, không phải time-series liên tục; chúng cho thấy bộ nhớ cao hơn tại các thời điểm chụp nhưng không đủ để kết luận mức tăng kéo dài liên tục, không có plateau hoặc là memory leak.

Các con số này nằm ngoài raw JTL. Vì vậy, kết luận của AI rằng JTL không thể chứng minh CPU/RAM usage hoặc memory leak là đúng trong phạm vi dữ liệu JTL. Muốn đánh giá memory stability cần thu thập RSS/working set và heap của Node.js theo chu kỳ, bao gồm thời gian sau khi dừng tải để quan sát việc thu hồi bộ nhớ.

Minh chứng: [Soak phút 1](../task1/evidence/soak1.png), [Soak phút 5](../task1/evidence/soak5.png), [Soak phút 10](../task1/evidence/soak9.png). CPU 00–01% ở các ảnh chụp chỉ là quan sát tại thời điểm chụp, không đại diện cho mức CPU trong suốt toàn bộ lần chạy.

### 5.9. Kiến trúc backend và tên request label

`AI_Analysis.md` được yêu cầu phân tích raw JTL, nên việc không xác định database engine hoặc kiến trúc backend từ JTL là một giới hạn đúng của nguồn dữ liệu, không phải hallucination. Ở tài liệu `AI_Recommendations.md`, khi có thêm mã nguồn, AI xác định backend dùng Express và SQLite. Hai kết quả không mâu thuẫn vì phạm vi đầu vào khác nhau.

Trong bảng theo label, AI dùng tên tiếng Anh như `Read order list`, `Confirm order` và `Check order status`. Đây là bản dịch để đọc dễ hơn, không làm thay đổi số liệu. Tuy nhiên, khi trích dẫn hoặc truy ngược về JTL, nên giữ nguyên label tiếng Việt và chỉ thêm bản dịch trong ngoặc nếu cần.

## 6. Đánh giá các Performance Thresholds do AI đề xuất

Các ngưỡng dưới đây là giá trị AI **đề xuất**, không phải SLA đã được chủ hệ thống phê duyệt và cũng không phải số liệu đo được trực tiếp từ JTL.

| Metric | Warning AI đề xuất | Failure AI đề xuất | Nhận xét Human Review |
|---|---:|---:|---|
| Error rate | > 0.1% | ≥ 1%, hoặc có HTTP 5xx / functional assertion failure | Có thể dùng làm ngưỡng khởi điểm. Cần thống nhất cách xử lý HTTP 4xx theo nghiệp vụ, vì không phải mọi 4xx đều là lỗi hiệu năng. |
| P95 response time | > 120 ms | > 250 ms | Cần xác định áp dụng cho toàn kịch bản hay từng endpoint. Nên có ngưỡng theo từng label để tránh percentile gộp che khuất đuôi chậm. |
| P99 response time | > 200 ms | > 400 ms | Là ngưỡng đề xuất; cần xác nhận theo yêu cầu nghiệp vụ và workload ổn định. Spike có P99 cao hơn rõ rệt do các outlier. |
| Throughput | < 90% target đã khai báo | < 75% target đã khai báo | Chưa áp dụng được khi chưa có target. Nên khai báo target theo completed workflow/s và request/s nếu cả hai đều quan trọng. |
| Memory stability | Tăng > 10% liên tục so với baseline đã warm-up trong nửa cuối | Tăng > 20%, vượt 85% memory limit, OOM hoặc restart | JTL không có memory telemetry. Cần time-series cho Node.js; ba snapshot Task Manager chưa đủ kiểm tra điều kiện “sustained” hoặc “no plateau”. |

Các ngưỡng latency là provisional. Việc dùng một tỷ lệ nhân từ baseline hiện tại chỉ có ý nghĩa khi request mix, kích thước payload, số VU, think-time và môi trường thực thi tương đương. Không nên dùng trực tiếp các ngưỡng này làm release gate trước khi có workload mục tiêu và SLA được thống nhất.

## 7. Đối chiếu với các đề xuất tối ưu backend

Các đề xuất tối ưu cấp mã nguồn được trình bày chi tiết trong [`AI_Recommendations.md`](AI_Recommendations.md) và đánh giá Feasible/Hallucinated trong [`Human_Review.md`](Human_Review.md). Tài liệu này ghi nhận các điểm dữ liệu hỗ trợ việc ưu tiên kiểm tra:

1. **Pagination cho `GET /api/admin/orders`:** có cơ sở trực tiếp nhất vì endpoint trả toàn bộ danh sách; mean response bytes của request đọc danh sách tăng từ khoảng 8.7 KB ở Load lên khoảng 352.3 KB ở Soak. Cần benchmark trước/sau với cùng tập dữ liệu.
2. **Minimal response DTO:** có thể giảm field không cần thiết, nhưng phải đối chiếu toàn bộ nơi sử dụng API và giữ đủ trường UI cần.
3. **Spike tail investigation:** lặp lại profile Spike đã sửa để duy trì concurrency theo thiết kế, đồng thời thu log backend, query timing, event-loop delay và resource telemetry. Năm sample chậm chưa chỉ ra root cause.
4. **Soak memory monitoring:** chạy lâu hơn với đo RSS/heap liên tục và tiếp tục quan sát sau khi dừng tải. Ba snapshot hiện tại không chứng minh memory leak.
5. **Index, connection pool hoặc WAL:** chỉ thử khi query plan hoặc phép đo database cho thấy có vấn đề tương ứng. Không thêm index cho admin list nếu query không có điều kiện lọc phù hợp; không mặc định thêm connection pool cho một SQLite connection; không bật WAL với giả định rằng nó chắc chắn sửa được Spike tail.

Không có tối ưu nào được triển khai trong Task 2. Các đề xuất cần được đo bằng một lần benchmark có kiểm soát trước khi kết luận hiệu quả.

## 8. Bảng tổng hợp phân loại nhận định của AI

| # | Nội dung được kiểm tra | Phân loại | Kết luận độc lập |
|---:|---|---|---|
| 1 | Tổng 5,994 samples, success=true, HTTP 200, Error Rate 0% | Correct AI Interpretation | Khớp toàn bộ raw JTL. |
| 2 | Request throughput của bốn kịch bản | Missing Analysis / Omission | Các request/s đúng; cần bổ sung completed workflow/s, đặc biệt Soak có năm workflow dở dang. |
| 3 | Stress throughput cao hơn Load khoảng 3.48 lần | Correct Calculation, Needs Qualification | Phép chia trên toàn lần chạy đúng; cần giải thích ảnh hưởng của ramp-up, VU và think-time. Không suy ra server capacity. |
| 4 | P90/P95/P99 khác Dashboard | Calculation Method Difference | Hai bộ giá trị có thể tái tạo bằng các percentile conventions khác nhau. |
| 5 | Response bytes trung bình theo kịch bản | Correct Aggregate Metric, Scope Limitation | Trung bình trộn nhiều label là hợp lệ nhưng không đại diện riêng endpoint; cần phân tích theo label. |
| 6 | Spike Confirm Order P95 = 347.25 ms | Calculation Method Difference | Đúng theo linear interpolation của AI; Dashboard/nearest-rank cho kết quả khác. Không phải lỗi số học đã xác nhận. |
| 7 | Tất cả P95 theo kịch bản dưới ngưỡng warning | Missing Analysis / Omission | P95 gộp thấp, nhưng P95 riêng Confirm Order ở Spike vượt 250 ms theo cả hai cách tính. |
| 8 | Spike group không duy trì concurrency cao đủ 60 giây | Correct AI Interpretation | JMX đặt loops=2 dù duration=60; high-concurrency window thực tế rất ngắn. |
| 9 | Độ trễ không tăng trong cửa sổ allThreads ≥18 | Correct AI Interpretation | Raw JTL ghi nhận Average trước/trong cửa sổ gần nhau; outlier xảy ra sau đó. |
| 10 | Năm sample >1,000 ms xảy ra sau high-concurrency window | Correct AI Interpretation | Năm sample đều allThreads=2, Connect=0, success=true và HTTP 200. Root cause chưa rõ. |
| 11 | Soak tăng độ trễ ở khoảng phút 7–8 rồi giảm | Correct Overall Trend, Needs Clearer Bins | Có một cửa sổ tăng rõ và một số outlier ở cửa sổ kế tiếp; không có suy giảm đơn điệu. Nên ghi elapsed intervals. |
| 12 | Response bytes Soak tăng từ 351,364 lên 353,304 | Correct Observation, Cause Not Proven by JTL Alone | Chênh lệch khớp 2 × 970, phù hợp giả thuyết độ dài status thay đổi; cần response body/source để xác nhận cơ chế. |
| 13 | HTTP 200/success không tự chứng minh business correctness | Correct Within JTL Scope, Needs JMX Context | JMX bổ sung assertion ở hai bước GET; các bước login/PUT chưa có assertion body tương đương. |
| 14 | Không suy ra CPU/RAM/memory leak từ JTL | Correct AI Interpretation | Snapshot Task Manager là dữ liệu ngoài JTL và chưa đủ kết luận memory leak hoặc plateau. |
| 15 | Không xác định được database/backend architecture từ JTL | Correct AI Interpretation | AI_Recommendations xác định Express/SQLite sau khi có thêm source code; không mâu thuẫn về phạm vi. |
| 16 | Dịch tên label tiếng Việt sang tiếng Anh | Presentation / Traceability Issue | Không đổi số liệu nhưng nên giữ nguyên label gốc để dễ truy ngược JTL. |

## 9. Kết luận

Phân tích độc lập xác nhận các số đếm tổng, HTTP status, average, median, min/max và request throughput chính trong `AI_Analysis.md` khớp với raw JTL. Các khác biệt P95/P99 chủ yếu đến từ percentile convention, không nên tự động xem là lỗi tính toán. Điểm cần bổ sung quan trọng là completed workflow throughput và phạm vi áp dụng threshold theo từng request label.

Spike có năm sample vượt 1,000 ms sau cửa sổ concurrency cao; tuy nhiên, cấu hình JMX cho thấy nhóm 18 người dùng chỉ chạy hai vòng nên tải đột biến không duy trì đủ thời lượng dự kiến. Soak cho thấy dao động cục bộ rồi hồi phục, không chứng minh suy giảm đơn điệu. Các snapshot bộ nhớ ngoài JTL cho thấy working set tăng ở những thời điểm chụp, nhưng chưa đủ kết luận memory leak.

Các bằng chứng hỗ trợ ưu tiên kiểm tra pagination và payload của endpoint danh sách đơn, sửa/kiểm chứng profile Spike, đồng thời bổ sung telemetry trước khi quy nguyên nhân cho backend hoặc SQLite. Nhìn chung, AI hỗ trợ tốt việc tổng hợp và tính toán ban đầu, nhưng kết quả phải được đối chiếu với JTL, JMX, Dashboard và mã nguồn. Tester chịu trách nhiệm phân biệt số liệu đo được, khác biệt phương pháp, giả thuyết và kết luận cuối cùng.

## 10. Tài liệu liên quan

- [`AI_Analysis.md`](AI_Analysis.md) – kết quả phân tích ban đầu do AI tạo.
- [`Misinterpretation_Hunt.md`](Misinterpretation_Hunt.md) – bảng rà soát các điểm AI diễn giải sai hoặc bỏ sót.
- [`AI_Recommendations.md`](AI_Recommendations.md) – các đề xuất tối ưu backend do AI tạo.
- [`Human_Review.md`](Human_Review.md) – đánh giá của sinh viên về tính khả thi của các đề xuất.
- [`AI_Critique.md`](../ai/AI_Critique.md) – phản biện AI 200–300 từ.
- [`Task 1 Report`](../task1/23120184_HW05_Task1_Report.md) – cấu hình, kết quả kiểm thử và minh chứng tài nguyên.
