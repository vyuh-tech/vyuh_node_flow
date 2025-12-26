'use client';

import React from 'react';
import { Image, Video, Play, Clapperboard } from 'lucide-react';

type MediaType = 'image' | 'video' | 'animation' | 'demo';

interface MediaPlaceholderProps {
  type: MediaType;
  title: string;
  description: string;
  aspectRatio?: string;
}

const mediaConfig: Record<
  MediaType,
  { icon: React.ElementType; label: string; color: string; bgColor: string }
> = {
  image: {
    icon: Image,
    label: 'Image',
    color: 'text-blue-600 dark:text-blue-400',
    bgColor: 'bg-blue-50 dark:bg-blue-950/30',
  },
  video: {
    icon: Video,
    label: 'Video',
    color: 'text-purple-600 dark:text-purple-400',
    bgColor: 'bg-purple-50 dark:bg-purple-950/30',
  },
  animation: {
    icon: Play,
    label: 'Animation',
    color: 'text-green-600 dark:text-green-400',
    bgColor: 'bg-green-50 dark:bg-green-950/30',
  },
  demo: {
    icon: Clapperboard,
    label: 'Interactive Demo',
    color: 'text-orange-600 dark:text-orange-400',
    bgColor: 'bg-orange-50 dark:bg-orange-950/30',
  },
};

export function MediaPlaceholder({
  type,
  title,
  description,
  aspectRatio = '16/9',
}: MediaPlaceholderProps) {
  const config = mediaConfig[type] || mediaConfig.image;
  const Icon = config.icon;

  return (
    <div
      className={`my-6 rounded-lg border-2 border-dashed border-slate-300 dark:border-slate-700 ${config.bgColor} overflow-hidden backdrop-blur-sm`}
    >
      <div
        className="flex flex-col items-center justify-center p-8"
        style={{ aspectRatio }}
      >
        <div className={`flex items-center gap-2 mb-3 ${config.color}`}>
          <Icon className="w-8 h-8" />
          <span className="text-sm font-bold uppercase tracking-widest font-heading">
            {config.label}
          </span>
        </div>

        <h4 className="text-lg font-black text-slate-900 dark:text-white text-center mb-2 font-heading">
          {title}
        </h4>

        <p className="text-sm text-slate-600 dark:text-slate-400 text-center max-w-md leading-relaxed font-medium">
          {description}
        </p>

        <div className="mt-4 px-3 py-1 bg-slate-200 dark:bg-slate-800 rounded-full">
          <span className="text-xs text-slate-500 dark:text-slate-500 font-mono font-bold tracking-tighter">
            PROTOTYPE PREVIEW
          </span>
        </div>
      </div>
    </div>
  );
}

// Named exports for convenience
export function ImagePlaceholder(props: Omit<MediaPlaceholderProps, 'type'>) {
  return <MediaPlaceholder {...props} type="image" />;
}
export function VideoPlaceholder(props: Omit<MediaPlaceholderProps, 'type'>) {
  return <MediaPlaceholder {...props} type="video" />;
}
export function AnimationPlaceholder(props: Omit<MediaPlaceholderProps, 'type'>) {
  return <MediaPlaceholder {...props} type="animation" />;
}
export function DemoPlaceholder(props: Omit<MediaPlaceholderProps, 'type'>) {
  return <MediaPlaceholder {...props} type="demo" />;
}

export default MediaPlaceholder;