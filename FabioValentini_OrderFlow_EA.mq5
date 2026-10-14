//+------------------------------------------------------------------+
//|                                   FabioValentini_OrderFlow_EA.mq5|
//|         Robbins World Cup Champion Strategy - Fabio Valentini    |
//|         Order Flow Breakout, CVD & Pyramiding Scaling Engine     |
//+------------------------------------------------------------------+
#property copyright "Robbins World Cup Quantitative Architecture"
#property link      "https://github.com/algorithmic-trading"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- Enums
enum ENUM_ENTRY_STYLE
  {
   ENTRY_BREAKOUT_DIRECT  = 0, // Direct Breakout (Phá vỡ trực tiếp kèm đột biến CVD)
   ENTRY_PULLBACK_RETEST  = 1  // Pullback Retest (Chờ nến hồi retest biên Range)
  };

enum ENUM_PYRAMID_LEVEL
  {
   PYRAMID_NONE    = 0,
   PYRAMID_BASE    = 1, // Lệnh 1 (50% Risk)
   PYRAMID_STAGE_2 = 2, // Lệnh 2 (+25% Risk)
   PYRAMID_STAGE_3 = 3  // Lệnh 3 (+25% Risk)
  };

//--- Input Parameters
input group "=== 1. Quản trị Rủi ro Động (Dynamic Risk Budgeting) ==="
input double               InpBaseRiskPercent      = 0.5;                     // Rủi ro cơ sở mỗi chu kỳ (% Equity - Mặc định 0.5%)
input bool                 InpUseProfitCompounding = true;                    // Kích hoạt Dynamic Risk: Trích 50% lãi ngày vào lệnh sau
input double               InpProfitReinvestPct    = 50.0;                    // Tỷ lệ lợi nhuận ngày tái đầu tư vào Risk Budget (%)
input double               InpMaxDailyRiskBudgetPct= 3.0;                     // Trần rủi ro tối đa cho phép trong ngày (% Vốn)
input double               InpMaxDailyLossPercent  = 2.0;                     // Ngắt mạch lỗ tối đa trong ngày (% Equity)
input double               InpMaxTotalDrawdownPct  = 10.0;                    // Dừng khẩn cấp khi Drawdown chạm (% High-Water Mark)
input double               InpFixedLotIfNoDynamic  = 0.01;                    // Lot cố định (nếu tắt Dynamic Risk)
input bool                 InpUseDynamicSizing     = true;                    // Bật tính Lot động theo Risk Budget

input group "=== 2. Nhận diện Vùng Tích lũy (Market Range Detection) ==="
input int                  InpRangeLookbackBars    = 25;                      // Số nến M15 dò biên tích lũy (Range Lookback)
input double               InpMaxRangeWidthATR     = 2.8;                     // Biên độ hộp tối đa (x ATR) - Chặn hộp quá rộng
input double               InpMinRangeWidthATR     = 0.8;                     // Biên độ hộp tối thiểu (x ATR) - Chặn hộp quá hẹp
input int                  InpHTFTrendEMAPeriod    = 200;                     // EMA xu hướng khung lớn (Lọc thiên kiến chỉ đánh 1 chiều)
input ENUM_TIMEFRAMES      InpHTFTimeframe         = PERIOD_H1;               // Khung thời gian xác định xu hướng lớn

input group "=== 3. Order Flow & Cumulative Volume Delta (CVD) ==="
input int                  InpCVDLookbackTicks     = 1000;                    // Số tick phân tích Delta gần nhất
input double               InpCVDThresholdRatio    = 1.5;                     // Tỷ lệ xung lực CVD Delta tối thiểu để xác nhận phá biên
input bool                 InpUseVolumeAbsorption  = true;                    // Kiểm tra cạn kiệt thanh khoản gần 2 biên Range

input group "=== 4. Kích hoạt Lệnh & Chiến thuật Nhồi Vị thế (Pyramiding) ==="
input ENUM_ENTRY_STYLE     InpEntryStyle           = ENTRY_BREAKOUT_DIRECT;   // Phong cách vào lệnh (Direct Breakout / Pullback Retest)
input bool                 InpEnablePyramiding     = true;                    // Bật thuật toán nhồi lệnh thuận xu hướng (50-25-25)
input double               InpPyramidStepATR       = 1.0;                     // Khoảng cách nhịp đẩy tiếp theo để nhồi lệnh (x ATR)
input double               InpBaseLotRatio         = 0.50;                    // Tỷ lệ khối lượng lệnh 1 (50% Risk Budget)
input double               InpAddLotRatio          = 0.25;                    // Tỷ lệ khối lượng lệnh 2 & 3 (25% Risk Budget mỗi lệnh)
input int                  InpMaxPyramidStages     = 3;                       // Số tầng lệnh tối đa (Tối đa 3 lệnh: Base + 2 nhồi)

