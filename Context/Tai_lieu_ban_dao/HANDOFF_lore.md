# Bàn giao lore Soujourn Echoes of the Soul

Ngày bàn giao và kiểm tra file: **24/10/2026**, múi giờ **Asia/Saigon**.

Thư mục dự án: `D:/Godot Project/soujourn--echoes-of-the-soul`.

Đây là bàn giao nhánh **cốt truyện, worldbuilding và cơ cấu cai trị Varenne tại An Châu**. File `HANDOFF.md` hiện có thuộc nhánh kỹ thuật/gameplay khác và được giữ nguyên. Nhiệm vụ chỉnh cơ cấu gần nhất đã có bản Word giao cho người dùng; phần đối chiếu lịch sử chuyên sâu còn dang dở.

## 1. Bắt đầu ở đây

1. Đọc [AGENTS.md](<AGENTS.md>).
2. Kiểm tra trạng thái file và Git thực tế. Bàn giao mô tả bản đã lưu trên đĩa; có file khóa Word nên có thể tồn tại thay đổi chưa lưu trong cửa sổ của người dùng.
3. Đọc [bản An Châu cơ cấu Thống đốc](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/Bản phác luồng cốt truyện Arc 1 An Châu - cơ cấu Thống đốc.docx>). Đây là kết quả làm việc mới nhất của chat này, không đồng nghĩa toàn bộ nội dung đã chốt canon.
4. Đọc mục 3–5 dưới đây để phân biệt yêu cầu trực tiếp của người dùng, lựa chọn của AI và điểm chưa được xác minh.
5. Khi tiếp tục, báo ngắn trạng thái đã xác minh và chỗ khác với bàn giao, rồi xử lý yêu cầu mới. Nếu tiếp tục việc cơ cấu lịch sử, ưu tiên các điểm ở mục 9; không tự coi mọi ý tưởng cốt truyện cũ là nhiệm vụ cần viết hoặc triển khai.

## 2. Mục tiêu và cách làm việc

- Vai trò: cố vấn cốt truyện, worldbuilding và nhà phát triển game cho **Soujourn: Echoes of the Soul**. Giai đoạn chỉ tiếp nhận thông tin đã kết thúc theo yêu cầu người dùng.
- Người dùng muốn một thế giới có chiều rộng, chiều sâu, quan hệ nhân quả và lịch sử liên kết; các sự kiện diễn ra vì động lực của thế giới, không chỉ xoay quanh Adel. Terra/Arknights là nguồn cảm hứng rõ rệt.
- Người dùng muốn tự ngẫm và viết chiều sâu nhân vật, cách mạng, triết học, vật phẩm và môi trường. Hỗ trợ bằng nhận xét, câu hỏi, tài liệu tham khảo; viết lại/sắp xếp khi được yêu cầu cụ thể.
- Giao tiếp bằng tiếng Việt, ngắn, rõ, phản biện có căn cứ. Không biến đề xuất của AI thành canon bằng cách lặp lại như sự thật.
- Phân biệt tài liệu đính kèm với yêu cầu hiện hành. Master prompt và các văn bản cũ là nguồn cần đọc trong bối cảnh; yêu cầu mới của người dùng có ưu tiên.
- Theo AGENTS.md: bảo toàn DOCX và tài liệu lịch sử do người dùng cung cấp. Công việc này đã tạo bản chỉnh sửa riêng. Các quy tắc cập nhật hướng dẫn tuning chỉ áp dụng khi thực sự sửa thông số gameplay/code, không phát sinh từ việc chỉnh lore.

## 3. Yêu cầu đã chốt và lựa chọn chưa chốt riêng

### Yêu cầu trực tiếp của người dùng

