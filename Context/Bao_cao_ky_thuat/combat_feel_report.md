# Combat feel: Attack → Defense, input buffer, hit-stop

Ngày: 15/10/2026. Phạm vi: PlayableAdel, Saber combo 1–4, Defense/Guard/Deflect và điều phối hiệu ứng thời gian.

## Hành vi đã chốt

- Attack 1–3 mở Defense ở **0,60 giây**, Attack 4 ở **0,75 giây**, tương ứng cuối animation hiện tại. Giữ chuột phải trong lúc đánh sẽ ghi nhận yêu cầu, không cần nhấn lại. Thả nút trước khi được phép sẽ hủy yêu cầu.
- Không bắt buộc đi qua saber_ready giữa attack và defense. Khi có yêu cầu Defense hợp lệ, không nối combo đang chờ. Vào Defense sẽ dọn queue, hitbox, callback đòn cũ và bắt đầu lại combo từ đòn 1 ở lần tấn công mới.
- Các mốc nối combo / cho di chuyển hiện có **0,40 / 0,55 giây** được giữ. Nếu đã rời đòn bằng di chuyển, vẫn phải chờ đủ ngân sách 0,60 / 0,75 giây của đòn đó mới vào Defense, tránh dùng di chuyển để đỡ sớm.
- Quy tắc này áp dụng combo Saber. Áp dụng thêm Defense chờ trong chuỗi jump attack: air/fall chỉ ghi nhận ý định, không có bảo vệ; landing mở Defense sau khi hết clip mặc định 0,50 giây. Không mở Defense trong Dash, Pickup hoặc Stagger.
- Thời điểm nhấn giữ chuột phải là gốc tính Deflect: **[0;0,10) Guard → [0,10;0,30) Deflect → [0,30;∞) Guard**. Thời gian này vẫn trôi trong phần attack còn cam kết. Không cấp lại cửa sổ Deflect khi animation attack kết thúc. Không reset cửa sổ khi đổi pose Guard/Deflect.
- Ví dụ: nhấn RMB ở giây 0,10 của Attack 1, Defense bắt đầu ở 0,60: đã giữ 0,50 giây nên vào Guard. Nhấn ở 0,50: vào Defense ở 0,60, vừa tới đầu cửa sổ Deflect; hết Deflect ở 0,80 tính từ đầu attack.
- Guard/Deflect vẫn cần hit từ phía trước và stamina dương. Không thay chi phí, giảm damage, recoil, stagger threshold, thiếu stamina hoặc i-frame hiện có. Guard đầu tiên có thể tạo i-frame theo luật cũ; không phải mọi overlap tiếp theo trong cửa sổ Deflect đều được nhận.

## Vị trí chỉnh trong Godot

Mở **res://scenes/adel/playable_adel.tscn**, chọn root **PlayableAdel**. Để thay mặc định dùng scene này; override trên Player trong map chỉ đổi instance đó.

### Combat Input

- **Attack Defense Unlock Time = 0.60**: mốc mở Defense cho Attack 1/2/3, tính từ bắt đầu mỗi nhát, theo giây game.
- **Attack 4 Defense Unlock Time = 0.75**: mốc tương tự cho đòn 4.
- **Jump Attack Land Defense Unlock Time = 0.50**: mốc mở Defense tính từ lúc bắt đầu jump_attack(land), bằng độ dài clip đáp hiện tại. Giữ RMB từ air/fall cũng chỉ vào Defense sau mốc này; tuổi Deflect vẫn tính từ lần nhấn, không reset khi chạm đất. Movement unlock 0,30 giây không mở Defense sớm hơn. Thả nút, stagger, zero stamina hoặc campfire vẫn hủy yêu cầu theo luật chung.
- **Attack Input Buffer = 0.18**: thời hạn tối đa của một lần nhấn Attack đang chờ. Nhấn trước mốc nối combo không quá 0,18 giây có thể nối; nhấn quá sớm sẽ hết hạn. Chỉ giữ một lệnh, không tích hàng dài; nhấn mới thay lệnh cũ.

