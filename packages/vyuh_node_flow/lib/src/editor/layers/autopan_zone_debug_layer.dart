import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../extensions/auto_pan_extension.dart';
import '../../extensions/debug_extension.dart';
import '../controller/node_flow_controller.dart';

/// Debug layer that visualizes the autopan edge zones.
///
/// This layer renders a semi-transparent overlay showing where autopan
/// activates when dragging elements near the viewport edges.
///
/// **Coordinate System**: This layer uses **screen coordinates** and should
/// be placed outside the InteractiveViewer to remain fixed to the viewport
/// edges regardless of zoom/pan level.
///
/// ## Behavior Zones
///
/// ```
/// ┌─────────────────────────────────────────────┐
/// │░░░░░░░░░░░░░░ EDGE ZONE ░░░░░░░░░░░░░░░░░░░│
/// │░░┌─────────────────────────────────────┐░░░│
/// │░░│                                     │░░░│
/// │░░│         Safe area (no pan)          │░░░│
/// │░░│                                     │░░░│
/// │░░└─────────────────────────────────────┘░░░│
/// │░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
/// └─────────────────────────────────────────────┘
/// ```
///
/// ## Usage
///
/// This layer is automatically shown when `controller.debug.showAutoPanZone`
/// is true and autopan is configured. Place it outside the InteractiveViewer:
///
/// ```dart
/// Stack(
///   children: [
///     InteractiveViewer(...),
///     AutopanZoneDebugLayer<MyData>(controller: controller),
///   ],
/// )
/// ```
class AutopanZoneDebugLayer<T> extends StatelessWidget {
  const AutopanZoneDebugLayer({super.key, required this.controller});

  /// The node flow controller containing the config.
  final NodeFlowController<T> controller;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final autoPanConfig = controller.autoPan.currentConfig;
        final debug = controller.debug;

        // Only show if autopan zone debug is enabled and autopan is configured
        if (!debug.showAutoPanZone ||
            autoPanConfig == null ||
            !autoPanConfig.isEnabled) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          child: CustomPaint(
            painter: _AutopanZonePainter(
              edgePadding: autoPanConfig.edgePadding,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

/// Painter that draws the autopan edge zones.
class _AutopanZonePainter extends CustomPainter {
  _AutopanZonePainter({required this.edgePadding});

  final EdgeInsets edgePadding;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw left edge zone
    if (edgePadding.left > 0) {
      final leftRect = Rect.fromLTWH(0, 0, edgePadding.left, size.height);
      canvas.drawRect(leftRect, paint);
      canvas.drawLine(
        Offset(edgePadding.left, 0),
        Offset(edgePadding.left, size.height),
        borderPaint,
      );
    }

    // Draw right edge zone
    if (edgePadding.right > 0) {
      final rightRect = Rect.fromLTWH(
        size.width - edgePadding.right,
        0,
        edgePadding.right,
        size.height,
      );
      canvas.drawRect(rightRect, paint);
      canvas.drawLine(
        Offset(size.width - edgePadding.right, 0),
        Offset(size.width - edgePadding.right, size.height),
        borderPaint,
      );
    }

    // Draw top edge zone
    if (edgePadding.top > 0) {
      final topRect = Rect.fromLTWH(0, 0, size.width, edgePadding.top);
      canvas.drawRect(topRect, paint);
      canvas.drawLine(
        Offset(0, edgePadding.top),
        Offset(size.width, edgePadding.top),
        borderPaint,
      );
    }

    // Draw bottom edge zone
    if (edgePadding.bottom > 0) {
      final bottomRect = Rect.fromLTWH(
        0,
        size.height - edgePadding.bottom,
        size.width,
        edgePadding.bottom,
      );
      canvas.drawRect(bottomRect, paint);
      canvas.drawLine(
        Offset(0, size.height - edgePadding.bottom),
        Offset(size.width, size.height - edgePadding.bottom),
        borderPaint,
      );
    }

    // Draw inner bounds rectangle (where no autopan occurs)
    final innerRect = Rect.fromLTRB(
      edgePadding.left,
      edgePadding.top,
      size.width - edgePadding.right,
      size.height - edgePadding.bottom,
    );

    final innerBorderPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw dashed inner rectangle
    _drawDashedRect(canvas, innerRect, innerBorderPaint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 4.0;

    // Top edge
    _drawDashedLine(
      canvas,
      rect.topLeft,
      rect.topRight,
      paint,
      dashWidth,
      dashSpace,
    );

    // Right edge
    _drawDashedLine(
      canvas,
      rect.topRight,
      rect.bottomRight,
      paint,
      dashWidth,
      dashSpace,
    );

    // Bottom edge
    _drawDashedLine(
      canvas,
      rect.bottomRight,
      rect.bottomLeft,
      paint,
      dashWidth,
      dashSpace,
    );

    // Left edge
    _drawDashedLine(
      canvas,
      rect.bottomLeft,
      rect.topLeft,
      paint,
      dashWidth,
      dashSpace,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / length;
    final unitY = dy / length;

    var distance = 0.0;
    var drawing = true;

    while (distance < length) {
      final segmentLength = drawing ? dashWidth : dashSpace;
      final actualSegment = (distance + segmentLength > length)
          ? length - distance
          : segmentLength;

      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitX * distance, start.dy + unitY * distance),
          Offset(
            start.dx + unitX * (distance + actualSegment),
            start.dy + unitY * (distance + actualSegment),
          ),
          paint,
        );
      }

      distance += actualSegment;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_AutopanZonePainter oldDelegate) {
    return edgePadding != oldDelegate.edgePadding;
  }
}
