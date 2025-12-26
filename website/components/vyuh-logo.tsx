import { Layers } from 'lucide-react';

export function VyuhLogo({ className }: { className?: string }) {
  return (
    <div className={`flex items-center gap-2 font-heading font-bold text-xl tracking-tight ${className}`}>
      <div className="relative flex items-center justify-center w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 shadow-md shadow-blue-500/20">
        <Layers className="w-5 h-5 text-white" />
        <div className="absolute inset-0 rounded-lg ring-1 ring-white/20" />
      </div>
      <span className="hidden sm:inline-block bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-700 dark:from-white dark:to-slate-300">
        Vyuh Node Flow
      </span>
    </div>
  );
}
