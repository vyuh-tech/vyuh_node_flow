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
