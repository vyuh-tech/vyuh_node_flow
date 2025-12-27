<script setup lang="ts">
import { Icon } from '@iconify/vue';
import Badge from './components/Badge.vue';
import CtaButton from './components/CtaButton.vue';
import SectionHeader from './components/SectionHeader.vue';
import FeatureCard from './components/FeatureCard.vue';
import FeatureSection from './components/FeatureSection.vue';
import FlutterBrand from './components/FlutterBrand.vue';
import GridBackground from './components/GridBackground.vue';
import MarqueeSection from './components/MarqueeSection.vue';
import CodePreview from './components/CodePreview.vue';
import UseCaseCard from './components/UseCaseCard.vue';
import SiteFooter from './components/SiteFooter.vue';
import WordFlipper from './components/WordFlipper.vue';

// Full words for the flipper
const flipperWords = [
  'WORK FLOW',
  'DATA FLOW',
  'TASK FLOW',
  'PROCESS FLOW',
  'NODE FLOW',
  'CONTENT FLOW',
  'STATE FLOW',
  'CODE FLOW',
];

// Code example for the Quick Start section
const codeExample = `import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class SimpleFlowEditor extends StatefulWidget {
  @override
  State<SimpleFlowEditor> createState() => _SimpleFlowEditorState();
}

class _SimpleFlowEditorState extends State<SimpleFlowEditor> {
  // Create controller with initial nodes
  late final controller = NodeFlowController<String>( // [!code focus]
    nodes: [
      Node<String>(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(150, 60),
        data: 'Input Node',
        outputPorts: const [Port(id: 'out')],
      ),
      Node<String>(
        id: 'node-2',
        position: const Offset(400, 100),
        size: const Size(150, 60),
        data: 'Output Node',
        inputPorts: const [Port(id: 'in')],
      ),
    ],
    connections: [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'node-1', sourcePortId: 'out',
        targetNodeId: 'node-2', targetPortId: 'in',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => NodeFlowEditor<String>( // [!code focus]
    controller: controller, // [!code focus]
    theme: NodeFlowTheme.light,
    nodeBuilder: (context, node) => Container( // [!code focus]
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: Text(node.data)),
    ),
  );
}`;

// Code markers for tooltips
const codeMarkers = [
  {
    line: 11,
    title: 'NodeFlowController',
    description:
      'The main controller that manages nodes and connections. Provides programmatic control over the editor, including adding/removing nodes, creating connections, and handling selection.',
  },
  {
    line: 38,
    title: 'NodeFlowEditor Widget',
    description:
      'The Flutter widget that renders the visual editor. Features include pan & zoom, node dragging, connection creation, selection, and customizable theming.',
  },
  {
    line: 41,
    title: 'Custom Node Builder',
    description:
      'Create custom nodes and appearances using any Flutter widget. Full control over node styling, content, and interactions.',
  },
];

// Marquee content
const marqueeBlue = [
  'Annotations & Sticky Notes',
  'Keyboard Shortcuts',
  'Read-Only Viewer',
  'Multi-touch Gestures',
  'Undo/Redo Support',
  'Auto Pan',
  'Bezier Curves',
  'Straight Lines',
];

const marqueePurple = [
  'Dark & Light Themes',
  'Snap to Grid',
  'Zoom Controls',
  'Drag Selection',
  'Viewport Animations',
  'Infinite Canvas',
  'Custom Markers',
  'Gradient Flow',
];

