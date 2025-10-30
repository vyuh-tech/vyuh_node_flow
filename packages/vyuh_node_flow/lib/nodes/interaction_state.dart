import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../connections/temporary_connection.dart';

/// Contains all interaction-related state for the node flow editor
/// Encapsulates drag operations, connection creation, selection, and UI state
class InteractionState {
  // Drag and pointer state
  final Observable<String?> draggedNodeId = Observable<String?>(null);
  final Observable<Offset?> lastPointerPosition = Observable<Offset?>(null);

  // Connection interaction state
  final Observable<TemporaryConnection?> temporaryConnection =
      Observable<TemporaryConnection?>(null);

  // Selection rectangle state
  final Observable<Offset?> selectionStartPoint = Observable<Offset?>(null);
  final Observable<Rect?> selectionRectangle = Observable<Rect?>(null);

  // Track previously intersecting nodes to prevent flickering during toggle
  Set<String> _previouslyIntersecting = <String>{};

  // UI state
  final Observable<MouseCursor> currentCursor = Observable(
    SystemMouseCursors.basic,
  );
  final Observable<bool> panEnabled = Observable(true);

  // Public getters
  String? get currentDraggedNodeId => draggedNodeId.value;

  Offset? get currentPointerPosition => lastPointerPosition.value;

  bool get isCreatingConnection => temporaryConnection.value != null;

  String? get connectionSourceNodeId => temporaryConnection.value?.sourceNodeId;

  String? get connectionSourcePortId => temporaryConnection.value?.sourcePortId;

  // Computed: isDrawingSelection is true when we have a selection rectangle
  bool get isDrawingSelection => selectionRectangle.value != null;

  Offset? get selectionStart => selectionStartPoint.value;

  MouseCursor get cursor => currentCursor.value;

  bool get isPanEnabled => panEnabled.value;

  // State modification methods
  void setDraggedNode(String? nodeId) {
    runInAction(() {
      draggedNodeId.value = nodeId;
    });
  }

  void setPointerPosition(Offset? position) {
    runInAction(() {
      lastPointerPosition.value = position;
    });
  }

  void update({
    MouseCursor? cursor,
    bool? panEnabled,
    TemporaryConnection? temporaryConnection,
  }) {
    runInAction(() {
      if (cursor != null) currentCursor.value = cursor;
      if (panEnabled != null) this.panEnabled.value = panEnabled;
      if (temporaryConnection != null) {
        this.temporaryConnection.value = temporaryConnection;
      }
    });
  }

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

  void finishSelection() {
    runInAction(() {
      selectionStartPoint.value = null;
      selectionRectangle.value = null;
      _previouslyIntersecting.clear();
    });
  }

  void cancelConnection() {
    runInAction(() {
      temporaryConnection.value = null;
    });
  }

  void resetState() {
    runInAction(() {
      draggedNodeId.value = null;
      lastPointerPosition.value = null;
      temporaryConnection.value = null;
      selectionStartPoint.value = null;
      selectionRectangle.value = null;
      currentCursor.value = SystemMouseCursors.basic;
      panEnabled.value = true;
    });
  }
}
