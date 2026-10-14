BÁO CÁO TIẾN ĐỘ NCKH – TUẦN 4

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





