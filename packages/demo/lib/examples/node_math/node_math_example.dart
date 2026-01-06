import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/math_canvas.dart';
import 'widgets/math_toolbox.dart';

/// Visual math expression editor demonstrating vyuh_node_flow capabilities.
///
/// **Key Features:**
/// - Number nodes: editable numeric constants
/// - Operator nodes: binary arithmetic (+, -, ×, ÷)
/// - Function nodes: unary math functions (sin, cos, √)
/// - Result nodes: display computed expression and value
///
/// **Architecture:**
/// - [MathState]: MobX store owning nodes, connections, and evaluation results
/// - [MathCanvas]: bridges MathState with NodeFlowController, handles sync
/// - [MathEvaluator]: stateless graph evaluation with topological sort
class NodeMathExample extends StatefulWidget {
  const NodeMathExample({super.key});

  @override
  State<NodeMathExample> createState() => _NodeMathExampleState();
}

class _NodeMathExampleState extends State<NodeMathExample> {
  final _state = MathState();
  late NodeFlowTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = MathTheme.nodeFlowTheme;
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  /// Clears all nodes and connections from the canvas.
  void _handleReset() {
    _state.clearAll();
  }

  /// Updates the connection style theme (straight, bezier, smoothstep).
  void _updateTheme(NodeFlowTheme newTheme) {
    setState(() {
      _theme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      onReset: _handleReset,
      child: MathCanvas(state: _state, theme: _theme),
      children: [
        MathToolbox(state: _state),
        ConnectionStyleSelector(theme: _theme, onThemeChanged: _updateTheme),
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
