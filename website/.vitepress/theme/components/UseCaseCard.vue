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
  <div class="use-case-card" :class="'use-case-card-' + color">
    <div class="use-case-icon" :class="'use-case-icon-' + color">
      <Icon :icon="icon" />
    </div>
    <div class="use-case-text">
      <h3 class="use-case-title">{{ title }}</h3>
      <p class="use-case-desc">{{ description }}</p>
    </div>
  </div>
</template>
