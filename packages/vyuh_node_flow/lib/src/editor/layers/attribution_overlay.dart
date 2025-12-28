import 'package:flutter/material.dart';

/// Attribution overlay widget that renders "Powered by Vyuh" label at the bottom center
class AttributionOverlay extends StatelessWidget {
  const AttributionOverlay({super.key, required this.show});

  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      bottom: 4,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Powered by Vyuh',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
