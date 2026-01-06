import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('NodeFlowTheme', () {
    group('construction', () {
      test('can be constructed with all required parameters', () {
        final theme = NodeFlowTheme(
          nodeTheme: NodeTheme.light,
          connectionTheme: ConnectionTheme.light,
          temporaryConnectionTheme: ConnectionTheme.light,
          portTheme: PortTheme.light,
          labelTheme: LabelTheme.light,
          gridTheme: GridTheme.light,
          selectionTheme: SelectionTheme.light,
          cursorTheme: CursorTheme.light,
          resizerTheme: ResizerTheme.light,
        );

        expect(theme.nodeTheme, equals(NodeTheme.light));
        expect(theme.connectionTheme, equals(ConnectionTheme.light));
        expect(theme.temporaryConnectionTheme, equals(ConnectionTheme.light));
        expect(theme.portTheme, equals(PortTheme.light));
        expect(theme.labelTheme, equals(LabelTheme.light));
        expect(theme.gridTheme, equals(GridTheme.light));
        expect(theme.selectionTheme, equals(SelectionTheme.light));
        expect(theme.cursorTheme, equals(CursorTheme.light));
        expect(theme.resizerTheme, equals(ResizerTheme.light));
      });

      test('has default backgroundColor of white', () {
        final theme = NodeFlowTheme(
          nodeTheme: NodeTheme.light,
          connectionTheme: ConnectionTheme.light,
          temporaryConnectionTheme: ConnectionTheme.light,
          portTheme: PortTheme.light,
          labelTheme: LabelTheme.light,
          gridTheme: GridTheme.light,
          selectionTheme: SelectionTheme.light,
          cursorTheme: CursorTheme.light,
          resizerTheme: ResizerTheme.light,
        );

        expect(theme.backgroundColor, equals(Colors.white));
      });

      test('has default connectionAnimationDuration of 2 seconds', () {
        final theme = NodeFlowTheme(
          nodeTheme: NodeTheme.light,
          connectionTheme: ConnectionTheme.light,
          temporaryConnectionTheme: ConnectionTheme.light,
          portTheme: PortTheme.light,
          labelTheme: LabelTheme.light,
          gridTheme: GridTheme.light,
          selectionTheme: SelectionTheme.light,
          cursorTheme: CursorTheme.light,
          resizerTheme: ResizerTheme.light,
        );

        expect(
          theme.connectionAnimationDuration,
          equals(const Duration(seconds: 2)),
        );
      });

      test('can override backgroundColor', () {
        final theme = NodeFlowTheme(
          nodeTheme: NodeTheme.light,
          connectionTheme: ConnectionTheme.light,
          temporaryConnectionTheme: ConnectionTheme.light,
          portTheme: PortTheme.light,
          labelTheme: LabelTheme.light,
          gridTheme: GridTheme.light,
          selectionTheme: SelectionTheme.light,
          cursorTheme: CursorTheme.light,
          resizerTheme: ResizerTheme.light,
          backgroundColor: Colors.grey,
        );

        expect(theme.backgroundColor, equals(Colors.grey));
      });

      test('can override connectionAnimationDuration', () {
        final theme = NodeFlowTheme(
          nodeTheme: NodeTheme.light,
          connectionTheme: ConnectionTheme.light,
          temporaryConnectionTheme: ConnectionTheme.light,
          portTheme: PortTheme.light,
          labelTheme: LabelTheme.light,
          gridTheme: GridTheme.light,
          selectionTheme: SelectionTheme.light,
          cursorTheme: CursorTheme.light,
          resizerTheme: ResizerTheme.light,
          connectionAnimationDuration: const Duration(seconds: 5),
        );

        expect(
          theme.connectionAnimationDuration,
          equals(const Duration(seconds: 5)),
        );
      });
    });

    group('predefined themes', () {
      test('light theme has correct properties', () {
        final theme = NodeFlowTheme.light;

        expect(theme.nodeTheme, equals(NodeTheme.light));
        expect(theme.connectionTheme, equals(ConnectionTheme.light));
        expect(theme.portTheme, equals(PortTheme.light));
        expect(theme.labelTheme, equals(LabelTheme.light));
        expect(theme.gridTheme, equals(GridTheme.light));
        expect(theme.selectionTheme, equals(SelectionTheme.light));
        expect(theme.cursorTheme, equals(CursorTheme.light));
        expect(theme.resizerTheme, equals(ResizerTheme.light));
        expect(theme.backgroundColor, equals(Colors.white));
      });

      test('dark theme has correct properties', () {
        final theme = NodeFlowTheme.dark;

        expect(theme.nodeTheme, equals(NodeTheme.dark));
        expect(theme.connectionTheme, equals(ConnectionTheme.dark));
        expect(theme.portTheme, equals(PortTheme.dark));
        expect(theme.labelTheme, equals(LabelTheme.dark));
        expect(theme.gridTheme, equals(GridTheme.dark));
        expect(theme.selectionTheme, equals(SelectionTheme.dark));
        expect(theme.cursorTheme, equals(CursorTheme.dark));
        expect(theme.resizerTheme, equals(ResizerTheme.dark));
        expect(theme.backgroundColor, equals(const Color(0xFF1A1A1A)));
      });

      test('light theme temporaryConnectionTheme has dashed pattern', () {
        final theme = NodeFlowTheme.light;

        expect(theme.temporaryConnectionTheme.dashPattern, equals([5.0, 5.0]));
        expect(
          theme.temporaryConnectionTheme.startPoint,
          equals(ConnectionEndPoint.none),
        );
        expect(
          theme.temporaryConnectionTheme.endPoint,
          equals(ConnectionEndPoint.capsuleHalf),
        );
      });

      test('dark theme temporaryConnectionTheme has dashed pattern', () {
        final theme = NodeFlowTheme.dark;

        expect(theme.temporaryConnectionTheme.dashPattern, equals([5.0, 5.0]));
        expect(
          theme.temporaryConnectionTheme.startPoint,
          equals(ConnectionEndPoint.none),
        );
        expect(
          theme.temporaryConnectionTheme.endPoint,
          equals(ConnectionEndPoint.capsuleHalf),
        );
      });
    });

    group('copyWith', () {
      test('returns new instance with updated nodeTheme', () {
        final original = NodeFlowTheme.light;
        final updated = original.copyWith(nodeTheme: NodeTheme.dark);

        expect(updated.nodeTheme, equals(NodeTheme.dark));
        expect(updated.connectionTheme, equals(original.connectionTheme));
        expect(updated.portTheme, equals(original.portTheme));
      });

      test('returns new instance with updated connectionTheme', () {
        final original = NodeFlowTheme.light;
        final updated = original.copyWith(
          connectionTheme: ConnectionTheme.dark,
        );

        expect(updated.connectionTheme, equals(ConnectionTheme.dark));
        expect(updated.nodeTheme, equals(original.nodeTheme));
      });

      test('returns new instance with updated backgroundColor', () {
        final original = NodeFlowTheme.light;
        final updated = original.copyWith(backgroundColor: Colors.red);

        expect(updated.backgroundColor, equals(Colors.red));
        expect(updated.nodeTheme, equals(original.nodeTheme));
      });

      test('returns new instance with updated selectionTheme', () {
        final original = NodeFlowTheme.light;
        final updated = original.copyWith(selectionTheme: SelectionTheme.dark);

        expect(updated.selectionTheme, equals(SelectionTheme.dark));
      });

      test('returns new instance with updated resizerTheme', () {
        final original = NodeFlowTheme.light;
        final updated = original.copyWith(resizerTheme: ResizerTheme.dark);

        expect(updated.resizerTheme, equals(ResizerTheme.dark));
      });

      test('returns new instance with updated connectionAnimationDuration', () {
        final original = NodeFlowTheme.light;
        final updated = original.copyWith(
          connectionAnimationDuration: const Duration(seconds: 10),
        );

        expect(
          updated.connectionAnimationDuration,
          equals(const Duration(seconds: 10)),
        );
      });

      test('preserves all properties when no arguments provided', () {
        final original = NodeFlowTheme.light;
        final updated = original.copyWith();

        expect(updated.nodeTheme, equals(original.nodeTheme));
        expect(updated.connectionTheme, equals(original.connectionTheme));
        expect(
          updated.temporaryConnectionTheme,
          equals(original.temporaryConnectionTheme),
        );
        expect(updated.portTheme, equals(original.portTheme));
        expect(updated.labelTheme, equals(original.labelTheme));
        expect(updated.gridTheme, equals(original.gridTheme));
        expect(updated.selectionTheme, equals(original.selectionTheme));
        expect(updated.cursorTheme, equals(original.cursorTheme));
        expect(updated.resizerTheme, equals(original.resizerTheme));
        expect(updated.backgroundColor, equals(original.backgroundColor));
      });
    });

    group('lerp', () {
      test('returns this when other is not NodeFlowTheme', () {
        final theme = NodeFlowTheme.light;
        final result = theme.lerp(null, 0.5);

        expect(identical(result, theme), isTrue);
      });

      test('lerps backgroundColor', () {
        final light = NodeFlowTheme.light;
        final dark = NodeFlowTheme.dark;
        final result = light.lerp(dark, 0.5);

        final expectedColor = Color.lerp(
          light.backgroundColor,
          dark.backgroundColor,
          0.5,
        );
        expect(result.backgroundColor, equals(expectedColor));
      });

      test('switches themes at t=0.5', () {
        final light = NodeFlowTheme.light;
        final dark = NodeFlowTheme.dark;

        final beforeHalf = light.lerp(dark, 0.4);
        final afterHalf = light.lerp(dark, 0.6);

        expect(beforeHalf.gridTheme, equals(light.gridTheme));
        expect(afterHalf.gridTheme, equals(dark.gridTheme));
      });
    });

    group('ThemeExtension', () {
      test('is a ThemeExtension', () {
        expect(NodeFlowTheme.light, isA<ThemeExtension<NodeFlowTheme>>());
      });
    });
  });

  group('NodeTheme', () {
    group('construction', () {
      test('can be constructed with all required parameters', () {
        final theme = NodeTheme(
          backgroundColor: Colors.white,
          selectedBackgroundColor: Colors.grey,
          highlightBackgroundColor: Colors.lightBlue,
          borderColor: Colors.black,
          selectedBorderColor: Colors.blue,
          highlightBorderColor: Colors.cyan,
          borderWidth: 1.0,
          selectedBorderWidth: 2.0,
          borderRadius: BorderRadius.circular(4.0),
          titleStyle: const TextStyle(fontSize: 14.0),
          contentStyle: const TextStyle(fontSize: 12.0),
        );

        expect(theme.backgroundColor, equals(Colors.white));
        expect(theme.selectedBackgroundColor, equals(Colors.grey));
        expect(theme.highlightBackgroundColor, equals(Colors.lightBlue));
        expect(theme.borderColor, equals(Colors.black));
        expect(theme.selectedBorderColor, equals(Colors.blue));
        expect(theme.highlightBorderColor, equals(Colors.cyan));
        expect(theme.borderWidth, equals(1.0));
        expect(theme.selectedBorderWidth, equals(2.0));
        expect(theme.borderRadius, equals(BorderRadius.circular(4.0)));
        expect(theme.titleStyle.fontSize, equals(14.0));
        expect(theme.contentStyle.fontSize, equals(12.0));
      });
    });

    group('predefined themes', () {
      test('light theme has correct colors', () {
        const theme = NodeTheme.light;

        expect(theme.backgroundColor, equals(Colors.white));
        expect(theme.selectedBackgroundColor, equals(const Color(0xFFF5F5F5)));
        expect(theme.highlightBackgroundColor, equals(const Color(0xFFE3F2FD)));
        expect(theme.borderColor, equals(const Color(0xFFE0E0E0)));
        expect(theme.selectedBorderColor, equals(const Color(0xFF2196F3)));
        expect(theme.highlightBorderColor, equals(const Color(0xFF42A5F5)));
        expect(theme.borderWidth, equals(2.0));
        expect(theme.selectedBorderWidth, equals(2.0));
      });

      test('dark theme has correct colors', () {
        const theme = NodeTheme.dark;

        expect(theme.backgroundColor, equals(const Color(0xFF2D2D2D)));
        expect(theme.selectedBackgroundColor, equals(const Color(0xFF3D3D3D)));
        expect(theme.highlightBackgroundColor, equals(const Color(0xFF263238)));
        expect(theme.borderColor, equals(const Color(0xFF555555)));
        expect(theme.selectedBorderColor, equals(const Color(0xFF64B5F6)));
        expect(theme.highlightBorderColor, equals(const Color(0xFF90CAF9)));
      });

      test('light and dark themes have same border radius', () {
        expect(
          NodeTheme.light.borderRadius,
          equals(NodeTheme.dark.borderRadius),
        );
        expect(
          NodeTheme.light.borderRadius,
          equals(const BorderRadius.all(Radius.circular(8.0))),
        );
      });
    });

    group('copyWith', () {
      test('returns new instance with updated backgroundColor', () {
        final original = NodeTheme.light;
        final updated = original.copyWith(backgroundColor: Colors.red);

        expect(updated.backgroundColor, equals(Colors.red));
        expect(updated.borderColor, equals(original.borderColor));
      });

      test('returns new instance with updated borderRadius', () {
        final original = NodeTheme.light;
        final updated = original.copyWith(
          borderRadius: BorderRadius.circular(16.0),
        );

        expect(updated.borderRadius, equals(BorderRadius.circular(16.0)));
      });

      test('returns new instance with updated titleStyle', () {
        final original = NodeTheme.light;
        final updated = original.copyWith(
          titleStyle: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        );

        expect(updated.titleStyle.fontSize, equals(20.0));
        expect(updated.titleStyle.fontWeight, equals(FontWeight.bold));
      });

      test('preserves all properties when no arguments provided', () {
        const original = NodeTheme.light;
        final updated = original.copyWith();

        expect(updated.backgroundColor, equals(original.backgroundColor));
        expect(
          updated.selectedBackgroundColor,
          equals(original.selectedBackgroundColor),
        );
        expect(updated.borderColor, equals(original.borderColor));
        expect(updated.borderWidth, equals(original.borderWidth));
      });
    });
  });

  group('PortTheme', () {
    group('construction', () {
      test('can be constructed with all required parameters', () {
        final theme = PortTheme(
          size: const Size(10, 10),
          color: Colors.grey,
          connectedColor: Colors.green,
          highlightColor: Colors.lightGreen,
          highlightBorderColor: Colors.black,
          borderColor: Colors.white,
          borderWidth: 2.0,
        );

        expect(theme.size, equals(const Size(10, 10)));
        expect(theme.color, equals(Colors.grey));
        expect(theme.connectedColor, equals(Colors.green));
        expect(theme.highlightColor, equals(Colors.lightGreen));
        expect(theme.highlightBorderColor, equals(Colors.black));
        expect(theme.borderColor, equals(Colors.white));
        expect(theme.borderWidth, equals(2.0));
      });

      test('has default labelOffset of 4.0', () {
        final theme = PortTheme(
          size: const Size(10, 10),
          color: Colors.grey,
          connectedColor: Colors.green,
          highlightColor: Colors.lightGreen,
          highlightBorderColor: Colors.black,
          borderColor: Colors.white,
          borderWidth: 2.0,
        );

        expect(theme.labelOffset, equals(4.0));
      });

      test('has default shape of capsuleHalf', () {
        final theme = PortTheme(
          size: const Size(10, 10),
          color: Colors.grey,
          connectedColor: Colors.green,
          highlightColor: Colors.lightGreen,
          highlightBorderColor: Colors.black,
          borderColor: Colors.white,
          borderWidth: 2.0,
        );

        expect(theme.shape, equals(MarkerShapes.capsuleHalf));
      });
    });

    group('predefined themes', () {
      test('light theme has correct properties', () {
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

      test('dark theme has correct properties', () {
        const theme = PortTheme.dark;

        expect(theme.size, equals(const Size(9, 9)));
        expect(theme.color, equals(const Color(0xFF666666)));
        expect(theme.connectedColor, equals(const Color(0xFF64B5F6)));
        expect(theme.highlightColor, equals(const Color(0xFF90CAF9)));
        expect(theme.highlightBorderColor, equals(const Color(0xFFFFFFFF)));
        expect(theme.borderColor, equals(Colors.transparent));
      });

      test('light and dark themes have labelTextStyle', () {
        expect(PortTheme.light.labelTextStyle, isNotNull);
        expect(PortTheme.dark.labelTextStyle, isNotNull);
        expect(PortTheme.light.labelTextStyle!.fontSize, equals(10.0));
        expect(PortTheme.dark.labelTextStyle!.fontSize, equals(10.0));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated size', () {
        const original = PortTheme.light;
        final updated = original.copyWith(size: const Size(15, 15));

        expect(updated.size, equals(const Size(15, 15)));
        expect(updated.color, equals(original.color));
      });

      test('returns new instance with updated color', () {
        const original = PortTheme.light;
        final updated = original.copyWith(color: Colors.purple);

        expect(updated.color, equals(Colors.purple));
      });

      test('returns new instance with updated shape', () {
        const original = PortTheme.light;
        final updated = original.copyWith(shape: MarkerShapes.circle);

        expect(updated.shape, equals(MarkerShapes.circle));
      });

      test('preserves all properties when no arguments provided', () {
        const original = PortTheme.light;
        final updated = original.copyWith();

        expect(updated.size, equals(original.size));
        expect(updated.color, equals(original.color));
        expect(updated.connectedColor, equals(original.connectedColor));
        expect(updated.highlightColor, equals(original.highlightColor));
        expect(updated.borderWidth, equals(original.borderWidth));
        expect(updated.labelOffset, equals(original.labelOffset));
      });
    });
  });

  group('LabelTheme', () {
    group('construction', () {
      test('can be constructed with default values', () {
        const theme = LabelTheme();

        expect(theme.textStyle.fontSize, equals(12.0));
        expect(theme.backgroundColor, isNull);
        expect(theme.border, isNull);
        expect(
          theme.borderRadius,
          equals(const BorderRadius.all(Radius.circular(4.0))),
        );
        expect(
          theme.padding,
          equals(const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
        );
        expect(theme.maxWidth, equals(double.infinity));
        expect(theme.maxLines, isNull);
        expect(theme.offset, equals(0.0));
        expect(theme.labelGap, equals(8.0));
      });

      test('can be constructed with custom values', () {
        const theme = LabelTheme(
          textStyle: TextStyle(fontSize: 16.0, color: Colors.red),
          backgroundColor: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          padding: EdgeInsets.all(10.0),
          maxWidth: 200.0,
          maxLines: 2,
          offset: 5.0,
          labelGap: 12.0,
        );

        expect(theme.textStyle.fontSize, equals(16.0));
        expect(theme.textStyle.color, equals(Colors.red));
        expect(theme.backgroundColor, equals(Colors.white));
        expect(
          theme.borderRadius,
          equals(const BorderRadius.all(Radius.circular(8.0))),
        );
        expect(theme.padding, equals(const EdgeInsets.all(10.0)));
        expect(theme.maxWidth, equals(200.0));
        expect(theme.maxLines, equals(2));
        expect(theme.offset, equals(5.0));
        expect(theme.labelGap, equals(12.0));
      });
    });

    group('predefined themes', () {
      test('light theme has correct properties', () {
        const theme = LabelTheme.light;

        expect(theme.textStyle.color, equals(const Color(0xFF333333)));
        expect(theme.textStyle.fontSize, equals(12.0));
        expect(theme.textStyle.fontWeight, equals(FontWeight.w500));
        expect(theme.backgroundColor, equals(const Color(0xFFFBFBFB)));
        expect(theme.border, isNotNull);
        expect(
          theme.borderRadius,
          equals(const BorderRadius.all(Radius.circular(4.0))),
        );
        expect(theme.offset, equals(0.0));
      });

      test('dark theme has correct properties', () {
        const theme = LabelTheme.dark;

        expect(theme.textStyle.color, equals(const Color(0xFFE5E5E5)));
        expect(theme.textStyle.fontSize, equals(12.0));
        expect(theme.textStyle.fontWeight, equals(FontWeight.w500));
        expect(theme.backgroundColor, equals(const Color(0xFF404040)));
        expect(theme.border, isNotNull);
        expect(theme.offset, equals(0.0));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated textStyle', () {
        const original = LabelTheme.light;
        final updated = original.copyWith(
          textStyle: const TextStyle(fontSize: 20.0),
        );

        expect(updated.textStyle.fontSize, equals(20.0));
        expect(updated.backgroundColor, equals(original.backgroundColor));
      });

      test('returns new instance with updated backgroundColor', () {
        const original = LabelTheme.light;
        final updated = original.copyWith(backgroundColor: Colors.yellow);

        expect(updated.backgroundColor, equals(Colors.yellow));
      });

      test('returns new instance with updated maxWidth', () {
        const original = LabelTheme.light;
        final updated = original.copyWith(maxWidth: 150.0);

        expect(updated.maxWidth, equals(150.0));
      });

      test('returns new instance with updated labelGap', () {
        const original = LabelTheme.light;
        final updated = original.copyWith(labelGap: 16.0);

        expect(updated.labelGap, equals(16.0));
      });

      test('preserves all properties when no arguments provided', () {
        const original = LabelTheme.light;
        final updated = original.copyWith();

        expect(updated.textStyle, equals(original.textStyle));
        expect(updated.backgroundColor, equals(original.backgroundColor));
        expect(updated.border, equals(original.border));
        expect(updated.borderRadius, equals(original.borderRadius));
        expect(updated.padding, equals(original.padding));
        expect(updated.offset, equals(original.offset));
      });
    });
  });

  group('CursorTheme', () {
    group('construction', () {
      test('can be constructed with all required parameters', () {
        const theme = CursorTheme(
          canvasCursor: SystemMouseCursors.basic,
          selectionCursor: SystemMouseCursors.precise,
          dragCursor: SystemMouseCursors.move,
          nodeCursor: SystemMouseCursors.click,
          portCursor: SystemMouseCursors.precise,
        );

        expect(theme.canvasCursor, equals(SystemMouseCursors.basic));
        expect(theme.selectionCursor, equals(SystemMouseCursors.precise));
        expect(theme.dragCursor, equals(SystemMouseCursors.move));
        expect(theme.nodeCursor, equals(SystemMouseCursors.click));
        expect(theme.portCursor, equals(SystemMouseCursors.precise));
      });
    });

    group('predefined themes', () {
      test('light theme has correct cursors', () {
        const theme = CursorTheme.light;

        expect(theme.canvasCursor, equals(SystemMouseCursors.grab));
        expect(theme.selectionCursor, equals(SystemMouseCursors.precise));
        expect(theme.dragCursor, equals(SystemMouseCursors.grabbing));
        expect(theme.nodeCursor, equals(SystemMouseCursors.click));
        expect(theme.portCursor, equals(SystemMouseCursors.precise));
      });

      test('dark theme has same cursors as light theme', () {
        const light = CursorTheme.light;
        const dark = CursorTheme.dark;

        expect(dark.canvasCursor, equals(light.canvasCursor));
        expect(dark.selectionCursor, equals(light.selectionCursor));
        expect(dark.dragCursor, equals(light.dragCursor));
        expect(dark.nodeCursor, equals(light.nodeCursor));
        expect(dark.portCursor, equals(light.portCursor));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated canvasCursor', () {
        const original = CursorTheme.light;
        final updated = original.copyWith(
          canvasCursor: SystemMouseCursors.basic,
        );

        expect(updated.canvasCursor, equals(SystemMouseCursors.basic));
        expect(updated.dragCursor, equals(original.dragCursor));
      });

      test('returns new instance with updated dragCursor', () {
        const original = CursorTheme.light;
        final updated = original.copyWith(dragCursor: SystemMouseCursors.move);

        expect(updated.dragCursor, equals(SystemMouseCursors.move));
      });

      test('returns new instance with updated portCursor', () {
        const original = CursorTheme.light;
        final updated = original.copyWith(portCursor: SystemMouseCursors.cell);

        expect(updated.portCursor, equals(SystemMouseCursors.cell));
      });

      test('preserves all properties when no arguments provided', () {
        const original = CursorTheme.light;
        final updated = original.copyWith();

        expect(updated.canvasCursor, equals(original.canvasCursor));
        expect(updated.selectionCursor, equals(original.selectionCursor));
        expect(updated.dragCursor, equals(original.dragCursor));
        expect(updated.nodeCursor, equals(original.nodeCursor));
        expect(updated.portCursor, equals(original.portCursor));
      });
    });
  });

  group('SelectionTheme', () {
    group('construction', () {
      test('can be constructed with all required parameters', () {
        const theme = SelectionTheme(
          color: Colors.blue,
          borderColor: Colors.blueAccent,
          borderWidth: 2.0,
        );

        expect(theme.color, equals(Colors.blue));
        expect(theme.borderColor, equals(Colors.blueAccent));
        expect(theme.borderWidth, equals(2.0));
      });
    });

    group('predefined themes', () {
      test('light theme has correct properties', () {
        const theme = SelectionTheme.light;

        expect(theme.color, equals(const Color(0x3300BCD4)));
        expect(theme.borderColor, equals(const Color(0xFF00BCD4)));
        expect(theme.borderWidth, equals(1.0));
      });

      test('dark theme has correct properties', () {
        const theme = SelectionTheme.dark;

        expect(theme.color, equals(const Color(0x3364B5F6)));
        expect(theme.borderColor, equals(const Color(0xFF64B5F6)));
        expect(theme.borderWidth, equals(1.0));
      });

      test('light and dark themes have same borderWidth', () {
        expect(
          SelectionTheme.light.borderWidth,
          equals(SelectionTheme.dark.borderWidth),
        );
      });
    });

    group('copyWith', () {
      test('returns new instance with updated color', () {
        const original = SelectionTheme.light;
        final updated = original.copyWith(color: Colors.green);

        expect(updated.color, equals(Colors.green));
        expect(updated.borderColor, equals(original.borderColor));
      });

      test('returns new instance with updated borderColor', () {
        const original = SelectionTheme.light;
        final updated = original.copyWith(borderColor: Colors.red);

        expect(updated.borderColor, equals(Colors.red));
      });

      test('returns new instance with updated borderWidth', () {
        const original = SelectionTheme.light;
        final updated = original.copyWith(borderWidth: 3.0);

        expect(updated.borderWidth, equals(3.0));
      });

      test('preserves all properties when no arguments provided', () {
        const original = SelectionTheme.light;
        final updated = original.copyWith();

        expect(updated.color, equals(original.color));
        expect(updated.borderColor, equals(original.borderColor));
        expect(updated.borderWidth, equals(original.borderWidth));
      });
    });
  });

  group('ResizerTheme', () {
    group('construction', () {
      test('can be constructed with all required parameters', () {
        const theme = ResizerTheme(
          handleSize: 10.0,
          color: Colors.white,
          borderColor: Colors.blue,
          borderWidth: 2.0,
          snapDistance: 5.0,
        );

        expect(theme.handleSize, equals(10.0));
        expect(theme.color, equals(Colors.white));
        expect(theme.borderColor, equals(Colors.blue));
        expect(theme.borderWidth, equals(2.0));
        expect(theme.snapDistance, equals(5.0));
      });
    });

    group('predefined themes', () {
      test('light theme has correct properties', () {
        const theme = ResizerTheme.light;

        expect(theme.handleSize, equals(8.0));
        expect(theme.color, equals(Colors.white));
        expect(theme.borderColor, equals(Colors.blue));
        expect(theme.borderWidth, equals(1.0));
        expect(theme.snapDistance, equals(4.0));
      });

      test('dark theme has correct properties', () {
        const theme = ResizerTheme.dark;

        expect(theme.handleSize, equals(8.0));
        expect(theme.color, equals(const Color(0xFF1E1E1E)));
        expect(theme.borderColor, equals(const Color(0xFF64B5F6)));
        expect(theme.borderWidth, equals(1.0));
        expect(theme.snapDistance, equals(4.0));
      });

      test('light and dark themes have same handleSize', () {
        expect(
          ResizerTheme.light.handleSize,
          equals(ResizerTheme.dark.handleSize),
        );
      });

      test('light and dark themes have same snapDistance', () {
        expect(
          ResizerTheme.light.snapDistance,
          equals(ResizerTheme.dark.snapDistance),
        );
      });
    });

    group('copyWith', () {
      test('returns new instance with updated handleSize', () {
        const original = ResizerTheme.light;
        final updated = original.copyWith(handleSize: 12.0);

        expect(updated.handleSize, equals(12.0));
        expect(updated.color, equals(original.color));
      });

      test('returns new instance with updated color', () {
        const original = ResizerTheme.light;
        final updated = original.copyWith(color: Colors.grey);

        expect(updated.color, equals(Colors.grey));
      });

      test('returns new instance with updated borderColor', () {
        const original = ResizerTheme.light;
        final updated = original.copyWith(borderColor: Colors.green);

        expect(updated.borderColor, equals(Colors.green));
      });

      test('returns new instance with updated snapDistance', () {
        const original = ResizerTheme.light;
        final updated = original.copyWith(snapDistance: 8.0);

        expect(updated.snapDistance, equals(8.0));
      });

      test('preserves all properties when no arguments provided', () {
        const original = ResizerTheme.light;
        final updated = original.copyWith();

        expect(updated.handleSize, equals(original.handleSize));
        expect(updated.color, equals(original.color));
        expect(updated.borderColor, equals(original.borderColor));
        expect(updated.borderWidth, equals(original.borderWidth));
        expect(updated.snapDistance, equals(original.snapDistance));
      });
    });
  });

  group('MinimapTheme', () {
    group('construction', () {
      test('can be constructed with default values', () {
        const theme = MinimapTheme();

        expect(theme.backgroundColor, equals(const Color(0xFFF5F5F5)));
        expect(theme.nodeColor, equals(const Color(0xFF1976D2)));
        expect(theme.viewportColor, equals(const Color(0xFF1976D2)));
        expect(theme.viewportFillOpacity, equals(0.1));
        expect(theme.viewportBorderOpacity, equals(0.4));
        expect(theme.borderColor, equals(const Color(0xFFBDBDBD)));
        expect(theme.borderWidth, equals(1.0));
        expect(theme.borderRadius, equals(4.0));
        expect(theme.padding, equals(const EdgeInsets.all(4.0)));
        expect(theme.showViewport, isTrue);
        expect(theme.nodeBorderRadius, equals(2.0));
      });

      test('can be constructed with custom values', () {
        const theme = MinimapTheme(
          backgroundColor: Colors.black,
          nodeColor: Colors.white,
          viewportColor: Colors.red,
          viewportFillOpacity: 0.2,
          viewportBorderOpacity: 0.5,
          borderColor: Colors.grey,
          borderWidth: 2.0,
          borderRadius: 8.0,
          padding: EdgeInsets.all(8.0),
          showViewport: false,
          nodeBorderRadius: 4.0,
        );

        expect(theme.backgroundColor, equals(Colors.black));
        expect(theme.nodeColor, equals(Colors.white));
        expect(theme.viewportColor, equals(Colors.red));
        expect(theme.viewportFillOpacity, equals(0.2));
        expect(theme.viewportBorderOpacity, equals(0.5));
        expect(theme.borderColor, equals(Colors.grey));
        expect(theme.borderWidth, equals(2.0));
        expect(theme.borderRadius, equals(8.0));
        expect(theme.padding, equals(const EdgeInsets.all(8.0)));
        expect(theme.showViewport, isFalse);
        expect(theme.nodeBorderRadius, equals(4.0));
      });
    });

    group('predefined themes', () {
      test('light theme has correct properties', () {
        const theme = MinimapTheme.light;

        expect(theme.backgroundColor, equals(const Color(0xFFF5F5F5)));
        expect(theme.nodeColor, equals(const Color(0xFF1976D2)));
        expect(theme.viewportColor, equals(const Color(0xFF1976D2)));
        expect(theme.borderColor, equals(const Color(0xFFBDBDBD)));
      });

      test('dark theme has correct properties', () {
        const theme = MinimapTheme.dark;

        expect(theme.backgroundColor, equals(const Color(0xFF2D2D2D)));
        expect(theme.nodeColor, equals(const Color(0xFF64B5F6)));
        expect(theme.viewportColor, equals(const Color(0xFF64B5F6)));
        expect(theme.borderColor, equals(const Color(0xFF424242)));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated backgroundColor', () {
        const original = MinimapTheme.light;
        final updated = original.copyWith(backgroundColor: Colors.grey);

        expect(updated.backgroundColor, equals(Colors.grey));
        expect(updated.nodeColor, equals(original.nodeColor));
      });

      test('returns new instance with updated nodeColor', () {
        const original = MinimapTheme.light;
        final updated = original.copyWith(nodeColor: Colors.green);

        expect(updated.nodeColor, equals(Colors.green));
      });

      test('returns new instance with updated viewportColor', () {
        const original = MinimapTheme.light;
        final updated = original.copyWith(viewportColor: Colors.orange);

        expect(updated.viewportColor, equals(Colors.orange));
      });

      test('returns new instance with updated viewportFillOpacity', () {
        const original = MinimapTheme.light;
        final updated = original.copyWith(viewportFillOpacity: 0.3);

        expect(updated.viewportFillOpacity, equals(0.3));
      });

      test('returns new instance with updated showViewport', () {
        const original = MinimapTheme.light;
        final updated = original.copyWith(showViewport: false);

        expect(updated.showViewport, isFalse);
      });

      test('returns new instance with updated nodeBorderRadius', () {
        const original = MinimapTheme.light;
        final updated = original.copyWith(nodeBorderRadius: 6.0);

        expect(updated.nodeBorderRadius, equals(6.0));
      });

      test('preserves all properties when no arguments provided', () {
        const original = MinimapTheme.light;
        final updated = original.copyWith();

        expect(updated.backgroundColor, equals(original.backgroundColor));
        expect(updated.nodeColor, equals(original.nodeColor));
        expect(updated.viewportColor, equals(original.viewportColor));
        expect(
          updated.viewportFillOpacity,
          equals(original.viewportFillOpacity),
        );
        expect(
          updated.viewportBorderOpacity,
          equals(original.viewportBorderOpacity),
        );
        expect(updated.borderColor, equals(original.borderColor));
        expect(updated.borderWidth, equals(original.borderWidth));
        expect(updated.borderRadius, equals(original.borderRadius));
        expect(updated.padding, equals(original.padding));
        expect(updated.showViewport, equals(original.showViewport));
        expect(updated.nodeBorderRadius, equals(original.nodeBorderRadius));
      });
    });
  });

  group('GridTheme', () {
    group('construction', () {
      test('can be constructed with all required parameters', () {
        const theme = GridTheme(
          color: Colors.grey,
          size: 25.0,
          thickness: 1.5,
          style: GridStyles.lines,
        );

        expect(theme.color, equals(Colors.grey));
        expect(theme.size, equals(25.0));
        expect(theme.thickness, equals(1.5));
        expect(theme.style, equals(GridStyles.lines));
      });
    });

    group('predefined themes', () {
      test('light theme has correct properties', () {
        const theme = GridTheme.light;

        expect(theme.color, equals(const Color(0xFFC8C8C8)));
        expect(theme.size, equals(20.0));
        expect(theme.thickness, equals(1.0));
        expect(theme.style, equals(GridStyles.dots));
      });

      test('dark theme has correct properties', () {
        const theme = GridTheme.dark;

        expect(theme.color, equals(const Color(0xFF707070)));
        expect(theme.size, equals(20.0));
        expect(theme.thickness, equals(1.0));
        expect(theme.style, equals(GridStyles.dots));
      });

      test('light and dark themes have same size and thickness', () {
        expect(GridTheme.light.size, equals(GridTheme.dark.size));
        expect(GridTheme.light.thickness, equals(GridTheme.dark.thickness));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated color', () {
        const original = GridTheme.light;
        final updated = original.copyWith(color: Colors.blue);

        expect(updated.color, equals(Colors.blue));
        expect(updated.size, equals(original.size));
      });

      test('returns new instance with updated size', () {
        const original = GridTheme.light;
        final updated = original.copyWith(size: 30.0);

        expect(updated.size, equals(30.0));
      });

      test('returns new instance with updated thickness', () {
        const original = GridTheme.light;
        final updated = original.copyWith(thickness: 2.0);

        expect(updated.thickness, equals(2.0));
      });

      test('returns new instance with updated style', () {
        const original = GridTheme.light;
        final updated = original.copyWith(style: GridStyles.lines);

        expect(updated.style, equals(GridStyles.lines));
      });

      test('preserves all properties when no arguments provided', () {
        const original = GridTheme.light;
        final updated = original.copyWith();

        expect(updated.color, equals(original.color));
        expect(updated.size, equals(original.size));
        expect(updated.thickness, equals(original.thickness));
        expect(updated.style, equals(original.style));
      });
    });
  });

  group('GridStyles', () {
    test('provides lines style', () {
      expect(GridStyles.lines, isNotNull);
    });

    test('provides dots style', () {
      expect(GridStyles.dots, isNotNull);
    });

    test('provides cross style', () {
      expect(GridStyles.cross, isNotNull);
    });

    test('provides hierarchical style', () {
      expect(GridStyles.hierarchical, isNotNull);
    });

    test('provides none style', () {
      expect(GridStyles.none, isNotNull);
    });
  });

  group('ConnectionTheme', () {
    group('construction', () {
      test('can be constructed with all required parameters', () {
        const theme = ConnectionTheme(
          style: ConnectionStyles.bezier,
          color: Colors.grey,
          selectedColor: Colors.blue,
          highlightColor: Colors.lightBlue,
          highlightBorderColor: Colors.blueAccent,
          strokeWidth: 2.0,
          selectedStrokeWidth: 3.0,
          startPoint: ConnectionEndPoint.none,
          endPoint: ConnectionEndPoint.triangle,
          endpointColor: Colors.grey,
          endpointBorderColor: Colors.black,
          endpointBorderWidth: 1.0,
          bezierCurvature: 0.5,
          cornerRadius: 4.0,
          portExtension: 20.0,
          backEdgeGap: 20.0,
          hitTolerance: 8.0,
        );

        expect(theme.style, equals(ConnectionStyles.bezier));
        expect(theme.color, equals(Colors.grey));
        expect(theme.selectedColor, equals(Colors.blue));
        expect(theme.highlightColor, equals(Colors.lightBlue));
        expect(theme.strokeWidth, equals(2.0));
        expect(theme.selectedStrokeWidth, equals(3.0));
        expect(theme.startPoint, equals(ConnectionEndPoint.none));
        expect(theme.endPoint, equals(ConnectionEndPoint.triangle));
        expect(theme.bezierCurvature, equals(0.5));
        expect(theme.cornerRadius, equals(4.0));
        expect(theme.portExtension, equals(20.0));
        expect(theme.hitTolerance, equals(8.0));
      });

      test('has default startGap and endGap of 0', () {
        const theme = ConnectionTheme(
          style: ConnectionStyles.bezier,
          color: Colors.grey,
          selectedColor: Colors.blue,
          highlightColor: Colors.lightBlue,
          highlightBorderColor: Colors.blueAccent,
          strokeWidth: 2.0,
          selectedStrokeWidth: 3.0,
          startPoint: ConnectionEndPoint.none,
          endPoint: ConnectionEndPoint.triangle,
          endpointColor: Colors.grey,
          endpointBorderColor: Colors.black,
          endpointBorderWidth: 1.0,
          bezierCurvature: 0.5,
          cornerRadius: 4.0,
          portExtension: 20.0,
          backEdgeGap: 20.0,
          hitTolerance: 8.0,
        );

        expect(theme.startGap, equals(0.0));
        expect(theme.endGap, equals(0.0));
      });

      test('dashPattern is optional and defaults to null', () {
        const theme = ConnectionTheme(
          style: ConnectionStyles.bezier,
          color: Colors.grey,
          selectedColor: Colors.blue,
          highlightColor: Colors.lightBlue,
          highlightBorderColor: Colors.blueAccent,
          strokeWidth: 2.0,
          selectedStrokeWidth: 3.0,
          startPoint: ConnectionEndPoint.none,
          endPoint: ConnectionEndPoint.triangle,
          endpointColor: Colors.grey,
          endpointBorderColor: Colors.black,
          endpointBorderWidth: 1.0,
          bezierCurvature: 0.5,
          cornerRadius: 4.0,
          portExtension: 20.0,
          backEdgeGap: 20.0,
          hitTolerance: 8.0,
        );

        expect(theme.dashPattern, isNull);
      });

      test('animationEffect is optional and defaults to null', () {
        const theme = ConnectionTheme(
          style: ConnectionStyles.bezier,
          color: Colors.grey,
          selectedColor: Colors.blue,
          highlightColor: Colors.lightBlue,
          highlightBorderColor: Colors.blueAccent,
          strokeWidth: 2.0,
          selectedStrokeWidth: 3.0,
          startPoint: ConnectionEndPoint.none,
          endPoint: ConnectionEndPoint.triangle,
          endpointColor: Colors.grey,
          endpointBorderColor: Colors.black,
          endpointBorderWidth: 1.0,
          bezierCurvature: 0.5,
          cornerRadius: 4.0,
          portExtension: 20.0,
          backEdgeGap: 20.0,
          hitTolerance: 8.0,
        );

        expect(theme.animationEffect, isNull);
      });
    });

    group('predefined themes', () {
      test('light theme has correct properties', () {
        const theme = ConnectionTheme.light;

        expect(theme.style, equals(ConnectionStyles.smoothstep));
        expect(theme.color, equals(const Color(0xFF666666)));
        expect(theme.selectedColor, equals(const Color(0xFF2196F3)));
        expect(theme.highlightColor, equals(const Color(0xFF42A5F5)));
        expect(theme.strokeWidth, equals(2.0));
        expect(theme.selectedStrokeWidth, equals(3.0));
        expect(theme.startPoint, equals(ConnectionEndPoint.none));
        expect(theme.endPoint, equals(ConnectionEndPoint.capsuleHalf));
        expect(theme.bezierCurvature, equals(0.5));
        expect(theme.cornerRadius, equals(4.0));
        expect(theme.portExtension, equals(20.0));
        expect(theme.hitTolerance, equals(8.0));
      });

      test('dark theme has correct properties', () {
        const theme = ConnectionTheme.dark;

        expect(theme.style, equals(ConnectionStyles.smoothstep));
        expect(theme.color, equals(const Color(0xFF999999)));
        expect(theme.selectedColor, equals(const Color(0xFF64B5F6)));
        expect(theme.highlightColor, equals(const Color(0xFF90CAF9)));
        expect(theme.strokeWidth, equals(2.0));
        expect(theme.selectedStrokeWidth, equals(3.0));
        expect(theme.startPoint, equals(ConnectionEndPoint.none));
        expect(theme.endPoint, equals(ConnectionEndPoint.capsuleHalf));
      });

      test('light and dark themes have same geometry parameters', () {
        expect(
          ConnectionTheme.light.bezierCurvature,
          equals(ConnectionTheme.dark.bezierCurvature),
        );
        expect(
          ConnectionTheme.light.cornerRadius,
          equals(ConnectionTheme.dark.cornerRadius),
        );
        expect(
          ConnectionTheme.light.portExtension,
          equals(ConnectionTheme.dark.portExtension),
        );
        expect(
          ConnectionTheme.light.hitTolerance,
          equals(ConnectionTheme.dark.hitTolerance),
        );
      });
    });

    group('copyWith', () {
      test('returns new instance with updated color', () {
        const original = ConnectionTheme.light;
        final updated = original.copyWith(color: Colors.red);

        expect(updated.color, equals(Colors.red));
        expect(updated.selectedColor, equals(original.selectedColor));
      });

      test('returns new instance with updated style', () {
        const original = ConnectionTheme.light;
        final updated = original.copyWith(style: ConnectionStyles.bezier);

        expect(updated.style, equals(ConnectionStyles.bezier));
      });

      test('returns new instance with updated dashPattern', () {
        const original = ConnectionTheme.light;
        final updated = original.copyWith(dashPattern: [5.0, 3.0]);

        expect(updated.dashPattern, equals([5.0, 3.0]));
      });

      test('returns new instance with updated startPoint', () {
        const original = ConnectionTheme.light;
        final updated = original.copyWith(
          startPoint: ConnectionEndPoint.circle,
        );

        expect(updated.startPoint, equals(ConnectionEndPoint.circle));
      });

      test('returns new instance with updated endPoint', () {
        const original = ConnectionTheme.light;
        final updated = original.copyWith(
          endPoint: ConnectionEndPoint.triangle,
        );

        expect(updated.endPoint, equals(ConnectionEndPoint.triangle));
      });

      test('returns new instance with updated bezierCurvature', () {
        const original = ConnectionTheme.light;
        final updated = original.copyWith(bezierCurvature: 0.8);

        expect(updated.bezierCurvature, equals(0.8));
      });

      test('returns new instance with updated hitTolerance', () {
        const original = ConnectionTheme.light;
        final updated = original.copyWith(hitTolerance: 12.0);

        expect(updated.hitTolerance, equals(12.0));
      });

      test('returns new instance with updated startGap and endGap', () {
        const original = ConnectionTheme.light;
        final updated = original.copyWith(startGap: 5.0, endGap: 10.0);

        expect(updated.startGap, equals(5.0));
        expect(updated.endGap, equals(10.0));
      });

      test('preserves most properties when no arguments provided', () {
        const original = ConnectionTheme.light;
        final updated = original.copyWith();

        expect(updated.style, equals(original.style));
        expect(updated.color, equals(original.color));
        expect(updated.selectedColor, equals(original.selectedColor));
        expect(updated.strokeWidth, equals(original.strokeWidth));
        expect(updated.startPoint, equals(original.startPoint));
        expect(updated.endPoint, equals(original.endPoint));
        expect(updated.bezierCurvature, equals(original.bezierCurvature));
        expect(updated.cornerRadius, equals(original.cornerRadius));
        // Note: dashPattern and animationEffect are set to null by copyWith
        expect(updated.dashPattern, isNull);
        expect(updated.animationEffect, isNull);
      });
    });
  });

  group('ConnectionEndPoint', () {
    group('predefined endpoints', () {
      test('none endpoint has zero size', () {
        const endpoint = ConnectionEndPoint.none;

        expect(endpoint.size, equals(Size.zero));
        expect(endpoint.shape, equals(MarkerShapes.none));
      });

      test('capsuleHalf endpoint has correct properties', () {
        const endpoint = ConnectionEndPoint.capsuleHalf;

        expect(endpoint.size, equals(const Size.square(5.0)));
        expect(endpoint.shape, equals(MarkerShapes.capsuleHalf));
      });

      test('circle endpoint has correct properties', () {
        const endpoint = ConnectionEndPoint.circle;

        expect(endpoint.size, equals(const Size.square(5.0)));
        expect(endpoint.shape, equals(MarkerShapes.circle));
      });

      test('rectangle endpoint has correct properties', () {
        const endpoint = ConnectionEndPoint.rectangle;

        expect(endpoint.size, equals(const Size.square(5.0)));
        expect(endpoint.shape, equals(MarkerShapes.rectangle));
      });

      test('diamond endpoint has correct properties', () {
        const endpoint = ConnectionEndPoint.diamond;

        expect(endpoint.size, equals(const Size.square(5.0)));
        expect(endpoint.shape, equals(MarkerShapes.diamond));
      });

      test('triangle endpoint has correct properties', () {
        const endpoint = ConnectionEndPoint.triangle;

        expect(endpoint.size, equals(const Size.square(5.0)));
        expect(endpoint.shape, equals(MarkerShapes.triangle));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated shape', () {
        const original = ConnectionEndPoint.circle;
        final updated = original.copyWith(shape: MarkerShapes.triangle);

        expect(updated.shape, equals(MarkerShapes.triangle));
        expect(updated.size, equals(original.size));
      });

      test('returns new instance with updated size', () {
        const original = ConnectionEndPoint.circle;
        final updated = original.copyWith(size: const Size.square(10.0));

        expect(updated.size, equals(const Size.square(10.0)));
      });

      test('returns new instance with updated color', () {
        const original = ConnectionEndPoint.circle;
        final updated = original.copyWith(color: Colors.red);

        expect(updated.color, equals(Colors.red));
      });
    });

    group('equality', () {
      test('identical endpoints are equal', () {
        const a = ConnectionEndPoint.circle;
        const b = ConnectionEndPoint.circle;

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different endpoints are not equal', () {
        const a = ConnectionEndPoint.circle;
        const b = ConnectionEndPoint.triangle;

        expect(a, isNot(equals(b)));
      });
    });
  });
}
