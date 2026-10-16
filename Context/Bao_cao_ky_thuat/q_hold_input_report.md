# Giữ Q chờ hành động và Q ngắt defense

Ngày: 16/10/2026. Phạm vi: input của Saber Q hiện tại; không thêm skill Sentinel, stamina cost, asset, audio hoặc sửa animation.

## Luật đã thực hiện

- Nhấn và giữ Q trong DASH_ACTIVE/DASH_SKID tạo một yêu cầu chờ. Q bắt đầu ngay khi kết thúc DASH/SKID nếu vẫn giữ Q và đủ điều kiện sử dụng skill; không chờ cooldown. Nhấn Q mới trong cooldown cũng bắt đầu ngay. Cooldown scene vẫn giữ nguyên giá trị người dùng đã lưu, hiện 0,06 giây, và chỉ chặn dash tiếp theo.
- Nhấn giữ Q trong `saber_attack_1/2/3/4` đợi hết animation đòn hiện tại. Không cancel sớm ở mốc cho phép di chuyển 0,40/0,55 giây. Đòn combo kế tiếp đã buffer bị xóa; click attack mới không lấy lại ưu tiên khi Q đang chờ. Thả Q hủy yêu cầu, không tự phục hồi đòn combo cũ.
- Thời gian tụ lực tính từ **lúc thực sự bắt đầu Q**, không tính thời gian giữ trong dash/cooldown/attack. Ví dụ giữ Q trong khi chờ 0,6 giây không được tính sẵn 0,6 giây charge.
- Thả Q trước khi bắt đầu: hủy yêu cầu, không phát một đòn tap muộn. Nếu Q đã bắt đầu thì release tiếp tục dùng luật tap/charge cũ. Sau auto-release full charge, giữ nguyên Q không tự lặp skill thứ hai.
- Menu/pause/focus cleanup, rest/pickup, stagger và khóa điều khiển hủy yêu cầu chờ. Khi Sentinel đánh dấu chờ thoát ở 1 HP, yêu cầu Q cũng bị xóa, nhưng Q đã chạy vẫn được hoàn thành theo luật cũ.

## Q và defense

- Khi Q được phép bắt đầu, nó ngắt defense dù nút chuột phải vẫn giữ. Áp dụng cả DEFENSE_HOLD, GUARD_REACTION và DEFLECT_REACTION. Dọn guard push và hủy slow motion riêng của deflect trước khi vào Q, tránh callback deflect thay animation Q.
- Các hit-stop độc lập đang chạy không bị xóa thêm ngoài cleanup sẵn có. Q không tự thêm i-frame cho quá trình charge.
- Nếu chuột phải vẫn giữ lúc Q bắt đầu, đặt cờ yêu cầu nhả defense. Không tự vào defense sau khi Q kết thúc và không nhận lại lần giữ cũ. Nhả rồi nhấn mới có thể nhận defense tiếp theo luật trạng thái hiện tại.
- Nếu người chơi đã nhả defense trước khi Q bắt đầu, không ép thêm một lần nhả giả. Release bị UI xử lý mất sự kiện vẫn được phát hiện qua trạng thái nút trong physics.
- Q đang chờ có ưu tiên hơn yêu cầu defense đang chờ. Nếu defense đang hoạt động, Q được phép bắt đầu ngay và ngắt defense; dash cooldown không trì hoãn thao tác này.

Dash cooldown chỉ dùng để hạn chế dash liên tục. Q và defense chờ trong dash được thực thi ngay khi hết skid (Q ưu tiên nếu đã được chọn); attack, nhảy, di chuyển và quyền bắt đầu hành động chung cũng không bị cooldown này chặn. Những điều kiện riêng như stamina, mặt đất, stagger hoặc khóa menu vẫn có hiệu lực.

## Điều kiện sử dụng giữ nguyên

