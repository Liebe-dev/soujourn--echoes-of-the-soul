# Stagger impact / horizontal slide — 2026-10-15

## Hành vi đã triển khai

- Khi bắt đầu phản ứng stagger: yêu cầu slow motion ngay lập tức, mặc định **0.35x trong 0.18 giây thực**, qua CombatTime. Không tạo một bộ ghi Engine.time_scale mới. Hit-stop/Deflect/skill vẫn được bộ điều phối chung phân xử; hiệu ứng có scale nhỏ nhất sẽ thắng khi trùng nhau.
- Zoom tiến nhanh tới **1.5 lần zoom trước khi trúng đòn** trong khoảng **0.06 giây thực**. Với Player scene hiện có, `1.05 → 1.575`. Trong pha zoom, camera giữ mặt phẳng chân theo tỷ lệ 43/270 chiều cao từ đáy viewport; trục X tiếp tục theo độ trễ và pan hiện có.
- Sau khi đạt đỉnh, zoom và framing trả dần về giá trị trước đó. Hoàn tất **0.2 giây thời gian animation/game trước khi stagger kết thúc**. Camera giữ nguyên mức zoom cũ trong đoạn cuối này.
- Stagger mặc định vẫn kéo dài **0.3 + 0.45 = 0.75 giây game**. Frame 0 giữ tới mốc 0.3; frame 1 từ mốc 0.3 đến 0.75; hồi về frame 2 của saber_ready như trước.
- Bật lùi chỉ tác động vận tốc **X**. Nguồn đòn đánh ở trên/dưới không tạo xung lực lên trời. Nếu đang rơi, giữ vận tốc rơi; trọng lực và va chạm địa hình vẫn hoạt động. Nếu đang bay lên, stagger chặn đà bay lên rồi áp trọng lực bình thường.
- Pha frame 0: vận tốc X ổn định. Sau khi chuyển frame 1 tại 0.3 giây, vẫn trượt và giảm tốc mạnh trong **0.2 giây**, dừng tại mốc **0.5 giây game**, tiếp tục stun đứng yên đến 0.75.
- Giữ ngân sách quãng đường đã chỉnh trong Player scene là **200px**. Vận tốc đầu được chuẩn hóa để việc thêm đoạn giảm tốc không tăng tổng quãng đường. Tường/địa hình vẫn có thể cắt bớt quãng di chuyển thực tế.

Các mốc 0.3/0.5/0.55/0.75 là đồng hồ game dùng cùng stagger, không phải đồng hồ thực khi slow motion đang chạy. Slow motion và thời gian zoom vào dùng đồng hồ thực có dừng khi pause. Với cấu hình hiện tại, slow motion kết thúc trước pha giảm tốc nên đoạn giảm tốc 0.2 giây vẫn diễn ra ở tốc độ game bình thường.

## Vị trí điều chỉnh

Mở `res://scenes/adel/playable_adel.tscn` → chọn node gốc **PlayableAdel** → Inspector.

**Stagger Threshold**:

- `Stagger Knockback Distance`: khoảng bật lùi tổng; Player scene đang đặt **200**.
- `Stagger Knockback Duration`: thời gian giữ frame 0 / pha đẩy đều; **0.3s**.
- `Stagger Stun Duration`: thời gian giữ frame cuối sau pha đầu; **0.45s**. Tổng stagger = Duration + Stun Duration.

**Stagger Impact**:

- `Stagger Knockback Deceleration Duration`: thời gian giảm tốc sau khi đổi frame, **0.2s**. Không cộng thêm thời gian stagger; tự giới hạn trong Stun Duration nếu chỉnh stun ngắn hơn.
- `Stagger Zoom Enabled`: bật/tắt zoom.
- `Stagger Zoom Multiplier`: **1.5**, tương ứng thêm 50%.
- `Stagger Zoom In Duration`: **0.06s thực**, thời gian tiến tới zoom đỉnh.
- `Stagger Zoom Return Lead`: **0.2s game**, trả zoom trước khi hết stagger từng này thời gian. Nếu tổng stagger quá ngắn, bỏ zoom để bảo đảm có thể trả đúng hạn.
- `Stagger Slow Motion Enabled`: bật/tắt slow motion riêng của stagger.
- `Stagger Slow Motion Scale`: **0.35**.
- `Stagger Slow Motion Duration`: **0.18s thực**.

I-frame chung vẫn là **1.0 giây game**, tại `DamageComponent.STAGGER_INVULN_SEC` trong `res://scenes/adel/components/damage_component.gd`. Không đổi luật HP threshold, bleeding tick, debuff, stamina hay Guard thường đủ stamina.

Guard/Deflect thiếu stamina tiếp tục dùng chung phản ứng stagger vật lý nên cũng nhận zoom và slow motion stagger mới. Đây là hiệu ứng stagger riêng; không mở pulse/pose Deflect thành công và không tiêu marker HP hay áp debuff.

## Tổ chức và cleanup

