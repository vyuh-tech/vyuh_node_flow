import 'package:flutter/material.dart';

import '../../shared/ui_widgets.dart';
import 'state.dart';
import 'widgets/math_canvas.dart';
import 'widgets/math_toolbox.dart';

/// Node Math Calculator example.
///
/// Demonstrates building a visual math expression editor using vyuh_node_flow.
/// Features:
/// - Number input nodes with editable values
/// - Operator nodes (+, -, ×, ÷)
/// - Function nodes (sin, cos, sqrt)
/// - Result node showing expression and computed value
/// - Live evaluation with cycle detection
class NodeMathExample extends StatefulWidget {
  const NodeMathExample({super.key});

  @override
  State<NodeMathExample> createState() => _NodeMathExampleState();
}

class _NodeMathExampleState extends State<NodeMathExample> {
  final _state = MathState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _handleReset() {
    _state.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      onReset: _handleReset,
      child: MathCanvas(state: _state),
      children: [
        MathToolbox(state: _state),
        const Spacer(),
        const SectionTitle('Instructions'),
        const SectionContent(
          child: InfoCard(
            title: 'How to Use',
            content: '''
1. Add nodes from the toolbox
2. Connect output ports to input ports
3. Edit number values directly
4. Click operator buttons to change operation
5. Result node shows live computation''',
          ),
        ),
      ],
    );
  }
}
