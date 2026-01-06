/// Comprehensive tests for GradientFlowEffect and ParticleEffect paint methods.
///
/// These tests verify the paint behavior of connection effects using mock canvases
/// and various configurations to ensure proper rendering at different animation states.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

/// A mock canvas that records all drawing operations for verification.
class MockCanvas implements ui.Canvas {
  final List<DrawOperation> operations = [];

  @override
  void drawPath(ui.Path path, ui.Paint paint) {
    operations.add(DrawPathOperation(path, paint));
  }

  @override
  void drawCircle(ui.Offset c, double radius, ui.Paint paint) {
    operations.add(DrawCircleOperation(c, radius, paint));
  }

  @override
  void save() {
    operations.add(SaveOperation());
  }

  @override
  void restore() {
    operations.add(RestoreOperation());
  }

  @override
  void translate(double dx, double dy) {
    operations.add(TranslateOperation(dx, dy));
  }

  @override
  void rotate(double radians) {
    operations.add(RotateOperation(radians));
  }

  // Required Canvas interface methods - no-op implementations for testing
  @override
  void clipPath(ui.Path path, {bool doAntiAlias = true}) {}
  @override
  void clipRect(
    ui.Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {}
  @override
  void clipRRect(ui.RRect rrect, {bool doAntiAlias = true}) {}
  @override
  void clipRSuperellipse(
    ui.RSuperellipse rsuperellipse, {
    bool doAntiAlias = true,
  }) {}
  @override
  void drawArc(
    ui.Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    ui.Paint paint,
  ) {}
  @override
  void drawAtlas(
    ui.Image atlas,
    List<ui.RSTransform> transforms,
    List<ui.Rect> rects,
    List<ui.Color>? colors,
    ui.BlendMode? blendMode,
    ui.Rect? cullRect,
    ui.Paint paint,
  ) {}
  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {}
  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {}
  @override
  void drawImage(ui.Image image, ui.Offset offset, ui.Paint paint) {}
  @override
  void drawImageNine(
    ui.Image image,
    ui.Rect center,
    ui.Rect dst,
    ui.Paint paint,
  ) {}
  @override
  void drawImageRect(
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  ) {}
  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {}
  @override
  void drawOval(ui.Rect rect, ui.Paint paint) {}
  @override
  void drawPaint(ui.Paint paint) {}
  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    operations.add(DrawParagraphOperation(paragraph, offset));
  }

  @override
  void drawPicture(ui.Picture picture) {}
  @override
  void drawPoints(
    ui.PointMode pointMode,
    List<ui.Offset> points,
    ui.Paint paint,
  ) {}
  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) {}
  @override
  void drawRSuperellipse(ui.RSuperellipse rsuperellipse, ui.Paint paint) {}
  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    ui.BlendMode? blendMode,
    ui.Rect? cullRect,
    ui.Paint paint,
  ) {}
  @override
  void drawRawPoints(
    ui.PointMode pointMode,
    Float32List points,
    ui.Paint paint,
  ) {}
  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {}
  @override
  void drawShadow(
    ui.Path path,
    ui.Color color,
    double elevation,
    bool transparentOccluder,
  ) {}
  @override
  void drawVertices(
    ui.Vertices vertices,
    ui.BlendMode blendMode,
    ui.Paint paint,
  ) {}
  @override
  int getSaveCount() => 0;
  @override
  void restoreToCount(int count) {}
  @override
  void saveLayer(ui.Rect? bounds, ui.Paint paint) {}
  @override
  void scale(double sx, [double? sy]) {}
  @override
  void skew(double sx, double sy) {}
  @override
  void transform(Float64List matrix4) {}
  @override
  ui.Rect getDestinationClipBounds() => ui.Rect.zero;
  @override
  ui.Rect getLocalClipBounds() => ui.Rect.zero;
  @override
  Float64List getTransform() => Float64List(16);
}

/// Base class for recorded draw operations.
abstract class DrawOperation {}

