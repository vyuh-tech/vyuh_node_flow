'use client';

import { motion } from 'motion/react';
import { useEffect, useState, useMemo } from 'react';
import { GRID_SIZE } from './grid-background';

export function BlinkingGridBackground() {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Generate enough cells to cover large viewports
  const COLS = 50; // Wide enough for 2000px+ screens
  const ROWS = 30; // Tall enough for 1200px+ screens

  const cells = useMemo(() => {
    const items = [];
    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < COLS; c++) {
        // Sparsity: 12% of cells blink for a subtle effect
        if (Math.random() > 0.12) continue;
        items.push({ r, c, delay: Math.random() * 8 });
      }
    }
    return items;
  }, []);

  if (!mounted) return null;

  return (
    // Absolute positioning within parent, with radial fade mask
    <div className="absolute inset-0 overflow-hidden pointer-events-none [mask-image:radial-gradient(ellipse_80%_70%_at_50%_40%,black_10%,transparent_70%)]">
      <svg className="w-full h-full" width="100%" height="100%">
        {cells.map((cell, i) => (
          <motion.rect
            key={i}
            // Coordinates match the grid pattern exactly
            x={cell.c * GRID_SIZE}
            y={cell.r * GRID_SIZE}
            width={GRID_SIZE}
            height={GRID_SIZE}
            className="fill-blue-400/30 dark:fill-blue-400/25"
            initial={{ opacity: 0 }}
            animate={{ opacity: [0, 0.5, 0] }}
            transition={{
              duration: 3 + Math.random() * 4,
              repeat: Infinity,
              delay: cell.delay,
              ease: 'easeInOut',
            }}
          />
        ))}
      </svg>
    </div>
  );
}
