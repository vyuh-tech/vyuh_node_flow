<script setup lang="ts">
import Badge from './Badge.vue';
import CtaButton from './CtaButton.vue';

export interface CtaAction {
  href?: string;
  icon?: string;
  label: string;
  external?: boolean;
  onClick?: () => void;
}

defineProps<{
  badge: string;
  badgeIcon: string;
  badgeColor?: 'blue' | 'purple' | 'teal' | 'amber';
  title: string;
  subtitle?: string;
  primaryAction: CtaAction;
  secondaryActions?: CtaAction[];
  /** Add a top border */
  borderTop?: boolean;
  /** Add a bottom border */
  borderBottom?: boolean;
}>();
</script>

<template>
  <section
    class="cta-section"
    :class="[
      borderTop && 'border-t border-slate-200/50 dark:border-zinc-700/50',
      borderBottom && 'border-b border-slate-200/50 dark:border-zinc-700/50',
    ]"
  >
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
          @click="primaryAction.onClick?.()"
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
  @apply relative py-32 px-6 text-center overflow-hidden bg-slate-950 border-t border-slate-800;
}

.cta-content {
  @apply relative z-10 max-w-3xl mx-auto;
}

.cta-title {
  @apply text-balance text-4xl sm:text-5xl font-bold text-white mb-6;
  font-family: var(--vn-font-display);
}

.cta-subtitle {
  @apply text-pretty text-lg text-slate-300 leading-relaxed mb-14;
}

.cta-actions {
  @apply flex flex-col sm:flex-row justify-center gap-4 flex-wrap mt-16;
}
</style>
