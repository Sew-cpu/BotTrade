//+------------------------------------------------------------------+
//|                                  XAUUSD_M15_Production_v3_1.mq5  |
//|         Event-Driven Accounting & HWM Drawdown Engine (v3.10)    |
//|         Institutional Gold Algo Trading Architecture             |
//+------------------------------------------------------------------+
#property copyright "Quantitative System Architecture"
#property link      "https://github.com/algorithmic-trading"
#property version   "3.10"
#property strict

#include <Trade\Trade.mqh>

//--- Enums định nghĩa cấu hình rõ ràng
enum ENUM_DST_SCHEDULE
  {
   DST_US   = 0, // US DST (Chủ Nhật thứ 2 Tháng 3 -> Chủ Nhật đầu tiên Tháng 11)
   DST_EU   = 1, // EU/UK DST (Chủ Nhật cuối Tháng 3 -> Chủ Nhật cuối Tháng 10)
   DST_NONE = 2  // Không đổi giờ DST (Offset cố định quanh năm)
  };

enum ENUM_COMMISSION_MODE
  {
   COMM_CHARGED_PER_SIDE     = 0, // Sàn thu phí từng chiều (Deal IN mới thu 1/2 -> Nhân 2 khi dự tính đóng)
   COMM_CHARGED_UPFRONT_FULL = 1  // Sàn thu trọn gói 2 chiều ngay tại Deal IN (Giữ nguyên 1x)
  };

