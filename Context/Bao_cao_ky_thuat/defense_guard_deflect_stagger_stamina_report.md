# BÁO CÁO KỸ THUẬT — DEFENSE / GUARD / DEFLECT / STAGGER / STAMINA

**Dự án:** Sojourn: Echoes of the Soul  
**Ngày lập:** 14/10/2026  
**Phạm vi:** hệ thống phòng thủ, nhận đòn và stamina của PlayableAdel; tương tác với các nguồn damage.  
**Nguồn:** code và scene đang lưu tại `D:/Godot Project/soujourn--echoes-of-the-soul`. Báo cáo này được tách từ phần combat Player trong `enemy_technical_report.md` và bổ sung chi tiết để đọc độc lập.

Trong lượt tách báo cáo chỉ sửa tài liệu. Không thay đổi code, tuning, asset, rig, audio hoặc gameplay. Các kết quả chạy Godot ở mục 12 thuộc những lượt kiểm thử trước; không chạy lại game trong lượt tách tài liệu này.

## 1. Các khái niệm và luật hiện tại

- **Defense:** trạng thái giữ phòng thủ. Nhấn nút sẽ giữ pose `saber_defense`; bản thân việc giữ chưa phải Guard/Deflect thành công và không trừ stamina.
- **Deflect:** nhận một đòn hợp lệ từ phía trước trong 0.2 giây đầu kể từ bắt đầu Defense, gồm mốc đúng 0.2 giây. Đủ stamina thì không mất HP, phát `saber_deflect` và slow motion.
- **Guard:** nhận đòn hợp lệ từ phía trước sau cửa sổ Deflect, khi Defense vẫn có bảo vệ. Giảm damage cơ bản 50%, trừ stamina, phát `saber_guard` và bật lùi ngang nhẹ.
- **Stagger threshold:** mốc 66% và 33% max HP. Đòn trực tiếp vượt/chạm mốc còn sẵn sẽ chặn HP tại mốc, tiêu marker, gây phản ứng bật lùi/stun và áp debuff.
- **Stagger do thiếu stamina:** dùng cùng phản ứng vật lý/animation/i-frame, nhưng không tiêu marker HP, không áp debuff ngẫu nhiên và không tự kích hoạt khóa HP mới.
- **Stamina:** thanh xanh lục dưới HP. Tốn khi bắt đầu Dash hoặc khi một đòn được xử lý là Guard/Deflect. Attack chưa có chi phí stamina trong phạm vi hiện tại.

HP-threshold lock, trạng thái stunned và i-frame là ba cơ chế khác nhau: khóa HP nằm trong StatsComponent; quyền điều khiển/phản ứng nằm trong DamageComponent/HFSM; i-frame chặn tiếp nhận đòn ở Player. Không dùng một cờ để diễn giải cả ba.

## 2. Cấu trúc và trách nhiệm

### 2.1. Những file chính

- `res://scenes/adel/playable_adel.gd`: điều phối input, `take_damage()`, Defense, dash, slow motion, stagger và cấu hình stamina từ Inspector.
- `res://scenes/adel/playable_adel.tscn`: lưu tuning của nhân vật. Override scene/instance ưu tiên hơn default script.
- `res://scenes/adel/components/adel_state_machine.gd`: HFSM, quyền sở hữu hành động, transition và enter/exit cleanup.
- `res://scenes/adel/components/defense_component.gd`: RefCounted, quản lý thời gian giữ, phân loại đòn, ngân sách bật lùi Guard. Không tự trừ HP/stamina hoặc phát animation.
- `res://scenes/adel/components/damage_component.gd`: RefCounted, quản lý push/stun/i-frame, signal và kiểm tra vòng đời body trước timer/callback.
- `res://scenes/adel/components/adel_animation_component.gd`: RefCounted, trình bày pose và biến thể ready chỉ frame cuối theo từng instance.
- `res://scenes/adel/components/deflect_slow_motion.gd`: Node giữ pulse time scale, timeout theo thời gian thực và khôi phục scale.
- `res://scenes/UI/stats_component.gd`: RefCounted, mô hình HP, threshold, debuff, stamina, chi phí và hồi phục; không phụ thuộc SceneTree.
- `res://scenes/UI/ui.gd`: facade cho StatsComponent, đồng bộ thanh chỉ số/marker/icon, xử lý feedback và gọi SaveManager khi chết.
- `res://scenes/UI/status_icon_slot.gd`: dùng icon Bleed/fracture và thể hiện cấp hiệu ứng.
- `res://scenes/Mechanic/player_progress.gd`: max HP/stamina cơ bản, nâng cấp và áp chỉ số vào HUD.

