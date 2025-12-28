import 'package:flutter/material.dart';

import 'coordinates.dart';

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
/// All coordinate transformations use typed extension types ([GraphPosition],
/// [ScreenPosition], [GraphOffset], [ScreenOffset]) to prevent accidentally
/// mixing coordinate spaces.
///
/// Example:
/// ```dart
/// // Create a viewport centered at origin with 100% zoom
/// final viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
///
/// // Convert screen position to graph coordinates (type-safe!)
/// final screenPos = ScreenPosition.fromXY(100, 100);
/// final graphPos = viewport.toGraph(screenPos);
///
/// // Convert graph position to screen coordinates
/// final nodePos = GraphPosition.fromXY(50, 50);
/// final screenNodePos = viewport.toScreen(nodePos);
///
/// // Check if a rectangle is visible
/// final bounds = GraphRect.fromLTWH(0, 0, 100, 100);
/// final isVisible = viewport.isRectVisible(bounds, Size(800, 600));
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

  // ============================================================================
  // Coordinate Transformations
  // ============================================================================

  /// Transforms a [ScreenPosition] to a [GraphPosition].
  ///
  /// Converts a position in screen pixels to the corresponding position
  /// in the graph's coordinate space, accounting for pan and zoom.
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);
  /// final screenPos = ScreenPosition.fromXY(200, 150);
  /// final graphPos = viewport.toGraph(screenPos);
  /// // Returns: GraphPosition(50, 50)
  /// ```
  GraphPosition toGraph(ScreenPosition screenPoint) {
    return GraphPosition(
      Offset((screenPoint.dx - x) / zoom, (screenPoint.dy - y) / zoom),
    );
  }

  /// Transforms a [ScreenOffset] to a [GraphOffset].
  ///
  /// Converts a change in screen position to the corresponding change
  /// in graph coordinates. Unlike [toGraph], this only applies
  /// zoom scaling, not pan translation.
  ///
  /// Useful for converting mouse drag distances to graph movement.
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(zoom: 2.0);
  /// final screenDrag = ScreenOffset.fromXY(100, 50);
  /// final graphDrag = viewport.toGraphOffset(screenDrag);
  /// // Returns: GraphOffset(50, 25)
  /// ```
  GraphOffset toGraphOffset(ScreenOffset screenOffset) {
    return GraphOffset(Offset(screenOffset.dx / zoom, screenOffset.dy / zoom));
  }

  /// Transforms a [GraphPosition] to a [ScreenPosition].
  ///
  /// Converts a position in graph coordinates to the corresponding position
  /// in screen pixels, accounting for pan and zoom.
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);
  /// final graphPos = GraphPosition.fromXY(50, 50);
  /// final screenPos = viewport.toScreen(graphPos);
  /// // Returns: ScreenPosition(200, 150)
  /// ```
  ScreenPosition toScreen(GraphPosition graphPoint) {
    return ScreenPosition(
      Offset(graphPoint.dx * zoom + x, graphPoint.dy * zoom + y),
    );
  }

  /// Transforms a [GraphOffset] to a [ScreenOffset].
  ///
  /// Converts a graph-space movement to screen-space movement,
  /// applying only zoom scaling (no translation).
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(zoom: 2.0);
  /// final graphDrag = GraphOffset.fromXY(50, 25);
  /// final screenDrag = viewport.toScreenOffset(graphDrag);
  /// // Returns: ScreenOffset(100, 50)
  /// ```
  ScreenOffset toScreenOffset(GraphOffset graphOffset) {
    return ScreenOffset(Offset(graphOffset.dx * zoom, graphOffset.dy * zoom));
  }

  /// Transforms a [GraphRect] to a [ScreenRect].
  ///
  /// Converts a rectangle in graph coordinates to screen coordinates,
  /// applying pan and zoom transformations.
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);
  /// final nodeBounds = GraphRect.fromLTWH(0, 0, 50, 50);
  /// final screenBounds = viewport.toScreenRect(nodeBounds);
  /// ```
  ScreenRect toScreenRect(GraphRect graphRect) {
    final topLeft = toScreen(graphRect.topLeft);
    final bottomRight = toScreen(graphRect.bottomRight);
    return ScreenRect.fromPoints(topLeft, bottomRight);
  }

  /// Transforms a [ScreenRect] to a [GraphRect].
  ///
  /// Converts a rectangle in screen coordinates to graph coordinates,
  /// applying inverse pan and zoom transformations.
  GraphRect toGraphRect(ScreenRect screenRect) {
    final topLeft = toGraph(screenRect.topLeft);
    final bottomRight = toGraph(ScreenPosition(screenRect.rect.bottomRight));
    return GraphRect.fromPoints(topLeft, bottomRight);
  }

  // ============================================================================
  // Visibility and Area Queries
  // ============================================================================

  /// Gets the visible area in graph coordinates.
  ///
  /// Returns a [GraphRect] representing what portion of the graph is currently
  /// visible in the given screen size. Useful for culling off-screen elements.
  ///
  /// Parameters:
  /// - [screenSize]: The size of the viewport in screen pixels
  ///
  /// Returns: A [GraphRect] representing the visible area
  ///
  /// Example:
  /// ```dart
  /// final viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
  /// final visible = viewport.getVisibleArea(Size(800, 600));
  /// // Returns: GraphRect from (0,0) to (800,600) in graph coordinates
  /// ```
  GraphRect getVisibleArea(Size screenSize) {
    final topLeft = toGraph(ScreenPosition.zero);
    final bottomRight = toGraph(
      ScreenPosition.fromXY(screenSize.width, screenSize.height),
    );

    return GraphRect.fromPoints(topLeft, bottomRight);
  }

  /// Checks if a rectangle is visible in the current viewport.
  ///
  /// Determines whether any part of the given [GraphRect] is visible
  /// within the screen area. Used for visibility culling and optimization.
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
  /// final nodeRect = GraphRect.fromLTWH(100, 100, 50, 50);
  /// final isVisible = viewport.isRectVisible(nodeRect, Size(800, 600));
  /// ```
  bool isRectVisible(GraphRect rect, Size screenSize) {
    final visibleArea = getVisibleArea(screenSize);
    return visibleArea.overlaps(rect);
  }

  /// Checks if a point is visible in the current viewport.
  ///
  /// Parameters:
  /// - [point]: Point in graph coordinates to check
  /// - [screenSize]: The size of the viewport in screen pixels
  ///
  /// Returns: `true` if the point is within the visible area
  bool isPointVisible(GraphPosition point, Size screenSize) {
    final visibleArea = getVisibleArea(screenSize);
    return visibleArea.contains(point);
  }

  // ============================================================================
  // Serialization
  // ============================================================================

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
