import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';

import 'controller/node_flow_controller.dart';

/// Result of a snap position calculation.
///
/// Contains the snapped visual position and whether snapping is active
/// on each axis.
class SnapResult {
  const SnapResult({
    required this.position,
    this.snappingX = false,
    this.snappingY = false,
  });

  /// Creates a "no snapping" result - use the intended position as-is.
  const SnapResult.none(this.position) : snappingX = false, snappingY = false;

  /// The snapped visual position.
  final Offset position;

  /// Whether the X axis is actively snapping.
  final bool snappingX;

  /// Whether the Y axis is actively snapping.
  final bool snappingY;

  /// Whether any snapping is active.
  bool get isSnapping => snappingX || snappingY;

  /// Creates a copy with fields replaced.
  SnapResult copyWith({Offset? position, bool? snappingX, bool? snappingY}) {
    return SnapResult(
      position: position ?? this.position,
      snappingX: snappingX ?? this.snappingX,
      snappingY: snappingY ?? this.snappingY,
    );
  }
}

/// Interface for delegates that need controller access.
///
/// Implement this if your snap delegate needs to access the controller
/// (e.g., to iterate over nodes). The [SnapExtension] will call
/// [setController] during attach/detach.
abstract interface class ControllerAwareDelegate {
  /// Called when the extension is attached to a controller.
  void setController(NodeFlowController? controller);
}

/// Interface for snap delegates that can provide a visual layer.
///
/// Implement this if your snap delegate needs to render visual feedback
/// (e.g., alignment guides). The [SnapExtension] will delegate layer
/// building to the first delegate that implements this interface.
///
/// The layer is built by [SnapExtension] via the [LayerProvider] interface.
abstract interface class SnapLayerDelegate {
  /// Builds a layer widget for visual feedback during snapping.
  ///
  /// Return null if no layer should be rendered.
  Widget? buildSnapLayer(BuildContext context);
}

/// Delegate interface for snap-to behavior during node drag operations.
///
/// Implement this interface to provide custom snapping logic, such as
/// alignment guides, grid snapping, or magnetic snapping to other nodes.
///
/// ## Position Model
///
/// The snapping system uses two positions:
/// - **position**: The user's intended position (freeform, raw movement)
/// - **visualPosition**: The displayed position (snapped)
///
/// Snap delegates transform `position` → `visualPosition`. The delegate
/// receives the intended position and returns the snapped visual position.
///
/// ## Usage
///
/// ```dart
/// class MySnapDelegate implements SnapDelegate {
///   @override
///   SnapResult snapPosition({
///     required Set<String> draggedNodeIds,
///     required Offset intendedPosition,
///     required Rect visibleBounds,
///   }) {
///     // Calculate snapped position
///     final snapped = calculateSnap(intendedPosition);
///     return SnapResult(
///       position: snapped,
///       snappingX: snapped.dx != intendedPosition.dx,
///       snappingY: snapped.dy != intendedPosition.dy,
///     );
///   }
///
///   @override
///   void onDragStart(Set<String> nodeIds) {
///     // Prepare for snapping
///   }
///
///   @override
///   void onDragEnd() {
///     // Clean up snap state
///   }
/// }
/// ```
abstract interface class SnapDelegate {
  /// Called when a node drag operation starts.
  ///
  /// Use this to prepare snap calculations, such as caching candidate
  /// snap targets from visible nodes.
  ///
  /// [nodeIds] contains the IDs of all nodes being dragged.
  void onDragStart(Set<String> nodeIds);

  /// Calculate the snapped visual position from the intended position.
  ///
  /// This method is called on each drag update. Return a [SnapResult]
  /// containing the snapped position and which axes are actively snapping.
  ///
  /// Parameters:
  /// - [draggedNodeIds]: IDs of nodes being dragged
  /// - [intendedPosition]: Where the user wants the node (position.value)
  /// - [visibleBounds]: The currently visible area of the canvas
  ///
  /// Returns a [SnapResult] with the snapped position and snapping state.
  SnapResult snapPosition({
    required Set<String> draggedNodeIds,
    required Offset intendedPosition,
    required Rect visibleBounds,
  });

  /// Called when the drag operation ends.
  ///
  /// Clean up any cached state and hide snap indicators.
  void onDragEnd();
}