### 2.2. HFSM liên quan

```text
ROOT
├── LOCOMOTION
│   ├── GROUNDED
│   ├── AIRBORNE
│   └── READY
├── ATTACK
│   ├── COMBO
│   ├── JUMP_ATTACK → JUMP_HANG / JUMP_FALL
│   └── JUMP_LAND
├── DEFENSE
│   ├── DEFENSE_HOLD
│   ├── GUARD_REACTION
│   └── DEFLECT_REACTION
├── STAGGER
│   ├── KNOCKBACK
│   └── STUN
└── DASH / CONTACT_REACTION / REST / PICKUP
```

Chuyển giữa hai state con của DEFENSE không thoát parent nên không reset thời điểm bắt đầu Defense. Khi thoát DEFENSE, component kết thúc bảo vệ và dọn recoil/timer pose. Khi thoát ATTACK, queue/callback/hitbox được dọn. Slow motion là hiệu ứng có vòng đời riêng, có thể cùng tồn tại với một trạng thái vật lý; không dùng nó thay cho HFSM.

## 3. Luồng nhận đòn và điều kiện Defense

Nguồn damage gọi `PlayableAdel.take_damage(dmg, hit_from_global)`. Enemy mới gửi origin là vị trí root enemy, không phải điểm va chạm VFX. Các đòn leap/attack2/attack3 và normal/special của vũ khí legacy dùng cùng quy tắc phía Player.

Thứ tự xử lý chính:

1. Bỏ qua damage ≤0, body ngoài tree/queued deletion, hoặc Player đang invulnerable/stunned.
2. Lấy HUD sở hữu chỉ số; nếu Defense còn cờ giữ nhưng stamina đã về 0 thì kết thúc bảo vệ trước khi phân loại.
3. DefenseComponent trả NONE, DEFLECT hoặc GUARD theo trạng thái, hướng và thời gian giữ.
4. Nếu đỡ hợp lệ: xác định đủ/thiếu stamina **trước khi trừ**, rồi tiêu chi phí hoặc phần còn lại.
5. DEFLECT chặn HP; GUARD giảm damage rồi đi tiếp vào StatsComponent. Phản ứng thiếu stamina dùng nhánh riêng.
6. Kiểm tra chết/respawn/rời tree sau khi apply damage, trước khi tạo phản ứng/timer tiếp theo.
7. Nếu sống: thiếu stamina → stagger vật lý; threshold thật → stagger threshold; damage thường >0 → i-frame nhận đòn ngắn.

Để bắt đầu Defense, HFSM phải cho phép bắt đầu hành động từ LOCOMOTION, không bị external lock/stun/contact reaction/slow-motion lock và stamina phải **>0**. Defense không được bắt đầu giữa ATTACK hoặc DASH. Điều kiện không yêu cầu luôn đứng sàn: có thể Defense trong AIRBORNE; gravity vẫn được áp theo nhánh vật lý tương ứng.

Hướng đỡ dùng dấu của `(hit_from.x - player.x) × facing_direction`. Giá trị phải >0. Đòn phía sau, cùng x hoặc origin không hữu hạn không được coi là frontal hit. Như vậy, một VFX đi qua trước mặt nhưng origin enemy ở sau vẫn không được đỡ theo định nghĩa hiện tại.

Sau khi bắt đầu Defense, `_update_defense()` kiểm tra release/lock/stamina trước nhánh xử lý chuyển động, giúp tránh giữ bảo vệ do mất hoặc bị tiêu thụ sự kiện release. Thời gian Deflect được đo từ **lần bắt đầu Defense**, không reset bởi mỗi lần Guard/Deflect hay mỗi lần đổi reaction pose.

## 4. Defense và Guard đủ stamina

### 4.1. Defense không nhận đòn

Giữ `saber_defense` cả khi đã quá 0.2 giây nếu chưa có hit. Không tự chuyển `saber_guard` chỉ vì hết cửa sổ Deflect. Không trừ stamina khi chỉ giữ nút, nhưng trạng thái Defense vẫn chặn hồi stamina.

