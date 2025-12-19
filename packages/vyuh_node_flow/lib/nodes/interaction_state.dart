import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';

import '../connections/temporary_connection.dart';

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

  /// Observable position of the last pointer event.
  ///
  /// Used for tracking cursor movement during interactions.
  final Observable<Offset?> lastPointerPosition = Observable<Offset?>(null);

  /// Observable temporary connection being created.
  ///
  /// Non-null when the user is dragging from a port to create a connection.
  final Observable<TemporaryConnection?> temporaryConnection =
      Observable<TemporaryConnection?>(null);

  /// Observable starting point of a selection rectangle.
  ///
  /// Non-null when the user has initiated a drag selection.
  final Observable<Offset?> selectionStartPoint = Observable<Offset?>(null);

  /// Observable selection rectangle bounds.
  ///
  /// Non-null during active selection drag operations.
  final Observable<Rect?> selectionRectangle = Observable<Rect?>(null);

  /// Tracks nodes that were previously intersecting the selection rectangle.
  ///
  /// Used to prevent flickering during toggle selection mode.
  Set<String> _previouslyIntersecting = <String>{};

  /// Observable flag for whether panning is enabled.
  ///
  /// When false, pan gestures are disabled (e.g., during node dragging).
  final Observable<bool> panEnabled = Observable(true);

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

  /// Gets the current pointer position.
  ///
  /// Returns null if no pointer position has been recorded.
  Offset? get currentPointerPosition => lastPointerPosition.value;

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
  bool get isDrawingSelection => selectionRectangle.value != null;

  /// Gets the starting point of the selection rectangle.
  ///
  /// Returns null if no selection is active.
  Offset? get selectionStart => selectionStartPoint.value;

  /// Gets whether panning is enabled.
  ///
  /// Returns false during interactions that should disable panning.
  bool get isPanEnabled => panEnabled.value;

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

  /// Sets the currently dragged node.
  ///
  /// Parameters:
  /// * [nodeId] - The ID of the node being dragged, or null to clear
  void setDraggedNode(String? nodeId) {
    runInAction(() {
      draggedNodeId.value = nodeId;
    });
  }

  /// Sets the current pointer position.
  ///
  /// Parameters:
  /// * [position] - The current pointer position, or null to clear
  void setPointerPosition(Offset? position) {
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
  /// * [panEnabled] - Whether panning should be enabled
  /// * [temporaryConnection] - New temporary connection state
  void update({bool? panEnabled, TemporaryConnection? temporaryConnection}) {
    runInAction(() {
      if (panEnabled != null) this.panEnabled.value = panEnabled;
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
  /// * [startPoint] - Starting point of the selection rectangle
  /// * [rectangle] - Current bounds of the selection rectangle
  /// * [intersectingNodes] - List of node IDs that intersect the rectangle
  /// * [toggle] - Whether to toggle selection instead of replacing
  /// * [selectNodes] - Callback to select/deselect nodes
  void updateSelection({
    Offset? startPoint,
    Rect? rectangle,
    List<String>? intersectingNodes,
    bool? toggle,
    Function(List<String>, {bool toggle})? selectNodes,
  }) {
    runInAction(() {
      if (startPoint != null) {
        selectionStartPoint.value = startPoint;
      }
      if (rectangle != null) {
        selectionRectangle.value = rectangle;
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
      selectionStartPoint.value = null;
      selectionRectangle.value = null;
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
  /// Clears all ongoing interactions and resets the pan state.
  /// This is useful when canceling all interactions or resetting the editor.
  /// Note: Cursor is derived from state, so clearing state automatically resets cursor.
  void resetState() {
    runInAction(() {
      draggedNodeId.value = null;
      lastPointerPosition.value = null;
      temporaryConnection.value = null;
      selectionStartPoint.value = null;
      selectionRectangle.value = null;
      panEnabled.value = true;
      isViewportInteracting.value = false;
      hoveringConnection.value = false;
      cursorOverride.value = null;
      selectionStarted.value = false;
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
}
