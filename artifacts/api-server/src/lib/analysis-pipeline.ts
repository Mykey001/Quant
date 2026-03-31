import { db } from "@workspace/db";
import { analysisRunsTable, stepResultsTable } from "@workspace/db";
import { eq, and } from "drizzle-orm";
import { GoogleGenerativeAI } from "@google/generative-ai";

const STEP_NAMES = [
  "Strategy Deconstruction",
  "Data Collection & Preparation",
  "Baseline Backtest",
  "Market Regime Segmentation",
  "Model Training & Adaptation",
  "Parameter Optimization",
  "Validation (Out-of-Sample)",
  "Walk-Forward Analysis",
  "Risk & Failure Analysis",
  "Final Output & Recommendations",
];

const STEP_PROMPTS: ((fileContent: string, fileType: string, previousSteps: string) => string)[] = [
  // Step 1: Strategy Deconstruction
  (fileContent, fileType, _prev) => `
You are a quantitative trading strategy analyst. Analyze the following ${fileType.toUpperCase()} trading strategy code/script:

\`\`\`${fileType}
${fileContent.slice(0, 8000)}
\`\`\`

Perform Step 1: Strategy Deconstruction. Provide:
1. Entry conditions analysis
2. Exit conditions analysis  
3. Risk management approach (SL/TP, position sizing)
4. Indicators and parameters used
5. Why trades are taken
6. Market conditions where strategy performs well vs poorly
7. Strategy classification (trend-following, mean reversion, breakout, hybrid, etc.)

Be specific and technical. Format with clear sections.`,

  // Step 2: Data Collection & Preparation
  (_fileContent, _fileType, prev) => `
Based on this strategy analysis:
${prev.slice(0, 2000)}

Perform Step 2: Data Collection & Preparation plan. Provide:
1. Recommended markets to test (prioritize XAUUSD, major forex pairs, indices)
2. Required timeframes (M1, M5, M15, H1, H4, D1)
3. Data quality requirements and preprocessing steps
4. Feature engineering recommendations:
   - Volatility metrics (ATR, standard deviation windows)
   - Trend strength indicators (ADX thresholds, slope calculations)
   - Market regime features

Return also a metrics JSON block like:
METRICS: {"marketsRequired": 5, "timeframesRequired": 6, "yearsOfData": 10, "featuresEngineered": 12}`,

  // Step 3: Baseline Backtest
  (_fileContent, _fileType, prev) => `
Based on the strategy analysis:
${prev.slice(0, 2000)}

Perform Step 3: Baseline Backtest analysis. Simulate expected results and provide:
1. Expected performance across different market types
2. Estimated baseline metrics:
   - Net profit range
   - Expected max drawdown range
   - Estimated win rate range
   - Profit factor estimate
   - Sharpe ratio estimate
3. Best-performing market conditions
4. Worst-performing scenarios

Return a metrics JSON block:
METRICS: {"expectedNetProfitPct": 45, "expectedMaxDrawdownPct": 18, "expectedWinRate": 0.52, "expectedProfitFactor": 1.6, "expectedSharpeRatio": 1.2, "bestMarket": "XAUUSD", "worstCondition": "ranging low volatility"}`,

  // Step 4: Market Regime Segmentation
  (_fileContent, _fileType, prev) => `
Based on strategy analysis:
${prev.slice(0, 2000)}

Perform Step 4: Market Regime Segmentation. Provide:
1. Define regime categories (trending up, trending down, ranging tight, ranging wide, high volatility, low volatility)
2. Regime detection methodology (ADX thresholds, ATR percentiles, etc.)
3. Expected strategy performance in each regime:
   - Mark "avoid zones" (regimes where strategy underperforms)
   - Mark "target zones" (regimes where strategy excels)
4. Recommended regime filters to implement

Return metrics JSON:
METRICS: {"trendingPerformance": "strong", "rangingPerformance": "weak", "highVolPerformance": "moderate", "avoidZones": ["tight ranging", "news events"], "targetZones": ["trending with momentum", "breakout sessions"]}`,

  // Step 5: Model Training
  (_fileContent, _fileType, prev) => `
Based on strategy analysis:
${prev.slice(0, 2000)}

Perform Step 5: Model Training & Adaptation plan. Provide:
1. Recommended ML model architecture for regime detection
2. Input features specification:
   - Volatility features
   - Trend features  
   - Momentum features
3. Model outputs (trade/no-trade decision or regime classification)
4. Training approach (Random Forest, XGBoost recommendations)
5. Expected improvement from ML filter
6. Overfitting prevention strategies

Return metrics JSON:
METRICS: {"recommendedModel": "XGBoost", "inputFeatures": 18, "expectedFilterImprovement": 22, "crossValidationFolds": 5, "estimatedAccuracy": 0.73}`,

  // Step 6: Parameter Optimization
  (_fileContent, _fileType, prev) => `
Based on strategy analysis:
${prev.slice(0, 2000)}

Perform Step 6: Parameter Optimization. Provide:
1. Parameters to optimize and their ranges
2. Optimization method recommendation (Grid Search, Bayesian, Genetic Algorithm)
3. Objective function definition
4. Cross-validation approach to prevent overfitting
5. Optimal parameter candidates
6. Stability analysis across parameter space

Return metrics JSON:
METRICS: {"parametersOptimized": 8, "optimizationMethod": "Bayesian", "iterations": 500, "bestSharpeImprovement": 0.35, "stabilityScore": 0.82, "overfitRisk": "low"}`,

  // Step 7: Validation
  (_fileContent, _fileType, prev) => `
Based on strategy analysis:
${prev.slice(0, 2000)}

Perform Step 7: Out-of-Sample Validation. Provide:
1. Data split methodology (70% train, 15% validation, 15% test)
2. No-data-leakage confirmation
3. Expected OOS performance metrics
4. Performance consistency analysis
5. Statistical significance tests
6. Comparison of IS vs OOS results

Return metrics JSON:
METRICS: {"trainSharpe": 1.45, "validationSharpe": 1.21, "testSharpe": 1.18, "trainMaxDD": 12, "testMaxDD": 15, "consistencyScore": 0.87, "dataLeakageRisk": "none"}`,

  // Step 8: Walk-Forward
  (_fileContent, _fileType, prev) => `
Based on strategy analysis:
${prev.slice(0, 2000)}

Perform Step 8: Walk-Forward Analysis. Provide:
1. Rolling window configuration (training window, test window sizes)
2. Number of walk-forward periods analyzed
3. Stability metrics across periods
4. Performance degradation analysis
5. Parameter stability over time
6. Regime shift detection

Return metrics JSON:
METRICS: {"totalPeriods": 20, "avgPeriodSharpe": 1.14, "minPeriodSharpe": 0.62, "maxPeriodSharpe": 1.89, "stabilityCoeff": 0.79, "avgRetrainFrequency": "quarterly"}`,

  // Step 9: Risk Analysis
  (_fileContent, _fileType, prev) => `
Based on strategy analysis:
${prev.slice(0, 2000)}

Perform Step 9: Risk & Failure Analysis. Provide:
1. Conditions that cause major drawdowns
2. Trade loss clustering analysis
3. Tail risk assessment
4. Recommended safeguards:
   - Volatility filters
   - Trade cooldown rules
   - Dynamic position sizing
5. Maximum position size recommendations
6. Circuit breaker conditions

Return metrics JSON:
METRICS: {"maxConsecutiveLosses": 7, "tailRiskVaR95": 3.2, "recommendedMaxRiskPerTrade": 1.5, "cooldownPeriodHours": 4, "volatilityFilterATRMultiple": 2.5, "circuitBreakerDrawdownPct": 8}`,

  // Step 10: Final Output
  (_fileContent, _fileType, prev) => `
Based on the complete analysis:
${prev.slice(0, 3000)}

Perform Step 10: Final Output & Recommendations. Provide:
1. Fully optimized strategy summary
2. Final parameter set recommendations
3. Market conditions to trade and avoid (specific rules)
4. Performance improvement summary (before vs after optimization)
5. Final risk metrics
6. Implementation checklist
7. Portfolio diversification suggestions
8. Ensemble strategy recommendations if applicable

Return final metrics JSON:
METRICS: {"finalSharpeRatio": 1.42, "finalSortinoRatio": 1.89, "finalMaxDrawdownPct": 11, "finalWinRate": 0.57, "finalProfitFactor": 1.92, "improvementVsBaseline": 35, "recommendedMarkets": ["XAUUSD", "EURUSD", "NQ", "GC"], "confidenceScore": 0.84}`,
];

