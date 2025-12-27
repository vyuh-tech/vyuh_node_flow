<script setup lang="ts">
import { Icon } from '@iconify/vue';
</script>

<template>
  <span class="flutter-brand"><Icon icon="simple-icons:flutter" /> Flutter</span>
</template>

<style>
@reference "../style.css";

.flutter-brand {
  @apply inline-flex items-baseline gap-1 font-black text-blue-600 dark:text-blue-400;
}

.flutter-brand svg {
  @apply relative top-[0.1em];
}
</style>
