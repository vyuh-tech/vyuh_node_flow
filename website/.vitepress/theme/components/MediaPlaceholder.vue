<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  type: 'video' | 'animation' | 'image' | 'gif';
  title: string;
  description: string;
  aspectRatio?: string;
}>();

const typeConfig = {
  video: { icon: 'ph:video-fill', label: 'Video' },
  animation: { icon: 'ph:gif-fill', label: 'Animation' },
  image: { icon: 'ph:image-fill', label: 'Image' },
  gif: { icon: 'ph:gif-fill', label: 'GIF' },
};
</script>

<template>
  <div class="media-placeholder" :style="{ aspectRatio: aspectRatio || '16/10' }">
    <div class="media-placeholder-inner">
      <div class="media-placeholder-badge">
        <Icon :icon="typeConfig[type].icon" />
        <span>{{ typeConfig[type].label }}</span>
      </div>
      <h4 class="media-placeholder-title">{{ title }}</h4>
      <p class="media-placeholder-desc">{{ description }}</p>
      <div class="media-placeholder-hint">
        <Icon icon="ph:arrow-square-out-fill" />
        <span>Replace with actual media</span>
      </div>
    </div>
  </div>
</template>
