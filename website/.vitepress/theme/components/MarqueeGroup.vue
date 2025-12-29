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
  <section class="py-16 overflow-hidden bg-slate-100/80 dark:bg-zinc-700/70 backdrop-blur-md border-y border-slate-200/60 dark:border-zinc-600/50">
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
