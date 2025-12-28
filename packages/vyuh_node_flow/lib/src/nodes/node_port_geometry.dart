import 'dart:ui';

import '../ports/port.dart';
import 'node.dart';
import 'node_shape.dart';

/// Extension providing port geometry calculations for nodes.
///
/// This extension handles all port position calculations, including:
/// - Visual port origins (where port widgets render)
/// - Connection attachment points (where connection lines attach)
/// - Port centers (for hit testing and highlighting)
///
/// The calculations account for node shapes and port-specific offsets,
/// ensuring ports are correctly positioned on various node geometries.
///
/// ## Usage
///
/// ```dart
/// final connectionPoint = node.getConnectionPoint(
///   'port-id',
///   portSize: Size(12, 12),
/// );
/// ```
extension NodePortGeometry<T> on Node<T> {
  /// Gets the visual position where a port should be rendered within the node container.
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
  Offset getVisualPortOrigin(
    String portId, {
    required Size portSize,
    NodeShape? shape,
  }) {
    final port = findPort(portId);

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

  /// Gets the connection attachment point for a port in graph coordinates.
  ///
  /// This is where connection lines should attach to the port.
  ///
  /// Parameters:
  /// * [portId] - The unique identifier of the port
  /// * [portSize] - The size of the port widget (width x height)
  /// * [shape] - Optional shape to use for port position calculation
  ///
  /// Returns the absolute [Offset] in graph coordinates where connections attach.
  ///
  /// Throws [ArgumentError] if no port with the given [portId] is found.
  Offset getConnectionPoint(
    String portId, {
    required Size portSize,
    NodeShape? shape,
  }) {
    final port = findPort(portId);

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
  Offset getPortCenter(
    String portId, {
    required Size portSize,
    NodeShape? shape,
  }) {
    final port = findPort(portId);

    if (port == null) {
      throw ArgumentError('Port $portId not found');
    }

    // Center offset is simply half the port size
    final centerOffset = Offset(portSize.width / 2, portSize.height / 2);

    // Convert from node coordinates to absolute graph coordinates
    return visualPosition.value +
        getVisualPortOrigin(portId, portSize: portSize, shape: shape) +
        centerOffset;
  }

  /// Creates a fallback anchor for a port position.
  ///
  /// Used when a shape doesn't provide an anchor for a specific position.
  /// Returns anchors at edge centers for the node's current size.
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
}
