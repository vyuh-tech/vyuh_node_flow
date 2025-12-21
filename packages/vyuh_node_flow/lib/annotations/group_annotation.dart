import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '../graph/node_flow_theme.dart';
import 'annotation.dart';

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
  /// - Membership: Explicit node ID set via [GroupAnnotation.nodeIds]
  /// - Size: Auto-computed (bounding box of members + padding)
  /// - Nodes always visually inside (group resizes to fit)
  /// - Not resizable (size is computed)
  explicit,

  /// Parent-child link - nodes linked but free to move independently.
  ///
  /// - Membership: Explicit node ID set via [GroupAnnotation.nodeIds]
  /// - Size: Manual (resizable)
  /// - Nodes move WITH group when group is dragged
  /// - Nodes can be dragged outside group bounds
  parent,
}

/// A group annotation that creates a region for containing nodes.
///
/// Group annotations create visual boundaries that can contain nodes. The
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
/// ## Features
///
/// - Manual resizing from 8 handle positions (except for `explicit` behavior)
/// - Customizable title and color
/// - When moved, automatically moves contained/linked nodes
/// - Typically rendered behind nodes (negative z-index)
///
/// ## Example
///
/// ```dart
/// // Bounds behavior (default) - spatial containment
/// final regionGroup = GroupAnnotation(
///   id: 'region-1',
///   position: Offset(100, 100),
///   size: Size(400, 300),
///   title: 'Processing Region',
/// );
///
/// // Explicit behavior - auto-sized to fit members
/// final explicitGroup = GroupAnnotation(
///   id: 'explicit-1',
///   position: Offset.zero, // Will be computed
///   size: Size.zero,       // Will be computed
///   title: 'Data Pipeline',
///   behavior: GroupBehavior.explicit,
///   nodeIds: {'node-1', 'node-2', 'node-3'},
///   // Default padding: 40 top (for title), 20 sides and bottom
/// );
/// explicitGroup.fitToNodes((id) => controller.nodes[id]);
///
/// // Parent behavior - linked nodes, manual size
/// final parentGroup = GroupAnnotation(
///   id: 'parent-1',
///   position: Offset(50, 50),
///   size: Size(500, 400),
///   title: 'Workflow Stage',
///   behavior: GroupBehavior.parent,
///   nodeIds: {'node-a', 'node-b'},
/// );
/// ```
class GroupAnnotation extends Annotation {
  GroupAnnotation({
    required super.id,
    required Offset position,
    required Size size,
    required String title,
    Color color = Colors.blue,
    GroupBehavior behavior = GroupBehavior.bounds,
    Set<String>? nodeIds,
    this.padding = defaultPadding,
    int zIndex = -1, // Usually behind nodes
    bool isVisible = true,
    super.selected = false,
    super.isInteractive = true,
    super.metadata,
  }) : _nodeIds = ObservableSet.of(nodeIds ?? {}),
       _observableBehavior = Observable(behavior),
       super(
         type: 'group',
         initialPosition: position,
         initialZIndex: zIndex,
         initialIsVisible: isVisible,
       ) {
    _observableSize = Observable(size);
    _observableTitle = Observable(title);
    _observableColor = Observable(color);
  }

  late final Observable<Size> _observableSize;
  late final Observable<String> _observableTitle;
  late final Observable<Color> _observableColor;
  final Observable<GroupBehavior> _observableBehavior;

  /// Reactive observable for the group's behavior.
  ///
  /// When behavior changes, the annotation controller automatically
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
  /// This is manually set through resize operations or programmatically.
  Observable<Size> get observableSize => _observableSize;

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

  @override
  AnnotationRenderLayer get layer => AnnotationRenderLayer.background;

