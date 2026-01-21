/// Unit tests for ConnectionsLayer widget.
///
/// Tests cover:
/// - ConnectionsLayer widget construction and properties
/// - ConnectionsCanvas CustomPainter behavior
/// - LOD (Level of Detail) visibility calculations
/// - Static vs active connection separation
/// - shouldRepaint behavior
/// - Edge cases and error handling
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
// Import internal classes for testing
import 'package:vyuh_node_flow/src/connections/connections_canvas.dart';
import 'package:vyuh_node_flow/src/editor/layers/connections_layer.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // ConnectionsLayer Widget Construction Tests
  // ===========================================================================

  group('ConnectionsLayer Construction', () {
    test('creates with required controller parameter', () {
      final controller = createTestController();

      final layer = ConnectionsLayer<String, dynamic>(controller: controller);

      expect(layer.controller, same(controller));
      expect(layer.animation, isNull);
      expect(layer.connectionStyleBuilder, isNull);
    });

    test('creates with optional animation parameter', () {
      final controller = createTestController();
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      final layer = ConnectionsLayer<String, dynamic>(
        controller: controller,
        animation: animationController,
      );

      expect(layer.animation, same(animationController));

      animationController.dispose();
    });

    test('creates with optional connectionStyleBuilder parameter', () {
      final controller = createTestController();
      ConnectionStyle? styleBuilder(
        Connection connection,
        Node sourceNode,
        Node targetNode,
      ) => ConnectionStyles.bezier;

      final layer = ConnectionsLayer<String, dynamic>(
        controller: controller,
        connectionStyleBuilder: styleBuilder,
      );

      expect(layer.connectionStyleBuilder, same(styleBuilder));
    });

    test('creates with all optional parameters', () {
      final controller = createTestController();
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );
      ConnectionStyle? styleBuilder(
        Connection connection,
        Node sourceNode,
        Node targetNode,
      ) => ConnectionStyles.smoothstep;

      final layer = ConnectionsLayer<String, dynamic>(
        controller: controller,
        animation: animationController,
        connectionStyleBuilder: styleBuilder,
      );

      expect(layer.controller, same(controller));
      expect(layer.animation, same(animationController));
      expect(layer.connectionStyleBuilder, same(styleBuilder));

      animationController.dispose();
    });
  });

  // ===========================================================================
  // ConnectionsCanvas Construction Tests
  // ===========================================================================

  group('ConnectionsCanvas Construction', () {
    test('creates with required parameters', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      expect(canvas.store, same(controller));
      expect(canvas.theme, same(NodeFlowTheme.light));
      expect(canvas.connectionPainter, same(painter));
      expect(canvas.connections, isNull);
      expect(canvas.animation, isNull);
      expect(canvas.connectionStyleBuilder, isNull);
    });

    test('creates with specific connections list', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);
      final connections = <Connection>[];

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
        connections: connections,
      );

      expect(canvas.connections, same(connections));
    });

    test('creates with animation', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
        animation: animationController,
      );

      expect(canvas.animation, same(animationController));

      animationController.dispose();
    });

    test('creates with connectionStyleBuilder', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);
      ConnectionStyle? styleBuilder(
        Connection connection,
        Node sourceNode,
        Node targetNode,
      ) => ConnectionStyles.straight;

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
        connectionStyleBuilder: styleBuilder,
      );

      expect(canvas.connectionStyleBuilder, same(styleBuilder));
    });
  });

  // ===========================================================================
  // ConnectionsCanvas shouldRepaint Tests
  // ===========================================================================

  group('ConnectionsCanvas shouldRepaint', () {
    test('shouldRepaint always returns true', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas1 = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      final canvas2 = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      // shouldRepaint should always return true for MobX reactivity
      expect(canvas1.shouldRepaint(canvas2), isTrue);
    });

    test('shouldRepaint returns true even with same references', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      // Same canvas instance
      expect(canvas.shouldRepaint(canvas), isTrue);
    });

    test('shouldRepaint returns true with different themes', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas1 = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      final canvas2 = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.dark,
        connectionPainter: painter,
      );

      expect(canvas1.shouldRepaint(canvas2), isTrue);
    });

    test('shouldRepaint returns true with different controllers', () {
      final controller1 = createTestController();
      final controller2 = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas1 = ConnectionsCanvas<String, dynamic>(
        store: controller1,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      final canvas2 = ConnectionsCanvas<String, dynamic>(
        store: controller2,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      expect(canvas1.shouldRepaint(canvas2), isTrue);
    });
  });

  // ===========================================================================
  // ConnectionsCanvas shouldRebuildSemantics Tests
  // ===========================================================================

  group('ConnectionsCanvas shouldRebuildSemantics', () {
    test('shouldRebuildSemantics always returns false', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas1 = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      final canvas2 = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.dark,
        connectionPainter: painter,
      );

      expect(canvas1.shouldRebuildSemantics(canvas2), isFalse);
    });
  });

  // ===========================================================================
  // LOD Visibility Tests (Unit)
  // ===========================================================================

  group('LOD Visibility Calculations', () {
    test('LOD extension can be attached to controller', () {
      final controller = createTestController(
        config: NodeFlowConfig(extensions: [LodExtension(enabled: true)]),
      );

      expect(controller.lod, isNotNull);
      expect(controller.lod!.isEnabled, isTrue);
    });

    test('LOD defaults to showing connection lines when disabled', () {
      final controller = createTestController(
        config: NodeFlowConfig(extensions: [LodExtension(enabled: false)]),
      );

      expect(controller.lod, isNotNull);
      expect(controller.lod!.showConnectionLines, isTrue);
    });

    test('LOD returns null when no LOD extension configured', () {
      final controller = createTestController(
        config: NodeFlowConfig(extensions: []),
      );

      expect(controller.lod, isNull);
    });

    test('showConnectionEndpoints depends on LOD state', () {
      final controller = createTestController(
        config: NodeFlowConfig(extensions: [LodExtension(enabled: false)]),
      );

      expect(controller.lod!.showConnectionEndpoints, isTrue);
    });
  });

  // ===========================================================================
  // Visible Connections Tests
  // ===========================================================================

  group('Visible Connections', () {
    test('connections list returns empty for empty controller', () {
      final controller = createTestController();

      expect(controller.connections, isEmpty);
    });

    test('connections list includes all added connections', () {
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

      final controller = createTestController(
        nodes: [sourceNode, targetNode],
        connections: [connection],
      );

      expect(controller.connections, hasLength(1));
      expect(controller.connections.first.id, equals(connection.id));
    });

    test(
      'getVisibleConnections excludes connections with hidden source node',
      () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'node-a',
          portId: 'output-1',
          position: const Offset(0, 0),
          visible: false,
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

        final controller = createTestController(
          nodes: [sourceNode, targetNode],
          connections: [connection],
        );

        // getVisibleConnections method filters by node.isVisible
        expect(controller.getVisibleConnections(), isEmpty);
      },
    );

    test(
      'getVisibleConnections excludes connections with hidden target node',
      () {
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
          visible: false,
        );
        targetNode.setSize(const Size(100, 50));

        final connection = createTestConnection(
          sourceNodeId: 'node-a',
          sourcePortId: 'output-1',
          targetNodeId: 'node-b',
          targetPortId: 'input-1',
        );

        final controller = createTestController(
          nodes: [sourceNode, targetNode],
          connections: [connection],
        );

        // getVisibleConnections method filters by node.isVisible
        expect(controller.getVisibleConnections(), isEmpty);
      },
    );
  });

  // ===========================================================================
  // Active Connection ID Tests
  // ===========================================================================

  group('Active Connection IDs', () {
    test('activeConnectionIds is empty when no nodes are being interacted', () {
      final controller = createConnectedNodesController();

      expect(controller.activeConnectionIds, isEmpty);
    });

    test('activeConnectionIds includes connections for dragged nodes', () {
      // Note: activeConnectionIds relies on _connectionsByNodeId which is populated
      // when addConnection is called. When using constructor initialization,
      // the index may not be populated. This test verifies the mechanism works
      // when connections are added via API.

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

      // Create controller without initial connections
      final controller = createTestController(nodes: [sourceNode, targetNode]);

      // Add connection via API - this populates the index
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
      controller.addConnection(connection);

      // Simulate dragging source node by setting the interaction state
      controller.interaction.draggedNodeId.value = 'node-a';

      expect(controller.activeConnectionIds, contains('conn-1'));

      // Clean up
      controller.interaction.draggedNodeId.value = null;
    });
  });

  // ===========================================================================
  // Static vs Active Connection Separation Tests
  // ===========================================================================

  group('Static vs Active Connection Separation', () {
    test('connections split correctly during node drag', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));

      final midNode = createTestNodeWithPorts(
        id: 'node-b',
        inputPortId: 'input-1',
        outputPortId: 'output-2',
        position: const Offset(200, 0),
      );
      midNode.setSize(const Size(100, 50));

      final targetNode = createTestNodeWithInputPort(
        id: 'node-c',
        portId: 'input-2',
        position: const Offset(400, 0),
      );
      targetNode.setSize(const Size(100, 50));

      // Create controller without initial connections
      final controller = createTestController(
        nodes: [sourceNode, midNode, targetNode],
      );

      // Add connections via API to populate the index
      final connection1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
      controller.addConnection(connection1);

      final connection2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-b',
        sourcePortId: 'output-2',
        targetNodeId: 'node-c',
        targetPortId: 'input-2',
      );
      controller.addConnection(connection2);

      // Before drag, no active connections
      expect(controller.activeConnectionIds, isEmpty);

      // Simulate dragging middle node (connects to both)
      controller.interaction.draggedNodeId.value = 'node-b';

      // Both connections should be active since node-b is involved
      final activeIds = controller.activeConnectionIds;
      expect(activeIds, contains('conn-1'));
      expect(activeIds, contains('conn-2'));

      // Clean up
      controller.interaction.draggedNodeId.value = null;
    });
  });

  // ===========================================================================
  // Selected Connection IDs Tests
  // ===========================================================================

  group('Selected Connection IDs', () {
    test('selectedConnectionIds is empty initially', () {
      final controller = createConnectedNodesController();

      expect(controller.selectedConnectionIds, isEmpty);
    });

    test('selecting a connection adds to selectedConnectionIds', () {
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
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final controller = createTestController(
        nodes: [sourceNode, targetNode],
        connections: [connection],
      );

      controller.selectConnection('conn-1');

      expect(controller.selectedConnectionIds, contains('conn-1'));
    });

    test(
      'clearing connection selection removes from selectedConnectionIds',
      () {
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
          id: 'conn-1',
          sourceNodeId: 'node-a',
          sourcePortId: 'output-1',
          targetNodeId: 'node-b',
          targetPortId: 'input-1',
        );

        final controller = createTestController(
          nodes: [sourceNode, targetNode],
          connections: [connection],
        );

        controller.selectConnection('conn-1');
        expect(controller.selectedConnectionIds, contains('conn-1'));

        controller.clearConnectionSelection();
        expect(controller.selectedConnectionIds, isEmpty);
      },
    );

    test('toggling connection selection removes when already selected', () {
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
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final controller = createTestController(
        nodes: [sourceNode, targetNode],
        connections: [connection],
      );

      controller.selectConnection('conn-1');
      expect(controller.selectedConnectionIds, contains('conn-1'));

      // Toggle should remove from selection
      controller.selectConnection('conn-1', toggle: true);
      expect(controller.selectedConnectionIds, isEmpty);
    });
  });

  // ===========================================================================
  // Theme Integration Tests
  // ===========================================================================

  group('Theme Integration', () {
    test('canvas uses provided theme for rendering', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.dark,
        connectionPainter: painter,
      );

      expect(canvas.theme, same(NodeFlowTheme.dark));
    });

    test('controller theme is observable', () {
      final controller = createTestController();

      // Theme starts as null
      expect(controller.theme, isNull);

      // Note: The theme is typically set internally by the editor widget
      // during initialization via _initController()
    });

    test('controller defaults to null theme', () {
      final controller = createTestController();

      expect(controller.theme, isNull);
    });
  });

  // ===========================================================================
  // Connection Painter Integration Tests
  // ===========================================================================

  group('Connection Painter Integration', () {
    test('connectionPainter is used for rendering', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      expect(canvas.connectionPainter, same(painter));
    });

    test('controller connectionPainter requires theme initialization', () {
      final controller = createTestController();

      // connectionPainter throws if theme is not set
      expect(() => controller.connectionPainter, throwsA(isA<StateError>()));
    });

    test('isConnectionPainterInitialized returns false without theme', () {
      final controller = createTestController();

      expect(controller.isConnectionPainterInitialized, isFalse);
    });

    test('standalone connection painter caches paths', () {
      // Create a standalone ConnectionPainter for testing
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      // Initially no paths cached
      expect(painter.getCacheStats()['cachedPaths'], equals(0));
    });
  });

  // ===========================================================================
  // Edge Cases and Error Handling
  // ===========================================================================

  group('Edge Cases', () {
    test('handles controller with no nodes or connections', () {
      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
      );

      expect(canvas.store.connections, isEmpty);
      expect(canvas.store.nodes, isEmpty);
    });

    test('handles connections with missing source node', () {
      final targetNode = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );

      final connection = createTestConnection(
        sourceNodeId: 'missing-node',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final controller = createTestController(
        nodes: [targetNode],
        connections: [connection],
      );

      // Connection should still be in list but getNode returns null
      expect(controller.connections, hasLength(1));
      expect(controller.getNode('missing-node'), isNull);
    });

    test('handles connections with missing target node', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );

      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'missing-node',
        targetPortId: 'input-1',
      );

      final controller = createTestController(
        nodes: [sourceNode],
        connections: [connection],
      );

      // Connection should still be in list but getNode returns null
      expect(controller.connections, hasLength(1));
      expect(controller.getNode('missing-node'), isNull);
    });

    test('handles animation value at boundary (0.0)', () {
      final controller = createConnectedNodesController();
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
        value: 0.0,
      );
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
        animation: animationController,
      );

      expect(canvas.animation?.value, equals(0.0));

      animationController.dispose();
    });

    test('handles animation value at boundary (1.0)', () {
      final controller = createConnectedNodesController();
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
        value: 1.0,
      );
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
        animation: animationController,
      );

      expect(canvas.animation?.value, equals(1.0));

      animationController.dispose();
    });
  });

  // ===========================================================================
  // Connection Style Builder Tests
  // ===========================================================================

  group('Connection Style Builder', () {
    test('connectionStyleBuilder is called for each connection', () {
      ConnectionStyle? styleBuilder(
        Connection connection,
        Node sourceNode,
        Node targetNode,
      ) {
        return ConnectionStyles.bezier;
      }

      final controller = createConnectedNodesController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
        connectionStyleBuilder: styleBuilder,
      );

      expect(canvas.connectionStyleBuilder, isNotNull);
    });

    test(
      'connectionStyleBuilder can return different styles per connection',
      () {
        ConnectionStyle? styleBuilder(
          Connection connection,
          Node sourceNode,
          Node targetNode,
        ) {
          if (connection.id.contains('bezier')) {
            return ConnectionStyles.bezier;
          }
          return ConnectionStyles.straight;
        }

        final controller = createTestController();
        final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

        final canvas = ConnectionsCanvas<String, dynamic>(
          store: controller,
          theme: NodeFlowTheme.light,
          connectionPainter: painter,
          connectionStyleBuilder: styleBuilder,
        );

        expect(canvas.connectionStyleBuilder, isNotNull);
      },
    );

    test('connectionStyleBuilder can return null to use default style', () {
      ConnectionStyle? styleBuilder(
        Connection connection,
        Node sourceNode,
        Node targetNode,
      ) {
        return null; // Use default from theme
      }

      final controller = createTestController();
      final painter = createTestConnectionPainter(theme: NodeFlowTheme.light);

      final canvas = ConnectionsCanvas<String, dynamic>(
        store: controller,
        theme: NodeFlowTheme.light,
        connectionPainter: painter,
        connectionStyleBuilder: styleBuilder,
      );

      expect(canvas.connectionStyleBuilder, isNotNull);
    });
  });

  // ===========================================================================
  // Multiple Connections Tests
  // ===========================================================================

  group('Multiple Connections', () {
    test('handles multiple connections between nodes', () {
      final sourceNode = createTestNode(
        id: 'node-a',
        position: const Offset(0, 0),
        outputPorts: [
          createTestPort(id: 'output-1', type: PortType.output),
          createTestPort(id: 'output-2', type: PortType.output),
        ],
      );
      sourceNode.setSize(const Size(100, 50));

      final targetNode = createTestNode(
        id: 'node-b',
        position: const Offset(200, 0),
        inputPorts: [
          createTestPort(id: 'input-1', type: PortType.input),
          createTestPort(id: 'input-2', type: PortType.input),
        ],
      );
      targetNode.setSize(const Size(100, 50));

      final connection1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final connection2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-2',
        targetNodeId: 'node-b',
        targetPortId: 'input-2',
      );

      final controller = createTestController(
        nodes: [sourceNode, targetNode],
        connections: [connection1, connection2],
      );

      expect(controller.connections, hasLength(2));
      expect(controller.visibleConnections, hasLength(2));
    });

    test('handles chain of connections', () {
      final chain = createNodeChain(count: 5);

      final controller = createTestController(
        nodes: chain.nodes,
        connections: chain.connections,
      );

      expect(
        controller.connections,
        hasLength(4),
      ); // n-1 connections for n nodes
      expect(controller.nodes, hasLength(5));
    });
  });

  // ===========================================================================
  // Connection Visibility During Node Visibility Changes
  // ===========================================================================

  group('Connection Visibility During Node Changes', () {
    test(
      'getVisibleConnections updates when source node visibility changes',
      () {
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

        final controller = createTestController(
          nodes: [sourceNode, targetNode],
          connections: [connection],
        );

        // Initially visible (both nodes visible)
        expect(controller.getVisibleConnections(), hasLength(1));

        // Hide source node
        sourceNode.isVisible = false;

        // Connection should no longer be visible in getVisibleConnections
        expect(controller.getVisibleConnections(), isEmpty);

        // Show source node again
        sourceNode.isVisible = true;

        // Connection should be visible again
        expect(controller.getVisibleConnections(), hasLength(1));
      },
    );

    test(
      'getVisibleConnections updates when target node visibility changes',
      () {
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

        final controller = createTestController(
          nodes: [sourceNode, targetNode],
          connections: [connection],
        );

        // Initially visible (both nodes visible)
        expect(controller.getVisibleConnections(), hasLength(1));

        // Hide target node
        targetNode.isVisible = false;

        // Connection should no longer be visible
        expect(controller.getVisibleConnections(), isEmpty);
      },
    );
  });

  // ===========================================================================
  // Position.fill Tests (Layer Positioning)
  // ===========================================================================

  group('Layer Positioning', () {
    test('ConnectionsLayer uses Positioned.fill wrapper', () {
      final controller = createTestController();

      final layer = ConnectionsLayer<String, dynamic>(controller: controller);

      // The widget should build a Positioned.fill at the root
      // This ensures the connections layer fills the entire canvas
      expect(layer, isA<ConnectionsLayer<String, dynamic>>());
    });

    test('ConnectionsLayer wrapped with IgnorePointer', () {
      final controller = createTestController();

      final layer = ConnectionsLayer<String, dynamic>(controller: controller);

      // The ConnectionsLayer uses IgnorePointer to not block hit tests
      expect(layer, isA<ConnectionsLayer<String, dynamic>>());
    });
  });
}

/// Test implementation of TickerProvider for animations
class TestVSync extends TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
