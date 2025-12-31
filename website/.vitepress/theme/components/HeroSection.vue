<script setup lang="ts">
defineProps<{
  /** Layout variant: 'split' for two-column, 'centered' for single centered column */
  variant?: 'split' | 'centered';
  /** Add a top border */
  borderTop?: boolean;
  /** Add a bottom border */
  borderBottom?: boolean;
}>();
</script>

<template>
  <section
    class="hero-section"
    :class="[
      borderTop && 'border-t border-slate-200/50 dark:border-zinc-700/50',
      borderBottom && 'border-b border-slate-200/50 dark:border-zinc-700/50',
    ]"
  >
    <!-- Blur effects background -->
    <div class="absolute inset-0 z-0">
      <div class="hero-blur bg-blue-500 -top-48 -left-24 w-[600px] h-[600px] opacity-15 dark:opacity-25" />
      <div class="hero-blur bg-violet-500 top-24 -right-36 w-[500px] h-[500px] opacity-12 dark:opacity-20" />
      <div class="hero-blur bg-teal-500 -bottom-24 left-1/3 w-[400px] h-[400px] opacity-10 dark:opacity-18" />
    </div>

    <!-- Split layout (default) - two columns -->
    <div v-if="variant !== 'centered'" class="hero-content-split">
      <div class="hero-text">
        <slot name="text" />
      </div>
      <div class="hero-visual">
        <slot name="visual" />
      </div>
    </div>

    <!-- Centered layout - single column -->
    <div v-else class="hero-content-centered">
      <slot />
    </div>
  </section>
</template>

<style>
@reference "../style.css";

.hero-section {
  @apply relative min-h-screen flex items-center justify-center py-10 px-6 overflow-hidden;
}

.hero-blur {
  @apply absolute rounded-full;
  filter: blur(120px);
}

/* Split layout - two columns on xl+, single column below */
.hero-content-split {
  @apply relative z-10 max-w-7xl w-full grid xl:grid-cols-[1fr_1.4fr] gap-16 items-center;
  @apply max-xl:grid-cols-1 max-xl:text-center max-xl:justify-items-center;
}

.hero-text {
  animation: fadeSlideUp 0.8s var(--vn-ease-out) forwards;
  @apply opacity-0;
}

.hero-visual {
  @apply relative w-full;
  animation: fadeSlideUp 0.8s var(--vn-ease-out) 0.5s forwards;
  @apply opacity-0;
}

/* Centered layout - single column */
.hero-content-centered {
  @apply relative z-10 max-w-4xl w-full flex flex-col items-center text-center;
}

@keyframes fadeSlideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