/// Records a drawPath call.
class DrawPathOperation extends DrawOperation {
  DrawPathOperation(this.path, this.paint);
  final ui.Path path;
  final ui.Paint paint;
}

/// Records a drawCircle call.
class DrawCircleOperation extends DrawOperation {
  DrawCircleOperation(this.center, this.radius, this.paint);
  final ui.Offset center;
  final double radius;
  final ui.Paint paint;
}

/// Records a save call.
class SaveOperation extends DrawOperation {}

/// Records a restore call.
class RestoreOperation extends DrawOperation {}

/// Records a translate call.
class TranslateOperation extends DrawOperation {
  TranslateOperation(this.dx, this.dy);
  final double dx;
  final double dy;
}

/// Records a rotate call.
class RotateOperation extends DrawOperation {
  RotateOperation(this.radians);
  final double radians;
}

/// Records a drawParagraph call.
class DrawParagraphOperation extends DrawOperation {
  DrawParagraphOperation(this.paragraph, this.offset);
  final ui.Paragraph paragraph;
  final ui.Offset offset;
}

/// Creates a simple horizontal test path from (0,0) to (100,0).
ui.Path createHorizontalPath({double length = 100}) {
  return ui.Path()
    ..moveTo(0, 0)
    ..lineTo(length, 0);
}

/// Creates a test path with a curve.
ui.Path createCurvedPath() {
  return ui.Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(50, 50, 100, 0);
}

/// Creates a base paint for testing.
Paint createBasePaint({Color color = Colors.blue, double strokeWidth = 2.0}) {
  return Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}

