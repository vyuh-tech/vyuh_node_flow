import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';
import { Montserrat, JetBrains_Mono } from 'next/font/google';
import type { Metadata } from 'next';

const fontSans = Montserrat({
  subsets: ['latin'],
  variable: '--font-sans',
});

const fontMono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-mono',
  weight: ['400', '500', '600', '700'],
  display: 'swap',
});

export const metadata: Metadata = {
  title: {
    default: 'Vyuh Node Flow',
    template: '%s | Vyuh Node Flow',
  },
  description:
    'A flexible, high-performance node-based flow editor for Flutter applications.',
  icons: {
    icon: '/favicon.ico',
  },
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className={`${fontSans.variable} ${fontMono.variable}`}
      suppressHydrationWarning
    >
      <body className="flex flex-col min-h-screen">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