Trong Defense, di chuyển ngang chủ động, tấn công, nhảy mới và Dash không được xử lý như trạng thái locomotion bình thường. Gravity/chuyển động dọc đang có vẫn được xử lý, tránh treo nhân vật trên không.

### 4.2. Guard thành công

Guard đủ chi phí hiện trừ **20 stamina** mỗi hit được chấp nhận. Hệ số damage cơ bản là `1 - guard_damage_reduction = 0.5`. Player làm tròn damage sau Guard rồi chuyển vào StatsComponent để áp modifier nhận damage và threshold.

Ví dụ hit 20, không có debuff: nhận 10 HP. Nếu Fracture cấp 1 thì damage sau Guard 10 được nhân 1.2 thành 12 HP. Nếu phòng thủ được cấu hình giảm 100% thì damage về 0; vẫn là một hit đỡ thành công và vẫn xử lý chi phí/phản ứng, không ép trở lại 1 HP.

Guard reaction giữ pose `saber_guard`, bật lùi **ngang 20 đơn vị trong 0.1 giây** theo scene đang lưu, không thêm vận tốc hất lên. Recoil dùng ngân sách quãng đường và `move_and_slide()`, nên tường có thể chặn bớt quãng đường. Normal Guard trong không trung không tự thêm một cú nhấc lên; gravity/vận tốc dọc theo vật lý hiện có tiếp tục được xử lý.

Pose Guard tồn tại ít nhất theo `Defense Hit Pose Duration` hiện **0.2 giây**, và vẫn giữ nếu ngân sách push chưa kết thúc. Vì vậy push 0.1 giây không có nghĩa pose phải hết sau đúng 0.1 giây. Sau reaction, còn giữ nút và stamina dương thì quay về `saber_defense`.

Defense vẫn bảo vệ các đòn tiếp theo trong recoil nếu còn stamina và đòn mới qua được kiểm tra i-frame. Đòn Guard có HP loss thường tạo i-frame **0.2 giây**, nên contact trong thời gian này có thể bị bỏ qua; không diễn giải thành mọi overlap frame đều phải trừ stamina. Hit mới hợp lệ có thể bắt đầu lại recoil budget. Thả Defense bình thường sẽ hủy recoil còn lại.

Nếu damage đã Guard chạm threshold HP thật, phản ứng threshold ưu tiên hơn normal Guard pose; nhánh này dùng hướng bật lùi ngang để không hất lên khi đỡ đòn.

## 5. Deflect đủ stamina và slow motion

Deflect hợp lệ trong cửa sổ đầu trừ **20 stamina**, không trừ HP và không tạo debuff/tiêu marker threshold. Giữ pose `saber_deflect` trong pulse.

Tuning scene hiện tại: **time scale 0.5x, thời lượng 0.45 giây thực**. Default trong script là 0.6x / 0.2 giây; chỉ đọc default sẽ không phản ánh nhân vật đang được lưu.

DeflectSlowMotion lưu scale trước pulse, đặt `Engine.time_scale`, và dùng timer `ignore_time_scale = true` để thời lượng pulse không kéo dài do chính hiệu ứng slow motion. Hết pulse hoặc node rời tree thì khôi phục scale đã lưu. Token generation ngăn callback cũ kết thúc nhầm pulse mới khi một pulse được khởi động lại.

Physics/FSM/animation dùng thời gian game sẽ cùng chậm; timer hồi stamina/stagger dùng thời gian game cũng bị kéo theo. Không tuyên bố rằng âm thanh, shader dùng đồng hồ thực hoặc một hệ thống tự bỏ qua time scale đều được giảm đúng tốc độ chỉ bằng thay Engine.time_scale. Không có thay đổi audio trong phần triển khai này.

Thả Defense trong lúc pulse đang chạy kết thúc khả năng bảo vệ nhưng vẫn giữ pose Deflect đến hết pulse. Khi hết pulse: nếu còn Defense, còn stamina và vẫn giữ nút thì về pose phù hợp; nếu không thì về ready. External lock/stun/rest/contact được kiểm tra để callback pulse không tự mở khóa hoặc phục hồi sai state.

Deflect không tự gây stagger hoặc ngắt đòn của enemy. Enemy giữ FSM của nó và đánh dấu contact đã xử lý cho swing hiện tại. Muốn enemy có phản ứng sau Deflect là một yêu cầu gameplay khác, chưa triển khai.

## 6. Stamina: chi phí, hồi phục và các trường hợp biên

