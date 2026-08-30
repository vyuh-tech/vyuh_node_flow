<script setup lang="ts">
import Badge from './Badge.vue';

defineProps<{
  badge: string;
  badgeIcon: string;
  badgeColor: 'blue' | 'purple' | 'teal' | 'amber';
  title?: string;
  subtitle?: string;
  centered?: boolean;
  largeTitle?: boolean;
}>();
</script>

<template>
  <div class="section-header" :class="{ centered }">
    <Badge :icon="badgeIcon" :color="badgeColor">{{ badge }}</Badge>
    <h2 class="section-title" :class="{ 'section-title-large': largeTitle }">
      <slot name="title">{{ title }}</slot>
    </h2>
    <p v-if="subtitle" class="section-subtitle">{{ subtitle }}</p>
  </div>
</template>

<style>
@reference "../style.css";

.section-header.centered {
  @apply flex flex-col items-center text-center;
}

.section-header.centered .section-subtitle {
  @apply mx-auto;
}

.section-title {
  @apply text-balance text-4xl sm:text-5xl font-bold text-slate-950 dark:text-slate-50 leading-tight mb-4;
  font-family: var(--vn-font-display);
}

.section-title-large {
  @apply text-5xl sm:text-6xl lg:text-7xl;
}

.section-subtitle {
  @apply text-pretty text-lg text-slate-600 dark:text-slate-400 mb-16 max-w-2xl;
}
</style>
