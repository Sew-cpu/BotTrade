//+------------------------------------------------------------------+
//|                                            TitanGold_Pro_EA.mq5  |
//|               Ultimate Institutional Gold & Forex Trading Robot  |
//|                    High Profit & Bulletproof Low Risk Architecture|
//|                                  Copyright 2026, Antigravity     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Antigravity"
#property link        "https://github.com"
#property version     "3.00"
#property description "Expert Advisor Giao Dich VANG (XAUUSD) & Forex Dinh Cao"
#property description "Ket hop 9 Chien luoc Vang: Trend Following, Asian Liquidity Sweep, ATR Dynamic SL,"
#property description "Bollinger Squeeze, Fibonacci Confluence, Partial Close 50% & Daily Drawdown Guard"
#property strict

//--- Thu vien MQL5 chuan
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS & STRUCTURES                                               |
//+------------------------------------------------------------------+
enum ENUM_STRATEGY_MODE
  {
   STRATEGY_HYBRID_CONFLUENCE = 0, // Che do Hybrid (Trend EMA + RSI + Bollinger + ATR)
   STRATEGY_ASIAN_SWEEP       = 1  // Che do Quet Thanh Khoan Phien A (Asian Range Sweep/Breakout)
  };

enum ENUM_RISK_CALC
  {
   RISK_BY_EQUITY_PERCENT     = 0, // % Rui ro theo Equity (Khuyen nghi cho Vang)
   RISK_BY_BALANCE_PERCENT    = 1, // % Rui ro theo Balance
   RISK_BY_FIXED_LOT          = 2  // Khau do Lot co dinh
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS (THIET LAP THAM SO DAU VAO)                    |
//+------------------------------------------------------------------+
input group "=== 1. CHE DO CHIEN LUOC & NEN TANG ==="
input ENUM_STRATEGY_MODE InpStrategyMode        = STRATEGY_HYBRID_CONFLUENCE; // Chien luoc chu dao
input ulong              InpMagicNumber         = 7772026;             // Magic Number rieng cho EA
input string             InpTradeComment        = "TitanGold_Pro";     // Ghi chu lenh
input ulong              InpSlippage            = 30;                  // Do truot gia cho phep (Points)

input group "=== 2. QUAN TRI RUI RO THAP (LOW RISK & SAFETY GUARD) ==="
input ENUM_RISK_CALC     InpRiskMode            = RISK_BY_EQUITY_PERCENT; // Phuong phap quan ly von
input double             InpRiskPercent         = 1.0;                 // % Rui ro moi lenh (Khuyen nghi 0.5% - 1.0%)
input double             InpFixedLot            = 0.01;                // Lot co dinh (neu chon Fixed)
input double             InpMaxDailyLossPct     = 3.0;                 // Gioi han sụt giam von toi da trong ngay (%)
input int                InpMaxSpreadPoints     = 350;                 // Spread toi da cho phep (Points, vi du Exness XAUUSDm ~ 200-300 points)
input int                InpMaxOpenTrades       = 1;                   // So vi the mo toi da dong thoi

input group "=== 3. THIET LAP CHIEN LUOC HYBRID CONFLUENCE ==="
input int                InpFastEmaPeriod       = 50;                  // EMA 50 (Xu huong trung han)
input int                InpSlowEmaPeriod       = 200;                 // EMA 200 (Xu huong dai han theo Dow)
input int                InpRsiPeriod           = 14;                  // Chu ky RSI
input double             InpRsiBullishMin       = 48.0;                // RSI Buy toi thieu
input double             InpRsiBullishMax       = 68.0;                // RSI Buy toi da (Tranh du dinh Qua Mua)
input double             InpRsiBearishMax       = 52.0;                // RSI Sell toi da
input double             InpRsiBearishMin       = 32.0;                // RSI Sell toi thieu (Tranh ban day Qua Ban)
input int                InpBandsPeriod         = 20;                  // Chu ky Bollinger Bands
input double             InpBandsDeviation      = 2.0;                 // Do lech chuan Bands

input group "=== 4. THIET LAP CHIEN LUOC ASIAN RANGE SWEEP ==="
input int                InpAsianStartHour      = 0;                   // Gio bat dau phien A (Server Time)
input int                InpAsianEndHour        = 7;                   // Gio ket thuc phien A (Server Time)
input double             InpSweepBufferATR      = 0.2;                 // Bo dem quet thanh khoan (x ATR)

input group "=== 5. STOP LOSS & TAKE PROFIT THEO ATR (HIGH R:R) ==="
input int                InpAtrPeriod           = 14;                  // Chu ky ATR do bien dong thuc te
input double             InpAtrMultiplierSL     = 1.5;                 // Boi so ATR cho Stop Loss (Tranh quét râu nến)
input double             InpRiskRewardRatio     = 2.5;                 // Ty le R:R (1:2.5 den 1:3.0 toi da hoa loi nhuan)

input group "=== 6. CHOT LOI TUNG PHAN (PARTIAL TAKE PROFIT 50%) ==="
input bool               InpUsePartialClose     = true;                // Kich hoat chot loi 50% khoi luong
input double             InpPartialCloseRatioR  = 1.5;                 // Chot 50% khi lai dat 1.5R (Bo tien vao tui)

input group "=== 7. KHOA LOI NHUAN: BREAK-EVEN & TRAILING STOP ==="
input bool               InpUseBreakEven        = true;                // Kich hoat Auto Break-Even
input double             InpBreakEvenTriggerR   = 1.0;                 // Dua ve hoa von khi lai vuot 1.0R
input int                InpBreakEvenBufferPts  = 15;                  // Points cong them tren Entry de bu spread
input bool               InpUseTrailingStop     = true;                // Kich hoat Trailing Stop
input double             InpTrailingStartR      = 1.5;                 // Kich hoat Trailing khi lai vuot 1.5R
input double             InpTrailingAtrMult     = 1.2;                 // Khoang cach Trailing tinh theo x ATR
input int                InpTrailingStepPts     = 25;                  // Buoc nhay Trailing (Points)

input group "=== 8. KHUNG GIO GIAO DICH VANG (KILL ZONES FILTER) ==="
input bool               InpUseTradingHours     = true;                // Bat bo loc gio giao dich
input int                InpTradeStartHour      = 8;                   // Bat dau phien London (Thanh khoan cao)
input int                InpTradeEndHour        = 21;                  // Ket thuc phien My (Tranh giao phien gian spread)

input group "=== 9. GIAO DIEN BẢNG DIEU KHIEN (DASHBOARD) ==="
input bool               InpShowDashboard       = true;                // Hien thi Dashboard tren man hinh MT5

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & HANDLES                                         |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;
CAccountInfo   m_account;
CSymbolInfo    m_symbol;

int            m_fastEmaHandle  = INVALID_HANDLE;
int            m_slowEmaHandle  = INVALID_HANDLE;
int            m_rsiHandle      = INVALID_HANDLE;
int            m_bandsHandle    = INVALID_HANDLE;
int            m_atrHandle      = INVALID_HANDLE;

datetime       m_lastBarTime    = 0;
datetime       m_currentDay     = 0;
double         m_dayStartEquity = 0.0;
bool           m_dailyLimitHit  = false;

// Bien luu tru Asian Range
double         m_asianHigh      = 0.0;
double         m_asianLow       = 0.0;
bool           m_asianRangeReady= false;
datetime       m_asianDate      = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!m_symbol.Name(_Symbol))
     {
      Print("Loi khoi tao symbol: ", _Symbol);
      return INIT_FAILED;
     }
   m_symbol.Refresh();

   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(InpSlippage);

   // Tự động nhận diện Filling Mode của sàn
   uint filling = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((filling & SYMBOL_FILLING_IOC) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);

   // Khoi tao cac chi bao ky thuat
   m_fastEmaHandle = iMA(_Symbol, PERIOD_CURRENT, InpFastEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_slowEmaHandle = iMA(_Symbol, PERIOD_CURRENT, InpSlowEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_rsiHandle     = iRSI(_Symbol, PERIOD_CURRENT, InpRsiPeriod, PRICE_CLOSE);
   m_bandsHandle   = iBands(_Symbol, PERIOD_CURRENT, InpBandsPeriod, 0, InpBandsDeviation, PRICE_CLOSE);
   m_atrHandle     = iATR(_Symbol, PERIOD_CURRENT, InpAtrPeriod);

   if(m_fastEmaHandle == INVALID_HANDLE || m_slowEmaHandle == INVALID_HANDLE ||
      m_rsiHandle == INVALID_HANDLE || m_bandsHandle == INVALID_HANDLE || m_atrHandle == INVALID_HANDLE)
     {
      Print("Loi khoi tao Indicator handles!");
      return INIT_FAILED;
     }

   m_dayStartEquity = m_account.Equity();
   m_currentDay     = GetStartOfDay(TimeCurrent());

   Print(">>> TitanGold_Pro_EA da khoi tao thanh cong tren ", _Symbol, " | Magic: ", InpMagicNumber);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(m_fastEmaHandle != INVALID_HANDLE) IndicatorRelease(m_fastEmaHandle);
   if(m_slowEmaHandle != INVALID_HANDLE) IndicatorRelease(m_slowEmaHandle);
   if(m_rsiHandle != INVALID_HANDLE)     IndicatorRelease(m_rsiHandle);
   if(m_bandsHandle != INVALID_HANDLE)   IndicatorRelease(m_bandsHandle);
   if(m_atrHandle != INVALID_HANDLE)     IndicatorRelease(m_atrHandle);

   ObjectsDeleteAll(0, "TitanDash_");
   Comment("");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!m_symbol.RefreshRates())
      return;

   // 1. Kiem tra va Reset gioi han ngay
   CheckDailyRiskLimit();

   // 2. Tinh toan Asian Range neu dung che do Asian Sweep
   UpdateAsianRange();

   // 3. Quan ly cac vi the dang mo (Break-Even, Partial Close 50%, Trailing Stop)
   ManageActiveTrades();

   // 4. Ve Dashboard len man hinh
   if(InpShowDashboard)
      RenderDashboard();

   // Neu cham gioi han lo trong ngay, dung mo lenh
   if(m_dailyLimitHit)
      return;

   // 5. Kiem tra Spread an toan
   int currentSpread = (int)m_symbol.Spread();
   if(currentSpread > InpMaxSpreadPoints)
      return;

   // 6. Kiem tra khung gio giao dich
   if(InpUseTradingHours && !IsTradingAllowedNow())
      return;

   // 7. Kiem tra nến mới (Chi vao lenh khi nen vua dong cua)
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime == m_lastBarTime)
      return;
   m_lastBarTime = barTime;

   PrintFormat(">>> [Nen moi %s] Dang quet tin hieu tren %s (Spread: %d) | Dang cho diem vao dep...",
               TimeToString(barTime, TIME_MINUTES), _Symbol, currentSpread);

   // 8. Kiem tra so luong vi the dang chay
   if(CountActiveTrades() >= InpMaxOpenTrades)
      return;

   // 9. Thuc thi tin hieu giao dich theo chien luoc
   if(InpStrategyMode == STRATEGY_HYBRID_CONFLUENCE)
      ExecuteHybridConfluenceStrategy();
   else if(InpStrategyMode == STRATEGY_ASIAN_SWEEP)
      ExecuteAsianSweepStrategy();
  }