input group "=== 5. Thoát Lệnh & Trailing Stop ==="
input int                  InpExitEMAPeriod        = 20;                      // Chu kỳ EMA theo dõi thoát lệnh (EMA 20)
input bool                 InpExitOnEMACross       = true;                    // Đóng toàn bộ lệnh khi nến M15 đóng ngược qua EMA 20
input double               InpTrailingATR          = 1.2;                     // Khoảng cách Trailing Stop bảo vệ (x ATR)
input double               InpMinProfitBEATR       = 1.0;                     // Dời BE khi giá chạy được (x ATR)

input group "=== 6. Thời gian & Thông số Kỹ thuật ==="
input int                  InpStartHourGMT         = 7;                       // Giờ bắt đầu tìm cơ hội (GMT) - 14:00 VN
input int                  InpEndHourGMT           = 19;                      // Giờ dừng tìm cơ hội mới (GMT) - 02:00 VN
input ulong                InpMagicNumber          = 20261020;                // Magic Number định danh Bot
input ulong                InpSlippagePts          = 30;                      // Slippage cho phép (Points)
input bool                 InpShowHUD              = true;                    // Hiển thị bảng HUD Dashboard Order Flow

//--- Đối tượng giao dịch & Chỉ báo
CTrade         g_trade;
int            g_handleHTFEMA = INVALID_HANDLE;
int            g_handleEMA20  = INVALID_HANDLE;
int            g_handleATR    = INVALID_HANDLE;

//--- Biến trạng thái Order Flow & Range
datetime       g_lastBarTime          = 0;
double         g_rangeHigh            = 0.0;
double         g_rangeLow             = 0.0;
bool           g_rangeValid           = false;
double         g_currentCVD           = 0.0;
double         g_cvdBuyVolume         = 0.0;
double         g_cvdSellVolume        = 0.0;

//--- Quản lý Tài khoản & Rủi ro Động
double         g_dayStartBalance      = 0.0;
int            g_currentGMTDay        = -1;
double         g_dailyRealizedProfit  = 0.0;
double         g_highWaterMark        = 0.0;
bool           g_isLockedForDay       = false;
datetime       g_lastGuiUpdate        = 0;
int            g_activePyramidStage   = PYRAMID_NONE;
int            g_tradeDirection       = 0; // 1 = BUY, -1 = SELL

//+------------------------------------------------------------------+
//| Tính toán chính xác GMT hiện tại                                 |
//+------------------------------------------------------------------+
datetime GetGMTTime()
  {
   return TimeGMT();
  }

//+------------------------------------------------------------------+
//| Cập nhật Trạng thái Ngày & Reset Daily Metrics                   |
//+------------------------------------------------------------------+
void UpdateDailyAccounting()
  {
   MqlDateTime gmt;
   TimeToStruct(GetGMTTime(), gmt);

   if(gmt.day != g_currentGMTDay)
     {
      g_currentGMTDay       = gmt.day;
      g_dayStartBalance     = AccountInfoDouble(ACCOUNT_BALANCE);
      g_dailyRealizedProfit = 0.0;
      g_isLockedForDay      = false;
      PrintFormat("VALENTINI EA: New Trading Day Initialized. Starting Balance: $%.2f", g_dayStartBalance);
     }

   // Đồng bộ HWM
   double curEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(curEquity > g_highWaterMark)
      g_highWaterMark = curEquity;

   // Tính lợi nhuận đã chốt trong ngày hôm nay
   datetime dayStart = StringToTime(StringFormat("%04d.%02d.%02d 00:00", gmt.year, gmt.mon, gmt.day));
   HistorySelect(dayStart, TimeCurrent());
   int totalDeals = HistoryDealsTotal();
   double realizedToday = 0.0;

   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
         HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpMagicNumber)
        {
         realizedToday += HistoryDealGetDouble(ticket, DEAL_PROFIT)
                        + HistoryDealGetDouble(ticket, DEAL_SWAP)
                        + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        }
     }
   g_dailyRealizedProfit = realizedToday;

   // Kiểm tra ngắt mạch ngày
   double maxDailyLoss = (g_dayStartBalance > 0.0) ? (g_dayStartBalance * InpMaxDailyLossPercent / 100.0) : 20.0;
   if(g_dailyRealizedProfit <= -maxDailyLoss)
      g_isLockedForDay = true;
  }

