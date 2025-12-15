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
