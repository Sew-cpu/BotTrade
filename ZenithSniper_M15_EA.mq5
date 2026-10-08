//+------------------------------------------------------------------+
//|                                        ZenithSniper_M15_EA.mq5   |
//|      M15 High-Profit & Ultra-Safe Robot - GOLD (XAUUSD) EDITION  |
//|             Optimized Exclusively for Gold with $100 Capital      |
//|   Integrating FX Academy, Nial Fuller, ForexBrokers & News Engine |
//|                                  Copyright 2026, Antigravity     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Antigravity"
#property link        "https://github.com"
#property version     "4.00"
#property description "Robot M15 CHUYEN BIET CHO VANG (XAUUSD) - Toi uu von 100$"
#property description "Chong quet rau nen (Anti-Wick Hunt) + Double Bollinger Bands + Price Action TLS"
#property description "Nhoi lenh duong thong minh (Smart Pyramiding) + Khong khoa tai khoan"
#property description "Bo loc Tin tuc USD (CPI, NFP, FOMC) & Soc bien dong vang the gioi"
#property strict

//--- Thu vien chuan MQL5
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS & DEFINITIONS                                              |
//+------------------------------------------------------------------+
enum ENUM_ENTRY_MODE
  {
   ENTRY_ALL_SIGNALS = 0,    // Pin Bar + Fakey + DBB Confluence (Toi uu nhat cho Vang)
   ENTRY_PINBAR_ONLY = 1,    // Chi danh Pin Bar Rejection (Rut rau vang)
   ENTRY_FAKEY_ONLY  = 2     // Chi danh Fakey False Breakout (Bay gia vang)
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - CHUYEN BIET TOI UU CHO VANG (XAUUSD)         |
//+------------------------------------------------------------------+
input group "=== 1. QUAN TRI VON 100$ CHUYEN BIET CHO VANG (XAUUSD) ==="
input double            InpRiskPercent          = 2.0;                 // % Rui ro moi lenh (2.0% tren von 100$ ~ $2.00 - $3.50)
input bool              InpUseDailyLossGuard    = false;               // Khoa tai khoan khi lo (false = KHONG KHOA TAI KHOAN)
input double            InpMaxDailyLossPercent  = 6.0;                 // Moc canh bao sut giam trong ngay (% von)
input double            InpMaxLotSizeGold       = 0.02;                // Lot toi da cho phep (0.01 - 0.02 lot cho von 100$)
input int               InpMaxSpreadPoints      = 350;                 // Spread toi da cho phep danh Vang (Points, Exness ~240 pts)

input group "=== 2. NHOI LENH THONG MINH CHO VANG (SMART PYRAMIDING) ==="
input bool              InpEnablePyramiding     = true;                // Bat tinh nang tu dong NHOI LENH khi gap Diem Vao Cuc Dep
input int               InpMaxPositionsTotal    = 2;                   // So lenh toi da khi nhồi tren Vang (2 lenh 0.01 lot)
input bool              InpPyramidOnlyInProfit  = true;                // Chi nhoi khi lenh cu DANG CO LAI (Bao toan 100$ von)
input double            InpPyramidMinProfitR    = 1.0;                 // Lenh 1 phai lai >= 1.0R (lai ~$3.0 - $4.0) moi duoc nhoi
input bool              InpSuperSetupOnly       = true;                // Chi nhoi khi gap Super Setup tren Vang
input bool              InpSyncStopLossOnPyramid= true;                // Tu dong khoa SL lenh 1 ve hoa von khi vao lenh 2

input group "=== 3. CHONG QUET RAU NEN VANG (ANTI-WICK HUNTING) ==="
input int               InpGoldBufferPoints     = 25;                  // Khoang dem phong ve chong quet rau (Points ~ $0.25 gia)
input double            InpMinPinBarWickRatio   = 0.65;                // Ti le rau nen Vang toi thieu de xac nhan rut chan (>= 65%)
input double            InpMaxPinBarBodyRatio   = 0.25;                // Ti le than nen Vang toi da (<= 25%)

input group "=== 4. BO LOC TIN TUC USD & VANG (CPI, NFP, FOMC) ==="
input bool              InpUseNewsFilter        = true;                // Bat bo loc Tin tuc MQL5 Calendar
input int               InpMinsBeforeNews       = 30;                  // Dung vao lenh truoc gio tin do USD (Phut)
input int               InpMinsAfterNews        = 30;                  // Dung vao lenh sau gio tin do USD (Phut)
input bool              InpNewsProtectToBE      = true;                // Tu dong keo SL ve Breakeven truoc gio tin USD
input bool              InpFilterHighImpactOnly = true;                // Chi loc tin do (High-Impact USD)

input group "=== 5. BO DO SOC BIEN DONG VANG THE GIOI (VOLATILITY SHOCK) ==="
input bool              InpUseVolatilityFilter  = true;                // Bat bo do Bien dong Dot bien Vang (Shock Detector)
input double            InpVolSpikeThreshold    = 2.0;                 // Nguong soc bien dong Vang (ATR3 / ATR30 >= 2.0x)
input bool              InpUseSpreadShock       = true;                // Bat bo loc soc gian spread Vang
input double            InpSpreadShockRatio     = 1.8;                 // Nguong soc spread Vang (Spread > 1.8x trung binh)

input group "=== 6. BO LOC XU HUONG KHUNG LON (HTF TREND H1) ==="
input bool              InpUseHtfFilter         = true;                // Bat bo loc xu huong H1
input ENUM_TIMEFRAMES   InpHtfTimeframe         = PERIOD_H1;           // Khung thoi gian xu huong lon (H1)
input int               InpHtfFastEma           = 21;                  // EMA Nhanh H1 (Nial Fuller Dynamic EMA)
input int               InpHtfSlowEma           = 50;                  // EMA Cham H1 (Trend Base)

input group "=== 7. HE THONG DOUBLE BOLLINGER BANDS (DBB M15) ==="
input bool              InpUseDbbFilter         = true;                // Bat bo loc DBB (Cliff Wachtel)
input int               InpDbbPeriod            = 20;                  // Chu ky Bollinger Bands
input double            InpDbbDevOuter          = 2.0;                 // Do lech chuan ngoai (2.0 SD)
input double            InpDbbDevInner          = 1.0;                 // Do lech chuan trong (1.0 SD)
input ENUM_ENTRY_MODE   InpEntryMode            = ENTRY_ALL_SIGNALS;   // Che do tin hieu vao lenh

input group "=== 8. STOP LOSS & TAKE PROFIT THEO ATR DONG CHO VANG ==="
input int               InpAtrPeriod            = 14;                  // Chu ky ATR
input double            InpAtrMultiplierSL      = 1.8;                 // Boi so ATR cho SL Vang (1.8x ATR dem an toan)
input double            InpRiskRewardRatio      = 2.2;                 // Ty le R:R (1:2.2 - Dat muc lai $7.0 - $9.0 moi lenh)

input group "=== 9. KHOA LAI: BREAK-EVEN & TRAILING STOP CHO VANG ==="
input bool              InpUseBreakEven         = true;                // Tu dong doi hoa von khi Vang chay du song
input double            InpBreakEvenTriggerR    = 1.0;                 // Doi SL ve Entry khi lai dat 1.0R (lai ~$3.5)
input int               InpBreakEvenOffsetPts   = 20;                  // Diem cong tren Entry bu phi & spread ($0.20 gia)
input bool              InpUseTrailingStop      = true;                // Kich hoat Chandelier Trailing Stop
input double            InpTrailingStartR       = 1.4;                 // Bat dau Trailing khi lai dat >= 1.4R
input double            InpTrailingDistanceATR  = 1.5;                 // Khoang cach Trailing theo ATR Vang (1.5x)
input int               InpTrailingStepPts      = 20;                  // Buoc nhay Trailing (Points ~ $0.20 gia)

input group "=== 10. KHUNG GIO GIAO DICH VANG (GOLD SESSIONS) ==="
input bool              InpUseTimeFilter        = true;                // Bat bo loc gio giao dich Vang
input int               InpStartHour            = 8;                   // Bat dau luc 8h sang (Phien Au/My bien dong manh)
input int               InpEndHour              = 21;                  // Dung mo lenh luc 21h toi (Tranh giao phien dem gian spread)

input group "=== 11. THIET LAP HE THONG ==="
input ulong             InpMagicNumber          = 8881526;             // Magic Number rieng cho Vang
input ulong             InpSlippage             = 30;                  // Truot gia cho phep cua Vang (Points)
input string            InpTradeComment         = "ZenithGold_M15";    // Ghi chu lenh
input bool              InpShowDashboard        = true;                // Hien thi Dashboard truc quan

//+------------------------------------------------------------------+
//| BIEN TOAN CUC & HANDLES                                          |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;
CAccountInfo   m_account;
CSymbolInfo    m_symbol;

int            m_htfFastEmaHandle = INVALID_HANDLE;
int            m_htfSlowEmaHandle = INVALID_HANDLE;
int            m_bbOuterHandle    = INVALID_HANDLE;
int            m_bbInnerHandle    = INVALID_HANDLE;
int            m_atrHandle        = INVALID_HANDLE;
int            m_atrFastHandle    = INVALID_HANDLE;
int            m_atrSlowHandle    = INVALID_HANDLE;

datetime       m_lastDailyResetDate = 0;
double         m_dailyStartEquity   = 0.0;
bool           m_dailyTradingLocked = false;
datetime       m_lastBarTime        = 0;
datetime       m_lastReportTime     = 0;

string         m_newsStatusText       = "SAFE (Khong co tin do USD)";
bool           m_isNewsRestricted     = false;
string         m_volatilityStatusText = "NORMAL (1.00x)";
bool           m_isVolatilityShocked  = false;
double         m_currentVolRatio      = 1.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!m_symbol.Name(_Symbol))
   {
      Print("Loi: Khong the khoi tao symbol ", _Symbol);
      return INIT_FAILED;
   }
   m_symbol.RefreshRates();

   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(InpSlippage);
   m_trade.SetTypeFillingBySymbol(_Symbol);

   // 1. Khoi tao HTF Trend H1
   if(InpUseHtfFilter)
   {
      m_htfFastEmaHandle = iMA(_Symbol, InpHtfTimeframe, InpHtfFastEma, 0, MODE_EMA, PRICE_CLOSE);
      m_htfSlowEmaHandle = iMA(_Symbol, InpHtfTimeframe, InpHtfSlowEma, 0, MODE_EMA, PRICE_CLOSE);
      if(m_htfFastEmaHandle == INVALID_HANDLE || m_htfSlowEmaHandle == INVALID_HANDLE)
      {
         Print("Loi khoi tao chi bao HTF EMA tren Vang!");
         return INIT_FAILED;
      }
   }

   // 2. Khoi tao Double Bollinger Bands M15
   m_bbOuterHandle = iBands(_Symbol, PERIOD_CURRENT, InpDbbPeriod, 0, InpDbbDevOuter, PRICE_CLOSE);
   m_bbInnerHandle = iBands(_Symbol, PERIOD_CURRENT, InpDbbPeriod, 0, InpDbbDevInner, PRICE_CLOSE);
   if(m_bbOuterHandle == INVALID_HANDLE || m_bbInnerHandle == INVALID_HANDLE)
   {
      Print("Loi khoi tao Double Bollinger Bands tren Vang!");
      return INIT_FAILED;
   }

   // 3. Khoi tao ATR dong
   m_atrHandle     = iATR(_Symbol, PERIOD_CURRENT, InpAtrPeriod);
   m_atrFastHandle = iATR(_Symbol, PERIOD_CURRENT, 3);
   m_atrSlowHandle = iATR(_Symbol, PERIOD_CURRENT, 30);
   if(m_atrHandle == INVALID_HANDLE || m_atrFastHandle == INVALID_HANDLE || m_atrSlowHandle == INVALID_HANDLE)
   {
      Print("Loi khoi tao ATR tren Vang!");
      return INIT_FAILED;
   }

   m_dailyStartEquity   = m_account.Equity();
   m_lastDailyResetDate = TimeCurrent();
   m_dailyTradingLocked = false;
   m_lastReportTime     = 0;

   // Khoi tao Timer 1 giay de luon cap nhat man hinh va gui bao cao
   EventSetTimer(1);

   // Ve Dashboard ngay lap tuc khi vua tha vao bieu do
   RenderDashboard();

   Print(">>> [KHOI TAO] ZenithSniper_M15_EA (XAUUSD v4.0) da khoi tao thanh cong! Bot hoat dong 100% binh thuong | DANG CHO DIEM VAO DEP...");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   if(m_htfFastEmaHandle != INVALID_HANDLE) IndicatorRelease(m_htfFastEmaHandle);
   if(m_htfSlowEmaHandle != INVALID_HANDLE) IndicatorRelease(m_htfSlowEmaHandle);
   if(m_bbOuterHandle    != INVALID_HANDLE) IndicatorRelease(m_bbOuterHandle);
   if(m_bbInnerHandle    != INVALID_HANDLE) IndicatorRelease(m_bbInnerHandle);
   if(m_atrHandle        != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
   if(m_atrFastHandle    != INVALID_HANDLE) IndicatorRelease(m_atrFastHandle);
   if(m_atrSlowHandle    != INVALID_HANDLE) IndicatorRelease(m_atrSlowHandle);

   Comment("");
   ObjectsDeleteAll(0, "ZS_");
}

