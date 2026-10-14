Update code tuần 2

Các nội dung chỉnh sửa và cải tiến hệ thống

Trong quá trình phát triển, nhóm tiến hành refactor hệ thống quản lý trạng thái nhân vật nhằm giảm sự phụ thuộc giữa logic gameplay và giao diện người dùng, đồng thời cải thiện khả năng bảo trì và mở rộng mã nguồn. Trọng tâm của quá trình cải tiến là tách phần quản lý trạng thái và chỉ số nhân vật khỏi tệp ui.gd, vốn trước đó đảm nhiệm đồng thời cả xử lý gameplay và cập nhật giao diện.

1\. Tách StatsComponent khỏi ui.gd

Trước khi cải tiến, ui.gd chứa nhiều nhóm logic khác nhau, bao gồm quản lý HP, Stamina, Soul Flask, Bleeding, Fracture, Stagger, Buff/Debuff và các hệ thống cập nhật giao diện. Điều này làm cho một tệp phải đảm nhiệm nhiều trách nhiệm, gây khó khăn cho việc kiểm soát và mở rộng mã nguồn.

Nhóm đã xây dựng StatsComponent dưới dạng một thành phần độc lập để quản lý các trạng thái và logic liên quan đến chỉ số nhân vật.

Các trạng thái được chuyển sang StatsComponent gồm:

•	HP và HP tối đa.

•	Stamina và Stamina tối đa.

•	Số lượng Soul Flask và giới hạn Flask.

•	Lượng HP hồi phục từ Flask.

•	Cấp độ Bleeding.

•	Cấp độ Fracture.

•	Các Buff đang hoạt động.

•	Trạng thái Stagger và các ngưỡng Stagger.

•	Trạng thái khóa Stagger.

•	Bộ đếm thời gian xử lý Bleeding.

•	Các hệ số ảnh hưởng đến sát thương, tốc độ di chuyển và tốc độ tấn công.

Trong ui.gd, đối tượng \_stats được sử dụng để tham chiếu đến StatsComponent, qua đó tách biệt dữ liệu gameplay khỏi phần giao diện.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

2\. Áp dụng mô hình Facade để duy trì tương thích với hệ thống cũ

Một vấn đề được xem xét trong quá trình refactor là việc nhiều hệ thống khác trong game đang truy cập các thuộc tính và phương thức thông qua ui.gd. Nếu chuyển toàn bộ logic sang StatsComponent và thay đổi trực tiếp API hiện có, quá trình refactor có thể gây ảnh hưởng đến nhiều hệ thống khác.

Do đó, nhóm sử dụng cơ chế Facade trong ui.gd.

Các thuộc tính như:

hp

max\_hp

stamina

max\_stamina

flask\_charges

max\_flask\_charges

flask\_heal\_per\_use

bleeding\_level

fracture\_level

active\_buffs

stagger\_tiers\_ready

stagger\_lock\_hp

stagger\_lock\_timer

vẫn được duy trì trong ui.gd dưới dạng property trung gian, nhưng dữ liệu thực tế được lưu trữ trong StatsComponent.

Ví dụ:

var hp: int:

&#x20;   get:

&#x20;       return \_stats.hp

&#x20;   set(value):

&#x20;       \_stats.hp = value

Nhờ đó, các hệ thống hiện có vẫn có thể sử dụng giao diện lập trình cũ mà không cần thay đổi hàng loạt mã nguồn.

Các hệ thống như playable\_adel.gd, player\_progress.gd, safe\_zone.gd và save\_manager.gd vẫn có thể truy cập ui.gd thông qua API hiện tại.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

3\. Phân tách logic gameplay và logic giao diện

Sau khi refactor, trách nhiệm giữa hai thành phần được phân chia rõ ràng hơn.

StatsComponent đảm nhiệm

•	Quản lý trạng thái nhân vật.

•	Tính toán và thay đổi HP, Stamina và Flask.

•	Quản lý Bleeding, Fracture và Stagger.

•	Quản lý Buff/Debuff.

•	Tính toán các hệ số gameplay.

•	Xử lý các thay đổi trạng thái theo thời gian.

ui.gd đảm nhiệm

•	Cập nhật thanh HP, Stamina và Flask.

•	Cập nhật biểu tượng trạng thái.

•	Hiển thị Stagger marker.

•	Xử lý animation và Tween.

•	Hiển thị hiệu ứng nhận sát thương/hồi máu.

•	Phát các signal cần thiết.

•	Điều phối các thao tác liên quan đến gameplay và UI.

•	Xử lý các side effect như respawn.

Cách phân chia này giúp StatsComponent không phụ thuộc vào node giao diện, animation hoặc SaveManager, trong khi ui.gd đóng vai trò trung gian giữa gameplay state và hệ thống hiển thị.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

