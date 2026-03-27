import { Card, CardContent, CardHeader, CardTitle, Badge } from "@/components/ui";
import { Activity, Code2, Database, Zap } from "lucide-react";
import { useStrategiesHooks } from "@/hooks/use-strategies";
import { useRunsHooks } from "@/hooks/use-runs";
import { Link } from "wouter";

export default function Dashboard() {
  const { strategiesQuery } = useStrategiesHooks();
  const { data: runs } = useRunsHooks();
  const strategies = strategiesQuery.data || [];

  const completedRuns = runs?.filter(r => r.status === 'completed') || [];
  const activeRuns = runs?.filter(r => r.status === 'running' || r.status === 'pending') || [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight glow-text">System Overview</h1>
        <p className="text-muted-foreground mt-1 font-mono text-sm">Welcome to Quantitative Research Terminal v1.0</p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card className="border-t-4 border-t-primary">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2 bg-transparent">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Strategies</CardTitle>
            <Code2 className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{strategies.length}</div>
            <p className="text-xs text-muted mt-1 font-mono">{strategies.filter(s => s.fileType === 'mq5').length} MQ5 files</p>
          </CardContent>
        </Card>
        
        <Card className="border-t-4 border-t-secondary">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2 bg-transparent">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Analyses</CardTitle>
            <Database className="h-4 w-4 text-secondary" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{runs?.length || 0}</div>
            <p className="text-xs text-muted mt-1 font-mono">Historical records</p>
          </CardContent>
        </Card>

        <Card className="border-t-4 border-t-success">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2 bg-transparent">
            <CardTitle className="text-sm font-medium text-muted-foreground">Completed Runs</CardTitle>
            <Activity className="h-4 w-4 text-success" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{completedRuns.length}</div>
            <p className="text-xs text-success mt-1 font-mono glow-text">100% processing rate</p>
          </CardContent>
        </Card>

        <Card className="border-t-4 border-t-warning">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2 bg-transparent">
            <CardTitle className="text-sm font-medium text-muted-foreground">Active Pipelines</CardTitle>
            <Zap className="h-4 w-4 text-warning" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{activeRuns.length}</div>
            {activeRuns.length > 0 ? (
              <p className="text-xs text-warning mt-1 font-mono animate-pulse">Processing data...</p>
            ) : (
              <p className="text-xs text-muted mt-1 font-mono">Idle</p>
            )}
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Recent Strategies</CardTitle>
          </CardHeader>
          <CardContent>
            {strategies.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground font-mono text-sm border border-dashed border-border rounded-md">
                No strategies uploaded.
              </div>
            ) : (
              <div className="space-y-3">
                {strategies.slice(0, 5).map(strategy => (
                  <Link key={strategy.id} href={`/strategies/${strategy.id}`}>
                    <div className="flex items-center justify-between p-3 rounded-md bg-surface border border-border hover:border-primary/50 transition-colors cursor-pointer group">
                      <div className="flex items-center gap-3">
                        <Code2 className="h-5 w-5 text-muted-foreground group-hover:text-primary transition-colors" />
                        <div>
                          <p className="font-medium text-sm text-foreground">{strategy.name}</p>
                          <p className="text-xs text-muted-foreground font-mono">{strategy.fileName}</p>
                        </div>
                      </div>
                      <Badge variant="default">{strategy.fileType}</Badge>
                    </div>
                  </Link>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recent Pipeline Runs</CardTitle>
          </CardHeader>
          <CardContent>
             {(!runs || runs.length === 0) ? (
              <div className="text-center py-8 text-muted-foreground font-mono text-sm border border-dashed border-border rounded-md">
                No active or historical runs.
              </div>
            ) : (
              <div className="space-y-3">
                {runs.slice(0, 5).map(run => (
                  <Link key={run.id} href={`/runs/${run.id}`}>
                    <div className="flex items-center justify-between p-3 rounded-md bg-surface border border-border hover:border-primary/50 transition-colors cursor-pointer group">
                      <div className="flex items-center gap-3">
                        <Activity className="h-5 w-5 text-muted-foreground group-hover:text-primary transition-colors" />
                        <div>
                          <p className="font-medium text-sm text-foreground">Run #{run.id}</p>
                          <p className="text-xs text-muted-foreground font-mono">Strategy ID: {run.strategyId}</p>
                        </div>
                      </div>
                      <Badge variant={
                        run.status === 'completed' ? 'success' :
                        run.status === 'failed' ? 'danger' :
                        run.status === 'running' ? 'pending' : 'warning'
                      }>
                        {run.status}
                      </Badge>
                    </div>
                  </Link>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
