<script setup lang="ts">
import { Icon } from '@iconify/vue';
import MediaPlaceholder from './MediaPlaceholder.vue';

export interface MediaConfig {
  type: 'video' | 'animation' | 'image' | 'gif';
  title: string;
  description: string;
}

defineProps<{
  tag: string;
  tagIcon: string;
  tagColor: 'blue' | 'purple' | 'teal' | 'amber';
  title: string;
  subtitle: string;
  bullets: string[];
  media: MediaConfig;
  reverse?: boolean;
}>();
</script>

<template>
  <div class="detail-row" :class="{ 'detail-row-reverse': reverse }">
    <div class="detail-content">
      <div class="badge" :class="'badge-' + tagColor">
        <Icon :icon="tagIcon" />
        <span>{{ tag }}</span>
      </div>
      <h2 class="section-title">{{ title }}</h2>
      <p class="detail-subtitle">{{ subtitle }}</p>
      <ul class="detail-bullets">
        <li v-for="bullet in bullets" :key="bullet">
          <Icon icon="ph:check-circle-fill" class="bullet-icon" />
          <span>{{ bullet }}</span>
        </li>
      </ul>
    </div>
    <div class="detail-visual">
      <MediaPlaceholder
        :type="media.type"
        :title="media.title"
        :description="media.description"
      />
    </div>
  </div>
</template>
