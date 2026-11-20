# Đề xuất kiểm thử hiệu năng liên tục

Bổ sung vào kết luận báo cáo: commit nào kích hoạt đo, baseline nào phù hợp, cách so p95 theo endpoint, cách xác minh cảnh báo bằng lần chạy lại.

Sơ đồ khởi đầu để điều chỉnh:

~~~mermaid
flowchart TD
 A[Commit mới] --> B{Ảnh hưởng backend?}
 B -->|Có| C[Chạy workload cố định]
 B -->|Không| D[Bỏ qua lần đo]
 C --> E{p95 vượt ngưỡng?}
 E -->|Có| F[Chạy lại và đối chiếu]
 E -->|Không| G[Lưu kết quả]
~~~

Giải thích chi phí chạy, nguy cơ bỏ sót thay đổi và báo động giả do nhiễu phần cứng.
