//+------------------------------------------------------------------+
//|                                           ApexConfluence_EA.mq5  |
//|                    High Profit & Low Risk Multi-Confluence Robot |
//|                                  Copyright 2026, Antigravity     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Antigravity"
#property link        "https://github.com"
#property version     "2.00"
#property description "Expert Advisor Forex Dinh Cao: Confluence Da Chi Bao"
#property description "EMA Trend + Bollinger Squeeze + RSI Momentum + ATR Dynamic SL"
#property description "Tich hop Partial Close, Trailing Stop, Break-Even & Max Daily Loss Guard"
#property strict

//--- Thu vien giao dich chuan MQL5
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS & DEFINITIONS                                              |
//+------------------------------------------------------------------+
enum ENUM_RISK_MODE
  {
   RISK_PERCENT_EQUITY = 0, // Tinh Lot theo % Equity (Khuyen nghi)
   RISK_PERCENT_BALANCE = 1, // Tinh Lot theo % Balance
   RISK_FIXED_LOT       = 2  // Lot co dinh
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS (THIET LAP THAM SO DAU VAO)                    |
//+------------------------------------------------------------------+
input group "=== 1. QUAN LY VON & RUI RO THAP (LOW RISK GUARD) ==="
input ENUM_RISK_MODE    InpRiskMode             = RISK_PERCENT_EQUITY; // Che do tinh khoi luong
input double            InpRiskPercent          = 1.0;                 // % Rui ro tren moi lenh (0.5% - 1.5%)
input double            InpFixedLotSize         = 0.01;                // Lot co dinh neu dung Fixed
input double            InpMaxDailyLossPercent  = 3.0;                 // Gioi han lo toi da trong ngay (%)
input int               InpMaxSpreadPoints      = 30;                  // Spread toi da cho phep vao lenh (Points)
input int               InpMaxPositions         = 1;                   // So vi the mo toi da tren symbol nay

input group "=== 2. BO LOC XU HUONG (TREND FILTER - DOW & EMA) ==="
input bool              InpUseTrendFilter       = true;                // Bat bo loc xu huong EMA
input int               InpFastEmaPeriod        = 50;                  // EMA Nhanh (Xu huong trung han)
input int               InpSlowEmaPeriod        = 200;                 // EMA Cham (Xu huong dai han)
input ENUM_TIMEFRAMES   InpTrendTimeframe       = PERIOD_CURRENT;      // Khung thoi gian xac dinh xu huong

input group "=== 3. XUNG LUONG & BIEN DO (RSI & BOLLINGER BANDS) ==="
input int               InpRsiPeriod            = 14;                  // Chu ky RSI
input double            InpRsiBuyMin            = 50.0;                // RSI Buy toi thieu (tren 50 la Bullish)
input double            InpRsiBuyMax            = 70.0;                // RSI Buy toi da (tranh mua o Qua Mua)
input double            InpRsiSellMax           = 50.0;                // RSI Sell toi da (duoi 50 la Bearish)
input double            InpRsiSellMin           = 30.0;                // RSI Sell toi thieu (tranh ban o Qua Ban)

input int               InpBandsPeriod          = 20;                  // Chu ky Bollinger Bands
input double            InpBandsDeviation       = 2.0;                 // Do lech chuan Bollinger Bands
input bool              InpFilterBandSqueeze    = true;                // Lọc Bollinger Squeeze (bien do nen)

input group "=== 4. STOP LOSS & TAKE PROFIT THEO ATR (HIGH R:R) ==="
input int               InpAtrPeriod            = 14;                  // Chu ky ATR
input double            InpAtrMultiplierSL      = 1.5;                 // Boi so ATR cho Stop Loss (1.5x)
input double            InpRiskRewardRatio      = 2.5;                 // Ty le R:R (1:2.5 mang lai loi nhuan vuot troi)

input group "=== 5. CHOT LOI TUNG PHAN (PARTIAL TAKE PROFIT) ==="
input bool              InpUsePartialClose      = true;                // Kich hoat chot loi 50% khoi luong
input double            InpPartialCloseRatioR   = 1.5;                 // Chot 50% khi dat bao nhieu R (1.5R)

input group "=== 6. KHOA LOI NHUAN: BREAK-EVEN & TRAILING STOP ==="
input bool              InpUseBreakEven         = true;                // Kich hoat Break-Even (Hoa von)
input double            InpBreakEvenTriggerR    = 1.0;                 // Dua ve hoa von khi lai dat 1.0R
input int               InpBreakEvenLockPoints  = 10;                  // Points cong them tren Entry (bu phi)

input bool              InpUseTrailingStop      = true;                // Kich hoat Trailing Stop
input double            InpTrailingStartR       = 1.5;                 // Bat dau Trailing khi lai vuot 1.5R
input double            InpTrailingDistanceATR  = 1.2;                 // Khoang cach Trailing tinh theo x ATR
input int               InpTrailingStepPoints   = 20;                  // Buoc nhay Trailing (Points)

input group "=== 7. BO LOC PHIEN GIAO DICH (TIME FILTER) ==="
input bool              InpUseTimeFilter        = true;                // Bat bo loc gio giao dich
input int               InpStartHour            = 8;                   // Gio bat dau (Phien London & New York)
input int               InpEndHour              = 21;                  // Gio ket thuc (Tranh phien dem gian spread)

input group "=== 8. THIET LAP HE THONG & DASHBOARD ==="
input ulong             InpMagicNumber          = 9992026;             // Magic Number
input ulong             InpSlippage             = 20;                  // Truot gia cho phep (Points)
input string            InpTradeComment         = "ApexConfluence";    // Ghi chu lenh
input bool              InpShowDashboard        = true;                // Hien thi bang Dashboard tren chart

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

   // Tự động nhận diện Filling Mode của Broker
   uint filling = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((filling & SYMBOL_FILLING_IOC) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);

   // Khoi tao cac Indicators
   m_fastEmaHandle = iMA(_Symbol, InpTrendTimeframe, InpFastEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_slowEmaHandle = iMA(_Symbol, InpTrendTimeframe, InpSlowEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_rsiHandle     = iRSI(_Symbol, PERIOD_CURRENT, InpRsiPeriod, PRICE_CLOSE);
   m_bandsHandle   = iBands(_Symbol, PERIOD_CURRENT, InpBandsPeriod, 0, InpBandsDeviation, PRICE_CLOSE);
   m_atrHandle     = iATR(_Symbol, PERIOD_CURRENT, InpAtrPeriod);

   if(m_fastEmaHandle == INVALID_HANDLE || m_slowEmaHandle == INVALID_HANDLE ||
      m_rsiHandle == INVALID_HANDLE || m_bandsHandle == INVALID_HANDLE || m_atrHandle == INVALID_HANDLE)
     {
      Print("Loi khoi tao chi bao ky thuat!");
      return INIT_FAILED;
     }

   m_dayStartEquity = m_account.Equity();
   m_currentDay     = GetStartOfDay(TimeCurrent());

   Print(">>> ApexConfluence_EA khoi tao thanh cong tren ", _Symbol, " | Magic: ", InpMagicNumber);
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

   // Xoa Dashboard objects
   ObjectsDeleteAll(0, "ApexDash_");
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

   // 2. Quan ly cac vi the dang mo (Break-Even, Partial Close, Trailing Stop)
   ManageActivePositions();

   // 3. Cap nhat giao dien Dashboard
   if(InpShowDashboard)
      RenderDashboard();

   // Neu da cham gioi han lo trong ngay, khoa giao dich
   if(m_dailyLimitHit)
      return;

   // 4. Kiem tra Spread
   int currentSpread = (int)m_symbol.Spread();
   if(currentSpread > InpMaxSpreadPoints)
      return;

   // 5. Kiem tra gio giao dich
   if(InpUseTimeFilter && !IsTradingAllowedNow())
      return;

   // 6. Kiem tra co phai nen moi khong
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime == m_lastBarTime)
      return; // Chi thuc thi khi nen cu vua dong cua de tranh fakeout

   m_lastBarTime = barTime;

   // 7. Kiem tra so luong vi the dang chay
   if(CountActivePositions() >= InpMaxPositions)
      return;

   // 8. Kiem tra tin hieu vao lenh Confluence
   CheckSignalAndExecute();
  }

//+------------------------------------------------------------------+
//| Kiem tra va thuc thi tin hieu hoi tu Confluence                  |
//+------------------------------------------------------------------+
void CheckSignalAndExecute()
  {
   // Doc du lieu tu cac Indicator
   double fastEma = GetIndicatorBuffer(m_fastEmaHandle, 0, 1);
   double slowEma = GetIndicatorBuffer(m_slowEmaHandle, 0, 1);
   double rsi     = GetIndicatorBuffer(m_rsiHandle, 0, 1);
   double upperBand = GetIndicatorBuffer(m_bandsHandle, 1, 1);
   double lowerBand = GetIndicatorBuffer(m_bandsHandle, 2, 1);
   double middleBand = GetIndicatorBuffer(m_bandsHandle, 0, 1);
   double atr     = GetIndicatorBuffer(m_atrHandle, 0, 1);

   if(fastEma == 0 || slowEma == 0 || rsi == 0 || atr == 0)
      return;

   // Doc thong tin 2 nen gan nhat (nen 1 vua dong, nen 2 truoc do)
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_CURRENT, 1, 2, rates) < 2)
      return;

   double close1 = rates[0].close;
   double open1  = rates[0].open;
   double low1   = rates[0].low;
   double high1  = rates[0].high;

   // --- DIEU KIEN BUY CONFLUENCE ---
   // 1. Xu huong: Fast EMA > Slow EMA VA Gia dong cua > Fast EMA
   bool trendBuy = (!InpUseTrendFilter) || (fastEma > slowEma && close1 > fastEma);

   // 2. Xung luong: RSI nam trong vung Bullish lanh manh (50 -> 70)
   bool rsiBuy = (rsi >= InpRsiBuyMin && rsi <= InpRsiBuyMax);

   // 3. Bollinger Confirmation: Gia vuot qua Middle Band huong len
   bool bandBuy = (close1 > middleBand && open1 <= middleBand);

   // 4. Nen tang xac nhan (Bullish candle)
   bool candleBuy = (close1 > open1);

   if(trendBuy && rsiBuy && bandBuy && candleBuy)
     {
      double ask = m_symbol.Ask();
      double slDistance = atr * InpAtrMultiplierSL;
      double sl = NormalizeDouble(ask - slDistance, m_symbol.Digits());
      double tp = NormalizeDouble(ask + (slDistance * InpRiskRewardRatio), m_symbol.Digits());

      double lot = CalculateLotSize(ask, sl);
      if(lot > 0)
        {
         if(m_trade.Buy(lot, _Symbol, ask, sl, tp, InpTradeComment))
           {
            PrintFormat(">>> [BUY EXECUTED] Lot=%.2f | Price=%.5f | SL=%.5f | TP=%.5f | RSI=%.1f | ATR=%.5f",
                        lot, ask, sl, tp, rsi, atr);
           }
        }
      return;
     }

   // --- DIEU KIEN SELL CONFLUENCE ---
   // 1. Xu huong: Fast EMA < Slow EMA VA Gia dong cua < Fast EMA
   bool trendSell = (!InpUseTrendFilter) || (fastEma < slowEma && close1 < fastEma);

   // 2. Xung luong: RSI nam trong vung Bearish lanh manh (30 -> 50)
   bool rsiSell = (rsi <= InpRsiSellMax && rsi >= InpRsiSellMin);

   // 3. Bollinger Confirmation: Gia vuot qua Middle Band huong xuong
   bool bandSell = (close1 < middleBand && open1 >= middleBand);

   // 4. Nen giam xac nhan (Bearish candle)
   bool candleSell = (close1 < open1);

   if(trendSell && rsiSell && bandSell && candleSell)
     {
      double bid = m_symbol.Bid();
      double slDistance = atr * InpAtrMultiplierSL;
      double sl = NormalizeDouble(bid + slDistance, m_symbol.Digits());
      double tp = NormalizeDouble(bid - (slDistance * InpRiskRewardRatio), m_symbol.Digits());

      double lot = CalculateLotSize(bid, sl);
      if(lot > 0)
        {
         if(m_trade.Sell(lot, _Symbol, bid, sl, tp, InpTradeComment))
           {
            PrintFormat(">>> [SELL EXECUTED] Lot=%.2f | Price=%.5f | SL=%.5f | TP=%.5f | RSI=%.1f | ATR=%.5f",
                        lot, bid, sl, tp, rsi, atr);
           }
        }
      return;
     }
  }

