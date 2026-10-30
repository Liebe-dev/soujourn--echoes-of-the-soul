# Bàn giao Soujourn Echoes of the Soul

**Ngày kiểm tra gần nhất:** 30/10/2026, múi giờ Asia/Saigon; phạm vi lượt này là bàn giao art/asset.
**Mục đích:** giúp chat mới tiếp quản đúng trạng thái, giữ công việc người dùng và phân biệt thiết kế với triển khai.  
**Nhiệm vụ gần nhất:** hoàn thiện thiết kế Đản theo art Uyển, gần nhất làm bàn tay lộ ra có cảm giác già nua; chuẩn bị bàn giao sang chat mới. Đọc cập nhật 30/10 dưới đây trước. Các cập nhật gameplay 24/10 và mục 1–10 phía sau là lịch sử của nhánh khác, không phải kết quả kiểm tra gameplay ngày 30/10.

## Cập nhật bàn giao art/asset — 30/10/2026

### Tiếp quản ngay: mục tiêu và trạng thái

- Project `P = D:/Godot Project/soujourn--echoes-of-the-soul`. Nhánh đang làm là **art nhân vật và asset**, không tự chuyển sang Observe/chỉ số/VFX gameplay chỉ vì các mục lịch sử bên dưới có nhắc đến chúng.
- Mục tiêu hiện hành: hoàn thiện **Đản**, cha xứ nhà thờ làng ở đầu arc, boss đầu Adel đối mặt, chủng **Hallow**, tương đối có tuổi, tóc trắng. Người dùng đưa bản phác riêng và muốn hoàn thiện theo **minh họa Uyển gốc**, không dùng tỷ lệ chibi của sprite Adel cho minh họa Đản.
- Yêu cầu gần nhất nguyên ý: **tiếp tục từ bản khoanh nhẹ trước bụng còn lộ một bàn tay, làm bàn tay trông già nua**. Đã tạo ảnh mới và hiển thị. **Chưa có lời duyệt cuối sau ảnh này**, chưa có yêu cầu biến Đản thành sprite/tách lớp/rig/tích hợp game.
- Bản để tiếp tục mặc định: [dan_current_aged_hand.png](../../output/handoff/character_art_2026-10-30/dan_current_aged_hand.png). Bản người dùng chỉ đích danh trước khi sửa tay: [dan_before_aged_hand.png](../../output/handoff/character_art_2026-10-30/dan_before_aged_hand.png). Bản thứ hai là nguồn của bản mới nhất, không phải ảnh giấu cả hai bàn tay.
- Thư mục tài nguyên bàn giao `A = P/output/handoff/character_art_2026-10-30/`: có **14 PNG sao chép nguyên byte**, `resource_manifest.json` ghi đường dẫn gốc, bản sao, vai trò, kích thước và SHA256; `verification.json`, `enemy_asset_verification.json` ghi kiểm tra. Có `.gdignore`, không được game dùng. Bản HANDOFF trước cập nhật giữ ở `A/HANDOFF_before_art_update.md` để đối chiếu.

### Yêu cầu và quyết định hình ảnh

**Đản — yêu cầu hiện hành:**

- Giữ nhận diện bản phác: mặt nam trưởng thành dài/góc cạnh, mắt hơi mệt, mũi dài, nét cười nhẹ; tóc trắng thẳng ngang vai, râu cằm nhỏ; vòng halo elip nghiêng mảnh có các chóp nhọn. Không thay bằng kính, râu bện dài hoặc kiểu tóc của nhân vật ảnh tham chiếu.
- Người dùng chuyển hướng trang phục sang **Công giáo La Mã** và nêu phối chasuble Gothic bên ngoài với lớp đen kiểu pellegrina bên trong. Đã phát triển hướng đó trong preview: trắng ngà–đen–vàng trầm, cổ giáo sĩ đen có tab trắng, cổ vai đen viền vàng, dải đen dọc giữa có thập giá hình học và ít họa tiết vàng. Đây là thiết kế fantasy đã dùng trong ảnh, chưa phải trang phục được nghiệm thu về nghi lễ/lịch sử.
- Dáng cuối: đứng toàn thân, **hai cẳng tay bắt chéo nhẹ trước bụng**, khuỷu tay thấp/thả lỏng; một bàn tay lộ ra tựa lên cẳng tay/cổ tay đối diện, tay kia khuất trong tay áo. **Không khoanh cao ôm bắp tay trước ngực**; không đặt tay trên cằm; **không cây gậy**.
- Người dùng từng yêu cầu giấu cả hai bàn tay nhưng **sau đó chọn lại đích danh bản còn lộ tay** và yêu cầu làm già bàn tay. Yêu cầu mới đã thay lựa chọn giấu tay cũ.
- Chi tiết tay mới: khớp/ngón gầy, nếp nhăn, gân và mạch máu nhẹ theo nét 2D; giữ tư thế, không làm già thêm mặt hay đổi áo. Ảnh đã được tạo; đánh giá cuối mức độ già của tay còn chờ người dùng.
- Style minh họa: nét 2D anime gọn, màu lì, mảng đổ bóng kiểm soát, bảng màu trầm như art Uyển gốc. Giữ các phần người dùng không yêu cầu sửa. Ảnh Đản hiện là **minh họa nền xám sáng**, không phải sprite PNG đã tách nền.

**Uyển — yêu cầu lịch sử còn có giá trị khi quay lại:**

- Từ art Uyển gốc tạo sprite dùng trong game theo nét/tỷ lệ/dáng idle Adel; chiều cao thấp hơn Adel một chút. **97%/thấp hơn 3% là giả định trợ lý từng nêu, chưa được người dùng chốt số và chưa có xuất chuẩn hóa chiều cao thực tế cạnh Adel.**
- Người dùng đã bỏ chỉnh nhìn thẳng, giữ mặt hơi nghiêng của `exec-05733226-...png`. Sau đó giảm nếp gấp ở tay áo/váy, bỏ khuyên tai; từng thử váy lót trắng xám mờ 40% phủ giày, rồi **bỏ hoàn toàn váy lót**, tay áo ít nếp. Bản sprite sau các sửa này: `A/uyen_latest_sprite.png`, PNG trong suốt 852×1846.
- Giữ tóc đen đuôi ngựa bên trái người xem/hoa trắng, mắt xám, blouse trắng–cà vạt đen–gile đen/vàng, đai chéo, váy đen dài, giày đen và kiếm trong bao. Hai tay thả theo idle Adel. Chưa thay sprite/rig Adel hay đưa Uyển vào scene.
- Đã làm preview **21 bộ phận**, tham khảo `P/asset/Character/Adel/layers/Adel spine action use/`. Bàn tay đi liền cẳng tay; có đầu, hai lọn tóc, tóc đuôi ngựa, thân trên/dưới, hông/đai, hai cánh tay, hai cẳng tay, hai đùi, hai cẳng chân, hai giày, ba mảng váy, kiếm trong bao. Đây là các lớp **được vẽ lại/vẽ bù phần khuất**, không phải cắt giữ nguyên từng pixel của sprite và chưa căn vào rig.

**Quy tắc làm asset đã được người dùng nhấn mạnh:**

- Với thay asset, trình preview rồi chờ duyệt đúng lần trước khi ghi đè vào game; duyệt một ảnh không tự cấp quyền thay mọi ảnh khác.
- Khi cần khớp rig cũ, vẽ trên đúng khung/hướng/kích thước từng PNG gốc, giữ tên, alpha vùng khớp, vị trí và cách chia frame. Giữ nguyên các giá trị rig/scene/animation người dùng đã căn. Không tự xoay, dịch tâm, thêm padding hay sắp xếp lại các phần để ép vào rig.
- Preview atlas được bố trí để xem rõ và phải được phân biệt với tọa độ atlas/rig thật. Thao tác cắt/đóng gói không chứng minh khớp chuyển động.

