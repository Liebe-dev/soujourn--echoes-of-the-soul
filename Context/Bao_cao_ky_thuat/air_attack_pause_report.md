# Air attack pause and jump windup

Ngày: 2026-10-16.

## Hành vi

- `saber_attack_1/2/3`: khi tới frame 1 của sprite (frame thứ hai), nếu đang trên không thì dừng rơi trong 0,07 giây game. Animation, hitbox và input tiếp tục hoạt động bình thường. Mỗi lần ra đòn chỉ ngưng một lần; đứng nguyên trên frame 1 không kích hoạt lại.
- Sau khoảng ngưng, tiếp tục vận tốc rơi chậm đang có; không đặt lại tiến trình rơi của combo. Giữ nguyên hệ số rơi người dùng đã chỉnh ở scene, hiện là **0.05**, và không thêm lực đẩy ngang.
- Không thêm khoảng ngưng vào `saber_attack_4`. Đòn dưới đất không có khoảng ngưng rơi. Marker được đi qua ở dưới đất sẽ không kích hoạt muộn khi bước khỏi mép nền.
- `jump_attack(air)`: giữ nguyên độ cao suốt animation, hiện dài **0,25 giây**, sau đó mới bắt đầu lao xuống. Chuyển tiếp dùng tín hiệu kết thúc animation thật, do đó theo đúng slow motion, pause và tốc độ animation. Không thêm khoảng ngưng 0,07 giây riêng ở frame 1 của đòn này.
- Hitbox jump attack mở trong giai đoạn lao xuống; không mở sớm trong animation chuẩn bị. Giữ nguyên sát thương và vùng đánh đã có.
- Thoát trạng thái ATTACK hoặc chuyển sang jump attack sẽ hủy khoảng ngưng combo còn lại, tránh để ảnh hưởng sang dash/defense/stagger/hành động tiếp theo.

## Điều chỉnh

Mở `res://scenes/adel/playable_adel.tscn` → node gốc **PlayableAdel** → Inspector → **Air Attack** → **Air Attack Frame Pause Duration**, mặc định `0.07` giây. Đặt `0` để tắt khoảng ngưng của ba đòn saber. Thời gian được tính theo game, dừng khi pause và chịu ảnh hưởng của slow motion; thời điểm bắt đầu/kết thúc được lượng tử hóa theo một bước physics.

Mốc bắt đầu được đọc từ key có giá trị `1` trong track `TestAttackSprite:frame` của từng animation. Hiện ba đòn saber đều có mốc **0,15 giây**. Chỉnh key đó trong animation sẽ tự thay đổi mốc bắt đầu, không cần sửa mã.

Để thay đổi thời gian chuẩn bị đâm xuống, chỉnh độ dài animation **jump_attack(air)** trong `res://asset/Character/Adel/adel spine action use.tscn`; runtime sẽ chờ animation kết thúc. Các resource animation gốc không bị sửa trong tác vụ này.

## Phân chia trách nhiệm

- `AdelAnimationComponent.sprite_frame_time()`: đọc mốc frame trong animation.
- `CombatComponent`: giữ khoảng ngưng một lần, hủy khi gián đoạn và giữ giai đoạn chuẩn bị jump attack.
- `PlayableAdel`: nối animation với component và chỉ dừng chuyển động Y trong khoảng ngưng.

## Kiểm tra

Scene mới `res://tests/adel/air_pause_validation.tscn` đã chạy bằng Godot thật ở headless và có hiển thị. Kiểm tra mốc của cả ba đòn, bước thời gian 30/60/120 Hz, tiếp tục vận tốc sau ngưng, không kích hoạt lại, đổi thời gian và tắt chức năng, hủy khi gián đoạn, nền đất và mép nền, tự theo mốc frame chỉnh lại, animation jump attack ở tốc độ 1,0 và 0,5, thời điểm mở hitbox, cùng animation thật tiếp tục chạy khi đứng yên trên không.

Các bài kiểm tra quỹ đạo dùng hệ số rơi cố định trong fixture; không ghi đè thông số scene của người dùng. Bằng chứng và log kết quả được lưu kèm tác vụ.
