# Saber skill Q — vận hành và tuning

Ngày: 15/10/2026. Skill dùng sáu animation người dùng đã cung cấp. Không sửa clip, texture, rig, ordering hay prototype cũ. Các lựa chọn đã trả lời: slow motion 0,50x; mức charge 1 giây có thêm 0,10 giây skill_2 kể từ lúc thả Q.

## Luồng ba mức

- **Tap / thả trước 1 giây:** skill_1 giữ ít nhất 0,20 giây tính từ lúc nhấn; thả ở 0,40 giây thì đã đủ lấy đà và lao ngay. Skill_4 trong lúc lao, tối đa 180px ở 900px/s. Gây 20 damage, hit-stop 0,065 giây, không stun. Skill_5 giữ pose impact 0,05 giây game, sau đó skill_6 phát ở 2x để hoàn tất trong 0,15 giây game; không tạo slow motion thu kiếm.
- **Giữ từ 1 đến dưới 2 giây rồi thả:** skill_1 trong giây đầu, skill_2 báo charge sau mốc 1 giây. Khi thả, giữ thêm skill_2 đúng 0,10 giây rồi lao 270px tối đa, damage 24 (20 × 1,2), hit-stop 0,075 giây và stun 0,25 giây game. Sau skill_5, skill_6 phát 0,30 giây thực; thế giới chậm 0,50x, Player giữ tốc độ bình thường.
- **Đủ 2 giây:** skill_1 từ 0–1s, skill_2 từ 1–1,8s, skill_3 từ 1,8–2s. Tự lao ở mốc 2s dù chưa thả Q. Tầm tối đa 360px, damage 32 (20 × 1,6), hit-stop 0,10 giây, stun 0,40 giây game. Skill_5 rồi skill_6 và slow motion như mức 1 giây.

Thả ở 1,50 hoặc 1,90 giây đều lấy mức 1 giây; nếu đang ở skill_3 nhưng chưa đủ 2 giây thì trở lại skill_2 cho 0,10 giây release. Không phải giữ đúng một frame tại mốc. Auto lao mức 2 giây chỉ thực hiện một lần; giữ Q sau khi skill kết thúc không tự lặp lại, phải nhấn mới.

Skill 1–5 hiện là clip pose dài 0,05 giây; script giữ pose và quyết định thời lượng pha. Skill_6 giữ clip gốc 0,30 giây. Không retime resource gốc dùng chung giữa các Player.

## Vị trí điều chỉnh trong Godot

Mở **res://scenes/adel/playable_adel.tscn → chọn node SaberSkill**. Chỉnh trên scene này để thay mặc định; chỉnh SaberSkill của một Player instance trong map chỉ thay instance đó.

### Charge

- **Tap Windup = 0.20:** lấy đà tối thiểu của tap, tính từ nhấn Q.
- **Charge Level 1 Time = 1.00:** mốc nhận mức 1 giây.
- **Charge Level 2 Time = 2.00:** mốc auto lao mức cao nhất.
- **Charged Release Windup = 0.10:** thời gian skill_2 thêm sau khi thả ở mức 1 giây.
- **Full Charge Final Pose = 0.20:** thời gian skill_3 cuối cùng trước auto lao. Pha skill_2 khi giữ đến đầy là phần từ Level 1 đến (Level 2 − Final Pose), mặc định 0,80s.
- **Allow Airborne = Off:** lựa chọn mặc định cho bản đầu là chỉ bắt đầu skill trên mặt đất. Có thể bật để dùng Q từ trạng thái di chuyển trên không; không cho Q chen ngang jump_attack hay hành động khác. Mốc Level 2 thực tế được bảo đảm không nhỏ hơn Level 1 + Final Pose.

Các mốc charge, lấy đà, lao và impact dùng giây game, nên nhất quán khi có hiệu ứng thời gian khác. Q giữ trong pause không tích charge. Khi tiếp tục giữ qua ngưỡng, pose được chọn theo charge hiện tại; hướng lao được chốt theo hướng nhìn lúc bắt đầu Q.

### Lunge

- **Lunge Distance = 180:** khoảng lao cơ bản, đơn vị px của thế giới, đây là giá trị đề xuất để tự căn.
- **Lunge Speed = 900:** tốc độ lao px/giây game. Giữ tốc độ này thì tăng tầm cũng tăng thời lượng lao.
- **Charged Distance Multiplier = 1.50 / Full Distance Multiplier = 2.00:** hệ số khoảng lao.
- **Enemy Detection Mask = 5:** quét layer enemy (bit 4) và world (bit 1 để nhận diện enemy legacy), lọc body có take_damage và loại Player. Không dùng VFX hoặc Area2D vũ khí enemy làm điểm chặn lao.