const marqueeTeal = [
  'Port Validation',
  'Event Callbacks',
  'Viewport Controls',
  'Grid Styles',
  'Node Resizing',
  'Connection Effects',
  'JSON Serialization',
  'Reactive State',
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
    desc: 'Create any node UI using standard Flutter widgets with full control over appearance.',
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
    title: 'Type-Safe Data',
    desc: 'Generic type support for strongly-typed node data with Dart pattern matching.',
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
    desc: 'Create collapsible groups and nested hierarchies for complex workflows.',
    color: 'teal' as const,
  },
  {
    icon: 'ph:hand-pointing-fill',
    title: 'Touch Optimized',
    desc: 'Full multi-touch support with pinch zoom, pan gestures, and haptic feedback ready.',
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
    placeholder: {
      type: 'video' as const,
      title: 'Type-Safe API Demo',
      description:
        'Screen recording showing IDE autocomplete, type inference, and compile-time error catching while building a flow',
    },
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
    placeholder: {
      type: 'video' as const,
      title: 'Theme Switching',
      description:
        'Animated transition between light/dark themes and custom brand colors applied to nodes and connections',
    },
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
    placeholder: {
      type: 'video' as const,
      title: 'Connection Effects Showcase',
      description:
        'Loop showing FlowingDash, Particle, Pulse, and Rainbow effects on connections with smooth transitions',
    },
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
    placeholder: {
      type: 'video' as const,
      title: 'Custom Node Builder',
      description:
        'Walkthrough of creating a custom node with form inputs, dropdowns, and real-time preview inside the node',
    },
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
    placeholder: {
      type: 'video' as const,
      title: 'Performance Stress Test',
      description:
        'Demo showing smooth 60fps interaction with 1000+ nodes, zooming, panning, and selecting',
    },
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

const heroBlinkCells = generateBlinkCells(20, 42);
const ctaBlinkCells = generateBlinkCells(15, 73);
</script>

<template>
  <div class="home-page">
    <!-- Shared Grid Background -->
    <GridBackground color="blue" />

    <!-- Hero Section -->
    <section class="hero-section">
      <div class="hero-background">
        <svg class="hero-grid-svg" width="100%" height="100%">
          <defs>
            <pattern
              id="smallGrid"
              width="40"
              height="40"
              patternUnits="userSpaceOnUse"
            >
              <path
                d="M 40 0 L 0 0 0 40"
                fill="none"
                stroke="rgba(37, 99, 235, 0.08)"
                stroke-width="1"
              />
            </pattern>
            <pattern
              id="largeGrid"
              width="200"
              height="200"
              patternUnits="userSpaceOnUse"
            >
              <rect width="200" height="200" fill="url(#smallGrid)" />
              <path
                d="M 200 0 L 0 0 0 200"
                fill="none"
                stroke="rgba(37, 99, 235, 0.15)"
                stroke-width="1"
              />
            </pattern>
            <radialGradient id="gridFade" cx="50%" cy="50%" r="70%">
              <stop offset="0%" stop-color="white" stop-opacity="1" />
              <stop offset="100%" stop-color="white" stop-opacity="0" />
            </radialGradient>
            <mask id="gridMask">
              <rect width="100%" height="100%" fill="url(#gridFade)" />
            </mask>
          </defs>
          <rect
            width="100%"
            height="100%"
            fill="url(#largeGrid)"
            mask="url(#gridMask)"
          />
        </svg>
        <div class="hero-grid-blink">
          <div
            class="blink-cell"
            v-for="(cell, n) in heroBlinkCells"
            :key="n"
            :style="{
              left: `${cell.left}px`,
              top: `${cell.top}px`,
              animationDelay: `${cell.delay}s`,
              animationDuration: `${cell.duration}s`,
            }"
          />
        </div>
        <div class="hero-blur hero-blur-blue" />
        <div class="hero-blur hero-blur-purple" />
        <div class="hero-blur hero-blur-teal" />
      </div>

      <div class="hero-content">
        <div class="hero-text">
          <Badge icon="simple-icons:flutter" color="blue"
            >Built for Flutter</Badge
          >
          <h1 class="hero-title">
            <span class="hero-title-static">Visualize any</span>
            <WordFlipper :words="flipperWords" :interval="1500" />
          </h1>
          <p class="hero-subtitle">
            A flexible, high-performance node-based flow editor for
            <FlutterBrand />. Build workflow editors, visual programming
            interfaces, and interactive diagrams.
          </p>
          <div class="hero-actions">
            <CtaButton
              href="/docs/getting-started/installation"
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
        </div>

        <div class="hero-visual">
          <div class="demo-frame-wrapper">
            <div class="demo-frame-header">
              <span class="demo-frame-dot demo-frame-dot-red" />
              <span class="demo-frame-dot demo-frame-dot-yellow" />
              <span class="demo-frame-dot demo-frame-dot-green" />
              <a
                href="https://flow.demo.vyuh.tech"
                target="_blank"
                class="demo-frame-url"
                >flow.demo.vyuh.tech</a
              >
            </div>
            <iframe
              src="https://flow.demo.vyuh.tech"
              class="demo-iframe"
              title="Vyuh Node Flow Demo"
              loading="lazy"
            />
          </div>
        </div>
      </div>
    </section>

    <!-- Code Preview Section -->
    <section class="code-section">
      <div class="code-container">
        <SectionHeader
          badge="Quick Start"
          badge-icon="simple-icons:flutter"
          badge-color="blue"
          title="Simple & Intuitive API"
        />
        <CodePreview
          :code="codeExample"
          filename="simple_flow_editor.dart"
          :markers="codeMarkers"
        />
      </div>
    </section>

    <!-- Detailed Feature Sections -->
    <section class="feature-sections">
      <div class="feature-sections-container">
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
          :reverse="index % 2 === 1"
        />
      </div>
    </section>

    <!-- Capabilities Grid -->
    <section class="features-section">
      <SectionHeader
        badge="Capabilities"
        badge-icon="ph:squares-four-fill"
        badge-color="purple"
        title="Everything You Need"
        subtitle="Build sophisticated visual editors with a complete toolkit designed for Flutter."
        centered
      />
      <div class="features-grid">
        <FeatureCard
          v-for="(cap, index) in capabilities"
          :key="index"
          :icon="cap.icon"
          :title="cap.title"
          :description="cap.desc"
          :color="cap.color"
        />
      </div>
    </section>

    <!-- Marquee -->
    <section class="marquee-section">
      <MarqueeSection :items="marqueeBlue" color="blue" />
      <MarqueeSection :items="marqueePurple" color="purple" reverse />
      <MarqueeSection :items="marqueeTeal" color="teal" />
    </section>

    <!-- Use Cases Section -->
    <section class="use-cases-section">
      <SectionHeader
        badge="Infinite Possibilities"
        badge-icon="ph:infinity"
        badge-color="teal"
        title="Build Anything"
        subtitle="From simple diagrams to complex visual programming environments, Vyuh Node Flow adapts to your needs."
        centered
      />
      <div class="use-cases-grid">
        <UseCaseCard
          v-for="(useCase, index) in useCases"
          :key="index"
          :icon="useCase.icon"
          :title="useCase.title"
          :description="useCase.desc"
          :color="useCase.color"
        />
      </div>
    </section>

    <!-- CTA Section -->
    <section class="cta-section">
      <svg class="cta-grid-svg" width="100%" height="100%">
        <defs>
          <pattern
            id="ctaSmallGrid"
            width="40"
            height="40"
            patternUnits="userSpaceOnUse"
          >
            <path
              d="M 40 0 L 0 0 0 40"
              fill="none"
              stroke="rgba(245, 158, 11, 0.12)"
              stroke-width="1"
            />
          </pattern>
          <pattern
            id="ctaLargeGrid"
            width="200"
            height="200"
            patternUnits="userSpaceOnUse"
          >
            <rect width="200" height="200" fill="url(#ctaSmallGrid)" />
            <path
              d="M 200 0 L 0 0 0 200"
              fill="none"
              stroke="rgba(245, 158, 11, 0.25)"
              stroke-width="1"
            />
          </pattern>
          <radialGradient id="ctaGridFade" cx="50%" cy="50%" r="70%">
            <stop offset="0%" stop-color="white" stop-opacity="1" />
            <stop offset="100%" stop-color="white" stop-opacity="0" />
          </radialGradient>
          <mask id="ctaGridMask">
            <rect width="100%" height="100%" fill="url(#ctaGridFade)" />
          </mask>
        </defs>
        <rect
          width="100%"
          height="100%"
          fill="url(#ctaLargeGrid)"
          mask="url(#ctaGridMask)"
        />
      </svg>
      <div class="cta-grid-blink">
        <div
          class="blink-cell blink-cell-amber"
          v-for="(cell, n) in ctaBlinkCells"
          :key="n"
          :style="{
            left: `${cell.left}px`,
            top: `${cell.top}px`,
            animationDelay: `${cell.delay}s`,
            animationDuration: `${cell.duration}s`,
          }"
        />
      </div>
      <div class="cta-blur cta-blur-blue" />
      <div class="cta-blur cta-blur-purple" />
      <div class="cta-content">
        <SectionHeader
          badge="Ready"
          badge-icon="ph:rocket-launch-fill"
          badge-color="amber"
          title="Ready to Create?"
          centered
          large-title
        />
        <p class="cta-subtitle">
          Join developers building next-generation visual editors with Flutter.
          Production-ready, fully typed, and beautifully designed.
        </p>
        <div class="cta-actions">
          <a
            href="/docs/getting-started/installation"
            class="hero-btn hero-btn-primary hero-btn-lg"
          >
            <Icon icon="ph:book-open-fill" /> Read the Docs
          </a>
          <a
            href="https://pub.dev/packages/vyuh_node_flow"
            class="hero-btn hero-btn-secondary hero-btn-lg"
            target="_blank"
          >
            <Icon icon="simple-icons:dart" /> View on pub.dev
          </a>
          <a
            href="https://github.com/vyuh-tech/vyuh_node_flow"
            class="hero-btn hero-btn-secondary hero-btn-lg"
            target="_blank"
          >
            <Icon icon="ph:github-logo-fill" /> Star on GitHub
          </a>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <SiteFooter />
  </div>
