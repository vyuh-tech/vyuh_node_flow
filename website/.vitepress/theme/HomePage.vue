<script setup lang="ts">
import {computed} from 'vue';
import {Icon} from '@iconify/vue';
import Badge from './components/Badge.vue';
import BentoGrid from './components/BentoGrid.vue';
import CtaButton from './components/CtaButton.vue';
import CtaSection from './components/CtaSection.vue';
import CommunityShowcase from './components/CommunityShowcase.vue';
import DemoFrame from './components/DemoFrame.vue';
import FeatureCard from './components/FeatureCard.vue';
import FeatureSection from './components/FeatureSection.vue';
import FloatingNodes from './components/FloatingNodes.vue';
import FlutterBrand from './components/FlutterBrand.vue';
import GridBackground from './components/GridBackground.vue';
import HeroSection from './components/HeroSection.vue';
import MarqueeGroup from './components/MarqueeGroup.vue';
import QuickStartSection from './components/QuickStartSection.vue';
import Section from './components/Section.vue';
import SectionConnector from './components/SectionConnector.vue';
import SectionHeader from './components/SectionHeader.vue';
import SiteFooter from './components/SiteFooter.vue';

// Demo URL - use localhost in dev mode, production URL otherwise
const demoUrl = computed(() => {
  const path = '#/hero/image?embed=true';
  return import.meta.env.DEV
    ? `https://flow.demo.vyuh.tech/${path}`
    // ? `http://localhost:8080/${path}`
    : `https://flow.demo.vyuh.tech/${path}`;
});

// Marquee content
const marqueeLines = [
  {
    items: [
      'High Performance',
      'Annotations & Sticky Notes',
      'Keyboard Shortcuts',
      'Read-Only Viewer',
      'Multi-touch Gestures',
      'Undo/Redo Support',
      'Auto Pan',
      'Bezier Curves',
      'Node Shapes',
      'Behavior Modes',
    ],
    color: 'blue' as const,
    duration: 40,
  },
  {
    items: [
      'Dark & Light Themes',
      'Snap to Grid',
      'Zoom Controls',
      'Drag Selection',
      'Viewport Animations',
      'Infinite Canvas',
      'Align & Distribute',
      'Z-Order Controls',
    ],
    color: 'purple' as const,
    reverse: true,
    duration: 50, // Slower
  },
  {
    items: [
      'Port Validation',
      'Event Callbacks',
      'Viewport Controls',
      'Grid Styles',
      'Node Resizing',
      'Connection Effects',
      'Connection Labels',
      'Lock & Freeze',
      'Level of Detail',
      'Viewport Culling',
    ],
    color: 'teal' as const,
    duration: 35, // Faster
  },
];

// Capability cards for the grid
const capabilities = [
  {
    icon: 'ph:lightning-fill',
    title: 'High Performance',
    desc: 'Render hundreds of nodes at 60fps with optimized virtualization and efficient canvas rendering.',
    color: 'blue' as const,
  },
  {
    icon: 'ph:paint-brush-fill',
    title: 'Custom Themes',
    desc: 'Style every aspect of your editor to match your brand identity with comprehensive theming.',
    color: 'purple' as const,
  },
  {
    icon: 'ph:link-fill',
    title: 'Smart Connections',
    desc: 'Auto-routing, validation rules, and multiple path styles including Bezier and Smoothstep.',
    color: 'teal' as const,
  },
  {
    icon: 'ph:cube-fill',
    title: 'Custom Nodes',
    desc: 'Build any node UI with Flutter widgets. Includes Circle, Diamond, and Hexagon shapes out of the box.',
    color: 'amber' as const,
  },
  {
    icon: 'ph:map-trifold-fill',
    title: 'MiniMap',
    desc: 'Navigate massive graphs with a real-time overview and click-to-pan navigation.',
    color: 'blue' as const,
  },
  {
    icon: 'ph:shield-check-fill',
    title: 'Type-Safe API',
    desc: 'Strongly-typed nodes, connections, and graph data with full Dart generics support.',
    color: 'purple' as const,
  },
  {
    icon: 'ph:file-code-fill',
    title: 'Serialization',
    desc: 'Save and load flows from JSON with type-safe deserialization and custom converters.',
    color: 'teal' as const,
  },
  {
    icon: 'ph:sparkle-fill',
    title: 'Connection Effects',
    desc: 'Animated effects like FlowingDash, Particle, Pulse, and GradientFlow animations.',
    color: 'amber' as const,
  },
  {
    icon: 'ph:broadcast-fill',
    title: 'Event System',
    desc: 'Rich callbacks for all interactions including node moves, connections, and selections.',
    color: 'blue' as const,
  },
  {
    icon: 'ph:note-fill',
    title: 'Annotations',
    desc: 'Add sticky notes and documentation directly on the canvas for context.',
    color: 'purple' as const,
  },
  {
    icon: 'ph:stack-fill',
    title: 'Group Nodes',
    desc: 'Create collapsible groups with nested hierarchies. Align and distribute nodes for clean layouts.',
    color: 'teal' as const,
  },
  {
    icon: 'ph:hand-pointing-fill',
    title: 'Touch Optimized',
    desc: 'Full multi-touch support with pinch zoom, pan gestures, and haptic feedback ready.',
    color: 'amber' as const,
  },
  {
    icon: 'ph:puzzle-piece-fill',
    title: 'Plugin System',
    desc: 'Modular architecture with plug-and-play plugins for adding features without modifying core.',
    color: 'blue' as const,
  },
  {
    icon: 'ph:arrows-out-fill',
    title: 'Auto-Pan',
    desc: 'Automatically pan the viewport when dragging nodes or connections near canvas edges.',
    color: 'purple' as const,
  },
  {
    icon: 'ph:eye-fill',
    title: 'Level of Detail',
    desc: 'Opt-in progressive rendering for graph-heavy experiences that need an adaptive overview.',
    color: 'teal' as const,
  },
  {
    icon: 'ph:bug-fill',
    title: 'Debug Layers',
    desc: 'Visual debugging overlays showing hit areas, spatial indices, and performance metrics.',
    color: 'amber' as const,
  },
];

