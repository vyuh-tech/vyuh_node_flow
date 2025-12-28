import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';

import '../connections/temporary_connection.dart';
import '../graph/coordinates.dart';
import '../editor/resizer_widget.dart';

/// Contains all interaction-related state for the node flow editor.
///
/// This class manages the state for various user interactions including:
/// * Node dragging
/// * Connection creation
/// * Multi-node selection
/// * Mouse cursor state
/// * Pan/zoom control
///
/// All state is managed using MobX observables for reactive updates.
/// The class provides both low-level observables and high-level convenience
/// getters for accessing state.
///
/// Example usage:
/// ```dart
/// final state = InteractionState();
///
/// // Check if user is dragging a node
/// if (state.currentDraggedNodeId != null) {
///   // Handle drag
/// }
///
/// // Start a connection
/// state.update(
///   temporaryConnection: TemporaryConnection(
///     sourceNodeId: 'node-1',
///     sourcePortId: 'port-1',
///   ),
/// );
/// ```
///
/// See also:
/// * [TemporaryConnection], which represents an in-progress connection
class InteractionState {
  /// Observable ID of the node currently being dragged.
  ///
  /// Null when no node is being dragged.
  final Observable<String?> draggedNodeId = Observable<String?>(null);

  /// Observable position of the last pointer event in screen/widget-local coordinates.
  ///
  /// This position is relative to the NodeFlowEditor widget's top-left corner,
  /// used for tracking cursor movement during interactions like drag selection.
  /// For graph coordinates, use [NodeFlowController.viewport.toGraph].
  /// Uses [ScreenPosition] for compile-time type safety.
  final Observable<ScreenPosition?> lastPointerPosition =
      Observable<ScreenPosition?>(null);

  /// Observable temporary connection being created.
  ///
  /// Non-null when the user is dragging from a port to create a connection.
  final Observable<TemporaryConnection?> temporaryConnection =
      Observable<TemporaryConnection?>(null);

  /// Observable starting point of a selection rectangle in graph coordinates.
  ///
  /// Non-null when the user has initiated a drag selection. This is the point
  /// where the selection drag started, in graph/canvas coordinates.
  /// Uses [GraphPosition] for compile-time type safety.
  final Observable<GraphPosition?> selectionStart = Observable<GraphPosition?>(
    null,
  );

  /// Observable selection rectangle bounds in graph coordinates.
  ///
  /// Non-null during active selection drag operations. The rectangle is in
  /// graph coordinates for hit testing against node positions.
  /// Uses [GraphRect] for compile-time type safety.
  final Observable<GraphRect?> selectionRect = Observable<GraphRect?>(null);

  /// Tracks nodes that were previously intersecting the selection rectangle.
  ///
  /// Used to prevent flickering during toggle selection mode.
  Set<String> _previouslyIntersecting = <String>{};

  /// Observable flag for whether the canvas is locked (pan/zoom disabled).
  ///
  /// When true, both pan and zoom gestures are disabled. This is set during
  /// drag operations (nodes, connections, resize) to prevent coordinate
  /// misalignment when the viewport changes mid-drag.
  final Observable<bool> canvasLocked = Observable(false);

  /// Observable flag for whether the viewport is currently being interacted with.
  ///
  /// True during canvas panning/zooming via InteractiveViewer.
  /// This is used to suppress hover effects on ports during viewport interactions,
  /// preventing stale highlights when the mouse passes over ports during pan gestures.
  final Observable<bool> isViewportInteracting = Observable(false);

  /// Observable flag for whether the cursor is hovering over a connection.
  ///
  /// Used to show a click cursor when hovering over connection segments.
  final Observable<bool> hoveringConnection = Observable(false);

  /// Observable cursor override for exclusive operations like resizing.
  ///
  /// When non-null, this cursor takes precedence over all other cursor
  /// derivation logic. Used during resize operations to lock the cursor
  /// to the active resize handle cursor regardless of what the mouse hovers over.
  final Observable<MouseCursor?> cursorOverride = Observable<MouseCursor?>(
    null,
  );

  /// Observable flag for whether the user has indicated selection intent.
  ///
  /// When true, shows selection cursor to indicate that the user can
  /// initiate a selection rectangle. Typically set when Shift key is held.
  final Observable<bool> selectionStarted = Observable(false);

  // ===========================================================================
  // Resize State (works for any resizable Node, including Annotations)
  // ===========================================================================

  /// Observable ID of the node currently being resized.
  ///
  /// This works for both regular nodes and annotations since Annotation
  /// extends Node. Null when no resize operation is in progress.
  final Observable<String?> resizingNodeId = Observable<String?>(null);

  /// Observable handle being used for the current resize operation.
  ///
  /// Determines which edge/corner is being dragged and the resize behavior.
  final Observable<ResizeHandle?> resizeHandle = Observable<ResizeHandle?>(
    null,
  );

