'use client';

import { useState, useEffect } from 'react';
import { Check, Copy, Eye, Code2, FileCode } from 'lucide-react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { codeToHtml } from 'shiki';

function cn(...inputs: (string | undefined | null | false)[]) {
  return twMerge(clsx(inputs));
}

const EXAMPLE_CODE_DART = `import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class SimpleFlowEditor extends StatefulWidget {
  @override
  State<SimpleFlowEditor> createState() => _SimpleFlowEditorState();
}

class _SimpleFlowEditorState extends State<SimpleFlowEditor> {
  late final NodeFlowController<String> controller;

  @override
  void initState() {
    super.initState();
    // 1. Initialize the controller
    controller = NodeFlowController<String>();

    // 2. Add nodes programmatically
    controller.addNode(Node<String>(
      id: 'node-1',
      type: 'input',
      position: const Offset(100, 100),
      data: 'Start',
      outputPorts: [Port(id: 'out', name: 'Output')],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NodeFlowEditor<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        // 3. Customize node rendering
        nodeBuilder: (context, node) => Container(
          padding: EdgeInsets.all(16),
          child: Text(node.data),
        ),
      ),
    );
  }
}`;

const EXAMPLE_CODE_YAML = `name: my_awesome_app
description: A new Flutter project.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  vyuh_node_flow: any`;

export function CodeWindow() {
  const [copied, setCopied] = useState(false);
  const [activeTab, setActiveTab] = useState('main.dart');
  const [highlightedDart, setHighlightedDart] = useState<string>('');
  const [highlightedYaml, setHighlightedYaml] = useState<string>('');

  const activeCode = activeTab === 'main.dart' ? EXAMPLE_CODE_DART : EXAMPLE_CODE_YAML;

  useEffect(() => {
    // Highlight both code blocks on mount
    const highlightCode = async () => {
      const dartHtml = await codeToHtml(EXAMPLE_CODE_DART, {
        lang: 'dart',
        theme: 'github-dark',
      });
      setHighlightedDart(dartHtml);

      const yamlHtml = await codeToHtml(EXAMPLE_CODE_YAML, {
        lang: 'yaml',
        theme: 'github-dark',
      });
      setHighlightedYaml(yamlHtml);
    };

    highlightCode();
  }, []);

  const onCopy = () => {
    navigator.clipboard.writeText(activeCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const highlightedCode = activeTab === 'main.dart' ? highlightedDart : highlightedYaml;

  return (
    <div className="relative w-full max-w-3xl mx-auto rounded-xl overflow-hidden shadow-2xl bg-[#1e1e1e] border border-white/10 font-mono text-sm flex flex-col h-[600px]">
      {/* Window Title Bar */}
      <div className="flex items-center justify-between px-4 py-3 bg-[#252526] border-b border-white/5 shrink-0">
        <div className="flex items-center gap-4">
          <div className="flex gap-1.5">
            <div className="w-3 h-3 rounded-full bg-[#ff5f56]" />
            <div className="w-3 h-3 rounded-full bg-[#ffbd2e]" />
            <div className="w-3 h-3 rounded-full bg-[#27c93f]" />
          </div>
          <div className="flex gap-1 bg-black/20 rounded-lg p-1">
             <button
                onClick={() => setActiveTab('main.dart')}
                className={cn(
                    "px-3 py-1.5 rounded-md text-xs font-medium transition-all flex items-center gap-2",
                    activeTab === 'main.dart'
                      ? "bg-[#37373d] text-white shadow-sm"
                      : "text-gray-400 hover:text-gray-200 hover:bg-white/5"
                )}
             >
                <Code2 className="w-3.5 h-3.5" />
                main.dart
             </button>
             <button
                onClick={() => setActiveTab('pubspec.yaml')}
                className={cn(
                    "px-3 py-1.5 rounded-md text-xs font-medium transition-all flex items-center gap-2",
                    activeTab === 'pubspec.yaml'
                      ? "bg-[#37373d] text-white shadow-sm"
                      : "text-gray-400 hover:text-gray-200 hover:bg-white/5"
                )}
             >
                <FileCode className="w-3.5 h-3.5" />
                pubspec.yaml
             </button>
             <button
                onClick={() => setActiveTab('preview')}
                className={cn(
                    "px-3 py-1.5 rounded-md text-xs font-medium transition-all flex items-center gap-2",
                    activeTab === 'preview'
                      ? "bg-[#37373d] text-white shadow-sm"
                      : "text-gray-400 hover:text-gray-200 hover:bg-white/5"
                )}
             >
                <Eye className="w-3.5 h-3.5" />
                Preview
             </button>
          </div>
        </div>

        {activeTab !== 'preview' && (
          <button
            onClick={onCopy}
            className="p-2 hover:bg-white/10 rounded-md transition-colors text-gray-400 hover:text-white"
            title="Copy code"
          >
            {copied ? <Check className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
          </button>
        )}
      </div>

      {/* Content Area */}
      <div className="relative flex-1 overflow-hidden bg-[#1e1e1e]">
        {activeTab === 'preview' ? (
          <div className="absolute inset-0 bg-white">
            <iframe
              src="https://flow.demo.vyuh.tech"
              className="w-full h-full border-none"
              title="Vyuh Node Flow Demo"
              loading="lazy"
            />
          </div>
        ) : (
          <div
            className="absolute inset-0 overflow-auto p-6 [&_pre]:!bg-transparent [&_pre]:!m-0 [&_pre]:!p-0 [&_code]:font-mono [&_.line]:table-row [&_.line::before]:table-cell [&_.line::before]:select-none [&_.line::before]:text-gray-600 [&_.line::before]:text-right [&_.line::before]:pr-6 [&_.line::before]:opacity-40 [&_.line::before]:text-xs [&_.line::before]:content-[counter(line)] [&_.line::before]:counter-increment-[line] [&_pre]:counter-reset-[line]"
            style={{ fontFamily: "'JetBrains Mono', monospace" }}
            dangerouslySetInnerHTML={{ __html: highlightedCode || `<pre><code>${activeCode}</code></pre>` }}
          />
        )}
      </div>

    </div>
  );
}
