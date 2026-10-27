# Bản vẽ lại theo khung rig gốc — đang dùng

Đã thay 10 PNG trong `asset/Enemies/sample/images` bằng bộ `parts/` của thư mục này. Mỗi file giữ đúng tên, chiều rộng và chiều cao của ảnh gốc trước khi thay; không thêm viền 48 px, không xoay, dịch tâm hoặc căn từng phần như bản v1. Không sửa file cảnh, xương, vị trí Sprite2D, khóa animation hoặc `.import`.

Mỗi phần được vẽ mới bằng công cụ ImageGen tích hợp. Khuôn dùng hình dáng/hướng ảnh gốc; thiết kế tham khảo bộ vỏ trắng sáng, da than đen, vết thương khô cũ và khói đen mỏng đã duyệt. `generated_sources.json` lưu prompt cuối và đường dẫn ảnh tạo cho cả 10 phần; chân gần sử dụng bản cuối với `full_canvas=true`. `generated/` giữ ảnh tạo, `templates/` giữ khuôn tham chiếu. Bước đưa ảnh về độ phân giải gốc chỉ lấy khung cố định của khuôn và đổi độ phân giải, không áp dụng phép xoay hay dịch riêng từng phần. Các vùng alpha che khớp gốc được giữ bằng lớp đen phẳng ở đúng tọa độ, không sao chép chi tiết bề mặt cũ.

`fixed_frame_validation.json` xác nhận kích thước gốc của 10 file và không mất vùng che khớp. Bộ kiểm tra Godot riêng dùng đúng file PNG đã import, không thay texture lúc chạy, dựng 6 tư thế: walk 0/0.5 giây, run 0.25/0.75 giây, detect player 0.2 giây, RESET 0 giây. Kết quả `installed_validation.json`: passed, đủ 10 phần mỗi tư thế. Có cảnh báo Bone2D cuối không có con vốn có trong rig gốc; không sửa rig để loại cảnh báo đó. Đây là kiểm tra 6 tư thế, không phải kiểm thử toàn bộ gameplay.

`installed_rig_check.png` là ảnh ghép các tư thế; `installed_preview.png` là một tư thế đi. `parts_fixed_frame_preview.png` là ảnh tổng 10 phần kèm kích thước. `installation_result.json` ghi hash của 10 PNG đã cài; đã xác nhận chúng trùng file `parts/`, cảnh rig và các file import giữ nguyên. Editor Godot không kết nối khi hoàn tất lần thay này; dự án sẽ nạp lại các PNG thay đổi khi mở.

Bản sao trước lượt sửa nằm ở `before_redo/` (bản v1 đã căn sai ý người dùng). Ảnh cũ lấy từ mạng trước mọi lần thay nằm ở `../enemy_parts_2026-10-26_v1/originals/`. Bộ preview từng được duyệt vẫn nguyên ở `../../previews/enemy_parts_2026-10-26_v2_flat_joints/`.

Phạm vi thay là 10 phần trong `images/`. `template.png`, các ảnh trong `attack/` và `death.png` chưa thay; những animation dùng ảnh riêng đó vẫn hiển thị thiết kế cũ.
