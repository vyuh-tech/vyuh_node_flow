import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'auto_pan/auto_pan_mixin.dart';
import 'drag_session.dart';
import 'non_trackpad_pan_gesture_recognizer.dart';
import '../extensions/autopan/auto_pan_extension.dart';
import '../graph/coordinates.dart';

/// A unified interaction scope for draggable elements (nodes, ports).
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
/// For element movement (nodes):
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
/// ## Autopan Support
///
/// When [autoPan] is provided and enabled, the widget automatically pans the
/// viewport when the pointer approaches the edges during a drag operation.
/// The element moves with the viewport during autopan.
///
/// ```dart
/// ElementScope(
///   onDragStart: (_) => controller.startNodeDrag(nodeId),
///   onDragUpdate: (details) => controller.moveNodeDrag(details.delta),
///   onDragEnd: (_) => controller.endNodeDrag(),
///   // Enable autopan via the controller's autopan extension
///   autoPan: controller.autoPan,
///   getViewportBounds: () => controller.viewportScreenBounds.rect,
///   onAutoPan: (delta) {
///     // Pan viewport - ElementScope also calls onDragUpdate to move element
///     final zoom = controller.viewport.zoom;
///     controller.panBy(ScreenOffset(Offset(-delta.dx * zoom, -delta.dy * zoom)));
///   },
///   child: NodeVisual(...),
/// )
/// ```
///
/// See also:
/// - [NodeWidget] which uses this for node interactions
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
    this.createSession,
    this.isDraggable = true,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onTap,
    this.onDoubleTap,
    this.onContextMenu,
    this.onMouseEnter,
    this.onMouseLeave,
    this.cursor,
    this.hitTestBehavior = HitTestBehavior.opaque,
    // Autopan parameters
    this.autoPan,
    this.onAutoPan,
    this.getViewportBounds,
    this.screenToGraph,
  });

  /// The child widget to wrap with interaction handling.
  ///
  /// This is typically the visual representation of the element.
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

  /// Factory function to create a [DragSession] for this element.
  ///
  /// When provided, ElementScope manages the session lifecycle:
  /// - On drag start: calls [createSession], then [DragSession.start] (locks canvas)
  /// - On drag end: calls [DragSession.end] (unlocks canvas)
  /// - On drag cancel: calls [DragSession.cancel] (unlocks canvas)
  ///
  /// Elements manage their own business state (positions, sizes) internally.
  /// The session purely handles canvas lock coordination.
  ///
  /// Example:
  /// ```dart
  /// ElementScope(
  ///   createSession: () => controller.createSession(),
  ///   onDragStart: (_) => controller.startNodeDrag(nodeId),
  ///   onDragUpdate: (details) => controller.moveNodeDrag(details.delta),
  ///   onDragEnd: (_) => controller.endNodeDrag(),
  ///   // ... other callbacks
  /// )
  /// ```
  final DragSession Function()? createSession;

  /// Called when the element is tapped.
  ///
  /// Fires immediately on pointer down (before gesture arena resolution)
  /// for instant selection feedback.
  final VoidCallback? onTap;

  /// Called when the element is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Called when the element is right-clicked (context menu).
  ///
  /// Receives the screen position for showing a context menu.
  final void Function(ScreenPosition screenPosition)? onContextMenu;

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

  // ---------------------------------------------------------------------------
  // Autopan Parameters
  // ---------------------------------------------------------------------------

  /// The autopan extension for autopan behavior during drag operations.
  ///
  /// When provided (non-null) and enabled, autopan is active. The viewport will
  /// automatically pan when the pointer approaches the edges during a drag.
  ///
  /// Requires [onAutoPan] and [getViewportBounds] to also be provided.
  final AutoPanExtension? autoPan;

  /// Callback invoked when autopan triggers during a drag.
  ///
  /// Receives the pan delta in graph units. The parent should:
  /// 1. Pan the viewport by this delta (converted to screen units with zoom)
  /// 2. Move the dragged element by this delta to maintain cursor position
  ///
  /// Required when [autoPan] is provided.
  final void Function(Offset delta)? onAutoPan;

  /// Returns the current viewport bounds in screen coordinates.
  ///
  /// Used to determine when the pointer is within the edge padding zone.
  /// Required when [autoPan] is provided.
  final Rect Function()? getViewportBounds;

  /// Converts a screen position to graph coordinates.
  ///
  /// When provided, enables absolute positioning mode where the element
  /// position is calculated directly from the pointer's graph position.
  /// This prevents offset accumulation issues that can occur with delta-based
  /// positioning.
  ///
  /// Example:
  /// ```dart
  /// screenToGraph: (screenPos) => controller.screenToGraph(screenPos).offset,
  /// ```
  final Offset Function(Offset screenPosition)? screenToGraph;

  @override
  State<ElementScope> createState() => _ElementScopeState();
}

