<script setup lang="ts">
import Badge from './Badge.vue';
import CtaButton from './CtaButton.vue';

export interface CtaAction {
  href: string;
  icon?: string;
  label: string;
  external?: boolean;
}

defineProps<{
  badge: string;
  badgeIcon: string;
  badgeColor?: 'blue' | 'purple' | 'teal' | 'amber';
  title: string;
  subtitle?: string;
  primaryAction: CtaAction;
  secondaryActions?: CtaAction[];
}>();
</script>

<template>
  <section class="cta-section">
    <div class="cta-blur cta-blur-1" />
    <div class="cta-blur cta-blur-2" />
    <div class="cta-content">
      <Badge :icon="badgeIcon" :color="badgeColor || 'amber'">{{
        badge
      }}</Badge>
      <h2 class="cta-title">{{ title }}</h2>
      <p v-if="subtitle" class="cta-subtitle">
        {{ subtitle }}
      </p>
      <slot name="subtitle" />
      <div class="cta-actions">
        <CtaButton
          :href="primaryAction.href"
          :icon="primaryAction.icon"
          variant="primary"
          size="large"
          :external="primaryAction.external"
        >
          {{ primaryAction.label }}
        </CtaButton>
        <CtaButton
          v-for="(action, index) in secondaryActions"
          :key="index"
          :href="action.href"
          :icon="action.icon"
          variant="secondary"
          size="large"
          :external="action.external"
        >
          {{ action.label }}
        </CtaButton>
      </div>
    </div>
  </section>
</template>

<style>
@reference "../style.css";

.cta-section {
  @apply relative py-32 px-6 text-center overflow-hidden;
}

.cta-blur {
  @apply absolute rounded-full pointer-events-none;
  filter: blur(150px);
}

.cta-blur-1 {
  @apply w-[600px] h-[600px] bg-blue-500 -top-48 left-[10%] opacity-12 dark:opacity-20;
}

.cta-blur-2 {
  @apply w-[500px] h-[500px] bg-violet-500 -bottom-36 right-[10%] opacity-10 dark:opacity-18;
}

.cta-content {
  @apply relative z-10 max-w-3xl mx-auto;
}

.cta-title {
  @apply text-4xl sm:text-5xl font-black text-slate-900 dark:text-zinc-100 mb-6 tracking-tight;
  font-family: var(--vn-font-display);
}

.cta-subtitle {
  @apply text-lg text-slate-600 dark:text-zinc-400 leading-relaxed mb-14;
}

.cta-actions {
  @apply flex flex-col sm:flex-row justify-center gap-4 flex-wrap mt-16;
}
</style>
