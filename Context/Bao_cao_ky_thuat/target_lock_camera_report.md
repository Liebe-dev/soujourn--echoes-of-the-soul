# Camera: target lock and mouse preferences — 2026-10-15

## Cách sử dụng

- Nhấn rồi thả chuột giữa: khóa enemy gần Player nhất, trong số enemy có tâm hurtbox nằm trong khung camera hiện tại. Khi đã khóa, nhấn ngắn chuột giữa lần nữa để hủy.
- Giữ chuột giữa rồi rê: dùng điểm khóa hiện tại làm gốc để tìm enemy theo hướng rê. Vòng vàng là lựa chọn xem trước; thả nút giữa để xác nhận. Nếu không tìm được mục tiêu theo hướng đó, giữ mục tiêu hiện tại. Giữ mà không rê cũng giữ mục tiêu, không hủy.
- Vòng trắng nằm đúng tâm hurtbox khi đã khóa. Khi khóa, vị trí con trỏ không điều khiển camera. Khoảng kéo tăng theo khoảng cách Player–enemy và bị giới hạn cùng ellipse với lia chuột.
- Enemy chết, bị xóa, ẩn, hurtbox bị tắt hoặc tâm hurtbox rời khung camera: mất khóa, camera trở về vị trí theo Player. Không tự nhảy sang enemy khác.
- Sau khi hủy/mất khóa, con trỏ cũ không kéo camera trở lại; phải rê tiếp để lia lại.
- Lia chuột mà không rê thêm trong 3 giây thực: camera tự về tâm, giữ ở tâm đến lần rê kế tiếp. Player di chuyển không khởi động lại bộ đếm. Tự trả tâm không tác động khi còn khóa enemy.

## Nơi điều chỉnh

Trong game: **Esc → Camera**.

- `Auto-center when mouse stops moving`: bật/tắt tự trả tâm.
- `Idle delay`: mặc định 3.0 giây, chỉnh 0.5–30 giây.
- `Mouse deadzone`: Player hiện đang đặt 15%, chỉnh 0–90%. Đây là bán kính vùng chuột trung tính theo tọa độ màn hình chuẩn hóa, dùng chung cách tính lia chuột cũ.

Trong Godot: mở `res://scenes/adel/playable_adel.tscn`, chọn `Camera2D`.

- **Mouse Pan → Mouse Pan Max Distance**: Player hiện đặt `(120, 75)` world px; giới hạn này dùng chung cho khóa và lia chuột. Ở góc chéo dùng giới hạn ellipse. Giá trị mặc định trong script là `(90, 55)`.
- **Mouse Pan → Mouse Pan Follow Speed**: Player hiện đặt `6.7`; tốc độ camera tiến tới offset và trở về tâm. Giá trị mặc định trong script là `5`.
- **Mouse Auto Reset**: giá trị mặc định trước khi có tùy chọn đã lưu từ pause.
- **Target Lock → Lock On Enabled**: bật/tắt chức năng.
- **Target Lock → Lock Switch Hold Time**: `0.20s`; phân biệt nhấn ngắn để hủy với giữ đứng yên để duy trì khóa.
- **Target Lock → Lock Switch Drag Distance**: `24` pixel trong viewport; loại rê tay quá nhỏ khi nhấn. Rê vượt ngưỡng sẽ được xem là chuyển mục tiêu, kể cả thả trước mốc 0.20s.
- **Target Lock → Lock Switch Half Angle**: `65°`; nửa góc vùng tìm theo hướng rê. Ưu tiên góc gần hướng rê nhất; khi góc gần bằng nhau chọn khoảng cách gần hơn.

Tùy chọn pause lưu riêng trong `user://camera_controls.cfg`; không thay đổi checkpoint hoặc các slot save. Giá trị lưu từ pause được nạp lại khi tạo Camera2D mới, có ưu tiên hơn mặc định Inspector cho đúng ba tùy chọn trên.

Giữ nguyên các giá trị người dùng đã đặt trong Player scene: theo X `6`, delay X `0.2s`, snap `0.2`, pan `(120,75)`, deadzone `0.15`, tốc độ pan `6.7`; không trả chúng về mặc định script.

## Cấu trúc

- `scenes/camera_2d.gd`: giữ nguyên cách theo Player theo X/Y; chỉ chọn nguồn offset giữa lia chuột, khóa hoặc trả tâm.
- `scenes/camera/camera_target_lock.gd`: chọn mục tiêu, thao tác chuột giữa, kiểm tra vòng đời/khung nhìn, vòng chỉ thị và bộ đếm đứng chuột. Component được tạo dưới Camera2D lúc chạy.
- `scenes/camera/camera_preferences.gd`: đọc/lưu tùy chọn camera.
- `scenes/enemy/enemy_base.gd`: tự đăng ký group riêng `camera_lock_targets`, cung cấp `get_lock_on_point()`. SpineEnemy và Wobtear kế thừa EnemyBase đều được hỗ trợ. Không thêm group `Enemy` vốn có thể gây sát thương tiếp xúc.
- Điểm khóa = tâm hình học `CollisionShape2D` gốc của EnemyBase, có áp dụng transform. Không lấy `WeaponPivot/Hitbox` hay `LeapHitbox`.
- `scenes/UI/game_pause_menu.tscn` và `pause.gd`: thêm bộ chỉnh camera.

Phạm vi tạm chọn: “trong tầm” là tâm hurtbox nằm trong viewport camera, không áp thêm bán kính thế giới hay kiểm tra đường nhìn. Prototype cũ không kế thừa EnemyBase vẫn được giữ nguyên; muốn dùng khóa cần cung cấp API điểm khóa và group riêng nói trên. Chức năng hiện tại chỉ tác động camera/điểm khóa, không tự xoay Player hay thay đổi hướng/sát thương đòn đánh.

Pause/B tạm ẩn vòng chỉ thị và vô hiệu thao tác khóa, giữ khóa đã xác nhận nếu enemy còn hợp lệ. Hủy thao tác đang giữ khi mở UI hoặc mất focus; thả chuột trong UI không xác nhận mục tiêu cũ. Campfire vẫn dùng camera riêng và không nhận thao tác khóa của camera gameplay.

## Kiểm chứng

Đã chạy bằng Godot 4.7 stable Windows trên bản sao project và các thư mục user riêng:

- Bộ khóa mục tiêu: 39 kiểm tra headless và 56 kiểm tra có render/chuột Windows.
- Hồi quy độ trễ X/cách theo Y: 15.
- Hồi quy lia chuột, cursor, B/Esc/campfire/title: 21 headless và 41 có render.
- Campfire: 58; entry/save: 60.
- Tổng: 290 kiểm tra, không có assertion thất bại trong các lượt xác nhận cuối; không có SCRIPT ERROR/ERROR trong log cuối.

Log còn cảnh báo Bone2D có sẵn từ rig enemy. Đây là kiểm thử tự động trên engine thật, chưa thay thế việc người thiết kế tự chơi để đánh giá cảm giác chuyển mục tiêu. Không sửa cân bằng combat, animation, các prototype legacy, scene Player đã chỉnh thông số hoặc `project.godot`; không chạy test vào save thật. Không commit/push trong yêu cầu này.
