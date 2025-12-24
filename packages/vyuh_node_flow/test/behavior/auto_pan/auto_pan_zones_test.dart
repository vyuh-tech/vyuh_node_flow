@Tags(['behavior'])
library;

import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    controller = createTestController();
    controller.setScreenSize(const Size(800, 600));
  });

  tearDown(() {
    controller.dispose();
  });

  group('Auto-Pan Zone Configuration', () {
    test('normal preset defines 50px edge zones', () {
      const config = AutoPanConfig.normal;

      expect(config.edgePadding.left, equals(50.0));
      expect(config.edgePadding.right, equals(50.0));
      expect(config.edgePadding.top, equals(50.0));
      expect(config.edgePadding.bottom, equals(50.0));
    });

    test('fast preset defines 60px edge zones', () {
      const config = AutoPanConfig.fast;

      expect(config.edgePadding.left, equals(60.0));
      expect(config.edgePadding.right, equals(60.0));
      expect(config.edgePadding.top, equals(60.0));
      expect(config.edgePadding.bottom, equals(60.0));
    });

    test('precise preset defines 30px edge zones', () {
      const config = AutoPanConfig.precise;

      expect(config.edgePadding.left, equals(30.0));
      expect(config.edgePadding.right, equals(30.0));
      expect(config.edgePadding.top, equals(30.0));
      expect(config.edgePadding.bottom, equals(30.0));
    });

    test('asymmetric zones can be configured', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.only(
          left: 40.0,
          right: 60.0,
          top: 30.0,
          bottom: 100.0, // larger for toolbar area
        ),
      );

      expect(config.edgePadding.left, equals(40.0));
      expect(config.edgePadding.right, equals(60.0));
      expect(config.edgePadding.top, equals(30.0));
      expect(config.edgePadding.bottom, equals(100.0));
    });
  });

  group('Zone Boundary Calculations', () {
    test('inner bounds exclude edge padding from viewport', () {
      // With viewport 800x600 and 50px padding on all sides:
      // Inner bounds should be from (50, 50) to (750, 550)
      const padding = EdgeInsets.all(50.0);
      const viewportSize = Size(800, 600);

      final innerLeft = padding.left;
      final innerTop = padding.top;
      final innerRight = viewportSize.width - padding.right;
      final innerBottom = viewportSize.height - padding.bottom;

      expect(innerLeft, equals(50.0));
      expect(innerTop, equals(50.0));
      expect(innerRight, equals(750.0));
      expect(innerBottom, equals(550.0));
    });

    test('edge zone width equals edge padding', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.only(
          left: 40.0,
          right: 60.0,
          top: 30.0,
          bottom: 50.0,
        ),
      );

      expect(config.edgePadding.left, equals(40.0));
      expect(config.edgePadding.right, equals(60.0));
      expect(config.edgePadding.top, equals(30.0));
      expect(config.edgePadding.bottom, equals(50.0));
    });

    test('zero padding on one edge disables that zone', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.only(
          left: 50.0,
          right: 0.0, // disabled
          top: 50.0,
          bottom: 50.0,
        ),
      );

      expect(config.edgePadding.right, equals(0.0));
      // Config is still enabled because other edges have padding
      expect(config.isEnabled, isTrue);
    });
  });

  group('Point Position Classification', () {
    // These tests verify the logic for classifying point positions
    // relative to viewport bounds and edge zones

    test('point in center is in inner bounds (no autopan)', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.all(50.0);
      const point = Offset(400, 300); // center

      final isInEdgeZone = _isInEdgeZone(point, viewportBounds, padding);
      expect(isInEdgeZone, isFalse);
    });

    test('point near left edge is in left zone', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.all(50.0);
      const point = Offset(25, 300); // in left zone

      final isInLeftZone = point.dx < viewportBounds.left + padding.left;
      expect(isInLeftZone, isTrue);
    });

    test('point near right edge is in right zone', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.all(50.0);
      const point = Offset(775, 300); // in right zone

      final isInRightZone = point.dx > viewportBounds.right - padding.right;
      expect(isInRightZone, isTrue);
    });

    test('point near top edge is in top zone', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.all(50.0);
      const point = Offset(400, 25); // in top zone

      final isInTopZone = point.dy < viewportBounds.top + padding.top;
      expect(isInTopZone, isTrue);
    });

    test('point near bottom edge is in bottom zone', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.all(50.0);
      const point = Offset(400, 575); // in bottom zone

      final isInBottomZone = point.dy > viewportBounds.bottom - padding.bottom;
      expect(isInBottomZone, isTrue);
    });

    test('point in corner is in multiple zones', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.all(50.0);
      const point = Offset(25, 25); // top-left corner

      final isInLeftZone = point.dx < viewportBounds.left + padding.left;
      final isInTopZone = point.dy < viewportBounds.top + padding.top;

      expect(isInLeftZone, isTrue);
      expect(isInTopZone, isTrue);
    });

    test('point outside viewport is outside bounds', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const point = Offset(-10, 300); // outside left

      final isOutside = !viewportBounds.contains(point);
      expect(isOutside, isTrue);
    });

    test('point at exact edge boundary is in zone', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.all(50.0);
      const point = Offset(50, 300); // at left zone boundary

      final isInLeftZone = point.dx < viewportBounds.left + padding.left;
      expect(isInLeftZone, isFalse); // exactly at boundary, not in zone
    });

    test('point just inside zone boundary is in zone', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.all(50.0);
      const point = Offset(49, 300); // just inside left zone

      final isInLeftZone = point.dx < viewportBounds.left + padding.left;
      expect(isInLeftZone, isTrue);
    });
  });

  group('Viewport with Offset', () {
    test('zone calculation works with non-zero viewport origin', () {
      // Viewport that doesn't start at (0, 0)
      const viewportBounds = Rect.fromLTWH(100, 50, 800, 600);
      const padding = EdgeInsets.all(50.0);
      const point = Offset(125, 300); // in left zone of offset viewport

      final isInLeftZone = point.dx < viewportBounds.left + padding.left;
      expect(isInLeftZone, isTrue);
    });

    test('inner bounds are relative to viewport origin', () {
      const viewportBounds = Rect.fromLTWH(100, 50, 800, 600);
      const padding = EdgeInsets.all(50.0);

      final innerLeft = viewportBounds.left + padding.left;
      final innerTop = viewportBounds.top + padding.top;
      final innerRight = viewportBounds.right - padding.right;
      final innerBottom = viewportBounds.bottom - padding.bottom;

      expect(innerLeft, equals(150.0));
      expect(innerTop, equals(100.0));
      expect(innerRight, equals(850.0));
      expect(innerBottom, equals(600.0));
    });
  });

  group('Edge Zone Overlap', () {
    test('large padding can cause zones to overlap in center', () {
      // With 400px padding on left and right in 800px viewport,
      // the zones meet in the middle
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.symmetric(horizontal: 400.0, vertical: 50.0);

      final leftZoneEnd = viewportBounds.left + padding.left;
      final rightZoneStart = viewportBounds.right - padding.right;

      // Zones overlap or meet
      expect(leftZoneEnd, greaterThanOrEqualTo(rightZoneStart));
    });

    test('point in overlapping zone triggers both directions', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const padding = EdgeInsets.symmetric(horizontal: 450.0, vertical: 50.0);
      const point = Offset(400, 300); // center

      final isInLeftZone = point.dx < viewportBounds.left + padding.left;
      final isInRightZone = point.dx > viewportBounds.right - padding.right;

      // Both can be true with overlapping zones
      expect(isInLeftZone, isTrue);
      expect(isInRightZone, isTrue);
    });
  });

  group('Zone Detection with Zoom', () {
    test('edge zones are in screen pixels, not graph units', () {
      // Edge padding is always in screen pixels
      // This is by design - the visual trigger zone stays constant
      // regardless of zoom level
      const config = AutoPanConfig(edgePadding: EdgeInsets.all(50.0));

      // At zoom 0.5, 1.0, or 2.0, the edge padding is still 50 screen pixels
      expect(config.edgePadding.left, equals(50.0));
    });

    test('viewport extent in graph coordinates changes with zoom', () {
      // viewportExtent returns the visible area in GRAPH coordinates
      // At lower zoom, you see more of the graph
      controller.zoomTo(1.0);
      final extent1 = controller.viewportExtent;

      controller.zoomTo(2.0);
      final extent2 = controller.viewportExtent;

      // At 2x zoom, you see half the graph area
      expect(extent2.width, closeTo(extent1.width / 2, 1.0));
      expect(extent2.height, closeTo(extent1.height / 2, 1.0));
    });
  });

  group('Disabled Zones', () {
    test('zero edge padding disables autopan', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.zero,
        panAmount: 10.0,
      );

      expect(config.isEnabled, isFalse);
    });

    test('zero pan amount disables autopan', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.all(50.0),
        panAmount: 0.0,
      );

      expect(config.isEnabled, isFalse);
    });

    test('negative pan amount disables autopan', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.all(50.0),
        panAmount: -5.0,
      );

      expect(config.isEnabled, isFalse);
    });

    test('partially disabled zones still enable autopan', () {
      const config = AutoPanConfig(
        edgePadding: EdgeInsets.only(left: 50.0), // only left enabled
        panAmount: 10.0,
      );

      expect(config.isEnabled, isTrue);
    });
  });
}

/// Helper to check if a point is in any edge zone
bool _isInEdgeZone(Offset point, Rect bounds, EdgeInsets padding) {
  if (!bounds.contains(point)) {
    return false; // Outside bounds entirely
  }

  final inLeftZone = padding.left > 0 && point.dx < bounds.left + padding.left;
  final inRightZone =
      padding.right > 0 && point.dx > bounds.right - padding.right;
  final inTopZone = padding.top > 0 && point.dy < bounds.top + padding.top;
  final inBottomZone =
      padding.bottom > 0 && point.dy > bounds.bottom - padding.bottom;

  return inLeftZone || inRightZone || inTopZone || inBottomZone;
}
