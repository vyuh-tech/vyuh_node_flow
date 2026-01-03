<script setup lang="ts">
import { Icon } from '@iconify/vue';
import TitleBadge from './TitleBadge.vue';

export interface ComparisonRow {
  category: string;
  openSource?: string | boolean;
  pro?: string | boolean;
  /** If true, this row is a section header that spans all columns */
  isSection?: boolean;
  /** Optional icon for section headers */
  icon?: string;
}

defineProps<{
  rows: ComparisonRow[];
}>();
</script>

<template>
  <div class="comparison-wrapper">
    <div class="comparison-container">
      <table class="comparison-table">
        <thead>
          <tr>
            <th class="feature-header">
              <span class="feature-header-label">Features</span>
            </th>
            <th class="plan-header opensource-header">
              <div class="plan-header-inner">
                <div class="plan-icon-box opensource-icon-box">
                  <Icon icon="ph:package-fill" />
                </div>
                <div class="plan-details">
                  <span class="plan-name">Open Source</span>
                  <span class="plan-tagline">Free forever</span>
                </div>
              </div>
            </th>
            <th class="plan-header pro-header">
              <div class="pro-header-glow" />
              <div class="plan-header-inner">
                <div class="plan-icon-box pro-icon-box">
                  <Icon icon="ph:crown-fill" />
                </div>
                <div class="plan-details">
                  <div class="plan-name-row">
                    <span class="plan-name">Node Flow</span>
                    <TitleBadge color="amber" size="sm">Pro</TitleBadge>
                  </div>
                  <span class="plan-tagline">Select Program</span>
                </div>
              </div>
            </th>
          </tr>
        </thead>
        <tbody>
          <template v-for="(row, index) in rows" :key="index">
            <!-- Section Header Row -->
            <tr v-if="row.isSection" class="section-row">
              <td colspan="3" class="section-cell">
                <span>
                  <Icon v-if="row.icon" :icon="row.icon" class="section-icon" />
                  {{ row.category }}
                </span>
              </td>
            </tr>
            <!-- Feature Row -->
            <tr v-else class="feature-row">
              <td class="feature-cell">{{ row.category }}</td>
              <td class="value-cell opensource-cell">
                <template v-if="typeof row.openSource === 'boolean'">
                  <div v-if="row.openSource" class="check-badge check-included">
                    <Icon icon="ph:check-bold" />
                  </div>
                  <div v-else class="check-badge check-excluded">
                    <Icon icon="ph:x-bold" />
                  </div>
                </template>
                <span v-else class="value-label">{{ row.openSource }}</span>
              </td>
              <td class="value-cell pro-cell">
                <template v-if="typeof row.pro === 'boolean'">
                  <div v-if="row.pro" class="check-badge check-included">
                    <Icon icon="ph:check-bold" />
                  </div>
                  <div v-else class="check-badge check-excluded">
                    <Icon icon="ph:x-bold" />
                  </div>
                </template>
                <span v-else class="value-label pro-value-label">{{ row.pro }}</span>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>

<style>
@reference "../style.css";

.comparison-wrapper {
  @apply max-w-5xl mx-auto p-4 -m-4;
}

.comparison-container {
  @apply relative rounded-2xl;
  @apply border border-slate-200/80 dark:border-zinc-700/80;
  @apply bg-white dark:bg-zinc-900;
  @apply overflow-x-auto;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.03);
}

