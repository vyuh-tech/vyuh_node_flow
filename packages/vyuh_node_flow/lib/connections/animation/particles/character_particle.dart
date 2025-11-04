import 'dart:ui';

import 'package:flutter/material.dart'
    show TextPainter, TextSpan, TextStyle, TextAlign, TextDirection;

import '../particle_painter.dart';

/// A character/emoji particle painter.
///
/// Renders particles as text characters or emojis, allowing for
/// expressive and customizable flow visualizations.
///
/// Example:
/// ```dart
/// // Emoji particle
/// ParticleEffect(
///   particlePainter: CharacterParticle(
///     character: '🚀',
///     fontSize: 16.0,
///   ),
///   particleCount: 3,
///   speed: 1,
/// )
///
/// // Text particle
/// ParticleEffect(
///   particlePainter: CharacterParticle(
///     character: '→',
///     fontSize: 20.0,
///   ),
///   particleCount: 5,
///   speed: 2,
/// )
/// ```
class CharacterParticle implements ParticlePainter {
  /// Creates a character/emoji particle painter.
  ///
  /// Parameters:
  /// - [character]: The character or emoji to display. Default: '●'
  /// - [fontSize]: The font size in pixels. Default: 12.0
  /// - [color]: Optional color override. If null, uses connection color.
  ///   Note: For emojis, color override may not work as emojis have their own colors.
  CharacterParticle({this.character = '●', this.fontSize = 12.0, this.color})
    : assert(character.isNotEmpty, 'Character must not be empty'),
      assert(fontSize > 0, 'Font size must be positive') {
    // Pre-compute the size by measuring the text
    _computeSize();
  }

  /// The character or emoji to display
  final String character;

  /// The font size in pixels
  final double fontSize;

  /// Optional color override for the particle (null = use connection color)
  /// Note: For emojis, this may not have an effect as emojis render with their own colors
  final Color? color;

  late Size _cachedSize;

  void _computeSize() {
    // Create a temporary text painter to measure the character
    final textPainter = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontSize: fontSize,
          color: color ?? const Color(0xFFFFFFFF), // Placeholder color
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    _cachedSize = Size(textPainter.width, textPainter.height);
  }

  @override
  void paint(Canvas canvas, Offset position, Tangent tangent, Paint basePaint) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(fontSize: fontSize, color: color ?? basePaint.color),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Center the text at the position
    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  Size get size => _cachedSize;
}
