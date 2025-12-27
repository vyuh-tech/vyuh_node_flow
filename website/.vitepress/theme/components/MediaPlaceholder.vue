<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  type: 'video' | 'animation' | 'image' | 'gif';
  title: string;
  description: string;
  aspectRatio?: string;
}>();

const typeConfig = {
  video: { icon: 'ph:video-fill', label: 'Video' },
  animation: { icon: 'ph:gif-fill', label: 'Animation' },
  image: { icon: 'ph:image-fill', label: 'Image' },
  gif: { icon: 'ph:gif-fill', label: 'GIF' },
};
</script>

<template>
  <div class="media-placeholder" :style="{ aspectRatio: aspectRatio || '16/10' }">
    <div class="media-placeholder-inner">
      <div class="media-placeholder-badge">
        <Icon :icon="typeConfig[type].icon" />
        <span>{{ typeConfig[type].label }}</span>
      </div>
      <h4 class="media-placeholder-title">{{ title }}</h4>
      <p class="media-placeholder-desc">{{ description }}</p>
      <div class="media-placeholder-hint">
        <Icon icon="ph:arrow-square-out-fill" />
        <span>Replace with actual media</span>
      </div>
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

.media-placeholder-badge {
  @apply inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold uppercase tracking-wider;
  @apply bg-white dark:bg-zinc-800 text-slate-500 dark:text-zinc-400 border border-slate-200 dark:border-zinc-600 mb-4;
  font-family: var(--vn-font-mono);
}

.media-placeholder-badge svg {
  @apply text-sm text-violet-600 dark:text-violet-400;
}

.media-placeholder-title {
  @apply text-base font-bold text-slate-800 dark:text-zinc-200 mb-2;
  font-family: var(--vn-font-display);
}

.media-placeholder-desc {
  @apply text-sm text-slate-500 dark:text-zinc-400 leading-normal mb-4;
}

.media-placeholder-hint {
  @apply inline-flex items-center gap-1.5 text-xs text-slate-400 dark:text-zinc-500;
}

.media-placeholder-hint svg {
  @apply text-sm;
}
</style>
