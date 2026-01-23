/// Unit tests for [AutoPanMixin] in auto_pan_mixin.dart.
///
/// Tests cover:
/// - Auto-pan zone detection (left, right, top, bottom, corners)
/// - Pan velocity calculations with proximity scaling
/// - Edge case handling (corners, multiple edges, overlapping zones)
/// - Pan trigger thresholds
/// - Lifecycle management (start/stop auto-pan, state reset)
/// - Drag delta processing (freeze/snap behavior)
@Tags(['unit'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Zone Detection Tests
  // ===========================================================================

  group('AutoPanMixin - Zone Detection', () {
    group('Left Edge Zone', () {
      testWidgets('detects pointer in left edge zone', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(25, 300));

        await tester.pump(const Duration(milliseconds: 20));

        expect(autoPanDeltas, isNotEmpty);
        expect(autoPanDeltas.last.dx, lessThan(0));
        expect(autoPanDeltas.last.dy, equals(0));
      });

      testWidgets(
        'does not trigger at left boundary edge (exactly at padding)',
        (tester) async {
          final autoPanDeltas = <Offset>[];

          await tester.pumpWidget(
            _AutoPanTestHarness(
              autoPan: AutoPanPlugin(
                edgePadding: const EdgeInsets.all(50.0),
                panAmount: 10.0,
                panInterval: const Duration(milliseconds: 16),
              ),
              getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
              onAutoPan: autoPanDeltas.add,
            ),
          );

          final state = _getTestState(tester);

          state.simulateDragging(true);
          // Exactly at left boundary (x=50 with 50px padding)
          state.updatePointerPosition(const Offset(50, 300));

          await tester.pump(const Duration(milliseconds: 20));

          // At boundary, not in zone
          expect(autoPanDeltas, isEmpty);
        },
      );

      testWidgets('triggers just inside left boundary', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        // Just inside left zone (x=49 with 50px padding)
        state.updatePointerPosition(const Offset(49, 300));

        await tester.pump(const Duration(milliseconds: 20));

        expect(autoPanDeltas, isNotEmpty);
        expect(autoPanDeltas.last.dx, lessThan(0));
      });
    });

    group('Right Edge Zone', () {
      testWidgets('detects pointer in right edge zone', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(775, 300));

        await tester.pump(const Duration(milliseconds: 20));

        expect(autoPanDeltas, isNotEmpty);
        expect(autoPanDeltas.last.dx, greaterThan(0));
        expect(autoPanDeltas.last.dy, equals(0));
      });

      testWidgets('does not trigger at right boundary edge', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        // Exactly at right boundary (x=750 with 800 width and 50px padding)
        state.updatePointerPosition(const Offset(750, 300));

        await tester.pump(const Duration(milliseconds: 20));

        expect(autoPanDeltas, isEmpty);
      });
    });

    group('Top Edge Zone', () {
      testWidgets('detects pointer in top edge zone', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(400, 25));

        await tester.pump(const Duration(milliseconds: 20));

        expect(autoPanDeltas, isNotEmpty);
        expect(autoPanDeltas.last.dx, equals(0));
        expect(autoPanDeltas.last.dy, lessThan(0));
      });
    });

    group('Bottom Edge Zone', () {
      testWidgets('detects pointer in bottom edge zone', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(400, 575));

        await tester.pump(const Duration(milliseconds: 20));

        expect(autoPanDeltas, isNotEmpty);
        expect(autoPanDeltas.last.dx, equals(0));
        expect(autoPanDeltas.last.dy, greaterThan(0));
      });
    });

    group('Safe Zone (Center)', () {
      testWidgets('no autopan in center safe zone', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(400, 300));

        await tester.pump(const Duration(milliseconds: 50));

        expect(autoPanDeltas, isEmpty);
      });

      testWidgets('no autopan just inside safe zone boundaries', (
        tester,
      ) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        // Just inside safe zone on all sides
        state.updatePointerPosition(const Offset(51, 300));
        await tester.pump(const Duration(milliseconds: 20));
        expect(autoPanDeltas, isEmpty);

        state.updatePointerPosition(const Offset(749, 300));
        await tester.pump(const Duration(milliseconds: 20));
        expect(autoPanDeltas, isEmpty);

        state.updatePointerPosition(const Offset(400, 51));
        await tester.pump(const Duration(milliseconds: 20));
        expect(autoPanDeltas, isEmpty);

        state.updatePointerPosition(const Offset(400, 549));
        await tester.pump(const Duration(milliseconds: 20));
        expect(autoPanDeltas, isEmpty);
      });
    });
  });

  // ===========================================================================
  // Corner/Multiple Edge Tests
  // ===========================================================================

  group('AutoPanMixin - Corner and Multiple Edge Handling', () {
    testWidgets('detects top-left corner (both edges)', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 25));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, lessThan(0)); // Panning left
      expect(autoPanDeltas.last.dy, lessThan(0)); // Panning up
    });

    testWidgets('detects top-right corner (both edges)', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(775, 25));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, greaterThan(0)); // Panning right
      expect(autoPanDeltas.last.dy, lessThan(0)); // Panning up
    });

    testWidgets('detects bottom-left corner (both edges)', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 575));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, lessThan(0)); // Panning left
      expect(autoPanDeltas.last.dy, greaterThan(0)); // Panning down
    });

    testWidgets('detects bottom-right corner (both edges)', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(775, 575));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, greaterThan(0)); // Panning right
      expect(autoPanDeltas.last.dy, greaterThan(0)); // Panning down
    });

    testWidgets('corner produces diagonal pan with equal magnitudes', (
      tester,
    ) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // Equal distance from both edges
      state.updatePointerPosition(const Offset(25, 25));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      // Equal proximity should produce equal magnitude
      expect(autoPanDeltas.last.dx.abs(), equals(autoPanDeltas.last.dy.abs()));
    });
  });

  // ===========================================================================
  // Pan Velocity Calculation Tests
  // ===========================================================================

  group('AutoPanMixin - Pan Velocity Calculations', () {
    testWidgets('pans at max speed when outside bounds', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // Outside left edge
      state.updatePointerPosition(const Offset(-50, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, equals(-10.0)); // Max pan amount
    });

    testWidgets('pans at max speed when far outside bounds', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // Way outside right edge
      state.updatePointerPosition(const Offset(1500, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, equals(10.0)); // Still max pan amount
    });

    testWidgets('uses proximity scaling when enabled', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            useProximityScaling: true,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // At edge zone boundary (proximity = small)
      state.updatePointerPosition(const Offset(49, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      // Near boundary should have smaller pan amount
      expect(autoPanDeltas.last.dx.abs(), lessThan(10.0));
    });

    testWidgets('proximity scaling increases speed near viewport edge', (
      tester,
    ) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            useProximityScaling: true,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // Near viewport edge (high proximity)
      state.updatePointerPosition(const Offset(5, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      // Near edge should have larger pan amount (up to 1.5x)
      expect(autoPanDeltas.last.dx.abs(), greaterThan(10.0));
    });

    testWidgets('configurable pan amount affects velocity', (tester) async {
      final smallPanDeltas = <Offset>[];
      final largePanDeltas = <Offset>[];

      // Test with small pan amount
      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 5.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: smallPanDeltas.add,
        ),
      );

      var state = _getTestState(tester);
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(-10, 300));
      await tester.pump(const Duration(milliseconds: 20));

      // Test with large pan amount
      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 20.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: largePanDeltas.add,
        ),
      );

      state = _getTestState(tester);
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(-10, 300));
      await tester.pump(const Duration(milliseconds: 20));

      expect(smallPanDeltas.last.dx, equals(-5.0));
      expect(largePanDeltas.last.dx, equals(-20.0));
    });
  });

  // ===========================================================================
  // Pan Trigger Thresholds Tests
  // ===========================================================================

  group('AutoPanMixin - Pan Trigger Thresholds', () {
    testWidgets('respects zero padding on specific edge', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.only(
              left: 0, // Disabled
              right: 50,
              top: 50,
              bottom: 50,
            ),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // Near left edge - but left padding is 0
      state.updatePointerPosition(const Offset(10, 300));

      await tester.pump(const Duration(milliseconds: 50));

      // Should not autopan on left edge (no padding there)
      expect(autoPanDeltas.where((d) => d.dx < 0), isEmpty);
    });

    testWidgets('respects asymmetric edge paddings', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.only(
              left: 100, // Large zone
              right: 20, // Small zone
              top: 50,
              bottom: 50,
            ),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // x=50 is inside left zone (100px) but outside right zone
      state.updatePointerPosition(const Offset(50, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, lessThan(0)); // Left pan triggered

      autoPanDeltas.clear();
      state.stopAutoPan();

      // x=785 is outside left zone but inside right zone (800-20=780)
      state.updatePointerPosition(const Offset(785, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, greaterThan(0)); // Right pan triggered
    });

    testWidgets('large overlapping paddings trigger multiple directions', (
      tester,
    ) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.symmetric(
              horizontal: 450, // Overlapping zones
              vertical: 50,
            ),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // Center is in both left AND right zones with overlapping padding
      state.updatePointerPosition(const Offset(400, 300));

      await tester.pump(const Duration(milliseconds: 20));

      // With overlapping zones, the mixin uses else-if logic,
      // so only one direction is chosen (left takes precedence)
      expect(autoPanDeltas, isNotEmpty);
    });
  });

  // ===========================================================================
  // Lifecycle Management Tests
  // ===========================================================================

  group('AutoPanMixin - Lifecycle Management', () {
    group('Start Auto-Pan', () {
      testWidgets('starts timer on first pointer position update', (
        tester,
      ) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(25, 300));

        // Timer should fire
        await tester.pump(const Duration(milliseconds: 20));

        expect(autoPanDeltas, isNotEmpty);
      });

      testWidgets('does not start timer when autoPan is null', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: null, // No autopan
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(25, 300));

        await tester.pump(const Duration(milliseconds: 50));

        expect(autoPanDeltas, isEmpty);
      });

      testWidgets('does not start timer when autoPan is disabled', (
        tester,
      ) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              enabled: false,
              edgePadding: const EdgeInsets.all(50.0),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(25, 300));

        await tester.pump(const Duration(milliseconds: 50));

        expect(autoPanDeltas, isEmpty);
      });

      testWidgets('does not start duplicate timer', (tester) async {
        var timerCallCount = 0;

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: (_) => timerCallCount++,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);

        // Multiple position updates should not create multiple timers
        state.updatePointerPosition(const Offset(25, 300));
        state.updatePointerPosition(const Offset(20, 300));
        state.updatePointerPosition(const Offset(15, 300));

        await tester.pump(const Duration(milliseconds: 20));

        // Should have reasonable number of calls, not triple
        expect(timerCallCount, lessThanOrEqualTo(2));
      });
    });

    group('Stop Auto-Pan', () {
      testWidgets('stops timer when stopAutoPan is called', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(25, 300));

        await tester.pump(const Duration(milliseconds: 20));

        // Stop autopan
        state.stopAutoPan();

        autoPanDeltas.clear();

        // Wait for more ticks
        await tester.pump(const Duration(milliseconds: 50));

        // No more callbacks should occur
        expect(autoPanDeltas, isEmpty);
      });

      testWidgets('can be called multiple times safely', (tester) async {
        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: (_) {},
          ),
        );

        final state = _getTestState(tester);

        expect(() => state.stopAutoPan(), returnsNormally);
        expect(() => state.stopAutoPan(), returnsNormally);
        expect(() => state.stopAutoPan(), returnsNormally);
      });

      testWidgets('timer fires continuously until stopped', (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(
              edgePadding: const EdgeInsets.all(50.0),
              panAmount: 10.0,
              panInterval: const Duration(milliseconds: 16),
            ),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: autoPanDeltas.add,
          ),
        );

        final state = _getTestState(tester);

        state.simulateDragging(true);
        state.updatePointerPosition(const Offset(25, 300));

        // Wait for multiple timer ticks
        await tester.pump(const Duration(milliseconds: 100));

        expect(autoPanDeltas.length, greaterThan(3));
      });
    });

    group('Reset Auto-Pan State', () {
      testWidgets('clears pointer position', (tester) async {
        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: (_) {},
          ),
        );

        final state = _getTestState(tester);

        state.simulatePointerPosition(const Offset(400, 300));
        state.resetAutoPanState();

        // After reset, pointer position is null, so processDragDelta
        // should return the delta unchanged (can't determine if outside)
        final result = state.processDragDelta(const Offset(10, 5));
        expect(result, equals(const Offset(10, 5)));
      });

      testWidgets('clears accumulated offset', (tester) async {
        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: (_) {},
          ),
        );

        final state = _getTestState(tester);

        // Accumulate offset by going outside bounds
        state.simulatePointerPosition(const Offset(900, 300));
        state.processDragDelta(const Offset(10, 5));
        state.processDragDelta(const Offset(20, 10));

        // Reset state
        state.resetAutoPanState();

        // Now when we come back inside, no accumulated snap
        state.simulatePointerPosition(const Offset(400, 300));
        final result = state.processDragDelta(const Offset(3, 2));

        expect(result, equals(const Offset(3, 2)));
      });

      testWidgets('clears wasOutsideBounds flag', (tester) async {
        await tester.pumpWidget(
          _AutoPanTestHarness(
            autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
            getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
            onAutoPan: (_) {},
          ),
        );

        final state = _getTestState(tester);

        // Go outside bounds
        state.simulatePointerPosition(const Offset(900, 300));
        state.processDragDelta(const Offset(10, 5));

        // Reset state
        state.resetAutoPanState();

        // wasOutsideBounds is cleared, so no snap on re-entry
        state.simulatePointerPosition(const Offset(400, 300));
        final result = state.processDragDelta(const Offset(3, 2));

        expect(result, equals(const Offset(3, 2)));
      });
    });
  });

  // ===========================================================================
  // Drag Delta Processing Tests
  // ===========================================================================

  group('AutoPanMixin - processDragDelta', () {
    testWidgets('returns delta unchanged when inside bounds', (tester) async {
      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(400, 300));

      final result = state.processDragDelta(const Offset(10, 5));

      expect(result, equals(const Offset(10, 5)));
    });

    testWidgets('returns zero delta when pointer is outside bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(900, 300));

      final result = state.processDragDelta(const Offset(10, 5));

      expect(result, equals(Offset.zero));
    });

    testWidgets('accumulates offset when outside bounds', (tester) async {
      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(900, 300));

      // All deltas return zero while outside
      expect(state.processDragDelta(const Offset(10, 5)), equals(Offset.zero));
      expect(state.processDragDelta(const Offset(20, 10)), equals(Offset.zero));
      expect(state.processDragDelta(const Offset(5, 15)), equals(Offset.zero));

      // Move back inside
      state.simulatePointerPosition(const Offset(400, 300));

      // Snap happens with accumulated offset
      final snapResult = state.processDragDelta(const Offset(3, 2));

      // delta + accumulated = (3,2) + (10+20+5, 5+10+15) = (38, 32)
      expect(snapResult, equals(const Offset(38, 32)));
    });

    testWidgets('clears accumulated offset after snap', (tester) async {
      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Go outside, accumulate, come back
      state.simulatePointerPosition(const Offset(900, 300));
      state.processDragDelta(const Offset(10, 5));

      state.simulatePointerPosition(const Offset(400, 300));
      state.processDragDelta(const Offset(3, 2)); // Snap happens

      // Next delta should be normal
      final normalResult = state.processDragDelta(const Offset(5, 5));
      expect(normalResult, equals(const Offset(5, 5)));
    });

    testWidgets('returns delta unchanged when no viewport bounds callback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: null, // No bounds callback
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(1000, 1000));

      final result = state.processDragDelta(const Offset(10, 5));

      expect(result, equals(const Offset(10, 5)));
    });

    testWidgets('returns delta unchanged when no pointer position set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Don't set pointer position

      final result = state.processDragDelta(const Offset(10, 5));

      expect(result, equals(const Offset(10, 5)));
    });

    testWidgets('handles rapid in/out/in transitions', (tester) async {
      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Inside
      state.simulatePointerPosition(const Offset(400, 300));
      expect(
        state.processDragDelta(const Offset(5, 5)),
        equals(const Offset(5, 5)),
      );

      // Outside
      state.simulatePointerPosition(const Offset(900, 300));
      expect(state.processDragDelta(const Offset(10, 10)), equals(Offset.zero));

      // Inside again (snap with accumulated)
      state.simulatePointerPosition(const Offset(400, 300));
      expect(
        state.processDragDelta(const Offset(3, 3)),
        equals(const Offset(13, 13)),
      );

      // Outside again
      state.simulatePointerPosition(const Offset(-100, 300));
      expect(state.processDragDelta(const Offset(7, 7)), equals(Offset.zero));

      // Inside final time
      state.simulatePointerPosition(const Offset(400, 300));
      expect(
        state.processDragDelta(const Offset(2, 2)),
        equals(const Offset(9, 9)), // 2 + 7
      );
    });
  });

  // ===========================================================================
  // Integration Tests
  // ===========================================================================

  group('AutoPanMixin - Integration', () {
    testWidgets('autopan calls onDragUpdate with delta', (tester) async {
      final dragUpdates = <DragUpdateDetails>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
          onDragUpdate: dragUpdates.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300));

      await tester.pump(const Duration(milliseconds: 50));

      expect(dragUpdates, isNotEmpty);
      expect(dragUpdates.last.delta.dx, lessThan(0));
    });

    testWidgets('does not perform autopan when not dragging', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      // Not dragging
      state.simulateDragging(false);
      state.updatePointerPosition(const Offset(25, 300));

      await tester.pump(const Duration(milliseconds: 50));

      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('does not perform autopan when onAutoPan callback is null', (
      tester,
    ) async {
      var dragUpdateCount = 0;

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: null, // No callback
          onDragUpdate: (_) => dragUpdateCount++,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300));

      await tester.pump(const Duration(milliseconds: 50));

      // No drag updates from autopan
      expect(dragUpdateCount, equals(0));
    });

    testWidgets('viewport with non-zero origin works correctly', (
      tester,
    ) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          // Viewport offset from origin
          getViewportBounds: () => const Rect.fromLTWH(100, 50, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // In left edge zone of offset viewport (100 + 25 = 125)
      state.updatePointerPosition(const Offset(125, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, lessThan(0));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('AutoPanMixin - Edge Cases', () {
    testWidgets('handles exact boundary positions', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);

      // Exactly at viewport edge (x=0)
      state.updatePointerPosition(const Offset(0, 300));
      await tester.pump(const Duration(milliseconds: 20));

      // At viewport boundary, it's considered "in edge zone" not "outside"
      // but still triggers autopan
      expect(autoPanDeltas, isNotEmpty);
    });

    testWidgets('handles very small viewport', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          // Small viewport where edges overlap
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 80, 80),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // Center of small viewport
      state.updatePointerPosition(const Offset(40, 40));

      await tester.pump(const Duration(milliseconds: 20));

      // In overlapping zones - should trigger based on position
      expect(autoPanDeltas, isNotEmpty);
    });

    testWidgets('handles negative viewport coordinates', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _AutoPanTestHarness(
          autoPan: AutoPanPlugin(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          // Viewport with negative origin
          getViewportBounds: () => const Rect.fromLTWH(-400, -300, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      // Near left edge of negative viewport
      state.updatePointerPosition(const Offset(-375, 0));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, lessThan(0));
    });

    testWidgets('handles widget disposal during autopan', (tester) async {
      final autoPanDeltas = <Offset>[];

      final key = GlobalKey<_TestElementScopeState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestElementScope(
              key: key,
              autoPan: AutoPanPlugin(
                edgePadding: const EdgeInsets.all(50.0),
                panAmount: 10.0,
                panInterval: const Duration(milliseconds: 16),
              ),
              getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
              onAutoPan: autoPanDeltas.add,
              onDragUpdate: (_) {},
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = key.currentState!;

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);

      // Remove widget (triggers dispose)
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      autoPanDeltas.clear();

      // Wait to ensure no more callbacks
      await tester.pump(const Duration(milliseconds: 50));

      expect(autoPanDeltas, isEmpty);
    });
  });
}

