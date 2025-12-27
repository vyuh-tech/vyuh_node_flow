<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';

const props = defineProps<{
  words: string[];
  interval?: number;
}>();

const emit = defineEmits<{
  (e: 'animating', value: boolean): void;
}>();

const currentIndex = ref(0);
const isAnimating = ref(false);

let intervalId: ReturnType<typeof setInterval> | null = null;

// Previous word (the one fading out)
const previousWord = computed(() => props.words[currentIndex.value]);

// Next word (the one fading in)
const nextWord = computed(() => props.words[(currentIndex.value + 1) % props.words.length]);

const flipWord = () => {
  isAnimating.value = true;
  emit('animating', true);

  // After animation completes, update index and reset
  setTimeout(() => {
    currentIndex.value = (currentIndex.value + 1) % props.words.length;
    isAnimating.value = false;
    emit('animating', false);
  }, 400);
};

onMounted(() => {
  intervalId = setInterval(flipWord, props.interval || 3000);
});

onUnmounted(() => {
  if (intervalId) clearInterval(intervalId);
});
</script>

<template>
  <span class="word-flipper">
    <!-- Previous word - takes up space, fades out during animation -->
    <span
      class="flipper-word flipper-previous"
      :class="{ 'animating-out': isAnimating }"
    >{{ previousWord }}</span>

    <!-- Next word - overlays, fades in during animation -->
    <span
      class="flipper-word flipper-next"
      :class="{ 'animating-in': isAnimating }"
    >{{ nextWord }}</span>
  </span>
</template>

<style>
.word-flipper {
  display: block;
  position: relative;
  overflow: visible;
  width: 100%;
}

.flipper-word {
  display: inline-block;
  white-space: nowrap;
  padding-right: 0.1em;
  /* Gradient text effect */
  background: linear-gradient(135deg, #2563eb, #8b5cf6);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

/* Previous word takes up space */
.flipper-previous {
  position: relative;
}

/* Next word overlays the previous */
.flipper-next {
  position: absolute;
  top: 0;
  left: 0;
  visibility: hidden;
  filter: opacity(0);
  transform: translateY(0.3em);
}

/* Previous word fades out and moves up */
.flipper-previous.animating-out {
  animation: slideOut 0.4s ease-in forwards;
}

/* Next word fades in and moves up */
.flipper-next.animating-in {
  visibility: visible;
  animation: slideIn 0.4s ease-out forwards;
}

@keyframes slideOut {
  0% {
    filter: opacity(1);
    transform: translateY(0);
  }
  100% {
    filter: opacity(0);
    transform: translateY(-0.3em);
  }
}

@keyframes slideIn {
  0% {
    filter: opacity(0);
    transform: translateY(0.3em);
  }
  100% {
    filter: opacity(1);
    transform: translateY(0);
  }
}
</style>
