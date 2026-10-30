# Kế hoạch battle VFX cho Soujourn

Khởi tạo 28/10, cập nhật 30/10/2026, Asia/Saigon. **Trạng thái: hit slash Saber 1–4, máu bám Player và particles V3 đã duyệt, tích hợp.**

**Particles V3 30/10 — đã duyệt và tích hợp:** `PlayableAdel/BattleHitParticles`
dùng nguyên sheet preview, Q nhấn/tụ 1/tụ 2 phát 6/11/15 hạt, Player HP
stagger phát cố định 8 máu. Hướng chủ yếu gần ngang, hạt stagger sau toàn
bộ Player; giữ tuning V2 và Q brush hai răng. Quota, clock, lớp, phạm vi
trigger và trần 96 hạt xem [tuning hiện hành](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#battle-particles).
Production Player gọi trực tiếp ở nhánh HP stagger sau áp dụng knockback;
không dùng cờ chờ từ mọi `vitals.damage_received` như prototype. Q vẫn nhận
accepted target/hold thật, dùng chung deadline cho nhiều mục tiêu. Bằng chứng
tích hợp ở `soujourn-particles-integration-2026-10-30/` dưới Output preview;
phạm vi kiểm thực tế và giới hạn xem [bàn giao](HANDOFF_anim.md).

**Máu bám Player 29/10 — đã duyệt và tích hợp:** hai vết cơ thể ở hai vùng khác nhau, chọn độc lập 1/8 mẫu (được trùng) + một vệt cố định dưới mắt. Giữ `#850505`, alpha 0.8, thân rig cỡ ×1.4; theo mọi FBF/rig hiện dùng, giữ cùng nhóm khi đổi pose/facing. Component `PlayableAdel/PlayerBlood`, atlas/data tại `asset/VFX/Adel/Blood/`, có mapping 16 sheet / 31 frame FBF và 9 binding rig. Hồi đúng vạch bắt đầu fade 3s thực; nếu chưa hồi thì sau 150s bắt đầu fade; pause dừng tuổi. Signal hồi vạch từ model phân biệt với Sentinel ẩn/reset cờ. Hết stun không xóa, chết/restore checkpoint dọn; không thêm vào save. [Tuning hiện hành](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#player-blood), [phạm vi tích hợp và bằng chứng](HANDOFF_anim.md). Các đoạn preview cũ bên dưới là lịch sử, không còn là trạng thái chờ duyệt máu bám hiện hành.

**Hit slash V2 29/10 — đã duyệt và tích hợp:** người dùng duyệt bản **fade 200ms, dài ×1.30, dày ×1.00**, rồi chốt **enemy < dấu trúng < VFX kiếm**. Hướng lấy từ trục riêng từng PNG (đòn 1 khoảng −32.88°, đòn 2 −11.79°, đòn 3 −0.91°, đòn 4 −0.92°); affine kéo theo trục đó để nét chéo giữ độ dày/hướng. Component `PlayableAdel/SaberHitSlashVFX` nghe accepted `target_hit`, tạo dấu ngay callback, giữ `#EDF3F7` và hit-stop 35/55ms có sẵn rồi fade 200ms thực; pause dừng tuổi. Bốn PNG runtime ở `asset/VFX/Adel/Hit/` nguyên hash ảnh người dùng. Nhiều mục tiêu có dấu riêng; địch chết/xóa vẫn tan ở vị trí cuối. Q/jump, particles và máu bám chưa được nối vào dấu mới. Suite mới 84 checks + hồi quy VFX cũ 253 = **337 checks, 0 failures**; capture production Forward+ D3D12 có 8 hit/8 dấu ở hai hướng, 0 mẫu sai lớp và 16 PNG peak/fade. Trong manifest 74 nguồn của preview V2, 72 giữ nguyên, hai nguồn khác đúng dự kiến do thêm component/getter; diff Player script chỉ chuyển duration hold. Bằng chứng tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-hit-slash-integration-2026-10-29/`; [tuning hiện hành](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#saber-hit-slash), [phạm vi/giới hạn kiểm tra](HANDOFF_anim.md). GIF preview V2 cũ tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-hit-slash-motion-2026-10-29-v2-fade200-longer/` được giữ nguyên.

**Preview động hit slash V1 29/10 — lịch sử, nhịp/kích thước được thay ở V2:** người dùng yêu cầu hiện dấu chém ngay lúc hitbox ghi nhận trúng và fade cực nhanh nhưng có chuyển tiếp. Ánh xạ `D:/Downloads/1.png` → Saber Attack 1, lần lượt đến ảnh 4 → Attack 4. Đã capture native 426 frame/60fps trong project riêng, xuất GIF thường 7.1s và GIF đoạn hit chậm 0.25×/8s tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-hit-slash-motion-2026-10-29-v1/`, có GIF riêng từng đòn và 16 keyframe bằng chứng. Bản thử dùng **script SaberHitbox + capsule/animation hitbox nguồn không sửa, Area2D/body_entered thật**; địch có collider/rig nguồn với receiver preview nhận damage, chưa phải đầy đủ EnemyBase/AI. Tạo dấu ngay trong callback `target_hit` sau accepted damage, cùng process/physics tick; giữ đỉnh qua hit-stop combo 35/55ms, rồi **fade alpha tuyến tính 100ms, giữ nguyên hình/kích thước**. Mỗi dấu có 6 frame alpha trung gian; 4 accepted hits sinh đúng 4 dấu. Đánh hụt và contact bị từ chối damage không sinh dấu. Nhịp 100ms là lựa chọn để duyệt, chưa chốt runtime tuning. Giữ pose và vệt vung Saber cùng các override hiện có; đồng hồ vệt vung được cấp thời gian capture trong harness, hit-stop scale 0.05. 74 hash nguồn không đổi, không có script/render error; có cảnh báo Bone2D lá nguồn trong log. Chưa thử đầy đủ renderer/camera/map/nhiều mục tiêu của game; không thay Q, particles hoặc hệ máu bám/máu mặt.

**Hiệu chỉnh hit slash/particles 29/10 — V4, chưa duyệt tích hợp:** người dùng yêu cầu vệt chém ảnh 1 dùng **`#EDF3F7`**; máu văng ảnh 2 dùng **`#850505`**, thêm shading cơ bản cho particles và làm mặt bóng xương tối, phân rõ hơn. Đã tạo hai PNG nền trong suốt tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-battle-vfx-preview-2026-10-29-v4-palette-shading/`: slash ba hướng 2172×724; sheet 10 giọt/nét máu + 8 mảnh xương 1774×887. Mảng bóng preview: máu `#480303`, xương `#786D65`, xương sáng `#FBF1E1`; các màu phụ này do AI chọn để preview, chưa chốt runtime tuning. Dùng built-in imagegen chỉnh ảnh, rồi render palette phẳng bằng Godot riêng để chốt đúng hai mã màu nền; lấy mẫu pixel opaque xác nhận `#EDF3F7`/`#850505`, góc nền alpha 0. Đã kiểm hình, giữ ngôn ngữ mảng lớn/hai tông và ít chi tiết. Biên hình/alpha lấy từ bản AI sinh, không khẳng định khớp pixel nguồn. Chưa tích hợp game hoặc kiểm chuyển động; không đổi Q, tuning hoặc máu bám/máu mặt. Bản nguồn và trung gian giữ trong `references/` của thư mục preview.

**Màu máu bám được yêu cầu mới nhất 29/10: `#850505`**, thay tint `#CF1908` của preview trước. Giữ alpha **0.8**, bốn vùng đặt và quy tắc random hai vị trí/mẫu độc lập. Preview V4 tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-blood-placement-2026-10-29-v4-850505/`; chưa tích hợp game. Mã màu là tint của lớp máu trước khi hòa alpha với quần áo.

**Máu dưới mắt 29/10 — yêu cầu áp dụng toàn bộ animation, chưa tích hợp:** sau khi Player bị stagger tạo nhóm hai vệt máu ngẫu nhiên trên cơ thể, **luôn có thêm một vệt cố định dưới mắt**. Vệt mặt nằm ngoài pool chọn hai vùng. Cả máu mặt và máu cơ thể phải bám qua **mọi động tác FBF và rig xương**, kể cả sau khi hết pose stagger; đổi clip/frame hoặc chuyển FBF ↔ rig không xóa hay random lại vệt mặt. **Người dùng đã làm rõ: giới hạn hai ảnh chỉ nhằm tạo preview nhanh hơn, hoàn toàn không giới hạn phạm vi trong game ở Saber Def và idle.** Hai ảnh minh họa tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-blood-face-2026-10-29-v1-850505/`, vẫn hiện bốn vùng cơ thể như ảnh nguồn để duyệt vị trí, cộng vệt mặt. Lượt preview dùng built-in imagegen; **không phải native render, không khẳng định pixel/pose nguồn được bảo toàn tuyệt đối**, màu `#850505`/opacity khoảng 80% là chỉ dẫn prompt, chưa phải runtime tuning đã đo. Không dùng ảnh chỉnh làm sprite game. Chưa tích hợp, chưa kiểm mapping xuyên anim hay thay quy tắc fade/timeout đã có.

**Làm rõ phạm vi 29/10:** stagger là sự kiện tạo vết; máu phải tồn tại xuyên suốt mọi animation FBF và rig xương sau đó, cho đến khi đủ điều kiện tan. Không giới hạn hiển thị ở pose stagger. Preview V4 mới mapping hai frame stagger; chưa có bằng chứng chuyển FBF ↔ rig hoặc bám trên những animation còn lại. Phương án triển khai đề xuất ở mục 3.C, đang chờ duyệt cách làm.

**Preview ảnh rig xương 29/10 — chưa duyệt tích hợp:** đã render riêng bốn ảnh **chạy / đứng yên / nhảy / dash**, mỗi ảnh hiện đủ bốn vùng để duyệt, tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-blood-spine-poses-2026-10-29-v1-850505/`. Dùng các clip nguồn `run` 0.12s, `idle` 0.30s, `jump_air (fall)` 0.15s và `dash` 0.10s, tint `#850505`, alpha 0.8, cùng mẫu 5/2/3/8 qua bốn pose. Material preview theo sprite thân/tay/chân, giữ thứ tự che khuất của rig; hai vùng chân căn trên phần quần quanh đầu gối để thấy khi tà áo che đùi. Mapping này là đề xuất riêng cho rig, chưa duyệt tương ứng giải phẫu với FBF. Đã kiểm hình bốn ảnh, 16 binding vùng/pose có phần cơ thể đang hiện và 42 hash nguồn (41 texture + scene rig) không đổi; không có render/script error. Log có cảnh báo Bone2D lá từ rig nguồn. Chỉ là ảnh tĩnh theo yêu cầu, chưa chứng minh chuyển động/chuyển FBF ↔ rig hoặc lifecycle máu, chưa thay production.

**Phóng to máu thân 29/10:** theo yêu cầu phóng to vệt ở thân, preview V2 dùng hệ số **1.4 theo chiều rộng/cao** so với V1 trên cả bốn pose; mức 40% là lựa chọn preview, chưa được chốt làm runtime tuning. Giữ tâm/góc/mẫu thân, các vết tay/chân, tint `#850505` và alpha 0.8. Bốn ảnh đã render và kiểm hình tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-blood-spine-poses-2026-10-29-v2-torso140/`; 42 hash nguồn không đổi, không có render/script error. Chưa tích hợp game; V1 vẫn được giữ riêng.

**Preview ảnh FBF 29/10 — chưa duyệt tích hợp:** theo yêu cầu “saber attack 1 4, saber skill 6, saber def, saber guard”, đã dựng **4 ảnh / 5 pose**, ghép Attack 1 và Attack 4 chung ảnh. Nguồn/frame đếm từ 0: `mov_1_1.png` 0/3, `mov_1_4.png` 2/3, `sabers6.png` 1/2, `def1.png` 0/1 (`saber_defense`), `def3.png` 0/1 (`saber_guard`). Bộ ảnh tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-blood-fbf-poses-2026-10-29-v1-850505/`. Mỗi pose hiện đủ bốn vùng, mẫu 5/2/3/8, tint `#850505`, alpha 0.8 và hướng vệt thân lớn như spine V2; kích thước/góc được căn theo từng pose. Preview dùng polygon vùng thân/tay và alpha gốc để tránh vẽ máu thân lên tay đang che, giữ PNG nguồn nguyên vẹn. Đã kiểm hình cả bốn ảnh; lưu PNG OK, exit 0, không có render/script error; 8 hash bảo toàn (5 texture FBF + rig + 2 texture Q) không đổi. Đây là mapping đề xuất cho các frame được chọn, chưa có mapping đủ clip, chưa kiểm liên tục giải phẫu/chuyển FBF ↔ rig, motion, random hoặc lifecycle gameplay.

**Bổ sung vị trí/random 29/10:** người dùng yêu cầu máu sẫm hơn, vừa ba vùng khoanh trên tay/hai chân và random hai vị trí mỗi lần stagger. Pool hiện có **4 vị trí: thân cũ + bắp tay + chân A + chân B**. Mỗi lần chọn **2 vị trí khác nhau**, mỗi vị trí chọn độc lập 1/8 texture; **được trùng mẫu**, vị trí cũng có thể được chọn lại ở lần stagger sau. Giữ cặp vị trí/mẫu qua đổi pose. Preview riêng dùng tint `#9f2933`, alpha **0.8**, tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-blood-placement-2026-10-29-v2-dark-random/`; hình overview hiện đủ 4 vùng để duyệt mapping, hình random chỉ có 2 vết. Đã kiểm sampler 512 lần và render 64 tổ hợp mẫu/vị trí/pose, chưa tích hợp production. Hai vết trong cùng lần stagger là một nhóm gắn vạch và tuổi fade/timeout chung; quy tắc hồi vạch/2–3 phút giữ nguyên.

**Texture máu mới 29/10:** người dùng chọn `D:/Downloads/FX_Tex_BloodSprite.png` thay cho hình mảng máu tự tạo. Bản đỏ nền trong suốt hiện ở `D:/Downloads/FX_Tex_BloodSprite_red_alpha.png`. Theo yêu cầu giảm opacity thêm 20%, đã dựng preview tĩnh trên hai sprite stagger gốc với hệ số alpha **0.8**, ô dưới-trái của atlas 4×2. Bằng chứng tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-blood-on-player-2026-10-29-v1-alpha80/`. Đây là render riêng, chưa tích hợp mask/lifecycle vào game; file atlas và PNG nhân vật gốc giữ nguyên. Lựa chọn texture cụ thể này ưu tiên hơn mảng máu V2/V3 bên dưới.

**Màu preview mới nhất 29/10:** người dùng yêu cầu **màu sáng hơn** trên thiết kế đơn giản V2. V3 ở `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-battle-vfx-preview-2026-10-29-v3-brighter/`: hit slash gần trắng, máu đỏ tươi hơn, mảnh vỏ và bóng phẳng sáng hơn. Đây là preview hình, **chưa được duyệt tích hợp**; mã màu prompt chưa phải màu runtime đã khóa. Q brush và tuning game giữ nguyên.

**Hiệu chỉnh hình 28/10:** người dùng yêu cầu ăn nhập với nét nhân vật: **mảng màu lớn, ít shading, ít chi tiết nhỏ**. Preview V2 ở `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-battle-vfx-preview-2026-10-28-v2-simple/`: hit slash trắng ngà viền tối; particles ít phần tử và ít tông; máu bám một mảng đỏ liền. V2 thay hướng hình chi tiết của V1; V3 tiếp tục giữ hướng đơn giản này và nâng palette. Quy tắc máu theo hồi vạch/timeout giữ nguyên.

## 1. Mục tiêu và nền hiện hành

Tái hiện cảm giác combat quan sát được trong Limbus: pose có lực, tiếp xúc rõ, một đỉnh VFX nổi bật rồi phần dư hạ nhanh; phản ứng người nhận đòn tiếp tục đọc được sau mảng sáng chính. Phù hợp nhịp hành động trực tiếp của Soujourn và mức tiết chế người dùng đã chọn.

Giữ combo Saber 1–4, Jump AIR/LAND/Descent, Ready và Q brush V4 hai răng cưa đã duyệt. Q giữ hai màu #ef241e / #f55d58, các nét đỏ trong PNG nhân vật và override hold/lifetime 0.02/0.25s thực. Không dùng plan này để đặt lại tuning combat hoặc VFX cũ.

Phạm vi đợt đầu: **vết trúng trên địch, particles khi hai phía nhận đòn, máu bám Player sau stagger do đòn đánh**. Phần máu bám thực hiện theo quy tắc riêng người dùng yêu cầu, không ghi là cơ chế Limbus đã được chứng minh.

Nguồn quan sát/timestamp và giới hạn: [báo cáo nghiên cứu Limbus](../Bao_cao_ky_thuat/nghien_cuu_animation_combat_limbus.md), mục bổ sung 28/10. Đặc biệt:

- [Priest Gregor 0:19–0:22](https://www.youtube.com/watch?v=p1QAz4OdjR4&t=19s): đường vũ khí lớn, lóe tiếp xúc gọn và pose mục tiêu.
- [W Corp. 0:10–0:11](https://www.youtube.com/watch?v=gv0Hwl7u4-I&t=10s): nét rộng rút thành nét mảnh rồi mất.
- [Gameplay Smis 0:20–0:21](https://www.youtube.com/watch?v=0_BZIH8ciyU&t=20s): mảng chém chính mất trong khi lớp nhỏ/UI/pose còn tiếp nối.
- [Ring 0:38–0:42](https://www.youtube.com/watch?v=4wpmk1qVK5k&t=38s): màu trên trang phục và nền thuộc ngữ cảnh identity, không tự đồng nhất với máu do bị thương.

## 2. Ngôn ngữ hình ảnh đề xuất

- Nét vẽ bám nhân vật: mảng màu lớn, viền rõ, tối đa một vùng bóng phẳng khi cần; giảm hạt nhỏ và bỏ xước li ti/glow. Hình nhỏ vẫn đọc được ở camera chơi thật.
- Đỉnh đòn có một điểm nhấn chính. Thứ tự chú ý: tiếp xúc -> phản ứng mục tiêu -> phần hạt/dư. Mức đậm và diện tích giảm ở phần kết.
- Dấu trúng hiện hành theo yêu cầu 29/10 là mảng `#EDF3F7` với viền tối. Máu văng dùng nền `#850505` với một mảng bóng phẳng; mảnh xương có mặt sáng/tối phân rõ hơn và bóng tối hơn. Máu bám giữ thiết kế riêng đã preview. Palette mới phải có preview duyệt riêng; không đổi màu Q hoặc toàn bộ combo.
- Hình và hướng đi theo loại lực: chém có nét rạch và spray kéo theo hướng chém; va đập có burst gọn hơn. Không xoay ngẫu nhiên cùng một dấu cho mọi đòn.
- Dấu trúng mới theo yêu cầu 29/10 giữ hình và fade alpha cực nhanh sau đỉnh; preview hiện hành 200ms sau hit-stop, có các frame trung gian rõ. Vệt vung kiếm đã duyệt giữ chuyển động rút/thu hiện tại. Particles có quỹ đạo và tan theo profile riêng.

## 3. Ba nhóm cần làm

### A. Hit slash trên địch — Saber 1–4 đã tích hợp, mở rộng còn là kế hoạch

Một vết rạch `#EDF3F7` theo yêu cầu màu 29/10, mảng liền, viền tối và ít mẻ lớn ở vùng nhận đòn. Bỏ lớp đỏ xước/chi tiết quanh dấu của V1; máu là nhóm riêng. Xuất hiện tức thời khi hit được chấp nhận; theo yêu cầu mới giữ đỉnh qua hit-stop rồi fade alpha cực nhanh, không cắt biến mất ngay lập tức. Giữ hình/kích thước khi fade; preview hiện hành 200ms. Bám vùng thân mục tiêu trong tuổi ngắn, theo chuyển động nhận đòn. Với Saber Attack 1–4 dùng bốn ảnh người dùng cung cấp đúng thứ tự.

Saber 1–4 dùng bốn ảnh/hướng cố định đã duyệt, tự lật theo facing, không thêm góc random. Biến thể Q lao/jump là mở rộng cần preview duyệt riêng; với jump, hướng lực xuống thấp, không tự gắn hiệu ứng lên đầu mọi mục tiêu.

Điểm phát lấy vùng thân/hurtbox gần phía tiếp xúc, có anchor chỉnh được theo loại địch. Hiện signal target_hit chưa cung cấp tọa độ tiếp xúc chính xác, nên phải preview cả gần/xa và mục tiêu lớn/nhỏ, không coi vị trí WeaponPivot là điểm trúng trên địch.

Mỗi mục tiêu được một dấu cho mỗi hit thực đã được hệ combat chấp nhận. Q recovery `_6` có slash hình ảnh nhưng không tự sinh thêm phản hồi damage nếu không có hit mới. AIR/LAND cùng một lượt đánh không được nhân đôi phản hồi trên mục tiêu mà combat chỉ tính một hit.

### B. Particles cho địch và Player — đã tích hợp V3 ngày 30/10

**Yêu cầu hiện hành:** chỉ phát khi **Q trúng địch** hoặc **Player bị HP stagger**. Đòn Saber thường, jump, Q hụt, Player nhận hit thường và phản ứng cạn stamina không phát particles. Quy tắc này thay đề xuất hit thường/hit mạnh ở bản plan trước. Máu bám và dấu chém đã tích hợp giữ nguyên.

**Preview V1, chưa tích hợp:** dùng nguyên sheet `02_particles_850505_shaded.png` đã chỉnh: 10 mẫu máu, 8 mẫu xương, máu `#850505`/bóng `#480303`, xương `#FBF1E1`/bóng `#786D65`. Mảng lớn, hai tông, ưu tiên nét máu dài; một vài giọt gọn làm phụ. Mảnh xương có hai mặt rõ và xoay vừa phải.

**V3 đã duyệt 30/10:** hạt stagger nằm **sau toàn bộ Player**, giữ máu bám trên áo/mặt ở lớp hiện có; lớp Q không đổi. Phần lớn vận tốc ban đầu nằm ngang hoặc xuống 0–8°, chỉ 1–2 hạt/burst lệch lên nhẹ 8–12°: Q nhấn 5/6, tụ 1 10/11, tụ 2 13/15 và Player 7/8 hạt gần ngang. Hướng chính vẫn theo lực Q/knockback Player. Giữ nguyên mọi thông số V2 bên dưới, chỉ đổi góc và lớp stagger. Capture preview trước tích hợp có 224 frame, 23 checks native/56 mẫu lớp stagger đúng và 78 kiểm hướng/thông số qua; GIF thường 11.49s, chậm 0.33× 11.19s. Bằng chứng preview lịch sử tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-particles-q-stagger-2026-10-30-v3-behind-forward/`; bản tích hợp xem đầu file.

**Thông số V2 được giữ ở V3:** so với V1, cỡ hạt ×1.5; tổng lượng ×1.5 làm tròn gần nhất, .5 lên; vùng sinh quanh cùng neo rộng/cao ×3; tốc và tham số tầm ×3. Q nhấn **6 (4 máu/2 xương)**, tụ mức 1 **11 (8/3)**, tụ mức 2 **15 (10/5)**, Player HP stagger **8 máu cố định**. Tốc Q 720/1080/1560 và Player 660 world px/s; tầm cơ sở 165/270/405/156 world px. Vùng sinh half-extents (12,15) thay (4,5). Neo cơ thể, lifetime, gravity, fade, palette và Q nguồn giữ nguyên. Khung QA mở rộng để xem tầm văng; không thay camera runtime. V2 lịch sử tại `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-particles-q-stagger-2026-10-30-v2/` được giữ nguyên. Các thông số V2 này đã được giữ nguyên khi duyệt và tích hợp V3 ngày 30/10.

**Mốc V1 lịch sử** (đã thay bởi V2, không phải thông số runtime đã duyệt):

- Q nhấn/tier 0: **4 hạt = 3 máu + 1 xương**, tốc đầu 240 world px/s, giới hạn quỹ đạo cơ sở 55 world px, máu sống 0.42s.
- Q tụ mức 1: **7 hạt = 5 máu + 2 xương**, tốc 360 px/s (×1.50), tầm cơ sở 90 px (×1.64), máu sống 0.48s.
- Q tụ mức 2: **10 hạt = 7 máu + 3 xương**, tốc 520 px/s (×2.17), tầm cơ sở 135 px (×2.45), máu sống 0.55s.
- Player HP stagger: **cố định 5 giọt máu**, không xương; tốc 220 px/s, tầm cơ sở 52 px, sống 0.44s. Chỉ một burst của hit gây stagger, không phát liên tục trong pose stun.

Giữ đúng số hạt mỗi profile; random mẫu/góc/kích thước trong biên nhỏ, không random tổng lượng. Tốc/tầm từng hạt dao động ±10%; mảnh xương dùng 75% tốc/tầm của profile, sống lâu hơn máu 0.10s. Hướng văng theo facing Q, hoặc hướng bật lùi thật của Player. Hạt văng theo quạt, giảm tốc theo đường cong rồi rơi, fade tuyến tính 0.13s cuối. Điểm phát Q đặt về mép thân theo phía văng để xương không chìm trong mảng trắng của địch; Player phát cao hơn tâm collider 20 world px. Đây là neo preview, chưa phải điểm tiếp xúc pixel chính xác.

Sinh ngay accepted Q hit, giữ đỉnh theo hit-stop được skill chấp nhận (65/75/100ms hiện hành), rồi chuyển động bằng giây thực không pause. Giữ nguyên charge time, dash, damage, stun, camera pulse và Q brush hai răng cưa. Mỗi mục tiêu accepted nhận một burst; Q recovery `_6` không sinh thêm burst. Hạt bay trong world, không kéo theo nhân vật; pause giữ tuổi/vị trí, không đặt lại tuổi khi đổi clip. Không đọng sàn/nảy đất trong bản đầu.

**Điểm nối trong project preview lịch sử (runtime hiện hành xem đầu file):** `SaberHitbox.target_hit` lọc `saber_skill` + skill đang active, đọc tier thật; `impact_confirmed` lấy hold accepted. Player dùng kết quả `vitals.damage_received` để đánh dấu HP stagger, rồi phát ở `DamageComponent.staggered` đồng bộ với phản ứng thật; loại stamina exhaustion, ordinary hit, bleed/self-drain. Toàn bộ bridge/emitter ở project thử, chưa thêm vào source runtime. Không cần thay JumpAttackHitbox cho phạm vi mới này.

**Bằng chứng V1:** thư mục `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-particles-q-stagger-2026-10-29-v1/`, có GIF thường/chậm 0.33×, PNG native, timeline và project thử. Ba Q dùng input/physics production và đủ thời gian tụ lực gốc; Player gọi API damage thật để gây gãy vạch, AI/vitals/HUD tắt. Kiểm Q nhấn/tụ 1/tụ 2 và HP stagger đúng profile/lượng, tầm Q tăng dần, fade có alpha trung gian; ordinary Saber contact, ordinary Player damage, stamina exhaustion và Q hụt không sinh burst. Đây là native preview của component particles thử, không khẳng định đã tích hợp game hoặc đã kiểm mọi trường hợp nhiều mục tiêu/hai hướng.

Các bước duyệt chuyển động và tích hợp V3 đã hoàn thành ngày 30/10; mục prototype phía trên giữ làm lịch sử. Player particles chỉ là máu; xương thuộc profile Q trên địch. Thay đổi hình/motion tiếp theo vẫn cần preview → duyệt → tích hợp theo phạm vi người dùng yêu cầu.
### C. Máu bám Player — thiết kế đã duyệt, triển khai hiện hành xem đầu file

Vết đỏ sẫm nằm trên vùng thân/quần áo; mask theo phần nhân vật đang hiển thị và giới hạn vùng thân, không nhuộm cả khung chữ nhật/silhouette vũ khí. Phải kiểm cả frame-by-frame và phần rig đang dùng cho di chuyển. Máu theo Player khi đẩy lùi/quay mặt/đổi pose, không trôi trong màn hình.

**Vệt mặt bắt buộc:** khi có nhóm máu do stagger, luôn thêm một vệt dưới mắt ngoài hai vệt cơ thể ngẫu nhiên. Phạm vi gồm mọi animation FBF và rig xương, không riêng stagger/Def/idle. Mapping phần mặt theo đầu và vùng dưới mắt của từng hình, dùng cùng trạng thái máu xuyên đổi clip/frame/chế độ hiển thị. Hai ảnh preview mặt là minh họa vị trí, không phải danh sách animation được hỗ trợ trong thiết kế.

**Phương án bám xuyên animation — thiết kế làm nền cho tích hợp 29/10:**

- Giữ một bộ dữ liệu vết máu ở Player, độc lập với clip đang chạy. Một lần stagger tạo nhóm hai vết: vùng cơ thể, mẫu atlas, vị trí trong vùng, màu/alpha, vạch liên quan và tuổi. Đổi clip, frame hoặc chế độ hiển thị không random lại, không tạo lại nhóm và không đặt lại bộ đếm.
- Dùng bốn vùng cơ thể thống nhất giữa hai cách hiển thị: thân, bắp tay, chân A, chân B. Vùng là danh tính phần cơ thể, không phải vị trí trái/phải trên màn hình; phải đối chiếu lại tương ứng giải phẫu của các vùng preview khi lập mapping toàn bộ pose.
- Rig hiện tại là `Skeleton2D`/`Bone2D` với các `Sprite2D` riêng và nhiều biến thể phần thân/tay/chân bật tắt theo clip trong `asset/Character/Adel/adel spine action use.tscn`. Đề xuất hòa máu trong material của từng sprite phần cơ thể theo tọa độ texture của phần đó, với mapping cho mọi biến thể đang dùng. Như vậy vết theo transform của phần cơ thể, cắt theo alpha của phần đó và giữ thứ tự che khuất đang có; không cần đổi animation xương.
- FBF hiện dùng `TestAttackSprite`, đổi texture/hframes/frame và cả position theo clip. Cần một bộ dữ liệu đặt vết theo từng frame nguồn: điểm neo, góc, kích thước hoặc tứ giác khi pose cần bóp méo, cùng mask vùng cơ thể đang lộ. Dùng cùng mẫu vết đã lưu để chiếu vào vùng tương ứng của frame hiện tại. Mask chỉ silhouette toàn người không đủ để ngăn máu thân vẽ đè lên tay/vũ khí che phía trước.
- Giữ atlas máu và PNG nhân vật riêng; dữ liệu mapping/mask là tài nguyên phụ, không vẽ máu cố định vào PNG từng animation. Có thể dùng lại mapping cho frame trùng hình; các pose khác vẫn phải căn và duyệt. Vùng bị che tạm thời chỉ ngừng vẽ phần khuất, dữ liệu vết và tuổi vẫn còn.
- Khi chuyển FBF ↔ rig, hai phần hiển thị đọc cùng dữ liệu nhóm vết. Cập nhật theo hình thực đang hiện sau khi animation áp pose, kể cả giữ frame stagger, Ready biến thể, hit-stop và lật hướng. Phải kiểm chỗ đổi hình để tránh một frame mất máu hoặc xuất hiện cả hai lớp.

Bước preview tiếp theo cho phương án này: giữ nguyên một cặp vết và chạy chuỗi **stagger → idle → walk/run → combo → Q → jump → idle**, cả hai hướng, có pose tay che thân/chân chồng nhau. Duyệt độ bám, che khuất và tính liên tục trước khi nối vào sự kiện combat thật. Giữ tint `#850505`, alpha 0.8 và tuning animation/VFX đã duyệt.

Điều kiện: một đòn trực tiếp gây gãy vạch stagger HP; phân biệt với phản ứng cạn stamina. Mỗi lớp liên kết với vạch đã gãy. Giới hạn độ phủ và số lớp, không cộng dồn đến khi toàn thân thành một mảng đỏ.

**Quy tắc người dùng đã yêu cầu:** vạch liên quan hồi lại thì vết tan dần trong vài giây; vạch chưa hồi thì vẫn tự tan sau khoảng 2–3 phút. Hết stun/đứng dậy không phải sự kiện hồi vạch. Khi bình hồi một vạch, chỉ cho lớp liên quan tan; hồi toàn bộ thì cho các lớp còn lại tan. Theo trạng thái gameplay thực, không coi việc UI tạm ẩn vạch là hồi phục.

Mỗi vết có tuổi riêng; hit thường không đặt lại tuổi tất cả vết. Đề xuất dùng thời gian chơi thực, dừng bộ đếm khi pause/menu. Chết/respawn phải dọn dữ liệu hiển thị đúng lifecycle; không tự thêm máu vào dữ liệu save.

## 4. Nhịp hiện hành và giả thuyết thử

Hit slash Saber 1–4 đã thành runtime tuning sau duyệt; giá trị particles/máu bên dưới vẫn là giả thuyết preview, không phải số đo từ Limbus:

- Hit slash Saber 1–4: đã duyệt và tích hợp fade alpha 0.20s thực sau hit-stop, giữ hình/kích thước khi fade; dài ×1.30, dày ×1.00. Saber 1–3 giữ theo accepted hit-stop 0.035s, đòn 4 là 0.055s hiện có; hit-stop tắt thì không thêm hold. Suite đã kiểm clock không phụ thuộc time_scale và pause. Q 65/75/100ms chỉ xem xét khi preview mở rộng phạm vi.
- Particles theo phạm vi mới: chỉ Q trúng và Player HP stagger. Preview V2 dùng Q 6/11/15 hạt theo tier, Player cố định 8 máu; thời gian/tốc/tầm và hệ số so với V1 ở mục 3.B. Các mốc hit thường 4–6/hit nặng 6–8 của plan cũ đã bị thay thế.
- Máu bám: runtime dùng fade 3s khi vạch hồi; timeout 150s rồi fade, tính theo nhóm hai vết của một stagger. Đây là lựa chọn cụ thể trong khoảng người dùng đã chốt vài giây/2–3 phút; chỉnh tại PlayerBlood theo hướng dẫn chung.
- Kích thước dấu/hạt căn theo kích thước thân mục tiêu và hệ tọa độ game; không lấy pixel screenshot YouTube làm đơn vị world/source-frame.
- VFX ngắn cần đồng bộ hit-stop và kết thúc rõ; quy tắc pause của hiệu ứng mới phải được kiểm riêng, không thay hành vi pause hiện có của combo/Q.

## 5. Điểm nối source dự kiến

- Saber 1–4 đã nối `SaberHitSlashVFX` vào `scenes/adel/components/saber_hitbox.gd.target_hit`; hai getter mới chỉ đọc tên/generation. Player chuyển duration hit-stop đã được chấp nhận sau `hit_confirmed`, không đổi logic dedup/damage/hit-stop. Q vẫn dùng signal cũ cho lifecycle riêng, chưa thêm dấu trúng Q.
- Jump không phát particles theo phạm vi mới. Nếu sau này mở rộng dấu trúng Jump mới xét bổ sung kết quả hit theo quy ước Saber; giữ cửa sổ/damage/dedup AIR/LAND hiện có.
- Player particles chỉ phát khi đòn trực tiếp sau Defense gây HP stagger; loại ordinary hit, stamina exhaustion, Bleed, tự tiêu HP và đòn miễn nhiễm. Máu bám production giữ lifecycle riêng.
- Máu bám: theo trạng thái vạch ở `StatsComponent` qua lớp vitals/presentation; không bám riêng signal `DamageComponent.stagger_recovered`. Kiểm đường hồi bình, vùng an toàn, Sentinel và respawn để không nhầm thay đổi mode với hồi vạch.
- Tách phần trình bày mới thành component/profile tái dùng. Một sự kiện nhận hit mô tả mục tiêu, anchor tại tiếp xúc, hướng/loại đòn và mức phản hồi; không biến component VFX thành nơi quyết định damage/stagger.
- Lưu snapshot transform/anchor trước khi đối tượng có thể chết/xóa. Hạt đã văng hoàn thành trong world; dấu còn bám xử lý an toàn khi mục tiêu biến mất. Có giới hạn số hiệu ứng sống đồng thời và cleanup khi đổi scene/thoát.

## 6. Preview -> duyệt -> tích hợp

1. **Duyệt hình:** một sheet hit slash đủ hướng ở peak, một sheet giọt/mảnh ở kích thước chơi thật, máu bám trên Player ở ít nhất pose stagger và đứng. Mỗi nhóm thể hiện đủ lớp dự định có trong game. Giữ rig/PNG nguồn nguyên vẹn.
2. **Duyệt chuyển động particles trong bản thử riêng:** Q nhấn/tụ 1/tụ 2 trúng địch và Player HP stagger; xác nhận ordinary hit/Q hụt/cạn stamina không phát. Xuất bản thường và chậm từ capture thật. Khi tích hợp kiểm thêm UI, hai hướng, nhiều mục tiêu, ngắt, pause và kết liễu; không đổi lifecycle máu bám đã có.
3. **Chốt hình/màu/nhịp:** sửa preview theo phản hồi. Không suy ra duyệt hình tĩnh là đã duyệt toàn bộ motion/ghép game.
4. **Tích hợp nhóm đã duyệt:** kết nối đúng sự kiện production, kiểm tra phạm vi thay đổi và hash asset cần bảo toàn. Cập nhật hướng dẫn tuning cùng lượt cho mọi export/override mới, rồi cập nhật README/bàn giao phù hợp.

Mọi preview/ref/video/log và project thử ở `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/`, theo thư mục con rõ tên. Chỉ asset runtime đã duyệt và source cần thiết vào project. Không commit/push hoặc force reload editor theo plan này.

## 7. Tiêu chí nghiệm thu

- Nhìn camera chơi thật nhận ra ai vừa trúng và hướng lực; nhân vật/địch vẫn đọc rõ khi có UI, nền sáng/tối và nối đòn.
- Hụt không có dấu trúng; nhiều mục tiêu có phản hồi riêng; một hit không phát lặp vì nhiều signal/collider; hit kết liễu không lỗi hoặc mất hạt ngoài ý muốn.
- Particles đúng ba tier Q ở hai hướng, Q recovery không gây hit giả; combo thường/jump không phát particles. Giữ nguyên accepted hit-stop và các VFX combo/jump đã tích hợp.
- Player chỉ có particles khi HP stagger do đòn trực tiếp; một burst cố định cho hit đó. Ordinary damage, stamina exhaustion, deflect/iframe và tick Bleed không sinh spray. Máu bám vẫn chỉ tạo nhóm đúng HP stagger.
- Máu theo pose/facing, mask không lộ hình chữ nhật hoặc nhuộm cả vũ khí; hồi đúng vạch mới fade đúng lớp; hết stun không tự xóa; fallback 2–3 phút hoạt động riêng mỗi vết.
- Pause, freeze/slow motion, đổi scene, Sentinel, chết/respawn và mục tiêu bị xóa có cleanup đúng. Có giới hạn hiệu ứng khi đánh đám đông; xem và đo frame time trên renderer game trước khi chốt mật độ.
- Không thay damage, collider, animation thân, camera hoặc tuning hiện có để làm preview đẹp hơn. VFX mới phải phối hợp với thiết kế đã duyệt.

Saber 1–4, máu bám/máu mặt và particles V3 đã qua preview → duyệt → tích hợp, bằng chứng ở bàn giao hiện hành. Các mở rộng ngoài phạm vi này cần duyệt riêng.