// Detailed feature sections
const detailedFeatures = [
  {
    tag: 'Developer Experience',
    tagColor: 'blue' as const,
    icon: 'ph:code-fill',
    title: 'Declarative & Type-Safe',
    subtitle:
      'Built for Flutter developers who love clean, maintainable code. Define your nodes, connections, and logic in pure Dart with full type safety.',
    bullets: [
      'Reactive state with automatic graph updates',
      'Strict typing catches errors at compile time',
      'Pattern matching for node data handling',
      'Comprehensive API documentation',
    ],
    video: '/videos/type-safe.webm',
  },
  {
    tag: 'Theming',
    tagColor: 'purple' as const,
    icon: 'ph:palette-fill',
    title: 'Designed for Your Brand',
    subtitle:
      "Don't settle for default styles. Our comprehensive theming system allows you to customize every pixel - from node borders and shadows to connection colors and grid patterns.",
    bullets: [
      'Dark & Light mode support out of the box',
      'Granular control over ports, labels, and handles',
      'Custom shapes for endpoints and markers',
      'Consistent theming across all components',
    ],
    video: '/videos/theming.webm',
  },
  {
    tag: 'Interactions',
    tagColor: 'teal' as const,
    icon: 'ph:hand-swipe-right-fill',
    title: 'Fluid Interactions',
    subtitle:
      'Make your flows feel tangible. Connections snap into place, nodes glow on selection, and data flow is visualized with beautiful, performant animations.',
    bullets: [
      '60fps animations even with complex graphs',
      'Connection effects: FlowingDash, Particles, Pulse, Rainbow',
      'Drag-and-drop with snap-to-port validation',
      'Smooth pan and zoom with momentum',
    ],
    video: '/videos/interactions.webm',
  },
  {
    tag: 'Custom Nodes',
    tagColor: 'amber' as const,
    icon: 'ph:cube-fill',
    title: 'Build Any Node You Can Imagine',
    subtitle:
      'Create custom node types using standard Flutter widgets. From simple text nodes to complex forms with inputs, dropdowns, and live previews.',
    bullets: [
      'Use any Flutter widget inside nodes',
      'Custom port positions and shapes',
      'Dynamic sizing and resizing support',
      'Node templates for rapid development',
    ],
    video: '/videos/node-styles.webm',
  },
  {
    tag: 'Performance',
    tagColor: 'purple' as const,
    icon: 'ph:chart-line-up-fill',
    title: 'Built for Scale',
    subtitle:
      'Irrespective of the number of nodes, Vyuh Node Flow maintains buttery smooth performance using efficient rendering techniques and virtualization.',
    bullets: [
      'Virtualized viewport rendering',
      'Optimized gesture handling',
      'Minimal memory footprint',
      'Efficient hit testing algorithms',
    ],
    video: '/videos/perf.webm',
  },
];

