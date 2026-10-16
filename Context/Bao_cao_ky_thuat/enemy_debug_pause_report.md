# Debug enemy từ pause menu

Ngày: 16/10/2026. Áp dụng cho hệ thống enemy hiện hành `EnemyBase`, Wobtear và SpineEnemy. Giữ nguyên các prototype/legacy; không sửa AI hoặc damage của các script prototype cũ.

## Sử dụng

Nhấn **Esc → Debug - Enemies**:

- **Disable enemy AI**: dừng patrol, phát hiện, đuổi và tấn công. Quái vẫn chịu trọng lực, còn hurtbox/điểm lock-on và vẫn bị đánh/stun. Với SpineEnemy, hủy swing hiện tại, đóng cả hitbox chém và nhảy vồ, đưa về pose walk đứng yên. Bỏ chọn sẽ quay về luồng WALK → DETECT → RUN bình thường khi player ở gần, không tiếp tục đòn bị dừng.
- **Invincible enemies**: hit hợp lệ vẫn trả về thành công để hit-stop/feedback/stun Q tiếp tục hoạt động; HP không giảm, không chết và không phát EXP. Bỏ chọn áp dụng damage bình thường ngay, không cần tải lại map. Không tự hồi đầy HP cũ khi bật, không hồi sinh quái đã chết.

Hai cờ độc lập, mặc định tắt ở lần chạy game mới, dùng chung cho enemy hiện có và enemy spawn mới. Giữ trong phiên khi tạo lại pause hoặc tải lại khu vực, không ghi vào save/checkpoint hoặc cấu hình người chơi. Cả giao diện và tác dụng đều được giới hạn bằng `OS.is_debug_build()`; bản release không hiện nhóm debug và không áp cờ. Không tuyên bố đã export/chạy bản release trong lượt này.

Chỉ AI bị dừng: không đặt toàn enemy thành PROCESS_MODE_DISABLED hoặc xóa physics. Do đó quái trên không vẫn rơi, xác đã chết vẫn phát death/fading và rơi xuống nền như trước. Nếu đang chịu Q stun, cơ chế stun vẫn quản lý physics riêng; khi hết stun, AI tiếp tục tuân theo cờ hiện tại.

## Code

- `res://scenes/enemy/enemy_debug_settings.gd`: module static dùng chung, preload trực tiếp; không cần thêm autoload hoặc sửa `project.godot`.
- `res://scenes/UI/game_pause_menu.tscn` và `pause.gd`: hai CheckButton trong `VBoxContainer/EnemyDebug`, đọc lại cờ mỗi lần mở pause. Nới khung menu để chứa mục mới; giữ đường dẫn camera settings/nút cũ.
- `enemy_base.gd`: AI idle chỉ giữ gravity/hurtbox; nhận hit bất tử vẫn hợp lệ, chặn mất HP và chết/EXP.
- `spine_enemy.gd`: đóng cửa sổ damage và chặn callback hit khi tắt AI, kể cả trước tick AI đầu tiên sau resume; re-enable từ trạng thái trung lập. Death chạy trước nhánh debug để không làm đứng xác.
- `playable_adel.gd`: đường damage do va chạm thân cũng bỏ qua EnemyBase khi AI tắt. Không thay damage của nguồn khác.

## Kiểm chứng

Scene `res://tests/enemy/enemy_debug_validation.tscn` dùng save riêng `CodexEnemyDebug20261016`, kiểm tra control pause, cờ độc lập, không sửa SaveManager, enemy đứng yên/không damage, hurtbox/lock-on, hit Q thật trên quái bất tử, không EXP, spawn mới, Wobtear, re-enable AI, pause instance mới và xác chết.

Đã chạy Godot 4.7 có render và xem ảnh pause; kết quả cuối cùng/log nằm trong `outputs/enemy-debug-20261016`. Các suite enemy detection/death/corpse fall, campfire và camera/pause được chạy để đối chiếu hành vi mặc định. Asset, rig, thông số gameplay trong scene Player/enemy, save thật và legacy được giữ nguyên.
