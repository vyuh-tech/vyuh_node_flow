/// Unit tests for the [SpatialGrid] class.
///
/// Tests cover:
/// - Grid construction with different cell sizes
/// - Adding/removing entries
/// - Query by point
/// - Query by bounds (Rect)
/// - Grid rebuilding and clearing
/// - Dragging optimization mode
/// - Caching behavior
/// - Edge cases (empty grid, overlapping entries)
/// - Debug utilities (stats, cell info, consistency diagnostics)
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/shared/spatial/spatial_grid.dart';
import 'package:vyuh_node_flow/src/shared/spatial/spatial_item.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  group('SpatialGrid Construction', () {
    test('creates with default grid size', () {
      final grid = SpatialGrid<SpatialItem>();

      expect(grid.gridSize, equals(500.0));
      expect(grid.enableCaching, isTrue);
    });

    test('creates with custom grid size', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);

      expect(grid.gridSize, equals(100.0));
    });

    test('creates with small grid size', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 10.0);

      expect(grid.gridSize, equals(10.0));
    });

    test('creates with large grid size', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 5000.0);

      expect(grid.gridSize, equals(5000.0));
    });

    test('creates with caching disabled', () {
      final grid = SpatialGrid<SpatialItem>(enableCaching: false);

      expect(grid.enableCaching, isFalse);
    });

    test('starts empty', () {
      final grid = SpatialGrid<SpatialItem>();

      expect(grid.objectCount, equals(0));
      expect(grid.objects, isEmpty);
    });

    test('stats reflect empty initial state', () {
      final grid = SpatialGrid<SpatialItem>();
      final stats = grid.stats;

      expect(stats.objectCount, equals(0));
      expect(stats.gridCellCount, equals(0));
      expect(stats.isDragging, isFalse);
      expect(stats.draggingObjectCount, equals(0));
      expect(stats.cacheSize, equals(0));
    });
  });

  group('Adding Entries', () {
    test('addOrUpdate adds a single item', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      expect(grid.objectCount, equals(1));
      expect(grid.getObject('node_node-1'), equals(item));
    });

    test('addOrUpdate updates existing item', () {
      final grid = SpatialGrid<SpatialItem>();
      const item1 = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );
      const item2 = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(200, 200, 150, 150),
      );

      grid.addOrUpdate(item1);
      grid.flushPendingUpdates();
      grid.addOrUpdate(item2);
      grid.flushPendingUpdates();

      expect(grid.objectCount, equals(1));
      final retrieved = grid.getObject('node_node-1') as NodeSpatialItem;
      expect(retrieved.bounds, equals(const Rect.fromLTWH(200, 200, 150, 150)));
    });

    test('addOrUpdate adds multiple items', () {
      final grid = SpatialGrid<SpatialItem>();

      for (var i = 0; i < 10; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 100.0, 0, 50, 50),
          ),
        );
      }
      grid.flushPendingUpdates();

      expect(grid.objectCount, equals(10));
    });

    test('addOrUpdate handles different SpatialItem types', () {
      final grid = SpatialGrid<SpatialItem>();

      const node = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );
      const port = PortSpatialItem(
        portId: 'port-1',
        nodeId: 'node-1',
        isOutput: true,
        bounds: Rect.fromLTWH(95, 45, 20, 20),
      );
      const conn = ConnectionSegmentItem(
        connectionId: 'conn-1',
        segmentIndex: 0,
        bounds: Rect.fromLTWH(100, 50, 200, 10),
      );

      grid.addOrUpdate(node);
      grid.addOrUpdate(port);
      grid.addOrUpdate(conn);
      grid.flushPendingUpdates();

      expect(grid.objectCount, equals(3));
      expect(grid.getObject('node_node-1'), equals(node));
      expect(grid.getObject('port_node-1_port-1'), equals(port));
      expect(grid.getObject('conn_conn-1_seg_0'), equals(conn));
    });

    test('addOrUpdate places item in correct grid cells', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);
      // Item that spans multiple cells (0,0), (1,0), (0,1), (1,1)
      const item = NodeSpatialItem(
        nodeId: 'spanning',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // Check via active cell keys
      final cellKeys = grid.activeCellKeys.toSet();
      expect(cellKeys, contains('0_0'));
      expect(cellKeys, contains('1_0'));
      expect(cellKeys, contains('0_1'));
      expect(cellKeys, contains('1_1'));
    });
  });

  group('Removing Entries', () {
    test('remove deletes existing item', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();
      grid.remove('node_node-1');

      expect(grid.objectCount, equals(0));
      expect(grid.getObject('node_node-1'), isNull);
    });

    test('remove handles non-existent item gracefully', () {
      final grid = SpatialGrid<SpatialItem>();

      // Should not throw
      grid.remove('non-existent-id');

      expect(grid.objectCount, equals(0));
    });

    test('remove cleans up grid cells', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();
      expect(grid.activeCellKeys, isNotEmpty);

      grid.remove('node_node-1');
      expect(grid.activeCellKeys, isEmpty);
    });

    test('remove only affects targeted item', () {
      final grid = SpatialGrid<SpatialItem>();
      const item1 = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );
      const item2 = NodeSpatialItem(
        nodeId: 'node-2',
        bounds: Rect.fromLTWH(200, 200, 100, 100),
      );

      grid.addOrUpdate(item1);
      grid.addOrUpdate(item2);
      grid.flushPendingUpdates();

      grid.remove('node_node-1');

      expect(grid.objectCount, equals(1));
      expect(grid.getObject('node_node-1'), isNull);
      expect(grid.getObject('node_node-2'), equals(item2));
    });
  });

  group('Query by Point', () {
    test('queryPoint returns empty list for empty grid', () {
      final grid = SpatialGrid<SpatialItem>();

      final result = grid.queryPoint(const Offset(100, 100));

      expect(result, isEmpty);
    });

    test('queryPoint finds item at exact point', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      final result = grid.queryPoint(const Offset(50, 50));

      expect(result, hasLength(1));
      expect(result.first, equals(item));
    });

    test('queryPoint returns empty for point outside all items', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      final result = grid.queryPoint(const Offset(200, 200));

      expect(result, isEmpty);
    });

    test('queryPoint finds item at edge of bounds', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // Point at bottom-right edge (still inside)
      final result = grid.queryPoint(const Offset(99, 99));

      expect(result, hasLength(1));
    });

    test('queryPoint with radius finds nearby items', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(100, 100, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // Point just outside bounds, but within radius
      final result = grid.queryPoint(const Offset(90, 90), radius: 20);

      expect(result, hasLength(1));
    });

    test('queryPoint with radius excludes items outside radius', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(100, 100, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // Point far from bounds
      final result = grid.queryPoint(const Offset(0, 0), radius: 10);

      expect(result, isEmpty);
    });

    test('queryPoint finds multiple overlapping items', () {
      final grid = SpatialGrid<SpatialItem>();
      const item1 = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );
      const item2 = NodeSpatialItem(
        nodeId: 'node-2',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
      );

      grid.addOrUpdate(item1);
      grid.addOrUpdate(item2);
      grid.flushPendingUpdates();

      // Point in overlap region
      final result = grid.queryPoint(const Offset(75, 75));

      expect(result, hasLength(2));
    });

    test('queryPoint at negative coordinates', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(-100, -100, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      final result = grid.queryPoint(const Offset(-75, -75));

      expect(result, hasLength(1));
    });
  });

  group('Query by Bounds', () {
    test('query returns empty list for empty grid', () {
      final grid = SpatialGrid<SpatialItem>();

      final result = grid.query(const Rect.fromLTWH(0, 0, 500, 500));

      expect(result, isEmpty);
    });

    test('query finds item within bounds', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(100, 100, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      final result = grid.query(const Rect.fromLTWH(0, 0, 500, 500));

      expect(result, hasLength(1));
      expect(result.first, equals(item));
    });

    test('query excludes items outside bounds', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(600, 600, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      final result = grid.query(const Rect.fromLTWH(0, 0, 500, 500));

      expect(result, isEmpty);
    });

    test('query finds items that overlap bounds', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(450, 450, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      final result = grid.query(const Rect.fromLTWH(0, 0, 500, 500));

      expect(result, hasLength(1));
    });

    test('query returns multiple matching items', () {
      final grid = SpatialGrid<SpatialItem>();

      for (var i = 0; i < 5; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 50.0, i * 50.0, 40, 40),
          ),
        );
      }
      grid.flushPendingUpdates();

      final result = grid.query(const Rect.fromLTWH(0, 0, 300, 300));

      expect(result, hasLength(5));
    });

    test('query with zero-size bounds inside item still finds it', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // Zero-size bounds at a point inside the item - Rect.overlaps returns true
      // for zero-size rects that share the same coordinate space
      final result = grid.query(const Rect.fromLTWH(75, 75, 0, 0));

      expect(result, hasLength(1));
    });

    test('query with zero-size bounds outside item finds nothing', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // Zero-size bounds completely outside the item
      final result = grid.query(const Rect.fromLTWH(200, 200, 0, 0));

      expect(result, isEmpty);
    });

    test('query with large bounds finds all items', () {
      final grid = SpatialGrid<SpatialItem>();

      for (var i = 0; i < 100; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 10.0, i * 10.0, 8, 8),
          ),
        );
      }
      grid.flushPendingUpdates();

      final result = grid.query(const Rect.fromLTWH(-1000, -1000, 5000, 5000));

      expect(result, hasLength(100));
    });

    test('query at negative coordinate bounds', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(-150, -150, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      final result = grid.query(const Rect.fromLTWH(-200, -200, 300, 300));

      expect(result, hasLength(1));
    });
  });

  group('Grid Clearing', () {
    test('clear removes all items', () {
      final grid = SpatialGrid<SpatialItem>();

      for (var i = 0; i < 10; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 100.0, 0, 50, 50),
          ),
        );
      }
      grid.flushPendingUpdates();

      grid.clear();

      expect(grid.objectCount, equals(0));
      expect(grid.activeCellKeys, isEmpty);
    });

    test('clear on empty grid does nothing', () {
      final grid = SpatialGrid<SpatialItem>();

      grid.clear(); // Should not throw

      expect(grid.objectCount, equals(0));
    });

    test('grid can be reused after clear', () {
      final grid = SpatialGrid<SpatialItem>();
      const item1 = NodeSpatialItem(
        nodeId: 'before',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );
      const item2 = NodeSpatialItem(
        nodeId: 'after',
        bounds: Rect.fromLTWH(200, 200, 100, 100),
      );

      grid.addOrUpdate(item1);
      grid.flushPendingUpdates();
      grid.clear();
      grid.addOrUpdate(item2);
      grid.flushPendingUpdates();

      expect(grid.objectCount, equals(1));
      expect(grid.getObject('node_after'), equals(item2));
      expect(grid.getObject('node_before'), isNull);
    });
  });

  group('Dragging Optimization', () {
    test('startDragging sets dragging state', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();
      grid.startDragging(['node_node-1']);

      expect(grid.stats.isDragging, isTrue);
      expect(grid.stats.draggingObjectCount, equals(1));
    });

    test('endDragging clears dragging state', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();
      grid.startDragging(['node_node-1']);
      grid.endDragging();

      expect(grid.stats.isDragging, isFalse);
      expect(grid.stats.draggingObjectCount, equals(0));
    });

    test('startDragging with empty list does not start drag mode', () {
      final grid = SpatialGrid<SpatialItem>();

      grid.startDragging([]);

      expect(grid.stats.isDragging, isFalse);
    });

    test('updateDraggingObjects updates only dragged items', () {
      final grid = SpatialGrid<SpatialItem>();
      const item1 = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );
      const item2 = NodeSpatialItem(
        nodeId: 'node-2',
        bounds: Rect.fromLTWH(200, 200, 100, 100),
      );

      grid.addOrUpdate(item1);
      grid.addOrUpdate(item2);
      grid.flushPendingUpdates();
      grid.startDragging(['node_node-1']);

      // Update the dragged item's position
      const updatedItem1 = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
      );
      grid.updateDraggingObjects([updatedItem1]);

      final retrieved = grid.getObject('node_node-1') as NodeSpatialItem;
      expect(retrieved.bounds, equals(const Rect.fromLTWH(50, 50, 100, 100)));

      grid.endDragging();
    });

    test('updateDraggingObjects does nothing when not dragging', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // Try to update without starting drag
      const updatedItem = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(50, 50, 100, 100),
      );
      grid.updateDraggingObjects([updatedItem]);

      final retrieved = grid.getObject('node_node-1') as NodeSpatialItem;
      // Should still have original bounds since drag not started
      expect(retrieved.bounds, equals(const Rect.fromLTWH(0, 0, 100, 100)));
    });

    test('endDragging rebuilds spatial index for dragged objects', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();
      grid.startDragging(['node_node-1']);

      // Move item to a different cell
      const updatedItem = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(200, 200, 50, 50),
      );
      grid.updateDraggingObjects([updatedItem]);
      grid.endDragging();

      // Query should find item at new location
      final result = grid.query(const Rect.fromLTWH(150, 150, 100, 100));
      expect(result, hasLength(1));
    });
  });

  group('Caching Behavior', () {
    test('repeated identical queries use cache', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(100, 100, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // First query
      const queryBounds = Rect.fromLTWH(0, 0, 500, 500);
      grid.query(queryBounds);
      final cachedSize = grid.stats.cacheSize;

      // Second identical query should use cache
      grid.query(queryBounds);
      expect(grid.stats.cacheSize, equals(cachedSize));
    });

    test('cache disabled prevents caching', () {
      final grid = SpatialGrid<SpatialItem>(enableCaching: false);
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(100, 100, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      grid.query(const Rect.fromLTWH(0, 0, 500, 500));

      expect(grid.stats.cacheSize, equals(0));
    });

    test('adding item invalidates cache', () {
      final grid = SpatialGrid<SpatialItem>();
      const item1 = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(100, 100, 50, 50),
      );
      const item2 = NodeSpatialItem(
        nodeId: 'node-2',
        bounds: Rect.fromLTWH(200, 200, 50, 50),
      );

      grid.addOrUpdate(item1);
      grid.flushPendingUpdates();
      grid.query(const Rect.fromLTWH(0, 0, 500, 500));

      final cacheBeforeAdd = grid.stats.cacheSize;
      expect(cacheBeforeAdd, greaterThan(0));

      grid.addOrUpdate(item2);
      grid.flushPendingUpdates();

      expect(grid.stats.cacheSize, equals(0));
    });

    test('removing item invalidates cache', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(100, 100, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();
      grid.query(const Rect.fromLTWH(0, 0, 500, 500));

      expect(grid.stats.cacheSize, greaterThan(0));

      grid.remove('node_node-1');

      expect(grid.stats.cacheSize, equals(0));
    });
  });

  group('Edge Cases', () {
    group('Empty Grid', () {
      test('getObject returns null for any id', () {
        final grid = SpatialGrid<SpatialItem>();

        expect(grid.getObject('any-id'), isNull);
      });

      test('objects is empty iterable', () {
        final grid = SpatialGrid<SpatialItem>();

        expect(grid.objects, isEmpty);
      });

      test('isUsingSpatialGrid is false', () {
        final grid = SpatialGrid<SpatialItem>();

        expect(grid.isUsingSpatialGrid, isFalse);
      });

      test('activeCellKeys is empty', () {
        final grid = SpatialGrid<SpatialItem>();

        expect(grid.activeCellKeys, isEmpty);
      });
    });

    group('Overlapping Entries', () {
      test('handles completely overlapping items', () {
        final grid = SpatialGrid<SpatialItem>();
        const item1 = NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        );
        const item2 = NodeSpatialItem(
          nodeId: 'node-2',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        );

        grid.addOrUpdate(item1);
        grid.addOrUpdate(item2);
        grid.flushPendingUpdates();

        expect(grid.objectCount, equals(2));

        final result = grid.queryPoint(const Offset(50, 50));
        expect(result, hasLength(2));
      });

      test('handles partially overlapping items', () {
        final grid = SpatialGrid<SpatialItem>();
        const item1 = NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        );
        const item2 = NodeSpatialItem(
          nodeId: 'node-2',
          bounds: Rect.fromLTWH(50, 50, 100, 100),
        );
        const item3 = NodeSpatialItem(
          nodeId: 'node-3',
          bounds: Rect.fromLTWH(100, 100, 100, 100),
        );

        grid.addOrUpdate(item1);
        grid.addOrUpdate(item2);
        grid.addOrUpdate(item3);
        grid.flushPendingUpdates();

        // Point in overlap of item1 and item2
        final result = grid.queryPoint(const Offset(75, 75));
        expect(result, hasLength(2));
      });

      test('item spanning many cells is found correctly', () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 50.0);
        // Item spans 4x4 = 16 cells
        const item = NodeSpatialItem(
          nodeId: 'large',
          bounds: Rect.fromLTWH(0, 0, 200, 200),
        );

        grid.addOrUpdate(item);
        grid.flushPendingUpdates();

        // Should be findable from any point within
        expect(grid.queryPoint(const Offset(25, 25)), hasLength(1));
        expect(grid.queryPoint(const Offset(175, 175)), hasLength(1));
        expect(grid.queryPoint(const Offset(100, 100)), hasLength(1));
      });
    });

    group('Boundary Conditions', () {
      test('item at grid cell boundary', () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);
        // Item exactly at cell boundary
        const item = NodeSpatialItem(
          nodeId: 'boundary',
          bounds: Rect.fromLTWH(100, 100, 50, 50),
        );

        grid.addOrUpdate(item);
        grid.flushPendingUpdates();

        final result = grid.queryPoint(const Offset(125, 125));
        expect(result, hasLength(1));
      });

      test('item with zero size', () {
        final grid = SpatialGrid<SpatialItem>();
        const item = NodeSpatialItem(
          nodeId: 'zero-size',
          bounds: Rect.fromLTWH(100, 100, 0, 0),
        );

        grid.addOrUpdate(item);
        grid.flushPendingUpdates();

        expect(grid.objectCount, equals(1));
        // Zero-size bounds can't contain any point
        final result = grid.queryPoint(const Offset(100, 100));
        expect(result, isEmpty);
      });

      test('very large item across many cells', () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);
        const item = NodeSpatialItem(
          nodeId: 'huge',
          bounds: Rect.fromLTWH(-1000, -1000, 3000, 3000),
        );

        grid.addOrUpdate(item);
        grid.flushPendingUpdates();

        expect(grid.objectCount, equals(1));
        final result = grid.query(const Rect.fromLTWH(0, 0, 100, 100));
        expect(result, hasLength(1));
      });
    });

    group('Negative Coordinates', () {
      test('handles items with negative positions', () {
        final grid = SpatialGrid<SpatialItem>();
        const item = NodeSpatialItem(
          nodeId: 'negative',
          bounds: Rect.fromLTWH(-500, -500, 100, 100),
        );

        grid.addOrUpdate(item);
        grid.flushPendingUpdates();

        final result = grid.queryPoint(const Offset(-450, -450));
        expect(result, hasLength(1));
      });

      test('handles items spanning negative and positive', () {
        final grid = SpatialGrid<SpatialItem>();
        const item = NodeSpatialItem(
          nodeId: 'spanning-origin',
          bounds: Rect.fromLTWH(-50, -50, 100, 100),
        );

        grid.addOrUpdate(item);
        grid.flushPendingUpdates();

        expect(grid.queryPoint(const Offset(-25, -25)), hasLength(1));
        expect(grid.queryPoint(const Offset(25, 25)), hasLength(1));
      });
    });
  });

  group('countWhere', () {
    test('counts items matching predicate', () {
      final grid = SpatialGrid<SpatialItem>();

      grid.addOrUpdate(
        const NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        ),
      );
      grid.addOrUpdate(
        const PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.fromLTWH(95, 45, 20, 20),
        ),
      );
      grid.addOrUpdate(
        const PortSpatialItem(
          portId: 'port-2',
          nodeId: 'node-1',
          isOutput: false,
          bounds: Rect.fromLTWH(-5, 45, 20, 20),
        ),
      );
      grid.flushPendingUpdates();

      final nodeCount = grid.countWhere((item) => item is NodeSpatialItem);
      final portCount = grid.countWhere((item) => item is PortSpatialItem);
      final outputPortCount = grid.countWhere(
        (item) => item is PortSpatialItem && item.isOutput,
      );

      expect(nodeCount, equals(1));
      expect(portCount, equals(2));
      expect(outputPortCount, equals(1));
    });

    test('returns zero when no items match', () {
      final grid = SpatialGrid<SpatialItem>();

      grid.addOrUpdate(
        const NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        ),
      );
      grid.flushPendingUpdates();

      final count = grid.countWhere((item) => item is ConnectionSegmentItem);

      expect(count, equals(0));
    });
  });

  group('Debug Utilities', () {
    group('parseCellKey', () {
      test('parses positive cell coordinates', () {
        final (x, y) = SpatialGrid.parseCellKey('5_3');

        expect(x, equals(5));
        expect(y, equals(3));
      });

      test('parses zero cell coordinates', () {
        final (x, y) = SpatialGrid.parseCellKey('0_0');

        expect(x, equals(0));
        expect(y, equals(0));
      });

      test('parses negative cell coordinates', () {
        final (x, y) = SpatialGrid.parseCellKey('-2_-5');

        expect(x, equals(-2));
        expect(y, equals(-5));
      });
    });

    group('cellBounds', () {
      test('returns correct bounds for cell at origin', () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);

        final bounds = grid.cellBounds(0, 0);

        expect(bounds, equals(const Rect.fromLTWH(0, 0, 100, 100)));
      });

      test('returns correct bounds for positive cell', () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);

        final bounds = grid.cellBounds(2, 3);

        expect(bounds, equals(const Rect.fromLTWH(200, 300, 100, 100)));
      });

      test('returns correct bounds for negative cell', () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);

        final bounds = grid.cellBounds(-1, -2);

        expect(bounds, equals(const Rect.fromLTWH(-100, -200, 100, 100)));
      });
    });

    group('getObjectCountInCell', () {
      test('returns zero for non-existent cell', () {
        final grid = SpatialGrid<SpatialItem>();

        expect(grid.getObjectCountInCell('99_99'), equals(0));
      });

      test('returns correct count for populated cell', () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);

        grid.addOrUpdate(
          const NodeSpatialItem(
            nodeId: 'node-1',
            bounds: Rect.fromLTWH(10, 10, 30, 30),
          ),
        );
        grid.addOrUpdate(
          const NodeSpatialItem(
            nodeId: 'node-2',
            bounds: Rect.fromLTWH(50, 50, 30, 30),
          ),
        );
        grid.flushPendingUpdates();

        expect(grid.getObjectCountInCell('0_0'), equals(2));
      });
    });

    group('getActiveCellsInfo', () {
      test('returns empty for empty grid', () {
        final grid = SpatialGrid<SpatialItem>();

        expect(grid.getActiveCellsInfo(), isEmpty);
      });

      test('returns cell info with type breakdown', () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 200.0);

        grid.addOrUpdate(
          const NodeSpatialItem(
            nodeId: 'node-1',
            bounds: Rect.fromLTWH(10, 10, 50, 50),
          ),
        );
        grid.addOrUpdate(
          const PortSpatialItem(
            portId: 'port-1',
            nodeId: 'node-1',
            isOutput: true,
            bounds: Rect.fromLTWH(55, 30, 20, 20),
          ),
        );
        grid.addOrUpdate(
          const ConnectionSegmentItem(
            connectionId: 'conn-1',
            segmentIndex: 0,
            bounds: Rect.fromLTWH(75, 40, 100, 10),
          ),
        );
        grid.flushPendingUpdates();

        final cellsInfo = grid.getActiveCellsInfo();

        expect(cellsInfo, hasLength(1));
        expect(cellsInfo.first.nodeCount, equals(1));
        expect(cellsInfo.first.portCount, equals(1));
        expect(cellsInfo.first.connectionCount, equals(1));
        expect(cellsInfo.first.totalCount, equals(3));
        expect(cellsInfo.first.isEmpty, isFalse);
      });

      test('typeBreakdown returns compact string', () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 200.0);

        grid.addOrUpdate(
          const NodeSpatialItem(
            nodeId: 'node-1',
            bounds: Rect.fromLTWH(10, 10, 50, 50),
          ),
        );
        grid.addOrUpdate(
          const NodeSpatialItem(
            nodeId: 'node-2',
            bounds: Rect.fromLTWH(70, 10, 50, 50),
          ),
        );
        grid.flushPendingUpdates();

        final cellsInfo = grid.getActiveCellsInfo();
        expect(cellsInfo.first.typeBreakdown, equals('n:2'));
      });
    });

    group('diagnoseConsistency', () {
      test('shows consistent state for properly indexed items', () {
        final grid = SpatialGrid<SpatialItem>();

        grid.addOrUpdate(
          const NodeSpatialItem(
            nodeId: 'node-1',
            bounds: Rect.fromLTWH(0, 0, 100, 100),
          ),
        );
        grid.addOrUpdate(
          const NodeSpatialItem(
            nodeId: 'node-2',
            bounds: Rect.fromLTWH(200, 200, 100, 100),
          ),
        );
        grid.flushPendingUpdates();

        final diag = grid.diagnoseConsistency();

        expect(diag.objectsCount, equals(2));
        expect(diag.spatialGridItemCount, equals(2));
        expect(diag.pendingCount, equals(0));
        expect(diag.missingFromGrid, isEmpty);
      });

      test('shows pending items before flush', () {
        final grid = SpatialGrid<SpatialItem>();

        grid.addOrUpdate(
          const NodeSpatialItem(
            nodeId: 'node-1',
            bounds: Rect.fromLTWH(0, 0, 100, 100),
          ),
        );
        // Don't flush

        final diag = grid.diagnoseConsistency();

        expect(diag.objectsCount, equals(1));
        expect(diag.pendingCount, greaterThan(0));
      });
    });
  });

  group('SpatialIndexStats', () {
    test('toString includes all fields', () {
      const stats = SpatialIndexStats(
        objectCount: 10,
        gridCellCount: 5,
        isDragging: true,
        draggingObjectCount: 2,
        cacheSize: 8,
      );

      final str = stats.toString();

      expect(str, contains('objects: 10'));
      expect(str, contains('gridCells: 5'));
      expect(str, contains('dragging: true'));
      expect(str, contains('draggingObjects: 2'));
      expect(str, contains('cacheSize: 8'));
    });
  });

  group('CellDebugInfo', () {
    test('isEmpty returns true for zero counts', () {
      const info = CellDebugInfo(
        bounds: Rect.zero,
        cellX: 0,
        cellY: 0,
        nodeCount: 0,
        portCount: 0,
        connectionCount: 0,
      );

      expect(info.isEmpty, isTrue);
      expect(info.totalCount, equals(0));
    });

    test('isEmpty returns false for non-zero counts', () {
      const info = CellDebugInfo(
        bounds: Rect.zero,
        cellX: 0,
        cellY: 0,
        nodeCount: 1,
        portCount: 0,
        connectionCount: 0,
      );

      expect(info.isEmpty, isFalse);
      expect(info.totalCount, equals(1));
    });

    test('totalCount sums all type counts', () {
      const info = CellDebugInfo(
        bounds: Rect.zero,
        cellX: 0,
        cellY: 0,
        nodeCount: 3,
        portCount: 5,
        connectionCount: 2,
      );

      expect(info.totalCount, equals(10));
    });

    test('typeBreakdown shows only non-zero counts', () {
      const infoNodesOnly = CellDebugInfo(
        bounds: Rect.zero,
        cellX: 0,
        cellY: 0,
        nodeCount: 2,
        portCount: 0,
        connectionCount: 0,
      );
      const infoAll = CellDebugInfo(
        bounds: Rect.zero,
        cellX: 0,
        cellY: 0,
        nodeCount: 1,
        portCount: 2,
        connectionCount: 3,
      );
      const infoEmpty = CellDebugInfo(
        bounds: Rect.zero,
        cellX: 0,
        cellY: 0,
        nodeCount: 0,
        portCount: 0,
        connectionCount: 0,
      );

      expect(infoNodesOnly.typeBreakdown, equals('n:2'));
      expect(infoAll.typeBreakdown, equals('n:1 p:2 c:3'));
      expect(infoEmpty.typeBreakdown, equals(''));
    });
  });

  group('Large Scale Performance', () {
    test('handles 100+ objects efficiently', () {
      final grid = SpatialGrid<SpatialItem>();

      // Add 100 nodes
      for (var i = 0; i < 100; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(
              (i % 10) * 150.0,
              (i ~/ 10) * 150.0,
              100,
              100,
            ),
          ),
        );
      }
      grid.flushPendingUpdates();

      expect(grid.objectCount, equals(100));
      expect(grid.isUsingSpatialGrid, isTrue);

      // Query should still work
      final result = grid.query(const Rect.fromLTWH(0, 0, 500, 500));
      expect(result.isNotEmpty, isTrue);
    });

    test('spatial grid is used for large object counts', () {
      final grid = SpatialGrid<SpatialItem>();

      // Add 51 objects to trigger spatial grid usage
      for (var i = 0; i < 51; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 20.0, 0, 15, 15),
          ),
        );
      }
      grid.flushPendingUpdates();

      expect(grid.isUsingSpatialGrid, isTrue);
    });

    test('direct iteration used for small object counts', () {
      final grid = SpatialGrid<SpatialItem>();

      // Add fewer than 21 objects
      for (var i = 0; i < 15; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 20.0, 0, 15, 15),
          ),
        );
      }
      grid.flushPendingUpdates();

      expect(grid.isUsingSpatialGrid, isFalse);
    });
  });

  group('flushPendingUpdates', () {
    test('processes all pending updates immediately', () {
      final grid = SpatialGrid<SpatialItem>();

      grid.addOrUpdate(
        const NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        ),
      );

      // Before flush, might have pending updates
      grid.flushPendingUpdates();

      // After flush, no pending updates
      final diag = grid.diagnoseConsistency();
      expect(diag.pendingCount, equals(0));
    });

    test('flushPendingUpdates on empty grid does nothing', () {
      final grid = SpatialGrid<SpatialItem>();

      // Should not throw
      grid.flushPendingUpdates();

      expect(grid.objectCount, equals(0));
    });
  });

  group('Dragging with immediate updates', () {
    test('addOrUpdate during dragging updates spatial index immediately', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();
      grid.startDragging(['node_node-1']);

      // Update the item while dragging - should update immediately
      const updatedItem = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(300, 300, 50, 50),
      );
      grid.addOrUpdate(updatedItem);

      // Check that the item was updated immediately (no pending updates)
      // The item should be findable at its new location
      final retrieved = grid.getObject('node_node-1') as NodeSpatialItem;
      expect(retrieved.bounds, equals(const Rect.fromLTWH(300, 300, 50, 50)));

      grid.endDragging();
    });

    test('endDragging when not dragging does nothing', () {
      final grid = SpatialGrid<SpatialItem>();
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // Should not throw or cause issues
      grid.endDragging();

      expect(grid.stats.isDragging, isFalse);
      expect(grid.objectCount, equals(1));
    });

    test(
      'endDragging rebuilds index only for existing dragged objects gracefully',
      () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);
        const item = NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(0, 0, 50, 50),
        );

        grid.addOrUpdate(item);
        grid.flushPendingUpdates();

        // Start dragging with an ID that includes a non-existent object
        grid.startDragging(['node_node-1', 'node_non-existent']);

        // End dragging - should handle non-existent object gracefully
        grid.endDragging();

        expect(grid.stats.isDragging, isFalse);
        expect(grid.objectCount, equals(1));
      },
    );
  });

  group('Query with surgical cache during dragging', () {
    test('uses surgical cache for minor panning during drag', () {
      final grid = SpatialGrid<SpatialItem>();

      // Add enough items to populate cache
      for (var i = 0; i < 10; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 50.0, i * 50.0, 40, 40),
          ),
        );
      }
      grid.flushPendingUpdates();

      // Initial query to populate cache
      grid.query(const Rect.fromLTWH(0, 0, 500, 500));
      expect(grid.stats.cacheSize, greaterThan(0));

      // Start dragging
      grid.startDragging(['node_node-0']);

      // Query with slightly different bounds (minor pan < 50px)
      final result = grid.query(const Rect.fromLTWH(10, 10, 500, 500));

      // Should still find items
      expect(result.isNotEmpty, isTrue);

      grid.endDragging();
    });

    test('uses surgical cache for larger movements during drag', () {
      final grid = SpatialGrid<SpatialItem>();

      // Add items
      for (var i = 0; i < 10; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 50.0, i * 50.0, 40, 40),
          ),
        );
      }
      grid.flushPendingUpdates();

      // Initial query to populate cache
      grid.query(const Rect.fromLTWH(0, 0, 500, 500));

      // Start dragging
      grid.startDragging(['node_node-0']);

      // Query with larger pan (> 100px from center) but still within surgical cache bounds
      final result = grid.query(const Rect.fromLTWH(40, 40, 500, 500));

      expect(result.isNotEmpty, isTrue);

      grid.endDragging();
    });

    test('surgical cache adds newly visible objects at edges', () {
      final grid = SpatialGrid<SpatialItem>();

      // Add items spread out
      for (var i = 0; i < 20; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 30.0, i * 30.0, 25, 25),
          ),
        );
      }
      grid.flushPendingUpdates();

      // Initial query with smaller bounds
      grid.query(const Rect.fromLTWH(0, 0, 300, 300));

      // Start dragging
      grid.startDragging(['node_node-0']);

      // Pan slightly to reveal more items
      final result = grid.query(const Rect.fromLTWH(20, 20, 350, 350));

      // Should find items including potentially new ones at edges
      expect(result.isNotEmpty, isTrue);

      grid.endDragging();
    });
  });

  group('Query cache during dragging with strict tolerance', () {
    test('uses cache during dragging for very similar bounds', () {
      final grid = SpatialGrid<SpatialItem>();

      for (var i = 0; i < 5; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 50.0, 0, 40, 40),
          ),
        );
      }
      grid.flushPendingUpdates();

      // Initial query
      const queryBounds = Rect.fromLTWH(0, 0, 300, 300);
      grid.query(queryBounds);
      final initialCacheSize = grid.stats.cacheSize;

      // Start dragging
      grid.startDragging(['node_node-0']);

      // Query with very similar bounds (within 10px tolerance)
      final result = grid.query(const Rect.fromLTWH(5, 5, 305, 305));

      expect(result.isNotEmpty, isTrue);
      // Cache should still be populated
      expect(grid.stats.cacheSize, equals(initialCacheSize));

      grid.endDragging();
    });

    test('does not use cache during dragging for different bounds', () {
      final grid = SpatialGrid<SpatialItem>();

      for (var i = 0; i < 5; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 50.0, 0, 40, 40),
          ),
        );
      }
      grid.flushPendingUpdates();

      // Initial query
      grid.query(const Rect.fromLTWH(0, 0, 300, 300));

      // Start dragging
      grid.startDragging(['node_node-0']);

      // Query with bounds that differ by more than 10px
      // This should trigger surgical cache path instead of direct cache
      grid.query(const Rect.fromLTWH(15, 15, 315, 315));

      grid.endDragging();
    });
  });

  group('Large area spatial grid query', () {
    test('queryWithSpatialGrid handles large cell count efficiently', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 50.0);

      // Add more than 50 items to trigger spatial grid usage
      for (var i = 0; i < 60; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH((i % 10) * 60.0, (i ~/ 10) * 60.0, 40, 40),
          ),
        );
      }
      grid.flushPendingUpdates();

      expect(grid.isUsingSpatialGrid, isTrue);

      // Query a large area that spans more than 4 cells (triggers large area code path)
      // With gridSize=50, a 400x400 query spans 8x8=64 cells
      final result = grid.query(const Rect.fromLTWH(0, 0, 400, 400));

      expect(result.isNotEmpty, isTrue);
    });

    test(
      'queryWithSpatialGrid handles small cell count with simple iteration',
      () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 200.0);

        // Add more than 50 items to trigger spatial grid usage
        for (var i = 0; i < 60; i++) {
          grid.addOrUpdate(
            NodeSpatialItem(
              nodeId: 'node-$i',
              bounds: Rect.fromLTWH(i * 10.0, 0, 8, 8),
            ),
          );
        }
        grid.flushPendingUpdates();

        expect(grid.isUsingSpatialGrid, isTrue);

        // Query a small area that spans <= 4 cells
        // With gridSize=200, a 100x100 query spans at most 1-2 cells
        final result = grid.query(const Rect.fromLTWH(0, 0, 100, 100));

        expect(result.isNotEmpty, isTrue);
      },
    );
  });

  group('Spatial rects query path', () {
    test('uses spatial rects for medium object counts', () {
      final grid = SpatialGrid<SpatialItem>();

      // Add between 21 and 50 items to trigger spatial rects path
      for (var i = 0; i < 30; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 20.0, 0, 15, 15),
          ),
        );
      }
      grid.flushPendingUpdates();

      // 30 objects: > 20, so uses spatial rects, but < 51, so not spatial grid
      expect(grid.isUsingSpatialGrid, isFalse);

      final result = grid.query(const Rect.fromLTWH(0, 0, 300, 100));

      expect(result.isNotEmpty, isTrue);
    });
  });

  group('Batch update processing', () {
    test('batch processes updates when threshold is reached', () {
      final grid = SpatialGrid<SpatialItem>();

      // Add 10+ items quickly to trigger batch threshold
      for (var i = 0; i < 12; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 20.0, 0, 15, 15),
          ),
        );
      }

      // The batch should have been processed due to threshold
      // Check that items are in the grid
      expect(grid.objectCount, equals(12));
    });
  });

  group('queryPoint with radius edge cases', () {
    test(
      'queryPoint with radius finds item when point is just outside bounds',
      () {
        final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);
        const item = NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(100, 100, 50, 50),
        );

        grid.addOrUpdate(item);
        grid.flushPendingUpdates();

        // Point is at (95, 125) - just outside left edge of item at x=100
        // With radius of 10, inflated bounds become (90, 90, 70, 70) -> contains (95, 125)
        final result = grid.queryPoint(const Offset(95, 125), radius: 10);

        expect(result, hasLength(1));
      },
    );

    test('queryPoint with large radius finds distant items', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 100.0);
      const item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(200, 200, 50, 50),
      );

      grid.addOrUpdate(item);
      grid.flushPendingUpdates();

      // Point is at (100, 100), item is at (200, 200)
      // Distance from point to nearest edge of item is ~100px
      // With radius 150, should find it
      final result = grid.queryPoint(const Offset(100, 100), radius: 150);

      expect(result, hasLength(1));
    });

    test('queryPoint checks multiple cells when radius spans them', () {
      final grid = SpatialGrid<SpatialItem>(gridSize: 50.0);

      // Place items in different cells
      const item1 = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(10, 10, 20, 20),
      );
      const item2 = NodeSpatialItem(
        nodeId: 'node-2',
        bounds: Rect.fromLTWH(60, 60, 20, 20),
      );

      grid.addOrUpdate(item1);
      grid.addOrUpdate(item2);
      grid.flushPendingUpdates();

      // Query point in between with radius spanning both
      final result = grid.queryPoint(const Offset(40, 40), radius: 50);

      expect(result, hasLength(2));
    });
  });

  group('Surgical cache conditions', () {
    test('surgical cache not used when cache is empty', () {
      final grid = SpatialGrid<SpatialItem>();

      for (var i = 0; i < 5; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 50.0, 0, 40, 40),
          ),
        );
      }
      grid.flushPendingUpdates();

      // Start dragging without prior query (cache is empty)
      grid.startDragging(['node_node-0']);

      // Query - should not use surgical cache since cache is empty
      final result = grid.query(const Rect.fromLTWH(0, 0, 300, 300));

      expect(result.isNotEmpty, isTrue);

      grid.endDragging();
    });

    test('surgical cache not used when bounds differ too much', () {
      final grid = SpatialGrid<SpatialItem>();

      for (var i = 0; i < 10; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 50.0, i * 50.0, 40, 40),
          ),
        );
      }
      grid.flushPendingUpdates();

      // Initial query
      grid.query(const Rect.fromLTWH(0, 0, 300, 300));

      // Start dragging
      grid.startDragging(['node_node-0']);

      // Query with very different bounds (exceeds surgical cache thresholds)
      final result = grid.query(const Rect.fromLTWH(200, 200, 500, 500));

      expect(result.isNotEmpty, isTrue);

      grid.endDragging();
    });
  });

  group('Cache invalidation on caching disabled', () {
    test('cache disabled does not store results', () {
      final grid = SpatialGrid<SpatialItem>(enableCaching: false);

      grid.addOrUpdate(
        const NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        ),
      );
      grid.flushPendingUpdates();

      // Multiple queries
      grid.query(const Rect.fromLTWH(0, 0, 200, 200));
      grid.query(const Rect.fromLTWH(0, 0, 200, 200));

      // Cache should always be 0
      expect(grid.stats.cacheSize, equals(0));
    });

    test('cache disabled still returns correct results', () {
      final grid = SpatialGrid<SpatialItem>(enableCaching: false);

      for (var i = 0; i < 5; i++) {
        grid.addOrUpdate(
          NodeSpatialItem(
            nodeId: 'node-$i',
            bounds: Rect.fromLTWH(i * 50.0, 0, 40, 40),
          ),
        );
      }
      grid.flushPendingUpdates();

      final result = grid.query(const Rect.fromLTWH(0, 0, 250, 100));

      expect(result.length, equals(5));
    });
  });

  group('updateDraggingObjects edge cases', () {
    test('updateDraggingObjects ignores non-dragged objects', () {
      final grid = SpatialGrid<SpatialItem>();
      const item1 = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.fromLTWH(0, 0, 100, 100),
      );
      const item2 = NodeSpatialItem(
        nodeId: 'node-2',
        bounds: Rect.fromLTWH(200, 200, 100, 100),
      );

      grid.addOrUpdate(item1);
      grid.addOrUpdate(item2);
      grid.flushPendingUpdates();

      // Only drag node-1
      grid.startDragging(['node_node-1']);

      // Try to update node-2 via updateDraggingObjects
      const updatedItem2 = NodeSpatialItem(
        nodeId: 'node-2',
        bounds: Rect.fromLTWH(500, 500, 100, 100),
      );
      grid.updateDraggingObjects([updatedItem2]);

      // node-2 should NOT be updated since it's not in dragging set
      final retrieved = grid.getObject('node_node-2') as NodeSpatialItem;
      expect(retrieved.bounds, equals(const Rect.fromLTWH(200, 200, 100, 100)));

      grid.endDragging();
    });
  });
}
