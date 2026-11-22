# Task 2.2 – AI Misinterpretation Hunt

## Tóm tắt kết quả review

Tôi đã đọc độc lập các bản ghi trong bốn file JTL, đối chiếu `statistics.json` trong bốn HTML Dashboard của JMeter và tham khảo báo cáo Task 1.

**Không xác nhận được lỗi số học trong các tổng số mẫu, success/failure, HTTP code, average, median, min/max hoặc request throughput của `AI_Analysis.md`.** Các khác biệt percentile có thể tái hiện bằng hai percentile conventions khác nhau; đây là **Calculation Method Difference**, không tự động là lỗi. Spike outliers và nhận định Soak không suy giảm đơn điệu cũng được raw JTL xác nhận.

Thiếu sót chính là AI không tính **completed end-to-end workflows/second**: throughput đã nêu là request samples/second. Ngoài ra, Task 1 có một số quan sát tài nguyên ngoài JTL và xác nhận JMeter/backend chạy cùng máy; các thông tin đó cần được phân biệt với dữ liệu JTL, không được biến thành kết luận về CPU saturation hay memory leak.

## Phạm vi và nguồn

| Kịch bản | Raw JTL đã kiểm tra | JMeter HTML Dashboard data |
|---|---|---|
| Load | `task1/results/load/20261120_195907/load.jtl` | `task1/results/load/20261120_195907/html/statistics.json` |
| Stress | `task1/results/stress/20261121_084816/stress.jtl` | `task1/results/stress/20261121_084816/html/statistics.json` |
| Spike | `task1/results/spike/20261121_091902/spike.jtl` | `task1/results/spike/20261121_091902/html/statistics.json` |
| Soak | `task1/results/soak/20261121_094256/soak.jtl` | `task1/results/soak/20261121_094256/html/statistics.json` |

Tệp tham khảo thêm: [AI_Analysis.md](AI_Analysis.md) và [báo cáo Task 1](../task1/23120184_HW05_Task1_Report.md). Template `analysis.md` không còn trong workspace; kết quả review được lưu trong tài liệu này. Cả bốn HTML Dashboard và `statistics.json` đều hiện diện.