Lao dừng ở hurtbox body đầu tiên hoặc tường/thế giới chặn trước đó, không đi xuyên tường. Query shape được quét theo chuyển động mỗi tick để tránh xuyên enemy khi tăng tốc; kiểm tra riêng nếu đã chồng hurtbox ngay lúc bắt đầu. Player/enemy vẫn đi xuyên nhau khi không dùng skill. Hurtbox hiện tại của enemy là CollisionShape2D trên CharacterBody2D.

### Damage And Stun

- **Damage = 20:** damage tap.
- **Charged Damage Multiplier = 1.20 / Full Damage Multiplier = 1.60:** damage mức charge, làm tròn số nguyên.
- **Charged Stun Duration = 0.25 / Full Stun Duration = 0.40:** thời gian stun theo **giây game**. Slow motion và hit-stop làm thời gian thực tương ứng dài hơn. Tap không áp stun.
- **Impact Pose Duration = 0.05:** thời gian game giữ skill_5 và cửa sổ hitbox, chưa gồm phần kéo dài do hit-stop.

Hitbox skill dùng đúng **WeaponPivot/SaberHitbox/Hitbox/CollisionShape2D**, cùng shape và transform của saber_attack_1; bốn đòn thường hiện dùng cùng transform. Tại impact, shape mở ngay, không chờ mốc active 0,15s của animation chém thường. Collider body Player không đổi kích thước. Skill không mở AttackHitbox legacy.

Lao dừng vì enemy đầu tiên; sau đó damage theo vùng Saber như đòn thường nên những enemy khác cùng nằm trong vùng chém có thể cũng trúng. Mỗi target chỉ nhận một lần trong một skill. Registry dùng chung giữa query ngay khi mở và signal body_entered, không nhân damage trong hit-stop. Chỉ damage được target chấp nhận mới tạo feedback/stun. Enemy chết vẫn cho hit-stop, không gắn stun lên node đã queue_free.

Stun là node tạm **Enemy/WeaponSkillStun**: giữ nguyên hurtbox, dừng AI và animation, chặn Area gây damage, xử lý gravity, rồi khôi phục các cờ xử lý/animation/monitoring trước đó. Có thể kéo dài bằng hit stun tiếp theo; không cộng dồn thời lượng một cách vô hạn. Không viết đè script prototype cũ hoặc sửa HP/damage kỹ năng của enemy. Hết stun tiếp tục hành động đang bị tạm dừng; chưa thêm animation stun riêng cho enemy.

### Impact Timing

- **Tap Hit Stop Duration = 0.065**.
- **Charged Hit Stop Duration = 0.075**.
- **Full Hit Stop Duration = 0.100**.
- **Recovery Slow Motion Scale = 0.50**.
- **Charged Recovery Duration = 0.30**.
- **Tap Recovery Duration = 0.15**: với clip skill_6 gốc 0,30s thì tương đương 2x.

Ba duration Hit Stop và slow motion recovery dùng giây thực không pause. Mức gần dừng dùng chung **PlayableAdel → Hit Stop → Hit Stop Scale**, hiện 0,05x. Công tắc **Hit Stop Enabled** trên PlayableAdel vẫn tắt được feedback hit-stop để A/B; nó không tắt slow motion recovery.

## Miễn sát thương, ngắt và trường hợp hụt

- Chỉ pha SKILL_DASH có miễn damage: đòn trực tiếp, HUD damage và bleeding tick không làm mất HP, không kích hoạt stagger. I-frame này dựa vào state skill, không ghi đè cờ/timer i-frame thường, nên không bị callback i-frame cũ kết thúc nhầm.
- Charge, release, skill_5 và skill_6 vẫn nhận damage. Stagger thật hủy skill, dọn hitbox, time effect, timer exemption và chế độ playback. Hit thường chưa chạm threshold vẫn dùng luật nhận đòn/i-frame hiện có, không tự thêm stagger mới.
- Trong lúc dùng skill, attack/defense/dash/jump mới không thay thế skill. Q không hủy combo, Defense, dash, pickup, campfire hoặc stagger đang có. Có thể bắt đầu từ Ready/di chuyển hợp lệ; chưa thêm input buffer Q.
- Mở pause/inventory, vào campfire, mất focus hoặc rời scene hủy skill và dọn trạng thái chờ; không thực hiện lại một lần Q cũ sau Resume.
- Không đặt chi phí stamina hay cooldown mới vì yêu cầu chưa có luật đó. Skill thuộc ATTACK nên chặn hồi stamina trong lúc thực hiện, theo luật hành động đang có.
- Khi không chạm enemy hoặc bị tường chặn: hết lao rồi skill_6 để thu kiếm; không phát impact skill_5 giả, không damage/stun/hit-stop hoặc slow motion thưởng. Charged whiff vẫn dùng thời lượng thu kiếm 0,30s, tap 0,15s. Đây là lựa chọn đề xuất, có thể thay đổi sau khi chơi thử.

## Time ownership và file chính

