<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  icon?: string;
  color?: 'blue' | 'purple' | 'teal' | 'amber' | 'gray';
}>();
</script>

<template>
  <div class="badge-wrapper" :class="color ? `badge-color-${color}` : 'badge-color-blue'">
    <div class="badge-connector">
      <div class="badge-line" />
    </div>
    <div class="badge-port-wrapper">
      <div class="badge-port" />
    </div>
    <div class="badge">
      <Icon v-if="icon" :icon="icon" />
      <span><slot /></span>
    </div>
  </div>
</template>

<style>
@reference "../style.css";

.badge-wrapper {
  @apply relative inline-flex flex-col items-center mb-6;
}

.badge-connector {
  @apply flex flex-col items-center;
}

.badge-line {
  @apply h-20;
  width: 2px;
  background: repeating-linear-gradient(
    to bottom,
    currentColor 0,
    currentColor 3px,
    transparent 3px,
    transparent 6px
  );
  opacity: 0.4;
  mask-image: linear-gradient(to bottom, transparent, black 40%);
  -webkit-mask-image: linear-gradient(to bottom, transparent, black 40%);
}

.badge-port-wrapper {
  @apply relative h-0 w-full flex justify-center;
}

.badge-port {
  @apply w-2.5 h-2.5 rounded-full border-2 absolute;
  @apply bg-white dark:bg-zinc-900;
  border-color: currentColor;
  opacity: 0.8;
  top: -5px; /* Half of height to center on the badge top border */
}

.badge {
  @apply inline-flex items-center gap-2 px-5 py-2 rounded-full text-xs font-semibold uppercase tracking-widest w-fit;
  font-family: var(--vn-font-mono);
}

.badge svg {
  @apply text-sm;
}

/* Color variants - applied to wrapper for connector inheritance */
.badge-color-blue {
  @apply text-blue-600 dark:text-blue-400;
}
.badge-color-blue .badge {
  @apply bg-blue-600/10 border border-blue-600/30;
  @apply dark:bg-blue-400/15 dark:border-blue-400/30;
  box-shadow: var(--glow-blue);
}

.badge-color-purple {
  @apply text-violet-500 dark:text-violet-400;
}
.badge-color-purple .badge {
  @apply bg-violet-500/10 border border-violet-500/30;
  @apply dark:bg-violet-400/15 dark:border-violet-400/30;
  box-shadow: var(--glow-purple);
}

.badge-color-teal {
  @apply text-teal-500 dark:text-teal-400;
}
.badge-color-teal .badge {
  @apply bg-teal-500/10 border border-teal-500/30;
  @apply dark:bg-teal-400/15 dark:border-teal-400/30;
  box-shadow: var(--glow-teal);
}

.badge-color-amber {
  @apply text-amber-600 dark:text-amber-400;
}
.badge-color-amber .badge {
  @apply bg-amber-600/10 border border-amber-600/30;
  @apply dark:bg-amber-400/15 dark:border-amber-400/30;
  box-shadow: var(--glow-amber);
}

.badge-color-gray {
  @apply text-slate-600 dark:text-zinc-400;
}
.badge-color-gray .badge {
  @apply bg-slate-100 border border-slate-200;
  @apply dark:bg-zinc-700 dark:border-zinc-600;
}
</style>
