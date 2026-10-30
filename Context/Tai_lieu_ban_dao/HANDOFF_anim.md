# Bàn giao animation / VFX combat Adel

**Cập nhật: 30/10/2026, Asia/Saigon; giữ snapshot 28/10 và lịch sử từ 26/10.** Project: `D:/Godot Project/soujourn--echoes-of-the-soul`.
File này ở `D:/Godot Project/soujourn--echoes-of-the-soul/Context/Tai_lieu_ban_dao/HANDOFF_anim.md`.

## Hiện hành 30/10/2026 — particles V3 đã duyệt và tích hợp

Người dùng đã **duyệt V3**, cho phép đưa particles vào game. Component mới
`PlayableAdel/BattleHitParticles`, script
`scenes/adel/components/battle_hit_particles.gd`, node không có scene override.
Sheet/cell data nguyên byte preview tại `asset/VFX/Adel/Particles/`.
Giữ Q brush hai răng cưa của snapshot 28/10, hit slash và máu bám đã tích hợp.

- Chỉ accepted Q impact trên địch và HP stagger Player do đòn trực tiếp.
  Q nhấn/tụ 1/tụ 2 **6/11/15** hạt (**4/2, 8/3, 10/5 máu/xương**);
  Player **8 máu cố định**. Cỡ/vùng sinh/tốc/tầm/lifetime/gravity/fade đúng V2,
  hướng gần ngang và lớp sau Player đúng V3. Không phát ở combo/jump,
  Q hụt/rejected, ordinary Player hit, iframe/deflect, cạn stamina,
  Bleed hoặc tự tiêu HP.
- Q giữ cụm qua accepted hit-stop từ `impact_confirmed`, chung deadline mỗi
  swing; không thêm timing Q riêng. HP stagger gọi sau `damage.apply_stagger`
  trong `take_damage`, lấy vận tốc knockback đã áp dụng. Khác prototype ở
  điểm này: không giữ cờ chờ từ mọi signal damage để tránh lẫn nguồn mất HP.
- Sprite world anchored; địch chết/xóa hoặc Q ngắt không kéo/mất burst cũ.
  Pause dừng tuổi; slow motion không kéo dài. Chết/restore checkpoint dọn
  ngay; sprite top-level vẫn là con của component để xóa cùng Player/scene.
  Trần **96 sprite/Player**, đầy thì bỏ hạt cũ nhất, không chặn target damage.
  Lớp Q cập nhật source Z −3; stagger cập nhật thấp hơn mọi Sprite2D cơ thể
  rig/FBF. Không đổi vị trí/lớp material máu bám.

**Đã chạy:** bộ mới `battle_particles_validation.gd` **95/95**; hồi quy máu
bám **134**, dấu chém **84**, Saber VFX **68**, Q VFX **98**, gameplay Q
**160**, guard/stamina **96**, Fracture **80**, tổng **815 checks headless,
0 failures**. Gồm hai hướng, nhiều accepted target, dedup, rejected/whiff,
đòn kết liễu queued deletion, ngắt Q, world anchoring, pause/time_scale,
đổi rig/FBF, quá trần, chết/respawn và xóa scene/owner. Kiểm cơ học không
được diễn giải thành 815 tình huống gameplay độc lập.

Native Forward+/D3D12 exit 0: **233 frame**, **23 checks qua**, **64 mẫu lớp
stagger**, 0 mẫu sai; quota đúng **6/11/15/8**, Q có accepted hold khoảng
65/75/100ms, alpha tan có trung gian. GIF thường **11.64s**, chậm 0.33×
**11.16s**; bốn PNG peak đã được xem. Capture dùng input/physics Q thật,
`Player.take_damage` thật, observer chỉ đọc component production để ghi số
liệu. AI/vitals/HUD tắt và camera đóng khung QA; không coi là kiểm mọi map,
UI/nền/crowd hoặc đo hiệu năng gameplay. Hai hướng/nhiều target/lifecycle
được kiểm headless; capture native gồm Q hướng phải và Player knockback trái.

**Bảo toàn:** baseline 125 source/runtime/asset so với trước tích hợp có
**123 nguyên hash**, chỉ Player script/scene khác đúng dự kiến do nối node,
trigger và cleanup. Hai asset particles khớp hash V3; Q brush/rig/animation,
collider, camera, damage và toàn bộ tuning cũ nguyên hash. Git vẫn **main /
2ab87da**, giữ các thay đổi chưa commit của lượt hit slash/máu bám và các
thay đổi tài liệu khác trong workspace; không commit/push hoặc force reload.

Media, log, manifest, source snapshot và project thử tại
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-particles-integration-2026-10-30/`.
Project thử dùng custom user directory và APPDATA riêng; FmodManager chỉ bị
tắt trong clone vì mismatch API có sẵn, không đổi audio/settings thật. Log
cuối không script/render error; warnings Bone2D/UID nguồn vẫn còn. Tuning đầy
đủ ở [hướng dẫn chung](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#battle-particles).
Các mục preview dưới đây là lịch sử trước duyệt, không phải tác vụ còn chờ.

## Lịch sử preview 30/10/2026 — V3 stagger sau Player, hướng văng gần ngang

Hai yêu cầu mới: **particles stagger ở sau nhân vật** và **đa số hạt văng
ra trước, hạn chế góc trên**. V3 giữ nguyên lượng/cỡ/tốc/tầm/vùng sinh, màu,
shading và thời gian tan của V2; vẫn chỉ là preview, chưa tích hợp particles.

- Hạt Player stagger dùng Z thấp hơn toàn bộ sprite cơ thể trong Skeleton2D
  và FBF; cập nhật khi chạy để không nổi lên trước khi đổi pose. Máu bám trên
  áo/mặt vẫn ở material nhân vật như trước. Nhánh lớp Q giữ source depth −3.
- Hướng chính theo lực Q/hướng knockback Player, **0–8° xuống nhẹ**; chỉ
  một hạt của nhóm có ít nhất bốn phần tử lệch lên **8–12°**. Kết quả Q nhấn
  5/6 gần ngang, tụ 1 10/11, tụ 2 13/15; Player 7/8. Không đổi chiều lực
  Player sang facing; chỉ thu góc quạt gần ngang.
- Native Forward+/D3D12 exit 0: **224 frame**, GIF thường **11.49s**, chậm
  0.33× **11.19s**. **23 checks native qua**, gồm 56 mẫu hạt stagger ở sau
  sprite Player đang hiện, 0 mẫu sai lớp. **78 kiểm góc/thông số qua**; đây
  là các kiểm cơ học, không phải 101 tình huống gameplay độc lập.

Đã xem PNG peak Q tụ 2 và stagger để kiểm hướng, che khuất; log cuối không
script/render error, Bone2D warnings nguồn còn. Hash source/runtime được
lưu cùng bằng chứng, không sửa runtime game. Các giới hạn hai hướng/nhiều
mục tiêu/pause/kill của preview trước vẫn còn. Media/log/project tại
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-particles-q-stagger-2026-10-30-v3-behind-forward/`.
V2/V1 giữ nguyên; quy trình vẫn preview → duyệt → tích hợp.

## Lịch sử preview 30/10/2026 — particles V2 tăng cỡ/lượng/vùng sinh/tốc/tầm

Người dùng yêu cầu so với V1: **cỡ ×1.5, lượng ×1.5, vùng sinh ×3, tốc và
tầm văng ×3**. V2 chỉ là preview chỉnh tiếp, **chưa duyệt tích hợp particles**.
Giữ phạm vi Q trúng địch và Player HP stagger, không mở sang hit thường/jump.

- Q nhấn **6 hạt (4 máu/2 xương)**, tụ 1 **11 (8/3)**, tụ 2 **15 (10/5)**;
  Player HP stagger **8 máu cố định**. Tổng lượng nhân 1.5 rồi làm tròn gần
  nhất, phần .5 lên: 4→6, 7→11, 10→15, 5→8. Phân bổ xương làm tròn trong
  tổng này, không cộng thêm hạt ngoài quota.
- Sprite lớn ×1.5 theo cả hai chiều; vùng jitter quanh cùng neo rộng/cao ×3,
  half-extents từ (4,5) lên **(12,15)** world px. Không nhân offset neo trên
  cơ thể hoặc góc quạt. Tốc Q **720/1080/1560**, Player **660** world px/s;
  tham số tầm **165/270/405/156** world px. Giữ lifetime/gravity/shading/fade,
  tỉ lệ tốc/tầm xương 75%, hit-stop, Q charge và tuning source hiện có.
- Khung QA rộng hơn 1440×720 và dịch camera để xem trọn quỹ đạo mới; hệ số
  cỡ/tốc/tầm tính trong world, không lấy kích thước GIF trên màn hình làm đơn vị.

Capture Forward+/D3D12 cuối exit 0: **244 frame**, GIF thường **11.53s**, chậm
0.33× **11.64s**. **22 checks native + 103 kiểm hệ số/hình học qua**, gồm số
sprite thực, kích thước sprite và vùng sinh trong từng burst. Các kiểm cơ học
này không phải 125 tình huống gameplay độc lập. **125/125 hash runtime/source/
asset giữ nguyên** và baseline vẫn khớp V1. Rà PNG peak cả bốn profile; log
cuối không script/render error, Bone2D warnings nguồn còn. Phạm vi chưa chứng
minh của V1 (hai hướng/nhiều mục tiêu/pause/kill) vẫn giữ nguyên.

