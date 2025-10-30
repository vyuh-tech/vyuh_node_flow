import '../nodes/node.dart';
import '../ports/port.dart';

/// Result of a connection validation check
class ConnectionValidationResult {
  const ConnectionValidationResult({
    this.allowed = true,
    this.reason,
    this.showMessage = false,
  });

  /// Whether the connection should be allowed
  final bool allowed;

  /// Optional reason for denying the connection (for debugging/logging)
  final String? reason;

  /// Whether to show a visual message to the user when denied
  final bool showMessage;

  /// Create a result that allows the connection
  const ConnectionValidationResult.allow() : this();

  /// Create a result that denies the connection
  const ConnectionValidationResult.deny({
    String? reason,
    bool showMessage = false,
  }) : this(allowed: false, reason: reason, showMessage: showMessage);
}

/// Context provided when starting a connection from a port
class ConnectionStartContext<T> {
  const ConnectionStartContext({
    required this.sourceNode,
    required this.sourcePort,
    required this.existingConnections,
  });

  /// The node where the connection is starting
  final Node<T> sourceNode;

  /// The port where the connection is starting
  final Port sourcePort;

  /// Existing connections from this port (will be removed if port doesn't allow multiple)
  final List<String> existingConnections;

  /// Whether this is an output port
  bool get isOutputPort => sourceNode.outputPorts.contains(sourcePort);

  /// Whether this is an input port
  bool get isInputPort => sourceNode.inputPorts.contains(sourcePort);
}

/// Context provided when attempting to complete a connection
class ConnectionCompleteContext<T> {
  const ConnectionCompleteContext({
    required this.sourceNode,
    required this.sourcePort,
    required this.targetNode,
    required this.targetPort,
    required this.existingSourceConnections,
    required this.existingTargetConnections,
  });

  /// The source node of the connection
  final Node<T> sourceNode;

  /// The source port of the connection
  final Port sourcePort;

  /// The target node of the connection
  final Node<T> targetNode;

  /// The target port of the connection
  final Port targetPort;

  /// Existing connections from the source port (will be removed if port doesn't allow multiple)
  final List<String> existingSourceConnections;

  /// Existing connections to the target port (will be removed if port doesn't allow multiple)
  final List<String> existingTargetConnections;

  /// Whether this connection goes from output to input
  bool get isOutputToInput =>
      sourceNode.outputPorts.contains(sourcePort) &&
      targetNode.inputPorts.contains(targetPort);

  /// Whether this connection goes from input to output
  bool get isInputToOutput =>
      sourceNode.inputPorts.contains(sourcePort) &&
      targetNode.outputPorts.contains(targetPort);

  /// Whether this is a self-connection (same node)
  bool get isSelfConnection => sourceNode.id == targetNode.id;

  /// Whether this is connecting to the same port
  bool get isSamePort =>
      sourceNode.id == targetNode.id && sourcePort.id == targetPort.id;
}