//+------------------------------------------------------------------+
//| Quan ly vi the: Partial Close, Break-Even & Trailing Stop        |
//+------------------------------------------------------------------+
void ManageActivePositions()
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

      // Tinh khoang cach 1R ban dau
      double initialRiskDist = 0.0;
      if(currentSL > 0)
         initialRiskDist = MathAbs(openPrice - currentSL);
      else
         initialRiskDist = atr * InpAtrMultiplierSL;

      if(initialRiskDist <= 0) initialRiskDist = 100 * m_symbol.Point();

      double currentProfitDist = 0.0;
      if(type == POSITION_TYPE_BUY)
         currentProfitDist = m_symbol.Bid() - openPrice;
      else
         currentProfitDist = openPrice - m_symbol.Ask();

      double profitInR = currentProfitDist / initialRiskDist;

      // 1. CHOT LOI TUNG PHAN (PARTIAL CLOSE 50%)
      if(InpUsePartialClose && profitInR >= InpPartialCloseRatioR)
        {
         // Kiem tra comment vi the xem da tung partial close chua
         string comment = m_position.Comment();
         if(StringFind(comment, "[PC]") < 0)
           {
            double stepLot = m_symbol.LotsStep();
            double minLot  = m_symbol.LotsMin();
            double closeLot = MathFloor((volume * 0.5) / stepLot) * stepLot;

            if(closeLot >= minLot && (volume - closeLot) >= minLot)
              {
               if(m_trade.PositionClosePartial(ticket, closeLot))
                 {
                  PrintFormat(">>> [PARTIAL CLOSE] Ticket #%d: Da chot 50%% (%.2f Lot) tai %.2f R",
                              ticket, closeLot, profitInR);
                 }
              }
           }
        }

      // 2. BREAK-EVEN (Doi SL ve hoa von + buffer)
      if(InpUseBreakEven && profitInR >= InpBreakEvenTriggerR)
        {
         if(type == POSITION_TYPE_BUY)
           {
            double beSL = openPrice + (InpBreakEvenLockPoints * m_symbol.Point());
            beSL = NormalizeDouble(beSL, m_symbol.Digits());
            if(currentSL < beSL || currentSL == 0)
              {
               if(m_trade.PositionModify(ticket, beSL, currentTP))
                  PrintFormat(">>> [BREAK-EVEN] Ticket #%d BUY da dua ve hoa von tai %.5f", ticket, beSL);
              }
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double beSL = openPrice - (InpBreakEvenLockPoints * m_symbol.Point());
            beSL = NormalizeDouble(beSL, m_symbol.Digits());
            if(currentSL > beSL || currentSL == 0)
              {
               if(m_trade.PositionModify(ticket, beSL, currentTP))
                  PrintFormat(">>> [BREAK-EVEN] Ticket #%d SELL da dua ve hoa von tai %.5f", ticket, beSL);
              }
           }
        }

      // 3. TRAILING STOP DONG THEO ATR
      if(InpUseTrailingStop && profitInR >= InpTrailingStartR)
        {
         double trailDist = atr * InpTrailingDistanceATR;
         if(type == POSITION_TYPE_BUY)
           {
            double newSL = NormalizeDouble(m_symbol.Bid() - trailDist, m_symbol.Digits());
            if(newSL > currentSL + (InpTrailingStepPoints * m_symbol.Point()) || currentSL == 0)
              {
               if(m_trade.PositionModify(ticket, newSL, currentTP))
                  PrintFormat(">>> [TRAILING STOP] Ticket #%d BUY SL doi len %.5f", ticket, newSL);
              }
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double newSL = NormalizeDouble(m_symbol.Ask() + trailDist, m_symbol.Digits());
            if(newSL < currentSL - (InpTrailingStepPoints * m_symbol.Point()) || currentSL == 0)
              {
               if(m_trade.PositionModify(ticket, newSL, currentTP))
                  PrintFormat(">>> [TRAILING STOP] Ticket #%d SELL SL doi xuong %.5f", ticket, newSL);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Quan ly rui ro: Tinh Lot Size theo % von (Low Risk Calculation)  |
//+------------------------------------------------------------------+
double CalculateLotSize(double entryPrice, double slPrice)
  {
   if(InpRiskMode == RISK_FIXED_LOT)
      return NormalizeLot(InpFixedLotSize);

   double baseCapital = (InpRiskMode == RISK_PERCENT_EQUITY) ? m_account.Equity() : m_account.Balance();
   double riskPercent = MathMax(0.1, MathMin(InpRiskPercent, 5.0)); // Gioi han rui ro 0.1% -> 5%
   double moneyRisk   = baseCapital * (riskPercent / 100.0);

   double slDistancePoints = MathAbs(entryPrice - slPrice) / m_symbol.Point();
   if(slDistancePoints <= 0)
      return NormalizeLot(m_symbol.LotsMin());

   double tickValue = m_symbol.TickValue();
   double tickSize  = m_symbol.TickSize();
   double pointValue = (tickSize > 0) ? (tickValue * (m_symbol.Point() / tickSize)) : tickValue;
   if(pointValue <= 0) pointValue = 1.0;

   double rawLot = moneyRisk / (slDistancePoints * pointValue);
   return NormalizeLot(rawLot);
  }

//+------------------------------------------------------------------+
//| Chuan hoa khoi luong Lot                                         |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
  {
   double minLot  = m_symbol.LotsMin();
   double maxLot  = m_symbol.LotsMax();
   double stepLot = m_symbol.LotsStep();
   if(stepLot <= 0) stepLot = 0.01;

   double normalized = MathFloor(lot / stepLot) * stepLot;
   if(normalized < minLot) normalized = minLot;
   if(normalized > maxLot) normalized = maxLot;

   int digits = 2;
   if(stepLot == 0.1) digits = 1;
   if(stepLot == 1.0) digits = 0;

   return NormalizeDouble(normalized, digits);
  }

//+------------------------------------------------------------------+
//| Kiem tra va Reset Gioi han Lo toi da trong ngay (Daily Guard)   |
//+------------------------------------------------------------------+
void CheckDailyRiskLimit()
  {
   datetime now = TimeCurrent();
   datetime todayStart = GetStartOfDay(now);

   // Neu sang ngay moi, cap nhat lai muc von khoi dau
   if(todayStart != m_currentDay)
     {
      m_currentDay = todayStart;
      m_dayStartEquity = m_account.Equity();
      m_dailyLimitHit = false;
      Print(">>> [DAILY RESET] Sang ngay moi! Day Start Equity: ", m_dayStartEquity);
     }

   double currentEquity = m_account.Equity();
   double dailyDrawdownMoney = m_dayStartEquity - currentEquity;
   double dailyDrawdownPercent = (m_dayStartEquity > 0) ? ((dailyDrawdownMoney / m_dayStartEquity) * 100.0) : 0.0;

   if(dailyDrawdownPercent >= InpMaxDailyLossPercent)
     {
      if(!m_dailyLimitHit)
        {
         m_dailyLimitHit = true;
         PrintFormat(">>> [ALERT] Chạm giới hạn lỗ tối đa trong ngày (Drawdown=%.2f%% >= %.2f%%). Tạm dừng mở lệnh mới!",
                     dailyDrawdownPercent, InpMaxDailyLossPercent);
        }
     }
  }

//+------------------------------------------------------------------+
//| Dem so vi the dang chay cua Bot                                  |
//+------------------------------------------------------------------+
int CountActivePositions()
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
//| Lay thoi gian 00:00:00 dau ngay                                  |
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
//| Kiem tra gio cho phep giao dich                                  |
//+------------------------------------------------------------------+
bool IsTradingAllowedNow()
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   if(InpStartHour <= InpEndHour)
      return (dt.hour >= InpStartHour && dt.hour <= InpEndHour);
   else
      return (dt.hour >= InpStartHour || dt.hour <= InpEndHour);
  }

//+------------------------------------------------------------------+
//| Ve bang thong tin Dashboard tren Chart                           |
//+------------------------------------------------------------------+
void RenderDashboard()
  {
   string prefix = "ApexDash_";
   int x = 20;
   int y = 30;
   int lineHeight = 20;

   // 1. Background Box
   CreateRectLabel(prefix + "BG", x - 10, y - 10, 260, 240, C'15,23,42', C'51,65,85');

   // 2. Title
   CreateLabel(prefix + "Title", "★ APEX CONFLUENCE EA ★", x, y, "Segoe UI", 10, C'56,189,248', true);

   // 3. Balance & Equity
   y += lineHeight + 5;
   CreateLabel(prefix + "Balance", StringFormat("Balance: $%.2f", m_account.Balance()), x, y, "Segoe UI", 9, clrWhite);
   y += lineHeight;
   CreateLabel(prefix + "Equity", StringFormat("Equity: $%.2f", m_account.Equity()), x, y, "Segoe UI", 9, clrLime);

   // 4. Spread & Risk %
   y += lineHeight;
   int spread = (int)m_symbol.Spread();
   color spreadColor = (spread <= InpMaxSpreadPoints) ? clrLime : clrSalmon;
   CreateLabel(prefix + "Spread", StringFormat("Spread: %d pts (Max: %d)", spread, InpMaxSpreadPoints), x, y, "Segoe UI", 9, spreadColor);

   y += lineHeight;
   CreateLabel(prefix + "Risk", StringFormat("Risk per Trade: %.1f%% (R:R 1:%.1f)", InpRiskPercent, InpRiskRewardRatio), x, y, "Segoe UI", 9, C'251,191,36');

   // 5. Daily Guard Status
   y += lineHeight;
   double dayDD = (m_dayStartEquity > 0) ? ((m_dayStartEquity - m_account.Equity()) / m_dayStartEquity * 100.0) : 0.0;
   string statusText = m_dailyLimitHit ? "LOCKED (Max DD Hit)" : "ACTIVE";
   color statusColor = m_dailyLimitHit ? clrRed : clrLime;
   CreateLabel(prefix + "DailyGuard", StringFormat("Daily DD: %.2f%% [%s]", MathMax(0.0, dayDD), statusText), x, y, "Segoe UI", 9, statusColor);

   // 6. Trend State
   y += lineHeight;
   double fastEma = GetIndicatorBuffer(m_fastEmaHandle, 0, 1);
   double slowEma = GetIndicatorBuffer(m_slowEmaHandle, 0, 1);
   string trendStr = (fastEma > slowEma) ? "UPTREND (Bullish)" : (fastEma < slowEma ? "DOWNTREND (Bearish)" : "NEUTRAL");
   color trendCol  = (fastEma > slowEma) ? clrLime : (fastEma < slowEma ? clrSalmon : clrGray);
   CreateLabel(prefix + "Trend", StringFormat("Trend: %s", trendStr), x, y, "Segoe UI", 9, trendCol);

   // 7. Active Positions
   y += lineHeight;
   int activePos = CountActivePositions();
   CreateLabel(prefix + "Positions", StringFormat("Active Positions: %d / %d", activePos, InpMaxPositions), x, y, "Segoe UI", 9, clrWhite);
  }

//+------------------------------------------------------------------+
//| Helper tao Label chu tren Chart                                  |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, string font, int fontSize, color textColor, bool bold = false)
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
//| Helper tao Khung nen chu nhat tren Chart                         |
//+------------------------------------------------------------------+
void CreateRectLabel(string name, int x, int y, int width, int height, color bgColor, color borderColor)
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
