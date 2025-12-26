'use client';

import Link from 'next/link';
import React, { useEffect, useState } from 'react';
import { ArrowRight } from 'lucide-react';
import { SiFlutter } from 'react-icons/si';
import { HeroVisual } from '@/components/hero-visual';
import { GridBackground } from '@/components/grid-background';
import { BlinkingGridBackground } from '@/components/blinking-grid';
import { FloatingOrbs } from '@/components/floating-orbs';
import { ScrambleText } from '@/components/scramble-text';
import { SCENARIOS } from '@/components/hero-scenarios';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { motion, AnimatePresence } from 'motion/react';
import { useIsMobile } from '@/hooks/use-mobile';

function cn(...inputs: (string | undefined | null | false)[]) {
  return twMerge(clsx(inputs));
}

const CYCLE_DURATION = 5000;

export function HeroSection() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [isLocked, setIsLocked] = useState(false);
  const [mounted, setMounted] = useState(false);
  const isMobile = useIsMobile();

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (isLocked) return;

    const timer = setInterval(() => {
      setActiveIndex((prev) => (prev + 1) % SCENARIOS.length);
    }, CYCLE_DURATION);

    return () => clearInterval(timer);
  }, [isLocked]);

  const activeScenario = SCENARIOS[activeIndex];

  return (
    <section
      className="relative w-full overflow-hidden min-h-screen flex flex-col justify-center"
      onClick={() => setIsLocked(false)}
    >
      {/* Fixed Background Layer */}
      <div className="absolute inset-0 z-0 pointer-events-none">
        <GridBackground />
        <div className="absolute inset-0 [mask-image:linear-gradient(to_bottom,black_0%,black_60%,transparent_80%)]">
          <BlinkingGridBackground />
        </div>
      </div>

      {/* Floating Orbs - only on desktop */}
      <FloatingOrbs />

      {/* Ambient Lighting */}
      <div className="absolute top-[-10%] left-[-10%] w-[70%] h-[90%] bg-blue-300/30 dark:bg-blue-600/20 blur-[150px] dark:blur-[200px] rounded-full pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[70%] h-[90%] bg-purple-300/30 dark:bg-purple-600/30 blur-[150px] dark:blur-[200px] rounded-full pointer-events-none" />

      <div className="container relative z-10 px-4 md:px-6 mx-auto pt-32 pb-20">
        <div className="text-center mb-16">
          {mounted ? (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="inline-flex items-center rounded-full border border-blue-500/20 bg-blue-500/10 px-4 py-1.5 text-sm font-medium text-blue-600 dark:text-blue-300 backdrop-blur-xl mb-8 shadow-lg shadow-blue-500/10"
            >
              <span className="flex h-2.5 w-2.5 rounded-full bg-blue-400 mr-2.5 shadow-[0_0_10px_#3b82f6]"></span>
              Beta now available
            </motion.div>
          ) : (
            <div className="inline-flex items-center rounded-full border border-blue-500/20 bg-blue-500/10 px-4 py-1.5 text-sm font-medium text-blue-600 dark:text-blue-300 backdrop-blur-xl mb-8 shadow-lg shadow-blue-500/10">
              <span className="flex h-2.5 w-2.5 rounded-full bg-blue-400 mr-2.5 shadow-[0_0_10px_#3b82f6]"></span>
              Beta now available
            </div>
          )}

          <h1 className="text-6xl md:text-8xl font-black font-heading mb-8 text-slate-900 dark:text-white drop-shadow-sm px-4">
            Visualize Your <br className="hidden md:block" />
            <span className="inline-block py-2 pr-4 text-transparent bg-clip-text bg-gradient-to-r from-blue-600 via-indigo-500 to-purple-600 dark:from-blue-400 dark:via-white dark:to-purple-400 uppercase tracking-tight">
              <ScrambleText /> Flow
            </span>
          </h1>

          <p className="max-w-3xl mx-auto text-xl md:text-2xl text-slate-600 dark:text-slate-300 mb-12 leading-relaxed font-medium">
            A high-performance, fully customizable node-based flow editor for{' '}
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
          </p>

          <div className="flex flex-col sm:flex-row gap-6 justify-center items-center">
            <div className="relative group">
              <div className="absolute -inset-[2px] rounded-full bg-gradient-to-r from-blue-600 via-purple-500 to-blue-600 opacity-75 blur-sm group-hover:opacity-100 group-hover:blur-md transition-all duration-200 animate-gradient-x" />
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
          </div>
        </div>

        {/* Interactive Demo Section */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-16 items-center">
          <div className="lg:col-span-4 flex flex-col gap-4">
            {SCENARIOS.map((scenario, index) => {
              const isActive = activeIndex === index;
              return (
                <button
                  key={scenario.id}
                  onClick={(e) => {
                    e.stopPropagation();
                    setActiveIndex(index);
                    setIsLocked(true);
                  }}
                  className={cn(
                    'relative text-left p-6 rounded-2xl transition-all duration-150 border overflow-hidden backdrop-blur-3xl group',
                    isActive
                      ? 'border-blue-500/60 shadow-xl shadow-blue-500/10 scale-[1.02] bg-white/[0.08] dark:bg-white/[0.04]'
                      : 'border-slate-200/50 dark:border-white/5 bg-white/[0.02] dark:bg-white/[0.01] hover:bg-white/[0.06] hover:border-blue-300/30 text-slate-500'
                  )}
                >
                  {isActive && !isLocked && !isMobile && (
                    <motion.div
                      key={`progress-${index}`}
                      initial={{ x: '-100%' }}
                      animate={{ x: '0%' }}
                      transition={{
                        duration: CYCLE_DURATION / 1000,
                        ease: 'linear',
                      }}
                      className="absolute inset-0 bg-blue-500/20 z-0 origin-left"
                    />
                  )}
                  {isActive && isLocked && (
                    <div className="absolute inset-0 bg-blue-500/[0.15] z-0" />
                  )}
                  <div className="relative z-10">
                    <div
                      className={cn(
                        'font-black font-heading text-lg mb-1 transition-all duration-300 tracking-widest uppercase',
                        isActive
                          ? 'text-blue-700 dark:text-blue-300'
                          : 'text-slate-500 dark:text-slate-400 group-hover:text-slate-700 dark:group-hover:text-white'
                      )}
                    >
                      {scenario.label}
                    </div>
                    <div
                      className={cn(
                        'text-sm font-bold leading-relaxed transition-all duration-300',
                        isActive
                          ? 'text-slate-800 dark:text-blue-100/90'
                          : 'text-slate-400 dark:text-slate-500'
                      )}
                    >
                      {scenario.description}
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
          <div className="lg:col-span-8 relative h-[400px] lg:h-[600px]">
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
                  <HeroVisual
                    nodes={activeScenario.nodes}
                    connections={activeScenario.connections}
                  />
                </motion.div>
              </AnimatePresence>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
