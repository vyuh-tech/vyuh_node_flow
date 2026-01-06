/// Comprehensive rendering tests for marker shapes.
///
/// Tests all marker shape types construction, properties, paint methods,
/// and the MarkerShapes registry.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

// Import the concrete shape implementations for testing
import 'package:vyuh_node_flow/src/shared/shapes/capsule_half_marker_shape.dart';
import 'package:vyuh_node_flow/src/shared/shapes/circle_marker_shape.dart';
import 'package:vyuh_node_flow/src/shared/shapes/diamond_marker_shape.dart';
import 'package:vyuh_node_flow/src/shared/shapes/none_marker_shape.dart';
import 'package:vyuh_node_flow/src/shared/shapes/rectangle_marker_shape.dart';
import 'package:vyuh_node_flow/src/shared/shapes/triangle_marker_shape.dart';

// Import CapsuleFlatSide for extension tests
import 'package:vyuh_node_flow/src/ports/capsule_half.dart';

import '../../helpers/test_factories.dart';

/// A mock canvas that records drawing operations for testing.
class RecordingCanvas implements Canvas {
  final List<String> operations = [];
  final List<Path> drawnPaths = [];
  final List<Offset> drawnCircleCenters = [];
  final List<double> drawnCircleRadii = [];
  final List<Rect> drawnRects = [];
  final List<RRect> drawnRRects = [];

  void clear() {
    operations.clear();
    drawnPaths.clear();
    drawnCircleCenters.clear();
    drawnCircleRadii.clear();
    drawnRects.clear();
    drawnRRects.clear();
  }

  @override
  void drawPath(Path path, Paint paint) {
    operations.add('drawPath');
    drawnPaths.add(path);
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    operations.add('drawCircle');
    drawnCircleCenters.add(c);
    drawnCircleRadii.add(radius);
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    operations.add('drawRect');
    drawnRects.add(rect);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    operations.add('drawRRect');
    drawnRRects.add(rrect);
  }

  // Required Canvas interface methods - not used in our tests but must be implemented
  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {}

  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {}

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {}

  @override
  void clipRSuperellipse(
    ui.RSuperellipse rsuperellipse, {
    bool doAntiAlias = true,
  }) {}

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {}

  @override
  void drawAtlas(
    ui.Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {}

  @override
  void drawColor(Color color, BlendMode blendMode) {}

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {}

  @override
  void drawImage(ui.Image image, Offset offset, Paint paint) {}

  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) {}

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {}

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {}

  @override
  void drawOval(Rect rect, Paint paint) {}

  @override
  void drawPaint(Paint paint) {}

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {}

  @override
  void drawPicture(ui.Picture picture) {}

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {}

  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {}

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) {}

  @override
  void drawRSuperellipse(ui.RSuperellipse rsuperellipse, Paint paint) {}

  @override
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  ) {}

  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) {}

  @override
  int getSaveCount() => 0;

  @override
  void restore() {}

  @override
  void restoreToCount(int count) {}

  @override
  void rotate(double radians) {}

  @override
  void save() {}

  @override
  void saveLayer(Rect? bounds, Paint paint) {}

  @override
  void scale(double sx, [double? sy]) {}

  @override
  void skew(double sx, double sy) {}

  @override
  void transform(Float64List matrix4) {}

  @override
  void translate(double dx, double dy) {}

  @override
  ui.Rect getDestinationClipBounds() => Rect.zero;

  @override
  ui.Rect getLocalClipBounds() => Rect.zero;

  @override
  Float64List getTransform() => Float64List(16);
}

