import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';
import 'core/models.dart';
import 'presentation/state.dart';
import 'presentation/theme.dart';
import 'widgets/canvas/math_canvas.dart';
import 'widgets/stats/math_stats_widget.dart';
import 'widgets/toolbox/math_toolbox.dart';
import 'widgets/validator/math_validator_widget.dart';

class NodeMathExample extends StatefulWidget {
  const NodeMathExample({super.key});

  @override
  State<NodeMathExample> createState() => _NodeMathExampleState();
}

class _NodeMathExampleState extends State<NodeMathExample> {
  late final MathState _state;
  late NodeFlowTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = MathTheme.nodeFlowTheme;

    final controller = NodeFlowController<MathNodeData, dynamic>(
      config: NodeFlowConfig(minZoom: 0.25, maxZoom: 2.0),
    );

    _state = MathState(controller);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _handleReset() {
    _state.clearAll();
  }

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
        MathValidatorWidget(state: _state),
        MathToolbox(state: _state),
        ConnectionStyleSelector(theme: _theme, onThemeChanged: _updateTheme),
        MathStatsWidget(state: _state),
      ],
    );
  }
}
