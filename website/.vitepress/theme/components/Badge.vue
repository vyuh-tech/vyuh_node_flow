<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  icon?: string;
  color?: 'blue' | 'purple' | 'teal' | 'amber' | 'gray';
}>();
</script>

<template>
  <div class="badge" :class="color ? `badge-${color}` : 'badge-blue'">
    <Icon v-if="icon" :icon="icon" />
    <span><slot /></span>
  </div>
</template>

<style>
@reference "../style.css";

.badge {
  @apply inline-flex items-center gap-2 px-5 py-2 rounded-full text-xs font-semibold uppercase tracking-widest mb-6 w-fit;
  font-family: var(--vn-font-mono);
}

.badge svg {
  @apply text-sm;
}

/* Color variants with glow effects */
.badge-blue {
  @apply bg-blue-600/10 text-blue-600 border border-blue-600/30;
  @apply dark:bg-blue-400/15 dark:text-blue-400 dark:border-blue-400/30;
  box-shadow: var(--glow-blue);
}

.badge-purple {
  @apply bg-violet-500/10 text-violet-500 border border-violet-500/30;
  @apply dark:bg-violet-400/15 dark:text-violet-400 dark:border-violet-400/30;
  box-shadow: var(--glow-purple);
}

.badge-teal {
  @apply bg-teal-500/10 text-teal-500 border border-teal-500/30;
  @apply dark:bg-teal-400/15 dark:text-teal-400 dark:border-teal-400/30;
  box-shadow: var(--glow-teal);
}

.badge-amber {
  @apply bg-amber-600/10 text-amber-600 border border-amber-600/30;
  @apply dark:bg-amber-400/15 dark:text-amber-400 dark:border-amber-400/30;
  box-shadow: var(--glow-amber);
}

.badge-gray {
  @apply bg-slate-100 text-slate-600 border border-slate-200;
  @apply dark:bg-zinc-700 dark:text-zinc-400 dark:border-zinc-600;
}
</style>
