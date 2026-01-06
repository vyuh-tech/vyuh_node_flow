/// Unit tests for coordinate extension types in [coordinates.dart].
///
/// Tests cover:
/// - GraphPosition: Construction, arithmetic, distance calculations, lerp
/// - ScreenPosition: Construction, arithmetic, debug strings
/// - GraphOffset: Construction, arithmetic, distance property
/// - ScreenOffset: Construction, arithmetic, distance property
/// - GraphPositionOffsetExtension: translate method
/// - ScreenPositionOffsetExtension: translate method
/// - GraphRect: Construction, properties, contains, overlaps, transformations
/// - ScreenRect: Construction, properties, contains, overlaps
/// - Edge cases: Zero values, negative values, infinity, large values
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

  // ===========================================================================
  // GraphPosition Tests
  // ===========================================================================

  group('GraphPosition', () {
    group('construction', () {
      test('creates from Offset constructor', () {
        const pos = GraphPosition(Offset(100, 200));

        expect(pos.dx, equals(100.0));
        expect(pos.dy, equals(200.0));
      });

      test('creates from fromXY factory', () {
        final pos = GraphPosition.fromXY(150, 250);

        expect(pos.dx, equals(150.0));
        expect(pos.dy, equals(250.0));
      });

      test('zero constant is at origin', () {
        expect(GraphPosition.zero.dx, equals(0.0));
        expect(GraphPosition.zero.dy, equals(0.0));
      });

      test('offset property returns underlying Offset', () {
        final pos = GraphPosition.fromXY(100, 200);

        expect(pos.offset, equals(const Offset(100, 200)));
      });
    });

    group('arithmetic operators', () {
      test('addition combines two positions', () {
        final pos1 = GraphPosition.fromXY(100, 50);
        final pos2 = GraphPosition.fromXY(25, 75);

        final result = pos1 + pos2;

        expect(result.dx, equals(125.0));
        expect(result.dy, equals(125.0));
      });

      test('subtraction finds difference between positions', () {
        final pos1 = GraphPosition.fromXY(100, 80);
        final pos2 = GraphPosition.fromXY(30, 20);

        final result = pos1 - pos2;

        expect(result.dx, equals(70.0));
        expect(result.dy, equals(60.0));
      });

      test('unary negation inverts position', () {
        final pos = GraphPosition.fromXY(100, -50);

        final result = -pos;

        expect(result.dx, equals(-100.0));
        expect(result.dy, equals(50.0));
      });

      test('multiplication scales position', () {
        final pos = GraphPosition.fromXY(50, 25);

        final result = pos * 3;

        expect(result.dx, equals(150.0));
        expect(result.dy, equals(75.0));
      });

      test('division scales position down', () {
        final pos = GraphPosition.fromXY(100, 50);

        final result = pos / 2;

        expect(result.dx, equals(50.0));
        expect(result.dy, equals(25.0));
      });

      test('multiplication by zero results in zero', () {
        final pos = GraphPosition.fromXY(100, 200);

        final result = pos * 0;

        expect(result.dx, equals(0.0));
        expect(result.dy, equals(0.0));
      });

      test('multiplication by negative value inverts', () {
        final pos = GraphPosition.fromXY(50, 100);

        final result = pos * -2;

        expect(result.dx, equals(-100.0));
        expect(result.dy, equals(-200.0));
      });
    });

    group('distance calculations', () {
      test('distanceTo calculates Euclidean distance', () {
        final pos1 = GraphPosition.fromXY(0, 0);
        final pos2 = GraphPosition.fromXY(3, 4);

        expect(pos1.distanceTo(pos2), equals(5.0));
      });

      test('distanceTo returns zero for same position', () {
        final pos = GraphPosition.fromXY(100, 200);

        expect(pos.distanceTo(pos), equals(0.0));
      });

      test('distanceTo is symmetric', () {
        final pos1 = GraphPosition.fromXY(10, 20);
        final pos2 = GraphPosition.fromXY(40, 60);

        expect(pos1.distanceTo(pos2), equals(pos2.distanceTo(pos1)));
      });

      test('distanceSquaredTo calculates squared distance', () {
        final pos1 = GraphPosition.fromXY(0, 0);
        final pos2 = GraphPosition.fromXY(3, 4);

        expect(pos1.distanceSquaredTo(pos2), equals(25.0));
      });

      test('distanceSquaredTo avoids sqrt for performance', () {
        final pos1 = GraphPosition.fromXY(10, 10);
        final pos2 = GraphPosition.fromXY(20, 20);

        final distance = pos1.distanceTo(pos2);
        final distanceSquared = pos1.distanceSquaredTo(pos2);

        expect(distanceSquared, closeTo(distance * distance, 0.001));
      });

      test('distanceSquaredTo with negative coordinates', () {
        final pos1 = GraphPosition.fromXY(-10, -20);
        final pos2 = GraphPosition.fromXY(10, 20);

        // Distance = sqrt((20)^2 + (40)^2) = sqrt(400 + 1600) = sqrt(2000)
        expect(pos1.distanceSquaredTo(pos2), equals(2000.0));
      });
    });

    group('lerp interpolation', () {
      test('lerp at t=0 returns first position', () {
        final pos1 = GraphPosition.fromXY(0, 0);
        final pos2 = GraphPosition.fromXY(100, 200);

        final result = GraphPosition.lerp(pos1, pos2, 0);

        expect(result.dx, equals(0.0));
        expect(result.dy, equals(0.0));
      });

      test('lerp at t=1 returns second position', () {
        final pos1 = GraphPosition.fromXY(0, 0);
        final pos2 = GraphPosition.fromXY(100, 200);

        final result = GraphPosition.lerp(pos1, pos2, 1);

        expect(result.dx, equals(100.0));
        expect(result.dy, equals(200.0));
      });

      test('lerp at t=0.5 returns midpoint', () {
        final pos1 = GraphPosition.fromXY(0, 0);
        final pos2 = GraphPosition.fromXY(100, 200);

        final result = GraphPosition.lerp(pos1, pos2, 0.5);

        expect(result.dx, equals(50.0));
        expect(result.dy, equals(100.0));
      });

      test('lerp at t=0.25 returns quarter point', () {
        final pos1 = GraphPosition.fromXY(0, 0);
        final pos2 = GraphPosition.fromXY(100, 200);

        final result = GraphPosition.lerp(pos1, pos2, 0.25);

        expect(result.dx, equals(25.0));
        expect(result.dy, equals(50.0));
      });

      test('lerp with negative coordinates', () {
        final pos1 = GraphPosition.fromXY(-100, -50);
        final pos2 = GraphPosition.fromXY(100, 50);

        final result = GraphPosition.lerp(pos1, pos2, 0.5);

        expect(result.dx, equals(0.0));
        expect(result.dy, equals(0.0));
      });

      test('lerp extrapolates beyond t=1', () {
        final pos1 = GraphPosition.fromXY(0, 0);
        final pos2 = GraphPosition.fromXY(100, 100);

        final result = GraphPosition.lerp(pos1, pos2, 2.0);

        expect(result.dx, equals(200.0));
        expect(result.dy, equals(200.0));
      });

      test('lerp extrapolates below t=0', () {
        final pos1 = GraphPosition.fromXY(100, 100);
        final pos2 = GraphPosition.fromXY(200, 200);

        final result = GraphPosition.lerp(pos1, pos2, -1.0);

        expect(result.dx, equals(0.0));
        expect(result.dy, equals(0.0));
      });
    });

    group('isFinite', () {
      test('returns true for finite coordinates', () {
        final pos = GraphPosition.fromXY(100, 200);

        expect(pos.isFinite, isTrue);
      });

      test('returns true for zero', () {
        expect(GraphPosition.zero.isFinite, isTrue);
      });

      test('returns true for negative coordinates', () {
        final pos = GraphPosition.fromXY(-100, -200);

        expect(pos.isFinite, isTrue);
      });

      test('returns false for infinite x', () {
        const pos = GraphPosition(Offset(double.infinity, 100));

        expect(pos.isFinite, isFalse);
      });

      test('returns false for infinite y', () {
        const pos = GraphPosition(Offset(100, double.infinity));

        expect(pos.isFinite, isFalse);
      });

      test('returns false for negative infinity', () {
        const pos = GraphPosition(Offset(double.negativeInfinity, 100));

        expect(pos.isFinite, isFalse);
      });

      test('returns false for NaN', () {
        const pos = GraphPosition(Offset(double.nan, 100));

        expect(pos.isFinite, isFalse);
      });
    });

    group('toDebugString', () {
      test('formats with one decimal place', () {
        final pos = GraphPosition.fromXY(123.456, 789.012);

        final result = pos.toDebugString();

        expect(result, equals('GraphPosition(123.5, 789.0)'));
      });

      test('formats zero correctly', () {
        final result = GraphPosition.zero.toDebugString();

        expect(result, equals('GraphPosition(0.0, 0.0)'));
      });

      test('formats negative values correctly', () {
        final pos = GraphPosition.fromXY(-50.5, -100.9);

        final result = pos.toDebugString();

        expect(result, equals('GraphPosition(-50.5, -100.9)'));
      });

      test('formats large values correctly', () {
        final pos = GraphPosition.fromXY(10000.1, 99999.9);

        final result = pos.toDebugString();

        expect(result, equals('GraphPosition(10000.1, 99999.9)'));
      });
    });
  });

  // ===========================================================================
  // ScreenPosition Tests
  // ===========================================================================

  group('ScreenPosition', () {
    group('construction', () {
      test('creates from Offset constructor', () {
        const pos = ScreenPosition(Offset(100, 200));

        expect(pos.dx, equals(100.0));
        expect(pos.dy, equals(200.0));
      });

      test('creates from fromXY factory', () {
        final pos = ScreenPosition.fromXY(150, 250);

        expect(pos.dx, equals(150.0));
        expect(pos.dy, equals(250.0));
      });

      test('zero constant is at origin', () {
        expect(ScreenPosition.zero.dx, equals(0.0));
        expect(ScreenPosition.zero.dy, equals(0.0));
      });

      test('offset property returns underlying Offset', () {
        final pos = ScreenPosition.fromXY(100, 200);

        expect(pos.offset, equals(const Offset(100, 200)));
      });
    });

    group('arithmetic operators', () {
      test('addition combines two positions', () {
        final pos1 = ScreenPosition.fromXY(100, 50);
        final pos2 = ScreenPosition.fromXY(25, 75);

        final result = pos1 + pos2;

        expect(result.dx, equals(125.0));
        expect(result.dy, equals(125.0));
      });

      test('subtraction finds difference between positions', () {
        final pos1 = ScreenPosition.fromXY(100, 80);
        final pos2 = ScreenPosition.fromXY(30, 20);

        final result = pos1 - pos2;

        expect(result.dx, equals(70.0));
        expect(result.dy, equals(60.0));
      });

      test('unary negation inverts position', () {
        final pos = ScreenPosition.fromXY(100, -50);

        final result = -pos;

        expect(result.dx, equals(-100.0));
        expect(result.dy, equals(50.0));
      });

      test('multiplication scales position', () {
        final pos = ScreenPosition.fromXY(50, 25);

        final result = pos * 3;

        expect(result.dx, equals(150.0));
        expect(result.dy, equals(75.0));
      });

      test('division scales position down', () {
        final pos = ScreenPosition.fromXY(100, 50);

        final result = pos / 2;

        expect(result.dx, equals(50.0));
        expect(result.dy, equals(25.0));
      });
    });

    group('isFinite', () {
      test('returns true for finite coordinates', () {
        final pos = ScreenPosition.fromXY(100, 200);

        expect(pos.isFinite, isTrue);
      });

      test('returns false for infinite values', () {
        const pos = ScreenPosition(Offset(double.infinity, 100));

        expect(pos.isFinite, isFalse);
      });
    });

    group('toDebugString', () {
      test('formats with one decimal place', () {
        final pos = ScreenPosition.fromXY(123.456, 789.012);

        final result = pos.toDebugString();

        expect(result, equals('ScreenPosition(123.5, 789.0)'));
      });

      test('formats zero correctly', () {
        final result = ScreenPosition.zero.toDebugString();

        expect(result, equals('ScreenPosition(0.0, 0.0)'));
      });

      test('formats negative values correctly', () {
        final pos = ScreenPosition.fromXY(-50.5, -100.9);

        final result = pos.toDebugString();

        expect(result, equals('ScreenPosition(-50.5, -100.9)'));
      });
    });
  });

  // ===========================================================================
  // GraphOffset Tests
  // ===========================================================================

  group('GraphOffset', () {
    group('construction', () {
      test('creates from Offset constructor', () {
        const offset = GraphOffset(Offset(10, 20));

        expect(offset.dx, equals(10.0));
        expect(offset.dy, equals(20.0));
      });

      test('creates from fromXY factory', () {
        final offset = GraphOffset.fromXY(15, 25);

        expect(offset.dx, equals(15.0));
        expect(offset.dy, equals(25.0));
      });

      test('zero constant is zero offset', () {
        expect(GraphOffset.zero.dx, equals(0.0));
        expect(GraphOffset.zero.dy, equals(0.0));
      });

      test('offset property returns underlying Offset', () {
        final offset = GraphOffset.fromXY(10, 20);

        expect(offset.offset, equals(const Offset(10, 20)));
      });
    });

    group('arithmetic operators', () {
      test('addition combines two offsets', () {
        final offset1 = GraphOffset.fromXY(10, 5);
        final offset2 = GraphOffset.fromXY(5, 10);

        final result = offset1 + offset2;

        expect(result.dx, equals(15.0));
        expect(result.dy, equals(15.0));
      });

      test('subtraction finds difference between offsets', () {
        final offset1 = GraphOffset.fromXY(30, 20);
        final offset2 = GraphOffset.fromXY(10, 5);

        final result = offset1 - offset2;

        expect(result.dx, equals(20.0));
        expect(result.dy, equals(15.0));
      });

      test('unary negation inverts offset', () {
        final offset = GraphOffset.fromXY(10, -5);

        final result = -offset;

        expect(result.dx, equals(-10.0));
        expect(result.dy, equals(5.0));
      });

      test('multiplication scales offset', () {
        final offset = GraphOffset.fromXY(5, 10);

        final result = offset * 4;

        expect(result.dx, equals(20.0));
        expect(result.dy, equals(40.0));
      });

      test('division scales offset down', () {
        final offset = GraphOffset.fromXY(20, 40);

        final result = offset / 4;

        expect(result.dx, equals(5.0));
        expect(result.dy, equals(10.0));
      });
    });

    group('distance property', () {
      test('calculates magnitude of offset', () {
        final offset = GraphOffset.fromXY(3, 4);

        expect(offset.distance, equals(5.0));
      });

      test('returns zero for zero offset', () {
        expect(GraphOffset.zero.distance, equals(0.0));
      });

      test('calculates correctly for negative values', () {
        final offset = GraphOffset.fromXY(-3, -4);

        expect(offset.distance, equals(5.0));
      });

      test('calculates correctly for mixed signs', () {
        final offset = GraphOffset.fromXY(-6, 8);

        expect(offset.distance, equals(10.0));
      });
    });

    group('isFinite', () {
      test('returns true for finite values', () {
        final offset = GraphOffset.fromXY(10, 20);

        expect(offset.isFinite, isTrue);
      });

      test('returns false for infinite values', () {
        const offset = GraphOffset(Offset(double.infinity, 10));

        expect(offset.isFinite, isFalse);
      });

      test('returns false for NaN', () {
        const offset = GraphOffset(Offset(10, double.nan));

        expect(offset.isFinite, isFalse);
      });
    });

    group('toDebugString', () {
      test('formats with one decimal place', () {
        final offset = GraphOffset.fromXY(12.34, 56.78);

        final result = offset.toDebugString();

        expect(result, equals('GraphOffset(12.3, 56.8)'));
      });

      test('formats zero correctly', () {
        final result = GraphOffset.zero.toDebugString();

        expect(result, equals('GraphOffset(0.0, 0.0)'));
      });

      test('formats negative values correctly', () {
        final offset = GraphOffset.fromXY(-5.5, -10.9);

        final result = offset.toDebugString();

        expect(result, equals('GraphOffset(-5.5, -10.9)'));
      });
    });
  });

  // ===========================================================================
  // ScreenOffset Tests
  // ===========================================================================

  group('ScreenOffset', () {
    group('construction', () {
      test('creates from Offset constructor', () {
        const offset = ScreenOffset(Offset(10, 20));

        expect(offset.dx, equals(10.0));
        expect(offset.dy, equals(20.0));
      });

      test('creates from fromXY factory', () {
        final offset = ScreenOffset.fromXY(15, 25);

        expect(offset.dx, equals(15.0));
        expect(offset.dy, equals(25.0));
      });

      test('zero constant is zero offset', () {
        expect(ScreenOffset.zero.dx, equals(0.0));
        expect(ScreenOffset.zero.dy, equals(0.0));
      });

      test('offset property returns underlying Offset', () {
        final offset = ScreenOffset.fromXY(10, 20);

        expect(offset.offset, equals(const Offset(10, 20)));
      });
    });

    group('arithmetic operators', () {
      test('addition combines two offsets', () {
        final offset1 = ScreenOffset.fromXY(10, 5);
        final offset2 = ScreenOffset.fromXY(5, 10);

        final result = offset1 + offset2;

        expect(result.dx, equals(15.0));
        expect(result.dy, equals(15.0));
      });

      test('subtraction finds difference between offsets', () {
        final offset1 = ScreenOffset.fromXY(30, 20);
        final offset2 = ScreenOffset.fromXY(10, 5);

        final result = offset1 - offset2;

        expect(result.dx, equals(20.0));
        expect(result.dy, equals(15.0));
      });

      test('unary negation inverts offset', () {
        final offset = ScreenOffset.fromXY(10, -5);

        final result = -offset;

        expect(result.dx, equals(-10.0));
        expect(result.dy, equals(5.0));
      });

      test('multiplication scales offset', () {
        final offset = ScreenOffset.fromXY(5, 10);

        final result = offset * 4;

        expect(result.dx, equals(20.0));
        expect(result.dy, equals(40.0));
      });

      test('division scales offset down', () {
        final offset = ScreenOffset.fromXY(20, 40);

        final result = offset / 4;

        expect(result.dx, equals(5.0));
        expect(result.dy, equals(10.0));
      });
    });

    group('distance property', () {
      test('calculates magnitude of offset in pixels', () {
        final offset = ScreenOffset.fromXY(6, 8);

        expect(offset.distance, equals(10.0));
      });

      test('returns zero for zero offset', () {
        expect(ScreenOffset.zero.distance, equals(0.0));
      });

      test('calculates correctly for negative values', () {
        final offset = ScreenOffset.fromXY(-5, 12);

        expect(offset.distance, equals(13.0));
      });
    });

    group('isFinite', () {
      test('returns true for finite values', () {
        final offset = ScreenOffset.fromXY(10, 20);

        expect(offset.isFinite, isTrue);
      });

      test('returns false for infinite values', () {
        const offset = ScreenOffset(Offset(double.negativeInfinity, 10));

        expect(offset.isFinite, isFalse);
      });
    });

    group('toDebugString', () {
      test('formats with one decimal place', () {
        final offset = ScreenOffset.fromXY(12.34, 56.78);

        final result = offset.toDebugString();

        expect(result, equals('ScreenOffset(12.3, 56.8)'));
      });

      test('formats zero correctly', () {
        final result = ScreenOffset.zero.toDebugString();

        expect(result, equals('ScreenOffset(0.0, 0.0)'));
      });
    });
  });

  // ===========================================================================
  // GraphPositionOffsetExtension Tests
  // ===========================================================================

  group('GraphPositionOffsetExtension', () {
    group('translate', () {
      test('translates position by positive offset', () {
        final pos = GraphPosition.fromXY(100, 100);
        final offset = GraphOffset.fromXY(25, 50);

        final result = pos.translate(offset);

        expect(result.dx, equals(125.0));
        expect(result.dy, equals(150.0));
      });

      test('translates position by negative offset', () {
        final pos = GraphPosition.fromXY(100, 100);
        final offset = GraphOffset.fromXY(-30, -20);

        final result = pos.translate(offset);

        expect(result.dx, equals(70.0));
        expect(result.dy, equals(80.0));
      });

      test('translates by zero offset returns same position', () {
        final pos = GraphPosition.fromXY(100, 200);

        final result = pos.translate(GraphOffset.zero);

        expect(result.dx, equals(100.0));
        expect(result.dy, equals(200.0));
      });

      test('translates zero position', () {
        final offset = GraphOffset.fromXY(50, 75);

        final result = GraphPosition.zero.translate(offset);

        expect(result.dx, equals(50.0));
        expect(result.dy, equals(75.0));
      });

      test('chained translations work correctly', () {
        final pos = GraphPosition.fromXY(0, 0);
        final offset1 = GraphOffset.fromXY(10, 20);
        final offset2 = GraphOffset.fromXY(30, 40);

        final result = pos.translate(offset1).translate(offset2);

        expect(result.dx, equals(40.0));
        expect(result.dy, equals(60.0));
      });
    });
  });

  // ===========================================================================
  // ScreenPositionOffsetExtension Tests
  // ===========================================================================

  group('ScreenPositionOffsetExtension', () {
    group('translate', () {
      test('translates position by positive offset', () {
        final pos = ScreenPosition.fromXY(200, 150);
        final offset = ScreenOffset.fromXY(50, 100);

        final result = pos.translate(offset);

        expect(result.dx, equals(250.0));
        expect(result.dy, equals(250.0));
      });

      test('translates position by negative offset', () {
        final pos = ScreenPosition.fromXY(200, 150);
        final offset = ScreenOffset.fromXY(-75, -50);

        final result = pos.translate(offset);

        expect(result.dx, equals(125.0));
        expect(result.dy, equals(100.0));
      });

      test('translates by zero offset returns same position', () {
        final pos = ScreenPosition.fromXY(300, 400);

        final result = pos.translate(ScreenOffset.zero);

        expect(result.dx, equals(300.0));
        expect(result.dy, equals(400.0));
      });

      test('translates zero position', () {
        final offset = ScreenOffset.fromXY(100, 200);

        final result = ScreenPosition.zero.translate(offset);

        expect(result.dx, equals(100.0));
        expect(result.dy, equals(200.0));
      });
    });
  });

  // ===========================================================================
  // GraphRect Tests
  // ===========================================================================

  group('GraphRect', () {
    group('construction', () {
      test('creates from Rect constructor', () {
        const rect = GraphRect(Rect.fromLTWH(10, 20, 100, 50));

        expect(rect.left, equals(10.0));
        expect(rect.top, equals(20.0));
        expect(rect.width, equals(100.0));
        expect(rect.height, equals(50.0));
      });

      test('creates from fromLTWH factory', () {
        final rect = GraphRect.fromLTWH(10, 20, 100, 50);

        expect(rect.left, equals(10.0));
        expect(rect.top, equals(20.0));
        expect(rect.width, equals(100.0));
        expect(rect.height, equals(50.0));
      });

      test('creates from fromPoints factory', () {
        final rect = GraphRect.fromPoints(
          GraphPosition.fromXY(10, 20),
          GraphPosition.fromXY(110, 70),
        );

        expect(rect.left, equals(10.0));
        expect(rect.top, equals(20.0));
        expect(rect.right, equals(110.0));
        expect(rect.bottom, equals(70.0));
      });

      test('creates from fromPoints with reversed points', () {
        final rect = GraphRect.fromPoints(
          GraphPosition.fromXY(110, 70),
          GraphPosition.fromXY(10, 20),
        );

        expect(rect.left, equals(10.0));
        expect(rect.top, equals(20.0));
        expect(rect.right, equals(110.0));
        expect(rect.bottom, equals(70.0));
      });

      test('creates from fromCenter factory', () {
        final rect = GraphRect.fromCenter(
          center: GraphPosition.fromXY(100, 100),
          width: 50,
          height: 30,
        );

        expect(rect.left, equals(75.0));
        expect(rect.top, equals(85.0));
        expect(rect.width, equals(50.0));
        expect(rect.height, equals(30.0));
        expect(rect.center.dx, equals(100.0));
        expect(rect.center.dy, equals(100.0));
      });

      test('zero constant is empty at origin', () {
        expect(GraphRect.zero.left, equals(0.0));
        expect(GraphRect.zero.top, equals(0.0));
        expect(GraphRect.zero.width, equals(0.0));
        expect(GraphRect.zero.height, equals(0.0));
        expect(GraphRect.zero.isEmpty, isTrue);
      });
    });

    group('corner accessors', () {
      test('topLeft returns top-left corner position', () {
        final rect = GraphRect.fromLTWH(100, 50, 200, 150);

        expect(rect.topLeft.dx, equals(100.0));
        expect(rect.topLeft.dy, equals(50.0));
      });

      test('topRight returns top-right corner position', () {
        final rect = GraphRect.fromLTWH(100, 50, 200, 150);

        expect(rect.topRight.dx, equals(300.0));
        expect(rect.topRight.dy, equals(50.0));
      });

      test('bottomLeft returns bottom-left corner position', () {
        final rect = GraphRect.fromLTWH(100, 50, 200, 150);

        expect(rect.bottomLeft.dx, equals(100.0));
        expect(rect.bottomLeft.dy, equals(200.0));
      });

      test('bottomRight returns bottom-right corner position', () {
        final rect = GraphRect.fromLTWH(100, 50, 200, 150);

        expect(rect.bottomRight.dx, equals(300.0));
        expect(rect.bottomRight.dy, equals(200.0));
      });

      test('center returns center position', () {
        final rect = GraphRect.fromLTWH(100, 50, 200, 100);

        expect(rect.center.dx, equals(200.0));
        expect(rect.center.dy, equals(100.0));
      });
    });

    group('edge accessors', () {
      test('left returns left edge x-coordinate', () {
        final rect = GraphRect.fromLTWH(100, 50, 200, 150);

        expect(rect.left, equals(100.0));
      });

      test('top returns top edge y-coordinate', () {
        final rect = GraphRect.fromLTWH(100, 50, 200, 150);

        expect(rect.top, equals(50.0));
      });

      test('right returns right edge x-coordinate', () {
        final rect = GraphRect.fromLTWH(100, 50, 200, 150);

        expect(rect.right, equals(300.0));
      });

      test('bottom returns bottom edge y-coordinate', () {
        final rect = GraphRect.fromLTWH(100, 50, 200, 150);

        expect(rect.bottom, equals(200.0));
      });
    });

    group('size accessors', () {
      test('width returns rectangle width', () {
        final rect = GraphRect.fromLTWH(0, 0, 150, 100);

        expect(rect.width, equals(150.0));
      });

      test('height returns rectangle height', () {
        final rect = GraphRect.fromLTWH(0, 0, 150, 100);

        expect(rect.height, equals(100.0));
      });

      test('size returns Size object', () {
        final rect = GraphRect.fromLTWH(0, 0, 150, 100);

        expect(rect.size, equals(const Size(150, 100)));
      });
    });

    group('isEmpty and isFinite', () {
      test('isEmpty returns true for zero-size rectangle', () {
        final rect = GraphRect.fromLTWH(100, 100, 0, 0);

        expect(rect.isEmpty, isTrue);
      });

      test('isEmpty returns false for non-zero rectangle', () {
        final rect = GraphRect.fromLTWH(100, 100, 50, 50);

        expect(rect.isEmpty, isFalse);
      });

      test('isEmpty returns true for zero-width rectangle', () {
        final rect = GraphRect.fromLTWH(100, 100, 0, 50);

        expect(rect.isEmpty, isTrue);
      });

      test('isEmpty returns true for zero-height rectangle', () {
        final rect = GraphRect.fromLTWH(100, 100, 50, 0);

        expect(rect.isEmpty, isTrue);
      });

      test('isFinite returns true for finite rectangle', () {
        final rect = GraphRect.fromLTWH(100, 100, 50, 50);

        expect(rect.isFinite, isTrue);
      });

      test('isFinite returns false for infinite rectangle', () {
        const rect = GraphRect(Rect.fromLTWH(0, 0, double.infinity, 100));

        expect(rect.isFinite, isFalse);
      });
    });

    group('contains', () {
      test('returns true for point inside rectangle', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);
        final point = GraphPosition.fromXY(150, 150);

        expect(rect.contains(point), isTrue);
      });

      test('returns false for point outside rectangle', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);
        final point = GraphPosition.fromXY(50, 50);

        expect(rect.contains(point), isFalse);
      });

      test('returns true for point on edge', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);
        final point = GraphPosition.fromXY(100, 150);

        expect(rect.contains(point), isTrue);
      });

      test('returns true for point at corner', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);
        final point = GraphPosition.fromXY(100, 100);

        expect(rect.contains(point), isTrue);
      });

      test('returns false for point just outside', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);
        final point = GraphPosition.fromXY(201, 150);

        expect(rect.contains(point), isFalse);
      });
    });

    group('overlaps', () {
      test('returns true for overlapping rectangles', () {
        final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
        final rect2 = GraphRect.fromLTWH(50, 50, 100, 100);

        expect(rect1.overlaps(rect2), isTrue);
      });

      test('returns false for non-overlapping rectangles', () {
        final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
        final rect2 = GraphRect.fromLTWH(200, 200, 100, 100);

        expect(rect1.overlaps(rect2), isFalse);
      });

      test('returns false for adjacent rectangles (touching edge)', () {
        final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
        final rect2 = GraphRect.fromLTWH(100, 0, 100, 100);

        expect(rect1.overlaps(rect2), isFalse);
      });

      test('returns true when one rect contains another', () {
        final outer = GraphRect.fromLTWH(0, 0, 200, 200);
        final inner = GraphRect.fromLTWH(50, 50, 50, 50);

        expect(outer.overlaps(inner), isTrue);
        expect(inner.overlaps(outer), isTrue);
      });
    });

    group('intersect', () {
      test('returns intersection of overlapping rectangles', () {
        final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
        final rect2 = GraphRect.fromLTWH(50, 50, 100, 100);

        final intersection = rect1.intersect(rect2);

        expect(intersection.left, equals(50.0));
        expect(intersection.top, equals(50.0));
        expect(intersection.right, equals(100.0));
        expect(intersection.bottom, equals(100.0));
      });

      test('returns empty rectangle for non-overlapping rectangles', () {
        final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
        final rect2 = GraphRect.fromLTWH(200, 200, 100, 100);

        final intersection = rect1.intersect(rect2);

        expect(intersection.isEmpty, isTrue);
      });
    });

    group('expandToInclude', () {
      test('expands to include separate rectangle', () {
        final rect1 = GraphRect.fromLTWH(0, 0, 50, 50);
        final rect2 = GraphRect.fromLTWH(100, 100, 50, 50);

        final expanded = rect1.expandToInclude(rect2);

        expect(expanded.left, equals(0.0));
        expect(expanded.top, equals(0.0));
        expect(expanded.right, equals(150.0));
        expect(expanded.bottom, equals(150.0));
      });

      test('expands to include overlapping rectangle', () {
        final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
        final rect2 = GraphRect.fromLTWH(50, 50, 100, 100);

        final expanded = rect1.expandToInclude(rect2);

        expect(expanded.left, equals(0.0));
        expect(expanded.top, equals(0.0));
        expect(expanded.right, equals(150.0));
        expect(expanded.bottom, equals(150.0));
      });

      test('returns outer when inner is fully contained', () {
        final outer = GraphRect.fromLTWH(0, 0, 200, 200);
        final inner = GraphRect.fromLTWH(50, 50, 50, 50);

        final expanded = outer.expandToInclude(inner);

        expect(expanded.left, equals(0.0));
        expect(expanded.top, equals(0.0));
        expect(expanded.right, equals(200.0));
        expect(expanded.bottom, equals(200.0));
      });
    });

    group('inflate', () {
      test('expands rectangle by positive delta', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);

        final inflated = rect.inflate(10);

        expect(inflated.left, equals(90.0));
        expect(inflated.top, equals(90.0));
        expect(inflated.right, equals(210.0));
        expect(inflated.bottom, equals(210.0));
      });

      test('inflate by zero returns same rectangle', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);

        final inflated = rect.inflate(0);

        expect(inflated.left, equals(100.0));
        expect(inflated.top, equals(100.0));
        expect(inflated.width, equals(100.0));
        expect(inflated.height, equals(100.0));
      });

      test('negative inflate shrinks rectangle (like deflate)', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);

        final inflated = rect.inflate(-10);

        expect(inflated.left, equals(110.0));
        expect(inflated.top, equals(110.0));
        expect(inflated.width, equals(80.0));
        expect(inflated.height, equals(80.0));
      });
    });

    group('deflate', () {
      test('shrinks rectangle by positive delta', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);

        final deflated = rect.deflate(10);

        expect(deflated.left, equals(110.0));
        expect(deflated.top, equals(110.0));
        expect(deflated.width, equals(80.0));
        expect(deflated.height, equals(80.0));
      });

      test('deflate by zero returns same rectangle', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);

        final deflated = rect.deflate(0);

        expect(deflated.left, equals(100.0));
        expect(deflated.top, equals(100.0));
        expect(deflated.width, equals(100.0));
        expect(deflated.height, equals(100.0));
      });

      test('negative deflate expands rectangle (like inflate)', () {
        final rect = GraphRect.fromLTWH(100, 100, 100, 100);

        final deflated = rect.deflate(-10);

        expect(deflated.left, equals(90.0));
        expect(deflated.top, equals(90.0));
        expect(deflated.width, equals(120.0));
        expect(deflated.height, equals(120.0));
      });
    });

    group('translate', () {
      test('moves rectangle by positive offset', () {
        final rect = GraphRect.fromLTWH(100, 100, 50, 50);
        final offset = GraphOffset.fromXY(25, 30);

        final translated = rect.translate(offset);

        expect(translated.left, equals(125.0));
        expect(translated.top, equals(130.0));
        expect(translated.width, equals(50.0));
        expect(translated.height, equals(50.0));
      });

      test('moves rectangle by negative offset', () {
        final rect = GraphRect.fromLTWH(100, 100, 50, 50);
        final offset = GraphOffset.fromXY(-20, -15);

        final translated = rect.translate(offset);

        expect(translated.left, equals(80.0));
        expect(translated.top, equals(85.0));
      });

      test('translate by zero returns same position', () {
        final rect = GraphRect.fromLTWH(100, 100, 50, 50);

        final translated = rect.translate(GraphOffset.zero);

        expect(translated.left, equals(100.0));
        expect(translated.top, equals(100.0));
      });
    });

    group('shift', () {
      test('shifts rectangle by position offset', () {
        final rect = GraphRect.fromLTWH(100, 100, 50, 50);
        final position = GraphPosition.fromXY(25, 30);

        final shifted = rect.shift(position);

        expect(shifted.left, equals(125.0));
        expect(shifted.top, equals(130.0));
        expect(shifted.width, equals(50.0));
        expect(shifted.height, equals(50.0));
      });

      test('shifts rectangle by negative position', () {
        final rect = GraphRect.fromLTWH(100, 100, 50, 50);
        final position = GraphPosition.fromXY(-20, -15);

        final shifted = rect.shift(position);

        expect(shifted.left, equals(80.0));
        expect(shifted.top, equals(85.0));
      });

      test('shift by zero returns same position', () {
        final rect = GraphRect.fromLTWH(100, 100, 50, 50);

        final shifted = rect.shift(GraphPosition.zero);

        expect(shifted.left, equals(100.0));
        expect(shifted.top, equals(100.0));
      });
    });

    group('toDebugString', () {
      test('formats with one decimal place', () {
        final rect = GraphRect.fromLTWH(10.5, 20.5, 100.3, 50.7);

        final result = rect.toDebugString();

        expect(result, equals('GraphRect(10.5, 20.5, 100.3, 50.7)'));
      });

      test('formats zero rectangle', () {
        final result = GraphRect.zero.toDebugString();

        expect(result, equals('GraphRect(0.0, 0.0, 0.0, 0.0)'));
      });

      test('formats negative position', () {
        final rect = GraphRect.fromLTWH(-50.0, -25.0, 100.0, 75.0);

        final result = rect.toDebugString();

        expect(result, equals('GraphRect(-50.0, -25.0, 100.0, 75.0)'));
      });
    });
  });

  // ===========================================================================
  // ScreenRect Tests
  // ===========================================================================

  group('ScreenRect', () {
    group('construction', () {
      test('creates from Rect constructor', () {
        const rect = ScreenRect(Rect.fromLTWH(10, 20, 100, 50));

        expect(rect.left, equals(10.0));
        expect(rect.top, equals(20.0));
        expect(rect.width, equals(100.0));
        expect(rect.height, equals(50.0));
      });

      test('creates from fromLTWH factory', () {
        final rect = ScreenRect.fromLTWH(10, 20, 100, 50);

        expect(rect.left, equals(10.0));
        expect(rect.top, equals(20.0));
        expect(rect.width, equals(100.0));
        expect(rect.height, equals(50.0));
      });

      test('creates from fromPoints factory', () {
        final rect = ScreenRect.fromPoints(
          ScreenPosition.fromXY(10, 20),
          ScreenPosition.fromXY(110, 70),
        );

        expect(rect.left, equals(10.0));
        expect(rect.top, equals(20.0));
        expect(rect.right, equals(110.0));
        expect(rect.bottom, equals(70.0));
      });

      test('zero constant is empty at origin', () {
        expect(ScreenRect.zero.left, equals(0.0));
        expect(ScreenRect.zero.top, equals(0.0));
        expect(ScreenRect.zero.width, equals(0.0));
        expect(ScreenRect.zero.height, equals(0.0));
      });
    });

    group('accessors', () {
      test('topLeft returns top-left corner position', () {
        final rect = ScreenRect.fromLTWH(100, 50, 200, 150);

        expect(rect.topLeft.dx, equals(100.0));
        expect(rect.topLeft.dy, equals(50.0));
      });

      test('center returns center position', () {
        final rect = ScreenRect.fromLTWH(100, 50, 200, 100);

        expect(rect.center.dx, equals(200.0));
        expect(rect.center.dy, equals(100.0));
      });

      test('edge accessors return correct values', () {
        final rect = ScreenRect.fromLTWH(100, 50, 200, 150);

        expect(rect.left, equals(100.0));
        expect(rect.top, equals(50.0));
        expect(rect.right, equals(300.0));
        expect(rect.bottom, equals(200.0));
      });

      test('size returns Size object', () {
        final rect = ScreenRect.fromLTWH(0, 0, 150, 100);

        expect(rect.size, equals(const Size(150, 100)));
      });
    });

    group('contains', () {
      test('returns true for point inside rectangle', () {
        final rect = ScreenRect.fromLTWH(100, 100, 100, 100);
        final point = ScreenPosition.fromXY(150, 150);

        expect(rect.contains(point), isTrue);
      });

      test('returns false for point outside rectangle', () {
        final rect = ScreenRect.fromLTWH(100, 100, 100, 100);
        final point = ScreenPosition.fromXY(50, 50);

        expect(rect.contains(point), isFalse);
      });

      test('returns true for point on edge', () {
        final rect = ScreenRect.fromLTWH(100, 100, 100, 100);
        final point = ScreenPosition.fromXY(100, 150);

        expect(rect.contains(point), isTrue);
      });
    });

    group('overlaps', () {
      test('returns true for overlapping rectangles', () {
        final rect1 = ScreenRect.fromLTWH(0, 0, 100, 100);
        final rect2 = ScreenRect.fromLTWH(50, 50, 100, 100);

        expect(rect1.overlaps(rect2), isTrue);
      });

      test('returns false for non-overlapping rectangles', () {
        final rect1 = ScreenRect.fromLTWH(0, 0, 100, 100);
        final rect2 = ScreenRect.fromLTWH(200, 200, 100, 100);

        expect(rect1.overlaps(rect2), isFalse);
      });
    });

    group('toDebugString', () {
      test('formats with one decimal place', () {
        final rect = ScreenRect.fromLTWH(10.5, 20.5, 100.3, 50.7);

        final result = rect.toDebugString();

        expect(result, equals('ScreenRect(10.5, 20.5, 100.3, 50.7)'));
      });

      test('formats zero rectangle', () {
        final result = ScreenRect.zero.toDebugString();

        expect(result, equals('ScreenRect(0.0, 0.0, 0.0, 0.0)'));
      });

      test('formats large values', () {
        final rect = ScreenRect.fromLTWH(1000.0, 2000.0, 500.0, 300.0);

        final result = rect.toDebugString();

        expect(result, equals('ScreenRect(1000.0, 2000.0, 500.0, 300.0)'));
      });
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    group('extreme values', () {
      test('very large position values', () {
        final pos = GraphPosition.fromXY(1e15, 1e15);

        expect(pos.dx, equals(1e15));
        expect(pos.dy, equals(1e15));
        expect(pos.isFinite, isTrue);
      });

      test('very small position values', () {
        final pos = GraphPosition.fromXY(1e-15, 1e-15);

        expect(pos.dx, closeTo(1e-15, 1e-20));
        expect(pos.dy, closeTo(1e-15, 1e-20));
        expect(pos.isFinite, isTrue);
      });

      test('mixed extreme values', () {
        final pos = GraphPosition.fromXY(-1e10, 1e10);

        expect(pos.dx, equals(-1e10));
        expect(pos.dy, equals(1e10));
      });

      test('very small offset distance is calculated correctly', () {
        final offset = GraphOffset.fromXY(0.001, 0.001);

        expect(offset.distance, closeTo(0.001414, 0.0001));
      });

      test('large rectangle dimensions', () {
        final rect = GraphRect.fromLTWH(0, 0, 1e10, 1e10);

        expect(rect.width, equals(1e10));
        expect(rect.height, equals(1e10));
        expect(rect.isFinite, isTrue);
      });
    });

    group('negative coordinates', () {
      test('position in negative quadrant', () {
        final pos = GraphPosition.fromXY(-500, -300);

        expect(pos.dx, equals(-500.0));
        expect(pos.dy, equals(-300.0));
      });

      test('rectangle with negative position', () {
        final rect = GraphRect.fromLTWH(-100, -50, 200, 100);

        expect(rect.left, equals(-100.0));
        expect(rect.top, equals(-50.0));
        expect(rect.right, equals(100.0));
        expect(rect.bottom, equals(50.0));
      });

      test('negative position distance calculation', () {
        final pos1 = GraphPosition.fromXY(-10, -10);
        final pos2 = GraphPosition.fromXY(10, 10);

        // Distance = sqrt(20^2 + 20^2) = sqrt(800)
        expect(pos1.distanceTo(pos2), closeTo(28.28, 0.01));
      });
    });

    group('special floating point values', () {
      test('position with infinity', () {
        const pos = GraphPosition(Offset(double.infinity, 100));

        expect(pos.isFinite, isFalse);
        expect(pos.dx, equals(double.infinity));
      });

      test('position with negative infinity', () {
        const pos = GraphPosition(Offset(double.negativeInfinity, 100));

        expect(pos.isFinite, isFalse);
        expect(pos.dx, equals(double.negativeInfinity));
      });

      test('position with NaN', () {
        const pos = GraphPosition(Offset(double.nan, 100));

        expect(pos.isFinite, isFalse);
        expect(pos.dx.isNaN, isTrue);
      });

      test('offset with infinity', () {
        const offset = GraphOffset(Offset(double.infinity, 0));

        expect(offset.isFinite, isFalse);
      });
    });

    group('identity operations', () {
      test('adding zero position', () {
        final pos = GraphPosition.fromXY(100, 200);

        final result = pos + GraphPosition.zero;

        expect(result.dx, equals(100.0));
        expect(result.dy, equals(200.0));
      });

      test('subtracting zero position', () {
        final pos = GraphPosition.fromXY(100, 200);

        final result = pos - GraphPosition.zero;

        expect(result.dx, equals(100.0));
        expect(result.dy, equals(200.0));
      });

      test('multiplying by one', () {
        final pos = GraphPosition.fromXY(100, 200);

        final result = pos * 1;

        expect(result.dx, equals(100.0));
        expect(result.dy, equals(200.0));
      });

      test('dividing by one', () {
        final pos = GraphPosition.fromXY(100, 200);

        final result = pos / 1;

        expect(result.dx, equals(100.0));
        expect(result.dy, equals(200.0));
      });
    });

    group('rect property access', () {
      test('GraphRect rect property returns underlying Rect', () {
        final graphRect = GraphRect.fromLTWH(10, 20, 100, 50);

        expect(graphRect.rect, equals(const Rect.fromLTWH(10, 20, 100, 50)));
      });

      test('ScreenRect rect property returns underlying Rect', () {
        final screenRect = ScreenRect.fromLTWH(10, 20, 100, 50);

        expect(screenRect.rect, equals(const Rect.fromLTWH(10, 20, 100, 50)));
      });
    });
  });

  // ===========================================================================
  // Coordinate System Interoperability
  // ===========================================================================

  group('Coordinate System Interoperability', () {
    test('GraphPosition and ScreenPosition have same underlying structure', () {
      final graphPos = GraphPosition.fromXY(100, 200);
      final screenPos = ScreenPosition.fromXY(100, 200);

      expect(graphPos.offset, equals(screenPos.offset));
    });

    test('GraphOffset and ScreenOffset have same underlying structure', () {
      final graphOffset = GraphOffset.fromXY(50, 75);
      final screenOffset = ScreenOffset.fromXY(50, 75);

      expect(graphOffset.offset, equals(screenOffset.offset));
    });

    test('GraphRect and ScreenRect have same underlying structure', () {
      final graphRect = GraphRect.fromLTWH(10, 20, 100, 50);
      final screenRect = ScreenRect.fromLTWH(10, 20, 100, 50);

      expect(graphRect.rect, equals(screenRect.rect));
    });

    test('type safety prevents mixing coordinate types accidentally', () {
      // This test documents that the extension types provide type safety
      // The following would cause compile errors:
      // GraphPosition pos = ScreenPosition.fromXY(100, 200); // Error!
      // GraphOffset offset = ScreenOffset.fromXY(10, 20); // Error!

      // But we can explicitly convert by accessing the underlying offset
      final screenPos = ScreenPosition.fromXY(100, 200);
      final graphPosFromScreen = GraphPosition(screenPos.offset);

      expect(graphPosFromScreen.dx, equals(100.0));
      expect(graphPosFromScreen.dy, equals(200.0));
    });
  });
}
