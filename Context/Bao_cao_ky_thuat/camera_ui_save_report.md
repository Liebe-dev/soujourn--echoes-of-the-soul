# Camera, HUD, menu, campfire và save

Cập nhật: 16/10/2026. Báo cáo hiện hành đã gộp các bản thay đổi camera/UI/save. [Hướng dẫn tùy chỉnh chung](huong_dan_tuy_chinh.md) là nơi tra thông số. Kế hoạch camera rộng trước đây là phương án lịch sử đã được người dùng yêu cầu khôi phục; không coi mọi đề xuất trong kế hoạch đó là tính năng đang bật.

## 1. Camera gameplay

Camera hiện hành dùng `res://scenes/camera_2d.gd` trên `PlayableAdel/Camera2D`. Theo X có delay khi bắt đầu/đổi hướng, sau đó follow theo tốc độ cấu hình; dừng sẽ trở về giữa X. Không thêm lookahead theo facing ngoài yêu cầu này. Theo Y vẫn có deadzone/follow hiện có.

Ground Framing giữ chân ở phần trăm màn hình tính từ đáy, mặc định r = 43/270. Với H là chiều cao viewport và z là zoom thực tế:

```text
visible_height_world = H / z
ground_margin_world = (H / z) * r
ground_screen_y = H * (1 - r)
camera_center_y = tracked_feet_y - (H / z) * (0.5 - r)
```

H = 1080 và r = 43/270: phần dưới chân là 172 pixel đầu ra; khi zoom 1/1,5/2 tương ứng 172/114,67/86 đơn vị world. Điểm chân lấy từ collider vật lý có xét transform. Zoom combat/resize tính lại bố cục Y; giữ độ lệch X do follow delay. Mouse pan/lock cộng offset riêng lên bố cục này. Khi đang nhảy/rơi, follow/deadzone Y vẫn tác động.

## 2. Lia chuột và khóa mục tiêu

Mouse pan có deadzone, giới hạn ellipse X/Y và tốc độ tiến/trả offset. Khi không rê thêm quá thời gian cấu hình, trả tâm và giữ tâm tới lần rê mới; di chuyển Player không reset bộ đếm. Bộ đếm là thời gian thực khi gameplay đang nhận điều khiển.

Nhấn/thả chuột giữa chọn enemy gần Player nhất trong số có tâm hurtbox đang nằm trong camera. Nhấn ngắn lần nữa để hủy. Giữ rồi rê dùng target hiện tại làm gốc tìm theo hướng; vòng vàng xem trước, thả xác nhận; không tìm thấy thì giữ target cũ. Không có bán kính hay kiểm tra line-of-sight bổ sung ngoài luật trong khung hiện tại.

Khóa tại tâm collider thân EnemyBase, không lấy hitbox đánh. Khóa tắt mouse pan và kéo camera về enemy trong giới hạn cùng ellipse. Chết/xóa/ẩn/tắt hurtbox hoặc rời camera thì mất khóa và trả tâm, không tự đổi target khác. Sau mất khóa cần rê tiếp để lia lại. Chức năng chỉ điều khiển camera, không tự xoay Player hay hướng đòn.

Pause/menu tạm ẩn reticle và hủy thao tác đang giữ, giữ target đã xác nhận nếu còn hợp lệ. Campfire dùng camera riêng. Tùy chọn deadzone, auto reset on/off và delay có thể chỉnh trong Esc → Camera, lưu riêng ở `user://camera_controls.cfg`; ba giá trị đã lưu ưu tiên hơn mặc định scene. Không đụng slot checkpoint.

## 3. Zoom chiến đấu và thời gian

`HitStopCameraZoom` là pulse nhỏ tính theo thời gian thực không pause. Hit-stop thường của combo vẫn có nhưng đã tắt zoom của `saber_attack_1/2/3/4`. Guard/Deflect, Q và nguồn gọi hit-stop phù hợp còn có thể yêu cầu pulse; cấu hình/tình trạng stagger có thể từ chối pulse. Không suy ra mọi lần chậm game đều có zoom nhỏ.

Stagger và phản ứng thiếu stamina dùng `StaggerImpact`, với mức zoom/time riêng cho thiếu stamina. Q có ba bộ riêng và pha freeze trả zoom cho charge 1/2; xem [báo cáo Player](player_technical_report.md). Các nguồn zoom combat được phối hợp bằng mức lớn nhất, không nhân chồng thành zoom quá mức. Effect chỉ dọn nguồn của mình. Pause/resume/focus/đổi scene có cleanup.

Các trigger zoom map legacy vẫn tồn tại, có thể ghi trực tiếp camera.zoom. Chưa chuyển mọi trigger cũ vào cơ chế phối hợp; nếu gắn trigger mới cần kiểm tra tranh quyền với zoom combat. Không tự xóa các trigger/prototype cũ.

## 4. HUD thường và Sentinel

`res://scenes/UI/hud.tscn` có CanvasLayer ScreenSpace, bình máu, thanh HP/stamina, marker và icon status. `ui.gd` quan sát model của Player; preview độc lập dùng model cục bộ. Hiện/ẩn HUD hoặc thay skin không tự thay luật damage.