//+------------------------------------------------------------------+
//| Tính toán Ngân sách Rủi ro Động (Dynamic Risk Budget)            |
//+------------------------------------------------------------------+
double CalculateDynamicRiskBudget()
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0) equity = 1000.0;

   // Rủi ro cơ sở
   double baseRiskMoney = equity * (InpBaseRiskPercent / 100.0);

   // Nếu có lãi trong ngày và bật Profit Compounding: Trích 50% lãi cộng vào Risk Budget
   double extraRiskMoney = 0.0;
   if(InpUseProfitCompounding && g_dailyRealizedProfit > 0.0)
     {
      extraRiskMoney = g_dailyRealizedProfit * (InpProfitReinvestPct / 100.0);
     }

   double totalRiskBudget = baseRiskMoney + extraRiskMoney;

   // Giới hạn trần rủi ro tối đa trong ngày
   double maxRiskAllowed = equity * (InpMaxDailyRiskBudgetPct / 100.0);
   if(totalRiskBudget > maxRiskAllowed)
      totalRiskBudget = maxRiskAllowed;

   return totalRiskBudget;
  }

//+------------------------------------------------------------------+
//| Tính toán Cumulative Volume Delta (CVD) từ Tick Stream           |
//+------------------------------------------------------------------+
void CalculateTickOrderFlow(double &outDelta, double &outBuyVol, double &outSellVol)
  {
   outDelta   = 0.0;
   outBuyVol  = 0.0;
   outSellVol = 0.0;

   MqlTick ticks[];
   int copied = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, InpCVDLookbackTicks);
   if(copied <= 1) return;

   for(int i = 1; i < copied; i++)
     {
      double vol = (ticks[i].volume_real > 0) ? (double)ticks[i].volume_real : (double)ticks[i].volume;
      if(vol <= 0.0) vol = 1.0;

      // Nhận diện Aggressor Side theo cơ chế chuẩn Order Flow
      if((ticks[i].flags & TICK_FLAG_BUY) != 0 || ticks[i].last >= ticks[i].ask)
        {
         outBuyVol += vol;
         outDelta  += vol;
        }
      else if((ticks[i].flags & TICK_FLAG_SELL) != 0 || ticks[i].last <= ticks[i].bid)
        {
         outSellVol += vol;
         outDelta   -= vol;
        }
      else
        {
         // Dựa trên bước nhảy giá (Tick rule)
         if(ticks[i].last > ticks[i-1].last)
           {
            outBuyVol += vol;
            outDelta  += vol;
           }
         else if(ticks[i].last < ticks[i-1].last)
           {
            outSellVol += vol;
            outDelta   -= vol;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Quét và nhận diện Vùng Tích Lũy (Range / Consolidation Box)      |
//+------------------------------------------------------------------+
bool DetectConsolidationRange(double &rangeHigh, double &rangeLow, double currentATR)
  {
   if(currentATR <= 0.0) return false;

   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_M15, 1, InpRangeLookbackBars, rates) < InpRangeLookbackBars)
      return false;

   double highest = rates[0].high;
   double lowest  = rates[0].low;

   for(int i = 1; i < InpRangeLookbackBars; i++)
     {
      if(rates[i].high > highest) highest = rates[i].high;
      if(rates[i].low < lowest)   lowest  = rates[i].low;
     }

   double rangeWidth = highest - lowest;
   // Kiểm tra điều kiện nén biến động (Consolidation Squeeze)
   if(rangeWidth < InpMinRangeWidthATR * currentATR || rangeWidth > InpMaxRangeWidthATR * currentATR)
      return false;

   rangeHigh = highest;
   rangeLow  = lowest;
   return true;
  }

//+------------------------------------------------------------------+
//| Chuẩn hóa Khối lượng giao dịch (Lot Size)                        |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
  {
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(stepLot <= 0.0) stepLot = 0.01;
   double norm = MathFloor(lot / stepLot) * stepLot;

   if(norm < minLot) norm = minLot;
   if(norm > maxLot) norm = maxLot;
   return NormalizeDouble(norm, 2);
  }

//+------------------------------------------------------------------+
//| Tính Lot theo Ngân sách Rủi ro và Tỷ lệ Nhồi (50% / 25%)        |
//+------------------------------------------------------------------+
double CalculatePyramidLot(double riskMoneyForThisStage, double entryPrice, double stopLossPrice)
  {
   if(!InpUseDynamicSizing)
      return InpFixedLotIfNoDynamic;

   double slDistance = MathAbs(entryPrice - stopLossPrice);
   if(slDistance <= 0.0) return InpFixedLotIfNoDynamic;

   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0.0 || tickValue <= 0.0) return InpFixedLotIfNoDynamic;

   double lossPerLot = (slDistance / tickSize) * tickValue;
   if(lossPerLot <= 0.0) return InpFixedLotIfNoDynamic;

   double lot = riskMoneyForThisStage / lossPerLot;
   return NormalizeLot(lot);
  }

