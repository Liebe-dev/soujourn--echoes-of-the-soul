# Bàn giao animation / VFX combat Adel

**Snapshot: 26/10/2026, Asia/Saigon.** Project: `D:/Godot Project/soujourn--echoes-of-the-soul`.
File này ở `D:/Godot Project/soujourn--echoes-of-the-soul/Context/Tai_lieu_ban_dao/HANDOFF_anim.md`.

## Cập nhật 27/10/2026 — VFX jump attack đã duyệt và tích hợp

Phần snapshot 26/10 bên dưới vẫn là lịch sử bốn đòn Saber. **Ưu tiên source và
cập nhật này cho jump attack**. Người dùng đã duyệt bản preview
`adel-jump-preview-2026-10-27-v4-minimal-crush/final/`, sau các lần sửa:

- AIR frame cuối đúng và được giữ. FALL là cú chém từ trên xuống dập đất,
  cần chân cung dày chạm nền và phản ứng không khí dưới chân.
- Bản có smoke nhiễu/xám và lớp kéo riêng để che kiếm bị loại: khói lạc phong
  cách, quá nhiều chi tiết. Bản chỉ co đuôi cung vẫn trông như slash thường.
- Bản chốt: **bỏ smoke và lớp bọc kiếm**, cung chính ép thấp tiêu xuống đất;
  hai nét khí trắng sát chân dạt sang hai bên rồi đứt mỏng. Không sửa frame PNG.

Đã gắn **`JumpAttackVFX`** vào
`asset/Character/Adel/adel spine action use.tscn`, nên Player dùng chung rig tự
nhận hiệu ứng. Script mới `scenes/adel/components/jump_attack_vfx.gd` và ba shader
`jump_attack_air.gdshader`, `jump_attack_crush.gdshader`,
`jump_attack_ground_air.gdshader` dùng lại `asset/VFX/Adel/Saber/saber_attack_1.png`.
Bốn đòn Saber/scene tuning của người dùng không đổi. Component chỉ đọc clip/frame
và sàn; không sửa Player/combat/hitbox, damage hoặc timing nguồn.

Tên “FALL” người dùng dùng tương ứng **`jump_attack(land)`** trong source.
Mốc frame thật: AIR frame 1 tại 0.18s; LAND frame 2 tại 0s, frame 3 tại 0.025s.
Phát một lần mỗi clip; tuổi là thời gian thực, không bị kéo dài bởi hit-stop,
freeze, pause hoặc đổi animation. LAND giữ transform thế giới lúc sinh; AIR có
lớp gắn pose ngắn và vệt dư riêng. Khi Player có tiếp xúc sàn, căn điểm tiêu cung
và khí vào sàn thật; khi xem rig độc lập dùng Y=923 pixel nguồn.

Chỗ chỉnh: **rig → JumpAttackVFX** hoặc **Player → SpinePivot/SpineRig/JumpAttackVFX**.
Danh mục duy nhất về default/override/đơn vị:
`Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#jump-vfx`. Hiện không có override
tham số của node mới trong rig/Player/map.

**Kiểm tra thực chạy trong lượt tích hợp**: `tests/adel/jump_vfx_validation.gd`
**33 checks, 0 failures**, gồm marker, hai hướng, world anchor, bỏ lớp bọc kiếm,
capacity/cleanup, near-zero time scale, CombatTime hit-stop và pause. Hồi quy
Saber **68/68**, jump damage **42/42**. Capture
`tests/adel/jump_vfx_capture.gd` điều khiển Player bằng input thật: **nhảy rồi
giữ xuống + đánh**, hai hướng; cú trái yêu cầu CombatTime hit-stop 120 ms.
Đã bắt đủ AIR/LAND hai hướng, sai số Y giữa khí và tiếp xúc sàn **0 world pixel**
trong scene phẳng thử, cuối lượt không còn VFX. Không coi đây là test trùng khít
pixel VFX/hitbox hoặc mọi nền/slope/camera.

Bằng chứng ở:
`C:/Users/xuank/.codex/visualizations/2026/10/25/01a170fc-5832-7430-b538-78ebad4ad7b3/adel-jump-integration-2026-10-27/`.
`gameplay-v2/` là capture thành công (262 ảnh có timestamp và bốn pose); thư mục
`gameplay/` cũ là lượt harness nhấn attack thường do thiếu giữ xuống, **không dùng
làm bằng chứng jump VFX**. Các log `jump-tests*`, `saber-regression*`,
`jump-damage-regression*`, `capture-v2*` là kết quả lượt này. Cấu hình/save thử
riêng, không dùng save chơi thật. Rà tham chiếu vẫn ghi lỗi UID dialogue/BG cũ
và 8 warning legacy đã nêu trong snapshot; không có tham chiếu VFX mới hỏng.

**Còn chờ:** phản hồi sau khi người dùng chơi bản tích hợp; VFX ready và skill Q
chưa được thiết kế/duyệt hoặc triển khai trong lượt này. Không suy ra lệnh “duyệt”
cho jump thành quyền làm các VFX còn lại. Chưa commit/push.

## 1. Tiếp quản nhanh và mức độ bằng chứng

1. Đọc `Context/Tai_lieu_ban_dao/AGENTS.md` và `HANDOFF.md`, sau đó đối chiếu Git/source/scene trước khi sửa. Các đường dẫn `res://...` trong file này tính từ project gốc nêu trên.
2. Công việc chính hiện tại là **bốn VFX trắng cho `saber_attack_1/2/3/4`**, trên rig `res://asset/Character/Adel/adel spine action use.tscn`. Đã tích hợp **phương án 2**: lớp gắn frame + vệt dư độc lập. Không còn là bản plan chưa tích hợp.
3. Thay đổi hình học gần nhất đã hoàn thành: **đòn 3 kéo dài về sau, nâng lên ngang vai, phẳng và chỉ hơi nghiêng**, đi ngược đòn 4. Đã gửi ảnh/gameplay cho người dùng. **Chưa có phản hồi nghiệm thu thị giác cuối cùng của người dùng sau bản này**; yêu cầu tiếp theo là viết bàn giao, không phải thêm một hiệu ứng mới.
4. Nguồn tuning duy nhất: `Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md`, mục **VFX bốn đòn Saber**, anchor `saber-vfx`. Đọc cả mặc định script và override scene; không đặt lại số người dùng đã căn.
5. Xem bằng chứng mới nhất ở mục 7; dùng thư mục `saber-attack3-shoulder/final`, không lấy các preview cũ làm kết quả hiện hành.

Phân biệt các mức sau trong toàn bộ bản bàn giao:

- **Xác minh lúc bàn giao:** đã đọc file/source, Git, override hiện hành, đường dẫn và nội dung báo cáo. Lượt viết bàn giao chỉ sửa tài liệu, sao chép ref nguyên vẹn; không chạy lại game/test.
- **Kiểm thử lịch sử có bằng chứng:** các lượt thực sự chạy trước đó trong chat, có log/ảnh/GIF tại vị trí ghi dưới. Không có nghĩa mọi thay đổi ngoài phạm vi vừa xuất hiện trong checkout đều đã được test lại.
- **Quan sát video:** những đoạn đã xem/tiến từng ảnh trong lượt nghiên cứu; không phải đã xem trọn mọi video.
- **Phân tích/giả thuyết:** kết luận thiết kế từ hình ảnh, cần đánh giá trong game; không phải mô tả mã nguồn nội bộ của Limbus.
- **Yêu cầu người dùng:** giữ nguyên ý định dù nó không trùng cơ chế thật của Limbus. Kết quả kiểm tra kỹ thuật không thay cho việc người dùng thấy VFX đẹp/hợp kiếm.

## 2. Mục tiêu, yêu cầu và quyết định đã chốt

### Điều người dùng muốn đạt được

- Combat theo hướng Limbus Company: **dứt khoát, mạnh, có sức nặng vũ khí**, không nhiều màu hoặc hiệu ứng rối mắt. Palette VFX là **trắng**, có xám trung tính/quầng sáng tiết chế; ref vàng chỉ dùng cấu trúc nét, không lấy màu vàng.
- Người dùng thấy FBF hiện tại **đã đủ dứt khoát và nặng**. Điểm yếu là cảm giác hơi khựng và thiếu hình mô tả quỹ đạo/vùng đánh. Mục tiêu VFX là bù chuyển động giữa các pose, không mặc định thêm frame thân người hoặc làm animation mềm đi.
- FBF ba frame: chuẩn bị → motion blur mạnh, gần pose cuối → tư thế cuối. Không có đủ ảnh để đọc toàn bộ vùng quét kiếm; vệt phải giúp người chơi hình dung tầm đánh và hướng lực.
- Vệt là **một cung/lưỡi liềm liền khối**, có cạnh cắt rõ, đầu/đuôi thuôn; xước mảnh chạy theo cung và glow vừa phải. Không tách thành nhiều vệt phụ độc lập hoặc vòng sáng trang trí làm mất đường chém chính.
- Vệt dư phải chuyển động/biến mất từ đuôi, không đứng theo freeze/hit-stop; có thể sống qua đổi animation/đòn tiếp, nhưng hết sớm để đòn mới vẫn rõ.
- VFX cần theo **đường kiếm, mặt phẳng vung và vai**, không chỉ phủ đủ một hình hộp phía trước. Độ dài X, độ cao cung Y và bề dày nét là ba việc khác nhau.

### Hai phương án từng đề nghị và trạng thái thật

- **Phương án 1 / A:** chỉ vệt độc lập tự tan/thu. Đây vẫn là hướng đối chiếu thiết kế; chưa có bằng chứng một đợt A/B có kiểm soát đã chọn được bản thắng.
- **Phương án 2 / B — hiện đang dùng:** lớp theo frame làm rõ đỉnh chém, mất ngay khi hết frame được chọn/đổi animation và không fade; vệt dư nhẹ/ít chi tiết hơn tiếp tục chuyển động và thu lại độc lập.
- Hai lớp là **Sprite2D riêng trong game**, không vẽ đè vào ba PNG frame nhân vật. Cùng dùng bitmap slash của từng đòn; shader/độ đậm/detail khác nhau giữa hai lớp. Không có hai bộ bitmap riêng bắt buộc cho hai lớp.
- Người dùng đã nhiều lần chuyển từ plan sang lệnh thực hiện; phần VFX và các sửa hướng/hình học nêu dưới đã được cho làm. Khi người dùng nói plan/chưa làm ở nhiệm vụ mới, tiếp tục giữ giới hạn đó. Bản bàn giao không tự cấp quyền mở rộng camera, hit-stop, damage, hitbox, Q hoặc animation khác.
- Không có mode A/B hoàn chỉnh trong UI. Đặt Attached Opacity về 0 chỉ là cách thử tắt lớp chính; chưa tương đương một nghiên cứu A/B đã cân lại đầy đủ lớp dư.

### Hướng bốn đòn: ưu tiên mô tả mới nhất của người dùng

- **Đòn 1:** chém từ **trên xuống**. Đã lật hình/cung theo Y bằng `attack_flip_v[0] = true` để đầu/đuôi đi xuống. Không phục hồi chiều lên của ảnh/preview cũ.
- **Đòn 2:** giữ hướng và hình học đang có; không được chỉnh ké khi sửa đòn 3.
- **Đòn 3:** người dùng mô tả từ tay phải về phía trái nhân vật, với hướng mặc định nhìn sang phải màn hình; gần mặt phẳng chém của đòn 4 nhưng **ngược chiều**, ngang vai, hơi nghiêng. Kiểm chứng hiện tại khi nhìn phải: đầu nét dày ở trái, đuôi nhọn ở phải, dòng thu đi về trái; nhìn trái phản chiếu tương ứng. Đây là mô tả hình màn hình đã kiểm tra, không phải quy ước tay trái/phải có thể áp bừa cho mọi pose.
- **Đòn 4:** chém ngang vai từ phía trái ra phải theo mô tả người dùng. Hướng đã được người dùng xác nhận đúng; cung phải **mảnh và ngang**. Ở lượt sớm người dùng từng sửa ý hiểu sai rằng vệt đi ra sau; chỉ đạo ngang vai về sau thay thế concept vòm cao trong các prompt ảnh cũ.
- Chỉnh mới nhất cho đòn 3: tăng X nhưng **neo phía trước** để phần thêm kéo về sau; nâng lên và giảm độ vồng. Không chỉ kéo scale từ tâm vì sẽ nới cả tầm trước không chủ đích.

## 3. Những gì học từ ref và phản hồi

### 3.1. Ref Limbus đã xem và điều thực sự quan sát được

Báo cáo đầy đủ: `Context/Bao_cao_ky_thuat/nghien_cuu_animation_combat_limbus.md`.
Đầu báo cáo và phần kế hoạch A/B giữ trạng thái lịch sử lúc khảo sát 25/10/2026, có câu “chưa thay đổi code/chưa chọn bản thắng”. Dùng phần đó làm lịch sử nghiên cứu; **trạng thái triển khai hiện tại theo mục 2 và source**, không coi toàn project vẫn đang plan.