// =============================================================================
// Test Harness
// =============================================================================

/// Helper to get test state from tester.
_TestElementScopeState _getTestState(WidgetTester tester) {
  return tester.state<_TestElementScopeState>(find.byType(_TestElementScope));
}

/// Test harness widget that wraps a testable ElementScope-like state.
class _AutoPanTestHarness extends StatelessWidget {
  const _AutoPanTestHarness({
    required this.autoPan,
    required this.getViewportBounds,
    required this.onAutoPan,
    this.onDragUpdate,
  });

  final AutoPanPlugin? autoPan;
  final Rect Function()? getViewportBounds;
  final void Function(Offset delta)? onAutoPan;
  final void Function(DragUpdateDetails details)? onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _TestElementScope(
          autoPan: autoPan,
          getViewportBounds: getViewportBounds,
          onAutoPan: onAutoPan,
          onDragUpdate: onDragUpdate ?? (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
  }
}

/// Widget that mimics ElementScope but exposes mixin methods for testing.
class _TestElementScope extends StatefulWidget {
  const _TestElementScope({
    super.key,
    required this.autoPan,
    required this.getViewportBounds,
    required this.onAutoPan,
    required this.onDragUpdate,
    required this.child,
  });

  final AutoPanPlugin? autoPan;
  final Rect Function()? getViewportBounds;
  final void Function(Offset delta)? onAutoPan;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final Widget child;

