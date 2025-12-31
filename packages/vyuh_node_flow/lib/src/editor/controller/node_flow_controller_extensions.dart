part of '../node_flow_editor.dart';

/// Internal controller extension methods for widget implementation
/// These methods are not part of the public API
extension _NodeFlowControllerWidgetInternal<T, C> on NodeFlowController<T, C> {
  // Internal widget support methods - not part of public API
  // Note: Connection drag methods have been moved to the public API
  // (startConnectionDrag, updateConnectionDrag, completeConnectionDrag, cancelConnectionDrag)
  // and are now called directly by PortWidget's pan gesture handlers.

  /// Sets the pointer position in screen/widget-local coordinates.
  void _setPointerPosition(ScreenPosition? position) {
    interaction.setPointerPosition(position);
  }

  void _updateInteractionState({bool? canvasLocked}) {
    interaction.update(canvasLocked: canvasLocked);
  }

  /// Cleans up any stale interaction state from previous incomplete gestures.
  ///
  /// This handles edge cases where quick tap-pan sequences or widget rebuilds
  /// leave state in an inconsistent condition. Called at the start of new
  /// pointer interactions to ensure a clean starting state.
  ///
  /// Checks and cleans up ALL states that can block interactions:
  /// - Node drag state (draggedNodeId, node.dragging)
  /// - Node resize state
  /// - Connection creation state (temporaryConnection)
  /// - Selection rectangle state (selectionRect)
  void _cleanupStaleDragState() {
    // Clean up node drag state
    if (interaction.draggedNodeId.value != null) {
      endNodeDrag();
    }

    // Clean up any nodes with stale dragging flag (includes GroupNode and CommentNode)
    runInAction(() {
      for (final node in nodes.values) {
        if (node.dragging.value) {
          node.dragging.value = false;
        }
      }
    });

    // Clean up resize state (unified for all node types)
    if (isResizing) {
      endResize();
    }

    // Clean up connection creation state
    if (interaction.isCreatingConnection) {
      cancelConnectionDrag();
    }

    // Clean up selection rectangle state
    if (interaction.isDrawingSelection) {
      interaction.finishSelection();
    }

    // Force unlock canvas if it's still locked after cleanup
    if (interaction.isCanvasLocked) {
      runInAction(() {
        interaction.canvasLocked.value = false;
      });
    }
  }

  /// Updates selection drag state with graph coordinates.
  ///
  /// Parameters:
  /// * [startPoint] - Starting point of selection (graph coordinates)
  /// * [rectangle] - Current selection rectangle (graph coordinates)
  /// * [intersectingNodes] - List of node IDs that intersect the rectangle
  /// * [toggle] - Whether to toggle selection instead of replacing
  void _updateSelectionDrag({
    GraphPosition? startPoint,
    GraphRect? rectangle,
    List<String>? intersectingNodes,
    bool? toggle,
  }) {
    interaction.updateSelection(
      startPoint: startPoint,
      rectangle: rectangle,
      intersectingNodes: intersectingNodes,
      toggle: toggle,
      selectNodes: selectNodes,
    );
  }

  void _finishSelectionDrag() => interaction.finishSelection();
}
