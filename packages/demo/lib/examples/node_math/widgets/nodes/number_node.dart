import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models.dart';
import '../../presentation/theme.dart';
import '../../utils/formatters.dart';

class NumberNodeContent extends StatefulWidget {
  final NumberData data;
  final ValueChanged<NumberData>? onChanged;

  const NumberNodeContent({super.key, required this.data, this.onChanged});

  @override
  State<NumberNodeContent> createState() => _NumberNodeContentState();
}

class _NumberNodeContentState extends State<NumberNodeContent> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: MathFormatters.formatForInput(widget.data.value),
    );
  }

  @override
  void didUpdateWidget(NumberNodeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.value != widget.data.value && !_isFocused) {
      _controller.text = MathFormatters.formatForInput(widget.data.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      decoration: MathNodeStyles.nodeDecoration,
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
