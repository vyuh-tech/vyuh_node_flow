/// Comprehensive unit tests for BezierConnectionStyle.
///
/// Tests cover:
/// - Bezier curve calculations
/// - Control point calculations
/// - Path generation
/// - Edge cases with different start/end positions
/// - Node avoidance adjustments
/// - CustomBezierConnectionStyle
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import 'package:vyuh_node_flow/src/connections/styles/bezier_connection_style.dart';
import 'package:vyuh_node_flow/src/connections/styles/path_segments.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // BezierConnectionStyle Core Properties
  // ==========================================================================

  group('BezierConnectionStyle Core Properties', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('has correct id', () {
      expect(style.id, equals('bezier'));
    });

    test('has correct displayName', () {
      expect(style.displayName, equals('Bezier'));
    });

    test('is a ConnectionStyle instance', () {
      expect(style, isA<ConnectionStyle>());
    });

    test('has default hit tolerance of 8.0', () {
      expect(style.defaultHitTolerance, equals(8.0));
    });

    test('toString includes id and displayName', () {
      final str = style.toString();
      expect(str, contains('bezier'));
      expect(str, contains('Bezier'));
    });

    test('isEquivalentTo returns true for same style', () {
      expect(style.isEquivalentTo(ConnectionStyles.bezier), isTrue);
    });

    test('isEquivalentTo returns false for different styles', () {
      expect(style.isEquivalentTo(ConnectionStyles.straight), isFalse);
      expect(style.isEquivalentTo(ConnectionStyles.step), isFalse);
      expect(style.isEquivalentTo(ConnectionStyles.smoothstep), isFalse);
    });

    test('equality works correctly', () {
      expect(ConnectionStyles.bezier == ConnectionStyles.bezier, isTrue);
      expect(ConnectionStyles.bezier == ConnectionStyles.straight, isFalse);
    });

    test('hashCode is consistent', () {
      expect(
        ConnectionStyles.bezier.hashCode,
        equals(ConnectionStyles.bezier.hashCode),
      );
    });
  });

  // ==========================================================================
  // Forward Bezier Curve Generation
  // ==========================================================================

  group('Forward Bezier Curve Generation', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('creates single cubic segment for forward connection', () {
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
      expect(result.segments.length, equals(1));
      expect(result.segments.first, isA<CubicSegment>());
    });

    test('creates valid path for horizontal forward connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 100),
        end: const Offset(300, 100),
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
      final bounds = path.getBounds();

      expect(bounds.left, lessThanOrEqualTo(0));
      expect(bounds.right, greaterThanOrEqualTo(300));
    });

    test('creates valid path for diagonal forward connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
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

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);
      final bounds = path.getBounds();

      expect(bounds.isEmpty, isFalse);
      expect(bounds.left, lessThanOrEqualTo(0));
      expect(bounds.right, greaterThanOrEqualTo(200));
    });

    test('cubic segment has correct end point', () {
      final params = ConnectionPathParameters(
        start: const Offset(50, 75),
        end: const Offset(250, 125),
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
      final segment = result.segments.first as CubicSegment;

      expect(segment.end, equals(params.end));
    });
  });

  // ==========================================================================
  // Control Point Calculations
  // ==========================================================================

  group('Control Point Calculations', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('control points extend in port direction for right-to-left', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 100),
        end: const Offset(300, 100),
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
      final segment = result.segments.first as CubicSegment;

      // Control point 1 should be to the right of start (source is right port)
      expect(segment.controlPoint1.dx, greaterThan(params.start.dx));
      // Control point 2 should be to the left of end (target is left port)
      expect(segment.controlPoint2.dx, lessThan(params.end.dx));
    });

    test('control points extend correctly for top-to-bottom', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(100, 250),
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
      final segment = result.segments.first as CubicSegment;

      // Control point 1 should be below start (source is bottom port)
      expect(segment.controlPoint1.dy, greaterThan(params.start.dy));
      // Control point 2 should be above end (target is top port)
      expect(segment.controlPoint2.dy, lessThan(params.end.dy));
    });

    test('control points extend correctly for left-to-right', () {
      final params = ConnectionPathParameters(
        start: const Offset(300, 100),
        end: const Offset(100, 100),
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
      final segment = result.segments.first as CubicSegment;

      // Control point 1 should be to the left of start (source is left port)
      expect(segment.controlPoint1.dx, lessThan(params.start.dx));
      // Control point 2 should be to the right of end (target is right port)
      expect(segment.controlPoint2.dx, greaterThan(params.end.dx));
    });

    test('control points extend correctly for bottom-to-top', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 250),
        end: const Offset(100, 50),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.top,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.bottom,
        ),
      );

      final result = style.createSegments(params);
      final segment = result.segments.first as CubicSegment;

      // Control point 1 should be above start (source is top port)
      expect(segment.controlPoint1.dy, lessThan(params.start.dy));
      // Control point 2 should be below end (target is bottom port)
      expect(segment.controlPoint2.dy, greaterThan(params.end.dy));
    });

    test('curvature affects control point distance', () {
      final paramsLow = ConnectionPathParameters(
        start: const Offset(0, 100),
        end: const Offset(200, 100),
        curvature: 0.2,
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

      final paramsHigh = ConnectionPathParameters(
        start: const Offset(0, 100),
        end: const Offset(200, 100),
        curvature: 0.8,
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

      final resultLow = style.createSegments(paramsLow);
      final resultHigh = style.createSegments(paramsHigh);

      final segmentLow = resultLow.segments.first as CubicSegment;
      final segmentHigh = resultHigh.segments.first as CubicSegment;

      // Higher curvature should result in control points further from anchors
      final distanceLow = (segmentLow.controlPoint1.dx - paramsLow.start.dx)
          .abs();
      final distanceHigh = (segmentHigh.controlPoint1.dx - paramsHigh.start.dx)
          .abs();

      expect(distanceHigh, greaterThan(distanceLow));
    });
  });

  // ==========================================================================
  // Node Avoidance Adjustments
  // ==========================================================================

  group('Node Avoidance Adjustments', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('adjusts control point for source node with right port', () {
      final sourceNodeBounds = const Rect.fromLTRB(0, 0, 100, 100);
      final targetNodeBounds = const Rect.fromLTRB(250, 0, 350, 100);

      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(250, 50),
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
      final segment = result.segments.first as CubicSegment;

      // Control point 1 should be to the right of source node bounds
      expect(
        segment.controlPoint1.dx,
        greaterThanOrEqualTo(sourceNodeBounds.right),
      );
    });

    test('adjusts control point for target node with left port', () {
      final sourceNodeBounds = const Rect.fromLTRB(0, 0, 100, 100);
      final targetNodeBounds = const Rect.fromLTRB(250, 0, 350, 100);

      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(250, 50),
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
      final segment = result.segments.first as CubicSegment;

      // Control point 2 should be to the left of target node bounds
      expect(
        segment.controlPoint2.dx,
        lessThanOrEqualTo(targetNodeBounds.left),
      );
    });

    test('adjusts control point for top port', () {
      final sourceNodeBounds = const Rect.fromLTRB(50, 100, 150, 200);

      final params = ConnectionPathParameters(
        start: const Offset(100, 100),
        end: const Offset(100, 0),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.top,
        ),
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.bottom,
        ),
        sourceNodeBounds: sourceNodeBounds,
      );

      final result = style.createSegments(params);
      final segment = result.segments.first as CubicSegment;

      // Control point should be above the source node top
      expect(segment.controlPoint1.dy, lessThanOrEqualTo(sourceNodeBounds.top));
    });

    test('adjusts control point for bottom port', () {
      final sourceNodeBounds = const Rect.fromLTRB(50, 0, 150, 100);

      final params = ConnectionPathParameters(
        start: const Offset(100, 100),
        end: const Offset(100, 250),
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
        sourceNodeBounds: sourceNodeBounds,
      );

      final result = style.createSegments(params);
      final segment = result.segments.first as CubicSegment;

      // Control point should be below the source node bottom
      expect(
        segment.controlPoint1.dy,
        greaterThanOrEqualTo(sourceNodeBounds.bottom),
      );
    });

    test('does not adjust when control point already outside bounds', () {
      // Source node is far enough that control point naturally clears it
      final sourceNodeBounds = const Rect.fromLTRB(0, 0, 50, 100);
      final targetNodeBounds = const Rect.fromLTRB(400, 0, 500, 100);

      final params = ConnectionPathParameters(
        start: const Offset(50, 50),
        end: const Offset(400, 50),
        curvature: 0.5,
        offset: 10.0,
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
      final segment = result.segments.first as CubicSegment;

      // Control points should be outside bounds naturally
      expect(segment.controlPoint1.dx, greaterThan(sourceNodeBounds.right));
      expect(segment.controlPoint2.dx, lessThan(targetNodeBounds.left));
    });

    test('handles node avoidance with only source bounds', () {
      final sourceNodeBounds = const Rect.fromLTRB(0, 0, 100, 100);

      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(250, 50),
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
      );

      final result = style.createSegments(params);
      expect(result.segments, isNotEmpty);
    });

    test('handles node avoidance with only target bounds', () {
      final targetNodeBounds = const Rect.fromLTRB(200, 0, 300, 100);

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
        targetNodeBounds: targetNodeBounds,
      );

      final result = style.createSegments(params);
      expect(result.segments, isNotEmpty);
    });
  });

  // ==========================================================================
  // Loopback Routing
  // ==========================================================================

  group('Loopback Routing', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('uses loopback routing when target is behind source', () {
      final params = ConnectionPathParameters(
        start: const Offset(200, 50),
        end: const Offset(0, 50),
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

      // Loopback routing produces multiple segments (not a single cubic)
      expect(result.segments.length, greaterThanOrEqualTo(1));
      expect(result.start, equals(params.start));
    });

    test('uses loopback routing for same-side ports', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(100, 150),
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
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('uses loopback routing for self-connection', () {
      final nodeBounds = const Rect.fromLTRB(0, 0, 100, 100);

      final params = ConnectionPathParameters(
        start: const Offset(100, 30),
        end: const Offset(100, 70),
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
        targetNodeBounds: nodeBounds,
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('loopback routing creates valid path', () {
      final params = ConnectionPathParameters(
        start: const Offset(200, 50),
        end: const Offset(0, 100),
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

      expect(path.getBounds().isEmpty, isFalse);
    });
  });

  // ==========================================================================
  // Path Building
  // ==========================================================================

  group('Path Building', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('buildPath creates non-empty path', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 100),
        curvature: 0.5,
      );

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);

      expect(path.getBounds().isEmpty, isFalse);
    });

    test('buildPath starts at correct point', () {
      final params = ConnectionPathParameters(
        start: const Offset(50, 75),
        end: const Offset(250, 125),
        curvature: 0.5,
      );

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);
      final bounds = path.getBounds();

      expect(bounds.left, lessThanOrEqualTo(50));
    });

    test('buildPath ends at correct point', () {
      final params = ConnectionPathParameters(
        start: const Offset(50, 75),
        end: const Offset(250, 125),
        curvature: 0.5,
      );

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);
      final bounds = path.getBounds();

      expect(bounds.right, greaterThanOrEqualTo(250));
    });
  });

  // ==========================================================================
  // Hit Testing
  // ==========================================================================

  group('Hit Testing', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('buildHitTestRects creates non-empty list', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 50),
        curvature: 0.5,
      );

      final result = style.createSegments(params);
      final rects = style.buildHitTestRects(result.start, result.segments, 8.0);

      expect(rects, isNotEmpty);
    });

    test('hit test rects have positive dimensions', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 100),
        curvature: 0.5,
      );

      final result = style.createSegments(params);
      final rects = style.buildHitTestRects(result.start, result.segments, 8.0);

      for (final rect in rects) {
        expect(rect.width, greaterThan(0));
        expect(rect.height, greaterThan(0));
      }
    });

    test('hit test rects cover the path', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 50),
        curvature: 0.5,
      );

      final result = style.createSegments(params);
      final rects = style.buildHitTestRects(result.start, result.segments, 8.0);

      // Check that rects span from start to end
      final allLeft = rects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
      final allRight = rects
          .map((r) => r.right)
          .reduce((a, b) => a > b ? a : b);

      expect(allLeft, lessThanOrEqualTo(8.0)); // Start minus tolerance
      expect(allRight, greaterThanOrEqualTo(192.0)); // End minus tolerance
    });

    test('buildHitTestPath creates valid path from rects', () {
      final rects = [
        const Rect.fromLTRB(0, 40, 100, 60),
        const Rect.fromLTRB(100, 40, 200, 60),
      ];

      final path = style.buildHitTestPath(rects);

      expect(path.getBounds().isEmpty, isFalse);
    });

    test('buildHitTestPath returns empty path for empty list', () {
      final path = style.buildHitTestPath([]);

      expect(path.getBounds().isEmpty, isTrue);
    });
  });

  // ==========================================================================
  // Bend Points Extraction
  // ==========================================================================

  group('Bend Points Extraction', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('extractBendPoints returns start and end for forward bezier', () {
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

      expect(bendPoints.first, equals(result.start));
      expect(bendPoints.last, equals(params.end));
    });

    test('extractBendPoints returns only start for empty segments', () {
      final bendPoints = style.extractBendPoints(const Offset(10, 20), []);

      expect(bendPoints.length, equals(1));
      expect(bendPoints[0], equals(const Offset(10, 20)));
    });

    test('extractBendPoints includes all segment endpoints for loopback', () {
      final params = ConnectionPathParameters(
        start: const Offset(200, 50),
        end: const Offset(0, 50),
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

      // Should have at least start + each segment endpoint
      expect(bendPoints.length, equals(result.segments.length + 1));
      expect(bendPoints.first, equals(result.start));
      expect(bendPoints.last, equals(result.segments.last.end));
    });
  });

  // ==========================================================================
  // Temporary Connections (no target port)
  // ==========================================================================

  group('Temporary Connections', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('handles temporary connection from output port', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(250, 100),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
        // No target port
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
      expect(result.start, equals(params.start));
    });

    test('handles temporary connection from input port', () {
      final params = ConnectionPathParameters(
        start: const Offset(250, 100),
        end: const Offset(100, 50),
        curvature: 0.5,
        // No source port
        targetPort: createTestPort(
          id: 'in-1',
          type: PortType.input,
          position: PortPosition.left,
        ),
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('temporary connection creates valid path', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(300, 150),
        curvature: 0.5,
        sourcePort: createTestPort(
          id: 'out-1',
          type: PortType.output,
          position: PortPosition.right,
        ),
      );

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);

      expect(path.getBounds().isEmpty, isFalse);
    });
  });

  // ==========================================================================
  // Edge Cases
  // ==========================================================================

  group('Edge Cases', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test('handles zero-length connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 100),
        end: const Offset(100, 100),
        curvature: 0.5,
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('handles very short connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(100, 100),
        end: const Offset(101, 100),
        curvature: 0.5,
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('handles very long connection', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(10000, 5000),
        curvature: 0.5,
      );

      final result = style.createSegments(params);
      final path = style.buildPath(result.start, result.segments);

      expect(result.segments, isNotEmpty);
      expect(path.getBounds().isEmpty, isFalse);
    });

    test('handles negative coordinates', () {
      final params = ConnectionPathParameters(
        start: const Offset(-100, -50),
        end: const Offset(-300, -150),
        curvature: 0.5,
      );

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('handles curvature of 0', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 0.0,
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('handles curvature of 1', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 1.0,
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
    });

    test('handles very high curvature', () {
      final params = ConnectionPathParameters(
        start: const Offset(0, 0),
        end: const Offset(100, 100),
        curvature: 2.0,
      );

      final result = style.createSegments(params);

      expect(result.segments, isNotEmpty);
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

          final result = style.createSegments(params);

          expect(
            result.segments,
            isNotEmpty,
            reason: 'Should handle $sourcePos -> $targetPos',
          );
        }
      }
    });
  });

  // ==========================================================================
  // CustomBezierConnectionStyle
  // ==========================================================================

  group('CustomBezierConnectionStyle', () {
    test('has correct id', () {
      expect(ConnectionStyles.customBezier.id, equals('customBezier'));
    });

    test('has correct displayName', () {
      expect(
        ConnectionStyles.customBezier.displayName,
        equals('Custom Bezier'),
      );
    });

    test('default curvature factor is 1.0', () {
      const style = CustomBezierConnectionStyle();
      expect(style.customCurvatureFactor, equals(1.0));
    });

    test('default asymmetricControls is false', () {
      const style = CustomBezierConnectionStyle();
      expect(style.asymmetricControls, isFalse);
    });

    test('accepts custom curvature factor', () {
      const style = CustomBezierConnectionStyle(customCurvatureFactor: 1.5);
      expect(style.customCurvatureFactor, equals(1.5));
    });

    test('accepts asymmetricControls', () {
      const style = CustomBezierConnectionStyle(asymmetricControls: true);
      expect(style.asymmetricControls, isTrue);
    });

    test('creates valid segments', () {
      const style = CustomBezierConnectionStyle();

      final params = ConnectionPathParameters(
        start: const Offset(0, 50),
        end: const Offset(200, 50),
        curvature: 0.5,
      );

      final result = style.createSegments(params);

      expect(result.start, equals(params.start));
      expect(result.segments, isNotEmpty);
    });

    test('curvature factor affects curve shape', () {
      const styleLow = CustomBezierConnectionStyle(customCurvatureFactor: 0.5);
      const styleHigh = CustomBezierConnectionStyle(customCurvatureFactor: 2.0);

      final params = ConnectionPathParameters(
        start: const Offset(0, 100),
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

      final resultLow = styleLow.createSegments(params);
      final resultHigh = styleHigh.createSegments(params);

      // Both should produce valid segments
      expect(resultLow.segments, isNotEmpty);
      expect(resultHigh.segments, isNotEmpty);

      // If both are cubic segments, check control point positions differ
      if (resultLow.segments.first is CubicSegment &&
          resultHigh.segments.first is CubicSegment) {
        final segmentLow = resultLow.segments.first as CubicSegment;
        final segmentHigh = resultHigh.segments.first as CubicSegment;

        expect(
          segmentLow.controlPoint1,
          isNot(equals(segmentHigh.controlPoint1)),
        );
      }
    });

    test('equality considers customCurvatureFactor', () {
      const style1 = CustomBezierConnectionStyle(customCurvatureFactor: 1.0);
      const style2 = CustomBezierConnectionStyle(customCurvatureFactor: 1.0);
      const style3 = CustomBezierConnectionStyle(customCurvatureFactor: 1.5);

      expect(style1, equals(style2));
      expect(style1, isNot(equals(style3)));
    });

    test('equality considers asymmetricControls', () {
      const style1 = CustomBezierConnectionStyle(asymmetricControls: false);
      const style2 = CustomBezierConnectionStyle(asymmetricControls: false);
      const style3 = CustomBezierConnectionStyle(asymmetricControls: true);

      expect(style1, equals(style2));
      expect(style1, isNot(equals(style3)));
    });

    test('hashCode is consistent', () {
      const style1 = CustomBezierConnectionStyle(
        customCurvatureFactor: 1.5,
        asymmetricControls: true,
      );
      const style2 = CustomBezierConnectionStyle(
        customCurvatureFactor: 1.5,
        asymmetricControls: true,
      );

      expect(style1.hashCode, equals(style2.hashCode));
    });

    test('hashCode differs for different parameters', () {
      const style1 = CustomBezierConnectionStyle(customCurvatureFactor: 1.0);
      const style2 = CustomBezierConnectionStyle(customCurvatureFactor: 2.0);

      expect(style1.hashCode, isNot(equals(style2.hashCode)));
    });
  });

  // ==========================================================================
  // Integration Tests
  // ==========================================================================

  group('Integration Tests', () {
    late ConnectionStyle style;

    setUp(() {
      style = ConnectionStyles.bezier;
    });

    test(
      'complete workflow: createSegments -> buildPath -> buildHitTestRects',
      () {
        final params = ConnectionPathParameters(
          start: const Offset(50, 100),
          end: const Offset(250, 150),
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
          sourceNodeBounds: const Rect.fromLTRB(0, 50, 50, 150),
          targetNodeBounds: const Rect.fromLTRB(250, 100, 350, 200),
        );

        // Step 1: Create segments
        final result = style.createSegments(params);
        expect(result.segments, isNotEmpty);

        // Step 2: Build path
        final path = style.buildPath(result.start, result.segments);
        expect(path.getBounds().isEmpty, isFalse);

        // Step 3: Build hit test rects
        final rects = style.buildHitTestRects(
          result.start,
          result.segments,
          8.0,
        );
        expect(rects, isNotEmpty);

        // Step 4: Extract bend points
        final bendPoints = style.extractBendPoints(
          result.start,
          result.segments,
        );
        expect(bendPoints.first, equals(result.start));
        expect(bendPoints.last, equals(result.segments.last.end));
      },
    );

    test('bezier handles complex scenario with all features', () {
      final sourceNodeBounds = const Rect.fromLTRB(0, 0, 100, 100);
      final targetNodeBounds = const Rect.fromLTRB(300, 50, 400, 150);

      final params = ConnectionPathParameters(
        start: const Offset(100, 50),
        end: const Offset(300, 100),
        curvature: 0.6,
        cornerRadius: 8.0,
        offset: 20.0,
        backEdgeGap: 30.0,
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

      final path = style.buildPath(result.start, result.segments);
      expect(path.getBounds().isEmpty, isFalse);
    });
  });
}
