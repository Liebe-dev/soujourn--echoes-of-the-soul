# Bàn giao lore Soujourn Echoes of the Soul

Ngày cập nhật và kiểm tra file **06/11/2026**, múi giờ **Asia/Saigon**. Các kết quả ngày 24/10 bên dưới được ghi theo bản đã kiểm tra khi đó.

Thư mục dự án: `D:/Godot Project/soujourn--echoes-of-the-soul`.

Đây là bàn giao nhánh **cốt truyện, worldbuilding và cơ cấu cai trị Varenne tại An Châu**. Bản Word Thống đốc hiện nằm trong `Context/Tai_lieu_cot_truyen/` và đã thay đổi sau bản giao 24/10. Tài liệu đối chiếu Varenne đã có kết quả về mốc 1911 và đề xuất phân quyền. Hai lượt trao đổi tiếp theo bổ sung tước quý tộc và chính quyền Việt Nam khoảng 1930–1945. Cơ cấu pháp lý của Varenne và các tầng chức vụ vẫn chờ quyết định.

## 1. Bắt đầu ở đây

1. Đọc [AGENTS.md](AGENTS.md) trong thư mục bàn giao và kiểm tra Git cùng các file liên quan. Dùng vị trí và SHA-256 ở mục 7 để nhận biết thay đổi sau 06/11.
2. Đọc [bản An Châu cơ cấu Thống đốc](<../Tai_lieu_cot_truyen/Bản phác luồng cốt truyện Arc 1 An Châu - cơ cấu Thống đốc.docx>) và mục 3–5. Đây là bản phác đang dùng để trao đổi. Mục 3 phân biệt yêu cầu trực tiếp, lựa chọn của AI và các quyết định còn mở.
3. Khi tiếp tục về cơ cấu, đọc [đối chiếu lịch sử Varenne](co_cau_Varenne_doi_chieu_lich_su.md), phần tra cứu bổ sung ở mục 7 và các bước ở mục 9. Dùng mục 7 của bản bàn giao để tìm DOCX vì một số liên kết trong tài liệu đối chiếu vẫn theo vị trí cũ.
4. Báo ngắn những điểm khác với snapshot này, rồi tiếp tục phần người dùng yêu cầu. Khi cần kiểm tra Observe hoặc tình trạng triển khai game, chuyển sang [bàn giao kỹ thuật](HANDOFF.md) và đặc tả hiện hành.

## 2. Mục tiêu và cách làm việc

- Vai trò: cố vấn cốt truyện, worldbuilding và nhà phát triển game cho **Soujourn: Echoes of the Soul**. Giai đoạn chỉ tiếp nhận thông tin đã kết thúc theo yêu cầu người dùng.
- Người dùng muốn một thế giới có chiều rộng, chiều sâu, quan hệ nhân quả và lịch sử liên kết; các sự kiện diễn ra vì động lực của thế giới, không chỉ xoay quanh Adel. Terra/Arknights là nguồn cảm hứng rõ rệt.
- Người dùng muốn tự ngẫm và viết chiều sâu nhân vật, cách mạng, triết học, vật phẩm và môi trường. Hỗ trợ bằng nhận xét, câu hỏi, tài liệu tham khảo; viết lại/sắp xếp khi được yêu cầu cụ thể.
- Giao tiếp bằng tiếng Việt, ngắn, rõ, phản biện có căn cứ. Không biến đề xuất của AI thành canon bằng cách lặp lại như sự thật.
- Phân biệt tài liệu đính kèm với yêu cầu hiện hành. Master prompt và các văn bản cũ là nguồn cần đọc trong bối cảnh; yêu cầu mới của người dùng có ưu tiên.
- Dùng hướng dẫn dự án hiện hành trong [AGENTS.md](AGENTS.md). Phân biệt thiết kế truyện, tài liệu yêu cầu gameplay và kết quả đã chạy. Lần chỉnh Word trước tạo bản riêng để đối chiếu với bản gốc.

## 3. Yêu cầu đã chốt và lựa chọn chưa chốt riêng

