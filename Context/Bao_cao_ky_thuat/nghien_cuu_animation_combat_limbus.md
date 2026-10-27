# Nguồn nghiên cứu animation combat Limbus Company

Ngày khảo sát: 25/10/2026. Phạm vi: ghi chú nghiên cứu cho bốn đòn `saber_attack_1/2/3/4` của Adel; chưa thay đổi code, scene, animation hoặc VFX của game.

## Kết quả quan sát trực tiếp và hướng áp dụng cho Adel

Phần này bổ sung sau bước tìm nguồn bên dưới. Đã mở video gốc trên YouTube, dừng tại các đoạn ghi rõ dưới đây và dùng phím tiến khung hình của player để đối chiếu các ảnh liên tiếp. Đây là khảo sát các đoạn combat, không phải tuyên bố đã xem trọn mọi video hoặc giải mã bộ điều khiển của Project Moon. Các số bước tiến của player không được quy đổi thành số frame tác giả vẽ hay thời lượng hit-stop. Video có thể chứa dựng trailer và thay đổi tốc độ trong game.

### Các đoạn đã trực tiếp xem

- **Sinclair, Crimson God:** [preview chính thức, khoảng 1:44–1:45](https://www.youtube.com/watch?v=Gpj-lvOnAgs&t=104s). Cung chém đỏ lớn thay đổi hình dáng và cường độ qua các ảnh kế tiếp; điểm sáng va chạm ở mục tiêu có hình riêng. Silhouette hành động của nhân vật ít thay đổi hơn phần cung và các mảnh sáng. Mẫu này cho thấy có thể dùng biến đổi VFX để duy trì cảm giác vận động quanh một tư thế rõ. Không lấy lượng hạt/màu và độ phủ toàn màn hình của bộ này làm mẫu cho vệt trắng tối giản của Adel.
- **Don Quixote, Le Noir Brand Manager:** [preview chính thức, khoảng 0:30–0:31](https://www.youtube.com/watch?v=Hc6CJXJrzME&t=30s). Thấy tư thế vung búa chuyển sang đưa người lên cao; dải sáng chéo vẫn hiện rồi thu nhỏ, đứt và thưa dần trong phần tiếp nối. Qua các ảnh, phần đường chuyển động thay đổi trong khi tư thế sau vung trở nên rõ và giữ lâu hơn. Đây là bằng chứng hình ảnh của việc chia chức năng giữa pose và phần chuyển động phụ; chưa phải bằng chứng về node hoặc clock độc lập.
- **Rodion, Alteration Shop:** [preview chính thức, khoảng 0:27–0:28](https://www.youtube.com/watch?v=GIe7Fna5LD4&t=27s). Thân nhân vật giữ động tác giơ tay khá ổn định, còn các lưỡi/cấu kiện ở phía trên và cung trắng mảnh đổi hình, đổi hướng. Mẫu này hữu ích để thấy lớp chuyển động phụ có thể dẫn mắt mà không cần thân nhân vật liên tục đổi pose. Đây là bộ có thành phần vũ khí/hiệu ứng trên cao; không coi mọi cung đó là đường kiếm cầm tay.
- **Hong Lu trong preview chung với Heathcliff:** [preview chính thức ngày 23/10, khoảng 1:25–1:26](https://www.youtube.com/watch?v=jWYcZpYtdls&t=85s). Cung vàng lớn và điểm lóe tại mục tiêu tách biệt về hình. Ở các ảnh kế tiếp, cung rộng chuyển thành các nét mảnh rồi mất, trong khi nhân vật chuyển động tác và camera đi vào cận cảnh. Đây là mẫu gần ý tưởng vệt ngắn nối qua thay đổi tư thế. Không đủ bằng chứng phân biệt shader xóa từ đuôi, thay texture từng frame hay nhiều lớp sprite. Video là preview cho extraction 29/10, chưa phải bản ghi chơi sau phát hành tại ngày khảo sát.
- **Don Quixote trong trận thực tế:** [gameplay Kritzkingvoid, khoảng 0:48–0:55](https://www.youtube.com/watch?v=8CMs_ij_dMU&t=48s). Đã thấy UI trận, nhịp lên đòn, hình búa/vệt sáng theo đường đánh, lóe tại điểm trúng và camera đi theo pha va chạm. Nút tốc độ **MAX** xuất hiện trong đoạn lựa chọn ở khoảng 0:48. Vì vậy đoạn này hỗ trợ đối chiếu thứ tự hình ảnh và cách đọc đòn; không dùng số giây của nó để chốt timing ở tốc độ thường. Không khẳng định toàn video không cắt dựng.

### Những nguyên tắc rút ra từ các mẫu đã xem

Các mục sau là phân tích thiết kế từ hình ảnh, không phải quy tắc nội bộ được Project Moon công bố.

1. **Phân bố thời gian không đều giữa các pha.** Pose chuẩn bị và pose kết cần đủ rõ để đọc được hướng lực; đoạn chuyển qua quỹ đạo đánh có thể rất ngắn. Hướng áp dụng là giữ cấu trúc ba frame của Adel, đánh giá độ dài các pha trước khi thêm frame hoặc nội suy thân người. Nguồn đối chiếu: Don 0:30–0:31 và chuỗi Hong Lu 1:25.
2. **Mượt về cảm nhận có thể đến từ chuyển động phụ.** Cung chém, vũ khí, mảnh sáng và phản ứng mục tiêu thay đổi qua thời gian dù thân nhân vật giữ một tư thế rõ. Vệt của Adel có thể bổ sung phần quỹ đạo mà ba ảnh hiện tại không mô tả. Nguồn đối chiếu: Rodion 0:27–0:28, Don 0:30–0:31.
3. **Phân biệt đường chém với điểm va chạm.** Cung dài diễn tả hướng và độ rộng chuyển động; lóe nhỏ tại mục tiêu diễn tả thời điểm tiếp xúc. Với Adel, vệt vẫn xuất hiện khi chém hụt; phản hồi trúng chỉ thêm khi hit được xác nhận. Nguồn đối chiếu: Sinclair 1:44, Hong Lu 1:25 và gameplay Don 0:54.
4. **Lớp lưu vệt nên hạ vai trò nhanh sau đỉnh đòn.** Những ảnh kế tiếp có thể chuyển từ mảng lớn sang nét mảnh, đứt hoặc ít sáng hơn. Đề xuất cho Adel là để đòn mới chiếm ưu thế, còn vệt cũ chỉ nối chuyển động. Không có một con số lifetime chung nào đã được đo từ các video. Nguồn đối chiếu: Don 0:30–0:31 và Hong Lu 1:25.
5. **Cảm giác nặng là phối hợp nhiều dấu hiệu.** Tư thế, đường đi của cả người, điểm tiếp xúc, phản ứng mục tiêu và chuyển động camera cùng tham gia. Khảo sát này không có phép thử tắt riêng từng thành phần nên chưa định lượng đóng góp của chúng. Có thể giữ animation Adel hiện tại và dùng VFX để bổ sung đường đánh trước khi tăng camera shake hay hit-stop.
6. **Các mẫu mới không có cùng một mức độ trang trí.** Sinclair dùng nhiều lớp và độ phủ lớn; Rodion có đoạn nét trắng mảnh; Hong Lu có cung rộng rồi thu lại. Mục tiêu học là cấu trúc thông tin và nhịp, còn palette trắng và mức chi tiết thấp vẫn theo yêu cầu riêng của Adel.

### Những điều cần tránh suy ra từ video

- Không coi việc nhân vật giữ pose nhưng VFX thay đổi là bằng chứng game đã freeze animator hoặc dùng unscaled time. Giữ pose có thể là một đoạn được tác giả dựng sẵn.
- Không khẳng định mọi VFX Limbus sống qua chuyển animation. Video không lộ ranh giới clip hoặc sự kiện dọn tài nguyên.
- Không coi bề rộng cung chém trong Limbus là hình hitbox thật. Với Adel phải đối chiếu vùng gây sát thương của chính project.
- Không chép duration từ trailer, đoạn có MAX speed, video nén hoặc bản xuất GIF sang Godot như thông số đã kiểm chứng.

### Kế hoạch thử nghiệm A/B cho bốn đòn Saber

Giữ nguyên ba sprite và timing combat hiện có ở lượt thử đầu. Dùng cùng cung, hướng, tầm vươn và màu trắng cho cả hai phương án; không đồng thời đổi camera/hit-stop để dễ xác định nguyên nhân khác biệt.

- **A — chỉ vệt độc lập:** bật vệt ở frame ra đòn; một mask mô tả thứ tự dọc cung để xóa từ đuôi đến đầu; mỗi vệt tự hết tuổi theo thời gian thực. Đổi animation không xóa, kéo dài, xoay hoặc di chuyển lại vệt đã sinh. Mục tiêu: kiểm tra một lớp có đủ nối cảm nhận chuyển động và diễn tả vùng đánh không.
- **B — vệt độc lập nhẹ hơn + lớp theo frame:** lớp theo frame làm rõ quỹ đạo/đỉnh cú chém, mất ngay khi đổi animation và không fade; lớp độc lập có ít nét hơn, mảnh và nhẹ hơn, tiếp tục xóa từ đuôi. Mục tiêu: kiểm tra việc tách đỉnh lực và phần nối có giữ cảm giác gọn, nặng và rõ hơn không.
- **Yêu cầu chung do người dùng đặt ra:** fade không bị freeze/hit-stop làm chậm hoặc đứng; vệt được sống qua chuyển đòn nhưng tự kết thúc sớm; palette trắng; tránh chồng nhiều vệt rõ cùng lúc. Đây là yêu cầu thiết kế cho Adel, không phải cơ chế Limbus đã được chứng minh.
- **Giả thuyết hiện tại:** B có khả năng kiểm soát điểm nhấn tốt hơn; A phải được giữ làm bản so sánh. Chưa thử trong game nên chưa chọn bản thắng.
- **Tiêu chí đánh giá:** còn nhận ra ba tư thế mạnh không; đường chém có dễ đọc hơn không; vệt cũ có lấn đòn mới không; vùng vệt sáng có nhất quán với hitbox không; đổi hướng/di chuyển có kéo sai vệt cũ không; hit-stop dài có làm vệt tan hết quá sớm về cảm nhận không.
- **Phạm vi chỉnh khi được ra lệnh:** thử VFX và công tắc A/B trước; các đề xuất timing, camera hoặc hit-stop chỉ được đánh giá sau khi đã xem bản thử và theo phạm vi người dùng chốt.

## Mức độ kiểm chứng

- Các URL dưới đây được tìm qua web và đối chiếu tiêu đề, tác giả hoặc mô tả do trang video cung cấp. Một số trang YouTube trả lỗi khi mở bằng công cụ đọc web; kết quả tìm kiếm vẫn trả metadata của chính trang video.
- Tác vụ nền tìm nguồn không phát video bằng trình duyệt. Tác vụ chính đã bổ sung phần quan sát trực tiếp phía trên. Các mục catalog nguồn bên dưới giữ ghi chú về mức kiểm chứng tại lúc tìm nguồn. Toàn bộ nghiên cứu vẫn chưa khẳng định số frame tác giả vẽ, độ dài hit-stop, dạng shader hay kiến trúc lifetime bên trong Limbus.
- Timestamp do mô tả video công bố được ghi rõ là chapter của tác giả. Chúng là mốc tìm đoạn, không phải phép đo timing của đòn đánh.
- Trailer, compilation, GIF và bản dựng lại có thể thay đổi tốc độ, camera hoặc thiếu ngữ cảnh. Dùng chúng để tìm mẫu; dùng gameplay gốc để kiểm tra nhịp trong trận.

## Bổ sung theo yêu cầu: nhân vật gần đây trong năm 2026

Phần này mở rộng mẫu khảo sát vượt ra ngoài W Corp. Meursault. Các video là preview do kênh ProjectMoon Official công bố; không tự gán loại vũ khí, số frame hoặc kỹ thuật VFX chỉ từ tên nhân vật. Các timestamp chiến đấu cụ thể chưa được xem và đo trong tác vụ tìm nguồn.

### R1. Heathcliff và Hong Lu — preview ngày 23/10/2026

- [Video gốc](https://www.youtube.com/watch?v=jWYcZpYtdls), dài 2:23.
- Tiêu đề: `LimbusCompany [000] 오트쿠튀르::르루주 바느질의 왕 히스클리프 / [000] 오트쿠튀르::르누아르 3F 방송실 홍루`.
- Tên tiếng Anh trong thông báo: Haute Couture::Le Rouge King of Needleworks Heathcliff và Haute Couture::Le Noir 3F Public Address Room Hong Lu. [Thông báo extraction](https://store.steampowered.com/news/app/1973530/view/667254131059070030).
- Ngày đăng và kênh ProjectMoon Official được đối chiếu bằng [metadata video Imbench](https://www.imbench.com/youtube/video/jWYcZpYtdls) và [metadata YT50](https://yt50.app/kr/v/jWYcZpYtdls). Ngày extraction là 29/10/2026; tại ngày nghiên cứu 25/10 đây là preview chưa phát hành, không phải bản ghi gameplay người chơi sau phát hành.
- Mục tiêu xem: art direction mới nhất và cấu trúc ra đòn của hai nhân vật khác nhau; phân biệt đoạn gameplay với dựng trailer.

### R2. Sinclair — preview ngày 09/10/2026

- [Video gốc](https://www.youtube.com/watch?v=Gpj-lvOnAgs), metadata kênh liệt kê dài 2:55.
- Tiêu đề: `LimbusCompany [000] 오트쿠튀르::르루주 붉은 신 싱클레어` — Haute Couture::The Crimson God of Le Rouge Sinclair.
- Ngày và kênh được đối chiếu qua [danh sách video của channel ProjectMoon Official](https://www.koreachannels.com/ko/channel/projectmoonofficial); URL lấy trực tiếp từ liên kết video của danh sách, không đoán video ID. Có [bản cộng đồng dẫn đúng URL gốc cùng ngày 09/10](https://www.bilibili.com/video/BV1eLp464EhS/).
- Công cụ đọc web không mở được nội dung video YouTube để xác minh trực tiếp phần hình; cần parent xem bằng trình duyệt. Không suy diễn cơ chế từ nội dung bình luận.

### R3. Don Quixote — preview ngày 25/09/2026

- [Video gốc](https://www.youtube.com/watch?v=Hc6CJXJrzME), dài 1:17.
- Tiêu đề: `LimbusCompany [000] 오트쿠튀르::르누아르 브랜드 매니저 돈키호테` — Haute Couture::Le Noir Brand Manager Don Quixote.
- Metadata ngày đăng 25/09 và kênh ProjectMoon Official được đối chiếu qua [RankTube](https://ranktube.co.kr/video/Hc6CJXJrzME) và [TRENVID](https://trenvid.zzxxccvv.com/video/Hc6CJXJrzME/). Không dùng phần tóm tắt caption tự động của trang thứ hai làm phân tích animation.
- Mục tiêu xem: so sánh đòn thường và cú kết trong cùng bộ mới; không coi camera trailer là một chuyển động của sprite.

### R4. Rodion — preview ngày 18/09/2026

- [Video dài gốc](https://www.youtube.com/watch?v=GIe7Fna5LD4), dài 1:09 theo danh sách channel.
- [Phiên bản khác do cùng channel đăng](https://www.youtube.com/watch?v=avJlUx4CSA8). Chính metadata trang YouTube của phiên bản này xác nhận `ProjectMoon Official` và ngày đăng `2026-09-18`.
- Tiêu đề: `LimbusCompany [000] 오트쿠튀르::수선실 로쟈` — Haute Couture::Alteration Shop Rodion.
- [Danh sách channel đối chiếu hai bản](https://www.koreachannels.com/ko/channel/projectmoonofficial), [bản dẫn URL video dài từ ngày 18/09](https://www.bilibili.com/video/BV1g9em6GEYW/).
- Mục tiêu xem: chuyển động vũ khí có hình dạng khác kiếm đơn và mức chi tiết VFX trong một bộ mới; chưa gán kết luận về độ nặng chỉ từ tên.

### R5. Outis — preview ngày 22/05/2026

- [Video gốc](https://www.youtube.com/watch?v=BF_ULinL-jU), dài 2:55.
- Tiêu đề: `LimbusCompany [000] 거미집 중지 아비 오티스 / E.G.O 5단계 환상 해석 개방` — The House of Spiders: The Middle Nursefather Outis.
- Kênh ProjectMoon Official, ngày 22/05/2026 và độ dài được đối chiếu bằng [metadata RankTube](https://ranktube.co.kr/video/BF_ULinL-jU) và [Korea.com](https://video.korea.com/view/?id=BF_ULinL-jU).
- Dùng như mẫu khác nhóm cắt kiếm để parent kiểm tra cách dựng lực va đập, pose chuẩn bị và cú kết. Loại vũ khí/đòn đánh cần xác nhận trực quan trước khi phân loại.

### R6. Ryōshū — preview tháng 05/2026

- [Bản gốc không voice](https://www.youtube.com/watch?v=G3Pi7V_-DH0), ngày 08/05/2026, dài 2:21.
- [Bản có voice](https://www.youtube.com/watch?v=LkLhzmoJZ6Y), ngày 13/05/2026, dài 1:44 theo metadata channel.
- Tiêu đề gốc: `LimbusCompany [000] 거미집의 검 료슈 (보이스 없음) / E.G.O 5단계 환상 해석 개방` — Blade of the House of Spiders Ryōshū.
- Kênh ProjectMoon Official, ngày và độ dài bản không voice được đối chiếu qua [RankTube](https://ranktube.co.kr/video/G3Pi7V_-DH0); [Korea.com](https://video.korea.com/view/?id=LkLhzmoJZ6Y) xác định bản voice cùng channel.
- Mục tiêu xem: một bộ kiếm năm 2026 để đối chiếu với W Corp. Ryōshū năm 2023, tránh kết luận phong cách hiện tại chỉ từ asset đời đầu.

### Mẫu bổ sung nếu cần

- [Cinq Assoc. East Section 3 Hong Lu](https://www.youtube.com/watch?v=mGJJuEI52EU), metadata channel ghi 14/08/2026. [Nguồn đối chiếu danh sách channel](https://www.koreachannels.com/ko/channel/projectmoonofficial).
- Tìm được tiêu đề gameplay gần đây của Jexnpierre về Le Noir Don Quixote và Crimson God Sinclair, nhưng chưa xác minh được URL gốc YouTube bằng metadata đủ tin cậy trong lượt tìm này. Không đưa URL suy đoán vào danh sách.

### Ranh giới bằng chứng cho phần recent

Metadata channel, ngày đăng và URL không chứng minh đã xem hình chuyển động. Các nhãn cắt kiếm, blunt nặng, multi-hit và quy tắc VFX chỉ được ghi thành kết luận khi quan sát trực tiếp. Không dùng bản simulation fan hoặc caption AI để lấp phần chưa xem. Các trang thống kê chỉ hỗ trợ kiểm tra metadata; bằng chứng chuyển động phải là video gốc mà chúng dẫn đến.

## Gameplay người chơi bổ sung cho các identity mới

Các URL sau được tìm từ liên kết video thật trên [danh sách channel Kritzkingvoid](https://invidious.tiekoetter.com/channel/UCgoMZk2xpqGjx2LMH5-UAtA). Tên kênh trên nguồn là **Kritzkingvoid**. Đây là gameplay cộng đồng để parent xem đối chiếu với preview; tác vụ tìm nguồn chưa phát các video này.

### G1. The Crimson God of Le Rouge Sinclair vs Lei Heng

- [Video YouTube gốc](https://www.youtube.com/watch?v=P0MvX3ehFEA).
- Tiêu đề được danh sách channel hiển thị: `[Limbus Company] The Crimson God of Le Rouge Sinclair vs Lei Heng`.
- Tác giả: Kritzkingvoid; độ dài được hiển thị: 7:02.
- Video ID `P0MvX3ehFEA` lấy từ [liên kết watch của chính danh sách channel](https://invidious.tiekoetter.com/watch?v=P0MvX3ehFEA), không suy đoán từ tiêu đề.
- Công cụ đọc web không mở được trang YouTube. Thời gian tương đối trên bản cache Invidious thay đổi giữa các lần truy xuất, nên chưa xác minh ngày đăng lịch chính xác và không ghi một ngày phỏng đoán. Không dùng nhãn thời gian tương đối để đo tuổi video.
- Mục tiêu xem: nhịp đi từ chuẩn bị đến blur, giữ pose trúng đòn, lifetime vệt và phản ứng mục tiêu trong một trận chiến. Cần kiểm tra tốc độ playback và khả năng cắt dựng trước khi đưa ra phép đo timing.

### G2. Le Noir Can't Stop Winning — Don Quixote

- [Video YouTube gốc](https://www.youtube.com/watch?v=8CMs_ij_dMU).
- Tiêu đề được danh sách channel hiển thị: `[Limbus Company] Le Noir Can't Stop Winning [Le Noir Brand Manager Don Quixote]`.
- Tác giả: Kritzkingvoid; độ dài được hiển thị: 7:20.
- Video ID `8CMs_ij_dMU` lấy từ [liên kết watch của danh sách channel](https://invidious.tiekoetter.com/watch?v=8CMs_ij_dMU).
- Chưa xác minh ngày đăng chính xác bằng trang YouTube; không xem số tuần tương đối trong cache là ngày công bố. Chưa xác nhận clip có cắt dựng hoặc chỉnh tốc độ hay không.
- Mục tiêu xem: so sánh nhịp đòn thường, cú kết và phần VFX còn lại sau đổi pose với video chính thức Don Quixote ngày 25/09/2026.

## Nguồn chính thức đời đầu để đối chiếu lịch sử

### 1. W Corp. Ryōshū và Hong Lu — ProjectMoon Official

- URL: https://www.youtube.com/watch?v=gv0Hwl7u4-I
- Tiêu đề gốc: `LimbusCompany [000] W사 3등급 정리요원 료슈 / [00] W사 2등급 정리요원 홍루`.
- Kết quả từ chính trang YouTube xác nhận kênh `ProjectMoon Official`. Nguồn là preview identity của nhà phát triển. Công cụ đọc web timeout khi mở trực tiếp nên chưa xác nhận timestamp của các đòn.
- Mục tiêu xem: đối chiếu đòn chém liên tiếp, cách giữ silhouette nhân vật khi có cung chém và phần kết vệt sau khi pose đã đổi. Đây là câu hỏi khảo sát, chưa phải kết luận về video.
- [Nguồn video](https://www.youtube.com/watch?v=gv0Hwl7u4-I).

### 2. W Corp. L3 Cleanup Agent Yi Sang — ProjectMoon Official

- URL: https://www.youtube.com/watch?v=5IqXi_SPSn0
- Tiêu đề gốc: `LimbusCompany [000] W사 3등급 정리 요원 이상`.
- Metadata của chính trang video xác nhận kênh `ProjectMoon Official`, ngày đăng 03/11/2023. Mô tả công bố identity extraction ngày 09/11/2023. Không dùng ngày extraction để suy ra timing animation.
- Mục tiêu xem: các cú cắt có sự dịch chuyển và đổi phía; phân biệt chuyển động nhân vật, camera và VFX. Chưa đo tốc độ hoặc đếm frame.
- [Nguồn video](https://www.youtube.com/watch?v=5IqXi_SPSn0).

## Gameplay người chơi và compilation để đối chiếu

### 3. W corp Meursault MD5I solo — Bullet

- URL: https://www.youtube.com/watch?v=-kVezQqmYjA
- Metadata của chính trang YouTube: tác giả `Bullet`, ngày đăng 10/06/2025. Mô tả xác định W Corp. L2 Cleanup Agent Meursault, Mirror Dungeon Infinity solo.
- Chapter của tác giả: `0:00` Pink Shoes; `2:34` Alleyway Watchdog; `4:51` KQE; `7:17` Timer Ripper. Đây là gameplay người chơi; không phải video chính thức hoặc tài liệu triển khai của Project Moon.
- Ưu tiên mở từ [đầu trận](https://www.youtube.com/watch?v=-kVezQqmYjA&t=0s) hoặc [Alleyway Watchdog](https://www.youtube.com/watch?v=-kVezQqmYjA&t=154s) để tìm đòn đánh trong ngữ cảnh mục tiêu và phản ứng trúng đòn.
- Chỉ ghi nhận các mốc chapter có trong mô tả, chưa gán timestamp cụ thể cho Skill 3.

### 4. [Limbus Company] W Corp Meursault - MD4R Solo Run — Solitarius

- URL: https://www.youtube.com/watch?v=kuAOxD92wuo
- Metadata của chính trang YouTube: tác giả `Solitarius`, ngày đăng 29/09/2024. Mô tả xác định đây là W Corp. L2 Cleanup Agent Meursault trong Mirror Dungeon 4 Ritornello/Hard Solo Run.
- Chapter của tác giả: `00:00` Floor 1 Automated Factory; `08:48` Floor 1 Boss You Want To Get Beat? Hurtily?; `14:11` Floor 2 Hell's Chicken; `20:10` Floor 2 Boss Papa Bongy.
- Mốc mở xem: [đầu trận](https://www.youtube.com/watch?v=kuAOxD92wuo&t=0s) và [boss đầu](https://www.youtube.com/watch?v=kuAOxD92wuo&t=528s).
- Dùng để đối chiếu video Bullet và GIF người dùng, tránh xem một bản export GIF là toàn bộ hành vi trong game.

### 5. All Skill Animations | Limbus Company — compilation cộng đồng

- URL: https://www.youtube.com/watch?v=0369rOXojBQ
- Mô tả của chính video nêu phạm vi các animation hiện có đến đợt N Corp. Rodya/Meursault ngày 09/03/2023; có chapter `1:56 W Corp`.
- Mốc mở xem: [W Corp, 1:56](https://www.youtube.com/watch?v=0369rOXojBQ&t=116s).
- Tên kênh chưa được metadata trả về trong lần khảo sát này; không gán video cho ProjectMoon. Compilation phù hợp tìm các ví dụ gần nhau, nhưng không được coi việc cắt dựng là timing nguyên bản.
- [Nguồn video và mô tả](https://www.youtube.com/watch?v=0369rOXojBQ).

### 6. [Limbus Company] A Full Guide to LCD Ishmael & Blade Lineage Meursault — Jexnpierre

- URL: https://www.youtube.com/watch?v=upu78JTIEg8
- Metadata của chính trang YouTube: tác giả `Jexnpierre`, ngày đăng 16/06/2026.
- Chapter của tác giả: `11:13` BL Meursault Skills Overview; `17:02` Skill Rotation; `18:03` Blade Lineage Team Example.
- Ưu tiên [đoạn team example, 18:03](https://www.youtube.com/watch?v=upu78JTIEg8&t=1083s) cho hình gameplay. Không dùng lời bình hoặc đánh giá build trong video để khẳng định kỹ thuật animation.
- [Nguồn video](https://www.youtube.com/watch?v=upu78JTIEg8).

## Nguồn bổ sung cần thận trọng

### 7. Blade Lineage Mentor Meursault — References and Origins — Shiio

- URL: https://www.youtube.com/watch?v=EnmC7tQ6Tzg
- Metadata của chính trang video xác nhận tác giả `Shiio`, ngày đăng 26/02/2024. Tiêu đề là `[Limbus Company] Blade Lineage Mentor Meursault - References and Origins`.
- Đây là video biên tập so sánh/reference, không phải tài liệu do nhà phát triển công bố. Có thể dùng tìm đặc trưng pose và bố cục, không dùng làm bằng chứng định lượng timing nguyên bản khi chưa đối chiếu gameplay.
- [Nguồn video](https://www.youtube.com/watch?v=EnmC7tQ6Tzg).

### 8. Combat Systems Introduction — video giới thiệu trước phát hành

- URL được một trang dẫn video trỏ tới: https://www.youtube.com/watch?v=WEJfLhJ4xOA
- [Trang dẫn nguồn Main Gamers](https://www.maingamers.com/games/limbus-company/videos/cmui2g2jm0014gorvopfy22tm) ghi tiêu đề `ProjectMoon Official｜[ Limbus Company ] Combat Systems Introduction ( Kr / En / Jp ) CC` và liên kết gốc YouTube trên.
- Chưa xác nhận trực tiếp metadata kênh bằng trang YouTube trong lần khảo sát này. Không nhầm ngày đăng bài Main Gamers năm 2026 với ngày phát hành video.
- Có dấu vết công bố từ tháng 05/2022 và mô tả bản đang phát triển; vì vậy chỉ dùng làm ngữ cảnh lịch sử, không dùng để khẳng định hành vi hiện tại. [Bản lưu bài chia sẻ của ProjectMoon](https://twfan.net/user/3422670313/new/3), [bản chia sẻ ngày 06/05/2022](https://www.bilibili.com/video/BV1v54y1f7er/).

## Những điều chưa có bằng chứng để khẳng định

1. Fade từ đuôi trong Limbus có chạy theo đồng hồ độc lập với hit-stop hay không.
2. VFX có là node độc lập sống qua chuyển animation, hay được dựng bằng nhiều sprite/frame trong cùng clip.
3. Video có giảm tốc nhân vật, dừng animator, thay time scale, hoặc chỉ giữ nguyên sprite pose trong thời gian hit-stop.
4. Các con số lifetime hoặc freeze chính xác. Không thể suy ra đáng tin cậy từ snippet/transcript hoặc video đã chỉnh tốc độ.
5. Một shader duy nhất là cách Project Moon tạo mọi cung chém. Hình ảnh đầu ra không chứng minh kiến trúc runtime.

## Phiếu quan sát cho bước xem video

Với mỗi đoạn đã phát và xem được, ghi: URL/timestamp, tốc độ playback, tư thế chuẩn bị, frame chuyển blur, pose kết, lúc VFX bắt đầu/mất, phản ứng mục tiêu, dấu hiệu camera di chuyển, và phần nào vẫn chuyển động khi nhân vật giữ pose. Tách ba mức: quan sát trực tiếp, suy luận từ quan sát, đề xuất thử nghiệm cho Adel.

Đối với Adel, giữ hai phương án do người dùng yêu cầu làm giả thuyết cần thử: (1) chỉ vệt trắng độc lập tan từ đuôi; (2) vệt độc lập nhẹ hơn kết hợp lớp VFX gắn frame, mất ngay khi chuyển animation. Không coi việc tìm thấy nguồn là bằng chứng phương án nào tốt hơn.