4\. Tái cấu trúc hệ thống xử lý sát thương và Stagger

Hệ thống xử lý sát thương được tái cấu trúc để tách phần tính toán trạng thái khỏi phần điều phối và hiển thị.

StatsComponent chịu trách nhiệm xác định kết quả của việc vượt qua các ngưỡng Stagger thông qua:

resolve\_stagger\_crossing(...)

Trong khi đó, ui.gd tiếp nhận kết quả và thực hiện các thao tác liên quan đến giao diện, signal và các side effect.

Thứ tự xử lý quan trọng được giữ nguyên:

Tính toán Stagger

&#x20;       ↓

Cập nhật Stagger marker

&#x20;       ↓

Xử lý Debuff

&#x20;       ↓

Phát signal

&#x20;       ↓

Cập nhật HP

&#x20;       ↓

Cập nhật giao diện HP

&#x20;       ↓

Hiệu ứng nhận sát thương

&#x20;       ↓

Combat state / Respawn

Đặc biệt, quá trình kiểm thử xác nhận signal stagger\_triggered vẫn được phát trước khi ghi giá trị HP mới, nhằm bảo đảm hành vi của hệ thống trước và sau refactor không bị thay đổi.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

5\. Tái cấu trúc cơ chế Bleeding và cập nhật trạng thái theo thời gian

Cơ chế Bleeding trước đây được xử lý trực tiếp trong ui.gd. Sau khi refactor, bộ đếm thời gian và logic thay đổi trạng thái được chuyển sang StatsComponent.

Trong mỗi frame, ui.gd gọi:

var tick\_result := \_stats.tick(delta)

StatsComponent xử lý việc cập nhật trạng thái và trả về kết quả cho ui.gd. ui.gd sau đó thực hiện các thao tác liên quan đến hiển thị, hiệu ứng và respawn.

Cách tổ chức này giúp đảm bảo chỉ tồn tại một nguồn xử lý Bleeding, tránh tình trạng nhiều thành phần cùng thay đổi HP hoặc cùng thực hiện một tick.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

6\. Tách xử lý Stamina

Logic phục hồi Stamina cũng được chuyển vào StatsComponent.

ui.gd chỉ quyết định thời điểm cần phục hồi dựa trên trạng thái gameplay, sau đó gọi logic tương ứng trong component và cập nhật giao diện khi giá trị thay đổi.

Điều này giúp phân biệt rõ:

Gameplay calculation

&#x20;       ↓

StatsComponent



UI presentation

&#x20;       ↓

ui.gd

Nhờ đó, việc thay đổi cơ chế phục hồi Stamina trong tương lai có thể thực hiện chủ yếu ở StatsComponent mà không cần sửa phần giao diện.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

7\. Tái cấu trúc hệ thống Soul Flask và hồi phục

Hệ thống Soul Flask được phân tách thành hai lớp xử lý.

StatsComponent chịu trách nhiệm thay đổi trạng thái:

•	Tiêu hao Flask.

•	Hồi HP.

•	Xóa Bleeding/Fracture khi sử dụng Flask.

•	Khôi phục Stagger threshold.

Trong khi đó, ui.gd chịu trách nhiệm:

•	Kiểm tra điều kiện sử dụng.

•	Điều khiển Tween.

•	Animation Flask.

•	Đồng bộ giao diện.

•	Hiển thị hiệu ứng hồi phục.

•	Điều khiển trạng thái combat.

Quá trình sử dụng Flask vì vậy được tổ chức thành:

Kiểm tra điều kiện

&#x20;     ↓

Animation / Tween

&#x20;     ↓

Thay đổi gameplay state

&#x20;     ↓

Đồng bộ UI

&#x20;     ↓

Hiệu ứng hồi phục

Việc kiểm thử cũng xác nhận không xảy ra hiện tượng tiêu hao Flask hoặc hồi HP nhiều lần do quá trình callback của Tween.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

8\. Tái cấu trúc hệ thống Buff/Debuff

Các trạng thái như Bleeding, Fracture và Buff được đưa về quản lý tập trung trong StatsComponent.

Các phương thức liên quan đến:

•	Kiểm tra Debuff.

•	Thêm/xóa Buff.

•	Xóa toàn bộ Debuff.

•	Tính toán hệ số ảnh hưởng của trạng thái.

được chuyển về lớp quản lý trạng thái.

Trong khi đó, ui.gd chỉ thực hiện cập nhật phần hiển thị tương ứng thông qua các phương thức sync\_\*.

Điều này giúp tránh việc logic gameplay phải trực tiếp thao tác với các node giao diện.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

9\. Tổ chức lại hệ thống Signal

Trong quá trình refactor, nhóm tiến hành kiểm tra toàn bộ Signal liên quan đến Stagger và Debuff.

