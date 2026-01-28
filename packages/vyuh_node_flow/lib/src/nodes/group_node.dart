import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '../editor/themes/node_flow_theme.dart';
import '../ports/port.dart';
import 'mixins/groupable_mixin.dart';
import 'mixins/resizable_mixin.dart';
import 'node.dart';

/// Default padding for group nodes.
///
/// Provides space around member nodes: 40 top (for title), 20 on sides and bottom.
const kGroupNodeDefaultPadding = EdgeInsets.fromLTRB(20, 40, 20, 20);

/// How a group determines its member nodes and sizing behavior.
enum GroupBehavior {
  /// Spatial containment - nodes inside bounds move with group.
  ///
  /// - Membership: Computed from spatial bounds at drag time
  /// - Size: Manual (resizable)
  /// - Nodes can escape by dragging out of bounds
  bounds,

  /// Explicit membership - group auto-fits to contain member nodes.
  ///
  /// - Membership: Explicit node ID set via [GroupNode.nodeIds]
  /// - Size: Auto-computed (bounding box of members + padding)
  /// - Nodes always visually inside (group resizes to fit)
  /// - Not resizable (size is computed)
  explicit,

  /// Parent-child link - nodes linked but free to move independently.
  ///
  /// - Membership: Explicit node ID set via [GroupNode.nodeIds]
  /// - Size: Manual (resizable)
  /// - Nodes move WITH group when group is dragged
  /// - Nodes can be dragged outside group bounds
  parent,
}

/// Callback type for looking up nodes by ID.
///
/// Used by group nodes that need to access node data during lifecycle
/// operations like fitting bounds or responding to node changes.
typedef NodeLookup = Node? Function(String nodeId);

/// A group node that creates a region for containing other nodes.
///
/// Group nodes create visual boundaries that can contain nodes. The
/// membership and sizing behavior is determined by [behavior]:
///
/// - [GroupBehavior.bounds]: Spatial containment - nodes inside bounds move
///   with group. Group is manually resizable. Nodes can escape by dragging out.
///
/// - [GroupBehavior.explicit]: Explicit membership - nodes are specified by ID.
///   Group auto-sizes to fit member nodes + padding. Not resizable.
///
/// - [GroupBehavior.parent]: Parent-child link - nodes specified by ID move
///   with group when dragged. Group is manually resizable. Nodes can be
///   positioned outside group bounds.
///
/// ## Optional Ports for Subflow Patterns
///
/// Group nodes can optionally have input/output ports, enabling them to act
/// as subflow containers where the group itself can be connected to other nodes.
///
/// ## Features
///
/// - Manual resizing from 8 handle positions (except for `explicit` behavior)
/// - Customizable title and color
/// - When moved, automatically moves contained/linked nodes
/// - Typically rendered behind nodes (background layer)
///
/// ## Example
///
/// ```dart
/// // Bounds behavior (default) - spatial containment
/// final regionGroup = GroupNode<String>(
///   id: 'region-1',
///   position: Offset(100, 100),
///   size: Size(400, 300),
///   title: 'Processing Region',
///   data: 'group-data',
/// );
///
/// // Explicit behavior - auto-sized to fit members
/// final explicitGroup = GroupNode<String>(
///   id: 'explicit-1',
///   position: Offset.zero, // Will be computed
///   size: Size.zero,       // Will be computed
///   title: 'Data Pipeline',
///   data: 'pipeline-data',
///   behavior: GroupBehavior.explicit,
///   nodeIds: {'node-1', 'node-2', 'node-3'},
/// );
/// explicitGroup.fitToNodes((id) => controller.nodes[id]);
///
/// // Group with ports for subflow connections
/// final subflowGroup = GroupNode<String>(
///   id: 'subflow-1',
///   position: Offset(50, 50),
///   size: Size(500, 400),
///   title: 'Subflow',
///   data: 'subflow-data',
///   ports: [
///     Port(id: 'in-1', name: 'Input', type: PortType.input, position: PortPosition.left),
///     Port(id: 'out-1', name: 'Output', type: PortType.output, position: PortPosition.right),
///   ],
/// );
/// ```
class GroupNode<T> extends Node<T> with ResizableMixin<T>, GroupableMixin<T> {
  GroupNode({
    required super.id,
    required super.position,
    required Size super.size,
    required String title,
    required super.data,
    Color color = Colors.blue,
    GroupBehavior behavior = GroupBehavior.bounds,
    Set<String>? nodeIds,
    this.padding = kGroupNodeDefaultPadding,
    int zIndex = -1, // Usually behind nodes
    bool isVisible = true,
    super.locked,
    // Optional ports for subflow patterns
    super.ports,
    // Custom widget builder for subclass rendering (e.g., LoopNode)
    super.widgetBuilder,
    // Override default auto-delete behavior when group becomes empty
    bool preserveWhenEmpty = false,
  }) : _nodeIds = ObservableSet.of(nodeIds ?? {}),
       _observableBehavior = Observable(behavior),
       _observableTitle = Observable(title),
       _observableColor = Observable(color),
       _preserveWhenEmpty = preserveWhenEmpty,
       super(
         type: 'group',
         layer: NodeRenderLayer.background,
         initialZIndex: zIndex,
         visible: isVisible,
         selectable: true,
       );