- GIF người dùng gửi: `refs_anim/w_corp_meursault_skill_3.gif` cạnh file bàn giao này; bản gốc `D:/Downloads/W_Corp._L2_Cleanup_Agent_Meursault_Skill_3.gif`. Là đối chiếu cảm giác ra đòn/lưu vệt, không phải bộ timing đã đo để chép thẳng.
- **Sinclair — Crimson God:** https://www.youtube.com/watch?v=Gpj-lvOnAgs&t=104s, đoạn khoảng **1:44–1:45**. Cung đỏ lớn đổi hình/cường độ qua các ảnh kế tiếp, điểm lóe trúng mục tiêu có hình riêng, pose nhân vật ít đổi hơn VFX. Học được cách VFX tiếp tục dẫn mắt quanh pose rõ; không lấy lượng hạt/độ phủ/màu của bộ này làm mức trang trí cho Adel.
- **Don Quixote — Le Noir Brand Manager:** https://www.youtube.com/watch?v=Hc6CJXJrzME&t=30s, khoảng **0:30–0:31**. Động tác vung búa chuyển sang đưa người lên cao; dải sáng chéo còn hiện rồi thu/đứt/thưa trong phần tiếp nối. Pose sau vung rõ và giữ lâu hơn phần chuyển động phụ. Đây là quan sát hình, chưa chứng minh node hoặc clock độc lập.
- **Rodion — Alteration Shop:** https://www.youtube.com/watch?v=GIe7Fna5LD4&t=27s, khoảng **0:27–0:28**. Thân giữ động tác giơ tay khá ổn định trong khi cấu kiện/lưỡi phía trên và cung trắng đổi hình/hướng. Học cách chuyển động phụ giữ nhịp khi thân ít frame; không nhầm cấu kiện trên cao với quỹ đạo kiếm cầm tay.
- **Hong Lu, preview chung với Heathcliff:** https://www.youtube.com/watch?v=jWYcZpYtdls&t=85s, khoảng **1:25–1:26**. Cung vàng và lóe trúng mục tiêu tách hình; cung rộng trở thành nét mảnh rồi mất trong khi pose/camera chuyển. Không đủ bằng chứng phân biệt shader, texture FBF hoặc nhiều lớp sprite. Tại ngày khảo sát, đây là preview cho extraction 29/10/2026, không phải gameplay sau phát hành.
- **Don trong gameplay thực tế — Kritzkingvoid:** https://www.youtube.com/watch?v=8CMs_ij_dMU&t=48s, khoảng **0:48–0:55**. Đã thấy UI trận, nhịp lên đòn, vệt/búa, lóe tại chỗ trúng và camera theo va chạm. Có nút tốc độ **MAX** trong đoạn lựa chọn: dùng để đối chiếu thứ tự hình, không lấy số giây thành timing tốc độ thường.
- Catalog đã tìm còn có Outis https://www.youtube.com/watch?v=BF_ULinL-jU và Ryōshū https://www.youtube.com/watch?v=G3Pi7V_-DH0 / https://www.youtube.com/watch?v=LkLhzmoJZ6Y cùng các video/compilation Meursault trong báo cáo. **Tìm được metadata/link không đồng nghĩa đã xem và phân tích từng đoạn**; không gán kết luận quan sát trực tiếp cho toàn catalog.

Các bài học thiết kế rút ra — là phân tích, không phải “quy tắc nội bộ Project Moon”:

1. Phân bố thời gian không đều: chuẩn bị/kết đủ rõ, đoạn chuyển qua quỹ đạo có thể rất ngắn. Với Adel giữ ba pose và nhịp hiện có trước khi nghĩ tới thêm frame.
2. Mượt cảm nhận có thể đến từ vũ khí/cung chém/chi tiết phụ tiếp tục biến đổi quanh pose mạnh. Không cần nội suy cả thân để sửa cảm giác khựng.
3. Tách chức năng **đường chém** khỏi **phản hồi va chạm**. Vệt xuất hiện cả khi chém hụt; flash/impact ở mục tiêu chỉ nên thêm khi hit được xác nhận. Vệt Saber mới chưa phải một hệ impact mới.
4. Vệt cũ phải hạ vai trò nhanh sau đỉnh chém: ngắn/mảnh/ít nét hơn, tránh cạnh tranh với đòn kế. Không có lifetime chung nào đã đo đáng tin từ video.
5. Độ nặng phối hợp pose, chuyển động cả người/vũ khí, tiếp xúc, phản ứng địch và camera. Chưa có thử nghiệm tắt từng thành phần nên không định lượng phần đóng góp.
6. Các nhân vật mới có mức trang trí khác nhau. Học cấu trúc thông tin/nhịp, giữ palette trắng và mức tiết chế do người dùng đặt ra.

**Giới hạn cần giữ:** không suy ra số frame tác giả vẽ, duration hit-stop chuẩn, unscaled time, một shader chung, node sống qua đổi clip hay hitbox thật của Limbus từ trailer/GIF. Giữ pose nhưng VFX đổi có thể là hình được dựng sẵn. Các bước tiến frame của player không phải phép đếm frame artwork.

### 3.2. Video After Effects: cách vệt biến mất

Nguồn người dùng yêu cầu xem: https://www.youtube.com/watch?v=WCWH8AnEvbI .
Ghi nhận từ lượt xem/tiến khung video trong lịch sử chat, **không xem lại video trong lượt viết bàn giao**; chưa lưu phép đo timing/timestamp chi tiết thành báo cáo repo.

- Quan sát được cách **Mask Path** kéo hình/dải từ dạng gọn ra dài rồi co lại trong lúc tiếp tục đi; **Polar Coordinates** biến đường/dải thành cung.
- Điều người dùng gọi “fade out” thực chất cần **chuyển động kết thúc và thay hình**, không chỉ alpha giảm đều trên một lưỡi liềm đứng yên.
- Hướng áp dụng: đầu vệt đi thêm một đoạn; đuôi đuổi nhanh hơn; khoảng cung giữa chúng ngắn dần; bề dày cũng co. Xước/nét bên trong phải đi/co cùng khối, không chỉ lộ qua mép mask đang cắt ảnh tĩnh.
- Các chi tiết yếu/glow mất trước; lõi trắng giữ độ rõ phần lớn thời gian, chỉ mảnh rất nhỏ cuối cùng mới giảm alpha. Nhờ vậy không thành một mảng xám lơ lửng sau đòn.
- Đây là **chuyển thể thị giác sang Godot**, không phải đã sao chép nguyên project AE hoặc chứng minh Limbus dùng kỹ thuật AE này.

### 3.3. Phản hồi của người dùng đã thay đổi cách thiết kế

