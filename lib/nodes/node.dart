import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

import '../ports/capsule_half.dart';
import '../ports/port.dart';
import '../shared/json_converters.dart';

class Node<T> {
  Node({
    required this.id,
    required this.type,
    required Offset position,
    required this.data,
    Size? size,
    List<Port> inputPorts = const [],
    List<Port> outputPorts = const [],
    int initialZIndex = 0,
  }) : size = size ?? const Size(150, 100),
       position = Observable(position),
       visualPosition = Observable(position), // Initialize with same position
       zIndex = Observable(initialZIndex),
       selected = Observable(false),
       dragging = Observable(false),
       inputPorts = ObservableList.of(inputPorts),
       outputPorts = ObservableList.of(outputPorts);

  final String id;
  final String type;

  final Size size;
  final ObservableList<Port> inputPorts;
  final ObservableList<Port> outputPorts;
  final T data;

  // Observable properties for reactive updates
  final Observable<Offset> position;
  final Observable<int> zIndex;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final Observable<bool> selected;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final Observable<bool> dragging;

  // Visual position for rendering (with snap to grid applied)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Observable<Offset> visualPosition;

  int get currentZIndex => zIndex.value;
  set currentZIndex(int value) => runInAction(() => zIndex.value = value);

  bool get isSelected => selected.value;
  set isSelected(bool value) => runInAction(() => selected.value = value);

  bool get isDragging => dragging.value;
  set isDragging(bool value) => runInAction(() => dragging.value = value);

  /// Updates the visual position based on the actual position and snapping rules
  void setVisualPosition(Offset snappedPosition) {
    runInAction(() {
      visualPosition.value = snappedPosition;
    });
  }

  /// Gets the visual position where a port should be rendered within the node container
  /// This is used for positioning port widgets within the node's padded container
  /// The port is centered on this position
  Offset getVisualPortPosition(String portId, {required double portSize}) {
    final port = [
      ...inputPorts,
      ...outputPorts,
    ].cast<Port?>().firstWhere((p) => p?.id == portId, orElse: () => null);

    if (port == null) {
      throw ArgumentError('Port $portId not found');
    }

    switch (port.position) {
      case PortPosition.left:
        // Left edge: port protrudes halfway out from left edge
        return Offset(
          port.offset.dx, // Left edge of padded container
          port.offset.dy, // Centered vertically with offset
        );
      case PortPosition.right:
        // Right edge: port protrudes halfway out from right edge
        return Offset(
          size.width -
              portSize +
              port.offset.dx, // Right edge of padded container minus port size
          port.offset.dy, // Centered vertically with offset
        );
      case PortPosition.top:
        // Top edge: port protrudes halfway out from top edge
        return Offset(
          port.offset.dx, // Centered horizontally with offset
          port.offset.dy, // Top edge of padded container
        );
      case PortPosition.bottom:
        // Bottom edge: port protrudes halfway out from bottom edge
        return Offset(
          port.offset.dx, // Centered horizontally with offset
          size.height - portSize + port.offset.dy, // Bottom edge of container
        );
    }
  }

  /// Gets the connection point for a port where line endpoints should attach
  /// Connections should align with the flat edge of the capsule halves
  Offset getPortPosition(String portId, {required double portSize}) {
    final portHalfSize = portSize / 2;

    // Convert from node coordinates to absolute graph coordinates
    // Use visual position for consistent rendering
    return visualPosition.value +
        getVisualPortPosition(portId, portSize: portSize) +
        Offset(portHalfSize, portHalfSize);
  }

  /// Gets the capsule flat side orientation for a port
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

  /// Adds an input port to the node
  void addInputPort(Port port) {
    runInAction(() {
      inputPorts.add(port);
    });
  }

  /// Adds an output port to the node
  void addOutputPort(Port port) {
    runInAction(() {
      outputPorts.add(port);
    });
  }

  /// Removes an input port by ID
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

  /// Removes an output port by ID
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

  /// Removes a port by ID from either input or output ports
  bool removePort(String portId) {
    return removeInputPort(portId) || removeOutputPort(portId);
  }

  /// Updates an existing input port by ID
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

  /// Updates an existing output port by ID
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

  /// Updates a port by ID in either input or output ports
  bool updatePort(String portId, Port updatedPort) {
    return updateInputPort(portId, updatedPort) ||
        updateOutputPort(portId, updatedPort);
  }

  /// Gets all ports (input and output combined)
  List<Port> get allPorts => [...inputPorts, ...outputPorts];

  /// Finds a port by ID in either input or output ports
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

  /// Checks if a point is within the node bounds (excluding port padding)
  bool containsPoint(Offset point, {double portSize = 11.0}) {
    // Check if point is within the actual node bounds (not including port padding)
    return Rect.fromLTWH(
      position.value.dx,
      position.value.dy,
      size.width,
      size.height,
    ).contains(point);
  }

  /// Gets the node's bounding rectangle (excluding port padding)
  Rect getBounds({double portSize = 11.0}) {
    // Return the actual node bounds without port padding
    // Use visual position for bounds
    return Rect.fromLTWH(
      position.value.dx,
      position.value.dy,
      size.width,
      size.height,
    );
  }

  void dispose() {
    // MobX observables don't need manual disposal
  }

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
            : null, // Let the constructor use its default
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

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
    'id': id,
    'type': type,
    'size': const SizeConverter().toJson(size),
    'inputPorts': inputPorts.map((e) => e.toJson()).toList(),
    'outputPorts': outputPorts.map((e) => e.toJson()).toList(),
    'data': toJsonT(data),
    'position': const OffsetConverter().toJson(position.value),
    'zIndex': zIndex.value,
    'selected': selected.value,
  };
}
