# Dark Sentinel — HUD và đặc tả đã duyệt

> Cập nhật sau refactor 16/10/2026: đã sửa ownership i-frame, chuyển stats/đồng hồ sang Player, gom dash vào module và cho defense bắt đầu ngay sau skid, không chờ cooldown. Xem [player_runtime_refactor_report.md](player_runtime_refactor_report.md). Nội dung và kết quả trước đó bên dưới là snapshot lịch sử; i-frame bug đã nêu trong snapshot nay đã có regression và được sửa.

Giao diện thực hiện ngày 2026-10-15. Cập nhật 2026-10-16: đã thêm rút máu 2% max HP mỗi giây game và chờ kết thúc hành động để thoát ở 1 HP; T/R/Y trên Player đã nối vào module gameplay tối thiểu. Chi tiết, giới hạn, dash và đánh giá kiến trúc: [player_dash_sentinel_architecture_report.md](player_dash_sentinel_architecture_report.md). Chưa có full chuyển dạng/vũ khí/kỹ năng/buff Sentinel hay tích ulti từ combat.

## Phần giao diện đã làm

- Thanh ulti nằm trên HP, đầy theo chiều ngang. Khi đầy có ba móng vuốt đỏ mỗi bên, chữ R và phần đen chuyển động chậm bằng shader.
- Cụm vũ khí Sentinel ở góc trái dưới: Q bên trái, E bên phải, kế tiếp là 1/2/3/4. Có nhãn phím, lớp hiển thị hồi chiêu và trạng thái thiếu tài nguyên/chờ thoát.
- Khi bật trình bày Sentinel: thanh HP đen, viền đỏ; ẩn vạch stagger. Khi tắt: khôi phục chính xác texture và vạch cũ. Đây chỉ là thay đổi hình ảnh, không phải miễn stagger trong combat.
- Dùng nguyên ảnh `res://asset/UI/Menu screen/dark conversion bar.png` qua AtlasTexture. Shader ẩn nền RGB(163,163,163); không sửa file ảnh gốc. Móng vuốt và các lớp HP là SVG riêng.
- Cụm kỹ năng thuộc CanvasLayer ScreenSpace hiện tại, không dịch chuyển theo camera hoặc zoom. HUD đầy ulti/Sentinel được giữ hiện; campfire vẫn ẩn toàn bộ qua cơ chế sẵn có.
- Hoạt ảnh cháy dùng delta thời gian game, dừng khi pause và chậm theo Engine.time_scale. Các lớp shader giữ đúng độ mờ của HUD.

## Xem thử và chỉnh giao diện

Mở `res://scenes/UI/previews/dark_sentinel_hud_preview.tscn`, nhấn F6. Các nút cho xem Thường, Ulti 50%, Ulti đầy, Sentinel, Chờ thoát và hồi chiêu/thiếu tài nguyên. Scene này chỉ dựng HUD độc lập, không đổi gameplay hay ghi save. Hướng dẫn xem thử tự ẩn ở viewport nhỏ để không chồng lên HUD.

Trong `res://scenes/UI/hud.tscn`, chọn node gốc `hud`, nhóm **Sentinel HUD Layout**:

- `Sentinel Loadout Scale`: kích thước toàn cụm dưới trái, mặc định 1.0; tự giảm để vừa màn hình.
- `Sentinel Screen Margin`: khoảng cách đến mép trái/dưới, mặc định (24,24).
- Vị trí thanh ulti: chọn `ScreenSpace/bar/hp_bar_panel/UltimateMeter` trong hud.tscn, kéo trực tiếp bằng công cụ Move hoặc chỉnh Layout → Transform → Position. Tăng X để cách xa bình máu; lưu hud.tscn. Runtime giữ nguyên vị trí đã lưu khi khởi tạo hoặc resize. Đã bỏ Ultimate Meter Offset trên node hud để tránh hai nơi cùng ghi vị trí.

Chỉnh từng ô và vị trí Q/E/1–4 trong `res://scenes/UI/sentinel/sentinel_loadout.tscn`. Node gốc có `Preview Active` để xem trong editor. Thay icon bằng AtlasTexture hoặc texture khác ở thuộc tính `Icon` từng ô; thay hình vũ khí ở WeaponArtwork.

