/// Unit tests for extension events in vyuh_node_flow.
///
/// Tests cover all event types defined in the extension system:
/// - Node events: NodeAdded, NodeRemoved, NodeMoved, NodeResized, etc.
/// - Connection events: ConnectionAdded, ConnectionRemoved
/// - Selection events: SelectionChanged
/// - Viewport events: ViewportChanged
/// - Drag events: NodeDragStarted, NodeDragEnded, ConnectionDragStarted, etc.
/// - Hover events: NodeHoverChanged, PortHoverChanged, ConnectionHoverChanged
/// - Lifecycle events: GraphCleared, GraphLoaded
/// - Batch events: BatchStarted, BatchEnded
/// - LOD events: LODLevelChanged
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Node Events
  // ===========================================================================

  group('NodeAdded', () {
    test('creates event with node', () {
      final node = createTestNode(id: 'test-node');
      final event = NodeAdded(node);

      expect(event.node, equals(node));
    });

    test('node property returns correct node', () {
      final node = createTestNode(id: 'node-123', type: 'processor');
      final event = NodeAdded(node);

      expect(event.node.id, equals('node-123'));
      expect(event.node.type, equals('processor'));
    });

    test('toString contains node id', () {
      final node = createTestNode(id: 'my-node');
      final event = NodeAdded(node);

      expect(event.toString(), contains('my-node'));
      expect(event.toString(), contains('NodeAdded'));
    });

    test('is a GraphEvent', () {
      final node = createTestNode();
      final event = NodeAdded(node);

      expect(event, isA<GraphEvent>());
    });
  });

  group('NodeRemoved', () {
    test('creates event with node', () {
      final node = createTestNode(id: 'removed-node');
      final event = NodeRemoved(node);

      expect(event.node, equals(node));
    });

    test('preserves full node state for undo capability', () {
      final node = createTestNode(
        id: 'full-state-node',
        position: const Offset(100, 200),
        data: 'important-data',
      );
      final event = NodeRemoved(node);

      expect(event.node.position.value, equals(const Offset(100, 200)));
      expect(event.node.data, equals('important-data'));
    });

    test('toString contains node id', () {
      final node = createTestNode(id: 'deleted-node');
      final event = NodeRemoved(node);

      expect(event.toString(), contains('deleted-node'));
      expect(event.toString(), contains('NodeRemoved'));
    });

    test('is a GraphEvent', () {
      final node = createTestNode();
      final event = NodeRemoved(node);

      expect(event, isA<GraphEvent>());
    });
  });

  group('NodeMoved', () {
    test('creates event with node and previous position', () {
      final node = createTestNode(
        id: 'moved-node',
        position: const Offset(100, 100),
      );
      final previousPosition = const Offset(0, 0);
      final event = NodeMoved(node, previousPosition);

      expect(event.node, equals(node));
      expect(event.previousPosition, equals(previousPosition));
    });

    test('tracks position change correctly', () {
      final node = createTestNode(position: const Offset(200, 150));
      final previousPosition = const Offset(50, 75);
      final event = NodeMoved(node, previousPosition);

      expect(event.previousPosition, equals(const Offset(50, 75)));
      expect(event.node.position.value, equals(const Offset(200, 150)));
    });

    test('toString contains position information', () {
      final node = createTestNode(
        id: 'pos-node',
        position: const Offset(100, 100),
      );
      final event = NodeMoved(node, const Offset(0, 0));

      final str = event.toString();
      expect(str, contains('NodeMoved'));
      expect(str, contains('pos-node'));
    });

    test('supports undo by storing previous position', () {
      final previousPos = const Offset(10, 20);
      final node = createTestNode(position: const Offset(30, 40));
      final event = NodeMoved(node, previousPos);

      // Can use previousPosition to restore state
      expect(event.previousPosition.dx, equals(10));
      expect(event.previousPosition.dy, equals(20));
    });

    test('is a GraphEvent', () {
      final node = createTestNode();
      final event = NodeMoved(node, Offset.zero);

      expect(event, isA<GraphEvent>());
    });
  });

  group('NodeResized', () {
    test('creates event with node and previous size', () {
      final node = createTestNode(
        id: 'resized-node',
        size: const Size(200, 150),
      );
      final previousSize = const Size(100, 100);
      final event = NodeResized(node, previousSize);

      expect(event.node, equals(node));
      expect(event.previousSize, equals(previousSize));
    });

    test('tracks size change correctly', () {
      final node = createTestNode(size: const Size(300, 200));
      final previousSize = const Size(150, 100);
      final event = NodeResized(node, previousSize);

      expect(event.previousSize, equals(const Size(150, 100)));
      expect(event.node.size.value, equals(const Size(300, 200)));
    });

    test('toString contains size information', () {
      final node = createTestNode(id: 'size-node', size: const Size(200, 150));
      final event = NodeResized(node, const Size(100, 100));

      final str = event.toString();
      expect(str, contains('NodeResized'));
      expect(str, contains('size-node'));
    });

    test('supports undo by storing previous size', () {
      final previousSize = const Size(50, 60);
      final node = createTestNode(size: const Size(100, 120));
      final event = NodeResized(node, previousSize);

      expect(event.previousSize.width, equals(50));
      expect(event.previousSize.height, equals(60));
    });

    test('is a GraphEvent', () {
      final node = createTestNode();
      final event = NodeResized(node, const Size(100, 100));

      expect(event, isA<GraphEvent>());
    });
  });

  group('NodeDataChanged', () {
    test('creates event with node and previous data', () {
      final node = createTestNode(id: 'data-node', data: 'new-data');
      final event = NodeDataChanged(node, 'old-data');

      expect(event.node, equals(node));
      expect(event.previousData, equals('old-data'));
    });

    test('tracks data change correctly', () {
      final node = createTestNode(data: 'updated-value');
      final event = NodeDataChanged(node, 'original-value');

      expect(event.previousData, equals('original-value'));
      expect(event.node.data, equals('updated-value'));
    });

    test('toString contains node id', () {
      final node = createTestNode(id: 'data-changed-node');
      final event = NodeDataChanged(node, 'old');

      expect(event.toString(), contains('NodeDataChanged'));
      expect(event.toString(), contains('data-changed-node'));
    });

    test('is a GraphEvent', () {
      final node = createTestNode();
      final event = NodeDataChanged(node, 'old');

      expect(event, isA<GraphEvent>());
    });
  });

  group('NodeVisibilityChanged', () {
    test('creates event with node and wasVisible flag', () {
      final node = createTestNode(id: 'visibility-node', visible: false);
      final event = NodeVisibilityChanged(node, true);

      expect(event.node, equals(node));
      expect(event.wasVisible, isTrue);
    });

    test('tracks visibility change from visible to hidden', () {
      final node = createTestNode(visible: false);
      final event = NodeVisibilityChanged(node, true);

      expect(event.wasVisible, isTrue);
      expect(event.node.isVisible, isFalse);
    });

    test('tracks visibility change from hidden to visible', () {
      final node = createTestNode(visible: true);
      final event = NodeVisibilityChanged(node, false);

      expect(event.wasVisible, isFalse);
      expect(event.node.isVisible, isTrue);
    });

    test('toString contains visibility information', () {
      final node = createTestNode(id: 'vis-node');
      final event = NodeVisibilityChanged(node, true);

      final str = event.toString();
      expect(str, contains('NodeVisibilityChanged'));
      expect(str, contains('vis-node'));
      expect(str, contains('wasVisible'));
    });

    test('is a GraphEvent', () {
      final node = createTestNode();
      final event = NodeVisibilityChanged(node, true);

      expect(event, isA<GraphEvent>());
    });
  });

  group('NodeZIndexChanged', () {
    test('creates event with node and previous z-index', () {
      final node = createTestNode(id: 'zindex-node', zIndex: 10);
      final event = NodeZIndexChanged(node, 5);

      expect(event.node, equals(node));
      expect(event.previousZIndex, equals(5));
    });

    test('tracks z-index change correctly', () {
      final node = createTestNode(zIndex: 15);
      final event = NodeZIndexChanged(node, 3);

      expect(event.previousZIndex, equals(3));
      expect(event.node.currentZIndex, equals(15));
    });

    test('toString contains z-index information', () {
      final node = createTestNode(id: 'z-node', zIndex: 8);
      final event = NodeZIndexChanged(node, 2);

      final str = event.toString();
      expect(str, contains('NodeZIndexChanged'));
      expect(str, contains('z-node'));
    });

    test('is a GraphEvent', () {
      final node = createTestNode();
      final event = NodeZIndexChanged(node, 0);

      expect(event, isA<GraphEvent>());
    });
  });

  group('NodeLockChanged', () {
    test('creates event with node and wasLocked flag', () {
      final node = Node<String>(
        id: 'lock-node',
        type: 'test',
        position: Offset.zero,
        data: 'test',
        locked: true,
      );
      final event = NodeLockChanged(node, false);

      expect(event.node, equals(node));
      expect(event.wasLocked, isFalse);
    });

    test('tracks lock change from unlocked to locked', () {
      final node = Node<String>(
        id: 'lock-node',
        type: 'test',
        position: Offset.zero,
        data: 'test',
        locked: true,
      );
      final event = NodeLockChanged(node, false);

      expect(event.wasLocked, isFalse);
      expect(event.node.locked, isTrue);
    });

    test('tracks lock change from locked to unlocked', () {
      final node = Node<String>(
        id: 'lock-node',
        type: 'test',
        position: Offset.zero,
        data: 'test',
        locked: false,
      );
      final event = NodeLockChanged(node, true);

      expect(event.wasLocked, isTrue);
      expect(event.node.locked, isFalse);
    });

    test('toString contains lock information', () {
      final node = Node<String>(
        id: 'locked-node',
        type: 'test',
        position: Offset.zero,
        data: 'test',
        locked: true,
      );
      final event = NodeLockChanged(node, false);

      final str = event.toString();
      expect(str, contains('NodeLockChanged'));
      expect(str, contains('locked-node'));
      expect(str, contains('wasLocked'));
    });

    test('is a GraphEvent', () {
      final node = createTestNode();
      final event = NodeLockChanged(node, false);

      expect(event, isA<GraphEvent>());
    });
  });

  group('NodeGroupChanged', () {
    test('creates event with node and group IDs', () {
      final node = createTestNode(id: 'group-member');
      final event = NodeGroupChanged(node, 'old-group', 'new-group');

      expect(event.node, equals(node));
      expect(event.previousGroupId, equals('old-group'));
      expect(event.currentGroupId, equals('new-group'));
    });

    test('handles node added to group (null to group)', () {
      final node = createTestNode();
      final event = NodeGroupChanged(node, null, 'group-1');

      expect(event.previousGroupId, isNull);
      expect(event.currentGroupId, equals('group-1'));
    });

    test('handles node removed from group (group to null)', () {
      final node = createTestNode();
      final event = NodeGroupChanged(node, 'group-1', null);

      expect(event.previousGroupId, equals('group-1'));
      expect(event.currentGroupId, isNull);
    });

    test('handles node moved between groups', () {
      final node = createTestNode();
      final event = NodeGroupChanged(node, 'group-a', 'group-b');

      expect(event.previousGroupId, equals('group-a'));
      expect(event.currentGroupId, equals('group-b'));
    });

    test('toString contains group information', () {
      final node = createTestNode(id: 'grouped-node');
      final event = NodeGroupChanged(node, 'old', 'new');

      final str = event.toString();
      expect(str, contains('NodeGroupChanged'));
      expect(str, contains('grouped-node'));
    });

    test('is a GraphEvent', () {
      final node = createTestNode();
      final event = NodeGroupChanged(node, null, null);

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // Connection Events
  // ===========================================================================

  group('ConnectionAdded', () {
    test('creates event with connection', () {
      final connection = createTestConnection(
        id: 'test-conn',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final event = ConnectionAdded(connection);

      expect(event.connection, equals(connection));
    });

    test('connection property returns correct connection', () {
      final connection = createTestConnection(
        id: 'conn-123',
        sourceNodeId: 'source',
        sourcePortId: 'out-1',
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );
      final event = ConnectionAdded(connection);

      expect(event.connection.id, equals('conn-123'));
      expect(event.connection.sourceNodeId, equals('source'));
      expect(event.connection.targetNodeId, equals('target'));
    });

    test('toString contains connection id', () {
      final connection = createTestConnection(
        id: 'my-connection',
        sourceNodeId: 'a',
        targetNodeId: 'b',
      );
      final event = ConnectionAdded(connection);

      expect(event.toString(), contains('my-connection'));
      expect(event.toString(), contains('ConnectionAdded'));
    });

    test('is a GraphEvent', () {
      final connection = createTestConnection(
        sourceNodeId: 'a',
        targetNodeId: 'b',
      );
      final event = ConnectionAdded(connection);

      expect(event, isA<GraphEvent>());
    });
  });

  group('ConnectionRemoved', () {
    test('creates event with connection', () {
      final connection = createTestConnection(
        id: 'removed-conn',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final event = ConnectionRemoved(connection);

      expect(event.connection, equals(connection));
    });

    test('preserves full connection state for undo capability', () {
      final connection = createTestConnection(
        id: 'full-state-conn',
        sourceNodeId: 'source-node',
        sourcePortId: 'output',
        targetNodeId: 'target-node',
        targetPortId: 'input',
        animated: true,
      );
      final event = ConnectionRemoved(connection);

      expect(event.connection.sourceNodeId, equals('source-node'));
      expect(event.connection.targetNodeId, equals('target-node'));
      expect(event.connection.animated, isTrue);
    });

    test('toString contains connection id', () {
      final connection = createTestConnection(
        id: 'deleted-connection',
        sourceNodeId: 'a',
        targetNodeId: 'b',
      );
      final event = ConnectionRemoved(connection);

      expect(event.toString(), contains('deleted-connection'));
      expect(event.toString(), contains('ConnectionRemoved'));
    });

    test('is a GraphEvent', () {
      final connection = createTestConnection(
        sourceNodeId: 'a',
        targetNodeId: 'b',
      );
      final event = ConnectionRemoved(connection);

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // Selection Events
  // ===========================================================================

  group('SelectionChanged', () {
    test('creates event with all selection sets', () {
      final event = SelectionChanged(
        selectedNodeIds: {'node-1', 'node-2'},
        selectedConnectionIds: {'conn-1'},
        previousNodeIds: {'node-3'},
        previousConnectionIds: {},
      );

      expect(event.selectedNodeIds, equals({'node-1', 'node-2'}));
      expect(event.selectedConnectionIds, equals({'conn-1'}));
      expect(event.previousNodeIds, equals({'node-3'}));
      expect(event.previousConnectionIds, isEmpty);
    });

    test('tracks selection addition', () {
      final event = SelectionChanged(
        selectedNodeIds: {'node-1', 'node-2'},
        selectedConnectionIds: {},
        previousNodeIds: {'node-1'},
        previousConnectionIds: {},
      );

      // node-2 was added to selection
      expect(
        event.selectedNodeIds.difference(event.previousNodeIds),
        equals({'node-2'}),
      );
    });

    test('tracks selection removal', () {
      final event = SelectionChanged(
        selectedNodeIds: {'node-1'},
        selectedConnectionIds: {},
        previousNodeIds: {'node-1', 'node-2'},
        previousConnectionIds: {},
      );

      // node-2 was removed from selection
      expect(
        event.previousNodeIds.difference(event.selectedNodeIds),
        equals({'node-2'}),
      );
    });

    test('tracks clear selection', () {
      final event = SelectionChanged(
        selectedNodeIds: {},
        selectedConnectionIds: {},
        previousNodeIds: {'node-1', 'node-2'},
        previousConnectionIds: {'conn-1'},
      );

      expect(event.selectedNodeIds, isEmpty);
      expect(event.selectedConnectionIds, isEmpty);
    });

    test('handles empty selection states', () {
      final event = SelectionChanged(
        selectedNodeIds: {},
        selectedConnectionIds: {},
        previousNodeIds: {},
        previousConnectionIds: {},
      );

      expect(event.selectedNodeIds, isEmpty);
      expect(event.previousNodeIds, isEmpty);
    });

    test('toString contains selection counts', () {
      final event = SelectionChanged(
        selectedNodeIds: {'node-1', 'node-2', 'node-3'},
        selectedConnectionIds: {'conn-1', 'conn-2'},
        previousNodeIds: {},
        previousConnectionIds: {},
      );

      final str = event.toString();
      expect(str, contains('SelectionChanged'));
      expect(str, contains('3')); // nodes count
      expect(str, contains('2')); // connections count
    });

    test('is a GraphEvent', () {
      final event = SelectionChanged(
        selectedNodeIds: {},
        selectedConnectionIds: {},
        previousNodeIds: {},
        previousConnectionIds: {},
      );

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // Viewport Events
  // ===========================================================================

  group('ViewportChanged', () {
    test('creates event with viewports', () {
      final currentViewport = createTestViewport(x: 100, y: 50, zoom: 1.5);
      final previousViewport = createTestViewport(x: 0, y: 0, zoom: 1.0);
      final event = ViewportChanged(currentViewport, previousViewport);

      expect(event.viewport, equals(currentViewport));
      expect(event.previousViewport, equals(previousViewport));
    });

    test('tracks pan change', () {
      final currentViewport = createTestViewport(x: 200, y: 100, zoom: 1.0);
      final previousViewport = createTestViewport(x: 0, y: 0, zoom: 1.0);
      final event = ViewportChanged(currentViewport, previousViewport);

      expect(event.viewport.x, equals(200));
      expect(event.viewport.y, equals(100));
      expect(event.previousViewport.x, equals(0));
      expect(event.previousViewport.y, equals(0));
    });

    test('tracks zoom change', () {
      final currentViewport = createTestViewport(zoom: 2.0);
      final previousViewport = createTestViewport(zoom: 1.0);
      final event = ViewportChanged(currentViewport, previousViewport);

      expect(event.viewport.zoom, equals(2.0));
      expect(event.previousViewport.zoom, equals(1.0));
    });

    test('tracks combined pan and zoom change', () {
      final currentViewport = createTestViewport(x: 50, y: 25, zoom: 1.5);
      final previousViewport = createTestViewport(x: 0, y: 0, zoom: 1.0);
      final event = ViewportChanged(currentViewport, previousViewport);

      expect(event.viewport.x, equals(50));
      expect(event.viewport.zoom, equals(1.5));
    });

    test('toString contains zoom information', () {
      final currentViewport = createTestViewport(zoom: 2.5);
      final previousViewport = createTestViewport(zoom: 1.0);
      final event = ViewportChanged(currentViewport, previousViewport);

      final str = event.toString();
      expect(str, contains('ViewportChanged'));
      expect(str, contains('zoom'));
    });

    test('is a GraphEvent', () {
      final currentViewport = createTestViewport();
      final previousViewport = createTestViewport();
      final event = ViewportChanged(currentViewport, previousViewport);

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // Drag Events - Node Dragging
  // ===========================================================================

  group('NodeDragStarted', () {
    test('creates event with node IDs and start position', () {
      final event = NodeDragStarted({
        'node-1',
        'node-2',
      }, const Offset(100, 50));

      expect(event.nodeIds, equals({'node-1', 'node-2'}));
      expect(event.startPosition, equals(const Offset(100, 50)));
    });

    test('handles single node drag', () {
      final event = NodeDragStarted({'single-node'}, const Offset(0, 0));

      expect(event.nodeIds.length, equals(1));
      expect(event.nodeIds.first, equals('single-node'));
    });

    test('handles multi-node drag', () {
      final event = NodeDragStarted({
        'node-1',
        'node-2',
        'node-3',
      }, const Offset(50, 50));

      expect(event.nodeIds.length, equals(3));
    });

    test('toString contains node count', () {
      final event = NodeDragStarted({'a', 'b', 'c'}, Offset.zero);

      final str = event.toString();
      expect(str, contains('NodeDragStarted'));
      expect(str, contains('3')); // 3 nodes
    });

    test('is a GraphEvent', () {
      final event = NodeDragStarted({'node'}, Offset.zero);

      expect(event, isA<GraphEvent>());
    });
  });

  group('NodeDragEnded', () {
    test('creates event with node IDs and total delta', () {
      final event = NodeDragEnded({'node-1', 'node-2'}, const Offset(150, 75));

      expect(event.nodeIds, equals({'node-1', 'node-2'}));
      expect(event.totalDelta, equals(const Offset(150, 75)));
    });

    test('handles zero delta (click without movement)', () {
      final event = NodeDragEnded({'node'}, Offset.zero);

      expect(event.totalDelta, equals(Offset.zero));
    });

    test('handles negative delta', () {
      final event = NodeDragEnded({'node'}, const Offset(-100, -50));

      expect(event.totalDelta.dx, equals(-100));
      expect(event.totalDelta.dy, equals(-50));
    });

    test('toString contains node count and delta', () {
      final event = NodeDragEnded({'a', 'b'}, const Offset(100, 50));

      final str = event.toString();
      expect(str, contains('NodeDragEnded'));
      expect(str, contains('2')); // 2 nodes
      expect(str, contains('delta'));
    });

    test('is a GraphEvent', () {
      final event = NodeDragEnded({'node'}, Offset.zero);

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // Drag Events - Connection Dragging
  // ===========================================================================

  group('ConnectionDragStarted', () {
    test('creates event with source info', () {
      final event = ConnectionDragStarted(
        sourceNodeId: 'node-1',
        sourcePortId: 'output-1',
        isOutput: true,
      );

      expect(event.sourceNodeId, equals('node-1'));
      expect(event.sourcePortId, equals('output-1'));
      expect(event.isOutput, isTrue);
    });

    test('handles drag from output port', () {
      final event = ConnectionDragStarted(
        sourceNodeId: 'source',
        sourcePortId: 'out',
        isOutput: true,
      );

      expect(event.isOutput, isTrue);
    });

    test('handles drag from input port', () {
      final event = ConnectionDragStarted(
        sourceNodeId: 'target',
        sourcePortId: 'in',
        isOutput: false,
      );

      expect(event.isOutput, isFalse);
    });

    test('toString contains source info', () {
      final event = ConnectionDragStarted(
        sourceNodeId: 'my-node',
        sourcePortId: 'my-port',
        isOutput: true,
      );

      final str = event.toString();
      expect(str, contains('ConnectionDragStarted'));
      expect(str, contains('my-node'));
      expect(str, contains('my-port'));
      expect(str, contains('isOutput'));
    });

    test('is a GraphEvent', () {
      final event = ConnectionDragStarted(
        sourceNodeId: 'node',
        sourcePortId: 'port',
        isOutput: true,
      );

      expect(event, isA<GraphEvent>());
    });
  });

  group('ConnectionDragEnded', () {
    test('creates event for successful connection', () {
      final connection = createTestConnection(
        sourceNodeId: 'a',
        targetNodeId: 'b',
      );
      final event = ConnectionDragEnded(
        wasConnected: true,
        connection: connection,
      );

      expect(event.wasConnected, isTrue);
      expect(event.connection, equals(connection));
    });

    test('creates event for cancelled connection', () {
      final event = ConnectionDragEnded(wasConnected: false);

      expect(event.wasConnected, isFalse);
      expect(event.connection, isNull);
    });

    test('connection is null when cancelled', () {
      final event = ConnectionDragEnded(wasConnected: false, connection: null);

      expect(event.connection, isNull);
    });

    test('toString for successful connection', () {
      final connection = createTestConnection(
        id: 'new-conn',
        sourceNodeId: 'a',
        targetNodeId: 'b',
      );
      final event = ConnectionDragEnded(
        wasConnected: true,
        connection: connection,
      );

      final str = event.toString();
      expect(str, contains('ConnectionDragEnded'));
      expect(str, contains('wasConnected: true'));
      expect(str, contains('new-conn'));
    });

    test('toString for cancelled connection', () {
      final event = ConnectionDragEnded(wasConnected: false);

      final str = event.toString();
      expect(str, contains('ConnectionDragEnded'));
      expect(str, contains('wasConnected: false'));
    });

    test('is a GraphEvent', () {
      final event = ConnectionDragEnded(wasConnected: false);

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // Drag Events - Resize Dragging
  // ===========================================================================

  group('ResizeStarted', () {
    test('creates event with node ID and initial size', () {
      final event = ResizeStarted('node-1', const Size(100, 100));

      expect(event.nodeId, equals('node-1'));
      expect(event.initialSize, equals(const Size(100, 100)));
    });

    test('captures initial dimensions', () {
      final event = ResizeStarted('resize-node', const Size(200, 150));

      expect(event.initialSize.width, equals(200));
      expect(event.initialSize.height, equals(150));
    });

    test('toString contains node ID and size', () {
      final event = ResizeStarted('my-node', const Size(100, 100));

      final str = event.toString();
      expect(str, contains('ResizeStarted'));
      expect(str, contains('my-node'));
    });

    test('is a GraphEvent', () {
      final event = ResizeStarted('node', const Size(100, 100));

      expect(event, isA<GraphEvent>());
    });
  });

  group('ResizeEnded', () {
    test('creates event with node ID and both sizes', () {
      final event = ResizeEnded(
        'node-1',
        const Size(100, 100),
        const Size(200, 150),
      );

      expect(event.nodeId, equals('node-1'));
      expect(event.initialSize, equals(const Size(100, 100)));
      expect(event.finalSize, equals(const Size(200, 150)));
    });

    test('tracks size increase', () {
      final event = ResizeEnded(
        'node',
        const Size(100, 100),
        const Size(200, 200),
      );

      expect(event.finalSize.width, greaterThan(event.initialSize.width));
      expect(event.finalSize.height, greaterThan(event.initialSize.height));
    });

    test('tracks size decrease', () {
      final event = ResizeEnded(
        'node',
        const Size(200, 200),
        const Size(100, 100),
      );

      expect(event.finalSize.width, lessThan(event.initialSize.width));
      expect(event.finalSize.height, lessThan(event.initialSize.height));
    });

    test('handles no change', () {
      final size = const Size(100, 100);
      final event = ResizeEnded('node', size, size);

      expect(event.initialSize, equals(event.finalSize));
    });

    test('toString contains size information', () {
      final event = ResizeEnded(
        'resized',
        const Size(100, 100),
        const Size(200, 150),
      );

      final str = event.toString();
      expect(str, contains('ResizeEnded'));
      expect(str, contains('resized'));
    });

    test('is a GraphEvent', () {
      final event = ResizeEnded(
        'node',
        const Size(100, 100),
        const Size(150, 150),
      );

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // Hover Events
  // ===========================================================================

  group('NodeHoverChanged', () {
    test('creates event for hover start', () {
      final event = NodeHoverChanged('node-1', true);

      expect(event.nodeId, equals('node-1'));
      expect(event.isHovered, isTrue);
    });

    test('creates event for hover end', () {
      final event = NodeHoverChanged('node-1', false);

      expect(event.nodeId, equals('node-1'));
      expect(event.isHovered, isFalse);
    });

    test('toString contains hover state', () {
      final event = NodeHoverChanged('hover-node', true);

      final str = event.toString();
      expect(str, contains('NodeHoverChanged'));
      expect(str, contains('hover-node'));
      expect(str, contains('isHovered'));
    });

    test('is a GraphEvent', () {
      final event = NodeHoverChanged('node', true);

      expect(event, isA<GraphEvent>());
    });
  });

  group('ConnectionHoverChanged', () {
    test('creates event for hover start', () {
      final event = ConnectionHoverChanged('conn-1', true);

      expect(event.connectionId, equals('conn-1'));
      expect(event.isHovered, isTrue);
    });

    test('creates event for hover end', () {
      final event = ConnectionHoverChanged('conn-1', false);

      expect(event.connectionId, equals('conn-1'));
      expect(event.isHovered, isFalse);
    });

    test('toString contains hover state', () {
      final event = ConnectionHoverChanged('hover-conn', true);

      final str = event.toString();
      expect(str, contains('ConnectionHoverChanged'));
      expect(str, contains('hover-conn'));
      expect(str, contains('isHovered'));
    });

    test('is a GraphEvent', () {
      final event = ConnectionHoverChanged('conn', true);

      expect(event, isA<GraphEvent>());
    });
  });

  group('PortHoverChanged', () {
    test('creates event for output port hover start', () {
      final event = PortHoverChanged(
        nodeId: 'node-1',
        portId: 'output-1',
        isHovered: true,
        isOutput: true,
      );

      expect(event.nodeId, equals('node-1'));
      expect(event.portId, equals('output-1'));
      expect(event.isHovered, isTrue);
      expect(event.isOutput, isTrue);
    });

    test('creates event for input port hover start', () {
      final event = PortHoverChanged(
        nodeId: 'node-1',
        portId: 'input-1',
        isHovered: true,
        isOutput: false,
      );

      expect(event.nodeId, equals('node-1'));
      expect(event.portId, equals('input-1'));
      expect(event.isHovered, isTrue);
      expect(event.isOutput, isFalse);
    });

    test('creates event for hover end', () {
      final event = PortHoverChanged(
        nodeId: 'node-1',
        portId: 'port-1',
        isHovered: false,
        isOutput: true,
      );

      expect(event.isHovered, isFalse);
    });

    test('toString contains port info', () {
      final event = PortHoverChanged(
        nodeId: 'my-node',
        portId: 'my-port',
        isHovered: true,
        isOutput: true,
      );

      final str = event.toString();
      expect(str, contains('PortHoverChanged'));
      expect(str, contains('my-node'));
      expect(str, contains('my-port'));
    });

    test('is a GraphEvent', () {
      final event = PortHoverChanged(
        nodeId: 'node',
        portId: 'port',
        isHovered: true,
        isOutput: true,
      );

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // Lifecycle Events
  // ===========================================================================

  group('GraphCleared', () {
    test('creates event with previous counts', () {
      final event = GraphCleared(
        previousNodeCount: 10,
        previousConnectionCount: 15,
      );

      expect(event.previousNodeCount, equals(10));
      expect(event.previousConnectionCount, equals(15));
    });

    test('handles empty graph clear', () {
      final event = GraphCleared(
        previousNodeCount: 0,
        previousConnectionCount: 0,
      );

      expect(event.previousNodeCount, equals(0));
      expect(event.previousConnectionCount, equals(0));
    });

    test('handles large graph clear', () {
      final event = GraphCleared(
        previousNodeCount: 1000,
        previousConnectionCount: 5000,
      );

      expect(event.previousNodeCount, equals(1000));
      expect(event.previousConnectionCount, equals(5000));
    });

    test('toString contains counts', () {
      final event = GraphCleared(
        previousNodeCount: 5,
        previousConnectionCount: 8,
      );

      final str = event.toString();
      expect(str, contains('GraphCleared'));
      expect(str, contains('5'));
      expect(str, contains('8'));
    });

    test('is a GraphEvent', () {
      final event = GraphCleared(
        previousNodeCount: 0,
        previousConnectionCount: 0,
      );

      expect(event, isA<GraphEvent>());
    });
  });

  group('GraphLoaded', () {
    test('creates event with loaded counts', () {
      final event = GraphLoaded(nodeCount: 20, connectionCount: 30);

      expect(event.nodeCount, equals(20));
      expect(event.connectionCount, equals(30));
    });

    test('handles empty graph load', () {
      final event = GraphLoaded(nodeCount: 0, connectionCount: 0);

      expect(event.nodeCount, equals(0));
      expect(event.connectionCount, equals(0));
    });

    test('handles large graph load', () {
      final event = GraphLoaded(nodeCount: 2000, connectionCount: 10000);

      expect(event.nodeCount, equals(2000));
      expect(event.connectionCount, equals(10000));
    });

    test('toString contains counts', () {
      final event = GraphLoaded(nodeCount: 12, connectionCount: 25);

      final str = event.toString();
      expect(str, contains('GraphLoaded'));
      expect(str, contains('12'));
      expect(str, contains('25'));
    });

    test('is a GraphEvent', () {
      final event = GraphLoaded(nodeCount: 0, connectionCount: 0);

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // Batch Events
  // ===========================================================================

  group('BatchStarted', () {
    test('creates event with reason', () {
      final event = BatchStarted('multi-node-move');

      expect(event.reason, equals('multi-node-move'));
    });

    test('supports various batch reasons', () {
      final moveEvent = BatchStarted('multi-node-move');
      final pasteEvent = BatchStarted('paste');
      final deleteEvent = BatchStarted('delete-selection');

      expect(moveEvent.reason, equals('multi-node-move'));
      expect(pasteEvent.reason, equals('paste'));
      expect(deleteEvent.reason, equals('delete-selection'));
    });

    test('toString contains reason', () {
      final event = BatchStarted('test-batch');

      final str = event.toString();
      expect(str, contains('BatchStarted'));
      expect(str, contains('test-batch'));
    });

    test('is a GraphEvent', () {
      final event = BatchStarted('reason');

      expect(event, isA<GraphEvent>());
    });
  });

  group('BatchEnded', () {
    test('creates event', () {
      final event = BatchEnded();

      expect(event, isNotNull);
    });

    test('toString returns expected format', () {
      final event = BatchEnded();

      final str = event.toString();
      expect(str, contains('BatchEnded'));
    });

    test('is a GraphEvent', () {
      final event = BatchEnded();

      expect(event, isA<GraphEvent>());
    });

    test('can be const constructed', () {
      const event = BatchEnded();

      expect(event, isNotNull);
    });
  });

  // ===========================================================================
  // LOD Events
  // ===========================================================================

  group('LODLevelChanged', () {
    test('creates event with visibility configurations', () {
      final event = LODLevelChanged(
        previousVisibility: DetailVisibility.minimal,
        currentVisibility: DetailVisibility.standard,
        normalizedZoom: 0.5,
      );

      expect(event.previousVisibility, equals(DetailVisibility.minimal));
      expect(event.currentVisibility, equals(DetailVisibility.standard));
      expect(event.normalizedZoom, equals(0.5));
    });

    test('tracks zoom in (minimal to standard)', () {
      final event = LODLevelChanged(
        previousVisibility: DetailVisibility.minimal,
        currentVisibility: DetailVisibility.standard,
        normalizedZoom: 0.4,
      );

      expect(event.previousVisibility.showNodeContent, isFalse);
      expect(event.currentVisibility.showNodeContent, isTrue);
    });

    test('tracks zoom in (standard to full)', () {
      final event = LODLevelChanged(
        previousVisibility: DetailVisibility.standard,
        currentVisibility: DetailVisibility.full,
        normalizedZoom: 0.8,
      );

      expect(event.previousVisibility.showPortLabels, isFalse);
      expect(event.currentVisibility.showPortLabels, isTrue);
    });

    test('tracks zoom out (full to standard)', () {
      final event = LODLevelChanged(
        previousVisibility: DetailVisibility.full,
        currentVisibility: DetailVisibility.standard,
        normalizedZoom: 0.35,
      );

      expect(event.previousVisibility.showResizeHandles, isTrue);
      expect(event.currentVisibility.showResizeHandles, isFalse);
    });

    test('tracks zoom out (standard to minimal)', () {
      final event = LODLevelChanged(
        previousVisibility: DetailVisibility.standard,
        currentVisibility: DetailVisibility.minimal,
        normalizedZoom: 0.1,
      );

      expect(event.previousVisibility.showNodeContent, isTrue);
      expect(event.currentVisibility.showNodeContent, isFalse);
    });

    test('handles custom visibility configurations', () {
      final custom = DetailVisibility(
        showNodeContent: true,
        showPorts: true,
        showPortLabels: false,
        showConnectionLines: true,
        showConnectionLabels: false,
        showConnectionEndpoints: true,
        showResizeHandles: false,
      );

      final event = LODLevelChanged(
        previousVisibility: DetailVisibility.minimal,
        currentVisibility: custom,
        normalizedZoom: 0.6,
      );

      expect(event.currentVisibility.showPorts, isTrue);
      expect(event.currentVisibility.showPortLabels, isFalse);
    });

    test('normalizedZoom is in valid range', () {
      final event = LODLevelChanged(
        previousVisibility: DetailVisibility.minimal,
        currentVisibility: DetailVisibility.full,
        normalizedZoom: 0.75,
      );

      expect(event.normalizedZoom, greaterThanOrEqualTo(0.0));
      expect(event.normalizedZoom, lessThanOrEqualTo(1.0));
    });

    test('toString contains zoom information', () {
      final event = LODLevelChanged(
        previousVisibility: DetailVisibility.minimal,
        currentVisibility: DetailVisibility.full,
        normalizedZoom: 0.65,
      );

      final str = event.toString();
      expect(str, contains('LODLevelChanged'));
      expect(str, contains('zoom'));
    });

    test('is a GraphEvent', () {
      final event = LODLevelChanged(
        previousVisibility: DetailVisibility.minimal,
        currentVisibility: DetailVisibility.full,
        normalizedZoom: 0.5,
      );

      expect(event, isA<GraphEvent>());
    });
  });

  // ===========================================================================
  // GraphEvent Base Class
  // ===========================================================================

  group('GraphEvent sealed class', () {
    test('all event types extend GraphEvent', () {
      final node = createTestNode();
      final connection = createTestConnection(
        sourceNodeId: 'a',
        targetNodeId: 'b',
      );
      final viewport = createTestViewport();

      final events = <GraphEvent>[
        NodeAdded(node),
        NodeRemoved(node),
        NodeMoved(node, Offset.zero),
        NodeResized(node, const Size(100, 100)),
        NodeDataChanged(node, 'old'),
        NodeVisibilityChanged(node, true),
        NodeZIndexChanged(node, 0),
        NodeLockChanged(node, false),
        NodeGroupChanged(node, null, null),
        ConnectionAdded(connection),
        ConnectionRemoved(connection),
        SelectionChanged(
          selectedNodeIds: {},
          selectedConnectionIds: {},
          previousNodeIds: {},
          previousConnectionIds: {},
        ),
        ViewportChanged(viewport, viewport),
        NodeDragStarted({'node'}, Offset.zero),
        NodeDragEnded({'node'}, Offset.zero),
        ConnectionDragStarted(
          sourceNodeId: 'node',
          sourcePortId: 'port',
          isOutput: true,
        ),
        ConnectionDragEnded(wasConnected: false),
        ResizeStarted('node', const Size(100, 100)),
        ResizeEnded('node', const Size(100, 100), const Size(150, 150)),
        NodeHoverChanged('node', true),
        ConnectionHoverChanged('conn', true),
        PortHoverChanged(
          nodeId: 'node',
          portId: 'port',
          isHovered: true,
          isOutput: true,
        ),
        GraphCleared(previousNodeCount: 0, previousConnectionCount: 0),
        GraphLoaded(nodeCount: 0, connectionCount: 0),
        BatchStarted('test'),
        const BatchEnded(),
        LODLevelChanged(
          previousVisibility: DetailVisibility.minimal,
          currentVisibility: DetailVisibility.full,
          normalizedZoom: 0.5,
        ),
      ];

      for (final event in events) {
        expect(
          event,
          isA<GraphEvent>(),
          reason: '${event.runtimeType} should be a GraphEvent',
        );
      }
    });

    test('supports pattern matching', () {
      final node = createTestNode(id: 'pattern-test');
      final event = NodeAdded(node) as GraphEvent;

      final result = switch (event) {
        NodeAdded(:final node) => 'Added: ${node.id}',
        NodeRemoved(:final node) => 'Removed: ${node.id}',
        _ => 'Other event',
      };

      expect(result, equals('Added: pattern-test'));
    });
  });
}
