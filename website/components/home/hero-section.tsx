'use client';

import Link from 'next/link';
import React, { useEffect, useState } from 'react';
import { ArrowRight } from 'lucide-react';
import { SiFlutter } from 'react-icons/si';
import { SCENARIOS } from '@/components/hero-scenarios';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import dynamic from 'next/dynamic';

function cn(...inputs: (string | undefined | null | false)[]) {
  return twMerge(clsx(inputs));
}

// Dynamically import heavy components - only loaded on desktop
const HeroVisual = dynamic(
  () => import('@/components/hero-visual').then((mod) => mod.HeroVisual),
  { ssr: false, loading: () => <HeroPlaceholder /> }
);

const BlinkingGridBackground = dynamic(
  () =>
    import('@/components/blinking-grid').then(
      (mod) => mod.BlinkingGridBackground
    ),
  { ssr: false }
);

const FloatingOrbs = dynamic(
  () => import('@/components/floating-orbs').then((mod) => mod.FloatingOrbs),
  { ssr: false }
);

const ScrambleText = dynamic(
  () => import('@/components/scramble-text').then((mod) => mod.ScrambleText),
  { ssr: false, loading: () => <span>Data</span> }
);

// Lightweight placeholder for mobile
function HeroPlaceholder() {
  return (
    <div className="w-full h-[400px] flex items-center justify-center">
      <div className="text-center text-slate-400 dark:text-slate-600">
        <div className="w-16 h-16 mx-auto mb-4 rounded-xl bg-gradient-to-br from-blue-500/20 to-purple-500/20 animate-pulse" />
        <p className="text-sm font-medium">Loading visualization...</p>
      </div>
    </div>
  );
}

const CYCLE_DURATION = 5000;