  /// Checks if a connection is currently being created.
  ///
  /// Returns true when the user is dragging from a port to create a connection.
  /// Used by widgets to set their cursor during connection operations.
  ///
  /// Note: When accessed inside an Observer, this will track [temporaryConnection]
  /// changes since it accesses [temporaryConnection.value] internally.
  bool get isCreatingConnection => temporaryConnection.value != null;

  /// Gets the ID of the currently dragged node.
  ///
  /// Returns null if no node is being dragged.
  String? get currentDraggedNodeId => draggedNodeId.value;

  /// Gets the current pointer position in screen/widget-local coordinates.
  ///
  /// Returns null if no pointer position has been recorded.
  ScreenPosition? get pointerPosition => lastPointerPosition.value;

  /// Gets the starting node ID of the temporary connection.
  ///
  /// Returns null if no connection is being created.
  String? get connectionStartNodeId => temporaryConnection.value?.startNodeId;

  /// Gets the starting port ID of the temporary connection.
  ///
  /// Returns null if no connection is being created.
  String? get connectionStartPortId => temporaryConnection.value?.startPortId;

  /// Checks if a selection rectangle is being drawn.
  ///
  /// Returns true when the user is actively drag-selecting nodes.
  bool get isDrawingSelection => selectionRect.value != null;

  /// Gets the starting point of the selection rectangle in graph coordinates.
  ///
  /// Returns null if no selection is active.
  GraphPosition? get selectionStartPoint => selectionStart.value;

  /// Gets the current selection rectangle in graph coordinates.
  ///
  /// Returns null if no selection is active.
  GraphRect? get currentSelectionRect => selectionRect.value;

  /// Gets whether the canvas is locked (pan/zoom disabled).
  ///
  /// Returns true during drag operations to prevent coordinate misalignment.
  bool get isCanvasLocked => canvasLocked.value;

  /// Gets whether the viewport is currently being interacted with (panning/zooming).
  ///
  /// Returns true during active canvas pan/zoom gestures.
  bool get isViewportDragging => isViewportInteracting.value;

  /// Gets whether the cursor is hovering over a connection.
  ///
  /// Used to determine if a click cursor should be shown.
  bool get isHoveringConnection => hoveringConnection.value;

  /// Gets the current cursor override, if any.
  ///
  /// Returns null if no override is active, meaning cursor should be
  /// derived from element type and interaction state.
  MouseCursor? get currentCursorOverride => cursorOverride.value;

  /// Checks if there is an active cursor override.
  ///
  /// Returns true during exclusive operations like resizing.
  bool get hasCursorOverride => cursorOverride.value != null;

  /// Gets whether the user has indicated selection intent.
  ///
  /// When true, shows selection cursor to indicate selection mode is available.
  bool get hasStartedSelection => selectionStarted.value;

  /// Gets the ID of the node currently being resized.
  ///
  /// Returns null if no resize operation is in progress.
  /// Works for both regular nodes and annotations.
  String? get currentResizingNodeId => resizingNodeId.value;

  /// Gets the current resize handle.
  ///
  /// Returns null if no resize operation is in progress.
  ResizeHandle? get currentResizeHandle => resizeHandle.value;

  /// Checks if any resize operation is in progress.
  ///
  /// Returns true when a node or annotation is being resized.
  bool get isResizing => resizingNodeId.value != null;

  /// Sets the currently dragged node.
  ///
  /// Parameters:
  /// * [nodeId] - The ID of the node being dragged, or null to clear
  void setDraggedNode(String? nodeId) {
    runInAction(() {
      draggedNodeId.value = nodeId;
    });
  }

  /// Sets the current pointer position in screen/widget-local coordinates.
  ///
  /// Parameters:
  /// * [position] - The current pointer position relative to the widget, or null to clear
  void setPointerPosition(ScreenPosition? position) {
    runInAction(() {
      lastPointerPosition.value = position;
    });
  }

  /// Updates multiple state properties atomically.
  ///
  /// Only non-null parameters will be updated. This is useful for updating
  /// multiple related state properties in a single action.
  ///
  /// Parameters:
  /// * [canvasLocked] - Whether canvas interactions (pan/zoom) should be disabled
  /// * [temporaryConnection] - New temporary connection state
  void update({bool? canvasLocked, TemporaryConnection? temporaryConnection}) {
    runInAction(() {
      if (canvasLocked != null) this.canvasLocked.value = canvasLocked;
      if (temporaryConnection != null) {
        this.temporaryConnection.value = temporaryConnection;
      }
    });
  }

