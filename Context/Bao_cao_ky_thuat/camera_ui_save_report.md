# Camera, HUD, menu, campfire và save

Cập nhật: 17/10/2026. Báo cáo hiện hành đã gộp các bản thay đổi camera/UI/save. [Hướng dẫn tùy chỉnh chung](huong_dan_tuy_chinh.md) là nơi tra thông số. Kế hoạch camera rộng trước đây là phương án lịch sử đã được người dùng yêu cầu khôi phục; không coi mọi đề xuất trong kế hoạch đó là tính năng đang bật.

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

Nhấn/thả action target_lock (mặc định chuột giữa, có thể đổi ở Controls) chọn enemy gần Player nhất trong số có tâm hurtbox đang nằm trong camera. Nhấn ngắn lần nữa để hủy. Giữ rồi rê dùng target hiện tại làm gốc tìm theo hướng; vòng vàng xem trước, thả xác nhận; không tìm thấy thì giữ target cũ. Không có bán kính hay kiểm tra line-of-sight bổ sung ngoài luật trong khung hiện tại.

Khóa tại tâm collider thân EnemyBase, không lấy hitbox đánh. Khóa tắt mouse pan và kéo camera về enemy trong giới hạn cùng ellipse. Chết/xóa/ẩn/tắt hurtbox hoặc rời camera thì mất khóa và trả tâm, không tự đổi target khác. Sau mất khóa cần rê tiếp để lia lại. Chức năng chỉ điều khiển camera, không tự xoay Player hay hướng đòn.

Pause/menu tạm ẩn reticle và hủy thao tác đang giữ, giữ target đã xác nhận nếu còn hợp lệ. Campfire dùng camera riêng. Tùy chọn deadzone, auto reset on/off và delay có thể chỉnh trong Esc → Camera, lưu riêng ở `user://camera_controls.cfg`; ba giá trị đã lưu ưu tiên hơn mặc định scene. Không đụng slot checkpoint.

## 3. Zoom chiến đấu và thời gian

`HitStopCameraZoom` là pulse nhỏ tính theo thời gian thực không pause. Hit-stop thường của combo vẫn có nhưng đã tắt zoom của `saber_attack_1/2/3/4`. Guard/Deflect, Q và nguồn gọi hit-stop phù hợp còn có thể yêu cầu pulse; cấu hình/tình trạng stagger có thể từ chối pulse. Không suy ra mọi lần chậm game đều có zoom nhỏ.

Stagger và phản ứng thiếu stamina dùng `StaggerImpact`, với mức zoom/time riêng cho thiếu stamina. Q có ba bộ riêng và pha freeze trả zoom cho charge 1/2; xem [báo cáo Player](player_technical_report.md). Các nguồn zoom combat được phối hợp bằng mức lớn nhất, không nhân chồng thành zoom quá mức. Effect chỉ dọn nguồn của mình. Pause/resume/focus/đổi scene có cleanup.

Các trigger zoom map legacy vẫn tồn tại, có thể ghi trực tiếp camera.zoom. Chưa chuyển mọi trigger cũ vào cơ chế phối hợp; nếu gắn trigger mới cần kiểm tra tranh quyền với zoom combat. Không tự xóa các trigger/prototype cũ.

## 4. HUD thường và Sentinel

`res://scenes/UI/hud.tscn` có CanvasLayer ScreenSpace, bình máu, thanh HP/stamina, marker và icon status. `ui.gd` quan sát model của Player; preview độc lập dùng model cục bộ. Hiện/ẩn HUD hoặc thay skin không tự thay luật damage.

Thanh ulti trên HP đầy theo chiều ngang, khi đầy có ba móng đỏ mỗi bên và phần đen chuyển động bằng shader. Sentinel đổi HP thành đen/viền đỏ, ẩn marker và hiện loadout góc trái dưới: hình vũ khí, Q/E hai bên và slot 1–4 kế bên. Atlas/shader tận dụng ảnh gốc; không sửa ảnh nguồn. Các ô có trình bày cooldown/thiếu tài nguyên/chờ thoát nhưng không tự thực thi skill.

