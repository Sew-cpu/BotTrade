//+------------------------------------------------------------------+
//|                                              BreakoutSR_EA.mq5   |
//|                             Forex Support & Resistance Breakout  |
//|                                  Copyright 2026, Antigravity     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Antigravity"
#property link        "https://github.com"
#property version     "1.00"
#property description "Expert Advisor Forex: Chien luoc Breakout Ho tro - Khang cu"
#property description "Tich hop quan ly von theo % rui ro, Trailing Stop va Break-even"
#property strict

// Include thu vien giao dich chuan cua MQL5
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Enums
enum ENUM_SL_MODE
  {
   SL_MODE_OPPOSITE_LEVEL = 0, // Theo duong ho tro/khang cu doi dien
   SL_MODE_ATR            = 1, // Theo boi so ATR (Bien dong)
   SL_MODE_FIXED_POINTS   = 2  // Theo Points co dinh
  };

enum ENUM_TP_MODE
  {
   TP_MODE_RISK_REWARD    = 0, // Theo ty le Risk:Reward (vi du 1:1.5, 1:2)
   TP_MODE_FIXED_POINTS   = 1  // Theo Points co dinh
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS (THIET LAP THAM SO DAU VAO)                    |
//+------------------------------------------------------------------+
input group "=== 1. CAU HINH CHIEN LUOC BREAKOUT S/R ==="
input int               InpLookbackBars         = 30;          // So nen tim Dinh/Day (Lookback Bars)
input int               InpMinChannelPoints     = 100;         // Khoang cach S/R toi thieu (Points)
input bool              InpWaitBarClose         = true;        // Doi nen dong cua de xac nhan Breakout
input ENUM_TIMEFRAMES   InpTimeframe            = PERIOD_CURRENT; // Khung thoi gian tinh S/R

input group "=== 2. BO LOC BIEN DONG & ATR ==="
input int               InpAtrPeriod            = 14;          // Chu ky ATR
input double            InpAtrMultiplierSL      = 1.5;         // Boi so ATR cho Stop Loss

input group "=== 3. QUAN LY VON (RISK MANAGEMENT) ==="
input bool              InpAutoLotRisk          = true;        // Bat tu dong tinh Lot theo % rui ro
input double            InpRiskPercent          = 1.0;         // % Rui ro tren moi lenh (vi du: 1.0 = 1%)
input double            InpFixedLot             = 0.01;        // Khau do Lot co dinh (neu tat AutoLot)
input ENUM_SL_MODE      InpSLMode               = SL_MODE_ATR; // Phuong phap dat Stop Loss
input int               InpFixedSLPoints        = 250;         // Stop Loss co dinh (Points - neu chon Fixed)
input ENUM_TP_MODE      InpTPMode               = TP_MODE_RISK_REWARD; // Phuong phap dat Take Profit
input double            InpRiskRewardRatio      = 2.0;         // Ty le R:R (vi du 2.0 = Loi nhuan gap doi rui ro)
input int               InpFixedTPPoints        = 500;         // Take Profit co dinh (Points - neu chon Fixed)
input int               InpMaxOpenPositions     = 1;           // So vi the mo toi da tren symbol nay

input group "=== 4. TRAILING STOP & BREAK-EVEN ==="
input bool              InpUseTrailingStop      = true;        // Kich hoat Trailing Stop
input int               InpTrailingStart        = 150;         // Lãi toi thieu de bat dau Trailing (Points)
input int               InpTrailingDistance     = 150;         // Khoang cach Trailing cach gia hien tai (Points)
input int               InpTrailingStep         = 30;          // Buoc nhay Trailing (Points)

input bool              InpUseBreakEven         = true;        // Kich hoat Break-even (Doi ve hoa von)
input int               InpBreakEvenTrigger     = 120;         // Lai toi thieu de ve hoa von (Points)
input int               InpBreakEvenProfit      = 10;          // Diem SL duoc dời (Points tren Entry de bu phi)

input group "=== 5. CAU HINH HE THONG & THOI GIAN ==="
input ulong             InpMagicNumber          = 8882026;     // Magic Number rieng cho Bot
input ulong             InpSlippage             = 20;          // Do truot gia cho phep (Points)
input string            InpOrderComment         = "BreakoutSR_EA"; // Ghi chu lenh
input bool              InpUseTimeFilter        = false;       // Kich hoat loc gio giao dich
input int               InpStartHour            = 7;           // Gio bat dau giao dich (Server time)
input int               InpEndHour              = 21;          // Gio ket thuc giao dich (Server time)

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & VARIABLES                                       |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;
CAccountInfo   m_account;
CSymbolInfo    m_symbol;

int            m_atrHandle = INVALID_HANDLE;
datetime       m_lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Khoi tao thong tin Symbol
   if(!m_symbol.Name(_Symbol))
     {
      Print("Khong the khoi tao symbol: ", _Symbol);
      return INIT_FAILED;
     }
   m_symbol.Refresh();

   // Cau hinh CTrade
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(InpSlippage);
   
   // Xac dinh Filling Mode phu hop voi san
   uint filling = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((filling & SYMBOL_FILLING_IOC) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);

   // Khoi tao Indicator ATR
   m_atrHandle = iATR(_Symbol, InpTimeframe, InpAtrPeriod);
   if(m_atrHandle == INVALID_HANDLE)
     {
      Print("Loi khoi tao ATR indicator!");
      return INIT_FAILED;
     }

   Print("BreakoutSR_EA khoi tao thanh cong tren Symbol: ", _Symbol, " | Magic: ", InpMagicNumber);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(m_atrHandle != INVALID_HANDLE)
      IndicatorRelease(m_atrHandle);

   Print("BreakoutSR_EA da huy khoi tao. Ly do: ", reason);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Cap nhat thong tin gia
   if(!m_symbol.RefreshRates())
      return;

   // 1. Xu ly Trailing Stop va Break-even cho cac vi the hien co
   ManageOpenPositions();

   // 2. Kiem tra xem co nến moi khong (neu su dung InpWaitBarClose)
   if(InpWaitBarClose)
     {
      datetime currentBarTime = iTime(_Symbol, InpTimeframe, 0);
      if(currentBarTime == m_lastBarTime)
         return; // Chua dong nen moi, chua kiem tra vao lenh
      m_lastBarTime = currentBarTime;
     }

   // 3. Kiem tra gio giao dich
   if(InpUseTimeFilter && !IsTradingTimeAllowed())
      return;

   // 4. Kiem tra so luong vi the dang mo
   if(CountOpenPositions() >= InpMaxOpenPositions)
      return;

   // 5. Quet tim muc Support & Resistance
   double resistance = 0.0;
   double support = 0.0;
   if(!CalculateSupportResistance(resistance, support))
      return;

   // Kiem tra bien do kenh gia toi thieu
   double channelPoints = (resistance - support) / m_symbol.Point();
   if(channelPoints < InpMinChannelPoints)
      return;

   // 6. Kiem tra tin hieu Breakout
   CheckAndExecuteBreakout(resistance, support);
  }