enum ENUM_LOCKDOWN_SCOPE
  {
   SCOPE_THIS_EA_ONLY   = 0, // Tính Equity ảo (HWM) và chỉ đóng lệnh của riêng EA này (Symbol + Magic)
   SCOPE_ENTIRE_ACCOUNT = 1  // Tính Equity và đóng toàn bộ vị thế/lệnh chờ trên tài khoản
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

//--- Input Parameters
input group "=== 1. Quản trị Nguồn vốn & Rủi ro (High-Water Mark) ==="
input double               InpReferenceCapital     = 0.0;                     // Vốn tham chiếu ban đầu (0 = Tự động lấy Balance lúc khởi chạy)
input bool                 InpUseDynamicLot        = false;                   // Tính Lot tự động theo % Risk (False = Dùng InpFixedLot 0.01)
input double               InpFixedLot             = 0.01;                    // Khối lượng cố định (Lot)
input double               InpRiskPercentPerTrade  = 1.0;                     // Rủi ro mục tiêu mỗi lệnh (% Equity đầu ngày)
input double               InpMaxRiskCapPercent    = 1.2;                     // Trần rủi ro tối đa cho phép (% Equity đầu ngày)
input double               InpMaxDailyLossPercent  = 3.0;                     // Ngắt mạch lỗ tối đa trong ngày (% Equity lúc 00:00 GMT)
input double               InpMaxHWMDrawdownPct    = 15.0;                    // Ngắt mạch sụt giảm từ Đỉnh vốn HWM (% High-Water Mark)
input ENUM_LOCKDOWN_SCOPE  InpLockdownScope        = SCOPE_THIS_EA_ONLY;      // Phạm vi kế toán rủi ro & đóng lệnh khẩn cấp
input int                  InpResetLockdownToken   = 0;                       // One-Shot Reset: Đổi sang số nguyên mới (>0) để mở khóa 1 lần

input group "=== 2. Chi phí Giao dịch, Hòa vốn & Trailing Stop ==="
input double               InpMaxEffectiveCostOz   = 0.35;                    // Trần chi phí (Spread + Comm quy đổi) trên 1 oz
input double               InpEstCommPerLotRT      = 7.0;                     // Commission 2 chiều ước tính / 1 Lot (Kiểm tra Pre-trade)
input ENUM_COMMISSION_MODE InpCommissionMode       = COMM_CHARGED_PER_SIDE;   // Cơ chế ghi nhận DEAL_COMMISSION của Broker
input bool                 InpUseBreakEven         = true;                    // Bật/Tắt chế độ dời Hòa vốn (Break-Even)
input double               InpBETriggerATR         = 1.2;                     // Kích hoạt dời BE khi giá chạy được (x ATR) [Baseline gốc]
input double               InpBEExtraBufferMoney   = 0.30;                    // Lãi ròng đệm khi chạm BE (Theo đồng tiền TK)
input bool                 InpUseTrailingStop      = true;                    // Bật/Tắt chế độ Trailing Stop
input double               InpTrailStartATR        = 1.5;                     // Kích hoạt Trailing khi giá chạy được (x ATR)
input double               InpTrailDistanceATR     = 1.0;                     // Khoảng cách neo SL phía sau giá hiện tại (x ATR)
input double               InpTrailStepATR         = 0.25;                    // Bước nhảy tối thiểu mỗi lần dời SL (x ATR)

input group "=== 3. Chỉ số Lọc Điểm Đẹp & Setup A+ (Confluence Engine) ==="
input bool                 InpRequireAPlusSetup    = true;                    // Bật bộ lọc chỉ bắn tỉa Setup A+ Confluence
input int                  InpMinConfluenceScore   = 70;                      // Điểm số tối thiểu để vào lệnh (>= 70: Chuẩn A/A+ Tối ưu số lệnh)
input double               InpMinPinBarWickRatio   = 0.50;                    // Tỷ lệ râu nến Pin Bar tối thiểu (50%)
input double               InpMaxPinBarBodyRatio   = 0.40;                    // Tỷ lệ thân nến Pin Bar tối đa (40%)
input int                  InpMaxSimultaneousPos   = 2;                       // Số vị thế mở tối đa đồng thời (1 - 2)
input bool                 InpAllowReentryOnBE     = true;                    // Chỉ cho phép mở lệnh 2 khi lệnh 1 đã dời Hòa Vốn (Free-Risk)
input int                  InpEMAFastPeriod        = 50;                      // Chu kỳ EMA Trung hạn
input int                  InpEMASlowPeriod        = 200;                     // Chu kỳ EMA Dài hạn
input int                  InpRSIPeriod            = 14;                      // Chu kỳ RSI
input double               InpRSIBuyCrossLevel     = 45.0;                    // Mức RSI cắt lên cho lệnh BUY
input double               InpRSISellCrossLevel    = 55.0;                    // Mức RSI cắt xuống cho lệnh SELL
input int                  InpATRPeriod            = 14;                      // Chu kỳ ATR
input double               InpSLMultiplierATR      = 1.5;                     // Khoảng cách Stop Loss ban đầu (x ATR) [Baseline gốc]
input double               InpTPMultiplierATR      = 2.5;                     // Khoảng cách Take Profit ban đầu (x ATR) [Baseline gốc]
input double               InpMaxCandleSpikeATR    = 2.0;                     // Chặn vào lệnh nếu nến tín hiệu dài quá (x ATR) [Baseline gốc]

input group "=== 4. Thời gian, Lịch Tin tức & Bảo vệ Qua đêm ==="
input int                  InpStartHourGMT         = 7;                       // Giờ bắt đầu mở lệnh (GMT) - 14:00 VN (Bao trọn Phiên London)
input int                  InpEndHourGMT           = 19;                      // Giờ ngừng mở lệnh mới (GMT) - 02:00 VN (Hết Phiên New York)
input int                  InpWinterGMTOffset      = 2;                       // GMT Offset mùa đông của Server (Dùng khi Backtest)
input ENUM_DST_SCHEDULE    InpDSTSchedule          = DST_US;                  // Lịch đổi giờ mùa hè của Server (Dùng khi Backtest)
input bool                 InpUseNewsFilter        = true;                    // Bật lọc tin tức USD High-Impact
input int                  InpNewsPauseBeforeMin   = 30;                      // Số phút dừng mở lệnh trước tin đỏ
input int                  InpNewsPauseAfterMin    = 30;                      // Số phút dừng mở lệnh sau tin đỏ
input bool                 InpCloseBeforeWeekend   = true;                    // Tự động đóng vị thế tối Thứ Sáu chống Gap
input int                  InpFridayCloseHourGMT   = 20;                      // Giờ đóng toàn bộ lệnh tối Thứ Sáu (GMT)
input bool                 InpAvoidTripleSwapDay   = true;                    // Chặn mở lệnh mới cuối phiên ngày tính Triple Swap
input int                  InpRolloverAvoidHours   = 2;                       // Số giờ cuối phiên chặn mở lệnh trong ngày Triple Swap

input group "=== 5. Định danh & Thực thi Lệnh ==="
input ulong                InpMagicNumber          = 20261015;                // Magic Number định danh EA
input ulong                InpNormalDeviationPts   = 30;                      // Slippage cho phép khi mở lệnh (Points)
input ulong                InpPanicDeviationPts    = 100;                     // Slippage tối đa khi đóng lệnh khẩn cấp (Points)

input group "=== 6. Giao Diện & Bảng Điều Khiển (Visual HUD) ==="
input bool                 InpShowDashboard        = true;                    // Hiển thị HUD Dashboard trên biểu đồ
input color                InpColorTheme           = clrDodgerBlue;           // Tông màu chủ đạo Dashboard

//--- Biến toàn cục nội bộ
CTrade   g_trade;
int      g_handleEMAFast = INVALID_HANDLE;
int      g_handleEMASlow = INVALID_HANDLE;
int      g_handleRSI     = INVALID_HANDLE;
int      g_handleATR     = INVALID_HANDLE;

datetime g_lastBarTime                = 0;
int      g_currentGMTDateKey          = 0;
datetime g_eaEpochStartTime           = 0;   // Thời điểm khởi tạo chu kỳ kế toán của EA
double   g_referenceCapital           = 0.0; // Vốn gốc neo ban đầu
double   g_highWaterMarkEquity        = 0.0; // Đỉnh vốn cao nhất (HWM) để tính Max Drawdown
double   g_dayStartEquitySnapshot     = 0.0; // Snapshot Equity tại đúng 00:00 GMT đầu ngày
bool     g_isEmergencyLockdown        = false;
bool     g_isDailyLossLocked          = false;
datetime g_lastAlertTime              = 0;
datetime g_lastModifyAttempt          = 0;
int      g_lastLoggedGMTOffset        = -999;
datetime g_lastGuiUpdateTime          = 0;

int      g_lastSetupScore             = 0;
string   g_lastSetupReason            = "Đang quét tín hiệu A+...";

//--- Biến Cache kế toán (Chỉ cập nhật khi có OnTradeTransaction hoặc đổi ngày)
bool     g_accountingCacheDirty       = true;
double   g_cachedEARealizedAllTime    = 0.0;
double   g_cachedEARealizedToday      = 0.0;
double   g_cachedAllRealizedToday     = 0.0;
double   g_cachedNetBalanceFlowsToday = 0.0;

//--- Cache Break-Even theo Ticket
ulong    g_cachedBETicket             = 0;
double   g_cachedBEPrice              = 0.0;

//--- Khóa GlobalVariables (Có chứa ACCOUNT_LOGIN)
string   g_gvLockdownKey;
string   g_gvResetTokenKey;
string   g_gvEpochTimeKey;
string   g_gvRefCapKey;
string   g_gvHWMKey;
string   g_gvDaySnapKey;
string   g_gvDayDateKey;

//+------------------------------------------------------------------+
//| Khởi tạo tên biến GlobalVariable có chứa ACCOUNT_LOGIN           |
//+------------------------------------------------------------------+
void InitGlobalKeys()
  {
   long login        = AccountInfoInteger(ACCOUNT_LOGIN);
   string prefix     = StringFormat("EA_%I64d_%s_%I64u_", login, _Symbol, InpMagicNumber);
   g_gvLockdownKey   = prefix + "LOCK";
   g_gvResetTokenKey = prefix + "RST_TOK";
   g_gvEpochTimeKey  = prefix + "EPOCH";
   g_gvRefCapKey     = prefix + "REFCAP";
   g_gvHWMKey        = prefix + "HWM";
   g_gvDaySnapKey    = prefix + "DAY_SNAP";
   g_gvDayDateKey    = prefix + "DAY_DATE";
  }

//+------------------------------------------------------------------+
//| Gửi thông báo an toàn                                            |
//+------------------------------------------------------------------+
void SafeSendNotification(string message)
  {
   Print("[ALERT] ", message);
   if(TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
      SendNotification(message);
  }

//+------------------------------------------------------------------+
//| Tính số chữ số thập phân của Volume từ SYMBOL_VOLUME_STEP        |
//+------------------------------------------------------------------+
int GetVolumeDigits(double step)
  {
   if(step <= 0.0) return 2;
   int digits = 0;
   double temp = step;
   while(digits < 8 && MathAbs(temp - MathRound(temp)) > 1e-7)
     {
      temp *= 10.0;
      digits++;
     }
   return digits;
  }

//+------------------------------------------------------------------+
//| Tính chính xác ngày Chủ Nhật đầu tiên và cuối cùng của tháng     |
//+------------------------------------------------------------------+
void GetMonthSundays(int year, int month, int day, int dayOfWeek, int &firstSunday, int &lastSunday)
  {
   int dowOfFirst = (dayOfWeek - ((day - 1) % 7) + 7) % 7;
   firstSunday    = (dowOfFirst == 0) ? 1 : (8 - dowOfFirst);

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
//| Lấy Offset hiện tại giữa Server và GMT + In Log khi chuyển mùa   |
//+------------------------------------------------------------------+
int GetActiveServerGMTOffset()
  {
   int activeOffset = InpWinterGMTOffset;

   if(!MQLInfoInteger(MQL_TESTER))
     {
      activeOffset = (int)MathRound((double)(TimeCurrent() - TimeGMT()) / 3600.0);
     }
   else if(InpDSTSchedule != DST_NONE)
     {
      datetime srvTime = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(srvTime, dt);

      int firstSun = 1, lastSun = 28;
      GetMonthSundays(dt.year, dt.mon, dt.day, dt.day_of_week, firstSun, lastSun);

      bool isSummer = false;
      if(InpDSTSchedule == DST_US)
        {
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
         if(dt.mon > 3 && dt.mon < 10)
            isSummer = true;
         else if(dt.mon == 3)
            isSummer = (dt.day > lastSun) || (dt.day == lastSun && dt.hour >= 2);
         else if(dt.mon == 10)
            isSummer = (dt.day < lastSun) || (dt.day == lastSun && dt.hour < 3);
        }
      activeOffset = InpWinterGMTOffset + (isSummer ? 1 : 0);
     }

   if(activeOffset != g_lastLoggedGMTOffset)
     {
      PrintFormat("[DST MONITOR] Server Time: %s | Active GMT Offset: GMT+%d | Calculated GMT: %s",
                  TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES),
                  activeOffset,
                  TimeToString(TimeCurrent() - activeOffset * 3600, TIME_DATE|TIME_MINUTES));
      g_lastLoggedGMTOffset = activeOffset;
     }

   return activeOffset;
  }

//+------------------------------------------------------------------+
//| Trả về thời gian GMT chính xác                                   |
//+------------------------------------------------------------------+
datetime GetAccurateGMT()
  {
   if(!MQLInfoInteger(MQL_TESTER))
      return TimeGMT();
   return TimeCurrent() - (GetActiveServerGMTOffset() * 3600);
  }

//+------------------------------------------------------------------+
//| Trả về thời điểm Server tương ứng với 00:00 GMT của ngày hiện tại|
//+------------------------------------------------------------------+
datetime GetToday00GMTInServerTime()
  {
   MqlDateTime gmtStruct;
   TimeToStruct(GetAccurateGMT(), gmtStruct);
   gmtStruct.hour = 0; gmtStruct.min = 0; gmtStruct.sec = 0;
   return StructToTime(gmtStruct) + (GetActiveServerGMTOffset() * 3600);
  }

//+------------------------------------------------------------------+
//| Cập nhật Cache Kế toán (Chỉ gọi khi có Deal mới hoặc đổi ngày)   |
//| Đảm bảo tính đủ DEAL_ENTRY_IN commission, DEAL_FEE và Balance    |
//+------------------------------------------------------------------+
void RefreshAccountingCacheIfNeeded()
  {
   if(!g_accountingCacheDirty)
      return;

   datetime today00Server = GetToday00GMTInServerTime();
   datetime queryStart    = MathMin(g_eaEpochStartTime, today00Server);

   if(!HistorySelect(queryStart, TimeCurrent() + 60))
      return;

   double eaRealizedSinceEpoch = 0.0;
   double eaRealizedToday      = 0.0;
   double allRealizedToday     = 0.0;
   double balanceFlowsToday    = 0.0;

   int totalDeals = HistoryDealsTotal();
   for(int i = 0; i < totalDeals; i++)
     {
      ulong dTicket = HistoryDealGetTicket(i);
      if(dTicket == 0) continue;

      datetime dealTime = (datetime)HistoryDealGetInteger(dTicket, DEAL_TIME);
      long dealType     = HistoryDealGetInteger(dTicket, DEAL_TYPE);

      // 1. Ghi nhận dòng tiền Nạp/Rút trong ngày để không làm méo Daily Loss của tài khoản
      if(dealType == DEAL_TYPE_BALANCE || dealType == DEAL_TYPE_CREDIT ||
         dealType == DEAL_TYPE_BONUS   || dealType == DEAL_TYPE_CHARGE ||
         dealType == DEAL_TYPE_CORRECTION)
        {
         if(dealTime >= today00Server)
            balanceFlowsToday += HistoryDealGetDouble(dTicket, DEAL_PROFIT);
         continue;
        }

      // 2. Chỉ tính các Deal giao dịch (BUY / SELL)
      if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL)
         continue;

      double dealNetPnL = HistoryDealGetDouble(dTicket, DEAL_PROFIT)
                        + HistoryDealGetDouble(dTicket, DEAL_SWAP)
                        + HistoryDealGetDouble(dTicket, DEAL_COMMISSION)
                        + HistoryDealGetDouble(dTicket, DEAL_FEE);

      if(dealTime >= today00Server)
         allRealizedToday += dealNetPnL;

      bool isThisEA = (HistoryDealGetString(dTicket, DEAL_SYMBOL) == _Symbol &&
                       (ulong)HistoryDealGetInteger(dTicket, DEAL_MAGIC) == InpMagicNumber);

      if(isThisEA)
        {
         if(dealTime >= g_eaEpochStartTime)
            eaRealizedSinceEpoch += dealNetPnL;
         if(dealTime >= today00Server)
            eaRealizedToday += dealNetPnL;
        }
     }

   g_cachedEARealizedAllTime    = eaRealizedSinceEpoch;
   g_cachedEARealizedToday      = eaRealizedToday;
   g_cachedAllRealizedToday     = allRealizedToday;
   g_cachedNetBalanceFlowsToday = balanceFlowsToday;
   g_accountingCacheDirty       = false;
  }

//+------------------------------------------------------------------+
//| Sự kiện giao dịch: Đánh dấu làm mới Cache khi có Deal phát sinh  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD || trans.type == TRADE_TRANSACTION_HISTORY_ADD)
     {
      g_accountingCacheDirty = true;
     }
  }