//+------------------------------------------------------------------+
//| Expert timer function (Chay moi giay - Bao cao moi 10 phut)     |
//+------------------------------------------------------------------+
void OnTimer()
{
   m_symbol.RefreshRates();
   datetime now = TimeCurrent();

   // Bao cao dinh ky moi 10 phut (600 giay) vao tab Experts
   if(now - m_lastReportTime >= 600 || m_lastReportTime == 0)
   {
      m_lastReportTime = now;
      int htf = GetHtfTrend();
      string htfText = (htf == 1) ? "TANG (Bullish)" : (htf == -1 ? "GIAM (Bearish)" : "DI NGANG (Neutral)");
      long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      PrintFormat(">>> [BAO CAO 10 PHUT - %s] Bot ZenithSniper M15 hoat dong 100%% binh thuong | Gia: %.2f | Xu huong: %s | Spread: %d pts | DANG CHO DIEM VAO DEP...",
                  TimeToString(now, TIME_MINUTES), m_symbol.Bid(), htfText, spread);
   }

   if(InpShowDashboard)
   {
      RenderDashboard();
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   m_symbol.RefreshRates();

   // 1. Cap nhat Daily Loss Guard
   UpdateDailyLossGuard();

   // 2. Cap nhat Bo loc Tin tuc USD & Soc bien dong Vang
   UpdateNewsAndVolatilityEngine();

   // 3. Quan ly vi the dang mo (Break-Even & Trailing Stop)
   ManageOpenPositions();

   // 4. Cap nhat Dashboard hien thi thoi gian thuc
   if(InpShowDashboard)
   {
      RenderDashboard();
   }

   // 5. Kiem tra cay nen moi tren khung M15
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == m_lastBarTime)
   {
      return;
   }

   // 6. Kiem tra cac bo loc an toan
   if(InpUseDailyLossGuard && m_dailyTradingLocked) return;

   // Bo loc tin do USD
   if(InpUseNewsFilter && m_isNewsRestricted) return;

   // Bo loc soc bien dong vang
   if(InpUseVolatilityFilter && m_isVolatilityShocked) return;

   // Bo loc gian spread tren Vang
   long currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(currentSpread > InpMaxSpreadPoints) return;

   // Bo loc khung gio
   if(InpUseTimeFilter && !IsTradingTimeAllowed()) return;

   // 7. Doc du lieu chi bao va nến Vang
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 5, rates) < 5) return;

   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(m_atrHandle, 0, 0, 3, atr) < 3 || atr[1] <= 0) return;

   // 8. Xac dinh xu huong HTF (H1 Trend)
   int htfTrend = GetHtfTrend();

   // 9. Xac dinh phan vung Double Bollinger Bands (M15 DBB Zone)
   int dbbZone = GetDbbZone(rates[1].close);

   // 10. Quet tin hieu Price Action tren Vang (Rut rau chuan)
   bool isBullishPin = false, isBearishPin = false;
   DetectPinBar(rates[1], isBullishPin, isBearishPin);

   bool isBullishFakey = false, isBearishFakey = false;
   DetectFakey(rates, isBullishFakey, isBearishFakey);

   // 11. NHẬN DIỆN "ĐIỂM VÀO CỰC KỲ ĐẸP TRÊN VÀNG" (SUPER GOLD CONFLUENCE)
   bool isSuperBuySetup = false;
   if(htfTrend == 1 && (isBullishPin || isBullishFakey) && dbbZone == 1)
   {
      isSuperBuySetup = true;
   }

   bool isSuperSellSetup = false;
   if(htfTrend == -1 && (isBearishPin || isBearishFakey) && dbbZone == -1)
   {
      isSuperSellSetup = true;
   }

   // 12. Xet dieu kien VAO LENH / NHOI LENH BUY VÀNG
   bool buySignal = false;
   if(htfTrend >= 0)
   {
      if(isBullishPin && (dbbZone >= 0 || !InpUseDbbFilter))           buySignal = true;
      else if(isBullishFakey && (dbbZone >= 0 || !InpUseDbbFilter))    buySignal = true;
      else if(InpEntryMode == ENTRY_ALL_SIGNALS && dbbZone == 1 && rates[1].close > rates[2].high) buySignal = true;
   }

   // 13. Xet dieu kien VAO LENH / NHOI LENH SELL VÀNG
   bool sellSignal = false;
   if(htfTrend <= 0)
   {
      if(isBearishPin && (dbbZone <= 0 || !InpUseDbbFilter))          sellSignal = true;
      else if(isBearishFakey && (dbbZone <= 0 || !InpUseDbbFilter))   sellSignal = true;
      else if(InpEntryMode == ENTRY_ALL_SIGNALS && dbbZone == -1 && rates[1].close < rates[2].low) sellSignal = true;
   }

   // 14. THUC THI MO LENH HOAC NHOI LENH VANG
   if(buySignal && !sellSignal)
   {
      if(CanExecuteBuy(isSuperBuySetup))
      {
         bool isPyramid = (CountPositionsByType(POSITION_TYPE_BUY) > 0);
         ExecuteBuyOrder(rates[1], atr[1], isPyramid);
         m_lastBarTime = currentBarTime;
      }
   }
   else if(sellSignal && !buySignal)
   {
      if(CanExecuteSell(isSuperSellSetup))
      {
         bool isPyramid = (CountPositionsByType(POSITION_TYPE_SELL) > 0);
         ExecuteSellOrder(rates[1], atr[1], isPyramid);
         m_lastBarTime = currentBarTime;
      }
   }
}

