//+------------------------------------------------------------------+
//|                                     NocturnalSniper_1000U_EA.mq5 |
//|          XẠ THỦ PHIÊN TỐI - HỆ THỐNG GIAO DỊCH VÀNG VỐN 1000$     |
//|        Tối Ưu Tỷ Lệ Thắng Cao Nhất | Chờ Điểm Đẹp Mới Vào Lệnh   |
//|               Bản Quyền 2026 - Tinh Hoa Price Action & SMC       |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Antigravity Institutional Trading"
#property link        "https://github.com"
#property version     "5.20"
#property description "NOCTURNAL SNIPER EA - Chuyen Biet Khung Gio Toi Cho VANG (XAUUSD)"
#property description "Ho tro cau hinh truc tiep theo GIO VIET NAM (GMT+7, tu 19h toi)"
#property description "Ket Hop: Nial Fuller Naked Action + FX Academy DBB + SMC Asian Sweep"
#property description "Quan Ly Von 1000u: Risk 1.0%, Partial Close 50%, Auto Break-Even & Chot Lenh Trong Toi"
#property strict

//--- Thu vien Trade MQL5 chuan
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS & STRUCTURES                                               |
//+------------------------------------------------------------------+
enum ENUM_EVENING_FINISH_MODE
  {
   FINISH_CLOSE_PROFIT_LOCK_BE = 0, // Chot sach lenh loi, dua lenh con lai ve hoa von (Khuyen nghi)
   FINISH_CLOSE_ALL_POSITIONS  = 1, // Dong toan bo moi vi the dung gio ket thuc (Ve 100% tien mat)
   FINISH_STOP_NEW_ONLY        = 2  // Chi dung mo lenh moi, de cac vi the tu dong cham TP/SL
  };

