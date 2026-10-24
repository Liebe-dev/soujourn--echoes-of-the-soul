# Hướng dẫn tùy chỉnh thông số game

Cập nhật: **24/10/2026**. Đây là file dùng chung: khi thêm hoặc đổi thông số, cập nhật ngay mục liên quan trong file này. Không tạo thêm một báo cáo riêng chỉ để thông báo chỗ chỉnh thông số.

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

Các mục dưới phản ánh cấu hình source/scene hiện hành; không dùng giá trị mặc định để đặt lại override của người dùng. Thuộc tính có Resource cấu hình riêng từ 24/10/2026, các hệ thống khác vẫn theo vị trí ghi ở từng mục.

<a id="hp-stamina"></a>
## 2. HP, stamina, bình máu và progression

### Thuộc tính, HP/stamina và điểm lên cấp — 24/10/2026

Mở **FileSystem → `res://scenes/Mechanic/progression_config.tres` → Inspector**. Resource này được `PlayerProgress.config` nạp; script khai báo là `res://scenes/Mechanic/progression_config.gd`. Dừng game, sửa và lưu Resource rồi chạy lại. Tám thuộc tính khởi đầu có **0 điểm đầu tư**; save lưu điểm đã đầu tư, không lưu một bản công thức riêng.

Các giá trị dưới đây là **mặc định script**, Resource hiện **không override**, scene/instance hiện không override các trường này. Đây là **bộ số thử nghiệm**, chưa nghiệm thu cân bằng:

- **Level and Resources:** `points_per_level = 5` điểm/cấp; `base_hp = 100` HP; `base_stamina = 100` stamina; `exp_per_level_base = 100` EXP, ngưỡng cấp kế = hệ số × level. Đổi điểm/cấp chỉ tác động lần lên cấp tiếp theo của save phiên bản 2, không tính lại số điểm đã nhận.
- **Attribute Contributions:** `vitality_hp = 10` HP/điểm Vitality; `strength_hp = 4` HP/điểm Strength; `resistance_hp = 2` HP/điểm Resistance. HP tối đa = nền + ba đóng góp, làm tròn về số nguyên một lần.
- Cùng nhóm: `agility_stamina = 4` stamina/điểm Agility; `agility_regen = 0.28` stamina/**giây actor**/điểm Agility. Tốc hồi = **giá trị nền đã cấu hình trên Player/instance** + thưởng Agility; không cộng lên giá trị model đã có thưởng. Actor time hiện chịu pause/slow motion và các chủ sở hữu CombatTime hiện hành, không phải giây thực.
- Cùng nhóm: `prowess_attack = 0.02`, `strength_attack = 0.012`, hệ số thưởng sát thương nền/điểm, tương ứng 2% và 1,2%, còn nhân scaling riêng của món vũ khí. Đây không phải % tăng tổng HP/stamina mỗi điểm.
- **Dark Sentinel:** `assimilation_damage = 0.003` hệ số sát thương Sentinel thêm/điểm Dark Arts Assimilation; `upkeep_step = 10` điểm/mốc; `upkeep_reduction_per_step = 0.05` hệ số giảm HP rút duy trì/mốc; `upkeep_reduction_cap = 0.5` trần giảm. Giảm duy trì = min(floor(điểm / mốc) × hệ số, trần); lượng HP rút nền vẫn lấy từ Player và tính theo **giây game**, không phải giây thực.
- **Equipment:** `unmet_requirement_factor = 0.2` hệ số damage khi vũ khí thiếu ít nhất một yêu cầu. Chỉ áp dụng một lần. Hiện nối cho vũ khí; chưa phải hệ giáp/passive.

`PlayerProgress.apply_to_stats()` tính lại từ dữ liệu gốc, giữ HP/stamina hiện có và clamp nếu vượt tối đa mới; không hồi khi mở menu, thay thuộc tính hoặc gắn lại HUD. Mặc định model hồi stamina vẫn **28**, Player scene `PlayableAdel → Stamina → Stamina Regen Per Second` vẫn override **33**; Agility cộng lên đúng nền này. Instance trong `spine_enemy_test.tscn` không override nền hồi; vẫn phải kiểm tra instance khi chỉnh map khác.

Resistance hiện chỉ cộng HP, **không tác động Bleed/Fracture**. Giảm xác suất/thời lượng debuff ngoài hai loại này chưa có nguồn gameplay hỗ trợ. Arts Compatibility/Faith lưu và nâng được nhưng chờ Arts/Divine Arts; Dark Arts Assimilation hiện chỉ nối damage Sentinel và duy trì, chưa nối nguồn ulti/chi phí skill 1–4. Xem mô tả khi rê vào tên thuộc tính trong menu. Chưa có soft cap hay đồ bonus tham gia xét yêu cầu.

### Cách nâng và đọc dữ liệu thật

Vào campfire → **Relica/Upgrade**: dùng `− / +` cho tám thuộc tính trong danh sách cuộn, xem HP/stamina/hồi và Saber trước → sau; **Confirm and save** mới tiêu điểm và ghi slot. **Reset plan** hoặc **Back** bỏ bản phân bổ thử, không tẩy điểm đã xác nhận. Thiếu điểm/dữ liệu không hợp lệ/lỗi ghi giữ điểm và bản thử; scene chạy riêng chưa chọn slot không được tự ghi đè. Character đọc tám thuộc tính, EXP, điểm và Coin/Soul thật; Equipment hiện thông tin vũ khí đang cầm, còn grid túi đồ/giáp là nền trình bày.

Vị trí UI: `res://scenes/UI/campfire_upgrade_menu.tscn → Panel/MarginContainer/VBox`: **Scroll/Attributes** chứa tám hàng tạo từ danh mục trong `campfire_upgrade_menu.gd::_ready()`; font hàng **22 px viewport**, nút +/− **44×44 px**; **Preview, Status, Actions/Confirm, Actions/Reset, BackButton** giữ bố cục. `_layout()` dùng khung **920×880 px**, lề tổng **32 px**, thu nhỏ đồng đều tới vừa viewport, không phóng quá 1. Đây là số layout cố định trong hàm, không export/override; offsets scene đồng bộ khung này. Character giữ bố cục cũ, **UpgradePointsLabel** ở (136,982)–(620,1040), font 22; Equipment **WeaponDetails** ở (136,730)–(700,870), font 22. Những giá trị này là layout authored trong scene, không có mặc định script hay override instance mới.

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


### Yêu cầu và scaling vũ khí

