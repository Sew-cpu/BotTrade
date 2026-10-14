# CẨM NANG VẬN HÀNH AURORA SNIPER M15 EA (1000U) - PHIÊN BẢN SÁNG & CHIỀU THỰC CHIẾN

> **Mã nguồn Robot:** [`AuroraSniper_M15_1000U_EA.mq5`](file:///c:/Users/AD/Documents/BotTrade/AuroraSniper_M15_1000U_EA.mq5) *(v10.0 - DUAL SESSION EDITION)*  
> **File thực thi đã biên dịch:** [`AuroraSniper_M15_1000U_EA.ex5`](file:///c:/Users/AD/Documents/BotTrade/AuroraSniper_M15_1000U_EA.ex5) *(Đã biên dịch 0 lỗi, 0 cảnh báo)*  
> **Nền tảng:** MetaTrader 5 (MT5)  
> **Khung thời gian:** **M15 (15 Phút) & Xác nhận Trend H4 + H1**  
> **Mức vốn tối ưu:** **$1,000 USD (1000u)**  
> **Tài sản khuyến nghị:** **`XAUUSD` (Vàng)**  

---

## 1. VÌ SAO CHIỀU NAY BOT KHÔNG VÀO LỆNH VÀ ĐÃ ĐƯỢC KHẮC PHỤC THẾ NÀO?

Trong buổi chiều hôm nay, giá Vàng có một đợt đổ đèo (Downtrend) rất mạnh từ **4,168** xuống **4,142** nhưng bot chưa kịp vào lệnh vì 2 lý do:

1. **Bộ lọc râu nến trước đó bị thắt quá chặt (yêu cầu râu $\ge 70\%$):** Trong những con sóng Vàng đổ đèo hoặc tăng mạnh theo trend, các cây nến giảm là nến thân đặc (Momentum Candle), râu nến trên chỉ dài 15% – 25% nên thuật toán Pin Bar cũ đã bỏ qua.
2. **Điểm bóp cò đặt ở mức 90/100:** Ngưỡng 90 điểm chỉ kích hoạt khi có bẫy quét thanh khoản đỉnh/đáy đêm (Tokyo Sweep lúc sáng sớm). Sang đến phiên chiều, giá đã cách xa vùng đáy đêm nên không có điểm thưởng Sweep, khiến tổng điểm chỉ dừng ở mức 80 – 85 điểm (bị thiếu 5 – 10 điểm để bóp cò).

---

## 2. NÂNG CẤP V10.0 MỚI NHẤT ĐỂ BẮT TRỌN SÓNG CẢ SÁNG LẪN CHIỀU

1. **Bổ Sung Thế Đánh `SIGNAL_MOMENTUM_BEAR` & `SIGNAL_MOMENTUM_BULL`:**
   * Khi H4 và H1 đồng thuận Downtrend mạnh (như chiều nay): Nến M15 giảm dứt khoát với thân nến $\ge 50\%$ phá vỡ đáy nến trước và nằm dưới Mid Band của DBB $\rightarrow$ **Kích hoạt ngay lệnh SELL tiếp diễn xu hướng**!
   * Khi H4 và H1 đồng thuận Uptrend: Nến M15 tăng dứt khoát phá vỡ đỉnh nến trước $\rightarrow$ **Kích hoạt ngay lệnh BUY tiếp diễn xu hướng**!
2. **Bổ Sung Săn Thanh Khoản Đỉnh/Đáy Phiên Sáng Cho Phiên Chiều (London Asian Sweep):**
   * Phiên sáng tạo ra `Asian High` và `Asian Low`.
   * Phiên chiều (14:00 – 18:30 VN): Khi London phá vỡ hoặc quét cản đỉnh/đáy sáng $\rightarrow$ Được cộng ngay **+15 điểm thưởng SMC**!
3. **Cân Chỉnh Ngưỡng Điểm Bóp Cò Chuẩn Vàng $\ge 80/100$:**
   * Chỉ cần H4 Trend (+20) + H1 Trend (+20) + DBB Pullback (+20) + Nến Động Lượng (+20) = **80 Điểm $\rightarrow$ Bóp cò ngay lập tức!**
   * Vẫn giữ tỷ lệ thắng cao vì:
     * Tuyệt đối không đánh ngược H4 và H1.
     * Auto Break-Even sớm tại `+0.65R` (~$2.0 giá Vàng là lệnh trở thành Risk-Free 0% rủi ro).
     * Chốt lời 50% tại `+1.0R` (~$3.0 giá Vàng là đút túi tiền tươi chắc chắn).
     * Target TP ngọt ngào tại `1:1.8`.
