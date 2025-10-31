import 'package:flutter/material.dart';

final class GraphViewport {
  const GraphViewport({this.x = 0.0, this.y = 0.0, this.zoom = 1.0});

  final double x;
  final double y;
  final double zoom;

  /// Transforms a screen point to graph coordinates
  Offset screenToGraph(Offset screenPoint) {
    return Offset((screenPoint.dx - x) / zoom, (screenPoint.dy - y) / zoom);
  }

  /// Transforms a screen delta to graph delta (without translation)
  Offset screenToGraphDelta(Offset screenDelta) {
    return Offset(screenDelta.dx / zoom, screenDelta.dy / zoom);
  }

  /// Transforms a graph point to screen coordinates
  Offset graphToScreen(Offset graphPoint) {
    return Offset(graphPoint.dx * zoom + x, graphPoint.dy * zoom + y);
  }

  /// Gets the visible area in graph coordinates
  Rect getVisibleArea(Size screenSize) {
    final topLeft = screenToGraph(Offset.zero);
    final bottomRight = screenToGraph(
      Offset(screenSize.width, screenSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Checks if a rectangle is visible in the current viewport
  bool isRectVisible(Rect rect, Size screenSize) {
    final visibleArea = getVisibleArea(screenSize);
    return visibleArea.overlaps(rect);
  }

  factory GraphViewport.fromJson(Map<String, dynamic> json) {
    return GraphViewport(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'zoom': zoom};

  /// Creates a new GraphViewport with updated values
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
