<script setup lang="ts">
import { ref } from 'vue';
import Badge from './components/Badge.vue';
import ComparisonTable, {
  type ComparisonRow,
} from './components/ComparisonTable.vue';
import CtaSection from './components/CtaSection.vue';
import FeatureSection from './components/FeatureSection.vue';
import FloatingNodes from './components/FloatingNodes.vue';
import FlutterBrand from './components/FlutterBrand.vue';
import FormDialog from './components/FormDialog.vue';
import GridBackground from './components/GridBackground.vue';
import HeroSection from './components/HeroSection.vue';
import MarqueeGroup from './components/MarqueeGroup.vue';
import Section from './components/Section.vue';
import SectionConnector from './components/SectionConnector.vue';
import SectionHeader from './components/SectionHeader.vue';
import SelectProgramCard from './components/SelectProgramCard.vue';
import SiteFooter from './components/SiteFooter.vue';
import TitleBadge from './components/TitleBadge.vue';
import { SELECT_PROGRAM_FORM_URL } from './constants';

// Form dialog state
const ctaDialogOpen = ref(false);

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
    duration: 40,
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
    duration: 50, // Slower
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
    duration: 35, // Faster
  },
];

// Comparison table data - merged Pro Features + Plan Comparison
const comparisonRows: ComparisonRow[] = [
  // Core features (both editions)
  { category: 'Core Editor Features', openSource: true, pro: true },
  { category: 'Theming & Customization', openSource: true, pro: true },
  { category: 'Connection Effects', openSource: true, pro: true },
  { category: 'Serialization', openSource: true, pro: true },
  // Pro-exclusive editor features
  { category: 'History & Undo/Redo', openSource: false, pro: true },
  { category: 'Advanced Grouping', openSource: false, pro: true },
  {
    category: 'Extension System',
    openSource: true,
    pro: 'Many more custom extensions',
  },
  { category: 'Custom Node & Graph Layouts', openSource: false, pro: true },
  { category: 'Export & Import', openSource: false, pro: true },
  { category: 'Copy & Paste', openSource: false, pro: true },
  { category: 'Access Control', openSource: false, pro: true },
  // Workflow Engine section
  {
    category: 'Workflow Engine',
    isSection: true,
    icon: 'ph:git-branch-fill',
  },
  {
    category: 'Visual Workflow Editor',
    openSource: false,
    pro: 'See details below',
  },
  {
    category: 'Server-Side Workflow Engine',
    openSource: false,
    pro: 'See details below',
  },
  {
    category: 'Real-Time Monitoring',
    openSource: false,
    pro: 'See details below',
  },
  // Support section
  {
    category: 'Support',
    isSection: true,
    icon: 'ph:headset-fill',
  },
  {
    category: 'Documentation',
    openSource: 'Community',
    pro: 'Advanced Samples & Use Cases',
  },
  { category: 'Priority Support', openSource: false, pro: true },
  {
    category: 'Expert Consultation',
    openSource: false,
    pro: 'Face time with core team',
  },
  { category: 'Architecture Guidance', openSource: false, pro: true },
  {
    category: 'Custom Development',
    openSource: false,
    pro: 'Nodes, plugins & extensions',
  },
  {
    category: 'Bespoke Features',
    openSource: false,
    pro: 'Tailored to your needs',
  },
];
</script>

<template>
  <div class="min-h-screen relative overflow-x-hidden">
    <!-- Grid Background -->
    <GridBackground color="purple" :blinkCells="proBlinkCells" />

    <!-- Floating decorative nodes -->
    <FloatingNodes />

    <!-- Hero Section with centered variant -->
    <HeroSection variant="centered" border-bottom>
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

    <!-- Connector: Hero to Comparison -->
    <SectionConnector color="purple" />

    <!-- Unified Comparison Table Section -->
    <Section border-top border-bottom background>
      <SectionHeader
        badge="Compare Plans"
        badge-icon="ph:scales-fill"
        badge-color="purple"
        subtitle="See what's included in each edition and choose the right fit for your project."
        centered
      >
        <template #title>
          Open Source vs
          <span class="text-amber-500 dark:text-amber-400">Pro</span>
        </template>
      </SectionHeader>
      <ComparisonTable :rows="comparisonRows" />
    </Section>

    <!-- Connector: Comparison to Workflow -->
    <SectionConnector color="purple" />

    <!-- Workflow Engine Section -->
    <Section border-top border-bottom background variant="teal">
      <SectionHeader
        badge="Workflow Engine"
        badge-icon="ph:git-branch-fill"
        badge-color="teal"
        subtitle="Design, execute, and monitor BPMN-style workflows with native Dart executors and real-time observability."
        centered
        large-title
      >
        <template #title>
          <span class="workflow-title-gradient"
            >Server-Side Workflow Automation</span
          >
        </template>
      </SectionHeader>

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

    <!-- Connector: Workflow to Marquee -->
    <SectionConnector color="teal" />

    <!-- Marquee -->
    <MarqueeGroup :lines="marqueeLines" />

    <!-- Connector: Marquee to CTA -->
    <SectionConnector color="purple" />

    <!-- CTA Section -->
    <CtaSection
      border-top
      badge="Partner With Us"
      badge-icon="ph:handshake-fill"
      badge-color="purple"
      title="Join Our Select Program"
      :primary-action="{
        icon: 'ph:rocket-launch-fill',
        label: 'Apply for Select Access',
        onClick: () => (ctaDialogOpen = true),
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

    <!-- Form Dialog for CTA -->
    <FormDialog
      :open="ctaDialogOpen"
      :form-url="SELECT_PROGRAM_FORM_URL"
      @close="ctaDialogOpen = false"
    />

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

/* Workflow section title - teal to amber gradient */
.workflow-title-gradient {
  background: linear-gradient(
    135deg,
    theme('colors.teal.600'),
    theme('colors.amber.500')
  );
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.dark .workflow-title-gradient {
  background: linear-gradient(
    135deg,
    theme('colors.teal.400'),
    theme('colors.amber.400')
  );
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
</style>
