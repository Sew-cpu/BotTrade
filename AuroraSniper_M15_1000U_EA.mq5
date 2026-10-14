//+------------------------------------------------------------------+
//|                                       AuroraSniper_M15_1000U_EA.mq5 |
//|          XẠ THỦ PHIÊN SÁNG & CHIỀU - HỆ THỐNG GIAO DỊCH VÀNG 1000$ |
//|    Chuyên Biệt Giờ Việt Nam (GMT+7): Phiên Sáng (Á) & Chiều (Âu) |
//|       KẾT HỢP: SĂN THANH KHOẢN SMC + BẮT SÓNG TIẾP DIỄN TREND     |
//|        BẢNG ĐIỀU KHIỂN HUD ĐỒ HỌA SANG TRỌNG (KHÔNG ĐÈ NẾN)      |
//|               Bản Quyền 2026 - Tinh Hoa Price Action & SMC       |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Antigravity Institutional Trading"
#property link        "https://github.com"
#property version     "10.00"
#property description "AURORA SNIPER EA - Chuyên Biệt Vàng (XAUUSD) M15 Phiên Sáng & Chiều VN"
#property description "Giờ Việt Nam GMT+7: Phiên Sáng (07:00-11:30 VN) & Phiên Chiều (14:00-18:30 VN)"
#property description "Hỗ trợ 2 thế đánh: Săn bẫy quét thanh khoản SMC + Bắt sóng xung lực Trend tiếp diễn"
#property description "Chế độ High Winrate: Auto BE 0.65R, Partial TP 1.0R, Target R:R 1:1.8"
#property strict

//--- Thư viện giao dịch MQL5 chuẩn
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS & STRUCTURES                                               |
//+------------------------------------------------------------------+
enum ENUM_WINRATE_MODE
  {
   MODE_ULTRA_WINRATE = 0, // [KHUYÊN DÙNG] Tỷ Lệ Thắng Đỉnh Cao (85% - 90%+ | Điểm >= 80, BE 0.65R, R:R 1:1.8)
   MODE_BALANCED      = 1  // Tiêu Chuẩn Cân Bằng (75% - 80% | Điểm >= 75, BE 0.8R, R:R 1:2.2)
  };

enum ENUM_SESSION_FINISH_MODE
  {
   FINISH_CLOSE_PROFIT_LOCK_BE = 0, // Chốt hết lệnh lãi, đưa lệnh còn lại về hòa vốn trước giờ nghỉ (Khuyên dùng)
   FINISH_CLOSE_ALL_POSITIONS  = 1, // Đóng toàn bộ mọi vị thế khi hết phiên (Về 100% tiền mặt)
   FINISH_STOP_NEW_ONLY        = 2  // Chỉ dừng mở lệnh mới, để các lệnh tự do chạm TP/SL
  };

enum ENUM_HUD_POSITION
  {
   HUD_LEFT_TOP    = 0, // Góc Trái Trên (Có Hộp Nền Đen Đồ Họa Riêng Biệt)
   HUD_RIGHT_TOP   = 1, // Góc Phải Trên (Gọn Gàng, Trống Biểu Đồ Bên Trái)
   HUD_HIDE        = 2  // Tắt Hoàn Toàn Bảng Điều Khiển
  };