Sau khi đánh giá, các Signal phục vụ giao tiếp với hệ thống bên ngoài được giữ lại trong ui.gd, bao gồm:

stagger\_triggered

stagger\_debuff\_applied

StatsComponent không trực tiếp phát Signal giao diện. Thay vào đó, component trả về kết quả xử lý cho ui.gd, sau đó ui.gd quyết định thời điểm phát Signal.

Cách thiết kế này giúp giảm sự phụ thuộc giữa component quản lý trạng thái và hệ thống giao diện.

Đồng thời, các Signal không còn được sử dụng trong StatsComponent đã được loại bỏ nhằm tránh tồn tại mã nguồn dư thừa.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

10\. Loại bỏ mã nguồn dư thừa sau khi tái cấu trúc

Sau khi hoàn thành việc chuyển đổi, nhóm thực hiện một đợt kiểm tra dependency và caller để xác định những phần mã nguồn không còn được sử dụng.

Các phương thức xử lý sát thương cũ trong StatsComponent như:

apply\_damage()

damage()

được xác nhận không còn caller và không còn phù hợp với kiến trúc mới nên được loại bỏ.

Ngoài ra, các hằng số không còn được sử dụng trong ui.gd cũng được loại bỏ.

Việc cleanup được thực hiện sau khi xác nhận bằng search/caller audit, thay vì xóa trực tiếp trong quá trình refactor. Điều này giúp hạn chế nguy cơ loại bỏ nhầm API vẫn đang được các hệ thống khác sử dụng.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

11\. Kiểm tra tính tương thích với các hệ thống hiện có

Sau khi thay đổi cấu trúc, nhóm kiểm tra các hệ thống có liên quan trực tiếp đến ui.gd, bao gồm:

•	playable\_adel.gd.

•	player\_progress.gd.

•	safe\_zone.gd.

•	save\_manager.gd.

Các phương thức và thuộc tính mà các hệ thống này sử dụng vẫn được duy trì thông qua Facade của ui.gd.

Kết quả kiểm tra cho thấy các integration point vẫn được phân giải đúng và không phát sinh lỗi API do quá trình refactor.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

12\. Kiểm thử và xác nhận sau khi chỉnh sửa

Sau khi hoàn thành refactor, hệ thống được kiểm tra theo nhiều mức:

Kiểm tra mã nguồn

Thực hiện kiểm tra cú pháp đối với StatsComponent và kiểm tra các dependency liên quan.

Kết quả:

EXIT = 0

Kiểm tra scene HUD

Chạy scene:

res://scenes/UI/hud.tscn

ở chế độ headless.

Kết quả:

EXIT = 0

Không phát hiện các lỗi như:

•	Parse Error.

•	Compile Error.

•	Script Error.

•	Invalid call.

•	Invalid property.

•	Identifier not found.

Kiểm tra integration

Các luồng chính được kiểm tra gồm:

•	Damage → Stagger → Debuff → HP.

•	Soul Flask → Heal → Cure Debuff → Restore Stagger.

•	Bleeding → HP loss → UI update → Respawn.

•	Stamina regeneration.

•	Heal to full.

•	Restore Stagger threshold.

•	Clear Debuff.

•	Save/Load và Safe Zone.

Kết quả kiểm tra cuối cùng xác nhận D1 hoàn thành và không phát hiện regression thuộc phạm vi refactor.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

13\. Kết quả đạt được

Sau quá trình cải tiến, kiến trúc quản lý trạng thái nhân vật được tổ chức lại theo hướng:

&#x20;

Kết quả chính của việc cải tiến là phân tách trách nhiệm giữa quản lý trạng thái gameplay và hệ thống giao diện, giảm sự phụ thuộc trực tiếp của logic gameplay vào UI, đồng thời vẫn duy trì API hiện có để hạn chế ảnh hưởng đến các hệ thống đã được xây dựng.

Cấu trúc mới cũng tạo cơ sở thuận lợi cho việc tiếp tục tách các thành phần khác của nhân vật trong những giai đoạn phát triển tiếp theo, đặc biệt là quá trình tái cấu trúc playable\_adel.gd.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_



BÁO CÁO KỸ THUẬT NCKH TUẦN 3

I.	NHỮNG CÔNG VIỆC ĐÃ LÀM ĐƯỢC

1\.	Tái cấu trúc playable\_adel.gd.

Trong tuần 3, nhóm tiếp tục thực hiện tái cấu trúc playable\_adel.gd theo định hướng Component hóa. Phạm vi được chia thành bốn phần chính gồm

\-	LocomotionComponent

\-	CombatComponent

\-	DamageComponent

\-	DashComponent

Nhằm tách các nhóm trách nhiệm gameplay khỏi Player coordinator nhưng vẫn duy trì hành vi hiện có.

