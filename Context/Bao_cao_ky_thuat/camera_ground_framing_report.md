# Camera ground framing và slow motion thiếu stamina — 2026-10-16

## Hành vi hiện tại

Camera giữ mặt phẳng chân ở 227/270 = 84.074074% chiều cao màn hình khi player đứng trên đất và không lia chuột/khóa mục tiêu. Phần bên dưới chiếm 43/270 = 15.925926%, tương đương 172px trên màn hình cao 1080px. Khi zoom, điểm neo Y được tính lại ngay từ zoom hiện tại, không kéo tâm thân player vào giữa màn hình.

Trục X tiếp tục dùng Horizontal Follow Delay, Follow Speed X và Center Snap hiện có. Khi đang di chuyển/bật lùi, khoảng lệch X vẫn do độ trễ camera tạo ra; zoom không xóa khoảng lệch đó. Lia chuột và pan theo khóa mục tiêu vẫn cộng lên bố cục mặc định. Khi player nhảy/rơi hoặc đổi cao độ, vertical follow/deadzone hiện tại tiếp tục điều khiển Y.

## Công thức

Gọi H là chiều cao viewport game, z là Camera2D.zoom.y thực tế và r = 43/270:

```text
visible_height_world = H / z
ground_margin_world = visible_height_world * r
ground_screen_y = H * (1 - r)
camera_center_y = tracked_feet_y - visible_height_world * (0.5 - r)
```

Khi đứng ổn định, tracked_feet_y là mặt phẳng chân vật lý. Với hệ follow Y hiện có, camera theo root lệch -30 đơn vị, nên offset cộng lại 30 và độ cao từ root tới đáy CollisionShape2D. Đáy shape được tính trong world space, có xét scale/rotation; không phụ thuộc khung animation.

Ví dụ viewport 1920x1080:

- Zoom tuyệt đối 1.0: vùng nhìn cao 1080 world units; phần đất dưới chân 172 world units.
- Zoom tuyệt đối 1.5: vùng nhìn cao 720; phần đất 114.666667 world units.
- Zoom tuyệt đối 2.0: vùng nhìn cao 540; phần đất 86 world units.

Sau khi phóng lên màn hình đầu ra 1080p, phần dưới mặt phẳng chân vẫn là 172px. Đây là phân biệt giữa kích thước trong vùng nhìn world và pixel đầu ra. Zoom stagger +50% nhân với zoom nền; ví dụ nền 1.05 thì đỉnh là 1.575, công thức dùng z = 1.575.

Camera tính bố cục lại khi cập nhật zoom combat hoặc resize viewport. Các lớp hit-stop và stagger vẫn lấy mức zoom lớn nhất, không nhân chồng. Lặp zoom vào/ra giữ cùng điểm neo, không tích lũy sai lệch.

## Chỗ chỉnh trong Godot

`res://scenes/adel/playable_adel.tscn` → node **Camera2D** → **Ground Framing**:

- **Ground Framing Enabled**: mặc định bật; tắt để dùng lại Offset Y đã lưu trong scene.
- **Ground Screen Fraction**: mặc định `43.0 / 270.0` (0.159259259). Tăng để thấy nhiều phần đất dưới chân hơn, nhân vật cao hơn trong khung; giảm để chân nằm thấp hơn.

Nhóm **Horizontal Follow** / **Camera Settings** giữ nguyên các thông số trễ X và tốc độ follow. Công thức Y tự xử lý mọi độ zoom hiện tại, gồm zoom stagger và hit-stop.

## Slow motion khi thiếu stamina

`playable_adel.tscn` → node gốc **PlayableAdel** → **Stagger Impact**:

- **Stamina Exhaustion Slow Motion Duration Multiplier**: mặc định 0.5.
- Thời lượng thiếu stamina = **Stagger Slow Motion Duration × hệ số này**.
- Cấu hình scene đang có 0.36s → Guard/Deflect thiếu stamina dùng 0.18s thực. Stagger HP thường vẫn dùng 0.36s.
- Giữ nguyên mức chậm **Stagger Slow Motion Scale**, các thời gian zoom vào/ra, animation, knockback, i-frame và luật sát thương/stamina.
- Giữ nguyên mức zoom thiếu stamina người dùng đã chỉnh trong scene là 1.05; không tự đặt lại 1.3. Script default của thông số zoom riêng vẫn là 1.3.

## Kiểm tra

Godot 4.7 stable, trên bản sao project với các thư mục save riêng:

- Ground framing: 35 kiểm tra headless + 35 kiểm tra có render. Ba tỷ lệ viewport, zoom 1/1.5/2, canvas projection của chân, trễ X hai hướng, trả tâm khi dừng, pan cộng thêm, vòng zoom không drift, Guard/Deflect thiếu stamina và stagger HP thật.
- Stagger regression: 49 kiểm tra headless. Bộ này dùng fixture rõ ràng (200px / pha đầu 0.3s / slow motion 0.18s) trong test, không sửa scene đã căn chỉnh của người dùng. Các khẳng định focus giữa thân cũ được cập nhật cho bố cục X hiện tại.
- Target lock: 39 kiểm tra headless.
- Mouse/menu/campfire: 21 kiểm tra headless; không dùng headless để tuyên bố đã xác minh con trỏ hệ điều hành.

Tổng 179 kiểm tra đạt. Ảnh zoom-1.0, zoom-1.5, zoom-2.0 và stagger-peak được chụp trực tiếp từ viewport có render. Các source scene, animation/rig, ảnh asset, project.godot và save thật không thay đổi.
