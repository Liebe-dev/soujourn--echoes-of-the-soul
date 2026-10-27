# attack2 — tay quật dài dưới hàm, đã duyệt và tích hợp

- [Chi tiết tay đã sửa](arm_detail.png).
- [Đối chiếu tay trước và sau](arm_comparison.png).
- [Sheet 3 ô có đường chia để xem](preview.png).
- [PNG nền trong suốt 3823 × 704](attack2.png): file dành cho bước thay vào game nếu được duyệt.

Sửa riêng frame 2 theo vùng người dùng khoanh đỏ: kéo dài tay tới ngay dưới hàm, khuỷu đưa ra phía trước-trái, phần cẳng tay gập/quật vào trong; bàn tay và vuốt vẫn khuất sau thân. Không giữ kiểu gập ngắn sát ngực của v2.

Tay mới được vẽ bằng ImageGen tích hợp từ ảnh khoanh đỏ của người dùng. [Prompt cuối](generation_prompt_frame2.txt) và [nguồn ảnh tạo](generation_source.json). Khi tích hợp ảnh tạo, chỉ cập nhật vùng tay trong frame 2; các pixel ngoài vùng đó (kể cả dải chém) giữ từ preview trước. Frame 1 và frame 3 được chép nguyên byte, đã đối chiếu hash. Khổ sheet vẫn 3823 × 704 với 3 mốc chia X bằng nhau như gốc, không đổi vị trí ô hoặc tự căn giữa nhân vật.

[Kết quả kiểm tra](preview_validation.json) ghi vùng sửa và xác nhận hai frame còn lại cùng tài nguyên game không đổi. Đây là preview, chưa chạy animation mới trong game.

**Đã được người dùng duyệt bằng lệnh “duyệt, thay đi” và thay vào game.** Đã chép nguyên byte PNG `attack2.png` của thư mục này vào `asset/Enemies/sample/attack/attack2.png`, giữ khổ 3823 × 704 và cách chia 3 frame X. Không đổi cảnh, animation hoặc file import. `preview_validation.json` ghi kiểm tra trước khi tích hợp; bản sao ảnh cũ và kết quả cài đặt nằm ở `../../integration/enemy_attack2_2026-10-27_v3_long_inward_arm/`.
