import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A Stack that allows hit testing on children positioned outside its bounds.
///
/// Flutter's default Stack blocks hit testing for children outside its bounds,
/// even when clipBehavior is Clip.none. This custom Stack overrides hitTest
/// to allow gestures on overflow content.
///
/// This is essential for infinite canvas implementations where nodes and other
/// elements can be positioned at arbitrary coordinates that may be outside
/// the Stack's layout bounds after pan/zoom transformations.
///
/// Example usage:
/// ```dart
/// UnboundedStack(
///   clipBehavior: Clip.none,
///   children: [
///     Positioned(
///       left: 5000, // Far outside typical bounds
///       top: 5000,
///       child: GestureDetector(
///         onTap: () => print('Tap works!'),
///         child: Container(...),
///       ),
///     ),
///   ],
/// )
/// ```
class UnboundedStack extends Stack {
  const UnboundedStack({
    super.key,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return _UnboundedRenderStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStack renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}

class _UnboundedRenderStack extends RenderStack {
  _UnboundedRenderStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Skip the default bounds check (_size.contains(position))
    // This allows hit testing on children positioned outside this Stack's bounds
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// A SizedBox that allows hit testing on children outside its bounds.
///
/// Use this when you need fixed sizing for layout but want gestures to work
/// on content that has been transformed outside the box (e.g., after pan/zoom
/// via InteractiveViewer).
///
/// This widget maintains the same layout behavior as SizedBox - it constrains
/// its child to the specified width/height. However, unlike SizedBox, it does
/// not block hit testing for positions outside its bounds.
///
/// Example usage:
/// ```dart
/// InteractiveViewer(
///   child: UnboundedSizedBox(
///     width: screenWidth,
///     height: screenHeight,
///     child: Stack(
///       clipBehavior: Clip.none,
///       children: [...], // Can be positioned anywhere
///     ),
///   ),
/// )
/// ```
class UnboundedSizedBox extends SingleChildRenderObjectWidget {
  const UnboundedSizedBox({super.key, this.width, this.height, super.child});

  final double? width;
  final double? height;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _UnboundedRenderConstrainedBox(
      additionalConstraints: BoxConstraints.tightFor(
        width: width,
        height: height,
      ),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderConstrainedBox renderObject,
  ) {
    renderObject.additionalConstraints = BoxConstraints.tightFor(
      width: width,
      height: height,
    );
  }
}

class _UnboundedRenderConstrainedBox extends RenderConstrainedBox {
  _UnboundedRenderConstrainedBox({required super.additionalConstraints});

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Skip the default bounds check - allow hit testing outside this box
    // This is essential when content has been transformed (pan/zoom) to
    // positions outside this box's layout bounds
    if (child != null) {
      return child!.hitTest(result, position: position);
    }
    return false;
  }
}

/// A Positioned widget that allows hit testing on its child outside its bounds.
///
/// Use this inside an [UnboundedStack] for layer widgets that need to receive
/// hit tests for positions outside the layer's layout bounds.
///
/// This is essential for infinite canvas implementations where:
/// - The layer fills the visible viewport (e.g., 800x600)
/// - Content within the layer can be at arbitrary canvas coordinates (e.g., 5000, 5000)
/// - Hit tests need to reach content regardless of position
///
/// Example usage:
/// ```dart
/// UnboundedStack(
///   clipBehavior: Clip.none,
///   children: [
///     UnboundedPositioned.fill(
///       child: NodesContainer(...), // Contains nodes at arbitrary positions
///     ),
///   ],
/// )
/// ```
class UnboundedPositioned extends StatelessWidget {
  const UnboundedPositioned({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.child,
  });

  /// Creates a Positioned that fills its parent while allowing unbounded hit testing.
  const UnboundedPositioned.fill({super.key, required this.child})
    : left = 0.0,
      top = 0.0,
      right = 0.0,
      bottom = 0.0,
      width = null,
      height = null;

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: _UnboundedHitTestBox(child: child),
    );
  }
}

/// Internal widget that wraps a child and skips bounds checking during hit tests.
///
/// This widget maintains the same layout as its child but allows hit testing
/// to pass through to children even when the position is outside this widget's bounds.
class _UnboundedHitTestBox extends SingleChildRenderObjectWidget {
  const _UnboundedHitTestBox({required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _UnboundedRenderProxyBox();
  }
}

class _UnboundedRenderProxyBox extends RenderProxyBox {
  _UnboundedRenderProxyBox();

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Skip the default bounds check (_size.contains(position))
    // Forward hit test to child regardless of position
    if (child != null) {
      if (child!.hitTest(result, position: position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }
}

/// A RepaintBoundary that allows hit testing on its child outside its bounds.
///
/// Flutter's [RepaintBoundary] creates a separate layer for efficient repainting,
/// but it inherits [RenderProxyBox]'s hit testing which blocks hits outside bounds.
///
/// Use this widget in infinite canvas implementations where:
/// - You want repaint isolation for performance
/// - Content can be at positions outside the widget's layout bounds
/// - Hit tests need to reach that content
///
/// Example usage:
/// ```dart
/// UnboundedPositioned.fill(
///   child: UnboundedRepaintBoundary(
///     child: Stack(
///       clipBehavior: Clip.none,
///       children: [...], // Nodes at arbitrary positions
///     ),
///   ),
/// )
/// ```
class UnboundedRepaintBoundary extends SingleChildRenderObjectWidget {
  const UnboundedRepaintBoundary({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _UnboundedRenderRepaintBoundary();
  }
}

class _UnboundedRenderRepaintBoundary extends RenderRepaintBoundary {
  _UnboundedRenderRepaintBoundary();

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Skip the default bounds check (_size.contains(position))
    // This allows hit testing on children positioned outside this boundary's bounds
    // while still maintaining the repaint isolation benefits
    if (child != null) {
      if (child!.hitTest(result, position: position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }
}
