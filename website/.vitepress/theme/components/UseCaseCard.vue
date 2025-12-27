<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  icon: string;
  title: string;
  description: string;
  color: 'blue' | 'purple' | 'teal' | 'amber';
}>();
</script>

<template>
  <div class="use-case-card" :class="'use-case-card-' + color">
    <div class="use-case-icon" :class="'use-case-icon-' + color">
      <Icon :icon="icon" />
    </div>
    <div class="use-case-text">
      <h3 class="use-case-title">{{ title }}</h3>
      <p class="use-case-desc">{{ description }}</p>
    </div>
  </div>
</template>

<style>
@reference "../style.css";

.use-case-card {
  @apply flex items-start gap-6 p-10 bg-white dark:bg-zinc-800 border border-slate-200/60 dark:border-zinc-500/40 rounded-2xl;
  transition: all 0.4s var(--vn-ease-out);
}

.use-case-card:hover {
  @apply -translate-y-1 shadow-xl;
}

.dark .use-case-card:hover {
  box-shadow: 0 0 30px rgba(139, 92, 246, 0.3), 0 0 60px rgba(139, 92, 246, 0.15);
}

.use-case-card-blue:hover { @apply border-blue-600/30 dark:border-blue-400/30; }
.use-case-card-purple:hover { @apply border-violet-500/30 dark:border-violet-400/30; }
.use-case-card-teal:hover { @apply border-teal-500/30 dark:border-teal-400/30; }
.use-case-card-amber:hover { @apply border-amber-500/30 dark:border-amber-400/30; }

.use-case-icon {
  @apply shrink-0 w-12 h-12 flex items-center justify-center rounded-xl text-2xl;
}

.use-case-icon-blue { @apply bg-blue-600/10 text-blue-600 dark:bg-blue-400/15 dark:text-blue-400; }
.use-case-icon-purple { @apply bg-violet-500/10 text-violet-500 dark:bg-violet-400/15 dark:text-violet-400; }
.use-case-icon-teal { @apply bg-teal-500/10 text-teal-500 dark:bg-teal-400/15 dark:text-teal-400; }
.use-case-icon-amber { @apply bg-amber-500/10 text-amber-500 dark:bg-amber-400/15 dark:text-amber-400; }

.use-case-text {
  @apply flex-1;
}

.use-case-title {
  @apply text-lg font-bold text-slate-900 dark:text-zinc-100 mb-1;
  font-family: var(--vn-font-display);
}

.use-case-desc {
  @apply text-sm text-slate-600 dark:text-zinc-400 leading-normal;
}
</style>
