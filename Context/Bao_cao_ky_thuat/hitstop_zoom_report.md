# Hit-stop camera zoom — 2026-10-15

## Hành vi

Mỗi request hit-stop hợp lệ từ Player kích hoạt zoom nhẹ **1.15x**, tức thêm **15%** so với zoom gốc. Camera hiện đặt 1.05 nên đỉnh pulse khoảng **1.2075**. Zoom vào trong **0.025 giây thực**, ra trong **0.09 giây thực**, tổng khoảng **0.115 giây**, có dừng khi pause. Các thời lượng này không bị nhân dài do hit-stop giảm tốc game.

Không tạo hit-stop mới, không đổi sát thương hay thời lượng hit-stop cũ. Đánh hụt, hit bị từ chối, damage bằng 0 hoặc tắt Hit Stop Enabled không tạo zoom. Chạm nhiều enemy trong cùng một swing vẫn chỉ có request xác nhận đầu tiên như trước.

Pulse lặp khi pulse trước chưa kết thúc dùng chung zoom gốc, chuyển tiếp từ mức zoom đang có tới đỉnh tối đa; không nhân chồng. Stagger hủy pulse nhỏ ngay lúc bắt đầu và ưu tiên zoom stagger riêng. Trong toàn bộ stagger, kể cả đoạn cuối đã trả zoom, hit-stop zoom không giành quyền zoom; thời hạn trả zoom stagger vẫn được giữ.

## Những đoạn có hit-stop hiện tại

Mọi nguồn dưới đây đều đi qua `PlayableAdel._request_hit_stop()` và mặc định dùng time scale **0.05**:

- Saber attack **1, 2, 3** khi damage được enemy chấp nhận: **0.035s**.
- Saber attack **4** khi trúng: **0.055s**.
- **Guard đủ stamina** khi đỡ thành công: **0.025s**.
- **Deflect đủ stamina** khi thành công: **0.065s**. Sau hit-stop mới tới slow motion Deflect riêng, theo luật cũ.
- **Q nhấn nhanh** khi xác nhận damage: **0.065s**.
- **Q cấp charge 1** khi xác nhận damage: **0.075s**.
- **Q cấp charge 2** khi xác nhận damage: **0.10s**.

Q hiện lấy cấp theo các ngưỡng người dùng đang đặt trong SaberSkill (0.7/1.5s), không sửa các ngưỡng đó.

**Jump attack fall/land hiện gây damage nhưng chưa gọi hit-stop**, nên không nhận zoom mới này. Attack air chưa gây hit-stop riêng. Damage thường nhận vào Player cũng chưa tạo hit-stop; threshold/thiếu stamina có hiệu ứng stagger riêng. Guard/Deflect thiếu stamina không tạo hit-stop thành công, tiếp tục dùng stagger.

## Chỗ chỉnh trong Godot

Mở `res://scenes/adel/playable_adel.tscn` → chọn **Camera2D** → Inspector → **Hit Stop Zoom**:

- `Hit Stop Zoom Enabled`: bật/tắt riêng zoom, không tắt hit-stop.
- `Hit Stop Zoom Multiplier`: **1.15**, chỉnh **1.10–1.20** cho mức thêm 10–20%.
- `Hit Stop Zoom In Duration`: **0.025s thực**.
- `Hit Stop Zoom Out Duration`: **0.09s thực**.

Thời lượng hit-stop gốc của đòn thường/đòn 4/Guard/Deflect: chọn node gốc **PlayableAdel** → **Hit Stop**. Thời lượng hit-stop của ba cấp Q: chọn **SaberSkill** → **Impact Timing**.

## Tổ chức và bảo toàn

- `playable_adel.gd`: chỉ báo camera sau khi CombatTime chấp nhận request hit-stop; dọn pulse khi Player chết.
- `scenes/camera/hit_stop_camera_zoom.gd`: chạy pulse nhẹ bằng đồng hồ thực có dừng lúc pause, khôi phục khi đổi camera hoặc owner rời scene.
- `camera_2d.gd`: các nguồn zoom dùng chung một baseline và lấy multiplier lớn nhất; thêm các thông số Inspector.
- `stagger_impact.gd`: đưa zoom qua camera để tránh hai thành phần ghi đè hoặc ghi nhớ baseline đã bị phóng to. Fallback cho Camera2D thuần được giữ.
- CombatTime vẫn là nơi duy nhất ghi Engine.time_scale; không thay đổi bộ điều phối thời gian.

Giữ nguyên Player scene, các chỉnh sửa stagger mới nhất **220px / 0.4s**, zoom vào **0.09s**, lead **0.25s**, slow motion **0.36s** và camera/skill tuning khác. Không sửa animation, asset, enemy, save, stamina, audio hay luật jump attack.

## Kiểm chứng

Chạy Godot 4.7 stable trên bản sao project với custom user directory riêng. Bộ `hitstop_zoom_validation.tscn` kiểm tra bốn Saber swing qua hitbox nhận damage, Guard/Deflect qua input và damage classifier, cả ba cấp Q qua luồng skill thật, whiff/rejected/zero damage, trùng stagger, pause, đổi camera và xóa Player. Kiểm thử tự động có render kèm capture đỉnh zoom; không thay thế việc người thiết kế tự chơi đánh giá cảm giác.

Số kiểm tra cuối và log hồi quy nằm trong gói xác minh. Cảnh báo Bone2D có sẵn từ rig có thể vẫn xuất hiện; không liên quan đến pulse zoom.

Kết quả: **449 kiểm tra, 0 thất bại** — bộ mới 56 headless + 56 có render; camera X 15, khóa 39, lia chuột/menu 21; combat feel 106, Guard/stamina 96 và entry/save 60. Không có SCRIPT ERROR/ERROR trong các log xác nhận cuối.
