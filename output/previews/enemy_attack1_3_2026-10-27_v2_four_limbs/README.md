# attack1_3 — bản đủ tay chân đã duyệt và tích hợp

[PNG nền trong suốt, khung 964 × 441](frames/attack1_3.png). [Ảnh độ phân giải cao](high_res/attack1_3.png).

Đã dùng ImageGen tích hợp để bổ sung tay/bàn tay phía xa phía trên tay chính và chân/bàn chân phía xa bên trái chân chính, dựa theo ảnh cũ trên nền xám. Các chi phía xa dùng da tối và giáp trắng xám để tách lớp. Giữ tư thế lao tới, đầu, thân, tay chân chính, đuôi và màu sắc hiện có.

[Prompt cuối](generation_prompt.txt) và [nguồn ảnh tạo](generation_source.json). Bản PNG trong frames chỉ chuyển độ phân giải toàn canvas về khung gốc; không xoay, dịch hoặc cắt riêng bộ phận.

**Đã được người dùng duyệt và thay vào game bằng lệnh “thay vào đi”.** Đã chép nguyên PNG trong `frames/` vào `asset/Enemies/sample/attack/attack1_3.png`, giữ khung 964 × 441 và file import, cảnh/animation. `preview_validation.json` ghi kiểm tra lịch sử trước khi tích hợp. Bản sao ảnh trước khi thay và kết quả đối chiếu ở `../../integration/enemy_attack1_3_2026-10-27_v2_four_limbs/`. Godot không kết nối khi thay; ảnh sẽ được nạp lại khi mở dự án.
