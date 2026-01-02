<script setup lang="ts">
defineProps<{
  title: string;
  description: string;
  aspectRatio?: string;
}>();
</script>

<template>
  <div class="media-placeholder" :style="{ aspectRatio: aspectRatio || '16/10' }">
    <div class="media-placeholder-inner">
      <h4 class="media-placeholder-title">{{ title }}</h4>
      <p class="media-placeholder-desc">{{ description }}</p>
    </div>
  </div>
</template>

<style>
@reference "../style.css";

.media-placeholder {
  @apply relative w-full min-h-[280px] h-full max-w-full box-border;
  @apply bg-slate-100 dark:bg-zinc-700 border-2 border-dashed border-slate-300 dark:border-zinc-500 rounded-2xl;
  @apply flex items-center justify-center overflow-hidden transition-all duration-300;
}

.media-placeholder:hover {
  @apply border-violet-600 bg-violet-600/10 dark:border-violet-400 dark:bg-violet-400/10;
}

.media-placeholder-inner {
  @apply text-center p-10 max-w-full box-border;
}

.media-placeholder-title {
  @apply text-base font-bold text-slate-800 dark:text-zinc-200 mb-2;
  font-family: var(--vn-font-display);
}

.media-placeholder-desc {
  @apply text-sm text-slate-500 dark:text-zinc-400 leading-normal;
}
</style>