//+------------------------------------------------------------------+
//| Chien luoc 1: Hybrid Confluence (Trend + RSI + Bands + ATR)      |
//+------------------------------------------------------------------+
void ExecuteHybridConfluenceStrategy()
  {
   double fastEma   = GetIndicatorBuffer(m_fastEmaHandle, 0, 1);
   double slowEma   = GetIndicatorBuffer(m_slowEmaHandle, 0, 1);
   double rsi       = GetIndicatorBuffer(m_rsiHandle, 0, 1);
   double upperBand = GetIndicatorBuffer(m_bandsHandle, 1, 1);
   double lowerBand = GetIndicatorBuffer(m_bandsHandle, 2, 1);
   double midBand   = GetIndicatorBuffer(m_bandsHandle, 0, 1);
   double atr       = GetIndicatorBuffer(m_atrHandle, 0, 1);

   if(fastEma == 0 || slowEma == 0 || rsi == 0 || atr == 0)
      return;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_CURRENT, 1, 2, rates) < 2)
      return;

   double close1 = rates[0].close;
   double open1  = rates[0].open;
   double low1   = rates[0].low;
   double high1  = rates[0].high;

   // --- TIN HIEU BUY CONFLUENCE ---
   // 1. Xu huong chu dao: EMA50 > EMA200 va Gia > EMA50
   bool trendBullish = (fastEma > slowEma && close1 > fastEma);
   // 2. RSI nam trong vung xung luong tang lanh manh (48 - 68), chua qua mua
   bool rsiBullish   = (rsi >= InpRsiBullishMin && rsi <= InpRsiBullishMax);
   // 3. Gia bat tang tu Middle Band hoac vuot len tren Middle Band
   bool bandBullish  = (close1 > midBand && (open1 <= midBand || low1 <= midBand * 1.0005));
   // 4. Nen xanh xac nhan (Close > Open)
   bool candleBullish= (close1 > open1);

   if(trendBullish && rsiBullish && bandBullish && candleBullish)
     {
      double ask = m_symbol.Ask();
      double slDist = atr * InpAtrMultiplierSL;
      double sl = NormalizeDouble(ask - slDist, m_symbol.Digits());
      double tp = NormalizeDouble(ask + (slDist * InpRiskRewardRatio), m_symbol.Digits());

      double lot = CalculateSmartLot(ask, sl);
      if(lot > 0)
        {
         if(m_trade.Buy(lot, _Symbol, ask, sl, tp, InpTradeComment))
            PrintFormat(">>> [BUY HYBRID] Lot=%.2f | Price=%.3f | SL=%.3f | TP=%.3f | R:R=1:%.1f",
                        lot, ask, sl, tp, InpRiskRewardRatio);
        }
      return;
     }

   // --- TIN HIEU SELL CONFLUENCE ---
   // 1. Xu huong chu dao: EMA50 < EMA200 va Gia < EMA50
   bool trendBearish = (fastEma < slowEma && close1 < fastEma);
   // 2. RSI nam trong vung xung luong giam lanh manh (32 - 52), chua qua ban
   bool rsiBearish   = (rsi <= InpRsiBearishMax && rsi >= InpRsiBearishMin);
   // 3. Gia quay dau tu Middle Band xuong duoi
   bool bandBearish  = (close1 < midBand && (open1 >= midBand || high1 >= midBand * 0.9995));
   // 4. Nen do xac nhan (Close < Open)
   bool candleBearish= (close1 < open1);

   if(trendBearish && rsiBearish && bandBearish && candleBearish)
     {
      double bid = m_symbol.Bid();
      double slDist = atr * InpAtrMultiplierSL;
      double sl = NormalizeDouble(bid + slDist, m_symbol.Digits());
      double tp = NormalizeDouble(bid - (slDist * InpRiskRewardRatio), m_symbol.Digits());

      double lot = CalculateSmartLot(bid, sl);
      if(lot > 0)
        {
         if(m_trade.Sell(lot, _Symbol, bid, sl, tp, InpTradeComment))
            PrintFormat(">>> [SELL HYBRID] Lot=%.2f | Price=%.3f | SL=%.3f | TP=%.3f | R:R=1:%.1f",
                        lot, bid, sl, tp, InpRiskRewardRatio);
        }
      return;
     }
  }