//+------------------------------------------------------------------+
//| Tinh toan nguong Khang cu (Resistance) va Ho tro (Support)       |
//+------------------------------------------------------------------+
bool CalculateSupportResistance(double &resistance, double &support)
  {
   // Lay gia High va Low cua cac nen tu 1 den InpLookbackBars
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   
   int copied = CopyRates(_Symbol, InpTimeframe, 1, InpLookbackBars, rates);
   if(copied < InpLookbackBars)
     {
      Print("Khong du du lieu lich su nen de tinh S/R!");
      return false;
     }

   resistance = rates[0].high;
   support    = rates[0].low;

   for(int i = 1; i < copied; i++)
     {
      if(rates[i].high > resistance)
         resistance = rates[i].high;
      if(rates[i].low < support)
         support = rates[i].low;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Kiem tra va thuc thi tin hieu Breakout                           |
//+------------------------------------------------------------------+
void CheckAndExecuteBreakout(double resistance, double support)
  {
   // Doc nến 1 (nến vua dong)
   MqlRates lastBar[];
   ArraySetAsSeries(lastBar, true);
   if(CopyRates(_Symbol, InpTimeframe, 1, 1, lastBar) <= 0)
      return;

   double closePrice = lastBar[0].close;
   double openPrice  = lastBar[0].open;

   // Doc gia ATR
   double atrValue = GetAtrValue(1);

   // TIN HIEU BUY: Nen vua dong cao hon muc Khang cu (Bullish Breakout)
   if(closePrice > resistance && closePrice > openPrice)
     {
      double ask = m_symbol.Ask();
      double sl = CalculateBuyStopLoss(ask, support, atrValue);
      double tp = CalculateTakeProfit(ask, sl, ORDER_TYPE_BUY);

      double lotSize = CalculateLotSize(ask, sl);
      if(lotSize <= 0)
         return;

      if(m_trade.Buy(lotSize, _Symbol, ask, sl, tp, InpOrderComment))
        {
         PrintFormat(">>> LENH BUY DA MO: Lot=%.2f, Price=%.5f, SL=%.5f, TP=%.5f [Breakout Resistance=%.5f]",
                     lotSize, ask, sl, tp, resistance);
        }
      else
        {
         Print("Loi mo lenh BUY: ", m_trade.ResultRetcodeDescription());
        }
     }
   // TIN HIEU SELL: Nen vua dong thap hon muc Ho tro (Bearish Breakout)
   else if(closePrice < support && closePrice < openPrice)
     {
      double bid = m_symbol.Bid();
      double sl = CalculateSellStopLoss(bid, resistance, atrValue);
      double tp = CalculateTakeProfit(bid, sl, ORDER_TYPE_SELL);

      double lotSize = CalculateLotSize(bid, sl);
      if(lotSize <= 0)
         return;

      if(m_trade.Sell(lotSize, _Symbol, bid, sl, tp, InpOrderComment))
        {
         PrintFormat(">>> LENH SELL DA MO: Lot=%.2f, Price=%.5f, SL=%.5f, TP=%.5f [Breakout Support=%.5f]",
                     lotSize, bid, sl, tp, support);
        }
      else
        {
         Print("Loi mo lenh SELL: ", m_trade.ResultRetcodeDescription());
        }
     }
  }

//+------------------------------------------------------------------+
//| Tinh toan Stop Loss cho lenh BUY                                 |
//+------------------------------------------------------------------+
double CalculateBuyStopLoss(double entryPrice, double supportLevel, double atrValue)
  {
   double sl = 0.0;
   switch(InpSLMode)
     {
      case SL_MODE_OPPOSITE_LEVEL:
         sl = supportLevel;
         break;
      case SL_MODE_ATR:
         sl = entryPrice - (atrValue * InpAtrMultiplierSL);
         break;
      case SL_MODE_FIXED_POINTS:
         sl = entryPrice - (InpFixedSLPoints * m_symbol.Point());
         break;
     }

   // Dam bao SL khong vuot qua gia vao lenh
   if(sl >= entryPrice)
      sl = entryPrice - (InpFixedSLPoints * m_symbol.Point());

   return NormalizeDouble(sl, m_symbol.Digits());
  }

//+------------------------------------------------------------------+
//| Tinh toan Stop Loss cho lenh SELL                                |
//+------------------------------------------------------------------+
double CalculateSellStopLoss(double entryPrice, double resistanceLevel, double atrValue)
  {
   double sl = 0.0;
   switch(InpSLMode)
     {
      case SL_MODE_OPPOSITE_LEVEL:
         sl = resistanceLevel;
         break;
      case SL_MODE_ATR:
         sl = entryPrice + (atrValue * InpAtrMultiplierSL);
         break;
      case SL_MODE_FIXED_POINTS:
         sl = entryPrice + (InpFixedSLPoints * m_symbol.Point());
         break;
     }

   // Dam bao SL khong thap hon gia vao lenh
   if(sl <= entryPrice)
      sl = entryPrice + (InpFixedSLPoints * m_symbol.Point());

   return NormalizeDouble(sl, m_symbol.Digits());
  }

//+------------------------------------------------------------------+
//| Tinh toan Take Profit dua vao Risk:Reward hoac Points            |
//+------------------------------------------------------------------+
double CalculateTakeProfit(double entryPrice, double slPrice, ENUM_ORDER_TYPE orderType)
  {
   double tp = 0.0;
   double slDistance = MathAbs(entryPrice - slPrice);

   if(InpTPMode == TP_MODE_RISK_REWARD)
     {
      double targetDistance = slDistance * InpRiskRewardRatio;
      if(orderType == ORDER_TYPE_BUY)
         tp = entryPrice + targetDistance;
      else
         tp = entryPrice - targetDistance;
     }
   else // TP_MODE_FIXED_POINTS
     {
      double targetDistance = InpFixedTPPoints * m_symbol.Point();
      if(orderType == ORDER_TYPE_BUY)
         tp = entryPrice + targetDistance;
      else
         tp = entryPrice - targetDistance;
     }

   return NormalizeDouble(tp, m_symbol.Digits());
  }

//+------------------------------------------------------------------+
//| Quan ly von: Tinh Lot size dua tren % rui ro tai khoan va SL    |
//+------------------------------------------------------------------+
double CalculateLotSize(double entryPrice, double slPrice)
  {
   if(!InpAutoLotRisk)
     {
      return NormalizeLot(InpFixedLot);
     }

   double riskPercent = MathMax(0.1, MathMin(InpRiskPercent, 10.0)); // Gioi han rui ro 0.1% -> 10%
   double equity = m_account.Equity();
   double riskAmountMoney = equity * (riskPercent / 100.0); // So tien chap nhan mat

   double slDistancePoints = MathAbs(entryPrice - slPrice) / m_symbol.Point();
   if(slDistancePoints <= 0)
      return NormalizeLot(InpFixedLot);

   // Tinh gia tri moi Point cho 1 Lot tieu chuan
   double tickValue = m_symbol.TickValue();
   double tickSize  = m_symbol.TickSize();
   double pointValue = (tickSize > 0) ? (tickValue * (m_symbol.Point() / tickSize)) : (tickValue);

   if(pointValue <= 0)
      pointValue = 1.0; // Phong truong hop symbol khong tra ve tick value chuan

   // Cong thuc: Risk = Lot * SL_Points * PointValue => Lot = Risk / (SL_Points * PointValue)
   double calculatedLot = riskAmountMoney / (slDistancePoints * pointValue);

   return NormalizeLot(calculatedLot);
  }

//+------------------------------------------------------------------+
//| Chuan hoa khoi luong Lot theo quy dinh cua San                  |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
  {
   double minLot  = m_symbol.LotsMin();
   double maxLot  = m_symbol.LotsMax();
   double stepLot = m_symbol.LotsStep();

   if(stepLot <= 0)
      stepLot = 0.01;

   // Lam tron theo buoc nhay (LotsStep)
   double normalized = MathFloor(lot / stepLot) * stepLot;

   if(normalized < minLot)
      normalized = minLot;
   if(normalized > maxLot)
      normalized = maxLot;

   int digits = 2;
   if(stepLot == 0.1) digits = 1;
   if(stepLot == 1.0) digits = 0;

   return NormalizeDouble(normalized, digits);
  }

//+------------------------------------------------------------------+
//| Xu ly Trailing Stop va Break-even cho cac vi the                 |
//+------------------------------------------------------------------+
void ManageOpenPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      // Chi xu ly cac lenh thuoc Symbol va Magic Number cua Bot
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber)
         continue;

      ulong  ticket    = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double currentSL = m_position.StopLoss();
      double currentTP = m_position.TakeProfit();
      ENUM_POSITION_TYPE type = m_position.PositionType();

      // ================= 1. BREAK-EVEN =================
      if(InpUseBreakEven)
        {
         if(type == POSITION_TYPE_BUY)
           {
            double profitPoints = (m_symbol.Bid() - openPrice) / m_symbol.Point();
            double beSL = openPrice + (InpBreakEvenProfit * m_symbol.Point());
            beSL = NormalizeDouble(beSL, m_symbol.Digits());

            // Neu lai vuot qua nguong trigger va SL hien tai chua ve hoa von
            if(profitPoints >= InpBreakEvenTrigger && (currentSL < beSL || currentSL == 0))
              {
               if(m_trade.PositionModify(ticket, beSL, currentTP))
                  PrintFormat("Ticket #%d: BUY da dời ve BREAK-EVEN tai %.5f", ticket, beSL);
              }
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double profitPoints = (openPrice - m_symbol.Ask()) / m_symbol.Point();
            double beSL = openPrice - (InpBreakEvenProfit * m_symbol.Point());
            beSL = NormalizeDouble(beSL, m_symbol.Digits());

            // Neu lai vuot qua nguong trigger va SL hien tai chua ve hoa von
            if(profitPoints >= InpBreakEvenTrigger && (currentSL > beSL || currentSL == 0))
              {
               if(m_trade.PositionModify(ticket, beSL, currentTP))
                  PrintFormat("Ticket #%d: SELL da dời ve BREAK-EVEN tai %.5f", ticket, beSL);
              }
           }
        }

      // ================= 2. TRAILING STOP =================
      if(InpUseTrailingStop)
        {
         if(type == POSITION_TYPE_BUY)
           {
            double bid = m_symbol.Bid();
            double profitPoints = (bid - openPrice) / m_symbol.Point();

            if(profitPoints >= InpTrailingStart)
              {
               double newSL = bid - (InpTrailingDistance * m_symbol.Point());
               newSL = NormalizeDouble(newSL, m_symbol.Digits());

               // Chi dời khi SL moi cao hon SL cu it nhat mot khoang TrailingStep
               if(newSL > currentSL + (InpTrailingStep * m_symbol.Point()) || currentSL == 0)
                 {
                  if(m_trade.PositionModify(ticket, newSL, currentTP))
                     PrintFormat("Ticket #%d: Trailing Stop BUY dời len %.5f", ticket, newSL);
                 }
              }
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double ask = m_symbol.Ask();
            double profitPoints = (openPrice - ask) / m_symbol.Point();

            if(profitPoints >= InpTrailingStart)
              {
               double newSL = ask + (InpTrailingDistance * m_symbol.Point());
               newSL = NormalizeDouble(newSL, m_symbol.Digits());

               // Chi dời khi SL moi thap hon SL cu it nhat mot khoang TrailingStep
               if(newSL < currentSL - (InpTrailingStep * m_symbol.Point()) || currentSL == 0)
                 {
                  if(m_trade.PositionModify(ticket, newSL, currentTP))
                     PrintFormat("Ticket #%d: Trailing Stop SELL dời xuong %.5f", ticket, newSL);
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Dem so luong vi the dang mo cua Bot tren Symbol nay              |
//+------------------------------------------------------------------+
int CountOpenPositions()
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
//| Lay gia tri ATR tai barIndex                                     |
//+------------------------------------------------------------------+
double GetAtrValue(int barIndex)
  {
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   if(CopyBuffer(m_atrHandle, 0, barIndex, 1, atrBuffer) > 0)
      return atrBuffer[0];
   return 0.0010; // Gia tri mac dinh du phong (10 pips)
  }

//+------------------------------------------------------------------+
//| Kiem tra gio cho phep giao dich                                  |
//+------------------------------------------------------------------+
bool IsTradingTimeAllowed()
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   
   if(InpStartHour <= InpEndHour)
      return (dt.hour >= InpStartHour && dt.hour <= InpEndHour);
   else // Chuyen dem qua 0h
      return (dt.hour >= InpStartHour || dt.hour <= InpEndHour);
  }
//+------------------------------------------------------------------+
