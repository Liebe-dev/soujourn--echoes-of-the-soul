# attack2 — preview một ảnh gồm 3 frame, chờ duyệt

**Bản đã duyệt và đang dùng trong game:** [v3 — kéo dài tay quật vào trong ngay dưới hàm](../enemy_attack2_2026-10-27_v3_long_inward_arm/README.md). V1 giữ để đối chiếu, không phải bản đã cài.

- [PNG sprite sheet nền trong suốt](attack2.png): **3823 × 704**, cùng khổ file đang dùng trong game.
- [Bản xem có đường chia 3 ô](preview.png): nền xám giúp nhìn rõ chi tối và dải chém đen; nhãn/đường chia chỉ nằm trong ảnh xem này.
- [Đối chiếu gốc và mới](comparison.png): gốc ở trên, mới ở dưới, dùng cùng mốc chia X.

Giữ `hframes=3`, `vframes=1`. Khổ gốc không chia hết cho 3 ở mức pixel nguyên, nên giữ mốc chia toán học của engine: x=0; 1274,333…; 2548,666…; 3823. Không đổi chiều rộng ảnh để làm tròn. Các ô nguồn được lấy theo đúng những mốc này và ghép lại vào cùng tọa độ. Các PNG làm việc trong `frames/` có khung 1274 × 704; toàn bộ canvas được đổi độ phân giải vào ô đích 1274,333… × 704, không cắt sát alpha, không xoay, dịch hoặc tự căn giữa nhân vật theo hình bao. Giữ phần trống của từng tư thế theo ảnh tham chiếu.

Ba frame: giơ tay chuẩn bị; quét nhanh có dải chém đen và nhòe chuyển động; chùng người hồi chiêu. Mỗi frame được vẽ riêng bằng ImageGen tích hợp theo thiết kế quái mới (vỏ trắng, da than đen, đuôi đỏ rượu, vết nứt/vết thương khô tiết chế), dùng ảnh cũ trên nền xám để thấy cả các chi màu đen. Sau đó ghép bằng vị trí ô cố định. [Prompt cuối và nguồn ảnh tạo](generation_manifest.json); [bố cục nguồn](layout_manifest.json).

`preview_validation.json` xác nhận khổ sheet, cách chia ba ô và hash tài nguyên game/cảnh không đổi. Đã kiểm tra ảnh đối chiếu và mép các frame; chưa chạy animation mới trong game. Animation gốc đã đọc có vị trí (714,644), scale (0.9,0.9), frame 0/1/2 tại 0/0.3/0.4 giây, độ dài 0.7 giây; các thông số này không bị sửa.

**Chỉ preview, chờ người dùng duyệt. Chưa thay `asset/Enemies/sample/attack/attack2.png` trong game.** Nếu được duyệt, file cần thay là PNG `attack2.png` nền trong suốt ở đầu tài liệu, không phải ảnh preview có nhãn/đường chia.
