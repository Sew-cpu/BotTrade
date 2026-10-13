//+------------------------------------------------------------------+
//|                                     FlashGold_M1_Scalper_EA.mq5  |
//|        SMART-FLOW & ANTI-TRAP M1 SCALPER - GOLD EXNESS EDITION     |
//|               PHIÊN BẢN V5.20 - VÀO NHANH & CHỐNG BẪY WHIPLASH   |
//| 1. Chống đu đỉnh tuyệt đối: Cấm Buy khi RSI > 68 hoặc chạm Upper BB|
//| 2. Chống bán đáy tuyệt đối: Cấm Sell khi RSI < 32 hoặc chạm Lower BB|
//| 3. Tận dụng đảo chiều đỉnh/đáy: Sell khi chạm đỉnh, Buy khi nảy đáy|
//| 4. Rải vị thế cách nấc $0.50 giá (không dồn cục chết chùm)        |
//| 5. Chốt lời cụm Basket TP siêu tốc + Cập nhật Realtime từng giây  |
//|                                  Copyright 2026, Antigravity     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, Antigravity"
#property link        "https://github.com/Sew-cpu/BotTrade"
#property version     "5.20"
#property description "Robot Luot Song VANG M1: Vao nhanh lien tuc + Bo loc thong minh chong du dinh ban day"
#property strict

