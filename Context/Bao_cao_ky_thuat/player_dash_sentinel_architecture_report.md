# Player: Sentinel drain, dash và đánh giá kiến trúc

> Cập nhật sau refactor 16/10/2026: đã sửa ownership i-frame, chuyển stats/đồng hồ sang Player, gom dash vào module và cho defense bắt đầu ngay sau skid, không chờ cooldown. Xem [player_runtime_refactor_report.md](player_runtime_refactor_report.md). Nội dung và kết quả trước đó bên dưới là snapshot lịch sử; i-frame bug đã nêu trong snapshot nay đã có regression và được sửa.

Ngày kiểm tra: 16/10/2026. Nguồn: code và scene đang lưu trong repository `D:/Godot Project/soujourn--echoes-of-the-soul`, không lấy default script để thay cho override trong scene. Phạm vi đánh giá là Player/combat/Sentinel và đường nhận damage liên quan, không phải audit toàn bộ game hay benchmark hiệu năng.

## Phần đã thực hiện

Thêm rút máu vào Sentinel đang thử nghiệm bằng T/R/Y. T cộng 30 ulti, R khi đầy tiêu thanh và kích hoạt module trên Player, Y là thoát debug ngay. Standalone HUD preview vẫn chỉ đổi hình minh họa; không chạy gameplay hay rút máu.

- Tốc độ mặc định: **2% HP tối đa mỗi giây game**. Ví dụ max HP 100: 2 HP/giây; max HP 250: 5 HP/giây, bất kể HP hiện tại.
- Dùng delta gốc của physics trước `CombatTime.actor_delta`. Vì vậy pause dừng rút, global slow motion/hit-stop giảm tốc rút; kể cả khi Q được miễn slow motion cho Player, rút máu vẫn theo thời gian thế giới.
- HP hiện dùng số nguyên: module giữ phần lẻ, chỉ cập nhật HP khi tích đủ một điểm. Với 100 max HP và tốc độ mặc định, thanh mất một HP mỗi 0,5 giây game. Không làm tròn lên mỗi frame.
- Tự rút không qua đường nhận đòn, không bị guard/deflect/i-frame/Toughness hoặc HP threshold lock chặn. Không kích hoạt marker stagger, debuff, camera impact hay i-frame.
- Tự rút dừng ở **1 HP**, không hồi sinh HP đã bằng 0. Sát thương bình thường vẫn đi qua đường damage hiện có và có thể giết Player.
- Tới 1 HP trong đòn đánh, jump attack, Q, dash/skid, stagger, contact reaction, pickup hoặc rest: bật `exit_pending`, xóa buffer đòn kế, dừng rút tiếp và đợi trạng thái đang chạy kết thúc. Không nhận combo/Q/dash/pickup/campfire mới trong lúc chờ. Chuỗi Q đang chạy vẫn tự thực hiện các pha còn lại; giữ Q không kéo dài vô hạn do đã có auto-release.
- Locomotion/ready hoặc defense: thoát ngay, không chờ giữ chuột phải kết thúc. Cooldown dash không phải hành động nên không trì hoãn thoát. HP không được hoàn lại khi thoát. Y debug có thể bỏ qua chờ.

### Vị trí chỉnh

Mở `res://scenes/adel/playable_adel.tscn`, chọn node gốc **PlayableAdel → Dark Sentinel → Sentinel Hp Drain Percent**. Giá trị **2.0** nghĩa là 2% max HP mỗi giây game; 0 tắt rút máu phục vụ thử nghiệm. Default nằm gần đầu `res://scenes/adel/playable_adel.gd`.

Logic vòng đời/rút máu/chờ thoát nằm tại `res://scenes/adel/components/dark_sentinel_state.gd`. Phép trừ HP không gây chết nằm trong `StatsComponent.drain_hp_nonlethal`; HUD chỉ chuyển lời gọi và đồng bộ hiển thị. Player sở hữu module và tick bằng thời gian game; mode Sentinel chạy song song với action HFSM.

### Giới hạn hiện tại

