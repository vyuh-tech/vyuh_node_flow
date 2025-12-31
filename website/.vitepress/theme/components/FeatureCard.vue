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
  <div class="card" :class="'card-' + color">
    <div class="port port-left" :class="'port-' + color" />
    <div class="port port-right" :class="'port-' + color" />

    <div class="header">
      <div class="icon" :class="'icon-' + color">
        <Icon :icon="icon" />
      </div>
      <span class="title">{{ title }}</span>
    </div>
    <p class="description">{{ description }}</p>
  </div>
</template>

<style scoped>
@reference "../style.css";

.card {
  @apply relative p-6 bg-white dark:bg-zinc-800 border border-slate-200/60 dark:border-zinc-500/40 rounded-2xl;
  transition: all 0.4s var(--vn-ease-out);
}

.card:hover {
  @apply -translate-y-1;
}

.card-blue:hover { @apply border-blue-600/30 dark:border-blue-400/30; }
.card-purple:hover { @apply border-violet-500/30 dark:border-violet-400/30; }
.card-teal:hover { @apply border-teal-500/30 dark:border-teal-400/30; }
.card-amber:hover { @apply border-amber-500/30 dark:border-amber-400/30; }

/* Light mode: color-tinted shadows */
.card-blue:hover {
  box-shadow: 0 20px 40px -10px rgba(37, 99, 235, 0.25), 0 8px 16px -8px rgba(37, 99, 235, 0.15);
}
.card-purple:hover {
  box-shadow: 0 20px 40px -10px rgba(139, 92, 246, 0.25), 0 8px 16px -8px rgba(139, 92, 246, 0.15);
}
.card-teal:hover {
  box-shadow: 0 20px 40px -10px rgba(20, 184, 166, 0.25), 0 8px 16px -8px rgba(20, 184, 166, 0.15);
}
.card-amber:hover {
  box-shadow: 0 20px 40px -10px rgba(245, 158, 11, 0.25), 0 8px 16px -8px rgba(245, 158, 11, 0.15);
}

/* Dark mode: color-specific glow effects */
.dark .card-blue:hover {
  box-shadow: 0 0 30px rgba(96, 165, 250, 0.3), 0 0 60px rgba(96, 165, 250, 0.15);
}
.dark .card-purple:hover {
  box-shadow: 0 0 30px rgba(167, 139, 250, 0.3), 0 0 60px rgba(167, 139, 250, 0.15);
}
.dark .card-teal:hover {
  box-shadow: 0 0 30px rgba(45, 212, 191, 0.3), 0 0 60px rgba(45, 212, 191, 0.15);
}
.dark .card-amber:hover {
  box-shadow: 0 0 30px rgba(251, 191, 36, 0.3), 0 0 60px rgba(251, 191, 36, 0.15);
}

.header {
  @apply flex items-center gap-3 mb-3;
}

.icon {
  @apply w-10 h-10 flex items-center justify-center rounded-xl shrink-0 text-xl;
}

.icon-blue { @apply bg-blue-600/10 text-blue-600 dark:bg-blue-400/15 dark:text-blue-400; }
.icon-purple { @apply bg-violet-500/10 text-violet-500 dark:bg-violet-400/15 dark:text-violet-400; }
.icon-teal { @apply bg-teal-500/10 text-teal-500 dark:bg-teal-400/15 dark:text-teal-400; }
.icon-amber { @apply bg-amber-500/10 text-amber-500 dark:bg-amber-400/15 dark:text-amber-400; }

.title {
  @apply text-base font-bold text-slate-900 dark:text-zinc-100;
  font-family: var(--vn-font-display);
}

.description {
  @apply text-sm text-slate-600 dark:text-zinc-400 leading-relaxed m-0;
}

.port {
  @apply absolute w-2.5 h-2.5 rounded-full border-2 bg-white dark:bg-zinc-900 opacity-0 transition-opacity duration-300;
  top: 50%;
  transform: translateY(-50%);
}

.card:hover .port { @apply opacity-100; }

.port-left { left: -5px; }
.port-right { right: -5px; }

.port-blue { @apply border-blue-600 dark:border-blue-400; }
.port-purple { @apply border-violet-500 dark:border-violet-400; }
.port-teal { @apply border-teal-500 dark:border-teal-400; }
.port-amber { @apply border-amber-500 dark:border-amber-400; }
</style>
