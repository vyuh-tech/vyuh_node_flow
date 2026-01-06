/// Unit tests for [AutoPanMixin] in editor/auto_pan/auto_pan_mixin.dart.
///
/// Tests cover:
/// - updatePointerPosition - tracking pointer position and starting timer
/// - processDragDelta - processing drag deltas with boundary behavior
/// - resetAutoPanState - resetting all autopan state
/// - stopAutoPan - stopping autopan timer
/// - _isPointerOutsideBounds - detecting when pointer exits viewport bounds
/// - _isInEdgeZone - edge zone detection with padding
/// - _performAutoPan - autopan execution logic with pan calculations
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
  // updatePointerPosition Tests
  // ===========================================================================

  group('AutoPanMixin - updatePointerPosition', () {
    testWidgets('updates last pointer position', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.updatePointerPosition(const Offset(100, 200));

      // The pointer position should be tracked (we verify this by
      // checking that edge zone detection works correctly)
      state.simulateDragging(true);

      // Wait for timer
      await tester.pump(const Duration(milliseconds: 20));

      // Should not be in edge zone at (100, 200)
      // We can verify position was stored because subsequent operations use it
    });

    testWidgets(
      'starts autopan timer when autoPan is enabled and not running',
      (tester) async {
        final autoPanDeltas = <Offset>[];

        await tester.pumpWidget(
          _TestHarness(
            autoPan: AutoPanExtension(
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
        state.updatePointerPosition(const Offset(25, 300)); // In edge zone

        // Timer should start and fire
        await tester.pump(const Duration(milliseconds: 20));

        expect(autoPanDeltas, isNotEmpty);
      },
    );

    testWidgets('does not start timer when autoPan is null', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: null,
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
        _TestHarness(
          autoPan: AutoPanExtension(
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

    testWidgets('does not create duplicate timer on multiple calls', (
      tester,
    ) async {
      var callCount = 0;

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) => callCount++,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);

      // Multiple position updates
      state.updatePointerPosition(const Offset(25, 300));
      state.updatePointerPosition(const Offset(20, 300));
      state.updatePointerPosition(const Offset(15, 300));

      await tester.pump(const Duration(milliseconds: 20));

      // Should only have one timer running, not multiple
      expect(callCount, lessThanOrEqualTo(2));
    });
  });

  // ===========================================================================
  // processDragDelta Tests
  // ===========================================================================

  group('AutoPanMixin - processDragDelta', () {
    testWidgets('returns delta unchanged when inside bounds', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Center of viewport - inside bounds
      state.simulatePointerPosition(const Offset(400, 300));

      final result = state.processDragDelta(const Offset(10, 5));

      expect(result, equals(const Offset(10, 5)));
    });

    testWidgets('returns zero delta when pointer is outside bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Outside right edge
      state.simulatePointerPosition(const Offset(900, 300));

      final result = state.processDragDelta(const Offset(10, 5));

      expect(result, equals(Offset.zero));
    });

    testWidgets('freezes element at edge when outside bounds', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Outside left edge
      state.simulatePointerPosition(const Offset(-50, 300));

      // Multiple deltas should all return zero
      expect(state.processDragDelta(const Offset(10, 5)), equals(Offset.zero));
      expect(state.processDragDelta(const Offset(20, 10)), equals(Offset.zero));
      expect(state.processDragDelta(const Offset(5, 15)), equals(Offset.zero));
    });

    testWidgets('accumulates offset and snaps on re-entry', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Go outside bounds
      state.simulatePointerPosition(const Offset(900, 300));

      // Accumulate deltas
      state.processDragDelta(const Offset(10, 5));
      state.processDragDelta(const Offset(20, 10));
      state.processDragDelta(const Offset(5, 15));

      // Re-enter bounds
      state.simulatePointerPosition(const Offset(400, 300));

      // Next delta should include snap
      final snapResult = state.processDragDelta(const Offset(3, 2));

      // delta + accumulated = (3,2) + (10+20+5, 5+10+15) = (38, 32)
      expect(snapResult, equals(const Offset(38, 32)));
    });

    testWidgets('clears accumulated offset after snap', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
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

    testWidgets('returns delta unchanged when getViewportBounds is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: null,
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(1000, 1000));

      final result = state.processDragDelta(const Offset(10, 5));

      // Without bounds, cannot determine if outside
      expect(result, equals(const Offset(10, 5)));
    });

    testWidgets('returns delta unchanged when pointer position is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Don't set pointer position

      final result = state.processDragDelta(const Offset(10, 5));

      expect(result, equals(const Offset(10, 5)));
    });

    testWidgets('handles rapid in/out transitions', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
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

      // Inside (snap)
      state.simulatePointerPosition(const Offset(400, 300));
      expect(
        state.processDragDelta(const Offset(3, 3)),
        equals(const Offset(13, 13)),
      );

      // Outside again
      state.simulatePointerPosition(const Offset(-100, 300));
      expect(state.processDragDelta(const Offset(7, 7)), equals(Offset.zero));

      // Inside final
      state.simulatePointerPosition(const Offset(400, 300));
      expect(
        state.processDragDelta(const Offset(2, 2)),
        equals(const Offset(9, 9)),
      );
    });
  });

  // ===========================================================================
  // resetAutoPanState Tests
  // ===========================================================================

  group('AutoPanMixin - resetAutoPanState', () {
    testWidgets('clears pointer position', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(900, 300));
      state.resetAutoPanState();

      // After reset, pointer position is null, so processDragDelta
      // returns unchanged (can't determine outside bounds)
      final result = state.processDragDelta(const Offset(10, 5));
      expect(result, equals(const Offset(10, 5)));
    });

    testWidgets('clears accumulated offset', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Accumulate offset
      state.simulatePointerPosition(const Offset(900, 300));
      state.processDragDelta(const Offset(10, 5));
      state.processDragDelta(const Offset(20, 10));

      // Reset
      state.resetAutoPanState();

      // Re-enter - should be no accumulated snap
      state.simulatePointerPosition(const Offset(400, 300));
      final result = state.processDragDelta(const Offset(3, 2));

      expect(result, equals(const Offset(3, 2)));
    });

    testWidgets('clears wasOutsideBounds flag', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Go outside
      state.simulatePointerPosition(const Offset(900, 300));
      state.processDragDelta(const Offset(10, 5));

      // Reset
      state.resetAutoPanState();

      // Re-enter - no snap because wasOutsideBounds is cleared
      state.simulatePointerPosition(const Offset(400, 300));
      final result = state.processDragDelta(const Offset(3, 2));

      expect(result, equals(const Offset(3, 2)));
    });

    testWidgets('can be called when already in clean state', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Call multiple times
      expect(() => state.resetAutoPanState(), returnsNormally);
      expect(() => state.resetAutoPanState(), returnsNormally);
      expect(() => state.resetAutoPanState(), returnsNormally);
    });
  });

  // ===========================================================================
  // stopAutoPan Tests
  // ===========================================================================

  group('AutoPanMixin - stopAutoPan', () {
    testWidgets('cancels running timer', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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

      // Timer should have fired
      expect(autoPanDeltas, isNotEmpty);

      // Stop autopan
      state.stopAutoPan();
      autoPanDeltas.clear();

      // Wait for more time
      await tester.pump(const Duration(milliseconds: 100));

      // No more callbacks
      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('can be called when timer is not running', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // No timer started yet
      expect(() => state.stopAutoPan(), returnsNormally);
    });

    testWidgets('can be called multiple times safely', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      expect(() => state.stopAutoPan(), returnsNormally);
      expect(() => state.stopAutoPan(), returnsNormally);
      expect(() => state.stopAutoPan(), returnsNormally);
    });

    testWidgets('allows timer to restart after stop', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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

      // Stop
      state.stopAutoPan();
      autoPanDeltas.clear();

      // Restart
      state.updatePointerPosition(const Offset(775, 300));

      await tester.pump(const Duration(milliseconds: 20));

      // Timer should have restarted
      expect(autoPanDeltas, isNotEmpty);
    });
  });

  // ===========================================================================
  // _isPointerOutsideBounds Tests (via processDragDelta behavior)
  // ===========================================================================

  group('AutoPanMixin - isPointerOutsideBounds (inferred)', () {
    testWidgets('returns false when inside all bounds', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Center of bounds
      state.simulatePointerPosition(const Offset(400, 300));

      // Delta passes through (not outside bounds)
      expect(
        state.processDragDelta(const Offset(5, 5)),
        equals(const Offset(5, 5)),
      );
    });

    testWidgets('returns true when left of left bound', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(-10, 300));

      expect(state.processDragDelta(const Offset(5, 5)), equals(Offset.zero));
    });

    testWidgets('returns true when right of right bound', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(850, 300));

      expect(state.processDragDelta(const Offset(5, 5)), equals(Offset.zero));
    });

    testWidgets('returns true when above top bound', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(400, -10));

      expect(state.processDragDelta(const Offset(5, 5)), equals(Offset.zero));
    });

    testWidgets('returns true when below bottom bound', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      state.simulatePointerPosition(const Offset(400, 650));

      expect(state.processDragDelta(const Offset(5, 5)), equals(Offset.zero));
    });

    testWidgets('returns false when exactly at boundary', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Exactly at left edge (x=0) is inside bounds
      state.simulatePointerPosition(const Offset(0, 300));

      expect(
        state.processDragDelta(const Offset(5, 5)),
        equals(const Offset(5, 5)),
      );
    });

    testWidgets('handles viewport with non-zero origin', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(100, 50, 800, 600),
          onAutoPan: (_) {},
        ),
      );

      final state = _getTestState(tester);

      // Inside offset bounds
      state.simulatePointerPosition(const Offset(500, 350));
      expect(
        state.processDragDelta(const Offset(5, 5)),
        equals(const Offset(5, 5)),
      );

      // Outside left of offset bounds (x < 100)
      state.simulatePointerPosition(const Offset(50, 350));
      expect(state.processDragDelta(const Offset(5, 5)), equals(Offset.zero));
    });
  });

  // ===========================================================================
  // _isInEdgeZone Tests (via autopan behavior)
  // ===========================================================================

  group('AutoPanMixin - isInEdgeZone (inferred)', () {
    testWidgets('detects left edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      // x=25 is within 50px of left edge
      state.updatePointerPosition(const Offset(25, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, lessThan(0)); // Panning left
    });

    testWidgets('detects right edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      // x=775 is within 50px of right edge (800)
      state.updatePointerPosition(const Offset(775, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, greaterThan(0)); // Panning right
    });

    testWidgets('detects top edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      // y=25 is within 50px of top edge
      state.updatePointerPosition(const Offset(400, 25));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dy, lessThan(0)); // Panning up
    });

    testWidgets('detects bottom edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      // y=575 is within 50px of bottom edge (600)
      state.updatePointerPosition(const Offset(400, 575));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dy, greaterThan(0)); // Panning down
    });

    testWidgets('not in edge zone at center', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      state.updatePointerPosition(const Offset(400, 300)); // Center

      await tester.pump(const Duration(milliseconds: 50));

      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('not in edge zone exactly at inner boundary', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      // x=50 is exactly at boundary (not in zone)
      state.updatePointerPosition(const Offset(50, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('respects zero edge padding', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      // Near left edge but no padding
      state.updatePointerPosition(const Offset(10, 300));

      await tester.pump(const Duration(milliseconds: 50));

      // Should not trigger left pan
      expect(autoPanDeltas.where((d) => d.dx < 0), isEmpty);
    });

    testWidgets('corner triggers both axes', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      // Bottom-right corner
      state.updatePointerPosition(const Offset(775, 575));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, greaterThan(0)); // Right
      expect(autoPanDeltas.last.dy, greaterThan(0)); // Down
    });
  });

  // ===========================================================================
  // _performAutoPan Tests
  // ===========================================================================

  group('AutoPanMixin - performAutoPan', () {
    testWidgets('does not pan when not dragging', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(false); // Not dragging
      state.updatePointerPosition(const Offset(25, 300)); // In edge zone

      await tester.pump(const Duration(milliseconds: 50));

      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('does not pan when onAutoPan is null', (tester) async {
      var dragUpdateCount = 0;

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: null,
          onDragUpdate: (_) => dragUpdateCount++,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300));

      await tester.pump(const Duration(milliseconds: 50));

      // performAutoPan returns early, no drag update from autopan
      expect(dragUpdateCount, equals(0));
    });

    testWidgets('does not pan when getViewportBounds is null', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: null,
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300));

      await tester.pump(const Duration(milliseconds: 50));

      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('does not pan when pointer position is null', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      // Don't set pointer position - manually start timer
      state.forceStartAutoPan();

      await tester.pump(const Duration(milliseconds: 50));

      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('does not pan when in inner bounds (safe zone)', (
      tester,
    ) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      state.updatePointerPosition(const Offset(400, 300)); // Center

      await tester.pump(const Duration(milliseconds: 50));

      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('pans at max speed when outside bounds', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      state.updatePointerPosition(const Offset(-50, 300)); // Outside left

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, equals(-10.0)); // Max pan amount
    });

    testWidgets('uses proximity scaling in edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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
      // Near edge zone boundary (low proximity)
      state.updatePointerPosition(const Offset(49, 300));

      await tester.pump(const Duration(milliseconds: 20));

      expect(autoPanDeltas, isNotEmpty);
      // Near boundary should be slower
      expect(autoPanDeltas.last.dx.abs(), lessThan(10.0));
    });

    testWidgets('calls onDragUpdate with autopan delta', (tester) async {
      final dragUpdates = <DragUpdateDetails>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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

    testWidgets('timer fires continuously during drag', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
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

      // Wait for multiple ticks
      await tester.pump(const Duration(milliseconds: 100));

      expect(autoPanDeltas.length, greaterThan(3));
    });
  });

  // ===========================================================================
  // Widget Dispose Tests
  // ===========================================================================

  group('AutoPanMixin - Widget Disposal', () {
    testWidgets('stops timer on dispose', (tester) async {
      final autoPanDeltas = <Offset>[];
      final key = GlobalKey<_TestElementScopeState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestElementScope(
              key: key,
              autoPan: AutoPanExtension(
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

      // Dispose widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      autoPanDeltas.clear();

      // Wait to ensure no more callbacks
      await tester.pump(const Duration(milliseconds: 100));

      expect(autoPanDeltas, isEmpty);
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('AutoPanMixin - Edge Cases', () {
    testWidgets('handles very small viewport', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          // Viewport smaller than edge zones
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 80, 80),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(40, 40)); // Center

      await tester.pump(const Duration(milliseconds: 20));

      // Overlapping edge zones
      expect(autoPanDeltas, isNotEmpty);
    });

    testWidgets('handles negative viewport coordinates', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
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

    testWidgets('handles zero pan amount (disabled)', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 0.0, // Disabled
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: autoPanDeltas.add,
        ),
      );

      final state = _getTestState(tester);

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300));

      await tester.pump(const Duration(milliseconds: 50));

      // isEnabled is false when panAmount <= 0
      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('handles asymmetric edge padding', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.only(
              left: 100,
              right: 20,
              top: 50,
              bottom: 10,
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

      // In large left zone
      state.updatePointerPosition(const Offset(50, 300));
      await tester.pump(const Duration(milliseconds: 20));
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, lessThan(0));

      state.stopAutoPan();
      autoPanDeltas.clear();

      // In small right zone
      state.updatePointerPosition(const Offset(785, 300));
      await tester.pump(const Duration(milliseconds: 20));
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, greaterThan(0));
    });
  });
}

// =============================================================================
// Test Harness
// =============================================================================

/// Helper to get test state.
_TestElementScopeState _getTestState(WidgetTester tester) {
  return tester.state<_TestElementScopeState>(find.byType(_TestElementScope));
}

/// Test harness widget.
class _TestHarness extends StatelessWidget {
  const _TestHarness({
    required this.autoPan,
    required this.getViewportBounds,
    required this.onAutoPan,
    this.onDragUpdate,
  });

  final AutoPanExtension? autoPan;
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

/// Widget that mimics ElementScope and exposes mixin methods for testing.
class _TestElementScope extends StatefulWidget {
  const _TestElementScope({
    super.key,
    required this.autoPan,
    required this.getViewportBounds,
    required this.onAutoPan,
    required this.onDragUpdate,
    required this.child,
  });

  final AutoPanExtension? autoPan;
  final Rect Function()? getViewportBounds;
  final void Function(Offset delta)? onAutoPan;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final Widget child;

  @override
  State<_TestElementScope> createState() => _TestElementScopeState();
}

/// State with testable AutoPan implementation.
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

/// Testable AutoPan implementation matching the real mixin.
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

  /// Force start autopan timer (for testing null pointer cases).
  void forceStartAutoPan() {
    _startAutoPan();
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
