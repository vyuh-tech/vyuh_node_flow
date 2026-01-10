<script setup lang="ts">
import { ref, computed } from 'vue';
import { data as pubData } from '../data/pubVersion.data';

const props = withDefaults(
  defineProps<{
    showGit?: boolean;
  }>(),
  {
    showGit: true,
  }
);

const activeTab = ref<'pubdev' | 'git'>('pubdev');

const currentCode = computed(() =>
  activeTab.value === 'pubdev' ? pubData.pubdevCode : pubData.gitCode
);

const currentHtml = computed(() =>
  activeTab.value === 'pubdev' ? pubData.pubdevHtml : pubData.gitHtml
);

const copyCode = async () => {
  await navigator.clipboard.writeText(currentCode.value);
};
</script>

<template>
  <div class="vp-code-group vp-adaptive-theme">
    <div class="tabs">
      <input
        type="radio"
        name="pubspec-tab"
        id="tab-pubdev"
        :checked="activeTab === 'pubdev'"
        @change="activeTab = 'pubdev'"
      />
      <label for="tab-pubdev">pub.dev</label>
      <input
        v-if="showGit"
        type="radio"
        name="pubspec-tab"
        id="tab-git"
        :checked="activeTab === 'git'"
        @change="activeTab = 'git'"
      />
      <label v-if="showGit" for="tab-git">Git</label>
    </div>
    <div class="blocks">
      <div class="language-yaml active">
        <button title="Copy Code" class="copy" @click="copyCode"></button>
        <span class="lang">yaml</span>
        <div v-html="currentHtml"></div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Let VitePress default styles handle the code block */
:deep(pre.shiki) {
  margin: 0;
  background-color: var(--vp-code-block-bg) !important;
}
</style>