### Yêu cầu trực tiếp của người dùng

- Sơ đồ thể hiện **phân tầng quyền lực từ cao xuống thấp**, không phải chuỗi chỉ huy. Chức có quyền lực thấp hơn không mặc nhiên nhận lệnh từ mọi chức ở tầng trên.
- Sơ đồ ngắn, chỉ tên chức danh, không chèn mô tả nhiệm vụ trong từng ô.
- Cơ cấu cần tham khảo **bộ máy cai trị Pháp tại Việt Nam thời Pháp thuộc**, không chỉ dùng tên chức nghe cổ.
- Yêu cầu chỉnh cơ cấu đã thực hiện trong bản Word là **đổi Tổng đại diện và bốn Ủy viên sang mô hình dùng Thống sứ, Khâm sứ hoặc Thống đốc**.
- Người dùng chọn **`Context/Tai_lieu_ban_dao/`** làm thư mục dành cho các đợt bàn giao AI. Lượt 06/11 yêu cầu cập nhật bản lore tại chỗ và soạn lời nhắn để người dùng gửi vào chat mới.

### Lựa chọn AI đã thực hiện trong bản Word mới nhất

- Chọn **Thống đốc An Châu**, diễn giải theo mô hình cai trị trực tiếp ở Nam Kỳ. Người dùng cho phép lựa chọn giữa ba chức danh nhưng chưa xác nhận riêng lý do chọn Thống đốc.
- Thay bốn Ủy viên bằng các chức đứng đầu ngành chuyên môn.
- Chuyển Obscur từ Ủy viên An ninh sang **Giám đốc Sở Liêm phóng**.
- Thay sáu chỗ `Phủ Khâm sai` bằng `Phủ Thống đốc` để tên địa điểm thống nhất với chức đứng đầu.
- Đổi Tổng thư ký thành **Chánh văn phòng**, bỏ tầng Giám đốc sở chung chung bị trùng với các chức đứng đầu sở mới.

Những lựa chọn trên đã được ghi vào bản chỉnh sửa và giao cho người dùng ngày 24/10. Đến lượt bàn giao 06/11, chưa thấy xác nhận riêng về từng chức danh hoặc về toàn bộ lore trong bản phác.

### Đề xuất và câu hỏi còn mở sau đối chiếu

- Phương án AI ưu tiên để thảo luận là **Thống đốc đứng đầu chính quyền An Châu, Varenne là liên hiệp công nghiệp hưởng đặc quyền**. Phương án Varenne trực tiếp nhận quyền cai trị vẫn để mở. Cơ chế trao quyền, bổ nhiệm và trách nhiệm trước Old Kroy cần người dùng quyết định.
- Nếu giữ Obscur làm Giám đốc Sở Liêm phóng, tách **tước Bá tước**, **thẩm quyền của chức vụ** và **quyền lực cá nhân qua La Clôture de Fer**. Chức vụ và vị trí đại diện Kenkyokara vẫn là phương án. Phần tra cứu tước vị và chính quyền người Việt phục vụ tham khảo, chưa thiết lập hệ tước Old Kroy hoặc một bộ máy bản xứ riêng cho An Châu.

## 4. Trạng thái cơ cấu hiện nằm trong bản Word

Đã đối chiếu bảng trong **bản lưu ngày 06/11** với bản dựng 24/10. Năm hàng và chữ trong các ô khớp nhau. Đây là các tầng của bản phác Varenne. Việc xác định thẩm quyền, quan hệ chỉ huy và căn cứ lịch sử cho từng chức còn ở mục 9.

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
- Đã giao DOCX và gửi yêu cầu mở file trong ứng dụng. Công cụ trả về `queued`. Trạng thái xem và nghiệm thu của người dùng chưa được xác nhận.
- Hoàn thành một lượt đối chiếu lịch sử mốc **20/10/1911** và ghi các phương án phân quyền trong [đối chiếu lịch sử Varenne](co_cau_Varenne_doi_chieu_lich_su.md). Đã rà phần liên quan của artbook, phương án tuyến Hắc và concept Arc 1. Artbook có các cách xử lý Hắc–Uyển, Lam và boss cuối khác bản phác Thống đốc. Chi tiết các khác biệt nằm trong tài liệu đối chiếu.
- Đã chuyển tài liệu bàn giao lore và đối chiếu Varenne vào `Context/Tai_lieu_ban_dao/` theo đường dẫn người dùng đính chính. Lượt 06/11 rà lại đường dẫn sau khi repo sắp xếp thêm thư mục tài liệu cốt truyện.
- Đã trả lời hai câu hỏi tham khảo về tước quý tộc và chính quyền Việt Nam cùng giai đoạn cảm hứng của Arc 1. Nguồn và phạm vi nằm ở mục 7. Chưa có yêu cầu áp các nội dung trao đổi đó vào bản Word.