### File và phiên bản Đản cần tìm

Cache ảnh gốc `G = C:/Users/xuank/.codex/generated_images/01a1722e-0438-7060-84ea-76648f36bf4e/`. Các tên dưới đây là file trực tiếp trong `G`; nguồn/bản sao đầy đủ xem `A/resource_manifest.json`.

- **Mới nhất:** `exec-df3063f2-51fe-45d9-a882-ad4b5226cdae.png` → `A/dan_current_aged_hand.png`, 1051×1496; SHA256 `AAE179B547B991385670FFA9207DAF6B5563F9328F2810700B1880CE2450B982`.
- **Nguồn được người dùng chọn, khoanh nhẹ trước bụng/lộ một bàn tay:** `exec-a7b18e41-bfc8-4719-b8a4-4c7d447a4f42.png` → `A/dan_before_aged_hand.png`, 1051×1496; SHA256 `D3867B7B3D5E6E484477E4E09F87132F45C48EEB9E403E174D72C8375F6493E8`.
- Minh họa hoàn thiện đầu tiên, khung nửa người, dùng làm nguồn mặt/áo và tham chiếu tư thế tay: `exec-e2676550-05ca-4a7a-bcae-68332479071b.png` → `A/dan_initial_portrait.png`, 1051×1497.
- Phác Đản của người dùng: `C:/Users/xuank/AppData/Local/Temp/codex-clipboard-627323ea-a467-475f-a8b9-3739459cbb74.png` → `A/dan_user_sketch.png`, 561×800. Có bản sao nên không cần phụ thuộc Temp.
- Ảnh **chỉ tham chiếu dáng đứng**: `D:/Downloads/Layer 23.png` → `A/pose_reference_only_no_staff.png`, 2310×3080. Bản quyền/thiết kế của ảnh này không được chuyển thành quyết định về khuôn mặt, gậy hay phụ kiện Đản.
- Biến thể không dùng làm điểm tiếp tục: tay ở cằm `exec-18a12ac0-ed51-4cbc-adfc-b3a56f6e1728.png`; hai bàn tay thả cùng mức `exec-9ce91b38-720a-4bba-981e-20a78a873de0.png`; khoanh cao trước ngực `exec-2dc58e13-b1bf-4500-a085-b15063349327.png`; giấu cả hai tay `exec-bbad5d3c-2f76-4585-8469-0160d28835eb.png`. **Đã xác minh bốn file vẫn tồn tại trong G ngày 30/10**, nhưng không sao chép vào A để tránh chọn nhầm.

### Nguồn Uyển/Adel và chênh lệch file hiện tại

- Minh họa Uyển gốc: `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Side Character/Uyen/splash art.png`, 2254×3421 → `A/uyen_original_illustration.png`. **Dùng art này làm style cho minh họa Đản.**
- Sprite Adel: `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Project Adel/Adel idle.png`, 268×867 → `A/adel_idle_style_reference.png`. Dùng style/dáng này cho **sprite Uyển**. Hai file Photoshop xuất PNG gốc vẫn có hash trùng kết quả đọc trước trong chat.
- Bản Uyển mặt hơi nghiêng được chọn: `G/exec-05733226-c2a9-44c7-aa00-96c4c97151d9.png` → `A/uyen_chosen_three_quarter_base.png`.
- Sprite Uyển mới nhất trước tách: `G/exec-61253656-e9ac-439c-b16a-4ef6ef406359.png` → `A/uyen_latest_sprite.png`; SHA256 `AA5589925AAF736CAC0FDAC2121F63D05168C7FD2BE34514CF79941EFB2724DC`.
- Khuôn chia lớp Adel hiện có: `P/asset/Character/Adel/layers/Adel spine action use/`, gồm PNG, `layers.json`, `doc.json` (canvas PSD 1920×1080); scene `P/asset/Character/Adel/adel spine action use.tscn`. Có cả tên thường và biến thể `[merge]`; đừng coi mọi file là bộ phận độc lập cần nhân đôi.
- **Chênh lệch xác minh 30/10:** `P/output/previews/` hiện trống. Bộ đã từng xuất/hiển thị ở `output/previews/uyen_parts_2026-10-28_v1/` (21 PNG, `uyen_parts_preview.png`, ZIP, manifest và prompt JSON) **không còn tại đường dẫn đó**. Không xác minh được ai hoặc thao tác nào làm mất file; không coi link preview/ZIP cũ còn dùng được. Không tự dựng lại hay thay thế asset trong lượt bàn giao.
- Còn đủ **5 sheet sinh ảnh nguồn của bộ tách Uyển**, đã sao chép vào A để có thể phục hồi nếu người dùng yêu cầu: `uyen_parts_sheet_A_head_torso_uncorrected.png` từ `G/exec-43e24be5-5e6d-4775-a59b-638eacd492be.png`; `uyen_parts_sheet_B_limbs.png` từ `exec-24a57dce-63a9-461f-ba30-8d77550e7b3b.png`; `uyen_parts_sheet_C_skirt_equipment_uncorrected.png` từ `exec-064ef7a4-320a-4b84-98ac-5ab7292bb0b4.png`; `uyen_parts_corrected_torso.png` từ `exec-37855fd9-2e37-4335-a5e6-6e3be8255df8.png`; `uyen_parts_corrected_hip.png` từ `exec-1dda867d-0bb1-4642-85b8-6cf8413ef1d0.png`.
- Sheet A gốc còn dính tay áo vào thân, sheet C còn lặp cán kiếm trên hông; dùng **hai sheet corrected** cho thân/hông. Những PNG này không tự chứa tọa độ khớp của sprite ban đầu. Không nói đã phục hồi 21 PNG chỉ vì còn 5 sheet.

### Asset quái đã hoàn thành trước nhánh Đản/Uyển

- Người dùng muốn thay thiết kế lấy từ ảnh mạng bằng thiết kế mới, giữ hình dáng/cách đi để animation còn khớp. Hướng đã duyệt: vỏ trắng sáng bị nứt/vỡ tiết chế, da than đen có khói đen mỏng, thương tích cũ/máu khô ít, không máu chảy, đuôi dạng dải đỏ sẫm. Khớp là mảng đen 2D phẳng, không mặt cắt 3D.
- **Đã kiểm tra lại 30/10:** 10 PNG ở `P/asset/Enemies/sample/images/` trùng SHA256 với `P/output/integration/enemy_parts_2026-10-26_v2_redo/parts/`: `body.png` 303×263; `head.png` 99×188; `lef leg.png` 181×229 (giữ lỗi chính tả tên); `left hand.png` 139×208; `left palm.png` 159×79; `right bicep.png` 128×106; `right hand.png` 163×131; `right leg.png` 148×191; `right palm.png` 144×85; `tail.png` 361×232.
- **Đã kiểm tra lại 30/10:** 5 ảnh ở `P/asset/Enemies/sample/attack/` trùng hash trong các `installation_result.json` tương ứng bên dưới: `attack1_1.png` 660×384, `attack1_2.png` 568×492, `attack1_3.png` 964×441, `attack2.png` 3823×704, `attack3.png` 2703×931. `attack2`/`attack3` dùng strip ba frame ngang bằng nhau; bảo toàn canvas và vị trí từng frame, đặc biệt 3823 không chia hết cho 3 theo pixel nguyên.
- `output/integration/enemy_attack1_2026-10-27_v1/`: hồ sơ thay ba frame attack1 và `originals/`. **Riêng attack1_3 đã được thay tiếp bằng v2 bên dưới**, đừng lấy hash attack1_3 v1 làm tiêu chuẩn cuối.
- `output/integration/enemy_attack1_3_2026-10-27_v2_four_limbs/`: bản sửa đủ tay/chân phía xa, đã duyệt/thay; hash cuối `E2673CF876053D03D54D9E0D0009DCA29AD7C9A1492FD5BE3524CB07782D4C80`.
- `output/integration/enemy_attack2_2026-10-27_v3_long_inward_arm/`: bản v3 đã duyệt/thay; frame 1 giơ tay ngoài, frame 2 quật chéo vào trong, tay dài dưới hàm, vuốt khuất; hash cuối `7E3F8CF2317B8001322D0786504BB6B695DD9A9EFFE4069872990ABCF0BCF89A`.
- `output/integration/enemy_attack3_2026-10-27_v1/`: đã duyệt/thay; hash cuối `04767562F131C1FAAFC57AD6D7205C4745D2992D9B23450B6A8F899FE88B374F`.
- Các thư mục **integration vẫn có** hồ sơ JSON/README và nơi lưu originals; các đường dẫn `output/previews/enemy_*` mà hồ sơ cũ trỏ tới **không còn trong output/previews hiện tại**. Lấy asset trong game và hash hồ sơ integration làm bằng chứng hiện trạng; không mặc nhiên dùng link preview cũ.
- Bản ảnh mạng tham chiếu ban đầu còn ở `D:/Downloads/wolf_ego_chp3.png`. Bộ phần cũ trước thay nằm trong `output/integration/enemy_parts_2026-10-26_v1/originals/`; bản căn sai v1 trước làm lại được lưu trong `enemy_parts_2026-10-26_v2_redo/before_redo/`.
- `images/template.png` và `death.png` không nằm trong phạm vi đã thay của chat này. README bộ phần v2 còn nói các attack chưa thay vì nó được viết **trước** các lượt thay attack1/2/3; đó là ghi chú theo thời điểm, không phải hiện trạng attack ngày 30/10.

