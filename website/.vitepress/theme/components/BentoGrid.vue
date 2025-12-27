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
  grid-template-columns: repeat(5, 1fr);
}

/* Bento layout pattern - varied column spans */
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

/* Tablet: 3-column layout */
@media (max-width: 1100px) and (min-width: 768px) {
  .bento-grid {
    grid-template-columns: repeat(3, 1fr);
  }
  .bento-grid > :nth-child(4n + 1) { grid-column: span 2; }
  .bento-grid > :nth-child(4n + 2) { grid-column: span 1; }
  .bento-grid > :nth-child(4n + 3) { grid-column: span 1; }
  .bento-grid > :nth-child(4n) { grid-column: span 2; }
}

/* Mobile: single column */
@media (max-width: 767px) {
  .bento-grid {
    @apply grid-cols-1;
  }
  .bento-grid > :nth-child(n) {
    grid-column: span 1;
  }
}
</style>
