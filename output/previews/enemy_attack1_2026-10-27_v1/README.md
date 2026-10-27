# Đòn tấn công 1 — đã duyệt và thay vào game

**Cập nhật:** riêng `attack1_3.png` đã được thay tiếp bằng [bản v2 bổ sung tay và chân phía sau](../enemy_attack1_3_2026-10-27_v2_four_limbs/README.md). Các ảnh trong thư mục preview v1 này giữ để đối chiếu lịch sử.

Người dùng đã duyệt bằng lệnh “thay vào đi”. Cả 3 PNG trong `frames/` đã được chép nguyên byte vào `asset/Enemies/sample/attack/`, giữ đúng tên và kích thước. Bản sao ảnh cũ và kết quả đối chiếu nằm ở `../../integration/enemy_attack1_2026-10-27_v1/`. Cảnh, animation và các file import giữ nguyên. Godot đang không kết nối lúc thay; dự án sẽ nạp lại ảnh khi mở.

Ba khung được tạo bằng ImageGen tích hợp, lấy tư thế và bố cục từ các ảnh attack1 cũ, dùng thiết kế quái mới làm tham chiếu: vỏ trắng sáng, da than đen, mắt đỏ, vết nứt và vết thương khô tiết chế, đuôi đỏ rượu và khói đen mỏng.

- [Ảnh đối chiếu cả ba khung](comparison.png): ảnh cũ bên trái, preview mới bên phải.
- [attack1_1.png](frames/attack1_1.png): khung 660 × 384.
- [attack1_2.png](frames/attack1_2.png): khung 568 × 492.
- [attack1_3.png](frames/attack1_3.png): khung 964 × 441.

`high_res/` chứa PNG tạo ở độ phân giải cao. `frames/` chứa bản chuyển toàn bộ canvas về kích thước file gốc để duyệt; không cắt tự động theo vật thể, không xoay hoặc dịch riêng bộ phận. Khung thứ hai dùng lượt cuối, giữ cả tay giơ sau đầu và chân phía xa có màu đen trong ảnh cũ. Khung thứ ba dùng lượt tạo cuối với một tay vươn dài và tay còn lại bị che như ảnh cũ, không dùng bản chùng người ban đầu.

[Prompt và nguồn ảnh tạo](generation_manifest.json) ghi prompt cuối cho từng khung. [Kết quả kiểm tra](preview_validation.json) xác nhận nền trong suốt, kích thước của ba PNG và hash các ảnh game/cảnh rig không đổi.

Ba ảnh đã được tích hợp sau khi duyệt. `preview_validation.json` ghi nhận kiểm tra tại thời điểm tạo preview, trước khi tích hợp; `installation_result.json` trong thư mục integration ghi kết quả cài đặt. Chưa kiểm tra thời điểm hoặc sự nối tiếp các khung trong animation chạy trong game ở lượt thay này.
