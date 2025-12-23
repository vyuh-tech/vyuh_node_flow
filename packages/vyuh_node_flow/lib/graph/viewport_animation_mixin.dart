import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'viewport.dart';

/// A [Tween] that interpolates between two [Matrix4] values.
///
/// Interpolates translation and uniform scale for viewport animations.
class _Matrix4ViewportTween extends Tween<Matrix4> {
  _Matrix4ViewportTween({required Matrix4 begin, required Matrix4 end})
    : super(begin: begin, end: end);

  @override
  Matrix4 lerp(double t) {
    // Extract translation and scale from begin/end matrices
    final beginTranslation = begin!.getTranslation();
    final endTranslation = end!.getTranslation();
    final beginScale = begin!.getMaxScaleOnAxis();
    final endScale = end!.getMaxScaleOnAxis();

    // Lerp translation and scale
    final tx = lerpDouble(beginTranslation.x, endTranslation.x, t)!;
    final ty = lerpDouble(beginTranslation.y, endTranslation.y, t)!;
    final scale = lerpDouble(beginScale, endScale, t)!;

    // Create new matrix with interpolated values
    return Matrix4.identity()
      ..translateByVector3(Vector3(tx, ty, 0))
      ..scaleByDouble(scale, scale, scale, 1.0);
  }
}

/// Callback type for syncing final viewport state after animation completes.
typedef ViewportSyncCallback = void Function(GraphViewport viewport);

/// Mixin that provides viewport animation capabilities for [NodeFlowEditor].
///
/// This mixin directly animates a [TransformationController]'s matrix using lerp,
/// bypassing reactive state management for smooth, direct animations.
///
/// The mixin provides the core animation infrastructure. All convenience methods
/// (animateToNode, animateToPosition, animateToBounds, animateToScale) are
/// available on [NodeFlowController] which delegates to this mixin's
/// [animateViewportTo] method.
///
/// ## Usage
///
/// ```dart
/// class _MyEditorState extends State<MyEditor>
///     with TickerProviderStateMixin, ViewportAnimationMixin {
///
///   late TransformationController _transformationController;
///
///   @override
///   void initState() {
///     super.initState();
///     _transformationController = TransformationController();
///     attachViewportAnimation(
///       tickerProvider: this,
///       transformationController: _transformationController,
///       onAnimationComplete: (viewport) {
///         // Sync final state if needed
///         controller.setViewport(viewport);
///       },
///     );
///   }
///
///   @override
///   void dispose() {
///     detachViewportAnimation();
///     super.dispose();
///   }
/// }
/// ```
mixin ViewportAnimationMixin {
  /// Animation controller for viewport animations.
  AnimationController? _viewportAnimationController;

  /// Current matrix animation (null when not animating).
  Animation<Matrix4>? _matrixAnimation;

  /// The transformation controller to animate.
  TransformationController? _transformationController;

  /// Callback when animation completes to sync final viewport state.
  ViewportSyncCallback? _onAnimationComplete;

  /// Whether the animation system is attached.
  bool get isViewportAnimationAttached => _viewportAnimationController != null;

  /// Whether a viewport animation is currently running.
  bool get isViewportAnimating =>
      _viewportAnimationController?.isAnimating ?? false;

  /// Attach the viewport animation system to a ticker provider.
  ///
  /// This creates the animation controller and prepares the mixin for animations.
  /// Must be called before using any animation methods (typically in `initState`).
  ///
  /// Parameters:
  /// - [tickerProvider]: The TickerProvider to use for animations
  /// - [transformationController]: The TransformationController to animate
  /// - [onAnimationComplete]: Optional callback when animation completes
  void attachViewportAnimation({
    required TickerProvider tickerProvider,
    required TransformationController transformationController,
    ViewportSyncCallback? onAnimationComplete,
  }) {
    _transformationController = transformationController;
    _onAnimationComplete = onAnimationComplete;

    _viewportAnimationController = AnimationController(
      vsync: tickerProvider,
      duration: const Duration(milliseconds: 400),
    );
    _viewportAnimationController!.addListener(_onAnimationTick);
    _viewportAnimationController!.addStatusListener(_onAnimationStatus);
  }

  /// Detach the viewport animation system.
  ///
  /// This disposes the animation controller and cleans up resources.
  /// Must be called when done with animations (typically in `dispose`).
  void detachViewportAnimation() {
    _viewportAnimationController?.removeListener(_onAnimationTick);
    _viewportAnimationController?.removeStatusListener(_onAnimationStatus);
    _viewportAnimationController?.dispose();
    _viewportAnimationController = null;
    _matrixAnimation = null;
    _transformationController = null;
    _onAnimationComplete = null;
  }

  /// Animate the viewport to a target state.
  ///
  /// This is the core animation method that directly lerps the
  /// [TransformationController]'s matrix for smooth animation.
  ///
  /// All controller animation methods (animateToNode, animateToPosition,
  /// animateToBounds, animateToScale) delegate to this method.
  ///
  /// Parameters:
  /// - [target]: The target viewport state (position and zoom)
  /// - [duration]: Animation duration (default: 400ms)
  /// - [curve]: Animation curve (default: easeInOut)
  void animateViewportTo(
    GraphViewport target, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
  }) {
    if (_viewportAnimationController == null ||
        _transformationController == null) {
      return;
    }

    // Stop any existing animation
    _viewportAnimationController!.stop();

    // Get current matrix and create target matrix
    final currentMatrix = _transformationController!.value;
    final targetMatrix = Matrix4.identity()
      ..translateByVector3(Vector3(target.x, target.y, 0))
      ..scaleByDouble(target.zoom, target.zoom, target.zoom, 1.0);

    // Create tween from current to target matrix
    _matrixAnimation =
        _Matrix4ViewportTween(begin: currentMatrix, end: targetMatrix).animate(
          CurvedAnimation(parent: _viewportAnimationController!, curve: curve),
        );

    // Configure duration and start
    _viewportAnimationController!.duration = duration;
    _viewportAnimationController!.forward(from: 0.0);
  }

  /// Stop any currently running viewport animation.
  void stopViewportAnimation() {
    _viewportAnimationController?.stop();
  }

  /// Called on each animation frame to update the transform.
  void _onAnimationTick() {
    if (_matrixAnimation != null && _transformationController != null) {
      _transformationController!.value = _matrixAnimation!.value;
    }
  }

  /// Called when animation status changes.
  void _onAnimationStatus(AnimationStatus status) {
    // Only handle completed - dismissed happens when stop() is called to start a new animation
    if (status == AnimationStatus.completed) {
      // Sync final viewport state
      if (_onAnimationComplete != null && _transformationController != null) {
        final matrix = _transformationController!.value;
        final translation = matrix.getTranslation();
        final zoom = matrix.getMaxScaleOnAxis();
        _onAnimationComplete!(
          GraphViewport(x: translation.x, y: translation.y, zoom: zoom),
        );
      }
      _matrixAnimation = null;
    }
    // Note: dismissed status is ignored - it fires when stop() is called to start a new animation
  }
}