### 6.1. Dữ liệu và hồi phục

- Max stamina cơ bản: **100**, được PlayerProgress quản lý; nâng cấp stamina hiện thêm **15** mỗi điểm nâng cấp tương ứng.
- Dash / Guard / Deflect: **20** cho mỗi hành động hoặc hit được chấp nhận; có export riêng để chỉnh độc lập.
- Tốc độ hồi: **28 stamina / giây game**.
- **Thời gian chờ hồi đang lưu trong scene: 1.0 giây.** Default Player/StatsComponent vẫn là **1.5 giây**, đồng thời là giá trị yêu cầu/kiểm thử ban đầu. Scene override 1.0 được giữ nguyên.
- Không thêm chi phí attack. Defense không nhận đòn không tiêu stamina.

`_configure_stamina()` lấy export Player và truyền vào StatsComponent qua HUD khi `_ready()`. Muốn thay cấu hình đang lưu, sửa Inspector, save và chạy lại; chỉnh default StatsComponent đơn lẻ có thể bị cấu hình Player ghi đè.

Tiêu stamina đặt lại thời gian chờ hồi. Khi ATTACK, bất kỳ state DEFENSE hoặc pulse Deflect còn active, `blocks_stamina_regeneration()` chặn hồi và reset delay. Sau khi hết các hoạt động đó, chờ đủ delay rồi mới hồi dần; nếu một delta vượt qua mốc delay thì chỉ phần thời gian dư được dùng để hồi. Stamina không vượt max hoặc xuống âm.

Hồi phục độc lập với cờ HUD `in_combat`/thời gian fade. Thanh xanh cập nhật ngay khi tiêu và khi hồi. DASH/STAGGER/READY không nằm trong danh sách chặn hồi của hàm hiện tại; chúng vẫn có thể đang chờ delay do lần tiêu hoặc trạng thái trước đó.

### 6.2. Còn dương nhưng thiếu chi phí — ví dụ còn 10, chi phí 20

- **Dash:** vẫn được thực hiện, tiêu 10 còn lại, không có trừng phạt stagger bổ sung. Quy tắc cooldown/aerial dash thông thường vẫn áp dụng.
- **Deflect:** tiêu 10 còn lại, HP không mất, chuyển ngay sang phản ứng stagger đầy đủ và i-frame chung. Không bắt đầu pulse; nếu pulse cũ còn active thì hủy để hiện stagger ngay.
- **Guard:** tiêu 10 còn lại, nhận damage sau giảm Guard cơ bản 50% cùng modifier hiện có, rồi phản ứng stagger giống trường hợp Deflect thiếu stamina.

Thiếu stamina không kích hoạt threshold HP/debuff mới. Guard thiếu stamina dùng `skip_stagger_thresholds = true`; HP có thể đi qua 66%/33% mà không tiêu marker. Nếu một floor lock từ threshold trước đang còn hiệu lực, damage trực tiếp vẫn tôn trọng floor lock đó.

### 6.3. Vừa đủ chi phí — ví dụ còn 20

Hit đầu vẫn là Guard/Deflect đủ stamina, không nhận hình phạt thiếu stamina chỉ vì sau khi trừ còn 0. Normal Guard hoàn tất recoil/pose, Deflect hoàn tất pulse/pose; **bảo vệ kết thúc ngay ở 0**. Đòn tiếp theo không được Guard/Deflect, kể cả nếu xảy ra trước physics tick tiếp theo; i-frame hiện có vẫn có thể từ chối nhận đòn.

Đây là phân biệt giữa “phản ứng của lần đỡ đã được thanh toán” và “đang còn quyền Defense”. Cờ `is_guarding` có thể false trong khi pose phản ứng vừa trả chi phí vẫn còn phát.

### 6.4. Stamina bằng 0

- Chặn bắt đầu Dash và Defense ở cả input và helper điều phối.
- Dash bị từ chối không tiêu cooldown, allowance air dash, i-frame hoặc reset delay hồi stamina.
- Defense đang giữ hết bảo vệ; không Guard/Deflect được đòn mới.
- Nút Defense bị từ chối không giữ state DEFENSE để chặn hồi. Giữ nút sau khi hết stamina cũng không tự tái bắt đầu Defense khi hồi được stamina; thả và nhấn lại.
- Di chuyển/nhảy/attack vẫn có thể thực hiện theo quyền state thông thường; bằng 0 không tự tạo một trạng thái khóa toàn bộ nhân vật.

