<script setup lang="ts">
import Badge from './Badge.vue';

defineProps<{
  badge: string;
  badgeIcon: string;
  badgeColor: 'blue' | 'purple' | 'teal' | 'amber';
  title: string;
  subtitle?: string;
  centered?: boolean;
  largeTitle?: boolean;
}>();
</script>

<template>
  <div class="section-header" :class="{ centered }">
    <Badge :icon="badgeIcon" :color="badgeColor">{{ badge }}</Badge>
    <h2 class="section-title" :class="{ 'section-title-large': largeTitle }">{{ title }}</h2>
    <p v-if="subtitle" class="section-subtitle">{{ subtitle }}</p>
  </div>
</template>

<style>
@reference "../style.css";

.section-header.centered {
  @apply text-center;
}

.section-header.centered .section-subtitle {
  @apply mx-auto;
}

.section-title {
  @apply text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 dark:text-slate-100 leading-tight mb-4 tracking-tight;
  font-family: var(--vn-font-display);
}

.section-title-large {
  @apply text-5xl sm:text-6xl lg:text-7xl;
}

.section-subtitle {
  @apply text-lg font-medium text-slate-600 dark:text-slate-400 mb-16 max-w-xl;
}
</style>
