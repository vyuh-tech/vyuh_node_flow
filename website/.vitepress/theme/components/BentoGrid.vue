<script setup lang="ts">
/**
 * BentoGrid - A responsive grid with varied column spans for visual interest.
 * Uses CSS nth-child selectors for the bento layout pattern.
 */
</script>

<template>
  <div class="bento-grid">
    <slot />
  </div>
</template>

<style>
@reference "../style.css";

.bento-grid {
  @apply grid gap-6 max-w-7xl mx-auto;
  @apply max-md:grid-cols-1 md:max-lg:grid-cols-3 lg:grid-cols-5;
}

/* Mobile: single column - all items span 1 */
.bento-grid > * {
  @apply max-md:col-span-1;
}

/* Tablet (md to lg): 3-column layout with repeating pattern */
@media (min-width: 768px) and (max-width: 1023px) {
  .bento-grid > :nth-child(4n + 1) { grid-column: span 2; }
  .bento-grid > :nth-child(4n + 2) { grid-column: span 1; }
  .bento-grid > :nth-child(4n + 3) { grid-column: span 1; }
  .bento-grid > :nth-child(4n) { grid-column: span 2; }
}

/* Desktop (lg+): 5-column layout with custom spans */
@media (min-width: 1024px) {
  .bento-grid > :nth-child(1) { grid-column: span 2; }
  .bento-grid > :nth-child(2) { grid-column: span 2; }
  .bento-grid > :nth-child(3) { grid-column: span 1; }
  .bento-grid > :nth-child(4) { grid-column: span 1; }
  .bento-grid > :nth-child(5) { grid-column: span 2; }
  .bento-grid > :nth-child(6) { grid-column: span 2; }
  .bento-grid > :nth-child(7) { grid-column: span 2; }
  .bento-grid > :nth-child(8) { grid-column: span 1; }
  .bento-grid > :nth-child(9) { grid-column: span 2; }
  .bento-grid > :nth-child(10) { grid-column: span 2; }
  .bento-grid > :nth-child(11) { grid-column: span 1; }
  .bento-grid > :nth-child(12) { grid-column: span 2; }
}
</style>
