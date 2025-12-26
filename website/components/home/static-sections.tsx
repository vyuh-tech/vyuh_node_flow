import Link from 'next/link';
import Image from 'next/image';
import {
  ArrowRight,
  Cpu,
  Type,
  Zap,
  GitBranch,
  Sparkles,
  Map,
  FileJson,
  ShieldCheck,
  Play,
  Code2,
  Share2,
  Workflow,
  MousePointer2,
  Smartphone,
} from 'lucide-react';
import { SiFlutter } from 'react-icons/si';
import { SectionHeader } from '@/components/section-header';
import { CodeWindow } from '@/components/code-window';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: (string | undefined | null | false)[]) {
  return twMerge(clsx(inputs));
}

// Marquee content
const MARQUEE_ROW_1 = [
  'Annotations & Sticky Notes',
  'Keyboard Shortcuts',
  'Read-Only Viewer',
  'Multi-touch Gestures',
  'Undo/Redo Support',
  'Auto Pan',
  'Bezier Curves',
  'Straight Lines',
];

const MARQUEE_ROW_2 = [
  'Dark & Light Themes',
  'Snap to Grid',
  'Zoom Controls',
  'Drag Selection',
  'Box Selection',
  'Infinite Canvas',
  'Custom Markers',
  'Gradient Flow',
];

const MARQUEE_ROW_3 = [
  'Port Validation',
  'Event Callbacks',
  'Viewport Controls',
  'Auto Layout',
  'Node Resizing',
  'Particle Effects',
  'JSON Serialization',
  'Reactive State',
];

const useCases = [
  {
    title: 'Workflow Automation',
    color: 'bg-blue-500',
    icon: GitBranch,
    desc: 'Visual step-by-step logic engines.',
  },
  {
    title: 'IoT Device Managers',
    color: 'bg-emerald-500',
    icon: Cpu,
    desc: 'Real-time device network topologies.',
  },
  {
    title: 'Visual Coding Tools',
    color: 'bg-purple-500',
    icon: Code2,
    desc: 'Custom node-based programming editors.',
  },
  {
    title: 'Chatbot Builders',
    color: 'bg-pink-500',
    icon: Sparkles,
    desc: 'Dialogue tree and response mapping.',
  },
  {
    title: 'Database Design',
    color: 'bg-orange-500',
    icon: FileJson,
    desc: 'Schema visualization and relationship mapping.',
  },
  {
    title: 'Mind Mapping',
    color: 'bg-yellow-500',
    icon: Map,
    desc: 'Infinite canvas for collaborative ideas.',
  },
  {
    title: 'Network Topologies',
    color: 'bg-cyan-500',
    icon: Share2,
    desc: 'Cloud infrastructure visualization.',
  },
  {
    title: 'Circuit Simulators',
    color: 'bg-red-500',
    icon: Zap,
    desc: 'Electronic and logic gate simulation.',
  },
];

function FeatureSection({
  align,
  title,
  description,
  icon,
  image,
  features: featureList,
}: {
  align: 'left' | 'right';
  title: string;
  description: string;
  icon: React.ReactNode;
  image: string;
  features: string[];
}) {
  return (
    <div className="py-24 md:py-40 overflow-hidden">
      <div className="container px-4 md:px-6 mx-auto">
        <div
          className={cn(
            'flex flex-col lg:flex-row items-center gap-12 lg:gap-24',
            align === 'right' ? 'lg:flex-row-reverse' : ''
          )}
        >
          <div className="flex-1">
            <SectionHeader
              icon={icon}
              tag={title}
              title={title}
              subtitle={description}
              features={featureList}
              align="left"
            />
          </div>
          <div className="flex-1 w-full relative perspective-[1500px]">
            <div className="relative rounded-[2.5rem] overflow-hidden shadow-2xl border border-slate-200 dark:border-white/10 bg-white/40 dark:bg-white/5 backdrop-blur-xl group">
              <div className="absolute inset-0 bg-gradient-to-tr from-blue-500/10 to-transparent pointer-events-none z-10" />
              <Image
                src={image}
                alt={title}
                width={800}
                height={600}
                className="w-full h-auto object-cover opacity-90"
                loading="lazy"
                unoptimized
              />
            </div>
            <div
              className={cn(
                'absolute -z-10 w-full h-full top-12 blur-[100px] opacity-25 rounded-full',
                align === 'left' ? '-right-16 bg-blue-500' : '-left-16 bg-purple-500'
              )}
            />
          </div>
        </div>
      </div>
    </div>
  );
}

