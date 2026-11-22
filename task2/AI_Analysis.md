# Phân tích hiệu năng Apache JMeter từ JTL

## Tóm tắt điều hành

Báo cáo này phân tích trực tiếp các file kết quả JMeter thô dưới đây. Các metrics được tính từ dữ liệu JTL, không dựa vào ảnh chụp màn hình hay các bản tóm tắt có sẵn.

- **Load:** `task1/results/load/20261120_195907/load.jtl`
- **Stress:** `task1/results/stress/20261121_084816/stress.jtl`
- **Spike:** `task1/results/spike/20261121_091902/spike.jtl`
- **Soak:** `task1/results/soak/20261121_094256/soak.jtl`

Tổng cộng có **5,994 mẫu** trong bốn file. Cả 5,994 mẫu đều có `success=true` và HTTP response code `200`; error rate quan sát được là **0%**. Đáng chú ý nhất là tail latency muộn trong lượt Spike: năm mẫu vượt một giây, cao nhất là 1,653 ms. Response time của Soak dao động, tăng ở phút 7–8 rồi cải thiện; đây không phải xu hướng tăng đơn điệu. JTL không có số đo CPU hoặc memory nên không thể xác định resource saturation hay độ ổn định bộ nhớ.

## 1. Nguồn dữ liệu và kiểm tra tính hợp lệ

| Kịch bản | Tên file JTL gốc | Khoảng mẫu UTC (bắt đầu mẫu đầu tiên đến hoàn tất mẫu cuối) | Khoảng đo |
|---|---|---|---:|
| Load | `load.jtl` | 2026-11-20 12:59:10.736–12:59:49.638 | 38.902 s |
| Stress | `stress.jtl` | 2026-11-21 01:48:20.253–01:49:49.569 | 89.316 s |
| Spike | `spike.jtl` | 2026-11-21 02:19:05.195–02:20:10.989 | 65.794 s |
| Soak | `soak.jtl` | 2026-11-21 02:43:01.186–02:53:10.837 | 609.651 s |