export function HeroSection() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [isLocked, setIsLocked] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    // Check if mobile on mount
    const checkMobile = () => setIsMobile(window.innerWidth < 768);
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  useEffect(() => {
    if (isLocked || isMobile) return; // Don't auto-rotate on mobile

    const timer = setInterval(() => {
      setActiveIndex((prev) => (prev + 1) % SCENARIOS.length);
    }, CYCLE_DURATION);

    return () => clearInterval(timer);
  }, [isLocked, isMobile]);

  const activeScenario = SCENARIOS[activeIndex];

  return (
    <section
      className="relative w-full overflow-hidden min-h-screen flex flex-col justify-center"
      onClick={() => setIsLocked(false)}
    >
      {/* Fixed Background Layer - Canvas draws both grid and blinking cells */}
      <div className="absolute inset-0 z-0 pointer-events-none">
        {mounted && (
          <div className="absolute inset-0 [mask-image:linear-gradient(to_bottom,black_0%,black_60%,transparent_80%)]">
            <BlinkingGridBackground />
          </div>
        )}
      </div>

      {/* Floating Orbs - desktop only */}
      {mounted && !isMobile && <FloatingOrbs />}

      {/* Ambient Lighting - vertical on mobile, diagonal on desktop */}
      <div
        className={cn(
          'absolute rounded-full pointer-events-none',
          isMobile
            ? 'top-0 left-1/2 -translate-x-1/2 w-[120%] h-[40%] bg-blue-300/25 dark:bg-blue-600/15 blur-[100px]'
            : 'top-[-10%] left-[-10%] w-[70%] h-[90%] bg-blue-300/30 dark:bg-blue-600/20 blur-[150px] dark:blur-[200px]'
        )}
      />
      <div
        className={cn(
          'absolute rounded-full pointer-events-none',
          isMobile
            ? 'bottom-0 left-1/2 -translate-x-1/2 w-[120%] h-[40%] bg-purple-300/25 dark:bg-purple-600/15 blur-[100px]'
            : 'bottom-[-10%] right-[-10%] w-[70%] h-[90%] bg-purple-300/30 dark:bg-purple-600/30 blur-[150px] dark:blur-[200px]'
        )}
      />

      <div className="container relative z-10 px-4 md:px-6 mx-auto pt-24 md:pt-32 pb-12 md:pb-20">
        <div className="text-center mb-8 md:mb-16">
          {/* Badge */}
          <div className="inline-flex items-center rounded-full border border-blue-500/20 bg-blue-500/10 px-4 py-1.5 text-sm font-medium text-blue-600 dark:text-blue-300 backdrop-blur-xl mb-6 md:mb-8 shadow-lg shadow-blue-500/10">
            <span className="flex h-2.5 w-2.5 rounded-full bg-blue-400 mr-2.5 shadow-[0_0_10px_#3b82f6] animate-pulse" />
            Beta now available
          </div>

          {/* Headline */}
          <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-8xl font-black font-heading mb-6 md:mb-8 text-slate-900 dark:text-white drop-shadow-sm px-2 md:px-4">
            Visualize Your <br className="hidden sm:block" />
            <span className="inline-block py-2 pr-2 md:pr-4 text-transparent bg-clip-text bg-gradient-to-r from-blue-600 via-indigo-500 to-purple-600 dark:from-blue-400 dark:via-white dark:to-purple-400 uppercase tracking-tight">
              {mounted ? <ScrambleText /> : 'Data'} Flow
            </span>
          </h1>

          {/* Subheadline */}
          <p className="max-w-3xl mx-auto text-lg md:text-xl lg:text-2xl text-slate-600 dark:text-slate-300 mb-8 md:mb-12 leading-relaxed font-medium px-2">
            A high-performance, fully customizable node-based flow editor for{' '}
            <span className="inline-flex items-baseline font-bold text-blue-600 dark:text-blue-400 uppercase tracking-tight">
              <SiFlutter className="w-4 h-4 md:w-5 md:h-5 lg:w-6 lg:h-6 mr-1" />
              Flutter
            </span>
            .{' '}
            <span className="hidden sm:inline">
              Build workflow editors and process automation tools with
              <span className="font-bold text-blue-600 dark:text-blue-400">
                {' '}
                fluid precision
              </span>
              .
            </span>
          </p>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 md:gap-6 justify-center items-center">
            <Link
              href="/docs/getting-started"
              className="relative inline-flex items-center justify-center h-12 md:h-14 w-full sm:w-auto px-8 md:px-10 rounded-full bg-blue-600 text-white font-black font-heading text-lg md:text-xl tracking-normal transition-all duration-150 hover:bg-blue-500 hover:scale-105 shadow-xl shadow-blue-500/30 active:scale-95"
            >
              Start Building
              <ArrowRight className="ml-2 h-5 w-5 md:h-6 md:w-6" />
            </Link>
            <a
              href="https://flow.demo.vyuh.tech"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center justify-center h-12 md:h-14 w-full sm:w-auto px-8 md:px-10 rounded-full border border-slate-300 dark:border-blue-400/40 bg-white/50 dark:bg-white/5 text-slate-900 dark:text-blue-100 font-black font-heading text-lg md:text-xl tracking-normal transition-all duration-150 hover:bg-white/80 dark:hover:bg-white/10 hover:border-blue-400 backdrop-blur-xl active:scale-95"
            >
              Live Demo
            </a>
          </div>
        </div>

        {/* Interactive Demo Section */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 lg:gap-16 items-center">
          {/* Scenario Selector */}
          <div className="lg:col-span-4 flex flex-col gap-3 md:gap-4">
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
                    'relative text-left p-4 md:p-6 rounded-xl md:rounded-2xl transition-all duration-150 border overflow-hidden backdrop-blur-xl group',
                    isActive
                      ? 'border-blue-500/60 shadow-lg shadow-blue-500/10 bg-white/10 dark:bg-white/[0.04]'
                      : 'border-slate-200/50 dark:border-white/5 bg-white/[0.02] dark:bg-white/[0.01] hover:bg-white/[0.06] hover:border-blue-300/30 text-slate-500'
                  )}
                >
                  {/* Progress bar - desktop only, no JS animation */}
                  {isActive && !isLocked && !isMobile && (
                    <div
                      className="absolute inset-0 bg-blue-500/20 z-0 origin-left animate-progress-bar"
                      style={
                        {
                          '--duration': `${CYCLE_DURATION}ms`,
                        } as React.CSSProperties
                      }
                    />
                  )}
                  {isActive && isLocked && (
                    <div className="absolute inset-0 bg-blue-500/[0.15] z-0" />
                  )}
                  <div className="relative z-10">
                    <div
                      className={cn(
                        'font-black font-heading text-base md:text-lg mb-1 transition-all duration-300 tracking-widest uppercase',
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

          {/* Visual */}
          <div className="lg:col-span-8 relative h-[350px] md:h-[500px] lg:h-[600px]">
            <div className="absolute inset-0 flex items-center justify-center">
              {mounted && (
                <div
                  key={activeIndex}
                  className="w-full h-full flex items-center justify-center animate-fade-in"
                >
                  <HeroVisual
                    nodes={activeScenario.nodes}
                    connections={activeScenario.connections}
                  />
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
