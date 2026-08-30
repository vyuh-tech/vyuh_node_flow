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
    <div class="hero-rule" aria-hidden="true" />

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
  @apply relative min-h-dvh flex items-center justify-center px-6 py-24 overflow-hidden border-b border-slate-200 bg-transparent;
  @apply dark:border-zinc-800;
}

.hero-rule {
  @apply absolute top-0 bottom-0 left-[calc(50%-1px)] w-px bg-slate-100 dark:bg-zinc-900 max-xl:hidden;
}

/* Split layout - two columns on xl+, single column below */
.hero-content-split {
  @apply relative z-10 max-w-7xl w-full grid xl:grid-cols-[1fr_1.35fr] gap-16 items-center;
  @apply max-xl:grid-cols-1 max-xl:text-center max-xl:justify-items-center;
}

.hero-text {
  @apply max-w-2xl;
}

.hero-visual {
  @apply relative w-full;
}

/* Centered layout - single column */
.hero-content-centered {
  @apply relative z-10 max-w-4xl w-full flex flex-col items-center text-center;
}

</style>
