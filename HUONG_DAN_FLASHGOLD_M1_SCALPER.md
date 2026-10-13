# ⚡ HƯỚNG DẪN VẬN HÀNH FLASHGOLD M1 - TURBO SCALPER EA

Robot Siêu Lướt Sóng Chuyên Biệt Khung M1 Cho Vàng (**XAUUSD / XAUUSDm / XAUUSDz**) trên sàn Exness.

---

## 🎯 1. TẠI SAO CON BOT NÀY GIẢI QUYẾT TRIỆT ĐỂ LỖI "VỪA MỞ LÀ DÍNH SL"?

| Tiêu chí | Bot cũ (QuantumPulse) | ⚡ FLASHGOLD M1 SCALPER (MỚI) |
| :--- | :--- | :--- |
| **Cách tính SL/TP** | Tính theo Points bị chia sai do Exness 3 chữ số thập phân $\rightarrow$ **SL chỉ có $0.45** (45 cents) | **Tính trực tiếp theo GIÁ USD VÀNG**: Cố định **$2.20 - $2.50 giá** |
| **So với Spread Exness** | Spread $0.24 mà SL chỉ $0.45 $\rightarrow$ **chỉ cần giật nhẹ 2 tick là quét sạch SL** | SL $2.20 **gấp gần 10 lần Spread** $\rightarrow$ Nến M1 thoải mái thở, triệt tiêu quét râu |
| **Cơ chế Hòa Vốn (BE)** | Nhích nhẹ $0.36 là kéo SL về $0.07 $\rightarrow$ giá vừa quay đầu là cắn SL hòa vốn ngay | Phải chạy ít nhất **$1.60 giá** mới kéo BE; kèm bù Spread +$0.35 $\rightarrow$ **về BE vẫn CÓ LÃI** |
| **Tần suất & Nhịp độ** | Khóa Cooldown 40 phút $\rightarrow$ ngồi chờ mòn mỏi cả tiếng mới có 1 lệnh | **Tần suất M1 liên tục**: Cooldown chỉ 0 - 15 giây, quét theo từng nến M1 |

---

## 🚀 2. HƯỚNG DẪN KÍCH HOẠT TRÊN MT5 (CHỈ MẤT 30 GIÂY)

1. Mở phần mềm **MetaTrader 5 Exness**.
2. Mở chart **XAUUSDm** (hoặc XAUUSD), chọn khung thời gian **M1** (1 Phút).
3. Tại khung cửa sổ **Navigator** (bên trái):
   - Nhấp chuột phải vào mục **Expert Advisors** $\rightarrow$ Chọn **Refresh**.
   - Anh sẽ thấy xuất hiện ngay: **`FlashGold_M1_Scalper_EA`**.
4. Kéo thả **`FlashGold_M1_Scalper_EA`** vào đồ thị M1.
5. Tại tab **Common**: Tích chọn **Allow Algo Trading** (Cho phép giao dịch tự động).
6. Bấm **OK**. Kiểm tra góc trên bên phải chart có icon nón xanh và nút **Algo Trading** trên thanh công cụ đang bật màu xanh.

---

## ⚙️ 3. BẢNG THÔNG SỐ TỐI ƯU KHUYÊN DÙNG THEO MỨC VỐN

| Mức vốn | Chế độ Lot | Lot đề xuất | Max Lệnh đồng thời | Lãi mục tiêu ngày |
| :--- | :--- | :--- | :--- | :--- |
| **$100 - $300** | `M1_LOT_FIXED` | `0.01` | 1 lệnh | $10 - $20 |
| **$500 - $1,000** | `M1_LOT_FIXED` | `0.02 - 0.03` | 2 lệnh | $30 - $60 |
| **$1,000 - $3,000** | `M1_LOT_FIXED` | `0.05 - 0.10` | 2 - 3 lệnh | $80 - $150 |

---

## 💡 4. CÁC THIẾT LẬP NÂNG CAO TRONG INPUT PARAMETERS

- **`InpTriggerMode`**:
  - `TRIGGER_EMA_RSI_FLOW` (Mặc định - Khuyên nghị): Lướt sóng theo bộ 3 đường EMA (9/21/50) + RSI 7. Tỷ lệ thắng cao nhất.
  - `TRIGGER_ULTRA_AGGRESSIVE`: Chế độ cực nhanh, mở lệnh dồn dập ngay khi EMA 9 cắt EMA 21.
- **`InpStopLoss_USD`**: Mặc định `2.20` ($2.20 giá Vàng). Tuyệt đối không hạ dưới $1.80 để tránh nhiễu spread Exness.
- **`InpTakeProfit_USD`**: Mặc định `2.80` ($2.80 giá Vàng).
- **`InpUseMoneyTP`**: `true` | `InpTargetProfitUSD = 3.50`: Cứ mỗi lệnh chạm lãi $3.50 tiền mặt là bot chủ động đóng ngay đút túi, không để thị trường kịp đảo chiều.
- **`InpCooldownSeconds`**: Mặc định `15` giây. Nếu muốn vừa đóng lệnh là vào lệnh tiếp theo ngay lập tức, anh có thể đặt về `0`.