Mở `res://scenes/adel/weapon/saber.tscn → Saber → Requirements and Scaling`, hoặc **PlayableAdel/WeaponHolder/Saber**. Script `weapon_data.gd`:
- `requirements: Dictionary[StringName, int] = {}`: số điểm cần đạt theo ID thuộc tính; dictionary rỗng nghĩa là không yêu cầu. ID dùng `vitality, prowess, strength, agility, resistance, arts_compatibility, dark_arts_assimilation, faith`. Phải đạt tất cả; vẫn được cầm món không đạt.
- `attribute_scaling = {prowess: 1.0, strength: 1.0}`: hệ số không đơn vị của riêng món. Hiện công thức damage hỗ trợ Prowess và Strength, các stat Arts chưa cấp damage giả. Saber scene và instance Player/map hiện **không override** hai dictionary, nên vũ khí khởi đầu dùng đủ ngay với tám điểm đầu tư bằng 0.
- Attack = damage nền × (1 + Prowess × hệ số cấu hình × scaling Prowess + Strength × hệ số cấu hình × scaling Strength), rồi nhân mức thiếu yêu cầu từ Resource. Combo/jump/Q dùng chung `PlayableAdel.scale_attack_damage()` tại contact: kết hợp Fracture và thưởng Sentinel đúng một lần, làm tròn damage cuối về số nguyên. Giữ `damage = 20`, finisher `1.2` và timing cũ.
- Thiếu yêu cầu chặn Q trước animation, tài nguyên, cooldown và buffer; HUD **ScreenSpace/WeaponLoadout/Q** hiện **LOCK** và làm tối icon, rê vào để xem đang có/cần có. Đây là trình bày khóa theo gameplay, không phải export mới. Đủ lại thì gỡ khóa; cooldown thực vẫn độc lập. E/tay trái chưa có gameplay. Kiểm tra điều kiện thuộc về từng WeaponData, chưa có inventory/equip nhiều tay để thử luồng đổi đồ thực.
- Tab Equipment có **WeaponDetails**: damage nền/thực nhận trước mục tiêu, scaling, yêu cầu và trạng thái Q. Chưa thay icon placeholder thành một hệ túi đồ.

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

- **Cooldown:** **SaberSkill → Cooldown** có `tap_cooldown`, `charged_cooldown`, `full_cooldown`, tương ứng nhấn nhanh/tụ mức 1/mức 2. Mặc định script **5/8/10**; scene `playable_adel.tscn` hiện được người dùng override thành **4/6/8**. Đơn vị **giây game**, chưa có override map riêng cho ba trường này. Bắt đầu ở `_start_lunge()` khi thực sự tung đòn, không tính lúc đang giữ/tụ Q. Dừng khi pause và freeze trả zoom; chịu slow motion/hit-stop toàn game, kể cả pha Player được miễn slow motion. Chỉnh số giây trong Inspector; 0 là không hồi cho mức đó. Đánh hụt hoặc bị ngắt sau khi tung vẫn giữ hồi; bị hủy trước khi lao không tiêu hồi. Chỉ chặn Q, không khóa di chuyển/đánh thường/Defense; bấm trong hồi không tạo lệnh chờ tự dùng khi hết. `restore_checkpoint_state()` reset hồi và HUD; hồi không lưu trong save.
- **Tắt/bật hồi khi debug:** trong game **Esc → Debug - Skills → Skill cooldowns**. Mặc định **bật**; **tắt** sẽ xóa hồi Q hiện tại, trả HUD về sẵn sàng ngay khi menu còn pause và bỏ hồi ở mọi lần Q tiếp theo, tới khi **bật lại**. Bật lại chỉ áp dụng hồi bình thường cho lần tung tiếp theo, không tự tạo hồi cho chiêu trước đó. Tùy chọn giữ xuyên checkpoint/đổi map trong phiên debug, không ghi save/config, khởi động game mới mặc định bật; release luôn dùng hồi bình thường. Scene `res://scenes/UI/game_pause_menu.tscn` → **VBoxContainer/SkillDebug/CooldownsEnabled** là CheckButton, `button_pressed=true` trong scene; script `pause.gd` đồng bộ trạng thái phiên khi mở menu và xử lý `_on_skill_cooldowns_toggled()`. Biến bool `cooldowns_enabled=true` trong `res://scenes/adel/components/skill_debug_settings.gd` là mặc định script, không export/không override scene; `SaberWeaponSkill` đọc qua `are_cooldowns_enabled()`. Việc tắt không sửa ba thông số Cooldown trong Inspector; bật lại dùng đúng override hiện tại **4/6/8**. Nhóm debug chỉ hiện ở debug build.
- **Charge:** `tap_windup`; `charge_level_1_time`/`charge_level_2_time` là hai mốc giữ; `charged_release_windup` là phần thêm sau thả mức 1; `full_charge_final_pose` là pose cuối trước ép lao mức 2. Thả giữa mốc lấy mức thấp đã đạt. `allow_airborne` bật/tắt Q trên không.
- **Lunge:** `lunge_distance` là quãng nhấn nhanh; nhân `charged_distance_multiplier`/`full_distance_multiplier` cho hai mức giữ. `lunge_speed` đổi tốc độ, không đổi tổng ngân sách quãng đường. `enemy_detection_mask` là physics bitmask chọn đối tượng dò; không phải layer index đơn lẻ.
- **Damage And Stun:** `damage` cơ sở, `charged_damage_multiplier`/`full_damage_multiplier`; `charged_stun_duration`/`full_stun_duration` là thời gian enemy không tấn công sau trúng. Nhấn nhanh không có stun charge. `impact_pose_duration` là pha skill_5.
- **Impact Timing:** ba `*_hit_stop_duration` cho tap/mức 1/mức 2; `tap_recovery_duration` và `charged_recovery_duration` đặt thời lượng skill_6; `recovery_slow_motion_scale` đặt mức chậm toàn game trừ Player của recovery charge. Thời lượng recovery charge được giữ theo thời gian thực.
- **Tap Impact / Charge Level 1 Impact / Charge Level 2 Impact:** ba bộ độc lập. `*_zoom_enabled`, `*_zoom_multiplier`, `*_zoom_in_duration`, `*_zoom_duration`; `*_slow_motion_enabled`, `*_slow_motion_scale`, `*_slow_motion_duration`.

**Quan trọng về Zoom Duration:** với charge 1/2, giữ zoom đỉnh tới khi skill_6 kết thúc, rồi `charged_impact_zoom_duration`/`full_impact_zoom_duration` là thời gian trả zoom có đóng băng toàn game, tính bằng giây thực. Với tap, duration vẫn là pulse theo đồng hồ actor, không có pha freeze cuối. Tắt zoom/hệ số 1/thời lượng 0 không tạo freeze vô hình. Slow motion impact tính thời gian thực và độc lập hiệu ứng recovery; nguồn chậm mạnh nhất được chọn khi cùng tồn tại.

Freeze vẫn nhận một input buffer mới nhất; không có tham số export riêng cho số lượng buffer. Không đổi `attack_input_buffer` để kéo dài freeze hay tích nhiều hành động. Trong freeze, Defense cần còn giữ; các điều kiện hành động được kiểm tra lại sau mở băng. Q buffer vẫn phải qua kiểm tra cooldown; với hồi mặc định đang chạy sẽ không được thực hiện lại. Khi Q nhận quyền điều khiển sau tiếp đất, `SaberWeaponSkill.begin()` xóa cờ `_playing_land_anim` của clip đã bị thay để đi/chạy có thể ngắt Ready ngay sau skill; đứng yên vẫn chơi đủ Ready gốc. Không có thông số tuning mới cho sửa animation này.

