<script setup lang="ts">
import { Icon } from '@iconify/vue';
import SectionHeader from './components/SectionHeader.vue';
import FeatureCard from './components/FeatureCard.vue';
import DetailRow from './components/DetailRow.vue';
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
  'MIND FLOW',
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
    theme: NodeFlowTheme.light, // [!code focus]
    nodeBuilder: (context, node) => Container(
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
    media: {
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
    media: {
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
    media: {
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
    media: {
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
    media: {
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
  <div class="custom-home">
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
          <div class="badge badge-blue">
            <Icon icon="simple-icons:flutter" />
            <span>Built for Flutter</span>
          </div>
          <h1 class="hero-title">
            <span class="hero-title-static">Visualize any</span>
            <WordFlipper :words="flipperWords" :interval="1500" />
          </h1>
          <p class="hero-subtitle">
            A flexible, high-performance node-based flow editor for
            <span class="flutter-brand"
              ><Icon icon="simple-icons:flutter" /> Flutter</span
            >. Build workflow editors, visual programming interfaces, and
            interactive diagrams.
          </p>
          <div class="hero-actions">
            <a
              href="/docs/getting-started/installation"
              class="hero-btn hero-btn-primary hero-btn-lg"
            >
              Get Started <Icon icon="ph:arrow-right-bold" />
            </a>
            <a
              href="https://flow.demo.vyuh.tech"
              class="hero-btn hero-btn-secondary hero-btn-lg"
              target="_blank"
            >
              <Icon icon="ph:play-fill" /> Live Demo
            </a>
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
          badge-icon="ph:terminal-fill"
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
    <section class="detail-section">
      <div class="detail-container">
        <DetailRow
          v-for="(feature, index) in detailedFeatures"
          :key="index"
          :tag="feature.tag"
          :tag-icon="feature.icon"
          :tag-color="feature.tagColor"
          :title="feature.title"
          :subtitle="feature.subtitle"
          :bullets="feature.bullets"
          :media="feature.media"
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
        badge-icon="ph:infinity-fill"
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
