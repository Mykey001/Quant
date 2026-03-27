import { useState, useEffect } from "react";
import { useRoute, useLocation } from "wouter";
import { useStrategyDetail, useStrategiesHooks } from "@/hooks/use-strategies";
import { useStrategyParameters, useSaveParameters, type StrategyParameter } from "@/hooks/use-parameters";
import { Card, CardContent, CardHeader, CardTitle, Badge, Button } from "@/components/ui";
import {
  ArrowLeft, Play, FileText, Calendar, Info, AlertTriangle,
  SlidersHorizontal, Save, RotateCcw, ChevronDown, ChevronUp,
} from "lucide-react";
import { format } from "date-fns";
import { motion, AnimatePresence } from "framer-motion";

// ─── Parameter Input ─────────────────────────────────────────────────────────
function ParameterInput({
  param,
  value,
  onChange,
}: {
  param: StrategyParameter;
  value: string;
  onChange: (v: string) => void;
}) {
  const base =
    "w-full bg-[#0a0e17] border border-border/60 rounded px-3 py-1.5 text-sm font-mono text-foreground focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/40 transition-colors";

  if (param.type === "bool") {
    return (
      <select className={base} value={value} onChange={e => onChange(e.target.value)}>
        <option value="true">true</option>
        <option value="false">false</option>
        <option value="True">True</option>
        <option value="False">False</option>
      </select>
    );
  }

  if (param.type === "enum" && param.options && param.options.length > 0) {
    return (
      <select className={base} value={value} onChange={e => onChange(e.target.value)}>
        {param.options.map(opt => (
          <option key={opt} value={opt}>{opt}</option>
        ))}
      </select>
    );
  }

  if (param.type === "color") {
    return (
      <div className="flex gap-2 items-center">
        <input
          type="color"
          className="h-8 w-14 cursor-pointer rounded border border-border/60 bg-transparent p-0.5"
          value={value.startsWith("#") ? value : "#ffffff"}
          onChange={e => onChange(e.target.value)}
        />
        <input
          type="text"
          className={base}
          value={value}
          onChange={e => onChange(e.target.value)}
          placeholder="clrWhite or #FFFFFF"
        />
      </div>
    );
  }

  if (param.type === "int") {
    return (
      <input
        type="number"
        step="1"
        min={param.min ?? undefined}
        max={param.max ?? undefined}
        className={base}
        value={value}
        onChange={e => onChange(e.target.value)}
      />
    );
  }

  if (param.type === "double") {
    return (
      <input
        type="number"
        step="any"
        min={param.min ?? undefined}
        max={param.max ?? undefined}
        className={base}
        value={value}
        onChange={e => onChange(e.target.value)}
      />
    );
  }

  return (
    <input
      type="text"
      className={base}
      value={value}
      onChange={e => onChange(e.target.value)}
    />
  );
}

