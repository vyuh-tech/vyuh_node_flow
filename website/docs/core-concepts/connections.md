---
title: Connections
description: Understanding connections between nodes
---

# Connections

Connections (also called edges or links) connect ports on different nodes, representing relationships or data flow in your graph.

## Connection Structure

```dart
class Connection {
  final String id;              // Unique identifier
  final String sourceNodeId;    // Source node ID
  final String sourcePortId;    // Source port ID
  final String targetNodeId;    // Target node ID
  final String targetPortId;    // Target port ID
  final String? label;          // Optional middle label
  final String? startLabel;     // Optional start label
  final String? endLabel;       // Optional end label
}
```

## Creating Connections

::: code-group

```dart [Basic Connection]
final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'node-1-out',
  targetNodeId: 'node-2',
  targetPortId: 'node-2-in',
);

controller.addConnection(connection);
```

```dart [Connection with Labels]
final connection = Connection(
  id: 'conn-2',
  sourceNodeId: 'node-1',
  sourcePortId: 'node-1-out',
  targetNodeId: 'node-2',
  targetPortId: 'node-2-in',
  label: 'Data Flow',        // Center label
  startLabel: 'Send',        // Label at source
  endLabel: 'Receive',       // Label at target
);

controller.addConnection(connection);
```

:::

## Connection Styles

::: details 🖼️ Connection Styles Comparison
Four-panel comparison showing the same two connected nodes with different connection styles: (1) Smoothstep - smooth orthogonal paths with rounded corners, (2) Bezier - flowing curved S-shape, (3) Step - sharp 90-degree right angles, (4) Straight - direct diagonal line. Each labeled with style name.
:::

Vyuh Node Flow supports multiple connection rendering styles:

### Smoothstep (Recommended)

```dart
theme: NodeFlowTheme(
  connectionStyle: ConnectionStyles.smoothstep,
)
```

Smooth orthogonal paths that maintain horizontal/vertical segments.

### Bezier

```dart
theme: NodeFlowTheme(
  connectionStyle: ConnectionStyles.bezier,
)
```

Curved Bezier paths for a flowing appearance.

### Step

```dart
theme: NodeFlowTheme(
  connectionStyle: ConnectionStyles.step,
)
```

Sharp right-angle paths with clear horizontal and vertical segments.

### Straight

```dart
theme: NodeFlowTheme(
  connectionStyle: ConnectionStyles.straight,
)
```

Direct straight lines between ports.

## Connection Theme

Customize connection appearance:

```dart
theme: NodeFlowTheme(
  connectionTheme: ConnectionTheme(
    color: Colors.blue,              // Default color
    strokeWidth: 2,                  // Line width
    selectedColor: Colors.blue[700]!, // Selected color
    selectedStrokeWidth: 3,          // Selected width
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint(
      shape: EndpointShape.triangle,
      size: 9,
      color: Colors.blue,
    ),
    dashPattern: null,               // Solid line (default)
  ),
)
```

::: code-group

```dart [Dashed Connections]
connectionTheme: ConnectionTheme(
  color: Colors.grey,
  strokeWidth: 2,
  dashPattern: [8, 4], // 8px dash, 4px gap
)
```

```dart [Arrows and Endpoints]
// Triangle arrow at end
endPoint: ConnectionEndPoint(
  shape: EndpointShape.triangle,
  size: 10,
  color: Colors.blue,
)

// Circle at start
startPoint: ConnectionEndPoint(
  shape: EndpointShape.circle,
  size: 6,
  color: Colors.blue,
)

// No endpoints
startPoint: ConnectionEndPoint.none,
endPoint: ConnectionEndPoint.none,
```

:::

## Temporary Connections

When creating connections by dragging, a temporary connection is shown:

```dart
theme: NodeFlowTheme(
  temporaryConnectionStyle: ConnectionStyles.smoothstep,
  temporaryConnectionTheme: ConnectionTheme(
    color: Colors.blue.withOpacity(0.5),
    strokeWidth: 2,
    dashPattern: [8, 4],
    endPoint: ConnectionEndPoint(
      shape: EndpointShape.triangle,
      size: 9,
    ),
  ),
)
```

## Connection Events

Handle connection lifecycle and interactions using the `ConnectionEvents` class. See [Event System](/docs/advanced/events) for complete documentation.

::: code-group

```dart [Lifecycle Events]
NodeFlowEditor<MyData>(
  controller: controller,
  events: NodeFlowEvents(
    connection: ConnectionEvents(
      onCreated: (connection) {
        print('Created: ${connection.id}');
        saveConnection(connection);
      },
      onDeleted: (connection) {
        print('Deleted: ${connection.id}');
        deleteConnection(connection.id);
      },
      onSelected: (connection) {
        print('Selected: ${connection?.id}');
      },
    ),
  ),
)
```