## 7. Stagger threshold 66% / 33% HP

### 7.1. Điều kiện vượt mốc và khóa HP

StatsComponent dùng `STAGGER_THRESHOLD_FRACS = [0.66, 0.33]`. Floor của mỗi tier là `round(max_hp × fraction)`; với max HP 100 là 66 và 33, không phải phân số chính xác 2/3 và 1/3.

Một marker còn sẵn kích hoạt khi **HP trước đòn > floor** và **HP dự kiến sau đòn ≤ floor**. Khi kích hoạt:

1. HP dừng ở floor, bỏ phần damage trực tiếp vượt quá mốc trong hit đó.
2. Marker bị đánh dấu đã dùng.
3. Đặt floor lock **1.0 giây game**.
4. Chọn debuff ngẫu nhiên.
5. Player thực hiện phản ứng stagger nếu kết quả không yêu cầu bỏ qua phản ứng.

Ví dụ HP 70, nhận 20 damage: dừng 66 và dùng marker 66. Trong lúc khóa, damage trực tiếp không đẩy HP dưới floor 66. Sau lock, HP có thể giảm tiếp; marker đã dùng không kích hoạt lại cho đến khi được phục hồi. Một hit lớn chỉ kích hoạt tier đầu tiên tìm được và dừng tại đó, không tiêu cả hai marker cùng hit.

Ngoại lệ “đang bleeding thì bỏ stagger khi nhận đòn trực tiếp” đã được loại bỏ: có bleeding vẫn chạm threshold, bật lùi/stun và áp hiệu ứng theo cùng logic. `skip_player_stagger` của kết quả crossing hiện không được đặt true vì bleeding.

### 7.2. Bleed tick đi ngoài luồng threshold

Theo lựa chọn người dùng, tick bleeding tiếp tục bỏ qua threshold. `_process_bleeding()` đi qua `_apply_raw_hp_loss()` thay vì `PlayableAdel.take_damage()` / `StatsComponent.apply_damage()`, nên không gọi Guard/Deflect và không tiêu stamina.

Đường raw HP hiện cũng không kiểm tra DamageComponent i-frame hoặc floor lock của damage trực tiếp; bleed có thể làm HP xuống dưới mốc trong thời gian các cơ chế đó còn active. Đây là mô tả source đang có, không phải quy tắc mới được thêm khi viết báo cáo.

Nếu DOT đã làm HP ≤ một mốc chưa dùng, hit trực tiếp tiếp theo không tự kích hoạt ngược mốc đó vì điều kiện yêu cầu HP trước hit > floor. Marker có thể vẫn hiện ready; cần hồi HP lên trên mốc rồi crossing lại hoặc thay luật trong một yêu cầu sau này nếu muốn hành vi khác.

### 7.3. Phục hồi marker

`restore_stagger_thresholds()` phục hồi cả hai marker và dọn floor lock. Full heal phục hồi HP/stamina, marker, flask và debuff theo model hiện tại. Soul Flask phục hồi một marker đã dùng; vòng lặp ưu tiên marker 33 trước 66, đồng thời có luật hồi HP/chữa debuff riêng.

## 8. Phản ứng stagger vật lý, animation và i-frame

Threshold thật và thiếu stamina gọi cùng `DamageComponent.apply_stagger()` với cấu hình chung:

- Ngân sách bật lùi ngang: **200 đơn vị** theo scene.
- Push: **0.3 giây game**.
- Stun sau push: **0.45 giây game**.
- I-frame cấu hình tổng: **1.0 giây game** từ đầu push, nằm trong `STAGGER_INVULN_SEC`.
- `saber_stagger` frame **0** khi KNOCKBACK, frame **1** khi STUN; hồi về `saber_ready` frame **2**.

Push chạy qua `move_and_slide()` và ngân sách quãng đường; tường/địa hình có thể cắt bớt travel. Threshold không Guard có thể nhận vận tốc dọc theo hướng hit do `compute_knockback_dir()`; Guard-triggered threshold và phản ứng thiếu stamina được truyền hướng ngang, không tạo cú hất lên. Khoảng cách cấu hình là ngân sách ngang, không bảo đảm tổng độ dài quỹ đạo 2D luôn bằng đúng 200.

