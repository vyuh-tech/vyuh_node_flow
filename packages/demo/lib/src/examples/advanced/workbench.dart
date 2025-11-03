import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

class WorkbenchExample extends StatefulWidget {
  const WorkbenchExample({super.key});

  @override
  State<WorkbenchExample> createState() => _WorkbenchExampleState();
}

class _WorkbenchExampleState extends State<WorkbenchExample> {
  late NodeFlowController<Map<String, dynamic>> _store;
  late NodeFlowTheme _nodeFlowTheme;
  late NodeFlowConfig _nodeFlowConfig;
  bool _isLoading = true;
  final bool _scrollToZoom = true;

  // Workflow dropdown
  String _selectedWorkflow = 'manufacturing_workflow.json';
  final List<Map<String, String>> _availableWorkflows = [
    {'file': 'simple_workflow.json', 'name': 'Simple Data Pipeline'},
    {'file': 'manufacturing_workflow.json', 'name': 'Manufacturing Process'},
    {'file': 'quality_control_workflow.json', 'name': 'Quality Control'},
    {'file': 'supply_chain_workflow.json', 'name': 'Supply Chain'},
    {'file': 'software_development_workflow.json', 'name': 'Software CI/CD'},
    {'file': 'healthcare_workflow.json', 'name': 'Healthcare Process'},
    {'file': 'iot_data_pipeline.json', 'name': 'IoT Data Pipeline'},
  ];

