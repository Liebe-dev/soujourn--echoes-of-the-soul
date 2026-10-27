# attack3 — preview 3 frame, chờ duyệt

- [PNG sprite sheet nền trong suốt](attack3.png): **2703 × 931**, ba ô **901 × 931** theo X.
- [Bản xem có đường chia ô](preview.png).
- [Đối chiếu ảnh gốc và ảnh mới](comparison.png): gốc ở trên, mới ở dưới.

Ba tư thế: đứng giơ rộng hai tay; hai tay quật xuống/vào trong với hai dải chém đen và nhòe chuyển động; chùng người hồi chiêu ở nửa dưới ô cuối. Tay ở tư thế quật dùng phần khuỷu/cẳng tay dài, bàn tay khuất theo nguyên tắc đã duyệt ở attack2. Giữ các chi phía xa làm lớp tối, không bỏ chi đen trong ảnh gốc.

Ảnh được vẽ bằng ImageGen tích hợp theo khuôn tư thế gốc và thiết kế quái mới: vỏ trắng, da than đen, đuôi đỏ rượu, vết nứt khô tiết chế. [Prompt cuối cho từng frame và nguồn ảnh tạo](generation_manifest.json). `high_res/` lưu ảnh tạo độ phân giải cao, `frames/` lưu toàn bộ canvas từng ô ở khung gốc. Khi ghép không cắt sát alpha hoặc tự căn giữa nhân vật; giữ mốc X=0, 901, 1802, 2703. Nền xám, nhãn và đường chia chỉ thuộc bản xem, không nằm trong PNG sprite sheet.

[Kết quả kiểm tra](preview_validation.json) xác nhận khổ sheet/cách chia ô và các tài nguyên game/cảnh không đổi. Đã xem ảnh đối chiếu sau khi ghép. Chưa chạy animation mới trong game.

Animation gốc đã đọc: `hframes=3`, `vframes=1`, vị trí (1007,522), scale (0.9,0.9), các frame 0/1/2 tại 0/0.4/0.6 giây, độ dài 0.9 giây. Không thay các thông số này; bản đọc lưu ở `original_animation.txt`.

**Chỉ preview. Chờ người dùng phê duyệt mới thay `asset/Enemies/sample/attack/attack3.png` trong game.**
