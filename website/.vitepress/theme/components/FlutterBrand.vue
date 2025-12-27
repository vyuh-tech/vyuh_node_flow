<script setup lang="ts">
import { Icon } from '@iconify/vue';
</script>

<template>
  <span class="flutter-brand"><Icon icon="simple-icons:flutter" /> Flutter</span>
</template>

<style>
.flutter-brand {
  display: inline-flex;
  align-items: baseline;
  gap: 0.2em;
  font-weight: 900;
  color: var(--vn-blue);
}

.flutter-brand svg {
  position: relative;
  top: 0.1em;
}
</style>