Chỉnh `Meter Size` (mặc định 132x22), `Fire Speed` (0.35) và `Preview Charge` trên node gốc của `res://scenes/UI/sentinel/ultimate_meter.tscn`. Preview Charge chỉ dùng trong editor, không tự làm đầy ulti lúc chơi. Màu HP nằm trong hp_sentinel_fill.svg / hp_sentinel_rim.svg / hp_sentinel_track.svg.

## Interface hiển thị cho bước gameplay sau

Các phương thức sau nằm trên HUD hiện tại, `res://scenes/UI/ui.gd`:

```gdscript
hud.set_ultimate_charge(value, maximum) # Mặc định maximum = 100; chỉ trình bày.
hud.set_sentinel_active(active) # Đổi skin và hiện/ẩn cụm kỹ năng.
hud.set_sentinel_exit_pending(pending) # Làm mờ tất cả ô khi đang chờ thoát.
hud.set_sentinel_ability_presentation(slot, remaining, total, affordable, available)
# slot: &"Q", &"E", &"1", &"2", &"3", &"4".
```

HUD không đếm hồi chiêu, tính chi phí, nhận input kỹ năng hoặc tự tiêu hao ulti. Module gameplay sở hữu các giá trị này và gửi trạng thái tới HUD; module rút máu/chờ thoát đã có, skill/cooldown/chi phí còn chờ triển khai. Controller phải chủ động đặt charge = 0 khi tiêu hao ulti; gọi set_sentinel_active không tự làm việc đó. Khi rời dạng, các ô xóa trình bày hồi chiêu/cảnh báo cũ; controller vẫn sở hữu luật hồi chiêu thực tế.

Có phím debug T/R/Y để thử giao diện trong bản debug: T cộng 30 điểm (tối đa 100, chỉ ngoài Sentinel), R tiêu hao thanh đầy và bật hiển thị Sentinel, Y tắt hiển thị Sentinel. Trên Player thật, R nay bật module rút máu/chờ thoát và Y dừng module đó; HUD độc lập vẫn chỉ preview. Chưa có tự hồi đầy HP, full chuyển dạng chiến đấu, đổi vũ khí hay kỹ năng Sentinel. Các phím không hoạt động trong bản release, pause/menu/campfire, khi nhập văn bản hoặc giữ Ctrl/Alt/Meta; giữ phím không cộng lặp. Tắt bằng Debug Keys Enabled trên node SentinelDebugControls trong hud.tscn; chỉnh Ultimate Gain để đổi mức cộng 30. Scene xem thử vẫn có nút riêng để chuyển hình minh họa. Những giá trị HP/stamina trong scene xem thử là dữ liệu cục bộ phục vụ hiển thị.

## Luật gameplay người dùng đã duyệt — dành cho bước triển khai sau