- Preview ban đầu quá đơn giản/chưa thể hiện vùng đánh. Người dùng cung cấp bốn ảnh: **hộp xanh là hitbox giả định**, mảng đỏ chỉ gợi vị trí/hướng/tầm/hình. Được phép bóp méo/ghép đường để ra một cung tốt hơn; không chép nguyên hình đỏ hay lấy màu đỏ.
- Chỉ giữ vệt gần lưỡi kiếm không đủ mô tả vùng quét giữa ba frame. Nhưng phủ hộp hitbox bằng một cung không bám kiếm cũng không đạt; đây là lý do người dùng tiếp tục sửa hướng và mặt phẳng đòn 3/4.
- Người dùng yêu cầu một lưỡi liềm **dứt khoát và liền mạch**; các ref trắng gợi cạnh sắc, thân sáng, groove theo cung, glow tiết chế. Ref vàng dùng độ thuôn/cấu trúc, không dùng palette.
- Người dùng phân biệt **preview hình khối** với **sản phẩm thị giác dự kiến trong game** và yêu cầu ảnh chỉ có VFX, ở lúc dài nhất, đủ mọi lớp dự định. Không được hứa mơ hồ “vào game sẽ đẹp hơn” khi ảnh chưa thể hiện thiết kế cuối.
- PNG hoàn thiện đã được sinh trước tích hợp. Sau đó vẫn phải hiệu chỉnh biến đổi trong game: đúng bitmap không tự đảm bảo đúng hướng, đúng chiều thu hoặc đúng mặt phẳng vũ khí.
- Hướng không chỉ là dấu sweep: người dùng thấy ngược cả vệt lẫn cách mất. Phải kiểm tra **đầu dày/đuôi nhọn ở ảnh bung hết** và **hướng chuyển động lúc thu** cùng lúc.
- Đòn 4 cần tách “dài cung theo Y” với “bề dày nét”: ép phẳng toàn hình và giảm stroke width là hai chỉnh khác nhau. Đòn 3 về sau cần cùng logic ngang vai, ngược hướng, dài về sau, hơi nghiêng.

## 4. Triển khai hiện hành và vị trí tìm file

### Source, scene và tài nguyên thật trong repo

- Rig nguồn: `res://asset/Character/Adel/adel spine action use.tscn`; node **SaberSwingVFX**, cạnh **TestAttackSprite** và **AnimationPlayer**.
- Player thật: `res://scenes/adel/playable_adel.tscn`; đường node **SpinePivot/SpineRig/SaberSwingVFX**. Scene thử: `res://scenes/enemy/spine_enemy_test.tscn`.
- Điều khiển/lifetime/phép căn: `res://scenes/adel/components/saber_swing_vfx.gd` (`class_name SaberSwingVFX`).
- Shader: `res://scenes/adel/components/saber_slash.gdshader`; có file `.uid` tương ứng.
- Bốn bitmap: `res://asset/VFX/Adel/Saber/saber_attack_1.png`, `saber_attack_2.png`, `saber_attack_3.png`, `saber_attack_4.png`, cùng `.import`. Bitmap 1429×1101, trắng/xám trên nền đen; shader chuyển độ sáng sang alpha. Không coi chúng là PNG đã có alpha trong suốt để thay shader tùy ý.
- README cơ chế: `res://asset/VFX/Adel/Saber/README.md`, đã trỏ về hướng dẫn tuning chung.
- Sprite nhân vật: `res://asset/Character/Adel/Saber attack/mov_1_1.png` … `mov_1_4.png`; sheet 4113×976, chia ba ô 1371×976. `TestAttackSprite` có `hframes=3`, scale hiện `(1.007,1.007)`, position `(533,516.99994)`, z-index 50.
- Hitbox thật: `res://scenes/adel/components/saber_hitbox.gd`; node Player **WeaponPivot/SaberHitbox/Hitbox/CollisionShape2D** và **WeaponPivot/SaberHitbox/AnimationPlayer**. Code VFX không đổi collider, damage hoặc xác nhận hit.

`saber_attack_1/2/3` hiện dài `0.6s`, đòn 4 `0.75s`; frame 0/1/2 ở `0 / 0.15 / 0.20s` của animation. Các hằng `ATTACK_INTERRUPT_TIME=0.40`, `ATTACK_4_INTERRUPT_TIME=0.55` ở `res://scenes/adel/playable_adel.gd`. Đây là đọc source, không coi số giây game này là clock vệt dư.

### Cơ chế hai lớp

- `_read_markers()` đọc track `TestAttackSprite:frame`. `_sample_animation()` sinh một vệt ở mốc frame 1; không sinh trùng khi giữ pose; có xử lý nhảy qua mốc giữa hai tick.
- Lớp **AttachedSlash** chỉ hiện từ frame 1 đến trước frame 2, hiện tại khoảng `0.15–0.20s` animation. Mất tại frame 2 hoặc đổi clip, không fade. Nó theo transform sprite hiện tại.
- Lớp **ResidualSlash** có material riêng, `top_level=true`, giữ global transform lúc sinh: vị trí/hướng/scale cũ không đổi khi nhân vật di chuyển hoặc đòn mới quay mặt. Phần hình bên trong transform này vẫn trượt/co dọc cung.
- Tuổi tính bằng `Time.get_ticks_usec()`, xử lý `PROCESS_MODE_ALWAYS`; shader không dùng engine `TIME`. Hit-stop/freeze/slow motion không kéo dài tuổi. Test đã xác nhận vệt còn chạy khi SceneTree pause; đây là hành vi hiện có của VFX, khác vài hiệu ứng game khác có thể dừng khi pause.
- Max residual mặc định 3; quá giới hạn dọn vệt cũ nhất. Hết tuổi, disable component hoặc xóa rig đều có cleanup.
- **Sống độc lập không đồng nghĩa luôn nhìn thấy sau mọi lần đổi clip:** nếu đã hết lifetime trước khi clip đổi thì vệt đã mất. Tốc đánh, mốc nối và lifetime quyết định mức chồng thực tế.

### Hình thu vệt và điều cần giữ khi sửa shader

- Với tiến độ tuổi chuẩn hóa `p`: đầu `head = 1 + travel * (1 - (1-p)^2)`; chiều dài còn lại `1 - smoothstep(0.10,1,p)`; đuôi `tail = head - chiều_dài`; bề dày co từ 1 về 0.025 qua `smoothstep(0.06,1,p)`.
- Shader ánh xạ ngược tọa độ ellipse về cửa sổ cung `[tail,head]`; nét vẽ thật co/chạy theo cửa sổ đó. Erosion loại chi tiết yếu với `smoothstep(0.35,0.95,p)*0.22`; alpha cuối chỉ giảm ở `p=0.90…1`.
- `attack_reverse_motion` vừa đổi thứ tự `arc_start/arc_sweep`, vừa truyền `reverse_artwork` để đảo vị trí đầu/đuôi nét vẽ ở full length. Chỉ đảo sweep sẽ tái tạo lỗi cũ: chiều mất đúng nhưng hình đầu tiên vẫn ngược.
- `_attack_transform()` áp dụng offset/scale/rotation/pivot/flip nhất quán cho **cả hai lớp**. `_arc_setup()` xử lý chiều. `_source_frame_transform()` giữ cùng hệ tọa độ với sprite và hướng nhân vật.
- `_configure_sprite()` mở rộng region quad với `MOTION_PADDING_PIXELS=(320,220)` để đầu vệt đi ngoài bitmap gốc không bị cắt cạnh; UV phải giữ ánh xạ gốc. Đã render kiểm tra full-length main so với residual ở p=0; không tùy ý reset UV về 0–1 trên quad mở rộng.
- Attached dùng detail cutoff 0, residual 0.10: vệt dư mất bớt chi tiết yếu. Cùng ảnh nguồn, không phải sinh một ảnh khác cho mỗi frame thu.