Đây là bước **rút máu + chờ thoát** trên nền HUD thử nghiệm. Chưa triển khai full Sentinel: tự hồi đầy HP khi vào, đổi/cố định vũ khí, miễn stagger thực tế, cấm bình máu, xóa debuff, skill Sentinel Q/E/1–4 và chi phí, Sharpness/Toughness hay tích ulti từ combat. Q hiện vẫn là skill Saber cũ và vẫn có i-frame lúc lao; không nhầm với Q xích Sentinel đã được duyệt là không có i-frame. Các luật này vẫn được lưu trong `dark_sentinel_hud_report.md` cho bước tiếp theo.

R/Y hiện là phím debug, không chạy trong bản release. UI preview gọi `set_sentinel_active` chỉ đổi giao diện; gameplay phải gọi `Player.begin_sentinel/end_sentinel`. Controller chưa phải hệ thống chuyển dạng/đổi vũ khí hoàn chỉnh.

## Dash hiện hoạt động như thế nào

### Điều kiện và đầu vào

- Phím `dodge` hiện gắn Shift. Đọc `just_pressed`, không tự lặp khi giữ và chưa có buffer dash trong cooldown.
- Trên đất phải có hướng trái/phải. Trên không không cần giữ hướng: dùng hướng đang nhìn nếu không có A/D.
- Cần stamina > 0; mặc định tốn 20. Nếu chỉ còn 10 vẫn dash và tiêu 10; bằng 0 không dash.
- Thường bắt đầu từ locomotion/ready; jump-attack land sau mốc mở khóa 0,3 giây cũng có thể vào đường locomotion để dash. Không phải cancel phổ quát cho mọi attack/defense/stagger/Q.
- Quyền air dash được reset khi nhảy hoặc tiếp đất. **Double jump cũng phát `jumped` và reset air dash**, nên không phải giới hạn tuyệt đối một air dash cho cả lần rời đất. Cần chốt lại thiết kế nếu muốn cấm dash → double jump → dash.

### Trình tự trên đất

1. `DASH_ACTIVE`: **0,30 giây game**, animation `dash`, bật i-frame, khóa vận tốc Y bằng 0. Vận tốc X ban đầu `140 × 20 = 2800 px/s`, Tween QUAD/EASE_OUT giảm dần về 140 px/s. Khi hết pha, code đặt X về 0.
2. `DASH_SKID`: **0,20 giây game**, animation `dash skid`. I-frame đã tắt; Y vẫn bị đặt 0 bởi cùng hàm physics dash. Ghost trail còn chạy đến khi rời toàn bộ DASH.
3. Rời DASH mới bắt đầu Timer `DodgeCooldown`: **0,06 giây**, là giá trị hiện đang lưu trong scene. Trong cooldown có thể trở lại locomotion; dash chưa được cấp lại.

Tổng khoảng cách thời gian tối thiểu giữa hai lần bắt đầu dash đất là khoảng **0,56 giây game**, cộng sai số tick. Dash không dùng một biến khoảng cách cố định; quãng đường phụ thuộc đường tốc độ, sampling physics/Tween và va chạm. Không coi phép tích phân liên tục là quãng đường runtime đã đo.

Dash bắt đầu trên không dùng `dash_air`, chỉ có ACTIVE 0,30 giây rồi cooldown 0,06, không có SKID: khoảng **0,36 giây game**, nhưng còn phải thỏa quyền air dash. Việc bỏ SKID dựa trên trạng thái lúc bắt đầu, không dựa vào vừa đáp đất trong dash hay chưa.

Giữ defense trong dash/cooldown: giữ yêu cầu chờ, hết cả DASH và cooldown mới vào defense nếu nút vẫn giữ và stamina > 0. Thả nút hoặc cleanup input sẽ hủy. Cửa sổ deflect tính từ lần nhấn ban đầu, không được cấp lại khi defense chờ bắt đầu.

Body Player và enemy luôn được cho đi xuyên nhau, cả ngoài dash. Hitbox Area2D vẫn hoạt động; đi xuyên thân quái không đồng nghĩa đang miễn damage.

### I-frame: ý định và hành vi đã xác minh