1.1. Tách xử lý Locomotion

Nhóm xây dựng: scenes/adel/components/locomotion\_component.gd

Các trách nhiệm liên quan đến locomotion được tách khỏi playable\_adel.gd, bao gồm:

\-	Xử lý chuyển động ngang. 

\-	Xử lý nhảy. 

\-	Xử lý chuyển động theo trục dọc. 

\-	Xác định các trạng thái liên quan đến quá trình nhảy và tiếp đất. 

\-	Phát signal khi nhân vật thực hiện Jump và Land. 

LocomotionComponent không trực tiếp sở hữu CharacterBody2D.velocity. Việc quản lý velocity vẫn thuộc Player để đảm bảo CharacterBody2D tiếp tục là nơi thực hiện chuyển động vật lý thực tế.

Các signal được sử dụng để thông báo kết quả cho playable\_adel.gd, qua đó Player tiếp tục đảm nhiệm vai trò coordinator giữa gameplay logic và animation/FSM.

1.2. Tách xử lý Combat

Nhóm xây dựng:

scenes/adel/components/combat\_component.gd

Các trách nhiệm liên quan đến combat được chuyển sang CombatComponent, bao gồm:

•	Quản lý trạng thái combo. 

•	Xác định combo step. 

•	Xử lý input attack. 

•	Queue đòn đánh tiếp theo trong combo. 

•	Xác định attack action. 

•	Xử lý chuyển tiếp giữa các đòn combo. 

•	Xác định animation tương ứng với đòn đánh. 

•	Xử lý logic liên quan đến Jump Attack. 

playable\_adel.gd tiếp tục đảm nhiệm vai trò coordinator: tiếp nhận kết quả từ CombatComponent, sau đó điều phối animation, movement lock và các trạng thái liên quan của Player.

Mô hình xử lý được tổ chức theo hướng:

Input  CombatComponent  AttackAction / Combat State  playable\_adel.gd  Animation / Player State

Việc tách này giúp giảm lượng combat logic trực tiếp nằm trong playable\_adel.gd mà không thay đổi cách Player giao tiếp với hệ thống animation hiện tại.

1.3. Tách Damage, Stagger và Invulnerability

Nhóm xây dựng: scenes/adel/components/damage\_component.gd

Các logic liên quan đến phản ứng khi nhân vật nhận damage được chuyển sang DamageComponent. playable\_adel.gd vẫn giữ API take\_damage() để tiếp tục đóng vai trò coordinator.

•	Damage Reaction:

Các logic liên quan đến phản ứng khi nhân vật nhận damage được chuyển sang DamageComponent.

•	Stagger:

Các constant liên quan đến Stagger được chuyển sang Component, bao gồm:

\-	STAGGER\_STUN\_SEC

\-	STAGGER\_INVULN\_SEC

\-	STAGGER\_KNOCKBACK

\-	HIT\_INVULN\_SEC

•	Invulnerability:

DamageComponent quản lý is\_invulnerable và các trạng thái liên quan đến damage reaction. Dash vẫn có thể tác động đến trạng thái damage.is\_invulnerable thông qua coordinator để duy trì behavior hiện tại.

•	Knockback:

Logic xử lý Knockback được tách khỏi Player coordinator, nhưng không chuyển velocity vào Component. CharacterBody2D vẫn sở hữu và áp dụng velocity, trong khi DamageComponent chịu trách nhiệm xử lý logic phản ứng Knockback.

•	Giữ HP và Stats ở StatsComponent

HP và các chỉ số gameplay không được chuyển sang DamageComponent. Các dữ liệu này tiếp tục thuộc StatsComponent nhằm duy trì ranh giới trách nhiệm giữa quản lý trạng thái nhân vật và xử lý phản ứng khi nhận damage.

•	Kết quả:

playable\_adel.gd từ 531 dòng còn 501 dòng, các responsibility liên quan đến Damage, Stagger, Invulnerability và Knockback reaction đã được tách thành DamageComponent.

&#x20;

1.4. Tách Dash/Dodge

Nhóm xây dựng: scenes/adel/components/dash\_component.gd

•	Tách Dash State:

Ba state: is\_dodging, able\_to\_dodge, has\_air\_dashed được chuyển khỏi playable\_adel.gd sang DashComponent.

&#x20;

•	Tách điều kiện có thể Dash

Các điều kiện trước đây liên quan đến: wants\_dash, can\_ground\_dash, can\_air\_dash được gom lại thành: can\_dash()

Hàm này chịu trách nhiệm xác định Player có đủ điều kiện thực hiện Dash hay không.

•	Tách xác định hướng Dash

\-	Logic xác định hướng Dash được chuyển vào start\_dash() bao gồm:

\-	Xác định Dash trên không hay dưới đất. 

\-	Xác định hướng Dash. 

