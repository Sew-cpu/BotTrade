# HƯỚNG DẪN CHI TIẾT ROBOT SCALPING FABIO VALENTINI
### (Hệ Thống Breakout Order Flow, CVD & Pyramiding Scaling Của Nhà Vô Địch Robbins World Cup)

---

## 🏆 1. TỔNG QUAN PHƯƠNG PHÁP FABIO VALENTINI
Hệ thống được chuyển hóa trực tiếp từ chiến lược của **Fabio Valentini** – Quán quân giải vô địch giao dịch thế giới **Robbins World Cup**, được phân tích chi tiết trong video của **Nhật Hoài Trader**.

Bản chất cốt lõi của phương pháp gồm 3 trụ cột:
1. **Breakout theo Order Flow & CVD (Cumulative Volume Delta):** Không chỉ nhìn nến giá thuần túy mà đo lường dòng lệnh chủ động (Aggressor Buying vs Aggressor Selling) và khối lượng giao dịch để lọc 100% bẫy phá vỡ giả (Fakeout).
2. **Pyramiding (Nhồi vị thế thuận xu hướng 50% - 25% - 25%):** Không bao giờ vào 100% khối lượng ngay từ đầu. Chia nhỏ thành 3 tầng:
   * **Lệnh 1 (Base Position):** Vào 50% ngân sách rủi ro khi bứt phá biên.
   * **Lệnh 2 (Scale-in 1):** Giá tạo nhịp đẩy mới $\ge 1.0 \text{ ATR} \rightarrow$ Vào thêm 25%, đồng thời **dời SL lệnh 1 về Hòa Vốn (Break-Even)**.
   * **Lệnh 3 (Scale-in 2):** Giá tiếp tục tạo sóng bùng nổ $\rightarrow$ Vào nốt 25% còn lại và **dời SL của tất cả các lệnh** bám sát theo đáy/đỉnh mới hoặc đường EMA 20.
3. **Quản lý rủi ro động (Dynamic Risk Budgeting):**
   * Khởi đầu ngày với mức rủi ro rất nhỏ (**0.5%** vốn).
   * Khi chuỗi lệnh trong ngày có lãi: **Trích 50% lợi nhuận đã chốt** cộng dồn vào ngân sách rủi ro của setup tiếp theo để tạo hiệu ứng lãi kép lũy tiến (Profit Compounding) bùng nổ tài khoản trong những ngày thị trường có xu hướng mạnh.

---

## ⚙️ 2. THÔNG SỐ CẤU HÌNH TRÊN MT5

| Nhóm Thông Số | Tên Input | Mặc Định | Ý Nghĩa Kỹ Thuật |
| :--- | :--- | :---: | :--- |
| **Quản trị Rủi ro Động** | `InpBaseRiskPercent` | `0.5%` | Rủi ro cơ sở cho mỗi chu kỳ lệnh (% Equity) |
| | `InpUseProfitCompounding` | `true` | Bật trích lãi trong ngày để mở rộng ngân sách rủi ro |
| | `InpProfitReinvestPct` | `50.0%` | Tỷ lệ lợi nhuận ngày tái đầu tư vào lệnh kế tiếp |
| | `InpMaxDailyRiskBudgetPct`| `3.0%` | Trần rủi ro tối đa cho phép trong ngày |
| | `InpMaxDailyLossPercent` | `2.0%` | Ngắt mạch dừng bot nếu tổng lỗ ngày chạm 2% vốn |
| **Vùng Tích Lũy (Range)** | `InpRangeLookbackBars` | `25` | Quét hộp tích lũy trong 25 nến M15 gần nhất |
| | `InpMinRangeWidthATR` | `0.8` | Chặn hộp quá hẹp (< 0.8x ATR) |
| | `InpMaxRangeWidthATR` | `2.8` | Chặn hộp quá rộng (> 2.8x ATR) |
| | `InpHTFTrendEMAPeriod` | `200` | EMA 200 trên khung H1 (Lọc chỉ đánh theo xu hướng lớn) |
| **Order Flow & CVD** | `InpCVDLookbackTicks` | `1000` | Phân tích 1,000 tick dòng lệnh gần nhất |
| | `InpCVDThresholdRatio` | `1.5` | Xung lực Delta tối thiểu xác nhận bứt phá |
| **Kích Hoạt Lệnh & Nhồi** | `InpEntryStyle` | `ENTRY_BREAKOUT_DIRECT` | `ENTRY_BREAKOUT_DIRECT` (Xung lực) hoặc `ENTRY_PULLBACK_RETEST` (Bảo thủ - Nhật Hoài) |
| | `InpEnablePyramiding` | `true` | Bật tự động nhồi vị thế 3 tầng (50% - 25% - 25%) |
| | `InpPyramidStepATR` | `1.0` | Khoảng cách nhịp đẩy để kích hoạt lệnh nhồi (x ATR) |
| **Thoát Lệnh (Exit)** | `InpExitEMAPeriod` | `20` | Đường EMA 20 theo dõi xu hướng |
| | `InpExitOnEMACross` | `true` | Đóng toàn bộ lệnh khi nến M15 đóng ngược qua EMA 20 |
| | `InpTrailingATR` | `1.2` | Khoảng cách Trailing Stop bám sát (1.2x ATR) |
| | `InpMinProfitBEATR` | `1.0` | Dời BE khi giá chạy được 1.0x ATR |
| **Thời Gian Giao Dịch** | `InpStartHourGMT` | `7` | 14:00 VN (Bắt đầu Phiên London) |
| | `InpEndHourGMT` | `19` | 02:00 VN (Kết thúc Phiên New York) |

