import 'package:flutter/material.dart';

import 'debug_extension.dart';
import '../../graph/viewport.dart';
import '../../shared/spatial/graph_spatial_index.dart';
import '../../shared/spatial/spatial_grid.dart';

/// Debug painter that visualizes the spatial index grid.
///
/// This painter draws the spatial hashing grid used for efficient hit testing
/// and spatial queries. Each cell shows:
/// - Grid cell boundary
/// - Cell coordinates in top-left as `x, y` with green background when mouse is in cell
/// - Object counts below as vertical list: `N: X`, `P: X`, `C: X` (nodes, ports, connections)
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
      ..strokeWidth =
          borderWidth /
          zoom // Scale with zoom
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

    // Pass 3: Draw labels on top of grid cells
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

    // Pass 4-6: Draw element bounds in order: connections → nodes → ports
    _drawConnectionSegments(canvas, zoom);
    _drawNodeBounds(canvas, zoom);
    _drawPortSnapZones(canvas, zoom);
  }

  void _drawConnectionSegments(Canvas canvas, double zoom) {
    final segmentColor = theme.getSegmentColor(0); // connections = index 0
    final fillPaint = Paint()
      ..color = segmentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = segmentColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.5 / zoom
      ..style = PaintingStyle.stroke;

    for (final segment in spatialIndex.connectionSegmentItems) {
      canvas.drawRect(segment.bounds, fillPaint);
      canvas.drawRect(segment.bounds, borderPaint);
    }
  }

  void _drawNodeBounds(Canvas canvas, double zoom) {
    final segmentColor = theme.getSegmentColor(1); // nodes = index 1
    final fillPaint = Paint()
      ..color = segmentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = segmentColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0 / zoom
      ..style = PaintingStyle.stroke;

    for (final nodeItem in spatialIndex.nodeItems) {
      canvas.drawRect(nodeItem.bounds, fillPaint);
      canvas.drawRect(nodeItem.bounds, borderPaint);
    }
  }

  void _drawPortSnapZones(Canvas canvas, double zoom) {
    final segmentColor = theme.getSegmentColor(2); // ports = index 2
    final fillPaint = Paint()
      ..color = segmentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = segmentColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0 / zoom
      ..style = PaintingStyle.stroke;

    for (final portItem in spatialIndex.portItems) {
      canvas.drawRect(portItem.bounds, fillPaint);
      canvas.drawRect(portItem.bounds, borderPaint);
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
    final paddingV = 3 / zoom;
    final lineSpacing = 2 / zoom;

    // Coordinate label: x, y
    final coordText = '$cellX, $cellY';

    final textStyle = TextStyle(
      color: theme.labelColor,
      fontSize: scaledFontSize,
      fontWeight: FontWeight.normal,
      fontFamily: 'monospace',
    );

    // Create text painter for coordinates
    final coordPainter = TextPainter(
      text: TextSpan(text: coordText, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    coordPainter.layout();

    // Draw coordinate label background (green if mouse in cell)
    final coordBgRect = Rect.fromLTWH(
      bounds.left + paddingH / 2,
      bounds.top + paddingV / 2,
      coordPainter.width + paddingH * 2,
      coordPainter.height + paddingV * 2,
    );

    final coordBgPaint = Paint()
      ..color = isMouseCell
          ? theme.indicatorColor.withValues(alpha: 0.85)
          : theme.labelBackgroundColor.withValues(alpha: 0.85);

    canvas.drawRRect(
      RRect.fromRectAndRadius(coordBgRect, Radius.circular(2 / zoom)),
      coordBgPaint,
    );

    // Draw coordinate text (use dark color when background is green)
    final coordTextStyle = isMouseCell
        ? textStyle.copyWith(color: const Color(0xFF000000))
        : textStyle;
    final coordPainterFinal = TextPainter(
      text: TextSpan(text: coordText, style: coordTextStyle),
      textDirection: TextDirection.ltr,
    );
    coordPainterFinal.layout();

    coordPainterFinal.paint(
      canvas,
      Offset(coordBgRect.left + paddingH, coordBgRect.top + paddingV),
    );

    // Draw stats label if cell has objects (N:, P:, C: as vertical list)
    if (cellInfo != null && !cellInfo.isEmpty) {
      final stats = <String>[];
      if (cellInfo.nodeCount > 0) stats.add('N: ${cellInfo.nodeCount}');
      if (cellInfo.portCount > 0) stats.add('P: ${cellInfo.portCount}');
      if (cellInfo.connectionCount > 0) {
        stats.add('C: ${cellInfo.connectionCount}');
      }

      if (stats.isNotEmpty) {
        // Create painters for each stat line to measure widths
        final statPainters = stats.map((stat) {
          final painter = TextPainter(
            text: TextSpan(text: stat, style: textStyle),
            textDirection: TextDirection.ltr,
          );
          painter.layout();
          return painter;
        }).toList();

        // Find max width for right alignment
        final maxWidth = statPainters
            .map((p) => p.width)
            .reduce((a, b) => a > b ? a : b);

        // Calculate total height
        final totalHeight =
            statPainters.fold<double>(0, (sum, p) => sum + p.height) +
            (stats.length - 1) * lineSpacing;

        // Stats background positioned below coordinates
        final statsBgRect = Rect.fromLTWH(
          bounds.left + paddingH / 2,
          coordBgRect.bottom + lineSpacing,
          maxWidth + paddingH * 2,
          totalHeight + paddingV * 2,
        );

        final statsBgPaint = Paint()
          ..color = theme.labelBackgroundColor.withValues(alpha: 0.85);

        canvas.drawRRect(
          RRect.fromRectAndRadius(statsBgRect, Radius.circular(2 / zoom)),
          statsBgPaint,
        );

        // Draw each stat line, left-aligned
        var currentY = statsBgRect.top + paddingV;
        for (final painter in statPainters) {
          painter.paint(canvas, Offset(statsBgRect.left + paddingH, currentY));
          currentY += painter.height + lineSpacing;
        }
      }
    }
  }

  @override
  bool shouldRepaint(SpatialIndexDebugPainter oldDelegate) {
    return viewport != oldDelegate.viewport ||
        version != oldDelegate.version ||
        theme != oldDelegate.theme ||
        mousePositionWorld != oldDelegate.mousePositionWorld;
  }
}
