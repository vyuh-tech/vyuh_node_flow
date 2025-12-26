'use client';

import { useMemo } from 'react';
import { useIsMobile, useReducedMotion } from '@/hooks/use-mobile';

interface Orb {
  id: number;
  size: number;
  x: number;
  y: number;
  duration: number;
  delay: number;
  color: string;
}

export function FloatingOrbs() {
  const isMobile = useIsMobile();
  const prefersReducedMotion = useReducedMotion();

  // Disable animations on mobile or when reduced motion is preferred
  const shouldAnimate = !isMobile && !prefersReducedMotion;

  const orbs = useMemo<Orb[]>(() => {
    // Return fewer orbs on mobile, or none if animations disabled
    if (!shouldAnimate) return [];

    const colors = [
      'bg-blue-400/20 dark:bg-blue-500/15',
      'bg-purple-400/20 dark:bg-purple-500/15',
      'bg-indigo-400/15 dark:bg-indigo-500/10',
      'bg-cyan-400/15 dark:bg-cyan-500/10',
    ];

    return Array.from({ length: 6 }, (_, i) => ({
      id: i,
      size: 100 + Math.random() * 200,
      x: Math.random() * 100,
      y: Math.random() * 100,
      duration: 15 + Math.random() * 20,
      delay: Math.random() * 5,
      color: colors[i % colors.length],
    }));
  }, [shouldAnimate]);

  if (!shouldAnimate) return null;

  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {orbs.map((orb) => (
        <div
          key={orb.id}
          className={`absolute rounded-full blur-3xl ${orb.color} animate-float-orb`}
          style={{
            width: orb.size,
            height: orb.size,
            left: `${orb.x}%`,
            top: `${orb.y}%`,
            animationDuration: `${orb.duration}s`,
            animationDelay: `${orb.delay}s`,
          }}
        />
      ))}
    </div>
  );
}
