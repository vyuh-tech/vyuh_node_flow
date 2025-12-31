<script setup lang="ts">
import { Icon } from '@iconify/vue';
import TitleBadge from './TitleBadge.vue';
</script>

<template>
  <a href="/pro" class="nav-pro-link">
    <TitleBadge color="amber" size="nav" class="nav-pro-badge">
      <Icon icon="ph:crown-fill" class="nav-pro-icon" />
      <span>Pro</span>
    </TitleBadge>
  </a>
</template>

<style>
.nav-pro-link {
  display: inline-flex;
  align-self: center;
  text-decoration: none;
}

.nav-pro-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  transition: all 0.2s ease;
}

.nav-pro-icon {
  width: 0.85rem;
  height: 0.85rem;
}

.nav-pro-link:hover .nav-pro-badge {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(180, 83, 9, 0.35); /* amber-700 for light mode */
}

.dark .nav-pro-link:hover .nav-pro-badge {
  box-shadow: 0 4px 12px rgba(251, 191, 36, 0.25); /* lighter amber for dark mode */
}
</style>
