# CẨM NANG VẬN HÀNH EA XAUUSD M15 PRODUCTION PRO (PHIÊN BẢN v3.10)
## EVENT-DRIVEN ACCOUNTING & HIGH-WATER MARK DRAWDOWN ENGINE

> **Mã nguồn Robot:** [`XAUUSD_M15_Production_v3_1.mq5`](file:///c:/Users/AD/Documents/BotTrade/XAUUSD_M15_Production_v3_1.mq5)  
> **File nhị phân đã biên dịch:** [`XAUUSD_M15_Production_v3_1.ex5`](file:///c:/Users/AD/Documents/BotTrade/XAUUSD_M15_Production_v3_1.ex5) *(Trạng thái: 0 Errors, 0 Warnings)*  
> **Nền tảng:** MetaTrader 5 (MT5 x64)  
> **Tài sản khuyến nghị:** **`XAUUSD` (Vàng)**  
> **Khung thời gian:** **M15 (15 Phút)**  
> **Khung giờ giao dịch:** **11:00 - 18:00 GMT** (Tương đương 18:00 - 01:00 VN, bắt trọn thanh khoản phiên Mỹ sôi động nhất)

---

## 1. TỔNG KẾT NÂNG CẤP V3.10: KHẮC PHỤC TRIỆT ĐỂ 8 LỖI KỸ THUẬT

Phiên bản **v3.10** được hoàn thiện dựa trên tiêu chuẩn định lượng của các quỹ tài chính (Prop Firms / Institutional Quant), loại bỏ hoàn toàn các lỗi nghẽn cổ chai và sai lệch kế toán:

### A. Khắc Phục 4 Lỗi Nghiêm Trọng (Critical Bugs)

1. **Loại bỏ hoàn toàn `HistorySelect` trên mỗi Tick bằng Event-Driven Cache (`OnTradeTransaction`):**
   * *Trước đây:* Gọi `HistorySelect()` mỗi tick làm nghẽn CPU trầm trọng khi backtest và gây giật lag trên MT5 live khi tài khoản có hàng ngàn deals lịch sử.
   * *Giải pháp v3.10:* Toàn bộ chỉ số PnL (`g_cachedEARealizedAllTime`, `g_cachedNetBalanceFlowsToday`) được lưu vào bộ nhớ cache. Cache chỉ được đánh dấu làm mới khi có sự kiện thực thi lệnh `OnTradeTransaction(TRADE_TRANSACTION_DEAL_ADD)` hoặc khi bước sang ngày mới (00:00 GMT).

2. **Chuẩn hóa Kế toán Giao dịch Toàn diện (Full Deal Accounting & Snapshot 00:00 GMT):**
   * *Đủ 100% chi phí:* Khi tính PnL của EA, hệ thống tính gộp toàn bộ:
     $$\text{Net PnL} = \text{DEAL\_PROFIT} + \text{DEAL\_SWAP} + \text{DEAL\_COMMISSION} + \text{DEAL\_FEE}$$
     trên mọi deal (`DEAL_ENTRY_IN`, `DEAL_ENTRY_OUT`, `DEAL_ENTRY_INOUT`, `DEAL_ENTRY_OUT_BY`). Phí sàn trừ ngay khi vào lệnh (`DEAL_ENTRY_IN`) được ghi nhận sòng phẳng vào PnL trong ngày.
   * *Khử sai lệch lệnh qua đêm & dòng tiền nạp/rút:* Neo cố định `g_dayStartEquitySnapshot` tại đúng 00:00 GMT. Các biến động nạp/rút tiền (`DEAL_TYPE_BALANCE`, `CREDIT`, `BONUS`) trong ngày được biến `g_cachedNetBalanceFlowsToday` bù trừ tự động, loại bỏ hoàn toàn hiện tượng nạp/rút tiền kích hoạt nhầm cầu dao cắt lỗ ngày.

3. **Tính Max Drawdown theo chuẩn High-Water Mark (HWM - Sụt giảm từ đỉnh vốn thực tế):**
   * Tạo mốc thời gian `g_eaEpochStartTime` (lưu trữ bền vững trong `GlobalVariables` kèm mã số `ACCOUNT_LOGIN`) để không bị tính lẫn lịch sử từ các chu kỳ chạy trước của cùng MagicNumber.
   * Trên mỗi tick, hệ thống liên tục ghi nhận đỉnh vốn cao nhất:
     $$g\_highWaterMarkEquity = \max(g\_highWaterMarkEquity, currentScopeEquity)$$
   * Nếu tài khoản tăng từ $1,000 lên $1,300 (đỉnh HWM mới), giới hạn sụt giảm 15% sẽ bảo vệ tại mức giảm $195 tính từ đỉnh $1,300, bảo toàn tuyệt đối thành quả lợi nhuận đã tích lũy.

4. **Cơ chế One-Shot Reset Token (`InpResetLockdownToken`):**
   * Thay vì dùng biến `bool` dễ bị kẹt trạng thái reset nếu người dùng quên tắt, v3.10 sử dụng mã số nguyên `int InpResetLockdownToken`.
   * Khi muốn mở khóa sau Lockdown, người dùng chỉ cần đổi số này sang số mới (ví dụ `1`, lần sau là `2`). EA kiểm tra với `LAST_RESET_TOKEN`: nếu là số mới chưa từng chạy, EA xóa cờ Lockdown đúng một lần duy nhất rồi lưu lại. Kể cả khi khởi động lại MT5, trạng thái bảo vệ không bao giờ bị xóa nhầm.

---

### B. Khắc Phục 4 Lỗi Trung Bình & Khôi Phục Baseline Tham Số

1. **Đọc ngày Triple Swap động từ `SYMBOL_SWAP_ROLLOVER3DAYS`:**
   * Thay vì mặc định Thứ Tư, EA tự động truy vấn broker để biết ngày sàn thu phí qua đêm x3 (`SYMBOL_SWAP_ROLLOVER3DAYS`).
   * Chặn mở vị thế mới trong `InpRolloverAvoidHours = 2` giờ cuối phiên giao dịch ngày hôm đó (16:00 - 18:00 GMT), triệt tiêu rủi ro bị sàn giãn spread và trừ phí swap 3 ngày vô lý.

2. **Đồng bộ Bộ lọc Tin tức Vĩ mô giữa Strategy Tester và Live/Demo:**
   * Live/Demo: Truy vấn trực tiếp MQL5 Economic Calendar thông qua `CalendarValueHistory()` lọc tin đỏ USD trong khoảng $\pm 30$ phút.
   * Strategy Tester: Bổ sung thuật toán mô phỏng 3 sự kiện vĩ mô lớn nhất của USD trong lịch sử (NFP Thứ Sáu đầu tháng, US CPI ngày 10–15 hàng tháng, và FOMC Thứ Tư tuần thứ 3), giúp kết quả backtest phản ánh chính xác tác động thực tế của tin tức.

3. **Đảo thứ tự kiểm tra Spread lên trước Lịch Tin tức:**
   * Kiểm tra điều kiện chi phí `effectiveCostPerOz > InpMaxEffectiveCostOz` trước khi gọi lịch tin tức. Nếu spread đang giãn đầu nến, EA thoát ngay lập tức, tiết kiệm tài nguyên CPU tối đa.

4. **Tính động số chữ số thập phân của Lot từ `SYMBOL_VOLUME_STEP`:**
   * Sử dụng hàm `GetVolumeDigits(lotStep)` để chuẩn hóa khối lượng vào lệnh chính xác theo từng sàn (hỗ trợ cả bước nhảy 0.1, 0.01 hay 0.001 của tài khoản micro/cent).

5. **Khôi phục Tham số Chiến lược Baseline Gốc:**
   * Toàn bộ tham số được giữ nguyên thiết kế chuẩn: **SL = 1.5 ATR**, **TP = 2.5 ATR**, **BE Trigger = 1.2 ATR**, **Max Candle Spike = 2.0 ATR**, **BE Buffer = 0.30 USD**, loại bỏ hiện tượng curve-fitting trên giấy.

---

### C. Nâng Cấp Giao Diện HUD Trực Quan (On-Chart Dashboard)

Robot được tích hợp sẵn bảng điều khiển HUD hiển thị tức thời trên góc biểu đồ:
* 📊 Vốn thực tế & Đỉnh vốn cao nhất (High-Water Mark).
* 📉 Mức Drawdown hiện tại so với trần HWM (15%).
* 📅 Mức lỗ trong ngày so với trần Daily Loss (3%).
* ⏱️ Giờ GMT chuẩn xác kèm GMT Offset của máy chủ sàn (tự động phát hiện DST mùa hè).
* ⚡ Chi phí thực tế (Spread + Comm quy đổi trên 1 oz Vàng) so với trần $0.35.
* 🚦 Trạng thái bảo vệ: Active, Standby ngoài giờ, Lockdown hoặc Daily Paused.

---

## 2. BẢNG THAM SỐ CẤU HÌNH (INPUT PARAMETERS)

| Nhóm Cấu Hình | Tên Tham Số | Giá Trị Mặc Định | Ý Nghĩa Chuyên Sâu |
| :--- | :--- | :--- | :--- |
| **Quản trị vốn HWM** | `InpReferenceCapital` | `0.0` | Vốn mốc ban đầu (0 = tự động nhận diện Balance lúc nạp bot) |
| | `InpUseDynamicLot` | `false` | Tính Lot tự động theo % Risk (false = dùng fixed 0.01 lot) |
| | `InpFixedLot` | `0.01` | Khối lượng lệnh cố định an toàn cho tài khoản 1,000u |
| | `InpRiskPercentPerTrade` | `1.0%` | Rủi ro mục tiêu cho 1 lệnh (% Vốn snapshot đầu ngày) |
| | `InpMaxRiskCapPercent` | `1.2%` | Trần rủi ro tối đa cho phép của 1 lệnh (chặn lệnh nếu SL quá xa) |
| | `InpMaxDailyLossPercent` | `3.0%` | Cầu dao ngắt mạch lỗ tối đa trong ngày (dừng đến 00:00 GMT) |
| | `InpMaxHWMDrawdownPct` | `15.0%` | Cầu dao ngắt mạch sụt giảm từ Đỉnh vốn cao nhất (HWM) |
| | `InpLockdownScope` | `SCOPE_THIS_EA_ONLY` | Chỉ quản lý và đóng lệnh của EA này (Virtual Scope) |
| | `InpResetLockdownToken` | `0` | Nhập số nguyên mới (> 0) để mở khóa 1 lần duy nhất |
| **Hòa vốn & Trailing** | `InpMaxEffectiveCostOz` | `0.35` | Trần chi phí thực tế (Spread + Comm quy đổi trên 1 oz Vàng) |
| | `InpEstCommPerLotRT` | `7.0` | Chi phí Commission 2 chiều ước tính trên 1.0 Lot chuẩn |
| | `InpCommissionMode` | `COMM_CHARGED_PER_SIDE` | Thu từng chiều (sàn ECN) hay thu trọn gói lúc mở |
| | `InpUseBreakEven` | `true` | Bật tính năng tự động dời Stop Loss về Hòa vốn |
| | `InpBETriggerATR` | `1.2` | Giá chạy được $1.2 \times \text{ATR}$ thì kích hoạt dời BE |
| | `InpBEExtraBufferMoney` | `0.30` | Lãi đệm bảo đảm dương tiền sau khi trừ sạch phí sàn và swap |
| | `InpUseTrailingStop` | `true` | Bật tính năng khóa lời động (Trailing Stop) |
| | `InpTrailStartATR` | `1.5` | Giá chạy được $1.5 \times \text{ATR}$ thì kích hoạt Trailing |
| | `InpTrailDistanceATR` | `1.0` | Khoảng cách neo SL phía sau giá hiện tại ($1.0 \times \text{ATR}$) |
| | `InpTrailStepATR` | `0.25` | Bước nhảy tối thiểu mỗi lần kéo SL lên ($0.25 \times \text{ATR}$) |
| **Kỹ thuật & Tín hiệu** | `InpEMAFastPeriod` | `50` | Đường EMA 50 khung M15 |
| | `InpEMASlowPeriod` | `200` | Đường EMA 200 khung M15 (đường xu hướng dài hạn) |
| | `InpRSIPeriod` | `14` | Chu kỳ RSI 14 |
| | `InpRSIBuyCrossLevel` | `45.0` | RSI cắt lên 45 xác nhận đảo chiều tăng theo trend |
| | `InpRSISellCrossLevel` | `55.0` | RSI cắt xuống 55 xác nhận đảo chiều giảm theo trend |
| | `InpATRPeriod` | `14` | Chu kỳ ATR đo độ biến động |
| | `InpSLMultiplierATR` | `1.5` | Stop Loss ban đầu neo bằng $1.5 \times \text{ATR}$ |
| | `InpTPMultiplierATR` | `2.5` | Take Profit ban đầu neo bằng $2.5 \times \text{ATR}$ |
| | `InpMaxCandleSpikeATR` | `2.0` | Chặn vào lệnh nếu nến tín hiệu giãn nở quá $2.0 \times \text{ATR}$ |
| **Thời gian & Tin tức** | `InpStartHourGMT` | `11` | Giờ bắt đầu nhận tín hiệu (11:00 GMT = 18:00 VN) |
| | `InpEndHourGMT` | `18` | Giờ dừng nhận tín hiệu mới (18:00 GMT = 01:00 VN sáng hôm sau) |
| | `InpWinterGMTOffset` | `2` | Múi giờ mùa đông sàn broker (dùng khi Backtest) |
| | `InpDSTSchedule` | `DST_US` | Chuẩn đổi giờ mùa hè US DST (tự động điều chỉnh) |
| | `InpUseNewsFilter` | `true` | Bật lọc tin tức vĩ mô USD đỏ |
| | `InpNewsPauseBeforeMin` | `30` | Tạm dừng mở lệnh trước giờ ra tin đỏ 30 phút |
| | `InpNewsPauseAfterMin` | `30` | Tạm dừng mở lệnh sau giờ ra tin đỏ 30 phút |
| | `InpCloseBeforeWeekend` | `true` | Tự động thanh lý hết lệnh tối Thứ Sáu chống rủi ro Gap tuần |
| | `InpFridayCloseHourGMT` | `20` | Giờ đóng hết lệnh tối Thứ Sáu (20:00 GMT = 03:00 VN sáng T7) |
| | `InpAvoidTripleSwapDay` | `true` | Tự động chặn mở lệnh mới cuối phiên ngày tính Triple Swap |
| | `InpRolloverAvoidHours` | `2` | Chặn mở lệnh 2 giờ trước khi phiên ngày Triple Swap kết thúc |
| **Định danh & Giao diện**| `InpMagicNumber` | `20261015` | Magic ID duy nhất của EA |
| | `InpShowDashboard` | `true` | Hiển thị HUD Dashboard trực tiếp trên màn hình chart |

---

## 3. QUY TRÌNH NẠP BOT VÀ KIỂM THỬ THỰC CHIẾN TRÊN MT5

1. **Khởi chạy trên tài khoản Demo/Live:**
   * Mở phần mềm MT5 $\rightarrow$ Mở cửa sổ **Navigator** (`Ctrl + N`).
   * Tìm mục **Expert Advisors** $\rightarrow$ Kéo tệp [`XAUUSD_M15_Production_v3_1.ex5`](file:///c:/Users/AD/Documents/BotTrade/XAUUSD_M15_Production_v3_1.ex5) thả vào biểu đồ **`XAUUSD` khung `M15`**.
   * Tích chọn ô **Allow Algo Trading** ở tab Common.
   * Quan sát HUD Dashboard xuất hiện ở góc trên bên trái biểu đồ hiển thị thông số mốc Vốn, Đỉnh HWM, Giờ GMT và trạng thái Hoạt động.

2. **Cách mở khóa khi EA kích hoạt Lockdown (One-Shot Reset):**
   * Nếu EA từng chạm ngưỡng Hard Drawdown và khóa lại, vào phần Inputs của EA:
   * Tìm tham số `InpResetLockdownToken`: Đổi giá trị từ `0` sang `1` (hoặc bất kỳ số nguyên mới nào lớn hơn số trước đó) $\rightarrow$ Bấm **OK**.
   * EA sẽ xóa cờ Lockdown và đặt lại mốc Epoch mới đúng một lần duy nhất.
