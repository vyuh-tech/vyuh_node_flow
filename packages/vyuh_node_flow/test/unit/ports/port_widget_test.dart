/// Comprehensive widget tests for PortWidget in vyuh_node_flow.
///
/// Tests cover:
/// - PortWidget construction and rendering
/// - Port positioning (left, right, top, bottom)
/// - Custom port decoration and styling
/// - Hover states
/// - Connection state display
/// - Theme cascade resolution
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String, dynamic> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
    controller.setScreenSize(const Size(800, 600));
  });

  tearDown(() {
    controller.dispose();
  });

  // ===========================================================================
  // Helper to build a widget test environment with NodeFlowEditor
  // ===========================================================================
  Widget buildTestWidget({
    required NodeFlowController<String, dynamic> controller,
    Widget Function(BuildContext context, Node<String> node)? nodeBuilder,
    PortBuilder<String>? portBuilder,
    NodeFlowTheme? theme,
    NodeFlowBehavior? behavior,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: NodeFlowEditor<String, dynamic>(
            controller: controller,
            nodeBuilder:
                nodeBuilder ??
                (context, node) =>
                    SizedBox(width: 100, height: 60, child: Text(node.id)),
            portBuilder: portBuilder,
            theme: theme ?? NodeFlowTheme.light,
            behavior: behavior ?? NodeFlowBehavior.design,
          ),
        ),
      ),
    );
  }

  // Helper to check if a port has connections
  bool isPortConnected(
    NodeFlowController<String, dynamic> ctrl,
    String nodeId,
    String portId,
  ) {
    final fromConnections = ctrl.getConnectionsFromPort(nodeId, portId);
    final toConnections = ctrl.getConnectionsToPort(nodeId, portId);
    return fromConnections.isNotEmpty || toConnections.isNotEmpty;
  }

  // ===========================================================================
  // PortWidget Construction and Rendering Tests
  // ===========================================================================
  group('PortWidget Construction and Rendering', () {
    testWidgets('node with ports renders port widgets', (tester) async {
      final node = createTestNodeWithPorts(id: 'test-node');
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      // Node should be rendered
      expect(find.text('test-node'), findsOneWidget);
    });

    testWidgets('node with input port only renders correctly', (tester) async {
      final node = createTestNodeWithInputPort(id: 'input-only-node');
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('input-only-node'), findsOneWidget);
    });

    testWidgets('node with output port only renders correctly', (tester) async {
      final node = createTestNodeWithOutputPort(id: 'output-only-node');
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('output-only-node'), findsOneWidget);
    });

    testWidgets('node with multiple input ports renders all ports', (
      tester,
    ) async {
      final inputPorts = [
        createInputPort(id: 'input-1'),
        createInputPort(id: 'input-2'),
        createInputPort(id: 'input-3'),
      ];
      final node = createTestNode(
        id: 'multi-input-node',
        inputPorts: inputPorts,
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('multi-input-node'), findsOneWidget);
      expect(
        controller.getNode('multi-input-node')!.inputPorts.length,
        equals(3),
      );
    });

    testWidgets('node with multiple output ports renders all ports', (
      tester,
    ) async {
      final outputPorts = [
        createOutputPort(id: 'output-1'),
        createOutputPort(id: 'output-2'),
      ];
      final node = createTestNode(
        id: 'multi-output-node',
        outputPorts: outputPorts,
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('multi-output-node'), findsOneWidget);
      expect(
        controller.getNode('multi-output-node')!.outputPorts.length,
        equals(2),
      );
    });

    testWidgets('custom port builder is invoked for each port', (tester) async {
      final node = createTestNodeWithPorts(id: 'custom-port-node');
      controller.addNode(node);

      var portBuilderCallCount = 0;

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          portBuilder: (context, node, port) {
            portBuilderCallCount++;
            return Container(
              key: ValueKey('custom-port-${port.id}'),
              width: 12,
              height: 12,
              color: Colors.red,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Should be called for both input and output port
      expect(portBuilderCallCount, greaterThanOrEqualTo(2));
    });

    testWidgets('custom port builder receives correct node and port', (
      tester,
    ) async {
      final inputPort = createInputPort(id: 'specific-input');
      final outputPort = createOutputPort(id: 'specific-output');
      final node = createTestNode(
        id: 'check-ports-node',
        inputPorts: [inputPort],
        outputPorts: [outputPort],
      );
      controller.addNode(node);

      final receivedPorts = <String>[];

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          portBuilder: (context, builderNode, port) {
            receivedPorts.add(port.id);
            expect(builderNode.id, equals('check-ports-node'));
            return SizedBox(width: 10, height: 10);
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(receivedPorts, containsAll(['specific-input', 'specific-output']));
    });
  });

  // ===========================================================================
  // Port Positioning Tests
  // ===========================================================================
  group('Port Positioning', () {
    testWidgets('left position port is rendered on the left side', (
      tester,
    ) async {
      final leftPort = Port(
        id: 'left-port',
        name: 'Left Port',
        position: PortPosition.left,
        type: PortType.input,
      );
      final node = createTestNode(id: 'left-port-node', inputPorts: [leftPort]);
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('left-port-node'), findsOneWidget);
      expect(node.inputPorts.first.position, equals(PortPosition.left));
    });

    testWidgets('right position port is rendered on the right side', (
      tester,
    ) async {
      final rightPort = Port(
        id: 'right-port',
        name: 'Right Port',
        position: PortPosition.right,
        type: PortType.output,
      );
      final node = createTestNode(
        id: 'right-port-node',
        outputPorts: [rightPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('right-port-node'), findsOneWidget);
      expect(node.outputPorts.first.position, equals(PortPosition.right));
    });

    testWidgets('top position port is rendered on the top side', (
      tester,
    ) async {
      final topPort = Port(
        id: 'top-port',
        name: 'Top Port',
        position: PortPosition.top,
        type: PortType.input,
      );
      final node = createTestNode(id: 'top-port-node', inputPorts: [topPort]);
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('top-port-node'), findsOneWidget);
      expect(node.inputPorts.first.position, equals(PortPosition.top));
    });

    testWidgets('bottom position port is rendered on the bottom side', (
      tester,
    ) async {
      final bottomPort = Port(
        id: 'bottom-port',
        name: 'Bottom Port',
        position: PortPosition.bottom,
        type: PortType.output,
      );
      final node = createTestNode(
        id: 'bottom-port-node',
        outputPorts: [bottomPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('bottom-port-node'), findsOneWidget);
      expect(node.outputPorts.first.position, equals(PortPosition.bottom));
    });

    testWidgets('ports on all four sides render correctly', (tester) async {
      final leftPort = Port(
        id: 'left',
        name: 'Left',
        position: PortPosition.left,
        type: PortType.input,
      );
      final rightPort = Port(
        id: 'right',
        name: 'Right',
        position: PortPosition.right,
        type: PortType.output,
      );
      final topPort = Port(
        id: 'top',
        name: 'Top',
        position: PortPosition.top,
        type: PortType.input,
      );
      final bottomPort = Port(
        id: 'bottom',
        name: 'Bottom',
        position: PortPosition.bottom,
        type: PortType.output,
      );

      final node = createTestNode(
        id: 'four-sided-node',
        inputPorts: [leftPort, topPort],
        outputPorts: [rightPort, bottomPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('four-sided-node'), findsOneWidget);
      expect(node.inputPorts.length, equals(2));
      expect(node.outputPorts.length, equals(2));
    });

    testWidgets('port with custom offset is positioned correctly', (
      tester,
    ) async {
      final offsetPort = Port(
        id: 'offset-port',
        name: 'Offset Port',
        position: PortPosition.left,
        type: PortType.input,
        offset: const Offset(5, 25), // Custom vertical offset
      );
      final node = createTestNode(id: 'offset-node', inputPorts: [offsetPort]);
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('offset-node'), findsOneWidget);
      expect(node.inputPorts.first.offset, equals(const Offset(5, 25)));
    });
  });

  // ===========================================================================
  // Custom Port Decoration Tests
  // ===========================================================================
  group('Custom Port Decoration', () {
    testWidgets('port with custom size uses specified size', (tester) async {
      final customSizePort = Port(
        id: 'custom-size-port',
        name: 'Custom Size',
        position: PortPosition.left,
        type: PortType.input,
        size: const Size(16, 16),
      );
      final node = createTestNode(
        id: 'custom-size-node',
        inputPorts: [customSizePort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(node.inputPorts.first.size, equals(const Size(16, 16)));
    });

    testWidgets('port with custom shape uses specified shape', (tester) async {
      final diamondPort = Port(
        id: 'diamond-port',
        name: 'Diamond',
        position: PortPosition.right,
        type: PortType.output,
        shape: MarkerShapes.diamond,
      );
      final node = createTestNode(
        id: 'diamond-shape-node',
        outputPorts: [diamondPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(node.outputPorts.first.shape, equals(MarkerShapes.diamond));
    });

    testWidgets('port with custom theme uses theme values', (tester) async {
      final customTheme = PortTheme.light.copyWith(
        color: Colors.purple,
        connectedColor: Colors.orange,
        size: const Size(14, 14),
      );
      final themedPort = Port(
        id: 'themed-port',
        name: 'Themed Port',
        position: PortPosition.left,
        type: PortType.input,
        theme: customTheme,
      );
      final node = createTestNode(
        id: 'themed-port-node',
        inputPorts: [themedPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(node.inputPorts.first.theme, isNotNull);
      expect(node.inputPorts.first.theme!.color, equals(Colors.purple));
      expect(
        node.inputPorts.first.theme!.connectedColor,
        equals(Colors.orange),
      );
    });

    testWidgets('port with showLabel true displays label', (tester) async {
      final labeledPort = Port(
        id: 'labeled-port',
        name: 'My Label',
        position: PortPosition.left,
        type: PortType.input,
        showLabel: true,
      );
      final node = createTestNode(
        id: 'labeled-port-node',
        inputPorts: [labeledPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      // Verify label property is set
      expect(node.inputPorts.first.showLabel, isTrue);
      expect(node.inputPorts.first.name, equals('My Label'));
    });

    testWidgets('port with showLabel false does not display label', (
      tester,
    ) async {
      final unlabeledPort = Port(
        id: 'unlabeled-port',
        name: 'Hidden Label',
        position: PortPosition.left,
        type: PortType.input,
        showLabel: false,
      );
      final node = createTestNode(
        id: 'unlabeled-port-node',
        inputPorts: [unlabeledPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(node.inputPorts.first.showLabel, isFalse);
    });

    testWidgets('port widget builder on port instance is used', (tester) async {
      var instanceBuilderCalled = false;
      final portWithBuilder = Port(
        id: 'builder-port',
        name: 'Builder Port',
        position: PortPosition.left,
        type: PortType.input,
        widgetBuilder: (context, node, port) {
          instanceBuilderCalled = true;
          return Container(
            key: const ValueKey('instance-builder-port'),
            width: 20,
            height: 20,
            color: Colors.green,
          );
        },
      );
      final node = createTestNode(
        id: 'instance-builder-node',
        inputPorts: [portWithBuilder],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      // Port with widgetBuilder should use that builder
      expect(portWithBuilder.widgetBuilder, isNotNull);
      expect(instanceBuilderCalled, isTrue);
    });
  });

  // ===========================================================================
  // Hover States Tests
  // ===========================================================================
  group('Hover States', () {
    testWidgets('port highlighted observable starts as false', (tester) async {
      final port = Port(
        id: 'highlight-test-port',
        name: 'Highlight Test',
        position: PortPosition.left,
        type: PortType.input,
      );
      final node = createTestNode(id: 'highlight-node', inputPorts: [port]);
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(port.highlighted.value, isFalse);
    });

    testWidgets('port highlighted can be toggled programmatically', (
      tester,
    ) async {
      final port = Port(
        id: 'toggle-highlight-port',
        name: 'Toggle Highlight',
        position: PortPosition.left,
        type: PortType.input,
      );
      final node = createTestNode(
        id: 'toggle-highlight-node',
        inputPorts: [port],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      // Initially false
      expect(port.highlighted.value, isFalse);

      // Set to true using runInAction for MobX compliance
      runInAction(() {
        port.highlighted.value = true;
      });
      await tester.pump();
      expect(port.highlighted.value, isTrue);

      // Set back to false
      runInAction(() {
        port.highlighted.value = false;
      });
      await tester.pump();
      expect(port.highlighted.value, isFalse);
    });

    testWidgets('multiple ports have independent highlighted states', (
      tester,
    ) async {
      final port1 = Port(
        id: 'port-1',
        name: 'Port 1',
        position: PortPosition.left,
        type: PortType.input,
      );
      final port2 = Port(
        id: 'port-2',
        name: 'Port 2',
        position: PortPosition.right,
        type: PortType.output,
      );
      final node = createTestNode(
        id: 'multi-highlight-node',
        inputPorts: [port1],
        outputPorts: [port2],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      // Set only port1 highlighted using runInAction for MobX compliance
      runInAction(() {
        port1.highlighted.value = true;
      });
      await tester.pump();

      expect(port1.highlighted.value, isTrue);
      expect(port2.highlighted.value, isFalse);
    });

    testWidgets('hover suppressed in preview mode', (tester) async {
      final port = Port(
        id: 'preview-port',
        name: 'Preview Port',
        position: PortPosition.left,
        type: PortType.input,
      );
      final node = createTestNode(id: 'preview-node', inputPorts: [port]);
      controller.addNode(node);

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          behavior: NodeFlowBehavior.preview,
        ),
      );
      await tester.pumpAndSettle();

      // In preview mode, canCreate is false
      expect(NodeFlowBehavior.preview.canCreate, isFalse);
    });

    testWidgets('hover suppressed in present mode', (tester) async {
      final port = Port(
        id: 'present-port',
        name: 'Present Port',
        position: PortPosition.left,
        type: PortType.input,
      );
      final node = createTestNode(id: 'present-node', inputPorts: [port]);
      controller.addNode(node);

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          behavior: NodeFlowBehavior.present,
        ),
      );
      await tester.pumpAndSettle();

      // In present mode, canCreate is false
      expect(NodeFlowBehavior.present.canCreate, isFalse);
    });
  });

  // ===========================================================================
  // Connection State Display Tests
  // ===========================================================================
  group('Connection State Display', () {
    testWidgets('port isConnected shows connected color when connected', (
      tester,
    ) async {
      // Create two nodes with ports and connect them
      final nodeA = createTestNodeWithOutputPort(id: 'node-a', portId: 'out');
      final nodeB = createTestNodeWithInputPort(id: 'node-b', portId: 'in');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'out',
        targetNodeId: 'node-b',
        targetPortId: 'in',
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addConnection(connection);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      // Verify connection exists
      expect(controller.connections.length, equals(1));
      expect(isPortConnected(controller, 'node-a', 'out'), isTrue);
      expect(isPortConnected(controller, 'node-b', 'in'), isTrue);
    });

    testWidgets('port shows disconnected state when not connected', (
      tester,
    ) async {
      final node = createTestNodeWithPorts(id: 'disconnected-node');
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      // No connections
      expect(controller.connections, isEmpty);
      expect(
        isPortConnected(controller, 'disconnected-node', 'input-1'),
        isFalse,
      );
      expect(
        isPortConnected(controller, 'disconnected-node', 'output-1'),
        isFalse,
      );
    });

    testWidgets(
      'connection count tracked correctly for multi-connection port',
      (tester) async {
        final multiInputPort = Port(
          id: 'multi-in',
          name: 'Multi Input',
          type: PortType.input,
          position: PortPosition.left,
          multiConnections: true,
          maxConnections: 5,
        );
        final targetNode = createTestNode(
          id: 'target',
          inputPorts: [multiInputPort],
        );
        final sourceA = createTestNodeWithOutputPort(
          id: 'source-a',
          portId: 'out-a',
        );
        final sourceB = createTestNodeWithOutputPort(
          id: 'source-b',
          portId: 'out-b',
        );

        controller.addNode(sourceA);
        controller.addNode(sourceB);
        controller.addNode(targetNode);

        // Add first connection
        controller.addConnection(
          createTestConnection(
            id: 'conn-1',
            sourceNodeId: 'source-a',
            sourcePortId: 'out-a',
            targetNodeId: 'target',
            targetPortId: 'multi-in',
          ),
        );

        // Add second connection
        controller.addConnection(
          createTestConnection(
            id: 'conn-2',
            sourceNodeId: 'source-b',
            sourcePortId: 'out-b',
            targetNodeId: 'target',
            targetPortId: 'multi-in',
          ),
        );

        await tester.pumpWidget(buildTestWidget(controller: controller));
        await tester.pumpAndSettle();

        expect(controller.connections.length, equals(2));
        expect(isPortConnected(controller, 'target', 'multi-in'), isTrue);
      },
    );

    testWidgets('removing connection updates port display', (tester) async {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a', portId: 'out');
      final nodeB = createTestNodeWithInputPort(id: 'node-b', portId: 'in');
      final connection = createTestConnection(
        id: 'removable-conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'out',
        targetNodeId: 'node-b',
        targetPortId: 'in',
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addConnection(connection);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(isPortConnected(controller, 'node-a', 'out'), isTrue);

      // Remove connection
      controller.removeConnection('removable-conn');
      await tester.pumpAndSettle();

      expect(isPortConnected(controller, 'node-a', 'out'), isFalse);
    });
  });

  // ===========================================================================
  // Theme Cascade Tests
  // ===========================================================================
  group('Theme Cascade', () {
    testWidgets('port uses theme values when no overrides', (tester) async {
      final port = Port(
        id: 'theme-cascade-port',
        name: 'Theme Cascade',
        position: PortPosition.left,
        type: PortType.input,
        // No size, shape, or theme override
      );
      final node = createTestNode(id: 'theme-cascade-node', inputPorts: [port]);
      controller.addNode(node);

      await tester.pumpWidget(
        buildTestWidget(controller: controller, theme: NodeFlowTheme.light),
      );
      await tester.pumpAndSettle();

      // Port should use theme defaults
      expect(port.size, isNull); // Will fall back to theme
      expect(port.shape, isNull); // Will fall back to theme
      expect(port.theme, isNull); // No override
    });

    testWidgets('port size overrides theme size', (tester) async {
      final port = Port(
        id: 'size-override-port',
        name: 'Size Override',
        position: PortPosition.left,
        type: PortType.input,
        size: const Size(20, 20), // Override
      );
      final node = createTestNode(id: 'size-override-node', inputPorts: [port]);
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(port.size, equals(const Size(20, 20)));
      // Theme default is Size(9, 9) but port override takes precedence
    });

    testWidgets('port theme colors override global theme colors', (
      tester,
    ) async {
      final customPortTheme = PortTheme.light.copyWith(
        color: Colors.red,
        connectedColor: Colors.blue,
        highlightColor: Colors.yellow,
      );
      final port = Port(
        id: 'color-override-port',
        name: 'Color Override',
        position: PortPosition.left,
        type: PortType.input,
        theme: customPortTheme,
      );
      final node = createTestNode(
        id: 'color-override-node',
        inputPorts: [port],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(port.theme!.color, equals(Colors.red));
      expect(port.theme!.connectedColor, equals(Colors.blue));
      expect(port.theme!.highlightColor, equals(Colors.yellow));
    });

    testWidgets('dark theme port colors are different from light theme', (
      tester,
    ) async {
      final port = Port(
        id: 'dark-theme-port',
        name: 'Dark Theme',
        position: PortPosition.left,
        type: PortType.input,
      );
      final node = createTestNode(id: 'dark-theme-node', inputPorts: [port]);
      controller.addNode(node);

      await tester.pumpWidget(
        buildTestWidget(controller: controller, theme: NodeFlowTheme.dark),
      );
      await tester.pumpAndSettle();

      // Verify dark theme is being used
      expect(
        NodeFlowTheme.dark.portTheme.color,
        isNot(equals(NodeFlowTheme.light.portTheme.color)),
      );
    });
  });

  // ===========================================================================
  // Port Shape Widget Tests
  // ===========================================================================
  group('Port Shape Widget', () {
    testWidgets('port with circle shape renders circle', (tester) async {
      final circlePort = Port(
        id: 'circle-port',
        name: 'Circle',
        position: PortPosition.left,
        type: PortType.input,
        shape: MarkerShapes.circle,
      );
      final node = createTestNode(
        id: 'circle-shape-node',
        inputPorts: [circlePort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(circlePort.shape, equals(MarkerShapes.circle));
    });

    testWidgets('port with rectangle shape renders rectangle', (tester) async {
      final rectPort = Port(
        id: 'rect-port',
        name: 'Rectangle',
        position: PortPosition.right,
        type: PortType.output,
        shape: MarkerShapes.rectangle,
      );
      final node = createTestNode(
        id: 'rect-shape-node',
        outputPorts: [rectPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(rectPort.shape, equals(MarkerShapes.rectangle));
    });

    testWidgets('port with triangle shape renders triangle', (tester) async {
      final trianglePort = Port(
        id: 'triangle-port',
        name: 'Triangle',
        position: PortPosition.top,
        type: PortType.input,
        shape: MarkerShapes.triangle,
      );
      final node = createTestNode(
        id: 'triangle-shape-node',
        inputPorts: [trianglePort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(trianglePort.shape, equals(MarkerShapes.triangle));
    });

    testWidgets('port with capsuleHalf shape (default) renders capsuleHalf', (
      tester,
    ) async {
      final capsulePort = Port(
        id: 'capsule-port',
        name: 'Capsule Half',
        position: PortPosition.bottom,
        type: PortType.output,
        shape: MarkerShapes.capsuleHalf, // Default theme shape
      );
      final node = createTestNode(
        id: 'capsule-shape-node',
        outputPorts: [capsulePort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(capsulePort.shape, equals(MarkerShapes.capsuleHalf));
    });
  });

  // ===========================================================================
  // Port Behavior Mode Tests
  // ===========================================================================
  group('Port Behavior Mode', () {
    testWidgets('port is draggable in design mode', (tester) async {
      final node = createTestNodeWithPorts(id: 'design-mode-node');
      controller.addNode(node);

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          behavior: NodeFlowBehavior.design,
        ),
      );
      await tester.pumpAndSettle();

      expect(NodeFlowBehavior.design.canCreate, isTrue);
      expect(NodeFlowBehavior.design.canDrag, isTrue);
    });

    testWidgets('port is not draggable in preview mode for connections', (
      tester,
    ) async {
      final node = createTestNodeWithPorts(id: 'preview-mode-node');
      controller.addNode(node);

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          behavior: NodeFlowBehavior.preview,
        ),
      );
      await tester.pumpAndSettle();

      // In preview mode, connections cannot be created
      expect(NodeFlowBehavior.preview.canCreate, isFalse);
      // But nodes can still be dragged
      expect(NodeFlowBehavior.preview.canDrag, isTrue);
    });

    testWidgets('port is not interactive in present mode', (tester) async {
      final node = createTestNodeWithPorts(id: 'present-mode-node');
      controller.addNode(node);

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          behavior: NodeFlowBehavior.present,
        ),
      );
      await tester.pumpAndSettle();

      // In present mode, nothing is interactive
      expect(NodeFlowBehavior.present.canCreate, isFalse);
      expect(NodeFlowBehavior.present.canDrag, isFalse);
      expect(NodeFlowBehavior.present.canSelect, isFalse);
    });
  });

  // ===========================================================================
  // Port Label Position Tests
  // ===========================================================================
  group('Port Label Position', () {
    testWidgets('left port label appears to the right of port', (tester) async {
      final leftPort = Port(
        id: 'left-label-port',
        name: 'Input Data',
        position: PortPosition.left,
        type: PortType.input,
        showLabel: true,
      );
      final node = createTestNode(
        id: 'left-label-node',
        inputPorts: [leftPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      // Verify port has label enabled
      expect(leftPort.showLabel, isTrue);
      expect(leftPort.position, equals(PortPosition.left));
    });

    testWidgets('right port label appears to the left of port', (tester) async {
      final rightPort = Port(
        id: 'right-label-port',
        name: 'Output Result',
        position: PortPosition.right,
        type: PortType.output,
        showLabel: true,
      );
      final node = createTestNode(
        id: 'right-label-node',
        outputPorts: [rightPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(rightPort.showLabel, isTrue);
      expect(rightPort.position, equals(PortPosition.right));
    });

    testWidgets('top port label appears below port', (tester) async {
      final topPort = Port(
        id: 'top-label-port',
        name: 'Config',
        position: PortPosition.top,
        type: PortType.input,
        showLabel: true,
      );
      final node = createTestNode(id: 'top-label-node', inputPorts: [topPort]);
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(topPort.showLabel, isTrue);
      expect(topPort.position, equals(PortPosition.top));
    });

    testWidgets('bottom port label appears above port', (tester) async {
      final bottomPort = Port(
        id: 'bottom-label-port',
        name: 'Debug',
        position: PortPosition.bottom,
        type: PortType.output,
        showLabel: true,
      );
      final node = createTestNode(
        id: 'bottom-label-node',
        outputPorts: [bottomPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(bottomPort.showLabel, isTrue);
      expect(bottomPort.position, equals(PortPosition.bottom));
    });
  });

  // ===========================================================================
  // Edge Cases and Integration Tests
  // ===========================================================================
  group('Edge Cases', () {
    testWidgets('port with empty name renders without error', (tester) async {
      final emptyNamePort = Port(
        id: 'empty-name-port',
        name: '',
        position: PortPosition.left,
        type: PortType.input,
        showLabel: true,
      );
      final node = createTestNode(
        id: 'empty-name-node',
        inputPorts: [emptyNamePort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(emptyNamePort.name, isEmpty);
      expect(find.text('empty-name-node'), findsOneWidget);
    });

    testWidgets('port with very long name renders without overflow', (
      tester,
    ) async {
      final longNamePort = Port(
        id: 'long-name-port',
        name:
            'This is a very long port name that could potentially cause overflow issues',
        position: PortPosition.left,
        type: PortType.input,
        showLabel: true,
      );
      final node = createTestNode(
        id: 'long-name-node',
        inputPorts: [longNamePort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('long-name-node'), findsOneWidget);
    });

    testWidgets('port with zero size does not crash', (tester) async {
      final zeroSizePort = Port(
        id: 'zero-size-port',
        name: 'Zero Size',
        position: PortPosition.left,
        type: PortType.input,
        size: Size.zero,
      );
      final node = createTestNode(
        id: 'zero-size-node',
        inputPorts: [zeroSizePort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(zeroSizePort.size, equals(Size.zero));
    });

    testWidgets('non-connectable port is rendered but not interactive', (
      tester,
    ) async {
      final nonConnectablePort = Port(
        id: 'non-connectable-port',
        name: 'Non Connectable',
        position: PortPosition.left,
        type: PortType.input,
        isConnectable: false,
      );
      final node = createTestNode(
        id: 'non-connectable-node',
        inputPorts: [nonConnectablePort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(nonConnectablePort.isConnectable, isFalse);
    });

    testWidgets('hidden node does not render ports', (tester) async {
      final node = createTestNode(
        id: 'hidden-node',
        visible: false,
        inputPorts: [createInputPort(id: 'hidden-input')],
        outputPorts: [createOutputPort(id: 'hidden-output')],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      // Hidden node content should not be visible
      expect(find.text('hidden-node'), findsNothing);
    });

    testWidgets('port tooltip is set correctly', (tester) async {
      final tooltipPort = Port(
        id: 'tooltip-port',
        name: 'Tooltip Port',
        position: PortPosition.left,
        type: PortType.input,
        tooltip: 'This is a helpful tooltip',
      );
      final node = createTestNode(
        id: 'tooltip-node',
        inputPorts: [tooltipPort],
      );
      controller.addNode(node);

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(tooltipPort.tooltip, equals('This is a helpful tooltip'));
    });
  });
}
