import 'dart:math' as math;
import 'dart:ui';

import '../../ports/port.dart';
import 'connection_style_base.dart';
import 'path_segments.dart';

// Re-export segment types for convenience
export 'path_segments.dart';

// ============================================================
// Enums and Constants
// ============================================================

/// Direction for routing around obstacles.
enum LoopbackDirection {
  /// Route above the obstacle (negative Y direction)
  above,

  /// Route below the obstacle (positive Y direction)
  below,

  /// Route to the left of the obstacle (negative X direction)
  left,

  /// Route to the right of the obstacle (positive X direction)
  right,
}

/// Builds waypoints for connection paths with node-aware routing.
///
/// This class handles all routing scenarios:
/// 1. **Direct**: Straight line when ports align and no obstruction
/// 2. **L-Shape**: Single bend when simple corner routing works
/// 3. **Same-Side**: Routes past union of node bounds when ports face same direction
/// 4. **Self-Connection**: Routes around the node's own bounds
/// 5. **Loop-back**: Routes around union of node bounds when target is behind source
///
/// ## Node-Aware Routing
///
/// When [sourceNodeBounds] and [targetNodeBounds] are provided, the builder
/// ensures connections never route through nodes. Instead, connections route
/// around the union of both node rectangles.
///
/// ## Example
/// ```dart
/// final waypoints = WaypointBuilder.calculateWaypoints(
///   start: sourcePort.globalPosition,
///   end: targetPort.globalPosition,
///   sourcePosition: sourcePort.position,
///   targetPosition: targetPort.position,
///   offset: theme.portExtension,
///   sourceNodeBounds: sourceNode.getBounds(),
///   targetNodeBounds: targetNode.getBounds(),
/// );
/// ```
class WaypointBuilder {
  const WaypointBuilder._();

  // ============================================================
  // Loopback Routing (Shared by All Styles)
  // ============================================================

  /// Determines if loopback routing is needed for the given parameters.
  ///
  /// Loopback routing is required when:
  /// - Self-connection (same node)
  /// - Same-side ports (e.g., right→right)
  /// - Target is behind source relative to port direction
  ///
  /// This method is shared by all connection styles since loopback detection
  /// logic is independent of the visual style.
  static bool needsLoopbackRouting(ConnectionPathParameters params) {
    final sourcePosition = params.sourcePosition;
    final targetPosition = params.targetPosition;

    // Self-connection check
    if (params.sourceNodeBounds != null &&
        params.targetNodeBounds != null &&
        params.sourceNodeBounds == params.targetNodeBounds) {
      return true;
    }

    // Same-side ports always need loopback
    if (sourcePosition == targetPosition) {
      return true;
    }

    // Check if target is behind source relative to port direction
    final start = params.start;
    final end = params.end;
    final offset = params.offset;

    final isTargetBehind = switch (sourcePosition) {
      PortPosition.right => end.dx < start.dx - offset,
      PortPosition.left => end.dx > start.dx + offset,
      PortPosition.bottom => end.dy < start.dy - offset,
      PortPosition.top => end.dy > start.dy + offset,
    };

    return isTargetBehind;
  }

  /// Builds path segments for loopback routing.
  ///
  /// Uses waypoint-based routing with rounded corners (quadratic curves).
  /// This method is shared by all connection styles since loopback routing
  /// always uses the same step-based approach regardless of style.
  ///
  /// Returns a list of [PathSegment]s that route around node bounds.
  static List<PathSegment> buildLoopbackSegments(
    ConnectionPathParameters params,
  ) {
    final waypoints = calculateWaypoints(
      start: params.start,
      end: params.end,
      sourcePosition: params.sourcePosition,
      targetPosition: params.targetPosition,
      offset: params.offset,
      backEdgeGap: params.backEdgeGap,
      sourceNodeBounds: params.sourceNodeBounds,
      targetNodeBounds: params.targetNodeBounds,
    );
    final optimized = optimizeWaypoints(waypoints);

    // Convert waypoints to segments with rounded corners
    return waypointsToSegments(optimized, cornerRadius: params.cornerRadius);
  }

  // ============================================================
  // Main Entry Point
  // ============================================================

