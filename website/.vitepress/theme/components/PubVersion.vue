<script setup lang="ts">
import { data as pubData } from '../data/pubVersion.data';

withDefaults(
  defineProps<{
    prefix?: string;
  }>(),
  {
    prefix: '^',
  }
);
</script>

<template>
  <code class="pub-version">{{ prefix }}{{ pubData.version }}</code>
</template>

<style scoped>
.pub-version {
  font-family: var(--vp-font-family-mono);
  font-size: 0.875em;
  color: var(--vp-c-brand-1);
  background-color: var(--vp-c-brand-soft);
  border-radius: 4px;
  padding: 0.15em 0.4em;
}
</style>
