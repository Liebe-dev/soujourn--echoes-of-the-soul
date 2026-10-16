# Saber Q: full ready và phản hồi va chạm

> Cập nhật tách tuning 16/10/2026: zoom/slow motion khi Q va chạm đã độc lập hoàn toàn với stagger và có ba bộ riêng trên SaberSkill: Tap Impact, Charge Level 1 Impact, Charge Level 2 Impact. Cả thời gian trả zoom cũng không còn theo knockback/stun stagger. Xem [q_impact_tier_tuning_report.md](q_impact_tier_tuning_report.md). Những mô tả dùng chung stagger bên dưới là snapshot trước lần tách này.

Ngày: 16/10/2026. Áp dụng cho Q Saber hiện tại, cả tap và hai mức charge. Không sửa animation/texture/rig hoặc tuning đang lưu trong scene.

## Hành vi mới

- Hoàn tất Q, dù trúng hoặc hụt, chuyển sang `saber_ready` gốc, đủ frame 0 → 1 → 2. Giữ nguyên thời lượng clip 1 giây game và quyền ngắt ready để di chuyển/attack/defense/Q theo điều kiện sẵn có. Không sửa ready cuối frame của defense/guard/deflect/stagger. Bị ngắt Q bởi stagger/menu/checkpoint không được xem là Q hoàn tất bình thường.
- Ngay khi lunge chạm hurtbox enemy và vào `saber_skill_5`, bắt đầu zoom mạnh và pulse slow motion. Không đợi đến `saber_skill_6` hoặc đợi xác nhận damage. Chỉ chạm tường hoặc hết tầm không tạo pulse này.
- Đọc trực tiếp các giá trị stagger trên Player lúc va chạm, gồm enabled, zoom multiplier, zoom-in duration, return lead, slow-motion scale/duration. Với scene đang lưu: **zoom ×1,5**, vào zoom **0,09s thực**, slow motion **0,35x trong 0,36s thực không tính pause**. Khoảng zoom dùng cùng ngân sách stagger **0,4 + 0,45 = 0,85 giây actor**, hoàn trả zoom trước mốc cuối **0,25 giây actor**, theo đường cong stagger hiện có.
- Hit-stop riêng ba mức Q vẫn giữ 0,065 / 0,075 / 0,10s. Pulse slow motion bắt đầu ngay khi chạm và chạy đồng thời; CombatTime chọn mức chậm mạnh nhất, không nhân các time scale. Sau hit-stop, pulse còn lại tiếp tục ở mức stagger. Bỏ zoom hit-stop nhẹ riêng của Q để không trộn hai hiệu ứng zoom cho cùng va chạm.
- `saber_skill_6` vẫn giữ hành vi trước: tap 0,15s game, charge 0,30s thực với Player miễn slow motion trong recovery và world slow 0,50x. Khi pulse va chạm còn hiệu lực, world dùng mức mạnh hơn giữa các nguồn. Không thêm miễn damage trong impact/recovery; chỉ lunge giữ quyền miễn damage đã có.

Clip `saber_skill_6` hiện đã được người dùng lưu dài 0,45s. Script tự retime để giữ thời lượng recovery đã cấu hình; không đưa asset về 0,30s. Assertion cũ về tốc độ cố định 2x/1x được sửa thành kiểm tra thời lượng phát đúng với clip hiện có, tránh báo lỗi giả khi clip thay đổi độ dài.
- Hiệu ứng được phép trả zoom dần sau khi Q hoàn tất, tránh snap camera tại chuyển ready. Stagger thực tế, dash, vào Sentinel, rest/menu/checkpoint/focus cleanup hoặc Q tiếp theo sẽ hủy pulse Q khi thực hiện cleanup input. Pause đóng băng hiệu ứng. Không đổi Engine.time_scale trực tiếp ngoài CombatTime.

## Vị trí chỉnh

Mở `res://scenes/adel/playable_adel.tscn`, chọn **PlayableAdel → Stagger Impact**. Q dùng chung các thông số:

- **Stagger Zoom Multiplier**: hiện 1,5, nghĩa là thêm 50% zoom.
- **Stagger Zoom In Duration**: hiện 0,09s.
- **Stagger Zoom Return Lead**: hiện 0,25s.
- **Stagger Slow Motion Scale**: hiện 0,35.
- **Stagger Slow Motion Duration**: hiện 0,36s.
- **Stagger Zoom Enabled / Stagger Slow Motion Enabled**: bật/tắt từng phần cho cả stagger và va chạm Q.

Ngân sách zoom cũng theo **Stagger Threshold → Stagger Knockback Duration + Stagger Stun Duration**. Không thay khoảng bật lùi hoặc gây stagger cho Player khi Q đánh trúng; đây chỉ là cách lấy cùng đường cong/thời lượng hiệu ứng đã yêu cầu.

Thông số damage/charge/lunge/hit-stop và skill_6 vẫn tại node **SaberSkill**. Ready dùng clip gốc `saber_ready` trong AnimationPlayer; không chỉnh resource gốc hoặc frame cuối của những luồng khác.

## Cấu trúc

`SaberWeaponSkill` tạo child `SkillImpactFeedback` dùng lại `stagger_impact.gd`; truyền Player làm actor clock và dùng camera source riêng `skill_impact`. Stagger vẫn có source `stagger`, độc lập cleanup. Time pulse có owner Node riêng nên hủy Q không xóa effect của nguồn khác. Hoàn tất Q đặt cờ nội bộ trong transition để cleanup skill không cắt cụt zoom tail; mọi luồng ngắt thực sự vẫn hủy pulse.

`Player.clear_combat_input()` hủy feedback Q ngay cả khi Q vừa kết thúc và pulse đang trả zoom. `StaggerImpact` hỗ trợ actor và zoom_source tùy chọn; instance stagger cũ giữ mặc định cũ. Không thêm audio, asset hay thay scene của người dùng.

## Kiểm chứng

Test mới `res://tests/adel/q_impact_validation.tscn`: chạy Q thật với enemy hurtbox, ba mức charge/damage, timing va chạm, camera zoom thực, pulse, full ready, miss, pause, hit-stop, ngắt bởi stagger/checkpoint/Sentinel và attack ngắt ready. Chạy Godot 4.7 headless và có render, save riêng `CodexQImpact20261016`; có ảnh viewport ở thời điểm zoom sau va chạm.

Các suite Q cũ, giữ Q, stagger, Sentinel và ground framing cũng được chạy khi kiểm chứng. Kết quả cuối và ảnh nằm trong gói `outputs/q-impact-20261016` của lượt làm việc; không coi ảnh là kiểm chứng cảm giác chiến đấu thay cho nhận xét của người chơi.