Media/log/project và `multiplier_verification.json` tại
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-particles-q-stagger-2026-10-30-v2/`.
V1 bên dưới là lịch sử và được giữ nguyên. Quy trình vẫn preview → duyệt →
tích hợp; không commit/push, không force reload editor hoặc sửa source runtime.

## Lịch sử preview 29/10/2026 — V1 particles chỉ cho Q trúng và Player HP stagger

Người dùng thu hẹp phạm vi: **chỉ Q trúng địch** và **Player bị HP stagger**
mới có particles; Q tụ lực tăng lượng, tốc và tầm, Player dùng lượng cố định.
Đây là yêu cầu preview, **chưa duyệt tích hợp particles**. Bản plan hit thường,
Saber 4/jump hoặc Player nhận hit thường phát hạt đã bị thay thế.

Preview V1 dùng sheet máu/xương V4 nguyên ảnh: Q nhấn **4 hạt (3 máu/1 xương)**,
tụ mức 1 **7 (5/2)**, tụ mức 2 **10 (7/3)**; tốc cơ sở 240/360/520 world px/s,
tham số tầm 55/90/135 world px. Player HP stagger **5 giọt máu**, không xương,
tốc 220, tham số tầm 52. Đây là các mốc thử để người dùng xem, chưa là tuning
runtime đã khóa. Hạt ưu tiên nét dài, xương có mặt bóng phẳng rõ, bay trong
world và tan; Q giữ đỉnh theo accepted hit-stop 65/75/100ms có sẵn.

Capture Forward+/D3D12 có 344 frame, GIF thường 11.12s và chậm 0.33×/11.10s.
Q dùng input/physics và tier thật, không rút thời gian tụ gốc; Player gọi
`take_damage` thật để gây HP stagger, AI/vitals/HUD tắt. Prototype particles
ở project thử; Q brush/máu bám là source production hiện có. **22 checks qua**:
đúng bốn burst và lượng/profile, tầm Q tăng dần, fade có alpha trung gian,
ordinary Saber accepted contact, ordinary Player hit, stamina exhaustion và
Q hụt không phát burst. Kiểm callback ordinary Saber không phải một pass input
Saber quay native riêng. Chưa chứng minh hai hướng/nhiều mục tiêu/pause/kill
của prototype. Rà PNG peak cả bốn profile; log cuối không script/render error,
Bone2D warnings cũ còn. **125/125 hash runtime/source/asset giữ nguyên**.

Media, log, project riêng và ghi chú tại
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-particles-q-stagger-2026-10-29-v1/`.
Xem [plan particles hiện hành](Ke_hoach_battle_vfx.md#b-particles-cho-địch-và-player--phạm-vi-mới-2910).
Giữ preview → duyệt → tích hợp; không đưa prototype/capture vào Git hoặc sửa
tuning cũ để làm bản thử. Project thử tiếp tục tắt riêng FmodManager do lỗi API
cũ như các lượt trước, source audio/settings thật không đổi.

## Hiện hành 29/10/2026 — máu bám Player đã duyệt và tích hợp

Người dùng duyệt riêng **máu bám lên người Player** sau lượt tích hợp dấu
chém. Phạm vi gồm **hai vết cơ thể ngẫu nhiên + một vệt cố định dưới mắt**
sau HP stagger do đòn trực tiếp; đi theo mọi animation FBF và rig hiện dùng,
không giới hạn ở hai ảnh preview. Particles vẫn chưa được tích hợp.

- `PlayableAdel/PlayerBlood`, script `scenes/adel/components/player_blood.gd`
  và shader `player_blood.gdshader` dùng atlas tám mẫu alpha nguyên bản đã
  lưu trong preview rig. Runtime atlas/data ở `asset/VFX/Adel/Blood/`.
- `#850505`, alpha 0.8; thân rig giữ cỡ ×1.4 đã preview. Mỗi stagger chọn
  hai vùng khác nhau trong thân/tay/chân A/chân B, mỗi vùng chọn độc lập
  1/8 mẫu (được trùng). Giữ danh tính vết/mẫu/tuổi khi đổi clip/frame/facing.
  Vệt dưới mắt nằm ngoài pool; luôn có khi còn nhóm máu, chỉ phần da đang
  lộ được vẽ, không nhuộm tóc/mặt nạ/tay che.
- Dữ liệu mapping gồm **16 sheet / 31 frame FBF**, **9 binding rig** cho
  hai bộ thân/tay/đầu và ba biến thể chân. FBF dùng pixel frame + polygon vùng
  + lọc chất liệu; rig hòa trong material từng sprite để giữ che khuất.
  Không vẽ máu vào PNG nhân vật hoặc sửa animation nguồn.
- Mỗi nhóm liên kết `stagger_tier`. Đúng vạch hồi thì fade **3s thực**;
  vạch chưa hồi thì **150s** bắt đầu cùng fade. Đây là lựa chọn trong khoảng
  người dùng yêu cầu vài giây / 2–3 phút. Pause dừng tuổi, slow motion/hit-stop
  không kéo tuổi. Hết choáng không xóa; chết/restore checkpoint dọn hết.
- Signal mới `StatsComponent.stagger_threshold_restored(tier)` phát khi
  hồi một vạch hoặc lệnh hồi toàn bộ (kể cả cờ đã sẵn sàng do Sentinel).
  `suspend_stagger_thresholds()` dùng `notify=false`: đổi mode/ẩn vạch không
  bị coi là hồi vạch. Không đổi công thức damage, threshold, hồi bình hoặc
  Sentinel. Vết mới chỉ phát trong nhánh HP stagger thật của `take_damage`,
  không phát do i-frame, deflect, cạn stamina, bleed tick hoặc tự tiêu HP.
- Node không override export. Tuning và cách thêm mapping tại
  [máu bám Player](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#player-blood).

**Kiểm tra thực chạy:** máu **134**, Fracture **80**, Guard/Stamina **96**,
Sentinel Entry **59**, Sentinel Drain **36**, Player Refactor **46**,
dấu chém **84**, Saber VFX **68**, Q VFX **98**: **701 checks, 0 failures**.
Capture Forward+/D3D12 cuối exit 0: **138 PNG**, **277 frame motion** qua
stagger → idle/run → combo → Q → jump → dash, **0 frame mất material máu**;
giữ nguyên nhóm/mẫu/tuổi và cuối fade còn 0 nhóm. Rà hình 31 frame FBF và
36 mẫu rig nhìn phải bằng contact sheet; hướng trái có capture tương ứng.
Đây không phải kiểm mọi frame/key hoặc mọi map chơi. Capture kết hợp thêm
máu đã có sẵn + combo bằng input/physics thật: 8 hit hai hướng, 0 mẫu sai
lớp giữa địch/dấu chém/vệt kiếm, 16 PNG; không thay renderer VFX bằng overlay.

Manifest trước lượt máu: 48 file, **45 nguyên hash**, ba file đổi đúng dự
kiến (Player script/scene, StatsComponent). Manifest rig cũ **42/42 nguyên**;
atlas runtime nguyên hash atlas preview. Giữ Q hai răng, mọi bitmap nhân vật,
vệt Saber/Jump/Ready và dấu trúng đã duyệt. Bone2D warnings cũ còn; log cuối
không có script/render error. Lượt thử đầu sai cách gọi một scene suite cũ
và lỗi cleanup trong harness capture đã được sửa ở runner, không sửa gameplay
để làm các suite qua. Project thử tắt riêng FmodManager như lượt dấu chém vì
lỗi API FMOD sẵn có; audio không được kiểm, settings nguồn không đổi.

Kiểm tra/bằng chứng lượt này được ghi trong
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-player-blood-integration-2026-10-29/`.
Suite mới `player_blood_validation.gd`; capture native
`player_blood_capture.gd`. Kết quả cuối, điều kiện test và giới hạn ở
`INTEGRATION_NOTES.md`, `regression_results.json`, `capture/capture_summary.json`.
Capture phân biệt một hit stagger thật với fixture hiện đủ bốn vùng để rà
mapping; không ghi fixture đó là random gameplay. Camera QA riêng, AI/HUD
tắt; audio không thuộc nghiệm thu này. Không sửa camera/project settings
thật hoặc save người chơi; không force reload editor, commit hoặc push.

## Hiện hành 29/10/2026 — dấu chém trúng Saber 1–4 đã duyệt và tích hợp

Người dùng duyệt preview V2 rồi chốt lớp vẽ **enemy < dấu trúng < VFX kiếm**;
yêu cầu không làm thêm preview trước khi tích hợp. Phạm vi duyệt này là dấu
chém của bốn đòn combo, không bao gồm particles hoặc máu bám Player/máu dưới mắt.
Các nhóm còn lại tiếp tục theo [kế hoạch battle VFX](Ke_hoach_battle_vfx.md).

**Đối chiếu nền 28/10:** vẫn nhánh `main`, HEAD `2ab87da` (`vfx complete`).
Q brush hai răng cưa, hai màu và override 0.02/0.25s thực vẫn nguyên. Manifest
74 nguồn của preview V2 có 72 hash không đổi; hai nguồn khác đúng dự kiến là
Player scene thêm component và SaberHitbox thêm hai getter chỉ đọc. Diff
Player script chỉ thêm tham chiếu component và chuyển duration hit-stop đã
được chấp nhận cho nó. Không đổi rig, bitmap nhân vật, vệt kiếm cũ, Q, damage,
collider, animation, camera hoặc project settings. Source mới đang ở working
tree; không commit/push hoặc force reload editor.

**Runtime mới:**

- `asset/VFX/Adel/Hit/saber_hit_1.png` … `saber_hit_4.png` chép nguyên hash
  bốn ảnh người dùng đưa, đúng thứ tự Saber Attack 1–4. Shader giữ alpha/viền
  tối và tô lõi `#EDF3F7`.
- `scenes/adel/components/saber_hit_slash_vfx.gd` nghe accepted `target_hit`,
  tạo dấu ngay trong callback; miss, rejected damage, Q và jump không tạo dấu
  combo. Dedup mỗi mục tiêu/swing và hit-stop cũ giữ nguyên.
- Dài ×1.30 theo trục riêng của từng ảnh, dày ×1.00; phản chiếu toàn transform
  theo hướng đòn. Neo tâm collider mục tiêu, theo địch; địch chết/xóa thì giữ
  vị trí cuối để tan hết. Mỗi mục tiêu có dấu riêng, tối đa 24 dấu đang sống.
- Giữ đỉnh qua hit-stop thực đã được chấp nhận (combo 35/55ms hiện có), sau đó
  fade alpha tuyến tính **200ms thời gian thực không pause**. Nhiều mục tiêu
  cùng swing dùng chung hạn giữ; slow motion không kéo tuổi, pause dừng tuổi.
- Node `PlayableAdel/SaberHitSlashVFX` chỉ gắn script, **không override** export.
  Z tuyệt đối = effective Z frame Player − 2, dưới vệt kiếm Z − 1 và trên enemy
  theo dải Z hiện hành. Hướng dẫn tuning duy nhất tại
  [mục dấu chém trúng](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#saber-hit-slash).

**Kiểm tra thực chạy 29/10:** suite mới `hit_slash_validation.gd` **84 checks**;
hồi quy Saber **68**, Ready **29**, Jump **33**, Descent **25**, Q VFX **98**:
tổng **337 checks, 0 failures**. Bao gồm accepted/rejected/miss, hai hướng,
đúng hình/màu/transform/lớp, nhiều mục tiêu, follow, kill, giới hạn/cleanup,
thời gian thực và pause. Đây không phải 337 tình huống thị giác độc lập.

Capture `hit_slash_capture.gd` dùng Player + SpineEnemy production, input và
physics thật, **Forward+ / D3D12**: 8 hit (4 đòn × 2 hướng), dấu có sẵn trong
cả 8 callback, **0 mẫu sai lớp**, 16 PNG peak/fade, cuối không còn dấu. Camera
cố định để so hình, AI/vitals tắt trong harness; chưa thay cho nghiệm thu người
chơi trên mọi map/nền/UI. Bone2D warnings nguồn còn. Bản sao kiểm thử có save
riêng và tắt riêng autoload FmodManager vì lỗi API FMOD sẵn có khi import;
audio không được kiểm trong lượt này, audio/project settings thật không đổi.

Bằng chứng và bản source tích hợp tại
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/soujourn-hit-slash-integration-2026-10-29/`:
`capture/`, log, `regression_results.json`, `source_preservation.json` và
`INTEGRATION_NOTES.md`. Không đưa capture/project thử vào Git. Preview V2
lịch sử giữ nguyên ở thư mục `soujourn-hit-slash-motion-2026-10-29-v2-fade200-longer/`.

## Snapshot nền — bản bàn giao cuối lượt 28/10/2026

- **Đã xác minh trong lượt bàn giao này:** nhánh `main`, HEAD **`2ab87da` —
  `vfx complete`** (28/10/2026 19:59:38 +07:00); working tree sạch trước khi
  sửa tài liệu. Hai PNG Q runtime đã tracked và vẫn khớp SHA256 bản đã duyệt.
  Không fetch, chạy lại game/test hoặc xem lại video trong lượt bàn giao.
- **Đã hoàn thành:** combo Saber 1–4, jump AIR/LAND, cung giữ khi lao xuống,
  Ready và Q brush hai răng cưa. Q brush là thay đổi hình/màu mới nhất, đã
  được duyệt và tích hợp. Không có phần code đã được giao nào đang bỏ dở.
- **Palette hiện hành:** combo/Ready/AIR/LAND trắng tiết chế; cung giữ pha
  lao xuống `#b4b6be`; riêng Q có lõi `#ef241e`, nét nhạt `#f55d58`.
  Các đoạn lịch sử yêu cầu Q trắng hoặc `#df5c55` đã được thay thế.
- **Đọc theo thứ tự:** mục 1 để tiếp quản; phần Q brush ngay dưới để biết
  kết quả mới nhất; mục 3 cho bài học ref/nhận xét; mục 4 cho file; mục 10
  cho phần chưa chứng minh và bước tiếp. Các cập nhật có ngày cũ là lịch sử,
  không biến câu “Q chưa triển khai” của ngày 27/10 thành trạng thái hiện tại.
- **Nguồn tuning duy nhất:**
  `D:/Godot Project/soujourn--echoes-of-the-soul/Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md`
  tại các anchor `saber-vfx`, `jump-vfx`, `ready-vfx`, `q-vfx`.
  Preview/ref/evidence mới ở `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/`,
  chỉ lưu cục bộ. Asset runtime đã duyệt nằm trong `asset/VFX/Adel/Saber/`.
- **Mức bằng chứng:** 413 checks và capture Q là kết quả thực chạy của lượt
  tích hợp trước đó, đã mở log đối chiếu lại; không ghi là vừa rerun trên
  HEAD mới. Quan sát video là lịch sử khảo sát có URL/timestamp; nguyên tắc
  thiết kế rút ra không phải mô tả mã nguồn hay tiêu chuẩn nội bộ của Limbus.

## Hiện hành 28/10/2026 — Q brush V4 hai răng cưa đã duyệt và tích hợp

**Yêu cầu mới nhất đã chốt:** sau cung phẳng, người dùng muốn chất nét theo
`D:/Downloads/Layer 2.png`: răng cưa chỉ ở biên trong, hướng về đầu nhọn,
biên ngoài liền mạch, lõi kín và vài nét nhạt vẽ lên lõi. Sau khi giảm còn
bốn răng, người dùng gạch bỏ hai răng gần đuôi và gọt dải biên trong để đuôi
thu mảnh hơn, áp cho cả hai cung. Đã duyệt **brush V4 hai răng cưa**; đây là
đợt V4 khác với V4 cung phẳng lịch sử bên dưới. Màu mới lấy trực tiếp từ
ảnh mẫu: lõi **#ef241e**, nét nhạt **#f55d58**, thay #df5c55 cho riêng Q.

**Đã tích hợp:**

- `asset/VFX/Adel/Saber/skill_q_lunge.png` và `skill_q_slash.png` là bản sao
  nguyên hash của hai PNG đã duyệt tại
  `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-q-vfx-brush-preview-2026-10-28-v4-two-teeth-tapered/`.
  Đây là **asset chạy game**, không phải đưa cả thư mục preview vào repo.
- `scenes/adel/components/saber_skill_vfx.gd` đọc biên alpha ảnh thành dải
  mesh, bỏ khoảng padding khi căn theo Frame Rect trong pixel frame nguồn.
  Lunge đi từ trái → phải, slash từ dưới-phải → trên-trái khi nhìn phải;
  tự lật theo facing. Giữ hai răng và đuôi của ảnh, không dựng gần giống bằng
  răng cưa ngẫu nhiên. Biên ảnh cache theo texture, mesh đầy đủ dựng lúc ready.
- `saber_skill_arc.gdshader` đọc alpha/nét vẽ và ánh xạ về hai màu mẫu, loại
  fringe alpha mờ; lõi được giữ đặc. `tint` và `highlight_tint` chỉnh độc lập.
  Các trường Bézier cũ không còn dùng, thay bằng Texture/Frame Rect. Nguồn
  tuning hiện hành duy nhất: `Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#q-vfx`.
- Giữ nguyên signal/lifecycle Q: giữ cung suốt lao, trúng tiêu theo accepted
  hit-stop thực 65/75/100ms, hụt tắt cung lao ngay, `_6` có slash riêng; pause,
  freeze không kéo dài đồng hồ; hủy dọn ngay. Source frame `_4` cache vẫn giữ
  đúng vị trí lúc sang `_5`, Z lunge/source=251/250, slash=249 trong scene này.
- Rig có các override người dùng đã chỉnh từ trước lượt này:
  `slash_hold=0.02`, `slash_lifetime=0.25` **giây thực**; đã giữ nguyên.
  Script mặc định vẫn 0.012/0.18. Chỉ cập nhật override `tint` cũ sang màu mới.
  Không sửa producer Q, ảnh `sabers4/5/6`, Player hoặc VFX Saber/Jump/Ready.

**Kiểm tra thực chạy:** Q VFX **98/98** (thêm texture, hai màu và hướng tiêu
slash), Saber **68**, Jump **33**, Ready **29**, Descent **25**, gameplay Q
**160**: tổng **413 checks, 0 failures** trên mirror/cache và dữ liệu riêng.
Lượt đầu 98/1 do override tint cũ trong rig, đã sửa đúng màu đã duyệt; không
xóa override thời gian để làm test qua. Không coi số checks là từng ấy tình
huống thị giác độc lập. Bone2D warnings cũ còn; không có script error ở lượt cuối.

Capture **Forward+ D3D12** theo renderer game, không ép Compatibility:
201 frame input/physics thật, trúng phải + hụt trái, 4 mẫu tiêu trong hit-stop
tap 65ms, 0 mẫu mất cung giữa dash, cuối sạch. Pixel native lõi/nét nhạt đúng
RGB(239,36,30)/RGB(245,93,88): dash 5932/959 pixel, slash 10216/838 pixel.
Các tier 75/100ms có suite, chưa quay native riêng. Bằng chứng tại
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-q-brush-integration-2026-10-28/`:
Thư mục `capture/` chứa `dash_0.png`, `slash_0.png`, `slash_1.png`,
`impact_*.png`, `capture_summary.json`, `timeline.json`; log test/capture và
`INTEGRATION_NOTES.md` ở gốc evidence. Chín file cần bảo toàn giữ nguyên hash;
rig khác đúng dòng Tint mới, đã dựng lại dòng cũ và đối chiếu SHA256 để xác nhận.
Ảnh trong capture là từ component production; không gắn overlay VFX thay thế.

**Giới hạn và bước tiếp theo:** nghiệm thu cảm giác ở map chơi, nhiều mục tiêu
và camera do người dùng thử tiếp. Nét đỏ/xước đã vẽ sẵn trong `sabers4/6.png`
vẫn hiện cùng VFX, có thể che một phần silhouette; đây là nguồn người dùng
đã sửa, không tự xóa. Không chờ duyệt triển khai nữa; nếu có nhận xét mới,
căn Texture/Frame Rect/Scale hoặc làm preview ảnh mới theo quy trình cũ.
Preview/evidence chỉ lưu ngoài Git; không commit/push, không force reload editor.

## Lịch sử 28/10/2026 — Q V4 cung phẳng, màu #df5c55 (đã thay hình/màu)

**Đã chốt:** người dùng duyệt V4, sau đó yêu cầu đổi màu **#df5c55**. Cả
cung lao `_4` và slash `_6` đã dùng màu này. Một cung cong mượt liền mạch,
đuôi nhọn, đầu còn lại là **mặt cắt chéo tù nối đao**, không móc nhọn.
Phần đỏ có sẵn trong PNG giữ nguyên. Cung `_4` đè lên Player; khi nhìn phải,
**đuôi nhọn bên trái mất trước → đầu nối kiếm bên phải mất sau**. Đây là
chiều V4 được duyệt, thay cho chiều V2/V3 lịch sử bên dưới.

**Đã triển khai và xác minh:**

- `scenes/adel/components/saber_skill_vfx.gd` (`SaberSkillVFX`) và
  `saber_skill_arc.gdshader` dựng mesh production, không dùng overlay preview.
  Node mới trong `asset/Character/Adel/adel spine action use.tscn`; khi chơi
  là `SpinePivot/SpineRig/SaberSkillVFX`. Không override export trong scene.
- `scenes/adel/components/saber_weapon_skill.gd` thêm các signal
  `lunge_started`, `impact_confirmed(hit_stop_seconds)`,
  `recovery_started(hit_confirmed)`, `ended(interrupted)` để nối vòng đời.
  Giữ timing/damage/cooldown cùng các giá trị người dùng đã căn.
- Cung `_4` giữ suốt pha lao, bám Player. Khi xác nhận trúng, giữ gốc thế
  giới tại chạm theo transform frame `_4` đã cache, không nhảy theo bounds
  texture `_5`. Tiêu đuôi bằng thời gian hit-stop **thực sự được chấp nhận**,
  hiện 65/75/100 ms; hit-stop tắt thì mất ngay. Hụt tắt cung lao khi sang `_6`.
- Slash `_6` riêng, giữ hình 0.012s, tổng tuổi 0.18s **thực**, ngắn và mỏng
  dần. Vệt dư đứng trong thế giới, tiếp tục qua Ready, pause/freeze/hit-stop;
  ngắt Q dọn ngay. Q4 Z=251/source=250; Q6 source−1=249 trong scene hiện tại.
- Tham số/tọa độ/đơn vị/mặc định/override xem nguồn tuning duy nhất:
  `Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#q-vfx`. Chỉnh màu ở
  **SaberSkillVFX → Appearance → Tint**. README cơ chế:
  `asset/VFX/Adel/Saber/README.md`.

**Kiểm tra thực chạy:** `tests/adel/skill_vfx_validation.gd` **89/89** gồm ba
tier/hai hướng, giữ cung, màu/lớp, accepted hit-stop, duplicate hit, gốc
impact, miss, cancel, pause/expiry và freeze trả zoom cuối chiêu. Hồi quy
Saber VFX **68**, Jump **33**, Ready **29**, Descent **25**, gameplay Q **160**;
tổng **404 checks, 0 failures**. Không coi số checks là từng ấy tình huống
thị giác độc lập. Các lượt dùng bản mirror/cache và user data riêng, không
save chơi thật; cảnh báo Bone2D cũ vẫn còn, không phải script error mới.

`tests/adel/skill_vfx_capture.gd` quay input/physics thật, component production:
200 frame, trúng phải + hụt trái, 4 mẫu tiêu trong hit-stop tap 65 ms,
0 mẫu mất cung giữa dash, cuối không còn dash/slash. Màu lõi native được
đối chiếu RGB(223,92,85): dash 9,564 pixel, slash 9,350 pixel trong capture mới.
Suite Q VFX 89/89 đã chạy lại sau cập nhật PNG nguồn. Video chỉ
quay **tap**; charge 75/100 ms có suite nhưng chưa quay native riêng.

**Bằng chứng tích hợp:**
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-q-vfx-integration-2026-10-28/`.
Hai video hiện hành: `final/q_v4_df5c55_ingame_hit_miss_current_assets_normal.mp4`
(~3.33s), `final/q_v4_df5c55_ingame_hit_miss_current_assets_slow_4x.mp4`
(~13.32s), đều giải mã được. `capture-current-assets/`,
`review_frames_current_assets/`, `video_manifest_current_assets.json`,
`pixel_color_check_current_assets.json`, `*-tests*`/`*-regression*` và
`INTEGRATION_NOTES.md` ở cùng gốc. Bản `capture/`/video không có
`current_assets` là lịch sử trước lần PNG mới nhất, không gửi lại.

Trong lúc tích hợp, hash `sabers4.png`/`sabers6.png` thay đổi do hoạt động
ngoài các chỉnh sửa của tác vụ, lần lượt 16:37/16:42; cache editor import
16:43, sau capture đầu 16:39. AI không ghi đè/khôi phục hai PNG: chúng nay
có thêm nét đỏ xước, giữ nguyên. 6/8 file cần bảo toàn giữ hash từ đầu lượt;
đã lấy baseline mới, quay lại với cache khớp MD5 nguồn và xác nhận **8/8 hash
ổn định qua lượt cuối** (`protected_hashes_current_assets_before/after.json`).
Không so nhầm các hash này với Git sạch vì PNG và scene đã có sửa từ trước.
Toàn bộ preview/evidence ngoài Git, không commit/push; junction mirror được
tháo sau kiểm tra. Không force reload/save cửa sổ editor người dùng.

**Không còn chờ duyệt triển khai Q V4.** Nếu tiếp tục, đọc source và trạng thái
Git trước, hỏi cảm giác trong game khi người dùng có nhận xét mới. Độ đẹp
ở mọi map, nhiều địch hoặc mọi tình huống camera chưa được nghiệm thu.

**V4 preview trắng là lịch sử đã được duyệt**, còn lưu tại
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-q-vfx-preview-2026-10-28-v4-flat-cut/`.
V3 thất bại vì cap bị nhô thành móc và chiều tiêu sai; V4 bỏ móc, dùng hai
biên Bézier có đầu cuối khác nhau cho mặt cắt chéo, đảo chiều về đuôi → kiếm.
V2 từng dùng Z=51 nhưng tổng source=250 nên vẫn ở sau: phải so tổng Z qua
ancestor, không chỉ Z của sprite con. Bản slash cũ để lại khối gần chữ nhật
khi về Ready: thu thêm bề rộng theo `(1-progress)^0.75` đã xử lý.

**V3 bên dưới là lịch sử đã bị yêu cầu sửa tiếp.** Người dùng yêu cầu
`saber_skill_4` đè lên nhân vật, dày hơn và cong theo ref đầu tù. V3 chuyển
cung lao ra lớp trước đúng nghĩa render: source có tổng Z=250 (Player 200
cộng sprite 50), VFX Z=251; V2 từng đặt Z=51 nên ở sau Player. Không chuyển vị
trí cú đánh thấp thành slash trên đầu. Hai đường cong inner/outer mới tạo
thân dày và đầu loe/tù nối lưỡi đao, đuôi nhọn; trắng liền mạch, giữ đỏ gốc.
Giữ chiều thu trúng mũi đao → phía sau và nhánh hụt của V2; không sửa hình,
độ sâu hay nhịp tiêu skill_6 trong V3.

V3 nằm tại
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-q-vfx-preview-2026-10-28-v3-foreground/`.
`final/q_v3_foreground_hit_miss_normal.mp4` (~3.33s),
`final/q_v3_foreground_hit_miss_slow_4x.mp4` (~13.32s); `capture/` là nguồn
native, `video_manifest.json`, `review_frames/`, `PREVIEW_NOTES.md` ghi chi tiết.
200 frame input/physics thật, trúng phải + hụt trái, 4 mẫu tiêu trong hit-stop
65 ms, không mẫu mất cung giữa dash, cuối sạch; giữ speed scene=2811. Đã
kiểm source 9/9 hash không đổi và MP4 giải mã được. Video review xác nhận
cung đè hai chân, dày/cong hơn, đầu tù nối đao, đỏ còn, không clipping/remnant
mới và cuối sạch. Chỉ preview ngoài Git,
junction thử tháo sau kiểm tra. Chờ duyệt V3 trước khi tích hợp.

**V2 video bên dưới là lịch sử.** Người dùng sửa rằng
chiều thu ở V1 ngược: V2 tiêu từ phía mũi đao/phía trước về phía sau (nhìn
phải: phải → trái). Đồng thời đổi silhouette theo ref mới: **đuôi nhọn, đầu
tù nối lưỡi đao**, vẫn một cung trắng mượt liền mạch, giữ phần đỏ gốc; áp cho
cung lao và cung slash `_6`. Không lấy màu/glow/nhiều vệt song song trong ref.

Vị trí:
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-q-vfx-preview-2026-10-28-v2-blunt-video/`.
Hai MP4 mới nhất trong `final/`: `q_v2_blunt_hit_miss_normal_r2.mp4` (~3.32s)
và `q_v2_blunt_hit_miss_slow_4x_r2.mp4` (~13.30s). `capture-final-v2/` là nguồn đúng,
200 frame có timestamp, một cú trúng phải + hụt trái bằng input/physics/Q
thật, overlay chỉ gắn tạm trong memory của bản thử. Có 4 mẫu vệt đang tiêu
trong hit-stop 65 ms thực, không mẫu nào mất cung giữa lúc dash, cuối sạch.
Scene lunge_speed thực giữ **2811**; không đổi timing/gameplay production.
Các tier 75/100 ms chưa quay riêng. Bản chậm chỉ đổi tốc độ xuất video.

`PREVIEW_NOTES.md`, `video_manifest_v2.json`, `review_frames_v2/`,
`source_hashes_before/after.json` ghi chi tiết. Đã kiểm 9/9 file production
nguyên hash, MP4 giải mã được. `capture/` cũ trước `capture-final/` có lỗi
căn camera lúc impact, **không dùng làm preview**; bản cuối đã sửa camera
thử, không sửa camera game. Bản video đầu còn khối trắng gần chữ nhật ở cuối
slash khi về Ready; R2 đã cho bề rộng slash thu thêm theo `(1-progress)^0.75`,
giữ hình đầy đủ ban đầu. Các MP4 không có `_r2` đã bị thay thế, không gửi lại.
Video review đã xác nhận R2: cap nối đao hai hướng, chiều tiêu đúng, hụt tắt
cung lao, phần cuối thu mỏng không còn khối chữ nhật; đủ để gửi chờ duyệt.
Junction thử được tháo sau kiểm tra; file ở
ngoài Git. Chờ người dùng duyệt V2 trước khi tích hợp Q.

Phần sau mô tả **V1 lịch sử**, đặc biệt chiều tiêu V1 đã bị V2 thay thế:

Người dùng cung cấp ba ảnh khoanh xanh cho `saber_skill_4/5/6`. Xanh chỉ gợi
vị trí/tầm; bẻ lại thành **cung trắng cong mượt, liền mạch**. Phần đỏ sau sống
đao có sẵn trong PNG phải giữ nguyên. Cung thấp ở `_4` tồn tại suốt lúc phóng;
khi trúng và sang `_5`, thu từ đuôi về phía đầu trong thời gian hit-stop lúc
va chạm; hụt thì tắt ngay. `_6` có cung slash riêng trên đầu như đòn thường.

Đã dựng **preview ảnh, chưa tích hợp và chưa được duyệt** tại
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-q-vfx-preview-2026-10-28-v1/`:
`q_vfx_overview.png` và `q_vfx_tail_timing.png`; `references/` giữ ba ảnh người
dùng, `PREVIEW_NOTES.md` có điểm bẻ cung/giả định/cách chạy renderer. Giữ mọi
file này cục bộ, ngoài Git. Không tạo video trong lượt này.

Đã xác minh từ code: hụt đi thẳng `_4` → `_6`, không qua `_5`. Hit-stop lần
trúng đầu có default **65/75/100 ms thực** theo tier, không thấy override ở
Player scene. Không dùng `impact_pose_duration=0.05` (giây game) hoặc freeze
zoom-return muộn ở cuối charged Q để định tuổi vệt này. Khi tích hợp cần đọc
xác nhận hit thật, giữ transform của cung `_4` tại va chạm thay vì dời theo
sprite `_5`, và dùng clock thực. Thứ tự thu cung `_6` hiện là suy luận theo
pose từ phía trước/thấp lên đầu kiếm cao phía sau, chưa đo quỹ đạo liên tục.
Vệt dư `_6` đang đề xuất 0.18 giây thực, còn chờ duyệt/tuning.

Kiểm tra đợt preview: render native Godot 4.7 OpenGL thành công, 9 file source
được bảo vệ giữ nguyên hash, gồm ba PNG skill và rig/Player/skill code. Đã
xem ảnh; không đổi asset đỏ, shader/combat production hoặc hitbox. **Chưa
kiểm thử runtime đồng bộ hit-stop/hụt/hai hướng cho VFX Q**, chưa chạy suite
gameplay vì đây là preview ảnh. Bước tiếp theo: chờ phản hồi/duyệt của người
dùng trước khi tạo component Q và kiểm tra tích hợp.

## Cập nhật 28/10/2026 — vị trí lưu preview mới

**Từ nay lưu mọi preview mới tại:**
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/`.
Giữ mỗi lượt trong thư mục con có tên rõ; Skill Q tiếp theo cũng dùng gốc này.
Đây là đường dẫn người dùng chỉ định, không tạo lại preview trong
`D:/Godot Project/soujourn--echoes-of-the-soul/output/previews/` hoặc gốc
visualizations cũ. Source/asset đã tích hợp vẫn nằm trong project Godot.

**Chỉ lưu cục bộ, không đưa bộ preview vào Git:** không `git add`, commit hoặc
push ảnh/GIF/ref/log/project thử trong thư mục Output preview. Không chép bộ
này trở lại repository để sao lưu. Gốc mới nằm ngoài repository; `.gitignore`
của game thêm `/output/previews/` để bỏ qua preview mới nếu thư mục cũ được
tạo lại. Những bản preview từng có trong lịch sử Git vẫn là lịch sử; lượt này
không xóa lịch sử hoặc tự commit/push. Các file đã xóa trong working tree
vẫn chờ người dùng quyết định commit việc dọn.

Đã chuyển toàn bộ preview, ảnh, GIF, ref và bằng chứng/log/project thử của chat
từ gốc visualizations cũ sang đây, giữ nguyên tên và cấu trúc thư mục. **8.912
file, 606.419.875 byte (khoảng 578 MB)** được đối chiếu SHA-256 từng file trước
khi dọn bản cũ. Danh sách và hash ở
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/TRANSFER_manifest_2026-10-28.json`.
Các đường dẫn tuyệt đối tới preview trong bản bàn giao đã đổi sang gốc mới;
những đường dẫn con ở các mục dưới ghép vào gốc này.

**Phân biệt với lượt dọn trước:** `output/previews` trong project đã bị xóa
195 file (khoảng 85 MB) theo lệnh dọn của người dùng. Lượt này khôi phục được
**159 file có bản lưu Git**, từ commit `f5d1a2bcf01cc6640aa3bbaa71721391686fe5f1`,
vào thư mục con **`enemy-previews-recovered-from-git-2026-10-28/output/previews/`**
của gốc mới. `RECOVERY_NOTES.md` trong thư mục khôi phục ghi nguồn. Đây là
phiên bản đã commit; **36 file còn lại và sửa chưa commit của các file đã xóa
chưa được khôi phục**. Không coi bộ khôi phục là bản đầy đủ của working tree
trước dọn. Không phục hồi file trở lại `output/previews` của project.

Các script/manifest/log bên trong bộ preview lịch sử được chuyển nguyên byte,
nên có thể còn chuỗi đường dẫn máy cũ. Đó là provenance; trước khi chạy lại
harness, sửa cấu hình/output sang gốc mới và dựng lại mirror/junction cần
thiết. Không chạy script archive rồi để nó ghi preview vào vị trí cũ. Việc
chuyển file không phải chạy lại test hay nghiệm thu lại VFX.

## Cập nhật 27/10/2026 — cung Descent V6 đã duyệt và tích hợp

Người dùng đã duyệt ảnh
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-jump-descent-preview-2026-10-27-v6-lower-belly/lower_belly_preview.png`.
Đã đưa **đúng cung trắng mượt V6** vào pha giữ frame cuối AIR lao xuống:
đầu trên thanh, phần phình kéo thấp gần lưỡi kiếm, chỉ phủ một phần lưỡi.
Vùng khoanh đỏ của người dùng hướng dẫn vị trí/tỉ lệ, không phải khuôn phải
chép sát. Không thêm brush, glow, smoke hoặc đổi hình sau khi duyệt.

Những hướng đã bị thay thế trong vòng preview này: nét quá thấp ở cạnh kiếm;
khối lớn che toàn bộ lưỡi; cung V4 kéo quá gần chuôi; V5 đưa lên cao nhưng
phình quá cao. V6 giữ đầu trên, dồn bề dày xuống thấp và đưa đầu thấp gần kiếm.
Người dùng đã đổi yêu cầu từ che toàn bộ sang **chỉ phủ một phần**; lấy yêu cầu
sau làm chuẩn. Y dương trong Godot xuống dưới; trước đây câu chữ “lên trên,
Y dương” có mâu thuẫn, các vòng ảnh đã giải quyết bằng vị trí nhìn thấy/duyệt.

Source hiện hành: `scenes/adel/components/jump_attack_vfx.gd`, thêm
`jump_attack_descent.gdshader` cùng thư mục. Vẫn node **JumpAttackVFX** trong
`asset/Character/Adel/adel spine action use.tscn`, Player ở
**SpinePivot/SpineRig/JumpAttackVFX**; không sửa scene rig hoặc frame PNG trong
đợt này. Thông số mới/đơn vị/default/override và vị trí chỉnh ở
`Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#jump-vfx`, nhóm **Descent
(source-frame pixels)**. Có offset, scale, width, 4 control point, opacity,
công tắc riêng; hiện không có override Descent trong scene.

**Đã xác minh từ code và chạy thật:** Player phát `jump_attack(air)`, giữ
sprite frame 1 khi clip kết thúc, combat hết hanging và lao xuống; AIR có thể
không còn tên trong `current_animation`. `_sample_descent()` đọc combat
`is_jump_attacking && !is_jump_attack_hanging`, chưa chạm sàn, sprite hiện và
frame 1. Cung đi theo Player/hướng suốt lúc rơi, không dùng lifetime ngắn AIR
và không sinh residual liên tục. LAND/ngắt đòn/ẩn sprite/tắt component làm nó
mất ngay; LAND nhận tiếp cung crush + khí thấp cũ. Hit-stop giữ cung của pha
rơi còn đang diễn ra; các residual AIR/LAND vẫn tuổi thực như trước. Không đổi
combat, physics, damage, hitbox, timing, bốn Saber hay Ready.

**Kiểm tra thực chạy đợt này:** `tests/adel/jump_descent_vfx_validation.gd`
**23 checks, 0 failures** trên Player/combat thật, gồm hết AIR, held pose, rơi
thường không phát, hai hướng, ngắt/disable/ẩn source, LAND, CombatTime hit-stop
và owner cleanup. Hồi quy Jump **33/33**, Saber **68/68**, Ready **29/29**;
các số là các suite khác nhau, không phải 153 kịch bản thị giác độc lập.
`tests/adel/jump_descent_vfx_capture.gd` điều khiển input/physics thật, chụp
ảnh native OpenGL: **3 mẫu rơi phải, 25 mẫu rơi trái dài**, **8 mẫu trong
hit-stop**, **0 mẫu hiện sai trạng thái, 0 mẫu sai pose**; hai lần LAND bắt đủ,
cuối không còn cung rơi/residual. Lần trái nâng điểm rơi thêm **360 world px**
chỉ trong harness để quan sát rơi dài, không đổi gameplay nguồn. Đã xem ảnh
cả hai hướng và LAND: cong mượt, phủ một phần kiếm, không dư cung rơi lúc đáp.

Bằng chứng ngoài repo:
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-jump-descent-integration-2026-10-27/`.
`gameplay-stills/` chứa `right_descent.png`, `left_long_descent.png`,
`right_landing.png`, `left_landing.png`, `capture_summary.json`. Log
`descent-tests*`, `jump_vfx-regression*`, `saber_vfx-regression*`,
`ready_vfx-regression*`, `capture*`. Chỉ ảnh tĩnh, **không tạo video** theo
yêu cầu gần nhất. Project/config/save thử riêng, tái dùng import/class cache
hiện có; không tuyên bố thử import từ checkout trắng. Godot MCP không có
session kết nối; dùng tiến trình thử riêng. Log có warning Bone2D cũ và một
warning cổng FMOD live update đang được dùng khi hai lượt kiểm tra chạy cùng
lúc; không có script/shader error trong các lượt này.

**Điều chỉnh tiếp theo cùng ngày theo yêu cầu người dùng:** khi VFX
`jump_attack(land)` phát thì tắt cung lao xuống ngay. `_spawn_landing()` nay
ẩn `_descent` và đặt `_descent_blocked`; `_sample_descent()` không được bật
lại lớp này đến `_on_animation_started(AIR_CLIP)` của đòn mới. Không phụ thuộc
combat hoặc frame đổi kịp trong cùng tick. Test mô phỏng LAND phát khi trạng
thái combat còn báo rơi: trước sửa **25 checks, 2 failures**, sau sửa **25/25**;
hồi quy AIR/LAND **33/33**. Log/bằng chứng ở thư mục cùng gốc artifact
**`adel-jump-landing-handoff-2026-10-27/`**. Không có tham số Inspector mới.

**Đổi màu tiếp theo:** người dùng yêu cầu riêng cung pha lao xuống là
**`#b4b6be`**. Đã đổi default uniform `tint : source_color` trong
`jump_attack_descent.gdshader`; geometry V6, opacity, handoff LAND và các VFX
khác giữ nguyên. Hướng dẫn tuning ghi vị trí/default màu mới.

**Giới hạn:** chưa kiểm chứng mọi nền/slope/camera hoặc độ trùng pixel với
hitbox. Câu “Q chưa có preview/duyệt” là trạng thái tại 27/10 và đã hết hiệu
lực: Q brush đã duyệt/tích hợp ngày 28/10 ở đầu file. Junction của project
thử đã tháo, phải dựng lại nếu chạy cấu hình artifact đó; trạng thái Git
hiện tại xem mục 9, không lấy trạng thái chưa commit của lượt cũ làm chuẩn.

## Cập nhật 27/10/2026 — Saber Ready đã duyệt và tích hợp

Người dùng duyệt preview **`adel-ready-preview-2026-10-27-v1/final/`** rồi yêu cầu
tiếp tục theo quy trình cũ. Ready là **vẩy kiếm nhanh ra trước**: nét trắng ngắn
trên đầu ở frame 1, một cung mảnh trước mũi kiếm ở frame 2, vệt dư khoảng 0.1s.
Vùng đỏ trong `D:/Downloads/saber_ready.png` chỉ định vị/hướng/tầm, được bẻ lại
thành đường cong mượt; không chép nguyên polygon. Không smoke hay lớp bọc kiếm.

Đã thêm **SaberReadyVFX** vào rig
`asset/Character/Adel/adel spine action use.tscn`. Source:
`scenes/adel/components/saber_ready_vfx.gd`, `saber_ready_slash.gdshader` và UID;
dùng lại `asset/VFX/Adel/Saber/saber_attack_1.png`. Không sửa texture/frame,
`AdelAnimationComponent`, Player/combat/hitbox, bốn Saber hoặc Jump VFX. Mặc định
vệt dư **0.105 giây thực**, cap lớp gắn pose **0.012 giây thực**; giữ vệt theo
thế giới lúc phát qua đổi pose/hướng, vẫn tan trong freeze/hit-stop/pause.

Điểm quan trọng: `AdelAnimationComponent.ready_pose(true)` thay entry cùng tên
`saber_ready` bằng resource chỉ giữ frame 2 từ 0s. Component đọc lại resource
hiện tại mỗi lần play/thay clip, **chỉ phát khi có marker frame 1 rồi frame 2**.
Frame thật là 1 tại **0.345s**, 2 tại **0.35s**, pose giữa chỉ 5 ms; skip pose
giữa vẫn bắt mốc và phát cung phía trước. Nhánh chỉ giữ pose cuối không phát.

Chỉnh tại **rig → SaberReadyVFX** hoặc **Player → SpinePivot/SpineRig/SaberReadyVFX**.
Vị trí/scale, hai dãy 4 control point để tự bẻ cung, bề rộng/opacity/lifetime
được quản lý tại `Context/Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#ready-vfx`.
Hiện không có override node mới trong rig/Player/map. Geometry dựng lúc khởi tạo.

Kiểm tra thực chạy: `tests/adel/ready_vfx_validation.gd` **29 checks, 0 failures**,
gồm variant resource thực của Player, skip frame 5 ms, hủy, quay hướng, clock,
hit-stop, pause/capacity/cleanup. Hồi quy Saber **68/68**, Jump **33/33**. Capture
`tests/adel/ready_vfx_capture.gd` dùng input/physics thật: Ready tự vào sau đánh
thường, hai hướng; cú trái có CombatTime hit-stop 160 ms. Sau thả Guard có
**39 mẫu** qua mốc 0.35s của held Ready và **0 mẫu phát vệt thừa**, cuối sạch.
Đây là kiểm tra scene sàn phẳng, không phải nghiệm thu mọi camera/đám đông.

Bằng chứng tại gốc artifact ngoài repo đã nêu trong mục Jump bên dưới, thư mục
**`adel-ready-integration-2026-10-27/`**: `gameplay/` có 307 frame timestamp và
ba pose; `ready-tests*`, `saber-regression*`, `jump-regression*`, `capture*` là
log lượt này. GIF `adel_saber_ready_ingame_normal.gif` / `_slow.gif` là clip
gameplay 5.1 / 10.2 giây. Test dùng project/config/save riêng. Junction thử sẽ
được tháo sau lượt kiểm tra, cần dựng lại trước khi chạy lại cấu hình artifact.
Capture xác nhận cuối ở `gameplay-final/`, log `capture-final*`, cũng 307 frame:
bộ đếm 39 mẫu held Ready yêu cầu cả `_ready_final_frame=true` lẫn resource
không có marker vẩy; 0 mẫu có vệt thừa. Clip GIF trên lấy từ `gameplay/` và
đã được review thị giác riêng; bản quay cuối không đổi code/hình VFX.

**Giới hạn:** cần phản hồi khi chơi Ready trên các map/camera khác. Q từng
chưa được duyệt tại snapshot Ready ngày 27/10; nay đã được duyệt/tích hợp
bằng lệnh riêng ngày 28/10, xem đầu file. Các sửa enemy/output được giữ
nguyên; trạng thái Git hiện tại ở mục 9.

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
`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-jump-integration-2026-10-27/`.
`gameplay-v2/` là capture thành công (262 ảnh có timestamp và bốn pose); thư mục
`gameplay/` cũ là lượt harness nhấn attack thường do thiếu giữ xuống, **không dùng
làm bằng chứng jump VFX**. Các log `jump-tests*`, `saber-regression*`,
`jump-damage-regression*`, `capture-v2*` là kết quả lượt này. Cấu hình/save thử
riêng, không dùng save chơi thật. Rà tham chiếu vẫn ghi lỗi UID dialogue/BG cũ
và 8 warning legacy đã nêu trong snapshot; không có tham chiếu VFX mới hỏng.

**Tại thời điểm tích hợp Jump:** Ready và skill Q còn chờ. Ready đã được duyệt
và tích hợp ở cập nhật mới hơn phía trên; skill Q vẫn chờ thiết kế/duyệt riêng.
Không suy ra quyền làm các VFX khác từ lệnh duyệt Jump. Chưa commit/push.

## 1. Tiếp quản nhanh và mức độ bằng chứng

1. Đọc `Context/Tai_lieu_ban_dao/AGENTS.md` và `HANDOFF.md`, sau đó đối chiếu Git/source/scene trước khi sửa. Các đường dẫn `res://...` trong file này tính từ project gốc nêu trên.
2. Xác nhận đủ bốn component trên rig nguồn: **SaberSwingVFX**, **JumpAttackVFX**, **SaberReadyVFX**, **SaberSkillVFX**. Trong Player chúng ở `SpinePivot/SpineRig/`. Các animation và logic chiến đấu hiện hữu được giữ; không tự thêm frame thân người/hitbox/damage/camera.
3. Thay đổi mới nhất là **Q brush V4 hai răng cưa, đuôi thu nhọn**, đã duyệt và tích hợp. Xem hai PNG runtime và ảnh native ở phần đầu. Combo đòn 3 ngang vai/kéo về sau là thành quả trước đó, không phải nhiệm vụ đang chờ làm; chưa có phép nghiệm thu khách quan toàn quỹ đạo/hitbox.
4. Đối chiếu đủ bốn anchor tuning nêu đầu file. Đặc biệt Q có override scene **hold 0.02s / lifetime 0.25s thực**, khác script **0.012 / 0.18**; combo có scale/lifetime override riêng. Giữ giá trị người dùng đã căn.
5. Kiểm tra đường dẫn preview/evidence và hash trước khi dùng. Kết quả Q mới ở `adel-q-brush-integration-2026-10-28/`; combo đòn 3 ở `saber-attack3-shoulder/final/`. Mirror thử đã tháo junction, cần dựng lại nếu chạy; test dùng dữ liệu riêng. Báo ngắn phần đã xác minh và chênh lệch mới trước khi tiếp tục yêu cầu tiếp theo.

Phân biệt các mức sau trong toàn bộ bản bàn giao:

- **Xác minh lúc bàn giao 28/10:** đã đọc source, Git, override, đường dẫn, log và hash ảnh Q; ghi `handoff-verification-2026-10-28.json` và chép nguyên ref màu vào evidence Q. Lượt này sửa tài liệu, không chạy lại game/test hoặc xem lại video.
- **Kiểm thử lịch sử có bằng chứng:** các lượt thực sự chạy trước đó trong chat, có log/ảnh/GIF tại vị trí ghi dưới. Không có nghĩa mọi thay đổi ngoài phạm vi vừa xuất hiện trong checkout đều đã được test lại.
- **Quan sát video:** những đoạn đã xem/tiến từng ảnh trong lượt nghiên cứu; không phải đã xem trọn mọi video.
- **Phân tích/giả thuyết:** kết luận thiết kế từ hình ảnh, cần đánh giá trong game; không phải mô tả mã nguồn nội bộ của Limbus.
- **Yêu cầu người dùng:** giữ nguyên ý định dù nó không trùng cơ chế thật của Limbus. Kết quả kiểm tra kỹ thuật không thay cho việc người dùng thấy VFX đẹp/hợp kiếm.

## 2. Mục tiêu, yêu cầu và quyết định đã chốt

### Điều người dùng muốn đạt được

- Combat theo hướng Limbus Company: **dứt khoát, mạnh, có sức nặng vũ khí**, ít màu và ít lớp gây rối. Combo/Ready/AIR/LAND dùng trắng/xám tiết chế; cung giữ khi lao xuống là **#b4b6be**. Riêng Q đã được đổi sang **#ef241e / #f55d58** theo ref màu mới. Ref vàng trước đó chỉ dùng cấu trúc, không lấy palette vàng.
- Người dùng thấy FBF hiện tại **đã đủ dứt khoát và nặng**. Điểm yếu là cảm giác hơi khựng và thiếu hình mô tả quỹ đạo/vùng đánh. Mục tiêu VFX là bù chuyển động giữa các pose, không mặc định thêm frame thân người hoặc làm animation mềm đi.
- FBF ba frame: chuẩn bị → motion blur mạnh, gần pose cuối → tư thế cuối. Không có đủ ảnh để đọc toàn bộ vùng quét kiếm; vệt phải giúp người chơi hình dung tầm đánh và hướng lực.
- Vệt là **một cung/lưỡi liềm liền khối**, có cạnh cắt rõ, đầu/đuôi thuôn; xước mảnh chạy theo cung và glow vừa phải. Không tách thành nhiều vệt phụ độc lập hoặc vòng sáng trang trí làm mất đường chém chính.
- Vệt dư phải chuyển động/biến mất từ đuôi, không đứng theo freeze/hit-stop; có thể sống qua đổi animation/đòn tiếp, nhưng hết sớm để đòn mới vẫn rõ.
- VFX cần theo **đường kiếm, mặt phẳng vung và vai**, không chỉ phủ đủ một hình hộp phía trước. Độ dài X, độ cao cung Y và bề dày nét là ba việc khác nhau.

### Hai phương án từng đề nghị và trạng thái thật

- **Phương án 1 / A:** chỉ vệt độc lập tự tan/thu. Đây vẫn là hướng đối chiếu thiết kế; chưa có bằng chứng một đợt A/B có kiểm soát đã chọn được bản thắng.
- **Phương án 2 / B — đang dùng cho combo 1–4:** lớp theo frame làm rõ đỉnh chém, mất ngay khi hết frame được chọn/đổi animation và không fade; vệt dư nhẹ/ít chi tiết hơn tiếp tục chuyển động và thu lại độc lập. Đây không phải khẳng định mọi pha Jump/Ready/Q đều có cùng hai lớp.
- Hai lớp combo là **Sprite2D riêng trong game**, không vẽ đè vào ba PNG frame nhân vật. Cùng dùng bitmap slash của từng đòn; shader/độ đậm/detail khác nhau giữa hai lớp. Jump/Ready/Q dùng component mesh/shader riêng theo pha; Q hiện có hai PNG VFX độc lập với PNG nhân vật.
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
6. Các nhân vật mới có mức trang trí khác nhau. Học cấu trúc thông tin/nhịp, giữ palette và mức tiết chế người dùng đã chốt cho từng đòn; Q đỏ mới không phải lý do đổi toàn bộ combo trắng sang đỏ.

**Giới hạn cần giữ:** không suy ra số frame tác giả vẽ, duration hit-stop chuẩn, unscaled time, một shader chung, node sống qua đổi clip hay hitbox thật của Limbus từ trailer/GIF. Giữ pose nhưng VFX đổi có thể là hình được dựng sẵn. Các bước tiến frame của player không phải phép đếm frame artwork.

### 3.2. Video After Effects: cách vệt biến mất

Nguồn người dùng yêu cầu xem: https://www.youtube.com/watch?v=WCWH8AnEvbI .
Ghi nhận từ lượt xem/tiến khung video trong lịch sử chat, **không xem lại video trong lượt viết bàn giao 28/10**; chưa lưu phép đo timing/timestamp chi tiết thành báo cáo repo. Tên công cụ AE bên dưới là ghi chép lịch sử; nếu cần tái tạo chính xác timeline/project AE thì phải mở lại đối chiếu, không coi là source project đã có.

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

### 3.4. Các bài học bổ sung từ Jump, Ready và Q (27–28/10)

1. **Đáp mạnh cần kết thúc lực xuống nền.** AIR cuối đúng chưa đủ: người dùng
   muốn LAND cho cảm giác vừa rơi mạnh xuống đất, có khí thấp dưới chân. Bản
   khói nhiều bị xem lạc phong cách; lớp bọc kín lưỡi kiếm bị yêu cầu bỏ. Bản
   đã duyệt ép cung xuống sàn, còn hai nét khí thấp dạt hai bên, không tan như
   một slash thông thường. “VFX đủ vùng” phải đi cùng cách kết thúc lực của đòn.
2. **Cung giữ khi lao xuống khác vệt dư AIR.** Người dùng đổi từ che toàn bộ
   sang chỉ phủ một phần kiếm, giữ cung mượt ở phía trên đầu lưỡi, rồi hạ
   phần phình gần kiếm (Descent V6). Cung này theo Player/hướng suốt pha rơi,
   tắt ngay khi LAND phát và có chốt chống bật lại trong cùng tick, kể cả
   combat chưa kịp đổi trạng thái. Màu riêng #b4b6be không lan sang AIR/LAND.
3. **Ready là vẩy nhanh, không phải đòn lớn.** Nét ngắn trên đầu rồi cung
   mảnh phía trước, dư khoảng 0.105s. Frame giữa thực chỉ 5ms: bắt mốc bằng
   tiến trình clip, không đòi renderer thấy đúng frame đó. Variant Ready chỉ
   giữ pose cuối sau Guard không được phát vệt; đọc resource hiện hành thay
   vì chỉ dựa vào tên animation. Tốc độ đọc đòn quan trọng hơn thêm độ phủ.
4. **Q có vòng đời riêng được người dùng chốt.** Cung `_4` giữ suốt thời
   gian phóng; trúng mới tiêu trong accepted hit-stop, hụt tắt ngay lúc hồi;
   `_6` phát slash riêng. Quan sát video Limbus không chứng minh cơ chế này:
   đây là yêu cầu của Adel, nay đã có signal/clock production và test riêng.
5. **Tách hướng hình khỏi hướng tiêu và lớp vẽ.** Q từng bị sai chiều tiêu
   nhiều lần; bản hiện hành tiêu đuôi → đầu nối kiếm. Đầu nối phải là mặt
   cắt tù, không thành móc nhô lên. “Đè lên nhân vật” là tổng Z qua ancestor,
   không phải đưa vị trí đòn thấp lên đầu; Z=51 vẫn ở sau Player+sprite=250.
   Câu “lên trên, Y dương” từng mâu thuẫn: Godot Y dương xuống dưới, lấy ảnh
   đã duyệt làm chuẩn và nói rõ trục hay lớp vẽ trước khi chỉnh.
6. **Đơn giản không đồng nghĩa mảng phẳng.** Q cung phẳng đã đúng vùng nhưng
   người dùng muốn chất brush theo `Layer 2.png`. Bản xước cả hai biên/lỗ
   xuyên lõi chưa đúng. Yêu cầu cuối: ngoài mượt, trong có răng cùng hướng
   về đầu nhọn, lõi kín, nét nhạt là màu vẽ lên lõi; giảm 8→4→2 răng, bỏ hai
   răng gần đuôi và gọt mảnh đuôi. Giữ hai răng gần đầu tù. Đây là quyết
   định thị giác của người dùng, không suy ra từ “Limbus luôn dùng răng cưa”.
7. **Ảnh gen và màu runtime là hai việc cần kiểm riêng.** Bảng màu mới được
   lấy từ pixel mẫu: #ef241e / #f55d58. PNG gen có sai số màu/alpha nhưng
   đúng hình đã duyệt; dùng nguyên ảnh làm alpha/nét vẽ, shader khóa hai màu
   và loại fringe mờ. Đã kiểm pixel native khớp cả hai. Hash ảnh runtime
   khớp ảnh được duyệt không đồng nghĩa mọi RGB của ảnh gen vốn chính xác.
8. **Ảnh peak và capture trả lời các câu hỏi khác nhau.** PNG chỉ VFX ở độ
   dài tối đa cho phép duyệt nét/lõi/răng; ảnh/gameplay thật kiểm vị trí,
   hướng, trúng/hụt, layer, clock và chuyển pha. Khung xanh người dùng vẽ
   là hitbox giả định, mảng đỏ/xanh chỉ hướng dẫn vùng; không chép polygon
   hoặc đổi collider để ép khớp preview. Dùng source frame pixels, không
   dùng pixel screenshot làm world unit.

## 4. Triển khai hiện hành và vị trí tìm file

### Bản đồ component và nguồn tuning (đã đối chiếu 28/10)

Tất cả đường `res://` dưới đây bắt đầu tại
`D:/Godot Project/soujourn--echoes-of-the-soul/`. Rig chung là
`asset/Character/Adel/adel spine action use.tscn`; Player
`scenes/adel/playable_adel.tscn` instance rig ở `SpinePivot/SpineRig`.

- **Combo 1–4:** node `SaberSwingVFX`, `scenes/adel/components/saber_swing_vfx.gd`,
  shader `saber_slash.gdshader`; bốn `asset/VFX/Adel/Saber/saber_attack_*.png`.
  Tuning anchor `saber-vfx`. Hướng/căn đòn 3/4 ở phần combo bên dưới.
- **Jump AIR/LAND và cung giữ rơi:** node `JumpAttackVFX`,
  `scenes/adel/components/jump_attack_vfx.gd`; shader `jump_attack_air`,
  `jump_attack_crush`, `jump_attack_ground_air`, `jump_attack_descent`
  (đuôi `.gdshader` cùng thư mục). Dùng lại `saber_attack_1.png`; cung Descent
  là mesh riêng. Tuning `jump-vfx`. Tên clip thật **`jump_attack(land)`**;
  người dùng từng gọi pha này “fall”, không tự đổi tên animation theo lời gọi.
- **Ready:** node `SaberReadyVFX`, `scenes/adel/components/saber_ready_vfx.gd`,
  `saber_ready_slash.gdshader`; dùng lại `saber_attack_1.png`, tuning `ready-vfx`.
- **Q:** node `SaberSkillVFX`, `scenes/adel/components/saber_skill_vfx.gd`,
  `saber_skill_arc.gdshader`; hai `asset/VFX/Adel/Saber/skill_q_*.png` cùng
  `.import`. Producer signal ở `scenes/adel/components/saber_weapon_skill.gd`,
  tuning `q-vfx`. Không còn dùng các trường Bézier của Q cung phẳng.
- **Tests/capture:** `tests/adel/` có các cặp `{saber_vfx,jump_vfx,ready_vfx,
  jump_descent_vfx,skill_vfx}_{validation,capture}.gd`; gameplay Q dùng
  `saber_skill_validation.tscn`, skeleton dùng `skeleton_instance_validation.gd`.
- **Ref/video:** `Context/Bao_cao_ky_thuat/nghien_cuu_animation_combat_limbus.md`
  và `Context/Tai_lieu_ban_dao/refs_anim/`. Snapshot ref màu Q được bổ sung
  trong evidence ngoài repo, xem mục 8. README cơ chế chung
  `asset/VFX/Adel/Saber/README.md` trỏ về hướng dẫn tuning.

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

Các kết quả checker/UID/test camera ở đoạn này là **lịch sử**, chưa chạy lại
project checker trong lượt bàn giao 28/10; không khẳng định số warning hiện
tại vẫn đúng 1+8. Đã kiểm tra lại ba scene legacy nêu trên vẫn không tồn tại.

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
10. **Q dùng Z của sprite con thay tổng Z:** V2 đặt VFX=51 nhưng Player+sprite=250,
    vẫn ở sau nhân vật. Tính qua ancestor và dùng offset so source; hiện lunge
    251, slash 249. Không sửa tọa độ Y để chữa lỗi thứ tự vẽ.
11. **Q đầu tù thành móc và thu sai chiều:** bản cung phẳng V3 bị yêu cầu sửa;
    V4 cắt mặt chéo tù, đuôi → đầu kiếm. Slash dư cũ từng còn khối gần chữ nhật
    khi vào Ready, đã bổ sung thu bề rộng. Bản brush mới giữ logic đó và thay
    hình bằng đúng PNG đã duyệt, không lấy V4 cung phẳng làm hình hiện hành.
12. **Chỉ nhắc mã màu trong prompt imagegen:** ảnh vẫn có sai số RGB, alpha và
    fringe. Không tuyên bố “y hệt màu” chỉ từ prompt. Giữ shape được duyệt,
    dùng shader ánh xạ hai màu rồi kiểm pixel native; ref/PNG/artifact và màu
    runtime có bằng chứng riêng. Nét xước xuyên lỗ/rách cả hai biên của brush V1
    cũng đã bị thay bằng yêu cầu lõi kín, ngoài mượt, trong hai răng ở mục 3.4.
13. **Q đổi default script nhưng quên override scene:** lượt đầu 98 checks/1 fail
    vì rig còn tint cũ #df2722. Chỉ đổi dòng tint sang #ef241e; giữ hold/lifetime
    người dùng đã căn 0.02/0.25. Không xóa toàn bộ override để ép test qua.
14. **Capture bị lệch camera hoặc định lượng từ GIF:** zoom impact từng trả về
    authored offset cũ khiến nhân vật ra mép ảnh; sửa camera **trong harness**,
    không sửa camera production. FFconcat mặc định lượng tử hóa 25fps từng làm
    nhịp xuất sai: dùng timestamp native và `option framerate 1000` cho từng
    ảnh đầu vào, rồi xuất 60fps; bản slow chỉ đổi tốc độ video. Script encode
    lịch sử ở `adel-q-vfx-preview-2026-10-28-v4-flat-cut/encode_video.py`, FFmpeg
    bundled cục bộ ở `adel-q-vfx-preview-2026-10-28-v2-blunt-video/_tools/`.

## 7. Kết quả kiểm tra và bằng chứng để mở lại

Gốc preview và bằng chứng ngoài repo, đã chuyển ngày 28/10/2026:

`D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/`

### Mới nhất toàn nhánh: Q brush hai răng cưa (28/10)

`adel-q-brush-integration-2026-10-28/` là evidence production mới nhất:
`capture/` chứa ảnh peak/impact/hụt và 201 frame có timestamp;
`q-vfx-tests-final*`, `*-regression*`, `capture*` là các log đã chạy.
`approved_asset_hashes.json`, `native_color_check.json`,
`protected_hashes_before/after.json`, `INTEGRATION_NOTES.md` ghi phạm vi.
Chi tiết số checks/màu/hit-stop và giới hạn ở phần Q brush đầu file.

Lượt bàn giao bổ sung **`handoff-verification-2026-10-28.json`**: HEAD, hash
source hiện tại, kiểm ảnh runtime còn khớp bản đã duyệt, và đường ref màu.
Đây là xác minh file/log, không phải một lần chạy lại 413 checks.
Hai PNG peak riêng đã duyệt ở
`adel-q-vfx-brush-preview-2026-10-28-v4-two-teeth-tapered/`.
**Chưa xuất MP4 mới cho Q brush trong lượt tích hợp này**; các MP4 V2/V3/V4
cung phẳng hoặc `#df5c55` là lịch sử, không gửi chúng như video của brush đỏ.

Tên bên dưới ghép vào gốc này. Chúng là **kết quả lịch sử đã thực chạy**, không phải các test được chạy lại trong lượt chỉ viết tài liệu.

### Combo 1–4: đòn 3 ngang vai, kéo dài về sau (26/10)

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

### Ref màu Q và hình brush đã duyệt (28/10)

- Gốc người dùng: **`D:/Downloads/Layer 2.png`**, 556×148, palette đã lấy
  từ pixel: #ef241e (mảng chính), #f55d58 (nét nhạt). Không dùng nền trắng
  của ref như nền VFX; PNG runtime là alpha trong suốt.
- Bản sao nguyên byte ổn định:
  `D:/Adobe Photoshop/Sojourn Echoes of the Soul/Output preview/adel-q-brush-integration-2026-10-28/references/Layer_2_reference_red.png`.
  SHA256 **`3E522A404EE7D79B7BB08B9CB85C5F6C69F1C994B19589F0EB23A4F22C724600`**.
- Hai ảnh brush cuối: thư mục preview V4 two-teeth-tapered ở đầu file,
  `q_lunge_two_teeth_tapered_preview.png`, `q_slash_two_teeth_tapered_preview.png`.
  File `PREVIEW_SPEC.json` tại đó lưu prompt và diễn giải nét trắng gạch xóa.
  Ảnh annotation không có đường local được cung cấp trong tin nhắn cuối;
  mô tả đã chốt là **xóa hai răng gần đầu nhọn, giữ hai răng gần đầu tù,
  gọt biên trong để đuôi mảnh dần** cho cả hai cung. Không vẽ các nét trắng
  annotation lên VFX hoặc đo tọa độ từ ảnh đã bị resize trong chat.
- Các vòng brush V1/V2/V3 ở thư mục cùng tiền tố là lịch sử: V1 xước/lỗ,
  V2 răng chỉ biên trong + lõi kín + nét nhạt, V3 bốn răng + đỏ từ ref,
  V4 còn hai răng + đuôi thu nhọn. Hai asset runtime khớp hash V4;
  xem `approved_asset_hashes.json` thay vì đoán theo tên “vfx complete”.

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

**Xác minh mới ngày 28/10/2026:** nhánh **main**, HEAD
**`2ab87da` — `vfx complete`**, commit timestamp 19:59:38 +07:00. Hai commit
trước là `f5d1a2b` (`vfx small update`) và `5cad301` (`vfx update`). Working
tree **sạch ở đầu lượt bàn giao**, trước khi sửa file này. Các PNG Q, component,
shader và tests Q đã tracked; câu “VFX còn untracked” ở snapshot cũ đã hết hiệu lực.
`git status` hiển thị `main...origin/main` không có ahead/behind tại lần đọc;
chưa fetch/xác minh trạng thái máy chủ, không suy ra một lần push vừa được thực hiện.

Không phải agent vừa commit trong lượt bàn giao: đây là trạng thái Git đã
quan sát được. Agent không tự commit/push. Lượt bàn giao chỉ cập nhật file
này và chép ref màu/ghi snapshot kiểm chứng ngoài repo; không đổi gameplay,
scene tuning hoặc tài liệu Word. HEAD của `HANDOFF.md` tổng và các snapshot
ngày cũ có thể khác; source/Git hiện tại cùng snapshot đầu file này có ưu tiên.

Các công việc VFX đã có trong source: bốn component/asset/test ở mục 4;
Local To Scene cho skeleton/IK, xóa scene legacy và pause wrapper ở mục 5.
Giữ các sửa enemy, rig float/pose, PNG `sabers4/6` và hệ thống zoom/cooldown
có sẵn của người dùng. Hash trong evidence xác minh **phạm vi từng lượt**,
không chứng minh mọi asset/nhánh khác đã được kiểm thử hoặc bằng Git HEAD.

Preview/ref/GIF/video/log/project thử chỉ ở gốc ngoài repo đã chỉ định;
`.gitignore` có `/output/previews/` (đã kiểm lại). Hai PNG Q runtime trong
`asset/VFX/Adel/Saber/` là bản đã duyệt để game dùng và được tracked hợp lệ.
Đây không phải quyền chép toàn bộ bộ preview vào Git. Kiểm tra lại
`git status --short`/diff khi tiếp quản và bảo toàn mọi sửa mới sau snapshot.

## 10. Việc dang dở, giả định và bước tiếp theo

### Chưa được chứng minh hoặc chưa được người dùng nghiệm thu

- Combo đòn 3 đã chỉnh/triển khai; Jump, Ready, Descent và Q brush đều đã được duyệt theo các lượt riêng. Không có bước chờ duyệt cũ đang chặn việc dùng bản hiện hành. “Gần đường kiếm hơn” vẫn là đánh giá thị giác, không phải đã đo được quỹ đạo liên tục giữa ba frame.
- Chưa có phép xác nhận pixel VFX trùng hitbox thật hoặc vùng có damage toàn bộ theo cung. Hộp xanh của ref là giả định; capture tập trung hình vệt không thay thế test collider.
- Chưa có A/B có kiểm soát giữa một lớp và hai lớp để kết luận khách quan B tốt hơn A. Hiện đã chọn triển khai B theo lệnh người dùng, không phải kết quả nghiên cứu A/B thắng.
- Đã có 413 checks trong lượt tích hợp Q brush; chưa chạy lại mọi suite của project hoặc checker legacy trong lượt bàn giao này. Không tuyên bố toàn game sạch lỗi. UID/test camera ở mục 5 là phát hiện lịch sử cần kiểm lại nếu tiếp quản nhánh đó.
- Lifetime/độ sáng/tầm vươn vẫn là số tuning, chưa được nghiệm thu cho mọi tốc đánh, mọi camera/nền sáng hoặc đám đông. Với real time, một hit-stop rất dài có thể khiến vệt tan hết trong khi nhân vật vẫn freeze; đây là điều cần đánh giá cảm giác, không phải lỗi clock đã biết.
- Không có tác vụ code bắt buộc nào đang bỏ dở trong phần điều chỉnh đã được giao. Bước kế tiếp là tiếp quản đúng trạng thái và nhận/áp dụng phản hồi cụ thể, không tự thêm hạt, impact, rung/zoom hoặc thêm frame nhân vật.

### Trình tự khuyến nghị cho chat mới

1. Đối chiếu HEAD/Git với `2ab87da`, source và override trong rig/player/map với hướng dẫn tuning. Xem hai PNG Q hiện hành, `capture/dash_0.png`, `slash_0.png`, nhánh hụt và ảnh impact trong `adel-q-brush-integration-2026-10-28/`. Chỉ dùng evidence combo/Jump/Ready tương ứng khi sửa họ đó. Báo rõ nếu source đã khác snapshot.
2. Xác nhận yêu cầu mới/việc người dùng muốn tiếp tục. Nếu chỉ tiếp quản, báo ngắn phần đã xác minh và phần cần phản hồi; không coi bàn giao là lệnh tự chỉnh mọi hệ thống.
3. Khi sửa hình: xác định đúng component/pha. Combo dùng array index 0–3 và cả main/residual; Q dùng Texture/Frame Rect, không còn các control point cũ. Sửa bitmap thì tạo preview riêng ở chiều dài tối đa, chờ duyệt rồi tích hợp; sửa vị trí/scale bằng code không cần gen lại hình. Muốn kéo về sau cần neo phía trước; muốn mảnh ngang tách Y scale, rotation, offset và bề dày. Kiểm cả ảnh full-length lẫn chiều tiêu và hai hướng.
4. Nếu cần kiểm vùng đánh: bật debug hitbox thật và thử vào/ra mép vùng, chém hụt/trúng, nối nhanh, chuyển hướng, không/trên đất, bị ngắt; xác minh collider trong WeaponPivot thay vì hộp ref. Thay hitbox/damage/timing cần nằm trong yêu cầu được chốt.
5. Nếu người dùng muốn so A/B: làm trên cùng combo/timing/hitbox/camera/hit-stop, cân riêng bản chỉ residual và bản B hiện tại; không đổi nhiều nhóm tham số cùng lúc. Nếu sửa Q, ưu tiên trúng/hụt, các tier 65/75/100ms, giữ cung lao dài, hủy và freeze cuối chiêu. Giữ script mặc định và scene override tách biệt.
6. Sau thay đổi: chạy suite VFX phù hợp, render/capture thật và đọc log; thêm suite combat/skill/skeleton khi phạm vi/thất bại yêu cầu. Q dùng `skill_vfx_validation.gd` (baseline 98); đụng producer Q cân nhắc `saber_skill_validation.tscn` (160); shared skeleton dùng suite 14 checks. Các baseline không phải số bắt buộc giữ nguyên khi thêm kiểm tra hữu ích. Cập nhật hướng dẫn tuning cùng lượt, README/bàn giao theo phạm vi và gửi bằng chứng thị giác thật.

## 11. Môi trường chạy lại an toàn và giới hạn công cụ

- Godot đã dùng: **`D:/Godot_v4.7-stable_win64.exe`**, runtime 4.7 stable. Python đã dùng cho đọc ảnh/đo/encode: **`C:/Users/xuank/AppData/Local/Programs/Python/Python313/python.exe`**, có PIL/numpy.
- Dùng skill Godot phù hợp: `godot-gdscript`, `godot-shaders`, `godot-animation`, `godot-resources`; `diagnosing-bugs` khi lỗi có repro; `imagegen` khi thật sự cần tạo/sửa bitmap. Căn transform/shader không cần sinh lại ảnh. Với video chứng minh, quy trình `walkthrough-artifacts` đã yêu cầu review trước khi gửi.
- Chạy test trên project copy/mirror có custom user directory riêng, redirect APPDATA/LOCALAPPDATA. Các suite VFX/capture và skeleton chặn nếu user dir không chứa **`CodexSaberVFX`**; gameplay Q `saber_skill_validation` cần **`CodexSaberSkill`**. Đây là guard bảo vệ save chơi thật. Mirror/config Q brush dùng `CodexSaberVFXQBrush`, tạm đổi tên riêng cho suite gameplay rồi khôi phục.
- Khi cần import texture hoặc đăng ký class mới, dùng scan/import phù hợp trước test. Những lượt này tái dùng import/class/extension/UID cache, không phải checkout trắng. Các junction `addons`, `asset`, `bin`, `scenes`, `soujournAudio`, `tests`, `.godot/imported` của mirror evidence đã tháo, không chạy ngay cấu hình archive như thể còn đủ source.
- Lệnh mẫu sau khi đã chuẩn bị bản thử riêng (thay đường dẫn placeholder, không chạy thẳng với save thật):

```powershell
& "D:/Godot_v4.7-stable_win64.exe" --path "<project-thu-rieng>" --headless --audio-driver Dummy --max-fps 120 --quit-after 4000 --script res://tests/adel/saber_vfx_validation.gd
& "D:/Godot_v4.7-stable_win64.exe" --path "<project-thu-rieng>" --headless --audio-driver Dummy --quit-after 1200 --script res://tests/adel/skeleton_instance_validation.gd
& "D:/Godot_v4.7-stable_win64.exe" --path "<project-thu-rieng>" --rendering-method gl_compatibility --audio-driver Dummy --disable-vsync --quit-after 1800 --script res://tests/adel/saber_vfx_capture.gd -- --output="<thu-muc-capture-tuyet-doi>"
& "D:/Godot_v4.7-stable_win64.exe" --path "<project-thu-rieng>" --headless --audio-driver Dummy --script res://tests/adel/skill_vfx_validation.gd
& "D:/Godot_v4.7-stable_win64.exe" --path "<project-thu-rieng>" --audio-driver Dummy --max-fps 120 --quit-after 1500 --script res://tests/adel/skill_vfx_capture.gd -- --output="<thu-muc-capture-Q-tuyet-doi>"
```

- Capture dùng **scene combat thật, input game thật**, giữ Player/physics/hitbox/animation. Harness giấu UI không liên quan, dời/khóa AI địch, vô hiệu simulation vitals. Capture combo cũ zoom 2.1 chủ yếu để xem vệt, không chứng minh phản ứng hit. Q brush mới thực sự có một hit + một miss, zoom thử 1.575, offset `(50*facing,-35)`, giữ lunge scene **2811**; hit-stop lấy signal thật. Đây là căn camera trong fixture, không phải đổi camera game.
- Headless không thay cho xem shader thật. Combo/Jump/Ready lịch sử có OpenGL Compatibility; Q brush mới có **Forward+ D3D12** trên RTX2050, kiểm được hai màu native. Không suy ra mọi renderer/GPU đều đã test. Các lệnh mẫu nên bọc bằng `Start-Process -WindowStyle Hidden -Wait`, redirect stdout/stderr và kiểm exit code khi chạy từ công cụ; `--quit-after` là giới hạn frame, không phải giây.
- `skill_vfx_validation.gd` cố ý để biến `skill` không gắn type `SaberWeaponSkill`: runner SceneTree nạp quá sớm từng làm autoload `CombatTime` chưa resolve khi ép type/preload chuỗi. Component production vẫn typed. Giữ thứ tự ready/bind deferred của Player/rig khi refactor.
- Godot MCP từng có session rồi mất kết nối; không giả định trạng thái editor. Kiểm tra tool/session trước, tránh force reload làm mất sửa chưa lưu. Các editor/process thử đã tự kết thúc; không dừng process của người dùng để “dọn”.
- Shell thường từng vấp lỗi launcher MXC `0x80070020`; lệnh có quyền mở rộng qua auto-review chạy được trong các lượt trước. Đây là giới hạn công cụ, không phải lỗi project. Launch helper Windows bằng `Start-Process -WindowStyle Hidden`; chỉ dọn junction trong thư mục thử đã kiểm đường dẫn, không đệ quy theo junction vào project thật.

**Điểm tiếp quản cuối:** combo, Jump/Descent, Ready và Q brush đã tích hợp;
Q hai răng cưa/đuôi nhọn là bản mới nhất đã duyệt. Giữ tuning và asset hiện
tại, đối chiếu trạng thái mới rồi tiếp tục theo nhận xét/yêu cầu cụ thể.
Không có code đã giao còn dang dở; còn đánh giá cảm giác trên nhiều map,
camera, nhiều địch và độ khớp collider. Không có bằng chứng Limbus dùng
đúng kiến trúc runtime này, cũng chưa có nghiệm thu quỹ đạo tuyệt đối từ
nguồn FBF ba frame.