//--- Thu vien chuan MetaQuotes MQL5
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                     |
//+------------------------------------------------------------------+
enum ENUM_M1_LOT_MODE
  {
   M1_LOT_FIXED        = 0, // Lot co dinh moi lenh (0.01 hoac 0.02)
   M1_LOT_RISK_PERCENT = 1  // Tinh theo % Rui ro tai khoan
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - THIẾT LẬP V5.20 SMART FLOW                    |
//+------------------------------------------------------------------+
input group "=== 1. TỐC ĐỘ VÀO LỆNH & SỐ VỊ THẾ DỒN DẬP ==="
input int                  InpMaxOpenPositions  = 5;                    // So lenh mo toi da dong thoi (3 - 8 lenh)
input double               InpMinDistanceUSD    = 0.50;                 // Khoang cach toi thieu giua cac lenh ($0.50 gia, tranh don cuc)
input int                  InpCooldownSeconds   = 2;                    // Cooldown giua cac lenh (2 giay)

input group "=== 2. CHỐNG ĐU ĐỈNH & BÁN ĐÁY (ANTI-TRAP FILTERS) ==="
input double               InpRsiOverbought     = 68.0;                 // Nguong qua mua M1 (RSI > 68: CAM BUY, chi canh Sell dao chieu)
input double               InpRsiOversold       = 32.0;                 // Nguong qua ban M1 (RSI < 32: CAM SELL, chi canh Buy dao chieu)
input int                  InpBandsPeriod       = 20;                   // Bollinger Bands chu ky 20
input double               InpBandsDeviation    = 2.0;                  // Do lech chuan 2.0 SD

input group "=== 3. CHỐT LỜI SIÊU TỐC (BASKET TP & MONEY TP) ==="
input bool                 InpUseBasketTP       = true;                 // Chot loi ca chum lenh khi tong lai dat muc tieu
input double               InpBasketProfitUSD   = 4.00;                 // Tong tien loi USD cua ca chum de DONG SACH DUT TUI
input bool                 InpUseIndividualTP   = true;                 // Chot loi don le theo tung lenh
input double               InpTargetProfitUSD   = 2.20;                 // Lenh cu lai >= $2.20 USD la chot ngay khong cho doi

input group "=== 4. QUẢN TRỊ VỐN & VOLUME LOT ==="
input ENUM_M1_LOT_MODE     InpLotMode           = M1_LOT_FIXED;         // Che do tinh Lot
input double               InpFixedLot          = 0.02;                 // Lot moi lenh (0.01 hoac 0.02)
input double               InpRiskPercent       = 1.0;                  // % Rui ro neu dung che do Risk
input double               InpMaxLotAllowed     = 0.50;                 // Tran Lot toi da
input bool                 InpUseDailyLossGuard = true;                 // Bat la chan bao ve so du trong ngay
input double               InpMaxDailyLossPct   = 6.0;                  // Dung bot neu lo vuot qua % von trong ngay

input group "=== 5. CHỈ SỐ SL/TP BẢO VỆ CHỐNG QUÉT SPREAD (USD) ==="
input double               InpStopLoss_USD      = 2.50;                 // SL moi lenh ($2.50 gia, gap 10 lan spread Exness)
input double               InpTakeProfit_USD    = 3.20;                 // TP co dinh moi lenh ($3.20 gia)
input bool                 InpUseBreakEven      = true;                 // Bat Auto Break-Even
input double               InpBreakEvenTrigger_USD = 1.40;              // Keo BE khi gia chay duoc >= $1.40 gia
input double               InpBreakEvenOffset_USD  = 0.35;              // Bu phi spread Vang +$0.35 (Hoa von van DUONG TIEN)
input bool                 InpUseTrailingStop   = true;                 // Bat Trailing Stop
input double               InpTrailingStart_USD = 1.60;                 // Bat dau Trailing khi lai vuot $1.60 gia
input double               InpTrailingStep_USD  = 0.25;                 // Buoc nhay Trailing ($0.25 gia)

input group "=== 6. BỘ LỌC AN TOÀN SÀN EXNESS ==="
input double               InpMaxSpread_USD     = 0.45;                 // Spread toi da cho phep ($0.45 = 450 pts)
input ulong                InpMagicNumber       = 888520;               // Magic Number FlashGold v5.20
input string               InpTradeComment      = "SmartM1_v52";        // Ghi chu lenh
input bool                 InpShowDashboard     = true;                 // Hien thi bang HUD truc quan

//+------------------------------------------------------------------+
//| BIẾN TOÀN CỤC & ĐỐI TƯỢNG                                        |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;
CAccountInfo   m_account;
CSymbolInfo    m_symbol;

int            m_hM1FastEma = INVALID_HANDLE;
int            m_hM1SlowEma = INVALID_HANDLE;
int            m_hM1Rsi     = INVALID_HANDLE;
int            m_hM1Bands   = INVALID_HANDLE;

// Thong ke & Quan ly
datetime       m_lastTradeTime     = 0;
datetime       m_dayStartTime      = 0;
double         m_dayStartEquity    = 0.0;
bool           m_dailyLimitHit     = false;
int            m_todayTotalTrades  = 0;
int            m_todayWinTrades    = 0;
int            m_todayLossTrades   = 0;
double         m_todayProfit       = 0.0;
int            m_lastDealsTotal    = 0;
string         m_lastSignalDesc    = "DANG SAN TIN HIEU THONG MINH...";
color          m_statusColor       = clrGold;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0, "FlashM1_");

   if(!m_symbol.Name(_Symbol))
     {
      Print("[LOI] Khong the khoi tao symbol: ", _Symbol);
      return(INIT_FAILED);
     }
   m_symbol.Refresh();

   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(30);

   uint filling = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((filling & SYMBOL_FILLING_IOC) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);

   m_hM1FastEma = iMA(_Symbol, PERIOD_M1, 9, 0, MODE_EMA, PRICE_CLOSE);
   m_hM1SlowEma = iMA(_Symbol, PERIOD_M1, 21, 0, MODE_EMA, PRICE_CLOSE);
   m_hM1Rsi     = iRSI(_Symbol, PERIOD_M1, 7, PRICE_CLOSE);
   m_hM1Bands   = iBands(_Symbol, PERIOD_M1, InpBandsPeriod, 0, InpBandsDeviation, PRICE_CLOSE);

   if(m_hM1FastEma == INVALID_HANDLE || m_hM1SlowEma == INVALID_HANDLE || 
      m_hM1Rsi == INVALID_HANDLE     || m_hM1Bands == INVALID_HANDLE)
     {
      Print("[LOI] Khong the khoi tao Indicators!");
      return(INIT_FAILED);
     }

   // RESET MỐC BẢO VỆ ĐỂ BOT HOẠT ĐỘNG NGAY
   m_dayStartEquity = m_account.Equity();
   m_dayStartTime   = GetDayStartTime(TimeCurrent());
   m_dailyLimitHit  = false;
   m_lastTradeTime  = 0;
   m_lastDealsTotal = 0;

   // CẤU HÌNH GIAO DIỆN CHỐNG NẾN CHÈN VÀ TỰ ĐỘNG CHỪA LỀ
   ChartSetInteger(0, CHART_FOREGROUND, false);
   ChartSetInteger(0, CHART_SHIFT, true);
   ChartSetDouble(0, CHART_SHIFT_SIZE, 18.0);

   // BẬT TIMER CẬP NHẬT CHỈ SỐ SIÊU TỐC 4 LẦN/GIÂY (250ms)
   EventSetMillisecondTimer(250);

   RefreshTodayStats();

   PrintFormat(">>> [FLASHGOLD v5.25 SMART ANTI-TRAP] Khoi tao tren %s | Max %d lenh | Magic: %d",
               _Symbol, InpMaxOpenPositions, InpMagicNumber);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(m_hM1FastEma != INVALID_HANDLE) IndicatorRelease(m_hM1FastEma);
   if(m_hM1SlowEma != INVALID_HANDLE) IndicatorRelease(m_hM1SlowEma);
   if(m_hM1Rsi     != INVALID_HANDLE) IndicatorRelease(m_hM1Rsi);
   if(m_hM1Bands   != INVALID_HANDLE) IndicatorRelease(m_hM1Bands);

   ObjectsDeleteAll(0, "FlashM1_");
   Comment("");
  }