Khi kết thúc push, chuyển STUN và dừng vận tốc ngang. Hết stun thì trả quyền điều khiển qua READY. Với tuning 0.3 + 0.45, khoảng **0.25 giây i-frame còn lại** kéo dài sau hồi điều khiển. Nếu tổng push + stun dài hơn i-frame cấu hình, invulnerability vẫn ít nhất bao phủ hết stun. Sai số tick/timer có thể khiến thời điểm quan sát lệch một bước xử lý; không coi con số cấu hình là đo bảo đảm tới từng millisecond.

Floor lock HP 1.0 giây và iframe 1.0 giây là hai timer độc lập dù hiện có cùng giá trị. Thay một constant không tự thay constant kia.

Pulse Deflect là hiệu ứng độc lập: trong trường hợp threshold vật lý xuất hiện khi một pulse trước vẫn còn, pose Deflect có thể được giữ đến hết pulse rồi hiển thị frame stagger phù hợp với pha hiện tại. Phản ứng **thiếu stamina hủy pulse trước khi stagger**, nên không bị pulse che pose tức thời.

## 9. Debuff từ threshold và icon HUD

### 9.1. Chọn hiệu ứng

Mỗi threshold thật hiện chọn bleeding hoặc fracture theo xác suất **50% / 50%**. Đây là lựa chọn mỗi lần, không luân phiên cố định. Thiếu stamina không gọi lựa chọn này. Không có debuff thứ ba trong nhánh random threshold hiện tại.

### 9.2. Bleeding

- Tick interval: **1.0 giây game**.
- Damage tick cấp 1: **3 HP**; cấp 2: **6 HP**.
- Random threshold gọi `_apply_bleeding(1)`; áp lại dùng `max(current, requested)`, không tự cộng một cấp mỗi lần. Cấp 2 được hỗ trợ trong model nhưng không tự sinh chỉ vì nhận bleeding cấp 1 lần nữa.
- Soul Flask xóa bleeding và timer tick; full heal/clear debuffs cũng xóa.
- Icon: `res://asset/UI/Menu screen/Bleed.png`.

### 9.3. Fracture — phần hiện có, chưa coi là hoàn thiện thiết kế

Áp fracture cộng một cấp, clamp tối đa **3**. Modifier hiện có:

- Cấp 1: damage nhận ×1.2, damage gây ×0.85; chưa giảm tốc di chuyển/tấn công.
- Cấp 2: damage nhận ×1.4, damage gây ×0.80, tốc di chuyển ×0.72, tốc tấn công ×0.75.
- Cấp 3: damage nhận ×1.6, damage gây ×0.65, tốc di chuyển ×0.72, tốc tấn công ×0.75.
- Soul Flask giảm một cấp fracture; full heal/clear debuffs xóa toàn bộ.
- Icon: `res://asset/UI/Menu screen/fracture.png`.

Các hệ số damage gây/tốc tấn công là dữ liệu/getter model; không suy diễn mọi đường gây damage hoặc mọi animation đều đã sử dụng getter. Saber hiện đã đọc WeaponData.damage, nhưng chưa tự nối thêm các hệ số damage gây của Fracture; jump attack có damage export riêng. Theo phạm vi đã thống nhất, không tự hoàn thiện thêm fracture trong các lượt chỉnh animation/icon/stamina hoặc lượt viết báo cáo này.

HUD đồng bộ icon qua `sync_status_icons()` và status slots; marker threshold ready trắng, đã dùng mờ/xám. Thanh xanh phản ánh stamina, không phải một thanh stagger riêng.

## 10. Animation recovery và các lỗi đã sửa

### 10.1. Ready chỉ frame cuối, vẫn ngắt được

Sau Defense/Guard/Deflect/Stagger, `_play_ready(true)` dùng biến thể `saber_ready` **chỉ frame index 2**, thời lượng **1.0 giây game**, không loop. READY nằm trong LOCOMOTION nên có thể bị movement/jump/attack/Defense/Dash hợp lệ ngắt; không tạo khóa hành động một giây.

AdelAnimationComponent nhân bản AnimationLibrary theo Player instance, giữ animation ready gốc và tạo variant riêng. Texture/hframes được áp trước track frame=2. Không sửa trực tiếp asset animation nguồn `res://asset/Character/Adel/adel spine action use.tscn`; ready sau combo bình thường vẫn có thể dùng bản gốc.

### 10.2. Kẹt attack khi animation bị stagger ngắt