- Sơ đồ thể hiện **phân tầng quyền lực từ cao xuống thấp**, không phải chuỗi chỉ huy. Chức có quyền lực thấp hơn không mặc nhiên nhận lệnh từ mọi chức ở tầng trên.
- Sơ đồ ngắn, chỉ tên chức danh, không chèn mô tả nhiệm vụ trong từng ô.
- Cơ cấu cần tham khảo **bộ máy cai trị Pháp tại Việt Nam thời Pháp thuộc**, không chỉ dùng tên chức nghe cổ.
- Yêu cầu hành động gần nhất: **đổi cơ cấu Tổng đại diện và bốn Ủy viên sang Thống sứ, Khâm sứ hoặc Thống đốc**.
- Nhiệm vụ bàn giao hiện tại: lưu đúng tên `HANDOFF_lore.md`, giữ nguyên `HANDOFF.md` đã có.

### Lựa chọn AI đã thực hiện trong bản Word mới nhất

- Chọn **Thống đốc An Châu**, diễn giải theo mô hình cai trị trực tiếp ở Nam Kỳ. Người dùng cho phép lựa chọn giữa ba chức danh nhưng chưa xác nhận riêng lý do chọn Thống đốc.
- Thay bốn Ủy viên bằng các chức đứng đầu ngành chuyên môn.
- Chuyển Obscur từ Ủy viên An ninh sang **Giám đốc Sở Liêm phóng**.
- Thay sáu chỗ `Phủ Khâm sai` bằng `Phủ Thống đốc` để tên địa điểm thống nhất với chức đứng đầu.
- Đổi Tổng thư ký thành **Chánh văn phòng**, bỏ tầng Giám đốc sở chung chung bị trùng với các chức đứng đầu sở mới.

Những lựa chọn trên đã được ghi vào bản chỉnh sửa và giao cho người dùng. Chưa có phản hồi nghiệm thu sau đó: các lượt tiếp theo là `/status`, đánh giá độ dài chat và yêu cầu bàn giao. Đừng ghi rằng người dùng đã duyệt riêng mọi chức danh hoặc chốt toàn bộ lore trong file.

## 4. Trạng thái cơ cấu hiện nằm trong bản Word

Đây là **bản làm việc đã kiểm tra nội dung**, không phải sơ đồ nguyên mẫu của một chính quyền Pháp có năm/nghị định xác định. Các nhóm dưới đây mô tả vị trí trong sơ đồ, không xác nhận quan hệ chỉ huy.

- Tầng đầu: **Thống đốc An Châu**.
- Tầng kế: **Chánh văn phòng; Giám đốc Sở Mỏ; Giám đốc Sở Tài chính và Thương vụ; Giám đốc Sở Công chính; Giám đốc Sở Liêm phóng**.
- Tầng tiếp: **Quản đốc khu vực; Chủ sự kế toán; Quản kho; Giám đốc nhà máy; Trưởng đoàn vận tải; Chánh thanh tra; Chỉ huy bảo an**.
- Tầng dưới: **Đốc công; Thủ quỹ; Kỹ sư trưởng**.
- Tầng cuối: **Cai phu; Nhân viên thu phí; Kỹ thuật viên**.

Phần văn bản kèm sơ đồ giữ các chức năng thiết kế vốn có: mỏ và nhân công; tài chính/tín dụng/giao dịch tinh thể; nhà máy/tinh luyện/năng lượng/hạ tầng; kiểm tra nội bộ/phản gián/bảo vệ Varenne.

### Giới hạn cần sửa bằng nghiên cứu, không bằng suy đoán