- `damage_component.gd`: hướng ngang; đường cong vận tốc giảm theo `(1-u)^2`, lấy tích phân để giữ ngân sách quãng đường ở 30/60/120 bước mỗi giây. `is_knocking_back` tiếp tục đánh dấu pha frame 0; STUN giữ quyền điều khiển trong phần trượt frame 1.
- `playable_adel.gd`: cấu hình Inspector, gọi hiệu ứng, cho phép phần trượt trong STUN và giữ trọng lực bình thường.
- `stagger_impact.gd`: zoom, thời hạn trả zoom và request lane `stagger_impact` qua CombatTime. Khôi phục đúng zoom đã ghi nhận, không nhân chồng khi khởi động lại.
- `camera_2d.gd`: tính offset Y từ mặt phẳng chân, viewport và zoom thực tế; follow X/Y, lia chuột và khóa mục tiêu tiếp tục dùng đường điều khiển hiện có.
- Pause đóng băng tiến trình hiệu ứng. Thoát stagger, chết, Player bị xóa hoặc camera khác giành quyền hiện tại đều dọn hiệu ứng và trả zoom. Không ghi đè zoom của camera campfire.
- Khóa mục tiêu tiếp tục tuân thủ khung nhìn thực tế: nếu zoom làm tâm enemy ra khỏi màn hình, luật mất khóa hiện có vẫn áp dụng.

Pose Deflect đang được giữ từ trước vẫn có ưu tiên hiển thị theo luật cũ nếu một threshold thật xuất hiện giữa pulse Deflect; thiếu stamina vốn đã hủy pulse Deflect để hiển thị stagger ngay. Không thay đổi ngoại lệ trình bày này trong yêu cầu hiện tại.

## Kiểm thử

Chạy Godot 4.7 stable Windows trên bản sao project với custom user directory tách biệt; không chạy vào save thật. Log cuối và tổng số kiểm tra được ghi trong gói xác minh bàn giao.

Kết quả cuối: **628 kiểm tra, 0 thất bại** — stagger 49 headless + 49 có render, combat 337, campfire/entry-save 118, camera 75. Không có SCRIPT ERROR/ERROR trong các log cuối.

- Bộ stagger mới chạy headless và có render: hướng hit trên/dưới, khoảng trượt và giảm tốc tại 30/60/120 bước, đổi frame, ngắt combo, hồi attack, zoom 1.5x, deadline trả zoom, slow motion thực, pause, đổi camera, khởi động lại, thiếu stamina và Player bị xóa.
- Hồi quy combat và camera/menu/save theo log xác minh.
- Hai bộ hồi quy HFSM/Guard tắt riêng hiệu ứng trình bày khi đo luật combat theo đồng hồ cũ; bộ stagger mới kiểm tra đầy đủ hiệu ứng bật. Guard regression đã đổi giả định “dừng ngay ở frame 1” thành “tiếp tục trượt, dừng trước hồi điều khiển”.

Không sửa source rig/animation, enemy, Player scene đã chỉnh tay, project.godot, file save hay audio. Các cảnh báo Bone2D từ rig hiện có vẫn có thể xuất hiện. Kiểm thử tự động trên engine thật không thay thế đánh giá cảm giác khi người thiết kế tự chơi.


## Cập nhật 2026-10-15 — zoom riêng khi thiếu stamina

Guard/Deflect được chấp nhận với stamina còn ít hơn chi phí dùng `Stamina Exhaustion Zoom Multiplier = 1.3` (+30%). Chỉnh ở node gốc PlayableAdel trong playable_adel.tscn, Inspector → Stagger Impact. Stagger do ngưỡng HP vẫn dùng `Stagger Zoom Multiplier` (mặc định 1.5, +50%). Mức zoom tính so với zoom nền camera, không cộng dồn với hit-stop zoom.

Chỉ tách cường độ zoom; giữ nguyên animation hai frame, quãng đường/thời gian bật lùi, stun, i-frame, slow motion và thời gian trả zoom. Ngữ cảnh thiếu stamina chỉ tồn tại trong lúc apply_stagger phát tín hiệu đồng bộ; không ảnh hưởng stagger thường xảy ra sau đó.

Test `res://tests/adel/exhaustion_zoom_validation.tscn`: 27 kiểm tra headless và 27 có render trong Godot 4.7, trên save riêng CodexExhaustionZoom20261015. Kiểm tra Guard/Deflect với 10 stamina, HP/stamina/threshold không đổi luật, peak camera 1.3, trả zoom nền, stagger thường sau đó vẫn 1.5 và thay thông số riêng không đổi stagger thường.


## Cập nhật 2026-10-16 — ground framing và thời lượng thiếu stamina

Xem `camera_ground_framing_report.md` cho công thức và cấu hình hiện tại. Camera giữ phần đất 43/270 chiều cao vùng nhìn: viewport 1080, zoom 1/1.5/2 tương ứng 172/114.666667/86 world units dưới chân, cùng 172px trên màn hình đầu ra. Zoom giữ trễ X hiện có. Guard/Deflect thiếu stamina dùng `Stamina Exhaustion Slow Motion Duration Multiplier = 0.5` nhân với thời lượng slow motion stagger thường; scene hiện tại 0.36s thành 0.18s, mức chậm giữ nguyên. Mức zoom thiếu stamina do người dùng đã chỉnh (1.05) được giữ nguyên. Những giá trị trong phần bàn giao cũ là cấu hình của lần kiểm tra đó; báo cáo ground framing mô tả cấu hình mới.
