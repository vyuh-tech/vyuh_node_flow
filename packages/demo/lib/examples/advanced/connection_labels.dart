import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

/// Example demonstrating dynamic connection label management.
///
/// This example showcases:
/// - Adding and removing labels dynamically
/// - Controlling label text, anchor position, and perpendicular offset
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

  @override
  void initState() {
    super.initState();
    _store = _ConnectionLabelsStore();

    // Add initial nodes and connections after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _store.addInitialNodesAndConnections();
    });
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Main canvas
          Expanded(
            flex: 3,
            child: Observer(
              builder: (_) => NodeFlowEditor<Map<String, dynamic>>(
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
                onConnectionSelected: _store.onConnectionSelected,
              ),
            ),
          ),
          // Control panel
          Container(
            width: 320,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: _ConnectionLabelsControlPanel(store: _store),
          ),
        ],
      ),
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
  late final NodeFlowController<Map<String, dynamic>> controller;

  final Observable<String?> _selectedConnectionId = Observable(null);
  final Observable<ConnectionLabel?> _selectedLabel = Observable(null);

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
    controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig(),
    );
  }

  String? get selectedConnectionId => _selectedConnectionId.value;

  ConnectionLabel? get selectedLabel => _selectedLabel.value;

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
        inputPorts: const [],
        outputPorts: const [
          Port(
            id: 'out-1',
            name: 'Out',
            position: PortPosition.right,
            offset: Offset(0, 40),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-2',
        type: 'simple',
        position: const Offset(400, 150),
        data: {'label': 'Target Node'},
        size: const Size(150, 80),
        inputPorts: const [
          Port(
            id: 'in-1',
            name: 'In',
            position: PortPosition.left,
            offset: Offset(0, 40),
          ),
        ],
        outputPorts: const [],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-3',
        type: 'simple',
        position: const Offset(100, 300),
        data: {'label': 'Input A'},
        size: const Size(150, 80),
        inputPorts: const [],
        outputPorts: const [
          Port(
            id: 'out-3',
            name: 'Out',
            position: PortPosition.right,
            offset: Offset(0, 40),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-4',
        type: 'simple',
        position: const Offset(400, 300),
        data: {'label': 'Output B'},
        size: const Size(150, 80),
        inputPorts: const [
          Port(
            id: 'in-4',
            name: 'In',
            position: PortPosition.left,
            offset: Offset(0, 40),
          ),
        ],
        outputPorts: const [],
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
        labels: [
          ConnectionLabel(
            text: 'Data Flow',
            anchor: 0.5,
            offset: 0.0,
            id: 'label-1',
          ),
        ],
      ),
    );

    controller.addConnection(
      Connection(
        id: 'conn-2',
        sourceNodeId: 'node-3',
        sourcePortId: 'out-3',
        targetNodeId: 'node-4',
        targetPortId: 'in-4',
        labels: [
          ConnectionLabel(
            text: 'Start',
            anchor: 0.0,
            offset: 10.0,
            id: 'label-2-start',
          ),
          ConnectionLabel(
            text: 'Middle',
            anchor: 0.5,
            offset: -15.0,
            id: 'label-2-mid',
          ),
          ConnectionLabel(
            text: 'End',
            anchor: 1.0,
            offset: 10.0,
            id: 'label-2-end',
          ),
        ],
      ),
    );
  }

  void onConnectionSelected(Connection? connection) {
    runInAction(() {
      _selectedConnectionId.value = connection?.id;
      _selectedLabel.value = null;
    });
  }

  void selectLabel(ConnectionLabel? label) {
    runInAction(() {
      _selectedLabel.value = label;
    });
  }

  void addLabel() {
    final connection = selectedConnection;
    if (connection == null) return;

    connection.addLabel(
      ConnectionLabel(text: 'New Label', anchor: 0.5, offset: 0.0),
    );
  }

  void removeLabel() {
    if (_selectedLabel.value == null) return;

    final connection = selectedConnection;
    if (connection == null) return;

    connection.removeLabel(_selectedLabel.value!.id);
    runInAction(() {
      _selectedLabel.value = null;
    });
  }

  void updateLabelText(String text) {
    if (_selectedLabel.value == null) return;

    runInAction(() {
      _selectedLabel.value!.updateText(text);
    });
  }

  void updateLabelAnchor(double anchor) {
    if (_selectedLabel.value == null) return;

    runInAction(() {
      _selectedLabel.value!.updateAnchor(anchor);
    });
  }

  void updateLabelOffset(double offset) {
    if (_selectedLabel.value == null) return;

    runInAction(() {
      _selectedLabel.value!.updateOffset(offset);
    });
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
    return Observer(
      builder: (_) {
        final connection = store.selectedConnection;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Only show connection-specific sections when a connection is selected
              if (store.selectedConnectionId != null) ...[
                const SectionTitle('Selected Connection'),
                const SizedBox(height: 12),
                Text('ID: ${store.selectedConnectionId}'),
                Text('Labels: ${connection?.labels.length ?? 0}'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: store.addLabel,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Label'),
                ),
                const SizedBox(height: 24),

                // Labels list - wrapped in Observer to react to label changes
                const SectionTitle('Labels'),
                const SizedBox(height: 12),
                Observer(
                  builder: (_) {
                    if (connection != null && connection.labels.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: connection.labels.map((label) {
                          final isSelected =
                              store.selectedLabel?.id == label.id;
                          return Observer(
                            builder: (_) => Card(
                              color: isSelected ? Colors.blue[50] : null,
                              child: ListTile(
                                title: Text(label.text),
                                subtitle: Text(
                                  'Anchor: ${label.anchor.toStringAsFixed(2)} | Offset: ${label.offset.toStringAsFixed(1)}',
                                ),
                                selected: isSelected,
                                onTap: () => store.selectLabel(label),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () {
                                    connection.removeLabel(label.id);
                                    if (store.selectedLabel?.id == label.id) {
                                      store.selectLabel(null);
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      return const Text(
                        'No labels. Click "Add Label" to create one.',
                        style: TextStyle(color: Colors.grey),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Label editor - wrapped in Observer to react to label property changes
                if (store.selectedLabel != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle('Edit Label'),
                      const SizedBox(height: 12),
                      Observer(
                        builder: (_) => TextField(
                          decoration: const InputDecoration(
                            labelText: 'Label Text',
                            border: OutlineInputBorder(),
                          ),
                          controller:
                              TextEditingController(
                                  text: store.selectedLabel!.text,
                                )
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: store.selectedLabel!.text.length,
                                  ),
                                ),
                          onChanged: store.updateLabelText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Observer(
                        builder: (_) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Anchor: ${store.selectedLabel!.anchor.toStringAsFixed(2)}',
                            ),
                            Slider(
                              value: store.selectedLabel!.anchor,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              label: store.selectedLabel!.anchor
                                  .toStringAsFixed(2),
                              onChanged: store.updateLabelAnchor,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '0.0 = Start, 0.5 = Center, 1.0 = End',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Observer(
                        builder: (_) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Offset: ${store.selectedLabel!.offset.toStringAsFixed(1)}px',
                            ),
                            Slider(
                              value: store.selectedLabel!.offset,
                              min: -50.0,
                              max: 50.0,
                              divisions: 100,
                              label: store.selectedLabel!.offset
                                  .toStringAsFixed(1),
                              onChanged: store.updateLabelOffset,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Perpendicular offset from path',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: store.removeLabel,
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove Label'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
              ],

              // Theme controls - always visible
              const SectionTitle('Global Label Theme'),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              Observer(
                builder: (_) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Max Width: ${store.labelMaxWidth.value.isFinite ? store.labelMaxWidth.value.toStringAsFixed(0) : "∞"}',
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
              const SizedBox(height: 12),
              Observer(
                builder: (_) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Max Lines: ${store.labelMaxLines.value?.toString() ?? "∞"}',
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
        );
      },
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