  /// Whether to preserve this group when it becomes empty.
  ///
  /// By default, groups with [GroupBehavior.explicit] are auto-deleted when
  /// all member nodes are removed. Set this to `true` to prevent auto-deletion.
  /// Useful for loop containers that should persist even without body nodes.
  final bool _preserveWhenEmpty;

  final Observable<String> _observableTitle;
  final Observable<Color> _observableColor;
  final Observable<GroupBehavior> _observableBehavior;

  /// Reactive observable for the group's behavior.
  ///
  /// When behavior changes, the controller automatically
  /// sets up or disposes node monitoring reactions as needed.
  Observable<GroupBehavior> get observableBehavior => _observableBehavior;

  /// The behavior that determines how this group manages node membership.
  GroupBehavior get behavior => _observableBehavior.value;

  /// Explicit node IDs for [GroupBehavior.explicit] and [GroupBehavior.parent].
  ///
  /// For [GroupBehavior.bounds], this is ignored - membership is computed
  /// spatially at drag time.
  final ObservableSet<String> _nodeIds;

  /// Padding around member nodes when computing bounds for [GroupBehavior.explicit].
  ///
  /// For other behaviors, this is informational only.
  final EdgeInsets padding;

  // Cached set of contained node IDs during drag operations.
  // Captured at drag start and used throughout the drag to ensure
  // consistent behavior (nodes don't get added/removed mid-drag).
  Set<String>? _containedNodeIds;

  /// Reactive observable for the group's size.
  ///
  /// This is the same as Node's size observable.
  Observable<Size> get observableSize => size;

  /// Reactive observable for the group's title.
  ///
  /// The title is displayed in the group's header bar and updates automatically
  /// when changed via [updateTitle].
  Observable<String> get observableTitle => _observableTitle;

  /// Reactive observable for the group's color.
  ///
  /// The color affects the group's header bar and background tint.
  Observable<Color> get observableColor => _observableColor;

  /// The current title value (non-reactive).
  ///
  /// For reactive access, use [observableTitle] instead.
  String get currentTitle => _observableTitle.value;

  /// The current color value (non-reactive).
  ///
  /// For reactive access, use [observableColor] instead.
  Color get currentColor => _observableColor.value;

  /// The set of explicitly linked node IDs.
  ///
  /// Only meaningful for [GroupBehavior.explicit] and [GroupBehavior.parent].
  /// For [GroupBehavior.bounds], this set is ignored.
  Set<String> get nodeIds => Set.unmodifiable(_nodeIds);

