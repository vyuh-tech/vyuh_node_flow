<script setup lang="ts">
import { ref } from 'vue';
import { Icon } from '@iconify/vue';
import CodePreview, { type CodeMarker } from './CodePreview.vue';

export interface CodeTab {
  id: string;
  label: string;
  icon: string;
  code?: string;
  filename?: string;
  lang?: string;
  markers?: CodeMarker[];
  isPreview?: boolean;
  previewUrl?: string;
  previewTitle?: string;
}

const props = defineProps<{
  tabs: CodeTab[];
}>();

const activeTab = ref(props.tabs[0]?.id || '');
</script>

<template>
  <div class="tabbed-code-preview">
    <!-- Tab Bar -->
    <div class="tab-bar">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        class="tab-button"
        :class="{ active: activeTab === tab.id }"
        @click="activeTab = tab.id"
      >
        <Icon :icon="tab.icon" class="tab-icon" />
        <span>{{ tab.label }}</span>
      </button>
    </div>

    <!-- Tab Content -->
    <div class="tab-content">
      <template v-for="tab in tabs" :key="tab.id">
        <div v-show="activeTab === tab.id" class="tab-panel">
          <!-- Code Tab -->
          <CodePreview
            v-if="!tab.isPreview && tab.code"
            :code="tab.code"
            :filename="tab.filename || ''"
            :lang="tab.lang"
            :markers="tab.markers"
            class="tabbed-code-window"
          />
          <!-- Preview Tab -->
          <div v-else-if="tab.isPreview" class="preview-panel">
            <iframe
              :src="'https://' + (tab.previewUrl || 'flow.demo.vyuh.tech')"
              :title="tab.previewTitle || 'Preview'"
              class="preview-iframe"
              loading="lazy"
            />
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<style>
@reference "../style.css";

.tabbed-code-preview {
  @apply rounded-xl overflow-hidden;
  @apply border border-white/10;
  @apply bg-slate-900 dark:bg-slate-950;
  @apply shadow-2xl;
}

.tab-bar {
  @apply flex gap-1 px-3 py-2;
  @apply bg-slate-800 dark:bg-slate-900;
  @apply border-b border-white/10;
}

.tab-button {
  @apply flex items-center gap-2 px-4 py-2;
  @apply text-sm font-medium;
  @apply text-slate-400 dark:text-slate-500;
  @apply rounded-lg;
  @apply transition-all duration-200;
  @apply cursor-pointer;
  @apply border-none bg-transparent;
  font-family: var(--vn-font-mono);
}

.tab-button:hover {
  @apply text-slate-200 bg-slate-700/50;
}

.tab-button.active {
  @apply text-white bg-slate-700;
}

.tab-icon {
  @apply text-base;
}

.tab-content {
  @apply relative;
  height: 640px;
}

.tab-panel {
  @apply w-full h-full;
}

/* Override CodePreview styles when inside tabs */
.tabbed-code-window {
  @apply border-0 rounded-none shadow-none h-full flex flex-col;
}

.tabbed-code-window .code-window-header {
  @apply hidden;
}

/* Make scroll container fill available space and scroll */
.tabbed-code-window .code-body-wrapper {
  @apply flex-1 overflow-hidden;
}

.tabbed-code-window .code-scroll-container {
  @apply h-full overflow-y-auto overflow-x-auto;
}

.preview-panel {
  @apply p-0 h-full;
}

.preview-iframe {
  @apply w-full h-full border-none bg-white;
}

/* Responsive heights */
@media (max-width: 1024px) {
  .tab-content {
    height: 560px;
  }
}

@media (max-width: 768px) {
  .tab-content {
    height: 480px;
  }
}

@media (max-width: 640px) {
  .tab-content {
    height: 400px;
  }
}
</style>
