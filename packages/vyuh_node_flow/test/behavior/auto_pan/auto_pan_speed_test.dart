@Tags(['behavior'])
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('Auto-Pan Speed - Preset Configurations', () {
    test('normal preset pan amount is 10 graph units', () {
      final extension = AutoPanPlugin()..useNormal();
      expect(extension.panAmount, equals(10.0));
    });

    test('fast preset pan amount is 20 graph units', () {
      final extension = AutoPanPlugin()..useFast();
      expect(extension.panAmount, equals(20.0));
    });

    test('precise preset pan amount is 5 graph units', () {
      final extension = AutoPanPlugin()..usePrecise();
      expect(extension.panAmount, equals(5.0));
    });

    test('normal preset interval is ~60fps (16ms)', () {
      final extension = AutoPanPlugin()..useNormal();
      expect(extension.panInterval, equals(const Duration(milliseconds: 16)));
    });

    test('fast preset interval is ~83fps (12ms)', () {
      final extension = AutoPanPlugin()..useFast();
      expect(extension.panInterval, equals(const Duration(milliseconds: 12)));
    });

    test('precise preset interval is ~50fps (20ms)', () {
      final extension = AutoPanPlugin()..usePrecise();
      expect(extension.panInterval, equals(const Duration(milliseconds: 20)));
    });
  });

  group('Auto-Pan Speed - Effective Speed Calculation', () {
    test('normal preset speed: 10 units * 60 ticks/sec = 600 units/sec', () {
      final extension = AutoPanPlugin()..useNormal();
      final ticksPerSecond = 1000 / extension.panInterval.inMilliseconds;
      final unitsPerSecond = extension.panAmount * ticksPerSecond;

      expect(ticksPerSecond, closeTo(62.5, 0.1)); // 1000/16
      expect(unitsPerSecond, closeTo(625, 5)); // 10 * 62.5
    });

    test('fast preset speed: 20 units * 83 ticks/sec ≈ 1667 units/sec', () {
      final extension = AutoPanPlugin()..useFast();
      final ticksPerSecond = 1000 / extension.panInterval.inMilliseconds;
      final unitsPerSecond = extension.panAmount * ticksPerSecond;

      expect(ticksPerSecond, closeTo(83.3, 0.1)); // 1000/12
      expect(unitsPerSecond, closeTo(1666.7, 5)); // 20 * 83.3
    });

    test('precise preset speed: 5 units * 50 ticks/sec = 250 units/sec', () {
      final extension = AutoPanPlugin()..usePrecise();
      final ticksPerSecond = 1000 / extension.panInterval.inMilliseconds;
      final unitsPerSecond = extension.panAmount * ticksPerSecond;

      expect(ticksPerSecond, equals(50.0)); // 1000/20
      expect(unitsPerSecond, equals(250.0)); // 5 * 50
    });
  });

  group('Auto-Pan Speed - Proximity Scaling', () {
    test('without proximity scaling, speed is constant', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: false,
      );

      // At different proximities, the result should be the same
      final atBoundary = extension.calculatePanAmount(
        0.0,
        edgePaddingValue: 50.0,
      );
      final atMiddle = extension.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );
      final atEdge = extension.calculatePanAmount(50.0, edgePaddingValue: 50.0);

      expect(atBoundary, equals(10.0));
      expect(atMiddle, equals(10.0));
      expect(atEdge, equals(10.0));
    });

    test('with proximity scaling, speed varies from 0.3x to 1.5x', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // At zone boundary (proximity = 0): 0.3x = 3.0
      final atBoundary = extension.calculatePanAmount(
        0.0,
        edgePaddingValue: 50.0,
      );
      expect(atBoundary, closeTo(3.0, 0.01));

      // At viewport edge (proximity = padding): 1.5x = 15.0
      final atEdge = extension.calculatePanAmount(50.0, edgePaddingValue: 50.0);
      expect(atEdge, closeTo(15.0, 0.01));
    });

    test('proximity scaling with linear curve', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.linear,
      );

      // Linear interpolation from 0.3x to 1.5x
      // At 25% proximity: 0.3 + 0.25 * 1.2 = 0.6 → 6.0
      final at25Percent = extension.calculatePanAmount(
        12.5,
        edgePaddingValue: 50.0,
      );
      expect(at25Percent, closeTo(6.0, 0.1));

      // At 50% proximity: 0.3 + 0.5 * 1.2 = 0.9 → 9.0
      final at50Percent = extension.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );
      expect(at50Percent, closeTo(9.0, 0.1));

      // At 75% proximity: 0.3 + 0.75 * 1.2 = 1.2 → 12.0
      final at75Percent = extension.calculatePanAmount(
        37.5,
        edgePaddingValue: 50.0,
      );
      expect(at75Percent, closeTo(12.0, 0.1));
    });

    test('proximity scaling with easeIn curve (slow start)', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.easeIn,
      );

      // easeIn starts slow and accelerates
      final atMiddle = extension.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );

      // With linear, midpoint would be 9.0
      // With easeIn, it should be less (slower start)
      expect(atMiddle, lessThan(9.0));

      // But still progressing
      expect(atMiddle, greaterThan(3.0));
    });

    test('proximity scaling with easeOut curve (fast start)', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.easeOut,
      );

      // easeOut starts fast and decelerates
      final atMiddle = extension.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );

      // With linear, midpoint would be 9.0
      // With easeOut, it should be more (faster start)
      expect(atMiddle, greaterThan(9.0));

      // But not at maximum yet
      expect(atMiddle, lessThan(15.0));
    });

    test('proximity scaling with easeInOut curve', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.easeInOut,
      );

      // easeInOut: slow start, fast middle, slow end
      final atMiddle = extension.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );

      // At midpoint, easeInOut should be around linear value
      expect(atMiddle, closeTo(9.0, 1.0));
    });
  });

  group('Auto-Pan Speed - Minimum and Maximum', () {
    test('minimum speed is 0.3x base (at zone boundary)', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
      );

      final minSpeed = extension.calculatePanAmount(
        0.0,
        edgePaddingValue: 50.0,
      );
      expect(minSpeed, closeTo(3.0, 0.01)); // 0.3 * 10
    });

    test('maximum speed is 1.5x base (at viewport edge)', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
      );

      final maxSpeed = extension.calculatePanAmount(
        50.0,
        edgePaddingValue: 50.0,
      );
      expect(maxSpeed, closeTo(15.0, 0.01)); // 1.5 * 10
    });

    test('speed beyond edge padding clamps to maximum', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // Proximity exceeds edge padding (pointer outside bounds)
      final beyondMax = extension.calculatePanAmount(
        100.0,
        edgePaddingValue: 50.0,
      );
      expect(beyondMax, closeTo(15.0, 0.01)); // Clamped to max
    });

    test('negative proximity clamps to minimum', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // Negative proximity (shouldn't happen but handled)
      final negative = extension.calculatePanAmount(
        -10.0,
        edgePaddingValue: 50.0,
      );
      expect(negative, closeTo(3.0, 0.01)); // Clamped to min
    });
  });

  group('Auto-Pan Speed - Per-Edge Asymmetry', () {
    test('different edges can have different pan zones', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.only(
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
      final inLeftZone = extension.calculatePanAmount(
        15.0,
        edgePaddingValue: extension.edgePadding.left,
      );

      final inRightZone = extension.calculatePanAmount(
        15.0,
        edgePaddingValue: extension.edgePadding.right,
      );

      // 15px in 30px zone = 50% → speed ~9.0
      expect(inLeftZone, closeTo(9.0, 0.5));

      // 15px in 80px zone = 18.75% → speed ~5.25
      expect(inRightZone, closeTo(5.25, 0.5));

      // Different speeds for same absolute distance
      expect(inLeftZone, greaterThan(inRightZone));
    });

    test('wider zone provides more precision at edges', () {
      final narrowPlugin = AutoPanPlugin(
        edgePadding: const EdgeInsets.all(30.0),
        panAmount: 10.0,
        useProximityScaling: true,
      );

      final widePlugin = AutoPanPlugin(
        edgePadding: const EdgeInsets.all(100.0),
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // 10px from viewport edge
      // In narrow zone: 10/30 = 33% from edge
      // In wide zone: 10/100 = 10% from edge
      final narrowSpeed = narrowPlugin.calculatePanAmount(
        30.0 - 10.0,
        edgePaddingValue: 30.0,
      );

      final wideSpeed = widePlugin.calculatePanAmount(
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
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
      );

      final result = extension.calculatePanAmount(25.0, edgePaddingValue: 0.0);
      expect(result, equals(10.0));
    });

    test('very small pan amount still works', () {
      final extension = AutoPanPlugin(
        panAmount: 0.1,
        useProximityScaling: true,
      );

      final atEdge = extension.calculatePanAmount(50.0, edgePaddingValue: 50.0);
      expect(atEdge, closeTo(0.15, 0.01)); // 0.1 * 1.5
    });

    test('very large pan amount still works', () {
      final extension = AutoPanPlugin(
        panAmount: 1000.0,
        useProximityScaling: true,
      );

      final atEdge = extension.calculatePanAmount(50.0, edgePaddingValue: 50.0);
      expect(atEdge, closeTo(1500.0, 1.0)); // 1000 * 1.5
    });

    test('fractional proximity calculates correctly', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // 33.33% into zone
      final result = extension.calculatePanAmount(
        16.6666,
        edgePaddingValue: 50.0,
      );
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
      // Two extensions with same effective speed
      final fastTicks = AutoPanPlugin(
        panAmount: 5.0,
        panInterval: const Duration(milliseconds: 8), // 125 fps
      );

      final slowTicks = AutoPanPlugin(
        panAmount: 20.0,
        panInterval: const Duration(milliseconds: 32), // ~31 fps
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
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: const Cubic(0.2, 0.0, 0.4, 1.0), // Custom bezier
      );

      // Custom curve should produce values different from linear
      final atMiddle = extension.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );

      // Just verify it's within valid range
      expect(atMiddle, greaterThanOrEqualTo(3.0));
      expect(atMiddle, lessThanOrEqualTo(15.0));
    });

    test('step curve creates discrete speed levels', () {
      // Using a curve that approximates step function
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: const Threshold(0.5), // Jump at 50%
      );

      // Before threshold: minimum speed
      final before = extension.calculatePanAmount(24.9, edgePaddingValue: 50.0);
      expect(before, closeTo(3.0, 0.1)); // 0.3x

      // After threshold: maximum speed
      final after = extension.calculatePanAmount(25.1, edgePaddingValue: 50.0);
      expect(after, closeTo(15.0, 0.1)); // 1.5x
    });
  });

  group('Auto-Pan Speed - Preset Switching', () {
    test('can switch between presets dynamically', () {
      final extension = AutoPanPlugin();

      // Start with normal
      extension.useNormal();
      expect(extension.panAmount, equals(10.0));
      expect(extension.panInterval, equals(const Duration(milliseconds: 16)));

      // Switch to fast
      extension.useFast();
      expect(extension.panAmount, equals(20.0));
      expect(extension.panInterval, equals(const Duration(milliseconds: 12)));

      // Switch to precise
      extension.usePrecise();
      expect(extension.panAmount, equals(5.0));
      expect(extension.panInterval, equals(const Duration(milliseconds: 20)));

      // Back to normal
      extension.useNormal();
      expect(extension.panAmount, equals(10.0));
    });

    test('custom settings override presets', () {
      final extension = AutoPanPlugin()..useFast();

      // Verify fast preset
      expect(extension.panAmount, equals(20.0));

      // Override with custom setting
      extension.setPanAmount(15.0);
      expect(extension.panAmount, equals(15.0));

      // Interval unchanged
      expect(extension.panInterval, equals(const Duration(milliseconds: 12)));
    });
  });
}
