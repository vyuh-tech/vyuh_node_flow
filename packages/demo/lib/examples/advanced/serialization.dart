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
  final _controller = NodeFlowController<Map<String, dynamic>>(
    config: NodeFlowConfig(),
    nodes: _createNodes(),
    connections: _createConnections(),
  );
  String _savedJson = '';
  String _statusMessage = '';
  Highlighter? _highlighter;
  CodeEditorController? _codeEditorController;

  @override
  void initState() {
    super.initState();
    _initializeHighlighter();
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

  static List<Node<Map<String, dynamic>>> _createNodes() {
    return [
      Node<Map<String, dynamic>>(
        id: 'input-1',
        type: 'input',
        position: const Offset(100, 150),
        size: const Size(150, 80),
        data: {'label': 'Input', 'value': 42},
        outputPorts: [
          Port(
            id: 'out',
            name: 'Output',
            position: PortPosition.right,
            offset: Offset(2, 40), // Vertical center of 80 height
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'process-1',
        type: 'process',
        position: const Offset(350, 100),
        size: const Size(150, 100),
        data: {'label': 'Process A', 'operation': 'multiply'},
        inputPorts: [
          Port(
            id: 'in',
            name: 'Input',
            position: PortPosition.left,
            offset: Offset(-2, 50), // Vertical center of 100 height
          ),
        ],
        outputPorts: [
          Port(
            id: 'out',
            name: 'Result',
            position: PortPosition.right,
            offset: Offset(2, 50), // Vertical center of 100 height
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'process-2',
        type: 'process',
        position: const Offset(350, 250),
        size: const Size(150, 100),
        data: {'label': 'Process B', 'operation': 'add'},
        inputPorts: [
          Port(
            id: 'in',
            name: 'Input',
            position: PortPosition.left,
            offset: Offset(-2, 50), // Vertical center of 100 height
          ),
        ],
        outputPorts: [
          Port(
            id: 'out',
            name: 'Result',
            position: PortPosition.right,
            offset: Offset(2, 50), // Vertical center of 100 height
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'output-1',
        type: 'output',
        position: const Offset(600, 150),
        size: const Size(150, 80),
        data: {'label': 'Output', 'format': 'json'},
        inputPorts: [
          Port(
            id: 'in1',
            name: 'Input 1',
            position: PortPosition.left,
            offset: Offset(-2, 20), // Multiple ports: starting offset 20
          ),
          Port(
            id: 'in2',
            name: 'Input 2',
            position: PortPosition.left,
            offset: Offset(-2, 50), // Multiple ports: 20 + 30 separation
          ),
        ],
      ),
    ];
  }

  static List<Connection> _createConnections() {
    return [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'input-1',
        sourcePortId: 'out',
        targetNodeId: 'process-1',
        targetPortId: 'in',
      ),
      Connection(
        id: 'conn-2',
        sourceNodeId: 'input-1',
        sourcePortId: 'out',
        targetNodeId: 'process-2',
        targetPortId: 'in',
      ),
      Connection(
        id: 'conn-3',
        sourceNodeId: 'process-1',
        sourcePortId: 'out',
        targetNodeId: 'output-1',
        targetPortId: 'in1',
      ),
      Connection(
        id: 'conn-4',
        sourceNodeId: 'process-2',
        sourcePortId: 'out',
        targetNodeId: 'output-1',
        targetPortId: 'in2',
      ),
    ];
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

      _controller.fitToView();
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
    // Re-add nodes and connections from static methods
    for (final node in _createNodes()) {
      _controller.addNode(node);
    }
    for (final connection in _createConnections()) {
      _controller.addConnection(connection);
    }
    setState(() {
      _statusMessage = 'Reset to initial graph';
    });
    _controller.fitToView();
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
        events: NodeFlowEvents(onInit: () => _controller.fitToView()),
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
        ControlButton(
          icon: Icons.upload,
          label: 'Export',
          onPressed: _exportGraph,
        ),
        const SizedBox(height: 8),
        ControlButton(
          icon: Icons.download,
          label: 'Import',
          onPressed: _importGraph,
        ),
        const SizedBox(height: 8),
        ControlButton(
          icon: Icons.clear,
          label: 'Clear',
          onPressed: _clearGraph,
        ),
        const SizedBox(height: 8),
        ControlButton(
          icon: Icons.refresh,
          label: 'Reset',
          onPressed: _resetToInitial,
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
