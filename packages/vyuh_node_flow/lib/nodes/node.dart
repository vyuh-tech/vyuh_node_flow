import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

import '../ports/capsule_half.dart';
import '../ports/port.dart';
import '../shared/json_converters.dart';
import 'node_shape.dart';

/// Represents a single node in the flow graph.
///
/// A node is a visual element that can be connected to other nodes via [Port]s.
/// Each node has a position, size, and custom data of type [T]. Nodes can be
/// dragged, selected, and connected to create complex flow diagrams.
///
/// The node system uses MobX observables for reactive updates, ensuring that
/// any changes to node properties automatically trigger UI updates.
///
/// Example usage:
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
/// * [NodeData], the interface for node data objects
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
  Node({
    required this.id,
    required this.type,
    required Offset position,
    required this.data,
    Size? size,
    List<Port> inputPorts = const [],
    List<Port> outputPorts = const [],
    int initialZIndex = 0,
  }) : size = Observable(size ?? const Size(150, 100)),
       position = Observable(position),
       visualPosition = Observable(position),
       // Initialize with same position
       zIndex = Observable(initialZIndex),
       selected = Observable(false),
       dragging = Observable(false),
       inputPorts = ObservableList.of(inputPorts),
       outputPorts = ObservableList.of(outputPorts);

  /// Unique identifier for this node.
  ///
  /// Used to reference the node in connections and operations.
  final String id;

  /// Type classification for this node.
  ///
  /// Typically used to categorize nodes (e.g., 'input', 'processor', 'output')
  /// and may affect rendering or behavior.
  final String type;

  /// Observable size of the node.
  ///
  /// Changes to this value will automatically trigger UI updates.
  final Observable<Size> size;

  /// Observable list of input ports for incoming connections.
  ///
  /// Ports define where connections can be attached to receive data.
  final ObservableList<Port> inputPorts;

  /// Observable list of output ports for outgoing connections.
  ///
  /// Ports define where connections can originate to send data.
  final ObservableList<Port> outputPorts;

  /// Custom data associated with this node.
  ///
  /// The type [T] can be any object that implements [NodeData].
  final T data;

  /// Observable position of the node in graph coordinates.
  ///
  /// This is the actual logical position. For rendering, use [visualPosition]
  /// which may include snap-to-grid adjustments.
  final Observable<Offset> position;

  /// Observable z-index for stacking order.
  ///
  /// Higher values appear on top of lower values. Useful for managing
  /// overlapping nodes.
  final Observable<int> zIndex;

  /// Observable selection state.
  ///
  /// When true, the node is selected and may be styled differently.
  /// Not serialized to JSON.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Observable<bool> selected;

  /// Observable dragging state.
  ///
  /// When true, the node is currently being dragged by the user.
  /// Not serialized to JSON.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Observable<bool> dragging;

  /// Observable visual position for rendering.
  ///
  /// This may differ from [position] when snap-to-grid is enabled.
  /// Use this value for actual rendering in the UI.
  /// Not serialized to JSON.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Observable<Offset> visualPosition;

  /// Gets the current z-index value.
  ///
  /// This is a convenience getter for accessing the observable's value.
  int get currentZIndex => zIndex.value;

  /// Sets the z-index value in a MobX action.
  ///
  /// Updates are wrapped in [runInAction] to ensure proper state management.
  set currentZIndex(int value) => runInAction(() => zIndex.value = value);

  /// Gets the current selection state.
  ///
  /// Returns true if the node is currently selected.
  bool get isSelected => selected.value;

  /// Sets the selection state in a MobX action.
  ///
  /// Updates are wrapped in [runInAction] to ensure proper state management.
  set isSelected(bool value) => runInAction(() => selected.value = value);

  /// Gets the current dragging state.
  ///
  /// Returns true if the node is currently being dragged.
  bool get isDragging => dragging.value;

  /// Sets the dragging state in a MobX action.
  ///
  /// Updates are wrapped in [runInAction] to ensure proper state management.
  set isDragging(bool value) => runInAction(() => dragging.value = value);

  /// Updates the visual position based on the actual position and snapping rules.
  ///
  /// The visual position may differ from the logical [position] when snap-to-grid
  /// or other positioning constraints are applied. This method should be called
  /// by the graph controller when position constraints are updated.
  ///
  /// Parameters:
  /// * [snappedPosition] - The adjusted position to use for rendering
  void setVisualPosition(Offset snappedPosition) {
    runInAction(() {
      visualPosition.value = snappedPosition;
    });
  }

  /// Gets the visual position where a port should be rendered within the node container.
  ///
  /// Gets the visual origin (top-left corner) of a port within this node's
  /// local coordinate space.
  ///
  /// The origin is where the port widget's top-left corner should be positioned.
  /// Port widgets are positioned so their outer edge aligns with the node boundary.
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port
  /// * [portSize] - The size of the port widget (width x height)
  /// * [shape] - Optional shape for anchor-based positioning
  ///
  /// Returns the [Offset] where the port widget's top-left corner should be positioned.
  ///
  /// Throws [ArgumentError] if no port with the given [portId] is found.
  ///
  /// See also:
  /// - [getConnectionPoint] for the connection attachment position
  /// - [getPortCenter] for the visual center position
  Offset getVisualPortOrigin(
    String portId, {
    required Size portSize,
    NodeShape? shape,
  }) {
    final port = [
      ...inputPorts,
      ...outputPorts,
    ].cast<Port?>().firstWhere((p) => p?.id == portId, orElse: () => null);

    if (port == null) {
      throw ArgumentError('Port $portId not found');
    }

    // Get anchor position from shape (full node size) or default edge centers
    final Offset anchorOffset;
    if (shape != null) {
      final anchors = shape.getPortAnchors(size.value);
      final anchor = anchors.firstWhere(
        (a) => a.position == port.position,
        orElse: () => _fallbackAnchor(port.position),
      );
      anchorOffset = anchor.offset;
    } else {
      anchorOffset = _fallbackAnchor(port.position).offset;
    }

    // Use centralized calculation from PortPosition extension
    return port.position.calculateOrigin(
      anchorOffset: anchorOffset,
      portSize: portSize,
      portAdjustment: port.offset,
      useAnchorForPerpendicularAxis: shape != null,
    );
  }

  /// Creates a fallback anchor for a port position.
  ///
  /// Used when a shape doesn't provide an anchor for a specific position.
  /// Returns anchors at edge centers for the node's current size.
  ///
  /// Parameters:
  /// * [position] - The port position
  PortAnchor _fallbackAnchor(PortPosition position) {
    final centerX = size.value.width / 2;
    final centerY = size.value.height / 2;

    switch (position) {
      case PortPosition.left:
        return PortAnchor(
          position: PortPosition.left,
          offset: Offset(0, centerY),
          normal: const Offset(-1, 0),
        );
      case PortPosition.right:
        return PortAnchor(
          position: PortPosition.right,
          offset: Offset(size.value.width, centerY),
          normal: const Offset(1, 0),
        );
      case PortPosition.top:
        return PortAnchor(
          position: PortPosition.top,
          offset: Offset(centerX, 0),
          normal: const Offset(0, -1),
        );
      case PortPosition.bottom:
        return PortAnchor(
          position: PortPosition.bottom,
          offset: Offset(centerX, size.value.height),
          normal: const Offset(0, 1),
        );
    }
  }

  /// Gets the connection attachment point for a port in graph coordinates.
  ///
  /// This is where connection lines should attach to the port. The connection
  /// point is at the port's outer edge (the edge aligned with the node boundary).
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port
  /// * [portSize] - The size of the port widget (width x height)
  /// * [shape] - Optional shape to use for port position calculation
  ///
  /// Returns the absolute [Offset] in graph coordinates where connections attach.
  ///
  /// Throws [ArgumentError] if no port with the given [portId] is found.
  ///
  /// See also:
  /// - [getVisualPortOrigin] for the port widget's top-left position
  /// - [getPortCenter] for the visual center position
  Offset getConnectionPoint(
    String portId, {
    required Size portSize,
    NodeShape? shape,
  }) {
    final port = [
      ...inputPorts,
      ...outputPorts,
    ].cast<Port?>().firstWhere((p) => p?.id == portId, orElse: () => null);

    if (port == null) {
      throw ArgumentError('Port $portId not found');
    }

    // Use centralized calculation from PortPosition extension
    final connectionOffset = port.position.connectionOffset(portSize);

    // Convert from node coordinates to absolute graph coordinates
    return visualPosition.value +
        getVisualPortOrigin(portId, portSize: portSize, shape: shape) +
        connectionOffset;
  }

  /// Gets the visual center of a port in graph coordinates.
  ///
  /// This is the center of the port widget, used for hit testing bounds
  /// and visual highlighting.
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port
  /// * [portSize] - The size of the port widget (width x height)
  /// * [shape] - Optional shape to use for port position calculation
  ///
  /// Returns the absolute [Offset] of the port's visual center in graph coordinates.
  ///
  /// Throws [ArgumentError] if no port with the given [portId] is found.
  ///
  /// See also:
  /// - [getVisualPortOrigin] for the port widget's top-left position
  /// - [getConnectionPoint] for the connection attachment position
  Offset getPortCenter(
    String portId, {
    required Size portSize,
    NodeShape? shape,
  }) {
    final port = [
      ...inputPorts,
      ...outputPorts,
    ].cast<Port?>().firstWhere((p) => p?.id == portId, orElse: () => null);

    if (port == null) {
      throw ArgumentError('Port $portId not found');
    }

    // Center offset is simply half the port size (doesn't depend on port position)
    final centerOffset = Offset(portSize.width / 2, portSize.height / 2);

    // Convert from node coordinates to absolute graph coordinates
    return visualPosition.value +
        getVisualPortOrigin(portId, portSize: portSize, shape: shape) +
        centerOffset;
  }

  /// Gets the capsule flat side orientation for a port.
  ///
  /// Ports are rendered as capsule half shapes with one flat edge. This method
  /// determines which edge should be flat based on the port's position.
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port
  ///
  /// Returns the [CapsuleFlatSide] orientation for the port.
  ///
  /// Throws [ArgumentError] if no port with the given [portId] is found.
  CapsuleFlatSide getPortCapsuleSide(String portId) {
    final port = [
      ...inputPorts,
      ...outputPorts,
    ].cast<Port?>().firstWhere((p) => p?.id == portId, orElse: () => null);

    if (port == null) {
      throw ArgumentError('Port $portId not found');
    }

    switch (port.position) {
      case PortPosition.left:
        return CapsuleFlatSide.left;
      case PortPosition.right:
        return CapsuleFlatSide.right;
      case PortPosition.top:
        return CapsuleFlatSide.top;
      case PortPosition.bottom:
        return CapsuleFlatSide.bottom;
    }
  }

  /// Adds an input port to the node.
  ///
  /// The port will be added to the end of the [inputPorts] list.
  ///
  /// Parameters:
  /// * [port] - The port to add
  void addInputPort(Port port) {
    runInAction(() {
      inputPorts.add(port);
    });
  }

  /// Adds an output port to the node.
  ///
  /// The port will be added to the end of the [outputPorts] list.
  ///
  /// Parameters:
  /// * [port] - The port to add
  void addOutputPort(Port port) {
    runInAction(() {
      outputPorts.add(port);
    });
  }

  /// Removes an input port by ID.
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port to remove
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
  /// Parameters:
  /// * [portId] - The unique identifier of the port to remove
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
  ///
  /// This is a convenience method that searches both input and output ports.
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port to remove
  ///
  /// Returns true if the port was found and removed, false otherwise.
  bool removePort(String portId) {
    return removeInputPort(portId) || removeOutputPort(portId);
  }

  /// Updates an existing input port by ID.
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port to update
  /// * [updatedPort] - The new port object to replace the existing one
  ///
  /// Returns true if the port was found and updated, false otherwise.
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
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port to update
  /// * [updatedPort] - The new port object to replace the existing one
  ///
  /// Returns true if the port was found and updated, false otherwise.
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
  ///
  /// This is a convenience method that searches both input and output ports.
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port to update
  /// * [updatedPort] - The new port object to replace the existing one
  ///
  /// Returns true if the port was found and updated, false otherwise.
  bool updatePort(String portId, Port updatedPort) {
    return updateInputPort(portId, updatedPort) ||
        updateOutputPort(portId, updatedPort);
  }

  /// Gets all ports (input and output combined).
  ///
  /// Returns a new list containing all input ports followed by all output ports.
  List<Port> get allPorts => [...inputPorts, ...outputPorts];

  /// Finds a port by ID in either input or output ports.
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port to find
  ///
  /// Returns the [Port] if found, null otherwise.
  Port? findPort(String portId) {
    try {
      return inputPorts.firstWhere((port) => port.id == portId);
    } catch (_) {
      try {
        return outputPorts.firstWhere((port) => port.id == portId);
      } catch (_) {
        return null;
      }
    }
  }

  /// Checks if a point is within the node's rectangular bounds.
  ///
  /// This method tests if a given point in graph coordinates falls within
  /// the node's bounding rectangle.
  ///
  /// For shaped nodes, hit testing is handled by the NodeShapePainter's hitTest method.
  ///
  /// Parameters:
  /// * [point] - The point to test in graph coordinates
  ///
  /// Returns true if the point is inside the node bounds, false otherwise.
  bool containsPoint(Offset point) {
    // Check if point is within the actual node bounds (not including port padding)
    return Rect.fromLTWH(
      position.value.dx,
      position.value.dy,
      size.value.width,
      size.value.height,
    ).contains(point);
  }

  /// Gets the node's bounding rectangle.
  ///
  /// Returns the rectangle that defines the node's area in graph coordinates.
  /// Port padding is excluded from the bounds. The bounds use the current
  /// position value.
  ///
  /// Returns a [Rect] representing the node's bounding box.
  Rect getBounds() {
    // Return the actual node bounds without port padding
    // Use visual position for bounds
    return Rect.fromLTWH(
      position.value.dx,
      position.value.dy,
      size.value.width,
      size.value.height,
    );
  }

  /// Disposes of resources used by this node.
  ///
  /// Currently, MobX observables don't require manual disposal, so this
  /// method is a no-op. It's provided for future extensibility.
  void dispose() {
    // MobX observables don't need manual disposal
  }

  /// Creates a node from JSON data.
  ///
  /// This factory constructor deserializes a node from a JSON map. The custom
  /// data type [T] must be deserialized using the provided [fromJsonT] function.
  ///
  /// Parameters:
  /// * [json] - The JSON map containing node data
  /// * [fromJsonT] - Function to deserialize the custom data of type [T]
  ///
  /// Returns a new [Node] instance with data from the JSON.
  factory Node.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return Node<T>(
        id: json['id'] as String,
        type: json['type'] as String,
        position: json['position'] != null
            ? const OffsetConverter().fromJson(
                json['position'] as Map<String, dynamic>,
              )
            : Offset.zero,
        data: fromJsonT(json['data']),
        size: json['size'] != null
            ? const SizeConverter().fromJson(
                json['size'] as Map<String, dynamic>,
              )
            : null,
        // Let the constructor use its default
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
      )
      // Set the observable values after construction
      ..position.value = json['position'] != null
          ? const OffsetConverter().fromJson(
              json['position'] as Map<String, dynamic>,
            )
          : Offset.zero
      ..zIndex.value = (json['zIndex'] as num?)?.toInt() ?? 0
      ..selected.value = (json['selected'] as bool?) ?? false;
  }

  /// Converts the node to a JSON map.
  ///
  /// This method serializes the node to a JSON-compatible map. The custom
  /// data type [T] must be serialized using the provided [toJsonT] function.
  ///
  /// Parameters:
  /// * [toJsonT] - Function to serialize the custom data of type [T]
  ///
  /// Returns a JSON-compatible [Map] containing the node's data.
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
    'id': id,
    'type': type,
    'size': const SizeConverter().toJson(size.value),
    'inputPorts': inputPorts.map((e) => e.toJson()).toList(),
    'outputPorts': outputPorts.map((e) => e.toJson()).toList(),
    'data': toJsonT(data),
    'position': const OffsetConverter().toJson(position.value),
    'zIndex': zIndex.value,
    'selected': selected.value,
  };
}
