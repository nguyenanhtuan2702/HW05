# HW05 · Performance Testing trên EShop

**MSSV:** 23120184 · **Tự đánh giá đề xuất:** 084/100
**SUT:** [EShop](https://github.com/ttbhanh/eshop-sut) · **Repo bài nộp:** [nguyenanhtuan2702/HW05](https://github.com/nguyenanhtuan2702/HW05)

> Điểm 084 là tự đánh giá cho chất lượng nội dung hiện có, không phải điểm chính thức. Các PDF đã được xuất; cần hoàn thiện nội dung bản PDF chính, bổ sung nhật ký AI đầy đủ và đóng gói ZIP theo checklist trước khi nộp.

## Tóm tắt kết quả

Workflow quản trị gồm đăng nhập, đọc danh sách đơn, xác nhận một đơn `pending`, rồi đọc lại để kiểm tra đúng `orderId` đã thành `confirmed`. Luồng bao phủ ba nhóm endpoint: auth-heavy, read-heavy và transactional.

| Kịch bản | Tải | Samples | Workflow hoàn tất | Request/s | Workflow/s | P95 toàn lượt | Lỗi |
|---|---|---:|---:|---:|---:|---:|---:|
| Load | 5 VU, 10 vòng/VU | 200 | 50 | 5,14 | 1,285 | 16,95 ms | 0 |
| Stress | 20 VU, 20 vòng/VU | 1.600 | 400 | 17,91 | 4,478 | 17,00 ms | 0 |
| Spike | 2 VU nền, tăng lên 20 VU | 304 | 76 | 4,62 | 1,155 | 32,75 ms | 0 |
| Soak | 5 VU trong 610 s | 3.890 | 970 | 6,38 | 1,591 | 59,00 ms | 0 |

P95 lấy từ JMeter Dashboard cho toàn kịch bản, không đại diện cho riêng một endpoint. Có năm mẫu Spike chậm hơn 1 giây; chưa xác định nguyên nhân từ JTL. Kết quả Stress là mức tải đã thử, không xác định capacity tối đa.

### Endurance: mức tải ổn định đã quan sát

Ở cấu hình Soak 5 VU, hệ thống chạy **609,651 giây (10 phút 10 giây)** với **6,38 request/s**, **P95 59 ms**, **0 lỗi trên 3.890 request** và **970 workflow hoàn tất (1,591 workflow/s)**. Đây là mức tải ổn định quan sát được trong cấu hình này, **không phải RPS tối đa hoặc giới hạn capacity đã xác định**.

Working set backend tại ba snapshot là 26.136 K (phút 1), 42.320 K (phút 5) và 62.348 K (phút 10). 62.348 K là mức cao nhất trong các snapshot, không phải memory ceiling; các ảnh chụp rời rạc cũng chưa đủ kết luận memory leak.

## Test plans và kết quả

| Kịch bản | Test plan | Dữ liệu | JTL | HTML Dashboard |
|---|---|---|---|---|
| Load | [23120184_Load_20261120.jmx](task1/plans/23120184_Load_20261120.jmx) | [orders.csv](task1/data/orders.csv) | [load.jtl](task1/results/load/20261120_195907/load.jtl) | [Mở dashboard](task1/results/load/20261120_195907/html/index.html) |
| Stress | [23120184_Stress_20261120.jmx](task1/plans/23120184_Stress_20261120.jmx) | [orders_stress.csv](task1/data/orders_stress.csv) | [stress.jtl](task1/results/stress/20261121_084816/stress.jtl) | [Mở dashboard](task1/results/stress/20261121_084816/html/index.html) |
| Spike | [23120184_Spike_20261121.jmx](task1/plans/23120184_Spike_20261121.jmx) | [orders_spike.csv](task1/data/orders_spike.csv) | [spike.jtl](task1/results/spike/20261121_091902/spike.jtl) | [Mở dashboard](task1/results/spike/20261121_091902/html/index.html) |
| Soak | [23120184_Soak_20261121.jmx](task1/plans/23120184_Soak_20261121.jmx) | [orders_soak.csv](task1/data/orders_soak.csv) | [soak.jtl](task1/results/soak/20261121_094256/soak.jtl) | [Mở dashboard](task1/results/soak/20261121_094256/html/index.html) |

Ba plan bắt buộc dùng ba report view khác nhau: Summary Report (Load), Aggregate Report (Stress), Aggregate Graph (Spike). Soak là kịch bản endurance bổ sung.

## Vấn đề và minh chứng

- **Lỗi chức năng:** 0/5.994 request thất bại.
- **Vấn đề hiệu năng được ghi nhận:** ba issue trên repo EShop:
  - [nguyenanhtuan2702/eshop-sut#201](https://github.com/nguyenanhtuan2702/eshop-sut/issues/201) — danh sách đơn quản trị không phân trang.
  - [nguyenanhtuan2702/eshop-sut#202](https://github.com/nguyenanhtuan2702/eshop-sut/issues/202) — năm request Spike có độ trễ trên 1 giây.
  - [nguyenanhtuan2702/eshop-sut#203](https://github.com/nguyenanhtuan2702/eshop-sut/issues/203) — working set tăng qua ba snapshot Soak; chưa đủ kết luận memory leak.
- Mô tả và tham chiếu tới log/ảnh: [HW05_Task1_GitHub_Issues.md](task1/HW05_Task1_GitHub_Issues.md), [báo cáo Task 1](task1/23120184_HW05_Task1_Report.md), [thư mục evidence](task1/evidence).

## Tự đánh giá

| Tiêu chí | Tối đa | Tự chấm đề xuất | Cơ sở |
|---|---:|---:|---|
| Task 1 — Load | 30 | 26 | Có plan, dữ liệu, JTL, dashboard và workflow assertion; còn thiếu ảnh dxdiag/screenfetch theo đúng rubric. |
| Task 1 — Stress | 20 | 17 | Đã chạy 20 VU, 0 lỗi; chưa xác định điểm gãy/capacity tối đa. |
| Task 1 — Spike | 20 | 16 | Đã chạy và ghi nhận outlier bằng JTL; chưa lặp lại để xác minh khả năng tái hiện/nguyên nhân. |
| Task 2 — AI analysis và misinterpretation hunt | 10 | 8 | Có phân tích raw JTL, human review và critique; AI Audit hiện còn ở dạng tóm lược tương tác. |
| Task 3 — Continuous performance testing | 10 | 9 | Có lưu đồ, điều kiện chạy, ngưỡng P95 và trade-off; đây là đề xuất, chưa triển khai CI. |
| Agent Skill và demo | 10 | 8 | Có [Agent Skill](agent/eshop-jmeter/SKILL.md) và link demo; cần tự xác nhận thời lượng/nội dung video đúng yêu cầu. |
| **Tổng** | **100** | **84** | Điểm tự đánh giá đề xuất; giảng viên quyết định điểm chính thức. |

## Tài liệu

- Báo cáo tổng hợp: [report/report.md](report/report.md)
- PDF hiện có: [AI Audit](ai/AI_AUDIT.pdf), [AI Critique](ai/AI_CRITIQUE.pdf). Báo cáo tổng hợp PDF chưa có; xem checklist bên dưới.
- Báo cáo chi tiết: [Task 1](task1/23120184_HW05_Task1_Report.md)
- Task 2: [AI analysis](task2/AI_Analysis.md), [recommendations](task2/AI_Recommendations.md), [human review](task2/Human_Review.md), [independent analysis](task2/Independent_Analysis.md), [misinterpretation hunt](task2/Misinterpretation_Hunt.md)
- Task 3: [đề xuất continuous testing](task3/proposal.md)
- AI: [Audit](ai/AI_AUDIT.md), [Critique](ai/AI_Critique.md)
- Agent Skill: [SKILL.md](agent/eshop-jmeter/SKILL.md)
- DxDiag summary: [dxdiag.txt](task1/evidence/dxdiag.txt), [DxDiag screenshot](task1/evidence/dxdiag.png), [hostname screenshot](task1/evidence/hostname.png)

## Video demo

- **Agent Skill demo:** [Xem trên YouTube](https://www.youtube.com/watch?v=LC_F-cynYG8)
- **Task 1 demo:** [Xem trên YouTube](https://www.youtube.com/watch?v=J2pilpxvBZo)

## Checklist trước khi nộp Moodle

- [x] Có ba plan Load/Stress/Spike đúng tên; có CSV, raw JTL và HTML Dashboard. Soak được bổ sung.
- [x] Có ba report view riêng cho ba plan bắt buộc.
- [x] Có ảnh resource monitor cùng màn hình chạy và bảng cấu hình phần cứng; hostname ghi nhận là `nguyenatuan143`.
- [x] Có Soak khoảng 10 phút với request/s, P95, lỗi và working-set snapshots được báo cáo có giới hạn rõ ràng.
- [x] Có AI Critique 200–300 từ và đề xuất Task 3 kèm lưu đồ.
- [x] Có Agent Skill, liên kết demo và các issue hiệu năng với tham chiếu tới log/ảnh minh chứng.
- [x] Bổ sung ảnh DxDiag và đối chiếu hostname trên DxDiag với lệnh `hostname` (khớp không phân biệt hoa/thường).
- [X] Xác nhận hostname hiện tại khớp với hostname trong bài trước.
- [X] Hoàn thiện AI Audit thành nhật ký đầy đủ từng tương tác (thời gian, prompt, output); hiện có bản Markdown/PDF tóm lược.
- [X] Cập nhật lại PDF báo cáo chính để bản nộp bao gồm báo cáo hiệu năng chi tiết, toàn văn AI Critique và đề xuất Task 3/lưu đồ; PDF hiện tại là bản tổng hợp ngắn.
- [X] Tạo `git-log.txt`; lịch sử hiện có chưa thể hiện commit riêng cho từng bước theo yêu cầu.
- [X] Xác nhận video unlisted, tổng thời lượng ít nhất 6 phút, có giọng thuyết minh tiếng Việt và tool/resource monitor trong cùng khung hình.

