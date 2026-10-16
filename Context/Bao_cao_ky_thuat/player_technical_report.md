# Player, combo, Q Saber và Dark Sentinel

Cập nhật: 16/10/2026. Đây là báo cáo hiện hành đã gộp các bản theo từng lượt sửa. Tra vị trí và giá trị tùy chỉnh trong [hướng dẫn chung](huong_dan_tuy_chinh.md).

## 1. Ownership và HFSM

`res://scenes/adel/playable_adel.gd` điều phối input, state và các component. `AdelStateMachine` quản lý cây trạng thái: Locomotion gồm Grounded/Airborne/Ready; Attack gồm Combo, Jump Attack và Skill; ngoài ra có Defense, Dash, Stagger, Rest, Pickup, Sentinel Entry. Quyền ưu tiên phản ứng và cleanup thuộc HFSM, không chỉ dựa vào animation đang phát.

- `LocomotionComponent`: di chuyển ngang, trọng lực, nhảy và tiếp đất.
- `CombatComponent`: tiến trình combo, buffer nối đòn, rơi chậm, khoảng ngưng rơi và jump attack.
- `AdelAnimationComponent`: trình bày, hướng nhìn, biến thể ready và đọc mốc frame; không sửa animation nguồn khi tạo biến thể runtime.
- `DashComponent`: eligibility, pha active/skid, chuyển động, i-frame và cooldown dash.
- `StatsComponent`: model HP, stamina, bình máu, hiệu ứng và threshold. Player sở hữu model, dù source vẫn nằm ở `scenes/UI/stats_component.gd`.
- `PlayerVitals`: tick gameplay và gọi model; HUD quan sát cùng model qua signal/facade. Tháo hoặc ẩn HUD không dừng regen, bleed, tự rút HP hay nhận damage.
- `SaberWeaponSkill`, `ChargedSkillFinish`, `StaggerImpact`, `CombatTime`: lần lượt sở hữu skill Q, freeze khi trả zoom, phản hồi va chạm và các nguồn thay đổi thời gian.
- `DarkSentinelState`: vào dạng, hồi theo tick, tự rút HP và chờ thoát.

Đây là cấu trúc HFSM có component và adapter tương thích HUD cũ; chưa phải framework đa vũ khí hoàn chỉnh. Một số module còn gọi coordinator. Không tách thêm HFSM riêng theo vũ khí trong lần tổng hợp tài liệu này.

## 2. Combo thường, input và ready

Combo dùng `saber_attack_1/2/3/4`. Damage cơ sở lấy từ `WeaponHolder/Saber`; đòn 4 nhân `combo_finisher_multiplier`. Hitbox điều khiển bằng AnimationPlayer riêng tại `WeaponPivot/SaberHitbox`; mỗi mục tiêu chỉ nhận một hit trong cùng cửa sổ đòn. Không chỉnh `AttackHitbox` legacy để căn hitbox combo đang dùng.

Attack → Defense có khóa theo thời gian riêng cho đòn 1–3 và đòn 4; khi giữ chuột phải hợp lệ thì ghi ý định và thực thi lúc được phép. Cửa sổ deflect tính từ lần nhấn ban đầu, không được cấp lại miễn phí chỉ vì chờ hết đòn. Buffer combo có thời hạn. Giữ Q có thể chờ hết đòn thường, nhưng không cắt đòn giữa chừng.