//+------------------------------------------------------------------+
//| Đếm số vị thế đang mở của EA                                     |
//+------------------------------------------------------------------+
int CountManagedPositions(int &outDirection)
  {
   int count = 0;
   outDirection = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
        {
         count++;
         ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         outDirection = (pt == POSITION_TYPE_BUY) ? 1 : -1;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Dời Stop Loss đồng loạt cho tất cả các vị thế đang mở            |
//+------------------------------------------------------------------+
void MoveAllStops(double newSL)
  {
   newSL = NormalizeDouble(newSL, _Digits);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
        {
         double curSL = PositionGetDouble(POSITION_SL);
         double curTP = PositionGetDouble(POSITION_TP);
         ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         if(pt == POSITION_TYPE_BUY)
           {
            if(newSL > curSL + _Point)
               g_trade.PositionModify(ticket, newSL, curTP);
           }
         else if(pt == POSITION_TYPE_SELL)
           {
            if(curSL == 0.0 || newSL < curSL - _Point)
               g_trade.PositionModify(ticket, newSL, curTP);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Đóng tất cả các vị thế đang mở khẩn cấp                          |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
        {
         g_trade.PositionClose(ticket);
        }
     }
   g_activePyramidStage = PYRAMID_NONE;
   g_tradeDirection     = 0;
   Print("[VALENTINI EA EXIT] ", reason);
  }

//+------------------------------------------------------------------+
//| Giao Diện Dashboard HUD Bậc Thầy Order Flow (Góc Trái Màn Hình)  |
//+------------------------------------------------------------------+
void SetHudLabel(string name, string text, int x, int y, color clr, int fontSize=9, bool isBold=false)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, name, OBJPROP_FONT, isBold ? "Segoe UI Bold" : "Segoe UI");
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
     }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
  }

void SetHudPanel(string name, int x, int y, int width, int height, color bgColor, color borderColor)
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

void DestroyChartHUD()
  {
   ObjectsDeleteAll(0, "VALENTINI_HUD_");
   Comment("");
  }

