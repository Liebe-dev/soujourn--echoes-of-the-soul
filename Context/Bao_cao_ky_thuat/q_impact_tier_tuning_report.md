# Q: tách thông số va chạm theo ba mức

> Cập nhật Q mức 1/2 ngày 16/10/2026: giữ zoom qua toàn bộ skill_6, sau đó pause thật trong lúc trả zoom và nhận một input buffer mới nhất; mở băng mới full ready/replay. Zoom Duration mức 1/2 nay là thời gian trả zoom theo giây thực, độc lập mỗi mức. Player root Z Index 200, nằm trước enemy. Chi tiết: [q_charged_return_freeze_report.md](q_charged_return_freeze_report.md).

Ngày: 16/10/2026. Đây là cấu hình hiện hành, thay cho việc Q dùng chung thông số với stagger trong `q_impact_ready_report.md`.

Mở `res://scenes/adel/playable_adel.tscn`, chọn node **SaberSkill**. Inspector có ba nhóm độc lập:

- **Tap Impact**: nhấn nhanh hoặc thả trước mốc charge mức 1. Tên biến bắt đầu bằng `tap_impact_`.
- **Charge Level 1 Impact**: đạt mức 1, chưa đạt mức 2. Tên biến bắt đầu bằng `charged_impact_`.
- **Charge Level 2 Impact**: đạt mức 2/auto lunge. Tên biến bắt đầu bằng `full_impact_`.

Mỗi nhóm có đủ bảy thuộc tính riêng, tương ứng tiền tố của nhóm:

- **Zoom Enabled**: bật/tắt zoom.
- **Zoom Multiplier = 1.5**: nhân zoom nền; 1,5 nghĩa là thêm 50%.
- **Zoom In Duration = 0.09s**: thời gian vào zoom, giây thực không tính pause.
- **Zoom Duration = 0.6s**: ngân sách từ lúc va chạm đến khi trả về zoom nền, theo giây actor. Đã bỏ phụ thuộc Knockback Duration, Stun Duration và Return Lead của stagger. Đây là tổng thời gian hiệu ứng zoom, không phải thời gian giữ cố định ở đỉnh; đường cong vẫn vào nhanh rồi trả dần như trước. Slow motion và Player exemption trong skill_6 vẫn ảnh hưởng đồng hồ actor theo luồng hiện có.
- **Slow Motion Enabled**: bật/tắt pulse slow motion lúc va chạm.
- **Slow Motion Scale = 0.35**: tốc độ thế giới; số nhỏ hơn chậm hơn, 1 là bình thường.
- **Slow Motion Duration = 0.36s**: thời lượng pulse, giây thực không tính pause.

Trong Inspector tên thuộc tính gồm cả tiền tố, ví dụ **Tap Impact Zoom Multiplier**, **Charged Impact Slow Motion Scale**, **Full Impact Zoom Duration**. Có thể dùng ô tìm kiếm Inspector với `impact`.

Mặc định của cả ba nhóm giữ đúng hiệu ứng trước khi tách. Đổi một mức không đổi hai mức còn lại hoặc stagger; đổi/tắt stagger cũng không đổi Q. Tuning riêng một instance Player trong map chỉ tác động instance đó; sửa SaberSkill trong scene Player để thay mặc định chung. Không chỉnh scene, asset hay animation của người dùng trong lượt này.

`SaberWeaponSkill._start_impact_feedback()` chọn cấu hình theo tier đã chốt khi lunge. Trigger vẫn ngay lúc va chạm và vào `saber_skill_5`. Damage, hit-stop từng mức, full `saber_ready`, hủy hiệu ứng khi bị ngắt, pause và camera framing giữ nguyên. Module hiệu ứng được tái sử dụng nhưng giá trị Q không đọc từ Player.stagger_* nữa.

Các nhóm này chỉ điều khiển **hiệu ứng va chạm skill_5**. Slow motion thu kiếm của `saber_skill_6` vẫn có cấu hình riêng sẵn có trong **SaberSkill → Impact Timing → Recovery Slow Motion Scale**, cùng **Charged Recovery Duration / Tap Recovery Duration**. Nếu tắt pulse va chạm của mức charge, pha skill_6 vẫn có thể làm chậm thế giới theo luật cũ. Hit-stop cũng giữ cấu hình riêng và CombatTime vẫn chọn mức chậm mạnh nhất giữa các nguồn đang chạy.

Kiểm chứng: test `q_impact_validation.tscn` được mở rộng để thử ba bộ giá trị khác nhau, đổi mạnh tuning stagger mà Q không đổi, bật/tắt từng thành phần, kiểm tra 21 field export trong Inspector và lưu/load scene giữ đủ ba cấu hình. Test Q cũ tắt pulse Q bằng các toggle Q mới để cô lập đồng hồ skill; không còn dùng toggle stagger để tắt Q. Log cuối nằm trong gói `outputs/q-tiers-20261016`.