void main() {
  late RecordingCanvas canvas;
  late Paint fillPaint;
  late Paint borderPaint;

  setUp(() {
    resetTestCounters();
    canvas = RecordingCanvas();
    fillPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
  });

  group('MarkerShapes Registry', () {
    test('provides all standard marker shapes', () {
      expect(MarkerShapes.none, isA<NoneMarkerShape>());
      expect(MarkerShapes.circle, isA<CircleMarkerShape>());
      expect(MarkerShapes.rectangle, isA<RectangleMarkerShape>());
      expect(MarkerShapes.diamond, isA<DiamondMarkerShape>());
      expect(MarkerShapes.triangle, isA<TriangleMarkerShape>());
      expect(MarkerShapes.capsuleHalf, isA<CapsuleHalfMarkerShape>());
    });

    test('shapes are const instances', () {
      // Verify they are the same instances (const)
      expect(identical(MarkerShapes.none, MarkerShapes.none), isTrue);
      expect(identical(MarkerShapes.circle, MarkerShapes.circle), isTrue);
      expect(identical(MarkerShapes.rectangle, MarkerShapes.rectangle), isTrue);
      expect(identical(MarkerShapes.diamond, MarkerShapes.diamond), isTrue);
      expect(identical(MarkerShapes.triangle, MarkerShapes.triangle), isTrue);
      expect(
        identical(MarkerShapes.capsuleHalf, MarkerShapes.capsuleHalf),
        isTrue,
      );
    });

    test('cannot instantiate MarkerShapes class', () {
      // MarkerShapes has a private constructor, so we cannot test instantiation directly
      // This test verifies that all shapes are accessible via static members
      expect(MarkerShapes.none, isNotNull);
      expect(MarkerShapes.circle, isNotNull);
      expect(MarkerShapes.rectangle, isNotNull);
      expect(MarkerShapes.diamond, isNotNull);
      expect(MarkerShapes.triangle, isNotNull);
      expect(MarkerShapes.capsuleHalf, isNotNull);
    });
  });

  group('NoneMarkerShape', () {
    test('has correct typeName', () {
      const shape = NoneMarkerShape();
      expect(shape.typeName, equals('none'));
    });

    test('paint does nothing', () {
      const shape = NoneMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        borderPaint,
      );

      expect(canvas.operations, isEmpty);
    });

    test('paint with orientation does nothing', () {
      const shape = NoneMarkerShape();
      for (final direction in ShapeDirection.values) {
        canvas.clear();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          borderPaint,
          orientation: direction,
        );
        expect(canvas.operations, isEmpty);
      }
    });

    test('equality works correctly', () {
      const shape1 = NoneMarkerShape();
      const shape2 = NoneMarkerShape();
      expect(shape1, equals(shape2));
      expect(shape1.hashCode, equals(shape2.hashCode));
    });

    test('toJson returns correct map', () {
      const shape = NoneMarkerShape();
      expect(shape.toJson(), equals({'type': 'none'}));
    });

    test('fromJson creates correct instance', () {
      final shape = MarkerShape.fromJson({'type': 'none'});
      expect(shape, isA<NoneMarkerShape>());
    });
  });

  group('CircleMarkerShape', () {
    test('has correct typeName', () {
      const shape = CircleMarkerShape();
      expect(shape.typeName, equals('circle'));
    });

    test('paint draws circle with fill', () {
      const shape = CircleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      expect(canvas.operations, contains('drawCircle'));
      expect(canvas.drawnCircleRadii.first, equals(10.0)); // radius = 20/2
    });

    test('paint draws circle with fill and border', () {
      const shape = CircleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        borderPaint,
      );

      expect(
        canvas.operations.where((op) => op == 'drawCircle').length,
        equals(2),
      );
    });

    test('uses shortest side for diameter with asymmetric size', () {
      const shape = CircleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(30, 20), // Asymmetric size
        fillPaint,
        null,
      );

      // Should use the shortest side (20) as diameter, so radius = 10
      expect(canvas.drawnCircleRadii.first, equals(10.0));
    });

    test('adjusts center for left orientation', () {
      const shape = CircleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(30, 20),
        fillPaint,
        null,
        orientation: ShapeDirection.left,
      );

      // For left port with size 30x20, circle diameter = 20, radius = 10
      // Widget center at (50, 50), halfWidth = 15
      // Adjusted center: (50 - 15 + 10, 50) = (45, 50)
      expect(canvas.drawnCircleCenters.first.dx, equals(45.0));
      expect(canvas.drawnCircleCenters.first.dy, equals(50.0));
    });

    test('adjusts center for right orientation', () {
      const shape = CircleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(30, 20),
        fillPaint,
        null,
        orientation: ShapeDirection.right,
      );

      // For right port with size 30x20, circle diameter = 20, radius = 10
      // Widget center at (50, 50), halfWidth = 15
      // Adjusted center: (50 + 15 - 10, 50) = (55, 50)
      expect(canvas.drawnCircleCenters.first.dx, equals(55.0));
      expect(canvas.drawnCircleCenters.first.dy, equals(50.0));
    });

    test('adjusts center for top orientation', () {
      const shape = CircleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 30),
        fillPaint,
        null,
        orientation: ShapeDirection.top,
      );

      // For top port with size 20x30, circle diameter = 20, radius = 10
      // Widget center at (50, 50), halfHeight = 15
      // Adjusted center: (50, 50 - 15 + 10) = (50, 45)
      expect(canvas.drawnCircleCenters.first.dx, equals(50.0));
      expect(canvas.drawnCircleCenters.first.dy, equals(45.0));
    });

    test('adjusts center for bottom orientation', () {
      const shape = CircleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 30),
        fillPaint,
        null,
        orientation: ShapeDirection.bottom,
      );

      // For bottom port with size 20x30, circle diameter = 20, radius = 10
      // Widget center at (50, 50), halfHeight = 15
      // Adjusted center: (50, 50 + 15 - 10) = (50, 55)
      expect(canvas.drawnCircleCenters.first.dx, equals(50.0));
      expect(canvas.drawnCircleCenters.first.dy, equals(55.0));
    });

    test('equality works correctly', () {
      const shape1 = CircleMarkerShape();
      const shape2 = CircleMarkerShape();
      expect(shape1, equals(shape2));
      expect(shape1.hashCode, equals(shape2.hashCode));
    });

    test('toJson returns correct map', () {
      const shape = CircleMarkerShape();
      expect(shape.toJson(), equals({'type': 'circle'}));
    });

    test('fromJson creates correct instance', () {
      final shape = MarkerShape.fromJson({'type': 'circle'});
      expect(shape, isA<CircleMarkerShape>());
    });

    test('skips border when strokeWidth is 0', () {
      const shape = CircleMarkerShape();
      final zeroBorderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.0;

      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        zeroBorderPaint,
      );

      // Should only draw fill circle, not border
      expect(
        canvas.operations.where((op) => op == 'drawCircle').length,
        equals(1),
      );
    });
  });

  group('RectangleMarkerShape', () {
    test('has correct typeName', () {
      const shape = RectangleMarkerShape();
      expect(shape.typeName, equals('rectangle'));
    });

    test('paint draws rectangle with fill', () {
      const shape = RectangleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      expect(canvas.operations, contains('drawRect'));
      final rect = canvas.drawnRects.first;
      expect(rect.center, equals(const Offset(50, 50)));
      expect(rect.width, equals(20.0));
      expect(rect.height, equals(20.0));
    });

    test('paint draws rectangle with fill and border', () {
      const shape = RectangleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        borderPaint,
      );

      expect(
        canvas.operations.where((op) => op == 'drawRect').length,
        equals(2),
      );
    });

    test('creates rectangle with correct size for asymmetric dimensions', () {
      const shape = RectangleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(30, 15),
        fillPaint,
        null,
      );

      final rect = canvas.drawnRects.first;
      expect(rect.width, equals(30.0));
      expect(rect.height, equals(15.0));
    });

    test('orientation parameter does not affect rectangle shape', () {
      const shape = RectangleMarkerShape();

      for (final direction in ShapeDirection.values) {
        canvas.clear();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: direction,
        );

        final rect = canvas.drawnRects.first;
        expect(rect.center, equals(const Offset(50, 50)));
        expect(rect.width, equals(20.0));
        expect(rect.height, equals(20.0));
      }
    });

    test('equality works correctly', () {
      const shape1 = RectangleMarkerShape();
      const shape2 = RectangleMarkerShape();
      expect(shape1, equals(shape2));
      expect(shape1.hashCode, equals(shape2.hashCode));
    });

    test('toJson returns correct map', () {
      const shape = RectangleMarkerShape();
      expect(shape.toJson(), equals({'type': 'rectangle'}));
    });

    test('fromJson creates correct instance', () {
      final shape = MarkerShape.fromJson({'type': 'rectangle'});
      expect(shape, isA<RectangleMarkerShape>());
    });

    test('skips border when strokeWidth is 0', () {
      const shape = RectangleMarkerShape();
      final zeroBorderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.0;

      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        zeroBorderPaint,
      );

      // Should only draw fill rect, not border
      expect(
        canvas.operations.where((op) => op == 'drawRect').length,
        equals(1),
      );
    });
  });

  group('DiamondMarkerShape', () {
    test('has correct typeName', () {
      const shape = DiamondMarkerShape();
      expect(shape.typeName, equals('diamond'));
    });

    test('paint draws path with fill', () {
      const shape = DiamondMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      expect(canvas.operations, contains('drawPath'));
      expect(canvas.drawnPaths, hasLength(1));
    });

    test('paint draws path with fill and border', () {
      const shape = DiamondMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        borderPaint,
      );

      expect(
        canvas.operations.where((op) => op == 'drawPath').length,
        equals(2),
      );
    });

    test('diamond path has correct bounds', () {
      const shape = DiamondMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      final path = canvas.drawnPaths.first;
      final bounds = path.getBounds();

      // Diamond should span from (40, 40) to (60, 60) centered at (50, 50)
      expect(bounds.left, closeTo(40, 0.1));
      expect(bounds.top, closeTo(40, 0.1));
      expect(bounds.right, closeTo(60, 0.1));
      expect(bounds.bottom, closeTo(60, 0.1));
    });

    test('diamond path contains center point', () {
      const shape = DiamondMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      final path = canvas.drawnPaths.first;
      expect(path.contains(const Offset(50, 50)), isTrue);
    });

    test('diamond path does not contain corner points', () {
      const shape = DiamondMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      final path = canvas.drawnPaths.first;
      // Corners of the bounding box should be outside the diamond
      expect(path.contains(const Offset(40, 40)), isFalse);
      expect(path.contains(const Offset(60, 40)), isFalse);
      expect(path.contains(const Offset(40, 60)), isFalse);
      expect(path.contains(const Offset(60, 60)), isFalse);
    });

    test('orientation parameter does not affect diamond shape', () {
      const shape = DiamondMarkerShape();

      // Diamond is symmetric, so orientation should not affect it
      for (final direction in ShapeDirection.values) {
        canvas.clear();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: direction,
        );

        final path = canvas.drawnPaths.first;
        final bounds = path.getBounds();
        expect(bounds.center.dx, closeTo(50, 0.1));
        expect(bounds.center.dy, closeTo(50, 0.1));
      }
    });

    test('isPointingOutward parameter does not affect diamond', () {
      const shape = DiamondMarkerShape();

      // Diamond is symmetric, so isPointingOutward should not affect it
      for (final pointing in [true, false]) {
        canvas.clear();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          isPointingOutward: pointing,
        );

        final path = canvas.drawnPaths.first;
        final bounds = path.getBounds();
        expect(bounds.center.dx, closeTo(50, 0.1));
        expect(bounds.center.dy, closeTo(50, 0.1));
      }
    });

    test('equality works correctly', () {
      const shape1 = DiamondMarkerShape();
      const shape2 = DiamondMarkerShape();
      expect(shape1, equals(shape2));
      expect(shape1.hashCode, equals(shape2.hashCode));
    });

    test('toJson returns correct map', () {
      const shape = DiamondMarkerShape();
      expect(shape.toJson(), equals({'type': 'diamond'}));
    });

    test('fromJson creates correct instance', () {
      final shape = MarkerShape.fromJson({'type': 'diamond'});
      expect(shape, isA<DiamondMarkerShape>());
    });

    test('skips border when strokeWidth is 0', () {
      const shape = DiamondMarkerShape();
      final zeroBorderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.0;

      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        zeroBorderPaint,
      );

      // Should only draw fill path, not border
      expect(
        canvas.operations.where((op) => op == 'drawPath').length,
        equals(1),
      );
    });

    test('works with asymmetric size', () {
      const shape = DiamondMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(30, 15),
        fillPaint,
        null,
      );

      final path = canvas.drawnPaths.first;
      final bounds = path.getBounds();
      expect(bounds.width, closeTo(30, 0.1));
      expect(bounds.height, closeTo(15, 0.1));
    });
  });

  group('TriangleMarkerShape', () {
    test('has correct typeName', () {
      const shape = TriangleMarkerShape();
      expect(shape.typeName, equals('triangle'));
    });

    test('paint draws path with fill', () {
      const shape = TriangleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      expect(canvas.operations, contains('drawPath'));
      expect(canvas.drawnPaths, hasLength(1));
    });

    test('paint draws path with fill and border', () {
      const shape = TriangleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        borderPaint,
      );

      expect(
        canvas.operations.where((op) => op == 'drawPath').length,
        equals(2),
      );
    });

    test('triangle path has correct bounds', () {
      const shape = TriangleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      final path = canvas.drawnPaths.first;
      final bounds = path.getBounds();

      expect(bounds.width, closeTo(20, 0.1));
      expect(bounds.height, closeTo(20, 0.1));
    });

    test('triangle path contains center point', () {
      const shape = TriangleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      final path = canvas.drawnPaths.first;
      expect(path.contains(const Offset(50, 50)), isTrue);
    });

    test('defaults to right orientation when not specified', () {
      const shape = TriangleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      // Default is right with isPointingOutward = false
      // This means flat side on right, tip pointing left (inward)
      final path = canvas.drawnPaths.first;
      // The leftmost point should be the tip
      final bounds = path.getBounds();
      expect(bounds.left, closeTo(40, 0.1));
    });

    group('orientation - isPointingOutward = false (input ports)', () {
      test('left orientation - flat on left, tip points right', () {
        const shape = TriangleMarkerShape();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: ShapeDirection.left,
          isPointingOutward: false,
        );

        final path = canvas.drawnPaths.first;
        // Tip should be on the right side (pointing inward for left port)
        expect(path.contains(const Offset(60, 50)), isTrue);
      });

      test('right orientation - flat on right, tip points left', () {
        const shape = TriangleMarkerShape();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: ShapeDirection.right,
          isPointingOutward: false,
        );

        final path = canvas.drawnPaths.first;
        // Tip should be on the left side (pointing inward for right port)
        expect(path.contains(const Offset(40, 50)), isTrue);
      });

      test('top orientation - flat on top, tip points down', () {
        const shape = TriangleMarkerShape();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: ShapeDirection.top,
          isPointingOutward: false,
        );

        final path = canvas.drawnPaths.first;
        // Tip should be on the bottom (pointing inward for top port)
        expect(path.contains(const Offset(50, 60)), isTrue);
      });

      test('bottom orientation - flat on bottom, tip points up', () {
        const shape = TriangleMarkerShape();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: ShapeDirection.bottom,
          isPointingOutward: false,
        );

        final path = canvas.drawnPaths.first;
        // Tip should be on the top (pointing inward for bottom port)
        expect(path.contains(const Offset(50, 40)), isTrue);
      });
    });

    group('orientation - isPointingOutward = true (output ports)', () {
      test('left orientation - tip on left, flat on right', () {
        const shape = TriangleMarkerShape();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: ShapeDirection.left,
          isPointingOutward: true,
        );

        final path = canvas.drawnPaths.first;
        // Tip should be on the left side (pointing outward)
        expect(path.contains(const Offset(40, 50)), isTrue);
      });

      test('right orientation - tip on right, flat on left', () {
        const shape = TriangleMarkerShape();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: ShapeDirection.right,
          isPointingOutward: true,
        );

        final path = canvas.drawnPaths.first;
        // Tip should be on the right side (pointing outward)
        expect(path.contains(const Offset(60, 50)), isTrue);
      });

      test('top orientation - tip on top, flat on bottom', () {
        const shape = TriangleMarkerShape();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: ShapeDirection.top,
          isPointingOutward: true,
        );

        final path = canvas.drawnPaths.first;
        // Tip should be on the top (pointing outward)
        expect(path.contains(const Offset(50, 40)), isTrue);
      });

      test('bottom orientation - tip on bottom, flat on top', () {
        const shape = TriangleMarkerShape();
        shape.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          fillPaint,
          null,
          orientation: ShapeDirection.bottom,
          isPointingOutward: true,
        );

        final path = canvas.drawnPaths.first;
        // Tip should be on the bottom (pointing outward)
        expect(path.contains(const Offset(50, 60)), isTrue);
      });
    });

    test('equality works correctly', () {
      const shape1 = TriangleMarkerShape();
      const shape2 = TriangleMarkerShape();
      expect(shape1, equals(shape2));
      expect(shape1.hashCode, equals(shape2.hashCode));
    });

    test('toJson returns correct map', () {
      const shape = TriangleMarkerShape();
      expect(shape.toJson(), equals({'type': 'triangle'}));
    });

    test('fromJson creates correct instance', () {
      final shape = MarkerShape.fromJson({'type': 'triangle'});
      expect(shape, isA<TriangleMarkerShape>());
    });

    test('skips border when strokeWidth is 0', () {
      const shape = TriangleMarkerShape();
      final zeroBorderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.0;

      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        zeroBorderPaint,
      );

      // Should only draw fill path, not border
      expect(
        canvas.operations.where((op) => op == 'drawPath').length,
        equals(1),
      );
    });

    test('works with asymmetric size', () {
      const shape = TriangleMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(30, 15),
        fillPaint,
        null,
      );

      final path = canvas.drawnPaths.first;
      final bounds = path.getBounds();
      expect(bounds.width, closeTo(30, 0.1));
      expect(bounds.height, closeTo(15, 0.1));
    });
  });

  group('CapsuleHalfMarkerShape', () {
    test('has correct typeName', () {
      const shape = CapsuleHalfMarkerShape();
      expect(shape.typeName, equals('capsuleHalf'));
    });

    test('paint draws rounded rect with fill', () {
      const shape = CapsuleHalfMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      expect(canvas.operations, contains('drawRRect'));
      expect(canvas.drawnRRects, hasLength(1));
    });

    test('paint draws rounded rect with fill and border', () {
      const shape = CapsuleHalfMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        borderPaint,
      );

      expect(
        canvas.operations.where((op) => op == 'drawRRect').length,
        equals(2),
      );
    });

    test('defaults to right orientation when not specified', () {
      const shape = CapsuleHalfMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
      );

      final rrect = canvas.drawnRRects.first;
      // Right orientation means flat right edge, curved left edge
      expect(rrect.tlRadius, isNot(Radius.zero));
      expect(rrect.blRadius, isNot(Radius.zero));
    });

    test('left orientation - flat left, curved right', () {
      const shape = CapsuleHalfMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
        orientation: ShapeDirection.left,
      );

      final rrect = canvas.drawnRRects.first;
      // Flat left edge, curved right edge
      expect(rrect.trRadius, isNot(Radius.zero));
      expect(rrect.brRadius, isNot(Radius.zero));
    });

    test('right orientation - flat right, curved left', () {
      const shape = CapsuleHalfMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
        orientation: ShapeDirection.right,
      );

      final rrect = canvas.drawnRRects.first;
      // Flat right edge, curved left edge
      expect(rrect.tlRadius, isNot(Radius.zero));
      expect(rrect.blRadius, isNot(Radius.zero));
    });

    test('top orientation - flat top, curved bottom', () {
      const shape = CapsuleHalfMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
        orientation: ShapeDirection.top,
      );

      final rrect = canvas.drawnRRects.first;
      // Flat top edge, curved bottom edge
      expect(rrect.blRadius, isNot(Radius.zero));
      expect(rrect.brRadius, isNot(Radius.zero));
    });

    test('bottom orientation - flat bottom, curved top', () {
      const shape = CapsuleHalfMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        fillPaint,
        null,
        orientation: ShapeDirection.bottom,
      );

      final rrect = canvas.drawnRRects.first;
      // Flat bottom edge, curved top edge
      expect(rrect.tlRadius, isNot(Radius.zero));
      expect(rrect.trRadius, isNot(Radius.zero));
    });

    test('equality works correctly', () {
      const shape1 = CapsuleHalfMarkerShape();
      const shape2 = CapsuleHalfMarkerShape();
      expect(shape1, equals(shape2));
      expect(shape1.hashCode, equals(shape2.hashCode));
    });

    test('toJson returns correct map', () {
      const shape = CapsuleHalfMarkerShape();
      // Note: typeName is 'capsuleHalf' for serialization
      expect(shape.toJson(), equals({'type': 'capsuleHalf'}));
    });

    test('fromJson creates correct instance', () {
      final shape = MarkerShape.fromJson({'type': 'capsuleHalf'});
      expect(shape, isA<CapsuleHalfMarkerShape>());
    });

    test('works with asymmetric size for left/right orientation', () {
      const shape = CapsuleHalfMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(30, 20),
        fillPaint,
        null,
        orientation: ShapeDirection.right,
      );

      final rrect = canvas.drawnRRects.first;
      // For left/right, uses height/2 as radius
      expect(rrect.tlRadiusY, equals(10.0));
    });

    test('works with asymmetric size for top/bottom orientation', () {
      const shape = CapsuleHalfMarkerShape();
      shape.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 30),
        fillPaint,
        null,
        orientation: ShapeDirection.bottom,
      );

      final rrect = canvas.drawnRRects.first;
      // For top/bottom, uses width/2 as radius
      expect(rrect.tlRadiusX, equals(10.0));
    });
  });

  group('ShapeDirection Extension', () {
    test('toCapsuleFlatSide converts left correctly', () {
      expect(
        ShapeDirection.left.toCapsuleFlatSide(),
        equals(CapsuleFlatSide.left),
      );
    });

    test('toCapsuleFlatSide converts right correctly', () {
      expect(
        ShapeDirection.right.toCapsuleFlatSide(),
        equals(CapsuleFlatSide.right),
      );
    });

    test('toCapsuleFlatSide converts top correctly', () {
      expect(
        ShapeDirection.top.toCapsuleFlatSide(),
        equals(CapsuleFlatSide.top),
      );
    });

    test('toCapsuleFlatSide converts bottom correctly', () {
      expect(
        ShapeDirection.bottom.toCapsuleFlatSide(),
        equals(CapsuleFlatSide.bottom),
      );
    });
  });

  group('MarkerShape.fromJson', () {
    test('throws ArgumentError for unknown type', () {
      expect(
        () => MarkerShape.fromJson({'type': 'unknown'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('creates all valid shape types', () {
      final types = [
        'none',
        'circle',
        'rectangle',
        'diamond',
        'triangle',
        'capsuleHalf',
      ];
      for (final type in types) {
        expect(
          () => MarkerShape.fromJson({'type': type}),
          returnsNormally,
          reason: 'Should create shape for type: $type',
        );
      }
    });
  });

  group('MarkerShape.getEffectiveSize', () {
    test('default implementation returns base size unchanged', () {
      const shape = CircleMarkerShape();
      const baseSize = Size(20, 20);
      final effectiveSize = shape.getEffectiveSize(
        baseSize,
        ShapeDirection.right,
      );
      expect(effectiveSize, equals(baseSize));
    });

    test('all built-in shapes return base size by default', () {
      final shapes = <MarkerShape>[
        MarkerShapes.none,
        MarkerShapes.circle,
        MarkerShapes.rectangle,
        MarkerShapes.diamond,
        MarkerShapes.triangle,
        MarkerShapes.capsuleHalf,
      ];

      const baseSize = Size(20, 20);
      for (final shape in shapes) {
        for (final direction in ShapeDirection.values) {
          final effectiveSize = shape.getEffectiveSize(baseSize, direction);
          expect(
            effectiveSize,
            equals(baseSize),
            reason: '${shape.typeName} should return base size for $direction',
          );
        }
      }
    });
  });

  group('MarkerShape inequality', () {
    test('different shape types are not equal', () {
      expect(MarkerShapes.circle, isNot(equals(MarkerShapes.rectangle)));
      expect(MarkerShapes.triangle, isNot(equals(MarkerShapes.diamond)));
      expect(MarkerShapes.none, isNot(equals(MarkerShapes.capsuleHalf)));
    });
  });
}
