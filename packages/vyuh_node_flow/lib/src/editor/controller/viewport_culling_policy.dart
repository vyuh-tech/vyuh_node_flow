import 'package:flutter/material.dart';

/// Viewport-aware culling policy for visible node/connection queries.
///
/// This policy keeps the same total prefetch budget as the legacy implementation
/// but, during active viewport panning, biases the query window in the pan
/// direction. This reduces expensive cache boundary re-queries that can cause
/// hitching near culling edges.
class ViewportCullingPolicy {
  const ViewportCullingPolicy._();

  static const double _prefetchPadding = 1000.0;
  static const double _safetyMargin = 200.0;
  static const double _directionalBias = 600.0;
  static const double _minAxisPadding = 250.0;

  /// Returns whether the cached query rect still safely contains the viewport.
  static bool isCacheValid({
    required Rect? cachedQueryRect,
    required Rect viewportRect,
    required bool indexChanged,
  }) {
    if (indexChanged || cachedQueryRect == null) {
      return false;
    }

    return cachedQueryRect.contains(
          viewportRect.topLeft - const Offset(_safetyMargin, _safetyMargin),
        ) &&
        cachedQueryRect.contains(
          viewportRect.bottomRight + const Offset(_safetyMargin, _safetyMargin),
        );
  }

  /// Builds a query rect for visible-element culling.
  ///
  /// While idle, this matches the original symmetric `inflate(1000)` behavior.
  /// While panning, it biases prefetch toward movement direction.
  static Rect buildQueryRect({
    required Rect viewportRect,
    required Rect? previousViewportRect,
    required bool isViewportInteracting,
  }) {
    if (!isViewportInteracting || previousViewportRect == null) {
      return viewportRect.inflate(_prefetchPadding);
    }

    final dx = viewportRect.center.dx - previousViewportRect.center.dx;
    final dy = viewportRect.center.dy - previousViewportRect.center.dy;

    final xPads = _axisPads(dx);
    final yPads = _axisPads(dy);

    return Rect.fromLTRB(
      viewportRect.left - xPads.before,
      viewportRect.top - yPads.before,
      viewportRect.right + xPads.after,
      viewportRect.bottom + yPads.after,
    );
  }

  static ({double before, double after}) _axisPads(double delta) {
    if (delta.abs() < 0.01) {
      return (before: _prefetchPadding, after: _prefetchPadding);
    }

    final direction = delta.sign;
    final before = (_prefetchPadding - _directionalBias * direction)
        .clamp(_minAxisPadding, double.infinity)
        .toDouble();
    final after = (_prefetchPadding + _directionalBias * direction)
        .clamp(_minAxisPadding, double.infinity)
        .toDouble();

    return (before: before, after: after);
  }
}
