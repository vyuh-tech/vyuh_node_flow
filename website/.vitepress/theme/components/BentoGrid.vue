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
  @apply grid-cols-1 md:grid-cols-2 xl:grid-cols-3;
}
</style>