</template>

<style>
@reference "./style.css";

/* ═══════════════════════════════════════════════════════════════════
   CUSTOM HOME PAGE
   ═══════════════════════════════════════════════════════════════════ */

.home-page {
  @apply min-h-screen relative overflow-x-hidden;
  /* No solid background - let the grid show through */
}

/* ═══════════════════════════════════════════════════════════════════
   HERO SECTION
   ═══════════════════════════════════════════════════════════════════ */

.hero-section {
  @apply relative min-h-screen flex items-center justify-center py-10 px-6 overflow-hidden;
}

.hero-background {
  @apply absolute inset-0 z-0;
}

.hero-grid-svg {
  @apply absolute inset-0 w-full h-full;
}

.hero-grid-blink {
  @apply fixed inset-0 pointer-events-none z-0;
}

.blink-cell {
  @apply absolute w-10 h-10 bg-blue-500/10 dark:bg-blue-400/20 rounded-sm;
  animation: cellBlink 6s ease-in-out infinite;
}

.blink-cell-amber {
  @apply bg-amber-500/10 dark:bg-amber-400/20;
}

@keyframes cellBlink {
  0%, 100% { opacity: 0; transform: scale(0.8); }
  50% { opacity: 1; transform: scale(1); }
}

.hero-blur {
  @apply absolute rounded-full;
  filter: blur(120px);
}