  /// Adds a node to the explicit membership.
  ///
  /// Only valid for [GroupBehavior.explicit] and [GroupBehavior.parent].
  /// For [GroupBehavior.bounds], use spatial containment instead.
  void addNode(String nodeId) {
    assert(
      behavior != GroupBehavior.bounds,
      'Cannot add nodes to bounds behavior - use spatial containment',
    );
    runInAction(() => _nodeIds.add(nodeId));
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
  /// - **bounds → explicit/parent**: If [captureContainedNodes] is provided,
  ///   those nodes are added to [nodeIds]. For explicit, [fitToNodes] is called.
  /// - **explicit/parent → bounds**: [nodeIds] is optionally cleared based on
  ///   [clearNodesOnBoundsSwitch].
  /// - **explicit ↔ parent**: [nodeIds] is preserved.
  ///
  /// The annotation controller automatically updates node monitoring reactions
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
  void onNodesDeleted(Set<String> nodeIds, AnnotationDragContext context) {
    final removed = _nodeIds.intersection(nodeIds);
    if (removed.isEmpty) return;
    runInAction(() => _nodeIds.removeAll(removed));

    // For explicit behavior, refit to remaining nodes
    if (behavior == GroupBehavior.explicit && _nodeIds.isNotEmpty) {
      fitToNodes(context.getNode);
    }
  }

  @override
  bool get monitorNodes => behavior != GroupBehavior.bounds;

  @override
  Set<String> get monitoredNodeIds =>
      behavior != GroupBehavior.bounds ? _nodeIds.toSet() : const {};

  @override
  bool get isEmpty => behavior != GroupBehavior.bounds && _nodeIds.isEmpty;

  @override
  bool get shouldRemoveWhenEmpty => behavior == GroupBehavior.explicit;

  @override
  void onNodeMoved(
    String nodeId,
    Offset newPosition,
    AnnotationDragContext context,
  ) {
    // Only explicit behavior auto-resizes when member nodes move
    if (behavior != GroupBehavior.explicit) return;
    if (!_nodeIds.contains(nodeId)) return;

    // Refit to contain all member nodes
    fitToNodes(context.getNode);
  }

  @override
  void onNodeResized(
    String nodeId,
    Size newSize,
    AnnotationDragContext context,
  ) {
    // Only explicit behavior auto-resizes when member nodes resize
    if (behavior != GroupBehavior.explicit) return;
    if (!_nodeIds.contains(nodeId)) return;

    // Refit to contain all member nodes
    fitToNodes(context.getNode);
  }

  /// Checks if a node is an explicit member of this group.
  ///
  /// For [GroupBehavior.bounds], always returns `false` since membership
  /// is determined spatially, not by ID.
  bool hasNode(String nodeId) => _nodeIds.contains(nodeId);

  @override
  Size get size => _observableSize.value;

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
    runInAction(() => _observableSize.value = constrainedSize);
  }

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
      position = newPos;
      visualPosition = newPos;
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
  @override
  Rect get bounds => Rect.fromLTWH(
    visualPosition.dx,
    visualPosition.dy,
    size.width,
    size.height,
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
  Widget buildWidget(BuildContext context) {
    return _GroupContent(annotation: this);
  }

  /// Creates a copy of this group annotation with optional property overrides.
  ///
  /// This is useful for creating variations of an existing group or
  /// for implementing undo/redo functionality.
  GroupAnnotation copyWith({
    String? id,
    Offset? position,
    Size? size,
    String? title,
    Color? color,
    GroupBehavior? behavior,
    Set<String>? nodeIds,
    EdgeInsets? padding,
    int? zIndex,
    bool? isVisible,
    bool? isInteractive,
    Map<String, dynamic>? metadata,
  }) {
    return GroupAnnotation(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      title: title ?? currentTitle,
      color: color ?? currentColor,
      behavior: behavior ?? this.behavior,
      nodeIds: nodeIds ?? Set.from(_nodeIds),
      padding: padding ?? this.padding,
      zIndex: zIndex ?? this.zIndex,
      isVisible: isVisible ?? this.isVisible,
      isInteractive: isInteractive ?? this.isInteractive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a [GroupAnnotation] from a JSON map.
  ///
  /// This factory method is used during workflow deserialization to recreate
  /// group annotations from saved data.
  /// Default padding: 40 top (for title), 20 sides and bottom
  static const defaultPadding = EdgeInsets.fromLTRB(20, 40, 20, 20);

  factory GroupAnnotation.fromJsonMap(Map<String, dynamic> json) {
    // Parse padding from JSON (stored as LTRB array or object)
    EdgeInsets padding = defaultPadding;
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

    final annotation = GroupAnnotation(
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
      color: Color(json['color'] as int? ?? Colors.blue.toARGB32()),
      behavior: GroupBehavior.values.byName(
        json['behavior'] as String? ?? 'bounds',
      ),
      nodeIds:
          (json['nodeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      padding: padding,
      zIndex: json['zIndex'] as int? ?? -1,
      isVisible: json['isVisible'] as bool? ?? true,
      isInteractive: json['isInteractive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
    return annotation;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': position.dx,
    'y': position.dy,
    'width': size.width,
    'height': size.height,
    'title': currentTitle,
    'color': currentColor.toARGB32(),
    'behavior': behavior.name,
    'nodeIds': _nodeIds.toList(),
    'padding': [padding.left, padding.top, padding.right, padding.bottom],
    'zIndex': zIndex,
    'isVisible': isVisible,
    'isInteractive': isInteractive,
    'metadata': metadata,
  };

  // ============================================================
  // Drag Lifecycle - Move contained nodes with the group
  // ============================================================

  @override
  void onDragStart(AnnotationDragContext context) {
    // Capture nodes to move based on behavior
    _containedNodeIds = switch (behavior) {
      // Spatial containment - find nodes inside bounds
      GroupBehavior.bounds => context.findNodesInBounds(bounds),
      // Explicit membership - use the explicit node ID set
      GroupBehavior.explicit => Set.from(_nodeIds),
      // Parent-child link - use the explicit node ID set
      GroupBehavior.parent => Set.from(_nodeIds),
    };
  }

  @override
  void onDragMove(Offset delta, AnnotationDragContext context) {
    // Move all contained nodes along with this group
    if (_containedNodeIds != null && _containedNodeIds!.isNotEmpty) {
      context.moveNodes(_containedNodeIds!, delta);
    }
  }

  @override
  void onDragEnd() {
    // Clear the cached contained nodes
    _containedNodeIds = null;
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    final newPosition = Offset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
    position = newPosition;
    visualPosition = newPosition; // Initialize visual position to match
    zIndex = json['zIndex'] as int? ?? -1;
    isVisible = json['isVisible'] as bool? ?? true;
    updateTitle(json['title'] as String? ?? '');
    updateColor(Color(json['color'] as int? ?? Colors.blue.toARGB32()));
    setSize(
      Size(
        (json['width'] as num?)?.toDouble() ?? 200.0,
        (json['height'] as num?)?.toDouble() ?? 150.0,
      ),
    );

    // Update nodeIds
    final nodeIdsList = json['nodeIds'] as List<dynamic>?;
    if (nodeIdsList != null) {
      runInAction(() {
        _nodeIds.clear();
        _nodeIds.addAll(nodeIdsList.map((e) => e as String));
      });
    }

    // Update behavior if specified
    final behaviorStr = json['behavior'] as String?;
    if (behaviorStr != null) {
      final newBehavior = GroupBehavior.values.firstWhere(
        (b) => b.name == behaviorStr,
        orElse: () => GroupBehavior.bounds,
      );
      runInAction(() => _observableBehavior.value = newBehavior);
    }
  }
}

/// Internal widget for rendering group content with inline title editing.
class _GroupContent extends StatefulWidget {
  const _GroupContent({required this.annotation});

  final GroupAnnotation annotation;

  @override
  State<_GroupContent> createState() => _GroupContentState();
}

class _GroupContentState extends State<_GroupContent> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  ReactionDisposer? _editingReaction;

  /// Stores the original title when editing starts, for cancel/restore.
  String _originalTitle = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.annotation.currentTitle,
    );
    _focusNode = FocusNode();

    // React to editing state changes to auto-focus
    _editingReaction = reaction((_) => widget.annotation.isEditing, (
      bool isEditing,
    ) {
      if (isEditing) {
        // Store original title for potential cancel
        _originalTitle = widget.annotation.currentTitle;
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
    if (!_focusNode.hasFocus && widget.annotation.isEditing) {
      _commitEdit();
    }
  }

  void _commitEdit() {
    widget.annotation.updateTitle(_textController.text);
    widget.annotation.isEditing = false;
  }

  /// Cancels the edit and restores the original title.
  void _cancelEdit() {
    _textController.text = _originalTitle;
    widget.annotation.isEditing = false;
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
    final flowTheme = Theme.of(context).extension<NodeFlowTheme>()!;
    final nodeTheme = flowTheme.nodeTheme;
    final annotationTheme = flowTheme.annotationTheme;
    final borderRadius = nodeTheme.borderRadius;
    final borderWidth = nodeTheme.borderWidth;

    return Observer(
      builder: (_) {
        // Observe all reactive properties including size and editing state
        final title = widget.annotation.currentTitle;
        final color = widget.annotation.currentColor;
        final currentSize = widget.annotation.observableSize.value;
        final isEditing = widget.annotation.isEditing;
        final radius = Radius.circular(borderRadius.topLeft.x - borderWidth);

        return Container(
          width: currentSize.width,
          height: currentSize.height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.all(radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.only(
                    topLeft: radius,
                    topRight: radius,
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
                          style: annotationTheme.labelStyle,
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
                        style: annotationTheme.labelStyle,
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