/// A snap delegate that snaps positions to a grid.
///
/// This is a pure delegate that snaps positions to a configurable grid.
/// It can be combined with other delegates using [SnapDelegateChain].
///
/// The parent [SnapExtension] controls when snapping is active via its
/// [enabled] property (toggled with the 'N' key). This delegate simply
/// performs the grid snap calculation when called.
///
/// ## Configuration
///
/// The [gridSize] is observable and can be changed at runtime:
///
/// ```dart
/// final gridSnap = GridSnapDelegate(gridSize: 20.0);
/// gridSnap.gridSize = 10.0;  // Change grid size dynamically
/// ```
class GridSnapDelegate implements SnapDelegate {
  GridSnapDelegate({double gridSize = 20.0}) : _gridSize = Observable(gridSize);

  final Observable<double> _gridSize;

  /// The grid size to snap to.
  double get gridSize => _gridSize.value;

  set gridSize(double value) => runInAction(() => _gridSize.value = value);

  /// Snaps a point to the grid.
  ///
  /// This is a general-purpose method for snapping any position to the grid,
  /// independent of drag operations. Use this for snapping positions when
  /// adding nodes, pasting, or other programmatic position updates.
  Offset snapPoint(Offset position) {
    if (gridSize <= 0) {
      return position;
    }

    final snappedX = (position.dx / gridSize).round() * gridSize;
    final snappedY = (position.dy / gridSize).round() * gridSize;
    return Offset(snappedX, snappedY);
  }

  @override
  void onDragStart(Set<String> nodeIds) {
    // No preparation needed for grid snap
  }

  @override
  SnapResult snapPosition({
    required Set<String> draggedNodeIds,
    required Offset intendedPosition,
    required Rect visibleBounds,
  }) {
    if (gridSize <= 0) {
      return SnapResult.none(intendedPosition);
    }

    // Snap intended position to grid
    final snappedX = (intendedPosition.dx / gridSize).round() * gridSize;
    final snappedY = (intendedPosition.dy / gridSize).round() * gridSize;

    return SnapResult(
      position: Offset(snappedX, snappedY),
      snappingX: true,
      snappingY: true,
    );
  }

  @override
  void onDragEnd() {
    // No cleanup needed for grid snap
  }
}

/// A delegate that chains multiple snap delegates together.
///
/// Delegates are tried in order. The first delegate that returns an
/// active snap on an axis "wins" that axis. If no delegate snaps an axis,
/// the intended position is used unchanged for that axis.
///
/// ## Usage
///
/// ```dart
/// final chain = SnapDelegateChain([
///   alignmentSnapDelegate,  // Try alignment first
///   gridSnapDelegate,       // Fall back to grid
/// ]);
/// controller.setSnapDelegate(chain);
/// ```
class SnapDelegateChain implements SnapDelegate {
  SnapDelegateChain(this.delegates);

  /// The delegates to chain, in priority order.
  final List<SnapDelegate> delegates;

  @override
  void onDragStart(Set<String> nodeIds) {
    for (final delegate in delegates) {
      delegate.onDragStart(nodeIds);
    }
  }

  @override
  SnapResult snapPosition({
    required Set<String> draggedNodeIds,
    required Offset intendedPosition,
    required Rect visibleBounds,
  }) {
    // Track whether we've found a snap for each axis
    var snappedX = false;
    var snappedY = false;
    var posX = intendedPosition.dx;
    var posY = intendedPosition.dy;

    for (final delegate in delegates) {
      // Skip if both axes are already snapped
      if (snappedX && snappedY) break;

      final result = delegate.snapPosition(
        draggedNodeIds: draggedNodeIds,
        intendedPosition: intendedPosition,
        visibleBounds: visibleBounds,
      );

      // Take X from first delegate that snaps X
      if (!snappedX && result.snappingX) {
        posX = result.position.dx;
        snappedX = true;
      }

      // Take Y from first delegate that snaps Y
      if (!snappedY && result.snappingY) {
        posY = result.position.dy;
        snappedY = true;
      }
    }

    return SnapResult(
      position: Offset(posX, posY),
      snappingX: snappedX,
      snappingY: snappedY,
    );
  }

  @override
  void onDragEnd() {
    for (final delegate in delegates) {
      delegate.onDragEnd();
    }
  }
}
