<script setup lang="ts">
defineProps<{
  /** URL to display in the address bar */
  url: string;
  /** Optional iframe src (if different from display URL) */
  src?: string;
  /** Title for the iframe */
  title?: string;
  /** Height of the iframe */
  height?: string;
}>();
</script>

<template>
  <div
    class="relative rounded-lg overflow-hidden border border-slate-200/50 dark:border-zinc-600/50 bg-white dark:bg-zinc-800"
    style="box-shadow: 0 20px 50px rgba(0, 0, 0, 0.1), 0 0 60px rgba(139, 92, 246, 0.15)"
  >
    <!-- Browser chrome header -->
    <div class="flex items-center gap-1.5 px-3 py-2 bg-slate-100 dark:bg-zinc-700 border-b border-slate-200 dark:border-zinc-600">
      <span class="w-2 h-2 rounded-full bg-red-500" />
      <span class="w-2 h-2 rounded-full bg-yellow-500" />
      <span class="w-2 h-2 rounded-full bg-green-500" />
      <a
        :href="`https://${url}`"
        target="_blank"
        class="flex-1 ml-2 px-2.5 py-1 bg-white dark:bg-zinc-800 rounded-md text-xs text-slate-400 dark:text-zinc-500 no-underline transition-colors hover:text-blue-600 hover:bg-blue-600/10 dark:hover:text-blue-400 dark:hover:bg-blue-400/10 font-mono"
      >
        {{ url }}
      </a>
    </div>
    <!-- Content -->
    <iframe
      :src="src || `https://${url}`"
      class="w-full border-none bg-white"
      :style="{ height: height || '520px' }"
      :title="title || url"
      loading="lazy"
    />
  </div>
</template>
