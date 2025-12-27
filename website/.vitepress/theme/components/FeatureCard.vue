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
  <div class="feature-card" :class="'feature-card-' + color">
    <div class="feature-icon" :class="'feature-icon-' + color">
      <Icon :icon="icon" />
    </div>
    <h3 class="feature-title">{{ title }}</h3>
    <p class="feature-desc">{{ description }}</p>
  </div>
</template>
