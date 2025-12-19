import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'unbounded_widgets.dart';

/// Position of resize handles on a resizable element.
enum ResizeHandle {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Extension to add cursor and widget building capabilities to resize handles.
extension ResizeHandleExtension on ResizeHandle {
  /// Returns the appropriate mouse cursor for this resize handle position.
  MouseCursor get cursor {
    switch (this) {
      case ResizeHandle.topLeft:
      case ResizeHandle.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case ResizeHandle.topRight:
      case ResizeHandle.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case ResizeHandle.topCenter:
      case ResizeHandle.bottomCenter:
        return SystemMouseCursors.resizeUpDown;
      case ResizeHandle.centerLeft:
      case ResizeHandle.centerRight:
        return SystemMouseCursors.resizeLeftRight;
    }
  }

  /// Whether this is a corner handle (vs edge-centered handle).
  bool get isCorner => switch (this) {
    ResizeHandle.topLeft ||
    ResizeHandle.topRight ||
    ResizeHandle.bottomLeft ||
    ResizeHandle.bottomRight => true,
    _ => false,
  };

  /// Whether this is an edge-centered handle (vs corner handle).
  bool get isEdge => !isCorner;

  /// The edge handles (excludes corners).
  static List<ResizeHandle> get edges => [
    ResizeHandle.topCenter,
    ResizeHandle.bottomCenter,
    ResizeHandle.centerLeft,
    ResizeHandle.centerRight,
  ];

  /// Builds an edge hit area widget for this handle position.
  ///
  /// Only valid for edge handles (topCenter, bottomCenter, centerLeft, centerRight).
  /// Returns null for corner handles.
  ///
  /// [thickness] is the width/height of the invisible hit area strip.
  /// [child] is the content (typically a MouseRegion + GestureDetector).
  Widget? buildEdgeHitArea({required double thickness, required Widget child}) {
    final halfThickness = thickness / 2;
    return switch (this) {
      ResizeHandle.topCenter => Positioned(
        left: 0,
        right: 0,
        top: -halfThickness,
        height: thickness,
        child: child,
      ),
      ResizeHandle.bottomCenter => Positioned(
        left: 0,
        right: 0,
        bottom: -halfThickness,
        height: thickness,
        child: child,
      ),
      ResizeHandle.centerLeft => Positioned(
        top: 0,
        bottom: 0,
        left: -halfThickness,
        width: thickness,
        child: child,
      ),
      ResizeHandle.centerRight => Positioned(
        top: 0,
        bottom: 0,
        right: -halfThickness,
        width: thickness,
        child: child,
      ),
      // Corner handles don't have edge hit areas
      _ => null,
    };
  }

  /// Builds a positioned widget for this handle.
  ///
  /// [offset] is the distance from the boundary to center the handle on.
  /// [hitAreaSize] is the total size of the hit area (handle + snap padding).
  /// [child] is the handle content widget.
  Widget buildPositioned({
    required double offset,
    required double hitAreaSize,
    required Widget child,
  }) {
    // Corner handles have fixed size at corner positions
    // Edge handles stretch along the edge and center their content
    return switch (this) {
      ResizeHandle.topLeft => Positioned(
        left: -offset,
        top: -offset,
        width: hitAreaSize,
        height: hitAreaSize,
        child: child,
      ),
      ResizeHandle.topRight => Positioned(
        right: -offset,
        top: -offset,
        width: hitAreaSize,
        height: hitAreaSize,
        child: child,
      ),
      ResizeHandle.bottomLeft => Positioned(
        left: -offset,
        bottom: -offset,
        width: hitAreaSize,
        height: hitAreaSize,
        child: child,
      ),
      ResizeHandle.bottomRight => Positioned(
        right: -offset,
        bottom: -offset,
        width: hitAreaSize,
        height: hitAreaSize,
        child: child,
      ),
      ResizeHandle.topCenter => Positioned(
        left: 0,
        right: 0,
        top: -offset,
        child: Center(
          child: SizedBox(
            width: hitAreaSize,
            height: hitAreaSize,
            child: child,
          ),
        ),
      ),
      ResizeHandle.bottomCenter => Positioned(
        left: 0,
        right: 0,
        bottom: -offset,
        child: Center(
          child: SizedBox(
            width: hitAreaSize,
            height: hitAreaSize,
            child: child,
          ),
        ),
      ),
      ResizeHandle.centerLeft => Positioned(
        top: 0,
        bottom: 0,
        left: -offset,
        child: Center(
          child: SizedBox(
            width: hitAreaSize,
            height: hitAreaSize,
            child: child,
          ),
        ),
      ),
      ResizeHandle.centerRight => Positioned(
        top: 0,
        bottom: 0,
        right: -offset,
        child: Center(
          child: SizedBox(
            width: hitAreaSize,
            height: hitAreaSize,
            child: child,
          ),
        ),
      ),
    };
  }
}

/// Callbacks for resize operations.
typedef OnResizeStart = void Function(ResizeHandle handle);
typedef OnResizeUpdate = void Function(Offset delta);
typedef OnResizeEnd = void Function();

/// A widget that wraps a child with resize handles and edge hit areas.
///
/// This widget provides 8 resize handles (corners and edge midpoints) around
/// its child. Additionally, the entire edge is a valid resize target via
/// invisible edge hit areas. All resize operations are delegated to callbacks,
/// allowing the parent (typically a controller) to handle the actual resize logic.
///
/// ## Usage
///
/// ```dart
/// ResizerWidget(
///   handleSize: 10.0,
///   color: Colors.white,
///   borderColor: Colors.blue,
///   borderWidth: 1.0,
///   snapDistance: 4.0,
///   onResizeStart: (handle) => controller.startResize(itemId, handle),
///   onResizeUpdate: (delta) => controller.updateResize(delta),
///   onResizeEnd: () => controller.endResize(),
///   child: MyContent(),
/// )
/// ```
///
/// ## Handle Positions and Edge Hit Areas
///
/// ```
/// TL ─────── TC ─────── TR
/// │    [top edge]       │
/// │                     │
/// CL      child        CR
/// [left]         [right]
/// │                     │
/// │   [bottom edge]     │
/// BL ─────── BC ─────── BR
/// ```
///
/// Each edge has an invisible hit area of [snapDistance] thickness for easy
/// targeting. Corner and midpoint handles have additional [snapDistance]
/// padding around them.
class ResizerWidget extends StatelessWidget {
  const ResizerWidget({
    super.key,
    required this.child,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    this.handleSize = 8.0,
    this.color = Colors.white,
    this.borderColor = Colors.blue,
    this.borderWidth = 1.0,
    this.snapDistance = 4.0,
  });

