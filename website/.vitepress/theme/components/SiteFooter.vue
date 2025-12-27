<script setup lang="ts">
import { Icon } from '@iconify/vue';

defineProps<{
  isProPage?: boolean;
}>();
</script>

<template>
  <footer class="custom-footer">
    <div class="footer-container">
      <div class="footer-brand">
        <div class="footer-logo">
          <img src="/icon.svg" alt="Vyuh Node Flow" class="footer-logo-img" />
          <span class="footer-logo-text">Vyuh Node Flow</span>
        </div>
        <p class="footer-tagline">High-performance visual flow editor for Flutter</p>
      </div>

      <div class="footer-links">
        <div class="footer-column">
          <h4 class="footer-heading">Resources</h4>
          <a href="/docs/getting-started/installation" class="footer-link"><Icon icon="ph:book-open-fill" /> Documentation</a>
          <a href="/docs/api-reference/" class="footer-link"><Icon icon="ph:code-fill" /> API Reference</a>
          <a href="/docs/examples/" class="footer-link"><Icon icon="ph:folder-open-fill" /> Examples</a>
          <a href="https://flow.demo.vyuh.tech" target="_blank" class="footer-link"><Icon icon="ph:play-fill" /> Live Demo</a>
        </div>
        <div class="footer-column">
          <h4 class="footer-heading">Community</h4>
          <a href="https://github.com/vyuh-tech/vyuh_node_flow" target="_blank" class="footer-link"><Icon icon="ph:github-logo-fill" /> GitHub</a>
          <a href="https://pub.dev/packages/vyuh_node_flow" target="_blank" class="footer-link"><Icon icon="simple-icons:dart" /> pub.dev</a>
          <a href="https://youtube.com/@vyuh_tech" target="_blank" class="footer-link"><Icon icon="ph:youtube-logo-fill" /> YouTube</a>
          <a href="https://x.com/vyuh_tech" target="_blank" class="footer-link"><Icon icon="ph:x-logo-fill" /> X</a>
        </div>
        <div class="footer-column">
          <h4 class="footer-heading">Product</h4>
          <a v-if="isProPage" href="/" class="footer-link"><Icon icon="ph:github-logo-fill" /> Open Source</a>
          <a v-else href="/pro" class="footer-link footer-link-pro"><Icon icon="ph:crown-fill" /> Pro Version</a>
          <a href="https://vyuh.tech" target="_blank" class="footer-link"><Icon icon="ph:globe-fill" /> Vyuh Technologies</a>
        </div>
      </div>
    </div>

    <div class="footer-bottom">
      <p class="footer-copyright">&copy; {{ new Date().getFullYear() }} Vyuh Technologies Private Limited. All rights reserved.</p>
    </div>
  </footer>
</template>

<style>
@reference "../style.css";

.custom-footer {
  @apply relative z-10 py-16 px-6;
  @apply bg-white/50 dark:bg-zinc-800/50;
  @apply backdrop-blur-md;
}

.footer-container {
  @apply max-w-6xl mx-auto grid grid-cols-[1fr_2fr] gap-16;
}

@media (max-width: 900px) {
  .footer-container {
    @apply grid-cols-1;
  }
}

.footer-brand {
  @apply flex flex-col gap-4;
}

.footer-logo {
  @apply flex items-center gap-4;
}

.footer-logo-img {
  @apply w-8 h-8;
}

.footer-logo-text {
  @apply text-lg font-bold text-slate-900 dark:text-zinc-100;
  font-family: var(--vn-font-display);
}

.footer-tagline {
  @apply text-sm text-slate-600 dark:text-zinc-400;
}

.footer-links {
  @apply grid grid-cols-3 gap-10;
}

@media (max-width: 600px) {
  .footer-links {
    @apply grid-cols-1;
  }
}

.footer-column {
  @apply flex flex-col gap-2;
}

.footer-heading {
  @apply text-xs font-bold uppercase tracking-widest text-slate-900 dark:text-zinc-100 mb-2;
  font-family: var(--vn-font-mono);
}

.footer-link {
  @apply inline-flex items-center gap-2 text-sm text-slate-600 dark:text-zinc-400 no-underline transition-colors;
}

.footer-link:hover {
  @apply text-violet-600 dark:text-violet-400;
}

.footer-link-pro {
  @apply text-amber-500 dark:text-amber-400;
}

.footer-link-pro:hover {
  @apply text-amber-600 dark:text-amber-300;
}

.footer-bottom {
  @apply max-w-6xl mx-auto mt-10 pt-6 text-center;
}

.footer-copyright {
  @apply text-sm text-slate-400 dark:text-zinc-500;
}
</style>