  /// Updates selection rectangle state and handles node selection.
  ///
  /// This method manages the selection rectangle during drag-selection operations
  /// and calls the [selectNodes] callback with nodes that intersect the rectangle.
  ///
  /// The method supports two selection modes:
  /// * Normal mode: Replaces the current selection with intersecting nodes
  /// * Toggle mode: Toggles the selection state of intersecting nodes while
  ///   preventing flicker by only toggling nodes whose intersection state changed
  ///
  /// Parameters:
  /// * [startPoint] - Starting point of the selection rectangle (graph coordinates)
  /// * [rectangle] - Current bounds of the selection rectangle (graph coordinates)
  /// * [intersectingNodes] - List of node IDs that intersect the rectangle
  /// * [toggle] - Whether to toggle selection instead of replacing
  /// * [selectNodes] - Callback to select/deselect nodes
  void updateSelection({
    GraphPosition? startPoint,
    GraphRect? rectangle,
    List<String>? intersectingNodes,
    bool? toggle,
    Function(List<String>, {bool toggle})? selectNodes,
  }) {
    runInAction(() {
      if (startPoint != null) {
        selectionStart.value = startPoint;
      }
      if (rectangle != null) {
        selectionRect.value = rectangle;
      }

      // Handle selection logic
      if (intersectingNodes != null && selectNodes != null) {
        final isToggle = toggle ?? false;

        if (isToggle) {
          // Cmd+drag: only toggle nodes that have changed state to prevent flickering
          final currentIntersecting = intersectingNodes.toSet();
          final nodesToToggle = currentIntersecting
              .difference(_previouslyIntersecting.toSet())
              .union(
                _previouslyIntersecting.toSet().difference(currentIntersecting),
              )
              .toList();

          if (nodesToToggle.isNotEmpty) {
            selectNodes(nodesToToggle, toggle: true);
          }

          _previouslyIntersecting = currentIntersecting;
        } else {
          // Shift+drag: replace selection normally
          selectNodes(intersectingNodes, toggle: false);
          _previouslyIntersecting.clear();
        }
      }
    });
  }

  /// Finishes the current selection operation.
  ///
  /// Clears the selection rectangle and resets tracking state.
  /// Should be called when the user releases the mouse button after
  /// drag-selecting nodes.
  void finishSelection() {
    runInAction(() {
      selectionStart.value = null;
      selectionRect.value = null;
      _previouslyIntersecting.clear();
    });
  }

  /// Cancels the current connection creation.
  ///
  /// Clears the temporary connection state. Should be called when the user
  /// cancels a connection drag operation (e.g., by pressing Escape or
  /// releasing outside a valid target port).
  void cancelConnection() {
    runInAction(() {
      temporaryConnection.value = null;
    });
  }

  /// Resets all interaction state to default values.
  ///
  /// Clears all ongoing interactions and unlocks the canvas.
  /// This is useful when canceling all interactions or resetting the editor.
  /// Note: Cursor is derived from state, so clearing state automatically resets cursor.
  void resetState() {
    runInAction(() {
      draggedNodeId.value = null;
      lastPointerPosition.value = null;
      temporaryConnection.value = null;
      selectionStart.value = null;
      selectionRect.value = null;
      canvasLocked.value = false;
      isViewportInteracting.value = false;
      hoveringConnection.value = false;
      cursorOverride.value = null;
      selectionStarted.value = false;
      resizingNodeId.value = null;
      resizeHandle.value = null;
    });
  }

  /// Sets the viewport interaction state.
  ///
  /// Parameters:
  /// * [interacting] - Whether the viewport is being interacted with
  void setViewportInteracting(bool interacting) {
    runInAction(() {
      isViewportInteracting.value = interacting;
    });
  }

  /// Sets the connection hover state.
  ///
  /// Parameters:
  /// * [hovering] - Whether the cursor is hovering over a connection
  void setHoveringConnection(bool hovering) {
    runInAction(() {
      hoveringConnection.value = hovering;
    });
  }

  /// Sets a global cursor override for exclusive operations.
  ///
  /// When set, this cursor takes precedence over all element-specific and
  /// interaction-based cursor derivation. Use this during resize, connection
  /// creation, or other exclusive operations where the cursor should remain
  /// locked regardless of what the mouse hovers over.
  ///
  /// Parameters:
  /// * [cursor] - The cursor to force, or null to clear the override
  void setCursorOverride(MouseCursor? cursor) {
    runInAction(() {
      cursorOverride.value = cursor;
    });
  }

  /// Sets the selection started state.
  ///
  /// When true, the cursor changes to selection cursor
  /// to indicate that selection mode is available.
  ///
  /// Parameters:
  /// * [started] - Whether selection mode has been initiated
  void setSelectionStarted(bool started) {
    runInAction(() {
      selectionStarted.value = started;
    });
  }

  // ===========================================================================
  // Resize Methods (unified for Node and Annotation)
  // ===========================================================================

  /// Starts a resize operation for a node.
  ///
  /// Works for any resizable Node, including annotations. The node must have
  /// [Node.isResizable] set to `true`.
  ///
  /// Parameters:
  /// * [nodeId] - The ID of the node being resized
  /// * [handle] - The resize handle being dragged
  void startResize(String nodeId, ResizeHandle handle) {
    runInAction(() {
      resizingNodeId.value = nodeId;
      resizeHandle.value = handle;
      canvasLocked.value = true;
      setCursorOverride(handle.cursor);
    });
  }

  /// Ends the current resize operation.
  ///
  /// Clears resize state and unlocks the canvas.
  void endResize() {
    runInAction(() {
      resizingNodeId.value = null;
      resizeHandle.value = null;
      canvasLocked.value = false;
      setCursorOverride(null);
    });
  }
}
