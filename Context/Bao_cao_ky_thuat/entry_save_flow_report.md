# Luồng vào game và bảo toàn save — 14/10/2026

Đã sửa trên working tree hiện hành, giữ các thay đổi combat/animation/HUD và prototype cũ. Không commit/push trong yêu cầu này. Kiểm thử chạy trên bản sao project với user data riêng; không đọc, xóa hoặc ghi save thật của người dùng.

## Hành vi mới

- Start mở lựa chọn 5 slot. Chọn slot trống tạo game mới và một save khởi đầu; chọn slot đã có dữ liệu cần xác nhận Replace. Hủy không thay dữ liệu. Chỉ slot được chọn được thay, các slot khác giữ nguyên.
- Continue mở lựa chọn slot; slot trống, save không hợp lệ hoặc scene đã mất không được chọn để load. Nếu bản chính lỗi nhưng `.bak` còn hợp lệ, slot hiển thị `Backup:` và có thể tiếp tục từ bản dự phòng. Việc đọc/recover không tự ghi lại file chính.
- New Game hiện vào `res://scenes/Map 1/map_1_scene_2.tscn`, dùng `SpawnPoint_Default`. Scene này có Adel hiện hành và campfire. Đây là điểm vào tạm thời có thể cấu hình; không khôi phục `opening.tscn` đã mất hoặc thay intro legacy.
- Các luồng về title dùng chung `res://scenes/UI/menu (2).tscn`. Pause và campfire về đúng title; tree không còn bị giữ paused. Khi load game, khôi phục được vị trí, hướng, HP/flask và progression sau khi scene và player đã sẵn sàng.
- Adel có menu pause bằng Esc: Resume, Restart Area, Return to Title. Restart Area reload scene và dùng checkpoint đã chọn nếu checkpoint thuộc scene đó; không ghi lại save. Esc đóng master menu ngoài campfire; từ khi bắt đầu vào đến hết fade rời campfire, Esc bị chặn kể cả menu nâng cấp (cập nhật 15/10/2026).
- Nghỉ campfire vẫn hồi phục và lưu vào slot của phiên chơi. Save As vào một slot khác đã có dữ liệu cần xác nhận. Khi chạy trực tiếp scene bằng F6 mà chưa chọn slot của phiên chơi, autosave/progression không được ghi đè một slot cũ chỉ vì nó đang là active_slot mặc định; có thể chọn Save tại campfire và xác nhận slot cần dùng.
- Campfire chỉ báo Saved sau khi ghi thành công. Lỗi load/ghi hiện thông báo và để UI có thể tiếp tục thao tác.

## Bảo vệ file lưu

Tên slot 1 vẫn là `user://soujourn_save.json`; slot 2–5 là `user://soujourn_save_2.json`…`soujourn_save_5.json`. Không chuyển vị trí dữ liệu hoặc đổi tên project.

Ghi dữ liệu vào `<save>.tmp`, flush/kiểm tra bytes, giữ bản hợp lệ trước đó ở `<save>.bak`, rồi đổi tên file tạm thay file chính. Nếu bước ghi/backup/replace thất bại, không cập nhật checkpoint trong bộ nhớ như thể đã lưu thành công. Không dùng dữ liệu chính bị hỏng để ghi đè một backup còn tốt.

New Game thay slot đã có dữ liệu còn tạo bản lưu độc lập `<save>.before-new-game-<timestamp>-<ticks>.bak`; các lần lưu checkpoint sau không xoay mất bản này. Không tự xóa các bản lưu độc lập. `.bak` là bản dự phòng tự động gần nhất, không phải toàn bộ lịch sử.

