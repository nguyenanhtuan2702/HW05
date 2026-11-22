---
name: eshop-jmeter
description: Run a local EShop performance-test workflow with JMeter and analyze raw CSV JTL results by endpoint. Use for an admin-order demo or for reviewing another endpoint group's JTL.
---

# Kiểm thử EShop và đọc log JMeter

1. Xác định chế độ từ yêu cầu. Với demo trực tiếp trên Windows, dùng backend EShop tại localhost:3000, plan Load của Task 1, Python 3 và JMeter 5.6.3. Với yêu cầu đọc kết quả cũ, dùng đường dẫn JTL được cung cấp.
2. Với demo trực tiếp, chạy scripts/run-demo.ps1 trong PowerShell tương tác. Nếu cửa sổ terminal của agent không hiển thị được hộp nhập mật khẩu, đưa đúng lệnh cho người dùng chạy trong terminal VS Code rồi đọc kết quả ở agent/runs/. Chỉ dùng tài khoản khách hàng để chuẩn bị đơn riêng. Plan thực hiện đăng nhập quản trị, đọc đúng mã đơn pending, gửi PUT, đọc lại và kiểm tra confirmed. Lượt demo dùng một người dùng và một vòng. Lưu JMX, CSV và kết quả vào thư mục mới cho mỗi lần chạy.
3. Với JTL bất kỳ, chạy Python 3 với scripts/analyze.py và đường dẫn JTL. Dùng --out để ghi Markdown. Nhóm theo label thực tế trong log. Đọc số mẫu, số lỗi, P95 và max từng bước. P95 dùng vị trí 0,95 × (n+1), đếm từ 1 và chặn ở hai đầu. Throughput tính theo số request trên khoảng từ lúc bắt đầu mẫu đầu tới khi hoàn tất mẫu cuối.
4. Với demo, kiểm tra đúng 4 bước thành công và ID trong URL PUT khớp ID của CSV. Nếu sai, báo bước lỗi và dẫn JTL/log. Với nhóm endpoint mới, dùng plan, dữ liệu và assertion của nhóm đó; tái sử dụng analyze.py cho log. Chỉ so P95 giữa các lượt cùng cấu hình tải, dữ liệu và cách tính.
5. Trả lời bằng tiếng Việt, chỉ rõ tệp nguồn và bằng chứng. Một mẫu cho mỗi bước chỉ minh họa luồng. Để diễn giải độ trễ dưới tải, dùng JTL Task 1 thực tế.
