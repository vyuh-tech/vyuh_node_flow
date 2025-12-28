/// Types of drag sessions that can be created.
///
/// Each type represents a different drag operation in the node flow editor.
/// The controller ensures only one session can be active at a time.
enum DragSessionType {
  /// Dragging one or more nodes to reposition them.
  nodeDrag,

  /// Creating a new connection by dragging from a port.
  connectionDrag,
}

/// Abstract interface for a drag session.
///
/// A drag session manages the lifecycle of a drag operation, handling
/// canvas locking/unlocking automatically. Elements only need to:
/// - Request a session from the controller via `createSession(type)`
/// - Call lifecycle methods: [start], [end], [cancel]
///
/// Elements manage their own business state (positions, sizes) internally.
/// The session purely handles canvas lock coordination.
///
/// ## Usage
///
/// ```dart
/// // In widget - get session from controller
/// DragSession? _session;
///
/// void _handleDragStart(DragStartDetails details) {
///   _originalPosition = widget.position; // Element manages its own state
///   _session = controller.createSession(DragSessionType.nodeDrag);
///   _session!.start(); // Locks canvas
///   // ...
/// }
///
/// void _handleDragEnd(DragEndDetails details) {
///   _session?.end(); // Unlocks canvas
///   _session = null;
///   // Commit state (no restore needed)
/// }
///
/// void _handleDragCancel() {
///   _session?.cancel(); // Unlocks canvas
///   _session = null;
///   // Restore state
///   widget.position = _originalPosition!;
/// }
/// ```
///
/// ## Design
///
/// The controller owns session creation, ensuring centralized control over
/// canvas locking. Elements don't need direct access to `InteractionState`;
/// they only interact with this abstract session API. The implementation
/// is private within the controller.
abstract class DragSession {
  /// The type of this drag session.
  DragSessionType get type;

  /// Whether this session is currently active.
  bool get isActive;

  /// Starts the drag session.
  ///
  /// Locks the canvas to prevent pan/zoom during drag operations.
  /// Does nothing if already active.
  void start();

  /// Ends the drag session successfully.
  ///
  /// Unlocks the canvas. The element should commit any state changes.
  /// Does nothing if not active.
  void end();

  /// Cancels the drag session.
  ///
  /// Unlocks the canvas. The element should restore its state to the
  /// values captured at session start.
  /// Does nothing if not active.
  void cancel();
}
