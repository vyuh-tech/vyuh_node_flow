import 'graph_events.dart';

/// Interface for extensions that can observe and react to graph events.
///
/// Extensions are purely additive - they observe events and provide
/// additional capabilities without modifying core behavior.
///
/// ## Lifecycle
///
/// 1. Extension is created
/// 2. [attach] is called with the controller reference
/// 3. [onEvent] is called for each graph event
/// 4. [detach] is called when the extension is removed
///
/// ## Example Implementation
///
/// ```dart
/// class LoggingExtension<T> implements NodeFlowExtension<T> {
///   NodeFlowController<T>? _controller;
///
///   @override
///   String get id => 'logging';
///
///   @override
///   void attach(NodeFlowController<T> controller) {
///     _controller = controller;
///     print('Logging extension attached');
///   }
///
///   @override
///   void detach() {
///     _controller = null;
///     print('Logging extension detached');
///   }
///
///   @override
///   void onEvent(GraphEvent event) {
///     print('Event: $event');
///   }
/// }
/// ```
///
/// ## Usage
///
/// ```dart
/// final controller = NodeFlowController<MyData>();
/// controller.addExtension(LoggingExtension<MyData>());
/// ```
abstract interface class NodeFlowExtension<T> {
  /// Unique identifier for this extension.
  ///
  /// Used to prevent duplicate registrations and for removal.
  /// Should be a descriptive, kebab-case string like 'undo-redo' or 'export'.
  String get id;

  /// Called when the extension is attached to a controller.
  ///
  /// Store the controller reference for later use. This is the only
  /// way extensions can access the controller.
  void attach(covariant dynamic controller);

  /// Called when the extension is detached from the controller.
  ///
  /// Clean up any resources, listeners, or stored state.
  /// The controller reference should be cleared.
  void detach();

  /// Called when a graph event occurs.
  ///
  /// Use pattern matching to handle events of interest:
  /// ```dart
  /// void onEvent(GraphEvent event) {
  ///   switch (event) {
  ///     case NodeAdded(:final node):
  ///       // Handle node added
  ///     case NodeMoved(:final node, :final previousPosition):
  ///       // Handle node moved
  ///     case BatchStarted(:final reason):
  ///       // Start accumulating events
  ///     case BatchEnded():
  ///       // Finalize batch
  ///     default:
  ///       // Ignore other events
  ///   }
  /// }
  /// ```
  void onEvent(GraphEvent event);
}
