import 'package:flutter/services.dart';

/// Theme configuration for mouse cursors in the node flow editor.
///
/// Defines cursor styles for different interaction contexts:
/// - Default selection/pan cursor
/// - Cursor when dragging nodes
/// - Cursor when hovering over nodes
/// - Cursor when hovering over ports
///
/// Example:
/// ```dart
/// final customCursorTheme = CursorTheme.light.copyWith(
///   selectionCursor: SystemMouseCursors.move,
///   dragCursor: SystemMouseCursors.grabbing,
/// );
/// ```
class CursorTheme {
  const CursorTheme({
    required this.selectionCursor,
    required this.dragCursor,
    required this.nodeCursor,
    required this.portCursor,
  });

  /// Default mouse cursor for selection and panning.
  ///
  /// Used when hovering over empty canvas areas or during normal interaction.
  final SystemMouseCursor selectionCursor;

  /// Mouse cursor when dragging nodes or panning the canvas.
  ///
  /// Typically a grabbing hand cursor to indicate active movement.
  final SystemMouseCursor dragCursor;

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
    SystemMouseCursor? selectionCursor,
    SystemMouseCursor? dragCursor,
    SystemMouseCursor? nodeCursor,
    SystemMouseCursor? portCursor,
  }) {
    return CursorTheme(
      selectionCursor: selectionCursor ?? this.selectionCursor,
      dragCursor: dragCursor ?? this.dragCursor,
      nodeCursor: nodeCursor ?? this.nodeCursor,
      portCursor: portCursor ?? this.portCursor,
    );
  }

  /// Light theme cursor configuration.
  ///
  /// Uses standard cursor styles suitable for most applications:
  /// - Selection: grab hand
  /// - Drag: grabbing hand
  /// - Node: click pointer
  /// - Port: precise crosshair
  static const light = CursorTheme(
    selectionCursor: SystemMouseCursors.grab,
    dragCursor: SystemMouseCursors.grabbing,
    nodeCursor: SystemMouseCursors.click,
    portCursor: SystemMouseCursors.precise,
  );

  /// Dark theme cursor configuration.
  ///
  /// Uses the same cursor styles as light theme, as cursor visibility
  /// is typically handled by the operating system.
  static const dark = CursorTheme(
    selectionCursor: SystemMouseCursors.grab,
    dragCursor: SystemMouseCursors.grabbing,
    nodeCursor: SystemMouseCursors.click,
    portCursor: SystemMouseCursors.precise,
  );
}
