import 'package:flutter/material.dart';

import '../../../shared/ui_widgets.dart';
import '../constants.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';

/// Side panel containing buttons to add new nodes to the canvas.
///
/// Organized into sections: Inputs (Number), Operators, Functions, Output (Result).
/// Each button creates a new node with default values and adds it to the graph.
class MathToolbox extends StatelessWidget {
  final MathState state;

  const MathToolbox({super.key, required this.state});

  /// Creates a number node with default value of 10.
  void _addNumber() {
    final id = state.generateNodeId();
    state.addNode(NumberData(id: id, value: 10));
  }

  /// Creates an operator node defaulting to addition.
  void _addOperator() {
    final id = state.generateNodeId();
    state.addNode(OperatorData(id: id, operator: MathOperator.add));
  }

  /// Creates a function node with the specified mathematical function.
  void _addFunction(MathFunction func) {
    final id = state.generateNodeId();
    state.addNode(FunctionData(id: id, function: func));
  }

  /// Creates a result node for displaying computed output.
  void _addResult() {
    final id = state.generateNodeId();
    state.addNode(ResultData(id: id));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Inputs'),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ToolboxButton(
                label: 'Number',
                icon: Icons.pin,
                color: MathColors.portNumber,
                onPressed: _addNumber,
              ),
            ],
          ),
        ),
        const SectionTitle('Operators'),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ToolboxButton(
                label: 'Operator',
                icon: Icons.calculate,
                color: MathColors.portOperator,
                onPressed: _addOperator,
              ),
            ],
          ),
        ),
        const SectionTitle('Functions'),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ToolboxButton(
                label: 'sin',
                icon: Icons.functions,
                color: MathColors.portOperator,
                onPressed: () => _addFunction(MathFunction.sin),
              ),
              const SizedBox(height: 4),
              _ToolboxButton(
                label: 'cos',
                icon: Icons.functions,
                color: MathColors.portOperator,
                onPressed: () => _addFunction(MathFunction.cos),
              ),
              const SizedBox(height: 4),
              _ToolboxButton(
                label: 'sqrt',
                icon: Icons.functions,
                color: MathColors.portOperator,
                onPressed: () => _addFunction(MathFunction.sqrt),
              ),
            ],
          ),
        ),
        const SectionTitle('Output'),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ToolboxButton(
                label: 'Result',
                icon: Icons.output,
                color: MathColors.portResult,
                onPressed: _addResult,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Styled button for the toolbox with icon, label, and semantic color.
class _ToolboxButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ToolboxButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