//+------------------------------------------------------------------+
//| Chien luoc 2: Asian Session Liquidity Sweep / Breakout           |
//+------------------------------------------------------------------+
void ExecuteAsianSweepStrategy()
  {
   if(!m_asianRangeReady || m_asianHigh <= 0 || m_asianLow <= 0)
      return;

   double atr = GetIndicatorBuffer(m_atrHandle, 0, 1);
   if(atr <= 0) return;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_CURRENT, 1, 2, rates) < 2)
      return;

   double close1 = rates[0].close;
   double open1  = rates[0].open;
   double high1  = rates[0].high;
   double low1   = rates[0].low;

   // 1. BULLISH SWEEP: Gia tho ra duoi day phien A (Low < AsianLow) nhung dong nen lai rut len tren AsianLow
   // Day la tin hieu Fakeout / Quet thanh khoan day kinh dien cua Vang!
   if(low1 < m_asianLow && close1 > m_asianLow && close1 > open1)
     {
      double ask = m_symbol.Ask();
      double slDist = MathMax(atr * InpAtrMultiplierSL, MathAbs(ask - low1) + (10 * m_symbol.Point()));
      double sl = NormalizeDouble(ask - slDist, m_symbol.Digits());
      double tp = NormalizeDouble(ask + (slDist * InpRiskRewardRatio), m_symbol.Digits());

      double lot = CalculateSmartLot(ask, sl);
      if(lot > 0)
        {
         if(m_trade.Buy(lot, _Symbol, ask, sl, tp, "TitanGold_SweepBuy"))
            PrintFormat(">>> [ASIAN SWEEP BUY] Quet day %.3f -> Bat tang dong nen %.3f | Lot=%.2f",
                        m_asianLow, close1, lot);
        }
      return;
     }

   // 2. BEARISH SWEEP: Gia tho ra tren dinh phien A (High > AsianHigh) nhung dong nen lai rut xuong duoi AsianHigh
   // Quet thanh khoan dinh cua Vang!
   if(high1 > m_asianHigh && close1 < m_asianHigh && close1 < open1)
     {
      double bid = m_symbol.Bid();
      double slDist = MathMax(atr * InpAtrMultiplierSL, MathAbs(high1 - bid) + (10 * m_symbol.Point()));
      double sl = NormalizeDouble(bid + slDist, m_symbol.Digits());
      double tp = NormalizeDouble(bid - (slDist * InpRiskRewardRatio), m_symbol.Digits());

      double lot = CalculateSmartLot(bid, sl);
      if(lot > 0)
        {
         if(m_trade.Sell(lot, _Symbol, bid, sl, tp, "TitanGold_SweepSell"))
            PrintFormat(">>> [ASIAN SWEEP SELL] Quet dinh %.3f -> Dao chieu dong nen %.3f | Lot=%.2f",
                        m_asianHigh, close1, lot);
        }
      return;
     }
  }

