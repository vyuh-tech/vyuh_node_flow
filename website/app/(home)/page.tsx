'use client';

import Link from 'next/link';
import Image from 'next/image';
import React, { useEffect, useState } from 'react';
import {
  ArrowRight,
  Cpu,
  MousePointer2,
  Smartphone,
  Type,
  Zap,
  Palette,
  GitBranch,
  Sparkles,
  Map,
  FileJson,
  Plug,
  ShieldCheck,
  Play,
  Code2,
  Share2,
  Box,
  Layers,
  Activity,
  History,
  Workflow,
  MessageSquare,
  Group,
} from 'lucide-react';
import { SiFlutter } from 'react-icons/si';
import { HeroVisual } from '@/components/hero-visual';
import { GridBackground } from '@/components/grid-background';
import { BlinkingGridBackground } from '@/components/blinking-grid';
import { FloatingOrbs } from '@/components/floating-orbs';
import { ScrambleText } from '@/components/scramble-text';
import { SCENARIOS } from '@/components/hero-scenarios';
import { SectionHeader } from '@/components/section-header';
import { BentoGrid, BentoCard } from '@/components/bento-grid';
import { CodeWindow } from '@/components/code-window';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { motion, useScroll, useTransform, AnimatePresence } from 'motion/react';

function cn(...inputs: (string | undefined | null | false)[]) {
  return twMerge(clsx(inputs));
}

const CYCLE_DURATION = 5000; // 5 seconds per slide

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