### Snapshot tuning quan trọng ngày bàn giao

Chi tiết đầy đủ/ý nghĩa/đơn vị ở hướng dẫn tuning chung; các số sau chỉ là snapshot để nhận diện thay đổi mới nhất:

- **Script default:** Effect Scale `(1,1)`, residual lifetime `0.35s`, finisher `0.44s`, head travel `0.12`.
- **Override scene gốc hiện đang lưu:** Effect Scale **`(1.15,1.15)`**, residual lifetime **`0.30s`**, finisher **`0.39s`**, head travel **`0.10`**. Đây là số đã căn trên scene, không trả lại thành mặc định script.
- Opacity script `0.96` / `0.86`, max residual `3`; scene kế thừa. Các mảng per-attack hiện kế thừa default script, không có override array riêng trong rig/playable/test khi đọc file.
- Đòn 3, index **2**: Offset `(0,-80)`, Scale `(1.38,0.40)`, Rotation `-1°`, Pivot `(1660,400)`, Reverse Motion `true`, Stroke Width `0.90`, không Flip H/V.
- Đòn 4, index **3**: Offset `(0,-60)`, Scale `(1,0.22)`, Rotation `0°`, Pivot `(905,400)`, Reverse Motion `false`, Stroke Width `0.75`.
- Đòn 1 bật Flip V; đòn 2 không chỉnh hình/hướng. Mọi array dùng index **0/1/2/3 ↔ đòn 1/2/3/4**.
- Chỉnh Remote chỉ thử tạm. Cần lưu tại scene/instance đúng chủ sở hữu để tồn tại sau lần chạy. Per-attack dùng pixel frame gốc, không phải pixel ảnh 1280×720/GIF.

## 5. Công việc đã hoàn thành ngoài căn hình vệt

### Sửa lỗi editor “Drawing is only allowed…”

- Input người dùng: `C:/Users/xuank/.codex/attachments/e09a7920-c061-43ac-ab9e-9dfc06e373ed/Pasted text.txt`; người dùng xác nhận lỗi lúc **mở project/chọn node trong editor**, không phải chỉ khi đánh trong game.
- Đã tái hiện bằng editor riêng; nguồn native báo `draw_set_transform`, `scene/main/canvas_item.cpp:1046`. Combo gameplay riêng không tạo lỗi này.
- Thử cache editor mới và tắt plugin vẫn lỗi: hai giả thuyết đã bị loại trừ cho trường hợp tái hiện. Scene tam giác và một rig đơn không lỗi; **hai instance dùng chung stack** tái hiện đúng lỗi.
- Nguyên nhân đã xác minh qua test instance: stack chứa tham chiếu Skeleton2D; tài nguyên dùng chung bị gắn tới rig sau. Lúc rig khác yêu cầu gizmo, lời gọi vẽ nhắm sai node đang trong draw notification. Các IK subresource của Adel cũng đang dùng chung.
- Sửa `resource_local_to_scene=true` trên **hai `SkeletonModification2DTwoBoneIK` + một `SkeletonModificationStack2D`** trong rig Adel, và stack của `res://scenes/enemy/enemy_spine.tscn`. Không xóa IK hoặc thay engine để giấu lỗi.
- Test `res://tests/adel/skeleton_instance_validation.gd` + `.uid`: trước sửa **14 checks, 6 failures**; sau sửa **14 checks, 0 failures**. Mở lại ba scene và chọn **246 node**: **0 lỗi Drawing**. VFX suite cùng đợt 68/68; tổng 82 là hai suite, không phải 82 kịch bản thị giác độc lập.

### Scene legacy đã được người dùng cho xóa

- `res://asset/Map/background/thewworldrudooo.tscn` — tham chiếu audio cũ thiếu.
- `res://scenes/Map 1/main.tscn` — các ảnh Adel/Wobtear cũ thiếu.
- `res://scenes/adel/Adel1.tscn` — ảnh Adel idle/walk cũ thiếu.
- Người dùng nói rõ đây là ba bản cũ đã bỏ. Trạng thái Git `D` là chủ đích, không khôi phục chỉ vì thấy thiếu file.
- `res://scenes/UI/pause.tscn` là wrapper trỏ tới `res://scenes/UI/game_pause_menu.tscn`; đã cập nhật để dùng scene pause hiện hành.
- Project checker lịch sử vẫn có **1 duplicate UID** `uid://560h85egf0du` giữa `asset/UI/dialogueUI/main.tscn` và `asset/BG/main.tscn`, cùng 8 warning tham chiếu legacy/test camera. Đây không phải toàn project đã sạch.
- Trong phép thử editor còn thấy test camera cũ tham chiếu lớp `CameraRoom`/`CameraMotionPreferences` không còn có. Đã ghi tách biệt, chưa sửa trong phạm vi VFX/resource.

## 6. Cách đã thử không đạt và bài học triển khai

