<script setup lang="ts">
import { ref } from 'vue';
import Badge from './Badge.vue';
import CtaButton from './CtaButton.vue';
import FormDialog from './FormDialog.vue';
import { SELECT_PROGRAM_FORM_URL } from '../constants';

defineProps<{
  /** CTA button label */
  buttonLabel?: string;
}>();

const dialogOpen = ref(false);
</script>

<template>
  <div
    class="flex flex-col items-center gap-4 p-8 rounded-2xl max-w-xl mx-auto bg-white/80 dark:bg-zinc-800/60 backdrop-blur-sm border border-slate-200/60 dark:border-zinc-600/40 shadow-lg dark:shadow-xl"
  >
    <Badge icon="ph:users-three-fill" color="amber">Select Program</Badge>
    <p class="text-base text-slate-500 dark:text-zinc-400 text-center">
      <slot>
        We're working closely with select customers to refine the Vyuh Node Flow
        package, editor, and workflow engine. Want to shape the future of visual
        flow editing in Flutter?
      </slot>
    </p>
    <CtaButton
      icon="ph:envelope-fill"
      variant="primary"
      @click="dialogOpen = true"
    >
      {{ buttonLabel || 'Apply for Select Access' }}
    </CtaButton>
  </div>

  <!-- Form Dialog -->
  <FormDialog
    :open="dialogOpen"
    :form-url="SELECT_PROGRAM_FORM_URL"
    @close="dialogOpen = false"
  />
</template>