.hero-blur-blue {
  @apply w-[600px] h-[600px] bg-blue-500 -top-48 -left-24 opacity-15 dark:opacity-25;
}

.hero-blur-purple {
  @apply w-[500px] h-[500px] bg-violet-500 top-24 -right-36 opacity-12 dark:opacity-20;
}

.hero-blur-teal {
  @apply w-[400px] h-[400px] bg-teal-500 -bottom-24 left-1/3 opacity-10 dark:opacity-18;
}

.hero-content {
  @apply relative z-10 max-w-7xl w-full grid lg:grid-cols-[1fr_1.4fr] gap-16 items-center;
}

@media (max-width: 1100px) {
  .hero-content {
    @apply grid-cols-1 text-center;
  }
}

.hero-text {
  animation: fadeSlideUp 0.8s var(--vn-ease-out) forwards;
  @apply opacity-0;
}

@keyframes fadeSlideUp {
  from { opacity: 0; transform: translateY(30px); }
  to { opacity: 1; transform: translateY(0); }
}

.hero-title {
  @apply text-4xl sm:text-5xl lg:text-6xl font-black leading-tight mb-6 text-slate-900 dark:text-zinc-100 tracking-tight;
  font-family: var(--vn-font-display);
  animation: fadeSlideUp 0.8s var(--vn-ease-out) 0.2s forwards;
  @apply opacity-0;
}