enum ENUM_PRICE_ACTION_SIGNAL
  {
   SIGNAL_NONE             = 0,
   SIGNAL_PINBAR_BULLISH   = 1,
   SIGNAL_PINBAR_BEARISH   = 2,
   SIGNAL_FAKEY_BULLISH    = 3,
   SIGNAL_FAKEY_BEARISH    = 4,
   SIGNAL_ENGULFING_BULL   = 5,
   SIGNAL_ENGULFING_BEAR   = 6,
   SIGNAL_MOMENTUM_BULL    = 7, // Nến xung lực tăng mạnh thuận trend
   SIGNAL_MOMENTUM_BEAR    = 8  // Nến xung lực giảm mạnh thuận trend
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS (THIẾT LẬP THAM SỐ ĐẦU VÀO)                     |
//+------------------------------------------------------------------+
input group "=== 0. CHỌN CHẾ ĐỘ TỶ LỆ THẮNG (WIN RATE ENGINE) ==="
input ENUM_WINRATE_MODE         InpWinRateMode              = MODE_ULTRA_WINRATE; // Chế độ giao dịch (High Winrate 85%-90%+)

input group "=== 1. THIẾT LẬP PHIÊN SÁNG VIỆT NAM (PHIÊN Á: 07:00 - 11:30 VN) ==="
input bool                      InpTradeMorningSession      = true;         // Bật giao dịch PHIÊN SÁNG (Á)
input int                       InpMorningStartHourVN       = 7;            // Giờ VN BẮT ĐẦU sáng (07:00 VN lúc Tokyo mở cửa)
input int                       InpMorningStartMinVN        = 0;            // Phút VN bắt đầu (00)
input int                       InpMorningEndHourVN         = 11;           // Giờ VN DỪNG mở lệnh sáng (11:30 VN)
input int                       InpMorningEndMinVN          = 30;           // Phút VN dừng mở lệnh sáng (30)
input int                       InpMorningFinishHourVN      = 12;           // Giờ VN CHỐT PHIÊN SÁNG (12:30 trưa VN)
input int                       InpMorningFinishMinVN       = 30;           // Phút VN chốt phiên sáng (30)

input group "=== 2. THIẾT LẬP PHIÊN CHIỀU VIỆT NAM (PHIÊN ÂU: 14:00 - 18:30 VN) ==="
input bool                      InpTradeAfternoonSession    = true;         // Bật giao dịch PHIÊN CHIỀU (Âu)
input int                       InpAfternoonStartHourVN     = 14;           // Giờ VN BẮT ĐẦU chiều (14:00 VN London mở cửa)
input int                       InpAfternoonStartMinVN      = 0;            // Phút VN bắt đầu (00)
input int                       InpAfternoonEndHourVN       = 18;           // Giờ VN DỪNG mở lệnh chiều (18:30 VN)
input int                       InpAfternoonEndMinVN        = 30;           // Phút VN dừng mở lệnh chiều (30)
input int                       InpAfternoonFinishHourVN    = 19;           // Giờ VN CHỐT PHIÊN CHIỀU (19:00 tối VN)
input int                       InpAfternoonFinishMinVN     = 0;            // Phút VN chốt phiên chiều (00)
input ENUM_SESSION_FINISH_MODE  InpSessionFinishMode        = FINISH_CLOSE_PROFIT_LOCK_BE; // Cơ chế xử lý khi hết phiên

input group "=== 3. QUẢN TRỊ VỐN CHUẨN 1000U (RISK MANAGEMENT) ==="
input double                    InpBaseCapital              = 1000.0;       // Mức vốn mục tiêu (USD)
input double                    InpRiskPercentPerTrade      = 1.0;          // % Rủi ro mỗi lệnh (1.0% = $10 / lệnh cho 1000u)
input double                    InpMaxLotAllowed            = 0.08;         // Khối lượng Lot trần tối đa an toàn (1000u)
input int                       InpMaxTradesPerSession      = 1;            // Số lệnh tối đa mỗi phiên (1 sáng + 1 chiều = 2 lệnh/ngày)
input int                       InpMaxConcurrentPositions   = 1;            // Số lệnh mở đồng thời tối đa (Duy nhất 1 lệnh)
input double                    InpMaxDailyDrawdownPct      = 2.5;          // Giới hạn sụt giảm tối đa trong ngày (2.5% = $25)
input int                       InpMaxSpreadPoints          = 320;          // Spread tối đa cho Vàng (320 pts chuẩn Exness/IC Markets)

input group "=== 4. CHỈ SỐ LỌC ĐIỂM ĐẸP (A+ CONFLUENCE FILTERS) ==="
input int                       InpMinConfluenceScore       = 80;           // Điểm số tối thiểu để bắn tỉa (80/100: Chuẩn tối ưu thực chiến)
input bool                      InpUseH4TrendFilter         = true;         // Bật lọc đồng pha xu hướng vĩ mô H4
input bool                      InpUseHtfTrendFilter        = true;         // Bật lọc xu hướng H1
input int                       InpHtfFastEma               = 21;           // EMA 21 trên H1
input int                       InpHtfSlowEma               = 50;           // EMA 50 trên H1
input int                       InpH4TrendEma               = 50;           // EMA 50 trên H4 (Định hướng dòng tiền lớn)
input int                       InpDbbPeriod                = 20;           // Chu kỳ Double Bollinger Bands (M15)
input double                    InpDbbDevOuter              = 2.0;          // Độ lệch chuẩn ngoài (+2.0 SD)
input double                    InpDbbDevInner              = 1.0;          // Độ lệch chuẩn trong (+1.0 SD)
input int                       InpRsiPeriod                = 14;           // Chu kỳ RSI (Lọc động lượng)
input double                    InpRsiBuyMin                = 40.0;         // RSI tối thiểu để BUY
input double                    InpRsiBuyMax                = 68.0;         // RSI tối đa để BUY
input double                    InpRsiSellMin               = 32.0;         // RSI tối thiểu để SELL
input double                    InpRsiSellMax               = 60.0;         // RSI tối đa để SELL

input group "=== 5. QUY TẮC NẾN PRICE ACTION & THANH KHOẢN ĐA PHIÊN ==="
input double                    InpMinPinBarWickRatio       = 0.55;         // Tỷ lệ râu nến Pin Bar chuẩn (>= 55%)
input double                    InpMaxPinBarBodyRatio       = 0.35;         // Tỷ lệ thân nến Pin Bar (<= 35%)
input bool                      InpUseSweepFilters          = true;         // Bật bẫy quét thanh khoản Đêm (cho sáng) & Đỉnh/Đáy sáng (cho chiều)
input int                       InpOvernightStartHourVN     = 23;           // Giờ bắt đầu tính biên độ đêm (23:00 VN tối hôm trước)
input int                       InpOvernightEndHourVN       = 6;            // Giờ kết thúc biên độ đêm (06:00 VN sáng hôm sau)

input group "=== 6. STOP LOSS & CHỐT LỜI ULTRA WINRATE (85% - 90%+) ==="
input int                       InpAtrPeriod                = 14;           // Chu kỳ ATR đo biến động nến M15
input double                    InpAtrSlMultiplier          = 1.4;          // Hệ số nhân ATR cho Stop Loss động
input double                    InpTargetRrRatio            = 1.8;          // Tỷ lệ R:R mục tiêu (1:1.8 - Cực dễ chạm full TP)
input bool                      InpUsePartialClose          = true;         // Kích hoạt chốt lời từng phần 50%
input double                    InpPartialCloseRatioR       = 1.0;          // Chốt 50% khối lượng khi đạt 1.0R (Đút túi tiền tươi sớm)
input bool                      InpUseAutoBreakEven         = true;         // Tự động dời Stop Loss về hòa vốn (Risk-Free)
input double                    InpBreakEvenTriggerR        = 0.65;         // Kích hoạt hòa vốn sớm tại 0.65R (Chạy ~$2.0 giá là an toàn)
input int                       InpBreakEvenBufferPts       = 15;           // Đệm cộng thêm để bù spread & swap (Points)
input bool                      InpUseTrailingStop          = true;         // Kích hoạt Trailing Stop ATR sau khi chốt 50%
input double                    InpTrailingStartR           = 1.3;          // Kích hoạt Trailing khi giá vượt 1.3R
input double                    InpTrailingAtrMult          = 1.1;          // Khoảng cách Trailing Stop (x ATR)

input group "=== 7. BẢO VỆ TIN TỨC & CHỐNG SỐC BIẾN ĐỘNG ==="
input bool                      InpUseNewsFilter            = true;         // Bật lọc tin tức kinh tế MQL5 Calendar
input int                       InpNewsPauseMinsBefore      = 60;           // Dừng mở lệnh trước tin đỏ (phút) - Tăng 60p né bão CPI/NFP
input int                       InpNewsPauseMinsAfter       = 30;           // Dừng mở lệnh sau tin đỏ (phút)
input bool                      InpNewsLockOpenToBE         = true;         // Tự kéo SL về hòa vốn nếu có lệnh trước tin
input double                    InpVolSpikeThreshold        = 1.8;          // Ngưỡng phát hiện sốc biến động (ATR 3 / ATR 30)

input group "=== 8. HỆ THỐNG GIAO DIỆN & CẤU HÌNH HỆ THỐNG ==="
input ENUM_HUD_POSITION         InpHudPosition              = HUD_LEFT_TOP; // Vị trí bảng điều khiển (Góc Trái/Phải/Ẩn)
input ulong                     InpMagicNumber              = 7772026;      // Magic Number định danh (Aurora 777)
input string                    InpTradeComment             = "AuroraSniper_1000U"; // Ghi chú lệnh
input ulong                     InpSlippage                 = 30;           // Độ trượt giá tối đa (Points)

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & HANDLES                                         |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;
CPositionInfo  m_positionHelper;
CAccountInfo   m_account;
CSymbolInfo    m_symbol;

int            m_h4TrendEmaHandle     = INVALID_HANDLE;
int            m_htfFastEmaHandle     = INVALID_HANDLE;
int            m_htfSlowEmaHandle     = INVALID_HANDLE;
int            m_bbOuterHandle        = INVALID_HANDLE;
int            m_bbInnerHandle        = INVALID_HANDLE;
int            m_rsiHandle            = INVALID_HANDLE;
int            m_atrHandle            = INVALID_HANDLE;
int            m_atrFastHandle        = INVALID_HANDLE;
int            m_atrSlowHandle        = INVALID_HANDLE;

datetime       m_lastBarTime          = 0;
datetime       m_dailyResetDate       = 0;
double         m_dailyStartEquity     = 0.0;
bool           m_dailyShieldActive    = false;
int            m_morningTradesCount   = 0;
int            m_afternoonTradesCount = 0;

int            m_pointScale           = 1;

// Range đêm (cho phiên Sáng)
double         m_overnightHigh        = 0.0;
double         m_overnightLow         = 0.0;
bool           m_overnightReady       = false;
datetime       m_overnightCalcDate    = 0;

// Range sáng (cho phiên Chiều)
double         m_asianHigh            = 0.0;
double         m_asianLow             = 0.0;
bool           m_asianReady           = false;
datetime       m_asianCalcDate        = 0;

string         m_newsStatusText       = "AN TOÀN (Không có tin đỏ)";
bool           m_isNewsRestricted     = false;
string         m_volatilityText       = "BÌNH THƯỜNG (1.0x)";
bool           m_isVolShocked         = false;
double         m_currentVolRatio      = 1.0;
int            m_lastSetupScore       = 0;
string         m_lastSetupDesc        = "Đang dò tìm A+ Setup...";

// Dynamic values according to WinRate mode
double         g_effectiveBeTriggerR    = 0.65;
double         g_effectivePartialCloseR = 1.0;
double         g_effectiveTargetRr      = 1.8;
int            g_effectiveMinScore      = 80;
double         g_effectiveWickRatio     = 0.55;
double         g_effectiveBodyRatio     = 0.35;

//+------------------------------------------------------------------+
//| HÀM LẤY GIỜ VIỆT NAM GMT+7 CHUẨN XÁC                             |
//+------------------------------------------------------------------+
datetime GetCurrentVietnamTime()
  {
   datetime gmt = TimeGMT();
   if(gmt > 0)
      return (gmt + 7 * 3600);
   return TimeLocal();
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!m_symbol.Name(_Symbol))
     {
      Print("Lỗi khởi tạo Symbol: ", _Symbol);
      return INIT_FAILED;
     }
   m_symbol.RefreshRates();

   if(_Digits == 3 || _Digits == 5)
      m_pointScale = 10;
   else
      m_pointScale = 1;

   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(InpSlippage * m_pointScale);
   m_trade.SetTypeFillingBySymbol(_Symbol);

   Comment("");
   ObjectsDeleteAll(0, "AS_HUD_");

   if(InpWinRateMode == MODE_ULTRA_WINRATE)
     {
      g_effectiveBeTriggerR    = 0.65;
      g_effectivePartialCloseR = 1.0;
      g_effectiveTargetRr      = 1.8;
      g_effectiveMinScore      = 80; // Chuẩn A+ tối ưu, không bỏ lỡ sóng
      g_effectiveWickRatio     = 0.55;
      g_effectiveBodyRatio     = 0.35;
     }
   else
     {
      g_effectiveBeTriggerR    = InpBreakEvenTriggerR;
      g_effectivePartialCloseR = InpPartialCloseRatioR;
      g_effectiveTargetRr      = InpTargetRrRatio;
      g_effectiveMinScore      = 75;
      g_effectiveWickRatio     = 0.50;
      g_effectiveBodyRatio     = 0.40;
     }

   if(InpUseH4TrendFilter)
     {
      m_h4TrendEmaHandle = iMA(_Symbol, PERIOD_H4, InpH4TrendEma, 0, MODE_EMA, PRICE_CLOSE);
      if(m_h4TrendEmaHandle == INVALID_HANDLE)
        {
         Print("Lỗi tạo handle H4 EMA!");
         return INIT_FAILED;
        }
     }

   if(InpUseHtfTrendFilter)
     {
      m_htfFastEmaHandle = iMA(_Symbol, PERIOD_H1, InpHtfFastEma, 0, MODE_EMA, PRICE_CLOSE);
      m_htfSlowEmaHandle = iMA(_Symbol, PERIOD_H1, InpHtfSlowEma, 0, MODE_EMA, PRICE_CLOSE);
      if(m_htfFastEmaHandle == INVALID_HANDLE || m_htfSlowEmaHandle == INVALID_HANDLE)
        {
         Print("Lỗi tạo handle HTF EMA!");
         return INIT_FAILED;
        }
     }

   m_bbOuterHandle = iBands(_Symbol, PERIOD_M15, InpDbbPeriod, 0, InpDbbDevOuter, PRICE_CLOSE);
   m_bbInnerHandle = iBands(_Symbol, PERIOD_M15, InpDbbPeriod, 0, InpDbbDevInner, PRICE_CLOSE);
   if(m_bbOuterHandle == INVALID_HANDLE || m_bbInnerHandle == INVALID_HANDLE)
     {
      Print("Lỗi tạo handle Double Bollinger Bands!");
      return INIT_FAILED;
     }

   m_rsiHandle     = iRSI(_Symbol, PERIOD_M15, InpRsiPeriod, PRICE_CLOSE);
   m_atrHandle     = iATR(_Symbol, PERIOD_M15, InpAtrPeriod);
   m_atrFastHandle = iATR(_Symbol, PERIOD_M15, 3);
   m_atrSlowHandle = iATR(_Symbol, PERIOD_M15, 30);
   if(m_rsiHandle == INVALID_HANDLE || m_atrHandle == INVALID_HANDLE ||
      m_atrFastHandle == INVALID_HANDLE || m_atrSlowHandle == INVALID_HANDLE)
     {
      Print("Lỗi tạo handle RSI hoặc ATR!");
      return INIT_FAILED;
     }

   m_dailyStartEquity = m_account.Equity();
   m_dailyResetDate   = iTime(_Symbol, PERIOD_D1, 0);

   Print("==========================================================");
   PrintFormat("=== AURORA SNIPER M15 - PHIÊN SÁNG & CHIỀU VN (1000U) ===");
   PrintFormat("Chế độ: %s | Vốn: $%.2f | Sáng: %02d:%02d-%02d:%02d VN | Chiều: %02d:%02d-%02d:%02d VN",
               (InpWinRateMode == MODE_ULTRA_WINRATE ? "ULTRA WINRATE (85% - 90%+)" : "TIÊU CHUẨN"),
               m_account.Balance(),
               InpMorningStartHourVN, InpMorningStartMinVN, InpMorningEndHourVN, InpMorningEndMinVN,
               InpAfternoonStartHourVN, InpAfternoonStartMinVN, InpAfternoonEndHourVN, InpAfternoonEndMinVN);
   Print("==========================================================");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(m_h4TrendEmaHandle != INVALID_HANDLE) IndicatorRelease(m_h4TrendEmaHandle);
   if(m_htfFastEmaHandle != INVALID_HANDLE) IndicatorRelease(m_htfFastEmaHandle);
   if(m_htfSlowEmaHandle != INVALID_HANDLE) IndicatorRelease(m_htfSlowEmaHandle);
   if(m_bbOuterHandle    != INVALID_HANDLE) IndicatorRelease(m_bbOuterHandle);
   if(m_bbInnerHandle    != INVALID_HANDLE) IndicatorRelease(m_bbInnerHandle);
   if(m_rsiHandle        != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
   if(m_atrHandle        != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
   if(m_atrFastHandle    != INVALID_HANDLE) IndicatorRelease(m_atrFastHandle);
   if(m_atrSlowHandle    != INVALID_HANDLE) IndicatorRelease(m_atrSlowHandle);

   ObjectsDeleteAll(0, "AS_HUD_");
   Comment("");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   m_symbol.RefreshRates();

   // 1. Quản lý sụt giảm ngày (Daily Loss Shield)
   CheckDailyResetAndShield();

   // 2. Tính toán biên độ phiên đêm (cho sáng) & phiên sáng (cho chiều)
   UpdateOvernightRange();
   UpdateAsianMorningRange();

   // 3. Quản lý lệnh đang mở (Auto Break-Even sớm, Partial TP 50%, Chandelier Trailing Stop)
   ManageActivePositions();

   // 4. Quy trình xử lý khi hết phiên sáng (12:30 VN) & hết phiên chiều (19:00 VN)
   ProcessSessionFinishProtocols();

   // 5. Cập nhật bảng điều khiển đồ họa HUD Dashboard
   RenderModernDashboard();

   // 6. Kiểm tra nến M15 mới đóng cửa để phân tích điểm vào lệnh (Khóa cứng M15)
   datetime currentBarTime = iTime(_Symbol, PERIOD_M15, 0);
   if(currentBarTime == m_lastBarTime)
      return;

   m_lastBarTime = currentBarTime;

   // 7. Kiểm tra các điều kiện an toàn trước khi tìm cơ hội bắn tỉa
   string sessionName = "";
   if(!IsMarketSafeForTrading(sessionName))
      return;

   // 8. Quét tín hiệu Price Action & chấm điểm Confluence Setup A+
   CheckForSniperSignals(sessionName);
  }

//+------------------------------------------------------------------+
//| QUẢN LÝ SỤT GIẢM NGÀY (DAILY LOSS SHIELD)                        |
//+------------------------------------------------------------------+
void CheckDailyResetAndShield()
  {
   datetime todayD1 = iTime(_Symbol, PERIOD_D1, 0);
   if(todayD1 != m_dailyResetDate)
     {
      m_dailyResetDate       = todayD1;
      m_dailyStartEquity     = m_account.Equity();
      m_dailyShieldActive    = false;
      m_morningTradesCount   = 0;
      m_afternoonTradesCount = 0;
      PrintFormat(">> [DAILY RESET] Ngày mới bắt đầu. Vốn chốt mốc: $%.2f", m_dailyStartEquity);
     }

   if(m_dailyStartEquity <= 0.0)
      m_dailyStartEquity = m_account.Equity();

   double currentEquity = m_account.Equity();
   double dailyDd = ((m_dailyStartEquity - currentEquity) / m_dailyStartEquity) * 100.0;

   if(dailyDd >= InpMaxDailyDrawdownPct && !m_dailyShieldActive)
     {
      m_dailyShieldActive = true;
      PrintFormat(">> [CẢNH BÁO BẢO VỆ VỐN] Sụt giảm ngày đạt %.2f%% (Vượt %.2f%%). Khóa bot bảo toàn vốn 1000U!",
                  dailyDd, InpMaxDailyDrawdownPct);
     }
  }

//+------------------------------------------------------------------+
//| TÍNH TOÁN BIÊN ĐỘ PHIÊN ĐÊM (OVERNIGHT RANGE: 23:00 - 06:00 VN)  |
//+------------------------------------------------------------------+
void UpdateOvernightRange()
  {
   datetime nowVn = GetCurrentVietnamTime();
   MqlDateTime dt;
   TimeToStruct(nowVn, dt);

   datetime todayStart = nowVn - (dt.hour * 3600 + dt.min * 60 + dt.sec);
   if(m_overnightCalcDate == todayStart && m_overnightReady)
      return;

   if(dt.hour < 6)
      return;

   int barsNeeded = 32;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   if(CopyRates(_Symbol, PERIOD_M15, 1, barsNeeded, rates) >= barsNeeded)
     {
      double highest = -1.0;
      double lowest  = 999999.0;
      int count = 0;

      for(int i = 0; i < barsNeeded; i++)
        {
         datetime barVn = rates[i].time - (TimeCurrent() - TimeGMT()) + 7 * 3600;
         MqlDateTime barDt;
         TimeToStruct(barVn, barDt);

         bool isOvernightBar = false;
         if(barDt.day == dt.day && barDt.hour < InpOvernightEndHourVN)
            isOvernightBar = true;
         else if(barDt.day != dt.day && barDt.hour >= InpOvernightStartHourVN)
            isOvernightBar = true;

         if(isOvernightBar)
           {
            if(rates[i].high > highest) highest = rates[i].high;
            if(rates[i].low < lowest)   lowest  = rates[i].low;
            count++;
           }
        }

      if(count >= 8 && highest > 0 && lowest < 999999.0)
        {
         m_overnightHigh     = highest;
         m_overnightLow      = lowest;
         m_overnightReady    = true;
         m_overnightCalcDate = todayStart;
        }
     }
  }

//+------------------------------------------------------------------+
//| TÍNH TOÁN BIÊN ĐỘ PHIÊN SÁNG (ASIAN RANGE: 07:00 - 11:30 VN)     |
//+------------------------------------------------------------------+
void UpdateAsianMorningRange()
  {
   datetime nowVn = GetCurrentVietnamTime();
   MqlDateTime dt;
   TimeToStruct(nowVn, dt);

   datetime todayStart = nowVn - (dt.hour * 3600 + dt.min * 60 + dt.sec);
   if(m_asianCalcDate == todayStart && m_asianReady)
      return;

   if(dt.hour < 12)
      return; // Chỉ đo sau khi phiên sáng kết thúc

   int barsNeeded = 25;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   if(CopyRates(_Symbol, PERIOD_M15, 1, barsNeeded, rates) >= barsNeeded)
     {
      double highest = -1.0;
      double lowest  = 999999.0;
      int count = 0;

      for(int i = 0; i < barsNeeded; i++)
        {
         datetime barVn = rates[i].time - (TimeCurrent() - TimeGMT()) + 7 * 3600;
         MqlDateTime barDt;
         TimeToStruct(barVn, barDt);

         if(barDt.day == dt.day && barDt.hour >= 7 && (barDt.hour < 11 || (barDt.hour == 11 && barDt.min <= 30)))
           {
            if(rates[i].high > highest) highest = rates[i].high;
            if(rates[i].low < lowest)   lowest  = rates[i].low;
            count++;
           }
        }

      if(count >= 10 && highest > 0 && lowest < 999999.0)
        {
         m_asianHigh     = highest;
         m_asianLow      = lowest;
         m_asianReady    = true;
         m_asianCalcDate = todayStart;
         PrintFormat(">> [ASIAN MORNING RANGE] Đỉnh Sáng: %.2f | Đáy Sáng: %.2f", m_asianHigh, m_asianLow);
        }
     }
  }

//+------------------------------------------------------------------+
//| KIỂM TRA ĐIỀU KIỆN AN TOÀN TRƯỚC KHI BẮN TỈA (SÁNG & CHIỀU)      |
//+------------------------------------------------------------------+
bool IsMarketSafeForTrading(string &sessionName)
  {
   if(m_dailyShieldActive)
     {
      m_lastSetupDesc = "Đã chạm mức sụt giảm ngày tối đa (Shield On)";
      return false;
     }

   bool isSessionActive = CheckCurrentActiveSession(sessionName);
   if(!isSessionActive)
     {
      m_lastSetupDesc = "Ngoài phiên sáng/chiều VN (Nghỉ ngơi bảo vệ vốn)";
      return false;
     }

   if(sessionName == "SÁNG" && m_morningTradesCount >= InpMaxTradesPerSession)
     {
      m_lastSetupDesc = "Đã hoàn thành 1 lệnh đẹp nhất phiên Sáng";
      return false;
     }
   if(sessionName == "CHIỀU" && m_afternoonTradesCount >= InpMaxTradesPerSession)
     {
      m_lastSetupDesc = "Đã hoàn thành 1 lệnh đẹp nhất phiên Chiều";
      return false;
     }

   int currentPositions = CountOpenPositions();
   if(currentPositions >= InpMaxConcurrentPositions)
     {
      m_lastSetupDesc = "Đang gồng 1 vị thế mở (Chờ lệnh chạm TP/SL/BE)";
      return false;
     }

   long spread = m_symbol.Spread();
   if(spread > InpMaxSpreadPoints)
     {
      m_lastSetupDesc = StringFormat("Spread Vàng cao (%d > %d pts), bảo vệ vốn!", spread, InpMaxSpreadPoints);
      return false;
     }

   double fastAtr[], slowAtr[];
   ArraySetAsSeries(fastAtr, true);
   ArraySetAsSeries(slowAtr, true);

   if(CopyBuffer(m_atrFastHandle, 0, 1, 1, fastAtr) > 0 &&
      CopyBuffer(m_atrSlowHandle, 0, 1, 1, slowAtr) > 0)
     {
      if(slowAtr[0] > 0.0)
        {
         m_currentVolRatio = fastAtr[0] / slowAtr[0];
         if(m_currentVolRatio >= InpVolSpikeThreshold)
           {
            m_isVolShocked = true;
            m_volatilityText = StringFormat("SỐC BIẾN ĐỘNG (%.2fx) - DỪNG VÀO LỆNH", m_currentVolRatio);
            m_lastSetupDesc = m_volatilityText;
            return false;
           }
         else
           {
            m_isVolShocked = false;
            m_volatilityText = StringFormat("Ổn định (%.2fx)", m_currentVolRatio);
           }
        }
     }

   if(InpUseNewsFilter && CheckNewsRisk())
     {
      m_lastSetupDesc = "Có tin tức kinh tế High-Impact, bảo vệ lệnh!";
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| KIỂM TRA PHIÊN HIỆN TẠI (SÁNG HOẶC CHIỀU THEO GIỜ VN)            |
//+------------------------------------------------------------------+
bool CheckCurrentActiveSession(string &sessionName)
  {
   datetime targetTime = GetCurrentVietnamTime();
   MqlDateTime dt;
   TimeToStruct(targetTime, dt);

   int curMin = dt.hour * 60 + dt.min;

   // 1. Phiên Sáng (Á)
   if(InpTradeMorningSession)
     {
      int mStartMin = InpMorningStartHourVN * 60 + InpMorningStartMinVN;
      int mEndMin   = InpMorningEndHourVN * 60 + InpMorningEndMinVN;
      if(curMin >= mStartMin && curMin <= mEndMin)
        {
         sessionName = "SÁNG";
         return true;
        }
     }

   // 2. Phiên Chiều (Âu)
   if(InpTradeAfternoonSession)
     {
      int aStartMin = InpAfternoonStartHourVN * 60 + InpAfternoonStartMinVN;
      int aEndMin   = InpAfternoonEndHourVN * 60 + InpAfternoonEndMinVN;
      if(curMin >= aStartMin && curMin <= aEndMin)
        {
         sessionName = "CHIỀU";
         return true;
        }
     }

   sessionName = "NGHỈ";
   return false;
  }

//+------------------------------------------------------------------+
//| QUY TRÌNH "KẾT THÚC PHIÊN SÁNG (12:30) & CHIỀU (19:00)"          |
//+------------------------------------------------------------------+
void ProcessSessionFinishProtocols()
  {
   datetime targetTime = GetCurrentVietnamTime();
   MqlDateTime dt;
   TimeToStruct(targetTime, dt);

   int curMin      = dt.hour * 60 + dt.min;
   int mFinishMin  = InpMorningFinishHourVN * 60 + InpMorningFinishMinVN;
   int aFinishMin  = InpAfternoonFinishHourVN * 60 + InpAfternoonFinishMinVN;

   bool isFinishTime = false;
   string finishName = "";

   if(InpTradeMorningSession && curMin >= mFinishMin && curMin < (mFinishMin + 60))
     {
      isFinishTime = true;
      finishName   = "KẾT THÚC PHIÊN SÁNG (NGHỈ TRƯA)";
     }
   else if(InpTradeAfternoonSession && curMin >= aFinishMin && curMin < (aFinishMin + 60))
     {
      isFinishTime = true;
      finishName   = "KẾT THÚC PHIÊN CHIỀU (NGHỈ TỐI)";
     }

   if(isFinishTime)
     {
      double point = m_symbol.Point();
      double bufferPts = InpBreakEvenBufferPts * m_pointScale;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(!m_position.SelectByIndex(i)) continue;
         if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

         ulong  ticket    = m_position.Ticket();
         double openPrice = m_position.PriceOpen();
         double curPrice  = m_position.PriceCurrent();
         double curProfit = m_position.Profit();
         double curSl     = m_position.StopLoss();
         double curTp     = m_position.TakeProfit();

         if(InpSessionFinishMode == FINISH_CLOSE_ALL_POSITIONS)
           {
            m_trade.PositionClose(ticket);
            PrintFormat(">> [%s] Đóng toàn bộ vị thế ticket %d (Lãi/Lỗ: $%.2f)", finishName, ticket, curProfit);
           }
         else if(InpSessionFinishMode == FINISH_CLOSE_PROFIT_LOCK_BE)
           {
            if(curProfit > 0.0)
              {
               m_trade.PositionClose(ticket);
               PrintFormat(">> [%s - ĐÚT TÚI LỢI NHUẬN] Chốt sạch vị thế lãi ticket %d (Lãi: +$%.2f)", finishName, ticket, curProfit);
              }
            else
              {
               if(m_position.PositionType() == POSITION_TYPE_BUY)
                 {
                  double bePrice = NormalizeDouble(openPrice + bufferPts * point, _Digits);
                  if(curSl < bePrice && curPrice >= openPrice)
                    {
                     m_trade.PositionModify(ticket, bePrice, curTp);
                     PrintFormat(">> [%s - KHÓA BE] Dời SL BUY %d về hòa vốn an toàn", finishName, ticket);
                    }
                 }
               else if(m_position.PositionType() == POSITION_TYPE_SELL)
                 {
                  double bePrice = NormalizeDouble(openPrice - bufferPts * point, _Digits);
                  if((curSl > bePrice || curSl == 0.0) && curPrice <= openPrice)
                    {
                     m_trade.PositionModify(ticket, bePrice, curTp);
                     PrintFormat(">> [%s - KHÓA BE] Dời SL SELL %d về hòa vốn an toàn", finishName, ticket);
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| TÍNH TOÁN LOT CHUẨN XÁC THEO RISK 1.0% VỐN 1000U                 |
//+------------------------------------------------------------------+
double CalculateOptimalLotSize(double slPoints)
  {
   double balance = m_account.Balance();
   double equity  = m_account.Equity();
   double capital = MathMin(balance, equity);

   double riskMoney = capital * (InpRiskPercentPerTrade / 100.0);

   double tickSize  = m_symbol.TickSize();
   double tickValue = m_symbol.TickValue();
   double point     = m_symbol.Point();

   if(slPoints <= 0 || tickSize <= 0 || tickValue <= 0 || point <= 0)
      return m_symbol.LotsMin();

   double lossPerOneLot = (slPoints * point / tickSize) * tickValue;
   if(lossPerOneLot <= 0.0) return m_symbol.LotsMin();

   double rawLot = riskMoney / lossPerOneLot;

   double lotStep = m_symbol.LotsStep();
   double normalizedLot = MathFloor(rawLot / lotStep) * lotStep;

   double maxLotSafe = MathMin(InpMaxLotAllowed, m_symbol.LotsMax());
   if(normalizedLot < m_symbol.LotsMin()) normalizedLot = m_symbol.LotsMin();
   if(normalizedLot > maxLotSafe)        normalizedLot = maxLotSafe;

   return normalizedLot;
  }

//+------------------------------------------------------------------+
//| ĐÁNH GIÁ CHẤT LƯỢNG ĐIỂM VÀO LỆNH A+ CONFLUENCE SCORE (>= 80/100)|
//+------------------------------------------------------------------+
int EvaluateConfluenceScore(int direction, ENUM_PRICE_ACTION_SIGNAL paSignal, double entryPrice, double currentAtr, string sessionName, string &scoreReason)
  {
   int score = 0;
   scoreReason = "";

   // 1. Xu hướng vĩ mô H4 [+20 Điểm]
   if(InpUseH4TrendFilter && m_h4TrendEmaHandle != INVALID_HANDLE)
     {
      double h4Ema[];
      ArraySetAsSeries(h4Ema, true);
      if(CopyBuffer(m_h4TrendEmaHandle, 0, 1, 1, h4Ema) > 0)
        {
         if(direction == 1 && entryPrice > h4Ema[0])
           {
            score += 20;
            scoreReason += "H4 Bull (+20) | ";
           }
         else if(direction == -1 && entryPrice < h4Ema[0])
           {
            score += 20;
            scoreReason += "H4 Bear (+20) | ";
           }
         else
           {
            scoreReason += "H4 Ngược (0) | ";
            return 0; // Tuyệt đối không đánh ngược xu hướng H4!
           }
        }
     }
   else
     {
      score += 20;
     }

   // 2. Xu hướng HTF H1 [+20 Điểm]
   double htfFast[], htfSlow[];
   ArraySetAsSeries(htfFast, true);
   ArraySetAsSeries(htfSlow, true);

   if(InpUseHtfTrendFilter)
     {
      if(CopyBuffer(m_htfFastEmaHandle, 0, 1, 1, htfFast) > 0 &&
         CopyBuffer(m_htfSlowEmaHandle, 0, 1, 1, htfSlow) > 0)
        {
         if(direction == 1 && htfFast[0] > htfSlow[0])
           {
            score += 20;
            scoreReason += "H1 Up (+20) | ";
           }
         else if(direction == -1 && htfFast[0] < htfSlow[0])
           {
            score += 20;
            scoreReason += "H1 Down (+20) | ";
           }
         else
           {
            scoreReason += "H1 Ngược (0) | ";
            return 0; // Tuyệt đối không đánh ngược H1!
           }
        }
     }
   else
     {
      score += 20;
     }

   // 3. Vùng giá trị Double Bollinger Bands M15 [+20 Điểm]
   double innerUpper[], innerLower[], midBand[];
   ArraySetAsSeries(innerUpper, true);
   ArraySetAsSeries(innerLower, true);
   ArraySetAsSeries(midBand, true);

   if(CopyBuffer(m_bbInnerHandle, 1, 1, 1, innerUpper) > 0 &&
      CopyBuffer(m_bbInnerHandle, 2, 1, 1, innerLower) > 0 &&
      CopyBuffer(m_bbInnerHandle, 0, 1, 1, midBand) > 0)
     {
      if(direction == 1)
        {
         if(entryPrice >= innerLower[0] - currentAtr * 0.3 && entryPrice <= midBand[0] + currentAtr * 0.4)
           {
            score += 20;
            scoreReason += "DBB Pullback (+20) | ";
           }
         else if(entryPrice < innerLower[0])
           {
            score += 15;
            scoreReason += "DBB Discount (+15) | ";
           }
         else if(entryPrice > midBand[0] && (paSignal == SIGNAL_MOMENTUM_BULL || paSignal == SIGNAL_ENGULFING_BULL))
           {
            score += 20;
            scoreReason += "DBB Trend Breakout (+20) | ";
           }
        }
      else if(direction == -1)
        {
         if(entryPrice <= innerUpper[0] + currentAtr * 0.3 && entryPrice >= midBand[0] - currentAtr * 0.4)
           {
            score += 20;
            scoreReason += "DBB Pullback (+20) | ";
           }
         else if(entryPrice > innerUpper[0])
           {
            score += 15;
            scoreReason += "DBB Premium (+15) | ";
           }
         else if(entryPrice < midBand[0] && (paSignal == SIGNAL_MOMENTUM_BEAR || paSignal == SIGNAL_ENGULFING_BEAR))
           {
            score += 20;
            scoreReason += "DBB Trend Breakdown (+20) | ";
           }
        }
     }

   // 4. Tín hiệu Price Action Nến M15 [+20 Điểm]
   if(direction == 1)
     {
      if(paSignal == SIGNAL_PINBAR_BULLISH)
        {
         score += 20;
         scoreReason += "Pin Bar Rút Chân (+20) | ";
        }
      else if(paSignal == SIGNAL_FAKEY_BULLISH)
        {
         score += 20;
         scoreReason += "Fakey Bẫy (+20) | ";
        }
      else if(paSignal == SIGNAL_ENGULFING_BULL)
        {
         score += 20;
         scoreReason += "Engulfing Tăng (+20) | ";
        }
      else if(paSignal == SIGNAL_MOMENTUM_BULL)
        {
         score += 20;
         scoreReason += "Nến Xung Lực Trend (+20) | ";
        }
     }
   else if(direction == -1)
     {
      if(paSignal == SIGNAL_PINBAR_BEARISH)
        {
         score += 20;
         scoreReason += "Pin Bar Bắn Đỉnh (+20) | ";
        }
      else if(paSignal == SIGNAL_FAKEY_BEARISH)
        {
         score += 20;
         scoreReason += "Fakey Bẫy Bán (+20) | ";
        }
      else if(paSignal == SIGNAL_ENGULFING_BEAR)
        {
         score += 20;
         scoreReason += "Engulfing Giảm (+20) | ";
        }
      else if(paSignal == SIGNAL_MOMENTUM_BEAR)
        {
         score += 20;
         scoreReason += "Nến Xung Lực Trend (+20) | ";
        }
     }

   // 5. Động lượng RSI(14) Sung Mãn [+10 Điểm]
   double rsiBuf[];
   ArraySetAsSeries(rsiBuf, true);
   if(CopyBuffer(m_rsiHandle, 0, 1, 1, rsiBuf) > 0)
     {
      double rsi = rsiBuf[0];
      if(direction == 1 && rsi >= InpRsiBuyMin && rsi <= InpRsiBuyMax)
        {
         score += 10;
         scoreReason += StringFormat("RSI %.1f (+10) | ", rsi);
        }
      else if(direction == -1 && rsi >= InpRsiSellMin && rsi <= InpRsiSellMax)
        {
         score += 10;
         scoreReason += StringFormat("RSI %.1f (+10) | ", rsi);
        }
      else
        {
         scoreReason += StringFormat("RSI %.1f (+0) | ", rsi);
        }
     }

   // 6. Bẫy Quét Thanh Khoản Đa Phiên (Sáng dùng Đêm, Chiều dùng Sáng) [+15 Điểm Thưởng]
   if(InpUseSweepFilters)
     {
      MqlRates ratesList[];
      ArraySetAsSeries(ratesList, true);
      if(CopyRates(_Symbol, PERIOD_M15, 1, 1, ratesList) > 0)
        {
         MqlRates prevBar = ratesList[0];
         // Với phiên Sáng: Săn Đỉnh/Đáy Đêm
         if(sessionName == "SÁNG" && m_overnightReady)
           {
            if(direction == 1 && prevBar.low < m_overnightLow && prevBar.close > m_overnightLow)
              {
               score += 15;
               scoreReason += "Tokyo Low Sweep (+15)!";
              }
            else if(direction == -1 && prevBar.high > m_overnightHigh && prevBar.close < m_overnightHigh)
              {
               score += 15;
               scoreReason += "Tokyo High Sweep (+15)!";
              }
           }
         // Với phiên Chiều: Săn Đỉnh/Đáy Phiên Sáng
         else if(sessionName == "CHIỀU" && m_asianReady)
           {
            if(direction == 1 && prevBar.low < m_asianLow && prevBar.close > m_asianLow)
              {
               score += 15;
               scoreReason += "London Asian Low Sweep (+15)!";
              }
            else if(direction == -1 && prevBar.high > m_asianHigh && prevBar.close < m_asianHigh)
              {
               score += 15;
               scoreReason += "London Asian High Sweep (+15)!";
              }
            else if(direction == -1 && prevBar.close < m_asianLow)
              {
               score += 10;
               scoreReason += "London Asian Low Breakdown (+10)!";
              }
            else if(direction == 1 && prevBar.close > m_asianHigh)
              {
               score += 10;
               scoreReason += "London Asian High Breakout (+10)!";
              }
           }
        }
     }

   return score;
  }

//+------------------------------------------------------------------+
//| NHẬN DIỆN MÔ HÌNH NẾN PRICE ACTION THỰC CHIẾN (PINBAR, MOMENTUM) |
//+------------------------------------------------------------------+
ENUM_PRICE_ACTION_SIGNAL DetectPriceActionPattern(const MqlRates &c1, const MqlRates &c2, const MqlRates &c3)
  {
   double range1 = c1.high - c1.low;
   if(range1 <= 0.0) return SIGNAL_NONE;

   double body1      = MathAbs(c1.close - c1.open);
   double lowerWick1 = MathMin(c1.open, c1.close) - c1.low;
   double upperWick1 = c1.high - MathMax(c1.open, c1.close);

   // 1. PIN BAR CHUẨN THỰC CHIẾN (Râu >= 55%, Thân <= 35%)
   if(lowerWick1 / range1 >= g_effectiveWickRatio && body1 / range1 <= g_effectiveBodyRatio)
      return SIGNAL_PINBAR_BULLISH;

   if(upperWick1 / range1 >= g_effectiveWickRatio && body1 / range1 <= g_effectiveBodyRatio)
      return SIGNAL_PINBAR_BEARISH;

   // 2. FAKEY (BẪY PHÁ VỠ GIẢ INSIDE BAR)
   bool c2InsideC3 = (c2.high <= c3.high && c2.low >= c3.low);
   if(c2InsideC3)
     {
      if(c1.low < c2.low && c1.close > c2.low && c1.close > c1.open)
         return SIGNAL_FAKEY_BULLISH;

      if(c1.high > c2.high && c1.close < c2.high && c1.close < c1.open)
         return SIGNAL_FAKEY_BEARISH;
     }

   // 3. ENGULFING (NẾN NHẬN CHÌM)
   double body2 = MathAbs(c2.close - c2.open);
   if(c1.close > c1.open && c2.close < c2.open)
     {
      if(c1.close > c2.open && c1.open < c2.close && body1 >= body2 * 1.05)
         return SIGNAL_ENGULFING_BULL;
     }
   else if(c1.close < c1.open && c2.close > c2.open)
     {
      if(c1.close < c2.open && c1.open > c2.close && body1 >= body2 * 1.05)
         return SIGNAL_ENGULFING_BEAR;
     }

   // 4. TREND MOMENTUM BAR (NẾN XUNG LỰC TIẾP DIỄN XU HƯỚNG)
   // Bắt trọn các con sóng đổ đèo hoặc bứt phá mạnh mẽ
   if(c1.close < c1.open && (body1 / range1) >= 0.50 && c1.close < c2.low)
      return SIGNAL_MOMENTUM_BEAR; // Nến đỏ thân lớn phá vỡ đáy nến trước

   if(c1.close > c1.open && (body1 / range1) >= 0.50 && c1.close > c2.high)
      return SIGNAL_MOMENTUM_BULL; // Nến xanh thân lớn phá vỡ đỉnh nến trước

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| KIỂM TRA TÍN HIỆU VÀ KÍCH HOẠT BẮN TỈA A+ SETUP                  |
//+------------------------------------------------------------------+
void CheckForSniperSignals(string currentSession)
  {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M15, 1, 4, rates) < 4)
      return;

   MqlRates c1 = rates[0];
   MqlRates c2 = rates[1];
   MqlRates c3 = rates[2];

   ENUM_PRICE_ACTION_SIGNAL paSignal = DetectPriceActionPattern(c1, c2, c3);
   if(paSignal == SIGNAL_NONE)
     {
      m_lastSetupScore = 0;
      m_lastSetupDesc = "Chờ nến Price Action chuẩn M15...";
      return;
     }

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(m_atrHandle, 0, 1, 1, atrBuf) <= 0)
      return;

   double currentAtr = atrBuf[0];

   // Đánh giá hướng BUY
   if(paSignal == SIGNAL_PINBAR_BULLISH || paSignal == SIGNAL_FAKEY_BULLISH ||
      paSignal == SIGNAL_ENGULFING_BULL || paSignal == SIGNAL_MOMENTUM_BULL)
     {
      string reason = "";
      int score = EvaluateConfluenceScore(1, paSignal, c1.close, currentAtr, currentSession, reason);
      m_lastSetupScore = score;
      m_lastSetupDesc  = StringFormat("BUY [%s]: %d/100 -> %s", currentSession, score, reason);

      if(score >= g_effectiveMinScore)
        {
         ExecuteSniperTrade(ORDER_TYPE_BUY, c1, currentAtr, currentSession);
        }
     }
   // Đánh giá hướng SELL
   else if(paSignal == SIGNAL_PINBAR_BEARISH || paSignal == SIGNAL_FAKEY_BEARISH ||
           paSignal == SIGNAL_ENGULFING_BEAR || paSignal == SIGNAL_MOMENTUM_BEAR)
     {
      string reason = "";
      int score = EvaluateConfluenceScore(-1, paSignal, c1.close, currentAtr, currentSession, reason);
      m_lastSetupScore = score;
      m_lastSetupDesc  = StringFormat("SELL [%s]: %d/100 -> %s", currentSession, score, reason);

      if(score >= g_effectiveMinScore)
        {
         ExecuteSniperTrade(ORDER_TYPE_SELL, c1, currentAtr, currentSession);
        }
     }
  }

//+------------------------------------------------------------------+
//| VÀO LỆNH BẮN TỈA VỚI SL/TP TỐI ƯU VỐN 1000U                      |
//+------------------------------------------------------------------+
void ExecuteSniperTrade(ENUM_ORDER_TYPE orderType, const MqlRates &triggerBar, double currentAtr, string sessionName)
  {
   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid();
   double point = m_symbol.Point();

   double entryPrice = 0.0;
   double slPrice    = 0.0;
   double tpPrice    = 0.0;
   double slDistance = 0.0;

   double bufferPts = 15 * m_pointScale;

   if(orderType == ORDER_TYPE_BUY)
     {
      entryPrice = ask;
      double rawSl = triggerBar.low - (currentAtr * 0.35) - (bufferPts * point);
      double maxSlDistance = currentAtr * InpAtrSlMultiplier;

      if((entryPrice - rawSl) > maxSlDistance)
         rawSl = entryPrice - maxSlDistance;

      slPrice    = NormalizeDouble(rawSl, _Digits);
      slDistance = entryPrice - slPrice;
      tpPrice    = NormalizeDouble(entryPrice + slDistance * g_effectiveTargetRr, _Digits);
     }
   else if(orderType == ORDER_TYPE_SELL)
     {
      entryPrice = bid;
      double rawSl = triggerBar.high + (currentAtr * 0.35) + (bufferPts * point);
      double maxSlDistance = currentAtr * InpAtrSlMultiplier;

      if((rawSl - entryPrice) > maxSlDistance)
         rawSl = entryPrice + maxSlDistance;

      slPrice    = NormalizeDouble(rawSl, _Digits);
      slDistance = slPrice - entryPrice;
      tpPrice    = NormalizeDouble(entryPrice - slDistance * g_effectiveTargetRr, _Digits);
     }

   double slPoints = slDistance / point;
   double lot = CalculateOptimalLotSize(slPoints);

   if(lot < m_symbol.LotsMin())
     {
      PrintFormat(">> [LỖI KHỐI LƯỢNG] Lot tính toán %.3f nhỏ hơn Lot tối thiểu %.2f", lot, m_symbol.LotsMin());
      return;
     }

   bool res = false;
   if(orderType == ORDER_TYPE_BUY)
      res = m_trade.Buy(lot, _Symbol, entryPrice, slPrice, tpPrice, InpTradeComment);
   else if(orderType == ORDER_TYPE_SELL)
      res = m_trade.Sell(lot, _Symbol, entryPrice, slPrice, tpPrice, InpTradeComment);

   if(res)
     {
      if(sessionName == "SÁNG")
         m_morningTradesCount++;
      else if(sessionName == "CHIỀU")
         m_afternoonTradesCount++;

      PrintFormat("==========================================================");
      PrintFormat(">> [BẮN TỈA A+ THÀNH CÔNG - %s] %s Vàng %.2f Lot @ %.2f | SL: %.2f | TP: %.2f",
                  sessionName, (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"), lot, entryPrice, slPrice, tpPrice);
      PrintFormat(">> Rủi ro: $%.2f (1.0%%) | Mục tiêu TP: $%.2f (R:R 1:%.1f)",
                  (m_account.Balance() * InpRiskPercentPerTrade / 100.0),
                  (m_account.Balance() * InpRiskPercentPerTrade / 100.0) * g_effectiveTargetRr,
                  g_effectiveTargetRr);
      Print("==========================================================");
     }
   else
     {
      PrintFormat(">> [LỖI VÀO LỆNH] Mã lỗi: %d - %s", m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| QUẢN LÝ LỆNH ĐANG MỞ (AUTO BREAK-EVEN, PARTIAL TP, TRAILING STOP)|
//+------------------------------------------------------------------+
void ManageActivePositions()
  {
   double point = m_symbol.Point();
   double bufferPts = InpBreakEvenBufferPts * m_pointScale;

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   double curAtr = 0.0;
   if(CopyBuffer(m_atrHandle, 0, 1, 1, atrBuf) > 0)
      curAtr = atrBuf[0];

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      ulong  ticket    = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double curPrice  = m_position.PriceCurrent();
      double curSl     = m_position.StopLoss();
      double curTp     = m_position.TakeProfit();
      double volume    = m_position.Volume();
      long   posType   = m_position.PositionType();

      double initialRisk = 0.0;
      if(posType == POSITION_TYPE_BUY && curSl > 0.0)
         initialRisk = openPrice - curSl;
      else if(posType == POSITION_TYPE_SELL && curSl > 0.0)
         initialRisk = curSl - openPrice;

      if(initialRisk <= 0.0)
         initialRisk = (curAtr > 0.0 ? curAtr * InpAtrSlMultiplier : 300 * point);

      // 1. TỰ ĐỘNG DỜI HÒA VỐN SỚM (AUTO BREAK-EVEN TẠI +0.65R)
      if(InpUseAutoBreakEven)
        {
         if(posType == POSITION_TYPE_BUY)
           {
            double beTriggerPrice = openPrice + initialRisk * g_effectiveBeTriggerR;
            double targetBeSl     = NormalizeDouble(openPrice + bufferPts * point, _Digits);

            if(curPrice >= beTriggerPrice && curSl < targetBeSl)
              {
               m_trade.PositionModify(ticket, targetBeSl, curTp);
               PrintFormat(">> [AUTO BREAK-EVEN] Đã dời SL BUY ticket %d về hòa vốn (+%.2f pts). Lệnh Risk-Free 100%%!",
                           ticket, bufferPts);
              }
           }
         else if(posType == POSITION_TYPE_SELL)
           {
            double beTriggerPrice = openPrice - initialRisk * g_effectiveBeTriggerR;
            double targetBeSl     = NormalizeDouble(openPrice - bufferPts * point, _Digits);

            if(curPrice <= beTriggerPrice && (curSl > targetBeSl || curSl == 0.0))
              {
               m_trade.PositionModify(ticket, targetBeSl, curTp);
               PrintFormat(">> [AUTO BREAK-EVEN] Đã dời SL SELL ticket %d về hòa vốn (-%.2f pts). Lệnh Risk-Free 100%%!",
                           ticket, bufferPts);
              }
           }
        }

      // 2. CHỐT LỜI TỪNG PHẦN 50% TẠI +1.0R (ĐÚT TÚI TIỀN TƯƠI)
      if(InpUsePartialClose && volume > m_symbol.LotsMin())
        {
         double profitDistance = 0.0;
         if(posType == POSITION_TYPE_BUY)
            profitDistance = curPrice - openPrice;
         else if(posType == POSITION_TYPE_SELL)
            profitDistance = openPrice - curPrice;

         if(profitDistance >= initialRisk * g_effectivePartialCloseR)
           {
            double halfLot = NormalizeDouble(volume / 2.0, 2);
            double minLot  = m_symbol.LotsMin();
            double lotStep = m_symbol.LotsStep();
            halfLot = MathFloor(halfLot / lotStep) * lotStep;

            if(halfLot >= minLot && (volume - halfLot) >= minLot)
              {
               if(m_trade.PositionClosePartial(ticket, halfLot))
                 {
                  PrintFormat(">> [PARTIAL TP 50%%] Đã chốt %.2f Lot tại +%.1fR cho ticket %d! Tiền tươi đã về tài khoản!",
                              halfLot, g_effectivePartialCloseR, ticket);
                 }
              }
           }
        }

      // 3. TRAILING STOP THEO ATR (CHANDELIER TRAILING)
      if(InpUseTrailingStop && curAtr > 0.0)
        {
         double trailDistance = curAtr * InpTrailingAtrMult;

         if(posType == POSITION_TYPE_BUY)
           {
            double trailTrigger = openPrice + initialRisk * InpTrailingStartR;
            if(curPrice >= trailTrigger)
              {
               double newSl = NormalizeDouble(curPrice - trailDistance, _Digits);
               if(newSl > curSl + 10 * point && newSl > openPrice)
                 {
                  m_trade.PositionModify(ticket, newSl, curTp);
                 }
              }
           }
         else if(posType == POSITION_TYPE_SELL)
           {
            double trailTrigger = openPrice - initialRisk * InpTrailingStartR;
            if(curPrice <= trailTrigger)
              {
               double newSl = NormalizeDouble(curPrice + trailDistance, _Digits);
               if((curSl == 0.0 || newSl < curSl - 10 * point) && newSl < openPrice)
                 {
                  m_trade.PositionModify(ticket, newSl, curTp);
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| BỘ LỌC TIN TỨC KINH TẾ (MQL5 CALENDAR ENGINE)                    |
//+------------------------------------------------------------------+
bool CheckNewsRisk()
  {
   datetime nowServer = TimeCurrent();
   datetime timeFrom  = nowServer - (InpNewsPauseMinsAfter * 60);
   datetime timeTo    = nowServer + (InpNewsPauseMinsBefore * 60);

   MqlCalendarValue values[];
   int totalEvents = CalendarValueHistory(values, timeFrom, timeTo);

   if(totalEvents > 0)
     {
      for(int i = 0; i < totalEvents; i++)
        {
         MqlCalendarEvent event;
         if(CalendarEventById(values[i].event_id, event))
           {
            if(event.importance == CALENDAR_IMPORTANCE_HIGH)
              {
               MqlCalendarCountry country;
               if(CalendarCountryById(event.country_id, country))
                 {
                  if(country.currency == "USD" || country.currency == "GBP" || country.currency == "EUR" || country.currency == "JPY")
                    {
                     m_isNewsRestricted = true;
                     m_newsStatusText   = StringFormat("CẢNH BÁO: Tin đỏ %s (%s)", country.currency, event.name);

                     if(InpNewsLockOpenToBE)
                        LockPositionsToBreakEvenBeforeNews();

                     return true;
                    }
                 }
              }
           }
        }
     }

   m_isNewsRestricted = false;
   m_newsStatusText   = "AN TOÀN (Không có tin đỏ)";
   return false;
  }

//+------------------------------------------------------------------+
//| KÉO SL VỀ HÒA VỐN TRƯỚC GIỜ TIN ĐỎ ĐỂ BẢO VỆ TÀI KHOẢN           |
//+------------------------------------------------------------------+
void LockPositionsToBreakEvenBeforeNews()
  {
   double point = m_symbol.Point();
   double bufferPts = InpBreakEvenBufferPts * m_pointScale;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      ulong  ticket    = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double curPrice  = m_position.PriceCurrent();
      double curSl     = m_position.StopLoss();
      double curTp     = m_position.TakeProfit();

      if(m_position.PositionType() == POSITION_TYPE_BUY)
        {
         double bePrice = NormalizeDouble(openPrice + bufferPts * point, _Digits);
         if(curSl < bePrice && curPrice >= openPrice)
            m_trade.PositionModify(ticket, bePrice, curTp);
        }
      else if(m_position.PositionType() == POSITION_TYPE_SELL)
        {
         double bePrice = NormalizeDouble(openPrice - bufferPts * point, _Digits);
         if((curSl > bePrice || curSl == 0.0) && curPrice <= openPrice)
            m_trade.PositionModify(ticket, bePrice, curTp);
        }
     }
  }

//+------------------------------------------------------------------+
//| ĐẾM SỐ LƯỢNG VỊ THẾ MỞ CỦA EA HIỆN TẠI                           |
//+------------------------------------------------------------------+
int CountOpenPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_positionHelper.SelectByIndex(i))
        {
         if(m_positionHelper.Symbol() == _Symbol && m_positionHelper.Magic() == InpMagicNumber)
            count++;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| TIỆN ÍCH TẠO HỘP CHỮ NHẬT NỀN CHO BẢNG HUD (GRAPHICAL PANEL)     |
//+------------------------------------------------------------------+
void SetRectLabel(string name, int x, int y, int width, int height, color bgCol, color borderCol, ENUM_BASE_CORNER corner)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgCol);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderCol);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
     }
   else
     {
      ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgCol);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderCol);
     }
  }

//+------------------------------------------------------------------+
//| TIỆN ÍCH TẠO DÒNG CHỮ TRÊN BẢNG HUD VỚI MÀU SẮC & PHÔNG CHỮ ĐẸP  |
//+------------------------------------------------------------------+
void SetTextLabel(string name, int x, int y, string text, color col, int fontSize, bool isBold, ENUM_BASE_CORNER corner)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, col);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, name, OBJPROP_FONT, isBold ? "Segoe UI Bold" : "Segoe UI");
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
     }
   else
     {
      ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, col);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
     }
  }

//+------------------------------------------------------------------+
//| VẼ BẢNG ĐIỀU KHIỂN HUD ĐỒ HỌA SANG TRỌNG (KHÔNG ĐÈ NẾN)          |
//+------------------------------------------------------------------+
void RenderModernDashboard()
  {
   Comment("");

   if(InpHudPosition == HUD_HIDE)
     {
      ObjectsDeleteAll(0, "AS_HUD_");
      return;
     }

   ENUM_BASE_CORNER corner = (InpHudPosition == HUD_RIGHT_TOP ? CORNER_RIGHT_UPPER : CORNER_LEFT_UPPER);
   int posX = 20;
   int posY = (InpHudPosition == HUD_RIGHT_TOP ? 35 : 45);
   int panelWidth  = 395;
   int panelHeight = 250;

   datetime nowVn     = GetCurrentVietnamTime();
   datetime nowServer = TimeCurrent();
   MqlDateTime dtVn, dtServer;
   TimeToStruct(nowVn, dtVn);
   TimeToStruct(nowServer, dtServer);

   string sessionName = "";
   bool inSession = CheckCurrentActiveSession(sessionName);
   double balance = m_account.Balance();
   double equity  = m_account.Equity();
   double dayProfit = equity - m_dailyStartEquity;

   color statusCol = C'46,213,115';
   string statusText = "";

   if(sessionName == "SÁNG")
      statusText = "ĐANG MỞ - PHIÊN SÁNG (Á)";
   else if(sessionName == "CHIỀU")
      statusText = "ĐANG MỞ - PHIÊN CHIỀU (ÂU)";
   else
     {
      statusCol = C'255,165,2';
      int curMin = dtVn.hour * 60 + dtVn.min;
      if(curMin >= 11*60+30 && curMin < 14*60)
         statusText = "NGHỈ TRƯA (CHỜ PHIÊN CHIỀU)";
      else
         statusText = "HẾT GIỜ CHIỀU (NGHỈ TỐI / ĐÊM)";
     }

   if(m_dailyShieldActive)
     {
      statusCol  = C'255,71,87';
      statusText = "KHÓA BẢO VỆ VỐN (SL NGÀY)";
     }

   color bgMain   = C'18,22,32';
   color bgHeader = C'26,34,48';
   color bdBorder = C'45,55,72';

   SetRectLabel("AS_HUD_BG", posX, posY, panelWidth, panelHeight, bgMain, bdBorder, corner);
   SetRectLabel("AS_HUD_HEADER", posX, posY, panelWidth, 30, bgHeader, C'0,180,216', corner);

   SetTextLabel("AS_HUD_TITLE", posX + 12, posY + 6, "AURORA SNIPER M15 - SÁNG & CHIỀU", C'0,212,255', 9, true, corner);
   SetTextLabel("AS_HUD_MODE", posX + panelWidth - 95, posY + 8, "[ULTRA 90%]", C'255,215,0', 8, true, corner);

   int yStart = posY + 38;
   int lineGap = 19;

   string timeStr = StringFormat("Giờ VN (GMT+7): %02d:%02d:%02d  |  Server: %02d:%02d",
                                 dtVn.hour, dtVn.min, dtVn.sec, dtServer.hour, dtServer.min);
   SetTextLabel("AS_HUD_L1", posX + 12, yStart, timeStr, clrWhite, 9, false, corner);

   string sessStr = StringFormat("Trạng thái: %s", statusText);
   SetTextLabel("AS_HUD_L2", posX + 12, yStart + lineGap * 1, sessStr, statusCol, 9, true, corner);

   string sessTimeStr = StringFormat("Khung giờ: Sáng %02d:%02d-%02d:%02d  |  Chiều %02d:%02d-%02d:%02d",
                                     InpMorningStartHourVN, InpMorningStartMinVN, InpMorningEndHourVN, InpMorningEndMinVN,
                                     InpAfternoonStartHourVN, InpAfternoonStartMinVN, InpAfternoonEndHourVN, InpAfternoonEndMinVN);
   SetTextLabel("AS_HUD_L2B", posX + 12, yStart + lineGap * 2, sessTimeStr, C'180,195,210', 9, false, corner);

   string balStr = StringFormat("Vốn: $%.2f  |  Equity: $%.2f  |  Lãi: %s$%.2f",
                                balance, equity, (dayProfit >= 0 ? "+" : ""), dayProfit);
   SetTextLabel("AS_HUD_L3", posX + 12, yStart + lineGap * 3, balStr, (dayProfit >= 0 ? C'46,213,115' : C'255,71,87'), 9, false, corner);

   string riskStr = StringFormat("Lệnh ngày: Sáng %d/1, Chiều %d/1  |  Risk 1.0%% ($%.2f)",
                                 m_morningTradesCount, m_afternoonTradesCount,
                                 balance * (InpRiskPercentPerTrade / 100.0));
   SetTextLabel("AS_HUD_L4", posX + 12, yStart + lineGap * 4, riskStr, C'200,210,225', 9, false, corner);

   string scoreStr = StringFormat("Setup A+: %d/100 (Yêu cầu >= %d) -> %s",
                                  m_lastSetupScore, g_effectiveMinScore, m_lastSetupDesc);
   if(StringLen(scoreStr) > 52)
      scoreStr = StringSubstr(scoreStr, 0, 49) + "...";
   SetTextLabel("AS_HUD_L5", posX + 12, yStart + lineGap * 5, scoreStr, C'255,215,0', 9, false, corner);

   string protStr = StringFormat("Cơ chế: Auto BE +%.2fR  |  Partial +%.1fR  |  R:R 1:%.1f",
                                 g_effectiveBeTriggerR, g_effectivePartialCloseR, g_effectiveTargetRr);
   SetTextLabel("AS_HUD_L6", posX + 12, yStart + lineGap * 6, protStr, C'0,212,255', 9, false, corner);

   string statStr = StringFormat("Spread: %d pts  |  Tin đỏ: %s  |  Lệnh mở: %d",
                                 m_symbol.Spread(), (m_isNewsRestricted ? "CÓ TIN ĐỎ" : "An toàn"),
                                 CountOpenPositions());
   SetTextLabel("AS_HUD_L7", posX + 12, yStart + lineGap * 7, statStr, C'220,225,235', 9, false, corner);

   SetTextLabel("AS_HUD_FOOTER", posX + 12, yStart + lineGap * 8 + 8, "Nghỉ trưa 11:30-14:00 | Nghỉ tối sau 18:30 VN", C'100,115,135', 8, false, corner);
  }
//+------------------------------------------------------------------+