  /// Whether this group can be manually resized.
  ///
  /// Returns `false` for [GroupBehavior.explicit] since size is auto-computed.
  @override
  bool get isResizable => behavior != GroupBehavior.explicit;

  /// Adds a node to the explicit membership.
  ///
  /// Only valid for [GroupBehavior.explicit] and [GroupBehavior.parent].
  /// For [GroupBehavior.bounds], use spatial containment instead.
  ///
  /// If the added node is a [GroupNode], its z-index is automatically
  /// bumped to ensure it renders above this parent group.
  void addNode(String nodeId) {
    assert(
      behavior != GroupBehavior.bounds,
      'Cannot add nodes to bounds behavior - use spatial containment',
    );
    runInAction(() {
      _nodeIds.add(nodeId);

      // Ensure nested groups have higher z-index than this parent
      if (groupContext != null) {
        final childNode = groupContext!.getNode(nodeId);
        if (childNode is GroupNode<T> &&
            childNode.zIndex.value <= zIndex.value) {
          childNode.zIndex.value = zIndex.value + 1;
        }
      }
    });
  }

  /// Removes a node from the explicit membership.
  ///
  /// Works for all behaviors, but only meaningful for explicit/parent.
  void removeNode(String nodeId) {
    runInAction(() => _nodeIds.remove(nodeId));
  }

  /// Clears all explicitly linked nodes.
  void clearNodes() {
    runInAction(() => _nodeIds.clear());
  }

  /// Changes the group's behavior.
  ///
  /// When switching behaviors:
  /// - **bounds -> explicit/parent**: If [captureContainedNodes] is provided,
  ///   those nodes are added to [nodeIds]. For explicit, [fitToNodes] is called.
  /// - **explicit/parent -> bounds**: [nodeIds] is optionally cleared based on
  ///   [clearNodesOnBoundsSwitch].
  /// - **explicit <-> parent**: [nodeIds] is preserved.
  ///
  /// The controller automatically updates node monitoring reactions
  /// when behavior changes.
  void setBehavior(
    GroupBehavior newBehavior, {
    Set<String>? captureContainedNodes,
    NodeLookup? nodeLookup,
    bool clearNodesOnBoundsSwitch = true,
  }) {
    if (behavior == newBehavior) return;

    final oldBehavior = behavior;

    runInAction(() {
      // Handle transition from bounds to explicit/parent
      if (oldBehavior == GroupBehavior.bounds &&
          newBehavior != GroupBehavior.bounds) {
        // Capture contained nodes if provided
        if (captureContainedNodes != null && captureContainedNodes.isNotEmpty) {
          _nodeIds.addAll(captureContainedNodes);
        }
      }

      // Handle transition to bounds - optionally clear nodeIds
      if (newBehavior == GroupBehavior.bounds && clearNodesOnBoundsSwitch) {
        _nodeIds.clear();
      }

      // Update behavior
      _observableBehavior.value = newBehavior;

      // For explicit behavior, fit to nodes if we have any and a lookup
      if (newBehavior == GroupBehavior.explicit &&
          _nodeIds.isNotEmpty &&
          nodeLookup != null) {
        fitToNodes(nodeLookup);
      }
    });
  }

  @override
  void onChildrenDeleted(Set<String> nodeIds) {
    final removed = _nodeIds.intersection(nodeIds);
    if (removed.isEmpty) return;
    runInAction(() => _nodeIds.removeAll(removed));

    // For explicit behavior, refit to remaining nodes
    if (behavior == GroupBehavior.explicit &&
        _nodeIds.isNotEmpty &&
        groupContext != null) {
      fitToNodes(groupContext!.getNode);
    }
  }

  @override
  bool get isGroupable => behavior != GroupBehavior.bounds;

  @override
  Set<String> get groupedNodeIds =>
      behavior != GroupBehavior.bounds ? _nodeIds.toSet() : const {};

