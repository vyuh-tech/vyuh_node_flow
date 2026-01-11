/// Number formatting utilities for display and input fields.
abstract final class MathFormatters {
  /// Formats a number for result display.
  ///
  /// - Returns "?" for NaN/Infinite values
  /// - Omits decimal for whole numbers (e.g., "42" not "42.00")
  /// - Shows 2 decimal places otherwise (e.g., "3.14")
  static String formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return '?';
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  /// Formats a number for text field editing.
  ///
  /// Preserves full precision to avoid losing decimal places during editing.
  static String formatForInput(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
