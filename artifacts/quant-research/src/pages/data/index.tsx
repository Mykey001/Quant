import { useState, useCallback, useRef } from "react";
import { useLocation } from "wouter";
import { useDropzone } from "react-dropzone";
import { motion, AnimatePresence } from "framer-motion";
import {
  AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
} from "recharts";
import {
  useDatasets, useDataset, useUploadDataset, useDeleteDataset, usePrepareDataset,
  type Dataset,
} from "@/hooks/use-datasets";
import { Card, CardContent, CardHeader, CardTitle, Badge, Button } from "@/components/ui";
import {
  Upload, Database, Trash2, Zap, ArrowLeft, ChevronRight, CheckCircle2,
  AlertTriangle, Clock, FileText, BarChart2, Calendar, Hash, Columns3,
  RefreshCw, Info,
} from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";

// ─── Helpers ──────────────────────────────────────────────────────────────────
const TIMEFRAMES = ["M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN"];
const COMMON_ASSETS = ["XAUUSD", "EURUSD", "GBPUSD", "USDJPY", "BTCUSD", "ETHUSD", "SPX500", "NAS100"];

function fmtDate(s: string | null) {
  if (!s) return "—";
  try { return format(new Date(s), "dd MMM yyyy"); } catch { return s; }
}

function fmtNum(n: number | null | undefined, decimals = 2) {
  if (n == null) return "—";
  return n.toLocaleString(undefined, { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
}

// ─── Upload Modal ─────────────────────────────────────────────────────────────
function UploadModal({ onClose }: { onClose: () => void }) {
  const [asset, setAsset] = useState("");
  const [timeframe, setTimeframe] = useState("");
  const [name, setName] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const uploadMutation = useUploadDataset();

  const onDrop = useCallback((accepted: File[]) => {
    if (accepted[0]) {
      setFile(accepted[0]);
      if (!name) setName(accepted[0].name.replace(/\.[^.]+$/, ""));
    }
  }, [name]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { "text/csv": [".csv"], "application/json": [".json"], "text/plain": [".txt"] },
    maxFiles: 1,
  });

  const handleSubmit = () => {
    if (!file) return;
    const fd = new FormData();
    fd.append("file", file);
    if (asset) fd.append("asset", asset);
    if (timeframe) fd.append("timeframe", timeframe);
    if (name) fd.append("name", name);
    uploadMutation.mutate(fd, { onSuccess: onClose });
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4"
    >
      <motion.div
        initial={{ scale: 0.95, y: 20 }}
        animate={{ scale: 1, y: 0 }}
        exit={{ scale: 0.95, y: 20 }}
        className="w-full max-w-lg glass-panel border border-border/60 rounded-xl p-6 space-y-5"
      >
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-bold font-display tracking-wide text-primary">IMPORT DATA FILE</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-white text-xl">&times;</button>
        </div>

        {/* Drop zone */}
        <div
          {...getRootProps()}
          className={cn(
            "border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors",
            isDragActive ? "border-primary bg-primary/10" : "border-border/50 hover:border-primary/60 hover:bg-primary/5",
          )}
        >
          <input {...getInputProps()} />
          <Upload className={cn("mx-auto h-10 w-10 mb-3", isDragActive ? "text-primary" : "text-muted-foreground")} />
          {file ? (
            <p className="font-mono text-sm text-foreground">{file.name} <span className="text-muted-foreground">({(file.size / 1024).toFixed(1)} KB)</span></p>
          ) : (
            <>
              <p className="font-mono text-sm text-muted-foreground">Drop CSV, JSON, or TXT file here</p>
              <p className="text-xs text-muted-foreground/60 mt-1">OHLCV, tick data, or any tabular market data</p>
            </>
          )}
        </div>

        {/* Metadata */}
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-xs text-muted-foreground font-mono">Dataset Name</label>
            <input
              className="w-full bg-[#0a0e17] border border-border/60 rounded px-3 py-2 text-sm font-mono focus:outline-none focus:border-primary"
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="e.g. XAUUSD Daily 2020-2024"
            />
          </div>
          <div className="space-y-1">
            <label className="text-xs text-muted-foreground font-mono">Asset Symbol</label>
            <input
              className="w-full bg-[#0a0e17] border border-border/60 rounded px-3 py-2 text-sm font-mono focus:outline-none focus:border-primary"
              value={asset}
              onChange={e => setAsset(e.target.value.toUpperCase())}
              placeholder="e.g. XAUUSD"
              list="asset-list"
            />
            <datalist id="asset-list">
              {COMMON_ASSETS.map(a => <option key={a} value={a} />)}
            </datalist>
          </div>
          <div className="space-y-1">
            <label className="text-xs text-muted-foreground font-mono">Timeframe</label>
            <select
              className="w-full bg-[#0a0e17] border border-border/60 rounded px-3 py-2 text-sm font-mono focus:outline-none focus:border-primary"
              value={timeframe}
              onChange={e => setTimeframe(e.target.value)}
            >
              <option value="">Auto-detect</option>
              {TIMEFRAMES.map(tf => <option key={tf} value={tf}>{tf}</option>)}
            </select>
          </div>
        </div>

        {uploadMutation.isError && (
          <p className="text-destructive text-xs font-mono bg-destructive/10 px-3 py-2 rounded">
            {uploadMutation.error.message}
          </p>
        )}

        <div className="flex gap-3 pt-1">
          <Button variant="ghost" className="flex-1" onClick={onClose}>Cancel</Button>
          <Button
            variant="primary"
            className="flex-1"
            onClick={handleSubmit}
            disabled={!file || uploadMutation.isPending}
            isLoading={uploadMutation.isPending}
          >
            <Upload className="h-4 w-4 mr-2" />
            {uploadMutation.isPending ? "Parsing..." : "Import Data"}
          </Button>
        </div>
      </motion.div>
    </motion.div>
  );
}

// ─── Dataset Card (list) ──────────────────────────────────────────────────────
function DatasetCard({ ds, onSelect, onDelete }: {
  ds: Dataset;
  onSelect: () => void;
  onDelete: () => void;
}) {
  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      className="group"
    >
      <Card
        className="border-border/40 hover:border-primary/40 transition-all cursor-pointer"
        onClick={onSelect}
      >
        <CardContent className="p-5">
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2 flex-wrap">
                <h3 className="font-semibold text-foreground truncate">{ds.name}</h3>
                {ds.asset && <Badge variant="default" className="text-[10px]">{ds.asset}</Badge>}
                {ds.timeframe && <Badge variant="warning" className="text-[10px]">{ds.timeframe}</Badge>}
                {ds.isPrepared && (
                  <Badge variant="success" className="text-[10px] flex items-center gap-1">
                    <CheckCircle2 className="h-2.5 w-2.5" /> Prepared
                  </Badge>
                )}
              </div>
              <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground font-mono">
                <span className="flex items-center gap-1"><Hash className="h-3 w-3" />{ds.rowCount.toLocaleString()} rows</span>
                <span className="flex items-center gap-1"><Columns3 className="h-3 w-3" />{ds.columns.length} cols</span>
                {ds.startDate && (
                  <span className="flex items-center gap-1">
                    <Calendar className="h-3 w-3" />{fmtDate(ds.startDate)} – {fmtDate(ds.endDate)}
                  </span>
                )}
                <span className="flex items-center gap-1"><FileText className="h-3 w-3" />{ds.fileType.toUpperCase()}</span>
              </div>
            </div>
            <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
              <button
                onClick={e => { e.stopPropagation(); onDelete(); }}
                className="p-2 text-muted-foreground hover:text-destructive transition-colors rounded"
              >
                <Trash2 className="h-4 w-4" />
              </button>
              <ChevronRight className="h-5 w-5 text-muted-foreground" />
            </div>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}

// ─── Prepare Options ──────────────────────────────────────────────────────────
function PreparePanel({ dataset }: { dataset: Dataset }) {
  const [opts, setOpts] = useState({ removeNulls: true, detectGaps: true, normalize: false });
  const prepareMutation = usePrepareDataset();

  const toggle = (k: keyof typeof opts) => setOpts(prev => ({ ...prev, [k]: !prev[k] }));

  return (
    <Card className="border-primary/20 bg-primary/5">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-sm">
          <Zap className="h-4 w-4 text-primary" />
          Data Preparation Pipeline
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {dataset.isPrepared && dataset.preparationReport && (
          <div className="text-xs font-mono text-success bg-success/10 border border-success/20 rounded px-3 py-2">
            <CheckCircle2 className="inline h-3 w-3 mr-1" />
            {dataset.preparationReport}
          </div>
        )}

        <div className="space-y-3">
          {[
            { key: "removeNulls" as const, label: "Remove null / invalid OHLCV rows", desc: "Drops rows where price/volume fields are empty or non-numeric" },
            { key: "detectGaps" as const, label: "Detect time-series gaps", desc: "Identifies missing bars in the time series" },
            { key: "normalize" as const, label: "Normalize numeric precision", desc: "Rounds all numeric columns to 6 decimal places" },
          ].map(({ key, label, desc }) => (
            <label key={key} className="flex items-start gap-3 cursor-pointer group">
              <div
                onClick={() => toggle(key)}
                className={cn(
                  "mt-0.5 h-4 w-4 rounded border-2 flex-shrink-0 flex items-center justify-center transition-colors",
                  opts[key] ? "bg-primary border-primary" : "border-border/60 group-hover:border-primary/60",
                )}
              >
                {opts[key] && <span className="text-[8px] text-white font-bold">✓</span>}
              </div>
              <div>
                <p className="text-sm text-foreground">{label}</p>
                <p className="text-[11px] text-muted-foreground font-mono">{desc}</p>
              </div>
            </label>
          ))}
        </div>

        {prepareMutation.isError && (
          <p className="text-destructive text-xs font-mono">{prepareMutation.error.message}</p>
        )}

        <Button
          variant="primary"
          className="w-full"
          onClick={() => prepareMutation.mutate({ id: dataset.id, options: opts })}
          isLoading={prepareMutation.isPending}
        >
          <Zap className="h-4 w-4 mr-2" />
          {dataset.isPrepared ? "Re-Run Preparation" : "Run Data Preparation"}
        </Button>
      </CardContent>
    </Card>
  );
}

// ─── Closing price chart ──────────────────────────────────────────────────────
function PriceChart({ rows, columns }: { rows: Record<string, string>[]; columns: string[] }) {
  const closeCol = columns.find(c => /^close$/i.test(c)) ?? columns.find(c => /close|price|last/i.test(c));
  const dateCol = columns.find(c => /^(date|time|datetime|timestamp)/i.test(c));
  if (!closeCol) return null;

  const chartData = rows
    .slice(0, 200)
    .map((r, i) => ({
      idx: dateCol ? r[dateCol]?.slice(0, 10) : i,
      value: parseFloat(r[closeCol]),
    }))
    .filter(d => !isNaN(d.value));

  if (chartData.length < 2) return null;

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="flex items-center gap-2 text-sm">
          <BarChart2 className="h-4 w-4 text-primary" /> Close Price Preview
          <span className="text-xs text-muted-foreground font-mono">(first 200 rows)</span>
        </CardTitle>
      </CardHeader>
      <CardContent className="h-40 p-0 px-4 pb-4">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={chartData}>
            <defs>
              <linearGradient id="closeGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#06b6d4" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#06b6d4" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#ffffff10" />
            <XAxis dataKey="idx" hide />
            <YAxis domain={["auto", "auto"]} width={70} tick={{ fontSize: 10, fill: "#6b7280" }} tickFormatter={v => v.toFixed(2)} />
            <Tooltip
              contentStyle={{ background: "#0d1117", border: "1px solid #374151", borderRadius: 6 }}
              labelStyle={{ color: "#9ca3af", fontSize: 11 }}
              formatter={(v: number) => [v.toFixed(5), closeCol]}
            />
            <Area type="monotone" dataKey="value" stroke="#06b6d4" strokeWidth={1.5} fill="url(#closeGrad)" dot={false} />
          </AreaChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

// ─── Detail View ──────────────────────────────────────────────────────────────
function DatasetDetail({ id, onBack }: { id: number; onBack: () => void }) {
  const { data: ds, isLoading } = useDataset(id);

  if (isLoading || !ds) {
    return (
      <div className="py-20 text-center text-primary font-mono animate-pulse">LOADING_DATASET...</div>
    );
  }

  const ohlcvCols = (ds.columnStats ?? []).filter(c =>
    /^(open|high|low|close|volume|vol)/i.test(c.name)
  );
  const hasOHLCV = ohlcvCols.length > 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={onBack}><ArrowLeft className="h-5 w-5" /></Button>
        <div>
          <h2 className="text-2xl font-bold tracking-tight">{ds.name}</h2>
          <div className="flex items-center gap-2 mt-1">
            {ds.asset && <Badge variant="default">{ds.asset}</Badge>}
            {ds.timeframe && <Badge variant="warning">{ds.timeframe}</Badge>}
            {ds.isPrepared && <Badge variant="success" className="flex items-center gap-1"><CheckCircle2 className="h-3 w-3" /> Prepared</Badge>}
          </div>
        </div>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {[
          { label: "Rows", value: ds.rowCount.toLocaleString(), icon: Hash },
          { label: "Columns", value: ds.columns.length, icon: Columns3 },
          { label: "Start Date", value: fmtDate(ds.startDate), icon: Calendar },
          { label: "End Date", value: fmtDate(ds.endDate), icon: Clock },
        ].map(({ label, value, icon: Icon }) => (
          <Card key={label}>
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                <Icon className="h-3 w-3 text-primary" /> {label}
              </div>
              <p className="font-mono text-base font-bold text-foreground">{value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left: prepare + gap info */}
        <div className="space-y-4">
          <PreparePanel dataset={ds} />

          {(ds.gapsDetected != null || ds.nullsRemoved != null) && (
            <Card className={cn("border", ds.gapsDetected ? "border-warning/40" : "border-border/40")}>
              <CardContent className="p-4 space-y-2 text-sm font-mono">
                <p className="font-semibold flex items-center gap-2 text-foreground">
                  <Info className="h-4 w-4 text-primary" /> Preparation Summary
                </p>
                {ds.nullsRemoved != null && (
                  <p className={cn(ds.nullsRemoved > 0 ? "text-warning" : "text-muted-foreground")}>
                    Nulls removed: {ds.nullsRemoved}
                  </p>
                )}
                {ds.gapsDetected != null && (
                  <p className={cn(ds.gapsDetected > 0 ? "text-warning" : "text-success")}>
                    {ds.gapsDetected > 0
                      ? `⚠ ${ds.gapsDetected} gap(s) detected`
                      : "✓ No time gaps"}
                  </p>
                )}
              </CardContent>
            </Card>
          )}
        </div>

        {/* Right: chart + stats + preview */}
        <div className="lg:col-span-2 space-y-4">
          {ds.previewRows && ds.previewRows.length > 0 && (
            <PriceChart rows={ds.previewRows} columns={ds.columns} />
          )}

          {/* OHLCV column stats */}
          {hasOHLCV && (
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm flex items-center gap-2">
                  <BarChart2 className="h-4 w-4 text-primary" /> Column Statistics
                </CardTitle>
              </CardHeader>
              <CardContent className="overflow-x-auto">
                <table className="w-full text-xs font-mono">
                  <thead>
                    <tr className="border-b border-border/40">
                      {["Column", "Min", "Max", "Mean", "Std Dev", "Nulls"].map(h => (
                        <th key={h} className="pb-2 text-left text-muted-foreground pr-4">{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {(ds.columnStats ?? []).filter(c =>
                      /^(open|high|low|close|vol|price|bid|ask)/i.test(c.name)
                    ).map(c => (
                      <tr key={c.name} className="border-b border-border/20">
                        <td className="py-1.5 pr-4 text-primary font-semibold">{c.name}</td>
                        <td className="py-1.5 pr-4">{fmtNum(c.min, 5)}</td>
                        <td className="py-1.5 pr-4">{fmtNum(c.max, 5)}</td>
                        <td className="py-1.5 pr-4">{fmtNum(c.mean, 5)}</td>
                        <td className="py-1.5 pr-4">{fmtNum(c.std, 5)}</td>
                        <td className={cn("py-1.5", c.nullCount > 0 ? "text-warning" : "text-muted-foreground")}>
                          {c.nullCount}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          )}

          {/* Preview rows table */}
          {ds.previewRows && ds.previewRows.length > 0 && (
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm flex items-center gap-2">
                  <FileText className="h-4 w-4 text-primary" /> Data Preview
                  <span className="text-xs text-muted-foreground font-mono">(first 10 + last 5 rows)</span>
                </CardTitle>
              </CardHeader>
              <CardContent className="overflow-x-auto p-0">
                <div className="overflow-x-auto terminal-scrollbar">
                  <table className="w-full text-xs font-mono">
                    <thead className="sticky top-0 bg-panel">
                      <tr className="border-b border-border/40">
                        {ds.columns.slice(0, 8).map(c => (
                          <th key={c} className="px-3 py-2 text-left text-muted-foreground whitespace-nowrap">{c}</th>
                        ))}
                        {ds.columns.length > 8 && (
                          <th className="px-3 py-2 text-muted-foreground/50">+{ds.columns.length - 8} more</th>
                        )}
                      </tr>
                    </thead>
                    <tbody>
                      {ds.previewRows.map((row, i) => (
                        <tr key={i} className={cn("border-b border-border/20", i === 9 ? "border-b-2 border-primary/30" : "")}>
                          {ds.columns.slice(0, 8).map(c => (
                            <td key={c} className="px-3 py-1.5 text-foreground/80 whitespace-nowrap max-w-32 truncate">{row[c]}</td>
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export default function DataPage() {
  const [showUpload, setShowUpload] = useState(false);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const { data: datasets = [], isLoading } = useDatasets();
  const deleteMutation = useDeleteDataset();

  if (selectedId != null) {
    return <DatasetDetail id={selectedId} onBack={() => setSelectedId(null)} />;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Data Import & Preparation</h1>
          <p className="text-muted-foreground mt-1 text-sm">
            Upload historical OHLCV data, inspect statistics, and run cleaning pipelines before analysis.
          </p>
        </div>
        <Button
          variant="primary"
          size="lg"
          className="font-display tracking-wider font-bold shadow-[0_0_20px_rgba(6,182,212,0.4)]"
          onClick={() => setShowUpload(true)}
        >
          <Upload className="h-4 w-4 mr-2" /> Import Data
        </Button>
      </div>

      {/* Inline drop zone when empty */}
      {!isLoading && datasets.length === 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col items-center justify-center py-24 border-2 border-dashed border-border/40 rounded-xl text-center space-y-4 hover:border-primary/40 hover:bg-primary/5 transition-colors cursor-pointer"
          onClick={() => setShowUpload(true)}
        >
          <Database className="h-16 w-16 text-muted-foreground/40" />
          <div>
            <p className="font-display text-xl font-bold text-muted-foreground">NO DATA IMPORTED</p>
            <p className="text-sm text-muted-foreground/60 mt-1 font-mono">
              Upload CSV or JSON files containing OHLCV market data
            </p>
          </div>
          <Button variant="primary" className="mt-2">
            <Upload className="h-4 w-4 mr-2" /> Import Your First Dataset
          </Button>
        </motion.div>
      )}

      {/* Dataset list */}
      <AnimatePresence mode="popLayout">
        {datasets.map(ds => (
          <DatasetCard
            key={ds.id}
            ds={ds}
            onSelect={() => setSelectedId(ds.id)}
            onDelete={() => {
              if (confirm(`Delete "${ds.name}"?`)) deleteMutation.mutate(ds.id);
            }}
          />
        ))}
      </AnimatePresence>

      {/* Loading shimmer */}
      {isLoading && (
        <div className="space-y-3">
          {[1, 2].map(i => (
            <div key={i} className="h-24 rounded-lg bg-surface/40 animate-pulse" />
          ))}
        </div>
      )}

      {/* Upload modal */}
      <AnimatePresence>
        {showUpload && <UploadModal onClose={() => setShowUpload(false)} />}
      </AnimatePresence>
    </div>
  );
}
