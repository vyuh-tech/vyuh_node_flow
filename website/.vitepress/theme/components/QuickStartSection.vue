<script setup lang="ts">
import { computed } from 'vue';
import Section from './Section.vue';
import SectionHeader from './SectionHeader.vue';
import TabbedCodePreview, { type CodeTab } from './TabbedCodePreview.vue';
import { data as pubData } from '../data/pubVersion.data';

// Import code sample as raw text
import mainDartCode from '../code-samples/quick-start.dart?raw';

// Code markers for main.dart
const mainDartMarkers = [
  {
    line: 4,
    title: 'App Entry',
    description:
      'Standard Flutter entry point with MaterialApp wrapping the flow editor.',
  },
  {
    line: 13,
    title: 'Controller Setup',
    description:
      'NodeFlowController manages the graph state. Define nodes with positions, data, and ports. Connections link output ports to input ports.',
  },
  {
    line: 31,
    title: 'NodeFlowEditor',
    description:
      'The editor widget renders the canvas with pan, zoom, drag, and connection creation built-in.',
  },
  {
    line: 37,
    title: 'Node Builder',
    description:
      'Customize how each node looks. Receives node data to render any Flutter widget.',
  },
];

// Dynamic pubspec.yaml with fetched version
const pubspecCode = computed(() => {
  return `name: my_flow_app
description: A node-based flow editor app

environment:
  sdk: ^3.9.0
  flutter: ">=3.35.0"

dependencies:
  flutter:
    sdk: flutter

  vyuh_node_flow: ${pubData.versionWithCaret}  # [!code focus]

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0`;
});

// Code tabs configuration - reactive to version changes
const codeTabs = computed<CodeTab[]>(() => [
  {
    id: 'main',
    label: 'main.dart',
    icon: 'simple-icons:dart',
    code: mainDartCode,
    filename: 'main.dart',
    lang: 'dart',
    markers: mainDartMarkers,
  },
  {
    id: 'pubspec',
    label: 'pubspec.yaml',
    icon: 'ph:file-text-fill',
    code: pubspecCode.value,
    filename: 'pubspec.yaml',
    lang: 'yaml',
  },
  {
    id: 'preview',
    label: 'Preview',
    icon: 'ph:play-fill',
    isPreview: true,
    previewUrl:
      'https://flow.demo.vyuh.tech/#/getting-started/simple?embed=true',
    previewTitle: 'Simple Flow Editor',
  },
]);
</script>

<template>
  <Section first background size="sm">
    <SectionHeader
      badge="Quick Start"
      badge-icon="simple-icons:flutter"
      badge-color="blue"
      title="Simple & Intuitive API"
      centered
    />
    <TabbedCodePreview :tabs="codeTabs" />
  </Section>
</template>
