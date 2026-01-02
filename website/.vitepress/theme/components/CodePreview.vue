<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, watch, shallowRef } from 'vue';
import { createHighlighter, type Highlighter } from 'shiki';
import {
  transformerNotationFocus,
  transformerNotationHighlight,
} from '@shikijs/transformers';

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
const markerPositions = ref<{ [key: number]: number }>({});
const scrollOffset = ref(0);
const codeBodyRef = ref<HTMLElement | null>(null);
const highlighter = shallowRef<Highlighter | null>(null);

// Highlight code with shiki
const highlightCode = async (code: string) => {
  if (!highlighter.value) return;

  highlightedCode.value = highlighter.value.codeToHtml(code, {
    lang: props.lang || 'dart',
    theme: 'github-dark',
    transformers: [
      transformerNotationFocus(),
      transformerNotationHighlight(),
    ],
  });

  // Recalculate marker positions after code is rendered
  await nextTick();
  calculateMarkerPositions();
};

const showTooltip = (marker: CodeMarker, event: MouseEvent | FocusEvent) => {
  activeMarker.value = marker;
  const target = event.currentTarget as HTMLElement;
  const rect = target.getBoundingClientRect();
  const container = target.closest('.code-window')?.getBoundingClientRect();
  if (container) {
    markerPosition.value = {
      top: rect.top - container.top + (rect.height / 2),
      right: container.right - rect.left + 12,
    };
  }
};

const hideTooltip = () => {
  activeMarker.value = null;
};

const calculateMarkerPositions = () => {
  if (!codeBodyRef.value || !props.markers) return;

  const scrollContainer = codeBodyRef.value;
  const lines = scrollContainer.querySelectorAll('.line');
  const positions: { [key: number]: number } = {};

  // Get the scroll container's position for reference
  const containerRect = scrollContainer.getBoundingClientRect();

  props.markers.forEach((marker) => {
    const lineIndex = marker.line - 1;
    if (lines[lineIndex]) {
      const lineElement = lines[lineIndex] as HTMLElement;
      const lineRect = lineElement.getBoundingClientRect();
      // Calculate position relative to scroll container, accounting for current scroll
      positions[marker.line] = lineRect.top - containerRect.top + scrollContainer.scrollTop + (lineRect.height / 2) - 12;
    }
  });

  markerPositions.value = positions;
};

const handleScroll = () => {
  if (codeBodyRef.value) {
    scrollOffset.value = codeBodyRef.value.scrollTop;
  }
};

onMounted(async () => {
  highlighter.value = await createHighlighter({
    themes: ['github-dark'],
    langs: [props.lang || 'dart'],
  });

  // Initial highlight
  await highlightCode(props.code);

  // Listen to scroll events
  if (codeBodyRef.value) {
    codeBodyRef.value.addEventListener('scroll', handleScroll);
  }

  // Recalculate on resize
  window.addEventListener('resize', calculateMarkerPositions);
});

// Re-highlight when code prop changes
watch(() => props.code, async (newCode) => {
  await highlightCode(newCode);
});