function extractMetrics(text: string): Record<string, unknown> {
  const match = text.match(/METRICS:\s*(\{[\s\S]*?\})/);
  if (!match) return {};
  try {
    return JSON.parse(match[1]);
  } catch {
    return {};
  }
}

function cleanFindings(text: string): string {
  return text.replace(/METRICS:\s*\{[\s\S]*?\}/g, "").trim();
}

export async function runAnalysisPipeline(
  runId: number,
  strategyFileContent: string,
  fileType: string
): Promise<void> {
  const apiKey = process.env.GEMINI_API_KEY || "";
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not set.");
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const geminiModel = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

  let previousStepsSummary = "";

  for (let stepNumber = 1; stepNumber <= 10; stepNumber++) {
    const stepName = STEP_NAMES[stepNumber - 1];

    await db
      .update(analysisRunsTable)
      .set({ status: "running", currentStep: stepNumber, updatedAt: new Date() })
      .where(eq(analysisRunsTable.id, runId));

    await db
      .update(stepResultsTable)
      .set({ status: "running", startedAt: new Date() })
      .where(and(eq(stepResultsTable.runId, runId), eq(stepResultsTable.stepNumber, stepNumber)));

    try {
      const prompt = STEP_PROMPTS[stepNumber - 1](strategyFileContent, fileType, previousStepsSummary);

      const result = await geminiModel.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: {
          maxOutputTokens: 2048,
          temperature: 0.2,
        },
      });
      const response = await result.response;
      const rawText = response.text();
      const metrics = extractMetrics(rawText);
      const findings = cleanFindings(rawText);

      previousStepsSummary += `\n\n=== Step ${stepNumber}: ${stepName} ===\n${findings}`;

      await db
        .update(stepResultsTable)
        .set({
          status: "completed",
          findings,
          metrics,
          completedAt: new Date(),
        })
        .where(and(eq(stepResultsTable.runId, runId), eq(stepResultsTable.stepNumber, stepNumber)));
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      await db
        .update(stepResultsTable)
        .set({
          status: "failed",
          findings: `Error during analysis: ${errorMsg}`,
          completedAt: new Date(),
        })
        .where(and(eq(stepResultsTable.runId, runId), eq(stepResultsTable.stepNumber, stepNumber)));
    }
  }

  await db
    .update(analysisRunsTable)
    .set({
      status: "completed",
      currentStep: 10,
      summary: "Full 10-step quantitative analysis pipeline completed.",
      updatedAt: new Date(),
    })
    .where(eq(analysisRunsTable.id, runId));
}
