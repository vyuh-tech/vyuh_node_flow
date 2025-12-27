<script setup lang="ts">
import { Icon } from '@iconify/vue';
import SiteFooter from './components/SiteFooter.vue';
import Badge from './components/Badge.vue';
import CtaButton from './components/CtaButton.vue';
import CtaSection from './components/CtaSection.vue';
import FeatureCard from './components/FeatureCard.vue';
import FeatureSection from './components/FeatureSection.vue';
import FlutterBrand from './components/FlutterBrand.vue';
import GridBackground from './components/GridBackground.vue';
import MarqueeSection from './components/MarqueeSection.vue';
import SectionHeader from './components/SectionHeader.vue';
import TitleBadge from './components/TitleBadge.vue';

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
  {
    icon: 'ph:clock-counter-clockwise-fill',
    title: 'History & Undo/Redo',
    desc: 'Full history management with unlimited undo/redo stack and time-travel debugging.',
    color: 'purple' as const,
  },
  {
    icon: 'ph:arrows-split-fill',
    title: 'Advanced Grouping',
    desc: 'Nested groups, collapsible subflows, and hierarchical node organization.',
    color: 'blue' as const,
  },
  {
    icon: 'ph:puzzle-piece-fill',
    title: 'Extension System',
    desc: 'Plugin architecture for custom tools, panels, and editor extensions.',
    color: 'teal' as const,
  },
  {
    icon: 'ph:cloud-arrow-down-fill',
    title: 'Cloud Sync',
    desc: 'Real-time collaboration with cloud-based flow storage and versioning.',
    color: 'amber' as const,
  },
  {
    icon: 'ph:magic-wand-fill',
    title: 'AI-Powered Layouts',
    desc: 'Intelligent auto-layout algorithms for optimal graph organization.',
    color: 'purple' as const,
  },
  {
    icon: 'ph:export-fill',
    title: 'Export & Import',
    desc: 'Export to multiple formats including PNG, SVG, PDF, and custom schemas.',
    color: 'blue' as const,
  },
  {
    icon: 'ph:lock-key-fill',
    title: 'Access Control',
    desc: 'Role-based permissions for collaborative editing and view-only modes.',
    color: 'teal' as const,
  },
  {
    icon: 'ph:headset-fill',
    title: 'Priority Support',
    desc: 'Direct access to the development team with priority issue resolution.',
    color: 'amber' as const,
  },
];

