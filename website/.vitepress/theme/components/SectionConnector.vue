<script setup lang="ts">
defineProps<{
  color?: 'blue' | 'purple' | 'teal';
  variant?: 'left' | 'right' | 'center';
}>();
</script>

<template>
  <div class="section-connector" :class="[`connector-${color || 'purple'}`, `connector-${variant || 'center'}`]">
    <svg class="connector-svg" viewBox="0 0 200 120" preserveAspectRatio="none">
      <!-- Main flowing path -->
      <path
        class="connector-path"
        d="M 100 0 Q 100 60, 100 120"
        fill="none"
        stroke-width="2"
      />
      <!-- Animated dash overlay -->
      <path
        class="connector-path-animated"
        d="M 100 0 Q 100 60, 100 120"
        fill="none"
        stroke-width="2"
      />
    </svg>
    <!-- Port at top -->
    <div class="connector-port connector-port-top" />
    <!-- Port at bottom -->
    <div class="connector-port connector-port-bottom" />
  </div>
</template>

<style>
@reference "../style.css";

.section-connector {
  @apply relative h-24 w-full flex justify-center pointer-events-none z-20;
}

.connector-svg {
  @apply h-full w-48;
  z-index: 1; /* Behind ports */
}

.connector-path {
  stroke: currentColor;
  opacity: 0.2;
}

.connector-path-animated {
  stroke: currentColor;
  opacity: 0.6;
  stroke-dasharray: 8 12;
  animation: flowDown 2s linear infinite;
}

@keyframes flowDown {
  0% { stroke-dashoffset: 40; }
  100% { stroke-dashoffset: 0; }
}

.connector-port {
  @apply absolute w-3 h-3 rounded-full border-2;
  @apply bg-white dark:bg-zinc-900;
  left: 50%;
  transform: translateX(-50%);
  border-color: currentColor;
  z-index: 2; /* Above SVG lines */
}

.connector-port-top {
  top: -6px;
}

.connector-port-bottom {
  bottom: -6px;
}

/* Color variants */
.connector-blue { @apply text-blue-500 dark:text-blue-400; }
.connector-purple { @apply text-violet-500 dark:text-violet-400; }
.connector-teal { @apply text-teal-500 dark:text-teal-400; }

/* Position variants */
.connector-left {
  @apply justify-start pl-16;
}

.connector-right {
  @apply justify-end pr-16;
}
</style>