- Đã có căn cứ cho chức đứng đầu xứ: Thống sứ Bắc Kỳ, Khâm sứ Trung Kỳ, Thống đốc Nam Kỳ. Đây là những vị trí đứng đầu các xứ khác nhau, không phải ba bậc liên tiếp để cùng đặt lên một sơ đồ An Châu.
- Chưa chứng minh mọi tầng bên dưới khớp cơ cấu Pháp thuộc: ví dụ Kỹ sư trưởng ở thấp hơn Giám đốc nhà máy, Chủ sự kế toán ngang Quản kho, Chánh thanh tra ngang Chỉ huy bảo an.
- Bản cũ AI từng đề xuất nâng Kỹ sư trưởng ngang Giám đốc nhà máy, Quản kho ngang Thủ quỹ. Người dùng chưa chốt; bản mới nhất thực tế vẫn có các tầng như liệt kê trên. Không lấy danh sách đề xuất cũ thay cho nội dung file.
- `Sở Tài chính và Thương vụ` là tên ghép thích ứng cho game, chưa xác minh là tên chính thức ở một xứ và thời điểm lịch sử cụ thể.
- Cần phân biệt cơ quan nhà nước quản lý mỏ/công chính với doanh nghiệp trực tiếp điều hành mỏ/nhà máy. Bản hiện hành còn trộn hai loại vai trò.
- Tính chất của Varenne chưa được giải quyết hoàn toàn: trước đây là liên hiệp công nghiệp/công ty được trao đặc quyền, bản mới dùng người đứng đầu chính quyền thuộc địa. Cần làm rõ quan hệ giữa Thống đốc, Varenne và bên trao quyền ở Old Kroy khi phát triển tiếp; không tự bịa một đạo luật, hiệp ước hoặc cơ chế bổ nhiệm đã là canon.
- Các mức “50%”, “50–60% sát sử” AI từng nêu chỉ là ước lượng chủ quan, không có tiêu chí đo. Không tái sử dụng như kết quả nghiên cứu.

## 5. Bối cảnh lore cần giữ và những gì còn là phác thảo

### Dữ kiện quan trọng do người dùng trực tiếp cung cấp

- **La Clôture de Fer** là đội vệ sĩ riêng tinh nhuệ gồm **bốn người**, đích thân Bá tước Obscur lựa chọn. Bảo vệ bá tước, theo dõi mục tiêu, giám sát cấp dưới thi hành lệnh và ám sát là các chức năng đã được trao đổi. Đây là công cụ quyền lực cá nhân của Obscur.
- **Uyển là em gái Hắc**. Cô được lựa chọn nhờ kiếm thuật, khả năng sử dụng Ám thuật, khả năng dùng kiếm đặc biệt, ngoại hình và lễ nghi phù hợp việc theo hầu quý tộc; Obscur cũng trọng dụng cô trong thí nghiệm.
- Kiếm đặc biệt của Uyển: mắt đỏ lớn chuyển động trên bao kiếm, nhiều tròng mắt đỏ nhỏ ở tay cầm; kỹ năng liên quan đến máu, gây tổn hại lớn đến sức khỏe và tâm lý người dùng.
- Varenne là thế lực áp bức trực tiếp ở An Châu, gắn với khai thác tinh thể và bóc lột; có liên hệ hậu thuẫn với Old Kroy. Quan hệ pháp lý cụ thể với Old Kroy còn cần làm rõ.
- Người dùng muốn bộ máy đa chủng tộc, từng nêu mong muốn có ít nhất một Werebeast đại diện một lãnh chúa Kenkyokara. Chưa xác lập chức vụ cho người này trong cơ cấu Thống đốc.
- Người dùng muốn nhấn mạnh **thắng lợi cách mạng thuộc về nhân dân**: hình ảnh hai/ba chiến sĩ bình thường, vô danh phất cờ trên trụ sở; không quy vinh quang cho riêng một thủ lĩnh hay Adel.

### Arc An Châu là bản phác, chưa phải toàn bộ canon

Người dùng nói rõ luồng dài ban đầu là “vừa nghĩ vừa viết”, yêu cầu đánh giá như nhà phát triển game rồi sắp xếp để đồng đội góp ý. Trang đầu DOCX cũng ghi chưa chốt canon. Các mốc dưới đây chỉ giúp định vị nội dung cần đọc:

1. Adel bị chặn ở cửa ngõ; giao dịch với Rat để vào An Châu; gặp Lam khi bảo dưỡng kiếm; bị cách mạng bắt và hỏi về kiếm. Thỏa thuận hợp tác/đổi lấy việc rời An Châu còn chưa chắc.
2. Năm ngày tại mỏ phía đông: ban ngày khai thác tinh thể, chiến đấu và xuống sâu dần; ban đêm làm nhiệm vụ với Hắc/Lam. Lịch đêm: Hắc; Lam; Lam; cả hai; Hắc.
3. Đêm thứ năm ám sát Obscur, Hắc gặp Uyển; hôm sau rời cách mạng để về phía Liên hiệp.
4. Adel chuyển tình báo cho phu nhân Bình qua Rat, rồi hộ tống bà; gặp Hắc vui vẻ bên Uyển và chọn im lặng. Phu nhân Bình lấy cảm hứng Madame Bình, không đồng nhất với nhân vật lịch sử.
5. Rat được hé lộ là liên lạc viên bí mật. Trong phác thảo mới, Rat thực chất là **Human nhiễm Ám thuật, biến dị giống chuột**, không phải Werebeast bẩm sinh. Cống bị tấn công; tìm thấy áo choàng không đủ xác nhận Rat chết. Rat lấy cảm hứng Lượm.
6. Mỏ phía tây bị tấn công; rút về mỏ phía đông; có giai đoạn khám phá tự do trước khởi nghĩa. Kế hoạch phác: 11 giờ mít tinh, 11 giờ 30 tiến công, Adel/Lam đi đường cống để chặn rút lui và giải cứu người bị thí nghiệm.
7. Duo boss Hắc–Uyển nhấn mạnh sự gắn bó anh em. Hắc đỡ đòn cho Uyển; khi cô muốn phản bội Liên hiệp, tinh thể cấy ở tim kích hoạt biến đổi. Dạng corrupted lấy chủ đề hàng rào sắt, giữ cơ thể Hắc bên trong.
8. Lam trọng thương và chết sau khi đưa thiết bị phá khóa; Observe hé lộ việc cô dùng cánh tay máy chế thiết bị và cố che thương tích lúc Adel đến. Đây là thiết kế truyện, không phải xác nhận Observe đã được lập trình.
9. Boss cuối chưa có concept chốt; chiến thắng, phất cờ, rồi nguy cơ từ các lãnh chúa Kenkyokara dẫn đến hành trình tiếp theo.

“Ngày 6”, “ngày 7” ngoài chuỗi năm ngày là mốc tạm sắp xếp trong bản viết lại, không phải lịch đã nghiệm thu độc lập.

### Old Kroy và cách kể chuyện

- Đã trao đổi ý tưởng Adel mang lý tưởng từ An Châu sang Old Kroy, gặp lại phu nhân Bình trong hoạt động ngoại giao, tự chọn đứng lên rồi nhận ra giới hạn của cách hiểu ban đầu.
- Người dùng thích cách kể để người chơi tin mình đúng qua thông tin không đầy đủ, dần nhận ra sai và nhìn lại lựa chọn.
- Người dùng nói đây là ý tưởng tức thời; thiên về giữ tuyến Old Kroy cũ và thử thủ pháp trong truyện phụ/Observe. Việc Adel theo phe lấy cảm hứng Bolshevik chưa được chốt thành tuyến chính.
- Cuộc chat có lần nhắc Arc 3 rồi sửa “4”; không đủ cơ sở từ phần trao đổi đã đọc để tái dựng toàn bộ trục Arc 3/4. Khi cần, đọc nguồn worldbuilding và hỏi đúng phần thiếu thay vì suy ra.

## 6. Việc đã hoàn thành

- Thay năm SmartArt dài của bản cũ bằng sơ đồ chức danh dạng bảng Word chỉnh sửa được, không có mũi tên chỉ huy. Phiên bản đầu vẫn giữ Tổng đại diện/bốn Ủy viên.
- Sau yêu cầu mới, đọc **bản người dùng đang lưu hiện tại**, không lấy bản dựng cũ làm đầu vào. Tạo bản cơ cấu Thống đốc riêng, cập nhật bảy đoạn tổ chức, chức vụ Obscur và sáu tên địa điểm cho thống nhất.
- Sơ đồ mới nằm riêng trên một trang ngang; phần truyện vẫn là trang dọc.
- Kiểm tra nội dung, tính toàn vẹn DOCX, bảo toàn bản gốc; xuất PDF bằng Word và xem đủ chín trang.
- Giao DOCX và yêu cầu ứng dụng mở file. Công cụ báo `queued`; không khẳng định người dùng đã nhìn hoặc duyệt nội dung chỉ dựa trên trạng thái này.
- Bàn giao này chỉ thêm `HANDOFF_lore.md`; không sửa lore, code hoặc tài liệu gốc trong lượt tạo bàn giao.

