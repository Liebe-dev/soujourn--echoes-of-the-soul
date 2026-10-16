# Defense, Guard, Deflect, Stagger Threshold và Stamina

Cập nhật: 16/10/2026. Báo cáo hiện hành; [vị trí và cách chỉnh thông số](huong_dan_tuy_chinh.md) được quản lý trong một file chung.

## 1. Trạng thái và đường nhận đòn

Defense là tư thế giữ chuột phải; Guard/Deflect là kết quả khi nhận đòn hợp lệ trong tư thế đó. Enemy gọi Player nhận damage với vị trí nguồn đánh; `DefenseComponent` quyết định kết quả, `StatsComponent` xử lý HP/stamina/threshold/debuff, `DamageComponent` sở hữu phản ứng và i-frame. HFSM của Player điều phối pose và chuyển trạng thái.

Guard/Deflect áp dụng cho mọi đòn hiện có của SpineEnemy, không còn chỉ nhánh quyết định đầu tiên. Tư thế cần đúng hướng nguồn đánh theo kiểm tra của defense; không phải miễn damage toàn hướng. Damage thật, hit-stop và kết quả đỡ được xử lý ở cùng cửa nhận đòn, tránh hitbox tự quyết định riêng.

Guard hiện nhân damage đầu vào với `1 - guard_damage_reduction` ở cả trường hợp đủ và thiếu stamina; mặc định nhận 50% trước các hệ số khác. Deflect hợp lệ không nhận damage. Đủ stamina không đồng nghĩa Guard chặn 100% HP damage.

## 2. Animation và cửa sổ Deflect

Giữ Defense mà không nhận đòn: giữ `saber_defense`. Trong thời gian startup trước Deflect vẫn Guard được. Từ `deflect_delay` tới hết `deflect_window` tính từ lần nhấn là Deflect; ngoài cửa sổ đó là Guard. Các giá trị script mặc định từng được chốt là 0,1 giây startup + 0,2 giây cửa sổ; scene có thể override, xem hướng dẫn chung.

Chỉ khi nhận đòn mới dùng `saber_guard` hoặc `saber_deflect`; không tự chuyển pose theo đồng hồ khi chưa bị đánh. Deflect thành công giữ pose trong hiệu ứng slow motion toàn game. Hết phản ứng mà còn giữ hợp lệ thì về Defense, nhả thì hồi phục bằng ready frame cuối. Có thể đổi hướng khi Defense.

Attack 1–3, Attack 4 và Jump Land có thời điểm cho phép vào Defense riêng. Jump Air/Fall không được Defense. Giữ xuyên Dash/Skid sẽ vào Defense ngay khi Skid kết thúc, không chờ cooldown dash, nhưng không làm mới tuổi lần nhấn để kiếm cửa sổ Deflect mới. Q ngắt Defense và yêu cầu nhả/nhấn lại trước khi nhận Defense tiếp.

## 3. Stamina và phản ứng thiếu stamina

Model có max stamina, chi phí theo hành động, thời gian chờ và tốc độ hồi. Dash, Guard thành công, Deflect thành công tiêu stamina; chỉ giữ Defense không tự trừ. Attack/Defense/Guard/Deflect và Sentinel Entry chặn hồi, đồng thời giữ lại thời gian chờ; sau đó mới hồi tới max. Vitals tick độc lập HUD.

- **Stamina đủ chi phí:** Dash/Guard/Deflect xử lý bình thường. Guard có bật lùi ngang nhẹ, giữ pose Guard và vẫn có thể đỡ đòn kế tiếp.
- **Còn dương nhưng thiếu chi phí:** tiêu hết phần còn lại. Dash vẫn thực hiện, không phạt thêm. Deflect không mất HP nhưng kích hoạt cùng phản ứng ngang, hai pose và i-frame như stagger; không tiêu marker hoặc random debuff. Guard cũng phản ứng như vậy nhưng nhận damage theo `guard_damage_reduction`, hiện giữ 50% trước các hệ số damage còn lại.
- **Stamina bằng 0:** không bắt đầu Dash hoặc Defense; vì không Defense nên không Guard/Deflect. Phản ứng đỡ đang xảy ra được dọn theo HFSM, không tự cấp thêm cơ hội đỡ miễn phí.
- **Vừa đủ chi phí:** đó là kết quả đủ stamina, không bị xử phạt thiếu chỉ vì số dư sau chi phí bằng 0.

Phản ứng do cạn stamina dùng thông số zoom riêng và nhân thời lượng slow motion riêng; khoảng bật lùi, chuỗi pose, stun và i-frame vẫn dùng cùng cấu hình stagger. Không đồng nhất nó với việc tiêu một stagger threshold.

## 4. Stagger Threshold

Hai marker tại 66% và 33% HP tối đa. Đòn trực tiếp vượt mốc còn hiệu lực chặn HP ở mốc, tiêu một marker, áp random debuff và phát phản ứng. Mỗi đòn xử lý một marker theo thứ tự ngoài cùng; HP lock có đồng hồ riêng. Nếu đang Bleed vẫn có thể kích hoạt threshold từ đòn trực tiếp, giống khi đang Fracture.

Tick Bleed đi qua đường raw HP loss và bỏ qua threshold. Không dùng ngoại lệ 'đang bleeding' để vô hiệu hóa tất cả threshold. Thao tác tự rút/HP cost Sentinel đi qua đường không gây stagger, tạm vô hiệu marker trong dạng.

