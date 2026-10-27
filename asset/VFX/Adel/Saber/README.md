# Adel Saber VFX

Bốn PNG là đúng bộ hình VFX trắng đã duyệt, dùng cho `saber_attack_1/2/3/4`.
PNG giữ nguyên nền đen và toàn bộ nét xước/quầng sáng. Shader chuyển độ sáng
thành độ phủ khi vẽ, nên trong game không xuất hiện hình chữ nhật đen.

Component: `SaberSwingVFX` trong
`asset/Character/Adel/adel spine action use.tscn`. Scene nhân vật chơi được
dùng chung rig này, nên tự nhận VFX.

## Chỉnh trong Inspector

Chọn node `SaberSwingVFX` trong rig. Danh mục tham số, đơn vị, mặc định script,
override scene và cách căn riêng từng đòn được quản lý tại
[hướng dẫn tuning chung — VFX bốn đòn Saber](../../../../Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#saber-vfx).
Đây là nguồn tuning duy nhất; README giữ mô tả cơ chế và cách kiểm tra.

## Nhịp và vòng đời

Thời điểm phát đọc từ key frame 1 của animation; lớp chính mất ở key frame 2
hoặc ngay khi chuyển animation. Gốc và hướng của vệt dư giữ theo lúc phát,
không chạy theo nhân vật hoặc lật theo đòn mới. Bên trong gốc cố định này,
đầu vệt vẫn đi tiếp theo cung; đuôi đuổi nhanh hơn, làm vệt ngắn và mỏng dần.
Từng vệt có material riêng.

Chuyển động kết thúc dùng `Time.get_ticks_usec()`. Shader nén toàn bộ nét vẽ
vào đoạn cung giữa đầu và đuôi đang chuyển động, đồng thời thu bề dày.
Nét xước co theo thân vệt; các nét mảnh và quầng sáng mất trước lõi trắng.
Độ đậm lõi được giữ trong phần lớn quá trình; chỉ mảnh rất nhỏ cuối cùng
mới giảm độ trong suốt. Ảnh PNG gốc giữ nguyên; các thông số riêng từng đòn
định hình lại vệt khi vẽ.

Hit-stop, freeze, thay đổi attack speed và chuyển animation không kéo dài
đồng hồ này.

Component chỉ xử lý hình ảnh; hitbox, sát thương và nhịp combat không thay đổi.

## Jump attack

Rig còn có component `JumpAttackVFX` cho `jump_attack(air)` và
`jump_attack(land)` (FALL theo cách gọi của người dùng). Component dùng lại
`saber_attack_1.png` để dựng cung trắng; khi đáp, cung ép tiêu xuống nền và
hai nét khí thấp dạt sang hai bên. Pha đáp không có khói hay lớp bọc kiếm riêng.
Khi giữ pose cuối AIR lao xuống, cung **Descent V6** màu `#b4b6be` mượt phủ một phần
lưỡi kiếm và bám Player; phần phình nằm thấp gần kiếm. Cung này dùng mesh và
`jump_attack_descent.gdshader`, không dùng brush bitmap, tắt khi LAND/ngắt đòn
và không sinh vệt dư dồn lên nhau. AIR ngắn và hiệu ứng đáp giữ cơ chế cũ.
Hướng dẫn tham số và thời gian thực nằm tại
[VFX jump attack](../../../../Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#jump-vfx).

## Saber Ready

`SaberReadyVFX` trong rig dùng lại nét trắng để dựng một nét vẩy ngắn trên đầu,
rồi cung mảnh phía trước tan nhanh. Bản Ready chỉ giữ pose cuối không phát vệt.
Các điểm bẻ cong, bề rộng, vị trí và tuổi thực được quản lý tại
[VFX Saber Ready](../../../../Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#ready-vfx).

## Kiểm tra

`tests/adel/saber_vfx_validation.gd` kiểm tra marker, hai lớp VFX, chuyển
animation, lật hướng, đầu/đuôi chuyển động, thu chiều dài/bề dày, giữ độ rõ
của lõi trắng, đồng hồ thực, CombatTime hit-stop, pause và cleanup.
Chạy bằng `--script` trong cấu hình riêng có user directory chứa
`CodexSaberVFX`; không chạy các bài kiểm tra bằng dữ liệu bản lưu thật.

`tests/adel/saber_vfx_capture.gd` điều khiển scene combat thật qua input game
và chụp cả hai hướng; nhận `-- --output=<thư mục ảnh>`.

`tests/adel/jump_descent_vfx_validation.gd` kiểm tra ranh giới chuẩn bị/rơi/đáp,
hit-stop, hướng, hủy và cleanup. `tests/adel/jump_descent_vfx_capture.gd` chụp
ảnh tĩnh hai hướng từ input/physics thật; cũng dùng thư mục dữ liệu thử riêng.