## 7. File và tài nguyên

### File trong dự án đã xác minh tồn tại

- [Bản An Châu cơ cấu Thống đốc](<../Tai_lieu_cot_truyen/Bản phác luồng cốt truyện Arc 1 An Châu - cơ cấu Thống đốc.docx>) là bản phác Word tìm thấy trong repo ngày 06/11. Kích thước **28.424 byte**, SHA-256 `dbfbd876978038078deb437e0029bd1f32b40f50de69c56691be6d01217b9603`. Hash ngày 24/10 nằm ở phần bản dựng cũ bên dưới.
- Bản tên `Bản phác luồng cốt truyện Arc 1 An Châu.docx` với Tổng đại diện và bốn Ủy viên từng nằm trong `Context/`. Hiện chưa tìm thấy bản mang tên đó trong cây làm việc. Bản sao trước khi đổi cơ cấu vẫn còn trong thư mục QA bên dưới.
- [Artbook](../Tai_lieu_cot_truyen/artbook.docx) có **22.770.445 byte**, SHA-256 `9096e223494973861e24d6e6bdc0b1cbaa09d7b2105777148c09ac5c8b523394`. So với văn bản trích xuất ngày 24/10, có thay đổi ở ghi chú cảm hứng văn hóa của Hallow. Phần chữ đã đối chiếu không cho thấy thay đổi ở đoạn Arc 1. Toàn bộ hình ảnh và bố cục chưa được rà lại.
- [Phương án 2 về tuyến truyện của Hắc](<../Tai_lieu_cot_truyen/Phương án 2 về tuyến truyện của Hắc.docx>) và [concept thiết kế và gameplay loop Arc 1](<../Tai_lieu_cot_truyen/Concept thiết kế và gameplay loop arc 1.pdf>) là các bản tham khảo khi đối chiếu động cơ Hắc và luồng nhiệm vụ. [Danh mục tham khảo](<../Tai_lieu_cot_truyen/tham khảo.docx>) là danh sách đọc.
- [Đối chiếu lịch sử Varenne](co_cau_Varenne_doi_chieu_lich_su.md) lưu mức đọc từng nguồn, so sánh thể chế và đề xuất chức năng. Các hash và đường dẫn DOCX được ghi trong phần kiểm kê của file đó thuộc snapshot 24/10. Dùng các đường dẫn hiện tại trong mục này để mở tài liệu.
- [Log nội dung](<../Log nội dung.docx>) ghi nhận nhóm còn cần thống nhất bản cốt truyện và các điểm như động cơ Adel, lựa chọn của Hắc, kết cục Hắc–Uyển, đoạn cuối của Lam, vai trò Varenne và boss cuối. [Đề xuất tái tổ chức 1.0](<../Đề xuất tái tổ chức 1.0.docx>) bàn về phân công nhóm. Hai file giúp định vị công việc và quyết định cần trao đổi.
- [Developerbook](../developerbook.docx) và [HANDOFF.md kỹ thuật](HANDOFF.md) dùng khi cần đối chiếu phần triển khai. [Yêu cầu Observe hạn 13/11/2026](<../Bao_cao_ky_thuat/Requirement Observe hạn 13-11-2026.docx>) là đặc tả gameplay riêng. Phần Observe của Lam ở mục 5 là thiết kế truyện. Bàn giao kỹ thuật ghi kết quả tra cứu và phần chưa nghiệm thu theo các nhóm OBS, HUD, AI và DBG.

