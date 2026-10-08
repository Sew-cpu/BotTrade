# CẨM NANG THỰC CHIẾN QUANTUMPULSE SCALPER EA v2.0
## HỆ THỐNG GIAO DỊCH LƯỚT SÓNG ĐỘC QUYỀN CHO VÀNG (XAUUSD ONLY)

> **Tên Robot:** `QuantumPulse_Scalper_EA.mq5` (**GOLD EDITION v2.0**)  
> **Cặp giao dịch độc quyền:** **XAUUSD / GOLD** (Tự động từ chối các cặp forex khác)  
> **Khung thời gian tối ưu:** **M5** (Khung vào lệnh) kết hợp **H1** (Khung xu hướng)  
> **Tần suất mục tiêu:** Trung bình **~1 lệnh / tiếng** trong phiên sôi động  
> **Bản quyền & Triết lý:** Độc lập hoàn toàn, tích hợp tinh hoa **FX Academy (DBB)**, **Nial Fuller (TLS & EMA)** và công nghệ **Chống quét râu nến Vàng (Anti-Wick Hunt)**.

---

## 1. TẠI SAO PHẢI TỐI ƯU RIÊNG CHO VÀNG (XAUUSD)?

Vàng là "ông vua biến động" trong thị trường tài chính:
* **Biên độ cực lớn:** Mỗi ngày Vàng dao động từ $15 đến $40/ounce (1,500 - 4,000 points).
* **Độ giãn Spread đặc thù:** Spread Vàng ở các sàn dao động từ 15 - 35 pips (150 - 350 points), không thể áp dụng mức spread 30-50 points của Forex.
* **Tập tính quét râu nến (Stop Hunt):** Vàng liên tục tạo các râu nến dài để săn thanh khoản trước khi chạy xu hướng thật.

**QuantumPulse Scalper EA v2.0** được thiết kế lại toàn bộ thuật toán để "đo ni đóng giày" cho đúng tính cách của Vàng!

---

## 2. BỘ THÔNG SỐ VÀ CƠ CHẾ VÀNG ĐỘC QUYỀN

### 2.1. Kiểm Tra Ép Buộc Symbol Vàng (`IsGoldSymbol`)
* Bot tự động kiểm tra tên mã giao dịch (`XAUUSD`, `GOLD`, `XAUUSDm`, `XAUUSD.ecn`...). 
* Nếu người dùng vô tình gắn vào cặp tiền tệ Forex khác, bot sẽ hiện cảnh báo và từ chối khởi động nhằm bảo vệ an toàn.

### 2.2. Lọc Điểm Vào Hội Tụ A+ Trên Khung M5 Vàng
1. **Xu hướng lớn H1:** `EMA 21` > `EMA 50` dốc lên (chỉ Buy) hoặc `EMA 21` < `EMA 50` dốc xuống (chỉ Sell).
2. **Hồi quy M5 (Value Area):** Giá Vàng hồi quy (Pullback) chạm vào vùng đệm giữa `EMA 8` và `EMA 21` trên M5, hoặc nằm trong phân vùng bùng nổ của **Double Bollinger Bands** (Cliff Wachtel).
3. **Bộ lọc xung lượng RSI:** Chỉ Buy khi RSI từ 40 - 68 (tránh bắt dao rơi, tránh đu đỉnh). Chỉ Sell khi RSI từ 32 - 60 (tránh bán đáy).
4. **Nến kích hoạt rút chân (Anti-Wick Hunt):** 
   * Yêu cầu râu nến Pin Bar rút chân $\ge 60\%$ chiều dài nến.
   * Thân nến nhỏ $\le 28\%$.
   * Biên độ nến $\ge 0.5 \times \text{ATR}$ (loại bỏ nến Doji rác).

### 2.3. Bộ Lọc Tin Tức Đỏ USD (MQL5 Economic Calendar)
* Tích hợp trực tiếp cổng dữ liệu Lịch kinh tế của MT5 (`CalendarValueHistory`).
* **Tránh bão tin đỏ USD (CPI, Non-Farm Payrolls, FOMC, PPI, Retail Sales)**: Tự động dừng vào lệnh trước 30 phút và sau 30 phút quanh thời điểm công bố tin tức đỏ.
* **Auto Protect Breakeven**: Nếu đang có lệnh mở trước giờ tin, bot tự động kéo Stop Loss về mốc **Hòa Vốn (Breakeven)** để dù giá giật mạnh 2 đầu cũng không thể gây lỗ cho tài khoản.

