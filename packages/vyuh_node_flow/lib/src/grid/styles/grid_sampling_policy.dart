import 'dart:math' as math;

typedef GridArea = ({double left, double top, double right, double bottom});

typedef GridSampling = ({
  double startX,
  double startY,
  int columns,
  int rows,
  double spacing,
});

/// Safety policy for grid iteration counts.
///
/// This keeps grid rendering bounded at extreme zoom-out and very large pan
/// offsets by coarsening the spacing before styles generate paths/points.
final class GridSamplingPolicy {
  const GridSamplingPolicy._();

  static const int defaultMaxColumns = 320;
  static const int defaultMaxRows = 320;

  static GridSampling? resolve({
    required GridArea area,
    required double baseSpacing,
    int maxColumns = defaultMaxColumns,
    int maxRows = defaultMaxRows,
  }) {
    if (maxColumns <= 0 || maxRows <= 0) return null;
    if (!baseSpacing.isFinite || baseSpacing <= 0) return null;
    if (!_isFiniteArea(area)) return null;

    final width = area.right - area.left;
    final height = area.bottom - area.top;
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return null;
    }

    final rawColumns = _count(width, baseSpacing);
    final rawRows = _count(height, baseSpacing);
    if (rawColumns <= 0 || rawRows <= 0) return null;

    final columnFactor = (rawColumns / maxColumns).ceil();
    final rowFactor = (rawRows / maxRows).ceil();
    final factor = math.max(1, math.max(columnFactor, rowFactor));

    final spacing = baseSpacing * factor;
    if (!spacing.isFinite || spacing <= 0) return null;

    final columns = _count(width, spacing);
    final rows = _count(height, spacing);
    if (columns <= 0 || rows <= 0) return null;

    final startX = (area.left / spacing).floor() * spacing;
    final startY = (area.top / spacing).floor() * spacing;
    if (!startX.isFinite || !startY.isFinite) return null;

    return (
      startX: startX,
      startY: startY,
      columns: columns,
      rows: rows,
      spacing: spacing,
    );
  }

  static int _count(double extent, double spacing) {
    if (!extent.isFinite || !spacing.isFinite || spacing <= 0) {
      return 0;
    }
    return (extent / spacing).floor() + 1;
  }

  static bool _isFiniteArea(GridArea area) {
    return area.left.isFinite &&
        area.top.isFinite &&
        area.right.isFinite &&
        area.bottom.isFinite;
  }
}