// Use cases from flow.vyuh.tech
const useCases = [
  {
    icon: 'ph:git-branch-fill',
    title: 'Workflow Automation',
    desc: 'Visual step-by-step logic engines',
    color: 'blue' as const,
  },
  {
    icon: 'ph:cpu-fill',
    title: 'IoT Device Managers',
    desc: 'Real-time device network topologies',
    color: 'purple' as const,
  },
  {
    icon: 'ph:code-fill',
    title: 'Visual Coding Tools',
    desc: 'Custom node-based programming editors',
    color: 'teal' as const,
  },
  {
    icon: 'ph:sparkle-fill',
    title: 'Chatbot Builders',
    desc: 'Dialogue tree and response mapping',
    color: 'amber' as const,
  },
  {
    icon: 'ph:database-fill',
    title: 'Database Design',
    desc: 'Schema visualization and relationship mapping',
    color: 'blue' as const,
  },
  {
    icon: 'ph:map-trifold-fill',
    title: 'Mind Mapping',
    desc: 'Infinite canvas for collaborative ideas',
    color: 'purple' as const,
  },
  {
    icon: 'ph:share-network-fill',
    title: 'Network Topologies',
    desc: 'Cloud infrastructure visualization',
    color: 'teal' as const,
  },
  {
    icon: 'ph:lightning-fill',
    title: 'Circuit Simulators',
    desc: 'Electronic and logic gate simulation',
    color: 'amber' as const,
  },
];

const communityProjects = [
  {
    title: 'Vyuh Workflow Editor',
    description:
      'A visual workflow editor for building BPMN-inspired workflows in Flutter, powered by Vyuh Node Flow.',
    authorHandle: '@vyuh_tech',
    href: 'https://editor.flow.vyuh.tech',
    media: {
      type: 'image' as const,
      src: 'https://editor.flow.vyuh.tech/workflow-editor-banner.png',
      alt: 'Vyuh Workflow Editor showing a visual workflow built with connected nodes',
    },
  },
  {
    title: 'Zen Router Dev Tools',
    description:
      'A Flutter DevTools extension for exploring route graphs in real time, testing deep links, and debugging navigation with Vyuh Node Flow.',
    authorHandle: '@definev2',
    href: 'https://pub.dev/packages/zenrouter',
    media: {
      type: 'video' as const,
      src: '/videos/zenrouter-devtools.mp4',
      poster: '/images/community/zenrouter-devtools.webp',
      alt: 'Zen Router Dev Tools showing a live route graph powered by Vyuh Node Flow',
    },
  },
];

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

const heroBlinkCells = generateBlinkCells(20, 42);
</script>

