# Kế hoạch nâng cấp camera — Soujourn: Echoes of the Soul

Ngày: 15/10/2026. Trạng thái: nghiên cứu và đề xuất, CHƯA triển khai. Đã đọc code/scene thực tế; không chạy Godot trong lượt lập kế hoạch này. Không sửa gameplay, animation, hitbox hoặc thông số người dùng đã chỉnh.

## 1. Hướng thiết kế

Camera phục vụ ba việc theo thứ tự: đọc được không gian và nguy hiểm; theo chuyển động có thể dự đoán; nhấn mạnh các khoảnh khắc đáng nhớ. Với combat vũ khí nặng, camera nên ổn định trong lúc cam kết ra đòn, phản hồi ngắn ở thời điểm tiếp xúc, rồi trở lại bình thường. “Mượt” không đồng nghĩa kéo theo thật chậm.

Yêu cầu 80% tham khảo / 20% suy luận được hiểu là nghiên cứu dẫn đường, sau đó điều chỉnh cho Soujourn. Đây không phải tỷ lệ có thể đo khoa học. Nguyên lý tham khảo được dẫn nguồn; mọi con số thử dưới đây là đề xuất riêng, chưa qua playtest và không phải cấu hình của game nổi tiếng.

## 2. Hiện trạng đã đối chiếu

- `scenes/adel/playable_adel.tscn` dùng `scenes/camera_2d.gd`. Camera có zoom 1.05, offset Y -234.71; script thêm mốc theo Y -30. Khi chỉnh khung phải xét đồng thời hai phần này.
- Script đã có smoothing X/Y, nhìn trước theo hướng quay mặt 120 world px và vertical deadzone 60 world px. Chưa thấy vùng chết ngang, cơ chế ưu tiên phòng hay phản hồi combat trong script này.
- Trên mặt đất, `_target_y` được làm mượt rồi `global_position.y` được làm mượt thêm. Đây là hai tầng lọc nối tiếp, có thể tạo cảm giác bám trễ; cần so sánh khi chơi, chưa kết luận là lỗi runtime.
- Lookahead đổi theo facing, không xét việc di chuyển đủ lâu; xoay người để đánh có thể đổi hướng nhìn ngay cả khi không đi xa.
- `scenes/Mechanic/camera_2d.gd` là một script camera khác; không phải script gắn cho PlayableAdel hiện tại. Giữ nguyên prototype.
- `scenes/Mechanic/camera_zoom_trigger.gd` được dùng trong `scenes/Map 1/main.tscn`. Nó tween zoom và position; `scenes/Map 1/main.gd` cũng đổi zoom cho intro/QTE. Không tự áp kiến trúc mới lên toàn bộ legacy.
- Campfire đổi sang camera riêng, zoom 3.0, rồi trả quyền cho camera trước. Cần giữ nguyên trình tự fade/UI/khóa input hiện có.
- Đã có rung bằng screen-space shader tại `scenes/effect/screen_effects.gd` và `screen_shake.gdshader`, được HUD gọi khi stagger/uống bình nếu current scene có node `ScreenEffects`. HUD còn có rung riêng của bình. `spine_enemy_test.tscn` hiện không khai báo `ScreenEffects`; vì thế không được coi hiệu ứng này đang hoạt động trong mọi scene.
- Shake shader hiện dịch mẫu ảnh theo UV bằng sin/cos, không phải chuyển camera trong thế giới. Cần chọn một đường phát rung để tránh cộng đôi; kiểm tra thứ tự CanvasLayer để HUD không rung theo world.
- Q trong scene đã được người dùng chỉnh mốc charge 0.7/1.5s và tốc độ lao 2811 px/s, khác mặc định script. Không khôi phục các giá trị này. Camera cần thích ứng vận tốc thực, không dựa vào giá trị cũ.
- Player dùng `CombatTime.actor_delta`; camera hiện nhận delta thế giới trực tiếp. Đây là điểm phải xử lý khi player được miễn slow motion ở recovery Q.

## 3. Cơ sở tham khảo

### Khung nhìn và bám nhân vật

