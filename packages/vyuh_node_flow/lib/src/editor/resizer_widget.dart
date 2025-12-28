import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'non_trackpad_pan_gesture_recognizer.dart';
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
///
/// [OnResizeStart] is called when a resize operation begins, providing the
/// handle being dragged and the global position of the pointer.
///
/// [OnResizeUpdate] is called during resize with the current global position
/// of the pointer. The controller uses this with the start position to
/// calculate bounds using absolute positioning.
///
/// [OnResizeEnd] is called when the resize operation completes.
typedef OnResizeStart =
    void Function(ResizeHandle handle, Offset globalPosition);
typedef OnResizeUpdate = void Function(Offset globalPosition);
typedef OnResizeEnd = void Function();

/// Configuration for resize behavior including size constraints.
///
/// This class encapsulates all the behavioral configuration for resizing,
/// separate from visual theming.
class ResizerConfig {
  /// Minimum size constraints for the resizable element.
  final Size minSize;

  /// Maximum size constraints for the resizable element.
  /// If null, the element can grow without limit.
  final Size? maxSize;

  /// Threshold distance (in graph units) for proximity-based resize resume.
  ///
  /// When constraints prevent resizing and the pointer drifts away from the
  /// expected handle position, resizing only resumes when the pointer moves
  /// back within this distance of the handle.
  final double driftThreshold;

  const ResizerConfig({
    this.minSize = const Size(100, 60),
    this.maxSize,
    this.driftThreshold = 50.0,
  });

  /// Creates a copy with the given fields replaced.
  ResizerConfig copyWith({
    Size? minSize,
    Size? maxSize,
    double? driftThreshold,
  }) {
    return ResizerConfig(
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      driftThreshold: driftThreshold ?? this.driftThreshold,
    );
  }
}

/// A widget that wraps a child with resize handles and edge hit areas.
///
/// This widget provides 8 resize handles (corners and edge midpoints) around
/// its child. Additionally, the entire edge is a valid resize target via
/// invisible edge hit areas. All resize operations are delegated to callbacks,
/// allowing the parent (typically a controller) to handle the actual resize logic.
///
/// ## Absolute Position-Based Resizing
///
/// This widget uses global positions for resize callbacks instead of incremental
/// deltas. This enables proper handling of:
/// - Constraint boundaries (min/max size)
/// - Drift tracking between handle position and pointer
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
///   minSize: Size(100, 60),
///   maxSize: Size(600, 400),
///   onResizeStart: (handle, pos) => controller.startResize(itemId, handle, pos),
///   onResizeUpdate: (pos) => controller.updateResize(pos),
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
    this.minSize = const Size(100, 60),
    this.maxSize,
    this.isResizing = false,
  });

  /// The content to wrap with resize handles.
  final Widget child;

  /// Called when a resize operation starts with handle and global position.
  final OnResizeStart onResizeStart;

  /// Called during resize with the current global position.
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

  /// Minimum size constraints for the resizable element.
  ///
  /// The element cannot be resized smaller than this.
  final Size minSize;

  /// Maximum size constraints for the resizable element.
  ///
  /// If null, the element can grow without limit.
  final Size? maxSize;

  /// Whether a resize operation is currently in progress.
  ///
  /// When true, cursor handling is deferred to allow the global cursor override
  /// to take effect. This prevents cursor flickering when the pointer moves
  /// over other resize handles during an active resize operation.
  final bool isResizing;

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

  /// Builds edge gesture detector using custom pan recognizer that rejects
  /// trackpad gestures, allowing them to bubble to InteractiveViewer.
  Widget _buildEdgeGestureDetector(ResizeHandle handle) {
    // When resizing, defer cursor to allow the global cursor override to work.
    // Otherwise, show the appropriate resize cursor on hover.
    final cursor = isResizing ? MouseCursor.defer : handle.cursor;

    return MouseRegion(
      cursor: cursor,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          NonTrackpadPanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                NonTrackpadPanGestureRecognizer
              >(() => NonTrackpadPanGestureRecognizer(), (recognizer) {
                recognizer.dragStartBehavior = DragStartBehavior.down;
                recognizer.onStart = (details) =>
                    onResizeStart(handle, details.globalPosition);
                recognizer.onUpdate = (details) =>
                    onResizeUpdate(details.globalPosition);
                recognizer.onEnd = (_) => onResizeEnd();
                recognizer.onCancel = onResizeEnd;
              }),
        },
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

  /// Builds handle content using custom pan recognizer that rejects
  /// trackpad gestures, allowing them to bubble to InteractiveViewer.
  Widget _buildHandleContent(ResizeHandle handle) {
    // When resizing, defer cursor to allow the global cursor override to work.
    // Otherwise, show the appropriate resize cursor on hover.
    final cursor = isResizing ? MouseCursor.defer : handle.cursor;

    return MouseRegion(
      cursor: cursor,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          NonTrackpadPanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                NonTrackpadPanGestureRecognizer
              >(() => NonTrackpadPanGestureRecognizer(), (recognizer) {
                recognizer.dragStartBehavior = DragStartBehavior.down;
                recognizer.onStart = (details) =>
                    onResizeStart(handle, details.globalPosition);
                recognizer.onUpdate = (details) =>
                    onResizeUpdate(details.globalPosition);
                recognizer.onEnd = (_) => onResizeEnd();
                recognizer.onCancel = onResizeEnd;
              }),
        },
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
