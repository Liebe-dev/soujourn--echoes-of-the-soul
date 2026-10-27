# Bộ phận quái đã thay vào game

**Bản v1 này đã ngừng dùng.** Người dùng yêu cầu làm lại vì không chấp nhận việc tự xoay/co giãn/căn hình trong từng file. Bộ đang cài là `../enemy_parts_2026-10-26_v2_redo/parts/`, được vẽ lại theo khung, hướng và kích thước ảnh gốc. Các thông tin bên dưới chỉ ghi nhận bản v1 lịch sử; không dùng script v1 để cài lại.

Đã thay 10 PNG trong `asset/Enemies/sample/images`, giữ đúng tên cũ (kể cả `lef leg.png`). Nguồn là bộ preview khớp đen phẳng đã duyệt trong `output/previews/enemy_parts_2026-10-26_v2_flat_joints/parts`.

Ảnh được xoay, co giãn và căn theo các điểm gắn của rig cũ. Canvas được thêm 48 px trong suốt đối xứng ở mỗi cạnh để giữ nguyên tâm Sprite2D và tránh cắt mất phần hình nhô ra. Không sửa xương, vị trí Sprite2D, khóa chuyển động hoặc file cảnh. Các file `.import` và UID giữ nguyên.

`originals/` chứa bản sao ảnh cũ và các file import trước khi thay. `before_hashes.json` và `replacement_result.json` ghi hash trước/sau. `candidate/` chứa đúng 10 PNG đã ghi vào game. Muốn khôi phục, chép lại 10 PNG cùng tên từ `originals/` về thư mục đích rồi nạp lại ảnh trong Godot.

Đã reimport 10 PNG trong editor. Bộ kiểm tra riêng dùng tài nguyên PNG đã import (không ghi đè texture lúc chạy), dựng 6 tư thế: walk 0 và 0.5 giây; run 0.25 và 0.75 giây; detect player 0.2 giây; RESET 0 giây. Mỗi tư thế nạp đủ 10 phần, kích thước đúng bản thay. `installed_validation.json` lưu kết quả; `installed_rig_check.png` lưu ảnh kiểm tra; `installed_preview.png` là tư thế đi sau khi thay. Cảnh gốc và các file import đã được đối chiếu hash và không thay đổi. Cảnh gốc vốn có cảnh báo Bone2D ở xương cuối không có con; đây là cảnh báo có sẵn trong cả bản cũ và bản thay.

Phạm vi lần này là 10 ảnh bộ phận vừa duyệt. `template.png`, ảnh riêng trong `attack/` và `death.png` chưa thay; các animation tấn công/chết đang hiển thị bộ ảnh riêng đó nên vẫn mang thiết kế cũ.

Không tạo ảnh AI mới ở bước tích hợp này. Nguồn hình đã được tạo bằng công cụ ImageGen tích hợp ở bước preview; prompt gốc nằm tại `output/previews/enemy_parts_2026-10-26_v2_flat_joints/generation_prompt.txt`.