- Theo code dash: chỉ ACTIVE **0,30 giây**, không có i-frame trong SKID 0,20 hoặc cooldown 0,06.
- Nhận damage thường có cửa sổ **0,20 giây** riêng. Stagger nhắm tới **1,00 giây** bảo vệ; `is_stunned` cũng chặn nhận đòn. Saber Q miễn damage trong `SKILL_DASH`, các pha tụ/impact/recovery không mặc định miễn.
- **Đã tái hiện lỗi hiện có:** gọi miễn đòn thường 0,10 giây rồi bắt đầu dash; sau khoảng 0,13 giây vẫn ở `DASH_ACTIVE` nhưng `damage.is_invulnerable == false` và `can_take_damage() == true`. Timer cũ gọi `_end_invulnerability()` và tắt cờ đang được dash dùng. Trường hợp chơi tương ứng là vừa chịu đòn thường, rồi dash trong cửa sổ miễn đòn còn lại. Số 0,10 trong phép thử giúp tái hiện gọn; duration đòn thường thật là 0,20.
- Vì vậy 0,30 giây là **thời lượng dự kiến**, chưa phải bảo đảm trong mọi tình huống chồng nguồn. Không sửa ownership i-frame trong lần thêm Sentinel này. Log headless và có render đều ghi `DASH IFRAME REVIEW ... = true`; đây là bằng chứng lỗi, không phải kiểm tra tính đúng của i-frame.

### Chỗ chỉnh dash hiện tại

- Cooldown: `playable_adel.tscn → DodgeCooldown → Wait Time`, hiện **0.06**.
- Chi phí: node PlayableAdel → Stamina → Dash Stamina Cost, mặc định **20**.
- Thời gian ACTIVE/SKID và hệ số tốc độ: `scenes/adel/components/dash_component.gd`, các hằng `DASH_TWEEN_DURATION=0.3`, `DASH_SKID_DURATION=0.2`, `DASH_SPEED_MULTIPLIER=20`.
- Áp vận tốc, animation và bật/tắt i-frame: `playable_adel.gd::_perform_dash`, `_physics_dash`, `_exit_player_state`.
- Không nên đổi WALK_SPEED chỉ để chỉnh dash vì nó thay cả tốc độ đi bộ.

## Đánh giá kiến trúc và code

**Kết luận:** đã có HFSM thật và nhiều module chuyên trách, đủ tốt để tiếp tục prototype có kiểm thử. Chưa đủ tách rời để mở rộng nhiều vũ khí và full Sentinel mà không tăng rủi ro. Không thể kết luận game đã production-ready từ phạm vi kiểm tra này.

### Điểm đang làm tốt

- `AdelStateMachine` có cây parent, transition theo tổ tiên chung, entry/exit cleanup; rời ATTACK đóng hitbox và buffer, rời SKILL dọn exemption/time effects. Đây là quyền sở hữu hành động có cấu trúc, không chỉ đổi tên enum.
- Locomotion, combat, damage, defense, dash, animation, Saber Q đã có nơi quản lý riêng. `StatsComponent` không phụ thuộc SceneTree nên kiểm thử model được.
- `CombatTime` làm đầu mối global time scale và các lane hiệu ứng; không để từng skill tự hoàn nguyên time scale tùy ý.
- Enemy mỗi swing ghi nhận mục tiêu đã tiếp xúc, kể cả đòn bị dash/guard từ chối, tránh một swing trừ HP nhiều lần. Code có kiểm tra body còn sống trong tree sau những đường damage có thể respawn ngay.
- Runtime có test input, animation, pause, slow motion và HUD thật trên Godot; không chỉ kiểm tra cú pháp.

### Ưu tiên cải thiện

