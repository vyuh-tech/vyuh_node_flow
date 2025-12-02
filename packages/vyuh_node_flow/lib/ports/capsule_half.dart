import 'package:flutter/material.dart';

enum CapsuleFlatSide {
  left, // Flat left edge, curved right edge
  right, // Flat right edge, curved left edge
  top, // Flat top edge, curved bottom edge
  bottom; // Flat bottom edge, curved top edge

  CapsuleFlatSide get opposite {
    switch (this) {
      case CapsuleFlatSide.left:
        return CapsuleFlatSide.right;
      case CapsuleFlatSide.right:
        return CapsuleFlatSide.left;
      case CapsuleFlatSide.top:
        return CapsuleFlatSide.bottom;
      case CapsuleFlatSide.bottom:
        return CapsuleFlatSide.top;
    }
  }
}

/// A widget that renders half of a capsule shape using CustomPainter for perfect consistency
class CapsuleHalf extends StatelessWidget {
  const CapsuleHalf({
    super.key,
    required this.size,
    required this.flatSide,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  final double size;
  final CapsuleFlatSide flatSide;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CapsuleHalfCustomPainter(
        flatSide: flatSide,
        color: color,
        borderColor: borderColor,
        borderWidth: borderWidth,
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

/// CustomPainter that uses CapsuleHalfPainter for consistent rendering
class _CapsuleHalfCustomPainter extends CustomPainter {
  const _CapsuleHalfCustomPainter({
    required this.flatSide,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  final CapsuleFlatSide flatSide;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // Use the simplified painter
    final center = Offset(size.width / 2, size.height / 2);
    CapsuleHalfPainter.paint(
      canvas,
      center,
      size,
      flatSide,
      fillPaint,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_CapsuleHalfCustomPainter oldDelegate) {
    return flatSide != oldDelegate.flatSide ||
        color != oldDelegate.color ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth;
  }
}

/// A painter that draws a CapsuleHalf shape directly on canvas (for connection endpoints)
class CapsuleHalfPainter {
  static void paint(
    Canvas canvas,
    Offset center,
    Size size,
    CapsuleFlatSide flatSide,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
    final width = size.width;
    final height = size.height;

    // Use the shorter dimension for the corner radius
    final radius =
        (flatSide == CapsuleFlatSide.left || flatSide == CapsuleFlatSide.right)
        ? height / 2
        : width / 2;

    // Position is the center, create capsule half based on flat side
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    RRect rrect;
    switch (flatSide) {
      case CapsuleFlatSide.left:
        // Flat left edge, curved right edge
        rrect = RRect.fromRectAndCorners(
          rect,
          topRight: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );
        break;
      case CapsuleFlatSide.right:
        // Flat right edge, curved left edge
        rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
        );
        break;
      case CapsuleFlatSide.top:
        // Flat top edge, curved bottom edge
        rrect = RRect.fromRectAndCorners(
          rect,
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );
        break;
      case CapsuleFlatSide.bottom:
        // Flat bottom edge, curved top edge
        rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        );
        break;
    }

    canvas.drawRRect(rrect, fillPaint);

    if (borderPaint != null) {
      canvas.drawRRect(rrect, borderPaint);
    }
  }
}
