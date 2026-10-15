# Refactor Player: i-frame, stats và dash

Ngày: 16/10/2026. Thực hiện theo ba đề xuất đã được duyệt và yêu cầu defense bắt đầu ngay sau skid, không chờ cooldown dash. Dựa trên repo và scene thực tế tại thời điểm bắt đầu; không thay scene, asset, rig, audio hoặc xóa prototype.

## Hành vi sau thay đổi

- Dash đất vẫn có ACTIVE 0,30s và SKID 0,20s. **Giữ defense trong dash sẽ vào defense ngay khi hết SKID**, nếu vẫn giữ nút và stamina > 0. Air dash vào defense ngay sau ACTIVE vì không có SKID.
- Cooldown scene đang lưu **0,06s**, vẫn bắt đầu khi rời DASH và vẫn chặn lần dash tiếp theo; không còn chặn defense. Nhấn defense mới trong cooldown cũng vào ngay.
- Không mở lại cửa sổ deflect khi yêu cầu giữ được thực thi. Thời gian vẫn tính từ lần nhấn defense ban đầu. Thả nút, menu/focus cleanup hoặc stagger hủy yêu cầu chờ. Nếu stamina chưa hồi về >0 khi dash kết thúc thì không vào defense.
- Dash vẫn mặc định tiêu 20 stamina, có thể tiêu phần còn lại khi dưới 20, bằng 0 không thực hiện. Quyền air dash reset khi nhảy hoặc tiếp đất như trước; double jump vẫn cấp lại air dash.

## 1. I-frame có nguồn sở hữu riêng

`DamageComponent` không còn dùng một bool để cho timer HIT, DASH và STAGGER tắt bảo vệ của nhau. Mỗi nguồn giữ token riêng; callback chỉ giải phóng đúng token của nguồn đó. Gia hạn cùng nguồn sinh token mới nên timeout cũ không ảnh hưởng lần mới. Kết thúc dash chỉ giải phóng DASH, không xóa HIT/STAGGER còn hiệu lực.

`is_invulnerable` được tính từ các nguồn đang giữ. Setter cũ còn để tương thích caller cũ/test reset; gameplay hiện tại không ghi bool này trực tiếp. Miễn damage của Saber Q vẫn do chủ sở hữu `SKILL_DASH` quyết định và được kết hợp ở cửa nhận damage; không dùng timer dùng chung.

Callback knockback/stun có generation riêng, bao gồm kiểm tra lại sau khi phát signal. Khi restore checkpoint/respawn, reset generation và các nguồn miễn damage để callback của lượt sống trước không thay đổi trạng thái lượt sống mới. Sentinel và thao tác bình máu đang chờ cũng được hủy khi chết/restore.

Đã biến tình huống lỗi cũ thành regression: HIT hết hạn giữa DASH_ACTIVE vẫn không nhận damage; hết DASH vẫn giữ HIT dài hơn; callback cùng nguồn cũ không kết thúc cửa sổ mới; stagger ngắt dash vẫn giữ i-frame stagger; phục hồi checkpoint không bị callback cũ kéo lại STUN/READY.

## 2. Player sở hữu HP/stamina và đồng hồ gameplay

Player khởi tạo một `StatsComponent` và một module `PlayerVitals`. HUD đang gắn tham chiếu đến cùng model này; không sở hữu bản sao dữ liệu nhân vật. File model vẫn ở `scenes/UI/stats_component.gd` để giữ tương thích đường dẫn/UID hiện có; vị trí source không quyết định ownership runtime.

`PlayerVitals` điều phối nhận damage, tiêu stamina, tự rút HP, bleed, hồi stamina và tiến trình dùng bình máu. Player tick module bằng physics. Đường tự rút Sentinel nhận delta game gốc; bleed/regen tiếp tục dùng delta actor để giữ luật miễn slow motion hiện tại của Q. Bình máu chờ 0,9 giây game trước khi thực hiện hồi phục, như Tween trước đây, nhưng việc hồi và trừ bình không còn phụ thuộc HUD hoặc Tween giao diện.

HUD nhận signal để cập nhật thanh, icon, animation bình và feedback. Tắt xử lý, tháo hoặc thay HUD không dừng regen/bleed/flask/Sentinel và không vô hiệu hóa nhận damage. HUD preview độc lập vẫn có model cục bộ để minh họa, không thay đổi dữ liệu Player.

Các property/method facade cũ trên HUD vẫn tồn tại cho caller cũ. SaveManager, PlayerProgress và safe zone đã ưu tiên model của Player, có fallback cho HUD cũ. Schema save không đổi; không migration hoặc ghi save thật trong kiểm thử. Player không có HUD ngay từ khi khởi tạo vẫn nhận được nâng cấp HP/stamina.

Các tương tác với UI như ẩn HUD tại campfire vẫn ở Player/HUD. Không đưa logic đổi vũ khí hoặc triển khai full Sentinel vào lần refactor này. Rút máu/chờ thoát Sentinel tiếp tục hoạt động với model Player và phát signal trình bày; Q/E/1–4 Sentinel vẫn chưa được tạo.

## 3. Dash có một module quản lý vòng đời