Saber Q vẫn dùng các mốc charge, damage, khoảng lunge, hit-stop, stun, slow motion và i-frame hiện có. Không thêm chi phí stamina. `Allow Airborne` mặc định false vẫn có hiệu lực: yêu cầu giữ Q sau air dash chỉ thực thi khi đã đủ điều kiện trên mặt đất. Không mở thêm buffer Q cho jump_attack fall/air/land, rest hoặc pickup trong lần này; yêu cầu chỉ áp dụng đòn thường 1–4.

Trong Q vẫn giữ khóa hành động vốn có: nhả rồi nhấn defense không biến defense thành một cách cancel Q giữa skill. Không đổi các mốc attack → defense 0,6/0,75 giây đã thiết lập.

## Vị trí code và tuning

- `res://scenes/adel/playable_adel.gd`: `request_weapon_skill`, `release_weapon_skill`, `_try_consume_weapon_skill`, `cancel_weapon_skill_request`; cờ `_skill_requested` và `_guard_requires_release`. Dùng trạng thái giữ thật, không thêm Timer buffer có timeout.
- `res://scenes/adel/components/adel_state_machine.gd`: chuyển input Q sang các phương thức trên.
- `res://scenes/adel/components/saber_weapon_skill.gd`: `begin(interrupt_defense)` kiểm tra điều kiện và animation trước khi thay defense.
- `res://scenes/adel/components/dark_sentinel_state.gd`: bỏ yêu cầu Q khi vào pending exit.
- Cooldown dash: `playable_adel.tscn → DodgeCooldown → Wait Time`.
- Charge Q: chọn `SaberSkill` trong playable_adel.tscn, nhóm **Charge**. Các mốc charge tính từ khi skill bắt đầu; không có thông số thời gian tích sẵn trong hàng chờ.

## Kiểm chứng

`res://tests/adel/q_hold_validation.tscn`: input thật cho dash/cooldown, cả bốn đòn thường, buffer combo, hủy do release/cleanup/stagger/Sentinel, ghi nhận charge từ zero, Q ngắt defense/guard/deflect, khóa nhả lại defense, zero stamina và không auto-repeat. Có kiểm tra Godot headless và có render. Cooldown fixture dài hơn để chứng minh Q bắt đầu ngay trong khi cooldown vẫn còn; không sửa scene chơi thật.

Hồi quy chạy thêm Saber Q, combat feel, dash → defense, Sentinel drain và HFSM. Assertion cũ “Q không ngắt Defense” trong Saber suite đã được đổi theo luật vừa duyệt. Kết quả cuối và hash file nằm trong `Q-hold-input-verification.json` ở workspace. Không dùng kết quả 900 check của lượt refactor trước để tuyên bố kiểm chứng lượt thay đổi này.

Giữ nguyên scene, tuning, camera, rig, asset, audio, save và prototype/legacy. Không commit hoặc push.

Kết quả cuối: **449 check đạt, 0 thất bại** qua 7 lượt chạy Godot 4.7; log cuối không có SCRIPT ERROR/ERROR. Cảnh báo Bone2D/UID có sẵn của asset/copy vẫn còn, không sửa rig trong lượt này.

## Đính chính cooldown và kiểm tra mới

Theo yêu cầu sau cùng, bỏ hoàn toàn dash cooldown khỏi điều kiện Q. Khi kết thúc skid, module dash thực thi ngay yêu cầu Q hoặc defense đang chờ; cooldown chỉ còn được đọc trong điều kiện bắt đầu một dash mới. Thời gian tụ lực Q vẫn tính từ lúc vào skill. Không đổi thời lượng cooldown, skid hoặc chi phí stamina.

Kiểm tra lần đính chính: 52 check Q headless + 52 có render; 24 dash/defense, 46 Player refactor, 106 combat feel. Tổng **280 check đạt, 0 thất bại**; không có SCRIPT ERROR/ERROR trong các log cuối. Có kiểm tra Q, đòn thường và nhảy thực hiện được trong cooldown dài của fixture, đồng thời dash mới vẫn bị chặn và không tiêu stamina khi bị từ chối. Các kết quả 449 check ở phần trước thuộc phiên bản trước đính chính.