### Những cách đã thử không phù hợp và giới hạn

- Lần đầu thay phần quái có xoay/dịch/căn lại ảnh, lệch ý muốn giữ rig; người dùng yêu cầu làm lại. Bộ v2 vẽ theo canvas/hướng gốc thay cho cách ép ảnh đã duyệt vào rig. Không lặp lại tự động sắp xếp các phần.
- Attack1_3 từng thiếu tay/chân phía sau, đã sửa v2. Attack2 từng để bàn vuốt ngoài lộ ra/hướng ra ngoài, đã sửa thành cẳng tay dài quật vào trong, vuốt bị che. Không quay về các bản này khi tìm file cache.
- Uyển từng quá cao/theo tỷ lệ minh họa; đã tạo bản compact. Chỉnh nhìn thẳng bị người dùng hủy; bản có váy lót mờ cũng đã bị bỏ. Preview tách lớp vẽ lại các vùng khuất nên chưa chứng minh giữ nguyên pixel hay khớp rig Adel.
- Đản từng khoanh cao trước ngực, tay ở cằm, hai tay thả bên nhau, hoặc giấu cả hai bàn tay; đều đã được thay bằng lựa chọn cụ thể mới hơn. Dùng đúng file người dùng chỉ tên, không chỉ dùng ảnh sinh cuối nếu người dùng đã quay lại ảnh cũ.
- Đường dẫn attachment có thể bị giao diện gửi dạng `/C:/Users/...png`, gây `os error 123`. Dùng đường dẫn Windows chuẩn `C:/Users/...png` hoặc `C:\Users\...png`; các file Đản/Uyển đã xác minh vẫn đọc được sau chuẩn hóa. Không yêu cầu gửi lại chỉ vì dấu `/` thừa trước ổ đĩa.
- Một lượt sinh bàn tay già bị ngắt, không có kết quả lưu trong store; đã gọi lại ImageGen và có file `exec-df3063f2-...png`. Không ghi lượt bị ngắt là hoàn thành; không có bằng chứng đây là từ chối chính sách.
- PowerShell từng không khởi động do `CreateProcessSecurityEnvironment`/`0x80070020`; là lỗi khởi chạy đã gặp, không phải PNG hỏng. Các lần kiểm tra bàn giao hiện tại đã chạy được.
- Khi đóng gói PNG bằng System.Drawing, vẽ bằng source/destination rectangle với đơn vị pixel; `DrawImageUnscaled` từng làm sai kích thước hiển thị do DPI. `Add-Type` C# trên runtime .NET 10 từng cần thêm `System.Drawing.Common`, `System.Drawing.Primitives`, các assembly `System.Private.Windows.*`; không lấy lỗi helper đóng gói làm bằng chứng ảnh sinh lỗi.

### Kiểm tra thực chạy và điều chưa xác minh

- **Xác minh 30/10:** 14 ảnh tài nguyên trong A tồn tại, đọc được kích thước và hash; từng bản sao trùng nguyên byte với nguồn. Đản mới nhất/nguồn trước sửa tay/portrait và cả bốn biến thể trung gian đã được kiểm tra tồn tại. Hai file PNG người dùng xuất từ Photoshop có hash không đổi so với lần đọc trước trong chat.
- **Xác minh 30/10:** 10 phần quái khớp v2; 5 ảnh attack khớp hồ sơ cài đặt cuối; kích thước giữ như trên. Kết quả máy đọc trong `A/enemy_asset_verification.json`. Đây là kiểm tra file/hash, không phải chạy lại animation.
- **Bằng chứng lịch sử có file:** `output/integration/enemy_parts_2026-10-26_v2_redo/installed_validation.json` ghi `status=passed`, 6 tư thế, đủ 10 phần: walk 0/0.5s, run 0.25/0.75s, `detect player` 0.2s, RESET 0s; có `installed_rig_check.png`. Cảnh báo Bone2D cuối vốn có trong rig. Lượt bàn giao chỉ đọc kết quả này, **không chạy lại Godot/gameplay**.
- **Bằng chứng lịch sử trong chat, hiện thiếu artifact:** preview tách Uyển 21 PNG từng được ghép, xem bằng mắt và kiểm tra số file/góc alpha/hash nguồn. Vì thư mục kết quả không còn, không coi những kiểm tra đó là xác minh lại 30/10.
- **Chưa xác minh/chưa làm:** nghiệm thu tay già của Đản; độ chính xác nghi lễ/lịch sử của áo fantasy; sprite/rig/animation Đản; chiều cao Uyển tương đối Adel ở độ phân giải game; pivot/overlap/khớp chuyển động bộ tách Uyển; gameplay/export hiện tại và trạng thái editor Godot hôm nay. Không suy ra các điều này từ việc tạo được PNG.
- **Git hiện tại trước bàn giao:** nhánh `main`, HEAD `2ab87da`; working tree có sửa VFX/gameplay/tài liệu của công việc khác. Danh sách lưu ở `A/git_status_before_handoff.txt`: gồm `HANDOFF_anim.md`, hướng dẫn tuning, nghiên cứu animation, stats, saber_hitbox, playable_adel và các file Blood/Hit/Particles/tests chưa track. Không chỉnh/reset/commit chúng trong nhánh art này. Bản bàn giao 24/10 ghi HEAD cũ `dc45428` là lịch sử.

### Việc dang dở và bước tiếp theo