Itay Keren trình bày camera window, smoothing, platform snapping, forward focus và neo theo vùng; mục tiêu là đủ thông tin, chuyển động dự đoán được và thoải mái. Phần Mushroom 11 mô tả hệ thống do chính tác giả làm với đường camera/zoom theo vùng và dự báo chuyển động. [GDC 2015 — Scroll Back](https://media.gdcvault.com/gdc2015/presentations/Keren_Itay_ScrollBack.pdf).

Cinemachine cho phép dead zone, damping từng trục và hard limits trên màn hình. Tài liệu cảnh báo lookahead có thể khuếch đại nhiễu chuyển động; làm mượt dự báo nhiều cũng tăng độ trễ. Lấy nguyên lý này để thiết kế Godot, không đưa phụ thuộc Unity vào dự án. [Position Composer](https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/CinemachinePositionComposer.html).

### Rung và ranh giới

Eiserloh đề xuất trauma giảm theo thời gian, biên độ trauma²/³ và noise mượt, giữ rung tách khỏi camera gốc. [GDC 2016 — Juicing Your Cameras with Math](https://media.gdcvault.com/gdc2016/Presentations/Eiserloh_Squirrel_JuicingYourCameras.pdf).

Giới hạn phòng phải xét cả kích thước vùng nhìn và aspect ratio. Đổi zoom đồng nghĩa đổi diện tích cần chứa; phòng nhỏ cần phương án riêng. [Cinemachine Confiner 2D](https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/CinemachineConfiner2D.html).

Godot có drag margins, smoothing và limits, nhưng offset có thể đẩy view vượt limits. Zoom lớn hơn là phóng gần hơn. `reset_smoothing()` chỉ reset smoothing tích hợp; bộ lọc custom của game phải tự reset trạng thái. [Godot Camera2D](https://docs.godotengine.org/en/stable/classes/class_camera2d.html).

Microsoft khuyến nghị cho tắt các chuyển động phụ như shake/bobbing và có tùy chỉnh camera. [Xbox Accessibility Guideline 117](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/117).

Không có đủ nguồn first-party trong lượt này để khẳng định thuật toán hay thông số camera của Celeste/Dead Cells/Ori. Không gán các giá trị thử của Soujourn cho những game đó.

## 4. Đề xuất riêng cho Soujourn

### A. Follow: êm nhưng không bỏ nhân vật lại

- Theo root vật lý của Player, không theo bone hoặc sprite đang đổi pose.
- Một bộ smoothing chính, damping có tính đến thời gian để phản hồi nhất quán. Chưa chồng thêm built-in smoothing lên custom smoothing.
- Khởi điểm: horizontal deadzone có tổng chiều rộng 6–10% vùng nhìn; vertical window tổng chiều cao 15–25%, sau đó điều chỉnh theo độ cao nhảy thực tế. Các vùng này quanh điểm đặt nhân vật trên màn hình, không mặc định quanh chính giữa.
- Thử half-life X 0.10–0.16s, Y 0.16–0.24s. Half-life nghĩa là sai lệch còn một nửa sau thời gian này nếu mục tiêu đứng yên; không phải chờ cố định rồi mới bám. Sau khoảng bốn half-life còn khoảng 6.25% sai lệch, nên phải có bắt kịp khi di chuyển nhanh.
- Vùng an toàn ngoài: khi player tới gần mép, tăng tốc bám thay vì tiếp tục thả trôi. Ban đầu thử giữ root trong vùng ngang 20–80% màn hình khi không bị giới hạn phòng; kích thước rig/hitbox cũng phải được xét khi kiểm tra.

### B. Lookahead: nhìn theo ý định di chuyển

- Dùng vận tốc ngang có lọc và hướng di chuyển ổn định; không đảo camera chỉ vì quay mặt để đánh.
- Thử đảo hướng nhìn sau 0.10–0.15s đi ngược ổn định. Dùng ngưỡng vận tốc để tránh nhiễu quanh 0; sau này có thể thay bằng ngưỡng khoảng cách backtrack nếu playtest tốt hơn.
- Lookahead tối đa thử 8–12% chiều rộng vùng nhìn. Đứng lại giữ ngắn rồi trở về từ tốn, không giật ngay về tâm.
- Dash/Q tăng khả năng bắt kịp nhưng cap dự báo; không nhân thẳng vận tốc 2811 px/s với thời gian dự báo không giới hạn.

### C. Nhảy/rơi: thấy được điểm đáp

- Nhảy ngắn trên cùng tầng: giữ cao độ camera trong window, giảm nhún dọc.
- Nhảy sang tầng mới: dần chuyển neo theo tầng đáp; không bật vị trí camera ngay khi chạm đất.
- Rơi dài: dịch khung xuống sớm và bám xuống nhanh hơn bám lên để đọc chỗ đáp. Ngưỡng rơi tính từ vận tốc/độ lệch thực; không lấy pose animation làm tín hiệu.
- Nhìn lên/xuống chủ động là tùy chọn giai đoạn sau, cần thống nhất phím vì input hiện đã có combat và UI.

### D. Phản hồi chiến đấu có cấp độ

Các giá trị là biên độ tối đa trên khung tham chiếu 1920×1080; cần quy đổi theo viewport một cách nhất quán, độc lập zoom.

- Attack 1–3 trúng: rung 1–2 px, khoảng 0.08s; không đổi zoom mặc định. Đánh hụt không phát impact shake.
- Attack 4 trúng: rung 3–4 px, khoảng 0.10–0.12s. Có thể thử zoom gần 2% nhưng mặc định thử rung trước.
- Guard thành công: xung ngang nhỏ 1–2 px, không zoom. Knockback gameplay vẫn theo cấu hình hiện có.
- Deflect thành công: rung 4–6 px, khoảng 0.10–0.14s; thử zoom gần 2–3% nếu không cắt mất địch/đường thoát.
- Q trúng: tap 2–3 px, charge một cấp 3–4 px, full charge 4–6 px. Đồng thời trúng nhiều mục tiêu chỉ phát một accent chính mỗi swing; clamp mức cộng dồn.
- Stagger: xung theo hướng đòn đánh, khoảng 4–6 px và 0.12–0.16s; ưu tiên thấy player hồi phục và nguy hiểm xung quanh, không zoom sát mặc định.
- Chỉ rung tịnh tiến ở bản đầu; rotation mặc định 0 là lựa chọn riêng cho việc đọc platform. Không thay timing hit-stop/slow motion đã duyệt khi làm camera.

### E. Zoom: phục vụ tình huống, tránh phập phồng

- Giữ baseline 1.05 trước để so sánh công bằng. Zoom tính bằng hệ số trên baseline/zoom vùng, không hard-code tất cả sự kiện về 1.0.
- Không zoom theo từng nhịp combo hay việc chỉ giữ defense.
- Deflect/đòn nổi bật có thể thử gần thêm 2–3%; đi vào khoảng 0.08–0.12s, trả về khoảng 0.20–0.30s, hạn chế lặp bằng cooldown thử 0.5s.
- Q lao dài có thể thử zoom xa 5–8%, blend khoảng 0.20–0.35s, bắt đầu từ giai đoạn charge/release có báo trước. Với tốc độ Q hiện tại, lao 180–360px chỉ kéo dài khoảng 0.064–0.128s nếu không va chạm: bắt đầu zoom lúc lao có thể quá muộn. Tap mặc định không cần zoom xa.
- Không coi zoom là cách cứu framing kém. Địch nhảy vồ hoặc chiến đấu cạnh hố cần giữ đủ khoảng nhìn; bỏ zoom gần nếu làm mất đe dọa quan trọng. Bản đầu có thể dùng profile combat ổn định thay vì xây ngay hệ thống phát hiện mọi đe dọa.
- Nếu kích hoạt zoom gần sau khi Q lao ra xa, chuyển từ zoom xa về zoom cơ sở trước; không giật từ xa sang gần trong vài frame.
- Zoom vùng khám phá/boss là bước sau khi có bố cục phòng rõ. Không cần sinh asset map để thử các nguyên lý camera.

### F. Quyền điều khiển, thời gian và giới hạn

- Một nơi tổng hợp kết quả camera: framing → follow → zoom → shake → kiểm tra giới hạn cuối. Các action gửi sự kiện/mức phản hồi, không tự tween transform camera.
- Trọng số/ưu tiên: campfire hoặc cinematic có quyền riêng; gameplay camera chỉ điều khiển khi được trả quyền. Trong gameplay, vùng/phòng định khung nền, combat thêm hiệu ứng có giới hạn.
- Bản đầu dùng bounds chữ nhật và vùng ưu tiên ổn định; chưa cần polygon confiner phức tạp. Không để hai zone giành camera khi player đứng sát mép chung.
- Clamp phải xét vùng nhìn sau zoom, offset và rung; phòng quá nhỏ dùng zoom hợp lệ hoặc bổ sung vùng nền có chủ đích. Không thể vừa giữ toàn bộ viewport trong một phòng nhỏ hơn viewport vừa giữ nguyên zoom.
- Follow dùng thời gian phù hợp actor để không bám chậm hơn player được miễn world slow motion; hit-stop giữ follow nền ổn định. Shake/zoom accent dùng thời gian thực không tính lúc pause để không bị kéo dài bất ngờ. Camera không tự ghi `Engine.time_scale`.
- Respawn/load/teleport reset cả trạng thái bộ lọc custom, lookahead, zoom và rung; campfire kết thúc blend hoặc snap theo fade đã có. Hủy yêu cầu cũ khi scene/player rời cây.
- World shake phải độc lập HUD. Giữ rung bình HUD là hiệu ứng riêng có chủ đích; không phát hai lần world shake từ cùng stagger. Không xóa prototype hay shader legacy.
- Có Shake Strength 0–100%, Dynamic Zoom bật/tắt và Reduced Camera Motion. Tắt các accent không thay đổi hitbox, sát thương, input, tầm nhìn cần thiết hoặc thời điểm guard/deflect.

## 5. Thứ tự triển khai đề nghị

1. **Nền follow/framing:** đo khung hiện tại, deadzone, lookahead đổi hướng, xử lý Y, bắt kịp dash/Q, reset camera. Có debug overlay hiển thị vùng chết/vùng an toàn và giá trị zoom. Chơi so sánh với camera cũ.
2. **Room bounds và chuyển quyền:** bounds zoom-aware, chuyển vùng, campfire/respawn/load. Giữ các intro prototype cũ hoạt động riêng; chỉ kết nối khi có yêu cầu rõ.
3. **Rung combat:** event tập trung, cấp độ, chống cộng đôi với ScreenEffects, không rung HUD; bật/tắt so sánh.
4. **Zoom chọn lọc và tinh chỉnh:** thử từng loại sự kiện, giữ những hiệu ứng giúp đọc gameplay và cảm giác lực; bỏ nếu làm mất thông tin. Thêm tùy chọn giảm chuyển động.

Đề xuất bắt đầu mục 1 và 2 trước. Sau khi người dùng duyệt cảm giác bám mới, triển khai mục 3 và 4; tránh thay cùng lúc đến mức không biết yếu tố nào gây khó chịu.

## 6. Kiểm chứng khi được lệnh triển khai

- Test logic damping/zone/reset bằng kiểm tra tự động thích hợp; dùng scene test có nền/phòng/platform đơn giản, không cần asset mới.
- Chạy Godot có render ở 30/60/120 FPS, các kích thước cửa sổ và aspect ratio thực được hỗ trợ. Kiểm tra đồng bộ physics/render, không chỉ headless.
- Đi/dừng/đảo hướng, quay mặt đánh tại chỗ; nhảy ngắn, đổi tầng, rơi dài, đáp sát hố; dash/Q các cấp, va tường/địch, lao ngược chiều.
- Hit-stop, deflect slow motion, Q world-slow/player-normal, liên tiếp nhiều hit/stagger, pause giữa hiệu ứng.
- Đi sát bounds, zoom tại mép phòng, chuyển zone liên tục, phòng nhỏ; không lộ vùng rỗng ngoài artwork đã thiết kế.
- Campfire vào/ra spam F, fade/UI, respawn/Continue/đổi scene: camera đúng chủ, hết offset/zoom/rung tồn dư; HUD/cursor theo luật hiện có.
- Quan sát: player/rig ở vùng đọc được, đường đáp và địch chính đủ thời gian xuất hiện, không giật khi xoay mặt, không phập phồng khi combo. Hiệu ứng trả về baseline và không tăng vô hạn.
- Quay các đoạn A/B cùng input để người dùng đánh giá “mượt, dứt khoát, có nhịp điệu”. Chỉ báo runtime đã test sau khi thực sự chạy; không thể chứng minh chất lượng cảm giác chỉ bằng công thức hoặc parse thành công.
