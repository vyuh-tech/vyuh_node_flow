import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../ports/port.dart';
import 'node_drag_context.dart';

export 'node_drag_context.dart';
export 'node_port_geometry.dart';

/// The rendering layer for a node.
///
/// Nodes are rendered in three layers:
/// - [background]: Behind regular nodes (e.g., group annotations)
/// - [middle]: Default layer for regular nodes
/// - [foreground]: Above nodes and connections (e.g., sticky notes, markers)
enum NodeRenderLayer {
  /// Rendered behind regular nodes.
  ///
  /// Use this for elements that should appear as backgrounds or containers,
  /// such as group annotations.
  background,

  /// Default rendering layer for regular nodes.
  ///
  /// This is where standard nodes are rendered, above background elements
  /// and connections.
  middle,

  /// Rendered above nodes and connections.
  ///
  /// Use this for elements that should overlay the canvas content,
  /// such as sticky notes and markers.
  foreground,
}

/// Represents a single node in the flow graph.
///
/// A node is a visual element that can be connected to other nodes via [Port]s.
/// Each node has a position, size, and custom data of type [T]. Nodes can be
/// dragged, selected, and connected to create complex flow diagrams.
///
/// The node system uses MobX observables for reactive updates, ensuring that
/// any changes to node properties automatically trigger UI updates.
///
/// ## Capability-Based Design
///
/// Node capabilities are added via mixins:
/// - [ResizableMixin] - Resize functionality (sets [isResizable] to true)
/// - [GroupableMixin] - Grouping/container functionality with child node monitoring
///
/// Base nodes have port geometry built-in. Specialized nodes like [GroupNode]
/// and [CommentNode] add capabilities through mixins.
///
/// ## Example
///
/// ```dart
/// final node = Node<MyData>(
///   id: 'node-1',
///   type: 'processor',
///   position: Offset(100, 100),
///   data: MyData(value: 'example'),
///   inputPorts: [
///     Port(id: 'in-1', position: PortPosition.left),
///   ],
///   outputPorts: [
///     Port(id: 'out-1', position: PortPosition.right),
///   ],
/// );
/// ```
///
/// See also:
/// * [Port], which defines connection points on nodes
/// * [NodeWidget], which renders nodes in the UI
/// * [GroupNode], a specialized node for grouping other nodes
/// * [CommentNode], a specialized node for annotations
class Node<T> {
  /// Creates a new node with the specified properties.
  ///
  /// Parameters:
  /// * [id] - Unique identifier for this node
  /// * [type] - Type classification for the node (e.g., 'input', 'processor', 'output')
  /// * [position] - Initial position in the graph coordinate space
  /// * [data] - Custom data associated with this node
  /// * [size] - Optional size, defaults to 150x100 if not specified
  /// * [inputPorts] - List of input ports for incoming connections
  /// * [outputPorts] - List of output ports for outgoing connections
  /// * [initialZIndex] - Initial stacking order, higher values appear on top
  /// * [visible] - Initial visibility state, defaults to true
  /// * [layer] - Rendering layer (background/middle/foreground), defaults to middle
  /// * [locked] - Whether the node is locked (cannot be dragged), defaults to false
  /// * [selectable] - Whether the node participates in marquee selection, defaults to true
  Node({
    required this.id,
    required this.type,
    required Offset position,
    required this.data,
    Size? size,
    List<Port> inputPorts = const [],
    List<Port> outputPorts = const [],
    int initialZIndex = 0,
    bool visible = true,
    this.layer = NodeRenderLayer.middle,
    this.locked = false,
    this.selectable = true,
  }) : size = Observable(size ?? const Size(150, 100)),
       position = Observable(position),
       visualPosition = Observable(position),
       zIndex = Observable(initialZIndex),
       selected = Observable(false),
       dragging = Observable(false),
       _isVisible = Observable(visible),
       _isEditing = Observable(false),
       inputPorts = ObservableList.of(inputPorts),
       outputPorts = ObservableList.of(outputPorts);

  // ===========================================================================
  // Core Properties
  // ===========================================================================

  /// Unique identifier for this node.
  final String id;

  /// Type classification for this node.
  final String type;

  /// Observable size of the node.
  final Observable<Size> size;

  /// Observable list of input ports for incoming connections.
  final ObservableList<Port> inputPorts;

  /// Observable list of output ports for outgoing connections.
  final ObservableList<Port> outputPorts;

  /// Custom data associated with this node.
  final T data;

