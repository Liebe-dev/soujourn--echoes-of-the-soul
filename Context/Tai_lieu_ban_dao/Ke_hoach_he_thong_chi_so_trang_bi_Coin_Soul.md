# Kế hoạch hệ thống chỉ số, trang bị và Coin/Soul

**Dự án:** Soujourn: Echoes of the Soul  
**Ngày tổng hợp:** 24/10/2026  
**Trạng thái 24/10/2026:** đã triển khai nền giai đoạn 1–4 với Saber/EnemyBase; giáp, giao dịch và các hệ thống phụ thuộc vẫn chờ.

Tài liệu tổng hợp thiết kế đã trao đổi: làm bảng Character phản ánh dữ liệu thật, thay nâng trực tiếp HP/stamina bằng thuộc tính, bổ sung yêu cầu và scaling trang bị, quản lý Coin/Soul và chuẩn bị rèn vũ khí boss. Phần quy tắc và đề xuất ban đầu được giữ để đối chiếu. Trạng thái triển khai hiện hành ở mục 8; số tuning runtime, mặc định và override chỉ tra trong hướng dẫn chung.

## 1. Cách đọc và phạm vi

- **Đã chốt:** quy tắc người dùng đã xác nhận trong cuộc trò chuyện.
- **Đề xuất:** phương án kỹ thuật, cách tính hoặc số cân bằng khởi điểm do trợ lý đề xuất; có thể điều chỉnh khi thử nghiệm.
- **Chờ hệ thống liên quan:** đã có định hướng tác dụng nhưng gameplay nền chưa hoàn thiện.

Các phần trăm 40/60, 80/20, 50 và 30 là **hệ số quy đổi so với một mức tăng chuẩn**, không phải cộng từng ấy phần trăm tổng chỉ số hiện tại cho mỗi điểm. Phần trăm tăng/giảm trong bộ số khởi điểm bên dưới tính trên giá trị gốc, không nhân dồn sau mỗi điểm.

File này giữ các số đề xuất lúc thiết kế, không quản lý tuning runtime. Với phần đã triển khai, vị trí chỉnh, đơn vị, mặc định script và override scene thực tế được ghi tại [hướng dẫn tùy chỉnh chung](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md). Báo cáo hệ thống hiện có được cập nhật tại chỗ và liên kết tới hướng dẫn đó; không dùng file kế hoạch làm một hướng dẫn tuning hiện hành thứ hai.

## 2. Hiện trạng ban đầu trước lượt triển khai 24/10/2026

Đây là snapshot lúc lập kế hoạch, không phải source sau triển khai. Trạng thái mới ở mục 8 và các báo cáo kỹ thuật hiện hành:

Tại thời điểm tổng hợp:

- `scenes/Mechanic/player_progress.gd` quản lý Level, EXP, điểm nâng và số lần nâng HP/stamina. Mỗi cấp hiện nhận **1 điểm**, HP nền **100**, mỗi nâng HP **+20**; stamina nền **100**, mỗi nâng stamina **+15**. Đây là cơ chế cũ, chưa chuyển sang thiết kế 5 điểm/cấp.
- `scenes/UI/campfire_upgrade_menu.gd` hiện chỉ có hai thao tác nâng HP và stamina, dùng điểm ngay khi nhấn.
- `scenes/UI/character_menu.gd` hiện đọc Level và HP/stamina tối đa; các dòng thuộc tính và tiền tệ chưa được nối đầy đủ với dữ liệu thật.
- `scenes/UI/stats_component.gd` là model HP/stamina, bình máu, stagger và debuff thuộc Player; hồi stamina mặc định trong model là **28 điểm/giây**. Cấu hình Player/instance có thể ghi đè giá trị này.
- `scenes/UI/save_manager.gd` đang dùng `SAVE_VERSION = 1`, có lưu progression cũ. Khi thay schema cần sửa cả bước đọc, kiểm tra và migration, không chỉ thêm khóa lúc ghi.
- `scenes/enemy/enemy_base.gd` đã có phần thưởng EXP khi chết; chưa thể coi đây là phần thưởng Coin/Soul đã hoạt động.
- Arts/mana, Divine Arts, đầy đủ skill Dark Arts 1–4 và các nguồn tích ulti chưa hoàn thiện. Có HUD/API nền không đồng nghĩa có đủ gameplay.