  @override
  bool get isEmpty => behavior != GroupBehavior.bounds && _nodeIds.isEmpty;

  @override
  bool get shouldRemoveWhenEmpty =>
      behavior == GroupBehavior.explicit && !_preserveWhenEmpty;

  @override
  void onChildMoved(String nodeId, Offset newPosition) {
    // Only explicit behavior auto-resizes when member nodes move
    if (behavior != GroupBehavior.explicit) return;
    if (!_nodeIds.contains(nodeId)) return;
    if (groupContext == null) return;

    // Refit to contain all member nodes
    fitToNodes(groupContext!.getNode);
  }

  @override
  void onChildResized(String nodeId, Size newSize) {
    // Only explicit behavior auto-resizes when member nodes resize
    if (behavior != GroupBehavior.explicit) return;
    if (!_nodeIds.contains(nodeId)) return;
    if (groupContext == null) return;

    // Refit to contain all member nodes
    fitToNodes(groupContext!.getNode);
  }

  /// Checks if a node is an explicit member of this group.
  ///
  /// For [GroupBehavior.bounds], always returns `false` since membership
  /// is determined spatially, not by ID.
  bool hasNode(String nodeId) => _nodeIds.contains(nodeId);

  /// The current size of the group.
  Size get currentSize => size.value;

  /// Sets the group's size directly.
  ///
  /// This is called during resize operations. The size is constrained to
  /// minimum dimensions to ensure the group remains usable.
  @override
  void setSize(Size newSize) {
    // Enforce minimum size
    const minWidth = 100.0;
    const minHeight = 60.0;
    final constrainedSize = Size(
      newSize.width.clamp(minWidth, double.infinity),
      newSize.height.clamp(minHeight, double.infinity),
    );
    super.setSize(constrainedSize);
  }

  @override
  Size get minSize => const Size(100, 60);

  /// Updates the group's title.
  ///
  /// The title appears in the group's header bar and is automatically saved
  /// when serializing the workflow.
  void updateTitle(String newTitle) {
    runInAction(() {
      _observableTitle.value = newTitle;
    });
  }

  /// Updates the group's color.
  ///
  /// The color affects both the header bar (solid) and background (translucent).
  void updateColor(Color newColor) {
    runInAction(() {
      _observableColor.value = newColor;
    });
  }

  /// Recomputes the group's position and size to fit all member nodes.
  ///
  /// Only meaningful for [GroupBehavior.explicit]. For other behaviors,
  /// this method does nothing.
  ///
  /// The [lookup] function is used to retrieve node objects by ID.
  /// Nodes that cannot be found are ignored.
  ///
  /// The resulting bounds will be the bounding box of all member nodes
  /// plus [padding] on each side.
  void fitToNodes(NodeLookup lookup) {
    if (behavior != GroupBehavior.explicit) return;
    if (_nodeIds.isEmpty) return;

    final nodeBounds = _computeNodeBounds(lookup);
    if (nodeBounds == null) return;

    runInAction(() {
      final newPos = Offset(
        nodeBounds.left - padding.left,
        nodeBounds.top - padding.top,
      );
      position.value = newPos;
      visualPosition.value = newPos;
      setSize(
        Size(
          nodeBounds.width + padding.horizontal,
          nodeBounds.height + padding.vertical,
        ),
      );
    });
  }

  /// Computes the bounding box of all member nodes.
  ///
  /// Returns `null` if no valid nodes are found.
  Rect? _computeNodeBounds(NodeLookup lookup) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    var foundAny = false;

    for (final nodeId in _nodeIds) {
      final node = lookup(nodeId);
      if (node == null) continue;

      foundAny = true;
      final b = node.getBounds();
      minX = min(minX, b.left);
      minY = min(minY, b.top);
      maxX = max(maxX, b.right);
      maxY = max(maxY, b.bottom);
    }

