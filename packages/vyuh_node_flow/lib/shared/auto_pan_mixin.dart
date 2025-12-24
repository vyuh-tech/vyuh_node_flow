import 'dart:async';

import 'package:flutter/material.dart';

import 'element_scope.dart';

/// Mixin that provides autopan functionality for [ElementScope].
///
/// This mixin handles:
/// - Timer-based autopan when pointer is near viewport edges
/// - Position clamping to keep elements within inner bounds
/// - Drift tracking for sticky behavior (element stays anchored until
///   pointer catches up to its original relative position)
///
/// ## Usage
///
/// Apply this mixin to a State class that extends [State<ElementScope>]:
///
/// ```dart
/// class _ElementScopeState extends State<ElementScope> with AutoPanMixin {
///   bool _isDragging = false;
///
///   @override
///   bool get isDragging => _isDragging;
///
///   // Use mixin methods in drag handlers...
/// }
/// ```
mixin AutoPanMixin on State<ElementScope> {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Timer for periodic autopan during drag.
  Timer? _autoPanTimer;

  /// Last known pointer position in screen coordinates.
  /// Used by the autopan timer to check edge proximity.
  Offset? _lastPointerPosition;

  /// Accumulated drift from clamping.
  ///
  /// When the element is clamped at the inner bounds edge and the pointer
  /// continues moving (during autopan), drift accumulates. This represents
  /// how far the pointer has "drifted away" from where it would be if the
  /// element could move freely.
  ///
  /// When the pointer returns toward the center, drift is consumed first
  /// before the element starts moving again. This creates "sticky" behavior
  /// where the element stays anchored until the pointer catches up to its
  /// original relative position.
  Offset _drift = Offset.zero;

  // ---------------------------------------------------------------------------
  // Abstract Interface
  // ---------------------------------------------------------------------------

  /// Whether a drag operation is currently in progress.
  ///
  /// The host State must provide this so the mixin can guard autopan operations.
  bool get isDragging;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Updates pointer position and starts autopan timer if configured.
  ///
  /// Call this from the drag update handler.
  void updatePointerPosition(Offset globalPosition) {
    _lastPointerPosition = globalPosition;

    // Start autopan timer if configured and not already running
    if (widget.autoPan != null && _autoPanTimer == null) {
      _startAutoPan();
    }
  }

  /// Processes a delta through the drift consumption and clamping pipeline.
  ///
  /// This implements "sticky" behavior:
  /// 1. First consume any accumulated drift (from previous clamping)
  /// 2. Apply clamping to the remaining delta
  /// 3. Accumulate new drift if clamping prevented movement
  ///
  /// The result is that when the pointer drifts away during autopan,
  /// the element stays anchored. When returning, the element doesn't move
  /// until the pointer catches up to its original relative position.
  Offset processDelta(Offset delta) {
    // Step 1: Consume existing drift
    final afterDriftConsumption = _consumeDrift(delta);

    // Step 2: Apply clamping
    final clampedDelta = _clampDelta(afterDriftConsumption);

    // Step 3: Accumulate new drift from clamping
    _drift += afterDriftConsumption - clampedDelta;

    return clampedDelta;
  }

  /// Resets all autopan state.
  ///
  /// Call this at drag start, end, and cancel.
  void resetAutoPanState() {
    _drift = Offset.zero;
    _lastPointerPosition = null;
  }

  /// Stops the autopan timer.
  ///
  /// Call this at drag end, cancel, and in dispose.
  void stopAutoPan() {
    _autoPanTimer?.cancel();
    _autoPanTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Private Implementation
  // ---------------------------------------------------------------------------

  /// Starts the autopan timer if configured and not already running.
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

  /// Performs autopan check and triggers pan if pointer is near edges.
  ///
  /// Called periodically by [_autoPanTimer] during drag operations.
  ///
  /// This method:
  /// 1. Calculates autopan delta based on pointer proximity to edges
  /// 2. Calls [onAutoPan] with the FULL delta for viewport panning
  /// 3. Processes delta through drift/clamping pipeline for element movement
  ///
  /// The viewport always pans to reveal more canvas. The element stays
  /// anchored at the inner bounds edge, and drift accumulates. When the
  /// pointer returns, the element only moves after drift is consumed
  /// (sticky behavior).
  void _performAutoPan() {
    final config = widget.autoPan;
    final onAutoPan = widget.onAutoPan;
    final getViewportBounds = widget.getViewportBounds;
    final pointer = _lastPointerPosition;

    // Guard: All required components must be available
    if (config == null ||
        onAutoPan == null ||
        getViewportBounds == null ||
        pointer == null ||
        !isDragging) {
      return;
    }

    final bounds = getViewportBounds();
    final padding = config.edgePadding;

    double dx = 0.0;
    double dy = 0.0;

    // Check left edge - pan left (negative delta)
    if (pointer.dx < bounds.left + padding) {
      final proximity = bounds.left + padding - pointer.dx;
      dx = -config.calculatePanAmount(proximity);
    }
    // Check right edge - pan right (positive delta)
    else if (pointer.dx > bounds.right - padding) {
      final proximity = pointer.dx - (bounds.right - padding);
      dx = config.calculatePanAmount(proximity);
    }

    // Check top edge - pan up (negative delta)
    if (pointer.dy < bounds.top + padding) {
      final proximity = bounds.top + padding - pointer.dy;
      dy = -config.calculatePanAmount(proximity);
    }
    // Check bottom edge - pan down (positive delta)
    else if (pointer.dy > bounds.bottom - padding) {
      final proximity = pointer.dy - (bounds.bottom - padding);
      dy = config.calculatePanAmount(proximity);
    }

    // Trigger pan and element movement if any edge is near
    if (dx != 0.0 || dy != 0.0) {
      final delta = Offset(dx, dy);

      // 1. Pan viewport by FULL delta (always happens to reveal more canvas)
      onAutoPan(delta);

      // 2. Process delta through drift/clamping pipeline
      // This accumulates drift when clamped, enabling sticky behavior
      final effectiveDelta = processDelta(delta);
      if (effectiveDelta != Offset.zero) {
        widget.onDragUpdate(
          DragUpdateDetails(globalPosition: pointer, delta: effectiveDelta),
        );
      }
    }
  }

  /// Clamps a drag delta to anchor the element position at the inner bounds edge.
  ///
  /// The inner bounds is the viewport minus the edge padding from autopan config.
  /// When the element's position reaches the edge, it stays anchored there while
  /// the viewport pans behind it.
  ///
  /// Returns the original delta if clamping is not configured or not needed.
  Offset _clampDelta(Offset delta) {
    final config = widget.autoPan;
    final getViewportBounds = widget.getViewportBounds;
    final getElementPosition = widget.getElementPosition;
    final screenToGraph = widget.screenToGraph;

    // Guard: All required components must be available for clamping
    if (config == null ||
        !config.isEnabled ||
        getViewportBounds == null ||
        getElementPosition == null ||
        screenToGraph == null) {
      return delta;
    }

    final currentPos = getElementPosition();

    // Calculate inner bounds in screen coordinates
    final viewportBounds = getViewportBounds();
    final innerScreenBounds = viewportBounds.deflate(config.edgePadding);

    // Convert inner bounds corners to graph coordinates
    final topLeft = screenToGraph(innerScreenBounds.topLeft);
    final bottomRight = screenToGraph(innerScreenBounds.bottomRight);
    final innerGraphBounds = Rect.fromPoints(topLeft, bottomRight);

    // Calculate new position after applying delta
    var newX = currentPos.dx + delta.dx;
    var newY = currentPos.dy + delta.dy;

    // Clamp position to inner bounds (anchor at edge)
    newX = newX.clamp(innerGraphBounds.left, innerGraphBounds.right);
    newY = newY.clamp(innerGraphBounds.top, innerGraphBounds.bottom);

    // Return the clamped delta
    return Offset(newX - currentPos.dx, newY - currentPos.dy);
  }

  /// Consumes accumulated drift from the given delta.
  ///
  /// When moving in the opposite direction of accumulated drift,
  /// the drift is reduced first before any movement is applied.
  /// This ensures the pointer must "catch up" to the element before
  /// movement resumes.
  ///
  /// Returns the effective delta after drift consumption.
  Offset _consumeDrift(Offset delta) {
    double effectiveDx = delta.dx;
    double effectiveDy = delta.dy;

    // X-axis: consume drift if moving in opposite direction
    if (_drift.dx > 0 && delta.dx < 0) {
      // Drift is positive (pointer drifted right), moving left to compensate
      final consume = (-delta.dx).clamp(0.0, _drift.dx);
      _drift = Offset(_drift.dx - consume, _drift.dy);
      effectiveDx = delta.dx + consume; // Reduce leftward movement magnitude
    } else if (_drift.dx < 0 && delta.dx > 0) {
      // Drift is negative (pointer drifted left), moving right to compensate
      final consume = delta.dx.clamp(0.0, -_drift.dx);
      _drift = Offset(_drift.dx + consume, _drift.dy);
      effectiveDx = delta.dx - consume; // Reduce rightward movement magnitude
    }

    // Y-axis: same logic
    if (_drift.dy > 0 && delta.dy < 0) {
      // Drift is positive (pointer drifted down), moving up to compensate
      final consume = (-delta.dy).clamp(0.0, _drift.dy);
      _drift = Offset(_drift.dx, _drift.dy - consume);
      effectiveDy = delta.dy + consume;
    } else if (_drift.dy < 0 && delta.dy > 0) {
      // Drift is negative (pointer drifted up), moving down to compensate
      final consume = delta.dy.clamp(0.0, -_drift.dy);
      _drift = Offset(_drift.dx, _drift.dy + consume);
      effectiveDy = delta.dy - consume;
    }

    return Offset(effectiveDx, effectiveDy);
  }
}
