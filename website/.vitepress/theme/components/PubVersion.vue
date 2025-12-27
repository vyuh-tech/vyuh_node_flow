<script setup lang="ts">
import { usePubVersion } from '../composables/usePubVersion';

const props = withDefaults(
  defineProps<{
    package?: string;
    prefix?: string;
  }>(),
  {
    package: 'vyuh_node_flow',
    prefix: '^',
  }
);

const { version, loading } = usePubVersion(props.package);
</script>

<template>
  <code class="pub-version">
    <template v-if="loading">
      <span class="version-loading">{{ prefix }}...</span>
    </template>
    <template v-else>
      {{ prefix }}{{ version }}
    </template>
  </code>
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

.version-loading {
  animation: pulse 1s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 0.4; }
  50% { opacity: 1; }
}
</style>
