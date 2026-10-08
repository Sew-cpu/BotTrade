# CẨM NANG VẬN HÀNH BOT ZENITH SNIPER M15 - CHUYÊN BIỆT CHO VÀNG (XAUUSD) VỐN 100$

> **Mã nguồn Robot:** [`ZenithSniper_M15_EA.mq5`](file:///c:/Users/AD/Documents/BotTrade/ZenithSniper_M15_EA.mq5) *(v4.0 - GOLD EDITION)*  
> **Nền tảng:** MetaTrader 5 (MT5)  
> **Khung thời gian (Timeframe):** **M15 (15 Phút)**  
> **Số vốn ban đầu:** **$100 USD (100u)**  
> **Tài sản độc quyền:** **`XAUUSD` (GOLD)**  

---

## 1. TỔNG HÒA TINH HOA TỪ 3 NỀN TẢNG KIẾN THỨC

Robot **ZenithSniper_M15_EA** được chế tác bằng cách đúc kết những gì ưu việt nhất từ:

```
                      +---------------------------------------+
                      |       ZENITH SNIPER EA (M15)          |
                      |          TÀI KHOẢN VỐN 100$           |
                      +---------------------------------------+
                                          |
        +---------------------------------+---------------------------------+
        |                                 |                                 |
        v                                 v                                 v
+-----------------------+     +-----------------------+     +-----------------------+
|  FX ACADEMY (Cliff)   |     | NIAL FULLER (Action)  |     |   FOREXBROKERS.COM    |
| - Double Bollinger    |     | - Mô hình T.L.S       |     | - Quản trị tài khoản  |
|   Bands (DBB 1.0/2.0) |     | - Pin Bar Rejection   |       nhỏ $100 (Max 0.01)   |
| - 3 Zones (Buy/Sell)  |     | - Fakey Bẫy Phá Vỡ    |     | - Daily Loss Guard    |
| - Dynamic ATR SL      |     | - Set and Forget      |     | - Lọc giãn Spread     |
| - Tỷ lệ R:R >= 1:2.2  |     | - Bắn tỉa (Sniper)    |     | - Tránh đêm giãn phí  |
+-----------------------+     +-----------------------+     +-----------------------+
```

---

## 2. VÌ SAO BOT NÀY GIẢI QUYẾT TRIỆT ĐỂ BÀI TOÁN "VỐN NHỎ 100$" MÀ VẪN AN TOÀN?

Tài khoản $100 là ngưỡng vốn nhạy cảm nhất trong Forex. Nếu dùng bot thông thường (nhồi Martingale, rải lưới Grid hoặc thả nổi không SL), chỉ cần 1 con sóng mạnh là tài khoản 100$ sẽ bốc hơi trong vài giờ.

`ZenithSniper_M15_EA` áp dụng bộ 5 cơ chế bảo vệ thép:

1. **Giới hạn số lệnh đồng thời:** Tuyệt đối chỉ mở **1 vị thế duy nhất** (`InpMaxOpenPositions = 1`). Không bao giờ nhồi lệnh hay gồng lỗ.
2. **Kẹp Lot vi mô tự động (Safe Lot Clamping):** 
   * Với vốn $100$, bot tự tính toán khối lượng theo tỷ lệ rủi ro $1.5\%$ (\$1.50 cho mỗi lệnh thua).
   * Khối lượng được cố định ở mức an toàn nhất là **0.01 Lot**.
3. **Lá chắn lỗ trong ngày (Daily Loss Guard):**
   * Giới hạn mức sụt giảm tối đa trong ngày là **3.5%** (tức \$3.50).
   * Nếu không may gặp 2 lệnh thua liên tiếp trong ngày, bot sẽ tự động kích hoạt chế độ **`[LOCKED]`**, ngắt toàn bộ giao dịch mới cho tới ngày hôm sau. Vốn gốc được bảo toàn nguyên vẹn.
4. **Bộ lọc dãn Spread & Giờ đêm:**
   * Từ chối mở lệnh nếu Spread thị trường vượt quá `28 points` (tránh trả phí ngớ ngẩn).
   * Dừng mở lệnh từ 21:00 đến 08:00 hôm sau để tránh bão trượt giá lúc giao phiên Mỹ - Á.
5. **Cơ chế Tự Động Hòa Vốn (Auto Break-Even) & Trailing Stop:**
   * Khi lệnh chạy có lãi đạt **$+1.0R$** (lợi nhuận bằng khoảng cách SL), bot dời SL về Entry + bù phí spread $\rightarrow$ Biến lệnh thành **Risk-Free Trade (Rủi ro bằng 0)**.
   * Khi giá đạt $+1.4R$, bot kích hoạt **Chandelier Trailing Stop** bám theo sóng để gồng trọn vẹn mức lãi $1:2.2$ hoặc cao hơn.

---

## 3. LOGIC KỸ THUẬT VÀO LỆNH TRÊN KHUNG M15

### 3.1. Bộ lọc xu hướng khung lớn (Trend - H1)
* Sử dụng bộ đôi đường trung bình động động của Nial Fuller: **EMA 21** và **EMA 50** trên khung H1.
* Chỉ tìm kiếm lệnh **BUY** khi EMA 21 > EMA 50.
* Chỉ tìm kiếm lệnh **SELL** khi EMA 21 < EMA 50.

### 3.2. Bộ lọc phân vùng Double Bollinger Bands (DBB - M15)
* Áp dụng dải Bollinger Bands kép (Chu kỳ 20):
  * Dải ngoài: Độ lệch chuẩn 2.0 (Outer Band).
  * Dải trong: Độ lệch chuẩn 1.0 (Inner Band).
* Nhận diện chính xác khi nào thị trường có động lượng thật sự (Buy Zone / Sell Zone), loại bỏ hoàn toàn các tín hiệu nhiễu khi giá kẹt trong vùng Neutral Zone.

### 3.3. Tín hiệu kích hoạt (Triggers)
1. **Bullish Pin Bar / Bearish Pin Bar:** Râu nến chiếm $\ge 60\%$ toàn bộ cây nến, từ chối giá tại các mép dải DBB.
2. **Fakey Pattern (Inside Bar False Breakout):** Nến tạo bẫy phá vỡ giả qua nến con rồi rút chân đóng cửa trở lại trong lòng nến mẹ.

---

## 4. HỆ THỐNG CẬP NHẬT TIN TỨC & PHÁT HIỆN SỐC BIẾN ĐỘNG THẾ GIỚI (V2.0)

Để bảo vệ an toàn tối đa cho tài khoản nhỏ $100 khỏi các sự kiện bão thị trường (Non-Farm Payrolls, FOMC, CPI, Chiến tranh địa chính trị), phiên bản v2.0 tích hợp **2 tầng phòng vệ thông minh**:

### 4.1. Bộ Lọc Tin Tức Kinh Tế Tự Động (MQL5 Economic Calendar API)
* Tự động nhận diện cặp tiền đang chạy (ví dụ `EURUSD` $\rightarrow$ theo dõi tin `EUR` và `USD`; `XAUUSD` $\rightarrow$ theo dõi tin `USD`).
* **Quy tắc 30 Phút:** Tự động **DỪNG MỞ LỆNH** trước giờ tin đỏ 30 phút và sau giờ tin đỏ 30 phút (`InpMinsBeforeNews = 30`, `InpMinsAfterNews = 30`).
* **Lá chắn Pre-News Protection:** Nếu đang có một lệnh mở có lãi trước khi tin đỏ công bố, bot sẽ **tự động kéo Stop Loss về hòa vốn (Entry + 1 pip)** để bảo vệ tài khoản khỏi cú giật 2 đầu (Whipsaw).

### 4.2. Bộ Đo Lường Sốc Biến Động Toàn Cầu (World Volatility Shock Detector)
* Đo lường tỷ lệ xung lực: $\frac{\text{ATR(3) [Biến động siêu nhanh]}}{\text{ATR(30) [Mặt bằng biến động nền]}}$.
* Nếu tỷ lệ này vượt **$1.8\times$** (`InpVolSpikeThreshold = 1.8`), tức là thị trường thế giới đang rơi vào trạng thái bão giá / Flash Crash $\rightarrow$ Bot tự động khóa mở lệnh mới.
* **Bộ đo kiệt quệ thanh khoản (Spread Shock):** Nếu Spread thị trường bất ngờ giãn vọt gấp $1.6\times$ so với bình thường $\rightarrow$ Tạm dừng ngay lập tức.

---

## 5. TÍNH NĂNG NHỒI LỆNH ĐỈNH CAO (SMART PYRAMIDING) & TÙY CHỌN KHÔNG KHÓA TÀI KHOẢN (V3.0)

Theo yêu cầu tối ưu hóa lợi nhuận tối đa khi gặp các cơ hội thị trường cực đẹp:

### 5.1. Định nghĩa "Điểm Vào Cực Kỳ Đẹp" (Super Confluence Setup)
Bot chỉ kích hoạt nhồi thêm vị thế khi thỏa mãn đồng thời 3 yếu tố hội tụ đỉnh cao:
1. **Xu Hướng Khung Lớn H1 (Trend):** EMA 21 nằm trên EMA 50 dốc mạnh (Uptrend) đối với lệnh BUY; hoặc EMA 21 nằm dưới EMA 50 (Downtrend) đối với lệnh SELL.
2. **Tín Hiệu Nến Đột Biến (Action Trigger):** Xuất hiện nến **Pin Bar cực chuẩn** (râu $\ge 60\%$, thân $\le 30\%$ rút chân quét cản) HOẶC nến **Fakey False Breakout**.
3. **Phân Vùng Động Lượng DBB:** Nến đóng cửa dứt khoát bên trong **Buy Zone (+1 SD đến +2 SD)** hoặc **Sell Zone (-1 SD đến -2 SD)**.

### 5.2. Nguyên Tắc Nhồi Lệnh Dương (Scale-In On Profit)
* **Không nhồi khi đang lỗ:** Tuyệt đối không nhồi lệnh kiểu Martingale khi thị trường đi ngược kỳ vọng.
* **Chỉ nhồi khi lệnh trước ĐANG CÓ LÃI:** Bot chỉ nhồi thêm khi lệnh trước đã có lãi tối thiểu **$0.8R$** (`InpPyramidMinProfitR = 0.8`).
* **Đồng Bộ Stop Loss (Sync All SL):** Khi một lệnh nhồi mới được mở, bot sẽ tự động kéo Stop Loss của toàn bộ các lệnh cũ lên mức **HÒA VỐN (Breakeven)**. Nhờ đó, **tổng thể toàn bộ cụm lệnh không bao giờ bị âm vốn**, biến cú nhồi lệnh thành cơ hội nhân đôi/nhân ba lợi nhuận hoàn toàn không rủi ro!

### 5.3. Tùy Chọn "Không Khóa Tài Khoản" (No Account Lock)
* Nếu bạn muốn bot tự do giao dịch liên tục mà không bao giờ tự dừng do chạm giới hạn sụt giảm hàng ngày:
  * Đặt tham số: **`InpUseDailyLossGuard = false`**.
  * Bot sẽ chuyển sang trạng thái: `[UNLOCKED] KHONG KHOA TAI KHOAN`, giao dịch xuyên suốt mà không có bất kỳ lệnh ngắt tự động nào.

---

## 6. HƯỚNG DẪN CÀI ĐẶT & BACKTEST TRÊN MT5

### Bước 1: Mở MetaEditor và Biên dịch (Compile)
1. Trong MT5, nhấn **`F4`** để mở MetaEditor.
2. Mở file [`ZenithSniper_M15_EA.mq5`](file:///c:/Users/AD/Documents/BotTrade/ZenithSniper_M15_EA.mq5).
3. Nhấn nút **Compile** (phím tắt **`F7`**). Đảm bảo kết quả hiển thị: `0 errors, 0 warnings`.

### Bước 2: Gắn Bot vào biểu đồ
1. Mở biểu đồ cặp tiền: **EURUSD** (hoặc GBPUSD).
2. Chuyển khung thời gian biểu đồ về: **M15**.
3. Kéo bot `ZenithSniper_M15_EA` từ cửa sổ *Navigator* thả vào biểu đồ.
4. Trong tab *Common*, tích chọn **Allow Algo Trading** (Cho phép giao dịch thuật toán).
5. Nhấn **OK**. Bảng điều khiển màu sắc sẽ hiện lên ở góc trên bên trái màn hình.

---

## 7. BẢNG THÔNG SỐ CẤU HÌNH V3.0 KHUYẾN NGHỊ CHO VỐN $100

| Nhóm Tính Năng | Tham Số Cấu Hình | Giá Trị Mặc Định | Ý Nghĩa / Cách Hoạt Động |
| :--- | :--- | :--- | :--- |
| **Nhồi Lệnh** | `InpEnablePyramiding` | **`true`** | **BẬT** tính năng tự động nhồi lệnh. |
| **Nhồi Lệnh** | `InpMaxPositionsTotal` | **`3`** | Tối đa mở 3 lệnh (mỗi lệnh 0.01 lot). |
| **Nhồi Lệnh** | `InpPyramidOnlyInProfit`| **`true`** | Chỉ nhồi khi lệnh cũ đang có lãi (Bảo vệ vốn). |
| **Nhồi Lệnh** | `InpPyramidMinProfitR` | **`0.8`** | Lệnh cũ phải có lãi tối thiểu 0.8R mới nhồi lệnh tiếp. |
| **Nhồi Lệnh** | `InpSuperSetupOnly` | **`true`** | Chỉ nhồi khi gặp Điểm Vào Cực Kỳ Đẹp (Super Setup). |
| **Nhồi Lệnh** | `InpSyncStopLossOnPyramid`| **`true`** | Tự động dời SL toàn bộ lệnh cũ về hòa vốn khi nhồi. |
| **Bảo Vệ Vốn** | `InpUseDailyLossGuard` | **`false`** | **KHÔNG KHÓA TÀI KHOẢN** (Tự do giao dịch liên tục). |
| **Bảo Vệ Vốn** | `InpRiskPercent` | **`1.5`** | Rủi ro \$1.50 cho mỗi vị thế trên tài khoản \$100. |
| **Tin Tức** | `InpUseNewsFilter` | **`true`** | Tránh bão tin đỏ (NFP/FOMC/CPI). |
| **Biến Động** | `InpUseVolatilityFilter`| **`true`** | Tránh bão giật nến Flash Crash. |
| **Chiến Lược** | `InpRiskRewardRatio` | **`2.2`** | Tỷ lệ R:R = 1:2.2 (Lãi gấp 2.2 lần rủi ro). |
