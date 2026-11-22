# Phụ lục HW05 · AI Audit Report

**Nguyễn Anh Tuấn · MSSV 23120184 · 20–22/11/2026**

**Khai báo:** “I use AI tools for the following tasks.” ChatGPT hỗ trợ thiết kế và gỡ lỗi kịch bản JMeter, phân tích kết quả, soạn phần rà soát và đề xuất mô hình kiểm thử liên tục. Các công cụ thực nghiệm gồm Apache JMeter 5.6.3, PowerShell, Chrome DevTools và Windows Task Manager.

**Phạm vi nhật ký.** Các mục dưới đây trích những câu hỏi kỹ thuật và câu hỏi đối chiếu trong hội thoại. Phần trả lời được tóm tắt. Những lượt yêu cầu soạn trọn phần được ghi nhận theo sản phẩm, không trích nguyên văn. Ngày được ghi theo giờ Việt Nam. Những mốc giờ gắn với JMeter là giờ của mẫu hoặc lượt chạy; thời điểm gửi từng tin nhắn chưa được xác minh.

## Task 1 · Thiết lập, chạy và đọc kết quả

**1. Xác thực request quản trị · ChatGPT · 20/11/2026**

Prompt: “`Authorization = Bearer ${adminToken}` thêm này sao”

Đầu ra và đối chiếu: Trong HTTP Header Manager của request quản trị, đặt tên header là `Authorization` và giá trị là `Bearer ${adminToken}`. Khi bước 03 trả 403, phần Request cho thấy giá trị thực gửi là `HTTP Header Manager`. Sau khi sửa, cả bốn bước chạy thành công. Hai lần đọc danh sách cho thấy đơn số 1 chuyển từ `pending` sang `confirmed`. Mẫu lỗi 403 được JMeter ghi lúc 19:17:17.

**2. Đặt thời gian chờ trước khi xác nhận · ChatGPT · 20/11/2026**

Prompt: “Uniform Random Timer dưới `03`Offset `2000` ms, Random Delay `2000` ms này là cái nào nuiawx”

Đầu ra: Gắn Uniform Random Timer bên dưới sampler 03 để mô phỏng thời gian quản trị viên xem đơn trước khi xác nhận. Đặt phần cố định 2.000 ms và phần ngẫu nhiên 2.000 ms, tạo khoảng chờ xấp xỉ 2–4 giây. Thời gian này ảnh hưởng số vòng hoàn tất mỗi giây và cần được giữ nhất quán khi so sánh các lượt chạy.

**3. Kiểm tra Stress đang chạy hay đã kết thúc · ChatGPT · 21/11/2026**

Prompt: “nó đang chạy á hả”

Đầu ra và đối chiếu: Dòng tiến độ khi đó ghi `Active: 20` và `Finished: 0`. Lượt Stress vẫn đang chạy. Đến 08:49:49, terminal ghi `Active: 0`, `Finished: 20` và `end of run`. Tổng cuối cùng là 1.600 mẫu.

**4. Phân biệt thời gian phản hồi tối đa với số lỗi · ChatGPT · 21/11/2026**

Prompt: “60 err tôi tg là 60 lỗi chứ”

Đầu ra và đối chiếu: Trong chuỗi `Max: 60 Err: 0 (0.00%)`, giá trị 60 thuộc trường `Max` và có đơn vị mili giây. Giá trị của trường `Err` là 0. Kết quả được diễn giải trong báo cáo là 1.600 mẫu, thời gian phản hồi tối đa 60 ms và 0 mẫu lỗi.

**5. Đọc hai biểu đồ Spike · ChatGPT · 21/11/2026**

Prompt: “giải thích kết quả” (kèm biểu đồ số thread hoạt động và thời gian phản hồi).

Đầu ra và đối chiếu: Đối chiếu hai biểu đồ theo thời gian để xác định các request chậm xảy ra ở pha nào. Log gốc ghi năm mẫu trên một giây khi số thread hoạt động đã trở về 2. Bốn mẫu thuộc bước xác nhận đơn và một mẫu thuộc bước đọc lại. Kết quả đủ để ghi nhận độ trễ bất thường sau đỉnh tải; nguyên nhân cần thêm số đo từ backend.

## Task 2 · Rà soát phân tích do AI tạo

**6. Phân tích raw JTL và lập báo cáo cơ sở · ChatGPT · 22/11/2026**

Prompt (tóm lược): Yêu cầu phân tích trực tiếp các raw JTL của Load, Stress, Spike và Soak; tính các chỉ số, so sánh kịch bản, đề xuất ngưỡng provisional, nêu giới hạn dữ liệu và lưu báo cáo tại `task2/AI_Analysis.md`.

Đầu ra và đối chiếu: ChatGPT tính và tổng hợp số mẫu, trạng thái, response time, throughput, latency, connect và xu hướng theo kịch bản; đồng thời tách measured baselines khỏi proposed thresholds. Theo yêu cầu tiếp theo, báo cáo được chuyển sang tiếng Việt. Rà soát độc lập sau đó xác nhận các số đếm chính và request throughput; phát hiện thiếu completed workflow throughput và chưa phân biệt đủ rõ scenario-wide với endpoint-specific P95. Percentile khác Dashboard do calculation convention, không tự động là lỗi số học. Báo cáo cũng không suy ra CPU/RAM hay nguyên nhân backend từ JTL.

