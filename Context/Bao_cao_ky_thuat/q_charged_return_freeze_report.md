# Q mức 1/2: giữ zoom, đóng băng khi trả zoom và input buffer

Ngày: 16/10/2026. Áp dụng cho Q Saber, cập nhật sau phần tách ba bộ tuning. Các giá trị người dùng đã chỉnh trong scene được giữ nguyên.

## Luồng hiện hành

- **Nhấn nhanh:** giữ luồng zoom/slow motion cũ, không có pha đóng băng khi kết thúc Q.
- **Charge mức 1 và 2, có va chạm:** ngay vào `saber_skill_5`, zoom vào theo cấu hình riêng rồi giữ tại đỉnh. Không tự trả zoom theo đồng hồ cũ trong lúc `saber_skill_6` đang chạy. Skill_6 vẫn chạy đúng toàn bộ clip và thời lượng recovery đã cấu hình; khi đến cuối, giữ pose cuối rồi mới bắt đầu trả zoom.
- **Trong lúc trả zoom:** dùng pause thật của SceneTree, không dùng time_scale gần 0. Player, enemy, physics, animation và timer gameplay ngừng hoàn toàn. Chỉ bộ điều khiển camera/input của pha này chạy. Camera tiếp tục cập nhật zoom và offset Y qua API camera hiện có, giữ luật mặt đất 43/270 và vị trí X đang có.
- Các đường nhận damage Player/Vitals/EnemyBase cũng chặn callback đến muộn trong pha freeze, tránh HP thay đổi do signal đã được xếp hàng trước ranh giới pause. Không thêm i-frame sau khi mở băng.
- **Trả zoom xong:** nhả đúng quyền pause do pha này tạo, về full `saber_ready` rồi thực hiện input đã buffer nếu còn hợp lệ. Q-owned slow motion kết thúc khi vào pha freeze, không bị giữ lại để phát tiếp sau khi mở băng. Những nguồn hiệu ứng khác vẫn thuộc chủ sở hữu của chúng.
- Đánh hụt, tắt Zoom Enabled, Zoom Multiplier = 1 hoặc Zoom Duration = 0: không tạo freeze không nhìn thấy; Q kết thúc bình thường. Không thay damage, tầm lao, điều kiện charge, hitbox hoặc i-frame.

## Input buffer trong pha trả zoom

Giữ **một yêu cầu mới nhất** cho Attack, Q, Defense, Dash, Jump hoặc Soul Heal. Input không bị hết hạn trong thời gian freeze và không được thực hiện sớm.

- Tap Attack/Q rồi nhả vẫn được thực hiện sau khi mở băng; Q đã nhả sẽ dùng nhánh tap/minimum windup bình thường.
- Defense cần vẫn giữ nút tại thời điểm mở băng; nhả trong freeze sẽ hủy yêu cầu. Lần nhấn mới đã buffer được nhận cả khi Q trước đó yêu cầu nhả/nhấn lại defense. Đồng hồ defense/deflect bắt đầu khi thực sự vào defense, không tính thời gian freeze.
- Dash giữ hướng tại lúc nhấn; vẫn kiểm tra stamina/cooldown/air-dash như trước. Jump dùng cùng logic nhảy hiện có.
- Hướng di chuyển đang giữ vẫn được Input cập nhật và nhân vật tiếp tục theo hướng đó sau freeze; không tích một hàng dài combo.
- Echo phím không tạo yêu cầu mới. Giữ Q cũ không tự lặp skill. Input bị từ chối nếu sau freeze player đang ở trạng thái không được phép, ví dụ chờ thoát Sentinel, chết/stagger hoặc khóa điều khiển.
- Esc/B/interact không mở hoặc nhả pause/menu giữa pha freeze. Menu thường vẫn hoạt động bình thường trước/sau pha này. Không buffer thao tác UI. Mất focus/checkpoint/chuyển scene dùng cleanup để nhả pause và xóa input cũ.

## Vị trí điều chỉnh

Mở `res://scenes/adel/playable_adel.tscn` → chọn **SaberSkill**:

- **Charge Level 1 Impact → Charged Impact Zoom Duration**: thời gian trả zoom/đóng băng của mức 1, tính bằng **giây thực**.
- **Charge Level 2 Impact → Full Impact Zoom Duration**: tương tự mức 2.

Giá trị mặc định hai trường này vẫn **0,60s** để không ghi đè tuning đã có. Từ lượt này chúng là thời gian trả zoom sau skill_6, không còn là tổng ngân sách hiệu ứng zoom theo giây actor từ lúc va chạm. Có thể thử giảm còn 0,15–0,25s nếu muốn nhịp trả zoom nhanh hơn; đây chỉ là gợi ý, không tự áp vào scene.

Zoom Multiplier/Zoom In Duration và Impact Slow Motion vẫn nằm trong từng nhóm Q. Thời gian giữ đỉnh tự theo chuỗi skill_5 → toàn bộ skill_6. **Impact Timing → Charged Recovery Duration** điều chỉnh thời gian skill_6; không làm ngắn animation resource gốc. Nhánh Tap Impact giữ cách tính Zoom Duration theo giây actor như trước.

## Thứ tự hiển thị

Node gốc **PlayableAdel → Ordering → Z Index = 200**. SpineEnemy vẫn ở 100, Wobtear ở band thấp hơn; các phần rig Player thấp nhất vẫn cao hơn toàn bộ rig enemy hiện tại. Enemy vì vậy nằm sau toàn bộ nhân vật, không bị xen giữa các chi/tay/đầu. Không sửa z_index từng bộ phận, rig, animation hoặc collision. Hitbox/hurtbox hoạt động độc lập thứ tự vẽ.

## Code và kiểm chứng

`charged_skill_finish.gd` sở hữu held zoom, paused return, một input buffer và pause owner dạng weak reference. Node chạy ALWAYS chỉ để vẽ camera/nhận input trong freeze, cleanup khi bị hủy hoặc rời cây. Không tiếp quản pause có sẵn. `SaberWeaponSkill` vẫn sở hữu chuỗi attack/recovery; phase completion theo clip manually advanced thật, không dựa vào timeout slow-motion có thể kết thúc sớm. `LocomotionComponent.perform_buffered_jump` tái sử dụng logic nhảy cũ; Player điều phối replay và kiểm tra điều kiện.

Pause/master menu kiểm tra quyền freeze trước khi đổi pause. `Player.clear_combat_input`, hủy skill, checkpoint, mất focus và rời scene hủy quyền/zoom/input tương ứng. Bản normal completion vẫn full ready và có thể bị ngắt bởi hành động mới.

Scene mới `tests/adel/q_return_validation.tscn` chạy trên Player/enemy thật: hai mức charge, zoom giữ đỉnh đến frame cuối, physics/animation/timer đóng băng, camera vẫn chuyển động, attack/Q/defense/dash/jump buffer, latest-wins, release gate, không lặp Q, chặn menu can thiệp pause, checkpoint/free Player, pause không thuộc cinematic, disabled/zero zoom, tap/whiff và hit-stop/slow motion dài không cắt clip. Chạy Godot 4.7 headless và có render, save riêng `CodexQReturn20261016`. Có ảnh viewport trong pha trả zoom, đã xem thứ tự nhân vật/enemy. Các suite Q, buffer cũ, Player cleanup, campfire, debug enemy và camera framing được chạy đối chiếu. Log cuối ở `outputs/q-return-20261016`.