  @override
  void initState() {
    super.initState();
    _nodeFlowTheme = _buildInitialTheme();
    _nodeFlowConfig = _buildInitialConfig();
    _store = NodeFlowController<Map<String, dynamic>>(config: _nodeFlowConfig);
    _store.setTheme(_nodeFlowTheme); // Set initial theme in controller
    _loadInitialWorkflow();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      title: 'Workbench Controls',
      width: 320,
      child: Stack(
        children: [
          NodeFlowEditor<Map<String, dynamic>>(
            controller: _store,
            theme: _nodeFlowTheme,
            nodeBuilder: _buildCustomNode,
            scrollToZoom: _scrollToZoom,
            onConnectionCreated: (connection) {
              _showSnackBar(
                'Connection created: ${connection.sourceNodeId} → ${connection.targetNodeId}',
              );
            },
            onConnectionDeleted: (connection) {
              _showSnackBar('Connection deleted');
            },
          ),
        ],
      ),
      children: _buildControlPanelChildren(),
    );
  }

  Future<void> _loadInitialWorkflow() async {
    try {
      final graph = await _loadGraphFromJson(_selectedWorkflow);
      if (mounted) {
        setState(() {
          _store.loadGraph(graph);
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback initialization
      if (mounted) {
        setState(() {
          _store.loadGraph(_createFallbackGraph());
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWorkflow(String workflowFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final graph = await _loadGraphFromJson(workflowFile);
      setState(() {
        _store.loadGraph(graph);
        _selectedWorkflow = workflowFile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load workflow: $e')));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<NodeGraph<Map<String, dynamic>>> _loadGraphFromJson(
    String filename,
  ) async {
    try {
      return await NodeGraph.fromAssetMap('assets/data/$filename');
    } catch (e) {
      // Return empty graph if asset loading fails
      return _createFallbackGraph();
    }
  }

  NodeGraph<Map<String, dynamic>> _createFallbackGraph() {
    return NodeGraph<Map<String, dynamic>>(
      nodes: [
        Node<Map<String, dynamic>>(
          id: 'source-1',
          type: 'Source',
          position: const Offset(100, 100),
          data: {'label': 'Data Source'},
          inputPorts: [],
          outputPorts: [
            const Port(
              id: 'output',
              name: 'Out',
              position: PortPosition.right,
              offset: Offset(0, 40),
            ),
          ],
        ),
        Node<Map<String, dynamic>>(
          id: 'transform-1',
          type: 'Transform',
          position: const Offset(350, 100),
          data: {'label': 'Data Transform'},
          inputPorts: [
            const Port(
              id: 'input',
              name: 'In',

              position: PortPosition.left,
              offset: Offset(0, 50),
            ),
          ],
          outputPorts: [
            const Port(
              id: 'output',
              name: 'Out',

              position: PortPosition.right,
              offset: Offset(0, 40),
            ),
          ],
        ),
      ],
      connections: [
        Connection(
          id: 'conn-1',
          sourceNodeId: 'source-1',
          sourcePortId: 'output',
          targetNodeId: 'transform-1',
          targetPortId: 'input',
          label: 'Data Flow',
          startLabel: 'Raw',
          endLabel: 'Process',
        ),
      ],
      viewport: const GraphViewport(x: 0, y: 0, zoom: 1.0),
    );
  }

  NodeFlowTheme _buildInitialTheme() {
    final connectionStyle = ConnectionStyles.step;

    return NodeFlowTheme.light.copyWith(
      temporaryConnectionTheme: NodeFlowTheme.light.temporaryConnectionTheme
          .copyWith(
            dashPattern: [5, 5],
            strokeWidth: 2.0,
            bezierCurvature: 0.5,
          ),
      connectionStyle: connectionStyle,
      temporaryConnectionStyle: connectionStyle,
      portTheme: NodeFlowTheme.light.portTheme.copyWith(
        size: 12.0, // Increased from default 9.0 for better visibility
        borderWidth: 1.0, // Add border for better visibility
      ),
    );
  }

  NodeFlowConfig _buildInitialConfig() {
    return NodeFlowConfig(
      minZoom: 0.25,
      maxZoom: 4.0,
      snapToGrid: false,
      gridSize: 20.0,
      autoPanMargin: 50.0,
      autoPanSpeed: 0.3,
    );
  }

  List<Widget> _buildControlPanelChildren() {
    return [
      // Loading indicator
      if (_isLoading)
        const LinearProgressIndicator()
      else
        const SizedBox(height: 4),

      // Workflow Selection Dropdown
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Workflow',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedWorkflow,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _availableWorkflows.map((workflow) {
                  return DropdownMenuItem<String>(
                    value: workflow['file']!,
                    child: Text(
                      workflow['name']!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedWorkflow) {
                    _loadWorkflow(newValue);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      _buildGridSection('Graph Serialization', [
        _buildGridButton('Export JSON', Icons.download, () async {
          final graph = _store.exportGraph();
          final jsonString = graph.toJsonString(indent: true);
          await Clipboard.setData(ClipboardData(text: jsonString));
          _showSnackBar(
            'JSON exported and copied to clipboard (${jsonString.length} chars)',
          );
        }),
        _buildGridButton('Clear Graph', Icons.clear_all, () {
          _store.clearGraph();
          _showSnackBar('Cleared all nodes');
        }),
      ]),
      _buildGridSection('UI Tools', [
        _buildGridButton('Shortcuts', Icons.keyboard, () {
          _store.showShortcutsDialog(context);
        }),
        _buildGridButton('Toggle Minimap', Icons.map, _toggleMinimap),
      ]),
      _buildGridSection('Viewport Controls', [
        _buildGridButton('Zoom In', Icons.zoom_in, () => _store.zoomBy(0.2)),
        _buildGridButton('Zoom Out', Icons.zoom_out, () => _store.zoomBy(-0.2)),
        _buildGridButton(
          'Reset Zoom',
          Icons.center_focus_strong,
          () => _store.zoomTo(1.0),
        ),
        _buildGridButton(
          'Fit to View',
          Icons.fit_screen,
          () => _store.fitToView(),
        ),
        Observer(
          name: 'FitSelectedButton',
          builder: (context) => _buildGridButton(
            'Fit Selected',
            Icons.crop_free,
            _store.selectedNodeIds.isNotEmpty
                ? () => _store.fitSelectedNodes()
                : null,
          ),
        ),
        _buildGridButton(
          'Reset Viewport',
          Icons.home,
          () => _store.resetViewport(),
        ),
      ]),
      _buildGridSection('Navigation', [
        Observer(
          name: 'CenterSelectedButton',
          builder: (context) => _buildGridButton(
            'Center Selected',
            Icons.my_location,
            _store.selectedNodeIds.isNotEmpty
                ? () => _store.centerOnNode(_store.selectedNodeIds.first)
                : null,
          ),
        ),
        Observer(
          name: 'CenterSelectionButton',
          builder: (context) => _buildGridButton(
            'Center Selection',
            Icons.center_focus_weak,
            _store.selectedNodeIds.isNotEmpty
                ? () => _store.centerOnSelection()
                : null,
          ),
        ),
        _buildGridButton(
          'Pan Right',
          Icons.arrow_forward,
          () => _store.panBy(const Offset(50, 0)),
        ),
        _buildGridButton(
          'Pan Down',
          Icons.arrow_downward,
          () => _store.panBy(const Offset(0, 50)),
        ),
        _buildGridButton(
          'Pan Left',
          Icons.arrow_back,
          () => _store.panBy(const Offset(-50, 0)),
        ),
        _buildGridButton(
          'Pan Up',
          Icons.arrow_upward,
          () => _store.panBy(const Offset(0, -50)),
        ),
      ]),
      _buildGridSection('Analysis', [
        _buildGridButton('Find Orphans', Icons.search, () {
          final orphans = _store.getOrphanNodes();
          _showSnackBar('Found ${orphans.length} orphan nodes');
          if (orphans.isNotEmpty) {
            _store.selectSpecificNodes(orphans.map((n) => n.id).toList());
          }
        }),
        _buildGridButton('Detect Cycles', Icons.loop, () {
          final cycles = _store.detectCycles();
          _showSnackBar('Found ${cycles.length} cycles');
        }),
      ]),

      // Display Information - Table
      _buildStatsTable(),
    ];
  }

  Widget _buildStatsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Graph Statistics'),
        const SizedBox(height: 12),
        Observer(
          builder: (context) => DataTable(
            headingRowHeight: 0,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 36,
            columnSpacing: 16,
            horizontalMargin: 0,
            dividerThickness: 0,
            columns: const [
              DataColumn(label: SizedBox.shrink()),
              DataColumn(label: SizedBox.shrink()),
            ],
            rows: [
              _buildDataRow(
                'Selected Nodes',
                '${_store.selectedNodeIds.length}',
              ),
              _buildDataRow('Total Nodes', '${_store.nodes.length}'),
              _buildDataRow(
                'Total Connections',
                '${_store.connections.length}',
              ),
              _buildDataRow(
                'Zoom Level',
                '${_store.currentZoom.toStringAsFixed(2)}x',
              ),
              _buildDataRow(
                'Pan Offset',
                '(${_store.currentPan.dx.toInt()}, ${_store.currentPan.dy.toInt()})',
              ),
              _buildDataRow(
                'Bounds',
                '${_store.nodesBounds.size.width.toInt()} × ${_store.nodesBounds.size.height.toInt()}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  DataRow _buildDataRow(String label, String value) {
    final theme = Theme.of(context);
    return DataRow(
      cells: [
        DataCell(
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridSection(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 4,
          children: buttons,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGridButton(
    String label,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNode(
    BuildContext context,
    Node<Map<String, dynamic>> node,
  ) {
    final data = node.data;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color nodeColor;
    Color iconColor;

    switch (node.type) {
      case 'Source':
        // Soft mint green
        nodeColor = isDark ? const Color(0xFF2D4A3E) : const Color(0xFFD4F1E8);
        iconColor = isDark ? const Color(0xFF88D5B3) : const Color(0xFF1B5E3F);
        break;
      case 'Transform':
        // Soft sky blue
        nodeColor = isDark ? const Color(0xFF2D3E52) : const Color(0xFFD4E7F7);
        iconColor = isDark ? const Color(0xFF88B8E6) : const Color(0xFF1B4D7A);
        break;
      case 'Filter':
        // Soft peach
        nodeColor = isDark ? const Color(0xFF4A3D32) : const Color(0xFFFFE5D4);
        iconColor = isDark ? const Color(0xFFFFB088) : const Color(0xFF8B4513);
        break;
      case 'Sink':
        // Soft coral
        nodeColor = isDark ? const Color(0xFF4A3239) : const Color(0xFFFFD4DD);
        iconColor = isDark ? const Color(0xFFFF88AA) : const Color(0xFF8B2D47);
        break;
      case 'AllPorts':
        // Soft lavender
        nodeColor = isDark ? const Color(0xFF3E3247) : const Color(0xFFE8D4F1);
        iconColor = isDark ? const Color(0xFFC088D5) : const Color(0xFF6B2D8B);
        break;
      default:
        // Soft peach (default)
        nodeColor = isDark ? const Color(0xFF4A3D32) : const Color(0xFFFFE5D4);
        iconColor = isDark ? const Color(0xFFFFB088) : const Color(0xFF8B4513);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(color: nodeColor),
          child: Row(
            children: [
              Icon(_getNodeIcon(node.type), size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['label'] ?? node.type,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ID: ${node.id}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Z: ${node.zIndex}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getNodeIcon(String type) {
    switch (type) {
      case 'Source':
        return Icons.input;
      case 'Transform':
        return Icons.transform;
      case 'Filter':
        return Icons.filter_alt;
      case 'Sink':
        return Icons.output;
      case 'AllPorts':
        return Icons.hub;
      default:
        return Icons.circle;
    }
  }

  void _toggleMinimap() {
    _store.config.toggleMinimap();
    _showSnackBar(
      _store.config.showMinimap.value ? 'Minimap enabled' : 'Minimap disabled',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