1. **Preview nhiều chi tiết/màu, hoặc chỉ nét đơn giản thiếu vùng quét:** người dùng yêu cầu tối giản trắng nhưng đủ chất liệu sản phẩm cuối; cần tách duyệt silhouette, hướng, vùng đánh và hoàn thiện brush/glow, không nhầm một preview vector với bitmap hoàn thiện.
2. **Cung không bám mặt phẳng kiếm:** đặc biệt đòn 3/4. Việc “phủ được phía trước” không thay thế kiểm tra vai, vị trí kiếm và hướng vung. Chỉ đạo ngang vai mới nhất có ưu tiên hơn bản vòm cao/đi sau trong manifest cũ.
3. **Giảm alpha đều trên cung tĩnh:** bị đánh giá lạc quẻ/đơn giản. Mảng xám tồn tại khiến cảm giác khựng lộ hơn. Thay bằng đầu tiếp tục đi, đuôi đuổi, co cả chiều dài/bề dày và giữ lõi trắng.
4. **Chỉ wipe/cắt ảnh tĩnh từ đuôi:** không tạo đúng cảm giác cả khối/nét đang đi. Ánh xạ lại cả texture lên cửa sổ cung chuyển động cho groove đi theo khối.
5. **Chỉ đảo dòng thu của đòn 3:** đã xem được thu về trái nhưng đầu sáng ở ảnh full-length còn hướng cũ. Bản `saber-vfx-directions` thuộc giai đoạn này. Bản `saber-vfx-directions-final` bổ sung `reverse_artwork` và mở quad, giải quyết cả ảnh lẫn flow.
6. **Đầu di chuyển ra ngoài quad bitmap:** có nguy cơ cắt phẳng theo biên ảnh. Mở region với padding, giữ nguyên ánh xạ frame/UV; đã xem main/residual p=0 khớp vị trí trước khi kiểm các pha thu.
7. **Căn đòn 3 mới với Offset Y=-55:** đã dài/phẳng hơn nhưng centroid nét sáng còn hơi thấp hơn bản cũ trong cùng điều kiện. Đây là bản thử trong `saber-attack3-shoulder/`, **không phải final**. Đổi thành **-80** ở thư mục `final/`; đo lại xác nhận cao hơn.
8. **Đếm/encode frame khi đang quay:** PNG compression từng làm mất nhịp quan sát. Capture hiện buffer ảnh trong RAM, lưu PNG sau, lưu timestamp thật và resample khi xuất GIF. Không tính timing theo số frame GIF (GIF còn gộp frame trùng).
9. **Đổ lỗi lỗi Drawing cho shader/fade, plugin hoặc cache chỉ từ triệu chứng:** đã loại trừ bằng thử riêng; test hai instance dùng chung stack mới khóa đúng nguyên nhân. Tách instance Resource, không xóa skeleton hoặc disable tính năng vẽ để che lỗi.

## 7. Kết quả kiểm tra và bằng chứng để mở lại

Gốc artifact ngoài repo, vẫn tồn tại lúc bàn giao:

`C:/Users/xuank/.codex/visualizations/2026/10/25/01a170fc-5832-7430-b538-78ebad4ad7b3/`

Tên bên dưới ghép vào gốc này. Chúng là **kết quả lịch sử đã thực chạy**, không phải các test được chạy lại trong lượt chỉ viết tài liệu.

### Mới nhất: đòn 3 ngang vai, kéo dài về sau

Thư mục **`saber-attack3-shoulder/final/`**:

- `gameplay/saber_attack_3_ingame.png`: ảnh peak thực trong game đã gửi người dùng; `saber_attack_4_ingame.png` cùng thư mục để so mặt phẳng.
- `adel_saber_attack3_shoulder_normal.gif` **6.5s** và `adel_saber_attack3_shoulder_slow.gif` **13s**. 389 ảnh nguồn có timestamp; GIF sau gộp còn 125 frame, hai bản dùng cùng hình, bản chậm kéo thời gian gấp đôi. Không coi 125 là số frame artwork.
- `tests.out.log`: **SABER VFX RESULTS: 68 checks, 0 failures**. `tests.err.log`, `motion*.log`, `gameplay*.log`: không có script/shader error trong lượt này.
- `motion-states/`: bốn đòn, mỗi đòn một ảnh peak và residual p=0/25/50/75/90; renderer xác nhận `MOTION_STATE_RENDER_OK 24`. Diện tích sáng co dần, lõi giữ tương phản tới pha cuối.
- `geometry_comparison.json`: so cùng viewport/scale hiện hành, threshold sáng 32. Riêng đòn 3: bounding width **514→714 px**, height **116→42 px**, centroid Y **263.826→251.428** (nhỏ hơn là cao hơn). Biên trái **354→145**, biên phải **867→858**: phần thêm chủ yếu ra sau, tầm trước gần giữ nguyên. Đây là pixel của ảnh kiểm tra, không phải world unit/hitbox.
- Cùng so sánh đó: **đòn 1/2/4 giống từng pixel** ở peak và năm pha thu; bảo toàn scale chung 1.15. Đây là xác minh phạm vi thay đổi, không phải kết luận mọi map/camera cho ảnh giống nhau.
- `verification_summary.json`, `capture_motion.gd`, `compare_shapes.py`, `export_gameplay.py` ghi cách dựng/đo.
- Video review đã xem hai hướng: vệt đòn 3 ngang vai/hơi nghiêng, dài hơn về sau, đầu dày và chiều thu đúng; không thấy clipping/nền chữ nhật/nhảy vệt. **Không khẳng định khớp tuyệt đối toàn quỹ đạo kiếm** vì source chỉ ba frame.

### Hướng 1/3 và hình mảnh đòn 4 ở đợt trước

- `saber-vfx-directions-final/adel_saber_corrected_normal.gif` / `_slow.gif`, các ảnh `gameplay/saber_attack_N_ingame.png`, `verification_summary.json`.
- `saber-vfx-directions/regression-combat.out.log`: **106 checks, 0 failures**.
- `saber-vfx-directions/regression-skill.out.log`: **160 checks, 0 failures**.
- Tổng **334** từng được báo ở đợt sửa hướng là 68 VFX + 106 combat + 160 skill; không coi đây là 334 test vừa được chạy lại sau mọi chỉnh đòn 3 hoặc thay đổi Q mới ngoài phạm vi.

### Lỗi editor / resource dùng chung

- `saber-draw-error/verification_summary.json`, `instance-before.out.log`, `instance-after.out.log`.
- `editor-after-result.json`: `draw_errors=[]`, `selected_nodes=246`; `editor-after.out.log` liệt kê đúng ba scene đã mở.
- `editor_verified.png` là screenshot editor cuối; `minimal-before.json`, `no-plugins-result.json`, `shared-stack-before.json` và các log là dấu vết chẩn đoán. Có lỗi test camera cũ riêng trong log; **0 lỗi Drawing không có nghĩa editor không còn bất kỳ lỗi nào**.

### Nguồn ảnh hoàn thiện và các bản đã bị thay thế

- `adel-vfx-finished-art/saber_attack_1_full.png` … `saber_attack_4_full.png`, `generation_manifest.json`: ảnh sinh bằng **image_gen**, prompt/provenance. Trong lượt bàn giao đã đối chiếu **bốn PNG tích hợp giống từng byte** với bản full; hiệu chỉnh sau bằng transform/shader, không vẽ lại bitmap.
- Manifest này ghi silhouette/orientation tại giai đoạn tạo ảnh; prompt đòn 4 còn concept overhead cũ. **Không dùng prompt đó để đảo ngược quyết định ngang vai về sau**.
- `adel-vfx-preview/`, `adel-vfx-preview-v2/`, `adel-vfx-preview-v3/`: các prototype silhouette/đường chém trước ảnh hoàn thiện.
- `saber-vfx-validation/`: tích hợp đầu; `saber-vfx-follow-through/`: chuyển từ fade đơn giản sang co/chuyển động sau video AE, có các GIF và log lịch sử. `references.json` trong đây là **báo cáo tham chiếu project**, không phải danh sách video.
- `obsolete-scene-cleanup/references-after.json`, `scene-loads*.log`: kiểm tra sau xóa scene legacy.
- Các thư mục test project/mirror từng dùng junction về checkout thật; **các junction của lượt test gần nhất đã dọn**. Không mặc định chạy trực tiếp `project/` trong artifact là đủ tài nguyên; tái dựng bản thử đúng cách.

