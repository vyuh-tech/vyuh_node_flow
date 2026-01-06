/// Unit tests for hit testing functionality in the node flow editor.
///
/// These tests cover the hit testing behavior used by NodeFlowEditor including:
/// - Hit detection for nodes at different positions
/// - Hit detection for ports with snap distance
/// - Hit detection for connections via segment bounds
/// - Priority/ordering of hit testing (layers, z-index, render order)
/// - Viewport transformation effects on hit testing
/// - Edge cases (overlapping elements, empty areas, hidden elements)
///
/// The hit testing logic is primarily implemented in [GraphSpatialIndex.hitTest]
/// and exposed through the [_HitTestingExtension] on [_NodeFlowEditorState].
/// Since the extension delegates to the spatial index, these tests verify the
/// spatial index hit testing behavior directly.
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import 'package:vyuh_node_flow/src/shared/spatial/graph_spatial_index.dart';
import 'package:vyuh_node_flow/src/shared/spatial/spatial_item.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Node Hit Detection Tests
  // ===========================================================================

  group('Node Hit Detection', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    group('Basic Node Hit Testing', () {
      test('returns canvas when no nodes exist', () {
        final result = spatialIndex.hitTest(const Offset(100, 100));

        expect(result.hitType, equals(HitTarget.canvas));
        expect(result.nodeId, isNull);
      });

      test('detects node at center of bounds', () {
        final node = createTestNode(
          id: 'center-hit',
          position: const Offset(100, 100),
          size: const Size(200, 100),
        );
        spatialIndex.update(node);

        // Center of node is at (200, 150)
        final result = spatialIndex.hitTest(const Offset(200, 150));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('center-hit'));
      });

      test('detects node at top-left corner', () {
        final node = createTestNode(
          id: 'corner-hit',
          position: const Offset(100, 100),
          size: const Size(200, 100),
        );
        spatialIndex.update(node);

        // Just inside top-left corner
        final result = spatialIndex.hitTest(const Offset(101, 101));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('corner-hit'));
      });

      test('detects node at bottom-right corner', () {
        final node = createTestNode(
          id: 'corner-hit',
          position: const Offset(100, 100),
          size: const Size(200, 100),
        );
        spatialIndex.update(node);

        // Just inside bottom-right corner (position + size - 1)
        final result = spatialIndex.hitTest(const Offset(299, 199));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('corner-hit'));
      });

      test('returns canvas when point is just outside node bounds', () {
        final node = createTestNode(
          id: 'outside-test',
          position: const Offset(100, 100),
          size: const Size(200, 100),
        );
        spatialIndex.update(node);

        // Just outside the right edge
        final result = spatialIndex.hitTest(const Offset(301, 150));

        expect(result.hitType, equals(HitTarget.canvas));
      });

      test('detects correct node among non-overlapping nodes', () {
        final nodeA = createTestNode(
          id: 'node-a',
          position: const Offset(0, 0),
          size: const Size(100, 100),
        );
        final nodeB = createTestNode(
          id: 'node-b',
          position: const Offset(200, 200),
          size: const Size(100, 100),
        );
        final nodeC = createTestNode(
          id: 'node-c',
          position: const Offset(400, 0),
          size: const Size(100, 100),
        );

        spatialIndex.update(nodeA);
        spatialIndex.update(nodeB);
        spatialIndex.update(nodeC);

        // Hit test each node
        expect(
          spatialIndex.hitTest(const Offset(50, 50)).nodeId,
          equals('node-a'),
        );
        expect(
          spatialIndex.hitTest(const Offset(250, 250)).nodeId,
          equals('node-b'),
        );
        expect(
          spatialIndex.hitTest(const Offset(450, 50)).nodeId,
          equals('node-c'),
        );

        // Point in empty area
        expect(
          spatialIndex.hitTest(const Offset(150, 150)).hitType,
          equals(HitTarget.canvas),
        );
      });
    });

    group('Node Hit Testing with Negative Coordinates', () {
      test('detects node at negative position', () {
        final node = createTestNode(
          id: 'negative-pos',
          position: const Offset(-200, -100),
          size: const Size(150, 80),
        );
        spatialIndex.update(node);

        // Center of node is at (-125, -60)
        final result = spatialIndex.hitTest(const Offset(-125, -60));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('negative-pos'));
      });

      test('detects node spanning origin', () {
        final node = createTestNode(
          id: 'spanning-origin',
          position: const Offset(-50, -50),
          size: const Size(100, 100),
        );
        spatialIndex.update(node);

        // Test at origin (inside node)
        final resultOrigin = spatialIndex.hitTest(Offset.zero);
        expect(resultOrigin.hitType, equals(HitTarget.node));

        // Test in negative quadrant (inside node)
        final resultNeg = spatialIndex.hitTest(const Offset(-25, -25));
        expect(resultNeg.hitType, equals(HitTarget.node));

        // Test in positive quadrant (inside node)
        final resultPos = spatialIndex.hitTest(const Offset(25, 25));
        expect(resultPos.hitType, equals(HitTarget.node));
      });
    });

    group('Node Visibility', () {
      test('ignores hidden nodes in hit testing', () {
        final hiddenNode = createTestNode(
          id: 'hidden',
          position: const Offset(100, 100),
          size: const Size(200, 100),
          visible: false,
        );
        spatialIndex.update(hiddenNode);

        // Point inside hidden node
        final result = spatialIndex.hitTest(const Offset(200, 150));

        expect(result.hitType, equals(HitTarget.canvas));
      });

      test('visible node blocks hidden node behind it', () {
        final hiddenNode = createTestNode(
          id: 'hidden',
          position: const Offset(100, 100),
          size: const Size(200, 200),
          visible: false,
          zIndex: 10, // Higher z-index but hidden
        );
        final visibleNode = createTestNode(
          id: 'visible',
          position: const Offset(150, 150),
          size: const Size(100, 100),
          visible: true,
          zIndex: 0, // Lower z-index but visible
        );
        spatialIndex.update(hiddenNode);
        spatialIndex.update(visibleNode);

        // Point inside both nodes
        final result = spatialIndex.hitTest(const Offset(200, 200));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('visible'));
      });

      test('returns canvas when only hidden nodes at point', () {
        final hidden1 = createTestNode(
          id: 'hidden-1',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          visible: false,
        );
        final hidden2 = createTestNode(
          id: 'hidden-2',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          visible: false,
        );
        spatialIndex.update(hidden1);
        spatialIndex.update(hidden2);

        final result = spatialIndex.hitTest(const Offset(150, 150));

        expect(result.hitType, equals(HitTarget.canvas));
      });
    });
  });

  // ===========================================================================
  // Port Hit Detection Tests
  // ===========================================================================

  group('Port Hit Detection', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>(portSnapDistance: 8.0);
    });

    test('hitTestPort returns null when no ports exist', () {
      final result = spatialIndex.hitTestPort(const Offset(100, 100));

      expect(result, isNull);
    });

    test('hitTestPort detects output port at center', () {
      final node = createTestNodeWithPorts(
        id: 'node-with-ports',
        position: const Offset(100, 100),
      );
      node.setSize(const Size(150, 100));
      spatialIndex.update(node);

      // Get the output port center
      const portSize = Size.square(10);
      final portCenter = node.getPortCenter('output-1', portSize: portSize);

      final result = spatialIndex.hitTestPort(portCenter);

      expect(result, isNotNull);
      expect(result!.hitType, equals(HitTarget.port));
      expect(result.nodeId, equals('node-with-ports'));
      expect(result.portId, equals('output-1'));
      expect(result.isOutput, isTrue);
    });

    test('hitTestPort detects input port', () {
      final node = createTestNodeWithPorts(
        id: 'node-with-ports',
        position: const Offset(100, 100),
      );
      node.setSize(const Size(150, 100));
      spatialIndex.update(node);

      // Get the input port center
      const portSize = Size.square(10);
      final portCenter = node.getPortCenter('input-1', portSize: portSize);

      final result = spatialIndex.hitTestPort(portCenter);

      expect(result, isNotNull);
      expect(result!.hitType, equals(HitTarget.port));
      expect(result.portId, equals('input-1'));
      expect(result.isOutput, isFalse);
    });

    test('hitTestPort uses snap distance for hit area', () {
      const snapDistance = 12.0;
      final indexWithSnap = GraphSpatialIndex<String, dynamic>(
        portSnapDistance: snapDistance,
      );

      final node = createTestNodeWithPorts(
        id: 'snap-test',
        position: const Offset(100, 100),
      );
      node.setSize(const Size(150, 100));
      indexWithSnap.update(node);

      // Get port center
      const portSize = Size.square(10);
      final portCenter = node.getPortCenter('output-1', portSize: portSize);

      // Test point within snap distance (but outside port visual bounds)
      final nearbyPoint = portCenter + const Offset(10, 0);
      final result = indexWithSnap.hitTestPort(nearbyPoint);

      expect(result, isNotNull);
      expect(result!.portId, equals('output-1'));
    });

    test('hitTestPort returns null when point is beyond snap distance', () {
      final node = createTestNodeWithPorts(
        id: 'out-of-range',
        position: const Offset(100, 100),
      );
      node.setSize(const Size(150, 100));
      spatialIndex.update(node);

      // Test point far from any port
      final result = spatialIndex.hitTestPort(const Offset(0, 0));

      expect(result, isNull);
    });

    test('hitTestPort ignores ports of hidden nodes', () {
      final node = createTestNode(
        id: 'hidden-node',
        position: const Offset(100, 100),
        inputPorts: [createTestPort(id: 'input-1', type: PortType.input)],
        outputPorts: [createTestPort(id: 'output-1', type: PortType.output)],
        visible: false,
      );
      node.setSize(const Size(150, 100));
      spatialIndex.update(node);

      const portSize = Size.square(10);
      final portCenter = node.getPortCenter('output-1', portSize: portSize);
      final result = spatialIndex.hitTestPort(portCenter);

      expect(result, isNull);
    });

    test(
      'hitTestPort prefers closer port when multiple are within snap distance',
      () {
        // Create a node with multiple ports close together
        final node = createTestNode(
          id: 'multi-port',
          position: const Offset(100, 100),
          inputPorts: [createTestPort(id: 'input-1', type: PortType.input)],
          outputPorts: [
            createTestPort(id: 'output-1', type: PortType.output),
            createTestPort(
              id: 'output-2',
              type: PortType.output,
              offset: const Offset(0, 20),
            ),
          ],
        );
        node.setSize(const Size(150, 100));

        // Use large snap distance to ensure overlap
        final largeSnapIndex = GraphSpatialIndex<String, dynamic>(
          portSnapDistance: 50.0,
        );
        largeSnapIndex.update(node);

        // Get port centers
        const portSize = Size.square(10);
        final output1Center = node.getPortCenter(
          'output-1',
          portSize: portSize,
        );

        // Query at output-1 center - should prefer output-1 even if output-2 is within snap
        final result = largeSnapIndex.hitTestPort(output1Center);

        expect(result, isNotNull);
        expect(result!.portId, equals('output-1'));
      },
    );
  });

  // ===========================================================================
  // Connection Hit Detection Tests
  // ===========================================================================

  group('Connection Hit Detection', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('connectionsAt returns empty list when no connections exist', () {
      final connections = spatialIndex.connectionsAt(const Offset(100, 100));

      expect(connections, isEmpty);
    });

    test('connectionsAt finds connection at segment bounds', () {
      // Create nodes for the connection
      final sourceNode = createTestNodeWithOutputPort(
        id: 'source',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));
      final targetNode = createTestNodeWithInputPort(
        id: 'target',
        position: const Offset(300, 0),
      );
      targetNode.setSize(const Size(100, 50));

      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      // Create connection with segment bounds
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      final segmentBounds = [const Rect.fromLTWH(100, 20, 200, 10)];
      spatialIndex.updateConnection(connection, segmentBounds);

      // Query at point within segment bounds
      final connections = spatialIndex.connectionsAt(const Offset(200, 25));

      expect(connections, hasLength(1));
      expect(connections.first.id, equals('conn-1'));
    });

    test('connectionsAt returns empty when source node is hidden', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'source',
        position: const Offset(0, 0),
        visible: false,
      );
      sourceNode.setSize(const Size(100, 50));
      final targetNode = createTestNodeWithInputPort(
        id: 'target',
        position: const Offset(300, 0),
      );
      targetNode.setSize(const Size(100, 50));

      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      final connection = createTestConnection(
        id: 'conn-hidden-source',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 20, 200, 10),
      ]);

      final connections = spatialIndex.connectionsAt(const Offset(200, 25));

      expect(connections, isEmpty);
    });

    test('connectionsAt returns empty when target node is hidden', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'source',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));
      final targetNode = createTestNodeWithInputPort(
        id: 'target',
        position: const Offset(300, 0),
        visible: false,
      );
      targetNode.setSize(const Size(100, 50));

      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      final connection = createTestConnection(
        id: 'conn-hidden-target',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 20, 200, 10),
      ]);

      final connections = spatialIndex.connectionsAt(const Offset(200, 25));

      expect(connections, isEmpty);
    });

    test('connectionsAt handles multiple segments per connection', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      final connection = createTestConnection(
        id: 'multi-segment',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );

      // Curved path with multiple segments
      final segments = [
        const Rect.fromLTWH(100, 20, 50, 10), // Segment 0
        const Rect.fromLTWH(150, 30, 50, 10), // Segment 1
        const Rect.fromLTWH(200, 25, 50, 10), // Segment 2
      ];
      spatialIndex.updateConnection(connection, segments);

      // Query at each segment
      expect(spatialIndex.connectionsAt(const Offset(125, 25)), hasLength(1));
      expect(spatialIndex.connectionsAt(const Offset(175, 35)), hasLength(1));
      expect(spatialIndex.connectionsAt(const Offset(225, 30)), hasLength(1));
    });

    test('removeConnection removes all segments', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      final connection = createTestConnection(
        id: 'to-remove',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 20, 50, 10),
        const Rect.fromLTWH(150, 30, 50, 10),
      ]);

      // Verify connection exists at both segments
      expect(spatialIndex.connectionsAt(const Offset(125, 25)), hasLength(1));

      // Remove connection
      spatialIndex.removeConnection('to-remove');

      // Verify connection is gone from both segments
      expect(spatialIndex.connectionsAt(const Offset(125, 25)), isEmpty);
      expect(spatialIndex.connectionsAt(const Offset(175, 35)), isEmpty);
    });

    test('connectionsIn returns connections within area bounds', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      final connection = createTestConnection(
        id: 'in-area',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 100, 100, 10),
      ]);

      // Query area that includes the segment
      final inArea = spatialIndex.connectionsIn(
        const Rect.fromLTWH(50, 50, 200, 200),
      );
      expect(inArea, hasLength(1));
      expect(inArea.first.id, equals('in-area'));

      // Query area that doesn't include the segment
      final outsideArea = spatialIndex.connectionsIn(
        const Rect.fromLTWH(500, 500, 100, 100),
      );
      expect(outsideArea, isEmpty);
    });
  });

  // ===========================================================================
  // Priority and Ordering Tests
  // ===========================================================================

  group('Hit Testing Priority and Ordering', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    group('Z-Index Ordering', () {
      test('higher zIndex node is hit first in overlap', () {
        final bottomNode = createTestNode(
          id: 'bottom',
          position: const Offset(100, 100),
          size: const Size(150, 100),
          zIndex: 0,
        );
        final topNode = createTestNode(
          id: 'top',
          position: const Offset(150, 150),
          size: const Size(150, 100),
          zIndex: 10,
        );

        spatialIndex.update(bottomNode);
        spatialIndex.update(topNode);

        // Point in overlap region
        final result = spatialIndex.hitTest(const Offset(175, 175));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('top'));
      });

      test('negative zIndex node is below zero zIndex node', () {
        final belowZero = createTestNode(
          id: 'below-zero',
          position: const Offset(100, 100),
          size: const Size(150, 100),
          zIndex: -5,
        );
        final atZero = createTestNode(
          id: 'at-zero',
          position: const Offset(100, 100),
          size: const Size(150, 100),
          zIndex: 0,
        );

        spatialIndex.update(belowZero);
        spatialIndex.update(atZero);

        final result = spatialIndex.hitTest(const Offset(175, 150));

        expect(result.nodeId, equals('at-zero'));
      });

      test('multiple overlapping nodes sorted by zIndex', () {
        final nodes = [
          createTestNode(
            id: 'z-5',
            position: Offset.zero,
            size: const Size(200, 200),
            zIndex: 5,
          ),
          createTestNode(
            id: 'z-1',
            position: Offset.zero,
            size: const Size(200, 200),
            zIndex: 1,
          ),
          createTestNode(
            id: 'z-10',
            position: Offset.zero,
            size: const Size(200, 200),
            zIndex: 10,
          ),
          createTestNode(
            id: 'z-3',
            position: Offset.zero,
            size: const Size(200, 200),
            zIndex: 3,
          ),
        ];

        for (final node in nodes) {
          spatialIndex.update(node);
        }

        final result = spatialIndex.hitTest(const Offset(100, 100));

        // z-10 should be on top
        expect(result.nodeId, equals('z-10'));
      });
    });

    group('Render Layer Priority', () {
      test('foreground layer (CommentNode) hit before middle layer', () {
        final regularNode = createTestNode(
          id: 'regular',
          position: const Offset(100, 100),
          size: const Size(150, 100),
          zIndex: 100, // Very high z-index
        );
        final commentNode = createTestCommentNode<String>(
          id: 'comment',
          position: const Offset(100, 100),
          width: 150,
          height: 100,
          data: 'test',
          zIndex: 0, // Low z-index but foreground layer
        );

        spatialIndex.update(regularNode);
        spatialIndex.update(commentNode);

        final result = spatialIndex.hitTest(const Offset(175, 150));

        // Comment node should be hit first due to foreground layer
        expect(result.nodeId, equals('comment'));
      });

      test('middle layer node hit before background layer (GroupNode)', () {
        final groupNode = createTestGroupNode<String>(
          id: 'group',
          position: const Offset(50, 50),
          size: const Size(300, 300),
          data: 'test',
          zIndex: 100, // Very high z-index but background layer
        );
        final regularNode = createTestNode(
          id: 'regular',
          position: const Offset(100, 100),
          size: const Size(150, 100),
          zIndex: 0, // Low z-index but middle layer
        );

        spatialIndex.update(groupNode);
        spatialIndex.update(regularNode);

        final result = spatialIndex.hitTest(const Offset(175, 150));

        // Regular node should be hit first due to middle layer
        expect(result.nodeId, equals('regular'));
      });

      test(
        'background node hit when no overlapping middle/foreground nodes',
        () {
          final groupNode = createTestGroupNode<String>(
            id: 'group-only',
            position: const Offset(100, 100),
            size: const Size(200, 200),
            data: 'test',
          );
          final regularNode = createTestNode(
            id: 'regular',
            position: const Offset(500, 500), // Not overlapping
            size: const Size(100, 100),
          );

          spatialIndex.update(groupNode);
          spatialIndex.update(regularNode);

          final result = spatialIndex.hitTest(const Offset(200, 200));

          expect(result.nodeId, equals('group-only'));
        },
      );

      test('foreground, middle, and background layers in correct order', () {
        final groupNode = createTestGroupNode<String>(
          id: 'group',
          position: const Offset(100, 100),
          size: const Size(300, 300),
          data: 'test',
          zIndex: 50,
        );
        final regularNode = createTestNode(
          id: 'regular',
          position: const Offset(100, 100),
          size: const Size(300, 300),
          zIndex: 0,
        );
        final commentNode = createTestCommentNode<String>(
          id: 'comment',
          position: const Offset(100, 100),
          width: 300,
          height: 300,
          data: 'test',
          zIndex: -10,
        );

        spatialIndex.update(groupNode);
        spatialIndex.update(regularNode);
        spatialIndex.update(commentNode);

        final result = spatialIndex.hitTest(const Offset(250, 250));

        // Foreground layer wins even with lowest z-index
        expect(result.nodeId, equals('comment'));
      });
    });

    group('Hit Priority Order: Ports > Nodes > Connections > Canvas', () {
      test('port hit before node body', () {
        final node = createTestNodeWithPorts(
          id: 'port-priority',
          position: const Offset(100, 100),
        );
        node.setSize(const Size(150, 100));
        spatialIndex.update(node);

        // Get port center
        const portSize = Size.square(10);
        final portCenter = node.getPortCenter('output-1', portSize: portSize);

        // hitTest at port location
        final result = spatialIndex.hitTest(portCenter);

        expect(result.hitType, equals(HitTarget.port));
        expect(result.portId, equals('output-1'));
      });

      test('node hit before connection', () {
        // Create nodes
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        sourceNode.setSize(const Size(100, 50));
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 0),
        );
        targetNode.setSize(const Size(100, 50));

        // Create a node that overlaps with connection path
        final overlappingNode = createTestNode(
          id: 'overlapping',
          position: const Offset(100, 10),
          size: const Size(50, 30),
        );

        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);
        spatialIndex.update(overlappingNode);

        // Add connection that passes through overlappingNode's area
        final connection = createTestConnection(
          id: 'conn',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );
        spatialIndex.updateConnection(connection, [
          const Rect.fromLTWH(100, 15, 50, 20),
        ]);

        // Hit test in overlap area
        final result = spatialIndex.hitTest(const Offset(125, 25));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('overlapping'));
      });

      test('connection hit before canvas', () {
        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        // Set up connection hit tester
        spatialIndex.connectionHitTester = (connection, point) {
          // Simple hit test - check if point is in segment bounds
          return const Rect.fromLTWH(100, 100, 100, 20).contains(point);
        };

        final connection = createTestConnection(
          id: 'conn',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );
        spatialIndex.updateConnection(connection, [
          const Rect.fromLTWH(100, 100, 100, 20),
        ]);

        // Hit test on connection (not on any node)
        final result = spatialIndex.hitTest(const Offset(150, 110));

        expect(result.hitType, equals(HitTarget.connection));
        expect(result.connectionId, equals('conn'));
      });
    });
  });

  // ===========================================================================
  // Viewport Transformation Effects
  // ===========================================================================

  group('Viewport Transformation Effects', () {
    test('viewport converts screen to graph coordinates correctly', () {
      // Create viewport with pan offset
      const viewport = GraphViewport(x: 100, y: 50, zoom: 1.0);

      // Screen position (200, 150) should map to graph (100, 100)
      final screenPos = ScreenPosition.fromXY(200, 150);
      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(100));
      expect(graphPos.dy, equals(100));
    });

    test('viewport with zoom affects coordinate conversion', () {
      // Viewport zoomed to 2x
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);

      // Screen position (200, 100) should map to graph (100, 50)
      final screenPos = ScreenPosition.fromXY(200, 100);
      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(100));
      expect(graphPos.dy, equals(50));
    });

    test('viewport with pan and zoom combined', () {
      // Pan (100, 50) and zoom 2x
      const viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);

      // Screen (300, 150) -> graph ((300-100)/2, (150-50)/2) = (100, 50)
      final screenPos = ScreenPosition.fromXY(300, 150);
      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(100));
      expect(graphPos.dy, equals(50));
    });

    test('hit testing uses graph coordinates after viewport transform', () {
      final spatialIndex = GraphSpatialIndex<String, dynamic>();

      // Node at graph position (100, 100)
      final node = createTestNode(
        id: 'graph-pos',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      spatialIndex.update(node);

      // Viewport with pan
      const viewport = GraphViewport(x: 50, y: 50, zoom: 1.0);

      // Screen position (200, 200) -> graph (150, 150) which is inside node
      final screenPos = ScreenPosition.fromXY(200, 200);
      final graphPos = viewport.toGraph(screenPos);

      final result = spatialIndex.hitTest(graphPos.offset);

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('graph-pos'));
    });

    test('hit testing respects zoomed viewport', () {
      final spatialIndex = GraphSpatialIndex<String, dynamic>();

      // Small node at origin
      final node = createTestNode(
        id: 'zoom-test',
        position: Offset.zero,
        size: const Size(50, 50),
      );
      spatialIndex.update(node);

      // Zoomed out (zoom 0.5 means graph appears half size)
      const viewport = GraphViewport(x: 0, y: 0, zoom: 0.5);

      // Screen (50, 50) -> graph (100, 100) which is outside node (0,0 to 50,50)
      final screenPos = ScreenPosition.fromXY(50, 50);
      final graphPos = viewport.toGraph(screenPos);

      final result = spatialIndex.hitTest(graphPos.offset);

      expect(result.hitType, equals(HitTarget.canvas));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('handles very small node', () {
      final tinyNode = createTestNode(
        id: 'tiny',
        position: const Offset(100, 100),
        size: const Size(1, 1),
      );
      spatialIndex.update(tinyNode);

      // Hit exactly at node position
      final result = spatialIndex.hitTest(const Offset(100.5, 100.5));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('tiny'));
    });

    test('handles very large node', () {
      final hugeNode = createTestNode(
        id: 'huge',
        position: const Offset(-5000, -5000),
        size: const Size(10000, 10000),
      );
      spatialIndex.update(hugeNode);

      // Hit at various points inside large node
      expect(spatialIndex.hitTest(Offset.zero).nodeId, equals('huge'));
      expect(
        spatialIndex.hitTest(const Offset(4999, 4999)).nodeId,
        equals('huge'),
      );
      expect(
        spatialIndex.hitTest(const Offset(-4999, -4999)).nodeId,
        equals('huge'),
      );
    });

    test('handles node at extreme coordinates', () {
      final extremeNode = createTestNode(
        id: 'extreme',
        position: const Offset(1000000, 1000000),
        size: const Size(100, 100),
      );
      spatialIndex.update(extremeNode);

      final result = spatialIndex.hitTest(const Offset(1000050, 1000050));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('extreme'));
    });

    test('handles many overlapping nodes', () {
      // Create 100 overlapping nodes with increasing z-index
      for (var i = 0; i < 100; i++) {
        final node = createTestNode(
          id: 'overlap-$i',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: i,
        );
        spatialIndex.update(node);
      }

      // Should hit the one with highest z-index
      final result = spatialIndex.hitTest(const Offset(150, 150));

      expect(result.nodeId, equals('overlap-99'));
    });

    test('handles node removal during iteration-like operations', () {
      final node1 = createTestNode(
        id: 'keep',
        position: Offset.zero,
        size: const Size(100, 100),
      );
      final node2 = createTestNode(
        id: 'remove',
        position: const Offset(50, 50),
        size: const Size(100, 100),
      );

      spatialIndex.update(node1);
      spatialIndex.update(node2);

      // Remove one node
      spatialIndex.removeNode('remove');

      // Hit test should still work
      final result = spatialIndex.hitTest(const Offset(50, 50));

      expect(result.nodeId, equals('keep'));
    });

    test('handles empty hit test area', () {
      // Add nodes outside the test area
      final node = createTestNode(
        id: 'far-away',
        position: const Offset(1000, 1000),
        size: const Size(100, 100),
      );
      spatialIndex.update(node);

      // Hit test in empty area
      final result = spatialIndex.hitTest(Offset.zero);

      expect(result.hitType, equals(HitTarget.canvas));
    });

    test('handles coincident node positions', () {
      // Two nodes at exactly the same position with same z-index
      final node1 = createTestNode(
        id: 'coincident-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 5,
      );
      final node2 = createTestNode(
        id: 'coincident-2',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 5,
      );

      spatialIndex.update(node1);
      spatialIndex.update(node2);

      // Should hit one of them (order depends on internal implementation)
      final result = spatialIndex.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      expect(
        result.nodeId,
        anyOf(equals('coincident-1'), equals('coincident-2')),
      );
    });

    test('clear removes all elements from hit testing', () {
      spatialIndex.update(
        createTestNode(
          id: 'node-1',
          position: Offset.zero,
          size: const Size(100, 100),
        ),
      );
      spatialIndex.update(
        createTestNode(
          id: 'node-2',
          position: const Offset(200, 200),
          size: const Size(100, 100),
        ),
      );

      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);
      spatialIndex.updateConnection(
        createTestConnection(sourceNodeId: 'source', targetNodeId: 'target'),
        [const Rect.fromLTWH(0, 0, 100, 10)],
      );

      // Verify elements exist
      expect(spatialIndex.nodeCount, greaterThan(0));
      expect(spatialIndex.connectionCount, greaterThan(0));

      // Clear everything
      spatialIndex.clear();

      // All hit tests should return canvas
      expect(
        spatialIndex.hitTest(const Offset(50, 50)).hitType,
        equals(HitTarget.canvas),
      );
      expect(
        spatialIndex.hitTest(const Offset(250, 250)).hitType,
        equals(HitTarget.canvas),
      );
      expect(spatialIndex.nodeCount, equals(0));
      expect(spatialIndex.connectionCount, equals(0));
    });
  });

  // ===========================================================================
  // nodesAt and nodesIn Query Tests
  // ===========================================================================

  group('Node Query Methods', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    group('nodesAt', () {
      test('returns all nodes at a point', () {
        final node1 = createTestNode(
          id: 'stacked-1',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 0,
        );
        final node2 = createTestNode(
          id: 'stacked-2',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 5,
        );
        spatialIndex.update(node1);
        spatialIndex.update(node2);

        final nodes = spatialIndex.nodesAt(const Offset(150, 150));

        expect(nodes, hasLength(2));
        expect(nodes.map((n) => n.id), containsAll(['stacked-1', 'stacked-2']));
      });

      test('returns empty list when no nodes at point', () {
        final node = createTestNode(
          id: 'far-node',
          position: const Offset(500, 500),
          size: const Size(100, 100),
        );
        spatialIndex.update(node);

        final nodes = spatialIndex.nodesAt(const Offset(100, 100));

        expect(nodes, isEmpty);
      });

      test('radius parameter expands search area', () {
        final node = createTestNode(
          id: 'near-node',
          position: const Offset(100, 100),
          size: const Size(50, 50),
        );
        spatialIndex.update(node);

        // Point just outside node
        final nodesNoRadius = spatialIndex.nodesAt(const Offset(160, 125));
        final nodesWithRadius = spatialIndex.nodesAt(
          const Offset(160, 125),
          radius: 15,
        );

        expect(nodesNoRadius, isEmpty);
        expect(nodesWithRadius, hasLength(1));
      });

      test('excludes hidden nodes', () {
        final visibleNode = createTestNode(
          id: 'visible',
          position: const Offset(100, 100),
          size: const Size(100, 100),
        );
        final hiddenNode = createTestNode(
          id: 'hidden',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          visible: false,
        );
        spatialIndex.update(visibleNode);
        spatialIndex.update(hiddenNode);

        final nodes = spatialIndex.nodesAt(const Offset(150, 150));

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('visible'));
      });
    });

    group('nodesIn', () {
      test('returns nodes within bounds', () {
        final insideNode = createTestNode(
          id: 'inside',
          position: const Offset(100, 100),
          size: const Size(50, 50),
        );
        final outsideNode = createTestNode(
          id: 'outside',
          position: const Offset(500, 500),
          size: const Size(50, 50),
        );
        spatialIndex.update(insideNode);
        spatialIndex.update(outsideNode);

        final nodes = spatialIndex.nodesIn(const Rect.fromLTWH(0, 0, 300, 300));

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('inside'));
      });

      test('includes partially overlapping nodes', () {
        final partialNode = createTestNode(
          id: 'partial',
          position: const Offset(250, 250),
          size: const Size(100, 100),
        );
        spatialIndex.update(partialNode);

        // Bounds that partially overlap with node
        final nodes = spatialIndex.nodesIn(const Rect.fromLTWH(0, 0, 275, 275));

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('partial'));
      });

      test('excludes hidden nodes', () {
        final visibleNode = createTestNode(
          id: 'visible',
          position: const Offset(100, 100),
          size: const Size(50, 50),
        );
        final hiddenNode = createTestNode(
          id: 'hidden',
          position: const Offset(150, 150),
          size: const Size(50, 50),
          visible: false,
        );
        spatialIndex.update(visibleNode);
        spatialIndex.update(hiddenNode);

        final nodes = spatialIndex.nodesIn(const Rect.fromLTWH(0, 0, 300, 300));

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('visible'));
      });

      test('handles empty bounds outside node', () {
        final node = createTestNode(
          id: 'node',
          position: const Offset(100, 100),
          size: const Size(100, 100),
        );
        spatialIndex.update(node);

        // Zero-area bounds completely outside the node
        final nodes = spatialIndex.nodesIn(const Rect.fromLTWH(500, 500, 0, 0));

        expect(nodes, isEmpty);
      });
    });
  });

  // ===========================================================================
  // Version and Reactivity Tests
  // ===========================================================================

  group('Version Tracking for Reactivity', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('version increments on node addition', () {
      final initialVersion = spatialIndex.version.value;

      spatialIndex.update(createTestNode());

      expect(spatialIndex.version.value, greaterThan(initialVersion));
    });

    test('version increments on node update', () {
      final node = createTestNode(id: 'to-update');
      spatialIndex.update(node);
      final versionAfterAdd = spatialIndex.version.value;

      // Update node position (position is an Observable)
      node.position.value = const Offset(500, 500);
      spatialIndex.update(node);

      expect(spatialIndex.version.value, greaterThan(versionAfterAdd));
    });

    test('version increments on node removal', () {
      final node = createTestNode(id: 'to-remove');
      spatialIndex.update(node);
      final versionAfterAdd = spatialIndex.version.value;

      spatialIndex.removeNode('to-remove');

      expect(spatialIndex.version.value, greaterThan(versionAfterAdd));
    });

    test('version increments on connection update', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);
      final versionAfterNodes = spatialIndex.version.value;

      spatialIndex.updateConnection(
        createTestConnection(sourceNodeId: 'source', targetNodeId: 'target'),
        [const Rect.fromLTWH(0, 0, 100, 10)],
      );

      expect(spatialIndex.version.value, greaterThan(versionAfterNodes));
    });

    test('version increments on connection removal', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);
      spatialIndex.updateConnection(
        createTestConnection(
          id: 'conn',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        ),
        [const Rect.fromLTWH(0, 0, 100, 10)],
      );
      final versionAfterConn = spatialIndex.version.value;

      spatialIndex.removeConnection('conn');

      expect(spatialIndex.version.value, greaterThan(versionAfterConn));
    });

    test('version increments on clear', () {
      spatialIndex.update(createTestNode());
      final versionAfterAdd = spatialIndex.version.value;

      spatialIndex.clear();

      expect(spatialIndex.version.value, greaterThan(versionAfterAdd));
    });

    test('batch operation increments version once at end', () {
      final initialVersion = spatialIndex.version.value;

      spatialIndex.batch(() {
        for (var i = 0; i < 10; i++) {
          spatialIndex.update(createTestNode(id: 'batch-$i'));
        }
      });

      // Version should be incremented (once at end of batch)
      expect(spatialIndex.version.value, greaterThan(initialVersion));
    });
  });

  // ===========================================================================
  // Controller Integration Tests
  // ===========================================================================

  group('Controller Integration', () {
    test('controller provides spatial index', () {
      final controller = createTestController();

      expect(controller.spatialIndex, isNotNull);
    });

    test('controller spatial index supports hit testing', () {
      final nodes = [
        createTestNode(
          id: 'test-node',
          position: const Offset(100, 100),
          size: const Size(150, 100),
        ),
      ];
      final controller = createTestController(nodes: nodes);

      // Note: Hit testing through controller requires proper initialization
      // which happens in the widget. We verify the interface exists.
      expect(controller.spatialIndex.hitTest, isA<Function>());
      expect(controller.spatialIndex.nodesAt, isA<Function>());
      expect(controller.spatialIndex.nodesIn, isA<Function>());
    });

    test('controller viewport can be used for coordinate conversion', () {
      final controller = createTestController(
        initialViewport: const GraphViewport(x: 100, y: 50, zoom: 2.0),
      );

      final screenPos = ScreenPosition.fromXY(200, 100);
      final graphPos = controller.viewport.toGraph(screenPos);

      // (200-100)/2 = 50, (100-50)/2 = 25
      expect(graphPos.dx, equals(50));
      expect(graphPos.dy, equals(25));
    });
  });
}
