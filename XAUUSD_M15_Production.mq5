//+------------------------------------------------------------------+
//|                                        XAUUSD_M15_Production.mq5 |
//|                        Production-Grade Specification Validation |
//+------------------------------------------------------------------+
#property copyright "Algorithmic Trading Architecture"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>

//--- Enums định nghĩa cấu hình rõ ràng, tránh giả định ngầm
enum ENUM_DST_SCHEDULE
  {
   DST_US   = 0, // US DST (Chủ Nhật thứ 2 Tháng 3 -> Chủ Nhật đầu tiên Tháng 11)
   DST_EU   = 1, // EU/UK DST (Chủ Nhật cuối Tháng 3 -> Chủ Nhật cuối Tháng 10)
   DST_NONE = 2  // Không đổi giờ DST (Offset cố định quanh năm)
  };

enum ENUM_COMMISSION_MODE
  {
   COMM_CHARGED_PER_SIDE     = 0, // Sàn thu phí từng chiều (Deal IN mới thu 1/2 -> Nhân 2 khi dự tính đóng)
   COMM_CHARGED_UPFRONT_FULL = 1  // Sàn thu trọn gói 2 chiều ngay ở Deal IN (Giữ nguyên 1x)
  };

enum ENUM_LOCKDOWN_SCOPE
  {
   SCOPE_THIS_EA_ONLY   = 0, // Chỉ đóng lệnh của EA này (Cùng Symbol + MagicNumber)
   SCOPE_ENTIRE_ACCOUNT = 1  // Đóng toàn bộ vị thế và lệnh chờ trên tài khoản
  };

//--- Input Parameters
input group "=== 1. Quản trị Rủi ro & Nguồn vốn (Theo % Account Currency) ==="
input double               InpInitialDeposit      = 1000.0;                  // Vốn mốc ban đầu (Theo đồng tiền TK)
input double               InpFixedLot            = 0.01;                    // Khối lượng vào lệnh (Lot)
input double               InpMaxRiskPercent      = 1.2;                     // Trần rủi ro tối đa mỗi lệnh (% Vốn đầu ngày)
input double               InpMaxDailyLossPercent = 3.0;                     // Ngắt mạch lỗ tối đa trong ngày (% Vốn đầu ngày)
input double               InpEquityFloorPercent  = 85.0;                    // Sàn Equity tối thiểu (% so với InpInitialDeposit)
input ENUM_LOCKDOWN_SCOPE  InpLockdownScope       = SCOPE_THIS_EA_ONLY;      // Phạm vi đóng lệnh khi chạm Hard Stop

input group "=== 2. Chi phí Giao dịch & Xử lý Hòa vốn ==="
input double               InpMaxEffectiveCostPerOz = 0.35;                  // Trần chi phí (Spread + Comm quy đổi) trên 1 oz
input double               InpCommissionPerLotRT    = 7.0;                   // Commission 2 chiều ước tính / 1.0 Lot (Khi chưa mở lệnh)
input ENUM_COMMISSION_MODE InpCommissionMode        = COMM_CHARGED_PER_SIDE; // Cơ chế thu phí Commission của Broker
input double               InpBETriggerATR          = 1.2;                   // Kích hoạt dời Hòa vốn (Hệ số ATR)
input double               InpBEExtraBufferMoney    = 0.30;                  // Lãi đệm mục tiêu khi dời BE (Theo đồng tiền TK)
input double               InpTrailStartATR         = 1.5;                   // Kích hoạt Trailing Stop (Hệ số ATR)
input double               InpTrailStepATR          = 0.5;                   // Bước dịch chuyển Trailing Stop (Hệ số ATR)

input group "=== 3. Chỉ báo Kỹ thuật & SL/TP (Khung M15) ==="
input int                  InpEMAFastPeriod       = 50;                      // Chu kỳ EMA Trung hạn
input int                  InpEMASlowPeriod       = 200;                     // Chu kỳ EMA Dài hạn
input int                  InpRSIPeriod           = 14;                      // Chu kỳ RSI
input double               InpRSIBuyCrossLevel    = 45.0;                    // Mức RSI cắt lên cho lệnh BUY
input double               InpRSISellCrossLevel   = 55.0;                    // Mức RSI cắt xuống cho lệnh SELL
input int                  InpATRPeriod           = 14;                      // Chu kỳ ATR
input double               InpSLMultiplierATR     = 1.5;                     // Hệ số Stop Loss (x ATR)
input double               InpTPMultiplierATR     = 2.5;                     // Hệ số Take Profit (x ATR)
input double               InpMaxCandleSpikeATR   = 2.0;                     // Chặn vào lệnh nếu nến tín hiệu dài quá (x ATR)

