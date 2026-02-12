import 'package:flutter/gestures.dart';

/// A pan gesture recognizer that ignores trackpad gestures.
///
/// This recognizer extends [PanGestureRecognizer] but rejects any pointer
/// that originates from a trackpad. This allows trackpad two-finger gestures
/// to bubble up to parent widgets (like [InteractiveViewer]) for canvas panning,
/// while still handling mouse and touch gestures for element dragging.
///
/// ## Usage
///
/// Use with [RawGestureDetector] instead of [GestureDetector]:
///
/// ```dart
/// RawGestureDetector(
///   gestures: {
///     NonTrackpadPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<
///         NonTrackpadPanGestureRecognizer>(
///       () => NonTrackpadPanGestureRecognizer(),
///       (recognizer) {
///         recognizer
///           ..onStart = _handlePanStart
///           ..onUpdate = _handlePanUpdate
///           ..onEnd = _handlePanEnd;
///       },
///     ),
///   },
///   child: myWidget,
/// )
/// ```
///
/// ## Why This Is Needed
///
/// On macOS and other platforms with trackpads, two-finger gestures generate
/// [PointerPanZoomEvent] events that bypass the normal pointer event flow.
/// These events go directly to [handleEvent] without triggering [addPointer]
/// or [isPointerAllowed]. The standard [PanGestureRecognizer] processes these
/// as pan gestures, which prevents parent widgets like [InteractiveViewer]
/// from handling canvas panning.
///
/// By rejecting trackpad events in both [handleEvent] and [isPointerAllowed],
/// we allow the gesture to bubble up to the parent's gesture recognizers.
class NonTrackpadPanGestureRecognizer extends PanGestureRecognizer {
  /// Creates a pan gesture recognizer that ignores trackpad gestures.
  NonTrackpadPanGestureRecognizer({super.debugOwner, this.allowTouch = false});

  /// Whether touch/stylus pointers are allowed by this recognizer.
  /// Defaults to false to avoid competing with touch-specific handlers.
  final bool allowTouch;

  /// Stores the default drag start behavior configured by the caller.
  /// This lets us override behavior per pointer type without losing the
  /// caller's intent (e.g., ports use DragStartBehavior.down).
  DragStartBehavior _defaultDragStartBehavior = DragStartBehavior.start;

  @override
  set dragStartBehavior(DragStartBehavior value) {
    _defaultDragStartBehavior = value;
    super.dragStartBehavior = value;
  }

  void _applyDragStartBehaviorForPointer(PointerDownEvent event) {
    final isTouchLike =
        event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;

    // On touch devices, starting immediately helps win the gesture arena
    // against InteractiveViewer panning/zooming.
    if (isTouchLike && _defaultDragStartBehavior == DragStartBehavior.start) {
      super.dragStartBehavior = DragStartBehavior.down;
      return;
    }

    super.dragStartBehavior = _defaultDragStartBehavior;
  }

  @override
  void addPointer(PointerDownEvent event) {
    _applyDragStartBehaviorForPointer(event);
    super.addPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    // Reject trackpad events - let them bubble to InteractiveViewer for canvas panning.
    // On macOS, two-finger trackpad gestures generate PointerPanZoomEvent which bypasses
    // addPointer/isPointerAllowed and goes directly to handleEvent.
    if (event.kind == PointerDeviceKind.trackpad ||
        (!allowTouch &&
            (event.kind == PointerDeviceKind.touch ||
                event.kind == PointerDeviceKind.stylus ||
                event.kind == PointerDeviceKind.invertedStylus))) {
      return;
    }
    super.handleEvent(event);
  }

  @override
  bool isPointerAllowed(PointerEvent event) {
    // Reject trackpad pointers - let them bubble to InteractiveViewer
    if (event.kind == PointerDeviceKind.trackpad ||
        (!allowTouch &&
            (event.kind == PointerDeviceKind.touch ||
                event.kind == PointerDeviceKind.stylus ||
                event.kind == PointerDeviceKind.invertedStylus))) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  void handleNonAllowedPointer(PointerDownEvent event) {
    // CRITICAL: Do nothing for trackpad pointers.
    // The default implementation in OneSequenceGestureRecognizer calls
    // resolve(GestureDisposition.rejected), which can interfere with an
    // ongoing drag gesture. By returning early for trackpad pointers,
    // we ensure that a trackpad tap during a mouse drag doesn't cancel
    // the mouse drag.
    if (event.kind == PointerDeviceKind.trackpad ||
        (!allowTouch &&
            (event.kind == PointerDeviceKind.touch ||
                event.kind == PointerDeviceKind.stylus ||
                event.kind == PointerDeviceKind.invertedStylus))) {
      return;
    }
    super.handleNonAllowedPointer(event);
  }

  @override
  void addPointerPanZoom(PointerPanZoomStartEvent event) {
    // CRITICAL: Do NOT add trackpad pan/zoom pointers to this recognizer.
    // PointerPanZoomStartEvent bypasses isPointerAllowed and addPointer.
    // By not calling super, we prevent the trackpad from entering the gesture arena
    // for this recognizer, allowing it to bubble to InteractiveViewer.
    if (event.kind == PointerDeviceKind.trackpad) {
      return;
    }
    super.addPointerPanZoom(event);
  }
}