Dạng thường có `ScreenSpace/WeaponLoadout`, nguồn `res://scenes/UI/weapon/weapon_loadout.tscn`: Saber tay phải ở ô bên trái theo mẫu, ô tay trái ở bên phải để trống và ba placeholder vật phẩm rỗng ở giữa. Từ 17/10/2026 đã bỏ hình khiên, ô skill E và chữ Q/E dưới skill thường; icon Q dùng `skill.png`, kiếm dùng `saber1.png` do người dùng cung cấp, nguyên kích thước/góc chéo để lấp ô lớn hơn. Không thêm mana/Arts thường hoặc input C/Z. Khi vào Sentinel ẩn cụm thường, thoát thì hiện lại; dùng chung lề dưới/trái với cụm Sentinel, cùng fade/nháy hồi máu và quyền ẩn campfire. Cụm Sentinel và chữ phím của Sentinel được giữ nguyên.

Phản hồi nhận damage đã bỏ nháy đỏ: xóa tween `flash_red()` cùng các lời gọi ở luồng Vitals, HUD độc lập và tick Bleed trong `ui.gd`. Giữ `stagger_triggered` nối `_on_stagger_triggered()` để rung màn hình/bình máu như trước; không đổi damage, ngưỡng stagger, thông số rung, nháy hồi máu hoặc fade. Chỗ chỉnh cường độ rung được ghi trong [hướng dẫn chung](huong_dan_tuy_chinh.md#hud).

Đã sửa trường hợp `spine_enemy_test` còn hiện kiếm/khiên cũ: instance WeaponLoadout trong `hud.tscn` lưu override ảnh và layout cũ, ưu tiên hơn scene vũ khí gốc. Bỏ các override ảnh/kích thước cũ để kế thừa đúng asset, giữ vị trí kiếm đã căn. Lỗi scale tiếp theo đến từ hai export trùng ở HUD cha: `_layout_hud()` ghi đè `hud_scale` trên hai cụm khi khởi tạo và resize. Đã bỏ hai export và phép gán đó; mỗi cụm dùng **Hud Scale** lưu trên scene/instance của mình. HUD cha chỉ truyền lề chung và vùng chừa phía trên. Giữ nguyên giá trị người dùng vừa chỉnh, bao gồm override riêng trong `hud.tscn`; sửa scene gốc chỉ truyền xuống nếu instance không override. Vị trí/giá trị và cách Revert được ghi tại [hướng dẫn chung](huong_dan_tuy_chinh.md#weapon-hud).

Khung giữ PNG tác giả, vá phần thiếu bằng hai AtlasTexture từ viền gốc lật dọc. Layer 10 được chuẩn hóa alpha nguồn rồi hiển thị nền xám trong khung; shader lấy đối xứng từ phần trên nguyên vẹn để lấp chỗ khoét badge cũ ở dưới hai ô, nên bỏ skill E không lộ khuyết nền. Họa tiết giữa không bị đổi. Icon Q hiện là `res://asset/UI/HUD/skill.png`; bản sinh ảnh `saber_q_icon.png` từ lượt trước và các ảnh nguồn vẫn được giữ, không ghi đè/xóa.

Skill Q thường dùng `weapon_skill_slot.tscn` riêng: viền trắng khi sẵn sàng, xám khi hồi, lớp đen 60% rút từ trên xuống và số giây còn lại; mỗi instance có style/material riêng. Cooldown Saber Q đã nối vào gameplay: controller skill sở hữu đồng hồ, Player nối signal `cooldown_changed` vào `ui.gd.set_weapon_ability_presentation(slot, remaining, total)` và đồng bộ khi khởi tạo. HUD chỉ hiển thị, giữ cụm hiện trong lúc hồi để đọc số; pause/freeze dừng cả số và lớp phủ, ẩn HUD/campfire/đổi cụm Sentinel không reset hồi. Hết hồi trả viền trắng, xóa lớp đen và số. Chưa thêm chi phí stamina Q; gọi cho ô E đang vắng được bỏ qua an toàn. E và controller vật phẩm/Arts/mana còn chờ. Vị trí/giá trị và mốc tính hồi chỉ quản lý ở [hướng dẫn chung](huong_dan_tuy_chinh.md#weapon-hud).

Vị trí UltimateMeter do layout node trong hud.tscn sở hữu; runtime không ghi đè bằng một offset export thứ hai. Thay kích thước, kéo node, chuyển scene hoặc resize phải tránh gọi CanvasItem lấy rect trước khi vào cây. Source tool đã có kiểm tra vòng đời cho preview.

HUD cung cấp `set_ultimate_charge`, `set_sentinel_active`, `set_sentinel_exit_pending`, `set_sentinel_ability_presentation` và `set_weapon_ability_presentation`. Gameplay gửi dữ liệu, HUD không tự tính hồi chiêu/chi phí. Scene xem thử là `res://scenes/UI/previews/dark_sentinel_hud_preview.tscn` và `weapon_hud_preview.tscn`; đồng hồ cooldown trong preview thường chỉ để xem hiệu ứng.

## 5. Con trỏ, pause và campfire

Gameplay ẩn icon chuột bằng HIDDEN, không capture cố định. Khi B/Esc/menu hoặc đoạn có con trỏ được mở hợp lệ, con trỏ hiện ở giữa viewport; đóng lại thì ẩn. Thay mode theo sự kiện, không warp về tâm mỗi frame để không phá mouse pan.

Pause có nhóm **Debug - Skills** với công tắc **Skill cooldowns**. Tắt sẽ xóa hồi Q đang có và bỏ hồi cho các lần dùng sau tới khi bật lại; HUD nhận signal reset ngay cả lúc thế giới đang pause. Bật lại không tạo hồi cho chiêu cũ, chỉ khôi phục luật hồi khi tung chiêu tiếp theo. Trạng thái dùng chung trong phiên debug để menu tạo lại/đổi scene vẫn đồng bộ, không lưu vào checkpoint/config và không có tác dụng trong release. Thời lượng cooldown Inspector được giữ nguyên. Vị trí node/script và cách dùng ở [hướng dẫn chung](huong_dan_tuy_chinh.md#skill-q).

Campfire có phase IDLE/ENTERING/RESTING/LEAVING/LOADING/TITLE và generation chống coroutine fade cũ mở lại UI. F chỉ dùng mở campfire, không đóng. Từ lúc nhận F tới hết fade rời: khóa Esc và menu ngoài, ẩn HUD; chỉ hiện menu/con trỏ sau fade-in hoàn tất. Leave là cách rời; menu con có nút Back/Cancel riêng. Không để nhấn F nhanh tạo lượt vào/ra chồng nhau.

Campfire xóa giữa lượt hoặc đổi scene dọn quyền UI/cursor đúng chủ sở hữu. Hide HUD là hide CanvasLayer, không dừng model. Khi load cùng scene, giữ Rest và HUD ẩn, con trỏ chỉ hiện lại lúc menu sẵn sàng. Freeze trả zoom của Q có quyền pause riêng và chặn UI lấy quyền đó cho tới khi kết thúc.

## 6. Vào game và bảo toàn save

Title hiện hành là `res://scenes/UI/title_screen.tscn`, node gốc **TitleScreen**, script `title_screen.gd`; đã đổi tên từ `menu (2)`/`Node2D2`. Main Scene của project và `SaveManager.TITLE_SCENE` đều trỏ tới scene này; giữ UID scene và sidecar script qua đổi tên. Start chọn một trong năm slot: slot trống tạo game mới; slot có dữ liệu cần xác nhận Replace, Cancel giữ dữ liệu. New Game vào `res://scenes/Map 1/map_1_scene_2.tscn` và `SpawnPoint_Default`, không gọi opening scene đã mất. Chỗ chỉnh đích khởi động/Return to Title được ghi trong [hướng dẫn chung](huong_dan_tuy_chinh.md).

Continue chỉ cho load slot/schema/scene hợp lệ. Slot 1 dùng `user://soujourn_save.json`, slot 2–5 có hậu tố `_2`…`_5`. File chính lỗi nhưng `.bak` hợp lệ thì có thể đọc backup, không tự ghi lại file chính. Không có backup tốt thì giữ save hỏng và báo không khả dụng, không tự tạo tiến độ giả.

Ghi qua file `.tmp`, flush/kiểm bytes, giữ bản hợp lệ ở `.bak`, rồi replace file chính. Thất bại không cập nhật checkpoint như đã lưu; không lấy file chính hỏng đè backup tốt. Replace bởi New Game có bản `.before-new-game-<timestamp>-<ticks>.bak` riêng, không bị save checkpoint sau xoay mất. Đây là giảm rủi ro ghi dở, không phải cam kết chống mọi lỗi ổ đĩa/mất điện.

Pause có Resume/Restart Area/Return to Title. Restart reload map và checkpoint phù hợp, không ghi save. Load/respawn chờ scene/Player sẵn sàng rồi khôi phục vị trí, hướng, HP/flask/progression và dọn action/callback cũ. SaveManager và PlayerProgress ưu tiên model Player, có facade tương thích HUD cũ.

Campfire lưu vào slot phiên chơi; Save As đè slot khác cần xác nhận. F6 scene mà chưa chọn slot phiên chơi không được tự ghi đè slot cũ chỉ vì giá trị active mặc định. Saved chỉ hiện khi ghi thành công; lỗi load/ghi trả thông báo và giữ UI có thể tiếp tục.

### Cấu trúc title screen hiện hành — 17/10/2026

Đã triển khai từ review: root TitleScreen (Node2D) giữ nền Sprite2D/parallax trong Background; Interface (CanvasLayer) chứa Root/MainMenu, PressStartLabel, SettingsMenu và SaveSlotMenu; TransitionLayer phủ fade trên toàn bộ UI; Audio gom các AudioStreamPlayer không gian phẳng. BG đổi tên Logo; bỏ node BgSample ẩn và player âm thanh rỗng, giữ asset gốc.

`title_screen.gd` điều phối bằng enum Intro/AwaitingStart/RevealingMenu/MainMenu/Slots/Settings/Transitioning. Một tween trình bày được quản lý tập trung để hủy khi đổi trạng thái; nút chỉ nhận thao tác trong MainMenu, khóa trong lúc reveal/chuyển cảnh. Khi menu hiện, Start nhận focus; mở Settings khóa cả bốn nút phía sau, giữ focus trong Settings, đóng bằng Back/Esc trả focus Option. Prompt bỏ qua key echo và nhận action ui_accept theo Input Map. Project hiện chưa gán nút tay cầm cho ui_accept hoặc nghiệm thu thiết bị vật lý; remap bàn phím/chuột đã có trong Controls.

Bốn script nút trùng nhau đã thay bằng `title_menu_button.gd`, dùng SelectionHighlight cho hover/focus; reset scale khi ẩn/rời lựa chọn. SaveSlotMenu là scene riêng với layout authored, nhận mode và slot summaries từ title; phát signal chọn slot/ghi đè hoặc hủy. Xác nhận Replace nằm trong module trình bày này. SaveManager vẫn sở hữu đọc/ghi/backup/chuyển scene; giữ khóa chuyển lặp và phục hồi UI/âm lượng khi vào game thất bại.

Đã sửa lỗi Settings: tạo bus Music/SFX trong bus layout của project, gán đúng các player title, tra bus theo tên và đồng bộ slider từ gain/mute thực tế. Mức 0 mute, tăng lại bỏ mute; bus thiếu được kiểm tra an toàn. Có nền tối để Settings đọc được trên logo. Volume hiện chỉ giữ trong phiên chạy, chưa lưu config. General vẫn là nội dung mẫu; Controls đã có gán phím bàn phím/chuột và Video đã có cấu hình màn hình/hiệu năng. Chưa thay SystemFont Trajan Pro hoặc nghiệm thu font trên máy khác.

Settings đã phóng lớn và tự giữ trong viewport. Controls là scene riêng với danh sách cuộn của 13 thao tác gameplay, hai ô bàn phím/chuột, clear ô phụ, reset từng dòng/toàn bộ, hủy capture bằng Esc/nút Cancel và khi mất focus/ẩn. Có kiểm tra trùng, giữ ít nhất một binding, nhận modifier/chord, tooltip cho tên dài và giữ focus trong modal. Không thêm skill E/Arts/vật phẩm/tay cầm. Autoload InputBindings nạp/lưu cấu hình riêng `user://controls.cfg` và áp dụng vào InputMap khi khởi động; camera đã nhận action target_lock thay cho đọc cứng chuột giữa. Cấu hình không đi qua SaveManager. Danh mục tuning/default/override, cách dùng và ưu tiên config được ghi tại [hướng dẫn chung — Controls](huong_dan_tuy_chinh.md#controls-settings).

Video là scene `video_settings.tscn` riêng; VideoPreferences giữ cấu hình confirmed và snapshot runtime cho preview. Có Windowed/Borderless/Fullscreen, chọn kích thước cửa sổ, VSync, FPS cap, Apply/Revert/defaults. Chỉ thay đổi màn hình mới yêu cầu Keep; hết thời gian hoặc đóng/rời UI thì hoàn tác. Countdown dùng Time.get_ticks_msec và process Always, chạy qua pause/time scale; xác nhận quá hạn cũng bị từ chối. Performance-only Apply lưu trực tiếp. Cấu hình riêng `video.cfg` có file tạm/backup, chỉ lưu khi xác nhận hợp lệ; lỗi ghi trả runtime cũ. Root Settings giữ focus trong modal Video, Esc của popup không đóng cả Settings. Vị trí chỉnh/default/override và đơn vị ở [hướng dẫn chung — Video](huong_dan_tuy_chinh.md#video-settings).

Fullscreen dùng desktop resolution; Windowed dùng preset vừa usable rect, không liệt kê mode GPU hoặc thay resolution hệ điều hành. Giữ viewport/aspect của project khi đổi cỡ cửa sổ theo [Godot — Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html); mode/vsync dùng API [DisplayServer](https://docs.godotengine.org/en/stable/classes/class_displayserver.html). Chưa thêm render scale/brightness/quality presets, selector màn hình hoặc refresh rate.

Thời lượng title cũ được export tại Title Timing, bố cục slot chuyển sang scene; danh mục mặc định/override, đơn vị và cách chỉnh chỉ quản lý trong [hướng dẫn chung — Title screen](huong_dan_tuy_chinh.md#title-screen).

## 7. Kiểm thử và giới hạn

Các suite hiện có dưới `res://tests/camera/`, `res://tests/ui/`, `res://tests/flow/`; dùng bản sao project và user directory riêng. Các lượt triển khai trước có chạy Godot thật, bao gồm render/native cho con trỏ và ảnh HUD. Headless không chứng minh con trỏ hệ điều hành.

Lượt gộp tài liệu ban đầu không đổi code, scene, asset hoặc save và không chạy lại Godot. Lượt HUD vũ khí thường sau đó ngày 16/10/2026 đã chạy Godot 4.7 trên bản sao project/user directory riêng: `weapon_hud_validation` đạt **36 headless + 39 có render**, hồi quy `sentinel_hud_validation` **34**, `sentinel_layout_validation` **12**, tổng **121 assertions đạt** (có kiểm tra chạy lặp ở hai mode, không phải 121 kịch bản độc lập). Đã xem ảnh native của HUD thường, cooldown, Sentinel, viewport nhỏ và HUD trong scene Player thật; kiểm tra pixel nền lót/cooldown, ẩn/hiện và camera zoom. Cảnh báo rig có sẵn và lỗi không ghi shader cache trong sandbox vẫn có; không có script error ở các lượt xác nhận cuối. Không dùng save chơi thật, không nghiệm thu skill E/vật phẩm/mana/Arts hay cooldown gameplay chỉ từ preview. Không nhập asset map hoặc sửa audio legacy ngoài phạm vi.

Lượt chỉnh HUD 17/10/2026: suite `weapon_hud_validation` đạt **38 headless + 42 có render**, tổng **80 assertions**, trên bản sao project với user directory riêng. Đã xem lại ảnh render để xác nhận kiếm theo ảnh mẫu, icon `skill.png`, tay trái trống không còn skill/chữ phím, nền ô trống liền mạch và cooldown Q giữ đúng hiệu ứng. Suite cũng kiểm tra chuyển Sentinel, campfire, viewport nhỏ và camera zoom; không có script error trong lượt xác nhận. Giữ nguyên ảnh nguồn, gameplay và save chơi thật.

Lượt sửa override tiếp theo cùng ngày tái hiện được lỗi ở đúng luồng instance Player/HUD của `spine_enemy_test` trước sửa. Sau sửa, suite mở rộng đạt **41 headless + 45 có render**, tổng **86 assertions**; kiểm tra trực tiếp ảnh kiếm/tay trái/icon Q và scale trên HUD trong scene Player thật, đồng thời xem ảnh render tại scene đó. Instance trong editor đang mở cũng nhận đúng ảnh mới/tay trái rỗng. Vẫn dùng bản sao project/user directory riêng khi chạy game; không dùng save chơi thật.

Lượt sửa scale tiếp theo ngày 17/10/2026 tái hiện **4 lỗi trên 44 checks** trước sửa: scale đã lưu bị đổi khi khởi tạo, resize và trong luồng Player của `spine_enemy_test`. Sau sửa, `weapon_hud_validation` đạt **44 headless + 48 có render**, `sentinel_hud_validation` **34**, `sentinel_layout_validation` **12**, tổng **138 assertions đạt**. Kiểm tra so sánh trực tiếp runtime với giá trị scene trước `_ready()`, xác nhận giữ lựa chọn của người dùng và tự căn theo scale khi resize. Đã xem ảnh render HUD trong scene Player; chỉ chạy game trên bản sao project/user directory riêng, không dùng save chơi thật. Script HUD trong editor đã được reload tại chỗ và parse-validate, không force reload scene.

Lượt bỏ nháy đỏ cùng ngày: script được parse-validate/reload trong editor; đối chiếu source xác nhận không còn hàm/lời gọi `flash_red()` và giữ nguyên luồng rung stagger. Chạy lại suite có sẵn trên bản sao/user directory riêng: `weapon_hud_validation` **44**, `stagger_impact_validation` **49**, tổng **93 checks headless đạt**, không có script error. Đây là kiểm tra hồi quy HUD và phản ứng stagger, chưa phải nghiệm thu hình ảnh native riêng cho lượt bỏ nháy đỏ.

Lượt nối cooldown Q ngày 17/10/2026: `q_cooldown_validation` chạy trên Player thật trong `spine_enemy_test`, đạt **80 headless + 80 có render**. Kiểm tra timer gameplay và số/lớp phủ/viền HUD đồng bộ khi tung đòn, nửa hồi, hết hồi, pause/freeze, slow motion, ẩn HUD, đổi cụm Sentinel và checkpoint reset. Đã xem ảnh render đầu/nửa hồi từ gameplay; hồi quy HUD hiện có đạt thêm **44 checks**. Kiểm chứng combat và tổng toàn lượt được ghi trong [báo cáo Player](player_technical_report.md#8-kiểm-chứng-và-giới-hạn). Dùng bản sao/user directory riêng; giá trị Inspector của scene hiện mở được đối chiếu để giữ các override người dùng đã chỉnh.

Lượt thêm công tắc pause cùng ngày: suite `q_cooldown_validation` mở rộng đạt **107 headless + 107 có render**, hồi quy `enemy_debug_validation` có render **30**, tổng **244 lượt checks đạt**. Đã thao tác CheckButton thật qua signal trong menu pause: tắt xóa hồi/HUD ngay, ba mức Q sau không hồi, checkpoint/menu tạo lại giữ lựa chọn, bật lại dùng hồi của scene từ lần tung kế tiếp, không sửa save hoặc tuning. Đã xem ảnh pause native và kiểm tra toàn bộ nội dung gồm nhóm Skills nằm trong viewport. Lượt xác nhận cuối đưa cả override **4/6/8** người dùng vừa lưu vào bản sao; fixture timing chung vẫn dùng mặc định script 5/8/10, phần debug khôi phục và kiểm tra đúng override đã đọc. Game và APPDATA thử riêng; không dùng save chơi thật.

Lượt đổi tên title ngày 17/10/2026: `entry_save_validation` hiện có đạt **60 checks headless**, bao gồm Start/Continue, xác nhận Replace, pause Return to Title, campfire/load/respawn và bảo toàn slot. Chạy thêm startup mặc định từ `project.godot` trên bản sao xác nhận nạp `title_screen.tscn` và `title_screen.gd`, không có script/parse error trong lượt cuối. Đã sửa cache UID cũ trỏ script về tên đã đổi; editor đang mở root **TitleScreen**, script đúng đường dẫn mới. UID scene và byte script/sidecar được giữ nguyên; script chỉ đổi tên. Dùng project/APPDATA thử riêng, giữ tài liệu `.docx` và các file lịch sử của người dùng.


Lượt tổ chức lại title ngày 17/10/2026: `title_screen_validation` mới đạt **38 headless + 38 có render**, hồi quy `entry_save_validation` hiện có đạt **60 headless**, tổng **136 lượt checks** (hai mode UI có các check lặp, không phải 136 kịch bản độc lập). Kiểm tra mouse input thật vào Start/Settings, focus ban đầu và giữ trong modal, chặn handler phía sau Settings, Esc/Back, bus Music/SFX độc lập kể cả đổi thứ tự bus, mute/unmute, đồng bộ slider, mở/đóng slot, reset scale, chặn input lúc reveal, action ui_accept và Quit qua tween của title. Suite entry đã điều chỉnh sang interface scene slot mới, bao phủ Replace/backup, Return to Title và khôi phục UI khi Continue thất bại. Editor đã parse-validate/reload bốn script không có diagnostics và reload đúng scene title từ disk. Đã xem ảnh native menu chính, Settings có nền tối và màn slot; không có script error trong các lượt xác nhận cuối. Chỉ dùng project/APPDATA thử riêng, không sử dụng save chơi thật. Cảnh báo rig Bone2D legacy vẫn có trong suite entry; FMOD từng báo cổng live update bị dùng khi chạy hai process thử đồng thời. Chưa kiểm tra export, font trên máy khác hoặc tay cầm vật lý.


Lượt phóng Settings/Controls ngày 17/10/2026: `controls_settings_validation` đạt **54 headless + 54 có render**, thêm **2 + 2** checks ở hai process khởi động mới để xác nhận tự nạp controls.cfg vào InputMap. Kiểm tra click/gán thật, conflict không đổi map/file, Esc/Cancel không đóng Settings, secondary/Clear/reset, modifier đơn và chord, mouse side button, Tab giữ trong modal, config thiếu/sai/trùng, viewport nhỏ và không ghi save checkpoint. Đã xem ảnh native ở viewport 1920×1080 và 960×540. Hồi quy `title_screen_validation` đạt **38 headless**, `lock_camera_validation` đạt **39 headless**. Native camera xác nhận gán L và dùng L khóa enemy thật đều đạt; toàn suite native lần cuối **58 checks, 2 fail** ở assert vị trí/rê con trỏ Windows. Đối chiếu trên bản sao với handler chuột giữa cũ và fixture chưa thêm remap cũng fail cùng nhóm pointer (**56 checks, 3 fail**); không coi toàn bộ camera native là đã nghiệm thu sạch, không đổi luật pan để ép test qua. Bốn script hệ thống được parse-validate/reload, scene title cập nhật trong editor; các lượt Controls cuối không có script error. Tất cả game/config thử dùng project và APPDATA riêng, không dùng save hoặc controls.cfg chơi thật. Không kiểm thử tay cầm, export hoặc bổ sung tab General/Video.


Lượt triển khai Video ngày 17/10/2026: `video_settings_validation` đạt **37 headless + 41 native OpenGL Compatibility**, thêm **2 headless + 4 native** ở process mới xác nhận nạp lại mode/kích thước, FPS cap và VSync; tổng **84 lượt checks**, có các kịch bản lặp giữa hai mode. Đã đổi Windowed/Borderless/Exclusive Fullscreen thật, xác nhận/revert bằng nút và Esc, kiểm tra pending không ghi config, giữ viewport/aspect, backup, lỗi ghi file, staged defaults, kích thước lưu quá lớn, rời tab/đóng Settings/dọn scene và không sửa checkpoint. Timeout đã chờ đủ 15 giây thực trong cả hai mode với SceneTree.paused=true và Engine.time_scale=0.01. Đã xem ảnh native trang Video và overlay xác nhận. Hồi quy headless: title **38**, Controls **54**, entry/save **60** đều đạt; chạy thêm reader Controls **2** để xác nhận/reset fixture sau hồi quy. Ba script Video/backend/Settings parse-validate và reload trong editor không có diagnostics, title scene nạp lại đúng cấu trúc. Các lượt xác nhận cuối không có script error; cảnh báo rig legacy còn trong suite entry. Chỉ dùng bản sao project và APPDATA/user directory riêng, không dùng video.cfg/controls.cfg hoặc save chơi thật. Chưa benchmark FPS/tearing, chưa kiểm tra native Forward+/D3D12, export, nhiều màn hình/hotplug hoặc mọi tỷ lệ màn hình.