//+------------------------------------------------------------------+
//| Cap nhat bien do Phien A (Asian Range High / Low)               |
//+------------------------------------------------------------------+
void UpdateAsianRange()
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   datetime today = GetStartOfDay(TimeCurrent());

   if(today != m_asianDate)
     {
      m_asianDate = today;
      m_asianHigh = 0.0;
      m_asianLow  = 0.0;
      m_asianRangeReady = false;
     }

   // Trong gio phien A: ghi nhan High va Low
   if(dt.hour >= InpAsianStartHour && dt.hour <= InpAsianEndHour)
     {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      int copied = CopyRates(_Symbol, PERIOD_H1, 0, dt.hour - InpAsianStartHour + 1, rates);
      if(copied > 0)
        {
         double highest = rates[0].high;
         double lowest  = rates[0].low;
         for(int i = 1; i < copied; i++)
           {
            if(rates[i].high > highest) highest = rates[i].high;
            if(rates[i].low < lowest)   lowest  = rates[i].low;
           }
         m_asianHigh = highest;
         m_asianLow  = lowest;
        }
     }
   else if(dt.hour > InpAsianEndHour)
     {
      // Sau khi phien A ket thuc, range da san sang
      if(m_asianHigh > 0 && m_asianLow > 0)
         m_asianRangeReady = true;
     }
  }

