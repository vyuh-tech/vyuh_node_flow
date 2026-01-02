<script setup lang="ts">
defineProps<{
  /** URL for the iframe (without https://) */
  url: string;
  /** Title for the iframe */
  title?: string;
  /** Height of the iframe */
  height?: string;
}>();
</script>

<template>
  <div
    class="relative rounded-lg overflow-hidden border border-slate-200/50 dark:border-zinc-600/50 bg-white/75 dark:bg-zinc-900/75"
    style="
      box-shadow:
        0 20px 50px rgba(0, 0, 0, 0.1),
        0 0 60px rgba(139, 92, 246, 0.15);
    "
  >
    <iframe
      :src="url"
      class="w-full border-none"
      :style="{ height: height || '520px' }"
      :title="title || url"
      loading="lazy"
    />
  </div>
</template>