\-	Sử dụng hướng đang facing nếu không có hướng input. 

\-	Xác định tốc độ Dash. 

•	Tách Dash Speed Resolution

Các giá trị liên quan đến tốc độ Dash được đưa thành constant thay vì tiếp tục sử dụng magic number. Constant được sử dụng: DASH\_SPEED\_MULTIPLIER với giá trị được giữ tương ứng với implementation trước khi refactor.

•	Tách Dash Cooldown

Logic quản lý cooldown được tách thành: end\_dash(), on\_cooldown\_timeout() trong đó: end\_dash() kết thúc Dash và bắt đầu cooldown. on\_cooldown\_timeout() cho phép Dash trở lại.

•	Tách Air Dash Reset

Logic khôi phục khả năng Air Dash được tách thành: reset\_air\_dash()

•	Giữ Ghost Trail ở Player

Các logic: \_ghost\_trail\_loop(), \_spawn\_ghost\_trail(), \_ghost\_pool chưa được chuyển sang DashComponent.

Đây là chủ ý giới hạn phạm vi, tránh mở rộng refactor sang responsibility của Object Pool và Ghost Trail.

Kết quả:

playable\_adel.gd từ 501 dòng còn 493 dòng. Các responsibility chính được phân tách rõ hơn giữa Player coordinator và DashComponent.

1.5. Kiến trúc playable\_adel.gd sau khi hoàn thành REfactor

Sau khi hoàn thành A15, kiến trúc được tổ chức theo hướng playable\_adel.gd đóng vai trò Player coordinator, trong khi các Component đảm nhiệm từng nhóm gameplay responsibility.

Mô hình tổng quát:

&#x20;

Trong khi đó, playable\_adel.gd tiếp tục giữ các responsibility thuộc Player/Coordinator:

\-	CharacterBody2D

\-	Velocity

\-	Animation

\-	Collision

\-	Tween

\-	Ghost Trail

\-	FSM Coordination

\-	Component Coordination

Cách tổ chức này giúp phân biệt rõ hơn giữa gameplay responsibility của Component và vai trò điều phối của Player.

2\. Kiểm tra và xác nhận sau tái cấu trúc

2.1. Kiểm tra từng Component

Các Component được kiểm tra sau khi tách nhằm xác nhận:

•	Script có thể được load/parse. 

•	Constructor và dependency được truyền đúng. 

•	Các method được gọi đúng từ playable\_adel.gd. 

•	Signal giữa Component và Player vẫn hoạt động. 

•	Các API cần thiết của Player vẫn được duy trì. 

2.2. Kiểm tra integration

Các integration point giữa playable\_adel.gd và các Component được rà soát, bao gồm:

 

Đặc biệt kiểm tra các luồng:

\-	Movement → LocomotionComponent. 

\-	Jump → LocomotionComponent → Player. 

\-	Attack → CombatComponent → Animation. 

\-	Combo Queue → CombatComponent → Next Attack. 

\-	Damage → DamageComponent → Player reaction. 

\-	Stagger → DamageComponent → Animation/State. 

\-	Dash → DashComponent → Player movement. 

\-	Cooldown → DashComponent → Player state. 

2.3. Kiểm tra behavior

Sau khi refactor, nhóm kiểm tra các behavior chính nhằm đảm bảo việc tách Component không làm thay đổi behavior đã có của Player. Các nội dung được kiểm tra gồm:

\-	Movement. 

\-	Jump/Land. 

\-	Combo Attack. 

\-	Attack Queue. 

\-	Jump Attack. 

\-	Damage Reaction. 

\-	Stagger. 

\-	Invulnerability. 

\-	Ground Dash. 

\-	Air Dash. 

\-	Dash Cooldown. 

\-	Air Dash Reset. 

Kết quả kiểm tra trong phạm vi thực hiện cho thấy các luồng chính vẫn hoạt động theo behavior hiện tại sau quá trình tái cấu trúc.

3\. Kết quả đạt được

Kết quả chính của A15 là playable\_adel.gd được tái cấu trúc theo hướng Component + Coordinator, trong đó các nhóm responsibility gameplay được phân tách thành:

\-	LocomotionComponent

\-	CombatComponent

\-	DamageComponent

\-	DashComponent

Trong khi playable\_adel.gd tiếp tục giữ vai trò Player coordinator và sở hữu các thành phần gắn trực tiếp với CharacterBody2D, animation, collision, velocity và các hệ thống trình diễn. playable\_adel.gd giảm từ 531 dòng còn 493 dòng. Sau 1.3 và 1.4 ,các nhóm logic chính được tổ chức thành các Component độc lập hơn.

Việc giữ velocity, animation và collision ở Player cũng giúp duy trì ranh giới giữa logic gameplay được tách thành Component và trách nhiệm trực tiếp của Actor/CharacterBody2D.

