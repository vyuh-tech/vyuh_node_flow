/// Comprehensive unit tests for port-related functionality in vyuh_node_flow.
///
/// Tests cover:
/// - Port construction with all parameters
/// - Port position calculations
/// - Port connectivity checking
/// - Multi-connection ports
/// - Port type inference
/// - Port themes and styling
/// - Port visibility options
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

  // ==========================================================================
  // Port Construction Tests
  // ==========================================================================
  group('Port Construction', () {
    group('Required Parameters', () {
      test('creates port with only required parameters', () {
        final port = Port(id: 'port-1', name: 'Input');

        expect(port.id, equals('port-1'));
        expect(port.name, equals('Input'));
      });

      test('id must be unique for equality', () {
        final port1 = Port(id: 'unique-id', name: 'Port');
        final port2 = Port(id: 'unique-id', name: 'Port');
        final port3 = Port(id: 'different-id', name: 'Port');

        expect(port1, equals(port2));
        expect(port1, isNot(equals(port3)));
      });
    });

    group('All Parameters', () {
      test('creates port with all available parameters', () {
        final theme = PortTheme.light;
        final port = Port(
          id: 'full-port',
          name: 'Full Port',
          multiConnections: true,
          position: PortPosition.right,
          offset: const Offset(10, 20),
          type: PortType.output,
          shape: MarkerShapes.circle,
          size: const Size(12, 12),
          tooltip: 'This is a tooltip',
          isConnectable: true,
          maxConnections: 5,
          showLabel: true,
          theme: theme,
        );

        expect(port.id, equals('full-port'));
        expect(port.name, equals('Full Port'));
        expect(port.multiConnections, isTrue);
        expect(port.position, equals(PortPosition.right));
        expect(port.offset, equals(const Offset(10, 20)));
        expect(port.type, equals(PortType.output));
        expect(port.shape, equals(MarkerShapes.circle));
        expect(port.size, equals(const Size(12, 12)));
        expect(port.tooltip, equals('This is a tooltip'));
        expect(port.isConnectable, isTrue);
        expect(port.maxConnections, equals(5));
        expect(port.showLabel, isTrue);
        expect(port.theme, equals(theme));
      });

      test('creates port with custom widget builder', () {
        widgetBuilderCalled = false;
        final port = Port(
          id: 'custom-widget-port',
          name: 'Custom Widget',
          widgetBuilder: (context, node, port) {
            widgetBuilderCalled = true;
            return const SizedBox(width: 10, height: 10);
          },
        );

        expect(port.widgetBuilder, isNotNull);
      });
    });

    group('Default Values', () {
      test('position defaults to left', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.position, equals(PortPosition.left));
      });

      test('offset defaults to zero', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.offset, equals(Offset.zero));
      });

      test('multiConnections defaults to false', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.multiConnections, isFalse);
      });

      test('isConnectable defaults to true', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.isConnectable, isTrue);
      });

      test('showLabel defaults to false', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.showLabel, isFalse);
      });

      test('maxConnections defaults to null', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.maxConnections, isNull);
      });

      test('shape defaults to null', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.shape, isNull);
      });

      test('size defaults to null', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.size, isNull);
      });

      test('tooltip defaults to null', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.tooltip, isNull);
      });

      test('theme defaults to null', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.theme, isNull);
      });

      test('highlighted observable defaults to false', () {
        final port = Port(id: 'port', name: 'Port');
        expect(port.highlighted.value, isFalse);
      });
    });
  });

  // ==========================================================================
  // Port Position Calculations
  // ==========================================================================
  group('Port Position Calculations', () {
    group('connectionOffset', () {
      test(
        'left position returns offset at left edge, vertically centered',
        () {
          const portSize = Size(10, 10);
          final offset = PortPosition.left.connectionOffset(portSize);

          expect(offset.dx, equals(0));
          expect(offset.dy, equals(5)); // portSize.height / 2
        },
      );

      test(
        'right position returns offset at right edge, vertically centered',
        () {
          const portSize = Size(10, 10);
          final offset = PortPosition.right.connectionOffset(portSize);

          expect(offset.dx, equals(10)); // portSize.width
          expect(offset.dy, equals(5)); // portSize.height / 2
        },
      );

      test(
        'top position returns offset at top edge, horizontally centered',
        () {
          const portSize = Size(10, 10);
          final offset = PortPosition.top.connectionOffset(portSize);

          expect(offset.dx, equals(5)); // portSize.width / 2
          expect(offset.dy, equals(0));
        },
      );

      test(
        'bottom position returns offset at bottom edge, horizontally centered',
        () {
          const portSize = Size(10, 10);
          final offset = PortPosition.bottom.connectionOffset(portSize);

          expect(offset.dx, equals(5)); // portSize.width / 2
          expect(offset.dy, equals(10)); // portSize.height
        },
      );

      test('connectionOffset works with asymmetric port sizes', () {
        const portSize = Size(20, 10);

        expect(
          PortPosition.left.connectionOffset(portSize),
          equals(const Offset(0, 5)),
        );
        expect(
          PortPosition.right.connectionOffset(portSize),
          equals(const Offset(20, 5)),
        );
        expect(
          PortPosition.top.connectionOffset(portSize),
          equals(const Offset(10, 0)),
        );
        expect(
          PortPosition.bottom.connectionOffset(portSize),
          equals(const Offset(10, 10)),
        );
      });
    });

    group('calculateOrigin', () {
      test('left port origin calculation with rectangular node', () {
        final origin = PortPosition.left.calculateOrigin(
          anchorOffset: const Offset(0, 50),
          portSize: const Size(10, 10),
          portAdjustment: Offset.zero,
          useAnchorForPerpendicularAxis: false,
        );

        // For left: x = anchorOffset.dx + adjustment.dx
        //           y = adjustment.dy - portSize.height / 2
        expect(origin.dx, equals(0));
        expect(origin.dy, equals(-5)); // 0 - 5
      });

      test('right port origin calculation with rectangular node', () {
        final origin = PortPosition.right.calculateOrigin(
          anchorOffset: const Offset(100, 50),
          portSize: const Size(10, 10),
          portAdjustment: Offset.zero,
          useAnchorForPerpendicularAxis: false,
        );

        // For right: x = anchorOffset.dx - portSize.width + adjustment.dx
        //            y = adjustment.dy - portSize.height / 2
        expect(origin.dx, equals(90)); // 100 - 10
        expect(origin.dy, equals(-5)); // 0 - 5
      });

      test('top port origin calculation with rectangular node', () {
        final origin = PortPosition.top.calculateOrigin(
          anchorOffset: const Offset(50, 0),
          portSize: const Size(10, 10),
          portAdjustment: Offset.zero,
          useAnchorForPerpendicularAxis: false,
        );

        // For top: x = adjustment.dx - portSize.width / 2
        //          y = anchorOffset.dy + adjustment.dy
        expect(origin.dx, equals(-5)); // 0 - 5
        expect(origin.dy, equals(0));
      });

      test('bottom port origin calculation with rectangular node', () {
        final origin = PortPosition.bottom.calculateOrigin(
          anchorOffset: const Offset(50, 100),
          portSize: const Size(10, 10),
          portAdjustment: Offset.zero,
          useAnchorForPerpendicularAxis: false,
        );

        // For bottom: x = adjustment.dx - portSize.width / 2
        //             y = anchorOffset.dy - portSize.height + adjustment.dy
        expect(origin.dx, equals(-5)); // 0 - 5
        expect(origin.dy, equals(90)); // 100 - 10
      });

      test('port origin with adjustment offset', () {
        final origin = PortPosition.left.calculateOrigin(
          anchorOffset: const Offset(0, 50),
          portSize: const Size(10, 10),
          portAdjustment: const Offset(5, 25), // Additional offset
          useAnchorForPerpendicularAxis: false,
        );

        expect(origin.dx, equals(5)); // 0 + 5
        expect(origin.dy, equals(20)); // 25 - 5
      });

      test(
        'port origin using anchor for perpendicular axis (shaped nodes)',
        () {
          final origin = PortPosition.left.calculateOrigin(
            anchorOffset: const Offset(10, 60),
            portSize: const Size(10, 10),
            portAdjustment: const Offset(0, 5),
            useAnchorForPerpendicularAxis: true,
          );

          // For shaped nodes, y uses anchor point
          expect(origin.dx, equals(10)); // anchorOffset.dx + 0
          expect(origin.dy, equals(60)); // anchorOffset.dy - 5 + 5
        },
      );
    });

    group('isHorizontal and isVertical', () {
      test('left and right are horizontal', () {
        expect(PortPosition.left.isHorizontal, isTrue);
        expect(PortPosition.right.isHorizontal, isTrue);
        expect(PortPosition.top.isHorizontal, isFalse);
        expect(PortPosition.bottom.isHorizontal, isFalse);
      });

      test('top and bottom are vertical', () {
        expect(PortPosition.top.isVertical, isTrue);
        expect(PortPosition.bottom.isVertical, isTrue);
        expect(PortPosition.left.isVertical, isFalse);
        expect(PortPosition.right.isVertical, isFalse);
      });
    });

    group('normal vectors', () {
      test('normal vectors point outward from node boundary', () {
        expect(PortPosition.left.normal, equals(const Offset(-1, 0)));
        expect(PortPosition.right.normal, equals(const Offset(1, 0)));
        expect(PortPosition.top.normal, equals(const Offset(0, -1)));
        expect(PortPosition.bottom.normal, equals(const Offset(0, 1)));
      });
    });

    group('toOrientation', () {
      test('converts port position to shape direction', () {
        expect(PortPosition.left.toOrientation(), equals(ShapeDirection.left));
        expect(
          PortPosition.right.toOrientation(),
          equals(ShapeDirection.right),
        );
        expect(PortPosition.top.toOrientation(), equals(ShapeDirection.top));
        expect(
          PortPosition.bottom.toOrientation(),
          equals(ShapeDirection.bottom),
        );
      });
    });
  });

  // ==========================================================================
  // Port Connectivity Checking
  // ==========================================================================
  group('Port Connectivity', () {
    group('isConnectable property', () {
      test('connectable port allows connections', () {
        final port = Port(id: 'port', name: 'Port', isConnectable: true);
        expect(port.isConnectable, isTrue);
      });

      test('non-connectable port prevents connections', () {
        final port = Port(id: 'port', name: 'Port', isConnectable: false);
        expect(port.isConnectable, isFalse);
      });
    });

    group('isInput and isOutput', () {
      test('input type port is input but not output', () {
        final port = Port(id: 'port', name: 'Port', type: PortType.input);

        expect(port.isInput, isTrue);
        expect(port.isOutput, isFalse);
      });

      test('output type port is output but not input', () {
        final port = Port(id: 'port', name: 'Port', type: PortType.output);

        expect(port.isOutput, isTrue);
        expect(port.isInput, isFalse);
      });
    });

    group('highlighted state', () {
      test('highlighted observable can be toggled', () {
        final port = Port(id: 'port', name: 'Port');

        expect(port.highlighted.value, isFalse);

        port.highlighted.value = true;
        expect(port.highlighted.value, isTrue);

        port.highlighted.value = false;
        expect(port.highlighted.value, isFalse);
      });

      test('multiple ports have independent highlighted states', () {
        final port1 = Port(id: 'port-1', name: 'Port 1');
        final port2 = Port(id: 'port-2', name: 'Port 2');

        port1.highlighted.value = true;

        expect(port1.highlighted.value, isTrue);
        expect(port2.highlighted.value, isFalse);
      });
    });
  });

  // ==========================================================================
  // Multi-Connection Ports
  // ==========================================================================
  group('Multi-Connection Ports', () {
    group('multiConnections property', () {
      test('single connection port', () {
        final port = Port(id: 'port', name: 'Port', multiConnections: false);
        expect(port.multiConnections, isFalse);
      });

      test('multi-connection port', () {
        final port = Port(id: 'port', name: 'Port', multiConnections: true);
        expect(port.multiConnections, isTrue);
      });
    });

    group('maxConnections property', () {
      test('unlimited connections when maxConnections is null', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          multiConnections: true,
          maxConnections: null,
        );
        expect(port.maxConnections, isNull);
      });

      test('limited connections with maxConnections set', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          multiConnections: true,
          maxConnections: 3,
        );
        expect(port.maxConnections, equals(3));
      });

      test('maxConnections of zero', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          multiConnections: true,
          maxConnections: 0,
        );
        expect(port.maxConnections, equals(0));
      });

      test('maxConnections of one', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          multiConnections: true,
          maxConnections: 1,
        );
        expect(port.maxConnections, equals(1));
      });

      test('very large maxConnections', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          multiConnections: true,
          maxConnections: 1000000,
        );
        expect(port.maxConnections, equals(1000000));
      });
    });

    group('controller connection management', () {
      test(
        'connecting to single-connection port replaces existing connection',
        () {
          final nodeA = createTestNodeWithOutputPort(
            id: 'node-a',
            portId: 'out',
          );
          final nodeB = createTestNodeWithInputPort(id: 'node-b', portId: 'in');
          final nodeC = createTestNodeWithOutputPort(
            id: 'node-c',
            portId: 'out',
          );

          final controller = createTestController(nodes: [nodeA, nodeB, nodeC]);

          // First connection
          controller.addConnection(
            Connection(
              id: 'conn-1',
              sourceNodeId: 'node-a',
              sourcePortId: 'out',
              targetNodeId: 'node-b',
              targetPortId: 'in',
            ),
          );

          expect(controller.connections.length, equals(1));
        },
      );

      test(
        'node with multi-connection input port can receive multiple connections',
        () {
          final multiInputPort = Port(
            id: 'multi-in',
            name: 'Multi Input',
            type: PortType.input,
            position: PortPosition.left,
            multiConnections: true,
            maxConnections: 5,
          );

          final nodeA = createTestNodeWithOutputPort(
            id: 'node-a',
            portId: 'out-a',
          );
          final nodeB = createTestNodeWithOutputPort(
            id: 'node-b',
            portId: 'out-b',
          );
          final targetNode = createTestNode(
            id: 'target',
            inputPorts: [multiInputPort],
          );

          final controller = createTestController(
            nodes: [nodeA, nodeB, targetNode],
          );

          controller.addConnection(
            Connection(
              id: 'conn-1',
              sourceNodeId: 'node-a',
              sourcePortId: 'out-a',
              targetNodeId: 'target',
              targetPortId: 'multi-in',
            ),
          );

          controller.addConnection(
            Connection(
              id: 'conn-2',
              sourceNodeId: 'node-b',
              sourcePortId: 'out-b',
              targetNodeId: 'target',
              targetPortId: 'multi-in',
            ),
          );

          expect(controller.connections.length, equals(2));
        },
      );
    });
  });

  // ==========================================================================
  // Port Type Inference
  // ==========================================================================
  group('Port Type Inference', () {
    group('inference from position', () {
      test('left position infers input type', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          position: PortPosition.left,
        );

        expect(port.type, equals(PortType.input));
        expect(port.isInput, isTrue);
      });

      test('top position infers input type', () {
        final port = Port(id: 'port', name: 'Port', position: PortPosition.top);

        expect(port.type, equals(PortType.input));
        expect(port.isInput, isTrue);
      });

      test('right position infers output type', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          position: PortPosition.right,
        );

        expect(port.type, equals(PortType.output));
        expect(port.isOutput, isTrue);
      });

      test('bottom position infers output type', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          position: PortPosition.bottom,
        );

        expect(port.type, equals(PortType.output));
        expect(port.isOutput, isTrue);
      });
    });

    group('explicit type override', () {
      test('explicit input type on right position', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          position: PortPosition.right,
          type: PortType.input,
        );

        expect(port.type, equals(PortType.input));
        expect(port.isInput, isTrue);
        expect(port.isOutput, isFalse);
      });

      test('explicit output type on left position', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          position: PortPosition.left,
          type: PortType.output,
        );

        expect(port.type, equals(PortType.output));
        expect(port.isOutput, isTrue);
        expect(port.isInput, isFalse);
      });

      test('explicit input type on bottom position', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          position: PortPosition.bottom,
          type: PortType.input,
        );

        expect(port.type, equals(PortType.input));
      });

      test('explicit output type on top position', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          position: PortPosition.top,
          type: PortType.output,
        );

        expect(port.type, equals(PortType.output));
      });
    });
  });

  // ==========================================================================
  // Port Themes and Styling
  // ==========================================================================
  group('Port Themes and Styling', () {
    group('PortTheme construction', () {
      test('creates theme with all required parameters', () {
        const theme = PortTheme(
          size: Size(12, 12),
          color: Colors.grey,
          connectedColor: Colors.green,
          highlightColor: Colors.lightGreen,
          highlightBorderColor: Colors.black,
          borderColor: Colors.white,
          borderWidth: 2.0,
        );

        expect(theme.size, equals(const Size(12, 12)));
        expect(theme.color, equals(Colors.grey));
        expect(theme.connectedColor, equals(Colors.green));
        expect(theme.highlightColor, equals(Colors.lightGreen));
        expect(theme.highlightBorderColor, equals(Colors.black));
        expect(theme.borderColor, equals(Colors.white));
        expect(theme.borderWidth, equals(2.0));
      });

      test('creates theme with optional parameters', () {
        const theme = PortTheme(
          size: Size(10, 10),
          color: Colors.blue,
          connectedColor: Colors.green,
          highlightColor: Colors.yellow,
          highlightBorderColor: Colors.black,
          borderColor: Colors.white,
          borderWidth: 1.0,
          shape: MarkerShapes.diamond,
          labelTextStyle: TextStyle(fontSize: 12, color: Colors.black),
          labelOffset: 10.0,
        );

        expect(theme.shape, equals(MarkerShapes.diamond));
        expect(theme.labelTextStyle, isNotNull);
        expect(theme.labelOffset, equals(10.0));
      });
    });

    group('predefined themes', () {
      test('light theme has correct values', () {
        const theme = PortTheme.light;

        expect(theme.size, equals(const Size(9, 9)));
        expect(theme.color, equals(const Color(0xFFBABABA)));
        expect(theme.connectedColor, equals(const Color(0xFF2196F3)));
        expect(theme.highlightColor, equals(const Color(0xFF42A5F5)));
        expect(theme.highlightBorderColor, equals(const Color(0xFF000000)));
        expect(theme.borderColor, equals(Colors.transparent));
        expect(theme.borderWidth, equals(1.0));
        expect(theme.labelOffset, equals(4.0));
      });

      test('dark theme has correct values', () {
        const theme = PortTheme.dark;

        expect(theme.size, equals(const Size(9, 9)));
        expect(theme.color, equals(const Color(0xFF666666)));
        expect(theme.connectedColor, equals(const Color(0xFF64B5F6)));
        expect(theme.highlightColor, equals(const Color(0xFF90CAF9)));
        expect(theme.highlightBorderColor, equals(const Color(0xFFFFFFFF)));
        expect(theme.borderColor, equals(Colors.transparent));
        expect(theme.borderWidth, equals(1.0));
        expect(theme.labelOffset, equals(4.0));
      });
    });

    group('theme copyWith', () {
      test('copyWith preserves values when no overrides', () {
        const original = PortTheme.light;
        final copy = original.copyWith();

        expect(copy.size, equals(original.size));
        expect(copy.color, equals(original.color));
        expect(copy.connectedColor, equals(original.connectedColor));
        expect(copy.highlightColor, equals(original.highlightColor));
        expect(copy.borderColor, equals(original.borderColor));
        expect(copy.borderWidth, equals(original.borderWidth));
      });

      test('copyWith overrides specified values', () {
        const original = PortTheme.light;
        final modified = original.copyWith(
          size: const Size(16, 16),
          color: Colors.red,
          borderWidth: 3.0,
        );

        expect(modified.size, equals(const Size(16, 16)));
        expect(modified.color, equals(Colors.red));
        expect(modified.borderWidth, equals(3.0));
        // Unmodified values remain
        expect(modified.connectedColor, equals(original.connectedColor));
        expect(modified.highlightColor, equals(original.highlightColor));
      });

      test('copyWith can change all values', () {
        const original = PortTheme.light;
        final modified = original.copyWith(
          size: const Size(20, 20),
          color: Colors.purple,
          connectedColor: Colors.orange,
          highlightColor: Colors.yellow,
          highlightBorderColor: Colors.red,
          borderColor: Colors.black,
          borderWidth: 5.0,
          shape: MarkerShapes.triangle,
          labelTextStyle: const TextStyle(fontSize: 14),
          labelOffset: 12.0,
        );

        expect(modified.size, equals(const Size(20, 20)));
        expect(modified.color, equals(Colors.purple));
        expect(modified.connectedColor, equals(Colors.orange));
        expect(modified.highlightColor, equals(Colors.yellow));
        expect(modified.highlightBorderColor, equals(Colors.red));
        expect(modified.borderColor, equals(Colors.black));
        expect(modified.borderWidth, equals(5.0));
        expect(modified.shape, equals(MarkerShapes.triangle));
        expect(modified.labelTextStyle?.fontSize, equals(14));
        expect(modified.labelOffset, equals(12.0));
      });
    });

    group('theme resolveSize', () {
      test('resolveSize uses port size when specified', () {
        const theme = PortTheme.light;
        final port = Port(id: 'port', name: 'Port', size: const Size(16, 16));

        expect(theme.resolveSize(port), equals(const Size(16, 16)));
      });

      test('resolveSize uses theme size when port size is null', () {
        const theme = PortTheme.light;
        final port = Port(id: 'port', name: 'Port');

        expect(theme.resolveSize(port), equals(theme.size));
      });
    });

    group('port-level theme override', () {
      test('port can have custom theme', () {
        final customTheme = PortTheme.light.copyWith(
          color: Colors.red,
          size: const Size(20, 20),
        );

        final port = Port(
          id: 'themed-port',
          name: 'Themed Port',
          theme: customTheme,
        );

        expect(port.theme, isNotNull);
        expect(port.theme!.color, equals(Colors.red));
        expect(port.theme!.size, equals(const Size(20, 20)));
      });

      test('port theme overrides shape', () {
        final customTheme = PortTheme.light.copyWith(
          shape: MarkerShapes.diamond,
        );

        final port = Port(
          id: 'diamond-port',
          name: 'Diamond Port',
          theme: customTheme,
        );

        expect(port.theme!.shape, equals(MarkerShapes.diamond));
      });
    });

    group('marker shapes', () {
      test('port can use circle shape', () {
        final port = Port(id: 'port', name: 'Port', shape: MarkerShapes.circle);
        expect(port.shape, equals(MarkerShapes.circle));
      });

      test('port can use rectangle shape', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          shape: MarkerShapes.rectangle,
        );
        expect(port.shape, equals(MarkerShapes.rectangle));
      });

      test('port can use diamond shape', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          shape: MarkerShapes.diamond,
        );
        expect(port.shape, equals(MarkerShapes.diamond));
      });

      test('port can use triangle shape', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          shape: MarkerShapes.triangle,
        );
        expect(port.shape, equals(MarkerShapes.triangle));
      });

      test('port can use capsuleHalf shape', () {
        final port = Port(
          id: 'port',
          name: 'Port',
          shape: MarkerShapes.capsuleHalf,
        );
        expect(port.shape, equals(MarkerShapes.capsuleHalf));
      });

      test('port can use none shape', () {
        final port = Port(id: 'port', name: 'Port', shape: MarkerShapes.none);
        expect(port.shape, equals(MarkerShapes.none));
      });
    });
  });

  // ==========================================================================
  // Port Visibility Options
  // ==========================================================================
  group('Port Visibility Options', () {
    group('showLabel property', () {
      test('port with showLabel false hides label', () {
        final port = Port(id: 'port', name: 'Hidden Label', showLabel: false);
        expect(port.showLabel, isFalse);
      });

      test('port with showLabel true shows label', () {
        final port = Port(id: 'port', name: 'Visible Label', showLabel: true);
        expect(port.showLabel, isTrue);
      });
    });

    group('port in node visibility context', () {
      test('visible node contains visible ports', () {
        final node = createTestNodeWithPorts(id: 'visible-node');
        expect(node.isVisible, isTrue);
        expect(node.inputPorts.isNotEmpty, isTrue);
        expect(node.outputPorts.isNotEmpty, isTrue);
      });

      test('invisible node has ports but is not visible', () {
        final node = createTestNode(
          id: 'invisible-node',
          visible: false,
          inputPorts: [createInputPort()],
          outputPorts: [createOutputPort()],
        );
        expect(node.isVisible, isFalse);
        expect(node.inputPorts.isNotEmpty, isTrue);
      });
    });
  });

  // ==========================================================================
  // Port copyWith
  // ==========================================================================
  group('Port copyWith', () {
    test('copyWith preserves all values when no overrides', () {
      final original = Port(
        id: 'port',
        name: 'Original',
        multiConnections: true,
        position: PortPosition.right,
        offset: const Offset(10, 20),
        type: PortType.output,
        shape: MarkerShapes.circle,
        size: const Size(12, 12),
        tooltip: 'Tooltip',
        isConnectable: true,
        maxConnections: 5,
        showLabel: true,
      );

      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.name, equals(original.name));
      expect(copy.multiConnections, equals(original.multiConnections));
      expect(copy.position, equals(original.position));
      expect(copy.offset, equals(original.offset));
      expect(copy.type, equals(original.type));
      expect(copy.shape, equals(original.shape));
      expect(copy.size, equals(original.size));
      expect(copy.tooltip, equals(original.tooltip));
      expect(copy.isConnectable, equals(original.isConnectable));
      expect(copy.maxConnections, equals(original.maxConnections));
      expect(copy.showLabel, equals(original.showLabel));
    });

    test('copyWith overrides specified values', () {
      final original = Port(id: 'port', name: 'Original');

      final modified = original.copyWith(
        id: 'new-id',
        name: 'Modified',
        showLabel: true,
      );

      expect(modified.id, equals('new-id'));
      expect(modified.name, equals('Modified'));
      expect(modified.showLabel, isTrue);
      // Original unchanged
      expect(original.id, equals('port'));
      expect(original.name, equals('Original'));
    });

    test('copyWith can change position and type', () {
      final original = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left,
        type: PortType.input,
      );

      final modified = original.copyWith(
        position: PortPosition.right,
        type: PortType.output,
      );

      expect(modified.position, equals(PortPosition.right));
      expect(modified.type, equals(PortType.output));
    });

    test('copyWith can add/change theme', () {
      final original = Port(id: 'port', name: 'Port');
      final newTheme = PortTheme.dark;

      final modified = original.copyWith(theme: newTheme);

      expect(modified.theme, equals(newTheme));
      expect(original.theme, isNull);
    });
  });

  // ==========================================================================
  // Port JSON Serialization
  // ==========================================================================
  group('Port JSON Serialization', () {
    test('toJson produces complete JSON', () {
      final port = Port(
        id: 'json-port',
        name: 'JSON Port',
        position: PortPosition.right,
        offset: const Offset(5, 10),
        type: PortType.output,
        multiConnections: true,
        maxConnections: 3,
        isConnectable: true,
        showLabel: true,
        tooltip: 'Test tooltip',
        size: const Size(14, 14),
      );

      final json = port.toJson();

      expect(json['id'], equals('json-port'));
      expect(json['name'], equals('JSON Port'));
      expect(json['position'], equals('right'));
      expect(json['type'], equals('output'));
      expect(json['multiConnections'], isTrue);
      expect(json['maxConnections'], equals(3));
      expect(json['isConnectable'], isTrue);
      expect(json['showLabel'], isTrue);
      expect(json['tooltip'], equals('Test tooltip'));
    });

    test('fromJson reconstructs port correctly', () {
      final original = Port(
        id: 'roundtrip',
        name: 'Roundtrip Port',
        position: PortPosition.bottom,
        offset: const Offset(50, 0),
        type: PortType.output,
        multiConnections: true,
        maxConnections: 10,
        isConnectable: false,
        showLabel: true,
        tooltip: 'Reconstructed tooltip',
      );

      final json = original.toJson();
      final restored = Port.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.position, equals(original.position));
      expect(restored.offset, equals(original.offset));
      expect(restored.type, equals(original.type));
      expect(restored.multiConnections, equals(original.multiConnections));
      expect(restored.maxConnections, equals(original.maxConnections));
      expect(restored.isConnectable, equals(original.isConnectable));
      expect(restored.showLabel, equals(original.showLabel));
      expect(restored.tooltip, equals(original.tooltip));
    });

    test('JSON roundtrip preserves all serializable properties', () {
      final original = Port(
        id: 'complete',
        name: 'Complete Port',
        position: PortPosition.top,
        offset: const Offset(75, 5),
        type: PortType.input,
        multiConnections: false,
        maxConnections: null,
        isConnectable: true,
        showLabel: false,
        tooltip: null,
        size: const Size(10, 10),
        shape: MarkerShapes.circle,
      );

      final json = original.toJson();
      final restored = Port.fromJson(json);

      expect(restored, equals(original));
    });
  });

  // ==========================================================================
  // Port buildWidget
  // ==========================================================================
  group('Port buildWidget', () {
    test('buildWidget returns null when no widgetBuilder set', () {
      final port = Port(id: 'port', name: 'Port');
      final node = createTestNode();

      // We can't call buildWidget without BuildContext, but we can verify the builder is null
      expect(port.widgetBuilder, isNull);
    });

    test('port with widgetBuilder has non-null builder', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        widgetBuilder: (context, node, port) => const SizedBox(),
      );

      expect(port.widgetBuilder, isNotNull);
    });
  });

  // ==========================================================================
  // Port Equality
  // ==========================================================================
  group('Port Equality', () {
    test('ports with identical properties are equal', () {
      final port1 = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left,
        offset: const Offset(0, 10),
        type: PortType.input,
        multiConnections: true,
        maxConnections: 5,
        isConnectable: true,
        showLabel: true,
        tooltip: 'Tooltip',
        size: const Size(10, 10),
      );

      final port2 = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left,
        offset: const Offset(0, 10),
        type: PortType.input,
        multiConnections: true,
        maxConnections: 5,
        isConnectable: true,
        showLabel: true,
        tooltip: 'Tooltip',
        size: const Size(10, 10),
      );

      expect(port1, equals(port2));
      expect(port1.hashCode, equals(port2.hashCode));
    });

    test('ports with different ids are not equal', () {
      final port1 = Port(id: 'port-1', name: 'Port');
      final port2 = Port(id: 'port-2', name: 'Port');

      expect(port1, isNot(equals(port2)));
    });

    test('ports with different names are not equal', () {
      final port1 = Port(id: 'port', name: 'Port A');
      final port2 = Port(id: 'port', name: 'Port B');

      expect(port1, isNot(equals(port2)));
    });

    test('ports with different positions are not equal', () {
      final port1 = Port(id: 'port', name: 'Port', position: PortPosition.left);
      final port2 = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.right,
      );

      expect(port1, isNot(equals(port2)));
    });

    test('ports with different types are not equal', () {
      final port1 = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left,
        type: PortType.input,
      );
      final port2 = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left,
        type: PortType.output,
      );

      expect(port1, isNot(equals(port2)));
    });
  });

  // ==========================================================================
  // Edge Cases
  // ==========================================================================
  group('Edge Cases', () {
    test('port with empty name', () {
      final port = Port(id: 'port', name: '');
      expect(port.name, isEmpty);
    });

    test('port with very long name', () {
      final longName = 'A' * 1000;
      final port = Port(id: 'port', name: longName);
      expect(port.name.length, equals(1000));
    });

    test('port with special characters in id', () {
      final port = Port(id: 'port-_@#\$%', name: 'Port');
      expect(port.id, equals('port-_@#\$%'));
    });

    test('port with negative offset', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        offset: const Offset(-10, -20),
      );
      expect(port.offset, equals(const Offset(-10, -20)));
    });

    test('port with very large offset', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        offset: const Offset(10000, 10000),
      );
      expect(port.offset, equals(const Offset(10000, 10000)));
    });

    test('port with zero size', () {
      final port = Port(id: 'port', name: 'Port', size: Size.zero);
      expect(port.size, equals(Size.zero));
    });

    test('port with asymmetric size', () {
      final port = Port(id: 'port', name: 'Port', size: const Size(20, 10));
      expect(port.size, equals(const Size(20, 10)));
    });

    test('defaultPortSize constant is correct', () {
      expect(defaultPortSize, equals(const Size(9, 9)));
    });
  });

  // ==========================================================================
  // Integration with Nodes
  // ==========================================================================
  group('Integration with Nodes', () {
    test('node with multiple input ports', () {
      final ports = [
        createInputPort(id: 'in-1'),
        createInputPort(id: 'in-2'),
        createInputPort(id: 'in-3'),
      ];

      final node = createTestNode(id: 'multi-input', inputPorts: ports);

      expect(node.inputPorts.length, equals(3));
      expect(
        node.inputPorts.map((p) => p.id),
        containsAll(['in-1', 'in-2', 'in-3']),
      );
    });

    test('node with multiple output ports', () {
      final ports = [
        createOutputPort(id: 'out-1'),
        createOutputPort(id: 'out-2'),
      ];

      final node = createTestNode(id: 'multi-output', outputPorts: ports);

      expect(node.outputPorts.length, equals(2));
      expect(
        node.outputPorts.map((p) => p.id),
        containsAll(['out-1', 'out-2']),
      );
    });

    test('node with ports on all sides', () {
      final inputLeft = Port(
        id: 'left-in',
        name: 'Left Input',
        position: PortPosition.left,
        type: PortType.input,
      );
      final inputTop = Port(
        id: 'top-in',
        name: 'Top Input',
        position: PortPosition.top,
        type: PortType.input,
      );
      final outputRight = Port(
        id: 'right-out',
        name: 'Right Output',
        position: PortPosition.right,
        type: PortType.output,
      );
      final outputBottom = Port(
        id: 'bottom-out',
        name: 'Bottom Output',
        position: PortPosition.bottom,
        type: PortType.output,
      );

      final node = createTestNode(
        id: 'four-sided',
        inputPorts: [inputLeft, inputTop],
        outputPorts: [outputRight, outputBottom],
      );

      expect(node.inputPorts.length, equals(2));
      expect(node.outputPorts.length, equals(2));
    });

    test('node findPort returns correct port', () {
      final inputPort = createInputPort(id: 'specific-input');
      final outputPort = createOutputPort(id: 'specific-output');

      final node = createTestNode(
        id: 'test-node',
        inputPorts: [inputPort],
        outputPorts: [outputPort],
      );

      expect(node.findPort('specific-input'), equals(inputPort));
      expect(node.findPort('specific-output'), equals(outputPort));
      expect(node.findPort('non-existent'), isNull);
    });

    test('node isOutputPort and isInputPort work correctly', () {
      final inputPort = createInputPort(id: 'input');
      final outputPort = createOutputPort(id: 'output');

      final node = createTestNode(
        id: 'test-node',
        inputPorts: [inputPort],
        outputPorts: [outputPort],
      );

      expect(node.isOutputPort(outputPort), isTrue);
      expect(node.isOutputPort(inputPort), isFalse);
      expect(node.isInputPort(inputPort), isTrue);
      expect(node.isInputPort(outputPort), isFalse);
    });
  });
}

// Helper variable for testing widget builder callback
bool widgetBuilderCalled = false;
