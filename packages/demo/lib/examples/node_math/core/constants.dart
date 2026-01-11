import 'dart:math' as math;

/// String identifiers for node types, used for type-based lookups and serialization.
abstract final class MathNodeTypes {
  static const number = 'number';
  static const operator = 'operator';
  static const function = 'function';
  static const result = 'result';
}

/// Port configuration constants for connection behavior and visual layout.
abstract final class MathPortConfig {
  /// Input ports accept only one connection (ensures deterministic evaluation).
  static const int maxInputConnections = 1;

  /// Horizontal offset to position ports slightly outside node bounds.
  static const double horizontalOffset = 3.0;

  /// Vertical ratios for operator's dual input ports (A at top, B at bottom).
  static const double operatorPortAVerticalRatio = 0.30;
  static const double operatorPortBVerticalRatio = 0.70;
}

/// Generates deterministic port IDs from node IDs.
///
/// Consistent naming ensures connections survive node recreation during data updates.
abstract final class MathPortIds {
  static String inputA(String nodeId) => '$nodeId-input-a';
  static String inputB(String nodeId) => '$nodeId-input-b';
  static String input(String nodeId) => '$nodeId-input';
  static String output(String nodeId) => '$nodeId-output';
}

/// Binary arithmetic operators with symbol and evaluation logic.
enum MathOperator {
  add('+'),
  subtract('-'),
  multiply('×'),
  divide('÷');

  final String symbol;
  const MathOperator(this.symbol);

  /// Applies the operator to two operands. Returns NaN for division by zero.
  double apply(double a, double b) => switch (this) {
    add => a + b,
    subtract => a - b,
    multiply => a * b,
    divide => b == 0 ? double.nan : a / b,
  };
}

/// Unary mathematical functions with symbol and evaluation logic.
enum MathFunction {
  sin('sin'),
  cos('cos'),
  sqrt('√');

  final String symbol;
  const MathFunction(this.symbol);

  /// Applies the function to input. Returns NaN for invalid domain (e.g., sqrt of negative).
  double apply(double value) => switch (this) {
    sin => math.sin(value),
    cos => math.cos(value),
    sqrt => value < 0 ? double.nan : math.sqrt(value),
  };
}
