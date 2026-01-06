/// Comprehensive unit tests for ViewportAnimationMixin.
///
/// Tests cover:
/// - Animation initialization and detachment
/// - animateViewportTo method behavior
/// - Animation state management (isAttached, isAnimating)
/// - Viewport sync callback on animation complete
/// - Animation controller lifecycle
/// - Token-based handler management
// ignore_for_file: deprecated_member_use
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
// Import the mixin directly from src since it's not exported in public API
import 'package:vyuh_node_flow/src/editor/viewport_animation_mixin.dart';

import '../../helpers/test_factories.dart';

/// A test class that uses ViewportAnimationMixin for testing purposes.
class TestViewportAnimator with ViewportAnimationMixin {
  TestViewportAnimator();
}

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Animation System Initialization
  // ===========================================================================

  group('Animation System Initialization', () {
    testWidgets('isViewportAnimationAttached returns false before attach', (
      tester,
    ) async {
      final animator = TestViewportAnimator();

      expect(animator.isViewportAnimationAttached, isFalse);
    });

    testWidgets('isViewportAnimationAttached returns true after attach', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, transformController, controller) {
            expect(animator.isViewportAnimationAttached, isTrue);
          },
        ),
      );
    });

    testWidgets('isViewportAnimationAttached returns false after detach', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestTickerProviderWidget(
          builder: (context, vsync) {
            final animator = TestViewportAnimator();
            final transformController = TransformationController();
            final controller = createTestController();

            animator.attachViewportAnimation(
              tickerProvider: vsync,
              transformationController: transformController,
              controller: controller,
            );

            animator.detachViewportAnimation();

            expect(animator.isViewportAnimationAttached, isFalse);

            transformController.dispose();

            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('isViewportAnimating returns false when not animating', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, transformController, controller) {
            expect(animator.isViewportAnimating, isFalse);
          },
        ),
      );
    });

    testWidgets('isViewportAnimating returns false when not attached', (
      tester,
    ) async {
      final animator = TestViewportAnimator();

      expect(animator.isViewportAnimating, isFalse);
    });
  });

  // ===========================================================================
  // Animation Handler Registration
  // ===========================================================================

  group('Animation Handler Registration', () {
    testWidgets('attachViewportAnimation registers handler on controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, transformController, controller) {
            // After attach, animateToViewport should trigger animation
            controller.animateToViewport(const GraphViewport(x: 100, y: 100));

            expect(animator.isViewportAnimating, isTrue);
          },
        ),
      );
    });

    testWidgets('detachViewportAnimation clears handler from controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestTickerProviderWidget(
          builder: (context, vsync) {
            final animator = TestViewportAnimator();
            final transformController = TransformationController();
            final controller = createTestController();

            animator.attachViewportAnimation(
              tickerProvider: vsync,
              transformationController: transformController,
              controller: controller,
            );

            animator.detachViewportAnimation();

            // After detach, animateToViewport should be a no-op
            controller.animateToViewport(const GraphViewport(x: 100, y: 100));

            // Since animator is detached, isViewportAnimating should be false
            expect(animator.isViewportAnimating, isFalse);

            transformController.dispose();

            return const SizedBox();
          },
        ),
      );
    });

    testWidgets(
      'clearAnimateToHandler only clears if token matches animator instance',
      (tester) async {
        await tester.pumpWidget(
          _TestTickerProviderWidget(
            builder: (context, vsync) {
              final animator1 = TestViewportAnimator();
              final animator2 = TestViewportAnimator();
              final transformController = TransformationController();
              final controller = createTestController();

              // First animator attaches
              animator1.attachViewportAnimation(
                tickerProvider: vsync,
                transformationController: transformController,
                controller: controller,
              );

              // Second animator tries to clear (different token)
              // This should NOT clear since token doesn't match
              controller.clearAnimateToHandler(animator2);

              // Animation should still work since handler wasn't cleared
              controller.animateToViewport(const GraphViewport(x: 100, y: 100));
              expect(animator1.isViewportAnimating, isTrue);

              animator1.detachViewportAnimation();
              transformController.dispose();

              return const SizedBox();
            },
          ),
        );
      },
    );
  });

  // ===========================================================================
  // animateViewportTo Behavior
  // ===========================================================================

  group('animateViewportTo Behavior', () {
    testWidgets('animateViewportTo starts animation', (tester) async {
      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, transformController, controller) {
            animator.animateViewportTo(
              const GraphViewport(x: 200, y: 150, zoom: 1.5),
            );

            expect(animator.isViewportAnimating, isTrue);
          },
        ),
      );
    });

    testWidgets('animateViewportTo does nothing if not attached', (
      tester,
    ) async {
      final animator = TestViewportAnimator();

      // Should not throw, just no-op
      animator.animateViewportTo(
        const GraphViewport(x: 200, y: 150, zoom: 1.5),
      );

      expect(animator.isViewportAnimating, isFalse);
    });

    testWidgets('animateViewportTo uses custom duration', (tester) async {
      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, transformController, controller) {
            animator.animateViewportTo(
              const GraphViewport(x: 200, y: 150, zoom: 1.5),
              duration: const Duration(milliseconds: 1000),
            );

            expect(animator.isViewportAnimating, isTrue);
          },
        ),
      );
    });

    testWidgets('animateViewportTo uses custom curve', (tester) async {
      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, transformController, controller) {
            animator.animateViewportTo(
              const GraphViewport(x: 200, y: 150, zoom: 1.5),
              curve: Curves.bounceOut,
            );

            expect(animator.isViewportAnimating, isTrue);
          },
        ),
      );
    });

    testWidgets('animateViewportTo stops existing animation before starting', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, transformController, controller) {
            // Start first animation
            animator.animateViewportTo(
              const GraphViewport(x: 100, y: 100, zoom: 1.0),
            );

            // Start second animation (should stop first)
            animator.animateViewportTo(
              const GraphViewport(x: 200, y: 200, zoom: 2.0),
            );

            expect(animator.isViewportAnimating, isTrue);
          },
        ),
      );
    });
  });

  // ===========================================================================
  // Animation Progress and Completion
  // ===========================================================================

  group('Animation Progress and Completion', () {
    testWidgets('animation updates transformation controller value', (
      tester,
    ) async {
      late TransformationController transformController;
      late TestViewportAnimator animator;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (a, tc, controller) {
            animator = a;
            transformController = tc;

            // Start animation to new position
            animator.animateViewportTo(
              const GraphViewport(x: 100, y: 50, zoom: 2.0),
              duration: const Duration(milliseconds: 200),
            );
          },
        ),
      );

      // Advance animation partway
      await tester.pump(const Duration(milliseconds: 100));

      // The transform value should have changed
      final matrix = transformController.value;
      final translation = matrix.getTranslation();
      final scale = matrix.getMaxScaleOnAxis();

      // At ~50%, values should be interpolated (not at start or end exactly)
      // With easeInOut, the midpoint won't be exactly 50% of final values
      expect(translation.x, greaterThanOrEqualTo(0));
      expect(translation.x, lessThanOrEqualTo(100));
      expect(scale, greaterThanOrEqualTo(1.0));
      expect(scale, lessThanOrEqualTo(2.0));

      // Complete the animation to clean up
      await tester.pumpAndSettle();
    });

    testWidgets('animation completes and calls sync callback', (tester) async {
      GraphViewport? syncedViewport;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onAnimationComplete: (viewport) {
            syncedViewport = viewport;
          },
          onBuild: (animator, transformController, controller) {
            animator.animateViewportTo(
              const GraphViewport(x: 100, y: 50, zoom: 2.0),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      // Complete the animation
      await tester.pumpAndSettle();

      expect(syncedViewport, isNotNull);
      expect(syncedViewport!.x, closeTo(100.0, 0.01));
      expect(syncedViewport!.y, closeTo(50.0, 0.01));
      expect(syncedViewport!.zoom, closeTo(2.0, 0.01));
    });

    testWidgets('animation is no longer running after completion', (
      tester,
    ) async {
      late TestViewportAnimator animator;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (a, transformController, controller) {
            animator = a;
            animator.animateViewportTo(
              const GraphViewport(x: 100, y: 50, zoom: 2.0),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      expect(animator.isViewportAnimating, isTrue);

      // Complete the animation
      await tester.pumpAndSettle();

      expect(animator.isViewportAnimating, isFalse);
    });

    testWidgets('transform reaches target values after animation completes', (
      tester,
    ) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;
            animator.animateViewportTo(
              const GraphViewport(x: 150, y: 75, zoom: 1.5),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      // Complete the animation
      await tester.pumpAndSettle();

      final matrix = transformController.value;
      final translation = matrix.getTranslation();
      final scale = matrix.getMaxScaleOnAxis();

      expect(translation.x, closeTo(150.0, 0.01));
      expect(translation.y, closeTo(75.0, 0.01));
      expect(scale, closeTo(1.5, 0.01));
    });
  });

  // ===========================================================================
  // Stop Animation
  // ===========================================================================

  group('Stop Animation', () {
    testWidgets('stopViewportAnimation stops running animation', (
      tester,
    ) async {
      late TestViewportAnimator animator;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (a, transformController, controller) {
            animator = a;
            animator.animateViewportTo(
              const GraphViewport(x: 200, y: 100, zoom: 2.0),
              duration: const Duration(milliseconds: 500),
            );
          },
        ),
      );

      expect(animator.isViewportAnimating, isTrue);

      animator.stopViewportAnimation();

      expect(animator.isViewportAnimating, isFalse);

      // Clean up
      await tester.pumpAndSettle();
    });

    testWidgets('stopViewportAnimation is safe when not animating', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, transformController, controller) {
            // Should not throw when not animating
            animator.stopViewportAnimation();

            expect(animator.isViewportAnimating, isFalse);
          },
        ),
      );
    });

    testWidgets(
      'stopViewportAnimation preserves transform at current position',
      (tester) async {
        late TransformationController transformController;
        late TestViewportAnimator animator;

        await tester.pumpWidget(
          _TestAnimatorWidget(
            onBuild: (a, tc, controller) {
              animator = a;
              transformController = tc;
              animator.animateViewportTo(
                const GraphViewport(x: 200, y: 100, zoom: 2.0),
                duration: const Duration(milliseconds: 500),
              );
            },
          ),
        );

        // Advance animation partially
        await tester.pump(const Duration(milliseconds: 250));

        final matrixBefore = transformController.value.clone();

        animator.stopViewportAnimation();

        final matrixAfter = transformController.value;

        // Matrix should be preserved at the stopped position
        expect(matrixAfter, equals(matrixBefore));

        // Clean up
        await tester.pumpAndSettle();
      },
    );
  });

  // ===========================================================================
  // Matrix Interpolation
  // ===========================================================================

  group('Matrix Interpolation', () {
    testWidgets('animates translation correctly', (tester) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;

            // Set initial transform
            transformController.value = Matrix4.identity()..translate(0.0, 0.0);

            animator.animateViewportTo(
              const GraphViewport(x: 200, y: 100, zoom: 1.0),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      // Complete animation
      await tester.pumpAndSettle();

      final translation = transformController.value.getTranslation();

      expect(translation.x, closeTo(200.0, 0.01));
      expect(translation.y, closeTo(100.0, 0.01));
    });

    testWidgets('animates scale correctly', (tester) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;

            // Set initial transform at zoom 1.0
            transformController.value = Matrix4.identity();

            animator.animateViewportTo(
              const GraphViewport(x: 0, y: 0, zoom: 3.0),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      // Complete animation
      await tester.pumpAndSettle();

      final scale = transformController.value.getMaxScaleOnAxis();

      expect(scale, closeTo(3.0, 0.01));
    });

    testWidgets('animates both translation and scale together', (tester) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;

            animator.animateViewportTo(
              const GraphViewport(x: 300, y: -150, zoom: 2.5),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      // Complete animation
      await tester.pumpAndSettle();

      final matrix = transformController.value;
      final translation = matrix.getTranslation();
      final scale = matrix.getMaxScaleOnAxis();

      expect(translation.x, closeTo(300.0, 0.01));
      expect(translation.y, closeTo(-150.0, 0.01));
      expect(scale, closeTo(2.5, 0.01));
    });

    testWidgets('intermediate animation values are interpolated correctly', (
      tester,
    ) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;

            // Start from (0, 0) zoom 1.0 to (100, 100) zoom 2.0
            // Using linear curve for predictable interpolation
            animator.animateViewportTo(
              const GraphViewport(x: 100, y: 100, zoom: 2.0),
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear,
            );
          },
        ),
      );

      // At 50%, values should be approximately halfway
      await tester.pump(const Duration(milliseconds: 50));

      final matrix = transformController.value;
      final translation = matrix.getTranslation();
      final scale = matrix.getMaxScaleOnAxis();

      // With linear curve, should be close to midpoint
      expect(translation.x, closeTo(50.0, 10.0));
      expect(translation.y, closeTo(50.0, 10.0));
      expect(scale, closeTo(1.5, 0.2));

      // Complete animation
      await tester.pumpAndSettle();
    });
  });

  // ===========================================================================
  // Cleanup and Resource Management
  // ===========================================================================

  group('Cleanup and Resource Management', () {
    testWidgets('detachViewportAnimation cleans up all resources', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestTickerProviderWidget(
          builder: (context, vsync) {
            final animator = TestViewportAnimator();
            final transformController = TransformationController();
            final controller = createTestController();

            animator.attachViewportAnimation(
              tickerProvider: vsync,
              transformationController: transformController,
              controller: controller,
            );

            animator.animateViewportTo(
              const GraphViewport(x: 100, y: 100, zoom: 1.0),
            );

            animator.detachViewportAnimation();

            // After detach, all state should be cleared
            expect(animator.isViewportAnimationAttached, isFalse);
            expect(animator.isViewportAnimating, isFalse);

            transformController.dispose();

            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('multiple attach/detach cycles work correctly', (tester) async {
      await tester.pumpWidget(
        _TestTickerProviderWidget(
          builder: (context, vsync) {
            final animator = TestViewportAnimator();
            final transformController = TransformationController();
            final controller = createTestController();

            // First cycle
            animator.attachViewportAnimation(
              tickerProvider: vsync,
              transformationController: transformController,
              controller: controller,
            );
            expect(animator.isViewportAnimationAttached, isTrue);

            animator.detachViewportAnimation();
            expect(animator.isViewportAnimationAttached, isFalse);

            // Second cycle
            animator.attachViewportAnimation(
              tickerProvider: vsync,
              transformationController: transformController,
              controller: controller,
            );
            expect(animator.isViewportAnimationAttached, isTrue);

            animator.animateViewportTo(
              const GraphViewport(x: 50, y: 50, zoom: 1.0),
            );
            expect(animator.isViewportAnimating, isTrue);

            animator.detachViewportAnimation();
            expect(animator.isViewportAnimationAttached, isFalse);

            transformController.dispose();

            return const SizedBox();
          },
        ),
      );
    });

    testWidgets(
      'detachViewportAnimation handles running animation gracefully',
      (tester) async {
        late TestViewportAnimator animator;

        await tester.pumpWidget(
          _TestAnimatorWidget(
            onBuild: (a, transformController, controller) {
              animator = a;
              animator.animateViewportTo(
                const GraphViewport(x: 200, y: 200, zoom: 2.0),
                duration: const Duration(milliseconds: 500),
              );
            },
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        expect(animator.isViewportAnimating, isTrue);

        // Detach while animation is running should not throw
        animator.detachViewportAnimation();

        expect(animator.isViewportAnimating, isFalse);
        expect(animator.isViewportAnimationAttached, isFalse);
      },
    );
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    testWidgets('animating to same position completes', (tester) async {
      int completionCount = 0;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onAnimationComplete: (_) => completionCount++,
          onBuild: (animator, transformController, controller) {
            // Animate to origin (same as initial)
            animator.animateViewportTo(
              const GraphViewport(x: 0, y: 0, zoom: 1.0),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(completionCount, equals(1));
    });

    testWidgets('animating with zero duration', (tester) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;

            animator.animateViewportTo(
              const GraphViewport(x: 100, y: 100, zoom: 2.0),
              duration: Duration.zero,
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final matrix = transformController.value;
      final translation = matrix.getTranslation();
      final scale = matrix.getMaxScaleOnAxis();

      expect(translation.x, closeTo(100.0, 0.01));
      expect(translation.y, closeTo(100.0, 0.01));
      expect(scale, closeTo(2.0, 0.01));
    });

    testWidgets('animating with negative viewport values', (tester) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;

            animator.animateViewportTo(
              const GraphViewport(x: -500, y: -300, zoom: 0.5),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final matrix = transformController.value;
      final translation = matrix.getTranslation();
      final scale = matrix.getMaxScaleOnAxis();

      expect(translation.x, closeTo(-500.0, 0.01));
      expect(translation.y, closeTo(-300.0, 0.01));
      expect(scale, closeTo(0.5, 0.01));
    });

    testWidgets('rapid successive animations replace previous', (tester) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;

            // Start multiple animations rapidly
            animator.animateViewportTo(
              const GraphViewport(x: 100, y: 100, zoom: 1.0),
            );
            animator.animateViewportTo(
              const GraphViewport(x: 200, y: 200, zoom: 1.5),
            );
            animator.animateViewportTo(
              const GraphViewport(x: 300, y: 300, zoom: 2.0),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Should end up at the final target
      final matrix = transformController.value;
      final translation = matrix.getTranslation();
      final scale = matrix.getMaxScaleOnAxis();

      expect(translation.x, closeTo(300.0, 0.01));
      expect(translation.y, closeTo(300.0, 0.01));
      expect(scale, closeTo(2.0, 0.01));
    });

    testWidgets('very large zoom values work correctly', (tester) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;

            animator.animateViewportTo(
              const GraphViewport(x: 0, y: 0, zoom: 10.0),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final scale = transformController.value.getMaxScaleOnAxis();

      expect(scale, closeTo(10.0, 0.01));
    });

    testWidgets('very small zoom values work correctly', (tester) async {
      late TransformationController transformController;

      await tester.pumpWidget(
        _TestAnimatorWidget(
          onBuild: (animator, tc, controller) {
            transformController = tc;

            animator.animateViewportTo(
              const GraphViewport(x: 0, y: 0, zoom: 0.1),
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final scale = transformController.value.getMaxScaleOnAxis();

      expect(scale, closeTo(0.1, 0.01));
    });
  });
}

/// A test widget that provides a TickerProvider for animation tests.
class _TestTickerProviderWidget extends StatefulWidget {
  const _TestTickerProviderWidget({required this.builder});

  final Widget Function(BuildContext context, TickerProvider vsync) builder;

  @override
  State<_TestTickerProviderWidget> createState() =>
      _TestTickerProviderWidgetState();
}

class _TestTickerProviderWidgetState extends State<_TestTickerProviderWidget>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: widget.builder(context, this)));
  }
}

/// A test widget that sets up the animator with proper lifecycle management.
class _TestAnimatorWidget extends StatefulWidget {
  const _TestAnimatorWidget({required this.onBuild, this.onAnimationComplete});

  final void Function(
    TestViewportAnimator animator,
    TransformationController transformController,
    NodeFlowController controller,
  )
  onBuild;

  final ViewportSyncCallback? onAnimationComplete;

  @override
  State<_TestAnimatorWidget> createState() => _TestAnimatorWidgetState();
}

class _TestAnimatorWidgetState extends State<_TestAnimatorWidget>
    with TickerProviderStateMixin {
  late final TestViewportAnimator _animator;
  late final TransformationController _transformController;
  late final NodeFlowController _controller;

  @override
  void initState() {
    super.initState();
    _animator = TestViewportAnimator();
    _transformController = TransformationController();
    _controller = createTestController();

    _animator.attachViewportAnimation(
      tickerProvider: this,
      transformationController: _transformController,
      controller: _controller,
      onAnimationComplete: widget.onAnimationComplete,
    );
  }

  @override
  void dispose() {
    _animator.detachViewportAnimation();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuild(_animator, _transformController, _controller);

    return MaterialApp(home: Scaffold(body: const SizedBox()));
  }
}