// ─── Parameters Card ─────────────────────────────────────────────────────────
function ParametersCard({ strategyId }: { strategyId: number }) {
  const { data: params, isLoading, isError } = useStrategyParameters(strategyId);
  const saveMutation = useSaveParameters(strategyId);

  const [edits, setEdits] = useState<Record<string, string>>({});
  const [saved, setSaved] = useState(false);
  const [collapsed, setCollapsed] = useState(false);

  // Initialise edits whenever params load/change
  useEffect(() => {
    if (!params) return;
    const initial: Record<string, string> = {};
    for (const p of params) initial[p.name] = p.value;
    setEdits(initial);
    setSaved(false);
  }, [params]);

  const isDirty = params?.some(p => edits[p.name] !== p.value) ?? false;

  const handleSave = () => {
    if (!params) return;
    const updated = params.map(p => ({ ...p, value: edits[p.name] ?? p.value }));
    saveMutation.mutate(updated, {
      onSuccess: () => {
        setSaved(true);
        setTimeout(() => setSaved(false), 2500);
      },
    });
  };

  const handleReset = () => {
    if (!params) return;
    const initial: Record<string, string> = {};
    for (const p of params) initial[p.name] = p.value;
    setEdits(initial);
  };

  if (isLoading) {
    return (
      <Card>
        <CardContent className="py-8 text-center text-muted-foreground font-mono text-sm animate-pulse">
          SCANNING INPUT PARAMS...
        </CardContent>
      </Card>
    );
  }

  if (isError || !params) {
    return (
      <Card className="border-destructive/30">
        <CardContent className="py-6 text-center text-muted-foreground font-mono text-sm">
          Could not parse parameters from this file type.
        </CardContent>
      </Card>
    );
  }

  if (params.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-sm">
            <SlidersHorizontal className="h-4 w-4 text-primary" /> Input Parameters
          </CardTitle>
        </CardHeader>
        <CardContent className="py-4 text-center text-muted-foreground font-mono text-xs">
          No input parameters detected in this strategy.
          <br />
          <span className="text-muted-foreground/60">
            MQ5: use <code className="text-primary">input</code> / PineScript: use <code className="text-primary">input()</code> / Python: UPPER_CASE constants
          </span>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="border-primary/20">
      <CardHeader className="border-b border-border/40 pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2 text-sm">
            <SlidersHorizontal className="h-4 w-4 text-primary" />
            Input Parameters
            <Badge variant="default" className="text-[10px] py-0 ml-1">{params.length}</Badge>
          </CardTitle>
          <div className="flex items-center gap-2">
            {isDirty && (
              <button
                onClick={handleReset}
                className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors font-mono"
              >
                <RotateCcw className="h-3 w-3" /> Reset
              </button>
            )}
            <Button
              variant="primary"
              size="sm"
              onClick={handleSave}
              disabled={!isDirty || saveMutation.isPending}
              isLoading={saveMutation.isPending}
              className="text-xs h-7 px-3"
            >
              {saved ? (
                <span className="text-success font-mono">✓ SAVED</span>
              ) : (
                <>
                  <Save className="h-3 w-3 mr-1" /> Save
                </>
              )}
            </Button>
            <button
              onClick={() => setCollapsed(c => !c)}
              className="text-muted-foreground hover:text-foreground transition-colors"
            >
              {collapsed ? <ChevronDown className="h-4 w-4" /> : <ChevronUp className="h-4 w-4" />}
            </button>
          </div>
        </div>
      </CardHeader>

      <AnimatePresence initial={false}>
        {!collapsed && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="overflow-hidden"
          >
            <CardContent className="pt-4">
              {saveMutation.isError && (
                <div className="mb-4 text-xs text-destructive font-mono bg-destructive/10 border border-destructive/30 rounded px-3 py-2">
                  Error saving: {(saveMutation.error as Error)?.message}
                </div>
              )}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-4">
                {params.map(param => (
                  <div key={param.name} className="space-y-1">
                    <div className="flex items-baseline justify-between">
                      <label className="text-xs font-medium text-foreground/90">
                        {param.label}
                      </label>
                      <span className="text-[10px] font-mono text-muted-foreground/60 uppercase tracking-wider">
                        {param.type}
                      </span>
                    </div>
                    <ParameterInput
                      param={param}
                      value={edits[param.name] ?? param.value}
                      onChange={v => {
                        setSaved(false);
                        setEdits(prev => ({ ...prev, [param.name]: v }));
                      }}
                    />
                    {param.description && (
                      <p className="text-[10px] text-muted-foreground/70 font-mono leading-tight">
                        {param.description}
                      </p>
                    )}
                    {(param.min != null || param.max != null) && (
                      <p className="text-[10px] text-muted-foreground/50 font-mono">
                        Range: {param.min ?? "−∞"} – {param.max ?? "+∞"}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </motion.div>
        )}
      </AnimatePresence>
    </Card>
  );
}

// ─── Main page ────────────────────────────────────────────────────────────────
export default function StrategyDetail() {
  const [, params] = useRoute("/strategies/:id");
  const id = parseInt(params?.id || "0", 10);
  const [, setLocation] = useLocation();

  const { data: strategy, isLoading, isError } = useStrategyDetail(id);
  const { analyzeMutation } = useStrategiesHooks();

  const handleAnalyze = () => {
    analyzeMutation.mutate(
      {
        id,
        data: {
          markets: ["XAUUSD", "EURUSD"],
          timeframes: ["H1", "D1"],
          yearsOfData: 5,
          trainSplit: 0.7,
          validationSplit: 0.3,
        },
      },
      { onSuccess: run => setLocation(`/runs/${run.id}`) }
    );
  };

  if (isLoading) {
    return (
      <div className="p-8 text-center text-primary font-mono animate-pulse">
        LOADING_DATA_STREAM...
      </div>
    );
  }

  if (isError || !strategy) {
    return (
      <div className="p-8 text-center text-danger font-mono">
        <AlertTriangle className="mx-auto h-12 w-12 mb-4" />
        ERROR: STRATEGY_NOT_FOUND
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => setLocation("/strategies")}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{strategy.name}</h1>
          <div className="flex items-center gap-3 mt-1 text-sm text-muted-foreground font-mono">
            <span>ID: {strategy.id.toString().padStart(4, "0")}</span>
            <span>•</span>
            <Badge variant="default" className="text-[10px] py-0">
              {strategy.fileType}
            </Badge>
          </div>
        </div>
        <div className="ml-auto">
          <Button
            variant="primary"
            size="lg"
            className="font-display tracking-wider font-bold shadow-[0_0_20px_rgba(6,182,212,0.4)]"
            onClick={handleAnalyze}
            isLoading={analyzeMutation.isPending}
          >
            <Play className="mr-2 h-5 w-5 fill-current" />
            INITIATE ANALYSIS
          </Button>
        </div>
      </div>

      {/* Body */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left column: meta + pipeline readiness + parameters */}
        <div className="lg:col-span-1 space-y-6">
          {/* Meta */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Info className="h-4 w-4 text-primary" /> Meta Data
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4 font-mono text-sm">
              <div>
                <span className="text-muted-foreground block text-xs">File Name</span>
                <span className="text-foreground">{strategy.fileName}</span>
              </div>
              <div>
                <span className="text-muted-foreground block text-xs">Detected Type</span>
                <Badge variant="warning" className="mt-1">
                  {strategy.strategyType || "UNKNOWN"}
                </Badge>
              </div>
              <div>
                <span className="text-muted-foreground block text-xs">Added On</span>
                <span className="text-foreground flex items-center gap-2 mt-1">
                  <Calendar className="h-3 w-3 text-muted-foreground" />
                  {format(new Date(strategy.createdAt), "PPpp")}
                </span>
              </div>
              {strategy.description && (
                <div>
                  <span className="text-muted-foreground block text-xs">Description</span>
                  <span className="text-foreground">{strategy.description}</span>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Pipeline readiness */}
          <Card className="border-primary/20 bg-primary/5">
            <CardHeader>
              <CardTitle className="text-primary text-sm uppercase tracking-widest">
                Pipeline Readiness
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="space-y-2 text-sm font-mono">
                <li className="flex items-center gap-2 text-success">
                  <span className="h-1.5 w-1.5 rounded-full bg-success" />
                  Syntax Validated
                </li>
                <li className="flex items-center gap-2 text-success">
                  <span className="h-1.5 w-1.5 rounded-full bg-success" />
                  Agent Systems Online
                </li>
                <li className="flex items-center gap-2 text-success">
                  <span className="h-1.5 w-1.5 rounded-full bg-success" />
                  Backtest Engine Ready
                </li>
              </ul>
            </CardContent>
          </Card>

          {/* Input Parameters */}
          <ParametersCard strategyId={id} />
        </div>

        {/* Right column: source code */}
        <div className="lg:col-span-2">
          <Card className="h-full flex flex-col">
            <CardHeader className="border-b border-border/50 bg-panel/50 flex-none">
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-4 w-4 text-primary" /> Source Code
              </CardTitle>
            </CardHeader>
            <CardContent className="flex-1 p-0 relative min-h-[500px]">
              <div className="absolute inset-0 overflow-auto terminal-scrollbar p-4 bg-[#0a0e17]">
                <pre className="text-[13px] leading-relaxed text-gray-300 font-mono">
                  <code>
                    {strategy.fileContent || "// Empty file or binary content unable to render."}
                  </code>
                </pre>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
