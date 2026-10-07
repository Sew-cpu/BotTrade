# TỔNG HỢP KIẾN THỨC FOREX NÂNG CAO (TOÀN BỘ 16 BÀI TỪ SCRIBD)

> **Tài liệu nguồn:** *Tài liệu Forex nâng cao (Đọc thêm).pdf* (81 trang - Tác giả: Dung Phạm Thị Phương)  
> **Tổng hợp & Hệ thống hóa:** Phân tích kỹ thuật chuyên sâu, Quản lý rủi ro và Ứng dụng thuật toán giao dịch Forex.

---

## MỤC LỤC CHI TIẾT
1. [Unit 15: 5 Bước Đặt Stop Loss Dễ Dàng & Chuẩn Chỉnh](#unit-15)
2. [Unit 16: Sử Dụng ATR (Average True Range) Đặt Stop Loss](#unit-16)
3. [Unit 17: Bollinger Bands & Chiến Thuật Giao Dịch Đi Kèm](#unit-17)
4. [Unit 18: Phân Loại Chỉ Báo Đi Trước (Leading) & Đi Sau (Lagging)](#unit-18)
5. [Unit 19: RSI & Chiến Thuật Giao Dịch Đa Tầng](#unit-19)
6. [Unit 20: Chỉ Báo MACD & Chiến Thuật Phân Kỳ Chuyên Sâu](#unit-20)
7. [Unit 21: Lý Thuyết Sóng Elliott (Elliott Wave Theory)](#unit-21)
8. [Unit 22: StochRSI & Chiến Thuật Bắt Nhịp Thị Trường Siêu Nhạy](#unit-22)
9. [Unit 23: Lý Thuyết Dow - Nền Tảng Của Toàn Bộ Phân Tích Kỹ Thuật](#unit-23)
10. [Unit 24: Giao Dịch Với Chỉ Báo Parabolic SAR](#unit-24)
11. [Unit 25: Giao Dịch Toàn Diện Với Các Đường Trung Bình Động (MA)](#unit-25)
12. [Unit 26: Biểu Đồ Nến Heikin Ashi - Bộ Lọc Nhiễu Xu Hướng](#unit-26)
13. [Unit 27: Hệ Thống Chỉ Báo Mây Ichimoku Kinko Hyo](#unit-27)
14. [Unit 28: Fibonacci Thoái Lui (Retracement) & Mở Rộng (Extension)](#unit-28)
15. [Unit 29: Pivot Point - Điểm Xoay Đỉnh Đáy](#unit-29)
16. [Unit 30: Chỉ Báo Hàng Hóa CCI (Commodity Channel Index)](#unit-30)

---

<a name="unit-15"></a>
## Unit 15: 5 Bước Đặt Stop Loss Dễ Dàng & Chuẩn Chỉnh

Một giao dịch chuyên nghiệp không bắt đầu từ việc kỳ vọng kiếm bao nhiêu tiền, mà bắt đầu từ việc **bảo vệ tài khoản như thế nào**:

* **Bước 1. Xác định điểm vào lệnh (Entry):**
  * Không bao giờ vào lệnh ngẫu nhiên. Cần sự hội tụ (confluence) của ít nhất 2–3 yếu tố kỹ thuật.
  * Ví dụ: Giá phản ứng tại vùng Hỗ trợ + Nằm trên đường xu hướng MA200 + RSI thoát khỏi vùng quá bán.
* **Bước 2. Xác định điểm Take Profit (TP) và Stop Loss (SL):**
  * Stop Loss: Đặt tại mức giá mà nếu thị trường chạm tới đó, kịch bản phân tích bị chứng minh là **sai hoàn toàn** (dưới đáy hỗ trợ cũ, dưới ngưỡng ATR).
  * Take Profit: Đặt tại các cản đối diện tiếp theo (kháng cự cũ, đỉnh cũ) nơi giá có khả năng cao sẽ phản ứng dừng lại.
* **Bước 3. Kiểm tra tỷ lệ R:R (Risk:Reward):**
  * Tỷ lệ tối thiểu bắt buộc là **1:1.5** hoặc **1:2** (mục tiêu lợi nhuận gấp đôi rủi ro).
  * **Cảnh báo sai lầm:** Tuyệt đối không chấp nhận các lệnh R:R nghịch đảo (như 2:1 — chấp nhận lỗ 2 phần để ăn 1 phần). Điều này dẫn tới việc chỉ cần 1 lệnh lỗ sẽ xóa sạch thành quả của nhiều lệnh thắng.
* **Bước 4. Tính toán số Lot theo % rủi ro tài khoản (Position Sizing):**
  * Mỗi cặp tiền tệ có độ biến động và giá trị pip/tick khác nhau (ví dụ: EURUSD khác XAUUSD và khác GBPJPY).
  * Công thức tính khối lượng chuẩn:  
    $$\text{Lot Size} = \frac{\text{Số tiền rủi ro chấp nhận mất (Equity} \times \text{Risk\%)}}{\text{Khoảng cách Stop Loss (points)} \times \text{Giá trị mỗi point của 1 Lot}}$$
* **Bước 5. Kỷ luật vào lệnh và quản lý tâm lý:**
  * Khi setup đã thỏa mãn và lệnh đã mở, giữ vững kỷ luật, tin tưởng vào hệ thống đã định hình. Không dời Stop Loss ra xa khi thị trường đi ngược kỳ vọng.

---

<a name="unit-16"></a>
## Unit 16: Sử Dụng ATR (Average True Range) Đặt Stop Loss

* **Khái niệm:** Do J. Welles Wilder sáng tạo năm 1978. ATR không chỉ ra hướng đi của giá (Trend) mà đo lường **độ biến động thực tế (Volatility)** của thị trường.
* **Công thức True Range (TR):**
  $$TR = \max(\text{High} - \text{Low},\; |\text{High} - \text{Close}_{\text{prev}}|,\; |\text{Low} - \text{Close}_{\text{prev}}|)$$
  ATR chu kỳ 14 là trung bình động 14 phiên của giá trị TR.
* **Ứng dụng thực chiến để đặt Stop Loss:**
  * Khắc phục nhược điểm của SL cố định (Fixed pips): Khi thị trường biến động giật mạnh (tin tức), SL cố định rất dễ bị quét oan. Khi thị trường êm dịu, SL cố định lại quá xa gây lãng phí tỷ lệ R:R.
  * Công thức SL theo ATR:
    * Lệnh BUY: $\text{Stop Loss} = \text{Entry} - (\text{ATR} \times \text{Multiplier})$ (thường dùng Multiplier từ $1.5$ đến $2.0$).
    * Lệnh SELL: $\text{Stop Loss} = \text{Entry} + (\text{ATR} \times \text{Multiplier})$.

---

<a name="unit-17"></a>
## Unit 17: Bollinger Bands & Chiến Thuật Giao Dịch Đi Kèm

* **Cấu tạo (John Bollinger):**
  * **Middle Band:** Đường trung bình động đơn giản SMA (mặc định chu kỳ 20).
  * **Upper Band:** $\text{SMA20} + (2 \times \text{Standard Deviation})$.
  * **Lower Band:** $\text{SMA20} - (2 \times \text{Standard Deviation})$.
* **Các hiện tượng cốt lõi:**
  1. **Bollinger Band Squeeze (Thắt nút cổ chai):** Hai dải trên và dưới co hẹp lại tối đa. Báo hiệu thị trường đang tích lũy nén biên độ và chuẩn bị bùng nổ mạnh mẽ (Breakout) sang một xu hướng mới.
  2. **Vùng quá mua / quá bán:** Nến vượt hẳn ra ngoài dải Upper/Lower Band thể hiện trạng thái cực đoan ngắn hạn.
* **Chiến thuật kết hợp:**
  * Không giao dịch mù quáng khi giá chạm Band.
  * Kết hợp Band với RSI quá mua/quá bán và phản ứng tại vùng Hỗ trợ / Kháng cự cứng để tìm điểm đảo chiều hoặc điểm bắt sóng sau giai đoạn Squeeze.

---

<a name="unit-18"></a>
## Unit 18: Phân Loại Chỉ Báo Đi Trước (Leading) & Đi Sau (Lagging)

* **Chỉ báo đi trước (Leading Indicators):**
  * *Đại diện:* RSI, Stochastic, StochRSI, CCI.
  * *Ưu điểm:* Phát hiện sớm các dấu hiệu đảo chiều, cung cấp điểm vào lệnh sớm ở mức giá tốt.
  * *Nhược điểm:* Phát ra nhiều tín hiệu giả (nhiễu/whipsaw), đặc biệt nguy hiểm trong các thị trường có xu hướng mạnh mẽ (giá liên tục tăng dù RSI đã quá mua từ lâu).
* **Chỉ báo đi sau (Lagging Indicators):**
  * *Đại diện:* Moving Average (SMA, EMA), MACD, Bollinger Bands Middle Line.
  * *Ưu điểm:* Độ tin cậy cao, đi theo xu hướng (Trend Following), giúp trader đi cùng dòng chảy chính của thị trường.
  * *Nhược điểm:* Tín hiệu trễ, bỏ lỡ đoạn đầu của con sóng.
* **Chỉ báo trùng hợp & hỗn hợp (Coincident):**
  * Hệ thống Ichimoku Cloud tích hợp cả đường đi sau (Chikou Span, Kijun), hiện tại (Tenkan) và dự phóng tương lai (Mây Kumo đi trước 26 phiên).
* **Quy tắc phối hợp vàng:** Dùng chỉ báo đi sau (Lagging) để xác định xu hướng chủ đạo (Trend Filter), và dùng chỉ báo đi trước (Leading) để căn thời điểm nổ súng (Timing Trigger).

---

<a name="unit-19"></a>
## Unit 19: RSI & Chiến Thuật Giao Dịch Đa Tầng

* **Khái niệm (J. Welles Wilder):** Đo lường sức mạnh tương đối giữa các phiên tăng và giảm trên thang điểm từ 0 đến 100 (chu kỳ chuẩn: 14).
* **Vùng quá mua (> 70) & Quá bán (< 30):** Có thể mở rộng lên 80/20 trong các thị trường có xu hướng dốc.
* **Đường trung tâm (RSI 50):**
  * $\text{RSI} > 50$: Phe mua đang kiểm soát đà tăng.
  * $\text{RSI} < 50$: Phe bán đang kiểm soát đà giảm.
  * Kết hợp MA50 dốc lên và RSI giữ vững trên 50 là xác nhận xu hướng tăng lành mạnh.
* **Chiến thuật Phân kỳ RSI (Divergence):**
  * **Phân kỳ thường giảm (Regular Bearish Divergence):** Giá tạo Đỉnh cao hơn (Higher High), nhưng RSI lại tạo Đỉnh thấp hơn (Lower High) $\rightarrow$ Lực mua kiệt sức, cảnh báo đảo chiều giảm.
  * **Phân kỳ thường tăng (Regular Bullish Divergence):** Giá tạo Đáy thấp hơn (Lower Low), nhưng RSI lại tạo Đáy cao hơn (Higher Low) $\rightarrow$ Lực bán suy yếu, cảnh báo đảo chiều tăng.

---

<a name="unit-20"></a>
## Unit 20: Chỉ Báo MACD & Chiến Thuật Phân Kỳ Chuyên Sâu

* **Cấu tạo (Gerald Appel):**
  * **Đường MACD:** $\text{EMA12} - \text{EMA26}$.
  * **Đường Signal (Tín hiệu):** $\text{EMA9 của đường MACD}$.
  * **MACD Histogram:** $\text{MACD} - \text{Signal}$.
* **Cách diễn giải:**
  * Đường MACD nằm trên mức 0: Xu hướng thị trường trong ngắn hạn đang tăng mạnh hơn trung hạn.
  * Giao cắt tín hiệu: Đường MACD cắt lên trên Signal $\rightarrow$ Tín hiệu Mua; Cắt xuống dưới Signal $\rightarrow$ Tín hiệu Bán.
* **Phân kỳ MACD:**
  * So sánh đỉnh/đáy giá với đỉnh/đáy của Histogram hoặc đường MACD. Khi giá phá đỉnh mới nhưng Histogram co lại thấp hơn, đây là tín hiệu chốt lời hoặc mở vị thế đảo chiều cực kỳ chuẩn xác.

---

<a name="unit-21"></a>
## Unit 21: Lý Thuyết Sóng Elliott (Elliott Wave Theory)

* **Bản chất:** Mô tả chu kỳ tâm lý đám đông lặp đi lặp lại trên thị trường tài chính gồm cấu trúc 8 sóng:
  * **5 sóng đẩy (Impulse Waves):** 1, 2, 3, 4, 5 (đi cùng xu hướng chính).
  * **3 sóng điều chỉnh (Corrective Waves):** A, B, C (đi ngược xu hướng chính).
* **3 Quy tắc vàng bắt buộc của sóng đẩy:**
  1. Sóng 2 không bao giờ hồi lui vượt quá điểm bắt đầu của Sóng 1.
  2. Sóng 3 không bao giờ là sóng ngắn nhất trong 3 sóng đẩy (1, 3, 5) — thường là con sóng dài và mạnh nhất.
  3. Sóng 4 không bao giờ đi vào vùng lãnh thổ giá của Sóng 1.
* **Ứng dụng:** Sử dụng đa khung thời gian để biết thị trường đang ở giai đoạn nào của con sóng lớn, tránh mua đuổi ở đỉnh Sóng 5 hoặc bán tháo ở đáy Sóng C.

---

<a name="unit-22"></a>
## Unit 22: StochRSI & Chiến Thuật Bắt Nhịp Thị Trường Siêu Nhạy

* **Khái niệm:** Do Tushar Chande và Stanley Kroll phát triển năm 1994. StochRSI là dao động ngẫu nhiên áp dụng trên chính giá trị của RSI:
  $$\text{StochRSI} = \frac{\text{RSI} - \text{RSI}_{\min}}{\text{RSI}_{\max} - \text{RSI}_{\min}}$$
* **Đặc tính:**
  * Dao động trong khoảng 0 đến 1 (hoặc 0 đến 100).
  * Phản ứng cực nhanh với biến động ngắn hạn.
  * Vùng quá bán: $< 0.20$ (hoặc 20). Vùng quá mua: $> 0.80$ (hoặc 80).
* **Lưu ý thực chiến:** Do quá nhạy, StochRSI có thể nằm lì ở vùng quá mua/quá bán khi trend mạnh. Luôn phải kết hợp xác nhận bằng Trendline, Hỗ trợ/Kháng cự hoặc EMA.

---

<a name="unit-23"></a>
## Unit 23: Lý Thuyết Dow - Nền Tảng Của Toàn Bộ Phân Tích Kỹ Thuật

Charles Dow để lại 6 nguyên lý cốt tử định hình tư duy của mọi trader thành công:
1. **Giá phản ánh tất cả (Discounts everything):** Mọi tin tức kinh tế, chính trị, tâm lý đều đã được phản ánh ngay lập tức vào giá.
2. **Ba xu hướng của thị trường:**
   * *Xu hướng cấp 1 (Chính):* Kéo dài trên 1 năm.
   * *Xu hướng cấp 2 (Thứ cấp - Điều chỉnh):* Kéo dài 3 tuần đến 3 tháng.
   * *Xu hướng cấp 3 (Ngắn hạn/Nhiễu):* Dưới 3 tuần.
3. **Ba giai đoạn của một thị trường giá lên:**
   * *Giai đoạn Tích lũy (Accumulation):* Dòng tiền thông minh (Smart Money) âm thầm thu gom khi đám đông còn bi quan.
   * *Giai đoạn Tham gia của công chúng (Public Participation):* Giá bùng nổ, tin tức tốt tràn ngập, đám đông nhảy vào mua.
   * *Giai đoạn Phân phối (Distribution):* Tay to âm thầm chốt lời cho đám đông hưng phấn.
4. **Các chỉ số/thị trường phải xác nhận lẫn nhau.**
5. **Khối lượng giao dịch (Volume) phải đồng thuận với xu hướng:** Giá tăng trong uptrend thì volume phải tăng; khi điều chỉnh giảm thì volume phải giảm.
6. **Xu hướng tồn tại cho đến khi có tín hiệu đảo chiều rõ ràng:** Cấu trúc đỉnh sau cao hơn đỉnh trước (Higher High), đáy sau cao hơn đáy trước (Higher Low) bị bẻ gãy khi xuất hiện Lower Low.

---

<a name="unit-24"></a>
## Unit 24: Giao Dịch Với Chỉ Báo Parabolic SAR

* **Khái niệm (J. Welles Wilder):** SAR = Stop and Reverse (Dừng và đảo chiều).
* **Cơ chế:** Các dấu chấm parabol nằm phía trên hoặc phía dưới nến.
  * Dấu chấm dưới giá $\rightarrow$ Xu hướng Tăng.
  * Dấu chấm trên giá $\rightarrow$ Xu hướng Giảm.
  * Hệ số gia tốc $AF$ bắt đầu từ $0.02$ và tăng dần theo từng đỉnh/đáy mới đến tối đa $0.20$.
* **Ứng dụng tuyệt vời nhất:** Làm công cụ **Trailing Stop động**. Thay vì kéo SL thủ công, trader có thể đặt Stop Loss tại dấu chấm SAR của cây nến vừa đóng cửa.

---

<a name="unit-25"></a>
## Unit 25: Giao Dịch Toàn Diện Với Các Đường Trung Bình Động (MA)

* **Phân loại:**
  * **SMA (Simple Moving Average):** Trung bình số học giản đơn, trọng số đều nhau.
  * **EMA (Exponential Moving Average):** Trung bình hàm mũ, ưu tiên trọng số cho các phiên gần nhất nên phản ứng nhanh và bám sát đường giá hơn.
* **Các chu kỳ kinh điển:**
  * Ngắn hạn: MA9, MA20.
  * Trung hạn: MA50.
  * Dài hạn: MA100, MA200.
* **Tín hiệu giao dịch cốt lõi:**
  * **Golden Cross:** Đường MA ngắn (ví dụ EMA50) cắt lên trên MA dài (EMA200) $\rightarrow$ Khẳng định Uptrend dài hạn.
  * **Death Cross:** Đường MA ngắn cắt xuống dưới MA dài $\rightarrow$ Báo hiệu Downtrend dài hạn.
  * **Vai trò cản động (Dynamic S/R):** Trong một con sóng tăng mạnh, giá thường có xu hướng hồi về chạm EMA20 hoặc EMA50 rồi tiếp tục bật tăng.

---

<a name="unit-26"></a>
## Unit 26: Biểu Đồ Nến Heikin Ashi - Bộ Lọc Nhiễu Xu Hướng

* **Bản chất:** Nến Heikin Ashi ("bước chân trung bình" trong tiếng Nhật) tính toán giá nến dựa trên trung bình nến trước để làm phẳng độ nhiễu:
  * $\text{Close}_{HA} = (\text{Open} + \text{High} + \text{Low} + \text{Close}) / 4$
  * $\text{Open}_{HA} = (\text{Open}_{\text{prev}} + \text{Close}_{\text{prev}}) / 2$
  * $\text{High}_{HA} = \max(\text{High},\; \text{Open}_{HA},\; \text{Close}_{HA})$
  * $\text{Low}_{HA} = \min(\text{Low},\; \text{Open}_{HA},\; \text{Close}_{HA})$
* **Nhận diện xu hướng mạnh:**
  * Chuỗi nến xanh liên tiếp, **không có bóng dưới** $\rightarrow$ Uptrend cực mạnh.
  * Chuỗi nến đỏ liên tiếp, **không có bóng trên** $\rightarrow$ Downtrend cực mạnh.
  * Xuất hiện nến thân nhỏ có cả 2 bóng nến (Doji) $\rightarrow$ Xu hướng suy yếu, chuẩn bị đảo chiều.

---

<a name="unit-27"></a>
## Unit 27: Hệ Thống Chỉ Báo Mây Ichimoku Kinko Hyo

* **Tác giả:** Goichi Hosoda (nhà báo Nhật Bản, xuất bản 1969). Là hệ thống phân tích "nhìn thoáng qua là thấy sự cân bằng của biểu đồ".
* **5 Thành phần cốt lõi:**
  1. **Tenkan-sen (Đường chuyển đổi - 9 phiên):** Trung bình Đỉnh cao nhất + Đáy thấp nhất của 9 nến.
  2. **Kijun-sen (Đường cơ sở - 26 phiên):** Trung bình Đỉnh cao nhất + Đáy thấp nhất của 26 nến. Đường Kijun phẳng thể hiện hỗ trợ/kháng cự nam châm hút giá.
  3. **Senkou Span A (Đường dẫn A):** $\frac{\text{Tenkan} + \text{Kijun}}{2}$, vẽ dịch về phía trước 26 phiên.
  4. **Senkou Span B (Đường dẫn B):** Trung bình Đỉnh cao nhất + Đáy thấp nhất của 52 nến, vẽ dịch về phía trước 26 phiên.
  5. **Chikou Span (Đường trễ):** Giá đóng cửa hiện tại, vẽ lùi về quá khứ 26 phiên.
* **Mây Kumo:** Vùng không gian nằm giữa Span A và Span B.
  * Giá trên mây $\rightarrow$ Uptrend. Giá dưới mây $\rightarrow$ Downtrend. Giá trong mây $\rightarrow$ Sideway không rõ xu hướng.
  * Mây Kumo mỏng là vị trí giá dễ breakout xuyên thủng nhất. Mây Kumo dày đóng vai trò là bức tường cản cực kỳ vững chắc.

---

<a name="unit-28"></a>
## Unit 28: Fibonacci Thoái Lui (Retracement) & Mở Rộng (Extension)

* **Tỷ lệ vàng toán học:** Dãy Fibonacci $(0, 1, 1, 2, 3, 5, 8, 13, 21, \dots)$ tạo nên các tỷ lệ kỳ diệu $0.618$ và $0.382$.
* **Fibonacci Thoái lui (Retracement):**
  * Dùng khi thị trường đang có sóng đẩy và bắt đầu hồi quy.
  * Các mốc quan trọng: **0.382, 0.500, 0.618, 0.786**.
  * Vùng **Golden Pocket (0.5 – 0.618)**: Điểm vào lệnh chuẩn mực nhất của các trader tổ chức khi hợp lưu cùng đỉnh/đáy hỗ trợ cũ.
* **Fibonacci Mở rộng (Extension):**
  * Các mốc: **1.272, 1.618, 2.618**.
  * Dùng để đo lường biên độ con sóng tiếp theo khi giá phá đỉnh cũ, giúp đặt mục tiêu chốt lời (Take Profit) khách quan thay vì đoán mò.

---

<a name="unit-29"></a>
## Unit 29: Pivot Point - Điểm Xoay Đỉnh Đáy

* **Khái niệm:** Công cụ tính toán các mức cản trong ngày (Intraday) dựa trên dữ liệu giá của phiên trước đó:
  * Điểm xoay trục chính:  
    $$PP = \frac{\text{High}_{\text{prev}} + \text{Low}_{\text{prev}} + \text{Close}_{\text{prev}}}{3}$$
  * Các mức kháng cự (Resistance):
    $$R1 = 2 \times PP - \text{Low}_{\text{prev}}$$
    $$R2 = PP + (\text{High}_{\text{prev}} - \text{Low}_{\text{prev}})$$
    $$R3 = \text{High}_{\text{prev}} + 2 \times (PP - \text{Low}_{\text{prev}})$$
  * Các mức hỗ trợ (Support):
    $$S1 = 2 \times PP - \text{High}_{\text{prev}}$$
    $$S2 = PP - (\text{High}_{\text{prev}} - \text{Low}_{\text{prev}})$$
    $$S3 = \text{Low}_{\text{prev}} - 2 \times (\text{High}_{\text{prev}} - PP)$$
* **Chiến thuật:**
  * Nếu giá mở cửa nằm trên $PP \rightarrow$ Ưu tiên canh Mua. Nằm dưới $PP \rightarrow$ Ưu tiên canh Bán.
  * Đánh đảo chiều khi giá chạm $S3$ hoặc $R3$ trong ngày không có tin tức biến động mạnh.
  * Đánh phá vỡ (Breakout): Khi nến đóng cửa vượt qua $R1$, nhắm mục tiêu đến $R2$.

---

<a name="unit-30"></a>
## Unit 30: Chỉ Báo Hàng Hóa CCI (Commodity Channel Index)

* **Tác giả:** Donald Lambert (1980). Đo lường mức độ sai lệch của giá so với mức giá trung bình thống kê.
* **Vùng biên độ quan trọng:** $+100$ và $-100$.
  * $\text{CCI} > +100$: Trạng thái quá mua (Overbought) hoặc bắt đầu một đà bùng nổ tăng giá mạnh.
  * $\text{CCI} < -100$: Trạng thái quá bán (Oversold) hoặc đà bán tháo mạnh.
* **Chiến thuật giao dịch:**
  * **Giao cắt đường 0 (Zero-line Cross):** Mua khi CCI cắt lên trên 0 trong xu hướng tăng lớn; Bán khi CCI cắt xuống dưới 0 trong xu hướng giảm.
  * **Phân kỳ CCI:** Tương tự như RSI và MACD, phân kỳ giữa đỉnh/đáy giá và CCI là dấu hiệu sớm báo hiệu cạn kiệt động lượng.
