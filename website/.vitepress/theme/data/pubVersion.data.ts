// VitePress data loader - runs at build time and dev server startup
import { createHighlighter } from 'shiki';

// Type declaration for the exported data
export interface PubVersionData {
  version: string;
  versionWithCaret: string;
  pubdevCode: string;
  gitCode: string;
  pubdevHtml: string;
  gitHtml: string;
}

declare const data: PubVersionData;
export { data };

const packageName = 'vyuh_node_flow';
const gitUrl = 'https://github.com/vyuh-tech/vyuh_node_flow.git';
const gitPath = 'packages/vyuh_node_flow';

export default {
  async load() {
    // Fetch version from pub.dev
    let version = '0.20.0';
    try {
      const response = await fetch(
        `https://img.shields.io/pub/v/${packageName}.json`
      );
      if (response.ok) {
        const data = await response.json();
        version = data.value?.replace(/^v/, '') || '0.20.0';
      }
    } catch (e) {
      console.warn('Failed to fetch pub.dev version, using fallback:', e);
    }

    const versionWithCaret = `^${version}`;

    // Generate code strings
    const pubdevCode = `dependencies:
  ${packageName}: ${versionWithCaret}`;

    const gitCode = `dependencies:
  ${packageName}:
    git:
      url: ${gitUrl}
      path: ${gitPath}`;

    // Create Shiki highlighter with the same themes VitePress uses
    const highlighter = await createHighlighter({
      themes: ['github-light', 'github-dark'],
      langs: ['yaml'],
    });

    // Generate highlighted HTML for both code blocks
    const pubdevHtml = highlighter.codeToHtml(pubdevCode, {
      lang: 'yaml',
      themes: {
        light: 'github-light',
        dark: 'github-dark',
      },
    });

    const gitHtml = highlighter.codeToHtml(gitCode, {
      lang: 'yaml',
      themes: {
        light: 'github-light',
        dark: 'github-dark',
      },
    });

    return {
      version,
      versionWithCaret,
      pubdevCode,
      gitCode,
      pubdevHtml,
      gitHtml,
    };
  },
};