//+------------------------------------------------------------------+
//| TIMER EVENT FUNCTION (CHẠY 250MS MỖI LẦN - BẢNG KHÔNG BAO GIỜ ĐƠ)|
//+------------------------------------------------------------------+
void OnTimer()
  {
   CheckHistoryDealsUpdate();
   if(InpShowDashboard)
     {
      RenderDashboard();
     }
  }

//+------------------------------------------------------------------+
//| TRADE EVENT FUNCTION                                             |
//+------------------------------------------------------------------+
void OnTrade()
  {
   RefreshTodayStats();
   if(InpShowDashboard) RenderDashboard();
  }

void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
     {
      RefreshTodayStats();
      if(InpShowDashboard) RenderDashboard();
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!m_symbol.RefreshRates()) return;

   // 1. Kiem tra reset ngay & Bao ve Drawdown
   CheckDailyGuard();

   // 2. Kiem tra lich su Deal de cap nhat Thong ke va PnL tuc thi moi tick
   CheckHistoryDealsUpdate();

   // 3. Kiem tra chot loi chum lenh (Basket Take Profit)
   CheckBasketTakeProfit();

   // 4. Quan ly cac vi the dang mo (Money TP, Break-Even, Trailing Stop)
   ManageOpenPositions();

   // 5. Cap nhat giao dien HUD Dashboard
   if(InpShowDashboard) RenderDashboard();

   // 6. Neu cham gioi han lo trong ngay thi tam dung
   if(m_dailyLimitHit) return;

   // 7. Kiem tra Spread hien tai (Chong gian spread)
   double currentSpreadUSD = (m_symbol.Ask() - m_symbol.Bid());
   if(currentSpreadUSD > InpMaxSpread_USD)
     {
      m_lastSignalDesc = StringFormat("[HOAN] Spread cao $%.2f", currentSpreadUSD);
      m_statusColor    = clrOrangeRed;
      return;
     }

   // 8. Kiem tra Cooldown giua cac lenh (2 giay)
   if(InpCooldownSeconds > 0 && (TimeCurrent() - m_lastTradeTime < InpCooldownSeconds))
     {
      return;
     }

   // 9. Kiem tra so luong lenh dang mo
   int currentTrades = CountCurrentTrades();
   if(currentTrades >= InpMaxOpenPositions)
     {
      return;
     }

   // 10. Quet va Thuc thi ban lenh thong minh (Smart Flow)
   CheckAndExecuteSmartSignals();
  }