Cả bốn JTL dùng chung header 17 cột. Ví dụ, xem header trong [load.jtl](../task1/results/load/20261120_195907/load.jtl#L1).

| Cột | Kiểu dữ liệu sau khi phân tích và ý nghĩa |
|---|---|
| `timeStamp` | Số nguyên, epoch timestamp tính bằng milliseconds |
| `elapsed`, `Latency`, `IdleTime`, `Connect` | Số nguyên, milliseconds |
| `bytes`, `sentBytes` | Số nguyên, số byte |
| `grpThreads`, `allThreads` | Số nguyên, số thread |
| `success` | Boolean |
| `label`, `responseCode`, `responseMessage`, `threadName`, `dataType`, `failureMessage`, `URL` | Văn bản |

Mỗi dòng có 17 trường. Các trường số không rỗng đều được phân tích thành số nguyên; các giá trị `success` được phân tích thành boolean. `failureMessage` rỗng ở mọi dòng. `responseCode` được giữ dưới dạng văn bản chứa giá trị HTTP status.

### Số lượng mẫu và response code

| Kịch bản | Tổng mẫu | `01 - Admin login` | `02 - Read order list` | `03 - Confirm order` | `04 - Check order status` | Thành công | Thất bại | Error rate | HTTP codes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Load | 200 | 50 | 50 | 50 | 50 | 200 | 0 | 0% | 200: 200 |
| Stress | 1,600 | 400 | 400 | 400 | 400 | 1,600 | 0 | 0% | 200: 1,600 |
| Spike | 304 | 76 | 76 | 76 | 76 | 304 | 0 | 0% | 200: 304 |
| Soak | 3,890 | 975 | 975 | 970 | 970 | 3,890 | 0 | 0% | 200: 3,890 |
| **Tổng** | **5,994** | **1,501** | **1,501** | **1,496** | **1,496** | **5,994** | **0** | **0%** | **200: 5,994** |

Các số đếm được lấy từ toàn bộ file thô: [load.jtl](../task1/results/load/20261120_195907/load.jtl), [stress.jtl](../task1/results/stress/20261121_084816/stress.jtl), [spike.jtl](../task1/results/spike/20261121_091902/spike.jtl) và [soak.jtl](../task1/results/soak/20261121_094256/soak.jtl).

## 2. Phương pháp tính

- Thống kê response time sử dụng `elapsed` của mọi mẫu trong kịch bản. Bảng theo nhãn request dùng cùng cách tính nhưng nhóm theo `label`.
- Percentile dùng linear interpolation trên các giá trị đã sắp xếp: với percentile `p`, rank bắt đầu từ 0 là `(n - 1) × p`; nếu rank là số thập phân thì nội suy tuyến tính giữa hai giá trị lân cận. Vì vậy percentile có thể là số milliseconds thập phân dù `elapsed` của từng mẫu là số nguyên.
- Min và max là các giá trị `elapsed` nhỏ nhất và lớn nhất quan sát được.
- Throughput được tính bằng `số mẫu / (thời điểm hoàn tất mẫu cuối − thời điểm bắt đầu mẫu đầu tiên)`. Khoảng đo dùng `timeStamp` nhỏ nhất và `timeStamp + elapsed` lớn nhất. Đây là tốc độ tổng hợp của các sampler, không phải offered-load target được chỉ định riêng hay bằng chứng về capacity.
- Response size lấy từ cột `bytes` của JMeter; bảng trình bày arithmetic mean và median. Đây là số byte response được JMeter ghi nhận, không phải phép đo tổng traffic trên wire. `sentBytes` là trường riêng cho số byte request.
- Latency và thời gian kết nối lần lượt lấy từ các cột `Latency` và `Connect` trong JTL. Tất cả thời gian được báo cáo bằng milliseconds, trừ khi có ghi chú khác.
- Timestamp trong báo cáo dùng UTC.

## 3. Metrics hiệu năng theo kịch bản

### Response time và throughput

| Kịch bản | Mẫu | Trung bình (ms) | Median (ms) | P90 (ms) | P95 (ms) | P99 (ms) | Min (ms) | Max (ms) | Throughput (mẫu/s) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Load | 200 | 7.86 | 6 | 14 | 16.1 | 21.1 | 3 | 62 | 5.14 |
| Stress | 1,600 | 8.43 | 8 | 14 | 17 | 31 | 0 | 60 | 17.91 |
| Spike | 304 | 35.45 | 11 | 23 | 32 | 1,291.7 | 2 | 1,653 | 4.62 |
| Soak | 3,890 | 21.42 | 15 | 47 | 59 | 91.2 | 0 | 391 | 6.38 |

### Response size, latency và thời gian kết nối

| Kịch bản | Response bytes: trung bình (median) | Latency: trung bình / P95 / max (ms) | Connect: trung bình / P95 / max (ms) |
|---|---:|---:|---:|
| Load | 4,591 (4,652) | 7.72 / 16.1 / 62 | 0.27 / 0 / 44 |
| Stress | 34,310 (34,203) | 7.85 / 15 / 59 | 0.07 / 0 / 34 |
| Spike | 40,936 (40,987) | 33.60 / 19 / 1,653 | 0.40 / 3 / 23 |
| Soak | 176,402 (176,002) | 19.49 / 48 / 391 | 0.04 / 0 / 30 |

### Response time theo label

`Avg / P95 / Max` có đơn vị milliseconds. Các giá trị này được tính từ dữ liệu thô của từng label.

| Kịch bản | Label request | Mẫu | Avg | P95 | Max |
|---|---|---:|---:|---:|---:|
| Load | 01 - Admin login | 50 | 6.52 | 9 | 62 |
| Load | 02 - Read order list | 50 | 5.36 | 8.55 | 10 |
| Load | 03 - Confirm order | 50 | 14.10 | 19.55 | 28 |
| Load | 04 - Check order status | 50 | 5.46 | 9 | 11 |
| Stress | 01 - Admin login | 400 | 4.57 | 10.05 | 60 |
| Stress | 02 - Read order list | 400 | 8.71 | 17 | 38 |
| Stress | 03 - Confirm order | 400 | 11.23 | 19 | 46 |
| Stress | 04 - Check order status | 400 | 9.21 | 21 | 43 |
| Spike | 01 - Admin login | 76 | 7.12 | 17.25 | 32 |
| Spike | 02 - Read order list | 76 | 14.63 | 34.5 | 46 |
| Spike | 03 - Confirm order | 76 | 88.39 | 347.25 | 1,653 |
| Spike | 04 - Check order status | 76 | 31.67 | 33 | 1,326 |
| Soak | 01 - Admin login | 975 | 5.39 | 19.3 | 67 |
| Soak | 02 - Read order list | 975 | 29.92 | 63 | 253 |
| Soak | 03 - Confirm order | 970 | 18.04 | 49.55 | 391 |
| Soak | 04 - Check order status | 970 | 32.37 | 65.55 | 179 |

## 4. So sánh và xu hướng giữa các kịch bản

### So sánh Load và Stress

Throughput đo được ở Stress là 17.91 mẫu/s, so với 5.14 mẫu/s ở Load, tức khoảng **3.48 lần**. Response time tổng thể khá gần nhau: trung bình lần lượt là 7.86 ms ở Load và 8.43 ms ở Stress; P95 là 16.1 ms và 17 ms. P99 tăng từ 21.1 lên 31 ms.

Đây không phải các lượt chạy được kiểm soát để so sánh trực tiếp từng yếu tố. Kế hoạch JMeter chỉ định Load có 5 users, 10 loops, ramp-up 10 giây; Stress có 20 users, 20 loops, ramp-up 30 giây ([Load plan](../task1/plans/23120184_Load_20261120.jmx#L13), [Stress plan](../task1/plans/23120184_Stress_20261120.jmx#L13)). Response size cũng khác đáng kể. Response đầu tiên của danh sách đơn có kích thước 8,664 bytes ở Load, 67,766 ở Stress, 81,334 ở Spike và 351,364 ở Soak ([Load](../task1/results/load/20261120_195907/load.jtl#L3), [Stress](../task1/results/stress/20261121_084816/stress.jtl#L3), [Spike](../task1/results/spike/20261121_091902/spike.jtl#L3), [Soak](../task1/results/soak/20261121_094256/soak.jtl#L3)). Khác biệt về response volume, ngày chạy, ramp profile, số mẫu và thời lượng chạy khiến việc quy kết chênh lệch chỉ cho số lượng users bị hạn chế.

Các giá trị lớn nhất trong cả Load và Stress đều là response login đầu tiên: Load ghi nhận elapsed 62 ms, latency 62 ms, connect 44 ms; Stress ghi nhận elapsed 60 ms, latency 59 ms, connect 34 ms ([dòng Load](../task1/results/load/20261120_195907/load.jtl#L2), [dòng Stress](../task1/results/stress/20261121_084816/stress.jtl#L2)). Đây là các quan sát riêng lẻ cho thấy thành phần connection tương đối lớn, nhưng không xác định nguyên nhân.

### Hành vi Spike và latency sau peak

Spike plan cấu hình baseline 2 users và một nhóm riêng 18 users, delay 15 giây, duration 60 giây, chạy hai loops ([Spike plan](../task1/plans/23120184_Spike_20261121.jmx#L288)). Trong JTL, các record có `allThreads >= 18` trải từ 02:19:20.871 đến 02:19:25.656 UTC — khoảng 15.676–20.461 giây sau mẫu đầu tiên — với 100 record trong nhóm này và peak quan sát được là 20 threads ([record đầu](../task1/results/spike/20261121_091902/spike.jtl#L72), [record cuối](../task1/results/spike/20261121_091902/spike.jtl#L171)). Vì vậy JTL cho thấy một cửa sổ high-concurrency ngắn được ghi nhận qua mẫu, không phải 60 giây duy trì peak concurrency. Giới hạn hai loops trong plan cần được lưu ý khi xác minh spike profile dự kiến có thực sự được tạo ra hay không.

Phân phối response time thay đổi rõ sau cửa sổ mẫu high-concurrency đó:

| Phân đoạn Spike, xác định theo timestamp/thread count trong JTL | Mẫu | Trung bình (ms) | P95 (ms) | Max (ms) | Số mẫu >1,000 ms |
|---|---:|---:|---:|---:|---:|
| Trước record đầu tiên có `allThreads >= 18` | 70 | 13.24 | 33.1 | 41 | 0 |
| Các record có `allThreads >= 18` | 100 | 12.50 | 23.15 | 37 | 0 |
| Sau record cuối cùng có `allThreads >= 18` | 134 | 64.19 | 36 | 1,653 | 5 |

Cả năm mẫu trên một giây đều là các record về sau, có `allThreads=2` và `Connect=0`: bốn lần xác nhận đơn mất 1,281, 1,517, 1,292 và 1,653 ms; một lần kiểm tra trạng thái đơn mất 1,326 ms ([1,281 ms](../task1/results/spike/20261121_091902/spike.jtl#L274), [1,517 ms](../task1/results/spike/20261121_091902/spike.jtl#L278), [1,292 ms](../task1/results/spike/20261121_091902/spike.jtl#L282), [1,653 ms](../task1/results/spike/20261121_091902/spike.jtl#L283), [1,326 ms](../task1/results/spike/20261121_091902/spike.jtl#L284)). Chúng xảy ra khoảng 29–36 giây sau record cuối cùng có `allThreads >= 18`. Thời điểm xuất hiện cho thấy một tail latency bất thường về cuối, nhưng tự nó không chứng minh peak là nguyên nhân.

Median của Spike là 11 ms, P95 là 32 ms, trong khi P99 là 1,291.7 ms. P99 cao do một tail nhỏ: **5 trong 304 mẫu (1.6%) vượt một giây**. Cả năm response vẫn được đánh dấu thành công với HTTP 200.

### Xu hướng response time trong Soak

Soak plan quy định 5 users, ramp-up 10 giây và duration 610 giây ([Soak plan](../task1/plans/23120184_Soak_20261121.jmx#L13)). Các bin dưới đây được tính theo thời điểm bắt đầu mỗi mẫu, tương đối với mẫu Soak đầu tiên. Bin cuối là bin chưa đủ một phút.

| Bin phút | Mẫu | Trung bình (ms) | P95 (ms) | Max (ms) |
|---:|---:|---:|---:|---:|
| 0 | 366 | 18.34 | 46 | 74 |
| 1 | 368 | 23.61 | 59 | 118 |
| 2 | 376 | 23.35 | 54 | 87 |
| 3 | 384 | 17.60 | 52.7 | 77 |
| 4 | 380 | 18.54 | 44.05 | 71 |
| 5 | 380 | 21.09 | 57.05 | 95 |
| 6 | 384 | 25.62 | 66.85 | 94 |
| 7 | 397 | 34.47 | 97.2 | 253 |
| 8 | 387 | 21.76 | 60.4 | 391 |
| 9 | 396 | 11.27 | 27 | 53 |
| 10 (một phần) | 72 | 12.86 | 28.9 | 44 |

Mẫu hình dao động, không tăng đều: trung bình và P95 cao nhất ở phút 7, mẫu lớn nhất xuất hiện ở phút 8, rồi cải thiện ở phút 9. Một số outlier về cuối gồm response danh sách đơn 253 ms và các mẫu xác nhận đơn 391 ms, 308 ms ([dòng Soak 2847](../task1/results/soak/20261121_094256/soak.jtl#L2847), [dòng 3148](../task1/results/soak/20261121_094256/soak.jtl#L3148), [dòng 3184](../task1/results/soak/20261121_094256/soak.jtl#L3184)). Các dòng này đều ghi nhận HTTP 200 thành công.

Response size của danh sách đơn cũng thay đổi trong Soak: response đầu tiên được trích dẫn là 351,364 bytes, còn response muộn là 353,304 bytes ([dòng đầu](../task1/results/soak/20261121_094256/soak.jtl#L3), [dòng muộn](../task1/results/soak/20261121_094256/soak.jtl#L3891)). Đây là thay đổi payload size quan sát được; riêng JTL không xác định nguyên nhân hoặc liệu nó có giải thích biến động response time hay không.

## 5. Ngưỡng tạm thời — đề xuất, không phải số đo

Các ngưỡng dưới đây là **đề xuất**, không phải giá trị có sẵn trong JTL hay service-level objective đã được thống nhất. Các ngưỡng latency được làm tròn từ khoảng 2 lần và 4 lần percentile cao nhất của các kịch bản không phải Spike (P95 59 ms; P99 91,2 ms). Chỉ so sánh latency với workload có request mix và response size tương đương.

| Metric | Ngưỡng cảnh báo đề xuất | Ngưỡng thất bại đề xuất | Kết quả đo và lý do |
|---|---|---|---|
| Error rate | >0,1% | ≥1%, hoặc có bất kỳ HTTP 5xx / functional assertion failure nào | Error rate đo được là 0% ở mỗi lượt. Điều kiện bổ sung cho 5xx/functional failure tránh để lỗi nghiêm trọng bị che khuất bởi tỷ lệ tổng thấp. |
| P95 response time | >120 ms | >250 ms | P95 cao nhất đo được ngoài Spike là 59 ms. P95 toàn kịch bản ở cả bốn lượt đều thấp hơn ngưỡng cảnh báo đề xuất. |
| P99 response time | >200 ms | >400 ms | P99 cao nhất đo được ngoài Spike là 91.2 ms. P99 của Spike là 1,291.7 ms, vượt ngưỡng thất bại đề xuất. |
| Throughput | <90% target đã xác định trước | <75% target đã xác định trước, hoặc không duy trì được target trong thời lượng yêu cầu | Tốc độ đo được là 5.14 (Load), 17.91 (Stress), 4.62 (Spike) và 6.38 (Soak) mẫu/s. JTL không có offered-load target nên không thể dùng riêng các tốc độ quan sát này làm ngưỡng capacity đạt/trượt. |
| Độ ổn định memory khi endurance test | Tăng >10% liên tục so với baseline sau warm-up trong nửa cuối lượt chạy và không đạt plateau | Tăng >20%, vượt >85% memory limit áp dụng, OOM hoặc restart | JTL không có số đo memory. Cần theo dõi process-memory phù hợp (ví dụ RSS; hoặc heap sau GC với JVM) trong endurance test đủ dài. |

Các tỷ lệ memory là ngưỡng giám sát đề xuất, không phải phát hiện từ các lượt test này. Soak kéo dài 609,651 giây là quá ngắn và không có memory telemetry, do đó không thể kết luận về độ ổn định bộ nhớ hay memory leak.

## 6. Rủi ro, bottleneck tiềm ẩn và giới hạn

1. **Tail response time muộn trong Spike:** năm mẫu vượt một giây sau cửa sổ high-concurrency quan sát được. `Connect=0` cho biết phần chậm được JMeter ghi nhận không nằm ở thời gian thiết lập kết nối. Cần điều tra application/server processing, queueing, host contention hoặc yếu tố khác; timing trong JTL không xác định được tầng gây ra.
2. **Dao động Soak và payload thay đổi:** P95 tăng ở phút 7 rồi giảm; response size cũng thay đổi. Dữ liệu không cho thấy xu hướng response time tăng đơn điệu kéo dài và không xác định được nguyên nhân.
3. **So sánh chưa kiểm soát payload hoặc run profile:** response danh sách đơn khác nhau đáng kể giữa các kịch bản. Các plan cũng khác về số users, ramp-up, duration và loop count; các lượt chạy diễn ra ở thời điểm khác nhau. Vì vậy không thể quy các khác biệt quan sát được chỉ cho mức tải.
4. **Không thể kết luận capacity:** throughput ở đây là tốc độ mẫu JMeter quan sát được trong khoảng timestamp của mỗi file. Không có offered-load target hay phép đo saturation. Dữ liệu không chứng minh server đã đạt giới hạn capacity.
5. **Không có telemetry host/resource trong JTL:** JTL không chứa CPU, RAM, heap, GC, queue depth hay database metrics. Chúng không thể chứng minh CPU/memory saturation, memory leak hoặc một bottleneck backend cụ thể.
6. **Chưa chứng minh đầy đủ tính đúng đắn của response:** `success=true` và HTTP 200 cho biết JMeter sample thành công, nhưng riêng chúng không xác thực response content hay tính đúng đắn nghiệp vụ.
7. **Vị trí load generator và service:** URL được ghi nhận dùng `localhost` (ví dụ [một request Spike](../task1/results/spike/20261121_091902/spike.jtl#L72)). Cần xác nhận load generator và service có chung host trước khi suy rộng kết quả; nếu có, tranh chấp tài nguyên giữa chúng có thể ảnh hưởng kết quả.
8. **Chưa biết kiến trúc:** không giả định database engine hay kiến trúc backend. Riêng JTL không cung cấp bằng chứng để nhận diện các thành phần này.

## Kết luận

Các lượt đo có zero failed samples và chỉ ghi nhận HTTP 200. Load và Stress có response time tổng thể tương tự dù throughput mẫu đo được khác nhau, nhưng response size và profile chạy cũng khác đáng kể. Spike có tail muộn rõ rệt với năm response thành công vượt một giây; Soak tăng tạm thời về cuối rồi hồi phục. Các quan sát này là cơ sở để kiểm tra tiếp bằng payload tương đương, spike profile duy trì được và telemetry latency/resource phía server; chúng không chứng minh giới hạn capacity, resource saturation hay memory leak.