  /// Calculates waypoints with node-aware routing.
  ///
  /// This is the main entry point for waypoint calculation. It handles:
  /// - Self-connections (same node)
  /// - Same-side ports (e.g., right→right)
  /// - Direct connections (collinear points)
  /// - L-shape connections (single bend)
  /// - Loop-back connections (routing around nodes)
  ///
  /// Parameters:
  /// - [offset]: Distance for port extension (straight segment from port)
  /// - [backEdgeGap]: Clearance from node bounds for loopback routing
  static List<Offset> calculateWaypoints({
    required Offset start,
    required Offset end,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    required double offset,
    double? backEdgeGap,
    Rect? sourceNodeBounds,
    Rect? targetNodeBounds,
  }) {
    // Use backEdgeGap for loopback routing, default to offset if not specified
    final loopbackGap = backEdgeGap ?? offset;
    // Calculate extended points (always outward from ports)
    final startExtended = getExtendedPoint(start, sourcePosition, offset);
    final endExtended = getExtendedPoint(end, targetPosition, offset);

    // 1. Check for self-connection (same node)
    if (isSelfConnection(sourceNodeBounds, targetNodeBounds)) {
      return _calculateSelfConnectionWaypoints(
        start: start,
        end: end,
        startExtended: startExtended,
        endExtended: endExtended,
        sourcePosition: sourcePosition,
        targetPosition: targetPosition,
        backEdgeGap: loopbackGap,
        nodeBounds: sourceNodeBounds!,
      );
    }

    // 2. Check for collinear points (straight line possible)
    //    BUT only if the straight line doesn't intersect node bounds
    if (_arePointsCollinear(start, startExtended, endExtended, end)) {
      // Check if the straight line would pass through either node
      final straightLineValid = _isCollinearPathClear(
        startExtended: startExtended,
        endExtended: endExtended,
        sourceNodeBounds: sourceNodeBounds,
        targetNodeBounds: targetNodeBounds,
      );
      if (straightLineValid) {
        return [start, startExtended, endExtended, end];
      }
      // Collinear but blocked by nodes - fall through to routing logic
    }

    // 3. Check for same-side ports (e.g., right→right)
    if (_areSameSide(sourcePosition, targetPosition)) {
      return _calculateSameSideWaypoints(
        start: start,
        end: end,
        startExtended: startExtended,
        endExtended: endExtended,
        sourcePosition: sourcePosition,
        backEdgeGap: loopbackGap,
        sourceNodeBounds: sourceNodeBounds,
        targetNodeBounds: targetNodeBounds,
      );
    }

    // 4. Check for opposite-facing ports (right↔left, top↔bottom)
    //    These typically need S-bends, not L-shapes
    if (_areOppositePorts(sourcePosition, targetPosition)) {
      return _calculateOppositePortWaypoints(
        start: start,
        end: end,
        startExtended: startExtended,
        endExtended: endExtended,
        sourcePosition: sourcePosition,
        targetPosition: targetPosition,
        backEdgeGap: loopbackGap,
        sourceNodeBounds: sourceNodeBounds,
        targetNodeBounds: targetNodeBounds,
      );
    }

    // 5. Check for L-shape (single bend) - only for adjacent port combinations
    //    (e.g., right→top, right→bottom, left→top, etc.)
    if (_canFormLShape(
      startExtended: startExtended,
      endExtended: endExtended,
      sourcePosition: sourcePosition,
      targetPosition: targetPosition,
      sourceNodeBounds: sourceNodeBounds,
      targetNodeBounds: targetNodeBounds,
    )) {
      return _createLShapeWaypoints(
        start: start,
        end: end,
        startExtended: startExtended,
        endExtended: endExtended,
        sourcePosition: sourcePosition,
        targetPosition: targetPosition,
      );
    }

    // 6. Full routing with node avoidance (complex routing for adjacent ports)
    return _calculateFullRoutingWaypoints(
      start: start,
      end: end,
      startExtended: startExtended,
      endExtended: endExtended,
      sourcePosition: sourcePosition,
      targetPosition: targetPosition,
      backEdgeGap: loopbackGap,
      sourceNodeBounds: sourceNodeBounds,
      targetNodeBounds: targetNodeBounds,
    );
  }

  // ============================================================
  // Detection Methods
  // ============================================================

  /// Checks if source and target are the same node (self-connection).
  static bool isSelfConnection(Rect? sourceNodeBounds, Rect? targetNodeBounds) {
    if (sourceNodeBounds == null || targetNodeBounds == null) {
      return false;
    }
    // Consider it a self-connection if bounds are identical
    return sourceNodeBounds == targetNodeBounds;
  }

  /// Checks if two port positions are on the same side.
  static bool _areSameSide(
    PortPosition sourcePosition,
    PortPosition targetPosition,
  ) {
    return sourcePosition == targetPosition;
  }

  /// Checks if ports are on opposite sides (left↔right, top↔bottom).
  /// These port combinations typically need S-bend routing.
  static bool _areOppositePorts(
    PortPosition sourcePosition,
    PortPosition targetPosition,
  ) {
    return (sourcePosition == PortPosition.left &&
            targetPosition == PortPosition.right) ||
        (sourcePosition == PortPosition.right &&
            targetPosition == PortPosition.left) ||
        (sourcePosition == PortPosition.top &&
            targetPosition == PortPosition.bottom) ||
        (sourcePosition == PortPosition.bottom &&
            targetPosition == PortPosition.top);
  }

  /// Checks if a collinear path is clear (doesn't pass through node bounds).
  ///
  /// Even when ports are perfectly aligned, we can't draw a straight line
  /// if it would pass through either node. This is critical for loop-back
  /// scenarios where the target node might be directly between the ports.
  static bool _isCollinearPathClear({
    required Offset startExtended,
    required Offset endExtended,
    Rect? sourceNodeBounds,
    Rect? targetNodeBounds,
  }) {
    // Check if the line between extended points passes through source node
    if (sourceNodeBounds != null) {
      if (_lineIntersectsRect(startExtended, endExtended, sourceNodeBounds)) {
        return false;
      }
    }

    // Check if the line between extended points passes through target node
    if (targetNodeBounds != null) {
      if (_lineIntersectsRect(startExtended, endExtended, targetNodeBounds)) {
        return false;
      }
    }

    return true;
  }

  /// Checks if four points are collinear (can form a straight line).
  static bool _arePointsCollinear(Offset p1, Offset p2, Offset p3, Offset p4) {
    const tolerance = 1.0;

    // Check if all points share the same X (vertical line)
    final sameX =
        (p1.dx - p2.dx).abs() < tolerance &&
        (p2.dx - p3.dx).abs() < tolerance &&
        (p3.dx - p4.dx).abs() < tolerance;

    // Check if all points share the same Y (horizontal line)
    final sameY =
        (p1.dy - p2.dy).abs() < tolerance &&
        (p2.dy - p3.dy).abs() < tolerance &&
        (p3.dy - p4.dy).abs() < tolerance;

    return sameX || sameY;
  }

  /// Checks if an L-shape (single bend) is possible without crossing node bounds.
  static bool _canFormLShape({
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    Rect? sourceNodeBounds,
    Rect? targetNodeBounds,
  }) {
    // Same-side ports cannot form an L-shape
    if (_areSameSide(sourcePosition, targetPosition)) {
      return false;
    }

    // Calculate the corner point for the L-shape
    final cornerPoint = _getLShapeCorner(
      startExtended,
      endExtended,
      sourcePosition,
      targetPosition,
    );

    // Check if the L-shape path would cross any node bounds
    if (sourceNodeBounds != null) {
      if (_lineIntersectsRect(startExtended, cornerPoint, sourceNodeBounds) ||
          _lineIntersectsRect(cornerPoint, endExtended, sourceNodeBounds)) {
        return false;
      }
    }

    if (targetNodeBounds != null) {
      if (_lineIntersectsRect(startExtended, cornerPoint, targetNodeBounds) ||
          _lineIntersectsRect(cornerPoint, endExtended, targetNodeBounds)) {
        return false;
      }
    }

    // Also check horizontal/vertical clearance
    return _hasLShapeClearance(
      startExtended: startExtended,
      endExtended: endExtended,
      sourcePosition: sourcePosition,
      targetPosition: targetPosition,
    );
  }

