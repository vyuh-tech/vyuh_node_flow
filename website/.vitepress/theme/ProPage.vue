<script setup lang="ts">
import { ref } from 'vue';
import Badge from './components/Badge.vue';
import CodePreview, { type CodeMarker } from './components/CodePreview.vue';
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

// Import code sample for Dart Executors
import validateDataExecutorCode from './code-samples/validate-data-executor.dart?raw';

// Code markers for the executor sample
const executorCodeMarkers: CodeMarker[] = [
  {
    line: 7,
    title: 'Typed Input',
    description:
      'Define your input structure with full type safety. Implement fromJson for deserialization.',
  },
  {
    line: 16,
    title: 'Typed Output',
    description:
      'Output is also strongly typed. Implement toJson for serialization to workflow variables.',
  },
  {
    line: 29,
    title: 'TypedTaskExecutor',
    description:
      'Extend TypedTaskExecutor<TInput, TOutput> for compile-time type safety. The base class handles error wrapping automatically.',
  },
  {
    line: 34,
    title: 'TypeDescriptor',
    description:
      'Register with a TypeDescriptor for JSON-driven workflows. Defines how to deserialize this executor from workflow definitions.',
  },
  {
    line: 55,
    title: 'executeTyped',
    description:
      'Implement your business logic here with full access to typed input and ExecutionContext.',
  },
  {
    line: 74,
    title: 'Registration',
    description:
      'Register your executor with the WorkflowDescriptor to make it available to the workflow engine.',
  },
];

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

const editorSdkFeatures = [
  {
    tag: 'Visual Editor',
    tagIcon: 'ph:flow-arrow-fill',
    tagColor: 'purple' as const,
    title: 'BPMN-Style Workflow Editor',
    subtitle:
      'Build workflow editors with BPMN-inspired notation. Complete with node palette, property panels, and drag-and-drop composition.',
    bullets: [
      'Node palette with categorized workflow nodes',
      'Property panels for configuring node behavior',
      'Conditional branching and parallel execution paths',
      'Pre-built activity, gateway, and event nodes',
    ],
    video: '/videos/editor.webm',
  },
  {
    tag: 'Simulation',
    tagIcon: 'ph:play-circle-fill',
    tagColor: 'teal' as const,
    title: 'Embedded Simulation Engine',
    subtitle:
      'Test workflows directly in the editor with a lightweight embedded engine. Step through execution, inspect variables, and debug logic.',
    bullets: [
      'Step-through execution with breakpoints',
      'Variable inspection at each node',
      'Simulate different input scenarios',
      'Validate workflow logic before deployment',
    ],
    code: {
      source: validateDataExecutorCode,
      filename: 'validate_data_executor.dart',
      markers: executorCodeMarkers,
    },
  },
  {
    tag: 'Monitoring',
    tagIcon: 'ph:chart-line-fill',
    tagColor: 'amber' as const,
    title: 'Real-Time Monitoring Dashboard',
    subtitle:
      'Build monitoring interfaces that track workflow execution in real-time. Visualize progress, inspect state, and debug issues.',
    bullets: [
      'Live execution status visualization',
      'Node-by-node progress tracking',
      'Execution history and audit trails',
      'Error highlighting and stack traces',
    ],
    video: '/videos/monitoring.webm',
  },
];

// Marquee content for Editor SDK features
const marqueeLines = [
  {
    items: [
      'Unlimited Undo/Redo',
      'Copy & Paste',
      'Node Palette',
      'Property Panels',
      'Custom Layouts',
      'Auto-Save',
      'Keyboard Shortcuts',
    ],
    color: 'purple' as const,
    duration: 40,
  },
  {
    items: [
      'Step-through Debugging',
      'Breakpoints',
      'Variable Inspection',
      'BPMN Activities',
      'Simulation Engine',
      'Execution Tracing',
      'Error Highlighting',
      'State Snapshots',
    ],
    color: 'teal' as const,
    reverse: true,
    duration: 50, // Slower
  },
  {
    items: [
      'Priority Support',
      'Custom Extensions',
      'Architecture Guidance',
      'Role-Based Access',
      'Export & Import',
      'JSON Serialization',
      'Custom Theming',
      'Expert Consultation',
    ],
    color: 'purple' as const,
    duration: 35, // Faster
  },
];