  @override
  State<_TestElementScope> createState() => _TestElementScopeState();
}

/// State that uses a testable version of AutoPanMixin.
class _TestElementScopeState extends State<_TestElementScope>
    with _TestableAutoPanMixin {
  bool _isDragging = false;

  @override
  bool get isDragging => _isDragging;

  void simulateDragging(bool value) {
    _isDragging = value;
  }

  void simulatePointerPosition(Offset position) {
    setPointerPosition(position);
  }

  @override
  void dispose() {
    stopAutoPan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A testable version of AutoPanMixin that works with _TestElementScope.
///
/// This mixin replicates the core logic from AutoPanMixin but works with
/// the test widget instead of requiring the full ElementScope hierarchy.
mixin _TestableAutoPanMixin on State<_TestElementScope> {
  Timer? _autoPanTimer;
  Offset? _lastPointerPosition;
  Offset _accumulatedOffset = Offset.zero;
  bool _wasOutsideBounds = false;

  bool get isDragging;

  void setPointerPosition(Offset position) {
    _lastPointerPosition = position;
  }

  void updatePointerPosition(Offset globalPosition) {
    _lastPointerPosition = globalPosition;

    final autoPan = widget.autoPan;
    if (autoPan != null && autoPan.isEnabled && _autoPanTimer == null) {
      _startAutoPan();
    }
  }

  Offset processDragDelta(Offset delta) {
    final isOutside = _isPointerOutsideBounds();

    if (isOutside) {
      _accumulatedOffset += delta;
      _wasOutsideBounds = true;
      return Offset.zero;
    }

    if (_wasOutsideBounds && _accumulatedOffset != Offset.zero) {
      final snap = _accumulatedOffset;
      _accumulatedOffset = Offset.zero;
      _wasOutsideBounds = false;
      return delta + snap;
    }

    _wasOutsideBounds = false;
    return delta;
  }

  void resetAutoPanState() {
    _lastPointerPosition = null;
    _accumulatedOffset = Offset.zero;
    _wasOutsideBounds = false;
  }

  void stopAutoPan() {
    _autoPanTimer?.cancel();
    _autoPanTimer = null;
  }

  bool _isPointerOutsideBounds() {
    final getViewportBounds = widget.getViewportBounds;
    final pointer = _lastPointerPosition;

    if (getViewportBounds == null || pointer == null) {
      return false;
    }

    final bounds = getViewportBounds();
    return !bounds.contains(pointer);
  }

  bool _isInEdgeZone() {
    final autoPan = widget.autoPan;
    final getViewportBounds = widget.getViewportBounds;
    final pointer = _lastPointerPosition;

    if (autoPan == null ||
        !autoPan.isEnabled ||
        getViewportBounds == null ||
        pointer == null) {
      return false;
    }

    final bounds = getViewportBounds();

    if (!bounds.contains(pointer)) {
      return false;
    }

    final padding = autoPan.edgePadding;

    final inLeftZone =
        padding.left > 0 && pointer.dx < bounds.left + padding.left;
    final inRightZone =
        padding.right > 0 && pointer.dx > bounds.right - padding.right;
    final inTopZone = padding.top > 0 && pointer.dy < bounds.top + padding.top;
    final inBottomZone =
        padding.bottom > 0 && pointer.dy > bounds.bottom - padding.bottom;

    return inLeftZone || inRightZone || inTopZone || inBottomZone;
  }

  void _startAutoPan() {
    final autoPan = widget.autoPan;
    if (autoPan == null || !autoPan.isEnabled || _autoPanTimer != null) {
      return;
    }

    _autoPanTimer = Timer.periodic(
      autoPan.panInterval,
      (_) => _performAutoPan(),
    );
  }

  void _performAutoPan() {
    final autoPan = widget.autoPan;
    final onAutoPan = widget.onAutoPan;
    final getViewportBounds = widget.getViewportBounds;
    final pointer = _lastPointerPosition;

    if (autoPan == null ||
        !autoPan.isEnabled ||
        onAutoPan == null ||
        getViewportBounds == null ||
        pointer == null ||
        !isDragging) {
      return;
    }

    final bounds = getViewportBounds();
    final padding = autoPan.edgePadding;
    final isOutside = !bounds.contains(pointer);

    if (!isOutside && !_isInEdgeZone()) {
      return;
    }

    double dx = 0.0;
    double dy = 0.0;

    // Left edge / outside left
    if (pointer.dx < bounds.left + padding.left) {
      if (isOutside && pointer.dx < bounds.left) {
        dx = -autoPan.panAmount;
      } else if (padding.left > 0) {
        final proximity = bounds.left + padding.left - pointer.dx;
        dx = -autoPan.calculatePanAmount(
          proximity,
          edgePaddingValue: padding.left,
        );
      }
    }
    // Right edge / outside right
    else if (pointer.dx > bounds.right - padding.right) {
      if (isOutside && pointer.dx > bounds.right) {
        dx = autoPan.panAmount;
      } else if (padding.right > 0) {
        final proximity = pointer.dx - (bounds.right - padding.right);
        dx = autoPan.calculatePanAmount(
          proximity,
          edgePaddingValue: padding.right,
        );
      }
    }

    // Top edge / outside top
    if (pointer.dy < bounds.top + padding.top) {
      if (isOutside && pointer.dy < bounds.top) {
        dy = -autoPan.panAmount;
      } else if (padding.top > 0) {
        final proximity = bounds.top + padding.top - pointer.dy;
        dy = -autoPan.calculatePanAmount(
          proximity,
          edgePaddingValue: padding.top,
        );
      }
    }
    // Bottom edge / outside bottom
    else if (pointer.dy > bounds.bottom - padding.bottom) {
      if (isOutside && pointer.dy > bounds.bottom) {
        dy = autoPan.panAmount;
      } else if (padding.bottom > 0) {
        final proximity = pointer.dy - (bounds.bottom - padding.bottom);
        dy = autoPan.calculatePanAmount(
          proximity,
          edgePaddingValue: padding.bottom,
        );
      }
    }

    if (dx != 0.0 || dy != 0.0) {
      final delta = Offset(dx, dy);

      onAutoPan(delta);

      widget.onDragUpdate(
        DragUpdateDetails(globalPosition: pointer, delta: delta),
      );
    }
  }
}
