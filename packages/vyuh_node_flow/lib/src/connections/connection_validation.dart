import '../nodes/node.dart';
import '../ports/port.dart';

/// Represents the result of a connection validation check.
///
/// Connection validation occurs when:
/// 1. Starting to drag a connection from a port
/// 2. Attempting to complete a connection to a target port
///
/// The result indicates whether the operation should be allowed and optionally
/// provides a reason and whether to show a user-facing message.
///
/// ## Usage Example
/// ```dart
/// // Allow a connection
/// return ConnectionValidationResult.allow();
///
/// // Deny with a reason
/// return ConnectionValidationResult.deny(
///   reason: 'Cannot connect input to input',
///   showMessage: true,
/// );
///
/// // Custom result
/// return ConnectionValidationResult(
///   allowed: isValid,
///   reason: validationMessage,
///   showMessage: true,
/// );
/// ```
class ConnectionValidationResult {
  /// Creates a connection validation result.
  ///
  /// Parameters:
  /// - [allowed]: Whether the connection should be allowed (default: true)
  /// - [reason]: Optional reason for the decision (for debugging/logging)
  /// - [showMessage]: Whether to show a visual message to the user (default: false)
  const ConnectionValidationResult({
    this.allowed = true,
    this.reason,
    this.showMessage = false,
  });

  /// Whether the connection should be allowed.
  final bool allowed;

  /// Optional reason for denying the connection.
  ///
  /// This is useful for debugging and logging. When [showMessage] is true,
  /// this may also be displayed to the user.
  final String? reason;

  /// Whether to show a visual message to the user when the connection is denied.
  ///
  /// If true and [allowed] is false, the UI may display a toast, snackbar,
  /// or other notification with the [reason].
  final bool showMessage;

  /// Creates a result that allows the connection.
  const ConnectionValidationResult.allow() : this();

  /// Creates a result that denies the connection.
  ///
  /// Parameters:
  /// - [reason]: Optional explanation for why the connection was denied
  /// - [showMessage]: Whether to show a visual message to the user (default: false)
  const ConnectionValidationResult.deny({
    String? reason,
    bool showMessage = false,
  }) : this(allowed: false, reason: reason, showMessage: showMessage);
}

/// Context provided when starting a connection from a port.
///
/// This context is passed to validation callbacks when a user begins dragging
/// a connection from a port. It provides information about the source node,
/// port, and existing connections to help determine if the drag operation
/// should be allowed.
///
/// ## Usage Example
/// ```dart
/// ConnectionValidationResult validateStart<T>(
///   ConnectionStartContext<T> context,
/// ) {
///   // Don't allow starting from a port that already has max connections
///   if (!context.sourcePort.allowMultiple &&
///       context.existingConnections.isNotEmpty) {
///     return ConnectionValidationResult.deny(
///       reason: 'Port already has a connection',
///       showMessage: true,
///     );
///   }
///   return ConnectionValidationResult.allow();
/// }
/// ```
class ConnectionStartContext<T> {
  /// Creates a connection start context.
  ///
  /// Parameters:
  /// - [sourceNode]: The node where the connection is starting
  /// - [sourcePort]: The port where the connection is starting
  /// - [existingConnections]: IDs of existing connections from this port
  const ConnectionStartContext({
    required this.sourceNode,
    required this.sourcePort,
    required this.existingConnections,
  });

  /// The node where the connection is starting.
  final Node<T> sourceNode;

  /// The port where the connection is starting.
  final Port sourcePort;

  /// Existing connection IDs from this port.
  ///
  /// These connections will be removed if the port doesn't allow multiple
  /// connections and a new connection is created.
  final List<String> existingConnections;

  /// Whether this is an output port.
  bool get isOutputPort => sourcePort.isOutput;

  /// Whether this is an input port.
  bool get isInputPort => sourcePort.isInput;
}

/// Context provided when attempting to complete a connection.
///
/// This context is passed to validation callbacks when a user attempts to
/// complete a connection by dropping on a target port. It provides complete
/// information about both the source and target to enable comprehensive
/// validation logic.
///
/// ## Usage Example
/// ```dart
/// ConnectionValidationResult validateComplete<T>(
///   ConnectionCompleteContext<T> context,
/// ) {
///   // Prevent self-connections
///   if (context.isSelfConnection) {
///     return ConnectionValidationResult.deny(
///       reason: 'Cannot connect node to itself',
///       showMessage: true,
///     );
///   }
///
///   // Only allow output-to-input connections
///   if (!context.isOutputToInput) {
///     return ConnectionValidationResult.deny(
///       reason: 'Must connect output to input',
///       showMessage: true,
///     );
///   }
///
///   return ConnectionValidationResult.allow();
/// }
/// ```
class ConnectionCompleteContext<T> {
  /// Creates a connection complete context.
  ///
  /// Parameters:
  /// - [sourceNode]: The source node of the connection
  /// - [sourcePort]: The source port of the connection
  /// - [targetNode]: The target node of the connection
  /// - [targetPort]: The target port of the connection
  /// - [existingSourceConnections]: IDs of existing connections from the source port
  /// - [existingTargetConnections]: IDs of existing connections to the target port
  const ConnectionCompleteContext({
    required this.sourceNode,
    required this.sourcePort,
    required this.targetNode,
    required this.targetPort,
    required this.existingSourceConnections,
    required this.existingTargetConnections,
  });

  /// The source node of the connection.
  final Node<T> sourceNode;

  /// The source port of the connection.
  final Port sourcePort;

  /// The target node of the connection.
  final Node<T> targetNode;

  /// The target port of the connection.
  final Port targetPort;

  /// Existing connection IDs from the source port.
  ///
  /// These connections will be removed if the port doesn't allow multiple
  /// connections and the new connection is created.
  final List<String> existingSourceConnections;

  /// Existing connection IDs to the target port.
  ///
  /// These connections will be removed if the port doesn't allow multiple
  /// connections and the new connection is created.
  final List<String> existingTargetConnections;

  /// Whether this connection goes from an output port to an input port.
  ///
  /// This is the typical and recommended connection direction.
  bool get isOutputToInput => sourcePort.isOutput && targetPort.isInput;

  /// Whether this connection goes from an input port to an output port.
  ///
  /// This is the reverse of the typical direction. Some applications may
  /// allow or disallow this based on their requirements.
  bool get isInputToOutput => sourcePort.isInput && targetPort.isOutput;

  /// Whether this is a self-connection (connecting a node to itself).
  ///
  /// Many applications disallow self-connections to prevent cycles,
  /// but some may allow them for specific use cases.
  bool get isSelfConnection => sourceNode.id == targetNode.id;

  /// Whether this is connecting a port to itself.
  ///
  /// This should typically be disallowed as it serves no practical purpose.
  bool get isSamePort =>
      sourceNode.id == targetNode.id && sourcePort.id == targetPort.id;
}
