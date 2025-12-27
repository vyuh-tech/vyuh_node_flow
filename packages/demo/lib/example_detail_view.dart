import 'package:flutter/material.dart';

import 'example_model.dart';
import 'shared/responsive.dart';

class ExampleDetailView extends StatelessWidget {
  final Example? example;

  const ExampleDetailView({super.key, this.example});

  @override
  Widget build(BuildContext context) {
    if (example == null) {
      return _buildEmptyState(context);
    }

    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final useDrawerNavigation = isMobile || isTablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Skip header in mobile/tablet mode as title is shown in AppBar
        if (!useDrawerNavigation) _buildHeader(context, example!),
        Expanded(child: example!.builder(context)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select an example',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an example from the navigation to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Example example) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      constraints: BoxConstraints(minHeight: isCompact ? 60 : 75),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (example.icon != null) ...[
            Container(
              padding: EdgeInsets.all(isCompact ? 6 : 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                example.icon,
                size: isCompact ? 16 : 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  example.title,
                  style:
                      (isCompact
                              ? theme.textTheme.titleSmall
                              : theme.textTheme.titleMedium)
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  example.description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
