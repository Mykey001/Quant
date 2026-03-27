import * as React from "react"
import { cn } from "@/lib/utils"
import { Loader2 } from "lucide-react"

// --- Button ---
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost' | 'outline';
  size?: 'sm' | 'md' | 'lg' | 'icon';
  isLoading?: boolean;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', isLoading, children, disabled, ...props }, ref) => {
    const variants = {
      primary: "bg-primary text-primary-foreground hover:bg-primary-hover shadow-[0_0_15px_rgba(6,182,212,0.3)] hover:shadow-[0_0_20px_rgba(6,182,212,0.5)] border border-primary/50",
      secondary: "bg-surface hover:bg-surface-hover text-white border border-border",
      danger: "bg-danger/10 text-danger border border-danger/30 hover:bg-danger/20 hover:border-danger/50 shadow-[0_0_10px_rgba(239,68,68,0.1)]",
      ghost: "bg-transparent text-muted hover:text-white hover:bg-surface",
      outline: "bg-transparent border border-primary/50 text-primary hover:bg-primary/10"
    };

    const sizes = {
      sm: "h-8 px-3 text-xs",
      md: "h-10 px-4 py-2 text-sm",
      lg: "h-12 px-6 text-base",
      icon: "h-10 w-10 flex items-center justify-center p-0"
    };

    return (
      <button
        ref={ref}
        disabled={isLoading || disabled}
        className={cn(
          "inline-flex items-center justify-center rounded-sm font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary disabled:pointer-events-none disabled:opacity-50",
          variants[variant],
          sizes[size],
          className
        )}
        {...props}
      >
        {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
        {children}
      </button>
    )
  }
)
Button.displayName = "Button"

// --- Card ---
export function Card({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "glass-panel rounded-lg overflow-hidden transition-all duration-300",
        className
      )}
      {...props}
    />
  )
}

export function CardHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("flex flex-col space-y-1.5 p-6 border-b border-border/50 bg-panel/50", className)} {...props} />
}

export function CardTitle({ className, ...props }: React.HTMLAttributes<HTMLHeadingElement>) {
  return <h3 className={cn("font-display text-xl font-semibold leading-none tracking-tight", className)} {...props} />
}

export function CardContent({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("p-6", className)} {...props} />
}

// --- Badge ---
export function Badge({ 
  className, 
  variant = 'default',
  ...props 
}: React.HTMLAttributes<HTMLDivElement> & { variant?: 'default' | 'success' | 'warning' | 'danger' | 'pending' }) {
  const variants = {
    default: "bg-surface text-muted border-border",
    success: "bg-success-bg text-success border-success/30 glow-text",
    warning: "bg-warning-bg text-warning border-warning/30",
    danger: "bg-danger-bg text-danger border-danger/30 glow-text",
    pending: "bg-primary/10 text-primary border-primary/30 animate-pulse",
  }
  
  return (
    <div className={cn(
      "inline-flex items-center rounded-sm border px-2.5 py-0.5 text-xs font-semibold transition-colors font-mono uppercase tracking-wider",
      variants[variant],
      className
    )} {...props} />
  )
}

// --- Input ---
export const Input = React.forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement>>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          "flex h-10 w-full rounded-sm border border-border bg-surface px-3 py-2 text-sm text-foreground ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary focus-visible:border-primary disabled:cursor-not-allowed disabled:opacity-50 transition-colors",
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

// --- Label ---
export const Label = React.forwardRef<HTMLLabelElement, React.LabelHTMLAttributes<HTMLLabelElement>>(
  ({ className, ...props }, ref) => (
    <label
      ref={ref}
      className={cn(
        "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-muted",
        className
      )}
      {...props}
    />
  )
)
Label.displayName = "Label"