  /// The content to wrap with resize handles.
  final Widget child;

  /// Called when a resize operation starts.
  final OnResizeStart onResizeStart;

  /// Called during resize with the delta movement.
  final OnResizeUpdate onResizeUpdate;

  /// Called when a resize operation ends.
  final OnResizeEnd onResizeEnd;

  /// Size of each visible resize handle.
  final double handleSize;

  /// Fill color of the resize handles.
  final Color color;

  /// Border color of the resize handles.
  final Color borderColor;

  /// Border width of the resize handles.
  final double borderWidth;

  /// Additional hit area padding around handles and edge thickness.
  ///
  /// This creates a larger invisible hit area around visible handles
  /// and defines the thickness of edge hit areas, making it easier
  /// to grab resize targets.
  final double snapDistance;

  /// Total hit area size including snap distance padding
  double get _hitAreaSize => handleSize + (snapDistance * 2);

  /// Offset to center the visible handle on the edge/corner.
  /// Since the visible handle is centered within _hitAreaSize, we offset
  /// by half the hit area size to make the handle straddle the boundary.
  double get _handleOffset => _hitAreaSize / 2;

  @override
  Widget build(BuildContext context) {
    return UnboundedStack(
      clipBehavior: Clip.none,
      children: [child, ..._buildEdgeHitAreas(), ..._buildHandles()],
    );
  }

  /// Builds invisible hit areas along each edge for resizing.
  List<Widget> _buildEdgeHitAreas() {
    return ResizeHandleExtension.edges
        .map(
          (handle) => handle.buildEdgeHitArea(
            thickness: snapDistance,
            child: _buildEdgeGestureDetector(handle),
          ),
        )
        .whereType<Widget>()
        .toList();
  }

  Widget _buildEdgeGestureDetector(ResizeHandle handle) {
    return MouseRegion(
      cursor: handle.cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (_) => onResizeStart(handle),
        onPanUpdate: (details) => onResizeUpdate(details.delta),
        onPanEnd: (_) => onResizeEnd(),
        onPanCancel: onResizeEnd,
        child: const SizedBox.expand(),
      ),
    );
  }

  List<Widget> _buildHandles() {
    return ResizeHandle.values.map((handle) {
      return handle.buildPositioned(
        offset: _handleOffset,
        hitAreaSize: _hitAreaSize,
        child: _buildHandleContent(handle),
      );
    }).toList();
  }

  Widget _buildHandleContent(ResizeHandle handle) {
    return MouseRegion(
      cursor: handle.cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (_) => onResizeStart(handle),
        onPanUpdate: (details) => onResizeUpdate(details.delta),
        onPanEnd: (_) => onResizeEnd(),
        onPanCancel: onResizeEnd,
        child: Center(
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: borderColor, width: borderWidth),
            ),
          ),
        ),
      ),
    );
  }
}
