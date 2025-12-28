<script setup lang="ts">
defineProps<{
  items: string[];
  color: 'blue' | 'purple' | 'teal';
  reverse?: boolean;
  duration?: number; // Duration in seconds (default: 40)
}>();
</script>

<template>
  <div
    class="marquee-track"
    :class="['marquee-' + color, { reverse }]"
    :style="duration ? { '--marquee-duration': `${duration}s` } : undefined"
  >
    <div class="marquee-content">
      <span v-for="(item, i) in [...items, ...items]" :key="i" class="marquee-item">
        {{ item }}
      </span>
    </div>
  </div>
</template>

<style>
@reference "../style.css";

.marquee-track {
  --marquee-duration: 40s; /* Default duration, can be overridden via style prop */
  @apply relative py-2 overflow-hidden whitespace-nowrap;
  mask-image: linear-gradient(90deg, transparent, black 10%, black 90%, transparent);
  -webkit-mask-image: linear-gradient(90deg, transparent, black 10%, black 90%, transparent);
}

.marquee-content {
  @apply inline-flex;
  animation: marqueeScroll var(--marquee-duration) linear infinite;
}

.marquee-track.reverse .marquee-content {
  animation-direction: reverse;
}

@keyframes marqueeScroll {
  0% { transform: translateX(0); }
  100% { transform: translateX(-50%); }
}

.marquee-item {
  @apply inline-block px-8 text-xl font-bold whitespace-nowrap;
  font-family: var(--vn-font-display);
}

.marquee-blue .marquee-item {
  @apply text-blue-600/40 dark:text-blue-400/50;
}

.marquee-purple .marquee-item {
  @apply text-violet-500/40 dark:text-violet-400/50;
}

.marquee-teal .marquee-item {
  @apply text-teal-500/40 dark:text-teal-400/50;
}
</style>