## 7. File và tài nguyên

### File trong dự án đã xác minh tồn tại

- [Bản An Châu cơ cấu Thống đốc](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/Bản phác luồng cốt truyện Arc 1 An Châu - cơ cấu Thống đốc.docx>): đầu ra mới nhất; **25.520 byte**, SHA-256 `ecb21665efae1c9e20ba77566af2c59b8d88dc901d79bc317e218c36b791cecf`.
- [Bản An Châu gốc đang lưu](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/Bản phác luồng cốt truyện Arc 1 An Châu.docx>): giữ cơ cấu Tổng đại diện/bốn Ủy viên; **28.704 byte**, SHA-256 `8ef652f1b682f3d97302ee82c8f7f4081903749fd8f5c51f8dfd6a0be4d384a9`. Không nhầm file này với bản làm việc mới nhất.
- [Artbook](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/artbook.docx>): **22.770.439 byte**. Đã kiểm tra tồn tại và ZIP hợp lệ trong lượt bàn giao, chưa đọc lại toàn bộ nội dung để xác nhận canon.
- [Phương án 2 về tuyến truyện của Hắc](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/Phương án 2 về tuyến truyện của Hắc.docx>).
- [Concept thiết kế và gameplay loop arc 1](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/Concept thiết kế và gameplay loop arc 1.pdf>).
- [Developerbook](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/developerbook.docx>) và [tham khảo](<D:/Godot Project/soujourn--echoes-of-the-soul/Context/tham khảo.docx>).
- Bốn tài nguyên ngay trên chỉ xác minh vị trí trong lượt bàn giao; nội dung cần đọc trước khi dùng để kết luận hoặc xử lý mâu thuẫn.
- [HANDOFF.md của nhánh kỹ thuật](<HANDOFF.md>): đã có trước lượt này; chỉ dùng khi cần đối chiếu tình trạng triển khai, không xem các kế hoạch trong đó là gameplay đã hoàn thành.

### Bản dựng, bản sao và bằng chứng kiểm tra ngoài repo

Thư mục đầy đủ: `C:/Users/xuank/.codex/visualizations/2026/10/17/01a14849-a8b5-7041-a77b-15937db102a6/`.

- `an_chau_co_cau_thong_doc.docx`: bản dựng khớp byte với đầu ra trong Context.
- `an_chau_before_governor_20261024.docx`: bản sao đầu vào ngay trước lần đổi Thống đốc; khớp byte với bản An Châu gốc trên đĩa.
- `update_governor_structure.py`: script của lần đổi Thống đốc; đầu vào được cố định trong script. Chỉ dùng để hiểu phép sửa; kiểm tra thay đổi của người dùng trước khi chạy lại.
- `governor_qa/governor_layout.pdf`: PDF kiểm tra chín trang.
- `governor_qa/final-page-1.png` đến `final-page-9.png`: ảnh kiểm tra; trang 6 kiểm chứng bổ sung bằng `page6-check.png` ở kích thước 1600.
- `edit_varenne_diagram.py`, `ban_phac_an_chau_diagram_edited.docx`, `ban_phac_an_chau_before_diagram_edit.docx`: lịch sử lần chỉnh sơ đồ đầu tiên, đã lỗi thời đối với cơ cấu Thống đốc.
- Các PDF/PNG/script là tài nguyên QA, không phải đầu ra cần tự động gửi lại cho người dùng.

### Tài nguyên từng được người dùng cung cấp, đã xác minh đường dẫn

