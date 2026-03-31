//+------------------------------------------------------------------+
//|                                    Goldmine Combined EA v4.mq5    |
//|                          Signal Detection + Reverse Trading       |
//|                                   v4.0 - Unified System          |
//+------------------------------------------------------------------+
#property copyright "Goldmine Combined Strategy v4.0"
#property version   "4.00"
#property strict

// Input Parameters
input group "=== EMA Settings ==="
input int FastEMA = 5;              // Fast EMA Period
input int SlowEMA = 15;             // Slow EMA Period

input group "=== Timeframe Settings ==="
input ENUM_TIMEFRAMES TF_1HR = PERIOD_H1;    // 1 Hour Timeframe (TF_1HR=1)
input ENUM_TIMEFRAMES TF_15M = PERIOD_M5;    // 15 Min Timeframe (TF_15M=5)
input ENUM_TIMEFRAMES TF_1M = PERIOD_M3;     // 1 Min Entry Timeframe (TF_1M=3)

input group "=== Trading Mode ==="
input bool ExecuteOriginalTrades = false;   // Execute original signal trades
input bool ExecuteReverseTrades = true;     // Execute reverse signal trades
input bool SendSignalsToFile = false;       // Send signals to file (for external receiver)

input group "=== Close Mode Settings ==="
input int CloseMode = 4;               // Close Mode (0=Normal, 1=CloseAll@TP1, 2=CloseAll@SL1, 3=Basket+Grid, 4=Impulse Grid)

input group "=== Grid Zone Settings (Mode 4) ==="
input int GridLayersZone1 = 3;         // Grid layers in Zone 1 (Entry to SL1)
input int GridLayersZone2 = 3;         // Grid layers in Zone 2 (SL1 to SL2)
input int GridLayersZone3 = 2;         // Grid layers in Zone 3 (SL2 to SL3)
input double LotMultiplier = 1.5;      // Lot size multiplier for each grid layer
input double BasketProfitMultiplier = 1.0;

input group "=== Risk Management ==="
input int LotSizeMode = 0;             // Lot Size Mode (0=Fixed, 1=Risk%, 2=Balance%)
input double LotSize = 0.01;           // Fixed lot size (Mode 0)
input double RiskPercent = 2.0;        // Risk percentage (Mode 1)
input double BalancePercent = 10.0;    // Balance percentage for lot calculation (Mode 2)
input int Slippage = 30;               // Slippage in Points
input int MagicNumber = 789012003;     // Magic Number

input group "=== Custom Basket Profit Settings ==="
input bool UseCustomBasketProfit = false;  // Enable custom basket profit per trade
input double CustomBasketProfitAmount = 50.0; // Custom basket profit target ($)
input bool UseCustomBasketPercent = false;  // Use percentage of balance for custom basket
input double CustomBasketProfitPercent = 5.0; // Custom basket profit target (% of balance)

input group "=== Break-Even Risk Management ==="
input bool UseBreakEvenProtection = false; // Enable break-even protection
input double BreakEvenTriggerAmount = 20.0; // Profit amount to trigger break-even ($)
input bool UseBreakEvenPercent = false;    // Use percentage for break-even trigger
input double BreakEvenTriggerPercent = 2.0; // Profit percentage to trigger break-even (% of balance)
input double BreakEvenCloseAmount = 2.0;   // Profit amount to close at break-even ($)
input bool UseBreakEvenClosePercent = false; // Use percentage for break-even close level
input double BreakEvenClosePercent = 0.5;  // Profit percentage to close at break-even (% of balance)
input bool NotifyBreakEven = true;         // Send notifications for break-even moves

input group "=== TP/SL Settings ==="
input double TP1_Points = 150.0;    // TP1 in Points (Fallback)
input double TP2_Points = 250.0;    // TP2 in Points (Fallback)
input double TP3_Points = 400.0;    // TP3 in Points (Fallback)
input double SL_Points = 100.0;     // SL in Points (Fallback)
input double TP1_Multiplier = 0.5;  // TP1 Distance (50% to swing)
input double TP2_Multiplier = 0.8;  // TP2 Distance (80% to swing)
input double TP3_Multiplier = 1.2;  // TP3 Beyond swing
input bool UseSwingTPSL = true;     // Use Swing-Based TP/SL

input group "=== Trading Filters ==="
input bool UseVolumeFilter = false; // Use Volume Confirmation (for signal detection)
input bool UseTrendFilter = true;   // Use Trend Alignment Filter
input bool AllowCounterTrend = false;// Allow Counter-Trend Trades
input int MinBarsForSwing = 1;      // Minimum Bars for Swing Detection

input group "=== Intelligent Grid Settings ==="
input int ATR_Period = 14;             // ATR Period for volatility
input double ImpulseATRMultiplier = 1.5; // Candle size vs ATR to detect impulse
input int ImpulseLookback = 3;         // Bars to check for impulse
input int CooldownBars = 2;            // Bars to wait after impulse before adding grid
input ENUM_TIMEFRAMES ImpulseTimeframe = PERIOD_M1; // Timeframe for impulse detection

input group "=== Volatility Adaptation ==="
input bool UseAdaptiveSpacing = true;  // Enable adaptive grid spacing
input double VolatilityMultiplier = 1.2; // Multiplier for high volatility periods
input double LowVolThreshold = 0.7;    // Low volatility threshold (ATR ratio)
input double HighVolThreshold = 1.5;   // High volatility threshold (ATR ratio)
input int VolatilityPeriod = 20;       // Period for volatility comparison

input group "=== Momentum Filters ==="
input bool UseMomentumFilter = true;   // Enable momentum-based filtering
input int RSI_Period = 14;             // RSI period for momentum
input double RSI_OverboughtLevel = 75; // RSI overbought level
input double RSI_OversoldLevel = 25;   // RSI oversold level
input bool UseVolumeConfirmation = true; // Require volume confirmation
input double VolumeMultiplier = 1.3;   // Volume spike multiplier

input group "=== RSI Entry Filter ==="
input bool UseRSIEntryFilter = false;  // Enable RSI-based entry timing
input double RSI_BuyEntryLevel = 34;   // RSI level for buy entries (34 and below)
input double RSI_SellEntryLevel = 68;  // RSI level for sell entries (68 and above)
input int RSI_WaitTimeoutBars = 50;    // Max bars to wait for RSI condition (0 = no timeout)
input bool RSI_WaitForCandleClose = false; // Wait for candle close to confirm RSI condition

input group "=== RSI Stop Loss ==="
input bool UseRSIStopLoss = false;     // Enable RSI-based stop loss
input double RSI_BuyStopLevel = 20;    // RSI level to close BUY positions (below this level)
input double RSI_SellStopLevel = 80;   // RSI level to close SELL positions (above this level)
input bool RSI_StopWaitForCandleClose = true; // Wait for candle close to confirm RSI stop

input group "=== Daily Limits ==="
input bool UseDailyLimits = true;      // Enable daily profit/loss limits
input bool UseDailyLimitPercentage = false; // Use percentage of balance for daily limits
input double DailyProfitTarget = 10.0; // Daily profit target ($) - stop trading when reached
input double DailyProfitPercent = 10.0; // Daily profit target (%) - used if UseDailyLimitPercentage = true
input double DailyLossLimit = 200.0;   // Daily loss limit ($) - stop trading when reached
input double DailyLossPercent = 5.0;   // Daily loss limit (%) - used if UseDailyLimitPercentage = true
input bool ResetDailyAtMidnight = true; // Reset daily P/L at midnight server time

input group "=== Equity Guard ==="
input bool UseEquityGuard = true;      // Enable one-time equity guard per day
input double EquityGuardPercent = 5.0; // Equity guard trigger percentage of balance
input bool EquityGuardUsesProfit = true; // True = trigger on profit, False = trigger on loss

input group "=== Order Filling Settings ==="
input bool AutoDetectFilling = true; // Auto-detect best filling method
input ENUM_ORDER_TYPE_FILLING ManualFillingMode = ORDER_FILLING_FOK; // Manual filling mode

input group "=== Telegram Notifications ==="
input bool EnableTelegramNotifications = true;  // Enable Telegram notifications
input string TelegramBotToken = "7950524854:AAGkeh9aIWgCk9MVA4UShJQC7aoDQa7Tfq8";  // Telegram Bot Token
input string TelegramChatID = "-1003572893349";  // Telegram Chat ID
input bool NotifyOnSignal = true;       // Notify when new signal received
input bool NotifyOnTrade = true;        // Notify when trades are opened/closed
input bool NotifyOnProfit = true;       // Notify when profit targets reached
input bool NotifyOnLimits = true;       // Notify when daily limits reached
input bool NotifyOnGrid = false;        // Notify when grid positions added (can be noisy)

input group "=== Visual Settings ==="
input bool ShowSignalTable = true;  // Show Signal Table
input bool ShowTPSLLines = true;    // Show TP/SL Lines on Chart
input bool ShowDebugInfo = false;   // Show Debug Information
input color BuyColor = 65280;       // Buy Signal Color
input color SellColor = 255;        // Sell Signal Color

input group "=== Swing Point Visualization ==="
input bool ShowSwingPoints = true;                          // Show Swing Points on Chart
input ENUM_TIMEFRAMES SwingPointTimeframe = PERIOD_H1;      // Swing Point Timeframe
input int SwingPointLookback = 200;                         // Bars to scan for swing points
input int SwingPointStrength = 3;                           // Bars on each side to confirm swing (strength)
input color SwingHighColor = clrMagenta;                    // Swing High (SH) marker color
input color SwingLowColor = clrDodgerBlue;                  // Swing Low (SL) marker color
input int SwingLabelFontSize = 9;                           // SH/SL label font size
input bool ShowSwingPriceLabels = true;                     // Show price next to SH/SL labels
input bool ConnectSwingHighs = false;                       // Draw lines connecting swing highs
input bool ConnectSwingLows = false;                        // Draw lines connecting swing lows
input bool UseATRSwingFilter = true;                        // Use ATR to filter insignificant swings
input double SwingATRMinFactor = 0.5;                       // Min swing size as ATR multiple (filters noise)
input bool UseBodyCloseConfirm = true;                      // Require candle body close to confirm swing
input int SwingConfirmBars = 1;                             // Bars after swing to confirm (price moved away)

input group "=== Swing Point Stop Loss ==="
input bool UseSwingPointSL = true;                          // Use swing point as stop loss for reverse trades
input ENUM_TIMEFRAMES SwingSLTimeframe = PERIOD_H1;         // Timeframe to find swing SL
input int SwingSLLookback = 100;                            // Bars to look back for swing SL
input int SwingSLStrength = 3;                              // Bars on each side for swing SL detection
input double SwingSLBufferPoints = 50;                      // Buffer beyond swing point in Points
input bool UseSwingBodyBreakClose = false;                  // Wait for body close beyond swing to close positions
input ENUM_TIMEFRAMES SwingBodyBreakTF = PERIOD_M15;        // Timeframe to monitor body break of swing SL
input bool ShowSwingSLLine = true;                          // Show swing SL line on chart
input color SwingSLLineColor = clrOrangeRed;                // Swing SL line color
input group "=== Dynamic Take Profit ==="
input bool UseRiskRewardTP = false;                        // Use Risk/Reward based Take Profit
input double RiskRewardRatio = 2.0;                        // Risk/Reward Ratio (e.g., 2.0 = TP is 2x SL distance)
input bool UseSwingPointTP = false;                        // Use Swing Point as Take Profit
input ENUM_TIMEFRAMES SwingTPTimeframe = PERIOD_H1;        // Timeframe to find swing TP
input int SwingTPLookback = 100;                           // Bars to look back for swing TP
input int SwingTPStrength = 3;                             // Bars on each side for swing TP detection
input bool ShowDynamicTPLine = true;                       // Show dynamic TP line on chart
input color DynamicTPLineColor = clrLimeGreen;             // Dynamic TP line color

// Global Variables - Signal Detection (from Sender)
int fastEmaHandle_1M, slowEmaHandle_1M;
int fastEmaHandle_15M, slowEmaHandle_15M;
int fastEmaHandle_1H, slowEmaHandle_1H;
int volumeHandle_1M;

double fastEma_1M[], slowEma_1M[];
double fastEma_15M[], slowEma_15M[];
double fastEma_1H[], slowEma_1H[];
double volume[];

datetime lastBarTime;
datetime lastSignalTime = 0;
int signalCount = 0;
int tradeCount = 0;

// Swing Point Visualization Variables
datetime lastSwingBarTime = 0;
int swingPointCount = 0;
int swingATRHandle = INVALID_HANDLE;

// Swing Point Stop Loss Variables
double currentSwingSLPrice = 0;       // Current swing-based SL price (with buffer)
double currentSwingRawPrice = 0;      // Raw swing point price (without buffer)
bool swingSLActive = false;            // Whether swing SL is currently active
datetime lastSwingSLCheckTime = 0;     // Last bar time for body break check

// Dynamic Take Profit Variables
double currentDynamicTPPrice = 0;      // Current dynamic active TP price
double currentDynamicRawTPPrice = 0;   // Raw TP without any adjustments
bool dynamicTPActive = false;          // Is a dynamic TP active?
string activeTPMode = "";              // "RR" or "Swing"

// Global Variables - Trading (from Receiver)
int atrHandle = INVALID_HANDLE;
int rsiHandle = INVALID_HANDLE;
datetime lastProcessedSignalTime = 0;

// Order filling mode
ENUM_ORDER_TYPE_FILLING currentFillingMode = ORDER_FILLING_FOK;

// Structures
struct SignalInfo {
    string type;
    double entryPrice;
    double tp1, tp2, tp3;
    double sl;
    string trend_1H;
    string trend_15M;
    string trend_1M;
    datetime signalTime;
    bool isValid;
    string reason;
};

struct ReverseSignal {
    string originalType;
    string reverseType;
    double entryPrice;
    double senderSL;      // Our TP
    double senderTP1;     // Our SL1 / Zone 1 boundary
    double senderTP2;     // Our SL2 / Zone 2 boundary
    double senderTP3;     // Our SL3 / Zone 3 boundary (final)
    datetime signalTime;
    bool isValid;
};

struct PendingRSISignal {
    ReverseSignal signal;
    datetime waitStartTime;
    int barsWaited;
    bool isWaiting;
    string waitingFor;    // "BUY_RSI" or "SELL_RSI"
};

struct PositionGroup {
    ulong ticket1;
    ulong ticket2;
    ulong ticket3;
    bool tp1Reached;
    bool tp2Reached;
    datetime openTime;
    string type;
    double entryPrice;
    double targetTP;
    double zone1Boundary;  // SL1
    double zone2Boundary;  // SL2
    double zone3Boundary;  // SL3
    double tp1Price;
    double tp2Price;
    double tp3Price;
    double slPrice;
};

struct GridLayer {
    ulong ticket;
    double entryPrice;
    double lotSize;
    int layerNumber;
    int zone;
    bool isActive;
};

struct ImpulseState {
    bool isInImpulse;
    datetime impulseStartTime;
    datetime impulseEndTime;
    int barsSinceImpulse;
    double impulseDirection;  // 1 = bullish, -1 = bearish
    double lastATR;
    double currentVolatility; // Current volatility ratio
    double avgVolatility;     // Average volatility
    bool isHighVolatility;    // High volatility flag
    bool isLowVolatility;     // Low volatility flag
};

struct MarketCondition {
    double currentRSI;
    double currentVolume;
    double avgVolume;
    bool isOverbought;
    bool isOversold;
    bool hasVolumeSpike;
    bool isMomentumStrong;
    string marketPhase;       // "TRENDING", "RANGING", "VOLATILE"
};

// Global State Variables
SignalInfo currentSignal;
ReverseSignal lastReverseSignal;
PendingRSISignal pendingRSISignal;
PositionGroup originalGroup;  // For original trades
PositionGroup reverseGroup;   // For reverse trades
GridLayer gridLayers[];
ImpulseState impulseState;
MarketCondition marketCondition;
bool syncActive = false;

// Grid Variables
int currentGridCount = 0;
double basketProfitTarget = 0;
double customBasketTarget = 0;  // New: Custom basket profit target
double initialLotSize = 0;
int currentZone = 1;

// Zone grid level prices
double zone1Levels[];
double zone2Levels[];
double zone3Levels[];
int zone1Triggered = 0;
int zone2Triggered = 0;
int zone3Triggered = 0;

// Break-Even Protection Variables
bool breakEvenActivated = false;
double breakEvenTriggerThreshold = 0;
double breakEvenCloseThreshold = 0;  // Level at which to close positions

// Adaptive Grid Variables
double adaptiveSpacing = 0;
double baseSpacing = 0;
datetime lastGridAddTime = 0;

// Daily Limits Tracking
double dailyProfitLoss = 0;
double dailyStartBalance = 0;
datetime currentTradingDay = 0;
bool dailyLimitReached = false;
string dailyLimitReason = "";
double effectiveDailyProfitTarget = 0;
double effectiveDailyLossLimit = 0;