export default function HomePage() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [isLocked, setIsLocked] = useState(false);
  const { scrollYProgress } = useScroll();
  const ghostX = useTransform(scrollYProgress, [0, 1], [0, -500]);

  // Auto-rotation logic
  useEffect(() => {
    if (isLocked) return;

    const timer = setInterval(() => {
      setActiveIndex((prev) => (prev + 1) % SCENARIOS.length);
    }, CYCLE_DURATION);

    return () => clearInterval(timer);
  }, [isLocked]);

  const activeScenario = SCENARIOS[activeIndex];

  return (
    <main
      className="flex flex-col min-h-screen relative selection:bg-blue-600 selection:text-white bg-slate-50 dark:bg-slate-900 transition-colors duration-500"
      onClick={() => setIsLocked(false)} // Global click resumes rotation
    >
      {/* Global Fixed Background Layer */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        <GridBackground />
        {/* Blinking grid overlay - only visible in hero area via mask */}
        <div className="absolute inset-0 [mask-image:linear-gradient(to_bottom,black_0%,black_60%,transparent_80%)]">
          <BlinkingGridBackground />
        </div>
      </div>

      <div className="relative z-10">
        {/* --- HERO SECTION --- */}
        <section className="relative w-full overflow-hidden min-h-screen flex flex-col justify-center">
          {/* Floating Orbs */}
          <FloatingOrbs />

          {/* Ambient Lighting */}
          <div className="absolute top-[-10%] left-[-10%] w-[70%] h-[90%] bg-blue-300/30 dark:bg-blue-600/20 blur-[150px] dark:blur-[200px] rounded-full pointer-events-none" />
          <div className="absolute bottom-[-10%] right-[-10%] w-[70%] h-[90%] bg-purple-300/30 dark:bg-purple-600/30 blur-[150px] dark:blur-[200px] rounded-full pointer-events-none" />

          <div className="container relative z-10 px-4 md:px-6 mx-auto pt-32 pb-20">
            <div className="text-center mb-16">
              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="inline-flex items-center rounded-full border border-blue-500/20 bg-blue-500/10 px-4 py-1.5 text-sm font-medium text-blue-600 dark:text-blue-300 backdrop-blur-xl mb-8 shadow-lg shadow-blue-500/10"
              >
                <span className="flex h-2.5 w-2.5 rounded-full bg-blue-400 mr-2.5 shadow-[0_0_10px_#3b82f6]"></span>
                Beta now available
              </motion.div>

              <motion.h1 
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className="text-6xl md:text-8xl font-black font-heading mb-8 text-slate-900 dark:text-white drop-shadow-sm px-4"
              >
                Visualize Your <br className="hidden md:block" />
                <span className="inline-block py-2 pr-4 text-transparent bg-clip-text bg-gradient-to-r from-blue-600 via-indigo-500 to-purple-600 dark:from-blue-400 dark:via-white dark:to-purple-400 uppercase tracking-tight">
                  <ScrambleText /> Flow
                </span>
              </motion.h1>

              <motion.p 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="max-w-3xl mx-auto text-xl md:text-2xl text-slate-600 dark:text-slate-300 mb-12 leading-relaxed font-medium"
              >
                A high-performance, fully customizable node-based flow editor
                for{' '}
                <span className="inline-flex items-baseline font-bold text-blue-600 dark:text-blue-400 uppercase tracking-tight">
                  <SiFlutter className="w-5 h-5 md:w-6 md:h-6 mr-1" />
                  Flutter
                </span>
                . Build workflow editors and process automation tools with
                <span className="font-bold text-blue-600 dark:text-blue-400">
                  {' '}
                  fluid precision
                </span>
                .
              </motion.p>

              <motion.div 
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.3 }}
                className="flex flex-col sm:flex-row gap-6 justify-center items-center"
              >
                <div className="relative group">
                  {/* Animated gradient border */}
                  <div className="absolute -inset-[2px] rounded-full bg-gradient-to-r from-blue-600 via-purple-500 to-blue-600 opacity-75 blur-sm group-hover:opacity-100 group-hover:blur-md transition-all duration-200 animate-gradient-x" />
                  {/* Glow effect */}
                  <div className="absolute -inset-4 rounded-full bg-blue-500/20 blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                  <Link
                    href="/docs/getting-started"
                    className="relative inline-flex items-center justify-center h-14 px-10 rounded-full bg-blue-600 text-white font-black font-heading text-xl transition-all duration-150 hover:bg-blue-500 hover:scale-105 shadow-xl shadow-blue-500/30 active:scale-95"
                  >
                    Start Building
                    <ArrowRight className="ml-2 h-6 w-6" />
                  </Link>
                </div>
                <a
                  href="https://flow.demo.vyuh.tech"
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center justify-center h-14 px-10 rounded-full border border-slate-300 dark:border-blue-400/40 bg-white/50 dark:bg-white/5 text-slate-900 dark:text-blue-100 font-bold text-xl transition-all duration-150 hover:bg-white/80 dark:hover:bg-white/10 hover:border-blue-400 hover:shadow-lg hover:shadow-blue-500/10 backdrop-blur-xl active:scale-95"
                >
                  Live Demo
                </a>
              </motion.div>
            </div>

            {/* --- INTERACTIVE DEMO SECTION --- */}
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-16 items-center">
              <div className="lg:col-span-4 flex flex-col gap-4">
                {SCENARIOS.map((scenario, index) => {
                  const isActive = activeIndex === index;
                  return (
                    <button
                      key={scenario.id}
                      onClick={(e) => { e.stopPropagation(); setActiveIndex(index); setIsLocked(true); }}
                      className={cn(
                        'relative text-left p-6 rounded-2xl transition-all duration-150 border overflow-hidden backdrop-blur-3xl group',
                        isActive
                          ? 'border-blue-500/60 shadow-xl shadow-blue-500/10 scale-[1.02] bg-white/[0.08] dark:bg-white/[0.04]'
                          : 'border-slate-200/50 dark:border-white/5 bg-white/[0.02] dark:bg-white/[0.01] hover:bg-white/[0.06] hover:border-blue-300/30 text-slate-500',
                      )}
                    >
                      {isActive && !isLocked && (
                        <motion.div
                          key={`progress-${index}`}
                          initial={{ x: '-100%' }}
                          animate={{ x: '0%' }}
                          transition={{ duration: CYCLE_DURATION / 1000, ease: 'linear' }}
                          className="absolute inset-0 bg-blue-500/20 z-0 origin-left"
                        />
                      )}
                      {isActive && isLocked && <div className="absolute inset-0 bg-blue-500/[0.15] z-0" />}
                      <div className="relative z-10">
                        <div className={cn('font-black font-heading text-lg mb-1 transition-all duration-300 tracking-widest uppercase', isActive ? 'text-blue-700 dark:text-blue-300' : 'text-slate-500 dark:text-slate-400 group-hover:text-slate-700 dark:group-hover:text-white')}>
                          {scenario.label}
                        </div>
                        <div className={cn('text-sm font-bold leading-relaxed transition-all duration-300', isActive ? 'text-slate-800 dark:text-blue-100/90' : 'text-slate-400 dark:text-slate-500')}>
                          {scenario.description}
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
              <div className="lg:col-span-8 relative h-[600px]">
                <div className="absolute inset-0 flex items-center justify-center">
                   <AnimatePresence mode="wait">
                    <motion.div
                        key={activeIndex}
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        exit={{ opacity: 0, scale: 1.05 }}
                        transition={{ duration: 0.5 }}
                        className="w-full h-full flex items-center justify-center"
                    >
                        <HeroVisual nodes={activeScenario.nodes} connections={activeScenario.connections} />
                    </motion.div>
                   </AnimatePresence>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* --- CODE SHOWCASE --- */}
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
                                { icon: Zap, title: "Reactive State", desc: "Changes to your data automatically update the graph. No manual redraws needed.", color: "text-blue-500" },
                                { icon: ShieldCheck, title: "Strict Typing", desc: "Catch errors at compile time with generic node data types.", color: "text-purple-500" }
                            ].map((f, i) => (
                                <motion.div key={i} whileInView={{ opacity: 1, x: 0 }} initial={{ opacity: 0, x: -20 }} transition={{ delay: i * 0.1 }} className="flex items-start gap-5 p-5 rounded-2xl bg-white dark:bg-white/5 border border-slate-200 dark:border-white/10 shadow-sm backdrop-blur-sm">
                                    <div className={cn("p-3 rounded-xl bg-slate-100 dark:bg-white/5", f.color)}>
                                        <f.icon className="w-6 h-6" />
                                    </div>
                                    <div>
                                        <h4 className="font-bold text-slate-900 dark:text-white text-lg">{f.title}</h4>
                                        <p className="text-slate-600 dark:text-slate-400 mt-1">{f.desc}</p>
                                    </div>
                                </motion.div>
                            ))}
                        </div>
                    </div>
                    <div className="lg:w-1/2 w-full">
                        <CodeWindow />
                    </div>
                </div>
            </div>
        </section>

        {/* --- FEATURE DEEP DIVES --- */}
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

        {/* --- BENTO GRID --- */}
        <section className="py-32 relative z-20">
          <div className="container px-4 md:px-6 mx-auto">
             <div className="mb-20">
              <SectionHeader
                icon={<Sparkles className="w-5 h-5" />}
                tag="Packed with Features"
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

        {/* --- REFINED SUBTLE MARQUEE (Restored Aesthetics) --- */}
        <section className="py-24 relative overflow-hidden z-20 border-y border-slate-200/50 dark:border-white/5 bg-white/30 dark:bg-black/20 backdrop-blur-md">
              <div className="absolute inset-y-0 left-0 w-48 bg-gradient-to-r from-slate-50/80 dark:from-slate-900/80 to-transparent z-10 pointer-events-none" />
              <div className="absolute inset-y-0 right-0 w-48 bg-gradient-to-l from-slate-50/80 dark:from-slate-900/80 to-transparent z-10 pointer-events-none" />

              <div className="flex flex-col gap-8">
                  {/* Row 1 */}
                  <div className="flex animate-marquee whitespace-nowrap py-2">
                    {[...MARQUEE_ROW_1, ...MARQUEE_ROW_1].map((feature, i) => (
                        <div key={i} className="flex items-center">
                          <span
                            className="text-xl font-bold text-blue-600/70 dark:text-blue-400/60 cursor-default"
                          >
                            {feature}
                          </span>
                          <span className="mx-8 text-blue-500/40 font-black">•</span>
                        </div>
                    ))}
                  </div>

                  {/* Row 2 */}
                  <div className="flex animate-marquee-reverse whitespace-nowrap py-2">
                    {[...MARQUEE_ROW_2, ...MARQUEE_ROW_2].map((feature, i) => (
                        <div key={i} className="flex items-center">
                          <span
                            className="text-xl font-bold text-purple-600/70 dark:text-purple-400/60 cursor-default"
                          >
                            {feature}
                          </span>
                          <span className="mx-8 text-purple-500/40 font-black">•</span>
                        </div>
                    ))}
                  </div>

                  {/* Row 3 */}
                  <div className="flex animate-marquee-slow whitespace-nowrap py-2">
                    {[...MARQUEE_ROW_3, ...MARQUEE_ROW_3].map((feature, i) => (
                        <div key={i} className="flex items-center">
                          <span
                            className="text-xl font-bold text-teal-600/70 dark:text-teal-400/60 cursor-default"
                          >
                            {feature}
                          </span>
                          <span className="mx-8 text-teal-500/40 font-black">•</span>
                        </div>
                    ))}
                  </div>
              </div>
        </section>

        {/* --- LIVE DEMO EMBED --- */}
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
                <motion.div 
                    initial={{ opacity: 0, y: 40 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    className="rounded-3xl overflow-hidden shadow-2xl bg-slate-900 border border-slate-700"
                >
                     <div className="bg-slate-800 px-4 py-3 flex items-center gap-4 border-b border-slate-700">
                        <div className="flex gap-1.5"><div className="w-3 h-3 rounded-full bg-red-500 shadow-[0_0_8px_#ef4444]" /><div className="w-3 h-3 rounded-full bg-yellow-500 shadow-[0_0_8px_#f59e0b]" /><div className="w-3 h-3 rounded-full bg-green-500 shadow-[0_0_8px_#10b981]" /></div>
                        <div className="flex-1 bg-slate-900 rounded-md py-1.5 px-3 text-xs text-slate-400 font-mono text-center">https://flow.demo.vyuh.tech</div>
                     </div>
                    <div className="aspect-video relative bg-slate-900 group cursor-pointer overflow-hidden">
                        <div className="absolute inset-0 bg-gradient-to-br from-blue-900/20 to-purple-900/20" />
                        <div className="absolute inset-0 flex flex-col items-center justify-center z-20 group-hover:scale-105 transition-transform duration-500">
                            <div className="w-24 h-24 rounded-full bg-blue-500/20 flex items-center justify-center mb-6 backdrop-blur-sm border border-blue-500/30 group-hover:bg-blue-500/40 group-hover:border-blue-500/50 transition-all">
                                <Play className="w-10 h-10 text-blue-400 fill-blue-400" />
                            </div>
                            <h3 className="text-3xl font-black font-heading text-white mb-2 drop-shadow-lg">Launch Interactive Demo</h3>
                             <p className="text-blue-300 font-bold opacity-0 group-hover:opacity-100 transition-opacity">Full Screen Editor Available</p>
                        </div>
                        <a href="https://flow.demo.vyuh.tech" target="_blank" className="absolute inset-0 z-30" />
                    </div>
                </motion.div>
            </div>
          </div>
        </section>

        {/* --- GALLERY OF POSSIBILITIES --- */}
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
              {[
                { title: 'Workflow Automation', color: 'bg-blue-500', icon: GitBranch, desc: 'Visual step-by-step logic engines.' },
                { title: 'IoT Device Managers', color: 'bg-emerald-500', icon: Cpu, desc: 'Real-time device network topologies.' },
                { title: 'Visual Coding Tools', color: 'bg-purple-500', icon: Code2, desc: 'Custom node-based programming editors.' },
                { title: 'Chatbot Builders', color: 'bg-pink-500', icon: Sparkles, desc: 'Dialogue tree and response mapping.' },
                { title: 'Database Design', color: 'bg-orange-500', icon: FileJson, desc: 'Schema visualization and relationship mapping.' },
                { title: 'Mind Mapping', color: 'bg-yellow-500', icon: Map, desc: 'Infinite canvas for collaborative ideas.' },
                { title: 'Network Topologies', color: 'bg-cyan-500', icon: Share2, desc: 'Cloud infrastructure visualization.' },
                { title: 'Circuit Simulators', color: 'bg-red-500', icon: Zap, desc: 'Electronic and logic gate simulation.' },
              ].map((item, i) => (
                <motion.div
                    key={i}
                    whileHover={{ y: -8, scale: 1.02 }}
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ type: "tween", duration: 0.1, ease: "easeOut" }}
                    className="group relative overflow-hidden p-8 rounded-3xl border border-slate-200 dark:border-white/10 bg-white/80 dark:bg-white/5 backdrop-blur-lg shadow-xl transition-shadow duration-100 hover:shadow-2xl hover:border-blue-500/20"
                >
                  <div className={cn("absolute top-0 right-0 w-32 h-32 -mr-12 -mt-12 rounded-full opacity-10 blur-3xl transition-opacity group-hover:opacity-20", item.color)} />
                  <div className={cn("w-12 h-12 rounded-2xl flex items-center justify-center mb-6 bg-slate-100 dark:bg-white/5 transition-colors group-hover:bg-slate-200 dark:group-hover:bg-white/10")}>
                    <item.icon className="w-6 h-6 text-slate-700 dark:text-slate-300 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors" />
                  </div>
                  <span className="font-black text-xl text-slate-900 dark:text-slate-100 block mb-2 tracking-normal">{item.title}</span>
                  <p className="text-slate-600 dark:text-slate-400 font-medium text-sm leading-relaxed">{item.desc}</p>
                </motion.div>
              ))}
            </div>
          </div>
        </section>

        {/* --- CTA --- */}
        <section className="py-40 relative overflow-hidden z-20">
          <div className="absolute inset-0 bg-gradient-to-t from-blue-100/50 to-transparent dark:from-blue-950/20 -z-10" />
          
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-full max-w-4xl max-h-[400px] bg-blue-500/10 blur-[120px] rounded-full pointer-events-none -z-10" />

          <div className="container px-4 md:px-6 mx-auto text-center">
            <motion.h2 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-5xl md:text-8xl font-black font-heading mb-10 text-slate-900 dark:text-white tracking-tight drop-shadow-2xl"
            >
              Ready to create?
            </motion.h2>
            
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.1 }}
              className="max-w-4xl mx-auto space-y-8"
            >
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
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, scale: 0.9 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ delay: 0.2 }}
              className="mt-16 flex flex-col sm:flex-row gap-8 justify-center items-center"
            >
              <div className="relative group">
                {/* Animated gradient border */}
                <div className="absolute -inset-[3px] rounded-full bg-gradient-to-r from-blue-600 via-purple-500 to-blue-600 opacity-75 blur-sm group-hover:opacity-100 group-hover:blur-md transition-all duration-200 animate-gradient-x" />
                {/* Glow effect */}
                <div className="absolute -inset-6 rounded-full bg-blue-500/20 blur-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                <Link
                  href="/docs/getting-started"
                  className="relative inline-flex items-center justify-center h-20 px-16 rounded-full bg-blue-600 text-white font-black font-heading text-3xl transition-all duration-150 hover:bg-blue-500 hover:scale-105 shadow-2xl shadow-blue-500/40 active:scale-95"
                >
                  Get Started Now
                  <ArrowRight className="ml-3 h-8 w-8" />
                </Link>
              </div>
            </motion.div>
            
            <p className="mt-12 text-slate-500 dark:text-slate-500 font-black tracking-widest uppercase text-sm">
              Start building your flows today.
            </p>
          </div>
        </section>

        {/* --- FOOTER SECTION --- */}
        <section className="py-16 relative z-20 border-t border-slate-200 dark:border-white/5 bg-slate-50/50 dark:bg-[#020617]/50 backdrop-blur-sm">
          <div className="container px-4 md:px-6 mx-auto text-center">
            <div className="flex flex-wrap justify-center items-center gap-8 text-sm font-medium text-slate-600 dark:text-slate-400">
              <Link href="/docs" className="hover:text-blue-500 dark:hover:text-blue-400 transition-colors">Documentation</Link>
              <Link href="https://github.com/vyuh-tech/vyuh_node_flow" target="_blank" rel="noopener noreferrer" className="hover:text-blue-500 dark:hover:text-blue-400 transition-colors">GitHub</Link>
              <Link href="/privacy-policy" className="hover:text-blue-500 dark:hover:text-blue-400 transition-colors">Privacy Policy</Link>
              <Link href="/terms-of-service" className="hover:text-blue-500 dark:hover:text-blue-400 transition-colors">Terms of Service</Link>
              <Link href="/pro" className="font-bold text-blue-600 dark:text-blue-400 hover:underline transition-colors">Pro Version</Link>
            </div>

            <div className="mt-12 text-slate-500 dark:text-slate-400 text-base font-medium">
              Copyright &copy; {new Date().getFullYear()} Vyuh Technologies Private Limited. All rights reserved.
            </div>
          </div>
          
          {/* Ghost Text Overlay - behind copyright text */}
          <div className="absolute inset-0 -z-10 pointer-events-none overflow-hidden select-none opacity-30 dark:opacity-20">
            <motion.div
              style={{ x: ghostX }}
              className="whitespace-nowrap text-[10vw] font-black uppercase leading-none text-slate-300 dark:text-white/20"
            >
              Vyuh Node Flow • Vyuh Node Flow • Vyuh Node Flow • Vyuh Node Flow
            </motion.div>
          </div>
        </section>
      </div>
    </main>
  );
}