4\. Đánh giá

Về mặt kiến trúc, A15 đã hoàn thành việc phân tách bốn nhóm responsibility chính của Player thành các Component tương ứng: locomotion, combat, damage và dash.

Về khả năng tương thích, Player vẫn giữ vai trò coordinator và các dependency giữa Component với playable\_adel.gd được duy trì thông qua constructor injection, signal và các API điều phối cần thiết.

Về kiểm thử, nhóm đã thực hiện kiểm tra các behavior và integration point chính trong phạm vi A15. Kết quả hiện tại cho thấy quá trình refactor không làm thay đổi behavior đã kiểm tra.

Tuy nhiên, việc playable\_adel.gd giảm số dòng từ 531 xuống 493 chỉ là một chỉ báo về mức độ thay đổi mã nguồn, chưa đủ để kết luận định lượng rằng maintainability hoặc coupling đã được cải thiện. Các chỉ số như số lượng dependency, số lượng integration point, change cost và performance cần được thu thập trong các giai đoạn đánh giá tiếp theo của nghiên cứu.

II. KHÓ KHĂN ĐẶT RA

2.1. Hạn chế và hướng phát triển

Tuần này tập trung vào việc tái cấu trúc các nhóm responsibility chính trong playable\_adel.gd và xác nhận behavior sau refactor. Vì vậy, báo cáo chưa đưa ra benchmark hiệu năng hoặc đánh giá định lượng đầy đủ về maintainability và change cost.

Trong các giai đoạn tiếp theo, nhóm có thể tiếp tục hoàn thiện hệ thống Component, mở rộng regression test và tiến hành đo lường các chỉ số phục vụ thực nghiệm so sánh kiến trúc.

2.2. Khó khăn trong quá trình refactor

playable\_adel.gd có nhiều responsibility và dependency liên kết với animation, FSM, CharacterBody2D, collision và các hệ thống gameplay khác. Vì vậy, việc tách Component phải duy trì đúng dependency và behavior hiện tại, đồng thời tránh chuyển nhầm responsibility sang Component.

Một số logic như velocity, animation và Ghost Trail được giữ lại ở Player để tránh mở rộng phạm vi refactor ngoài mục tiêu của A15.

2.3. Chưa có đánh giá định lượng

Nhóm chưa thực hiện đầy đủ benchmark hiệu năng và chưa thu thập các chỉ số trước/sau để đánh giá định lượng về:

•	Coupling. 

•	Change cost. 

•	Maintainability. 

•	Runtime performance. 

Do đó, các kết quả hiện tại chủ yếu xác nhận tính đúng đắn về cấu trúc và khả năng duy trì behavior, chưa phải kết luận định lượng về hiệu quả của kiến trúc.

2.4. Phạm vi tái cấu trúc còn giới hạn

A15 tập trung vào bốn nhóm responsibility:

\-	Locomotion

\-	Combat

\-	Damage

\-	Dash

Các hệ thống như Animation, Ghost Trail, Collision và FSM coordination vẫn được giữ ở playable\_adel.gd theo phạm vi đã xác định.

Việc giữ lại các thành phần này là có chủ đích nhằm tránh mở rộng scope refactor và bảo đảm quá trình thực nghiệm có thể kiểm soát được các biến thay đổi giữa các giai đoạn nghiên cứu.

3\. KẾ HOẠCH CÔNG VIỆC TUẦN TIẾP THEO

3.1. Xây dựng phương pháp thực nghiệm

Chốt lại Research Question và phạm vi đánh giá của đề tài.

Xác định các biến nghiên cứu, bao gồm biến độc lập, biến phụ thuộc và các điều kiện kiểm soát.

Xây dựng Experiment Protocol nhằm thống nhất quy trình thực hiện và đánh giá các thay đổi trên hai kiến trúc: FSM nguyên khối và Component + HFSM.

3.2. Thiết kế các Change Request

Xây dựng tập các yêu cầu thay đổi đại diện cho các khả năng của nhân vật.

Phân loại Change Request theo các nhóm chức năng như Locomotion, Combat, Damage/Stagger, Dash và tương tác giữa các thành phần.

Lựa chọn khoảng 4–6 Change Request phù hợp để sử dụng trong thực nghiệm.

3.3. Xây dựng hệ thống đo lường

Xác định các metric phục vụ đánh giá chi phí thay đổi, phạm vi ảnh hưởng và mức độ liên kết giữa các thành phần.

Thiết kế bảng ghi nhận dữ liệu cho từng Change Request.

Xây dựng checklist kiểm thử hồi quy nhằm đảm bảo hai kiến trúc được đánh giá trong cùng điều kiện.

