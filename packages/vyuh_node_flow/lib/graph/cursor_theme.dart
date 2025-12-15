import 'package:flutter/services.dart';

import '../nodes/interaction_state.dart';

/// Theme configuration for mouse cursors in the node flow editor.
///
/// Defines cursor styles for different interaction contexts:
/// - Default canvas cursor (idle state)
/// - Cursor when drawing a selection rectangle
/// - Cursor when dragging nodes or panning
/// - Cursor when zooming in/out
/// - Cursor when hovering over nodes
/// - Cursor when hovering over ports
///
/// Example:
/// ```dart
/// final customCursorTheme = CursorTheme.light.copyWith(
///   canvasCursor: SystemMouseCursors.basic,
///   dragCursor: SystemMouseCursors.grabbing,
/// );
/// ```
class CursorTheme {
  const CursorTheme({
    required this.canvasCursor,
    required this.selectionCursor,
    required this.dragCursor,
    required this.zoomInCursor,
    required this.zoomOutCursor,
    required this.nodeCursor,
    required this.portCursor,
  });

  /// Default mouse cursor when hovering over empty canvas areas.
  ///
  /// Typically a grab hand to indicate the canvas can be panned.
  final SystemMouseCursor canvasCursor;

  /// Mouse cursor when drawing a selection rectangle.
  ///
  /// Typically a precise cursor (crosshair) for accurate selection.
  final SystemMouseCursor selectionCursor;

  /// Mouse cursor when dragging nodes or panning the canvas.
  ///
  /// Typically a grabbing hand cursor to indicate active movement.
  final SystemMouseCursor dragCursor;

  /// Mouse cursor when zooming in on the canvas.
  final SystemMouseCursor zoomInCursor;

  /// Mouse cursor when zooming out on the canvas.
  final SystemMouseCursor zoomOutCursor;

  /// Mouse cursor when hovering over nodes.
  ///
  /// Indicates that the node is interactive and can be selected or moved.
  final SystemMouseCursor nodeCursor;

  /// Mouse cursor when hovering over ports or creating connections.
  ///
  /// Typically a precise cursor (crosshair) for accurate connection targeting.
  final SystemMouseCursor portCursor;

  /// Creates a copy of this theme with the given fields replaced.
  CursorTheme copyWith({
    SystemMouseCursor? canvasCursor,
    SystemMouseCursor? selectionCursor,
    SystemMouseCursor? dragCursor,
    SystemMouseCursor? zoomInCursor,
    SystemMouseCursor? zoomOutCursor,
    SystemMouseCursor? nodeCursor,
    SystemMouseCursor? portCursor,
  }) {
    return CursorTheme(
      canvasCursor: canvasCursor ?? this.canvasCursor,
      selectionCursor: selectionCursor ?? this.selectionCursor,
      dragCursor: dragCursor ?? this.dragCursor,
      zoomInCursor: zoomInCursor ?? this.zoomInCursor,
      zoomOutCursor: zoomOutCursor ?? this.zoomOutCursor,
      nodeCursor: nodeCursor ?? this.nodeCursor,
      portCursor: portCursor ?? this.portCursor,
    );
  }

  /// Light theme cursor configuration.
  ///
  /// Uses standard cursor styles suitable for most applications:
  /// - Canvas: grab hand (indicates pannable)
  /// - Selection: precise crosshair (for accurate selection)
  /// - Drag: grabbing hand (active movement)
  /// - Zoom in/out: system zoom cursors
  /// - Node: click pointer (interactive element)
  /// - Port: precise crosshair (connection targeting)
  static const light = CursorTheme(
    canvasCursor: SystemMouseCursors.grab,
    selectionCursor: SystemMouseCursors.precise,
    dragCursor: SystemMouseCursors.grabbing,
    zoomInCursor: SystemMouseCursors.zoomIn,
    zoomOutCursor: SystemMouseCursors.zoomOut,
    nodeCursor: SystemMouseCursors.click,
    portCursor: SystemMouseCursors.precise,
  );

  /// Dark theme cursor configuration.
  ///
  /// Uses the same cursor styles as light theme, as cursor visibility
  /// is typically handled by the operating system.
  static const dark = CursorTheme(
    canvasCursor: SystemMouseCursors.grab,
    selectionCursor: SystemMouseCursors.precise,
    dragCursor: SystemMouseCursors.grabbing,
    zoomInCursor: SystemMouseCursors.zoomIn,
    zoomOutCursor: SystemMouseCursors.zoomOut,
    nodeCursor: SystemMouseCursors.click,
    portCursor: SystemMouseCursors.precise,
  );
}

/// The type of UI element for cursor resolution.
///
/// Used by [CursorThemeExtension.cursorFor] to determine which cursor
/// to show based on the element type and interaction state.
enum ElementType {
  /// Canvas background area
  canvas,

  /// Node element
  node,

  /// Port element (connection point)
  port,

  /// Annotation element
  annotation,
}

/// Extension on [CursorTheme] for deriving cursors from interaction state.
///
/// This centralizes all cursor resolution logic, making it easy to determine
/// the correct cursor based on the current element type and interaction state.
///
/// ## Usage
///
/// ```dart
/// final cursor = cursorTheme.cursorFor(
///   ElementType.node,
///   interaction: controller.interaction,
/// );
/// ```
extension CursorThemeExtension on CursorTheme {
  /// Returns the appropriate cursor for the given element type and interaction state.
  ///
  /// The cursor is derived purely from state - there are no side effects.
  /// Priority is given to global interaction states:
  /// 1. Connection dragging → [portCursor]
  /// 2. Zooming → [zoomInCursor] or [zoomOutCursor] based on direction
  /// 3. Viewport dragging (panning) → [dragCursor]
  /// 4. Drawing selection → [selectionCursor]
  /// 5. Element-specific cursor based on [elementType]
  ///
  /// For annotations, an additional [isInteractive] parameter determines
  /// whether to show [nodeCursor] or [canvasCursor].
  SystemMouseCursor cursorFor(
    ElementType elementType,
    InteractionState interaction, {
    bool isInteractive = true,
  }) {
    final isConnecting = interaction.isCreatingConnection;
    final isZooming = interaction.isViewportZooming;
    final isZoomingIn = interaction.isViewportZoomingIn;
    final isViewportDragging = interaction.isViewportDragging;
    final isDrawingSelection = interaction.isDrawingSelection;

    return switch ((isConnecting, isZooming, isViewportDragging, isDrawingSelection)) {
      (true, _, _, _) => portCursor,
      (_, true, _, _) => isZoomingIn ? zoomInCursor : zoomOutCursor,
      (_, _, true, _) => dragCursor,
      (_, _, _, true) => selectionCursor,
      _ => switch (elementType) {
        ElementType.canvas => canvasCursor,
        ElementType.node => nodeCursor,
        ElementType.port => portCursor,
        ElementType.annotation => isInteractive ? nodeCursor : canvasCursor,
      },
    };
  }
}
