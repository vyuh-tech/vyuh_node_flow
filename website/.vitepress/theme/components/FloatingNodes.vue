<script setup lang="ts">
/**
 * Decorative floating node shapes that appear in the background
 * to reinforce the node editor theme.
 */

defineProps<{
  variant?: 'hero' | 'sparse';
}>();

// Individual port configuration for each node
interface PortConfig {
  top?: boolean;
  bottom?: boolean;
  left?: boolean;
  right?: boolean;
}

interface FloatingNode {
  id: number;
  x: string;
  y: string;
  size: 'xs' | 'sm' | 'md';
  color: 'blue' | 'purple' | 'teal';
  delay: number;
  ports: PortConfig;
}

// Predefined node positions with varied port combinations
const nodes: FloatingNode[] = [
  { id: 1, x: '5%', y: '20%', size: 'sm', color: 'blue', delay: 0, ports: { top: true, bottom: true } },
  { id: 2, x: '92%', y: '35%', size: 'md', color: 'purple', delay: 1, ports: { left: true } },
  { id: 3, x: '8%', y: '70%', size: 'sm', color: 'teal', delay: 2, ports: { right: true, bottom: true } },
  { id: 4, x: '88%', y: '75%', size: 'sm', color: 'blue', delay: 0.5, ports: { top: true } },
  { id: 5, x: '15%', y: '45%', size: 'xs', color: 'purple', delay: 1.5, ports: { left: true, right: true } },
  { id: 6, x: '85%', y: '15%', size: 'xs', color: 'teal', delay: 2.5, ports: { bottom: true, right: true } },
];

const sparseNodes: FloatingNode[] = [
  { id: 1, x: '3%', y: '30%', size: 'sm', color: 'purple', delay: 0, ports: { top: true, bottom: true } },
  { id: 2, x: '95%', y: '50%', size: 'sm', color: 'teal', delay: 1, ports: { left: true } },
];
</script>

<template>
  <div class="floating-nodes">
    <div
      v-for="node in (variant === 'sparse' ? sparseNodes : nodes)"
      :key="node.id"
      class="floating-node"
      :class="[`node-${node.size}`, `node-${node.color}`]"
      :style="{
        left: node.x,
        top: node.y,
        animationDelay: `${node.delay}s`
      }"
    >
      <!-- Node body with absolutely positioned ports -->
      <div class="node-body">
        <!-- Top port -->
        <template v-if="node.ports.top">
          <div class="node-line node-line-top" />
          <div class="node-port node-port-top" />
        </template>

        <!-- Bottom port -->
        <template v-if="node.ports.bottom">
          <div class="node-port node-port-bottom" />
          <div class="node-line node-line-bottom" />
        </template>

        <!-- Left port -->
        <template v-if="node.ports.left">
          <div class="node-line node-line-left" />
          <div class="node-port node-port-left" />
        </template>

        <!-- Right port -->
        <template v-if="node.ports.right">
          <div class="node-port node-port-right" />
          <div class="node-line node-line-right" />
        </template>
      </div>
    </div>
  </div>
</template>

<style>
@reference "../style.css";

.floating-nodes {
  @apply fixed inset-0 pointer-events-none overflow-hidden z-0;
}

.floating-node {
  @apply absolute;
  animation: floatNode 6s ease-in-out infinite;
  opacity: 0.5;
}

@keyframes floatNode {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

.node-body {
  @apply relative bg-white/90 dark:bg-zinc-800/90;
  border: 1px solid currentColor;
  border-radius: 8px;
}

/* Ports - absolutely positioned and centered on edges */
.node-port {
  @apply absolute rounded-full;
  background: white;
  border: 2px solid currentColor;
}

.dark .node-port {
  background: #18181b; /* zinc-900 */
}

/* Top/bottom ports: horizontally centered */
.node-port-top,
.node-port-bottom {
  left: 50%;
  transform: translateX(-50%);
}

.node-port-top {
  top: 0;
  transform: translateX(-50%) translateY(-50%);
}

.node-port-bottom {
  bottom: 0;
  transform: translateX(-50%) translateY(50%);
}

/* Left/right ports: vertically centered */
.node-port-left,
.node-port-right {
  top: 50%;
  transform: translateY(-50%);
}

.node-port-left {
  left: 0;
  transform: translateX(-50%) translateY(-50%);
}

.node-port-right {
  right: 0;
  transform: translateX(50%) translateY(-50%);
}

/* Fading connection lines - absolutely positioned */
.node-line {
  @apply absolute;
  background: currentColor;
  opacity: 0.5;
}

/* Vertical lines (top/bottom) */
.node-line-top,
.node-line-bottom {
  width: 1px;
  height: 16px;
  left: 50%;
  transform: translateX(-50%);
}

.node-line-top {
  bottom: 100%;
  margin-bottom: 4px; /* Gap for port */
  mask-image: linear-gradient(to bottom, transparent, black);
  -webkit-mask-image: linear-gradient(to bottom, transparent, black);
}

.node-line-bottom {
  top: 100%;
  margin-top: 4px; /* Gap for port */
  mask-image: linear-gradient(to top, transparent, black);
  -webkit-mask-image: linear-gradient(to top, transparent, black);
}

/* Horizontal lines (left/right) */
.node-line-left,
.node-line-right {
  width: 16px;
  height: 1px;
  top: 50%;
  transform: translateY(-50%);
}

.node-line-left {
  right: 100%;
  margin-right: 4px; /* Gap for port */
  mask-image: linear-gradient(to right, transparent, black);
  -webkit-mask-image: linear-gradient(to right, transparent, black);
}

.node-line-right {
  left: 100%;
  margin-left: 4px; /* Gap for port */
  mask-image: linear-gradient(to left, transparent, black);
  -webkit-mask-image: linear-gradient(to left, transparent, black);
}

/* Size variants */
.node-xs .node-body { @apply w-8 h-5; }
.node-xs .node-port { @apply w-2 h-2; }
.node-xs .node-line-top,
.node-xs .node-line-bottom { height: 12px; }
.node-xs .node-line-left,
.node-xs .node-line-right { width: 12px; }

.node-sm .node-body { @apply w-12 h-7; }
.node-sm .node-port { @apply w-2.5 h-2.5; }

.node-md .node-body { @apply w-16 h-9; }
.node-md .node-port { @apply w-3 h-3; }
.node-md .node-line-top,
.node-md .node-line-bottom { height: 20px; }
.node-md .node-line-left,
.node-md .node-line-right { width: 20px; }

/* Color variants */
.node-blue { @apply text-blue-500/70 dark:text-blue-400/60; }
.node-purple { @apply text-violet-500/70 dark:text-violet-400/60; }
.node-teal { @apply text-teal-500/70 dark:text-teal-400/60; }

/* Responsive: smaller nodes on mobile */
@media (max-width: 768px) {
  .floating-node {
    opacity: 0.35;
    transform: scale(0.8);
  }
}
</style>
