import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../core/constants.dart';

abstract final class MathColors {
  static const canvas = Color(0xFFF8F9FA);
  static const nodeBackground = Colors.white;
  static const nodeBorder = Color(0xFFE8E8E8);

  static const portNumber = Color(0xFFE91E63);
  static const portOperator = Color(0xFF2196F3);
  static const portResult = Color(0xFF4CAF50);

  static const operatorActive = Color(0xFF2196F3);
  static const operatorInactive = Color(0xFF424242);

  static const textPrimary = Color(0xFF424242);
  static const textSecondary = Color(0xFF757575);
  static const textResult = Color(0xFF4CAF50);
  static const textError = Color(0xFFF44336);

  static Color portColorFor(String nodeType) => switch (nodeType) {
    MathNodeTypes.number => portNumber,
    MathNodeTypes.operator || MathNodeTypes.function => portOperator,
    MathNodeTypes.result => portResult,
    _ => portOperator,
  };
}

abstract final class MathNodeStyles {
  static const double borderRadius = 10.0;
  static const double borderWidth = 1.0;

  /// Subtle drop shadow for depth perception.
  static List<BoxShadow> get nodeShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static BoxDecoration get nodeDecoration => BoxDecoration(
    color: MathColors.nodeBackground,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: MathColors.nodeBorder, width: borderWidth),
    boxShadow: nodeShadow,
  );

  /// Borderless decoration for cleaner look (function, result nodes).
  static BoxDecoration get nodeDecorationNoBorder => BoxDecoration(
    color: MathColors.nodeBackground,
    borderRadius: BorderRadius.circular(8),
    boxShadow: nodeShadow,
  );
}

abstract final class MathNodeSizes {
  static const number = Size(140, 48);
  static const operator = Size(200, 60);
  static const function = Size(90, 56);
  static const result = Size(100, 90);

  static const resultMinWidth = 80.0;
  static const resultMaxWidth = 300.0;
  static const resultHeight = 90.0;
  static const resultPadding = 24.0;

  static Size forType(String nodeType) => switch (nodeType) {
    MathNodeTypes.number => number,
    MathNodeTypes.operator => operator,
    MathNodeTypes.function => function,
    MathNodeTypes.result => result,
    _ => number,
  };
}

class MathTheme {
  static NodeFlowTheme get nodeFlowTheme {
    final base = NodeFlowTheme.light;

    return base.copyWith(
      backgroundColor: MathColors.canvas,
      connectionTheme: base.connectionTheme.copyWith(
        color: const Color(0xFFBDBDBD),
        selectedColor: MathColors.portOperator,
        strokeWidth: 2,
        selectedStrokeWidth: 2,
        style: ConnectionStyles.smoothstep,
        dashPattern: const [6, 4],
        startPoint: ConnectionEndPoint.none,
        endPoint: ConnectionEndPoint.triangle,
        endpointColor: const Color(0xFFBDBDBD),
        endpointBorderColor: Colors.white,
        endpointBorderWidth: 1,
        animationEffect: FlowingDashEffect(
          dashLength: 3,
          gapLength: 6,
          speed: 5,
        ),
      ),
      temporaryConnectionTheme: base.temporaryConnectionTheme.copyWith(
        color: const Color(0xFF9E9E9E),
        strokeWidth: 2,
        style: ConnectionStyles.smoothstep,
        dashPattern: const [6, 4],
        startPoint: ConnectionEndPoint.none,
        endPoint: ConnectionEndPoint.triangle,
        animationEffect: FlowingDashEffect(
          dashLength: 3,
          gapLength: 6,
          speed: 5,
        ),
      ),
      portTheme: base.portTheme.copyWith(
        color: MathColors.portOperator,
        size: const Size(10, 22),
        borderWidth: 1,
        borderColor: Colors.white,
        connectedColor: MathColors.portOperator,
        shape: MarkerShapes.rectangle,
      ),
      nodeTheme: base.nodeTheme.copyWith(
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        selectedBackgroundColor: Colors.transparent,
        selectedBorderColor: MathColors.portOperator,
        borderWidth: 0,
        selectedBorderWidth: 2,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
