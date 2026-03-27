import { 
  LineChart as RechartsLineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer 
} from 'recharts';

export function EquityCurveChart({ data }: { data: any[] }) {
  if (!data || data.length === 0) {
    // Generate dummy data if real data isn't provided to showcase terminal UI
    const dummyData = Array.from({ length: 50 }).map((_, i) => {
      const isUp = Math.random() > 0.4;
      const prev = i > 0 ? arguments[1][i-1] : 10000;
      const change = (Math.random() * 200) * (isUp ? 1 : -1);
      arguments[1][i] = prev + change;
      return {
        trade: i + 1,
        equity: prev + change,
        drawdown: Math.random() * -500
      };
    }, []);
    data = dummyData;
  }

  return (
    <div className="h-[250px] w-full">
      <ResponsiveContainer width="100%" height="100%">
        <RechartsLineChart data={data} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" vertical={false} />
          <XAxis 
            dataKey="trade" 
            stroke="var(--color-muted-foreground)" 
            fontSize={10} 
            tickLine={false} 
            axisLine={false}
          />
          <YAxis 
            stroke="var(--color-muted-foreground)" 
            fontSize={10} 
            tickLine={false} 
            axisLine={false}
            tickFormatter={(val) => `$${(val/1000).toFixed(0)}k`}
            domain={['auto', 'auto']}
          />
          <Tooltip 
            contentStyle={{ 
              backgroundColor: 'var(--color-panel)', 
              borderColor: 'var(--color-border)',
              borderRadius: '4px',
              fontFamily: 'var(--font-mono)',
              fontSize: '12px'
            }}
            itemStyle={{ color: 'var(--color-primary)' }}
          />
          <Line 
            type="monotone" 
            dataKey="equity" 
            stroke="var(--color-primary)" 
            strokeWidth={2} 
            dot={false}
            activeDot={{ r: 4, fill: 'var(--color-primary)', stroke: '#fff' }}
          />
        </RechartsLineChart>
      </ResponsiveContainer>
    </div>
  );
}
