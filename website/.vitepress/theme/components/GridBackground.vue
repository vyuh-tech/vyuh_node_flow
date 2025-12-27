<script setup lang="ts">
defineProps<{
  color?: 'blue' | 'purple' | 'amber';
  blinkCells?: Array<{ left: number; top: number; delay: number; duration: number }>;
}>();
</script>

<template>
  <div class="grid-background" :class="'grid-' + (color || 'blue')">
    <div v-if="blinkCells" class="grid-blink">
      <div
        class="blink-cell"
        :class="'blink-cell-' + (color || 'blue')"
        v-for="(cell, n) in blinkCells"
        :key="n"
        :style="{
          left: `${cell.left}px`,
          top: `${cell.top}px`,
          animationDelay: `${cell.delay}s`,
          animationDuration: `${cell.duration}s`,
        }"
      />
    </div>
  </div>
</template>

<style>
.grid-background {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  overflow: hidden;
}

/* Blue grid */
.grid-blue {
  background:
    linear-gradient(to right, rgba(37, 99, 235, 0.06) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(37, 99, 235, 0.06) 1px, transparent 1px),
    linear-gradient(to right, rgba(37, 99, 235, 0.02) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(37, 99, 235, 0.02) 1px, transparent 1px);
  background-size: 200px 200px, 200px 200px, 40px 40px, 40px 40px;
}

.dark .grid-blue {
  background:
    linear-gradient(to right, rgba(96, 165, 250, 0.04) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(96, 165, 250, 0.04) 1px, transparent 1px),
    linear-gradient(to right, rgba(96, 165, 250, 0.015) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(96, 165, 250, 0.015) 1px, transparent 1px);
  background-size: 200px 200px, 200px 200px, 40px 40px, 40px 40px;
}

/* Purple grid */
.grid-purple {
  background:
    linear-gradient(to right, rgba(139, 92, 246, 0.06) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(139, 92, 246, 0.06) 1px, transparent 1px),
    linear-gradient(to right, rgba(139, 92, 246, 0.02) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(139, 92, 246, 0.02) 1px, transparent 1px);
  background-size: 200px 200px, 200px 200px, 40px 40px, 40px 40px;
}

.dark .grid-purple {
  background:
    linear-gradient(to right, rgba(167, 139, 250, 0.04) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(167, 139, 250, 0.04) 1px, transparent 1px),
    linear-gradient(to right, rgba(167, 139, 250, 0.015) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(167, 139, 250, 0.015) 1px, transparent 1px);
  background-size: 200px 200px, 200px 200px, 40px 40px, 40px 40px;
}

/* Amber grid */
.grid-amber {
  background:
    linear-gradient(to right, rgba(245, 158, 11, 0.06) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(245, 158, 11, 0.06) 1px, transparent 1px),
    linear-gradient(to right, rgba(245, 158, 11, 0.02) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(245, 158, 11, 0.02) 1px, transparent 1px);
  background-size: 200px 200px, 200px 200px, 40px 40px, 40px 40px;
}

.dark .grid-amber {
  background:
    linear-gradient(to right, rgba(251, 191, 36, 0.04) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(251, 191, 36, 0.04) 1px, transparent 1px),
    linear-gradient(to right, rgba(251, 191, 36, 0.015) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(251, 191, 36, 0.015) 1px, transparent 1px);
  background-size: 200px 200px, 200px 200px, 40px 40px, 40px 40px;
}

/* Blinking cells */
.grid-blink {
  position: absolute;
  inset: 0;
}

.blink-cell {
  position: absolute;
  width: 40px;
  height: 40px;
  border-radius: 2px;
  animation: cellBlink 6s ease-in-out infinite;
}

.blink-cell-blue {
  background: rgba(37, 99, 235, 0.1);
}
.dark .blink-cell-blue {
  background: rgba(96, 165, 250, 0.15);
}

.blink-cell-purple {
  background: rgba(139, 92, 246, 0.1);
}
.dark .blink-cell-purple {
  background: rgba(167, 139, 250, 0.15);
}

.blink-cell-amber {
  background: rgba(245, 158, 11, 0.1);
}
.dark .blink-cell-amber {
  background: rgba(251, 191, 36, 0.15);
}

@keyframes cellBlink {
  0%, 100% { opacity: 0; transform: scale(0.8); }
  50% { opacity: 1; transform: scale(1); }
}
</style>
