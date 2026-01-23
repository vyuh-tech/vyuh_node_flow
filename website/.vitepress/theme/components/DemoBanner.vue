<script lang="ts" setup>
import {Icon} from '@iconify/vue';
</script>

<template>
  <a
      class="demo-banner"
      href="https://editor.flow.vyuh.tech"
      rel="noopener"
      target="_blank"
  >
    <span class="demo-banner-badge">Beta</span>
    <span class="demo-banner-text">Try our live BPMN Workflow Editor</span>
    <Icon class="demo-banner-arrow" icon="ph:arrow-right-bold"/>
  </a>
</template>

<style>
@reference "../style.css";

.demo-banner {
  @apply hidden sm:flex;
  /* Hide on mobile */
  @apply fixed top-0 left-0 right-0;
  @apply z-[60];
  /* Above VitePress nav (z-50) */
  @apply bg-gradient-to-r from-violet-600 via-purple-600 to-indigo-600;
  @apply dark:from-violet-500 dark:via-purple-500 dark:to-indigo-500;
  @apply text-white;
  @apply items-center justify-center gap-2;
  @apply py-1.5 px-4;
  @apply text-xs font-medium;
  @apply hover:brightness-110 transition-all duration-200;
  @apply no-underline;
}

.demo-banner:hover {
  @apply text-white no-underline;
}

.demo-banner-badge {
  @apply px-1.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider;
  @apply bg-white/20;
}

.demo-banner-text {
  @apply opacity-90;
}

.demo-banner-arrow {
  @apply text-xs opacity-70;
  transition: transform 0.2s ease;
}

.demo-banner:hover .demo-banner-arrow {
  transform: translateX(2px);
}
</style>
