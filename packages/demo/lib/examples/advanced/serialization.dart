import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

/// Example demonstrating graph serialization and deserialization
class SerializationExample extends StatefulWidget {
  const SerializationExample({super.key});

  @override
  State<SerializationExample> createState() => _SerializationExampleState();
}

class _SerializationExampleState extends State<SerializationExample> {
  late final NodeFlowController<Map<String, dynamic>> _controller;
  String _savedJson = '';
  String _statusMessage = '';
  Highlighter? _highlighter;
  CodeEditorController? _codeEditorController;

  @override
  void initState() {
    super.initState();
    _initializeHighlighter();
    _controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig(),
    );

    _createInitialGraph();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
  }

  Future<void> _initializeHighlighter() async {
    await Highlighter.initialize(['json']);

    // Use default light theme
    final theme = await HighlighterTheme.loadLightTheme();

    final highlighter = Highlighter(language: 'json', theme: theme);

    setState(() {
      _highlighter = highlighter;
      _codeEditorController = CodeEditorController(
        lightHighlighter: highlighter,
        darkHighlighter: highlighter,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createInitialGraph() {
    final node1 = Node<Map<String, dynamic>>(
      id: 'input-1',
      type: 'input',
      position: const Offset(100, 150),
      size: const Size(150, 80),
      data: {'label': 'Input', 'value': 42},
      outputPorts: const [
        Port(
          id: 'out',
          name: 'Output',
          position: PortPosition.right,
          offset: Offset(0, 20),
        ),
      ],
    );

    final node2 = Node<Map<String, dynamic>>(
      id: 'process-1',
      type: 'process',
      position: const Offset(350, 100),
      size: const Size(150, 100),
      data: {'label': 'Process A', 'operation': 'multiply'},
      inputPorts: const [
        Port(
          id: 'in',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 30),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out',
          name: 'Result',
          position: PortPosition.right,
          offset: Offset(0, 30),
        ),
      ],
    );

    final node3 = Node<Map<String, dynamic>>(
      id: 'process-2',
      type: 'process',
      position: const Offset(350, 250),
      size: const Size(150, 100),
      data: {'label': 'Process B', 'operation': 'add'},
      inputPorts: const [
        Port(
          id: 'in',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 30),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out',
          name: 'Result',
          position: PortPosition.right,
          offset: Offset(0, 30),
        ),
      ],
    );

    final node4 = Node<Map<String, dynamic>>(
      id: 'output-1',
      type: 'output',
      position: const Offset(600, 150),
      size: const Size(150, 80),
      data: {'label': 'Output', 'format': 'json'},
      inputPorts: const [
        Port(
          id: 'in1',
          name: 'Input 1',
          position: PortPosition.left,
          offset: Offset(0, 15),
        ),
        Port(
          id: 'in2',
          name: 'Input 2',
          position: PortPosition.left,
          offset: Offset(0, 45),
        ),
      ],
    );

    _controller.addNode(node1);
    _controller.addNode(node2);
    _controller.addNode(node3);
    _controller.addNode(node4);

    _controller.addConnection(
      Connection(
        id: 'conn-1',
        sourceNodeId: 'input-1',
        sourcePortId: 'out',
        targetNodeId: 'process-1',
        targetPortId: 'in',
      ),
    );

    _controller.addConnection(
      Connection(
        id: 'conn-2',
        sourceNodeId: 'input-1',
        sourcePortId: 'out',
        targetNodeId: 'process-2',
        targetPortId: 'in',
      ),
    );

    _controller.addConnection(
      Connection(
        id: 'conn-3',
        sourceNodeId: 'process-1',
        sourcePortId: 'out',
        targetNodeId: 'output-1',
        targetPortId: 'in1',
      ),
    );

    _controller.addConnection(
      Connection(
        id: 'conn-4',
        sourceNodeId: 'process-2',
        sourcePortId: 'out',
        targetNodeId: 'output-1',
        targetPortId: 'in2',
      ),
    );
  }

  void _exportGraph() {
    final graph = _controller.exportGraph();
    final jsonString = graph.toJsonString(indent: true);

    setState(() {
      _savedJson = jsonString;
      _statusMessage =
          'Graph exported successfully! '
          '(${graph.nodes.length} nodes, ${graph.connections.length} connections)';
    });

    // Show export dialog
    _showExportDialog(jsonString);
  }

  void _showExportDialog(String json) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Exported JSON',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: json));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('JSON copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy to clipboard',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _highlighter == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText.rich(
                            _highlighter!.highlight(json),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog() {
    if (_codeEditorController == null) return;

    // Set initial text
    _codeEditorController!.text = _savedJson;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Import JSON',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _codeEditorController!.text = data!.text!;
                      }
                    },
                    tooltip: 'Paste from clipboard',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: CodeEditor(
                    controller: _codeEditorController!,
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _importFromJson(_codeEditorController!.text);
                    },
                    child: const Text('Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _importFromJson(String jsonString) {
    if (jsonString.isEmpty) {
      setState(() {
        _statusMessage = 'No JSON to import!';
      });
      return;
    }

    try {
      final graph = NodeGraph.fromJsonStringMap(jsonString);
      _controller.loadGraph(graph);

      setState(() {
        _savedJson = jsonString;
        _statusMessage =
            'Graph imported successfully! '
            '(${graph.nodes.length} nodes, ${graph.connections.length} connections)';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.fitToView();
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Import failed: $e';
      });
    }
  }

  void _importGraph() {
    _showImportDialog();
  }

  void _clearGraph() {
    _controller.clearGraph();
    setState(() {
      _statusMessage = 'Graph cleared';
    });
  }

  void _resetToInitial() {
    _controller.clearGraph();
    _createInitialGraph();
    setState(() {
      _statusMessage = 'Reset to initial graph';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    Color color;
    IconData icon;

    switch (node.type) {
      case 'input':
        color = Colors.green.shade100;
        icon = Icons.input;
        break;
      case 'output':
        color = Colors.orange.shade100;
        icon = Icons.output;
        break;
      default:
        color = Colors.blue.shade100;
        icon = Icons.settings;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade700),
          const SizedBox(height: 4),
          Text(
            node.data['label'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      title: 'Save & Load',
      width: 320,
      child: NodeFlowEditor<Map<String, dynamic>>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: NodeFlowTheme.light.copyWith(
          connectionTheme: ConnectionTheme.light.copyWith(
            style: ConnectionStyles.smoothstep,
          ),
        ),
      ),
      children: [
        const Text(
          'Export your graph to JSON, clear the canvas, and import it back. '
          'Perfect for saving workflows!',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _buildActions(),
        const SizedBox(height: 16),
        if (_statusMessage.isNotEmpty) _buildStatus(),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Export', style: TextStyle(fontSize: 11)),
                onPressed: _exportGraph,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Import', style: TextStyle(fontSize: 11)),
                onPressed: _importGraph,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear', style: TextStyle(fontSize: 11)),
                onPressed: _clearGraph,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset', style: TextStyle(fontSize: 11)),
                onPressed: _resetToInitial,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