//+------------------------------------------------------------------+
//| Tính Floating PnL hiện tại của riêng EA                          |
//+------------------------------------------------------------------+
double GetEAFloatingPnL()
  {
   double floating = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
        {
         floating += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
     }
   return floating;
  }

//+------------------------------------------------------------------+
//| Trả về Equity hiện hành theo đúng Scope                          |
//+------------------------------------------------------------------+
double GetScopeCurrentEquity(ENUM_LOCKDOWN_SCOPE scope)
  {
   RefreshAccountingCacheIfNeeded();

   if(scope == SCOPE_ENTIRE_ACCOUNT)
      return AccountInfoDouble(ACCOUNT_EQUITY);

   // Với SCOPE_THIS_EA_ONLY: Virtual Equity = Vốn gốc + Tổng Realized của EA từ Epoch (đủ Comm/Fee) + Floating của EA
   return g_referenceCapital + g_cachedEARealizedAllTime + GetEAFloatingPnL();
  }

//+------------------------------------------------------------------+
//| Đồng bộ Snapshot Equity lúc 00:00 GMT & Cập nhật High-Water Mark |
//+------------------------------------------------------------------+
void SyncAccountingAndHWMState()
  {
   RefreshAccountingCacheIfNeeded();

   double currentScopeEquity = GetScopeCurrentEquity(InpLockdownScope);

   // 1. Cập nhật đỉnh vốn High-Water Mark (HWM)
   if(currentScopeEquity > g_highWaterMarkEquity)
     {
      g_highWaterMarkEquity = currentScopeEquity;
      GlobalVariableSet(g_gvHWMKey, g_highWaterMarkEquity);
     }

   // 2. Kiểm tra chuyển ngày GMT để chụp Snapshot Equity đầu ngày
   MqlDateTime gmtStruct;
   TimeToStruct(GetAccurateGMT(), gmtStruct);
   int todayKey = gmtStruct.year * 10000 + gmtStruct.mon * 100 + gmtStruct.day;

   if(GlobalVariableCheck(g_gvDayDateKey) && (int)GlobalVariableGet(g_gvDayDateKey) == todayKey)
     {
      g_currentGMTDateKey      = todayKey;
      g_dayStartEquitySnapshot = GlobalVariableGet(g_gvDaySnapKey);
      if(g_dayStartEquitySnapshot <= 0.0)
         g_dayStartEquitySnapshot = (g_referenceCapital > 0.0) ? g_referenceCapital : 1000.0;
     }
   else
     {
      // Bước sang ngày mới (00:00 GMT) hoặc khởi chạy lần đầu giữa ngày:
      g_currentGMTDateKey    = todayKey;
      g_isDailyLossLocked    = false;
      g_accountingCacheDirty = true;
      RefreshAccountingCacheIfNeeded();

      if(InpLockdownScope == SCOPE_ENTIRE_ACCOUNT)
        {
         // Tái tạo Balance lúc 00:00 GMT bằng cách trừ Realized PnL hôm nay và dòng tiền Nạp/Rút hôm nay, cộng Floating hiện tại
         double balanceAt00GMT    = AccountInfoDouble(ACCOUNT_BALANCE) - g_cachedAllRealizedToday - g_cachedNetBalanceFlowsToday;
         g_dayStartEquitySnapshot = balanceAt00GMT + AccountInfoDouble(ACCOUNT_PROFIT);
        }
      else
        {
         // Với SCOPE_THIS_EA_ONLY: Trừ đi phần Realized PnL phát sinh từ 00:00 GMT sáng nay (nếu khởi động muộn)
         g_dayStartEquitySnapshot = GetScopeCurrentEquity(SCOPE_THIS_EA_ONLY) - g_cachedEARealizedToday;
        }

      if(g_dayStartEquitySnapshot <= 0.0)
         g_dayStartEquitySnapshot = g_referenceCapital;

      GlobalVariableSet(g_gvDayDateKey, (double)todayKey);
      GlobalVariableSet(g_gvDaySnapKey, g_dayStartEquitySnapshot);
     }
  }

//+------------------------------------------------------------------+
//| Tính số tiền Lỗ trong ngày (So với Snapshot Equity lúc 00:00 GMT)|
//+------------------------------------------------------------------+
double GetCurrentDailyLossMoney(ENUM_LOCKDOWN_SCOPE scope)
  {
   double currentScopeEquity = GetScopeCurrentEquity(scope);
   // Nếu là toàn tài khoản, điều chỉnh mốc đầu ngày theo số tiền Nạp/Rút trong ngày
   double effectiveDayStart  = g_dayStartEquitySnapshot
                             + ((scope == SCOPE_ENTIRE_ACCOUNT) ? g_cachedNetBalanceFlowsToday : 0.0);

   return MathMax(0.0, effectiveDayStart - currentScopeEquity);
  }

//+------------------------------------------------------------------+
//| Tính độ sụt giảm từ Đỉnh vốn (High-Water Mark Drawdown)          |
//+------------------------------------------------------------------+
double GetCurrentHWMDrawdownMoney(ENUM_LOCKDOWN_SCOPE scope)
  {
   double currentScopeEquity = GetScopeCurrentEquity(scope);
   return MathMax(0.0, g_highWaterMarkEquity - currentScopeEquity);
  }

//+------------------------------------------------------------------+
//| Đếm vị thế và lệnh chờ theo Scope                                |
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
//| Đóng lệnh khẩn cấp (Đặt Filling Mode động theo từng Symbol)      |
//+------------------------------------------------------------------+
bool PurgeManagedExposures(ENUM_LOCKDOWN_SCOPE scope)
  {
   g_trade.SetDeviationInPoints(InpPanicDeviationPts);
   bool allCleared = true;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      string ordSym = OrderGetString(ORDER_SYMBOL);
      if(scope == SCOPE_THIS_EA_ONLY)
        {
         if(ordSym != _Symbol || (ulong)OrderGetInteger(ORDER_MAGIC) != InpMagicNumber)
            continue;
        }
      g_trade.SetTypeFillingBySymbol(ordSym);
      if(!g_trade.OrderDelete(ticket) || g_trade.ResultRetcode() != TRADE_RETCODE_DONE)
         allCleared = false;
     }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      string posSym = PositionGetString(POSITION_SYMBOL);
      if(scope == SCOPE_THIS_EA_ONLY)
        {
         if(posSym != _Symbol || (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
            continue;
        }
      g_trade.SetTypeFillingBySymbol(posSym);
      if(!g_trade.PositionClose(ticket, InpPanicDeviationPts))
         allCleared = false;
      else
        {
         uint ret = g_trade.ResultRetcode();
         if(ret != TRADE_RETCODE_DONE && ret != TRADE_RETCODE_DONE_PARTIAL)
            allCleared = false;
        }
     }

   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.SetDeviationInPoints(InpNormalDeviationPts);
   return (allCleared && CountManagedPositions(scope) == 0 && CountManagedOrders(scope) == 0);
  }

