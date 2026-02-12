@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/editor/controller/viewport_culling_policy.dart';

void main() {
  group('ViewportCullingPolicy.isCacheValid', () {
    test('returns false when index changed', () {
      final viewport = Rect.fromLTWH(0, 0, 100, 100);
      final cached = viewport.inflate(1000);

      final result = ViewportCullingPolicy.isCacheValid(
        cachedQueryRect: cached,
        viewportRect: viewport,
        indexChanged: true,
      );

      expect(result, isFalse);
    });

    test('returns true when viewport stays within safety margin', () {
      final viewport = Rect.fromLTWH(100, 100, 200, 200);
      final cached = viewport.inflate(1000);

      final result = ViewportCullingPolicy.isCacheValid(
        cachedQueryRect: cached,
        viewportRect: viewport,
        indexChanged: false,
      );

      expect(result, isTrue);
    });

    test('returns false when viewport approaches cached edge', () {
      final viewport = Rect.fromLTWH(980, 100, 200, 200);
      final cached = Rect.fromLTWH(0, 0, 1200, 1200);

      final result = ViewportCullingPolicy.isCacheValid(
        cachedQueryRect: cached,
        viewportRect: viewport,
        indexChanged: false,
      );

      expect(result, isFalse);
    });
  });

  group('ViewportCullingPolicy.buildQueryRect', () {
    test('uses symmetric padding when not interacting', () {
      final viewport = Rect.fromLTWH(50, 75, 300, 200);
      final queryRect = ViewportCullingPolicy.buildQueryRect(
        viewportRect: viewport,
        previousViewportRect: null,
        isViewportInteracting: false,
      );

      expect(queryRect.left, equals(-950));
      expect(queryRect.top, equals(-925));
      expect(queryRect.right, equals(1350));
      expect(queryRect.bottom, equals(1275));
    });

    test('biases padding in pan direction while interacting', () {
      final previous = Rect.fromLTWH(0, 0, 300, 200);
      final current = Rect.fromLTWH(100, 60, 300, 200);

      final queryRect = ViewportCullingPolicy.buildQueryRect(
        viewportRect: current,
        previousViewportRect: previous,
        isViewportInteracting: true,
      );

      final leftPad = current.left - queryRect.left;
      final rightPad = queryRect.right - current.right;
      final topPad = current.top - queryRect.top;
      final bottomPad = queryRect.bottom - current.bottom;

      expect(rightPad, greaterThan(leftPad));
      expect(bottomPad, greaterThan(topPad));
      expect(leftPad + rightPad, equals(2000));
      expect(topPad + bottomPad, equals(2000));
    });

    test('biases toward left/up for negative pan deltas', () {
      final previous = Rect.fromLTWH(100, 60, 300, 200);
      final current = Rect.fromLTWH(0, 0, 300, 200);

      final queryRect = ViewportCullingPolicy.buildQueryRect(
        viewportRect: current,
        previousViewportRect: previous,
        isViewportInteracting: true,
      );

      final leftPad = current.left - queryRect.left;
      final rightPad = queryRect.right - current.right;
      final topPad = current.top - queryRect.top;
      final bottomPad = queryRect.bottom - current.bottom;

      expect(leftPad, greaterThan(rightPad));
      expect(topPad, greaterThan(bottomPad));
      expect(leftPad + rightPad, equals(2000));
      expect(topPad + bottomPad, equals(2000));
    });
  });
}
