# SpineEnemy death animation — 2026-10-15

Enemy HP về 0 sẽ đánh dấu chết và thưởng EXP một lần như trước, rồi phát ngay animation **death** từ `res://scenes/enemy/enemy_spine.tscn`. Clip gốc dài **10 giây**, giữ nguyên các key pose và fade: opacity 1 tới giây 4, giảm về 0 ở giây 10. Không thêm fade/tween riêng, không sửa asset hay rig.

Trong lúc chết:

- State là `DEAD`, không chạy AI hoặc lao ngang; đóng ngay logic cửa sổ gây damage, xóa target. Từ cập nhật 16/10/2026, corpse vẫn rơi xuống địa hình bằng physics của Player trong khi death tiếp tục phát.
- Tắt body hurtbox gốc, hitbox melee, hitbox leap và collider combat. Combat collision layer vẫn bằng 0, Area2D ngừng monitoring/monitorable. Thêm collider riêng `CorpseTerrainCollider` chỉ va chạm địa hình (mask mặc định 1); mọi CharacterBody hiện có được thêm collision exception để corpse không đứng trên người chơi/quái. Các cập nhật dùng deferred để an toàn khi chết từ callback va chạm; `is_dead` chặn nhận/gây damage tức thì.
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


## Cập nhật 16/10/2026 — death trên không vẫn rơi xuống đất

Đã tái hiện bằng đòn nhảy vồ thật: trước sửa animation death tiến lên nhưng vị trí Y không thay đổi; suite mới có 7 thất bại trên 19 check. Nguyên nhân là EnemyBase.die tắt physics và SpineEnemy giữ mọi collider bị tắt suốt clip.

SpineEnemy nay bật một nhánh physics chỉ dành cho DEAD sau khi dựng collider địa hình bằng deferred. EnemyBase/Wobtear/prototype giữ cách chết/xóa cũ. Collider gốc dùng làm hurtbox vẫn disabled, các hitbox offensive vẫn disabled; collider địa hình mới có collision layer 0 nên không trở thành mục tiêu combat.

Nhánh DEAD dùng trực tiếp `LocomotionComponent.apply_vertical_physics`: cùng gravity, FALL_GRAVITY_MULT (hiện 2) và MAX_FALL_SPEED (hiện 920 px/s) của Player. Không teleport/snap enemy xuống đất, không giữ đà lao ngang/lên của leap. Khi chạm đất, move_and_slide giữ xác nằm trên mặt đất; không đổi animation sang land hoặc phát lại death. Xác tiếp tục dùng clip/fade gốc và biến mất khi clip 10 giây game kết thúc, kể cả chưa chạm đất. Pause/slow motion ảnh hưởng cả rơi và animation.

Nếu map dùng layer địa hình khác, chỉnh `spine_enemy.tscn → SpineEnemy → Death Terrain → Corpse Terrain Mask`, mặc định world layer 1. Không thêm bộ thông số rơi khác Player: để đổi tốc độ rơi chung, xem FALL_GRAVITY_MULT/MAX_FALL_SPEED trong `res://scenes/adel/components/locomotion_component.gd`. Lượt này không sửa những giá trị đó hoặc animation offsets.

Kiểm tra mới `res://tests/enemy/corpse_fall_validation.tscn`: leap lên không rồi nhận đòn chết; Y tăng trong khi clip death phát; so sánh với reference dùng module rơi Player; đáp đất/không lún, terminal speed, pause/slow motion, chết khi đang đứng đất, đi xuyên CharacterBody và xóa khi clip hết. Regression death cũ được cập nhật từ giả định “corpse đứng im” sang “corpse không có AI/combat nhưng vẫn có gravity”.

Kết quả lượt cập nhật: **233 check đạt, 0 thất bại** — corpse fall 19 headless + 19 có render; death/fade/reset 40 headless + 40 có render; leap hitbox 81; detect transition 34. Đã chạy Godot 4.7 thực tế, không có SCRIPT ERROR/ERROR trong log cuối. Các cảnh báo Bone2D/UID có sẵn vẫn còn. Kết quả 297 check ở phần trước thuộc lượt death-animation ban đầu.

Giữ nguyên scene/rig/asset/audio, Player tuning, damage/EXP, camera và legacy; không ghi save thật, không commit/push. Manifest mới: `Enemy-corpse-fall-verification.json` trong workspace.
