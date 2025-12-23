part of 'node_flow_editor.dart';

/// Internal controller extension methods for widget implementation
/// These methods are not part of the public API
extension _NodeFlowControllerWidgetInternal<T> on NodeFlowController<T> {
  // Internal widget support methods - not part of public API
  // Note: Connection drag methods have been moved to the public API
  // (startConnectionDrag, updateConnectionDrag, completeConnectionDrag, cancelConnectionDrag)
  // and are now called directly by PortWidget's pan gesture handlers.

  /// Sets the pointer position in screen/widget-local coordinates.
  void _setPointerPosition(ScreenPosition? position) {
    interaction.setPointerPosition(position);
  }

  void _updateInteractionState({bool? panEnabled}) {
    interaction.update(panEnabled: panEnabled);
  }

  /// Cleans up any stale interaction state from previous incomplete gestures.
  ///
  /// This handles edge cases where quick tap-pan sequences or widget rebuilds
  /// leave state in an inconsistent condition. Called at the start of new
  /// pointer interactions to ensure a clean starting state.
  ///
  /// Checks and cleans up ALL states that can block interactions:
  /// - Node drag state (draggedNodeId, node.dragging)
  /// - Annotation drag state (draggedAnnotationId)
  /// - Annotation resize state (resizingAnnotationId)
  /// - Connection creation state (temporaryConnection)
  /// - Selection rectangle state (selectionRect)
  void _cleanupStaleDragState() {
    // Clean up node drag state
    if (interaction.draggedNodeId.value != null) {
      endNodeDrag();
    }

    // Clean up any nodes with stale dragging flag
    runInAction(() {
      for (final node in nodes.values) {
        if (node.dragging.value) {
          node.dragging.value = false;
        }
      }
    });

    // Clean up annotation drag state
    if (annotations.draggedAnnotationId != null) {
      endAnnotationDrag();
    }

    // Clean up annotation resize state
    if (annotations.isResizing) {
      annotations.endAnnotationResize();
    }

    // Clean up connection creation state
    if (interaction.isCreatingConnection) {
      cancelConnectionDrag();
    }

    // Clean up selection rectangle state
    if (interaction.isDrawingSelection) {
      interaction.finishSelection();
    }

    // Force re-enable pan if it's still disabled after cleanup
    if (!interaction.isPanEnabled) {
      runInAction(() {
        interaction.panEnabled.value = true;
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