//+------------------------------------------------------------------+
//| Quan ly vi the: Chot loi 50%, Break-Even & Trailing Stop         |
//+------------------------------------------------------------------+
void ManageActiveTrades()
  {
   double atr = GetIndicatorBuffer(m_atrHandle, 0, 0);
   if(atr <= 0) atr = 0.0010;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber)
         continue;

      ulong  ticket    = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double currentSL = m_position.StopLoss();
      double currentTP = m_position.TakeProfit();
      double volume    = m_position.Volume();
      ENUM_POSITION_TYPE type = m_position.PositionType();

      // Tinh 1R goc
      double initialRiskDist = (currentSL > 0) ? MathAbs(openPrice - currentSL) : (atr * InpAtrMultiplierSL);
      if(initialRiskDist <= 0) initialRiskDist = 100 * m_symbol.Point();

      double currentProfitDist = (type == POSITION_TYPE_BUY) ? (m_symbol.Bid() - openPrice) : (openPrice - m_symbol.Ask());
      double profitInR = currentProfitDist / initialRiskDist;

      // --- 1. CHOT LOI TUNG PHAN 50% TAI 1.5R ---
      if(InpUsePartialClose && profitInR >= InpPartialCloseRatioR)
        {
         string cmt = m_position.Comment();
         if(StringFind(cmt, "[PC50]") < 0)
           {
            double stepLot = m_symbol.LotsStep();
            double minLot  = m_symbol.LotsMin();
            double closeLot = MathFloor((volume * 0.5) / stepLot) * stepLot;

            if(closeLot >= minLot && (volume - closeLot) >= minLot)
              {
               if(m_trade.PositionClosePartial(ticket, closeLot))
                  PrintFormat(">>> [CHOT LOI 50%%] Ticket #%d: Dong %.2f Lot tai %.2f R (Bo tien vao tui)",
                              ticket, closeLot, profitInR);
              }
           }
        }

      // --- 2. DUA VE HOA VON (BREAK-EVEN) TAI 1.0R ---
      if(InpUseBreakEven && profitInR >= InpBreakEvenTriggerR)
        {
         if(type == POSITION_TYPE_BUY)
           {
            double beSL = NormalizeDouble(openPrice + (InpBreakEvenBufferPts * m_symbol.Point()), m_symbol.Digits());
            if(currentSL < beSL || currentSL == 0)
              {
               if(m_trade.PositionModify(ticket, beSL, currentTP))
                  PrintFormat(">>> [BREAK-EVEN] Ticket #%d BUY dời SL ve hoa von %.3f", ticket, beSL);
              }
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double beSL = NormalizeDouble(openPrice - (InpBreakEvenBufferPts * m_symbol.Point()), m_symbol.Digits());
            if(currentSL > beSL || currentSL == 0)
              {
               if(m_trade.PositionModify(ticket, beSL, currentTP))
                  PrintFormat(">>> [BREAK-EVEN] Ticket #%d SELL dời SL ve hoa von %.3f", ticket, beSL);
              }
           }
        }

      // --- 3. TRAILING STOP THEO ATR ---
      if(InpUseTrailingStop && profitInR >= InpTrailingStartR)
        {
         double trailDist = atr * InpTrailingAtrMult;
         if(type == POSITION_TYPE_BUY)
           {
            double newSL = NormalizeDouble(m_symbol.Bid() - trailDist, m_symbol.Digits());
            if(newSL > currentSL + (InpTrailingStepPts * m_symbol.Point()) || currentSL == 0)
              {
               if(m_trade.PositionModify(ticket, newSL, currentTP))
                  PrintFormat(">>> [TRAILING STOP] Ticket #%d BUY dời SL bám song len %.3f", ticket, newSL);
              }
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double newSL = NormalizeDouble(m_symbol.Ask() + trailDist, m_symbol.Digits());
            if(newSL < currentSL - (InpTrailingStepPts * m_symbol.Point()) || currentSL == 0)
              {
               if(m_trade.PositionModify(ticket, newSL, currentTP))
                  PrintFormat(">>> [TRAILING STOP] Ticket #%d SELL dời SL bám song xuong %.3f", ticket, newSL);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Tinh toan Lot Size an toan chuan xac cho Vang & Forex            |
//+------------------------------------------------------------------+
double CalculateSmartLot(double entryPrice, double slPrice)
  {
   if(InpRiskMode == RISK_BY_FIXED_LOT)
      return NormalizeLot(InpFixedLot);

   double capital = (InpRiskMode == RISK_BY_EQUITY_PERCENT) ? m_account.Equity() : m_account.Balance();
   double riskPct = MathMax(0.1, MathMin(InpRiskPercent, 5.0));
   double riskCash = capital * (riskPct / 100.0);

   double slPoints = MathAbs(entryPrice - slPrice) / m_symbol.Point();
   if(slPoints <= 0)
      return NormalizeLot(m_symbol.LotsMin());

   double tickVal = m_symbol.TickValue();
   double tickSz  = m_symbol.TickSize();
   double pointVal = (tickSz > 0) ? (tickVal * (m_symbol.Point() / tickSz)) : tickVal;
   if(pointVal <= 0) pointVal = 1.0;

   double calcLot = riskCash / (slPoints * pointVal);
   return NormalizeLot(calcLot);
  }

//+------------------------------------------------------------------+
//| Chuan hoa Lot Size                                               |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
  {
   double minL  = m_symbol.LotsMin();
   double maxL  = m_symbol.LotsMax();
   double stepL = m_symbol.LotsStep();
   if(stepL <= 0) stepL = 0.01;

   double normalized = MathFloor(lot / stepL) * stepL;
   if(normalized < minL) normalized = minL;
   if(normalized > maxL) normalized = maxL;

   int digits = 2;
   if(stepL == 0.1) digits = 1;
   if(stepL == 1.0) digits = 0;

   return NormalizeDouble(normalized, digits);
  }

//+------------------------------------------------------------------+
//| Kiem tra va Reset Gioi han sụt giảm vốn ngày (Daily Drawdown)    |
//+------------------------------------------------------------------+
void CheckDailyRiskLimit()
  {
   datetime now = TimeCurrent();
   datetime todayStart = GetStartOfDay(now);

   if(todayStart != m_currentDay)
     {
      m_currentDay = todayStart;
      m_dayStartEquity = m_account.Equity();
      m_dailyLimitHit = false;
     }

   double currentEquity = m_account.Equity();
   double dailyLossMoney = m_dayStartEquity - currentEquity;
   double dailyLossPercent = (m_dayStartEquity > 0) ? ((dailyLossMoney / m_dayStartEquity) * 100.0) : 0.0;

   if(dailyLossPercent >= InpMaxDailyLossPct)
     {
      if(!m_dailyLimitHit)
        {
         m_dailyLimitHit = true;
         PrintFormat(">>> [DAILY SHIELD TRIGGERED] Sụt giảm ngày = %.2f%% >= %.2f%%. Khoa toan bo lenh moi hom nay!",
                     dailyLossPercent, InpMaxDailyLossPct);
        }
     }
  }

//+------------------------------------------------------------------+
//| Dem so vi the dang chay cua Bot                                  |
//+------------------------------------------------------------------+
int CountActiveTrades()
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
//| Lay gia tri buffer tu handle Indicator                           |
//+------------------------------------------------------------------+
double GetIndicatorBuffer(int handle, int bufferNum, int index)
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyBuffer(handle, bufferNum, index, 1, buf) > 0)
      return buf[0];
   return 0.0;
  }

//+------------------------------------------------------------------+
//| Lay moc 00:00:00 dau ngay                                        |
//+------------------------------------------------------------------+
datetime GetStartOfDay(datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t, dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   return StructToTime(dt);
  }

//+------------------------------------------------------------------+
//| Kiem tra gio cho phep giao dich (Kill Zones Filter)              |
//+------------------------------------------------------------------+
bool IsTradingAllowedNow()
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   if(InpTradeStartHour <= InpTradeEndHour)
      return (dt.hour >= InpTradeStartHour && dt.hour <= InpTradeEndHour);
   else
      return (dt.hour >= InpTradeStartHour || dt.hour <= InpTradeEndHour);
  }