Các JTL có cùng header 17 cột; ví dụ [header Load](../task1/results/load/20261120_195907/load.jtl#L1), [Stress](../task1/results/stress/20261121_084816/stress.jtl#L1), [Spike](../task1/results/spike/20261121_091902/spike.jtl#L1), [Soak](../task1/results/soak/20261121_094256/soak.jtl#L1). Các cột gồm `timeStamp`, `elapsed`, `label`, `responseCode`, `responseMessage`, `threadName`, `dataType`, `success`, `failureMessage`, `bytes`, `sentBytes`, `grpThreads`, `allThreads`, `URL`, `Latency`, `IdleTime`, `Connect`. Không có trường CPU hay RAM.

## 1. Kiểm chứng độc lập từ JTL

Đếm trên tất cả data rows (không tính header):

| Scenario | Sample rows / dòng JTL | Login | Orders list | Confirm order | Check order status | success | failure | HTTP response code |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Load | 200 / dòng 2–201 | 50 | 50 | 50 | 50 | 200 | 0 | 200: 200 |
| Stress | 1,600 / dòng 2–1,601 | 400 | 400 | 400 | 400 | 1,600 | 0 | 200: 1,600 |
| Spike | 304 / dòng 2–305 | 76 | 76 | 76 | 76 | 304 | 0 | 200: 304 |
| Soak | 3,890 / dòng 2–3,891 | 975 | 975 | 970 | 970 | 3,890 | 0 | 200: 3,890 |
| **Tổng** | **5,994** | **1,501** | **1,501** | **1,496** | **1,496** | **5,994** | **0** | **200: 5,994** |

Các số đếm được tính từ toàn bộ khoảng data rows của từng file: [Load JTL, dòng 2–201](../task1/results/load/20261120_195907/load.jtl#L2), [Stress, dòng 2–1,601](../task1/results/stress/20261121_084816/stress.jtl#L2), [Spike, dòng 2–305](../task1/results/spike/20261121_091902/spike.jtl#L2), [Soak, dòng 2–3,891](../task1/results/soak/20261121_094256/soak.jtl#L2). Tất cả records đều có `success=true`, response code `200`; error rate tính từ JTL là 0%.

### Response bytes, Latency và Connect

| Scenario | `bytes` average / median | Latency average / P95 / max (ms) | Connect average / P95 / max (ms) |
|---|---:|---:|---:|
| Load | 4,590.52 / 4,652 | 7.715 / 16.05 / 62 | 0.270 / 0 / 44 |
| Stress | 34,310.46 / 34,203 | 7.846 / 15 / 59 | 0.074 / 0 / 34 |
| Spike | 40,936.05 / 40,987 | 33.595 / 19 / 1,653 | 0.405 / 3 / 23 |
| Soak | 176,401.77 / 176,002 | 19.487 / 48 / 391 | 0.040 / 0 / 30 |

`bytes` là phản hồi theo JMeter, không phải tổng byte trên wire. Latency và Connect lấy trực tiếp từ các cột tương ứng; percentile tính theo linear rank đã nêu. Đây là aggregate trên mọi nhãn trong từng JTL.

### Average, median, percentiles, min/max

`AI linear` bên dưới được tính lại trên raw JTL theo đúng công thức mà AI_Analysis nêu: vị trí zero-based `h=(n−1)×p`, nội suy tuyến tính. Dashboard dùng các trường `pct1ResTime`, `pct2ResTime`, `pct3ResTime` lần lượt cho P90, P95, P99.

| Scenario | Avg / median (ms) | AI linear P90 / P95 / P99 (ms) | Dashboard P90 / P95 / P99 (ms) | Min / max (ms) |
|---|---:|---:|---:|---:|
| Load | 7.86 / 6 | 14 / 16.05 / 21.07 | 14 / 16.95 / 27.93 | 3 / 62 |
| Stress | 8.4281 / 8 | 14 / 17 / 31 | 14 / 17 / 31 | 0 / 60 |
| Spike | 35.4539 / 11 | 23 / 32 / 1,291.67 | 23.5 / 32.75 / 1,324.30 | 2 / 1,653 |
| Soak | 21.4213 / 15 | 47 / 59 / 91.22 | 47 / 59 / 93.09 | 0 / 391 |

`AI_Analysis.md` hiển thị một số kết quả đã làm tròn, ví dụ Load P95 16.1 và P99 21.1 ms; đây là cách trình bày của giá trị raw-linear 16.05 và 21.07 ms. Các Dashboard totals có thể xem tại [Load statistics.json, dòng 34–46](../task1/results/load/20261120_195907/html/statistics.json#L34), [Stress](../task1/results/stress/20261121_084816/html/statistics.json#L34), [Spike](../task1/results/spike/20261121_091902/html/statistics.json#L34), [Soak](../task1/results/soak/20261121_094256/html/statistics.json#L34). Bảng P90/P95/P99 trong Task 1 cũng trùng các giá trị Dashboard ([Task 1, dòng 228–230](../task1/23120184_HW05_Task1_Report.md#L228)).

### Request throughput và completed workflow throughput

**Method:** request throughput = tổng samples / khoảng đo. Khoảng đo tính từ `min(timeStamp)` đến `max(timeStamp + elapsed)`, giống kết quả `throughput` trong Dashboard. Một completed workflow được đếm khi cùng một `threadName` hoàn tất đủ thứ tự bốn nhãn `01 → 02 → 03 → 04`. Workflow throughput = số workflow hoàn tất / cùng khoảng đo. Task 1 mô tả luồng nghiệp vụ bốn bước này ([Task 1, dòng 79](../task1/23120184_HW05_Task1_Report.md#L79)); sequence được đếm trên toàn bộ data rows của [Load JTL](../task1/results/load/20261120_195907/load.jtl#L2), [Stress JTL](../task1/results/stress/20261121_084816/stress.jtl#L2), [Spike JTL](../task1/results/spike/20261121_091902/spike.jtl#L2), và [Soak JTL](../task1/results/soak/20261121_094256/soak.jtl#L2).

| Scenario | Sample span | Request throughput (samples/s) | Completed workflows | Workflow throughput (workflows/s) |
|---|---:|---:|---:|---:|
| Load | 38.902 s | 5.1411 | 50 | 1.2853 |
| Stress | 89.316 s | 17.9139 | 400 | 4.4785 |
| Spike | 65.794 s | 4.6205 | 76 | 1.1551 |
| Soak | 609.651 s | 6.3807 | 970 | 1.5911 |

Ba kịch bản đầu có đúng 4 samples cho mỗi workflow hoàn tất. Soak có 970 workflow đủ bốn bước và 5 workflow chưa hoàn tất khi dừng: label 01 và 02 nhiều hơn label 03 và 04 mỗi loại 5 samples. Các workflow dở dang bắt đầu tại các data rows 3,870, 3,878, 3,882, 3,886 và 3,890; phần cuối JTL cho thấy các thread còn xử lý label 01/02 khi run kết thúc ([Soak rows 3,870–3,891](../task1/results/soak/20261121_094256/soak.jtl#L3870)). Không dùng `3890/4` làm số completed workflow vì phép chia đó tính cả phần workflow chưa hoàn thành.

## 2. Findings theo template

| Phân loại | Nhận định trong AI_Analysis.md | Giá trị / bằng chứng độc lập từ JTL và nguồn đối chiếu | Calculation method | Kết luận human review |
|---|---|---|---|---|
| **Correct AI Interpretation** | Có 5,994 samples, tất cả success/HTTP 200, không lỗi ([AI report, dòng 40–44](AI_Analysis.md#L40)). | Raw rows: Load 2–201, Stress 2–1,601, Spike 2–305, Soak 2–3,891; mỗi scenario đều 0 failed và chỉ response code 200. | Đếm từng data row, nhóm theo `label`, `success`, `responseCode`. | Đúng. Không có lỗi số đếm hay HTTP code được xác nhận. |
| **Correct AI Interpretation** | Avg, median, min/max và request throughput được báo cáo theo từng scenario ([AI report, dòng 64–67](AI_Analysis.md#L64)). | Các avg/median/min/max khớp kết quả tự tính từ JTL. Request throughput lần lượt là 5.1411, 17.9139, 4.6205, 6.3807 samples/s và khớp Dashboard. | Thống kê trên mọi `elapsed`; request rate là samples chia sample span. | Đúng cho request-level metrics. Không đồng nghĩa với throughput workflow. |
| **Correct AI Interpretation** | AI báo response bytes, Latency và Connect theo scenario ([AI report, dòng 72–77](AI_Analysis.md#L72)). | Các average/median/P95/max tự tính từ JTL khớp bảng trên. | Tổng hợp các cột `bytes`, `Latency`, `Connect` trên toàn bộ data rows của mỗi scenario; P95 theo linear rank. | Đúng. Giá trị là aggregate trộn nhiều request labels. |
| **Calculation Method Difference** | AI báo P90/P95/P99 theo linear interpolation, với `h=(n−1)p` ([AI report, dòng 51](AI_Analysis.md#L51)). | Ví dụ Load: AI linear `14/16.05/21.07`, Dashboard `14/16.95/27.93`; Spike: `23/32/1,291.67` so với `23.5/32.75/1,324.30`. Stress P90/P95/P99 trùng; Soak P90/P95 trùng nhưng P99 là 91.22 so với 93.09. Các raw inputs là toàn bộ data rows của từng JTL, ví dụ [Spike JTL, dòng 2–305](../task1/results/spike/20261121_091902/spike.jtl#L2). | Tính lại raw JTL theo `(n−1)p`; đối chiếu Dashboard `statistics.json`. Kết quả Dashboard khớp với nội suy vị trí kiểu `p(n+1)` có chặn ở min/max. | Không xác nhận lỗi tính toán. Hai percentile conventions cho ra các giá trị khác nhau, đặc biệt ở tail và mẫu ít. Cần ghi rõ convention khi so sánh. |
| **Calculation Method Difference** | AI báo Spike label 03 P95 = 347.25 ms ([AI report, dòng 94](AI_Analysis.md#L94)). | JMeter Dashboard cho P95 label 03 = 1,282.65 ms (`pct2ResTime` của label này tại [Spike statistics.json, dòng 8–14](../task1/results/spike/20261121_091902/html/statistics.json#L8)); đối chiếu với 76 samples thuộc label 03 trong [Spike JTL, dòng 2–305](../task1/results/spike/20261121_091902/spike.jtl#L2). | So sánh linear `h=(n−1)p` với Dashboard `pct2ResTime`; các outlier làm kết quả nhạy với vị trí percentile. | Đây là khác biệt phương pháp, không phải lỗi số học đã xác nhận. Tuy nhiên, khác biệt lớn này cần được nêu vì diễn giải P95 riêng cho confirm-order thay đổi đáng kể; raw có bốn mẫu của label này trên 1 giây. |
| **Missing Analysis / Omission** | AI chỉ báo sample throughput, đồng thời nói đây là aggregate sampler rate ([AI report, dòng 53, 62–67](AI_Analysis.md#L53)). | Request rates là 5.1411 / 17.9139 / 4.6205 / 6.3807 samples/s. Completed workflow rates tính từ JTL là 1.2853 / 4.4785 / 1.1551 / 1.5911 workflows/s. | Count chuỗi nhãn 01→02→03→04 theo từng `threadName`; chia số workflow hoàn tất cho sample span. Soak loại 5 workflow dở dang. | Sample throughput AI báo là đúng, nhưng thiếu workflow throughput mà Task 2.2 yêu cầu. Đây là omission, không phải sai số request rate. |
| **Correct AI Interpretation** | AI ghi nhận 5 response Spike >1,000 ms xuất hiện sau khoảng high-concurrency records; không kết luận quan hệ nhân quả ([AI report, dòng 113–123](AI_Analysis.md#L113)). | Chi tiết từng record ở bảng Spike bên dưới: 5/304 mẫu; tất cả `allThreads=2`, `Connect=0`, `success=true`, HTTP 200; timestamp từ 02:19:54.941 đến 02:20:01.344 UTC. | Đọc trực tiếp từng dòng JTL; tính thời gian tương đối với sample cuối có `allThreads>=18` và sample cuối của spike group. | Outlier count, giá trị và cảnh báo không suy diễn nguyên nhân đều đúng. Cần phân biệt peak-thread window với toàn bộ mẫu của spike thread group. |
| **Correct AI Interpretation** | AI kết luận Soak biến động, không monotonic, có tăng rồi hồi phục ([AI report, dòng 127–147](AI_Analysis.md#L127)). | Raw minute buckets xác nhận tăng ở elapsed 420–480 s, max 391 ms ở 480–540 s, rồi giảm ở 540–600 s và đoạn cuối 600–609.651 s. | Bin theo `timeStamp` tương đối với sample đầu; tính n, average, P95 linear và max mỗi bin. | Đúng về hình dạng xu hướng; không có bằng chứng cho suy giảm đơn điệu. |
| **Calculation Method Difference** | AI dùng bin tên `0` đến `10`, rồi tóm tắt là “minutes 7–8” và cải thiện sau đó ([AI report, dòng 131–145](AI_Analysis.md#L131)). | Bin 7 là elapsed 420–480 s (phút thứ 8); bin 8 là 480–540 s (phút thứ 9); hồi phục ở 540–600 s (phút thứ 10). | Cùng sample/time bins, chỉ đổi cách đặt tên zero-based index sang elapsed interval/one-based minute. | Không có sai lệch số liệu hay kết luận monotonic. Đây là khác biệt đánh số bin; nên ghi elapsed interval hoặc thống nhất minute 1-based. |
| **Correct AI Interpretation** | AI nói raw JTL không có CPU/RAM, nên không thể kết luận CPU saturation hay memory leak từ JTL ([AI report, dòng 159, 169](AI_Analysis.md#L159)). | Các header 17 cột của cả bốn JTL không có CPU/RAM fields. Báo cáo Task 1 riêng có ba ảnh Task Manager: 26,136 K (phút 1), 42,320 K (phút 5), 62,348 K (phút 10), và CPU snapshots 00–01 ([Task 1, dòng 365–376, 398–408](../task1/23120184_HW05_Task1_Report.md#L365)). Giữa phút 5 và 10, working set tăng 20,028 K (47.3%), nhưng đây là hai snapshot rời rạc. | Tách raw JTL khỏi snapshot ngoài JTL; không nội suy thời gian giữa các snapshot. | Nhận định của AI về JTL là đúng. Snapshot ngoài JTL cho thấy mức tăng ở các thời điểm chụp, nhưng không đủ đánh giá điều kiện “sustained/no plateau” trong ngưỡng AI đề xuất và không chứng minh leak hoặc CPU saturation. |
| **Missing Analysis / Omission** | AI nói `success=true` và HTTP 200 không tự chứng minh nội dung/logic nghiệp vụ ([AI report, dòng 170](AI_Analysis.md#L170)). | JMeter plans có JMESPath assertions ở bước 02 và 04, kiểm tra trạng thái đúng `orderId` trước/sau confirm; ví dụ [Load plan, dòng 83–90 và 155–162](../task1/plans/23120184_Load_20261120.jmx#L83), [Stress](../task1/plans/23120184_Stress_20261120.jmx#L83), [Spike](../task1/plans/23120184_Spike_20261121.jmx#L93), [Soak](../task1/plans/23120184_Soak_20261121.jmx#L86). Các mẫu tương ứng trong JTL đều `success=true`. | Đối chiếu assertion trong JMX với cột `success` của JTL. | Câu cảnh báo AI đúng nếu chỉ nhìn status code; nhưng report bỏ sót assertion đã cấu hình ở bước 02/04. Không chứng minh toàn bộ workflow vì login/confirm không có assertion riêng cho response body. |
| **Missing Analysis / Omission** | AI khuyến nghị xác nhận liệu generator và service có chung host không ([AI report, dòng 171](AI_Analysis.md#L171)). | Báo cáo Task 1 đã xác nhận JMeter và backend chạy cùng một máy qua `localhost`, và cùng chia sẻ CPU/RAM ([Task 1, dòng 35, 49, 57–59](../task1/23120184_HW05_Task1_Report.md#L35)). | Đối chiếu mô tả môi trường trong Task 1; đây không phải field có trong JTL. | Không phải sai dữ liệu JTL, nhưng AI bỏ sót thông tin đã có trong báo cáo đầu vào; nên nêu rủi ro load-generator contention như một điều kiện đã biết, không chỉ yêu cầu xác minh. |
| **Correct AI Interpretation** | AI phân biệt measured baseline với các ngưỡng warning/failure đề xuất ([AI report, dòng 151–161](AI_Analysis.md#L151)). | Các ngưỡng 120/250 ms P95, 200/400 ms P99, 0.1%/1% lỗi và 10%/20% memory growth không xuất hiện trong JTL/Dashboard; đây là giá trị AI đề xuất. | Đối chiếu nội dung report với raw JTL; không coi ngưỡng đề xuất là kết quả đo. | Đúng khi được gắn nhãn provisional/proposed. Cần phê duyệt theo SLA và xác định target throughput trước khi dùng làm gate. |
| **Missing Analysis / Omission** | AI nhận xét tất cả P95 gộp theo scenario thấp hơn mức cảnh báo 120 ms ([AI report, dòng 156](AI_Analysis.md#L156)). | Spike label 03 có P95 linear 347.25 ms theo chính convention của AI; Dashboard cho 1,282.65 ms. Cả hai vượt AI đề xuất ngưỡng failure P95 >250 ms nếu ngưỡng được áp theo request label. | Đối chiếu per-label P95 của raw JTL/Dashboard với ngưỡng do AI đề xuất; không dùng P95 gộp để thay P95 của từng endpoint. | Câu về P95 gộp là đúng. Thiếu sót là không làm rõ threshold scope và không chỉ ra label 03 sẽ fail nếu ngưỡng áp dụng theo request. Đây là conditional omission, không phải lỗi tính P95. |

### Phân vị: so sánh chi tiết với Dashboard

Các trường `pct1ResTime`, `pct2ResTime`, `pct3ResTime` trong `statistics.json` tương ứng P90/P95/P99. Dashboard không thể thay thế raw JTL để kiểm chứng sample-level findings, nhưng có thể dùng đối chiếu cách tính percentile. Một ví dụ per-label cho thấy chênh lệch lớn hơn ở phần đuôi: P95 order-confirm của Spike là 347.25 ms theo linear rank của AI và 1,282.65 ms trong Dashboard. Điều này vẫn không bác bỏ các raw outlier; nó phản ánh vị trí rank khác nhau trong một nhóm có ít mẫu chậm.

### Năm Spike outliers >1,000 ms

| JTL line | Timestamp UTC | Label | Elapsed (ms) | allThreads | Connect (ms) | success | responseCode | threadName group |
|---:|---|---|---:|---:|---:|---|---:|---|
| 274 | 2026-11-21 02:19:54.941 | 03 - Confirm order | 1,281 | 2 | 0 | true | 200 | Spike_Nen_2_users |
| 278 | 2026-11-21 02:19:56.482 | 03 - Confirm order | 1,517 | 2 | 0 | true | 200 | Spike_Nen_2_users |
| 282 | 2026-11-21 02:20:00.053 | 03 - Confirm order | 1,292 | 2 | 0 | true | 200 | Spike_Nen_2_users |
| 283 | 2026-11-21 02:20:01.013 | 03 - Confirm order | 1,653 | 2 | 0 | true | 200 | Spike_Nen_2_users |
| 284 | 2026-11-21 02:20:01.344 | 04 - Check order status | 1,326 | 2 | 0 | true | 200 | Spike_Nen_2_users |

Nguồn từng dòng: [Spike JTL 274](../task1/results/spike/20261121_091902/spike.jtl#L274), [278](../task1/results/spike/20261121_091902/spike.jtl#L278), [282](../task1/results/spike/20261121_091902/spike.jtl#L282), [283](../task1/results/spike/20261121_091902/spike.jtl#L283), [284](../task1/results/spike/20261121_091902/spike.jtl#L284).

Tất cả năm mẫu đều thuộc nhóm 2-user nền, xảy ra sau peak và sau các mẫu của nhóm 18-user. Nhóm `Spike_Dot_18_users` có sample đầu ở dòng 38 (02:19:20.034 UTC) và completion cuối ở dòng 205 (02:19:28.436 UTC); nhóm có 144 sample records. Các mẫu có `allThreads>=18` chỉ trải từ dòng 72 (02:19:20.871) đến dòng 171 (02:19:25.656), 100 records. Vì vậy hai khoảng này không đồng nhất: AI đo “peak/high-concurrency window” theo ngưỡng `allThreads>=18`, trong khi toàn bộ spike-group records trải qua khoảng dài hơn. Năm outliers bắt đầu khoảng 26.5–32.9 giây sau completion cuối được ghi nhận của nhóm spike ([dòng 38](../task1/results/spike/20261121_091902/spike.jtl#L38), [dòng 205](../task1/results/spike/20261121_091902/spike.jtl#L205)).

### Soak minute trend và cách đánh số bin

Bins dưới đây được ghi bằng elapsed-time interval để tránh nhập nhằng 0-based/1-based:

| Elapsed interval (s) | Samples | Average (ms) | P95 linear (ms) | Max (ms) |
|---:|---:|---:|---:|---:|
| 0–60 | 366 | 18.34 | 46 | 74 |
| 60–120 | 368 | 23.61 | 59 | 118 |
| 120–180 | 376 | 23.35 | 54 | 87 |
| 180–240 | 384 | 17.60 | 52.7 | 77 |
| 240–300 | 380 | 18.54 | 44.05 | 71 |
| 300–360 | 380 | 21.09 | 57.05 | 95 |
| 360–420 | 384 | 25.62 | 66.85 | 94 |
| 420–480 | 397 | 34.47 | 97.2 | 253 |
| 480–540 | 387 | 21.76 | 60.4 | 391 |
| 540–600 | 396 | 11.27 | 27 | 53 |
| 600–609.651 (partial) | 72 | 12.86 | 28.9 | 44 |

Các con số khớp bins 0–10 của AI_Analysis. Chỉ khác cách gọi: bin 0 của AI là phút thứ nhất (elapsed 0–60s); bin 7 là elapsed 420–480s (phút thứ 8); bin 8 có max 391ms (phút thứ 9); bin 9 giảm (phút thứ 10). Vì vậy không có cơ sở nói xu hướng suy giảm đơn điệu. Toàn bộ phép tính dùng các rows 2–3,891 trong [Soak JTL](../task1/results/soak/20261121_094256/soak.jtl#L2); các outlier minh họa gồm [dòng 2,847](../task1/results/soak/20261121_094256/soak.jtl#L2847), [3,148](../task1/results/soak/20261121_094256/soak.jtl#L3148), [3,184](../task1/results/soak/20261121_094256/soak.jtl#L3184).

## 3. Bảng “Tối ưu AI đề xuất” theo template

AI_Analysis không đề xuất code changes cụ thể; các mục dưới đây là khuyến nghị vận hành/kiểm thử, không phải kết quả đo.

| Tối ưu / khuyến nghị AI đề xuất | Bằng chứng từ mã nguồn, cấu hình hoặc log | Khả thi / hallucinated và lý do |
|---|---|---|
| Dùng ngưỡng provisional cho error rate, P95/P99, throughput và memory growth. | JTL/Dashboard cung cấp baseline đo được; không có SLA/target throughput được khai báo. Các ngưỡng được gắn nhãn “proposed” trong [AI_Analysis.md](AI_Analysis.md#L151). | Khả thi như điểm khởi đầu, không phải SLO đã xác nhận. Cần thống nhất payload, workload, target throughput và chính sách release trước khi dùng làm pass/fail. Không phải số đo bị bịa vì được đánh dấu là đề xuất. |
| Lặp lại Spike, thu thập backend logs/traces và resource metrics. | Năm raw samples >1s tại Spike JTL dòng 274, 278, 282–284; không có CPU/RAM/time-series telemetry trong JTL. | Khả thi và được raw tail latency hỗ trợ. Không suy diễn nguyên nhân trước khi có telemetry. |
| Chạy Soak dài hơn và thu thập memory time series. | JTL Soak kéo dài 609.651s; Task 1 mô tả ba Task Manager snapshots, không phải liên tục. | Khả thi. Snapshot tăng theo thời gian là tín hiệu cần đo tiếp, không đủ để xác nhận leak. |
| Chuẩn hóa response payload và cấu hình tải trước khi so Load/Stress/Soak. | Raw `bytes` ở order-list khác đáng kể giữa bốn JTL; Task 1 cũng ghi kích thước bảng đơn khác nhau. | Khả thi và cần thiết để diễn giải công bằng; không phải yêu cầu thay đổi backend đã được chứng minh. |

## 4. Kết luận phân loại

- **Confirmed Misinterpretation:** không tìm thấy lỗi số học được xác nhận trong các giá trị chính AI báo từ raw JTL.
- **Calculation Method Difference:** P90/P95/P99 khác Dashboard do percentile convention; riêng Spike order-confirm P95 khác đáng kể nhưng cả hai được tái tạo từ cùng raw samples theo phương pháp đã nêu. Nhãn bin Soak 0-based so với phút 1-based cũng là khác biệt biểu diễn.
- **Missing Analysis / Omission:** chưa tính completed workflows/s; không làm rõ việc áp threshold theo từng label; không nêu assertion JMeter ở bước 02/04; không kết hợp ngữ cảnh Task 1 đã xác nhận cùng host và có các ảnh Task Manager ngoài JTL.
- **Correct AI Interpretation:** counts, status/error rate, average/median/min/max, response bytes, Latency/Connect, sample throughput, Spike tail, Soak non-monotonic trend, giới hạn CPU/RAM của JTL, và việc các threshold được đề xuất chứ không phải measured.

Không kết luận CPU saturation, memory leak, server capacity, hay nguyên nhân tầng backend từ JTL. Không sửa `AI_Analysis.md` hoặc bất kỳ JTL nào trong quá trình lập báo cáo này.
