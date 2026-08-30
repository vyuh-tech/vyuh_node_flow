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
  transition: transform 160ms ease-out, border-color 160ms ease-out, box-shadow 160ms ease-out;
}

.card:hover {
  @apply -translate-y-1;
}

.card-blue:hover { @apply border-blue-600/30 dark:border-blue-400/30; }
.card-purple:hover { @apply border-violet-500/30 dark:border-violet-400/30; }
.card-teal:hover { @apply border-teal-500/30 dark:border-teal-400/30; }
.card-amber:hover { @apply border-amber-500/30 dark:border-amber-400/30; }

.card:hover {
  @apply shadow-lg;
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