.hero-title-static {
  @apply block text-5xl sm:text-6xl lg:text-7xl;
}

/* WordFlipper text one notch smaller to prevent overflow */
.hero-title .word-flipper {
  @apply text-3xl sm:text-4xl lg:text-5xl;
}

.hero-subtitle {
  @apply text-xl font-medium text-slate-600 dark:text-zinc-300 leading-relaxed mb-10 max-w-lg;
  animation: fadeSlideUp 0.8s var(--vn-ease-out) 0.3s forwards;
  @apply opacity-0;
}

@media (max-width: 1100px) {
  .hero-subtitle {
    @apply mx-auto;
  }
}

.hero-actions {
  @apply flex gap-4 flex-wrap;
  animation: fadeSlideUp 0.8s var(--vn-ease-out) 0.4s forwards;
  @apply opacity-0;
}

@media (max-width: 1100px) {
  .hero-actions {
    @apply justify-center;
  }
}

/* ═══════════════════════════════════════════════════════════════════
   DEMO FRAME
   ═══════════════════════════════════════════════════════════════════ */

.hero-visual {
  @apply relative;
  animation: fadeSlideUp 0.8s var(--vn-ease-out) 0.5s forwards;
  @apply opacity-0;
}

@media (max-width: 1100px) {
  .hero-visual {
    @apply max-w-full;
  }
}

.demo-frame-wrapper {
  @apply relative rounded-lg overflow-hidden border border-slate-200/50 dark:border-zinc-600/50 bg-white dark:bg-zinc-800;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.1), 0 0 60px rgba(139, 92, 246, 0.15);
}

.demo-frame-header {
  @apply flex items-center gap-1.5 px-3 py-2 bg-slate-100 dark:bg-zinc-700 border-b border-slate-200 dark:border-zinc-600;
}

.demo-frame-dot {
  @apply w-2 h-2 rounded-full;
}

.demo-frame-dot-red { @apply bg-red-500; }
.demo-frame-dot-yellow { @apply bg-yellow-500; }
.demo-frame-dot-green { @apply bg-green-500; }

.demo-frame-url {
  @apply flex-1 ml-2 px-2.5 py-1 bg-white dark:bg-zinc-800 rounded-md text-xs text-slate-400 dark:text-zinc-500 no-underline transition-colors;
  font-family: var(--vn-font-mono);
}

.demo-frame-url:hover {
  @apply text-blue-600 bg-blue-600/10 dark:text-blue-400 dark:bg-blue-400/10;
}

.demo-iframe {
  @apply w-full h-[520px] border-none bg-white;
}

@media (max-width: 767px) {
  .demo-iframe {
    @apply h-[400px];
  }
}

/* ═══════════════════════════════════════════════════════════════════
   CODE SECTION
   ═══════════════════════════════════════════════════════════════════ */

