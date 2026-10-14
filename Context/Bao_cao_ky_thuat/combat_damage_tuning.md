# Jump attack, combo damage và vị trí chỉnh HP / kỹ năng enemy

## Thay đổi đã thực hiện

- Saber thường đọc `WeaponData.damage`, thay cho damage 20 cố định trong callback hitbox.
- Saber được lưu damage cơ bản **20**. Combo 1/2/3 dùng damage cơ bản; combo 4 nhân **Combo Finisher Multiplier = 1.2**, mặc định **24**. Damage được làm tròn sang số nguyên và chốt khi bắt đầu swing.
- Jump attack có hitbox riêng và damage **20**. Pha treo `jump_attack(air)` không gây damage; vùng damage mở từ pha rơi JUMP_FALL và kéo dài qua phần đầu `jump_attack(land)`.
- Một enemy chỉ nhận một lần damage trong cả chuỗi rơi–đáp. Enemy khác có thể mỗi con nhận một hit. Enemy đi vào vùng trong cửa sổ đáp vẫn có thể bị đánh nếu chưa trúng trong lần đó.
- Đóng hitbox khi hết cửa sổ, hủy đòn, chuyển sang combo, bị stagger hoặc thoát ATTACK. Callback đóng cửa sổ của swing Saber cũ có token để không hủy swing mới được bắt đầu ngay sau đó.
- Dùng overlap body thật và shape query bổ sung lúc mở vùng / frame đáp cuối. Không bổ sung swept collision cho mọi quãng chuyển động ở mọi tốc độ.
- Không thêm tiêu hao stamina cho attack/jump attack, không thêm audio hoặc mở rộng Fracture. Damage mới vẫn là lượng damage gửi vào receiver; các hệ số damage gây của Fracture chưa tự được áp thêm trong đường này.

Animation gốc, thời gian treo/rơi/khôi phục landing, các thông số Guard/Stagger/Stamina đã căn, collider enemy, hitbox enemy và prototype cũ được giữ nguyên. Các file tài liệu cũ đang bị người dùng xóa không được khôi phục.

## 1. Sát thương jump attack

Mở `res://scenes/adel/playable_adel.tscn`, chọn root **PlayableAdel** → Inspector → **Jump Attack**:

- **Jump Attack Damage = 20:** damage của cả lần jump attack cho mỗi enemy. Đổi 35 thì một target nhận 35 một lần, không phải 35 ở mỗi frame hoặc 35 riêng cho cả fall và land.
- **Jump Attack Landing Active Time = 0.15:** thời gian còn gây damage đầu pha đáp, tính bằng giây game. Đặt 0 để chỉ phần rơi/frame chạm sàn cuối có damage. Cửa sổ này bị giới hạn bởi thời điểm mở khóa landing hiện tại **0.3 giây**, và đóng khi thoát ATTACK.

Hitbox: **PlayableAdel → WeaponPivot → JumpAttackHitbox → CollisionShape2D**.

- Transform của Area2D `JumpAttackHitbox`: Position **(65,20)**, vùng hướng trước/bên dưới Player.
- Shape rectangle: Size **(150,100)**.
- WeaponPivot tự mirror theo hướng nhìn; kiểm tra cả trái/phải khi căn shape.
- Shape được script bật/tắt; không để enabled cố định để chữa một lỗi timing.

Position/size và 0.15 giây là giá trị đề xuất có thể chỉnh; không phải cân bằng gameplay đã chốt. `fall` hiện là state JUMP_FALL, vẫn dùng clip `jump_attack(air)`, không có animation `jump_attack(fall)` mới.

## 2. Sát thương combo thường và đòn thứ 4

Trong `playable_adel.tscn`, chọn **WeaponHolder → Saber** → Inspector → **Combat**:

- **Damage = 20:** damage của combo 1, 2, 3.
- **Combo Finisher Multiplier = 1.2:** damage combo 4 = `round(Damage × multiplier)`.
- Ví dụ Damage 30, multiplier 1.2: ba đòn đầu 30, đòn thứ 4 36.
- Có thể đặt multiplier riêng, ví dụ 1.5; thay damage cơ bản không đòi hỏi sửa callback hitbox.

Muốn đổi mặc định của mọi Saber instance, mở `res://scenes/adel/weapon/saber.tscn`, chọn root **Saber**, chỉnh cùng các field. Override trên WeaponHolder/Saber của Player hoặc trên instance Player trong map có thể ghi đè mặc định của scene Saber. Script WeaponData chung vẫn có default Damage=1 cho resource khác; scene Saber đã lưu Damage=20.

Cửa sổ active của combo hiện vẫn nằm trong **WeaponPivot → SaberHitbox → AnimationPlayer**, track `Hitbox/CollisionShape2D:disabled` cho `saber_attack_1` đến `saber_attack_4`. Cửa sổ không được chuyển sang các mảng timing legacy của WeaponData trong lượt này.

## 3. HP Player

Nguồn max HP cơ bản là `res://scenes/Mechanic/player_progress.gd`:

- **BASE_MAX_HP = 100:** HP cơ bản của Player.
- **HP_PER_UPGRADE = 20:** HP cộng thêm mỗi lần nâng HP.
- Công thức: `max HP = BASE_MAX_HP + hp_upgrades × HP_PER_UPGRADE`.

Sửa các constant này trong script rồi save/restart để đổi mức HP cơ bản/nâng cấp. Không chỉ đổi `StatsComponent.max_hp = 100` hoặc giá trị HUD rồi coi đó là nguồn chính: PlayerProgress áp progression vào HUD, và load/respawn còn phục hồi dữ liệu lưu. HP hiện có trong save và số lần nâng cấp có thể khiến kết quả khác HP cơ bản; dùng slot mới hoặc hồi đầy tại checkpoint khi cần kiểm tra từ trạng thái sạch, không xóa save thật.

