<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { createHighlighter } from 'shiki';
import {
  transformerNotationFocus,
  transformerNotationHighlight,
} from '@shikijs/transformers';
import { Icon } from '@iconify/vue';

export interface CodeMarker {
  line: number;
  title: string;
  description: string;
}

const props = defineProps<{
  code: string;
  filename: string;
  lang?: string;
  markers?: CodeMarker[];
}>();

const highlightedCode = ref('');
const activeMarker = ref<CodeMarker | null>(null);
const markerPosition = ref({ top: 0, right: 0 });

const showTooltip = (marker: CodeMarker, event: MouseEvent) => {
  activeMarker.value = marker;
  const target = event.currentTarget as HTMLElement;
  const rect = target.getBoundingClientRect();
  const container = target.closest('.code-window')?.getBoundingClientRect();
  if (container) {
    // Position tooltip to the left of the marker, vertically centered using CSS transform
    markerPosition.value = {
      top: rect.top - container.top + (rect.height / 2), // marker vertical center
      right: container.right - rect.left + 12, // 12px gap from marker
    };
  }
};

const hideTooltip = () => {
  activeMarker.value = null;
};

onMounted(async () => {
  const highlighter = await createHighlighter({
    themes: ['github-dark'],
    langs: [props.lang || 'dart'],
  });
  highlightedCode.value = highlighter.codeToHtml(props.code, {
    lang: props.lang || 'dart',
    theme: 'github-dark',
    transformers: [
      transformerNotationFocus(),
      transformerNotationHighlight(),
    ],
  });
});
</script>

<template>
  <div class="code-window">
    <div class="code-window-header">
      <span class="code-dot code-dot-red"></span>
      <span class="code-dot code-dot-yellow"></span>
      <span class="code-dot code-dot-green"></span>
      <span class="code-filename">{{ filename }}</span>
    </div>
    <div class="code-body-wrapper">
      <div class="code-body" v-html="highlightedCode"></div>

      <!-- Code markers -->
      <div v-if="markers" class="code-markers">
        <button
          v-for="(marker, index) in markers"
          :key="marker.line"
          class="code-marker"
          :style="{ top: `calc(1.5rem + ${(marker.line - 1) * 1.28}rem)` }"
          @mouseenter="showTooltip(marker, $event)"
          @mouseleave="hideTooltip"
          @focus="showTooltip(marker, $event)"
          @blur="hideTooltip"
        >{{ index + 1 }}</button>
      </div>

      <!-- Tooltip -->
      <Transition name="tooltip">
        <div
          v-if="activeMarker"
          class="code-tooltip"
          :style="{ top: `${markerPosition.top}px`, right: `${markerPosition.right}px` }"
        >
          <div class="code-tooltip-title">{{ activeMarker.title }}</div>
          <div class="code-tooltip-desc">{{ activeMarker.description }}</div>
        </div>
      </Transition>
    </div>
  </div>
</template>
