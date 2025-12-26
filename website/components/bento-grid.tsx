import { ReactNode } from 'react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: (string | undefined | null | false)[]) {
  return twMerge(clsx(inputs));
}

export function BentoGrid({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        'grid grid-cols-1 md:grid-cols-6 lg:grid-cols-3 gap-4 lg:gap-8 max-w-7xl mx-auto',
        className
      )}
    >
      {children}
    </div>
  );
}

export function BentoCard({
  name,
  className,
  background,
  Icon,
  description,
  href,
  cta,
}: {
  name: string;
  className: string;
  background: ReactNode;
  Icon: any;
  description: string;
  href: string;
  cta: string;
}) {
  return (
    <div
      key={name}
      className={cn(
        'group relative col-span-3 flex flex-col justify-between overflow-hidden rounded-3xl',
        'bg-white/40 dark:bg-white/[0.02] border border-slate-200/60 dark:border-white/10',
        'shadow-sm hover:shadow-lg hover:shadow-blue-500/5 transition-all duration-150 backdrop-blur-md',
        // CSS hover animation instead of Framer Motion
        'hover:-translate-y-2 hover:scale-[1.02]',
        className
      )}
    >
      <div className="absolute inset-0 z-0 transition-transform duration-200 group-hover:scale-105 opacity-60">
        {background}
      </div>

      {/* Subtle Glass Gradient Overlay */}
      <div className="absolute inset-0 z-10 bg-gradient-to-t from-white/80 via-white/20 to-transparent dark:from-black/80 dark:via-black/20 dark:to-transparent pointer-events-none" />

      <div className="pointer-events-none z-20 flex flex-col gap-2 p-6 mt-auto">
        <div className="w-10 h-10 rounded-xl bg-white/60 dark:bg-white/10 flex items-center justify-center backdrop-blur-md mb-2 shadow-sm border border-white/20 dark:border-white/10">
          <Icon className="h-5 w-5 text-slate-700 dark:text-slate-200" />
        </div>
        <h3 className="text-lg font-bold font-heading text-slate-900 dark:text-neutral-100">
          {name}
        </h3>
        <p className="max-w-lg text-sm font-medium text-slate-500 dark:text-neutral-400 leading-relaxed">
          {description}
        </p>
      </div>

      <div
        className={cn(
          'pointer-events-none absolute bottom-6 right-6 z-30 opacity-0 -translate-x-2 transition-all duration-300 group-hover:opacity-100 group-hover:translate-x-0'
        )}
      >
        <div className="pointer-events-auto">
          <a
            href={href}
            className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-blue-600/10 dark:bg-blue-500/20 text-blue-600 dark:text-blue-400 hover:bg-blue-600 hover:text-white dark:hover:bg-blue-500 transition-colors"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="h-4 w-4"
            >
              <path d="m9 18 6-6-6-6" />
            </svg>
          </a>
        </div>
      </div>
      <div className="pointer-events-none absolute inset-0 transition-all duration-150 group-hover:bg-blue-500/[0.02] dark:group-hover:bg-blue-500/[0.05]" />
    </div>
  );
}
