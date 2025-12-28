import 'package:flutter/material.dart';

/// Defines the visual styling for connection labels.
///
/// Connection labels can be positioned anywhere along a connection path using
/// an anchor value (0.0-1.0) and a perpendicular offset. Labels use [ConnectionLabel]
/// instances which contain their own positioning information.
///
/// [LabelTheme] controls the appearance of the label text and its background
/// container, including colors, borders, and padding.
///
/// ## Usage Example
/// ```dart
/// const labelTheme = LabelTheme(
///   textStyle: TextStyle(
///     color: Colors.black,
///     fontSize: 12.0,
///     fontWeight: FontWeight.w500,
///   ),
///   backgroundColor: Colors.white,
///   border: Border.all(color: Colors.grey, width: 1.0),
///   borderRadius: BorderRadius.all(Radius.circular(4.0)),
///   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
/// );
/// ```
///
/// See also:
/// - [ConnectionLabel] for label positioning and content
/// - [Connection] for applying labels to connections
/// - [NodeFlowTheme] for overall theme configuration
class LabelTheme {
  /// Creates a label theme with the specified styling properties.
  ///
  /// Parameters:
  /// - [textStyle]: The text style for the label text
  /// - [backgroundColor]: Background color of the label container
  /// - [border]: Border decoration (use Border.all() for simple borders)
  /// - [borderRadius]: Border radius for rounded corners
  /// - [padding]: Padding inside the label container
  /// - [maxWidth]: Maximum width before text wraps (default: infinite, no wrapping)
  /// - [maxLines]: Maximum number of lines (default: null, unlimited)
  /// - [offset]: Default perpendicular offset from the connection path
  /// - [labelGap]: Minimum gap from endpoints when anchor is 0.0 or 1.0 (default: 8.0)
  const LabelTheme({
    this.textStyle = const TextStyle(fontSize: 12.0),
    this.backgroundColor,
    this.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.maxWidth = double.infinity,
    this.maxLines,
    this.offset = 0.0,
    this.labelGap = 8.0,
  });

  /// Text style for the label text.
  ///
  /// Includes font size, color, weight, family, and other text styling.
  /// Defaults to 12.0 font size if not specified.
  final TextStyle textStyle;

  /// Background color of the label container.
  ///
  /// If null, the label will have a transparent background.
  final Color? backgroundColor;

  /// Border decoration for the label container.
  ///
  /// Use [Border.all()] for simple borders, or create custom borders.
  /// If null, no border is drawn.
  ///
  /// Example:
  /// ```dart
  /// border: Border.all(color: Colors.grey, width: 1.0)
  /// ```
  final BoxBorder? border;

  /// Border radius for rounded corners.
  ///
  /// Defaults to all corners with 4.0 radius.
  /// Use [BorderRadius.circular()] for uniform corners or
  /// [BorderRadius.only()] for selective corners.
  final BorderRadius borderRadius;

  /// Padding inside the label container.
  ///
  /// Defaults to 8 pixels horizontal and 2 pixels vertical.
  final EdgeInsets padding;

  /// Maximum width before text wraps to multiple lines.
  ///
  /// If the text exceeds this width, it will automatically wrap to the next line.
  /// Set to [double.infinity] (default) for no wrapping - text will be single line.
  ///
  /// Example:
  /// ```dart
  /// maxWidth: 150.0  // Text wraps after 150 logical pixels
  /// maxWidth: double.infinity  // No wrapping (default)
  /// ```
  final double maxWidth;

  /// Maximum number of lines for the label text.
  ///
  /// If the text exceeds this number of lines when wrapping, it will be truncated.
  /// Set to null (default) for unlimited lines.
  ///
  /// This works together with [maxWidth] to control text wrapping and overflow.
  ///
  /// Example:
  /// ```dart
  /// maxLines: 2  // Text limited to 2 lines
  /// maxLines: null  // Unlimited lines (default)
  /// ```
  final int? maxLines;

  /// Default perpendicular offset from the connection path.
  ///
  /// This value is used when a [ConnectionLabel] does not specify its own offset.
  /// Positive values offset the label to one side of the path, negative values to the other.
  /// Defaults to 0.0 (label sits on the path).
  final double offset;

  /// Minimum gap from connection endpoints when label anchor is at 0.0 or 1.0.
  ///
  /// When a label has anchor=0.0, the label's left edge will be at least [labelGap]
  /// pixels from the start of the connection.
  /// When anchor=1.0, the label's right edge will be at least [labelGap] pixels
  /// from the end of the connection.
  ///
  /// This prevents labels from overlapping with port markers or arrow heads.
  /// Defaults to 8.0 pixels.
  final double labelGap;

  /// Creates a copy of this theme with the given fields replaced with new values.
  LabelTheme copyWith({
    TextStyle? textStyle,
    Color? backgroundColor,
    BoxBorder? border,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    double? maxWidth,
    int? maxLines,
    double? offset,
    double? labelGap,
  }) {
    return LabelTheme(
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      maxWidth: maxWidth ?? this.maxWidth,
      maxLines: maxLines ?? this.maxLines,
      offset: offset ?? this.offset,
      labelGap: labelGap ?? this.labelGap,
    );
  }

  /// Predefined light theme for labels.
  static const light = LabelTheme(
    textStyle: TextStyle(
      color: Color(0xFF333333),
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
    ),
    backgroundColor: Color(0xFFFBFBFB),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFFDDDDDD), width: 1.0),
    ),
    borderRadius: BorderRadius.all(Radius.circular(4.0)),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    offset: 0.0,
  );

  /// Predefined dark theme for labels.
  static const dark = LabelTheme(
    textStyle: TextStyle(
      color: Color(0xFFE5E5E5),
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
    ),
    backgroundColor: Color(0xFF404040),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFF606060), width: 1.0),
    ),
    borderRadius: BorderRadius.all(Radius.circular(4.0)),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    offset: 0.0,
  );
}