1. Chat mới đọc cập nhật này và `AGENTS.md`, kiểm tra Git/file trước khi làm; mở `A/dan_current_aged_hand.png` và `A/dan_before_aged_hand.png` để xác nhận đúng nhánh hình ảnh. Báo ngắn kết quả kiểm tra, tiếp tục chỉnh theo phản hồi của người dùng, giữ tay khoanh thấp/không gậy. Chưa có yêu cầu hình ảnh tiếp thì không tự chọn thiết kế mới hoặc tích hợp asset.
2. Nếu người dùng duyệt Đản và yêu cầu làm sprite/tách lớp: xác định đúng ảnh đã chọn và khuôn/dáng xuất, trình preview. Việc này chưa được làm; duyệt art không tự chứng minh tương thích rig.
3. Nếu quay lại Uyển: dùng `A/uyen_latest_sprite.png`; nếu cần bộ 21 PNG, phục hồi có kiểm soát từ 5 sheet và hai bản corrected, ghép preview từ chính các file đã tách. Giữ phân biệt vẽ lại/vẽ bù với cắt pixel; căn tỷ lệ/pivot sau khi có đúng yêu cầu, không thay Adel.
4. Nếu quay lại quái: dùng asset hiện hành + JSON integration đã kiểm tra; giữ tên/kích thước/hướng/ba frame ngang/rig. `death.png` hoặc `template.png` chỉ làm khi có yêu cầu mới. Không cài lại bộ cũ để phục vụ xem preview.
5. Lượt bàn giao chỉ sửa HANDOFF này và tạo bản sao tài nguyên trong A, không sinh ảnh mới, không thay PNG game/scene, không commit/push. Các bản minh họa đều còn là preview cho đến khi người dùng chỉ định dùng vào game.

## Cập nhật tiếp quản — 24/10/2026

**Ưu tiên mới được người dùng chọn:** triển khai chỉ số/trang bị/Coin/Soul theo phân kỳ. Không còn chờ chọn giữa Observe và chỉ số cho lượt này. **Các mục 1–10 bên dưới là snapshot trước lượt tiếp quản**; dùng cập nhật này, source và báo cáo hiện hành cho trạng thái mới.

**Đã triển khai:** tám thuộc tính/Resource cấu hình; điểm lên cấp; Character/Equipment dữ liệu thật; campfire phân bổ thử/xác nhận/hủy; SaveManager v2 và migration/archive v1; yêu cầu/scaling Saber, khóa Q; ví Coin/Soul và thưởng EnemyBase một lần mỗi vòng đời; Assimilation tăng damage Sentinel và giảm duy trì. Giữ HP/stamina hiện có khi tính lại, chỉ clamp theo tối đa mới; không hồi khi nâng. Các bộ số mới là cấu hình thử, chưa cân bằng nghiệm thu.

**Còn chờ:** inventory/trang bị nhiều món, giáp/passive, shop/bán/rèn boss, gameplay E, Observe/nhiệm vụ/thưởng tương ứng, Resistance giảm debuff ngoài Bleed/Fracture, Arts/Divine Arts, nguồn ulti và skill Dark Arts 1–4. Phạt thiếu yêu cầu giáp/giao dịch vật phẩm chưa hoạt động. Lần tiếp theo theo nhánh chỉ số nên xây dữ liệu và trạng thái inventory/equip trước khi nối các giao dịch; không lấy placeholder grid làm túi đồ đã xong.

**Tài liệu:** kế hoạch mục 8 đã cập nhật trạng thái; hướng dẫn tuning chung là nơi duy nhất quản lý số/vị trí chỉnh; báo cáo Player, UI/save và Enemy cập nhật tại chỗ. Các tài liệu Word và lịch sử giữ nguyên. Báo cáo tuần 6 vẫn mang định hướng Observe, chưa chỉnh để biến công việc mới thành kết quả nghiên cứu.

**Kiểm thử thực chạy trong lượt này:** `progression_validation` trên bản sao checkout hiện tại, có headless/native OpenGL và restart; hồi quy entry/save, Player refactor, campfire UI, Fracture, Q cooldown, Sentinel drain, Weapon HUD. Kết quả cuối: **57 headless + 57 native + 4 restart**, hồi quy **431 checks headless**, đều failures=0. Số checks có lặp giữa các mode, không phải kịch bản độc lập; giới hạn ở báo cáo Player. Evidence tại `C:/Users/xuank/.codex/visualizations/2026/10/24/01a16d43-bd9e-7380-8d06-40bfaf5f301e/`: `stats-project/`, `stats-*.log`, `stats-final-regression-results.json`; ảnh `stats-project/progression-*.png`. Dữ liệu game/config thử nằm trong APPDATA/custom user dir riêng, chưa chạy trên save chơi thật.

**Bảo toàn Git:** chưa commit/push. Các sửa rig, project.godot, scene test và Word có sẵn vẫn giữ. Trong lúc làm xuất hiện thêm `HANDOFF_lore.md`, `Context/co_cau_Varenne_doi_chieu_lich_su.md`; Git cũng ghi thay đổi khác ở đề cương/tài liệu Word do hoạt động ngoài lượt này. Không chỉnh/khôi phục những file đó. Godot MCP không có session kết nối khi kiểm tra; không force reload editor.

## 1. Bắt đầu ở đây

1. Xác nhận thư mục làm việc là `D:/Godot Project/soujourn--echoes-of-the-soul`; đọc [AGENTS.md](AGENTS.md), rồi kiểm tra Git và file thực tế trước khi sửa.
2. Đọc [kế hoạch chỉ số, trang bị và Coin/Soul](Ke_hoach_he_thong_chi_so_trang_bi_Coin_Soul.md). File phân biệt quy tắc đã chốt, số cân bằng đề xuất và phần chờ phát triển.
3. Đọc tài liệu hiện hành theo nhánh công việc ở mục 4. Báo cáo tuần phản ánh mục tiêu nghiên cứu; code/scene là bằng chứng về hành vi hiện đang có.
4. Báo ngắn những gì đã xác minh, điểm khác với bàn giao và việc kế tiếp có thể thực hiện. Các hạng mục đang plan chưa có lệnh triển khai thì tiếp tục khảo sát/chuẩn bị, không tự coi việc bàn giao là phê duyệt code.

**Cách đánh dấu bằng chứng trong file này:**

- **Xác minh 24/10:** đã đọc source, trạng thái Git, nội dung tài liệu hoặc kiểm tra đường dẫn trong lượt bàn giao.
- **Kết quả lịch sử:** thực sự đã chạy trong các lượt trước, có báo cáo/log; không phải game vừa được chạy lại trên checkout hiện tại.
- **Kế hoạch/đề xuất:** chưa phải gameplay đã hoàn thành. Không ghi thành kết quả nghiên cứu hay kết quả kiểm thử.

## 2. Mục tiêu và quy tắc làm việc

### Mục tiêu dự án

- Phát triển prototype RPG/platformer/metroidvania **Soujourn: Echoes of the Soul** trên Godot.
- Với báo cáo NCKH, các công việc gameplay đang phục vụ môi trường prototype. Mục tiêu nghiên cứu chính trong đề cương là mô hình và kiểm tra lỗi tiến trình cốt truyện; không dùng kết quả kiểm thử combat làm kết quả đánh giá mô-đun nghiên cứu.
- Người dùng đã yêu cầu **kế hoạch tuần kế tiếp tập trung triển khai Observe**, thay cho chỉ chuẩn bị tài liệu chung. Đây là định hướng trong báo cáo tuần, chưa phải bằng chứng Observe đã hoạt động.
- Thiết kế chỉ số/trang bị/Coin/Soul đã được tổng hợp; người dùng chưa yêu cầu triển khai nó. Chưa xác định ưu tiên code tiếp theo giữa Observe và hệ thống chỉ số bằng một lệnh triển khai mới.

### Yêu cầu của người dùng và AGENTS.md