Trường hợp đã gặp: spam attack rồi bị stagger, clip attack không phát tới cuối nên callback hoàn tất không dọn state. HFSM hiện dọn queue, combat state, interrupt token và cả Saber/AttackHitbox khi thoát ATTACK. Callback cũ phải qua token/state check; không được bật lại state đã bị ngắt. Sau KNOCKBACK → STUN → READY, input attack mới có thể bắt đầu combo.

### 10.3. Timer trên Player đã rời tree khi chết

Damage từ enemy có thể làm HUD gọi respawn đồng bộ, đổi scene hoặc loại Player khỏi tree trước khi Player tạo i-frame. Code hiện kiểm tra kết quả died và vòng đời body trước bước tiếp; DamageComponent kiểm tra body hợp lệ, inside tree, chưa queued deletion trước get_tree/timer và trong callback. UI xử lý chết do bleeding cũng return sau respawn.

Các bảo vệ này sửa đường lỗi `get_tree() null / create_timer on null` đã ghi nhận. Không suy ra mọi callback trong toàn project đã được kiểm toán hoặc mọi native engine/addon crash đều được xử lý.

## 11. Vị trí điều chỉnh

Mở [playable_adel.tscn](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/adel/playable_adel.tscn>), chọn root **PlayableAdel**, xem Inspector:

- **Defense → Deflect Window:** 0.2 giây game.
- **Defense → Defense Hit Pose Duration:** 0.2 giây game; Guard giữ lâu hơn nếu push còn active.
- **Defense → Deflect Slow Motion Scale / Duration:** đang lưu 0.5x / 0.45 giây thực; default 0.6x / 0.2.
- **Guard Knockback → Distance / Duration:** đang lưu 20 / 0.1 giây game; default 50 / 0.2.
- **Stagger Threshold → Stagger Knockback Distance:** đang lưu 200; default 72.
- **Stagger Threshold → Stagger Knockback Duration / Stagger Stun Duration:** 0.3 / 0.45 giây game. Dùng chung threshold thật và thiếu stamina, không còn bộ Stamina Exhaustion export riêng.
- **Stamina → Dash / Guard / Deflect Stamina Cost:** mỗi loại 20, chỉnh độc lập.
- **Stamina → Stamina Regen Delay:** **scene 1.0 giây**, default 1.5.
- **Stamina → Stamina Regen Per Second:** 28.

Thông số chưa có export trực tiếp trên Player:

- I-frame stagger chung: `damage_component.gd` → `STAGGER_INVULN_SEC = 1.0`.
- I-frame hit thường: `damage_component.gd` → `HIT_INVULN_SEC = 0.2`.
- Mốc HP và thời gian floor lock: `stats_component.gd` → `STAGGER_THRESHOLD_FRACS`, `STAGGER_LOCK_DURATION`.
- Giảm damage Guard: `StatsComponent.guard_damage_reduction`, mặc định 0.5, có facade trên HUD; không phải export riêng đang lưu ở root PlayableAdel.
- Max stamina cơ bản/nâng cấp: `player_progress.gd` → `BASE_MAX_STAMINA`, `STAMINA_PER_UPGRADE`.
- Bleed/fracture: các constant/helper trong StatsComponent; icon preload trong `status_icon_slot.gd`.
- Pose nguồn: mở `adel spine action use.tscn` → AnimationPlayer → saber_defense / saber_guard / saber_deflect / saber_stagger. Variant frame-2 ready do animation component tạo riêng lúc chạy.
- Nút Defense: Project Settings → Input Map → action `guard and deflect`.

Override trên instance trong map có thể ghi đè wrapper Player; default script không thắng override scene/instance. Save và restart gameplay để nhận cấu hình stamina/damage component được tiêm khi ready. Chỉnh Remote Inspector không tự lưu vào file.

## 12. Kiểm thử đã có và giới hạn

Những lượt triển khai trước đã thực sự chạy Godot 4.7 trong bản sao dùng dữ liệu save riêng. Lượt sửa zero-stamina gần nhất đạt **369 checks headless và 94 checks có render**, gồm:

- Guard/stamina: 94; Defense: 59; Deflect slow motion: 25.
- Ready recovery: 21; Adel HFSM: 31.
- Leap/Defense qua enemy: 79; stagger/attack matrix: 40; death/respawn: 20.