  /// Checks if the extended points have proper clearance for L-shape routing.
  static bool _hasLShapeClearance({
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
  }) {
    // Check clearance based on source port position
    final hasHorizontalClearance = switch (sourcePosition) {
      PortPosition.right => startExtended.dx <= endExtended.dx,
      PortPosition.left => startExtended.dx >= endExtended.dx,
      PortPosition.top || PortPosition.bottom => true,
    };

    final hasVerticalClearance = switch (sourcePosition) {
      PortPosition.bottom => startExtended.dy <= endExtended.dy,
      PortPosition.top => startExtended.dy >= endExtended.dy,
      PortPosition.left || PortPosition.right => true,
    };

    return hasHorizontalClearance && hasVerticalClearance;
  }

  // ============================================================
  // Waypoint Calculation Methods
  // ============================================================

  /// Gets the extended point from a port in its facing direction.
  ///
  /// This ensures connections always start by moving OUTWARD from the port.
  static Offset getExtendedPoint(
    Offset point,
    PortPosition position,
    double offset,
  ) {
    return switch (position) {
      PortPosition.right => Offset(point.dx + offset, point.dy),
      PortPosition.left => Offset(point.dx - offset, point.dy),
      PortPosition.top => Offset(point.dx, point.dy - offset),
      PortPosition.bottom => Offset(point.dx, point.dy + offset),
    };
  }

  /// Calculates the corner point for an L-shape path.
  static Offset _getLShapeCorner(
    Offset startExtended,
    Offset endExtended,
    PortPosition sourcePosition,
    PortPosition targetPosition,
  ) {
    // For horizontal source ports, corner is at (startExtended.dx, endExtended.dy)
    // For vertical source ports, corner is at (endExtended.dx, startExtended.dy)
    return switch (sourcePosition) {
      PortPosition.left ||
      PortPosition.right => Offset(startExtended.dx, endExtended.dy),
      PortPosition.top ||
      PortPosition.bottom => Offset(endExtended.dx, startExtended.dy),
    };
  }

  /// Creates waypoints for an L-shape (single bend) path.
  static List<Offset> _createLShapeWaypoints({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
  }) {
    final cornerPoint = _getLShapeCorner(
      startExtended,
      endExtended,
      sourcePosition,
      targetPosition,
    );

    return [start, startExtended, cornerPoint, endExtended, end];
  }

  /// Calculates waypoints for same-side ports (e.g., right→right).
  ///
  /// Routes past the union of node bounds to ensure clearance.
  static List<Offset> _calculateSameSideWaypoints({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required double backEdgeGap,
    Rect? sourceNodeBounds,
    Rect? targetNodeBounds,
  }) {
    // Calculate union of node bounds if available
    final unionBounds = _getUnionBounds(sourceNodeBounds, targetNodeBounds);

    return switch (sourcePosition) {
      PortPosition.right => _sameSideRight(
        start,
        end,
        startExtended,
        endExtended,
        backEdgeGap,
        unionBounds,
      ),
      PortPosition.left => _sameSideLeft(
        start,
        end,
        startExtended,
        endExtended,
        backEdgeGap,
        unionBounds,
      ),
      PortPosition.top => _sameSideTop(
        start,
        end,
        startExtended,
        endExtended,
        backEdgeGap,
        unionBounds,
      ),
      PortPosition.bottom => _sameSideBottom(
        start,
        end,
        startExtended,
        endExtended,
        backEdgeGap,
        unionBounds,
      ),
    };
  }

  static List<Offset> _sameSideRight(
    Offset start,
    Offset end,
    Offset startExtended,
    Offset endExtended,
    double backEdgeGap,
    Rect? unionBounds,
  ) {
    // Route past the right edge of both nodes
    final routeX = unionBounds != null
        ? unionBounds.right + backEdgeGap
        : math.max(startExtended.dx, endExtended.dx) + backEdgeGap;

    return [
      start,
      startExtended,
      Offset(routeX, startExtended.dy),
      Offset(routeX, endExtended.dy),
      endExtended,
      end,
    ];
  }

  static List<Offset> _sameSideLeft(
    Offset start,
    Offset end,
    Offset startExtended,
    Offset endExtended,
    double backEdgeGap,
    Rect? unionBounds,
  ) {
    // Route past the left edge of both nodes
    final routeX = unionBounds != null
        ? unionBounds.left - backEdgeGap
        : math.min(startExtended.dx, endExtended.dx) - backEdgeGap;

    return [
      start,
      startExtended,
      Offset(routeX, startExtended.dy),
      Offset(routeX, endExtended.dy),
      endExtended,
      end,
    ];
  }

  static List<Offset> _sameSideTop(
    Offset start,
    Offset end,
    Offset startExtended,
    Offset endExtended,
    double backEdgeGap,
    Rect? unionBounds,
  ) {
    // Route past the top edge of both nodes
    final routeY = unionBounds != null
        ? unionBounds.top - backEdgeGap
        : math.min(startExtended.dy, endExtended.dy) - backEdgeGap;

    return [
      start,
      startExtended,
      Offset(startExtended.dx, routeY),
      Offset(endExtended.dx, routeY),
      endExtended,
      end,
    ];
  }

  static List<Offset> _sameSideBottom(
    Offset start,
    Offset end,
    Offset startExtended,
    Offset endExtended,
    double backEdgeGap,
    Rect? unionBounds,
  ) {
    // Route past the bottom edge of both nodes
    final routeY = unionBounds != null
        ? unionBounds.bottom + backEdgeGap
        : math.max(startExtended.dy, endExtended.dy) + backEdgeGap;

    return [
      start,
      startExtended,
      Offset(startExtended.dx, routeY),
      Offset(endExtended.dx, routeY),
      endExtended,
      end,
    ];
  }

