<script setup lang="ts">
defineProps<{
  /** URL for the iframe */
  url: string;
  /** Title for the iframe */
  title?: string;
  /** Height of the iframe */
  height?: string;
}>();
</script>

<template>
  <div
    class="relative rounded-lg overflow-hidden border border-slate-200/50 dark:border-zinc-600/50 bg-white dark:bg-zinc-800"
    style="
      box-shadow:
        0 20px 50px rgba(0, 0, 0, 0.1),
        0 0 60px rgba(139, 92, 246, 0.15);
    "
  >
    <iframe
      :src="url"
      class="w-full border-none bg-white"
      :style="{ height: height || '520px' }"
      :title="title || url"
      loading="lazy"
    />
  </div>
</template>
