import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

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
  bool _scrollToZoom = true;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Node Flow Workbench'),
        backgroundColor: Colors.indigo.shade100,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Main Editor
          Expanded(
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

                // Loading overlay
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),

          // Control Panel - Full Featured
          _buildControlPanel(),
        ],
      ),
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
              offset: Offset(150, 40),
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
              offset: Offset(150, 40),
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
        borderColor: Colors.grey.shade400,
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

  Widget _buildControlPanel() {
    return Container(
      width: 250,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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
                              if (newValue != null &&
                                  newValue != _selectedWorkflow) {
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
                    _buildGridButton(
                      'Toggle Minimap',
                      Icons.map,
                      _toggleMinimap,
                    ),
                  ]),
                  _buildGridSection('Viewport Controls', [
                    _buildGridButton(
                      'Zoom In',
                      Icons.zoom_in,
                      () => _store.zoomBy(0.2),
                    ),
                    _buildGridButton(
                      'Zoom Out',
                      Icons.zoom_out,
                      () => _store.zoomBy(-0.2),
                    ),
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
                            ? () => _store.centerOnNode(
                                _store.selectedNodeIds.first,
                              )
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
                  _buildGridSection('Node Operations', [
                    Observer(
                      name: 'DuplicateNodeButton',
                      builder: (context) => _buildGridButton(
                        'Duplicate',
                        Icons.content_copy,
                        _store.selectedNodeIds.isNotEmpty
                            ? () {
                                final nodeId = _store.selectedNodeIds.first;
                                _store.duplicateNode(nodeId);
                                _showSnackBar('Node duplicated');
                              }
                            : null,
                      ),
                    ),
                    Observer(
                      name: 'DeleteMultipleNodesButton',
                      builder: (context) => _buildGridButton(
                        'Delete Multiple',
                        Icons.delete_sweep,
                        _store.selectedNodeIds.isNotEmpty
                            ? () {
                                final count = _store.selectedNodeIds.length;
                                _store.deleteNodes(
                                  _store.selectedNodeIds.toList(),
                                );
                                _showSnackBar('Deleted $count nodes');
                              }
                            : null,
                      ),
                    ),
                    Observer(
                      name: 'MoveNodeRightButton',
                      builder: (context) => _buildGridButton(
                        'Move Right',
                        Icons.arrow_forward,
                        _store.selectedNodeIds.isNotEmpty
                            ? () {
                                final nodeId = _store.selectedNodeIds.first;
                                final node = _store.getNode(nodeId);
                                if (node != null) {
                                  _store.setNodePosition(
                                    nodeId,
                                    node.position.value + const Offset(50, 0),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                    Observer(
                      name: 'MoveNodeDownButton',
                      builder: (context) => _buildGridButton(
                        'Move Down',
                        Icons.arrow_downward,
                        _store.selectedNodeIds.isNotEmpty
                            ? () {
                                final nodeId = _store.selectedNodeIds.first;
                                final node = _store.getNode(nodeId);
                                if (node != null) {
                                  _store.setNodePosition(
                                    nodeId,
                                    node.position.value + const Offset(0, 50),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                    Observer(
                      name: 'MoveNodeLeftButton',
                      builder: (context) => _buildGridButton(
                        'Move Left',
                        Icons.arrow_back,
                        _store.selectedNodeIds.isNotEmpty
                            ? () {
                                final nodeId = _store.selectedNodeIds.first;
                                final node = _store.getNode(nodeId);
                                if (node != null) {
                                  _store.setNodePosition(
                                    nodeId,
                                    node.position.value + const Offset(-50, 0),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                    Observer(
                      name: 'MoveNodeUpButton',
                      builder: (context) => _buildGridButton(
                        'Move Up',
                        Icons.arrow_upward,
                        _store.selectedNodeIds.isNotEmpty
                            ? () {
                                final nodeId = _store.selectedNodeIds.first;
                                final node = _store.getNode(nodeId);
                                if (node != null) {
                                  _store.setNodePosition(
                                    nodeId,
                                    node.position.value + const Offset(0, -50),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                  ]),
                  _buildGridSection('Selection', [
                    _buildGridButton('Select All', Icons.select_all, () {
                      _store.selectAllNodes();
                      _showSnackBar('Selected all nodes');
                    }),
                    _buildGridButton('Select Connections', Icons.timeline, () {
                      _store.selectAllConnections();
                      _showSnackBar('Selected all connections');
                    }),
                    _buildGridButton('Invert Selection', Icons.flip, () {
                      _store.invertSelection();
                      _showSnackBar('Inverted selection');
                    }),
                    _buildGridButton('Clear Selection', Icons.deselect, () {
                      _store.clearSelection();
                      _showSnackBar('Selection cleared');
                    }),
                  ]),
                  _buildGridSection('Layout & Alignment', [
                    _buildGridButton('Grid Layout', Icons.grid_view, () {
                      _store.arrangeNodesInGrid(spacing: 150.0);
                      _showSnackBar('Arranged nodes in grid');
                    }),
                    _buildGridButton('Hierarchical', Icons.account_tree, () {
                      _store.arrangeNodesHierarchically();
                      _showSnackBar('Arranged nodes hierarchically');
                    }),
                    Observer(
                      name: 'AlignYButton',
                      builder: (context) => _buildGridButton(
                        'Align Y',
                        Icons.align_vertical_center,
                        _store.selectedNodeIds.length >= 2
                            ? () {
                                _store.alignNodes(
                                  _store.selectedNodeIds.toList(),
                                  NodeAlignment.verticalCenter,
                                );
                                _showSnackBar('Aligned nodes on Y axis');
                              }
                            : null,
                      ),
                    ),
                    Observer(
                      name: 'AlignXButton',
                      builder: (context) => _buildGridButton(
                        'Align X',
                        Icons.align_horizontal_center,
                        _store.selectedNodeIds.length >= 2
                            ? () {
                                _store.alignNodes(
                                  _store.selectedNodeIds.toList(),
                                  NodeAlignment.horizontalCenter,
                                );
                                _showSnackBar('Aligned nodes on X axis');
                              }
                            : null,
                      ),
                    ),
                    Observer(
                      name: 'DistributeHorizontalButton',
                      builder: (context) => _buildGridButton(
                        'Distribute H',
                        Icons.view_column,
                        _store.selectedNodeIds.length >= 3
                            ? () {
                                _store.distributeNodesHorizontally(
                                  _store.selectedNodeIds.toList(),
                                );
                                _showSnackBar('Distributed nodes horizontally');
                              }
                            : null,
                      ),
                    ),
                    Observer(
                      name: 'DistributeVerticalButton',
                      builder: (context) => _buildGridButton(
                        'Distribute V',
                        Icons.view_stream,
                        _store.selectedNodeIds.length >= 3
                            ? () {
                                _store.distributeNodesVertically(
                                  _store.selectedNodeIds.toList(),
                                );
                                _showSnackBar('Distributed nodes vertically');
                              }
                            : null,
                      ),
                    ),
                  ]),
                  _buildGridSection('Layering', [
                    Observer(
                      name: 'BringToFrontButton',
                      builder: (context) => _buildGridButton(
                        'Bring Front',
                        Icons.flip_to_front,
                        _store.selectedNodeIds.isNotEmpty
                            ? () {
                                final nodeId = _store.selectedNodeIds.first;
                                _store.bringNodeToFront(nodeId);
                                _showSnackBar('Node brought to front');
                              }
                            : null,
                      ),
                    ),
                    Observer(
                      name: 'SendToBackButton',
                      builder: (context) => _buildGridButton(
                        'Send Back',
                        Icons.flip_to_back,
                        _store.selectedNodeIds.isNotEmpty
                            ? () {
                                final nodeId = _store.selectedNodeIds.first;
                                _store.sendNodeToBack(nodeId);
                                _showSnackBar('Node sent to back');
                              }
                            : null,
                      ),
                    ),
                  ]),
                  _buildGridSection('Connections', [
                    _buildGridButton('Test Connection', Icons.link, () {
                      final source = _store.getNode('source-1');
                      final transform = _store.getNode('transform-1');
                      if (source != null && transform != null) {
                        _store.createConnection(
                          'source-1',
                          'output',
                          'transform-1',
                          'input',
                        );
                        _showSnackBar('Test connection created');
                      } else {
                        _showSnackBar('Source or target node not found');
                      }
                    }),
                    _buildGridButton(
                      'Delete Node Conns',
                      Icons.link_off,
                      _store.selectedNodeIds.isNotEmpty
                          ? () {
                              _store.deleteAllConnectionsForNode(
                                _store.selectedNodeIds.first,
                              );
                              _showSnackBar('Deleted all connections for node');
                            }
                          : null,
                    ),
                  ]),
                  _buildGridSection('Add Nodes', [
                    _buildGridButton(
                      'Add Source',
                      Icons.input,
                      () => _addNode('Source'),
                    ),
                    _buildGridButton(
                      'Add Transform',
                      Icons.transform,
                      () => _addNode('Transform'),
                    ),
                    _buildGridButton(
                      'Add Filter',
                      Icons.filter_alt,
                      () => _addNode('Filter'),
                    ),
                    _buildGridButton(
                      'Add Sink',
                      Icons.output,
                      () => _addNode('Sink'),
                    ),
                    _buildGridButton(
                      'Add All Ports',
                      Icons.hub,
                      () => _addNode('AllPorts'),
                    ),
                  ]),
                  _buildGridSection('Analysis', [
                    _buildGridButton('Find Orphans', Icons.search, () {
                      final orphans = _store.getOrphanNodes();
                      _showSnackBar('Found ${orphans.length} orphan nodes');
                      if (orphans.isNotEmpty) {
                        _store.selectSpecificNodes(
                          orphans.map((n) => n.id).toList(),
                        );
                      }
                    }),
                    _buildGridButton('Detect Cycles', Icons.loop, () {
                      final cycles = _store.detectCycles();
                      _showSnackBar('Found ${cycles.length} cycles');
                    }),
                  ]),
                  _buildStyleSection(),
                  _buildCanvasSettingsSection(),
                  _buildNodeStyleSection(),

                  // Display Information - Single Column
                  _buildInfoSection('Graph Statistics', [
                    Observer(
                      name: 'SelectedNodesCountInfo',
                      builder: (context) => _buildInfoText(
                        'Selected Nodes',
                        '${_store.selectedNodeIds.length}',
                      ),
                    ),
                    Observer(
                      name: 'TotalNodesCountInfo',
                      builder: (context) => _buildInfoText(
                        'Total Nodes',
                        '${_store.nodes.length}',
                      ),
                    ),
                    Observer(
                      name: 'TotalConnectionsCountInfo',
                      builder: (context) => _buildInfoText(
                        'Total Connections',
                        '${_store.connections.length}',
                      ),
                    ),
                    Observer(
                      name: 'ZoomLevelInfo',
                      builder: (context) => _buildInfoText(
                        'Zoom Level',
                        '${_store.currentZoom.toStringAsFixed(2)}x',
                      ),
                    ),
                    Observer(
                      name: 'PanOffsetInfo',
                      builder: (context) => _buildInfoText(
                        'Pan Offset',
                        '(${_store.currentPan.dx.toInt()}, ${_store.currentPan.dy.toInt()})',
                      ),
                    ),
                    Observer(
                      name: 'NodesBoundsInfo',
                      builder: (context) => _buildInfoText(
                        'Bounds',
                        '${_store.nodesBounds.size.width.toInt()} × ${_store.nodesBounds.size.height.toInt()}',
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSection(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ),
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

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
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

  Widget _buildInfoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Connection Style',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Style
              const Text(
                'Connection Type',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ConnectionStyles.all.map((style) {
                  if (style == ConnectionStyles.customBezier) {
                    return const SizedBox.shrink();
                  }
                  return ChoiceChip(
                    label: Text(
                      style.displayName,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _nodeFlowTheme.connectionStyle == style,
                    onSelected: (selected) {
                      if (selected) {
                        _updateTheme(
                          _nodeFlowTheme.copyWith(
                            connectionStyle: style,
                            temporaryConnectionStyle: style,
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Connection Colors
              const Text(
                'Connection Colors',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildColorPicker(
                'Normal Color',
                _nodeFlowTheme.connectionTheme.color,
                (color) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      connectionTheme: _nodeFlowTheme.connectionTheme.copyWith(
                        color: color,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildColorPicker(
                'Selected Color',
                _nodeFlowTheme.connectionTheme.selectedColor,
                (color) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      connectionTheme: _nodeFlowTheme.connectionTheme.copyWith(
                        selectedColor: color,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildColorPicker(
                'Temporary Color',
                _nodeFlowTheme.temporaryConnectionTheme.color,
                (color) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      temporaryConnectionTheme: _nodeFlowTheme
                          .temporaryConnectionTheme
                          .copyWith(color: color),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),

              // Stroke Width
              const Text(
                'Stroke Width',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildSlider(
                'Normal',
                _nodeFlowTheme.connectionTheme.strokeWidth,
                1.0,
                5.0,
                (value) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      connectionTheme: _nodeFlowTheme.connectionTheme.copyWith(
                        strokeWidth: value,
                      ),
                    );
                  });
                },
              ),
              _buildSlider(
                'Selected',
                _nodeFlowTheme.connectionTheme.selectedStrokeWidth,
                1.0,
                6.0,
                (value) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      connectionTheme: _nodeFlowTheme.connectionTheme.copyWith(
                        selectedStrokeWidth: value,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),

              // Dash Pattern
              const Text(
                'Dash Pattern (Temporary)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Dash: ', style: TextStyle(fontSize: 11)),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      controller: TextEditingController(
                        text:
                            _nodeFlowTheme
                                .temporaryConnectionTheme
                                .dashPattern
                                ?.first
                                .toString() ??
                            '5',
                      ),
                      onChanged: (value) {
                        final dashValue = double.tryParse(value);
                        if (dashValue != null && dashValue > 0) {
                          final currentGap =
                              _nodeFlowTheme
                                  .temporaryConnectionTheme
                                  .dashPattern
                                  ?.last ??
                              5.0;
                          setState(() {
                            _nodeFlowTheme = _nodeFlowTheme.copyWith(
                              temporaryConnectionTheme: _nodeFlowTheme
                                  .temporaryConnectionTheme
                                  .copyWith(
                                    dashPattern: [dashValue, currentGap],
                                  ),
                            );
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Gap: ', style: TextStyle(fontSize: 11)),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      controller: TextEditingController(
                        text:
                            _nodeFlowTheme
                                .temporaryConnectionTheme
                                .dashPattern
                                ?.last
                                .toString() ??
                            '5',
                      ),
                      onChanged: (value) {
                        final gapValue = double.tryParse(value);
                        if (gapValue != null && gapValue > 0) {
                          final currentDash =
                              _nodeFlowTheme
                                  .temporaryConnectionTheme
                                  .dashPattern
                                  ?.first ??
                              5.0;
                          setState(() {
                            _nodeFlowTheme = _nodeFlowTheme.copyWith(
                              temporaryConnectionTheme: _nodeFlowTheme
                                  .temporaryConnectionTheme
                                  .copyWith(
                                    dashPattern: [currentDash, gapValue],
                                  ),
                            );
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bezier Curvature
              const Text(
                'Bezier Curvature',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildSlider(
                'Curvature',
                _nodeFlowTheme.connectionTheme.bezierCurvature,
                0.0,
                1.0,
                (value) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      connectionTheme: _nodeFlowTheme.connectionTheme.copyWith(
                        bezierCurvature: value,
                      ),
                      temporaryConnectionTheme: _nodeFlowTheme
                          .temporaryConnectionTheme
                          .copyWith(bezierCurvature: value),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),

              // Endpoint Size
              const Text(
                'Endpoint Size',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildSlider(
                'End Point Size',
                _nodeFlowTheme.connectionTheme.endPoint.size,
                0.0,
                15.0,
                (value) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      connectionTheme: _nodeFlowTheme.connectionTheme.copyWith(
                        endPoint: _nodeFlowTheme.connectionTheme.endPoint
                            .copyWith(size: value),
                      ),
                    );
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCanvasSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Canvas Settings',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid Style
              const Text(
                'Grid Style',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GridStyle.values.map((style) {
                  return ChoiceChip(
                    label: Text(
                      style.name[0].toUpperCase() + style.name.substring(1),
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _nodeFlowTheme.gridStyle == style,
                    onSelected: (selected) {
                      if (selected) {
                        _updateTheme(_nodeFlowTheme.copyWith(gridStyle: style));
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Grid Size
              _buildSlider('Grid Size', _nodeFlowTheme.gridSize, 10.0, 50.0, (
                value,
              ) {
                _updateTheme(_nodeFlowTheme.copyWith(gridSize: value));
              }),
              const SizedBox(height: 8),

              // Grid Color
              _buildColorPicker('Grid Color', _nodeFlowTheme.gridColor, (
                color,
              ) {
                _updateTheme(_nodeFlowTheme.copyWith(gridColor: color));
              }),
              const SizedBox(height: 16),

              // Interaction Settings
              const Text(
                'Interaction Settings',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Snap to Grid
              Row(
                children: [
                  Observer(
                    builder: (_) => Checkbox(
                      value: _store.config.snapToGrid.value,
                      onChanged: (value) {
                        _store.config.update(snapToGrid: value ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Snap to Grid', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Scroll to Zoom
              Row(
                children: [
                  Checkbox(
                    value: _scrollToZoom,
                    onChanged: (value) {
                      setState(() {
                        _scrollToZoom = value ?? true;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Scroll to Zoom (trackpad)',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'When enabled, trackpad scroll gestures zoom in/out. When disabled, they pan.',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNodeStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Node Style',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Node Background Colors
              const Text(
                'Background Colors',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildColorPicker(
                'Normal',
                _nodeFlowTheme.nodeTheme.backgroundColor,
                (color) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      nodeTheme: _nodeFlowTheme.nodeTheme.copyWith(
                        backgroundColor: color,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildColorPicker(
                'Selected',
                _nodeFlowTheme.nodeTheme.selectedBackgroundColor,
                (color) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      nodeTheme: _nodeFlowTheme.nodeTheme.copyWith(
                        selectedBackgroundColor: color,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildColorPicker(
                'Hover',
                _nodeFlowTheme.nodeTheme.hoverBackgroundColor,
                (color) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      nodeTheme: _nodeFlowTheme.nodeTheme.copyWith(
                        hoverBackgroundColor: color,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),

              // Node Border Colors
              const Text(
                'Border Colors',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildColorPicker(
                'Normal',
                _nodeFlowTheme.nodeTheme.borderColor,
                (color) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      nodeTheme: _nodeFlowTheme.nodeTheme.copyWith(
                        borderColor: color,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildColorPicker(
                'Selected',
                _nodeFlowTheme.nodeTheme.selectedBorderColor,
                (color) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      nodeTheme: _nodeFlowTheme.nodeTheme.copyWith(
                        selectedBorderColor: color,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),

              // Border Width
              const Text(
                'Border Width',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildSlider(
                'Normal',
                _nodeFlowTheme.nodeTheme.borderWidth,
                0.0,
                5.0,
                (value) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      nodeTheme: _nodeFlowTheme.nodeTheme.copyWith(
                        borderWidth: value,
                      ),
                    );
                  });
                },
              ),
              _buildSlider(
                'Selected',
                _nodeFlowTheme.nodeTheme.selectedBorderWidth,
                0.0,
                5.0,
                (value) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      nodeTheme: _nodeFlowTheme.nodeTheme.copyWith(
                        selectedBorderWidth: value,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),

              // Border Radius
              const Text(
                'Border Radius',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildSlider(
                'Radius',
                _nodeFlowTheme.nodeTheme.borderRadius.topLeft.x,
                0.0,
                20.0,
                (value) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      nodeTheme: _nodeFlowTheme.nodeTheme.copyWith(
                        borderRadius: BorderRadius.circular(value),
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),

              // Padding
              const Text(
                'Padding',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildSlider(
                'All sides',
                _nodeFlowTheme.nodeTheme.padding.left,
                0.0,
                20.0,
                (value) {
                  setState(() {
                    _nodeFlowTheme = _nodeFlowTheme.copyWith(
                      nodeTheme: _nodeFlowTheme.nodeTheme.copyWith(
                        padding: EdgeInsets.all(value),
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildColorPicker(
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    final colors = [
      Colors.grey.shade300,
      Colors.blue.shade100,
      Colors.red.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
      Colors.indigo.shade100,
      Colors.amber.shade100,
      Colors.brown.shade100,
      Colors.cyan.shade100,
    ];

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text('$label:', style: const TextStyle(fontSize: 11)),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: colors.map((color) {
              return InkWell(
                onTap: () => onColorChanged(color),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: currentColor == color
                          ? Colors.black
                          : Colors.grey.shade300,
                      width: currentColor == color ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text('$label:', style: const TextStyle(fontSize: 11)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _addNode(String type) {
    final newNode = Node<Map<String, dynamic>>(
      id: '${type.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      position: Offset(
        100 + (_store.nodes.length * 30) % 400,
        100 + (_store.nodes.length * 40) % 300,
      ),
      data: {'label': '$type Node'},
      size: const Size(150, 120),
      inputPorts: _getInputPorts(type),
      outputPorts: _getOutputPorts(type),
    );
    _store.addNode(newNode);
    _showSnackBar('Added $type node');
  }

  List<Port> _getInputPorts(String type) {
    switch (type) {
      case 'Source':
        return []; // Source nodes have no input ports
      case 'AllPorts':
        return [
          const Port(
            id: 'input-left',
            name: 'Left In',

            position: PortPosition.left,
            offset: Offset(0, 20),
          ),
          const Port(
            id: 'input-top',
            name: 'Top In',

            position: PortPosition.top,
            offset: Offset(20, 0),
          ),
          const Port(
            id: 'input-right',
            name: 'Right In',

            position: PortPosition.right,
            offset: Offset(0, 20),
          ),
          const Port(
            id: 'input-bottom',
            name: 'Bottom In',

            position: PortPosition.bottom,
            offset: Offset(20, 0),
          ),
        ];
      default:
        return [
          const Port(
            id: 'input',
            name: 'In',

            position: PortPosition.left,
            offset: Offset(0, 60),
          ),
        ];
    }
  }

  List<Port> _getOutputPorts(String type) {
    switch (type) {
      case 'Sink':
        return []; // Sink nodes have no output ports
      case 'AllPorts':
        return [
          const Port(
            id: 'output-left',
            name: 'Left Out',

            position: PortPosition.left,
            offset: Offset(0, 90),
          ),
          const Port(
            id: 'output-right',
            name: 'Right Out',

            position: PortPosition.right,
            offset: Offset(0, 90),
          ),
          const Port(
            id: 'output-top',
            name: 'Top Out',

            position: PortPosition.top,
            offset: Offset(110, 0),
          ),
          const Port(
            id: 'output-bottom',
            name: 'Bottom Out',

            position: PortPosition.bottom,
            offset: Offset(110, 0),
          ),
        ];
      default:
        return [
          const Port(
            id: 'output',
            name: 'Out',

            position: PortPosition.right,
            offset: Offset(150, 60),
          ),
        ];
    }
  }

  Widget _buildCustomNode(
    BuildContext context,
    Node<Map<String, dynamic>> node,
  ) {
    final data = node.data;
    final nodeColor = _getNodeColor(node.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(color: nodeColor.withValues(alpha: 0.2)),
          child: Row(
            children: [
              Icon(_getNodeIcon(node.type), size: 14, color: nodeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['label'] ?? node.type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
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
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Z: ${node.zIndex}',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'Source':
        return Colors.green;
      case 'Transform':
        return Colors.blue;
      case 'Filter':
        return Colors.orange;
      case 'Sink':
        return Colors.red;
      case 'AllPorts':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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

  /// Helper method to update theme in both local state and controller
  void _updateTheme(NodeFlowTheme newTheme) {
    setState(() {
      _nodeFlowTheme = newTheme;
    });
    _store.setTheme(newTheme);
  }
}
