/// Comprehensive tests for PortTheme, NodeTheme, and LabelTheme.
///
/// Tests all theme classes through the public API.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('PortTheme', () {
    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(PortTheme.light, isNotNull);
      });

      test('dark theme is available', () {
        expect(PortTheme.dark, isNotNull);
      });

      test('light theme has correct size', () {
        expect(PortTheme.light.size, equals(const Size(9, 9)));
      });

      test('dark theme has correct size', () {
        expect(PortTheme.dark.size, equals(const Size(9, 9)));
      });

      test('light and dark themes have different colors', () {
        expect(PortTheme.light.color, isNot(equals(PortTheme.dark.color)));
      });

      test('light theme has label text style', () {
        expect(PortTheme.light.labelTextStyle, isNotNull);
        expect(PortTheme.light.labelTextStyle!.fontSize, equals(10.0));
      });

      test('dark theme has label text style', () {
        expect(PortTheme.dark.labelTextStyle, isNotNull);
        expect(PortTheme.dark.labelTextStyle!.fontSize, equals(10.0));
      });

      test('light theme has default shape', () {
        expect(PortTheme.light.shape, same(MarkerShapes.capsuleHalf));
      });

      test('dark theme has default shape', () {
        expect(PortTheme.dark.shape, same(MarkerShapes.capsuleHalf));
      });
    });

    group('Construction', () {
      test('creates with all required properties', () {
        final theme = PortTheme(
          size: const Size(12, 12),
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

      test('creates with optional labelTextStyle', () {
        final textStyle = TextStyle(fontSize: 14.0, color: Colors.red);
        final theme = PortTheme(
          size: const Size(10, 10),
          color: Colors.grey,
          connectedColor: Colors.green,
          highlightColor: Colors.lightGreen,
          highlightBorderColor: Colors.black,
          borderColor: Colors.white,
          borderWidth: 1.0,
          labelTextStyle: textStyle,
        );

        expect(theme.labelTextStyle, equals(textStyle));
      });

      test('creates with custom labelOffset', () {
        final theme = PortTheme(
          size: const Size(10, 10),
          color: Colors.grey,
          connectedColor: Colors.green,
          highlightColor: Colors.lightGreen,
          highlightBorderColor: Colors.black,
          borderColor: Colors.white,
          borderWidth: 1.0,
          labelOffset: 12.0,
        );

        expect(theme.labelOffset, equals(12.0));
      });

      test('default labelOffset is 4.0', () {
        final theme = PortTheme(
          size: const Size(10, 10),
          color: Colors.grey,
          connectedColor: Colors.green,
          highlightColor: Colors.lightGreen,
          highlightBorderColor: Colors.black,
          borderColor: Colors.white,
          borderWidth: 1.0,
        );

        expect(theme.labelOffset, equals(4.0));
      });

      test('creates with custom shape', () {
        final theme = PortTheme(
          size: const Size(10, 10),
          color: Colors.grey,
          connectedColor: Colors.green,
          highlightColor: Colors.lightGreen,
          highlightBorderColor: Colors.black,
          borderColor: Colors.white,
          borderWidth: 1.0,
          shape: MarkerShapes.circle,
        );

        expect(theme.shape, same(MarkerShapes.circle));
      });
    });

    group('copyWith', () {
      test('copies with new size', () {
        final original = PortTheme.light;
        final copied = original.copyWith(size: const Size(16, 16));

        expect(copied.size, equals(const Size(16, 16)));
        expect(copied.color, equals(original.color));
      });

      test('copies with new color', () {
        final original = PortTheme.light;
        final copied = original.copyWith(color: Colors.purple);

        expect(copied.color, equals(Colors.purple));
        expect(copied.size, equals(original.size));
      });

      test('copies with new connectedColor', () {
        final original = PortTheme.light;
        final copied = original.copyWith(connectedColor: Colors.orange);

        expect(copied.connectedColor, equals(Colors.orange));
      });

      test('copies with new highlightColor', () {
        final original = PortTheme.light;
        final copied = original.copyWith(highlightColor: Colors.yellow);

        expect(copied.highlightColor, equals(Colors.yellow));
      });

      test('copies with new borderWidth', () {
        final original = PortTheme.light;
        final copied = original.copyWith(borderWidth: 3.0);

        expect(copied.borderWidth, equals(3.0));
      });

      test('copies with new shape', () {
        final original = PortTheme.light;
        final copied = original.copyWith(shape: MarkerShapes.diamond);

        expect(copied.shape, same(MarkerShapes.diamond));
      });

      test('copies with new labelOffset', () {
        final original = PortTheme.light;
        final copied = original.copyWith(labelOffset: 20.0);

        expect(copied.labelOffset, equals(20.0));
      });

      test('preserves all values when no parameters provided', () {
        final original = PortTheme.light;
        final copied = original.copyWith();

        expect(copied.size, equals(original.size));
        expect(copied.color, equals(original.color));
        expect(copied.connectedColor, equals(original.connectedColor));
        expect(copied.highlightColor, equals(original.highlightColor));
        expect(copied.borderColor, equals(original.borderColor));
        expect(copied.borderWidth, equals(original.borderWidth));
        expect(copied.shape, same(original.shape));
        expect(copied.labelOffset, equals(original.labelOffset));
      });
    });

    group('resolveSize', () {
      test('returns port size when port has custom size', () {
        final theme = PortTheme.light;
        final port = Port(
          id: 'port1',
          name: 'Output',
          type: PortType.output,
          size: const Size(20, 20),
        );

        expect(theme.resolveSize(port), equals(const Size(20, 20)));
      });

      test('returns theme size when port has no custom size', () {
        final theme = PortTheme.light;
        final port = Port(id: 'port1', name: 'Output', type: PortType.output);

        expect(theme.resolveSize(port), equals(theme.size));
      });
    });
  });

  group('NodeTheme', () {
    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(NodeTheme.light, isNotNull);
      });

      test('dark theme is available', () {
        expect(NodeTheme.dark, isNotNull);
      });

      test('light theme has white background', () {
        expect(NodeTheme.light.backgroundColor, equals(Colors.white));
      });

      test('dark theme has dark background', () {
        expect(NodeTheme.dark.backgroundColor, equals(const Color(0xFF2D2D2D)));
      });

      test('light and dark themes have different backgrounds', () {
        expect(
          NodeTheme.light.backgroundColor,
          isNot(equals(NodeTheme.dark.backgroundColor)),
        );
      });

      test('light theme has correct border radius', () {
        expect(
          NodeTheme.light.borderRadius,
          equals(const BorderRadius.all(Radius.circular(8.0))),
        );
      });

      test('themes have title and content styles', () {
        expect(NodeTheme.light.titleStyle, isNotNull);
        expect(NodeTheme.light.contentStyle, isNotNull);
        expect(NodeTheme.dark.titleStyle, isNotNull);
        expect(NodeTheme.dark.contentStyle, isNotNull);
      });
    });

    group('Construction', () {
      test('creates with all required properties', () {
        final theme = NodeTheme(
          backgroundColor: Colors.white,
          selectedBackgroundColor: Colors.grey.shade100,
          highlightBackgroundColor: Colors.blue.shade50,
          borderColor: Colors.grey,
          selectedBorderColor: Colors.blue,
          highlightBorderColor: Colors.lightBlue,
          borderWidth: 1.0,
          selectedBorderWidth: 2.0,
          borderRadius: BorderRadius.circular(4.0),
          titleStyle: const TextStyle(fontSize: 16.0),
          contentStyle: const TextStyle(fontSize: 12.0),
        );

        expect(theme.backgroundColor, equals(Colors.white));
        expect(theme.selectedBackgroundColor, equals(Colors.grey.shade100));
        expect(theme.highlightBackgroundColor, equals(Colors.blue.shade50));
        expect(theme.borderColor, equals(Colors.grey));
        expect(theme.selectedBorderColor, equals(Colors.blue));
        expect(theme.highlightBorderColor, equals(Colors.lightBlue));
        expect(theme.borderWidth, equals(1.0));
        expect(theme.selectedBorderWidth, equals(2.0));
      });
    });

    group('copyWith', () {
      test('copies with new backgroundColor', () {
        final original = NodeTheme.light;
        final copied = original.copyWith(backgroundColor: Colors.yellow);

        expect(copied.backgroundColor, equals(Colors.yellow));
        expect(copied.borderColor, equals(original.borderColor));
      });

      test('copies with new selectedBackgroundColor', () {
        final original = NodeTheme.light;
        final copied = original.copyWith(
          selectedBackgroundColor: Colors.lightBlue,
        );

        expect(copied.selectedBackgroundColor, equals(Colors.lightBlue));
      });

      test('copies with new borderColor', () {
        final original = NodeTheme.light;
        final copied = original.copyWith(borderColor: Colors.red);

        expect(copied.borderColor, equals(Colors.red));
      });

      test('copies with new selectedBorderColor', () {
        final original = NodeTheme.light;
        final copied = original.copyWith(selectedBorderColor: Colors.green);

        expect(copied.selectedBorderColor, equals(Colors.green));
      });

      test('copies with new borderWidth', () {
        final original = NodeTheme.light;
        final copied = original.copyWith(borderWidth: 3.0);

        expect(copied.borderWidth, equals(3.0));
      });

      test('copies with new selectedBorderWidth', () {
        final original = NodeTheme.light;
        final copied = original.copyWith(selectedBorderWidth: 4.0);

        expect(copied.selectedBorderWidth, equals(4.0));
      });

      test('copies with new borderRadius', () {
        final original = NodeTheme.light;
        final newRadius = BorderRadius.circular(16.0);
        final copied = original.copyWith(borderRadius: newRadius);

        expect(copied.borderRadius, equals(newRadius));
      });

      test('copies with new titleStyle', () {
        final original = NodeTheme.light;
        final newStyle = const TextStyle(fontSize: 20.0, color: Colors.purple);
        final copied = original.copyWith(titleStyle: newStyle);

        expect(copied.titleStyle, equals(newStyle));
      });

      test('copies with new contentStyle', () {
        final original = NodeTheme.light;
        final newStyle = const TextStyle(fontSize: 14.0, color: Colors.teal);
        final copied = original.copyWith(contentStyle: newStyle);

        expect(copied.contentStyle, equals(newStyle));
      });

      test('preserves all values when no parameters provided', () {
        final original = NodeTheme.light;
        final copied = original.copyWith();

        expect(copied.backgroundColor, equals(original.backgroundColor));
        expect(
          copied.selectedBackgroundColor,
          equals(original.selectedBackgroundColor),
        );
        expect(copied.borderColor, equals(original.borderColor));
        expect(
          copied.selectedBorderColor,
          equals(original.selectedBorderColor),
        );
        expect(copied.borderWidth, equals(original.borderWidth));
        expect(
          copied.selectedBorderWidth,
          equals(original.selectedBorderWidth),
        );
        expect(copied.borderRadius, equals(original.borderRadius));
        expect(copied.titleStyle, equals(original.titleStyle));
        expect(copied.contentStyle, equals(original.contentStyle));
      });
    });
  });

  group('LabelTheme', () {
    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(LabelTheme.light, isNotNull);
      });

      test('dark theme is available', () {
        expect(LabelTheme.dark, isNotNull);
      });

      test('light theme has correct text style', () {
        expect(LabelTheme.light.textStyle.fontSize, equals(12.0));
        expect(LabelTheme.light.textStyle.fontWeight, equals(FontWeight.w500));
      });

      test('dark theme has correct text style', () {
        expect(LabelTheme.dark.textStyle.fontSize, equals(12.0));
        expect(LabelTheme.dark.textStyle.fontWeight, equals(FontWeight.w500));
      });

      test('light and dark themes have different text colors', () {
        expect(
          LabelTheme.light.textStyle.color,
          isNot(equals(LabelTheme.dark.textStyle.color)),
        );
      });

      test('themes have background colors', () {
        expect(LabelTheme.light.backgroundColor, isNotNull);
        expect(LabelTheme.dark.backgroundColor, isNotNull);
      });

      test('themes have borders', () {
        expect(LabelTheme.light.border, isNotNull);
        expect(LabelTheme.dark.border, isNotNull);
      });
    });

    group('Construction', () {
      test('creates with default values', () {
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

      test('creates with custom text style', () {
        const textStyle = TextStyle(fontSize: 16.0, color: Colors.red);
        const theme = LabelTheme(textStyle: textStyle);

        expect(theme.textStyle, equals(textStyle));
      });

      test('creates with custom background color', () {
        const theme = LabelTheme(backgroundColor: Colors.yellow);

        expect(theme.backgroundColor, equals(Colors.yellow));
      });

      test('creates with custom border', () {
        final border = Border.all(color: Colors.blue, width: 2.0);
        final theme = LabelTheme(border: border);

        expect(theme.border, equals(border));
      });

      test('creates with custom border radius', () {
        const borderRadius = BorderRadius.all(Radius.circular(8.0));
        const theme = LabelTheme(borderRadius: borderRadius);

        expect(theme.borderRadius, equals(borderRadius));
      });

      test('creates with custom padding', () {
        const padding = EdgeInsets.all(12.0);
        const theme = LabelTheme(padding: padding);

        expect(theme.padding, equals(padding));
      });

      test('creates with custom maxWidth', () {
        const theme = LabelTheme(maxWidth: 200.0);

        expect(theme.maxWidth, equals(200.0));
      });

      test('creates with custom maxLines', () {
        const theme = LabelTheme(maxLines: 3);

        expect(theme.maxLines, equals(3));
      });

      test('creates with custom offset', () {
        const theme = LabelTheme(offset: 10.0);

        expect(theme.offset, equals(10.0));
      });

      test('creates with custom labelGap', () {
        const theme = LabelTheme(labelGap: 16.0);

        expect(theme.labelGap, equals(16.0));
      });
    });

    group('copyWith', () {
      test('copies with new textStyle', () {
        const original = LabelTheme.light;
        const newStyle = TextStyle(fontSize: 18.0, color: Colors.purple);
        final copied = original.copyWith(textStyle: newStyle);

        expect(copied.textStyle, equals(newStyle));
        expect(copied.backgroundColor, equals(original.backgroundColor));
      });

      test('copies with new backgroundColor', () {
        const original = LabelTheme.light;
        final copied = original.copyWith(backgroundColor: Colors.pink);

        expect(copied.backgroundColor, equals(Colors.pink));
      });

      test('copies with new border', () {
        const original = LabelTheme.light;
        final newBorder = Border.all(color: Colors.red, width: 3.0);
        final copied = original.copyWith(border: newBorder);

        expect(copied.border, equals(newBorder));
      });

      test('copies with new borderRadius', () {
        const original = LabelTheme.light;
        const newRadius = BorderRadius.all(Radius.circular(12.0));
        final copied = original.copyWith(borderRadius: newRadius);

        expect(copied.borderRadius, equals(newRadius));
      });

      test('copies with new padding', () {
        const original = LabelTheme.light;
        const newPadding = EdgeInsets.all(16.0);
        final copied = original.copyWith(padding: newPadding);

        expect(copied.padding, equals(newPadding));
      });

      test('copies with new maxWidth', () {
        const original = LabelTheme.light;
        final copied = original.copyWith(maxWidth: 300.0);

        expect(copied.maxWidth, equals(300.0));
      });

      test('copies with new maxLines', () {
        const original = LabelTheme.light;
        final copied = original.copyWith(maxLines: 5);

        expect(copied.maxLines, equals(5));
      });

      test('copies with new offset', () {
        const original = LabelTheme.light;
        final copied = original.copyWith(offset: 15.0);

        expect(copied.offset, equals(15.0));
      });

      test('copies with new labelGap', () {
        const original = LabelTheme.light;
        final copied = original.copyWith(labelGap: 20.0);

        expect(copied.labelGap, equals(20.0));
      });

      test('preserves all values when no parameters provided', () {
        const original = LabelTheme.light;
        final copied = original.copyWith();

        expect(copied.textStyle, equals(original.textStyle));
        expect(copied.backgroundColor, equals(original.backgroundColor));
        expect(copied.border, equals(original.border));
        expect(copied.borderRadius, equals(original.borderRadius));
        expect(copied.padding, equals(original.padding));
        expect(copied.maxWidth, equals(original.maxWidth));
        expect(copied.maxLines, equals(original.maxLines));
        expect(copied.offset, equals(original.offset));
        expect(copied.labelGap, equals(original.labelGap));
      });
    });
  });
}