```dart [Validation]
NodeFlowEditor<MyData>(
  controller: controller,
  events: NodeFlowEvents(
    connection: ConnectionEvents(
      onBeforeStart: (context) {
        // Prevent connections from disabled nodes
        if (context.sourceNode.data.isDisabled) {
          return ConnectionValidationResult(
            allowed: false,
            reason: 'Cannot connect from disabled node',
          );
        }
        return ConnectionValidationResult(allowed: true);
      },
      onBeforeComplete: (context) {
        // Prevent self-connections
        if (context.sourceNode.id == context.targetNode.id) {
          return ConnectionValidationResult(
            allowed: false,
            reason: 'Cannot connect to same node',
          );
        }
        return ConnectionValidationResult(allowed: true);
      },
    ),
  ),
)
```

```dart [Interactions]
NodeFlowEditor<MyData>(
  controller: controller,
  events: NodeFlowEvents(
    connection: ConnectionEvents(
      onTap: (connection) => _selectConnection(connection),
      onDoubleTap: (connection) => _editConnection(connection),
      onContextMenu: (connection, position) {
        _showConnectionMenu(connection, position);
      },
      onConnectStart: (nodeId, portId, isOutput) {
        print('Starting connection from $nodeId:$portId');
      },
      onConnectEnd: (success) {
        print(success ? 'Connected' : 'Cancelled');
      },
    ),
  ),
)
```

:::

::: tip
Use `onBeforeComplete` for validation instead of removing connections after creation. This provides better UX with visual feedback before the connection is made.

:::

## Connection Operations

::: code-group

```dart [Add Connection]
controller.addConnection(connection);
```

```dart [Remove Connection]
controller.removeConnection('conn-1');
```

```dart [Get Connection]
final connection = controller.getConnection('conn-1');
```

```dart [Get All Connections]
final allConnections = controller.connections;
```

```dart [Get Connections for Node]
// Get all connections for a node (built-in method)
final nodeConnections = controller.getConnectionsForNode('node-1');

// Get connections from a specific port
final fromPort = controller.getConnectionsFromPort('node-1', 'out-1');

// Get connections to a specific port
final toPort = controller.getConnectionsToPort('node-2', 'in-1');
```

:::

## Connection Validation

::: code-group

```dart [Prevent Self-Connections]
bool isValidConnection(Connection connection) {
  if (connection.sourceNodeId == connection.targetNodeId) {
    return false;
  }
  return true;
}
```

```dart [Prevent Duplicate Connections]
bool isDuplicateConnection(Connection connection) {
  return controller.connections.any(
    (c) =>
        c.sourceNodeId == connection.sourceNodeId &&
        c.sourcePortId == connection.sourcePortId &&
        c.targetNodeId == connection.targetNodeId &&
        c.targetPortId == connection.targetPortId,
  );
}
```

```dart [Port Type Validation]
bool validatePortTypes(Connection connection) {
  final sourceNode = controller.getNode(connection.sourceNodeId);
  final targetNode = controller.getNode(connection.targetNodeId);

  if (sourceNode == null || targetNode == null) return false;

  final sourcePort = sourceNode.outputPorts.firstWhere(
    (p) => p.id == connection.sourcePortId,
    orElse: () => throw Exception('Source port not found'),
  );

  final targetPort = targetNode.inputPorts.firstWhere(
    (p) => p.id == connection.targetPortId,
    orElse: () => throw Exception('Target port not found'),
  );

  // Check if source can connect to target
  return sourcePort.type != PortType.target &&
      targetPort.type != PortType.source;
}
```

```dart [Cycle Detection]
bool wouldCreateCycle(Connection newConnection) {
  // Build adjacency list
  final adjacency = <String, Set<String>>{};

  // Add existing connections
  for (final conn in controller.connections) {
    adjacency.putIfAbsent(conn.sourceNodeId, () => {})
        .add(conn.targetNodeId);
  }

  // Add the new connection temporarily
  adjacency.putIfAbsent(newConnection.sourceNodeId, () => {})
      .add(newConnection.targetNodeId);

  // Check for cycle using DFS
  final visited = <String>{};
  final recStack = <String>{};

  bool hasCycle(String node) {
    if (!visited.contains(node)) {
      visited.add(node);
      recStack.add(node);

      final neighbors = adjacency[node] ?? {};
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor) && hasCycle(neighbor)) {
          return true;
        } else if (recStack.contains(neighbor)) {
          return true;
        }
      }
    }
    recStack.remove(node);
    return false;
  }

  return hasCycle(newConnection.sourceNodeId);
}
```

```dart [Complete Validation]
ConnectionValidationResult validateConnection(Connection connection) {
  // Check self-connection
  if (connection.sourceNodeId == connection.targetNodeId) {
    return ConnectionValidationResult.error('Cannot connect node to itself');
  }

  // Check duplicate
  if (isDuplicateConnection(connection)) {
    return ConnectionValidationResult.error('Connection already exists');
  }

  // Check port types
  if (!validatePortTypes(connection)) {
    return ConnectionValidationResult.error('Invalid port types');
  }

  // Check cycles
  if (wouldCreateCycle(connection)) {
    return ConnectionValidationResult.error('Would create a cycle');
  }

  return ConnectionValidationResult.valid();
}

class ConnectionValidationResult {
  final bool isValid;
  final String? errorMessage;

  ConnectionValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  ConnectionValidationResult.error(this.errorMessage) : isValid = false;
}
```

