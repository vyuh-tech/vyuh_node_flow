import 'package:flutter/material.dart';

import '../graph/viewport.dart';
import '../shared/spatial/graph_spatial_index.dart';
import '../shared/spatial/spatial_grid.dart';

/// Debug painter that visualizes the spatial index grid.
///
/// This painter draws the spatial hashing grid used for efficient hit testing
/// and spatial queries. Each cell shows:
/// - Grid cell boundary
/// - Cell coordinates (e.g., "(0, 0)", "(-1, 0)")
/// - Object counts by type: `n:X p:X c:X a:X` (nodes, ports, connections, annotations)
/// - Star indicator (★) for the cell containing the mouse cursor
///
/// The spatial index grid is typically much larger than the visual grid
/// (default 500px vs 20px) because it's optimized for query performance,
/// not visual reference.
///
/// ## Usage
///
/// ```dart
/// // In your node flow editor when debugMode is enabled:
/// if (theme.debugMode) {
///   CustomPaint(
///     painter: SpatialIndexDebugPainter(
///       spatialIndex: controller.spatialIndex,
///       viewport: controller.viewport,
///       theme: debugTheme,
///       mousePositionWorld: currentMousePosition,
///     ),
///   );
/// }
/// ```
class SpatialIndexDebugPainter extends CustomPainter {
  SpatialIndexDebugPainter({
    required this.spatialIndex,
    required this.viewport,
    required this.version,
    this.theme = const DebugTheme(),
    this.mousePositionWorld,
  });

  /// The spatial index to visualize.
  final GraphSpatialIndex spatialIndex;

  /// The current viewport transformation.
  final GraphViewport viewport;

  /// The version of the spatial index (used to detect changes).
  final int version;

  /// Theme for the debug visualization.
  final DebugTheme theme;

  /// The current mouse position in world coordinates.
  /// Used to show a star indicator in the cell containing the cursor.
  final Offset? mousePositionWorld;

  @override
  void paint(Canvas canvas, Size size) {
    final gridSize = spatialIndex.gridSize;
    if (gridSize <= 0) return;

    // Calculate visible area in world coordinates
    final zoom = viewport.zoom;
    final viewportLeft = -viewport.x / zoom;
    final viewportTop = -viewport.y / zoom;
    final viewportRight = viewportLeft + (size.width / zoom);
    final viewportBottom = viewportTop + (size.height / zoom);

    // Calculate which grid cells are potentially visible
    // Add padding to ensure we draw cells that are partially visible
    final startCellX = (viewportLeft / gridSize).floor() - 1;
    final endCellX = (viewportRight / gridSize).ceil() + 1;
    final startCellY = (viewportTop / gridSize).floor() - 1;
    final endCellY = (viewportBottom / gridSize).ceil() + 1;

    // Get active cells info for highlighting cells with objects
    final activeCells = spatialIndex.getActiveCellsInfo();
    final activeCellMap = <String, CellDebugInfo>{};
    for (final cell in activeCells) {
      activeCellMap['${cell.cellX}_${cell.cellY}'] = cell;
    }

    // Calculate which cell the mouse is in (if mouse position is available)
    int? mouseCellX;
    int? mouseCellY;
    if (mousePositionWorld != null) {
      mouseCellX = (mousePositionWorld!.dx / gridSize).floor();
      mouseCellY = (mousePositionWorld!.dy / gridSize).floor();
    }

    const borderWidth = 0.5;

    // Paint for grid lines (inactive cells use reddish border)
    final gridPaint = Paint()
      ..color = theme.borderColor
      ..strokeWidth = borderWidth / zoom // Scale with zoom
      ..style = PaintingStyle.stroke;

    // Paint for active cell fill (greenish)
    final activeFillPaint = Paint()
      ..color = theme.activeColor
      ..style = PaintingStyle.fill;

    // Paint for active cell border (greenish, same thickness)
    final activeBorderPaint = Paint()
      ..color = theme.activeBorderColor
      ..strokeWidth = borderWidth / zoom
      ..style = PaintingStyle.stroke;

    // Pass 1: Draw all inactive cell borders (baseline grid)
    for (int cellX = startCellX; cellX <= endCellX; cellX++) {
      for (int cellY = startCellY; cellY <= endCellY; cellY++) {
        final bounds = spatialIndex.cellBounds(cellX, cellY);
        final cellKey = '${cellX}_$cellY';
        final isActive = activeCellMap.containsKey(cellKey);

        // Only draw inactive cell borders in this pass
        if (!isActive) {
          canvas.drawRect(bounds, gridPaint);
        }
      }
    }

    // Pass 2: Draw active cells (fill + border) on top
    // This ensures active cell borders are fully visible
    for (int cellX = startCellX; cellX <= endCellX; cellX++) {
      for (int cellY = startCellY; cellY <= endCellY; cellY++) {
        final bounds = spatialIndex.cellBounds(cellX, cellY);
        final cellKey = '${cellX}_$cellY';
        final cellInfo = activeCellMap[cellKey];
        final isActive = cellInfo != null;

        if (isActive) {
          // Draw fill first, then border on top
          canvas.drawRect(bounds, activeFillPaint);
          canvas.drawRect(bounds, activeBorderPaint);
        }
      }
    }

    // Pass 3: Draw labels on top of everything
    for (int cellX = startCellX; cellX <= endCellX; cellX++) {
      for (int cellY = startCellY; cellY <= endCellY; cellY++) {
        final bounds = spatialIndex.cellBounds(cellX, cellY);
        final cellKey = '${cellX}_$cellY';
        final cellInfo = activeCellMap[cellKey];
        final isMouseCell = cellX == mouseCellX && cellY == mouseCellY;

        _drawCellLabel(
          canvas,
          bounds,
          cellX,
          cellY,
          cellInfo,
          isMouseCell,
          zoom,
        );
      }
    }
  }

