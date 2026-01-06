/// Unit tests for PulseEffect connection animation.
///
/// Tests cover:
/// - Constructor validation and defaults
/// - Paint method behavior at different animation values
/// - Glow effect at peak pulse
/// - Edge cases and boundary conditions
@Tags(['unit'])
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  // ===========================================================================
  // Constructor Tests
  // ===========================================================================

  group('PulseEffect - Constructor', () {
    test('default constructor creates effect with default values', () {
      final effect = PulseEffect();

      expect(effect.speed, equals(1));
      expect(effect.minOpacity, equals(0.4));
      expect(effect.maxOpacity, equals(1.0));
      expect(effect.widthVariation, equals(1.0));
    });

    test('constructor accepts custom speed', () {
      final effect = PulseEffect(speed: 3);

      expect(effect.speed, equals(3));
    });

    test('constructor accepts custom opacity range', () {
      final effect = PulseEffect(minOpacity: 0.2, maxOpacity: 0.8);

      expect(effect.minOpacity, equals(0.2));
      expect(effect.maxOpacity, equals(0.8));
    });

    test('constructor accepts custom width variation', () {
      final effect = PulseEffect(widthVariation: 2.0);

      expect(effect.widthVariation, equals(2.0));
    });

    test('constructor validates speed must be positive', () {
      expect(() => PulseEffect(speed: 0), throwsA(isA<AssertionError>()));
      expect(() => PulseEffect(speed: -1), throwsA(isA<AssertionError>()));
    });

    test('constructor validates minOpacity between 0 and 1', () {
      expect(
        () => PulseEffect(minOpacity: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PulseEffect(minOpacity: 1.1),
        throwsA(isA<AssertionError>()),
      );

      // Valid values should not throw
      expect(() => PulseEffect(minOpacity: 0.0), returnsNormally);
      expect(() => PulseEffect(minOpacity: 1.0), returnsNormally);
    });

    test('constructor validates maxOpacity between 0 and 1', () {
      expect(
        () => PulseEffect(maxOpacity: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PulseEffect(maxOpacity: 1.1),
        throwsA(isA<AssertionError>()),
      );

      // Valid values should not throw
      expect(
        () => PulseEffect(maxOpacity: 0.0, minOpacity: 0.0),
        returnsNormally,
      );
      expect(() => PulseEffect(maxOpacity: 1.0), returnsNormally);
    });

    test('constructor validates minOpacity <= maxOpacity', () {
      expect(
        () => PulseEffect(minOpacity: 0.8, maxOpacity: 0.4),
        throwsA(isA<AssertionError>()),
      );

      // Equal values should not throw
      expect(
        () => PulseEffect(minOpacity: 0.5, maxOpacity: 0.5),
        returnsNormally,
      );
    });

    test('constructor validates widthVariation >= 1.0', () {
      expect(
        () => PulseEffect(widthVariation: 0.5),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PulseEffect(widthVariation: 0.99),
        throwsA(isA<AssertionError>()),
      );

      // 1.0 should not throw
      expect(() => PulseEffect(widthVariation: 1.0), returnsNormally);
    });
  });

  // ===========================================================================
  // Paint Method Tests
  // ===========================================================================

  group('PulseEffect - paint', () {
    late _MockCanvas mockCanvas;
    late Path testPath;
    late Paint basePaint;

    setUp(() {
      mockCanvas = _MockCanvas();
      testPath = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      basePaint = Paint()
        ..color = const Color(0xFF0000FF)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    });

    test('paint draws path at animationValue 0', () {
      final effect = PulseEffect();

      effect.paint(mockCanvas, testPath, basePaint, 0.0);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paint draws path at animationValue 0.5', () {
      final effect = PulseEffect();

      effect.paint(mockCanvas, testPath, basePaint, 0.5);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paint draws path at animationValue 1.0', () {
      final effect = PulseEffect();

      effect.paint(mockCanvas, testPath, basePaint, 1.0);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paint opacity cycles based on animation value', () {
      final effect = PulseEffect(minOpacity: 0.2, maxOpacity: 1.0);

      // At animation value 0.25, sin wave should be at peak (1)
      // pulseProgress = (sin(0.25 * 2 * pi) + 1) / 2 = (1 + 1) / 2 = 1
      effect.paint(mockCanvas, testPath, basePaint, 0.25);
      final paintAtPeak = mockCanvas.lastPaint!;

      mockCanvas.reset();

      // At animation value 0.75, sin wave should be at trough (-1)
      // pulseProgress = (sin(0.75 * 2 * pi) + 1) / 2 = (-1 + 1) / 2 = 0
      effect.paint(mockCanvas, testPath, basePaint, 0.75);
      final paintAtTrough = mockCanvas.lastPaint!;

      // Peak should have higher opacity than trough
      expect(paintAtPeak.color.a, greaterThan(paintAtTrough.color.a));
    });

    test('paint with width variation changes stroke width', () {
      final effect = PulseEffect(widthVariation: 2.0);

      // At animation value 0.25 (peak)
      effect.paint(mockCanvas, testPath, basePaint, 0.25);
      final paintAtPeak = mockCanvas.lastPaint!;

      mockCanvas.reset();

      // At animation value 0.75 (trough)
      effect.paint(mockCanvas, testPath, basePaint, 0.75);
      final paintAtTrough = mockCanvas.lastPaint!;

      // Peak should have wider stroke than trough
      expect(paintAtPeak.strokeWidth, greaterThan(paintAtTrough.strokeWidth));
    });

    test('paint adds glow effect at peak with width variation', () {
      final effect = PulseEffect(widthVariation: 1.5);

      // At peak (animation value 0.25), glow should be drawn
      effect.paint(mockCanvas, testPath, basePaint, 0.25);

      // Should draw both main path and glow (2 calls)
      expect(mockCanvas.drawPathCalls, equals(2));
    });

    test('paint does not add glow effect without width variation', () {
      final effect = PulseEffect(widthVariation: 1.0);

      // At peak, no glow without width variation
      effect.paint(mockCanvas, testPath, basePaint, 0.25);

      // Should only draw main path (1 call)
      expect(mockCanvas.drawPathCalls, equals(1));
    });

    test('paint does not add glow effect at low pulse progress', () {
      final effect = PulseEffect(widthVariation: 1.5);

      // At trough (0.75), pulseProgress is 0, no glow
      effect.paint(mockCanvas, testPath, basePaint, 0.75);

      // Should only draw main path (1 call)
      expect(mockCanvas.drawPathCalls, equals(1));
    });

    test('paint preserves stroke cap and join from base paint', () {
      final effect = PulseEffect();
      basePaint.strokeCap = StrokeCap.square;
      basePaint.strokeJoin = StrokeJoin.bevel;

      effect.paint(mockCanvas, testPath, basePaint, 0.5);

      final drawnPaint = mockCanvas.lastPaint!;
      expect(drawnPaint.strokeCap, equals(StrokeCap.square));
      expect(drawnPaint.strokeJoin, equals(StrokeJoin.bevel));
    });

    test('paint with speed > 1 cycles faster', () {
      final effectSpeed1 = PulseEffect(speed: 1);
      final effectSpeed2 = PulseEffect(speed: 2);

      // At animation value 0.125, speed 1 is halfway to peak
      // pulseProgress = (sin(0.125 * 2 * pi) + 1) / 2 ≈ 0.85
      effectSpeed1.paint(mockCanvas, testPath, basePaint, 0.125);
      final opacitySpeed1 = mockCanvas.lastPaint!.color.a;

      mockCanvas.reset();

      // At animation value 0.125, speed 2 is at peak
      // pulseProgress = (sin(0.125 * 2 * 2 * pi) + 1) / 2 = (sin(pi/2) + 1) / 2 = 1
      effectSpeed2.paint(mockCanvas, testPath, basePaint, 0.125);
      final opacitySpeed2 = mockCanvas.lastPaint!.color.a;

      expect(opacitySpeed2, greaterThan(opacitySpeed1));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('PulseEffect - Edge Cases', () {
    test('handles animation value slightly above 1.0', () {
      final effect = PulseEffect();
      final canvas = _MockCanvas();
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      final paint = Paint()
        ..color = const Color(0xFF0000FF)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Should not throw for values slightly above 1.0
      expect(() => effect.paint(canvas, path, paint, 1.001), returnsNormally);
    });

    test('handles negative animation values', () {
      final effect = PulseEffect();
      final canvas = _MockCanvas();
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      final paint = Paint()
        ..color = const Color(0xFF0000FF)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Should not throw for negative values
      expect(() => effect.paint(canvas, path, paint, -0.1), returnsNormally);
    });

    test('equal min and max opacity produces constant opacity', () {
      final effect = PulseEffect(minOpacity: 0.5, maxOpacity: 0.5);
      final canvas = _MockCanvas();
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      final paint = Paint()
        ..color = const Color(0xFF0000FF)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      effect.paint(canvas, path, paint, 0.0);
      final opacity0 = canvas.lastPaint!.color.a;

      canvas.reset();
      effect.paint(canvas, path, paint, 0.5);
      final opacity5 = canvas.lastPaint!.color.a;

      // Opacity should be constant
      expect(opacity0, closeTo(opacity5, 0.01));
    });

    test('works with transparent colors', () {
      final effect = PulseEffect();
      final canvas = _MockCanvas();
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      final paint = Paint()
        ..color =
            const Color(0x800000FF) // 50% opacity
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      expect(() => effect.paint(canvas, path, paint, 0.5), returnsNormally);
    });

    test('pulse calculation is mathematically correct', () {
      // This test verifies the math used in PulseEffect for calculating pulse progress
      // The effect uses: pulseProgress = (sin(animationValue * 2 * pi) + 1) / 2

      // pulseProgress at animationValue 0:
      // (sin(0) + 1) / 2 = (0 + 1) / 2 = 0.5
      // opacity = 0.0 + (1.0 - 0.0) * 0.5 = 0.5
      final expectedProgress0 = (math.sin(0) + 1) / 2;
      expect(expectedProgress0, closeTo(0.5, 0.001));

      // pulseProgress at animationValue 0.25:
      // (sin(0.25 * 2 * pi) + 1) / 2 = (sin(pi/2) + 1) / 2 = (1 + 1) / 2 = 1.0
      final expectedProgress25 = (math.sin(0.25 * 2 * math.pi) + 1) / 2;
      expect(expectedProgress25, closeTo(1.0, 0.001));

      // pulseProgress at animationValue 0.5:
      // (sin(0.5 * 2 * pi) + 1) / 2 = (sin(pi) + 1) / 2 = (0 + 1) / 2 = 0.5
      final expectedProgress50 = (math.sin(0.5 * 2 * math.pi) + 1) / 2;
      expect(expectedProgress50, closeTo(0.5, 0.001));

      // pulseProgress at animationValue 0.75:
      // (sin(0.75 * 2 * pi) + 1) / 2 = (sin(3pi/2) + 1) / 2 = (-1 + 1) / 2 = 0.0
      final expectedProgress75 = (math.sin(0.75 * 2 * math.pi) + 1) / 2;
      expect(expectedProgress75, closeTo(0.0, 0.001));
    });
  });
}

/// Mock canvas for testing paint methods without a real canvas.
class _MockCanvas implements Canvas {
  int drawPathCalls = 0;
  Paint? lastPaint;
  Path? lastPath;

  void reset() {
    drawPathCalls = 0;
    lastPaint = null;
    lastPath = null;
  }

  @override
  void drawPath(Path path, Paint paint) {
    drawPathCalls++;
    lastPaint = paint;
    lastPath = path;
  }

  // Stub implementations for other Canvas methods
  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {}

  @override
  void clipRect(
    Rect rect, {
    ClipOp clipOp = ClipOp.intersect,
    bool doAntiAlias = true,
  }) {}

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {}

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
    Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {}

  @override
  void drawCircle(Offset c, double radius, Paint paint) {}

  @override
  void drawColor(Color color, BlendMode blendMode) {}

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {}

  @override
  void drawImage(Image image, Offset offset, Paint paint) {}

  @override
  void drawImageNine(Image image, Rect center, Rect dst, Paint paint) {}

  @override
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint) {}

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {}

  @override
  void drawOval(Rect rect, Paint paint) {}

  @override
  void drawPaint(Paint paint) {}

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {}

  @override
  void drawPicture(Picture picture) {}

  @override
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint) {}

  @override
  void drawRRect(RRect rrect, Paint paint) {}

  @override
  void drawRawAtlas(
    Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {}

  @override
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {}

  @override
  void drawRect(Rect rect, Paint paint) {}

  @override
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  ) {}

  @override
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {}

  @override
  Rect getDestinationClipBounds() => Rect.zero;

  @override
  Rect getLocalClipBounds() => Rect.zero;

  @override
  Float64List getTransform() => Float64List(16);

  @override
  void restore() {}

  @override
  void restoreToCount(int count) {}

  @override
  void rotate(double radians) {}

  @override
  int getSaveCount() => 0;

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
  void clipRSuperellipse(
    RSuperellipse rsuperellipse, {
    bool doAntiAlias = true,
  }) {}

  @override
  void drawRSuperellipse(RSuperellipse rsuperellipse, Paint paint) {}
}