`DashComponent` quản lý eligibility, pha ACTIVE/SKID, đồng hồ pha, chuyển động X, cửa sổ i-frame, animation/ghost trail qua Player, kết thúc/ngắt và cooldown. Action HFSM vẫn giữ quyền ưu tiên toàn cục; không nhân đôi cây HFSM theo vũ khí hay dạng.

Bỏ Tween ghi vận tốc. Chuyển động dùng tích phân chính xác đường vận tốc QUAD/EASE_OUT cũ trong physics, gồm cả tick đầu khi dash được gọi bằng input. Với tốc độ đầu 2800, cuối 140, thời gian 0,30s, quãng đường không bị cản là:

`distance = duration × (end_speed + (start_speed - end_speed) / 3) = 308 px`.

Đã đo bằng di chuyển Godot ở 30/60/120 nhịp physics và kiểm tra input dodge thật. Va tường rút ngắn quãng đường; không xuyên tường. Tick đầu không còn cộng thêm một bước vận tốc ngoài ngân sách dash. Vì bỏ sai lệch sampling của Tween/physics, cảm giác/quãng đường có thể khác vài chục px so với cách cũ ở một số FPS; đường tốc độ và thông số gốc được giữ.

Tại hết ACTIVE, kết thúc nguồn i-frame DASH; SKID không tự cấp bảo vệ. Nếu còn nguồn HIT/STAGGER độc lập thì tổng trạng thái vẫn được bảo vệ đúng nguồn đó. Bị ngắt sẽ dọn chuyển động/ghost/immunity DASH và bắt đầu cooldown một lần. Không còn Tween cũ di chuyển Player sau khi vào rest.

## Vị trí chỉnh

Mở `res://scenes/adel/playable_adel.tscn`, chọn node gốc **PlayableAdel → Dash**:

- **Dash Speed**: tốc độ đầu, mặc định 2800 px/s.
- **Dash End Speed**: tốc độ cuối đường cong, mặc định 140 px/s; khi ACTIVE kết thúc vẫn đặt X về 0 để vào skid.
- **Dash Active Duration**: 0,30 giây game.
- **Dash Skid Duration**: 0,20 giây game. Đặt 0 sẽ bỏ skid.
- **Dash Iframe Window**: Vector2(start, end), mặc định `(0, 0.3)`, được giới hạn trong ACTIVE. Khoảng thời gian dạng `[start, end)`; nếu end <= start thì không có i-frame DASH. Tăng Active Duration không tự tăng cửa sổ này.

Cooldown vẫn chỉnh ở **DodgeCooldown → Wait Time**, hiện 0,06. Chi phí vẫn ở **PlayableAdel → Stamina → Dash Stamina Cost**, mặc định 20. Stamina Regen Delay/Per Second và Dark Sentinel → Sentinel Hp Drain Percent vẫn giữ vị trí cũ. Các override scene do người dùng chỉnh được bảo toàn.

Các hằng cũ `DASH_TWEEN_DURATION`/`DASH_SKID_DURATION` chỉ còn giữ tên default để tương thích code/test cũ; runtime lấy thông số xuất trên Player. Không đổi WALK_SPEED để chỉnh dash.

## Kiểm chứng và giới hạn

Test mới `res://tests/adel/player_refactor_validation.tscn` kiểm tra i-frame chồng nguồn, callback cũ, ngắt dash, khoảng cách ở nhiều physics rate, input thật, va tường, defense không đợi cooldown, model không có HUD, HUD thay thế, bleed/regen/flask, pause, save restore, nâng cấp và respawn. Có chạy Godot 4.7 thực tế ở headless và có render.

Các fixture cũ vốn dùng `hud.set_process(false)` để ngừng stats nay phải đặt `player.vitals.simulation_enabled=false` riêng. Đây là thiết lập test, không thay scene chơi thật. Saber suite dùng timing baseline rõ ràng để không ép thông số scene người dùng về default. Các kết quả cuối và số check từng suite được ghi trong manifest kiểm chứng; không coi các kết quả trước refactor là xác minh bản mới.

Rig hiện có các cảnh báo Bone2D/UID trong bản copy kiểm thử. Một fixture tạo Player phụ không có HUD giữ actor đó tới khi đóng cây vì IK resource của asset đang dùng chung; không tuyên bố đã sửa vấn đề chia sẻ resource rig hoặc mọi trường hợp nhiều Player. Không thay asset rig trong lần này.

Kiến trúc hiện có ownership rõ hơn cho dữ liệu và hiệu ứng miễn damage. Vẫn còn facade tương thích HUD, một số module truy cập coordinator Player và logic vũ khí Saber riêng. Chưa phải refactor toàn bộ game thành hệ thống nhiều vũ khí, chưa benchmark số lượng lớn enemy, và chưa thay luật air dash/double jump. Không commit hoặc push trong lượt này.

Kết quả cuối: **900 check đạt, 0 thất bại** trên 16 lượt kiểm tra; gồm headless và có render. Danh sách từng suite và hash file triển khai được lưu trong `Player-runtime-refactor-verification.json` tại workspace. Các cảnh báo rig/UID có sẵn không bị tính thành kiểm tra đạt; tất cả log cuối không có SCRIPT ERROR/ERROR.
