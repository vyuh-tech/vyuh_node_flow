<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, computed } from 'vue';

const props = defineProps<{
  color?: 'blue' | 'purple' | 'amber';
  blinkCells?: Array<{ left: number; top: number; delay: number; duration: number }>;
}>();

const canvasRef = ref<HTMLCanvasElement | null>(null);
let animationId: number | null = null;
let startTime = 0;
let isPaused = false; // Track pause state for page visibility

// Color configurations for each theme
const colorConfigs = {
  blue: {
    light: { line: 'rgba(37, 99, 235, 0.08)', subLine: 'rgba(37, 99, 235, 0.055)', cell: 'rgba(37, 99, 235, 0.1)' },
    dark: { line: 'rgba(96, 165, 250, 0.06)', subLine: 'rgba(96, 165, 250, 0.02)', cell: 'rgba(96, 165, 250, 0.15)' },
  },
  purple: {
    light: { line: 'rgba(139, 92, 246, 0.08)', subLine: 'rgba(139, 92, 246, 0.055)', cell: 'rgba(139, 92, 246, 0.1)' },
    dark: { line: 'rgba(167, 139, 250, 0.06)', subLine: 'rgba(167, 139, 250, 0.02)', cell: 'rgba(167, 139, 250, 0.15)' },
  },
  amber: {
    light: { line: 'rgba(245, 158, 11, 0.08)', subLine: 'rgba(245, 158, 11, 0.055)', cell: 'rgba(245, 158, 11, 0.1)' },
    dark: { line: 'rgba(251, 191, 36, 0.06)', subLine: 'rgba(251, 191, 36, 0.02)', cell: 'rgba(251, 191, 36, 0.15)' },
  },
};

// Detect mobile for reduced animations
const isMobile = computed(() => typeof window !== 'undefined' && window.innerWidth <= 768);

// Detect dark mode
const isDarkMode = () => document.documentElement.classList.contains('dark');

const getColors = () => {
  const colorKey = props.color || 'blue';
  return isDarkMode() ? colorConfigs[colorKey].dark : colorConfigs[colorKey].light;
};

const drawGrid = (ctx: CanvasRenderingContext2D, width: number, height: number) => {
  const colors = getColors();
  const smallGrid = 40;
  const largeGrid = 200;

  // Draw small grid
  ctx.strokeStyle = colors.subLine;
  ctx.lineWidth = 1;
  ctx.beginPath();
  for (let x = 0; x <= width; x += smallGrid) {
    ctx.moveTo(x, 0);
    ctx.lineTo(x, height);
  }
  for (let y = 0; y <= height; y += smallGrid) {
    ctx.moveTo(0, y);
    ctx.lineTo(width, y);
  }
  ctx.stroke();

  // Draw large grid
  ctx.strokeStyle = colors.line;
  ctx.beginPath();
  for (let x = 0; x <= width; x += largeGrid) {
    ctx.moveTo(x, 0);
    ctx.lineTo(x, height);
  }
  for (let y = 0; y <= height; y += largeGrid) {
    ctx.moveTo(0, y);
    ctx.lineTo(width, y);
  }
  ctx.stroke();
};

const drawBlinkingCells = (ctx: CanvasRenderingContext2D, time: number) => {
  if (!props.blinkCells || isMobile.value) return;

  const colors = getColors();

  props.blinkCells.forEach((cell) => {
    // Calculate opacity based on time, delay, and duration
    const elapsed = (time - cell.delay * 1000) / 1000;
    const progress = (elapsed % cell.duration) / cell.duration;
    // Sine wave for smooth fade in/out
    const opacity = Math.max(0, Math.sin(progress * Math.PI));
    const scale = 0.8 + opacity * 0.2;

    if (opacity > 0.01) {
      ctx.save();
      ctx.globalAlpha = opacity;
      ctx.fillStyle = colors.cell;

      const size = 40 * scale;
      const offset = (40 - size) / 2;

      ctx.beginPath();
      ctx.roundRect(cell.left + offset, cell.top + offset, size, size, 2);
      ctx.fill();
      ctx.restore();
    }
  });
};

const render = (timestamp: number) => {
  const canvas = canvasRef.value;
  if (!canvas) return;

  // Don't render if paused (page not visible)
  if (isPaused) {
    animationId = null;
    return;
  }

  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const time = timestamp - startTime;

  // Clear canvas
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // Draw static grid
  drawGrid(ctx, canvas.width, canvas.height);

  // Draw animated cells (skipped on mobile)
  drawBlinkingCells(ctx, time);

  // Continue animation loop only if we have blinking cells and not on mobile
  if (props.blinkCells && !isMobile.value) {
    animationId = requestAnimationFrame(render);
  }
};

// Handle page visibility changes to pause/resume animation
const handleVisibilityChange = () => {
  isPaused = document.hidden;

  if (!isPaused && props.blinkCells && !isMobile.value && !animationId) {
    // Resume animation
    animationId = requestAnimationFrame(render);
  }
};

const resizeCanvas = () => {
  const canvas = canvasRef.value;
  if (!canvas) return;

  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();

  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;

  const ctx = canvas.getContext('2d');
  if (ctx) {
    ctx.scale(dpr, dpr);
  }

  // If not animating, just draw static grid
  if (!props.blinkCells || isMobile.value) {
    if (ctx) {
      drawGrid(ctx, rect.width, rect.height);
    }
  }
};

// Watch for dark mode changes
const observeDarkMode = () => {
  const observer = new MutationObserver(() => {
    if (canvasRef.value) {
      resizeCanvas();
      if (!animationId && (!props.blinkCells || isMobile.value)) {
        const ctx = canvasRef.value.getContext('2d');
        if (ctx) {
          drawGrid(ctx, canvasRef.value.width, canvasRef.value.height);
        }
      }
    }
  });
  observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] });
  return observer;
};

let darkModeObserver: MutationObserver | null = null;

onMounted(() => {
  resizeCanvas();
  startTime = performance.now();

  window.addEventListener('resize', resizeCanvas);
  document.addEventListener('visibilitychange', handleVisibilityChange);
  darkModeObserver = observeDarkMode();

  // Start animation loop if we have blinking cells
  if (props.blinkCells && !isMobile.value) {
    animationId = requestAnimationFrame(render);
  }
});

onUnmounted(() => {
  window.removeEventListener('resize', resizeCanvas);
  document.removeEventListener('visibilitychange', handleVisibilityChange);
  if (animationId) {
    cancelAnimationFrame(animationId);
  }
  if (darkModeObserver) {
    darkModeObserver.disconnect();
  }
});
</script>

<template>
  <canvas ref="canvasRef" class="grid-canvas" />
</template>

<style>
.grid-canvas {
  position: fixed;
  inset: 0;
  width: 100%;
  height: 100%;
  z-index: 0;
  pointer-events: none;
}
</style>