class _ElementScopeState extends State<ElementScope> with AutoPanMixin {
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

  /// The current drag session, if any.
  ///
  /// Created via [ElementScope.createSession] at drag start, manages canvas
  /// locking/unlocking automatically.
  DragSession? _session;

  // ---------------------------------------------------------------------------
  // AutoPanMixin Implementation
  // ---------------------------------------------------------------------------

  @override
  bool get isDragging => _isDragging;

  @override
  void dispose() {
    // Stop autopan timer before other cleanup (from mixin)
    stopAutoPan();
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
  ///
  /// If [createSession] is provided, creates a session and starts it,
  /// which automatically locks the canvas.
  void _startDrag(DragStartDetails details) {
    if (_isDragging) return;
    _isDragging = true;
    _dragPointerId = _pendingPointerId;
    resetAutoPanState(); // Reset drift at drag start (from mixin)

    // Create and start session if factory provided (locks canvas automatically)
    if (widget.createSession != null) {
      _session = widget.createSession!();
      _session!.start();
    }

    widget.onDragStart(details);
  }

  /// Updates during an active drag operation.
  ///
  /// Guard: Returns early if not dragging to prevent orphaned update events.
  /// Tracks pointer position for autopan and processes delta for drift compensation.
  ///
  /// Drift handling:
  /// - **Inside bounds**: Normal 1:1 movement (drift consumed/compensated if any)
  /// - **Outside bounds**: Element stays put, drift accumulates
  /// - **Re-entry**: For [trackPointerDirectly] elements, drift is applied
  ///   immediately (snap). For others, drift is consumed gradually.
  void _updateDrag(DragUpdateDetails details) {
    if (!_isDragging) return;

    // Track pointer position for autopan (uses mixin method)
    updatePointerPosition(details.globalPosition);

    // Process delta with drift compensation
    // For trackPointerDirectly: immediate snap on re-entry
    // For positioned elements: gradual consumption
    final effectiveDelta = processDragDelta(details.delta);

    // Only call onDragUpdate if there's actual movement
    if (effectiveDelta != Offset.zero) {
      widget.onDragUpdate(
        DragUpdateDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
          delta: effectiveDelta,
          primaryDelta: details.primaryDelta,
          sourceTimeStamp: details.sourceTimeStamp,
        ),
      );
    }
  }

  /// Ends the current drag operation.
  ///
  /// Guard: Returns early if not dragging to prevent duplicate ends.
  /// Stops the autopan timer and clears pointer position and drift.
  /// Ends the session if active (unlocks canvas automatically).
  void _endDrag(DragEndDetails details) {
    if (!_isDragging) return;
    stopAutoPan(); // From AutoPanMixin
    resetAutoPanState(); // From AutoPanMixin
    _isDragging = false;
    _dragPointerId = null;

    // End session if active (unlocks canvas automatically)
    _session?.end();
    _session = null;

    widget.onDragEnd(details);
  }

  /// Cancels the current drag operation.
  ///
  /// Called when the drag is interrupted (gesture cancelled, widget disposed,
  /// or pointer released). Cancels the session if active (unlocks canvas).
  /// Then calls [onDragCancel] if provided, otherwise falls back to [onDragEnd].
  void _cancelDrag() {
    if (!_isDragging) return;
    stopAutoPan(); // From AutoPanMixin
    resetAutoPanState(); // From AutoPanMixin
    _isDragging = false;
    _dragPointerId = null;

    // Cancel session if active (unlocks canvas automatically)
    _session?.cancel();
    _session = null;

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
                        widget.onContextMenu!(
                          ScreenPosition(details.globalPosition),
                        );
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
