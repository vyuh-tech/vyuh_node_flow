import 'package:flutter/material.dart';

/// Function type for deferred example loading.
/// Returns a widget builder after loading the deferred library.
typedef ExampleLoader = Future<Widget Function(BuildContext)> Function();

/// Represents a single example with deferred loading support.
class Example {
  final String id;
  final String title;
  final String description;
  final IconData? icon;

  /// Loader function that loads the deferred library and returns the builder.
  final ExampleLoader loader;

  /// Cached builder after loading.
  Widget Function(BuildContext)? _cachedBuilder;

  Example({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    required this.loader,
  });

  /// Whether this example has been loaded.
  bool get isLoaded => _cachedBuilder != null;

  /// Loads the example and returns the widget.
  /// Caches the builder after first load.
  Future<Widget> load(BuildContext context) async {
    _cachedBuilder ??= await loader();
    return _cachedBuilder!(context);
  }

  /// Builds the widget synchronously if already loaded.
  /// Throws if not loaded - use [load] first or [ExampleLoader] widget.
  Widget build(BuildContext context) {
    if (_cachedBuilder == null) {
      throw StateError('Example "$id" not loaded. Call load() first.');
    }
    return _cachedBuilder!(context);
  }
}

/// Represents a category of examples with its examples
class ExampleCategory {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<Example> examples;

  const ExampleCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.examples,
  });
}
