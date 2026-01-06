/// Comprehensive tests for NodeFlowTheme and related theme classes.
///
/// Tests NodeFlowTheme, SelectionTheme, CursorTheme, and ResizerTheme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('NodeFlowTheme', () {
    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(NodeFlowTheme.light, isNotNull);
      });

      test('dark theme is available', () {
        expect(NodeFlowTheme.dark, isNotNull);
      });

      test('light theme has white background', () {
        expect(NodeFlowTheme.light.backgroundColor, equals(Colors.white));
      });

      test('dark theme has dark background', () {
        expect(
          NodeFlowTheme.dark.backgroundColor,
          equals(const Color(0xFF1A1A1A)),
        );
      });

      test('light theme contains all sub-themes', () {
        expect(NodeFlowTheme.light.nodeTheme, isNotNull);
        expect(NodeFlowTheme.light.connectionTheme, isNotNull);
        expect(NodeFlowTheme.light.temporaryConnectionTheme, isNotNull);
        expect(NodeFlowTheme.light.portTheme, isNotNull);
        expect(NodeFlowTheme.light.labelTheme, isNotNull);
        expect(NodeFlowTheme.light.gridTheme, isNotNull);
        expect(NodeFlowTheme.light.selectionTheme, isNotNull);
        expect(NodeFlowTheme.light.cursorTheme, isNotNull);
        expect(NodeFlowTheme.light.resizerTheme, isNotNull);
      });

      test('dark theme contains all sub-themes', () {
        expect(NodeFlowTheme.dark.nodeTheme, isNotNull);
        expect(NodeFlowTheme.dark.connectionTheme, isNotNull);
        expect(NodeFlowTheme.dark.temporaryConnectionTheme, isNotNull);
        expect(NodeFlowTheme.dark.portTheme, isNotNull);
        expect(NodeFlowTheme.dark.labelTheme, isNotNull);
        expect(NodeFlowTheme.dark.gridTheme, isNotNull);
        expect(NodeFlowTheme.dark.selectionTheme, isNotNull);
        expect(NodeFlowTheme.dark.cursorTheme, isNotNull);
        expect(NodeFlowTheme.dark.resizerTheme, isNotNull);
      });

      test('light theme has correct node theme', () {
        expect(NodeFlowTheme.light.nodeTheme, same(NodeTheme.light));
      });

      test('dark theme has correct node theme', () {
        expect(NodeFlowTheme.dark.nodeTheme, same(NodeTheme.dark));
      });

      test('light theme has correct port theme', () {
        expect(NodeFlowTheme.light.portTheme, same(PortTheme.light));
      });

      test('dark theme has correct port theme', () {
        expect(NodeFlowTheme.dark.portTheme, same(PortTheme.dark));
      });

      test('default connection animation duration is 2 seconds', () {
        expect(
          NodeFlowTheme.light.connectionAnimationDuration,
          equals(const Duration(seconds: 2)),
        );
      });

      test('temporary connection theme has dashed pattern in light', () {
        expect(
          NodeFlowTheme.light.temporaryConnectionTheme.dashPattern,
          isNotNull,
        );
      });

      test('temporary connection theme has dashed pattern in dark', () {
        expect(
          NodeFlowTheme.dark.temporaryConnectionTheme.dashPattern,
          isNotNull,
        );
      });
    });

    group('copyWith', () {
      test('copies with new backgroundColor', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(backgroundColor: Colors.grey);

        expect(copied.backgroundColor, equals(Colors.grey));
        expect(copied.nodeTheme, same(original.nodeTheme));
      });

      test('copies with new nodeTheme', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(nodeTheme: NodeTheme.dark);

        expect(copied.nodeTheme, same(NodeTheme.dark));
        expect(copied.backgroundColor, equals(original.backgroundColor));
      });

      test('copies with new connectionTheme', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(connectionTheme: ConnectionTheme.dark);

        expect(copied.connectionTheme, same(ConnectionTheme.dark));
      });

      test('copies with new temporaryConnectionTheme', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(
          temporaryConnectionTheme: ConnectionTheme.dark,
        );

        expect(copied.temporaryConnectionTheme, same(ConnectionTheme.dark));
      });

      test('copies with new connectionAnimationDuration', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(
          connectionAnimationDuration: const Duration(seconds: 5),
        );

        expect(
          copied.connectionAnimationDuration,
          equals(const Duration(seconds: 5)),
        );
      });

      test('copies with new portTheme', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(portTheme: PortTheme.dark);

        expect(copied.portTheme, same(PortTheme.dark));
      });

      test('copies with new gridTheme', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(gridTheme: GridTheme.dark);

        expect(copied.gridTheme, same(GridTheme.dark));
      });

      test('copies with new selectionTheme', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(selectionTheme: SelectionTheme.dark);

        expect(copied.selectionTheme, same(SelectionTheme.dark));
      });

      test('copies with new cursorTheme', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(cursorTheme: CursorTheme.dark);

        expect(copied.cursorTheme, same(CursorTheme.dark));
      });

      test('copies with new resizerTheme', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith(resizerTheme: ResizerTheme.dark);

        expect(copied.resizerTheme, same(ResizerTheme.dark));
      });

      test('preserves all values when no parameters provided', () {
        final original = NodeFlowTheme.light;
        final copied = original.copyWith();

        expect(copied.backgroundColor, equals(original.backgroundColor));
        expect(copied.nodeTheme, same(original.nodeTheme));
        expect(copied.connectionTheme, same(original.connectionTheme));
        expect(copied.portTheme, same(original.portTheme));
        expect(copied.gridTheme, same(original.gridTheme));
      });
    });

    group('lerp', () {
      test('lerps backgroundColor', () {
        final start = NodeFlowTheme.light;
        final end = NodeFlowTheme.dark;
        final result = start.lerp(end, 0.5);

        expect(result.backgroundColor, isNotNull);
        expect(result.backgroundColor, isNot(equals(start.backgroundColor)));
        expect(result.backgroundColor, isNot(equals(end.backgroundColor)));
      });

      test('at t=0 returns start values', () {
        final start = NodeFlowTheme.light;
        final end = NodeFlowTheme.dark;
        final result = start.lerp(end, 0.0);

        expect(result.nodeTheme, same(start.nodeTheme));
        expect(result.gridTheme, same(start.gridTheme));
      });

      test('at t=1 returns end values', () {
        final start = NodeFlowTheme.light;
        final end = NodeFlowTheme.dark;
        final result = start.lerp(end, 1.0);

        expect(result.nodeTheme, same(start.nodeTheme));
        expect(result.gridTheme, same(end.gridTheme));
      });

      test('returns self when other is null', () {
        final theme = NodeFlowTheme.light;
        final result = theme.lerp(null, 0.5);

        expect(result, same(theme));
      });
    });

    group('ThemeExtension', () {
      test('is a ThemeExtension', () {
        expect(NodeFlowTheme.light, isA<ThemeExtension<NodeFlowTheme>>());
      });
    });
  });

  group('SelectionTheme', () {
    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(SelectionTheme.light, isNotNull);
      });

      test('dark theme is available', () {
        expect(SelectionTheme.dark, isNotNull);
      });

      test('light theme has cyan color', () {
        expect(
          SelectionTheme.light.borderColor,
          equals(const Color(0xFF00BCD4)),
        );
      });

      test('dark theme has light blue color', () {
        expect(
          SelectionTheme.dark.borderColor,
          equals(const Color(0xFF64B5F6)),
        );
      });

      test('both themes have border width of 1.0', () {
        expect(SelectionTheme.light.borderWidth, equals(1.0));
        expect(SelectionTheme.dark.borderWidth, equals(1.0));
      });

      test('themes have semi-transparent fill colors', () {
        // The alpha channel of the fill colors should be non-255 (semi-transparent)
        expect(SelectionTheme.light.color.alpha, lessThan(255));
        expect(SelectionTheme.dark.color.alpha, lessThan(255));
      });
    });

    group('Construction', () {
      test('creates with all required properties', () {
        const theme = SelectionTheme(
          color: Colors.red,
          borderColor: Colors.blue,
          borderWidth: 2.0,
        );

        expect(theme.color, equals(Colors.red));
        expect(theme.borderColor, equals(Colors.blue));
        expect(theme.borderWidth, equals(2.0));
      });
    });

    group('copyWith', () {
      test('copies with new color', () {
        const original = SelectionTheme.light;
        final copied = original.copyWith(color: Colors.green);

        expect(copied.color, equals(Colors.green));
        expect(copied.borderColor, equals(original.borderColor));
      });

      test('copies with new borderColor', () {
        const original = SelectionTheme.light;
        final copied = original.copyWith(borderColor: Colors.purple);

        expect(copied.borderColor, equals(Colors.purple));
      });

      test('copies with new borderWidth', () {
        const original = SelectionTheme.light;
        final copied = original.copyWith(borderWidth: 3.0);

        expect(copied.borderWidth, equals(3.0));
      });

      test('preserves all values when no parameters provided', () {
        const original = SelectionTheme.light;
        final copied = original.copyWith();

        expect(copied.color, equals(original.color));
        expect(copied.borderColor, equals(original.borderColor));
        expect(copied.borderWidth, equals(original.borderWidth));
      });
    });
  });

  group('CursorTheme', () {
    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(CursorTheme.light, isNotNull);
      });

      test('dark theme is available', () {
        expect(CursorTheme.dark, isNotNull);
      });

      test('light theme has grab cursor for canvas', () {
        expect(CursorTheme.light.canvasCursor, equals(SystemMouseCursors.grab));
      });

      test('light theme has grabbing cursor for drag', () {
        expect(
          CursorTheme.light.dragCursor,
          equals(SystemMouseCursors.grabbing),
        );
      });

      test('light theme has click cursor for node', () {
        expect(CursorTheme.light.nodeCursor, equals(SystemMouseCursors.click));
      });

      test('light theme has precise cursor for port', () {
        expect(
          CursorTheme.light.portCursor,
          equals(SystemMouseCursors.precise),
        );
      });

      test('light theme has precise cursor for selection', () {
        expect(
          CursorTheme.light.selectionCursor,
          equals(SystemMouseCursors.precise),
        );
      });

      test('light and dark themes have same cursor types', () {
        expect(
          CursorTheme.light.canvasCursor,
          equals(CursorTheme.dark.canvasCursor),
        );
        expect(
          CursorTheme.light.dragCursor,
          equals(CursorTheme.dark.dragCursor),
        );
        expect(
          CursorTheme.light.nodeCursor,
          equals(CursorTheme.dark.nodeCursor),
        );
        expect(
          CursorTheme.light.portCursor,
          equals(CursorTheme.dark.portCursor),
        );
        expect(
          CursorTheme.light.selectionCursor,
          equals(CursorTheme.dark.selectionCursor),
        );
      });
    });

    group('Construction', () {
      test('creates with all required properties', () {
        const theme = CursorTheme(
          canvasCursor: SystemMouseCursors.basic,
          selectionCursor: SystemMouseCursors.text,
          dragCursor: SystemMouseCursors.move,
          nodeCursor: SystemMouseCursors.click,
          portCursor: SystemMouseCursors.cell,
        );

        expect(theme.canvasCursor, equals(SystemMouseCursors.basic));
        expect(theme.selectionCursor, equals(SystemMouseCursors.text));
        expect(theme.dragCursor, equals(SystemMouseCursors.move));
        expect(theme.nodeCursor, equals(SystemMouseCursors.click));
        expect(theme.portCursor, equals(SystemMouseCursors.cell));
      });
    });

    group('copyWith', () {
      test('copies with new canvasCursor', () {
        const original = CursorTheme.light;
        final copied = original.copyWith(
          canvasCursor: SystemMouseCursors.basic,
        );

        expect(copied.canvasCursor, equals(SystemMouseCursors.basic));
        expect(copied.dragCursor, equals(original.dragCursor));
      });

      test('copies with new selectionCursor', () {
        const original = CursorTheme.light;
        final copied = original.copyWith(
          selectionCursor: SystemMouseCursors.text,
        );

        expect(copied.selectionCursor, equals(SystemMouseCursors.text));
      });

      test('copies with new dragCursor', () {
        const original = CursorTheme.light;
        final copied = original.copyWith(dragCursor: SystemMouseCursors.move);

        expect(copied.dragCursor, equals(SystemMouseCursors.move));
      });

      test('copies with new nodeCursor', () {
        const original = CursorTheme.light;
        final copied = original.copyWith(nodeCursor: SystemMouseCursors.move);

        expect(copied.nodeCursor, equals(SystemMouseCursors.move));
      });

      test('copies with new portCursor', () {
        const original = CursorTheme.light;
        final copied = original.copyWith(portCursor: SystemMouseCursors.cell);

        expect(copied.portCursor, equals(SystemMouseCursors.cell));
      });

      test('preserves all values when no parameters provided', () {
        const original = CursorTheme.light;
        final copied = original.copyWith();

        expect(copied.canvasCursor, equals(original.canvasCursor));
        expect(copied.selectionCursor, equals(original.selectionCursor));
        expect(copied.dragCursor, equals(original.dragCursor));
        expect(copied.nodeCursor, equals(original.nodeCursor));
        expect(copied.portCursor, equals(original.portCursor));
      });
    });
  });

  group('ResizerTheme', () {
    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(ResizerTheme.light, isNotNull);
      });

      test('dark theme is available', () {
        expect(ResizerTheme.dark, isNotNull);
      });

      test('light theme has white color', () {
        expect(ResizerTheme.light.color, equals(Colors.white));
      });

      test('dark theme has dark color', () {
        expect(ResizerTheme.dark.color, equals(const Color(0xFF1E1E1E)));
      });

      test('light theme has blue border', () {
        expect(ResizerTheme.light.borderColor, equals(Colors.blue));
      });

      test('both themes have handle size of 8.0', () {
        expect(ResizerTheme.light.handleSize, equals(8.0));
        expect(ResizerTheme.dark.handleSize, equals(8.0));
      });

      test('both themes have border width of 1.0', () {
        expect(ResizerTheme.light.borderWidth, equals(1.0));
        expect(ResizerTheme.dark.borderWidth, equals(1.0));
      });

      test('both themes have snap distance of 4.0', () {
        expect(ResizerTheme.light.snapDistance, equals(4.0));
        expect(ResizerTheme.dark.snapDistance, equals(4.0));
      });
    });

    group('Construction', () {
      test('creates with all required properties', () {
        const theme = ResizerTheme(
          handleSize: 10.0,
          color: Colors.yellow,
          borderColor: Colors.red,
          borderWidth: 2.0,
          snapDistance: 6.0,
        );

        expect(theme.handleSize, equals(10.0));
        expect(theme.color, equals(Colors.yellow));
        expect(theme.borderColor, equals(Colors.red));
        expect(theme.borderWidth, equals(2.0));
        expect(theme.snapDistance, equals(6.0));
      });
    });

    group('copyWith', () {
      test('copies with new handleSize', () {
        const original = ResizerTheme.light;
        final copied = original.copyWith(handleSize: 12.0);

        expect(copied.handleSize, equals(12.0));
        expect(copied.color, equals(original.color));
      });

      test('copies with new color', () {
        const original = ResizerTheme.light;
        final copied = original.copyWith(color: Colors.green);

        expect(copied.color, equals(Colors.green));
      });

      test('copies with new borderColor', () {
        const original = ResizerTheme.light;
        final copied = original.copyWith(borderColor: Colors.orange);

        expect(copied.borderColor, equals(Colors.orange));
      });

      test('copies with new borderWidth', () {
        const original = ResizerTheme.light;
        final copied = original.copyWith(borderWidth: 3.0);

        expect(copied.borderWidth, equals(3.0));
      });

      test('copies with new snapDistance', () {
        const original = ResizerTheme.light;
        final copied = original.copyWith(snapDistance: 8.0);

        expect(copied.snapDistance, equals(8.0));
      });

      test('preserves all values when no parameters provided', () {
        const original = ResizerTheme.light;
        final copied = original.copyWith();

        expect(copied.handleSize, equals(original.handleSize));
        expect(copied.color, equals(original.color));
        expect(copied.borderColor, equals(original.borderColor));
        expect(copied.borderWidth, equals(original.borderWidth));
        expect(copied.snapDistance, equals(original.snapDistance));
      });
    });
  });

  group('ElementType', () {
    test('has canvas value', () {
      expect(ElementType.canvas, isNotNull);
    });

    test('has node value', () {
      expect(ElementType.node, isNotNull);
    });

    test('has port value', () {
      expect(ElementType.port, isNotNull);
    });

    test('all values are distinct', () {
      final values = ElementType.values;
      expect(values.toSet().length, equals(values.length));
    });
  });
}
