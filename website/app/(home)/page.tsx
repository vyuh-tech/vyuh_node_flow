import { HeroSection } from '@/components/home/hero-section';
import {
  CodeShowcaseSection,
  FeatureDeepDivesSection,
  BentoGridSection,
  MarqueeSection,
  LiveDemoSection,
  UseCasesSection,
  CTASection,
  FooterSection,
} from '@/components/home/static-sections';
import { GridBackground } from '@/components/grid-background';

export default function HomePage() {
  return (
    <main className="flex flex-col min-h-screen relative selection:bg-blue-600 selection:text-white bg-slate-50 dark:bg-slate-900 transition-colors duration-500">
      {/* Hero Section - Client Component with its own Canvas grid */}
      <HeroSection />

      {/* Content sections with SVG grid background */}
      <div className="relative">
        {/* SVG Grid Background - only for sections after hero */}
        <div className="absolute inset-0 z-0 pointer-events-none">
          <GridBackground />
        </div>

        <div className="relative z-10">
          <CodeShowcaseSection />
          <FeatureDeepDivesSection />
          <BentoGridSection />
          <MarqueeSection />
          <LiveDemoSection />
          <UseCasesSection />
          <CTASection />
          <FooterSection />
        </div>
      </div>
    </main>
  );
}
