<script setup lang="ts">
import { Icon } from '@iconify/vue';
import Badge from './components/Badge.vue';
import BentoGrid from './components/BentoGrid.vue';
import CodePreview from './components/CodePreview.vue';
import CtaButton from './components/CtaButton.vue';
import CtaSection from './components/CtaSection.vue';
import DemoFrame from './components/DemoFrame.vue';
import FeatureCard from './components/FeatureCard.vue';
import FeatureSection from './components/FeatureSection.vue';
import FloatingNodes from './components/FloatingNodes.vue';
import FlutterBrand from './components/FlutterBrand.vue';
import GridBackground from './components/GridBackground.vue';
import HeroSection from './components/HeroSection.vue';
import MarqueeGroup from './components/MarqueeGroup.vue';
import Section from './components/Section.vue';
import SectionConnector from './components/SectionConnector.vue';
import SectionHeader from './components/SectionHeader.vue';
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
      'Straight Lines',
      'Smooth Step Lines',
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
      'Custom Markers',
      'Gradient Flow',
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
      'JSON Serialization',
      'Reactive State',
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
</script>

<template>
  <div class="min-h-screen relative overflow-x-hidden">
    <!-- Canvas-based Grid Background with blinking cells -->
    <GridBackground color="blue" :blinkCells="heroBlinkCells" />

    <!-- Decorative floating nodes -->
    <FloatingNodes />

    <!-- Hero Section -->
    <HeroSection>
      <template #text>
        <Badge icon="simple-icons:flutter" color="blue"
          >Built for Flutter</Badge
        >
        <h1 class="hero-title">
          <span class="block text-5xl sm:text-6xl lg:text-7xl mb-2"
            >Visualize any</span
          >
          <WordFlipper :words="flipperWords" :interval="1250" />
        </h1>
        <p
          class="text-xl font-medium text-slate-600 dark:text-zinc-300 leading-relaxed max-w-lg hero-animate-3 opacity-0 max-lg:mx-auto"
        >
          A flexible, high-performance node-based flow editor for
          <FlutterBrand />. Build workflow editors, visual programming
          interfaces, and interactive diagrams.
        </p>
        <div
          class="flex gap-4 flex-wrap hero-animate-4 opacity-0 max-lg:justify-center mt-12"
        >
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
      </template>

      <template #visual>
        <DemoFrame url="flow.demo.vyuh.tech" title="Vyuh Node Flow Demo" />
      </template>
    </HeroSection>

    <!-- Code Preview Section -->
    <Section first background size="sm">
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
    </Section>

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
        :reverse="index % 2 === 1"
      />
    </Section>

    <!-- Capabilities Grid -->
    <Section background>
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
    <Section background>
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
          layout="horizontal"
        />
      </div>
    </Section>

    <!-- CTA Section -->
    <CtaSection
      badge="Ready"
      badge-icon="ph:rocket-launch-fill"
      badge-color="amber"
      title="Ready to Create?"
      subtitle="Join developers building next-generation visual editors with Flutter. Production-ready, fully typed, and beautifully designed."
      :primary-action="{
        href: '/docs/getting-started/installation',
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

/* Hero title styling - kept here as it's page-specific */
.hero-title {
  @apply text-4xl sm:text-5xl lg:text-6xl font-black leading-tight mb-6 text-slate-900 dark:text-zinc-100 tracking-tight;
  font-family: var(--vn-font-display);
  animation: fadeSlideUp 0.8s var(--vn-ease-out) 0.2s forwards;
  @apply opacity-0;
}

/* WordFlipper text one notch smaller */
.hero-title .word-flipper {
  @apply text-3xl sm:text-4xl lg:text-5xl;
}

/* Staggered animation delays */
.hero-animate-3 {
  animation: fadeSlideUp 0.8s var(--vn-ease-out) 0.3s forwards;
}

.hero-animate-4 {
  animation: fadeSlideUp 0.8s var(--vn-ease-out) 0.4s forwards;
}

@keyframes fadeSlideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