Sản phẩm: [AI_Analysis.md](../task2/AI_Analysis.md).

**7. Rà soát độc lập các diễn giải AI · ChatGPT · 22/11/2026**

Prompt (tóm lược): Đóng vai independent human reviewer; đọc raw JTL, đối chiếu JMeter Dashboard và báo cáo Task 1; kiểm tra percentile convention, workflow throughput, Spike outliers, Soak trend và phân loại từng finding.

Đầu ra và đối chiếu: Tạo [Misinterpretation_Hunt.md](../task2/Misinterpretation_Hunt.md), ghi rõ không xác nhận lỗi số học chính; phân loại percentile variance là Calculation Method Difference và nêu omission về completed workflows/s. Ví dụ: Soak có 3.890 request nhưng 970 workflow hoàn tất, khoảng 1,59 workflow/s; Spike có năm sample trên 1.000 ms sau high-concurrency window, nhưng raw JTL không xác định nguyên nhân. Báo cáo cũng xác nhận JTL không chứa CPU/RAM telemetry và Soak không suy giảm đơn điệu.

**8. Đề xuất tối ưu dựa trên source code · ChatGPT · 22/11/2026**

Prompt (tóm lược): Kiểm tra EShop source/configuration trước khi đề xuất 6–8 tối ưu; xác minh database, connection management, `GET /api/admin/orders`, order confirmation, pagination, indexes, caching và pooling; chỉ lưu khuyến nghị, không sửa source.

Đầu ra và đối chiếu: Sau khi xem implementation Express/SQLite, ChatGPT soạn bảy đề xuất trong [AI_Recommendations.md](../task2/AI_Recommendations.md), gắn từng đề xuất với mã nguồn, số liệu hoặc giới hạn JTL, lợi ích kỳ vọng, rủi ro và điều kiện áp dụng. Đây là giả thuyết cần benchmark, không phải cam kết cải thiện; không có backend source nào được sửa trong bước này.

**9. Viết AI Critique · ChatGPT · 22/11/2026**

Prompt (tóm lược): Viết reflection cá nhân bằng tiếng Việt, 200–300 từ, dựa trên các báo cáo hiện có; nêu điều AI sai/thiếu, nguyên nhân và bài học, không bịa lỗi.

Đầu ra: Tạo [AI_Critique.md](AI_Critique.md). Nội dung phân biệt omission, valid percentile-method difference và kết luận đúng nhưng bị giới hạn bởi JTL; nêu trách nhiệm của tester trong việc xác minh raw data, source code, assumptions và kết luận.

**10. Chốt báo cáo sau kiểm tra của sinh viên · ChatGPT · 22/11/2026**

Prompt: “tôi đối chíu đúng rồi á nên chắc chốt bản này lun nhen”

Đầu ra: ChatGPT xác nhận cấu trúc các tài liệu rà soát và khuyến nghị đã bao phủ nội dung được yêu cầu. Sinh viên cho biết đã tự đối chiếu trước khi chốt; lời xác nhận này không thay thế việc kiểm chứng độc lập.

**11. Rà soát liên kết giữa các tài liệu · ChatGPT · 22/11/2026**

Prompt (tóm lược): Chuyển các liên kết AI Critique sang đúng thư mục `ai/` và kiểm tra liên kết trong các tài liệu hiện có.

Đầu ra và kiểm tra: Sửa liên kết trong báo cáo Task 1, `Independent_Analysis.md`, `Misinterpretation_Hunt.md` và `report/report.md`; thay tham chiếu tới `task2/analysis.md` đã không còn tồn tại bằng các báo cáo hiện có. Ở lần rà soát đó, quét 58 file Markdown và kiểm tra 224 liên kết nội bộ, không tìm thấy đích thiếu. Không sửa raw JTL hoặc push thay đổi lên GitHub.

## Task 3 · Kiểm tra phạm vi đề xuất

**12. Xác nhận nội dung Task 3 · ChatGPT · 22/11/2026**

Prompt: “vậy là ong task 3”

Đầu ra: ChatGPT xác nhận nội dung đề xuất đã bao phủ việc theo dõi commit EShop, chọn kịch bản, phát hiện P95 tăng và thảo luận chi phí cùng báo động giả. ChatGPT đã soạn bản đề xuất và lưu đồ trong `23120184_HW05_Task3_Proposal.md`. Mốc 20,45 ms lấy từ lần chạy Load. Hai giá trị 27 ms và 26 ms dùng để minh họa quy tắc cảnh báo. Phần này dừng ở thiết kế mô hình.

**Các lượt hỗ trợ soạn tài liệu khác.** Ngày 22/11/2026, ChatGPT còn hỗ trợ biên soạn nội dung ba GitHub Issue và bổ sung script PowerShell tạo CSV vào báo cáo Task 1. Việc chuẩn bị nội dung issue và việc đăng issue lên GitHub là hai thao tác riêng. Nhật ký này ghi nhận bước soạn nội dung.
