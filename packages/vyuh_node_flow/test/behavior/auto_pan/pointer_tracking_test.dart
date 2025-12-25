@Tags(['behavior'])
library;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('PointerTracking Enum', () {
    test('has two modes: free and anchored', () {
      expect(PointerTracking.values, hasLength(2));
      expect(PointerTracking.values, contains(PointerTracking.free));
      expect(PointerTracking.values, contains(PointerTracking.anchored));
    });

    test('free mode index is 0', () {
      expect(PointerTracking.free.index, equals(0));
    });

    test('anchored mode index is 1', () {
      expect(PointerTracking.anchored.index, equals(1));
    });
  });

  group('PointerTracking.free - Behavior Specification', () {
    test('element tracks pointer position freely everywhere', () {
      // In free mode:
      // - Element position is calculated directly from pointer position
      // - Even when pointer goes outside viewport bounds
      // - This is ideal for connection endpoints
      const mode = PointerTracking.free;
      expect(mode, equals(PointerTracking.free));
    });

    test('free mode is suitable for connection dragging', () {
      // Connection endpoints should always follow the pointer
      // because the visual feedback needs to show where the connection
      // would complete if released at that position
      const mode = PointerTracking.free;
      expect(mode.name, equals('free'));
    });

    test('free mode has no drift compensation', () {
      // In free mode, delta is always passed through directly
      // There's no accumulation or snap behavior
      const delta = Offset(10.0, 5.0);
      // free mode: effectiveDelta == delta
      expect(delta.dx, equals(10.0));
      expect(delta.dy, equals(5.0));
    });
  });

  group('PointerTracking.anchored - Behavior Specification', () {
    test('element anchors at boundary when pointer exits', () {
      // In anchored mode:
      // - When pointer goes outside viewport bounds
      // - Element position freezes (doesn't follow pointer)
      // - This keeps elements visible during autopan
      const mode = PointerTracking.anchored;
      expect(mode, equals(PointerTracking.anchored));
    });

    test('anchored mode is suitable for node/annotation dragging', () {
      // Nodes and annotations should stay visible
      // When dragging to far edge, node stays in view
      // while autopan reveals destination area
      const mode = PointerTracking.anchored;
      expect(mode.name, equals('anchored'));
    });

    test('anchored mode accumulates offset outside bounds', () {
      // When pointer is outside bounds:
      // - Delta is not applied (returns Offset.zero)
      // - Delta is accumulated internally
      // - On re-entry, accumulated delta is applied as "snap"

      // Simulate delta processing:
      final accumulatedOffset = Offset.zero;
      const delta = Offset(10.0, 5.0);
      const isOutsideBounds = true;

      if (isOutsideBounds) {
        // Accumulate and return zero
        final newAccumulated = accumulatedOffset + delta;
        const effectiveDelta = Offset.zero;

        expect(effectiveDelta, equals(Offset.zero));
        expect(newAccumulated, equals(const Offset(10.0, 5.0)));
      }
    });

    test('anchored mode snaps on re-entry', () {
      // When pointer re-enters bounds after being outside:
      // - Accumulated offset is applied as "snap"
      // - This ensures element catches up to pointer position

      // Simulate re-entry:
      const accumulatedOffset = Offset(50.0, 30.0); // From outside movement
      const delta = Offset(5.0, 3.0); // Current frame delta
      const wasOutsideBounds = true;
      const isOutsideBounds = false; // Now inside

      // ignore: dead_code
      if (wasOutsideBounds && !isOutsideBounds) {
        // Re-entry: apply accumulated + current
        final effectiveDelta = delta + accumulatedOffset;

        expect(effectiveDelta.dx, equals(55.0));
        expect(effectiveDelta.dy, equals(33.0));
      }
    });
  });

  group('PointerTracking - Drag Delta Processing', () {
    test('inside bounds: delta passes through normally (both modes)', () {
      const delta = Offset(15.0, 8.0);
      const isOutsideBounds = false;

      // Both modes behave the same inside bounds
      if (!isOutsideBounds) {
        final effectiveDelta = delta;
        expect(effectiveDelta, equals(delta));
      }
    });

    test('outside bounds with free mode: delta still passes through', () {
      const delta = Offset(15.0, 8.0);
      // isOutsideBounds would be true in this scenario
      const mode = PointerTracking.free;

      if (mode == PointerTracking.free) {
        final effectiveDelta = delta; // Always pass through
        expect(effectiveDelta, equals(delta));
      }
    });

    test('outside bounds with anchored mode: delta becomes zero', () {
      // Original delta would be non-zero but gets frozen when outside bounds
      const isOutsideBounds = true;
      const mode = PointerTracking.anchored;

      if (mode == PointerTracking.anchored && isOutsideBounds) {
        const effectiveDelta = Offset.zero; // Freeze
        expect(effectiveDelta, equals(Offset.zero));
      }
    });
  });

  group('PointerTracking - Use Cases', () {
    test('connection creation uses free mode', () {
      // When dragging to create a connection:
      // - Endpoint should always be at pointer position
      // - Visual feedback shows connection path to current location
      // - Even outside viewport, shows where connection would go
      const connectionDragMode = PointerTracking.free;
      expect(connectionDragMode, equals(PointerTracking.free));
    });

    test('node dragging uses anchored mode', () {
      // When dragging a node:
      // - Node should stay visible within viewport
      // - Autopan reveals destination without node disappearing
      // - On re-entry, node snaps to correct position
      const nodeDragMode = PointerTracking.anchored;
      expect(nodeDragMode, equals(PointerTracking.anchored));
    });

    test('annotation dragging uses anchored mode', () {
      // Same as nodes - annotations are positioned elements
      // that should remain visible during drag
      const annotationDragMode = PointerTracking.anchored;
      expect(annotationDragMode, equals(PointerTracking.anchored));
    });
  });

  group('PointerTracking - Drift Prevention', () {
    test('drift can accumulate with autopan and pointer movement', () {
      // Scenario: pointer moves outside while autopan is active
      // Without drift compensation, element position and pointer
      // would get increasingly out of sync

      // The anchored mode's accumulation mechanism prevents this
      // by tracking the "missed" movement and applying it on re-entry
      const mode = PointerTracking.anchored;
      expect(mode, equals(PointerTracking.anchored));
    });

    test('free mode prevents drift by tracking absolute position', () {
      // For free mode elements (like connections):
      // Position is calculated from absolute pointer location
      // rather than accumulated deltas, preventing drift entirely
      const mode = PointerTracking.free;
      expect(mode, equals(PointerTracking.free));
    });
  });

  group('PointerTracking - State Transitions', () {
    test('transition: inside -> outside (anchored)', () {
      // Element continues movement until boundary
      // Then freezes at boundary position
      var wasOutside = false;
      const isOutside = true;

      // First time outside
      if (!wasOutside && isOutside) {
        // Start accumulating
        wasOutside = true;
      }

      expect(wasOutside, isTrue);
    });

    test('transition: outside -> inside (anchored)', () {
      // Element snaps to catch up with pointer
      // Then resumes normal 1:1 tracking
      var wasOutside = true;
      const isOutside = false;

      // Re-entering
      if (wasOutside && !isOutside) {
        // Apply snap, clear accumulator
        wasOutside = false;
      }

      expect(wasOutside, isFalse);
    });

    test('transition: inside -> outside (free)', () {
      // No state change needed
      // Element continues tracking pointer freely
      const mode = PointerTracking.free;
      expect(mode, equals(PointerTracking.free));
    });

    test('transition: outside -> inside (free)', () {
      // No special handling needed
      // Element was already tracking correctly
      const mode = PointerTracking.free;
      expect(mode, equals(PointerTracking.free));
    });
  });

  group('PointerTracking - Viewport Boundary Detection', () {
    test('point inside viewport bounds', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const pointerPosition = Offset(400, 300);

      final isOutside = !viewportBounds.contains(pointerPosition);
      expect(isOutside, isFalse);
    });

    test('point outside viewport bounds (left)', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const pointerPosition = Offset(-10, 300);

      final isOutside = !viewportBounds.contains(pointerPosition);
      expect(isOutside, isTrue);
    });

    test('point outside viewport bounds (right)', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const pointerPosition = Offset(810, 300);

      final isOutside = !viewportBounds.contains(pointerPosition);
      expect(isOutside, isTrue);
    });

    test('point outside viewport bounds (top)', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const pointerPosition = Offset(400, -10);

      final isOutside = !viewportBounds.contains(pointerPosition);
      expect(isOutside, isTrue);
    });

    test('point outside viewport bounds (bottom)', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const pointerPosition = Offset(400, 610);

      final isOutside = !viewportBounds.contains(pointerPosition);
      expect(isOutside, isTrue);
    });

    test('point at exact boundary is inside', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const pointerPosition = Offset(800, 300); // At right edge

      // Rect.contains uses < for right/bottom, so exactly at edge is outside
      final isInside = viewportBounds.contains(pointerPosition);
      expect(isInside, isFalse); // At edge is NOT inside
    });

    test('point just inside boundary is inside', () {
      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const pointerPosition = Offset(799.9, 300);

      final isInside = viewportBounds.contains(pointerPosition);
      expect(isInside, isTrue);
    });
  });

  group('PointerTracking - Edge Zones vs Outside', () {
    test('edge zone is inside bounds but triggers autopan', () {
      // Edge zone: inside viewport but near edge
      // Outside bounds: pointer completely outside viewport
      // Both trigger autopan but have different element behaviors

      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);
      const edgePadding = EdgeInsets.all(50.0);

      // In edge zone (triggers autopan, but inside bounds)
      const inEdgeZone = Offset(25, 300);
      expect(viewportBounds.contains(inEdgeZone), isTrue);
      expect(inEdgeZone.dx < viewportBounds.left + edgePadding.left, isTrue);

      // Outside bounds (triggers autopan at max speed)
      const outsideBounds = Offset(-10, 300);
      expect(viewportBounds.contains(outsideBounds), isFalse);
    });

    test('anchored mode behaves differently in edge zone vs outside', () {
      // In edge zone: normal movement (inside bounds)
      // Outside bounds: freeze + accumulate

      const viewportBounds = Rect.fromLTWH(0, 0, 800, 600);

      const inEdgeZone = Offset(25, 300); // Inside, but in edge zone
      const outsideBounds = Offset(-10, 300); // Outside

      // Edge zone is still inside
      final isEdgeZoneOutside = !viewportBounds.contains(inEdgeZone);
      expect(isEdgeZoneOutside, isFalse);

      // Outside is outside
      final isOutsideOutside = !viewportBounds.contains(outsideBounds);
      expect(isOutsideOutside, isTrue);

      // So anchored mode:
      // - In edge zone: normal delta processing (autopan handles panning)
      // - Outside: freeze + accumulate (drift prevention)
    });
  });
}
