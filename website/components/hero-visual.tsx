'use client';

import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import React from 'react';
import { useIsMobile } from '@/hooks/use-mobile';

// --- Types ---

export type NodeType = 'source' | 'process' | 'output' | 'config' | 'action' | 'trigger' | 'broadcast';

export interface NodeData {
  id: string;
  type: NodeType;
  title: string;
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface ConnectionData {
  id: string;
  from: string;
  to: string;
  color?: string;
  delay?: number;
  type?: 'default' | 'loopback';
}

interface HeroVisualProps {
  nodes: NodeData[];
  connections: ConnectionData[];
}

function cn(...inputs: (string | undefined | null | false)[]) {
  return twMerge(clsx(inputs));
}

function getPathForConnection(conn: ConnectionData, nodes: NodeData[]) {
  const fromNode = nodes.find(n => n.id === conn.from);
  const toNode = nodes.find(n => n.id === conn.to);

  if (!fromNode || !toNode) return '';

  const startX = fromNode.x + fromNode.width;
  const startY = fromNode.y + (fromNode.height / 2);
  const endX = toNode.x;
  const endY = toNode.y + (toNode.height / 2) + 0.1;

  if (conn.type === 'loopback' || endX < startX) {
    const spacing = 30;
    const dropY = Math.max(startY, endY) + 80;
    return `M ${startX} ${startY} L ${startX + spacing} ${startY} L ${startX + spacing} ${dropY} L ${endX - spacing} ${dropY} L ${endX - spacing} ${endY} L ${endX} ${endY}`;
  }

  const deltaX = endX - startX;
  const controlOffset = Math.max(deltaX * 0.5, 60);
  const cp1X = startX + controlOffset;
  const cp1Y = startY;
  const cp2X = endX - controlOffset;
  const cp2Y = endY;

  return `M ${startX} ${startY} C ${cp1X} ${cp1Y}, ${cp2X} ${cp2Y}, ${endX} ${endY}`;
}

export function HeroVisual({ nodes, connections }: HeroVisualProps) {
  const isMobile = useIsMobile();

  // Fixed 3D rotation angles - no mouse interaction
  const rotateX = 30;
  const rotateZ = -30;

  // Scale down more on mobile
  const scale = isMobile ? 0.45 : 0.8;

  return (
    <div className="relative w-full h-[350px] md:h-[500px] lg:h-[600px] flex items-center justify-center overflow-hidden">
      <div
        style={{
          transform: `perspective(2000px) rotateX(${rotateX}deg) rotateZ(${rotateZ}deg) scale(${scale})`,
          transformStyle: 'preserve-3d',
        }}
        className="relative"
      >
        <div style={{ width: 800, height: 500 }} className="relative">
          {/* Connections */}
          <svg className="absolute inset-0 w-full h-full overflow-visible pointer-events-none">
            <defs>
              <linearGradient id="gradient-line" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="800" y2="0">
                <stop offset="0%" stopColor="#3b82f6" stopOpacity="0.8" />
                <stop offset="100%" stopColor="#a855f7" stopOpacity="0.8" />
              </linearGradient>
            </defs>
            {connections.map((conn, i) => (
              <ConnectionPath
                key={conn.id}
                d={getPathForConnection(conn, nodes)}
                delay={i * 0.2}
                color={conn.color}
              />
            ))}
          </svg>

          {/* Nodes */}
          {nodes.map((node, i) => (
            <StaticNode key={node.id} data={node} delay={i * 0.1} />
          ))}
        </div>
      </div>
    </div>
  );
}

// Static node with CSS animations
function StaticNode({ data, delay }: { data: NodeData; delay: number }) {
  const { x, y, width, height, type, title } = data;

  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width,
        height,
        animationDelay: `${delay}s`,
      }}
      className="font-mono animate-node-enter"
    >
      {/* Shadow layer */}
      <div className="absolute inset-4 rounded-xl bg-blue-500/10 dark:bg-black/40 blur-xl opacity-40" />

      {/* Node card */}
      <div
        className={cn(
          "absolute inset-0 rounded-xl border-2",
          "bg-white/[0.05] dark:bg-white/[0.02] border-white/20 dark:border-white/10 backdrop-blur-2xl shadow-xl",
          type === 'source' && "border-green-500/30 dark:border-green-400/30",
          type === 'process' && "border-blue-500/30 dark:border-blue-400/30",
          type === 'output' && "border-purple-500/30 dark:border-purple-400/30",
          type === 'config' && "border-orange-500/30 dark:border-orange-400/30",
          type === 'trigger' && "border-red-500/30 dark:border-red-400/30",
          type === 'action' && "border-indigo-500/30 dark:border-indigo-400/30",
          type === 'broadcast' && "border-pink-500/30 dark:border-pink-400/30",
        )}
      >
        {/* Port indicators */}
        <div className="absolute top-1/2 -left-1.5 -translate-y-1/2 w-3.5 h-3.5 rounded-full border border-white/30 bg-slate-800 shadow-sm" />
        <div className="absolute top-1/2 -right-1.5 -translate-y-1/2 w-3.5 h-3.5 rounded-full border border-white/30 bg-slate-800 shadow-sm" />

        {/* Content */}
        <div className="absolute inset-0 p-4 flex flex-col justify-between">
          <div className="flex items-center gap-2">
            <NodeIcon type={type} />
            <span className="text-[10px] font-bold text-slate-900 dark:text-white uppercase tracking-widest font-heading drop-shadow-sm">
              {title}
            </span>
          </div>
          <div className="flex-1 mt-2">
            <NodeContent type={type} />
          </div>
        </div>

        {/* Glass highlight */}
        <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-white/20 to-transparent opacity-30 pointer-events-none" />
      </div>
    </div>
  );
}

