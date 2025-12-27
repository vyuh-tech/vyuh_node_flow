<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  icon?: string;
  color?: 'blue' | 'purple' | 'teal' | 'amber' | 'gray';
}>();
</script>

<template>
  <div class="badge" :class="color ? `badge-${color}` : 'badge-blue'">
    <Icon v-if="icon" :icon="icon" />
    <span><slot /></span>
  </div>
</template>

<style>
.badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  font-family: var(--vn-font-mono);
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-radius: 100px;
  width: fit-content;
}

.badge svg {
  width: 1em;
  height: 1em;
}

/* Color variants */
.badge-blue {
  background: var(--vn-blue-dim);
  color: var(--vn-blue);
  border: 1px solid color-mix(in srgb, var(--vn-blue) 30%, transparent);
}

.badge-purple {
  background: var(--vn-purple-dim);
  color: var(--vn-purple);
  border: 1px solid color-mix(in srgb, var(--vn-purple) 30%, transparent);
}

.badge-teal {
  background: var(--vn-teal-dim);
  color: var(--vn-teal);
  border: 1px solid color-mix(in srgb, var(--vn-teal) 30%, transparent);
}

.badge-amber {
  background: var(--vn-amber-dim);
  color: var(--vn-amber);
  border: 1px solid color-mix(in srgb, var(--vn-amber) 30%, transparent);
}

.badge-gray {
  background: var(--vn-bg-elevated);
  color: var(--vn-text-secondary);
  border: 1px solid var(--vn-border);
}
</style>
