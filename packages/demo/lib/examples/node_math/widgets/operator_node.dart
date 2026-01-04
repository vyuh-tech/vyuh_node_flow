import 'package:flutter/material.dart';

import '../constants.dart';
import '../models.dart';
import '../theme.dart';

/// Content widget for an operator node - matches reference design.
class OperatorNodeContent extends StatelessWidget {
  final OperatorData data;
  final ValueChanged<MathOperator>? onOperatorChanged;

  const OperatorNodeContent({
    super.key,
    required this.data,
    this.onOperatorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MathColors.nodeBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          for (int i = 0; i < MathOperator.values.length; i++) ...[
            _OperatorButton(
              symbol: MathOperator.values[i].symbol,
              isActive: MathOperator.values[i] == data.operator,
              onPressed: onOperatorChanged != null
                  ? () => onOperatorChanged!(MathOperator.values[i])
                  : null,
            ),
            if (i < MathOperator.values.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _OperatorButton extends StatelessWidget {
  final String symbol;
  final bool isActive;
  final VoidCallback? onPressed;

  const _OperatorButton({
    required this.symbol,
    required this.isActive,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? MathColors.operatorActive : const Color(0xFF424242),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
