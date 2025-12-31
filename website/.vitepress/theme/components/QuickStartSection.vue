<script setup lang="ts">
import { computed } from 'vue';
import Section from './Section.vue';
import SectionHeader from './SectionHeader.vue';
import TabbedCodePreview, { type CodeTab } from './TabbedCodePreview.vue';
import { usePubVersion } from '../composables/usePubVersion';

// Fetch latest version from pub.dev
const { version, loading } = usePubVersion('vyuh_node_flow');

// Code example for the Quick Start section - main.dart
const mainDartCode = `import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() => runApp(const MyApp()); // [!code focus]

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // [!code focus]
      title: 'Node Flow Demo',
      theme: ThemeData.light(useMaterial3: true),
      home: const SimpleFlowEditor(), // [!code focus]
    );
  }
}

class SimpleFlowEditor extends StatefulWidget {
  const SimpleFlowEditor({super.key});

  @override
  State<SimpleFlowEditor> createState() => _SimpleFlowEditorState();
}

class _SimpleFlowEditorState extends State<SimpleFlowEditor> {
  late final controller = NodeFlowController<String>( // [!code focus]
    nodes: [
      Node<String>(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(150, 60),
        data: 'Input Node',
        outputPorts: const [Port(id: 'out')],
      ),
      Node<String>(
        id: 'node-2',
        position: const Offset(400, 100),
        size: const Size(150, 60),
        data: 'Output Node',
        inputPorts: const [Port(id: 'in')],
      ),
    ],
    connections: [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'node-1', sourcePortId: 'out',
        targetNodeId: 'node-2', targetPortId: 'in',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => NodeFlowEditor<String>( // [!code focus]
    controller: controller,
    theme: NodeFlowTheme.light,
    nodeBuilder: (context, node) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: Text(node.data)),
    ),
  );
}`;

// Code markers for main.dart
const mainDartMarkers = [
  {
    line: 4,
    title: 'Entry Point',
    description:
      'Standard Flutter entry point. The app starts with MyApp which sets up MaterialApp with theming.',
  },
  {
    line: 27,
    title: 'NodeFlowController',
    description:
      'The main controller that manages nodes and connections. Provides programmatic control over the editor.',
  },
  {
    line: 54,
    title: 'NodeFlowEditor Widget',
    description:
      'The Flutter widget that renders the visual editor with pan & zoom, node dragging, and connection creation.',
  },
];

// Dynamic pubspec.yaml with fetched version
const pubspecCode = computed(() => {
  const versionStr = loading.value
    ? '^x.x.x  # Loading...'
    : `^${version.value || '0.20.0'}`;

  return `name: my_flow_app
description: A node-based flow editor app

environment:
  sdk: ^3.9.0
  flutter: ">=3.35.0"

dependencies:
  flutter:
    sdk: flutter

  vyuh_node_flow: ${versionStr}  # [!code focus]

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
    previewUrl: 'flow.demo.vyuh.tech/#/basics/simple',
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
