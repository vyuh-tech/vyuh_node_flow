'use client';

import { useEffect, useRef } from 'react';
import { useIsMobile, useReducedMotion } from '@/hooks/use-mobile';

const GRID_SIZE = 40;
const LARGE_GRID_SIZE = 200;

interface Cell {
  r: number;
  c: number;
  phase: number;
  speed: number;
}

export function BlinkingGridBackground() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const isMobile = useIsMobile();
  const prefersReducedMotion = useReducedMotion();

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Generate blinking cells (skip only if reduced motion preferred)
    const cells: Cell[] = [];
    if (!prefersReducedMotion) {
      const COLS = Math.ceil(2000 / GRID_SIZE);
      const ROWS = Math.ceil(1200 / GRID_SIZE);
      // Fewer cells on mobile for performance
      const cellDensity = isMobile ? 0.06 : 0.1;

      for (let r = 0; r < ROWS; r++) {
        for (let c = 0; c < COLS; c++) {
          if (Math.random() > cellDensity) continue;
          cells.push({
            r,
            c,
            phase: Math.random() * Math.PI * 2,
            speed: 0.3 + Math.random() * 0.5,
          });
        }
      }
    }

    let animationId: number;
    const startTime = performance.now();

    const drawGrid = (isDark: boolean, width: number, height: number) => {

      // Draw small grid lines
      ctx.beginPath();
      ctx.strokeStyle = isDark
        ? 'rgba(37, 99, 235, 0.08)' // blue-600 very subtle
        : 'rgba(148, 163, 184, 0.15)'; // slate-400 subtle
      ctx.lineWidth = 1;

      // Vertical lines
      for (let x = 0; x <= width; x += GRID_SIZE) {
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
      }
      // Horizontal lines
      for (let y = 0; y <= height; y += GRID_SIZE) {
        ctx.moveTo(0, y);
        ctx.lineTo(width, y);
      }
      ctx.stroke();

      // Draw large grid lines
      ctx.beginPath();
      ctx.strokeStyle = isDark
        ? 'rgba(37, 99, 235, 0.05)' // blue-600 very faint
        : 'rgba(148, 163, 184, 0.10)'; // slate-400 faint
      ctx.lineWidth = 1;

      // Vertical lines
      for (let x = 0; x <= width; x += LARGE_GRID_SIZE) {
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
      }
      // Horizontal lines
      for (let y = 0; y <= height; y += LARGE_GRID_SIZE) {
        ctx.moveTo(0, y);
        ctx.lineTo(width, y);
      }
      ctx.stroke();
    };

    const animate = (time: number) => {
      const elapsed = (time - startTime) / 1000;

      // Resize canvas to match display size
      const rect = canvas.getBoundingClientRect();
      const dpr = window.devicePixelRatio || 1;
      const width = rect.width * dpr;
      const height = rect.height * dpr;

      if (canvas.width !== width || canvas.height !== height) {
        canvas.width = width;
        canvas.height = height;
        ctx.scale(dpr, dpr);
      }

      // Clear
      ctx.clearRect(0, 0, rect.width, rect.height);

      // Check for dark mode
      const isDark = document.documentElement.classList.contains('dark');

      // Draw static grid lines first
      drawGrid(isDark, rect.width, rect.height);

      // Draw blinking cells (skip only if reduced motion preferred)
      if (!prefersReducedMotion) {
        cells.forEach((cell) => {
          // Max opacity reduced for subtlety
          const maxOpacity = isDark ? 0.1 : 0.18;
          const opacity = ((Math.sin(elapsed * cell.speed + cell.phase) + 1) / 2) * maxOpacity;
          if (opacity < 0.02) return; // Skip nearly invisible cells

          ctx.fillStyle = isDark
            ? `rgba(96, 165, 250, ${opacity})` // blue-400
            : `rgba(59, 130, 246, ${opacity})`; // blue-500

          ctx.fillRect(
            cell.c * GRID_SIZE,
            cell.r * GRID_SIZE,
            GRID_SIZE - 1, // Slight inset to not overlap grid lines
            GRID_SIZE - 1
          );
        });
      }

      animationId = requestAnimationFrame(animate);
    };

    animationId = requestAnimationFrame(animate);

    return () => {
      cancelAnimationFrame(animationId);
    };
  }, [isMobile, prefersReducedMotion]);

  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      <canvas
        ref={canvasRef}
        className="w-full h-full"
        style={{ width: '100%', height: '100%' }}
      />
    </div>
  );
}