- Giao tiếp bằng tiếng Việt, trả lời ngắn, nêu vị trí và cách chỉnh sau mỗi thay đổi có liên quan; không bắt người dùng phải mở tài liệu mới biết chỗ chỉnh.
- Khi người dùng nói “plan”, “chưa thực hiện”, “chỉ kiểm tra”, giữ đúng phạm vi đó.
- Mỗi thay đổi tunable phải cập nhật cùng lượt tại `Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md`: scene/node/nhóm Inspector hoặc script/hàm, ý nghĩa, đơn vị, mặc định script và override thực tế. Phân biệt giây game với giây thực.
- Báo cáo kỹ thuật hệ thống cập nhật tại chỗ, liên kết tới hướng dẫn tuning chung. Không tạo báo cáo rời cho mỗi thông số. File kế hoạch mới là thiết kế do người dùng yêu cầu, không thay thế hướng dẫn tuning hiện hành.
- Bảo toàn `.docx`, asset và tài liệu lịch sử của người dùng. Chỉ chỉnh đúng báo cáo mà người dùng đang yêu cầu sửa; không tự sửa/khôi phục/xóa tài liệu khác.
- Giữ các giá trị người dùng đã căn trong Inspector; phân biệt script mặc định, scene gốc, instance trong map và runtime. Không tự chỉnh lại animation, rig, damage, offset hoặc timing ngoài phạm vi.
- Test save/config/giao dịch trên **bản sao project và thư mục dữ liệu riêng**, không dùng save chơi thật.
- Không tự commit/push, reset hay checkout đè thay đổi. Lệnh commit/push trước đây thuộc tác vụ cũ, không phải quyền thường trực cho mọi lượt sau.
- Không thêm audio, hệ thống phụ hoặc tự triển khai Arts/vật phẩm chỉ vì đã có icon. Asset map mới phải cho người dùng xem/duyệt trước khi tích hợp.

## 3. Môi trường và Git đã xác minh

### Đường dẫn gốc

- Project thực tế: `D:/Godot Project/soujourn--echoes-of-the-soul`.
- Godot console tồn tại: `D:/Godot_v4.7-stable_win64_console.exe`.
- Remote: `https://github.com/Liebe-dev/soujourn--echoes-of-the-soul.git`.
- Nhánh hiện tại: **main**. HEAD đọc được: **dc45428**, ngày 17/10/2026, `title screen improve`.
- Các commit gần trước: `b0fa128` HUD update; `bb6a011` Complete Fracture effects and consolidate technical documentation.
- Lượt bàn giao không fetch/push nên chưa xác nhận HEAD có bằng remote mới nhất hay không.

### Thay đổi có sẵn trước khi tạo HANDOFF.md

Tracked đang sửa:

- `asset/Character/Adel/adel spine action use.tscn`.
- `project.godot`.
- `scenes/enemy/spine_enemy_test.tscn`.

Tracked đang bị đánh dấu xóa:

- `Context/Phương án triển khai Arc 1.docx`.

Untracked đã thấy:

- `Context/Ke_hoach_he_thong_chi_so_trang_bi_Coin_Soul.md` — file kế hoạch vừa tạo trong chat này.
- `Context/Bao_cao_tien_do/Báo cáo tiến độ NCKH tuần 6.docx`.
- `Context/Bản phác luồng cốt truyện Arc 1 An Châu.docx`.
- `Context/Bản phác luồng cốt truyện Arc 1 An Châu - cơ cấu Thống đốc.docx`.
- `Context/~$n phác luồng cốt truyện Arc 1 An Châu.docx` — file khóa Word, không phải nội dung báo cáo để commit.
- `asset/Character/Adel/layers/Adel spine action use/dark sentinel/`.

Không xác minh ai đã thực hiện mọi thay đổi trên. Giữ nguyên chúng; đặc biệt không tự khôi phục file Arc 1 bị xóa chỉ vì thấy trạng thái `D`. Bản bàn giao không đánh giá hoặc nghiệm thu các sửa rig/asset đang có.

### Junction và tài nguyên ngoài repo

- Đã xác minh junction `C:/Users/xuank/Documents/Codex` trỏ tới `D:/AI IDE/Codex`; trong lượt kiểm tra ngày 20/10 đã dùng đường dẫn cuối của file để xác nhận mở qua C là cùng file trên D. Junction còn tồn tại khi bàn giao.
- Project vốn ở D. Không suy ra mọi file chat cũng ở D: attachment, dữ liệu kiểm thử và ảnh tạm dưới `.codex`/`AppData` vẫn có đường dẫn riêng trên C; lượt 20/10 xác nhận chúng thực sự ở C.
- Tệp bàn giao đầu vào cũ còn truy cập được tại `C:/Users/xuank/.codex/attachments/1e865862-5a7d-4a61-b97c-804495c09189/Pasted text.txt`. Dùng làm lịch sử; yêu cầu mới và source hiện tại có ưu tiên hơn trạng thái cũ trong tệp.

## 4. Tài liệu và file cần tìm

Các đường dẫn tương đối dưới đây tính từ project gốc ở mục 3.

### Tài liệu hiện hành

- Khi tiếp quản **animation/VFX combat Adel**, đọc [HANDOFF_anim.md](HANDOFF_anim.md)
  trước khi sửa: yêu cầu và phản hồi đã chốt, nghiên cứu Limbus/After Effects,
  trạng thái hai lớp VFX, lỗi resource dùng chung, bằng chứng và bước tiếp theo ngày 26/10/2026.
- [Hướng dẫn tuning chung](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md) — nơi duy nhất quản lý vị trí chỉnh thông số runtime.
- [Player](../Bao_cao_ky_thuat/player_technical_report.md) — HFSM, combo, Q, Sentinel, phần đã làm/chờ làm và kiểm chứng.
- [Defense, Guard, Deflect, Stagger, Stamina](../Bao_cao_ky_thuat/defense_guard_deflect_stagger_stamina_report.md) — Fracture/Bleed, nhận đòn và hồi phục.
- [Enemy](../Bao_cao_ky_thuat/enemy_technical_report.md).
- [Camera, UI và save](../Bao_cao_ky_thuat/camera_ui_save_report.md) — HUD, menu, Controls, Video, save và lịch sử test liên quan.
- [Kế hoạch chỉ số, trang bị, Coin/Soul](Ke_hoach_he_thong_chi_so_trang_bi_Coin_Soul.md) — 283 dòng khi tạo; đã kiểm tra UTF-8, code fence, đủ tám thuộc tính và liên kết tương đối.
- [Đề cương gốc](../Godot_De_cuong_NCKHSV_2026-2027_final.docx) — phạm vi Observe, đồ thị tiến trình và đánh giá nghiên cứu. Không chỉnh bản Word gốc. `Context/De_cuong.md` đã được đọc đầu lượt tiếp quản nhưng hiện bị xóa bởi hoạt động ngoài lượt này; không tự khôi phục.

### Source và scene chính

- `project.godot`: Main Scene hiện trỏ `res://scenes/UI/title_screen.tscn`; autoload gồm InputBindings, VideoPreferences, SaveManager, PlayerProgress.
- `scenes/adel/playable_adel.gd` và `.tscn`: Player; component nằm tại `scenes/adel/components/`.
- `scenes/adel/components/saber_weapon_skill.gd`: gameplay Q và đồng hồ cooldown.
- `scenes/adel/components/skill_debug_settings.gd`, `scenes/UI/pause.gd`: công tắc cooldown debug.
- `scenes/UI/stats_component.gd`: model stats thuộc Player; `scenes/UI/ui.gd`: facade/trình bày HUD tương thích.
- `scenes/Mechanic/player_progress.gd`: progression cũ, hiện chưa thay bởi kế hoạch mới.
- `scenes/UI/character_menu.gd`, `.tscn`; `campfire_upgrade_menu.gd`, `.tscn`; `equipment_menu.gd`, `.tscn`.
- `scenes/UI/save_manager.gd`; `scenes/Mechanic/campfire.gd`.
- `scenes/UI/weapon/weapon_loadout.tscn`, `weapon_skill_slot.tscn` và script tương ứng.
- `scenes/UI/title_screen.gd`, `.tscn`; `title_menu_button.gd`; `save_slot_menu.gd`, `.tscn`.
- `scenes/UI/settings_menu.gd`, `.tscn`; `controls_settings.gd`, `.tscn`; `input_bindings.gd`; `video_settings.gd`, `.tscn`; `video_preferences.gd`.
- `scenes/enemy/spine_enemy_test.tscn`: scene Player/Enemy thử nghiệm thường dùng; có sửa chưa commit.

