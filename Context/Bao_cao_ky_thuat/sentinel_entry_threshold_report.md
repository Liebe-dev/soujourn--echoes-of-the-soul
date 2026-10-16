# Sentinel: chuyển dạng, hồi phục và stagger threshold

Ngày: 16/10/2026. Thay thế phần giới hạn tương ứng trong các báo cáo Sentinel trước đây. Nguồn là code hiện lưu, không thay tuning/rig/asset trong scene của người dùng.

## Hành vi đã triển khai

- `R` debug khi đầy ulti bắt đầu pha `SENTINEL_ENTRY` dài **1,50 giây game**. Pha này ngắt/cleanup hành động cũ, đứng yên cả X/Y, không attack, Q, dash, defense, jump, dùng bình hoặc tương tác campfire/pickup. Input bị từ chối, không tích buffer để tự phát sau chuyển dạng. Pause/menu vẫn là thao tác giao diện; pause dừng đồng hồ chuyển dạng. `Y` debug cũng bị chặn trong pha chuyển dạng.
- Bắt đầu chuyển dạng khôi phục cả hai marker 66%/33%, xóa HP floor cũ và tạm vô hiệu threshold. Cấp i-frame riêng `sentinel_entry`, kết thúc đúng lúc hết pha, không xóa i-frame của nguồn khác. Tick bleed bị chặn trong pha chuyển dạng. Khi chuyển checkpoint/respawn, pha chuyển dạng và token i-frame được cleanup.
- HP/stamina chưa hồi tức thì khi nhấn R. Mỗi **0,015 giây game** cộng **1% max HP và 1% max stamina**, tối đa chỉ số đầy. 100 tick trong 1,50 giây. Giữ phần lẻ HP để max HP khác 100 không bị mất lượng hồi do làm tròn; chốt đầy khi kết thúc pha. Không hồi sinh HP đã bằng 0. Không tự refill flask hoặc thêm/xóa buff/debuff trong lượt này.
- Sau pha chuyển dạng mới bắt đầu rút **2% max HP/giây game**. Pause dừng, global slow motion/hit-stop làm chậm cả hồi phục/chuyển dạng/rút HP; không dùng delta riêng của actor được miễn slow motion.
- Rút HP và chi phí HP đi thẳng qua đường tự tiêu hao, không qua `apply_damage`: không dùng marker, không áp debuff, bật lùi, stun, camera stagger hoặc i-frame nhận đòn. Chỉ HP tự tiêu hao có sàn 1; damage enemy vẫn có thể giết Sentinel sau pha i-frame.
- Trong Sentinel, threshold không hoạt động và DamageComponent từ chối phản ứng stagger, kể cả phản ứng thiếu stamina. Chi phí/giảm damage guard hiện có vẫn giữ. Bình hồi phục bị chặn trong dạng theo luật đã duyệt.

## Thoát Sentinel và mốc nằm trên HP hiện tại

Thoát không tự kích hoạt mốc hoặc hồi HP; chỉ bật lại marker còn sẵn. Đánh dấu những marker đã nằm bằng/trên HP để nhận đòn trực tiếp kế tiếp kích hoạt từng marker theo thứ tự 66% rồi 33%. Mỗi đòn chỉ tiêu một marker và gọi random debuff Bleed/Fracture như luồng cũ. Tick bleed vẫn bỏ qua threshold; đang Bleed không được miễn threshold khi nhận đòn trực tiếp.

Ví dụ thoát ở 20/100 HP: chưa stagger; đòn hợp lệ mới tiêu mốc 66%, giữ HP ở 20 cho đòn được marker bảo vệ, bật lùi/stun/i-frame và áp debuff. Đòn hợp lệ kế tiếp sau khi hết i-frame tiêu mốc 33% tương tự. Không kéo HP ngược lên 66 hoặc 33. Sau khi hết cả hai marker, damage vẫn có thể giết. HP floor tạm thời cũng không bao giờ làm HP tăng ngược nếu trước đó bị tự tiêu hao xuống thấp hơn floor.

