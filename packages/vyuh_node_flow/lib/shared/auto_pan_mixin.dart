import 'dart:async';

import 'package:flutter/material.dart';

import 'element_scope.dart';

/// Mixin that provides autopan functionality for [ElementScope].
///
/// When the pointer is near viewport edges during a drag, this mixin
/// automatically pans the viewport to reveal more canvas.
///
/// ## Behavior Zones
///
/// ```
/// ┌─────────────────────────────────────────────────────────┐
/// │                    OUTSIDE BOUNDS                       │
/// │   (autopan at max speed, element frozen at edge)        │
/// │  ┌───────────────────────────────────────────────────┐  │
/// │  │░░░░░░░░░░░░░░ EDGE ZONE ░░░░░░░░░░░░░░░░░░░░░░░░░│  │
/// │  │░░┌─────────────────────────────────────────────┐░░│  │
/// │  │░░│                                             │░░│  │
/// │  │░░│          INNER BOUNDS                       │░░│  │
/// │  │░░│     (normal drag, 1:1 movement)             │░░│  │
/// │  │░░│                                             │░░│  │
/// │  │░░└─────────────────────────────────────────────┘░░│  │
/// │  │░░░░░░░░░░░░░░ (autopan active) ░░░░░░░░░░░░░░░░░░│  │
/// │  └───────────────────────────────────────────────────┘  │
/// └─────────────────────────────────────────────────────────┘
/// ```
///
/// ## Element Tracking Behavior
///
/// All elements use anchored tracking:
/// - Inside bounds: Element follows pointer 1:1
/// - Outside bounds: Element freezes at edge, offset accumulates
/// - Re-entry: Element snaps to match current pointer position
mixin AutoPanMixin on State<ElementScope> {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Timer for periodic autopan during drag.
  Timer? _autoPanTimer;

  /// Last known pointer position in screen coordinates.
  Offset? _lastPointerPosition;

  /// Accumulated offset when pointer is outside bounds.
  /// Applied as snap compensation on re-entry.
  Offset _accumulatedOffset = Offset.zero;

  /// Tracks whether pointer was outside bounds in the previous update.
  /// Used to detect re-entry for snap compensation.
  bool _wasOutsideBounds = false;

  // ---------------------------------------------------------------------------
  // Abstract Interface
  // ---------------------------------------------------------------------------

  /// Whether a drag operation is currently in progress.
  bool get isDragging;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Updates pointer position and manages autopan timer.
  void updatePointerPosition(Offset globalPosition) {
    _lastPointerPosition = globalPosition;

    // Start autopan timer if configured and not already running
    if (widget.autoPan != null && _autoPanTimer == null) {
      _startAutoPan();
    }
  }

  /// Processes a drag delta with anchored tracking behavior.
  ///
  /// - Inside bounds: Pass delta through (1:1 movement)
  /// - Outside bounds: Freeze element, accumulate offset
  /// - Re-entry: Apply accumulated offset as snap
  Offset processDragDelta(Offset delta) {
    final isOutside = _isPointerOutsideBounds();

    if (isOutside) {
      // Outside bounds - freeze element, accumulate offset for snap
      _accumulatedOffset += delta;
      _wasOutsideBounds = true;
      return Offset.zero;
    }

    // Inside bounds - check for re-entry snap
    if (_wasOutsideBounds && _accumulatedOffset != Offset.zero) {
      // Re-entered bounds - apply accumulated offset as snap
      final snap = _accumulatedOffset;
      _accumulatedOffset = Offset.zero;
      _wasOutsideBounds = false;
      return delta + snap;
    }

    _wasOutsideBounds = false;
    return delta;
  }

  /// Resets all autopan state.
  void resetAutoPanState() {
    _lastPointerPosition = null;
    _accumulatedOffset = Offset.zero;
    _wasOutsideBounds = false;
  }

  /// Stops the autopan timer.
  void stopAutoPan() {
    _autoPanTimer?.cancel();
    _autoPanTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Private Implementation
  // ---------------------------------------------------------------------------

  /// Checks if pointer is completely outside editor bounds.
  bool _isPointerOutsideBounds() {
    final getViewportBounds = widget.getViewportBounds;
    final pointer = _lastPointerPosition;

    if (getViewportBounds == null || pointer == null) {
      return false;
    }

    final bounds = getViewportBounds();
    return !bounds.contains(pointer);
  }

  /// Checks if pointer is in edge zone (autopan zone).
  bool _isInEdgeZone() {
    final config = widget.autoPan;
    final getViewportBounds = widget.getViewportBounds;
    final pointer = _lastPointerPosition;

    if (config == null || getViewportBounds == null || pointer == null) {
      return false;
    }

    final bounds = getViewportBounds();

    // First check if inside bounds at all
    if (!bounds.contains(pointer)) {
      return false;
    }

    final padding = config.edgePadding;

    final inLeftZone =
        padding.left > 0 && pointer.dx < bounds.left + padding.left;
    final inRightZone =
        padding.right > 0 && pointer.dx > bounds.right - padding.right;
    final inTopZone = padding.top > 0 && pointer.dy < bounds.top + padding.top;
    final inBottomZone =
        padding.bottom > 0 && pointer.dy > bounds.bottom - padding.bottom;

    return inLeftZone || inRightZone || inTopZone || inBottomZone;
  }

  /// Starts the autopan timer.
  void _startAutoPan() {
    final config = widget.autoPan;
    if (config == null || !config.isEnabled || _autoPanTimer != null) {
      return;
    }

    _autoPanTimer = Timer.periodic(
      config.panInterval,
      (_) => _performAutoPan(),
    );
  }

  /// Performs autopan when pointer is in edge zone or outside bounds.
  void _performAutoPan() {
    final config = widget.autoPan;
    final onAutoPan = widget.onAutoPan;
    final getViewportBounds = widget.getViewportBounds;
    final pointer = _lastPointerPosition;

    if (config == null ||
        onAutoPan == null ||
        getViewportBounds == null ||
        pointer == null ||
        !isDragging) {
      return;
    }

    final bounds = getViewportBounds();
    final padding = config.edgePadding;
    final isOutside = !bounds.contains(pointer);

    // If pointer is inside inner bounds (not in edge zone), no autopan needed
    if (!isOutside && !_isInEdgeZone()) {
      return;
    }

    double dx = 0.0;
    double dy = 0.0;

    // Calculate pan amounts based on pointer position relative to bounds
    // Works for both edge zone (inside but near edge) and outside bounds

    // Left edge / outside left
    if (pointer.dx < bounds.left + padding.left) {
      if (isOutside && pointer.dx < bounds.left) {
        // Outside left - pan at max speed
        dx = -config.panAmount;
      } else if (padding.left > 0) {
        // In left edge zone - scale by proximity
        final proximity = bounds.left + padding.left - pointer.dx;
        dx = -config.calculatePanAmount(
          proximity,
          edgePaddingValue: padding.left,
        );
      }
    }
    // Right edge / outside right
    else if (pointer.dx > bounds.right - padding.right) {
      if (isOutside && pointer.dx > bounds.right) {
        // Outside right - pan at max speed
        dx = config.panAmount;
      } else if (padding.right > 0) {
        // In right edge zone - scale by proximity
        final proximity = pointer.dx - (bounds.right - padding.right);
        dx = config.calculatePanAmount(
          proximity,
          edgePaddingValue: padding.right,
        );
      }
    }

    // Top edge / outside top
    if (pointer.dy < bounds.top + padding.top) {
      if (isOutside && pointer.dy < bounds.top) {
        // Outside top - pan at max speed
        dy = -config.panAmount;
      } else if (padding.top > 0) {
        // In top edge zone - scale by proximity
        final proximity = bounds.top + padding.top - pointer.dy;
        dy = -config.calculatePanAmount(
          proximity,
          edgePaddingValue: padding.top,
        );
      }
    }
    // Bottom edge / outside bottom
    else if (pointer.dy > bounds.bottom - padding.bottom) {
      if (isOutside && pointer.dy > bounds.bottom) {
        // Outside bottom - pan at max speed
        dy = config.panAmount;
      } else if (padding.bottom > 0) {
        // In bottom edge zone - scale by proximity
        final proximity = pointer.dy - (bounds.bottom - padding.bottom);
        dy = config.calculatePanAmount(
          proximity,
          edgePaddingValue: padding.bottom,
        );
      }
    }

    if (dx != 0.0 || dy != 0.0) {
      final delta = Offset(dx, dy);

      // 1. Pan viewport
      onAutoPan(delta);

      // 2. Move element by same amount to keep it moving with the pan
      //    This applies both when inside edge zone and outside bounds
      widget.onDragUpdate(
        DragUpdateDetails(globalPosition: pointer, delta: delta),
      );
    }
  }
}
