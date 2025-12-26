import {
  Zap,
  Palette,
  Sparkles,
  Map,
  FileJson,
  Plug,
  ShieldCheck,
  Box,
  Activity,
  MessageSquare,
  Group,
} from 'lucide-react';
import { SectionHeader } from '@/components/section-header';
import { BentoGrid, BentoCard } from '@/components/bento-grid';

const features = [
  {
    Icon: Zap,
    name: 'High Performance',
    description:
      'Rendering hundreds of nodes at 60fps with optimized virtualization.',
    href: '/docs/core-concepts/performance',
    cta: 'Learn more',
    className: 'lg:row-start-1 lg:row-end-2 lg:col-start-1 lg:col-end-3',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-amber-100 to-transparent dark:from-amber-900/20 opacity-50" />
    ),
  },
  {
    Icon: Palette,
    name: 'Custom Themes',
    description: 'Style every aspect of your graph to match your brand identity.',
    href: '/docs/theming',
    cta: 'Explore theming',
    className: 'lg:col-start-3 lg:col-end-4 lg:row-start-1 lg:row-end-2',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-purple-100 to-transparent dark:from-purple-900/20 opacity-50" />
    ),
  },
  {
    Icon: Plug,
    name: 'Smart Connections',
    description: 'Auto-routing, validation, and multiple path styles included.',
    href: '/docs/core-concepts/connections',
    cta: 'See connections',
    className: 'lg:col-start-1 lg:col-end-2 lg:row-start-2 lg:row-end-3',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-blue-100 to-transparent dark:from-blue-900/20 opacity-50" />
    ),
  },
  {
    Icon: Box,
    name: 'Custom Nodes',
    description:
      'Create any node UI you can imagine using standard Flutter widgets.',
    href: '/docs/core-concepts/custom-nodes',
    cta: 'Build nodes',
    className: 'lg:col-start-2 lg:col-end-4 lg:row-start-2 lg:row-end-3',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-green-100 to-transparent dark:from-green-900/20 opacity-50" />
    ),
  },
  {
    Icon: Map,
    name: 'MiniMap',
    description: 'Navigate huge graphs effortlessly with real-time overview.',
    href: '/docs/components/minimap',
    cta: 'Try minimap',
    className: 'lg:col-start-1 lg:col-end-2 lg:row-start-3 lg:row-end-4',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-teal-100 to-transparent dark:from-teal-900/20 opacity-50" />
    ),
  },
  {
    Icon: ShieldCheck,
    name: 'Type-Safe Data',
    description: 'Generic type support for strongly-typed node data.',
    href: '/docs/core-concepts/node-data',
    cta: 'See types',
    className: 'lg:col-start-2 lg:col-end-3 lg:row-start-3 lg:row-end-4',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-emerald-100 to-transparent dark:from-emerald-900/20 opacity-50" />
    ),
  },
  {
    Icon: FileJson,
    name: 'Serialization',
    description:
      'Save and load flows from JSON with type-safe deserialization.',
    href: '/docs/core-concepts/serialization',
    cta: 'Learn JSON',
    className: 'lg:col-start-3 lg:col-end-4 lg:row-start-3 lg:row-end-4',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-orange-100 to-transparent dark:from-orange-900/20 opacity-50" />
    ),
  },
  {
    Icon: Sparkles,
    name: 'Connection Effects',
    description: 'Animated effects like FlowingDash, Particle, and Pulse.',
    href: '/docs/core-concepts/connection-effects',
    cta: 'View effects',
    className: 'lg:col-start-1 lg:col-end-2 lg:row-start-4 lg:row-end-5',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-pink-100 to-transparent dark:from-pink-900/20 opacity-50" />
    ),
  },
  {
    Icon: Activity,
    name: 'Event System',
    description:
      'Rich event callbacks for user interactions and state changes.',
    href: '/docs/advanced/events',
    cta: 'Handle events',
    className: 'lg:col-start-2 lg:col-end-4 lg:row-start-4 lg:row-end-5',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-indigo-100 to-transparent dark:from-indigo-900/20 opacity-50" />
    ),
  },
  {
    Icon: MessageSquare,
    name: 'Annotations',
    description:
      'Add sticky notes, comments, and documentation directly on your canvas.',
    href: '/docs/advanced/annotations',
    cta: 'Add notes',
    className: 'lg:col-start-1 lg:col-end-3 lg:row-start-5 lg:row-end-6',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-yellow-100 to-transparent dark:from-yellow-900/20 opacity-50" />
    ),
  },
  {
    Icon: Group,
    name: 'Group Nodes',
    description:
      'Organize complex flows with collapsible groups and nested hierarchies.',
    href: '/docs/advanced/group-nodes',
    cta: 'Learn grouping',
    className: 'lg:col-start-3 lg:col-end-4 lg:row-start-5 lg:row-end-6',
    background: (
      <div className="absolute inset-0 bg-gradient-to-br from-cyan-100 to-transparent dark:from-cyan-900/20 opacity-50" />
    ),
  },
];

export function BentoGridSection() {
  return (
    <section className="py-32 relative z-20">
      <div className="container px-4 md:px-6 mx-auto">
        <div className="mb-20">
          <SectionHeader
            icon={<Sparkles className="w-5 h-5" />}
            tag="Features"
            tagColor="purple"
            title="Everything You Need"
            subtitle="A complete toolkit for building professional node-based interfaces."
          />
        </div>
        <BentoGrid className="lg:grid-rows-5">
          {features.map((feature) => (
            <BentoCard key={feature.name} {...feature} />
          ))}
        </BentoGrid>
      </div>
    </section>
  );
}
