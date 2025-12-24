@Tags(['unit'])
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('AutoPanConfig - Creation', () {
    test('creates with default values', () {
      const config = AutoPanConfig();

      expect(config.edgePadding, equals(const EdgeInsets.all(50.0)));
      expect(config.panAmount, equals(10.0));
      expect(config.panInterval, equals(const Duration(milliseconds: 16)));
      expect(config.useProximityScaling, isFalse);
      expect(config.speedCurve, isNull);
    });

    test('creates with custom uniform edge padding', () {
      const config = AutoPanConfig(edgePadding: EdgeInsets.all(80.0));

      expect(config.edgePadding.left, equals(80.0));
      expect(config.edgePadding.right, equals(80.0));
      expect(config.edgePadding.top, equals(80.0));
      expect(config.edgePadding.bottom, equals(80.0));
    });

    test('creates with custom per-edge padding', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.only(
          left: 30.0,
          right: 40.0,
          top: 50.0,
          bottom: 60.0,
        ),
      );

      expect(config.edgePadding.left, equals(30.0));
      expect(config.edgePadding.right, equals(40.0));
      expect(config.edgePadding.top, equals(50.0));
      expect(config.edgePadding.bottom, equals(60.0));
    });

    test('creates with symmetric padding', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
      );

      expect(config.edgePadding.left, equals(40.0));
      expect(config.edgePadding.right, equals(40.0));
      expect(config.edgePadding.top, equals(60.0));
      expect(config.edgePadding.bottom, equals(60.0));
    });

    test('creates with custom pan amount', () {
      const config = AutoPanConfig(panAmount: 25.0);
      expect(config.panAmount, equals(25.0));
    });

    test('creates with custom pan interval', () {
      const config = AutoPanConfig(panInterval: Duration(milliseconds: 32));
      expect(config.panInterval, equals(const Duration(milliseconds: 32)));
    });

    test('creates with proximity scaling enabled', () {
      const config = AutoPanConfig(useProximityScaling: true);
      expect(config.useProximityScaling, isTrue);
    });

    test('creates with speed curve', () {
      const config = AutoPanConfig(
        useProximityScaling: true,
        speedCurve: Curves.easeIn,
      );
      expect(config.speedCurve, equals(Curves.easeIn));
    });
  });

  group('AutoPanConfig - Presets', () {
    test('normal preset has balanced settings', () {
      const config = AutoPanConfig.normal;

      expect(config.edgePadding, equals(const EdgeInsets.all(50.0)));
      expect(config.panAmount, equals(10.0));
      expect(config.panInterval, equals(const Duration(milliseconds: 16)));
      expect(config.useProximityScaling, isFalse);
    });

    test('fast preset has larger pan amounts', () {
      const config = AutoPanConfig.fast;

      expect(config.edgePadding, equals(const EdgeInsets.all(60.0)));
      expect(config.panAmount, equals(20.0));
      expect(config.panInterval, equals(const Duration(milliseconds: 12)));
    });

    test('precise preset has smaller pan amounts and narrower zone', () {
      const config = AutoPanConfig.precise;

      expect(config.edgePadding, equals(const EdgeInsets.all(30.0)));
      expect(config.panAmount, equals(5.0));
      expect(config.panInterval, equals(const Duration(milliseconds: 20)));
    });

    test('normal is same as default constructor', () {
      const normal = AutoPanConfig.normal;
      const defaultConfig = AutoPanConfig();

      expect(normal, equals(defaultConfig));
    });
  });

  group('AutoPanConfig - isEnabled', () {
    test('isEnabled returns true for normal config', () {
      const config = AutoPanConfig.normal;
      expect(config.isEnabled, isTrue);
    });

    test('isEnabled returns false when all edge padding is zero', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.zero,
        panAmount: 10.0,
      );
      expect(config.isEnabled, isFalse);
    });

    test('isEnabled returns false when pan amount is zero', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.all(50.0),
        panAmount: 0.0,
      );
      expect(config.isEnabled, isFalse);
    });

    test('isEnabled returns false when pan amount is negative', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.all(50.0),
        panAmount: -5.0,
      );
      expect(config.isEnabled, isFalse);
    });

    test('isEnabled returns true with only one edge having padding', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.only(left: 50.0),
        panAmount: 10.0,
      );
      expect(config.isEnabled, isTrue);
    });

    test('isEnabled returns false when all edges are negative', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.all(-10.0),
        panAmount: 10.0,
      );
      expect(config.isEnabled, isFalse);
    });
  });

  group('AutoPanConfig - calculatePanAmount', () {
    test('returns base pan amount when proximity scaling disabled', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: false);

      final result = config.calculatePanAmount(
        25.0, // proximity
        edgePaddingValue: 50.0,
      );

      expect(result, equals(10.0));
    });

    test('returns base pan amount when edge padding is zero', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: true);

      final result = config.calculatePanAmount(
        25.0, // proximity
        edgePaddingValue: 0.0,
      );

      expect(result, equals(10.0));
    });

    test('scales pan amount with linear proximity when enabled', () {
      const config = AutoPanConfig(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: null, // linear
      );

      // At boundary (proximity = 0): should be 0.3x = 3.0
      final atBoundary = config.calculatePanAmount(0.0, edgePaddingValue: 50.0);
      expect(atBoundary, closeTo(3.0, 0.01));

      // At edge (proximity = edgePadding = 50): should be 1.5x = 15.0
      final atEdge = config.calculatePanAmount(50.0, edgePaddingValue: 50.0);
      expect(atEdge, closeTo(15.0, 0.01));

      // At midpoint (proximity = 25): should be 0.9x = 9.0
      final atMidpoint = config.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );
      expect(atMidpoint, closeTo(9.0, 0.01));
    });

    test('clamps proximity to 0-1 range', () {
      const config = AutoPanConfig(panAmount: 10.0, useProximityScaling: true);

      // Negative proximity should clamp to 0
      final negative = config.calculatePanAmount(-10.0, edgePaddingValue: 50.0);
      expect(negative, closeTo(3.0, 0.01)); // 0.3x

      // Proximity > edgePadding should clamp to 1
      final beyondEdge = config.calculatePanAmount(
        100.0,
        edgePaddingValue: 50.0,
      );
      expect(beyondEdge, closeTo(15.0, 0.01)); // 1.5x
    });

    test('applies speed curve when provided', () {
      const config = AutoPanConfig(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.easeIn,
      );

      // easeIn starts slow and accelerates
      // At midpoint, easeIn curve value is less than 0.5
      final atMidpoint = config.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );

      // With linear, midpoint would be 9.0
      // With easeIn, it should be less (slower start)
      expect(atMidpoint, lessThan(9.0));
      expect(atMidpoint, greaterThan(3.0)); // But still above minimum
    });
  });

  group('AutoPanConfig - Equality', () {
    test('equal configs are equal', () {
      const config1 = AutoPanConfig(
        edgePadding: EdgeInsets.all(50.0),
        panAmount: 10.0,
        panInterval: Duration(milliseconds: 16),
        useProximityScaling: false,
      );
      const config2 = AutoPanConfig(
        edgePadding: EdgeInsets.all(50.0),
        panAmount: 10.0,
        panInterval: Duration(milliseconds: 16),
        useProximityScaling: false,
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('different edge padding makes configs unequal', () {
      const config1 = AutoPanConfig(edgePadding: EdgeInsets.all(50.0));
      const config2 = AutoPanConfig(edgePadding: EdgeInsets.all(60.0));

      expect(config1, isNot(equals(config2)));
    });

    test('different pan amount makes configs unequal', () {
      const config1 = AutoPanConfig(panAmount: 10.0);
      const config2 = AutoPanConfig(panAmount: 15.0);

      expect(config1, isNot(equals(config2)));
    });

    test('different pan interval makes configs unequal', () {
      const config1 = AutoPanConfig(panInterval: Duration(milliseconds: 16));
      const config2 = AutoPanConfig(panInterval: Duration(milliseconds: 32));

      expect(config1, isNot(equals(config2)));
    });

    test('different proximity scaling makes configs unequal', () {
      const config1 = AutoPanConfig(useProximityScaling: false);
      const config2 = AutoPanConfig(useProximityScaling: true);

      expect(config1, isNot(equals(config2)));
    });

    test('different speed curve makes configs unequal', () {
      const config1 = AutoPanConfig(
        useProximityScaling: true,
        speedCurve: Curves.linear,
      );
      const config2 = AutoPanConfig(
        useProximityScaling: true,
        speedCurve: Curves.easeIn,
      );

      expect(config1, isNot(equals(config2)));
    });

    test('identical returns true for same instance', () {
      const config = AutoPanConfig.normal;
      expect(config == config, isTrue);
    });
  });

  group('AutoPanConfig - toString', () {
    test('toString contains all relevant information', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.all(50.0),
        panAmount: 10.0,
        panInterval: Duration(milliseconds: 16),
        useProximityScaling: true,
      );

      final str = config.toString();

      expect(str, contains('AutoPanConfig'));
      expect(str, contains('edgePadding'));
      expect(str, contains('panAmount'));
      expect(str, contains('panInterval'));
      expect(str, contains('useProximityScaling'));
    });
  });

  group('AutoPanConfig - Edge Cases', () {
    test('handles very small pan amounts', () {
      const config = AutoPanConfig(panAmount: 0.001);
      expect(config.isEnabled, isTrue);

      final scaled = config.calculatePanAmount(25.0, edgePaddingValue: 50.0);
      expect(scaled, greaterThan(0));
    });

    test('handles very large edge padding', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.all(10000.0),
        panAmount: 10.0,
      );

      expect(config.isEnabled, isTrue);
    });

    test('handles very small edge padding', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.all(1.0),
        panAmount: 10.0,
      );

      expect(config.isEnabled, isTrue);
    });

    test('handles asymmetric edge padding', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.only(left: 100.0, right: 10.0, top: 50.0),
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // Left edge with larger padding
      final leftResult = config.calculatePanAmount(
        50.0, // half of left padding
        edgePaddingValue: config.edgePadding.left,
      );

      // Right edge with smaller padding
      final rightResult = config.calculatePanAmount(
        5.0, // half of right padding
        edgePaddingValue: config.edgePadding.right,
      );

      // Both should give similar normalized scaling (at 50%)
      expect(leftResult, closeTo(rightResult, 0.1));
    });
  });
}