// Equity Guard Tracking
double equityGuardStartBalance = 0;
double equityGuardThreshold = 0;
datetime lastEquityGuardTrigger = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize EMA indicators for signal detection
    fastEmaHandle_1M = iMA(_Symbol, TF_1M, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
    slowEmaHandle_1M = iMA(_Symbol, TF_1M, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
    fastEmaHandle_15M = iMA(_Symbol, TF_15M, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
    slowEmaHandle_15M = iMA(_Symbol, TF_15M, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
    fastEmaHandle_1H = iMA(_Symbol, TF_1HR, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
    slowEmaHandle_1H = iMA(_Symbol, TF_1HR, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
    volumeHandle_1M = iVolumes(_Symbol, TF_1M, VOLUME_TICK);
    
    if(fastEmaHandle_1M == INVALID_HANDLE || slowEmaHandle_1M == INVALID_HANDLE ||
       fastEmaHandle_15M == INVALID_HANDLE || slowEmaHandle_15M == INVALID_HANDLE ||
       fastEmaHandle_1H == INVALID_HANDLE || slowEmaHandle_1H == INVALID_HANDLE ||
       volumeHandle_1M == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create EMA indicators!");
        return(INIT_FAILED);
    }
    
    // Initialize additional indicators for intelligent grid management
    if(CloseMode == 4)
    {
        atrHandle = iATR(_Symbol, ImpulseTimeframe, ATR_Period);
        if(atrHandle == INVALID_HANDLE)
        {
            Print("ERROR: Failed to create ATR indicator");
            return(INIT_FAILED);
        }
        
        if(UseMomentumFilter)
        {
            rsiHandle = iRSI(_Symbol, ImpulseTimeframe, RSI_Period, PRICE_CLOSE);
            if(rsiHandle == INVALID_HANDLE)
            {
                Print("ERROR: Failed to create RSI indicator");
                return(INIT_FAILED);
            }
        }
    }
    
    // Set array series
    ArraySetAsSeries(fastEma_1M, true);
    ArraySetAsSeries(slowEma_1M, true);
    ArraySetAsSeries(fastEma_15M, true);
    ArraySetAsSeries(slowEma_15M, true);
    ArraySetAsSeries(fastEma_1H, true);
    ArraySetAsSeries(slowEma_1H, true);
    ArraySetAsSeries(volume, true);
    
    // Initialize state
    lastBarTime = 0;
    currentSignal.isValid = false;
    lastReverseSignal.isValid = false;
    
    // Detect and set filling mode
    currentFillingMode = DetectFillingMode();
    Print("Order Filling Mode: ", GetFillingModeDescription(currentFillingMode));
    
    ResetPositionGroups();
    ResetGrid();
    ResetImpulseState();
    InitializeDailyTracking();
    InitializeEquityGuard();
    InitializeBreakEvenProtection();
    InitializePendingRSISignal();
    
    if(ShowSignalTable)
        CreateSignalTable();
    
    // Initialize swing point ATR for filtering
    if(ShowSwingPoints && UseATRSwingFilter)
    {
        swingATRHandle = iATR(_Symbol, SwingPointTimeframe, 14);
        if(swingATRHandle == INVALID_HANDLE)
            Print("WARNING: Failed to create Swing ATR indicator, ATR filtering disabled");
    }
    
    // Draw initial swing points
    if(ShowSwingPoints)
        DrawSwingPoints();
    
    Print("==========================================");
    Print("Goldmine Combined EA v4.0 Started");
    Print("Symbol: ", _Symbol);
    Print("Execute Original Trades: ", ExecuteOriginalTrades);
    Print("Execute Reverse Trades: ", ExecuteReverseTrades);
    Print("Send Signals to File: ", SendSignalsToFile);
    Print("Close Mode: ", GetCloseModeDescription());
    if(CloseMode == 4)
    {
        Print("Zone 1 Layers: ", GridLayersZone1);
        Print("Zone 2 Layers: ", GridLayersZone2);
        Print("Zone 3 Layers: ", GridLayersZone3);
        Print("Intelligent Features:");
        Print("  - Adaptive Spacing: ", (UseAdaptiveSpacing ? "ON" : "OFF"));
        Print("  - Momentum Filter: ", (UseMomentumFilter ? "ON" : "OFF"));
        Print("  - RSI Entry Filter: ", (UseRSIEntryFilter ? "ON" : "OFF"));
        if(UseRSIEntryFilter)
        {
            Print("    * Buy Entry RSI: <= ", DoubleToString(RSI_BuyEntryLevel, 1));
            Print("    * Sell Entry RSI: >= ", DoubleToString(RSI_SellEntryLevel, 1));
            Print("    * Wait Timeout: ", (RSI_WaitTimeoutBars > 0 ? IntegerToString(RSI_WaitTimeoutBars) + " bars" : "No timeout"));
            Print("    * Execution Mode: ", (RSI_WaitForCandleClose ? "Wait for candle close" : "Immediate (tick-based)"));
        }
        if(UseRSIStopLoss)
        {
            Print("  - RSI Stop Loss: ", (UseRSIStopLoss ? "ON" : "OFF"));
            Print("    * Buy Stop RSI: < ", DoubleToString(RSI_BuyStopLevel, 1));
            Print("    * Sell Stop RSI: > ", DoubleToString(RSI_SellStopLevel, 1));
            Print("    * Stop Mode: ", (RSI_StopWaitForCandleClose ? "Wait for candle close" : "Immediate (tick-based)"));
        }
        Print("  - Volatility Thresholds: Low=", DoubleToString(LowVolThreshold, 2), " High=", DoubleToString(HighVolThreshold, 2));
        Print("Impulse Detection: ATR x", DoubleToString(ImpulseATRMultiplier, 1), " | Cooldown: ", CooldownBars, " bars");
    }
    Print("Magic Number: ", MagicNumber);
    Print("==========================================");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release EMA indicators
    IndicatorRelease(fastEmaHandle_1M);
    IndicatorRelease(slowEmaHandle_1M);
    IndicatorRelease(fastEmaHandle_15M);
    IndicatorRelease(slowEmaHandle_15M);
    IndicatorRelease(fastEmaHandle_1H);
    IndicatorRelease(slowEmaHandle_1H);
    IndicatorRelease(volumeHandle_1M);
    
    // Release additional indicators
    if(atrHandle != INVALID_HANDLE)
        IndicatorRelease(atrHandle);
    if(rsiHandle != INVALID_HANDLE)
        IndicatorRelease(rsiHandle);
    if(swingATRHandle != INVALID_HANDLE)
        IndicatorRelease(swingATRHandle);
    
    // Clean up objects
    ObjectsDeleteAll(0, "Signal_");
    ObjectsDeleteAll(0, "TP_");
    ObjectsDeleteAll(0, "SL_");
    ObjectsDeleteAll(0, "Debug_");
    ObjectsDeleteAll(0, "Reverse_");
    ObjectsDeleteAll(0, "Grid_");
    ObjectsDeleteAll(0, "SwingH_");
    ObjectsDeleteAll(0, "SwingL_");
    ObjectsDeleteAll(0, "SwingHL_");
    ObjectsDeleteAll(0, "SwingLL_");
    ObjectsDeleteAll(0, "SwingSL_");
    ObjectsDeleteAll(0, "DynamicTP_");
    
    Print("Combined EA Stopped. Signals: ", signalCount, " | Trades: ", tradeCount);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update swing points on new bar of swing timeframe
    if(ShowSwingPoints)
    {
        datetime currentSwingBarTime = iTime(_Symbol, SwingPointTimeframe, 0);
        if(currentSwingBarTime != lastSwingBarTime)
        {
            lastSwingBarTime = currentSwingBarTime;
            DrawSwingPoints();
        }
    }
    
    // Check and update daily limits
    if(UseDailyLimits)
    {
        CheckDailyReset();
        UpdateDailyPL();
        
        // If daily limit reached, don't process new signals
        if(dailyLimitReached)
        {
            if(ShowSignalTable)
                UpdateSignalTable(currentSignal);
            return;
        }
    }
    
    // PRIORITY CHECK: Break-even protection (when active) - checked on EVERY TICK for instant reaction
    if(ExecuteReverseTrades && UseBreakEvenProtection && breakEvenActivated && syncActive)
    {
        CheckBreakEvenProtection();
        // If positions were closed by break-even, return immediately
        if(CountOpenPositions(false) == 0)
        {
            if(ShowSignalTable)
                UpdateSignalTable(currentSignal);
            return;
        }
    }
    
    // Check equity guard
    if(ExecuteReverseTrades && UseEquityGuard)
    {
        CheckEquityGuard();
    }
    
    // Check break-even protection for activation (only when not yet active)
    if(ExecuteReverseTrades && UseBreakEvenProtection && !breakEvenActivated && syncActive)
    {
        CheckBreakEvenProtection();
    }
    
    // Check RSI stop loss (priority check - before other processing)
    if(ExecuteReverseTrades && UseRSIStopLoss && UseMomentumFilter && syncActive)
    {
        if(RSI_StopWaitForCandleClose)
        {
            // Only check on new bar formation for candle close mode
            datetime currentBarTime = iTime(_Symbol, ImpulseTimeframe, 0);
            static datetime lastRSIStopTime = 0;
            if(currentBarTime != lastRSIStopTime)
            {
                lastRSIStopTime = currentBarTime;
                UpdateCurrentRSI(); // Update RSI for the check
                if(CheckRSIStopLoss())
                {
                    if(ShowSignalTable)
                        UpdateSignalTable(currentSignal);
                    return; // Exit early if positions were closed
                }
            }
        }
        else
        {
            // Check on every tick for immediate stop
            UpdateCurrentRSI(); // Update RSI for the check
            if(CheckRSIStopLoss())
            {
                if(ShowSignalTable)
                    UpdateSignalTable(currentSignal);
                return; // Exit early if positions were closed
            }
        }
    }
    
    // Check for new bar on 1M timeframe for signal detection
    datetime currentBarTime = iTime(_Symbol, TF_1M, 0);
    if(currentBarTime != lastBarTime)
    {
        lastBarTime = currentBarTime;
        
        // Copy indicator data for signal detection
        if(!CopyIndicatorData())
        {
            if(ShowDebugInfo)
                Print("DEBUG: Failed to copy indicator data");
            return;
        }
        
        // Analyze trends
        string trend_1H = AnalyzeTrend(TF_1HR);
        string trend_15M = AnalyzeTrend(TF_15M);
        string trend_1M = AnalyzeTrend(TF_1M);
        
        if(ShowDebugInfo)
        {
            static datetime lastDebugTime = 0;
            if(TimeCurrent() - lastDebugTime > 300)
            {
                Print("DEBUG Trends - 1H:", trend_1H, " | 15M:", trend_15M, " | 1M:", trend_1M);
                lastDebugTime = TimeCurrent();
            }
        }
        
        // Check for new signal only if no positions are open
        bool hasOriginalPositions = (ExecuteOriginalTrades && CountOpenPositions(true) > 0);
        bool hasReversePositions = (ExecuteReverseTrades && CountOpenPositions(false) > 0);
        
        if(!hasOriginalPositions && !hasReversePositions)
        {
            SignalInfo signal = CheckEMACrossover(trend_1H, trend_15M, trend_1M);
            
            if(signal.isValid)
            {
                signalCount++;
                currentSignal = signal;
                
                Print("=== NEW SIGNAL #", signalCount, " ===");
                Print("Type: ", signal.type);
                Print("Entry: ", signal.entryPrice);
                
                if(ShowSignalTable)
                    UpdateSignalTable(signal);
                
                if(ShowTPSLLines)
                    DrawTPSLLines(signal);
                
                // Execute original trades if enabled
                if(ExecuteOriginalTrades)
                {
                    ExecuteOriginalPositions(signal);
                }
                
                // Execute reverse trades if enabled
                if(ExecuteReverseTrades)
                {
                    ReverseSignal reverseSignal = ConvertToReverseSignal(signal);
                    
                    // Update RSI for immediate check
                    UpdateCurrentRSI();
                    
                    // Check RSI entry conditions
                    if(CheckRSIEntryConditions(reverseSignal.reverseType))
                    {
                        // RSI conditions are met, execute immediately
                        Print("=== RSI CONDITIONS MET IMMEDIATELY ===");
                        Print("Current RSI: ", DoubleToString(marketCondition.currentRSI, 1));
                        ExecuteReversePositions(reverseSignal);
                    }
                    else if(UseRSIEntryFilter)
                    {
                        // RSI conditions not met, add to pending queue
                        Print("=== RSI ENTRY CONDITIONS NOT MET ===");
                        Print("Signal Type: ", reverseSignal.reverseType);
                        Print("Current RSI: ", DoubleToString(marketCondition.currentRSI, 1));
                        
                        string requiredCondition = "";
                        if(reverseSignal.reverseType == "BUY")
                        {
                            requiredCondition = "RSI <= " + DoubleToString(RSI_BuyEntryLevel, 1);
                        }
                        else if(reverseSignal.reverseType == "SELL")
                        {
                            requiredCondition = "RSI >= " + DoubleToString(RSI_SellEntryLevel, 1);
                        }
                        
                        Print("Required: ", requiredCondition);
                        string monitoringMode = RSI_WaitForCandleClose ? "candle close confirmation" : "tick-based monitoring";
                        Print("Waiting for RSI conditions (", monitoringMode, ")...");
                        
                        // Store signal for later execution
                        pendingRSISignal.signal = reverseSignal;
                        pendingRSISignal.isWaiting = true;
                        pendingRSISignal.waitStartTime = TimeCurrent();
                        pendingRSISignal.barsWaited = 0;
                        pendingRSISignal.waitingFor = requiredCondition;
                    }
                    else
                    {
                        // RSI filter disabled, execute normally
                        ExecuteReversePositions(reverseSignal);
                    }
                }
                
                // Send signal to file if enabled
                if(SendSignalsToFile)
                {
                    SendSignalToFile(signal);
                }
            }
        }
        else
        {
            // If we have a pending signal and new signal comes, replace it
            if(pendingRSISignal.isWaiting)
            {
                Print("INFO: Replacing pending RSI signal with new signal");
                InitializePendingRSISignal();
            }
        }
    }
    
    // Manage original positions
    if(ExecuteOriginalTrades)
    {
        ManageOriginalPositions();
    }
    
    // Manage reverse positions with intelligent grid
    if(ExecuteReverseTrades && syncActive)
    {
        if(CloseMode == 4)
        {
            UpdateMarketAnalysis();
            ManageIntelligentGrid();
        }
        else if(CloseMode == 3)
        {
            ManageBasketAndGrid();
        }
        
        // Check swing point stop loss
        if(UseSwingPointSL && swingSLActive)
        {
            CheckSwingPointStopLoss();
        }
        
        // Check dynamic take profit
        if((UseSwingPointTP || UseRiskRewardTP) && dynamicTPActive)
        {
            CheckDynamicTakeProfit();
        }
    }
    
    // Process pending RSI signal (frequency depends on mode)
    if(ExecuteReverseTrades && UseRSIEntryFilter && UseMomentumFilter)
    {
        if(RSI_WaitForCandleClose)
        {
            // Only process on new bar formation for candle close mode
            datetime currentBarTime = iTime(_Symbol, ImpulseTimeframe, 0);
            static datetime lastRSIProcessTime = 0;
            if(currentBarTime != lastRSIProcessTime)
            {
                lastRSIProcessTime = currentBarTime;
                ProcessPendingRSISignal();
            }
        }
        else
        {
            // Process on every tick for immediate execution
            ProcessPendingRSISignal();
        }
    }
    
    if(ShowSignalTable)
        UpdateSignalTable(currentSignal);
}

//+------------------------------------------------------------------+
//| Copy indicator data                                                |
//+------------------------------------------------------------------+
bool CopyIndicatorData()
{
    if(CopyBuffer(fastEmaHandle_1M, 0, 0, 5, fastEma_1M) <= 0) return false;
    if(CopyBuffer(slowEmaHandle_1M, 0, 0, 5, slowEma_1M) <= 0) return false;
    if(CopyBuffer(fastEmaHandle_15M, 0, 0, 5, fastEma_15M) <= 0) return false;
    if(CopyBuffer(slowEmaHandle_15M, 0, 0, 5, slowEma_15M) <= 0) return false;
    if(CopyBuffer(fastEmaHandle_1H, 0, 0, 5, fastEma_1H) <= 0) return false;
    if(CopyBuffer(slowEmaHandle_1H, 0, 0, 5, slowEma_1H) <= 0) return false;
    if(CopyBuffer(volumeHandle_1M, 0, 0, 20, volume) <= 0) return false;
    return true;
}

//+------------------------------------------------------------------+
//| Analyze trend                                                      |
//+------------------------------------------------------------------+
string AnalyzeTrend(ENUM_TIMEFRAMES timeframe)
{
    double highs[], lows[], closes[];
    ArraySetAsSeries(highs, true);
    ArraySetAsSeries(lows, true);
    ArraySetAsSeries(closes, true);
    
    int bars = 50;
    if(CopyHigh(_Symbol, timeframe, 0, bars, highs) <= 0) return "NEUTRAL";
    if(CopyLow(_Symbol, timeframe, 0, bars, lows) <= 0) return "NEUTRAL";
    if(CopyClose(_Symbol, timeframe, 0, bars, closes) <= 0) return "NEUTRAL";
    
    int bullishBars = 0, bearishBars = 0;
    for(int i = 1; i < 10; i++)
    {
        if(closes[i] > closes[i+1]) bullishBars++;
        else bearishBars++;
    }
    
    double swingHighs[], swingLows[];
    ArrayResize(swingHighs, 0);
    ArrayResize(swingLows, 0);
    
    for(int i = MinBarsForSwing; i < bars - MinBarsForSwing; i++)
    {
        bool isSwingHigh = true;
        bool isSwingLow = true;
        
        for(int j = 1; j <= MinBarsForSwing; j++)
        {
            if(highs[i] <= highs[i-j] || highs[i] <= highs[i+j]) isSwingHigh = false;
            if(lows[i] >= lows[i-j] || lows[i] >= lows[i+j]) isSwingLow = false;
        }
        
        if(isSwingHigh)
        {
            int size = ArraySize(swingHighs);
            ArrayResize(swingHighs, size + 1);
            swingHighs[size] = highs[i];
        }
        if(isSwingLow)
        {
            int size = ArraySize(swingLows);
            ArrayResize(swingLows, size + 1);
            swingLows[size] = lows[i];
        }
    }
    
    int hhCount = 0, llCount = 0;
    for(int i = 1; i < ArraySize(swingHighs); i++)
        if(swingHighs[i-1] > swingHighs[i]) hhCount++;
    for(int i = 1; i < ArraySize(swingLows); i++)
        if(swingLows[i-1] > swingLows[i]) llCount++;
    
    if((bullishBars > bearishBars && hhCount >= llCount) || bullishBars >= 7)
        return "BULLISH";
    else if((bearishBars > bullishBars && llCount >= hhCount) || bearishBars >= 7)
        return "BEARISH";
    return "NEUTRAL";
}

//+------------------------------------------------------------------+
//| Check for EMA crossover signal                                     |
//+------------------------------------------------------------------+
SignalInfo CheckEMACrossover(string trend_1H, string trend_15M, string trend_1M)
{
    SignalInfo signal;
    signal.isValid = false;
    signal.trend_1H = trend_1H;
    signal.trend_15M = trend_15M;
    signal.trend_1M = trend_1M;
    signal.signalTime = TimeCurrent();
    signal.reason = "";
    
    if(TimeCurrent() - lastSignalTime < 60) return signal;
    
    if(UseVolumeFilter)
    {
        double avgVolume = 0;
        for(int i = 1; i < 20; i++) avgVolume += volume[i];
        avgVolume /= 19;
        if(volume[0] < avgVolume * 1.2) return signal; // Use fixed multiplier for signal detection
    }
    
    bool buyCross = (fastEma_1M[1] > slowEma_1M[1] && fastEma_1M[2] <= slowEma_1M[2]);
    bool sellCross = (fastEma_1M[1] < slowEma_1M[1] && fastEma_1M[2] >= slowEma_1M[2]);
    if(!buyCross && !sellCross) return signal;
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if(buyCross)
    {
        signal.type = "BUY";
        signal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        bool trendOK = !UseTrendFilter || AllowCounterTrend || trend_1M == "BULLISH" || trend_1M == "NEUTRAL" || (trend_15M == "BULLISH" && trend_1M == "NEUTRAL");
        if(!trendOK) return signal;
        
        if(UseSwingTPSL)
        {
            double swingHigh = GetSwingHigh(TF_15M);
            double swingLow = GetSwingLow(TF_1M);
            double distance = swingHigh - signal.entryPrice;
            if(swingHigh > 0 && swingLow < DBL_MAX && distance > 0)
            {
                signal.tp1 = signal.entryPrice + (distance * TP1_Multiplier);
                signal.tp2 = signal.entryPrice + (distance * TP2_Multiplier);
                signal.tp3 = signal.entryPrice + (distance * TP3_Multiplier);
                signal.sl = swingLow;
            }
            else
            {
                signal.tp1 = signal.entryPrice + (TP1_Points * point);
                signal.tp2 = signal.entryPrice + (TP2_Points * point);
                signal.tp3 = signal.entryPrice + (TP3_Points * point);
                signal.sl = signal.entryPrice - (SL_Points * point);
            }
        }
        else
        {
            signal.tp1 = signal.entryPrice + (TP1_Points * point);
            signal.tp2 = signal.entryPrice + (TP2_Points * point);
            signal.tp3 = signal.entryPrice + (TP3_Points * point);
            signal.sl = signal.entryPrice - (SL_Points * point);
        }
        signal.isValid = true;
        lastSignalTime = TimeCurrent();
    }
    else if(sellCross)
    {
        signal.type = "SELL";
        signal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        bool trendOK = !UseTrendFilter || AllowCounterTrend || trend_1M == "BEARISH" || trend_1M == "NEUTRAL" || (trend_15M == "BEARISH" && trend_1M == "NEUTRAL");
        if(!trendOK) return signal;
        
        if(UseSwingTPSL)
        {
            double swingLow = GetSwingLow(TF_15M);
            double swingHigh = GetSwingHigh(TF_1M);
            double distance = signal.entryPrice - swingLow;
            if(swingLow < DBL_MAX && swingHigh > 0 && distance > 0)
            {
                signal.tp1 = signal.entryPrice - (distance * TP1_Multiplier);
                signal.tp2 = signal.entryPrice - (distance * TP2_Multiplier);
                signal.tp3 = signal.entryPrice - (distance * TP3_Multiplier);
                signal.sl = swingHigh;
            }
            else
            {
                signal.tp1 = signal.entryPrice - (TP1_Points * point);
                signal.tp2 = signal.entryPrice - (TP2_Points * point);
                signal.tp3 = signal.entryPrice - (TP3_Points * point);
                signal.sl = signal.entryPrice + (SL_Points * point);
            }
        }
        else
        {
            signal.tp1 = signal.entryPrice - (TP1_Points * point);
            signal.tp2 = signal.entryPrice - (TP2_Points * point);
            signal.tp3 = signal.entryPrice - (TP3_Points * point);
            signal.sl = signal.entryPrice + (SL_Points * point);
        }
        signal.isValid = true;
        lastSignalTime = TimeCurrent();
    }
    return signal;
}

//+------------------------------------------------------------------+
//| Get swing high                                                     |
//+------------------------------------------------------------------+
double GetSwingHigh(ENUM_TIMEFRAMES timeframe)
{
    double highs[];
    ArraySetAsSeries(highs, true);
    if(CopyHigh(_Symbol, timeframe, 0, 50, highs) <= 0) return 0;
    for(int i = MinBarsForSwing; i < 50 - MinBarsForSwing; i++)
    {
        bool isSwing = true;
        for(int j = 1; j <= MinBarsForSwing; j++)
            if(highs[i] <= highs[i-j] || highs[i] <= highs[i+j]) { isSwing = false; break; }
        if(isSwing) return highs[i];
    }
    return 0;
}

//+------------------------------------------------------------------+
//| Get swing low                                                      |
//+------------------------------------------------------------------+
double GetSwingLow(ENUM_TIMEFRAMES timeframe)
{
    double lows[];
    ArraySetAsSeries(lows, true);
    if(CopyLow(_Symbol, timeframe, 0, 50, lows) <= 0) return DBL_MAX;
    for(int i = MinBarsForSwing; i < 50 - MinBarsForSwing; i++)
    {
        bool isSwing = true;
        for(int j = 1; j <= MinBarsForSwing; j++)
            if(lows[i] >= lows[i-j] || lows[i] >= lows[i+j]) { isSwing = false; break; }
        if(isSwing) return lows[i];
    }
    return DBL_MAX;
}

//+------------------------------------------------------------------+
//| Convert signal to reverse signal                                   |
//+------------------------------------------------------------------+
ReverseSignal ConvertToReverseSignal(SignalInfo &signal)
{
    ReverseSignal reverseSignal;
    reverseSignal.originalType = signal.type;
    reverseSignal.signalTime = signal.signalTime;
    
    if(signal.type == "BUY")
    {
        reverseSignal.reverseType = "SELL";
        reverseSignal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    }
    else
    {
        reverseSignal.reverseType = "BUY";
        reverseSignal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    }
    
    reverseSignal.senderSL = signal.sl;      // Our TP
    reverseSignal.senderTP1 = signal.tp1;   // Our SL1 / Zone 1 boundary
    reverseSignal.senderTP2 = signal.tp2;   // Our SL2 / Zone 2 boundary
    reverseSignal.senderTP3 = signal.tp3;   // Our SL3 / Zone 3 boundary (final)
    reverseSignal.isValid = true;
    
    return reverseSignal;
}

//+------------------------------------------------------------------+
//| Count open positions                                               |
//+------------------------------------------------------------------+
int CountOpenPositions(bool isOriginal = true)
{
    int count = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
            string comment = PositionGetString(POSITION_COMMENT);
            if(isOriginal)
            {
                // Original positions have comments like "Pos1-TP1", "Pos2-TP2", "Pos3-TP3"
                if(StringFind(comment, "Pos") >= 0 && StringFind(comment, "TP") >= 0)
                    count++;
            }
            else
            {
                // Reverse positions have comments like "Reverse", "Grid", "SmartGrid"
                if(StringFind(comment, "Reverse") >= 0 || StringFind(comment, "Grid") >= 0 || StringFind(comment, "SmartGrid") >= 0)
                    count++;
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Execute original positions (from sender logic)                     |
//+------------------------------------------------------------------+
void ExecuteOriginalPositions(SignalInfo &signal)
{
    double lot = LotSize;
    if(LotSizeMode != 0) // Not fixed lot mode
    {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = balance * RiskPercent / 100;
        double slDistance = MathAbs(signal.entryPrice - signal.sl) / _Point;
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        if(slDistance > 0 && tickValue > 0)
        {
            lot = riskAmount / (slDistance * tickValue * 3);
            lot = NormalizeDouble(lot, 2);
            double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
            if(lot < minLot) lot = minLot;
            if(lot > maxLot) lot = maxLot;
        }
    }
    
    ResetOriginalGroup();
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot;
    request.deviation = Slippage;
    request.magic = MagicNumber;
    request.sl = signal.sl;
    request.tp = 0;
    request.type_filling = currentFillingMode;
    
    if(signal.type == "BUY") { request.type = ORDER_TYPE_BUY; request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK); }
    else { request.type = ORDER_TYPE_SELL; request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID); }
    
    request.comment = "Pos1-TP1";
    if(OrderSend(request, result) && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
        originalGroup.ticket1 = result.order;
    
    Sleep(100);
    request.comment = "Pos2-TP2";
    if(OrderSend(request, result) && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
        originalGroup.ticket2 = result.order;
    
    Sleep(100);
    request.comment = "Pos3-TP3";
    if(OrderSend(request, result) && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
        originalGroup.ticket3 = result.order;
    
    if(originalGroup.ticket1 > 0 && originalGroup.ticket2 > 0 && originalGroup.ticket3 > 0)
    {
        originalGroup.type = signal.type;
        originalGroup.openTime = TimeCurrent();
        originalGroup.tp1Price = signal.tp1;
        originalGroup.tp2Price = signal.tp2;
        originalGroup.tp3Price = signal.tp3;
        originalGroup.slPrice = signal.sl;
        originalGroup.tp1Reached = false;
        originalGroup.tp2Reached = false;
        tradeCount++;
        Print("=== ORIGINAL TRADE GROUP #", tradeCount, " OPENED ===");
        DrawSignalArrow(signal);
    }
    else
    {
        if(originalGroup.ticket1 > 0) ClosePosition(originalGroup.ticket1);
        if(originalGroup.ticket2 > 0) ClosePosition(originalGroup.ticket2);
        if(originalGroup.ticket3 > 0) ClosePosition(originalGroup.ticket3);
        ResetOriginalGroup();
    }
}

//+------------------------------------------------------------------+
//| Execute reverse positions                                          |
//+------------------------------------------------------------------+
void ExecuteReversePositions(ReverseSignal &signal)
{
    double lot = CalculateLotSize();
    initialLotSize = lot;
    
    ResetReverseGroup();
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot;
    request.deviation = Slippage;
    request.magic = MagicNumber;
    request.sl = 0;
    request.tp = 0;
    request.type_filling = currentFillingMode;
    
    if(signal.reverseType == "BUY")
    {
        request.type = ORDER_TYPE_BUY;
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    }
    else
    {
        request.type = ORDER_TYPE_SELL;
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    }
    
    request.comment = "Reverse1";
    if(OrderSend(request, result) && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
        reverseGroup.ticket1 = result.order;
    
    Sleep(100);
    request.comment = "Reverse2";
    if(OrderSend(request, result) && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
        reverseGroup.ticket2 = result.order;
    
    Sleep(100);
    request.comment = "Reverse3";
    if(OrderSend(request, result) && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
        reverseGroup.ticket3 = result.order;
    
    if(reverseGroup.ticket1 > 0 && reverseGroup.ticket2 > 0 && reverseGroup.ticket3 > 0)
    {
        reverseGroup.type = signal.reverseType;
        reverseGroup.openTime = TimeCurrent();
        
        // Get the ACTUAL fill price from the opened position (not the stale signal price)
        // This is critical when RSI entry filter delays execution - signal.entryPrice may be
        // very different from where the trade actually filled
        double actualEntryPrice = signal.entryPrice; // fallback
        if(PositionSelectByTicket(reverseGroup.ticket1))
        {
            actualEntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            Print("Actual fill price: ", DoubleToString(actualEntryPrice, _Digits), 
                  " (Signal price was: ", DoubleToString(signal.entryPrice, _Digits), ")");
        }
        
        reverseGroup.entryPrice = signal.entryPrice;  // Keep signal price for zone/grid calculations
        reverseGroup.targetTP = signal.senderSL;
        reverseGroup.zone1Boundary = signal.senderTP1;
        reverseGroup.zone2Boundary = signal.senderTP2;
        reverseGroup.zone3Boundary = signal.senderTP3;
        
        // Calculate basket profit target
        basketProfitTarget = CalculateBasketProfitTarget(signal.entryPrice, signal.senderSL, lot, signal.reverseType);
        
        // Calculate custom basket target if enabled
        if(UseCustomBasketProfit)
        {
            if(UseCustomBasketPercent)
            {
                double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
                customBasketTarget = currentBalance * CustomBasketProfitPercent / 100.0;
            }
            else
            {
                customBasketTarget = CustomBasketProfitAmount;
            }
            Print("Custom Basket Target: $", DoubleToString(customBasketTarget, 2));
        }
        
        // Calculate grid levels for all zones
        CalculateAllZoneGridLevels(signal.entryPrice, signal.senderTP1, signal.senderTP2, signal.senderTP3, signal.reverseType);
        
        // Calculate swing point stop loss using ACTUAL FILL PRICE (not signal price)
        if(UseSwingPointSL)
        {
            double swingSL = FindSwingPointForSL(actualEntryPrice, signal.reverseType);
            if(swingSL > 0)
            {
                currentSwingRawPrice = swingSL;
                double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
                
                // Apply buffer beyond the swing point
                if(signal.reverseType == "BUY")
                    currentSwingSLPrice = swingSL - (SwingSLBufferPoints * point);
                else
                    currentSwingSLPrice = swingSL + (SwingSLBufferPoints * point);
                
                swingSLActive = true;
                lastSwingSLCheckTime = 0;
                
                Print("=== SWING POINT STOP LOSS SET ===");
                Print("Trade Type: ", signal.reverseType);
                Print("Actual Entry: ", DoubleToString(actualEntryPrice, _Digits));
                Print("Swing Point: ", DoubleToString(currentSwingRawPrice, _Digits));
                Print("Buffer: ", DoubleToString(SwingSLBufferPoints, 0), " points");
                Print("SL Price: ", DoubleToString(currentSwingSLPrice, _Digits));
                Print("Mode: ", (UseSwingBodyBreakClose ? "Body Break Close" : "Price Level Stop"));
                
                // === RECALCULATE GRID ZONES: Entry ↔ Swing SL ===
                // Divide the distance between actual entry and swing SL into 3 equal zones
                // This replaces the sender's TP-based zones with swing-based zones
                double totalDistance = MathAbs(actualEntryPrice - currentSwingSLPrice);
                double zone1Size = totalDistance * 0.33;  // Zone 1: closest to entry (33%)
                double zone2Size = totalDistance * 0.33;  // Zone 2: middle (33%)
                // Zone 3: remaining distance to SL (34%)
                
                double newZone1End, newZone2End, newZone3End;
                
                if(signal.reverseType == "BUY")
                {
                    // BUY: zones go downward from entry toward SL
                    newZone1End = actualEntryPrice - zone1Size;
                    newZone2End = newZone1End - zone2Size;
                    newZone3End = currentSwingSLPrice;  // Zone 3 ends at swing SL
                }
                else
                {
                    // SELL: zones go upward from entry toward SL
                    newZone1End = actualEntryPrice + zone1Size;
                    newZone2End = newZone1End + zone2Size;
                    newZone3End = currentSwingSLPrice;  // Zone 3 ends at swing SL
                }
                
                // Update reverseGroup with actual entry and new zone boundaries
                reverseGroup.entryPrice = actualEntryPrice;
                reverseGroup.zone1Boundary = newZone1End;
                reverseGroup.zone2Boundary = newZone2End;
                reverseGroup.zone3Boundary = newZone3End;
                
                // Recalculate grid levels using the new swing-based zones
                CalculateAllZoneGridLevels(actualEntryPrice, newZone1End, newZone2End, newZone3End, signal.reverseType);
                
                Print("=== SWING-BASED GRID ZONES ===");
                Print("Total distance (Entry to SL): ", DoubleToString(totalDistance / point, 0), " points");
                Print("Zone 1: Entry(", DoubleToString(actualEntryPrice, _Digits), ") to (", DoubleToString(newZone1End, _Digits), ") = ", DoubleToString(zone1Size / point, 0), " pts");
                Print("Zone 2: (", DoubleToString(newZone1End, _Digits), ") to (", DoubleToString(newZone2End, _Digits), ") = ", DoubleToString(zone2Size / point, 0), " pts");
                Print("Zone 3: (", DoubleToString(newZone2End, _Digits), ") to SL(", DoubleToString(newZone3End, _Digits), ") = ", DoubleToString(MathAbs(newZone3End - newZone2End) / point, 0), " pts");
                
                // Draw swing SL line on chart
                if(ShowSwingSLLine)
                {
                    DrawSwingSLLine();
                }
            }
            else
            {
                Print("WARNING: No valid swing point found for SL, swing SL not set");
                swingSLActive = false;
            }
        }
        
        // Calculate dynamic take profit
        if(UseSwingPointTP || UseRiskRewardTP)
        {
            bool tpSet = false;
            
            // 1. Try Swing Point TP first
            if(UseSwingPointTP)
            {
                double swingTP = FindSwingPointForTP(actualEntryPrice, signal.reverseType);
                if(swingTP > 0)
                {
                    currentDynamicTPPrice = swingTP;
                    currentDynamicRawTPPrice = swingTP;
                    activeTPMode = "Swing";
                    dynamicTPActive = true;
                    tpSet = true;
                }
                else
                {
                    Print("WARNING: No valid swing point found for TP.");
                }
            }
            
            // 2. Fallback or use Risk/Reward TP
            if(!tpSet && UseRiskRewardTP)
            {
                if(swingSLActive && currentSwingSLPrice > 0)
                {
                    double slDistance = MathAbs(actualEntryPrice - currentSwingSLPrice);
                    double tpDistance = slDistance * RiskRewardRatio;
                    
                    if(signal.reverseType == "BUY")
                        currentDynamicTPPrice = actualEntryPrice + tpDistance;
                    else
                        currentDynamicTPPrice = actualEntryPrice - tpDistance;
                        
                    currentDynamicRawTPPrice = currentDynamicTPPrice;
                    activeTPMode = "Risk/Reward";
                    dynamicTPActive = true;
                    tpSet = true;
                }
                else
                {
                    Print("WARNING: RR TP requires an active Stop Loss (Swing SL not found/active). RR TP not set.");
                }
            }
            
            if(tpSet)
            {
                Print("=== DYNAMIC TAKE PROFIT SET ===");
                Print("Mode: ", activeTPMode);
                Print("TP Price: ", DoubleToString(currentDynamicTPPrice, _Digits));
                
                if(ShowDynamicTPLine)
                {
                    DrawDynamicTPLine();
                }
            }
            else
            {
                dynamicTPActive = false;
            }
        }
        
        syncActive = true; // Enable reverse position management
        tradeCount++;
        Print("=== REVERSE TRADE GROUP #", tradeCount, " OPENED ===");
        Print("Basket Target: $", DoubleToString(basketProfitTarget, 2));
        
        lastReverseSignal = signal;
    }
    else
    {
        if(reverseGroup.ticket1 > 0) ClosePosition(reverseGroup.ticket1);
        if(reverseGroup.ticket2 > 0) ClosePosition(reverseGroup.ticket2);
        if(reverseGroup.ticket3 > 0) ClosePosition(reverseGroup.ticket3);
        ResetReverseGroup();
    }
}
//+------------------------------------------------------------------+
//| Manage original positions (from sender logic)                     |
//+------------------------------------------------------------------+
void ManageOriginalPositions()
{
    if(originalGroup.ticket1 == 0 && originalGroup.ticket2 == 0 && originalGroup.ticket3 == 0) return;
    
    bool pos1Exists = PositionSelectByTicket(originalGroup.ticket1);
    bool pos2Exists = PositionSelectByTicket(originalGroup.ticket2);
    bool pos3Exists = PositionSelectByTicket(originalGroup.ticket3);
    
    if(!pos1Exists && !pos2Exists && !pos3Exists) 
    { 
        Print("INFO: All original positions closed."); 
        ResetOriginalGroup(); 
        return; 
    }
    
    double currentPrice = (originalGroup.type == "BUY") ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    if(!originalGroup.tp1Reached)
    {
        bool tp1Hit = (originalGroup.type == "BUY" && currentPrice >= originalGroup.tp1Price) || 
                      (originalGroup.type == "SELL" && currentPrice <= originalGroup.tp1Price);
        if(tp1Hit)
        {
            Print("=== ORIGINAL TP1 REACHED ===");
            originalGroup.tp1Reached = true;
            if(pos1Exists) ClosePosition(originalGroup.ticket1);
            double bePrice = 0;
            if(pos2Exists && PositionSelectByTicket(originalGroup.ticket2))
            {
                bePrice = PositionGetDouble(POSITION_PRICE_OPEN) + ((originalGroup.type == "BUY") ? (10 * _Point) : (-10 * _Point));
                ModifyStopLoss(originalGroup.ticket2, bePrice);
            }
            if(pos3Exists && PositionSelectByTicket(originalGroup.ticket3))
            {
                bePrice = PositionGetDouble(POSITION_PRICE_OPEN) + ((originalGroup.type == "BUY") ? (10 * _Point) : (-10 * _Point));
                ModifyStopLoss(originalGroup.ticket3, bePrice);
            }
        }
    }
    
    if(originalGroup.tp1Reached && !originalGroup.tp2Reached)
    {
        bool tp2Hit = (originalGroup.type == "BUY" && currentPrice >= originalGroup.tp2Price) || 
                      (originalGroup.type == "SELL" && currentPrice <= originalGroup.tp2Price);
        if(tp2Hit)
        {
            Print("=== ORIGINAL TP2 REACHED ===");
            originalGroup.tp2Reached = true;
            if(pos2Exists) ClosePosition(originalGroup.ticket2);
            if(pos3Exists) ModifyStopLoss(originalGroup.ticket3, originalGroup.tp1Price);
        }
    }
    
    if(originalGroup.tp2Reached && pos3Exists)
    {
        bool tp3Hit = (originalGroup.type == "BUY" && currentPrice >= originalGroup.tp3Price) || 
                      (originalGroup.type == "SELL" && currentPrice <= originalGroup.tp3Price);
        if(tp3Hit) 
        { 
            Print("=== ORIGINAL TP3 REACHED ==="); 
            ClosePosition(originalGroup.ticket3);
        }
    }
}

//+------------------------------------------------------------------+
//| Manage basket and grid (Mode 3)                                   |
//+------------------------------------------------------------------+
void ManageBasketAndGrid()
{
    double currentPL = GetCurrentBasketPL();
    
    // Check if basket profit target reached
    if(currentPL >= basketProfitTarget && basketProfitTarget > 0)
    {
        Print("=== BASKET PROFIT TARGET REACHED ===");
        Print("Target: $", DoubleToString(basketProfitTarget, 2), " | Current: $", DoubleToString(currentPL, 2));
        CloseAllPositionsAndGrid("Basket profit target reached");
        return;
    }
    
    double currentPrice = (reverseGroup.type == "BUY") ? 
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Simple grid addition logic for Mode 3
    if(ShouldAddBasicGrid(currentPrice))
    {
        AddBasicGridLayer(currentPrice);
    }
}

//+------------------------------------------------------------------+
//| Manage intelligent grid (Mode 4)                                  |
//+------------------------------------------------------------------+
void ManageIntelligentGrid()
{
    double currentPL = GetCurrentBasketPL();
    
    // Determine which profit target to use
    double activeTarget = basketProfitTarget;
    string targetType = "Standard Basket";
    
    if(UseCustomBasketProfit && customBasketTarget > 0)
    {
        activeTarget = customBasketTarget;
        targetType = "Custom Basket";
    }
    
    // Check if basket profit target reached
    if(currentPL >= activeTarget && activeTarget > 0)
    {
        Print("=== ", targetType, " PROFIT TARGET REACHED ===");
        Print("Target: $", DoubleToString(activeTarget, 2), " | Current: $", DoubleToString(currentPL, 2));
        
        // Send Telegram notification
        if(EnableTelegramNotifications && NotifyOnProfit)
        {
            string content = targetType + " PROFIT TARGET REACHED!\n";
            content += "Current P/L: $" + DoubleToString(currentPL, 2) + "\n";
            content += "Target: $" + DoubleToString(activeTarget, 2) + "\n";
            content += "All positions closed";
            
            SendTelegramMessage(FormatTelegramMessage("PROFIT TARGET HIT", content));
        }
        
        CloseAllPositionsAndGrid(targetType + " profit target reached");
        return;
    }
    
    double currentPrice = (reverseGroup.type == "BUY") ? 
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Update RSI for current tick before grid decision
    if(UseMomentumFilter)
        UpdateCurrentRSI();
    
    // Intelligent grid addition logic
    if(ShouldAddIntelligentGrid(currentPrice))
    {
        AddIntelligentGridLayer(currentPrice);
    }
}

//+------------------------------------------------------------------+
//| Update market analysis for intelligent grid                       |
//+------------------------------------------------------------------+
void UpdateMarketAnalysis()
{
    datetime currentBarTime = iTime(_Symbol, ImpulseTimeframe, 0);
    static datetime lastAnalysisBarTime = 0;
    if(currentBarTime == lastAnalysisBarTime)
        return;
    lastAnalysisBarTime = currentBarTime;
    
    // Update ATR and volatility analysis
    UpdateVolatilityAnalysis();
    
    // Update momentum analysis
    if(UseMomentumFilter)
        UpdateMomentumAnalysis();
    
    // Update volume analysis
    if(UseVolumeConfirmation)
        UpdateVolumeAnalysis();
    
    // Update impulse detection
    UpdateImpulseDetection();
    
    // Determine market phase
    DetermineMarketPhase();
    
    // Calculate adaptive grid spacing
    if(UseAdaptiveSpacing)
        CalculateAdaptiveSpacing();
}

//+------------------------------------------------------------------+
//| Update volatility analysis                                         |
//+------------------------------------------------------------------+
void UpdateVolatilityAnalysis()
{
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, true);
    if(CopyBuffer(atrHandle, 0, 0, VolatilityPeriod + 5, atrBuffer) <= 0)
        return;
    
    impulseState.lastATR = atrBuffer[1];
    
    // Calculate average ATR for volatility comparison
    double atrSum = 0;
    for(int i = 1; i <= VolatilityPeriod; i++)
    {
        atrSum += atrBuffer[i];
    }
    impulseState.avgVolatility = atrSum / VolatilityPeriod;
    
    // Calculate current volatility ratio
    impulseState.currentVolatility = impulseState.lastATR / impulseState.avgVolatility;
    
    // Determine volatility state
    impulseState.isHighVolatility = (impulseState.currentVolatility > HighVolThreshold);
    impulseState.isLowVolatility = (impulseState.currentVolatility < LowVolThreshold);
}

//+------------------------------------------------------------------+
//| Update momentum analysis                                           |
//+------------------------------------------------------------------+
void UpdateMomentumAnalysis()
{
    double rsiBuffer[];
    ArraySetAsSeries(rsiBuffer, true);
    if(CopyBuffer(rsiHandle, 0, 0, 3, rsiBuffer) <= 0)
        return;
    
    marketCondition.currentRSI = rsiBuffer[1];
    marketCondition.isOverbought = (marketCondition.currentRSI > RSI_OverboughtLevel);
    marketCondition.isOversold = (marketCondition.currentRSI < RSI_OversoldLevel);
    
    // Determine if momentum is strong (RSI moving away from 50)
    double rsiDistance = MathAbs(marketCondition.currentRSI - 50);
    marketCondition.isMomentumStrong = (rsiDistance > 25);
}

//+------------------------------------------------------------------+
//| Update volume analysis                                             |
//+------------------------------------------------------------------+
void UpdateVolumeAnalysis()
{
    double volumeBuffer[];
    ArraySetAsSeries(volumeBuffer, true);
    if(CopyBuffer(volumeHandle_1M, 0, 0, 22, volumeBuffer) <= 0) // Copy 22 elements to access index 21
        return;
    
    marketCondition.currentVolume = volumeBuffer[1];
    
    // Calculate average volume
    double volumeSum = 0;
    for(int i = 2; i <= 21; i++)
    {
        volumeSum += volumeBuffer[i];
    }
    marketCondition.avgVolume = volumeSum / 20;
    
    // Check for volume spike
    marketCondition.hasVolumeSpike = (marketCondition.currentVolume > marketCondition.avgVolume * VolumeMultiplier);
}

//+------------------------------------------------------------------+
//| Update impulse detection                                           |
//+------------------------------------------------------------------+
void UpdateImpulseDetection()
{
    // Get recent candles
    double high[], low[], open[], close[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(close, true);
    
    if(CopyHigh(_Symbol, ImpulseTimeframe, 0, ImpulseLookback + 2, high) <= 0) return;
    if(CopyLow(_Symbol, ImpulseTimeframe, 0, ImpulseLookback + 2, low) <= 0) return;
    if(CopyOpen(_Symbol, ImpulseTimeframe, 0, ImpulseLookback + 2, open) <= 0) return;
    if(CopyClose(_Symbol, ImpulseTimeframe, 0, ImpulseLookback + 2, close) <= 0) return;
    
    bool impulseDetected = false;
    double impulseDir = 0;
    
    // Enhanced impulse detection
    for(int i = 1; i <= ImpulseLookback; i++)
    {
        double candleSize = MathAbs(close[i] - open[i]);
        
        // Primary: Large candle body vs ATR
        bool largeCandle = (candleSize > impulseState.lastATR * ImpulseATRMultiplier);
        
        // Secondary: High volatility confirmation
        bool highVolConfirm = impulseState.isHighVolatility;
        
        if(largeCandle && highVolConfirm)
        {
            impulseDetected = true;
            impulseDir = (close[i] > open[i]) ? 1 : -1;
            break;
        }
    }
    
    // Update impulse state
    if(impulseDetected)
    {
        if(!impulseState.isInImpulse)
        {
            impulseState.isInImpulse = true;
            impulseState.impulseStartTime = TimeCurrent();
            impulseState.impulseDirection = impulseDir;
            impulseState.barsSinceImpulse = 0;
            if(ShowDebugInfo)
                Print("=== IMPULSE DETECTED === Direction: ", (impulseDir > 0 ? "BULLISH" : "BEARISH"));
        }
    }
    else
    {
        if(impulseState.isInImpulse)
        {
            // Check for impulse end
            double lastCandleSize = MathAbs(close[1] - open[1]);
            bool isExhaustion = (lastCandleSize < impulseState.lastATR * 0.4) || impulseState.isLowVolatility;
            
            if(isExhaustion)
            {
                impulseState.isInImpulse = false;
                impulseState.impulseEndTime = TimeCurrent();
                impulseState.barsSinceImpulse = 0;
                if(ShowDebugInfo)
                    Print("=== IMPULSE ENDED ===");
            }
        }
        else
        {
            impulseState.barsSinceImpulse++;
        }
    }
}

//+------------------------------------------------------------------+
//| Determine current market phase                                     |
//+------------------------------------------------------------------+
void DetermineMarketPhase()
{
    if(impulseState.isHighVolatility && impulseState.isInImpulse)
    {
        marketCondition.marketPhase = "VOLATILE";
    }
    else if(marketCondition.isMomentumStrong && !impulseState.isLowVolatility)
    {
        marketCondition.marketPhase = "TRENDING";
    }
    else
    {
        marketCondition.marketPhase = "RANGING";
    }
}

//+------------------------------------------------------------------+
//| Calculate adaptive grid spacing                                    |
//+------------------------------------------------------------------+
void CalculateAdaptiveSpacing()
{
    if(baseSpacing == 0)
    {
        // Initialize base spacing from original zone calculations
        double zone1Distance = MathAbs(reverseGroup.zone1Boundary - reverseGroup.entryPrice);
        baseSpacing = zone1Distance / (GridLayersZone1 + 1);
    }
    
    double spacingMultiplier = 1.0;
    
    // Adjust based on volatility
    if(impulseState.isHighVolatility)
    {
        spacingMultiplier *= VolatilityMultiplier;
    }
    else if(impulseState.isLowVolatility)
    {
        spacingMultiplier *= 0.8; // Tighter spacing in low volatility
    }
    
    // Adjust based on market phase
    if(marketCondition.marketPhase == "VOLATILE")
    {
        spacingMultiplier *= 1.5; // Much wider spacing during volatile periods
    }
    else if(marketCondition.marketPhase == "RANGING")
    {
        spacingMultiplier *= 0.9; // Slightly tighter in ranging markets
    }
    
    adaptiveSpacing = baseSpacing * spacingMultiplier;
}

//+------------------------------------------------------------------+
//| Should add intelligent grid                                        |
//+------------------------------------------------------------------+
bool ShouldAddIntelligentGrid(double currentPrice)
{
    // CRITICAL: Only add grid when trade is in DRAWDOWN (not in profit)
    int currentZone = GetCurrentPriceZone(currentPrice);
    if(currentZone == 0)
    {
        if(ShowDebugInfo)
            Print("GRID BLOCKED: Trade is in PROFIT (Zone 0) - Grid only added in drawdown");
        return false;
    }
    
    // Check if current basket P/L is positive (additional safety check)
    double currentPL = GetCurrentBasketPL();
    if(currentPL > 0)
    {
        if(ShowDebugInfo)
            Print("GRID BLOCKED: Basket P/L is positive ($", DoubleToString(currentPL, 2), ") - Grid only added in drawdown");
        return false;
    }
    
    // Primary safety check: No impulse active
    if(impulseState.isInImpulse)
    {
        if(ShowDebugInfo)
            Print("GRID BLOCKED: Impulse active (", marketCondition.marketPhase, ")");
        return false;
    }
    
    // Check if indicators are ready
    if(impulseState.lastATR <= 0)
    {
        if(ShowDebugInfo)
            Print("GRID BLOCKED: ATR not ready");
        return false;
    }
    
    // Enhanced cooldown based on market conditions
    int requiredCooldown = CooldownBars;
    if(marketCondition.marketPhase == "VOLATILE")
        requiredCooldown *= 2; // Double cooldown in volatile markets
    else if(marketCondition.marketPhase == "TRENDING")
        requiredCooldown = (int)(requiredCooldown * 1.5); // 50% more in trending
    
    if(impulseState.barsSinceImpulse < requiredCooldown)
    {
        if(ShowDebugInfo)
            Print("GRID BLOCKED: Cooldown active (", impulseState.barsSinceImpulse, "/", requiredCooldown, ")");
        return false;
    }
    
    // Time-based throttling: Prevent rapid-fire additions
    if(TimeCurrent() - lastGridAddTime < 60) // Minimum 1 minute between additions
    {
        if(ShowDebugInfo)
            Print("GRID BLOCKED: Time throttle active");
        return false;
    }
    
    // Enhanced momentum filter: Check RSI conditions for grid addition
    if(UseMomentumFilter)
    {
        // For BUY positions: Don't add grid when RSI is oversold (market might reverse)
        // For SELL positions: Don't add grid when RSI is overbought (market might reverse)
        if(reverseGroup.type == "BUY" && marketCondition.isOversold)
        {
            if(ShowDebugInfo)
                Print("GRID BLOCKED: RSI oversold (", DoubleToString(marketCondition.currentRSI, 1), ") - potential reversal for BUY");
            return false;
        }
        else if(reverseGroup.type == "SELL" && marketCondition.isOverbought)
        {
            if(ShowDebugInfo)
                Print("GRID BLOCKED: RSI overbought (", DoubleToString(marketCondition.currentRSI, 1), ") - potential reversal for SELL");
            return false;
        }
    }
    
    // Enhanced volume filter: Don't add during high volume spikes against our position
    if(UseVolumeConfirmation && marketCondition.hasVolumeSpike)
    {
        // Check if volume spike is going against our position
        double currentCandle = iClose(_Symbol, ImpulseTimeframe, 1) - iOpen(_Symbol, ImpulseTimeframe, 1);
        bool volumeAgainstPosition = false;
        
        if(reverseGroup.type == "BUY" && currentCandle < 0) // Bearish candle against BUY
            volumeAgainstPosition = true;
        else if(reverseGroup.type == "SELL" && currentCandle > 0) // Bullish candle against SELL
            volumeAgainstPosition = true;
            
        if(volumeAgainstPosition)
        {
            if(ShowDebugInfo)
                Print("GRID BLOCKED: High volume spike against position direction");
            return false;
        }
    }
    
    // Adaptive distance check using dynamic spacing
    double distanceFromLastGrid = GetDistanceFromLastGrid(currentPrice);
    double requiredDistance = UseAdaptiveSpacing ? adaptiveSpacing : baseSpacing;
    
    if(requiredDistance <= 0)
    {
        // Fallback to basic spacing if adaptive spacing not ready
        requiredDistance = MathAbs(reverseGroup.zone1Boundary - reverseGroup.entryPrice) / (GridLayersZone1 + 1);
    }
    
    if(distanceFromLastGrid < requiredDistance)
    {
        return false; // Not far enough yet
    }
    
    // All checks passed - safe to add grid in drawdown
    if(ShowDebugInfo)
        Print("GRID APPROVED: Zone ", currentZone, " | P/L: $", DoubleToString(currentPL, 2), " | RSI: ", DoubleToString(marketCondition.currentRSI, 1));
    
    return true;
}

//+------------------------------------------------------------------+
//| Should add basic grid (Mode 3)                                    |
//+------------------------------------------------------------------+
bool ShouldAddBasicGrid(double currentPrice)
{
    // CRITICAL: Only add grid when trade is in DRAWDOWN (not in profit)
    int currentZone = GetCurrentPriceZone(currentPrice);
    if(currentZone == 0)
    {
        if(ShowDebugInfo)
            Print("BASIC GRID BLOCKED: Trade is in PROFIT (Zone 0) - Grid only added in drawdown");
        return false;
    }
    
    // Check if current basket P/L is positive (additional safety check)
    double currentPL = GetCurrentBasketPL();
    if(currentPL > 0)
    {
        if(ShowDebugInfo)
            Print("BASIC GRID BLOCKED: Basket P/L is positive ($", DoubleToString(currentPL, 2), ") - Grid only added in drawdown");
        return false;
    }
    
    // Simple distance-based check for Mode 3
    double distanceFromLastGrid = GetDistanceFromLastGrid(currentPrice);
    double requiredDistance = MathAbs(reverseGroup.zone1Boundary - reverseGroup.entryPrice) / (GridLayersZone1 + 1);
    
    bool distanceOK = (distanceFromLastGrid >= requiredDistance);
    
    if(ShowDebugInfo && distanceOK)
        Print("BASIC GRID APPROVED: Zone ", currentZone, " | P/L: $", DoubleToString(currentPL, 2));
    
    return distanceOK;
}

//+------------------------------------------------------------------+
//| Get distance from last grid position                              |
//+------------------------------------------------------------------+
double GetDistanceFromLastGrid(double currentPrice)
{
    double lastGridPrice = reverseGroup.entryPrice; // Start with entry price
    
    // Find the most recent grid position price
    for(int i = ArraySize(gridLayers) - 1; i >= 0; i--)
    {
        if(gridLayers[i].isActive)
        {
            lastGridPrice = gridLayers[i].entryPrice;
            break;
        }
    }
    
    return MathAbs(currentPrice - lastGridPrice);
}

//+------------------------------------------------------------------+
//| Add intelligent grid layer                                         |
//+------------------------------------------------------------------+
void AddIntelligentGridLayer(double currentPrice)
{
    // Determine which zone we're in and if we can add
    int priceZone = GetCurrentPriceZone(currentPrice);
    int layerInZone = 0;
    
    // Calculate which layer in the current zone
    if(priceZone == 1 && zone1Triggered < GridLayersZone1)
    {
        layerInZone = zone1Triggered;
    }
    else if(priceZone == 2 && zone2Triggered < GridLayersZone2)
    {
        layerInZone = zone2Triggered;
    }
    else if(priceZone == 3 && zone3Triggered < GridLayersZone3)
    {
        layerInZone = zone3Triggered;
    }
    else
    {
        return; // No more layers available in this zone
    }
    
    // Calculate intelligent lot size
    double layerLot = CalculateIntelligentLotSize(priceZone, layerInZone);
    
    // Execute the trade
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = layerLot;
    request.deviation = Slippage;
    request.magic = MagicNumber;
    request.sl = 0;
    request.tp = 0;
    request.comment = "SmartGrid-Z" + IntegerToString(priceZone) + "-L" + IntegerToString(layerInZone + 1);
    request.type_filling = currentFillingMode;
    
    if(reverseGroup.type == "BUY")
    {
        request.type = ORDER_TYPE_BUY;
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    }
    else
    {
        request.type = ORDER_TYPE_SELL;
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    }
    
    if(OrderSend(request, result) && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
    {
        int idx = ArraySize(gridLayers);
        ArrayResize(gridLayers, idx + 1);
        gridLayers[idx].ticket = result.order;
        gridLayers[idx].entryPrice = request.price;
        gridLayers[idx].lotSize = layerLot;
        gridLayers[idx].layerNumber = GetTotalTriggeredLayers() + 1;
        gridLayers[idx].zone = priceZone;
        gridLayers[idx].isActive = true;
        
        currentGridCount++;
        lastGridAddTime = TimeCurrent();
        
        // Update triggered counts
        if(priceZone == 1) zone1Triggered++;
        else if(priceZone == 2) zone2Triggered++;
        else if(priceZone == 3) zone3Triggered++;
        
        Print("=== INTELLIGENT GRID ADDED ===");
        Print("Zone: ", priceZone, " | Layer: ", (layerInZone + 1));
        Print("Price: ", DoubleToString(currentPrice, _Digits), " | Lot: ", DoubleToString(layerLot, 2));
        Print("Market Phase: ", marketCondition.marketPhase);
        Print("Ticket: ", result.order);
    }
    else
    {
        Print("ERROR: Failed to add intelligent grid layer - ", result.retcode);
    }
}

//+------------------------------------------------------------------+
//| Add basic grid layer (Mode 3)                                     |
//+------------------------------------------------------------------+
void AddBasicGridLayer(double currentPrice)
{
    // Determine which zone we're in and if we can add
    int priceZone = GetCurrentPriceZone(currentPrice);
    int layerInZone = 0;
    
    // Calculate which layer in the current zone
    if(priceZone == 1 && zone1Triggered < GridLayersZone1)
    {
        layerInZone = zone1Triggered;
    }
    else if(priceZone == 2 && zone2Triggered < GridLayersZone2)
    {
        layerInZone = zone2Triggered;
    }
    else if(priceZone == 3 && zone3Triggered < GridLayersZone3)
    {
        layerInZone = zone3Triggered;
    }
    else
    {
        return; // No more layers available in this zone
    }
    
    // Calculate basic lot size
    double layerLot = CalculateBasicLotSize(priceZone, layerInZone);
    
    // Execute the trade
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = layerLot;
    request.deviation = Slippage;
    request.magic = MagicNumber;
    request.sl = 0;
    request.tp = 0;
    request.comment = "Grid-Z" + IntegerToString(priceZone) + "-L" + IntegerToString(layerInZone + 1);
    request.type_filling = currentFillingMode;
    
    if(reverseGroup.type == "BUY")
    {
        request.type = ORDER_TYPE_BUY;
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    }
    else
    {
        request.type = ORDER_TYPE_SELL;
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    }
    
    if(OrderSend(request, result) && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED))
    {
        int idx = ArraySize(gridLayers);
        ArrayResize(gridLayers, idx + 1);
        gridLayers[idx].ticket = result.order;
        gridLayers[idx].entryPrice = request.price;
        gridLayers[idx].lotSize = layerLot;
        gridLayers[idx].layerNumber = GetTotalTriggeredLayers() + 1;
        gridLayers[idx].zone = priceZone;
        gridLayers[idx].isActive = true;
        
        currentGridCount++;
        lastGridAddTime = TimeCurrent();
        
        // Update triggered counts
        if(priceZone == 1) zone1Triggered++;
        else if(priceZone == 2) zone2Triggered++;
        else if(priceZone == 3) zone3Triggered++;
        
        Print("=== BASIC GRID ADDED ===");
        Print("Zone: ", priceZone, " | Layer: ", (layerInZone + 1));
        Print("Price: ", DoubleToString(currentPrice, _Digits), " | Lot: ", DoubleToString(layerLot, 2));
        Print("Ticket: ", result.order);
    }
    else
    {
        Print("ERROR: Failed to add basic grid layer - ", result.retcode);
    }
}
//+------------------------------------------------------------------+
//| Calculate lot size                                                 |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    double lot = LotSize;
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    switch(LotSizeMode)
    {
        case 0: // Fixed lot size
            lot = LotSize;
            break;
            
        case 1: // Risk percentage
            {
                double riskAmount = balance * RiskPercent / 100.0;
                // Simple risk calculation - can be enhanced based on SL distance
                lot = riskAmount / 1000; // Basic calculation
            }
            break;
            
        case 2: // Balance percentage
            {
                double balanceAmount = balance * BalancePercent / 100.0;
                lot = balanceAmount / 100000; // Basic calculation for balance percentage
            }
            break;
    }
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lot = MathFloor(lot / lotStep) * lotStep;
    if(lot < minLot) lot = minLot;
    if(lot > maxLot) lot = maxLot;
    
    return lot;
}

//+------------------------------------------------------------------+
//| Calculate intelligent lot size                                     |
//+------------------------------------------------------------------+
double CalculateIntelligentLotSize(int zone, int layerInZone)
{
    double layerLot = initialLotSize;
    
    // Apply standard progression
    int totalPreviousLayers = GetTotalTriggeredLayers();
    for(int i = 0; i < totalPreviousLayers; i++)
    {
        layerLot *= LotMultiplier;
    }
    
    // Market condition adjustments
    if(marketCondition.marketPhase == "VOLATILE")
    {
        layerLot *= 0.8; // Reduce lot size in volatile conditions
    }
    else if(marketCondition.marketPhase == "RANGING")
    {
        layerLot *= 1.1; // Slightly increase in ranging markets
    }
    
    // Volatility-based adjustment
    if(impulseState.isHighVolatility)
    {
        layerLot *= 0.7; // Significantly reduce in high volatility
    }
    else if(impulseState.isLowVolatility)
    {
        layerLot *= 1.2; // Increase in low volatility
    }
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    layerLot = MathFloor(layerLot / lotStep) * lotStep;
    if(layerLot < minLot) layerLot = minLot;
    if(layerLot > maxLot) layerLot = maxLot;
    
    return layerLot;
}

//+------------------------------------------------------------------+
//| Calculate basic lot size                                           |
//+------------------------------------------------------------------+
double CalculateBasicLotSize(int zone, int layerInZone)
{
    double layerLot = initialLotSize;
    
    // Apply standard progression
    int totalPreviousLayers = GetTotalTriggeredLayers();
    for(int i = 0; i < totalPreviousLayers; i++)
    {
        layerLot *= LotMultiplier;
    }
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    layerLot = MathFloor(layerLot / lotStep) * lotStep;
    if(layerLot < minLot) layerLot = minLot;
    if(layerLot > maxLot) layerLot = maxLot;
    
    return layerLot;
}

//+------------------------------------------------------------------+
//| Get total triggered layers                                         |
//+------------------------------------------------------------------+
int GetTotalTriggeredLayers()
{
    return zone1Triggered + zone2Triggered + zone3Triggered;
}

//+------------------------------------------------------------------+
//| Get current price zone                                             |
//+------------------------------------------------------------------+
int GetCurrentPriceZone(double price)
{
    if(reverseGroup.type == "BUY")
    {
        // For BUY: price above entry = profit (zone 0)
        // Price between entry and zone1Boundary = zone 1 (first drawdown)
        // etc.
        if(price >= reverseGroup.entryPrice) return 0;     // In profit (above entry)
        if(price >= reverseGroup.zone1Boundary) return 1;   // Zone 1 (closest to entry)
        if(price >= reverseGroup.zone2Boundary) return 2;   // Zone 2 (middle)
        if(price >= reverseGroup.zone3Boundary) return 3;   // Zone 3 (near SL)
        return 3;  // Beyond Zone 3 (past SL)
    }
    else // SELL
    {
        if(price <= reverseGroup.entryPrice) return 0;
        if(price <= reverseGroup.zone1Boundary) return 1;
        if(price <= reverseGroup.zone2Boundary) return 2;
        if(price <= reverseGroup.zone3Boundary) return 3;
        return 3;
    }
}
//+------------------------------------------------------------------+
//| Calculate all zone grid levels                                     |
//+------------------------------------------------------------------+
void CalculateAllZoneGridLevels(double entryPrice, double zone1End, double zone2End, double zone3End, string tradeType)
{
    // Zone 1: Entry to SL1
    ArrayResize(zone1Levels, GridLayersZone1);
    double zone1Distance = MathAbs(zone1End - entryPrice);
    double zone1Spacing = zone1Distance / (GridLayersZone1 + 1);
    
    // Zone 2: SL1 to SL2
    ArrayResize(zone2Levels, GridLayersZone2);
    double zone2Distance = MathAbs(zone2End - zone1End);
    double zone2Spacing = zone2Distance / (GridLayersZone2 + 1);
    
    // Zone 3: SL2 to SL3
    ArrayResize(zone3Levels, GridLayersZone3);
    double zone3Distance = MathAbs(zone3End - zone2End);
    double zone3Spacing = zone3Distance / (GridLayersZone3 + 1);
    
    Print("=== GRID ZONES CALCULATED ===");
    Print("Zone 1: Entry(", DoubleToString(entryPrice, _Digits), ") to SL1(", DoubleToString(zone1End, _Digits), ")");
    Print("Zone 2: SL1(", DoubleToString(zone1End, _Digits), ") to SL2(", DoubleToString(zone2End, _Digits), ")");
    Print("Zone 3: SL2(", DoubleToString(zone2End, _Digits), ") to SL3(", DoubleToString(zone3End, _Digits), ")");
    
    for(int i = 0; i < GridLayersZone1; i++)
    {
        if(tradeType == "BUY")
            zone1Levels[i] = entryPrice - (zone1Spacing * (i + 1));
        else
            zone1Levels[i] = entryPrice + (zone1Spacing * (i + 1));
    }
    
    for(int i = 0; i < GridLayersZone2; i++)
    {
        if(tradeType == "BUY")
            zone2Levels[i] = zone1End - (zone2Spacing * (i + 1));
        else
            zone2Levels[i] = zone1End + (zone2Spacing * (i + 1));
    }
    
    for(int i = 0; i < GridLayersZone3; i++)
    {
        if(tradeType == "BUY")
            zone3Levels[i] = zone2End - (zone3Spacing * (i + 1));
        else
            zone3Levels[i] = zone2End + (zone3Spacing * (i + 1));
    }
}

//+------------------------------------------------------------------+
//| Calculate basket profit target                                     |
//+------------------------------------------------------------------+
double CalculateBasketProfitTarget(double entryPrice, double targetTP, double lotSize, string tradeType)
{
    double profitPerPosition = 0;
    
    double priceDistance = 0;
    if(tradeType == "SELL")
    {
        priceDistance = entryPrice - targetTP;
    }
    else
    {
        priceDistance = targetTP - entryPrice;
    }
    
    if(priceDistance <= 0)
    {
        priceDistance = MathAbs(targetTP - entryPrice);
    }
    
    // Calculate profit using OrderCalcProfit
    ENUM_ORDER_TYPE orderType = (tradeType == "BUY") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    double calcProfit = 0;
    if(OrderCalcProfit(orderType, _Symbol, lotSize, entryPrice, targetTP, calcProfit))
    {
        profitPerPosition = MathAbs(calcProfit);
    }
    else
    {
        // Fallback calculation
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double ticksCount = priceDistance / tickSize;
        profitPerPosition = ticksCount * tickValue * lotSize;
    }
    
    double totalProfit = profitPerPosition * 3;
    
    // Apply minimum profit target for safety
    double minProfitTarget = 5.0;
    if(totalProfit < minProfitTarget)
    {
        totalProfit = minProfitTarget;
    }
    
    Print("=== BASKET PROFIT CALCULATION ===");
    Print("Entry: ", DoubleToString(entryPrice, _Digits));
    Print("Target TP: ", DoubleToString(targetTP, _Digits));
    Print("Lot Size: ", DoubleToString(lotSize, 2));
    Print("Profit per Position: $", DoubleToString(profitPerPosition, 2));
    Print("Total for 3 Positions: $", DoubleToString(totalProfit, 2));
    Print("Final Target: $", DoubleToString(totalProfit * BasketProfitMultiplier, 2));
    
    return totalProfit * BasketProfitMultiplier;
}
//+------------------------------------------------------------------+
//| Get current basket P/L                                             |
//+------------------------------------------------------------------+
double GetCurrentBasketPL()
{
    double totalPL = 0;
    
    // Check reverse positions
    if(PositionSelectByTicket(reverseGroup.ticket1))
        totalPL += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
    if(PositionSelectByTicket(reverseGroup.ticket2))
        totalPL += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
    if(PositionSelectByTicket(reverseGroup.ticket3))
        totalPL += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
    
    // Check grid positions
    for(int i = 0; i < ArraySize(gridLayers); i++)
    {
        if(gridLayers[i].isActive && PositionSelectByTicket(gridLayers[i].ticket))
        {
            totalPL += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
    }
    
    return totalPL;
}

//+------------------------------------------------------------------+
//| Close all positions and grid                                       |
//+------------------------------------------------------------------+
void CloseAllPositionsAndGrid(string reason)
{
    Print("=== CLOSING ALL POSITIONS ===");
    Print("Reason: ", reason);
    
    // Close reverse positions
    if(reverseGroup.ticket1 > 0) ClosePosition(reverseGroup.ticket1);
    if(reverseGroup.ticket2 > 0) ClosePosition(reverseGroup.ticket2);
    if(reverseGroup.ticket3 > 0) ClosePosition(reverseGroup.ticket3);
    
    // Close grid positions
    for(int i = 0; i < ArraySize(gridLayers); i++)
    {
        if(gridLayers[i].isActive)
        {
            ClosePosition(gridLayers[i].ticket);
            gridLayers[i].isActive = false;
        }
    }
    
    ResetReverseGroup();
    ResetGrid();
}

//+------------------------------------------------------------------+
//| Close position                                                     |
//+------------------------------------------------------------------+
bool ClosePosition(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return false;
    
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.symbol = _Symbol;
    request.volume = PositionGetDouble(POSITION_VOLUME);
    request.deviation = Slippage;
    request.magic = MagicNumber;
    request.type_filling = currentFillingMode;
    
    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    if(posType == POSITION_TYPE_BUY) 
    { 
        request.type = ORDER_TYPE_SELL; 
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID); 
    }
    else 
    { 
        request.type = ORDER_TYPE_BUY; 
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK); 
    }
    
    return OrderSend(request, result) && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED);
}

//+------------------------------------------------------------------+
//| Modify stop loss                                                   |
//+------------------------------------------------------------------+
void ModifyStopLoss(ulong ticket, double newSL)
{
    if(!PositionSelectByTicket(ticket)) return;
    
    double currentSL = PositionGetDouble(POSITION_SL);
    if(MathAbs(currentSL - newSL) < _Point * 5) return;
    
    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
    double minDistance = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
    
    if(posType == POSITION_TYPE_BUY && newSL >= currentPrice - minDistance) 
        newSL = currentPrice - minDistance - (10 * _Point);
    else if(posType == POSITION_TYPE_SELL && newSL <= currentPrice + minDistance) 
        newSL = currentPrice + minDistance + (10 * _Point);
    
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_SLTP;
    request.symbol = _Symbol;
    request.sl = newSL;
    request.tp = PositionGetDouble(POSITION_TP);
    request.position = ticket;
    request.type_filling = currentFillingMode;
    
    bool success = OrderSend(request, result);
    if(!success)
    {
        Print("ERROR: Failed to modify stop loss for ticket ", ticket, ". Error: ", result.retcode);
    }
}
//+------------------------------------------------------------------+
//| Reset position groups                                              |
//+------------------------------------------------------------------+
void ResetPositionGroups()
{
    ResetOriginalGroup();
    ResetReverseGroup();
}

//+------------------------------------------------------------------+
//| Reset original group                                               |
//+------------------------------------------------------------------+
void ResetOriginalGroup()
{
    originalGroup.ticket1 = 0;
    originalGroup.ticket2 = 0;
    originalGroup.ticket3 = 0;
    originalGroup.tp1Reached = false;
    originalGroup.tp2Reached = false;
    originalGroup.openTime = 0;
    originalGroup.type = "";
}

//+------------------------------------------------------------------+
//| Reset reverse group                                                |
//+------------------------------------------------------------------+
void ResetReverseGroup()
{
    reverseGroup.ticket1 = 0;
    reverseGroup.ticket2 = 0;
    reverseGroup.ticket3 = 0;
    reverseGroup.openTime = 0;
    reverseGroup.type = "";
    reverseGroup.entryPrice = 0;
    reverseGroup.targetTP = 0;
    reverseGroup.zone1Boundary = 0;
    reverseGroup.zone2Boundary = 0;
    reverseGroup.zone3Boundary = 0;
    syncActive = false;
    
    // Reset swing point SL
    currentSwingSLPrice = 0;
    currentSwingRawPrice = 0;
    swingSLActive = false;
    lastSwingSLCheckTime = 0;
    ObjectsDeleteAll(0, "SwingSL_");
    
    // Reset dynamic TP
    currentDynamicTPPrice = 0;
    currentDynamicRawTPPrice = 0;
    dynamicTPActive = false;
    activeTPMode = "";
    ObjectsDeleteAll(0, "DynamicTP_");
    
    // Cancel any pending RSI signal when positions are reset
    if(pendingRSISignal.isWaiting)
    {
        Print("INFO: Cancelling pending RSI signal due to position group reset");
        InitializePendingRSISignal();
    }
}

//+------------------------------------------------------------------+
//| Reset grid                                                         |
//+------------------------------------------------------------------+
void ResetGrid()
{
    ArrayResize(gridLayers, 0);
    currentGridCount = 0;
    basketProfitTarget = 0;
    zone1Triggered = 0;
    zone2Triggered = 0;
    zone3Triggered = 0;
    adaptiveSpacing = 0;
    baseSpacing = 0;
    lastGridAddTime = 0;
}

//+------------------------------------------------------------------+
//| Reset impulse state                                                |
//+------------------------------------------------------------------+
void ResetImpulseState()
{
    impulseState.isInImpulse = false;
    impulseState.impulseStartTime = 0;
    impulseState.impulseEndTime = 0;
    impulseState.barsSinceImpulse = 999;
    impulseState.impulseDirection = 0;
    impulseState.lastATR = 0;
    impulseState.currentVolatility = 1.0;
    impulseState.avgVolatility = 1.0;
    impulseState.isHighVolatility = false;
    impulseState.isLowVolatility = false;
    
    marketCondition.currentRSI = 50;
    marketCondition.currentVolume = 0;
    marketCondition.avgVolume = 0;
    marketCondition.isOverbought = false;
    marketCondition.isOversold = false;
    marketCondition.hasVolumeSpike = false;
    marketCondition.isMomentumStrong = false;
    marketCondition.marketPhase = "RANGING";
}

//+------------------------------------------------------------------+
//| Initialize daily tracking                                          |
//+------------------------------------------------------------------+
void InitializeDailyTracking()
{
    dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    currentTradingDay = GetTradingDay();
    dailyProfitLoss = 0;
    dailyLimitReached = false;
    dailyLimitReason = "";
    
    // Calculate effective daily limits
    CalculateEffectiveDailyLimits();
}

//+------------------------------------------------------------------+
//| Calculate effective daily limits                                   |
//+------------------------------------------------------------------+
void CalculateEffectiveDailyLimits()
{
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    if(UseDailyLimitPercentage)
    {
        effectiveDailyProfitTarget = currentBalance * DailyProfitPercent / 100.0;
        effectiveDailyLossLimit = currentBalance * DailyLossPercent / 100.0;
    }
    else
    {
        effectiveDailyProfitTarget = DailyProfitTarget;
        effectiveDailyLossLimit = DailyLossLimit;
    }
}

//+------------------------------------------------------------------+
//| Get trading day                                                    |
//+------------------------------------------------------------------+
datetime GetTradingDay()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Check daily reset                                                  |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
    datetime today = GetTradingDay();
    if(today != currentTradingDay)
    {
        currentTradingDay = today;
        dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        dailyProfitLoss = 0;
        dailyLimitReached = false;
        dailyLimitReason = "";
        
        // Recalculate effective limits for new day
        CalculateEffectiveDailyLimits();
        
        // Reset equity guard for new day
        InitializeEquityGuard();
        
        Print("New day started. Balance: $", DoubleToString(dailyStartBalance, 2));
        Print("Effective Daily Profit Target: $", DoubleToString(effectiveDailyProfitTarget, 2));
        Print("Effective Daily Loss Limit: $", DoubleToString(effectiveDailyLossLimit, 2));
    }
}

//+------------------------------------------------------------------+
//| Update daily P/L                                                   |
//+------------------------------------------------------------------+
void UpdateDailyPL()
{
    // Get closed P/L for today
    double closedPL = CalculateTodaysClosedPL();
    
    // Get floating P/L from open positions
    double floatingPL = GetCurrentBasketPL();
    
    // Total daily P/L
    dailyProfitLoss = closedPL + floatingPL;
    
    // Check daily profit target
    if(dailyProfitLoss >= effectiveDailyProfitTarget && !dailyLimitReached)
    {
        dailyLimitReached = true;
        dailyLimitReason = "Daily Profit Target Reached: $" + DoubleToString(dailyProfitLoss, 2);
        Print("=== DAILY PROFIT TARGET REACHED ===");
        Print("Target: $", DoubleToString(effectiveDailyProfitTarget, 2), " | Current: $", DoubleToString(dailyProfitLoss, 2));
        
        // Send Telegram notification
        if(EnableTelegramNotifications && NotifyOnLimits)
        {
            string content = "DAILY PROFIT TARGET REACHED!\n";
            content += "Current P/L: +$" + DoubleToString(dailyProfitLoss, 2) + "\n";
            content += "Target: $" + DoubleToString(effectiveDailyProfitTarget, 2) + "\n";
            content += "Trading stopped for today";
            
            SendTelegramMessage(FormatTelegramMessage("DAILY TARGET HIT", content));
        }
        
        // Close all positions
        if(CountOpenPositions(false) > 0)
        {
            CloseAllPositionsAndGrid("Daily profit target reached");
        }
    }
    
    // Check daily loss limit
    if(dailyProfitLoss <= -effectiveDailyLossLimit && !dailyLimitReached)
    {
        dailyLimitReached = true;
        dailyLimitReason = "Daily Loss Limit Reached: $" + DoubleToString(dailyProfitLoss, 2);
        Print("=== DAILY LOSS LIMIT REACHED ===");
        Print("Limit: -$", DoubleToString(effectiveDailyLossLimit, 2), " | Current: $", DoubleToString(dailyProfitLoss, 2));
        
        // Send Telegram notification
        if(EnableTelegramNotifications && NotifyOnLimits)
        {
            string content = "DAILY LOSS LIMIT REACHED!\n";
            content += "Current P/L: -$" + DoubleToString(MathAbs(dailyProfitLoss), 2) + "\n";
            content += "Limit: $" + DoubleToString(effectiveDailyLossLimit, 2) + "\n";
            content += "Trading stopped for today";
            
            SendTelegramMessage(FormatTelegramMessage("DAILY LIMIT HIT", content));
        }
        
        // Close all positions
        if(CountOpenPositions(false) > 0)
        {
            CloseAllPositionsAndGrid("Daily loss limit reached");
        }
    }
}
//+------------------------------------------------------------------+
//| Calculate today's closed P/L                                       |
//+------------------------------------------------------------------+
double CalculateTodaysClosedPL()
{
    double todayPL = 0;
    datetime todayStart = GetTradingDay();
    
    // Check history for today's closed trades
    if(HistorySelect(todayStart, TimeCurrent()))
    {
        int totalDeals = HistoryDealsTotal();
        for(int i = 0; i < totalDeals; i++)
        {
            ulong ticket = HistoryDealGetTicket(i);
            if(ticket > 0)
            {
                if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber &&
                   HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
                {
                    ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
                    if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)
                    {
                        todayPL += HistoryDealGetDouble(ticket, DEAL_PROFIT);
                        todayPL += HistoryDealGetDouble(ticket, DEAL_SWAP);
                        todayPL += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
                    }
                }
            }
        }
    }
    
    return todayPL;
}

//+------------------------------------------------------------------+
//| Send signal to file                                                |
//+------------------------------------------------------------------+
void SendSignalToFile(SignalInfo &signal)
{
    string signalData = signal.type + "," +
                        DoubleToString(signal.entryPrice, _Digits) + "," +
                        DoubleToString(signal.tp1, _Digits) + "," +
                        DoubleToString(signal.tp2, _Digits) + "," +
                        DoubleToString(signal.tp3, _Digits) + "," +
                        DoubleToString(signal.sl, _Digits) + "," +
                        _Symbol + "," +
                        IntegerToString((long)signal.signalTime) + "," +
                        "0";
    
    string fileName = "goldmine_combined_signal.csv";
    int handle = FileOpen(fileName, FILE_WRITE|FILE_TXT|FILE_COMMON|FILE_SHARE_READ|FILE_SHARE_WRITE);
    if(handle == INVALID_HANDLE)
    {
        Print("ERROR: Cannot create signal file. Error: ", GetLastError());
        return;
    }
    
    FileWriteString(handle, signalData);
    FileClose(handle);
    
    Print("Signal sent to file: ", signalData);
}

//+------------------------------------------------------------------+
//| Detect filling mode                                                |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING DetectFillingMode()
{
    if(!AutoDetectFilling)
    {
        return ManualFillingMode;
    }
    
    // Get symbol filling modes
    int fillingModes = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
    
    // Check supported modes in order of preference: FOK -> IOC -> RETURN
    if((fillingModes & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
    {
        return ORDER_FILLING_FOK;
    }
    else if((fillingModes & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
    {
        return ORDER_FILLING_IOC;
    }
    else
    {
        return ORDER_FILLING_RETURN;
    }
}

//+------------------------------------------------------------------+
//| Get filling mode description                                       |
//+------------------------------------------------------------------+
string GetFillingModeDescription(ENUM_ORDER_TYPE_FILLING mode)
{
    switch(mode)
    {
        case ORDER_FILLING_FOK: return "FOK (Fill or Kill)";
        case ORDER_FILLING_IOC: return "IOC (Immediate or Cancel)";
        case ORDER_FILLING_RETURN: return "RETURN (Return mode)";
        default: return "Unknown";
    }
}

//+------------------------------------------------------------------+
//| Get close mode description                                         |
//+------------------------------------------------------------------+
string GetCloseModeDescription()
{
    switch(CloseMode)
    {
        case 0: return "Normal (sync close)";
        case 1: return "Close ALL at TP1";
        case 2: return "Close ALL at SL1";
        case 3: return "Basket + Grid";
        case 4: return "Intelligent Volatility-Aware Grid";
        default: return "Unknown";
    }
}

//+------------------------------------------------------------------+
//| Create signal table                                                |
//+------------------------------------------------------------------+
void CreateSignalTable()
{
    if(!ShowSignalTable) return;
    
    string objName = "Signal_Table_BG";
    if(ObjectFind(0, objName) < 0)
    {
        ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, 20);
        ObjectSetInteger(0, objName, OBJPROP_XSIZE, 320);
        ObjectSetInteger(0, objName, OBJPROP_YSIZE, 350);
        ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBlack);
        ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
    }
}

//+------------------------------------------------------------------+
//| Update signal table                                                |
//+------------------------------------------------------------------+
void UpdateSignalTable(SignalInfo &signal)
{
    if(!ShowSignalTable) return;
    
    int x = 20, y = 30, lh = 20;
    CreateLabel("Signal_Header", "=== GOLDMINE COMBINED v4.0 ===", x, y, clrYellow, 10);
    
    if(signal.isValid)
    {
        CreateLabel("Signal_Type", "Signal: " + signal.type, x, y + lh, signal.type == "BUY" ? BuyColor : SellColor, 11);
        CreateLabel("Signal_Entry", "Entry: " + DoubleToString(signal.entryPrice, _Digits), x, y + lh*2, clrWhite);
        CreateLabel("Signal_TP1", "TP1: " + DoubleToString(signal.tp1, _Digits), x, y + lh*3, clrLimeGreen);
        CreateLabel("Signal_TP2", "TP2: " + DoubleToString(signal.tp2, _Digits), x, y + lh*4, clrLimeGreen);
        CreateLabel("Signal_TP3", "TP3: " + DoubleToString(signal.tp3, _Digits), x, y + lh*5, clrGreen);
        CreateLabel("Signal_SL", "SL: " + DoubleToString(signal.sl, _Digits), x, y + lh*6, clrRed);
    }
    else
    {
        CreateLabel("Signal_Type", "Signal: Waiting...", x, y + lh, clrGray, 11);
        CreateLabel("Signal_Entry", "Entry: -", x, y + lh*2, clrGray);
        CreateLabel("Signal_TP1", "TP1: -", x, y + lh*3, clrGray);
        CreateLabel("Signal_TP2", "TP2: -", x, y + lh*4, clrGray);
        CreateLabel("Signal_TP3", "TP3: -", x, y + lh*5, clrGray);
        CreateLabel("Signal_SL", "SL: -", x, y + lh*6, clrGray);
    }
    
    CreateLabel("Signal_Count", "Signals: " + IntegerToString(signalCount) + " | Trades: " + IntegerToString(tradeCount), x, y + lh*7, clrAqua);
    CreateLabel("Signal_Mode", "Original: " + (ExecuteOriginalTrades ? "ON" : "OFF") + " | Reverse: " + (ExecuteReverseTrades ? "ON" : "OFF"), x, y + lh*8, clrOrange);
    CreateLabel("Signal_CloseMode", "Close Mode: " + IntegerToString(CloseMode), x, y + lh*9, clrAqua);
    
    string status = "Status: ";
    if(ExecuteReverseTrades && reverseGroup.ticket1 > 0)
    {
        status += "Reverse Active (" + IntegerToString(CountOpenPositions(false)) + " pos)";
        if(basketProfitTarget > 0)
        {
            double currentPL = GetCurrentBasketPL();
            status += " | P/L: $" + DoubleToString(currentPL, 1);
        }
    }
    else if(ExecuteOriginalTrades && originalGroup.ticket1 > 0)
    {
        status += "Original Active";
        if(!originalGroup.tp1Reached) status += " (3 pos)";
        else if(!originalGroup.tp2Reached) status += " (2 pos at BE)";
        else status += " (1 pos at TP1)";
    }
    else
    {
        status += "No Positions";
    }
    
    CreateLabel("Signal_Status", status, x, y + lh*10, clrAqua);
    
    // Show RSI information if momentum filter is enabled
    if(UseMomentumFilter && marketCondition.currentRSI > 0)
    {
        string rsiInfo = "RSI: " + DoubleToString(marketCondition.currentRSI, 1);
        if(marketCondition.isOverbought) rsiInfo += " (OB)";
        else if(marketCondition.isOversold) rsiInfo += " (OS)";
        CreateLabel("Signal_RSI", rsiInfo, x, y + lh*11, clrYellow);
        
        // Show RSI Entry Filter status
        if(UseRSIEntryFilter && ExecuteReverseTrades)
        {
            if(pendingRSISignal.isWaiting)
            {
                string waitingStatus = "RSI ENTRY: WAITING (" + pendingRSISignal.signal.reverseType + ")";
                waitingStatus += " | Need: " + pendingRSISignal.waitingFor;
                waitingStatus += " | Bars: " + IntegerToString(pendingRSISignal.barsWaited);
                CreateLabel("Signal_RSI_Entry", waitingStatus, x, y + lh*12, clrOrange);
            }
            else
            {
                string entryStatus = "RSI Entry Filter: ACTIVE";
                entryStatus += " (Buy≤" + DoubleToString(RSI_BuyEntryLevel, 1);
                entryStatus += " Sell≥" + DoubleToString(RSI_SellEntryLevel, 1) + ")";
                CreateLabel("Signal_RSI_Entry", entryStatus, x, y + lh*12, clrLightGreen);
            }
        }
        
        // Show RSI Stop Loss status
        if(UseRSIStopLoss && ExecuteReverseTrades)
        {
            string stopStatus = "RSI Stop Loss: ACTIVE";
            if(syncActive && reverseGroup.type != "")
            {
                if(reverseGroup.type == "BUY")
                    stopStatus += " (Stop<" + DoubleToString(RSI_BuyStopLevel, 1) + ")";
                else
                    stopStatus += " (Stop>" + DoubleToString(RSI_SellStopLevel, 1) + ")";
            }
            CreateLabel("Signal_RSI_Stop", stopStatus, x, y + lh*13, clrPink);
        }
    }
    
    if(UseDailyLimits)
    {
        string dailyStatus = "Daily P/L: $" + DoubleToString(dailyProfitLoss, 1);
        int dailyY = y + lh*14;
        if(!UseMomentumFilter) dailyY = y + lh*11;
        else if(!UseRSIEntryFilter && !UseRSIStopLoss) dailyY = y + lh*12;
        else if(!UseRSIEntryFilter || !UseRSIStopLoss) dailyY = y + lh*13;
        
        if(dailyLimitReached)
        {
            dailyStatus += " | LIMIT REACHED";
            CreateLabel("Signal_Daily", dailyStatus, x, dailyY, clrRed);
        }
        else
        {
            CreateLabel("Signal_Daily", dailyStatus, x, dailyY, clrWhite);
        }
    }
}

//+------------------------------------------------------------------+
//| Create label                                                       |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize = 9)
{
    if(ObjectFind(0, name) < 0)
    {
        ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
    }
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
}

//+------------------------------------------------------------------+
//| Draw TP/SL lines                                                   |
//+------------------------------------------------------------------+
void DrawTPSLLines(SignalInfo &signal)
{
    if(!ShowTPSLLines) return;
    
    ObjectsDeleteAll(0, "TP_");
    ObjectsDeleteAll(0, "SL_");
    
    DrawHLine("TP_1", signal.tp1, clrLimeGreen, STYLE_DASH, 2);
    DrawHLine("TP_2", signal.tp2, clrLimeGreen, STYLE_DASH, 2);
    DrawHLine("TP_3", signal.tp3, clrGreen, STYLE_DOT, 1);
    DrawHLine("SL_Line", signal.sl, clrRed, STYLE_SOLID, 2);
}

//+------------------------------------------------------------------+
//| Draw horizontal line                                               |
//+------------------------------------------------------------------+
void DrawHLine(string name, double price, color clr, ENUM_LINE_STYLE style, int width = 1)
{
    if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
    ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
}

//+------------------------------------------------------------------+
//| Draw signal arrow                                                  |
//+------------------------------------------------------------------+
void DrawSignalArrow(SignalInfo &signal)
{
    string arrowName = "Signal_Arrow_" + TimeToString(signal.signalTime);
    if(signal.type == "BUY")
    {
        ObjectCreate(0, arrowName, OBJ_ARROW_BUY, 0, signal.signalTime, signal.entryPrice);
        ObjectSetInteger(0, arrowName, OBJPROP_COLOR, BuyColor);
    }
    else
    {
        ObjectCreate(0, arrowName, OBJ_ARROW_SELL, 0, signal.signalTime, signal.entryPrice);
        ObjectSetInteger(0, arrowName, OBJPROP_COLOR, SellColor);
    }
    ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 3);
}

//+------------------------------------------------------------------+
//| Initialize pending RSI signal                                     |
//+------------------------------------------------------------------+
void InitializePendingRSISignal()
{
    pendingRSISignal.isWaiting = false;
    pendingRSISignal.waitStartTime = 0;
    pendingRSISignal.barsWaited = 0;
    pendingRSISignal.waitingFor = "";
    pendingRSISignal.signal.isValid = false;
}

//+------------------------------------------------------------------+
//| Update current RSI value (called on every tick)                   |
//+------------------------------------------------------------------+
void UpdateCurrentRSI()
{
    if(!UseMomentumFilter || rsiHandle == INVALID_HANDLE)
        return;
    
    double rsiBuffer[];
    ArraySetAsSeries(rsiBuffer, true);
    
    // Get the latest RSI value (index 0 = current forming bar)
    if(CopyBuffer(rsiHandle, 0, 0, 2, rsiBuffer) > 0)
    {
        // Use the current forming bar RSI (index 0) for immediate response
        marketCondition.currentRSI = rsiBuffer[0];
        
        // Update overbought/oversold status
        marketCondition.isOverbought = (marketCondition.currentRSI > RSI_OverboughtLevel);
        marketCondition.isOversold = (marketCondition.currentRSI < RSI_OversoldLevel);
        
        // Update momentum strength
        double rsiDistance = MathAbs(marketCondition.currentRSI - 50);
        marketCondition.isMomentumStrong = (rsiDistance > 25);
    }
}

//+------------------------------------------------------------------+
//| Get previous completed bar RSI value                              |
//+------------------------------------------------------------------+
double GetPreviousBarRSI()
{
    if(!UseMomentumFilter || rsiHandle == INVALID_HANDLE)
        return 0;
    
    double rsiBuffer[];
    ArraySetAsSeries(rsiBuffer, true);
    
    // Get RSI from previous completed bar (index 1)
    if(CopyBuffer(rsiHandle, 0, 1, 1, rsiBuffer) > 0)
    {
        return rsiBuffer[0];
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Check if RSI entry conditions are met                             |
//+------------------------------------------------------------------+
bool CheckRSIEntryConditions(string signalType)
{
    if(!UseRSIEntryFilter)
        return true;  // Feature disabled, allow entry
    
    if(!UseMomentumFilter || marketCondition.currentRSI <= 0)
        return true;  // RSI not available, allow entry
    
    double rsiToCheck = marketCondition.currentRSI;
    
    // If waiting for candle close, use the previous completed bar's RSI
    if(RSI_WaitForCandleClose)
    {
        double rsiBuffer[];
        ArraySetAsSeries(rsiBuffer, true);
        if(CopyBuffer(rsiHandle, 0, 1, 1, rsiBuffer) > 0)  // Index 1 = previous completed bar
        {
            rsiToCheck = rsiBuffer[0];
        }
        else
        {
            return false;  // Can't get previous bar RSI, don't execute
        }
    }
    
    if(signalType == "BUY")
    {
        // For BUY signals, RSI should be at or below the buy entry level
        return (rsiToCheck <= RSI_BuyEntryLevel);
    }
    else if(signalType == "SELL")
    {
        // For SELL signals, RSI should be at or above the sell entry level
        return (rsiToCheck >= RSI_SellEntryLevel);
    }
    
    return true;  // Unknown signal type, allow entry
}

//+------------------------------------------------------------------+
//| Check RSI stop loss conditions                                    |
//+------------------------------------------------------------------+
bool CheckRSIStopLoss()
{
    if(!UseRSIStopLoss || !syncActive || CountOpenPositions(false) == 0)
        return false;
    
    if(!UseMomentumFilter || marketCondition.currentRSI <= 0)
        return false;
    
    double rsiToCheck = marketCondition.currentRSI;
    
    // If waiting for candle close, use the previous completed bar's RSI
    if(RSI_StopWaitForCandleClose)
    {
        rsiToCheck = GetPreviousBarRSI();
        if(rsiToCheck <= 0)
            return false;  // Can't get previous bar RSI
    }
    
    bool shouldStop = false;
    string stopReason = "";
    
    if(reverseGroup.type == "BUY")
    {
        // For BUY positions, stop if RSI goes below the stop level
        if(rsiToCheck < RSI_BuyStopLevel)
        {
            shouldStop = true;
            stopReason = "BUY RSI Stop: " + DoubleToString(rsiToCheck, 1) + " < " + DoubleToString(RSI_BuyStopLevel, 1);
        }
    }
    else if(reverseGroup.type == "SELL")
    {
        // For SELL positions, stop if RSI goes above the stop level
        if(rsiToCheck > RSI_SellStopLevel)
        {
            shouldStop = true;
            stopReason = "SELL RSI Stop: " + DoubleToString(rsiToCheck, 1) + " > " + DoubleToString(RSI_SellStopLevel, 1);
        }
    }
    
    if(shouldStop)
    {
        string modeStr = RSI_StopWaitForCandleClose ? "CANDLE CLOSE" : "TICK-BASED";
        Print("=== RSI STOP LOSS TRIGGERED (", modeStr, ") ===");
        Print("Position Type: ", reverseGroup.type);
        Print("RSI Value: ", DoubleToString(rsiToCheck, 1));
        Print("Stop Reason: ", stopReason);
        Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS));
        
        // Close all positions
        double finalPL = GetCurrentBasketPL();
        CloseAllPositionsAndGrid("RSI stop loss triggered");
        
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Process pending RSI signal                                        |
//+------------------------------------------------------------------+
void ProcessPendingRSISignal()
{
    if(!pendingRSISignal.isWaiting)
        return;
    
    // Update RSI based on mode
    if(RSI_WaitForCandleClose)
    {
        // Only check on new bar formation
        datetime currentBarTime = iTime(_Symbol, ImpulseTimeframe, 0);
        static datetime lastPendingBarTime = 0;
        if(currentBarTime != lastPendingBarTime)
        {
            lastPendingBarTime = currentBarTime;
            pendingRSISignal.barsWaited++;
            
            // Update RSI from previous completed bar
            UpdateCurrentRSI();
            
            if(ShowDebugInfo && pendingRSISignal.barsWaited % 5 == 0) // Log every 5 bars
            {
                Print("RSI ENTRY WAITING (CANDLE CLOSE): ", pendingRSISignal.signal.reverseType, 
                      " | Bars: ", pendingRSISignal.barsWaited,
                      " | Previous Bar RSI: ", DoubleToString(GetPreviousBarRSI(), 1),
                      " | Need: ", pendingRSISignal.waitingFor);
            }
        }
    }
    else
    {
        // Update on every tick for immediate execution
        UpdateCurrentRSI();
        
        // Count bars waited (only update on new bar)
        datetime currentBarTime = iTime(_Symbol, ImpulseTimeframe, 0);
        static datetime lastPendingBarTime = 0;
        if(currentBarTime != lastPendingBarTime)
        {
            lastPendingBarTime = currentBarTime;
            pendingRSISignal.barsWaited++;
            
            if(ShowDebugInfo && pendingRSISignal.barsWaited % 5 == 0) // Log every 5 bars
            {
                Print("RSI ENTRY WAITING (TICK-BASED): ", pendingRSISignal.signal.reverseType, 
                      " | Bars: ", pendingRSISignal.barsWaited,
                      " | Current RSI: ", DoubleToString(marketCondition.currentRSI, 1),
                      " | Need: ", pendingRSISignal.waitingFor);
            }
        }
    }
    
    // Check timeout
    if(RSI_WaitTimeoutBars > 0 && pendingRSISignal.barsWaited >= RSI_WaitTimeoutBars)
    {
        Print("=== RSI ENTRY TIMEOUT ===");
        Print("Signal Type: ", pendingRSISignal.signal.reverseType);
        Print("Waited ", pendingRSISignal.barsWaited, " bars for RSI condition");
        Print("Mode: ", (RSI_WaitForCandleClose ? "CANDLE CLOSE" : "TICK-BASED"));
        Print("Current RSI: ", DoubleToString(marketCondition.currentRSI, 1));
        Print("Required: ", pendingRSISignal.waitingFor);
        Print("Executing signal anyway due to timeout...");
        
        // Execute the signal despite timeout
        ExecuteReversePositions(pendingRSISignal.signal);
        InitializePendingRSISignal();
        return;
    }
    
    // Check if RSI conditions are now met
    if(CheckRSIEntryConditions(pendingRSISignal.signal.reverseType))
    {
        string executionMode = RSI_WaitForCandleClose ? "CANDLE CLOSE" : "TICK-BASED";
        double rsiValue = RSI_WaitForCandleClose ? GetPreviousBarRSI() : marketCondition.currentRSI;
        
        Print("=== RSI ENTRY CONDITIONS MET (", executionMode, ") ===");
        Print("Signal Type: ", pendingRSISignal.signal.reverseType);
        Print("Waited ", pendingRSISignal.barsWaited, " bars");
        Print("RSI Value: ", DoubleToString(rsiValue, 1));
        Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS));
        
        // Execute the signal
        ExecuteReversePositions(pendingRSISignal.signal);
        InitializePendingRSISignal();
        return;
    }
}

//+------------------------------------------------------------------+
//| URL encode a string for HTTP requests                             |
//+------------------------------------------------------------------+
string UrlEncode(string text)
{
    string encoded = "";
    
    // Convert to UTF-8 bytes first
    uchar utf8_bytes[];
    int utf8_len = StringToCharArray(text, utf8_bytes, 0, WHOLE_ARRAY, CP_UTF8);
    if(utf8_len > 0) utf8_len--; // Remove null terminator
    
    for(int i = 0; i < utf8_len; i++)
    {
        uchar ch = utf8_bytes[i];
        
        // Characters that don't need encoding
        if((ch >= 'A' && ch <= 'Z') || 
           (ch >= 'a' && ch <= 'z') || 
           (ch >= '0' && ch <= '9') ||
           ch == '-' || ch == '_' || ch == '.' || ch == '~')
        {
            encoded += CharToString(ch);
        }
        // Space becomes +
        else if(ch == ' ')
        {
            encoded += "+";
        }
        // Everything else gets percent encoded
        else
        {
            encoded += StringFormat("%%%02X", ch);
        }
    }
    return encoded;
}

//+------------------------------------------------------------------+
//| Send Telegram notification                                         |
//+------------------------------------------------------------------+
bool SendTelegramMessage(string message)
{
    if(!EnableTelegramNotifications || TelegramBotToken == "" || TelegramChatID == "")
        return false;
    
    // Validate inputs
    if(StringLen(TelegramBotToken) < 10 || StringLen(TelegramChatID) < 3)
    {
        Print("ERROR: Invalid Telegram Bot Token or Chat ID");
        return false;
    }
    
    string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
    
    // Clean the message - remove any problematic characters
    string cleanMessage = message;
    StringReplace(cleanMessage, "\r", "");  // Remove carriage returns
    
    // URL encode the message and chat ID
    string encodedMessage = UrlEncode(cleanMessage);
    string encodedChatID = UrlEncode(TelegramChatID);
    
    // Build POST data - remove parse_mode to avoid issues
    string postData = "chat_id=" + encodedChatID + "&text=" + encodedMessage;
    
    char data[];
    char result[];
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    
    // Convert string to char array with proper UTF-8 handling
    int dataLen = StringToCharArray(postData, data, 0, WHOLE_ARRAY, CP_UTF8);
    if(dataLen > 0) dataLen--; // Remove null terminator
    
    if(dataLen <= 0)
    {
        Print("ERROR: Failed to convert POST data to char array");
        return false;
    }
    
    int timeout = 10000; // 10 seconds timeout
    int res = WebRequest("POST", url, headers, timeout, data, result, headers);
    
    if(res == 200)
    {
        if(ShowDebugInfo)
            Print("Telegram notification sent successfully");
        return true;
    }
    else
    {
        Print("ERROR: Failed to send Telegram notification. HTTP code: ", res);
        return false;
    }
}

//+------------------------------------------------------------------+
//| Format Telegram message with EA info                              |
//+------------------------------------------------------------------+
string FormatTelegramMessage(string title, string content)
{
    string message = "Goldmine Combined EA v4.0\n";
    message += _Symbol + " | Mode " + IntegerToString(CloseMode) + "\n";
    message += TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "\n\n";
    message += "=== " + title + " ===\n";
    message += content;
    
    // Ensure message isn't too long (Telegram limit is 4096 characters)
    if(StringLen(message) > 4000)
    {
        message = StringSubstr(message, 0, 3900) + "\n...[Message truncated]";
    }
    
    return message;
}

//+------------------------------------------------------------------+
//| Initialize equity guard                                            |
//+------------------------------------------------------------------+
void InitializeEquityGuard()
{
    equityGuardStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    equityGuardThreshold = equityGuardStartBalance * EquityGuardPercent / 100.0;
    lastEquityGuardTrigger = 0;
}

//+------------------------------------------------------------------+
//| Initialize break-even protection                                   |
//+------------------------------------------------------------------+
void InitializeBreakEvenProtection()
{
    breakEvenActivated = false;
    
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    if(UseBreakEvenPercent)
    {
        breakEvenTriggerThreshold = currentBalance * BreakEvenTriggerPercent / 100.0;
    }
    else
    {
        breakEvenTriggerThreshold = BreakEvenTriggerAmount;
    }
    
    if(UseBreakEvenClosePercent)
    {
        breakEvenCloseThreshold = currentBalance * BreakEvenClosePercent / 100.0;
    }
    else
    {
        breakEvenCloseThreshold = BreakEvenCloseAmount;
    }
}

//+------------------------------------------------------------------+
//| Check break-even protection                                        |
//+------------------------------------------------------------------+
void CheckBreakEvenProtection()
{
    if(!UseBreakEvenProtection || CountOpenPositions(false) == 0)
        return;
    
    double currentPL = GetCurrentBasketPL();
    
    if(!breakEvenActivated && currentPL >= breakEvenTriggerThreshold)
    {
        breakEvenActivated = true;
        Print("=== BREAK-EVEN PROTECTION ACTIVATED ===");
        Print("Trigger Threshold: $", DoubleToString(breakEvenTriggerThreshold, 2));
        Print("Current P/L: $", DoubleToString(currentPL, 2));
        Print("Will close at: $", DoubleToString(breakEvenCloseThreshold, 2));
        
        if(EnableTelegramNotifications && NotifyBreakEven)
        {
            string content = "Break-Even Protection ACTIVATED!\n";
            content += "Trigger: $" + DoubleToString(breakEvenTriggerThreshold, 2) + "\n";
            content += "Current P/L: $" + DoubleToString(currentPL, 2) + "\n";
            content += "Will close at: $" + DoubleToString(breakEvenCloseThreshold, 2);
            
            SendTelegramMessage(FormatTelegramMessage("BREAK-EVEN ACTIVATED", content));
        }
    }
    
    if(breakEvenActivated && currentPL <= breakEvenCloseThreshold)
    {
        Print("=== BREAK-EVEN PROTECTION TRIGGERED ===");
        Print("Close Threshold: $", DoubleToString(breakEvenCloseThreshold, 2));
        Print("Current P/L: $", DoubleToString(currentPL, 2));
        Print("Closing all positions at break-even...");
        
        if(EnableTelegramNotifications && NotifyBreakEven)
        {
            string content = "Break-Even Protection TRIGGERED!\n";
            content += "Close Level: $" + DoubleToString(breakEvenCloseThreshold, 2) + "\n";
            content += "Final P/L: $" + DoubleToString(currentPL, 2) + "\n";
            content += "All positions closed";
            
            SendTelegramMessage(FormatTelegramMessage("BREAK-EVEN TRIGGERED", content));
        }
        
        CloseAllPositionsAndGrid("Break-even protection triggered");
        breakEvenActivated = false;
    }
}

//+------------------------------------------------------------------+
//| Check equity guard                                                 |
//+------------------------------------------------------------------+
void CheckEquityGuard()
{
    if(!UseEquityGuard)
        return;
    
    // Only check when positions are open
    if(CountOpenPositions(false) == 0)
        return;
    
    // Check if already triggered today
    datetime today = GetTradingDay();
    if(lastEquityGuardTrigger >= today)
        return;
    
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double floatingPL = currentEquity - currentBalance;
    
    bool shouldTrigger = false;
    
    if(EquityGuardUsesProfit)
    {
        // Trigger on profit reaching threshold
        if(floatingPL >= equityGuardThreshold)
            shouldTrigger = true;
    }
    else
    {
        // Trigger on loss reaching threshold
        if(floatingPL <= -equityGuardThreshold)
            shouldTrigger = true;
    }
    
    if(shouldTrigger)
    {
        lastEquityGuardTrigger = TimeCurrent();
        
        Print("=== EQUITY GUARD TRIGGERED ===");
        Print("Threshold: ", (EquityGuardUsesProfit ? "+" : "-"), "$", DoubleToString(equityGuardThreshold, 2));
        Print("Current Floating P/L: $", DoubleToString(floatingPL, 2));
        Print("Closing all positions for this signal...");
        
        if(EnableTelegramNotifications && NotifyOnLimits)
        {
            string content = "EQUITY GUARD TRIGGERED!\n";
            content += "Floating P/L: " + (floatingPL >= 0 ? "+" : "") + "$" + DoubleToString(floatingPL, 2) + "\n";
            content += "Threshold: " + (EquityGuardUsesProfit ? "+" : "-") + "$" + DoubleToString(equityGuardThreshold, 2) + "\n";
            content += "All positions closed";
            
            SendTelegramMessage(FormatTelegramMessage("EQUITY GUARD", content));
        }
        
        CloseAllPositionsAndGrid("Equity guard triggered");
    }
}

//+------------------------------------------------------------------+
//| Draw swing points on chart (Market Structure Detection)           |
//| Uses fractal method with ATR filtering and body-close confirmation|
//| Labels: SH = Swing High, SL = Swing Low                          |
//+------------------------------------------------------------------+
void DrawSwingPoints()
{
    // Clean up previous swing point objects
    ObjectsDeleteAll(0, "SwingH_");
    ObjectsDeleteAll(0, "SwingL_");
    ObjectsDeleteAll(0, "SwingHL_");
    ObjectsDeleteAll(0, "SwingLL_");
    swingPointCount = 0;
    
    // Get price data from the selected timeframe
    double highs[], lows[], opens[], closes[];
    datetime times[];
    ArraySetAsSeries(highs, true);
    ArraySetAsSeries(lows, true);
    ArraySetAsSeries(opens, true);
    ArraySetAsSeries(closes, true);
    ArraySetAsSeries(times, true);
    
    int barsNeeded = SwingPointLookback + SwingPointStrength + SwingConfirmBars + 1;
    
    if(CopyHigh(_Symbol, SwingPointTimeframe, 0, barsNeeded, highs) <= 0) return;
    if(CopyLow(_Symbol, SwingPointTimeframe, 0, barsNeeded, lows) <= 0) return;
    if(CopyOpen(_Symbol, SwingPointTimeframe, 0, barsNeeded, opens) <= 0) return;
    if(CopyClose(_Symbol, SwingPointTimeframe, 0, barsNeeded, closes) <= 0) return;
    if(CopyTime(_Symbol, SwingPointTimeframe, 0, barsNeeded, times) <= 0) return;
    
    // Get ATR for minimum swing distance filtering
    double atrBuffer[];
    bool atrAvailable = false;
    if(UseATRSwingFilter && swingATRHandle != INVALID_HANDLE)
    {
        ArraySetAsSeries(atrBuffer, true);
        if(CopyBuffer(swingATRHandle, 0, 0, barsNeeded, atrBuffer) > 0)
            atrAvailable = true;
    }
    
    // Arrays to store swing point data for connecting lines
    double swingHighPrices[];
    datetime swingHighTimes[];
    double swingLowPrices[];
    datetime swingLowTimes[];
    ArrayResize(swingHighPrices, 0);
    ArrayResize(swingHighTimes, 0);
    ArrayResize(swingLowPrices, 0);
    ArrayResize(swingLowTimes, 0);
    
    // Track the last confirmed swing low for ATR distance checking against swing highs
    double lastFoundSwingLow = 0;
    double lastFoundSwingHigh = 0;
    
    // Scan for swing points
    // Start from SwingPointStrength + SwingConfirmBars to ensure we have confirmation bars
    int scanStart = SwingPointStrength + SwingConfirmBars;
    
    for(int i = scanStart; i < SwingPointLookback - SwingPointStrength; i++)
    {
        // === SWING HIGH DETECTION ===
        bool isSwingHigh = true;
        
        // Step 1: Fractal check - bar must be highest among N bars on each side
        for(int j = 1; j <= SwingPointStrength; j++)
        {
            if(highs[i] <= highs[i - j] || highs[i] <= highs[i + j])
            {
                isSwingHigh = false;
                break;
            }
        }
        
        // Step 2: Body-close confirmation - confirm swing by checking that
        // subsequent bars closed below the swing high (price moved away)
        if(isSwingHigh && UseBodyCloseConfirm)
        {
            bool confirmed = false;
            for(int k = 1; k <= SwingConfirmBars; k++)
            {
                int confirmIdx = i - k;  // bars AFTER the swing (more recent, lower index)
                if(confirmIdx >= 0)
                {
                    // The close of at least one confirmation bar must be below the swing high
                    if(closes[confirmIdx] < highs[i])
                    {
                        confirmed = true;
                        break;
                    }
                }
            }
            if(!confirmed) isSwingHigh = false;
        }
        
        // Step 3: ATR minimum distance filter - swing high to nearest swing low
        // must be at least SwingATRMinFactor * ATR to be considered significant
        if(isSwingHigh && atrAvailable && UseATRSwingFilter)
        {
            double localATR = atrBuffer[i];
            double minSwingDistance = localATR * SwingATRMinFactor;
            
            // Find the nearest swing low to this high (look within the strength window)
            double nearestLow = lows[i];
            for(int k = MathMax(0, i - SwingPointStrength); k <= MathMin(barsNeeded - 1, i + SwingPointStrength); k++)
            {
                if(lows[k] < nearestLow) nearestLow = lows[k];
            }
            
            // Also check against last found swing low if available
            if(lastFoundSwingLow > 0)
                nearestLow = MathMin(nearestLow, lastFoundSwingLow);
            
            double swingSize = highs[i] - nearestLow;
            if(swingSize < minSwingDistance)
                isSwingHigh = false;
        }
        
        // === SWING LOW DETECTION ===
        bool isSwingLow = true;
        
        // Step 1: Fractal check - bar must be lowest among N bars on each side
        for(int j = 1; j <= SwingPointStrength; j++)
        {
            if(lows[i] >= lows[i - j] || lows[i] >= lows[i + j])
            {
                isSwingLow = false;
                break;
            }
        }
        
        // Step 2: Body-close confirmation - confirm swing by checking that
        // subsequent bars closed above the swing low (price moved away)
        if(isSwingLow && UseBodyCloseConfirm)
        {
            bool confirmed = false;
            for(int k = 1; k <= SwingConfirmBars; k++)
            {
                int confirmIdx = i - k;  // bars AFTER the swing (more recent, lower index)
                if(confirmIdx >= 0)
                {
                    // The close of at least one confirmation bar must be above the swing low
                    if(closes[confirmIdx] > lows[i])
                    {
                        confirmed = true;
                        break;
                    }
                }
            }
            if(!confirmed) isSwingLow = false;
        }
        
        // Step 3: ATR minimum distance filter
        if(isSwingLow && atrAvailable && UseATRSwingFilter)
        {
            double localATR = atrBuffer[i];
            double minSwingDistance = localATR * SwingATRMinFactor;
            
            // Find the nearest swing high to this low (look within the strength window)
            double nearestHigh = highs[i];
            for(int k = MathMax(0, i - SwingPointStrength); k <= MathMin(barsNeeded - 1, i + SwingPointStrength); k++)
            {
                if(highs[k] > nearestHigh) nearestHigh = highs[k];
            }
            
            // Also check against last found swing high if available
            if(lastFoundSwingHigh > 0)
                nearestHigh = MathMax(nearestHigh, lastFoundSwingHigh);
            
            double swingSize = nearestHigh - lows[i];
            if(swingSize < minSwingDistance)
                isSwingLow = false;
        }
        
        // === DRAW SWING HIGH ===
        if(isSwingHigh)
        {
            lastFoundSwingHigh = highs[i];
            
            // Build label text: "SH" or "SH 1.23456"
            string labelText = "SH";
            if(ShowSwingPriceLabels)
                labelText = "SH " + DoubleToString(highs[i], _Digits);
            
            // Draw SH text label above the swing high candle
            string objName = "SwingH_" + IntegerToString(swingPointCount);
            ObjectCreate(0, objName, OBJ_TEXT, 0, times[i], highs[i]);
            ObjectSetString(0, objName, OBJPROP_TEXT, labelText);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, SwingHighColor);
            ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, SwingLabelFontSize);
            ObjectSetString(0, objName, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LOWER);
            ObjectSetString(0, objName, OBJPROP_TOOLTIP, "Swing High: " + DoubleToString(highs[i], _Digits) + 
                            " | TF: " + EnumToString(SwingPointTimeframe) + 
                            " | " + TimeToString(times[i], TIME_DATE|TIME_MINUTES));
            
            // Store for connecting lines
            int sz = ArraySize(swingHighPrices);
            ArrayResize(swingHighPrices, sz + 1);
            ArrayResize(swingHighTimes, sz + 1);
            swingHighPrices[sz] = highs[i];
            swingHighTimes[sz] = times[i];
            
            swingPointCount++;
        }
        
        // === DRAW SWING LOW ===
        if(isSwingLow)
        {
            lastFoundSwingLow = lows[i];
            
            // Build label text: "SL" or "SL 1.23456"
            string labelText = "SL";
            if(ShowSwingPriceLabels)
                labelText = "SL " + DoubleToString(lows[i], _Digits);
            
            // Draw SL text label below the swing low candle
            string objName = "SwingL_" + IntegerToString(swingPointCount);
            ObjectCreate(0, objName, OBJ_TEXT, 0, times[i], lows[i]);
            ObjectSetString(0, objName, OBJPROP_TEXT, labelText);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, SwingLowColor);
            ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, SwingLabelFontSize);
            ObjectSetString(0, objName, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetString(0, objName, OBJPROP_TOOLTIP, "Swing Low: " + DoubleToString(lows[i], _Digits) + 
                            " | TF: " + EnumToString(SwingPointTimeframe) + 
                            " | " + TimeToString(times[i], TIME_DATE|TIME_MINUTES));
            
            // Store for connecting lines
            int sz = ArraySize(swingLowPrices);
            ArrayResize(swingLowPrices, sz + 1);
            ArrayResize(swingLowTimes, sz + 1);
            swingLowPrices[sz] = lows[i];
            swingLowTimes[sz] = times[i];
            
            swingPointCount++;
        }
    }
    
    // Draw connecting lines between swing highs
    if(ConnectSwingHighs && ArraySize(swingHighPrices) >= 2)
    {
        for(int i = 0; i < ArraySize(swingHighPrices) - 1; i++)
        {
            string lineName = "SwingHL_Line_" + IntegerToString(i);
            if(ObjectFind(0, lineName) >= 0) ObjectDelete(0, lineName);
            ObjectCreate(0, lineName, OBJ_TREND, 0, swingHighTimes[i], swingHighPrices[i], swingHighTimes[i+1], swingHighPrices[i+1]);
            ObjectSetInteger(0, lineName, OBJPROP_COLOR, SwingHighColor);
            ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(0, lineName, OBJPROP_BACK, true);
        }
    }
    
    // Draw connecting lines between swing lows
    if(ConnectSwingLows && ArraySize(swingLowPrices) >= 2)
    {
        for(int i = 0; i < ArraySize(swingLowPrices) - 1; i++)
        {
            string lineName = "SwingLL_Line_" + IntegerToString(i);
            if(ObjectFind(0, lineName) >= 0) ObjectDelete(0, lineName);
            ObjectCreate(0, lineName, OBJ_TREND, 0, swingLowTimes[i], swingLowPrices[i], swingLowTimes[i+1], swingLowPrices[i+1]);
            ObjectSetInteger(0, lineName, OBJPROP_COLOR, SwingLowColor);
            ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(0, lineName, OBJPROP_BACK, true);
        }
    }
    
    if(ShowDebugInfo)
        Print("Swing Points drawn: ", swingPointCount, " (SH+SL) on ", EnumToString(SwingPointTimeframe),
              " | ATR Filter: ", (UseATRSwingFilter && atrAvailable ? "ON" : "OFF"),
              " | Body Confirm: ", (UseBodyCloseConfirm ? "ON" : "OFF"));
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Find nearest swing point for stop loss                            |
//| For BUY: find nearest Swing Low BELOW entry price                 |
//| For SELL: find nearest Swing High ABOVE entry price               |
//+------------------------------------------------------------------+
double FindSwingPointForSL(double entryPrice, string tradeType)
{
    double highs[], lows[], opens[], closes[];
    datetime times[];
    ArraySetAsSeries(highs, true);
    ArraySetAsSeries(lows, true);
    ArraySetAsSeries(opens, true);
    ArraySetAsSeries(closes, true);
    ArraySetAsSeries(times, true);
    
    int barsNeeded = SwingSLLookback + SwingSLStrength + 2;
    
    if(CopyHigh(_Symbol, SwingSLTimeframe, 0, barsNeeded, highs) <= 0) return 0;
    if(CopyLow(_Symbol, SwingSLTimeframe, 0, barsNeeded, lows) <= 0) return 0;
    if(CopyOpen(_Symbol, SwingSLTimeframe, 0, barsNeeded, opens) <= 0) return 0;
    if(CopyClose(_Symbol, SwingSLTimeframe, 0, barsNeeded, closes) <= 0) return 0;
    if(CopyTime(_Symbol, SwingSLTimeframe, 0, barsNeeded, times) <= 0) return 0;
    
    double bestSwing = 0;
    int candidatesFound = 0;
    int candidatesSkippedPrice = 0;
    int candidatesSkippedConfirm = 0;
    
    Print("=== SWING SL SEARCH ===" );
    Print("Trade Type: ", tradeType, " | Entry Price: ", DoubleToString(entryPrice, _Digits));
    Print("Searching ", EnumToString(SwingSLTimeframe), " | Lookback: ", SwingSLLookback, " bars | Strength: ", SwingSLStrength);
    
    if(tradeType == "BUY")
    {
        // For BUY trades: find the nearest SWING LOW that is BELOW entry price
        // Example: BUY at 3000 -> skip swing lows at 3010, 3005 -> use swing low at 2990
        double bestDistance = DBL_MAX;
        
        for(int i = SwingSLStrength; i < SwingSLLookback - SwingSLStrength; i++)
        {
            // Check if this bar is a swing low (fractal)
            bool isSwingLow = true;
            for(int j = 1; j <= SwingSLStrength; j++)
            {
                if(lows[i] >= lows[i - j] || lows[i] >= lows[i + j])
                {
                    isSwingLow = false;
                    break;
                }
            }
            
            if(!isSwingLow) continue;
            
            candidatesFound++;
            
            // CRITICAL CHECK: Swing low must be BELOW the entry price
            // If BUY at 3000 and swing low is at 3010 -> SKIP (3010 >= 3000)
            // If BUY at 3000 and swing low is at 2990 -> VALID (2990 < 3000)
            if(lows[i] >= entryPrice)
            {
                candidatesSkippedPrice++;
                if(ShowDebugInfo)
                    Print("  Swing Low at ", DoubleToString(lows[i], _Digits), 
                          " (bar ", i, " @ ", TimeToString(times[i], TIME_DATE|TIME_MINUTES),
                          ") -> SKIPPED: above entry price ", DoubleToString(entryPrice, _Digits));
                continue;
            }
            
            // Body-close confirmation: at least one bar after the swing must have
            // closed above the swing low (price bounced off it, confirming the swing)
            bool confirmed = false;
            for(int k = i - 1; k >= MathMax(0, i - SwingSLStrength); k--)
            {
                if(closes[k] > lows[i])
                {
                    confirmed = true;
                    break;
                }
            }
            if(!confirmed)
            {
                candidatesSkippedConfirm++;
                if(ShowDebugInfo)
                    Print("  Swing Low at ", DoubleToString(lows[i], _Digits), 
                          " (bar ", i, ") -> SKIPPED: no body-close confirmation");
                continue;
            }
            
            // Valid candidate - check if it's the closest to entry price
            double distance = entryPrice - lows[i];
            
            if(ShowDebugInfo || distance < bestDistance)
                Print("  Swing Low at ", DoubleToString(lows[i], _Digits), 
                      " (bar ", i, " @ ", TimeToString(times[i], TIME_DATE|TIME_MINUTES),
                      ") -> VALID | Distance: ", DoubleToString(distance / _Point, 0), " points",
                      (distance < bestDistance ? " <- BEST SO FAR" : ""));
            
            if(distance < bestDistance)
            {
                bestDistance = distance;
                bestSwing = lows[i];
            }
        }
    }
    else if(tradeType == "SELL")
    {
        // For SELL trades: find the nearest SWING HIGH that is ABOVE entry price
        // Example: SELL at 3000 -> skip swing highs at 2990, 2995 -> use swing high at 3015
        double bestDistance = DBL_MAX;
        
        for(int i = SwingSLStrength; i < SwingSLLookback - SwingSLStrength; i++)
        {
            // Check if this bar is a swing high (fractal)
            bool isSwingHigh = true;
            for(int j = 1; j <= SwingSLStrength; j++)
            {
                if(highs[i] <= highs[i - j] || highs[i] <= highs[i + j])
                {
                    isSwingHigh = false;
                    break;
                }
            }
            
            if(!isSwingHigh) continue;
            
            candidatesFound++;
            
            // CRITICAL CHECK: Swing high must be ABOVE the entry price
            // If SELL at 3000 and swing high is at 2990 -> SKIP (2990 <= 3000)
            // If SELL at 3000 and swing high is at 3015 -> VALID (3015 > 3000)
            if(highs[i] <= entryPrice)
            {
                candidatesSkippedPrice++;
                if(ShowDebugInfo)
                    Print("  Swing High at ", DoubleToString(highs[i], _Digits), 
                          " (bar ", i, " @ ", TimeToString(times[i], TIME_DATE|TIME_MINUTES),
                          ") -> SKIPPED: below entry price ", DoubleToString(entryPrice, _Digits));
                continue;
            }
            
            // Body-close confirmation: at least one bar after the swing must have
            // closed below the swing high (price rejected from it, confirming the swing)
            bool confirmed = false;
            for(int k = i - 1; k >= MathMax(0, i - SwingSLStrength); k--)
            {
                if(closes[k] < highs[i])
                {
                    confirmed = true;
                    break;
                }
            }
            if(!confirmed)
            {
                candidatesSkippedConfirm++;
                if(ShowDebugInfo)
                    Print("  Swing High at ", DoubleToString(highs[i], _Digits), 
                          " (bar ", i, ") -> SKIPPED: no body-close confirmation");
                continue;
            }
            
            // Valid candidate - check if it's the closest to entry price
            double distance = highs[i] - entryPrice;
            
            if(ShowDebugInfo || distance < bestDistance)
                Print("  Swing High at ", DoubleToString(highs[i], _Digits), 
                      " (bar ", i, " @ ", TimeToString(times[i], TIME_DATE|TIME_MINUTES),
                      ") -> VALID | Distance: ", DoubleToString(distance / _Point, 0), " points",
                      (distance < bestDistance ? " <- BEST SO FAR" : ""));
            
            if(distance < bestDistance)
            {
                bestDistance = distance;
                bestSwing = highs[i];
            }
        }
    }
    
    // Summary log
    Print("--- Swing SL Search Results ---");
    Print("Total swing points found: ", candidatesFound);
    Print("Skipped (wrong side of entry): ", candidatesSkippedPrice);
    Print("Skipped (no body confirmation): ", candidatesSkippedConfirm);
    
    if(bestSwing > 0)
    {
        Print("SELECTED Swing Point: ", DoubleToString(bestSwing, _Digits), 
              " | Distance from entry: ", DoubleToString(MathAbs(entryPrice - bestSwing) / _Point, 0), " points");
    }
    else
    {
        Print("NO valid swing point found ", 
              (tradeType == "BUY" ? "below" : "above"), 
              " entry price ", DoubleToString(entryPrice, _Digits));
    }
    Print("=== END SWING SL SEARCH ===");
    
    return bestSwing;
}

//+------------------------------------------------------------------+
//| Check swing point stop loss condition                              |
//| Two modes: Price Level Stop or Body Break Close                    |
//+------------------------------------------------------------------+
void CheckSwingPointStopLoss()
{
    if(!swingSLActive || currentSwingSLPrice <= 0)
        return;
    
    if(CountOpenPositions(false) == 0)
    {
        swingSLActive = false;
        return;
    }
    
    if(UseSwingBodyBreakClose)
    {
        // === BODY BREAK CLOSE MODE ===
        // Only check on new bar of the specified timeframe
        datetime currentBarTime = iTime(_Symbol, SwingBodyBreakTF, 0);
        if(currentBarTime == lastSwingSLCheckTime)
            return;  // Already checked this bar
        lastSwingSLCheckTime = currentBarTime;
        
        // Get the PREVIOUS completed candle (bar index 1) on the body break timeframe
        double prevClose = iClose(_Symbol, SwingBodyBreakTF, 1);
        double prevOpen = iOpen(_Symbol, SwingBodyBreakTF, 1);
        
        if(prevClose <= 0 || prevOpen <= 0)
            return;  // Data not available
        
        bool bodyBreak = false;
        
        if(reverseGroup.type == "BUY")
        {
            // For BUY: body break means the candle body closed BELOW the swing SL level
            // Both open and close should be below, OR close must be below (bearish candle breaking down)
            if(prevClose < currentSwingSLPrice)
            {
                bodyBreak = true;
            }
        }
        else if(reverseGroup.type == "SELL")
        {
            // For SELL: body break means the candle body closed ABOVE the swing SL level
            if(prevClose > currentSwingSLPrice)
            {
                bodyBreak = true;
            }
        }
        
        if(bodyBreak)
        {
            double finalPL = GetCurrentBasketPL();
            
            Print("=== SWING SL BODY BREAK TRIGGERED ===");
            Print("Mode: Body Close Confirmation on ", EnumToString(SwingBodyBreakTF));
            Print("Position Type: ", reverseGroup.type);
            Print("Swing Point: ", DoubleToString(currentSwingRawPrice, _Digits));
            Print("SL Level (with buffer): ", DoubleToString(currentSwingSLPrice, _Digits));
            Print("Candle Close: ", DoubleToString(prevClose, _Digits));
            Print("Basket P/L at close: $", DoubleToString(finalPL, 2));
            
            // Send Telegram notification
            if(EnableTelegramNotifications && NotifyOnTrade)
            {
                string content = "SWING SL BODY BREAK TRIGGERED!\n";
                content += "Type: " + reverseGroup.type + "\n";
                content += "Swing Point: " + DoubleToString(currentSwingRawPrice, _Digits) + "\n";
                content += "SL Level: " + DoubleToString(currentSwingSLPrice, _Digits) + "\n";
                content += "Body Close: " + DoubleToString(prevClose, _Digits) + "\n";
                content += "Basket P/L: $" + DoubleToString(finalPL, 2) + "\n";
                content += "TF: " + EnumToString(SwingBodyBreakTF);
                
                SendTelegramMessage(FormatTelegramMessage("SWING SL HIT", content));
            }
            
            CloseAllPositionsAndGrid("Swing SL body break on " + EnumToString(SwingBodyBreakTF));
        }
    }
    else
    {
        // === PRICE LEVEL STOP MODE ===
        // Check on every tick if price has reached the swing SL level
        double currentPrice = 0;
        
        if(reverseGroup.type == "BUY")
            currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        else
            currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        bool slHit = false;
        
        if(reverseGroup.type == "BUY" && currentPrice <= currentSwingSLPrice)
            slHit = true;
        else if(reverseGroup.type == "SELL" && currentPrice >= currentSwingSLPrice)
            slHit = true;
        
        if(slHit)
        {
            double finalPL = GetCurrentBasketPL();
            
            Print("=== SWING SL PRICE LEVEL HIT ===");
            Print("Mode: Immediate Price Level Stop");
            Print("Position Type: ", reverseGroup.type);
            Print("Swing Point: ", DoubleToString(currentSwingRawPrice, _Digits));
            Print("SL Level (with buffer): ", DoubleToString(currentSwingSLPrice, _Digits));
            Print("Current Price: ", DoubleToString(currentPrice, _Digits));
            Print("Basket P/L at close: $", DoubleToString(finalPL, 2));
            
            // Send Telegram notification
            if(EnableTelegramNotifications && NotifyOnTrade)
            {
                string content = "SWING SL PRICE LEVEL HIT!\n";
                content += "Type: " + reverseGroup.type + "\n";
                content += "Swing Point: " + DoubleToString(currentSwingRawPrice, _Digits) + "\n";
                content += "SL Level: " + DoubleToString(currentSwingSLPrice, _Digits) + "\n";
                content += "Price: " + DoubleToString(currentPrice, _Digits) + "\n";
                content += "Basket P/L: $" + DoubleToString(finalPL, 2);
                
                SendTelegramMessage(FormatTelegramMessage("SWING SL HIT", content));
            }
            
            CloseAllPositionsAndGrid("Swing SL price level hit");
        }
    }
}

//+------------------------------------------------------------------+
//| Draw swing SL line on chart                                        |
//+------------------------------------------------------------------+
void DrawSwingSLLine()
{
    // Delete previous swing SL line
    ObjectsDeleteAll(0, "SwingSL_");
    
    if(currentSwingSLPrice <= 0)
        return;
    
    // Draw the SL level line (with buffer)
    string slLineName = "SwingSL_Level";
    if(ObjectFind(0, slLineName) >= 0) ObjectDelete(0, slLineName);
    ObjectCreate(0, slLineName, OBJ_HLINE, 0, 0, currentSwingSLPrice);
    ObjectSetInteger(0, slLineName, OBJPROP_COLOR, SwingSLLineColor);
    ObjectSetInteger(0, slLineName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, slLineName, OBJPROP_WIDTH, 2);
    ObjectSetString(0, slLineName, OBJPROP_TOOLTIP, "Swing SL: " + DoubleToString(currentSwingSLPrice, _Digits) + 
                    " (Raw: " + DoubleToString(currentSwingRawPrice, _Digits) + 
                    " + " + DoubleToString(SwingSLBufferPoints, 0) + "pt buffer)" +
                    " | Mode: " + (UseSwingBodyBreakClose ? "Body Break" : "Price Level"));
    
    // Draw the raw swing point level (dotted, thinner)
    string rawLineName = "SwingSL_Raw";
    if(ObjectFind(0, rawLineName) >= 0) ObjectDelete(0, rawLineName);
    ObjectCreate(0, rawLineName, OBJ_HLINE, 0, 0, currentSwingRawPrice);
    ObjectSetInteger(0, rawLineName, OBJPROP_COLOR, SwingSLLineColor);
    ObjectSetInteger(0, rawLineName, OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, rawLineName, OBJPROP_WIDTH, 1);
    ObjectSetString(0, rawLineName, OBJPROP_TOOLTIP, "Swing Point (raw): " + DoubleToString(currentSwingRawPrice, _Digits));
    
    // Draw label for SL line
    string lblName = "SwingSL_Label";
    if(ObjectFind(0, lblName) >= 0) ObjectDelete(0, lblName);
    ObjectCreate(0, lblName, OBJ_TEXT, 0, TimeCurrent(), currentSwingSLPrice);
    string modeText = UseSwingBodyBreakClose ? " [Body Break]" : " [Price Stop]";
    ObjectSetString(0, lblName, OBJPROP_TEXT, "Swing SL " + DoubleToString(currentSwingSLPrice, _Digits) + modeText);
    ObjectSetInteger(0, lblName, OBJPROP_COLOR, SwingSLLineColor);
    ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, lblName, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT);
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Find nearest swing point for take profit                          |
//| For BUY: find nearest Swing High ABOVE entry price                |
//| For SELL: find nearest Swing Low BELOW entry price                |
//+------------------------------------------------------------------+
double FindSwingPointForTP(double entryPrice, string tradeType)
{
    double highs[], lows[], opens[], closes[];
    datetime times[];
    ArraySetAsSeries(highs, true);
    ArraySetAsSeries(lows, true);
    ArraySetAsSeries(opens, true);
    ArraySetAsSeries(closes, true);
    ArraySetAsSeries(times, true);
    
    int barsNeeded = SwingTPLookback + SwingTPStrength + 2;
    
    if(CopyHigh(_Symbol, SwingTPTimeframe, 0, barsNeeded, highs) <= 0) return 0;
    if(CopyLow(_Symbol, SwingTPTimeframe, 0, barsNeeded, lows) <= 0) return 0;
    if(CopyOpen(_Symbol, SwingTPTimeframe, 0, barsNeeded, opens) <= 0) return 0;
    if(CopyClose(_Symbol, SwingTPTimeframe, 0, barsNeeded, closes) <= 0) return 0;
    if(CopyTime(_Symbol, SwingTPTimeframe, 0, barsNeeded, times) <= 0) return 0;
    
    double bestSwing = 0;
    int candidatesFound = 0;
    int candidatesSkippedPrice = 0;
    int candidatesSkippedConfirm = 0;
    
    Print("=== SWING TP SEARCH ===" );
    Print("Trade Type: ", tradeType, " | Entry Price: ", DoubleToString(entryPrice, _Digits));
    Print("Searching ", EnumToString(SwingTPTimeframe), " | Lookback: ", SwingTPLookback, " bars | Strength: ", SwingTPStrength);
    
    if(tradeType == "BUY")
    {
        // For BUY trades: find the nearest SWING HIGH that is ABOVE entry price for TP
        double bestDistance = DBL_MAX;
        
        for(int i = SwingTPStrength; i < SwingTPLookback - SwingTPStrength; i++)
        {
            // Check if this bar is a swing high
            bool isSwingHigh = true;
            for(int j = 1; j <= SwingTPStrength; j++)
            {
                if(highs[i] <= highs[i - j] || highs[i] <= highs[i + j])
                {
                    isSwingHigh = false;
                    break;
                }
            }
            
            if(!isSwingHigh) continue;
            
            candidatesFound++;
            
            // Swing high must be ABOVE the entry price for TP
            if(highs[i] <= entryPrice)
            {
                candidatesSkippedPrice++;
                if(ShowDebugInfo)
                    Print("  Swing High at ", DoubleToString(highs[i], _Digits), 
                          " (bar ", i, " @ ", TimeToString(times[i], TIME_DATE|TIME_MINUTES),
                          ") -> SKIPPED: below or at entry price ", DoubleToString(entryPrice, _Digits));
                continue;
            }
            
            // Body-close confirmation: at least one bar after the swing must have
            // closed below the swing high (price rejected from it)
            bool confirmed = false;
            for(int k = i - 1; k >= MathMax(0, i - SwingTPStrength); k--)
            {
                if(closes[k] < highs[i])
                {
                    confirmed = true;
                    break;
                }
            }
            if(!confirmed)
            {
                candidatesSkippedConfirm++;
                if(ShowDebugInfo)
                    Print("  Swing High at ", DoubleToString(highs[i], _Digits), 
                          " (bar ", i, ") -> SKIPPED: no body-close confirmation");
                continue;
            }
            
            // Valid candidate - check if it's the closest to entry price
            double distance = highs[i] - entryPrice;
            
            if(ShowDebugInfo || distance < bestDistance)
                Print("  Swing High at ", DoubleToString(highs[i], _Digits), 
                      " (bar ", i, " @ ", TimeToString(times[i], TIME_DATE|TIME_MINUTES),
                      ") -> VALID | Distance: ", DoubleToString(distance / _Point, 0), " points",
                      (distance < bestDistance ? " <- BEST SO FAR" : ""));
            
            if(distance < bestDistance)
            {
                bestDistance = distance;
                bestSwing = highs[i];
            }
        }
    }
    else if(tradeType == "SELL")
    {
        // For SELL trades: find the nearest SWING LOW that is BELOW entry price for TP
        double bestDistance = DBL_MAX;
        
        for(int i = SwingTPStrength; i < SwingTPLookback - SwingTPStrength; i++)
        {
            // Check if this bar is a swing low
            bool isSwingLow = true;
            for(int j = 1; j <= SwingTPStrength; j++)
            {
                if(lows[i] >= lows[i - j] || lows[i] >= lows[i + j])
                {
                    isSwingLow = false;
                    break;
                }
            }
            
            if(!isSwingLow) continue;
            
            candidatesFound++;
            
            // Swing low must be BELOW the entry price
            if(lows[i] >= entryPrice)
            {
                candidatesSkippedPrice++;
                if(ShowDebugInfo)
                    Print("  Swing Low at ", DoubleToString(lows[i], _Digits), 
                          " (bar ", i, " @ ", TimeToString(times[i], TIME_DATE|TIME_MINUTES),
                          ") -> SKIPPED: above or at entry price ", DoubleToString(entryPrice, _Digits));
                continue;
            }
            
            // Body-close confirmation: at least one bar after the swing must have
            // closed above the swing low (price bounced off it)
            bool confirmed = false;
            for(int k = i - 1; k >= MathMax(0, i - SwingTPStrength); k--)
            {
                if(closes[k] > lows[i])
                {
                    confirmed = true;
                    break;
                }
            }
            if(!confirmed)
            {
                candidatesSkippedConfirm++;
                if(ShowDebugInfo)
                    Print("  Swing Low at ", DoubleToString(lows[i], _Digits), 
                          " (bar ", i, ") -> SKIPPED: no body-close confirmation");
                continue;
            }
            
            // Valid candidate - check if it's the closest to entry price
            double distance = entryPrice - lows[i];
            
            if(ShowDebugInfo || distance < bestDistance)
                Print("  Swing Low at ", DoubleToString(lows[i], _Digits), 
                      " (bar ", i, " @ ", TimeToString(times[i], TIME_DATE|TIME_MINUTES),
                      ") -> VALID | Distance: ", DoubleToString(distance / _Point, 0), " points",
                      (distance < bestDistance ? " <- BEST SO FAR" : ""));
            
            if(distance < bestDistance)
            {
                bestDistance = distance;
                bestSwing = lows[i];
            }
        }
    }
    
    // Summary log
    Print("--- Swing TP Search Results ---");
    Print("Total swing points found: ", candidatesFound);
    Print("Skipped (wrong side of entry): ", candidatesSkippedPrice);
    Print("Skipped (no body confirmation): ", candidatesSkippedConfirm);
    
    if(bestSwing > 0)
    {
        Print("SELECTED Swing Point TP: ", DoubleToString(bestSwing, _Digits), 
              " | Distance from entry: ", DoubleToString(MathAbs(entryPrice - bestSwing) / _Point, 0), " points");
    }
    else
    {
        Print("NO valid swing point found ", 
              (tradeType == "BUY" ? "above" : "below"), 
              " entry price ", DoubleToString(entryPrice, _Digits));
    }
    Print("=== END SWING TP SEARCH ===");
    
    return bestSwing;
}

//+------------------------------------------------------------------+
//| Check dynamic take profit condition                                |
//+------------------------------------------------------------------+
void CheckDynamicTakeProfit()
{
    if(!dynamicTPActive || currentDynamicTPPrice <= 0)
        return;
    
    if(CountOpenPositions(false) == 0)
    {
        dynamicTPActive = false;
        return;
    }
    
    double currentPrice = 0;
    
    if(reverseGroup.type == "BUY")
        currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    else
        currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    bool tpHit = false;
    
    if(reverseGroup.type == "BUY" && currentPrice >= currentDynamicTPPrice)
        tpHit = true;
    else if(reverseGroup.type == "SELL" && currentPrice <= currentDynamicTPPrice)
        tpHit = true;
    
    if(tpHit)
    {
        double finalPL = GetCurrentBasketPL();
        string reasonStr = "Dynamic TP hit (" + activeTPMode + ")";
        
        Print("=== DYNAMIC TAKE PROFIT HIT ===");
        Print("Mode: ", activeTPMode);
        Print("Position Type: ", reverseGroup.type);
        Print("TP Level: ", DoubleToString(currentDynamicTPPrice, _Digits));
        Print("Current Price: ", DoubleToString(currentPrice, _Digits));
        Print("Basket P/L at close: $", DoubleToString(finalPL, 2));
        
        // Send Telegram notification
        if(EnableTelegramNotifications && NotifyOnProfit)
        {
            string content = "DYNAMIC TP HIT (" + activeTPMode + ")!\n";
            content += "Type: " + reverseGroup.type + "\n";
            content += "TP Level: " + DoubleToString(currentDynamicTPPrice, _Digits) + "\n";
            content += "Price: " + DoubleToString(currentPrice, _Digits) + "\n";
            content += "Basket P/L: $" + DoubleToString(finalPL, 2);
            
            SendTelegramMessage(FormatTelegramMessage("PROFIT TARGET HIT", content));
        }
        
        CloseAllPositionsAndGrid(reasonStr);
    }
}

//+------------------------------------------------------------------+
//| Draw dynamic TP line on chart                                      |
//+------------------------------------------------------------------+
void DrawDynamicTPLine()
{
    // Delete previous dynamic TP line
    ObjectsDeleteAll(0, "DynamicTP_");
    
    if(currentDynamicTPPrice <= 0)
        return;
    
    // Draw the TP level line
    string tpLineName = "DynamicTP_Level";
    if(ObjectFind(0, tpLineName) >= 0) ObjectDelete(0, tpLineName);
    ObjectCreate(0, tpLineName, OBJ_HLINE, 0, 0, currentDynamicTPPrice);
    ObjectSetInteger(0, tpLineName, OBJPROP_COLOR, DynamicTPLineColor);
    ObjectSetInteger(0, tpLineName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, tpLineName, OBJPROP_WIDTH, 2);
    ObjectSetString(0, tpLineName, OBJPROP_TOOLTIP, "Dynamic TP (" + activeTPMode + "): " + DoubleToString(currentDynamicTPPrice, _Digits));
    
    // Draw label for TP line
    string lblName = "DynamicTP_Label";
    if(ObjectFind(0, lblName) >= 0) ObjectDelete(0, lblName);
    ObjectCreate(0, lblName, OBJ_TEXT, 0, TimeCurrent(), currentDynamicTPPrice);
    ObjectSetString(0, lblName, OBJPROP_TEXT, " TP (" + activeTPMode + ") " + DoubleToString(currentDynamicTPPrice, _Digits));
    ObjectSetInteger(0, lblName, OBJPROP_COLOR, DynamicTPLineColor);
    ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, lblName, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT);
    
    ChartRedraw(0);
}
//+------------------------------------------------------------------+