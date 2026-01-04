import {defineConfig} from 'vitepress';
import tailwindcss from '@tailwindcss/vite';
import {visualizer} from 'rollup-plugin-visualizer';

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
        // Google Analytics 4
        [
            'script',
            {
                async: '',
                src: 'https://www.googletagmanager.com/gtag/js?id=G-5JHR3XB6XK',
            },
        ],
        [
            'script',
            {},
            `
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'G-5JHR3XB6XK');
    `,
        ],

        // Preconnect for faster resource loading
        ['link', {rel: 'preconnect', href: 'https://fonts.googleapis.com'}],
        [
            'link',
            {rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: ''},
        ],
        ['link', {rel: 'preconnect', href: 'https://api.iconify.design'}],
        ['link', {rel: 'preconnect', href: 'https://flow.demo.vyuh.tech'}],
        // Non-blocking font loading - reduced weights for faster load
        // Montserrat: 400 (regular body), 600 (semibold), 700 (bold), 900 (black for headers)
        // JetBrains Mono: 400 only (code doesn't need variants)
        [
            'link',
            {
                rel: 'stylesheet',
                href: 'https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400&family=Montserrat:wght@400;600;700;900&display=swap',
                media: 'print',
                onload: "this.media='all'",
            },
        ],
        // Fallback for browsers with JS disabled
        [
            'noscript',
            {},
            '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400&family=Montserrat:wght@400;600;700;900&display=swap">',
        ],
        ['link', {rel: 'icon', href: '/icon.svg', type: 'image/svg+xml'}],
        ['meta', {property: 'og:type', content: 'website'}],
        [
            'meta',
            {
                property: 'og:title',
                content: 'Vyuh Node Flow - Visual Flow Editor for Flutter',
            },
        ],
        [
            'meta',
            {
                property: 'og:description',
                content:
                    'A flexible, high-performance node-based flow editor for building workflow editors, visual programming interfaces, and interactive diagrams in Flutter.',
            },
        ],
        [
            'meta',
            {
                property: 'og:image',
                content: 'https://flow.vyuh.tech/node-flow-banner.png',
            },
        ],
        ['meta', {property: 'og:url', content: 'https://flow.vyuh.tech'}],
        ['meta', {name: 'twitter:card', content: 'summary_large_image'}],
        [
            'meta',
            {
                name: 'twitter:title',
                content: 'Vyuh Node Flow - Visual Flow Editor for Flutter',
            },
        ],
        [
            'meta',
            {
                name: 'twitter:description',
                content:
                    'A flexible, high-performance node-based flow editor for building workflow editors, visual programming interfaces, and interactive diagrams in Flutter.',
            },
        ],
        [
            'meta',
            {
                name: 'twitter:image',
                content: 'https://flow.vyuh.tech/node-flow-banner.png',
            },
        ],
    ],

    // Ignore dead links to planned pages that don't exist yet
    ignoreDeadLinks: [],

    themeConfig: {
        logo: '/icon.svg',

        nav: [
            {text: 'Docs', link: '/docs/start/installation'},
            {text: 'Examples', link: '/docs/examples/'},
            {component: 'NavProBadge'},
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
                    {text: 'Live Demo', link: 'https://flow.demo.vyuh.tech'},
                ],
            },
        ],

        sidebar: {
            '/docs/': [
                {
                    text: 'Getting Started',
                    items: [
                        {
                            text: 'Installation',
                            link: '/docs/start/installation',
                        },
                        {text: 'Quick Start', link: '/docs/start/quick-start'},
                    ],
                },
                {
                    text: 'Core Concepts',
                    items: [
                        {text: 'Architecture', link: '/docs/concepts/architecture'},
                        {text: 'Controller', link: '/docs/concepts/controller'},
                        {
                            text: 'Configuration',
                            link: '/docs/concepts/configuration',
                        },
                        {text: 'Nodes', link: '/docs/concepts/nodes'},
                        {text: 'Ports', link: '/docs/concepts/ports'},
                        {text: 'Connections', link: '/docs/concepts/connections'},
                        {text: 'Extensions', link: '/docs/concepts/extensions'},
                    ],
                },
                {
                    text: 'Components',
                    items: [
                        {
                            text: 'NodeFlowEditor',
                            link: '/docs/components/node-flow-editor',
                        },
                        {
                            text: 'NodeFlowViewer',
                            link: '/docs/components/node-flow-viewer',
                        },
                        {text: 'NodeWidget', link: '/docs/components/node-widget'},
                        {text: 'PortWidget', link: '/docs/components/port-widget'},
                        {
                            text: 'ConnectionsLayer',
                            link: '/docs/components/connections-layer',
                        },
                        {
                            text: 'Special Node Types',
                            link: '/docs/components/special-node-types',
                        },
                    ],
                },
                {
                    text: 'Extensions',
                    items: [
                        {text: 'Minimap', link: '/docs/extensions/minimap'},
                        {text: 'AutoPan', link: '/docs/extensions/autopan'},
                        {text: 'Level of Detail (LOD)', link: '/docs/extensions/lod'},
                        {text: 'Debug', link: '/docs/extensions/debug'},
                        {text: 'Stats', link: '/docs/extensions/stats'},
                    ],
                },
                {
                    text: 'Examples',
                    items: [{text: 'Overview', link: '/docs/examples/'}],
                },
                {
                    text: 'Theming',
                    items: [
                        {text: 'Overview', link: '/docs/theming/overview'},
                        {
                            text: 'Connection Styles',
                            link: '/docs/theming/connection-styles',
                        },
                        {
                            text: 'Connection Effects',
                            link: '/docs/theming/connection-effects',
                        },
                        {text: 'Port Shapes', link: '/docs/theming/port-shapes'},
                        {text: 'Port Labels', link: '/docs/theming/port-labels'},
                        {text: 'Grid Styles', link: '/docs/theming/grid-styles'},
                        {text: 'Node Shapes', link: '/docs/theming/node-shapes'},
                    ],
                },
                {
                    text: 'Advanced',
                    items: [
                        {
                            text: 'Special Node Types',
                            link: '/docs/advanced/special-node-types',
                        },
                        {
                            text: 'Viewport Animations',
                            link: '/docs/advanced/viewport-animations',
                        },
                        {text: 'Events', link: '/docs/advanced/events'},
                        {text: 'Serialization', link: '/docs/advanced/serialization'},
                        {
                            text: 'Keyboard Shortcuts',
                            link: '/docs/advanced/keyboard-shortcuts',
                        },
                        {
                            text: 'Shortcuts & Actions',
                            link: '/docs/advanced/shortcuts-actions',
                        },
                    ],
                },
                {
                    text: 'API',
                    items: [
                        {text: 'Overview', link: '/docs/api/'},
                        {text: 'Controller', link: '/docs/api/controller'},
                        {text: 'Node', link: '/docs/api/node'},
                        {text: 'Port', link: '/docs/api/port'},
                        {text: 'Connection', link: '/docs/api/connection'},
                        {text: 'Events', link: '/docs/api/events'},
                        {text: 'Theme', link: '/docs/api/theme'},
                    ],
                },
            ],
        },

        socialLinks: [
            {icon: 'github', link: 'https://github.com/vyuh-tech/vyuh_node_flow'},
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
