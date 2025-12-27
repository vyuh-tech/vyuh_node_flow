<script setup lang="ts">
import { Icon } from '@iconify/vue';

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
    <div class="badge" :class="'badge-' + badgeColor">
      <Icon :icon="badgeIcon" />
      <span>{{ badge }}</span>
    </div>
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
