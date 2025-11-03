import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExampleNotFound extends StatelessWidget {
  final String? categoryId;
  final String? exampleId;

  const ExampleNotFound({super.key, this.categoryId, this.exampleId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String message;
    if (categoryId != null && exampleId != null) {
      message = 'Example "$exampleId" not found in category "$categoryId"';
    } else if (categoryId != null) {
      message = 'Category "$categoryId" not found';
    } else {
      message = 'Page not found';
    }

    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 120,
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 32),
              Text(
                'Oops!',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go to Examples'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