1. **Cao — sửa quyền sở hữu i-frame trước.** `DamageComponent.start_invulnerability/_end_invulnerability`, dash và contact reaction cùng ghi một bool. Cần nguồn miễn damage riêng: DASH, HIT, STAGGER, SKILL; nhận damage khi không còn nguồn nào. Mỗi nguồn có generation/token hoặc thời điểm hết hạn để callback cũ chỉ kết thúc đúng quyền của mình. Bổ sung regression: timer HIT hết giữa dash, hết dash vẫn còn STAGGER/HIT, ngắt hành động, respawn. Phải sửa cả nơi ghi cờ; chỉ thêm token cho một timeout chưa đủ.
2. **Cao — chuyển quyền sở hữu stats khỏi HUD.** Hiện Player tìm HUD để đọc/spend stamina và nhận damage; HUD giữ `_stats` và tick bleed/regen. Thay HUD, tháo HUD hoặc tái cấu trúc giao diện có thể đổi gameplay. Nên Player sở hữu Stats và vòng tick; HUD subscribe thay đổi. Giữ facade tạm trong quá trình chuyển để SaveManager/map chưa bị vỡ. Module Sentinel mới đã tách vòng đời khỏi HUD nhưng vẫn dùng adapter hiện có để tránh refactor rộng trong một tính năng nhỏ.
3. **Vừa — gom toàn bộ luật dash trong một module có cấu hình.** DashComponent hiện giữ eligibility/cooldown, Player giữ vận tốc/Tween/timer/iframe/cleanup. Cần một tick physics quản lý phase và chuyển động, xuất kết quả cho animation/VFX; `dash_speed`, `active_duration`, `skid_duration`, `cooldown`, iframe window nên là dữ liệu chỉnh được. Giữ quãng đường ổn định khi FPS khác nhau và thêm test va tường/ra mép/tiếp đất/slow motion. Không tự đổi feel hoặc thông số hiện tại khi chưa duyệt.
4. **Vừa — giảm việc các module đọc/ghi nội bộ Player.** SaberWeaponSkill và HFSM gọi nhiều hàm `_...` và biết các module anh em. Khi thêm Sentinel, nên có interface rõ cho quyền bắt đầu hành động, mở/đóng damage window, kết thúc hoặc ngắt hành động và yêu cầu hiệu ứng. Weapon/form là dữ liệu/hành vi riêng; không sao chép cả Player hoặc cả cây HFSM cho mỗi vũ khí.
5. **Vừa — củng cố test theo hành vi và fixture.** Một số test cũ dựa vào giá trị Inspector mặc định trong khi người dùng đang chỉnh scene. Test luật nên đặt fixture của nó, còn test tích hợp đọc override thật. Tách kiểm tra gameplay đúng khỏi script chẩn đoán lỗi đã biết. Chưa benchmark số lượng lớn enemy, save toàn game, scene streaming hay mọi độ phân giải nên không đưa kết luận hiệu năng tổng thể.

## Kiểm tra lần này

Godot 4.7 stable thực sự đã chạy, dùng bản sao project có thư mục save riêng. Kết quả cuối và danh sách file triển khai nằm trong manifest kiểm chứng tại workspace.

- `sentinel_drain_validation`: 35 check headless và 35 check có render, gồm rate/phần lẻ/max HP, nonlethal, không trigger threshold, pending combo/Q/dash/skid, defense, phím T/R/Y, pause và world slow motion khi Player có exemption.
- `dash_defense_validation`: 24 check headless với cooldown scene thật 0,06.
- `combat_feel_validation`: 106 check headless, hồi quy combo/defense/stagger/stamina.
- `sentinel_debug_validation`: 23 check headless. Fixture đặt rate=0 để kiểm tra input và giao diện độc lập với timing rút máu; không đổi cấu hình scene chơi thật.
- `sentinel_hud_validation`: 39 check có render cho HUD, shader, kích thước và preview.

Tổng **262 check chức năng đạt**. Ngoài ra có hai lần tái hiện lỗi ownership i-frame (headless và có render); lỗi đó được báo cáo, chưa sửa. Không có SCRIPT ERROR/ERROR trong các log kiểm tra cuối. Chưa đo cảm giác gameplay bằng phiên chơi dài hoặc xác minh full bộ skill Sentinel vì chưa triển khai.

Giữ nguyên scene/rig/asset/audio, các thông số người dùng đang chỉnh và prototype cũ. Không sửa save chính, không commit hoặc push trong lần này.
