import 'package:flutter/widgets.dart';

import 'controller/node_flow_controller.dart';

/// An InheritedWidget that provides [NodeFlowController] to descendants.
///
/// This scope allows nodes and other widgets within the node flow to access
/// the controller without explicit passing. This is particularly useful for:
/// - Nodes that need to call controller methods (e.g., resize callbacks)
/// - Custom widgets that need viewport information
/// - Plugins or extensions that need controller access
///
/// ## Usage
///
/// Access the controller in any descendant widget:
///
/// ```dart
/// Widget build(BuildContext context) {
///   final controller = NodeFlowScope.of<MyData>(context);
///   // Use controller...
/// }
/// ```
///
/// For optional access (when the widget might be outside the scope):
///
/// ```dart
/// Widget build(BuildContext context) {
///   final controller = NodeFlowScope.maybeOf<MyData>(context);
///   if (controller != null) {
///     // Use controller...
///   }
/// }
/// ```
class NodeFlowScope<T> extends InheritedWidget {
  const NodeFlowScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// The [NodeFlowController] provided by this scope.
  final NodeFlowController<T, dynamic> controller;

  /// Returns the [NodeFlowController] from the nearest [NodeFlowScope] ancestor.
  ///
  /// Throws if no [NodeFlowScope] is found in the widget tree.
  static NodeFlowController<T, dynamic> of<T>(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NodeFlowScope<T>>();
    assert(scope != null, 'No NodeFlowScope<$T> found in context');
    return scope!.controller;
  }

  /// Returns the [NodeFlowController] from the nearest [NodeFlowScope] ancestor,
  /// or null if not found.
  ///
  /// Use this when the widget might exist outside a [NodeFlowScope].
  static NodeFlowController<T, dynamic>? maybeOf<T>(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NodeFlowScope<T>>();
    return scope?.controller;
  }

  @override
  bool updateShouldNotify(NodeFlowScope<T> oldWidget) {
    return controller != oldWidget.controller;
  }
}
