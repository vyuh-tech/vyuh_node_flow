import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'non_trackpad_pan_gesture_recognizer.dart';

/// A unified interaction scope for draggable elements (nodes, annotations, ports).
///
/// This widget provides consistent gesture handling and drag lifecycle management
/// across all interactive elements in the node flow editor. It solves the problem
/// of gesture recognizer callbacks not firing when widgets rebuild during drag
/// operations (due to MobX Observer rebuilds).
///
/// ## Key Features
///
/// 1. **StatefulWidget Architecture**: The State object persists across widget
///    rebuilds, maintaining drag state even when the parent Observer rebuilds.
///
/// 2. **Local Drag Tracking**: Uses `_isDragging` to track whether this widget
///    instance started a drag, preventing duplicate start/end calls.
///
/// 3. **Dispose Cleanup**: If the widget is removed while dragging (e.g., element
///    deleted), `dispose()` ensures proper cleanup by calling `onDragEnd`.
///
/// 4. **Guard Clauses**: All drag methods check `_isDragging` state to prevent
///    invalid operations (double-start, end without start, etc.).
///
/// 5. **Pointer ID Tracking**: Tracks which pointer started the drag to prevent
///    interference from other pointers (e.g., trackpad taps during mouse drag).
///
/// ## Gesture Handling
///
/// Uses [RawGestureDetector] with [NonTrackpadPanGestureRecognizer] to:
/// - Handle mouse/touch drag gestures
/// - Reject trackpad gestures (allowing them to bubble up for canvas panning)
/// - Support double-tap and context menu (right-click) gestures
///
/// ## Widget Tree Structure
///
/// ```
/// ElementScope (StatefulWidget)
/// └── Listener (immediate tap feedback, pointer ID tracking)
///     └── RawGestureDetector (drag, double-tap, context menu)
///         └── MouseRegion (cursor, hover callbacks)
///             └── child (provided by parent)
/// ```
///
/// ## Example Usage
///
/// For element movement (nodes, annotations):
/// ```dart
/// ElementScope(
///   onDragStart: (_) => controller.startNodeDrag(nodeId),
///   onDragUpdate: (details) => controller.moveNodeDrag(details.delta),
///   onDragEnd: (_) => controller.endNodeDrag(),
///   onTap: () => controller.selectNode(nodeId),
///   cursor: SystemMouseCursors.grab,
///   child: NodeVisual(...),
/// )
/// ```
///
/// For connection creation (ports):
/// ```dart
/// ElementScope(
///   onDragStart: (details) => controller.startConnection(details.globalPosition),
///   onDragUpdate: (details) => controller.updateConnection(details.globalPosition),
///   onDragEnd: (details) => controller.completeConnection(),
///   dragStartBehavior: DragStartBehavior.down, // Start immediately on pointer down
///   child: PortVisual(...),
/// )
/// ```
///
/// See also:
/// - [NodeWidget] which uses this for node interactions
/// - [AnnotationWidget] which uses this for annotation interactions
/// - [PortWidget] which uses this for connection creation
class ElementScope extends StatefulWidget {
  /// Creates an element scope with the specified interaction callbacks.
  ///
  /// The [onDragStart], [onDragUpdate], and [onDragEnd] callbacks are required
  /// and form the core drag lifecycle. Other callbacks are optional.
  const ElementScope({
    super.key,
    required this.child,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onDragCancel,
    this.isDraggable = true,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onTap,
    this.onDoubleTap,
    this.onContextMenu,
    this.onMouseEnter,
    this.onMouseLeave,
    this.cursor,
    this.hitTestBehavior = HitTestBehavior.opaque,
  });

  /// The child widget to wrap with interaction handling.
  ///
  /// This is typically the visual representation of the element (node or annotation).
  final Widget child;

  /// Whether this element can be dragged.
  ///
  /// When false, the drag gesture recognizer is not registered, allowing
  /// drag events to pass through to underlying elements.
  final bool isDraggable;

  /// Determines when a drag gesture formally starts.
  ///
  /// - [DragStartBehavior.start] (default): Drag starts after the pointer has
  ///   moved beyond the drag threshold. Best for element movement where you want
  ///   to distinguish between taps and drags.
  ///
  /// - [DragStartBehavior.down]: Drag starts immediately on pointer down. Best
  ///   for connection creation (ports) where you want immediate feedback.
  final DragStartBehavior dragStartBehavior;