// Comparison table data - Editor SDK Features
const comparisonRows: ComparisonRow[] = [
  // Core Editor section
  {
    category: 'Core Editor',
    isSection: true,
    icon: 'ph:frame-corners-fill',
  },
  { category: 'Visual Node Graph Canvas', openSource: true, pro: true },
  { category: 'Theming & Customization', openSource: true, pro: true },
  { category: 'Connection Effects', openSource: true, pro: true },
  { category: 'Serialization (JSON)', openSource: true, pro: true },
  {
    category: 'Extension System',
    openSource: true,
    pro: 'Many more custom extensions',
  },
  // Editor SDK Features section
  {
    category: 'Editor SDK Features',
    isSection: true,
    icon: 'ph:code-fill',
  },
  { category: 'History & Undo/Redo', openSource: false, pro: true },
  { category: 'Copy & Paste', openSource: false, pro: true },
  { category: 'Node Palette', openSource: false, pro: true },
  { category: 'Property Panels', openSource: false, pro: true },
  { category: 'Export & Import', openSource: false, pro: true },
  { category: 'Custom Node & Graph Layouts', openSource: false, pro: true },
  { category: 'Advanced Grouping', openSource: false, pro: true },
  { category: 'Access Control', openSource: false, pro: true },
  // Simulation & Debugging section
  {
    category: 'Simulation & Debugging',
    isSection: true,
    icon: 'ph:play-circle-fill',
  },
  {
    category: 'Embedded Simulation Engine',
    openSource: false,
    pro: 'See examples below',
  },
  {
    category: 'Step-through Debugging',
    openSource: false,
    pro: 'See examples below',
  },
  {
    category: 'Real-Time Monitoring',
    openSource: false,
    pro: 'See examples below',
  },
  {
    category: 'Breakpoints & Inspection',
    openSource: false,
    pro: 'See examples below',
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
        A comprehensive Editor SDK for building enterprise-grade workflow
        editors with undo/redo, copy-paste, node palettes, property panels, and
        an embedded simulation engine.
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
        subtitle="The Editor SDK provides everything you need to build professional workflow editors. Compare editions below."
        centered
      >
        <template #title>
          Open Source vs
          <span class="text-amber-500 dark:text-amber-400">Pro</span>
        </template>
      </SectionHeader>
      <ComparisonTable :rows="comparisonRows" />
    </Section>

    <!-- Connector: Comparison to Editor SDK Examples -->
    <SectionConnector color="purple" />

    <!-- Editor SDK Examples Section -->
    <Section border-top border-bottom background variant="teal">
      <SectionHeader
        badge="Editor SDK Examples"
        badge-icon="ph:code-fill"
        badge-color="teal"
        subtitle="Build professional workflow editors with BPMN-style nodes, embedded simulation, step-through debugging, and real-time monitoring."
        centered
        large-title
      >
        <template #title>
          <span class="workflow-title-gradient"
            >Build Enterprise Workflow Editors</span
          >
        </template>
      </SectionHeader>

      <div class="mt-16">
        <template v-for="(feature, index) in editorSdkFeatures" :key="index">
          <FeatureSection
            v-if="feature.code"
            :tag="feature.tag"
            :tag-icon="feature.tagIcon"
            :tag-color="feature.tagColor"
            :title="feature.title"
            :subtitle="feature.subtitle"
            :bullets="feature.bullets"
            :reverse="index % 2 === 1"
          >
            <CodePreview
              :code="feature.code.source"
              :filename="feature.code.filename"
              lang="dart"
              :markers="feature.code.markers"
              class="executor-code-preview"
            />
          </FeatureSection>
          <FeatureSection
            v-else
            :tag="feature.tag"
            :tag-icon="feature.tagIcon"
            :tag-color="feature.tagColor"
            :title="feature.title"
            :subtitle="feature.subtitle"
            :bullets="feature.bullets"
            :video="feature.video"
            :placeholder="feature.placeholder"
            :reverse="index % 2 === 1"
          />
        </template>
      </div>
    </Section>

    <!-- Connector: Editor SDK Examples to Marquee -->
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
          href: '/docs/start/installation',
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

/* Code preview styling for executor sample */
.executor-code-preview {
  @apply w-full h-full flex flex-col;
  height: 500px;
  box-shadow:
    0 0 60px -15px rgba(99, 102, 241, 0.4),
    0 25px 50px -12px rgba(0, 0, 0, 0.25);
}

:root.dark .executor-code-preview {
  box-shadow:
    0 0 80px -15px rgba(129, 140, 248, 0.3),
    0 25px 50px -12px rgba(0, 0, 0, 0.5);
}

/* Same approach as TabbedCodePreview */
.executor-code-preview .code-body-wrapper {
  @apply flex-1 overflow-hidden;
}

.executor-code-preview .code-scroll-container {
  @apply h-full overflow-y-auto overflow-x-auto;
}

@media (max-width: 768px) {
  .executor-code-preview {
    height: 400px;
  }
}
</style>