input group "=== 4. Múi giờ GMT & Cấu hình Hệ thống ==="
input int                  InpStartHourGMT        = 11;                      // Giờ bắt đầu giao dịch (GMT) - 18:00 VN
input int                  InpEndHourGMT          = 18;                      // Giờ kết thúc mở lệnh mới (GMT) - 01:00 VN
input int                  InpWinterGMTOffset     = 2;                       // GMT Offset mùa đông của Server (Dùng khi Backtest)
input ENUM_DST_SCHEDULE    InpDSTSchedule         = DST_US;                  // Lịch đổi giờ mùa hè của Server (Dùng khi Backtest)
input ulong                InpMagicNumber         = 20261015;                // Magic Number định danh EA
input ulong                InpNormalDeviationPts  = 30;                      // Slippage cho phép khi mở lệnh (Points)
input ulong                InpPanicDeviationPts   = 100;                     // Slippage tối đa khi đóng lệnh khẩn cấp (Points)

input group "=== 5. Giao Diện & Bảng Điều Khiển (Visual HUD) ==="
input bool                 InpShowDashboard       = true;                    // Hiển thị HUD Dashboard trên biểu đồ
input color                InpColorTheme          = clrDodgerBlue;           // Tông màu chủ đạo Dashboard

//--- Biến toàn cục nội bộ
CTrade   g_trade;
int      g_handleEMAFast = INVALID_HANDLE;
int      g_handleEMASlow = INVALID_HANDLE;
int      g_handleRSI     = INVALID_HANDLE;
int      g_handleATR     = INVALID_HANDLE;

datetime g_lastBarTime          = 0;
int      g_currentGMTDateKey    = 0;
double   g_dayStartEquityAnchor = 0.0;
bool     g_isEmergencyLockdown  = false;
bool     g_isDailyLossLocked    = false;
datetime g_lastAlertTime        = 0;
datetime g_lastGuiUpdateTime    = 0;

string    g_gvLockdownKey;
string    g_gvDayAnchorKey;
string    g_gvDayDateKey;

//+------------------------------------------------------------------+
//| Khởi tạo tên biến GlobalVariable duy nhất cho từng EA instance   |
//+------------------------------------------------------------------+
void InitGlobalKeys()
  {
   string prefix    = "EA_" + _Symbol + "_" + IntegerToString(InpMagicNumber) + "_";
   g_gvLockdownKey  = prefix + "LOCKDOWN";
   g_gvDayAnchorKey = prefix + "DAY_ANCHOR";
   g_gvDayDateKey   = prefix + "DAY_DATE";
  }

//+------------------------------------------------------------------+
//| Tính chính xác ngày Chủ Nhật đầu tiên và cuối cùng của tháng     |
//+------------------------------------------------------------------+
void GetMonthSundays(int year, int month, int day, int dayOfWeek, int &firstSunday, int &lastSunday)
  {
   // Tìm thứ trong tuần của ngày mùng 1: Luôn dương nhờ cộng +7 trước khi chia lấy dư
   int dowOfFirst = (dayOfWeek - ((day - 1) % 7) + 7) % 7;
   firstSunday    = (dowOfFirst == 0) ? 1 : (8 - dowOfFirst);

   // Tìm số ngày tối đa của tháng
   int daysInMonth = 31;
   if(month == 4 || month == 6 || month == 9 || month == 11)
      daysInMonth = 30;
   else if(month == 2)
     {
      bool isLeap = ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0));
      daysInMonth = isLeap ? 29 : 28;
     }

   lastSunday = firstSunday;
   while(lastSunday + 7 <= daysInMonth)
      lastSunday += 7;
  }

//+------------------------------------------------------------------+
//| Tính GMT chuẩn xác trong cả Live/Demo và Strategy Tester         |
//+------------------------------------------------------------------+
datetime GetAccurateGMT()
  {
   if(!MQLInfoInteger(MQL_TESTER))
      return TimeGMT();

   datetime srvTime = TimeCurrent();
   if(InpDSTSchedule == DST_NONE)
      return srvTime - (InpWinterGMTOffset * 3600);

   MqlDateTime dt;
   TimeToStruct(srvTime, dt);

   int firstSun = 1, lastSun = 28;
   GetMonthSundays(dt.year, dt.mon, dt.day, dt.day_of_week, firstSun, lastSun);

   bool isSummer = false;
   if(InpDSTSchedule == DST_US)
     {
      // US DST: Chủ Nhật thứ 2 của Tháng 3 -> Chủ Nhật đầu tiên của Tháng 11
      int secondSunMarch = firstSun + 7;
      if(dt.mon > 3 && dt.mon < 11)
         isSummer = true;
      else if(dt.mon == 3)
         isSummer = (dt.day > secondSunMarch) || (dt.day == secondSunMarch && dt.hour >= 2);
      else if(dt.mon == 11)
         isSummer = (dt.day < firstSun) || (dt.day == firstSun && dt.hour < 2);
     }
   else if(InpDSTSchedule == DST_EU)
     {
      // EU DST: Chủ Nhật cuối cùng của Tháng 3 -> Chủ Nhật cuối cùng của Tháng 10
      if(dt.mon > 3 && dt.mon < 10)
         isSummer = true;
      else if(dt.mon == 3)
         isSummer = (dt.day > lastSun) || (dt.day == lastSun && dt.hour >= 2);
      else if(dt.mon == 10)
         isSummer = (dt.day < lastSun) || (dt.day == lastSun && dt.hour < 3);
     }

   int activeOffset = InpWinterGMTOffset + (isSummer ? 1 : 0);
   return srvTime - (activeOffset * 3600);
  }

