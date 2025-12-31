<script setup lang="ts">
defineProps<{
  color?: 'amber' | 'blue' | 'purple' | 'teal';
  size?: 'sm' | 'lg' | 'nav';
}>();
</script>

<template>
  <span
    class="title-badge"
    :class="[
      'title-badge-' + (color || 'amber'),
      size === 'sm' ? 'title-badge-sm' : size === 'nav' ? 'title-badge-nav' : 'title-badge-lg'
    ]"
  >
    <slot />
  </span>
</template>

<style>
@reference "../style.css";

.title-badge {
  @apply inline-block uppercase;
  font-family: var(--vn-font-mono);
}

/* Size: Large (default) - for hero titles */
.title-badge-lg {
  @apply block text-4xl sm:text-5xl lg:text-6xl px-6 py-2 mt-4 rounded-xl mx-auto w-fit;
  @apply font-light;
}

/* Size: Small - for tables and inline use */
.title-badge-sm {
  @apply text-[10px] px-1.5 rounded;
  @apply font-semibold tracking-wider;
}

/* Size: Nav - for navigation bar */
.title-badge-nav {
  @apply text-xs px-2 py-0.5 rounded;
  @apply font-semibold;
}

/* Amber variant */
.title-badge-amber {
  @apply bg-amber-500/20 border border-amber-500/50;
  @apply dark:bg-amber-500/15 dark:border-amber-400/40;
  @apply text-amber-600 dark:text-amber-400;
}

.title-badge-lg.title-badge-amber {
  @apply border-2 text-amber-500 dark:text-amber-300;
  box-shadow:
    0 0 20px theme('colors.amber.500 / 30%'),
    0 0 40px theme('colors.amber.500 / 15%');
}

.dark .title-badge-lg.title-badge-amber {
  box-shadow:
    0 0 25px theme('colors.amber.400 / 40%'),
    0 0 50px theme('colors.amber.400 / 20%');
}

/* Blue variant */
.title-badge-blue {
  @apply bg-blue-500/20 border border-blue-500/50;
  @apply dark:bg-blue-500/15 dark:border-blue-400/40;
  @apply text-blue-600 dark:text-blue-400;
}

.title-badge-lg.title-badge-blue {
  @apply border-2 text-blue-400 dark:text-blue-300;
  box-shadow:
    0 0 20px theme('colors.blue.500 / 30%'),
    0 0 40px theme('colors.blue.500 / 15%');
}

.dark .title-badge-lg.title-badge-blue {
  box-shadow:
    0 0 25px theme('colors.blue.400 / 40%'),
    0 0 50px theme('colors.blue.400 / 20%');
}

/* Purple variant */
.title-badge-purple {
  @apply bg-violet-500/20 border border-violet-500/50;
  @apply dark:bg-violet-500/15 dark:border-violet-400/40;
  @apply text-violet-600 dark:text-violet-400;
}

.title-badge-lg.title-badge-purple {
  @apply border-2 text-violet-400 dark:text-violet-300;
  box-shadow:
    0 0 20px theme('colors.violet.500 / 30%'),
    0 0 40px theme('colors.violet.500 / 15%');
}

.dark .title-badge-lg.title-badge-purple {
  box-shadow:
    0 0 25px theme('colors.violet.400 / 40%'),
    0 0 50px theme('colors.violet.400 / 20%');
}

/* Teal variant */
.title-badge-teal {
  @apply bg-teal-500/20 border border-teal-500/50;
  @apply dark:bg-teal-500/15 dark:border-teal-400/40;
  @apply text-teal-600 dark:text-teal-400;
}

.title-badge-lg.title-badge-teal {
  @apply border-2 text-teal-400 dark:text-teal-300;
  box-shadow:
    0 0 20px theme('colors.teal.500 / 30%'),
    0 0 40px theme('colors.teal.500 / 15%');
}

.dark .title-badge-lg.title-badge-teal {
  box-shadow:
    0 0 25px theme('colors.teal.400 / 40%'),
    0 0 50px theme('colors.teal.400 / 20%');
}
</style>
