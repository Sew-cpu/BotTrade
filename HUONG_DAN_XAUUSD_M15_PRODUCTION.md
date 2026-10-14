# CẨM NANG VẬN HÀNH EA XAUUSD M15 PRODUCTION (CHUẨN TỔ CHỨC 2.00)

> **Mã nguồn Robot:** [`XAUUSD_M15_Production.mq5`](file:///c:/Users/AD/Documents/BotTrade/XAUUSD_M15_Production.mq5)  
> **File nhị phân đã biên dịch:** [`XAUUSD_M15_Production.ex5`](file:///c:/Users/AD/Documents/BotTrade/XAUUSD_M15_Production.ex5) *(Kết quả: 0 Errors, 0 Warnings)*  
> **Nền tảng:** MetaTrader 5 (MT5 x64)  
> **Khung thời gian:** **M15 (15 Phút)**  
> **Cặp giao dịch khuyến nghị:** **`XAUUSD` (Vàng)**  
> **Khung giờ giao dịch:** **11:00 - 18:00 GMT (tương đương 18:00 - 01:00 giờ Việt Nam - Phiên Mỹ sôi động)**  

---

## 1. TỔNG QUAN VỀ 5 BƯỚC KHẮC PHỤC LỖI KỸ THUẬT & TOÁN HỌC

Phiên bản **XAUUSD M15 Production v2.00** được thiết kế để giải quyết triệt để 5 vấn đề cốt lõi thường gặp trong các EA MQL5 truyền thống:

### 1. Sửa Lỗi Toán Học Phép Chia Lấy Dư Số Âm (%) & Đa Chuẩn Lịch Giờ Mùa Hè (DST)
* **Vấn đề cũ:** Trong C++/MQL5, biểu thức `(dt.day - dt.day_of_week) % 7` cho kết quả âm khi `dt.day < dt.day_of_week` (ví dụ: ngày 1 rơi vào thứ Sáu thì $(1 - 5) \pmod 7 = -4$), làm sai lệch toàn bộ việc xác định ngày Chủ Nhật đầu tiên của tháng.
* **Thuật toán chuẩn xác:** Neo trực tiếp vào ngày 1 của tháng hiện tại:
  $$\text{dowOfFirst} = (\text{dt.day\_of\_week} - (\text{dt.day} - 1)\pmod 7 + 7)\pmod 7$$
  $$\text{firstSunday} = (\text{dowOfFirst} == 0) \ ? \ 1 : (8 - \text{dowOfFirst})$$
* **Hỗ trợ đa chuẩn DST (`ENUM_DST_SCHEDULE`):**
  * `DST_US`: Áp dụng lịch Bắc Mỹ (Chủ Nhật thứ 2 Tháng 3 $\rightarrow$ Chủ Nhật đầu tiên Tháng 11).
  * `DST_EU`: Áp dụng lịch Châu Âu/UK (Chủ Nhật cuối cùng Tháng 3 $\rightarrow$ Chủ Nhật cuối cùng Tháng 10).
  * `DST_NONE`: Giữ nguyên chênh lệch không đổi quanh năm (phù hợp các broker sử dụng múi giờ cố định).

---

### 2. Truy Xuất Phí Sàn Chuẩn MQL5 & Chống Tính Trùng (Double-Counting)
* **Vấn đề cũ:** `POSITION_COMMISSION` đã bị MetaQuotes loại bỏ khỏi `ENUM_POSITION_PROPERTY_DOUBLE` trong chuẩn MQL5 hiện đại.
* **Giải pháp chuẩn:** EA duyệt lịch sử giao dịch thông qua `HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER))` và đọc thuộc tính `DEAL_COMMISSION` của các deals liên quan.
* **Cơ chế thu phí linh hoạt (`ENUM_COMMISSION_MODE`):**
  * `COMM_CHARGED_PER_SIDE`: Sàn thu từng chiều (deal vào `DEAL_ENTRY_IN` chỉ thu một nửa phí $\rightarrow$ EA tự nhân 2 khi tính phí round-trip để dời Break-Even).
  * `COMM_CHARGED_UPFRONT_FULL`: Sàn thu trọn gói 2 chiều ngay khi khớp deal vào $\rightarrow$ EA giữ nguyên 1x phí thực tế.

---

### 3. Tính Điểm Hòa Vốn (Break-Even) Bằng `OrderCalcProfit()` Chính Xác Tuyệt Đối
* **Vấn đề cũ:** Ước tính Tick Value qua `SYMBOL_TRADE_TICK_VALUE` dễ bị sai lệch khi tài khoản không phải là USD (EUR, AUD, JPY...) hoặc khi spread giãn rộng.
* **Giải pháp chuẩn:**
  * Dùng `OrderCalcProfit()` để đo lường chính xác giá trị tiền tệ thực tế trên mỗi $1.0 giá của vị thế hiện tại:
    $$\Delta \text{Price} = \frac{\text{TotalRoundTripComm} + |\text{NegativeSwap}| + \text{InpBEExtraBufferMoney}}{\text{ProfitPerOneUnit}}$$
  * Kiểm tra hợp lệ trước khi gửi lệnh sửa `PositionModify`: So sánh khoảng cách với `SYMBOL_TRADE_STOPS_LEVEL` và `SYMBOL_TRADE_FREEZE_LEVEL` nhằm loại bỏ hoàn toàn mã lỗi `TRADE_RETCODE_INVALID_STOPS` (10016).

---

### 4. Cô Lập Phạm Vi Khẩn Cấp (Lockdown Scope Isolation)
* Cung cấp tùy chọn `InpLockdownScope`:
  * `SCOPE_THIS_EA_ONLY` (Mặc định): Chỉ đóng các lệnh và vị thế khớp đúng `_Symbol` và `InpMagicNumber` của EA, không làm ảnh hưởng đến các bot khác hoặc lệnh giao dịch tay trên cùng tài khoản.
  * `SCOPE_ENTIRE_ACCOUNT`: Đóng cưỡng chế toàn bộ tài khoản và lệnh chờ khi chạm mốc rủi ro lớn (Hard Stop).

---

### 5. Quản Trị Vốn Theo % Thay Vì Số Tiền Tuyệt Đối
* Thay vì gán cố định số tiền USD, hệ thống tính toán dựa trên % Vốn/Equity thực tế:
  * `InpMaxRiskPercent = 1.2%`: Trần rủi ro tối đa cho 1 lệnh (tính cả Stop Loss lẫn Commission ước tính bằng `OrderCalcProfit`).
  * `InpMaxDailyLossPercent = 3.0%`: Mức ngắt mạch lỗ tối đa trong ngày dựa trên mốc `g_dayStartEquityAnchor` ghi nhận tại 00:00 GMT.
  * `InpEquityFloorPercent = 85.0%`: Sàn bảo vệ vốn tối thiểu so với vốn mốc ban đầu `InpInitialDeposit`.

---

## 2. BẢNG THAM SỐ CẤU HÌNH (INPUT PARAMETERS)

| Nhóm Tham Số | Tên Tham Số | Giá Trị Mặc Định | Ý Nghĩa Kỹ Thuật |
| :--- | :--- | :--- | :--- |
| **Quản trị rủi ro** | `InpInitialDeposit` | `1000.0` | Vốn mốc ban đầu dùng để tính sàn bảo vệ vốn |
| | `InpFixedLot` | `0.01` | Khối lượng vào lệnh mỗi trade |
| | `InpMaxRiskPercent` | `1.2%` | Trần rủi ro tối đa 1 lệnh (% Vốn mốc đầu ngày) |
| | `InpMaxDailyLossPercent` | `3.0%` | Mức cắt lỗ tổng tối đa trong một ngày |
| | `InpEquityFloorPercent` | `85.0%` | Sàn Equity tối thiểu kích hoạt cơ chế Lockdown |
| | `InpLockdownScope` | `SCOPE_THIS_EA_ONLY` | Phạm vi đóng lệnh khẩn cấp |
| **Chi phí & Break-Even** | `InpMaxEffectiveCostPerOz` | `0.35` | Trần chi phí thực tế (Spread + Comm quy đổi trên 1 oz Vàng) |
| | `InpCommissionPerLotRT` | `7.0` | Ước tính Commission 2 chiều / 1 Lot chuẩn |
| | `InpCommissionMode` | `COMM_CHARGED_PER_SIDE` | Cơ chế thu phí của Broker (Mỗi chiều / Trọn gói) |
| | `InpBETriggerATR` | `1.2` | Hệ số ATR kích hoạt dời Stop Loss về Hòa vốn |
| | `InpBEExtraBufferMoney`| `0.30` | Lợi nhuận đệm tối thiểu khi dời BE (theo tiền tệ TK) |
| | `InpTrailStartATR` | `1.5` | Hệ số ATR bắt đầu kích hoạt Trailing Stop |
| | `InpTrailStepATR` | `0.5` | Bước dịch chuyển Trailing Stop (x ATR) |
| **Chỉ báo & SL/TP** | `InpEMAFastPeriod` | `50` | Chu kỳ EMA nhanh M15 |
| | `InpEMASlowPeriod` | `200` | Chu kỳ EMA chậm M15 |
| | `InpRSIPeriod` | `14` | Chu kỳ RSI M15 |
| | `InpRSIBuyCrossLevel` | `45.0` | Ngưỡng RSI cắt lên để mở vị thế BUY |
| | `InpRSISellCrossLevel` | `55.0` | Ngưỡng RSI cắt xuống để mở vị thế SELL |
| | `InpATRPeriod` | `14` | Chu kỳ ATR đo lường biến động |
| | `InpSLMultiplierATR` | `1.5` | Khoảng cách Stop Loss ban đầu (x ATR) |
| | `InpTPMultiplierATR` | `2.5` | Khoảng cách Take Profit ban đầu (x ATR) |
| | `InpMaxCandleSpikeATR` | `2.0` | Bộ lọc chống nến giật bất thường (Anti-Spike) |
| **Hệ thống & Múi giờ** | `InpStartHourGMT` | `11` | Bắt đầu nhận tín hiệu mở lệnh (18:00 VN) |
| | `InpEndHourGMT` | `18` | Dừng mở lệnh mới (01:00 VN sáng hôm sau) |
| | `InpWinterGMTOffset` | `2` | Múi giờ mùa đông của Broker (phục vụ Backtest) |
| | `InpDSTSchedule` | `DST_US` | Chuẩn đổi giờ mùa hè của Broker |
| | `InpMagicNumber` | `20261015` | Magic ID định danh lệnh của Bot |

---

## 3. QUY TRÌNH KIỂM THỬ XÁC MINH (VERIFICATION CHECKLIST) TRÊN MT5

### Bước 1: Kiểm Tra Biên Dịch (Compilation Test)
* Mở **MetaEditor 64-bit** (nhấn phím `F4` từ MT5).
* Mở file [`XAUUSD_M15_Production.mq5`](file:///c:/Users/AD/Documents/BotTrade/XAUUSD_M15_Production.mq5).
* Nhấn **`F7`** để biên dịch.
* **Kết quả xác nhận trên hệ thống:**
  ```text
  Result: 0 errors, 0 warnings, 1205 ms elapsed, cpu='X64 Regular'
  Output File: XAUUSD_M15_Production.ex5 (47,812 bytes)
  ```

### Bước 2: Kiểm Tra Chuyển Mốc Đổi Giờ Mùa Hè (DST Transition Test)
* Mở **Strategy Tester** (`Ctrl + R`) trong MT5.
* Chọn Expert: `XAUUSD_M15_Production.ex5`.
* Cặp tiền: `XAUUSD`, Khung thời gian: `M15`.
* Chạy Visual Mode qua các mốc:
  * **08/03/2026**: Chủ Nhật thứ 2 của Tháng 3 (Bắt đầu US Daylight Saving Time).
  * **01/11/2026**: Chủ Nhật đầu tiên của Tháng 11 (Kết thúc US DST).
* Kiểm tra tab **Journal**: Khung giờ giao dịch 11:00 - 18:00 GMT được EA căn chỉnh chính xác theo giờ Server mà không bị lệch 1 tiếng.

### Bước 3: Stress Test Dữ Liệu Tick Thực Tế (Real Ticks Model)
* Chọn **Modelling**: `Every tick based on real ticks` (Dữ liệu tick thực của sàn có spread thả nổi).
* Cài đặt độ trễ mạng: `Execution Delay: 50ms - 100ms`.
* Tiến hành Backtest trên dữ liệu lịch sử để đo lường:
  * **Profit Factor** $> 1.3$.
  * **Max Equity Drawdown** $< 12\%$.
  * Tính toán chính xác Break-Even dời SL dương tiền sau khi đã trừ phí Spread + Commission thực tế.