Mục tiêu cuối tuần: Hoàn thiện Experiment Protocol, bộ Change Request và hệ thống metric làm cơ sở cho giai đoạn chuẩn bị baseline và thực nghiệm ở các tuần tiếp theo.


BÁO CÁO KỸ THUẬT NCKH – TUẦN 4

I. NHỮNG CÔNG VIỆC ĐÃ LÀM ĐƯỢC

1.1. Phân tích luồng nhận sát thương và cơ chế phòng thủ hiện tại

Tiến hành rà soát luồng nhận sát thương của nhân vật Adel trong scenes/adel/playable\_adel.gd và các nguồn gây sát thương trong game. Kết quả phân tích xác định PlayableAdel.take\_damage() là điểm tiếp nhận sát thương tập trung từ các nguồn như va chạm với kẻ địch, hurtbox của Ade1, hitbox vũ khí của Ishmael trong scene kiểm thử và phím gây sát thương phục vụ debug.

Bên cạnh đó, xác định cơ chế Guard/Deflect hiện tại chưa được tích hợp đầy đủ vào luồng xử lý sát thương. Trạng thái is\_guarding và holding\_duration đã tồn tại trong nhân vật nhưng chưa quyết định việc giảm hoặc vô hiệu hóa sát thương tại take\_damage(). Một phần logic phòng thủ vẫn nằm trong enemy\_weapon.gd, dẫn đến trách nhiệm xử lý bị phân tán giữa nhân vật và kẻ địch.

1.2. Thiết kế kiến trúc DefenseComponent

Đề xuất tách logic trạng thái phòng thủ khỏi playable\_adel.gd bằng component mới DefenseComponent, đặt tại scenes/adel/components/defense\_component.gd.

Component được thiết kế theo hướng RefCounted, chịu trách nhiệm quản lý trạng thái Guard và thời gian giữ phòng thủ, đồng thời phân loại kết quả khi nhân vật nhận đòn đánh. Component không trực tiếp quản lý animation, HP, knockback, stagger hoặc invulnerability; các trách nhiệm này tiếp tục thuộc về hệ thống hiện có.

Ba kết quả xử lý được xác định gồm:

•	NONE: nhân vật không phòng thủ hoặc đòn đánh đến từ phía sau.

•	DEFLECT: đòn đánh xảy ra trong cửa sổ phản đòn 0,2 giây đầu.

•	GUARD: đòn đánh xảy ra sau cửa sổ phản đòn khi nhân vật vẫn đang giữ phòng thủ.

Thiết kế này hướng đến việc tập trung hóa quy tắc phòng thủ, giảm sự phụ thuộc vào từng loại kẻ địch và tạo điều kiện mở rộng cơ chế trong tương lai.

1.3. Thiết kế tích hợp DefenseComponent vào nhân vật Adel

Xây dựng kế hoạch tích hợp DefenseComponent vào playable\_adel.gd, trong đó trạng thái phòng thủ được ủy quyền cho component thay vì tiếp tục lưu trữ logic độc lập trong nhân vật.

Các thuộc tính is\_guarding và holding\_duration dự kiến được giữ dưới dạng thuộc tính chỉ đọc, chuyển tiếp dữ liệu từ component nhằm duy trì khả năng tương thích với những đoạn code đang sử dụng chúng.

Quy trình Guard/Deflect được thiết kế theo các bước:

1\.	Khi người chơi nhấn nút phòng thủ và nhân vật không thực hiện hành động khác, hệ thống bắt đầu Guard, khóa di chuyển và phát animation saber\_deflect.

2\.	Trong 0,2 giây đầu, đòn đánh hợp lệ được phân loại là Deflect và không gây sát thương.

3\.	Nếu tiếp tục giữ nút quá thời gian trên, hệ thống chuyển sang animation saber\_guard; sát thương được giảm theo hệ số phòng thủ.

4\.	Khi người chơi thả nút, hệ thống kết thúc Guard, khôi phục khả năng điều khiển và chuyển sang saber\_ready, sau đó trở về trạng thái idle theo luồng animation hiện có.

Vị trí cập nhật trạng thái phòng thủ trong vòng lặp xử lý cũng được xác định cần đặt trước nhánh thoát sớm do is\_locked hoặc can\_move. Điều này nhằm bảo đảm thao tác thả nút vẫn được xử lý, tránh tình trạng nhân vật bị khóa phòng thủ ngoài ý muốn.

1.4. Thiết kế tích hợp giảm sát thương và khả năng mở rộng chỉ số

Đề xuất bổ sung chỉ số guard\_damage\_reduction trong StatsComponent, với mức giảm sát thương phòng thủ cơ bản là 50%. Hệ số sát thương nhận vào được tính từ chỉ số này thông qua hàm get\_guard\_damage\_multiplier().