  /// Calculates waypoints for opposite-facing ports (right↔left, top↔bottom).
  ///
  /// These connections typically use S-bends when there's enough space,
  /// or route around nodes when space is limited.
  static List<Offset> _calculateOppositePortWaypoints({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    required double backEdgeGap,
    Rect? sourceNodeBounds,
    Rect? targetNodeBounds,
  }) {
    final unionBounds = _getUnionBounds(sourceNodeBounds, targetNodeBounds);

    // Determine if this is a horizontal (left↔right) or vertical (top↔bottom) connection
    final isHorizontal =
        sourcePosition == PortPosition.left ||
        sourcePosition == PortPosition.right;

    if (isHorizontal) {
      return _calculateHorizontalOppositeWaypoints(
        start: start,
        end: end,
        startExtended: startExtended,
        endExtended: endExtended,
        sourcePosition: sourcePosition,
        backEdgeGap: backEdgeGap,
        unionBounds: unionBounds,
      );
    } else {
      return _calculateVerticalOppositeWaypoints(
        start: start,
        end: end,
        startExtended: startExtended,
        endExtended: endExtended,
        sourcePosition: sourcePosition,
        backEdgeGap: backEdgeGap,
        unionBounds: unionBounds,
      );
    }
  }

  /// Calculates S-bend waypoints for horizontal opposite ports (right↔left).
  static List<Offset> _calculateHorizontalOppositeWaypoints({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required double backEdgeGap,
    Rect? unionBounds,
  }) {
    // Determine if there's enough horizontal space for an S-bend
    final hasHorizontalClearance = sourcePosition == PortPosition.right
        ? startExtended.dx < endExtended.dx
        : startExtended.dx > endExtended.dx;

    if (hasHorizontalClearance) {
      // S-bend: go through the horizontal middle
      final midX = (startExtended.dx + endExtended.dx) / 2;
      return [
        start,
        startExtended,
        Offset(midX, startExtended.dy),
        Offset(midX, endExtended.dy),
        endExtended,
        end,
      ];
    } else {
      // No horizontal clearance - prefer S-curve through vertical midpoint
      // over looping around nodes when possible
      final midY = (startExtended.dy + endExtended.dy) / 2;

      // Check if an S-curve through midY would intersect node bounds
      final sCurveWaypoints = [
        start,
        startExtended,
        Offset(startExtended.dx, midY),
        Offset(endExtended.dx, midY),
        endExtended,
        end,
      ];

      // Only route around if the S-curve would intersect the union bounds
      if (unionBounds != null) {
        final sCurveIntersects = _waypointsIntersectBounds(
          sCurveWaypoints,
          unionBounds,
        );

        if (sCurveIntersects) {
          // S-curve would intersect - route around (above or below)
          final routeAbove = end.dy < start.dy;
          final routeY = routeAbove
              ? unionBounds.top - backEdgeGap
              : unionBounds.bottom + backEdgeGap;
          return [
            start,
            startExtended,
            Offset(startExtended.dx, routeY),
            Offset(endExtended.dx, routeY),
            endExtended,
            end,
          ];
        }
      }

      // S-curve is clear or no bounds to check - use it
      return sCurveWaypoints;
    }
  }

  /// Calculates S-bend waypoints for vertical opposite ports (top↔bottom).
  static List<Offset> _calculateVerticalOppositeWaypoints({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required double backEdgeGap,
    Rect? unionBounds,
  }) {
    // Determine if there's enough vertical space for an S-bend
    final hasVerticalClearance = sourcePosition == PortPosition.bottom
        ? startExtended.dy < endExtended.dy
        : startExtended.dy > endExtended.dy;

    if (hasVerticalClearance) {
      // S-bend: go through the vertical middle
      final midY = (startExtended.dy + endExtended.dy) / 2;
      return [
        start,
        startExtended,
        Offset(startExtended.dx, midY),
        Offset(endExtended.dx, midY),
        endExtended,
        end,
      ];
    } else {
      // No vertical clearance - prefer S-curve through horizontal midpoint
      // over looping around nodes when possible
      final midX = (startExtended.dx + endExtended.dx) / 2;

      // Check if an S-curve through midX would intersect node bounds
      final sCurveWaypoints = [
        start,
        startExtended,
        Offset(midX, startExtended.dy),
        Offset(midX, endExtended.dy),
        endExtended,
        end,
      ];

      // Only route around if the S-curve would intersect the union bounds
      if (unionBounds != null) {
        final sCurveIntersects = _waypointsIntersectBounds(
          sCurveWaypoints,
          unionBounds,
        );

        if (sCurveIntersects) {
          // S-curve would intersect - route around (left or right)
          final routeLeft = end.dx < start.dx;
          final routeX = routeLeft
              ? unionBounds.left - backEdgeGap
              : unionBounds.right + backEdgeGap;
          return [
            start,
            startExtended,
            Offset(routeX, startExtended.dy),
            Offset(routeX, endExtended.dy),
            endExtended,
            end,
          ];
        }
      }

      // S-curve is clear or no bounds to check - use it
      return sCurveWaypoints;
    }
  }

  /// Calculates waypoints for self-connections (node to itself).
  ///
  /// Routes around the node's own bounds.
  static List<Offset> _calculateSelfConnectionWaypoints({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    required double backEdgeGap,
    required Rect nodeBounds,
  }) {
    // Determine the best direction to route based on port positions
    final direction = _determineSelfConnectionDirection(
      sourcePosition: sourcePosition,
      targetPosition: targetPosition,
      nodeBounds: nodeBounds,
      startExtended: startExtended,
      endExtended: endExtended,
    );

    return _routeAroundBounds(
      start: start,
      end: end,
      startExtended: startExtended,
      endExtended: endExtended,
      bounds: nodeBounds,
      direction: direction,
      backEdgeGap: backEdgeGap,
    );
  }

