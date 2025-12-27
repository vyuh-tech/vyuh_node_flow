<script setup lang="ts">
import { Icon } from '@iconify/vue';
import SiteFooter from './SiteFooter.vue';
import Badge from './Badge.vue';
import CtaButton from './CtaButton.vue';
import DetailRow from './DetailRow.vue';
import FlutterBrand from './FlutterBrand.vue';
import SectionHeader from './SectionHeader.vue';

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

const workflowFeatures = [
  {
    tag: 'Visual Design',
    tagIcon: 'ph:flow-arrow-fill',
    tagColor: 'purple' as const,
    title: 'BPMN-Style Workflow Editor',
    subtitle: 'Design complex workflows visually with an intuitive drag-and-drop interface inspired by industry-standard BPMN notation.',
    bullets: [
      'Visual canvas for designing workflow processes',
      'Pre-built activity, gateway, and event nodes',
      'Conditional branching and parallel execution paths',
      'Reusable sub-workflows and templates',
    ],
    media: {
      type: 'video' as const,
      title: 'Workflow Editor Demo',
      description: 'See the visual workflow designer in action',
    },
  },
  {
    tag: 'Dart Execution',
    tagIcon: 'ph:terminal-fill',
    tagColor: 'teal' as const,
    title: 'Native Dart Executors',
    subtitle: 'Run workflows on the server with type-safe Dart executors. Full control over execution logic with native performance.',
    bullets: [
      'Type-safe activity implementations in Dart',
      'Async/await support for non-blocking execution',
      'Built-in retry policies and error handling',
      'Custom executor plugins for specialized tasks',
    ],
    media: {
      type: 'animation' as const,
      title: 'Executor Pipeline',
      description: 'Watch workflows execute step-by-step',
    },
  },
  {
    tag: 'Observability',
    tagIcon: 'ph:chart-line-fill',
    tagColor: 'amber' as const,
    title: 'Real-Time Monitoring',
    subtitle: 'Track every workflow execution with comprehensive monitoring, event streams, and detailed analytics dashboards.',
    bullets: [
      'Live execution status and progress tracking',
      'Complete event history and audit trails',
      'Performance metrics and bottleneck detection',
      'Alerting and notification integrations',
    ],
    media: {
      type: 'image' as const,
      title: 'Monitoring Dashboard',
      description: 'Live workflow analytics and insights',
    },
  },
  {
    tag: 'Enterprise Ready',
    tagIcon: 'ph:buildings-fill',
    tagColor: 'blue' as const,
    title: 'Production-Grade Infrastructure',
    subtitle: 'Deploy workflows with confidence using enterprise features designed for reliability, scalability, and security.',
    bullets: [
      'Distributed execution across multiple workers',
      'Workflow versioning and migration support',
      'Role-based access control for workflows',
      'Integration with external systems and APIs',
    ],
    media: {
      type: 'image' as const,
      title: 'Infrastructure Overview',
      description: 'Scalable workflow architecture',
    },
  },
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
      <Badge icon="ph:crown-fill" color="purple">Pro Edition</Badge>
      <h1 class="pro-title">
        <span class="pro-title-gradient">Vyuh Node Flow</span>
        <span class="pro-title-sub">Pro</span>
      </h1>
      <p class="pro-subtitle">
        Enterprise-grade features for building sophisticated visual editors,
        workflow engines, and BPMN-style automation.
      </p>
      <div class="pro-coming-soon">
        <Badge icon="ph:users-three-fill" color="amber">Select Program</Badge>
        <p class="coming-soon-text">
          We're working closely with select customers to refine the Vyuh Node Flow package,
          editor, and workflow engine. Want to shape the future of visual flow editing in Flutter?
        </p>
        <CtaButton href="https://vyuh.tech" icon="ph:envelope-fill" variant="primary" external>
          Join the Waitlist
        </CtaButton>
      </div>
    </section>

    <!-- Features Grid -->
    <section class="pro-features-section">
      <SectionHeader
        badge="Pro Features"
        badge-icon="ph:star-fill"
        badge-color="purple"
        title="Everything in Free, Plus..."
        subtitle="Powerful capabilities designed for professional development teams and enterprise applications."
        centered
      />
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

    <!-- Workflow Engine Section -->
    <section class="workflow-engine-section">
      <SectionHeader
        badge="Workflow Engine"
        badge-icon="ph:git-branch-fill"
        badge-color="teal"
        title="Server-Side Workflow Automation"
        subtitle="Design, execute, and monitor BPMN-style workflows with native Dart executors and real-time observability."
        centered
        large-title
      />

      <div class="workflow-details">
        <DetailRow
          v-for="(feature, index) in workflowFeatures"
          :key="index"
          :tag="feature.tag"
          :tag-icon="feature.tagIcon"
          :tag-color="feature.tagColor"
          :title="feature.title"
          :subtitle="feature.subtitle"
          :bullets="feature.bullets"
          :media="feature.media"
          :reverse="index % 2 === 1"
        />
      </div>
    </section>

    <!-- CTA Section -->
    <section class="pro-cta-section">
      <div class="pro-cta-content">
        <Badge icon="ph:handshake-fill" color="purple">Partner With Us</Badge>
        <h2 class="pro-cta-title">Join Our Select Program</h2>
        <p class="pro-cta-subtitle">
          We're collaborating with a select group of customers to build the future of visual flow editing in
          <FlutterBrand />. Get early access, direct support, and help shape the product roadmap.
        </p>
        <div class="pro-cta-actions">
          <CtaButton href="https://vyuh.tech" icon="ph:rocket-launch-fill" variant="primary" size="large" external>
            Apply for Select Access
          </CtaButton>
          <CtaButton href="/docs/getting-started/installation" icon="ph:github-logo-fill" variant="secondary" size="large">
            Try Free Version
          </CtaButton>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <SiteFooter :is-pro-page="true" />
  </div>
</template>