  /// Called when a drag operation starts.
  ///
  /// Receives [DragStartDetails] with the start position. Use this to:
  /// - Set the dragged element ID in the controller
  /// - Select the element if not already selected
  /// - Disable canvas panning
  /// - Calculate connection start point (for ports)
  final void Function(DragStartDetails details) onDragStart;

  /// Called during drag with update details.
  ///
  /// Receives [DragUpdateDetails] containing:
  /// - [delta]: Movement since last update (useful for element movement)
  /// - [globalPosition]: Current pointer position (useful for connections)
  /// - [localPosition]: Position relative to this widget
  final void Function(DragUpdateDetails details) onDragUpdate;

  /// Called when a drag operation ends normally.
  ///
  /// Receives [DragEndDetails] with velocity information. Use this to:
  /// - Clear the dragged element ID
  /// - Re-enable canvas panning
  /// - Complete connections (for ports)
  final void Function(DragEndDetails details) onDragEnd;

  /// Called when a drag operation is cancelled.
  ///
  /// This is called instead of [onDragEnd] when:
  /// - The gesture recognizer cancels the gesture
  /// - The widget is disposed mid-drag
  /// - The pointer up handler detects the original pointer released
  ///
  /// If null, [onDragEnd] is called with empty [DragEndDetails] as a fallback.
  final VoidCallback? onDragCancel;

  /// Called when the element is tapped.
  ///
  /// Fires immediately on pointer down (before gesture arena resolution)
  /// for instant selection feedback.
  final VoidCallback? onTap;

  /// Called when the element is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Called when the element is right-clicked (context menu).
  ///
  /// Receives the global position for showing a context menu.
  final void Function(Offset globalPosition)? onContextMenu;

  /// Called when the mouse enters the element bounds.
  final VoidCallback? onMouseEnter;

  /// Called when the mouse leaves the element bounds.
  final VoidCallback? onMouseLeave;

  /// The cursor to display when hovering over the element.
  ///
  /// If null, [MouseCursor.defer] is used.
  final MouseCursor? cursor;

  /// How to behave during hit testing.
  ///
  /// Defaults to [HitTestBehavior.opaque] which captures all events within bounds.
  /// Use [HitTestBehavior.translucent] if you need events to pass through.
  final HitTestBehavior hitTestBehavior;

  @override
  State<ElementScope> createState() => _ElementScopeState();
}

class _ElementScopeState extends State<ElementScope> {
  /// Local drag state - tracks whether THIS widget instance started a drag.
  ///
  /// This is the source of truth for drag lifecycle within this widget.
  /// It persists across Observer rebuilds because State objects survive
  /// widget rebuilds (as long as widget type and key match).
  bool _isDragging = false;

  /// The pointer ID that started the current drag.
  ///
  /// Used to ensure we only end the drag when the SAME pointer that started
  /// it ends. This prevents premature drag termination when other pointers
  /// (like trackpad gestures) end while the drag is active.
  int? _dragPointerId;

  /// The pointer ID captured from onPointerDown, used for _startDrag.
  ///
  /// Since DragStartDetails doesn't contain the pointer ID, we capture it
  /// from the Listener's onPointerDown (which fires immediately) and use
  /// it when the gesture recognizer's onStart fires (after gesture arena).
  int? _pendingPointerId;

  @override
  void dispose() {
    // Guarantee cleanup: if we're still dragging when disposed, cancel the drag.
    // This handles edge cases like:
    // - Element deletion during drag
    // - Widget tree restructuring during drag
    // - Hot reload during drag
    if (_isDragging) {
      _cancelDrag();
    }
    super.dispose();
  }

  /// Starts a drag operation using the captured pointer ID.
  ///
  /// Guard: Returns early if already dragging to prevent duplicate starts.
  /// Uses the pointer ID captured from onPointerDown (stored in _pendingPointerId).
  void _startDrag(DragStartDetails details) {
    if (_isDragging) return;
    _isDragging = true;
    _dragPointerId = _pendingPointerId;
    widget.onDragStart(details);
  }

  /// Updates during an active drag operation.
  ///
  /// Guard: Returns early if not dragging to prevent orphaned update events.
  void _updateDrag(DragUpdateDetails details) {
    if (!_isDragging) return;
    widget.onDragUpdate(details);
  }

  /// Ends the current drag operation.
  ///
  /// Guard: Returns early if not dragging to prevent duplicate ends.
  void _endDrag(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    _dragPointerId = null;
    widget.onDragEnd(details);
  }