//+------------------------------------------------------------------+
//| KIỂM TRA CHỐT LỜI CẢ CHÙM LỆNH (BASKET TAKE PROFIT)              |
//+------------------------------------------------------------------+
void CheckBasketTakeProfit()
  {
   if(!InpUseBasketTP) return;

   double totalFloatingProfit = 0.0;
   int myPositions = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
        {
         totalFloatingProfit += (m_position.Profit() + m_position.Swap());
         myPositions++;
        }
     }

   // Cả chùm lệnh từ 2 lệnh trở lên chạm mục tiêu -> ĐÓNG SẠCH CẢ CỤM!
   if(myPositions >= 2 && totalFloatingProfit >= InpBasketProfitUSD)
     {
      PrintFormat(">>>>> [BASKET TP] Tong lai chum lenh dat +$%.2f USD! DONG SACH %d LENH!",
                  totalFloatingProfit, myPositions);
      CloseAllMyPositions();
     }
  }

//+------------------------------------------------------------------+
//| ĐÓNG TẤT CẢ VỊ THẾ CỦA EA                                        |
//+------------------------------------------------------------------+
void CloseAllMyPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
        {
         m_trade.PositionClose(m_position.Ticket());
        }
     }
   RefreshTodayStats();
   if(InpShowDashboard) RenderDashboard();
  }

//+------------------------------------------------------------------+
//| QUÉT TÍN HIỆU THÔNG MINH CHỐNG ĐU ĐỈNH BÁN ĐÁY (SMART FLOW)      |
//+------------------------------------------------------------------+
void CheckAndExecuteSmartSignals()
  {
   double fastEma0 = GetIndicatorVal(m_hM1FastEma, 0, 0);
   double slowEma0 = GetIndicatorVal(m_hM1SlowEma, 0, 0);
   double rsi0     = GetIndicatorVal(m_hM1Rsi, 0, 0);
   double upperBB0 = GetIndicatorVal(m_hM1Bands, 1, 0);
   double lowerBB0 = GetIndicatorVal(m_hM1Bands, 2, 0);
   double midBB0   = GetIndicatorVal(m_hM1Bands, 0, 0);

   if(fastEma0 == 0 || slowEma0 == 0 || rsi0 == 0 || upperBB0 == 0) return;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M1, 0, 2, rates) < 2) return;

   double currentBid = m_symbol.Bid();
   double currentAsk = m_symbol.Ask();

   bool buySignal  = false;
   bool sellSignal = false;

   // ---------------------------------------------------------------
   // 1. TÍN HIỆU BUY THÔNG MINH:
   // ---------------------------------------------------------------
   // A. Thuận đà tăng (Trend Flow): EMA 9 >= EMA 21 VÀ Giá trên midBB
   //    CHỐNG ĐU ĐỈNH: RSI PHẢI <= 65 VÀ Giá không được vượt ngoài dải trên Bollinger!
   if(fastEma0 >= slowEma0 && rates[0].close >= midBB0 && rsi0 >= 40.0 && rsi0 <= InpRsiOverbought && currentAsk < upperBB0 - 0.20)
     {
      if(CanOpenNextOrder(POSITION_TYPE_BUY, currentAsk))
        {
         buySignal = true;
        }
     }
   // B. Bắt đáy đảo chiều (Bounce Bottom): Khi RSI rơi sâu chạm vùng quá bán hoặc chạm Lower BB rồi nảy lên
   else if((rsi0 <= InpRsiOversold || currentBid <= lowerBB0 + 0.15) && rates[0].close > rates[0].open)
     {
      if(CanOpenNextOrder(POSITION_TYPE_BUY, currentAsk))
        {
         buySignal = true;
        }
     }

   // ---------------------------------------------------------------
   // 2. TÍN HIỆU SELL THÔNG MINH:
   // ---------------------------------------------------------------
   // A. Thuận đà giảm (Trend Flow): EMA 9 < EMA 21 VÀ Giá dưới midBB
   //    CHỐNG BÁN ĐÁY: RSI PHẢI >= 35 VÀ Giá không được vượt ngoài dải dưới Bollinger!
   if(fastEma0 < slowEma0 && rates[0].close <= midBB0 && rsi0 <= 60.0 && rsi0 >= InpRsiOversold && currentBid > lowerBB0 + 0.20)
     {
      if(CanOpenNextOrder(POSITION_TYPE_SELL, currentBid))
        {
         sellSignal = true;
        }
     }
   // B. Bắt đỉnh đảo chiều (Drop Top): Khi RSI phóng cao chạm vùng quá mua hoặc chạm Upper BB rồi cắm xuống
   else if((rsi0 >= InpRsiOverbought || currentAsk >= upperBB0 - 0.15) && rates[0].close < rates[0].open)
     {
      if(CanOpenNextOrder(POSITION_TYPE_SELL, currentBid))
        {
         sellSignal = true;
        }
     }

   // THỰC THI BẮN LỆNH
   if(buySignal)
     {
      ExecuteBuyOrder();
     }
   else if(sellSignal)
     {
      ExecuteSellOrder();
     }
  }

