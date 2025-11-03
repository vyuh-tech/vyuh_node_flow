import 'package:flutter/material.dart';

/// Represents a single example
class Example {
  final String id;
  final String title;
  final String description;
  final IconData? icon;
  final Widget Function(BuildContext context) builder;

  const Example({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    required this.builder,
  });
}

/// Represents a category of examples with its examples
class ExampleCategory {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<Example> examples;

  const ExampleCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.examples,
  });
}