  /// Observable position of the node in graph coordinates.
  final Observable<Offset> position;

  /// Observable z-index for stacking order.
  final Observable<int> zIndex;

  /// Observable selection state.
  final Observable<bool> selected;

  /// Observable dragging state.
  final Observable<bool> dragging;

  /// Observable visibility state.
  final Observable<bool> _isVisible;

  /// Observable editing state.
  final Observable<bool> _isEditing;

  /// Observable visual position for rendering (may include snap-to-grid).
  final Observable<Offset> visualPosition;

  /// Rendering layer for this node.
  final NodeRenderLayer layer;

  /// Whether this node is locked from user interactions.
  ///
  /// When `true`, the node cannot be dragged or resized via the UI.
  /// Programmatic operations (delete, move, resize via API) still work.
  /// Useful for template elements or locked design components.
  final bool locked;

  /// Whether this node participates in marquee selection.
  final bool selectable;

  // ===========================================================================
  // Capability Indicators
  // ===========================================================================

  /// Whether this node can be resized.
  ///
  /// Returns `false` by default. Nodes that include [ResizableMixin]
  /// get this overridden to `true`. Subclasses can further override
  /// to add conditional logic (e.g., GroupNode checks behavior).
  ///
  /// This is a capability indicator - if `true`, the node is guaranteed
  /// to have [ResizableMixin] and can be safely cast to access resize methods.
  bool get isResizable => false;

  // ===========================================================================
  // State Accessors
  // ===========================================================================

  /// Gets the current visibility state.
  bool get isVisible => _isVisible.value;

  /// Sets the visibility state.
  set isVisible(bool value) => runInAction(() => _isVisible.value = value);

  /// Gets the current editing state.
  bool get isEditing => _isEditing.value;

  /// Sets the editing state.
  set isEditing(bool value) => runInAction(() => _isEditing.value = value);

  /// Gets the current z-index value.
  int get currentZIndex => zIndex.value;

  /// Sets the z-index value in a MobX action.
  set currentZIndex(int value) => runInAction(() => zIndex.value = value);

  /// Gets the current selection state.
  bool get isSelected => selected.value;

  /// Sets the selection state in a MobX action.
  set isSelected(bool value) => runInAction(() => selected.value = value);

  /// Gets the current dragging state.
  bool get isDragging => dragging.value;

  /// Sets the dragging state in a MobX action.
  set isDragging(bool value) => runInAction(() => dragging.value = value);

  /// Sets the size of this node.
  ///
  /// Override this method in subclasses that need custom size handling.
  void setSize(Size newSize) {
    runInAction(() {
      size.value = newSize;
    });
  }

  /// Updates the visual position based on the actual position and snapping rules.
  void setVisualPosition(Offset snappedPosition) {
    runInAction(() {
      visualPosition.value = snappedPosition;
    });
  }

  // ===========================================================================
  // Port Management
  // ===========================================================================

  /// Adds an input port to the node.
  void addInputPort(Port port) {
    runInAction(() {
      inputPorts.add(port);
    });
  }

  /// Adds an output port to the node.
  void addOutputPort(Port port) {
    runInAction(() {
      outputPorts.add(port);
    });
  }

  /// Removes an input port by ID.
  ///
  /// Returns true if the port was found and removed, false otherwise.
  bool removeInputPort(String portId) {
    return runInAction(() {
      final index = inputPorts.indexWhere((port) => port.id == portId);
      if (index >= 0) {
        inputPorts.removeAt(index);
        return true;
      }
      return false;
    });
  }

  /// Removes an output port by ID.
  ///
  /// Returns true if the port was found and removed, false otherwise.
  bool removeOutputPort(String portId) {
    return runInAction(() {
      final index = outputPorts.indexWhere((port) => port.id == portId);
      if (index >= 0) {
        outputPorts.removeAt(index);
        return true;
      }
      return false;
    });
  }

  /// Removes a port by ID from either input or output ports.
  bool removePort(String portId) {
    return removeInputPort(portId) || removeOutputPort(portId);
  }

  /// Updates an existing input port by ID.
  bool updateInputPort(String portId, Port updatedPort) {
    return runInAction(() {
      final index = inputPorts.indexWhere((port) => port.id == portId);
      if (index >= 0) {
        inputPorts[index] = updatedPort;
        return true;
      }
      return false;
    });
  }

