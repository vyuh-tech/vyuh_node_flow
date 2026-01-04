import 'dart:math' as math;

/// Node type identifiers for the math calculator.
abstract final class MathNodeTypes {
  static const number = 'number';
  static const operator = 'operator';
  static const function = 'function';
  static const result = 'result';
}

/// Configuration for port connection limits and positioning.
abstract final class MathPortConfig {
  /// Maximum connections allowed per input port.
  static const int maxInputConnections = 1;

  /// Horizontal offset for ports (positive = outward from node edge).
  static const double horizontalOffset = 3.0;

  /// Vertical position ratios for operator node's two input ports.
  static const double operatorPortAVerticalRatio = 0.30;
  static const double operatorPortBVerticalRatio = 0.70;
}

/// Port ID generation utilities.
abstract final class MathPortIds {
  static String inputA(String nodeId) => '$nodeId-input-a';
  static String inputB(String nodeId) => '$nodeId-input-b';
  static String input(String nodeId) => '$nodeId-input';
  static String output(String nodeId) => '$nodeId-output';
}

/// Arithmetic operators.
enum MathOperator {
  add('+'),
  subtract('-'),
  multiply('×'),
  divide('÷');

  final String symbol;
  const MathOperator(this.symbol);

  double apply(double a, double b) => switch (this) {
    add => a + b,
    subtract => a - b,
    multiply => a * b,
    divide => b == 0 ? double.nan : a / b,
  };
}

/// Mathematical functions.
enum MathFunction {
  sin('sin'),
  cos('cos'),
  sqrt('√');

  final String symbol;
  const MathFunction(this.symbol);

  double apply(double value) => switch (this) {
    sin => math.sin(value),
    cos => math.cos(value),
    sqrt => value < 0 ? double.nan : math.sqrt(value),
  };
}
