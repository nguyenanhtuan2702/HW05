# HW05 · Performance Testing trên EShop

Workflow cá nhân: admin đăng nhập → đọc danh sách đơn → xác nhận một đơn pending → đọc lại đúng mã đơn ở trạng thái confirmed.

## Bắt đầu

Chạy EShop từ repo ứng dụng. Lưu kế hoạch JMeter, dữ liệu và báo cáo trong repo HW05 này. Bắt đầu từ [ghi nhận API](task1/workflow.md). Khi đã biết đủ endpoint, chạy thử 1 thread × 1 vòng trên một đơn thử mới. Commit riêng sau mỗi bước.

## Tóm tắt để nộp

| Nội dung | Kết quả thực tế |
|---|---|
| MSSV / commit EShop dùng để đo | |
| Kịch bản đã chạy | |
| Nhóm endpoint đã kiểm thử | |
| Ngưỡng ổn định, thời gian giữ tải, RPS, p95, lỗi và bộ nhớ backend | |
| Số lỗi hoặc vấn đề hiệu năng / link GitHub Issues | |
| Link video YouTube unlisted | |
| Link repo GitHub công khai để nộp | |

## Tự đánh giá

| Tiêu chí | Tối đa | Tự chấm |
|---|---:|---:|
| Load | 30 | |
| Stress | 20 | |
| Spike | 20 | |
| Phân tích AI và đối chiếu log | 10 | |
| Đề xuất continuous performance testing | 10 | |
| Agent Skill và demo | 10 | |
| Tổng | 100 | |

## Checklist nộp Moodle

- [ ] Ba test plan theo mẫu `{StudentID}_{ScenarioType}_{YYYYMMDD}.jmx`, dữ liệu CSV, ba raw JTL đầy đủ và ba thư mục HTML report.
- [ ] Ba kiểu listener/report view khác nhau. Ảnh công cụ cùng mức sử dụng tài nguyên của tiến trình backend cho từng lần chạy.
- [ ] Soak 10–15 phút, kết quả có số liệu. Ảnh dxdiag và bảng cấu hình máy, hostname khớp các bài trước.
- [ ] Video unlisted ≥6 phút tổng cộng, công cụ và resource monitor cùng khung hình, giọng thuyết minh tiếng Việt của mình.
- [ ] Báo cáo chính, AI Audit và AI Critique có bản Markdown + PDF. Đưa AI Audit vào phụ lục báo cáo chính.
- [ ] README có bảng tự chấm và tóm tắt. Đính kèm link repo, video, issue và ảnh nếu có. Nếu làm Agent Skill, đính kèm skill và link demo trọn một nhóm endpoint.
- [ ] Sau commit nội dung cuối, chạy trong PowerShell: `git log --oneline --reverse | Out-File -Encoding utf8 git-log.txt`.
- [ ] ZIP nộp: `<StudentID>_HW05_AI_Performance_<SelfAssessedGrade>.zip`, điểm gồm 3 chữ số từ 000 đến 100.