const workflowFeatures = [
  {
    tag: 'Visual Design',
    tagIcon: 'ph:flow-arrow-fill',
    tagColor: 'purple' as const,
    title: 'BPMN-Style Workflow Editor',
    subtitle:
      'Design complex workflows visually with an intuitive drag-and-drop interface inspired by industry-standard BPMN notation.',
    bullets: [
      'Visual canvas for designing workflow processes',
      'Pre-built activity, gateway, and event nodes',
      'Conditional branching and parallel execution paths',
      'Simulation mode with step-through debugging',
    ],
    placeholder: {
      type: 'video' as const,
      title: 'Workflow Editor Demo',
      description: 'See the visual workflow designer in action',
    },
  },
  {
    tag: 'Dart Execution',
    tagIcon: 'simple-icons:dart',
    tagColor: 'blue' as const,
    title: 'Native Dart Executors',
    subtitle:
      'Run workflows on the server with type-safe Dart executors. Full control over execution logic with native performance.',
    bullets: [
      'Type-safe activity implementations in Dart',
      'Async/await support for non-blocking execution',
      'Built-in retry policies and error handling',
      'Custom executor plugins for specialized tasks',
    ],
    placeholder: {
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
    subtitle:
      'Track every workflow execution with comprehensive monitoring, event streams, and detailed analytics dashboards.',
    bullets: [
      'Live execution status and progress tracking',
      'Complete event history and audit trails',
      'Performance metrics and bottleneck detection',
      'Alerting and notification integrations',
    ],
    placeholder: {
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
    subtitle:
      'Deploy workflows with confidence using enterprise features designed for reliability, scalability, and security.',
    bullets: [
      'Distributed execution across multiple workers',
      'Workflow versioning and migration support',
      'Role-based access control for workflows',
      'Integration with external systems and APIs',
    ],
    placeholder: {
      type: 'image' as const,
      title: 'Infrastructure Overview',
      description: 'Scalable workflow architecture',
    },
  },
];

// Marquee content for Pro features
const marqueePurple = [
  'Unlimited Undo/Redo',
  'Step-through Debugging',
  'Workflow Versioning',
  'Custom Tasks',
  'Task Libraries',
  'Auto-Save',
  'Collaboration',
];

const marqueeTeal = [
  'BPMN Activities',
  'Saga Patterns',
  'Retry Policies',
  'Error Handling',
  'Async Execution',
  'Event Streams',
  'Audit Trails',
  'Worker Pools',
];

const marqueeAmber = [
  'Priority Support',
  'Custom Integrations',
  'SSO Authentication',
  'Role-Based Access',
  'API Access',
  'Webhooks',
  'Custom Branding',
  'SLA Guarantee',
];
</script>

<template>
  <div class="pro-page">
    <!-- Grid Background (reused component) -->
    <GridBackground color="purple" :blinkCells="proBlinkCells" />

    <!-- Blur Effects -->
    <div class="pro-background">
      <div class="pro-blur pro-blur-purple" />
      <div class="pro-blur pro-blur-blue" />
      <div class="pro-blur pro-blur-teal" />
    </div>

    <!-- Hero Section -->
    <section class="pro-hero">
      <Badge icon="ph:crown-fill" color="purple">Pro Edition</Badge>
      <h1 class="pro-title">
        <span class="pro-title-gradient">Vyuh Node Flow</span>
        <TitleBadge color="amber">Pro</TitleBadge>
      </h1>
      <p class="pro-subtitle">
        Enterprise-grade features for building sophisticated visual editors,
        workflow engines, and BPMN-style automation.
      </p>
      <div class="pro-select-card">
        <Badge icon="ph:users-three-fill" color="amber">Select Program</Badge>
        <p class="pro-select-text">
          We're working closely with select customers to refine the Vyuh Node
          Flow package, editor, and workflow engine. Want to shape the future of
          visual flow editing in Flutter?
        </p>
        <CtaButton
          href="https://vyuh.tech"
          icon="ph:envelope-fill"
          variant="primary"
          external
        >
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
        <FeatureCard
          v-for="(feature, index) in proFeatures"
          :key="index"
          :icon="feature.icon"
          :title="feature.title"
          :description="feature.desc"
          :color="feature.color"
        />
      </div>
    </section>

    <!-- Marquee -->
    <section class="pro-marquee-section">
      <MarqueeSection :items="marqueePurple" color="purple" />
      <MarqueeSection :items="marqueeTeal" color="teal" reverse />
      <MarqueeSection :items="marqueeAmber" color="purple" />
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
        <FeatureSection
          v-for="(feature, index) in workflowFeatures"
          :key="index"
          :tag="feature.tag"
          :tag-icon="feature.tagIcon"
          :tag-color="feature.tagColor"
          :title="feature.title"
          :subtitle="feature.subtitle"
          :bullets="feature.bullets"
          :placeholder="feature.placeholder"
          :reverse="index % 2 === 1"
        />
      </div>
    </section>

    <!-- CTA Section -->
    <CtaSection
      badge="Partner With Us"
      badge-icon="ph:handshake-fill"
      badge-color="purple"
      title="Join Our Select Program"
      :primary-action="{
        href: 'https://vyuh.tech',
        icon: 'ph:rocket-launch-fill',
        label: 'Apply for Select Access',
        external: true
      }"
      :secondary-actions="[
        { href: '/docs/getting-started/installation', icon: 'ph:github-logo-fill', label: 'Try Free Version' }
      ]"
    >
      <template #subtitle>
        <p class="cta-subtitle">
          We're collaborating with a select group of customers to build the
          future of visual flow editing in
          <FlutterBrand />. Get early access, direct support, and help shape the
          product roadmap.
        </p>
      </template>
    </CtaSection>

    <!-- Footer -->
    <SiteFooter :is-pro-page="true" />
  </div>
