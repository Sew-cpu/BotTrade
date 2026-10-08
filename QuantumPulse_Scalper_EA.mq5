//+------------------------------------------------------------------+
//|                                     QuantumPulse_Scalper_EA.mq5  |
//|         HIGH-PROBABILITY MOMENTUM SCALPER - GOLD ONLY EDITION     |
//|               CHUYÊN BIỆT ĐỘC QUYỀN CHO VÀNG (XAUUSD)             |
//|        Tần suất ~1 lệnh/giờ | Điểm vào Hội tụ A+ | Chống quét râu |
//|          Tích hợp FX Academy (DBB), Nial Fuller (TLS & EMA),     |
//|             ForexBrokers.com (ECN Execution & Cost Engine)       |
//|                                  Copyright 2026, Antigravity     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Antigravity"
#property link        "https://github.com/Sew-cpu/BotTrade"
#property version     "2.00"
#property description "Robot Luot Song (Scalping) CHUYEN BIET CHO VANG (XAUUSD) - Tan suat ~1 lenh/tieng"
#property description "Hoi tu da khung thoi gian (H1 Trend + M5 Value Area + Pin Bar/Engulfing A+ Setup)"
#property description "Chong quet rau nen Vang (Anti-Wick Hunt) + Bo do soc bien dong Vang (Volatility Shock)"
#property description "Chot loi 2 tang (Dual-TP), Auto Break-Even sieu toc & Micro-ATR Trailing Stop"
#property description "Toi uu hoa chi phi san ECN/STP tren Vang, phong ve gian spread phien dem"
#property strict

//--- Thu vien chuan MetaQuotes MQL5
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS & STRATEGY DEFINITIONS                              |
//+------------------------------------------------------------------+
enum ENUM_SCALP_TRIGGER_MODE
  {
   TRIGGER_CONFLUENCE_ALL = 0, // Pin Bar + Engulfing + RSI Momemtum (Khuyen nghi - A+ Setup cho Vang)
   TRIGGER_PRICE_ACTION   = 1, // Chi dung Pin Bar Rejection & Bull/Bear Engulfing
   TRIGGER_DBB_MOMENTUM   = 2  // Chi dung Double Bollinger Bands bứt phá động lượng
  };