Trong trạng thái đang chạy, HP hiện tại khác Max HP. Các mốc stagger 66%/33% được tính theo Max HP và làm tròn; đổi HP cơ bản cũng đổi vị trí số học của threshold.

## 4. HP enemy

**SpineEnemy:** mở `res://scenes/enemy/spine_enemy.tscn`, chọn root **SpineEnemy** → **Health → Max Health**, hiện **100**.

**Wobtear M1:** mở `res://scenes/enemy/wobtear_enemy.tscn`, chọn root **WobtearEnemy** → **Health → Max Health**, hiện dùng default **20** từ EnemyBase.

Muốn chỉnh riêng một con trong map/test, chọn **instance Enemy** trong scene chứa nó và chỉnh Max Health tại đó. Instance override chỉ thay con đó; chỉnh wrapper scene thay mặc định cho các instance không override. `current_health` được gán từ Max Health khi enemy `_ready()`, nên chỉnh Max Health rồi chạy lại để kiểm tra đúng.

EnemyPrototype / EnemyPrototypeTesting cũ có export `max_health` riêng trên root scene legacy; chúng chưa được thay bằng EnemyBase. Không giả định thay EnemyBase sẽ chỉnh mọi prototype cũ.

## 5. Damage từng kỹ năng SpineEnemy

Mở `res://scenes/enemy/spine_enemy.tscn`, chọn root **SpineEnemy**:

- **Opening Leap → Leap Damage = 20:** damage nhảy vồ `attack1_2` / LEAP. `attack1_1` lấy đà và `attack1_3` đáp không mở vùng damage trong AI hiện tại.
- **Follow-up Attacks → Attack2 Damage = 12:** damage đòn attack2.
- **Follow-up Attacks → Attack3 Damage = 18:** damage đòn attack3.
- **Attack2 Window = (0.3,0.45)** và **Attack3 Window = (0.4,0.65):** thời điểm damage active theo giây game, tách biệt với lượng damage.
- **Attack3 Chance = 0.2:** xác suất chọn attack3 ở mỗi lần chọn melee; không chỉnh damage.

Hitbox vồ ở **LeapHitbox/CollisionShape2D**; hitbox attack2/3 ở **WeaponPivot/Hitbox/CollisionShape2D**. Đổi kích thước vùng không tự đổi damage. Giá trị damage gửi đến Player còn được Guard, i-frame, threshold và modifier nhận damage xử lý; ví dụ raw leap 20 được Guard cơ bản có thể mất 10 HP.

Enemy thử nghiệm legacy dùng `res://scenes/testing/Enemies/enemy_weapon.gd` → `_on_hitbox_body_entered()` → `body.take_damage(20, global_position)`, hiện cùng raw 20 cho normal/special. Các export damage của SpineEnemy không điều khiển vũ khí legacy này. Wobtear M1 chưa có kỹ năng chủ động gây damage.

## 6. Source và kiểm thử

- `scenes/adel/components/jump_attack_hitbox.gd`: vòng đời cửa sổ jump, registry chung fall/land, lọc body và truy vấn biên.
- `scenes/adel/components/combat_component.gd` → `get_combo_damage()`: công thức damage thường/finisher.
- `scenes/adel/components/saber_hitbox.gd`: cache lượng damage riêng của swing và bảo vệ deferred shutdown bằng generation.
- `scenes/adel/playable_adel.gd`: export jump damage/window, tích hợp với HFSM và movement.
- `tests/adel/jump_attack_damage_validation.tscn`: kiểm tra damage combo thực, jump qua input/physics, hai hướng, nhiều target, reentry fall–land, landing-only contact, last-flight contact, cấu hình damage 35/0, interruption, chết/EXP.

Chạy kiểm thử trên bản sao project với custom user directory riêng để không sử dụng progression/save thật. Bằng chứng và kết quả cuối nằm trong `Jump-attack-damage-verification.zip` của workspace. Cảnh báo rig/addon/UID đã tồn tại không được sửa trong thay đổi này; không tuyên bố toàn dự án sạch lỗi chỉ từ các suite combat đã qua.

### Kết quả kiểm chứng cuối

Godot 4.7 đã thực sự chạy trên bản sao working tree với user data riêng:
42 kiểm tra riêng cho damage mới và 294 kiểm tra hồi quy = **336 checks headless,
0 failures**. Suite damage mới còn chạy có render: **42 checks, 0 failures**.
Không có SCRIPT ERROR mới trong các log nghiệm thu cuối. Suite Defense legacy
vẫn có hai lỗi thiếu animation walk / node WeaponPivot giống hệt log trước;
không sửa chúng trong scope damage mới. Cảnh báo Bone2D đang có vẫn được ghi nhận.
Ảnh jump_attack_damage_verified.png chỉ có viền hitbox
phục vụ verification, không thêm viền đó vào scene gameplay.

Max HP khi load save còn đi qua `SaveManager._apply_hp_to_hud()` và lấy
`max(max_hp đã lưu, PlayerProgress.get_max_hp())`; vì vậy hạ BASE_MAX_HP có thể
không hạ Max HP của một save cũ cao hơn. Không sửa chính sách load/save hoặc tự
thay HP đang lưu trong lượt này.

Lượt này chưa commit hoặc push. Các file đã bị xóa hoặc chỉnh bởi người dùng
trước khi bắt đầu được giữ nguyên trạng thái; không khôi phục các báo cáo cũ.
