# Hệ thống Enemy

Cập nhật: 16/10/2026. Gộp báo cáo Enemy, death và debug pause; phản ánh code/scene hiện tại. Vị trí và giá trị thiết kế được tra trong [hướng dẫn tùy chỉnh](huong_dan_tuy_chinh.md). Phòng thủ Player được ghi riêng ở [báo cáo Defense](defense_guard_deflect_stagger_stamina_report.md).

## 1. EnemyBase và Wobtear

`res://scenes/enemy/enemy_base.gd` cung cấp hợp đồng HP, `take_damage()`, `die()`, EXP, tuần tra và API điểm khóa camera. `wobtear_enemy.tscn` là scene M1 tối thiểu dùng EnemyBase, AnimatedSprite2D và collider. Hai PNG Wobtear idle/walking gốc đã khôi phục từ Git; scene atlas chọn frame theo từng ảnh. Không thay sprite sheet bằng ảnh AI.

Wobtear chỉ là nền tối thiểu: đi/đứng theo thời gian và phạm vi tuần tra, đổi hướng và animation. Không có bộ AI chiến đấu giống SpineEnemy. Các giá trị chưa được chốt bằng thiết kế nằm ở export để chỉnh, không xem mặc định là cân bằng cuối.

`enemy.gd`, `s_1e_1.gd` cùng các scene/prototype cũ vẫn được giữ. Chúng không tự động nhận toàn bộ hợp đồng/debug/lock của EnemyBase. Luôn phân biệt enemy hiện hành và legacy khi sửa map hoặc debug.

## 2. SpineEnemy và rig

Scene gameplay là `res://scenes/enemy/spine_enemy.tscn`, script `spine_enemy.gd` kế thừa EnemyBase. Rig chứa animation là `res://scenes/enemy/enemy_spine.tscn`, instance tại `VisualPivot/EnemyRig`. Scene kiểm tra hiện có `spine_enemy_test.tscn` và các fixture dưới `res://tests/enemy/`.

Các node chính: collider gốc, VisualPivot/EnemyRig, WeaponPivot/Hitbox và LeapHitbox. FSM gameplay độc lập AnimationPlayer nhưng phát clip theo từng pha. Hình nguồn quay trái; VisualPivot và WeaponPivot được mirror cùng nhau theo hướng để hình/VFX/vùng đánh nằm đúng phía.

Run bay/không chạm đất là dụng ý tác giả. Không tự hạ rig để 'sửa' pose chạy. `animation_offsets` là công cụ căn theo clip; giá trị hiện lưu của scene được giữ nguyên. Chỉnh rig hay ordering nội bộ chỉ ảnh hưởng trình bày, không dùng để định nghĩa damage.

## 3. FSM và hành vi

Luồng chính: **WALK → DETECT → RUN → WINDUP → LEAP → LAND → RECOVERY**, sau đó **MELEE → RECOVERY** tùy điều kiện.

- Walk tuần tra. Khi Player vào `detection_distance`, phát clip `detect player` rồi mới Run. Phát hiện không bỏ qua clip chuyển tiếp.
- `disengage_distance` và `chase_memory` hạn chế đổi trạng thái liên tục khi Player chạm biên tầm. Có tùy chọn reset đòn mở đầu sau mất mục tiêu.
- Đòn mở đầu dùng `attack1_1` lấy đà, `attack1_2` vồ trên không và `attack1_3` sau tiếp đất. Điểm rơi/tốc độ được giới hạn theo thông số leap, không phải teleport tới Player.
- Đòn kế tiếp chủ yếu `attack2`, xen `attack3` theo xác suất. Melee cần trong khoảng ngang và chênh cao cho phép; mỗi clip có cửa sổ gây damage riêng, xong clip chuyển recovery.
- Stun do Q lưu/dọn đúng chuyển động và các damage window. Enemy chết hoặc tắt AI không được callback stun cũ khôi phục hành vi/collision.

## 4. Collider, hurtbox và hitbox

`SpineEnemy/CollisionShape2D` là collider thân vật lý đồng thời là shape nhận hit từ các query/body hit hiện tại; chưa phải một hurtbox Area2D riêng. Khóa camera dùng tâm shape này có xét transform. Nó không phải vùng gây sát thương melee.

- **Melee:** `WeaponPivot/Hitbox/CollisionShape2D`, hình chữ nhật nằm trước enemy, vùng VFX. Transform đã căn cho hướng trái nguồn; WeaponPivot mirror khi quay phải. `attack2_window`/`attack3_window` bật/tắt vùng này theo thời gian clip.
- **Leap:** `LeapHitbox/CollisionShape2D`, shape theo thân và gần collider nhận hit, dành riêng cho vồ. Không dùng chung vùng VFX melee.
- **Damage:** Area2D tìm Player theo mask; gọi `take_damage(damage, global_position)` để Player có đủ nguồn hướng cho Guard/Deflect. Mỗi swing có tập target đã trúng để tránh hit lặp theo frame.
- Query shape bổ sung ở biên chuyển từ windup sang leap và khi đáp đất, tránh mất hit vì monitoring cập nhật chậm một physics tick. Không dùng một vùng query lớn phủ cả đoạn để đánh xuyên tường tùy ý.

