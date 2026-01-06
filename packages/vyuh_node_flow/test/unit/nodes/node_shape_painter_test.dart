/// Comprehensive unit tests for NodeShapePainter.
///
/// Tests cover:
/// - Different node shapes (diamond, circle, hexagon)
/// - Paint methods with different styles
/// - Shadow painting
/// - Edge cases with varying sizes
/// - shouldRepaint behavior
/// - Hit testing
@Tags(['unit'])
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

// Import internal NodeShapePainter for testing
import 'package:vyuh_node_flow/src/nodes/node_shape_painter.dart';

import '../../helpers/test_factories.dart';

// =============================================================================
// Mock Canvas for Testing
// =============================================================================

/// A mock canvas that records drawing operations for testing.
class RecordingCanvas implements Canvas {
  final List<String> operations = [];
  final List<Path> drawnPaths = [];
  final List<Paint> drawnPaints = [];
  final List<Offset> pathOffsets = [];

  void clear() {
    operations.clear();
    drawnPaths.clear();
    drawnPaints.clear();
    pathOffsets.clear();
  }

  @override
  void drawPath(Path path, Paint paint) {
    operations.add('drawPath');
    drawnPaths.add(path);
    drawnPaints.add(paint);
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    operations.add('drawCircle');
    drawnPaints.add(paint);
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    operations.add('drawRect');
    drawnPaints.add(paint);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    operations.add('drawRRect');
    drawnPaints.add(paint);
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

// =============================================================================
// Test NodeShape Implementations
// =============================================================================

/// A simple rectangle shape for testing.
class TestRectangleShape extends NodeShape {
  const TestRectangleShape({
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  @override
  Path buildPath(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  List<PortAnchor> getPortAnchors(Size size) => [];
}

/// A rounded rectangle shape for testing.
class TestRoundedRectangleShape extends NodeShape {
  const TestRoundedRectangleShape({
    this.borderRadius = 8.0,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  final double borderRadius;

  @override
  Path buildPath(Size size) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ),
    );
  }

  @override
  List<PortAnchor> getPortAnchors(Size size) => [];
}

/// An ellipse shape for testing.
class TestEllipseShape extends NodeShape {
  const TestEllipseShape({
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  @override
  Path buildPath(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  List<PortAnchor> getPortAnchors(Size size) => [];

  @override
  bool containsPoint(Offset point, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusX = size.width / 2;
    final radiusY = size.height / 2;

    final dx = (point.dx - centerX) / radiusX;
    final dy = (point.dy - centerY) / radiusY;
    return (dx * dx + dy * dy) <= 1.0;
  }
}

void main() {
  late RecordingCanvas canvas;

  setUp(() {
    resetTestCounters();
    canvas = RecordingCanvas();
  });

  // ===========================================================================
  // Construction Tests
  // ===========================================================================
  group('NodeShapePainter Construction', () {
    test('creates with required parameters', () {
      const shape = DiamondShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      expect(painter.shape, equals(shape));
      expect(painter.backgroundColor, equals(Colors.blue));
      expect(painter.borderColor, equals(Colors.black));
      expect(painter.borderWidth, equals(2.0));
      expect(painter.size, equals(const Size(100, 100)));
    });

    test('creates with default inset', () {
      const shape = DiamondShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      expect(painter.inset, equals(EdgeInsets.zero));
    });

    test('creates with custom inset', () {
      const shape = DiamondShape();
      const customInset = EdgeInsets.all(10.0);
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        inset: customInset,
        size: const Size(100, 100),
      );

      expect(painter.inset, equals(customInset));
    });

    test('creates with null shadows by default', () {
      const shape = DiamondShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      expect(painter.shadows, isNull);
    });

    test('creates with custom shadows', () {
      const shape = DiamondShape();
      final shadows = [
        const BoxShadow(
          color: Colors.black26,
          blurRadius: 4.0,
          offset: Offset(2, 2),
        ),
      ];
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: shadows,
        size: const Size(100, 100),
      );

      expect(painter.shadows, equals(shadows));
    });
  });

  // ===========================================================================
  // Paint Method Tests - Different Shapes
  // ===========================================================================
  group('NodeShapePainter.paint - Different Shapes', () {
    group('Rectangle Shape', () {
      test('paints rectangle shape with fill and border', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.blue,
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        // Should draw fill path and border path
        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });

      test('rectangle path has correct bounds', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.blue,
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(100, 80),
        );

        painter.paint(canvas, const Size(100, 80));

        final fillPath = canvas.drawnPaths.first;
        final bounds = fillPath.getBounds();
        expect(bounds.width, closeTo(100, 0.1));
        expect(bounds.height, closeTo(80, 0.1));
      });
    });

    group('Rounded Rectangle Shape', () {
      test('paints rounded rectangle shape', () {
        const shape = TestRoundedRectangleShape(borderRadius: 12.0);
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.green,
          borderColor: Colors.green.shade900,
          borderWidth: 3.0,
          size: const Size(120, 100),
        );

        painter.paint(canvas, const Size(120, 100));

        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });

      test('rounded rectangle with different border radius', () {
        const smallRadius = TestRoundedRectangleShape(borderRadius: 4.0);
        const largeRadius = TestRoundedRectangleShape(borderRadius: 20.0);

        final smallPainter = NodeShapePainter(
          shape: smallRadius,
          backgroundColor: Colors.blue,
          borderColor: Colors.black,
          borderWidth: 1.0,
          size: const Size(100, 100),
        );

        final largePainter = NodeShapePainter(
          shape: largeRadius,
          backgroundColor: Colors.blue,
          borderColor: Colors.black,
          borderWidth: 1.0,
          size: const Size(100, 100),
        );

        smallPainter.paint(canvas, const Size(100, 100));
        canvas.clear();
        largePainter.paint(canvas, const Size(100, 100));

        // Both should draw 2 paths (fill and border)
        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });
    });

    group('Diamond Shape', () {
      test('paints diamond shape with fill and border', () {
        const shape = DiamondShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.orange,
          borderColor: Colors.deepOrange,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });

      test('diamond path contains center point', () {
        const shape = DiamondShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.orange,
          borderColor: Colors.deepOrange,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final fillPath = canvas.drawnPaths.first;
        expect(fillPath.contains(const Offset(50, 50)), isTrue);
      });

      test('diamond path excludes corner points', () {
        const shape = DiamondShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.orange,
          borderColor: Colors.deepOrange,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final fillPath = canvas.drawnPaths.first;
        // Corners of bounding box should be outside diamond
        expect(fillPath.contains(const Offset(0, 0)), isFalse);
        expect(fillPath.contains(const Offset(100, 0)), isFalse);
        expect(fillPath.contains(const Offset(100, 100)), isFalse);
        expect(fillPath.contains(const Offset(0, 100)), isFalse);
      });
    });

    group('Ellipse/Circle Shape', () {
      test('paints ellipse shape with fill and border', () {
        const shape = TestEllipseShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.purple,
          borderColor: Colors.deepPurple,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });

      test('ellipse path has correct bounds for circular size', () {
        const shape = TestEllipseShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.purple,
          borderColor: Colors.deepPurple,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final fillPath = canvas.drawnPaths.first;
        final bounds = fillPath.getBounds();
        expect(bounds.width, closeTo(100, 0.1));
        expect(bounds.height, closeTo(100, 0.1));
      });

      test('ellipse path has correct bounds for oval size', () {
        const shape = TestEllipseShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.purple,
          borderColor: Colors.deepPurple,
          borderWidth: 2.0,
          size: const Size(200, 100),
        );

        painter.paint(canvas, const Size(200, 100));

        final fillPath = canvas.drawnPaths.first;
        final bounds = fillPath.getBounds();
        expect(bounds.width, closeTo(200, 0.1));
        expect(bounds.height, closeTo(100, 0.1));
      });
    });

    group('CircleShape (built-in)', () {
      test('paints circle shape', () {
        const shape = CircleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.teal,
          borderColor: Colors.tealAccent,
          borderWidth: 2.0,
          size: const Size(80, 80),
        );

        painter.paint(canvas, const Size(80, 80));

        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });
    });

    group('HexagonShape (built-in)', () {
      test('paints horizontal hexagon shape', () {
        const shape = HexagonShape(orientation: HexagonOrientation.horizontal);
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.amber,
          borderColor: Colors.orange,
          borderWidth: 2.0,
          size: const Size(100, 60),
        );

        painter.paint(canvas, const Size(100, 60));

        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });

      test('paints vertical hexagon shape', () {
        const shape = HexagonShape(orientation: HexagonOrientation.vertical);
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.cyan,
          borderColor: Colors.cyanAccent,
          borderWidth: 2.0,
          size: const Size(60, 100),
        );

        painter.paint(canvas, const Size(60, 100));

        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });
    });
  });

  // ===========================================================================
  // Paint Method Tests - Different Styles
  // ===========================================================================
  group('NodeShapePainter.paint - Different Styles', () {
    group('Fill Paint', () {
      test('uses backgroundColor for fill paint', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.red,
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final fillPaint = canvas.drawnPaints.first;
        expect(fillPaint.color.value, equals(Colors.red.value));
        expect(fillPaint.style, equals(PaintingStyle.fill));
      });

      test('uses shape fillColor when provided', () {
        const shape = TestRectangleShape(fillColor: Colors.green);
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.red, // Should be overridden
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final fillPaint = canvas.drawnPaints.first;
        expect(fillPaint.color.value, equals(Colors.green.value));
      });
    });

    group('Border Paint', () {
      test('uses borderColor for stroke paint', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.blue,
          borderWidth: 3.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        // Second paint is border
        final borderPaint = canvas.drawnPaints[1];
        expect(borderPaint.color.value, equals(Colors.blue.value));
        expect(borderPaint.style, equals(PaintingStyle.stroke));
        expect(borderPaint.strokeWidth, equals(3.0));
      });

      test('uses shape strokeColor when provided', () {
        const shape = TestRectangleShape(strokeColor: Colors.purple);
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.blue, // Should be overridden
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final borderPaint = canvas.drawnPaints[1];
        expect(borderPaint.color.value, equals(Colors.purple.value));
      });

      test('uses shape strokeWidth when provided', () {
        const shape = TestRectangleShape(strokeWidth: 5.0);
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 2.0, // Should be overridden
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final borderPaint = canvas.drawnPaints[1];
        expect(borderPaint.strokeWidth, equals(5.0));
      });

      test('skips border when borderWidth is 0', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 0.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        // Should only draw fill, no border
        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(1),
        );
      });

      test('border paint has round stroke cap and join', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final borderPaint = canvas.drawnPaints[1];
        expect(borderPaint.strokeCap, equals(StrokeCap.round));
        expect(borderPaint.strokeJoin, equals(StrokeJoin.round));
      });
    });

    group('Transparency', () {
      test('supports semi-transparent backgroundColor', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.blue.withValues(alpha: 0.5),
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final fillPaint = canvas.drawnPaints.first;
        expect(fillPaint.color.a, closeTo(0.5, 0.01));
      });

      test('supports semi-transparent borderColor', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black.withValues(alpha: 0.3),
          borderWidth: 2.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        final borderPaint = canvas.drawnPaints[1];
        expect(borderPaint.color.a, closeTo(0.3, 0.01));
      });
    });
  });

  // ===========================================================================
  // Shadow Painting Tests
  // ===========================================================================
  group('NodeShapePainter.paint - Shadows', () {
    test('paints single shadow', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            offset: Offset(2, 2),
          ),
        ],
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      // Shadow + fill + border = 3 drawPath calls
      expect(
        canvas.operations.where((op) => op == 'drawPath').length,
        equals(3),
      );
    });

    test('paints multiple shadows', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: [
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 2.0,
            offset: Offset(1, 1),
          ),
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 8.0,
            offset: Offset(4, 4),
          ),
        ],
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      // 2 shadows + fill + border = 4 drawPath calls
      expect(
        canvas.operations.where((op) => op == 'drawPath').length,
        equals(4),
      );
    });

    test('shadow paint has correct color', () {
      const shape = TestRectangleShape();
      const shadowColor = Colors.red;
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: [
          const BoxShadow(
            color: shadowColor,
            blurRadius: 4.0,
            offset: Offset(2, 2),
          ),
        ],
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      // First paint is shadow
      final shadowPaint = canvas.drawnPaints.first;
      expect(shadowPaint.color.value, equals(shadowColor.value));
    });

    test('shadow paint has mask filter for blur', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 8.0,
            offset: Offset(2, 2),
          ),
        ],
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      final shadowPaint = canvas.drawnPaints.first;
      expect(shadowPaint.maskFilter, isNotNull);
    });

    test('shadow path is offset correctly', () {
      const shape = TestRectangleShape();
      const shadowOffset = Offset(10, 10);
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            offset: shadowOffset,
          ),
        ],
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      final shadowPath = canvas.drawnPaths.first;
      final fillPath = canvas.drawnPaths[1];

      final shadowBounds = shadowPath.getBounds();
      final fillBounds = fillPath.getBounds();

      // Shadow should be offset from fill
      expect(
        shadowBounds.left,
        closeTo(fillBounds.left + shadowOffset.dx, 0.1),
      );
      expect(shadowBounds.top, closeTo(fillBounds.top + shadowOffset.dy, 0.1));
    });

    test('empty shadows list does not draw shadows', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: const [], // Empty list
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      // Only fill + border = 2 drawPath calls
      expect(
        canvas.operations.where((op) => op == 'drawPath').length,
        equals(2),
      );
    });

    test('null shadows does not draw shadows', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: null,
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      // Only fill + border = 2 drawPath calls
      expect(
        canvas.operations.where((op) => op == 'drawPath').length,
        equals(2),
      );
    });
  });

  // ===========================================================================
  // Inset Tests
  // ===========================================================================
  group('NodeShapePainter.paint - Insets', () {
    test('applies uniform inset', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        inset: const EdgeInsets.all(10.0),
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      final fillPath = canvas.drawnPaths.first;
      final bounds = fillPath.getBounds();

      // Size should be reduced by inset (100 - 20 = 80)
      expect(bounds.width, closeTo(80, 0.1));
      expect(bounds.height, closeTo(80, 0.1));
      // Position should be offset by inset
      expect(bounds.left, closeTo(10, 0.1));
      expect(bounds.top, closeTo(10, 0.1));
    });

    test('applies asymmetric inset', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        inset: const EdgeInsets.only(left: 20, right: 10, top: 5, bottom: 15),
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      final fillPath = canvas.drawnPaths.first;
      final bounds = fillPath.getBounds();

      // Width: 100 - 20 - 10 = 70
      // Height: 100 - 5 - 15 = 80
      expect(bounds.width, closeTo(70, 0.1));
      expect(bounds.height, closeTo(80, 0.1));
      expect(bounds.left, closeTo(20, 0.1));
      expect(bounds.top, closeTo(5, 0.1));
    });

    test('zero inset does not affect size', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        inset: EdgeInsets.zero,
        size: const Size(100, 100),
      );

      painter.paint(canvas, const Size(100, 100));

      final fillPath = canvas.drawnPaths.first;
      final bounds = fillPath.getBounds();

      expect(bounds.width, closeTo(100, 0.1));
      expect(bounds.height, closeTo(100, 0.1));
      expect(bounds.left, closeTo(0, 0.1));
      expect(bounds.top, closeTo(0, 0.1));
    });
  });

  // ===========================================================================
  // Edge Cases with Varying Sizes
  // ===========================================================================
  group('NodeShapePainter.paint - Edge Cases', () {
    group('Small Sizes', () {
      test('paints with very small size', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 1.0,
          size: const Size(10, 10),
        );

        painter.paint(canvas, const Size(10, 10));

        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });

      test('paints with minimum 1x1 size', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 0.5,
          size: const Size(1, 1),
        );

        painter.paint(canvas, const Size(1, 1));

        expect(canvas.operations, isNotEmpty);
      });

      test('handles border wider than shape', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 20.0, // Border wider than shape
          size: const Size(10, 10),
        );

        // Should not crash
        painter.paint(canvas, const Size(10, 10));
        expect(canvas.operations, isNotEmpty);
      });
    });

    group('Large Sizes', () {
      test('paints with large size', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(1000, 1000),
        );

        painter.paint(canvas, const Size(1000, 1000));

        final fillPath = canvas.drawnPaths.first;
        final bounds = fillPath.getBounds();
        expect(bounds.width, closeTo(1000, 0.1));
        expect(bounds.height, closeTo(1000, 0.1));
      });

      test('paints with very large size', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(10000, 10000),
        );

        painter.paint(canvas, const Size(10000, 10000));

        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(2),
        );
      });
    });

    group('Asymmetric Sizes', () {
      test('paints wide rectangle', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(500, 50),
        );

        painter.paint(canvas, const Size(500, 50));

        final fillPath = canvas.drawnPaths.first;
        final bounds = fillPath.getBounds();
        expect(bounds.width, closeTo(500, 0.1));
        expect(bounds.height, closeTo(50, 0.1));
      });

      test('paints tall rectangle', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 2.0,
          size: const Size(50, 500),
        );

        painter.paint(canvas, const Size(50, 500));

        final fillPath = canvas.drawnPaths.first;
        final bounds = fillPath.getBounds();
        expect(bounds.width, closeTo(50, 0.1));
        expect(bounds.height, closeTo(500, 0.1));
      });

      test('wide diamond shape', () {
        const shape = DiamondShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.orange,
          borderColor: Colors.deepOrange,
          borderWidth: 2.0,
          size: const Size(200, 50),
        );

        painter.paint(canvas, const Size(200, 50));

        final fillPath = canvas.drawnPaths.first;
        final bounds = fillPath.getBounds();
        expect(bounds.width, closeTo(200, 0.1));
        expect(bounds.height, closeTo(50, 0.1));
      });

      test('tall diamond shape', () {
        const shape = DiamondShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.orange,
          borderColor: Colors.deepOrange,
          borderWidth: 2.0,
          size: const Size(50, 200),
        );

        painter.paint(canvas, const Size(50, 200));

        final fillPath = canvas.drawnPaths.first;
        final bounds = fillPath.getBounds();
        expect(bounds.width, closeTo(50, 0.1));
        expect(bounds.height, closeTo(200, 0.1));
      });
    });

    group('Zero Values', () {
      test('handles zero border width', () {
        const shape = TestRectangleShape();
        final painter = NodeShapePainter(
          shape: shape,
          backgroundColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 0.0,
          size: const Size(100, 100),
        );

        painter.paint(canvas, const Size(100, 100));

        // Only fill, no border
        expect(
          canvas.operations.where((op) => op == 'drawPath').length,
          equals(1),
        );
      });
    });
  });

  // ===========================================================================
  // shouldRepaint Tests
  // ===========================================================================
  group('NodeShapePainter.shouldRepaint', () {
    test('returns false when all properties are the same', () {
      const shape = DiamondShape();
      final painter1 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );
      final painter2 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('returns true when shape changes', () {
      final painter1 = NodeShapePainter(
        shape: const DiamondShape(),
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );
      final painter2 = NodeShapePainter(
        shape: const CircleShape(),
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('returns true when backgroundColor changes', () {
      const shape = DiamondShape();
      final painter1 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );
      final painter2 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.red,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('returns true when borderColor changes', () {
      const shape = DiamondShape();
      final painter1 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );
      final painter2 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.white,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('returns true when borderWidth changes', () {
      const shape = DiamondShape();
      final painter1 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );
      final painter2 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 4.0,
        size: const Size(100, 100),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('returns true when inset changes', () {
      const shape = DiamondShape();
      final painter1 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        inset: const EdgeInsets.all(10),
        size: const Size(100, 100),
      );
      final painter2 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        inset: const EdgeInsets.all(20),
        size: const Size(100, 100),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('returns true when shadows change', () {
      const shape = DiamondShape();
      final painter1 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: [const BoxShadow(color: Colors.black26, blurRadius: 4.0)],
        size: const Size(100, 100),
      );
      final painter2 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: [const BoxShadow(color: Colors.black54, blurRadius: 8.0)],
        size: const Size(100, 100),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('returns true when shadows added', () {
      const shape = DiamondShape();
      final painter1 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: null,
        size: const Size(100, 100),
      );
      final painter2 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        shadows: [const BoxShadow(color: Colors.black26, blurRadius: 4.0)],
        size: const Size(100, 100),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('returns true when size changes', () {
      const shape = DiamondShape();
      final painter1 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );
      final painter2 = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(200, 200),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });

  // ===========================================================================
  // Hit Testing Tests
  // ===========================================================================
  group('NodeShapePainter.hitTest', () {
    test('returns true for point inside rectangle shape', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      expect(painter.hitTest(const Offset(50, 50)), isTrue);
    });

    test('returns false for point outside rectangle shape', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      expect(painter.hitTest(const Offset(150, 150)), isFalse);
    });

    test('returns true for point inside diamond shape', () {
      const shape = DiamondShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.orange,
        borderColor: Colors.deepOrange,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      // Center should be inside
      expect(painter.hitTest(const Offset(50, 50)), isTrue);
    });

    test('returns false for corner point on diamond shape', () {
      const shape = DiamondShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.orange,
        borderColor: Colors.deepOrange,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      // Corners should be outside diamond
      expect(painter.hitTest(const Offset(0, 0)), isFalse);
      expect(painter.hitTest(const Offset(100, 0)), isFalse);
      expect(painter.hitTest(const Offset(0, 100)), isFalse);
      expect(painter.hitTest(const Offset(100, 100)), isFalse);
    });

    test('returns true for vertex points on diamond shape', () {
      const shape = DiamondShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.orange,
        borderColor: Colors.deepOrange,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      // Diamond vertices should be on the boundary (inside)
      expect(painter.hitTest(const Offset(50, 0)), isTrue); // Top
      expect(painter.hitTest(const Offset(100, 50)), isTrue); // Right
      expect(painter.hitTest(const Offset(50, 100)), isTrue); // Bottom
      expect(painter.hitTest(const Offset(0, 50)), isTrue); // Left
    });

    test('returns true for point inside ellipse shape', () {
      const shape = TestEllipseShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.purple,
        borderColor: Colors.deepPurple,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      // Center should be inside
      expect(painter.hitTest(const Offset(50, 50)), isTrue);
    });

    test('returns false for corner point on ellipse shape', () {
      const shape = TestEllipseShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.purple,
        borderColor: Colors.deepPurple,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      // Corners should be outside ellipse
      expect(painter.hitTest(const Offset(0, 0)), isFalse);
      expect(painter.hitTest(const Offset(100, 0)), isFalse);
      expect(painter.hitTest(const Offset(0, 100)), isFalse);
      expect(painter.hitTest(const Offset(100, 100)), isFalse);
    });

    test('hit test uses full size, not inset size', () {
      const shape = TestRectangleShape();
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.blue,
        borderColor: Colors.black,
        borderWidth: 2.0,
        inset: const EdgeInsets.all(20),
        size: const Size(100, 100),
      );

      // Point in the inset area but within full size should still hit
      expect(painter.hitTest(const Offset(10, 10)), isTrue);
      expect(painter.hitTest(const Offset(90, 90)), isTrue);
    });
  });

  // ===========================================================================
  // Integration Tests
  // ===========================================================================
  group('NodeShapePainter Integration', () {
    test('paints complex shape with all features', () {
      const shape = DiamondShape(
        fillColor: Colors.amber,
        strokeColor: Colors.orange,
        strokeWidth: 3.0,
      );
      final painter = NodeShapePainter(
        shape: shape,
        backgroundColor: Colors.white, // Will be overridden
        borderColor: Colors.black, // Will be overridden
        borderWidth: 1.0, // Will be overridden
        inset: const EdgeInsets.all(5),
        shadows: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            offset: Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(4, 4),
          ),
        ],
        size: const Size(150, 100),
      );

      painter.paint(canvas, const Size(150, 100));

      // 2 shadows + fill + border = 4 operations
      expect(
        canvas.operations.where((op) => op == 'drawPath').length,
        equals(4),
      );

      // Verify fill uses shape's color
      final fillPaint =
          canvas.drawnPaints[2]; // Third paint is fill (after 2 shadows)
      expect(fillPaint.color.value, equals(Colors.amber.value));

      // Verify border uses shape's color and width
      final borderPaint = canvas.drawnPaints[3];
      expect(borderPaint.color.value, equals(Colors.orange.value));
      expect(borderPaint.strokeWidth, equals(3.0));
    });

    test('different shapes produce different paths', () {
      final diamondPainter = NodeShapePainter(
        shape: const DiamondShape(),
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      final circlePainter = NodeShapePainter(
        shape: const CircleShape(),
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        borderWidth: 2.0,
        size: const Size(100, 100),
      );

      diamondPainter.paint(canvas, const Size(100, 100));
      final diamondPath = canvas.drawnPaths.first;

      canvas.clear();

      circlePainter.paint(canvas, const Size(100, 100));
      final circlePath = canvas.drawnPaths.first;

      // Diamond corners should be outside circle
      expect(diamondPath.contains(const Offset(0, 0)), isFalse);
      expect(circlePath.contains(const Offset(0, 0)), isFalse);

      // Circle should have point at (100, 50) on boundary
      // Diamond should have point at (100, 50) on boundary too
      // But circle has point at ~(85, 15) inside, diamond does not
      expect(circlePath.contains(const Offset(85, 50)), isTrue);
      expect(diamondPath.contains(const Offset(85, 50)), isTrue);

      // Check a point that's inside circle but outside diamond
      // At (75, 15): for 100x100 centered at (50,50)
      // Diamond: |25/50| + |35/50| = 0.5 + 0.7 = 1.2 > 1 (outside)
      // Circle: (25/50)^2 + (35/50)^2 = 0.25 + 0.49 = 0.74 < 1 (inside)
      expect(circlePath.contains(const Offset(75, 15)), isTrue);
      expect(diamondPath.contains(const Offset(75, 15)), isFalse);
    });
  });
}
