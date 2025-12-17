part of 'node_flow_editor.dart';

/// Internal controller extension methods for widget implementation
/// These methods are not part of the public API
extension _NodeFlowControllerWidgetInternal<T> on NodeFlowController<T> {
  // Internal widget support methods - not part of public API
  // Note: Connection drag methods have been moved to the public API
  // (startConnectionDrag, updateConnectionDrag, completeConnectionDrag, cancelConnectionDrag)
  // and are now called directly by PortWidget's pan gesture handlers.

  void _setPointerPosition(Offset? position) {
    interaction.setPointerPosition(position);
  }

  void _updateInteractionState({bool? panEnabled}) {
    interaction.update(panEnabled: panEnabled);
  }

  void _updateSelectionDrag({
    Offset? startPoint,
    Rect? rectangle,
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
