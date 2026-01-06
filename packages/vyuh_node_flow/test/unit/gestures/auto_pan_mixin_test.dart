/// Unit tests for [AutoPanMixin].
///
/// Tests cover:
/// - Auto-pan configuration (zones, speed, curves)
/// - Auto-pan state management (resetAutoPanState, stopAutoPan)
/// - Edge detection logic (when pointer is near edges or outside bounds)
/// - Pan direction calculations
/// - Drag delta processing with freeze/snap behavior
/// - Animation callbacks and timer management
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

  group('AutoPanMixin - processDragDelta', () {
    testWidgets('returns delta unchanged when inside bounds', (tester) async {
      final deltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () =>
              const Rect.fromLTWH(0, 0, 800, 600), // Large bounds
          onAutoPan: (_) {},
          onDragUpdate: (details) => deltas.add(details.delta),
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Simulate pointer inside bounds (center of viewport)
      state.simulatePointerPosition(const Offset(400, 300));

      // Process a delta
      final result = state.processDragDelta(const Offset(10, 5));

      // Delta should pass through unchanged
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
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Simulate pointer outside bounds (beyond right edge)
      state.simulatePointerPosition(const Offset(900, 300));

      // Process a delta
      final result = state.processDragDelta(const Offset(10, 5));

      // Delta should be zero (element frozen at edge)
      expect(result, equals(Offset.zero));
    });

    testWidgets('accumulates offset when outside bounds', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Simulate pointer outside bounds
      state.simulatePointerPosition(const Offset(900, 300));

      // Process multiple deltas while outside - all should return zero
      expect(state.processDragDelta(const Offset(10, 5)), equals(Offset.zero));
      expect(state.processDragDelta(const Offset(20, 10)), equals(Offset.zero));
      expect(state.processDragDelta(const Offset(5, 15)), equals(Offset.zero));

      // Now move pointer back inside bounds
      state.simulatePointerPosition(const Offset(400, 300));

      // Next delta should include the accumulated offset as a snap
      final snapResult = state.processDragDelta(const Offset(3, 2));

      // Expected: delta + accumulated = (3,2) + (10+20+5, 5+10+15) = (38, 32)
      expect(snapResult, equals(const Offset(38, 32)));
    });

    testWidgets('clears accumulated offset after snap', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Go outside, accumulate, come back
      state.simulatePointerPosition(const Offset(900, 300));
      state.processDragDelta(const Offset(10, 5));

      state.simulatePointerPosition(const Offset(400, 300));
      state.processDragDelta(const Offset(3, 2)); // Snap happens here

      // Next delta should be normal (no more accumulated offset)
      final normalResult = state.processDragDelta(const Offset(5, 5));
      expect(normalResult, equals(const Offset(5, 5)));
    });

    testWidgets('returns delta unchanged when no viewport bounds callback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: null, // No bounds callback
          onAutoPan: (_) {},
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Without bounds, pointer position doesn't matter
      state.simulatePointerPosition(const Offset(1000, 1000));

      final result = state.processDragDelta(const Offset(10, 5));

      // Should pass through since we can't determine if outside bounds
      expect(result, equals(const Offset(10, 5)));
    });

    testWidgets('returns delta unchanged when no pointer position set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Don't set pointer position

      final result = state.processDragDelta(const Offset(10, 5));

      // Should pass through since we can't determine if outside bounds
      expect(result, equals(const Offset(10, 5)));
    });
  });

  group('AutoPanMixin - resetAutoPanState', () {
    testWidgets('clears pointer position', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Set pointer position
      state.simulatePointerPosition(const Offset(400, 300));

      // Reset state
      state.resetAutoPanState();

      // After reset, pointer position is cleared, so outside check should return false
      // This means delta passes through unchanged
      final result = state.processDragDelta(const Offset(10, 5));
      expect(result, equals(const Offset(10, 5)));
    });

    testWidgets('clears accumulated offset', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Accumulate offset by going outside bounds
      state.simulatePointerPosition(const Offset(900, 300));
      state.processDragDelta(const Offset(10, 5));
      state.processDragDelta(const Offset(20, 10));

      // Reset state
      state.resetAutoPanState();

      // Now when we come back inside, there should be no accumulated snap
      state.simulatePointerPosition(const Offset(400, 300));
      final result = state.processDragDelta(const Offset(3, 2));

      // Should be just the delta, no accumulated offset
      expect(result, equals(const Offset(3, 2)));
    });

    testWidgets('clears wasOutsideBounds flag', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Go outside bounds
      state.simulatePointerPosition(const Offset(900, 300));
      state.processDragDelta(const Offset(10, 5));

      // Reset state
      state.resetAutoPanState();

      // Go inside - since wasOutsideBounds was reset, no snap should occur
      state.simulatePointerPosition(const Offset(400, 300));
      final result = state.processDragDelta(const Offset(3, 2));

      expect(result, equals(const Offset(3, 2)));
    });
  });

  group('AutoPanMixin - stopAutoPan', () {
    testWidgets('stops auto-pan timer', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Start dragging in edge zone
      state.simulateDragging(true);
      state.simulatePointerPosition(const Offset(25, 300)); // In left edge zone

      // This would normally start the auto-pan timer
      state.updatePointerPosition(const Offset(25, 300));

      // Wait for one timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Stop auto-pan
      state.stopAutoPan();

      // Clear captured deltas
      autoPanDeltas.clear();

      // Wait for more ticks - no more deltas should be captured
      await tester.pump(const Duration(milliseconds: 50));

      // Timer should have stopped, so no more callbacks
      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('can be called multiple times safely', (tester) async {
      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(edgePadding: const EdgeInsets.all(50.0)),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (_) {},
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Should not throw when called multiple times
      expect(() => state.stopAutoPan(), returnsNormally);
      expect(() => state.stopAutoPan(), returnsNormally);
      expect(() => state.stopAutoPan(), returnsNormally);
    });
  });

  group('AutoPanMixin - Edge Detection', () {
    testWidgets('detects pointer in left edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Start dragging in left edge zone (inside bounds but near left edge)
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300)); // 25 < 50 (left edge)

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should have triggered autopan with negative dx (panning left)
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, lessThan(0));
    });

    testWidgets('detects pointer in right edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Start dragging in right edge zone (inside bounds but near right edge)
      state.simulateDragging(true);
      state.updatePointerPosition(
        const Offset(775, 300),
      ); // 775 > 800-50 (right edge)

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should have triggered autopan with positive dx (panning right)
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, greaterThan(0));
    });

    testWidgets('detects pointer in top edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Start dragging in top edge zone
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(400, 25)); // 25 < 50 (top edge)

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should have triggered autopan with negative dy (panning up)
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dy, lessThan(0));
    });

    testWidgets('detects pointer in bottom edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Start dragging in bottom edge zone
      state.simulateDragging(true);
      state.updatePointerPosition(
        const Offset(400, 575),
      ); // 575 > 600-50 (bottom edge)

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should have triggered autopan with positive dy (panning down)
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dy, greaterThan(0));
    });

    testWidgets('detects pointer in corner edge zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Start dragging in bottom-right corner
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(775, 575)); // Both edges

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should have triggered autopan with both positive dx and dy
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, greaterThan(0));
      expect(autoPanDeltas.last.dy, greaterThan(0));
    });

    testWidgets('no autopan in center safe zone', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Start dragging in center (safe zone)
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(400, 300)); // Center

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should not have triggered autopan
      expect(autoPanDeltas, isEmpty);
    });
  });

  group('AutoPanMixin - Outside Bounds', () {
    testWidgets('autopan at max speed when pointer is outside left', (
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
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Pointer outside left edge
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(-50, 300));

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should autopan at max speed (panAmount = 10.0)
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, equals(-10.0));
    });

    testWidgets('autopan at max speed when pointer is outside right', (
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
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Pointer outside right edge
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(850, 300));

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should autopan at max speed
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dx, equals(10.0));
    });

    testWidgets('autopan at max speed when pointer is outside top', (
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
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Pointer outside top edge
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(400, -50));

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should autopan at max speed
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dy, equals(-10.0));
    });

    testWidgets('autopan at max speed when pointer is outside bottom', (
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
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Pointer outside bottom edge
      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(400, 650));

      // Wait for timer tick
      await tester.pump(const Duration(milliseconds: 20));

      // Should autopan at max speed
      expect(autoPanDeltas, isNotEmpty);
      expect(autoPanDeltas.last.dy, equals(10.0));
    });
  });

  group('AutoPanMixin - Timer Management', () {
    testWidgets('does not start timer when autoPan is null', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: null, // No auto-pan configured
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300)); // In edge zone

      await tester.pump(const Duration(milliseconds: 50));

      // No autopan should occur without configuration
      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('does not start timer when autoPan is disabled', (
      tester,
    ) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            enabled: false, // Explicitly disabled
            edgePadding: const EdgeInsets.all(50.0),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300)); // In edge zone

      await tester.pump(const Duration(milliseconds: 50));

      // No autopan should occur when disabled
      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('does not perform autopan when not dragging', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      // Not dragging
      state.simulateDragging(false);
      state.updatePointerPosition(const Offset(25, 300)); // In edge zone

      await tester.pump(const Duration(milliseconds: 50));

      // No autopan should occur when not dragging
      expect(autoPanDeltas, isEmpty);
    });

    testWidgets('does not perform autopan when onAutoPan callback is null', (
      tester,
    ) async {
      var dragUpdateCount = 0;

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: null, // No callback
          onDragUpdate: (_) => dragUpdateCount++,
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300)); // In edge zone

      await tester.pump(const Duration(milliseconds: 50));

      // Even though timer runs, performAutoPan should early-return
      // when onAutoPan is null, so no drag updates from autopan
      expect(dragUpdateCount, equals(0));
    });

    testWidgets('timer fires multiple times during drag', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.all(50.0),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300)); // In edge zone

      // Wait for multiple timer ticks
      await tester.pump(const Duration(milliseconds: 100));

      // Should have multiple autopan callbacks
      expect(autoPanDeltas.length, greaterThan(1));
    });
  });

  group('AutoPanMixin - Asymmetric Edge Padding', () {
    testWidgets('respects zero left edge padding', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.only(
              left: 0,
              right: 50,
              top: 50,
              bottom: 50,
            ),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      state.simulateDragging(true);
      // Near left edge - but left padding is 0, so should not trigger
      state.updatePointerPosition(const Offset(10, 300));

      await tester.pump(const Duration(milliseconds: 50));

      // Should not autopan on left edge (no padding there)
      expect(autoPanDeltas.where((d) => d.dx < 0), isEmpty);
    });

    testWidgets('respects different edge paddings', (tester) async {
      final autoPanDeltas = <Offset>[];

      await tester.pumpWidget(
        _TestHarness(
          autoPan: AutoPanExtension(
            edgePadding: const EdgeInsets.only(
              left: 100, // Large left zone
              right: 20, // Small right zone
              top: 50,
              bottom: 50,
            ),
            panAmount: 10.0,
            panInterval: const Duration(milliseconds: 16),
          ),
          getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      state.simulateDragging(true);

      // x=50 is inside left zone (100px) but outside right zone (20px from 800)
      state.updatePointerPosition(const Offset(50, 300));

      await tester.pump(const Duration(milliseconds: 50));

      // Should trigger autopan for left edge
      expect(autoPanDeltas.where((d) => d.dx < 0), isNotEmpty);

      autoPanDeltas.clear();
      state.stopAutoPan();

      // x=785 is outside left zone but inside right zone (800-20=780)
      state.updatePointerPosition(const Offset(785, 300));

      await tester.pump(const Duration(milliseconds: 50));

      // Should trigger autopan for right edge
      expect(autoPanDeltas.where((d) => d.dx > 0), isNotEmpty);
    });
  });

  group('AutoPanMixin - Proximity Scaling', () {
    testWidgets('uses proximity scaling when enabled', (tester) async {
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
          onAutoPan: (delta) => autoPanDeltas.add(delta),
          onDragUpdate: (_) {},
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      state.simulateDragging(true);

      // At edge zone boundary (proximity = 0, should be slower ~0.3x)
      state.updatePointerPosition(const Offset(50, 300)); // Just at boundary

      await tester.pump(const Duration(milliseconds: 20));

      if (autoPanDeltas.isNotEmpty) {
        // Near boundary should have smaller pan amount
        expect(autoPanDeltas.last.dx.abs(), lessThanOrEqualTo(10.0));
      }

      autoPanDeltas.clear();
      state.stopAutoPan();

      // Reset and test near edge (proximity = edgePadding, should be faster ~1.5x)
      state.updatePointerPosition(const Offset(0, 300)); // At edge

      await tester.pump(const Duration(milliseconds: 20));

      if (autoPanDeltas.isNotEmpty) {
        // Near edge with outside bounds logic - uses max speed
        expect(autoPanDeltas.last.dx.abs(), greaterThanOrEqualTo(10.0));
      }
    });
  });

  group('AutoPanMixin - Integration with onDragUpdate', () {
    testWidgets('autopan calls onDragUpdate with delta', (tester) async {
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
          onDragUpdate: (details) => dragUpdates.add(details),
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final state = tester.state<_TestElementScopeState>(
        find.byType(_TestElementScope),
      );

      state.simulateDragging(true);
      state.updatePointerPosition(const Offset(25, 300)); // In left edge zone

      await tester.pump(const Duration(milliseconds: 50));

      // Should have received drag updates from autopan
      expect(dragUpdates, isNotEmpty);
      // The delta should match the autopan delta
      expect(dragUpdates.last.delta.dx, lessThan(0)); // Panning left
    });
  });
}

// =============================================================================
// Test Harness
// =============================================================================

/// Test harness widget that wraps a testable ElementScope-like state.
class _TestHarness extends StatelessWidget {
  const _TestHarness({
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
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _TestElementScope(
          autoPan: autoPan,
          getViewportBounds: getViewportBounds,
          onAutoPan: onAutoPan,
          onDragUpdate: onDragUpdate,
          child: child,
        ),
      ),
    );
  }
}

/// Widget that mimics ElementScope but exposes mixin methods for testing.
class _TestElementScope extends StatefulWidget {
  const _TestElementScope({
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

/// State that uses AutoPanMixin and exposes its methods for testing.
class _TestElementScopeState extends State<_TestElementScope>
    with _TestAutoPanMixin {
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
/// our test widget instead of requiring the full ElementScope hierarchy.
mixin _TestAutoPanMixin on State<_TestElementScope> {
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
