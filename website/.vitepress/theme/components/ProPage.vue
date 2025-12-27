<script setup lang="ts">
import { Icon } from '@iconify/vue';
import SiteFooter from './SiteFooter.vue';

// Blinking grid cells generator
const generateBlinkCells = (count: number, seed: number) => {
  const cells = [];
  for (let i = 0; i < count; i++) {
    const pseudoRandom = (seed + i * 17) % 100;
    cells.push({
      left: Math.floor((pseudoRandom * 7) % 30) * 40,
      top: Math.floor((pseudoRandom * 3) % 20) * 40,
      delay: pseudoRandom % 8,
      duration: 4 + (pseudoRandom % 4),
    });
  }
  return cells;
};

const proBlinkCells = generateBlinkCells(18, 91);

const proFeatures = [
  { icon: 'ph:clock-counter-clockwise-fill', title: 'History & Undo/Redo', desc: 'Full history management with unlimited undo/redo stack and time-travel debugging.' },
  { icon: 'ph:arrows-split-fill', title: 'Advanced Grouping', desc: 'Nested groups, collapsible subflows, and hierarchical node organization.' },
  { icon: 'ph:puzzle-piece-fill', title: 'Extension System', desc: 'Plugin architecture for custom tools, panels, and editor extensions.' },
  { icon: 'ph:cloud-arrow-down-fill', title: 'Cloud Sync', desc: 'Real-time collaboration with cloud-based flow storage and versioning.' },
  { icon: 'ph:magic-wand-fill', title: 'AI-Powered Layouts', desc: 'Intelligent auto-layout algorithms for optimal graph organization.' },
  { icon: 'ph:export-fill', title: 'Export & Import', desc: 'Export to multiple formats including PNG, SVG, PDF, and custom schemas.' },
  { icon: 'ph:lock-key-fill', title: 'Access Control', desc: 'Role-based permissions for collaborative editing and view-only modes.' },
  { icon: 'ph:headset-fill', title: 'Priority Support', desc: 'Direct access to the development team with priority issue resolution.' },
];
</script>

<template>
  <div class="pro-page">
    <!-- Background Effects -->
    <div class="pro-background">
      <svg class="pro-grid-svg" width="100%" height="100%">
        <defs>
          <pattern id="proSmallGrid" width="40" height="40" patternUnits="userSpaceOnUse">
            <path d="M 40 0 L 0 0 0 40" fill="none" stroke="rgba(139, 92, 246, 0.06)" stroke-width="1"/>
          </pattern>
          <pattern id="proLargeGrid" width="200" height="200" patternUnits="userSpaceOnUse">
            <rect width="200" height="200" fill="url(#proSmallGrid)"/>
            <path d="M 200 0 L 0 0 0 200" fill="none" stroke="rgba(139, 92, 246, 0.12)" stroke-width="1"/>
          </pattern>
          <radialGradient id="proGridFade" cx="50%" cy="30%" r="60%">
            <stop offset="0%" stop-color="white" stop-opacity="1"/>
            <stop offset="100%" stop-color="white" stop-opacity="0"/>
          </radialGradient>
          <mask id="proGridMask">
            <rect width="100%" height="100%" fill="url(#proGridFade)"/>
          </mask>
        </defs>
        <rect width="100%" height="100%" fill="url(#proLargeGrid)" mask="url(#proGridMask)"/>
      </svg>
      <div class="pro-grid-blink">
        <div
          class="blink-cell blink-cell-purple"
          v-for="(cell, n) in proBlinkCells"
          :key="n"
          :style="{
            left: `${cell.left}px`,
            top: `${cell.top}px`,
            animationDelay: `${cell.delay}s`,
            animationDuration: `${cell.duration}s`
          }"
        />
      </div>
      <div class="pro-blur pro-blur-purple"/>
      <div class="pro-blur pro-blur-blue"/>
      <div class="pro-blur pro-blur-teal"/>
    </div>

    <!-- Hero Section -->
    <section class="pro-hero">
      <div class="pro-badge">
        <Icon icon="ph:crown-fill" />
        <span>Pro Edition</span>
      </div>
      <h1 class="pro-title">
        <span class="pro-title-gradient">Vyuh Node Flow</span>
        <span class="pro-title-sub">Pro</span>
      </h1>
      <p class="pro-subtitle">
        Enterprise-grade features for building sophisticated visual editors.
        Unlimited power, complete control.
      </p>
      <div class="pro-coming-soon">
        <div class="coming-soon-badge">
          <Icon icon="ph:rocket-launch-fill" />
          <span>Coming Soon</span>
        </div>
        <p class="coming-soon-text">
          Be the first to know when Pro launches. Join the waitlist for early access.
        </p>
        <a href="https://vyuh.tech" target="_blank" class="pro-btn">
          <Icon icon="ph:envelope-fill" />
          Join Waitlist
        </a>
      </div>
    </section>

    <!-- Features Grid -->
    <section class="pro-features-section">
      <div class="pro-section-header">
        <div class="badge badge-purple">
          <Icon icon="ph:star-fill" />
          <span>Pro Features</span>
        </div>
        <h2 class="section-title">Everything in Free, Plus...</h2>
        <p class="section-subtitle">Powerful capabilities designed for professional development teams and enterprise applications.</p>
      </div>
      <div class="pro-features-grid">
        <div
          v-for="(feature, index) in proFeatures"
          :key="index"
          class="pro-feature-card"
        >
          <div class="pro-feature-icon">
            <Icon :icon="feature.icon" />
          </div>
          <div class="pro-feature-text">
            <h3 class="pro-feature-title">{{ feature.title }}</h3>
            <p class="pro-feature-desc">{{ feature.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA Section -->
    <section class="pro-cta-section">
      <div class="pro-cta-content">
        <h2 class="pro-cta-title">Ready to Go Pro?</h2>
        <p class="pro-cta-subtitle">Get notified when Pro launches and receive exclusive early-bird pricing.</p>
        <div class="pro-cta-actions">
          <a href="https://vyuh.tech" target="_blank" class="pro-btn pro-btn-primary">
            <Icon icon="ph:envelope-fill" /> Join the Waitlist
          </a>
          <a href="/docs/getting-started/installation" class="pro-btn pro-btn-secondary">
            <Icon icon="ph:download-fill" /> Try Free Version
          </a>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <SiteFooter :is-pro-page="true" />
  </div>
</template>