Khi vào Sentinel, marker được khôi phục và tạm tắt. Sau thoát, nếu HP đã thấp hơn marker thì chỉ ghi trạng thái chờ; chưa bật phản ứng ngay, không nâng HP lên marker. Đòn trực tiếp mới tiêu một marker chờ và random debuff như thường. Hồi marker qua bình máu/checkpoint theo model hiện tại.

## 5. Bật lùi, pose, zoom và i-frame

Stagger đẩy theo X, giữ Y đang rơi nếu có; không hất lên trời. Pose dùng frame 0 của `saber_stagger` trong pha bật lùi, rồi frame 1 ở pha stun. Gần cuối pha bật lùi giảm tốc mạnh trong khoảng cấu hình để dừng; độ dài pha và lúc đổi pose tuân theo thông số hiện hành, không suy ra từ một giá trị cũ trong báo cáo.

Zoom stagger vào nhanh và trả về trước khi phản ứng kết thúc theo `return_lead`. Camera giữ bố cục chân và độ trễ X, không tự đặt thân ở tâm dọc. Stagger HP và thiếu stamina dùng mức zoom khác nhau. Zoom/slow motion Q độc lập hoàn toàn với các thông số này.

I-frame có nguồn sở hữu/token riêng: HIT, DASH, STAGGER, SENTINEL_ENTRY. Timer cũ chỉ giải phóng đúng token của nó; gia hạn sinh token mới. Hết Dash không tắt HIT còn hiệu lực; stagger ngắt dash vẫn giữ STAGGER. Callback knockback/stun cũng có generation, kiểm tra lại sau signal và bị vô hiệu khi restore checkpoint/respawn. Không gọi `get_tree().create_timer()` trên node đã rời cây khi Player chết.

## 6. Hiệu ứng bất lợi hiện có

`StatsComponent` là nơi chứa luật thử nghiệm, không phải hệ thống buff hoàn thiện:

- **Bleeding:** level 1/2 tương ứng mất 3/6 HP mỗi tick 1 giây. Nhận thêm Bleed lấy mức cao hơn, không tự cộng level mỗi lần. Tick không kích hoạt threshold, có thể giết Player nếu không có điều kiện chặn damage phù hợp.
- **Fracture:** cộng level, giới hạn 3. Tăng damage trực tiếp nhận 20% mỗi level. Damage gây ra còn 85%/80%/65% ở level 1/2/3, đã áp dụng khi chạm qua cả SaberHitbox (combo/ba mức Q) và JumpAttackHitbox. Từ level 2, tốc di chuyển ngang còn 72% trên đất/trên không và tốc đánh combo/jump còn 75%. Hình, hitbox và mốc nối đòn/Defense/land dùng nhịp đồng bộ; dùng bình hạ cấp sẽ cập nhật tốc độ trong physics tick tiếp theo mà không khởi động lại đòn. Q giữ timing riêng và chỉ chịu giảm damage. Không thay jump height/gravity/dash, nhịp Defense/Ready, thời gian input buffer hoặc khoảng ngưng rơi riêng. Vị trí, đơn vị và cách chỉnh các hằng `FRACTURE_*` nằm trong [hướng dẫn chung, mục Fracture](huong_dan_tuy_chinh.md#fracture).
- Random threshold hiện chọn Bleed I hoặc thêm Fracture với xác suất 50/50. Icon lấy từ `res://asset/UI/Menu screen/Bleed.png` và `res://asset/UI/Menu screen/fracture.png`.
- Bình máu hiện hồi theo `flask_heal_per_use`, xóa Bleed, giảm một level Fracture và hồi một marker theo điều kiện model; không ghi là xóa toàn bộ Fracture mọi cấp. Dùng bình bị cấm trong Sentinel. Poisoning và debuff cao cấp chưa có gameplay hoàn chỉnh.

## 7. Source và kiểm tra liên quan

Source chính: `res://scenes/adel/components/defense_component.gd`, `damage_component.gd`, `player_vitals.gd`, `stagger_impact.gd`, `deflect_slow_motion.gd`, `res://scenes/UI/stats_component.gd` và coordinator `playable_adel.gd`.

Các scene test: `fracture_validation`, `guard_stamina_validation`, `stagger_impact_validation`, `exhaustion_zoom_validation`, `combat_feel_validation`, `jump_attack_defense_validation`, `player_refactor_validation`, `sentinel_entry_validation` dưới `res://tests/adel/`; camera framing dưới `res://tests/camera/`. Những lần triển khai trước có log Godot thật với save thử riêng. Không chạy test ghi save trong thư mục user thật.

Lượt hoàn thiện Fracture 16/10/2026 đã chạy Godot 4.7 trên bản sao project có custom user directory riêng: `fracture_validation` đạt **80 assertions headless + 80 có render**. Phạm vi gồm bốn cấp, damage nhận, combo/finisher/jump/Q, chống hit lặp, vận tốc đất/không, đồng bộ hình/hitbox, bình hạ cấp giữa đòn, giữ hệ số playback khác, jump hang/land và Defense sau đòn bị chậm. Đây là kiểm chứng hành vi hiện hành, chưa nghiệm thu balance hoặc debuff nâng cao.

Hồi quy headless cùng lượt: `combat_feel_validation` **106**, `adel_hfsm_validation` **32**, `jump_attack_defense_validation` **41**, `jump_attack_damage_validation` **42** assertions, tất cả đạt. Tổng lượt này **381 assertions** (gồm 80 chạy lại có render, không phải 381 kịch bản độc lập). Log còn cảnh báo rig/UID có sẵn; bản chạy render không ghi được shader cache trong user directory do giới hạn filesystem, nhưng hoàn tất toàn bộ assertions. Không có script error trong các suite trên. Không sửa override scene để làm test đạt và không ghi/xóa save chơi thật.
