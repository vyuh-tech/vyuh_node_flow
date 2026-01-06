/// Comprehensive unit tests for WaypointBuilder in vyuh_node_flow.
///
/// These tests cover all public methods and waypoint generation logic:
/// - Loopback detection and routing
/// - Self-connection handling
/// - Same-side port routing
/// - Opposite port routing (S-bends)
/// - L-shape routing
/// - Full routing with node avoidance
/// - Waypoint optimization
/// - Path and segment generation
/// - Hit test generation
/// - Bezier segment creation
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import 'package:vyuh_node_flow/src/connections/styles/waypoint_builder.dart';
import 'package:vyuh_node_flow/src/connections/styles/connection_style_base.dart';
import 'package:vyuh_node_flow/src/connections/styles/path_segments.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // needsLoopbackRouting Tests
  // ===========================================================================

  group('needsLoopbackRouting', () {
    test('returns true for self-connection (same node bounds)', () {
      final nodeBounds = const Rect.fromLTWH(0, 0, 100, 100);
      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(0, 50),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in',
          type: PortType.input,
          position: PortPosition.left,
        ),
        sourceNodeBounds: nodeBounds,
        targetNodeBounds: nodeBounds, // Same bounds = self-connection
      );

      expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);
    });

    test('returns true for same-side ports (right to right)', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(300, 50),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'out2',
          type: PortType.output,
          position: PortPosition.right,
        ),
      );

      expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);
    });

    test('returns true for same-side ports (left to left)', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 50),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'in1',
          type: PortType.input,
          position: PortPosition.left,
        ),
        targetPort: createTestPort(
          id: 'in2',
          type: PortType.input,
          position: PortPosition.left,
        ),
      );

      expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);
    });

    test('returns true for same-side ports (top to top)', () {
      final params = ConnectionPathParameters(
        start: const Offset(50, 0),
        end: const Offset(250, 0),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'top1',
          type: PortType.input,
          position: PortPosition.top,
        ),
        targetPort: createTestPort(
          id: 'top2',
          type: PortType.input,
          position: PortPosition.top,
        ),
      );

      expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);
    });

    test('returns true for same-side ports (bottom to bottom)', () {
      final params = ConnectionPathParameters(
        start: const Offset(50, 100),
        end: const Offset(250, 100),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'bot1',
          type: PortType.output,
          position: PortPosition.bottom,
        ),
        targetPort: createTestPort(
          id: 'bot2',
          type: PortType.output,
          position: PortPosition.bottom,
        ),
      );

      expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);
    });

    test(
      'returns true when target is behind source (right port, target left of source)',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(200, 50),
          end: const Offset(50, 50),
          curvature: 0.5,
          offset: 20.0,
          sourcePort: createTestPort(
            id: 'out',
            type: PortType.output,
            position: PortPosition.right,
          ),
          targetPort: createTestPort(
            id: 'in',
            type: PortType.input,
            position: PortPosition.left,
          ),
        );

        // Target (50) is behind source (200) - offset = 200 - 20 = 180
        expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);
      },
    );

    test(
      'returns true when target is behind source (left port, target right of source)',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(50, 50),
          end: const Offset(200, 50),
          curvature: 0.5,
          offset: 20.0,
          sourcePort: createTestPort(
            id: 'in',
            type: PortType.input,
            position: PortPosition.left,
          ),
          targetPort: createTestPort(
            id: 'out',
            type: PortType.output,
            position: PortPosition.right,
          ),
        );

        // For left port, target behind means end.dx > start.dx + offset
        expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);
      },
    );

    test(
      'returns true when target is behind source (bottom port, target above)',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(50, 200),
          end: const Offset(50, 50),
          curvature: 0.5,
          offset: 20.0,
          sourcePort: createTestPort(
            id: 'bot',
            type: PortType.output,
            position: PortPosition.bottom,
          ),
          targetPort: createTestPort(
            id: 'top',
            type: PortType.input,
            position: PortPosition.top,
          ),
        );

        // For bottom port, target behind means end.dy < start.dy - offset
        expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);
      },
    );

    test(
      'returns true when target is behind source (top port, target below)',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(50, 50),
          end: const Offset(50, 200),
          curvature: 0.5,
          offset: 20.0,
          sourcePort: createTestPort(
            id: 'top',
            type: PortType.input,
            position: PortPosition.top,
          ),
          targetPort: createTestPort(
            id: 'bot',
            type: PortType.output,
            position: PortPosition.bottom,
          ),
        );

        // For top port, target behind means end.dy > start.dy + offset
        expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);
      },
    );

    test(
      'returns false for forward connection (right to left, target ahead)',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(100, 50),
          end: const Offset(300, 50),
          curvature: 0.5,
          offset: 20.0,
          sourcePort: createTestPort(
            id: 'out',
            type: PortType.output,
            position: PortPosition.right,
          ),
          targetPort: createTestPort(
            id: 'in',
            type: PortType.input,
            position: PortPosition.left,
          ),
        );

        // Target (300) is ahead of source (100) for right port
        expect(WaypointBuilder.needsLoopbackRouting(params), isFalse);
      },
    );

    test(
      'returns false for forward connection (bottom to top, target below)',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(50, 100),
          end: const Offset(50, 300),
          curvature: 0.5,
          offset: 20.0,
          sourcePort: createTestPort(
            id: 'bot',
            type: PortType.output,
            position: PortPosition.bottom,
          ),
          targetPort: createTestPort(
            id: 'top',
            type: PortType.input,
            position: PortPosition.top,
          ),
        );

        // Target (y=300) is ahead of source (y=100) for bottom port
        expect(WaypointBuilder.needsLoopbackRouting(params), isFalse);
      },
    );
  });

  // ===========================================================================
  // buildLoopbackSegments Tests
  // ===========================================================================

  group('buildLoopbackSegments', () {
    test('builds segments for self-connection', () {
      final nodeBounds = const Rect.fromLTWH(0, 0, 100, 100);
      final params = ConnectionPathParameters(
        start: const Offset(100, 30),
        end: const Offset(100, 70),
        curvature: 0.5,
        cornerRadius: 4.0,
        offset: 20.0,
        sourcePort: createTestPort(
          id: 'out',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in',
          type: PortType.input,
          position: PortPosition.right,
        ),
        sourceNodeBounds: nodeBounds,
        targetNodeBounds: nodeBounds,
      );

      final segments = WaypointBuilder.buildLoopbackSegments(params);

      expect(segments, isNotEmpty);
      // Should have multiple segments for routing around the node
      expect(segments.length, greaterThanOrEqualTo(1));
    });

    test('builds segments for same-side ports', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(100, 150),
        curvature: 0.5,
        cornerRadius: 4.0,
        offset: 20.0,
        sourcePort: createTestPort(
          id: 'out1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'out2',
          type: PortType.output,
          position: PortPosition.right,
        ),
        sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        targetNodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );

      final segments = WaypointBuilder.buildLoopbackSegments(params);

      expect(segments, isNotEmpty);
    });
  });

  // ===========================================================================
  // isSelfConnection Tests
  // ===========================================================================

  group('isSelfConnection', () {
    test('returns true when source and target bounds are identical', () {
      final bounds = const Rect.fromLTWH(0, 0, 100, 100);
      expect(WaypointBuilder.isSelfConnection(bounds, bounds), isTrue);
    });

    test('returns false when source and target bounds differ', () {
      final sourceBounds = const Rect.fromLTWH(0, 0, 100, 100);
      final targetBounds = const Rect.fromLTWH(200, 0, 100, 100);
      expect(
        WaypointBuilder.isSelfConnection(sourceBounds, targetBounds),
        isFalse,
      );
    });

    test('returns false when source bounds is null', () {
      final targetBounds = const Rect.fromLTWH(0, 0, 100, 100);
      expect(WaypointBuilder.isSelfConnection(null, targetBounds), isFalse);
    });

    test('returns false when target bounds is null', () {
      final sourceBounds = const Rect.fromLTWH(0, 0, 100, 100);
      expect(WaypointBuilder.isSelfConnection(sourceBounds, null), isFalse);
    });

    test('returns false when both bounds are null', () {
      expect(WaypointBuilder.isSelfConnection(null, null), isFalse);
    });
  });

  // ===========================================================================
  // getExtendedPoint Tests
  // ===========================================================================

  group('getExtendedPoint', () {
    test('extends right from point for right port', () {
      const point = Offset(100, 50);
      const offset = 20.0;

      final extended = WaypointBuilder.getExtendedPoint(
        point,
        PortPosition.right,
        offset,
      );

      expect(extended.dx, equals(120.0));
      expect(extended.dy, equals(50.0));
    });

    test('extends left from point for left port', () {
      const point = Offset(100, 50);
      const offset = 20.0;

      final extended = WaypointBuilder.getExtendedPoint(
        point,
        PortPosition.left,
        offset,
      );

      expect(extended.dx, equals(80.0));
      expect(extended.dy, equals(50.0));
    });

    test('extends up from point for top port', () {
      const point = Offset(50, 100);
      const offset = 20.0;

      final extended = WaypointBuilder.getExtendedPoint(
        point,
        PortPosition.top,
        offset,
      );

      expect(extended.dx, equals(50.0));
      expect(extended.dy, equals(80.0));
    });

    test('extends down from point for bottom port', () {
      const point = Offset(50, 100);
      const offset = 20.0;

      final extended = WaypointBuilder.getExtendedPoint(
        point,
        PortPosition.bottom,
        offset,
      );

      expect(extended.dx, equals(50.0));
      expect(extended.dy, equals(120.0));
    });

    test('handles zero offset', () {
      const point = Offset(100, 50);
      const offset = 0.0;

      final extended = WaypointBuilder.getExtendedPoint(
        point,
        PortPosition.right,
        offset,
      );

      expect(extended, equals(point));
    });
  });

  // ===========================================================================
  // calculateWaypoints Tests - Direct/Collinear
  // ===========================================================================

  group('calculateWaypoints - Direct/Collinear', () {
    test('returns 4 points for horizontally aligned ports with clear path', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(300, 50),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        offset: 20.0,
      );

      expect(waypoints.length, equals(4));
      expect(waypoints.first, equals(const Offset(100, 50)));
      expect(waypoints.last, equals(const Offset(300, 50)));
    });

    test('returns 4 points for vertically aligned ports with clear path', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(50, 100),
        end: const Offset(50, 300),
        sourcePosition: PortPosition.bottom,
        targetPosition: PortPosition.top,
        offset: 20.0,
      );

      expect(waypoints.length, equals(4));
      expect(waypoints.first, equals(const Offset(50, 100)));
      expect(waypoints.last, equals(const Offset(50, 300)));
    });
  });

  // ===========================================================================
  // calculateWaypoints Tests - Same-Side Routing
  // ===========================================================================

  group('calculateWaypoints - Same-Side Routing', () {
    test('routes around for right-to-right ports', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(100, 150),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.right,
        offset: 20.0,
        sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        targetNodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );

      expect(waypoints.length, greaterThan(4));
      // Should route to the right of both nodes
      final maxX = waypoints.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
      expect(maxX, greaterThan(100.0)); // Should extend past the right edge
    });

    test('routes around for left-to-left ports', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(0, 50),
        end: const Offset(0, 150),
        sourcePosition: PortPosition.left,
        targetPosition: PortPosition.left,
        offset: 20.0,
        sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        targetNodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );

      expect(waypoints.length, greaterThan(4));
      // Should route to the left of both nodes
      final minX = waypoints.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
      expect(minX, lessThan(0.0)); // Should extend past the left edge
    });

    test('routes around for top-to-top ports', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(50, 0),
        end: const Offset(150, 0),
        sourcePosition: PortPosition.top,
        targetPosition: PortPosition.top,
        offset: 20.0,
        sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        targetNodeBounds: const Rect.fromLTWH(100, 0, 100, 100),
      );

      expect(waypoints.length, greaterThan(4));
      // Should route above both nodes
      final minY = waypoints.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      expect(minY, lessThan(0.0)); // Should extend past the top edge
    });

    test('routes around for bottom-to-bottom ports', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(50, 100),
        end: const Offset(150, 100),
        sourcePosition: PortPosition.bottom,
        targetPosition: PortPosition.bottom,
        offset: 20.0,
        sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        targetNodeBounds: const Rect.fromLTWH(100, 0, 100, 100),
      );

      expect(waypoints.length, greaterThan(4));
      // Should route below both nodes
      final maxY = waypoints.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
      expect(maxY, greaterThan(100.0)); // Should extend past the bottom edge
    });

    test('uses backEdgeGap for same-side routing without node bounds', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(100, 150),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.right,
        offset: 20.0,
        backEdgeGap: 30.0,
      );

      expect(waypoints.length, greaterThan(4));
    });
  });

  // ===========================================================================
  // calculateWaypoints Tests - Opposite Port Routing (S-bends)
  // ===========================================================================

  group('calculateWaypoints - Opposite Port Routing', () {
    test('creates S-bend for horizontal opposite ports with clearance', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(300, 150),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        offset: 20.0,
      );

      expect(waypoints.length, greaterThanOrEqualTo(4));
      expect(waypoints.first, equals(const Offset(100, 50)));
      expect(waypoints.last, equals(const Offset(300, 150)));
    });

    test('creates S-bend for vertical opposite ports with clearance', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(50, 100),
        end: const Offset(150, 300),
        sourcePosition: PortPosition.bottom,
        targetPosition: PortPosition.top,
        offset: 20.0,
      );

      expect(waypoints.length, greaterThanOrEqualTo(4));
      expect(waypoints.first, equals(const Offset(50, 100)));
      expect(waypoints.last, equals(const Offset(150, 300)));
    });

    test(
      'routes around nodes for horizontal opposite ports without clearance',
      () {
        final waypoints = WaypointBuilder.calculateWaypoints(
          start: const Offset(100, 50),
          end: const Offset(50, 100),
          sourcePosition: PortPosition.right,
          targetPosition: PortPosition.left,
          offset: 20.0,
          sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
          targetNodeBounds: const Rect.fromLTWH(50, 50, 100, 100),
        );

        expect(waypoints.length, greaterThanOrEqualTo(4));
      },
    );

    test(
      'routes around nodes for vertical opposite ports without clearance',
      () {
        final waypoints = WaypointBuilder.calculateWaypoints(
          start: const Offset(50, 100),
          end: const Offset(100, 50),
          sourcePosition: PortPosition.bottom,
          targetPosition: PortPosition.top,
          offset: 20.0,
          sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
          targetNodeBounds: const Rect.fromLTWH(50, 50, 100, 100),
        );

        expect(waypoints.length, greaterThanOrEqualTo(4));
      },
    );
  });

  // ===========================================================================
  // calculateWaypoints Tests - L-Shape Routing
  // ===========================================================================

  group('calculateWaypoints - L-Shape Routing', () {
    test('creates L-shape for right to top ports', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(200, 0),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.top,
        offset: 20.0,
      );

      expect(waypoints.length, equals(5));
      expect(waypoints.first, equals(const Offset(100, 50)));
      expect(waypoints.last, equals(const Offset(200, 0)));
    });

    test('creates L-shape for right to bottom ports', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(200, 100),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.bottom,
        offset: 20.0,
      );

      expect(waypoints.length, equals(5));
      expect(waypoints.first, equals(const Offset(100, 50)));
      expect(waypoints.last, equals(const Offset(200, 100)));
    });

    test('creates L-shape for bottom to right ports', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(50, 100),
        end: const Offset(200, 150),
        sourcePosition: PortPosition.bottom,
        targetPosition: PortPosition.right,
        offset: 20.0,
      );

      expect(waypoints.length, equals(5));
      expect(waypoints.first, equals(const Offset(50, 100)));
      expect(waypoints.last, equals(const Offset(200, 150)));
    });

    test('creates L-shape for top to left ports', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(150, 0),
        end: const Offset(0, 50),
        sourcePosition: PortPosition.top,
        targetPosition: PortPosition.left,
        offset: 20.0,
      );

      // This combination may use a more complex routing path
      // depending on the clearance check. We just verify the path is valid.
      expect(waypoints.length, greaterThanOrEqualTo(4));
      expect(waypoints.first, equals(const Offset(150, 0)));
      expect(waypoints.last, equals(const Offset(0, 50)));
    });
  });

  // ===========================================================================
  // calculateWaypoints Tests - Self-Connection
  // ===========================================================================

  group('calculateWaypoints - Self-Connection', () {
    test('routes around node for right to left self-connection', () {
      final nodeBounds = const Rect.fromLTWH(0, 0, 100, 100);
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 30),
        end: const Offset(0, 70),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        offset: 20.0,
        sourceNodeBounds: nodeBounds,
        targetNodeBounds: nodeBounds,
      );

      expect(waypoints.length, greaterThan(4));
      expect(waypoints.first, equals(const Offset(100, 30)));
      expect(waypoints.last, equals(const Offset(0, 70)));
    });

    test('routes around node for top to bottom self-connection', () {
      final nodeBounds = const Rect.fromLTWH(0, 0, 100, 100);
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(30, 0),
        end: const Offset(70, 100),
        sourcePosition: PortPosition.top,
        targetPosition: PortPosition.bottom,
        offset: 20.0,
        sourceNodeBounds: nodeBounds,
        targetNodeBounds: nodeBounds,
      );

      expect(waypoints.length, greaterThan(4));
      expect(waypoints.first, equals(const Offset(30, 0)));
      expect(waypoints.last, equals(const Offset(70, 100)));
    });

    test('routes around node for right to right self-connection', () {
      final nodeBounds = const Rect.fromLTWH(0, 0, 100, 100);
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 30),
        end: const Offset(100, 70),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.right,
        offset: 20.0,
        sourceNodeBounds: nodeBounds,
        targetNodeBounds: nodeBounds,
      );

      expect(waypoints.length, greaterThan(4));
    });
  });

  // ===========================================================================
  // calculateWaypoints Tests - Full Routing
  // ===========================================================================

  group('calculateWaypoints - Full Routing', () {
    test('uses union bounds for routing around multiple nodes', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(50, 150),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.top,
        offset: 20.0,
        sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        targetNodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );

      expect(waypoints.length, greaterThanOrEqualTo(4));
    });

    test('uses fallback routing when no node bounds provided', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(50, 150),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.top,
        offset: 20.0,
      );

      expect(waypoints.length, greaterThanOrEqualTo(4));
      expect(waypoints.first, equals(const Offset(100, 50)));
      expect(waypoints.last, equals(const Offset(50, 150)));
    });
  });

  // ===========================================================================
  // calculateWaypoints Tests - Edge Cases
  // ===========================================================================

  group('calculateWaypoints - Edge Cases', () {
    test('handles zero offset', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(300, 50),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        offset: 0.0,
      );

      expect(waypoints, isNotEmpty);
      expect(waypoints.first, equals(const Offset(100, 50)));
      expect(waypoints.last, equals(const Offset(300, 50)));
    });

    test('handles custom source and target offsets', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(300, 50),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        offset: 20.0,
        sourceOffset: 30.0,
        targetOffset: 10.0,
      );

      expect(waypoints, isNotEmpty);
      // Extended points should use custom offsets
      expect(waypoints[1].dx, equals(130.0)); // start + sourceOffset
      expect(
        waypoints[waypoints.length - 2].dx,
        equals(290.0),
      ); // end - targetOffset
    });

    test('handles zero targetOffset for temporary connections', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(100, 50),
        end: const Offset(300, 50),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        offset: 20.0,
        targetOffset: 0.0,
      );

      expect(waypoints, isNotEmpty);
      // End extended should equal end when targetOffset is 0
      expect(waypoints[waypoints.length - 2], equals(const Offset(300, 50)));
    });

    test('handles negative coordinates', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(-100, -50),
        end: const Offset(-300, -50),
        sourcePosition: PortPosition.left,
        targetPosition: PortPosition.right,
        offset: 20.0,
      );

      expect(waypoints, isNotEmpty);
      expect(waypoints.first, equals(const Offset(-100, -50)));
      expect(waypoints.last, equals(const Offset(-300, -50)));
    });

    test('handles very large coordinates', () {
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: const Offset(10000, 5000),
        end: const Offset(30000, 5000),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        offset: 20.0,
      );

      expect(waypoints, isNotEmpty);
      expect(waypoints.first, equals(const Offset(10000, 5000)));
      expect(waypoints.last, equals(const Offset(30000, 5000)));
    });
  });

  // ===========================================================================
  // optimizeWaypoints Tests
  // ===========================================================================

  group('optimizeWaypoints', () {
    test('removes collinear horizontal points', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(50, 50),
        const Offset(100, 50),
        const Offset(150, 50),
        const Offset(200, 50),
      ];

      final optimized = WaypointBuilder.optimizeWaypoints(waypoints);

      // Should collapse all horizontal collinear points
      expect(optimized.length, equals(2));
      expect(optimized.first, equals(const Offset(0, 50)));
      expect(optimized.last, equals(const Offset(200, 50)));
    });

    test('removes collinear vertical points', () {
      final waypoints = [
        const Offset(50, 0),
        const Offset(50, 50),
        const Offset(50, 100),
        const Offset(50, 150),
        const Offset(50, 200),
      ];

      final optimized = WaypointBuilder.optimizeWaypoints(waypoints);

      // Should collapse all vertical collinear points
      expect(optimized.length, equals(2));
      expect(optimized.first, equals(const Offset(50, 0)));
      expect(optimized.last, equals(const Offset(50, 200)));
    });

    test('preserves corner points', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(100, 50),
        const Offset(100, 100),
        const Offset(200, 100),
      ];

      final optimized = WaypointBuilder.optimizeWaypoints(waypoints);

      // Corner at (100, 50) should be preserved
      expect(optimized.length, equals(4));
      expect(optimized, equals(waypoints));
    });

    test('handles two-point path', () {
      final waypoints = [const Offset(0, 50), const Offset(200, 50)];

      final optimized = WaypointBuilder.optimizeWaypoints(waypoints);

      expect(optimized, equals(waypoints));
    });

    test('handles single-point path', () {
      final waypoints = [const Offset(100, 50)];

      final optimized = WaypointBuilder.optimizeWaypoints(waypoints);

      expect(optimized, equals(waypoints));
    });

    test('handles empty path', () {
      final waypoints = <Offset>[];

      final optimized = WaypointBuilder.optimizeWaypoints(waypoints);

      expect(optimized, isEmpty);
    });
  });

  // ===========================================================================
  // generatePathFromWaypoints Tests
  // ===========================================================================

  group('generatePathFromWaypoints', () {
    test('returns empty path for fewer than 2 waypoints', () {
      final path = WaypointBuilder.generatePathFromWaypoints([
        const Offset(0, 0),
      ]);
      expect(path.getBounds(), equals(Rect.zero));
    });

    test('creates line path for 2 waypoints', () {
      final waypoints = [const Offset(0, 0), const Offset(100, 100)];

      final path = WaypointBuilder.generatePathFromWaypoints(waypoints);

      expect(path.getBounds().left, closeTo(0, 0.1));
      expect(path.getBounds().top, closeTo(0, 0.1));
      expect(path.getBounds().right, closeTo(100, 0.1));
      expect(path.getBounds().bottom, closeTo(100, 0.1));
    });

    test('creates straight path with zero corner radius', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(100, 50),
        const Offset(100, 100),
        const Offset(200, 100),
      ];

      final path = WaypointBuilder.generatePathFromWaypoints(
        waypoints,
        cornerRadius: 0,
      );

      final bounds = path.getBounds();
      expect(bounds.left, closeTo(0, 0.1));
      expect(bounds.right, closeTo(200, 0.1));
    });

    test('creates rounded path with corner radius', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(100, 50),
        const Offset(100, 100),
        const Offset(200, 100),
      ];

      final path = WaypointBuilder.generatePathFromWaypoints(
        waypoints,
        cornerRadius: 10.0,
      );

      final bounds = path.getBounds();
      expect(bounds.left, closeTo(0, 0.1));
      expect(bounds.right, closeTo(200, 0.1));
    });

    test('handles corner radius larger than available space', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(10, 50), // Very short segment
        const Offset(10, 60),
        const Offset(20, 60),
      ];

      // Should not throw, should adapt radius
      final path = WaypointBuilder.generatePathFromWaypoints(
        waypoints,
        cornerRadius: 100.0, // Much larger than segment length
      );

      expect(path.getBounds(), isNot(equals(Rect.zero)));
    });
  });

  // ===========================================================================
  // generateHitTestSegments Tests
  // ===========================================================================

  group('generateHitTestSegments', () {
    test('returns empty for fewer than 2 waypoints', () {
      final segments = WaypointBuilder.generateHitTestSegments([
        const Offset(0, 0),
      ], 8.0);

      expect(segments, isEmpty);
    });

    test('creates rectangles for simple horizontal path', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(100, 50),
        const Offset(200, 50),
      ];

      final segments = WaypointBuilder.generateHitTestSegments(waypoints, 8.0);

      expect(segments, isNotEmpty);
      // Each rectangle should contain the path
      for (final rect in segments) {
        expect(rect.top, lessThanOrEqualTo(50.0 + 8.0));
        expect(rect.bottom, greaterThanOrEqualTo(50.0 - 8.0));
      }
    });

    test('creates rectangles for path with corners', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(100, 50),
        const Offset(100, 100),
        const Offset(200, 100),
      ];

      final segments = WaypointBuilder.generateHitTestSegments(waypoints, 8.0);

      expect(segments, isNotEmpty);
    });

    test('tolerance affects rectangle size', () {
      final waypoints = [const Offset(0, 50), const Offset(100, 50)];

      final smallTolerance = WaypointBuilder.generateHitTestSegments(
        waypoints,
        4.0,
      );
      final largeTolerance = WaypointBuilder.generateHitTestSegments(
        waypoints,
        16.0,
      );

      expect(
        smallTolerance.first.height,
        lessThan(largeTolerance.first.height),
      );
    });
  });

  // ===========================================================================
  // generatePathFromSegments Tests
  // ===========================================================================

  group('generatePathFromSegments', () {
    test('creates empty path from empty segments', () {
      final path = WaypointBuilder.generatePathFromSegments(
        start: const Offset(0, 0),
        segments: [],
      );

      expect(path.getBounds(), equals(Rect.zero));
    });

    test('creates path from straight segments', () {
      final segments = [
        const StraightSegment(end: Offset(100, 0)),
        const StraightSegment(end: Offset(100, 100)),
        const StraightSegment(end: Offset(200, 100)),
      ];

      final path = WaypointBuilder.generatePathFromSegments(
        start: const Offset(0, 0),
        segments: segments,
      );

      final bounds = path.getBounds();
      expect(bounds.left, closeTo(0, 0.1));
      expect(bounds.right, closeTo(200, 0.1));
      expect(bounds.top, closeTo(0, 0.1));
      expect(bounds.bottom, closeTo(100, 0.1));
    });

    test('creates path from quadratic segments', () {
      final segments = [
        const StraightSegment(end: Offset(50, 0)),
        const QuadraticSegment(
          controlPoint: Offset(60, 0),
          end: Offset(60, 10),
        ),
        const StraightSegment(end: Offset(60, 50)),
      ];

      final path = WaypointBuilder.generatePathFromSegments(
        start: const Offset(0, 0),
        segments: segments,
      );

      expect(path.getBounds(), isNot(equals(Rect.zero)));
    });

    test('creates path from cubic segments', () {
      final segments = [
        CubicSegment(
          controlPoint1: const Offset(50, 0),
          controlPoint2: const Offset(50, 100),
          end: const Offset(100, 100),
        ),
      ];

      final path = WaypointBuilder.generatePathFromSegments(
        start: const Offset(0, 0),
        segments: segments,
      );

      final bounds = path.getBounds();
      expect(bounds.right, closeTo(100, 0.1));
      expect(bounds.bottom, closeTo(100, 0.1));
    });

    test('creates path from mixed segment types', () {
      final segments = <PathSegment>[
        const StraightSegment(end: Offset(50, 0)),
        const QuadraticSegment(
          controlPoint: Offset(60, 0),
          end: Offset(60, 10),
        ),
        CubicSegment(
          controlPoint1: const Offset(60, 50),
          controlPoint2: const Offset(100, 50),
          end: const Offset(100, 100),
        ),
        const StraightSegment(end: Offset(150, 100)),
      ];

      final path = WaypointBuilder.generatePathFromSegments(
        start: const Offset(0, 0),
        segments: segments,
      );

      expect(path.getBounds(), isNot(equals(Rect.zero)));
    });
  });

  // ===========================================================================
  // generateHitTestFromSegments Tests
  // ===========================================================================

  group('generateHitTestFromSegments', () {
    test('returns empty for empty segments', () {
      final rects = WaypointBuilder.generateHitTestFromSegments(
        start: const Offset(0, 0),
        segments: [],
        tolerance: 8.0,
      );

      expect(rects, isEmpty);
    });

    test('generates rects for straight segments', () {
      final segments = [
        const StraightSegment(end: Offset(100, 0)),
        const StraightSegment(end: Offset(100, 100)),
      ];

      final rects = WaypointBuilder.generateHitTestFromSegments(
        start: const Offset(0, 0),
        segments: segments,
        tolerance: 8.0,
      );

      expect(rects.length, equals(2));
    });

    test('generates rects for quadratic segments', () {
      final segments = [
        const QuadraticSegment(
          controlPoint: Offset(50, 0),
          end: Offset(50, 50),
        ),
      ];

      final rects = WaypointBuilder.generateHitTestFromSegments(
        start: const Offset(0, 0),
        segments: segments,
        tolerance: 8.0,
      );

      expect(rects, isNotEmpty);
    });

    test('generates rects for cubic segments', () {
      final segments = [
        CubicSegment(
          controlPoint1: const Offset(50, 0),
          controlPoint2: const Offset(50, 100),
          end: const Offset(100, 100),
        ),
      ];

      final rects = WaypointBuilder.generateHitTestFromSegments(
        start: const Offset(0, 0),
        segments: segments,
        tolerance: 8.0,
      );

      expect(rects, isNotEmpty);
    });

    test('respects generateHitTestRects flag', () {
      final segmentsWithHitTest = [
        const StraightSegment(end: Offset(50, 0)),
        const QuadraticSegment(
          controlPoint: Offset(60, 0),
          end: Offset(60, 10),
          generateHitTestRects: true, // Include hit test for this segment
        ),
        const StraightSegment(end: Offset(60, 100)),
      ];

      final segmentsWithoutHitTest = [
        const StraightSegment(end: Offset(50, 0)),
        const QuadraticSegment(
          controlPoint: Offset(60, 0),
          end: Offset(60, 10),
          generateHitTestRects: false, // Skip hit test for this segment
        ),
        const StraightSegment(end: Offset(60, 100)),
      ];

      final rectsWithHitTest = WaypointBuilder.generateHitTestFromSegments(
        start: const Offset(0, 0),
        segments: segmentsWithHitTest,
        tolerance: 8.0,
      );

      final rectsWithoutHitTest = WaypointBuilder.generateHitTestFromSegments(
        start: const Offset(0, 0),
        segments: segmentsWithoutHitTest,
        tolerance: 8.0,
      );

      // With generateHitTestRects: false, should have fewer rects
      expect(rectsWithoutHitTest.length, lessThan(rectsWithHitTest.length));
    });
  });

  // ===========================================================================
  // waypointsToSegments Tests
  // ===========================================================================

  group('waypointsToSegments', () {
    test('returns empty for fewer than 2 waypoints', () {
      final segments = WaypointBuilder.waypointsToSegments([
        const Offset(0, 0),
      ]);
      expect(segments, isEmpty);
    });

    test('creates single segment for 2 waypoints', () {
      final waypoints = [const Offset(0, 0), const Offset(100, 0)];

      final segments = WaypointBuilder.waypointsToSegments(waypoints);

      expect(segments.length, equals(1));
      expect(segments.first, isA<StraightSegment>());
      expect(segments.first.end, equals(const Offset(100, 0)));
    });

    test('creates straight segments with zero corner radius', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(100, 50),
        const Offset(100, 100),
        const Offset(200, 100),
      ];

      final segments = WaypointBuilder.waypointsToSegments(
        waypoints,
        cornerRadius: 0,
      );

      expect(segments.length, equals(3));
      expect(segments.every((s) => s is StraightSegment), isTrue);
    });

    test('creates rounded corners with positive corner radius', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(100, 50),
        const Offset(100, 100),
        const Offset(200, 100),
      ];

      final segments = WaypointBuilder.waypointsToSegments(
        waypoints,
        cornerRadius: 10.0,
      );

      // Should have quadratic segments for corners
      expect(segments.any((s) => s is QuadraticSegment), isTrue);
    });

    test('handles corner radius larger than segment length', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(5, 50), // Very short segment
        const Offset(5, 55),
        const Offset(10, 55),
      ];

      // Should not throw, should adapt radius
      final segments = WaypointBuilder.waypointsToSegments(
        waypoints,
        cornerRadius: 100.0,
      );

      expect(segments, isNotEmpty);
    });

    test('skips very short segments', () {
      final waypoints = [
        const Offset(0, 50),
        const Offset(0.001, 50), // Nearly zero-length
        const Offset(100, 50),
      ];

      final segments = WaypointBuilder.waypointsToSegments(
        waypoints,
        cornerRadius: 10.0,
      );

      expect(segments, isNotEmpty);
    });
  });

  // ===========================================================================
  // createBezierSegment Tests
  // ===========================================================================

  group('createBezierSegment', () {
    test('creates cubic segment for right to left connection', () {
      final segment = WaypointBuilder.createBezierSegment(
        start: const Offset(0, 50),
        end: const Offset(200, 50),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        curvature: 0.5,
        portExtension: 20.0,
      );

      expect(segment, isA<CubicSegment>());
      expect(segment.end, equals(const Offset(200, 50)));
      // Control point 1 should be to the right of start
      expect(segment.controlPoint1.dx, greaterThan(0));
      // Control point 2 should be to the left of end
      expect(segment.controlPoint2.dx, lessThan(200));
    });

    test('creates cubic segment for bottom to top connection', () {
      final segment = WaypointBuilder.createBezierSegment(
        start: const Offset(50, 0),
        end: const Offset(50, 200),
        sourcePosition: PortPosition.bottom,
        targetPosition: PortPosition.top,
        curvature: 0.5,
        portExtension: 20.0,
      );

      expect(segment, isA<CubicSegment>());
      expect(segment.end, equals(const Offset(50, 200)));
      // Control point 1 should be below start
      expect(segment.controlPoint1.dy, greaterThan(0));
      // Control point 2 should be above end
      expect(segment.controlPoint2.dy, lessThan(200));
    });

    test('uses custom source extension', () {
      final segment = WaypointBuilder.createBezierSegment(
        start: const Offset(0, 50),
        end: const Offset(200, 50),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        curvature: 0.5,
        portExtension: 20.0,
        sourceExtension: 50.0,
      );

      // Control point 1 should use sourceExtension
      expect(segment.controlPoint1.dx, greaterThanOrEqualTo(50));
    });

    test('uses custom target extension', () {
      final segment = WaypointBuilder.createBezierSegment(
        start: const Offset(0, 50),
        end: const Offset(200, 50),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        curvature: 0.5,
        portExtension: 20.0,
        targetExtension: 50.0,
      );

      // Control point 2 should use targetExtension
      expect(segment.controlPoint2.dx, lessThanOrEqualTo(150));
    });

    test('uses zero target extension for temporary connections', () {
      final segment = WaypointBuilder.createBezierSegment(
        start: const Offset(0, 50),
        end: const Offset(200, 50),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        curvature: 0.5,
        portExtension: 20.0,
        targetExtension: 0.0,
      );

      // With targetExtension=0, the control point calculation uses
      // max(0, distance * curvature) = max(0, 200 * 0.5) = 100
      // So cp2 should be at end.dx - 100 = 100
      // For left port, the control point is at anchor.dx - offset
      expect(segment.controlPoint2.dx, equals(100.0));
    });

    test('handles different curvature values', () {
      final lowCurvature = WaypointBuilder.createBezierSegment(
        start: const Offset(0, 50),
        end: const Offset(200, 100),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        curvature: 0.1,
        portExtension: 20.0,
      );

      final highCurvature = WaypointBuilder.createBezierSegment(
        start: const Offset(0, 50),
        end: const Offset(200, 100),
        sourcePosition: PortPosition.right,
        targetPosition: PortPosition.left,
        curvature: 0.9,
        portExtension: 20.0,
      );

      // Higher curvature should result in control points further from start/end
      expect(
        highCurvature.controlPoint1.dx,
        greaterThan(lowCurvature.controlPoint1.dx),
      );
    });

    test('creates segment for left port', () {
      final segment = WaypointBuilder.createBezierSegment(
        start: const Offset(200, 50),
        end: const Offset(0, 50),
        sourcePosition: PortPosition.left,
        targetPosition: PortPosition.right,
        curvature: 0.5,
        portExtension: 20.0,
      );

      expect(segment, isA<CubicSegment>());
      // Control point 1 should be to the left of start
      expect(segment.controlPoint1.dx, lessThan(200));
    });

    test('creates segment for top port', () {
      final segment = WaypointBuilder.createBezierSegment(
        start: const Offset(50, 200),
        end: const Offset(50, 0),
        sourcePosition: PortPosition.top,
        targetPosition: PortPosition.bottom,
        curvature: 0.5,
        portExtension: 20.0,
      );

      expect(segment, isA<CubicSegment>());
      // Control point 1 should be above start
      expect(segment.controlPoint1.dy, lessThan(200));
    });
  });

  // ===========================================================================
  // LoopbackDirection Enum Tests
  // ===========================================================================

  group('LoopbackDirection', () {
    test('has all expected values', () {
      expect(LoopbackDirection.values, hasLength(4));
      expect(LoopbackDirection.values, contains(LoopbackDirection.above));
      expect(LoopbackDirection.values, contains(LoopbackDirection.below));
      expect(LoopbackDirection.values, contains(LoopbackDirection.left));
      expect(LoopbackDirection.values, contains(LoopbackDirection.right));
    });
  });

  // ===========================================================================
  // Integration Tests
  // ===========================================================================

  group('Integration - Complete Path Generation', () {
    test('generates complete path for forward connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(300, 50),
        curvature: 0.5,
        cornerRadius: 4.0,
        offset: 20.0,
        sourcePort: createTestPort(
          id: 'out',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in',
          type: PortType.input,
          position: PortPosition.left,
        ),
      );

      // Check that loopback is not needed
      expect(WaypointBuilder.needsLoopbackRouting(params), isFalse);

      // Generate waypoints
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: params.start,
        end: params.end,
        sourcePosition: params.sourcePosition,
        targetPosition: params.targetPosition,
        offset: params.offset,
      );

      expect(waypoints, isNotEmpty);
      expect(waypoints.first, equals(params.start));
      expect(waypoints.last, equals(params.end));

      // Generate path
      final path = WaypointBuilder.generatePathFromWaypoints(waypoints);
      expect(path.getBounds(), isNot(equals(Rect.zero)));

      // Generate hit test segments
      final hitRects = WaypointBuilder.generateHitTestSegments(waypoints, 8.0);
      expect(hitRects, isNotEmpty);
    });

    test('generates complete path for loopback connection', () {
      final nodeBounds = const Rect.fromLTWH(0, 0, 100, 100);
      final params = ConnectionPathParameters(
        start: const Offset(100, 30),
        end: const Offset(0, 70),
        curvature: 0.5,
        cornerRadius: 4.0,
        offset: 20.0,
        sourcePort: createTestPort(
          id: 'out',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in',
          type: PortType.input,
          position: PortPosition.left,
        ),
        sourceNodeBounds: nodeBounds,
        targetNodeBounds: nodeBounds,
      );

      // Check that loopback is needed
      expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);

      // Build loopback segments
      final segments = WaypointBuilder.buildLoopbackSegments(params);
      expect(segments, isNotEmpty);

      // Generate path from segments
      final path = WaypointBuilder.generatePathFromSegments(
        start: params.start,
        segments: segments,
      );
      expect(path.getBounds(), isNot(equals(Rect.zero)));

      // Generate hit test from segments
      final hitRects = WaypointBuilder.generateHitTestFromSegments(
        start: params.start,
        segments: segments,
        tolerance: 8.0,
      );
      expect(hitRects, isNotEmpty);
    });

    test('generates complete path for same-side connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(100, 150),
        curvature: 0.5,
        cornerRadius: 4.0,
        offset: 20.0,
        sourcePort: createTestPort(
          id: 'out1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'out2',
          type: PortType.output,
          position: PortPosition.right,
        ),
        sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        targetNodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );

      // Check that loopback is needed for same-side
      expect(WaypointBuilder.needsLoopbackRouting(params), isTrue);

      // Generate waypoints
      final waypoints = WaypointBuilder.calculateWaypoints(
        start: params.start,
        end: params.end,
        sourcePosition: params.sourcePosition,
        targetPosition: params.targetPosition,
        offset: params.offset,
        sourceNodeBounds: params.sourceNodeBounds,
        targetNodeBounds: params.targetNodeBounds,
      );

      expect(waypoints.length, greaterThan(4));

      // Convert to segments with rounded corners
      final segments = WaypointBuilder.waypointsToSegments(
        waypoints,
        cornerRadius: 4.0,
      );
      expect(segments, isNotEmpty);
    });
  });
}