## 8. Ref người dùng và tài nguyên bên ngoài

### Bản sao ổn định trong repo

Trong lượt bàn giao đã copy **10 file nguyên byte**, đối chiếu SHA-256, tổng 1,300,787 byte tới:

`D:/Godot Project/soujourn--echoes-of-the-soul/Context/Tai_lieu_ban_dao/refs_anim/`

- `w_corp_meursault_skill_3.gif`: GIF Limbus ban đầu.
- `hitbox_saber_attack_1.png` … `hitbox_saber_attack_4.png`: bốn ảnh đỏ/xanh, theo đúng thứ tự đòn. Xanh là hitbox giả định; đỏ là gợi hình/hướng/tầm, không phải màu sản phẩm hoặc collider thật đã đo.
- `single_crescent_shape.png`: ref lưỡi liềm trắng liền khối mà người dùng chốt.
- `style_white_ellipse.png`, `style_white_brush_arc.png`, `style_white_slender_arc.png`: cấu trúc/brush/glow trắng.
- `style_gold_structure_only.png`: chỉ tham khảo độ thuôn/nhịp nét; không lấy màu vàng.
- `sources.json`: tên gốc đầy đủ dưới `C:/Users/xuank/AppData/Local/Temp/codex-clipboard-*.png` hoặc `D:/Downloads/`, tên bản sao, kích thước và SHA-256. Bản gốc còn tồn tại khi copy; chat mới ưu tiên bản sao trong repo vì Temp có thể bị dọn.
- `.gdignore` giữ thư mục ref tài liệu ngoài pipeline import của game; mở bằng filesystem khi cần, không tìm chúng như Texture trong Godot FileSystem.

### Drive asset Limbus do người dùng cung cấp

- Folder: https://drive.google.com/drive/folders/1Nk9WWMxEcovs5Ewku5ICT1PbfByNcV_z — **Limbus Company - Organized Assets**. Screenshot đầu có các thư mục Audio, Fonts, Images, Other, Text, Videos và FAQ.
- File từng mở trong browser context: https://drive.google.com/file/d/1IJLEV9bjx07XpZzO9uakJwoQzXdZsY8K/view . Không có nội dung/tên file được xác minh trong bản bàn giao này; **không tự gán nó là slash cụ thể**.
- Người dùng cho phép tự tìm trong bộ asset để báo cáo/tham khảo. Trong source VFX hiện tại, bốn PNG là ảnh sinh riêng theo ref; **không có bằng chứng chúng được lấy từ một file rip cụ thể trên Drive**. Chưa có catalog mapping tên asset Limbus → bốn đòn Adel được lưu trong repo. Nếu cần dùng lại asset thật, phải xem/file-map cụ thể trước khi kết luận phù hợp.

## 9. Trạng thái Git và phần ngoài phạm vi

Xác minh lúc bàn giao: nhánh **main**, HEAD **`bdff79c` — `quy hoạch đô thị`**. Không fetch để xác minh remote mới nhất. Source và Git hiện tại có ưu tiên hơn HEAD/nhánh trong `HANDOFF.md` cũ. Chat VFX này không tự commit/push các thay đổi nêu dưới.

Phần trực tiếp thuộc công việc animation/VFX trong chat:

- Sửa rig `asset/Character/Adel/adel spine action use.tscn`: gắn component VFX; về sau Local To Scene cho stack và hai IK. Scene có tuning do người dùng căn; không reset toàn file.
- Mới: `scenes/adel/components/saber_swing_vfx.gd`, `saber_slash.gdshader`, `.uid`; `asset/VFX/Adel/Saber/`; `tests/adel/saber_vfx_validation.gd`, `saber_vfx_capture.gd`, `skeleton_instance_validation.gd` và `.uid`.
- Sửa `scenes/enemy/enemy_spine.tscn`: Local To Scene cho stack. Xóa ba scene legacy và cập nhật pause wrapper như mục 5.
- Nghiên cứu mới: `Context/Bao_cao_ky_thuat/nghien_cuu_animation_combat_limbus.md`.
- Lượt bàn giao: điền file này, thêm pointer trong `HANDOFF.md`, đồng bộ mục VFX trong hướng dẫn tuning chung và README trỏ về đó, lưu `refs_anim/`. **Không đổi giá trị/code gameplay trong lượt viết bàn giao**.

Những thay đổi khác được thấy khi bàn giao, **không nhận là do công việc VFX và chưa kiểm chứng lại trong lượt này**:

- `Context/artbook.docx`, `Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md` đã có sửa trước lượt bàn giao; giữ phần người dùng/nhánh khác, đặc biệt mục zoom Q vừa được bổ sung.
- `scenes/adel/playable_adel.tscn`, `scenes/adel/components/saber_weapon_skill.gd`; mới `skill_charge_zoom.gd`/`.uid`, `tests/adel/q_charge_zoom_validation.gd`/`.uid`. Hướng dẫn chung ghi nghiên cứu/kiểm tra của nhánh zoom Q; **không coi các số test đó là test của chat VFX**.
- Mười PNG trong `asset/Enemies/sample/images/` (body/head/lef leg/left hand/left palm/right bicep/right hand/right leg/right palm/tail) đang sửa, cùng thư mục `output/` untracked. Giữ nguyên; chưa xác minh tác giả hoặc nội dung mọi thay đổi này.
- Rig Adel vốn có các chênh float nhỏ ở L_upper_arm/cloth_bone2 trước phần sửa VFX. Không sửa lại chỉ để làm diff sạch.

Kiểm tra lại `git status --short`/diff ngay khi tiếp quản. Phần lớn file VFX/test còn untracked; bảo toàn chúng, tránh `git clean`, reset/checkout đè, và không tự commit toàn working tree.

## 10. Việc dang dở, giả định và bước tiếp theo

### Chưa được chứng minh hoặc chưa được người dùng nghiệm thu