.dark .comparison-container {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.comparison-table {
  @apply w-full border-collapse;
  font-family: var(--vn-font-mono);
  min-width: 640px; /* Force horizontal scroll on small screens */
}

/* Sticky Header with Glass Effect */
.comparison-table thead {
  @apply sticky top-0 z-10;
}

.comparison-table thead tr {
  @apply bg-slate-50/95 dark:bg-zinc-800/95;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.feature-header {
  @apply py-5 px-6 text-left align-middle;
  @apply border-b-2 border-slate-200 dark:border-zinc-700;
  width: 28%;
}

@media (max-width: 768px) {
  .feature-header {
    width: 24%;
    @apply px-4;
  }
}

.feature-header-label {
  @apply text-xs font-semibold uppercase tracking-widest;
  @apply text-slate-400 dark:text-zinc-500;
}

.plan-header {
  @apply py-5 px-6 align-middle;
  @apply border-b-2 border-slate-200 dark:border-zinc-700;
  width: 36%;
}

@media (max-width: 768px) {
  .plan-header {
    width: 38%;
    @apply px-3;
  }
}

.opensource-header {
  @apply border-r border-slate-200 dark:border-zinc-700;
}

.pro-header {
  @apply relative;
  @apply border-amber-300 dark:border-amber-700/60;
  background: linear-gradient(
    to bottom,
    theme('colors.amber.50'),
    theme('colors.amber.50/50')
  );
}

.dark .pro-header {
  background: linear-gradient(
    to bottom,
    theme('colors.amber.900/30'),
    theme('colors.amber.900/15')
  );
}

.pro-header-glow {
  @apply absolute inset-x-0 top-0 h-0.5;
  background: linear-gradient(
    90deg,
    transparent,
    theme('colors.amber.400'),
    transparent
  );
}

.plan-header-inner {
  @apply relative flex items-center gap-4;
  @apply max-lg:flex-col max-lg:gap-2 max-lg:text-center;
}

.plan-icon-box {
  @apply w-11 h-11 rounded-xl flex items-center justify-center text-xl shrink-0;
}

.opensource-icon-box {
  @apply bg-slate-200/80 text-slate-600;
  @apply dark:bg-zinc-700 dark:text-zinc-400;
}

.pro-icon-box {
  @apply bg-amber-200/80 text-amber-600;
  @apply dark:bg-amber-800/50 dark:text-amber-400;
  box-shadow: 0 0 20px theme('colors.amber.400/25');
}

.plan-details {
  @apply flex flex-col;
}

.plan-name-row {
  @apply flex items-center gap-2;
  @apply max-lg:justify-center;
}

.plan-name {
  @apply text-base font-bold text-slate-900 dark:text-zinc-100;
  font-family: var(--vn-font-display);
}

.plan-tagline {
  @apply text-xs text-slate-500 dark:text-zinc-500 mt-0.5;
}

/* Table Rows */
.feature-row {
  @apply transition-colors duration-150;
}

.feature-row:hover {
  @apply bg-slate-50/60 dark:bg-zinc-800/40;
}

.feature-row:last-child .feature-cell,
.feature-row:last-child .value-cell {
  @apply border-b-0;
}

.feature-cell {
  @apply py-4 px-6 text-left;
  @apply text-sm text-slate-700 dark:text-zinc-300;
  @apply border-b border-slate-100 dark:border-zinc-800;
}

.value-cell {
  @apply py-4 px-6 text-center;
  @apply border-b border-slate-100 dark:border-zinc-800;
}

.opensource-cell {
  @apply border-r border-slate-100 dark:border-zinc-800;
}

.pro-cell {
  @apply bg-amber-50/40 dark:bg-amber-900/10;
}

/* Check Badges */
.check-badge {
  @apply inline-flex w-7 h-7 rounded-full items-center justify-center text-sm font-bold;
}

.check-included {
  @apply bg-teal-100 text-teal-600;
  @apply dark:bg-teal-900/50 dark:text-teal-400;
}

.check-excluded {
  @apply bg-slate-100 text-slate-400;
  @apply dark:bg-zinc-800 dark:text-zinc-600;
}

.value-label {
  @apply text-sm text-slate-600 dark:text-zinc-400;
}

.pro-value-label {
  @apply text-amber-700 dark:text-amber-400 font-medium;
}

/* Section Header Rows */
.section-row {
  @apply bg-slate-100/80 dark:bg-zinc-800/80;
}

.section-cell {
  @apply py-3 px-6;
  @apply text-xs font-bold uppercase tracking-widest;
  @apply text-slate-500 dark:text-zinc-400;
  @apply border-y border-slate-200 dark:border-zinc-700;
}

.section-cell > span {
  @apply inline-flex items-center gap-2;
}

.section-icon {
  @apply text-sm text-slate-400 dark:text-zinc-500 inline-block align-middle;
}
</style>
