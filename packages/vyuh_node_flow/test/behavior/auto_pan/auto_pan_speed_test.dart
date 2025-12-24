@Tags(['behavior'])
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('Auto-Pan Speed - Preset Configurations', () {
    test('normal preset pan amount is 10 graph units', () {
      const config = AutoPanConfig.normal;
      expect(config.panAmount, equals(10.0));
    });

    test('fast preset pan amount is 20 graph units', () {
      const config = AutoPanConfig.fast;
      expect(config.panAmount, equals(20.0));
    });

    test('precise preset pan amount is 5 graph units', () {
      const config = AutoPanConfig.precise;
      expect(config.panAmount, equals(5.0));
    });

    test('normal preset interval is ~60fps (16ms)', () {
      const config = AutoPanConfig.normal;
      expect(config.panInterval, equals(const Duration(milliseconds: 16)));
    });

    test('fast preset interval is ~83fps (12ms)', () {
      const config = AutoPanConfig.fast;
      expect(config.panInterval, equals(const Duration(milliseconds: 12)));
    });

    test('precise preset interval is ~50fps (20ms)', () {
      const config = AutoPanConfig.precise;
      expect(config.panInterval, equals(const Duration(milliseconds: 20)));
    });
  });

  group('Auto-Pan Speed - Effective Speed Calculation', () {
    test('normal preset speed: 10 units * 60 ticks/sec = 600 units/sec', () {
      const config = AutoPanConfig.normal;
      final ticksPerSecond = 1000 / config.panInterval.inMilliseconds;
      final unitsPerSecond = config.panAmount * ticksPerSecond;

      expect(ticksPerSecond, closeTo(62.5, 0.1)); // 1000/16
      expect(unitsPerSecond, closeTo(625, 5)); // 10 * 62.5
    });

    test('fast preset speed: 20 units * 83 ticks/sec ≈ 1667 units/sec', () {
      const config = AutoPanConfig.fast;
      final ticksPerSecond = 1000 / config.panInterval.inMilliseconds;
      final unitsPerSecond = config.panAmount * ticksPerSecond;

      expect(ticksPerSecond, closeTo(83.3, 0.1)); // 1000/12
      expect(unitsPerSecond, closeTo(1666.7, 5)); // 20 * 83.3
    });

    test('precise preset speed: 5 units * 50 ticks/sec = 250 units/sec', () {
      const config = AutoPanConfig.precise;
      final ticksPerSecond = 1000 / config.panInterval.inMilliseconds;
      final unitsPerSecond = config.panAmount * ticksPerSecond;

      expect(ticksPerSecond, equals(50.0)); // 1000/20
      expect(unitsPerSecond, equals(250.0)); // 5 * 50
    });
  });

  group('Auto-Pan Speed - Proximity Scaling', () {
    test('without proximity scaling, speed is constant', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: false);

      // At different proximities, the result should be the same
      final atBoundary = config.calculatePanAmount(0.0, edgePaddingValue: 50.0);
      final atMiddle = config.calculatePanAmount(25.0, edgePaddingValue: 50.0);
      final atEdge = config.calculatePanAmount(50.0, edgePaddingValue: 50.0);

      expect(atBoundary, equals(10.0));
      expect(atMiddle, equals(10.0));
      expect(atEdge, equals(10.0));
    });

    test('with proximity scaling, speed varies from 0.3x to 1.5x', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: true);

      // At zone boundary (proximity = 0): 0.3x = 3.0
      final atBoundary = config.calculatePanAmount(0.0, edgePaddingValue: 50.0);
      expect(atBoundary, closeTo(3.0, 0.01));

      // At viewport edge (proximity = padding): 1.5x = 15.0
      final atEdge = config.calculatePanAmount(50.0, edgePaddingValue: 50.0);
      expect(atEdge, closeTo(15.0, 0.01));
    });

    test('proximity scaling with linear curve', () {
      const config = AutoPanConfig(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.linear,
      );

      // Linear interpolation from 0.3x to 1.5x
      // At 25% proximity: 0.3 + 0.25 * 1.2 = 0.6 → 6.0
      final at25Percent = config.calculatePanAmount(
        12.5,
        edgePaddingValue: 50.0,
      );
      expect(at25Percent, closeTo(6.0, 0.1));

      // At 50% proximity: 0.3 + 0.5 * 1.2 = 0.9 → 9.0
      final at50Percent = config.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );
      expect(at50Percent, closeTo(9.0, 0.1));

      // At 75% proximity: 0.3 + 0.75 * 1.2 = 1.2 → 12.0
      final at75Percent = config.calculatePanAmount(
        37.5,
        edgePaddingValue: 50.0,
      );
      expect(at75Percent, closeTo(12.0, 0.1));
    });

    test('proximity scaling with easeIn curve (slow start)', () {
      const config = AutoPanConfig(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.easeIn,
      );

      // easeIn starts slow and accelerates
      final atMiddle = config.calculatePanAmount(25.0, edgePaddingValue: 50.0);

      // With linear, midpoint would be 9.0
      // With easeIn, it should be less (slower start)
      expect(atMiddle, lessThan(9.0));

      // But still progressing
      expect(atMiddle, greaterThan(3.0));
    });

    test('proximity scaling with easeOut curve (fast start)', () {
      const config = AutoPanConfig(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.easeOut,
      );

      // easeOut starts fast and decelerates
      final atMiddle = config.calculatePanAmount(25.0, edgePaddingValue: 50.0);

      // With linear, midpoint would be 9.0
      // With easeOut, it should be more (faster start)
      expect(atMiddle, greaterThan(9.0));

      // But not at maximum yet
      expect(atMiddle, lessThan(15.0));
    });

    test('proximity scaling with easeInOut curve', () {
      const config = AutoPanConfig(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.easeInOut,
      );

      // easeInOut: slow start, fast middle, slow end
      final atMiddle = config.calculatePanAmount(25.0, edgePaddingValue: 50.0);

      // At midpoint, easeInOut should be around linear value
      expect(atMiddle, closeTo(9.0, 1.0));
    });
  });

  group('Auto-Pan Speed - Minimum and Maximum', () {
    test('minimum speed is 0.3x base (at zone boundary)', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: true);

      final minSpeed = config.calculatePanAmount(0.0, edgePaddingValue: 50.0);
      expect(minSpeed, closeTo(3.0, 0.01)); // 0.3 * 10
    });

    test('maximum speed is 1.5x base (at viewport edge)', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: true);

      final maxSpeed = config.calculatePanAmount(50.0, edgePaddingValue: 50.0);
      expect(maxSpeed, closeTo(15.0, 0.01)); // 1.5 * 10
    });

    test('speed beyond edge padding clamps to maximum', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: true);

      // Proximity exceeds edge padding (pointer outside bounds)
      final beyondMax = config.calculatePanAmount(
        100.0,
        edgePaddingValue: 50.0,
      );
      expect(beyondMax, closeTo(15.0, 0.01)); // Clamped to max
    });

    test('negative proximity clamps to minimum', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: true);

      // Negative proximity (shouldn't happen but handled)
      final negative = config.calculatePanAmount(-10.0, edgePaddingValue: 50.0);
      expect(negative, closeTo(3.0, 0.01)); // Clamped to min
    });
  });

  group('Auto-Pan Speed - Per-Edge Asymmetry', () {
    test('different edges can have different pan zones', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.only(
          left: 30.0, // narrow zone
          right: 80.0, // wide zone
          top: 50.0,
          bottom: 50.0,
        ),
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // Same absolute proximity (15px into zone)
      // but different normalized proximity based on zone width
      final inLeftZone = config.calculatePanAmount(
        15.0,
        edgePaddingValue: config.edgePadding.left,
      );

      final inRightZone = config.calculatePanAmount(
        15.0,
        edgePaddingValue: config.edgePadding.right,
      );

      // 15px in 30px zone = 50% → speed ~9.0
      expect(inLeftZone, closeTo(9.0, 0.5));

      // 15px in 80px zone = 18.75% → speed ~5.25
      expect(inRightZone, closeTo(5.25, 0.5));

      // Different speeds for same absolute distance
      expect(inLeftZone, greaterThan(inRightZone));
    });

    test('wider zone provides more precision at edges', () {
      const narrowConfig = AutoPanConfig(
        edgePadding: EdgeInsets.all(30.0),
        panAmount: 10.0,
        useProximityScaling: true,
      );

      const wideConfig = AutoPanConfig(
        edgePadding: EdgeInsets.all(100.0),
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // 10px from viewport edge
      // In narrow zone: 10/30 = 33% from edge
      // In wide zone: 10/100 = 10% from edge
      final narrowSpeed = narrowConfig.calculatePanAmount(
        30.0 - 10.0,
        edgePaddingValue: 30.0,
      );

      final wideSpeed = wideConfig.calculatePanAmount(
        100.0 - 10.0,
        edgePaddingValue: 100.0,
      );

      // Narrow zone: 20/30 = 0.67 → 0.3 + 0.67 * 1.2 = 1.1 → 11.0
      // Wide zone: 90/100 = 0.9 → 0.3 + 0.9 * 1.2 = 1.38 → 13.8
      expect(narrowSpeed, closeTo(11.0, 0.5));
      expect(wideSpeed, closeTo(13.8, 0.5));
    });
  });

  group('Auto-Pan Speed - Edge Cases', () {
    test('zero edge padding returns base pan amount', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: true);

      final result = config.calculatePanAmount(25.0, edgePaddingValue: 0.0);
      expect(result, equals(10.0));
    });

    test('very small pan amount still works', () {
      const config = AutoPanConfig(panAmount: 0.1, useProximityScaling: true);

      final atEdge = config.calculatePanAmount(50.0, edgePaddingValue: 50.0);
      expect(atEdge, closeTo(0.15, 0.01)); // 0.1 * 1.5
    });

    test('very large pan amount still works', () {
      const config = AutoPanConfig(
        panAmount: 1000.0,
        useProximityScaling: true,
      );

      final atEdge = config.calculatePanAmount(50.0, edgePaddingValue: 50.0);
      expect(atEdge, closeTo(1500.0, 1.0)); // 1000 * 1.5
    });

    test('fractional proximity calculates correctly', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: true);

      // 33.33% into zone
      final result = config.calculatePanAmount(16.6666, edgePaddingValue: 50.0);
      // 0.3 + 0.333 * 1.2 = 0.7 → 7.0
      expect(result, closeTo(7.0, 0.1));
    });
  });

  group('Auto-Pan Speed - Timer Frequency', () {
    test('pan interval determines update frequency', () {
      const fastInterval = Duration(milliseconds: 8);
      const normalInterval = Duration(milliseconds: 16);
      const slowInterval = Duration(milliseconds: 32);

      expect(1000 / fastInterval.inMilliseconds, equals(125)); // 125 fps
      expect(
        1000 / normalInterval.inMilliseconds,
        closeTo(62.5, 0.1),
      ); // ~60 fps
      expect(
        1000 / slowInterval.inMilliseconds,
        closeTo(31.25, 0.1),
      ); // ~30 fps
    });

    test('effective speed compensates for different intervals', () {
      // Two configs with same effective speed
      const fastTicks = AutoPanConfig(
        panAmount: 5.0,
        panInterval: Duration(milliseconds: 8), // 125 fps
      );

      const slowTicks = AutoPanConfig(
        panAmount: 20.0,
        panInterval: Duration(milliseconds: 32), // ~31 fps
      );

      final fastSpeed =
          fastTicks.panAmount * (1000 / fastTicks.panInterval.inMilliseconds);
      final slowSpeed =
          slowTicks.panAmount * (1000 / slowTicks.panInterval.inMilliseconds);

      // Both should result in similar units/second
      expect(fastSpeed, equals(625.0)); // 5 * 125
      expect(slowSpeed, equals(625.0)); // 20 * 31.25
    });
  });

  group('Auto-Pan Speed - Custom Curves', () {
    test('custom cubic curve affects speed progression', () {
      const config = AutoPanConfig(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Cubic(0.2, 0.0, 0.4, 1.0), // Custom bezier
      );

      // Custom curve should produce values different from linear
      final atMiddle = config.calculatePanAmount(25.0, edgePaddingValue: 50.0);

      // Just verify it's within valid range
      expect(atMiddle, greaterThanOrEqualTo(3.0));
      expect(atMiddle, lessThanOrEqualTo(15.0));
    });

    test('step curve creates discrete speed levels', () {
      // Using a curve that approximates step function
      const config = AutoPanConfig(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Threshold(0.5), // Jump at 50%
      );

      // Before threshold: minimum speed
      final before = config.calculatePanAmount(24.9, edgePaddingValue: 50.0);
      expect(before, closeTo(3.0, 0.1)); // 0.3x

      // After threshold: maximum speed
      final after = config.calculatePanAmount(25.1, edgePaddingValue: 50.0);
      expect(after, closeTo(15.0, 0.1)); // 1.5x
    });
  });
}
