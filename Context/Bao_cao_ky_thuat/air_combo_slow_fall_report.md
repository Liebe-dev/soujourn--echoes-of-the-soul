# Air combo: continuous slow fall

Ngày: 2026-10-16.

## Thay đổi

- Combo đánh thường `saber_attack_1/2/3/4` trên không không còn giữ vận tốc Y bằng 0 mỗi frame. Nhân vật liên tục rơi xuống trong chuỗi đòn.
- Vận tốc rơi bằng `0.3` lần vận tốc rơi thông thường. Component duy trì một vận tốc tham chiếu, tích lũy cùng trọng lực và giới hạn rơi của locomotion; vận tốc thực bằng vận tốc tham chiếu nhân hệ số. Với giới hạn thông thường 920 px/s, giới hạn khi đánh trên không là 276 px/s.
- Sang đòn combo tiếp theo không đặt lại vận tốc tham chiếu, tránh treo người hoặc chậm lại sau mỗi lần đánh. Nếu bắt đầu đánh lúc còn đang bay lên, quán tính lên được ngắt và nhân vật bắt đầu rơi xuống chậm.
- Bỏ xung vận tốc ngang 150 px/s ở các đòn đánh thường trên không. Đòn đánh dưới đất vẫn giữ xung vận tốc cũ. Di chuyển chủ động sau khi hủy đòn vẫn tuân theo luật hiện có.
- Rơi chậm kết thúc khi rời combo; vận tốc hiện tại tiếp tục được trọng lực thường gia tốc. Tiếp đất hoặc gián đoạn sẽ xóa vận tốc tham chiếu của combo cũ.
- Chuỗi đâm xuống riêng `jump_attack(air)/(fall)/(land)` giữ nguyên thời gian treo, vận tốc rơi, hitbox và sát thương. Không chỉnh animation, asset, scene hay thông số người dùng đã căn chỉnh.

## Điều chỉnh

Mở `res://scenes/adel/playable_adel.tscn`, chọn node gốc **PlayableAdel**. Trong Inspector → **Air Attack**, chỉnh **Air Attack Fall Speed Multiplier**:

- `0.3`: tốc độ yêu cầu.
- `0.5`: rơi nhanh hơn, bằng một nửa rơi bình thường.
- `1.0`: tốc độ rơi bình thường.

Khai báo mặc định ở `res://scenes/adel/playable_adel.gd`, biến `air_attack_fall_speed_multiplier`. Logic vận tốc tham chiếu nằm trong `CombatComponent.apply_combat_air_physics()`.

## Kiểm tra

Scene `res://tests/adel/air_combo_validation.tscn` kiểm tra quỹ đạo và tích phân quãng đường so với locomotion bình thường ở bước thời gian 30/60/120 Hz, nhiều vận tốc bắt đầu, toàn bộ bốn đòn combo, giới hạn rơi, hai hướng, va chạm nền, thay đổi hệ số và gián đoạn sang dash. Có kiểm tra vòng physics và animation thực của Player trong Godot.

Kết quả chạy thực tế được lưu kèm báo cáo ở thư mục bằng chứng của tác vụ. Bản kiểm tra dùng thư mục save riêng, không dùng save chơi thật. Chưa thay thế việc người dùng đánh giá cảm giác điều khiển bằng tay.

## Bổ sung 2026-10-16: ngưng rơi theo frame

`saber_attack_1/2/3` có khoảng ngưng rơi 0,07 giây tại frame 1, sau đó tiếp tục rơi chậm. `jump_attack(air)` giữ trên không suốt animation 0,25 giây rồi lao xuống. Chi tiết và thông số: `air_attack_pause_report.md`. Hệ số 0.3 bên trên là mặc định của script; giá trị scene do người dùng chỉnh hiện là 0.05 và được giữ nguyên.
