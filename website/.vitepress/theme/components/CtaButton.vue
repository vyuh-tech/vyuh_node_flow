<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  href?: string;
  icon?: string;
  variant?: 'primary' | 'secondary';
  size?: 'default' | 'large';
  external?: boolean;
}>();

defineEmits<{
  click: [event: MouseEvent];
}>();
</script>

<template>
  <!-- Render as anchor when href is provided -->
  <a
    v-if="href"
    :href="href"
    class="hero-btn"
    :class="[
      variant === 'secondary' ? 'hero-btn-secondary' : 'hero-btn-primary',
      size === 'large' ? 'hero-btn-lg' : '',
    ]"
    :target="external ? '_blank' : undefined"
    :rel="external ? 'noopener noreferrer' : undefined"
  >
    <Icon v-if="icon" :icon="icon" />
    <slot />
  </a>
  <!-- Render as button when no href (click handler mode) -->
  <button
    v-else
    type="button"
    class="hero-btn"
    :class="[
      variant === 'secondary' ? 'hero-btn-secondary' : 'hero-btn-primary',
      size === 'large' ? 'hero-btn-lg' : '',
    ]"
    @click="$emit('click', $event)"
  >
    <Icon v-if="icon" :icon="icon" />
    <slot />
  </button>
</template>

<style>
@reference "../style.css";

.hero-btn {
  @apply inline-flex items-center gap-2 px-7 py-3.5 font-semibold text-sm rounded-xl cursor-pointer no-underline;
  @apply max-md:justify-center max-md:w-full;
  font-family: var(--vn-font-body);
  transition: transform 160ms var(--vn-ease-out), border-color 160ms ease-out, background-color 160ms ease-out, color 160ms ease-out, box-shadow 160ms ease-out;
}

.hero-btn-primary {
  @apply text-white border border-blue-700 bg-blue-700;
  box-shadow: 0 8px 18px -14px rgba(29, 78, 216, 0.75);
}

.hero-btn-primary:hover {
  @apply -translate-y-0.5 bg-blue-800 border-blue-800;
  box-shadow:
    0 14px 30px -14px rgba(29, 78, 216, 0.78),
    0 0 0 4px rgba(37, 99, 235, 0.1);
}

.hero-btn-secondary {
  @apply bg-white text-slate-700 border border-slate-200;
  @apply dark:bg-zinc-700 dark:text-zinc-300 dark:border-zinc-500;
}

.hero-btn-secondary:hover {
  @apply -translate-y-0.5 border-blue-700 text-blue-700;
  @apply dark:border-blue-400 dark:text-blue-400;
  box-shadow:
    0 12px 26px -16px rgba(30, 64, 175, 0.45),
    0 0 0 4px rgba(37, 99, 235, 0.07);
}

.hero-btn:active {
  transform: translateY(0);
  box-shadow: none;
}

.hero-btn:focus-visible {
  @apply outline-2 outline-offset-2 outline-blue-600;
}

.hero-btn-lg {
  @apply px-10 py-4 text-base;
}
</style>
