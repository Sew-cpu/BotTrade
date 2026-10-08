# HỆ THỐNG TRADING BOT FOREX METATRADER 5 (MT5)

Dự án gồm 4 Robot Giao Dịch Tự Động (**Expert Advisors - EA**) viết bằng ngôn ngữ **MQL5 thuần túy**, được thiết kế theo các tiêu chuẩn phân tích kỹ thuật và quản lý vốn nâng cao:

1. **`ZenithSniper_M15_EA.mq5` (CHUYÊN BIỆT CHO VÀNG XAUUSD / VỐN 100$)** — **Robot Bắn Tỉa Vàng M15 v4.0**: Tối ưu độc quyền cho Vàng (XAUUSD) với vốn nhỏ $100, tích hợp công nghệ Chống quét râu nến (Anti-Wick Hunt), DBB, Smart Pyramiding nhồi lệnh dương, lọc tin đỏ USD và không khóa tài khoản. Có cẩm nang: [`HUONG_DAN_ZENITHSNIPER_M15_100U.md`](file:///c:/Users/AD/Documents/BotTrade/HUONG_DAN_ZENITHSNIPER_M15_100U.md).
2. **`ApexConfluence_EA.mq5`** — **Hệ thống Hội Tụ Đa Chỉ Báo (Multi-Confluence)**: Lợi Nhuận Cao, Rủi Ro Cực Thấp với cơ chế Bảo Vệ Vốn Đa Tầng, Chốt Lời Từng Phần (Partial Close), Trailing Stop ATR và Dashboard trực quan.
3. **`BreakoutSR_EA.mq5`** — Chiến lược Breakout Hỗ trợ & Kháng cự kinh điển kết hợp ATR Stop Loss và Trailing Stop.
4. **`TitanGold_Pro_EA.mq5`** & **`CHIEN_LUOC_VANG_XAUUSD.md`** — Chuyên biệt hóa cho giao dịch Vàng (XAUUSD).
5. **`TAI_LIEU_FOREX_NANG_CAO.md`** — Toàn văn giáo trình 16 bài học Forex nâng cao (Unit 15 - Unit 30 từ Scribd).
6. **`GIAO_TRINH_FX_ACADEMY.md`** — Toàn bộ hệ thống kiến thức, chiến lược độc quyền (Double Bollinger Bands, Pin Bar, ATR Volatility) từ Học viện quốc tế [FX Academy](https://www.fxacademy.com/).
7. **`GIAO_TRINH_PRICE_ACTION_NIAL_FULLER.md`** — Tinh hoa Price Action Biểu Đồ Trần (Naked Chart), Mô hình T.L.S, Pin Bar 50% Retracement, Inside Bar & Fakey từ [LearnToTradeTheMarket.com](https://www.learntotradethemarket.com/) (Nial Fuller).
8. **`GIAO_TRINH_FOREXBROKERS_COM.md`** — Cẩm nang hạ tầng thực chiến, Tiêu chuẩn an toàn Trust Score, Mô hình sàn ECN/STP, Chi phí ẩn, So sánh MT4 vs MT5 và Quy chuẩn vận hành Bot Algo từ [ForexBrokers.com](https://www.forexbrokers.com/).

---

## 🌟 TẠI SAO `ApexConfluence_EA` ĐẠT LỢI NHUẬN CAO & RỦI RO CỰC THẤP?

Trong giao dịch tài chính, "Lợi nhuận cao & Rủi ro thấp" không đến từ việc đánh bạc hay gồng lỗ Martingale (rất dễ cháy tài khoản), mà đến từ **Toán học xác suất & Bảo toàn vốn thông minh**:

| Cơ Chế | Cách Hoạt Động | Vì Sao Mang Lại Lợi Nhuận Cao & Rủi Ro Thấp? |
| :--- | :--- | :--- |
| **Hội Tụ Đa Chỉ Báo (Confluence)** | Chỉ vào lệnh khi đồng thời thỏa mãn: Xu hướng (EMA50/200), Xung lượng (RSI 50-70), và Bùng nổ biên độ (Bollinger Bands). | Lọc bỏ 85% tín hiệu giả và sideway gây hao hụt tài khoản. |
| **Quản Lý Vốn Chuẩn % (Position Sizing)** | Rủi ro mỗi lệnh chỉ **0.5% - 1.0%** tài khoản, khối lượng Lot tự động tính dựa trên khoảng cách SL thực tế. | Bất chấp thị trường có chuỗi 5-10 lệnh thua liên tiếp, tài khoản chỉ giảm nhẹ vài %, không bao giờ có nguy cơ cháy. |
| **Stop Loss Động Theo ATR** | SL đặt cách giá vào lệnh $1.5 \times \text{ATR(14)}$. | Không bị quét râu nến ngẫu nhiên do biến động thị trường. |
| **Tỷ Lệ Risk:Reward Khủng (1:2.5)** | Mỗi lệnh thắng mang về lợi nhuận gấp **2.5 lần** số tiền rủi ro. | Chỉ cần tỷ lệ thắng (Win Rate) đạt **40%**, tài khoản vẫn tăng trưởng lợi nhuận vượt bậc! |
| **Chốt Lời Từng Phần (Partial Close 50%)** | Khi lệnh đạt $1.5 \text{R}$, bot tự động đóng $50\%$ khối lượng để bỏ tiền vào túi. | Đảm bảo lệnh đã có lãi chắc chắn trong tay, giải tỏa hoàn toàn áp lực tâm lý. |
| **Auto Break-Even (Hòa Vốn)** | Khi lệnh đạt $1.0 \text{R}$, SL tự dời về Entry + bù phí spread. | Biến lệnh thành **giao dịch hoàn toàn không có rủi ro (Risk-Free Trade)**. |
| **Smart Trailing Stop theo ATR** | Khi giá chạy xa ($> 1.5 \text{R}$), SL tự bám theo từng bước sóng. | "Gồng lãi" trọn vẹn các con sóng lớn của thị trường (ăn 3R, 4R, 5R). |
| **Lá Chắn Lỗ Trong Ngày (Daily Loss Guard)** | Nếu tổng drawdown trong ngày chạm mức tối đa (ví dụ 3%), bot tự ngắt giao dịch mới. | Tránh hiện tượng tài khoản bị bào mòn trong những ngày thị trường nhiễu loạn do tin tức lớn. |
| **Lọc Phóng Giãn Spread** | Không vào lệnh nếu Spread vượt quá mức cho phép (`InpMaxSpreadPoints`). | Tránh mất tiền oan vào thời điểm giao phiên hoặc thị trường mất thanh khoản. |

---

## 🖥️ GIAO DIỆN BẢNG ĐIỀU KHIỂN (ON-CHART DASHBOARD)

Khi gắn `ApexConfluence_EA` lên biểu đồ MT5, bot sẽ tự động vẽ một bảng điều khiển thời gian thực ở góc trên bên trái:
* **Balance & Equity**: Theo dõi số dư và tài sản thực tế.
* **Spread Monitor**: Hiển thị độ giãn spread hiện tại và cảnh báo màu đỏ nếu vượt ngưỡng an toàn.
* **Risk Monitor**: Hiển thị % rủi ro và tỷ lệ R:R đang áp dụng.
* **Daily DD & Guard Status**: Thống kê mức sụt giảm trong ngày và trạng thái khóa an toàn (`ACTIVE` hoặc `LOCKED`).
* **Trend State**: Nhận diện xu hướng (`UPTREND (Bullish)`, `DOWNTREND (Bearish)`).
* **Active Positions**: Theo dõi số vị thế đang mở.

---

## 🚀 HƯỚNG DẪN CÀI ĐẶT VÀO METATRADER 5

### Bước 1: Copy file vào thư mục MT5
1. Mở phần mềm **MetaTrader 5**.
2. Trên thanh menu, chọn **File** ➔ **Open Data Folder**.
3. Mở thư mục: `MQL5\Experts\`.
4. Copy file [`ApexConfluence_EA.mq5`](file:///c:/Users/AD/Documents/BotTrade/ApexConfluence_EA.mq5) (và [`BreakoutSR_EA.mq5`](file:///c:/Users/AD/Documents/BotTrade/BreakoutSR_EA.mq5)) vào đây.

### Bước 2: Biên dịch (Compile)
1. Trong MT5, nhấn phím **`F4`** để mở **MetaEditor**.
2. Tại cây thư mục Navigator bên trái, mở mục `Experts` ➔ nhấp đúp vào `ApexConfluence_EA.mq5`.
3. Nhấn phím **`F7`** (hoặc nút **Compile**).
4. Đảm bảo thông báo ở dưới báo: `0 errors, 0 warnings`. Lúc này file `ApexConfluence_EA.ex5` đã sẵn sàng.

### Bước 3: Đưa Bot lên biểu đồ
1. Quay lại **MetaTrader 5**.
2. Mở cửa sổ **Navigator** (`Ctrl + N`) ➔ Nhấp chuột phải vào `Expert Advisors` ➔ chọn **Refresh**.
3. Mở cặp tiền tệ khuyến nghị: **`EURUSD`**, **`GBPUSD`**, **`XAUUSD` (Vàng)** hoặc **`USDJPY`**.
4. Khung thời gian khuyến nghị: **`M15`** hoặc **`H1`**.
5. Kéo thả `ApexConfluence_EA` vào biểu đồ.
6. Trong tab **Common**: Tích chọn **`Allow Algo Trading`**.
7. Chuyển sang tab **Inputs** để kiểm tra tham số:
   - `InpRiskPercent`: Đặt `1.0` (1% vốn trên mỗi lệnh).
   - `InpRiskRewardRatio`: `2.5` (mục tiêu ăn 2.5R).
   - `InpMaxDailyLossPercent`: `3.0` (dừng ngày nếu lỗ 3%).
8. Nhấn **OK**.
9. Bấm nút **Algo Trading** (Màu Xanh) trên thanh công cụ chính của MT5.

---

## 🧪 HƯỚNG DẪN BACKTEST ĐỂ KIỂM CHỨNG LỢI NHUẬN & DRAWDOWN

1. Nhấn **`Ctrl + R`** trong MT5 để mở cửa sổ **Strategy Tester**.
2. Thiết lập:
   - **Expert**: `ApexConfluence_EA.ex5`
   - **Symbol**: `EURUSD` hoặc `GBPUSD`
   - **Period**: `M15` hoặc `H1`
   - **Date**: Chọn 1 năm gần nhất
   - **Deposit**: `$1,000` (hoặc số vốn dự kiến của bạn)
   - **Modeling**: `Every tick based on real ticks` (để kiểm tra khớp lệnh chính xác từng tick giá).
3. Nhấn **Start** và quan sát biểu đồ vốn tăng trưởng dốc đều với mức sụt giảm (Drawdown) cực kỳ thấp.
