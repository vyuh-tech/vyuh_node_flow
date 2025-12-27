<script setup lang="ts">
defineProps<{
  items: string[];
  color: 'blue' | 'purple' | 'teal';
  reverse?: boolean;
}>();
</script>

<template>
  <div class="marquee-track" :class="['marquee-' + color, { reverse }]">
    <div class="marquee-content">
      <span v-for="(item, i) in [...items, ...items]" :key="i" class="marquee-item">
        {{ item }}
      </span>
    </div>
  </div>
</template>
