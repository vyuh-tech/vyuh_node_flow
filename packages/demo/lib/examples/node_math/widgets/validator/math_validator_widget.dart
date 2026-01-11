library;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../../../design_kit/theme.dart';
import '../../../../shared/ui_widgets.dart';
import '../../presentation/state.dart';
import 'math_validator.dart';

class MathValidatorWidget extends StatefulWidget {
  final MathState state;

  const MathValidatorWidget({super.key, required this.state});

  @override
  State<MathValidatorWidget> createState() => _MathValidatorWidgetState();
}

class _MathValidatorWidgetState extends State<MathValidatorWidget> {
  // Always expanded to provide continuous guidance
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final messages = MathValidator.validate(
          widget.state.controller,
          widget.state.results,
        );

        // Always show at least one message for guidance
        final topMessage = messages.first;
        final hasMultiple = messages.length > 1;

        return SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ValidationCard(
                message: topMessage,
                isExpanded: _isExpanded,
                onToggle: hasMultiple
                    ? () => setState(() => _isExpanded = !_isExpanded)
                    : null,
                onNodeHighlight: (nodeId) {
                  widget.state.controller.selectNode(nodeId);
                },
                state: widget.state,
              ),
              if (_isExpanded && hasMultiple) ...[
                const SizedBox(height: 8),
                ...messages
                    .skip(1)
                    .map(
                      (msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ValidationCard(
                          message: msg,
                          isExpanded: true,
                          onNodeHighlight: (nodeId) {
                            widget.state.controller.selectNode(nodeId);
                          },
                          state: widget.state,
                        ),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ValidationCard extends StatelessWidget {
  final ValidationMessage message;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final void Function(String)? onNodeHighlight;
  final MathState? state;

  const _ValidationCard({
    required this.message,
    required this.isExpanded,
    this.onToggle,
    this.onNodeHighlight,
    this.state,
  });

  Color _getColor(BuildContext context, ValidationLevel level) {
    return switch (level) {
      ValidationLevel.info => DemoTheme.info,
      ValidationLevel.warning => Colors.orange,
      ValidationLevel.error => Colors.red,
    };
  }

  IconData _getIcon(ValidationLevel level) {
    return switch (level) {
      ValidationLevel.info => Icons.info_outline_rounded,
      ValidationLevel.warning => Icons.warning_amber_rounded,
      ValidationLevel.error => Icons.error_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final color = _getColor(context, message.level);
    final icon = _getIcon(message.level);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  if (onToggle != null)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: color.withValues(alpha: 0.7),
                    ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: color.withValues(alpha: isDark ? 0.2 : 0.15),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                  if (message.nodeId != null && onNodeHighlight != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        if (onNodeHighlight != null) {
                          onNodeHighlight!(message.nodeId!);
                        }
                        if (state != null) {
                          state!.controller.selectNode(message.nodeId!);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Highlight Node',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