### Asset HUD

- Asset trong repo: `res://asset/UI/HUD/`; đã xác minh có `saber1.png`, `skill.png`, `Rectangle 4.png`, `Layer 10.png`, `weapon bar.png`, `saber.png`, `saber_q_icon.png`.
- Loadout hiện dùng **saber1.png** và **skill.png**, không lấy nhầm icon Q cũ chỉ vì cùng nằm trong thư mục.
- Người dùng từng chỉ asset ở `res://asset/UI/Menu screen/`; dùng đúng tham chiếu hiện tại của scene trước khi thay.
- Nguồn Photoshop người dùng nêu: `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Artbook/UI_UX/`. Thư mục tồn tại khi bàn giao, nhưng không xác minh mọi file riêng trong đó. Đầu cuộc trò chuyện từng có ảnh không đọc được ở đường dẫn này; ưu tiên asset đã import trong repo.

## 5. Quyết định thiết kế đã chốt nhưng chưa triển khai

Chi tiết, số đề xuất, migration và tiêu chí kiểm thử ở file kế hoạch; không sao chép toàn bộ bộ số cân bằng vào đây.

### Chỉ số

- Lên cấp nhận **5 điểm**, có thể điều chỉnh; bỏ nâng HP/stamina trực tiếp.
- Tám stat: **Vitality, Prowess, Strength, Agility, Resistance, Arts Compatibility, Dark Arts Assimilation, Faith**.
- Vitality tăng HP; Prowess tăng ATK; Strength quy đổi 40% HP + 60% ATK; Agility 80% stamina + 20% hồi stamina.
- Resistance: 20% HP, giảm xác suất/thời lượng debuff từ địch; **vô dụng với Bleed/Fracture** về tác dụng debuff.
- Arts Compatibility: hồi mana và hệ số 50% sát thương phép; chờ Arts.
- Dark Arts Assimilation: hệ số 30% hồi/tích ulti, giảm HP tiêu skill Dark Arts 1–4, hệ số 30% sát thương Sentinel; các mốc giảm HP rút khi duy trì Sentinel.
- Faith dành cho Divine Arts: giảm cooldown, kéo dài hiệu ứng. Divine Arts không tiêu mana, tiêu thanh ulti và có thể buff/debuff; khác Arts, chưa phát triển.
- Các tỷ lệ là **hệ số quy đổi**, không phải cộng 40/60/80/30% tổng tài nguyên mỗi điểm. Người dùng cho phép chọn số khởi điểm hợp lý để tự test/cân bằng sau; các số trợ lý đã chọn vẫn được đánh dấu **đề xuất**, không phải cân bằng đã nghiệm thu.

### Trang bị

- Mỗi vũ khí có yêu cầu chỉ số và scaling riêng.
- Thiếu yêu cầu: sát thương còn **20%**, không dùng skill của chính vũ khí đó; **Q tay phải, E tay trái**, xét độc lập từng tay.
- Giáp thiếu yêu cầu: còn **20% hiệu quả giảm sát thương**, passive của riêng món đó không hoạt động. Ví dụ giảm 25% bình thường còn giảm 5%, không phải giảm cố định 20% damage nhận.
- Vẫn được trang bị món thiếu yêu cầu; thiếu nhiều yêu cầu không nhân phạt nhiều lần.
- Xét chỉ số gốc hay tính bonus, cách gộp giáp, mapping S–E, yêu cầu cụ thể từng món và soft cap là phần đề xuất/chưa chốt. Không tự áp quy tắc cầm hai tay hay tải trọng của FromSoftware.

### Coin/Soul

- Coin: diệt quái, nhiệm vụ, bán đồ; dùng mua vật phẩm ở shop.
- Soul: diệt địch/boss và Observe; dùng rèn vũ khí đặc biệt; mua điểm nâng là khả năng giai đoạn sau.
- Rèn boss: lõi tinh thể ám thuật cô đặc rơi từ boss + nguyên liệu + Soul → vũ khí boss hoặc vũ khí dựa trên sức mạnh/hình tượng boss.
- Quản lý hai số dư riêng theo save; giao dịch rèn phải kiểm tra đủ điều kiện rồi trừ/trao đồng thời.
- Chưa chốt lượng thưởng, giá, cơ chế nhận thưởng Observe hay mất tiền khi chết. Thưởng Observe một lần/ID và cách ghi giao dịch là **đề xuất kỹ thuật**, không tự gán thành luật đã được người dùng duyệt.

### Chênh lệch với source đã xác minh

`PlayerProgress` vẫn là **1 điểm/cấp**, HP nền 100 +20/lần nâng, stamina nền 100 +15/lần nâng. `SaveManager.SAVE_VERSION` vẫn 1. Character/campfire còn dùng luồng cũ. Do đó việc ghi xong kế hoạch không có nghĩa hệ thống 5 điểm/tám stat/scaling/Coin/Soul đã chạy.

## 6. Việc đã hoàn thành trong chat

### Gameplay và UI ở các lượt phát triển trước

Các hạng mục sau đã được triển khai và có kiểm thử lịch sử; đọc báo cáo tương ứng và kiểm tra diff hiện tại trước khi kết luận checkout hôm nay vẫn vượt mọi test:

- Hoàn thiện Fracture, đồng bộ tác động damage/di chuyển/tốc đánh với hitbox; giữ Q có timing riêng. Bỏ nháy đỏ khi nhận đòn, giữ rung stagger.
- HUD vũ khí thường góc dưới trái dùng Saber lớn và icon Q do người dùng cung cấp; tay trái trống, bỏ khiên/skill E/chữ Q E dưới ô skill. Nền xám 32%, vá viền. Chưa thêm mana/Arts hoặc gameplay C/Z. Vào Sentinel ẩn loadout thường và hiện cụm Sentinel.
- Sửa lỗi Q giữ animation sau chuỗi trên không → giữ Q → tiếp đất → kết thúc skill. Cooldown gameplay nối HUD: viền xám, phủ đen 60% rút từ trên xuống, số giây; hết hồi trả viền trắng.
- Pause debug có **Skill cooldowns**: tắt xóa hồi hiện tại và bỏ hồi các lần sau tới khi bật lại. Trạng thái phiên debug, không lưu checkpoint/config; bật lại không tạo cooldown cho chiêu cũ.
- Đổi `menu (2)` thành `title_screen.tscn`; tổ chức nền, UI, transition và audio; gộp script nút, tách SaveSlotMenu, giữ UID và flow save.
- Settings phóng lớn, giữ trong viewport. Controls remap 13 thao tác bằng bàn phím/chuột, hai binding, conflict/reset/capture; lưu `user://controls.cfg`. Camera target lock dùng action thay vì hard-code chuột giữa.
- Video có Windowed/Borderless/Fullscreen, kích thước cửa sổ, VSync, giới hạn FPS, Apply/Revert/defaults, giữ thay đổi màn hình trong **15 giây thực** rồi hoàn tác nếu chưa xác nhận; lưu `user://video.cfg` riêng với checkpoint.

**Giá trị scene đã đọc khi bàn giao:** Q script mặc định 5/8/10 giây, nhưng `PlayableAdel.tscn` override **4/6/8**; hồi stamina scene **33 điểm/giây**, model mặc định 28; `weapon_loadout.tscn` lưu `hud_scale = 1.5`; Player scene `z_index = 200`. Không lấy số mặc định hoặc số plan ghi đè các override này. Instance trong map vẫn cần kiểm tra riêng.

