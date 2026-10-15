# SpineEnemy death animation — 2026-10-15

Enemy HP về 0 sẽ đánh dấu chết và thưởng EXP một lần như trước, rồi phát ngay animation **death** từ `res://scenes/enemy/enemy_spine.tscn`. Clip gốc dài **10 giây**, giữ nguyên các key pose và fade: opacity 1 tới giây 4, giảm về 0 ở giây 10. Không thêm fade/tween riêng, không sửa asset hay rig.

Trong lúc chết:

- State là `DEAD`, không chạy AI hoặc di chuyển; đóng ngay logic cửa sổ gây damage, xóa target.
- Tắt body hurtbox, hitbox melee, hitbox leap cùng mọi collider con. Collision layer/mask về 0; Area2D ngừng monitoring/monitorable. Các cập nhật PhysicsServer dùng deferred để an toàn khi chết từ callback va chạm; `is_dead` chặn nhận/gây damage tức thì.
- Loại khỏi group khóa mục tiêu và group tiếp xúc Enemy; camera mất khóa, Q không dừng lại vì corpse hoặc thêm stun mới lên corpse.
- Nếu đang bị Q stun, hủy node stun, không để cleanup của stun bật lại AI/area hay ngắt death.
- Khi `AnimationPlayer.animation_finished("death")` phát, enemy `queue_free()` khỏi map. Không dùng timer 10 giây thực độc lập để tránh xóa trước khi fade hoàn tất trong slow motion/pause.

10 giây là **thời gian clip/game**: pause dừng playback, slow motion làm clip chậm theo game. Không tự respawn sau một khoảng chờ. **Restart Area/reset/reload scene** tạo lại enemy từ scene với HP đầy, opacity 1 và collider hoạt động bình thường; không lưu trạng thái chết vĩnh viễn vào save. Reset cả khi corpse đang phát death cũng được hỗ trợ.

## File chỉnh sửa

- `scenes/enemy/enemy_base.gd`: tách bước `_finish_death()` khỏi phần HP/EXP chung. Mặc định vẫn xóa ngay, nên Wobtear/prototype dùng lớp nền không bị đổi death behavior.
- `scenes/enemy/spine_enemy.gd`: state DEAD, cleanup collider/stun/target, phát death ở speed 1 và xóa khi clip kết thúc; callback combat cũ không được mở lại đòn.
- `scenes/adel/components/enemy_skill_stun.gd`: không hồi AI/animation/Area cho body đã chết; enemy còn sống vẫn hồi phục sau stun như trước.
- `scenes/adel/components/saber_weapon_skill.gd`: bỏ qua body đã chết/HP 0 trong chọn mục tiêu và gắn stun.
- Hai suite detect/leap được cập nhật vì trước đây giả định enemy bị free ngay; nay xác nhận death trước rồi kết thúc clip để kiểm tra cleanup.

Không thay đổi Player scene/tuning, damage, EXP reward, animation offsets, thứ tự hiển thị, camera, stamina, audio hoặc prototype cũ. Nếu rig bị thiếu death trong tương lai, cảnh báo và xóa ngay để không để corpse tồn tại vô hạn.

## Kiểm chứng

Godot 4.7 stable Windows, bản sao project có custom user directory riêng. Bộ mới để clip chính chạy tự nhiên đủ **10 giây animation trên engine**, có kiểm tra pause/slow motion. Không chạy vào save thật.

Bộ mới kiểm tra lethal Saber/Q, death giữa melee/leap, không thêm stun vào đòn kết liễu, stun cũ không hồi enemy chết, stun không kết liễu vẫn phục hồi enemy sống, tắt toàn bộ collider, cached contact, stale callback, EXP một lần, mất lock-on, fade gốc, kết thúc tự nhiên, legacy removal và reset scene cả sau khi xóa lẫn đang fade.

Kết quả cuối và log hồi quy được lưu trong gói xác minh. Cảnh báo Bone2D từ rig có sẵn và cảnh báo thiếu detect do fixture kiểm thử vẫn có thể xuất hiện; không thêm audio hay tự sửa rig vì những cảnh báo này.

Kết quả cuối: **297 kiểm tra, 0 thất bại** — death 40 headless + 40 có render; detect 34; leap hitbox 81; jump/Wobtear 42; entry/save 60. Không có SCRIPT ERROR/ERROR trong các log xác nhận cuối.
