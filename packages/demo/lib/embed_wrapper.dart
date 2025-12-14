import 'package:flutter/material.dart';

import 'example_model.dart';

/// Minimal wrapper for embedding examples in iframes.
///
/// Shows the example with minimal chrome - just the example content
/// and optionally a small header with title and source link.
class EmbedWrapper extends StatelessWidget {
  final Example example;
  final bool showHeader;
  final VoidCallback? onSourceTap;

  const EmbedWrapper({
    super.key,
    required this.example,
    this.showHeader = true,
    this.onSourceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Minimal header for embedded view
          if (showHeader)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (example.icon != null) ...[
                    Icon(
                      example.icon,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      example.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onSourceTap != null)
                    TextButton.icon(
                      onPressed: onSourceTap,
                      icon: Icon(
                        Icons.code,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Source',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
          // Example content
          Expanded(child: example.builder(context)),
        ],
      ),
    );
  }
}

/// Embed wrapper without any header - just the raw example.
class EmbedWrapperMinimal extends StatelessWidget {
  final Example example;

  const EmbedWrapperMinimal({super.key, required this.example});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: example.builder(context));
  }
}