:::

## Conditional Connection Styling

Style connections based on their properties using connection-specific overrides:

```dart
// Create connections with different colors based on type
final errorConnection = Connection(
  id: 'error-conn',
  sourceNodeId: 'node-1',
  sourcePortId: 'error-out',
  targetNodeId: 'node-2',
  targetPortId: 'in',
  color: Colors.red,  // Override theme color
  label: 'Error Path',
);

final successConnection = Connection(
  id: 'success-conn',
  sourceNodeId: 'node-1',
  sourcePortId: 'success-out',
  targetNodeId: 'node-3',
  targetPortId: 'in',
  color: Colors.green,  // Override theme color
  label: 'Success Path',
);

controller.addConnection(errorConnection);
controller.addConnection(successConnection);
```

## Connection Labels

::: code-group

```dart [Static Labels]
Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'port-out',
  targetNodeId: 'node-2',
  targetPortId: 'port-in',
  label: 'Data Flow',
  startLabel: 'Send',
  endLabel: 'Receive',
)
```

```dart [Dynamic Labels]
Connection getConnectionWithDynamicLabel(
  String sourceId,
  String targetId,
) {
  final sourceNode = controller.getNode(sourceId);
  final targetNode = controller.getNode(targetId);

  final label = '${sourceNode?.data.label} → ${targetNode?.data.label}';

  return Connection(
    id: 'conn-${DateTime.now().millisecondsSinceEpoch}',
    sourceNodeId: sourceId,
    sourcePortId: 'out',
    targetNodeId: targetId,
    targetPortId: 'in',
    label: label,
  );
}
```

```dart [Label Theme]
theme: NodeFlowTheme(
  labelTheme: LabelTheme(
    fontSize: 12,
    color: Colors.black87,
    backgroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    borderRadius: 4,
    border: Border.all(color: Colors.grey[300]!),
  ),
)
```

:::

## Connection Selection

Connections can be selected (future feature):

```dart
// Select connection
controller.selectConnection('conn-1');

// Clear connection selection
controller.clearConnectionSelection();

// Get selected connections
final selectedConnections = controller.selectedConnectionIds;
```

## Interactive Connections

Handle connection interactions through the events API:

```dart
events: NodeFlowEvents(
  connection: ConnectionEvents(
    onTap: (connection) {
      showDialog(
        context: context,
        builder: (_) => ConnectionPropertiesDialog(connection: connection),
      );
    },
    onDoubleTap: (connection) => _editConnection(connection),
    onContextMenu: (connection, position) => _showMenu(connection, position),
  ),
)
```

## Connection Serialization

Connections are automatically serialized with the graph:

```dart
// Export graph (includes nodes, connections, annotations)
final graph = controller.exportGraph();
final json = graph.toJson((data) => data.toJson());

// Load graph
final loadedGraph = NodeGraph.fromJson(json, (map) => MyData.fromJson(map));
controller.loadGraph(loadedGraph);
```

## Best Practices

1. **Unique IDs**: Use unique, meaningful connection IDs
2. **Validation**: Always validate connections before adding
3. **Cleanup**: Remove connections when deleting nodes
4. **Visual Feedback**: Use different colors for different connection types
5. **Labels**: Use labels sparingly to avoid clutter
6. **Performance**: Limit the number of connections for smooth rendering
7. **Cycles**: Decide if cycles are allowed in your graph

## Common Patterns

::: code-group

```dart [Connection Factory]
class ConnectionFactory {
  static String generateId() {
    return 'conn-${DateTime.now().millisecondsSinceEpoch}';
  }

  static Connection create({
    required String sourceNodeId,
    required String sourcePortId,
    required String targetNodeId,
    required String targetPortId,
    String? label,
  }) {
    return Connection(
      id: generateId(),
      sourceNodeId: sourceNodeId,
      sourcePortId: sourcePortId,
      targetNodeId: targetNodeId,
      targetPortId: targetPortId,
      label: label,
    );
  }
}
```

```dart [Auto-Connect Nodes]
void autoConnect(String sourceNodeId, String targetNodeId) {
  final sourceNode = controller.getNode(sourceNodeId);
  final targetNode = controller.getNode(targetNodeId);

  if (sourceNode == null || targetNode == null) return;
  if (sourceNode.outputPorts.isEmpty || targetNode.inputPorts.isEmpty) return;

  // Connect first available ports
  final connection = Connection(
    id: ConnectionFactory.generateId(),
    sourceNodeId: sourceNodeId,
    sourcePortId: sourceNode.outputPorts.first.id,
    targetNodeId: targetNodeId,
    targetPortId: targetNode.inputPorts.first.id,
  );

  controller.addConnection(connection);
}
```

:::

## Next Steps

- Learn about [Event System](/docs/advanced/events) for connection validation
- Explore [Connection Styles](/docs/theming/connection-styles)
- See [Connection Effects](/docs/theming/connection-effects) for animations