void UpdateChartHUD()
  {
   if(!InpShowHUD)
     {
      DestroyChartHUD();
      return;
     }

   if(TimeCurrent() - g_lastGuiUpdate < 1) return;
   g_lastGuiUpdate = TimeCurrent();

   int panelX = 15;
   int panelY = 25;
   int panelW = 430;
   int panelH = 340;

   SetHudPanel("VALENTINI_HUD_BG", panelX, panelY, panelW, panelH, C'12,18,26', C'40,85,130');
   SetHudPanel("VALENTINI_HUD_HEAD", panelX, panelY, panelW, 28, C'20,40,65', clrDodgerBlue);
   SetHudLabel("VALENTINI_HUD_TITLE", "⚡ FABIO VALENTINI ORDER FLOW & PYRAMID", panelX + 12, panelY + 6, clrGold, 10, true);

   int startY = panelY + 35;
   int lineH  = 22;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskBudget = CalculateDynamicRiskBudget();

   // Dòng 1: Tài chính & Ngân sách rủi ro động
   SetHudLabel("VALENTINI_HUD_L1", StringFormat("💰 Vốn: $%.2f | Ngân Sách Risk Động: $%.2f (%.2f%%)",
                                               equity, riskBudget, (riskBudget / equity * 100.0)),
               panelX + 12, startY, clrAqua, 9, true);

   // Dòng 2: Lãi ngày & Compounding
   color pnlClr = (g_dailyRealizedProfit >= 0.0) ? clrLime : clrTomato;
   SetHudLabel("VALENTINI_HUD_L2", StringFormat("📈 Lãi Đã Chốt Ngày: %+.2f$ | Tái Đầu Tư Risk: %.0f%%",
                                               g_dailyRealizedProfit, InpProfitReinvestPct),
               panelX + 12, startY + lineH, pnlClr, 9);

   // Dòng 3: Cấu trúc Range
   string rangeDesc = g_rangeValid ? StringFormat("Hộp [%.2f - %.2f] | Biên: $%.2f", g_rangeLow, g_rangeHigh, g_rangeHigh - g_rangeLow) : "Đang Tìm Vùng Nén...";
   SetHudLabel("VALENTINI_HUD_L3", StringFormat("📦 Vùng Tích Lũy (Range): %s", rangeDesc),
               panelX + 12, startY + lineH * 2, g_rangeValid ? clrYellow : clrDarkGray, 9);

   // Dòng 4: Cumulative Volume Delta (CVD)
   color cvdClr = (g_currentCVD > 0) ? clrLime : ((g_currentCVD < 0) ? clrTomato : clrSilver);
   SetHudLabel("VALENTINI_HUD_L4", StringFormat("🌊 CVD Order Flow: %+.0f (Buy: %.0f | Sell: %.0f)",
                                               g_currentCVD, g_cvdBuyVolume, g_cvdSellVolume),
               panelX + 12, startY + lineH * 3, cvdClr, 9, true);

   // Dòng 5: Xu Hướng HTF (H1 EMA 200)
   double htfEMA[1];
   string trendStr = "CHỜ TÍN HIỆU";
   color  trendClr = clrSilver;
   if(CopyBuffer(g_handleHTFEMA, 0, 1, 1, htfEMA) == 1)
     {
      double closeM15 = iClose(_Symbol, PERIOD_M15, 1);
      if(closeM15 > htfEMA[0])
        {
         trendStr = "BULLISH 🟢 (Chỉ Canh Buy)";
         trendClr = clrLime;
        }
      else
        {
         trendStr = "BEARISH 🔴 (Chỉ Canh Sell)";
         trendClr = clrTomato;
        }
     }
   SetHudLabel("VALENTINI_HUD_L5", StringFormat("🧭 Thiên Kiến Lớn (H1 EMA200): %s", trendStr),
               panelX + 12, startY + lineH * 4, trendClr, 9);

   // Dòng 6: Trạng thái Pyramiding (Nhồi Lệnh)
   int openCount = 0, dir = 0;
   openCount = CountManagedPositions(dir);
   string pyrStr = "CHƯA CÓ LỆNH (Sẵn sàng Base 50%)";
   color  pyrClr = clrSilver;
   if(openCount == 1)
     {
      pyrStr = StringFormat("LỆNH 1 (Base 50%% Risk) - %s", (dir == 1 ? "BUY" : "SELL"));
      pyrClr = clrDeepSkyBlue;
     }
   else if(openCount == 2)
     {
      pyrStr = "LỆNH 2 (Nhồi +25% Risk - Đã BE Lệnh 1) ⚡";
      pyrClr = clrOrange;
     }
   else if(openCount >= 3)
     {
      pyrStr = "LỆNH 3 (Max Pyramiding 100%) 🏆 FULL ATTACK";
      pyrClr = clrGold;
     }
   SetHudLabel("VALENTINI_HUD_L6", StringFormat("🪜 Tầng Pyramiding: %s", pyrStr),
               panelX + 12, startY + lineH * 5, pyrClr, 9, true);

   // Dòng 7: Thoát lệnh EMA 20
   double ema20Val[1];
   double ema20Num = (CopyBuffer(g_handleEMA20, 0, 1, 1, ema20Val) == 1) ? ema20Val[0] : 0.0;
   SetHudLabel("VALENTINI_HUD_L7", StringFormat("🛡️ Đường Thoát Lệnh (EMA 20): %.2f", ema20Num),
               panelX + 12, startY + lineH * 6, clrWheat, 8);

   // Dòng 8: Trạng thái Hệ thống
   string statusText = g_isLockedForDay ? "🔴 TẠM DỪNG: DAILY LOSS LIMIT REACHED" : "🟢 SẴN SÀNG QUÉT BREAKOUT & ORDER FLOW";
   color  statusClr  = g_isLockedForDay ? clrRed : clrLime;
   SetHudLabel("VALENTINI_HUD_L8", StringFormat("🚦 Trạng Thái: %s", statusText),
               panelX + 12, startY + lineH * 7, statusClr, 9, true);

   // Dòng 9: Phiên Giao dịch
   MqlDateTime gmt;
   TimeToStruct(GetGMTTime(), gmt);
   int vnHour = (gmt.hour + 7) % 24;
   bool inSession = (gmt.hour >= InpStartHourGMT && gmt.hour < InpEndHourGMT);
   SetHudLabel("VALENTINI_HUD_L9", StringFormat("⏱️ Phiên Trade: %02d:00-%02d:00 GMT [%02dh-%02dh VN] (%s)",
                                               InpStartHourGMT, InpEndHourGMT, (InpStartHourGMT+7)%24, (InpEndHourGMT+7)%24,
                                               inSession ? "ĐANG TRONG PHIÊN" : "NGOÀI GIỜ"),
               panelX + 12, startY + lineH * 8, inSession ? clrSpringGreen : clrGray, 8);

   // Dòng 10: Chế độ Thực thi
   SetHudLabel("VALENTINI_HUD_L10", StringFormat("🎯 Chế Độ Vào Lệnh: %s",
                                                (InpEntryStyle == ENTRY_BREAKOUT_DIRECT ? "Direct Breakout (Xung Lực)" : "Pullback Retest (Bảo Thủ)")),
               panelX + 12, startY + lineH * 9, clrLightSlateGray, 8);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   DestroyChartHUD();

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePts);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   g_handleHTFEMA = iMA(_Symbol, InpHTFTimeframe, InpHTFTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_handleEMA20  = iMA(_Symbol, PERIOD_M15, InpExitEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_handleATR    = iATR(_Symbol, PERIOD_M15, 14);

   if(g_handleHTFEMA == INVALID_HANDLE || g_handleEMA20 == INVALID_HANDLE || g_handleATR == INVALID_HANDLE)
     {
      Print("Init Error: Failed to create indicators.");
      return INIT_FAILED;
     }

   g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_highWaterMark   = AccountInfoDouble(ACCOUNT_EQUITY);
   UpdateDailyAccounting();

   Print("FABIO VALENTINI ORDER FLOW SCALPING EA Initialized Successfully.");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DestroyChartHUD();
   if(g_handleHTFEMA != INVALID_HANDLE) IndicatorRelease(g_handleHTFEMA);
   if(g_handleEMA20  != INVALID_HANDLE) IndicatorRelease(g_handleEMA20);
   if(g_handleATR    != INVALID_HANDLE) IndicatorRelease(g_handleATR);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Cập nhật Kế toán Tài chính & HUD
   UpdateDailyAccounting();
   UpdateChartHUD();

   if(g_isLockedForDay) return;

   // 2. Đọc giá trị ATR hiện tại
   double atrBuf[1];
   if(CopyBuffer(g_handleATR, 0, 1, 1, atrBuf) != 1 || atrBuf[0] <= 0.0)
      return;
   double currentATR = atrBuf[0];

   // 3. Phân tích Order Flow & CVD Tức thời
   CalculateTickOrderFlow(g_currentCVD, g_cvdBuyVolume, g_cvdSellVolume);

   // 4. Quét Vùng Tích Lũy (Range Consolidation)
   g_rangeValid = DetectConsolidationRange(g_rangeHigh, g_rangeLow, currentATR);

   // 5. Quản lý Vị thế Đang Mở: Trailing Stop & Thoát Lệnh Theo EMA 20
   int openDirection = 0;
   int openCount = CountManagedPositions(openDirection);

   if(openCount > 0)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // Thoát lệnh khi nến M15 đóng ngược qua EMA 20 (Đặc trưng Fabio Valentini)
      if(InpExitOnEMACross)
        {
         double ema20[2];
         MqlRates lastRates[2];
         if(CopyBuffer(g_handleEMA20, 0, 1, 2, ema20) == 2 && CopyRates(_Symbol, PERIOD_M15, 1, 2, lastRates) == 2)
           {
            if(openDirection == 1 && lastRates[1].close < ema20[1]) // BUY mà đóng dưới EMA 20
              {
               CloseAllPositions("Nến M15 Đóng Dưới EMA 20 (Sóng Tăng Kết Thúc)");
               return;
              }
            else if(openDirection == -1 && lastRates[1].close > ema20[1]) // SELL mà đóng trên EMA 20
              {
               CloseAllPositions("Nến M15 Đóng Trên EMA 20 (Sóng Giảm Kết Thúc)");
               return;
              }
           }
        }

      // Quản lý Trailing Stop & Break-Even
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
           {
            double openP = PositionGetDouble(POSITION_PRICE_OPEN);
            double curSL = PositionGetDouble(POSITION_SL);
            double curTP = PositionGetDouble(POSITION_TP);
            ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            if(pt == POSITION_TYPE_BUY)
              {
               // Dời BE
               if(bid - openP >= InpMinProfitBEATR * currentATR && curSL < openP)
                 {
                  g_trade.PositionModify(ticket, NormalizeDouble(openP + 0.30, _Digits), curTP);
                 }
               // Trailing Stop bám sát
               double newSL = NormalizeDouble(bid - InpTrailingATR * currentATR, _Digits);
               if(newSL > openP && newSL > curSL + 0.20 * currentATR)
                 {
                  g_trade.PositionModify(ticket, newSL, curTP);
                 }
              }
            else if(pt == POSITION_TYPE_SELL)
              {
               // Dời BE
               if(openP - ask >= InpMinProfitBEATR * currentATR && (curSL == 0.0 || curSL > openP))
                 {
                  g_trade.PositionModify(ticket, NormalizeDouble(openP - 0.30, _Digits), curTP);
                 }
               // Trailing Stop bám sát
               double newSL = NormalizeDouble(ask + InpTrailingATR * currentATR, _Digits);
               if(newSL < openP && (curSL == 0.0 || newSL < curSL - 0.20 * currentATR))
                 {
                  g_trade.PositionModify(ticket, newSL, curTP);
                 }
              }
           }
        }

      // 6. THUẬT TOÁN NHỒI VỊ THẾ PYRAMIDING (STAGES 2 & 3)
      if(InpEnablePyramiding && openCount < InpMaxPyramidStages)
        {
         // Kiểm tra nếu nến mới xuất hiện
         datetime barTime = iTime(_Symbol, PERIOD_M15, 0);
         if(barTime != g_lastBarTime)
           {
            g_lastBarTime = barTime;

            // Tìm giá vào lệnh gần nhất
            double lastEntryPrice = 0.0;
            for(int i = PositionsTotal() - 1; i >= 0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol &&
                  PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
                 {
                  lastEntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                  break;
                 }
              }

            double totalRiskBudget = CalculateDynamicRiskBudget();
            double addRiskMoney    = totalRiskBudget * InpAddLotRatio; // 25% Risk

            if(openDirection == 1) // Đang có lệnh BUY
              {
               // Nhồi khi giá tiếp tục bứt phá đỉnh mới cao hơn lệnh trước ít nhất 1.0 ATR
               if(bid >= lastEntryPrice + InpPyramidStepATR * currentATR && g_currentCVD > 0)
                 {
                  double sl = NormalizeDouble(bid - InpTrailingATR * currentATR, _Digits);
                  double lot = CalculatePyramidLot(addRiskMoney, bid, sl);
                  if(lot > 0.0)
                    {
                     // Dời toàn bộ SL các lệnh cũ lên mức SL mới trước khi nhồi
                     MoveAllStops(sl);
                     string cmt = StringFormat("Valentini_Pyramid_L%d", openCount + 1);
                     if(g_trade.Buy(lot, _Symbol, ask, sl, 0.0, cmt))
                        PrintFormat("PYRAMID BUY EXECUTED Stage %d: Lot %.2f @ %.2f", openCount + 1, lot, ask);
                    }
                 }
              }
            else if(openDirection == -1) // Đang có lệnh SELL
              {
               // Nhồi khi giá tiếp tục phá đáy mới thấp hơn lệnh trước ít nhất 1.0 ATR
               if(ask <= lastEntryPrice - InpPyramidStepATR * currentATR && g_currentCVD < 0)
                 {
                  double sl = NormalizeDouble(ask + InpTrailingATR * currentATR, _Digits);
                  double lot = CalculatePyramidLot(addRiskMoney, ask, sl);
                  if(lot > 0.0)
                    {
                     // Dời toàn bộ SL các lệnh cũ lên mức SL mới trước khi nhồi
                     MoveAllStops(sl);
                     string cmt = StringFormat("Valentini_Pyramid_L%d", openCount + 1);
                     if(g_trade.Sell(lot, _Symbol, bid, sl, 0.0, cmt))
                        PrintFormat("PYRAMID SELL EXECUTED Stage %d: Lot %.2f @ %.2f", openCount + 1, lot, bid);
                    }
                 }
              }
           }
        }
      return; // Đang có lệnh mở, không quét lệnh gốc mới
     }

   // 7. KIỂM TRA ĐIỀU KIỆN MỞ LỆNH GỐC (BASE POSITION - 50% RISK)
   MqlDateTime gmt;
   TimeToStruct(GetGMTTime(), gmt);
   if(gmt.hour < InpStartHourGMT || gmt.hour >= InpEndHourGMT)
      return;

   if(!g_rangeValid) return;

   // Kiểm tra Thiên kiến Xu hướng Khung Lớn (HTF Trend Filter)
   double htfEMA[1];
   if(CopyBuffer(g_handleHTFEMA, 0, 1, 1, htfEMA) != 1) return;
   double htfEMAPrice = htfEMA[0];

   MqlRates rates[2];
   if(CopyRates(_Symbol, PERIOD_M15, 1, 2, rates) < 2) return;
   double close1 = rates[1].close;
   double prevC1 = rates[0].close;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   bool buyBreakout  = false;
   bool sellBreakout = false;

   if(InpEntryStyle == ENTRY_BREAKOUT_DIRECT)
     {
      // Breakout trực tiếp khi giá phá biên Range kèm xác nhận CVD Delta
      buyBreakout  = (close1 > g_rangeHigh) && (close1 > htfEMAPrice) && (g_currentCVD > InpCVDThresholdRatio * 10.0);
      sellBreakout = (close1 < g_rangeLow)  && (close1 < htfEMAPrice) && (g_currentCVD < -InpCVDThresholdRatio * 10.0);
     }
   else // ENTRY_PULLBACK_RETEST (Phong cách Nhật Hoài)
     {
      // Chờ nến trước phá biên, nến này hồi test biên rồi rút râu thuận xu hướng
      bool buyRetest  = (prevC1 > g_rangeHigh) && (rates[1].low <= g_rangeHigh + 0.3 * currentATR) && (close1 > g_rangeHigh);
      bool sellRetest = (prevC1 < g_rangeLow)  && (rates[1].high >= g_rangeLow - 0.3 * currentATR) && (close1 < g_rangeLow);

      buyBreakout  = buyRetest  && (close1 > htfEMAPrice) && (g_currentCVD > 0);
      sellBreakout = sellRetest && (close1 < htfEMAPrice) && (g_currentCVD < 0);
     }

   if(!buyBreakout && !sellBreakout) return;

   // 8. TÍNH TOÁN LOT CHO BASE POSITION (50% RISK BUDGET)
   double totalRiskBudget = CalculateDynamicRiskBudget();
   double baseRiskMoney   = totalRiskBudget * InpBaseLotRatio; // 50%

   if(buyBreakout)
     {
      double sl = NormalizeDouble(g_rangeLow, _Digits); // SL ban đầu đặt dưới biên dưới của Range
      // Nếu Range quá rộng thì chặn tối đa 1.8 ATR
      if(ask - sl > 1.8 * currentATR) sl = NormalizeDouble(ask - 1.8 * currentATR, _Digits);

      double lot = CalculatePyramidLot(baseRiskMoney, ask, sl);
      if(lot > 0.0)
        {
         if(g_trade.Buy(lot, _Symbol, ask, sl, 0.0, "Valentini_Base_50%"))
           {
            g_activePyramidStage = PYRAMID_BASE;
            g_tradeDirection     = 1;
            PrintFormat("BASE BUY ORDER EXECUTED: Lot %.2f @ %.2f | SL: %.2f | CVD: %.0f", lot, ask, sl, g_currentCVD);
           }
        }
     }
   else if(sellBreakout)
     {
      double sl = NormalizeDouble(g_rangeHigh, _Digits); // SL ban đầu đặt trên biên trên của Range
      // Nếu Range quá rộng thì chặn tối đa 1.8 ATR
      if(sl - bid > 1.8 * currentATR) sl = NormalizeDouble(bid + 1.8 * currentATR, _Digits);

      double lot = CalculatePyramidLot(baseRiskMoney, bid, sl);
      if(lot > 0.0)
        {
         if(g_trade.Sell(lot, _Symbol, bid, sl, 0.0, "Valentini_Base_50%"))
           {
            g_activePyramidStage = PYRAMID_BASE;
            g_tradeDirection     = -1;
            PrintFormat("BASE SELL ORDER EXECUTED: Lot %.2f @ %.2f | SL: %.2f | CVD: %.0f", lot, bid, sl, g_currentCVD);
           }
        }
     }
  }
//+------------------------------------------------------------------+
