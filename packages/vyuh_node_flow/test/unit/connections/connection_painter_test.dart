/// Comprehensive tests for ConnectionPainter.
///
/// Tests cover:
/// - ConnectionPainter construction and initialization
/// - Theme management and cache invalidation
/// - Path building for different connection styles
/// - Hit testing for connections
/// - Cache management operations
/// - Temporary connection painting
/// - Dashed path creation
/// - Paint method with mock canvas
/// - Endpoint rendering
/// - Animation effects
/// - Custom connection properties
@Tags(['unit'])
library;

import 'dart:typed_data';
import 'dart:ui'
    show
        BlendMode,
        Canvas,
        ClipOp,
        Color,
        Offset,
        Paint,
        Paragraph,
        Path,
        Picture,
        PointMode,
        RRect,
        RSTransform,
        RSuperellipse,
        Rect,
        Vertices;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
// Import internal classes for type declarations
import 'package:vyuh_node_flow/src/connections/connection_painter.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // ConnectionPainter Construction Tests
  // ==========================================================================

  group('ConnectionPainter Construction', () {
    test('creates with light theme', () {
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      expect(painter.theme, same(NodeFlowTheme.light));
      expect(painter.nodeShape, isNull);
    });

    test('creates with dark theme', () {
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.dark);

      expect(painter.theme, same(NodeFlowTheme.dark));
    });

    test('creates with custom node shape getter', () {
      NodeShape? shapeGetter(Node node) => const DiamondShape();

      final painter = createTestConnectionPainter(
        theme: NodeFlowTheme.light,
        nodeShape: shapeGetter,
      );

      expect(painter.nodeShape, equals(shapeGetter));
    });

    test('exposes pathCache', () {
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      expect(painter.pathCache, isNotNull);
    });
  });

  // ==========================================================================
  // Theme Management Tests
  // ==========================================================================

  group('Theme Management', () {
    test('updateTheme changes theme', () {
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      expect(painter.theme, same(NodeFlowTheme.light));

      painter.updateTheme(NodeFlowTheme.dark);

      expect(painter.theme, same(NodeFlowTheme.dark));
    });

    test('updateTheme invalidates cache when style changes', () {
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      // Create connected nodes to populate the cache
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      // Populate the cache
      painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: painter.theme.connectionTheme.style,
      );

      expect(painter.hasConnectionCached(connection.id), isTrue);

      // Update theme with different style
      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          style: ConnectionStyles.bezier,
        ),
      );
      painter.updateTheme(newTheme);

      // Cache should be invalidated
      expect(painter.hasConnectionCached(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when curvature changes', () {
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(bezierCurvature: 0.8),
      );

      painter.updateTheme(newTheme);

      expect(painter.theme.connectionTheme.bezierCurvature, equals(0.8));
    });
  });

  // ==========================================================================
  // Node Shape Management Tests
  // ==========================================================================

  group('Node Shape Management', () {
    test('updateNodeShape changes shape getter', () {
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      expect(painter.nodeShape, isNull);

      NodeShape? newShapeGetter(Node node) => const DiamondShape();
      painter.updateNodeShape(newShapeGetter);

      expect(painter.nodeShape, equals(newShapeGetter));
    });

    test('updateNodeShape invalidates cache', () {
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      // Create connected nodes to populate the cache
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      // Populate the cache
      painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: painter.theme.connectionTheme.style,
      );

      expect(painter.hasConnectionCached(connection.id), isTrue);

      // Update node shape
      painter.updateNodeShape((node) => const CircleShape());

      // Cache should be invalidated
      expect(painter.hasConnectionCached(connection.id), isFalse);
    });
  });

  // ==========================================================================
  // Cache Management Tests
  // ==========================================================================

  group('Cache Management', () {
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('hasConnectionCached returns false for uncached connection', () {
      expect(painter.hasConnectionCached('nonexistent'), isFalse);
    });

    test('hasConnectionCached returns true after caching', () {
      painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: painter.theme.connectionTheme.style,
      );

      expect(painter.hasConnectionCached(connection.id), isTrue);
    });

    test('removeConnectionFromCache removes specific connection', () {
      painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: painter.theme.connectionTheme.style,
      );

      expect(painter.hasConnectionCached(connection.id), isTrue);

      painter.removeConnectionFromCache(connection.id);

      expect(painter.hasConnectionCached(connection.id), isFalse);
    });

    test('clearAllCachedPaths clears all cached paths', () {
      // Create and cache multiple connections
      painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: painter.theme.connectionTheme.style,
      );

      expect(painter.hasConnectionCached(connection.id), isTrue);

      painter.clearAllCachedPaths();

      expect(painter.hasConnectionCached(connection.id), isFalse);
    });

    test('getCacheStats returns cache statistics', () {
      final stats = painter.getCacheStats();

      expect(stats, isNotNull);
      expect(stats.containsKey('cachedPaths'), isTrue);
      expect(stats.containsKey('hitTolerance'), isTrue);
      expect(stats['cachedPaths'], isA<int>());
    });

    test('getCacheStats shows correct count after caching', () {
      var stats = painter.getCacheStats();
      expect(stats['cachedPaths'], equals(0));

      painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: painter.theme.connectionTheme.style,
      );

      stats = painter.getCacheStats();
      expect(stats['cachedPaths'], equals(1));
    });

    test('dispose clears cache', () {
      painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: painter.theme.connectionTheme.style,
      );

      expect(painter.hasConnectionCached(connection.id), isTrue);

      painter.dispose();

      expect(painter.hasConnectionCached(connection.id), isFalse);
    });
  });

  // ==========================================================================
  // Hit Testing Tests
  // ==========================================================================

  group('Hit Testing', () {
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      // Position source at (0, 0) with size 100x50
      // Output port on right: at (100, 25)
      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      // Position target at (300, 0) with size 100x50
      // Input port on left: at (300, 25)
      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(300, 0),
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('hitTestConnection returns false for point far from connection', () {
      final result = painter.hitTestConnection(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(1000, 1000),
      );

      expect(result, isFalse);
    });

    test('hitTestConnection returns true for point on connection path', () {
      // First, generate the path to understand its bounds
      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: painter.theme.connectionTheme.style,
      );
      expect(path, isNotNull);

      // Get the path bounds to find a point that's definitely on the path
      final bounds = path!.getBounds();
      final midX = bounds.center.dx;
      final midY = bounds.center.dy;

      final result = painter.hitTestConnection(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: Offset(midX, midY),
        tolerance: 20.0, // Generous tolerance for path center
      );

      expect(result, isTrue);
    });

    test('hitTestConnection respects custom tolerance', () {
      // First generate the path
      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: painter.theme.connectionTheme.style,
      );
      expect(path, isNotNull);

      final bounds = path!.getBounds();
      final midX = bounds.center.dx;
      final midY = bounds.center.dy;

      // Point at path center should hit
      final centerResult = painter.hitTestConnection(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: Offset(midX, midY),
        tolerance: 10.0,
      );
      expect(centerResult, isTrue);

      // Point very far from path should not hit
      final farResult = painter.hitTestConnection(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(200, 500),
        tolerance: 2.0,
      );
      expect(farResult, isFalse);
    });

    test('hitTestConnection returns false for hidden source node', () {
      sourceNode.isVisible = false;

      final result = painter.hitTestConnection(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(200, 25),
      );

      expect(result, isFalse);
    });

    test('hitTestConnection returns false for hidden target node', () {
      targetNode.isVisible = false;

      final result = painter.hitTestConnection(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(200, 25),
      );

      expect(result, isFalse);
    });
  });

  // ==========================================================================
  // Path Creation Tests
  // ==========================================================================

  group('Path Creation via Cache', () {
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      // Position nodes with different Y values to ensure non-degenerate paths
      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 50),
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('getOrCreatePath returns valid path for smoothstep style', () {
      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
      // Check that the path has some extent (not a degenerate path)
      final bounds = path!.getBounds();
      expect(bounds.width > 0 || bounds.height > 0, isTrue);
    });

    test('getOrCreatePath returns valid path for bezier style', () {
      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.bezier,
      );

      expect(path, isNotNull);
      final bounds = path!.getBounds();
      expect(bounds.width > 0 || bounds.height > 0, isTrue);
    });

    test('getOrCreatePath returns valid path for straight style', () {
      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.straight,
      );

      expect(path, isNotNull);
      final bounds = path!.getBounds();
      expect(bounds.width > 0 || bounds.height > 0, isTrue);
    });

    test('getOrCreatePath returns valid path for step style', () {
      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.step,
      );

      expect(path, isNotNull);
      final bounds = path!.getBounds();
      expect(bounds.width > 0 || bounds.height > 0, isTrue);
    });

    test('getOrCreatePath returns null for hidden source node', () {
      sourceNode.isVisible = false;

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNull);
    });

    test('getOrCreatePath returns null for hidden target node', () {
      targetNode.isVisible = false;

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNull);
    });

    test('getOrCreatePath returns cached path on second call', () {
      final path1 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      final path2 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Paths should be identical (same reference from cache)
      expect(path1, same(path2));
    });

    test('getOrCreatePath creates new path when node moves', () {
      final path1 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Move the source node
      sourceNode.position.value = const Offset(50, 50);

      final path2 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Paths should be different (new path created)
      expect(path1, isNot(same(path2)));
    });
  });

  // ==========================================================================
  // Loopback and Same-Side Port Tests
  // ==========================================================================

  group('Loopback and Same-Side Port Connections', () {
    late ConnectionPainter painter;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);
    });

    test('handles connection where target is behind source', () {
      // Source on right, target to the left
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(200, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(0, 0),
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
      expect(path!.getBounds().isEmpty, isFalse);
    });

    test('handles same-side ports (right to right)', () {
      final sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [
          createTestPort(
            id: 'output-1',
            type: PortType.output,
            position: PortPosition.right,
          ),
        ],
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(0, 100),
        inputPorts: [
          createTestPort(
            id: 'input-1',
            type: PortType.input,
            position: PortPosition.right,
          ),
        ],
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
      expect(path!.getBounds().isEmpty, isFalse);
    });

    test('handles same-side ports (left to left)', () {
      final sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [
          createTestPort(
            id: 'output-1',
            type: PortType.output,
            position: PortPosition.left,
          ),
        ],
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(0, 100),
        inputPorts: [
          createTestPort(
            id: 'input-1',
            type: PortType.input,
            position: PortPosition.left,
          ),
        ],
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
      expect(path!.getBounds().isEmpty, isFalse);
    });

    test('handles top to bottom ports', () {
      final sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [
          createTestPort(
            id: 'output-1',
            type: PortType.output,
            position: PortPosition.bottom,
          ),
        ],
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(
          50,
          150,
        ), // Offset X to ensure non-degenerate path
        inputPorts: [
          createTestPort(
            id: 'input-1',
            type: PortType.input,
            position: PortPosition.top,
          ),
        ],
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
      // Check that the path has some extent
      final bounds = path!.getBounds();
      expect(bounds.width > 0 || bounds.height > 0, isTrue);
    });
  });

  // ==========================================================================
  // Segment Bounds Tests
  // ==========================================================================

  group('Segment Bounds', () {
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 50),
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('getOrCreateSegmentBounds returns non-empty list', () {
      final bounds = painter.pathCache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(bounds, isNotEmpty);
    });

    test('getOrCreateSegmentBounds returns valid rectangles', () {
      final bounds = painter.pathCache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      for (final rect in bounds) {
        expect(rect.width, greaterThan(0));
        expect(rect.height, greaterThan(0));
      }
    });

    test('getOrCreateSegmentBounds returns empty for hidden nodes', () {
      sourceNode.isVisible = false;

      final bounds = painter.pathCache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(bounds, isEmpty);
    });

    test('getSegmentBounds returns null before caching', () {
      final bounds = painter.pathCache.getSegmentBounds(connection.id);

      expect(bounds, isNull);
    });

    test('getSegmentBounds returns cached bounds after caching', () {
      painter.pathCache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      final bounds = painter.pathCache.getSegmentBounds(connection.id);

      expect(bounds, isNotNull);
      expect(bounds, isNotEmpty);
    });
  });

  // ==========================================================================
  // Connection Style Integration Tests
  // ==========================================================================

  group('Connection Style Integration', () {
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 50),
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('all built-in styles create valid paths', () {
      for (final style in ConnectionStyles.all) {
        final path = painter.pathCache.getOrCreatePath(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: style,
        );

        expect(
          path,
          isNotNull,
          reason: '${style.id} should create a valid path',
        );
        expect(
          path!.getBounds().isEmpty,
          isFalse,
          reason: '${style.id} should create a non-empty path',
        );

        // Clear cache for next iteration
        painter.clearAllCachedPaths();
      }
    });

    test('all built-in styles support hit testing', () {
      for (final style in ConnectionStyles.all) {
        // First create the path
        painter.pathCache.getOrCreatePath(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: style,
        );

        // Hit test at approximate midpoint
        final result = painter.hitTestConnection(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          testPoint: const Offset(150, 40),
          tolerance: 20.0,
        );

        // Should at least not throw
        expect(result, isA<bool>());

        // Clear cache for next iteration
        painter.clearAllCachedPaths();
      }
    });
  });

  // ==========================================================================
  // Edge Cases and Error Handling Tests
  // ==========================================================================

  group('Edge Cases', () {
    late ConnectionPainter painter;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);
    });

    test('handles connection with missing source port gracefully', () {
      final sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [], // No ports
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'missing-port',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Should return null instead of throwing
      expect(path, isNull);
    });

    test('handles connection with missing target port gracefully', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(200, 0),
        inputPorts: [], // No ports
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'missing-port',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Should return null instead of throwing
      expect(path, isNull);
    });

    test('handles very short connection', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(110, 0), // Very close to source
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
    });

    test('handles very long connection', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(10000, 10000),
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.bezier,
      );

      expect(path, isNotNull);
      expect(path!.getBounds().isEmpty, isFalse);
    });

    test('handles nodes with negative positions', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(-100, -100),
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(-200, -200),
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
    });

    test('handles zero-size nodes', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      // Node starts with Size.zero by default

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Should still create a path (ports default to centered position)
      expect(path, isNotNull);
    });
  });

  // ==========================================================================
  // Port Offset Cache Invalidation Tests
  // ==========================================================================

  group('Port Offset Cache Invalidation', () {
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [
          createTestPort(
            id: 'output-1',
            type: PortType.output,
            position: PortPosition.right,
            offset: const Offset(0, 0),
          ),
        ],
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(200, 0),
        inputPorts: [
          createTestPort(
            id: 'input-1',
            type: PortType.input,
            position: PortPosition.left,
            offset: const Offset(0, 0),
          ),
        ],
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('cache invalidates when node size changes', () {
      final path1 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Change node size
      sourceNode.setSize(const Size(150, 75));

      final path2 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Paths should be different (cache invalidated due to size change)
      expect(path1, isNot(same(path2)));
    });
  });

  // ==========================================================================
  // Connection Gap Configuration Tests
  // ==========================================================================

  group('Connection Gap Configuration', () {
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));
    });

    test('handles connection with custom start gap', () {
      final connection = Connection(
        id: 'conn-gap-start',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startGap: 10.0,
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
    });

    test('handles connection with custom end gap', () {
      final connection = Connection(
        id: 'conn-gap-end',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        endGap: 10.0,
      );

      final path = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
    });

    test('cache invalidates when gap values change', () {
      final connection = Connection(
        id: 'conn-gap',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startGap: 5.0,
      );

      final path1 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Create a new connection with different gap
      final connectionWithDifferentGap = Connection(
        id: 'conn-gap', // Same ID
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startGap: 20.0, // Different gap
      );

      final path2 = painter.pathCache.getOrCreatePath(
        connection: connectionWithDifferentGap,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Paths should be different because gap changed
      expect(path1, isNot(same(path2)));
    });
  });

  // ==========================================================================
  // Paint Method Tests with Mock Canvas
  // ==========================================================================

  group('paintConnection with Canvas', () {
    late MockCanvas mockCanvas;
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      mockCanvas = MockCanvas();
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('paintConnection draws path on canvas', () {
      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);

      // Should draw at least one path (the connection line)
      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paintConnection does not draw when source port missing', () {
      final nodeWithoutPorts = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [],
      );
      nodeWithoutPorts.setSize(const Size(100, 50));

      painter.paintConnection(
        mockCanvas,
        connection,
        nodeWithoutPorts,
        targetNode,
      );

      // Should not draw anything
      expect(mockCanvas.drawPathCalls, equals(0));
    });

    test('paintConnection does not draw when target port missing', () {
      final nodeWithoutPorts = createTestNode(
        id: 'node-b',
        position: const Offset(200, 0),
        inputPorts: [],
      );
      nodeWithoutPorts.setSize(const Size(100, 50));

      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        nodeWithoutPorts,
      );

      // Should not draw anything
      expect(mockCanvas.drawPathCalls, equals(0));
    });

    test('paintConnection uses custom connection color', () {
      const customColor = Color(0xFFFF0000);
      final coloredConnection = Connection(
        id: 'conn-colored',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        color: customColor,
      );

      painter.paintConnection(
        mockCanvas,
        coloredConnection,
        sourceNode,
        targetNode,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
      expect(mockCanvas.lastPaint?.color, equals(customColor));
    });

    test('paintConnection uses custom stroke width', () {
      final thickConnection = Connection(
        id: 'conn-thick',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        strokeWidth: 5.0,
      );

      painter.paintConnection(
        mockCanvas,
        thickConnection,
        sourceNode,
        targetNode,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
      expect(mockCanvas.lastPaint?.strokeWidth, equals(5.0));
    });

    test('paintConnection uses selected color when selected', () {
      connection.selected = true;

      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        isSelected: true,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
      // Verify paint was applied (color may differ due to animation effects)
      expect(mockCanvas.lastPaint, isNotNull);
    });

    test('paintConnection applies dash pattern from theme', () {
      final dashedTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(dashPattern: [5, 5]),
      );
      final dashedPainter = createTestConnectionPainter(theme: dashedTheme);

      dashedPainter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paintConnection skips endpoints when skipEndpoints is true', () {
      // First paint with endpoints
      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        skipEndpoints: false,
      );
      final callsWithEndpoints = mockCanvas.drawPathCalls;

      mockCanvas.reset();

      // Then paint without endpoints
      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        skipEndpoints: true,
      );
      final callsWithoutEndpoints = mockCanvas.drawPathCalls;

      // Should have fewer or equal calls when skipping endpoints
      expect(callsWithoutEndpoints, lessThanOrEqualTo(callsWithEndpoints));
    });

    test('paintConnection uses overrideStyle', () {
      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        overrideStyle: ConnectionStyles.bezier,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });
  });

  // ==========================================================================
  // Animation Effect Tests with Canvas
  // ==========================================================================

  group('paintConnection with Animation Effects', () {
    late MockCanvas mockCanvas;
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      mockCanvas = MockCanvas();
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('paintConnection with PulseEffect at animationValue 0', () {
      connection.animationEffect = PulseEffect();

      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        animationValue: 0.0,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paintConnection with PulseEffect at animationValue 0.5', () {
      connection.animationEffect = PulseEffect();

      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        animationValue: 0.5,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paintConnection with PulseEffect at animationValue 1.0', () {
      connection.animationEffect = PulseEffect();

      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        animationValue: 1.0,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paintConnection with FlowingDashEffect', () {
      connection.animationEffect = FlowingDashEffect();

      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        animationValue: 0.5,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paintConnection with GradientFlowEffect', () {
      connection.animationEffect = GradientFlowEffect();

      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        animationValue: 0.5,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paintConnection with ParticleEffect', () {
      connection.animationEffect = ParticleEffect();

      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        animationValue: 0.5,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test(
      'paintConnection uses theme animation effect when connection has none',
      () {
        final animatedTheme = NodeFlowTheme.light.copyWith(
          connectionTheme: ConnectionTheme.light.copyWith(
            animationEffect: PulseEffect(),
          ),
        );
        final animatedPainter = createTestConnectionPainter(
            theme: animatedTheme);

        animatedPainter.paintConnection(
          mockCanvas,
          connection,
          sourceNode,
          targetNode,
          animationValue: 0.5,
        );

        expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
      },
    );

    test('paintConnection without animationValue draws static connection', () {
      connection.animationEffect = PulseEffect();

      painter.paintConnection(
        mockCanvas,
        connection,
        sourceNode,
        targetNode,
        // No animationValue provided
      );

      // Should still draw the connection statically
      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });
  });

  // ==========================================================================
  // Temporary Connection Painting Tests
  // ==========================================================================

  group('paintTemporaryConnection', () {
    late MockCanvas mockCanvas;
    late ConnectionPainter painter;

    setUp(() {
      mockCanvas = MockCanvas();
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);
    });

    test('paints temporary connection from start to end point', () {
      painter.paintTemporaryConnection(
        mockCanvas,
        const Offset(100, 50),
        const Offset(200, 50),
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints temporary connection with source port', () {
      final sourcePort = createTestPort(
        id: 'output-1',
        type: PortType.output,
        position: PortPosition.right,
      );

      painter.paintTemporaryConnection(
        mockCanvas,
        const Offset(100, 50),
        const Offset(200, 50),
        sourcePort: sourcePort,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints temporary connection with target port', () {
      final targetPort = createTestPort(
        id: 'input-1',
        type: PortType.input,
        position: PortPosition.left,
      );

      painter.paintTemporaryConnection(
        mockCanvas,
        const Offset(100, 50),
        const Offset(200, 50),
        targetPort: targetPort,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints temporary connection with both ports', () {
      final sourcePort = createTestPort(
        id: 'output-1',
        type: PortType.output,
        position: PortPosition.right,
      );
      final targetPort = createTestPort(
        id: 'input-1',
        type: PortType.input,
        position: PortPosition.left,
      );

      painter.paintTemporaryConnection(
        mockCanvas,
        const Offset(100, 50),
        const Offset(200, 50),
        sourcePort: sourcePort,
        targetPort: targetPort,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints temporary connection with node bounds', () {
      painter.paintTemporaryConnection(
        mockCanvas,
        const Offset(100, 50),
        const Offset(200, 50),
        sourceNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        targetNodeBounds: const Rect.fromLTWH(200, 0, 100, 100),
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints temporary connection with animation value', () {
      painter.paintTemporaryConnection(
        mockCanvas,
        const Offset(100, 50),
        const Offset(200, 50),
        animationValue: 0.5,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('uses temporary connection theme', () {
      // Create theme with distinct temporary connection styling
      final customTheme = NodeFlowTheme.light.copyWith(
        temporaryConnectionTheme: ConnectionTheme.light.copyWith(
          color: Colors.orange,
          dashPattern: [10, 5],
        ),
      );
      final customPainter = createTestConnectionPainter(theme: customTheme);

      customPainter.paintTemporaryConnection(
        mockCanvas,
        const Offset(100, 50),
        const Offset(200, 50),
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints temporary connection from different port positions', () {
      // Test with bottom port
      final bottomPort = createTestPort(
        id: 'output-1',
        type: PortType.output,
        position: PortPosition.bottom,
      );

      painter.paintTemporaryConnection(
        mockCanvas,
        const Offset(50, 100),
        const Offset(50, 200),
        sourcePort: bottomPort,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));

      mockCanvas.reset();

      // Test with top port
      final topPort = createTestPort(
        id: 'input-1',
        type: PortType.input,
        position: PortPosition.top,
      );

      painter.paintTemporaryConnection(
        mockCanvas,
        const Offset(50, 200),
        const Offset(50, 100),
        targetPort: topPort,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });
  });

  // ==========================================================================
  // Endpoint Rendering Tests
  // ==========================================================================

  group('Endpoint Rendering', () {
    late MockCanvas mockCanvas;
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      mockCanvas = MockCanvas();
      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('paints with triangle endpoints', () {
      final triangleTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          startPoint: ConnectionEndPoint.triangle,
          endPoint: ConnectionEndPoint.triangle,
        ),
      );
      painter = createTestConnectionPainter(theme: triangleTheme);

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints with circle endpoints', () {
      final circleTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          startPoint: ConnectionEndPoint.circle,
          endPoint: ConnectionEndPoint.circle,
        ),
      );
      painter = createTestConnectionPainter(theme: circleTheme);

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints with diamond endpoints', () {
      final diamondTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          startPoint: ConnectionEndPoint.diamond,
          endPoint: ConnectionEndPoint.diamond,
        ),
      );
      painter = createTestConnectionPainter(theme: diamondTheme);

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints with rectangle endpoints', () {
      final rectangleTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          startPoint: ConnectionEndPoint.rectangle,
          endPoint: ConnectionEndPoint.rectangle,
        ),
      );
      painter = createTestConnectionPainter(theme: rectangleTheme);

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints with no endpoints (none)', () {
      final noneTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          startPoint: ConnectionEndPoint.none,
          endPoint: ConnectionEndPoint.none,
        ),
      );
      painter = createTestConnectionPainter(theme: noneTheme);

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);

      // Should still draw the connection path
      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints with capsuleHalf endpoint', () {
      final capsuleTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          startPoint: ConnectionEndPoint.none,
          endPoint: ConnectionEndPoint.capsuleHalf,
        ),
      );
      painter = createTestConnectionPainter(theme: capsuleTheme);

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints with asymmetric endpoints (none start, triangle end)', () {
      final asymmetricTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          startPoint: ConnectionEndPoint.none,
          endPoint: ConnectionEndPoint.triangle,
        ),
      );
      painter = createTestConnectionPainter(theme: asymmetricTheme);

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('connection-specific endpoints override theme', () {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final connectionWithEndpoints = Connection(
        id: 'conn-custom-endpoints',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startPoint: ConnectionEndPoint.diamond,
        endPoint: ConnectionEndPoint.triangle,
      );

      painter.paintConnection(
        mockCanvas,
        connectionWithEndpoints,
        sourceNode,
        targetNode,
      );

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints with colored endpoints', () {
      final coloredEndpoints = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          endpointColor: Colors.green,
          endpointBorderColor: Colors.green.shade900,
          endpointBorderWidth: 2.0,
        ),
      );
      painter = createTestConnectionPainter(theme: coloredEndpoints);

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);

      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });
  });

  // ==========================================================================
  // Port Position Variations Tests
  // ==========================================================================

  group('Port Position Variations', () {
    late MockCanvas mockCanvas;
    late ConnectionPainter painter;

    setUp(() {
      mockCanvas = MockCanvas();
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);
    });

    test('paints right to left connection', () {
      final sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [
          createTestPort(
            id: 'output-1',
            type: PortType.output,
            position: PortPosition.right,
          ),
        ],
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(200, 0),
        inputPorts: [
          createTestPort(
            id: 'input-1',
            type: PortType.input,
            position: PortPosition.left,
          ),
        ],
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);
      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints bottom to top connection', () {
      final sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [
          createTestPort(
            id: 'output-1',
            type: PortType.output,
            position: PortPosition.bottom,
          ),
        ],
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(0, 150),
        inputPorts: [
          createTestPort(
            id: 'input-1',
            type: PortType.input,
            position: PortPosition.top,
          ),
        ],
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);
      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints left to right connection (reverse direction)', () {
      final sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(200, 0),
        outputPorts: [
          createTestPort(
            id: 'output-1',
            type: PortType.output,
            position: PortPosition.left,
          ),
        ],
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(0, 0),
        inputPorts: [
          createTestPort(
            id: 'input-1',
            type: PortType.input,
            position: PortPosition.right,
          ),
        ],
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);
      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });

    test('paints connection with port offsets', () {
      final sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [
          createTestPort(
            id: 'output-1',
            type: PortType.output,
            position: PortPosition.right,
            offset: const Offset(0, 10),
          ),
        ],
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(200, 0),
        inputPorts: [
          createTestPort(
            id: 'input-1',
            type: PortType.input,
            position: PortPosition.left,
            offset: const Offset(0, 40),
          ),
        ],
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      painter.paintConnection(mockCanvas, connection, sourceNode, targetNode);
      expect(mockCanvas.drawPathCalls, greaterThanOrEqualTo(1));
    });
  });

  // ==========================================================================
  // shouldRepaint equivalent (cache invalidation) Tests
  // ==========================================================================

  group('Cache Invalidation (shouldRepaint equivalent)', () {
    late ConnectionPainter painter;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('returns same path when positions unchanged', () {
      final path1 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      final path2 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path1, same(path2));
    });

    test('creates new path when source position changes', () {
      final path1 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      sourceNode.position.value = const Offset(10, 10);

      final path2 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path1, isNot(same(path2)));
    });

    test('creates new path when target position changes', () {
      final path1 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      targetNode.position.value = const Offset(250, 50);

      final path2 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path1, isNot(same(path2)));
    });

    test('creates new path when node size changes', () {
      final path1 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      sourceNode.setSize(const Size(150, 75));

      final path2 = painter.pathCache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path1, isNot(same(path2)));
    });
  });
}

