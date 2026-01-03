<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';

const props = defineProps<{
  /** URL for the iframe */
  url: string;
  /** Title for the iframe */
  title?: string;
  /** Height of the iframe */
  height?: string;
}>();

// Defer loading until visible
const containerRef = ref<HTMLElement | null>(null);
const isVisible = ref(false);
const isLoaded = ref(false);

const iframeHeight = computed(() => props.height || '520px');

let observer: IntersectionObserver | null = null;

onMounted(() => {
  observer = new IntersectionObserver(
    (entries) => {
      if (entries[0].isIntersecting) {
        isVisible.value = true;
        observer?.disconnect();
      }
    },
    { rootMargin: '200px' } // Start loading 200px before visible
  );

  if (containerRef.value) {
    observer.observe(containerRef.value);
  }
});

onUnmounted(() => {
  observer?.disconnect();
});
</script>

<template>
  <div
    ref="containerRef"
    class="demo-frame relative rounded-lg overflow-hidden border border-slate-200/50 dark:border-zinc-600/50 bg-white/75 dark:bg-zinc-900/75"
    :style="{ minHeight: iframeHeight }"
  >
    <!-- Loading skeleton -->
    <div
      v-if="!isLoaded"
      class="absolute inset-0 flex items-center justify-center bg-slate-100 dark:bg-zinc-800"
    >
      <div class="flex flex-col items-center gap-3">
        <div class="w-8 h-8 border-3 border-violet-500 border-t-transparent rounded-full animate-spin" />
        <span class="text-sm text-slate-500 dark:text-zinc-400">Loading demo...</span>
      </div>
    </div>

    <!-- Iframe (only render when visible) -->
    <iframe
      v-if="isVisible"
      :src="url"
      class="w-full border-none"
      :style="{ height: iframeHeight }"
      :title="title || url"
      @load="isLoaded = true"
    />
  </div>
</template>

<style>
.demo-frame {
  box-shadow:
    0 20px 50px rgba(0, 0, 0, 0.1),
    0 0 60px rgba(139, 92, 246, 0.15);
}

@media (max-width: 768px) {
  .demo-frame {
    box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.2);
  }
}
</style>
