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
        </div>
        <div class="footer-column">
          <h4 class="footer-heading">Community</h4>
          <a href="https://github.com/vyuh-tech/vyuh_node_flow" target="_blank" class="footer-link"><Icon icon="ph:github-logo-fill" /> GitHub</a>
          <a href="https://pub.dev/packages/vyuh_node_flow" target="_blank" class="footer-link"><Icon icon="simple-icons:dart" /> pub.dev</a>
          <a href="https://flow.demo.vyuh.tech" target="_blank" class="footer-link"><Icon icon="ph:play-fill" /> Live Demo</a>
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
      <p class="footer-license">Released under the <a href="https://opensource.org/licenses/MIT" target="_blank">MIT License</a></p>
    </div>
  </footer>
</template>