//+------------------------------------------------------------------+
//| Kiểm tra ngày tính Triple Swap thực tế từ SYMBOL_SWAP_ROLLOVER3DAYS|
//+------------------------------------------------------------------+
bool IsNearTripleSwapRollover(const MqlDateTime &gmtNow)
  {
   if(!InpAvoidTripleSwapDay)
      return false;

   int tripleSwapDay = (int)SymbolInfoInteger(_Symbol, SYMBOL_SWAP_ROLLOVER3DAYS);
   if(gmtNow.day_of_week == tripleSwapDay)
     {
      if(gmtNow.hour >= (InpEndHourGMT - InpRolloverAvoidHours))
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Kiểm tra Lịch Tin tức MQL5 (Đồng bộ NFP/CPI/FOMC cho cả Tester)  |
//+------------------------------------------------------------------+
bool IsHighImpactNewsWindow()
  {
   if(!InpUseNewsFilter)
      return false;

   if(MQLInfoInteger(MQL_TESTER))
     {
      MqlDateTime gmt;
      TimeToStruct(GetAccurateGMT(), gmt);
      int minOfDay = gmt.hour * 60 + gmt.min;

      // 1. NFP Window: Thứ Sáu đầu tiên của tháng (12:00 - 14:00 GMT)
      if(gmt.day_of_week == 5 && gmt.day <= 7)
        {
         if(minOfDay >= (12 * 60) && minOfDay <= (14 * 60))
            return true;
        }
      // 2. US CPI Window: Ngày 10 -> 15 hàng tháng vào Thứ Ba/Tư/Năm (12:00 - 14:00 GMT)
      if(gmt.day >= 10 && gmt.day <= 15 && gmt.day_of_week >= 2 && gmt.day_of_week <= 4)
        {
         if(minOfDay >= (12 * 60) && minOfDay <= (14 * 60))
            return true;
        }
      // 3. FOMC Rate Decision Window: Thứ Tư tuần thứ 3 của tháng (17:30 - 19:30 GMT)
      if(gmt.day_of_week == 3 && gmt.day >= 15 && gmt.day <= 22)
        {
         if(minOfDay >= (17 * 60 + 30) && minOfDay <= (19 * 60 + 30))
            return true;
        }
      return false;
     }

   // Khi chạy Live/Demo: Truy vấn trực tiếp MQL5 Economic Calendar
   datetime fromTime = TimeTradeServer() - (InpNewsPauseAfterMin * 60);
   datetime toTime   = TimeTradeServer() + (InpNewsPauseBeforeMin * 60);

   MqlCalendarValue values[];
   if(CalendarValueHistory(values, fromTime, toTime, NULL, "USD") <= 0)
      return false;

   for(int i = 0; i < ArraySize(values); i++)
     {
      MqlCalendarEvent event;
      if(CalendarEventById(values[i].event_id, event))
        {
         if(event.importance == CALENDAR_IMPORTANCE_HIGH)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Truy xuất Commission & Fee thực tế của Position đang mở          |
//+------------------------------------------------------------------+
bool GetPositionAccruedCosts(ulong positionTicket, double &outCommAndFee)
  {
   outCommAndFee = 0.0;
   if(!PositionSelectByTicket(positionTicket))
      return false;

   long posId = PositionGetInteger(POSITION_IDENTIFIER);
   if(!HistorySelectByPosition(posId))
      return false;

   int deals = HistoryDealsTotal();
   if(deals <= 0)
      return false;

   double total = 0.0;
   for(int i = 0; i < deals; i++)
     {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket > 0)
        {
         total += MathAbs(HistoryDealGetDouble(dealTicket, DEAL_COMMISSION))
                + MathAbs(HistoryDealGetDouble(dealTicket, DEAL_FEE));
        }
     }
   outCommAndFee = total;
   return true;
  }

//+------------------------------------------------------------------+
//| Kiểm tra các vị thế hiện tại đã dời SL về Hòa Vốn (Free-Risk)    |
//+------------------------------------------------------------------+
bool IsExistingPositionRiskFree()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL     = PositionGetDouble(POSITION_SL);

      if(pt == POSITION_TYPE_BUY)
        {
         if(curSL < openPrice) return false;
        }
      else if(pt == POSITION_TYPE_SELL)
        {
         if(curSL == 0.0 || curSL > openPrice) return false;
        }
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Tính giá Hòa vốn (Break-Even) có Cache theo Ticket               |
//+------------------------------------------------------------------+
double GetCachedOrCalculateBEPrice(ulong posTicket, double extraBufferMoney)
  {
   if(!PositionSelectByTicket(posTicket))
      return 0.0;

   double swap = PositionGetDouble(POSITION_SWAP);
   if(g_cachedBETicket == posTicket && g_cachedBEPrice > 0.0 && swap >= 0.0)
      return g_cachedBEPrice;

   double openPrice      = PositionGetDouble(POSITION_PRICE_OPEN);
   double volume         = PositionGetDouble(POSITION_VOLUME);
   ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double accruedCost = 0.0;
   double totalRoundTripComm = 0.0;
   if(GetPositionAccruedCosts(posTicket, accruedCost))
      totalRoundTripComm = (InpCommissionMode == COMM_CHARGED_PER_SIDE) ? (accruedCost * 2.0) : accruedCost;
   else
      totalRoundTripComm = InpEstCommPerLotRT * volume;

   double negativeSwap      = (swap < 0.0) ? MathAbs(swap) : 0.0;
   double targetGrossProfit = totalRoundTripComm + negativeSwap + extraBufferMoney;

   ENUM_ORDER_TYPE calcType = (pt == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double testClosePrice    = (pt == POSITION_TYPE_BUY) ? (openPrice + 1.0) : (openPrice - 1.0);
   double profitPerOneUnit  = 0.0;

   if(!OrderCalcProfit(calcType, _Symbol, volume, openPrice, testClosePrice, profitPerOneUnit) || profitPerOneUnit <= 0.0)
      return 0.0;

   double requiredPriceDelta = targetGrossProfit / profitPerOneUnit;
   double bePrice = (pt == POSITION_TYPE_BUY) ? (openPrice + requiredPriceDelta) : (openPrice - requiredPriceDelta);
   bePrice = NormalizeDouble(bePrice, _Digits);

   g_cachedBETicket = posTicket;
   g_cachedBEPrice  = bePrice;
   return bePrice;
  }

//+------------------------------------------------------------------+
//| Kiểm tra đúng chuẩn FREEZE_LEVEL (cũ) và STOPS_LEVEL (mới)       |
//+------------------------------------------------------------------+
bool IsStopModificationValid(ENUM_POSITION_TYPE posType, double newSL, double currentSL, double currentTP)
  {
   if(TimeCurrent() - g_lastModifyAttempt < 3)
      return false;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double stopsDist  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double freezeDist = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;

   if(posType == POSITION_TYPE_BUY)
     {
      if(freezeDist > 0.0)
        {
         if(currentSL > 0.0 && MathAbs(bid - currentSL) <= freezeDist) return false;
         if(currentTP > 0.0 && MathAbs(currentTP - bid) <= freezeDist) return false;
        }
      if(bid - newSL <= stopsDist) return false;
      if(currentSL > 0.0 && newSL <= currentSL + _Point) return false;
     }
   else
     {
      if(freezeDist > 0.0)
        {
         if(currentSL > 0.0 && MathAbs(currentSL - ask) <= freezeDist) return false;
         if(currentTP > 0.0 && MathAbs(ask - currentTP) <= freezeDist) return false;
        }
      if(newSL - ask <= stopsDist) return false;
      if(currentSL > 0.0 && newSL >= currentSL - _Point) return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Quản lý Break-Even & Trailing Stop                               |
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

      double openPrice      = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL          = PositionGetDouble(POSITION_SL);
      double curTP          = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(pt == POSITION_TYPE_BUY)
        {
         double moveDist = bid - openPrice;

         if(InpUseBreakEven && (curSL <= openPrice) && (moveDist >= InpBETriggerATR * currentATR))
           {
            double exactBE = GetCachedOrCalculateBEPrice(ticket, InpBEExtraBufferMoney);
            if(exactBE > 0.0 && IsStopModificationValid(pt, exactBE, curSL, curTP))
              {
               g_lastModifyAttempt = TimeCurrent();
               if(g_trade.PositionModify(ticket, exactBE, curTP))
                  curSL = exactBE;
              }
           }

         if(InpUseTrailingStop && (moveDist >= InpTrailStartATR * currentATR))
           {
            double candidateSL = NormalizeDouble(bid - (InpTrailDistanceATR * currentATR), _Digits);
            if(candidateSL > openPrice && (candidateSL - curSL >= InpTrailStepATR * currentATR))
              {
               if(IsStopModificationValid(pt, candidateSL, curSL, curTP))
                 {
                  g_lastModifyAttempt = TimeCurrent();
                  if(g_trade.PositionModify(ticket, candidateSL, curTP))
                     curSL = candidateSL;
                 }
              }
           }
        }
      else if(pt == POSITION_TYPE_SELL)
        {
         double moveDist = openPrice - ask;

         if(InpUseBreakEven && (curSL == 0.0 || curSL >= openPrice) && (moveDist >= InpBETriggerATR * currentATR))
           {
            double exactBE = GetCachedOrCalculateBEPrice(ticket, InpBEExtraBufferMoney);
            if(exactBE > 0.0 && IsStopModificationValid(pt, exactBE, curSL, curTP))
              {
               g_lastModifyAttempt = TimeCurrent();
               if(g_trade.PositionModify(ticket, exactBE, curTP))
                  curSL = exactBE;
              }
           }

         if(InpUseTrailingStop && (moveDist >= InpTrailStartATR * currentATR))
           {
            double candidateSL = NormalizeDouble(ask + (InpTrailDistanceATR * currentATR), _Digits);
            if(candidateSL < openPrice && (curSL == 0.0 || (curSL - candidateSL >= InpTrailStepATR * currentATR)))
              {
               if(IsStopModificationValid(pt, candidateSL, curSL, curTP))
                 {
                  g_lastModifyAttempt = TimeCurrent();
                  if(g_trade.PositionModify(ticket, candidateSL, curTP))
                     curSL = candidateSL;
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Tính Lot chuẩn hóa theo SYMBOL_VOLUME_STEP, Risk Cap & Margin    |
//+------------------------------------------------------------------+
double CalculateAndValidateLot(ENUM_ORDER_TYPE orderType, double entryPrice, double slPrice)
  {
   double lossPerOneLot = 0.0;
   if(!OrderCalcProfit(orderType, _Symbol, 1.0, entryPrice, slPrice, lossPerOneLot))
     {
      Print("OrderCalcProfit failed! Error: ", GetLastError());
      return 0.0;
     }

   double totalRiskPerOneLot = MathAbs(lossPerOneLot) + InpEstCommPerLotRT;
   if(totalRiskPerOneLot <= 0.0)
      return 0.0;

   double targetRiskMoney = g_dayStartEquitySnapshot * (InpRiskPercentPerTrade / 100.0);
   double maxCapRiskMoney = g_dayStartEquitySnapshot * (InpMaxRiskCapPercent / 100.0);

   double rawLot = InpFixedLot;
   if(InpUseDynamicLot)
      rawLot = targetRiskMoney / totalRiskPerOneLot;

   double minLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int    volDigits = GetVolumeDigits(lotStep);

   double normLot = MathFloor((rawLot + 1e-9) / lotStep) * lotStep;
   if(normLot < minLot)
      normLot = minLot;
   if(normLot > maxLot)
      normLot = maxLot;

   normLot = NormalizeDouble(normLot, volDigits);

   double actualRiskMoney = totalRiskPerOneLot * normLot;
   if(actualRiskMoney > maxCapRiskMoney)
     {
      PrintFormat("Trade Skipped: Lot (%.*f) risk (%.2f) exceeds Max Cap (%.2f).",
                  volDigits, normLot, actualRiskMoney, maxCapRiskMoney);
      return 0.0;
     }

   double requiredMargin = 0.0;
   if(!OrderCalcMargin(orderType, _Symbol, normLot, entryPrice, requiredMargin))
      return 0.0;

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(requiredMargin >= freeMargin * 0.90)
     {
      PrintFormat("Trade Skipped: Insufficient Free Margin (Req: %.2f, Free: %.2f).", requiredMargin, freeMargin);
      return 0.0;
     }

   return normLot;
  }

//+------------------------------------------------------------------+
//| NHẬN DIỆN MÔ HÌNH NẾN PRICE ACTION (PIN BAR, FAKEY, ENGULFING)    |
//+------------------------------------------------------------------+
ENUM_PRICE_ACTION_SIGNAL DetectPriceActionPattern(const MqlRates &c1, const MqlRates &c2, const MqlRates &c3)
  {
   double range1 = c1.high - c1.low;
   if(range1 <= 0.0) return SIGNAL_NONE;

   double body1      = MathAbs(c1.close - c1.open);
   double lowerWick1 = MathMin(c1.open, c1.close) - c1.low;
   double upperWick1 = c1.high - MathMax(c1.open, c1.close);

   // 1. Pin Bar Bullish (Rút chân mạnh)
   if((lowerWick1 / range1 >= InpMinPinBarWickRatio) &&
      (body1 / range1 <= InpMaxPinBarBodyRatio) &&
      (upperWick1 / range1 <= 0.20))
     {
      return SIGNAL_PINBAR_BULLISH;
     }

   // 2. Pin Bar Bearish (Từ chối giá cao)
   if((upperWick1 / range1 >= InpMinPinBarWickRatio) &&
      (body1 / range1 <= InpMaxPinBarBodyRatio) &&
      (lowerWick1 / range1 <= 0.20))
     {
      return SIGNAL_PINBAR_BEARISH;
     }

   // 3. Fakey (Inside Bar False Breakout theo Nial Fuller)
   bool isInsideBar = (c2.high <= c3.high && c2.low >= c3.low);
   if(isInsideBar)
     {
      if(c1.low < c2.low && c1.close > c2.low && c1.close > c1.open)
         return SIGNAL_FAKEY_BULLISH;
      if(c1.high > c2.high && c1.close < c2.high && c1.close < c1.open)
         return SIGNAL_FAKEY_BEARISH;
     }

   // 4. Bullish / Bearish Engulfing (Bao trùm)
   double body2 = MathAbs(c2.close - c2.open);
   if(c1.close > c1.open && c2.close < c2.open)
     {
      if(c1.close > c2.open && c1.open <= c2.close && body1 >= body2 * 1.1)
         return SIGNAL_ENGULFING_BULL;
     }
   else if(c1.close < c1.open && c2.close > c2.open)
     {
      if(c1.close < c2.open && c1.open >= c2.close && body1 >= body2 * 1.1)
         return SIGNAL_ENGULFING_BEAR;
     }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| CHẤM ĐIỂM HỘI TỤ CONFLUENCE SETUP A+ (0 -> 100 ĐIỂM)             |
//+------------------------------------------------------------------+
int EvaluateConfluenceScore(int direction, ENUM_PRICE_ACTION_SIGNAL paSignal,
                            double closePrice, double emaFastVal, double emaSlowVal,
                            double rsiVal, double currentATR, string &scoreReason)
  {
   int score = 0;
   scoreReason = "";

   // 1. Thuận Xu Hướng Vĩ Mô EMA 50 / 200 [+30 Điểm]
   if(direction == 1) // BUY
     {
      if(closePrice > emaSlowVal && emaFastVal > emaSlowVal)
        {
         score += 30;
         scoreReason += "Thuận Trend M15 Tăng (+30) | ";
        }
      else if(closePrice > emaFastVal)
        {
         score += 15;
         scoreReason += "Trên EMA 50 (+15) | ";
        }
     }
   else if(direction == -1) // SELL
     {
      if(closePrice < emaSlowVal && emaFastVal < emaSlowVal)
        {
         score += 30;
         scoreReason += "Thuận Trend M15 Giảm (+30) | ";
        }
      else if(closePrice < emaFastVal)
        {
         score += 15;
         scoreReason += "Dưới EMA 50 (+15) | ";
        }
     }

   // 2. Vùng Giá Trị Động (Value Area Pullback gần EMA 50) [+25 Điểm]
   double distToEmaFast = MathAbs(closePrice - emaFastVal);
   if(currentATR > 0.0)
     {
      if(distToEmaFast <= currentATR * 1.2)
        {
         score += 25;
         scoreReason += "Pullback Chuẩn Value Area (+25) | ";
        }
      else if(distToEmaFast <= currentATR * 2.0)
        {
         score += 15;
         scoreReason += "Gần Value Area (+15) | ";
        }
      else
        {
         scoreReason += "Giá Giãn Xa EMA (+0) | ";
        }
     }

   // 3. Mô Hình Nến Price Action Xác Nhận [+25 Điểm]
   if(direction == 1)
     {
      if(paSignal == SIGNAL_PINBAR_BULLISH)
        {
         score += 25;
         scoreReason += "Pin Bar Rút Chân (+25) | ";
        }
      else if(paSignal == SIGNAL_FAKEY_BULLISH)
        {
         score += 25;
         scoreReason += "Fakey Bẫy Giá (+25) | ";
        }
      else if(paSignal == SIGNAL_ENGULFING_BULL)
        {
         score += 20;
         scoreReason += "Engulfing Bao Trùm Tăng (+20) | ";
        }
      else
        {
         score += 10;
         scoreReason += "Nến Tăng Chuẩn (+10) | ";
        }
     }
   else if(direction == -1)
     {
      if(paSignal == SIGNAL_PINBAR_BEARISH)
        {
         score += 25;
         scoreReason += "Pin Bar Bắn Râu Trên (+25) | ";
        }
      else if(paSignal == SIGNAL_FAKEY_BEARISH)
        {
         score += 25;
         scoreReason += "Fakey Bẫy Giá Giảm (+25) | ";
        }
      else if(paSignal == SIGNAL_ENGULFING_BEAR)
        {
         score += 20;
         scoreReason += "Engulfing Bao Trùm Giảm (+20) | ";
        }
      else
        {
         score += 10;
         scoreReason += "Nến Giảm Chuẩn (+10) | ";
        }
     }

   // 4. Động Lượng RSI trong Vùng Vàng Sweet Spot [+20 Điểm]
   if(direction == 1)
     {
      if(rsiVal >= 45.0 && rsiVal <= 65.0)
        {
         score += 20;
         scoreReason += StringFormat("RSI Vùng Vàng %.1f (+20)", rsiVal);
        }
      else if(rsiVal > 40.0 && rsiVal < 70.0)
        {
         score += 10;
         scoreReason += StringFormat("RSI %.1f (+10)", rsiVal);
        }
      else
        {
         scoreReason += StringFormat("RSI Quá Mua/Bán %.1f (+0)", rsiVal);
        }
     }
   else if(direction == -1)
     {
      if(rsiVal >= 35.0 && rsiVal <= 55.0)
        {
         score += 20;
         scoreReason += StringFormat("RSI Vùng Vàng %.1f (+20)", rsiVal);
        }
      else if(rsiVal > 30.0 && rsiVal < 60.0)
        {
         score += 10;
         scoreReason += StringFormat("RSI %.1f (+10)", rsiVal);
        }
      else
        {
         scoreReason += StringFormat("RSI Quá Mua/Bán %.1f (+0)", rsiVal);
        }
     }

   return score;
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

   double currentEquity  = GetScopeCurrentEquity(InpLockdownScope);
   double hwmDDMoney     = GetCurrentHWMDrawdownMoney(InpLockdownScope);
   double hwmDDPct       = (g_highWaterMarkEquity > 0.0) ? (hwmDDMoney / g_highWaterMarkEquity * 100.0) : 0.0;
   double dailyLossMoney = GetCurrentDailyLossMoney(InpLockdownScope);
   double dailyLossPct   = (g_dayStartEquitySnapshot > 0.0) ? (dailyLossMoney / g_dayStartEquitySnapshot * 100.0) : 0.0;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize <= 0.0) contractSize = 100.0;
   double effectiveCost = (ask - bid) + (InpEstCommPerLotRT / contractSize);
   long   curSpread     = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   MqlDateTime gmtNow;
   TimeToStruct(GetAccurateGMT(), gmtNow);
   int srvOffset = GetActiveServerGMTOffset();
   int vnHour    = (gmtNow.hour + 7) % 24;

   string statusStr = "🟢 HOẠT ĐỘNG (SẴN SÀNG TRADE)";
   color  statusClr = clrLime;
   if(g_isEmergencyLockdown)
     {
      statusStr = "🔴 KHẨN CẤP: LOCKDOWN HWM";
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
   else if(effectiveCost > InpMaxEffectiveCostOz)
     {
      statusStr = "⚠️ CHI PHÍ SPREAD CAO (HOLD)";
      statusClr = clrOrangeRed;
     }

   // 1. Kích thước & Khung viền Bảng HUD ở góc trái trên
   int panelX = 15;
   int panelY = 25;
   int panelW = 425;
   int panelH = 365;

   SetHudPanel("XAU_HUD_BG", panelX, panelY, panelW, panelH, C'11,18,28', C'32,65,105');
   SetHudPanel("XAU_HUD_HEAD", panelX, panelY, panelW, 28, C'18,34,58', InpColorTheme);
   SetHudLabel("XAU_HUD_TITLE", "👑 XAUUSD M15 PRODUCTION PRO (v3.10)", panelX + 12, panelY + 6, clrGold, 10, true);

   int startY = panelY + 36;
   int lineH  = 23;

   // Dòng 1: Vốn & Đỉnh HWM
   SetHudLabel("XAU_HUD_L1", StringFormat("💰 Vốn: $%.2f | Đỉnh Vốn HWM: $%.2f", currentEquity, g_highWaterMarkEquity),
               panelX + 12, startY, clrAqua, 9, true);

   // Dòng 2: HWM Drawdown
   color hwmClr = (hwmDDPct > 10.0) ? clrTomato : ((hwmDDPct > 5.0) ? clrOrange : clrSpringGreen);
   SetHudLabel("XAU_HUD_L2", StringFormat("📉 Sụt Giảm HWM: -$%.2f (-%.2f%% / Trần: %.1f%%)", hwmDDMoney, hwmDDPct, InpMaxHWMDrawdownPct),
               panelX + 12, startY + lineH, hwmClr, 9);

   // Dòng 3: Daily Loss
   color lossClr = (dailyLossPct > 2.0) ? clrTomato : clrLimeGreen;
   SetHudLabel("XAU_HUD_L3", StringFormat("📅 Lỗ Hôm Nay: -$%.2f (-%.2f%% / Trần: %.1f%%)", dailyLossMoney, dailyLossPct, InpMaxDailyLossPercent),
               panelX + 12, startY + lineH * 2, lossClr, 9);

   // Dòng 4: Xu hướng EMA 50 / EMA 200
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

   // Dòng 6: Spread & Chi Phí
   color costClr = (effectiveCost > InpMaxEffectiveCostOz) ? clrOrangeRed : clrLightCyan;
   SetHudLabel("XAU_HUD_L6", StringFormat("⚡ Spread: %d pts | Chi Phí 1 oz: $%.2f (Trần: $%.2f)", curSpread, effectiveCost, InpMaxEffectiveCostOz),
               panelX + 12, startY + lineH * 5, costClr, 9);

   // Dòng 7: Setup A+ Confluence Score
   string gradeStr = (g_lastSetupScore >= InpMinConfluenceScore) ? "CHUẨN A+ ⭐" : ((g_lastSetupScore >= 60) ? "ĐANG TÍCH LŨY ⏳" : "CHỜ TÍN HIỆU ⚪");
   color  gradeClr = (g_lastSetupScore >= InpMinConfluenceScore) ? clrGold : ((g_lastSetupScore >= 60) ? clrOrange : clrSilver);
   SetHudLabel("XAU_HUD_L7", StringFormat("🏆 Setup A+: %d / 100 [%s] (Chuẩn: >= %d)", g_lastSetupScore, gradeStr, InpMinConfluenceScore),
               panelX + 12, startY + lineH * 6, gradeClr, 9, true);

   // Dòng 8: Đánh giá chi tiết Setup
   string reasonDisplay = (g_lastSetupReason != "") ? g_lastSetupReason : "Đang phân tích cấu trúc nến & động lượng...";
   if(StringLen(reasonDisplay) > 55)
      reasonDisplay = StringSubstr(reasonDisplay, 0, 52) + "...";
   SetHudLabel("XAU_HUD_L8", StringFormat("🔎 Chi Tiết: %s", reasonDisplay),
               panelX + 12, startY + lineH * 7, clrDeepSkyBlue, 8);

   // Dòng 9: Vị thế đang mở
   string posDesc = "CHƯA CÓ LỆNH (Đang Quét Điểm Vào)";
   color  posClr  = clrSilver;
   int totalPos = PositionsTotal();
   int managedCount = 0;
   double totalManagedProfit = 0.0;
   string lastPosSummary = "";

   for(int i = 0; i < totalPos; i++)
     {
      string posSym = PositionGetSymbol(i);
      if(posSym == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
        {
         managedCount++;
         ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double pVol  = PositionGetDouble(POSITION_VOLUME);
         double pProf = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         double pOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         totalManagedProfit += pProf;
         lastPosSummary = StringFormat("%s %.2f Lot @ %.2f", (pType == POSITION_TYPE_BUY ? "BUY 🟢" : "SELL 🔴"), pVol, pOpen);
        }
     }

   if(managedCount == 1)
     {
      posDesc = StringFormat("%s | Lãi/Lỗ: %+.2f$", lastPosSummary, totalManagedProfit);
      posClr  = (totalManagedProfit >= 0.0) ? clrLime : clrTomato;
     }
   else if(managedCount > 1)
     {
      posDesc = StringFormat("%d Lệnh Chạy (Free-Risk) | Tổng PnL: %+.2f$", managedCount, totalManagedProfit);
      posClr  = (totalManagedProfit >= 0.0) ? clrLime : clrTomato;
     }

   SetHudLabel("XAU_HUD_L9", StringFormat("🎯 Vị Thế: %s", posDesc),
               panelX + 12, startY + lineH * 8, posClr, 9, true);

   // Dòng 10: Khung giờ giao dịch
   bool isInSession = (gmtNow.hour >= InpStartHourGMT && gmtNow.hour < InpEndHourGMT);
   string sessionTag = isInSession ? "🟢 ĐANG TRONG PHIÊN" : "🟡 NGOÀI GIỜ CHỜ";
   SetHudLabel("XAU_HUD_L10", StringFormat("⏱️ Phiên Trade: %02d:00-%02d:00 GMT [%02dh-%02dh VN] (%s)",
                                          InpStartHourGMT, InpEndHourGMT, (InpStartHourGMT+7)%24, (InpEndHourGMT+7)%24, sessionTag),
               panelX + 12, startY + lineH * 9, isInSession ? clrLime : clrDarkGray, 8);

   // Dòng 11: Đồng hồ GMT / Giờ VN
   SetHudLabel("XAU_HUD_L11", StringFormat("🕒 Đồng Hồ: %02d:%02d GMT (Server GMT+%d) | Giờ VN: %02d:%02d",
                                          gmtNow.hour, gmtNow.min, srvOffset, vnHour, gmtNow.min),
               panelX + 12, startY + lineH * 10, clrSkyBlue, 8);

   // Dòng 12: Lọc Tin Tức
   bool newsRestricted = InpUseNewsFilter && IsHighImpactNewsWindow();
   string newsTxt = newsRestricted ? "CẢNH BÁO TIN ĐỎ USD (TẠM DỪNG MỞ LỆNH)" : "AN TOÀN (Không vướng tin đỏ USD)";
   color  newsClr = newsRestricted ? clrOrangeRed : clrSpringGreen;
   SetHudLabel("XAU_HUD_L12", StringFormat("📰 Lịch Tin: %s", newsTxt),
               panelX + 12, startY + lineH * 11, newsClr, 8);

   // Dòng 13: Trạng thái Hệ thống
   SetHudLabel("XAU_HUD_L13", StringFormat("🚦 Hệ Thống: %s", statusStr),
               panelX + 12, startY + lineH * 12, statusClr, 9, true);

   // Dòng 14: Scope & Reset Token
   SetHudLabel("XAU_HUD_L14", StringFormat("🛡️ Quản Trị: %s | Reset Token: #%d",
                                          (InpLockdownScope == SCOPE_THIS_EA_ONLY ? "Chỉ EA Này (Virtual)" : "Toàn Tài Khoản"),
                                          InpResetLockdownToken),
               panelX + 12, startY + lineH * 13, clrLightSlateGray, 8);
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

   // 1. Cơ chế One-Shot Reset bằng Token (Không bao giờ tự xóa lặp lại nếu quên tắt input)
   int lastAppliedToken = GlobalVariableCheck(g_gvResetTokenKey) ? (int)GlobalVariableGet(g_gvResetTokenKey) : 0;
   if(InpResetLockdownToken > 0 && InpResetLockdownToken != lastAppliedToken)
     {
      GlobalVariableDel(g_gvLockdownKey);
      GlobalVariableDel(g_gvRefCapKey);
      GlobalVariableDel(g_gvHWMKey);
      GlobalVariableDel(g_gvEpochTimeKey);
      GlobalVariableDel(g_gvDayDateKey);
      GlobalVariableSet(g_gvResetTokenKey, (double)InpResetLockdownToken);
      PrintFormat("ONE-SHOT RESET EXECUTED with Token #%d. Lockdown & HWM cleared once.", InpResetLockdownToken);
     }

   // 2. Thiết lập mốc thời gian Epoch của EA để không cộng dồn lịch sử cũ
   if(GlobalVariableCheck(g_gvEpochTimeKey) && GlobalVariableGet(g_gvEpochTimeKey) > 0)
      g_eaEpochStartTime = (datetime)GlobalVariableGet(g_gvEpochTimeKey);
   else
     {
      g_eaEpochStartTime = TimeCurrent();
      GlobalVariableSet(g_gvEpochTimeKey, (double)g_eaEpochStartTime);
     }

   // 3. Thiết lập Vốn tham chiếu ban đầu & kiểm tra chênh lệch
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(InpReferenceCapital > 0.0)
     {
      double diffRatio = (currentBalance > 0.0) ? MathAbs(InpReferenceCapital - currentBalance) / currentBalance : 0.0;
      if(diffRatio > 0.30 && currentBalance > 0.0)
        {
         PrintFormat("INIT ERROR: InpReferenceCapital (%.2f) deviates >30%% from Balance (%.2f)!",
                     InpReferenceCapital, currentBalance);
         return INIT_PARAMETERS_INCORRECT;
        }
      g_referenceCapital = InpReferenceCapital;
     }
   else
     {
      if(GlobalVariableCheck(g_gvRefCapKey) && GlobalVariableGet(g_gvRefCapKey) > 0.0)
         g_referenceCapital = GlobalVariableGet(g_gvRefCapKey);
      else
        {
         g_referenceCapital = (currentBalance > 0.0) ? currentBalance : 1000.0;
         GlobalVariableSet(g_gvRefCapKey, g_referenceCapital);
        }
     }

   // 4. Khôi phục High-Water Mark (HWM) và trạng thái Lockdown
   if(GlobalVariableCheck(g_gvHWMKey) && GlobalVariableGet(g_gvHWMKey) >= g_referenceCapital && GlobalVariableGet(g_gvHWMKey) > 0.0)
      g_highWaterMarkEquity = GlobalVariableGet(g_gvHWMKey);
   else
     {
      g_highWaterMarkEquity = (g_referenceCapital > 0.0) ? g_referenceCapital : 1000.0;
      GlobalVariableSet(g_gvHWMKey, g_highWaterMarkEquity);
     }

   // Luôn xóa cờ Lockdown và reset Daily Loss cũ khi khởi động lại để EA hoạt động bình thường trên biểu đồ
   GlobalVariableDel(g_gvLockdownKey);
   GlobalVariableDel(g_gvDayDateKey);
   GlobalVariableDel(g_gvDaySnapKey);
   g_isEmergencyLockdown = false;
   g_isDailyLossLocked   = false;

   g_accountingCacheDirty = true;
   SyncAccountingAndHWMState();

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

   PrintFormat("EA v3.10 Initialized. RefCap: %.2f | HWM: %.2f | DayStartSnap: %.2f | Epoch: %s",
               g_referenceCapital, g_highWaterMarkEquity, g_dayStartEquitySnapshot,
               TimeToString(g_eaEpochStartTime, TIME_DATE|TIME_MINUTES));
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
   // Cập nhật giao diện HUD định kỳ
   UpdateChartHUD();

   // 1. ĐỒNG BỘ HWM & KIỂM TRA MAX HIGH-WATER MARK DRAWDOWN
   SyncAccountingAndHWMState();

   double maxAllowedHWMDD = g_highWaterMarkEquity * (InpMaxHWMDrawdownPct / 100.0);
   double currentHWMDD    = GetCurrentHWMDrawdownMoney(InpLockdownScope);

   if(g_highWaterMarkEquity > 0.0 && currentHWMDD >= maxAllowedHWMDD && !g_isEmergencyLockdown)
     {
      g_isEmergencyLockdown = true;
      GlobalVariableSet(g_gvLockdownKey, 1.0);
      PrintFormat("CRITICAL: HWM Drawdown (%.2f from peak %.2f) breached limit (%.2f). Entering Lockdown!",
                  currentHWMDD, g_highWaterMarkEquity, maxAllowedHWMDD);
     }

   if(g_isEmergencyLockdown)
     {
      static bool s_lockdownNotified = false;
      if(!s_lockdownNotified)
        {
         PurgeManagedExposures(InpLockdownScope);
         SafeSendNotification("EA LOCKDOWN ACTIVE: All managed exposures closed on " + _Symbol);
         s_lockdownNotified = true;
        }
      return;
     }

   // 2. KIỂM TRA MAX DAILY LOSS (DỰA TRÊN SNAPSHOT EQUITY LÚC 00:00 GMT)
   double maxDailyLossMoney = g_dayStartEquitySnapshot * (InpMaxDailyLossPercent / 100.0);
   double currentDailyLoss  = GetCurrentDailyLossMoney(InpLockdownScope);

   if(g_dayStartEquitySnapshot > 0.0 && maxDailyLossMoney > 0.0 && currentDailyLoss >= maxDailyLossMoney && !g_isDailyLossLocked)
     {
      g_isDailyLossLocked = true;
      SafeSendNotification(StringFormat("Daily Loss Limit (%.2f) reached on %s. Pausing until 00:00 GMT.",
                                        currentDailyLoss, _Symbol));
     }

   if(g_isDailyLossLocked)
     {
      PurgeManagedExposures(InpLockdownScope);
      return;
     }

   // 3. ĐÓNG LỆNH TRƯỚC KHI NGHỈ CUỐI TUẦN
   MqlDateTime gmtNow;
   TimeToStruct(GetAccurateGMT(), gmtNow);
   if(InpCloseBeforeWeekend && gmtNow.day_of_week == 5 && gmtNow.hour >= InpFridayCloseHourGMT)
     {
      if(CountManagedPositions(SCOPE_THIS_EA_ONLY) > 0 || CountManagedOrders(SCOPE_THIS_EA_ONLY) > 0)
         PurgeManagedExposures(SCOPE_THIS_EA_ONLY);
      return;
     }

   // 4. QUẢN LÝ VỊ THẾ ĐANG MỞ
   int openPosCount = CountManagedPositions(SCOPE_THIS_EA_ONLY);
   if(openPosCount > 0)
     {
      double atrBuf[1];
      if(CopyBuffer(g_handleATR, 0, 1, 1, atrBuf) == 1)
         ManageOpenPositions(atrBuf[0]);
     }

   // 5. CHỈ KIỂM TRA TÍN HIỆU MỞ LỆNH KHI CÓ NẾN M15 MỚI
   datetime currentBarTime = iTime(_Symbol, PERIOD_M15, 0);
   if(currentBarTime == g_lastBarTime)
      return;

   if(openPosCount >= InpMaxSimultaneousPos)
     {
      g_lastBarTime = currentBarTime;
      return;
     }

   if(openPosCount > 0 && InpAllowReentryOnBE)
     {
      if(!IsExistingPositionRiskFree())
        {
         g_lastBarTime = currentBarTime;
         return; // Chỉ mở thêm lệnh mới khi các lệnh đang chạy đã dời SL về Hòa Vốn (Free-Risk)
        }
     }

   // 6. KIỂM TRA KHUNG GIỜ GIAO DỊCH & TRIPLE SWAP ROLLOVER
   if(gmtNow.hour < InpStartHourGMT || gmtNow.hour >= InpEndHourGMT)
     {
      g_lastBarTime = currentBarTime;
      return;
     }

   if(IsNearTripleSwapRollover(gmtNow))
     {
      g_lastBarTime = currentBarTime;
      return;
     }

   // 7. KIỂM TRA SPREAD TRƯỚC KHI GỌI LỊCH TIN TỨC (TRÁNH GỌI CALENDAR LẶP LẠI KHI SPREAD CAO)
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize <= 0.0) contractSize = 100.0;

   double effectiveCostPerOz = (ask - bid) + (InpEstCommPerLotRT / contractSize);
   if(effectiveCostPerOz > InpMaxEffectiveCostOz)
      return; // Thoát nhẹ trước khi chạm tới CalendarValueHistory

   // 8. KIỂM TRA LỊCH TIN TỨC KINH TẾ
   if(IsHighImpactNewsWindow())
     {
      g_lastBarTime = currentBarTime;
      return;
     }

   // 9. ĐỌC DỮ LIỆU CHỈ BÁO & 3 NẾN M15 VỪA ĐÓNG
   double emaFast[2], emaSlow[2], rsi[2], atr[2];
   MqlRates rates[3];

   if(CopyBuffer(g_handleEMAFast, 0, 1, 2, emaFast) < 2 ||
      CopyBuffer(g_handleEMASlow, 0, 1, 2, emaSlow) < 2 ||
      CopyBuffer(g_handleRSI,     0, 1, 2, rsi)     < 2 ||
      CopyBuffer(g_handleATR,     0, 1, 2, atr)     < 2 ||
      CopyRates(_Symbol, PERIOD_M15, 1, 3, rates)   < 3)
      return;

   // rates[2]: nến vừa đóng (Shift 1)
   // rates[1]: nến trước (Shift 2)
   // rates[0]: nến trước nữa (Shift 3)
   double close1   = rates[2].close;
   double range1   = rates[2].high - rates[2].low;
   double atr1     = atr[1];
   double emaF1    = emaFast[1];
   double emaS1    = emaSlow[1];
   double rsiPrev  = rsi[0]; // Shift 2
   double rsiClose = rsi[1]; // Shift 1

   g_lastBarTime = currentBarTime;

   if(atr1 <= 0.0 || range1 > InpMaxCandleSpikeATR * atr1)
     {
      g_lastSetupScore = 0;
      g_lastSetupReason = StringFormat("Spike nến quá lớn (%.2f > %.1fxATR)", range1, InpMaxCandleSpikeATR);
      return;
     }

   // 10. NHẬN DIỆN PRICE ACTION & CHẤM ĐIỂM CONFLUENCE SETUP A+
   ENUM_PRICE_ACTION_SIGNAL paSignal = DetectPriceActionPattern(rates[2], rates[1], rates[0]);

   bool uptrend   = (close1 > emaS1) && (emaF1 > emaS1);
   bool downtrend = (close1 < emaS1) && (emaF1 < emaS1);

   bool rsiBuyTrigger  = (rsiPrev <= InpRSIBuyCrossLevel  && rsiClose > InpRSIBuyCrossLevel);
   bool rsiSellTrigger = (rsiPrev >= InpRSISellCrossLevel && rsiClose < InpRSISellCrossLevel);

   bool paBuyTrigger   = (paSignal == SIGNAL_PINBAR_BULLISH || paSignal == SIGNAL_FAKEY_BULLISH || paSignal == SIGNAL_ENGULFING_BULL);
   bool paSellTrigger  = (paSignal == SIGNAL_PINBAR_BEARISH || paSignal == SIGNAL_FAKEY_BEARISH || paSignal == SIGNAL_ENGULFING_BEAR);

   int direction = 0;
   if(uptrend && (rsiBuyTrigger || paBuyTrigger))
      direction = 1;
   else if(downtrend && (rsiSellTrigger || paSellTrigger))
      direction = -1;
   else if(uptrend)
      direction = 1; // Đánh giá cấu trúc hiện tại để hiển thị HUD
   else if(downtrend)
      direction = -1; // Đánh giá cấu trúc hiện tại để hiển thị HUD

   string reason = "";
   int score = 0;
   if(direction != 0)
     {
      score = EvaluateConfluenceScore(direction, paSignal, close1, emaF1, emaS1, rsiClose, atr1, reason);
      g_lastSetupScore = score;
      g_lastSetupReason = reason;
     }
   else
     {
      g_lastSetupScore = 0;
      g_lastSetupReason = "Thị trường Sideway / Chưa rõ Trend";
     }

   bool buySignal  = (direction == 1) && (rsiBuyTrigger || paBuyTrigger);
   bool sellSignal = (direction == -1) && (rsiSellTrigger || paSellTrigger);

   if(!buySignal && !sellSignal)
      return;

   // Lọc khắt khe theo chuẩn A+ (Chỉ cho phép vào lệnh khi điểm hội tụ >= InpMinConfluenceScore)
   if(InpRequireAPlusSetup && score < InpMinConfluenceScore)
     {
      PrintFormat("Setup Ignored: Score %d < %d (Yêu cầu chuẩn A+). Chi tiết: %s",
                  score, InpMinConfluenceScore, reason);
      return;
     }

   // 11. CHUẨN HÓA LOT, KIỂM TRA MARGIN VÀ GỬI LỆNH
   g_trade.SetTypeFillingBySymbol(_Symbol);

   if(buySignal)
     {
      double sl  = NormalizeDouble(ask - (InpSLMultiplierATR * atr1), _Digits);
      double tp  = NormalizeDouble(ask + (InpTPMultiplierATR * atr1), _Digits);
      double lot = CalculateAndValidateLot(ORDER_TYPE_BUY, ask, sl);

      if(lot > 0.0)
        {
         string comment = StringFormat("XAU_M15_A+_%d", score);
         if(g_trade.Buy(lot, _Symbol, ask, sl, tp, comment))
           {
            uint ret = g_trade.ResultRetcode();
            if(ret != TRADE_RETCODE_DONE && ret != TRADE_RETCODE_PLACED)
               PrintFormat("BUY rejected! Retcode: %u (%s)", ret, g_trade.ResultRetcodeDescription());
            else
               PrintFormat("BUY EXECUTED: Setup A+ Score %d/100 | Lot: %.2f | %s", score, lot, reason);
           }
        }
     }
   else if(sellSignal)
     {
      double sl  = NormalizeDouble(bid + (InpSLMultiplierATR * atr1), _Digits);
      double tp  = NormalizeDouble(bid - (InpTPMultiplierATR * atr1), _Digits);
      double lot = CalculateAndValidateLot(ORDER_TYPE_SELL, bid, sl);

      if(lot > 0.0)
        {
         string comment = StringFormat("XAU_M15_A+_%d", score);
         if(g_trade.Sell(lot, _Symbol, bid, sl, tp, comment))
           {
            uint ret = g_trade.ResultRetcode();
            if(ret != TRADE_RETCODE_DONE && ret != TRADE_RETCODE_PLACED)
               PrintFormat("SELL rejected! Retcode: %u (%s)", ret, g_trade.ResultRetcodeDescription());
            else
               PrintFormat("SELL EXECUTED: Setup A+ Score %d/100 | Lot: %.2f | %s", score, lot, reason);
           }
        }
     }
  }
//+------------------------------------------------------------------+