Các nhóm trên là 369 assertion được báo bởi suite; render chạy lại suite 94, không phải thêm 94 case độc lập mới. Kiểm tra có input/physics/Area2D thật và có fixture gọi method/đặt state để kiểm tra biên. Không mô tả tất cả là chơi thủ công.

Đã kiểm tra chi phí 20, partial 10→0, đúng 20→0, chặn Defense/Dash ở 0, hit trước physics tick tiếp theo, giữ reaction đã trả chi phí, hai frame stagger, hồi quyền attack, regen, release/pulse và lethal Guard respawn. Log và ảnh nằm trong gói `Zero-stamina-verification.zip` của workspace trước đó.

**Giới hạn phiên bản kiểm thử:** các bài timing hồi stamina trước đó được chạy với scene delay **1.5 giây**. Scene được đọc khi tách báo cáo này lưu **1.0 giây**. Lượt này chỉ đối chiếu source/tài liệu, không chạy lại các assertion timing cho tuning 1.0; không dùng số test cũ để tuyên bố giá trị mới đã được runtime nghiệm thu.

Test được lưu trong repo gồm `tests/adel/guard_stamina_validation.tscn`, `ready_recovery_validation.tscn`, `adel_hfsm_validation.tscn` và `tests/enemy/leap_hitbox_validation.tscn`. Guard/stamina suite ghi checkpoint và có gate yêu cầu bản sao với custom user directory có prefix **CodexGuardStamina**. Không chạy suite này lên save thật để kiểm thử.

Chưa nghiệm thu mọi map/build, mọi interaction timing hoặc cân bằng gameplay. Chưa đánh giá xung đột khi nhiều chủ thể cùng thay global time scale. Cảnh báo rig/legacy/addon đã ghi nhận không được giải quyết chỉ bằng các sửa phòng thủ này.

## 13. Những phần còn mở

Các mục sau là đề xuất để chọn scope sau, không tự triển khai trong lượt báo cáo:

1. Cập nhật assertion thời gian hồi theo tuning scene hoặc chuẩn hóa fixture cấu hình rõ ràng, rồi chạy lại nếu chọn 1.0 giây làm giá trị nghiệm thu.
2. Chốt việc bleeding tick tiếp tục bỏ qua cả i-frame/floor lock, và cách hiển thị marker nếu DOT đã vượt mốc còn ready.
3. Hoàn thiện fracture và kiểm tra từng modifier thực sự được đường damage/animation nào sử dụng.
4. Quyết định enemy có bị phản ứng, mất nhịp hoặc mở cơ hội tấn công sau Deflect hay không; hiện chưa có phản ứng đó.
5. Nếu nhiều actor có slow motion, thiết kế một chủ sở hữu/điều phối time scale chung; mỗi pulse hiện lưu/khôi phục scale riêng.
6. Nếu thay push/stun dài hơn, kiểm tra riêng iframe và floor lock, không chỉ căn pose bằng mắt.

## 14. Source đối chiếu và liên kết báo cáo

- [Luồng nhận damage Player](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/adel/playable_adel.gd:271>).
- [DefenseComponent](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/adel/components/defense_component.gd>), [HFSM](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/adel/components/adel_state_machine.gd>).
- [DamageComponent](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/adel/components/damage_component.gd>), [slow motion](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/adel/components/deflect_slow_motion.gd>), [animation component](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/adel/components/adel_animation_component.gd>).
- [StatsComponent](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/stats_component.gd>), [HUD facade](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/ui.gd>), [icon](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/status_icon_slot.gd>), [PlayerProgress](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/Mechanic/player_progress.gd>).
- [Báo cáo enemy](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/Bao_cao_ky_thuat/enemy_technical_report.md>): AI, rig, collider, hitbox, damage và EXP của enemy.

`guard_def.md` và `guard_stamina.md` được giữ lại làm tài liệu ở các thời điểm trước, không xóa legacy báo cáo. Các giá trị cũ như delay 1.5 hoặc bản kế hoạch animation ban đầu không thay thế source/scene hiện tại. Báo cáo độc lập này là bản tổng hợp được đối chiếu lại tại ngày lập; tiếp tục cập nhật khi gameplay thay đổi.

Bổ sung damage Player: xem `Context/Bao_cao_ky_thuat/combat_damage_tuning.md` cho combo 20/24, jump attack và vị trí chỉnh HP/enemy skill damage. Không thêm chi phí stamina cho attack trong thay đổi đó.
