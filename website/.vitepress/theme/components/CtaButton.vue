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
    class="hero-btn"
    :class="[
      variant === 'secondary' ? 'hero-btn-secondary' : 'hero-btn-primary',
      size === 'large' ? 'hero-btn-lg' : '',
    ]"
    :target="external ? '_blank' : undefined"
  >
    <Icon v-if="icon" :icon="icon" />
    <slot />
  </a>
</template>

<style>
@reference "../style.css";

.hero-btn {
  @apply inline-flex items-center gap-2 px-7 py-3.5 font-semibold text-sm rounded-xl cursor-pointer no-underline;
  font-family: var(--vn-font-display);
  transition: all 0.3s var(--vn-ease-out);
}

.hero-btn-primary {
  @apply text-white border-none;
  background: linear-gradient(
    135deg,
    theme('colors.blue.600'),
    theme('colors.violet.500')
  );
  box-shadow: 0 4px 20px rgba(37, 99, 235, 0.3);
}

.hero-btn-primary:hover {
  @apply -translate-y-1;
  box-shadow:
    0 12px 40px rgba(37, 99, 235, 0.5),
    0 0 60px rgba(139, 92, 246, 0.3);
}

.hero-btn-secondary {
  @apply bg-white text-slate-700 border border-slate-200;
  @apply dark:bg-zinc-700 dark:text-zinc-300 dark:border-zinc-500;
}

.hero-btn-secondary:hover {
  @apply border-violet-600 text-violet-600;
  @apply dark:border-violet-400 dark:text-violet-400;
}

.hero-btn-lg {
  @apply px-10 py-4 text-base;
}

/* Mobile responsiveness */
@media (max-width: 767px) {
  .hero-btn {
    @apply justify-center w-full;
  }
}
</style>
