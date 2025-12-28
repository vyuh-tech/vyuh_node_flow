<script setup lang="ts">
import { Icon } from '@iconify/vue';
import Badge from './Badge.vue';
import MediaPlaceholder from './MediaPlaceholder.vue';

export interface PlaceholderConfig {
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
  placeholder?: PlaceholderConfig;
  reverse?: boolean;
}>();
</script>

<template>
  <div class="feature-section" :class="{ 'feature-section-reverse': reverse }">
    <div class="feature-section-content">
      <Badge :icon="tagIcon" :color="tagColor">{{ tag }}</Badge>
      <h2 class="section-title">{{ title }}</h2>
      <p class="feature-section-subtitle">{{ subtitle }}</p>
      <ul class="feature-section-bullets">
        <li v-for="bullet in bullets" :key="bullet">
          <Icon icon="ph:check-circle-fill" class="bullet-icon" />
          <span>{{ bullet }}</span>
        </li>
      </ul>
    </div>
    <div class="feature-section-visual">
      <!-- Slot takes priority over placeholder -->
      <slot v-if="$slots.default" />
      <MediaPlaceholder
        v-else-if="placeholder"
        :type="placeholder.type"
        :title="placeholder.title"
        :description="placeholder.description"
      />
    </div>
  </div>
</template>

<style>
@reference "../style.css";

.feature-section {
  @apply grid grid-cols-2 gap-16 items-center py-16;
  @apply max-lg:grid-cols-1 max-lg:gap-10;
}

.feature-section-reverse {
  direction: rtl;
}

.feature-section-reverse > * {
  direction: ltr;
}

/* On mobile, reset RTL to LTR */
.feature-section-reverse {
  @apply max-lg:[direction:ltr];
}

.feature-section-content {
  @apply py-6;
}

/* Section title is inherited from SectionHeader, but we need it here too */
.section-title {
  @apply text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 dark:text-zinc-100 leading-tight mb-4 tracking-tight;
  font-family: var(--vn-font-display);
}

.feature-section-subtitle {
  @apply text-lg font-medium text-slate-600 dark:text-zinc-400 leading-relaxed mb-10;
}

.feature-section-bullets {
  @apply list-none p-0 m-0 flex flex-col gap-3;
}

.feature-section-bullets li {
  @apply flex items-start gap-3 text-base text-slate-600 dark:text-zinc-400 leading-normal;
}

.bullet-icon {
  @apply shrink-0 mt-0.5 text-xl text-teal-500 dark:text-teal-400;
}

.feature-section-visual {
  @apply flex items-stretch justify-center w-full max-w-full overflow-hidden;
}
</style>
