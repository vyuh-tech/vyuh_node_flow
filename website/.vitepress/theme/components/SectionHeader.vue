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

<style scoped>
.section-header.centered {
  text-align: center;
}

.section-header.centered .section-subtitle {
  margin-left: auto;
  margin-right: auto;
}
</style>