//+------------------------------------------------------------------+
//| Đếm vị thế và lệnh chờ thuộc phạm vi quản lý                     |
//+------------------------------------------------------------------+
int CountManagedPositions(ENUM_LOCKDOWN_SCOPE scope)
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(scope == SCOPE_ENTIRE_ACCOUNT)
         count++;
      else if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
              (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         count++;
     }
   return count;
  }

int CountManagedOrders(ENUM_LOCKDOWN_SCOPE scope)
  {
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(scope == SCOPE_ENTIRE_ACCOUNT)
         count++;
      else if(OrderGetString(ORDER_SYMBOL) == _Symbol &&
              (ulong)OrderGetInteger(ORDER_MAGIC) == InpMagicNumber)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Đóng cưỡng chế vị thế & xóa lệnh chờ kèm kiểm tra Retcode        |
//+------------------------------------------------------------------+
bool PurgeManagedExposures(ENUM_LOCKDOWN_SCOPE scope)
  {
   g_trade.SetDeviationInPoints(InpPanicDeviationPts);
   bool allCleared = true;

   // 1. Xóa các lệnh chờ (Pending Orders)
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(scope == SCOPE_THIS_EA_ONLY)
        {
         if(OrderGetString(ORDER_SYMBOL) != _Symbol ||
            (ulong)OrderGetInteger(ORDER_MAGIC) != InpMagicNumber)
            continue;
        }
      if(!g_trade.OrderDelete(ticket) || g_trade.ResultRetcode() != TRADE_RETCODE_DONE)
         allCleared = false;
     }

   // 2. Đóng các vị thế đang mở (Open Positions)
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(scope == SCOPE_THIS_EA_ONLY)
        {
         if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
            (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
            continue;
        }
      if(!g_trade.PositionClose(ticket, InpPanicDeviationPts))
         allCleared = false;
      else
        {
         uint ret = g_trade.ResultRetcode();
         if(ret != TRADE_RETCODE_DONE && ret != TRADE_RETCODE_DONE_PARTIAL)
            allCleared = false;
        }
     }

   g_trade.SetDeviationInPoints(InpNormalDeviationPts);
   return (allCleared && CountManagedPositions(scope) == 0 && CountManagedOrders(scope) == 0);
  }

//+------------------------------------------------------------------+
//| Đồng bộ mốc Equity đầu ngày (00:00 GMT) và lưu GlobalVariables   |
//+------------------------------------------------------------------+
void SyncDailyAnchorState()
  {
   MqlDateTime gmt;
   TimeToStruct(GetAccurateGMT(), gmt);
   int todayKey = gmt.year * 10000 + gmt.mon * 100 + gmt.day;

   if(GlobalVariableCheck(g_gvDayDateKey) && (int)GlobalVariableGet(g_gvDayDateKey) == todayKey)
     {
      g_currentGMTDateKey    = todayKey;
      g_dayStartEquityAnchor = GlobalVariableGet(g_gvDayAnchorKey);
     }
   else
     {
      g_currentGMTDateKey    = todayKey;
      // Dùng Equity thực tế tại thời điểm mở ngày làm mốc chuẩn
      g_dayStartEquityAnchor = AccountInfoDouble(ACCOUNT_EQUITY);
      g_isDailyLossLocked    = false;
      GlobalVariableSet(g_gvDayDateKey, (double)todayKey);
      GlobalVariableSet(g_gvDayAnchorKey, g_dayStartEquityAnchor);
     }
  }

//+------------------------------------------------------------------+
//| Truy xuất tổng Commission thực tế đã phát sinh của 1 Position    |
//+------------------------------------------------------------------+
double GetPositionAccruedCommission(ulong positionTicket)
  {
   if(!PositionSelectByTicket(positionTicket))
      return 0.0;

   long posId = PositionGetInteger(POSITION_IDENTIFIER);
   if(!HistorySelectByPosition(posId))
      return 0.0;

   double totalComm = 0.0;
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++)
     {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket > 0)
         totalComm += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
     }
   return MathAbs(totalComm);
  }