---

## 📈 3. BẢNG HUD DASHBOARD TRỰC QUAN GÓC TRÁI BIỂU ĐỒ
Trên biểu đồ MT5, bot hiển thị bảng HUD Obsidian-Navy sang trọng với 10 dòng trạng thái:
1. **💰 Vốn & Ngân Sách Risk Động:** Hiển thị vốn thực và số tiền rủi ro được phép đánh cho setup tiếp theo.
2. **📈 Lãi Đã Chốt Ngày:** Lợi nhuận ròng hôm nay và tỷ lệ % lãi được dùng để tái đầu tư.
3. **📦 Vùng Tích Lũy (Range):** Tọa độ giá Hộp tích lũy `[Range Low - Range High]` và biên độ hộp.
4. **🌊 CVD Order Flow:** Giá trị Delta mua/bán tức thời (Xanh lá khi phe Mua áp đảo, Đỏ khi phe Bán chiếm lĩnh).
5. **🧭 Thiên Kiến Lớn (H1 EMA 200):** Chỉ báo hướng đánh an toàn (`BULLISH 🟢` hoặc `BEARISH 🔴`).
6. **🪜 Tầng Pyramiding:** Báo cáo thời gian thực lệnh đang ở tầng nào (`LỆNH 1 - Base 50%`, `LỆNH 2 - Nhồi 25% đã BE`, hay `LỆNH 3 - Full Attack`).
7. **🛡️ Đường Thoát Lệnh (EMA 20):** Mốc giá EMA 20 hiện tại để chuẩn bị chốt lời khi nến đảo chiều.
8. **🚦 Trạng Thái Hệ Thống:** Báo cáo bot sẵn sàng hay đang tạm dừng bảo vệ vốn.
9. **⏱️ Phiên Trade:** Giờ GMT và giờ Việt Nam đang hoạt động.
10. **🎯 Chế Độ Vào Lệnh:** Đang chạy Direct Breakout hay Pullback Retest.

---

## 🛠️ 4. HƯỚNG DẪN CÀI ĐẶT TRÊN METATRADER 5 (MT5)

1. Mở MT5, chọn cặp **XAUUSD (Vàng)** hoặc **US100 / NAS100 (Nasdaq)** trên khung thời gian **M15**.
2. Mở cửa sổ **Navigator (Ctrl + N)** $\rightarrow$ Mở mục **Expert Advisors** (hoặc thư mục **Free Robots** / **Advisors**).
3. Nhấp đúp hoặc kéo thả robot **`FabioValentini_OrderFlow_EA`** vào biểu đồ.
4. Tại tab **Common**, tích chọn:
   * ✅ **Allow Algo Trading** (Cho phép giao dịch tự động).
5. Bấm nút **Algo Trading** trên thanh công cụ phía trên của MT5 (biểu tượng chuyển sang màu xanh lá).
6. Bảng HUD Dashboard sẽ lập tức xuất hiện ở góc trái biểu đồ và tự động nhận diện Range, tính toán CVD và sẵn sàng giao dịch!