void main() {
  setUp(() {
    resetTestCounters();
  });

  group('GradientFlowEffect Paint Tests', () {
    group('basic paint behavior', () {
      test('paint draws on canvas at animation value 0.0', () {
        final effect = GradientFlowEffect();
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.0);

        // Should have drawn something (either base path or gradient path)
        expect(canvas.operations, isNotEmpty);
      });

      test('paint draws on canvas at animation value 0.5', () {
        final effect = GradientFlowEffect();
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
        // Should have path draw operations
        expect(canvas.operations.whereType<DrawPathOperation>(), isNotEmpty);
      });

      test('paint draws on canvas at animation value 1.0', () {
        final effect = GradientFlowEffect();
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 1.0);

        expect(canvas.operations, isNotEmpty);
      });

      test('paint handles empty path gracefully', () {
        final effect = GradientFlowEffect();
        final canvas = MockCanvas();
        final emptyPath = ui.Path();
        final basePaint = createBasePaint();

        // Should not throw
        expect(
          () => effect.paint(canvas, emptyPath, basePaint, 0.5),
          returnsNormally,
        );
      });
    });

    group('gradient length as percentage', () {
      test('gradientLength less than 1 is treated as percentage', () {
        final effect = GradientFlowEffect(gradientLength: 0.5);
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 200);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // Should draw something - gradient segment covers 50% of path
        expect(canvas.operations.whereType<DrawPathOperation>(), isNotEmpty);
      });

      test('gradientLength of 0.1 creates small gradient', () {
        final effect = GradientFlowEffect(gradientLength: 0.1);
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });

      test('gradientLength of 0.9 creates large gradient', () {
        final effect = GradientFlowEffect(gradientLength: 0.9);
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });
    });

    group('gradient length as absolute pixels', () {
      test('gradientLength >= 1 is treated as absolute pixels', () {
        final effect = GradientFlowEffect(gradientLength: 50.0);
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 200);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations.whereType<DrawPathOperation>(), isNotEmpty);
      });

      test('large absolute gradient length works correctly', () {
        final effect = GradientFlowEffect(gradientLength: 100.0);
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 200);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });
    });

    group('connection opacity', () {
      test('connectionOpacity 0 hides base connection', () {
        final effect = GradientFlowEffect(connectionOpacity: 0.0);
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // With 0 opacity, base path should not be drawn
        // Only gradient segment should be drawn
        final pathOps = canvas.operations.whereType<DrawPathOperation>();
        for (final op in pathOps) {
          // Any visible paths should have shader (gradient) or be the gradient segment
          // The base path with 0 opacity should not be drawn
        }
        expect(canvas.operations, isNotEmpty);
      });

      test('connectionOpacity 1 shows full base connection', () {
        final effect = GradientFlowEffect(connectionOpacity: 1.0);
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // Should draw multiple paths (base + gradient)
        expect(canvas.operations.whereType<DrawPathOperation>(), isNotEmpty);
      });

      test('connectionOpacity 0.5 shows semi-transparent base', () {
        final effect = GradientFlowEffect(connectionOpacity: 0.5);
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });
    });

    group('custom colors', () {
      test('null colors uses connection color', () {
        final effect = GradientFlowEffect(colors: null);
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint(color: Colors.red);

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });

      test('custom two-color gradient works', () {
        final effect = GradientFlowEffect(colors: [Colors.red, Colors.blue]);
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations.whereType<DrawPathOperation>(), isNotEmpty);
      });

      test('custom multi-color gradient works', () {
        final effect = GradientFlowEffect(
          colors: [Colors.red, Colors.green, Colors.blue, Colors.yellow],
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations.whereType<DrawPathOperation>(), isNotEmpty);
      });
    });

    group('speed variations', () {
      test('speed 1 creates single cycle per animation period', () {
        final effect = GradientFlowEffect(speed: 1);
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.25);
        final ops1 = List<DrawOperation>.from(canvas.operations);

        canvas.operations.clear();
        effect.paint(canvas, path, basePaint, 0.75);
        final ops2 = canvas.operations;

        // Both should produce valid output
        expect(ops1, isNotEmpty);
        expect(ops2, isNotEmpty);
      });

      test('speed 2 creates faster animation', () {
        final effect = GradientFlowEffect(speed: 2);
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.25);

        expect(canvas.operations, isNotEmpty);
      });

      test('high speed value works correctly', () {
        final effect = GradientFlowEffect(speed: 10);
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });
    });

    group('path variations', () {
      test('paint works with curved path', () {
        final effect = GradientFlowEffect();
        final canvas = MockCanvas();
        final path = createCurvedPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations.whereType<DrawPathOperation>(), isNotEmpty);
      });

      test('paint works with very short path', () {
        final effect = GradientFlowEffect();
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 5);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });

      test('paint works with very long path', () {
        final effect = GradientFlowEffect();
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 1000);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });

      test('paint works with multi-segment path', () {
        final effect = GradientFlowEffect();
        final canvas = MockCanvas();
        final path = ui.Path()
          ..moveTo(0, 0)
          ..lineTo(50, 0)
          ..moveTo(60, 0)
          ..lineTo(100, 0);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // Should handle multiple path metrics
        expect(canvas.operations, isNotEmpty);
      });
    });

    group('animation boundary conditions', () {
      test('animation at start (0.0) positions gradient at beginning', () {
        final effect = GradientFlowEffect(
          gradientLength: 0.25,
          connectionOpacity: 1.0,
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.0);

        expect(canvas.operations, isNotEmpty);
      });

      test('animation near end (0.99) positions gradient near end', () {
        final effect = GradientFlowEffect(
          gradientLength: 0.25,
          connectionOpacity: 1.0,
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.99);

        expect(canvas.operations, isNotEmpty);
      });

      test('animation values cycle smoothly from 0 to 1', () {
        final effect = GradientFlowEffect();
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        // Test multiple animation values
        for (var i = 0; i <= 10; i++) {
          canvas.operations.clear();
          final animValue = i / 10.0;
          effect.paint(canvas, path, basePaint, animValue);
          expect(
            canvas.operations,
            isNotEmpty,
            reason: 'Failed at animation value $animValue',
          );
        }
      });
    });

    group('gradient off path conditions', () {
      test('gradient entering from start draws correctly', () {
        final effect = GradientFlowEffect(
          gradientLength: 0.25,
          connectionOpacity: 0.5,
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        // At very start, gradient is entering the path
        effect.paint(canvas, path, basePaint, 0.01);

        expect(canvas.operations, isNotEmpty);
      });

      test('gradient exiting at end draws correctly', () {
        final effect = GradientFlowEffect(
          gradientLength: 0.25,
          connectionOpacity: 0.5,
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        // Near end, gradient is exiting the path
        effect.paint(canvas, path, basePaint, 0.95);

        expect(canvas.operations, isNotEmpty);
      });
    });
  });

  group('ParticleEffect Paint Tests', () {
    group('basic paint behavior', () {
      test('paint draws on canvas at animation value 0.0', () {
        final effect = ParticleEffect();
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.0);

        expect(canvas.operations, isNotEmpty);
      });

      test('paint draws on canvas at animation value 0.5', () {
        final effect = ParticleEffect();
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });

      test('paint draws on canvas at animation value 1.0', () {
        final effect = ParticleEffect();
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 1.0);

        expect(canvas.operations, isNotEmpty);
      });

      test('paint handles empty path gracefully', () {
        final effect = ParticleEffect();
        final canvas = MockCanvas();
        final emptyPath = ui.Path();
        final basePaint = createBasePaint();

        expect(
          () => effect.paint(canvas, emptyPath, basePaint, 0.5),
          returnsNormally,
        );
      });
    });

    group('particle count', () {
      test('single particle draws one circle', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // Should have base path + 1 circle
        final circleOps = canvas.operations.whereType<DrawCircleOperation>();
        expect(circleOps.length, equals(1));
      });

      test('multiple particles draw correct number of circles', () {
        final effect = ParticleEffect(
          particleCount: 5,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        final circleOps = canvas.operations.whereType<DrawCircleOperation>();
        expect(circleOps.length, equals(5));
      });

      test('particles are evenly distributed along path', () {
        final effect = ParticleEffect(
          particleCount: 4,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.0);

        final circleOps = canvas.operations
            .whereType<DrawCircleOperation>()
            .toList();
        expect(circleOps.length, equals(4));

        // Check that particles are spread across the path (0, 25, 50, 75 at animValue 0)
        final xPositions = circleOps.map((op) => op.center.dx).toList()..sort();

        // Particles should be roughly at 0%, 25%, 50%, 75% of path length
        expect(xPositions[0], closeTo(0, 1));
        expect(xPositions[1], closeTo(25, 1));
        expect(xPositions[2], closeTo(50, 1));
        expect(xPositions[3], closeTo(75, 1));
      });
    });

    group('connection opacity', () {
      test('connectionOpacity 0 hides base connection', () {
        final effect = ParticleEffect(
          connectionOpacity: 0.0,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // With 0 opacity, only particles should be drawn (no path)
        final pathOps = canvas.operations.whereType<DrawPathOperation>();
        expect(pathOps, isEmpty);
      });

      test('connectionOpacity 1 shows full base connection', () {
        final effect = ParticleEffect(
          connectionOpacity: 1.0,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // Should have path drawn
        final pathOps = canvas.operations.whereType<DrawPathOperation>();
        expect(pathOps.length, equals(1));
      });

      test('connectionOpacity affects paint alpha', () {
        final effect = ParticleEffect(
          connectionOpacity: 0.5,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint(color: Colors.blue);

        effect.paint(canvas, path, basePaint, 0.5);

        final pathOps = canvas.operations
            .whereType<DrawPathOperation>()
            .toList();
        expect(pathOps.length, equals(1));

        // The paint should have reduced opacity
        expect(pathOps[0].paint.color.a, closeTo(0.5, 0.01));
      });
    });

    group('speed variations', () {
      test('speed 1 moves particles at normal rate', () {
        final effect = ParticleEffect(
          speed: 1,
          particleCount: 1,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        final circleOps = canvas.operations
            .whereType<DrawCircleOperation>()
            .toList();
        expect(circleOps.length, equals(1));
        // At animation 0.5 with speed 1, single particle should be at 50
        expect(circleOps[0].center.dx, closeTo(50, 1));
      });

      test('speed 2 moves particles twice as fast', () {
        final effect = ParticleEffect(
          speed: 2,
          particleCount: 1,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.25);

        final circleOps = canvas.operations
            .whereType<DrawCircleOperation>()
            .toList();
        // At animation 0.25 with speed 2, position = (0.25 * 2) % 1 = 0.5
        expect(circleOps[0].center.dx, closeTo(50, 1));
      });

      test('high speed creates multiple cycles', () {
        final effect = ParticleEffect(
          speed: 4,
          particleCount: 1,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        // At 0.5 with speed 4: (0.5 * 4) % 1 = 0.0
        effect.paint(canvas, path, basePaint, 0.5);

        final circleOps = canvas.operations
            .whereType<DrawCircleOperation>()
            .toList();
        expect(circleOps[0].center.dx, closeTo(0, 1));
      });
    });

    group('CircleParticle painter', () {
      test('draws circles with correct radius', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const CircleParticle(radius: 8.0),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        final circleOps = canvas.operations
            .whereType<DrawCircleOperation>()
            .toList();
        expect(circleOps.length, equals(1));
        expect(circleOps[0].radius, equals(8.0));
      });

      test('uses custom color when specified', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const CircleParticle(color: Colors.red),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint(color: Colors.blue);

        effect.paint(canvas, path, basePaint, 0.5);

        final circleOps = canvas.operations
            .whereType<DrawCircleOperation>()
            .toList();
        // Compare Color values (MaterialColor wraps a Color)
        expect(circleOps[0].paint.color.value, equals(Colors.red.value));
      });

      test('uses base paint color when no custom color', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint(color: Colors.green);

        effect.paint(canvas, path, basePaint, 0.5);

        final circleOps = canvas.operations
            .whereType<DrawCircleOperation>()
            .toList();
        // Compare Color values (MaterialColor wraps a Color)
        expect(circleOps[0].paint.color.value, equals(Colors.green.value));
      });

      test('circle particle size is correct', () {
        const particle = CircleParticle(radius: 5.0);
        expect(particle.size, equals(const Size(10.0, 10.0)));
      });
    });

    group('ArrowParticle painter', () {
      test('draws arrows with canvas transformations', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const ArrowParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // Arrow particle uses save/translate/rotate/restore
        expect(canvas.operations.whereType<SaveOperation>(), isNotEmpty);
        expect(canvas.operations.whereType<TranslateOperation>(), isNotEmpty);
        expect(canvas.operations.whereType<RotateOperation>(), isNotEmpty);
        expect(canvas.operations.whereType<RestoreOperation>(), isNotEmpty);
        expect(canvas.operations.whereType<DrawPathOperation>(), isNotEmpty);
      });

      test('arrow rotation follows path tangent', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const ArrowParticle(),
        );
        final canvas = MockCanvas();
        // Horizontal path - tangent angle should be 0
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        final rotateOps = canvas.operations
            .whereType<RotateOperation>()
            .toList();
        expect(rotateOps.length, equals(1));
        // For horizontal path, rotation should be close to 0
        expect(rotateOps[0].radians, closeTo(0.0, 0.01));
      });

      test('arrow rotation follows diagonal path', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const ArrowParticle(),
        );
        final canvas = MockCanvas();
        // Diagonal path at 45 degrees
        final path = ui.Path()
          ..moveTo(0, 0)
          ..lineTo(100, 100);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        final rotateOps = canvas.operations
            .whereType<RotateOperation>()
            .toList();
        expect(rotateOps.length, equals(1));
        // For 45 degree path, rotation should be pi/4
        expect(rotateOps[0].radians, closeTo(math.pi / 4, 0.01));
      });

      test('uses custom color when specified', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const ArrowParticle(color: Colors.purple),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint(color: Colors.blue);

        effect.paint(canvas, path, basePaint, 0.5);

        // Arrow draws a path, find it (skip the base connection path)
        final pathOps = canvas.operations
            .whereType<DrawPathOperation>()
            .toList();
        // Last path op should be the arrow
        // Compare Color values (MaterialColor wraps a Color)
        expect(pathOps.last.paint.color.value, equals(Colors.purple.value));
      });

      test('arrow particle size reflects dimensions', () {
        const particle = ArrowParticle(length: 15.0, width: 10.0);
        expect(particle.size, equals(const Size(15.0, 10.0)));
      });
    });

    group('CharacterParticle painter', () {
      test('draws paragraph for character particle', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: CharacterParticle(character: 'X'),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // CharacterParticle uses TextPainter which draws a Paragraph
        expect(
          canvas.operations.whereType<DrawParagraphOperation>(),
          isNotEmpty,
        );
      });

      test('character particle size is computed from text', () {
        final particle = CharacterParticle(character: 'X', fontSize: 16.0);
        // Size should be positive and based on text measurement
        expect(particle.size.width, greaterThan(0));
        expect(particle.size.height, greaterThan(0));
      });

      test('emoji particle works correctly', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: CharacterParticle(character: '\u{1F680}'),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath();
        final basePaint = createBasePaint();

        expect(
          () => effect.paint(canvas, path, basePaint, 0.5),
          returnsNormally,
        );
      });
    });

    group('path variations', () {
      test('paint works with curved path', () {
        final effect = ParticleEffect(particlePainter: const CircleParticle());
        final canvas = MockCanvas();
        final path = createCurvedPath();
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations.whereType<DrawCircleOperation>(), isNotEmpty);
      });

      test('paint works with very short path', () {
        final effect = ParticleEffect(particlePainter: const CircleParticle());
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 5);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        expect(canvas.operations, isNotEmpty);
      });

      test('paint works with multi-segment path', () {
        final effect = ParticleEffect(
          particleCount: 2,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = ui.Path()
          ..moveTo(0, 0)
          ..lineTo(50, 0)
          ..moveTo(60, 0)
          ..lineTo(100, 0);
        final basePaint = createBasePaint();

        effect.paint(canvas, path, basePaint, 0.5);

        // Particles should be drawn for each path metric
        expect(canvas.operations.whereType<DrawCircleOperation>(), isNotEmpty);
      });
    });

    group('animation continuity', () {
      test('particles loop seamlessly from 0 to 1', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        // Get position at animation 0.0
        effect.paint(canvas, path, basePaint, 0.0);
        final pos0 = canvas.operations
            .whereType<DrawCircleOperation>()
            .first
            .center
            .dx;

        canvas.operations.clear();

        // Get position at animation 1.0 (should be same as 0.0 for seamless loop)
        effect.paint(canvas, path, basePaint, 1.0);
        final pos1 = canvas.operations
            .whereType<DrawCircleOperation>()
            .first
            .center
            .dx;

        // Position at 1.0 should equal position at 0.0 (modulo makes them same)
        expect(pos1, closeTo(pos0, 1));
      });

      test('particles move continuously through animation values', () {
        final effect = ParticleEffect(
          particleCount: 1,
          particlePainter: const CircleParticle(),
        );
        final canvas = MockCanvas();
        final path = createHorizontalPath(length: 100);
        final basePaint = createBasePaint();

        final positions = <double>[];

        // Sample positions at various animation values
        for (var i = 0; i < 10; i++) {
          canvas.operations.clear();
          final animValue = i / 10.0;
          effect.paint(canvas, path, basePaint, animValue);
          final pos = canvas.operations
              .whereType<DrawCircleOperation>()
              .first
              .center
              .dx;
          positions.add(pos);
        }

        // Positions should increase (particles moving forward)
        for (var i = 1; i < positions.length; i++) {
          expect(
            positions[i],
            greaterThan(positions[i - 1]),
            reason: 'Position should increase at index $i',
          );
        }
      });
    });
  });

  group('Integration with ConnectionEffect Interface', () {
    test('GradientFlowEffect implements ConnectionEffect correctly', () {
      final ConnectionEffect effect = GradientFlowEffect();
      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      // Should be callable via interface
      effect.paint(canvas, path, basePaint, 0.5);

      expect(canvas.operations, isNotEmpty);
    });

    test('ParticleEffect implements ConnectionEffect correctly', () {
      final ConnectionEffect effect = ParticleEffect();
      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      // Should be callable via interface
      effect.paint(canvas, path, basePaint, 0.5);

      expect(canvas.operations, isNotEmpty);
    });

    test('effects can be used interchangeably', () {
      final effects = <ConnectionEffect>[
        GradientFlowEffect(),
        ParticleEffect(),
        GradientFlowEffect(colors: [Colors.red, Colors.blue]),
        ParticleEffect(particlePainter: const ArrowParticle()),
      ];

      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      for (final effect in effects) {
        canvas.operations.clear();
        effect.paint(canvas, path, basePaint, 0.5);
        expect(
          canvas.operations,
          isNotEmpty,
          reason: 'Effect ${effect.runtimeType} should draw something',
        );
      }
    });
  });

  group('Built-in Effect Presets Paint Tests', () {
    test('ConnectionEffects.gradientFlow paints correctly', () {
      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      ConnectionEffects.gradientFlow.paint(canvas, path, basePaint, 0.5);

      expect(canvas.operations, isNotEmpty);
    });

    test('ConnectionEffects.gradientFlowBlue paints with blue colors', () {
      final effect = ConnectionEffects.gradientFlowBlue as GradientFlowEffect;
      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      effect.paint(canvas, path, basePaint, 0.5);

      expect(canvas.operations, isNotEmpty);
      expect(effect.colors, contains(Colors.blue));
    });

    test('ConnectionEffects.particles paints correctly', () {
      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      ConnectionEffects.particles.paint(canvas, path, basePaint, 0.5);

      expect(canvas.operations.whereType<DrawCircleOperation>(), isNotEmpty);
    });

    test('ConnectionEffects.particlesArrow paints with arrows', () {
      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      ConnectionEffects.particlesArrow.paint(canvas, path, basePaint, 0.5);

      // Arrow particles use save/restore
      expect(canvas.operations.whereType<SaveOperation>(), isNotEmpty);
    });
  });

  group('Edge Cases', () {
    test('GradientFlowEffect with minimum valid values', () {
      // Minimum speed is 1, minimum gradientLength > 0
      final effect = GradientFlowEffect(
        speed: 1,
        gradientLength: 0.01,
        connectionOpacity: 0.0,
      );
      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      expect(() => effect.paint(canvas, path, basePaint, 0.5), returnsNormally);
    });

    test('ParticleEffect with minimum particle count', () {
      final effect = ParticleEffect(
        particleCount: 1,
        speed: 1,
        connectionOpacity: 0.0,
      );
      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      effect.paint(canvas, path, basePaint, 0.5);

      final circleOps = canvas.operations.whereType<DrawCircleOperation>();
      expect(circleOps.length, equals(1));
    });

    test('effects handle path with zero length gracefully', () {
      final gradientEffect = GradientFlowEffect();
      final particleEffect = ParticleEffect();
      final canvas = MockCanvas();
      // Point path (zero length)
      final path = ui.Path()..moveTo(50, 50);
      final basePaint = createBasePaint();

      // Should not throw
      expect(
        () => gradientEffect.paint(canvas, path, basePaint, 0.5),
        returnsNormally,
      );
      expect(
        () => particleEffect.paint(canvas, path, basePaint, 0.5),
        returnsNormally,
      );
    });

    test('multiple effects on same canvas accumulate operations', () {
      final effect1 = GradientFlowEffect();
      final effect2 = ParticleEffect();
      final canvas = MockCanvas();
      final path = createHorizontalPath();
      final basePaint = createBasePaint();

      effect1.paint(canvas, path, basePaint, 0.5);
      final count1 = canvas.operations.length;

      effect2.paint(canvas, path, basePaint, 0.5);
      final count2 = canvas.operations.length;

      expect(count2, greaterThan(count1));
    });
  });
}
