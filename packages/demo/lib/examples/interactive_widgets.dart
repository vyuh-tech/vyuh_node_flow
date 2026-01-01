import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// Example demonstrating interactive widgets inside nodes.
///
/// This example tests whether Flutter gestures work correctly when nodes
/// are dragged far outside the original Stack bounds. Interactive widgets
/// like buttons, text fields, and sliders should continue to work regardless
/// of node position on the canvas.
///
/// The `UnboundedStack` and `UnboundedSizedBox` widgets in the NodeFlowEditor
/// enable hit testing outside the Stack's original bounds, allowing widgets
/// to receive gestures even when dragged far away from the origin.
class InteractiveWidgetsExample extends StatefulWidget {
  const InteractiveWidgetsExample({super.key});

  @override
  State<InteractiveWidgetsExample> createState() =>
      _InteractiveWidgetsExampleState();
}

class _InteractiveWidgetsExampleState extends State<InteractiveWidgetsExample> {
  late final NodeFlowController<InteractiveNodeData, dynamic> _controller;
  late final NodeFlowTheme _theme;
  final ObservableList<String> _eventLog = ObservableList<String>();
  int _nodeCounter = 4;

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    _controller = NodeFlowController<InteractiveNodeData, dynamic>(
      config: NodeFlowConfig(),
      nodes: [
        _createButtonNode('node-1', const Offset(100, 100)),
        _createTextFieldNode('node-2', const Offset(400, 100)),
        _createSliderNode('node-3', const Offset(100, 350)),
      ],
    );
  }

  Node<InteractiveNodeData> _createButtonNode(String id, Offset position) {
    return Node<InteractiveNodeData>(
      id: id,
      type: 'button',
      position: position,
      data: ButtonNodeData(),
      size: const Size(200, 150),
      inputPorts: [
        Port(
          id: 'input',
          name: 'In',
          position: PortPosition.left,
          offset: Offset(-2, 75),
        ),
      ],
      outputPorts: [
        Port(
          id: 'output',
          name: 'Out',
          position: PortPosition.right,
          offset: Offset(2, 75),
        ),
      ],
    );
  }

  Node<InteractiveNodeData> _createTextFieldNode(String id, Offset position) {
    return Node<InteractiveNodeData>(
      id: id,
      type: 'textfield',
      position: position,
      data: TextFieldNodeData(),
      size: const Size(220, 150),
      inputPorts: [
        Port(
          id: 'input',
          name: 'In',
          position: PortPosition.left,
          offset: Offset(-2, 75),
        ),
      ],
      outputPorts: [
        Port(
          id: 'output',
          name: 'Out',
          position: PortPosition.right,
          offset: Offset(2, 75),
        ),
      ],
    );
  }

  Node<InteractiveNodeData> _createSliderNode(String id, Offset position) {
    return Node<InteractiveNodeData>(
      id: id,
      type: 'slider',
      position: position,
      data: SliderNodeData(),
      size: const Size(220, 150),
      inputPorts: [
        Port(
          id: 'input',
          name: 'In',
          position: PortPosition.left,
          offset: Offset(-2, 75),
        ),
      ],
      outputPorts: [
        Port(
          id: 'output',
          name: 'Out',
          position: PortPosition.right,
          offset: Offset(2, 75),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _logEvent(String event) {
    runInAction(() {
      _eventLog.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)} $event',
      );
      if (_eventLog.length > 20) {
        _eventLog.removeLast();
      }
    });
  }

  void _addButtonNode() {
    final node = _createButtonNode(
      'node-$_nodeCounter',
      Offset(100 + (_nodeCounter * 30.0), 100 + (_nodeCounter * 30.0)),
    );
    _controller.addNode(node);
    _nodeCounter++;
  }

  void _addTextFieldNode() {
    final node = _createTextFieldNode(
      'node-$_nodeCounter',
      Offset(100 + (_nodeCounter * 30.0), 100 + (_nodeCounter * 30.0)),
    );
    _controller.addNode(node);
    _nodeCounter++;
  }

  void _addSliderNode() {
    final node = _createSliderNode(
      'node-$_nodeCounter',
      Offset(100 + (_nodeCounter * 30.0), 100 + (_nodeCounter * 30.0)),
    );
    _controller.addNode(node);
    _nodeCounter++;
  }

  Widget _buildNode(BuildContext context, Node<InteractiveNodeData> node) {
    final outerBorderRadius = _theme.nodeTheme.borderRadius;
    final borderWidth = _theme.nodeTheme.borderWidth;
    final outerRadius = outerBorderRadius.topLeft.x;
    final innerRadius = math.max(0.0, outerRadius - borderWidth);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: node.data.backgroundColor,
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            node.data.label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: node.data.foregroundColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildInteractiveContent(node)),
        ],
      ),
    );
  }

  Widget _buildInteractiveContent(Node<InteractiveNodeData> node) {
    final data = node.data;
    switch (data) {
      case ButtonNodeData():
        return _ButtonNodeContent(
          data: data,
          onPressed: () {
            _logEvent('Button pressed in ${node.id}');
            runInAction(() => data.counter.value++);
          },
        );
      case TextFieldNodeData():
        return _TextFieldNodeContent(
          data: data,
          onChanged: (text) {
            _logEvent('Text changed in ${node.id}: "$text"');
            runInAction(() => data.text.value = text);
          },
          onSubmitted: (text) {
            _logEvent('Text submitted in ${node.id}: "$text"');
          },
        );
      case SliderNodeData():
        return _SliderNodeContent(
          data: data,
          onChanged: (value) {
            _logEvent(
              'Slider changed in ${node.id}: ${value.toStringAsFixed(2)}',
            );
            runInAction(() => data.sliderValue.value = value);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: _controller,
      onReset: () {
        _controller.clearGraph();
        _eventLog.clear();
        _nodeCounter = 4;
        _controller.addNode(
          _createButtonNode('node-1', const Offset(100, 100)),
        );
        _controller.addNode(
          _createTextFieldNode('node-2', const Offset(400, 100)),
        );
        _controller.addNode(
          _createSliderNode('node-3', const Offset(100, 350)),
        );
        _controller.fitToView();
      },
      child: NodeFlowEditor<InteractiveNodeData, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: _theme,
        events: NodeFlowEvents(onInit: () => _controller.fitToView()),
      ),
      children: [
        const SectionTitle('About'),
        SectionContent(
          child: InfoCard(
            title: 'Test Instructions',
            content:
                'Drag nodes FAR outside the visible area, then interact with buttons/textfields/sliders. '
                'If gestures work, events will appear in the log.',
          ),
        ),
        const SectionTitle('Add Nodes'),
        SectionContent(
          child: Grid2Cols(
            buttons: [
              GridButton(
                label: 'Button',
                icon: Icons.smart_button,
                onPressed: _addButtonNode,
              ),
              GridButton(
                label: 'TextField',
                icon: Icons.text_fields,
                onPressed: _addTextFieldNode,
              ),
              GridButton(
                label: 'Slider',
                icon: Icons.tune,
                onPressed: _addSliderNode,
              ),
            ],
          ),
        ),
        const SectionTitle('Event Log'),
        SectionContent(
          child: SizedBox(
            height: 200,
            child: Observer(
              builder: (_) {
                if (_eventLog.isEmpty) {
                  return Center(
                    child: Text(
                      'No events yet. Interact with nodes!',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: _eventLog.length,
                  itemBuilder: (context, index) {
                    final isRecent = index < 3;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        _eventLog[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: isRecent
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.7),
                          fontWeight: isRecent
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// MobX Observable Data Models
// ============================================================

/// Base class for interactive node data with MobX observables.
sealed class InteractiveNodeData {
  String get label;

  Color get backgroundColor;

  Color get foregroundColor;
}

/// Button node data with observable counter.
class ButtonNodeData extends InteractiveNodeData {
  final Observable<int> counter = Observable(0);

  @override
  String get label => 'Button Node';

  @override
  Color get backgroundColor => Colors.blue.shade100;

  @override
  Color get foregroundColor => Colors.blue.shade800;
}

/// TextField node data with observable text.
class TextFieldNodeData extends InteractiveNodeData {
  final Observable<String> text = Observable('');

  @override
  String get label => 'TextField Node';

  @override
  Color get backgroundColor => Colors.green.shade100;

  @override
  Color get foregroundColor => Colors.green.shade800;
}

/// Slider node data with observable value.
class SliderNodeData extends InteractiveNodeData {
  final Observable<double> sliderValue = Observable(0.5);

  @override
  String get label => 'Slider Node';

  @override
  Color get backgroundColor => Colors.orange.shade100;

  @override
  Color get foregroundColor => Colors.orange.shade800;
}

// ============================================================
// Interactive Node Content Widgets (with MobX Observer)
// ============================================================

class _ButtonNodeContent extends StatelessWidget {
  const _ButtonNodeContent({required this.data, required this.onPressed});

  final ButtonNodeData data;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Click Me', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        Observer(
          builder: (_) {
            return Text(
              'Count: ${data.counter.value}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TextFieldNodeContent extends StatefulWidget {
  const _TextFieldNodeContent({
    required this.data,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextFieldNodeData data;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<_TextFieldNodeContent> createState() => _TextFieldNodeContentState();
}

class _TextFieldNodeContentState extends State<_TextFieldNodeContent> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.data.text.value);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 36,
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Type here...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.green.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.green.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
          ),
        ),
        const SizedBox(height: 8),
        Observer(
          builder: (_) {
            return Text(
              'Length: ${widget.data.text.value.length}',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
            );
          },
        ),
      ],
    );
  }
}

class _SliderNodeContent extends StatelessWidget {
  const _SliderNodeContent({required this.data, required this.onChanged});

  final SliderNodeData data;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.orange.shade600,
            inactiveTrackColor: Colors.orange.shade200,
            thumbColor: Colors.orange.shade700,
            overlayColor: Colors.orange.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Observer(
            builder: (_) {
              return Slider(
                value: data.sliderValue.value,
                onChanged: onChanged,
              );
            },
          ),
        ),
        Observer(
          builder: (_) {
            return Text(
              'Value: ${(data.sliderValue.value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            );
          },
        ),
      ],
    );
  }
}
