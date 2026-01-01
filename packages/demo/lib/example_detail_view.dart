import 'package:flutter/material.dart';

import 'embed_wrapper.dart';
import 'example_model.dart';

/// Provides example metadata to child widgets via InheritedWidget
class ExampleContext extends InheritedWidget {
  final Example example;

  const ExampleContext({
    super.key,
    required this.example,
    required super.child,
  });

  static ExampleContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ExampleContext>();
  }

  /// Get the current example's metadata, or null if not available
  static Example? maybeOf(BuildContext context) {
    return of(context)?.example;
  }

  @override
  bool updateShouldNotify(ExampleContext oldWidget) {
    return example.id != oldWidget.example.id;
  }
}

class ExampleDetailView extends StatelessWidget {
  final Example? example;

  const ExampleDetailView({super.key, this.example});

  @override
  Widget build(BuildContext context) {
    if (example == null) {
      return _buildEmptyState(context);
    }

    // No header - the header will be shown in the right panel
    // Wrap with ExampleContext so child widgets can access example metadata
    // Use DeferredExampleLoader to handle async loading
    return ExampleContext(
      example: example!,
      child: DeferredExampleLoader(example: example!),
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
}
