import { Link, useLocation } from "wouter";
import { Activity, FolderCode, Terminal, LayoutDashboard, Settings, Menu, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

export function Layout({ children }: { children: React.ReactNode }) {
  const [location] = useLocation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const navItems = [
    { href: "/", label: "Dashboard", icon: LayoutDashboard },
    { href: "/strategies", label: "Strategies", icon: FolderCode },
    { href: "/runs", label: "Analysis Runs", icon: Activity },
  ];

  return (
    <div className="flex min-h-screen w-full bg-background overflow-hidden relative">
      {/* Background Image / Overlay */}
      <div 
        className="absolute inset-0 z-0 opacity-20 pointer-events-none mix-blend-screen"
        style={{
          backgroundImage: `url(${import.meta.env.BASE_URL}images/terminal-bg.png)`,
          backgroundSize: 'cover',
          backgroundPosition: 'center'
        }}
      />

      {/* Sidebar - Desktop */}
      <aside className="hidden md:flex w-64 flex-col glass-panel border-r border-y-0 border-l-0 rounded-none z-10">
        <div className="flex h-16 items-center px-6 border-b border-border/50">
          <Terminal className="h-6 w-6 text-primary mr-3" />
          <span className="font-display font-bold text-xl tracking-wider bg-clip-text text-transparent bg-gradient-to-r from-primary to-blue-400">
            QUANT_OS
          </span>
        </div>
        <nav className="flex-1 space-y-2 p-4">
          {navItems.map((item) => {
            const isActive = location === item.href || (item.href !== "/" && location.startsWith(item.href));
            return (
              <Link key={item.href} href={item.href}>
                <div
                  className={cn(
                    "flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-all duration-200 group cursor-pointer",
                    isActive 
                      ? "bg-primary/10 text-primary border border-primary/30 shadow-[inset_0_0_10px_rgba(6,182,212,0.1)]" 
                      : "text-muted-foreground hover:bg-surface hover:text-white border border-transparent"
                  )}
                >
                  <item.icon className={cn("h-4 w-4", isActive ? "text-primary" : "text-muted-foreground group-hover:text-white")} />
                  {item.label}
                  {isActive && (
                    <motion.div 
                      layoutId="activeNav"
                      className="ml-auto w-1.5 h-1.5 rounded-full bg-primary shadow-[0_0_5px_#06b6d4]"
                    />
                  )}
                </div>
              </Link>
            );
          })}
        </nav>
        <div className="p-4 border-t border-border/50">
          <div className="flex items-center gap-3 px-3 py-2 text-sm text-muted-foreground">
            <Settings className="h-4 w-4" />
            System Status: <span className="text-success ml-auto text-xs font-mono">ONLINE</span>
          </div>
        </div>
      </aside>

      {/* Mobile Header */}
      <header className="md:hidden flex h-16 items-center justify-between px-4 glass-panel border-b border-x-0 border-t-0 rounded-none fixed top-0 w-full z-50">
        <div className="flex items-center">
          <Terminal className="h-5 w-5 text-primary mr-2" />
          <span className="font-display font-bold text-lg tracking-wider text-primary">QUANT_OS</span>
        </div>
        <button onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)} className="p-2 text-muted-foreground">
          {isMobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
      </header>

      {/* Mobile Menu */}
      <AnimatePresence>
        {isMobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="md:hidden fixed inset-x-0 top-16 bg-panel border-b border-border z-40 p-4"
          >
            <nav className="flex flex-col space-y-2">
              {navItems.map((item) => (
                <Link key={item.href} href={item.href}>
                  <div
                    onClick={() => setIsMobileMenuOpen(false)}
                    className={cn(
                      "flex items-center gap-3 rounded-md px-4 py-3 text-sm font-medium",
                      location === item.href ? "bg-primary/10 text-primary" : "text-muted-foreground"
                    )}
                  >
                    <item.icon className="h-5 w-5" />
                    {item.label}
                  </div>
                </Link>
              ))}
            </nav>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-h-0 relative z-10 pt-16 md:pt-0">
        <div className="flex-1 overflow-auto terminal-scrollbar p-4 md:p-8">
          <div className="mx-auto max-w-7xl h-full">
            {children}
          </div>
        </div>
      </main>
    </div>
  );
}