### Bản dựng, bản sao và bằng chứng kiểm tra ngoài repo

Thư mục đầy đủ: `C:/Users/xuank/.codex/visualizations/2026/10/17/01a14849-a8b5-7041-a77b-15937db102a6/`.

- `an_chau_co_cau_thong_doc.docx` là bản dựng và giao ngày 24/10, **25.520 byte**, SHA-256 `ecb21665efae1c9e20ba77566af2c59b8d88dc901d79bc317e218c36b791cecf`. PDF và ảnh bên dưới thuộc bản này.
- `an_chau_before_governor_20261024.docx` là bản sao trước lần đổi Thống đốc, **28.704 byte**, SHA-256 `8ef652f1b682f3d97302ee82c8f7f4081903749fd8f5c51f8dfd6a0be4d384a9`. Có thể đọc để đối chiếu cơ cấu gốc và phần truyện trước chỉnh sửa.
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
- Đã đọc phần nội dung được lập chỉ mục của [cụm sắc lệnh ngày 20/10/1911](https://data.decalog.net/enap1/Liens/fonds/F10E1.PDF) và [bản chép quy định về Toàn quyền](https://mjp.univ-perp.fr/constit/vn1887.htm). Các đoạn dùng được phân biệt `directeur des bureaux` với `chef de cabinet`, ghi nhận chức đứng đầu Công chính trong Hội đồng Tư mật và phân biệt quyền yêu cầu quân lực với quyền chỉ huy tác chiến. Chưa đối chiếu ảnh bản gốc, chưa có niên giám đủ để xác nhận Sở Mỏ, Liêm phóng hoặc các tầng bên trong doanh nghiệp. Xem mức đọc và số điều tại [bản đối chiếu](co_cau_Varenne_doi_chieu_lich_su.md).

Các danh xưng có thật không tự chứng minh các chức đó cùng tồn tại, cùng cấp hoặc cùng quan hệ tại một thời điểm. Khi đối chiếu, chọn rõ xứ, năm và văn bản tổ chức.

### Tra cứu bổ sung về tước vị và chính quyền Việt Nam

- Trong hệ quý tộc Anh, thứ tự tham chiếu là **Công, Hầu, Bá, Tử, Nam**. Các tên Pháp tương ứng là *duc, marquis, comte, vicomte, baron*. *Lord* có thể là cách gọi nhiều bậc, còn *Sir* dùng trong hệ danh hiệu riêng tùy ngữ cảnh. Từ “huân tước” trong bản dịch cần xem từ gốc. [Thư viện Quốc hội Anh](https://commonslibrary.parliament.uk/research-briefings/cbp-10635/) · [Từ điển Hán Nôm](https://hvdic.thivien.net/hv/hu%C3%A2n%20t%C6%B0%E1%BB%9Bc) · [Académie française về hầu tước](https://www.dictionnaire-academie.fr/article/A9M1193) · [Hoàng gia Anh về phong hiệp sĩ](https://www.royal.uk/knighthoods-and-damehoods)
- Mốc **1930–1945** được dùng làm khung tham chiếu trong trao đổi về An Châu. Mốc **1911** là lát cắt pháp quy của lượt tra cứu trước. Niên đại nội tại của game và mẫu thể chế sẽ áp dụng vẫn để mở.
- Trước cuộc đảo chính tháng 3/1945, dưới Toàn quyền Đông Dương có **Thống sứ Bắc Kỳ, Khâm sứ Trung Kỳ và Thống đốc Nam Kỳ**. Bắc và Trung Kỳ là xứ bảo hộ, Nam Kỳ là thuộc địa trực trị. Cần chọn kỳ khi đối chiếu mức tham gia của quan lại người Việt. [Trung tâm Lưu trữ quốc gia I về địa giới thuộc địa](https://www.archives.org.vn/gioi-thieu-tai-lieu-nghiep-vu/ky-ii-dia-gioi-hanh-chinh-viet-nam-thoi-ky-thuoc-dia-phap.htm)
- Triều Bảo Đại tại Huế tiếp tục xử lý công việc trong phạm vi chịu sự chi phối của chính quyền bảo hộ. Đợt cải tổ **2/5/1933** có bổ nhiệm các Thượng thư và sung Viện Cơ mật. Ở địa phương có các chức như Tổng đốc, Tuần phủ, Tri phủ, Tri huyện, Tri châu, Chánh tổng, Lý trưởng, tùy nơi và thời điểm. Tôn Thất Đàn từng là Thượng thư Bộ Hình và được phong **Phò Nhơn nam** năm 1933, một ví dụ về chức quan và tước phong cùng xuất hiện trong hồ sơ một người. [Hồi ký và Dụ cải tổ 1933](https://archives.org.vn/gioi-thieu-tai-lieu-nghiep-vu/tu-hoi-ky-cua-mot-cuu-dai-than-he-mo-nhieu-tham-cung-bi-su-trieu-nguyen-ky-2-he-mo-nhieu-tham-cung-bi-su-trieu-nguyen.htm) · [Tư liệu về Tôn Thất Đàn](https://www.archives.org.vn/tu-hoi-ky-cua-mot-cuu-dai-than-he-mo-nhieu-tham-cung-bi-su-trieu-nguyen-ky-1-ton-that-dan-va-hoi-ky-%E2%80%9Clac-vien-tieu-su%E2%80%9D.htm)
- Dùng **9/3/1945** làm điểm tách khi tra tổ chức thời chiến. Chính phủ Trần Trọng Kim và tên Phủ Khâm sai thuộc giai đoạn sau Nhật đảo chính Pháp. Cách mạng Tháng Tám lại mở một giai đoạn khác. [Bảo tàng Lịch sử Quốc gia về Chính phủ Trần Trọng Kim](https://baotanglichsu.vn/VI/Articles/3097/19449/su-thanh-lap-chinh-phu-tran-trong-kim-1945.html)

## 8. Kết quả kiểm tra và cách đã thử không thành công

### Xác minh trên đĩa ngày 06/11/2026

- Kiểm tra ZIP/CRC thành công với bản Thống đốc trên đĩa, artbook, bản tuyến Hắc và các bản sao Word An Châu dùng để đối chiếu. Hash bản Thống đốc hiện hành khác bản dựng cũ. Đọc XML thấy bảng vẫn có cùng năm hàng và chữ trong từng ô. Hai thay đổi văn bản là bỏ tiêu đề “Phân tầng quyền lực tại An Châu” trên bảng và chuyển dòng nguồn xuống dưới bảng.
- Bản hiện hành vẫn có một section dọc và một section ngang theo XML. Chưa render phiên bản 28.424 byte nên số trang và bố cục trực quan của phiên bản này chưa được xác nhận. PDF chín trang và chín PNG QA hiện còn trên đĩa và thuộc bản dựng 25.520 byte.
- Lần tìm 06/11 chỉ thấy một DOCX phác luồng An Châu trong repo. Chưa thấy file khóa Word tương ứng. Việc kiểm tra giới hạn ở phiên bản đã lưu trên đĩa. Ngày 24/10 từng gặp file khóa và đã đọc bản lưu qua chế độ chia sẻ.
- Đã đối chiếu đường dẫn tài liệu trong mục 7 và kiểm tra các tài nguyên ngoài repo được liệt kê. Kiểm tra game, quest, Observe và boss thuộc lượt kỹ thuật riêng. Lượt bàn giao này đối chiếu tài liệu và cấu trúc file.

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
- Bản quét ENAP và một số tài liệu Việt–Pháp từng gặp timeout hoặc lỗi 502. Các kết quả 1911 được giới hạn ở phần văn bản lập chỉ mục và mô tả phông. Nếu cần xác nhận chi tiết, tìm ảnh trang công báo hoặc niên giám theo số điều và mốc đã ghi trong bản đối chiếu.
- Ban đầu đặt thư mục bàn giao ở gốc dự án. Người dùng đính chính đích là `Context/Tai_lieu_ban_dao/`, nơi đã có tài liệu khác. Đã chuyển hai file vào thư mục có sẵn và bỏ thư mục trống ở gốc. Việc sắp xếp tài liệu cốt truyện sau đó khiến một số liên kết trong bản đối chiếu 24/10 lỗi thời. Mục 7 ghi lại vị trí hiện hành.

### Công cụ có thể cần khi tiếp tục DOCX

- Dùng skill `documents:documents` và công cụ `load_workspace_dependencies` để lấy đường dẫn hiện hành của runtime. Lượt 06/11 dùng bundle **26.1104.12130** để đọc ZIP/XML. Runtime từng chuyển vị trí giữa các lượt. Khi giao bản DOCX sửa tiếp, render và kiểm tra ảnh của đúng phiên bản sẽ giao.

## 9. Việc dang dở và bước tiếp theo

1. So sánh file đã lưu với mốc 06/11 ở mục 7, đọc bản Thống đốc hiện hành và báo rõ phần khác bản bàn giao. Giữ các chỉnh sửa đã có làm đầu vào cho lượt tiếp theo.
2. Nếu tiếp tục cơ cấu, làm rõ **Varenne là liên hiệp hưởng đặc quyền hay chủ thể trực tiếp cai trị**, bên nào trao quyền và Thống đốc chịu trách nhiệm trước ai. Sau đó xác định phần hành chính, doanh nghiệp, lực lượng vũ trang, quyền lực cá nhân và đại diện lợi ích. Đặt Obscur và đại diện Kenkyokara theo phạm vi quyền đã xác định.
3. Nếu cần sát sử hơn, chọn một kỳ và một năm cụ thể. Có thể bắt đầu với Nam Kỳ trước 9/3/1945 để đối chiếu lựa chọn Thống đốc. Dùng mốc 1911 làm căn cứ trước đó rồi tìm công báo hoặc niên giám của năm chọn. Chỉ xếp các chức vào tầng cụ thể sau khi nêu được phạm vi công việc, thẩm quyền và phần phỏng tác. Cần xác minh thêm Sở Mỏ, Liêm phóng, thanh tra, bảo an và các chức trong xí nghiệp.
4. Khi người dùng yêu cầu sửa Word, dùng bản làm việc hiện hành hoặc tạo bản riêng nếu cần so sánh. Cập nhật tên chức xuyên suốt phạm vi đã chốt. Sơ đồ giữ chức danh trong ô, theo tầng quyền lực. Render và kiểm tra phiên bản sẽ giao.
5. Nếu tiếp tục truyện, đọc phần liên quan của artbook và phương án tuyến Hắc. Dùng mục 5 và [Log nội dung](<../Log nội dung.docx>) để định vị các câu hỏi về động cơ Adel, quyết định của Hắc, kết cục Hắc–Uyển, đoạn cuối của Lam, boss cuối và chuyến đi Kenkyokara. Đối chiếu các phương án với yêu cầu mới nhất của người dùng trước khi viết tiếp.

## 10. Trạng thái workspace cần bảo toàn

Lúc kiểm tra 06/11, nhánh là `main`, HEAD `7044905`. Git ghi nhận thay đổi có sẵn ở các bản bàn giao kỹ thuật và animation, cùng các chỉnh sửa hoặc xóa ở scene/script và test. `Context/Phương án triển khai Arc 1.docx` đã xuất hiện trong lịch sử commit dưới trạng thái xóa ở `bdff79c`. Giữ các thay đổi ngoài phạm vi lore khi tiếp quản và đọc lại `git status` trước mọi chỉnh sửa.

Lượt 06/11 cập nhật tài liệu này và chuẩn bị lời nhắn để người dùng tự gửi vào chat mới. Bản đối chiếu lịch sử giữ giá trị như bản ghi nghiên cứu của lần 24/10. Mục 7 ở đây là nơi tra các đường dẫn và hash mới nhất đã kiểm tra.