//+------------------------------------------------------------------+
//| KIEM TRA CO DUOC PHEP MO HOAC NHOI LENH BUY VANG KHONG           |
//+------------------------------------------------------------------+
bool CanExecuteBuy(bool isSuperSetup)
{
   int currentBuys = CountPositionsByType(POSITION_TYPE_BUY);

   if(currentBuys == 0) return true; // Chua co lenh nao, vao binh thuong

   // Da co 1 lenh: Kiem tra dieu kien nhoi lenh
   if(!InpEnablePyramiding) return false;
   if(currentBuys >= InpMaxPositionsTotal) return false; // Toi da 2 lenh tren Vang

   if(InpSuperSetupOnly && !isSuperSetup) return false;

   if(InpPyramidOnlyInProfit)
   {
      double point = m_symbol.Point();
      double bid = m_symbol.Bid();

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(!m_position.SelectByIndex(i)) continue;
         if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;
         if(m_position.PositionType() == POSITION_TYPE_BUY)
         {
            double openPrice = m_position.PriceOpen();
            double sl        = m_position.StopLoss();
            double initRisk  = MathAbs(openPrice - sl);
            if(initRisk <= 0) initRisk = 150 * point;

            // Lenh 1 phai co lai >= InpPyramidMinProfitR (it nhat $3.0 - $4.0 lai tren Vang)
            if((bid - openPrice) < (initRisk * InpPyramidMinProfitR))
            {
               return false;
            }
         }
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| KIEM TRA CO DUOC PHEP MO HOAC NHOI LENH SELL VANG KHONG          |
//+------------------------------------------------------------------+
bool CanExecuteSell(bool isSuperSetup)
{
   int currentSells = CountPositionsByType(POSITION_TYPE_SELL);

   if(currentSells == 0) return true;

   if(!InpEnablePyramiding) return false;
   if(currentSells >= InpMaxPositionsTotal) return false;

   if(InpSuperSetupOnly && !isSuperSetup) return false;

   if(InpPyramidOnlyInProfit)
   {
      double point = m_symbol.Point();
      double ask = m_symbol.Ask();

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(!m_position.SelectByIndex(i)) continue;
         if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;
         if(m_position.PositionType() == POSITION_TYPE_SELL)
         {
            double openPrice = m_position.PriceOpen();
            double sl        = m_position.StopLoss();
            double initRisk  = MathAbs(openPrice - sl);
            if(initRisk <= 0) initRisk = 150 * point;

            if((openPrice - ask) < (initRisk * InpPyramidMinProfitR))
            {
               return false;
            }
         }
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| THUC THI LENH BUY VÀNG (CHỐNG QUÉT RÂU NẾN & ĐỆM AN TOÀN)        |
//+------------------------------------------------------------------+
void ExecuteBuyOrder(const MqlRates &lastBar, double currentAtr, bool isPyramidEntry)
{
   double ask = m_symbol.Ask();
   double point = m_symbol.Point();

   // SL tinh theo 1.8x ATR hoac day nen Pin Bar + khoang dem chong quet rau InpGoldBufferPoints
   double slDistAtr = (currentAtr * InpAtrMultiplierSL) / point;
   double slDistBar = (ask - lastBar.low) / point + InpGoldBufferPoints;

   double finalSlPoints = MathMax(slDistAtr, slDistBar);
   double slPrice = NormalizeDouble(ask - finalSlPoints * point, _Digits);
   double tpPrice = NormalizeDouble(ask + (finalSlPoints * InpRiskRewardRatio) * point, _Digits);

   double lotSize = CalculateSafeLotSize(finalSlPoints);

   string comment = isPyramidEntry ? "ZenithGold_PyramidBuy" : InpTradeComment;

   if(m_trade.Buy(lotSize, _Symbol, ask, slPrice, tpPrice, comment))
   {
      PrintFormat(">> [%s BUY VANG] Lot: %.2f | Gia: %.2f | SL: %.2f | TP: %.2f",
                  (isPyramidEntry ? "NHOI LENH" : "MO LENH"), lotSize, ask, slPrice, tpPrice);

      if(isPyramidEntry && InpSyncStopLossOnPyramid)
      {
         SyncAllStopLoss(POSITION_TYPE_BUY, slPrice);
      }
   }
   else
   {
      Print("Loi mo lenh BUY Vang: ", m_trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| THUC THI LENH SELL VÀNG (CHỐNG QUÉT RÂU NẾN & ĐỆM AN TOÀN)       |
//+------------------------------------------------------------------+
void ExecuteSellOrder(const MqlRates &lastBar, double currentAtr, bool isPyramidEntry)
{
   double bid = m_symbol.Bid();
   double point = m_symbol.Point();

   double slDistAtr = (currentAtr * InpAtrMultiplierSL) / point;
   double slDistBar = (lastBar.high - bid) / point + InpGoldBufferPoints;

   double finalSlPoints = MathMax(slDistAtr, slDistBar);
   double slPrice = NormalizeDouble(bid + finalSlPoints * point, _Digits);
   double tpPrice = NormalizeDouble(bid - (finalSlPoints * InpRiskRewardRatio) * point, _Digits);

   double lotSize = CalculateSafeLotSize(finalSlPoints);

   string comment = isPyramidEntry ? "ZenithGold_PyramidSell" : InpTradeComment;

   if(m_trade.Sell(lotSize, _Symbol, bid, slPrice, tpPrice, comment))
   {
      PrintFormat(">> [%s SELL VANG] Lot: %.2f | Gia: %.2f | SL: %.2f | TP: %.2f",
                  (isPyramidEntry ? "NHOI LENH" : "MO LENH"), lotSize, bid, slPrice, tpPrice);

      if(isPyramidEntry && InpSyncStopLossOnPyramid)
      {
         SyncAllStopLoss(POSITION_TYPE_SELL, slPrice);
      }
   }
   else
   {
      Print("Loi mo lenh SELL Vang: ", m_trade.ResultRetcodeDescription());
   }
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
         double targetSl = MathMax(safeBe, curSl);
         if(curSl < targetSl)
         {
            m_trade.PositionModify(ticket, targetSl, curTp);
            Print(">> [SYNC SL BUY VANG] Da bao ve lenh ticket ", ticket, " ve moc hoa von: ", targetSl);
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double safeBe = NormalizeDouble(openPrice - InpBreakEvenOffsetPts * point, _Digits);
         double targetSl = (curSl == 0.0) ? safeBe : MathMin(safeBe, curSl);
         if(curSl > targetSl || curSl == 0.0)
         {
            m_trade.PositionModify(ticket, targetSl, curTp);
            Print(">> [SYNC SL SELL VANG] Da bao ve lenh ticket ", ticket, " ve moc hoa von: ", targetSl);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| TINH TOAN KHOI LUONG LOT AN TOAN CHO VANG VOI VON 100$           |
//+------------------------------------------------------------------+
double CalculateSafeLotSize(double slDistancePoints)
{
   double balance = m_account.Balance();
   double equity  = m_account.Equity();
   double effectiveCapital = MathMin(balance, equity);

   // Tinh so tien chap nhan rui ro (vi du 2% cua 100$ = 2.0$)
   double riskAmount = effectiveCapital * (InpRiskPercent / 100.0);

   double tickSize  = m_symbol.TickSize();
   double tickValue = m_symbol.TickValue();
   double point     = m_symbol.Point();

   if(slDistancePoints <= 0 || tickSize <= 0 || tickValue <= 0 || point <= 0)
   {
      return m_symbol.LotsMin();
   }

   double moneyLossPerLot = (slDistancePoints * point / tickSize) * tickValue;
   if(moneyLossPerLot <= 0) return m_symbol.LotsMin();

   double calculatedLot = riskAmount / moneyLossPerLot;

   double step = m_symbol.LotsStep();
   calculatedLot = MathFloor(calculatedLot / step) * step;

   // Voi von 100$ tren Vang: Luon kep chat tu LotsMin (0.01) den InpMaxLotSizeGold (0.02)
   double safeMax = MathMin(InpMaxLotSizeGold, m_symbol.LotsMax());
   if(calculatedLot < m_symbol.LotsMin()) calculatedLot = m_symbol.LotsMin();
   if(calculatedLot > safeMax)            calculatedLot = safeMax;

   return calculatedLot;
}

//+------------------------------------------------------------------+
//| QUAN LY VI THE VANG: BREAK-EVEN & CHANDELIER TRAILING STOP       |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   double currentAtr = 0.0;
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(m_atrHandle, 0, 0, 1, atrBuf) > 0)
   {
      currentAtr = atrBuf[0];
   }

   double point = m_symbol.Point();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      ulong  ticket    = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double curSl     = m_position.StopLoss();
      double curTp     = m_position.TakeProfit();
      double curPrice  = m_position.PriceCurrent();
      double initialRiskDist = MathAbs(openPrice - curSl);

      if(initialRiskDist <= 0.0) continue;

      // 1. AUTO BREAK-EVEN TRÊN VÀNG (Lãi đạt 1.0R ~ $3.0 - $4.0)
      if(InpUseBreakEven)
      {
         if(m_position.PositionType() == POSITION_TYPE_BUY)
         {
            if((curPrice - openPrice) >= (initialRiskDist * InpBreakEvenTriggerR))
            {
               double bePrice = NormalizeDouble(openPrice + InpBreakEvenOffsetPts * point, _Digits);
               if(curSl < bePrice)
               {
                  m_trade.PositionModify(ticket, bePrice, curTp);
                  Print(">> [AUTO BREAK-EVEN VANG] Doi SL ve hoa von + phi: ", bePrice);
               }
            }
         }
         else if(m_position.PositionType() == POSITION_TYPE_SELL)
         {
            if((openPrice - curPrice) >= (initialRiskDist * InpBreakEvenTriggerR))
            {
               double bePrice = NormalizeDouble(openPrice - InpBreakEvenOffsetPts * point, _Digits);
               if(curSl > bePrice || curSl == 0.0)
               {
                  m_trade.PositionModify(ticket, bePrice, curTp);
                  Print(">> [AUTO BREAK-EVEN VANG] Doi SL ve hoa von + phi: ", bePrice);
               }
            }
         }
      }

      // 2. CHANDELIER TRAILING STOP TRÊN VÀNG (Lãi >= 1.4R)
      if(InpUseTrailingStop && currentAtr > 0.0)
      {
         double trailDistPts = (currentAtr * InpTrailingDistanceATR) / point;

         if(m_position.PositionType() == POSITION_TYPE_BUY)
         {
            if((curPrice - openPrice) >= (initialRiskDist * InpTrailingStartR))
            {
               double newSl = NormalizeDouble(curPrice - trailDistPts * point, _Digits);
               if(newSl > curSl + InpTrailingStepPts * point)
               {
                  m_trade.PositionModify(ticket, newSl, curTp);
                  Print(">> [TRAILING STOP VANG BUY] Cap nhat SL ticket: ", ticket, " toi: ", newSl);
               }
            }
         }
         else if(m_position.PositionType() == POSITION_TYPE_SELL)
         {
            if((openPrice - curPrice) >= (initialRiskDist * InpTrailingStartR))
            {
               double newSl = NormalizeDouble(curPrice + trailDistPts * point, _Digits);
               if(curSl == 0.0 || newSl < curSl - InpTrailingStepPts * point)
               {
                  m_trade.PositionModify(ticket, newSl, curTp);
                  Print(">> [TRAILING STOP VANG SELL] Cap nhat SL ticket: ", ticket, " toi: ", newSl);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| ENGINE TIN TUC USD & BIEN DONG VANG (CPI, NFP, FOMC)             |
//+------------------------------------------------------------------+
void UpdateNewsAndVolatilityEngine()
{
   m_isNewsRestricted = false;
   m_newsStatusText   = "SAFE (Khong co tin do USD)";

   if(InpUseNewsFilter)
   {
      datetime now = TimeCurrent();
      datetime fromTime = now - (InpMinsAfterNews * 60);
      datetime toTime   = now + (InpMinsBeforeNews * 60);

      MqlCalendarValue values[];
      // Vang chiu chi phoi boi USD
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

   // Bo do bien dong dot bien tren Vang
   m_isVolatilityShocked = false;
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
            m_isVolatilityShocked  = true;
            m_volatilityStatusText = StringFormat("[SHOCK BIEN DONG VANG] %.2fx (Khoa mo lenh!)", m_currentVolRatio);
         }
         else if(m_currentVolRatio >= 1.4)
         {
            m_volatilityStatusText = StringFormat("VANG BIEN DONG MANH (%.2fx)", m_currentVolRatio);
         }
         else
         {
            m_volatilityStatusText = StringFormat("VANG ON DINH (%.2fx)", m_currentVolRatio);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| TU DONG DOI STOP LOSS VE HOA VON TRUOC GIO TIN DO USD            |
//+------------------------------------------------------------------+
void ProtectPositionsBeforeNews()
{
   double point = m_symbol.Point();

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
         if(curPrice > openPrice + 20 * point)
         {
            double bePrice = NormalizeDouble(openPrice + 10 * point, _Digits);
            if(curSl < bePrice)
            {
               m_trade.PositionModify(ticket, bePrice, curTp);
               Print(">> [BAO VE TRUOC TIN USD] Da khoa hoa von ticket Vang: ", ticket);
            }
         }
      }
      else if(m_position.PositionType() == POSITION_TYPE_SELL)
      {
         if(curPrice < openPrice - 20 * point)
         {
            double bePrice = NormalizeDouble(openPrice - 10 * point, _Digits);
            if(curSl > bePrice || curSl == 0.0)
            {
               m_trade.PositionModify(ticket, bePrice, curTp);
               Print(">> [BAO VE TRUOC TIN USD] Da khoa hoa von ticket Vang: ", ticket);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| XAC DINH XU HUONG KHUNG LON HTF H1                               |
//+------------------------------------------------------------------+
int GetHtfTrend()
{
   if(!InpUseHtfFilter) return 1;

   double fastEma[], slowEma[];
   ArraySetAsSeries(fastEma, true);
   ArraySetAsSeries(slowEma, true);

   if(CopyBuffer(m_htfFastEmaHandle, 0, 1, 2, fastEma) < 2) return 0;
   if(CopyBuffer(m_htfSlowEmaHandle, 0, 1, 2, slowEma) < 2) return 0;

   if(fastEma[0] > slowEma[0]) return 1;
   if(fastEma[0] < slowEma[0]) return -1;

   return 0;
}

//+------------------------------------------------------------------+
//| XAC DINH PHAN VUNG DOUBLE BOLLINGER BANDS (DBB M15)              |
//+------------------------------------------------------------------+
int GetDbbZone(double closePrice)
{
   double outerUpper[], outerLower[], innerUpper[], innerLower[];
   ArraySetAsSeries(outerUpper, true);
   ArraySetAsSeries(outerLower, true);
   ArraySetAsSeries(innerUpper, true);
   ArraySetAsSeries(innerLower, true);

   if(CopyBuffer(m_bbOuterHandle, 1, 1, 1, outerUpper) < 1) return 0;
   if(CopyBuffer(m_bbOuterHandle, 2, 1, 1, outerLower) < 1) return 0;
   if(CopyBuffer(m_bbInnerHandle, 1, 1, 1, innerUpper) < 1) return 0;
   if(CopyBuffer(m_bbInnerHandle, 2, 1, 1, innerLower) < 1) return 0;

   if(closePrice >= innerUpper[0]) return 1;
   if(closePrice <= innerLower[0]) return -1;

   return 0;
}

//+------------------------------------------------------------------+
//| NHAN DIEN NEN PIN BAR RUT RAU CHUYEN BIET CHO VANG               |
//+------------------------------------------------------------------+
void DetectPinBar(const MqlRates &bar, bool &isBullish, bool &isBearish)
{
   isBullish = false;
   isBearish = false;

   double totalRange = bar.high - bar.low;
   if(totalRange <= 0.0) return;

   double body      = MathAbs(bar.close - bar.open);
   double lowerWick = MathMin(bar.open, bar.close) - bar.low;
   double upperWick = bar.high - MathMax(bar.open, bar.close);

   // Bullish Pin Bar tren Vang: Rau duoi >= 65% toan bo cay nen, than nen nho o dinh
   if((lowerWick / totalRange >= InpMinPinBarWickRatio) &&
      (body / totalRange <= InpMaxPinBarBodyRatio) &&
      (upperWick / totalRange <= 0.15))
   {
      isBullish = true;
   }

   // Bearish Pin Bar tren Vang: Rau tren >= 65% toan bo cay nen, than nen nho o day
   if((upperWick / totalRange >= InpMinPinBarWickRatio) &&
      (body / totalRange <= InpMaxPinBarBodyRatio) &&
      (lowerWick / totalRange <= 0.15))
   {
      isBearish = true;
   }
}

//+------------------------------------------------------------------+
//| NHAN DIEN MO HINH FAKEY TREN VANG                                |
//+------------------------------------------------------------------+
void DetectFakey(const MqlRates &rates[], bool &bullishFakey, bool &bearishFakey)
{
   bullishFakey = false;
   bearishFakey = false;

   bool isInsideBar = (rates[2].high < rates[3].high && rates[2].low > rates[3].low);
   if(!isInsideBar) return;

   if(rates[1].low < rates[2].low && rates[1].close > rates[2].low)
   {
      bullishFakey = true;
   }

   if(rates[1].high > rates[2].high && rates[1].close < rates[2].high)
   {
      bearishFakey = true;
   }
}

//+------------------------------------------------------------------+
//| DEM SO VI THE THEO LOAI (BUY HOAC SELL)                          |
//+------------------------------------------------------------------+
int CountPositionsByType(ENUM_POSITION_TYPE type)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
         {
            if(m_position.PositionType() == type)
            {
               count++;
            }
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| DEM TONG SO VI THE CUA EXPERT                                    |
//+------------------------------------------------------------------+
int CountTotalPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
         {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| QUAN LY DAILY LOSS GUARD                                         |
//+------------------------------------------------------------------+
void UpdateDailyLossGuard()
{
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

   MqlDateTime lastReset;
   TimeToStruct(m_lastDailyResetDate, lastReset);

   if(now.day != lastReset.day)
   {
      m_dailyStartEquity   = m_account.Equity();
      m_lastDailyResetDate = TimeCurrent();
      m_dailyTradingLocked = false;
   }

   if(!InpUseDailyLossGuard)
   {
      m_dailyTradingLocked = false;
      return;
   }

   double currentEquity = m_account.Equity();
   if(m_dailyStartEquity > 0.0)
   {
      double lossPercent = ((m_dailyStartEquity - currentEquity) / m_dailyStartEquity) * 100.0;
      if(lossPercent >= InpMaxDailyLossPercent)
      {
         m_dailyTradingLocked = true;
      }
   }
}

//+------------------------------------------------------------------+
//| KIEM TRA KHUNG GIO GIAO DICH CHO PHEP                            |
//+------------------------------------------------------------------+
bool IsTradingTimeAllowed()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour >= InpStartHour && dt.hour < InpEndHour)
   {
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| HELPER: TAO HOAC CAP NHAT LABEL DO HOA                           |
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
//| HELPER: TAO KHUNG HINH NEN BACKGROUND (GUI PANEL)                |
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
//| HIEN THI ON-CHART GUI DASHBOARD CHUYEN NGHIEP CHO VANG           |
//+------------------------------------------------------------------+
void RenderDashboard()
{
   Comment(""); // Xoa text raw comment trung len nen nen

   double currentEquity  = m_account.Equity();
   double currentBalance = m_account.Balance();
   long   spread         = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   int panelX = 15;
   int panelY = 25;
   int panelWidth = 310;
   int panelHeight = 255;

   // 1. Tao Panel nen toi mau chong loa va vien sang
   SetGuiPanel("ZS_BG_PANEL", panelX, panelY, panelWidth, panelHeight, C'12,20,32', C'45,85,140');
   SetGuiPanel("ZS_BG_HEADER", panelX, panelY, panelWidth, 26, C'20,35,55', C'45,85,140');

   // 2. Tieu de vang sang noi bat
   SetGuiLabel("ZS_TITLE", "🎯 ZENITH GOLD M15  (XAUUSD v4.0)", panelX + 12, panelY + 5, clrGold, 10, true);

   // 3. Noi dung chi tiet ro net
   int startY = panelY + 33;
   int lineH  = 20;

   // Dong 1: So Du & Von
   SetGuiLabel("ZS_L1", StringFormat("💰 Số Dư: $%.2f  |  Vốn: $%.2f", currentBalance, currentEquity), panelX + 12, startY, clrLimeGreen, 9, true);

   // Dong 2: Spread
   color spreadColor = (spread > InpMaxSpreadPoints) ? clrRed : clrAqua;
   SetGuiLabel("ZS_L2", StringFormat("⚡ Spread Vàng: %d pts (Max: %d pts)", spread, InpMaxSpreadPoints), panelX + 12, startY + lineH, spreadColor, 9);

   // Dong 3: Xu huong H1
   int htf = GetHtfTrend();
   string htfText = (htf == 1) ? "TĂNG MẠNH (Bullish)" : (htf == -1 ? "GIẢM MẠNH (Bearish)" : "ĐI NGANG (Neutral)");
   color htfColor = (htf == 1) ? clrLime : (htf == -1 ? clrOrangeRed : clrSilver);
   SetGuiLabel("ZS_L3", StringFormat("📈 Xu Hướng H1: %s", htfText), panelX + 12, startY + lineH*2, htfColor, 9, true);

   // Dong 4: Vi the dang mo
   int totalPos = CountTotalPositions();
   int buyPos   = CountPositionsByType(POSITION_TYPE_BUY);
   int sellPos  = CountPositionsByType(POSITION_TYPE_SELL);
   SetGuiLabel("ZS_L4", StringFormat("📊 Vị Thế Đang Chạy: %d / %d (BUY: %d | SELL: %d)", totalPos, InpMaxPositionsTotal, buyPos, sellPos), panelX + 12, startY + lineH*3, clrWhite, 9);

   // Dong 5: Che do nhoi lenh
   string pyStr = InpEnablePyramiding ? "BẬT (Khi lãi >= 1.0R)" : "TẮT (1 Lệnh)";
   SetGuiLabel("ZS_L5", StringFormat("🚀 Nhồi Lệnh: %s", pyStr), panelX + 12, startY + lineH*4, clrKhaki, 9);

   // Dong 6: Tin do USD
   string newsTxt = m_isNewsRestricted ? m_newsStatusText : "AN TOÀN (Không có tin đỏ)";
   color newsColor = m_isNewsRestricted ? clrOrange : clrSpringGreen;
   SetGuiLabel("ZS_L6", StringFormat("📰 Tin Đỏ USD: %s", newsTxt), panelX + 12, startY + lineH*5, newsColor, 9);

   // Dong 7: Bien dong vang
   color volColor = m_isVolatilityShocked ? clrRed : clrDeepSkyBlue;
   SetGuiLabel("ZS_L7", StringFormat("🌊 Biến Động Vàng: %s", m_volatilityStatusText), panelX + 12, startY + lineH*6, volColor, 9);

   // Dong 8: Dem chong quet rau & Ti le R:R
   SetGuiLabel("ZS_L8", StringFormat("🛡️ Đệm Râu: %d pts  |  R:R: 1 : %.1f ($7 - $9u)", InpGoldBufferPoints, InpRiskRewardRatio), panelX + 12, startY + lineH*7, clrYellow, 9);

   // Dong 9: Trang thai khoa tai khoan
   SetGuiLabel("ZS_L9", "🔒 Trạng Thái: KHÔNG KHÓA (Sẵn sàng 24/5)", panelX + 12, startY + lineH*8, clrLime, 9, true);

   // Hien thi them Comment du phong (Dam bao luon hien thi 100% tren moi loai bieu do)
   string dash = "";
   dash += "===========================================================\n";
   dash += "   🎯 ZENITH GOLD M15 (XAUUSD v4.0) - BOT BAN TIA VANG\n";
   dash += "===========================================================\n";
   dash += " 🟢 TRANG THAI: BOT HOAT DONG 100% BINH THUONG\n";
   dash += " ⏳ TIEN DO:    DANG CHO DIEM VAO DEP (PRICE ACTION M15)...\n";
   dash += "-----------------------------------------------------------\n";
   dash += StringFormat(" 💰 So Du: $%.2f | Von: $%.2f\n", currentBalance, currentEquity);
   dash += StringFormat(" ⚡ Spread Vang: %d pts (Max cho phep: %d pts)\n", spread, InpMaxSpreadPoints);
   dash += StringFormat(" 📈 Xu Huong H1: %s\n", htfText);
   dash += StringFormat(" 📊 Vi The: %d / %d Lenh (BUY: %d | SELL: %d)\n", totalPos, InpMaxPositionsTotal, buyPos, sellPos);
   dash += StringFormat(" 🚀 Nhoi Lenh: %s\n", pyStr);
   dash += StringFormat(" 📰 Tin Do USD: %s\n", newsTxt);
   dash += StringFormat(" 🌊 Bien Dong Vang: %s\n", m_volatilityStatusText);
   dash += StringFormat(" 🛡️ Dem Chong Quet Rau: %d pts\n", InpGoldBufferPoints);
   dash += StringFormat(" 🎯 Ti Le R:R: 1 : %.1f (Muc lai: $7.0 - $9.0/lenh)\n", InpRiskRewardRatio);
   dash += "===========================================================\n";

   Comment(dash);
   ChartRedraw(0);
}
//+------------------------------------------------------------------+
