<script setup lang="ts">
defineProps<{
  /** Whether this is the first content section (adds top border) */
  first?: boolean;
  /** Container max-width: 'sm' (4xl), 'md' (5xl), 'lg' (6xl), 'xl' (7xl) */
  size?: 'sm' | 'md' | 'lg' | 'xl';
  /** Whether to apply the content background */
  background?: boolean;
  /** Center the content */
  centered?: boolean;
}>();
</script>

<template>
  <section
    class="relative py-24 px-6"
    :class="[
      background && 'bg-slate-100/50 dark:bg-zinc-900/60',
      first && 'border-t border-slate-200/50 dark:border-zinc-700/50',
    ]"
  >
    <div
      :class="[
        'mx-auto',
        size === 'sm' && 'max-w-4xl',
        size === 'md' && 'max-w-5xl',
        (!size || size === 'lg') && 'max-w-6xl',
        size === 'xl' && 'max-w-7xl',
        centered && 'text-center',
      ]"
    >
      <slot />
    </div>
  </section>
</template>
