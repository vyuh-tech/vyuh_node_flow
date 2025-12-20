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
  NonTrackpadPanGestureRecognizer({super.debugOwner});

  @override
  void handleEvent(PointerEvent event) {
    // Reject trackpad events - let them bubble to InteractiveViewer for canvas panning.
    // On macOS, two-finger trackpad gestures generate PointerPanZoomEvent which bypasses
    // addPointer/isPointerAllowed and goes directly to handleEvent.
    if (event.kind == PointerDeviceKind.trackpad) {
      return;
    }
    super.handleEvent(event);
  }

  @override
  bool isPointerAllowed(PointerEvent event) {
    // Reject trackpad pointers - let them bubble to InteractiveViewer
    if (event.kind == PointerDeviceKind.trackpad) {
      return false;
    }
    return super.isPointerAllowed(event);
  }
}
