import 'package:flutter/material.dart';

import 'design_kit/theme.dart';
import 'example_model.dart';

/// Widget that handles deferred loading of examples.
///
/// Shows a loading indicator while the example loads, then displays it.
class DeferredExampleLoader extends StatefulWidget {
  final Example example;

  const DeferredExampleLoader({super.key, required this.example});

  @override
  State<DeferredExampleLoader> createState() => _DeferredExampleLoaderState();
}

class _DeferredExampleLoaderState extends State<DeferredExampleLoader> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.example.load();
  }

  @override
  void didUpdateWidget(DeferredExampleLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.example.id != widget.example.id) {
      _loadFuture = widget.example.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If already loaded, build immediately
    if (widget.example.isLoaded) {
      return widget.example.build(context);
    }

    // Otherwise show loading indicator while loading
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error.toString());
          }
          // Build synchronously after async load completes
          return widget.example.build(context);
        }
        return const _LoadingView();
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DemoTheme.accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading example...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 32, color: DemoTheme.error),
          const SizedBox(height: 12),
          Text(
            'Failed to load example',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Context that indicates whether the app is running in embed mode.
///
/// When in embed mode, certain UI elements like the navigation drawer
/// and control panel should be hidden.
class EmbedContext extends InheritedWidget {
  /// Whether embed mode is active.
  final bool isEmbed;

  const EmbedContext({super.key, required this.isEmbed, required super.child});

  /// Returns true if currently in embed mode.
  static bool of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<EmbedContext>();
    return widget?.isEmbed ?? false;
  }

  @override
  bool updateShouldNotify(EmbedContext oldWidget) =>
      isEmbed != oldWidget.isEmbed;
}

/// Wrapper for embedding examples in iframes or documentation.
///
/// Shows just the raw example content without any navigation,
/// control panel, or header chrome. Handles deferred loading automatically.
/// Uses a transparent background to allow the host page's background to show through.
class EmbedWrapper extends StatelessWidget {
  final Example example;

  const EmbedWrapper({super.key, required this.example});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: EmbedContext(
        isEmbed: true,
        child: DeferredExampleLoader(example: example),
      ),
    );
  }
}