1. R chỉ kích hoạt khi ulti đầy; tiêu hao thanh ulti, cố định vũ khí Sentinel, hồi đầy chỉ HP và cấm bình máu/đổi vũ khí. Không stagger trong dạng này.
2. Tự rút 2% HP tối đa mỗi giây theo thời gian game: dừng khi pause, chịu slow motion. Đường chi phí/tự rút không bị giảm bởi Toughness, guard hay i-frame.
3. Tự rút và chi phí kỹ năng không giết player; ngưỡng thấp nhất 1 HP. Sát thương enemy vẫn có thể giết.
4. Chiêu 1/2/3/4 dùng HP; thiếu HP thì không thể sử dụng. Q/E dùng stamina. Chưa chốt con số chi phí từng chiêu.
5. Chiêu 4 chủ động kết thúc và cấp Sharpness I. R không dùng để thoát. Thoát cưỡng bức không tự cấp Sharpness. Giữ HP tại thời điểm thoát.
6. Khi còn 1 HP giữa một hành động, đòn đánh hoặc kỹ năng: dừng tự rút, đánh dấu chờ thoát, đợi hành động đang diễn ra kết thúc. Defense không trì hoãn thoát. Trong lúc chờ không nhận combo hoặc kỹ năng mới; enemy vẫn có thể giết player. HUD làm mờ ô; module rút máu/chờ thoát đã khóa input combo/skill mới từ 16/10/2026.
7. Vào Sentinel xóa debuff cơ bản, ví dụ Bleed/Fracture; Poisoning được phân loại cơ bản khi triển khai. Bình máu có thể xóa nhóm cơ bản theo thiết kế tương lai. Debuff cao cấp cần điều kiện riêng; hiện chưa có loại cao cấp được triển khai. Bước HUD không sửa tác dụng bình máu/debuff hiện có.
8. Không tích ulti trong Sentinel. Tích công bằng theo tốc độ vũ khí được ghi nhận làm yêu cầu tương lai khi có thêm vũ khí; chưa triển khai chuẩn hóa trong bước này.
9. Q không có i-frame. E thường và E khi defense đều có i-frame, ngắn hơn dash; chưa chốt thời lượng.
10. Chiêu 1 cắm kiếm/đẩy lùi/Toughness. Chiêu 2 chém đánh dấu enemy đầu tiên, tái kích hoạt dịch chuyển/jump attack/hồi ít HP. Chiêu 3 kiếm phóng to/đập xuống, tụ lực tăng độ lớn/sát thương/chi phí HP, miễn choáng khi tụ. Chiêu 4 kết thúc/Sharpness I.
11. Q phóng xích kéo player tới enemy; chuột trái nối tiếp thành chém xoay. E thường dịch chuyển ngắn; khi defense đổi thành lao tới gây choáng/đẩy lùi.
12. Toughness giảm sát thương nhận, tạm vô hiệu hóa toàn bộ stagger threshold, giảm stamina Guard/Deflect. Sharpness tăng mọi sát thương gây ra. Các mức %, thời lượng, cooldown và chi tiết ngắt chiêu chưa được chốt; không coi những ví dụ trước đó là thông số đã duyệt.

## Kiểm tra

`res://tests/ui/sentinel_hud_validation.tscn` kiểm tra màu HP thực tế, alpha nền ảnh, chuyển động shader, pause/slow motion, nhãn phím, hồi chiêu, chờ thoát, khôi phục skin, độc lập dữ liệu giữa hai HUD, viewport 640x360, camera/zoom trong scene player thật và ẩn campfire. Test yêu cầu thư mục save tách biệt có tên CodexSentinelHUD20261015.

Có chạy Godot 4.7 thật ở chế độ headless và có render; ảnh kiểm tra là ảnh chụp từ viewport. Kết quả cụ thể và log được lưu trong gói kiểm chứng đi kèm. Các kiểm tra 15/10 ở mục này xác minh HUD. Kiểm tra rút máu/chờ thoát 16/10 và giới hạn gameplay còn lại được ghi riêng trong player_dash_sentinel_architecture_report.md.


## Sửa lỗi editor khi chuyển scene / kéo thanh ulti

Triệu chứng `canvas_item.cpp:1231: Condition "!is_inside_tree()" is true. Returning: Rect2()` được tái hiện bằng cách giữ node sống sau remove_child rồi phát viewport.size_changed. Callback _layout của SentinelLoadout còn được gọi khi node đã rời SceneTree; is_node_ready một mình không đảm bảo node đang nằm trong cây. _layout và _layout_hud nay kiểm tra is_inside_tree trước khi đọc viewport. Không cần thay đổi va chạm vật lý: hai hình HUD chỉ bị chồng hình.

Lỗi vị trí riêng biệt: ui.gd trước đây luôn ép UltimateMeter.position về (10,-42), ghi đè vị trí kéo trong editor. Đã bỏ lệnh đó và thuộc tính Ultimate Meter Offset. Vị trí lưu trên node UltimateMeter trong hud.tscn là nơi chỉnh duy nhất. Không tự thay vị trí hoặc sửa scene đang được người dùng căn chỉnh.

Test `res://tests/ui/sentinel_layout_validation.tscn` tái hiện lỗi trước sửa, kiểm tra callback khi rời cây, setter Inspector khi node rời cây, giữ vị trí được lưu, resize và tám vòng tháo/lắp scene. Log runner coi native ERROR là lỗi test. Test dùng thư mục save riêng CodexSentinelHUD20261015-LayoutFix.
