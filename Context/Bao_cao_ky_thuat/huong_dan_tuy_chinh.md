# Hướng dẫn tùy chỉnh thông số game

Cập nhật: **16/10/2026**. Đây là file dùng chung: khi thêm hoặc đổi thông số, cập nhật ngay mục liên quan trong file này. Không tạo thêm một báo cáo riêng chỉ để thông báo chỗ chỉnh thông số.

## Mục lục

- [Cách chỉnh và đọc giá trị](#cach-doc)
- [HP, stamina, bình máu và progression](#hp-stamina)
- [Di chuyển, nhảy và dash](#di-chuyen)
- [Combo, đánh trên không, jump attack và hitbox Player](#tan-cong)
- [Defense, Guard, Deflect, Stagger và hit-stop](#phong-thu)
- [Q Saber: charge, damage, zoom và freeze](#skill-q)
- [Dark Sentinel: entry, rút HP và debug](#sentinel)
- [Enemy: AI, damage, hitbox và death](#enemy)
- [Camera, mouse pan, khóa mục tiêu và zoom](#camera)
- [HUD, thanh ulti, icon và loadout](#hud)
- [Campfire, menu, save và phím](#campfire-save)
- [Quy trình cập nhật file này](#cap-nhat)

<a id="cach-doc"></a>
## 1. Cách chỉnh và đọc giá trị

1. Mở scene nêu ở mỗi phần; chọn đúng node trong cây Scene, xem nhóm tương ứng ở Inspector. Tên tiếng Anh hiển thị được ghi cùng tên biến để tìm bằng ô Filter Properties.
2. Với thông số export, ưu tiên sửa Inspector và lưu scene. Với hằng/model chưa export, sửa script/hàm được chỉ rõ. Không sửa giá trị của thanh progress để đổi HP/stamina gameplay.
3. Các danh mục bên dưới ghi **giá trị scene gốc đang lưu** và **mặc định script** tại ngày cập nhật. Nếu không có override, scene dùng mặc định. Instance trong map có thể ghi đè tiếp; chọn instance trong map để xem giá trị cuối. Giá trị chỉnh trong Remote khi đang chạy thường không lưu về scene.
4. Các lựa chọn camera đã lưu trong pause và dữ liệu progression/save có thể có ưu tiên hơn mặc định; đọc lưu ý ở từng phần trước khi kết luận chỉnh không có tác dụng.
5. `px` ở thông số gameplay là đơn vị world; `px/s` là vận tốc. Hệ số zoom `1.5` nghĩa là thêm 50% so với zoom nền, `1.1` thêm 10%; scale slow motion `0.5` nghĩa là còn nửa tốc độ. Game time chịu pause/time_scale; real time là thời gian thực theo chủ sở hữu hiệu ứng, có thể vẫn dừng theo pause thường.

Đây là ảnh chụp cấu hình từ source/scene, không phải giao diện chỉnh tập trung mới trong game. Lượt soạn tài liệu này không thay gameplay hoặc đặt lại các override của bạn.

<a id="hp-stamina"></a>
## 2. HP, stamina, bình máu và progression

### HP/stamina tối đa khi chơi thật

Sửa `res://scenes/Mechanic/player_progress.gd`:

- `BASE_MAX_HP`: HP nền, hiện 100.
- `HP_PER_UPGRADE`: HP thêm mỗi nâng cấp, hiện 20.
- `BASE_MAX_STAMINA`: stamina nền, hiện 100.
- `STAMINA_PER_UPGRADE`: stamina thêm mỗi nâng cấp, hiện 15.
- `EXP_PER_LEVEL_BASE`: hệ số EXP lên cấp, hiện 100; ngưỡng = hệ số × level.
- `UPGRADE_POINTS_PER_LEVEL`: điểm nâng cấp nhận khi lên cấp, hiện 1.

`get_max_hp()`/`get_max_stamina()` kết hợp hằng nền và số nâng cấp; progression/save có thể áp lại các giá trị này lên model. Sửa riêng `StatsComponent.max_hp` không đủ để đổi cân bằng game thật nếu PlayerProgress đang ghi đè. Khi thử, dùng save thử hoặc New Game ở slot riêng; không xóa save thật để kiểm tra.

### Model và bình máu

`res://scenes/UI/stats_component.gd` là model dữ liệu do Player sở hữu. Các biến khởi tạo chưa export: `max_hp`/`hp` = 100, `max_stamina`/`stamina` = 100, `max_flask_charges`/`flask_charges` = 3, `flask_heal_per_use` = 34, `guard_damage_reduction` = 0.5.

Sửa `flask_heal_per_use` để đổi HP mỗi bình; `max_flask_charges` để đổi sức chứa. Sửa `PlayerVitals.FLASK_DURATION` tại `res://scenes/adel/components/player_vitals.gd` để đổi thời gian dùng bình, hiện 0,9 giây game. Thời gian animation bình trên HUD nằm ở `ui.gd` (`FLASK_DRAIN_DURATION`); nếu đổi nhịp gameplay cần căn lại trình bày tương ứng.

### Chi phí và hồi stamina

Mở `res://scenes/adel/playable_adel.tscn` → **PlayableAdel → Stamina**. Ba chi phí là `dash_stamina_cost`, `guard_stamina_cost`, `deflect_stamina_cost`. `stamina_regen_delay` là thời gian chờ sau tiêu hao/hoạt động chặn hồi; `stamina_regen_per_second` là số điểm hồi mỗi giây actor. Giữ Attack/Defense/Guard/Deflect chặn hồi. Không chỉnh dictionary mặc định trong model nếu muốn ghi đè cấu hình Player đang chơi.

Luật hiện hành: còn dương nhưng thiếu thì tiêu hết phần còn lại; thiếu Guard/Deflect có phản ứng cạn stamina, Dash không phạt thêm. Bằng 0 không bắt đầu Dash/Defense. Cách giảm damage Guard và phản ứng thiếu được giải thích ở phần 5.

<a id="di-chuyen"></a>
## 3. Di chuyển, nhảy và dash

### Đi/chạy/nhảy: thông số trong script

Sửa hằng trong `res://scenes/adel/components/locomotion_component.gd`, chưa có nhóm Inspector:

- `WALK_SPEED`, `RUN_SPEED`: tốc độ đi/chạy; `RUN_BOOST_SPEED`, `RUN_BOOST_TIME`: boost đầu khi chạy.
- `GROUND_ACCEL`, `GROUND_FRICTION`, `TURN_ACCEL`: tăng tốc, hãm và quay đầu.
- `AIR_ACCEL_STAND`, `AIR_ACCEL_RUN`, `AIR_SPEED_CAP_STAND`, `AIR_SPEED_CAP_RUN`: điều khiển ngang khi đang trên không.
- `WALK_JUMP_VELOCITY`, `RUN_JUMP_VELOCITY`, `DOUBLE_JUMP_VELOCITY`: vận tốc nhảy Y; số âm lớn về độ lớn sẽ nhảy lên mạnh hơn. `MAX_JUMPS`: giới hạn nhảy.
- `JUMP_RISE_GRAVITY_MULT`, `FALL_GRAVITY_MULT`, `MAX_FALL_SPEED`: hệ số lên/xuống và vận tốc rơi tối đa. Trọng lực nền từ Project Settings → Physics → 2D. Xác SpineEnemy dùng chung luật rơi này; thay đổi sẽ ảnh hưởng cả xác.
- `JUMP_CUT_GRAVITY_MULT` hiện có khai báo nhưng chưa được `apply_vertical_physics()` dùng; đổi hằng đó riêng sẽ không tạo jump-cut.

### Dash: Inspector

Mở Player scene → **PlayableAdel → Dash**. `dash_speed`/`dash_end_speed` tạo đường tốc độ active; `dash_active_duration` là độ dài Active; `dash_skid_duration` là đoạn Skid sau dash đất. `dash_iframe_window = Vector2(start,end)` là khoảng `[start,end)` trong Active; tăng Active Duration không tự tăng i-frame. Skid không tự có i-frame.

Cooldown: chọn **PlayableAdel/DodgeCooldown → Wait Time**, hiện scene gốc 0,06s; chỉ khóa dash tiếp theo. Các hành động khác không chờ cooldown sau Skid. Quãng đường lý thuyết khi không va chạm: `active_duration × (end_speed + (speed - end_speed) / 3)`.

Ghost dash: `res://scenes/adel/components/adel_ghost_trail.gd`, các hằng `INTERVAL`, `FADE_DURATION`, `MAX_POOL` điều chỉnh nhịp bóng, thời gian mờ và số bóng tối đa.

<a id="tan-cong"></a>
## 4. Combo, đánh trên không, jump attack và hitbox Player

### Damage thường và đòn 4

Mở `res://scenes/adel/weapon/saber.tscn` → node **Saber → Combat** hoặc mở thuộc tính **PlayableAdel/WeaponHolder/Saber**:

- `damage`: damage cơ sở ba đòn đầu, scene gốc hiện 20.
- `combo_finisher_multiplier`: hệ số đòn 4, mặc định 1.2 → cơ sở 20 thành 24 trước modifier khác.
- `animation_prefix`: tên đầu animation dùng cho combo. `stamina_cost`, `combo_length`, `attack_active_start/end` là dữ liệu vũ khí, nhưng không mặc nhiên điều khiển mọi luồng hiện tại. Combo coordinator vẫn dùng giới hạn bốn đòn; active hitbox hiện hành do AnimationPlayer của SaberHitbox sở hữu.

`hitbox_offset`/`hitbox_size` trên WeaponData hiện cấu hình `AttackHitbox` legacy qua coordinator, không thay shape đang dùng của SaberHitbox. Để đổi vùng đánh thật, dùng đường dẫn trong mục căn hitbox bên dưới.

Scene `res://scenes/adel/weapon/saber.tscn` → **Saber**.


**Identity**

- **Weapon Id** (`weapon_id`): scene gốc `"saber"`; script `"saber"`.
- **Display Name** (`display_name`): scene gốc `"Saber"`; script `"Saber"`.

**Combat**

- **Damage** (`damage`): scene gốc `20`; script `1`.
- **Combo Finisher Multiplier** (`combo_finisher_multiplier`): scene gốc `1.2`; script `1.2`.
- **Stamina Cost** (`stamina_cost`): scene gốc `0`; script `0`.
- **Combo Length** (`combo_length`): scene gốc `4`; script `4`.

**Animation**

- **Animation Prefix** (`animation_prefix`): scene gốc `"saber"`; script `"saber"`.

**Hitbox**

- **Hitbox Offset** (`hitbox_offset`): scene gốc `Vector2(166, 0)`; script `Vector2.ZERO`.
- **Hitbox Size** (`hitbox_size`): scene gốc `Vector2(152.58, 124.5)`; script `Vector2.ZERO`.

**Attack Timing**

- **Attack Active Start** (`attack_active_start`): scene gốc `[0.1, 0.1, 0.1, 0.15]`; script `[0.1, 0.1, 0.1, 0.15]`.
- **Attack Active End** (`attack_active_end`): scene gốc `[0.2, 0.2, 0.2, 0.3]`; script `[0.2, 0.2, 0.2, 0.3]`.


### Rơi chậm và ngưng rơi theo frame

Player scene → **PlayableAdel → Air Attack**:

- **Air Attack Fall Speed Multiplier** (`air_attack_fall_speed_multiplier`): vận tốc rơi combo = hệ số × vận tốc tham chiếu bình thường. Mặc định script 0.3; scene hiện tại đã được bạn chỉnh khác, xem danh mục Player bên dưới.
- **Air Attack Frame Pause Duration** (`air_attack_frame_pause_duration`): khoảng ngưng tại frame 1 của `saber_attack_1/2/3`. Mặc định script 0.07s; đặt 0 để tắt. Đây là thời gian game, chỉ ngưng chuyển động rơi, không dừng animation/input. Không áp dụng đòn 4 hoặc đòn dưới đất.
- Đổi thời điểm bắt đầu bằng key giá trị `1` của track `TestAttackSprite:frame` trong từng clip ở `res://asset/Character/Adel/adel spine action use.tscn`; hiện key ở 0.15s. Runtime tự đọc key, không cần sửa mã để đổi mốc.

Combo trên không không có xung đẩy X mỗi lần ra đòn. Sau ngưng, tiếp tục tham chiếu rơi đang có; nối combo không đặt lại tốc độ. Bắt đầu đánh lúc đang bay lên sẽ ngắt quán tính lên.

### Jump attack

Player scene → **PlayableAdel → Jump Attack**: `jump_attack_damage` là damage cả chuỗi; `jump_attack_landing_active_time` là phần cửa sổ hit khi land. Một target không nhận lại hit chỉ vì chuyển từ fall sang land.

`jump_attack(air)` giữ trên không suốt animation thật, hiện 0.25s. Để thay độ dài giữ, chỉnh độ dài clip đó trong rig Adel; signal kết thúc mới cho lao xuống. `CombatComponent.JUMP_ATTACK_HANG_TIME = 0.15` chỉ là fallback cho caller component trực tiếp, **không phải thời gian giữ đang điều khiển Player scene**.

Vận tốc lao xuống: `JUMP_ATTACK_FALL_SPEED` trong `res://scenes/adel/components/combat_component.gd`, hiện 1500. `JUMP_ATTACK_LAND_UNLOCK` cùng file là mốc mở movement ở land; thời gian cho phép Defense riêng tại `jump_attack_land_defense_unlock_time` trên Player.

### Căn hitbox và animation

- Combo: Player scene → **WeaponPivot/SaberHitbox/Hitbox/CollisionShape2D**, chỉnh Shape/Position/Rotation. **WeaponPivot/SaberHitbox/AnimationPlayer** có các clip `saber_attack_1/2/3/4`; chỉnh track `disabled` để căn cửa sổ damage và track transform để căn vùng đánh theo từng đòn. Nếu có key ghi đè, chỉ kéo shape ngoài AnimationPlayer sẽ bị key đặt lại lúc chơi.
- Jump: **WeaponPivot/JumpAttackHitbox/Hitbox/CollisionShape2D** là shape riêng. Chỉnh kích thước/offset tại đây; thời gian mở theo hang/fall/land của component.
- Collider nhận hit Player: **PlayableAdel/CollisionShape2D**. Collider thân không phải hitbox tấn công. `AttackHitbox` là đường legacy, không dùng nó để căn SaberHitbox hiện hành.
- Animation hình: **SpinePivot/SpineRig/AnimationPlayer** thuộc rig Adel. Ready sau Defense/Stagger chỉ frame cuối; Q hoàn tất dùng đủ chuỗi. Thời gian khóa Defense ở phần 5 độc lập với việc kéo key pose.

<a id="phong-thu"></a>
## 5. Defense, Guard, Deflect, Stagger và hit-stop

### Mốc vào Defense và buffer

Player root → **Combat Input**: `attack_defense_unlock_time` cho Attack 1–3; `attack_4_defense_unlock_time` cho đòn 4; `jump_attack_land_defense_unlock_time` cho land; `attack_input_buffer` là thời hạn buffer nối combo. Jump Air/Fall không Defense. Giữ xuyên dash không làm mới đồng hồ lần nhấn.

Các mốc hủy combo để di chuyển đang là hằng `ATTACK_INTERRUPT_TIME`/`ATTACK_4_INTERRUPT_TIME` trong `playable_adel.gd`, không đồng nhất với mốc Defense. Đổi chúng cần kiểm tra cảm giác hủy bằng di chuyển riêng.

### Deflect, pose và Guard

Player root → **Defense**: `deflect_delay` là startup, `deflect_window` là độ dài Deflect sau startup; trước/sau cửa sổ vẫn Guard. `defense_hit_pose_duration` điều chỉnh pose phản ứng. `deflect_slow_motion_scale`/`deflect_slow_motion_duration` là mức chậm và thời lượng thực Deflect; giữ `saber_deflect` trong hiệu ứng. Chỉ giữ mà chưa bị đánh thì vẫn `saber_defense`.

**Guard Knockback**: `guard_knockback_distance`/`guard_knockback_duration` là bật lùi nhẹ ngang khi Guard đủ stamina; không đổi Y, vẫn cho đỡ tiếp nếu còn điều kiện. Giảm damage Guard nằm ở `StatsComponent.guard_damage_reduction`, hiện 0.5, nghĩa là nhận 50% damage trước modifier khác. Nó áp dụng cả đủ và thiếu stamina, không phải chỉ thiếu.

### Stagger, cạn stamina và i-frame

**Stagger Threshold**: khoảng lùi (`stagger_knockback_distance`), pha bật lùi (`stagger_knockback_duration`), stun (`stagger_stun_duration`). **Stagger Impact**: `stagger_knockback_deceleration_duration` là đoạn giảm tốc cuối; các trường zoom/slow motion ở nhóm đó chỉnh phản hồi.

- `stagger_zoom_multiplier`: zoom threshold HP.
- `stamina_exhaustion_zoom_multiplier`: zoom riêng khi Guard/Deflect thiếu stamina.
- `stamina_exhaustion_slow_motion_duration_multiplier`: thời gian slow motion cạn stamina = thời gian stagger thường × hệ số này. Mức chậm vẫn dùng `stagger_slow_motion_scale`.
- `stagger_zoom_in_duration`: thời gian vào zoom; `stagger_zoom_return_lead`: cần về zoom nền trước lúc kết thúc phản ứng bao lâu.
- `stagger_zoom_enabled`, `stagger_slow_motion_enabled`: bật/tắt từng phản hồi.
- I-frame stagger: `DamageComponent.STAGGER_INVULN_SEC`, hiện 1s; i-frame nhận đòn thường: `HIT_INVULN_SEC`, hiện 0.2s, ở `res://scenes/adel/components/damage_component.gd`. Các hằng fallback khoảng lùi/stun cùng file không ghi đè export Player đang dùng.

### Threshold, debuff và bình máu

`res://scenes/UI/stats_component.gd`: `STAGGER_THRESHOLD_FRACS` đặt mốc hiện 0.66/0.33; `STAGGER_LOCK_DURATION` đặt khóa HP hiện 1s. Cấu trúc đang có hai marker và các array hai phần tử; đổi **số lượng** mốc cần đồng bộ cả model/HUD/save, không chỉ thêm một số vào array.

`BLEED_TICK_INTERVAL` và `BLEED_DPS` chỉnh tick/HP bleed. Xác suất debuff trong `_apply_random_stagger_debuff()`, hiện Bleed/Fracture 50/50.

<a id="fracture"></a>
#### Fracture: vị trí và cách chỉnh

Mở `res://scenes/UI/stats_component.gd`, nhóm hằng `FRACTURE_*` ngay sau `BLEED_DPS`. Đây là **hằng script, không có export/nhóm Inspector và không có override scene**. Các giá trị dưới đây là mặc định hiện hành, giữ nguyên mức cân bằng trước khi nối vào gameplay:

- `FRACTURE_MAX_LEVEL = 3`: số cấp cộng dồn tối đa. Khi tăng, phải thêm phần tử tương ứng vào `FRACTURE_DAMAGE_DEALT` (chỉ số 0 là không bị Fracture).
- `FRACTURE_DAMAGE_TAKEN_PER_LEVEL = 0.2`: damage nhận tăng thêm 20% mỗi cấp; cấp 1/2/3 là ×1.2/1.4/1.6. Đây là hệ số không đơn vị, áp dụng cho damage trực tiếp sau giảm damage Guard; không nhân tick Bleed hoặc HP tự tiêu Sentinel.
- `FRACTURE_DAMAGE_DEALT = [1.0, 0.85, 0.8, 0.65]`: damage gây ra ở cấp 0/1/2/3. Muốn cấp 2 còn 70%, đổi phần tử chỉ số 2 thành `0.7`. Áp dụng đúng một lần khi hitbox thực sự chạm mục tiêu: combo 1–4 (sau hệ số đòn 4), jump attack và cả ba mức Q Saber; kết quả làm tròn sang HP nguyên. Với damage cơ sở 20, cấp 1/2/3 gây 17/16/13.
- `FRACTURE_SLOW_FROM_LEVEL = 2`: từ cấp này trở lên mới giảm tốc di chuyển và tốc đánh.
- `FRACTURE_MOVE_SPEED = 0.72`: tốc độ ngang còn 72%; áp dụng đi, chạy, boost đầu chạy và giới hạn điều khiển ngang trên không. Đây là hệ số vận tốc, không phải giảm 72%; không đổi gia tốc nền, độ cao nhảy, trọng lực, dash hay quãng/tốc lao Q.
- `FRACTURE_ATTACK_SPEED = 0.75`: tốc đánh còn 75%, nên cùng một đoạn animation mất `1 / 0.75 ≈ 1.333` lần thời gian game; khi chỉnh phải giữ hệ số lớn hơn 0. Áp dụng combo 1–4 và animation jump attack; animation hình và AnimationPlayer của SaberHitbox cùng nhịp. Mốc nối đòn/hủy bằng di chuyển dựa vào tiến trình clip, mốc vào Defense và mở movement ở jump land dùng đồng hồ tấn công cùng hệ số. Buffer input `attack_input_buffer` vẫn theo đồng hồ actor; khoảng ngưng rơi `air_attack_frame_pause_duration` vẫn là giây game riêng. Không đổi key/độ dài animation nguồn.

Q vẫn chịu giảm damage nhưng giữ timing charge/windup/lao/recovery/zoom/freeze riêng đã cấu hình ở phần 6; Fracture không kéo chậm toàn game hoặc các động tác Defense/Dash/Ready. Dùng bình giảm một cấp; hạ 2→1 hoặc xóa Fracture khôi phục tốc độ ở physics tick tiếp theo, kể cả giữa đòn, không đặt lại tiến trình animation. Damage đọc cấp hiện tại tại từng lần chạm. Lối vào Sentinel hiện chưa xóa debuff, vì vậy Fracture vẫn còn hiệu lực trong dạng cho tới khi được xóa theo model.

Luồng áp dụng: `playable_adel.gd.scale_attack_damage()` → hai hitbox; `LocomotionComponent.apply_horizontal_movement()` → vận tốc ngang; `playable_adel.gd._sync_attack_speed()`/`_tick_attack_interrupt()` → nhịp hình, hitbox và nối đòn. Khi thử dùng `res://tests/adel/fracture_validation.tscn` **trong bản sao project**, bật `application/config/use_custom_user_dir` và đặt tên user directory có `CodexFracture`; fixture từ chối chạy trên save chơi thật.

Đòn trực tiếp vẫn kích hoạt threshold khi đang Bleed; tick Bleed bỏ qua threshold. Bình máu hiện xóa Bleed, giảm một cấp Fracture và hồi marker theo model, không phải tự xóa mọi debuff cao cấp.

### Hit-stop

Player root → **Hit Stop**: `hit_stop_enabled`, `hit_stop_scale` và các duration `attack_`, `finisher_`, `guard_`, `deflect_hit_stop_duration`. Duration hit-stop là thời gian thực của hiệu ứng. Q có ba duration riêng ở SaberSkill nhưng vẫn chịu công tắc/mức hit-stop của Player. Hit-stop của combo thường **không zoom**; chỉnh zoom nhỏ ở Camera không tự bật lại zoom đánh thường.

### Danh mục Player: giá trị scene gốc và mặc định

Mở `res://scenes/adel/playable_adel.tscn` → **PlayableAdel**. Mỗi dòng ghi tên Inspector và tên biến, nhóm giống Inspector.

Scene `res://scenes/adel/playable_adel.tscn` → **PlayableAdel**.


**Dash**

- **Dash Speed** (`dash_speed`): scene gốc `2800`; script `2800`.
- **Dash End Speed** (`dash_end_speed`): scene gốc `140`; script `140`.
- **Dash Active Duration** (`dash_active_duration`): scene gốc `0.3`; script `0.3`.
- **Dash Skid Duration** (`dash_skid_duration`): scene gốc `0.2`; script `0.2`.
- **Dash Iframe Window** (`dash_iframe_window`): scene gốc `Vector2(0, 0.3)`; script `Vector2(0, 0.3)`.

**Dark Sentinel**

- **Sentinel Hp Drain Percent** (`sentinel_hp_drain_percent`): scene gốc `2`; script `2`.
- **Sentinel Entry Duration** (`sentinel_entry_duration`): scene gốc `1.5`; script `1.5`.
- **Sentinel Recovery Tick Interval** (`sentinel_recovery_tick_interval`): scene gốc `0.015`; script `0.015`.
- **Sentinel Recovery Percent** (`sentinel_recovery_percent`): scene gốc `1`; script `1`.

**Air Attack**

- **Air Attack Fall Speed Multiplier** (`air_attack_fall_speed_multiplier`): scene gốc `0.1`; script `0.3`.
- **Air Attack Frame Pause Duration** (`air_attack_frame_pause_duration`): scene gốc `0.15`; script `0.07`.

**Jump Attack**

- **Jump Attack Damage** (`jump_attack_damage`): scene gốc `20`; script `20`.
- **Jump Attack Landing Active Time** (`jump_attack_landing_active_time`): scene gốc `0.15`; script `0.15`.

**Stagger Threshold**

- **Stagger Knockback Distance** (`stagger_knockback_distance`): scene gốc `220`; script `72`.
- **Stagger Knockback Duration** (`stagger_knockback_duration`): scene gốc `0.4`; script `0.3`.
- **Stagger Stun Duration** (`stagger_stun_duration`): scene gốc `0.45`; script `0.45`.

**Stagger Impact**

- **Stagger Knockback Deceleration Duration** (`stagger_knockback_deceleration_duration`): scene gốc `0.2`; script `0.2`.
- **Stagger Zoom Enabled** (`stagger_zoom_enabled`): scene gốc `true`; script `true`.
- **Stagger Zoom Multiplier** (`stagger_zoom_multiplier`): scene gốc `1.5`; script `1.5`.
- **Stamina Exhaustion Zoom Multiplier** (`stamina_exhaustion_zoom_multiplier`): scene gốc `1.1`; script `1.3`.
- **Stamina Exhaustion Slow Motion Duration Multiplier** (`stamina_exhaustion_slow_motion_duration_multiplier`): scene gốc `0.5`; script `0.5`.
- **Stagger Zoom In Duration** (`stagger_zoom_in_duration`): scene gốc `0.09`; script `0.06`.
- **Stagger Zoom Return Lead** (`stagger_zoom_return_lead`): scene gốc `0.25`; script `0.2`.
- **Stagger Slow Motion Enabled** (`stagger_slow_motion_enabled`): scene gốc `true`; script `true`.
- **Stagger Slow Motion Scale** (`stagger_slow_motion_scale`): scene gốc `0.35`; script `0.35`.
- **Stagger Slow Motion Duration** (`stagger_slow_motion_duration`): scene gốc `0.36`; script `0.18`.

**Combat Input**

- **Attack Defense Unlock Time** (`attack_defense_unlock_time`): scene gốc `0.6`; script `0.6`.
- **Attack 4 Defense Unlock Time** (`attack_4_defense_unlock_time`): scene gốc `0.75`; script `0.75`.
- **Jump Attack Land Defense Unlock Time** (`jump_attack_land_defense_unlock_time`): scene gốc `0.5`; script `0.5`.
- **Attack Input Buffer** (`attack_input_buffer`): scene gốc `0.18`; script `0.18`.

**Hit Stop**

- **Hit Stop Enabled** (`hit_stop_enabled`): scene gốc `true`; script `true`.
- **Hit Stop Scale** (`hit_stop_scale`): scene gốc `0.05`; script `0.05`.
- **Attack Hit Stop Duration** (`attack_hit_stop_duration`): scene gốc `0.035`; script `0.035`.
- **Finisher Hit Stop Duration** (`finisher_hit_stop_duration`): scene gốc `0.055`; script `0.055`.
- **Guard Hit Stop Duration** (`guard_hit_stop_duration`): scene gốc `0.025`; script `0.025`.
- **Deflect Hit Stop Duration** (`deflect_hit_stop_duration`): scene gốc `0.065`; script `0.065`.

**Defense**

- **Deflect Delay** (`deflect_delay`): scene gốc `0.03`; script `0.1`.
- **Deflect Window** (`deflect_window`): scene gốc `0.2`; script `0.2`.
- **Defense Hit Pose Duration** (`defense_hit_pose_duration`): scene gốc `0.2`; script `0.2`.
- **Deflect Slow Motion Scale** (`deflect_slow_motion_scale`): scene gốc `0.5`; script `0.6`.
- **Deflect Slow Motion Duration** (`deflect_slow_motion_duration`): scene gốc `0.45`; script `0.2`.

**Guard Knockback**

- **Guard Knockback Distance** (`guard_knockback_distance`): scene gốc `20`; script `50`.
- **Guard Knockback Duration** (`guard_knockback_duration`): scene gốc `0.1`; script `0.2`.

**Stamina**

- **Dash Stamina Cost** (`dash_stamina_cost`): scene gốc `20`; script `20`.
- **Guard Stamina Cost** (`guard_stamina_cost`): scene gốc `20`; script `20`.
- **Deflect Stamina Cost** (`deflect_stamina_cost`): scene gốc `20`; script `20`.
- **Stamina Regen Delay** (`stamina_regen_delay`): scene gốc `0.8`; script `1.5`.
- **Stamina Regen Per Second** (`stamina_regen_per_second`): scene gốc `33`; script `28`.


<a id="skill-q"></a>
## 6. Q Saber: charge, damage, zoom và freeze

Mở Player scene → **SaberSkill**, không phải node WeaponHolder/Saber. Source: `res://scenes/adel/components/saber_weapon_skill.gd`.

- **Charge:** `tap_windup`; `charge_level_1_time`/`charge_level_2_time` là hai mốc giữ; `charged_release_windup` là phần thêm sau thả mức 1; `full_charge_final_pose` là pose cuối trước ép lao mức 2. Thả giữa mốc lấy mức thấp đã đạt. `allow_airborne` bật/tắt Q trên không.
- **Lunge:** `lunge_distance` là quãng nhấn nhanh; nhân `charged_distance_multiplier`/`full_distance_multiplier` cho hai mức giữ. `lunge_speed` đổi tốc độ, không đổi tổng ngân sách quãng đường. `enemy_detection_mask` là physics bitmask chọn đối tượng dò; không phải layer index đơn lẻ.
- **Damage And Stun:** `damage` cơ sở, `charged_damage_multiplier`/`full_damage_multiplier`; `charged_stun_duration`/`full_stun_duration` là thời gian enemy không tấn công sau trúng. Nhấn nhanh không có stun charge. `impact_pose_duration` là pha skill_5.
- **Impact Timing:** ba `*_hit_stop_duration` cho tap/mức 1/mức 2; `tap_recovery_duration` và `charged_recovery_duration` đặt thời lượng skill_6; `recovery_slow_motion_scale` đặt mức chậm toàn game trừ Player của recovery charge. Thời lượng recovery charge được giữ theo thời gian thực.
- **Tap Impact / Charge Level 1 Impact / Charge Level 2 Impact:** ba bộ độc lập. `*_zoom_enabled`, `*_zoom_multiplier`, `*_zoom_in_duration`, `*_zoom_duration`; `*_slow_motion_enabled`, `*_slow_motion_scale`, `*_slow_motion_duration`.

**Quan trọng về Zoom Duration:** với charge 1/2, giữ zoom đỉnh tới khi skill_6 kết thúc, rồi `charged_impact_zoom_duration`/`full_impact_zoom_duration` là thời gian trả zoom có đóng băng toàn game, tính bằng giây thực. Với tap, duration vẫn là pulse theo đồng hồ actor, không có pha freeze cuối. Tắt zoom/hệ số 1/thời lượng 0 không tạo freeze vô hình. Slow motion impact tính thời gian thực và độc lập hiệu ứng recovery; nguồn chậm mạnh nhất được chọn khi cùng tồn tại.

Freeze vẫn nhận một input buffer mới nhất; không có tham số export riêng cho số lượng buffer. Không đổi `attack_input_buffer` để kéo dài freeze hay tích nhiều hành động. Trong freeze, Defense cần còn giữ; các điều kiện hành động được kiểm tra lại sau mở băng.

Q dùng shape của **WeaponPivot/SaberHitbox/Hitbox/CollisionShape2D**; `SaberHitbox.begin_skill_window()` lấy Position/Rotation từ key đầu của clip hitbox **saber_attack_1**. Muốn đổi offset Q hiện tại thì chỉnh các key đó, nó sẽ ảnh hưởng cả đòn 1; chưa có export offset Q độc lập. Q dừng ở enemy đầu tiên. Vùng dò va chạm lunge lấy collider thân Player; không kéo collider detect để tăng damage area. Miễn damage của Q thường chỉ trong lunge; không nhầm với Q Sentinel đang ở thiết kế.

Scene `res://scenes/adel/playable_adel.tscn` → **SaberSkill**.


**Charge**

- **Tap Windup** (`tap_windup`): scene gốc `0.2`; script `0.2`.
- **Charge Level 1 Time** (`charge_level_1_time`): scene gốc `0.7`; script `1`.
- **Charge Level 2 Time** (`charge_level_2_time`): scene gốc `1.5`; script `2`.
- **Charged Release Windup** (`charged_release_windup`): scene gốc `0.1`; script `0.1`.
- **Full Charge Final Pose** (`full_charge_final_pose`): scene gốc `0.2`; script `0.2`.
- **Allow Airborne** (`allow_airborne`): scene gốc `false`; script `false`.

**Lunge**

- **Lunge Distance** (`lunge_distance`): scene gốc `180`; script `180`.
- **Lunge Speed** (`lunge_speed`): scene gốc `2811`; script `900`.
- **Charged Distance Multiplier** (`charged_distance_multiplier`): scene gốc `1.5`; script `1.5`.
- **Full Distance Multiplier** (`full_distance_multiplier`): scene gốc `2`; script `2`.
- **Enemy Detection Mask** (`enemy_detection_mask`): scene gốc `5`; script `5`.

**Damage And Stun**

- **Damage** (`damage`): scene gốc `20`; script `20`.
- **Charged Damage Multiplier** (`charged_damage_multiplier`): scene gốc `1.2`; script `1.2`.
- **Full Damage Multiplier** (`full_damage_multiplier`): scene gốc `1.6`; script `1.6`.
- **Charged Stun Duration** (`charged_stun_duration`): scene gốc `0.25`; script `0.25`.
- **Full Stun Duration** (`full_stun_duration`): scene gốc `0.4`; script `0.4`.
- **Impact Pose Duration** (`impact_pose_duration`): scene gốc `0.05`; script `0.05`.

**Impact Timing**

- **Tap Hit Stop Duration** (`tap_hit_stop_duration`): scene gốc `0.065`; script `0.065`.
- **Charged Hit Stop Duration** (`charged_hit_stop_duration`): scene gốc `0.075`; script `0.075`.
- **Full Hit Stop Duration** (`full_hit_stop_duration`): scene gốc `0.1`; script `0.1`.
- **Recovery Slow Motion Scale** (`recovery_slow_motion_scale`): scene gốc `0.5`; script `0.5`.
- **Charged Recovery Duration** (`charged_recovery_duration`): scene gốc `0.3`; script `0.3`.
- **Tap Recovery Duration** (`tap_recovery_duration`): scene gốc `0.15`; script `0.15`.

**Tap Impact**

- **Tap Impact Zoom Enabled** (`tap_impact_zoom_enabled`): scene gốc `true`; script `true`.
- **Tap Impact Zoom Multiplier** (`tap_impact_zoom_multiplier`): scene gốc `1.1`; script `1.5`.
- **Tap Impact Zoom In Duration** (`tap_impact_zoom_in_duration`): scene gốc `0.09`; script `0.09`.
- **Tap Impact Zoom Duration** (`tap_impact_zoom_duration`): scene gốc `0.6`; script `0.6`.
- **Tap Impact Slow Motion Enabled** (`tap_impact_slow_motion_enabled`): scene gốc `true`; script `true`.
- **Tap Impact Slow Motion Scale** (`tap_impact_slow_motion_scale`): scene gốc `0.5`; script `0.35`.
- **Tap Impact Slow Motion Duration** (`tap_impact_slow_motion_duration`): scene gốc `0.4`; script `0.36`.

**Charge Level 1 Impact**

- **Charged Impact Zoom Enabled** (`charged_impact_zoom_enabled`): scene gốc `true`; script `true`.
- **Charged Impact Zoom Multiplier** (`charged_impact_zoom_multiplier`): scene gốc `1.3`; script `1.5`.
- **Charged Impact Zoom In Duration** (`charged_impact_zoom_in_duration`): scene gốc `0.09`; script `0.09`.
- **Charged Impact Zoom Duration** (`charged_impact_zoom_duration`): scene gốc `0.3`; script `0.6`.
- **Charged Impact Slow Motion Enabled** (`charged_impact_slow_motion_enabled`): scene gốc `true`; script `true`.
- **Charged Impact Slow Motion Scale** (`charged_impact_slow_motion_scale`): scene gốc `0.42`; script `0.35`.
- **Charged Impact Slow Motion Duration** (`charged_impact_slow_motion_duration`): scene gốc `0.44`; script `0.36`.

**Charge Level 2 Impact**

- **Full Impact Zoom Enabled** (`full_impact_zoom_enabled`): scene gốc `true`; script `true`.
- **Full Impact Zoom Multiplier** (`full_impact_zoom_multiplier`): scene gốc `1.5`; script `1.5`.
- **Full Impact Zoom In Duration** (`full_impact_zoom_in_duration`): scene gốc `0.09`; script `0.09`.
- **Full Impact Zoom Duration** (`full_impact_zoom_duration`): scene gốc `0.4`; script `0.6`.
- **Full Impact Slow Motion Enabled** (`full_impact_slow_motion_enabled`): scene gốc `true`; script `true`.
- **Full Impact Slow Motion Scale** (`full_impact_slow_motion_scale`): scene gốc `0.37`; script `0.35`.
- **Full Impact Slow Motion Duration** (`full_impact_slow_motion_duration`): scene gốc `0.5`; script `0.36`.


<a id="sentinel"></a>
## 7. Dark Sentinel: entry, rút HP và debug

Player root → **Dark Sentinel**:

- `sentinel_hp_drain_percent`: phần trăm HP **tối đa** rút mỗi giây game. 2 nghĩa là 2%, không phải 2 HP với mọi max HP. Dừng khi pause, chịu slow motion, không kích hoạt threshold.
- `sentinel_entry_duration`: thời gian bất động/i-frame lúc vào.
- `sentinel_recovery_tick_interval`: khoảng giữa tick hồi.
- `sentinel_recovery_percent`: phần trăm max HP/stamina hồi mỗi tick; cuối entry chốt full để không sai do làm tròn.

Các trường nằm trong danh mục Player ở phần 5. HP tự rút/skill cost không tự giết; 1 HP dừng rút và chờ hết hành động rồi thoát, chặn combo/skill mới. Sau thoát, marker dưới HP chờ đòn mới, không bật ngay. `PlayerVitals.spend_sentinel_hp()` là API chi phí, chưa có full skill sử dụng.

**Chưa có thông số để chỉnh skill Sentinel 1–4/Q/E, Toughness/Sharpness hay mức tích ulti từ hit/kill**, vì gameplay đó chưa triển khai. Đường vào Sentinel hiện cũng chưa gọi xóa Bleed/Fracture; không xem hồi full HP là đã xóa debuff. Thiết kế đã duyệt được giữ trong báo cáo Player.

Debug: mở `res://scenes/UI/hud.tscn` → **SentinelDebugControls**. `debug_keys_enabled` tắt/bật phím thử; `ultimate_gain` đổi số điểm T cộng, mặc định 30/100. R kích hoạt khi đầy; Y là thoát thử nghiệm, không thay thiết kế chiêu 4. Chỉ debug build; không nhận khi pause/menu/campfire/đang nhập chữ hoặc entry đang khóa thao tác. Các icon HUD là trình bày, không cấp skill.

<a id="enemy"></a>
## 8. Enemy: AI, damage, hitbox và death

### Chọn đúng scene

Enemy chiến đấu hiện hành: `res://scenes/enemy/spine_enemy.tscn` → **SpineEnemy**. Rig animation: `res://scenes/enemy/enemy_spine.tscn` → AnimationPlayer. `wobtear_enemy.tscn` là EnemyBase tuần tra tối thiểu. Map có thể override từng instance; sửa scene gốc để đổi chung, sửa instance để đổi riêng.

### HP, EXP và hành vi

- **Health:** `max_health`, `exp_reward` (kế thừa EnemyBase).
- **Patrol:** `speed`, `patrol_range`, `walk_duration`, `idle_duration`, `initial_direction`. Đây là đi tuần, không phải tốc độ đuổi.
- **Detection:** `detection_distance`, `disengage_distance`, `chase_memory`, `reset_opener_on_disengage`, `run_speed`. Nên để disengage lớn hơn detect để tránh đổi trạng thái liên tục. Walk → detect player → Run là chuyển tiếp animation, không tự rút ngắn bằng cách tăng run_speed.
- **Opening Leap:** `leap_range`, `windup_time`, `jump_speed`, `max_leap_speed`, `landing_time`, `leap_damage`.
- **Follow-up Attacks:** `melee_range`, `attack_height_tolerance`, `attack3_chance` (0–1), `recovery_time`, `attack2_damage`, `attack3_damage`, `attack2_window`, `attack3_window`. Window là Vector2 giây từ đầu clip; cần start < end và nằm trong clip.
- **Rig Alignment:** `animation_offsets` chỉnh offset theo clip. Run bay là dụng ý; người dùng tự căn, không mặc định hạ rig. `sprite_faces_left` dành cho hướng nguồn EnemyBase; SpineEnemy mirror VisualPivot/WeaponPivot theo code riêng.

#### SpineEnemy

Scene `res://scenes/enemy/spine_enemy.tscn` → **SpineEnemy**.


**Health**

- **Max Health** (`max_health`): scene gốc `100`; script `20`.
- **Exp Reward** (`exp_reward`): scene gốc `30`; script `30`.

**Patrol**

- **Speed** (`speed`): scene gốc `80`; script `150`.
- **Patrol Range** (`patrol_range`): scene gốc `200`; script `200`.
- **Walk Duration** (`walk_duration`): scene gốc `5`; script `5`.
- **Idle Duration** (`idle_duration`): scene gốc `5`; script `5`.
- **Initial Direction** (`initial_direction`): scene gốc `1`; script `1`.

**Animation**

- **Animation Idle** (`animation_idle`): scene gốc `&"idle"`; script `&"idle"`.
- **Animation Walk** (`animation_walk`): scene gốc `&"walking"`; script `&"walking"`.
- **Sprite Faces Left** (`sprite_faces_left`): scene gốc `true`; script `true`.


**Detection**

- **Detection Distance** (`detection_distance`): scene gốc `500`; script `500`.
- **Disengage Distance** (`disengage_distance`): scene gốc `650`; script `650`.
- **Chase Memory** (`chase_memory`): scene gốc `1.5`; script `1.5`.
- **Reset Opener On Disengage** (`reset_opener_on_disengage`): scene gốc `true`; script `true`.
- **Run Speed** (`run_speed`): scene gốc `240`; script `240`.

**Opening Leap**

- **Leap Range** (`leap_range`): scene gốc `280`; script `280`.
- **Windup Time** (`windup_time`): scene gốc `0.4`; script `0.4`.
- **Jump Speed** (`jump_speed`): scene gốc `420`; script `420`.
- **Max Leap Speed** (`max_leap_speed`): scene gốc `520`; script `520`.
- **Landing Time** (`landing_time`): scene gốc `0.35`; script `0.35`.
- **Leap Damage** (`leap_damage`): scene gốc `20`; script `20`.

**Follow-up Attacks**

- **Melee Range** (`melee_range`): scene gốc `110`; script `110`.
- **Attack Height Tolerance** (`attack_height_tolerance`): scene gốc `100`; script `100`.
- **Attack3 Chance** (`attack3_chance`): scene gốc `0.2`; script `0.2`.
- **Recovery Time** (`recovery_time`): scene gốc `0.7`; script `0.7`.
- **Attack2 Damage** (`attack2_damage`): scene gốc `12`; script `12`.
- **Attack3 Damage** (`attack3_damage`): scene gốc `18`; script `18`.
- **Attack2 Window** (`attack2_window`): scene gốc `Vector2(0.3, 0.45)`; script `Vector2(0.3, 0.45)`.
- **Attack3 Window** (`attack3_window`): scene gốc `Vector2(0.4, 0.65)`; script `Vector2(0.4, 0.65)`.

**Death Terrain**

- **Corpse Terrain Mask** (`corpse_terrain_mask`): scene gốc `1`; script `1`.

**Rig Alignment**

- **Animation Offsets** (`animation_offsets`): scene gốc `Dictionary theo clip; mở Inspector để xem từng mục`; script `Dictionary theo clip; mở Inspector để xem từng mục`.

#### Wobtear

Scene `res://scenes/enemy/wobtear_enemy.tscn` → **WobtearEnemy**.


**Health**

- **Max Health** (`max_health`): scene gốc `20`; script `20`.
- **Exp Reward** (`exp_reward`): scene gốc `30`; script `30`.

**Patrol**

- **Speed** (`speed`): scene gốc `150`; script `150`.
- **Patrol Range** (`patrol_range`): scene gốc `200`; script `200`.
- **Walk Duration** (`walk_duration`): scene gốc `5`; script `5`.
- **Idle Duration** (`idle_duration`): scene gốc `5`; script `5`.
- **Initial Direction** (`initial_direction`): scene gốc `1`; script `1`.

**Animation**

- **Animation Idle** (`animation_idle`): scene gốc `&"idle"`; script `&"idle"`.
- **Animation Walk** (`animation_walk`): scene gốc `&"walking"`; script `&"walking"`.
- **Sprite Faces Left** (`sprite_faces_left`): scene gốc `true`; script `true`.


### Vùng đánh và vùng nhận hit

SpineEnemy scene:

- **CollisionShape2D** gốc: collider thân/hình nhận hit hiện tại và tâm lock-on. Đổi Shape/Position ảnh hưởng nhận hit, va địa hình và điểm khóa.
- **WeaponPivot/Hitbox/CollisionShape2D**: damage melee phía trước VFX. Căn khi rig hướng trái nguồn, thử lại cả hai hướng. `attack2_window`/`attack3_window` quyết định lúc mở, không chỉnh collider thân để tăng tầm chém.
- **LeapHitbox/CollisionShape2D**: damage vồ theo thân, shape riêng. Muốn gần bằng vùng nhận hit, căn kích thước và transform tương ứng collider gốc; không dùng vùng chém phía trước.
- Hitbox mở/đóng lúc runtime; `disabled` trong editor là trạng thái an toàn ban đầu. Bật Visible Collision Shapes khi debug để đối chiếu animation và physics.

### Death, ordering và debug

Thời gian tồn tại sau chết theo **độ dài clip death** trong enemy_spine.tscn, hiện 10s; không có timer xóa thứ hai. Chỉnh clip để thay thời gian; fading đã có trong animation. Khi chết trên không, vẫn phát death và rơi bằng luật Player; `corpse_terrain_mask` chỉ chọn địa hình cho collider xác, không bật lại combat.

Player root Z Index hiện 200, enemy 100 → enemy phía sau Player. Chỉnh **root actor → Ordering → Z Index** nếu muốn đổi cả actor; giữ nguyên ordering bộ phận rig. Ordering không thay khả năng đi xuyên/đánh trúng.

Kiểm tra cả **instance trong map/scene test**: một override ở instance sẽ ưu tiên hơn scene gốc. Trong `res://scenes/enemy/spine_enemy_test.tscn`, chọn **PlayableAdel → Ordering → Z Index**; giá trị đúng đang kế thừa là **200**. Đã bỏ override `0` tại instance này ngày 16/10/2026. Nếu có biểu tượng Revert cạnh thuộc tính, dùng Revert để trả về giá trị scene gốc thay vì sửa ordering từng bộ phận rig. Instance **Enemy** kế thừa **100**.

Trong game Esc → **Debug - Enemies** → **Disable enemy AI** / **Invincible enemies**. Hai tùy chọn giữ trong phiên debug, không save; không tự hỗ trợ mọi prototype legacy. Không cần đặt HP cực lớn để thử bất tử. Enemy đã chết không sống lại khi bật bất tử.

<a id="camera"></a>
## 9. Camera, mouse pan, khóa mục tiêu và zoom

Mở Player scene → **Camera2D**, script `res://scenes/camera_2d.gd`. Zoom nền ở Inspector Camera2D → **Zoom**; Offset có thể bị Ground Framing tính lại khi chức năng đó bật.

- **Camera Settings:** `follow_speed_x`, `follow_speed_y`; số lớn bám nhanh hơn.
- **Horizontal Follow:** `horizontal_follow_delay` là trễ khi bắt đầu/đổi hướng ngang; `horizontal_center_snap_distance` là khoảng gần tâm sẽ snap. Không thêm lookahead facing mặc định.
- **Ground Framing:** `ground_framing_enabled`; `ground_screen_fraction` là tỷ lệ dưới chân tính từ đáy. Tăng tỷ lệ thì thấy nhiều đất dưới chân hơn. Công thức: vùng world cao `viewport_height / zoom.y`, phần đất world = vùng cao × tỷ lệ. Với 43/270 và H1080, phần dưới chân luôn 172 pixel đầu ra khi đứng ổn định; zoom2 là 86 world units, không phải 86 pixel đầu ra.
- **Deadzone:** `vertical_deadzone` là vùng chênh cao trước khi đổi tracking Y, khác mouse deadzone.
- **Mouse Pan:** `mouse_pan_enabled`, `mouse_pan_max_distance` (Vector2, giới hạn world theo ellipse), `mouse_pan_deadzone` (0–0.9, tỷ lệ vùng chuột trung tính), `mouse_pan_follow_speed` (bám/trả offset).
- **Mouse Auto Reset:** bật/tắt và `mouse_pan_auto_reset_delay`; đếm không rê chuột theo thời gian thực khi gameplay nhận điều khiển.
- **Target Lock:** `lock_on_enabled`, `lock_switch_hold_time`, `lock_switch_drag_distance` (pixel viewport), `lock_switch_half_angle` (độ). Vùng chọn hiện là camera, không có export bán kính khóa độc lập. Giới hạn kéo khi khóa dùng chung `mouse_pan_max_distance`.
- **Hit Stop Zoom:** `hit_stop_zoom_enabled`, `hit_stop_zoom_multiplier`, `hit_stop_zoom_in_duration`, `hit_stop_zoom_out_duration`. Pulse ngắn theo thời gian thực không pause. Không tác động zoom đánh thường đã bị tắt, cũng không chỉnh zoom stagger/Q ở đây.

Trong game Esc → **Camera** cho chỉnh auto-center, idle delay và mouse deadzone. Các giá trị lưu trong `user://camera_controls.cfg` có ưu tiên hơn ba default Inspector tương ứng; muốn thử mặc định khác, chỉnh ngay menu hoặc dùng user directory thử riêng. Không xóa save/checkpoint để reset camera preferences.

Scene `res://scenes/adel/playable_adel.tscn` → **Camera2D**.


**Camera Settings**

- **Follow Speed X** (`follow_speed_x`): scene gốc `6`; script `8`.
- **Follow Speed Y** (`follow_speed_y`): scene gốc `5`; script `5`.

**Ground Framing**

- **Ground Framing Enabled** (`ground_framing_enabled`): scene gốc `true`; script `true`.
- **Ground Screen Fraction** (`ground_screen_fraction`): scene gốc `43 / 270`; script `43 / 270`.

**Horizontal Follow**

- **Horizontal Follow Delay** (`horizontal_follow_delay`): scene gốc `0.2`; script `0.1`.
- **Horizontal Center Snap Distance** (`horizontal_center_snap_distance`): scene gốc `0.2`; script `0.1`.

**Deadzone (Vùng chết)**

- **Vertical Deadzone** (`vertical_deadzone`): scene gốc `60`; script `60`.

**Mouse Pan**

- **Mouse Pan Enabled** (`mouse_pan_enabled`): scene gốc `true`; script `true`.
- **Mouse Pan Max Distance** (`mouse_pan_max_distance`): scene gốc `Vector2(110, 65)`; script `Vector2(90, 55)`.
- **Mouse Pan Deadzone** (`mouse_pan_deadzone`): scene gốc `0.15`; script `0.18`.
- **Mouse Pan Follow Speed** (`mouse_pan_follow_speed`): scene gốc `6.5`; script `5`.

**Mouse Auto Reset**

- **Mouse Pan Auto Reset Enabled** (`mouse_pan_auto_reset_enabled`): scene gốc `true`; script `true`.
- **Mouse Pan Auto Reset Delay** (`mouse_pan_auto_reset_delay`): scene gốc `3`; script `3`.

**Target Lock**

- **Lock On Enabled** (`lock_on_enabled`): scene gốc `true`; script `true`.
- **Lock Switch Hold Time** (`lock_switch_hold_time`): scene gốc `0.2`; script `0.2`.
- **Lock Switch Drag Distance** (`lock_switch_drag_distance`): scene gốc `24`; script `24`.
- **Lock Switch Half Angle** (`lock_switch_half_angle`): scene gốc `65`; script `65`.

**Hit Stop Zoom**

- **Hit Stop Zoom Enabled** (`hit_stop_zoom_enabled`): scene gốc `true`; script `true`.
- **Hit Stop Zoom Multiplier** (`hit_stop_zoom_multiplier`): scene gốc `1.02`; script `1.05`.
- **Hit Stop Zoom In Duration** (`hit_stop_zoom_in_duration`): scene gốc `0.035`; script `0.025`.
- **Hit Stop Zoom Out Duration** (`hit_stop_zoom_out_duration`): scene gốc `0.08`; script `0.09`.


Trigger map dùng `res://scenes/Mechanic/camera_zoom_trigger.gd`: `target_zoom`, `zoom_duration`. Đây là đường legacy ghi trực tiếp zoom; kiểm tra tranh quyền với zoom combat khi gắn trong map. Camera campfire là camera riêng, chỉnh ở scene Campfire.

<a id="hud"></a>
## 10. HUD, thanh ulti, icon và loadout

Mở `res://scenes/UI/hud.tscn` → node **hud**. **HUD Layout** có `hud_scale`, `screen_margin`, `show_numeric_values`; **Sentinel HUD Layout** có `sentinel_loadout_scale`, `sentinel_screen_margin`. HUD thuộc CanvasLayer nên không chạy theo camera zoom.

- Thanh ulti: **ScreenSpace/bar/hp_bar_panel/UltimateMeter** → Layout/Transform. Tăng Position X/offset_left để cách bình máu hơn; giữ width nếu không muốn đổi độ dài. Chỉnh trong hud.tscn và lưu, không chỉ kéo instance tạm trong Player. Runtime giữ vị trí node đã lưu; không còn export Ultimate Meter Offset thứ hai.
- Hình thanh ulti: mở `res://scenes/UI/sentinel/ultimate_meter.tscn`; `meter_size`, `fire_speed`, `preview_charge`. Preview Charge chỉ editor, không cấp charge gameplay; `fire_speed` là chuyển động phần cháy.
- Cụm Sentinel: `res://scenes/UI/sentinel/sentinel_loadout.tscn`. `hud_scale`, `screen_margin`, `reserved_top`; `preview_active` chỉ xem editor. `WeaponArtwork` đổi hình vũ khí. Các ô **Q**, **E**, **Skill1/2/3/4** có `icon` và `key_label`; nhãn phím không tự đổi input gameplay.
- Màu HP Sentinel: `res://scenes/UI/sentinel/hp_sentinel_fill.svg`, `res://scenes/UI/sentinel/hp_sentinel_rim.svg`, `res://scenes/UI/sentinel/hp_sentinel_track.svg`; các hằng texture trong ui.gd nạp ba file này. Texture HP thường và marker nằm trong hud.tscn.
- Icon Bleed/Fracture dùng `res://asset/UI/Menu screen/Bleed.png`, `fracture.png`; `ui.gd.sync_status_icons()` gửi ID effect tới thanh status. Xem mapping icon của `res://scenes/UI/status_icon_slot.gd` để thay đúng loại. Poisoning và icon thử không đồng nghĩa có debuff gameplay.
- Các hằng `SCREEN_SHAKE_FLASK`, `SCREEN_SHAKE_STAGGER`, `FLASK_SHAKE_DECAY` trong ui.gd là phản hồi HUD hiện có; không phải tham số rung Camera2D gameplay.

Preview an toàn: mở `res://scenes/UI/previews/dark_sentinel_hud_preview.tscn` và F6, dùng các nút xem Normal/Ulti/Sentinel/Pending/Cooldown. Preview độc lập không là bản skill gameplay và không ghi save.

#### HUD chính

Scene `res://scenes/UI/hud.tscn` → **hud**.


**HUD Layout**

- **Hud Scale** (`hud_scale`): scene gốc `1`; script `1.25`.
- **Screen Margin** (`screen_margin`): scene gốc `Vector2(24, 24)`; script `Vector2(24, 24)`.
- **Show Numeric Values** (`show_numeric_values`): scene gốc `false`; script `false`.

**Sentinel HUD Layout**

- **Sentinel Loadout Scale** (`sentinel_loadout_scale`): scene gốc `1`; script `1`.
- **Sentinel Screen Margin** (`sentinel_screen_margin`): scene gốc `Vector2(24, 24)`; script `Vector2(24, 24)`.

#### Thanh ulti

Scene `res://scenes/UI/sentinel/ultimate_meter.tscn` → **UltimateMeter**.


**Ultimate Appearance**

- **Meter Size** (`meter_size`): scene gốc `Vector2(132, 22)`; script `Vector2(132, 22)`.
- **Fire Speed** (`fire_speed`): scene gốc `0.35`; script `0.35`.

**Editor Preview**

- **Preview Charge** (`preview_charge`): scene gốc `100`; script `100`.

#### Cụm Sentinel

Scene `res://scenes/UI/sentinel/sentinel_loadout.tscn` → **SentinelLoadout**.


**Sentinel Layout**

- **Hud Scale** (`hud_scale`): scene gốc `1`; script `1`.
- **Screen Margin** (`screen_margin`): scene gốc `Vector2(24, 24)`; script `Vector2(24, 24)`.
- **Reserved Top** (`reserved_top`): scene gốc `220`; script `220`.

**Editor Preview**

- **Preview Active** (`preview_active`): scene gốc `false`; script `false`.

#### Phím Sentinel thử nghiệm

Scene `res://scenes/UI/hud.tscn` → **SentinelDebugControls**.


**Thông số**

- **Debug Keys Enabled** (`debug_keys_enabled`): scene gốc `true`; script `true`.
- **Ultimate Gain** (`ultimate_gain`): scene gốc `30`; script `30`.

#### Ô kỹ năng dùng lại

Scene `res://scenes/UI/sentinel/sentinel_ability_slot.tscn` → **Ability**.


**Thông số**

- **Icon** (`icon`): scene gốc `null`; script `null`.
- **Key Label** (`key_label`): scene gốc `"1"`; script `"1"`.


<a id="campfire-save"></a>
## 11. Campfire, menu, save và phím

### Campfire

Mở `res://scenes/Mechanic/campfire.tscn` hoặc chọn **Campfire** instance trong map. Source `res://scenes/Mechanic/campfire.gd`:

- `checkpoint_id`: định danh checkpoint; dùng ID riêng cho từng điểm. `display_name`, `rest_hint`: nhãn/gợi ý.
- `detect_radius` hiện chỉ được khai báo, chưa áp vào shape bằng script; để đổi tầm tương tác thực tế, chỉnh Shape của **Campfire/CollisionShape2D**. `rest_offset` đặt vị trí ngồi tương đối. Kiểm tra cả RestPosition và collider khi đổi layout.
- **Transitions:** `enter_fade_out_duration`, `enter_fade_in_duration`, `leave_fade_duration`, `load_fade_duration`, `title_fade_duration`. Fade theo thời gian thực; leave/load duration là mỗi nửa fade trong luồng tương ứng. Chỉ hiện chuột/menu sau fade-in hoàn tất.
- `REST_COOLDOWN_SEC` trong script là khóa chống dùng lại ngắn. F chỉ mở; thoát bằng Leave. Esc bị chặn trong toàn lượt campfire, không chỉnh shortcut pause để bỏ qua quyền UI này.

Scene `res://scenes/Mechanic/campfire.tscn` → **Campfire**.


**Thông số**

- **Checkpoint Id** (`checkpoint_id`): scene gốc `"campfire_01"`; script `"campfire_01"`.
- **Display Name** (`display_name`): scene gốc `"Campfire"`; script `"Campfire"`.
- **Rest Hint** (`rest_hint`): scene gốc `"Press F to rest"`; script `"Press F to rest"`.
- **Detect Radius** (`detect_radius`): scene gốc `96`; script `96`.
- **Rest Offset** (`rest_offset`): scene gốc `60`; script `60`.

**Transitions**

- **Enter Fade Out Duration** (`enter_fade_out_duration`): scene gốc `0.7`; script `0.7`.
- **Enter Fade In Duration** (`enter_fade_in_duration`): scene gốc `2`; script `2`.
- **Leave Fade Duration** (`leave_fade_duration`): scene gốc `0.5`; script `0.5`.
- **Load Fade Duration** (`load_fade_duration`): scene gốc `0.5`; script `0.5`.
- **Title Fade Duration** (`title_fade_duration`): scene gốc `0.8`; script `0.8`.


### Vào game và save

`res://scenes/UI/save_manager.gd`: `TITLE_SCENE`, `NEW_GAME_SCENE` chọn scene đích; New Game cần spawn phù hợp, hiện `SpawnPoint_Default`. `MAX_SAVE_SLOTS` hiện 5, tăng số lượng cần đồng bộ UI slot và validation, không chỉ đổi hằng. `SAVE_VERSION` là schema, không tăng tùy ý như một thông số gameplay.

Slot và backup nằm ở `user://`, dùng menu Project → Open User Data Folder để tìm. Slot1 `soujourn_save.json`, slot2–5 `soujourn_save_2.json`…`_5.json`, `.bak` là backup gần nhất. Các file `.before-new-game-...bak` là bản trước Replace. Không sửa/xóa các file đó chỉ để thử tuning. Dùng bản sao project với custom user directory khi chạy suite save/flow.

### Input Map và debug

Project Settings → **Input Map** là nơi đổi phím thực tế: `weapon_skill` (Q), `attack`, `guard and deflect`, `dodge`, `jump`, `move_left/right/down`, `soul_heal`, và các action tương tác/UI đang khai báo. Một số thao tác khóa chuột giữa và phím Sentinel debug xử lý trực tiếp trong component; tra `camera_target_lock.gd` và `sentinel_debug_controls.gd` trước khi chỉ đổi nhãn hoặc thêm action. Không sửa icon chữ Q/E để đổi shortcut.

Sau chỉnh: thử hai hướng, trên đất/trên không, thiếu stamina, bị ngắt, pause/resume và respawn với save riêng. Không mặc định F6 một suite ghi save là an toàn nếu fixture yêu cầu user directory riêng.

<a id="cap-nhat"></a>
## 12. Quy trình cập nhật file này

Khi có thông số mới hoặc chuyển node/script: sửa ngay phần hệ thống tương ứng, ghi tên Inspector/tên biến, đường dẫn, ý nghĩa/đơn vị, miền giá trị nếu cần và cách thử. Cập nhật giá trị scene gốc lẫn default script nếu chúng khác; không đặt lại scene của người dùng để khớp tài liệu. Nếu có runtime/save override, ghi ưu tiên đó.

Giữ nội dung hiện hành ngay tại mục đang có, thay mô tả đã bị thay thế thay vì chồng nhiều đoạn đính chính. Các bản báo cáo hệ thống chỉ ghi cơ chế, phạm vi và kiểm chứng; liên kết về file này cho tuning. Cập nhật ngày trên đầu file và mục thay đổi gần nhất bên dưới. Không tạo báo cáo mới cho từng thông số. `.docx` và bản tổng hợp tuần là tài liệu lịch sử giữ nguyên.

### Thay đổi gần nhất

- 16/10/2026: nối đầy đủ hệ số Fracture vào damage combo/jump/Q, tốc di chuyển ngang và tốc đánh combo/jump; đồng bộ hitbox, nối đòn và khóa Defense/land. Chuyển hệ số cũ thành các hằng `FRACTURE_*` trong model; không thay giá trị tuning/override scene.
- 16/10/2026: tạo hướng dẫn chung từ các báo cáo cũ, đối chiếu source/scene hiện tại; bao gồm rơi chậm/ngưng theo frame, jump air giữ trọn clip, Q ba mức/freeze, Sentinel nền, debug enemy và bố cục camera/HUD. Giá trị trong danh mục là cấu hình scene tại lượt tổng hợp, không phải cam kết mọi map instance giống nhau.
