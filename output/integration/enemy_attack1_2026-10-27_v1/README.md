# Đã thay ba khung đòn tấn công 1

**Cập nhật:** riêng `attack1_3.png` hiện dùng [bản v2 đủ tay và chân phía sau](../enemy_attack1_3_2026-10-27_v2_four_limbs/README.md). Bản ghi bên dưới phản ánh lần tích hợp v1 trước đó.

Nguồn: `../../previews/enemy_attack1_2026-10-27_v1/frames/`, đúng bộ người dùng vừa duyệt. Đã chép nguyên 3 PNG vào `asset/Enemies/sample/attack/`, không xử lý lại nội dung:

- `attack1_1.png`: 660 × 384.
- `attack1_2.png`: 568 × 492.
- `attack1_3.png`: 964 × 441.

`originals/` lưu 3 ảnh cũ cùng file import. `installation_result.json` ghi hash các ảnh đã cài và xác nhận trùng nguyên byte với PNG preview. `untouched_before.json` dùng để xác nhận các ảnh đòn đánh còn lại, các file import, bộ phận trong images và cảnh rig giữ nguyên.

Không đổi xương, offset, khóa hoặc thời điểm animation. Editor Godot không kết nối khi thay; dự án sẽ import lại các ảnh thay đổi khi mở. Lượt này kiểm tra file, kích thước và tham chiếu cảnh; chưa chạy lại animation trong game.