  void _drawCellLabel(
    Canvas canvas,
    Rect bounds,
    int cellX,
    int cellY,
    CellDebugInfo? cellInfo,
    bool isMouseCell,
    double zoom,
  ) {
    // Fixed font size, scaled inversely with zoom so it remains readable
    const baseFontSize = 10.0;
    final scaledFontSize = baseFontSize / zoom;

    // Don't draw labels if they'd be too small to read
    if (scaledFontSize < 4) return;

    final paddingH = 4 / zoom;
    final paddingV = 6 / zoom;
    final dotRadius = 3 / zoom;
    final dotSpacing = 5 / zoom;

    // Build label text: "(x, y)" followed by type breakdown if active
    final coordText = '($cellX, $cellY)';

    // For active cells, show type breakdown (n:X p:X c:X a:X)
    String labelText;
    if (cellInfo != null && !cellInfo.isEmpty) {
      final breakdown = cellInfo.typeBreakdown;
      labelText = breakdown.isNotEmpty ? '$coordText  $breakdown' : coordText;
    } else {
      labelText = coordText;
    }

    // Create text painter with uniform styling (no color/weight difference)
    final textSpan = TextSpan(
      text: labelText,
      style: TextStyle(
        color: theme.labelColor,
        fontSize: scaledFontSize,
        fontWeight: FontWeight.normal,
        fontFamily: 'monospace',
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Calculate content height (max of text and dot)
    final contentHeight = textPainter.height;

    // Draw background for better readability (uniform dark background)
    final bgRect = Rect.fromLTWH(
      bounds.left + paddingH / 2,
      bounds.top + paddingV / 2,
      dotRadius * 2 + dotSpacing + textPainter.width + paddingH * 1.5,
      contentHeight + paddingV,
    );

    final bgPaint = Paint()
      ..color = theme.labelBackgroundColor.withValues(alpha: 0.85);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(2 / zoom)),
      bgPaint,
    );

    // Calculate vertical center of the background
    final centerY = bgRect.top + bgRect.height / 2;

    // Calculate dot position (vertically centered)
    final dotCenter = Offset(
      bounds.left + paddingH + dotRadius,
      centerY,
    );

    // Draw the dot - uses theme colors for active/inactive states
    final dotPaint = Paint()
      ..color = isMouseCell ? theme.indicatorColor : theme.indicatorInactiveColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, dotRadius, dotPaint);

    // Calculate label offset (after the dot, vertically centered)
    final labelOffset = Offset(
      dotCenter.dx + dotRadius + dotSpacing,
      centerY - textPainter.height / 2,
    );

    // Draw text
    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(SpatialIndexDebugPainter oldDelegate) {
    return viewport != oldDelegate.viewport ||
        version != oldDelegate.version ||
        theme != oldDelegate.theme ||
        mousePositionWorld != oldDelegate.mousePositionWorld;
  }
}