### 2.4. Bộ Đo Sốc Biến Động Vàng (Volatility Shock Filter)
* Thuật toán so sánh: Tỷ lệ $\frac{\text{ATR}(3)}{\text{ATR}(20)} \ge 2.2\times$.
* Nếu Vàng giật giá bất thường do tin giật gân hoặc cá mập quét lệnh, bot lập tức tạm dừng để tránh bị trượt giá (slippage).

### 2.5. Stop Loss, Take Profit & Quản Lý Lệnh Thực Chiến
* **SL Động:** $1.6 \times \text{ATR}(14)$ hoặc Đáy/Đỉnh nến Pin Bar cộng thêm **đệm an toàn $25 \text{ points}$** ($0.25 giá Vàng).
* **SL Kẹp an toàn:** Tối thiểu **$1.8 giá** (180 points) và tối đa **$4.5 giá** (450 points).
* **TP Toàn phần:** Tỷ lệ Risk:Reward **1:2.0** (mục tiêu ăn từ $3.5 - $8.0 giá Vàng).
* **Chốt lời TP1 (50% khối lượng):** Khi giá chạy được **$+1.0\text{R}$** (lãi khoảng $1.8 - $2.5 giá), bot lập tức chốt $50\%$ khối lượng để bỏ tiền vào túi.
* **Auto Break-Even:** Khi giá chạy được **$+0.8\text{R}$**, tự động dời SL về Entry $+ 25 \text{ points}$ bù phí spread (hoàn toàn không còn rủi ro).
* **Micro-ATR Trailing Stop:** Khi giá vượt $+1.2\text{R}$, SL bám đuôi theo khoảng cách $1.3 \times \text{ATR}$ với bước nhảy mịn $20 \text{ points}$ ($0.20 giá).

---

## 3. THÔNG SỐ VẬN HÀNH KHUYẾN NGHỊ CHO VÀNG (M5)

| Tham Số | Giá Trị Khuyên Dùng | Ý Nghĩa |
| :--- | :--- | :--- |
| **`InpRiskPercent`** | `1.0%` (hoặc `1.5%`) | Mức rủi ro an toàn chuẩn toán học cho mỗi lệnh Vàng. |
| **`InpFixedLotSize`** | `0.01` | Khối lượng tối thiểu nếu chọn chế độ Lot cố định. |
| **`InpMaxLotAllowed`** | `0.20` | Trần lot tối đa chặn rủi ro tài khoản. |
| **`InpMaxSpreadPoints`** | `350` | Ngưỡng spread cho phép (Exness ~220-280 pts, sàn ECN ~120-180 pts). |
| **`InpMinCooldownMinutes`** | `40` | Nghỉ 40 phút giữa các nhịp sóng để đạt nhịp ~1 lệnh/giờ. |
| **`InpTradingStartHour`** | `8` | 8h sáng giờ server (bắt đầu phiên London sôi động). |
| **`InpTradingEndHour`** | `21` | 21h tối giờ server (tránh giờ đóng phiên New York giãn spread). |
| **`InpNotifySessionEnd`** | `true` | Tự động phát chuông cảnh báo & thống kê mỗi khi hết phiên (Á, Âu, Mỹ, cuối tuần). |
| **`InpSendPushOnSessionEnd`**| `true` | Đẩy Push Notification báo cáo PnL & vị thế về MT5 di động khi hết phiên. |
| **`InpMaxDailyLossPercent`** | `4.0%` | Dừng ngày nếu tổng sụt giảm chạm 4% vốn. |

---

## 4. HƯỚNG DẪN CÀI ĐẶT TRÊN METATRADER 5

1. Mở MT5 ➔ Nhấn **`F4`** (MetaEditor).
2. Mở file [`QuantumPulse_Scalper_EA.mq5`](file:///c:/Users/AD/Documents/BotTrade/QuantumPulse_Scalper_EA.mq5).
3. Nhấn **`F7`** để biên dịch (`0 errors, 0 warnings`).
4. Mở biểu đồ **`XAUUSD`** (hoặc `GOLD`), chọn khung nến **`M5`**.
5. Kéo `QuantumPulse_Scalper_EA` thả vào biểu đồ ➔ Tab Common tích chọn **`Allow Algo Trading`**.
6. Bấm nút **Algo Trading** (xanh) trên MT5.
7. Bảng điều khiển HUD màu vàng ánh kim sẽ xuất hiện góc trái màn hình, theo dõi nhịp sóng và hiển thị trạng thái `Cadence: SẴN SÀNG QUÉT SÓNG VÀNG`!
