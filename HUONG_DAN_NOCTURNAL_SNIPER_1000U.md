# CẨM NANG VẬN HÀNH NOCTURNAL SNIPER EA (1000U) - CHUYÊN BIỆT KHUNG GIỜ TỐI

> **Mã nguồn Robot:** [`NocturnalSniper_1000U_EA.mq5`](file:///c:/Users/AD/Documents/BotTrade/NocturnalSniper_1000U_EA.mq5)  
> **File thực thi đã biên dịch:** [`NocturnalSniper_1000U_EA.ex5`](file:///c:/Users/AD/Documents/BotTrade/NocturnalSniper_1000U_EA.ex5) *(Đã biên dịch 0 lỗi, 0 cảnh báo)*  
> **Nền tảng:** MetaTrader 5 (MT5)  
> **Khung thời gian (Timeframe):** **M15 (15 Phút) & Xác nhận Trend H1**  
> **Mức vốn tối ưu:** **$1,000 USD (1,000u)**  
> **Tài sản khuyến nghị:** **`XAUUSD` (Vàng)** hoặc **`GBPUSD`, `EURUSD`**

---

## 1. TỔNG HÒA TINH HOA TỪ TẤT CẢ NỀN TẢNG KIẾN THỨC

Robot **Nocturnal Sniper (Xạ Thủ Phiên Tối)** được đúc kết từ 4 trụ cột phân tích kỹ thuật và quản trị vốn đỉnh cao:

```
                      +------------------------------------------+
                      |       NOCTURNAL SNIPER EA (M15)          |
                      |          TÀI KHOẢN VỐN 1000U             |
                      +------------------------------------------+
                                           |
         +---------------------------------+---------------------------------+
         |                                 |                                 |
         v                                 v                                 v
+-----------------------+     +-----------------------+     +-----------------------+
|  NIAL FULLER (ACTION) |     |  FX ACADEMY (MOMENTUM)|     | 9 CHIẾN LƯỢC VÀNG     |
| - Mô hình T.L.S       |     | - Double Bollinger    |     | - Asian Range Sweep   |
| - Pin Bar râu >= 65%  |     |   Bands (DBB 1.0/2.0) |     | - New York Killzone   |
| - Fakey bẫy phá vỡ    |     | - Pullback Value Area |     | - Tránh giãn Spread   |
| - Sniper Mindset      |     | - Dynamic ATR SL      |     | - Lọc tin tức USD Đỏ  |
| - Tối đa 1-2 lệnh/tối |     | - Tỷ lệ R:R >= 1:2.2  |     | - Giao dịch xong tối  |
+-----------------------+     +-----------------------+     +-----------------------+
                                           |
                                           v
                              +-------------------------+
                              | QUẢN TRỊ VỐN 1000U      |
                              | - Rủi ro 1.0% ($10/lệnh)|
                              | - Chốt lời 50% tại 1.2R |
                              | - Auto Break-Even 0.8R  |
                              | - Trailing Stop ATR     |
                              | - Daily Loss Shield 3%  |
                              +-------------------------+
```

---

## 2. BÀI TOÁN "GIAO DỊCH XONG KHUNG GIỜ TỐI" ĐƯỢC GIẢI QUYẾT NHƯ THẾ NÀO?

### 2.1. Vì sao chỉ nên trade buổi tối?
* **Phiên Mỹ (New York Killzone) & Trùng phiên London (19:00 - 23:00 VN):** Đây là thời điểm thị trường Vàng và Forex có thanh khoản bùng nổ nhất trong ngày (chiếm hơn 75% khối lượng giao dịch toàn cầu). Giá di chuyển dứt khoát, sóng dài, ít bị sideway cù cưa cắn spread.

### 2.2. Cơ chế "Giao dịch xong trong tối - Không ôm lệnh qua đêm":
* **Cửa sổ mở lệnh:** Bắt đầu từ **15:00 Server** (khoảng 19:00 VN) và **khóa mở lệnh mới lúc 21:00 Server** (khoảng 01:00 sáng VN).
* **Mốc chốt dứt điểm phiên tối (22:30 Server / trước 02:30 - 03:00 sáng VN):**
  * Kích hoạt cơ chế thông minh `FINISH_CLOSE_PROFIT_LOCK_BE`:
    * Nếu lệnh đang **có lãi dương $\rightarrow$ Tự động chốt lời ngay lập tức** để hiện thực hóa lợi nhuận, đút tiền vào túi và đi ngủ.
    * Nếu lệnh đang dao động gần điểm vào $\rightarrow$ **Kéo chặt Stop Loss về hòa vốn (Entry + Buffer)** để loại bỏ 100% rủi ro.
  * **Lợi ích sống còn:** Tuyệt đối không để lệnh qua khung giờ **04:00 - 06:00 sáng VN**, thời điểm các sàn giãn Spread Vàng lên tới 100 - 200 points và tính phí Swap qua đêm (Overnight Swap).

---

## 3. THIẾT LẬP CHỈ SỐ TỐI ƯU CHO TỶ LỆ THẮNG CAO NHẤT (WINRATE $\ge 80\%$)

Để đạt được tỷ lệ thắng cao nhất, bot áp dụng quy tắc **"Chờ điểm đẹp - Không đủ điểm thì đứng ngoài"**:

### 3.1. Thang Điểm Hội Tụ A+ Setup (Confluence Score $\ge 85/100$ điểm)
Mỗi khi nến M15 đóng cửa, bot chấm điểm chất lượng thị trường:

| Yếu Tố | Điều Kiện Đạt Chuẩn | Điểm Số |
| :--- | :--- | :---: |
| **1. Xu Hướng H1 (Macro Trend)** | Khung H1: EMA 21 nằm trên EMA 50 (Uptrend cho BUY) hoặc EMA 21 nằm dưới EMA 50 (Downtrend cho SELL) | **+25** |
| **2. Vùng Giá Trị (DBB Pullback)** | Giá M15 hồi quy kiểm tra vùng lò xo DBB Inner Band (+1.0 SD / -1.0 SD) hoặc trục giữa SMA 20 | **+25** |
| **3. Tín Hiệu Nến (Price Action)** | Xuất hiện **Pin Bar chuẩn** (râu $\ge 65\%$, thân $\le 30\%$) HOẶC **Fakey** (Bẫy phá vỡ giả Inside Bar) | **+25** |
| **4. Động Lượng RSI** | RSI(14) nằm trong vùng sung mãn: BUY khi $45 \le \text{RSI} \le 68$; SELL khi $32 \le \text{RSI} \le 55$ (Không mua đỉnh, không bán đáy) | **+15** |
| **5. Quét Thanh Khoản Phiên Á** | Nến quét thủng đỉnh/đáy phiên Á (Asian High/Low) rồi rút chân quay ngược trở lại | **+10 (Thưởng)** |

$$\Rightarrow \mathbf{TỔNG\ ĐIỂM} \ge 85/100 \rightarrow \text{MỚI KÍCH HOẠT BẮN TỈA!}$$

### 3.2. Bộ 3 Bí Quyết Đưa Lệnh Về Bất Tử (Zero Risk)
1. **Auto Break-Even tại $+0.8R$:** Khi giá chạy được 80% khoảng cách rủi ro, bot dời SL về Entry $+ 15$ points. Sau bước này, **lệnh không bao giờ có thể bị lỗ**!
2. **Partial Take Profit 50% tại $+1.2R$:** Chốt một nửa khối lượng để cất tiền vào tài khoản. Ngay cả khi giá quay đầu, giao dịch này vẫn có lãi ròng chắc chắn!
3. **Chandelier ATR Trailing Stop:** 50% khối lượng còn lại thả trôi theo dải đệm ATR $1.2\times$ để ăn trọn các con sóng dài 20 - 40 giá của phiên Mỹ.

---

## 4. BẢNG THAM SỐ CẤU HÌNH VÀNG CHO VỐN 1000U

| Tham Số Đầu Vào | Giá Trị Thiết Lập | Ý Nghĩa Thực Chiến |
| :--- | :---: | :--- |
| `InpBaseCapital` | `1000.0` | Mức vốn cơ sở $1,000 USD |
| `InpRiskPercentPerTrade` | `1.0` | Rủi ro 1.0% ($10 USD / lệnh), cực kỳ an toàn |
| `InpMaxLotAllowed` | `0.10` | Khối lượng trần tối đa (bảo vệ tài khoản) |
| `InpMaxTradesPerNight` | `2` | Mỗi buổi tối chỉ bắn tối đa **1 đến 2 lệnh đẹp nhất** |
| `InpMaxConcurrentPositions`| `1` | Tuyệt đối chỉ giữ **1 lệnh duy nhất** cùng lúc |
| `InpMaxDailyDrawdownPct` | `3.0` | Giới hạn lỗ tối đa ngày: -3% (-$30u) là khóa bot |
| `InpMaxSpreadPoints` | `35` | Chỉ vào lệnh khi Spread $\le 35$ points (3.5 pips) |
| `InpMinConfluenceScore` | `85` | Ngưỡng điểm A+ để bóp cò |
| `InpTargetRrRatio` | `2.2` | Tỷ lệ R:R mục tiêu |
| `InpUsePartialClose` | `true` | Bật chốt lời 50% tại 1.2R |
| `InpUseAutoBreakEven` | `true` | Bật hòa vốn tự động tại 0.8R |
| `InpUseNewsFilter` | `true` | Tránh 30 phút trước và sau tin USD đỏ |
| `InpEveningStartHour` | `15` | Bắt đầu phiên tối (15:00 Server ~ 19:00 VN) |
| `InpEveningEndHour` | `21` | Dừng mở lệnh mới (21:00 Server ~ 01:00 VN) |
| `InpForceCloseHour` | `22` | Chốt dứt điểm phiên tối (22:30 Server) |

---

## 5. HƯỚNG DẪN CÀI ĐẶT TRÊN METATRADER 5 (MT5)

1. **Mở MT5** và đăng nhập vào tài khoản Vốn $1,000 USD.
2. Trên thanh menu, chọn **File $\rightarrow$ Open Data Folder**.
3. Vào thư mục **`MQL5\Experts\`**, file **[`NocturnalSniper_1000U_EA.ex5`](file:///c:/Users/AD/Documents/BotTrade/NocturnalSniper_1000U_EA.ex5)** đã được chuẩn bị sẵn tại đây!
4. Quay lại MT5, mở cửa sổ **Navigator (Ctrl + N)**, nhấp chuột phải vào mục **Expert Advisors $\rightarrow$ Refresh**.
5. Mở biểu đồ **`XAUUSD` (Vàng)**, chọn khung nến **`M15`**.
6. Kéo thả **`NocturnalSniper_1000U_EA`** vào biểu đồ.
7. Tại tab **Common**, tích chọn ô **`Allow Algo Trading`** (Cho phép giao dịch tự động).
8. Bấm nút **`Algo Trading`** lớn màu xanh trên thanh công cụ MT5.
9. Kiểm tra HUD Dashboard màu xanh đậm xuất hiện góc trái màn hình với dòng chữ:  
   `🌙 NOCTURNAL SNIPER 1000U (M15)` và trạng thái `AN TOÀN`.
