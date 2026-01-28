import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// Example demonstrating connection label management with three fixed positions.
///
/// This example showcases:
/// - Setting start, center, and end labels on connections
/// - Controlling label text and perpendicular offset for each position
/// - Theme-level label styling configuration
/// - Real-time reactive updates of label properties
class ConnectionLabelsExample extends StatefulWidget {
  const ConnectionLabelsExample({super.key});

  @override
  State<ConnectionLabelsExample> createState() =>
      _ConnectionLabelsExampleState();
}

class _ConnectionLabelsExampleState extends State<ConnectionLabelsExample> {
  late final _ConnectionLabelsStore _store;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _store = _ConnectionLabelsStore();

    // Add initial nodes and connections after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _store.addInitialNodesAndConnections();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ResponsiveControlPanel(
      controller: _store.controller,
      onReset: () {
        _store.controller.clearGraph();
        _store.addInitialNodesAndConnections();
      },
      child: Observer(
        builder: (_) => NodeFlowEditor<Map<String, dynamic>, dynamic>(
          controller: _store.controller,
          nodeBuilder: _buildNode,
          theme: NodeFlowTheme.light.copyWith(
            labelTheme: LabelTheme(
              textStyle: TextStyle(
                color: _store.labelColor.value,
                fontSize: _store.labelFontSize.value,
              ),
              backgroundColor: _store.labelBackgroundColor.value,
              border: Border.all(
                color: _store.labelBorderColor.value,
                width: 1.0,
              ),
              maxWidth: _store.labelMaxWidth.value,
              maxLines: _store.labelMaxLines.value,
            ),
          ),
          events: NodeFlowEvents<Map<String, dynamic>, dynamic>(
            connection: ConnectionEvents<Map<String, dynamic>, dynamic>(
              onSelected: _store.onConnectionSelected,
            ),
          ),
        ),
      ),
      children: [_ConnectionLabelsControlPanel(store: _store)],
    );
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          node.data['label'] ?? '',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      ),
    );
  }
}

/// MobX store for managing connection labels example state using raw observables
class _ConnectionLabelsStore {
  late final NodeFlowController<Map<String, dynamic>, dynamic> controller;

  final Observable<String?> _selectedConnectionId = Observable(null);

  // Theme controls
  final Observable<Color> labelColor = Observable(const Color(0xFF333333));
  final Observable<double> labelFontSize = Observable(12.0);
  final Observable<Color> labelBackgroundColor = Observable(
    const Color(0xFFFBFBFB),
  );
  final Observable<Color> labelBorderColor = Observable(
    const Color(0xFFDDDDDD),
  );
  final Observable<double> labelMaxWidth = Observable(double.infinity);
  final Observable<int?> labelMaxLines = Observable(null);

  _ConnectionLabelsStore() {
    controller = NodeFlowController<Map<String, dynamic>, dynamic>(
      config: NodeFlowConfig(
        plugins: [StatsPlugin(), ...NodeFlowConfig.defaultPlugins()],
      ),
    );
  }

  String? get selectedConnectionId => _selectedConnectionId.value;