enum ENUM_POSITION_SIZING_MODE
  {
   SIZING_RISK_PERCENT = 0,    // % Rui ro theo Balance/Equity (Chuan toan hoc FX)
   SIZING_FIXED_LOT    = 1     // Lot co dinh linh hoat
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - TỐI ƯU HÓA ĐỘC QUYỀN CHO VÀNG (XAUUSD)       |
//+------------------------------------------------------------------+
input group "=== 1. QUẢN LÝ TẦN SUẤT & ĐIỀU PHỐI NHỊP SÓNG VÀNG ==="
input int               InpMinCooldownMinutes   = 40;                  // Thoi gian cho toi thieu giua cac lenh moi (Phut, ~1 lenh/tieng)

input group "=== 2. QUY TẮC NHỒI LỆNH DƯƠNG VÀNG (SMART PYRAMIDING) ==="
input bool              InpEnablePyramiding     = true;                // Bat tinh nang NHOI LENH khi gap nhip song A+ tiep theo
input int               InpMaxPositionsTotal    = 2;                   // So lenh toi da khi nhoi tren Vang (2 lenh an toan nhat)
input bool              InpPyramidOnlyInProfit  = true;                // TUYET DOI chi nhoi khi lenh 1 DANG CO LAI (Khong gong lo)
input double            InpPyramidMinProfitR    = 1.0;                 // Lenh 1 phai lai >= 1.0R (~1.8 - 2.5 gia Vang) moi duoc nhoi
input bool              InpSyncStopLossOnPyramid= true;                // Tu dong khoa SL lenh 1 ve Hoa von ngay khi vao lenh nhoi

input group "=== 3. QUẢN TRỊ VỐN & POSITION SIZING CHO VÀNG ==="
input ENUM_POSITION_SIZING_MODE InpSizingMode   = SIZING_RISK_PERCENT; // Che do tinh khoi luong
input double            InpRiskPercent          = 1.0;                 // % Rui ro moi lenh (1.0% - 1.5% an toan cho Vang)
input double            InpFixedLotSize         = 0.01;                // Lot co dinh (neu dung che do FIXED_LOT)
input double            InpMaxLotAllowed        = 0.20;                // Tran lot toi da cho phep tren Vang (Bao ve von)
input double            InpMinLotAllowed        = 0.01;                // Lot toi thieu
input bool              InpUseDailyLossShield   = true;                // Bat la chan bao ve so du trong ngay
input double            InpMaxDailyLossPercent  = 4.0;                 // Ngat bot neu lo vuot qua % von trong ngay

input group "=== 3. BỘ LỌC XU HƯỚNG ĐA KHUNG THỜI GIAN (HTF TREND H1) ==="
input bool              InpUseHtfTrend          = true;                // Bat bo loc xu huong khung lon
input ENUM_TIMEFRAMES   InpHtfTimeframe         = PERIOD_H1;           // Khung thoi gian xu huong lon (H1)
input int               InpHtfFastEmaPeriod     = 21;                  // EMA Nhanh H1 (Nial Fuller Dynamic EMA)
input int               InpHtfSlowEmaPeriod     = 50;                  // EMA Cham H1 (Trend Baseline)

input group "=== 4. VÙNG GIÁ TRỊ VÀ ĐỘNG LƯỢNG LƯỚT SÓNG VÀNG (M5) ==="
input int               InpFastEmaM5            = 8;                   // EMA Nhanh M5 (Vung gia tri loi)
input int               InpSlowEmaM5            = 21;                  // EMA Cham M5 (Bien duoi vung gia tri)
input bool              InpUseDbbFilter         = true;                // Dung Double Bollinger Bands (Cliff Wachtel)
input int               InpDbbPeriod            = 20;                  // Chu ky BB
input double            InpDbbOuterDev          = 2.0;                 // Dai ngoai (2.0 SD)
input double            InpDbbInnerDev          = 1.0;                 // Dai trong (1.0 SD)
input bool              InpUseRsiFilter         = true;                // Loc xung luong qua ban/qua mua RSI
input int               InpRsiPeriod            = 14;                  // Chu ky RSI
input double            InpRsiBuyMin            = 36.0;                // RSI toi thieu de mua (Noi rong don song M5)
input double            InpRsiBuyMax            = 72.0;                // RSI toi da de mua (Tranh mua du dinh qua mua)
input double            InpRsiSellMin           = 28.0;                // RSI toi thieu de ban (Cho phep ban khi xu huong manh)
input double            InpRsiSellMax           = 64.0;                // RSI toi da de ban (Noi rong don song M5)

input group "=== 5. CHỐNG QUÉT RÂU VÀNG & ĐIỂM VÀO A+ (ANTI-WICK HUNT) ==="
input ENUM_SCALP_TRIGGER_MODE InpTriggerMode    = TRIGGER_CONFLUENCE_ALL; // Che do kich hoat
input double            InpMinWickRatioPinBar   = 0.50;                // Ty le rau nen Pin Bar Vang toi thieu (>= 50% rut chan, toi uu M5)
input double            InpMaxBodyRatioPinBar   = 0.35;                // Ty le than nen Pin Bar Vang toi da (<= 35%)
input int               InpGoldBufferPoints     = 35;                  // Khoang dem phong ve chong quet rau (Points ~ $0.35 gia Vang)
input bool              InpRequireMinCandleSize = true;                // Yeu cau nến kich hoat co bien do toi thieu
input double            InpMinCandleAtrFactor   = 0.40;                // Bien do nến >= 0.4x ATR (Loc bo nen doji tieng on)
input bool              InpAllowMomentumBreakout= true;                // Cho phep vao lenh theo nen bứt phá đà mạnh (Momentum Trend Bar)

input group "=== 6. BỘ LỌC TIN TỨC USD & SỐC BIẾN ĐỘNG VÀNG (NEWS & SHOCK) ==="
input bool              InpUseNewsFilter        = true;                // Bat bo loc Tin tuc MQL5 Calendar (CPI, NFP, FOMC)
input int               InpMinsBeforeNews       = 30;                  // Dung vao lenh truoc gio tin do USD (Phut)
input int               InpMinsAfterNews        = 30;                  // Dung vao lenh sau gio tin do USD (Phut)
input bool              InpNewsProtectToBE      = true;                // Tu dong keo SL ve Hoa von truoc gio tin USD
input bool              InpFilterHighImpactOnly = true;                // Chi loc tin do (High-Impact USD)
input bool              InpUseVolShockFilter    = true;                // Bat bo loc chan soc bien dong dot bien Vang
input double            InpVolSpikeThreshold    = 2.2;                 // Nguong soc bien dong (ATR3 / ATR20 >= 2.2x thi tam dung)

input group "=== 7. QUẢN LÝ LỆNH VÀNG: STOP LOSS, TAKE PROFIT & TRAILING ==="
input int               InpAtrPeriod            = 14;                  // Chu ky ATR do bien dong Vang
input double            InpAtrMultiplierSL      = 1.6;                 // Khoang cach SL = 1.6x ATR Vang
input int               InpMinSlPoints          = 250;                 // SL toi thieu cho Vang (Points ~ $2.5 gia, vuot spread Exness)
input int               InpMaxSlPoints          = 950;                 // SL toi da cho phep tren Vang (Points ~ $9.5 gia, chuan XAUUSD $4100+)
input double            InpRiskRewardRatio      = 2.0;                 // Ty le R:R muc tieu chinh (1:2.0 tren Vang)
input bool              InpUsePartialClose      = true;                // Chot loi 50% khoi luong tai muc TP1 (Dual-TP)
input double            InpPartialCloseAtR      = 1.0;                 // Chot loi 50% khi dat 1.0R (an chac ~$2.5-$4.0 gia Vang)
input double            InpPartialClosePercent  = 50.0;                // % Khoi luong can chot tai TP1
input bool              InpUseAutoBreakEven     = true;                // Tu dong keo SL ve hoa von (Risk-Free)
input double            InpBreakEvenTriggerR    = 0.8;                 // Keo hoa von khi gia Vang chay dat 0.8R
input int               InpBreakEvenOffsetPts   = 30;                  // Bu phi spread Vang (Points ~ $0.30 tren Entry)
input bool              InpUseTrailingStop      = true;                // Trailing Stop bam sat con song Vang
input double            InpTrailingStartR       = 1.2;                 // Bat dau trailing khi loi nhuan >= 1.2R
input double            InpTrailingDistanceATR  = 1.4;                 // Khoang cach trailing theo ATR Vang
input int               InpTrailingStepPts      = 25;                  // Buoc nhay toi thieu dời SL (Points ~ $0.25 gia)

input group "=== 8. BỘ LỌC AN TOÀN SÀN & PHIÊN GIAO DỊCH VÀNG ==="
input int               InpMaxSpreadPoints      = 350;                 // Spread toi da cho phep danh Vang (Points, Exness ~220-280 pts)
input ulong             InpMaxSlippagePoints    = 35;                  // Truot gia toi da cho phep tren Vang
input bool              InpUseTimeFilter        = false;               // Bat bo loc gio (false = CHAY CA NGAY 24/5, true = Chi danh phien Au/My)
input int               InpTradingStartHour     = 8;                   // Gio bat dau (Gio server, sang London soi dong)
input int               InpTradingEndHour       = 21;                  // Gio ket thuc (Gio server, toi New York)
input bool              InpAvoidFridayEvening   = true;                // Khong mo lenh sau 19h toi thu 6 (tranh Gap tuan sau)
input bool              InpNotifySessionEnd     = true;                // Bat thong bao moi khi ket thuc phien giao dich (A, Au, My)
input bool              InpSendPushOnSessionEnd = true;                // Gui Push Notification ve MT5 dien thoai khi het phien
input int               InpAsianEndHour         = 8;                   // Gio ket thuc phien A (Server hour, mac dinh 8h)
input int               InpLondonEndHour        = 16;                  // Gio ket thuc phien Au (Server hour, mac dinh 16h)
input int               InpNewYorkEndHour       = 21;                  // Gio ket thuc phien My (Server hour, mac dinh 21h)

input group "=== 9. THIẾT LẬP HỆ THỐNG & DASHBOARD ==="
input ulong             InpMagicNumber          = 777995;              // Magic Number doc quyen cua QuantumPulse Scalper
input string            InpTradeComment         = "QuantumGold_Scalp"; // Ghi chu lenh
input bool              InpShowDashboard        = true;                // Hien thi bang HUD truc quan

//+------------------------------------------------------------------+
//| BIẾN TOÀN CỤC & OBJECTS                                          |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;
CAccountInfo   m_account;
CSymbolInfo    m_symbol;

// Handles chi bao
int            m_htfFastEmaHandle  = INVALID_HANDLE;
int            m_htfSlowEmaHandle  = INVALID_HANDLE;
int            m_m5FastEmaHandle   = INVALID_HANDLE;
int            m_m5SlowEmaHandle   = INVALID_HANDLE;
int            m_bbOuterHandle     = INVALID_HANDLE;
int            m_bbInnerHandle     = INVALID_HANDLE;
int            m_rsiHandle         = INVALID_HANDLE;
int            m_atrHandle         = INVALID_HANDLE;
int            m_atrFastHandle     = INVALID_HANDLE;
int            m_atrSlowHandle     = INVALID_HANDLE;

// Bien trang thai van hanh
datetime       m_lastBarTime          = 0;
datetime       m_lastEntryTime        = 0;
datetime       m_lastDailyResetTime   = 0;
double         m_dailyStartEquity     = 0.0;
bool           m_dailyShieldTriggered = false;

// Thong ke & UI
int            m_tradesTodayCount     = 0;
int            m_winsTodayCount       = 0;
double         m_profitToday          = 0.0;
string         m_lastSignalDesc       = "Khoi tao he thong Vang...";
color          m_signalColor          = clrGold;
string         m_newsStatusText          = "SAFE (Khong co tin do USD)";
bool           m_isNewsRestricted        = false;
datetime       m_lastReportTime          = 0;
int            m_lastReportedSessionHour = -1;
int            m_lastReportedSessionDay  = -1;

//+------------------------------------------------------------------+
//| STRUCT & HELPERS QUẢN LÝ RISK GỐC CHO TỪNG VỊ THẾ (VÁ LỖI C)     |
//+------------------------------------------------------------------+
struct SPosRiskRecord
{
   ulong  ticket;
   double initialRiskPts;
   bool   tp1Closed;
};
SPosRiskRecord m_posRisks[];

void SetPosRiskRecord(ulong ticket, double initRiskPts)
{
   if(ticket == 0 || initRiskPts <= 0.0) return;
   int size = ArraySize(m_posRisks);
   for(int i = 0; i < size; i++)
   {
      if(m_posRisks[i].ticket == ticket)
      {
         m_posRisks[i].initialRiskPts = initRiskPts;
         return;
      }
   }
   ArrayResize(m_posRisks, size + 1);
   m_posRisks[size].ticket = ticket;
   m_posRisks[size].initialRiskPts = initRiskPts;
   m_posRisks[size].tp1Closed = false;
}

double GetPosInitialRiskPts(ulong ticket, double openPrice, double curTp, double curSl, double curAtr)
{
   int size = ArraySize(m_posRisks);
   for(int i = 0; i < size; i++)
   {
      if(m_posRisks[i].ticket == ticket && m_posRisks[i].initialRiskPts > 0.0)
      {
         return m_posRisks[i].initialRiskPts;
      }
   }

   double point = m_symbol.Point();
   double riskPts = 0.0;

   // 1. Tinh tu Take Profit goc (TP khong bao gio bi dời khi BE hay Trailing)
   if(curTp > 0.0 && InpRiskRewardRatio > 0.0 && point > 0.0)
   {
      riskPts = (MathAbs(openPrice - curTp) / point) / InpRiskRewardRatio;
   }

   // 2. Neu SL hien tai chua bi keo ve gan Entry
   if(riskPts < (double)InpMinSlPoints && curSl > 0.0 && point > 0.0)
   {
      double distSl = MathAbs(openPrice - curSl) / point;
      if(distSl >= (double)InpMinSlPoints) riskPts = distSl;
   }

   // 3. Fallback theo ATR Vang
   if(riskPts < (double)InpMinSlPoints)
   {
      if(curAtr > 0.0 && point > 0.0)
         riskPts = curAtr * InpAtrMultiplierSL / point;
      else
         riskPts = 350.0;
   }

   riskPts = MathMax(riskPts, (double)InpMinSlPoints);
   riskPts = MathMin(riskPts, (double)InpMaxSlPoints);

   SetPosRiskRecord(ticket, riskPts);
   return riskPts;
}

bool IsPosTp1Closed(ulong ticket)
{
   int size = ArraySize(m_posRisks);
   for(int i = 0; i < size; i++)
   {
      if(m_posRisks[i].ticket == ticket) return m_posRisks[i].tp1Closed;
   }
   return false;
}

void MarkPosTp1Closed(ulong ticket)
{
   int size = ArraySize(m_posRisks);
   for(int i = 0; i < size; i++)
   {
      if(m_posRisks[i].ticket == ticket)
      {
         m_posRisks[i].tp1Closed = true;
         return;
      }
   }
   SetPosRiskRecord(ticket, 350.0);
   int newSize = ArraySize(m_posRisks);
   if(newSize > 0) m_posRisks[newSize - 1].tp1Closed = true;
}

void CleanClosedPosRecords()
{
   int size = ArraySize(m_posRisks);
   for(int i = size - 1; i >= 0; i--)
   {
      if(!PositionSelectByTicket(m_posRisks[i].ticket))
      {
         for(int j = i; j < size - 1; j++)
         {
            m_posRisks[j] = m_posRisks[j + 1];
         }
         size--;
         ArrayResize(m_posRisks, size);
      }
   }
}

//+------------------------------------------------------------------+
//| HAM KIEM TRA BIEU DO CO PHAI LA VANG KHONG                       |
//+------------------------------------------------------------------+
bool IsGoldSymbol(string sym)
{
   string s = sym;
   StringToUpper(s);
   return (StringFind(s, "XAU") >= 0 || StringFind(s, "GOLD") >= 0);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // 1. Kiem tra Symbol co phai la Vang (XAUUSD) khong
   if(!IsGoldSymbol(_Symbol))
   {
      Alert(StringFormat("[CANH BAO] QuantumPulse Scalper duoc toi uu DOC QUYEN CHO VANG (XAUUSD)! Symbol hien tai '%s' khong phai Vang. Vui long gan vao bieu do XAUUSD!", _Symbol));
      PrintFormat("[LOI KHOI TAO] Bot chi chay tren Vang (XAUUSD / GOLD). Symbol hien tai: %s", _Symbol);
      return INIT_FAILED;
   }

   // 2. Khoi tao Symbol
   if(!m_symbol.Name(_Symbol))
   {
      PrintFormat("[LOI] Khong the khoi tao symbol %s!", _Symbol);
      return INIT_FAILED;
   }
   m_symbol.RefreshRates();

   // 3. Thiet lap CTrade
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(InpMaxSlippagePoints);
   m_trade.SetTypeFillingBySymbol(_Symbol);

   // 4. Khoi tao HTF EMA (Khung lon H1)
   if(InpUseHtfTrend)
   {
      m_htfFastEmaHandle = iMA(_Symbol, InpHtfTimeframe, InpHtfFastEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      m_htfSlowEmaHandle = iMA(_Symbol, InpHtfTimeframe, InpHtfSlowEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(m_htfFastEmaHandle == INVALID_HANDLE || m_htfSlowEmaHandle == INVALID_HANDLE)
      {
         Print("[LOI] Khong the khoi tao chi bao HTF EMA tren Vang!");
         return INIT_FAILED;
      }
   }

   // 5. Khoi tao M5 Value Area EMA (8 & 21)
   m_m5FastEmaHandle = iMA(_Symbol, PERIOD_CURRENT, InpFastEmaM5, 0, MODE_EMA, PRICE_CLOSE);
   m_m5SlowEmaHandle = iMA(_Symbol, PERIOD_CURRENT, InpSlowEmaM5, 0, MODE_EMA, PRICE_CLOSE);
   if(m_m5FastEmaHandle == INVALID_HANDLE || m_m5SlowEmaHandle == INVALID_HANDLE)
   {
      Print("[LOI] Khong the khoi tao chi bao M5 Dynamic EMA tren Vang!");
      return INIT_FAILED;
   }

   // 6. Khoi tao Double Bollinger Bands (Cliff Wachtel - FX Academy)
   if(InpUseDbbFilter)
   {
      m_bbOuterHandle = iBands(_Symbol, PERIOD_CURRENT, InpDbbPeriod, 0, InpDbbOuterDev, PRICE_CLOSE);
      m_bbInnerHandle = iBands(_Symbol, PERIOD_CURRENT, InpDbbPeriod, 0, InpDbbInnerDev, PRICE_CLOSE);
      if(m_bbOuterHandle == INVALID_HANDLE || m_bbInnerHandle == INVALID_HANDLE)
      {
         Print("[LOI] Khong the khoi tao chi bao Double Bollinger Bands tren Vang!");
         return INIT_FAILED;
      }
   }

   // 7. Khoi tao RSI Xung luong
   if(InpUseRsiFilter)
   {
      m_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, InpRsiPeriod, PRICE_CLOSE);
      if(m_rsiHandle == INVALID_HANDLE)
      {
         Print("[LOI] Khong the khoi tao chi bao RSI tren Vang!");
         return INIT_FAILED;
      }
   }

   // 8. Khoi tao ATR bien do va Bo do soc bien dong Vang
   m_atrHandle     = iATR(_Symbol, PERIOD_CURRENT, InpAtrPeriod);
   m_atrFastHandle = iATR(_Symbol, PERIOD_CURRENT, 3);
   m_atrSlowHandle = iATR(_Symbol, PERIOD_CURRENT, 20);
   if(m_atrHandle == INVALID_HANDLE || m_atrFastHandle == INVALID_HANDLE || m_atrSlowHandle == INVALID_HANDLE)
   {
      Print("[LOI] Khong the khoi tao chi bao ATR tren Vang!");
      return INIT_FAILED;
   }

   // 9. Thiet lap moc bao ve tai khoan trong ngay
   m_dailyStartEquity     = m_account.Equity();
   m_lastDailyResetTime   = TimeCurrent();
   m_dailyShieldTriggered = false;
   m_lastEntryTime        = 0;

   // 10. Khoi tao Timer 1s de lam moi UI & kiem tra dinh ky
   EventSetTimer(1);

   if(InpShowDashboard)
   {
      DrawDashboard();
   }

   PrintFormat(">>> [KHOI TAO THANH CONG] QuantumPulse Gold Scalper EA v2.00 tren [%s %s] | San san san song Vang!",
               _Symbol, EnumToString(Period()));
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   // Giai phong toan bo handle chi bao
   if(m_htfFastEmaHandle != INVALID_HANDLE) IndicatorRelease(m_htfFastEmaHandle);
   if(m_htfSlowEmaHandle != INVALID_HANDLE) IndicatorRelease(m_htfSlowEmaHandle);
   if(m_m5FastEmaHandle  != INVALID_HANDLE) IndicatorRelease(m_m5FastEmaHandle);
   if(m_m5SlowEmaHandle  != INVALID_HANDLE) IndicatorRelease(m_m5SlowEmaHandle);
   if(m_bbOuterHandle    != INVALID_HANDLE) IndicatorRelease(m_bbOuterHandle);
   if(m_bbInnerHandle    != INVALID_HANDLE) IndicatorRelease(m_bbInnerHandle);
   if(m_rsiHandle        != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
   if(m_atrHandle        != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
   if(m_atrFastHandle    != INVALID_HANDLE) IndicatorRelease(m_atrFastHandle);
   if(m_atrSlowHandle    != INVALID_HANDLE) IndicatorRelease(m_atrSlowHandle);

   // Xoa sach Dashboard tren bieu do
   ObjectsDeleteAll(0, "QP_");
   Comment("");
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
{
   m_symbol.RefreshRates();
   datetime now = TimeCurrent();

   CheckDailyReset();
   UpdateStatistics();
   UpdateNewsEngine();
   CheckSessionEndNotification();

   // Bao cao dinh ky moi 10 phut (600 giay) vao tab Experts
   if(now - m_lastReportTime >= 600 || m_lastReportTime == 0)
   {
      m_lastReportTime = now;
      int htf = GetHtfTrend();
      string htfText = (htf == 1) ? "TANG (Bullish)" : (htf == -1 ? "GIAM (Bearish)" : "DI NGANG (Neutral)");
      long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      int openOrders = CountOpenPositions();
      PrintFormat(">>> [BAO CAO 10 PHUT - %s] Bot QuantumPulse Gold Scalper hoat dong 100%% binh thuong | Gia: %.2f | Xu huong H1: %s | Spread: %d pts | Vi the: %d/%d | DANG SAN SONG VANG...",
                  TimeToString(now, TIME_MINUTES), m_symbol.Bid(), htfText, spread, openOrders, InpMaxPositionsTotal);
   }

   if(InpShowDashboard)
   {
      DrawDashboard();
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   m_symbol.RefreshRates();

   // 1. Kiem tra & quan ly cac vi the Vang dang mo (Break-Even, Partial Close, Trailing)
   ManageOpenPositions();

   // 2. Kiem tra cay nen moi de vao lenh (Chi vao o dau cay nen de tranh noise)
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == m_lastBarTime)
   {
      return; // Cung mot cay nen, khong quet tin hieu mo moi
   }

   // 3. Kiem tra la chan sụt giảm trong ngày (Daily Loss Shield)
   if(InpUseDailyLossShield && m_dailyShieldTriggered)
   {
      m_lastSignalDesc = "DUNG: Chạm giới hạn lỗ ngày!";
      m_signalColor    = clrCrimson;
      return;
   }

   // 4. Kiem tra bo loc tin tuc do USD (MQL5 Calendar)
   UpdateNewsEngine();
   if(InpUseNewsFilter && m_isNewsRestricted)
   {
      m_lastSignalDesc = "DỪNG: " + m_newsStatusText;
      m_signalColor    = clrCrimson;
      return;
   }

   // 5. Kiem tra bo loc thoi gian & phien giao dich Vang
   if(InpUseTimeFilter && !IsTradingAllowedTime())
   {
      m_lastSignalDesc = "CHO: Ngoài phiên thanh khoản cao của Vàng";
      m_signalColor    = clrSilver;
      return;
   }

   // 5. Kiem tra gian spread tren Vang
   long currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(currentSpread > InpMaxSpreadPoints)
   {
      m_lastSignalDesc = StringFormat("CHO: Spread Vàng cao (%d > %d pts)", currentSpread, InpMaxSpreadPoints);
      m_signalColor    = clrOrange;
      return;
   }

   // 6. Kiem tra bo do soc bien dong Vang (Shock Filter)
   if(InpUseVolShockFilter && IsVolatilityShocked())
   {
      m_lastSignalDesc = "CHO: Vàng biến động sốc bất thường (Shock Spike)";
      m_signalColor    = clrOrangeRed;
      return;
   }

   // 7. Kiem tra dieu phoi tan suat (Hourly Cadence Cooldown)
   datetime now = TimeCurrent();
   int secondsSinceLastEntry = (int)(now - m_lastEntryTime);
   int cooldownSeconds = InpMinCooldownMinutes * 60;
   if(m_lastEntryTime > 0 && secondsSinceLastEntry < cooldownSeconds)
   {
      int remainMins = (cooldownSeconds - secondsSinceLastEntry) / 60;
      m_lastSignalDesc = StringFormat("COOLDOWN: Chờ nhịp sóng Vàng (%d phút)", remainMins);
      m_signalColor    = clrGold;
      return;
   }

   // 8. Kiem tra so luong vi the toi da tren Vang
   int totalOpen = CountOpenPositions();
   if(totalOpen >= InpMaxPositionsTotal)
   {
      m_lastSignalDesc = StringFormat("DANG CHAY: Đã mở %d/%d lệnh Vàng", totalOpen, InpMaxPositionsTotal);
      m_signalColor    = clrMediumSeaGreen;
      return;
   }

   // 9. Lay du lieu nen va ATR cua Vang
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 5, rates) < 5) return;

   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(m_atrHandle, 0, 0, 3, atr) < 3 || atr[1] <= 0) return;

   // Kiem tra bien do nen toi thieu (Loc doji rac tren Vang)
   double barRange = rates[1].high - rates[1].low;
   if(InpRequireMinCandleSize && barRange < (atr[1] * InpMinCandleAtrFactor))
   {
      m_lastSignalDesc = "CHO: Nến nhỏ hơn ngưỡng biên độ tối thiểu";
      m_signalColor    = clrGray;
      return;
   }

   // 11. Xac dinh xu huong HTF (H1 Trend)
   int htfTrend = GetHtfTrend(); // 1 = Tang, -1 = Giam, 0 = Di ngang/Trung lap

   // 12. Xac dinh vi tri Pullback vao Vung Gia Tri M5 cua Vang (EMA 8 & 21 Value Area)
   bool inBuyValueArea = false;
   bool inSellValueArea = false;
   CheckM5ValueArea(rates[1], inBuyValueArea, inSellValueArea);

   // 13. Kiem tra Double Bollinger Bands Zone (DBB Cliff Wachtel)
   int dbbZone = 0; // 1 = Buy Zone (+1 to +2 SD), -1 = Sell Zone (-1 to -2 SD), 0 = Neutral
   if(InpUseDbbFilter)
   {
      dbbZone = GetDbbZone(rates[1].close);
   }

   // 14. Kiem tra RSI Momentum Filter
   bool rsiBuyOk = true, rsiSellOk = true;
   if(InpUseRsiFilter)
   {
      double rsi[];
      ArraySetAsSeries(rsi, true);
      if(CopyBuffer(m_rsiHandle, 0, 0, 3, rsi) >= 3)
      {
         rsiBuyOk  = (rsi[1] >= InpRsiBuyMin && rsi[1] <= InpRsiBuyMax);
         rsiSellOk = (rsi[1] >= InpRsiSellMin && rsi[1] <= InpRsiSellMax);
      }
   }

   // 15. Nhan dien Trigger Price Action tren Vang (Pin Bar rut chan, Engulfing & Momentum Bar)
   bool isBullPin = false, isBearPin = false;
   DetectPinBar(rates[1], isBullPin, isBearPin);

   bool isBullEngulf = false, isBearEngulf = false;
   DetectEngulfing(rates[1], rates[2], isBullEngulf, isBearEngulf);

   bool isBullMom = false, isBearMom = false;
   DetectMomentumBar(rates[1], atr[1], isBullMom, isBearMom);

   // 16. TONG HOP TIN HIEU VAO LENH A+ CHO VANG (HIGH-PROBABILITY CONFLUENCE)
   bool buyTrigger = false;
   bool sellTrigger = false;

   // Dieu kien BUY VÀNG:
   // 1. HTF Trend phai Tang hoac Neutral cho phep (htfTrend >= 0)
   // 2. Gia vua Pullback vao Vung gia tri M5 (inBuyValueArea) HOAC nam trong DBB Buy Zone
   // 3. Xung luong RSI nam trong khoang lướt an toan (rsiBuyOk)
   // 4. Nen dong cuoi (Bar 1) kich hoat Bullish Pin Bar, Bullish Engulfing hoac Momentum Bar
   if(htfTrend >= 0 && rsiBuyOk)
   {
      bool triggerPattern = false;
      if(InpTriggerMode == TRIGGER_CONFLUENCE_ALL)
         triggerPattern = (isBullPin || isBullEngulf || (InpAllowMomentumBreakout && isBullMom)) && (inBuyValueArea || dbbZone >= 0);
      else if(InpTriggerMode == TRIGGER_PRICE_ACTION)
         triggerPattern = (isBullPin || isBullEngulf || (InpAllowMomentumBreakout && isBullMom));
      else if(InpTriggerMode == TRIGGER_DBB_MOMENTUM)
         triggerPattern = (dbbZone == 1 && rates[1].close > rates[2].high);

      if(triggerPattern)
      {
         buyTrigger = true;
      }
   }

   // Dieu kien SELL VÀNG:
   // 1. HTF Trend phai Giam hoac Neutral cho phep (htfTrend <= 0)
   // 2. Gia vua Pullback vao Vung gia tri M5 (inSellValueArea) HOAC nam trong DBB Sell Zone
   // 3. Xung luong RSI nam trong khoang lướt an toan (rsiSellOk)
   // 4. Nen dong cuoi (Bar 1) kich hoat Bearish Pin Bar, Bearish Engulfing hoac Momentum Bar
   if(htfTrend <= 0 && rsiSellOk)
   {
      bool triggerPattern = false;
      if(InpTriggerMode == TRIGGER_CONFLUENCE_ALL)
         triggerPattern = (isBearPin || isBearEngulf || (InpAllowMomentumBreakout && isBearMom)) && (inSellValueArea || dbbZone <= 0);
      else if(InpTriggerMode == TRIGGER_PRICE_ACTION)
         triggerPattern = (isBearPin || isBearEngulf || (InpAllowMomentumBreakout && isBearMom));
      else if(InpTriggerMode == TRIGGER_DBB_MOMENTUM)
         triggerPattern = (dbbZone == -1 && rates[1].close < rates[2].low);

      if(triggerPattern)
      {
         sellTrigger = true;
      }
   }

   // 17. THUC THI LENH VANG HOAC NHOI LENH A+
   if(buyTrigger && !sellTrigger)
   {
      if(CanExecutePyramid(POSITION_TYPE_BUY))
      {
         bool isPyramid = (CountPositionsByType(POSITION_TYPE_BUY) > 0);
         ExecuteOrder(POSITION_TYPE_BUY, rates[1], atr[1], isPyramid);
         m_lastBarTime = currentBarTime;
      }
   }
   else if(sellTrigger && !buyTrigger)
   {
      if(CanExecutePyramid(POSITION_TYPE_SELL))
      {
         bool isPyramid = (CountPositionsByType(POSITION_TYPE_SELL) > 0);
         ExecuteOrder(POSITION_TYPE_SELL, rates[1], atr[1], isPyramid);
         m_lastBarTime = currentBarTime;
      }
   }
   else
   {
      m_lastBarTime = currentBarTime;
      string reason = "Chờ setup A+";
      if(htfTrend == 1 && !rsiBuyOk) reason = "Chờ RSI Buy (36-72)";
      else if(htfTrend == -1 && !rsiSellOk) reason = "Chờ RSI Sell (28-64)";
      else if(htfTrend == 0) reason = "Chờ xu hướng H1";
      else reason = "Chờ nến xác nhận M5";

      m_lastSignalDesc = StringFormat("QUAN SÁT: %s", reason);
      m_signalColor    = clrGold;
   }
}

//+------------------------------------------------------------------+
//| ENGINE TIN TUC USD CHO VANG (MQL5 ECONOMIC CALENDAR)             |
//+------------------------------------------------------------------+
void UpdateNewsEngine()
{
   m_isNewsRestricted = false;
   m_newsStatusText   = "SAFE (Khong co tin do USD)";

   if(!InpUseNewsFilter) return;

   datetime now = TimeCurrent();
   datetime fromTime = now - (InpMinsAfterNews * 60);
   datetime toTime   = now + (InpMinsBeforeNews * 60);

   MqlCalendarValue values[];
   int totalEvents = CalendarValueHistory(values, fromTime, toTime, NULL, "USD");
   for(int i = 0; i < totalEvents; i++)
   {
      MqlCalendarEvent event;
      if(CalendarEventById(values[i].event_id, event))
      {
         bool isHighImpact = (event.importance == CALENDAR_IMPORTANCE_HIGH);
         if(!InpFilterHighImpactOnly)
         {
            isHighImpact = (event.importance >= CALENDAR_IMPORTANCE_MODERATE);
         }

         if(isHighImpact)
         {
            datetime eventTime = values[i].time;
            long diffSeconds = (long)(eventTime - now);
            long diffMins = diffSeconds / 60;

            m_isNewsRestricted = true;
            if(diffMins >= 0)
            {
               m_newsStatusText = StringFormat("[TIN DO USD] %s con %d phut", event.name, diffMins);
            }
            else
            {
               m_newsStatusText = StringFormat("[TIN DO USD] %s cach day %d phut", event.name, MathAbs(diffMins));
            }

            if(InpNewsProtectToBE && diffMins >= 0 && diffMins <= InpMinsBeforeNews)
            {
               ProtectPositionsBeforeNews();
            }
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| KEO SL CAC LENH DANG MO VE HOA VON TRUOC GIO TIN DO USD          |
//+------------------------------------------------------------------+
void ProtectPositionsBeforeNews()
{
   double point = m_symbol.Point();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      ulong ticket     = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double curSl     = m_position.StopLoss();
      double curTp     = m_position.TakeProfit();
      ENUM_POSITION_TYPE type = m_position.PositionType();

      if(type == POSITION_TYPE_BUY)
      {
         double safeBe = NormalizeDouble(openPrice + InpBreakEvenOffsetPts * point, _Digits);
         if(curSl < safeBe)
         {
            m_trade.PositionModify(ticket, safeBe, curTp);
            Print(">> [NEWS PROTECTION BUY] Da keo SL ve hoa von truoc tin do USD: ", safeBe);
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double safeBe = NormalizeDouble(openPrice - InpBreakEvenOffsetPts * point, _Digits);
         if(curSl > safeBe || curSl == 0.0)
         {
            m_trade.PositionModify(ticket, safeBe, curTp);
            Print(">> [NEWS PROTECTION SELL] Da keo SL ve hoa von truoc tin do USD: ", safeBe);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| KIEM TRA SOC BIEN DONG VANG (ATR FAST / SLOW)                    |
//+------------------------------------------------------------------+
bool IsVolatilityShocked()
{
   double fastAtr[], slowAtr[];
   ArraySetAsSeries(fastAtr, true);
   ArraySetAsSeries(slowAtr, true);

   if(CopyBuffer(m_atrFastHandle, 0, 0, 2, fastAtr) < 2) return false;
   if(CopyBuffer(m_atrSlowHandle, 0, 0, 2, slowAtr) < 2) return false;

   if(slowAtr[1] <= 0) return false;

   double ratio = fastAtr[1] / slowAtr[1];
   return (ratio >= InpVolSpikeThreshold);
}

//+------------------------------------------------------------------+
//| XAC DINH XU HUONG KHUNG LON HTF (H1)                             |
//+------------------------------------------------------------------+
int GetHtfTrend()
{
   if(!InpUseHtfTrend) return 0; // Neu tat HTF thi coi nhu trung lap

   double fastEma[], slowEma[];
   ArraySetAsSeries(fastEma, true);
   ArraySetAsSeries(slowEma, true);

   if(CopyBuffer(m_htfFastEmaHandle, 0, 0, 3, fastEma) < 3) return 0;
   if(CopyBuffer(m_htfSlowEmaHandle, 0, 0, 3, slowEma) < 3) return 0;

   // Uptrend: Fast EMA > Slow EMA va Fast EMA dang doc len
   if(fastEma[1] > slowEma[1] && fastEma[1] >= fastEma[2])
   {
      return 1;
   }
   // Downtrend: Fast EMA < Slow EMA va Fast EMA dang doc xuong
   else if(fastEma[1] < slowEma[1] && fastEma[1] <= fastEma[2])
   {
      return -1;
   }

   return 0; // Sideway / Khong ro rang
}

//+------------------------------------------------------------------+
//| KIEM TRA PULLBACK VAO VUNG GIA TRI DONG M5 (EMA 8 - 21)          |
//+------------------------------------------------------------------+
void CheckM5ValueArea(const MqlRates &bar, bool &buyZone, bool &sellZone)
{
   buyZone = false;
   sellZone = false;

   double ema8[], ema21[];
   ArraySetAsSeries(ema8, true);
   ArraySetAsSeries(ema21, true);

   if(CopyBuffer(m_m5FastEmaHandle, 0, 0, 3, ema8) < 3) return;
   if(CopyBuffer(m_m5SlowEmaHandle, 0, 0, 3, ema21) < 3) return;

   // Vung Mua: EMA8 > EMA21, va gia Low cua nen cham hoac xuyen vao khoang giua EMA8 va EMA21 (Pullback)
   if(ema8[1] >= ema21[1])
   {
      double topVal = ema8[1];
      double botVal = ema21[1];
      if(bar.low <= topVal && bar.close >= botVal)
      {
         buyZone = true;
      }
   }

   // Vung Ban: EMA8 < EMA21, va gia High cua nen cham hoac xuyen vao khoang giua EMA8 va EMA21
   if(ema8[1] <= ema21[1])
   {
      double topVal = ema21[1];
      double botVal = ema8[1];
      if(bar.high >= botVal && bar.close <= topVal)
      {
         sellZone = true;
      }
   }
}

//+------------------------------------------------------------------+
//| PHAN TICH DOUBLE BOLLINGER BANDS ZONE (CLIFF WACHTEL)            |
//+------------------------------------------------------------------+
int GetDbbZone(double price)
{
   double outerUpper[], outerLower[];
   double innerUpper[], innerLower[];
   ArraySetAsSeries(outerUpper, true);
   ArraySetAsSeries(outerLower, true);
   ArraySetAsSeries(innerUpper, true);
   ArraySetAsSeries(innerLower, true);

   if(CopyBuffer(m_bbOuterHandle, 1, 0, 2, outerUpper) < 2) return 0;
   if(CopyBuffer(m_bbOuterHandle, 2, 0, 2, outerLower) < 2) return 0;
   if(CopyBuffer(m_bbInnerHandle, 1, 0, 2, innerUpper) < 2) return 0;
   if(CopyBuffer(m_bbInnerHandle, 2, 0, 2, innerLower) < 2) return 0;

   // Buy Zone (+1 SD den +2 SD hoac tren +2 SD)
   if(price >= innerUpper[1]) return 1;

   // Sell Zone (-1 SD den -2 SD hoac duoi -2 SD)
   if(price <= innerLower[1]) return -1;

   return 0; // Neutral Zone (giua -1 SD va +1 SD)
}

//+------------------------------------------------------------------+
//| NHAN DIEN PIN BAR VANG (CHONG QUET RAU NEN - ANTI-WICK HUNT)    |
//+------------------------------------------------------------------+
void DetectPinBar(const MqlRates &bar, bool &isBullPin, bool &isBearPin)
{
   isBullPin = false;
   isBearPin = false;

   double totalRange = bar.high - bar.low;
   if(totalRange <= 0) return;

   double body = MathAbs(bar.close - bar.open);
   double upperWick = bar.high - MathMax(bar.open, bar.close);
   double lowerWick = MathMin(bar.open, bar.close) - bar.low;

   double bodyRatio = body / totalRange;
   double lowerRatio = lowerWick / totalRange;
   double upperRatio = upperWick / totalRange;

   // Bullish Pin Bar tren Vang: Rau duoi dai >= InpMinWickRatioPinBar (>= 60%), than nen <= InpMaxBodyRatioPinBar (<= 28%)
   if(lowerRatio >= InpMinWickRatioPinBar && bodyRatio <= InpMaxBodyRatioPinBar)
   {
      isBullPin = true;
   }

   // Bearish Pin Bar tren Vang: Rau tren dai >= InpMinWickRatioPinBar, than nen <= InpMaxBodyRatioPinBar
   if(upperRatio >= InpMinWickRatioPinBar && bodyRatio <= InpMaxBodyRatioPinBar)
   {
      isBearPin = true;
   }
}

//+------------------------------------------------------------------+
//| NHAN DIEN NEN ENGULFING VANG (XUNG LUC PHU DINH)                 |
//+------------------------------------------------------------------+
void DetectEngulfing(const MqlRates &cur, const MqlRates &prev, bool &isBullEngulf, bool &isBearEngulf)
{
   isBullEngulf = false;
   isBearEngulf = false;

   bool prevIsBear = (prev.close < prev.open);
   bool curIsBull  = (cur.close > cur.open);

   // Bullish Engulfing: Nen truoc giam, nen sau tang va dong cua cao hon dinh nen truoc
   if(prevIsBear && curIsBull && (cur.close > prev.open) && (cur.low <= prev.low))
   {
      isBullEngulf = true;
   }

   bool prevIsBull = (prev.close > prev.open);
   bool curIsBear  = (cur.close < cur.open);

   // Bearish Engulfing: Nen truoc tang, nen sau giam va dong cua thap hon day nen truoc
   if(prevIsBull && curIsBear && (cur.close < prev.open) && (cur.high >= prev.high))
   {
      isBearEngulf = true;
   }
}

//+------------------------------------------------------------------+
//| NHAN DIEN NEN BUT PHA DONG LUONG MANH (MOMENTUM TREND BAR)      |
//+------------------------------------------------------------------+
void DetectMomentumBar(const MqlRates &bar, double curAtr, bool &isBullMom, bool &isBearMom)
{
   isBullMom = false;
   isBearMom = false;

   double body = MathAbs(bar.close - bar.open);
   double range = bar.high - bar.low;
   if(range <= 0.0) return;

   // Nen tang manh: Than nen chiem >= 50% bien do, chieu cao >= 0.5x ATR
   if(bar.close > bar.open && (body / range >= 0.50) && (range >= curAtr * 0.50))
   {
      isBullMom = true;
   }
   // Nen giam manh: Than nen chiem >= 50% bien do, chieu cao >= 0.5x ATR
   else if(bar.close < bar.open && (body / range >= 0.50) && (range >= curAtr * 0.50))
   {
      isBearMom = true;
   }
}

//+------------------------------------------------------------------+
//| KIEM TRA CO DUOC PHEP MO HOAC NHOI LENH VANG KHONG               |
//+------------------------------------------------------------------+
bool CanExecutePyramid(ENUM_POSITION_TYPE type)
{
   int currentTypeCount = CountPositionsByType(type);
   if(currentTypeCount == 0) return true; // Chua co lenh nao cung chieu

   // Da co 1 lenh: Kiem tra dieu kien nhoi lenh
   if(!InpEnablePyramiding) return false;
   if(currentTypeCount >= InpMaxPositionsTotal) return false;

   if(InpPyramidOnlyInProfit)
   {
      double point = m_symbol.Point();
      double curPrice = (type == POSITION_TYPE_BUY) ? m_symbol.Bid() : m_symbol.Ask();

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(!m_position.SelectByIndex(i)) continue;
         if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;
         if(m_position.PositionType() == type)
         {
            double openPrice = m_position.PriceOpen();
            double sl        = m_position.StopLoss();
            double initRisk  = MathAbs(openPrice - sl);
            if(initRisk <= 0) initRisk = 180 * point;

            double profitDiff = (type == POSITION_TYPE_BUY) ? (curPrice - openPrice) : (openPrice - curPrice);
            if(profitDiff < (initRisk * InpPyramidMinProfitR))
            {
               return false;
            }
         }
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| DONG BO STOP LOSS TAT CA CAC LENH CU VE MOC HOA VON              |
//+------------------------------------------------------------------+
void SyncAllStopLoss(ENUM_POSITION_TYPE type, double newSl)
{
   double point = m_symbol.Point();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;
      if(m_position.PositionType() != type) continue;

      ulong ticket = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double curSl = m_position.StopLoss();
      double curTp = m_position.TakeProfit();

      if(type == POSITION_TYPE_BUY)
      {
         double safeBe = NormalizeDouble(openPrice + InpBreakEvenOffsetPts * point, _Digits);
         // Dong bo ve SL moi cua lenh nhoi hoac it nhat la moc Hoa von (Break-even)
         double targetSl = (newSl > 0.0) ? MathMax(safeBe, newSl) : safeBe;
         targetSl = MathMax(targetSl, curSl);
         if(curSl < targetSl)
         {
            m_trade.PositionModify(ticket, targetSl, curTp);
            PrintFormat(">> [SYNC SL BUY VANG] Da dong bo SL ticket %I64u len moc: %.2f (BE: %.2f | NewSL: %.2f)",
                        ticket, targetSl, safeBe, newSl);
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double safeBe = NormalizeDouble(openPrice - InpBreakEvenOffsetPts * point, _Digits);
         // Dong bo ve SL moi cua lenh nhoi hoac it nhat la moc Hoa von (Break-even)
         double targetSl = (newSl > 0.0) ? MathMin(safeBe, newSl) : safeBe;
         targetSl = (curSl == 0.0) ? targetSl : MathMin(targetSl, curSl);
         if(curSl > targetSl || curSl == 0.0)
         {
            m_trade.PositionModify(ticket, targetSl, curTp);
            PrintFormat(">> [SYNC SL SELL VANG] Da dong bo SL ticket %I64u xuong moc: %.2f (BE: %.2f | NewSL: %.2f)",
                        ticket, targetSl, safeBe, newSl);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| DEM SO VI THE DANG MO THEO CHIEU (BUY HOAC SELL)                 |
//+------------------------------------------------------------------+
int CountPositionsByType(ENUM_POSITION_TYPE type)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
      {
         if(m_position.PositionType() == type) count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| THUC THI LENH BUY / SELL CHO VÀNG                                |
//+------------------------------------------------------------------+
void ExecuteOrder(ENUM_POSITION_TYPE posType, const MqlRates &lastBar, double curAtr, bool isPyramidEntry)
{
   double point = m_symbol.Point();
   double ask   = m_symbol.Ask();
   double bid   = m_symbol.Bid();

   double slDistancePoints = 0.0;
   double slPrice = 0.0;
   double tpPrice = 0.0;
   double entryPrice = 0.0;

   string comment = isPyramidEntry ? "QuantumGold_Pyramid" : InpTradeComment;

   if(posType == POSITION_TYPE_BUY)
   {
      entryPrice = ask;
      // SL tinh theo ATR hoac day nen Pin Bar cong them Gold Buffer Points ($0.25 dem)
      double slByAtr = curAtr * InpAtrMultiplierSL / point;
      double slByBar = (entryPrice - lastBar.low) / point + InpGoldBufferPoints;

      slDistancePoints = MathMax(slByAtr, slByBar);
      // Kep trong nguong min/max an toan cua Vang
      slDistancePoints = MathMax(slDistancePoints, (double)InpMinSlPoints);
      slDistancePoints = MathMin(slDistancePoints, (double)InpMaxSlPoints);

      slPrice = NormalizeDouble(entryPrice - slDistancePoints * point, _Digits);
      tpPrice = NormalizeDouble(entryPrice + (slDistancePoints * InpRiskRewardRatio) * point, _Digits);

      double lot = CalculateOrderLot(slDistancePoints);

      if(m_trade.Buy(lot, _Symbol, entryPrice, slPrice, tpPrice, comment))
      {
         m_lastEntryTime  = TimeCurrent();
         ulong posTicket = m_trade.ResultOrder();
         if(posTicket > 0) SetPosRiskRecord(posTicket, slDistancePoints);

         m_lastSignalDesc = StringFormat("%s BUY VÀNG KHỚP: Lot %.2f @ %.2f (SL: %.2f | TP: %.2f)",
                                         (isPyramidEntry ? "[NHỒI]" : "[MỞ]"), lot, entryPrice, slPrice, tpPrice);
         m_signalColor    = clrLimeGreen;
         PrintFormat(">>> [%s GOLD BUY] Lot: %.2f | Gia: %.2f | SL: %.2f | TP: %.2f (Risk: %.1f pts)", 
                     (isPyramidEntry ? "NHOI LENH" : "MO LENH"), lot, entryPrice, slPrice, tpPrice, slDistancePoints);

         if(isPyramidEntry && InpSyncStopLossOnPyramid)
         {
            SyncAllStopLoss(POSITION_TYPE_BUY, slPrice);
         }
      }
      else
      {
         PrintFormat("[LOI] Khong the vao lenh BUY Vang: %s", m_trade.ResultRetcodeDescription());
      }
   }
   else if(posType == POSITION_TYPE_SELL)
   {
      entryPrice = bid;
      double slByAtr = curAtr * InpAtrMultiplierSL / point;
      double slByBar = (lastBar.high - entryPrice) / point + InpGoldBufferPoints;

      slDistancePoints = MathMax(slByAtr, slByBar);
      slDistancePoints = MathMax(slDistancePoints, (double)InpMinSlPoints);
      slDistancePoints = MathMin(slDistancePoints, (double)InpMaxSlPoints);

      slPrice = NormalizeDouble(entryPrice + slDistancePoints * point, _Digits);
      tpPrice = NormalizeDouble(entryPrice - (slDistancePoints * InpRiskRewardRatio) * point, _Digits);

      double lot = CalculateOrderLot(slDistancePoints);

      if(m_trade.Sell(lot, _Symbol, entryPrice, slPrice, tpPrice, comment))
      {
         m_lastEntryTime  = TimeCurrent();
         ulong posTicket = m_trade.ResultOrder();
         if(posTicket > 0) SetPosRiskRecord(posTicket, slDistancePoints);

         m_lastSignalDesc = StringFormat("%s SELL VÀNG KHỚP: Lot %.2f @ %.2f (SL: %.2f | TP: %.2f)",
                                         (isPyramidEntry ? "[NHỒI]" : "[MỞ]"), lot, entryPrice, slPrice, tpPrice);
         m_signalColor    = clrTomato;
         PrintFormat(">>> [%s GOLD SELL] Lot: %.2f | Gia: %.2f | SL: %.2f | TP: %.2f (Risk: %.1f pts)", 
                     (isPyramidEntry ? "NHOI LENH" : "MO LENH"), lot, entryPrice, slPrice, tpPrice, slDistancePoints);

         if(isPyramidEntry && InpSyncStopLossOnPyramid)
         {
            SyncAllStopLoss(POSITION_TYPE_SELL, slPrice);
         }
      }
      else
      {
         PrintFormat("[LOI] Khong the vao lenh SELL Vang: %s", m_trade.ResultRetcodeDescription());
      }
   }
}

//+------------------------------------------------------------------+
//| TINH TOAN KHOI LUONG LOT AN TOAN CHO VÀNG CHUAN ECN              |
//+------------------------------------------------------------------+
double CalculateOrderLot(double slDistancePoints)
{
   if(InpSizingMode == SIZING_FIXED_LOT)
   {
      return NormalizeLot(InpFixedLotSize);
   }

   double balance = m_account.Balance();
   double equity  = m_account.Equity();
   double capital = MathMin(balance, equity);

   double riskMoney = capital * (InpRiskPercent / 100.0);

   double tickSize  = m_symbol.TickSize();
   double tickValue = m_symbol.TickValue();
   double point     = m_symbol.Point();

   if(slDistancePoints <= 0 || tickSize <= 0 || tickValue <= 0 || point <= 0)
   {
      return m_symbol.LotsMin();
   }

   double lossPerLot = (slDistancePoints * point / tickSize) * tickValue;
   if(lossPerLot <= 0) return m_symbol.LotsMin();

   double rawLot = riskMoney / lossPerLot;
   return NormalizeLot(rawLot);
}

//+------------------------------------------------------------------+
//| CHUAN HOA LOT THEO DUNG QUY CHUAN SAN CHO VANG                   |
//+------------------------------------------------------------------+
double NormalizeLot(double rawLot)
{
   double step = m_symbol.LotsStep();
   double minLot = MathMax(m_symbol.LotsMin(), InpMinLotAllowed);
   double maxLot = MathMin(m_symbol.LotsMax(), InpMaxLotAllowed);

   double lot = MathFloor(rawLot / step) * step;
   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;

   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| QUAN LY CAC VI THE VANG (BREAK-EVEN, DUAL-TP, TRAILING STOP)     |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   double point = m_symbol.Point();
   double bid   = m_symbol.Bid();
   double ask   = m_symbol.Ask();

   // Lay ATR cho Trailing
   double atr[];
   ArraySetAsSeries(atr, true);
   double curAtr = 0.0;
   if(CopyBuffer(m_atrHandle, 0, 0, 2, atr) >= 2)
   {
      curAtr = atr[1];
   }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      ulong  ticket    = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double curSl     = m_position.StopLoss();
      double curTp     = m_position.TakeProfit();
      double volume    = m_position.Volume();
      ENUM_POSITION_TYPE type = m_position.PositionType();

      // Tinh Initial Risk chuan xac tu struct bo nho hoac TakeProfit goc (VÁ TRIỆT ĐỂ LỖI C)
      double initialRiskPts = GetPosInitialRiskPts(ticket, openPrice, curTp, curSl, curAtr);
      if(initialRiskPts <= 0.0) initialRiskPts = 350.0;

      // 1. XU LY CHO LENH BUY VANG
      if(type == POSITION_TYPE_BUY)
      {
         double profitPoints = (bid - openPrice) / point;
         double profitR      = profitPoints / initialRiskPts;

         // A. CHOT LOI TUNG PHAN (PARTIAL CLOSE DUAL-TP CHO VANG) - Chi chot 1 lan duy nhat
         if(InpUsePartialClose && !IsPosTp1Closed(ticket) && profitR >= InpPartialCloseAtR && volume > m_symbol.LotsMin())
         {
            double closeVol = NormalizeLot(volume * (InpPartialClosePercent / 100.0));
            if(closeVol >= m_symbol.LotsMin() && (volume - closeVol) >= m_symbol.LotsMin())
            {
               if(m_trade.PositionClosePartial(ticket, closeVol))
               {
                  MarkPosTp1Closed(ticket);
                  PrintFormat(">> [GOLD DUAL-TP1 BUY] Da chot 50%% volume (%.2f lot) tai +%.1fR!", closeVol, profitR);
               }
            }
         }

         // B. AUTO BREAK-EVEN (HOA VON SIEU TOC CHO VANG)
         if(InpUseAutoBreakEven && profitR >= InpBreakEvenTriggerR)
         {
            double safeBe = NormalizeDouble(openPrice + InpBreakEvenOffsetPts * point, _Digits);
            if(curSl < safeBe || curSl == 0.0)
            {
               m_trade.PositionModify(ticket, safeBe, curTp);
               PrintFormat(">> [GOLD AUTO BREAK-EVEN BUY] Da khoa SL Vang len hoa von + offset: %.2f", safeBe);
            }
         }

         // C. MICRO-ATR TRAILING STOP CHO VANG
         if(InpUseTrailingStop && profitR >= InpTrailingStartR && curAtr > 0.0)
         {
            double trailDist = curAtr * InpTrailingDistanceATR;
            double targetSl  = NormalizeDouble(bid - trailDist, _Digits);
            double stepDist  = InpTrailingStepPts * point;

            if(targetSl > (curSl + stepDist) && targetSl > openPrice)
            {
               m_trade.PositionModify(ticket, targetSl, curTp);
            }
         }
      }
      // 2. XU LY CHO LENH SELL VANG
      else if(type == POSITION_TYPE_SELL)
      {
         double profitPoints = (openPrice - ask) / point;
         double profitR      = profitPoints / initialRiskPts;

         // A. CHOT LOI TUNG PHAN (PARTIAL CLOSE DUAL-TP CHO VANG) - Chi chot 1 lan duy nhat
         if(InpUsePartialClose && !IsPosTp1Closed(ticket) && profitR >= InpPartialCloseAtR && volume > m_symbol.LotsMin())
         {
            double closeVol = NormalizeLot(volume * (InpPartialClosePercent / 100.0));
            if(closeVol >= m_symbol.LotsMin() && (volume - closeVol) >= m_symbol.LotsMin())
            {
               if(m_trade.PositionClosePartial(ticket, closeVol))
               {
                  MarkPosTp1Closed(ticket);
                  PrintFormat(">> [GOLD DUAL-TP1 SELL] Da chot 50%% volume (%.2f lot) tai +%.1fR!", closeVol, profitR);
               }
            }
         }

         // B. AUTO BREAK-EVEN (HOA VON SIEU TOC CHO VANG)
         if(InpUseAutoBreakEven && profitR >= InpBreakEvenTriggerR)
         {
            double safeBe = NormalizeDouble(openPrice - InpBreakEvenOffsetPts * point, _Digits);
            if(curSl > safeBe || curSl == 0.0)
            {
               m_trade.PositionModify(ticket, safeBe, curTp);
               PrintFormat(">> [GOLD AUTO BREAK-EVEN SELL] Da khoa SL Vang len hoa von - offset: %.2f", safeBe);
            }
         }

         // C. MICRO-ATR TRAILING STOP CHO VANG
         if(InpUseTrailingStop && profitR >= InpTrailingStartR && curAtr > 0.0)
         {
            double trailDist = curAtr * InpTrailingDistanceATR;
            double targetSl  = NormalizeDouble(ask + trailDist, _Digits);
            double stepDist  = InpTrailingStepPts * point;

            if((curSl == 0.0 || targetSl < (curSl - stepDist)) && targetSl < openPrice)
            {
               m_trade.PositionModify(ticket, targetSl, curTp);
            }
         }
      }
   }

   // Don dep ve cac vi the da dong khoi bo nho quan ly
   CleanClosedPosRecords();
}

//+------------------------------------------------------------------+
//| KIEM TRA RESET NAY VA LA CHAN BAO VE SO DU                       |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   datetime now = TimeCurrent();
   MqlDateTime dtNow, dtReset;
   TimeToStruct(now, dtNow);
   TimeToStruct(m_lastDailyResetTime, dtReset);

   if(dtNow.day != dtReset.day)
   {
      m_dailyStartEquity     = m_account.Equity();
      m_lastDailyResetTime   = now;
      m_dailyShieldTriggered = false;
      m_tradesTodayCount     = 0;
      m_winsTodayCount       = 0;
      m_profitToday          = 0.0;
      Print(">>> [DAILY RESET] Bat dau ngay giao dich moi tren Vang, reset Daily Equity Shield.");
   }

   // Tinh muc sut giam trong ngay
   double currentEquity = m_account.Equity();
   if(m_dailyStartEquity > 0)
   {
      double ddPercent = (m_dailyStartEquity - currentEquity) / m_dailyStartEquity * 100.0;
      if(ddPercent >= InpMaxDailyLossPercent)
      {
         m_dailyShieldTriggered = true;
         PrintFormat(">>> [CANH BAO NGUY HIEM] Chạm giới hạn lỗ ngày tren Vang (%.2f%% >= %.2f%%). KHOA GIAO DICH MOI!",
                     ddPercent, InpMaxDailyLossPercent);
      }
   }
}

//+------------------------------------------------------------------+
//| CAP NHAT THONG KE GIAO DICH TRONG NGAY                           |
//+------------------------------------------------------------------+
void UpdateStatistics()
{
   datetime dayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE) + " 00:00");
   if(HistorySelect(dayStart, TimeCurrent()))
   {
      int deals = HistoryDealsTotal();
      int trades = 0;
      int wins = 0;
      double totalProfit = 0.0;

      for(int i = 0; i < deals; i++)
      {
         ulong dealTicket = HistoryDealGetTicket(i);
         if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol) continue;
         if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != InpMagicNumber) continue;

         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
         if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
         {
            trades++;
            double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
            totalProfit += profit;
            if(profit > 0) wins++;
         }
      }

      m_tradesTodayCount = trades;
      m_winsTodayCount   = wins;
      m_profitToday      = totalProfit;
   }
}

//+------------------------------------------------------------------+
//| KIEM TRA GIO GIAO DICH VANG (LONDON / NY HIGH LIQUIDITY)         |
//+------------------------------------------------------------------+
bool IsTradingAllowedTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // Tranh toi thu Sau
   if(InpAvoidFridayEvening && dt.day_of_week == 5 && dt.hour >= 19)
   {
      return false;
   }

   if(dt.hour < InpTradingStartHour || dt.hour >= InpTradingEndHour)
   {
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| LAY TEN PHIEN GIAO DICH HIEN TAI DUA TREN GIO SERVER             |
//+------------------------------------------------------------------+
string GetCurrentSessionName()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.hour < InpAsianEndHour)
   {
      return "Phiên Á (Tokyo/Asian)";
   }
   else if(dt.hour < InpLondonEndHour)
   {
      return "Phiên Âu (London)";
   }
   else if(dt.hour < InpNewYorkEndHour)
   {
      return "Phiên Mỹ (New York)";
   }
   return "Phiên Đêm (Off-hours / Giãn spread)";
}

//+------------------------------------------------------------------+
//| KIEM TRA VA PHAT THONG BAO KHI KET THUC MOI PHIEN GIAO DICH      |
//+------------------------------------------------------------------+
void CheckSessionEndNotification()
{
   if(!InpNotifySessionEnd) return;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // Chi kiem tra o dau gio (phut thu 0 cua gio ket thuc phien)
   if(dt.min != 0) return;

   int sessionKey = dt.day_of_year * 100 + dt.hour;
   if(sessionKey == m_lastReportedSessionHour) return;

   string sessionName = "";
   string sessionDesc = "";
   string nextSession = "";

   // 1. Phien Chieu Thu Sau (Dong tuan tranh Gap gia qua dem)
   if(InpAvoidFridayEvening && dt.day_of_week == 5 && dt.hour == 19)
   {
      sessionName = "KẾT THÚC TUẦN GIAO DỊCH (THỨ SÁU 19:00)";
      sessionDesc = "Thị trường chuẩn bị đóng cửa cuối tuần. Nghỉ ngơi bảo toàn vốn và lợi nhuận, tránh Gap giá thứ Hai!";
      nextSession = "Mở cửa tuần mới lúc 00:00 sáng Thứ Hai";
   }
   // 2. Ket thuc Phien A (Asian Session)
   else if(dt.hour == InpAsianEndHour)
   {
      sessionName = "KẾT THÚC PHIÊN Á (ASIAN SESSION CLOSE)";
      sessionDesc = "Phiên Á hoàn tất tích lũy & quét thanh khoản. Chuẩn bị đón sóng bùng nổ của Phiên London sôi động!";
      nextSession = "Phiên Âu (London Session)";
   }
   // 3. Ket thuc Phien Au (London Session)
   else if(dt.hour == InpLondonEndHour)
   {
      sessionName = "KẾT THÚC PHIÊN ÂU (LONDON SESSION CLOSE)";
      sessionDesc = "Phiên London khép lại. Dòng tiền chuyển dịch sang đỉnh điểm biến động của Phiên Mỹ (New York)!";
      nextSession = "Phiên Mỹ (New York Session)";
   }
   // 4. Ket thuc Phien My (New York Session) hoac het gio trade bot
   else if(dt.hour == InpNewYorkEndHour || (InpUseTimeFilter && dt.hour == InpTradingEndHour))
   {
      sessionName = "KẾT THÚC PHIÊN MỸ (NEW YORK SESSION CLOSE)";
      sessionDesc = "Kết thúc phiên giao dịch chính trong ngày. Thị trường chuyển sang phiên đêm thanh khoản mỏng, giãn spread!";
      nextSession = "Phiên Á rạng sáng mai";
   }

   if(sessionName == "") return;

   // Danh dau da thong bao cho gio nay de khong bao lap lai
   m_lastReportedSessionHour = sessionKey;

   // Thu thap so lieu hieu suat tong hop
   double winRate = (m_tradesTodayCount > 0) ? ((double)m_winsTodayCount / m_tradesTodayCount * 100.0) : 0.0;
   int openOrders = CountOpenPositions();
   double curBid  = m_symbol.Bid();
   long curSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   // Soan thong bao MT5 Alert
   string alertMsg = StringFormat("🔔 [QUANTUMPULSE GOLD] %s!\n"
                                  "⏰ Giờ Server: %02d:00 | Giá Vàng: %.2f | Spread: %d pts\n"
                                  "📊 Tổng kết hôm nay: %d lệnh | Thắng: %d (%.0f%%) | PnL: $%.2f\n"
                                  "📍 Vị thế đang chạy: %d/%d lệnh\n"
                                  "⏭ Tiếp theo: %s\n"
                                  "💡 Lưu ý: %s",
                                  sessionName, dt.hour, curBid, curSpread,
                                  m_tradesTodayCount, m_winsTodayCount, winRate, m_profitToday,
                                  openOrders, InpMaxPositionsTotal, nextSession, sessionDesc);

   // 1. Phat Alert Pop-up am thanh tren MT5
   Alert(alertMsg);

   // 2. Ghi nhat ky ro rang vao tab Experts
   Print("================================================================================");
   PrintFormat(">>> [THÔNG BÁO HẾT PHIÊN] %s (Lúc %02d:00 GMT Server)", sessionName, dt.hour);
   PrintFormat("    Giá Vàng (Bid): %.2f | Spread hiện tại: %d pts | Vị thế đang mở: %d/%d", 
               curBid, curSpread, openOrders, InpMaxPositionsTotal);
   PrintFormat("    Thống kê hôm nay: Tổng %d lệnh | Thắng %d lệnh (Win Rate: %.1f%%) | Lợi nhuận PnL: $%.2f",
               m_tradesTodayCount, m_winsTodayCount, winRate, m_profitToday);
   PrintFormat("    Tiếp theo: %s | %s", nextSession, sessionDesc);
   Print("================================================================================");

   // 3. Gui Push Notification ve ung dung MT5 di dong (neu duoc bat)
   if(InpSendPushOnSessionEnd)
   {
      string pushMsg = StringFormat("[QuantumPulse Gold] %s! Gia: %.2f | PnL: $%.2f (%d/%d Win) | Vi the: %d lenh",
                                    sessionName, curBid, m_profitToday, m_winsTodayCount, m_tradesTodayCount, openOrders);
      SendNotification(pushMsg);
   }
}

//+------------------------------------------------------------------+
//| DEM TONG SO VI THE DANG MO CUA BOT                               |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
      {
         count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| KIEM TRA LENH CU DANG MO CO LAI HAY KHONG                        |
//+------------------------------------------------------------------+
bool IsExistingPositionProfitable()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
      {
         return (m_position.Profit() > 0.0);
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| VE DASHBOARD HUD SIÊU ĐẸP & CHUYÊN NGHIỆP DÀNH CHO VÀNG          |
//+------------------------------------------------------------------+
void DrawDashboard()
{
   string prefix = "QP_";
   int startX = 20;
   int startY = 30;
   int rowHeight = 22;
   int row = 0;

   // 1. Background Box (Sắc màu Dark Gold sang trọng)
   CreateOrUpdateRect(prefix + "BG", startX - 8, startY - 8, 330, 365, C'24,22,18', 1);

   // 2. Title Header
   CreateOrUpdateLabel(prefix + "Title", "⚡ QUANTUMPULSE - GOLD SCALPER v2.0", startX, startY + (row++ * rowHeight), clrGold, 11, true);
   CreateOrUpdateLabel(prefix + "Sub", "Momentum Gold Scalper (XAUUSD ~1 Trade/Hour)", startX, startY + (row++ * rowHeight), clrKhaki, 8, false);

   // 3. Tai khoan
   string accText = StringFormat("Balance: $%.2f | Equity: $%.2f", m_account.Balance(), m_account.Equity());
   CreateOrUpdateLabel(prefix + "Acc", accText, startX, startY + (row++ * rowHeight), clrWhite, 9, false);

   // 4. Spread & ECN State cho Vang
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   color spColor = (spread <= InpMaxSpreadPoints) ? clrSpringGreen : clrRed;
   string spreadText = StringFormat("Spread Vàng: %d pts (Max: %d) | Giá: %.2f", spread, InpMaxSpreadPoints, m_symbol.Bid());
   CreateOrUpdateLabel(prefix + "Spread", spreadText, startX, startY + (row++ * rowHeight), spColor, 9, false);

   // 5. Xu huong HTF (H1)
   int htf = GetHtfTrend();
   string htfDesc = (htf == 1) ? "TĂNG (Bullish Uptrend)" : (htf == -1 ? "GIẢM (Bearish Downtrend)" : "ĐI NGANG (Neutral)");
   color htfColor = (htf == 1) ? clrLimeGreen : (htf == -1 ? clrTomato : clrGold);
   CreateOrUpdateLabel(prefix + "Trend", "HTF Trend (H1): " + htfDesc, startX, startY + (row++ * rowHeight), htfColor, 9, true);

   // 6. Cadence Cooldown Status
   datetime now = TimeCurrent();
   int cooldownSec = InpMinCooldownMinutes * 60;
   int passedSec = (m_lastEntryTime > 0) ? (int)(now - m_lastEntryTime) : cooldownSec;
   string cdText = "";
   color cdColor = clrLightGreen;
   if(passedSec < cooldownSec)
   {
      int remainMins = (cooldownSec - passedSec) / 60;
      cdText = StringFormat("Cadence: Cooldown còn %d phút (~1h/lệnh)", remainMins);
      cdColor = clrGold;
   }
   else
   {
      cdText = "Cadence: SẴN SÀNG QUÉT SÓNG VÀNG";
      cdColor = clrSpringGreen;
   }
   CreateOrUpdateLabel(prefix + "Cadence", cdText, startX, startY + (row++ * rowHeight), cdColor, 9, false);

   // 7. Vi the Vang dang mo
   int openCount = CountOpenPositions();
   string posText = StringFormat("Vị thế Vàng: %d / %d lệnh", openCount, InpMaxPositionsTotal);
   CreateOrUpdateLabel(prefix + "Pos", posText, startX, startY + (row++ * rowHeight), clrWhite, 9, false);

   // 8. Phien giao dich & Chuong thong bao
   string sessionInfo = StringFormat("Phiên: %s %s", GetCurrentSessionName(), InpNotifySessionEnd ? "(Chuông 🔔)" : "(Tắt 🔕)");
   CreateOrUpdateLabel(prefix + "Session", sessionInfo, startX, startY + (row++ * rowHeight), clrGold, 9, false);

   // 8. Hieu suat hom nay
   double winRate = (m_tradesTodayCount > 0) ? ((double)m_winsTodayCount / m_tradesTodayCount * 100.0) : 0.0;
   string statText = StringFormat("Hôm nay: %d lệnh | Thắng: %d (%.0f%%) | PnL: $%.2f",
                                  m_tradesTodayCount, m_winsTodayCount, winRate, m_profitToday);
   color pnlCol = (m_profitToday >= 0) ? clrLimeGreen : clrCrimson;
   CreateOrUpdateLabel(prefix + "Stat", statText, startX, startY + (row++ * rowHeight), pnlCol, 9, false);

   // 9. Daily Shield Status
   string shieldText = m_dailyShieldTriggered ? "SHIELD: ĐÃ KHÓA (Chạm giới hạn lỗ)" : "SHIELD: AN TOÀN (Active)";
   color shieldColor = m_dailyShieldTriggered ? clrRed : clrMediumSeaGreen;
   CreateOrUpdateLabel(prefix + "Shield", shieldText, startX, startY + (row++ * rowHeight), shieldColor, 9, true);

   // 10. Tin tuc USD MQL5 Calendar
   color newsColor = m_isNewsRestricted ? clrRed : clrLightGreen;
   CreateOrUpdateLabel(prefix + "News", "Tin đỏ USD: " + m_newsStatusText, startX, startY + (row++ * rowHeight), newsColor, 8, m_isNewsRestricted);

   // 11. Trạng thái tín hiệu hiện tại
   CreateOrUpdateLabel(prefix + "SigLabel", "Radar Sóng Vàng:", startX, startY + (row++ * rowHeight), clrSilver, 8, false);
   CreateOrUpdateLabel(prefix + "Signal", m_lastSignalDesc, startX, startY + (row++ * rowHeight), m_signalColor, 9, true);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| HELPER VE LABEL                                                  |
//+------------------------------------------------------------------+
void CreateOrUpdateLabel(string name, string text, int x, int y, color clr, int fontSize, bool isBold)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, isBold ? "Segoe UI Bold" : "Segoe UI");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| HELPER VE RECTANGLE LABEL (PANEL BACKGROUND)                     |
//+------------------------------------------------------------------+
void CreateOrUpdateRect(string name, int x, int y, int width, int height, color bgClr, int border)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgClr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, C'65,55,30');
}
//+------------------------------------------------------------------+