Player và enemy có thể đi/dash xuyên thân nhau theo mask hiện hành; va chạm địa hình vẫn có. Vùng gây/nhận damage hoạt động riêng với cản thân. Ordering không quyết định collision.

**Thứ tự vẽ hiện tại:** Player root `z_index=200`, SpineEnemy root `z_index=100`, nên enemy ở sau Player. Các mô tả Player ở sau quái trong báo cáo cũ đã bị thay thế; không chỉnh rời rạc Z Index từng xương để đảo toàn actor.

## 5. Nhận damage, chết và hồi sinh

EnemyBase chặn damage không hợp lệ hoặc sau chết; damage được xác nhận để Player dùng hit-stop/stun/feedback. HP về 0 gọi die đúng một lần và trao EXP đúng một lần. EXP có thể được tiêu ngay để lên level, nên số EXP hiển thị không nhất thiết tăng nguyên phần thưởng sau kill.

SpineEnemy vào DEAD ngay, đóng damage, bỏ target/nhóm khóa, tắt AI cùng hitbox/hurtbox combat. Phát `death` gốc đã có fading, hiện dài 10 giây; chỉ `queue_free()` khi clip hoàn tất. Không thêm fade thứ hai hoặc timer thời gian thực thay thế clip. Thiếu clip thì cảnh báo và xóa ngay.

Nếu chết trên không, vẫn chạy death đồng thời rơi bằng gravity multipliers và giới hạn tốc độ rơi của `LocomotionComponent` Player. Không teleport xuống đất, không giữ tốc độ lao ngang và không hất xác lên. Tạo collider bản sao `CorpseTerrainCollider` chỉ dò địa hình theo `corpse_terrain_mask`; collision layer bằng 0, bỏ tương tác CharacterBody khác. Shape này để xác đáp đất, không bật lại hurtbox/hitbox combat.

Pause/slow motion ảnh hưởng tiến trình death theo thời gian game. Reset/reload map tạo enemy mới từ scene; chưa lưu trạng thái enemy đã chết vào save lâu dài. Camera lock mất ngay khi chết, không đợi xóa node. Stun Q cũ không thể hồi sinh hoặc bật collision của xác.

## 6. Debug từ pause

Esc → **Debug - Enemies** có **Disable enemy AI** và **Invincible enemies**. Chỉ hoạt động trong debug build, giữ cho phiên chạy và không ghi save. Mở menu pause mới hoặc tạo enemy mới dùng cùng trạng thái debug hiện tại.

AI off: enemy hiện hành dừng quyết định/đòn, đóng damage window, giữ trọng lực và khả năng nhận hit. Bật lại SpineEnemy về luồng Walk/Detect/Run phù hợp, không tiếp tục đòn cũ. Damage tiếp xúc theo luồng EnemyBase bị chặn khi AI off.

Bất tử: nhận hit hợp lệ để vẫn có feedback/stun nhưng không trừ HP, không chết và không cấp EXP. Không hồi sinh enemy đã chết; xác tiếp tục death/rơi. Hai tùy chọn độc lập. Legacy chưa kế thừa EnemyBase không tự được hỗ trợ.

## 7. Kiểm thử và giới hạn

Các suite hiện có: leap hitbox, enemy detect, enemy death, corpse fall và enemy debug trong `res://tests/enemy/`; tích hợp Guard/Deflect/stamina/Q tại `res://tests/adel/`; lock camera tại `res://tests/camera/`. Các lần sửa trước có chạy Godot thật và có fixture đối chiếu biên hitbox/death/debug. Bản tổng hợp tài liệu này không chạy lại runtime.

Chưa nghiệm thu AI tránh vực/tìm đường nhiều tầng, né vật cản phức tạp, occlusion/line-of-sight, nhiều chủng quái dùng chung data, boss, balance hoặc stress test số lượng lớn. Không nâng phạm vi M1 thành hệ thống này chỉ vì đã có export. Prototype legacy và asset tác giả được giữ nguyên.

## Xác minh ordering trong scene test — 16/10/2026

Đã bỏ override `z_index = 0` trên instance PlayableAdel tại `res://scenes/enemy/spine_enemy_test.tscn`; scene test nay kế thừa Player Z = 200, Enemy Z = 100. Không chỉnh ordering bộ phận rig, animation, hitbox hoặc damage.

Đã chạy Godot có render trên bản sao project với save riêng và đặt hai actor chồng nhau. Kiểm tra toàn bộ phần hình của rig: Z hiệu dụng Player **194–250**, Enemy **94–100**, mọi phần Player đều cao hơn. Ảnh viewport xác nhận Player che enemy. Lượt này chỉ xác minh ordering, không chạy lại kiểm tra chiến đấu hay playthrough.