    if (!foundAny) return null;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Gets the bounding rectangle for the group in graph coordinates.
  Rect get bounds => Rect.fromLTWH(
    visualPosition.value.dx,
    visualPosition.value.dy,
    size.value.width,
    size.value.height,
  );

  /// Checks if a given rectangle is completely contained within this group.
  ///
  /// Used for determining if a node is part of the group.
  bool containsRect(Rect rect) {
    final groupBounds = bounds;
    return groupBounds.contains(rect.topLeft) &&
        groupBounds.contains(rect.bottomRight);
  }

  @override
  Widget? buildWidget(BuildContext context) {
    // Respect instance-level widgetBuilder first
    if (widgetBuilder != null) {
      return widgetBuilder!(context, this);
    }
    // GroupNode is self-rendering with its own styled content
    return _GroupContent<T>(node: this);
  }

  @override
  void paintThumbnail(
    Canvas canvas,
    Rect bounds, {
    required Color color,
    required bool isSelected,
    Color? selectedBorderColor,
    double borderRadius = 4.0,
  }) {
    // Use the group's own color with 15% opacity for subtle appearance
    final groupColor = currentColor.withValues(alpha: 0.15);
    final rrect = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = groupColor;
    canvas.drawRRect(rrect, paint);
  }

  @override
  void paintMinimapThumbnail(
    Canvas canvas,
    Rect bounds, {
    required Color defaultColor,
    double borderRadius = 2.0,
  }) {
    // Use the group's own color with 15% opacity for subtle appearance
    final groupColor = currentColor.withValues(alpha: 0.15);
    final rrect = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = groupColor;
    canvas.drawRRect(rrect, paint);
  }

  /// Creates a copy of this group node with optional property overrides.
  ///
  /// This is useful for creating variations of an existing group or
  /// for implementing undo/redo functionality.
  GroupNode<T> copyWith({
    String? id,
    Offset? position,
    Size? size,
    String? title,
    T? data,
    Color? color,
    GroupBehavior? behavior,
    Set<String>? nodeIds,
    EdgeInsets? padding,
    int? zIndex,
    bool? isVisible,
    bool? locked,
    List<Port>? ports,
    NodeWidgetBuilder<T>? widgetBuilder,
  }) {
    return GroupNode<T>(
      id: id ?? this.id,
      position: position ?? this.position.value,
      size: size ?? this.size.value,
      title: title ?? currentTitle,
      data: data ?? this.data,
      color: color ?? currentColor,
      behavior: behavior ?? this.behavior,
      nodeIds: nodeIds ?? Set.from(_nodeIds),
      padding: padding ?? this.padding,
      zIndex: zIndex ?? this.zIndex.value,
      isVisible: isVisible ?? this.isVisible,
      locked: locked ?? this.locked,
      ports: ports ?? this.ports.toList(),
      widgetBuilder: widgetBuilder ?? this.widgetBuilder,
    );
  }

