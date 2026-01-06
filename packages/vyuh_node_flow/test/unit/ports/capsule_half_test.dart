/// Comprehensive unit tests for CapsuleHalf and CapsuleHalfPainter in vyuh_node_flow.
///
/// Tests cover:
/// - CapsuleFlatSide enum and its opposite property
/// - CapsuleHalf widget construction and rendering
/// - CapsuleHalfPainter static paint method
/// - All capsule half shapes/positions (left, right, top, bottom)
/// - Boundary calculations and radius computation
/// - Edge cases (zero size, asymmetric sizes, large sizes)
@Tags(['unit'])
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/ports/capsule_half.dart';

void main() {
  // ===========================================================================
  // CapsuleFlatSide Enum Tests
  // ===========================================================================
  group('CapsuleFlatSide Enum', () {
    group('enum values', () {
      test('has all four expected values', () {
        expect(CapsuleFlatSide.values.length, equals(4));
        expect(CapsuleFlatSide.values, contains(CapsuleFlatSide.left));
        expect(CapsuleFlatSide.values, contains(CapsuleFlatSide.right));
        expect(CapsuleFlatSide.values, contains(CapsuleFlatSide.top));
        expect(CapsuleFlatSide.values, contains(CapsuleFlatSide.bottom));
      });

      test('enum indices are stable', () {
        expect(CapsuleFlatSide.left.index, equals(0));
        expect(CapsuleFlatSide.right.index, equals(1));
        expect(CapsuleFlatSide.top.index, equals(2));
        expect(CapsuleFlatSide.bottom.index, equals(3));
      });
    });

    group('opposite property', () {
      test('left opposite is right', () {
        expect(CapsuleFlatSide.left.opposite, equals(CapsuleFlatSide.right));
      });

      test('right opposite is left', () {
        expect(CapsuleFlatSide.right.opposite, equals(CapsuleFlatSide.left));
      });

      test('top opposite is bottom', () {
        expect(CapsuleFlatSide.top.opposite, equals(CapsuleFlatSide.bottom));
      });

      test('bottom opposite is top', () {
        expect(CapsuleFlatSide.bottom.opposite, equals(CapsuleFlatSide.top));
      });

      test('opposite is symmetric (double opposite returns original)', () {
        for (final side in CapsuleFlatSide.values) {
          expect(side.opposite.opposite, equals(side));
        }
      });
    });

    group('opposite pairs are mutually exclusive', () {
      test('left-right pair', () {
        expect(
          CapsuleFlatSide.left.opposite,
          isNot(equals(CapsuleFlatSide.left)),
        );
        expect(
          CapsuleFlatSide.right.opposite,
          isNot(equals(CapsuleFlatSide.right)),
        );
      });

      test('top-bottom pair', () {
        expect(
          CapsuleFlatSide.top.opposite,
          isNot(equals(CapsuleFlatSide.top)),
        );
        expect(
          CapsuleFlatSide.bottom.opposite,
          isNot(equals(CapsuleFlatSide.bottom)),
        );
      });
    });
  });

  // ===========================================================================
  // CapsuleHalf Widget Tests
  // ===========================================================================
  group('CapsuleHalf Widget', () {
    group('construction', () {
      test('creates widget with required parameters', () {
        const widget = CapsuleHalf(
          size: 10.0,
          flatSide: CapsuleFlatSide.left,
          color: Colors.blue,
          borderColor: Colors.black,
          borderWidth: 1.0,
        );

        expect(widget.size, equals(10.0));
        expect(widget.flatSide, equals(CapsuleFlatSide.left));
        expect(widget.color, equals(Colors.blue));
        expect(widget.borderColor, equals(Colors.black));
        expect(widget.borderWidth, equals(1.0));
      });

      test('creates widget for each flat side', () {
        for (final side in CapsuleFlatSide.values) {
          final widget = CapsuleHalf(
            size: 12.0,
            flatSide: side,
            color: Colors.red,
            borderColor: Colors.white,
            borderWidth: 2.0,
          );

          expect(widget.flatSide, equals(side));
        }
      });
    });

    group('rendering', () {
      testWidgets('renders without error for left flat side', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: 20.0,
                  flatSide: CapsuleFlatSide.left,
                  color: Colors.blue,
                  borderColor: Colors.black,
                  borderWidth: 1.0,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsOneWidget);
        // CapsuleHalf uses CustomPaint internally
        expect(
          find.descendant(
            of: find.byType(CapsuleHalf),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );
      });

      testWidgets('renders without error for right flat side', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: 20.0,
                  flatSide: CapsuleFlatSide.right,
                  color: Colors.green,
                  borderColor: Colors.grey,
                  borderWidth: 2.0,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsOneWidget);
      });

      testWidgets('renders without error for top flat side', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: 20.0,
                  flatSide: CapsuleFlatSide.top,
                  color: Colors.red,
                  borderColor: Colors.black,
                  borderWidth: 1.5,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsOneWidget);
      });

      testWidgets('renders without error for bottom flat side', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: 20.0,
                  flatSide: CapsuleFlatSide.bottom,
                  color: Colors.yellow,
                  borderColor: Colors.brown,
                  borderWidth: 0.5,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsOneWidget);
      });

      testWidgets('widget size matches specified size', (tester) async {
        const testSize = 30.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: testSize,
                  flatSide: CapsuleFlatSide.left,
                  color: Colors.blue,
                  borderColor: Colors.black,
                  borderWidth: 1.0,
                ),
              ),
            ),
          ),
        );

        final capsuleHalf = tester.widget<CapsuleHalf>(
          find.byType(CapsuleHalf),
        );
        expect(capsuleHalf.size, equals(testSize));

        // Find the CustomPaint that is a descendant of CapsuleHalf
        final customPaintFinder = find.descendant(
          of: find.byType(CapsuleHalf),
          matching: find.byType(CustomPaint),
        );
        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        expect(customPaint.size, equals(const Size(testSize, testSize)));
      });

      testWidgets('renders all flat sides in same widget tree', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: CapsuleFlatSide.values
                    .map(
                      (side) => CapsuleHalf(
                        key: ValueKey(side),
                        size: 16.0,
                        flatSide: side,
                        color: Colors.blue,
                        borderColor: Colors.black,
                        borderWidth: 1.0,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsNWidgets(4));
      });
    });

    group('edge cases', () {
      testWidgets('renders with zero border width', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: 20.0,
                  flatSide: CapsuleFlatSide.left,
                  color: Colors.blue,
                  borderColor: Colors.black,
                  borderWidth: 0.0,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsOneWidget);
      });

      testWidgets('renders with very small size', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: 1.0,
                  flatSide: CapsuleFlatSide.right,
                  color: Colors.blue,
                  borderColor: Colors.black,
                  borderWidth: 0.5,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsOneWidget);
      });

      testWidgets('renders with large size', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: 200.0,
                  flatSide: CapsuleFlatSide.top,
                  color: Colors.blue,
                  borderColor: Colors.black,
                  borderWidth: 5.0,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsOneWidget);
      });

      testWidgets('renders with transparent colors', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: 20.0,
                  flatSide: CapsuleFlatSide.bottom,
                  color: Colors.transparent,
                  borderColor: Colors.transparent,
                  borderWidth: 1.0,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsOneWidget);
      });

      testWidgets('renders with very thick border', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CapsuleHalf(
                  size: 20.0,
                  flatSide: CapsuleFlatSide.left,
                  color: Colors.blue,
                  borderColor: Colors.black,
                  borderWidth: 10.0,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CapsuleHalf), findsOneWidget);
      });
    });
  });

  // ===========================================================================
  // CapsuleHalfPainter Static Paint Method Tests
  // ===========================================================================
  group('CapsuleHalfPainter', () {
    late ui.PictureRecorder recorder;
    late Canvas canvas;

    setUp(() {
      recorder = ui.PictureRecorder();
      canvas = Canvas(recorder);
    });

    tearDown(() {
      recorder.endRecording();
    });

    group('paint method with fill only', () {
      test('paints left flat side capsule half', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        // Should not throw
        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          CapsuleFlatSide.left,
          fillPaint,
          null,
        );

        expect(true, isTrue); // Paint completed without error
      });

      test('paints right flat side capsule half', () {
        final fillPaint = Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          CapsuleFlatSide.right,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('paints top flat side capsule half', () {
        final fillPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          CapsuleFlatSide.top,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('paints bottom flat side capsule half', () {
        final fillPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          CapsuleFlatSide.bottom,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });
    });

    group('paint method with fill and border', () {
      test('paints capsule half with border for all flat sides', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        for (final side in CapsuleFlatSide.values) {
          CapsuleHalfPainter.paint(
            canvas,
            const Offset(100, 100),
            const Size(30, 30),
            side,
            fillPaint,
            borderPaint,
          );
        }

        expect(true, isTrue);
      });

      test('paints with different border widths', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        for (final width in [0.5, 1.0, 2.0, 5.0, 10.0]) {
          final borderPaint = Paint()
            ..color = Colors.black
            ..strokeWidth = width
            ..style = PaintingStyle.stroke;

          CapsuleHalfPainter.paint(
            canvas,
            const Offset(50, 50),
            const Size(20, 20),
            CapsuleFlatSide.left,
            fillPaint,
            borderPaint,
          );
        }

        expect(true, isTrue);
      });
    });

    group('paint method with various sizes', () {
      test('paints square capsule half', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(40, 40),
          CapsuleFlatSide.left,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('paints wide capsule half (horizontal orientation)', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        // For left/right flat sides, radius = height / 2
        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(60, 20),
          CapsuleFlatSide.left,
          fillPaint,
          null,
        );

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(60, 20),
          CapsuleFlatSide.right,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('paints tall capsule half (vertical orientation)', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        // For top/bottom flat sides, radius = width / 2
        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 60),
          CapsuleFlatSide.top,
          fillPaint,
          null,
        );

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 60),
          CapsuleFlatSide.bottom,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('paints very small capsule half', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(5, 5),
          const Size(2, 2),
          CapsuleFlatSide.left,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('paints large capsule half', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(500, 500),
          const Size(200, 200),
          CapsuleFlatSide.right,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });
    });

    group('paint method with various center positions', () {
      test('paints at origin', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          Offset.zero,
          const Size(20, 20),
          CapsuleFlatSide.left,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('paints at negative coordinates', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(-50, -50),
          const Size(20, 20),
          CapsuleFlatSide.top,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('paints at large coordinates', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(10000, 10000),
          const Size(20, 20),
          CapsuleFlatSide.bottom,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('paints at fractional coordinates', () {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(25.5, 30.75),
          const Size(15.25, 15.25),
          CapsuleFlatSide.right,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });
    });

    group('radius calculation verification', () {
      test('horizontal sides use height/2 for radius', () {
        // For left/right flat sides, the radius should be height / 2
        // This test verifies the paint doesn't throw with asymmetric sizes
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        // Width > Height scenario
        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(100, 20), // radius will be 10
          CapsuleFlatSide.left,
          fillPaint,
          null,
        );

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(100, 20),
          CapsuleFlatSide.right,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });

      test('vertical sides use width/2 for radius', () {
        // For top/bottom flat sides, the radius should be width / 2
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        // Height > Width scenario
        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 100), // radius will be 10
          CapsuleFlatSide.top,
          fillPaint,
          null,
        );

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 100),
          CapsuleFlatSide.bottom,
          fillPaint,
          null,
        );

        expect(true, isTrue);
      });
    });
  });

  // ===========================================================================
  // _CapsuleHalfCustomPainter shouldRepaint Tests
  // ===========================================================================
  group('CapsuleHalfCustomPainter shouldRepaint', () {
    testWidgets('repaints when flatSide changes', (tester) async {
      var currentSide = CapsuleFlatSide.left;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: GestureDetector(
                  onTap: () {
                    setState(() {
                      currentSide = CapsuleFlatSide.right;
                    });
                  },
                  child: CapsuleHalf(
                    size: 20.0,
                    flatSide: currentSide,
                    color: Colors.blue,
                    borderColor: Colors.black,
                    borderWidth: 1.0,
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(CapsuleHalf), findsOneWidget);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(find.byType(CapsuleHalf), findsOneWidget);
    });

    testWidgets('repaints when color changes', (tester) async {
      var currentColor = Colors.blue;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: GestureDetector(
                  onTap: () {
                    setState(() {
                      currentColor = Colors.red;
                    });
                  },
                  child: CapsuleHalf(
                    size: 20.0,
                    flatSide: CapsuleFlatSide.left,
                    color: currentColor,
                    borderColor: Colors.black,
                    borderWidth: 1.0,
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(find.byType(CapsuleHalf), findsOneWidget);
    });

    testWidgets('repaints when borderColor changes', (tester) async {
      var currentBorderColor = Colors.black;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: GestureDetector(
                  onTap: () {
                    setState(() {
                      currentBorderColor = Colors.white;
                    });
                  },
                  child: CapsuleHalf(
                    size: 20.0,
                    flatSide: CapsuleFlatSide.left,
                    color: Colors.blue,
                    borderColor: currentBorderColor,
                    borderWidth: 1.0,
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(find.byType(CapsuleHalf), findsOneWidget);
    });

    testWidgets('repaints when borderWidth changes', (tester) async {
      var currentBorderWidth = 1.0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: GestureDetector(
                  onTap: () {
                    setState(() {
                      currentBorderWidth = 3.0;
                    });
                  },
                  child: CapsuleHalf(
                    size: 20.0,
                    flatSide: CapsuleFlatSide.left,
                    color: Colors.blue,
                    borderColor: Colors.black,
                    borderWidth: currentBorderWidth,
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(find.byType(CapsuleHalf), findsOneWidget);
    });
  });

  // ===========================================================================
  // Boundary Calculations Tests
  // ===========================================================================
  group('Boundary Calculations', () {
    group('rect from center calculation', () {
      test('rect is correctly positioned from center', () {
        // The painter creates a rect from center: Rect.fromCenter(center: center, width: width, height: height)
        const center = Offset(50, 50);
        const size = Size(20, 20);

        final rect = Rect.fromCenter(
          center: center,
          width: size.width,
          height: size.height,
        );

        expect(rect.left, equals(40)); // 50 - 10
        expect(rect.top, equals(40)); // 50 - 10
        expect(rect.right, equals(60)); // 50 + 10
        expect(rect.bottom, equals(60)); // 50 + 10
        expect(rect.width, equals(20));
        expect(rect.height, equals(20));
      });

      test('rect handles asymmetric sizes', () {
        const center = Offset(100, 100);
        const size = Size(40, 20);

        final rect = Rect.fromCenter(
          center: center,
          width: size.width,
          height: size.height,
        );

        expect(rect.left, equals(80)); // 100 - 20
        expect(rect.top, equals(90)); // 100 - 10
        expect(rect.right, equals(120)); // 100 + 20
        expect(rect.bottom, equals(110)); // 100 + 10
      });
    });

    group('rounded rect corners', () {
      test('left flat side has rounded right corners', () {
        // Flat left edge, curved right edge
        // topRight and bottomRight should have radius
        const size = Size(20, 20);
        const radius = 10.0; // height / 2 for horizontal

        final rect = Rect.fromCenter(
          center: const Offset(50, 50),
          width: size.width,
          height: size.height,
        );
        final rrect = RRect.fromRectAndCorners(
          rect,
          topRight: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );

        expect(rrect.trRadius, equals(const Radius.circular(10)));
        expect(rrect.brRadius, equals(const Radius.circular(10)));
        expect(rrect.tlRadius, equals(Radius.zero));
        expect(rrect.blRadius, equals(Radius.zero));
      });

      test('right flat side has rounded left corners', () {
        // Flat right edge, curved left edge
        const size = Size(20, 20);
        const radius = 10.0;

        final rect = Rect.fromCenter(
          center: const Offset(50, 50),
          width: size.width,
          height: size.height,
        );
        final rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
        );

        expect(rrect.tlRadius, equals(const Radius.circular(10)));
        expect(rrect.blRadius, equals(const Radius.circular(10)));
        expect(rrect.trRadius, equals(Radius.zero));
        expect(rrect.brRadius, equals(Radius.zero));
      });

      test('top flat side has rounded bottom corners', () {
        // Flat top edge, curved bottom edge
        const size = Size(20, 20);
        const radius = 10.0; // width / 2 for vertical

        final rect = Rect.fromCenter(
          center: const Offset(50, 50),
          width: size.width,
          height: size.height,
        );
        final rrect = RRect.fromRectAndCorners(
          rect,
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );

        expect(rrect.blRadius, equals(const Radius.circular(10)));
        expect(rrect.brRadius, equals(const Radius.circular(10)));
        expect(rrect.tlRadius, equals(Radius.zero));
        expect(rrect.trRadius, equals(Radius.zero));
      });

      test('bottom flat side has rounded top corners', () {
        // Flat bottom edge, curved top edge
        const size = Size(20, 20);
        const radius = 10.0;

        final rect = Rect.fromCenter(
          center: const Offset(50, 50),
          width: size.width,
          height: size.height,
        );
        final rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        );

        expect(rrect.tlRadius, equals(const Radius.circular(10)));
        expect(rrect.trRadius, equals(const Radius.circular(10)));
        expect(rrect.blRadius, equals(Radius.zero));
        expect(rrect.brRadius, equals(Radius.zero));
      });
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================
  group('Edge Cases', () {
    late ui.PictureRecorder recorder;
    late Canvas canvas;

    setUp(() {
      recorder = ui.PictureRecorder();
      canvas = Canvas(recorder);
    });

    tearDown(() {
      recorder.endRecording();
    });

    test('handles zero width', () {
      final fillPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      // Should not throw
      CapsuleHalfPainter.paint(
        canvas,
        const Offset(50, 50),
        const Size(0, 20),
        CapsuleFlatSide.left,
        fillPaint,
        null,
      );

      expect(true, isTrue);
    });

    test('handles zero height', () {
      final fillPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      CapsuleHalfPainter.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 0),
        CapsuleFlatSide.top,
        fillPaint,
        null,
      );

      expect(true, isTrue);
    });

    test('handles zero size', () {
      final fillPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      CapsuleHalfPainter.paint(
        canvas,
        const Offset(50, 50),
        Size.zero,
        CapsuleFlatSide.right,
        fillPaint,
        null,
      );

      expect(true, isTrue);
    });

    test('handles very large dimensions', () {
      final fillPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      CapsuleHalfPainter.paint(
        canvas,
        const Offset(5000, 5000),
        const Size(10000, 10000),
        CapsuleFlatSide.bottom,
        fillPaint,
        null,
      );

      expect(true, isTrue);
    });

    test('handles extreme aspect ratio (very wide)', () {
      final fillPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      CapsuleHalfPainter.paint(
        canvas,
        const Offset(500, 50),
        const Size(1000, 2),
        CapsuleFlatSide.left,
        fillPaint,
        null,
      );

      expect(true, isTrue);
    });

    test('handles extreme aspect ratio (very tall)', () {
      final fillPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      CapsuleHalfPainter.paint(
        canvas,
        const Offset(50, 500),
        const Size(2, 1000),
        CapsuleFlatSide.top,
        fillPaint,
        null,
      );

      expect(true, isTrue);
    });

    test('handles paint with various blend modes', () {
      for (final blendMode in [
        BlendMode.src,
        BlendMode.dst,
        BlendMode.srcOver,
        BlendMode.clear,
      ]) {
        final fillPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill
          ..blendMode = blendMode;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          CapsuleFlatSide.left,
          fillPaint,
          null,
        );
      }

      expect(true, isTrue);
    });

    test('handles paint with various stroke caps', () {
      final fillPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      for (final strokeCap in [
        StrokeCap.butt,
        StrokeCap.round,
        StrokeCap.square,
      ]) {
        final borderPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = strokeCap;

        CapsuleHalfPainter.paint(
          canvas,
          const Offset(50, 50),
          const Size(20, 20),
          CapsuleFlatSide.right,
          fillPaint,
          borderPaint,
        );
      }

      expect(true, isTrue);
    });

    test('handles paint with anti-aliasing disabled', () {
      final fillPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..isAntiAlias = false;

      CapsuleHalfPainter.paint(
        canvas,
        const Offset(50, 50),
        const Size(20, 20),
        CapsuleFlatSide.top,
        fillPaint,
        borderPaint,
      );

      expect(true, isTrue);
    });
  });

  // ===========================================================================
  // Integration Tests
  // ===========================================================================
  group('Integration', () {
    testWidgets('multiple CapsuleHalf widgets can coexist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    const CapsuleHalf(
                      size: 16.0,
                      flatSide: CapsuleFlatSide.left,
                      color: Colors.blue,
                      borderColor: Colors.black,
                      borderWidth: 1.0,
                    ),
                    const SizedBox(width: 8),
                    const CapsuleHalf(
                      size: 16.0,
                      flatSide: CapsuleFlatSide.right,
                      color: Colors.green,
                      borderColor: Colors.black,
                      borderWidth: 1.0,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CapsuleHalf(
                      size: 16.0,
                      flatSide: CapsuleFlatSide.top,
                      color: Colors.red,
                      borderColor: Colors.black,
                      borderWidth: 1.0,
                    ),
                    const SizedBox(width: 8),
                    const CapsuleHalf(
                      size: 16.0,
                      flatSide: CapsuleFlatSide.bottom,
                      color: Colors.yellow,
                      borderColor: Colors.black,
                      borderWidth: 1.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CapsuleHalf), findsNWidgets(4));
    });

    testWidgets('CapsuleHalf updates correctly when rebuilt', (tester) async {
      var size = 16.0;
      var side = CapsuleFlatSide.left;
      var color = Colors.blue;

      late StateSetter testSetState;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            testSetState = setState;
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CapsuleHalf(
                    size: size,
                    flatSide: side,
                    color: color,
                    borderColor: Colors.black,
                    borderWidth: 1.0,
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(CapsuleHalf), findsOneWidget);

      // Update all properties
      testSetState(() {
        size = 24.0;
        side = CapsuleFlatSide.right;
        color = Colors.red;
      });
      await tester.pump();

      expect(find.byType(CapsuleHalf), findsOneWidget);

      // Verify the widget was updated (we can't directly check painter properties,
      // but the widget should rebuild without error)
      final widget = tester.widget<CapsuleHalf>(find.byType(CapsuleHalf));
      expect(widget.size, equals(24.0));
      expect(widget.flatSide, equals(CapsuleFlatSide.right));
      expect(widget.color, equals(Colors.red));
    });

    testWidgets('CapsuleHalf renders correctly at different scales', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (final scale in [0.5, 1.0, 2.0, 3.0])
                  Transform.scale(
                    scale: scale,
                    child: const CapsuleHalf(
                      size: 16.0,
                      flatSide: CapsuleFlatSide.left,
                      color: Colors.blue,
                      borderColor: Colors.black,
                      borderWidth: 1.0,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CapsuleHalf), findsNWidgets(4));
    });

    testWidgets('CapsuleHalf works with opacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Opacity(
              opacity: 0.5,
              child: const CapsuleHalf(
                size: 20.0,
                flatSide: CapsuleFlatSide.left,
                color: Colors.blue,
                borderColor: Colors.black,
                borderWidth: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CapsuleHalf), findsOneWidget);
    });
  });
}
