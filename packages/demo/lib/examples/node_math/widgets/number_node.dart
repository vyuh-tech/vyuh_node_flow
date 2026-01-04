import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../evaluation.dart';
import '../models.dart';
import '../theme.dart';

/// Content widget for a number input node - white input field.
class NumberNodeContent extends StatefulWidget {
  final NumberData data;
  final EvalResult? result;
  final ValueChanged<NumberData>? onChanged;

  const NumberNodeContent({
    super.key,
    required this.data,
    this.result,
    this.onChanged,
  });

  @override
  State<NumberNodeContent> createState() => _NumberNodeContentState();
}

class _NumberNodeContentState extends State<NumberNodeContent> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.data.value));
  }

  @override
  void didUpdateWidget(NumberNodeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.value != widget.data.value && !_isFocused) {
      _controller.text = _formatValue(widget.data.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  void _handleChange(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null) {
      widget.onChanged?.call(widget.data.copyWith(value: parsed));
    }
  }

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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Focus(
            onFocusChange: (focused) => setState(() => _isFocused = focused),
            child: TextField(
              controller: _controller,
              style: const TextStyle(
                color: MathColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.left,
              cursorColor: MathColors.textPrimary,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.-]')),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: _handleChange,
            ),
          ),
        ),
      ),
    );
  }
}
