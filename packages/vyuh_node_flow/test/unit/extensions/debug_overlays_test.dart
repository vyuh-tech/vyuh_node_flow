/// Unit tests for debug overlay components in vyuh_node_flow.
///
/// Tests cover:
/// - SpatialIndexDebugLayer construction and configuration
/// - SpatialIndexDebugPainter properties and shouldRepaint logic
/// - AutopanZoneDebugLayer construction and conditional rendering
/// - DebugTheme integration with painters
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
  // SpatialIndexDebugLayer - Construction
  // ===========================================================================

  group('SpatialIndexDebugLayer - Construction', () {
    testWidgets('creates widget with required parameters', (tester) async {
      final controller = createTestController();
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              SpatialIndexDebugLayer<String>(
                controller: controller,
                transformationController: transformationController,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(SpatialIndexDebugLayer<String>), findsOneWidget);

      controller.dispose();
      transformationController.dispose();
    });

    testWidgets('widget is a StatelessWidget', (tester) async {
      final controller = createTestController();
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              SpatialIndexDebugLayer<String>(
                controller: controller,
                transformationController: transformationController,
              ),
            ],
          ),
        ),
      );

      final widget = tester.widget<SpatialIndexDebugLayer<String>>(
        find.byType(SpatialIndexDebugLayer<String>),
      );
      expect(widget, isA<StatelessWidget>());

      controller.dispose();
      transformationController.dispose();
    });

    test('stores controller reference', () {
      final controller = createTestController();
      final transformationController = TransformationController();

      final layer = SpatialIndexDebugLayer<String>(
        controller: controller,
        transformationController: transformationController,
      );

      expect(layer.controller, same(controller));

      controller.dispose();
      transformationController.dispose();
    });

    test('stores transformation controller reference', () {
      final controller = createTestController();
      final transformationController = TransformationController();

      final layer = SpatialIndexDebugLayer<String>(
        controller: controller,
        transformationController: transformationController,
      );

      expect(layer.transformationController, same(transformationController));

      controller.dispose();
      transformationController.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugLayer - Widget Structure
  // ===========================================================================

  group('SpatialIndexDebugLayer - Widget Structure', () {
    testWidgets('uses Positioned.fill for layout', (tester) async {
      final controller = createTestController();
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                SpatialIndexDebugLayer<String>(
                  controller: controller,
                  transformationController: transformationController,
                ),
              ],
            ),
          ),
        ),
      );

      // Find Positioned as descendant of SpatialIndexDebugLayer
      expect(
        find.descendant(
          of: find.byType(SpatialIndexDebugLayer<String>),
          matching: find.byType(Positioned),
        ),
        findsOneWidget,
      );

      controller.dispose();
      transformationController.dispose();
    });

    testWidgets('uses IgnorePointer to prevent interaction', (tester) async {
      final controller = createTestController();
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                SpatialIndexDebugLayer<String>(
                  controller: controller,
                  transformationController: transformationController,
                ),
              ],
            ),
          ),
        ),
      );

      // Find IgnorePointer that ignores pointer events (ignoring: true)
      final ignorePointerFinder = find.descendant(
        of: find.byType(SpatialIndexDebugLayer<String>),
        matching: find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.ignoring == true,
        ),
      );
      expect(ignorePointerFinder, findsOneWidget);

      controller.dispose();
      transformationController.dispose();
    });

    testWidgets('uses RepaintBoundary for performance', (tester) async {
      final controller = createTestController();
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                SpatialIndexDebugLayer<String>(
                  controller: controller,
                  transformationController: transformationController,
                ),
              ],
            ),
          ),
        ),
      );

      // Find RepaintBoundary as descendant of SpatialIndexDebugLayer
      expect(
        find.descendant(
          of: find.byType(SpatialIndexDebugLayer<String>),
          matching: find.byType(RepaintBoundary),
        ),
        findsOneWidget,
      );

      controller.dispose();
      transformationController.dispose();
    });

    testWidgets('contains CustomPaint widget', (tester) async {
      final controller = createTestController();
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                SpatialIndexDebugLayer<String>(
                  controller: controller,
                  transformationController: transformationController,
                ),
              ],
            ),
          ),
        ),
      );

      // Find CustomPaint as descendant of SpatialIndexDebugLayer
      expect(
        find.descendant(
          of: find.byType(SpatialIndexDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      controller.dispose();
      transformationController.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Construction
  // ===========================================================================

  group('SpatialIndexDebugPainter - Construction', () {
    test('creates with required parameters', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      expect(painter.spatialIndex, same(controller.spatialIndex));
      expect(painter.viewport, same(viewport));
      expect(painter.version, equals(0));

      controller.dispose();
    });

    test('uses default theme when not provided', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      expect(painter.theme, isA<DebugTheme>());

      controller.dispose();
    });

    test('accepts custom theme', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.dark,
      );

      expect(painter.theme, equals(DebugTheme.dark));

      controller.dispose();
    });

    test('accepts null mouse position', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: null,
      );

      expect(painter.mousePositionWorld, isNull);

      controller.dispose();
    });

    test('accepts mouse position', () {
      final controller = createTestController();
      final viewport = createTestViewport();
      const mousePos = Offset(100, 200);

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: mousePos,
      );

      expect(painter.mousePositionWorld, equals(mousePos));

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Properties
  // ===========================================================================

  group('SpatialIndexDebugPainter - Properties', () {
    test('spatialIndex property returns provided index', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      expect(painter.spatialIndex, same(controller.spatialIndex));

      controller.dispose();
    });

    test('viewport property returns provided viewport', () {
      final controller = createTestController();
      final viewport = createTestViewport(x: 100, y: 200, zoom: 1.5);

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      expect(painter.viewport.x, equals(100));
      expect(painter.viewport.y, equals(200));
      expect(painter.viewport.zoom, equals(1.5));

      controller.dispose();
    });

    test('version property returns provided version', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 42,
      );

      expect(painter.version, equals(42));

      controller.dispose();
    });

    test('theme property returns provided theme', () {
      final controller = createTestController();
      final viewport = createTestViewport();
      const customTheme = DebugTheme(
        color: Color(0xFF123456),
        borderColor: Color(0xFF654321),
      );

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: customTheme,
      );

      expect(painter.theme.color, equals(const Color(0xFF123456)));
      expect(painter.theme.borderColor, equals(const Color(0xFF654321)));

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - shouldRepaint
  // ===========================================================================

  group('SpatialIndexDebugPainter - shouldRepaint', () {
    test('returns true when viewport changes', () {
      final controller = createTestController();
      final viewport1 = createTestViewport(x: 0, y: 0, zoom: 1.0);
      final viewport2 = createTestViewport(x: 100, y: 0, zoom: 1.0);

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport1,
        version: 0,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport2,
        version: 0,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when version changes', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when theme changes', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.light,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.dark,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when mouse position changes', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(0, 0),
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(100, 100),
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when mouse position becomes null', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(100, 100),
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: null,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns false when all properties are same', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.light,
        mousePositionWorld: const Offset(50, 50),
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.light,
        mousePositionWorld: const Offset(50, 50),
      );

      expect(painter2.shouldRepaint(painter1), isFalse);

      controller.dispose();
    });
  });

  // ===========================================================================
  // AutopanZoneDebugLayer - Construction
  // ===========================================================================

  group('AutopanZoneDebugLayer - Construction', () {
    testWidgets('creates widget with required parameters', (tester) async {
      final controller = createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      expect(find.byType(AutopanZoneDebugLayer<String>), findsOneWidget);

      controller.dispose();
    });

    test('stores controller reference', () {
      final controller = createTestController();

      final layer = AutopanZoneDebugLayer<String>(controller: controller);

      expect(layer.controller, same(controller));

      controller.dispose();
    });

    testWidgets('widget is a StatelessWidget', (tester) async {
      final controller = createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      final widget = tester.widget<AutopanZoneDebugLayer<String>>(
        find.byType(AutopanZoneDebugLayer<String>),
      );
      expect(widget, isA<StatelessWidget>());

      controller.dispose();
    });
  });

  // ===========================================================================
  // AutopanZoneDebugLayer - Conditional Rendering
  // ===========================================================================

  group('AutopanZoneDebugLayer - Conditional Rendering', () {
    testWidgets('returns SizedBox.shrink when debug extension is null', (
      tester,
    ) async {
      // Create controller without debug extension
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [AutoPanExtension()]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      // Should not show CustomPaint as descendant of AutopanZoneDebugLayer
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );

      controller.dispose();
    });

    testWidgets('returns SizedBox.shrink when autoPan extension is null', (
      tester,
    ) async {
      // Create controller without autoPan extension
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [DebugExtension()]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      // Should not show CustomPaint as descendant of AutopanZoneDebugLayer
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );

      controller.dispose();
    });

    testWidgets('returns SizedBox.shrink when debug mode is not autoPanZone', (
      tester,
    ) async {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            DebugExtension(mode: DebugMode.spatialIndex),
            AutoPanExtension(enabled: true),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show CustomPaint when mode is not autoPanZone
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );

      controller.dispose();
    });

    testWidgets('returns SizedBox.shrink when autoPan is disabled', (
      tester,
    ) async {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            DebugExtension(mode: DebugMode.autoPanZone),
            AutoPanExtension(enabled: false),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show CustomPaint when autoPan is disabled
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );

      controller.dispose();
    });

    testWidgets('shows CustomPaint when debug and autoPan are enabled', (
      tester,
    ) async {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            DebugExtension(mode: DebugMode.autoPanZone),
            AutoPanExtension(enabled: true),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      controller.dispose();
    });

    testWidgets('shows CustomPaint when debug mode is all', (tester) async {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            DebugExtension(mode: DebugMode.all),
            AutoPanExtension(enabled: true),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // AutopanZoneDebugLayer - Widget Structure
  // ===========================================================================

  group('AutopanZoneDebugLayer - Widget Structure', () {
    testWidgets('uses IgnorePointer to prevent interaction', (tester) async {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            DebugExtension(mode: DebugMode.autoPanZone),
            AutoPanExtension(enabled: true),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      // Find IgnorePointer as descendant of AutopanZoneDebugLayer
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // DebugTheme - Theme Integration
  // ===========================================================================

  group('DebugTheme - Properties', () {
    test('default theme has all required colors', () {
      const theme = DebugTheme();

      expect(theme.color, isA<Color>());
      expect(theme.borderColor, isA<Color>());
      expect(theme.activeColor, isA<Color>());
      expect(theme.activeBorderColor, isA<Color>());
      expect(theme.labelColor, isA<Color>());
      expect(theme.labelBackgroundColor, isA<Color>());
      expect(theme.indicatorColor, isA<Color>());
      expect(theme.segmentColors, isNotEmpty);
    });

    test('light theme is constant and accessible', () {
      const theme = DebugTheme.light;

      expect(theme.color, isA<Color>());
      expect(theme.borderColor, isA<Color>());
      expect(theme.segmentColors, hasLength(3));
    });

    test('dark theme is constant and accessible', () {
      const theme = DebugTheme.dark;

      expect(theme.color, isA<Color>());
      expect(theme.borderColor, isA<Color>());
      expect(theme.segmentColors, hasLength(3));
    });

    test('getSegmentColor returns valid colors for all indices', () {
      const theme = DebugTheme.dark;

      // Index 0: connections (red)
      expect(theme.getSegmentColor(0), isA<Color>());

      // Index 1: nodes (blue)
      expect(theme.getSegmentColor(1), isA<Color>());

      // Index 2: ports (green)
      expect(theme.getSegmentColor(2), isA<Color>());

      // Index beyond range returns last color
      expect(theme.getSegmentColor(100), equals(theme.getSegmentColor(2)));
    });

    test('getSegmentColor handles empty segment colors gracefully', () {
      // Default segment colors are used when segmentColors is empty
      const theme = DebugTheme();
      expect(theme.getSegmentColor(0), isA<Color>());
    });

    test('getSegmentColor clamps negative indices to 0', () {
      const theme = DebugTheme.dark;

      expect(theme.getSegmentColor(-1), equals(theme.getSegmentColor(0)));
    });
  });

  // ===========================================================================
  // DebugTheme - Equality and Hashing
  // ===========================================================================

  group('DebugTheme - Equality', () {
    test('identical themes are equal', () {
      const theme1 = DebugTheme.light;
      const theme2 = DebugTheme.light;

      expect(theme1, equals(theme2));
      expect(theme1.hashCode, equals(theme2.hashCode));
    });

    test('different themes are not equal', () {
      const light = DebugTheme.light;
      const dark = DebugTheme.dark;

      expect(light, isNot(equals(dark)));
    });

    test('themes with different colors are not equal', () {
      const theme1 = DebugTheme(color: Color(0xFF000000));
      const theme2 = DebugTheme(color: Color(0xFFFFFFFF));

      expect(theme1, isNot(equals(theme2)));
    });

    test('themes with different segment colors are not equal', () {
      const theme1 = DebugTheme(segmentColors: [Color(0xFF000000)]);
      const theme2 = DebugTheme(segmentColors: [Color(0xFFFFFFFF)]);

      expect(theme1, isNot(equals(theme2)));
    });

    test('themes with different segment color lengths are not equal', () {
      const theme1 = DebugTheme(segmentColors: [Color(0xFF000000)]);
      const theme2 = DebugTheme(
        segmentColors: [Color(0xFF000000), Color(0xFFFFFFFF)],
      );

      expect(theme1, isNot(equals(theme2)));
    });
  });

  // ===========================================================================
  // DebugTheme - copyWith
  // ===========================================================================

  group('DebugTheme - copyWith', () {
    test('copyWith returns new theme with updated color', () {
      const original = DebugTheme.light;
      final updated = original.copyWith(color: const Color(0xFF123456));

      expect(updated.color, equals(const Color(0xFF123456)));
      expect(updated.borderColor, equals(original.borderColor));
    });

    test('copyWith returns new theme with updated borderColor', () {
      const original = DebugTheme.light;
      final updated = original.copyWith(borderColor: const Color(0xFF654321));

      expect(updated.borderColor, equals(const Color(0xFF654321)));
      expect(updated.color, equals(original.color));
    });

    test('copyWith returns new theme with updated activeColor', () {
      const original = DebugTheme.light;
      final updated = original.copyWith(activeColor: const Color(0xFF00FF00));

      expect(updated.activeColor, equals(const Color(0xFF00FF00)));
    });

    test('copyWith returns new theme with updated activeBorderColor', () {
      const original = DebugTheme.light;
      final updated = original.copyWith(
        activeBorderColor: const Color(0xFF0000FF),
      );

      expect(updated.activeBorderColor, equals(const Color(0xFF0000FF)));
    });

    test('copyWith returns new theme with updated labelColor', () {
      const original = DebugTheme.light;
      final updated = original.copyWith(labelColor: const Color(0xFFAAAAAA));

      expect(updated.labelColor, equals(const Color(0xFFAAAAAA)));
    });

    test('copyWith returns new theme with updated labelBackgroundColor', () {
      const original = DebugTheme.light;
      final updated = original.copyWith(
        labelBackgroundColor: const Color(0xFF333333),
      );

      expect(updated.labelBackgroundColor, equals(const Color(0xFF333333)));
    });

    test('copyWith returns new theme with updated indicatorColor', () {
      const original = DebugTheme.light;
      final updated = original.copyWith(
        indicatorColor: const Color(0xFFFF00FF),
      );

      expect(updated.indicatorColor, equals(const Color(0xFFFF00FF)));
    });

    test('copyWith returns new theme with updated segmentColors', () {
      const original = DebugTheme.light;
      final newColors = [const Color(0xFF111111), const Color(0xFF222222)];
      final updated = original.copyWith(segmentColors: newColors);

      expect(updated.segmentColors, equals(newColors));
    });

    test('copyWith with no arguments returns equivalent theme', () {
      const original = DebugTheme.light;
      final updated = original.copyWith();

      expect(updated, equals(original));
    });
  });

  // ===========================================================================
  // Integration - Debug Overlays with Controller
  // ===========================================================================

  group('Integration - Debug Overlays with Controller', () {
    testWidgets('SpatialIndexDebugLayer responds to transformation changes', (
      tester,
    ) async {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      controller.setScreenSize(const Size(800, 600));
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                SpatialIndexDebugLayer<String>(
                  controller: controller,
                  transformationController: transformationController,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change transformation
      transformationController.value = Matrix4.identity()
        ..translate(100.0, 100.0);

      await tester.pump();

      // Widget should still be present (repainted with new transform)
      expect(find.byType(SpatialIndexDebugLayer<String>), findsOneWidget);

      controller.dispose();
      transformationController.dispose();
    });

    testWidgets('AutopanZoneDebugLayer responds to debug mode changes', (
      tester,
    ) async {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            DebugExtension(mode: DebugMode.none),
            AutoPanExtension(enabled: true),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no CustomPaint (debug mode is none)
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );

      // Enable autoPan zone debug mode
      controller.debug?.setMode(DebugMode.autoPanZone);
      await tester.pumpAndSettle();

      // Now CustomPaint should be visible
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      controller.dispose();
    });

    testWidgets('AutopanZoneDebugLayer responds to autoPan enable/disable', (
      tester,
    ) async {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            DebugExtension(mode: DebugMode.autoPanZone),
            AutoPanExtension(enabled: true),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AutopanZoneDebugLayer<String>(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      // Initially CustomPaint is visible
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      // Disable autoPan
      controller.autoPan?.disable();
      await tester.pumpAndSettle();

      // CustomPaint should be gone
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );

      // Re-enable autoPan
      controller.autoPan?.enable();
      await tester.pumpAndSettle();

      // CustomPaint should be visible again
      expect(
        find.descendant(
          of: find.byType(AutopanZoneDebugLayer<String>),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // Integration - Theme with Debug Extension
  // ===========================================================================

  group('Integration - Theme with Debug Extension', () {
    test('debug extension provides theme to layers', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            DebugExtension(mode: DebugMode.all, theme: DebugTheme.dark),
          ],
        ),
      );

      expect(controller.debug?.theme, equals(DebugTheme.dark));

      controller.dispose();
    });

    test('debug extension defaults to light theme', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: [DebugExtension()]),
      );

      expect(controller.debug?.theme, equals(DebugTheme.light));

      controller.dispose();
    });

    testWidgets('SpatialIndexDebugLayer uses controller debug theme', (
      tester,
    ) async {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            DebugExtension(
              mode: DebugMode.spatialIndex,
              theme: DebugTheme.dark,
            ),
          ],
        ),
      );
      controller.setScreenSize(const Size(800, 600));
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                SpatialIndexDebugLayer<String>(
                  controller: controller,
                  transformationController: transformationController,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the controller's debug theme is dark
      expect(controller.debug?.theme, equals(DebugTheme.dark));

      controller.dispose();
      transformationController.dispose();
    });
  });
}