function NodeIcon({ type }: { type: NodeType }) {
  switch(type) {
    case 'source': return <div className="w-2 h-2 rounded-full bg-green-600 dark:bg-green-400 shadow-[0_0_8px_#4ade80]" />;
    case 'process': return <div className="w-2.5 h-2.5 rounded-sm bg-blue-600 dark:bg-blue-400 shadow-[0_0_8px_#60a5fa]" />;
    case 'output': return <div className="w-2 h-2 rounded-full bg-purple-600 dark:bg-purple-400 shadow-[0_0_8px_#c084fc]" />;
    case 'config': return <div className="w-2 h-2 rounded-full bg-orange-600 dark:bg-orange-400 shadow-[0_0_8px_#fb923c]" />;
    case 'trigger': return <div className="w-2 h-2 rounded-full bg-red-600 dark:bg-red-400 shadow-[0_0_8px_#f87171]" />;
    case 'action': return <div className="w-2 h-2 rotate-45 bg-indigo-600 dark:bg-indigo-400 shadow-[0_0_8px_#818cf8]" />;
    case 'broadcast': return <div className="w-2 h-2 rounded-full bg-pink-600 dark:bg-pink-400 shadow-[0_0_8px_#f472b6]" />;
    default: return <div className="w-2 h-2 bg-gray-500" />;
  }
}

function NodeContent({ type }: { type: NodeType }) {
  switch(type) {
    case 'source': return (
      <div className="space-y-1.5 pt-1">
        <div className="h-1 w-[80%] bg-green-600/30 dark:bg-green-500/20 rounded-full" />
        <div className="h-1 w-[50%] bg-slate-400/40 dark:bg-white/10 rounded-full" />
      </div>
    );
    case 'process': return (
      <div className="flex items-center gap-2 h-full">
        <div className="w-8 h-8 rounded-lg bg-blue-600/10 dark:bg-blue-500/10 border-2 border-blue-600/20 dark:border-blue-500/20 flex items-center justify-center">
          <div className="w-4 h-4 rounded-full border-2 border-blue-600/40 dark:border-blue-500/40 border-t-blue-700 dark:border-t-blue-400 animate-spin-slow" />
        </div>
        <div className="space-y-1 flex-1">
          <div className="h-1.5 w-full bg-slate-300/40 dark:bg-white/5 rounded-full overflow-hidden">
            <div className="h-full bg-blue-600 dark:bg-blue-500/40 animate-progress" />
          </div>
        </div>
      </div>
    );
    case 'config': return (
      <div className="pt-1">
        <div className="h-1.5 w-full bg-slate-300/40 dark:bg-white/5 rounded-full overflow-hidden border border-orange-600/20 dark:border-white/10">
          <div className="h-full w-[90%] bg-orange-600 dark:bg-orange-400/40" />
        </div>
      </div>
    );
    case 'output': return (
      <div className="flex items-end gap-1 h-full pb-1">
        {[30, 60, 45, 80].map((h, i) => (
          <div
            key={i}
            style={{ animationDelay: `${i * 0.1}s` }}
            className="flex-1 bg-purple-600/40 dark:bg-white/10 rounded-t-[1px] border-t-2 border-purple-600 dark:border-white/20 animate-bar-pulse"
          />
        ))}
      </div>
    );
    case 'trigger': return (
      <div className="flex items-center justify-center h-full">
        <div className="w-8 h-8 rounded-full border-2 border-red-600/30 dark:border-red-500/20 flex items-center justify-center bg-red-600/10 dark:bg-white/5">
          <div className="w-2 h-2 bg-red-600 dark:bg-red-400 rounded-full shadow-[0_0_8px_#f87171]" />
        </div>
      </div>
    );
    case 'action': return (
      <div className="space-y-2 pt-1">
        <div className="flex gap-1">
          <div className="h-1 w-1 rounded-full bg-indigo-600 dark:bg-white/20" />
          <div className="h-1 w-1 rounded-full bg-indigo-600/60 dark:bg-white/10" />
          <div className="h-1 w-1 rounded-full bg-indigo-600/30 dark:bg-white/5" />
        </div>
        <div className="h-1.5 w-full bg-indigo-600/10 dark:bg-white/5 rounded-full border border-indigo-600/20 dark:border-white/5 overflow-hidden">
          <div className="h-full bg-indigo-600/60 dark:bg-indigo-400/40 rounded-full animate-progress-slow" />
        </div>
      </div>
    );
    case 'broadcast': return (
      <div className="flex items-center justify-center h-full pt-1">
        <div className="relative flex items-center justify-center w-12 h-12">
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              style={{ animationDelay: `${i * 0.6}s` }}
              className="absolute inset-0 rounded-full border-2 border-pink-600/40 dark:border-white/20 animate-ripple"
            />
          ))}
          <div className="relative w-3.5 h-3.5 bg-pink-600 dark:bg-pink-400 rounded-full shadow-[0_0_15px_rgba(236,72,153,0.6)] dark:shadow-[0_0_15px_rgba(236,72,153,0.4)]" />
        </div>
      </div>
    );
  }
}

function ConnectionPath({ d, delay, color }: { d: string; delay: number; color?: string }) {
  return (
    <g style={{ animationDelay: `${delay}s` }} className="animate-connection-enter">
      <path d={d} stroke={color || "url(#gradient-line)"} strokeWidth="3" fill="none" className="opacity-20" />
      <path
        d={d}
        stroke={color || "url(#gradient-line)"}
        strokeWidth="3"
        fill="none"
        strokeDasharray="8 8"
        className="animate-dash"
      />
    </g>
  );
}