/// Theme configuration for debug visualization.
///
/// Controls colors and styling for debug overlays including spatial index grid,
/// connection hit testing areas, and other debug visualizations.
///
/// The theme uses semantic names:
/// - **color/borderColor**: Reddish tones for general debug overlays (hit test regions, etc.)
/// - **activeColor/activeBorderColor**: Greenish tones for active/highlighted areas
/// - **indicatorColor/indicatorInactiveColor**: State indicators (mouse position, etc.)
/// - **labelColor/labelBackgroundColor**: Text labels
///
/// Border colors are opaque, fill colors can be transparent.
///
/// Use [DebugTheme.light] or [DebugTheme.dark] for pre-configured themes.
class DebugTheme {
  const DebugTheme({
    this.color = const Color(0x20CC4444),
    this.borderColor = const Color(0xFF994444),
    this.activeColor = const Color(0x2000AA00),
    this.activeBorderColor = const Color(0xFF338833),
    this.labelColor = const Color(0xCCDDDDDD),
    this.labelBackgroundColor = const Color(0xDD1A1A1A),
    this.indicatorColor = const Color(0xFF00DD00),
    this.indicatorInactiveColor = const Color(0xFF666666),
  });

  /// Fill color for debug overlays (hit test regions, etc.). Reddish tone, can be transparent.
  final Color color;

  /// Border color for debug overlays. Reddish tone, opaque.
  final Color borderColor;

  /// Fill color for active/highlighted areas (active cells, etc.). Greenish tone, can be transparent.
  final Color activeColor;

  /// Border color for active/highlighted areas. Greenish tone, opaque.
  final Color activeBorderColor;

  /// Text color for labels.
  final Color labelColor;

  /// Background color for labels.
  final Color labelBackgroundColor;

  /// Color for active indicators (mouse in cell, etc.). Opaque.
  final Color indicatorColor;

  /// Color for inactive indicators. Opaque.
  final Color indicatorInactiveColor;

  /// Light theme variant for debug visualization.
  static const light = DebugTheme(
    color: Color(0x20FF6666),
    borderColor: Color(0xFFCC6666),
    activeColor: Color(0x1844DD44),
    activeBorderColor: Color(0xFF66BB66),
    labelColor: Color(0xFFFFFFFF),
    labelBackgroundColor: Color(0xCC333333),
    indicatorColor: Color(0xFF44DD44),
    indicatorInactiveColor: Color(0xFFAAAAAA),
  );

  /// Dark theme variant for debug visualization.
  static const dark = DebugTheme(
    color: Color(0x20FF6666),
    borderColor: Color(0xFFAA5555),
    activeColor: Color(0x2000FF00),
    activeBorderColor: Color(0xFF44AA44),
    labelColor: Color(0xCCDDDDDD),
    labelBackgroundColor: Color(0xDD1A1A1A),
    indicatorColor: Color(0xFF00FF00),
    indicatorInactiveColor: Color(0xFF666666),
  );

  DebugTheme copyWith({
    Color? color,
    Color? borderColor,
    Color? activeColor,
    Color? activeBorderColor,
    Color? labelColor,
    Color? labelBackgroundColor,
    Color? indicatorColor,
    Color? indicatorInactiveColor,
  }) {
    return DebugTheme(
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      activeColor: activeColor ?? this.activeColor,
      activeBorderColor: activeBorderColor ?? this.activeBorderColor,
      labelColor: labelColor ?? this.labelColor,
      labelBackgroundColor: labelBackgroundColor ?? this.labelBackgroundColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorInactiveColor:
          indicatorInactiveColor ?? this.indicatorInactiveColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebugTheme &&
        other.color == color &&
        other.borderColor == borderColor &&
        other.activeColor == activeColor &&
        other.activeBorderColor == activeBorderColor &&
        other.labelColor == labelColor &&
        other.labelBackgroundColor == labelBackgroundColor &&
        other.indicatorColor == indicatorColor &&
        other.indicatorInactiveColor == indicatorInactiveColor;
  }

  @override
  int get hashCode => Object.hash(
    color,
    borderColor,
    activeColor,
    activeBorderColor,
    labelColor,
    labelBackgroundColor,
    indicatorColor,
    indicatorInactiveColor,
  );
}
