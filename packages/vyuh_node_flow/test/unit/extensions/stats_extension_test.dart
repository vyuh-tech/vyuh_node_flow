/// Unit tests for the [StatsExtension] class.
///
/// Tests cover:
/// - Extension construction and lifecycle
/// - Observable collections access
/// - Node statistics (counts, types, visibility, locked states)
/// - Connection statistics (counts, labels, averages)
/// - Selection statistics (counts, multi-selection detection)
/// - Viewport statistics (zoom, pan, LOD level)
/// - Bounds statistics (dimensions, area, center)
/// - Performance statistics (visible nodes, density, large graph detection)
/// - Summary helpers (graph, selection, viewport, bounds summaries)
/// - Controller extension access pattern
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // StatsExtension - Construction and Lifecycle
  // ===========================================================================

  group('StatsExtension - Construction', () {
    test('creates stats extension with correct id', () {
      final ext = StatsExtension();

      expect(ext.id, equals('stats'));
    });

    test('extension can be instantiated without controller', () {
      final ext = StatsExtension();

      expect(ext, isNotNull);
      expect(ext.id, equals('stats'));
    });

    test('extension id follows naming convention', () {
      final ext = StatsExtension();

      expect(ext.id, isNotEmpty);
      expect(ext.id, isA<String>());
      expect(ext.id, equals('stats'));
    });
  });

  group('StatsExtension - Lifecycle', () {
    test('attach initializes controller reference', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      // Stats should be accessible after attachment
      expect(stats.nodeCount, equals(0));

      controller.dispose();
    });

    test('detach clears controller reference', () {
      final stats = StatsExtension();
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [stats]),
      );

      // First verify it works
      expect(controller.stats, isNotNull);

      // Remove the extension
      controller.removeExtension('stats');

      // After removal, controller should not have stats
      expect(controller.hasExtension('stats'), isFalse);

      controller.dispose();
    });

    test('onEvent does not throw (no-op)', () {
      final stats = StatsExtension();
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [stats]),
      );

      // Trigger an event by adding a node
      expect(() => controller.addNode(createTestNode()), returnsNormally);

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Observable Collections Access
  // ===========================================================================

  group('StatsExtension - Observable Collections', () {
    test('nodes returns observable map of nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodes, isNotNull);
      expect(stats.nodes.length, equals(2));
      expect(stats.nodes.containsKey('node-1'), isTrue);
      expect(stats.nodes.containsKey('node-2'), isTrue);

      controller.dispose();
    });

    test('connections returns observable list of connections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.connections, isNotNull);
      expect(stats.connections.length, equals(1));

      controller.dispose();
    });

    test('selectedNodeIds returns observable set', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.selectedNodeIds, isNotNull);
      expect(stats.selectedNodeIds, isEmpty);

      controller.selectNode('node-1');
      expect(stats.selectedNodeIds, contains('node-1'));

      controller.dispose();
    });

    test('selectedConnectionIds returns observable set', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.selectedConnectionIds, isNotNull);
      expect(stats.selectedConnectionIds, isEmpty);

      controller.selectConnection('conn-1');
      expect(stats.selectedConnectionIds, contains('conn-1'));

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Node Statistics
  // ===========================================================================

  group('StatsExtension - Node Counts', () {
    test('nodeCount returns zero for empty graph', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodeCount, equals(0));

      controller.dispose();
    });

    test('nodeCount tracks number of nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodeCount, equals(2));

      controller.addNode(createTestNode(id: 'node-3'));
      expect(stats.nodeCount, equals(3));

      controller.dispose();
    });

    test('nodeCount decreases when nodes removed', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
          createTestNode(id: 'node-3'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodeCount, equals(3));

      controller.removeNode('node-1');
      expect(stats.nodeCount, equals(2));

      controller.dispose();
    });
  });

  group('StatsExtension - Visible Node Count', () {
    test('visibleNodeCount returns count of visible nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'visible-1', visible: true),
          createTestNode(id: 'visible-2', visible: true),
          createTestNode(id: 'hidden', visible: false),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.visibleNodeCount, equals(2));
      expect(stats.nodeCount, equals(3));

      controller.dispose();
    });

    test('visibleNodeCount returns zero when all nodes hidden', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'hidden-1', visible: false),
          createTestNode(id: 'hidden-2', visible: false),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.visibleNodeCount, equals(0));

      controller.dispose();
    });

    test('visibleNodeCount equals nodeCount when all visible', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1', visible: true),
          createTestNode(id: 'node-2', visible: true),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.visibleNodeCount, equals(stats.nodeCount));

      controller.dispose();
    });
  });

  group('StatsExtension - Locked Node Count', () {
    test('lockedNodeCount tracks locked nodes', () {
      final lockedNode = Node<String>(
        id: 'locked-node',
        type: 'test',
        position: Offset.zero,
        data: 'data',
        locked: true,
      );
      final regularNode = createTestNode(id: 'regular');

      final controller = NodeFlowController<String, dynamic>(
        nodes: [lockedNode, regularNode],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.lockedNodeCount, equals(1));

      controller.dispose();
    });

    test('lockedNodeCount returns zero when no locked nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.lockedNodeCount, equals(0));

      controller.dispose();
    });

    test('lockedNodeCount tracks multiple locked nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          Node<String>(
            id: 'locked-1',
            type: 'test',
            position: Offset.zero,
            data: 'data',
            locked: true,
          ),
          Node<String>(
            id: 'locked-2',
            type: 'test',
            position: const Offset(100, 0),
            data: 'data',
            locked: true,
          ),
          createTestNode(id: 'unlocked'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.lockedNodeCount, equals(2));

      controller.dispose();
    });
  });

  group('StatsExtension - Special Node Counts', () {
    test('groupCount tracks group nodes', () {
      final group = createTestGroupNode<String>(id: 'group-1', data: 'data');
      final regularNode = createTestNode(id: 'regular');

      final controller = NodeFlowController<String, dynamic>(
        nodes: [group, regularNode],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.groupCount, equals(1));

      controller.dispose();
    });

    test('commentCount tracks comment nodes', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        data: 'data',
      );
      final regularNode = createTestNode(id: 'regular');

      final controller = NodeFlowController<String, dynamic>(
        nodes: [comment, regularNode],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.commentCount, equals(1));

      controller.dispose();
    });

    test('regularNodeCount excludes groups and comments', () {
      final group = createTestGroupNode<String>(id: 'group-1', data: 'data');
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        data: 'data',
      );
      final regular1 = createTestNode(id: 'regular-1');
      final regular2 = createTestNode(id: 'regular-2');

      final controller = NodeFlowController<String, dynamic>(
        nodes: [group, comment, regular1, regular2],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodeCount, equals(4));
      expect(stats.groupCount, equals(1));
      expect(stats.commentCount, equals(1));
      expect(stats.regularNodeCount, equals(2));

      controller.dispose();
    });

    test('regularNodeCount equals nodeCount when no special nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
          createTestNode(id: 'node-3'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.regularNodeCount, equals(stats.nodeCount));
      expect(stats.regularNodeCount, equals(3));

      controller.dispose();
    });
  });

  group('StatsExtension - Nodes By Type', () {
    test('nodesByType returns breakdown of node types', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'test-1', type: 'process'),
          createTestNode(id: 'test-2', type: 'process'),
          createTestNode(id: 'test-3', type: 'decision'),
          createTestNode(id: 'test-4', type: 'start'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      final byType = stats.nodesByType;

      expect(byType['process'], equals(2));
      expect(byType['decision'], equals(1));
      expect(byType['start'], equals(1));
      expect(byType.length, equals(3));

      controller.dispose();
    });

    test('nodesByType returns empty map for empty graph', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodesByType, isEmpty);

      controller.dispose();
    });

    test('nodesByType includes special node types', () {
      final group = createTestGroupNode<String>(id: 'group-1', data: 'data');
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        data: 'data',
      );
      final regular = createTestNode(id: 'regular', type: 'process');

      final controller = NodeFlowController<String, dynamic>(
        nodes: [group, comment, regular],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      final byType = stats.nodesByType;

      expect(byType['group'], equals(1));
      expect(byType['comment'], equals(1));
      expect(byType['process'], equals(1));

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Connection Statistics
  // ===========================================================================

  group('StatsExtension - Connection Count', () {
    test('connectionCount returns zero for empty graph', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.connectionCount, equals(0));

      controller.dispose();
    });

    test('connectionCount tracks connections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.connectionCount, equals(1));

      controller.dispose();
    });

    test('connectionCount updates when connections added', () {
      final nodeA = createTestNodeWithPorts(id: 'node-a');
      final nodeB = createTestNodeWithPorts(id: 'node-b');
      final nodeC = createTestNodeWithPorts(id: 'node-c');

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB, nodeC],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.connectionCount, equals(0));

      controller.addConnection(
        createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'node-a',
          sourcePortId: 'output-1',
          targetNodeId: 'node-b',
          targetPortId: 'input-1',
        ),
      );
      expect(stats.connectionCount, equals(1));

      controller.dispose();
    });
  });

  group('StatsExtension - Labeled Connection Count', () {
    test('labeledConnectionCount tracks connections with labels', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');

      final labeledConnection = Connection(
        id: 'labeled-conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        label: ConnectionLabel.center(text: 'Flow'),
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [labeledConnection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.labeledConnectionCount, equals(1));

      controller.dispose();
    });

    test('labeledConnectionCount returns zero when no labels', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.labeledConnectionCount, equals(0));

      controller.dispose();
    });

    test('labeledConnectionCount ignores empty label text', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');

      final emptyLabelConnection = Connection(
        id: 'empty-label-conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        label: ConnectionLabel.center(text: ''),
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [emptyLabelConnection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.labeledConnectionCount, equals(0));

      controller.dispose();
    });
  });

  group('StatsExtension - Average Connections Per Node', () {
    test('avgConnectionsPerNode returns zero for empty graph', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.avgConnectionsPerNode, equals(0.0));

      controller.dispose();
    });

    test('avgConnectionsPerNode calculates correctly', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithPorts(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-b',
        sourcePortId: 'output-1',
        targetNodeId: 'node-c',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      // 2 connections / 3 nodes = 0.666...
      expect(stats.avgConnectionsPerNode, closeTo(0.666, 0.01));

      controller.dispose();
    });

    test('avgConnectionsPerNode returns zero when no connections', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.avgConnectionsPerNode, equals(0.0));

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Selection Statistics
  // ===========================================================================

  group('StatsExtension - Selected Node Count', () {
    test('selectedNodeCount returns zero initially', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.selectedNodeCount, equals(0));

      controller.dispose();
    });

    test('selectedNodeCount tracks selected nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNode('node-1');
      expect(stats.selectedNodeCount, equals(1));

      controller.selectNodes(['node-1', 'node-2']);
      expect(stats.selectedNodeCount, equals(2));

      controller.dispose();
    });

    test('selectedNodeCount decreases on deselection', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNodes(['node-1', 'node-2']);
      expect(stats.selectedNodeCount, equals(2));

      controller.clearSelection();
      controller.selectNode('node-1');
      expect(stats.selectedNodeCount, equals(1));

      controller.dispose();
    });
  });

  group('StatsExtension - Selected Connection Count', () {
    test('selectedConnectionCount returns zero initially', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.selectedConnectionCount, equals(0));

      controller.dispose();
    });

    test('selectedConnectionCount tracks selected connections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectConnection('conn-1');
      expect(stats.selectedConnectionCount, equals(1));

      controller.dispose();
    });
  });

  group('StatsExtension - Total Selection Count', () {
    test('selectedCount equals selectedNodeCount when nodes selected', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNodes(['node-1', 'node-2']);

      expect(stats.selectedCount, equals(2));
      expect(stats.selectedNodeCount, equals(2));
      expect(stats.selectedConnectionCount, equals(0));

      controller.dispose();
    });

    test(
      'selectedCount equals selectedConnectionCount when connections selected',
      () {
        final nodeA = createTestNodeWithOutputPort(id: 'node-a');
        final nodeB = createTestNodeWithInputPort(id: 'node-b');
        final connection = createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'node-a',
          targetNodeId: 'node-b',
        );

        final controller = NodeFlowController<String, dynamic>(
          nodes: [nodeA, nodeB],
          connections: [connection],
          config: NodeFlowConfig(extensions: [StatsExtension()]),
        );
        final stats = controller.stats!;

        controller.selectConnection('conn-1');

        // Note: selecting a connection clears node selection per API design
        expect(stats.selectedCount, equals(1));
        expect(stats.selectedNodeCount, equals(0));
        expect(stats.selectedConnectionCount, equals(1));

        controller.dispose();
      },
    );
  });

  group('StatsExtension - Has Selection', () {
    test('hasSelection returns false initially', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.hasSelection, isFalse);

      controller.dispose();
    });

    test('hasSelection returns true when items selected', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNode('node-1');
      expect(stats.hasSelection, isTrue);

      controller.dispose();
    });

    test('hasSelection returns false after clear selection', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNode('node-1');
      expect(stats.hasSelection, isTrue);

      controller.clearSelection();
      expect(stats.hasSelection, isFalse);

      controller.dispose();
    });
  });

  group('StatsExtension - Multi Selection', () {
    test('isMultiSelection returns false for single selection', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNode('node-1');
      expect(stats.isMultiSelection, isFalse);

      controller.dispose();
    });

    test('isMultiSelection returns true for multiple selections', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNodes(['node-1', 'node-2']);
      expect(stats.isMultiSelection, isTrue);

      controller.dispose();
    });

    test('isMultiSelection returns false for no selection', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.isMultiSelection, isFalse);

      controller.dispose();
    });

    test('isMultiSelection works with multiple nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
          createTestNode(id: 'node-3'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNode('node-1');
      expect(stats.isMultiSelection, isFalse);

      controller.selectNodes(['node-1', 'node-2', 'node-3']);
      expect(stats.isMultiSelection, isTrue);

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Viewport Statistics
  // ===========================================================================

  group('StatsExtension - Viewport Observable', () {
    test('viewport returns observable viewport', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(zoom: 1.0),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.viewport, isNotNull);
      expect(stats.viewport.value.zoom, equals(1.0));

      controller.dispose();
    });
  });

  group('StatsExtension - Zoom Statistics', () {
    test('zoom returns current zoom level', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(zoom: 1.5),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.zoom, equals(1.5));

      controller.dispose();
    });

    test('zoomPercent returns percentage', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(zoom: 0.75),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.zoomPercent, equals(75));

      controller.dispose();
    });

    test('zoomPercent rounds to nearest integer', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(zoom: 0.666),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.zoomPercent, equals(67));

      controller.dispose();
    });

    test('zoom updates when viewport changes', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(zoom: 1.0),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.zoom, equals(1.0));

      controller.setViewport(const GraphViewport(zoom: 2.0));
      expect(stats.zoom, equals(2.0));

      controller.dispose();
    });
  });

  group('StatsExtension - Pan Statistics', () {
    test('pan returns current offset', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(x: 100, y: 200),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.pan.dx, equals(100));
      expect(stats.pan.dy, equals(200));

      controller.dispose();
    });

    test('pan updates when viewport changes', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(x: 0, y: 0),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.pan, equals(Offset.zero));

      controller.setViewport(const GraphViewport(x: 50, y: 75));
      expect(stats.pan.dx, equals(50));
      expect(stats.pan.dy, equals(75));

      controller.dispose();
    });
  });

  group('StatsExtension - LOD Level', () {
    test('lodLevel returns full when LOD disabled', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [StatsExtension(), LodExtension(enabled: false)],
        ),
      );
      final stats = controller.stats!;

      expect(stats.lodLevel, equals('full'));

      controller.dispose();
    });

    test('lodLevel returns minimal for low zoom when enabled', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            StatsExtension(),
            LodExtension(enabled: true, minThreshold: 0.25, midThreshold: 0.6),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.1),
      );
      final stats = controller.stats!;

      expect(stats.lodLevel, equals('minimal'));

      controller.dispose();
    });

    test('lodLevel returns standard for medium zoom when enabled', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            StatsExtension(),
            LodExtension(enabled: true, minThreshold: 0.25, midThreshold: 0.6),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.4),
      );
      final stats = controller.stats!;

      expect(stats.lodLevel, equals('standard'));

      controller.dispose();
    });

    test('lodLevel returns full for high zoom when enabled', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            StatsExtension(),
            LodExtension(enabled: true, minThreshold: 0.25, midThreshold: 0.6),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.8),
      );
      final stats = controller.stats!;

      expect(stats.lodLevel, equals('full'));

      controller.dispose();
    });

    test('lodLevel returns full when no LOD extension', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.lodLevel, equals('full'));

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Bounds Statistics
  // ===========================================================================

  group('StatsExtension - Bounds', () {
    test('bounds returns bounding rectangle of all nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1', position: const Offset(0, 0)),
          createTestNode(id: 'node-2', position: const Offset(200, 150)),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.bounds, isNotNull);
      expect(stats.bounds.left, equals(0.0));
      expect(stats.bounds.top, equals(0.0));

      controller.dispose();
    });

    test('boundsWidth returns width of bounds', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(100, 50),
          ),
          createTestNode(
            id: 'node-2',
            position: const Offset(200, 0),
            size: const Size(100, 50),
          ),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      // Node at 0,0 with size 100x50 and node at 200,0 with size 100x50
      // Bounds width should be 200 + 100 = 300
      expect(stats.boundsWidth, greaterThan(0));

      controller.dispose();
    });

    test('boundsHeight returns height of bounds', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(100, 50),
          ),
          createTestNode(
            id: 'node-2',
            position: const Offset(0, 200),
            size: const Size(100, 50),
          ),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.boundsHeight, greaterThan(0));

      controller.dispose();
    });

    test('boundsCenter returns center of bounds', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
          createTestNode(
            id: 'node-2',
            position: const Offset(100, 100),
            size: const Size(100, 100),
          ),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.boundsCenter, isA<Offset>());

      controller.dispose();
    });

    test('boundsArea calculates area correctly', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.boundsArea, equals(stats.boundsWidth * stats.boundsHeight));

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Performance Statistics
  // ===========================================================================

  group('StatsExtension - Visible Nodes In Viewport', () {
    test('nodesInViewport returns count of visible nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1', position: const Offset(0, 0)),
          createTestNode(id: 'node-2', position: const Offset(100, 0)),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodesInViewport, greaterThanOrEqualTo(0));

      controller.dispose();
    });
  });

  group('StatsExtension - Large Graph Detection', () {
    test('isLargeGraph returns false for small graphs', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: List.generate(10, (i) => createTestNode(id: 'node-$i')),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.isLargeGraph, isFalse);

      controller.dispose();
    });

    test('isLargeGraph returns true for graphs with more than 100 nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: List.generate(101, (i) => createTestNode(id: 'node-$i')),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.isLargeGraph, isTrue);

      controller.dispose();
    });

    test('isLargeGraph returns false at exactly 100 nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: List.generate(100, (i) => createTestNode(id: 'node-$i')),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.isLargeGraph, isFalse);

      controller.dispose();
    });
  });

  group('StatsExtension - Node Density', () {
    test('density returns zero for empty graph', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.density, equals(0.0));

      controller.dispose();
    });

    test('density calculates nodes per million square units', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(1000, 1000),
          ),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      // Density = nodeCount / boundsArea * 1000000
      final expectedDensity = (stats.nodeCount / stats.boundsArea) * 1000000;
      expect(stats.density, closeTo(expectedDensity, 0.01));

      controller.dispose();
    });

    test('density increases with more nodes in same area', () {
      final controller1 = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );

      final controller2 = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(50, 50),
          ),
          createTestNode(
            id: 'node-2',
            position: const Offset(50, 50),
            size: const Size(50, 50),
          ),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );

      final density1 = controller1.stats!.density;
      final density2 = controller2.stats!.density;

      expect(density2, greaterThan(density1));

      controller1.dispose();
      controller2.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Summary Helpers
  // ===========================================================================

  group('StatsExtension - Graph Summary', () {
    test('summary returns node and connection counts', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.summary, equals('2 nodes, 1 connections'));

      controller.dispose();
    });

    test('summary updates when graph changes', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.summary, equals('0 nodes, 0 connections'));

      controller.addNode(createTestNode(id: 'node-1'));
      expect(stats.summary, equals('1 nodes, 0 connections'));

      controller.dispose();
    });
  });

  group('StatsExtension - Selection Summary', () {
    test('selectionSummary shows nothing selected', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.selectionSummary, equals('Nothing selected'));

      controller.dispose();
    });

    test('selectionSummary shows single node selected', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNode('node-1');
      expect(stats.selectionSummary, contains('1 node'));
      expect(stats.selectionSummary, contains('selected'));

      controller.dispose();
    });

    test('selectionSummary pluralizes correctly', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNodes(['node-1', 'node-2']);
      expect(stats.selectionSummary, contains('2 nodes'));
      expect(stats.selectionSummary, isNot(contains('1 node')));

      controller.dispose();
    });

    test('selectionSummary shows connection selection', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectConnection('conn-1');
      expect(stats.selectionSummary, contains('1 connection'));
      expect(stats.selectionSummary, contains('selected'));

      controller.dispose();
    });

    test('selectionSummary shows only connections when connection selected', () {
      // Note: The API design clears node selection when connection is selected
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      // Select a node first
      controller.selectNode('node-a');
      expect(stats.selectionSummary, contains('node'));

      // Then select a connection - this clears node selection per API design
      controller.selectConnection('conn-1');
      expect(stats.selectionSummary, contains('connection'));
      expect(stats.selectionSummary, contains('selected'));

      controller.dispose();
    });
  });

  group('StatsExtension - Viewport Summary', () {
    test('viewportSummary shows zoom and position', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(x: 50, y: 100, zoom: 0.8),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.viewportSummary, contains('80%'));
      expect(stats.viewportSummary, contains('50'));
      expect(stats.viewportSummary, contains('100'));

      controller.dispose();
    });

    test('viewportSummary updates with viewport changes', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(x: 0, y: 0, zoom: 1.0),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.viewportSummary, contains('100%'));

      controller.setViewport(const GraphViewport(x: 25, y: 75, zoom: 1.5));
      expect(stats.viewportSummary, contains('150%'));
      expect(stats.viewportSummary, contains('25'));
      expect(stats.viewportSummary, contains('75'));

      controller.dispose();
    });

    test('viewportSummary format is consistent', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(x: 100, y: 200, zoom: 1.0),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      // Format should be: "100% at (100, 200)"
      expect(
        stats.viewportSummary,
        matches(RegExp(r'\d+% at \(-?\d+, -?\d+\)')),
      );

      controller.dispose();
    });
  });

  group('StatsExtension - Bounds Summary', () {
    test('boundsSummary shows dimensions', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(200, 100),
          ),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.boundsSummary, contains('px'));
      expect(stats.boundsSummary, matches(RegExp(r'\d+ × \d+ px')));

      controller.dispose();
    });

    test('boundsSummary updates with graph changes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      final initialSummary = stats.boundsSummary;

      controller.addNode(
        createTestNode(
          id: 'node-2',
          position: const Offset(500, 500),
          size: const Size(100, 100),
        ),
      );

      expect(stats.boundsSummary, isNot(equals(initialSummary)));

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Controller Extension Access
  // ===========================================================================

  group('StatsExtension - Controller Extension Access', () {
    test('stats getter returns extension when registered', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );

      expect(controller.stats, isNotNull);
      expect(controller.stats, isA<StatsExtension>());

      controller.dispose();
    });

    test('stats getter returns null when not registered', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: []),
      );

      expect(controller.stats, isNull);

      controller.dispose();
    });

    test('stats can be accessed via resolveExtension', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );

      final stats = controller.resolveExtension<StatsExtension>();

      expect(stats, isNotNull);
      expect(stats, isA<StatsExtension>());

      controller.dispose();
    });

    test('multiple accesses return same instance', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );

      final stats1 = controller.stats;
      final stats2 = controller.stats;

      expect(identical(stats1, stats2), isTrue);

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Reactivity
  // ===========================================================================

  group('StatsExtension - Reactivity', () {
    test('nodeCount is reactive to node additions', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodeCount, equals(0));

      controller.addNode(createTestNode(id: 'node-1'));
      expect(stats.nodeCount, equals(1));

      controller.addNode(createTestNode(id: 'node-2'));
      expect(stats.nodeCount, equals(2));

      controller.dispose();
    });

    test('connectionCount is reactive to connection changes', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.connectionCount, equals(0));

      controller.addConnection(
        createTestConnection(sourceNodeId: 'node-a', targetNodeId: 'node-b'),
      );
      expect(stats.connectionCount, equals(1));

      controller.dispose();
    });

    test('selectedNodeCount is reactive to selection changes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.selectedNodeCount, equals(0));

      controller.selectNode('node-1');
      expect(stats.selectedNodeCount, equals(1));

      controller.selectNodes(['node-1', 'node-2']);
      expect(stats.selectedNodeCount, equals(2));

      controller.clearSelection();
      expect(stats.selectedNodeCount, equals(0));

      controller.dispose();
    });

    test('zoom is reactive to viewport changes', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(zoom: 1.0),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.zoom, equals(1.0));

      controller.setViewport(const GraphViewport(zoom: 1.5));
      expect(stats.zoom, equals(1.5));

      controller.setViewport(const GraphViewport(zoom: 0.5));
      expect(stats.zoom, equals(0.5));

      controller.dispose();
    });
  });

  // ===========================================================================
  // StatsExtension - Edge Cases
  // ===========================================================================

  group('StatsExtension - Edge Cases', () {
    test('handles empty graph gracefully', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodeCount, equals(0));
      expect(stats.connectionCount, equals(0));
      expect(stats.selectedCount, equals(0));
      expect(stats.avgConnectionsPerNode, equals(0.0));
      expect(stats.summary, equals('0 nodes, 0 connections'));
      expect(stats.selectionSummary, equals('Nothing selected'));

      controller.dispose();
    });

    test('handles graph with only groups', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestGroupNode<String>(id: 'group-1', data: 'data'),
          createTestGroupNode<String>(id: 'group-2', data: 'data'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodeCount, equals(2));
      expect(stats.groupCount, equals(2));
      expect(stats.regularNodeCount, equals(0));

      controller.dispose();
    });

    test('handles graph with only comments', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestCommentNode<String>(id: 'comment-1', data: 'data'),
          createTestCommentNode<String>(id: 'comment-2', data: 'data'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodeCount, equals(2));
      expect(stats.commentCount, equals(2));
      expect(stats.regularNodeCount, equals(0));

      controller.dispose();
    });

    test('handles rapid successive updates', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      // Add many nodes rapidly
      for (int i = 0; i < 50; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      expect(stats.nodeCount, equals(50));

      controller.dispose();
    });
  });
}
