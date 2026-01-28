/// Comprehensive tests for ConnectionPathCache.
///
/// Tests cover:
/// - Cache hit/miss scenarios
/// - Cache invalidation (theme changes, node movements, size changes, port offsets, gaps)
/// - Path computation and storage
/// - Memory management (dispose, clearAll, removeConnection)
/// - Concurrent access patterns
/// - Hidden node handling
/// - Debug path accessors
/// - Statistics reporting
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Import internal class for testing
import 'package:vyuh_node_flow/src/connections/connection_path_cache.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // Construction Tests
  // ==========================================================================

  group('ConnectionPathCache Construction', () {
    test('creates with light theme', () {
      final cache = ConnectionPathCache(theme: NodeFlowTheme.light);

      expect(cache.theme, same(NodeFlowTheme.light));
      expect(cache.nodeShape, isNull);
    });

    test('creates with dark theme', () {
      final cache = ConnectionPathCache(theme: NodeFlowTheme.dark);

      expect(cache.theme, same(NodeFlowTheme.dark));
    });

    test('creates with node shape function', () {
      NodeShape? shapeGetter(Node node) => const DiamondShape();

      final cache = ConnectionPathCache(
        theme: NodeFlowTheme.light,
        nodeShape: shapeGetter,
      );

      expect(cache.nodeShape, equals(shapeGetter));
    });

    test('exposes default hit tolerance from theme', () {
      final cache = ConnectionPathCache(theme: NodeFlowTheme.light);

      expect(
        cache.defaultHitTolerance,
        equals(NodeFlowTheme.light.connectionTheme.hitTolerance),
      );
    });
  });

  // ==========================================================================
  // Theme Update Tests
  // ==========================================================================

  group('Theme Updates', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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

    test('updateTheme changes theme reference', () {
      expect(cache.theme, same(NodeFlowTheme.light));

      cache.updateTheme(NodeFlowTheme.dark);

      expect(cache.theme, same(NodeFlowTheme.dark));
    });

    test(
      'updateTheme does not invalidate cache when non-path properties change',
      () {
        // Populate cache
        cache.getOrCreatePath(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: cache.theme.connectionTheme.style,
        );

        expect(cache.hasConnection(connection.id), isTrue);

        // Update theme with non-path-affecting properties only
        final newTheme = NodeFlowTheme.light.copyWith(
          backgroundColor: Colors.grey,
        );
        cache.updateTheme(newTheme);

        // Cache should still be valid
        expect(cache.hasConnection(connection.id), isTrue);
      },
    );

    test('updateTheme invalidates cache when style changes', () {
      // Populate cache
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      // Update theme with different style
      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          style: ConnectionStyles.bezier,
        ),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when bezierCurvature changes', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(bezierCurvature: 0.8),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when cornerRadius changes', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(cornerRadius: 12.0),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when portExtension changes', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(portExtension: 40.0),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when backEdgeGap changes', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(backEdgeGap: 40.0),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when startPoint changes', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          startPoint: ConnectionEndPoint.circle,
        ),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when endPoint changes', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(
          endPoint: ConnectionEndPoint.triangle,
        ),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when startGap changes', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(startGap: 10.0),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when endGap changes', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      final newTheme = NodeFlowTheme.light.copyWith(
        connectionTheme: ConnectionTheme.light.copyWith(endGap: 10.0),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('updateTheme invalidates cache when port size changes', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);

      final newTheme = NodeFlowTheme.light.copyWith(
        portTheme: PortTheme.light.copyWith(size: const Size(20, 20)),
      );
      cache.updateTheme(newTheme);

      expect(cache.hasConnection(connection.id), isFalse);
    });
  });

  // ==========================================================================
  // Cache Hit/Miss Scenarios
  // ==========================================================================

  group('Cache Hit/Miss Scenarios', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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

    test('first call creates path (cache miss)', () {
      expect(cache.hasConnection(connection.id), isFalse);

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path, isNotNull);
      expect(cache.hasConnection(connection.id), isTrue);
    });

    test('second call returns cached path (cache hit)', () {
      final path1 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      final path2 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Same path reference (cache hit)
      expect(path1, same(path2));
    });

    test('cache miss when source node position changes', () {
      final path1 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Move source node
      sourceNode.position.value = const Offset(50, 50);

      final path2 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Different path reference (cache miss, new path created)
      expect(path1, isNot(same(path2)));
    });

    test('cache miss when target node position changes', () {
      final path1 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Move target node
      targetNode.position.value = const Offset(250, 100);

      final path2 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Different path reference (cache miss)
      expect(path1, isNot(same(path2)));
    });

    test('cache miss when source node size changes', () {
      final path1 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Change source node size
      sourceNode.setSize(const Size(150, 75));

      final path2 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path1, isNot(same(path2)));
    });

    test('cache miss when target node size changes', () {
      final path1 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Change target node size
      targetNode.setSize(const Size(150, 75));

      final path2 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path1, isNot(same(path2)));
    });

    test('cache miss when connection start gap changes', () {
      final path1 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Create connection with different start gap
      final connectionWithGap = Connection(
        id: 'conn-1', // Same ID
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startGap: 15.0,
      );

      final path2 = cache.getOrCreatePath(
        connection: connectionWithGap,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path1, isNot(same(path2)));
    });

    test('cache miss when connection end gap changes', () {
      final path1 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Create connection with different end gap
      final connectionWithGap = Connection(
        id: 'conn-1', // Same ID
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        endGap: 15.0,
      );

      final path2 = cache.getOrCreatePath(
        connection: connectionWithGap,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path1, isNot(same(path2)));
    });

    test('cache miss when source port offset changes', () {
      // Create source node with modifiable port
      final sourceNodeWithOffset = createTestNode(
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
      sourceNodeWithOffset.setSize(const Size(100, 50));

      final path1 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNodeWithOffset,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Create new node with different port offset
      final sourceNodeWithNewOffset = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [
          createTestPort(
            id: 'output-1',
            type: PortType.output,
            position: PortPosition.right,
            offset: const Offset(0, 10), // Different offset
          ),
        ],
      );
      sourceNodeWithNewOffset.setSize(const Size(100, 50));

      final path2 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNodeWithNewOffset,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path1, isNot(same(path2)));
    });

    test('cache miss when target port offset changes', () {
      // Create target node with modifiable port
      final targetNodeWithOffset = createTestNode(
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
      targetNodeWithOffset.setSize(const Size(100, 50));

      final path1 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNodeWithOffset,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Create new node with different port offset
      final targetNodeWithNewOffset = createTestNode(
        id: 'node-b',
        position: const Offset(200, 0),
        inputPorts: [
          createTestPort(
            id: 'input-1',
            type: PortType.input,
            position: PortPosition.left,
            offset: const Offset(0, 10), // Different offset
          ),
        ],
      );
      targetNodeWithNewOffset.setSize(const Size(100, 50));

      final path2 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNodeWithNewOffset,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path1, isNot(same(path2)));
    });
  });

  // ==========================================================================
  // Path Computation and Storage
  // ==========================================================================

  group('Path Computation and Storage', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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

    test('getOrCreatePath returns valid path', () {
      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
      expect(path!.getBounds().isEmpty, isFalse);
    });

    test('getOrCreatePath returns null for hidden source node', () {
      sourceNode.isVisible = false;

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNull);
    });

    test('getOrCreatePath returns null for hidden target node', () {
      targetNode.isVisible = false;

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNull);
    });

    test('getOrCreatePath returns null when source port not found', () {
      final nodeWithoutPort = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [], // No ports
      );
      nodeWithoutPort.setSize(const Size(100, 50));

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: nodeWithoutPort,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNull);
    });

    test('getOrCreatePath returns null when target port not found', () {
      final nodeWithoutPort = createTestNode(
        id: 'node-b',
        position: const Offset(200, 0),
        inputPorts: [], // No ports
      );
      nodeWithoutPort.setSize(const Size(100, 50));

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: nodeWithoutPort,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNull);
    });

    test('getOrCreatePath creates paths for all built-in styles', () {
      for (final style in ConnectionStyles.all) {
        final path = cache.getOrCreatePath(
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

        // Clear for next iteration
        cache.clearAll();
      }
    });
  });

  // ==========================================================================
  // Segment Bounds Tests
  // ==========================================================================

  group('Segment Bounds', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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

    test('getSegmentBounds returns null before path creation', () {
      expect(cache.getSegmentBounds(connection.id), isNull);
    });

    test('getSegmentBounds returns cached bounds after path creation', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      final bounds = cache.getSegmentBounds(connection.id);

      expect(bounds, isNotNull);
      expect(bounds, isNotEmpty);
    });

    test('getOrCreateSegmentBounds returns non-empty list', () {
      final bounds = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(bounds, isNotEmpty);
    });

    test('getOrCreateSegmentBounds returns valid rectangles', () {
      final bounds = cache.getOrCreateSegmentBounds(
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

    test('getOrCreateSegmentBounds returns empty for hidden source', () {
      sourceNode.isVisible = false;

      final bounds = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(bounds, isEmpty);
    });

    test('getOrCreateSegmentBounds returns empty for hidden target', () {
      targetNode.isVisible = false;

      final bounds = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(bounds, isEmpty);
    });

    test('getOrCreateSegmentBounds uses cache on second call', () {
      final bounds1 = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      final bounds2 = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      // Same reference (cached)
      expect(bounds1, same(bounds2));
    });

    test('getOrCreateSegmentBounds invalidates on position change', () {
      final bounds1 = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      sourceNode.position.value = const Offset(50, 50);

      final bounds2 = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(bounds1, isNot(same(bounds2)));
    });

    test('getOrCreateSegmentBounds returns empty for missing ports', () {
      final nodeWithoutPort = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [],
      );
      nodeWithoutPort.setSize(const Size(100, 50));

      final bounds = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: nodeWithoutPort,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(bounds, isEmpty);
    });
  });

  // ==========================================================================
  // Hit Testing
  // ==========================================================================

  group('Hit Testing', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

      // Position source at (0, 0) with size 100x50
      sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      // Position target at (300, 0) with size 100x50
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

    test('hitTest returns false for point far from connection', () {
      final result = cache.hitTest(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(1000, 1000),
      );

      expect(result, isFalse);
    });

    test('hitTest returns true for point on connection path', () {
      // First generate the path
      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Get path center
      final bounds = path!.getBounds();
      final midPoint = bounds.center;

      final result = cache.hitTest(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: midPoint,
        tolerance: 20.0,
      );

      expect(result, isTrue);
    });

    test('hitTest computes path on demand if not cached', () {
      // Don't pre-create the path
      expect(cache.hasConnection(connection.id), isFalse);

      // Hit test should still work by computing on demand
      final result = cache.hitTest(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(200, 25), // Roughly between nodes
        tolerance: 30.0,
      );

      // Should have created the path
      expect(cache.hasConnection(connection.id), isTrue);
      expect(result, isA<bool>());
    });

    test('hitTest invalidates stale cache and recomputes', () {
      // Create path
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Move node (cache becomes stale)
      sourceNode.position.value = const Offset(50, 50);

      // Hit test should recompute
      final result = cache.hitTest(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(200, 50),
        tolerance: 30.0,
      );

      expect(result, isA<bool>());
    });

    test('hitTest returns false for hidden source node', () {
      sourceNode.isVisible = false;

      final result = cache.hitTest(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(200, 25),
      );

      expect(result, isFalse);
    });

    test('hitTest returns false for hidden target node', () {
      targetNode.isVisible = false;

      final result = cache.hitTest(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(200, 25),
      );

      expect(result, isFalse);
    });

    test('hitTest returns false when source port not found', () {
      final nodeWithoutPort = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [],
      );
      nodeWithoutPort.setSize(const Size(100, 50));

      final result = cache.hitTest(
        connection: connection,
        sourceNode: nodeWithoutPort,
        targetNode: targetNode,
        testPoint: const Offset(200, 25),
      );

      expect(result, isFalse);
    });

    test('hitTest respects custom tolerance', () {
      // Generate path first
      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      final bounds = path!.getBounds();

      // Point at path center should hit with large tolerance
      final centerResult = cache.hitTest(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: bounds.center,
        tolerance: 30.0,
      );
      expect(centerResult, isTrue);

      // Point very far from path should not hit
      final farResult = cache.hitTest(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: const Offset(200, 500),
        tolerance: 2.0,
      );
      expect(farResult, isFalse);
    });
  });

  // ==========================================================================
  // Memory Management
  // ==========================================================================

  group('Memory Management', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection1;
    late Connection connection2;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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

      connection1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      connection2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('removeConnection removes specific connection', () {
      cache.getOrCreatePath(
        connection: connection1,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );
      cache.getOrCreatePath(
        connection: connection2,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection1.id), isTrue);
      expect(cache.hasConnection(connection2.id), isTrue);

      cache.removeConnection(connection1.id);

      expect(cache.hasConnection(connection1.id), isFalse);
      expect(cache.hasConnection(connection2.id), isTrue);
    });

    test('clearAll removes all cached paths', () {
      cache.getOrCreatePath(
        connection: connection1,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );
      cache.getOrCreatePath(
        connection: connection2,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection1.id), isTrue);
      expect(cache.hasConnection(connection2.id), isTrue);

      cache.clearAll();

      expect(cache.hasConnection(connection1.id), isFalse);
      expect(cache.hasConnection(connection2.id), isFalse);
    });

    test('clearAll is idempotent on empty cache', () {
      // Should not throw
      cache.clearAll();
      cache.clearAll();

      expect(cache.hasConnection('any-id'), isFalse);
    });

    test('invalidateAll clears all cached paths', () {
      cache.getOrCreatePath(
        connection: connection1,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection1.id), isTrue);

      cache.invalidateAll();

      expect(cache.hasConnection(connection1.id), isFalse);
    });

    test('dispose clears cache', () {
      cache.getOrCreatePath(
        connection: connection1,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection1.id), isTrue);

      cache.dispose();

      expect(cache.hasConnection(connection1.id), isFalse);
    });
  });

  // ==========================================================================
  // Debug Path Accessors
  // ==========================================================================

  group('Debug Path Accessors', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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

    test('getOriginalPath returns null before caching', () {
      expect(cache.getOriginalPath(connection.id), isNull);
    });

    test('getOriginalPath returns cached path', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      final originalPath = cache.getOriginalPath(connection.id);

      expect(originalPath, isNotNull);
      expect(originalPath!.getBounds().isEmpty, isFalse);
    });

    test('getHitTestPath returns null before caching', () {
      expect(cache.getHitTestPath(connection.id), isNull);
    });

    test('getHitTestPath returns cached hit test path', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      final hitTestPath = cache.getHitTestPath(connection.id);

      expect(hitTestPath, isNotNull);
      expect(hitTestPath!.getBounds().isEmpty, isFalse);
    });

    test('hit test path is larger than original path', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      final originalPath = cache.getOriginalPath(connection.id);
      final hitTestPath = cache.getHitTestPath(connection.id);

      final originalBounds = originalPath!.getBounds();
      final hitTestBounds = hitTestPath!.getBounds();

      // Hit test path should encompass original path with tolerance
      expect(hitTestBounds.width, greaterThanOrEqualTo(originalBounds.width));
      expect(hitTestBounds.height, greaterThanOrEqualTo(originalBounds.height));
    });
  });

  // ==========================================================================
  // Statistics
  // ==========================================================================

  group('Statistics', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection1;
    late Connection connection2;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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

      connection1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      connection2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
    });

    test('getStats returns statistics map', () {
      final stats = cache.getStats();

      expect(stats, isNotNull);
      expect(stats, isA<Map<String, dynamic>>());
    });

    test('getStats includes cachedPaths count', () {
      final stats = cache.getStats();

      expect(stats.containsKey('cachedPaths'), isTrue);
      expect(stats['cachedPaths'], isA<int>());
    });

    test('getStats includes hitTolerance', () {
      final stats = cache.getStats();

      expect(stats.containsKey('hitTolerance'), isTrue);
      expect(stats['hitTolerance'], isA<double>());
    });

    test('getStats includes hitToleranceSource', () {
      final stats = cache.getStats();

      expect(stats.containsKey('hitToleranceSource'), isTrue);
      expect(stats['hitToleranceSource'], isA<String>());
    });

    test('getStats shows zero count on empty cache', () {
      final stats = cache.getStats();

      expect(stats['cachedPaths'], equals(0));
    });

    test('getStats shows correct count after caching', () {
      cache.getOrCreatePath(
        connection: connection1,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      var stats = cache.getStats();
      expect(stats['cachedPaths'], equals(1));

      cache.getOrCreatePath(
        connection: connection2,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      stats = cache.getStats();
      expect(stats['cachedPaths'], equals(2));
    });

    test('getStats shows correct count after removal', () {
      cache.getOrCreatePath(
        connection: connection1,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );
      cache.getOrCreatePath(
        connection: connection2,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      var stats = cache.getStats();
      expect(stats['cachedPaths'], equals(2));

      cache.removeConnection(connection1.id);

      stats = cache.getStats();
      expect(stats['cachedPaths'], equals(1));
    });
  });

  // ==========================================================================
  // hasConnection Tests
  // ==========================================================================

  group('hasConnection', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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

    test('returns false for uncached connection', () {
      expect(cache.hasConnection('nonexistent'), isFalse);
    });

    test('returns true after caching', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(cache.hasConnection(connection.id), isTrue);
    });

    test('returns false after removal', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      cache.removeConnection(connection.id);

      expect(cache.hasConnection(connection.id), isFalse);
    });

    test('returns false after clearAll', () {
      cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      cache.clearAll();

      expect(cache.hasConnection(connection.id), isFalse);
    });
  });

  // ==========================================================================
  // Node Shape Integration
  // ==========================================================================

  group('Node Shape Integration', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;
    late Connection connection;

    setUp(() {
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

    test('creates path without node shape function', () {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
    });

    test('creates path with node shape function', () {
      cache = ConnectionPathCache(
        theme: NodeFlowTheme.light,
        nodeShape: (node) => const DiamondShape(),
      );

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
    });

    test('creates path with different shapes for different nodes', () {
      cache = ConnectionPathCache(
        theme: NodeFlowTheme.light,
        nodeShape: (node) {
          if (node.id == 'node-a') return const DiamondShape();
          if (node.id == 'node-b') return const CircleShape();
          return null;
        },
      );

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
    });

    test('nodeShape property can be updated', () {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

      expect(cache.nodeShape, isNull);

      NodeShape? shapeGetter(Node node) => const CircleShape();
      cache.nodeShape = shapeGetter;

      expect(cache.nodeShape, equals(shapeGetter));
    });
  });

  // ==========================================================================
  // Edge Cases
  // ==========================================================================

  group('Edge Cases', () {
    late ConnectionPathCache cache;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);
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
        position: const Offset(110, 0), // Very close
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = cache.getOrCreatePath(
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

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.bezier,
      );

      expect(path, isNotNull);
      expect(path!.getBounds().isEmpty, isFalse);
    });

    test('handles negative positions', () {
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

      final path = cache.getOrCreatePath(
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
      // Size is zero by default

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      // Size is zero by default

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
    });

    test('handles back-edge (target behind source)', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(200, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(0, 0), // Behind source
      );
      targetNode.setSize(const Size(100, 50));

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = cache.getOrCreatePath(
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

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
    });

    test('handles top-to-bottom ports', () {
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
        position: const Offset(50, 150),
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

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.smoothstep,
      );

      expect(path, isNotNull);
      expect(path!.getBounds().isEmpty, isFalse);
    });
  });

  // ==========================================================================
  // Concurrent Access Patterns
  // ==========================================================================

  group('Concurrent Access Patterns', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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
    });

    test('multiple connections can be cached independently', () {
      final connections = List.generate(
        10,
        (i) => createTestConnection(
          id: 'conn-$i',
          sourceNodeId: 'node-a',
          sourcePortId: 'output-1',
          targetNodeId: 'node-b',
          targetPortId: 'input-1',
        ),
      );

      // Cache all connections
      for (final conn in connections) {
        cache.getOrCreatePath(
          connection: conn,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: cache.theme.connectionTheme.style,
        );
      }

      // All should be cached
      for (final conn in connections) {
        expect(cache.hasConnection(conn.id), isTrue);
      }

      expect(cache.getStats()['cachedPaths'], equals(10));
    });

    test('same connection ID overwrites previous cache entry', () {
      final connection1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path1 = cache.getOrCreatePath(
        connection: connection1,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Move node to force new path
      sourceNode.position.value = const Offset(50, 50);

      final path2 = cache.getOrCreatePath(
        connection: connection1,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Still only one entry
      expect(cache.getStats()['cachedPaths'], equals(1));
      expect(path1, isNot(same(path2)));
    });

    test('rapid consecutive calls return same cached path', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final paths = <Path?>[];
      for (var i = 0; i < 100; i++) {
        paths.add(
          cache.getOrCreatePath(
            connection: connection,
            sourceNode: sourceNode,
            targetNode: targetNode,
            connectionStyle: cache.theme.connectionTheme.style,
          ),
        );
      }

      // All should be the same reference
      final firstPath = paths.first;
      for (final path in paths) {
        expect(path, same(firstPath));
      }
    });

    test('interleaved getOrCreatePath and hit testing', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      // Create path
      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Use the actual source port connection point for hit testing - this is
      // guaranteed to be on/near the path, unlike bounds.center which may miss
      // curved paths when nodes have vertical offset
      final sourcePort = sourceNode.findPort('output-1')!;
      final sourcePoint = sourceNode.getConnectionPoint(
        'output-1',
        portSize: sourcePort.size ?? const Size(12, 12),
      );

      final hitResult = cache.hitTest(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: sourcePoint,
        tolerance: 20.0,
      );

      // Get path again
      final path2 = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(hitResult, isTrue);
      expect(path, same(path2));
    });

    test('interleaved segment bounds and path creation', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      // Get segment bounds (creates path internally)
      final bounds1 = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Get path (should use cache)
      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      // Get segment bounds again
      final bounds2 = cache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(bounds1, same(bounds2));
      expect(path, isNotNull);
    });
  });

  // ==========================================================================
  // Connection with Custom Gap Values
  // ==========================================================================

  group('Connection with Custom Gap Values', () {
    late ConnectionPathCache cache;
    late Node<String> sourceNode;
    late Node<String> targetNode;

    setUp(() {
      cache = ConnectionPathCache(theme: NodeFlowTheme.light);

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
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startGap: 15.0,
      );

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path, isNotNull);
    });

    test('handles connection with custom end gap', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        endGap: 15.0,
      );

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path, isNotNull);
    });

    test('handles connection with both custom gaps', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startGap: 10.0,
        endGap: 20.0,
      );

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path, isNotNull);
    });

    test('uses theme defaults when connection gaps are null', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final path = cache.getOrCreatePath(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: cache.theme.connectionTheme.style,
      );

      expect(path, isNotNull);
    });
  });
}
