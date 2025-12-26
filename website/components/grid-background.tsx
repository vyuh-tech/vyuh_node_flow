'use client';

const GRID_SIZE = 40;
const LARGE_GRID_SIZE = 200;

export { GRID_SIZE, LARGE_GRID_SIZE };

export function GridBackground({
  className = '',
  prominent = false,
}: {
  className?: string;
  prominent?: boolean;
}) {
  const opacity = prominent
    ? 'opacity-[0.35] dark:opacity-[0.25]'
    : 'opacity-[0.25] dark:opacity-[0.18]';

  return (
    <div className={`absolute inset-0 pointer-events-none ${className}`}>
      <svg className={`w-full h-full ${opacity}`} width="100%" height="100%">
        <defs>
          <pattern
            id="global-grid"
            width={GRID_SIZE}
            height={GRID_SIZE}
            patternUnits="userSpaceOnUse"
          >
            <path
              d={`M ${GRID_SIZE} 0 L 0 0 0 ${GRID_SIZE}`}
              fill="none"
              className="stroke-slate-400 dark:stroke-blue-700/60"
              strokeWidth="1"
            />
          </pattern>
          <pattern
            id="global-grid-large"
            width={LARGE_GRID_SIZE}
            height={LARGE_GRID_SIZE}
            patternUnits="userSpaceOnUse"
          >
            <rect
              width={LARGE_GRID_SIZE}
              height={LARGE_GRID_SIZE}
              fill="url(#global-grid)"
            />
            <path
              d={`M ${LARGE_GRID_SIZE} 0 L 0 0 0 ${LARGE_GRID_SIZE}`}
              fill="none"
              className="stroke-slate-400 dark:stroke-blue-600/80"
              strokeWidth="1.5"
            />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#global-grid-large)" />
      </svg>
    </div>
  );
}