// --- HELPERS ---

function FeatureSection({ align, title, description, icon, image, features }: { align: 'left' | 'right'; title: string; description: string; icon: React.ReactNode; image: string; features: string[]; }) {
  return (
    <div className="py-40 overflow-hidden">
      <div className="container px-4 md:px-6 mx-auto">
        <div className={cn('flex flex-col lg:flex-row items-center gap-24', align === 'right' ? 'lg:flex-row-reverse' : '')}>
          <div className="flex-1">
            <SectionHeader icon={icon} tag={title} title={title} subtitle={description} features={features} align="left" />
          </div>
          <div className="flex-1 w-full relative perspective-[1500px]">
            <div className="relative rounded-[2.5rem] overflow-hidden shadow-2xl border border-slate-200 dark:border-white/10 bg-white/40 dark:bg-white/5 backdrop-blur-xl group">
                <div className="absolute inset-0 bg-gradient-to-tr from-blue-500/10 to-transparent pointer-events-none z-10" />
                <Image src={image} alt={title} width={800} height={600} className="w-full h-auto object-cover opacity-90 group-hover:scale-105 group-hover:opacity-100 transition-all duration-200" unoptimized />
            </div>
            {/* Ambient Shadow/Glow */}
            <div className={cn("absolute -z-10 w-full h-full top-12 blur-[100px] opacity-25 rounded-full", align === 'left' ? "-right-16 bg-blue-500" : "-left-16 bg-purple-500")} />
          </div>
        </div>
      </div>
    </div>
  );
}