Giới hạn hiện hành theo báo cáo: General settings là nội dung mẫu; âm lượng Music/SFX chưa lưu config; chưa nghiệm thu gamepad, export, mọi renderer/màn hình. Sentinel còn thiếu full skill Q/E/1–4, Sharpness/Toughness và nguồn ulti; entry chưa gọi xóa Bleed/Fracture. Vật phẩm tối đa ba ô/C-Z và Arts là thiết kế chờ, không phải gameplay đã hoàn tất.

### Báo cáo tuần 6

- Người dùng yêu cầu chọn lọc việc đã làm theo kế hoạch tuần 5, để người đọc hiểu là xây môi trường prototype; không cần liệt kê toàn bộ thay đổi game.
- Đã tạo báo cáo Word tuần 6; sau đó đổi phần tuần tới sang **Observe** và sửa kết luận cho khớp.
- **Xác minh hiện tại:** file đúng để đọc là `Context/Bao_cao_tien_do/Báo cáo tiến độ NCKH tuần 6.docx`. Mục III có cảnh Observe 2–3 dấu vết, tương tác/gợi ý/UI, trạng thái phát hiện và test lưu/tải; mục IV có hai đoạn kết luận chuyển trọng tâm sang Observe.
- File từng được giao tên `Báo cáo tiến độ NCKH tuần 6 - Observe.docx` **hiện không còn trong project**. Không tiếp tục sửa đường dẫn cũ hoặc tự tái tạo bản trùng. Chưa xác minh ai đã đổi tên/gộp bản, nhưng nội dung Observe và kết luận đã xác minh trong file hiện tại.
- Bản gốc ban đầu 2 trang; người dùng đã bổ sung ảnh và định dạng. Lượt chỉnh Observe/kết luận đã render, xem đủ **4 trang**. Việc đọc nội dung hiện tại không phải một lượt render lại file mới nhất.

### File kế hoạch mới

Đã tạo `Context/Ke_hoach_he_thong_chi_so_trang_bi_Coin_Soul.md` theo yêu cầu rõ ràng của người dùng. Có hiện trạng source, quyết định, số đề xuất, UI, save/migration, phân kỳ triển khai và tiêu chí kiểm thử. Lượt tạo file không sửa gameplay hoặc hướng dẫn tuning vì chưa đổi thông số runtime.

## 7. Việc dang dở và giới hạn cần giữ rõ

- Không có bản code đang viết dở cho hệ chỉ số trong chat này; phần đó dừng ở **plan**.
- Observe là kế hoạch tuần tới, chưa có triển khai/kiểm thử Observe được nghiệm thu trong chat. Tìm chuỗi `Observe/observe` trong `.gd/.tscn` dưới `scenes/` không thấy kết quả khi bàn giao; điều này chỉ xác nhận kết quả tìm theo tên, không chứng minh không tồn tại cơ chế tương tự dưới tên khác.
- Nếu làm Observe, đọc đề cương: nguyên mẫu có một cảnh 60–90 giây và 2–3 dấu vết; mô hình tối đa 40 nút/bốn biến đúng-sai cho toàn bộ phạm vi đề tài, không tạo tùy ý một biến tiến trình mới cho mỗi món. Phân biệt ID phát hiện với biến điều kiện đồ thị.
- Các tài liệu phác cốt truyện Arc 1 mới xuất hiện đã được ghi đường dẫn ở mục 3, **chưa đọc/đánh giá nội dung trong lượt bàn giao**. Không mặc nhiên coi chúng là bản thiết kế đã chốt hoặc thay thế đề cương.
- Các thay đổi chưa commit trong rig/project/map có thể ảnh hưởng runtime. Chưa chạy hồi quy mới sau những chỉnh sửa đó.
- Hai thất bại vị trí/rê con trỏ Windows trong suite camera native vẫn là giới hạn chưa giải quyết; không tuyên bố toàn bộ camera native sạch lỗi.

## 8. Kiểm thử và bằng chứng

### Phạm vi xác minh của lượt bàn giao

Đã đọc AGENTS, Git, các đường dẫn, nội dung báo cáo tuần hiện có, source progression/tuning liên quan và log Video lưu lại. **Không chạy Godot/gameplay mới**, không thử save thật và không nghiệm thu các sửa chưa commit.

### Kết quả lịch sử đáng dùng

- Fracture: 80 checks headless + 80 có render; báo cáo ghi tổng lượt Fracture/hồi quy 381 assertions. Xem báo cáo phòng thủ/Player để biết suite thành phần.
- Cooldown Q và công tắc debug: suite mở rộng 107 headless +107 có render; thêm enemy debug native 30. Có kiểm thử override Q 4/6/8.
- HUD scale: 44 headless +48 có render; Sentinel HUD 34 và layout 12 ở lượt liên quan.
- Title refactor: 38 headless +38 có render; entry/save hồi quy 60 headless.
- Controls: 54 headless +54 có render, thêm 2+2 checks khởi động mới. Camera headless 39; native cuối 58 checks, **2 fail** ở con trỏ. Baseline handler cũ cũng fail cùng nhóm, 56 checks/3 fail.
- Video: **37 headless +41 native OpenGL**, restart **2 headless +4 native**, đều failures=0. Đã đọc lại đúng log kết quả trong lượt bàn giao. Hồi quy headless title 38, Controls 54, entry/save 60 theo báo cáo; đã đọc lại log entry 60/0.
- Báo cáo Word: đã kiểm tra nội dung, bảo toàn phần không sửa và xem toàn bộ PNG của các lượt xuất cuối. File kế hoạch Markdown đã kiểm tra cú pháp cơ bản/liên kết; không phải test gameplay.

Các số headless/native có trường hợp lặp; không cộng thành số kịch bản độc lập hoặc dùng làm benchmark hiệu năng, cân bằng hay đánh giá nghiên cứu.

### Vị trí artifact kiểm thử

Gốc bằng chứng ngoài repo, gọi là **E** trong phần này:

`C:/Users/xuank/.codex/visualizations/2026/10/16/01a144f8-6226-7903-ab14-0a491bed9ca8`

- `E/fracture-project/`: bản sao project dùng test; tồn tại. Đây là bản thử cũ, **không phải checkout nguồn mới nhất**.
- `E/test-appdata/`: vùng APPDATA thử theo cấu hình các lượt trước; cần kiểm tra lại tồn tại/nội dung trước khi dùng.
- Log tồn tại: `fracture-headless.log`, `fracture-render.log`, `q-cooldown-before.log`, `q-cooldown-after.log`, `q-cooldown-render.log`.
- Debug: `skill-cooldown-toggle-overrides-headless.log`, `skill-cooldown-toggle-overrides-render.log`.
- Controls/camera: `controls-headless.log`, `controls-native.log`, `controls-lock-native-final.log`, `controls-lock-native-baseline.log`.
- Title: `title-refactor-ui-headless.log`, `title-refactor-ui-native.log`, `title-refactor-entry.log`.
- Video: `video-headless.log`, `video-native.log`, `video-restart.log`, `video-native-restart.log`, `video-title-regression.log`, `video-controls-regression.log`, `video-entry-regression.log`.
- Bản dựng báo cáo ban đầu: `E/weekly-report-20261022/build_report.py`, `artifact.md`, `final-render/`.
- Bản sửa Observe: `E/weekly-report-20261022/observe-plan-20261023/edited.docx`, `render/`.
- Bản sửa kết luận: `E/weekly-report-20261022/observe-conclusion-20261023/edited.docx`, `render/page-1.png` … `page-4.png` và `updated.pdf`. Đây là bản dự phòng/evidence, không phải file project phải sửa mặc định.

