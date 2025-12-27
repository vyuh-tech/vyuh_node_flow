<script setup lang="ts">
import Badge from './components/Badge.vue';
import CtaSection from './components/CtaSection.vue';
import FeatureCard from './components/FeatureCard.vue';
import FeatureSection from './components/FeatureSection.vue';
import FlutterBrand from './components/FlutterBrand.vue';
import GridBackground from './components/GridBackground.vue';
import HeroSection from './components/HeroSection.vue';
import MarqueeGroup from './components/MarqueeGroup.vue';
import Section from './components/Section.vue';
import SectionHeader from './components/SectionHeader.vue';
import SelectProgramCard from './components/SelectProgramCard.vue';
import SiteFooter from './components/SiteFooter.vue';
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
const marqueeLines = [
  {
    items: [
      'Unlimited Undo/Redo',
      'Step-through Debugging',
      'Workflow Versioning',
      'Custom Tasks',
      'Task Libraries',
      'Auto-Save',
      'Collaboration',
    ],
    color: 'purple' as const,
  },
  {
    items: [
      'BPMN Activities',
      'Saga Patterns',
      'Retry Policies',
      'Error Handling',
      'Async Execution',
      'Event Streams',
      'Audit Trails',
      'Worker Pools',
    ],
    color: 'teal' as const,
    reverse: true,
  },
  {
    items: [
      'Priority Support',
      'Custom Integrations',
      'SSO Authentication',
      'Role-Based Access',
      'API Access',
      'Webhooks',
      'Custom Branding',
      'SLA Guarantee',
    ],
    color: 'purple' as const,
  },
];
</script>

<template>
  <div class="min-h-screen relative overflow-x-hidden">
    <!-- Grid Background -->
    <GridBackground color="purple" :blinkCells="proBlinkCells" />

    <!-- Hero Section with centered variant -->
    <HeroSection variant="centered">
      <Badge icon="ph:crown-fill" color="purple">Pro Edition</Badge>
      <h1 class="pro-title">
        <span class="pro-title-gradient">Vyuh Node Flow</span>
        <TitleBadge color="amber">Pro</TitleBadge>
      </h1>
      <p class="pro-subtitle">
        Enterprise-grade features for building sophisticated visual editors,
        workflow engines, and BPMN-style automation.
      </p>
      <div class="mt-12">
        <SelectProgramCard />
      </div>
    </HeroSection>

    <!-- Pro Features Grid -->
    <Section first background>
      <SectionHeader
        badge="Pro Features"
        badge-icon="ph:star-fill"
        badge-color="purple"
        title="Everything in Free, Plus..."
        subtitle="Powerful capabilities designed for professional development teams and enterprise applications."
        centered
      />
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <FeatureCard
          v-for="(feature, index) in proFeatures"
          :key="index"
          :icon="feature.icon"
          :title="feature.title"
          :description="feature.desc"
          :color="feature.color"
        />
      </div>
    </Section>

    <!-- Marquee -->
    <MarqueeGroup :lines="marqueeLines" />

    <!-- Workflow Engine Section -->
    <Section background>
      <SectionHeader
        badge="Workflow Engine"
        badge-icon="ph:git-branch-fill"
        badge-color="teal"
        title="Server-Side Workflow Automation"
        subtitle="Design, execute, and monitor BPMN-style workflows with native Dart executors and real-time observability."
        centered
        large-title
      />

      <div class="mt-16">
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
    </Section>

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
        external: true,
      }"
      :secondary-actions="[
        {
          href: '/docs/getting-started/installation',
          icon: 'ph:github-logo-fill',
          label: 'Try Free Version',
        },
      ]"
    >
      <template #subtitle>
        <p
          class="text-lg text-slate-600 dark:text-zinc-400 leading-relaxed mb-10"
        >
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

/* Pro page title - unique gradient styling */
.pro-title {
  @apply text-5xl sm:text-6xl lg:text-7xl font-black leading-none mb-6;
  font-family: var(--vn-font-display);
}

.pro-subtitle {
  @apply text-xl text-slate-600 dark:text-zinc-400 leading-relaxed;
  @apply text-center max-w-2xl mx-auto;
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
</style>
