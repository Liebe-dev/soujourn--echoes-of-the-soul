# Preview tách bộ phận quái

Thiết kế được duyệt: vỏ trắng sáng, da than đen, đuôi đỏ trầm, ít vết thương khô và khói đen mỏng.

## Xem trước

- parts_preview_labeled.png: ảnh tổng có nhãn tên file, nền xám để thấy rõ da tối và khói.
- parts_atlas_transparent.png: ảnh tổng nền trong suốt, không có chữ.
- parts/: 10 PNG rời, tên khớp bộ phận trong thư mục game, giữ nguyên cách viết lef leg.png.

## Cách tạo và giới hạn

Bản này được ImageGen dựng tách theo ảnh quái đã duyệt và sơ đồ 10 bộ phận hiện tại; các vùng bị che khuất và vùng chồng lấp ở khớp được dựng bù. Đây không phải phép cắt giữ nguyên từng pixel từ ảnh quái liền khối.

Các PNG rời được lấy trực tiếp từ atlas dựng tách, rồi ghép lại để xem cách phân chia. Kích thước preview hiện chưa được chuẩn hóa theo canvas/pivot của ảnh trong game; chưa xác nhận chạy khớp trên xương và chưa thay texture.

template.png không phải một bộ phận đang gắn lên rig, nên không tạo ảnh thay thế cho template trong bộ 10 phần này.

Ảnh trong asset/Enemies/sample/images và scene rig được giữ nguyên. Đã đối chiếu SHA-256 trước/sau đối với thư mục ảnh gốc.

Phần smoke hiện nằm trong ảnh preview. Khi tích hợp cần xem xét cách nó di chuyển theo từng bộ phận và độ trong suốt ở mép.

parts_manifest.json ghi vùng cắt và kích thước preview so với ảnh gốc. Atlas dựng tách gốc được lưu tại C:/Users/xuank/.codex/generated_images/01a1722e-0438-7060-84ea-76648f36bf4e/exec-0fd83511-55d8-4a15-95a3-a0c401f078ef.png.

