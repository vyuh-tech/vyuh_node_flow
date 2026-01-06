/// Comprehensive tests for connection path styles and segments.
///
/// Tests cover:
/// - ConnectionStyle interface implementations
/// - BezierConnectionStyle through ConnectionStyles.bezier
/// - StraightConnectionStyle through ConnectionStyles.straight
/// - EditablePathConnectionStyle implementations
/// - EditableSmoothStepConnectionStyle path creation
/// - ConnectionPathParameters behavior
/// - Integration with ConnectionStyle interface
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // BezierConnectionStyle Tests (via ConnectionStyles.bezier)
  // ==========================================================================

  group('BezierConnectionStyle', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('has correct id and displayName', () {
      expect(style.id, equals('bezier'));
      expect(style.displayName, equals('Bezier'));
    });

    test('is a ConnectionStyle', () {
      expect(style, isA<ConnectionStyle>());
    });

    test(
      'createSegments returns start and segments for forward connection',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 50),
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
        );

        final result = style.createSegments(params);

        expect(result.start, equals(params.start));
        expect(result.segments, isNotEmpty);
      },
    );

    test('createSegments returns single segment for forward bezier', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
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
      );

      final result = style.createSegments(params);

      // Forward bezier should have a single cubic segment
      expect(result.segments.length, equals(1));
    });

    test(
      'createSegments handles loopback routing when target behind source',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(200, 50),
          end: const Offset(0, 50), // Target behind source
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

        final result = style.createSegments(params);

        expect(result.start, equals(params.start));
        expect(result.segments, isNotEmpty);
        // Loopback routing produces at least one segment
        expect(result.segments.length, greaterThanOrEqualTo(1));
      },
    );

    test('createSegments handles same-side ports', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(0, 150),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.right, // Same side as source
        ),
      );

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('createSegments applies node avoidance when bounds provided', () {
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

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('buildPath creates valid Path from segments', () {
      // Use different Y coordinates to ensure path has non-zero height
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 100),
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

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);

      expect(path, isNotNull);
      // Path bounds should contain start and end points
      final bounds = path.getBounds();
      expect(bounds.left, lessThanOrEqualTo(0));
      expect(bounds.right, greaterThanOrEqualTo(200));
    });

    test('buildHitTestRects creates valid hit test areas', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
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
      );

      final result = style.createSegments(params);
      final rects = style.buildHitTestRects(result.start, result.segments, 8.0);

      expect(rects, isNotEmpty);
      for (final rect in rects) {
        expect(rect.width, greaterThan(0));
        expect(rect.height, greaterThan(0));
      }
    });

    test('extractBendPoints returns start and segment endpoints', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
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
      );

      final result = style.createSegments(params);
      final bendPoints = style.extractBendPoints(result.start, result.segments);

      expect(bendPoints, isNotEmpty);
      expect(bendPoints.first, equals(result.start));
      expect(bendPoints.last, equals(result.segments.last.end));
    });

    test('isEquivalentTo returns true for same style type', () {
      expect(style.isEquivalentTo(ConnectionStyles.bezier), isTrue);
    });

    test('isEquivalentTo returns false for different style type', () {
      expect(style.isEquivalentTo(ConnectionStyles.straight), isFalse);
    });
  });

  // ==========================================================================
  // CustomBezierConnectionStyle Tests (via ConnectionStyles.customBezier)
  // ==========================================================================

  group('CustomBezierConnectionStyle', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.customBezier;
    });

    test('has correct id and displayName', () {
      expect(style.id, equals('customBezier'));
      expect(style.displayName, equals('Custom Bezier'));
    });

    test('createSegments creates valid path', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 50),
        curvature: 0.5,
      );

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });
  });

  // ==========================================================================
  // StraightConnectionStyle Tests (via ConnectionStyles.straight)
  // ==========================================================================

  group('StraightConnectionStyle', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.straight;
    });

    test('has correct id and displayName', () {
      expect(style.id, equals('straight'));
      expect(style.displayName, equals('Straight'));
    });

    test('is a ConnectionStyle', () {
      expect(style, isA<ConnectionStyle>());
    });

    test(
      'createSegments returns start and segments for forward connection',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(0, 50),
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
        );

        final result = style.createSegments(params);

        expect(result.start, equals(params.start));
        expect(result.segments, isNotEmpty);
      },
    );

    test('createSegments returns multiple segments for forward connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
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
      );

      final result = style.createSegments(params);

      // Forward straight connection has 3 segments:
      // 1. Port to extension point
      // 2. Extension to extension
      // 3. Extension to port
      expect(result.segments.length, equals(3));
    });

    test('createSegments handles loopback routing', () {
      final params = ConnectionPathParameters(
        start: const Offset(200, 50),
        end: const Offset(0, 50), // Target behind source
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

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('createSegments handles different port positions', () {
      // Top to bottom
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

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('createSegments handles left port position', () {
      final params = ConnectionPathParameters(
        start: const Offset(200, 50),
        end: const Offset(0, 50),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.left,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.right,
        ),
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('buildPath creates valid Path', () {
      // Use different Y coordinates to ensure path has non-zero height
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 100),
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

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);

      expect(path, isNotNull);
      // Path bounds should contain start and end points
      final bounds = path.getBounds();
      expect(bounds.left, lessThanOrEqualTo(0));
      expect(bounds.right, greaterThanOrEqualTo(200));
    });

    test('buildHitTestRects creates rectangles for each segment', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
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
      );

      final result = style.createSegments(params);
      final rects = style.buildHitTestRects(result.start, result.segments, 8.0);

      expect(rects, isNotEmpty);
    });
  });

  // ==========================================================================
  // StepConnectionStyle Tests (via ConnectionStyles.step and smoothstep)
  // ==========================================================================

  group('StepConnectionStyle', () {
    test('step style has correct id', () {
      expect(ConnectionStyles.step.id, equals('step'));
    });

    test('smoothstep style has correct id', () {
      expect(ConnectionStyles.smoothstep.id, equals('smoothstep'));
    });

    test('step style creates segments', () {
      final params = ConnectionPathParameters(
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

      final result = ConnectionStyles.step.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('smoothstep style creates segments with rounded corners', () {
      final params = ConnectionPathParameters(
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

      final result = ConnectionStyles.smoothstep.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });
  });

  // ==========================================================================
  // EditableSmoothStepConnectionStyle Tests
  // ==========================================================================

  group('EditableSmoothStepConnectionStyle', () {
    late EditableSmoothStepConnectionStyle style;

    setUp(() {
      style = const EditableSmoothStepConnectionStyle();
    });

    test('has correct id and displayName', () {
      expect(style.id, equals('editable-smoothstep'));
      expect(style.displayName, equals('Editable Smooth Step'));
    });

    test('has default corner radius of 8.0', () {
      expect(style.defaultCornerRadius, equals(8.0));
    });

    test('accepts custom corner radius', () {
      const customStyle = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 16.0,
      );

      expect(customStyle.defaultCornerRadius, equals(16.0));
    });

    test('is an EditablePathConnectionStyle', () {
      expect(style, isA<EditablePathConnectionStyle>());
    });

    test('requiresControlPoints returns false', () {
      expect(style.requiresControlPoints, isFalse);
    });

    test('createDefaultSegments generates waypoint-based path', () {
      final params = ConnectionPathParameters(
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

      final result = style.createDefaultSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('createDefaultSegments uses params cornerRadius when > 0', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 150),
        curvature: 0.5,
        cornerRadius: 12.0,
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

      expect(result.segments, isNotEmpty);
    });

    test('createSegments uses control points when provided', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        controlPoints: [const Offset(50, 0), const Offset(50, 100)],
      );

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('createSegments uses default segments when no control points', () {
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

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('createSegmentsThroughWaypoints handles empty waypoints', () {
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

      // Should fall back to default segments
      expect(result.segments, isNotEmpty);
    });

    test('createSegmentsThroughWaypoints handles two waypoints', () {
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

      final waypoints = [params.start, params.end];
      final result = style.createSegmentsThroughWaypoints(waypoints, params);

      // Should fall back to default segments for just start/end
      expect(result.segments, isNotEmpty);
    });

    test('createSegmentsThroughWaypoints handles multiple waypoints', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      final waypoints = [
        params.start,
        const Offset(50, 0),
        const Offset(50, 100),
        params.end,
      ];

      final result = style.createSegmentsThroughWaypoints(waypoints, params);

      expect(result.start, equals(waypoints.first));
      expect(result.segments, isNotEmpty);
    });

    test('createWaypointsWithEnds includes start and end', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      final waypoints = style.createWaypointsWithEnds([], params);

      expect(waypoints.length, equals(2));
      expect(waypoints.first, equals(params.start));
      expect(waypoints.last, equals(params.end));
    });

    test('createWaypointsWithEnds includes control points', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      final controlPoints = [const Offset(50, 0), const Offset(50, 100)];
      final waypoints = style.createWaypointsWithEnds(controlPoints, params);

      expect(waypoints.length, equals(4));
      expect(waypoints[0], equals(params.start));
      expect(waypoints[1], equals(controlPoints[0]));
      expect(waypoints[2], equals(controlPoints[1]));
      expect(waypoints[3], equals(params.end));
    });

    test('createPathThroughWaypoints creates valid path', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      final waypoints = [params.start, const Offset(50, 0), params.end];
      final path = style.createPathThroughWaypoints(waypoints, params);

      expect(path, isNotNull);
      expect(path.getBounds().isEmpty, isFalse);
    });

    test('createDefaultPath creates valid path', () {
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

      final path = style.createDefaultPath(params);

      expect(path, isNotNull);
    });

    test('calculatePointAtPosition returns point on path', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 0),
        curvature: 0.5,
      );

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);
      final midPoint = style.calculatePointAtPosition(path, 0.5);

      expect(midPoint, isNotNull);
    });

    test('calculatePointAtPosition returns null for empty path', () {
      final emptyPath = Path();
      final point = style.calculatePointAtPosition(emptyPath, 0.5);

      expect(point, isNull);
    });

    test('calculatePointAtPosition handles position 0.0', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 0),
        curvature: 0.5,
      );

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);
      final startPoint = style.calculatePointAtPosition(path, 0.0);

      expect(startPoint, isNotNull);
    });

    test('equality includes defaultCornerRadius', () {
      const style1 = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 8.0,
      );
      const style2 = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 8.0,
      );
      const style3 = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 16.0,
      );

      expect(style1, equals(style2));
      expect(style1, isNot(equals(style3)));
    });

    test('hashCode includes defaultCornerRadius', () {
      const style1 = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 8.0,
      );
      const style2 = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 8.0,
      );

      expect(style1.hashCode, equals(style2.hashCode));
    });

    test('handles corner radius of 0 (sharp corners)', () {
      const sharpStyle = EditableSmoothStepConnectionStyle(
        defaultCornerRadius: 0.0,
      );

      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 150),
        curvature: 0.5,
        cornerRadius: 0.0,
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

      final result = sharpStyle.createDefaultSegments(params);

      expect(result.segments, isNotEmpty);
    });
  });

  // ==========================================================================
  // ConnectionPathParameters Tests
  // ==========================================================================

  group('ConnectionPathParameters', () {
    test('creates with required fields', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      expect(params.start, equals(const Offset(0, 0)));
      expect(params.end, equals(const Offset(100, 100)));
      expect(params.curvature, equals(0.5));
    });

    test('has default values for optional fields', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      expect(params.cornerRadius, equals(4.0));
      expect(params.offset, equals(10.0));
      expect(params.backEdgeGap, equals(20.0));
      expect(params.controlPoints, isEmpty);
      expect(params.sourceNodeBounds, isNull);
      expect(params.targetNodeBounds, isNull);
    });

    test('sourceOffset returns offset when source port exists', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        offset: 15.0,
        sourcePort: createTestPort(id: 'out-1', type: PortType.output),
      );

      expect(params.sourceOffset, equals(15.0));
    });

    test('sourceOffset returns 0 when no source port', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        offset: 15.0,
      );

      expect(params.sourceOffset, equals(0.0));
    });

    test('targetOffset returns offset when target port exists', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        offset: 15.0,
        targetPort: createTestPort(id: 'in-1', type: PortType.input),
      );

      expect(params.targetOffset, equals(15.0));
    });

    test('targetOffset returns 0 when no target port', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        offset: 15.0,
      );

      expect(params.targetOffset, equals(0.0));
    });

    test('sourcePosition returns source port position when available', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.bottom,
        ),
      );

      expect(params.sourcePosition, equals(PortPosition.bottom));
    });

    test('sourcePosition returns opposite of target when no source port', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.left,
        ),
      );

      // Opposite of left is right
      expect(params.sourcePosition, equals(PortPosition.right));
    });

    test('sourcePosition returns right as fallback when no ports', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      expect(params.sourcePosition, equals(PortPosition.right));
    });

    test('targetPosition returns target port position when available', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.top,
        ),
      );

      expect(params.targetPosition, equals(PortPosition.top));
    });

    test('targetPosition returns opposite of source when no target port', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
      );

      // Opposite of right is left
      expect(params.targetPosition, equals(PortPosition.left));
    });

    test('targetPosition returns left as fallback when no ports', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      expect(params.targetPosition, equals(PortPosition.left));
    });

    test('equality works correctly', () {
      final params1 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      final params2 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      final params3 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.6, // Different
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('hashCode is consistent', () {
      final params1 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      final params2 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      expect(params1.hashCode, equals(params2.hashCode));
    });

    test('equality considers control points', () {
      final params1 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        controlPoints: [const Offset(50, 50)],
      );

      final params2 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        controlPoints: [const Offset(50, 50)],
      );

      final params3 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        controlPoints: [const Offset(60, 60)],
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('equality considers node bounds', () {
      final params1 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        sourceNodeBounds: const Rect.fromLTRB(0, 0, 50, 50),
      );

      final params2 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        sourceNodeBounds: const Rect.fromLTRB(0, 0, 50, 50),
      );

      final params3 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.5,
        sourceNodeBounds: const Rect.fromLTRB(0, 0, 100, 100),
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });

  // ==========================================================================
  // ConnectionStyle Base Class Tests
  // ==========================================================================

  group('ConnectionStyle Base', () {
    test('defaultHitTolerance is 8.0', () {
      expect(ConnectionStyles.bezier.defaultHitTolerance, equals(8.0));
    });

    test('toString includes id and displayName', () {
      final str = ConnectionStyles.bezier.toString();

      expect(str, contains('bezier'));
      expect(str, contains('Bezier'));
    });

    test('buildHitTestPath creates path from rectangles', () {
      final style = ConnectionStyles.bezier;

      final rects = [
        const Rect.fromLTRB(0, 0, 50, 10),
        const Rect.fromLTRB(50, 0, 100, 10),
      ];

      final path = style.buildHitTestPath(rects);

      expect(path, isNotNull);
      expect(path.getBounds().isEmpty, isFalse);
    });

    test('buildHitTestPath returns empty path for empty list', () {
      final style = ConnectionStyles.bezier;

      final path = style.buildHitTestPath([]);

      expect(path.getBounds().isEmpty, isTrue);
    });

    test('extractBendPoints returns start for empty segments', () {
      final style = ConnectionStyles.bezier;

      final bendPoints = style.extractBendPoints(const Offset(10, 20), []);

      expect(bendPoints.length, equals(1));
      expect(bendPoints[0], equals(const Offset(10, 20)));
    });
  });

  // ==========================================================================
  // Integration Tests
  // ==========================================================================

  group('Style Integration', () {
    test(
      'all built-in styles can create segments for simple forward connection',
      () {
        final styles = ConnectionStyles.all;

        final params = ConnectionPathParameters(
          start: const Offset(0, 50),
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
        );

        for (final style in styles) {
          final result = style.createSegments(params);

          expect(
            result.start,
            equals(params.start),
            reason: '${style.id} should return correct start point',
          );
          expect(
            result.segments,
            isNotEmpty,
            reason: '${style.id} should return segments',
          );
        }
      },
    );

    test('all built-in styles can build path from their segments', () {
      final styles = ConnectionStyles.all;

      final params = ConnectionPathParameters(
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

      for (final style in styles) {
        final result = style.createSegments(params);
        final path = style.buildPath(result.start, result.segments);

        expect(
          path.getBounds().isEmpty,
          isFalse,
          reason: '${style.id} should create non-empty path',
        );
      }
    });

    test(
      'all built-in styles can build hit test rects from their segments',
      () {
        final styles = ConnectionStyles.all;

        final params = ConnectionPathParameters(
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

        for (final style in styles) {
          final result = style.createSegments(params);
          final rects = style.buildHitTestRects(
            result.start,
            result.segments,
            8.0,
          );

          expect(
            rects,
            isNotEmpty,
            reason: '${style.id} should create hit test rects',
          );
        }
      },
    );

    test(
      'all built-in styles handle temporary connections (no target port)',
      () {
        final styles = ConnectionStyles.all;

        final params = ConnectionPathParameters(
          start: const Offset(100, 50),
          end: const Offset(200, 150), // Mouse position
          curvature: 0.5,
          sourcePort: createTestPort(
            id: 'out-1',
            type: PortType.output,
            position: PortPosition.right,
          ),
          // No target port - temporary connection
        );

        for (final style in styles) {
          final result = style.createSegments(params);

          expect(
            result.segments,
            isNotEmpty,
            reason: '${style.id} should handle temporary connection',
          );
        }
      },
    );

    test('bezier style handles self-connection scenario', () {
      final nodeBounds = const Rect.fromLTRB(0, 0, 100, 100);

      final params = ConnectionPathParameters(
        start: const Offset(100, 30), // Right port
        end: const Offset(100, 70), // Right port (same node)
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.right,
        ),
        sourceNodeBounds: nodeBounds,
        targetNodeBounds: nodeBounds, // Same node
      );

      final result = ConnectionStyles.bezier.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('editable style integrated with standard styles', () {
      const editableStyle = EditableSmoothStepConnectionStyle();

      final params = ConnectionPathParameters(
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

      final result = editableStyle.createSegments(params);
      final path = editableStyle.buildPath(result.start, result.segments);
      final rects = editableStyle.buildHitTestRects(
        result.start,
        result.segments,
        8.0,
      );

      expect(result.segments, isNotEmpty);
      expect(path.getBounds().isEmpty, isFalse);
      expect(rects, isNotEmpty);
    });
  });

  // ==========================================================================
  // Edge Cases
  // ==========================================================================

  group('Edge Cases', () {
    test('handles zero-length connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 100),
        end: const Offset(100, 100), // Same as start
        curvature: 0.5,
      );

      final result = ConnectionStyles.bezier.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('handles very long connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(10000, 10000),
        curvature: 0.5,
      );

      final result = ConnectionStyles.bezier.createSegments(params);
      final path = ConnectionStyles.bezier.buildPath(
        result.start,
        result.segments,
      );

      expect(result.segments, isNotEmpty);
      expect(path.getBounds().isEmpty, isFalse);
    });

    test('handles negative coordinates', () {
      final params = ConnectionPathParameters(
        start: const Offset(-100, -100),
        end: const Offset(-200, -200),
        curvature: 0.5,
      );

      final result = ConnectionStyles.bezier.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('handles curvature at extremes', () {
      // Curvature 0
      final params1 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.0,
      );

      // Curvature 1
      final params2 = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 1.0,
      );

      final result1 = ConnectionStyles.bezier.createSegments(params1);
      final result2 = ConnectionStyles.bezier.createSegments(params2);

      expect(result1.segments, isNotEmpty);
      expect(result2.segments, isNotEmpty);
    });

    test('handles all port position combinations', () {
      final positions = PortPosition.values;

      for (final sourcePos in positions) {
        for (final targetPos in positions) {
          final params = ConnectionPathParameters(
            start: const Offset(0, 50),
            end: const Offset(200, 150),
            curvature: 0.5,
            sourcePort: createTestPort(
              id: 'out-1',
              type: PortType.output,
              position: sourcePos,
            ),
            targetPort: createTestPort(
              id: 'in-1',
              type: PortType.input,
              position: targetPos,
            ),
          );

          final result = ConnectionStyles.bezier.createSegments(params);

          expect(
            result.segments,
            isNotEmpty,
            reason: 'Should handle $sourcePos -> $targetPos',
          );
        }
      }
    });
  });
}