</template>

<style>
@reference "./style.css";

/* ═══════════════════════════════════════════════════════════════════
   PRO PAGE BASE
   ═══════════════════════════════════════════════════════════════════ */

.pro-page {
  @apply min-h-screen relative overflow-x-hidden;
  /* No solid background - let the grid show through */
}

/* ═══════════════════════════════════════════════════════════════════
   BACKGROUND EFFECTS
   ═══════════════════════════════════════════════════════════════════ */

.pro-background {
  @apply fixed inset-0 z-[1] pointer-events-none overflow-hidden;
}

.pro-blur {
  @apply absolute w-96 h-96 rounded-full blur-3xl;
}

.pro-blur-purple {
  @apply bg-violet-500/20 dark:bg-violet-400/15 top-1/4 left-1/4;
}

.pro-blur-blue {
  @apply bg-blue-500/15 dark:bg-blue-400/10 top-1/2 right-1/4;
}

.pro-blur-teal {
  @apply bg-teal-500/15 dark:bg-teal-400/10 bottom-1/4 left-1/3;
}

/* ═══════════════════════════════════════════════════════════════════
   HERO SECTION
   ═══════════════════════════════════════════════════════════════════ */

.pro-hero {
  @apply relative z-10 py-32 px-6 text-center max-w-4xl mx-auto;
}

.pro-title {
  @apply text-5xl sm:text-6xl lg:text-7xl font-black leading-none mb-6;
  font-family: var(--vn-font-display);
}

.pro-title-gradient {
  @apply block;
  background: linear-gradient(
    135deg,
    theme('colors.blue.600'),
    theme('colors.violet.600')
  );
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.dark .pro-title-gradient {
  background: linear-gradient(
    135deg,
    theme('colors.blue.400'),
    theme('colors.violet.400')
  );
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.pro-subtitle {
  @apply text-xl text-slate-600 dark:text-zinc-400 leading-relaxed mb-10 max-w-2xl mx-auto;
}

.pro-select-card {
  @apply flex flex-col items-center gap-4 p-8 rounded-2xl max-w-xl mx-auto;
  @apply bg-white/80 dark:bg-zinc-800/60 backdrop-blur-sm;
  @apply border border-slate-200/60 dark:border-zinc-600/40;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
}

.dark .pro-select-card {
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.pro-select-text {
  @apply text-base text-slate-500 dark:text-zinc-400 text-center;
}

/* ═══════════════════════════════════════════════════════════════════
   FEATURES SECTION
   ═══════════════════════════════════════════════════════════════════ */

.pro-features-section {
  @apply relative z-10 py-24 px-6 max-w-6xl mx-auto;
}

.pro-features-grid {
  @apply grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6;
}

/* ═══════════════════════════════════════════════════════════════════
   MARQUEE SECTION
   ═══════════════════════════════════════════════════════════════════ */

.pro-marquee-section {
  @apply relative z-10 py-10 overflow-hidden;
  @apply bg-white/70 dark:bg-zinc-800/50;
  @apply backdrop-blur-md;
}

/* ═══════════════════════════════════════════════════════════════════
   WORKFLOW ENGINE SECTION
   ═══════════════════════════════════════════════════════════════════ */

.workflow-engine-section {
  @apply relative z-10 py-24 px-6 max-w-6xl mx-auto;
}

.workflow-details {
  @apply mt-16;
}
</style>
