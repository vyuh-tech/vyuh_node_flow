import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Content widget for a function node.
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
