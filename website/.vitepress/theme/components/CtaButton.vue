<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  href: string;
  icon?: string;
  variant?: 'primary' | 'secondary';
  size?: 'default' | 'large';
  external?: boolean;
}>();
</script>

<template>
  <a
    :href="href"
    class="cta-button"
    :class="[
      variant === 'secondary' ? 'cta-button-secondary' : 'cta-button-primary',
      size === 'large' ? 'cta-button-lg' : ''
    ]"
    :target="external ? '_blank' : undefined"
  >
    <Icon v-if="icon" :icon="icon" />
    <slot />
  </a>
</template>

<style>
.cta-button {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.875rem 1.75rem;
  font-family: var(--vn-font-sans);
  font-size: 0.95rem;
  font-weight: 600;
  border-radius: var(--vn-radius-md);
  cursor: pointer;
  transition: all 0.4s var(--vn-ease-out);
  text-decoration: none;
  border: none;
}

.cta-button-primary {
  background: linear-gradient(135deg, var(--vn-blue), var(--vn-purple));
  color: white;
  box-shadow: 0 4px 20px rgba(37, 99, 235, 0.3);
}

.cta-button-primary:hover {
  box-shadow: 0 12px 40px rgba(37, 99, 235, 0.5), 0 0 60px rgba(139, 92, 246, 0.3);
  transform: translateY(-4px);
}

.cta-button-secondary {
  background: var(--vn-bg-surface);
  color: var(--vn-text-primary);
  border: 1px solid var(--vn-border-strong);
  box-shadow: var(--vn-shadow);
}

.cta-button-secondary:hover {
  border-color: var(--vn-blue);
  color: var(--vn-blue);
  background: var(--vn-blue-dim);
}

.cta-button-lg {
  padding: 1.125rem 2.5rem;
  font-size: 1.1rem;
}

/* Mobile responsiveness */
@media (max-width: 767px) {
  .cta-button {
    justify-content: center;
    width: 100%;
  }
}
</style>