- Master prompt cũ: `C:/Users/xuank/.codex/attachments/95745e6c-49b0-4132-b4fb-cf22ce1039cf/Pasted text.txt` — 51.909 byte.
- Văn bản tham khảo Koschei: `C:/Users/xuank/.codex/attachments/ef244bcb-bb32-4ac8-9ac2-4f5d13f2aeb3/Pasted text.txt` — 8.118 byte.
- Terra artbook: `D:/Downloads/Terra, a Journey/Terra, A Journey, Complete.pdf` — 923.698.222 byte; rất lớn, chỉ đọc phần liên quan khi cần.
- Terra chú giải: `D:/Downloads/Terra, a Journey/Terra Book Annotations.txt` — 50.164 byte.
- Trong lượt bàn giao chỉ kiểm tra tồn tại/kích thước bốn file này, không đọc lại toàn văn. Chúng là lịch sử/nguồn cảm hứng, không tự trở thành canon Soujourn hoặc nhiệm vụ dịch đang chờ.

### Nguồn lịch sử đã dùng và mức độ đọc

- [Trung tâm Lưu trữ quốc gia I — Sắc lệnh thành lập Hội đồng thuộc địa Nam Kỳ](https://www.archives.org.vn/gioi-thieu-tai-lieu-nghiep-vu/gioi-thieu-sac-lenh-thanh-lap-hoi-dong-thuoc-dia-nam-ky.htm): đã đọc nội dung trang, văn bản giới thiệu/lược dịch Sắc lệnh 1880. Hữu ích để phân biệt Thống đốc với các hội đồng và đại diện lợi ích; không chứng minh bảng chức danh Varenne hiện tại.
- [Phông Phủ Thống đốc Nam Kỳ 1858–1945](https://vietphap.luutru.gov.vn/tructuyen/UPLOADS/SachchidanPhong/Sach%20Phong%20Phu%20Thong%20doc%20Nam%20Ky%20%2811-3-2015%29.pdf): đọc đoạn trích từ kết quả tìm kiếm về cai trị trực tiếp, tổ chức năm 1909 và thay đổi sau đó. Mở toàn bộ PDF qua web bị timeout; chưa thể ghi đã đọc hết tài liệu.
- [Tài liệu lưu trữ Việt–Pháp](https://vietphap.luutru.gov.vn/tructuyen/ttlt.aspx?idCQ=1): dùng mô tả phông/cơ quan từ kết quả tìm kiếm; có lần mở trang gặp 502.
- [Nghiên cứu của Trần Nam Tiến về Liên bang Đông Dương qua phông Phủ Thống đốc](https://luutruvn.com/to-chuc-va-hoat-dong-cua-lien-bang-dong-duong-qua-nguon-tai-lieu-phong-phu-thong-doc-nam-ky/): đã đọc trang; là nghiên cứu thứ cấp có dẫn tài liệu, không phải bản gốc nghị định.
- [Lịch sử Việt Nam tập 8](https://thuvientinh.quangngai.gov.vn/wp-content/uploads/2020/12/Lich-su-Viet-Nam-tap-8.pdf): đoạn trích trang sách 72 về văn phòng cấp xứ và Chánh văn phòng. Chưa đọc toàn bộ sách; số trang sách có thể khác số trang PDF.
- [Trung tâm Lưu trữ quốc gia I — Lưu trữ Việt Nam thời kỳ 1945–1946](https://www.archives.org.vn/luu-tru-viet-nam-thoi-ky-1945-1946.htm): đã đọc trang, dùng đối chiếu bối cảnh sau Nhật đảo chính Pháp và tên Phủ Khâm sai năm 1945.
- [Bảo tàng Lịch sử Quốc gia — Võ Nguyên Giáp qua tài liệu lưu trữ](https://baotanglichsu.vn/VI/Articles/3097/72454/djai-tuong-vo-nguyen-giap-va-cuoc-van-djong-tien-toi-thang-loi-cua-tong-khoi-nghia-thang-8-1945-qua-cac-nguon-tai-lieu-luu-tru.html): tìm thấy chức danh Chánh mật thám; không đủ xác nhận toàn bộ cấp bậc an ninh.
- [Văn kiện Đảng toàn tập, tập 3](https://thuviendientu.laichau.gov.vn/upload/admin/images/1/files/lowres_SachBacHoVaCacTongBiThu/PD36180Vankienangtoantapquyen3.pdf): đoạn trích có từ “cai phu”; chỉ hỗ trợ cách gọi, không chứng minh quan hệ cấp bậc trong mỏ.
- Nguồn tìm thấy để nghiên cứu tiếp, **chưa đọc toàn văn**: [văn bản ngày 20/10/1911](https://data.decalog.net/enap1/Liens/fonds/F10E1.PDF), kết quả tìm kiếm có thành phần Hội đồng Tư mật/Bảo hộ và các chức chuyên môn. Cần mở, xác định xuất xứ và đọc ngữ cảnh trước khi dùng.

Các danh xưng có thật không tự chứng minh các chức đó cùng tồn tại, cùng cấp hoặc cùng quan hệ tại một thời điểm. Khi đối chiếu, chọn rõ xứ, năm và văn bản tổ chức.

## 8. Kết quả kiểm tra và cách đã thử không thành công

### Xác minh lại khi tạo bàn giao

- Hai DOCX An Châu đều mở được dưới dạng ZIP, kiểm tra CRC không có lỗi.
- Bản cơ cấu Thống đốc vẫn khớp byte với bản dựng đã render; bản gốc vẫn khớp bản sao trước lần sửa. Các hash ở mục 7 là mốc để chat mới phát hiện thay đổi sau bàn giao.
- Đọc lại XML bản mới: không còn Tổng đại diện, bốn Ủy viên hoặc Phủ Khâm sai; có Thống đốc, các Giám đốc Sở và Phủ Thống đốc đúng với bản giao.
- PDF QA có **chín trang**, mỗi trang đều có nội dung văn bản: tám trang dọc 612 × 792 pt, trang cuối ngang 792 × 612 pt. Không phải vừa render lại trong lượt bàn giao; đây là xác minh lại PDF của lượt sửa trước.
- Đã thấy file khóa Word tương ứng bản cơ cấu Thống đốc. Chưa kiểm tra thay đổi chưa lưu trong Word.

### Kiểm tra thực sự đã chạy ở lượt chỉnh Word trước

- Script kiểm tra phần truyện đầu tài liệu chỉ đổi tên địa điểm Phủ Khâm sai → Phủ Thống đốc; không viết lại diễn biến.
- Chỉ phần `word/document.xml` thay đổi trong gói DOCX; các phần khác giữ nguyên.
- Word mở bản dựng read-only, phân trang và xuất PDF thành công; đã xem ảnh đủ chín trang, không thấy tràn bảng hoặc thiếu chức danh ở sơ đồ.
- Không chạy game, không sửa scene/script Godot và không kiểm thử chức năng Observe hay quest. QA tài liệu không phải nghiệm thu gameplay hoặc thẩm định sử học.

### Cách thử thất bại và cách xử lý

- `render_docx.py` không xuất được tài liệu vì không có `LibreOffice soffice.exe` trên PATH; dọn thư mục tạm còn báo Access denied. Không lặp lại cùng cách một cách mù quáng. Đã dùng Word cài sẵn mở ẩn/read-only để xuất PDF, rồi Poppler để tạo PNG.
- Word COM từng gặp `E_ACCESSDENIED` trong sandbox quyền thường; các lần xuất bằng quyền được công cụ cho phép sau đó thành công. Chưa gặp từ chối của cơ chế duyệt tự động trong công việc này.
- Bản dựng đầu lượt đổi Thống đốc có **mười trang**, trang 9 trống do giữ thêm ngắt section cũ. Đã loại bỏ ngắt section trống dư và giữ một section dọc cho truyện, một section ngang cho sơ đồ; kết quả còn chín trang.
- Một số ảnh trang 6 ở kích thước render khác hiển thị thiếu đầu hai dòng đầu trang. Render Poppler với `-scale-to 1600` cho ảnh `page6-check.png` hiển thị đủ. Không kết luận mất nội dung DOCX chỉ từ ảnh lỗi đó.
- Cách làm nội dung trước đây chưa đạt yêu cầu lịch sử: chọn chức danh có thật rồi tự xếp quyền lực. Đã thừa nhận với người dùng. Lần sau phải chứng minh cơ cấu và thẩm quyền, đồng thời đánh dấu phần phỏng tác riêng cho Varenne.

### Công cụ có thể cần khi tiếp tục DOCX

- Skill: `C:/Users/xuank/.codex/plugins/cache/openai-primary-runtime/documents/26.1022.11436/skills/documents/SKILL.md`.
- Python đã dùng: `C:/Users/xuank/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
- Node đã dùng: `C:/Users/xuank/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe`.
- Poppler đã dùng: `C:/Users/xuank/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/poppler/Library/bin/pdftoppm.exe`.
- Lấy lại đường dẫn qua công cụ tải workspace dependencies nếu môi trường thay đổi. Đọc skill, render và xem ảnh trước khi giao bản DOCX sửa tiếp.

## 9. Việc dang dở và bước tiếp theo

1. **Kiểm tra đầu vào hiện tại:** so sánh hash/trạng thái đã lưu với mục 7; đọc bản Thống đốc và các sửa tay mới trước khi thao tác. Nếu có khác biệt, giữ thay đổi người dùng và xác định bản làm việc hiện hành.
2. **Đối chiếu lịch sử có phạm vi:** khi tiếp tục cơ cấu Varenne, chọn một mốc cụ thể, ưu tiên mô hình Nam Kỳ vì bản hiện hành chọn Thống đốc. Thu thập nguồn tổ chức/phân quyền trước khi sửa các tầng chuyên môn; không gán thêm một tỷ lệ “sát sử” thiếu thước đo.
3. **Tách các loại quyền lực:** xác định chức hành chính nhà nước, ngành chuyên môn, quản trị doanh nghiệp, lực lượng vũ trang và hội đồng tư vấn/đại diện lợi ích. Sau đó mới quyết định chức nào phù hợp cùng tầng trong game. Xem lại vị trí Sở Mỏ, Giám đốc nhà máy, Kỹ sư trưởng, thanh tra và bảo an.
4. **Giữ nguồn gốc lựa chọn rõ ràng:** báo ngắn phần nào nguồn lịch sử xác nhận, phần nào là thích ứng cho An Châu. Việc gán Obscur vào Sở Liêm phóng, chọn Thống đốc và vị trí đại diện Kenkyokara cần được trình bày đúng trạng thái làm việc, không suy thành các điều đã được người dùng duyệt riêng.
5. **Khi được yêu cầu sửa tiếp:** chỉnh bản sao/bản làm việc hiện hành, cập nhật tên chức xuyên suốt đúng phạm vi, giữ sơ đồ chỉ có chức danh, kiểm tra render rồi giao DOCX. Không tự thay đổi tuyến nhân vật hoặc đoạn kết vì thấy cơ cấu hành chính đổi.
6. **Nếu chuyển sang phát triển truyện:** đọc artbook và tài liệu tuyến Hắc khi liên quan; dùng mục 5 làm chỉ dẫn đến bản phác. Các khoảng trống lớn hiện được ghi trong DOCX gồm động cơ hợp tác của Adel, động cơ Hắc, logic các cuộc tấn công, thiết kế boss cuối và cơ sở chuyến đi Kenkyokara.

## 10. Trạng thái workspace cần bảo toàn

Git đọc ở lượt bàn giao cho thấy có thay đổi có sẵn ở `project.godot`, scene Adel, scene enemy; nhiều tài liệu/asset chưa được theo dõi; `Context/Phương án triển khai Arc 1.docx` bị đánh dấu xóa. Chưa xác định tác giả hay đánh giá các thay đổi này. Không khôi phục file bị xóa, reset, commit hoặc push chỉ vì tiếp quản lore.

`HANDOFF.md` có trước được giữ nguyên. SHA-256 trước khi viết bàn giao lore: `7d3295d2a025c9adb328414fd5c4b500f8fa834f8f0d3c8f50201b0c9ae38e54`.

Phạm vi hoàn thành của lượt bàn giao: tạo và kiểm tra `HANDOFF_lore.md`, cung cấp lời nhắn để người dùng tự chuyển sang chat mới. Chưa tạo chat mới hoặc gửi tin sang chat khác.