Fracture đã được nối vào gameplay: giảm damage combo/jump/ba mức Q đúng một lần tại hitbox, giảm tốc di chuyển ngang và giảm nhịp đánh combo/jump từ cấp 2. Animation hình/hitbox cùng hệ số, mốc nối đòn và khóa Defense/land đi cùng nhịp đánh; Q giữ timing riêng. Dùng bình hạ cấp giữa đòn cập nhật hệ số mà không khởi động lại clip. Cơ chế đầy đủ ở [báo cáo phòng thủ](defense_guard_deflect_stagger_stamina_report.md), thông số chỉ quản lý trong [hướng dẫn chung](huong_dan_tuy_chinh.md#fracture).

Sau Defense/Guard/Deflect/Stagger, `saber_ready` dùng riêng frame cuối trong thời lượng 1 giây và có thể bị ngắt. Q hoàn tất bình thường dùng đầy đủ chuỗi ready 0→1→2. Khi bị stagger ngắt attack, cleanup vô hiệu hóa callback/cửa sổ cũ, tránh kẹt trạng thái không thể đánh tiếp.

## 3. Đánh trên không và jump attack

Combo trên không không còn đẩy X mỗi lần vung. Nó giữ một vận tốc rơi tham chiếu theo trọng lực/giới hạn của locomotion, rồi nhân hệ số rơi chậm. Nối đòn không đặt lại tham chiếu. Bắt đầu đánh khi còn bay lên sẽ ngắt quán tính lên và chuyển sang rơi chậm.

Ở `saber_attack_1/2/3`, tới key có giá trị frame 1 của `TestAttackSprite:frame` thì ngưng rơi một lần trong thời gian cấu hình. Animation, hitbox và input vẫn tiếp tục; sau đó rơi tiếp với tham chiếu đang có. Đòn 4 không thêm khoảng ngưng. Đổi timing key sẽ tự thay mốc ngưng. Đòn dưới đất tiêu thụ marker mà không ngưng rơi; đi khỏi mép nền sau marker không kích hoạt muộn.

`jump_attack(air)` giữ nguyên độ cao suốt animation thật, hiện clip dài 0,25 giây; signal kết thúc mới cho chuyển sang lao xuống. Việc giữ này theo pause, slow motion và tốc độ animation. Pha lao xuống và land dùng `JumpAttackHitbox`, có query bổ sung khi chạm đất và chống hit lặp trong cùng chuỗi. Jump attack gây damage; land có thời điểm mở movement/Defense riêng. Không Defense trong air/fall.

## 4. Dash và input sau skid

Dash đất gồm Active rồi Skid; air dash không có Skid. Cooldown bắt đầu khi rời Dash và **chỉ chặn dash tiếp theo**. Defense, Q, attack và các hành động hợp lệ có thể bắt đầu ngay sau Skid, vẫn giữ điều kiện stamina/state riêng. Giữ Q không tự lặp skill; Q từ Defense buộc nhả rồi nhấn lại Defense để nhận tiếp.

Chuyển động dash dùng tích phân trong physics, không dùng Tween ghi vận tốc. Với đường cong QUAD/EASE_OUT, quãng đường không bị cản là `duration × (end_speed + (start_speed - end_speed) / 3)`. Va tường rút ngắn quãng đường. Active sở hữu nguồn i-frame DASH; Skid không tự cấp i-frame. Hết/gián đoạn dash dọn đúng nguồn và chỉ bắt đầu cooldown một lần. Double jump/tiếp đất reset quyền air dash theo luật hiện tại.

## 5. Q Saber: ba mức

Đây là Q của Saber thường, không phải Q xích của thiết kế Sentinel.

- Nhấn hoặc thả trước mốc charge 1: `saber_skill_1`, lao ngắn với `saber_skill_4`, chạm enemy đầu tiên thì dừng, `saber_skill_5`, rồi `saber_skill_6` nhanh.
- Đạt mốc charge 1 rồi thả trước mốc 2: dùng mức 1; sau khi thả có windup riêng trước khi lao. Khoảng lao, damage và hit-stop nhân/lấy thông số mức 1; có stun enemy ngắn.
- Đạt mốc charge 2: kết thúc pose charge cuối rồi tự lao, không chờ thả Q. Dùng khoảng lao, damage, hit-stop và stun mức 2.

Lunge kiểm tra hurtbox enemy đầu tiên và vật cản, dừng ngay khi va chạm. Skill dùng vùng đánh tương đương combo; không dùng vùng detect lunge làm vùng damage. Miễn damage chỉ trong pha lao. Các pha khác có thể bị stagger ngắt; cancel dọn animation, hitbox, hiệu ứng thời gian, zoom và buffer thuộc Q.

Damage, stun, hit-stop, recovery và zoom/slow motion tại impact có tham số riêng. Ba bộ Tap Impact/Charge Level 1 Impact/Charge Level 2 Impact độc lập với stagger. Recovery `saber_skill_6` của charge có slow motion toàn game trừ Player; chiều dài clip được retime về thời lượng cấu hình, không giả định clip luôn dài 0,3 giây.

## 6. Q charge: giữ zoom rồi freeze khi trả zoom

Khi charge mức 1/2 đánh trúng, zoom tăng ngay tại `saber_skill_5` và giữ đỉnh suốt toàn bộ `saber_skill_6`. Xong clip mới trả zoom theo thời gian thực; trong lúc trả dùng pause thật của SceneTree để đóng băng Player, enemy, physics, animation và timer gameplay. Chỉ controller camera/input của pha này tiếp tục chạy. Bố cục Y và độ lệch X hiện có được giữ.

Trong freeze, ghi tối đa một yêu cầu mới nhất cho Attack/Q/Defense/Dash/Jump/Soul Heal. Input không hết hạn và không thực hiện sớm. Defense cần vẫn giữ nút lúc mở băng; dash kiểm tra lại stamina/cooldown; Q đã nhả dùng nhánh tap. Không tích hàng dài combo và không buffer thao tác UI. Esc/B/F không lấy quyền pause giữa freeze. Mất focus, checkpoint hoặc đổi scene dọn quyền pause/buffer cũ.

Trả zoom xong, nhả đúng pause của Q, full ready rồi phát lại input còn hợp lệ. Chặn callback damage đến muộn trong freeze, không cộng thêm i-frame sau đó. Kết thúc các slow motion thuộc Q khi vào freeze để không chạy lại sau mở băng. Nhấn nhanh không có freeze này. Đánh hụt/tắt zoom/hệ số zoom bằng 1/thời gian trả bằng 0 không gây freeze vô hình.

## 7. Dark Sentinel: đã có và còn chờ

Đã triển khai phần nền gameplay và HUD:

- R kích hoạt khi thanh đầy; vào dạng bất động và có nguồn i-frame riêng. Hồi HP/stamina theo phần trăm tối đa mỗi tick tới cuối entry, khôi phục rồi tạm vô hiệu hóa threshold. Hồi đầy được chốt khi hoàn tất entry.
- Tự rút HP theo phần trăm **HP tối đa** mỗi giây game; dừng khi pause và chịu slow motion. Đường tự tiêu HP/chi phí Sentinel không kích hoạt stagger, không bị guard/Toughness/i-frame giảm và không tự giết Player.
- Chạm 1 HP thì dừng rút, chờ hành động đang chạy kết thúc; Defense không giữ việc thoát. Trong lúc chờ chặn combo/kỹ năng mới. Enemy vẫn có thể giết Player, kể cả trong lúc chờ.
- Thoát giữ HP còn lại, bật lại threshold. Marker đã vượt không kích hoạt ngay hoặc hồi HP lên mốc; đòn trực tiếp kế tiếp mới tiêu một marker ngoài cùng và nhận random debuff. Tick bleed vẫn bỏ qua threshold.
- Không dùng bình máu trong dạng. T cộng ulti và Y thoát phục vụ debug; R không dùng để chủ động thoát theo thiết kế chính thức. HUD đổi skin HP, ẩn marker và hiện loadout góc trái dưới; HUD không tự triển khai kỹ năng.

**Chưa triển khai đầy đủ:** đổi/cố định vũ khí Sentinel, skill Q/E/1/2/3/4, chi phí/cooldown tương ứng, Sharpness/Toughness hoàn chỉnh và tích ulti từ đánh trúng/kill. Đường `DarkSentinelState.activate()` hiện chưa gọi xóa debuff; hồi HP/stamina và tạm tắt threshold không đồng nghĩa đã xóa Bleed/Fracture. Không xem các icon/slot hay `spend_sentinel_hp()` là bằng chứng full skill đã hoạt động.

Đặc tả đã duyệt cần giữ cho bước sau:

- Chiêu 1 cắm kiếm, đẩy lùi và Toughness. Chiêu 2 đánh dấu enemy đầu tiên; tái kích hoạt teleport + jump attack + hồi ít HP. Chiêu 3 tụ lực phóng to kiếm rồi đập xuống, tăng kích thước/damage/HP cost theo charge và không bị choáng khi tụ. Chiêu 4 là cách chủ động thoát và cấp Sharpness I.
- Chiêu 1–4 dùng HP; thiếu HP không dùng. HP cost không tự giết, tới 1 HP theo luồng thoát. Q/E dùng stamina. Q phóng xích kéo Player rồi có thể nối đánh xoay bằng chuột trái; Q Sentinel không có i-frame. E thường teleport ngắn; E trong Defense lao tới stun/đẩy enemy; i-frame E ngắn hơn dash.
- Toughness giảm damage nhận, tạm loại threshold và giảm stamina Guard/Deflect; Sharpness tăng mọi damage gây ra. Chưa chốt phần trăm/thời lượng/chi phí/cooldown.
- Không tích ulti trong dạng. Khi có thêm vũ khí, chuẩn hóa tốc độ tích để vũ khí đánh nhanh không lợi thế vô điều kiện so với vũ khí chậm.
- Phân loại debuff cơ bản và cao cấp: Bleed/Fracture, và Poisoning khi làm, thuộc cơ bản; cao cấp cần điều kiện riêng. Hiện chưa có debuff cao cấp. Giữ phân biệt thiết kế tương lai với tác dụng bình máu thực tế ở báo cáo phòng thủ.

## 8. Kiểm chứng và giới hạn

Các lượt triển khai trước đã chạy Godot thật với save thử riêng; scene kiểm tra nằm dưới `res://tests/adel/` và `res://tests/ui/`. Air pause mới có 64 assertions headless và 64 có hiển thị; hồi quy air combo 44, combat feel 106, jump defense 41, jump damage 42 và HFSM 32, tổng 393 lượt assertion đạt ở lần bàn giao gần nhất. Đây không phải 393 kịch bản độc lập và không đại diện playthrough/balance/export.

Lượt gộp tài liệu ban đầu chỉ đối chiếu nguồn, giá trị scene, liên kết và hash, không chạy lại Godot hoặc đổi gameplay. Lượt hoàn thiện Fracture sau đó ngày 16/10/2026 đã chạy **381 assertions đạt** trên bản sao project/save riêng, gồm 80 headless + 80 có render cho Fracture và 221 hồi quy combat/HFSM/jump; chi tiết ở [báo cáo phòng thủ](defense_guard_deflect_stagger_stamina_report.md#7-source-và-kiểm-tra-liên-quan). Các cảnh báo rig/UID có sẵn, giới hạn nhiều Player/resource rig dùng chung, cân bằng combat và hiệu năng nhiều enemy vẫn chưa được nghiệm thu toàn diện.