Q dùng shape của **WeaponPivot/SaberHitbox/Hitbox/CollisionShape2D**; `SaberHitbox.begin_skill_window()` lấy Position/Rotation từ key đầu của clip hitbox **saber_attack_1**. Muốn đổi offset Q hiện tại thì chỉnh các key đó, nó sẽ ảnh hưởng cả đòn 1; chưa có export offset Q độc lập. Q dừng ở enemy đầu tiên. Vùng dò va chạm lunge lấy collider thân Player; không kéo collider detect để tăng damage area. Miễn damage của Q thường chỉ trong lunge; không nhầm với Q Sentinel đang ở thiết kế.

Scene `res://scenes/adel/playable_adel.tscn` → **SaberSkill**.


**Cooldown**

- **Tap Cooldown** (`tap_cooldown`): script `5.0`, scene gốc override `4.0` giây game; nhấn nhanh, miền Inspector từ 0 trở lên.
- **Charged Cooldown** (`charged_cooldown`): script `8.0`, scene gốc override `6.0` giây game; tụ mức 1.
- **Full Cooldown** (`full_cooldown`): script `10.0`, scene gốc override `8.0` giây game; tụ mức 2.
- Giữ các override scene người dùng vừa chỉnh, chưa có override map riêng; mốc bắt đầu và đồng hồ như mô tả trên. Không nhầm với các mốc giữ `charge_level_1_time=0.7`/`charge_level_2_time=1.5` đang được người dùng override trong scene.

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

- `sentinel_hp_drain_percent`: mức nền phần trăm HP **tối đa** rút mỗi giây game; nhân thêm hệ số giảm duy trì từ Dark Arts Assimilation (phần 2). 2 nghĩa là 2%, không phải 2 HP với mọi max HP. Dừng khi pause, chịu slow motion, không kích hoạt threshold.
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
- **Currency Rewards:** `coin_reward = 5` Coin/vòng đời, `soul_reward = 1` Soul/vòng đời là **mặc định script thử nghiệm** trong `enemy_base.gd`. `spine_enemy.tscn`, `wobtear_enemy.tscn` và các instance hiện không override hai trường; để chỉnh chọn root enemy → nhóm này. Nhận một lần lúc chết hợp lệ, không có đơn vị thời gian. Reload/respawn enemy tạo vòng đời mới; chưa lưu xác chết lâu dài. Enemy legacy dùng script khác không tự nhận thưởng tiền.
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

Mở `res://scenes/UI/hud.tscn` → node **hud**. **HUD Layout** có `hud_scale`, `screen_margin`, `show_numeric_values` cho cụm phía trên; nhóm **Bottom Loadout Layout** có `sentinel_screen_margin` dùng chung cho hai cụm phía dưới. Scale phía dưới chỉnh trực tiếp ở **ScreenSpace/WeaponLoadout** và **ScreenSpace/SentinelLoadout**, mỗi node có **Hud Scale** riêng. HUD thuộc CanvasLayer nên không chạy theo camera zoom.

- Thanh ulti: **ScreenSpace/bar/hp_bar_panel/UltimateMeter** → Layout/Transform. Tăng Position X/offset_left để cách bình máu hơn; giữ width nếu không muốn đổi độ dài. Chỉnh trong hud.tscn và lưu, không chỉ kéo instance tạm trong Player. Runtime giữ vị trí node đã lưu; không còn export Ultimate Meter Offset thứ hai.
- Hình thanh ulti: mở `res://scenes/UI/sentinel/ultimate_meter.tscn`; `meter_size`, `fire_speed`, `preview_charge`. Preview Charge chỉ editor, không cấp charge gameplay; `fire_speed` là chuyển động phần cháy.
- Cụm Sentinel: `res://scenes/UI/sentinel/sentinel_loadout.tscn`. `hud_scale`, `screen_margin`, `reserved_top`; `preview_active` chỉ xem editor. `WeaponArtwork` đổi hình vũ khí. Các ô **Q**, **E**, **Skill1/2/3/4** có `icon` và `key_label`; nhãn phím không tự đổi input gameplay.
- Màu HP Sentinel: `res://scenes/UI/sentinel/hp_sentinel_fill.svg`, `res://scenes/UI/sentinel/hp_sentinel_rim.svg`, `res://scenes/UI/sentinel/hp_sentinel_track.svg`; các hằng texture trong ui.gd nạp ba file này. Texture HP thường và marker nằm trong hud.tscn.
- Icon Bleed/Fracture dùng `res://asset/UI/Menu screen/Bleed.png`, `fracture.png`; `ui.gd.sync_status_icons()` gửi ID effect tới thanh status. Xem mapping icon của `res://scenes/UI/status_icon_slot.gd` để thay đúng loại. Poisoning và icon thử không đồng nghĩa có debuff gameplay.
- Phản hồi nhận đòn: `res://scenes/UI/ui.gd` đã bỏ `flash_red()` và các lời gọi trong `_on_vitals_damage()`, `apply_damage()` và `_process()`. HUD không nháy đỏ khi trúng đòn hoặc tick Bleed; HP, fade hiện/ẩn và nháy hồi máu vẫn hoạt động. Đây là thay đổi code, không có công tắc Inspector/override scene cho nháy đỏ.
- Rung stagger giữ luồng **`_on_stagger_triggered()` → `_trigger_impact_feedback()`** trong `ui.gd`: hằng `SCREEN_SHAKE_STAGGER=0.72` là cường độ màn hình, hệ số không đơn vị 0–1, không có override scene. Muốn mạnh/nhẹ hơn chỉnh hằng này; `_trigger_flask_shake()` vẫn rung bình máu cùng lượt. `SCREEN_SHAKE_FLASK` và `FLASK_SHAKE_DECAY` vẫn giữ nguyên; các hằng này không chỉnh thông số rung Camera2D gameplay.

Preview an toàn: mở `res://scenes/UI/previews/dark_sentinel_hud_preview.tscn` và F6, dùng các nút xem Normal/Ulti/Sentinel/Pending/Cooldown. Preview độc lập không là bản skill gameplay và không ghi save.

<a id="weapon-hud"></a>
#### HUD vũ khí thường: vị trí và cách chỉnh

Scene chính: `res://scenes/UI/hud.tscn` → **ScreenSpace/WeaponLoadout**, nguồn `res://scenes/UI/weapon/weapon_loadout.tscn`. Ở dạng thường hiện cụm này; vào Sentinel ẩn nó và hiện SentinelLoadout, thoát đổi lại. Hai cụm dùng chung lề trái/dưới, không vẽ chồng nhau; cùng chịu fade/nháy hồi máu và ẩn campfire như HUD hiện hành.