onUnmounted(() => {
  if (codeBodyRef.value) {
    codeBodyRef.value.removeEventListener('scroll', handleScroll);
  }
  window.removeEventListener('resize', calculateMarkerPositions);
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
      <!-- Scrollable container for code only -->
      <div ref="codeBodyRef" class="code-scroll-container">
        <div class="code-body" v-html="highlightedCode"></div>
      </div>

      <!-- Markers - outside scroll container, fixed to viewport edge -->
      <div v-if="markers && Object.keys(markerPositions).length > 0" class="code-markers">
        <button
          v-for="(marker, index) in markers"
          :key="marker.line"
          class="code-marker"
          :style="{ top: `${(markerPositions[marker.line] || 0) - scrollOffset}px` }"
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

<style scoped>
@reference "../style.css";

.code-window {
  @apply bg-slate-900 dark:bg-slate-950 border border-white/10 rounded-xl overflow-hidden shadow-2xl;
}

.code-window-header {
  @apply flex items-center gap-2 px-4 py-3.5 bg-slate-800 dark:bg-slate-900 border-b border-white/10;
}

.code-dot {
  @apply w-3 h-3 rounded-full;
}

.code-dot-red { @apply bg-red-500; }
.code-dot-yellow { @apply bg-amber-400; }
.code-dot-green { @apply bg-green-500; }

.code-filename {
  @apply ml-auto text-sm text-slate-400;
  font-family: var(--vn-font-mono);
}

.code-body-wrapper {
  @apply relative overflow-hidden;
}

.code-scroll-container {
  @apply overflow-auto;
}

.code-body {
  @apply p-0;
  width: fit-content;
  min-width: 100%;
}

.code-body :deep(pre) {
  @apply m-0 p-6 text-sm leading-relaxed;
  font-family: var(--vn-font-mono);
  background: transparent !important;
}

.code-body :deep(code) {
  font-family: var(--vn-font-mono);
  display: flex;
  flex-direction: column;
  width: fit-content;
  min-width: 100%;
}

/* Preserve height for empty/blank lines */
.code-body :deep(.line) {
  min-height: 1.5em;
}

.code-body :deep(.line:empty)::before {
  content: ' ';
}

/* Shiki Line Focus Styling */
.code-body :deep(.has-focused-lines .line:not(.focused)) {
  @apply opacity-35 transition-all duration-300;
  filter: blur(0.5px);
}

.code-body :deep(.has-focused-lines:hover .line:not(.focused)) {
  @apply opacity-60;
  filter: blur(0.2px);
}

.code-body :deep(.line.focused) {
  @apply bg-blue-500/20 border-l-[3px] border-blue-500;
  margin-left: -1.5rem;
  margin-right: -1.5rem;
  padding-left: calc(1.5rem - 3px);
  padding-right: 1.5rem;
}

.code-body :deep(.line.highlighted) {
  @apply bg-amber-500/20 border-l-[3px] border-amber-500;
  margin-left: -1.5rem;
  margin-right: -1.5rem;
  padding-left: calc(1.5rem - 3px);
  padding-right: 1.5rem;
}

/* Code Markers - positioned at viewport edge */
.code-markers {
  @apply absolute top-0 right-3 bottom-0 pointer-events-none z-20;
}

.code-marker {
  @apply absolute right-0 w-6 h-6 flex items-center justify-center;
  @apply bg-amber-500 text-white;
  @apply border-none rounded-full cursor-pointer pointer-events-auto;
  @apply text-xs font-black transition-all duration-200;
  animation: beacon 1.5s ease-out infinite;
}

@keyframes beacon {
  0% { box-shadow: 0 0 0 0 rgba(245, 158, 11, 0.6); }
  100% { box-shadow: 0 0 0 10px rgba(245, 158, 11, 0); }
}

.code-marker:hover {
  @apply bg-amber-400 scale-110;
  animation: none;
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.5);
}

/* Code Tooltip */
.code-tooltip {
  @apply absolute z-50 w-72 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-4 shadow-xl pointer-events-none;
  transform: translateY(-50%);
}

/* Responsive tooltip */
@media (max-width: 768px) {
  .code-tooltip {
    @apply w-56 p-3;
    right: 40px !important;
  }

  .code-tooltip-title {
    @apply text-xs;
  }

  .code-tooltip-desc {
    @apply text-xs;
  }
}

@media (max-width: 480px) {
  .code-tooltip {
    @apply w-48;
  }
}

.code-tooltip-title {
  @apply text-sm font-bold text-slate-900 dark:text-slate-100 mb-1;
  font-family: var(--vn-font-display);
}

.code-tooltip-desc {
  @apply text-sm text-slate-600 dark:text-slate-400 leading-normal;
}

/* Tooltip transition */
.tooltip-enter-active,
.tooltip-leave-active {
  @apply transition-all duration-200;
}

.tooltip-enter-from,
.tooltip-leave-to {
  @apply opacity-0;
  transform: translateY(-50%) translateX(8px);
}
</style>