  /// Determines the best direction for a self-connection.
  static LoopbackDirection _determineSelfConnectionDirection({
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    required Rect nodeBounds,
    required Offset startExtended,
    required Offset endExtended,
  }) {
    // For horizontal ports (left/right), prefer vertical routing
    // For vertical ports (top/bottom), prefer horizontal routing
    final isHorizontalSource =
        sourcePosition == PortPosition.left ||
        sourcePosition == PortPosition.right;
    final isHorizontalTarget =
        targetPosition == PortPosition.left ||
        targetPosition == PortPosition.right;

    if (isHorizontalSource && isHorizontalTarget) {
      // Both horizontal - route above or below
      // Prefer the direction with more space or based on relative port positions
      if (startExtended.dy < nodeBounds.center.dy &&
          endExtended.dy < nodeBounds.center.dy) {
        return LoopbackDirection.above;
      } else if (startExtended.dy > nodeBounds.center.dy &&
          endExtended.dy > nodeBounds.center.dy) {
        return LoopbackDirection.below;
      }
      return LoopbackDirection.below; // Default to below
    } else if (!isHorizontalSource && !isHorizontalTarget) {
      // Both vertical - route left or right
      if (startExtended.dx < nodeBounds.center.dx &&
          endExtended.dx < nodeBounds.center.dx) {
        return LoopbackDirection.left;
      } else if (startExtended.dx > nodeBounds.center.dx &&
          endExtended.dx > nodeBounds.center.dx) {
        return LoopbackDirection.right;
      }
      return LoopbackDirection.right; // Default to right
    } else {
      // Mixed orientation - choose based on port positions
      if (sourcePosition == PortPosition.right ||
          targetPosition == PortPosition.right) {
        return LoopbackDirection.right;
      } else if (sourcePosition == PortPosition.left ||
          targetPosition == PortPosition.left) {
        return LoopbackDirection.left;
      } else if (sourcePosition == PortPosition.bottom ||
          targetPosition == PortPosition.bottom) {
        return LoopbackDirection.below;
      }
      return LoopbackDirection.above;
    }
  }

  /// Calculates waypoints for full routing scenarios (loop-back, complex routing).
  static List<Offset> _calculateFullRoutingWaypoints({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    required double backEdgeGap,
    Rect? sourceNodeBounds,
    Rect? targetNodeBounds,
  }) {
    // Calculate union of node bounds for avoidance
    final unionBounds = _getUnionBounds(sourceNodeBounds, targetNodeBounds);

    // If no bounds available, use midpoint-based routing
    if (unionBounds == null) {
      return _fallbackFullRouting(
        start: start,
        end: end,
        startExtended: startExtended,
        endExtended: endExtended,
        sourcePosition: sourcePosition,
        targetPosition: targetPosition,
      );
    }

    // Determine the best direction to route around the union
    final direction = _determineLoopbackDirection(
      start: start,
      end: end,
      startExtended: startExtended,
      endExtended: endExtended,
      sourcePosition: sourcePosition,
      targetPosition: targetPosition,
      unionBounds: unionBounds,
    );

    return _routeAroundBounds(
      start: start,
      end: end,
      startExtended: startExtended,
      endExtended: endExtended,
      bounds: unionBounds,
      direction: direction,
      backEdgeGap: backEdgeGap,
    );
  }

  /// Determines the optimal direction for loop-back routing.
  ///
  /// The direction is constrained by the TARGET port's required approach direction:
  /// - TOP port: must approach from above
  /// - BOTTOM port: must approach from below
  /// - LEFT port: must approach from the left
  /// - RIGHT port: must approach from the right
  ///
  /// When both source and target allow flexibility, we choose based on position.
  static LoopbackDirection _determineLoopbackDirection({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    required Rect unionBounds,
  }) {
    // TARGET port direction is a hard constraint - the connection must approach
    // from the direction the port faces. This ensures connections never cross
    // behind the target node relative to the port.
    switch (targetPosition) {
      case PortPosition.top:
        // Must approach from above
        return LoopbackDirection.above;
      case PortPosition.bottom:
        // Must approach from below
        return LoopbackDirection.below;
      case PortPosition.left:
        // Must approach from the left
        return LoopbackDirection.left;
      case PortPosition.right:
        // Must approach from the right
        return LoopbackDirection.right;
    }
  }

  /// Routes around bounds in the specified direction.
  static List<Offset> _routeAroundBounds({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required Rect bounds,
    required LoopbackDirection direction,
    required double backEdgeGap,
  }) {
    switch (direction) {
      case LoopbackDirection.above:
        final routeY = bounds.top - backEdgeGap;
        return [
          start,
          startExtended,
          Offset(startExtended.dx, routeY),
          Offset(endExtended.dx, routeY),
          endExtended,
          end,
        ];
      case LoopbackDirection.below:
        final routeY = bounds.bottom + backEdgeGap;
        return [
          start,
          startExtended,
          Offset(startExtended.dx, routeY),
          Offset(endExtended.dx, routeY),
          endExtended,
          end,
        ];
      case LoopbackDirection.left:
        final routeX = bounds.left - backEdgeGap;
        return [
          start,
          startExtended,
          Offset(routeX, startExtended.dy),
          Offset(routeX, endExtended.dy),
          endExtended,
          end,
        ];
      case LoopbackDirection.right:
        final routeX = bounds.right + backEdgeGap;
        return [
          start,
          startExtended,
          Offset(routeX, startExtended.dy),
          Offset(routeX, endExtended.dy),
          endExtended,
          end,
        ];
    }
  }

  /// Fallback routing using midpoint when node bounds are not available.
  static List<Offset> _fallbackFullRouting({
    required Offset start,
    required Offset end,
    required Offset startExtended,
    required Offset endExtended,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
  }) {
    // Use midpoint-based routing as fallback
    final isHorizontalSource =
        sourcePosition == PortPosition.left ||
        sourcePosition == PortPosition.right;

    if (isHorizontalSource) {
      final midY = (startExtended.dy + endExtended.dy) / 2;
      return [
        start,
        startExtended,
        Offset(startExtended.dx, midY),
        Offset(endExtended.dx, midY),
        endExtended,
        end,
      ];
    } else {
      final midX = (startExtended.dx + endExtended.dx) / 2;
      return [
        start,
        startExtended,
        Offset(midX, startExtended.dy),
        Offset(midX, endExtended.dy),
        endExtended,
        end,
      ];
    }
  }

  // ============================================================
  // Utility Methods
  // ============================================================

