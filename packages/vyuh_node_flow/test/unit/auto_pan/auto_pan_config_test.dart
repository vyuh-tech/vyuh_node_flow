@Tags(['unit'])
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('AutoPanPlugin - Creation', () {
    test('creates with default values', () {
      final extension = AutoPanPlugin();

      expect(extension.edgePadding, equals(const EdgeInsets.all(50.0)));
      expect(extension.panAmount, equals(10.0));
      expect(extension.panInterval, equals(const Duration(milliseconds: 16)));
      expect(extension.useProximityScaling, isFalse);
      expect(extension.speedCurve, isNull);
    });

    test('creates with custom uniform edge padding', () {
      final extension = AutoPanPlugin(edgePadding: const EdgeInsets.all(80.0));

      expect(extension.edgePadding.left, equals(80.0));
      expect(extension.edgePadding.right, equals(80.0));
      expect(extension.edgePadding.top, equals(80.0));
      expect(extension.edgePadding.bottom, equals(80.0));
    });

    test('creates with custom per-edge padding', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.only(
          left: 30.0,
          right: 40.0,
          top: 50.0,
          bottom: 60.0,
        ),
      );

      expect(extension.edgePadding.left, equals(30.0));
      expect(extension.edgePadding.right, equals(40.0));
      expect(extension.edgePadding.top, equals(50.0));
      expect(extension.edgePadding.bottom, equals(60.0));
    });

    test('creates with symmetric padding', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.symmetric(
          horizontal: 40.0,
          vertical: 60.0,
        ),
      );

      expect(extension.edgePadding.left, equals(40.0));
      expect(extension.edgePadding.right, equals(40.0));
      expect(extension.edgePadding.top, equals(60.0));
      expect(extension.edgePadding.bottom, equals(60.0));
    });

    test('creates with custom pan amount', () {
      final extension = AutoPanPlugin(panAmount: 25.0);
      expect(extension.panAmount, equals(25.0));
    });

    test('creates with custom pan interval', () {
      final extension = AutoPanPlugin(
        panInterval: const Duration(milliseconds: 32),
      );
      expect(extension.panInterval, equals(const Duration(milliseconds: 32)));
    });

    test('creates with proximity scaling enabled', () {
      final extension = AutoPanPlugin(useProximityScaling: true);
      expect(extension.useProximityScaling, isTrue);
    });

    test('creates with speed curve', () {
      final extension = AutoPanPlugin(
        useProximityScaling: true,
        speedCurve: Curves.easeIn,
      );
      expect(extension.speedCurve, equals(Curves.easeIn));
    });
  });

  group('AutoPanPlugin - Presets', () {
    test('useNormal applies balanced settings', () {
      final extension = AutoPanPlugin();
      extension.useNormal();

      expect(extension.edgePadding, equals(const EdgeInsets.all(50.0)));
      expect(extension.panAmount, equals(10.0));
      expect(extension.panInterval, equals(const Duration(milliseconds: 16)));
      expect(extension.useProximityScaling, isFalse);
    });

    test('useFast applies larger pan amounts', () {
      final extension = AutoPanPlugin();
      extension.useFast();

      expect(extension.edgePadding, equals(const EdgeInsets.all(60.0)));
      expect(extension.panAmount, equals(20.0));
      expect(extension.panInterval, equals(const Duration(milliseconds: 12)));
    });

    test('usePrecise applies smaller pan amounts and narrower zone', () {
      final extension = AutoPanPlugin();
      extension.usePrecise();

      expect(extension.edgePadding, equals(const EdgeInsets.all(30.0)));
      expect(extension.panAmount, equals(5.0));
      expect(extension.panInterval, equals(const Duration(milliseconds: 20)));
    });
  });

  group('AutoPanPlugin - isEnabled', () {
    test('isEnabled returns true for default extension', () {
      final extension = AutoPanPlugin();
      expect(extension.isEnabled, isTrue);
    });

    test('isEnabled returns false when all edge padding is zero', () {
      final extension = AutoPanPlugin(
        edgePadding: EdgeInsets.zero,
        panAmount: 10.0,
      );
      expect(extension.isEnabled, isFalse);
    });

    test('isEnabled returns false when pan amount is zero', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.all(50.0),
        panAmount: 0.0,
      );
      expect(extension.isEnabled, isFalse);
    });

    test('isEnabled returns false when pan amount is negative', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.all(50.0),
        panAmount: -5.0,
      );
      expect(extension.isEnabled, isFalse);
    });

    test('isEnabled returns true with only one edge having padding', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.only(left: 50.0),
        panAmount: 10.0,
      );
      expect(extension.isEnabled, isTrue);
    });

    test('isEnabled returns false when all edges are negative', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.all(-10.0),
        panAmount: 10.0,
      );
      expect(extension.isEnabled, isFalse);
    });

    test('isEnabled returns false when explicitly disabled', () {
      final extension = AutoPanPlugin(enabled: false);
      expect(extension.isEnabled, isFalse);
    });
  });

  group('AutoPanPlugin - calculatePanAmount', () {
    test('returns base pan amount when proximity scaling disabled', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: false,
      );

      final result = extension.calculatePanAmount(
        25.0, // proximity
        edgePaddingValue: 50.0,
      );

      expect(result, equals(10.0));
    });

    test('returns base pan amount when edge padding is zero', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
      );

      final result = extension.calculatePanAmount(
        25.0, // proximity
        edgePaddingValue: 0.0,
      );

      expect(result, equals(10.0));
    });

    test('scales pan amount with linear proximity when enabled', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: null, // linear
      );

      // At boundary (proximity = 0): should be 0.3x = 3.0
      final atBoundary = extension.calculatePanAmount(
        0.0,
        edgePaddingValue: 50.0,
      );
      expect(atBoundary, closeTo(3.0, 0.01));

      // At edge (proximity = edgePadding = 50): should be 1.5x = 15.0
      final atEdge = extension.calculatePanAmount(50.0, edgePaddingValue: 50.0);
      expect(atEdge, closeTo(15.0, 0.01));

      // At midpoint (proximity = 25): should be 0.9x = 9.0
      final atMidpoint = extension.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );
      expect(atMidpoint, closeTo(9.0, 0.01));
    });

    test('clamps proximity to 0-1 range', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // Negative proximity should clamp to 0
      final negative = extension.calculatePanAmount(
        -10.0,
        edgePaddingValue: 50.0,
      );
      expect(negative, closeTo(3.0, 0.01)); // 0.3x

      // Proximity > edgePadding should clamp to 1
      final beyondEdge = extension.calculatePanAmount(
        100.0,
        edgePaddingValue: 50.0,
      );
      expect(beyondEdge, closeTo(15.0, 0.01)); // 1.5x
    });

    test('applies speed curve when provided', () {
      final extension = AutoPanPlugin(
        panAmount: 10.0,
        useProximityScaling: true,
        speedCurve: Curves.easeIn,
      );

      // easeIn starts slow and accelerates
      // At midpoint, easeIn curve value is less than 0.5
      final atMidpoint = extension.calculatePanAmount(
        25.0,
        edgePaddingValue: 50.0,
      );

      // With linear, midpoint would be 9.0
      // With easeIn, it should be less (slower start)
      expect(atMidpoint, lessThan(9.0));
      expect(atMidpoint, greaterThan(3.0)); // But still above minimum
    });
  });

  group('AutoPanPlugin - Enable/Disable', () {
    test('enable() enables autopan', () {
      final extension = AutoPanPlugin(enabled: false);
      expect(extension.isEnabled, isFalse);

      extension.enable();
      expect(extension.isEnabled, isTrue);
    });

    test('disable() disables autopan', () {
      final extension = AutoPanPlugin(enabled: true);
      expect(extension.isEnabled, isTrue);

      extension.disable();
      expect(extension.isEnabled, isFalse);
    });

    test('toggle() toggles enabled state', () {
      final extension = AutoPanPlugin(enabled: true);

      extension.toggle();
      expect(extension.isEnabled, isFalse);

      extension.toggle();
      expect(extension.isEnabled, isTrue);
    });
  });

  group('AutoPanPlugin - Property Setters', () {
    test('setEdgePadding updates edge padding', () {
      final extension = AutoPanPlugin();
      extension.setEdgePadding(const EdgeInsets.all(100.0));
      expect(extension.edgePadding, equals(const EdgeInsets.all(100.0)));
    });

    test('setPanAmount updates pan amount', () {
      final extension = AutoPanPlugin();
      extension.setPanAmount(25.0);
      expect(extension.panAmount, equals(25.0));
    });

    test('setPanInterval updates pan interval', () {
      final extension = AutoPanPlugin();
      extension.setPanInterval(const Duration(milliseconds: 32));
      expect(extension.panInterval, equals(const Duration(milliseconds: 32)));
    });

    test('setUseProximityScaling updates proximity scaling', () {
      final extension = AutoPanPlugin();
      extension.setUseProximityScaling(true);
      expect(extension.useProximityScaling, isTrue);
    });

    test('setSpeedCurve updates speed curve', () {
      final extension = AutoPanPlugin();
      extension.setSpeedCurve(Curves.easeIn);
      expect(extension.speedCurve, equals(Curves.easeIn));
    });
  });

  group('AutoPanPlugin - Edge Cases', () {
    test('handles very small pan amounts', () {
      final extension = AutoPanPlugin(panAmount: 0.001);
      expect(extension.isEnabled, isTrue);

      final scaled = extension.calculatePanAmount(25.0, edgePaddingValue: 50.0);
      expect(scaled, greaterThan(0));
    });

    test('handles very large edge padding', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.all(10000.0),
        panAmount: 10.0,
      );

      expect(extension.isEnabled, isTrue);
    });

    test('handles very small edge padding', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.all(1.0),
        panAmount: 10.0,
      );

      expect(extension.isEnabled, isTrue);
    });

    test('handles asymmetric edge padding', () {
      final extension = AutoPanPlugin(
        edgePadding: const EdgeInsets.only(left: 100.0, right: 10.0, top: 50.0),
        panAmount: 10.0,
        useProximityScaling: true,
      );

      // Left edge with larger padding
      final leftResult = extension.calculatePanAmount(
        50.0, // half of left padding
        edgePaddingValue: extension.edgePadding.left,
      );

      // Right edge with smaller padding
      final rightResult = extension.calculatePanAmount(
        5.0, // half of right padding
        edgePaddingValue: extension.edgePadding.right,
      );

      // Both should give similar normalized scaling (at 50%)
      expect(leftResult, closeTo(rightResult, 0.1));
    });
  });
}
