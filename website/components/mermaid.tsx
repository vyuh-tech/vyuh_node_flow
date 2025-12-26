'use client';

import { use, useEffect, useId, useState, Suspense } from 'react';
import { useTheme } from 'next-themes';

export function Mermaid({ chart }: { chart: string }) {
  return (
    <Suspense fallback={<div className="w-full h-32 animate-pulse bg-slate-100 dark:bg-slate-800 rounded-lg" />}>
      <MermaidInner chart={chart} />
    </Suspense>
  );
}

function MermaidInner({ chart }: { chart: string }) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return <div className="w-full h-32 bg-slate-100 dark:bg-slate-800 rounded-lg" />;
  
  return <MermaidContent chart={chart} />;
}

const cache = new Map<string, Promise<any>>();

function cachePromise<T>(
  key: string,
  setPromise: () => Promise<T>,
): Promise<T> {
  const cached = cache.get(key);
  if (cached) return cached as Promise<T>;

  const promise = setPromise();
  cache.set(key, promise);
  return promise;
}

function MermaidContent({ chart }: { chart: string }) {
  const id = useId().replace(/:/g, ''); // Ensure ID is valid for Mermaid
  const { resolvedTheme } = useTheme();
  
  const mermaidModule = use(
    cachePromise('mermaid', () => import('mermaid').then(m => m.default)),
  );

  useEffect(() => {
    mermaidModule.initialize({
      startOnLoad: false,
      securityLevel: 'loose',
      fontFamily: 'inherit',
      theme: resolvedTheme === 'dark' ? 'dark' : 'default',
    });
  }, [resolvedTheme, mermaidModule]);

  const svgData = use(
    cachePromise(`${chart}-${resolvedTheme}`, () => {
      return mermaidModule.render(id, chart.replaceAll('\n', '\n'));
    }),
  );

  return (
    <div
      className="my-6 flex justify-center"
      ref={(container) => {
        if (container && svgData.bindFunctions) {
            svgData.bindFunctions(container);
        }
      }}
      dangerouslySetInnerHTML={{ __html: svgData.svg }}
    />
  );
}

export default Mermaid;