//+------------------------------------------------------------------+
//| KIỂM TRA KHOẢNG CÁCH NẤC GIÁ $0.50 (KHÔNG DỒN CỤC CHẾT CHÙM)     |
//+------------------------------------------------------------------+
bool CanOpenNextOrder(ENUM_POSITION_TYPE posType, double currentPrice)
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      count++;
      if(m_position.PositionType() == posType)
        {
         double openPrice = m_position.PriceOpen();
         double distUSD   = MathAbs(currentPrice - openPrice);
         // Phải cách nhau tối thiểu $0.50 giá để rải đều vị thế an toàn!
         if(distUSD < InpMinDistanceUSD)
           {
            return false;
           }
        }
     }
   return (count < InpMaxOpenPositions);
  }

//+------------------------------------------------------------------+
//| VÀO LỆNH BUY VÀNG M1                                             |
//+------------------------------------------------------------------+
void ExecuteBuyOrder()
  {
   double ask = m_symbol.Ask();
   int digits = (int)m_symbol.Digits();

   double slPrice = NormalizeDouble(ask - InpStopLoss_USD, digits);
   double tpPrice = NormalizeDouble(ask + InpTakeProfit_USD, digits);

   double lot = CalculateOrderLot(InpStopLoss_USD);

   if(m_trade.Buy(lot, _Symbol, ask, slPrice, tpPrice, InpTradeComment))
     {
      m_lastTradeTime  = TimeCurrent();
      int totalPos = CountCurrentTrades();
      m_lastSignalDesc = StringFormat("[BUY #%d] %.2f Lot @ %.2f", totalPos, lot, ask);
      m_statusColor    = clrLimeGreen;
      PrintFormat(">>> [SMART BUY #%d] Lot: %.2f | Gia: %.2f | SL: -$%.2f | TP: +$%.2f",
                  totalPos, lot, ask, InpStopLoss_USD, InpTakeProfit_USD);
      
      RefreshTodayStats();
      if(InpShowDashboard) RenderDashboard();
     }
   else
     {
      PrintFormat("[LOI BUY] Khong the vao lenh: %s", m_trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| VÀO LỆNH SELL VÀNG M1                                            |
//+------------------------------------------------------------------+
void ExecuteSellOrder()
  {
   double bid = m_symbol.Bid();
   int digits = (int)m_symbol.Digits();

   double slPrice = NormalizeDouble(bid + InpStopLoss_USD, digits);
   double tpPrice = NormalizeDouble(bid - InpTakeProfit_USD, digits);

   double lot = CalculateOrderLot(InpStopLoss_USD);

   if(m_trade.Sell(lot, _Symbol, bid, slPrice, tpPrice, InpTradeComment))
     {
      m_lastTradeTime  = TimeCurrent();
      int totalPos = CountCurrentTrades();
      m_lastSignalDesc = StringFormat("[SELL #%d] %.2f Lot @ %.2f", totalPos, lot, bid);
      m_statusColor    = clrTomato;
      PrintFormat(">>> [SMART SELL #%d] Lot: %.2f | Gia: %.2f | SL: -$%.2f | TP: +$%.2f",
                  totalPos, lot, bid, InpStopLoss_USD, InpTakeProfit_USD);
      
      RefreshTodayStats();
      if(InpShowDashboard) RenderDashboard();
     }
   else
     {
      PrintFormat("[LOI SELL] Khong the vao lenh: %s", m_trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| QUẢN LÝ LỆNH ĐƠN LẺ                                              |
//+------------------------------------------------------------------+
void ManageOpenPositions()
  {
   double bid    = m_symbol.Bid();
   double ask    = m_symbol.Ask();
   int    digits = (int)m_symbol.Digits();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      ulong  ticket    = m_position.Ticket();
      double openPrice = m_position.PriceOpen();
      double curSl     = m_position.StopLoss();
      double curTp     = m_position.TakeProfit();
      double profitUSD = m_position.Profit() + m_position.Swap();
      ENUM_POSITION_TYPE type = m_position.PositionType();

      // 1. CHỐT LỜI ĐƠN LẺ
      if(InpUseIndividualTP && profitUSD >= InpTargetProfitUSD)
        {
         if(m_trade.PositionClose(ticket))
           {
            PrintFormat(">> [MONEY TP] Chot loi don le lenh #%I64u tai +$%.2f USD!", ticket, profitUSD);
            RefreshTodayStats();
            if(InpShowDashboard) RenderDashboard();
            continue;
           }
        }

      // 2. AUTO BREAK-EVEN & TRAILING CHO BUY
      if(type == POSITION_TYPE_BUY)
        {
         double profitPriceUSD = bid - openPrice;

         if(InpUseBreakEven && profitPriceUSD >= InpBreakEvenTrigger_USD)
           {
            double safeBePrice = NormalizeDouble(openPrice + InpBreakEvenOffset_USD, digits);
            if(curSl < safeBePrice || curSl == 0.0)
              {
               if(m_trade.PositionModify(ticket, safeBePrice, curTp))
                  curSl = safeBePrice;
              }
           }

         if(InpUseTrailingStop && profitPriceUSD >= InpTrailingStart_USD)
           {
            double newSl = NormalizeDouble(bid - InpStopLoss_USD * 0.70, digits);
            if(newSl > curSl + InpTrailingStep_USD)
               m_trade.PositionModify(ticket, newSl, curTp);
           }
        }
      // 3. AUTO BREAK-EVEN & TRAILING CHO SELL
      else if(type == POSITION_TYPE_SELL)
        {
         double profitPriceUSD = openPrice - ask;

         if(InpUseBreakEven && profitPriceUSD >= InpBreakEvenTrigger_USD)
           {
            double safeBePrice = NormalizeDouble(openPrice - InpBreakEvenOffset_USD, digits);
            if(curSl > safeBePrice || curSl == 0.0)
              {
               if(m_trade.PositionModify(ticket, safeBePrice, curTp))
                  curSl = safeBePrice;
              }
           }

         if(InpUseTrailingStop && profitPriceUSD >= InpTrailingStart_USD)
           {
            double newSl = NormalizeDouble(ask + InpStopLoss_USD * 0.70, digits);
            if(newSl < curSl - InpTrailingStep_USD || curSl == 0.0)
               m_trade.PositionModify(ticket, newSl, curTp);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| TÍNH TOÁN KHỐI LƯỢNG LOT                                         |
//+------------------------------------------------------------------+
double CalculateOrderLot(double slPriceDistanceUSD)
  {
   if(InpLotMode == M1_LOT_FIXED)
     {
      return NormalizeLot(InpFixedLot);
     }

   double balance   = m_account.Balance();
   double equity    = m_account.Equity();
   double capital   = MathMin(balance, equity);
   double riskMoney = capital * (InpRiskPercent / 100.0) / MathMax(1, InpMaxOpenPositions);

   double contractSize = m_symbol.ContractSize();
   if(contractSize <= 0) contractSize = 100.0;

   double lossPerLot = slPriceDistanceUSD * contractSize;
   if(lossPerLot <= 0) return NormalizeLot(0.01);

   double rawLot = riskMoney / lossPerLot;
   return NormalizeLot(rawLot);
  }

double NormalizeLot(double rawLot)
  {
   double step   = m_symbol.LotsStep();
   double minLot = m_symbol.LotsMin();
   double maxLot = MathMin(m_symbol.LotsMax(), InpMaxLotAllowed);

   if(step <= 0) step = 0.01;
   double lot = MathFloor(rawLot / step) * step;

   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;

   return NormalizeDouble(lot, 2);
  }

int CountCurrentTrades()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
         count++;
     }
   return count;
  }

void CheckDailyGuard()
  {
   datetime now = TimeCurrent();
   datetime currentDayStart = GetDayStartTime(now);

   if(currentDayStart != m_dayStartTime)
     {
      m_dayStartTime   = currentDayStart;
      m_dayStartEquity = m_account.Equity();
      m_dailyLimitHit  = false;
      m_lastDealsTotal = 0;
      RefreshTodayStats();
     }

   if(InpUseDailyLossGuard && !m_dailyLimitHit)
     {
      double curEquity = m_account.Equity();
      double maxAllowedLoss = m_dayStartEquity * (InpMaxDailyLossPct / 100.0);

      if(m_dayStartEquity - curEquity >= maxAllowedLoss)
        {
         m_dailyLimitHit  = true;
         m_lastSignalDesc = "[DỪNG BOT] Chạm mức lỗ tối đa ngày!";
         m_statusColor    = clrRed;
         PrintFormat(">>> FlashGold dừng giao dịch do chạm mức lỗ ngày: -$%.2f", (m_dayStartEquity - curEquity));
        }
     }
  }

void CheckHistoryDealsUpdate()
  {
   if(HistorySelect(m_dayStartTime, TimeCurrent()))
     {
      int currentDeals = HistoryDealsTotal();
      if(currentDeals != m_lastDealsTotal)
        {
         m_lastDealsTotal = currentDeals;
         RefreshTodayStats();
        }
     }
  }

void RefreshTodayStats()
  {
   m_todayTotalTrades = 0;
   m_todayWinTrades   = 0;
   m_todayLossTrades  = 0;
   m_todayProfit      = 0.0;

   if(!HistorySelect(m_dayStartTime, TimeCurrent())) return;
   int totalDeals = HistoryDealsTotal();
   m_lastDealsTotal = totalDeals;

   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;

      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT) + 
                      HistoryDealGetDouble(ticket, DEAL_SWAP) + 
                      HistoryDealGetDouble(ticket, DEAL_COMMISSION);

      m_todayTotalTrades++;
      m_todayProfit += profit;
      if(profit > 0) m_todayWinTrades++;
      else if(profit < 0) m_todayLossTrades++;
     }
  }

double GetIndicatorVal(int handle, int bufferNum, int index)
  {
   if(handle == INVALID_HANDLE) return 0.0;
   double val[];
   ArraySetAsSeries(val, true);
   if(CopyBuffer(handle, bufferNum, index, 1, val) <= 0) return 0.0;
   return val[0];
  }

datetime GetDayStartTime(datetime time)
  {
   MqlDateTime dt;
   TimeToStruct(time, dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   return StructToTime(dt);
  }

//+------------------------------------------------------------------+
//| VẼ DASHBOARD HUD V5.25 REALTIME                                  |
//+------------------------------------------------------------------+
void RenderDashboard()
  {
   ChartSetInteger(0, CHART_FOREGROUND, false); // Luôn đảm bảo nến không bao giờ chèn lên bảng

   string baseName = "FlashM1_";
   int panelX = 15;
   int panelY = 15;
   int panelW = 345;
   int panelH = 225;

   CreateOrUpdatePanel(baseName + "CardBg", panelX, panelY, panelW, panelH, C'14,18,24', C'210,165,30');

   int x = panelX + 12;
   int y = panelY + 10;
   int yStep = 20;

   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity    = AccountInfoDouble(ACCOUNT_EQUITY);
   double bid       = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask       = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spreadUSD = ask - bid;
   double curRsi    = GetIndicatorVal(m_hM1Rsi, 0, 0);

   double winRate   = (m_todayTotalTrades > 0) ? (m_todayWinTrades * 100.0 / m_todayTotalTrades) : 0.0;

   double floatingProfit = 0.0;
   int activeCount = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
        {
         floatingProfit += (m_position.Profit() + m_position.Swap());
         activeCount++;
        }
     }

   CreateOrUpdateLabel(baseName + "Title", StringFormat("⚡ FLASHGOLD v5.25 [SMART FLOW %d]", InpMaxOpenPositions), x, y, clrGold, 10, true); y += 23;
   CreateOrUpdateLabel(baseName + "Acc", StringFormat("Số dư: $%.2f | Vốn: $%.2f", balance, equity), x, y, clrWhite, 8); y += yStep;
   CreateOrUpdateLabel(baseName + "Spread", StringFormat("Spread: $%.2f (Max $%.2f) | Giá: %.2f", spreadUSD, InpMaxSpread_USD, bid), x, y, (spreadUSD <= InpMaxSpread_USD ? clrLime : clrRed), 8); y += yStep;
   CreateOrUpdateLabel(baseName + "Filters", StringFormat("Chống đu đỉnh/bán đáy: RSI=%.1f | BB 2.0", curRsi), x, y, clrAqua, 8, true); y += yStep;
   CreateOrUpdateLabel(baseName + "Basket", StringFormat("Chốt cụm (Basket TP): +$%.2f USD", InpBasketProfitUSD), x, y, clrCyan, 8); y += yStep;
   CreateOrUpdateLabel(baseName + "Pos", StringFormat("Chùm lệnh: %d / %d lệnh | Lãi nổi: %s$%.2f", activeCount, InpMaxOpenPositions, (floatingProfit >= 0 ? "+" : ""), floatingProfit), x, y, (floatingProfit >= 0 ? clrLime : clrSalmon), 8, true); y += yStep;
   CreateOrUpdateLabel(baseName + "Stats", StringFormat("Thống kê: %d Lệnh (%d Thắng / %d Thua - %.0f%%)", m_todayTotalTrades, m_todayWinTrades, m_todayLossTrades, winRate), x, y, clrGold, 8, true); y += yStep;
   CreateOrUpdateLabel(baseName + "PnL", StringFormat("Lợi nhuận ngày đã chốt: %s$%.2f USD", (m_todayProfit >= 0 ? "+" : ""), m_todayProfit), x, y, (m_todayProfit >= 0 ? clrLime : clrSalmon), 8, true); y += yStep;

   // Radar động realtime
   string radarLine = "";
   color  radarClr  = clrGold;
   if(activeCount > 0)
     {
      radarLine = StringFormat("Radar: Giữ %d lệnh | Lãi: %s$%.2f (Cụm TP: +$%.2f)",
                               activeCount, (floatingProfit >= 0 ? "+" : ""), floatingProfit, InpBasketProfitUSD);
      radarClr  = (floatingProfit >= 0 ? clrLime : clrSalmon);
     }
   else
     {
      string rsiStatus = "Vùng Cân Bằng";
      if(curRsi >= InpRsiOverbought) { rsiStatus = "QUÁ MUA (Chặn Buy)"; }
      else if(curRsi <= InpRsiOversold) { rsiStatus = "QUÁ BÁN (Chặn Sell)"; }
      radarLine = StringFormat("Radar: RSI=%.1f [%s] | Săn nhịp...", curRsi, rsiStatus);
      radarClr  = m_statusColor;
     }

   CreateOrUpdateLabel(baseName + "Signal", radarLine, x, y, radarClr, 8, true);

   ChartRedraw(0);
  }

void CreateOrUpdatePanel(string name, int x, int y, int width, int height, color bgColor, color borderColor)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
     }
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 100);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderColor);
  }

void CreateOrUpdateLabel(string name, string text, int x, int y, color clr, int fontSize = 8, bool isBold = false)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
     }
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 110);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, (isBold ? "Arial Bold" : "Arial"));
  }
//+------------------------------------------------------------------+