  /// Calculates the union of two node bounds.
  static Rect? _getUnionBounds(Rect? sourceNodeBounds, Rect? targetNodeBounds) {
    if (sourceNodeBounds == null && targetNodeBounds == null) {
      return null;
    }
    if (sourceNodeBounds == null) {
      return targetNodeBounds;
    }
    if (targetNodeBounds == null) {
      return sourceNodeBounds;
    }
    return sourceNodeBounds.expandToInclude(targetNodeBounds);
  }

  /// Checks if a line segment intersects a rectangle.
  /// Checks if any segment of the waypoints path intersects the given bounds.
  ///
  /// Skips the first and last segments (port to extended point) since those
  /// are expected to be near the nodes.
  static bool _waypointsIntersectBounds(List<Offset> waypoints, Rect bounds) {
    if (waypoints.length < 4) return false;

    // Check middle segments (skip first and last which connect to ports)
    for (int i = 1; i < waypoints.length - 2; i++) {
      if (_lineIntersectsRect(waypoints[i], waypoints[i + 1], bounds)) {
        return true;
      }
    }
    return false;
  }

  static bool _lineIntersectsRect(Offset p1, Offset p2, Rect rect) {
    // If either endpoint is inside the rect, it intersects
    if (rect.contains(p1) || rect.contains(p2)) {
      return true;
    }

    // Check if line crosses any of the four edges
    return _lineSegmentsIntersect(p1, p2, rect.topLeft, rect.topRight) ||
        _lineSegmentsIntersect(p1, p2, rect.topRight, rect.bottomRight) ||
        _lineSegmentsIntersect(p1, p2, rect.bottomRight, rect.bottomLeft) ||
        _lineSegmentsIntersect(p1, p2, rect.bottomLeft, rect.topLeft);
  }

  /// Checks if two line segments intersect.
  static bool _lineSegmentsIntersect(
    Offset p1,
    Offset p2,
    Offset p3,
    Offset p4,
  ) {
    final d1 = _crossProduct(p3, p4, p1);
    final d2 = _crossProduct(p3, p4, p2);
    final d3 = _crossProduct(p1, p2, p3);
    final d4 = _crossProduct(p1, p2, p4);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }

    const epsilon = 0.0001;
    if (d1.abs() < epsilon && _onSegment(p3, p4, p1)) return true;
    if (d2.abs() < epsilon && _onSegment(p3, p4, p2)) return true;
    if (d3.abs() < epsilon && _onSegment(p1, p2, p3)) return true;
    if (d4.abs() < epsilon && _onSegment(p1, p2, p4)) return true;

