# Camera lia theo chuột và con trỏ giao diện

Ngày 15/10/2026. Triển khai trên nền camera X đã duyệt: trễ 0.1s, tốc độ bám X 8, giữ nguyên thuật toán bám Y.

## Chỉnh trong Inspector

Mở `scenes/adel/playable_adel.tscn`, chọn **Camera2D → Mouse Pan**:

- **Mouse Pan Enabled**: bật/tắt lia theo chuột.
- **Mouse Pan Max Distance = (90, 55)**: độ kéo tối đa ngang/dọc, theo pixel thế giới Godot; đặt Y = 0 nếu muốn chỉ lia ngang. Zoom 1.05 làm mức dịch trên màn hình hơi lớn hơn giá trị này.
- **Mouse Pan Deadzone = 0.18**: vùng trung tính quanh tâm; tăng để cần đưa chuột xa tâm hơn mới kéo camera.
- **Mouse Pan Follow Speed = 5**: tăng để bám chuột nhanh hơn; giảm để chuyển động chậm/êm hơn.

Các nhóm **Camera Settings**, **Horizontal Follow** và **Deadzone** vẫn điều khiển bám nhân vật như trước. Khi chuột ở vùng tâm, nhân vật đứng yên sẽ trở về giữa theo X. Khi chuột ra ngoài vùng tâm, camera nhận thêm offset theo hướng chuột; không đổi vị trí/va chạm của nhân vật.

Lia được theo trái/phải, lên/xuống và các hướng chéo. Hướng chéo có giới hạn hình ellipse, không cộng biên độ vô hạn. Tọa độ chuột tính trong viewport, độc lập vị trí camera trong thế giới để tránh camera tự kéo xa dần. Chuột nằm ngoài vùng game hoặc cửa sổ không có focus không kéo camera. Không thêm zoom/rung hay thay đổi combat.

## Con trỏ khi mở giao diện

`scenes/UI/cursor_policy.gd` thống nhất các điểm hiện/ẩn chuột đang có:

- B và Esc: căn giữa rồi hiện con trỏ khi mở menu/pause.
- Campfire: vẫn ẩn suốt fade vào; chỉ căn giữa/hiện khi giao diện đã sẵn sàng. Load tại campfire vẫn theo luật này.
- Màn hình chính và trở về title: con trỏ hiện ở tâm viewport game.
- Đóng menu/quay lại chơi: căn giữa trước khi ẩn để camera không kéo theo vị trí nút vừa bấm.
- Refresh trạng thái menu thông thường không ghim con trỏ ở giữa; người dùng vẫn rê chuột để bấm các nút.
- Không warp con trỏ khi game không có focus, tránh kéo chuột khỏi ứng dụng khác. Khi quay lại cửa sổ với giao diện đang hiện, con trỏ được căn giữa.

Giữ chế độ gameplay **MOUSE_MODE_HIDDEN** hiện tại, không chuyển sang capture/khóa chuột. Camera không lia theo chuột khi con trỏ đang hiện, game pause, campfire đang hoạt động hoặc camera gameplay không còn là camera hiện hành. UI không dịch chuyển theo camera.

Thuật toán bám Y và độ trễ X không bị thay thế. Mouse pan thêm vào `Camera2D.offset` trên offset scene gốc `(0, -234.71)`. Zoom và các thông số gameplay người dùng đã chỉnh không thay đổi. Không chỉnh project settings hoặc format/nội dung save chơi thật.

## Kiểm chứng

Chạy Godot 4.7 Windows trên bản sao project với custom user directory riêng:

- 21 kiểm tra headless qua: vùng chết, hướng/giới hạn pan, tỷ lệ viewport, input B/Esc, fade/camera campfire và trở về title.
- 41 kiểm tra có render qua: thêm con trỏ native, căn giữa khi mở/đóng UI, không ghim chuột khi dùng menu, không kéo camera lúc pause, và pan không tự khuếch đại khi nhân vật di chuyển. Chạy cửa sổ 1280×720 với viewport game 1920×1080 để kiểm tra phép đổi tọa độ.
- 15 kiểm tra camera X/Y cũ qua, gồm trễ 0.1s tại 30/60/120 bước và đối chiếu Y theo từng frame với camera cũ.
- Campfire UI: 58 kiểm tra qua; entry/save: 60 kiểm tra qua.

Tổng 195 assertion qua trong các lượt kiểm tra trên. Headless không xác minh được con trỏ hệ điều hành; kết quả căn giữa native lấy từ lượt chạy có render. Đây là kiểm tra tự động trong engine, không thay thế nhận xét cảm giác của người chơi.

Tài liệu API: [Viewport.warp_mouse](https://docs.godotengine.org/en/stable/classes/class_viewport.html#class-viewport-method-warp-mouse). Tâm dùng tọa độ viewport game, không dùng tọa độ thế giới hoặc kích thước màn hình giả định.
