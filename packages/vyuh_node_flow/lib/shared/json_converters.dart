import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import 'shapes/marker_shape.dart';

/// A JSON converter for Flutter's [Offset] class.
///
/// This converter serializes [Offset] objects to JSON as a map with 'x' and 'y'
/// keys, and deserializes JSON maps back to [Offset] objects.
///
/// Example JSON representation:
/// ```json
/// {
///   "x": 100.0,
///   "y": 200.0
/// }
/// ```
///
/// Usage with json_serializable:
/// ```dart
/// @JsonSerializable()
/// class MyClass {
///   @OffsetConverter()
///   final Offset position;
///
///   MyClass(this.position);
/// }
/// ```
///
/// See also:
/// - [Offset], the Flutter class representing a 2D offset
/// - [SizeConverter], for converting [Size] objects
class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  /// Creates a const instance of [OffsetConverter].
  const OffsetConverter();

  /// Converts a JSON map to an [Offset] object.
  ///
  /// The JSON map must contain 'x' and 'y' keys with numeric values.
  /// Both integer and double values are supported and will be converted to doubles.
  ///
  /// Example:
  /// ```dart
  /// final converter = OffsetConverter();
  /// final offset = converter.fromJson({'x': 10, 'y': 20});
  /// // offset.dx == 10.0, offset.dy == 20.0
  /// ```
  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
  }

  /// Converts an [Offset] object to a JSON map.
  ///
  /// Returns a map with 'x' and 'y' keys containing the offset's dx and dy values.
  ///
  /// Example:
  /// ```dart
  /// final converter = OffsetConverter();
  /// final json = converter.toJson(Offset(10.5, 20.3));
  /// // json == {'x': 10.5, 'y': 20.3}
  /// ```
  @override
  Map<String, dynamic> toJson(Offset offset) {
    return {'x': offset.dx, 'y': offset.dy};
  }
}

/// A JSON converter for Flutter's [Size] class.
///
/// This converter serializes [Size] objects to JSON as a map with 'width' and 'height'
/// keys, and deserializes JSON maps back to [Size] objects. Supports nullable Size.
///
/// Example JSON representation:
/// ```json
/// {
///   "width": 300.0,
///   "height": 200.0
/// }
/// ```
///
/// Usage with json_serializable:
/// ```dart
/// @JsonSerializable()
/// class MyClass {
///   @SizeConverter()
///   final Size? dimensions; // null = use theme default
///
///   MyClass(this.dimensions);
/// }
/// ```
///
/// See also:
/// - [Size], the Flutter class representing 2D dimensions
/// - [OffsetConverter], for converting [Offset] objects
class SizeConverter implements JsonConverter<Size?, Map<String, dynamic>?> {
  /// Creates a const instance of [SizeConverter].
  const SizeConverter();

  /// Converts a JSON map to a [Size] object, or null if json is null.
  ///
  /// The JSON map must contain 'width' and 'height' keys with numeric values.
  /// Both integer and double values are supported and will be converted to doubles.
  ///
  /// Example:
  /// ```dart
  /// final converter = SizeConverter();
  /// final size = converter.fromJson({'width': 100, 'height': 50});
  /// // size.width == 100.0, size.height == 50.0
  /// ```
  @override
  Size? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Size(
      (json['width'] as num).toDouble(),
      (json['height'] as num).toDouble(),
    );
  }

  /// Converts a [Size] object to a JSON map, or null if size is null.
  ///
  /// Returns a map with 'width' and 'height' keys containing the size's dimensions.
  ///
  /// Example:
  /// ```dart
  /// final converter = SizeConverter();
  /// final json = converter.toJson(Size(100.5, 50.3));
  /// // json == {'width': 100.5, 'height': 50.3}
  /// ```
  @override
  Map<String, dynamic>? toJson(Size? size) {
    if (size == null) return null;
    return {'width': size.width, 'height': size.height};
  }
}

/// A JSON converter for Flutter's [Color] class.
///
/// This converter serializes [Color] objects to JSON as a 32-bit ARGB integer,
/// and deserializes integers back to [Color] objects. The integer representation
/// includes alpha, red, green, and blue channels in ARGB format.
///
/// Example JSON representation:
/// ```json
/// 4294901760  // 0xFFFF0000 - Red color
/// ```
///
/// Usage with json_serializable:
/// ```dart
/// @JsonSerializable()
/// class MyClass {
///   @ColorConverter()
///   final Color backgroundColor;
///
///   MyClass(this.backgroundColor);
/// }
/// ```
///
/// Note: The integer format preserves the full ARGB color information including
/// opacity, making it suitable for complete color serialization.
///
/// See also:
/// - [Color], the Flutter class representing colors
/// - [Color.toARGB32], the method used for serialization
class ColorConverter implements JsonConverter<Color, int> {
  /// Creates a const instance of [ColorConverter].
  const ColorConverter();

  /// Converts a 32-bit ARGB integer to a [Color] object.
  ///
  /// The integer should be in ARGB format where each byte represents:
  /// - Bits 24-31: Alpha (opacity)
  /// - Bits 16-23: Red
  /// - Bits 8-15: Green
  /// - Bits 0-7: Blue
  ///
  /// Example:
  /// ```dart
  /// final converter = ColorConverter();
  /// final color = converter.fromJson(0xFFFF0000); // Red
  /// // color == Color(0xFFFF0000)
  /// ```
  @override
  Color fromJson(int json) {
    return Color(json);
  }

  /// Converts a [Color] object to a 32-bit ARGB integer.
  ///
  /// Returns an integer in ARGB format that fully represents the color
  /// including its opacity.
  ///
  /// Example:
  /// ```dart
  /// final converter = ColorConverter();
  /// final json = converter.toJson(Colors.red);
  /// // json == 4294901760 (0xFFFF0000)
  /// ```
  @override
  int toJson(Color color) {
    return color.toARGB32();
  }
}

/// A JSON converter for [MarkerShape] class.
///
/// This converter serializes [MarkerShape] objects to JSON using their toJson method,
/// and deserializes JSON maps back to [MarkerShape] objects using the factory constructor.
///
/// Example JSON representation:
/// ```json
/// {
///   "type": "circle"
/// }
/// ```
///
/// For shapes with orientation:
/// ```json
/// {
///   "type": "triangle",
///   "orientation": "right"
/// }
/// ```
///
/// Usage with json_serializable:
/// ```dart
/// @JsonSerializable()
/// class Port {
///   @MarkerShapeConverter()
///   final MarkerShape? shape; // null = use theme default
///
///   Port(this.shape);
/// }
/// ```
class MarkerShapeConverter
    implements JsonConverter<MarkerShape?, Map<String, dynamic>?> {
  /// Creates a const instance of [MarkerShapeConverter].
  const MarkerShapeConverter();

  /// Converts a JSON map to a [MarkerShape] object, or null if json is null.
  ///
  /// Uses the factory constructor MarkerShape.fromJson to create the appropriate
  /// subclass based on the 'type' field in the JSON.
  @override
  MarkerShape? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return MarkerShape.fromJson(json);
  }

  /// Converts a [MarkerShape] object to a JSON map, or null if shape is null.
  ///
  /// Uses the toJson method of the MarkerShape instance, which returns
  /// a map with 'type' and any additional properties.
  @override
  Map<String, dynamic>? toJson(MarkerShape? shape) {
    return shape?.toJson();
  }
}
