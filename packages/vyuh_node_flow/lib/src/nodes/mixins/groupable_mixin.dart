import 'dart:ui';

import 'package:mobx/mobx.dart';

import '../node.dart';

/// Mixin for nodes that can group/contain other nodes.
///
/// This mixin provides lifecycle management for groupable nodes, including:
/// - Context attachment when added to the graph
/// - Automatic MobX reaction setup for monitoring child nodes
/// - Context detachment and cleanup when removed
///
/// ## Usage
///
/// ```dart
/// class GroupNode<T> extends Node<T> with GroupableMixin<T> {
///   @override
///   bool get isGroupable => behavior != GroupBehavior.bounds;
///
///   @override
///   Set<String> get groupedNodeIds => _memberNodeIds;
///
///   @override
///   void onChildMoved(String nodeId, Offset newPosition) {
///     fitToNodes();
///   }
/// }
/// ```
mixin GroupableMixin<T> on Node<T> {
  // The context providing all controller functionality
  NodeDragContext<T>? _groupContext;

  // Disposers for MobX reactions
  final List<ReactionDisposer> _reactionDisposers = [];

  /// The current group context, if attached.
  ///
  /// Returns `null` if this node is not attached to a controller.
  NodeDragContext<T>? get groupContext => _groupContext;

  /// Whether this node has a group context attached.
  bool get hasContext => _groupContext != null;

  // ===========================================================================
  // Lifecycle Methods
  // ===========================================================================

  /// Attaches the group context when this node is added to the controller.
  ///
  /// This is called by the controller when adding the node to the graph.
  /// Sets up MobX reactions to monitor child nodes if [isGroupable] is true.
  void attachContext(NodeDragContext<T> context) {
    _groupContext = context;

    if (isGroupable) {
      _setupReactions();
    }

    onContextAttached();
  }

  /// Detaches the group context when this node is removed from the controller.
  ///
  /// This is called by the controller when removing the node from the graph.
  /// Disposes all MobX reactions and clears the context.
  void detachContext() {
    onContextDetaching();

    _disposeReactions();
    _groupContext = null;
  }

  /// Called after the context is attached.
  ///
  /// Override this to perform setup that requires the context.
  void onContextAttached() {
    // Default: no-op
  }

  /// Called before the context is detached.
  ///
  /// Override this to perform cleanup before the context is cleared.
  void onContextDetaching() {
    // Default: no-op
  }

  // ===========================================================================
  // Groupable Configuration
  // ===========================================================================

  /// Whether this node actively groups/monitors other nodes.
  ///
  /// When true, MobX reactions are set up to track [groupedNodeIds].
  /// Override in subclasses to control when grouping is active.
  ///
  /// Default is `false`.
  bool get isGroupable => false;

  /// The set of node IDs this node is currently grouping.
  ///
  /// Only relevant when [isGroupable] is true. These nodes will be
  /// monitored for position and size changes.
  Set<String> get groupedNodeIds => const {};

  // ===========================================================================
  // Child Node Callbacks
  // ===========================================================================

  /// Called when a child node is moved.
  ///
  /// Only called if [isGroupable] is true and the node is in [groupedNodeIds].
  void onChildMoved(String nodeId, Offset newPosition) {
    // Default: no-op
  }

  /// Called when a child node is resized.
  ///
  /// Only called if [isGroupable] is true and the node is in [groupedNodeIds].
  void onChildResized(String nodeId, Size newSize) {
    // Default: no-op
  }

  /// Called when child nodes are deleted from the graph.
  ///
  /// Receives all deleted node IDs, allowing the grouping node to update
  /// its internal state (e.g., remove them from membership).
  void onChildrenDeleted(Set<String> nodeIds) {
    // Default: no-op
  }

  // ===========================================================================
  // Additional Callbacks
  // ===========================================================================

  /// Called when a node is added to the graph.
  ///
  /// This can be used to detect when new nodes appear within bounds.
  void onNodeAdded(String nodeId, Rect nodeBounds) {
    // Default: no-op
  }

  /// Called when node selection changes.
  ///
  /// Receives the full set of currently selected node IDs.
  void onSelectionChanged(Set<String> selectedNodeIds) {
    // Default: no-op
  }

  // ===========================================================================
  // Auto-removal Support
  // ===========================================================================

  /// Whether this node should be removed when it becomes empty.
  ///
  /// Used by group-like nodes that should be auto-deleted when they
  /// have no members. Works in conjunction with [isEmpty].
  ///
  /// Default is `false`.
  bool get shouldRemoveWhenEmpty => false;

  /// Whether this node is considered empty.
  ///
  /// Used in conjunction with [shouldRemoveWhenEmpty] to determine
  /// if the node should be automatically deleted.
  ///
  /// Default is `false`.
  bool get isEmpty => false;

  // ===========================================================================
  // Internal Reaction Management
  // ===========================================================================

  void _setupReactions() {
    _disposeReactions(); // Clear any existing reactions

    final context = _groupContext;
    if (context == null) return;

    // Watch positions of grouped nodes
    final positionDisposer = reaction(
      (_) {
        final positions = <String, Offset>{};
        for (final nodeId in groupedNodeIds) {
          final node = context.getNode(nodeId);
          if (node != null) {
            positions[nodeId] = node.position.value;
          }
        }
        return positions;
      },
      (Map<String, Offset> positions) {
        if (context.shouldSkipUpdates?.call() ?? false) return;
        for (final entry in positions.entries) {
          onChildMoved(entry.key, entry.value);
        }
      },
    );
    _reactionDisposers.add(positionDisposer);

    // Watch sizes of grouped nodes
    final sizeDisposer = reaction(
      (_) {
        final sizes = <String, Size>{};
        for (final nodeId in groupedNodeIds) {
          final node = context.getNode(nodeId);
          if (node != null) {
            sizes[nodeId] = node.size.value;
          }
        }
        return sizes;
      },
      (Map<String, Size> sizes) {
        if (context.shouldSkipUpdates?.call() ?? false) return;
        for (final entry in sizes.entries) {
          onChildResized(entry.key, entry.value);
        }
      },
    );
    _reactionDisposers.add(sizeDisposer);

    // Watch for isGroupable changes to enable/disable reactions
    final groupableDisposer = reaction((_) => isGroupable, (bool groupable) {
      if (groupable) {
        // Re-setup reactions when groupable becomes true
        // (after the current reaction completes)
        Future.microtask(_setupReactions);
      } else {
        // Dispose monitoring reactions when groupable becomes false
        _disposeReactions();
      }
    });
    _reactionDisposers.add(groupableDisposer);
  }

  void _disposeReactions() {
    for (final disposer in _reactionDisposers) {
      disposer();
    }
    _reactionDisposers.clear();
  }
}