  /// Cancels the current drag operation.
  ///
  /// Called when the drag is interrupted (gesture cancelled, widget disposed,
  /// or pointer released). Calls [onDragCancel] if provided, otherwise falls
  /// back to [onDragEnd] with empty details.
  void _cancelDrag() {
    if (!_isDragging) return;
    _isDragging = false;
    _dragPointerId = null;
    // Use dedicated cancel callback if provided, otherwise fall back to onDragEnd
    if (widget.onDragCancel != null) {
      widget.onDragCancel!();
    } else {
      widget.onDragEnd(DragEndDetails());
    }
  }

  /// Called on pointer up to check if the drag should end.
  ///
  /// Only ends the drag if the pointer that started the drag is the one ending.
  /// This is purely based on pointer ID matching - device kind doesn't matter.
  ///
  /// IMPORTANT: This is a safety net for edge cases where the gesture recognizer
  /// doesn't fire its callbacks. We schedule the cancel for the next microtask
  /// to give the gesture recognizer's `onEnd` callback priority. If `onEnd`
  /// fires first, it sets `_isDragging = false`, and this cancel becomes a no-op.
  ///
  /// Note: This is treated as a cancel because we don't have proper DragEndDetails
  /// from a pointer up event outside the gesture recognizer flow.
  void _handlePointerUp(PointerUpEvent event) {
    // Only consider canceling if this is the EXACT pointer that started the drag
    if (_isDragging && event.pointer == _dragPointerId) {
      // Schedule for next microtask to give gesture recognizer's onEnd priority.
      // The gesture recognizer processes the same PointerUpEvent and should call
      // onEnd synchronously. By deferring, we ensure onEnd fires first if it's
      // going to fire at all. If it doesn't (edge case), this cancel will clean up.
      Future.microtask(() {
        // Check again - onEnd may have already handled it
        if (_isDragging) {
          _cancelDrag();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      // Listener fires IMMEDIATELY on pointer down, before gesture arena.
      // We capture the pointer ID here for use when the drag starts.
      // This also provides instant tap feedback (e.g., selection).
      //
      // IMPORTANT: We only capture the pointer ID if we're not already dragging.
      // If a drag is in progress, a second pointer (any device) should not
      // overwrite the original pointer ID or trigger a new tap.
      onPointerDown: (event) {
        // If already dragging, don't let another pointer interfere
        if (_isDragging) {
          return;
        }

        _pendingPointerId = event.pointer;
        widget.onTap?.call();
      },
      // Track pointer up to ensure drag ends when the correct pointer releases
      onPointerUp: _handlePointerUp,
      child: RawGestureDetector(
        behavior: widget.hitTestBehavior,
        gestures: <Type, GestureRecognizerFactory>{
          // Custom pan recognizer that rejects trackpad gestures.
          // This allows trackpad pan to bubble up to InteractiveViewer
          // for canvas panning, while mouse/touch drag moves the element.
          if (widget.isDraggable)
            NonTrackpadPanGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  NonTrackpadPanGestureRecognizer
                >(() => NonTrackpadPanGestureRecognizer(), (recognizer) {
                  // Configure drag start behavior (immediate for ports, threshold for elements)
                  recognizer.dragStartBehavior = widget.dragStartBehavior;
                  // Use local methods that track drag state and pass full details
                  recognizer.onStart = _startDrag;
                  recognizer.onUpdate = _updateDrag;
                  recognizer.onEnd = _endDrag;
                  recognizer.onCancel = _cancelDrag;
                }),

          // Double tap recognizer
          if (widget.onDoubleTap != null)
            DoubleTapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  DoubleTapGestureRecognizer
                >(() => DoubleTapGestureRecognizer(), (recognizer) {
                  recognizer.onDoubleTap = widget.onDoubleTap;
                }),

          // Secondary tap (right-click) for context menu
          if (widget.onContextMenu != null)
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  () => TapGestureRecognizer(),
                  (recognizer) {
                    recognizer.onSecondaryTapUp = (details) =>
                        widget.onContextMenu!(details.globalPosition);
                  },
                ),
        },
        child: MouseRegion(
          cursor: widget.cursor ?? MouseCursor.defer,
          onEnter: widget.onMouseEnter != null
              ? (_) => widget.onMouseEnter!()
              : null,
          onExit: widget.onMouseLeave != null
              ? (_) => widget.onMouseLeave!()
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}