const features = [
  { 
    Icon: Zap, 
    name: 'High Performance', 
    description: 'Rendering hundreds of nodes at 60fps with optimized virtualization.', 
    href: '/docs/core-concepts/performance', 
    cta: 'Learn more', 
    className: 'lg:row-start-1 lg:row-end-2 lg:col-start-1 lg:col-end-3', 
    background: <div className="absolute inset-0 bg-gradient-to-br from-amber-100 to-transparent dark:from-amber-900/20 opacity-50" /> 
  },
  { 
    Icon: Palette, 
    name: 'Custom Themes', 
    description: 'Style every aspect of your graph to match your brand identity.', 
    href: '/docs/theming', 
    cta: 'Explore theming', 
    className: 'lg:col-start-3 lg:col-end-4 lg:row-start-1 lg:row-end-2', 
    background: <div className="absolute inset-0 bg-gradient-to-br from-purple-100 to-transparent dark:from-purple-900/20 opacity-50" /> 
  },
  { 
    Icon: Plug, 
    name: 'Smart Connections', 
    description: 'Auto-routing, validation, and multiple path styles included.', 
    href: '/docs/core-concepts/connections', 
    cta: 'See connections', 
    className: 'lg:col-start-1 lg:col-end-2 lg:row-start-2 lg:row-end-3', 
    background: <div className="absolute inset-0 bg-gradient-to-br from-blue-100 to-transparent dark:from-blue-900/20 opacity-50" /> 
  },
  { 
    Icon: Box, 
    name: 'Custom Nodes', 
    description: 'Create any node UI you can imagine using standard Flutter widgets.', 
    href: '/docs/core-concepts/custom-nodes', 
    cta: 'Build nodes', 
    className: 'lg:col-start-2 lg:col-end-4 lg:row-start-2 lg:row-end-3', 
    background: <div className="absolute inset-0 bg-gradient-to-br from-green-100 to-transparent dark:from-green-900/20 opacity-50" /> 
  },
  { 
    Icon: Map, 
    name: 'MiniMap', 
    description: 'Navigate huge graphs effortlessly with real-time overview.', 
    href: '/docs/components/minimap', 
    cta: 'Try minimap', 
    className: 'lg:col-start-1 lg:col-end-2 lg:row-start-3 lg:row-end-4', 
    background: <div className="absolute inset-0 bg-gradient-to-br from-teal-100 to-transparent dark:from-teal-900/20 opacity-50" /> 
  },
  { 
    Icon: ShieldCheck, 
    name: 'Type-Safe Data', 
    description: 'Generic type support for strongly-typed node data.', 
    href: '/docs/core-concepts/node-data', 
    cta: 'See types', 
    className: 'lg:col-start-2 lg:col-end-3 lg:row-start-3 lg:row-end-4', 
    background: <div className="absolute inset-0 bg-gradient-to-br from-emerald-100 to-transparent dark:from-emerald-900/20 opacity-50" /> 
  },
  { 
    Icon: FileJson, 
    name: 'Serialization', 
    description: 'Save and load flows from JSON with type-safe deserialization.', 
    href: '/docs/core-concepts/serialization', 
    cta: 'Learn JSON', 
    className: 'lg:col-start-3 lg:col-end-4 lg:row-start-3 lg:row-end-4', 
    background: <div className="absolute inset-0 bg-gradient-to-br from-orange-100 to-transparent dark:from-orange-900/20 opacity-50" /> 
  },
  { 
    Icon: Sparkles, 
    name: 'Connection Effects', 
    description: 'Animated effects like FlowingDash, Particle, and Pulse.', 
    href: '/docs/core-concepts/connection-effects', 
    cta: 'View effects', 
    className: 'lg:col-start-1 lg:col-end-2 lg:row-start-4 lg:row-end-5', 
    background: <div className="absolute inset-0 bg-gradient-to-br from-pink-100 to-transparent dark:from-pink-900/20 opacity-50" /> 
  },
  {
    Icon: Activity,
    name: 'Event System',
    description: 'Rich event callbacks for user interactions and state changes.',
    href: '/docs/advanced/events',
    cta: 'Handle events',
    className: 'lg:col-start-2 lg:col-end-4 lg:row-start-4 lg:row-end-5',
    background: <div className="absolute inset-0 bg-gradient-to-br from-indigo-100 to-transparent dark:from-indigo-900/20 opacity-50" />
  },
  {
    Icon: MessageSquare,
    name: 'Annotations',
    description: 'Add sticky notes, comments, and documentation directly on your canvas.',
    href: '/docs/advanced/annotations',
    cta: 'Add notes',
    className: 'lg:col-start-1 lg:col-end-3 lg:row-start-5 lg:row-end-6',
    background: <div className="absolute inset-0 bg-gradient-to-br from-yellow-100 to-transparent dark:from-yellow-900/20 opacity-50" />
  },
  {
    Icon: Group,
    name: 'Group Nodes',
    description: 'Organize complex flows with collapsible groups and nested hierarchies.',
    href: '/docs/advanced/group-nodes',
    cta: 'Learn grouping',
    className: 'lg:col-start-3 lg:col-end-4 lg:row-start-5 lg:row-end-6',
    background: <div className="absolute inset-0 bg-gradient-to-br from-cyan-100 to-transparent dark:from-cyan-900/20 opacity-50" />
  },
];