Nếu thoát ở 50 HP: mốc 66% đợi đòn mới như trên; mốc 33% vẫn chặn tại 33 khi một đòn sau thực sự kéo HP xuống chạm/vượt mốc đó. Nếu hồi HP lên lại trên một marker đang chờ, marker áp dụng quy tắc vượt mốc thông thường. Đường bypass threshold của exhausted Guard vẫn được giữ.

## Vị trí chỉnh

Mở `res://scenes/adel/playable_adel.tscn`, chọn node gốc **PlayableAdel → Inspector → Dark Sentinel**:

- **Sentinel Entry Duration = 1.5**: đồng thời thời gian bất động và i-frame chuyển dạng.
- **Sentinel Recovery Tick Interval = 0.015**: nhịp hồi theo giây game.
- **Sentinel Recovery Percent = 1.0**: phần trăm max HP/max stamina mỗi tick.
- **Sentinel Hp Drain Percent = 2.0**: phần trăm max HP rút mỗi giây game sau khi chuyển dạng.

Mặc định ở đầu `res://scenes/adel/playable_adel.gd`. Khi tự đổi thời gian/nhịp/% hồi, lưu ý module vẫn chốt đầy HP và stamina ở cuối pha chuyển dạng. Các mốc 66%/33% vẫn ở `STAGGER_THRESHOLD_FRACS` trong `res://scenes/UI/stats_component.gd`; khoảng bật lùi, stun, i-frame stagger thường giữ tuning hiện có.

## Trách nhiệm code và API chi phí HP

- `dark_sentinel_state.gd` sở hữu pha entry, đồng hồ game, phần lẻ hồi/rút và chờ thoát; HUD chỉ trình bày.
- `adel_state_machine.gd` thêm `SENTINEL_ENTRY` dưới ROOT. Không thay số enum cũ. Player coordinator chặn input/hành động, cleanup trạng thái trước và nối HUD.
- `StatsComponent.suspend_stagger_thresholds()` khôi phục rồi tắt marker; `resume_stagger_thresholds()` bật lại và đánh dấu các marker dưới HP khi thoát. `apply_damage` tiêu từng marker và sinh debuff.
- `Player.vitals.spend_sentinel_hp(amount)` là API dùng cho các skill Sentinel sẽ triển khai. Trả false nếu chưa ở dạng, đang entry/chờ thoát, giá trị âm, chết hoặc không đủ HP để còn tối thiểu 1. Khi thành công chỉ trừ đúng HP, cập nhật HUD và kiểm tra sàn 1 để chờ/kết thúc dạng ở điểm an toàn. Chi phí tới 1 khi giữa đòn không ngắt đòn hiện tại và không nhận thêm combo/skill mới.
- `DamageComponent.cancel_hit_reaction()` hủy callbacks stagger cũ bằng generation, chỉ nhả nguồn immunity stagger; entry dùng token riêng. Timer cũ không được phép kéo nhân vật ra khỏi entry hoặc tắt entry i-frame.

Chưa triển khai bộ vũ khí/animation Sentinel, Q xích, E, skill 1–4, con số chi phí từng skill, Sharpness/Toughness, xóa debuff cơ bản khi vào dạng hoặc tích ulti từ combat. Saber Q hiện vẫn là skill Saber cũ. API chi phí đã được kiểm thử nhưng không tuyên bố các skill Sentinel chưa tồn tại đã gây/trừ HP trong gameplay.

## Kiểm chứng

Scene mới `res://tests/adel/sentinel_entry_validation.tscn` chạy trên Player/HUD thật trong Godot 4.7, dùng save riêng `CodexSentinelEntry20261016`. Kiểm tra hồi từng tick, max HP/stamina khác 100, 30/60/120 tick, i-frame nhận đòn, khóa hành động, cleanup Q/dash, nguồn immunity độc lập, chi phí HP, deferred markers/debuff, đòn Player thực tế sau thoát, pause/slow motion, bleed, checkpoint và chống hồi sinh khi HP=0.

Các suite cũ liên quan drain/debug/refactor/Q đã cập nhật fixture để hoàn tất entry trước khi kiểm tra active form; không bỏ qua entry trong code production. Kết quả thực chạy cuối cùng được ghi trong gói `outputs/sentinel-entry-20261016`.
