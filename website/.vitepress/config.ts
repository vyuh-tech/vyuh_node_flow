import { defineConfig } from 'vitepress';
import tailwindcss from '@tailwindcss/vite';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  vite: {
    plugins: [
      tailwindcss(),
      // Bundle analyzer - generates stats.html after build
      visualizer({
        filename: '.vitepress/dist/stats.html',
        open: false,
        gzipSize: true,
        brotliSize: true,
      }),
    ],
  },

  // Configure Shiki for minimal bundle size
  // See: https://shiki.style/guide/bundles
  markdown: {
    theme: {
      light: 'github-light',
      dark: 'github-dark',
    },
  },

  appearance: true, // Enable dark mode toggle

  title: 'Vyuh Node Flow',
  description:
    'A flexible, high-performance node-based flow editor for Flutter applications',
  cleanUrls: true,

  head: [
    // Preconnect for faster resource loading
    ['link', { rel: 'preconnect', href: 'https://fonts.googleapis.com' }],
    ['link', { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' }],
    ['link', { rel: 'preconnect', href: 'https://api.iconify.design' }],
    ['link', { rel: 'preconnect', href: 'https://flow.demo.vyuh.tech' }],
    // Non-blocking font loading (moved from CSS @import for better performance)
    ['link', {
      rel: 'stylesheet',
      href: 'https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400&family=Montserrat:wght@400;600;800;900&display=swap',
      media: 'print',
      onload: "this.media='all'"
    }],
    // Fallback for browsers with JS disabled
    ['noscript', {}, '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400&family=Montserrat:wght@400;600;800;900&display=swap">'],
    ['link', { rel: 'icon', href: '/icon.svg', type: 'image/svg+xml' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'Vyuh Node Flow - Visual Flow Editor for Flutter' }],
    ['meta', { property: 'og:description', content: 'A flexible, high-performance node-based flow editor for building workflow editors, visual programming interfaces, and interactive diagrams in Flutter.' }],
    ['meta', { property: 'og:image', content: 'https://flow.vyuh.tech/node-flow-banner.png' }],
    ['meta', { property: 'og:url', content: 'https://flow.vyuh.tech' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: 'Vyuh Node Flow - Visual Flow Editor for Flutter' }],
    ['meta', { name: 'twitter:description', content: 'A flexible, high-performance node-based flow editor for building workflow editors, visual programming interfaces, and interactive diagrams in Flutter.' }],
    ['meta', { name: 'twitter:image', content: 'https://flow.vyuh.tech/node-flow-banner.png' }],
  ],

  // Ignore dead links to planned pages that don't exist yet
  ignoreDeadLinks: [
    /\/docs\/advanced\/validation/,
    /\/docs\/advanced\/connection-labels/,
    /\/docs\/api\/shortcuts-actions/,
    /\/docs\/api\/custom-port-shapes/,
    /\/docs\/theming\/node-theme/,
    /\/docs\/theming\/connection-theme/,
    /\/docs\/examples\/custom-nodes/,
    /\/docs\/examples\/custom-ports/,
  ],

  themeConfig: {
    logo: '/icon.svg',

    nav: [
      { text: 'Docs', link: '/docs/getting-started/installation' },
      { text: 'Examples', link: '/docs/examples/' },
      { component: 'NavProBadge' },
      {
        text: 'Links',
        items: [
          {
            text: 'GitHub',
            link: 'https://github.com/vyuh-tech/vyuh_node_flow',
          },
          {
            text: 'pub.dev',
            link: 'https://pub.dev/packages/vyuh_node_flow',
          },
          { text: 'Live Demo', link: 'https://flow.demo.vyuh.tech' },
        ],
      },
    ],

    sidebar: {
      '/docs/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Installation', link: '/docs/getting-started/installation' },
            { text: 'Quick Start', link: '/docs/getting-started/quick-start' },
          ],
        },
        {
          text: 'Core Concepts',
          items: [
            { text: 'Architecture', link: '/docs/core-concepts/architecture' },
            { text: 'Controller', link: '/docs/core-concepts/controller' },
            { text: 'Configuration', link: '/docs/core-concepts/configuration' },
            { text: 'Nodes', link: '/docs/core-concepts/nodes' },
            { text: 'Ports', link: '/docs/core-concepts/ports' },
            { text: 'Connections', link: '/docs/core-concepts/connections' },
          ],
        },
        {
          text: 'Components',
          items: [
            { text: 'NodeFlowEditor', link: '/docs/components/node-flow-editor' },
            { text: 'NodeFlowViewer', link: '/docs/components/node-flow-viewer' },
            { text: 'NodeWidget', link: '/docs/components/node-widget' },
            { text: 'PortWidget', link: '/docs/components/port-widget' },
            { text: 'ConnectionsLayer', link: '/docs/components/connections-layer' },
            { text: 'Special Node Types', link: '/docs/components/special-node-types' },
            { text: 'Minimap', link: '/docs/components/minimap' },
          ],
        },
        {
          text: 'Examples',
          items: [{ text: 'Overview', link: '/docs/examples/' }],
        },
        {
          text: 'Theming',
          items: [
            { text: 'Overview', link: '/docs/theming/overview' },
            { text: 'Connection Styles', link: '/docs/theming/connection-styles' },
            { text: 'Connection Effects', link: '/docs/theming/connection-effects' },
            { text: 'Port Shapes', link: '/docs/theming/port-shapes' },
            { text: 'Port Labels', link: '/docs/theming/port-labels' },
            { text: 'Grid Styles', link: '/docs/theming/grid-styles' },
            { text: 'Node Shapes', link: '/docs/theming/node-shapes' },
          ],
        },
        {
          text: 'Advanced',
          items: [
            { text: 'Special Node Types', link: '/docs/advanced/special-node-types' },
            { text: 'Level of Detail (LOD)', link: '/docs/advanced/lod' },
            { text: 'Events', link: '/docs/advanced/events' },
            { text: 'Serialization', link: '/docs/advanced/serialization' },
            { text: 'Keyboard Shortcuts', link: '/docs/advanced/keyboard-shortcuts' },
            { text: 'Shortcuts & Actions', link: '/docs/advanced/shortcuts-actions' },
          ],
        },
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/docs/api-reference/' },
            { text: 'Controller', link: '/docs/api-reference/controller' },
            { text: 'Node', link: '/docs/api-reference/node' },
            { text: 'Port', link: '/docs/api-reference/port' },
            { text: 'Connection', link: '/docs/api-reference/connection' },
            { text: 'Events', link: '/docs/api-reference/events' },
            { text: 'Theme', link: '/docs/api-reference/theme' },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/vyuh-tech/vyuh_node_flow' },
    ],

    search: {
      provider: 'local',
    },

    editLink: {
      pattern:
        'https://github.com/vyuh-tech/vyuh_node_flow/edit/main/website/:path',
    },
  },
});
