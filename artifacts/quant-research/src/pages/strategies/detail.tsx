import { useRoute, useLocation } from "wouter";
import { useStrategyDetail, useStrategiesHooks } from "@/hooks/use-strategies";
import { Card, CardContent, CardHeader, CardTitle, Badge, Button } from "@/components/ui";
import { ArrowLeft, Play, FileText, Calendar, Info, AlertTriangle } from "lucide-react";
import { format } from "date-fns";

export default function StrategyDetail() {
  const [, params] = useRoute("/strategies/:id");
  const id = parseInt(params?.id || "0", 10);
  const [, setLocation] = useLocation();
  
  const { data: strategy, isLoading, isError } = useStrategyDetail(id);
  const { analyzeMutation } = useStrategiesHooks();

  const handleAnalyze = () => {
    analyzeMutation.mutate({
      id,
      data: {
        markets: ["XAUUSD", "EURUSD"],
        timeframes: ["H1", "D1"],
        yearsOfData: 5,
        trainSplit: 0.7,
        validationSplit: 0.3
      }
    }, {
      onSuccess: (run) => {
        setLocation(`/runs/${run.id}`);
      }
    });
  };

  if (isLoading) {
    return <div className="p-8 text-center text-primary font-mono animate-pulse">LOADING_DATA_STREAM...</div>;
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
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => setLocation('/strategies')}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{strategy.name}</h1>
          <div className="flex items-center gap-3 mt-1 text-sm text-muted-foreground font-mono">
            <span>ID: {strategy.id.toString().padStart(4, '0')}</span>
            <span>•</span>
            <Badge variant="default" className="text-[10px] py-0">{strategy.fileType}</Badge>
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-1 space-y-6">
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
                <Badge variant="warning" className="mt-1">{strategy.strategyType || 'UNKNOWN'}</Badge>
              </div>
              <div>
                <span className="text-muted-foreground block text-xs">Added On</span>
                <span className="text-foreground flex items-center gap-2 mt-1">
                  <Calendar className="h-3 w-3 text-muted-foreground" />
                  {format(new Date(strategy.createdAt), 'PPpp')}
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

          <Card className="border-primary/20 bg-primary/5">
            <CardHeader>
              <CardTitle className="text-primary text-sm uppercase tracking-widest">Pipeline Readiness</CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="space-y-2 text-sm font-mono">
                <li className="flex items-center gap-2 text-success"><span className="h-1.5 w-1.5 rounded-full bg-success"></span> Syntax Validated</li>
                <li className="flex items-center gap-2 text-success"><span className="h-1.5 w-1.5 rounded-full bg-success"></span> Agent Systems Online</li>
                <li className="flex items-center gap-2 text-success"><span className="h-1.5 w-1.5 rounded-full bg-success"></span> Backtest Engine Ready</li>
              </ul>
            </CardContent>
          </Card>
        </div>

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
                  <code>{strategy.fileContent || '// Empty file or binary content unable to render.'}</code>
                </pre>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