//+------------------------------------------------------------------+
//| Ve bang thong tin Dashboard Pro tren Chart                       |
//+------------------------------------------------------------------+
void RenderDashboard()
  {
   string prefix = "TitanDash_";
   int x = 20;
   int y = 30;
   int lh = 20;

   // 1. Background
   CreateRect(prefix + "BG", x - 10, y - 10, 275, 275, C'10,15,30', C'212,175,55'); // Gold border

   // 2. Title
   CreateText(prefix + "Title", "⚜ TITAN GOLD PRO EA ⚜", x + 15, y, "Segoe UI", 10, C'234,179,8', true);

   // 3. Balance & Equity
   y += lh + 6;
   CreateText(prefix + "Bal", StringFormat("Balance: $%.2f", m_account.Balance()), x, y, "Segoe UI", 9, clrWhite);
   y += lh;
   CreateText(prefix + "Eq", StringFormat("Equity: $%.2f", m_account.Equity()), x, y, "Segoe UI", 9, clrLime);

   // 4. Spread & ATR
   y += lh;
   int sp = (int)m_symbol.Spread();
   color spCol = (sp <= InpMaxSpreadPoints) ? clrLime : clrSalmon;
   CreateText(prefix + "Sp", StringFormat("Spread: %d pts (Max: %d)", sp, InpMaxSpreadPoints), x, y, "Segoe UI", 9, spCol);

   y += lh;
   double atr = GetIndicatorBuffer(m_atrHandle, 0, 1);
   CreateText(prefix + "ATR", StringFormat("ATR(14) Volatility: %.3f", atr), x, y, "Segoe UI", 9, C'56,189,248');

   // 5. Daily DD Shield
   y += lh;
   double dayLoss = (m_dayStartEquity > 0) ? ((m_dayStartEquity - m_account.Equity()) / m_dayStartEquity * 100.0) : 0.0;
   string guardStr = m_dailyLimitHit ? "LOCKED (Max Loss Hit)" : "ACTIVE SHIELD";
   color guardCol  = m_dailyLimitHit ? clrRed : clrLime;
   CreateText(prefix + "Guard", StringFormat("Daily DD: %.2f%% [%s]", MathMax(0.0, dayLoss), guardStr), x, y, "Segoe UI", 9, guardCol);

   // 6. Strategy & Trend
   y += lh;
   string stratStr = (InpStrategyMode == STRATEGY_HYBRID_CONFLUENCE) ? "Hybrid Confluence" : "Asian Range Sweep";
   CreateText(prefix + "Strat", StringFormat("Strategy: %s", stratStr), x, y, "Segoe UI", 9, C'244,114,182');

   y += lh;
   double fastEma = GetIndicatorBuffer(m_fastEmaHandle, 0, 1);
   double slowEma = GetIndicatorBuffer(m_slowEmaHandle, 0, 1);
   string trendStr = (fastEma > slowEma) ? "BULLISH (Uptrend)" : (fastEma < slowEma ? "BEARISH (Downtrend)" : "SIDEWAY");
   color trendCol  = (fastEma > slowEma) ? clrLime : (fastEma < slowEma ? clrSalmon : clrGray);
   CreateText(prefix + "Trend", StringFormat("Market Trend: %s", trendStr), x, y, "Segoe UI", 9, trendCol);

   // 7. Active Trades & Asian Range
   y += lh;
   CreateText(prefix + "Pos", StringFormat("Open Trades: %d / %d | Risk: %.1f%%", CountActiveTrades(), InpMaxOpenTrades, InpRiskPercent), x, y, "Segoe UI", 9, clrWhite);
   
   y += lh;
   string asianStatus = m_asianRangeReady ? StringFormat("Asian: H=%.2f L=%.2f", m_asianHigh, m_asianLow) : "Asian: Forming...";
   CreateText(prefix + "Asian", asianStatus, x, y, "Segoe UI", 9, C'203,213,225');
  }

//+------------------------------------------------------------------+
//| Helper ve Text Dashboard                                         |
//+------------------------------------------------------------------+
void CreateText(string name, string text, int x, int y, string font, int fontSize, color textColor, bool bold = false)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
  }

//+------------------------------------------------------------------+
//| Helper ve Rectangle Dashboard                                    |
//+------------------------------------------------------------------+
void CreateRect(string name, int x, int y, int width, int height, color bgColor, color borderColor)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
  }
//+------------------------------------------------------------------+
