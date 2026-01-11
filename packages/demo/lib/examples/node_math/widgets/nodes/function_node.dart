import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../presentation/theme.dart';

/// Content widget displaying the function symbol (sin, cos, √).
///
/// Static display only - the function type is fixed at node creation.
class FunctionNodeContent extends StatelessWidget {
  final FunctionData data;

  const FunctionNodeContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MathNodeStyles.nodeDecorationNoBorder,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Text(
          data.function.symbol,
          style: const TextStyle(
            color: MathColors.portOperator,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
