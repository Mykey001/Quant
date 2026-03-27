import { useRoute, Link } from "wouter";
import { useRunDetail } from "@/hooks/use-runs";
import { Card, CardContent, CardHeader, CardTitle, Badge, Button } from "@/components/ui";
import { ArrowLeft, CheckCircle2, CircleDashed, Loader2, XCircle, AlertCircle, BarChart3 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { EquityCurveChart } from "@/components/chart";

export default function RunDetail() {
  const [, params] = useRoute("/runs/:id");
  const id = parseInt(params?.id || "0", 10);
  
  const { runQuery, stepsQuery } = useRunDetail(id);
  const run = runQuery.data;
  const steps = stepsQuery.data || [];

  const PIPELINE_STEPS = [
    "Strategy Deconstruction",
    "Data Collection & Prep",
    "Baseline Backtest",
    "Market Regime Segmentation",
    "Model Training & Adaptation",
    "Parameter Optimization",
    "Validation (Out-of-Sample)",
    "Walk-Forward Analysis",
    "Risk & Failure Analysis",
    "Final Output"
  ];

  if (runQuery.isLoading) {
    return <div className="p-8 text-center text-primary font-mono animate-pulse">CONNECTING_TO_CORE...</div>;
  }

  if (!run) {
    return <div className="p-8 text-center text-danger font-mono">OP_NOT_FOUND</div>;
  }

  const isPipelineActive = run.status === 'running';

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center gap-4 border-b border-border/50 pb-6">
        <Link href="/runs">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-display font-bold tracking-tight glow-text flex items-center gap-3">
            Operation Pipeline #{run.id.toString().padStart(4, '0')}
            {isPipelineActive && <span className="flex h-3 w-3 rounded-full bg-primary animate-ping ml-2" />}
          </h1>
          <div className="flex items-center gap-3 mt-1 text-sm text-muted-foreground font-mono">
            <span>Target: STRAT_{run.strategyId}</span>
            <span>•</span>
            <Badge variant={
              run.status === 'completed' ? 'success' :
              run.status === 'failed' ? 'danger' :
              run.status === 'running' ? 'pending' : 'warning'
            }>
              {run.status}
            </Badge>
          </div>
        </div>
      </div>

      {/* Main Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left Column: Pipeline Visualizer */}
        <div className="lg:col-span-1 space-y-4">
          <h3 className="font-mono text-sm text-muted-foreground uppercase tracking-wider mb-2">Execution Sequence</h3>
          <div className="relative border-l border-border/50 ml-4 space-y-6">
            {PIPELINE_STEPS.map((stepName, index) => {
              const stepNumber = index + 1;
              const stepResult = steps.find(s => s.stepNumber === stepNumber);
              const status = stepResult?.status || (run.currentStep === stepNumber && run.status === 'running' ? 'running' : 'pending');
              
              const isActive = status === 'running';
              const isCompleted = status === 'completed';
              const isFailed = status === 'failed';

              return (
                <div key={stepNumber} className="relative pl-6">
                  {/* Timeline Dot */}
                  <div className={`absolute -left-[9px] top-1 h-4 w-4 rounded-full border-2 bg-background flex items-center justify-center
                    ${isCompleted ? 'border-success text-success shadow-[0_0_8px_rgba(16,185,129,0.5)]' : 
                      isActive ? 'border-primary text-primary shadow-[0_0_8px_rgba(6,182,212,0.5)] animate-pulse' : 
                      isFailed ? 'border-danger text-danger shadow-[0_0_8px_rgba(239,68,68,0.5)]' : 
                      'border-muted-foreground/30'}`}
                  >
                    {isCompleted ? <CheckCircle2 className="h-4 w-4 bg-background rounded-full" /> :
                     isFailed ? <XCircle className="h-4 w-4 bg-background rounded-full" /> :
                     isActive ? <div className="h-1.5 w-1.5 rounded-full bg-primary" /> : null}
                  </div>
                  
                  <div className={`font-mono text-sm transition-colors duration-300
                    ${isCompleted ? 'text-foreground' : 
                      isActive ? 'text-primary font-semibold glow-text' : 
                      isFailed ? 'text-danger' : 
                      'text-muted-foreground'}`}
                  >
                    Step {stepNumber.toString().padStart(2, '0')}: {stepName}
                  </div>
                  
                  {/* Active Step Details */}
                  <AnimatePresence>
                    {isActive && (
                      <motion.div 
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: 'auto' }}
                        exit={{ opacity: 0, height: 0 }}
                        className="mt-2 text-xs font-mono text-muted-foreground border border-primary/20 bg-primary/5 p-2 rounded-sm"
                      >
                        <div className="flex items-center gap-2">
                          <Loader2 className="h-3 w-3 animate-spin text-primary" />
                          Processing neural arrays...
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Column: Active/Completed Step Details & Metrics */}
        <div className="lg:col-span-2 space-y-6">
          {/* Global Summary (if completed/failed) */}
          {run.summary && (
            <Card className={run.status === 'failed' ? 'border-danger/30' : 'border-success/30'}>
              <CardHeader className="bg-transparent pb-2">
                <CardTitle className={`flex items-center gap-2 text-base ${run.status === 'failed' ? 'text-danger' : 'text-success'}`}>
                  {run.status === 'failed' ? <AlertCircle className="h-4 w-4" /> : <CheckCircle2 className="h-4 w-4" />}
                  SYSTEM_VERDICT
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="font-mono text-sm text-foreground/90 leading-relaxed whitespace-pre-wrap">
                  {run.summary}
                </p>
                {run.errorMessage && (
                  <div className="mt-4 p-3 bg-danger/10 text-danger border border-danger/20 rounded-sm font-mono text-xs">
                    FATAL_ERROR: {run.errorMessage}
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Detailed Step Cards (Reverse chron or just completed ones) */}
          <div className="space-y-4">
            {steps.sort((a,b) => b.stepNumber - a.stepNumber).map(step => (
              <Card key={step.id} className={`transition-all ${step.status === 'running' ? 'border-primary shadow-[0_0_15px_rgba(6,182,212,0.1)]' : ''}`}>
                <CardHeader className="py-3 border-b border-border/50 bg-panel/30">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base font-display flex items-center gap-2">
                      <span className="font-mono text-muted-foreground text-sm">#{step.stepNumber.toString().padStart(2,'0')}</span> 
                      {step.stepName}
                    </CardTitle>
                    {step.status === 'running' ? (
                      <Badge variant="pending" className="animate-pulse">ANALYZING</Badge>
                    ) : step.status === 'completed' ? (
                      <Badge variant="success">LOG_SECURED</Badge>
                    ) : (
                      <Badge variant="danger">HALTED</Badge>
                    )}
                  </div>
                </CardHeader>
                <CardContent className="pt-4 space-y-4">
                  {step.findings && (
                    <div>
                      <p className="font-mono text-sm text-foreground/80 leading-relaxed whitespace-pre-wrap">
                        {step.findings}
                      </p>
                    </div>
                  )}

                  {/* Render Charts if Metrics are heavily involved (e.g. Backtest, Walk-Forward) */}
                  {step.metrics && Object.keys(step.metrics).length > 0 && (
                    <div className="mt-4 border border-border/50 rounded-md overflow-hidden bg-background/50">
                      <div className="p-2 bg-panel border-b border-border/50 flex items-center gap-2 text-xs font-mono text-primary">
                        <BarChart3 className="h-3 w-3" /> PERFORMANCE_METRICS
                      </div>
                      
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-px bg-border/50">
                        {Object.entries(step.metrics).map(([key, val]) => (
                          typeof val === 'number' || typeof val === 'string' ? (
                            <div key={key} className="bg-surface p-3 flex flex-col items-center text-center">
                              <span className="text-[10px] uppercase tracking-widest text-muted-foreground font-mono mb-1">
                                {key.replace(/([A-Z])/g, ' $1').trim()}
                              </span>
                              <span className={`font-mono font-bold ${
                                key.toLowerCase().includes('profit') || (typeof val === 'number' && val > 0 && !key.toLowerCase().includes('drawdown')) ? 'text-success' : 
                                key.toLowerCase().includes('drawdown') || (typeof val === 'number' && val < 0) ? 'text-danger' : 
                                'text-white'
                              }`}>
                                {typeof val === 'number' && key.toLowerCase().includes('factor') ? val.toFixed(2) :
                                 typeof val === 'number' && key.toLowerCase().includes('rate') ? `${(val*100).toFixed(1)}%` :
                                 typeof val === 'number' ? val.toLocaleString() : val}
                              </span>
                            </div>
                          ) : null
                        ))}
                      </div>

                      {/* Display chart specifically for backtest/validation steps to look awesome */}
                      {(step.stepNumber === 3 || step.stepNumber === 7 || step.stepNumber === 8) && (
                        <div className="p-4 bg-surface/50 border-t border-border/50">
                           <EquityCurveChart data={[]} />
                        </div>
                      )}
                    </div>
                  )}

                  {step.recommendations && (
                    <div className="mt-2 p-3 bg-primary/5 border border-primary/20 rounded-sm">
                      <p className="font-mono text-xs text-primary/90 flex gap-2">
                        <span className="font-bold text-primary shrink-0">AI_ADVICE:</span>
                        <span>{step.recommendations}</span>
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            ))}
            
            {steps.length === 0 && !isPipelineActive && (
               <div className="p-8 text-center text-muted-foreground font-mono border border-dashed border-border rounded-md">
                 AWAITING_TELEMETRY
               </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
