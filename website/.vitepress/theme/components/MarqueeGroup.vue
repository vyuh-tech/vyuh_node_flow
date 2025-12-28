<script setup lang="ts">
import MarqueeLine from './MarqueeLine.vue';

export interface MarqueeLineConfig {
  items: string[];
  color: 'blue' | 'purple' | 'teal' | 'amber';
  reverse?: boolean;
  duration?: number; // Duration in seconds (default: 40)
}

defineProps<{
  lines: MarqueeLineConfig[];
}>();
</script>

<template>
  <section class="py-10 overflow-hidden bg-white/70 dark:bg-zinc-800/50 backdrop-blur-md">
    <MarqueeLine
      v-for="(line, index) in lines"
      :key="index"
      :items="line.items"
      :color="line.color"
      :reverse="line.reverse"
      :duration="line.duration"
    />
  </section>
</template>