### Chạy lại test an toàn

- Suite nằm trong `tests/adel/`, `tests/ui/`, `tests/camera/`, `tests/flow/`, `tests/enemy/`; chọn đúng scene `.tscn` của thay đổi.
- Chỉ chạy trên bản sao đã đồng bộ file liên quan từ source. Giữ cấu hình test độc lập trong **bản sao**, không đưa cấu hình fixture vào `project.godot` thật.
- Các guard hiện có: Video yêu cầu user dir chứa `CodexEntrySave20261014-Video`; Controls chứa `CodexEntrySave20261014-Controls`; entry/save chứa `CodexEntrySave20261014`; camera lock bắt đầu `CodexLockCamera` trong `application/config/custom_user_dir_name`.
- Bản sao hiện lưu `config/use_custom_user_dir=true`, tên `CodexEntrySave20261014-Video20261017`. Đổi namespace theo suite; suite thoát vì guard không phải bằng chứng pass.
- Nếu dùng APPDATA riêng, đặt biến môi trường ở process test và kiểm tra `OS.get_user_data_dir()` vẫn trỏ nơi cách ly. Một số suite chủ động ghi/đổi/xóa fixture save/config.
- Headless không chứng minh được con trỏ hệ điều hành hoặc hiển thị native. Chạy render khi thay HUD/menu/display/input và xem ảnh thực tế.

## 9. Các cách đã thất bại và bài học tiếp quản

### HUD và cấu hình

- Sửa scene HUD gốc từng không thấy thay đổi trong `spine_enemy_test` vì override trên instance và logic runtime đặt lại scale. Đã xử lý ở các lượt trước; khi tái diễn, đối chiếu scene gốc → instance → Remote thay vì sửa script mặc định nhiều lần.
- Script mặc định Q 5/8/10 không phản ánh scene người dùng đã chỉnh 4/6/8. Fixture test có thể dùng mặc định để thử timing nhưng phải kiểm tra thêm override thật.
- Thêm autoload trong editor từng gặp cache identifier cũ; UI mới dùng `get_node('/root/InputBindings')`/`VideoPreferences` để tránh phụ thuộc cache global chưa cập nhật. Tool ghi project từ bộ nhớ editor có thể ghi đè sửa ngoài editor; kiểm tra và giữ snapshot `project.godot` trước thao tác đó.

### Test và công cụ

- Lỗi camera native không biến mất khi thử handler chuột giữa cũ; không sửa luật mouse pan để ép suite qua hoặc kết luận remap gây mọi lỗi con trỏ.
- Có cảnh báo rig Bone2D/UID legacy; chạy nhiều process từng làm FMOD tranh cổng live update. Đọc log để phân biệt cảnh báo với script error; không tự sửa rig/audio ngoài yêu cầu.
- Một probe SceneTree/ClassDB ngoài project từng làm Godot crash; Node probe trong bản sao hoạt động. Đây không phải lỗi gameplay đã xác nhận.
- Godot MCP có thể khả dụng hoặc không tùy phiên. Kiểm tra công cụ hiện có; không mặc nhiên cho rằng editor đang mở đúng scene hoặc script cache đã reload. `force_reload` có thể mất sửa chưa lưu.

### Tạo và sửa Word

- File tuần 6 từng đang mở trong Word, ghi trực tiếp bị `PermissionError`; đã giữ nguyên bản gốc và tạo bản “- Observe”. Hiện nội dung sửa đã có trong tên gốc; nguồn đổi tên/gộp chưa xác minh. Không đóng Word của người dùng để giải phóng khóa.
- Renderer tài liệu chuẩn từng thất bại do thiếu `soffice.exe` trên Windows. Không có bundled LibreOffice được tìm thấy trong lượt đó.
- COM Word trong sandbox trả `80070005 Access denied`; chạy lệnh xuất PDF bằng Word ẩn qua quyền mở rộng đã thành công. Chỉ mở tài liệu để đọc, xuất bản QA, đóng đúng tài liệu/process tự tạo; không save/đóng tài liệu khác.
- Cách render đã dùng: Word export PDF → nạp `render_docx.py` của skill và thay bước chuyển PDF bằng PDF đã xuất → rasterize bằng Poppler bundled → xem đủ PNG. Không sửa code của skill.
- Dùng runtime do `load_workspace_dependencies` trả về. Đường dẫn đã dùng: `C:/Users/xuank/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`; Node ở `dependencies/node/bin/node.exe`; Poppler ở `dependencies/native/poppler/Library/bin` cùng gốc runtime.
- Python Windows từng lỗi in tiếng Việt theo cp1252: dùng `sys.stdout.reconfigure(encoding='utf-8')` hoặc `PYTHONIOENCODING=utf-8`. Ưu tiên bundled Python, tránh alias Python hệ thống báo lỗi tìm executable.
- Khi tiếp tục sửa `.docx`, đọc skill Documents hiện có và làm render/visual QA; giữ bản trước sửa ở vùng QA. Không coi việc đọc XML đủ chứng minh bố cục.

## 10. Bước tiếp theo

### Việc làm ngay khi mở chat mới

1. Đọc bản bàn giao/AGENTS, kiểm tra cwd, Git, sự tồn tại và nội dung file chính; giữ các thay đổi người dùng ở mục 3.
2. Kiểm tra người dùng đang muốn tiếp tục **Observe**, **triển khai hệ chỉ số**, hay **chỉnh báo cáo**. Nếu chỉ có lời nhắn tiếp quản thì báo tình trạng trước; không tự khởi động cả hai hệ thống hoặc commit.
3. Với mọi yêu cầu sửa, xác định file/scene/override hiện hành và tiêu chí hoàn thành trước khi làm. Báo cáo vị trí chỉnh ngắn trong câu trả lời và cập nhật tài liệu theo AGENTS.

### Khi được yêu cầu làm Observe

Đọc đề cương và các bản phác cốt truyện hiện tại trước; chốt tình huống Observe phù hợp nội dung. Xây một lát cắt nhỏ từ phát hiện → gợi ý thao tác → hiển thị nội dung → ghi nhận tiến trình → lưu/tải, có 2–3 dấu vết thử. Kiểm tra quan sát lại, rời vùng, chặn input xuyên UI và khôi phục trạng thái. Không tự mở shop/rèn hoặc phát thưởng Soul trước khi có định nghĩa sự kiện/phần thưởng phù hợp.

### Khi được yêu cầu làm hệ chỉ số/trang bị/Coin/Soul

Theo phân kỳ và tiêu chí trong file kế hoạch. Ưu tiên mô hình thuộc tính/cấu hình, migration save và Character/campfire; sau đó Saber scaling/yêu cầu, rồi ví/phần thưởng và các luồng trang bị/giao dịch thật. Thực hiện trên nguồn mới nhất, giữ nhịp combat người dùng đã căn và ghi rõ phần chỉ mới là nền cho Arts/Divine Arts.

### Khi được yêu cầu chỉnh báo cáo

Dùng `Context/Bao_cao_tien_do/Báo cáo tiến độ NCKH tuần 6.docx` hiện có, giữ hình/định dạng người dùng đã bổ sung. Không quay về builder ban đầu vì sẽ làm mất các sửa thủ công. Chỉ thay phần được yêu cầu, bảo toàn phần còn lại và render lại.

**Trạng thái khi kết thúc bàn giao:** các phát triển gameplay mới vẫn ở mức kế hoạch; file kế hoạch đã hoàn thành; nội dung báo cáo tuần hiện có đã kiểm tra; bản bàn giao là thay đổi duy nhất của lượt này. Cần kiểm tra lại trạng thái lúc mở chat mới vì người dùng có thể tiếp tục sửa project.
