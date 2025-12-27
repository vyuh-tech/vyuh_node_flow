<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  icon: string;
  title: string;
  description: string;
  color: 'blue' | 'purple' | 'teal' | 'amber';
  layout?: 'vertical' | 'horizontal';
}>();
</script>

<template>
  <div
    class="feature-card"
    :class="[
      'feature-card-' + color,
      layout === 'horizontal' ? 'feature-card-horizontal' : ''
    ]"
  >
    <div class="feature-icon" :class="'feature-icon-' + color">
      <Icon :icon="icon" />
    </div>
    <div class="feature-content">
      <h3 class="feature-title">{{ title }}</h3>
      <p class="feature-desc">{{ description }}</p>
    </div>
  </div>
</template>

<style>
@reference "../style.css";

.feature-card {
  @apply relative p-10 bg-white dark:bg-zinc-800 border border-slate-200/60 dark:border-zinc-500/40 rounded-2xl overflow-hidden;
  transition: all 0.4s var(--vn-ease-out);
}

.feature-card:hover {
  @apply -translate-y-1 shadow-xl;
}

.dark .feature-card:hover {
  box-shadow: 0 0 30px rgba(139, 92, 246, 0.3), 0 0 60px rgba(139, 92, 246, 0.15);
}

.feature-card-blue:hover { @apply border-blue-600/30 dark:border-blue-400/30; }
.feature-card-purple:hover { @apply border-violet-500/30 dark:border-violet-400/30; }
.feature-card-teal:hover { @apply border-teal-500/30 dark:border-teal-400/30; }
.feature-card-amber:hover { @apply border-amber-500/30 dark:border-amber-400/30; }

/* Horizontal layout variant */
.feature-card-horizontal {
  @apply flex items-start gap-6;
}

.feature-card-horizontal .feature-icon {
  @apply shrink-0 mb-0;
}

.feature-card-horizontal .feature-content {
  @apply flex-1;
}

.feature-card-horizontal .feature-desc {
  @apply text-sm leading-normal;
}

.feature-icon {
  @apply w-12 h-12 flex items-center justify-center rounded-xl mb-6 text-2xl;
}

.feature-icon-blue { @apply bg-blue-600/10 text-blue-600 dark:bg-blue-400/15 dark:text-blue-400; }
.feature-icon-purple { @apply bg-violet-500/10 text-violet-500 dark:bg-violet-400/15 dark:text-violet-400; }
.feature-icon-teal { @apply bg-teal-500/10 text-teal-500 dark:bg-teal-400/15 dark:text-teal-400; }
.feature-icon-amber { @apply bg-amber-500/10 text-amber-500 dark:bg-amber-400/15 dark:text-amber-400; }

.feature-content {
  /* Default: no special styling needed for vertical layout */
}

.feature-title {
  @apply text-lg font-bold text-slate-900 dark:text-zinc-100 mb-2;
  font-family: var(--vn-font-display);
}

.feature-desc {
  @apply text-base text-slate-600 dark:text-zinc-400 leading-relaxed;
}
</style>
