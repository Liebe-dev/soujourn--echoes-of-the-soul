# attack3 — đã duyệt và thay vào game

Đã chép nguyên PNG được duyệt từ `../../previews/enemy_attack3_2026-10-27_v1/attack3.png` vào `asset/Enemies/sample/attack/attack3.png`. Giữ canvas 2703 × 931 và ba ô 901 × 931 theo X (`hframes=3`, `vframes=1`), không căn hoặc xử lý lại hình lúc cài.

`originals/attack3.png` và `.import` lưu bản trước khi thay. `installation_result.json` xác nhận hash ảnh đã cài trùng bản duyệt. Các ảnh đòn đánh khác, file import và cảnh/animation giữ nguyên, đã đối chiếu hash theo `unchanged_before.json`.

`editor_refresh.json` ghi trạng thái editor khi hoàn tất. Nếu editor không kết nối, ảnh mới sẽ được import lại khi mở dự án. Lượt thay này xác nhận file, kích thước và tham chiếu giữ nguyên; không chạy lại animation trong game.
