<script setup lang="ts">
import Badge from './Badge.vue';
import CtaButton from './CtaButton.vue';

defineProps<{
  /** CTA button href */
  href?: string;
  /** CTA button label */
  buttonLabel?: string;
}>();
</script>

<template>
  <div class="flex flex-col items-center gap-4 p-8 rounded-2xl max-w-xl mx-auto bg-white/80 dark:bg-zinc-800/60 backdrop-blur-sm border border-slate-200/60 dark:border-zinc-600/40 shadow-lg dark:shadow-xl">
    <Badge icon="ph:users-three-fill" color="amber">Select Program</Badge>
    <p class="text-base text-slate-500 dark:text-zinc-400 text-center">
      <slot>
        We're working closely with select customers to refine the Vyuh Node
        Flow package, editor, and workflow engine. Want to shape the future of
        visual flow editing in Flutter?
      </slot>
    </p>
    <CtaButton
      :href="href || 'https://vyuh.tech'"
      icon="ph:envelope-fill"
      variant="primary"
      external
    >
      {{ buttonLabel || 'Join the Waitlist' }}
    </CtaButton>
  </div>
</template>