- **Kích thước cả cụm khi chơi:** trong `hud.tscn`, chọn **ScreenSpace/WeaponLoadout → Weapon Layout → Hud Scale** (`hud_scale`), instance hiện **`1.25`**; cụm Sentinel chỉnh **ScreenSpace/SentinelLoadout → Sentinel Layout → Hud Scale**, instance hiện **`0.65`**. Đây là hệ số không đơn vị, miền Inspector 0.25–3.0; tăng để phóng to. Script của cả hai cụm mặc định `1.0`. Runtime giữ giá trị đã lưu khi khởi tạo/resize; viewport quá nhỏ tự giảm scale để vừa vùng trống. Không chỉnh **Transform → Scale** vì layout tính lại thuộc tính đó. Hai thông số scale trùng trên HUD cha đã bỏ vì trước đây ghi đè lựa chọn này.
- **Lề chung:** `hud.tscn` → **hud → Bottom Loadout Layout → Sentinel Screen Margin** (`sentinel_screen_margin`), mặc định script/scene `Vector2(24,24)`: X là lề trái, Y là lề dưới, đơn vị pixel viewport. Tên biến cũ được giữ để tương thích; kéo Position trực tiếp trên instance sẽ bị layout runtime đặt lại. HUD vẫn truyền lề chung và tính `reserved_top` từ HUD trên (hiện 223 px ở scale HUD trên bằng 1), nhưng không truyền scale. Không có map override mới trong lượt này.
- **Căn trong scene riêng và ưu tiên override:** `weapon_loadout.tscn` → **WeaponLoadout → Weapon Layout → Hud Scale** hiện **`1.5`**, mặc định script **`1.0`**. Scene Sentinel gốc hiện **`0.75`**, mặc định script **`1.0`**. Hai instance trong `hud.tscn` đang override thành **`1.25` / `0.65`**, nên sửa scene gốc sẽ chưa đổi gameplay; muốn kế thừa giá trị gốc thì bấm **Revert** cạnh **Hud Scale** trên instance tương ứng và lưu `hud.tscn`. Giữ nguyên các override người dùng vừa chỉnh. Khi mở scene riêng, `screen_margin=Vector2(24,24)` và `reserved_top=220.0` vẫn kế thừa mặc định script. Kích thước tham chiếu cụm thường là `REFERENCE_SIZE=Vector2(234,99)` trong `weapon_loadout.gd`, đồng bộ với size node gốc nếu đổi bố cục; đã bỏ phần chiều cao chừa cho chữ Q/E.
- **Nền lót:** chọn **WeaponLoadout → Weapon Appearance → Inset Opacity**, biến `inset_opacity`, mặc định script/scene **0.32** (32%, miền 0–1). Dùng `Layer 10.png` đặt tại node **Inset**, Position `(15,5)`, Size `(204,73)`; giữa khung `(10,0)`, Size `(214,88)`. Shader `weapon_inset.gdshader` chuẩn hóa alpha gốc 87/255 trước khi áp 0.32, tránh nhân alpha hai lần; phần dưới hai ô dùng nửa trên nguyên vẹn đối xứng để lấp chỗ khoét skill cũ, không đổi họa tiết giữa hoặc PNG nguồn. Chỉnh Position/Size của Inset nếu cần đổi khe hở với khung.
- **Khung và bản vá:** node **Frame** dùng nguyên `asset/UI/HUD/Rectangle 4.png`. **BorderRepair/Left** và **Right** lấy hai đoạn viền trên nguyên vẹn qua AtlasTexture, lật dọc để lấp phần thiếu ở hai góc dưới. Asset PNG tác giả được giữ nguyên, không dùng bản sinh ảnh đã làm lệch họa tiết giữa. Khi chỉnh kích thước/offset khung phải căn cả hai node vá và Inset theo cùng tỉ lệ.
- **Hình vũ khí:** **WeaponLoadout → Weapon Appearance → Right Weapon / Left Weapon**, tương ứng `right_weapon`/`left_weapon`; script mặc định cả hai `null`, scene gốc tay phải dùng **`res://asset/UI/HUD/saber1.png`**, tay trái `null`. Tay phải vẫn ở ô hình bên trái như ảnh mẫu; ô hình bên phải để trống. Đã bỏ ảnh khiên, material tách nền và ô skill E khỏi cụm thường; ảnh nguồn cũ vẫn giữ nguyên.
- **Phóng to/căn kiếm:** `weapon_loadout.tscn` → **RightWeaponArtwork → Layout/Transform**: Position hiện **`(18,5)` px** theo giá trị người dùng đã căn, Size **`(71,74)` px**, Rotation **`0°`** trong scene. PNG `saber1.png` đã có góc chéo như ảnh mẫu và hiển thị nguyên kích thước gốc, không còn xoay thêm -0.8 rad như bản dùng `saber.png`. Muốn to hơn, tăng hai chiều Size cùng tỉ lệ, rồi chỉnh Position để giữ hình giữa ô; không sửa rig gameplay hoặc ảnh nguồn. Stretch Mode vẫn Keep Aspect Centered. `LeftWeaponArtwork` giữ node rỗng để dành cho trang bị sau, không có texture/material.
- **Icon skill tay phải:** trong `weapon_loadout.tscn` chọn **Q → Icon** (`icon`): scene gốc dùng **`res://asset/UI/HUD/skill.png`** do người dùng cung cấp; script slot mặc định `null`. Không còn node **Key** hoặc export `key_label` trong slot thường nên không hiện chữ Q/E dưới icon. Tên node **Q** chỉ dùng định danh API, không vẽ lên màn hình. Quy ước input thiết kế vẫn là chuột trái/Q tay phải, chuột phải/E tay trái; lần sửa hình này không đổi input gameplay. Icon `saber_q_icon.png` cũ được giữ nhưng không còn được HUD thường tham chiếu.
- **Nếu scene test/map vẫn hiện ảnh cũ:** kiểm tra `hud.tscn` → **ScreenSpace/WeaponLoadout → Right Weapon / Left Weapon**. Instance này hiện kế thừa `saber1.png`/`null` từ scene gốc, không còn override kiếm/khiên cũ. Khi có biểu tượng Revert cạnh thuộc tính và muốn dùng cấu hình chung, trả về giá trị kế thừa; không gán lại texture cũ tại HUD. Luồng đã đối chiếu là `spine_enemy_test.tscn → PlayableAdel → Camera2D/hud → ScreenSpace/WeaponLoadout`. Nếu scale không đổi, kiểm tra **Hud Scale** trên instance trong `hud.tscn` trước khi sửa scene gốc như hướng dẫn ưu tiên override phía trên; lưu scene rồi dừng/chạy lại F6 để nạp cấu hình mới.
- **Cooldown:** chọn **Q → Cooldown Appearance**, `cooldown_opacity=0.6` (đen 60%), `ready_border_color=Color.WHITE`, `cooldown_border_color=Color(0.5,0.5,0.5,1)`; các giá trị scene kế thừa đúng mặc định script. Chữ thời gian: **Q/Remaining → Theme Overrides → Font Sizes → Font Size**, scene `19` px. Khi remaining > 0 và total > 0, viền xám, lớp đen giữ phần còn lại phía dưới và rút từ trên xuống; hiển thị số giây với một chữ số thập phân. Hết hồi trả viền trắng, bỏ lớp đen và số.
- **API hiển thị:** `ui.gd.set_weapon_ability_presentation(slot, remaining, total)` nhận slot `&"Q"`; `&"E"` được bỏ qua an toàn vì hiện không có ô E. `PlayableAdel._ready()` nối signal `SaberSkill.cooldown_changed` vào API này và đồng bộ trạng thái đầu tiên. Hồi Q gameplay hiện **4/6/8 giây game** theo override scene cho nhấn nhanh/tụ mức 1/mức 2; mặc định script 5/8/10, chỉnh tại [SaberSkill → Cooldown](#skill-q). HUD không sở hữu timer; giây còn lại và tổng được gửi từ skill, dừng/tiếp tục cùng gameplay khi pause/slow motion. Ví dụ remaining 3 / total 6 che nửa dưới. Khi đang hồi, tín hiệu giữ HUD hiện để đọc thời gian; ẩn campfire/đổi cụm Sentinel không reset đồng hồ. Tắt **Skill cooldowns** trong pause sẽ trả HUD về sẵn sàng tới khi bật lại. Chưa thêm chi phí stamina Q; E và logic chi phí/hồi chiêu tay trái còn chờ gameplay.
- **Vật phẩm/mana/Arts:** **ItemSlots/Selected, Next, Previous** chỉ là ba Control rỗng, chưa có icon/số lượng/trang bị/sử dụng. C/Z chưa bind; thiết kế chờ là C tới kế tiếp, Z về trước, xoay vòng tối đa ba vật phẩm (bánh mì → đá vụn → bình nước). Chưa thêm hai bình mana hoặc các ô Arts 1–4 vào cụm thường. Các ô 1–4 vốn có của Sentinel được giữ nguyên.

Xem thử: F6 `res://scenes/UI/previews/weapon_hud_preview.tscn`, chọn **Thường / Cooldown Q / Sentinel**. Đồng hồ 6 giây chỉ thuộc script preview `weapon_hud_preview.gd` (`_duration=6.0`, không export/không override scene), chịu pause/slow motion theo game time; không phải cooldown gameplay. Preview không spawn Player, không ghi save. Kiểm thử tự động ở `res://tests/ui/weapon_hud_validation.tscn` yêu cầu bản sao project có custom user directory chứa `CodexWeaponHUD`.

#### HUD chính

Scene `res://scenes/UI/hud.tscn` → **hud**.


**HUD Layout**

- **Hud Scale** (`hud_scale`): scene gốc `1`; script `1.25`.
- **Screen Margin** (`screen_margin`): scene gốc `Vector2(24, 24)`; script `Vector2(24, 24)`.
- **Show Numeric Values** (`show_numeric_values`): scene gốc `false`; script `false`.

**Bottom Loadout Layout**

- **Sentinel Screen Margin** (`sentinel_screen_margin`): scene gốc `Vector2(24, 24)`; script `Vector2(24, 24)`; dùng chung cho cụm thường và Sentinel.

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

- **Hud Scale** (`hud_scale`): scene gốc `0.75`; script `1`; instance **ScreenSpace/SentinelLoadout** trong `hud.tscn` override `0.65`. Hệ số không đơn vị, tăng để phóng to; viewport nhỏ tự giảm để vừa vùng trống. Chỉnh ở instance để đổi gameplay, hoặc Revert trên instance để kế thừa scene gốc.
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

Màn hình mở đầu là `res://scenes/UI/title_screen.tscn` → node gốc **TitleScreen** (Node2D), script **`res://scenes/UI/title_screen.gd`**. Đã đổi tên từ `menu (2)`/`Node2D2`; hiện gom cây node thành Background, Interface, TransitionLayer và Audio. Chỉnh scene chạy khi F5 ở **Project Settings → Application → Run → Main Scene**, hiện `res://scenes/UI/title_screen.tscn` (`application/run/main_scene` trong `project.godot`). Đây là đường dẫn scene, không có đơn vị; project đang ghi trực tiếp giá trị này, không có override map.

<a id="title-screen"></a>
**Title screen — vị trí chỉnh hiện hành**

- Mở `res://scenes/UI/title_screen.tscn`, chọn **TitleScreen → Inspector → Title Timing**. Các export sau tính bằng **giây game**, chịu Engine.time_scale/pause của cây; title bình thường chạy scale 1 nên trùng giây thực. Không có cơ chế ignore time scale. Mặc định script và scene hiện tại giống nhau, **không có override**: **Intro Fade Duration** `1.8` (đen → nền); **Prompt Fade Duration** `1.0` (chữ Press Start hiện); **Prompt Blink Duration** `1.5` (mỗi nửa nhịp nháy); **Prompt Exit Duration** `0.5`; **Menu Fade Duration** `0.8`; **Game Fade Duration** `0.8`; **Quit Fade Duration** `1.2`; **Quit Audio Duration** `2.0`. Quit chờ thời lượng dài nhất trong các tween song song. Các giá trị được chuyển từ số cố định cũ trong script, không thay nhịp mặc định.
- **Background/Logo**, **Background/Slogan**: Position và Texture của Sprite2D; giữ ảnh/vị trí cũ. Nền cuộn ở **Background/ParallaxBackground/ParallaxLayer/Sprite2D**. Script `parallax_background.gd` vẫn dùng `scroll_speed = 50` pixel viewport/giây game theo delta; không export, không override scene; đổi dấu để đảo chiều. Texture/font/âm thanh nguồn vẫn được giữ.
- Menu ở **Interface/Root/MainMenu/Start, Continue, Option, Quit**: chỉnh **Layout → Transform/Offsets** để căn nút và **Icon** để đổi ảnh chữ. Mỗi nút có **SelectionHighlight**: đổi **Texture**, vị trí/kích thước tại node này; mouse_filter Ignore và StyleBox focus rỗng để dùng chính ảnh chọn cho chuột/bàn phím. Script chung `title_menu_button.gd` có **Pressed Scale** mặc định `2.0` lần scale gốc, **Pressed Duration** `1.0` giây game; cả bốn instance hiện không override. Hiệu ứng reset khi rời lựa chọn/ẩn menu, không tăng scale cộng dồn.
- Chữ mở đầu ở **Interface/Root/PressStartLabel**: Text và Label Settings (font SystemFont Trajan Pro hiện tại, cỡ `38` pixel viewport). Có thể gán font resource do dự án cung cấp; chưa thay/đóng gói font trong lượt này.
- Màn chọn slot ở **Interface/Root/SaveSlotMenu**, nguồn **`res://scenes/UI/save_slot_menu.tscn`**. Chỉnh tại scene nguồn hoặc bật Editable Children để override instance: **Center/Panel → Custom Minimum Size X** `640` pixel viewport; **Margin** bốn lề `24`; **Contents → Separation** `14`; **Title → Font Size** `28`; **Status → Custom Minimum Size X** `580`; **SlotList → Separation** `10`; **Back → Custom Minimum Size Y** `48`. Đây là giá trị authored trong scene (không có default script tương ứng), instance title không override. Root **Slot Button Minimum Height** (`slot_button_minimum_height`, script `save_slot_menu.gd`) mặc định `52` pixel viewport, scene/instance không override; chỉ các nút slot được tạo từ dữ liệu lúc chạy. **Shade → Color alpha** `0.92`. **OverwriteConfirmation** giữ popup `560×200` pixel viewport trong `select_slot()`. Nội dung/kiểm tra slot thuộc SaveManager, không nhập số slot thủ công vào layout.
- Settings ở **Interface/Root/SettingsMenu**, nguồn `res://scenes/UI/settings_menu.tscn`. Chọn root **SettingsMenu → Inspector → Settings Layout**: **Panel Size** (`panel_size`) mặc định script `(1240,820)` pixel viewport, scene/instance title không override; **Screen Margin** (`screen_margin`) mặc định `40` pixel viewport mỗi cạnh, không override. `_layout_window()` lấy kích thước lớn hơn giữa Panel Size và minimum của container, giữ tâm rồi thu nhỏ đồng đều để vừa viewport trừ lề; không phóng lớn quá scale 1. Vì vậy chỉnh hai export này để đổi cỡ/lề, không kéo offsets HBox để chống lại runtime. HBox authored neo giữa `(0.5,0.5)`, offsets `(-620,-410,620,410)`, gap `32`; **Sidebar → Custom Minimum Size X** `240`, gap `16`, nút sidebar cao tối thiểu `64`; Theme_settings font chung `22`, tiêu đề trang `32`, Content Style_settings lề trong `24`, Shade alpha `0.92`. Các giá trị này là thuộc tính scene, không có default script tương ứng/override instance. General còn là nội dung mẫu; Video và Controls đã triển khai.
- **Audio → Music** trong title: **Volume dB** scene `-6.314` dB (mặc định AudioStreamPlayer `0` dB); **HoverSound/ClickSound/StartSound** `0` dB, không override. Dùng AudioStreamPlayer cho nhạc/UI, bus **Music** và **SFX** tương ứng. Chỉnh gain khởi tạo chung ở **Audio dock → Music/SFX** và lưu **`res://scenes/default_bus_layout.tres`**, hiện cả hai `0` dB, unmuted, gửi Master. Project Settings → Audio → Buses → Default Bus Layout đang trỏ file này. Thay bus gain ảnh hưởng mọi player đã nối bus; player còn nối Master không tự chuyển theo.
- Hai slider **SettingsMenu/HBoxContainer/Content/Audio/MusicSlider, SfxSlider** có miền `0..1`, bước `0.01`, đơn vị hệ số biên độ tuyến tính (1 = 0 dB, 0 = mute). Giá trị authored `0.5` của scene được **đồng bộ từ bus thực tế lúc ready/mở** bằng `settings_menu.gd::_sync_audio()`, không coi `0.5` là gain khởi tạo. Bus mặc định 0 dB nên lần đầu hiển thị 1; sau đó dùng giá trị bus hiện hành. `_set_volume()` tra tên Music/SFX, mute ở 0 và bỏ mute khi tăng; nếu bus thiếu thì slider bị khóa và không gọi index lỗi. Âm lượng giữ trong phiên chạy qua AudioServer, **chưa lưu config giữa các lần mở game**.
- **TransitionLayer → Layer** `50`, **Interface → Layer** `1` là thứ tự vẽ, không có đơn vị/default script/override. **TransitionLayer/FadeRect** full rect để phủ cả modal; chỉ chặn input trong Transitioning. Trạng thái điều phối ở enum `title_screen.gd::State`; không sửa các cờ visible để đổi luồng khi game đang chạy.

`res://scenes/UI/save_manager.gd`: `TITLE_SCENE = "res://scenes/UI/title_screen.tscn"` chọn đích **Return to Title**; `NEW_GAME_SCENE` chọn scene New Game, cần spawn phù hợp, hiện `SpawnPoint_Default`. Hai hằng là đường dẫn trong script, không export/override scene; nếu đổi đích title sang scene khác thì cập nhật cả Main Scene và `TITLE_SCENE` để khởi động/thoát về cùng màn hình. `MAX_SAVE_SLOTS` hiện 5, tăng số lượng cần đồng bộ UI slot và validation, không chỉ đổi hằng. `SAVE_VERSION` là schema, không tăng tùy ý như một thông số gameplay.

**Progression/save phiên bản 2:** `SaveManager.SAVE_VERSION = 2`, không có đơn vị/Inspector/override. Lưu tám điểm đầu tư, điểm còn lại, Coin/Soul; HP/stamina tối đa tính lại từ Resource, không lấy snapshot cũ làm công thức. Đọc v1/không có version theo luật cũ 1 điểm/cấp: hoàn số nâng HP + stamina, giữ điểm dư kể cả điểm debug, cộng max(điểm/cấp cấu hình − 1, 0) × (level − 1). Bù chỉ ở đường đọc v1; v2 không tính lại. Schema legacy có khai báo điểm/cấp riêng hoặc trộn khóa thuộc tính/tiền mới bị từ chối thay vì đoán. HP giữ số hiện có, chỉ clamp xuống tối đa mới. Thông báo chuyển cơ chế hiện tại campfire.

Đọc/Continue không ghi file. Trước lần ghi thay v1 hợp lệ, giữ nguyên bytes ở `soujourn_save[_n].json.before-stats-v2.bak`; vẫn có `.bak` xoay và archive trước New Game riêng. Nếu không sao lưu/ghi được thì không xác nhận nâng. Không sửa/xóa save thật để thử migration.

Coin/Soul thuộc `PlayerProgress.coin/soul`; `add_currency()` nhận thưởng, `try_spend_currency()` kiểm tra hai số dư và trừ cùng lúc trong RAM, chưa phải giao dịch vật phẩm/rèn. Giới hạn lưu kỹ thuật là số nguyên không âm tới `MAX_SAVED_INTEGER = 9007199254740991` để JSON roundtrip chính xác; không phải soft cap gameplay. Thưởng địch được lưu cùng progression khi ghi campfire/xác nhận nâng; không tự ghi từng kill. Chưa có luật mất tiền khi chết, thưởng Observe/nhiệm vụ, shop/bán đồ/rèn hoặc Soul mua điểm.

Slot và backup nằm ở `user://`, dùng menu Project → Open User Data Folder để tìm. Slot1 `soujourn_save.json`, slot2–5 `soujourn_save_2.json`…`_5.json`, `.bak` là backup gần nhất. Các file `.before-new-game-...bak` là bản trước Replace. Không sửa/xóa các file đó chỉ để thử tuning. Dùng bản sao project với custom user directory khi chạy suite save/flow.

<a id="video-settings"></a>
**Video — màn hình, FPS và xác nhận thay đổi**

- Trong title: **Setting → Video**. Chọn rồi **Apply**; **Revert** hủy lựa chọn chưa áp dụng. **Restore defaults** chỉ chọn bộ mặc định, cần Apply để dùng/lưu. Đổi mode hoặc kích thước Windowed mở xác nhận **Keep changes / Revert** trong **15 giây thực**, không chịu Engine.time_scale hoặc pause. Esc trong xác nhận chỉ hoàn tác, không đóng Settings. Hết thời gian, rời tab/đóng Settings hoặc scene bị dọn đều trả runtime trước preview; chưa Keep thì không ghi đè cấu hình đã xác nhận. Chỉ đổi VSync/FPS thì Apply lưu ngay, không yêu cầu xác nhận màn hình.
- Scene nguồn **`res://scenes/UI/video_settings.tscn`**, instance **SettingsMenu/HBoxContainer/Content/Video**; script UI **`video_settings.gd`**. Bố cục: root separation `20`; Heading font `32`; DisplayRows/PerformanceRows separation `16`; các dòng HBox gap `24`, label minimum width `260`, OptionButton `320×52`; Status minimum height `64`; Footer gap `16`, Apply/Revert `130×52`, Restore defaults `220×52`. Đây là pixel viewport, authored trong scene, không có default script hoặc override instance tương ứng. Root Settings Layout vẫn sở hữu kích thước/lề toàn cửa sổ; không scale riêng trang Video.
- **ConfirmationLayer → Layer** `80` (thứ tự vẽ, không đơn vị) phủ cả Settings và giữ Tab/mũi tên trong hai nút xác nhận. **Overlay/Shade → Color alpha** `0.97`; **Center/Panel → minimum width** `640`, **Margin** bốn lề `32`, Contents gap `28`; Countdown font `28`, nút Keep/Revert minimum `200×56`, font `22`, gap `24`. Đây là giá trị scene, không default script/override instance. Countdown text cập nhật theo đồng hồ thật, không chỉnh số 15 trong Label để đổi luật.
- Backend **`res://scenes/UI/video_preferences.gd`**, autoload **VideoPreferences**: **CONFIRMATION_SECONDS** `15.0` giây thực là thời hạn xác nhận; **DEFAULTS** mặc định `mode="borderless"`, Windowed size `1280×720` pixel client area, `vsync=true`, `max_fps=60` frame/giây. Các giá trị là hằng script, không export/không override scene. **FPS_OPTIONS** hiện `30,60,120,144,0`; `0` là Unlimited, không phải 0 FPS. Muốn thêm mức FPS, sửa danh sách này; UI lấy cùng nguồn. Engine.max_fps được backend áp dụng lúc startup/Apply, nên cấu hình Video đang dùng ưu tiên hơn một giá trị max_fps đặt riêng ở nơi khác.
- Mode: **Windowed** dùng cửa sổ có viền; **Borderless** dùng `Window.MODE_FULLSCREEN`; **Fullscreen** dùng `MODE_EXCLUSIVE_FULLSCREEN`. Hai mode toàn màn hình giữ độ phân giải desktop hiện tại, Resolution bị khóa và hiển thị Desktop; không đổi độ phân giải/refresh rate của hệ điều hành. Windowed chọn từ **WINDOW_SIZES** trong backend và kích thước đã lưu: danh sách preset được lọc theo usable rect màn hình hiện tại, chừa `32×64` px cho viền/taskbar trong `_window_limit()`; không gọi danh sách display modes của GPU. Kích thước lưu được clamp theo màn hình khi startup, nên default 1280×720 có thể nhỏ hơn trên desktop nhỏ. `normalize()` nhận từ 320×180 đến 16384×16384 trước khi clamp; không coi đây là gợi ý để chọn cửa sổ quá lớn/nhỏ.
- Khung thiết kế vẫn từ **Project Settings → Display → Window → Size → Viewport Width/Height** `1920×1080`; **Stretch Mode** `viewport`, **Stretch Aspect** `keep` và runtime Window.content_scale_aspect Keep. Đây là giá trị project, không override map; đổi cỡ cửa sổ không đổi vùng nhìn world/HUD hoặc kéo méo tỷ lệ, có letterbox theo tỷ lệ màn hình. Chưa thêm render scale, chất lượng đồ họa, brightness hoặc màn hình/refresh selector.
- Tự nạp/lưu **`user://video.cfg`**, schema version `1`; file tạm `.tmp` và bản trước `.bak` cùng đường dẫn. Config hợp lệ ưu tiên DEFAULTS; main lỗi định dạng/schema có thể đọc backup, thông số sai kiểu/ngoài miền dùng default an toàn. Preview chỉ giữ trong RAM; Keep mới ghi file và cập nhật confirmed. Ghi thất bại hoàn tác runtime và giữ confirmed trước. Không sửa checkpoint hoặc `controls.cfg`; không lưu FPS thực đo được. VSync yêu cầu qua DisplayServer, driver/renderer có thể quyết định trạng thái hiệu dụng; FPS Limit là trần engine, không cam kết phần cứng đạt mức đó.

### Input Map và debug

<a id="controls-settings"></a>
**Controls — gán phím và lưu cấu hình**

- Trong game: title **Setting → Controls**. Click ô phím chính/phụ rồi nhấn phím hoặc nút chuột; có thể gán Ctrl/Alt/Shift + phím, phím modifier đứng riêng được nhận khi thả. Esc hủy gán, nhấn Esc khi không gán để quay lại. Clear chỉ xóa ô phụ, giữ ít nhất một phím cho mỗi thao tác. Reset trên dòng khôi phục riêng thao tác; Restore defaults cần xác nhận và khôi phục tất cả. Phím trùng giữa các thao tác/giữa hai ô bị từ chối, báo tên thao tác đang dùng; không tự đổi hoặc xóa phím khác. Hai tổ hợp cùng phím nền cũng bị coi là trùng để tránh cùng kích hoạt khi gameplay chấp nhận modifier dư. Không gán wheel cho thao tác giữ/thả.
- Phạm vi 13 thao tác hiện có, mặc định từ **Project Settings → Input Map**: `move_left/right/down` = A/D/S, `jump` = Space, `run` = Ctrl, `dodge` = Shift, `attack` = chuột trái, `guard and deflect` = chuột phải, `weapon_skill` = Q, `soul_heal` = 1, `interact` = F, `toggle_master_menu` = B, `target_lock` = chuột giữa. Đây là phím mặc định project, không phải tuning có đơn vị hoặc export scene. UI điều hướng (Esc/Enter/Tab/mũi tên, Q/E chuyển tab master menu) và phím Sentinel/debug giữ quy tắc hiện có; Esc dành riêng cho Back/hủy. Chưa thêm E skill, vật phẩm C/Z, Arts hoặc remap tay cầm.
- **`res://scenes/UI/input_bindings.gd`**, autoload **InputBindings**, sở hữu danh sách `ACTIONS` (action và nhãn) và InputMap thực tế. Sửa nhãn/thêm thao tác ở đây cùng với Input Map và code nhận action. Không đổi icon/chữ Q để đổi phím. `camera_target_lock.gd::_input()` nay đọc `target_lock`, giữ luật nhấn/thả/giữ-rê như trước; đổi sang phím vẫn giữ phím + rê chuột để chuyển mục tiêu.
- Tự lưu phím thành **`user://controls.cfg`**, schema version `1`, tối đa **2** ô bàn phím/chuột mỗi action; lấy theo vị trí phím vật lý và modifier. Không sửa checkpoint/save slot. Khi khởi động, cấu hình hợp lệ ưu tiên hơn Input Map mặc định; phần thiếu/sai kiểu dùng mặc định, cấu hình trùng bị trả về bộ mặc định. Lỗi lưu được báo và không áp dụng bộ mới vào InputMap. Các sự kiện tay cầm nếu đã có trong Input Map được giữ; giao diện hiện chỉ gán bàn phím/chuột. Muốn thay phím mặc định sau khi đã lưu config, dùng Restore defaults để lấy lại defaults project; không cần xóa save.
- Layout Controls riêng: **`res://scenes/UI/controls_settings.tscn`** gắn ở **SettingsMenu/HBoxContainer/Content/Controls**. Chỉnh Heading `32` px, khoảng cách VBox `16`, **Scroll/ListMargin → margin_right** `16`, **Rows → separation** `10`, **Status → minimum height** `56`, Footer gap `16`; nút Cancel/Restore authored minimum `180×50`/`220×50` px. Scroll có follow_focus và danh sách được tạo từ ACTIONS, không thêm dòng tay vào instance.
- Mỗi dòng dùng **`res://scenes/UI/control_binding_row.tscn`**: HBox gap `10`, cao tối thiểu `48`; Action label rộng tối thiểu `250`; Primary/Secondary `150×48`, Clear `62×48`, Reset `68×48` pixel viewport. Primary/Secondary clip chữ dài, tooltip giữ tên đầy đủ. Đây là minimum authored trong scene, có thể tăng theo font/container; không có giá trị script/override instance. `controls_settings.gd` quản lý capture, conflict/status và signal focus; `settings_menu.gd::_refresh_focus()` gom nút hiện hành để Tab/mũi tên không rơi ra menu sau.

Sau chỉnh: thử hai hướng, trên đất/trên không, thiếu stamina, bị ngắt, pause/resume và respawn với save riêng. Không mặc định F6 một suite ghi save là an toàn nếu fixture yêu cầu user directory riêng.

<a id="cap-nhat"></a>
## 12. Quy trình cập nhật file này

Khi có thông số mới hoặc chuyển node/script: sửa ngay phần hệ thống tương ứng, ghi tên Inspector/tên biến, đường dẫn, ý nghĩa/đơn vị, miền giá trị nếu cần và cách thử. Cập nhật giá trị scene gốc lẫn default script nếu chúng khác; không đặt lại scene của người dùng để khớp tài liệu. Nếu có runtime/save override, ghi ưu tiên đó.

Giữ nội dung hiện hành ngay tại mục đang có, thay mô tả đã bị thay thế thay vì chồng nhiều đoạn đính chính. Các bản báo cáo hệ thống chỉ ghi cơ chế, phạm vi và kiểm chứng; liên kết về file này cho tuning. Cập nhật ngày trên đầu file và mục thay đổi gần nhất bên dưới. Không tạo báo cáo mới cho từng thông số. `.docx` và bản tổng hợp tuần là tài liệu lịch sử giữ nguyên.

### Thay đổi gần nhất

- 24/10/2026: triển khai thuộc tính, phân bổ thử/xác nhận, migration v2, Character/Equipment dữ liệu thật, yêu cầu/scaling Saber, Coin/Soul/thưởng EnemyBase và phần damage/duy trì Sentinel của Assimilation. Giữ các tuning combat, scene rig/map và tài liệu Word đang sửa. Bộ số mới là cấu hình thử; các luồng phụ thuộc chưa có nền vẫn chờ.

- 17/10/2026: triển khai Video với Windowed/Borderless/Fullscreen, kích thước cửa sổ, VSync và FPS cap; staged Apply/Revert/defaults, xác nhận 15 giây thực và rollback, video.cfg riêng có backup. Giữ viewport 1920×1080 và aspect Keep.

- 17/10/2026: phóng Settings lên thiết kế 1240×820, font 22 và layout tự co theo viewport. Hoàn thiện Controls bàn phím/chuột, hai ô mỗi thao tác, chống trùng, reset/hủy và lưu controls.cfg; thêm action target_lock chuột giữa để remap áp dụng vào camera.

- 17/10/2026: tổ chức title thành Background/Interface/TransitionLayer/Audio, tách SaveSlotMenu, gom TitleMenuButton, tập trung trạng thái/tween và chuyển thời lượng cũ ra Title Timing. Sửa focus/menu phía sau Settings, chọn Start ban đầu, nối bus Music/SFX và đồng bộ slider; thêm nền tối cho Settings. Hướng dẫn vị trí/giá trị hiện hành tại mục Title screen.

- 17/10/2026: đổi scene/script màn hình mở đầu `menu (2)` thành `title_screen.tscn`/`title_screen.gd`, node gốc **TitleScreen**. Giữ UID scene/sidecar script, cập nhật Main Scene và `SaveManager.TITLE_SCENE`; giữ nguyên logic nút/layout và tài liệu lịch sử.
- 17/10/2026: thêm công tắc **Esc → Debug - Skills → Skill cooldowns**. Tắt xóa hồi hiện tại và bỏ hồi cho mọi lần Q tiếp theo tới khi bật lại; trạng thái chỉ giữ trong phiên debug, không đổi thông số Inspector hoặc save. Đối chiếu/giữ override mới của người dùng **4/6/8** trong Player scene, tách khỏi mặc định script **5/8/10**.
- 17/10/2026: sửa cờ animation tiếp đất còn sót khi giữ Q trên không rồi tụ dưới đất, để di chuyển ngắt Ready sau skill. Thêm cooldown Saber Q 5/8/10 giây game bắt đầu khi lao, chặn input dùng lại và nối signal lên HUD hồi chiêu hiện có; giữ thông số charge/impact/layout của người dùng.
- 17/10/2026: bỏ nháy đỏ HUD ở mọi đường nhận damage/Bleed; giữ rung màn hình/bình máu khi stagger, nháy hồi máu và fade. Xóa hàm `flash_red()` cùng các lời gọi, không đổi damage hoặc thông số rung.
- 17/10/2026: bỏ override ảnh kiếm/khiên và kích thước cũ để scene test kế thừa asset mới; giữ vị trí kiếm `(18,5)`. Bỏ hai scale trùng trên HUD cha từng ghi đè lúc khởi tạo/resize; scale do từng loadout sở hữu. Giữ cấu hình mới của người dùng: scene thường/Sentinel `1.5`/`0.75`, instance trong `hud.tscn` `1.25`/`0.65`; bổ sung cách Revert để kế thừa scene gốc.
- 17/10/2026: để trống vũ khí tay trái, bỏ ảnh khiên/skill E và chữ Q/E của HUD thường. Thay kiếm bằng `saber1.png` nguyên cỡ 71×74 theo góc chéo ảnh mẫu và icon Q bằng `skill.png` người dùng cung cấp. Bỏ phần chiều cao chừa cho chữ phím, giữ lề dưới/trái chung và cơ chế cooldown/Sentinel.
- 16/10/2026: thêm HUD vũ khí thường, Saber/ảnh khiên mẫu, icon Q chỉnh mới, ba ô vật phẩm rỗng; vá viền bằng AtlasTexture gốc và nền lót 32%. Thêm lớp trình bày cooldown Q/E đen 60%, chuyển thường/Sentinel, đổi nhóm Inspector thành Bottom Loadout Layout và giữ lề chung. Không thêm gameplay vật phẩm/mana/Arts/E hoặc chi phí/cooldown Q mới.
- 16/10/2026: nối đầy đủ hệ số Fracture vào damage combo/jump/Q, tốc di chuyển ngang và tốc đánh combo/jump; đồng bộ hitbox, nối đòn và khóa Defense/land. Chuyển hệ số cũ thành các hằng `FRACTURE_*` trong model; không thay giá trị tuning/override scene.
- 16/10/2026: tạo hướng dẫn chung từ các báo cáo cũ, đối chiếu source/scene hiện tại; bao gồm rơi chậm/ngưng theo frame, jump air giữ trọn clip, Q ba mức/freeze, Sentinel nền, debug enemy và bố cục camera/HUD. Giá trị trong danh mục là cấu hình scene tại lượt tổng hợp, không phải cam kết mọi map instance giống nhau.
