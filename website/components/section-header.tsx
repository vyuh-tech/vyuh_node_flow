import { CheckCircle2 } from 'lucide-react';
import { ReactNode } from 'react';

interface SectionHeaderProps {
  icon?: ReactNode;
  tag?: string;
  tagColor?: 'blue' | 'purple' | 'green' | 'amber' | 'pink';
  title: string;
  subtitle?: string;
  features?: string[];
  align?: 'left' | 'center';
  size?: 'default' | 'large';
}

const colorClasses = {
  blue: {
    bg: 'bg-blue-500/10',
    border: 'border-blue-500/20',
    text: 'text-blue-600 dark:text-blue-400',
    icon: 'text-blue-500',
  },
  purple: {
    bg: 'bg-purple-500/10',
    border: 'border-purple-500/20',
    text: 'text-purple-600 dark:text-purple-400',
    icon: 'text-purple-500',
  },
  green: {
    bg: 'bg-green-500/10',
    border: 'border-green-500/20',
    text: 'text-green-600 dark:text-green-400',
    icon: 'text-green-500',
  },
  amber: {
    bg: 'bg-amber-500/10',
    border: 'border-amber-500/20',
    text: 'text-amber-600 dark:text-amber-400',
    icon: 'text-amber-500',
  },
  pink: {
    bg: 'bg-pink-500/10',
    border: 'border-pink-500/20',
    text: 'text-pink-600 dark:text-pink-400',
    icon: 'text-pink-500',
  },
};

export function SectionHeader({
  icon,
  tag,
  tagColor = 'blue',
  title,
  subtitle,
  features,
  align = 'center',
  size = 'default',
}: SectionHeaderProps) {
  const colors = colorClasses[tagColor];
  const alignClass = align === 'center' ? 'text-center' : 'text-left';
  const titleSize =
    size === 'large'
      ? 'text-5xl md:text-7xl tracking-tight'
      : 'text-4xl md:text-6xl';

  return (
    <div className={`space-y-6 ${alignClass}`}>
      {/* Tag/Badge */}
      {tag && (
        <div
          className={`inline-flex items-center rounded-full ${colors.bg} border ${colors.border} px-4 py-2`}
        >
          {icon && <span className={colors.icon}>{icon}</span>}
          <span
            className={`${icon ? 'ml-3' : ''} font-bold ${colors.text} tracking-wider uppercase text-sm`}
          >
            {tag}
          </span>
        </div>
      )}

      {/* Title */}
      <h2
        className={`${titleSize} font-black font-heading text-slate-900 dark:text-white leading-tight`}
      >
        {title}
      </h2>

      {/* Subtitle */}
      {subtitle && (
        <p
          className={`text-slate-600 dark:text-slate-300 text-lg md:text-xl font-medium leading-relaxed ${
            align === 'center' ? 'max-w-3xl mx-auto' : ''
          }`}
        >
          {subtitle}
        </p>
      )}

      {/* Features List */}
      {features && features.length > 0 && (
        <ul className="grid grid-cols-1 gap-4 pt-2">
          {features.map((feat, i) => (
            <li
              key={i}
              className="flex items-center text-slate-700 dark:text-slate-400 font-bold"
            >
              <CheckCircle2 className="w-5 h-5 text-blue-500 mr-4 shrink-0" />
              {feat}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
