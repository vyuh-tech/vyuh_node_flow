/// Unit tests for the [GraphViewport] data model.
///
/// Tests cover:
/// - Viewport creation with defaults and custom values
/// - Coordinate transformations (screen <-> graph)
/// - Visibility queries
/// - Equality and copyWith
/// - JSON serialization
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  group('GraphViewport Creation', () {
    test('creates viewport with default values', () {
      const viewport = GraphViewport();

      expect(viewport.x, equals(0.0));
      expect(viewport.y, equals(0.0));
      expect(viewport.zoom, equals(1.0));
    });

    test('creates viewport with custom pan values', () {
      const viewport = GraphViewport(x: 100, y: 200);

      expect(viewport.x, equals(100));
      expect(viewport.y, equals(200));
    });

    test('creates viewport with custom zoom value', () {
      const viewport = GraphViewport(zoom: 2.0);

      expect(viewport.zoom, equals(2.0));
    });

    test('creates viewport with all custom values', () {
      const viewport = GraphViewport(x: 50, y: 75, zoom: 1.5);

      expect(viewport.x, equals(50));
      expect(viewport.y, equals(75));
      expect(viewport.zoom, equals(1.5));
    });
  });

  group('Screen to Graph Transformation', () {
    test('toGraph at zoom=1.0 and no pan', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
      final screenPos = ScreenPosition.fromXY(100, 200);

      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, closeTo(100, 0.01));
      expect(graphPos.dy, closeTo(200, 0.01));
    });

    test('toGraph at zoom=2.0 (zoomed in)', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);
      final screenPos = ScreenPosition.fromXY(200, 200);

      final graphPos = viewport.toGraph(screenPos);

      // Screen 200,200 at 2x zoom = graph 100,100
      expect(graphPos.dx, closeTo(100, 0.01));
      expect(graphPos.dy, closeTo(100, 0.01));
    });

    test('toGraph at zoom=0.5 (zoomed out)', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 0.5);
      final screenPos = ScreenPosition.fromXY(100, 100);

      final graphPos = viewport.toGraph(screenPos);

      // Screen 100,100 at 0.5x zoom = graph 200,200
      expect(graphPos.dx, closeTo(200, 0.01));
      expect(graphPos.dy, closeTo(200, 0.01));
    });

    test('toGraph with pan offset', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 1.0);
      final screenPos = ScreenPosition.fromXY(200, 150);

      final graphPos = viewport.toGraph(screenPos);

      // (200-100)/1 = 100, (150-50)/1 = 100
      expect(graphPos.dx, closeTo(100, 0.01));
      expect(graphPos.dy, closeTo(100, 0.01));
    });

    test('toGraph with combined pan and zoom', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);
      final screenPos = ScreenPosition.fromXY(300, 250);

      final graphPos = viewport.toGraph(screenPos);

      // (300-100)/2 = 100, (250-50)/2 = 100
      expect(graphPos.dx, closeTo(100, 0.01));
      expect(graphPos.dy, closeTo(100, 0.01));
    });

    test('toGraphOffset scales without translation', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);
      final screenDelta = ScreenOffset.fromXY(100, 50);

      final graphDelta = viewport.toGraphOffset(screenDelta);

      // 100/2 = 50, 50/2 = 25 (pan is not applied)
      expect(graphDelta.dx, closeTo(50, 0.01));
      expect(graphDelta.dy, closeTo(25, 0.01));
    });
  });

  group('Graph to Screen Transformation', () {
    test('toScreen at zoom=1.0 and no pan', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
      final graphPos = GraphPosition.fromXY(100, 200);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, closeTo(100, 0.01));
      expect(screenPos.dy, closeTo(200, 0.01));
    });

    test('toScreen at zoom=2.0 (zoomed in)', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);
      final graphPos = GraphPosition.fromXY(100, 100);

      final screenPos = viewport.toScreen(graphPos);

      // Graph 100,100 at 2x zoom = screen 200,200
      expect(screenPos.dx, closeTo(200, 0.01));
      expect(screenPos.dy, closeTo(200, 0.01));
    });

    test('toScreen at zoom=0.5 (zoomed out)', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 0.5);
      final graphPos = GraphPosition.fromXY(200, 200);

      final screenPos = viewport.toScreen(graphPos);

      // Graph 200,200 at 0.5x zoom = screen 100,100
      expect(screenPos.dx, closeTo(100, 0.01));
      expect(screenPos.dy, closeTo(100, 0.01));
    });

    test('toScreen with pan offset', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 1.0);
      final graphPos = GraphPosition.fromXY(100, 100);

      final screenPos = viewport.toScreen(graphPos);

      // 100*1+100 = 200, 100*1+50 = 150
      expect(screenPos.dx, closeTo(200, 0.01));
      expect(screenPos.dy, closeTo(150, 0.01));
    });

    test('toScreen with combined pan and zoom', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);
      final graphPos = GraphPosition.fromXY(100, 100);

      final screenPos = viewport.toScreen(graphPos);

      // 100*2+100 = 300, 100*2+50 = 250
      expect(screenPos.dx, closeTo(300, 0.01));
      expect(screenPos.dy, closeTo(250, 0.01));
    });

    test('toScreenOffset scales without translation', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);
      final graphDelta = GraphOffset.fromXY(50, 25);

      final screenDelta = viewport.toScreenOffset(graphDelta);

      // 50*2 = 100, 25*2 = 50 (pan is not applied)
      expect(screenDelta.dx, closeTo(100, 0.01));
      expect(screenDelta.dy, closeTo(50, 0.01));
    });
  });

  group('Round-trip Transformations', () {
    test('screen -> graph -> screen returns original at zoom=1.0', () {
      const viewport = GraphViewport(x: 50, y: 75, zoom: 1.0);
      final original = ScreenPosition.fromXY(200, 300);

      final graphPos = viewport.toGraph(original);
      final restored = viewport.toScreen(graphPos);

      expect(restored.dx, closeTo(original.dx, 0.01));
      expect(restored.dy, closeTo(original.dy, 0.01));
    });

    test('screen -> graph -> screen returns original at zoom=2.0', () {
      const viewport = GraphViewport(x: 100, y: 100, zoom: 2.0);
      final original = ScreenPosition.fromXY(400, 500);

      final graphPos = viewport.toGraph(original);
      final restored = viewport.toScreen(graphPos);

      expect(restored.dx, closeTo(original.dx, 0.01));
      expect(restored.dy, closeTo(original.dy, 0.01));
    });

    test('graph -> screen -> graph returns original', () {
      const viewport = GraphViewport(x: 75, y: 125, zoom: 1.5);
      final original = GraphPosition.fromXY(300, 400);

      final screenPos = viewport.toScreen(original);
      final restored = viewport.toGraph(screenPos);

      expect(restored.dx, closeTo(original.dx, 0.01));
      expect(restored.dy, closeTo(original.dy, 0.01));
    });
  });

  group('Rectangle Transformations', () {
    test('toScreenRect transforms rectangle correctly', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);
      final graphRect = GraphRect.fromLTWH(0, 0, 100, 50);

      final screenRect = viewport.toScreenRect(graphRect);

      expect(screenRect.rect.width, closeTo(200, 0.01));
      expect(screenRect.rect.height, closeTo(100, 0.01));
    });

    test('toGraphRect transforms rectangle correctly', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);
      final screenRect = ScreenRect.fromLTWH(0, 0, 200, 100);

      final graphRect = viewport.toGraphRect(screenRect);

      expect(graphRect.rect.width, closeTo(100, 0.01));
      expect(graphRect.rect.height, closeTo(50, 0.01));
    });
  });

  group('Visibility Queries', () {
    test('getVisibleArea returns correct bounds at zoom=1.0', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
      const screenSize = Size(800, 600);

      final visibleArea = viewport.getVisibleArea(screenSize);

      expect(visibleArea.rect.left, closeTo(0, 0.01));
      expect(visibleArea.rect.top, closeTo(0, 0.01));
      expect(visibleArea.rect.width, closeTo(800, 0.01));
      expect(visibleArea.rect.height, closeTo(600, 0.01));
    });

    test('getVisibleArea returns larger area when zoomed out', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 0.5);
      const screenSize = Size(800, 600);

      final visibleArea = viewport.getVisibleArea(screenSize);

      expect(visibleArea.rect.width, closeTo(1600, 0.01));
      expect(visibleArea.rect.height, closeTo(1200, 0.01));
    });

    test('getVisibleArea returns smaller area when zoomed in', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);
      const screenSize = Size(800, 600);

      final visibleArea = viewport.getVisibleArea(screenSize);

      expect(visibleArea.rect.width, closeTo(400, 0.01));
      expect(visibleArea.rect.height, closeTo(300, 0.01));
    });

    test('isRectVisible returns true for visible rectangle', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
      const screenSize = Size(800, 600);
      final rect = GraphRect.fromLTWH(100, 100, 50, 50);

      expect(viewport.isRectVisible(rect, screenSize), isTrue);
    });

    test('isRectVisible returns false for off-screen rectangle', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
      const screenSize = Size(800, 600);
      final rect = GraphRect.fromLTWH(1000, 1000, 50, 50);

      expect(viewport.isRectVisible(rect, screenSize), isFalse);
    });

    test('isRectVisible returns true for partially visible rectangle', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
      const screenSize = Size(800, 600);
      final rect = GraphRect.fromLTWH(
        750,
        550,
        100,
        100,
      ); // Overlaps bottom-right

      expect(viewport.isRectVisible(rect, screenSize), isTrue);
    });

    test('isPointVisible returns true for visible point', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
      const screenSize = Size(800, 600);
      final point = GraphPosition.fromXY(400, 300);

      expect(viewport.isPointVisible(point, screenSize), isTrue);
    });

    test('isPointVisible returns false for off-screen point', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);
      const screenSize = Size(800, 600);
      final point = GraphPosition.fromXY(-100, -100);

      expect(viewport.isPointVisible(point, screenSize), isFalse);
    });
  });

  group('Equality', () {
    test('viewports with same values are equal', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 100, y: 200, zoom: 1.5);

      expect(viewport1, equals(viewport2));
    });

    test('viewports with different x are not equal', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 150, y: 200, zoom: 1.5);

      expect(viewport1, isNot(equals(viewport2)));
    });

    test('viewports with different y are not equal', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 100, y: 250, zoom: 1.5);

      expect(viewport1, isNot(equals(viewport2)));
    });

    test('viewports with different zoom are not equal', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 100, y: 200, zoom: 2.0);

      expect(viewport1, isNot(equals(viewport2)));
    });

    test('hashCode is consistent for equal viewports', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 100, y: 200, zoom: 1.5);

      expect(viewport1.hashCode, equals(viewport2.hashCode));
    });
  });

  group('copyWith', () {
    test('copyWith creates a copy with same values', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('copyWith can change x', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final modified = original.copyWith(x: 150);

      expect(modified.x, equals(150));
      expect(modified.y, equals(200)); // Unchanged
      expect(modified.zoom, equals(1.5)); // Unchanged
    });

    test('copyWith can change y', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final modified = original.copyWith(y: 250);

      expect(modified.x, equals(100)); // Unchanged
      expect(modified.y, equals(250));
      expect(modified.zoom, equals(1.5)); // Unchanged
    });

    test('copyWith can change zoom', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final modified = original.copyWith(zoom: 2.0);

      expect(modified.x, equals(100)); // Unchanged
      expect(modified.y, equals(200)); // Unchanged
      expect(modified.zoom, equals(2.0));
    });

    test('copyWith can change multiple values', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final modified = original.copyWith(x: 50, zoom: 3.0);

      expect(modified.x, equals(50));
      expect(modified.y, equals(200)); // Unchanged
      expect(modified.zoom, equals(3.0));
    });
  });

  group('JSON Serialization', () {
    test('toJson produces valid JSON', () {
      const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final json = viewport.toJson();

      expect(json['x'], equals(100.0));
      expect(json['y'], equals(200.0));
      expect(json['zoom'], equals(1.5));
    });

    test('fromJson reconstructs viewport correctly', () {
      final json = {'x': 150.0, 'y': 250.0, 'zoom': 2.0};

      final viewport = GraphViewport.fromJson(json);

      expect(viewport.x, equals(150));
      expect(viewport.y, equals(250));
      expect(viewport.zoom, equals(2.0));
    });

    test('round-trip serialization preserves all properties', () {
      const original = GraphViewport(x: 75, y: 125, zoom: 1.75);

      final restored = roundTripViewportJson(original);

      expect(restored.x, equals(original.x));
      expect(restored.y, equals(original.y));
      expect(restored.zoom, equals(original.zoom));
    });

    test('fromJson handles missing values with defaults', () {
      final json = <String, dynamic>{};

      final viewport = GraphViewport.fromJson(json);

      expect(viewport.x, equals(0.0));
      expect(viewport.y, equals(0.0));
      expect(viewport.zoom, equals(1.0));
    });

    test('fromJson handles integer values', () {
      final json = {'x': 100, 'y': 200, 'zoom': 2};

      final viewport = GraphViewport.fromJson(json);

      expect(viewport.x, equals(100.0));
      expect(viewport.y, equals(200.0));
      expect(viewport.zoom, equals(2.0));
    });
  });

  group('toString', () {
    test('toString returns readable format', () {
      const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final string = viewport.toString();

      expect(string, contains('GraphViewport'));
      expect(string, contains('100'));
      expect(string, contains('200'));
      expect(string, contains('1.5'));
    });
  });

  group('Edge Cases', () {
    test('viewport at origin', () {
      const viewport = GraphViewport();
      final screenPos = ScreenPosition.fromXY(0, 0);

      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(0));
      expect(graphPos.dy, equals(0));
    });

    test('viewport with negative pan', () {
      const viewport = GraphViewport(x: -100, y: -50, zoom: 1.0);
      final screenPos = ScreenPosition.fromXY(0, 0);

      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(100));
      expect(graphPos.dy, equals(50));
    });

    test('viewport with very small zoom', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 0.01);
      final screenPos = ScreenPosition.fromXY(10, 10);

      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, closeTo(1000, 0.01));
      expect(graphPos.dy, closeTo(1000, 0.01));
    });

    test('viewport with very large zoom', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 100.0);
      final graphPos = GraphPosition.fromXY(1, 1);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(100));
      expect(screenPos.dy, equals(100));
    });

    test('viewport with large pan values', () {
      const viewport = GraphViewport(x: 10000, y: 10000, zoom: 1.0);
      final graphPos = GraphPosition.fromXY(0, 0);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(10000));
      expect(screenPos.dy, equals(10000));
    });
  });
}