Thanh ulti trên HP đầy theo chiều ngang, khi đầy có ba móng đỏ mỗi bên và phần đen chuyển động bằng shader. Sentinel đổi HP thành đen/viền đỏ, ẩn marker và hiện loadout góc trái dưới: hình vũ khí, Q/E hai bên và slot 1–4 kế bên. Atlas/shader tận dụng ảnh gốc; không sửa ảnh nguồn. Các ô có trình bày cooldown/thiếu tài nguyên/chờ thoát nhưng không tự thực thi skill.

Vị trí UltimateMeter do layout node trong hud.tscn sở hữu; runtime không ghi đè bằng một offset export thứ hai. Thay kích thước, kéo node, chuyển scene hoặc resize phải tránh gọi CanvasItem lấy rect trước khi vào cây. Source tool đã có kiểm tra vòng đời cho preview.

HUD cung cấp `set_ultimate_charge`, `set_sentinel_active`, `set_sentinel_exit_pending` và `set_sentinel_ability_presentation`. Gameplay gửi dữ liệu, HUD không tự tính hồi chiêu/chi phí. Scene xem thử là `res://scenes/UI/previews/dark_sentinel_hud_preview.tscn`.

## 5. Con trỏ, pause và campfire

Gameplay ẩn icon chuột bằng HIDDEN, không capture cố định. Khi B/Esc/menu hoặc đoạn có con trỏ được mở hợp lệ, con trỏ hiện ở giữa viewport; đóng lại thì ẩn. Thay mode theo sự kiện, không warp về tâm mỗi frame để không phá mouse pan.

Campfire có phase IDLE/ENTERING/RESTING/LEAVING/LOADING/TITLE và generation chống coroutine fade cũ mở lại UI. F chỉ dùng mở campfire, không đóng. Từ lúc nhận F tới hết fade rời: khóa Esc và menu ngoài, ẩn HUD; chỉ hiện menu/con trỏ sau fade-in hoàn tất. Leave là cách rời; menu con có nút Back/Cancel riêng. Không để nhấn F nhanh tạo lượt vào/ra chồng nhau.

Campfire xóa giữa lượt hoặc đổi scene dọn quyền UI/cursor đúng chủ sở hữu. Hide HUD là hide CanvasLayer, không dừng model. Khi load cùng scene, giữ Rest và HUD ẩn, con trỏ chỉ hiện lại lúc menu sẵn sàng. Freeze trả zoom của Q có quyền pause riêng và chặn UI lấy quyền đó cho tới khi kết thúc.

## 6. Vào game và bảo toàn save

Title hiện hành là `res://scenes/UI/menu (2).tscn`. Start chọn một trong năm slot: slot trống tạo game mới; slot có dữ liệu cần xác nhận Replace, Cancel giữ dữ liệu. New Game vào `res://scenes/Map 1/map_1_scene_2.tscn` và `SpawnPoint_Default`, không gọi opening scene đã mất.

Continue chỉ cho load slot/schema/scene hợp lệ. Slot 1 dùng `user://soujourn_save.json`, slot 2–5 có hậu tố `_2`…`_5`. File chính lỗi nhưng `.bak` hợp lệ thì có thể đọc backup, không tự ghi lại file chính. Không có backup tốt thì giữ save hỏng và báo không khả dụng, không tự tạo tiến độ giả.

Ghi qua file `.tmp`, flush/kiểm bytes, giữ bản hợp lệ ở `.bak`, rồi replace file chính. Thất bại không cập nhật checkpoint như đã lưu; không lấy file chính hỏng đè backup tốt. Replace bởi New Game có bản `.before-new-game-<timestamp>-<ticks>.bak` riêng, không bị save checkpoint sau xoay mất. Đây là giảm rủi ro ghi dở, không phải cam kết chống mọi lỗi ổ đĩa/mất điện.

Pause có Resume/Restart Area/Return to Title. Restart reload map và checkpoint phù hợp, không ghi save. Load/respawn chờ scene/Player sẵn sàng rồi khôi phục vị trí, hướng, HP/flask/progression và dọn action/callback cũ. SaveManager và PlayerProgress ưu tiên model Player, có facade tương thích HUD cũ.

Campfire lưu vào slot phiên chơi; Save As đè slot khác cần xác nhận. F6 scene mà chưa chọn slot phiên chơi không được tự ghi đè slot cũ chỉ vì giá trị active mặc định. Saved chỉ hiện khi ghi thành công; lỗi load/ghi trả thông báo và giữ UI có thể tiếp tục.

## 7. Kiểm thử và giới hạn

Các suite hiện có dưới `res://tests/camera/`, `res://tests/ui/`, `res://tests/flow/`; dùng bản sao project và user directory riêng. Các lượt triển khai trước có chạy Godot thật, bao gồm render/native cho con trỏ và ảnh HUD. Headless không chứng minh con trỏ hệ điều hành.

Lượt tổng hợp này không đổi code, scene, asset hoặc save; không chạy lại Godot. Không nhập asset map, không triển khai bản camera nâng cấp đã bị yêu cầu hoàn tác, không sửa các phụ thuộc audio legacy đã mất và không tuyên bố playthrough/export/balance đã hoàn thiện.