Các bước dùng API [File/DirAccess của Godot](https://docs.godotengine.org/en/stable/classes/class_diraccess.html). Đây là cơ chế giảm rủi ro ghi dở, không cam kết chống mọi sự cố mất điện hoặc lỗi ổ đĩa. Không có backup hợp lệ thì save hỏng được giữ và báo unavailable; không bịa tiến độ thay thế.

Đọc save kiểm tra schema version, kiểu dữ liệu, số hữu hạn, vị trí và scene tồn tại. Giữ các field chưa biết khi lưu lại. Save legacy thiếu version vẫn được đọc theo version 1; version tương lai chưa hỗ trợ bị từ chối. Dùng [JSON.parse với xử lý lỗi](https://docs.godotengine.org/en/stable/classes/class_json.html), tránh spam lỗi parser khi UI kiểm tra một file hỏng.

## Vị trí chỉnh và source

- Điểm vào game/title: [save_manager.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/save_manager.gd:4>) — `TITLE_SCENE`, `NEW_GAME_SCENE`. Scene New Game cần Marker2D `SpawnPoint_Default`.
- Menu chọn slot/xác nhận: [menu (2).gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/menu (2).gd>) — `_open_slot_menu()`, `_on_slot_selected()`, `_begin_selected_game()`.
- Lưu/load/backup: [save_manager.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/save_manager.gd>) — `start_new_game()`, `load_game_from_slot()`, `save_at_campfire()`, `_replace_slot_bytes()`, `_read_valid_file()`.
- Khôi phục Adel: [playable_adel.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/adel/playable_adel.gd:360>) — `restore_checkpoint_state()`. Cập nhật anchor trước khi thoát Rest để không bị đưa về vị trí cũ.
- Menu pause hiện hành: [game_pause_menu.tscn](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/game_pause_menu.tscn>) và [pause.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/pause.gd>); được instance trong `PlayableAdel/Camera2D/UI_Layer/PauseMenu`.
- Campfire Save As/title: [campfire.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/Mechanic/campfire.gd>).
- Test luồng: [entry_save_validation.tscn](<D:/Godot Project/soujourn--echoes-of-the-soul/tests/flow/entry_save_validation.tscn>), controller cùng thư mục. Test từ chối chạy nếu không có user directory riêng mang tên CodexEntrySave20261014; không F6 test này trên project dùng save thật.

Scene pause legacy vẫn được giữ. Nó phụ thuộc hai file audio `res://zworld.mp3` và `res://metal-pipe-clang.mp3` đã mất; scene mới không phụ thuộc chúng. Không thêm hoặc chỉnh audio trong thay đổi này.

## Kiểm chứng

Godot thực tế dùng: `4.7.stable.official.5b4e0cb0f`.

- Repro trước sửa: Start xóa hai slot mẫu; đường dẫn scene không tồn tại — 4/4 kiểm tra thất bại.
- Repro sau sửa: 4/4 đạt.
- Luồng entry/save: 60/60 đạt, gồm slot selection/cancel/replace, Continue, HP/facing/position, pause/title/restart, campfire, failed write, corrupt save/backup, invalid schema/scene, same-scene và cross-scene respawn, bảo toàn bytes của slot không liên quan.
- Hồi quy: HFSM 31, stamina 94, jump damage 42, enemy detect 33 và death 20 kiểm tra. Tổng các suite nghiệm thu cuối: 284 checks headless; suite luồng còn chạy có render 60 checks. Đây là số assertions trong các lượt chạy, không tuyên bố tất cả đều là kịch bản độc lập.
- Smoke test boot bằng main_scene trong project.godot: Godot headless khởi động/thoát bình thường, không lỗi resource/script.
- Đã xem ảnh render của menu chọn slot và pause. Không thay đổi run floating, actor ordering, animation, hitbox, damage hoặc tuning stamina/slow motion.
- Suite stamina trước đó có bốn lỗi vì test dùng 1.5s cố định trong khi player scene đang override regen delay 1.0s. Đã tái hiện cùng bốn lỗi trên source trước sửa. Chỉ cập nhật thời gian chờ trong test theo cấu hình player; vẫn kiểm tra default 1.5s của model, và giữ scene override 1.0s.
- Cảnh báo Bone2D hiện có còn xuất hiện. Đây không phải playthrough cân bằng toàn game, không phải kiểm thử bản export hay đo hiệu năng.

Chạy lại trên bản sao của working tree với `work/stage_entry_save.py`, sau đó dùng `work/run_entry_save_tests.py tests/flow/entry_save_validation` trong workspace của chat. Runner dùng Godot với `--path`/`--log-file` tuyệt đối và user directory thử riêng. Bộ test chạm file lưu nên phải giữ cách ly này.

Bằng chứng: `Entry-save-flow-verification.zip`, các log baseline/final/render và ảnh `entry-save-new-game-slots.png`, `entry-save-pause-menu.png` trong outputs của workspace.

## Cập nhật campfire UI — 15/10/2026

F chỉ mở campfire; thoát bằng Leave. HUD được ẩn suốt lượt nghỉ; con trỏ chỉ hiện khi fade-in xong và menu sẵn sàng. Gameplay dùng MOUSE_MODE_HIDDEN, không capture ở tâm. Xem [báo cáo campfire UI](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/Bao_cao_ky_thuat/campfire_ui_report.md>) để biết trạng thái, khóa input và kiểm chứng mới.