Lượt tổng hợp tài liệu chỉ đọc source; không chạy kiểm thử gameplay mới và không chỉnh code, scene hay save.

## 3. Lên cấp và tám thuộc tính

### 3.1. Quy tắc đã chốt

- Mỗi lần lên cấp nhận **5 điểm nâng**; số điểm này phải có thể điều chỉnh.
- Bỏ nâng trực tiếp Health và Stamina. HP/stamina được suy ra từ thuộc tính.
- Danh sách có thể nâng gồm: **Vitality, Prowess, Strength, Agility, Resistance, Arts Compatibility, Dark Arts Assimilation, Faith**.
- Thay danh sách cũ; không giữ Dexterity và Arts Effectiveness như hai thuộc tính nâng riêng.
- EXP, Coin, Soul và điểm nâng là các đại lượng riêng. Cơ chế dùng Soul mua điểm nâng thuộc giai đoạn sau.

### 3.2. Tác dụng đã thống nhất

**Vitality** tăng HP.

**Prowess** tăng sức tấn công.

**Strength** kết hợp 40% mức tăng HP chuẩn và 60% mức tăng ATK chuẩn.

**Agility** kết hợp 80% mức tăng stamina chuẩn và 20% mức tăng tốc độ hồi stamina chuẩn. Không tự thay tốc chạy, nhịp animation, cửa sổ Deflect hay i-frame né.

**Resistance** tăng HP theo hệ số 20%, giảm xác suất nhận hiệu ứng bất lợi từ địch và giảm thời lượng tối đa phải chịu hiệu ứng đó. **Không tác động xác suất, cấp độ, sát thương, thời lượng hoặc cách chữa Bleed/Fracture**. Phần cộng HP của Resistance vẫn là cộng HP tối đa bình thường.

**Arts Compatibility** tăng hồi mana và tăng sát thương phép theo hệ số 50%. Tác dụng chờ hệ thống Arts/mana.

**Dark Arts Assimilation** có các tác dụng:

- Tăng tốc độ hồi/tích ulti theo hệ số 30%.
- Giảm HP tiêu hao khi dùng skill Dark Arts 1, 2, 3, 4.
- Tăng sát thương gây ra trong dạng Sentinel theo hệ số 30%.
- Đạt các mốc thuộc tính nhất định thì giảm phần trăm HP bị rút khi duy trì Sentinel.

Tách riêng chi phí HP của từng skill và lượng HP rút duy trì dạng Sentinel. Nguồn hồi/tích ulti cụ thể phải được nối khi hệ thống đó tồn tại; thuộc tính không tự tạo thêm nguồn tích ulti.

**Faith** giảm thời gian hồi và kéo dài hiệu ứng của **Divine Arts**. Divine Arts là cơ chế riêng với Arts: có thể gây debuff cho địch hoặc buff bản thân, không tiêu mana, hồi chiêu khá lâu và trừ thanh ulti khi sử dụng. Faith không mặc nhiên giảm hồi chiêu Q/E của vũ khí hay các kỹ năng khác.

### 3.3. Số cân bằng khởi điểm đề xuất lúc lập kế hoạch