<template>
  <div class="home-page min-h-screen relative isolate overflow-x-hidden">
    <GridBackground color="blue" :blinkCells="heroBlinkCells" />
    <FloatingNodes />

    <!-- Hero Section -->
    <HeroSection>
      <template #text>
        <Badge icon="simple-icons:flutter" color="blue">Flutter native</Badge>
        <h1 class="hero-title">
          Turn complex systems into
          <span class="hero-accent">clear, interactive flows.</span>
        </h1>
        <p class="hero-summary">
          A production-ready node editor for <FlutterBrand />. Shape workflows,
          visual programming tools, system maps, and any experience where
          connections matter.
        </p>
        <div class="hero-actions">
          <CtaButton
            href="/docs/start/installation"
            variant="primary"
            size="large"
          >
            Get Started <Icon icon="ph:arrow-right-bold" />
          </CtaButton>
          <CtaButton
            href="https://flow.demo.vyuh.tech"
            icon="ph:play-fill"
            variant="secondary"
            size="large"
            external
          >
            Live Demo
          </CtaButton>
        </div>
        <dl class="hero-proof" aria-label="Product highlights">
          <div>
            <dt>Typed</dt>
            <dd>Pure Dart APIs</dd>
          </div>
          <div>
            <dt>Native</dt>
            <dd>Flutter widgets</dd>
          </div>
          <div>
            <dt>Scalable</dt>
            <dd>LOD + culling</dd>
          </div>
        </dl>
      </template>

      <template #visual>
        <DemoFrame :url="demoUrl" title="Vyuh Node Flow Demo" />
      </template>
    </HeroSection>

    <!-- Quick Start Code Preview Section -->
    <QuickStartSection />

    <!-- Detailed Feature Sections -->
    <Section background>
      <FeatureSection
        v-for="(feature, index) in detailedFeatures"
        :key="index"
        :tag="feature.tag"
        :tag-icon="feature.icon"
        :tag-color="feature.tagColor"
        :title="feature.title"
        :subtitle="feature.subtitle"
        :bullets="feature.bullets"
        :placeholder="feature.placeholder"
        :video="feature.video"
        :image="feature.image"
        :reverse="index % 2 === 1"
      />
    </Section>

    <!-- Capabilities Grid -->
    <Section border-bottom background>
      <SectionHeader
        badge="Capabilities"
        badge-icon="ph:squares-four-fill"
        badge-color="purple"
        title="Everything You Need"
        subtitle="Build sophisticated visual editors with a complete toolkit designed for Flutter."
        centered
      />
      <BentoGrid>
        <FeatureCard
          v-for="(cap, index) in capabilities"
          :key="index"
          :icon="cap.icon"
          :title="cap.title"
          :description="cap.desc"
          :color="cap.color"
        />
      </BentoGrid>
    </Section>

    <!-- Section connector -->
    <SectionConnector color="purple" />

    <!-- Marquee -->
    <MarqueeGroup :lines="marqueeLines" />

    <!-- Section connector -->
    <SectionConnector color="teal" />

    <!-- Use Cases Section -->
    <Section border-top border-bottom background>
      <SectionHeader
        badge="Infinite Possibilities"
        badge-icon="ph:infinity"
        badge-color="teal"
        title="Build Anything"
        subtitle="From simple diagrams to complex visual programming environments, Vyuh Node Flow adapts to your needs."
        centered
      />
      <div class="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        <FeatureCard
          v-for="(useCase, index) in useCases"
          :key="index"
          :icon="useCase.icon"
          :title="useCase.title"
          :description="useCase.desc"
          :color="useCase.color"
        />
      </div>
    </Section>

    <!-- Community Showcase -->
    <Section id="community" border-bottom size="xl">
      <div class="community-heading">
        <SectionHeader
          badge="Community showcase"
          badge-icon="ph:users-three-fill"
          badge-color="blue"
          title="What people are building"
          subtitle="Real tools, experiments, and products made with Vyuh Node Flow. Share yours and help the next builder see what is possible."
        />
        <a
          class="community-submit"
          href="https://github.com/vyuh-tech/vyuh_node_flow/issues/new?title=Community%20showcase%20submission"
          target="_blank"
          rel="noopener noreferrer"
        >
          Submit your project
          <Icon icon="ph:arrow-up-right-bold" />
        </a>
      </div>
      <CommunityShowcase :projects="communityProjects" />
    </Section>

    <!-- CTA Section -->
    <CtaSection
      badge="Ready"
      badge-icon="ph:rocket-launch-fill"
      badge-color="amber"
      title="Ready to Create?"
      subtitle="Join developers building next-generation visual editors with Flutter. Production-ready, fully typed, and beautifully designed."
      :primary-action="{
        href: '/docs/start/installation',
        icon: 'ph:book-open-fill',
        label: 'Read the Docs',
      }"
      :secondary-actions="[
        {
          href: 'https://pub.dev/packages/vyuh_node_flow',
          icon: 'simple-icons:dart',
          label: 'View on pub.dev',
          external: true,
        },
        {
          href: 'https://github.com/vyuh-tech/vyuh_node_flow',
          icon: 'ph:github-logo-fill',
          label: 'Star on GitHub',
          external: true,
        },
      ]"
    />

    <!-- Footer -->
    <SiteFooter />
  </div>
</template>

<style>
@reference "./style.css";

.hero-title {
  @apply mt-6 mb-6 text-balance text-5xl sm:text-6xl lg:text-7xl font-bold leading-[0.98] text-slate-950 dark:text-zinc-50;
  font-family: var(--vn-font-display);
}

.hero-accent {
  @apply block text-blue-600 dark:text-blue-400;
}

.hero-summary {
  @apply max-w-xl text-pretty text-lg sm:text-xl leading-relaxed text-slate-600 dark:text-zinc-300 max-xl:mx-auto;
}

.hero-actions {
  @apply mt-10 flex flex-wrap gap-3 max-xl:justify-center;
}

.hero-proof {
  @apply mt-12 grid max-w-xl grid-cols-3 border-y border-slate-200 py-5 text-left dark:border-zinc-700 max-xl:mx-auto;
}

.hero-proof div {
  @apply px-5 first:pl-0 last:pr-0;
}

.hero-proof dt {
  @apply text-sm font-bold text-slate-950 dark:text-zinc-50;
}

.hero-proof dd {
  @apply mt-1 text-xs text-slate-500 dark:text-zinc-400;
}

.community-heading {
  @apply flex items-end justify-between gap-8;
}

.community-heading :deep(.section-subtitle) {
  @apply mb-0;
}

.community-submit {
  @apply mb-1 inline-flex shrink-0 items-center gap-2 rounded-full border border-slate-300 bg-white px-5 py-3 text-sm font-semibold text-slate-950 no-underline;
  @apply dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-50;
  transition: transform 160ms ease-out, border-color 160ms ease-out;
}

.community-submit:hover {
  @apply border-blue-600;
  transform: translateY(-2px);
}

.community-submit:focus-visible {
  @apply outline-2 outline-offset-2 outline-blue-600;
}

@media (max-width: 767px) {
  .hero-proof {
    @apply text-center;
  }

  .hero-proof div {
    @apply px-2 first:pl-0 last:pr-0;
  }

  .community-heading {
    @apply items-start flex-col;
  }
}
</style>
