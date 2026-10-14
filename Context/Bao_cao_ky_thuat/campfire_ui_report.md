# Campfire UI, input và con trỏ — 15/10/2026

Đã sửa luồng campfire để chặn các lượt vào/ra chạy chồng nhau, ẩn HUD trong giao diện nghỉ và quản lý con trỏ theo ngữ cảnh. Kiểm thử trên bản sao working tree với user data riêng; không đụng save thật. Không gen/import asset map, không sửa combat tuning hoặc animation nguồn.

## Hành vi

- F chỉ mở campfire khi player ở trong tầm và có thể bắt đầu nghỉ. Giữ F hoặc nhấn thêm trong lúc fade/menu/thoát không đóng campfire và không tạo thêm lượt lưu.
- Ngay khi nhận F hợp lệ, campfire giữ quyền điều khiển UI, đưa player vào Rest, ẩn toàn bộ CanvasLayer của HUD và ẩn con trỏ.
- Esc bị chặn từ lúc bắt đầu vào đến hết fade rời campfire, kể cả menu nâng cấp, Save/Load và hộp xác nhận ghi đè. Menu pause và master menu cũng từ chối mở trong thời gian này. Back/Cancel bằng nút trong menu con vẫn hoạt động; chúng không kết thúc lượt nghỉ.
- Chỉ khi fade-in vào đã hoàn tất thì menu nghỉ và con trỏ mới hiện. Save/load cùng scene giữ Rest, giữ HUD ẩn, ẩn con trỏ trong fade rồi hiện lại khi menu sẵn sàng.
- Thoát bằng Leave. Ngay khi bấm, mọi menu con và hộp xác nhận được ẩn, con trỏ ẩn. Player vẫn bị khóa và Esc vẫn bị chặn tới hết fade ra; sau đó HUD trở lại cơ chế hiển thị hiện có và player tiếp tục chơi.
- Gameplay dùng `Input.MOUSE_MODE_HIDDEN`: chỉ ẩn biểu tượng, giữ vị trí chuột và thao tác nút chuột; không capture ở tâm hoặc warp chuột. Pause/inventory ngoài campfire và title hiển thị con trỏ; Resume/đóng inventory/Continue đưa về con trỏ ẩn. [Hành vi MouseMode theo Godot](https://docs.godotengine.org/en/stable/classes/class_input.html#enum-input-mousemode).

## Nguyên nhân và sửa

Trước sửa, F bật qua lại giữa `_sit_and_save()` và `_stand_up()` trong khi mỗi hàm có các `await` fade riêng. Nhấn lần hai trước khi chuỗi vào hoàn tất cho phép player rời Rest, nhưng callback của chuỗi vào vẫn tiếp tục và gọi `rest_menu.show()`. Pause không có kiểm tra campfire đang sở hữu UI; Resume dùng CAPTURED và làm mất con trỏ cần cho menu campfire.

Campfire hiện có các phase IDLE/ENTERING/RESTING/LEAVING/LOADING/TITLE. Mọi thao tác kiểm tra phase; chỉ RESTING nhận các nút menu. Mỗi lượt có generation để callback cũ không thể khôi phục UI sau hủy, ngắt state hoặc đổi scene. Fade dùng thời gian thực và timer hữu hạn; hủy Tween không để coroutine đợi `finished` mãi. Các phím được chặn trước GUI/unhandled input; hộp xác nhận tắt `dialog_close_on_escape` của [AcceptDialog](https://docs.godotengine.org/en/stable/classes/class_acceptdialog.html#class-acceptdialog-property-dialog-close-on-escape).

Player giữ tham chiếu campfire đang sở hữu UI và trạng thái con trỏ có sẵn. Pause/master menu hỏi trạng thái đó; thay đổi chế độ chuột theo sự kiện, không polling/warp mỗi frame. Khi rời scene, campfire cũ không ghi chế độ chuột lên scene mới. Campfire bị xóa giữa lượt sẽ trả HUD và quyền di chuyển cho player còn sống.

HUD có CanvasLayer riêng nên chỉ hide Control cha chưa đủ. `set_campfire_hidden()` ẩn ScreenSpace, giữ xử lý HP, stamina và hiển thị dữ liệu nội bộ chạy bình thường. Heal/fade HUD không được làm lớp này hiện lại trong lượt nghỉ.

## Vị trí điều chỉnh

- [campfire.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/Mechanic/campfire.gd:9>): chọn Campfire trong scene → Inspector → **Transitions**. Giữ mặc định cũ: Enter Fade Out Duration 0.7s, Enter Fade In Duration 2.0s, Leave Fade Duration 0.5s cho mỗi nửa fade; Load Fade Duration 0.5s, Title Fade Duration 0.8s.
- [playable_adel.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/adel/playable_adel.gd:374>): `refresh_gameplay_cursor()` quản lý Hidden/Visible; `begin_campfire_ui()` và `end_campfire_ui()` quản lý quyền UI/HUD.
- [ui.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/ui.gd:200>): `set_campfire_hidden()` chỉ điều khiển lớp HUD, không ngừng stats.
- [pause.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/pause.gd>) và [master_menu.gd](<D:/Godot Project/soujourn--echoes-of-the-soul/scenes/UI/master_menu.gd>): khóa mở menu toàn cục khi campfire đang giữ quyền UI; cập nhật con trỏ khi mở/đóng ngoài campfire.

## Kiểm chứng

Godot 4.7.stable.official.5b4e0cb0f thực sự chạy trên bản sao project:

- Repro trước sửa: 4 kiểm tra thất bại, gồm menu hiện lại sau khi player thoát Rest và Esc mở pause trong campfire.
- Repro sau sửa: 4/4 đạt.
- Suite campfire mới: 58/58 headless; chạy có render 73/73, gồm 15 assertions riêng kiểm tra MouseMode native. Headless không được tính là bằng chứng chế độ con trỏ thực tế.
- Hồi quy: save/entry 60, HFSM 31, stamina 94, jump damage 42 và death 20 kiểm tra, đều đạt. Tổng lượt nghiệm thu headless: 309 assertions; không cộng lượt render thành số kịch bản độc lập.
- Có kiểm tra F qua Input.parse_input_event, spam các nút Leave/menu, 6 vòng vào/ra lặp, Esc trong các phase/menu con/native confirmation, HUD vẫn ẩn khi heal/regen, same-scene load, title/Continue, global slow motion và hủy/xóa campfire giữa fade. Đã xem ảnh render campfire có UI, không có HUD.
- Không có SCRIPT ERROR/engine ERROR trong log nghiệm thu cuối; cảnh báo Bone2D hiện có còn xuất hiện. Không tuyên bố playtest toàn game hoặc đo hiệu năng.

Test mới: [campfire_ui_validation.tscn](<D:/Godot Project/soujourn--echoes-of-the-soul/tests/flow/campfire_ui_validation.tscn>), controller cùng thư mục. Nó chỉ được chạy trên bản sao có custom user directory mang tên CodexCampfireUI20261015; từ chối chạm save của project thật.

Suite entry/save cũ được chỉnh một fixture: sau cross-scene respawn đang ở gameplay thì về title bằng SaveManager; không gọi hàm campfire khi chưa bắt đầu lượt nghỉ. Luồng nút title thật tại campfire được suite mới kiểm tra.

Chưa commit/push. Bằng chứng gồm source before/after, manifest, log baseline/final/render và ảnh trong `Campfire-UI-verification.zip` ở outputs của chat.