//+------------------------------------------------------------------+
//| Tính rủi ro tiền tệ chính xác của lệnh sắp mở bằng OrderCalcProfit|
//+------------------------------------------------------------------+
double CalculatePreTradeRiskMoney(ENUM_ORDER_TYPE orderType, double volume, double entryPrice, double slPrice)
  {
   double expectedLoss = 0.0;
   if(!OrderCalcProfit(orderType, _Symbol, volume, entryPrice, slPrice, expectedLoss))
     {
      Print("OrderCalcProfit failed! Error: ", GetLastError());
      return DBL_MAX; // Fail-safe: Chặn vào lệnh nếu không tính được rủi ro
     }

   // Tính Commission 2 chiều theo đồng tiền tài khoản
   double commMoney = InpCommissionPerLotRT * volume;
   return MathAbs(expectedLoss) + commMoney;
  }

//+------------------------------------------------------------------+
//| Tính giá Hòa vốn (Break-Even) dựa trên OrderCalcProfit chuẩn     |
//+------------------------------------------------------------------+
double CalculateExactBreakEvenPrice(ulong posTicket, double extraBufferMoney)
  {
   if(!PositionSelectByTicket(posTicket))
      return 0.0;

   double openPrice      = PositionGetDouble(POSITION_PRICE_OPEN);
   double volume         = PositionGetDouble(POSITION_VOLUME);
   double swap           = PositionGetDouble(POSITION_SWAP);
   ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double accruedComm = GetPositionAccruedCommission(posTicket);
   double totalRoundTripComm = (InpCommissionMode == COMM_CHARGED_PER_SIDE) ? (accruedComm * 2.0) : accruedComm;
   if(totalRoundTripComm <= 0.0)
      totalRoundTripComm = InpCommissionPerLotRT * volume;

   double negativeSwap = (swap < 0.0) ? MathAbs(swap) : 0.0;
   double targetGrossProfit = totalRoundTripComm + negativeSwap + extraBufferMoney;

   // Dùng OrderCalcProfit để đo chính xác giá trị tiền tệ của 1.0 đơn vị giá (1 USD trên XAUUSD)
   ENUM_ORDER_TYPE calcType = (pt == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double testClosePrice    = (pt == POSITION_TYPE_BUY) ? (openPrice + 1.0) : (openPrice - 1.0);
   double profitPerOneUnit  = 0.0;

   if(!OrderCalcProfit(calcType, _Symbol, volume, openPrice, testClosePrice, profitPerOneUnit) || profitPerOneUnit <= 0.0)
      return 0.0;

   double requiredPriceDelta = targetGrossProfit / profitPerOneUnit;
   double bePrice = (pt == POSITION_TYPE_BUY) ? (openPrice + requiredPriceDelta) : (openPrice - requiredPriceDelta);

   return NormalizeDouble(bePrice, _Digits);
  }

//+------------------------------------------------------------------+
//| Kiểm tra khoảng cách StopsLevel và FreezeLevel hợp lệ            |
//+------------------------------------------------------------------+
bool IsStopModificationValid(ENUM_POSITION_TYPE posType, double newSL, double currentSL)
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   int stopsPts  = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   int freezePts = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double minDistance = MathMax(stopsPts, freezePts) * _Point;

   if(posType == POSITION_TYPE_BUY)
     {
      if(bid - newSL <= minDistance) return false;
      if(currentSL > 0.0 && newSL <= currentSL + _Point) return false;
     }
   else
     {
      if(newSL - ask <= minDistance) return false;
      if(currentSL > 0.0 && newSL >= currentSL - _Point) return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Quản lý Break-Even & Trailing Stop cho vị thế đang mở            |
//+------------------------------------------------------------------+
void ManageOpenPositions(double currentATR)
  {
   if(currentATR <= 0.0) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL     = PositionGetDouble(POSITION_SL);
      double curTP     = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(pt == POSITION_TYPE_BUY)
        {
         double moveDist = bid - openPrice;
         // 1. Dời Hòa vốn (Break-Even)
         if(moveDist >= InpBETriggerATR * currentATR)
           {
            double exactBE = CalculateExactBreakEvenPrice(ticket, InpBEExtraBufferMoney);
            if(exactBE > 0.0 && (curSL < exactBE - _Point || curSL == 0.0))
              {
               if(IsStopModificationValid(pt, exactBE, curSL))
                  g_trade.PositionModify(ticket, exactBE, curTP);
              }
           }
         // 2. Trailing Stop
         if(moveDist >= InpTrailStartATR * currentATR)
           {
            double candidateSL = NormalizeDouble(bid - (InpSLMultiplierATR * currentATR), _Digits);
            if(candidateSL - curSL >= InpTrailStepATR * currentATR)
              {
               if(IsStopModificationValid(pt, candidateSL, curSL))
                  g_trade.PositionModify(ticket, candidateSL, curTP);
              }
           }
        }
      else if(pt == POSITION_TYPE_SELL)
        {
         double moveDist = openPrice - ask;
         // 1. Dời Hòa vốn (Break-Even)
         if(moveDist >= InpBETriggerATR * currentATR)
           {
            double exactBE = CalculateExactBreakEvenPrice(ticket, InpBEExtraBufferMoney);
            if(exactBE > 0.0 && (curSL > exactBE + _Point || curSL == 0.0))
              {
               if(IsStopModificationValid(pt, exactBE, curSL))
                  g_trade.PositionModify(ticket, exactBE, curTP);
              }
           }
         // 2. Trailing Stop
         if(moveDist >= InpTrailStartATR * currentATR)
           {
            double candidateSL = NormalizeDouble(ask + (InpSLMultiplierATR * currentATR), _Digits);
            if(curSL == 0.0 || (curSL - candidateSL >= InpTrailStepATR * currentATR))
              {
               if(IsStopModificationValid(pt, candidateSL, curSL))
                  g_trade.PositionModify(ticket, candidateSL, curTP);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| CÁC HÀM TIỆN ÍCH VẼ GIAO DIỆN BẢNG THÔNG SỐ (ON-CHART HUD PANEL)  |
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
   else
     {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, name, OBJPROP_COLOR, borderColor);
     }
  }

void DestroyChartHUD()
  {
   ObjectsDeleteAll(0, "XAU_HUD_");
   Comment("");
  }

//+------------------------------------------------------------------+
//| Cập nhật HUD Dashboard trên màn hình biểu đồ (Góc Trái Trên)     |
//+------------------------------------------------------------------+
void UpdateChartHUD()
  {
   if(!InpShowDashboard)
     {
      DestroyChartHUD();
      return;
     }

   if(TimeCurrent() - g_lastGuiUpdateTime < 1)
      return;
   g_lastGuiUpdateTime = TimeCurrent();

   double currentEquity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double hardFloorMoney = InpInitialDeposit * (InpEquityFloorPercent / 100.0);
   double dailyLossMoney = MathMax(0.0, g_dayStartEquityAnchor - currentEquity);
   double dailyLossPct   = (g_dayStartEquityAnchor > 0.0) ? (dailyLossMoney / g_dayStartEquityAnchor * 100.0) : 0.0;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize <= 0.0) contractSize = 100.0;
   double effectiveCost = (ask - bid) + (InpCommissionPerLotRT / contractSize);
   long   curSpread     = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   MqlDateTime gmtNow;
   TimeToStruct(GetAccurateGMT(), gmtNow);
   int srvOffset = (int)MathRound((double)(TimeCurrent() - GetAccurateGMT()) / 3600.0);
   int vnHour    = (gmtNow.hour + 7) % 24;

   string statusStr = "🟢 HOẠT ĐỘNG (SẴN SÀNG TRADE)";
   color  statusClr = clrLime;
   if(g_isEmergencyLockdown)
     {
      statusStr = "🔴 KHẨN CẤP: LOCKDOWN HARD STOP";
      statusClr = clrRed;
     }
   else if(g_isDailyLossLocked)
     {
      statusStr = "🟠 TẠM DỪNG: DAILY LOSS BREACH";
      statusClr = clrOrange;
     }
   else if(gmtNow.hour < InpStartHourGMT || gmtNow.hour >= InpEndHourGMT)
     {
      statusStr = "🟡 CHỜ PHIÊN GIAO DỊCH (STANDBY)";
      statusClr = clrGold;
     }
   else if(effectiveCost > InpMaxEffectiveCostPerOz)
     {
      statusStr = "⚠️ CHI PHÍ SPREAD CAO (HOLD)";
      statusClr = clrOrangeRed;
     }

   int panelX = 15;
   int panelY = 25;
   int panelW = 415;
   int panelH = 300;

   SetHudPanel("XAU_HUD_BG", panelX, panelY, panelW, panelH, C'11,18,28', C'32,65,105');
   SetHudPanel("XAU_HUD_HEAD", panelX, panelY, panelW, 28, C'18,34,58', InpColorTheme);
   SetHudLabel("XAU_HUD_TITLE", "👑 XAUUSD M15 PRODUCTION (v2.00)", panelX + 12, panelY + 6, clrGold, 10, true);

   int startY = panelY + 36;
   int lineH  = 23;

   // Dòng 1: Vốn & Vốn mốc
   SetHudLabel("XAU_HUD_L1", StringFormat("💰 Vốn: $%.2f | Vốn Mốc Đầu: $%.2f", currentEquity, InpInitialDeposit),
               panelX + 12, startY, clrAqua, 9, true);

   // Dòng 2: Sàn Equity tối thiểu
   color floorClr = (currentEquity <= hardFloorMoney * 1.05) ? clrTomato : clrSpringGreen;
   SetHudLabel("XAU_HUD_L2", StringFormat("🛡️ Sàn Bảo Vệ: $%.2f (%.1f%% Vốn Mốc)", hardFloorMoney, InpEquityFloorPercent),
               panelX + 12, startY + lineH, floorClr, 9);

   // Dòng 3: Daily Loss
   color lossClr = (dailyLossPct > 2.0) ? clrTomato : clrLimeGreen;
   SetHudLabel("XAU_HUD_L3", StringFormat("📅 Lỗ Hôm Nay: -$%.2f (-%.2f%% / Trần: %.1f%%)", dailyLossMoney, dailyLossPct, InpMaxDailyLossPercent),
               panelX + 12, startY + lineH * 2, lossClr, 9);

   // Dòng 4: Xu hướng EMA 50 / 200
   double emaF[1], emaS[1];
   string trendStr = "CHỜ TÍN HIỆU ⚪";
   color  trendClr = clrSilver;
   if(CopyBuffer(g_handleEMAFast, 0, 1, 1, emaF) == 1 && CopyBuffer(g_handleEMASlow, 0, 1, 1, emaS) == 1)
     {
      if(emaF[0] > emaS[0])
        {
         trendStr = "TĂNG TRƯỞNG 🟢 (EMA 50 > EMA 200)";
         trendClr = clrLime;
        }
      else if(emaF[0] < emaS[0])
        {
         trendStr = "GIẢM GIÁ 🔴 (EMA 50 < EMA 200)";
         trendClr = C'255,80,80';
        }
     }
   SetHudLabel("XAU_HUD_L4", StringFormat("📈 Xu Hướng M15: %s", trendStr),
               panelX + 12, startY + lineH * 3, trendClr, 9, true);

   // Dòng 5: RSI 14 & ATR 14
   double rsiVal[1], atrVal[1];
   double rsiNum = (CopyBuffer(g_handleRSI, 0, 1, 1, rsiVal) == 1) ? rsiVal[0] : 50.0;
   double atrNum = (CopyBuffer(g_handleATR, 0, 1, 1, atrVal) == 1) ? atrVal[0] : 0.0;
   SetHudLabel("XAU_HUD_L5", StringFormat("⚡ RSI(14): %.1f [Buy>%.0f | Sell<%.0f] | ATR: $%.2f", rsiNum, InpRSIBuyCrossLevel, InpRSISellCrossLevel, atrNum),
               panelX + 12, startY + lineH * 4, clrWheat, 9);

   // Dòng 6: Spread & Chi Phí 1 oz
   color costClr = (effectiveCost > InpMaxEffectiveCostPerOz) ? clrOrangeRed : clrLightCyan;
   SetHudLabel("XAU_HUD_L6", StringFormat("⚡ Spread: %d pts | Chi Phí 1 oz: $%.2f (Trần: $%.2f)", curSpread, effectiveCost, InpMaxEffectiveCostPerOz),
               panelX + 12, startY + lineH * 5, costClr, 9);

   // Dòng 7: Vị thế đang mở
   string posDesc = "CHƯA CÓ LỆNH (Đang Quét Điểm Vào)";
   color  posClr  = clrSilver;
   int totalPos = PositionsTotal();
   for(int i = 0; i < totalPos; i++)
     {
      ulong ticket = PositionGetSymbol(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
        {
         ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double pVol  = PositionGetDouble(POSITION_VOLUME);
         double pProf = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         double pOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         posDesc = StringFormat("%s %.2f Lot @ %.2f | Lãi/Lỗ: %+.2f$",
                                (pType == POSITION_TYPE_BUY ? "BUY 🟢" : "SELL 🔴"),
                                pVol, pOpen, pProf);
         posClr = (pProf >= 0.0) ? clrLime : clrTomato;
         break;
        }
     }
   SetHudLabel("XAU_HUD_L7", StringFormat("🎯 Vị Thế: %s", posDesc),
               panelX + 12, startY + lineH * 6, posClr, 9, true);

   // Dòng 8: Khung giờ giao dịch
   bool isInSession = (gmtNow.hour >= InpStartHourGMT && gmtNow.hour < InpEndHourGMT);
   string sessionTag = isInSession ? "🟢 ĐANG TRONG PHIÊN" : "🟡 NGOÀI GIỜ CHỜ";
   SetHudLabel("XAU_HUD_L8", StringFormat("⏱️ Phiên Trade: %02d:00-%02d:00 GMT [%02dh-%02dh VN] (%s)",
                                          InpStartHourGMT, InpEndHourGMT, (InpStartHourGMT+7)%24, (InpEndHourGMT+7)%24, sessionTag),
               panelX + 12, startY + lineH * 7, isInSession ? clrLime : clrDarkGray, 8);

   // Dòng 9: Đồng hồ GMT / Giờ VN
   SetHudLabel("XAU_HUD_L9", StringFormat("🕒 Đồng Hồ: %02d:%02d GMT (Server GMT+%d) | Giờ VN: %02d:%02d",
                                          gmtNow.hour, gmtNow.min, srvOffset, vnHour, gmtNow.min),
               panelX + 12, startY + lineH * 8, clrSkyBlue, 8);

   // Dòng 10: Trạng thái Hệ thống
   SetHudLabel("XAU_HUD_L10", StringFormat("🚦 Hệ Thống: %s", statusStr),
               panelX + 12, startY + lineH * 9, statusClr, 9, true);

   // Dòng 11: Scope Quản Trị
   SetHudLabel("XAU_HUD_L11", StringFormat("🛡️ Quản Trị: %s | Magic: %d",
                                          (InpLockdownScope == SCOPE_THIS_EA_ONLY ? "Chỉ EA Này (Virtual)" : "Toàn Tài Khoản"),
                                          InpMagicNumber),
               panelX + 12, startY + lineH * 10, clrLightSlateGray, 8);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   InitGlobalKeys();
   DestroyChartHUD();

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpNormalDeviationPts);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   // Khôi phục trạng thái Lockdown nếu trước đó đã chạm Hard Stop
   if(GlobalVariableCheck(g_gvLockdownKey) && GlobalVariableGet(g_gvLockdownKey) >= 1.0)
      g_isEmergencyLockdown = true;

   SyncDailyAnchorState();

   g_handleEMAFast = iMA(_Symbol, PERIOD_M15, InpEMAFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_handleEMASlow = iMA(_Symbol, PERIOD_M15, InpEMASlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_handleRSI     = iRSI(_Symbol, PERIOD_M15, InpRSIPeriod, PRICE_CLOSE);
   g_handleATR     = iATR(_Symbol, PERIOD_M15, InpATRPeriod);

   if(g_handleEMAFast == INVALID_HANDLE || g_handleEMASlow == INVALID_HANDLE ||
      g_handleRSI == INVALID_HANDLE || g_handleATR == INVALID_HANDLE)
     {
      Print("Failed to create indicator handles!");
      return INIT_FAILED;
     }

   UpdateChartHUD();
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DestroyChartHUD();
   if(g_handleEMAFast != INVALID_HANDLE) IndicatorRelease(g_handleEMAFast);
   if(g_handleEMASlow != INVALID_HANDLE) IndicatorRelease(g_handleEMASlow);
   if(g_handleRSI     != INVALID_HANDLE) IndicatorRelease(g_handleRSI);
   if(g_handleATR     != INVALID_HANDLE) IndicatorRelease(g_handleATR);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   UpdateChartHUD();

   // 1. KIỂM TRA HARD EQUITY FLOOR & STATE MACHINE LOCKDOWN
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double hardFloorMoney = InpInitialDeposit * (InpEquityFloorPercent / 100.0);

   if(currentEquity <= hardFloorMoney && !g_isEmergencyLockdown)
     {
      g_isEmergencyLockdown = true;
      GlobalVariableSet(g_gvLockdownKey, 1.0);
      Print("CRITICAL: Equity Floor breached (", currentEquity, " <= ", hardFloorMoney, "). Entering Emergency Lockdown!");
     }

   if(g_isEmergencyLockdown)
     {
      if(PurgeManagedExposures(InpLockdownScope))
        {
         Print("Lockdown complete: All managed positions/orders confirmed closed. Removing EA.");
         SendNotification("EA LOCKDOWN COMPLETE: All managed positions closed on " + _Symbol);
         ExpertRemove();
        }
      else
        {
         if(TimeCurrent() - g_lastAlertTime >= 60)
           {
            g_lastAlertTime = TimeCurrent();
            SendNotification("WARNING: EA Lockdown retry closing positions on " + _Symbol);
           }
        }
      return;
     }

   // 2. KIỂM TRA ĐỔI NGÀY GMT & MAX DAILY LOSS
   SyncDailyAnchorState();
   double maxDailyLossMoney = g_dayStartEquityAnchor * (InpMaxDailyLossPercent / 100.0);

   if((g_dayStartEquityAnchor - currentEquity) >= maxDailyLossMoney)
     {
      if(!g_isDailyLossLocked)
        {
         g_isDailyLossLocked = true;
         Print("Daily Loss Limit reached. Purging EA positions for today.");
        }
     }

   if(g_isDailyLossLocked)
     {
      PurgeManagedExposures(SCOPE_THIS_EA_ONLY);
      return;
     }

   // 3. QUẢN LÝ VỊ THẾ ĐANG MỞ (TRÊN MỌI TICK)
   double atrBuf[2];
   if(CopyBuffer(g_handleATR, 0, 1, 1, atrBuf) == 1)
      ManageOpenPositions(atrBuf[0]);

   // 4. CHỈ KIỂM TRA TÍN HIỆU MỞ LỆNH MỚI KHI ĐÓNG NẾN M15
   datetime currentBarTime = iTime(_Symbol, PERIOD_M15, 0);
   if(currentBarTime == g_lastBarTime)
      return;

   // Kiểm tra giới hạn tối đa 1 lệnh của EA này
   if(CountManagedPositions(SCOPE_THIS_EA_ONLY) >= 1)
     {
      g_lastBarTime = currentBarTime;
      return;
     }

   // 5. KIỂM TRA KHUNG GIỜ GIAO DỊCH (11:00 - 18:00 GMT)
   MqlDateTime gmtNow;
   TimeToStruct(GetAccurateGMT(), gmtNow);
   if(gmtNow.hour < InpStartHourGMT || gmtNow.hour >= InpEndHourGMT)
     {
      g_lastBarTime = currentBarTime;
      return;
     }

   // 6. KIỂM TRA TỔNG CHI PHÍ THỰC TẾ (EFFECTIVE FRICTION COST PER OZ)
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize <= 0.0) contractSize = 100.0;

   double effectiveCostPerOz = (ask - bid) + (InpCommissionPerLotRT / contractSize);
   if(effectiveCostPerOz > InpMaxEffectiveCostPerOz)
      return; // Chưa cập nhật g_lastBarTime để có thể thử lại ở tick kế tiếp nếu spread dịu xuống ngay đầu nến

   // 7. ĐỌC DỮ LIỆU CHỈ BÁO TẠI NẾN VỪA ĐÓNG (SHIFT 1 & SHIFT 2)
   double emaFast[2], emaSlow[2], rsi[2], atr[2];
   MqlRates rates[2];

   if(CopyBuffer(g_handleEMAFast, 0, 1, 2, emaFast) < 2 ||
      CopyBuffer(g_handleEMASlow, 0, 1, 2, emaSlow) < 2 ||
      CopyBuffer(g_handleRSI,     0, 1, 2, rsi)     < 2 ||
      CopyBuffer(g_handleATR,     0, 1, 2, atr)     < 2 ||
      CopyRates(_Symbol, PERIOD_M15, 1, 2, rates)   < 2)
      return;

   // Lưu ý thứ tự mảng CopyBuffer/CopyRates: index [1] là Shift 1 (nến vừa đóng), index [0] là Shift 2 (nến trước đó)
   double close1   = rates[1].close;
   double range1   = rates[1].high - rates[1].low;
   double atr1     = atr[1];
   double emaF1    = emaFast[1];
   double emaS1    = emaSlow[1];
   double rsiPrev  = rsi[0]; // Shift 2
   double rsiClose = rsi[1]; // Shift 1

   g_lastBarTime = currentBarTime; // Đánh dấu đã xử lý xong nến M15 này

   if(atr1 <= 0.0 || range1 > InpMaxCandleSpikeATR * atr1)
      return; // Bỏ qua nếu nến tín hiệu giãn biên độ bất thường (Anti-Spike)

   bool buySignal  = (close1 > emaS1) && (emaF1 > emaS1) && (rsiPrev <= InpRSIBuyCrossLevel  && rsiClose > InpRSIBuyCrossLevel);
   bool sellSignal = (close1 < emaS1) && (emaF1 < emaS1) && (rsiPrev >= InpRSISellCrossLevel && rsiClose < InpRSISellCrossLevel);

   if(!buySignal && !sellSignal)
      return;

   // 8. TÍNH SL/TP VÀ KIỂM TRA TRẦN RỦI RO TIỀN TỆ BẰNG ORDERCALCPROFIT
   double maxAllowedRiskMoney = g_dayStartEquityAnchor * (InpMaxRiskPercent / 100.0);

   if(buySignal)
     {
      double sl = NormalizeDouble(ask - (InpSLMultiplierATR * atr1), _Digits);
      double tp = NormalizeDouble(ask + (InpTPMultiplierATR * atr1), _Digits);
      double riskMoney = CalculatePreTradeRiskMoney(ORDER_TYPE_BUY, InpFixedLot, ask, sl);

      if(riskMoney <= maxAllowedRiskMoney)
         g_trade.Buy(InpFixedLot, _Symbol, ask, sl, tp, "XAU_M15_Trend_Buy");
      else
         Print("BUY skipped: Risk (", DoubleToString(riskMoney, 2), ") exceeds cap (", DoubleToString(maxAllowedRiskMoney, 2), ")");
     }
   else if(sellSignal)
     {
      double sl = NormalizeDouble(bid + (InpSLMultiplierATR * atr1), _Digits);
      double tp = NormalizeDouble(bid - (InpTPMultiplierATR * atr1), _Digits);
      double riskMoney = CalculatePreTradeRiskMoney(ORDER_TYPE_SELL, InpFixedLot, bid, sl);

      if(riskMoney <= maxAllowedRiskMoney)
         g_trade.Sell(InpFixedLot, _Symbol, bid, sl, tp, "XAU_M15_Trend_Sell");
      else
         Print("SELL skipped: Risk (", DoubleToString(riskMoney, 2), ") exceeds cap (", DoubleToString(maxAllowedRiskMoney, 2), ")");
     }
  }
//+------------------------------------------------------------------+