Đồng thời, bổ sung thuộc tính và hàm chuyển tiếp tương ứng trong ui.gd để duy trì vai trò facade của giao diện chỉ số. Luồng xử lý sát thương hiện có, bao gồm stagger và knockback, được giữ nguyên; không thay đổi trực tiếp StatsComponent.apply\_damage().

Thiết kế này tạo điểm mở rộng cho hệ thống nâng cấp phòng thủ trong tương lai mà không yêu cầu thay đổi lại quy trình phân loại Guard/Deflect.

1.5. Chuẩn hóa trách nhiệm xử lý giữa nhân vật và kẻ địch

Đề xuất loại bỏ logic kiểm tra hướng đánh và thời gian phản đòn trùng lặp trong scenes/testing/Enemies/enemy\_weapon.gd. Sau khi điều chỉnh, vũ khí của kẻ địch chỉ gửi yêu cầu gây sát thương thông qua body.take\_damage(20, global\_position); việc quyết định đòn đánh bị Deflect, Guard hay gây sát thương bình thường do phía nhân vật xử lý.

Phương án này nhằm bảo đảm các nguồn sát thương sử dụng cùng một quy tắc phòng thủ, đồng thời loại bỏ thao tác ghi đè body.is\_doing\_action = false từ phía kẻ địch có nguy cơ làm gián đoạn trạng thái hành động của nhân vật.

II. KHÓ KHĂN ĐẶT RA

2.1. Khó khăn trong việc đồng bộ trạng thái phòng thủ và vòng đời hành động

Cơ chế Guard/Deflect phải phối hợp với trạng thái hành động, khả năng di chuyển, animation và luồng nhận sát thương của nhân vật. Nếu cập nhật sai thứ tự, nhân vật có thể bị kẹt trong trạng thái phòng thủ, animation bị ghi đè hoặc vẫn thực hiện các hành động không phù hợp khi đang Guard.

2.2. Khó khăn trong việc bảo đảm tính nhất quán giữa các nguồn sát thương

Logic phòng thủ trước đây có một phần được xử lý tại phía kẻ địch, trong khi luồng nhận sát thương tập trung nằm ở phía nhân vật. Việc chuyển trách nhiệm sang PlayableAdel.take\_damage() cần được kiểm tra với từng nguồn sát thương để tránh trường hợp một loại đòn đánh bỏ qua quy tắc Guard/Deflect.

2.3. Chưa có kết quả kiểm thử thực tế

Ở giai đoạn hiện tại, các thay đổi nêu trên mới được xác định trong kế hoạch triển khai. Chưa có đủ kết quả chạy game để xác nhận thời gian Deflect, mức giảm sát thương, khả năng khôi phục điều khiển và tính tương thích với các nguồn sát thương. Vì vậy, hiệu quả của phương án cần được đánh giá sau khi hoàn thành triển khai và kiểm thử trong Godot.

2.4. Kết quả dự kiến

•	Tách trạng thái và quy tắc phân loại Guard/Deflect thành DefenseComponent.

•	Tập trung quyết định phòng thủ tại luồng nhận sát thương của nhân vật Adel.

•	Hoàn thiện quy tắc Deflect trong 0,2 giây đầu và Guard với mức giảm sát thương cơ bản 50%.

•	Duy trì cơ chế stagger và knockback hiện có đối với các đòn đánh được Guard.

•	Loại bỏ logic phòng thủ trùng lặp ở phía vũ khí kẻ địch.

•	Chuẩn bị cấu trúc để mở rộng chỉ số phòng thủ trong tương lai.

2.5. Kế hoạch kiểm thử và đánh giá

Sau khi hoàn thành triển khai, tiến hành kiểm thử trên scene scenes/testing/testing.tscn với các trường hợp:

1\.	Đòn đánh đến trong 0,2 giây đầu: không mất HP và phát animation saber\_deflect.

2\.	Giữ Guard quá 0,2 giây: sát thương nhận vào giảm khoảng 50% và phát animation saber\_guard.

3\.	Đòn đánh đến từ phía sau: nhận đầy đủ sát thương.

4\.	Thả nút phòng thủ rồi nhận đòn: nhận đầy đủ sát thương theo luồng thông thường.

5\.	Đang Guard: không thể di chuyển, nhảy hoặc Dash.

6\.	Không thể bắt đầu Guard giữa một hành động đang diễn ra.

7\.	Thả nút sau khi Guard: nhân vật khôi phục điều khiển và trở về trạng thái idle.

8\.	Kiểm tra nhiều nguồn sát thương

Kết quả kiểm thử sẽ được ghi nhận theo từng trường hợp, bao gồm trạng thái animation, lượng HP mất, hướng tấn công và khả năng khôi phục điều khiển. Chỉ kết luận cơ chế hoạt động đúng sau khi các trường hợp tương ứng được chạy và xác nhận trong game.









