BỘ XÂY DỰNG

TRƯỜNG ĐH KIẾN TRÚC HN	CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM

Độc lập - Tự do - Hạnh phúc



&#x09;

Hà Nội, ngày 25 tháng 8 năm 2026

ĐỀ CƯƠNG ĐỀ TÀI NGHIÊN CỨU KHOA HỌC SINH VIÊN

I.	Thông tin chung

•	Tên đề tài: Phát triển Game 2D Kể chuyện dựa trên Godot Engine

•	Nhóm sinh viên thực hiện:

Đào Xuân Khôi		Lớp: 24CN3		Khoa: Công nghệ Thông tin

Trịnh Duy Mạnh		Lớp: 24CN4		Khoa: Công nghệ Thông tin

Chu Thị Phương Anh		Lớp: 24CN3		Khoa: Công nghệ Thông tin

Bùi Minh Ánh			Lớp: 24CN3		Khoa: Công nghệ Thông tin

•	Giảng viên hướng dẫn: TS. Nguyễn Việt Hưng

II.	Nội dung đề cương

1\.	Giới thiệu đề tài

o	Lý do chọn đề tài / Tính cấp thiết:

Sai liên kết hội thoại hoặc điều kiện nhiệm vụ có thể khiến người chơi bị kẹt hay không tới được kết thúc; kiểm tra thủ công nhiều nhánh tốn thời gian. Đề tài đề xuất mô-đun kiểm tra tự động trên Godot Engine, kiểm chứng bằng nguyên mẫu Soujourn: Echoes of the Soul.

o	Tổng quan vấn đề nghiên cứu:

Dialogue Manager đã hỗ trợ hội thoại phân nhánh và kiểm tra cú pháp \[1] \[2]. Đề tài bổ sung quy tắc kiểm tra tiến trình và so sánh với kiểm tra thủ công trong game nhỏ.

2\.	Mục tiêu nghiên cứu

o	Mục tiêu chung:

Xây dựng mô-đun kiểm tra lỗi cốt truyện phân nhánh trên Godot Engine; đo hiệu quả so với kiểm tra thủ công.

o	Mục tiêu cụ thể:

\-	Mô hình hóa hội thoại, Observe và nhiệm vụ bằng đồ thị dữ liệu nhỏ; mỗi nút có mã, lựa chọn, điều kiện và cập nhật biến đúng/sai.

\-	Xây dựng mô-đun kiểm tra năm nhóm lỗi: mã/liên kết nút sai; biến chưa khai báo; trạng thái chưa kết thúc không có lựa chọn hợp lệ; một trong hai kết thúc đã chỉ định không thể đạt; vi phạm một trong hai quy tắc nhiệm vụ cố định.

\-	Xây dựng nguyên mẫu Soujourn: Echoes of the Soul để minh họa và kiểm chứng mô-đun.

\-	Đo khả năng phát hiện lỗi, độ chính xác cảnh báo, thời gian sửa lỗi và kiểm thử nguyên mẫu.

3\.	Đối tượng và phạm vi nghiên cứu

o	Đối tượng nghiên cứu: Đồ thị tiến trình cốt truyện, trạng thái nhiệm vụ, quy tắc kiểm tra và GDScript.

o	Phạm vi nghiên cứu:

\-	Không gian: Godot Engine trên PC.

\-	Thời gian: Từ tháng 9 năm 2026 đến tháng 5 năm 2027.

\-	Nội dung: Một chương chơi 10-15 phút, hai NPC, hai kết thúc, một cảnh Observe 60-90 giây và 2-3 dấu vết môi trường. Toàn bộ mô hình có tối đa 40 nút và bốn biến đúng/sai. Mỗi điều kiện kiểm tra tối đa hai biến bằng phép VÀ; tác động chỉ gán đúng/sai. Tái sử dụng điều khiển nhân vật, không làm AI hoặc hệ chiến đấu.

4\.	Phương pháp nghiên cứu

\-	Phân tích tài liệu: Đối chiếu Godot \[1], Dialogue Manager \[2], xác định chức năng kế thừa và quy tắc cần bổ sung.

\-	Thực nghiệm: Duyệt đồ thị trạng thái gồm nút và bốn biến đúng/sai bằng hàng đợi, tập đã thăm \[4]; tối đa 640 tổ hợp. Dữ liệu mô hình và game dùng chung; mọi thay đổi của bốn biến đều được khai báo. Xuất cảnh báo kèm loại lỗi và vị trí; đường đi minh họa cho trạng thái đạt được.

\-	Kiểm thử tích hợp: Xây dựng 15 kịch bản ngắn về hội thoại, Observe, nhiệm vụ/kết thúc và lưu/tải; sửa các lỗi chặn tiến trình trước khi đánh giá. Đo thời gian kiểm tra mô hình lớn nhất 10 lần, báo cáo trung vị và lớn nhất; dưới một giây là mục tiêu kỳ vọng. Ghi cấu hình máy, phiên bản Godot.

\-	Đánh giá mô-đun: Chuẩn bị 30 tình huống nhỏ: 20 có lỗi (4/nhóm), 10 hợp lệ; giảng viên rà soát nhãn. Bộ phát triển và bộ đánh giá cuối, mỗi bộ có 10 lỗi (2/nhóm), 5 hợp lệ; giữ riêng bộ cuối. Recall = TP/(TP+FN); Precision = TP/(TP+FP). Báo cáo từng nhóm và tổng hợp; 90% là mục tiêu kỳ vọng cho hai chỉ số tổng hợp.

\-	Thực nghiệm đối chứng quy mô nhỏ: Mời bốn sinh viên ngoài nhóm, mỗi người sửa hai bài dữ liệu ở mỗi điều kiện: thủ công, có mô-đun; tổng 16 lượt. Cả hai điều kiện dùng cùng Godot và Dialogue Manager. Dùng bài tương đương, khôi phục dữ liệu; hai người làm thủ công trước, hai người dùng mô-đun trước. Đo thời gian đạt cùng bộ kiểm thử và lỗi còn lại; quá 20 phút ghi chưa hoàn thành. Báo cáo thời gian từng người và trung vị phần trăm giảm; 25% là kỳ vọng, không là điều kiện bắt buộc. Kết luận chỉ áp dụng cho thử nghiệm này.

5\.	Dự kiến kết quả nghiên cứu

\-	Báo cáo về mô hình, quy tắc, kết quả đối chứng và giới hạn giải pháp.

\-	Một nguyên mẫu Soujourn: Echoes of the Soul chạy trên PC, tích hợp hội thoại, một cảnh Observe, nhiệm vụ, lưu/tải và mô-đun kiểm tra.

\-	Mô-đun kiểm tra, bộ 30 tình huống gán nhãn, 15 kịch bản tích hợp, mã nguồn, hướng dẫn và dữ liệu thực nghiệm để tái lập.



6\.	Tài liệu tham khảo chính

\-	\[1] Godot Engine. Official Documentation. https://docs.godotengine.org/en/stable/ (truy cập 05/10/2026).

\-	\[2] Nathan Hoad. Dialogue Manager. https://store.godotengine.org/asset/nathanhoad/dialogue-manager/ (truy cập 05/10/2026).

\-	\[3] Game Programming Patterns (2014) của Robert Nystrom xuất bản bởi Genever Benning.

\-	\[4] Bài giảng Cấu trúc dữ liệu và giải thuật (2020) của TS. Nguyễn Duy Phương, ThS. Nguyễn Mạnh Sơn (PTIT)

Lãnh đạo Khoa

(Ký tên)	Giảng viên hướng dẫn

(Ký tên)	Đại diện nhóm sinh viên

(Ký tên)

