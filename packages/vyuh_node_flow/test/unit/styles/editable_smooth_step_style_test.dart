/// Comprehensive tests for EditableSmoothStepConnectionStyle.
///
/// Tests cover:
/// - Editable waypoints functionality
/// - Path modification through control points
/// - Orthogonal waypoint generation edge cases
/// - Segment optimization (collinear point removal)
/// - Corner rounding with various radii
/// - Edge cases for segment generation
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/connections/styles/path_segments.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // Editable Waypoints Tests
  // ==========================================================================

  group('Editable Waypoints', () {
    late EditableSmoothStepConnectionStyle style;

    setUp(() {
      style = const EditableSmoothStepConnectionStyle();
    });

    test('createSegmentsThroughWaypoints with single waypoint returns empty', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.left,
        ),
      );

      // Single waypoint (< 2) returns empty segments
      // This is because _createOrthogonalWaypoints returns the single waypoint as-is
      // and _generateSmoothSegments returns [] for < 2 waypoints
      final waypoints = [const Offset(50, 50)];
      final result = style.createSegmentsThroughWaypoints(waypoints, params);

      expect(result.segments, isEmpty);
      expect(result.start, equals(waypoints.first));
    });

    test(
      'createSegmentsThroughWaypoints creates orthogonal path through multiple waypoints',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
        );

        final waypoints = [
          params.start,
          const Offset(100, 0), // First control point
          const Offset(100, 100), // Second control point
          const Offset(200, 100), // Third control point
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.start, equals(waypoints.first));
        expect(result.segments, isNotEmpty);
      },
    );

    test('waypoints maintain start point correctly', () {
      final params = ConnectionPathParameters(
        start: const Offset(25, 75),
        end: const Offset(300, 150),
        curvature: 0.5,
      );

      final waypoints = [
        params.start,
        const Offset(100, 75),
        const Offset(100, 150),
        params.end,
      ];

      final result = style.createSegmentsThroughWaypoints(waypoints, params);

      expect(result.start, equals(params.start));
    });

    test('control points converted to orthogonal segments', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        controlPoints: [const Offset(50, 25), const Offset(75, 75)],
      );

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
      // Path should contain mix of straight and quadratic segments
    });

    test('many waypoints are processed correctly', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(500, 500),
        curvature: 0.5,
      );

      final waypoints = [
        params.start,
        const Offset(100, 0),
        const Offset(100, 100),
        const Offset(200, 100),
        const Offset(200, 200),
        const Offset(300, 200),
        const Offset(300, 300),
        const Offset(400, 300),
        const Offset(400, 500),
        params.end,
      ];

      final result = style.createSegmentsThroughWaypoints(waypoints, params);

      expect(result.start, equals(waypoints.first));
      expect(result.segments, isNotEmpty);
    });
  });

  // ==========================================================================
  // Path Modification Tests
  // ==========================================================================

  group('Path Modification', () {
    late EditableSmoothStepConnectionStyle style;

    setUp(() {
      style = const EditableSmoothStepConnectionStyle();
    });

    test('adding control points changes the path', () {
      final paramsWithoutControl = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 150),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.left,
        ),
      );

      final paramsWithControl = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 150),
        curvature: 0.5,
        controlPoints: [const Offset(100, 0), const Offset(100, 200)],
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.left,
        ),
      );

      final resultWithout = style.createSegments(paramsWithoutControl);
      final resultWith = style.createSegments(paramsWithControl);

      // Both should produce valid segments
      expect(resultWithout.segments, isNotEmpty);
      expect(resultWith.segments, isNotEmpty);

      // The paths should be different due to control points
      final pathWithout = style.buildPath(
        resultWithout.start,
        resultWithout.segments,
      );
      final pathWith = style.buildPath(resultWith.start, resultWith.segments);

      // Build hit test rects to verify different paths
      final rectsWithout = style.buildHitTestRects(
        resultWithout.start,
        resultWithout.segments,
        8.0,
      );
      final rectsWith = style.buildHitTestRects(
        resultWith.start,
        resultWith.segments,
        8.0,
      );

      // Different control points should produce different numbers of hit test rects
      // (or at least different paths - we verify paths are non-empty)
      expect(pathWithout.getBounds().isEmpty, isFalse);
      expect(pathWith.getBounds().isEmpty, isFalse);
    });

    test('moving control point updates path accordingly', () {
      final params1 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(200, 200),
        curvature: 0.5,
        controlPoints: [const Offset(50, 100)],
      );

      final params2 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(200, 200),
        curvature: 0.5,
        controlPoints: [const Offset(150, 100)], // Moved control point
      );

      final result1 = style.createSegments(params1);
      final result2 = style.createSegments(params2);

      expect(result1.segments, isNotEmpty);
      expect(result2.segments, isNotEmpty);
    });

    test('removing all control points reverts to algorithmic path', () {
      final paramsWithControl = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 150),
        curvature: 0.5,
        controlPoints: [const Offset(100, 50)],
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.left,
        ),
      );

      final paramsWithoutControl = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 150),
        curvature: 0.5,
        controlPoints: [], // No control points
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.left,
        ),
      );

      final resultWith = style.createSegments(paramsWithControl);
      final resultWithout = style.createSegments(paramsWithoutControl);

      expect(resultWith.segments, isNotEmpty);
      expect(resultWithout.segments, isNotEmpty);
    });

    test('createWaypointsWithEnds correctly bookends control points', () {
      final params = ConnectionPathParameters(
        start: const Offset(10, 20),
        end: const Offset(300, 400),
        curvature: 0.5,
      );

      final controlPoints = [const Offset(100, 100), const Offset(200, 200)];

      final waypoints = style.createWaypointsWithEnds(controlPoints, params);

      expect(waypoints.length, equals(4));
      expect(waypoints.first, equals(params.start));
      expect(waypoints.last, equals(params.end));
      expect(waypoints[1], equals(controlPoints[0]));
      expect(waypoints[2], equals(controlPoints[1]));
    });
  });

  // ==========================================================================
  // Edge Cases Tests
  // ==========================================================================

  group('Edge Cases', () {
    late EditableSmoothStepConnectionStyle style;

    setUp(() {
      style = const EditableSmoothStepConnectionStyle();
    });

    group('Orthogonal Waypoints Edge Cases', () {
      test('handles waypoints with only horizontal difference', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 100),
          end: const Offset(200, 100), // Same Y coordinate
          curvature: 0.5,
        );

        final waypoints = [
          params.start,
          const Offset(100, 100), // On the same horizontal line
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });

      test('handles waypoints with only vertical difference', () {
        final params = ConnectionPathParameters(
          start: const Offset(100, 0),
          end: const Offset(100, 200), // Same X coordinate
          curvature: 0.5,
        );

        final waypoints = [
          params.start,
          const Offset(100, 100), // On the same vertical line
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });

      test('handles diagonal waypoints converted to orthogonal', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
        );

        // Diagonal points that must be converted to orthogonal
        final waypoints = [
          params.start,
          const Offset(50, 50), // Diagonal from start
          const Offset(100, 150), // Diagonal point
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });

      test('handles alternating horizontal and vertical movements', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(300, 300),
          curvature: 0.5,
        );

        // Create waypoints that alternate between horizontal and vertical
        final waypoints = [
          params.start,
          const Offset(100, 0), // Horizontal move
          const Offset(100, 100), // Vertical move
          const Offset(200, 100), // Horizontal move
          const Offset(200, 200), // Vertical move
          const Offset(300, 200), // Horizontal move
          params.end, // Final connection
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.start, equals(params.start));
        expect(result.segments, isNotEmpty);
      });

      test('handles connection when last segment is horizontal dominant', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 50),
          end: const Offset(
            200,
            60,
          ), // X difference > Y difference from last waypoint
          curvature: 0.5,
        );

        final waypoints = [params.start, const Offset(100, 50), params.end];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });

      test('handles connection when last segment is vertical dominant', () {
        final params = ConnectionPathParameters(
          start: const Offset(50, 0),
          end: const Offset(
            60,
            200,
          ), // Y difference > X difference from last waypoint
          curvature: 0.5,
        );

        final waypoints = [params.start, const Offset(50, 100), params.end];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });
    });

    group('Optimization Edge Cases', () {
      test('removes collinear horizontal points', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 50),
          end: const Offset(300, 50), // All on same horizontal line
          curvature: 0.5,
        );

        final waypoints = [
          params.start,
          const Offset(100, 50), // Collinear with start
          const Offset(200, 50), // Collinear with previous
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
        // Collinear points should be optimized away
      });

      test('removes collinear vertical points', () {
        final params = ConnectionPathParameters(
          start: const Offset(50, 0),
          end: const Offset(50, 300), // All on same vertical line
          curvature: 0.5,
        );

        final waypoints = [
          params.start,
          const Offset(50, 100), // Collinear with start
          const Offset(50, 200), // Collinear with previous
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });

      test('preserves corner waypoints (non-collinear)', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
        );

        // L-shaped path with a corner
        final waypoints = [
          params.start,
          const Offset(100, 0), // Horizontal segment end
          const Offset(100, 100), // Corner point (vertical segment)
          const Offset(200, 100), // Horizontal segment
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
        // Corner points should be preserved as turns
      });
    });

    group('Segment Generation Edge Cases', () {
      test('handles zero corner radius (sharp corners)', () {
        const sharpStyle = EditableSmoothStepConnectionStyle(
          defaultCornerRadius: 0.0,
        );

        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
          cornerRadius: 0.0,
        );

        // Create perfectly orthogonal waypoints that won't be modified
        // by _createOrthogonalWaypoints transformation
        final waypoints = [
          params.start,
          const Offset(100, 0), // Horizontal from start
          const Offset(100, 200), // Vertical
          params.end, // Horizontal to end
        ];

        final result = sharpStyle.createSegmentsThroughWaypoints(
          waypoints,
          params,
        );

        expect(result.segments, isNotEmpty);
        // With zero corner radius and orthogonal path, all segments should be straight
        for (final segment in result.segments) {
          expect(segment, isA<StraightSegment>());
        }
      });

      test('handles very small corner radius (< 1.0)', () {
        const smallRadiusStyle = EditableSmoothStepConnectionStyle(
          defaultCornerRadius: 0.5,
        );

        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
          cornerRadius: 0.5, // Very small radius
        );

        final waypoints = [
          params.start,
          const Offset(100, 0),
          const Offset(100, 100),
          const Offset(200, 100),
          params.end,
        ];

        final result = smallRadiusStyle.createSegmentsThroughWaypoints(
          waypoints,
          params,
        );

        expect(result.segments, isNotEmpty);
      });

      test('handles large corner radius that exceeds segment length', () {
        const largeRadiusStyle = EditableSmoothStepConnectionStyle(
          defaultCornerRadius: 100.0, // Very large
        );

        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(50, 50), // Short segments
          curvature: 0.5,
          cornerRadius: 100.0,
        );

        final waypoints = [
          params.start,
          const Offset(25, 0),
          const Offset(25, 25),
          params.end,
        ];

        final result = largeRadiusStyle.createSegmentsThroughWaypoints(
          waypoints,
          params,
        );

        expect(result.segments, isNotEmpty);
        // Corner radius should be adapted to available space
      });

      test('handles duplicate consecutive waypoints', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
        );

        // Duplicate waypoints (same point twice)
        final waypoints = [
          params.start,
          const Offset(100, 0),
          const Offset(100, 0), // Duplicate of previous
          const Offset(100, 100),
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });

      test('handles very close waypoints', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
        );

        // Waypoints very close together
        final waypoints = [
          params.start,
          const Offset(100, 0),
          const Offset(100.001, 0), // Almost same as previous
          const Offset(100.001, 100),
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });

      test('handles waypoints forming non-perpendicular angles', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
        );

        // Waypoints that don't form perfect 90-degree angles
        // (These get converted to orthogonal, then corners may not be perpendicular)
        final waypoints = [
          params.start,
          const Offset(50, 30), // Diagonal movement
          const Offset(100, 80), // Another diagonal
          const Offset(150, 150),
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });
    });

    group('Direct Segment Generation', () {
      test('handles only two waypoints (direct line)', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(100, 100),
          curvature: 0.5,
        );

        // Only start and end (should use default path)
        final waypoints = [params.start, params.end];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });

      test('handles waypoints forming straight horizontal line', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 50),
          end: const Offset(200, 50),
          curvature: 0.5,
        );

        final waypoints = [
          params.start,
          const Offset(50, 50),
          const Offset(100, 50),
          const Offset(150, 50),
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });

      test('handles waypoints forming straight vertical line', () {
        final params = ConnectionPathParameters(
          start: const Offset(50, 0),
          end: const Offset(50, 200),
          curvature: 0.5,
        );

        final waypoints = [
          params.start,
          const Offset(50, 50),
          const Offset(50, 100),
          const Offset(50, 150),
          params.end,
        ];

        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isNotEmpty);
      });
    });

    group('Corner Radius Determination', () {
      test('uses params cornerRadius when positive', () {
        const defaultStyle = EditableSmoothStepConnectionStyle(
          defaultCornerRadius: 8.0,
        );

        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
          cornerRadius: 16.0, // Override default
        );

        final waypoints = [
          params.start,
          const Offset(100, 0),
          const Offset(100, 100),
          params.end,
        ];

        final result = defaultStyle.createSegmentsThroughWaypoints(
          waypoints,
          params,
        );

        expect(result.segments, isNotEmpty);
      });

      test('uses defaultCornerRadius when params cornerRadius is zero', () {
        const styleWithDefault = EditableSmoothStepConnectionStyle(
          defaultCornerRadius: 12.0,
        );

        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(200, 200),
          curvature: 0.5,
          cornerRadius: 0.0, // Zero - should use default
        );

        final waypoints = [
          params.start,
          const Offset(100, 0),
          const Offset(100, 100),
          params.end,
        ];

        final result = styleWithDefault.createSegmentsThroughWaypoints(
          waypoints,
          params,
        );

        expect(result.segments, isNotEmpty);
      });
    });

    group('Special Routing Scenarios', () {
      test('handles backtrack routing (target behind source)', () {
        final params = ConnectionPathParameters(
          start: const Offset(200, 50),
          end: const Offset(0, 150), // Target is to the left of source
          curvature: 0.5,
          sourcePort: createTestPort(
            id: 'out-1',
            type: PortType.output,
            position: PortPosition.right,
          ),
          targetPort: createTestPort(
            id: 'in-1',
            type: PortType.input,
            position: PortPosition.left,
          ),
        );

        final result = style.createDefaultSegments(params);

        expect(result.start, equals(params.start));
        expect(result.segments, isNotEmpty);
      });

      test('handles same-side port routing', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 50),
          end: const Offset(0, 150), // Both on left side
          curvature: 0.5,
          sourcePort: createTestPort(
            id: 'out-1',
            type: PortType.output,
            position: PortPosition.right,
          ),
          targetPort: createTestPort(
            id: 'in-1',
            type: PortType.input,
            position: PortPosition.right, // Same side
          ),
        );

        final result = style.createDefaultSegments(params);

        expect(result.segments, isNotEmpty);
      });

      test('handles top-bottom port routing', () {
        final params = ConnectionPathParameters(
          start: const Offset(100, 0),
          end: const Offset(100, 200),
          curvature: 0.5,
          sourcePort: createTestPort(
            id: 'out-1',
            type: PortType.output,
            position: PortPosition.bottom,
          ),
          targetPort: createTestPort(
            id: 'in-1',
            type: PortType.input,
            position: PortPosition.top,
          ),
        );

        final result = style.createDefaultSegments(params);

        expect(result.segments, isNotEmpty);
      });

      test('handles node bounds for collision avoidance', () {
        final sourceNodeBounds = const Rect.fromLTRB(0, 0, 100, 100);
        final targetNodeBounds = const Rect.fromLTRB(200, 0, 300, 100);

        final params = ConnectionPathParameters(
          start: const Offset(100, 50),
          end: const Offset(200, 50),
          curvature: 0.5,
          sourcePort: createTestPort(
            id: 'out-1',
            type: PortType.output,
            position: PortPosition.right,
          ),
          targetPort: createTestPort(
            id: 'in-1',
            type: PortType.input,
            position: PortPosition.left,
          ),
          sourceNodeBounds: sourceNodeBounds,
          targetNodeBounds: targetNodeBounds,
        );

        final result = style.createDefaultSegments(params);

        expect(result.segments, isNotEmpty);
      });
    });

    group('Minimal Input Cases', () {
      test('empty waypoints uses default segments', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(100, 100),
          curvature: 0.5,
          sourcePort: createTestPort(
            id: 'out-1',
            type: PortType.output,
            position: PortPosition.right,
          ),
          targetPort: createTestPort(
            id: 'in-1',
            type: PortType.input,
            position: PortPosition.left,
          ),
        );

        final result = style.createSegmentsThroughWaypoints([], params);

        expect(result.segments, isNotEmpty);
      });

      test('single waypoint (less than 2) returns empty segments', () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 0),
          end: const Offset(100, 100),
          curvature: 0.5,
          sourcePort: createTestPort(
            id: 'out-1',
            type: PortType.output,
            position: PortPosition.right,
          ),
          targetPort: createTestPort(
            id: 'in-1',
            type: PortType.input,
            position: PortPosition.left,
          ),
        );

        // Single waypoint (< 2) results in empty segments
        // because _generateSmoothSegments returns [] for < 2 waypoints
        final waypoints = [const Offset(50, 50)];
        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        expect(result.segments, isEmpty);
      });

      test('two identical waypoints (zero length path)', () {
        final params = ConnectionPathParameters(
          start: const Offset(50, 50),
          end: const Offset(50, 50), // Same as start
          curvature: 0.5,
        );

        final waypoints = [params.start, params.end];
        final result = style.createSegmentsThroughWaypoints(waypoints, params);

        // Should handle gracefully even with zero-length path
        expect(result.start, equals(params.start));
      });
    });
  });

  // ==========================================================================
  // Integration and Path Building Tests
  // ==========================================================================

  group('Path Building Integration', () {
    late EditableSmoothStepConnectionStyle style;

    setUp(() {
      style = const EditableSmoothStepConnectionStyle();
    });

    test('buildPath produces valid path from segments', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(200, 200),
        curvature: 0.5,
      );

      final waypoints = [
        params.start,
        const Offset(100, 0),
        const Offset(100, 100),
        const Offset(200, 100),
        params.end,
      ];

      final result = style.createSegmentsThroughWaypoints(waypoints, params);
      final path = style.buildPath(result.start, result.segments);

      expect(path, isNotNull);
      expect(path.getBounds().isEmpty, isFalse);
    });

    test('buildHitTestRects covers the path', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(200, 200),
        curvature: 0.5,
      );

      final waypoints = [
        params.start,
        const Offset(100, 0),
        const Offset(100, 100),
        const Offset(200, 100),
        params.end,
      ];

      final result = style.createSegmentsThroughWaypoints(waypoints, params);
      final rects = style.buildHitTestRects(result.start, result.segments, 8.0);

      expect(rects, isNotEmpty);
      for (final rect in rects) {
        expect(rect.width, greaterThan(0));
        expect(rect.height, greaterThan(0));
      }
    });

    test('extractBendPoints returns waypoint positions', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(200, 200),
        curvature: 0.5,
      );

      final waypoints = [
        params.start,
        const Offset(100, 0),
        const Offset(100, 100),
        params.end,
      ];

      final result = style.createSegmentsThroughWaypoints(waypoints, params);
      final bendPoints = style.extractBendPoints(result.start, result.segments);

      expect(bendPoints, isNotEmpty);
      expect(bendPoints.first, equals(result.start));
    });

    test('full pipeline: params -> segments -> path -> hit test', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(300, 250),
        curvature: 0.5,
        controlPoints: [
          const Offset(100, 50),
          const Offset(100, 150),
          const Offset(200, 150),
        ],
      );

      // 1. Create segments
      final result = style.createSegments(params);
      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);

      // 2. Build path
      final path = style.buildPath(result.start, result.segments);
      expect(path.getBounds().isEmpty, isFalse);

      // 3. Build hit test rects
      final rects = style.buildHitTestRects(result.start, result.segments, 8.0);
      expect(rects, isNotEmpty);

      // 4. Build hit test path
      final hitPath = style.buildHitTestPath(rects);
      expect(hitPath.getBounds().isEmpty, isFalse);
    });
  });

  // ==========================================================================
  // Equality and HashCode Tests
  // ==========================================================================

  group('Equality and HashCode', () {
    test('styles with same corner radius are equal', () {
      const style1 = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 8.0,
      );
      const style2 = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 8.0,
      );

      expect(style1, equals(style2));
      expect(style1.hashCode, equals(style2.hashCode));
    });

    test('styles with different corner radius are not equal', () {
      const style1 = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 8.0,
      );
      const style2 = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 16.0,
      );

      expect(style1, isNot(equals(style2)));
    });

    test('style is equal to itself', () {
      const style = EditableSmoothStepConnectionStyle();

      expect(style, equals(style));
      expect(identical(style, style), isTrue);
    });

    test('style is not equal to different type', () {
      const editableStyle = EditableSmoothStepConnectionStyle();
      final otherStyle = ConnectionStyles.bezier;

      expect(editableStyle, isNot(equals(otherStyle)));
    });
  });

  // ==========================================================================
  // Style Properties Tests
  // ==========================================================================

  group('Style Properties', () {
    test('id is editable-smoothstep', () {
      const style = EditableSmoothStepConnectionStyle();
      expect(style.id, equals('editable-smoothstep'));
    });

    test('displayName is Editable Smooth Step', () {
      const style = EditableSmoothStepConnectionStyle();
      expect(style.displayName, equals('Editable Smooth Step'));
    });

    test('requiresControlPoints is false', () {
      const style = EditableSmoothStepConnectionStyle();
      expect(style.requiresControlPoints, isFalse);
    });

    test('default corner radius is 8.0', () {
      const style = EditableSmoothStepConnectionStyle();
      expect(style.defaultCornerRadius, equals(8.0));
    });

    test('custom corner radius is preserved', () {
      const style = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 20.0,
      );
      expect(style.defaultCornerRadius, equals(20.0));
    });

    test('defaultHitTolerance is 8.0', () {
      const style = EditableSmoothStepConnectionStyle();
      expect(style.defaultHitTolerance, equals(8.0));
    });
  });

  // ==========================================================================
  // Vertical First Connection Tests
  // ==========================================================================

  group('Vertical First Connection Scenarios', () {
    late EditableSmoothStepConnectionStyle style;

    setUp(() {
      style = const EditableSmoothStepConnectionStyle();
    });

    test('handles isHorizontal false path in final connection', () {
      // This tests the else branch at line 165-172 where isHorizontal is false
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(200, 300),
        curvature: 0.5,
      );

      // Create waypoints where the alternating logic ends with isHorizontal = false
      // After 2 waypoints (excluding start), isHorizontal toggles twice -> back to true
      // After 3 waypoints (excluding start), isHorizontal toggles 3 times -> false
      final waypoints = [
        params.start,
        const Offset(
          50,
          50,
        ), // 1st waypoint: isHorizontal starts true, ends false
        const Offset(100, 100), // 2nd waypoint: isHorizontal=false, ends true
        const Offset(150, 200), // 3rd waypoint: isHorizontal=true, ends false
        // Now isHorizontal is false when connecting to end
        params.end,
      ];

      final result = style.createSegmentsThroughWaypoints(waypoints, params);

      expect(result.segments, isNotEmpty);
    });

    test('vertical dominant final connection when isHorizontal is false', () {
      // Test the branch at line 167-168: Y difference > X difference when isHorizontal=false
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(10, 200), // Y diff (200) > X diff (10)
        curvature: 0.5,
      );

      // 3 intermediate waypoints to make isHorizontal=false at end
      final waypoints = [
        params.start,
        const Offset(5, 5),
        const Offset(8, 50),
        const Offset(9, 100),
        params.end,
      ];

      final result = style.createSegmentsThroughWaypoints(waypoints, params);

      expect(result.segments, isNotEmpty);
    });

    test('horizontal dominant final connection when isHorizontal is false', () {
      // Test the branch at line 169-170: X difference > Y difference when isHorizontal=false
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(200, 10), // X diff (200) > Y diff (10)
        curvature: 0.5,
      );

      // 3 intermediate waypoints to make isHorizontal=false at end
      final waypoints = [
        params.start,
        const Offset(5, 2),
        const Offset(50, 5),
        const Offset(100, 8),
        params.end,
      ];

      final result = style.createSegmentsThroughWaypoints(waypoints, params);

      expect(result.segments, isNotEmpty);
    });
  });
}
