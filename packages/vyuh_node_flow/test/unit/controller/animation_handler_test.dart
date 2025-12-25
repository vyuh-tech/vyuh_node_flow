/// Unit tests for the viewport animation handler lifecycle.
///
/// These tests verify that:
/// - Token-based handler registration works correctly
/// - Handler survives widget recreation (race condition fix)
/// - Old widget dispose doesn't clear new widget's handler
/// - Animation methods work after widget recreation
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
  // Token-Based Handler Registration
  // ===========================================================================

  group('Token-Based Handler Registration', () {
    test('setAnimateToHandler with token registers handler', () {
      final controller = createTestController();
      var handlerCalled = false;

      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        handlerCalled = true;
      }, token: Object());

      controller.animateToViewport(const GraphViewport(x: 0, y: 0, zoom: 1));
      expect(handlerCalled, isTrue);
    });

    test('clearAnimateToHandler with matching token clears handler', () {
      final controller = createTestController();
      final token = Object();
      var handlerCalled = false;

      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        handlerCalled = true;
      }, token: token);

      controller.clearAnimateToHandler(token);
      controller.animateToViewport(const GraphViewport(x: 0, y: 0, zoom: 1));

      expect(handlerCalled, isFalse);
    });

    test(
      'clearAnimateToHandler with non-matching token does NOT clear handler',
      () {
        final controller = createTestController();
        final token1 = Object();
        final token2 = Object();
        var handlerCalled = false;

        controller.setAnimateToHandler((
          target, {
          Duration duration = Duration.zero,
          Curve curve = Curves.linear,
        }) {
          handlerCalled = true;
        }, token: token1);

        // Try to clear with different token - should NOT clear
        controller.clearAnimateToHandler(token2);
        controller.animateToViewport(const GraphViewport(x: 0, y: 0, zoom: 1));

        expect(handlerCalled, isTrue);
      },
    );

    test('new handler replaces old handler and updates token', () {
      final controller = createTestController();
      final token1 = Object();
      final token2 = Object();
      var handler1Called = false;
      var handler2Called = false;

      // Set first handler
      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        handler1Called = true;
      }, token: token1);

      // Set second handler with different token
      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        handler2Called = true;
      }, token: token2);

      controller.animateToViewport(const GraphViewport(x: 0, y: 0, zoom: 1));

      expect(handler1Called, isFalse);
      expect(handler2Called, isTrue);
    });

    test('old token cannot clear after new handler is set', () {
      final controller = createTestController();
      final token1 = Object();
      final token2 = Object();
      var handler2Called = false;

      // Set first handler
      controller.setAnimateToHandler(
        (
          target, {
          Duration duration = Duration.zero,
          Curve curve = Curves.linear,
        }) {},
        token: token1,
      );

      // Set second handler with different token
      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        handler2Called = true;
      }, token: token2);

      // Try to clear with old token - should NOT clear
      controller.clearAnimateToHandler(token1);
      controller.animateToViewport(const GraphViewport(x: 0, y: 0, zoom: 1));

      expect(handler2Called, isTrue);
    });
  });

  // ===========================================================================
  // Widget Recreation Simulation
  // ===========================================================================

  group('Widget Recreation Simulation', () {
    test(
      'simulates widget recreation: new handler set, then old dispose clears',
      () {
        final controller = createTestController();
        final oldWidgetToken = Object();
        final newWidgetToken = Object();
        var newHandlerCalled = false;

        // Simulate: Old widget sets handler in initState
        controller.setAnimateToHandler(
          (
            target, {
            Duration duration = Duration.zero,
            Curve curve = Curves.linear,
          }) {},
          token: oldWidgetToken,
        );

        // Simulate: New widget sets handler in initState (happens BEFORE old dispose)
        controller.setAnimateToHandler((
          target, {
          Duration duration = Duration.zero,
          Curve curve = Curves.linear,
        }) {
          newHandlerCalled = true;
        }, token: newWidgetToken);

        // Simulate: Old widget clears handler in dispose (happens AFTER new initState)
        // This should NOT clear the new handler because tokens don't match
        controller.clearAnimateToHandler(oldWidgetToken);

        // Animation should still work via new handler
        controller.animateToViewport(const GraphViewport(x: 0, y: 0, zoom: 1));

        expect(newHandlerCalled, isTrue);
      },
    );

    test('multiple widget recreations maintain handler', () {
      final controller = createTestController();
      final tokens = [Object(), Object(), Object()];
      var lastHandlerIndex = -1;

      // Simulate multiple widget recreations
      for (var i = 0; i < tokens.length; i++) {
        // New widget sets handler
        final currentIndex = i;
        controller.setAnimateToHandler((
          target, {
          Duration duration = Duration.zero,
          Curve curve = Curves.linear,
        }) {
          lastHandlerIndex = currentIndex;
        }, token: tokens[i]);

        // Old widget (if any) tries to clear
        if (i > 0) {
          controller.clearAnimateToHandler(tokens[i - 1]);
        }
      }

      controller.animateToViewport(const GraphViewport(x: 0, y: 0, zoom: 1));

      // Should be the last handler
      expect(lastHandlerIndex, equals(tokens.length - 1));
    });
  });

  // ===========================================================================
  // Animation Methods After Recreation
  // ===========================================================================

  group('Animation Methods Work After Recreation', () {
    test('animateToNode works after simulated widget recreation', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      // Add a node
      final node = createTestNode(
        id: 'test-node',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      final oldToken = Object();
      final newToken = Object();
      GraphViewport? capturedTarget;

      // Simulate old widget
      controller.setAnimateToHandler(
        (
          target, {
          Duration duration = Duration.zero,
          Curve curve = Curves.linear,
        }) {},
        token: oldToken,
      );

      // Simulate new widget
      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        capturedTarget = target;
      }, token: newToken);

      // Old widget dispose
      controller.clearAnimateToHandler(oldToken);

      // animateToNode should work
      controller.animateToNode('test-node');

      expect(capturedTarget, isNotNull);
    });

    test('animateToPosition works after simulated widget recreation', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      final oldToken = Object();
      final newToken = Object();
      GraphViewport? capturedTarget;

      // Simulate old widget
      controller.setAnimateToHandler(
        (
          target, {
          Duration duration = Duration.zero,
          Curve curve = Curves.linear,
        }) {},
        token: oldToken,
      );

      // Simulate new widget
      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        capturedTarget = target;
      }, token: newToken);

      // Old widget dispose
      controller.clearAnimateToHandler(oldToken);

      // animateToPosition should work
      controller.animateToPosition(const GraphOffset(Offset(200, 150)));

      expect(capturedTarget, isNotNull);
    });

    test('animateToBounds works after simulated widget recreation', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      final oldToken = Object();
      final newToken = Object();
      GraphViewport? capturedTarget;

      // Simulate old widget
      controller.setAnimateToHandler(
        (
          target, {
          Duration duration = Duration.zero,
          Curve curve = Curves.linear,
        }) {},
        token: oldToken,
      );

      // Simulate new widget
      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        capturedTarget = target;
      }, token: newToken);

      // Old widget dispose
      controller.clearAnimateToHandler(oldToken);

      // animateToBounds should work
      controller.animateToBounds(
        const GraphRect(Rect.fromLTWH(0, 0, 400, 300)),
      );

      expect(capturedTarget, isNotNull);
    });

    test('animateToScale works after simulated widget recreation', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      final oldToken = Object();
      final newToken = Object();
      GraphViewport? capturedTarget;

      // Simulate old widget
      controller.setAnimateToHandler(
        (
          target, {
          Duration duration = Duration.zero,
          Curve curve = Curves.linear,
        }) {},
        token: oldToken,
      );

      // Simulate new widget
      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        capturedTarget = target;
      }, token: newToken);

      // Old widget dispose
      controller.clearAnimateToHandler(oldToken);

      // animateToScale should work
      controller.animateToScale(1.5);

      expect(capturedTarget, isNotNull);
      expect(capturedTarget!.zoom, equals(1.5));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('clearAnimateToHandler with null handler is safe', () {
      final controller = createTestController();
      final token = Object();

      // No handler set, clear should not throw
      expect(() => controller.clearAnimateToHandler(token), returnsNormally);
    });

    test('setAnimateToHandler with null handler clears handler', () {
      final controller = createTestController();
      final token = Object();
      var handlerCalled = false;

      controller.setAnimateToHandler((
        target, {
        Duration duration = Duration.zero,
        Curve curve = Curves.linear,
      }) {
        handlerCalled = true;
      }, token: token);

      // Set null handler
      controller.setAnimateToHandler(null, token: token);
      controller.animateToViewport(const GraphViewport(x: 0, y: 0, zoom: 1));

      expect(handlerCalled, isFalse);
    });

    test('animation methods gracefully handle null handler', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      // Add a node for animateToNode
      final node = createTestNode(id: 'test-node');
      controller.addNode(node);

      // No handler set - should not throw
      expect(
        () => controller.animateToViewport(
          const GraphViewport(x: 0, y: 0, zoom: 1),
        ),
        returnsNormally,
      );
      expect(() => controller.animateToNode('test-node'), returnsNormally);
      expect(
        () => controller.animateToPosition(const GraphOffset(Offset.zero)),
        returnsNormally,
      );
      expect(
        () => controller.animateToBounds(
          const GraphRect(Rect.fromLTWH(0, 0, 100, 100)),
        ),
        returnsNormally,
      );
      expect(() => controller.animateToScale(1.5), returnsNormally);
    });
  });
}
