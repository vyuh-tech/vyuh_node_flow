<script setup lang="ts">
defineProps<{
  /** Whether this is the first content section (adds top border) - deprecated, use borderTop */
  first?: boolean;
  /** Container max-width: 'sm' (4xl), 'md' (5xl), 'lg' (6xl), 'xl' (7xl) */
  size?: 'sm' | 'md' | 'lg' | 'xl';
  /** Whether to apply the content background */
  background?: boolean;
  /** Background color variant */
  variant?: 'default' | 'teal' | 'purple';
  /** Center the content */
  centered?: boolean;
  /** Add a top border */
  borderTop?: boolean;
  /** Add a bottom border */
  borderBottom?: boolean;
}>();
</script>

<template>
  <section
    class="relative py-24 px-6 overflow-hidden"
    :class="[
      background && !variant && 'bg-slate-100/50 dark:bg-zinc-900/60',
      background && variant === 'teal' && 'bg-[#f0f5e8] dark:bg-[rgba(45,55,40,0.6)]',
      background && variant === 'purple' && 'bg-violet-50 dark:bg-violet-950/40',
      (first || borderTop) && 'border-t border-slate-200/50 dark:border-zinc-700/50',
      borderBottom && 'border-b border-slate-200/50 dark:border-zinc-700/50',
    ]"
  >
    <!-- Teal variant blur orbs -->
    <template v-if="variant === 'teal'">
      <div class="absolute rounded-full pointer-events-none blur-[120px] w-[500px] h-[500px] bg-teal-400 -top-32 -left-24 opacity-15 dark:opacity-25" />
      <div class="absolute rounded-full pointer-events-none blur-[120px] w-[400px] h-[400px] bg-cyan-400 top-1/3 -right-32 opacity-12 dark:opacity-20" />
      <div class="absolute rounded-full pointer-events-none blur-[120px] w-[350px] h-[350px] bg-teal-500 bottom-24 left-1/4 opacity-10 dark:opacity-18" />
    </template>

    <!-- Purple variant blur orbs -->
    <template v-if="variant === 'purple'">
      <div class="absolute rounded-full pointer-events-none blur-[120px] w-[500px] h-[500px] bg-violet-400 -top-32 -right-24 opacity-15 dark:opacity-25" />
      <div class="absolute rounded-full pointer-events-none blur-[120px] w-[400px] h-[400px] bg-purple-500 bottom-24 -left-32 opacity-12 dark:opacity-20" />
    </template>

    <div
      :class="[
        'mx-auto relative z-10',
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
