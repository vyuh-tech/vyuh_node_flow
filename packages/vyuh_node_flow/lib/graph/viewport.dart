import 'package:flutter/material.dart';

/// Represents the viewport transformation for a node flow graph.
///
/// The viewport defines how the infinite graph coordinate space is mapped
/// to the finite screen space. It consists of:
/// - Pan offset ([x], [y]): Translation of the graph on screen
/// - Zoom level ([zoom]): Scale factor for the graph
///
/// Graph coordinates are independent of screen size and allow nodes to be
/// positioned anywhere. The viewport transforms these coordinates to screen
/// pixels for rendering.
///
/// Example:
/// ```dart
/// // Create a viewport centered at origin with 100% zoom
/// final viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
///
/// // Convert screen position to graph coordinates
/// final graphPos = viewport.screenToGraph(Offset(100, 100));
///
/// // Convert graph position to screen coordinates
/// final screenPos = viewport.graphToScreen(Offset(50, 50));
///
/// // Check if a rectangle is visible
/// final isVisible = viewport.isRectVisible(
///   Rect.fromLTWH(0, 0, 100, 100),
///   Size(800, 600),
/// );
/// ```
final class GraphViewport {
  /// Creates a viewport with the specified pan and zoom.
  ///
  /// Parameters:
  /// - [x]: Horizontal pan offset in screen pixels (default: 0.0)
  /// - [y]: Vertical pan offset in screen pixels (default: 0.0)
  /// - [zoom]: Zoom scale factor, where 1.0 is 100% (default: 1.0)
  ///
  /// The pan offset represents how much the graph has been translated
  /// on screen. Positive values move the graph right/down.
  const GraphViewport({this.x = 0.0, this.y = 0.0, this.zoom = 1.0});

  /// Horizontal pan offset in screen pixels.
  ///
  /// Positive values translate the graph to the right.
  final double x;

  /// Vertical pan offset in screen pixels.
  ///
  /// Positive values translate the graph downward.
  final double y;

  /// Zoom scale factor.
  ///
  /// - `1.0` represents 100% zoom (no scaling)
  /// - Values > 1.0 zoom in (graph appears larger)
  /// - Values < 1.0 zoom out (graph appears smaller)
  final double zoom;

  /// Transforms a screen point to graph coordinates.
  ///
  /// Converts a position in screen pixels to the corresponding position
  /// in the graph's coordinate space, accounting for pan and zoom.
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);
  /// final graphPos = viewport.screenToGraph(Offset(200, 150));
  /// // Returns: Offset(50, 50) in graph coordinates
  /// ```
  Offset screenToGraph(Offset screenPoint) {
    return Offset((screenPoint.dx - x) / zoom, (screenPoint.dy - y) / zoom);
  }

  /// Transforms a screen delta to graph delta (without translation).
  ///
  /// Converts a change in screen position to the corresponding change
  /// in graph coordinates. Unlike [screenToGraph], this only applies
  /// zoom scaling, not pan translation.
  ///
  /// Useful for converting mouse drag distances to graph movement.
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(zoom: 2.0);
  /// final graphDelta = viewport.screenToGraphDelta(Offset(100, 50));
  /// // Returns: Offset(50, 25) in graph units
  /// ```
  Offset screenToGraphDelta(Offset screenDelta) {
    return Offset(screenDelta.dx / zoom, screenDelta.dy / zoom);
  }

  /// Transforms a graph point to screen coordinates.
  ///
  /// Converts a position in graph coordinates to the corresponding position
  /// in screen pixels, accounting for pan and zoom.
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);
  /// final screenPos = viewport.graphToScreen(Offset(50, 50));
  /// // Returns: Offset(200, 150) in screen pixels
  /// ```
  Offset graphToScreen(Offset graphPoint) {
    return Offset(graphPoint.dx * zoom + x, graphPoint.dy * zoom + y);
  }

  /// Gets the visible area in graph coordinates.
  ///
  /// Returns a rectangle representing what portion of the graph is currently
  /// visible in the given screen size. Useful for culling off-screen elements.
  ///
  /// Parameters:
  /// - [screenSize]: The size of the viewport in screen pixels
  ///
  /// Returns: A [Rect] in graph coordinates representing the visible area
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
  /// final visible = viewport.getVisibleArea(Size(800, 600));
  /// // Returns: Rect from (0,0) to (800,600) in graph coordinates
  /// ```
  Rect getVisibleArea(Size screenSize) {
    final topLeft = screenToGraph(Offset.zero);
    final bottomRight = screenToGraph(
      Offset(screenSize.width, screenSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Checks if a rectangle is visible in the current viewport.
  ///
  /// Determines whether any part of the given rectangle (in graph coordinates)
  /// is visible within the screen area. Used for visibility culling and
  /// optimization.
  ///
  /// Parameters:
  /// - [rect]: Rectangle in graph coordinates to check
  /// - [screenSize]: The size of the viewport in screen pixels
  ///
  /// Returns: `true` if the rectangle overlaps the visible area
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
  /// final nodeRect = Rect.fromLTWH(100, 100, 50, 50);
  /// final isVisible = viewport.isRectVisible(nodeRect, Size(800, 600));
  /// ```
  bool isRectVisible(Rect rect, Size screenSize) {
    final visibleArea = getVisibleArea(screenSize);
    return visibleArea.overlaps(rect);
  }

  /// Creates a viewport from JSON data.
  ///
  /// Deserializes a viewport from a JSON map. Missing values default to
  /// identity viewport (0, 0, 1.0).
  ///
  /// Example:
  /// ```dart
  /// final json = {'x': 100.0, 'y': 50.0, 'zoom': 1.5};
  /// final viewport = GraphViewport.fromJson(json);
  /// ```
  factory GraphViewport.fromJson(Map<String, dynamic> json) {
    return GraphViewport(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Serializes this viewport to JSON.
  ///
  /// Returns a map suitable for JSON encoding containing x, y, and zoom values.
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 100, y: 50, zoom: 1.5);
  /// final json = viewport.toJson();
  /// // Returns: {'x': 100.0, 'y': 50.0, 'zoom': 1.5}
  /// ```
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'zoom': zoom};

  /// Creates a new viewport with updated values.
  ///
  /// Returns a copy of this viewport with the specified properties changed.
  /// Unspecified properties retain their current values.
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 100, y: 50, zoom: 1.0);
  /// final zoomed = viewport.copyWith(zoom: 2.0);
  /// // New viewport: x=100, y=50, zoom=2.0
  /// ```
  GraphViewport copyWith({double? x, double? y, double? zoom}) {
    return GraphViewport(
      x: x ?? this.x,
      y: y ?? this.y,
      zoom: zoom ?? this.zoom,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphViewport &&
        other.x == x &&
        other.y == y &&
        other.zoom == zoom;
  }

  @override
  int get hashCode => Object.hash(x, y, zoom);

  @override
  String toString() => 'GraphViewport(x: $x, y: $y, zoom: $zoom)';
}