    return false;
  }

  /// Cross product for three points.
  static double _crossProduct(Offset a, Offset b, Offset c) {
    return (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
  }

  /// Checks if point p lies on segment ab.
  static bool _onSegment(Offset a, Offset b, Offset p) {
    return p.dx <= math.max(a.dx, b.dx) &&
        p.dx >= math.min(a.dx, b.dx) &&
        p.dy <= math.max(a.dy, b.dy) &&
        p.dy >= math.min(a.dy, b.dy);
  }

  /// Optimizes waypoints by removing collinear intermediate points.
  static List<Offset> optimizeWaypoints(List<Offset> waypoints) {
    if (waypoints.length <= 2) return waypoints;

    final optimized = <Offset>[waypoints.first];

    for (int i = 1; i < waypoints.length - 1; i++) {
      final prev = optimized.last;
      final current = waypoints[i];
      final next = waypoints[i + 1];

      // Check if current point is NOT collinear with prev and next
      if (!_isCollinear(prev, current, next)) {
        optimized.add(current);
      }
    }

    optimized.add(waypoints.last);
    return optimized;
  }

  /// Checks if three points are collinear.
  static bool _isCollinear(Offset a, Offset b, Offset c) {
    const tolerance = 0.5;

    // Check for horizontal alignment
    if ((a.dy - b.dy).abs() < tolerance && (b.dy - c.dy).abs() < tolerance) {
      return true;
    }

    // Check for vertical alignment
    if ((a.dx - b.dx).abs() < tolerance && (b.dx - c.dx).abs() < tolerance) {
      return true;
    }

    return false;
  }

  // ============================================================
  // Path Generation from Waypoints
  // ============================================================

  /// Generates a Path from waypoints with optional rounded corners.
  ///
  /// This is the central path generation method that all connection styles
  /// can use for waypoint-based paths (loopback, step, etc.).
  ///
  /// Parameters:
  /// - [waypoints]: The list of points the path passes through
  /// - [cornerRadius]: Radius for rounding corners (0 for sharp corners)
  static Path generatePathFromWaypoints(
    List<Offset> waypoints, {
    double cornerRadius = 0,
  }) {
    if (waypoints.length < 2) {
      return Path();
    }

    final path = Path();
    path.moveTo(waypoints.first.dx, waypoints.first.dy);

    if (waypoints.length == 2) {
      path.lineTo(waypoints.last.dx, waypoints.last.dy);
      return path;
    }

    // If corner radius is 0, just draw straight lines
    if (cornerRadius == 0) {
      for (int i = 1; i < waypoints.length; i++) {
        path.lineTo(waypoints[i].dx, waypoints[i].dy);
      }
      return path;
    }

    // Draw path with rounded corners at waypoints
    for (int i = 1; i < waypoints.length - 1; i++) {
      final prev = waypoints[i - 1];
      final current = waypoints[i];
      final next = waypoints[i + 1];

      // Calculate vectors
      final incomingVector = current - prev;
      final outgoingVector = next - current;

      // Skip if vectors are zero (duplicate points)
      if (incomingVector.distance < 0.01 || outgoingVector.distance < 0.01) {
        path.lineTo(current.dx, current.dy);
        continue;
      }

      // Check if this is a corner (perpendicular segments)
      final incomingHorizontal = incomingVector.dy.abs() < 0.01;
      final incomingVertical = incomingVector.dx.abs() < 0.01;
      final outgoingHorizontal = outgoingVector.dy.abs() < 0.01;
      final outgoingVertical = outgoingVector.dx.abs() < 0.01;

      // Only round corners between perpendicular segments
      if ((incomingHorizontal && outgoingVertical) ||
          (incomingVertical && outgoingHorizontal)) {
        final incomingDistance = incomingVector.distance;
        final outgoingDistance = outgoingVector.distance;

        // Adapt corner radius to available space
        final maxRadius = math.min(incomingDistance / 2, outgoingDistance / 2);
        final actualRadius = math.min(cornerRadius, maxRadius);

        if (actualRadius < 1.0) {
          path.lineTo(current.dx, current.dy);
          continue;
        }

        // Calculate unit vectors
        final incomingDirection = incomingVector / incomingDistance;
        final outgoingDirection = outgoingVector / outgoingDistance;

        // Calculate corner start and end points
        final cornerStart = current - (incomingDirection * actualRadius);
        final cornerEnd = current + (outgoingDirection * actualRadius);

        // Draw line to corner start
        path.lineTo(cornerStart.dx, cornerStart.dy);

        // Draw quadratic bezier curve for the corner
        path.quadraticBezierTo(
          current.dx,
          current.dy,
          cornerEnd.dx,
          cornerEnd.dy,
        );
      } else {
        // Not a perpendicular corner, just draw straight line
        path.lineTo(current.dx, current.dy);
      }
    }

    // Draw line to the last point
    path.lineTo(waypoints.last.dx, waypoints.last.dy);

    return path;
  }

  // ============================================================
  // Hit Test Segment Generation
  // ============================================================

  /// Generates hit test segments from waypoints.
  ///
  /// For waypoint-based paths (step, loopback), the hit test segments
  /// are simple axis-aligned rectangles around each straight segment.
  /// This is much more efficient than curve sampling.
  ///
  /// Parameters:
  /// - [waypoints]: The list of waypoints
  /// - [tolerance]: The hit test tolerance (rectangle will extend this far)
  static List<Rect> generateHitTestSegments(
    List<Offset> waypoints,
    double tolerance,
  ) {
    if (waypoints.length < 2) return [];

    // Merge collinear segments to minimize rectangle count
    final mergedSegments = _mergeCollinearSegments(waypoints);

    return mergedSegments.map((segment) {
      return Rect.fromLTRB(
        math.min(segment.start.dx, segment.end.dx) - tolerance,
        math.min(segment.start.dy, segment.end.dy) - tolerance,
        math.max(segment.start.dx, segment.end.dx) + tolerance,
        math.max(segment.start.dy, segment.end.dy) + tolerance,
      );
    }).toList();
  }

  /// Merges consecutive collinear segments to reduce rectangle count.
  ///
  /// For example: [A→B→C] where A, B, C are on same line becomes [A→C]
  static List<({Offset start, Offset end})> _mergeCollinearSegments(
    List<Offset> waypoints,
  ) {
    if (waypoints.length < 2) return [];

    final segments = <({Offset start, Offset end})>[];
    Offset segmentStart = waypoints[0];

    for (int i = 1; i < waypoints.length; i++) {
      final current = waypoints[i];
      bool shouldEndSegment = (i == waypoints.length - 1);

      if (!shouldEndSegment && i < waypoints.length - 1) {
        final next = waypoints[i + 1];

        final currentVector = current - segmentStart;
        final nextVector = next - current;

        final currentIsHorizontal = currentVector.dy.abs() < 0.5;
        final currentIsVertical = currentVector.dx.abs() < 0.5;
        final nextIsHorizontal = nextVector.dy.abs() < 0.5;
        final nextIsVertical = nextVector.dx.abs() < 0.5;

        // If direction changes, end this segment
        shouldEndSegment =
            (currentIsHorizontal != nextIsHorizontal) ||
            (currentIsVertical != nextIsVertical);
      }

      if (shouldEndSegment) {
        segments.add((start: segmentStart, end: current));
        segmentStart = current;
      }
    }

    return segments;
  }

  // ============================================================
  // Segment-Based Path Generation
  // ============================================================

  /// Generates a [Path] from a list of [PathSegment]s.
  ///
  /// This is the core method for building paths from segment primitives.
  /// Each segment type is handled according to its definition:
  /// - [StraightSegment]: `lineTo`
  /// - [QuadraticSegment]: `quadraticBezierTo`
  /// - [CubicSegment]: `cubicTo`
  ///
  /// ## Example
  /// ```dart
  /// final path = WaypointBuilder.generatePathFromSegments(
  ///   start: Offset(0, 0),
  ///   segments: [
  ///     StraightSegment(end: Offset(50, 0)),
  ///     QuadraticSegment(controlPoint: Offset(60, 0), end: Offset(60, 10)),
  ///     StraightSegment(end: Offset(60, 100)),
  ///   ],
  /// );
  /// ```
  static Path generatePathFromSegments({
    required Offset start,
    required List<PathSegment> segments,
  }) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    for (final segment in segments) {
      switch (segment) {
        case StraightSegment():
          path.lineTo(segment.end.dx, segment.end.dy);
        case QuadraticSegment():
          path.quadraticBezierTo(
            segment.controlPoint.dx,
            segment.controlPoint.dy,
            segment.end.dx,
            segment.end.dy,
          );
        case CubicSegment():
          path.cubicTo(
            segment.controlPoint1.dx,
            segment.controlPoint1.dy,
            segment.controlPoint2.dx,
            segment.controlPoint2.dy,
            segment.end.dx,
            segment.end.dy,
          );
      }
    }

    return path;
  }

  // ============================================================
  // Segment-Based Hit Test Generation
  // ============================================================

  /// Generates hit test rectangles from a list of [PathSegment]s.
  ///
  /// Different segment types have different hit test strategies:
  /// - [StraightSegment]: Single rectangle around the line
  /// - [QuadraticSegment]: Sample points along the curve
  /// - [CubicSegment]: Sample points along the curve
  ///
  /// This method ensures tight hit test areas that follow the actual
  /// path geometry, minimizing false positives from oversized rectangles.
  ///
  /// Parameters:
  /// - [start]: The starting point of the path
  /// - [segments]: The list of path segments
  /// - [tolerance]: The hit test tolerance (rectangles extend this far from path)
  static List<Rect> generateHitTestFromSegments({
    required Offset start,
    required List<PathSegment> segments,
    required double tolerance,
  }) {
    if (segments.isEmpty) return [];

    final hitRects = <Rect>[];
    Offset currentPoint = start;

    for (final segment in segments) {
      // Each segment knows how to generate its own hit test rectangles
      hitRects.addAll(segment.getHitTestRects(currentPoint, tolerance));
      currentPoint = segment.end;
    }

    return hitRects;
  }

  // ============================================================
  // Segment Builders - Convert Waypoints to Segments
  // ============================================================

  /// Converts waypoints to path segments with optional rounded corners.
  ///
  /// This method transforms a list of waypoints into [PathSegment]s,
  /// inserting [QuadraticSegment]s at corners when [cornerRadius] > 0.
  ///
  /// This is useful for step/smoothstep styles that use waypoint-based
  /// routing but want the flexibility of the segment-based API.
  ///
  /// Parameters:
  /// - [waypoints]: The list of points to convert
  /// - [cornerRadius]: Radius for rounded corners (0 for sharp corners)
  static List<PathSegment> waypointsToSegments(
    List<Offset> waypoints, {
    double cornerRadius = 0,
  }) {
    if (waypoints.length < 2) return [];

    final segments = <PathSegment>[];

    if (waypoints.length == 2) {
      segments.add(StraightSegment(end: waypoints[1]));
      return segments;
    }

    // No corner radius - all straight segments
    if (cornerRadius <= 0) {
      for (int i = 1; i < waypoints.length; i++) {
        segments.add(StraightSegment(end: waypoints[i]));
      }
      return segments;
    }

    // Build segments with rounded corners
    for (int i = 1; i < waypoints.length - 1; i++) {
      final prev = i == 1 ? waypoints[0] : segments.last.end;
      final current = waypoints[i];
      final next = waypoints[i + 1];

      // Calculate vectors
      final incomingVector = current - prev;
      final outgoingVector = next - current;

      // Skip if vectors are too short
      if (incomingVector.distance < 0.01 || outgoingVector.distance < 0.01) {
        segments.add(StraightSegment(end: current));
        continue;
      }

      // Check if this is a perpendicular corner
      final incomingHorizontal = incomingVector.dy.abs() < 0.01;
      final incomingVertical = incomingVector.dx.abs() < 0.01;
      final outgoingHorizontal = outgoingVector.dy.abs() < 0.01;
      final outgoingVertical = outgoingVector.dx.abs() < 0.01;

      if ((incomingHorizontal && outgoingVertical) ||
          (incomingVertical && outgoingHorizontal)) {
        // Calculate corner radius that fits available space
        final maxRadius = math.min(
          incomingVector.distance / 2,
          outgoingVector.distance / 2,
        );
        final actualRadius = math.min(cornerRadius, maxRadius);

        if (actualRadius < 1.0) {
          segments.add(StraightSegment(end: current));
          continue;
        }

        // Calculate corner start and end
        final inDir = incomingVector / incomingVector.distance;
        final outDir = outgoingVector / outgoingVector.distance;
        final cornerStart = current - (inDir * actualRadius);
        final cornerEnd = current + (outDir * actualRadius);

        // Add straight segment to corner start
        segments.add(StraightSegment(end: cornerStart));

        // Add quadratic curve for the corner
        // Skip hit test rects - corner is already covered by adjacent straight segments
        segments.add(
          QuadraticSegment(
            controlPoint: current,
            end: cornerEnd,
            generateHitTestRects: false,
          ),
        );
      } else {
        // Not a perpendicular corner - straight line
        segments.add(StraightSegment(end: current));
      }
    }

    // Add final segment
    segments.add(StraightSegment(end: waypoints.last));

    return segments;
  }

  /// Creates a single cubic bezier segment for a forward connection.
  ///
  /// This is a convenience method for styles that use cubic bezier curves
  /// for forward (non-loopback) connections.
  ///
  /// Parameters:
  /// - [start]: The start point
  /// - [end]: The end point
  /// - [sourcePosition]: The position of the source port
  /// - [targetPosition]: The position of the target port
  /// - [curvature]: How curved the connection should be (0-1)
  /// - [portExtension]: The minimum extension from the port
  static CubicSegment createBezierSegment({
    required Offset start,
    required Offset end,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    required double curvature,
    required double portExtension,
  }) {
    // Calculate control points based on port positions
    final cp1 = _calculateBezierControlPoint(
      anchor: start,
      target: end,
      position: sourcePosition,
      curvature: curvature,
      portExtension: portExtension,
    );

    final cp2 = _calculateBezierControlPoint(
      anchor: end,
      target: start,
      position: targetPosition,
      curvature: curvature,
      portExtension: portExtension,
    );

    return CubicSegment(
      controlPoint1: cp1,
      controlPoint2: cp2,
      end: end,
      curvature: curvature,
    );
  }

  /// Calculates a bezier control point for a port.
  ///
  /// Matches React Flow's bezier calculation:
  /// offset = |distance| * curvature
  ///
  /// For horizontal ports, offset is based on horizontal distance.
  /// For vertical ports, offset is based on vertical distance.
  static Offset _calculateBezierControlPoint({
    required Offset anchor,
    required Offset target,
    required PortPosition position,
    required double curvature,
    required double portExtension,
  }) {
    // React Flow style: offset = |distance| * curvature
    // portExtension ensures minimum offset for very close nodes
    switch (position) {
      case PortPosition.right:
        final offset = math.max(
          portExtension,
          (target.dx - anchor.dx).abs() * curvature,
        );
        return Offset(anchor.dx + offset, anchor.dy);

      case PortPosition.left:
        final offset = math.max(
          portExtension,
          (target.dx - anchor.dx).abs() * curvature,
        );
        return Offset(anchor.dx - offset, anchor.dy);

      case PortPosition.bottom:
        final offset = math.max(
          portExtension,
          (target.dy - anchor.dy).abs() * curvature,
        );
        return Offset(anchor.dx, anchor.dy + offset);

      case PortPosition.top:
        final offset = math.max(
          portExtension,
          (target.dy - anchor.dy).abs() * curvature,
        );
        return Offset(anchor.dx, anchor.dy - offset);
    }
  }
}