Hai mốc Defense không tự kéo dài/rút ngắn animation gốc. Nếu cố ý giảm chúng xuống dưới độ dài clip, Defense có thể ngắt clip sớm. Nếu tăng lên cao hơn độ dài clip, phải chờ thêm đến mốc đó. Các mốc 0,60/0,75 mặc định không bị giảm chỉ vì mốc di chuyển/nối combo cũ đã mở.

### Defense

- **Deflect Delay = 0.10**: thời gian đầu chỉ Guard, tính từ lần nhấn giữ.
- **Deflect Window = 0.20**: độ dài cửa sổ Deflect sau Delay; mốc kết thúc là Delay + Window.
- **Deflect Slow Motion Scale / Duration**: giữ nguyên tuning đang lưu **0.50x / 0.45 giây thực**. Hit-stop kết thúc rồi mới bắt đầu tiêu thời lượng slow motion này; saber_deflect được giữ qua cả hai pha.

### Hit Stop

- **Hit Stop Enabled = On**: tắt để A/B so sánh cảm giác.
- **Hit Stop Scale = 0.05**: gần dừng toàn bộ mô phỏng dùng thời gian game; không đặt bằng 0.
- **Attack Hit Stop Duration = 0.035s**: Saber 1–3 đánh trúng.
- **Finisher Hit Stop Duration = 0.055s**: Saber 4 đánh trúng.
- **Guard Hit Stop Duration = 0.025s**: Guard thành công đủ stamina.
- **Deflect Hit Stop Duration = 0.065s**: Deflect thành công đủ stamina, trước slow motion.

Duration ở nhóm Hit Stop dùng giây thực đang không pause: 0,035 giây = 35ms. Duration = 0 bỏ pulse cho loại đó. Đánh hụt, damage 0, target từ chối hit hoặc contact lặp lại không tạo pulse Saber mới. Cả hai hướng đều dùng cùng quy tắc.

Những giá trị hit-stop/buffer là điểm khởi đầu có thể chỉnh. Chưa thêm pulse riêng cho jump_attack, hit thường lên Player, bleed, threshold hoặc thiếu stamina. Không thêm audio, screenshake hay thay asset/animation gốc.

## Input và vòng đời

- Defense là ý định giữ; Attack là một lệnh nhấn có hạn. Stagger/contact reaction/Dash/Pickup/Rest, mở pause/inventory và mất focus xóa ý định chờ; không replay lệnh từ trước menu hoặc stun.
- Stamina = 0 không nhận yêu cầu Defense mới. Hồi stamina khi vẫn giữ một lần nhấn bị từ chối không tự bật Defense; phải thả và nhấn lại.
- Input vẫn được nhận trong hit-stop. Tuổi yêu cầu Defense và hạn buffer dừng trong hit-stop để không bị mất cửa sổ do hiệu ứng feedback; sau đó tiếp tục theo giây game. Trong Deflect slow motion, các cửa sổ theo thời gian game chậm tương ứng.
- CombatTime là autoload duy nhất điều phối Engine.time_scale cho combat. Nhiều hiệu ứng lấy mức làm chậm mạnh nhất. Nhiều target cùng một nhát chỉ có một pulse; các pulse hợp lệ không cộng tổng duration.
- Pause tạm dừng thời lượng pulse và trả scale nền cho UI. Resume tiếp tục phần còn lại. Owner rời scene, chết hoặc vào campfire sẽ hủy hiệu ứng tương ứng và khôi phục scale còn hiệu lực / scale nền, không kẹt tốc độ.
- Engine.time_scale không đổi tốc độ audio. Không chỉnh hệ thống âm thanh trong lượt này. Tài liệu: https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-property-time-scale

## File chính