export function CodeShowcaseSection() {
  return (
    <section className="py-24 relative z-20 overflow-hidden bg-slate-100/50 dark:bg-white/[0.02] border-y border-slate-200 dark:border-white/5">
      <div className="absolute top-0 right-0 w-1/2 h-full bg-blue-500/5 blur-[120px] rounded-full pointer-events-none" />
      <div className="container px-4 md:px-6 mx-auto">
        <div className="flex flex-col lg:flex-row gap-16 items-center">
          <div className="lg:w-1/2">
            <SectionHeader
              align="left"
              icon={<Code2 className="w-5 h-5" />}
              tag="Developer First"
              tagColor="blue"
              title="Declarative & Type-Safe"
              subtitle="Built for Flutter developers who love clean, maintainable code. Define your nodes, connections, and logic in pure Dart with full type safety."
            />
            <div className="mt-10 space-y-6">
              {[
                {
                  icon: Zap,
                  title: 'Reactive State',
                  desc: 'Changes to your data automatically update the graph. No manual redraws needed.',
                  color: 'text-blue-500',
                },
                {
                  icon: ShieldCheck,
                  title: 'Strict Typing',
                  desc: 'Catch errors at compile time with generic node data types.',
                  color: 'text-purple-500',
                },
              ].map((f, i) => (
                <div
                  key={i}
                  className="flex items-start gap-5 p-5 rounded-2xl bg-white dark:bg-white/5 border border-slate-200 dark:border-white/10 shadow-sm backdrop-blur-sm"
                >
                  <div
                    className={cn(
                      'p-3 rounded-xl bg-slate-100 dark:bg-white/5',
                      f.color
                    )}
                  >
                    <f.icon className="w-6 h-6" />
                  </div>
                  <div>
                    <h4 className="font-bold text-slate-900 dark:text-white text-lg">
                      {f.title}
                    </h4>
                    <p className="text-slate-600 dark:text-slate-400 mt-1">
                      {f.desc}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="lg:w-1/2 w-full">
            <CodeWindow />
          </div>
        </div>
      </div>
    </section>
  );
}

export function FeatureDeepDivesSection() {
  return (
    <section className="relative z-20">
      <FeatureSection
        align="right"
        title="Designed for Your Brand"
        description="Don't settle for default styles. Our comprehensive theming system allows you to customize every pixel - from node borders and shadows to connection colors and grid patterns."
        icon={<Type className="w-6 h-6 text-purple-500" />}
        image="/image-2.png"
        features={[
          'Dark & Light mode support out of the box',
          'Granular control over ports, labels, and handles',
          'Custom shapes for endpoints and markers',
        ]}
      />

      <FeatureSection
        align="left"
        title="Fluid Interactions"
        description="Make your flows feel tangible. Connections snap into place, nodes glow on selection, and data flow is visualized with beautiful, performant animations."
        icon={<MousePointer2 className="w-6 h-6 text-blue-500" />}
        image="/connection-effects.gif"
        features={[
          '60fps animations even with complex graphs',
          'Connection effects: FlowingDash, Particles, Pulse, Rainbow',
          'Drag-and-drop with snap-to-port validation',
        ]}
      />

      <FeatureSection
        align="right"
        title="Built for Scale"
        description="Whether you're rendering 10 nodes or 10,000, Vyuh Node Flow maintains buttery smooth performance using efficient rendering techniques and virtualization."
        icon={<Cpu className="w-6 h-6 text-amber-500" />}
        image="/image-1.png"
        features={[
          'Virtualized viewport rendering',
          'Optimized gesture handling',
          'Minimal memory footprint',
        ]}
      />

      <FeatureSection
        align="left"
        title="Touch Optimized"
        description="Designing for mobile? No problem. Our interaction model adapts seamlessly to touch gestures, making it perfect for tablet and phone interfaces."
        icon={<Smartphone className="w-6 h-6 text-green-500" />}
        image="/in-action.gif"
        features={[
          'Multi-touch zoom and pan support',
          'Large touch targets for ports and handles',
          'Haptic feedback integration ready',
        ]}
      />
    </section>
  );
}

export function MarqueeSection() {
  return (
    <section className="py-24 relative overflow-hidden z-20 border-y border-slate-200/50 dark:border-white/5 bg-white/30 dark:bg-black/20 backdrop-blur-md">
      <div className="absolute inset-y-0 left-0 w-48 bg-gradient-to-r from-slate-50/80 dark:from-slate-900/80 to-transparent z-10 pointer-events-none" />
      <div className="absolute inset-y-0 right-0 w-48 bg-gradient-to-l from-slate-50/80 dark:from-slate-900/80 to-transparent z-10 pointer-events-none" />

      <div className="flex flex-col gap-8">
        <div className="flex animate-marquee whitespace-nowrap py-2">
          {[...MARQUEE_ROW_1, ...MARQUEE_ROW_1].map((feature, i) => (
            <div key={i} className="flex items-center">
              <span className="text-xl font-bold text-blue-600/70 dark:text-blue-400/60 cursor-default">
                {feature}
              </span>
              <span className="mx-8 text-blue-500/40 font-black">•</span>
            </div>
          ))}
        </div>

        <div className="flex animate-marquee-reverse whitespace-nowrap py-2">
          {[...MARQUEE_ROW_2, ...MARQUEE_ROW_2].map((feature, i) => (
            <div key={i} className="flex items-center">
              <span className="text-xl font-bold text-purple-600/70 dark:text-purple-400/60 cursor-default">
                {feature}
              </span>
              <span className="mx-8 text-purple-500/40 font-black">•</span>
            </div>
          ))}
        </div>

        <div className="flex animate-marquee-slow whitespace-nowrap py-2">
          {[...MARQUEE_ROW_3, ...MARQUEE_ROW_3].map((feature, i) => (
            <div key={i} className="flex items-center">
              <span className="text-xl font-bold text-teal-600/70 dark:text-teal-400/60 cursor-default">
                {feature}
              </span>
              <span className="mx-8 text-teal-500/40 font-black">•</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export function LiveDemoSection() {
  return (
    <section className="py-40 relative z-20 overflow-hidden">
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-full max-w-6xl bg-blue-500/5 blur-[150px] rounded-full pointer-events-none -z-10" />
      <div className="container px-4 md:px-6 mx-auto">
        <div className="mb-16">
          <SectionHeader
            icon={<Play className="w-5 h-5" />}
            tag="Try It Live"
            tagColor="green"
            title="See It in Action"
            subtitle="Experience the full power of Vyuh Node Flow with our interactive demo."
          />
        </div>
        <div className="relative max-w-6xl mx-auto">
          <div className="rounded-3xl overflow-hidden shadow-2xl bg-slate-900 border border-slate-700">
            <div className="bg-slate-800 px-4 py-3 flex items-center gap-4 border-b border-slate-700">
              <div className="flex gap-1.5">
                <div className="w-3 h-3 rounded-full bg-red-500 shadow-[0_0_8px_#ef4444]" />
                <div className="w-3 h-3 rounded-full bg-yellow-500 shadow-[0_0_8px_#f59e0b]" />
                <div className="w-3 h-3 rounded-full bg-green-500 shadow-[0_0_8px_#10b981]" />
              </div>
              <div className="flex-1 bg-slate-900 rounded-md py-1.5 px-3 text-xs text-slate-400 font-mono text-center">
                https://flow.demo.vyuh.tech
              </div>
            </div>
            <div className="aspect-video relative bg-slate-900 group cursor-pointer overflow-hidden">
              <div className="absolute inset-0 bg-gradient-to-br from-blue-900/20 to-purple-900/20" />
              <div className="absolute inset-0 flex flex-col items-center justify-center z-20 group-hover:scale-105 transition-transform duration-500">
                <div className="w-24 h-24 rounded-full bg-blue-500/20 flex items-center justify-center mb-6 backdrop-blur-sm border border-blue-500/30 group-hover:bg-blue-500/40 group-hover:border-blue-500/50 transition-all">
                  <Play className="w-10 h-10 text-blue-400 fill-blue-400" />
                </div>
                <h3 className="text-3xl font-black font-heading text-white mb-2 drop-shadow-lg">
                  Launch Interactive Demo
                </h3>
                <p className="text-blue-300 font-bold opacity-0 group-hover:opacity-100 transition-opacity">
                  Full Screen Editor Available
                </p>
              </div>
              <a
                href="https://flow.demo.vyuh.tech"
                target="_blank"
                rel="noreferrer"
                className="absolute inset-0 z-30"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

export function UseCasesSection() {
  return (
    <section className="py-40 relative z-20">
      <div className="container px-4 md:px-6 mx-auto">
        <div className="mb-20">
          <SectionHeader
            icon={<Workflow className="w-5 h-5" />}
            tag="Built for Complexity"
            tagColor="amber"
            title="Infinite Use Cases"
            subtitle="From simple logic to complex state machines, Vyuh Node Flow handles it with ease."
          />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {useCases.map((item, i) => (
            <div
              key={i}
              className="group relative overflow-hidden p-8 rounded-3xl border border-slate-200 dark:border-white/10 bg-white/80 dark:bg-white/5 backdrop-blur-lg shadow-xl transition-shadow duration-100 hover:shadow-2xl hover:border-blue-500/20"
            >
              <div
                className={cn(
                  'absolute top-0 right-0 w-32 h-32 -mr-12 -mt-12 rounded-full opacity-10 blur-3xl transition-opacity group-hover:opacity-20',
                  item.color
                )}
              />
              <div className="w-12 h-12 rounded-2xl flex items-center justify-center mb-6 bg-slate-100 dark:bg-white/5 transition-colors group-hover:bg-slate-200 dark:group-hover:bg-white/10">
                <item.icon className="w-6 h-6 text-slate-700 dark:text-slate-300 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors" />
              </div>
              <span className="font-black text-xl text-slate-900 dark:text-slate-100 block mb-2 tracking-normal">
                {item.title}
              </span>
              <p className="text-slate-600 dark:text-slate-400 font-medium text-sm leading-relaxed">
                {item.desc}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export function CTASection() {
  return (
    <section className="py-40 relative overflow-hidden z-20">
      <div className="absolute inset-0 bg-gradient-to-t from-blue-100/50 to-transparent dark:from-blue-950/20 -z-10" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-full max-w-4xl max-h-[400px] bg-blue-500/10 blur-[120px] rounded-full pointer-events-none -z-10" />

      <div className="container px-4 md:px-6 mx-auto text-center">
        <h2 className="text-5xl md:text-8xl font-black font-heading mb-10 text-slate-900 dark:text-white tracking-tight drop-shadow-2xl">
          Ready to create?
        </h2>

        <div className="max-w-4xl mx-auto space-y-8">
          <p className="text-2xl md:text-3xl text-slate-700 dark:text-slate-300 font-bold leading-tight">
            Join developers building the next generation of visual tools with{' '}
            <span className="inline-flex items-baseline font-black text-blue-600 dark:text-blue-400 uppercase tracking-tighter">
              <SiFlutter className="w-6 h-6 md:w-8 md:h-8 mr-1.5" />
              Flutter
            </span>{' '}
            and Vyuh Node Flow.
          </p>

          <div className="flex flex-wrap justify-center gap-x-8 gap-y-4 text-lg font-bold text-slate-500 dark:text-slate-400">
            <div className="flex items-center gap-2">
              <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 shadow-[0_0_10px_#10b981]" />
              <span>Open Source (MIT License)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2.5 h-2.5 rounded-full bg-blue-500 shadow-[0_0_10px_#3b82f6]" />
              <span>Community Driven</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2.5 h-2.5 rounded-full bg-purple-500 shadow-[0_0_10px_#a855f7]" />
              <span>Enterprise Ready</span>
            </div>
          </div>
        </div>

        <div className="mt-16 flex flex-col sm:flex-row gap-8 justify-center items-center">
          <div className="relative group">
            <div className="absolute -inset-[3px] rounded-full bg-gradient-to-r from-blue-600 via-purple-500 to-blue-600 opacity-75 blur-sm group-hover:opacity-100 group-hover:blur-md transition-all duration-200 animate-gradient-x" />
            <div className="absolute -inset-6 rounded-full bg-blue-500/20 blur-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
            <Link
              href="/docs/getting-started"
              className="relative inline-flex items-center justify-center h-20 px-16 rounded-full bg-blue-600 text-white font-black font-heading text-3xl transition-all duration-150 hover:bg-blue-500 hover:scale-105 shadow-2xl shadow-blue-500/40 active:scale-95"
            >
              Get Started Now
              <ArrowRight className="ml-3 h-8 w-8" />
            </Link>
          </div>
        </div>

        <p className="mt-12 text-slate-500 dark:text-slate-500 font-black tracking-widest uppercase text-sm">
          Start building your flows today.
        </p>
      </div>
    </section>
  );
}

export function FooterSection() {
  return (
    <section className="py-16 relative z-20 border-t border-slate-200 dark:border-white/5 bg-slate-50/50 dark:bg-[#020617]/50 backdrop-blur-sm">
      <div className="container px-4 md:px-6 mx-auto text-center">
        <div className="flex flex-wrap justify-center items-center gap-8 text-sm font-medium text-slate-600 dark:text-slate-400">
          <Link
            href="/docs"
            className="hover:text-blue-500 dark:hover:text-blue-400 transition-colors"
          >
            Documentation
          </Link>
          <Link
            href="https://github.com/vyuh-tech/vyuh_node_flow"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-blue-500 dark:hover:text-blue-400 transition-colors"
          >
            GitHub
          </Link>
          <Link
            href="/privacy-policy"
            className="hover:text-blue-500 dark:hover:text-blue-400 transition-colors"
          >
            Privacy Policy
          </Link>
          <Link
            href="/terms-of-service"
            className="hover:text-blue-500 dark:hover:text-blue-400 transition-colors"
          >
            Terms of Service
          </Link>
          <Link
            href="/pro"
            className="font-bold text-blue-600 dark:text-blue-400 hover:underline transition-colors"
          >
            Pro Version
          </Link>
        </div>

        <div className="mt-12 text-slate-500 dark:text-slate-400 text-base font-medium">
          Copyright &copy; {new Date().getFullYear()} Vyuh Technologies Private
          Limited. All rights reserved.
        </div>
      </div>
    </section>
  );
}
