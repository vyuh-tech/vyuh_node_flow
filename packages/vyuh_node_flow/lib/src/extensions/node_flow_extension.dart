import '../editor/controller/node_flow_controller.dart';
import 'events/events.dart';

/// Interface for extensions that add behavior and state to the node flow editor.
///
/// Extensions are purely additive - they observe events and provide
/// additional capabilities without modifying core behavior. Each extension
/// manages its own state and reacts to graph events.
///
/// ## Type Parameter
///
/// The [TConfig] type parameter represents the configuration type for this
/// extension. Use `void` for extensions that don't require configuration:
///
/// ```dart
/// // Extension with configuration
/// class MinimapExtension extends NodeFlowExtension<MinimapConfig> { ... }
///
/// // Extension without configuration
/// class StatsExtension extends NodeFlowExtension<void> { ... }
/// ```
///
/// ## Lifecycle
///
/// 1. Extension is created (optionally with config)
/// 2. [attach] is called with the controller reference
/// 3. [onEvent] is called for each graph event
/// 4. [detach] is called when the extension is removed
///
/// ## Example Implementation
///
/// ```dart
/// class LoggingExtension extends NodeFlowExtension<void> {
///   NodeFlowController? _controller;
///
///   @override
///   String get id => 'logging';
///
///   @override
///   void get config => null;
///
///   @override
///   void attach(NodeFlowController controller) {
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
/// controller.addExtension(LoggingExtension());
/// ```
abstract class NodeFlowExtension<TConfig> {
  /// Unique identifier for this extension.
  ///
  /// Used to prevent duplicate registrations and for removal.
  /// Should be a descriptive, kebab-case string like 'undo-redo' or 'export'.
  String get id;

  /// The configuration for this extension.
  ///
  /// For extensions with configuration, this returns the current config.
  /// For extensions without configuration (TConfig = void), return `null`.
  TConfig? get config;

  /// Called when the extension is attached to a controller.
  ///
  /// Store the controller reference for later use. This is the only
  /// way extensions can access the controller. The controller provides
  /// access to nodes, connections, viewport, and configuration.
  void attach(NodeFlowController controller);

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