.code-section {
  @apply relative py-24 px-6;
}

.code-container {
  @apply max-w-4xl mx-auto;
}

/* ═══════════════════════════════════════════════════════════════════
   FEATURES SECTION
   ═══════════════════════════════════════════════════════════════════ */

.features-section {
  @apply relative py-24 px-6;
}

.features-grid {
  @apply grid gap-6 max-w-7xl mx-auto;
  grid-template-columns: repeat(5, 1fr);
}

/* Bento grid layout */
.feature-card:nth-child(1) { grid-column: span 2; }
.feature-card:nth-child(2) { grid-column: span 2; }
.feature-card:nth-child(3) { grid-column: span 1; }
.feature-card:nth-child(4) { grid-column: span 1; }
.feature-card:nth-child(5) { grid-column: span 2; }
.feature-card:nth-child(6) { grid-column: span 2; }
.feature-card:nth-child(7) { grid-column: span 2; }
.feature-card:nth-child(8) { grid-column: span 1; }
.feature-card:nth-child(9) { grid-column: span 2; }
.feature-card:nth-child(10) { grid-column: span 2; }
.feature-card:nth-child(11) { grid-column: span 1; }
.feature-card:nth-child(12) { grid-column: span 2; }

@media (max-width: 1100px) and (min-width: 768px) {
  .features-grid { grid-template-columns: repeat(3, 1fr); }
  .feature-card:nth-child(4n+1) { grid-column: span 2; }
  .feature-card:nth-child(4n+2) { grid-column: span 1; }
  .feature-card:nth-child(4n+3) { grid-column: span 1; }
  .feature-card:nth-child(4n) { grid-column: span 2; }
}

@media (max-width: 767px) {
  .features-grid { @apply grid-cols-1; }
  .feature-card:nth-child(n) { grid-column: span 1; }
}

/* ═══════════════════════════════════════════════════════════════════
   FEATURE SECTIONS
   ═══════════════════════════════════════════════════════════════════ */

.feature-sections {
  @apply py-16 px-6;
}

.feature-sections-container {
  @apply max-w-6xl mx-auto;
}

/* ═══════════════════════════════════════════════════════════════════
   MARQUEE SECTION
   ═══════════════════════════════════════════════════════════════════ */

.marquee-section {
  @apply py-10 overflow-hidden;
  @apply bg-white/70 dark:bg-zinc-800/50;
  @apply backdrop-blur-md;
}

/* ═══════════════════════════════════════════════════════════════════
   USE CASES SECTION
   ═══════════════════════════════════════════════════════════════════ */

.use-cases-section {
  @apply relative py-24 px-6;
}

.use-cases-grid {
  @apply grid gap-6 max-w-6xl mx-auto;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
}

/* ═══════════════════════════════════════════════════════════════════
   CTA SECTION
   ═══════════════════════════════════════════════════════════════════ */

.cta-section {
  @apply relative py-32 px-6 text-center overflow-hidden;
}

.cta-grid-svg {
  @apply absolute inset-0 w-full h-full z-0;
}

.cta-grid-blink {
  @apply absolute inset-0 pointer-events-none z-0;
}

.cta-blur {
  @apply absolute rounded-full;
  filter: blur(150px);
}

.cta-blur-blue {
  @apply w-[600px] h-[600px] bg-blue-500 -top-48 left-[10%] opacity-12 dark:opacity-20;
}

.cta-blur-purple {
  @apply w-[500px] h-[500px] bg-violet-500 -bottom-36 right-[10%] opacity-10 dark:opacity-18;
}

.cta-content {
  @apply relative z-10 max-w-3xl mx-auto;
}

.cta-subtitle {
  @apply text-xl font-medium text-slate-600 dark:text-zinc-300 leading-relaxed mb-10;
}

.cta-actions {
  @apply flex justify-center gap-4 flex-wrap;
}
</style>