  /// Creates a [GroupNode] from a JSON map.
  ///
  /// This factory constructor is used during workflow deserialization to recreate
  /// group nodes from saved data.
  ///
  /// Parameters:
  /// * [json] - The JSON map containing node data
  /// * [dataFromJson] - Function to deserialize the custom data of type [T]
  factory GroupNode.fromJson(
    Map<String, dynamic> json, {
    required T Function(Object? json) dataFromJson,
  }) {
    // Parse padding from JSON (stored as LTRB array or object)
    EdgeInsets padding = kGroupNodeDefaultPadding;
    final paddingJson = json['padding'];
    if (paddingJson != null) {
      if (paddingJson is List) {
        padding = EdgeInsets.fromLTRB(
          (paddingJson[0] as num).toDouble(),
          (paddingJson[1] as num).toDouble(),
          (paddingJson[2] as num).toDouble(),
          (paddingJson[3] as num).toDouble(),
        );
      } else if (paddingJson is Map) {
        padding = EdgeInsets.fromLTRB(
          (paddingJson['left'] as num?)?.toDouble() ?? 0,
          (paddingJson['top'] as num?)?.toDouble() ?? 0,
          (paddingJson['right'] as num?)?.toDouble() ?? 0,
          (paddingJson['bottom'] as num?)?.toDouble() ?? 0,
        );
      }
    }

    // Parse ports from single ports array
    final parsedPorts =
        (json['ports'] as List<dynamic>?)
            ?.map((e) => Port.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const <Port>[];

    return GroupNode<T>(
      id: json['id'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      size: Size(
        (json['width'] as num?)?.toDouble() ?? 200.0,
        (json['height'] as num?)?.toDouble() ?? 150.0,
      ),
      title: json['title'] as String? ?? '',
      data: dataFromJson(json['data']),
      color: Color(json['color'] as int? ?? Colors.blue.toARGB32()),
      behavior: GroupBehavior.values.byName(
        json['behavior'] as String? ?? 'bounds',
      ),
      nodeIds: (json['nodeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet(),
      padding: padding,
      zIndex: json['zIndex'] as int? ?? -1,
      isVisible: json['isVisible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      ports: parsedPorts,
    );
  }

  /// Converts this group node to a JSON map.
  @override
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
    ...super.toJson(toJsonT),
    'title': currentTitle,
    'color': currentColor.toARGB32(),
    'behavior': behavior.name,
    'nodeIds': _nodeIds.toList(),
    'padding': [padding.left, padding.top, padding.right, padding.bottom],
  };

  // ============================================================
  // Drag Lifecycle - Move contained nodes with the group
  // ============================================================

  @override
  void onDragStart(NodeDragContext context) {
    // Capture nodes to move based on behavior
    _containedNodeIds = switch (behavior) {
      // Spatial containment - find nodes inside bounds
      GroupBehavior.bounds => context.findNodesInBounds(bounds),
      // Explicit membership - use the explicit node ID set
      GroupBehavior.explicit => Set.from(_nodeIds),
      // Parent-child link - use the explicit node ID set
      GroupBehavior.parent => Set.from(_nodeIds),
    };

    // Ensure child groups have higher z-index than this parent group
    // so they render on top and remain clickable
    _ensureChildGroupsAbove(context);
  }

  /// Called when the context is attached (on add to graph or load).
  ///
  /// For explicit/parent behaviors, this ensures:
  /// 1. Child groups have correct z-indices (above this parent)
  /// 2. Group is properly sized/positioned to fit all children with padding
  @override
  void onContextAttached() {
    super.onContextAttached();

    // For explicit/parent behaviors, fix z-indices and fit to children
    if (behavior != GroupBehavior.bounds && _nodeIds.isNotEmpty) {
      _ensureExplicitChildGroupsAbove();
      // Fit to nodes to ensure proper padding around all children
      if (groupContext != null) {
        fitToNodes(groupContext!.getNode);
      }
    }
  }

  /// Ensures explicitly added child GroupNodes have higher z-index.
  void _ensureExplicitChildGroupsAbove() {
    if (groupContext == null) return;

    final myZIndex = zIndex.value;

    runInAction(() {
      for (final childId in _nodeIds) {
        final childNode = groupContext!.getNode(childId);
        if (childNode is GroupNode<T> && childNode.zIndex.value <= myZIndex) {
          childNode.zIndex.value = myZIndex + 1;
        }
      }
    });
  }

  /// Ensures any child GroupNodes have a higher z-index than this group.
  ///
  /// This maintains proper rendering order so nested groups are always
  /// above their parent and remain selectable/clickable.
  void _ensureChildGroupsAbove(NodeDragContext context) {
    if (_containedNodeIds == null || _containedNodeIds!.isEmpty) return;

    final myZIndex = zIndex.value;

    runInAction(() {
      for (final childId in _containedNodeIds!) {
        final childNode = context.getNode(childId);
        if (childNode is GroupNode && childNode.zIndex.value <= myZIndex) {
          // Bump child group's z-index to be above this parent
          childNode.zIndex.value = myZIndex + 1;
        }
      }
    });
  }

  @override
  void onDragMove(Offset delta, NodeDragContext context) {
    // Move all contained nodes along with this group,
    // excluding nodes that are already selected (they're being moved by selection drag)
    if (_containedNodeIds != null && _containedNodeIds!.isNotEmpty) {
      final nodesToMove = _containedNodeIds!.difference(
        context.selectedNodeIds,
      );
      if (nodesToMove.isNotEmpty) {
        context.moveNodes(nodesToMove, delta);
      }
    }
  }

  @override
  void onDragEnd() {
    // Clear the cached contained nodes
    _containedNodeIds = null;
  }
}

/// Internal widget for rendering group content with inline title editing.
class _GroupContent<T> extends StatefulWidget {
  const _GroupContent({super.key, required this.node});

  final GroupNode<T> node;

  @override
  State<_GroupContent<T>> createState() => _GroupContentState<T>();
}

class _GroupContentState<T> extends State<_GroupContent<T>> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  ReactionDisposer? _editingReaction;

  /// Stores the original title when editing starts, for cancel/restore.
  String _originalTitle = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.node.currentTitle);
    _focusNode = FocusNode();

    // React to editing state changes to auto-focus
    _editingReaction = reaction((_) => widget.node.isEditing, (bool isEditing) {
      if (isEditing) {
        // Store original title for potential cancel
        _originalTitle = widget.node.currentTitle;
        // Update text controller with current title
        _textController.text = _originalTitle;
        // Auto-focus when editing starts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.requestFocus();
            // Select all text for easy replacement
            _textController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _textController.text.length,
            );
          }
        });
      }
    }, fireImmediately: true);

    // Handle focus loss to end editing
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.node.isEditing) {
      _commitEdit();
    }
  }

  void _commitEdit() {
    widget.node.updateTitle(_textController.text);
    widget.node.isEditing = false;
  }

  /// Cancels the edit and restores the original title.
  void _cancelEdit() {
    _textController.text = _originalTitle;
    widget.node.isEditing = false;
  }

  @override
  void dispose() {
    _editingReaction?.call();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get themes for consistent styling
    final flowTheme = Theme.of(context).extension<NodeFlowTheme>();
    assert(flowTheme != null, 'NodeFlowTheme must be provided in the context');

    final nodeTheme = flowTheme!.nodeTheme;
    final borderRadius = nodeTheme.borderRadius;
    final innerRadius = Radius.circular(
      borderRadius.topLeft.x - nodeTheme.borderWidth,
    );

    return Observer(
      builder: (_) {
        // Observe all reactive properties including size, editing, and selection state
        final title = widget.node.currentTitle;
        final color = widget.node.currentColor;
        final currentSize = widget.node.observableSize.value;
        final isEditing = widget.node.isEditing;
        final isSelected = widget.node.isSelected;

        return Container(
          width: currentSize.width,
          height: currentSize.height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: borderRadius,
            border: Border.all(
              color: isSelected
                  ? nodeTheme.selectedBorderColor
                  : Colors.transparent,
              width: nodeTheme.selectedBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.only(
                    topLeft: innerRadius,
                    topRight: innerRadius,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: isEditing
                    ? Focus(
                        // Capture Escape key before TextField processes it
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.escape) {
                            _cancelEdit();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          style: nodeTheme.titleStyle,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _commitEdit(),
                        ),
                      )
                    : Text(
                        title.isNotEmpty ? title : 'Group',
                        style: nodeTheme.titleStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              Expanded(child: Container()), // Empty space for nodes
            ],
          ),
        );
      },
    );
  }
}