Người dùng sẽ tự thử nghiệm và cân bằng lại. Các giá trị sau là đề xuất thiết kế ban đầu, chưa phải cân bằng đã nghiệm thu. Những hệ số đã được nối vào gameplay hiện được quản lý tại [hướng dẫn tuning](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md#hp-stamina); các tác dụng chưa có nền không tự trở thành thông số runtime:

- HP nền: **100**. Mỗi Vitality **+10 HP**, Strength **+4 HP**, Resistance **+2 HP**.
- Chuẩn thưởng ATK của Prowess: **2% sát thương nền/điểm**, trước hệ số scaling riêng của vũ khí. Strength dùng 60% chuẩn này, tương ứng **1,2%**.
- Stamina nền: **100**. Chuẩn tăng stamina **+5**; Agility nhận 80%, tức **+4 stamina/điểm**.
- Chuẩn tăng hồi stamina **+1,4 điểm/giây**; Agility nhận 20%, tức **+0,28 điểm/giây/điểm thuộc tính**. Nền model hiện tại là 28 điểm/giây; khi triển khai phải kết hợp đúng giá trị Player/instance đang dùng.
- Resistance: mỗi điểm giảm **1% tương đối** xác suất nhận debuff và **1%** thời lượng debuff; giới hạn giảm ban đầu **40%** cho mỗi tác dụng. Ngoại lệ Bleed/Fracture luôn có ưu tiên.
- Arts Compatibility: dự kiến **+1% hồi mana** và **+0,5% sát thương phép/điểm**; chỉ có tác dụng khi Arts được triển khai.
- Dark Arts Assimilation: dự kiến **+0,3% hồi/tích ulti**, **+0,3% sát thương Sentinel**, giảm **0,5% chi phí HP skill Dark Arts/điểm**. Mỗi **10 điểm** giảm thêm **5%** lượng HP rút duy trì Sentinel; giới hạn giảm tiêu hao ban đầu **50%** cho từng nhóm chi phí.
- Faith: dự kiến giảm **0,5% hồi chiêu Divine Arts/điểm**, giới hạn **30%**; tăng **1% thời lượng hiệu ứng/điểm**, giới hạn **50%**.

Ví dụ Resistance: xác suất gốc 50%, có 10 điểm thì còn `50% × (1 − 10%) = 45%`, không phải 40%. Debuff gốc 10 giây còn 9 giây. Bleed/Fracture không đi qua công thức này.

Công thức tài nguyên dự kiến, với V/S/R/A là số điểm tương ứng:

```text
max_hp = base_hp + 10 × V + 4 × S + 2 × R
max_stamina = base_stamina + 4 × A
stamina_regen = configured_base_regen + 0,28 × A
```

Mọi hệ số, mốc và giới hạn phải được cấu hình riêng. Các tốc độ hồi và thời lượng gameplay dùng thời gian game theo chủ sở hữu hiện có, không tự chuyển thành thời gian thực. Chưa chốt soft cap giảm lợi ích theo ngưỡng hoặc trần điểm chung của thuộc tính.

## 4. Yêu cầu và scaling trang bị

### 4.1. Quy tắc đã chốt cho vũ khí

- Mỗi vũ khí có yêu cầu thuộc tính và scaling riêng.
- Phải đạt **tất cả** yêu cầu mới phát huy 100% sức mạnh.
- Vẫn có thể trang bị khi thiếu chỉ số, nhưng sát thương chỉ còn **20%** mức bình thường sau scaling.
- Không đủ yêu cầu thì không dùng được skill của chính vũ khí đó: **Q tay phải, E tay trái**.
- Kiểm tra từng tay độc lập. Một vũ khí thiếu yêu cầu không khóa skill của vũ khí đủ yêu cầu ở tay kia.
- Thiếu nhiều yêu cầu vẫn chỉ áp dụng mức 20% một lần; không nhân phạt lặp.

Ví dụ: cùng một nhân vật, vũ khí có sát thương tính được là 100 khi không xét điều kiện sử dụng. Nếu thiếu ít nhất một yêu cầu, sát thương tương ứng còn 20, trước các bước xử lý mục tiêu liên quan.

### 4.2. Cách tính và dữ liệu đề xuất

Mỗi định nghĩa vũ khí cần: ID, tên/icon, sát thương nền, yêu cầu từng thuộc tính, hệ số scaling, dữ liệu kỹ năng và loại sát thương. Giá trị số là dữ liệu gốc; hạng S/A/B/C/D/E có thể dùng để trình bày sau, chưa chốt khoảng hệ số của từng hạng.

Ví dụ cho phần Prowess/Strength của một vũ khí:

```text
bonus = base_damage × (0,02 × prowess × k_prowess
                    + 0,012 × strength × k_strength)
weapon_attack = base_damage + bonus
requirement_factor = 1,0 nếu đủ yêu cầu, ngược lại 0,2
```

`k_prowess` và `k_strength` là hệ số riêng của món vũ khí. Hai hệ số 0,02/0,012 thuộc bộ số khởi điểm đề xuất. Chưa chốt hệ số hoặc yêu cầu cụ thể của từng món; không tự gán mọi thuộc tính thành nguồn sát thương chung.

Đề xuất đưa thưởng Prowess/Strength vào cùng một công thức scaling, không vừa cộng ATK chung rồi lại cộng lần nữa ở hitbox. Kết hợp sát thương vũ khí với hệ số đòn thường/combo/Q, phạt thiếu yêu cầu, buff/debuff và hệ thống nhận đòn hiện có; chỉ áp dụng mỗi hệ số một lần. Không làm thay đổi các tỷ lệ giữa đòn hoặc timing người dùng đã căn ngoài phạm vi.

Các quy tắc kỹ thuật đề xuất:

- Xét yêu cầu bằng chỉ số gốc cộng điểm đã nâng; chưa tính buff tạm hoặc bonus của chính món trang bị để tránh điều kiện tự thỏa mãn. Việc cho bonus ngoài tham gia xét yêu cầu cần quyết định riêng.
- Chặn skill thiếu yêu cầu trước khi trừ tài nguyên, bắt đầu hồi chiêu hoặc chạy animation. HUD cần thể hiện lý do khóa.
- Món khởi đầu phải dùng được đầy đủ ngay New Game. Giai đoạn thử nghiệm đầu có thể để yêu cầu Saber bằng 0, rồi căn lại theo chỉ số khởi đầu.
- Chuẩn bị E trong thiết kế dữ liệu; hiện ô tay trái đang trống và chưa có gameplay skill E, không tự tạo skill hoặc trang bị tay trái chỉ để minh họa.

### 4.3. Quy tắc đã chốt cho giáp

- Giáp cũng có yêu cầu thuộc tính.
- Không đủ yêu cầu thì chỉ nhận **20% hiệu quả giảm sát thương** của riêng món giáp đó và **không kích hoạt passive của món đó**.
- Ví dụ: món giảm 25% sát thương chỉ còn giảm `25% × 20% = 5%`; không phải giảm cố định 20% sát thương nhận.
- Giáp thiếu yêu cầu không vô hiệu hóa passive của món khác đủ yêu cầu.

Đề xuất: mỗi món lưu riêng chỉ số phòng thủ, yêu cầu và passive; nhiều nguồn giảm sát thương kết hợp có giới hạn và quy tắc rõ ràng. Nếu dùng phép nhân phần sát thương còn lại, hai nguồn 10% cho tổng giảm 19%, không cộng mặc định thành 20%. Cách gộp cuối cùng và loại sát thương được giáp bảo vệ còn cần chốt khi làm hệ giáp. Không tự coi chi phí HP Dark Arts hoặc HP rút Sentinel là sát thương được giáp giảm.

## 5. Coin và Soul

### 5.1. Vai trò đã chốt

**Coin** dùng mua vật phẩm ở shop. Nguồn nhận gồm tiêu diệt quái, hoàn thành nhiệm vụ và bán vật phẩm.

**Soul** nhận từ tiêu diệt kẻ địch, boss và Observe. Soul dùng rèn vũ khí đặc biệt; về sau có thể dùng mua điểm nâng chỉ số.

Hai loại tiền được quản lý riêng, hiển thị số dư thật tại hai dòng Coin/Soul của Character và lưu theo từng slot. Chưa chốt thưởng mỗi loại địch, giá shop, chi phí công thức hoặc giá mua điểm nâng. Không áp số thưởng EXP hiện tại thành Coin/Soul.

Không tự thêm mất tiền khi chết, nhặt lại tiền ở xác, đổi Coin sang Soul hoặc tăng giá theo cấp chỉ vì lấy cảm hứng từ Souls. Những quy tắc đó chưa được yêu cầu.

### 5.2. Quản lý phần thưởng và giao dịch đề xuất

- Số dư dùng số nguyên không âm; API nhận/trừ tiền kiểm tra dữ liệu và khả năng chi trả.
- Một lần chết của địch chỉ phát thưởng một lần, dù có nhiều hit/callback. Lần sinh lại hợp lệ là vòng đời mới.
- Nhiệm vụ và Observe cần ID sự kiện để kiểm soát nhận thưởng lặp. Đề xuất thưởng Observe một lần cho mỗi phát hiện hợp lệ và lưu dấu đã nhận; quy tắc phát hiện nào được thưởng cần được định nghĩa khi làm Observe.
- Mua: kiểm tra Coin và điều kiện nhận đồ, rồi trừ tiền và trao đồ như một giao dịch.
- Bán: kiểm tra vật phẩm/số lượng, rồi lấy vật phẩm và cộng Coin như một giao dịch.
- Không trừ tài nguyên ở màn xem trước. Thất bại không để lại trạng thái chỉ trừ tiền hoặc chỉ mất đồ.
- Cần phân biệt phần thưởng phát sinh trong phiên với mốc ghi checkpoint. Chưa chốt tự lưu mỗi phần thưởng; không tự ghi đè save khi chạy riêng một scene chưa chọn slot phiên chơi.

### 5.3. Rèn vũ khí boss đã thống nhất

```text
Lõi tinh thể ám thuật cô đặc của boss
+ các vật phẩm nguyên liệu yêu cầu
+ lượng Soul theo công thức
→ vũ khí đặc biệt
```

Lõi là vật phẩm/nguyên liệu, không phải loại tiền thứ ba. Thành phẩm có thể là vũ khí boss sử dụng hoặc vũ khí dựa trên sức mạnh và hình tượng của boss đó.

Mỗi công thức cần ID, loại và số lượng lõi/nguyên liệu, chi phí Soul, ID và số lượng thành phẩm. Màn rèn hiển thị đang có/cần có, chỉ số thành phẩm, yêu cầu và scaling. Có thể rèn dù chưa đủ chỉ số sử dụng đầy đủ, nhưng cần cảnh báo trước.

Chỉ khi xác nhận thành công mới đồng thời tiêu Soul, lõi, nguyên liệu và trao vũ khí. Kiểm tra lại toàn bộ điều kiện khi xác nhận, chặn thao tác lặp và khôi phục nhất quán khi ghi lưu thất bại theo chính sách giao dịch được chọn.

### 5.4. Dùng Soul mua điểm nâng trong tương lai

Giữ dưới dạng khả năng mở rộng, chưa thay cơ chế lên cấp nhận 5 điểm. Cần chốt riêng giá, giới hạn, điều kiện mở và cách tăng chi phí. Chỉ số dư Soul thực sự và giao dịch được xác nhận mới có thể sinh điểm nâng; không dùng Level để suy lại số điểm đã mua.

## 6. Character và màn nâng cấp tại campfire

### 6.1. Character

Đề xuất giữ bố cục và hình ảnh đã có, thay dữ liệu tĩnh bằng dữ liệu thật:

- Tên nhân vật, Level, EXP hiện tại/ngưỡng kế tiếp.
- HP/stamina tối đa tính từ thuộc tính; giao diện chiến đấu tiếp tục theo dõi tài nguyên hiện tại.
- Tám thuộc tính mới, mô tả tác dụng, nguồn đóng góp và giá trị kết quả có liên quan.
- Coin và Soul cập nhật khi nhận thưởng, giao dịch hoặc tải save.
- Cập nhật khi mở menu và khi dữ liệu thay đổi, không chỉ ở `_ready()`.

Arts Compatibility và Faith vẫn có thể lưu điểm đã nâng theo yêu cầu về tám stat, nhưng UI phải ghi rõ tác dụng chờ hệ thống Arts/Divine Arts. Các phần Dark Arts Assimilation chưa có gameplay tương ứng cũng được ghi rõ; không hiển thị như đã có đủ nguồn ulti hoặc skill 1–4.

### 6.2. Nâng cấp

Thay hai hàng nâng HP/stamina bằng danh sách tám thuộc tính có thể cuộn. Đề xuất:

1. Hiện điểm chưa phân bổ, chỉ số hiện tại và mô tả.
2. Dùng `− / +` để phân bổ thử; hiển thị `hiện tại → sau nâng` và kết quả HP/stamina/ATK liên quan.
3. Chỉ cho giảm phần điểm đang phân bổ thử, không mặc nhiên mở chức năng tẩy điểm đã xác nhận.
4. Xác nhận một lần mới tiêu điểm, áp vào Player và lưu theo slot hợp lệ. Hủy/đóng bỏ bản phân bổ thử.
5. Lỗi ghi lưu phải có thông báo và cách khôi phục nhất quán; không hiện thành công khi thao tác chưa hoàn tất.

Nếu một lần nâng làm trang bị vừa đủ yêu cầu, màn xem trước cần cho thấy sát thương trở về 100%, skill được mở hoặc passive giáp được kích hoạt. Không tự hồi đầy tài nguyên khi đổi menu hay tính lại chỉ số; chính sách bù HP/stamina khi tăng tối đa cần được xác định và kiểm thử.

### 6.3. Equipment và HUD

Mỗi món hiện yêu cầu `đang có/cần có`; tô rõ điều kiện thiếu, tách sát thương nền và thưởng scaling, hiển thị hiệu lực thực nhận. HUD skill phân biệt khóa do thiếu chỉ số với đang hồi chiêu. Khi không có vũ khí/skill ở một tay thì bỏ qua an toàn, không tạo icon giả.

## 7. Dữ liệu, kiến trúc và lưu tiến trình

### 7.1. Phân trách nhiệm đề xuất

- **PlayerProgress:** Level, EXP, điểm đã nhận/chưa phân bổ và đầu tư thuộc tính; phát sự kiện khi dữ liệu thay đổi.
- **Cấu hình thuộc tính:** mức nền, hệ số tăng, giới hạn và các mốc tác dụng. Dùng Godot Resource hoặc dữ liệu tương đương, gom tại một nơi.
- **Định nghĩa trang bị:** yêu cầu, scaling, phòng thủ, passive và skill của từng món; tách khỏi trạng thái túi đồ/trang bị của slot chơi.
- **Model Player:** nhận kết quả chỉ số đã tính để thực thi gameplay, kết hợp Fracture/buff; không sở hữu dữ liệu riêng mâu thuẫn với progression.
- **Ví Coin/Soul và giao dịch:** kiểm tra/cập nhật số dư, phần thưởng và chi phí; giao diện không tự sửa tiền.
- **SaveManager:** đọc, kiểm tra, migration, backup và ghi dữ liệu; UI nhận kết quả thành công/thất bại.
- **UI:** đọc snapshot và gửi yêu cầu; dần bỏ NodePath giao diện hard-code khỏi PlayerProgress, tránh progression phải biết cấu trúc menu.

Đây là ranh giới đề xuất, không phải danh sách component mới đã tạo. Khi thực hiện chỉ tách module phục vụ luồng cần dùng, không refactor toàn bộ game cùng lúc.

### 7.2. Dữ liệu cần lưu

Level/EXP, điểm chưa phân bổ, điểm đã nâng của tám thuộc tính, Coin/Soul, trang bị theo ID và tiến độ phần thưởng tương ứng. Khi có túi đồ/rèn, bổ sung số lượng lõi/nguyên liệu, thành phẩm và dữ liệu giao dịch cần thiết. Arts/Divine Arts chưa có gameplay thì không tự sinh dữ liệu chiêu hoặc vật phẩm giả.

Chỉ lưu dữ liệu gốc cần thiết; chỉ số suy ra được tính lại bằng công thức tập trung, tránh tải save cộng scaling thêm lần nữa. Các snapshot phục vụ tương thích phải có quy tắc rõ ràng, không trở thành nguồn chân lý thứ hai.

### 7.3. Save cũ và thay cấu hình điểm mỗi cấp

Đề xuất migration một lần, có phiên bản nhận diện:

- Giữ Level, EXP và điểm hợp lệ chưa tiêu.
- Hoàn lại điểm từng dùng nâng HP/stamina vì hai thao tác đó bị bỏ.
- Bù chênh lệch giữa luật cũ và 5 điểm/cấp cho các cấp đã nhận, không bù lặp khi tải lại.
- Với save chuẩn dùng đúng luật cũ 1 điểm/cấp, chưa có thuộc tính mới hoặc nguồn điểm khác, có thể bắt đầu từ `điểm cũ chưa tiêu + số nâng HP + số nâng stamina + 4 × (level − 1)`.
- Không áp công thức trên mù quáng cho save thử/debug hoặc save từng dùng cấu hình thưởng khác. Kiểm tra dữ liệu nguồn, giữ backup và không tự cắt điểm bổ sung hợp lệ.
- Khi bỏ bonus HP/stamina cũ, tính lại theo thuộc tính mới; cần thông báo chuyển cơ chế và chốt cách xử lý HP hiện tại. Không coi hoàn điểm là giữ nguyên mọi giá trị tối đa cũ.

Đổi số điểm mỗi cấp về sau chỉ áp cho các lần lên cấp mới, trừ khi có quyết định migration riêng. Không mỗi lần tải lại đều tính lại tổng điểm từ cấu hình mới. Điểm mua bằng Soul sau này phải có dữ liệu theo dõi riêng để không bị mất khi migration.

Mọi kiểm thử migration/giao dịch phải dùng bản sao project và thư mục dữ liệu riêng, không ghi hoặc xóa save chơi thật.

## 8. Phân kỳ và trạng thái triển khai — 24/10/2026

Người dùng đã chọn **triển khai hệ chỉ số/trang bị/Coin/Soul theo phân kỳ** trong lượt tiếp quản. Phạm vi đã có nền được thực hiện như sau:

1. **Đã có nền thuộc tính:** Resource cấu hình, tám điểm đầu tư, thưởng điểm/cấp, công thức HP/stamina/hồi và scaling Prowess/Strength. Dark Arts Assimilation có damage Sentinel và giảm duy trì; các phần còn lại chưa nối. Giữ tuning/rig/combat ngoài phạm vi.
2. **Đã có save/menu:** schema v2; đọc/migration v1 trong RAM, archive trước ghi; Character đọc thật; campfire phân bổ thử, xác nhận/hủy và giữ dữ liệu khi ghi thất bại. Chính sách khởi điểm: giữ số HP/stamina hiện có, chỉ clamp nếu vượt tối đa mới, không hồi miễn phí. Chuyển v1 hoàn điểm cũ và bù luật cấp, không giữ bonus HP/stamina trực tiếp.
3. **Đã có với Saber:** yêu cầu/scaling riêng WeaponData, phạt thiếu yêu cầu một lần, chặn Q trước side effect; HUD hiện LOCK và yêu cầu đang có/cần có. Equipment hiển thị thông tin vũ khí hiện cầm; slot/grid túi đồ vẫn là nền. Chưa có gameplay E/tay trái hoặc hệ equip nhiều món; không nghiệm thu chúng từ việc kiểm tra hai WeaponData độc lập.
4. **Đã có ví và thưởng EnemyBase:** Coin/Soul riêng theo slot, grant/debit kiểm điều kiện trong RAM, Character cập nhật và save roundtrip. EnemyBase/SpineEnemy/Wobtear nhận tiền một lần mỗi vòng đời. Số thưởng là cấu hình thử; enemy legacy script khác chưa đổi. Tiền ghi cùng progression khi lưu hợp lệ, chưa tự ghi từng kill. Boss riêng, Observe/nhiệm vụ và chính sách phần thưởng tương ứng chưa triển khai.
5. **Chờ giáp và giao dịch:** hiện chưa có inventory, món giáp/passive và shop thật. Bước tiếp theo là xây dữ liệu/trạng thái trang bị trước khi áp yêu cầu 20% giáp, mua/bán, rồi công thức rèn boss. Ví hiện tại không chứng minh giao dịch đồ/rèn đã hoạt động.
6. **Chờ hệ thống tương lai:** Arts/mana, Divine Arts, nguồn ulti, skill Dark Arts 1–4; Resistance giảm debuff ngoài Bleed/Fracture chờ loại debuff có hỗ trợ. Soul mua điểm nâng vẫn là giai đoạn sau.

Thực hiện đã cập nhật [Player](../Bao_cao_ky_thuat/player_technical_report.md), [UI/save](../Bao_cao_ky_thuat/camera_ui_save_report.md), [Enemy](../Bao_cao_ky_thuat/enemy_technical_report.md) tại chỗ. Toàn bộ vị trí chỉnh/default/override ở [hướng dẫn chung](../Bao_cao_ky_thuat/huong_dan_tuy_chinh.md), không nhân bản hướng dẫn tuning tại đây. Không sửa báo cáo Word tuần 6; định hướng Observe trong báo cáo nghiên cứu vẫn là kế hoạch riêng chưa được triển khai bởi lượt này.

## 9. Tiêu chí kiểm thử khi triển khai

- Tăng EXP qua một hoặc nhiều cấp nhận đúng số điểm theo cấu hình; không nhận lặp khi tải lại.
- Từng thuộc tính làm thay đổi đúng chỉ số, không cộng dồn khi mở menu, đổi scene, respawn, tải save hoặc đổi Sentinel.
- Resistance không ảnh hưởng Bleed/Fracture; giảm xác suất/thời lượng đúng với debuff có hỗ trợ và không vượt giới hạn.
- Campfire không tiêu điểm khi xem trước/hủy; không âm điểm hoặc xác nhận hai lần; dữ liệu Character và Player khớp nhau.
- Vũ khí đủ yêu cầu, thiếu một hoặc nhiều yêu cầu, và vừa chạm ngưỡng cho kết quả đúng; phạt 20% đúng một lần, có kiểm tra làm tròn.
- Thiếu chỉ số khóa đúng skill từng tay; không trừ tài nguyên/cooldown; không làm hỏng ô tay trái trống hoặc HUD hồi chiêu.
- Giáp thiếu yêu cầu còn đúng 20% hiệu quả phòng thủ, passive riêng bị tắt; các món khác vẫn hoạt động đúng.
- Scaling kết hợp đúng hệ số đòn, Fracture và Sentinel; không nhân hoặc cộng lại qua nhiều lớp.
- Địch chỉ thưởng một lần mỗi vòng đời; sự kiện Observe/nhiệm vụ tuân theo dấu nhận thưởng đã lưu.
- Coin/Soul độc lập giữa các slot; mua/bán/rèn thiếu tài nguyên, lỗi ghi file hoặc thao tác lặp không làm mất/nhân tiền và đồ.
- Migration save cũ chạy một lần, có backup, giữ đúng EXP/điểm và xử lý an toàn trường hợp dữ liệu không chuẩn.
- Tính năng chờ phát triển được ghi rõ trên UI và tài liệu; không nghiệm thu chỉ từ icon hoặc API nền.

Các tiêu chí của hệ phụ thuộc chưa có vẫn là dự kiến. Phần đã triển khai có suite `tests/flow/progression_validation`, process restart và hồi quy save/Player/campfire/Fracture/Q/Sentinel/HUD; số checks thực chạy, ảnh và giới hạn được ghi trong [báo cáo Player — kiểm chứng](../Bao_cao_ky_thuat/player_technical_report.md#8-kiểm-chứng-và-giới-hạn). Không dùng các checks này làm kết quả đánh giá mô-đun cốt truyện NCKH.

## 10. Những quyết định còn mở

- Chỉ số khởi đầu, giới hạn điểm, soft cap và hệ số cụ thể của từng vũ khí/giáp.
- Chính sách bonus trang bị/buff tham gia điều kiện sử dụng; cách gộp phòng thủ nhiều nguồn và nhóm sát thương được giảm.
- Chính sách đã chọn cho đợt nền là giữ số tài nguyên hiện có, clamp nếu vượt tối đa mới. Thay đổi chính sách về sau cần quyết định và migration/test riêng.
- Loại debuff ngoài Bleed/Fracture mà Resistance hỗ trợ, cùng công thức xác suất và thời lượng cuối cùng.
- Các nguồn ulti, chi phí Dark Arts/Divine Arts và thời lượng hiệu ứng cụ thể.
- Phần thưởng Coin/Soul, dấu vết Observe được thưởng, giá shop, công thức rèn và thời điểm ghi lưu các giao dịch.
- Giá/điều kiện mua điểm nâng bằng Soul ở giai đoạn sau.

Những điểm này có thể được hoàn thiện bằng số thử nghiệm theo phạm vi người dùng cho phép, nhưng phải ghi rõ là đề xuất hoặc cấu hình thử, không gán thành quyết định đã duyệt từ trước.
