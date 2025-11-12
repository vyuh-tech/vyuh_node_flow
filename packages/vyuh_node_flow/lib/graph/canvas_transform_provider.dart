import 'package:flutter/widgets.dart';

/// Provides access to the canvas transformation matrix for descendant widgets.
///
/// This allows widgets deep in the tree (like PortWidget) to access the current
/// canvas zoom level without explicitly passing it through constructors.
///
/// Example:
/// ```dart
/// // Access the scale from any descendant widget
/// final scale = CanvasTransformProvider.of(context)?.scale ?? 1.0;
/// ```
class CanvasTransformProvider extends InheritedWidget {
  const CanvasTransformProvider({
    super.key,
    required this.transform,
    required super.child,
  });

  final Matrix4 transform;

  /// Gets the current canvas scale (zoom level) from the transform matrix.
  ///
  /// Returns 1.0 if no transform is available.
  double get scale {
    final scaleX = transform.getMaxScaleOnAxis();
    return scaleX;
  }

  /// Retrieves the nearest [CanvasTransformProvider] ancestor from the widget tree.
  ///
  /// Returns null if no provider is found.
  static CanvasTransformProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CanvasTransformProvider>();
  }

  @override
  bool updateShouldNotify(CanvasTransformProvider oldWidget) {
    return transform != oldWidget.transform;
  }
}
