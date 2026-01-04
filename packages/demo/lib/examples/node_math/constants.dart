import 'dart:math' as math;

/// Node type identifiers for the math calculator.
abstract final class MathNodeTypes {
  static const number = 'number';
  static const operator = 'operator';
  static const function = 'function';
  static const result = 'result';
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