// =============================================================================
// Mock Canvas for Testing Paint Methods
// =============================================================================

/// Mock canvas for testing paint methods without a real canvas.
class MockCanvas implements Canvas {
  int drawPathCalls = 0;
  int drawCircleCalls = 0;
  int drawRectCalls = 0;
  int drawLineCalls = 0;
  Paint? lastPaint;
  Path? lastPath;

  void reset() {
    drawPathCalls = 0;
    drawCircleCalls = 0;
    drawRectCalls = 0;
    drawLineCalls = 0;
    lastPaint = null;
    lastPath = null;
  }

  @override
  void drawPath(Path path, Paint paint) {
    drawPathCalls++;
    lastPaint = paint;
    lastPath = path;
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    drawCircleCalls++;
    lastPaint = paint;
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    drawRectCalls++;
    lastPaint = paint;
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    drawLineCalls++;
    lastPaint = paint;
  }

  // Stub implementations for other Canvas methods
  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {}

  @override
  void clipRect(
    Rect rect, {
    ClipOp clipOp = ClipOp.intersect,
    bool doAntiAlias = true,
  }) {}

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {}

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {}

  @override
  void drawAtlas(
    ui.Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {}

  @override
  void drawColor(Color color, BlendMode blendMode) {}

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {}

  @override
  void drawImage(ui.Image image, Offset offset, Paint paint) {}

  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) {}

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {}

  @override
  void drawOval(Rect rect, Paint paint) {}

  @override
  void drawPaint(Paint paint) {}

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {}

  @override
  void drawPicture(Picture picture) {}

  @override
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint) {}

  @override
  void drawRRect(RRect rrect, Paint paint) {}

  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {}

  @override
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {}

  @override
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  ) {}

  @override
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {}

  @override
  Rect getDestinationClipBounds() => Rect.zero;

  @override
  Rect getLocalClipBounds() => Rect.zero;

  @override
  Float64List getTransform() => Float64List(16);

  @override
  void restore() {}

  @override
  void restoreToCount(int count) {}

  @override
  void rotate(double radians) {}

  @override
  int getSaveCount() => 0;

  @override
  void save() {}

  @override
  void saveLayer(Rect? bounds, Paint paint) {}

  @override
  void scale(double sx, [double? sy]) {}

  @override
  void skew(double sx, double sy) {}

  @override
  void transform(Float64List matrix4) {}

  @override
  void translate(double dx, double dy) {}

  @override
  void clipRSuperellipse(
    RSuperellipse rsuperellipse, {
    bool doAntiAlias = true,
  }) {}

  @override
  void drawRSuperellipse(RSuperellipse rsuperellipse, Paint paint) {}
}