- Chưa có phản hồi cuối sau preview đòn 3 mới nhất. “Gần đường kiếm hơn” là đánh giá thị giác đã review, không phải đã nội suy/đo được quỹ đạo thật liên tục giữa ba frame.
- Chưa có phép xác nhận pixel VFX trùng hitbox thật hoặc vùng có damage toàn bộ theo cung. Hộp xanh của ref là giả định; capture tập trung hình vệt không thay thế test collider.
- Chưa có A/B có kiểm soát giữa một lớp và hai lớp để kết luận khách quan B tốt hơn A. Hiện đã chọn triển khai B theo lệnh người dùng, không phải kết quả nghiên cứu A/B thắng.
- Chưa chạy lại mọi suite của project sau các thay đổi Q/enemy asset song song; không tuyên bố toàn game sạch lỗi. Các UID/test camera cũ ở mục 5 còn ngoài phạm vi.
- Lifetime/độ sáng/tầm vươn vẫn là số tuning, chưa được nghiệm thu cho mọi tốc đánh, mọi camera/nền sáng hoặc đám đông. Với real time, một hit-stop rất dài có thể khiến vệt tan hết trong khi nhân vật vẫn freeze; đây là điều cần đánh giá cảm giác, không phải lỗi clock đã biết.
- Không có tác vụ code bắt buộc nào đang bỏ dở trong phần điều chỉnh đã được giao. Bước kế tiếp là tiếp quản đúng trạng thái và nhận/áp dụng phản hồi cụ thể, không tự thêm hạt, impact, rung/zoom hoặc thêm frame nhân vật.

### Trình tự khuyến nghị cho chat mới

1. Đối chiếu source và override trong rig/player/map với hướng dẫn tuning. Xem ảnh peak đòn 3 và GIF mới nhất ở mục 7, rồi đối chiếu ref đỏ/xanh và thanh kiếm. Nếu source đã khác, báo rõ snapshot khác ở đâu.
2. Xác nhận yêu cầu mới/việc người dùng muốn tiếp tục. Nếu chỉ tiếp quản, báo ngắn phần đã xác minh và phần cần phản hồi; không coi bàn giao là lệnh tự chỉnh mọi hệ thống.
3. Khi chỉnh silhouette tiếp: chọn index đúng, thay một nhóm hình học nhỏ, áp cả main/residual. Muốn kéo về sau thì kiểm pivot/front extent; muốn mảnh ngang thì tách scale Y, rotation, offset Y và stroke width. Giữ chiều full-length lẫn chiều thu và thử cả hai hướng.
4. Nếu cần kiểm vùng đánh: bật debug hitbox thật và thử vào/ra mép vùng, chém hụt/trúng, nối nhanh, chuyển hướng, không/trên đất, bị ngắt; xác minh collider trong WeaponPivot thay vì hộp ref. Thay hitbox/damage/timing cần nằm trong yêu cầu được chốt.
5. Nếu được yêu cầu so A/B: dùng cùng silhouette/timing/hitbox/camera/hit-stop; chỉ thay cấu trúc/lượng VFX, tránh đổi nhiều yếu tố một lúc. Ghi rõ kết quả người dùng cảm nhận và phần có số đo riêng.
6. Sau thay đổi: chạy suite VFX phù hợp, render/capture thực tế, đọc log; chỉ chạy thêm suite combat/skill/skeleton nếu phạm vi/thất bại mới yêu cầu. Cập nhật hướng dẫn tuning, README/bàn giao và gửi hình/gameplay đủ để đánh giá kết quả thật.

## 11. Môi trường chạy lại an toàn và giới hạn công cụ

- Godot đã dùng: **`D:/Godot_v4.7-stable_win64.exe`**, runtime 4.7 stable. Python đã dùng cho đọc ảnh/đo/encode: **`C:/Users/xuank/AppData/Local/Programs/Python/Python313/python.exe`**, có PIL/numpy.
- Dùng skill Godot phù hợp: `godot-gdscript`, `godot-shaders`, `godot-animation`, `godot-resources`; `diagnosing-bugs` khi lỗi có repro; `imagegen` khi thật sự cần tạo/sửa bitmap. Căn transform/shader không cần sinh lại ảnh. Với video chứng minh, quy trình `walkthrough-artifacts` đã yêu cầu review trước khi gửi.
- Chạy test trên project copy/mirror có custom user directory riêng, redirect APPDATA/LOCALAPPDATA. **Hai script VFX/capture và skeleton validation chặn nếu user dir không chứa `CodexSaberVFX`**; đây là guard bảo vệ save chơi thật.
- Lệnh mẫu sau khi đã chuẩn bị bản thử riêng (thay đường dẫn placeholder, không chạy thẳng với save thật):

```powershell
& "D:/Godot_v4.7-stable_win64.exe" --path "<project-thu-rieng>" --headless --audio-driver Dummy --max-fps 120 --quit-after 4000 --script res://tests/adel/saber_vfx_validation.gd
& "D:/Godot_v4.7-stable_win64.exe" --path "<project-thu-rieng>" --headless --audio-driver Dummy --quit-after 1200 --script res://tests/adel/skeleton_instance_validation.gd
& "D:/Godot_v4.7-stable_win64.exe" --path "<project-thu-rieng>" --rendering-method gl_compatibility --audio-driver Dummy --disable-vsync --quit-after 1800 --script res://tests/adel/saber_vfx_capture.gd -- --output="<thu-muc-capture-tuyet-doi>"
```

- Capture dùng **scene combat thật, input game thật**, giữ Player/physics/hitbox/animation. Nó giấu UI không liên quan, dời/khóa AI địch, vô hiệu simulation vitals, đặt camera zoom 2.1 để tập trung. Vì vậy video không chứng minh phản ứng khi đánh trúng địch; hit-stop thật được suite gọi `CombatTime` kiểm riêng.
- Headless không thay cho xem shader thật; đã dùng OpenGL Compatibility cho ảnh/GIF. Không khẳng định mọi renderer/GPU đều đã test.
- Godot MCP từng có session rồi mất kết nối; không giả định trạng thái editor. Kiểm tra tool/session trước, tránh force reload làm mất sửa chưa lưu. Các editor/process thử đã tự kết thúc; không dừng process của người dùng để “dọn”.
- Shell thường từng vấp lỗi launcher MXC `0x80070020`; lệnh có quyền mở rộng qua auto-review chạy được trong các lượt trước. Đây là giới hạn công cụ, không phải lỗi project. Launch helper Windows bằng `Start-Process -WindowStyle Hidden`; chỉ dọn junction trong thư mục thử đã kiểm đường dẫn, không đệ quy theo junction vào project thật.

**Điểm tiếp quản cuối:** giữ thành quả và tuning hiện tại; chờ phản hồi thị giác mới nhất rồi chỉnh có mục tiêu. Đã hoàn thành điều chỉnh đòn 3 và sửa lỗi stack dùng chung; chưa có bằng chứng Limbus dùng đúng kiến trúc runtime này và chưa có nghiệm thu rằng mọi vệt khớp collider/quỹ đạo liên tục tuyệt đối.