enum ENUM_PRICE_ACTION_SIGNAL
  {
   SIGNAL_NONE             = 0,
   SIGNAL_PINBAR_BULLISH   = 1,
   SIGNAL_PINBAR_BEARISH   = 2,
   SIGNAL_FAKEY_BULLISH    = 3,
   SIGNAL_FAKEY_BEARISH    = 4,
   SIGNAL_ENGULFING_BULL   = 5,
   SIGNAL_ENGULFING_BEAR   = 6
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS (THIẾT LẬP THAM SỐ ĐẦU VÀO)                     |
//+------------------------------------------------------------------+
input group "=== 1. THIẾT LẬP PHIÊN TỐI THEO GIỜ VIỆT NAM (GMT+7) ==="
input bool                      InpUseEveningFilter      = true;         // Bật bộ lọc phiên tối
input bool                      InpUseVietnamTime        = true;         // Dùng Giờ Việt Nam GMT+7 (True = Giờ VN, False = Giờ Server)
input int                       InpEveningStartHourVN    = 19;           // Giờ VN BẮT ĐẦU phiên tối (19:00 VN)
input int                       InpEveningStartMinVN     = 0;            // Phút VN bắt đầu (00)
input int                       InpEveningEndHourVN      = 23;           // Giờ VN DỪNG mở lệnh mới (23:30 VN)
input int                       InpEveningEndMinVN       = 30;           // Phút VN dừng mở lệnh mới (30)
input int                       InpForceCloseHourVN      = 2;            // Giờ VN CHỐT DỨT ĐIỂM phiên tối (02:00 sáng hôm sau VN)
input int                       InpForceCloseMinVN       = 0;            // Phút VN chốt dứt điểm (00)
input ENUM_EVENING_FINISH_MODE  InpSessionFinishMode     = FINISH_CLOSE_PROFIT_LOCK_BE; // Cơ chế xử lý khi hết giờ tối

input group "=== 2. QUẢN TRỊ VỐN CHUẨN 1000U (RISK MANAGEMENT) ==="
input double                    InpBaseCapital           = 1000.0;       // Mức vốn mục tiêu (USD)
input double                    InpRiskPercentPerTrade   = 1.0;          // % Rủi ro mỗi lệnh (1.0% = $10 / lệnh cho 1000u)
input double                    InpMaxLotAllowed         = 0.10;         // Khối lượng Lot trần tối đa an toàn
input int                       InpMaxTradesPerNight     = 2;            // Số lệnh tối đa mỗi buổi tối (Sniper Mindset)
input int                       InpMaxConcurrentPositions= 1;            // Số lệnh mở đồng thời tối đa (1 lệnh duy nhất)
input double                    InpMaxDailyDrawdownPct   = 3.0;          // Giới hạn sụt giảm tối đa trong ngày (3.0% = $30)
input int                       InpMaxSpreadPoints       = 350;          // Spread tối đa cho Vàng (350 pts chuẩn cho Exness/IC Markets)

input group "=== 3. CHỈ SỐ LỌC ĐIỂM ĐẸP (CONFLUENCE SETUP FILTERS) ==="
input int                       InpMinConfluenceScore    = 85;           // Điểm số tối thiểu để bắn tỉa (85/100: A+ Setup)
input bool                      InpUseHtfTrendFilter     = true;         // Bật lọc xu hướng vĩ mô H1
input ENUM_TIMEFRAMES           InpHtfTimeframe          = PERIOD_H1;    // Khung thời gian xu hướng vĩ mô
input int                       InpHtfFastEma            = 21;           // EMA 21 trên H1 (Dynamic Value Area)
input int                       InpHtfSlowEma            = 50;           // EMA 50 trên H1 (Baseline Trend)
input int                       InpDbbPeriod             = 20;           // Chu kỳ Double Bollinger Bands (M15)
input double                    InpDbbDevOuter           = 2.0;          // Độ lệch chuẩn ngoài (+2.0 SD)
input double                    InpDbbDevInner           = 1.0;          // Độ lệch chuẩn trong (+1.0 SD)
input int                       InpRsiPeriod             = 14;           // Chu kỳ RSI (Lọc động lượng)
input double                    InpRsiBuyMin             = 45.0;         // RSI tối thiểu để BUY
input double                    InpRsiBuyMax             = 68.0;         // RSI tối đa để BUY (Tránh đu đỉnh quá mua)
input double                    InpRsiSellMin            = 32.0;         // RSI tối thiểu để SELL (Tránh bán đáy quá bán)
input double                    InpRsiSellMax            = 55.0;         // RSI tối đa để SELL

input group "=== 4. QUY TẮC NẾN PRICE ACTION & QUÉT THANH KHOẢN ==="
input double                    InpMinPinBarWickRatio    = 0.65;         // Tỷ lệ râu nến Pin Bar tối thiểu (65%)
input double                    InpMaxPinBarBodyRatio    = 0.30;         // Tỷ lệ thân nến Pin Bar tối đa (30%)
input bool                      InpUseAsianSweepFilter   = true;         // Tích hợp bẫy thanh khoản phiên Á (Asian Sweep)
input int                       InpAsianStartHour        = 0;            // Giờ bắt đầu phiên Á (Server)
input int                       InpAsianEndHour          = 8;            // Giờ kết thúc phiên Á (Server)

input group "=== 5. STOP LOSS & CHỐT LỜI CAO CẤP (HIGH WINRATE ENGINE) ==="
input int                       InpAtrPeriod             = 14;           // Chu kỳ ATR đo biến động nến M15
input double                    InpAtrSlMultiplier       = 1.5;          // Hệ số nhân ATR cho Stop Loss động
input double                    InpTargetRrRatio         = 2.2;          // Tỷ lệ R:R mục tiêu hoàn tất (1:2.2)
input bool                      InpUsePartialClose       = true;         // Kích hoạt chốt lời từng phần 50%
input double                    InpPartialCloseRatioR    = 1.2;          // Chốt 50% khối lượng khi đạt 1.2R (Đút túi tiền lãi)
input bool                      InpUseAutoBreakEven      = true;         // Tự động dời Stop Loss về hòa vốn (Risk-Free)
input double                    InpBreakEvenTriggerR     = 0.8;          // Kích hoạt hòa vốn khi giá chạy được 0.8R
input int                       InpBreakEvenBufferPts    = 20;           // Đệm cộng thêm để bù spread & swap (Points)
input bool                      InpUseTrailingStop       = true;         // Kích hoạt Trailing Stop ATR sau khi chốt 50%
input double                    InpTrailingStartR        = 1.4;          // Kích hoạt Trailing khi giá vượt 1.4R
input double                    InpTrailingAtrMult       = 1.2;          // Khoảng cách Trailing Stop (x ATR)

input group "=== 6. BẢO VỆ TIN TỨC & CHỐNG SỐC BIẾN ĐỘNG ==="
input bool                      InpUseNewsFilter         = true;         // Bật lọc tin tức kinh tế MQL5 Calendar
input int                       InpNewsPauseMinsBefore   = 30;           // Dừng mở lệnh trước tin đỏ USD (phút)
input int                       InpNewsPauseMinsAfter    = 30;           // Dừng mở lệnh sau tin đỏ USD (phút)
input bool                      InpNewsLockOpenToBE      = true;         // Tự kéo SL về hòa vốn nếu có lệnh trước tin
input double                    InpVolSpikeThreshold     = 1.8;          // Ngưỡng phát hiện sốc biến động (ATR 3 / ATR 30)

input group "=== 7. HỆ THỐNG GIAO DIỆN & CẤU HÌNH HỆ THỐNG ==="
input ulong                     InpMagicNumber           = 8882026;      // Magic Number định danh
input string                    InpTradeComment          = "Nocturnal_1000U"; // Ghi chú lệnh
input ulong                     InpSlippage              = 30;           // Độ trượt giá tối đa (Points)
input bool                      InpShowDashboard         = true;         // Hiển thị HUD Dashboard trên Chart

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & HANDLES                                         |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;
CPositionInfo  m_positionHelper;
CAccountInfo   m_account;
CSymbolInfo    m_symbol;

int            m_htfFastEmaHandle  = INVALID_HANDLE;
int            m_htfSlowEmaHandle  = INVALID_HANDLE;
int            m_bbOuterHandle     = INVALID_HANDLE;
int            m_bbInnerHandle     = INVALID_HANDLE;
int            m_rsiHandle         = INVALID_HANDLE;
int            m_atrHandle         = INVALID_HANDLE;
int            m_atrFastHandle     = INVALID_HANDLE;
int            m_atrSlowHandle     = INVALID_HANDLE;

datetime       m_lastBarTime       = 0;
datetime       m_dailyResetDate    = 0;
double         m_dailyStartEquity  = 0.0;
bool           m_dailyShieldActive = false;
int            m_nightTradesTaken  = 0;
datetime       m_lastNightDate     = 0;

int            m_pointScale        = 1;

double         m_asianHigh         = 0.0;
double         m_asianLow          = 0.0;
bool           m_asianRangeReady   = false;
datetime       m_asianDate         = 0;

string         m_newsStatusText    = "SAFE (Không có tin đỏ USD)";
bool           m_isNewsRestricted  = false;
string         m_volatilityText    = "BÌNH THƯỜNG (1.0x)";
bool           m_isVolShocked      = false;
double         m_currentVolRatio   = 1.0;
int            m_lastSetupScore    = 0;
string         m_lastSetupDesc     = "Đang chờ tín hiệu A+...";

//+------------------------------------------------------------------+
//| HÀM LẤY GIỜ VIỆT NAM GMT+7 CHUẨN XÁC 100%                        |
//+------------------------------------------------------------------+
datetime GetCurrentVietnamTime()
  {
   if(InpUseVietnamTime)
     {
      datetime gmt = TimeGMT();
      if(gmt > 0)
         return (gmt + 7 * 3600);
      return TimeLocal();
     }
   return TimeCurrent();
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

   // 1. Khởi tạo HTF Trend H1
   if(InpUseHtfTrendFilter)
     {
      m_htfFastEmaHandle = iMA(_Symbol, InpHtfTimeframe, InpHtfFastEma, 0, MODE_EMA, PRICE_CLOSE);
      m_htfSlowEmaHandle = iMA(_Symbol, InpHtfTimeframe, InpHtfSlowEma, 0, MODE_EMA, PRICE_CLOSE);
      if(m_htfFastEmaHandle == INVALID_HANDLE || m_htfSlowEmaHandle == INVALID_HANDLE)
        {
         Print("Lỗi tạo handle HTF EMA!");
         return INIT_FAILED;
        }
     }

   // 2. Khởi tạo Double Bollinger Bands M15
   m_bbOuterHandle = iBands(_Symbol, PERIOD_CURRENT, InpDbbPeriod, 0, InpDbbDevOuter, PRICE_CLOSE);
   m_bbInnerHandle = iBands(_Symbol, PERIOD_CURRENT, InpDbbPeriod, 0, InpDbbDevInner, PRICE_CLOSE);
   if(m_bbOuterHandle == INVALID_HANDLE || m_bbInnerHandle == INVALID_HANDLE)
     {
      Print("Lỗi tạo handle Double Bollinger Bands!");
      return INIT_FAILED;
     }

   // 3. Khởi tạo RSI & ATR
   m_rsiHandle     = iRSI(_Symbol, PERIOD_CURRENT, InpRsiPeriod, PRICE_CLOSE);
   m_atrHandle     = iATR(_Symbol, PERIOD_CURRENT, InpAtrPeriod);
   m_atrFastHandle = iATR(_Symbol, PERIOD_CURRENT, 3);
   m_atrSlowHandle = iATR(_Symbol, PERIOD_CURRENT, 30);
   if(m_rsiHandle == INVALID_HANDLE || m_atrHandle == INVALID_HANDLE ||
      m_atrFastHandle == INVALID_HANDLE || m_atrSlowHandle == INVALID_HANDLE)
     {
      Print("Lỗi tạo handle RSI hoặc ATR!");
      return INIT_FAILED;
     }

   m_dailyStartEquity = m_account.Equity();
   m_dailyResetDate   = iTime(_Symbol, PERIOD_D1, 0);

   Print("=== NOCTURNAL SNIPER 1000U KHỞI CHẠY THÀNH CÔNG ===");
   PrintFormat("Biểu tượng: %s (Digits: %d) | Vốn: $%.2f | Chế độ Giờ VN: %s (Bắt đầu: %02d:%02d VN)",
               _Symbol, _Digits, m_account.Balance(), InpUseVietnamTime ? "BẬT" : "TẮT", InpEveningStartHourVN, InpEveningStartMinVN);

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(m_htfFastEmaHandle != INVALID_HANDLE) IndicatorRelease(m_htfFastEmaHandle);
   if(m_htfSlowEmaHandle != INVALID_HANDLE) IndicatorRelease(m_htfSlowEmaHandle);
   if(m_bbOuterHandle    != INVALID_HANDLE) IndicatorRelease(m_bbOuterHandle);
   if(m_bbInnerHandle    != INVALID_HANDLE) IndicatorRelease(m_bbInnerHandle);
   if(m_rsiHandle        != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
   if(m_atrHandle        != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
   if(m_atrFastHandle    != INVALID_HANDLE) IndicatorRelease(m_atrFastHandle);
   if(m_atrSlowHandle    != INVALID_HANDLE) IndicatorRelease(m_atrSlowHandle);

   ObjectsDeleteAll(0, "NS_");
   Comment("");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   m_symbol.RefreshRates();

   // 1. Quản lý sụt giảm ngày
   CheckDailyResetAndShield();

   // 2. Cập nhật tin tức MQL5 Calendar
   UpdateNewsAndVolatilityStatus();

   // 3. Quản lý các lệnh đang mở (BE, Partial 50%, Trailing)
   ManageOpenPositions();

   // 4. Cơ chế chốt phiên tối
   ProcessEveningSessionFinish();

   // 5. Kiểm tra nến M15 đóng cửa để quét A+ Setup
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime != m_lastBarTime)
     {
      m_lastBarTime = currentBarTime;
      UpdateAsianRange();
      EvaluateAndExecuteSniperSetup();
     }

   // 6. Cập nhật giao diện HUD Dashboard
   if(InpShowDashboard)
     {
      RenderDashboard();
     }
  }

//+------------------------------------------------------------------+
//| KIỂM SOÁT RESET NGÀY VÀ LÁ CHẮN SỤT GIẢM (DAILY DRAWDOWN GUARD)  |
//+------------------------------------------------------------------+
void CheckDailyResetAndShield()
  {
   datetime todayD1 = iTime(_Symbol, PERIOD_D1, 0);
   if(todayD1 != m_dailyResetDate)
     {
      m_dailyResetDate    = todayD1;
      m_dailyStartEquity  = m_account.Equity();
      m_dailyShieldActive = false;
      m_nightTradesTaken  = 0;
      Print(">> [NGÀY MỚI] Reset Daily Shield. Vốn đầu ngày: $", DoubleToString(m_dailyStartEquity, 2));
     }

   double currentEquity = m_account.Equity();
   if(m_dailyStartEquity > 0.0)
     {
      double lossAmount = m_dailyStartEquity - currentEquity;
      double lossPercent = (lossAmount / m_dailyStartEquity) * 100.0;
      if(lossPercent >= InpMaxDailyDrawdownPct && !m_dailyShieldActive)
        {
         m_dailyShieldActive = true;
         PrintFormat(">> [DAILY SHIELD KÍCH HOẠT] Đã chạm giới hạn sụt giảm: -%.2f%% (-$%.2f). DỪNG TRADE HÔM NAY!", lossPercent, lossAmount);
        }
     }
  }

//+------------------------------------------------------------------+
//| CẬP NHẬT BIÊN ĐỘ PHIÊN Á (ASIAN RANGE 00:00 - 08:00 SERVER)      |
//+------------------------------------------------------------------+
void UpdateAsianRange()
  {
   if(!InpUseAsianSweepFilter) return;

   datetime todayD1 = iTime(_Symbol, PERIOD_D1, 0);
   if(todayD1 != m_asianDate)
     {
      m_asianDate       = todayD1;
      m_asianRangeReady = false;
      m_asianHigh       = 0.0;
      m_asianLow        = 0.0;
     }

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.hour >= InpAsianEndHour && !m_asianRangeReady)
     {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      int barsNeeded = 24 * 4;
      int copied = CopyRates(_Symbol, PERIOD_M15, 0, barsNeeded, rates);
      if(copied > 0)
        {
         double highest = -1.0;
         double lowest  = 999999.0;
         bool found = false;

         for(int i = 0; i < copied; i++)
           {
            MqlDateTime barDt;
            TimeToStruct(rates[i].time, barDt);
            if(barDt.day == dt.day && barDt.hour >= InpAsianStartHour && barDt.hour < InpAsianEndHour)
              {
               if(rates[i].high > highest) highest = rates[i].high;
               if(rates[i].low < lowest)   lowest  = rates[i].low;
               found = true;
              }
           }

         if(found && highest > 0.0 && lowest < 999999.0)
           {
            m_asianHigh       = highest;
            m_asianLow        = lowest;
            m_asianRangeReady = true;
            PrintFormat(">> [ASIAN RANGE XÁC LẬP] High: %.3f | Low: %.3f", m_asianHigh, m_asianLow);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| CẬP NHẬT TIN TỨC VĨ MÔ & ĐO LƯỜNG SỐC BIẾN ĐỘNG                  |
//+------------------------------------------------------------------+
void UpdateNewsAndVolatilityStatus()
  {
   m_isNewsRestricted = false;
   m_newsStatusText   = "SAFE (Không có tin đỏ USD)";

   if(InpUseNewsFilter)
     {
      datetime now = TimeCurrent();
      datetime fromTime = now - (InpNewsPauseMinsAfter * 60);
      datetime toTime   = now + (InpNewsPauseMinsBefore * 60);

      MqlCalendarValue values[];
      int totalEvents = CalendarValueHistory(values, fromTime, toTime, NULL, "USD");
      for(int i = 0; i < totalEvents; i++)
        {
         MqlCalendarEvent event;
         if(CalendarEventById(values[i].event_id, event))
           {
            if(event.importance == CALENDAR_IMPORTANCE_HIGH)
              {
               datetime eventTime = values[i].time;
               long diffSeconds = (long)(eventTime - now);
               long diffMins = diffSeconds / 60;

               m_isNewsRestricted = true;
               if(diffMins >= 0)
                  m_newsStatusText = StringFormat("[TIN ĐỎ USD] %s (còn %d phút)", event.name, diffMins);
               else
                  m_newsStatusText = StringFormat("[TIN ĐỎ USD] %s (vừa ra %d phút)", event.name, MathAbs(diffMins));

               if(InpNewsLockOpenToBE && diffMins >= 0 && diffMins <= InpNewsPauseMinsBefore)
                 {
                  SecurePositionsToBreakEvenBeforeNews();
                 }
               break;
              }
           }
        }
     }

   m_isVolShocked = false;
   double fastAtr[], slowAtr[];
   ArraySetAsSeries(fastAtr, true);
   ArraySetAsSeries(slowAtr, true);

   if(CopyBuffer(m_atrFastHandle, 0, 0, 1, fastAtr) > 0 && CopyBuffer(m_atrSlowHandle, 0, 0, 1, slowAtr) > 0)
     {
      if(slowAtr[0] > 0.0)
        {
         m_currentVolRatio = fastAtr[0] / slowAtr[0];
         if(m_currentVolRatio >= InpVolSpikeThreshold)
           {
            m_isVolShocked   = true;
            m_volatilityText = StringFormat("SỐC BIẾN ĐỘNG (%.2fx) - DỪNG VÀO LỆNH", m_currentVolRatio);
           }
         else if(m_currentVolRatio >= 1.35)
           {
            m_volatilityText = StringFormat("BIẾN ĐỘNG SÔI ĐỘNG (%.2fx)", m_currentVolRatio);
           }
         else
           {
            m_volatilityText = StringFormat("ỔN ĐỊNH BÌNH THƯỜNG (%.2fx)", m_currentVolRatio);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| BẢO VỆ VỊ THẾ DỜI VỀ HÒA VỐN TRƯỚC GIỜ TIN ĐỎ                    |
//+------------------------------------------------------------------+
void SecurePositionsToBreakEvenBeforeNews()
  {
   double point = m_symbol.Point();
   double bufferPts = InpBreakEvenBufferPts * m_pointScale;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      ulong  ticket    = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double curSl     = m_position.StopLoss();
      double curTp     = m_position.TakeProfit();
      double curPrice  = m_position.PriceCurrent();

      if(m_position.PositionType() == POSITION_TYPE_BUY)
        {
         if(curPrice > openPrice + 15 * point * m_pointScale)
           {
            double bePrice = NormalizeDouble(openPrice + bufferPts * point, _Digits);
            if(curSl < bePrice)
              {
               m_trade.PositionModify(ticket, bePrice, curTp);
               Print(">> [PRE-NEWS BE] Khóa hòa vốn vị thế BUY ticket: ", ticket);
              }
           }
        }
      else if(m_position.PositionType() == POSITION_TYPE_SELL)
        {
         if(curPrice < openPrice - 15 * point * m_pointScale)
           {
            double bePrice = NormalizeDouble(openPrice - bufferPts * point, _Digits);
            if(curSl > bePrice || curSl == 0.0)
              {
               m_trade.PositionModify(ticket, bePrice, curTp);
               Print(">> [PRE-NEWS BE] Khóa hòa vốn vị thế SELL ticket: ", ticket);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| KIỂM TRA KHUNG GIỜ MỞ LỆNH PHIÊN TỐI (THEO GIỜ VIỆT NAM)         |
//+------------------------------------------------------------------+
bool IsEveningTradingHours()
  {
   if(!InpUseEveningFilter) return true;

   datetime targetTime = GetCurrentVietnamTime();
   MqlDateTime dt;
   TimeToStruct(targetTime, dt);

   int curMin   = dt.hour * 60 + dt.min;
   int startMin = InpEveningStartHourVN * 60 + InpEveningStartMinVN;
   int endMin   = InpEveningEndHourVN * 60 + InpEveningEndMinVN;

   // Khung giờ tối thường từ 19:00 đến 23:30 (cùng trong ngày)
   if(startMin <= endMin)
     {
      if(curMin >= startMin && curMin < endMin) return true;
     }
   else
     {
      // Nếu có vắt qua nửa đêm (ví dụ từ 19:00 đến 01:00 sáng)
      if(curMin >= startMin || curMin < endMin) return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| QUY TRÌNH "GIAO DỊCH XONG KHUNG GIỜ TỐI"                         |
//+------------------------------------------------------------------+
void ProcessEveningSessionFinish()
  {
   if(!InpUseEveningFilter) return;

   datetime targetTime = GetCurrentVietnamTime();
   MqlDateTime dt;
   TimeToStruct(targetTime, dt);

   int curMin   = dt.hour * 60 + dt.min;
   int closeMin = InpForceCloseHourVN * 60 + InpForceCloseMinVN;

   // Chốt phiên vào lúc 02:00 sáng VN đến 06:00 sáng VN
   bool isFinishTime = false;
   if(InpForceCloseHourVN < 12)
     {
      if(dt.hour >= InpForceCloseHourVN && dt.hour < 7)
         isFinishTime = true;
     }
   else
     {
      if(curMin >= closeMin)
         isFinishTime = true;
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
            PrintFormat(">> [KẾT THÚC PHIÊN TỐI VN] Đóng sạch vị thế ticket %d (Lãi/Lỗ: $%.2f)", ticket, curProfit);
           }
         else if(InpSessionFinishMode == FINISH_CLOSE_PROFIT_LOCK_BE)
           {
            if(curProfit > 0.0)
              {
               m_trade.PositionClose(ticket);
               PrintFormat(">> [KẾT THÚC PHIÊN TỐI VN - CHỐT LÃI] Đã chốt vị thế ticket %d (Lãi: +$%.2f)", ticket, curProfit);
              }
            else
              {
               if(m_position.PositionType() == POSITION_TYPE_BUY)
                 {
                  double bePrice = NormalizeDouble(openPrice + bufferPts * point, _Digits);
                  if(curSl < bePrice && curPrice >= openPrice)
                    {
                     m_trade.PositionModify(ticket, bePrice, curTp);
                     PrintFormat(">> [KẾT THÚC PHIÊN TỐI VN - KHÓA BE] Dời SL BUY %d về hòa vốn", ticket);
                    }
                 }
               else if(m_position.PositionType() == POSITION_TYPE_SELL)
                 {
                  double bePrice = NormalizeDouble(openPrice - bufferPts * point, _Digits);
                  if((curSl > bePrice || curSl == 0.0) && curPrice <= openPrice)
                    {
                     m_trade.PositionModify(ticket, bePrice, curTp);
                     PrintFormat(">> [KẾT THÚC PHIÊN TỐI VN - KHÓA BE] Dời SL SELL %d về hòa vốn", ticket);
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| TÍNH TOÁN KHỐI LƯỢNG LOT TỐI ƯU CHO VỐN 1000U (SAFE SIZING)      |
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
//| ĐÁNH GIÁ CHẤT LƯỢNG ĐIỂM VÀO LỆNH (CONFLUENCE SCORING SYSTEM)    |
//+------------------------------------------------------------------+
int EvaluateConfluenceScore(int direction, ENUM_PRICE_ACTION_SIGNAL paSignal, double entryPrice, double currentAtr, string &scoreReason)
  {
   int score = 0;
   scoreReason = "";

   // 1. Xu hướng HTF H1 [+25 Điểm]
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
            score += 25;
            scoreReason += "H1 Uptrend (+25) | ";
           }
         else if(direction == -1 && htfFast[0] < htfSlow[0])
           {
            score += 25;
            scoreReason += "H1 Downtrend (+25) | ";
           }
         else
           {
            scoreReason += "H1 Ngược Trend (0) | ";
           }
        }
     }
   else
     {
      score += 25;
     }

   // 2. Vùng giá trị DBB M15 [+25 Điểm]
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
         if(entryPrice >= midBand[0] && entryPrice <= innerUpper[0] + currentAtr * 0.5)
           {
            score += 25;
            scoreReason += "DBB Pullback Zone (+25) | ";
           }
         else if(entryPrice < midBand[0])
           {
            score += 15;
            scoreReason += "DBB Deep Discount (+15) | ";
           }
        }
      else if(direction == -1)
        {
         if(entryPrice <= midBand[0] && entryPrice >= innerLower[0] - currentAtr * 0.5)
           {
            score += 25;
            scoreReason += "DBB Sell Zone (+25) | ";
           }
         else if(entryPrice > midBand[0])
           {
            score += 15;
            scoreReason += "DBB Premium Reject (+15) | ";
           }
        }
     }

   // 3. Tín hiệu Price Action [+25 Điểm]
   if(direction == 1)
     {
      if(paSignal == SIGNAL_PINBAR_BULLISH)
        {
         score += 25;
         scoreReason += "Bullish Pin Bar (+25) | ";
        }
      else if(paSignal == SIGNAL_FAKEY_BULLISH)
        {
         score += 25;
         scoreReason += "Bullish Fakey (+25) | ";
        }
      else if(paSignal == SIGNAL_ENGULFING_BULL)
        {
         score += 20;
         scoreReason += "Bullish Engulfing (+20) | ";
        }
     }
   else if(direction == -1)
     {
      if(paSignal == SIGNAL_PINBAR_BEARISH)
        {
         score += 25;
         scoreReason += "Bearish Pin Bar (+25) | ";
        }
      else if(paSignal == SIGNAL_FAKEY_BEARISH)
        {
         score += 25;
         scoreReason += "Bearish Fakey (+25) | ";
        }
      else if(paSignal == SIGNAL_ENGULFING_BEAR)
        {
         score += 20;
         scoreReason += "Bearish Engulfing (+20) | ";
        }
     }

   // 4. RSI Momentum [+15 Điểm]
   double rsiBuf[];
   ArraySetAsSeries(rsiBuf, true);
   if(CopyBuffer(m_rsiHandle, 0, 1, 1, rsiBuf) > 0)
     {
      double rsi = rsiBuf[0];
      if(direction == 1 && rsi >= InpRsiBuyMin && rsi <= InpRsiBuyMax)
        {
         score += 15;
         scoreReason += StringFormat("RSI %.1f Tốt (+15) | ", rsi);
        }
      else if(direction == -1 && rsi >= InpRsiSellMin && rsi <= InpRsiSellMax)
        {
         score += 15;
         scoreReason += StringFormat("RSI %.1f Tốt (+15) | ", rsi);
        }
      else
        {
         scoreReason += StringFormat("RSI %.1f (+0) | ", rsi);
        }
     }

   // 5. Quét thanh khoản phiên Á [+10 Điểm Thưởng]
   if(InpUseAsianSweepFilter && m_asianRangeReady)
     {
      MqlRates ratesList[];
      ArraySetAsSeries(ratesList, true);
      if(CopyRates(_Symbol, PERIOD_CURRENT, 1, 1, ratesList) > 0)
        {
         MqlRates prevBar = ratesList[0];
         if(direction == 1 && prevBar.low < m_asianLow && prevBar.close > m_asianLow)
           {
            score += 10;
            scoreReason += "Asian Low Sweep (+10)!";
           }
         else if(direction == -1 && prevBar.high > m_asianHigh && prevBar.close < m_asianHigh)
           {
            score += 10;
            scoreReason += "Asian High Sweep (+10)!";
           }
        }
     }

   return score;
  }

//+------------------------------------------------------------------+
//| NHẬN DIỆN MÔ HÌNH NẾN PRICE ACTION ĐỈNH CAO                      |
//+------------------------------------------------------------------+
ENUM_PRICE_ACTION_SIGNAL DetectPriceActionPattern(const MqlRates &c1, const MqlRates &c2, const MqlRates &c3)
  {
   double range1 = c1.high - c1.low;
   if(range1 <= 0.0) return SIGNAL_NONE;

   double body1      = MathAbs(c1.close - c1.open);
   double lowerWick1 = MathMin(c1.open, c1.close) - c1.low;
   double upperWick1 = c1.high - MathMax(c1.open, c1.close);

   if((lowerWick1 / range1 >= InpMinPinBarWickRatio) &&
      (body1 / range1 <= InpMaxPinBarBodyRatio) &&
      (upperWick1 / range1 <= 0.15))
     {
      return SIGNAL_PINBAR_BULLISH;
     }

   if((upperWick1 / range1 >= InpMinPinBarWickRatio) &&
      (body1 / range1 <= InpMaxPinBarBodyRatio) &&
      (lowerWick1 / range1 <= 0.15))
     {
      return SIGNAL_PINBAR_BEARISH;
     }

   bool isInsideBar = (c2.high < c3.high && c2.low > c3.low);
   if(isInsideBar)
     {
      if(c1.low < c2.low && c1.close > c2.low && c1.close > c1.open)
         return SIGNAL_FAKEY_BULLISH;
      if(c1.high > c2.high && c1.close < c2.high && c1.close < c1.open)
         return SIGNAL_FAKEY_BEARISH;
     }

   double body2 = MathAbs(c2.close - c2.open);
   if(c1.close > c1.open && c2.close < c2.open)
     {
      if(c1.close > c2.open && c1.open <= c2.close && body1 > body2 * 1.2)
         return SIGNAL_ENGULFING_BULL;
     }
   else if(c1.close < c1.open && c2.close > c2.open)
     {
      if(c1.close < c2.open && c1.open >= c2.close && body1 > body2 * 1.2)
         return SIGNAL_ENGULFING_BEAR;
     }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| ĐÁNH GIÁ VÀ BẮN TỈA SETUP ĐIỂM VÀNG (SNIPER EXECUTION)           |
//+------------------------------------------------------------------+
void EvaluateAndExecuteSniperSetup()
  {
   if(m_dailyShieldActive)
     {
      m_lastSetupDesc = "Đã chạm mức sụt giảm ngày (Shield Active). Khóa mở lệnh!";
      return;
     }

   if(!IsEveningTradingHours())
     {
      m_lastSetupDesc = StringFormat("Ngoài giờ phiên tối (%02d:%02d -> %02d:%02d VN). Đang chờ...",
                                     InpEveningStartHourVN, InpEveningStartMinVN, InpEveningEndHourVN, InpEveningEndMinVN);
      return;
     }

   if(m_isNewsRestricted)
     {
      m_lastSetupDesc = StringFormat("Đang né tin tức USD: %s", m_newsStatusText);
      return;
     }

   if(m_isVolShocked)
     {
      m_lastSetupDesc = StringFormat("Sốc biến động: %s", m_volatilityText);
      return;
     }

   long currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   long maxSpread = InpMaxSpreadPoints * m_pointScale;
   if(currentSpread > maxSpread)
     {
      m_lastSetupDesc = StringFormat("Spread cao: %d pts > Max %d pts. Đứng ngoài!", currentSpread, maxSpread);
      return;
     }

   if(m_nightTradesTaken >= InpMaxTradesPerNight)
     {
      m_lastSetupDesc = StringFormat("Đã đạt giới hạn %d lệnh trong tối. Nghỉ ngơi bảo toàn lãi!", InpMaxTradesPerNight);
      return;
     }

   if(CountTotalOpenPositions() >= InpMaxConcurrentPositions)
     {
      m_lastSetupDesc = "Đang có vị thế chạy. Tập trung quản lý lệnh hiện tại!";
      return;
     }

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_CURRENT, 1, 3, rates) < 3) return;

   MqlRates c1 = rates[0];
   MqlRates c2 = rates[1];
   MqlRates c3 = rates[2];

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(m_atrHandle, 0, 1, 1, atrBuf) < 1) return;
   double currentAtr = atrBuf[0];

   ENUM_PRICE_ACTION_SIGNAL paSignal = DetectPriceActionPattern(c1, c2, c3);
   if(paSignal == SIGNAL_NONE)
     {
      m_lastSetupDesc = "Chưa có nến Price Action chuẩn (Chờ Pin Bar/Fakey M15)...";
      return;
     }

   double point = m_symbol.Point();
   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid();

   // Đánh giá Setup BUY
   if(paSignal == SIGNAL_PINBAR_BULLISH || paSignal == SIGNAL_FAKEY_BULLISH || paSignal == SIGNAL_ENGULFING_BULL)
     {
      string scoreReason = "";
      int score = EvaluateConfluenceScore(1, paSignal, ask, currentAtr, scoreReason);
      m_lastSetupScore = score;

      if(score >= InpMinConfluenceScore)
        {
         double slPrice = NormalizeDouble(c1.low - (currentAtr * 0.3), _Digits);
         double slDistancePts = (ask - slPrice) / point;

         if(slDistancePts < (currentAtr * InpAtrSlMultiplier) / point)
           {
            slDistancePts = (currentAtr * InpAtrSlMultiplier) / point;
            slPrice = NormalizeDouble(ask - slDistancePts * point, _Digits);
           }

         double tpDistancePts = slDistancePts * InpTargetRrRatio;
         double tpPrice = NormalizeDouble(ask + tpDistancePts * point, _Digits);
         double lotSize = CalculateOptimalLotSize(slDistancePts);

         PrintFormat(">> [A+ BUY SETUP ĐẠT %d ĐIỂM] %s", score, scoreReason);
         PrintFormat(">> Mở BUY Lot: %.2f | SL: %.3f (%.0f pts) | TP: %.3f (R:R 1:%.1f)", lotSize, slPrice, slDistancePts, tpPrice, InpTargetRrRatio);

         if(m_trade.Buy(lotSize, _Symbol, ask, slPrice, tpPrice, InpTradeComment))
           {
            m_nightTradesTaken++;
            m_lastSetupDesc = StringFormat("BẮN TỈA BUY THÀNH CÔNG! (Điểm: %d/100)", score);
           }
         else
           {
            Print("Lỗi mở BUY: ", m_trade.ResultRetcodeDescription());
           }
        }
      else
        {
         m_lastSetupDesc = StringFormat("Tín hiệu BUY chưa đủ chuẩn: %d/%d điểm. Bỏ qua!", score, InpMinConfluenceScore);
        }
     }
   // Đánh giá Setup SELL
   else if(paSignal == SIGNAL_PINBAR_BEARISH || paSignal == SIGNAL_FAKEY_BEARISH || paSignal == SIGNAL_ENGULFING_BEAR)
     {
      string scoreReason = "";
      int score = EvaluateConfluenceScore(-1, paSignal, bid, currentAtr, scoreReason);
      m_lastSetupScore = score;

      if(score >= InpMinConfluenceScore)
        {
         double slPrice = NormalizeDouble(c1.high + (currentAtr * 0.3), _Digits);
         double slDistancePts = (slPrice - bid) / point;

         if(slDistancePts < (currentAtr * InpAtrSlMultiplier) / point)
           {
            slDistancePts = (currentAtr * InpAtrSlMultiplier) / point;
            slPrice = NormalizeDouble(bid + slDistancePts * point, _Digits);
           }

         double tpDistancePts = slDistancePts * InpTargetRrRatio;
         double tpPrice = NormalizeDouble(bid - tpDistancePts * point, _Digits);
         double lotSize = CalculateOptimalLotSize(slDistancePts);

         PrintFormat(">> [A+ SELL SETUP ĐẠT %d ĐIỂM] %s", score, scoreReason);
         PrintFormat(">> Mở SELL Lot: %.2f | SL: %.3f (%.0f pts) | TP: %.3f (R:R 1:%.1f)", lotSize, slPrice, slDistancePts, tpPrice, InpTargetRrRatio);

         if(m_trade.Sell(lotSize, _Symbol, bid, slPrice, tpPrice, InpTradeComment))
           {
            m_nightTradesTaken++;
            m_lastSetupDesc = StringFormat("BẮN TỈA SELL THÀNH CÔNG! (Điểm: %d/100)", score);
           }
         else
           {
            Print("Lỗi mở SELL: ", m_trade.ResultRetcodeDescription());
           }
        }
      else
        {
         m_lastSetupDesc = StringFormat("Tín hiệu SELL chưa đủ chuẩn: %d/%d điểm. Bỏ qua!", score, InpMinConfluenceScore);
        }
     }
  }

//+------------------------------------------------------------------+
//| QUẢN LÝ LỆNH: BREAK-EVEN, CHỐT LỜI 50% & TRAILING STOP           |
//+------------------------------------------------------------------+
void ManageOpenPositions()
  {
   double point = m_symbol.Point();
   double bufferPts = InpBreakEvenBufferPts * m_pointScale;

   double currentAtr = 0.0;
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(m_atrHandle, 0, 0, 1, atrBuf) > 0) currentAtr = atrBuf[0];

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
      ENUM_POSITION_TYPE type = m_position.PositionType();

      double originalRiskPts = 0.0;
      if(curSl > 0.0)
         originalRiskPts = MathAbs(openPrice - curSl) / point;
      else if(currentAtr > 0.0)
         originalRiskPts = (currentAtr * InpAtrSlMultiplier) / point;
      else
         originalRiskPts = 300 * m_pointScale;

      if(originalRiskPts <= 0) continue;

      // 1. TỰ ĐỘNG CHỐT LỜI 50% KHỐI LƯỢNG (PARTIAL CLOSE)
      if(InpUsePartialClose && volume >= (m_symbol.LotsMin() * 2.0))
        {
         double profitPts = 0.0;
         if(type == POSITION_TYPE_BUY)  profitPts = (curPrice - openPrice) / point;
         if(type == POSITION_TYPE_SELL) profitPts = (openPrice - curPrice) / point;

         if(profitPts >= (originalRiskPts * InpPartialCloseRatioR))
           {
            double closeLot = NormalizeDouble(volume / 2.0, 2);
            double step = m_symbol.LotsStep();
            closeLot = MathFloor(closeLot / step) * step;

            if(closeLot >= m_symbol.LotsMin())
              {
               if(m_trade.PositionClosePartial(ticket, closeLot))
                 {
                  PrintFormat(">> [CHỐT LỜI 50%% THÀNH CÔNG] Ticket %d cắt bớt %.2f lot tại %.1fR (+%.0f pts)!", ticket, closeLot, InpPartialCloseRatioR, profitPts);
                 }
              }
           }
        }

      // 2. TỰ ĐỘNG DỜI STOP LOSS VỀ HÒA VỐN (AUTO BREAK-EVEN)
      if(InpUseAutoBreakEven)
        {
         if(type == POSITION_TYPE_BUY)
           {
            double gainPts = (curPrice - openPrice) / point;
            if(gainPts >= (originalRiskPts * InpBreakEvenTriggerR))
              {
               double bePrice = NormalizeDouble(openPrice + bufferPts * point, _Digits);
               if(curSl < bePrice)
                 {
                  m_trade.PositionModify(ticket, bePrice, curTp);
                  PrintFormat(">> [AUTO BREAK-EVEN BUY] Đã dời SL ticket %d về hòa vốn (+%.1f pts buffer)", ticket, bufferPts);
                 }
              }
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double gainPts = (openPrice - curPrice) / point;
            if(gainPts >= (originalRiskPts * InpBreakEvenTriggerR))
              {
               double bePrice = NormalizeDouble(openPrice - bufferPts * point, _Digits);
               if(curSl > bePrice || curSl == 0.0)
                 {
                  m_trade.PositionModify(ticket, bePrice, curTp);
                  PrintFormat(">> [AUTO BREAK-EVEN SELL] Đã dời SL ticket %d về hòa vốn (+%.1f pts buffer)", ticket, bufferPts);
                 }
              }
           }
        }

      // 3. TRAILING STOP THEO ATR (GỒNG LÃI TỐI ĐA)
      if(InpUseTrailingStop && currentAtr > 0.0)
        {
         double trailDistPts = (currentAtr * InpTrailingAtrMult) / point;

         if(type == POSITION_TYPE_BUY)
           {
            double gainPts = (curPrice - openPrice) / point;
            if(gainPts >= (originalRiskPts * InpTrailingStartR))
              {
               double newSl = NormalizeDouble(curPrice - trailDistPts * point, _Digits);
               if(newSl > curSl && newSl > openPrice)
                 {
                  m_trade.PositionModify(ticket, newSl, curTp);
                  PrintFormat(">> [TRAILING STOP BUY] Dời SL ticket %d lên: %.3f", ticket, newSl);
                 }
              }
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double gainPts = (openPrice - curPrice) / point;
            if(gainPts >= (originalRiskPts * InpTrailingStartR))
              {
               double newSl = NormalizeDouble(curPrice + trailDistPts * point, _Digits);
               if((newSl < curSl || curSl == 0.0) && newSl < openPrice)
                 {
                  m_trade.PositionModify(ticket, newSl, curTp);
                  PrintFormat(">> [TRAILING STOP SELL] Dời SL ticket %d xuống: %.3f", ticket, newSl);
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| ĐẾM SỐ LƯỢNG VỊ THẾ HIỆN TẠI                                     |
//+------------------------------------------------------------------+
int CountTotalOpenPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
            count++;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| HELPER: TẠO VÀ CẬP NHẬT LABEL GIAO DIỆN                          |
//+------------------------------------------------------------------+
void SetGuiLabel(string name, string text, int x, int y, color clr, int fontSize=9, bool isBold=false)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, name, OBJPROP_FONT, isBold ? "Arial Bold" : "Segoe UI");
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
     }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
  }

//+------------------------------------------------------------------+
//| HELPER: TẠO PANEL GIAO DIỆN (BACKGROUND RECTANGLE)               |
//+------------------------------------------------------------------+
void SetGuiPanel(string name, int x, int y, int width, int height, color bgColor, color borderColor)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, name, OBJPROP_COLOR, borderColor);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
     }
  }

//+------------------------------------------------------------------+
//| VẼ BẢNG ĐIỀU KHIỂN TRỰC QUAN HUD DASHBOARD                       |
//+------------------------------------------------------------------+
void RenderDashboard()
  {
   double balance = m_account.Balance();
   double equity  = m_account.Equity();
   long   spread  = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   datetime vnTime = GetCurrentVietnamTime();
   MqlDateTime dtVN;
   TimeToStruct(vnTime, dtVN);

   int panelX = 15;
   int panelY = 25;
   int panelW = 385; // Mở rộng chiều ngang cho chữ thoáng đẹp
   int panelH = 300;

   // 1. Tạo Panel nền xám xanh đen sang trọng
   SetGuiPanel("NS_BG_MAIN", panelX, panelY, panelW, panelH, C'10,18,28', C'30,70,115');
   SetGuiPanel("NS_BG_HEAD", panelX, panelY, panelW, 28, C'16,30,50', C'30,70,115');

   // 2. Tiêu đề
   SetGuiLabel("NS_TITLE", "🌙 NOCTURNAL SNIPER 1000U (M15)", panelX + 12, panelY + 6, clrGold, 10, true);

   // 3. Các dòng nội dung chi tiết
   int startY = panelY + 36;
   int lineH  = 21;

   // Dòng 1: Vốn & Lãi Lỗ Ngày
   double todayPnl = equity - m_dailyStartEquity;
   color pnlColor = (todayPnl >= 0.0) ? clrLimeGreen : clrTomato;
   SetGuiLabel("NS_L1", StringFormat("💰 Vốn: $%.2f | Lời/Lỗ Hôm Nay: %+.2f$", equity, todayPnl), panelX + 12, startY, pnlColor, 9, true);

   // Dòng 2: Trạng thái Phiên Tối & Đồng hồ Việt Nam
   bool isEvening = IsEveningTradingHours();
   string eveningStr = isEvening ? StringFormat("ĐANG HOẠT ĐỘNG (19h00 -> %02dh%02d VN)", InpEveningEndHourVN, InpEveningEndMinVN)
                                 : StringFormat("CHỜ PHIÊN TỐI (%02dh%02d VN)", InpEveningStartHourVN, InpEveningStartMinVN);
   color eveningClr = isEvening ? clrLime : clrSilver;
   SetGuiLabel("NS_L2", StringFormat("🌙 Phiên Tối: %s [Giờ VN: %02d:%02d]", eveningStr, dtVN.hour, dtVN.min), panelX + 12, startY + lineH, eveningClr, 9, true);

   // Dòng 3: Spread & Giờ chốt phiên tối
   long maxSpread = InpMaxSpreadPoints * m_pointScale;
   color spreadColor = (spread > maxSpread) ? clrRed : clrAqua;
   SetGuiLabel("NS_L3", StringFormat("⚡ Spread: %d pts (Trần: %d) | Chốt Tối: %02d:%02d VN", spread, maxSpread, InpForceCloseHourVN, InpForceCloseMinVN), panelX + 12, startY + lineH*2, spreadColor, 9);

   // Dòng 4: Số lệnh tối nay & Vị thế đang chạy
   int openCount = CountTotalOpenPositions();
   SetGuiLabel("NS_L4", StringFormat("🎯 Lệnh Tối Nay: %d/%d | Đang Chạy: %d/%d vị thế", m_nightTradesTaken, InpMaxTradesPerNight, openCount, InpMaxConcurrentPositions), panelX + 12, startY + lineH*3, clrWhite, 9);

   // Dòng 5: Điểm số Setup gần nhất
   color scoreColor = (m_lastSetupScore >= InpMinConfluenceScore) ? clrGold : clrLightSkyBlue;
   SetGuiLabel("NS_L5", StringFormat("🏆 Điểm Setup A+: %d / 100 (Yêu cầu >= %d)", m_lastSetupScore, InpMinConfluenceScore), panelX + 12, startY + lineH*4, scoreColor, 9, true);

   // Dòng 6: Trạng thái bộ lọc nến & điểm đẹp
   SetGuiLabel("NS_L6", StringFormat("🔎 Tiến Độ: %s", m_lastSetupDesc), panelX + 12, startY + lineH*5, clrWheat, 8);

   // Dòng 7: Tin tức đỏ USD
   color newsClr = m_isNewsRestricted ? clrOrangeRed : clrSpringGreen;
   SetGuiLabel("NS_L7", StringFormat("📰 Tin Đỏ USD: %s", m_newsStatusText), panelX + 12, startY + lineH*6, newsClr, 8);

   // Dòng 8: Đo sốc biến động
   color volClr = m_isVolShocked ? clrRed : clrDeepSkyBlue;
   SetGuiLabel("NS_L8", StringFormat("🌊 Biến Động: %s", m_volatilityText), panelX + 12, startY + lineH*7, volClr, 8);

   // Dòng 9: Thanh khoản phiên Á & Đệm R:R
   string asianStr = m_asianRangeReady ? StringFormat("H:%.2f L:%.2f", m_asianHigh, m_asianLow) : "Đang tính";
   SetGuiLabel("NS_L9", StringFormat("🛡️ Asian Range: %s | R:R Mục Tiêu: 1 : %.1f", asianStr, InpTargetRrRatio), panelX + 12, startY + lineH*8, clrYellow, 8);

   // Dòng 10: Lá chắn Drawdown Guard
   string shieldStr = m_dailyShieldActive ? "[ĐÃ KHÓA BẢO TOÀN VỐN]" : "AN TOÀN (Max -3%)";
   color shieldClr = m_dailyShieldActive ? clrRed : clrLime;
   SetGuiLabel("NS_L10", StringFormat("🔒 Lá Chắn Ngày: %s", shieldStr), panelX + 12, startY + lineH*9, shieldClr, 9, true);

   string commentText = "";
   commentText += "============================================================\n";
   commentText += "   🌙 NOCTURNAL SNIPER 1000U - XẠ THỦ PHIÊN TỐI M15\n";
   commentText += "============================================================\n";
   commentText += StringFormat(" 💰 Vốn Hiện Tại: $%.2f | Lời/Lỗ Hôm Nay: %+.2f$\n", equity, todayPnl);
   commentText += StringFormat(" 🌙 Phiên Tối VN: %s [Giờ VN: %02d:%02d]\n", eveningStr, dtVN.hour, dtVN.min);
   commentText += StringFormat(" ⚡ Spread: %d pts (Trần: %d pts) | Chốt Tối: %02d:%02d VN\n", spread, maxSpread, InpForceCloseHourVN, InpForceCloseMinVN);
   commentText += StringFormat(" 🎯 Đã Bắn Tối Nay: %d / %d Lệnh (Chỉ Bắn A+ Setup >= %d Điểm)\n", m_nightTradesTaken, InpMaxTradesPerNight, InpMinConfluenceScore);
   commentText += StringFormat(" 🔎 Đánh Giá: %s\n", m_lastSetupDesc);
   commentText += StringFormat(" 📰 Tin Tức USD: %s\n", m_newsStatusText);
   commentText += StringFormat(" 🌊 Sốc Biến Động: %s\n", m_volatilityText);
   commentText += StringFormat(" 🛡️ Asian Range: %s | Tỷ Lệ R:R: 1 : %.1f\n", asianStr, InpTargetRrRatio);
   commentText += "============================================================\n";

   Comment(commentText);
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