- scenes/adel/playable_adel.gd: các export Inspector, ghi nhận/thực hiện Defense, thời gian cam kết, phản ứng hit.
- scenes/adel/components/adel_state_machine.gd: đưa press/release đến luồng xử lý, giữ cleanup ở parent ATTACK/DEFENSE.
- scenes/adel/components/combat_component.gd: buffer Attack một lệnh có thời hạn.
- scenes/adel/components/defense_component.gd: phân loại theo Delay và Window, giữ tuổi lần nhấn.
- scenes/adel/components/saber_hitbox.gd: xác nhận impact một lần mỗi swing sau khi target nhận damage.
- scenes/adel/components/combat_time_effects.gd: autoload CombatTime, quyền sở hữu scale, pause và cleanup.
- scenes/adel/components/deflect_slow_motion.gd: vòng đời pose Deflect, gửi slow-motion request về CombatTime.
- scenes/UI/pause.gd và master_menu.gd: xóa input cũ khi menu nhận quyền điều khiển.
- tests/adel/combat_feel_validation.tscn: test tích hợp qua Input.parse_input_event, HFSM và collision thật; cần custom user directory bắt đầu CodexCombatFeel.

## Kiểm chứng

Kết quả cuối và giới hạn được ghi ở phần nghiệm thu sau khi chạy đầy đủ. Các test save/checkpoint chạy trên project sao chép với thư mục user data riêng, không dùng save thật. Đây là kiểm chứng chức năng, không thay thế đánh giá nhịp combat bằng chơi thử của nhà thiết kế.


### Nghiệm thu cuối

Godot 4.7 thực sự chạy trên project sao chép với user data cô lập. Các kết quả:

- COMBAT REPRO RESULT: 3 checks, 0 failures
- COMBAT FEEL RESULT: 106 checks, 0 failures
- HFSM RESULT: 31 checks, 0 failures
- GUARD STAMINA RESULT: 94 checks, 0 failures
- JUMP DAMAGE RESULT: 42 checks, 0 failures
- LEAP HITBOX RESULT: 80 checks, 0 failures
- CAMP UI RESULT checks=58 failures=0
- ENTRY SAVE RESULT checks=60 failures=0
- DEATH RESULT: 20 checks, 0 failures
- READY RESULT: 21 checks, 0 failures
- COMBAT FEEL RESULT: 108 checks, 0 failures

Không có SCRIPT ERROR hoặc engine ERROR trong các log nghiệm thu trên. Cảnh báo Bone2D/rig sẵn có còn tồn tại. Lượt import editor cũng có cảnh báo FMOD bank/UID và cảnh báo tài nguyên khi đóng editor; không coi đó là kiểm chứng toàn dự án sạch lỗi. Không kiểm tra export hay một lượt chơi toàn map. Asset, rig, audio, thời lượng clip gốc và save thật không được chỉnh. Không commit/push.


### Bổ sung jump_attack → Defense, 15/10/2026

Giữ RMB trong air/fall/land được ghi nhận; chỉ landing mở Defense theo mốc 0,50 giây mặc định. Air/fall không có Guard/Deflect. Không đổi damage 20, cửa sổ gây damage landing, clip gốc hoặc timing di chuyển/nối đòn khi không có yêu cầu Defense. Dọn jump hitbox ở transition sang Defense; không tự ra đòn Attack cũ sau khi thả Defense.

- JUMP DEFENSE RESULT: 41 checks, 0 failures
- JUMP DAMAGE RESULT: 42 checks, 0 failures
- COMBAT FEEL RESULT: 106 checks, 0 failures
- HFSM RESULT: 31 checks, 0 failures
- JUMP DEFENSE RESULT: 41 checks, 0 failures

Các kết quả trên đã thực sự chạy bằng Godot 4.7 trên bản sao project với save cô lập, gồm collision/floor contact thật, hai hướng, giữ từ air/fall, release, movement unlock, stamina 0 và stagger. Không có SCRIPT ERROR/engine ERROR trong các log nghiệm thu. Chưa commit/push.


### Skill vũ khí Q

Skill Saber ba mức charge đã được tách vào node SaberSkill. Hướng dẫn khoảng lao, mốc giữ Q, hit-stop, stun và slow motion trừ Player: [saber_weapon_skill_report.md](saber_weapon_skill_report.md). Không dùng các export damage/hit-stop của combo thường để thay cho tuning riêng của skill Q.