  Connection? get selectedConnection {
    if (_selectedConnectionId.value == null) return null;
    try {
      return controller.connections.firstWhere(
        (c) => c.id == _selectedConnectionId.value,
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    controller.dispose();
  }

  void addInitialNodesAndConnections() {
    // Add nodes
    final nodes = [
      Node<Map<String, dynamic>>(
        id: 'node-1',
        type: 'simple',
        position: const Offset(100, 150),
        data: {'label': 'Source Node'},
        size: const Size(150, 80),
        ports: [
          Port(
            id: 'out-1',
            name: 'Out',
            type: PortType.output,
            position: PortPosition.right,
            offset: Offset(2, 40),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-2',
        type: 'simple',
        position: const Offset(400, 150),
        data: {'label': 'Target Node'},
        size: const Size(150, 80),
        ports: [
          Port(
            id: 'in-1',
            name: 'In',
            type: PortType.input,
            position: PortPosition.left,
            offset: Offset(-2, 40),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-3',
        type: 'simple',
        position: const Offset(100, 300),
        data: {'label': 'Input A'},
        size: const Size(150, 80),
        ports: [
          Port(
            id: 'out-3',
            name: 'Out',
            type: PortType.output,
            position: PortPosition.right,
            offset: Offset(2, 40),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-4',
        type: 'simple',
        position: const Offset(400, 300),
        data: {'label': 'Output B'},
        size: const Size(150, 80),
        ports: [
          Port(
            id: 'in-4',
            name: 'In',
            type: PortType.input,
            position: PortPosition.left,
            offset: Offset(-2, 40),
          ),
        ],
      ),
    ];

    for (final node in nodes) {
      controller.addNode(node);
    }

    // Add connections with labels
    controller.addConnection(
      Connection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'out-1',
        targetNodeId: 'node-2',
        targetPortId: 'in-1',
        label: ConnectionLabel.center(text: 'Data Flow', id: 'label-1'),
      ),
    );

    controller.addConnection(
      Connection(
        id: 'conn-2',
        sourceNodeId: 'node-3',
        sourcePortId: 'out-3',
        targetNodeId: 'node-4',
        targetPortId: 'in-4',
        startLabel: ConnectionLabel.start(
          text: 'Start',
          offset: 10.0,
          id: 'label-2-start',
        ),
        label: ConnectionLabel.center(
          text: 'Middle',
          offset: -15.0,
          id: 'label-2-mid',
        ),
        endLabel: ConnectionLabel.end(
          text: 'End',
          offset: 10.0,
          id: 'label-2-end',
        ),
      ),
    );
  }

  void onConnectionSelected(Connection? connection) {
    runInAction(() {
      _selectedConnectionId.value = connection?.id;
    });
  }

  void setStartLabel(String? text) {
    final connection = selectedConnection;
    if (connection == null) return;

    if (text == null || text.isEmpty) {
      connection.startLabel = null;
    } else if (connection.startLabel == null) {
      // Create new label if it doesn't exist
      connection.startLabel = ConnectionLabel.start(text: text);
    } else {
      // Update existing label
      connection.startLabel!.updateText(text);
    }
  }

  void setLabel(String? text) {
    final connection = selectedConnection;
    if (connection == null) return;

    if (text == null || text.isEmpty) {
      connection.label = null;
    } else if (connection.label == null) {
      // Create new label if it doesn't exist
      connection.label = ConnectionLabel.center(text: text);
    } else {
      // Update existing label
      connection.label!.updateText(text);
    }
  }

  void setEndLabel(String? text) {
    final connection = selectedConnection;
    if (connection == null) return;

    if (text == null || text.isEmpty) {
      connection.endLabel = null;
    } else if (connection.endLabel == null) {
      // Create new label if it doesn't exist
      connection.endLabel = ConnectionLabel.end(text: text);
    } else {
      // Update existing label
      connection.endLabel!.updateText(text);
    }
  }

  void setStartLabelOffset(double offset) {
    final connection = selectedConnection;
    if (connection == null || connection.startLabel == null) return;

    connection.startLabel!.updateOffset(offset);
  }

  void setLabelOffset(double offset) {
    final connection = selectedConnection;
    if (connection == null || connection.label == null) return;

    connection.label!.updateOffset(offset);
  }

  void setEndLabelOffset(double offset) {
    final connection = selectedConnection;
    if (connection == null || connection.endLabel == null) return;

    connection.endLabel!.updateOffset(offset);
  }

  void setLabelColor(Color color) {
    runInAction(() {
      labelColor.value = color;
    });
  }

  void setLabelFontSize(double size) {
    runInAction(() {
      labelFontSize.value = size;
    });
  }

  void setLabelBackgroundColor(Color color) {
    runInAction(() {
      labelBackgroundColor.value = color;
    });
  }

  void setLabelBorderColor(Color color) {
    runInAction(() {
      labelBorderColor.value = color;
    });
  }

  void setLabelMaxWidth(double width) {
    runInAction(() {
      labelMaxWidth.value = width;
    });
  }

  void setLabelMaxLines(int? lines) {
    runInAction(() {
      labelMaxLines.value = lines;
    });
  }
}

/// Control panel widget for managing connection labels
class _ConnectionLabelsControlPanel extends StatelessWidget {
  const _ConnectionLabelsControlPanel({required this.store});

  final _ConnectionLabelsStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Observer(
      builder: (_) {
        final connection = store.selectedConnection;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SectionTitle('About'),
            SectionContent(
              child: InfoCard(
                title: 'Instructions',
                content:
                    'Click on a connection to edit its labels. Adjust text, offset, and global theme settings.',
              ),
            ),
            // Only show connection-specific sections when a connection is selected
            if (store.selectedConnectionId != null) ...[
              const SectionTitle('Selected Connection'),
              SectionContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ID: ${store.selectedConnectionId}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Labels: ${connection?.labels.length ?? 0}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Start Label
              _LabelControl(
                title: 'Start Label',
                label: connection?.startLabel,
                onTextChanged: store.setStartLabel,
                onOffsetChanged: store.setStartLabelOffset,
              ),

              // Center Label
              _LabelControl(
                title: 'Center Label',
                label: connection?.label,
                onTextChanged: store.setLabel,
                onOffsetChanged: store.setLabelOffset,
              ),

              // End Label
              _LabelControl(
                title: 'End Label',
                label: connection?.endLabel,
                onTextChanged: store.setEndLabel,
                onOffsetChanged: store.setEndLabelOffset,
              ),
            ],

            // Theme controls - always visible
            const SectionTitle('Global Label Theme'),
            SectionContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Observer(
                    builder: (_) => _ColorPickerRow(
                      label: 'Text Color',
                      color: store.labelColor.value,
                      onColorChanged: store.setLabelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Observer(
                    builder: (_) => _ColorPickerRow(
                      label: 'Background',
                      color: store.labelBackgroundColor.value,
                      onColorChanged: store.setLabelBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Observer(
                    builder: (_) => _ColorPickerRow(
                      label: 'Border',
                      color: store.labelBorderColor.value,
                      onColorChanged: store.setLabelBorderColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Observer(
                    builder: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Font Size: ${store.labelFontSize.value.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        Slider(
                          value: store.labelFontSize.value,
                          min: 8.0,
                          max: 24.0,
                          divisions: 16,
                          label: store.labelFontSize.value.toStringAsFixed(0),
                          onChanged: store.setLabelFontSize,
                        ),
                      ],
                    ),
                  ),
                  Observer(
                    builder: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Max Width: ${store.labelMaxWidth.value.isFinite ? store.labelMaxWidth.value.toStringAsFixed(0) : "∞"}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            if (store.labelMaxWidth.value.isFinite)
                              TextButton(
                                onPressed: () =>
                                    store.setLabelMaxWidth(double.infinity),
                                child: const Text('Reset'),
                              ),
                          ],
                        ),
                        Slider(
                          value: store.labelMaxWidth.value.isFinite
                              ? store.labelMaxWidth.value
                              : 200.0,
                          min: 100.0,
                          max: 200.0,
                          divisions: 5,
                          label: store.labelMaxWidth.value.isFinite
                              ? store.labelMaxWidth.value.toStringAsFixed(0)
                              : '∞',
                          onChanged: store.setLabelMaxWidth,
                        ),
                      ],
                    ),
                  ),
                  Observer(
                    builder: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Max Lines: ${store.labelMaxLines.value?.toString() ?? "∞"}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            if (store.labelMaxLines.value != null)
                              TextButton(
                                onPressed: () => store.setLabelMaxLines(null),
                                child: const Text('Reset'),
                              ),
                          ],
                        ),
                        Slider(
                          value: (store.labelMaxLines.value ?? 5).toDouble(),
                          min: 1.0,
                          max: 5.0,
                          divisions: 4,
                          label: store.labelMaxLines.value?.toString() ?? '∞',
                          onChanged: (value) =>
                              store.setLabelMaxLines(value.toInt()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Label control widget for a single label position
class _LabelControl extends StatefulWidget {
  const _LabelControl({
    required this.title,
    required this.label,
    required this.onTextChanged,
    required this.onOffsetChanged,
  });

  final String title;
  final ConnectionLabel? label;
  final ValueChanged<String?> onTextChanged;
  final ValueChanged<double> onOffsetChanged;

  @override
  State<_LabelControl> createState() => _LabelControlState();
}

class _LabelControlState extends State<_LabelControl> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.label?.text ?? '');
  }

  @override
  void didUpdateWidget(_LabelControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the text controller if the label object changed (not just the text)
    // This prevents disrupting typing when the text is being edited
    if (widget.label?.id != oldWidget.label?.id) {
      _textController.text = widget.label?.text ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(widget.title),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Text',
                  border: const OutlineInputBorder(),
                  suffixIcon: widget.label != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _textController.clear();
                            widget.onTextChanged(null);
                          },
                        )
                      : null,
                ),
                onChanged: widget.onTextChanged,
              ),
              if (widget.label != null) ...[
                const SizedBox(height: 12),
                Observer(
                  builder: (_) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Offset: ${widget.label!.offset.toStringAsFixed(1)}px',
                      ),
                      Slider(
                        value: widget.label!.offset,
                        min: -50.0,
                        max: 50.0,
                        divisions: 100,
                        label: widget.label!.offset.toStringAsFixed(1),
                        onChanged: widget.onOffsetChanged,
                      ),
                      const Text(
                        'Perpendicular offset from path',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Color picker row widget
class _ColorPickerRow extends StatelessWidget {
  const _ColorPickerRow({
    required this.label,
    required this.color,
    required this.onColorChanged,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        GestureDetector(
          onTap: () async {
            final newColor = await showDialog<Color>(
              context: context,
              builder: (context) => _ColorPickerDialog(initialColor: color),
            );
            if (newColor != null) {
              onColorChanged(newColor);
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  final List<Color> _presetColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
    const Color(0xFFFBFBFB),
    const Color(0xFF333333),
    const Color(0xFFDDDDDD),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a Color'),
      content: SizedBox(
        width: 300,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