- **saber_weapon_skill.gd:** module skill, export Inspector, charge, sweep, impact, stun, recovery; child SaberSkill của Player.
- **adel_state_machine.gd:** SKILL thuộc ATTACK, có CHARGE / RELEASE / DASH / IMPACT / RECOVERY. Thoát SKILL dọn riêng rồi ATTACK dọn shared hitbox/callback.
- **saber_hitbox.gd:** mở cửa sổ skill theo shape chém thường, query ngay và signal target_hit cho feedback/stun, một hit mỗi target.
- **enemy_skill_stun.gd:** trạng thái tạm, dùng cho cả enemy hiện tại và prototype legacy mà không đổi script của chúng.
- **combat_time_effects.gd:** vẫn là autoload duy nhất quản lý scale combat. Bổ sung exemption cho Player ở charged skill_6; hit-stop vẫn làm chậm cả Player. Player physics, animation, stats/bleed, cooldown và damage timers giữ tốc độ bình thường trong exemption; pause vẫn dừng chúng.
- **damage_component.gd / ui.gd / stats_component.gd:** damage gate của pha lao, đồng hồ actor cho damage timer và stat tick. Timer damage không giữ SceneTreeTimer tự viết đè scale; dùng CombatTime.actor_timeout.
- **project.godot:** action weapon_skill gắn physical Q. Giữ nguyên Q đổi tab của UI khi menu có quyền input.
- **tests/adel/saber_skill_validation.tscn:** test input Q thật qua Input.parse_input_event, collision hurtbox, hai hướng, ba mức, nhả giữa mốc, auto lao, tường, lunge i-frame, stun, time exemption và stagger cleanup. Chạy trong project sao chép với custom user directory CodexSaberSkill để không dùng save thật.

Tài liệu engine đối chiếu: [shape sweep và initial overlap](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html), [manual animation advance](https://docs.godotengine.org/en/stable/classes/class_animationmixer.html), [global time scale](https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-property-time-scale). Exemption Player là logic riêng của dự án; Engine.time_scale không tự miễn một actor và không tự đổi tốc độ audio. Không thêm/chỉnh audio trong lượt này.

## Nghiệm thu

Đã thực sự chạy Godot 4.7 trên project sao chép với save riêng: **713 kiểm tra headless và 160 kiểm tra có render, 0 failures**. Bộ skill mới có 160 kiểm tra ở mỗi chế độ; còn lại là hồi quy. Không có SCRIPT ERROR/engine ERROR trong các log nghiệm thu cuối. Các cảnh báo Bone2D/rig đã có vẫn tồn tại. Lượt import editor có cảnh báo addon/UID và tài nguyên khi đóng editor, không nằm trong các log nghiệm thu runtime. Kiểm tra chức năng không thay thế lượt chơi thử/căn khoảng lao và nhịp skill của nhà thiết kế. Không kiểm chứng export trong phạm vi này.


- SABER SKILL RESULT: 160 checks, 0 failures
- HFSM RESULT: 31 checks, 0 failures
- GUARD STAMINA RESULT: 94 checks, 0 failures
- JUMP DAMAGE RESULT: 42 checks, 0 failures
- JUMP DEFENSE RESULT: 41 checks, 0 failures
- COMBAT FEEL RESULT: 106 checks, 0 failures
- READY RESULT: 21 checks, 0 failures
- LEAP HITBOX RESULT: 80 checks, 0 failures
- CAMP UI RESULT checks=58 failures=0
- ENTRY SAVE RESULT checks=60 failures=0
- DEATH RESULT: 20 checks, 0 failures
- SABER SKILL RESULT: 160 checks, 0 failures

Không dùng save thật, không thay clip/texture gốc, không thêm audio. Những lỗi parser trong quá trình phát triển đã được sửa và chạy lại trước khi áp dụng. Không commit/push.


## Cập nhật 2026-10-15 — đổi hướng khi tụ Q

A/D đổi hướng trong cả ba tư thế tụ Q khi vẫn giữ nút, đồng bộ animation/WeaponPivot và hướng lao. Không di chuyển ngang hoặc reset charge_time/tier. Release lấy hướng input mới nhất ngay cả khi đổi hướng và thả Q cùng một frame; hướng khóa từ lúc thả đến hết release/lunge/impact/recovery. Q nhấn nhanh vẫn giữ thời gian lấy đà tối thiểu; không đổi hướng trong phần lấy đà còn lại sau khi thả. Full charge khóa hướng lúc tự lao. Không đổi thông số thời gian, khoảng cách, damage, i-frame hoặc stun.

Test `res://tests/adel/facing_input_validation.tscn`: 29 check headless + 29 check có render. Có kiểm tra hitbox thật gây đúng sát thương cho enemy bên trái sau khi quay, các pose tụ, nhấn nhanh, release cùng frame và tự lao full charge. Chỉ chạy trên save riêng CodexFacingInput20261015.