  /// Updates an existing output port by ID.
  bool updateOutputPort(String portId, Port updatedPort) {
    return runInAction(() {
      final index = outputPorts.indexWhere((port) => port.id == portId);
      if (index >= 0) {
        outputPorts[index] = updatedPort;
        return true;
      }
      return false;
    });
  }

  /// Updates a port by ID in either input or output ports.
  bool updatePort(String portId, Port updatedPort) {
    return updateInputPort(portId, updatedPort) ||
        updateOutputPort(portId, updatedPort);
  }

  /// Gets all ports (input and output combined).
  List<Port> get allPorts => [...inputPorts, ...outputPorts];

  /// Finds a port by ID in either input or output ports.
  Port? findPort(String portId) {
    for (final port in inputPorts) {
      if (port.id == portId) return port;
    }
    for (final port in outputPorts) {
      if (port.id == portId) return port;
    }
    return null;
  }

  // ===========================================================================
  // Bounds and Containment
  // ===========================================================================

  /// Checks if a point is within the node's rectangular bounds.
  bool containsPoint(Offset point) {
    return Rect.fromLTWH(
      position.value.dx,
      position.value.dy,
      size.value.width,
      size.value.height,
    ).contains(point);
  }

  /// Gets the node's bounding rectangle.
  Rect getBounds() {
    return Rect.fromLTWH(
      position.value.dx,
      position.value.dy,
      size.value.width,
      size.value.height,
    );
  }

  // ===========================================================================
  // Widget Building
  // ===========================================================================

  /// Builds the widget for this node.
  ///
  /// Override this method to provide a custom widget for self-rendering nodes
  /// like annotations. When this returns `null`, the external `nodeBuilder`
  /// callback is used instead.
  Widget? buildWidget(BuildContext context) => null;

  // ===========================================================================
  // Drag Lifecycle Hooks
  // ===========================================================================

  /// Called when a drag operation starts on this node.
  void onDragStart(NodeDragContext context) {
    // Default: no-op
  }

  /// Called during a drag operation as the node moves.
  void onDragMove(Offset delta, NodeDragContext context) {
    // Default: no-op
  }

  /// Called when a drag operation ends.
  void onDragEnd() {
    // Default: no-op
  }

  // ===========================================================================
  // Disposal
  // ===========================================================================

  /// Disposes of resources used by this node.
  void dispose() {
    // MobX observables don't need manual disposal
  }

  // ===========================================================================
  // Serialization
  // ===========================================================================

  /// Creates a node from JSON data.
  factory Node.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    // Parse layer from string if present
    final layerStr = json['layer'] as String?;
    final layer = layerStr != null
        ? NodeRenderLayer.values.firstWhere(
            (l) => l.name == layerStr,
            orElse: () => NodeRenderLayer.middle,
          )
        : NodeRenderLayer.middle;

    // Parse position from x, y at top level
    final position = Offset(
      (json['x'] as num?)?.toDouble() ?? 0,
      (json['y'] as num?)?.toDouble() ?? 0,
    );

    // Parse size from width, height at top level
    final size = json.containsKey('width') && json.containsKey('height')
        ? Size(
            (json['width'] as num).toDouble(),
            (json['height'] as num).toDouble(),
          )
        : null;

    return Node<T>(
        id: json['id'] as String,
        type: json['type'] as String,
        position: position,
        data: fromJsonT(json['data']),
        size: size,
        inputPorts:
            (json['inputPorts'] as List<dynamic>?)
                ?.map((e) => Port.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        outputPorts:
            (json['outputPorts'] as List<dynamic>?)
                ?.map((e) => Port.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        initialZIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
        visible: (json['isVisible'] as bool?) ?? true,
        layer: layer,
        locked: (json['locked'] as bool?) ?? false,
        selectable: (json['selectable'] as bool?) ?? true,
      )
      // Set the observable values after construction
      ..position.value = position
      ..zIndex.value = (json['zIndex'] as num?)?.toInt() ?? 0
      ..selected.value = (json['selected'] as bool?) ?? false;
  }

  /// Converts the node to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
    'id': id,
    'type': type,
    'x': position.value.dx,
    'y': position.value.dy,
    'width': size.value.width,
    'height': size.value.height,
    'inputPorts': inputPorts.map((e) => e.toJson()).toList(),
    'outputPorts': outputPorts.map((e) => e.toJson()).toList(),
    'data': toJsonT(data),
    'zIndex': zIndex.value,
    'selected': selected.value,
    'isVisible': isVisible,
    'layer': layer.name,
    'locked': locked,
    'isResizable': isResizable,
    'selectable': selectable,
  };
}
