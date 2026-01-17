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
  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final messages = MathValidator.validate(
          widget.state.controller,
          widget.state.results,
        );

        if (messages.isEmpty) {
          return const SizedBox.shrink();
        }

        return SectionContent(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: messages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                return _ValidationListItem(
                  message: messages[index],
                  onFocus: messages[index].nodeId != null
                      ? () {
                          widget.state.controller.selectNode(
                            messages[index].nodeId!,
                          );
                        }
                      : null,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ValidationListItem extends StatelessWidget {
  final ValidationMessage message;
  final VoidCallback? onFocus;

  const _ValidationListItem({required this.message, this.onFocus});

  Color _getColor(BuildContext context, ValidationLevel level, String title) {
    if (level == ValidationLevel.error) {
      return Colors.red;
    }

    // Blue theme for "Get Started" and "Expression Complete" messages
    if (title == 'Get Started' || title == 'Expression Complete') {
      return DemoTheme.info;
    }

    // Orange/amber for all other info and warning messages
    return Colors.orange;
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
    final color = _getColor(context, message.level, message.title);
    final icon = _getIcon(message.level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  message.message,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (onFocus != null) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onFocus,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.lightbulb_outline, size: 14, color: color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
