import { Link } from "wouter";
import { Card, CardContent, CardHeader, CardTitle, Badge, Button } from "@/components/ui";
import { useRunsHooks } from "@/hooks/use-runs";
import { Activity, Clock, TerminalSquare, ArrowRight } from "lucide-react";
import { format } from "date-fns";

export default function RunsList() {
  const { data: runs, isLoading } = useRunsHooks();

  const getStatusBadge = (status: string) => {
    switch(status) {
      case 'completed': return <Badge variant="success">COMPLETED</Badge>;
      case 'failed': return <Badge variant="danger">FAILED</Badge>;
      case 'running': return <Badge variant="pending">PROCESSING</Badge>;
      default: return <Badge variant="default">PENDING</Badge>;
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight glow-text">Analysis Operations</h1>
        <p className="text-muted-foreground mt-1 font-mono text-sm">Live and historical pipeline runs</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TerminalSquare className="h-5 w-5 text-primary" />
            Execution Logs
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="p-8 text-center text-primary font-mono animate-pulse">FETCHING_LOGS...</div>
          ) : (!runs || runs.length === 0) ? (
            <div className="p-12 text-center text-muted-foreground font-mono">
              NO_ACTIVE_PROCESSES
            </div>
          ) : (
            <div className="divide-y divide-border">
              {runs.map((run) => (
                <div key={run.id} className="grid grid-cols-1 md:grid-cols-12 gap-4 p-4 hover:bg-surface/50 transition-colors items-center group">
                  <div className="md:col-span-3 flex items-center gap-3">
                    <div className={`p-2 rounded-md border ${
                      run.status === 'completed' ? 'border-success/30 text-success bg-success/5' :
                      run.status === 'failed' ? 'border-danger/30 text-danger bg-danger/5' :
                      run.status === 'running' ? 'border-primary/50 text-primary bg-primary/10 animate-pulse' :
                      'border-border text-muted-foreground bg-surface'
                    }`}>
                      <Activity className="h-4 w-4" />
                    </div>
                    <div>
                      <p className="font-mono font-bold text-foreground">OP_ID:{run.id.toString().padStart(4, '0')}</p>
                      <p className="text-xs text-muted-foreground font-mono mt-0.5">STRAT_{run.strategyId}</p>
                    </div>
                  </div>

                  <div className="md:col-span-4 space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-muted-foreground font-mono w-16">STATUS:</span>
                      {getStatusBadge(run.status)}
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-muted-foreground font-mono w-16">STEP:</span>
                      <span className="text-xs font-mono text-foreground">{run.currentStep || 0} / {run.totalSteps}</span>
                      {run.status === 'running' && (
                        <div className="h-1.5 flex-1 bg-surface rounded-full ml-2 overflow-hidden">
                          <div 
                            className="h-full bg-primary" 
                            style={{ width: `${((run.currentStep || 0) / run.totalSteps) * 100}%` }}
                          />
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="md:col-span-3 flex flex-col justify-center text-xs font-mono text-muted-foreground space-y-1">
                    <div className="flex items-center gap-2">
                      <Clock className="h-3 w-3" />
                      {format(new Date(run.createdAt), 'MM/dd HH:mm:ss')}
                    </div>
                    <div>TARGET: {run.options.markets?.[0]} ({run.options.timeframes?.[0]})</div>
                  </div>

                  <div className="md:col-span-2 flex justify-end">
                    <Link href={`/runs/${run.id}`}>
                      <Button variant="outline" size="sm" className="font-mono text-xs w-full md:w-auto">
                        VIEW_DATA <ArrowRight className="ml-2 h-3 w-3" />
                      </Button>
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
