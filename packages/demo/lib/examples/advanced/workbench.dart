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
  late NodeFlowController<Map<String, dynamic>> _controller;
  late NodeFlowTheme _nodeFlowTheme;
  late NodeFlowConfig _nodeFlowConfig;
  bool _isLoading = true;
  final bool _scrollToZoom = true;

  // Workflow dropdown
  String _selectedWorkflow = 'simple_workflow.json';
  final List<Map<String, String>> _availableWorkflows = [
    {'file': 'simple_workflow.json', 'name': 'Simple Data Pipeline'},
    {'file': 'manufacturing_workflow.json', 'name': 'Manufacturing Process'},
    {'file': 'quality_control_workflow.json', 'name': 'Quality Control'},
    {'file': 'supply_chain_workflow.json', 'name': 'Supply Chain'},
    {'file': 'software_development_workflow.json', 'name': 'Software CI/CD'},
    {'file': 'database_schema.json', 'name': 'E-Commerce Database'},
    {'file': 'iot_data_pipeline.json', 'name': 'IoT Data Pipeline'},
  ];

  // Connection effect dropdown
  String _selectedEffect = 'none';
  final List<Map<String, String>> _availableEffects = [
    {'value': 'none', 'name': 'None'},
    {'value': 'flowing_dash', 'name': 'Flowing Dash'},
    {'value': 'particle', 'name': 'Particle'},
    {'value': 'gradient_flow', 'name': 'Gradient Flow'},
    {'value': 'pulse', 'name': 'Pulse'},
  ];

  @override
  void initState() {
    super.initState();
    _nodeFlowTheme = _buildInitialTheme();
    _nodeFlowConfig = _buildInitialConfig();
    _controller = NodeFlowController<Map<String, dynamic>>(
      config: _nodeFlowConfig,
    );
    _controller.setTheme(_nodeFlowTheme); // Set initial theme in controller
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
            controller: _controller,
            theme: _nodeFlowTheme,
            nodeBuilder: _buildCustomNode,
            scrollToZoom: _scrollToZoom,
            events: NodeFlowEvents<Map<String, dynamic>>(
              connection: ConnectionEvents<Map<String, dynamic>>(
                onCreated: (connection) {
                  _showSnackBar(
                    'Connection created: ${connection.sourceNodeId} → ${connection.targetNodeId}',
                  );
                },
                onDeleted: (connection) {
                  _showSnackBar('Connection deleted');
                },
              ),
            ),
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
          _controller.loadGraph(graph);
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.fitToView();
        });
      }
    } catch (e) {
      // Fallback initialization
      if (mounted) {
        setState(() {
          _controller.loadGraph(_createFallbackGraph());
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
        _controller.loadGraph(graph);
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
          startLabel: ConnectionLabel.start(text: 'Raw'),
          label: ConnectionLabel.center(text: 'Data Flow'),
          endLabel: ConnectionLabel.end(text: 'Process'),
        ),
      ],
      viewport: const GraphViewport(x: 0, y: 0, zoom: 1.0),
    );
  }

  NodeFlowTheme _buildInitialTheme() {
    return NodeFlowTheme.light.copyWith(
      connectionTheme: ConnectionTheme.light.copyWith(
        style: ConnectionStyles.step,
      ),
      temporaryConnectionTheme: NodeFlowTheme.light.temporaryConnectionTheme
          .copyWith(
            style: ConnectionStyles.step,
            dashPattern: [5, 5],
            strokeWidth: 2.0,
            bezierCurvature: 0.5,
          ),
      portTheme: NodeFlowTheme.light.portTheme.copyWith(
        size: 12.0, // Increased from default 9.0 for better visibility
        borderWidth: 1.0, // Add border for better visibility
      ),
    );
  }

  ConnectionEffect? _createAnimationEffect(String effectType) {
    switch (effectType) {
      case 'flowing_dash':
        return FlowingDashEffect(speed: 2, dashLength: 10, gapLength: 5);
      case 'particle':
        return ParticleEffect(particleCount: 3, speed: 1);
      case 'gradient_flow':
        return GradientFlowEffect(
          colors: [Colors.transparent, Colors.deepOrange],
          gradientLength: 0.25,
          speed: 1,
        );
      case 'pulse':
        return PulseEffect(
          speed: 1,
          minOpacity: 0.25,
          maxOpacity: 1.0,
          widthVariation: 1.25,
        );
      case 'none':
      default:
        return null;
    }
  }

  void _updateConnectionEffect(String effectType) {
    setState(() {
      _selectedEffect = effectType;
      _nodeFlowTheme = _nodeFlowTheme.copyWith(
        connectionTheme: _nodeFlowTheme.connectionTheme.copyWith(
          animationEffect: _createAnimationEffect(effectType),
        ),
      );
    });
  }

  NodeFlowConfig _buildInitialConfig() {
    return NodeFlowConfig(
      minZoom: 0.25,
      maxZoom: 4.0,
      snapToGrid: false,
      gridSize: 20.0,
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

      // Connection Effect Selection Dropdown
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connection Effect',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedEffect,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _availableEffects.map((effect) {
                  return DropdownMenuItem<String>(
                    value: effect['value']!,
                    child: Text(
                      effect['name']!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedEffect) {
                    _updateConnectionEffect(newValue);
                  }
                },
              ),
            ],
          ),
        ),
      ),

      _buildGridSection('Graph Serialization', [
        GridButton(
          label: 'Export JSON',
          icon: Icons.download,
          onPressed: () async {
            final graph = _controller.exportGraph();
            final jsonString = graph.toJsonString(indent: true);
            await Clipboard.setData(ClipboardData(text: jsonString));
            _showSnackBar(
              'JSON exported and copied to clipboard (${jsonString.length} chars)',
            );
          },
        ),
        GridButton(
          label: 'Clear Graph',
          icon: Icons.clear_all,
          onPressed: () {
            _controller.clearGraph();
            _showSnackBar('Cleared all nodes');
          },
        ),
      ]),
      _buildGridSection('UI Tools', [
        GridButton(
          label: 'Shortcuts',
          icon: Icons.keyboard,
          onPressed: () {
            _controller.showShortcutsDialog(context);
          },
        ),
        GridButton(
          label: 'Toggle Minimap',
          icon: Icons.map,
          onPressed: _toggleMinimap,
        ),
      ]),
      _buildGridSection('Viewport Controls', [
        GridButton(
          label: 'Zoom In',
          icon: Icons.zoom_in,
          onPressed: () => _controller.zoomBy(0.2),
        ),
        GridButton(
          label: 'Zoom Out',
          icon: Icons.zoom_out,
          onPressed: () => _controller.zoomBy(-0.2),
        ),
        GridButton(
          label: 'Reset Zoom',
          icon: Icons.center_focus_strong,
          onPressed: () => _controller.zoomTo(1.0),
        ),
        GridButton(
          label: 'Fit to View',
          icon: Icons.fit_screen,
          onPressed: () => _controller.fitToView(),
        ),
        Observer(
          name: 'FitSelectedButton',
          builder: (context) => GridButton(
            label: 'Fit Selected',
            icon: Icons.crop_free,
            onPressed: _controller.selectedNodeIds.isNotEmpty
                ? () => _controller.fitSelectedNodes()
                : null,
          ),
        ),
        GridButton(
          label: 'Reset Viewport',
          icon: Icons.home,
          onPressed: () => _controller.resetViewport(),
        ),
        GridButton(
          label: 'Center Viewport',
          icon: Icons.filter_center_focus,
          onPressed: () => _controller.centerViewport(),
        ),
      ]),
      _buildGridSection('Navigation', [
        Observer(
          name: 'CenterSelectedButton',
          builder: (context) => GridButton(
            label: 'Center Selected',
            icon: Icons.my_location,
            onPressed: _controller.selectedNodeIds.isNotEmpty
                ? () => _controller.centerOnNode(
                    _controller.selectedNodeIds.first,
                  )
                : null,
          ),
        ),
        Observer(
          name: 'CenterSelectionButton',
          builder: (context) => GridButton(
            label: 'Center Selection',
            icon: Icons.center_focus_weak,
            onPressed: _controller.selectedNodeIds.isNotEmpty
                ? () => _controller.centerOnSelection()
                : null,
          ),
        ),
        GridButton(
          label: 'Pan Right',
          icon: Icons.arrow_forward,
          onPressed: () => _controller.panBy(const Offset(50, 0)),
        ),
        GridButton(
          label: 'Pan Down',
          icon: Icons.arrow_downward,
          onPressed: () => _controller.panBy(const Offset(0, 50)),
        ),
        GridButton(
          label: 'Pan Left',
          icon: Icons.arrow_back,
          onPressed: () => _controller.panBy(const Offset(-50, 0)),
        ),
        GridButton(
          label: 'Pan Up',
          icon: Icons.arrow_upward,
          onPressed: () => _controller.panBy(const Offset(0, -50)),
        ),
      ]),
      _buildGridSection('Analysis', [
        GridButton(
          label: 'Find Orphans',
          icon: Icons.search,
          onPressed: () {
            final orphans = _controller.getOrphanNodes();
            _showSnackBar('Found ${orphans.length} orphan nodes');
            if (orphans.isNotEmpty) {
              _controller.selectSpecificNodes(
                orphans.map((n) => n.id).toList(),
              );
            }
          },
        ),
        GridButton(
          label: 'Detect Cycles',
          icon: Icons.loop,
          onPressed: () {
            final cycles = _controller.detectCycles();
            _showSnackBar('Found ${cycles.length} cycles');
          },
        ),
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
                '${_controller.selectedNodeIds.length}',
              ),
              _buildDataRow('Total Nodes', '${_controller.nodes.length}'),
              _buildDataRow(
                'Total Connections',
                '${_controller.connections.length}',
              ),
              _buildDataRow(
                'Zoom Level',
                '${_controller.currentZoom.toStringAsFixed(2)}x',
              ),
              _buildDataRow(
                'Pan Offset',
                '(${_controller.currentPan.dx.toInt()}, ${_controller.currentPan.dy.toInt()})',
              ),
              _buildDataRow(
                'Bounds',
                '${_controller.nodesBounds.size.width.toInt()} × ${_controller.nodesBounds.size.height.toInt()}',
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

  Widget _buildCustomNode(
    BuildContext context,
    Node<Map<String, dynamic>> node,
  ) {
    final data = node.data;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Handle Table type specially
    if (node.type == 'Table') {
      return _buildTableNode(context, node, theme, isDark);
    }

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
          decoration: BoxDecoration(
            color: nodeColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
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
                Observer(
                  builder: (context) {
                    return Text(
                      'Z-Index: ${node.zIndex.value}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableNode(
    BuildContext context,
    Node<Map<String, dynamic>> node,
    ThemeData theme,
    bool isDark,
  ) {
    final data = node.data;
    final tableName = data['name'] ?? 'Table';
    final columns = data['columns'] as List<dynamic>? ?? [];

    // Soft blue for database tables
    final headerColor = isDark
        ? const Color(0xFF2D3E52)
        : const Color(0xFFD4E7F7);
    final iconColor = isDark
        ? const Color(0xFF88B8E6)
        : const Color(0xFF1B4D7A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with table name
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(color: headerColor),
          child: Row(
            children: [
              Icon(Icons.table_chart, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tableName,
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
        // Content - columns list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final column in columns)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      column.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
    _controller.config.toggleMinimap();
    _showSnackBar(
      _controller.config.showMinimap.value
          ? 'Minimap enabled'
          : 'Minimap disabled',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
