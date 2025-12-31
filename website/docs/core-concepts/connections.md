---
title: Connections
description: Understanding connections between nodes
---

# Connections

Connections (also called edges or links) connect ports on different nodes,
representing relationships or data flow in your graph.

## Connection Structure

```dart
class Connection {
  final String id;              // Unique identifier
  final String sourceNodeId;    // Source node ID
  final String sourcePortId;    // Source port ID
  final String targetNodeId;    // Target node ID
  final String targetPortId;    // Target port ID

  // Labels (ConnectionLabel objects, not strings)
  ConnectionLabel? startLabel;  // Label at start (anchor 0.0)
  ConnectionLabel? label;       // Label at center (anchor 0.5)
  ConnectionLabel? endLabel;    // Label at end (anchor 1.0)

  // Styling
  final ConnectionStyle? style;       // Custom style override
  final ConnectionEndPoint? startPoint; // Custom start marker
  final ConnectionEndPoint? endPoint;   // Custom end marker
  final double? startGap;             // Gap from source port
  final double? endGap;               // Gap from target port

  // State
  bool animated;                // Whether to show animation
  bool selected;                // Whether currently selected
  final bool locked;            // Whether deletion is prevented
}
```

## Connection Anatomy

::: details Connection Anatomy Diagram

<!-- TODO: Add visual diagram showing connection anatomy -->

A connection consists of the following visual elements:

**Path Elements:**

- **Connection Path** - The line itself rendered using `ConnectionStyle`
  (bezier, smoothstep, step, straight)
- **Path Stroke** - Line styling using `ConnectionTheme.color` and `strokeWidth`
- **Path Curvature** - Bezier curve control via
  `ConnectionTheme.bezierCurvature`
- **Corner Radius** - Rounded corners for step styles via
  `ConnectionTheme.cornerRadius`

**Endpoint Elements:**

- **Start Endpoint** - Marker at source port using `ConnectionEndPoint` (none,
  triangle, circle, diamond, rectangle, capsuleHalf)
- **End Endpoint** - Marker at target port using `ConnectionEndPoint`
- **Endpoint Colors** - Fill and border using `ConnectionTheme.endpointColor`
  and `endpointBorderColor`
- **Start/End Gaps** - Space between port and endpoint via `startGap` and
  `endGap`

**Label Elements:**

- **Start Label** - Text at anchor 0.0 (source port)
- **Center Label** - Text at anchor 0.5 (midpoint)
- **End Label** - Text at anchor 1.0 (target port)
- **Label Styling** - Background, border, text via `LabelTheme`

**Animation Elements:**

- **Animation Effect** - Visual effect (FlowingDashEffect, ParticleEffect,
  GradientFlowEffect, PulseEffect)
- **Dash Pattern** - Static dashes via `ConnectionTheme.dashPattern`

**State Colors:**

- **Default State** - Normal color using `ConnectionTheme.color`
- **Selected State** - When selected using `ConnectionTheme.selectedColor` and
  `selectedStrokeWidth`
- **Highlight State** - On hover using `ConnectionTheme.highlightColor`

**Control Points (Editable Paths):**

- **Waypoints** - User-defined control points stored in
  `Connection.controlPoints`
- **Control Point Handles** - Interactive handles for path editing :::

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
  startLabel: ConnectionLabel.start(text: 'Send'),
  label: ConnectionLabel.center(text: 'Data Flow'),
  endLabel: ConnectionLabel.end(text: 'Receive'),
);

controller.addConnection(connection);
```

```dart [Animated Connection]
final connection = Connection(
  id: 'conn-3',
  sourceNodeId: 'node-1',
  sourcePortId: 'node-1-out',
  targetNodeId: 'node-2',
  targetPortId: 'node-2-in',
  animated: true,
  style: ConnectionStyles.smoothstep,
);

controller.addConnection(connection);
```

:::

## Connection Styles

::: details Connection Styles Comparison Four-panel comparison showing the same
two connected nodes with different connection styles: (1) Smoothstep - smooth
orthogonal paths with rounded corners, (2) Bezier - flowing curved S-shape, (3)
Step - sharp 90-degree right angles, (4) Straight - direct diagonal line. Each
labeled with style name. :::

Vyuh Node Flow supports multiple connection rendering styles via
`ConnectionStyles`:

### Smoothstep (Recommended)

```dart
connectionTheme: ConnectionTheme.light.copyWith(
  style: ConnectionStyles.smoothstep,
)
```

Smooth orthogonal paths with rounded corners. This is the default.

### Bezier

```dart
connectionTheme: ConnectionTheme.light.copyWith(
  style: ConnectionStyles.bezier,
)
```

Curved Bezier paths for a flowing appearance.

### Step

```dart
connectionTheme: ConnectionTheme.light.copyWith(
  style: ConnectionStyles.step,
)
```

Sharp right-angle paths with clear horizontal and vertical segments.

### Straight

```dart
connectionTheme: ConnectionTheme.light.copyWith(
  style: ConnectionStyles.straight,
)
```

Direct straight lines between ports.

## Connection Theme

Customize connection appearance via `ConnectionTheme`:

```dart
theme: NodeFlowTheme.light.copyWith(
  connectionTheme: ConnectionTheme(
    style: ConnectionStyles.smoothstep,
    color: Colors.blue,
    selectedColor: Colors.blue.shade700,
    highlightColor: Colors.blue.shade400,
    highlightBorderColor: Colors.blue.shade800,
    strokeWidth: 2.0,
    selectedStrokeWidth: 3.0,
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.triangle,
    endpointColor: Colors.blue,
    endpointBorderColor: Colors.blue.shade800,
    endpointBorderWidth: 0.0,
    bezierCurvature: 0.5,
    cornerRadius: 4.0,
    portExtension: 20.0,
    backEdgeGap: 20.0,
    hitTolerance: 8.0,
    dashPattern: null,  // Solid line (default)
  ),
)
```

::: code-group

```dart [Dashed Connections]
connectionTheme: ConnectionTheme.light.copyWith(
  dashPattern: [8, 4], // 8px dash, 4px gap
)
```

```dart [Arrows and Endpoints]
// Triangle arrow at end (predefined)
endPoint: ConnectionEndPoint.triangle,

// Circle at start (predefined)
startPoint: ConnectionEndPoint.circle,

// Custom endpoint with colors
endPoint: ConnectionEndPoint(
  shape: MarkerShapes.triangle,
  size: Size.square(10),
  color: Colors.blue,
  borderColor: Colors.blue.shade800,
  borderWidth: 1.0,
),

// No endpoints
startPoint: ConnectionEndPoint.none,
endPoint: ConnectionEndPoint.none,
```

```dart [Predefined Endpoints]
// Available predefined endpoints:
ConnectionEndPoint.none        // No marker
ConnectionEndPoint.circle      // Circular dot
ConnectionEndPoint.triangle    // Arrow head
ConnectionEndPoint.rectangle   // Solid rectangle
ConnectionEndPoint.diamond     // Diamond shape
ConnectionEndPoint.capsuleHalf // Rounded arrow
```

:::

## Temporary Connections

When creating connections by dragging, a temporary connection is shown.
Configure via `temporaryConnectionTheme`:

```dart
theme: NodeFlowTheme.light.copyWith(
  temporaryConnectionTheme: ConnectionTheme.light.copyWith(
    color: Colors.grey,
    strokeWidth: 2,
    dashPattern: [5, 5],
    endPoint: ConnectionEndPoint.capsuleHalf,
  ),
)
```

## Connection Events

Handle connection lifecycle and interactions using `ConnectionEvents`. See
[Event System](/docs/advanced/events) for complete documentation.

::: code-group

```dart [Lifecycle Events]
NodeFlowEditor<MyData, dynamic>(
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
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  events: NodeFlowEvents(
    connection: ConnectionEvents(
      onBeforeStart: (context) {
        // Prevent connections from disabled nodes
        if (context.sourceNode.data.isDisabled) {
          return ConnectionValidationResult.deny(
            reason: 'Cannot connect from disabled node',
            showMessage: true,
          );
        }
        return ConnectionValidationResult.allow();
      },
      onBeforeComplete: (context) {
        // Prevent self-connections
        if (context.isSelfConnection) {
          return ConnectionValidationResult.deny(
            reason: 'Cannot connect to same node',
            showMessage: true,
          );
        }
        return ConnectionValidationResult.allow();
      },
    ),
  ),
)
```

```dart [Interactions]
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  events: NodeFlowEvents(
    connection: ConnectionEvents(
      onTap: (connection) => _selectConnection(connection),
      onDoubleTap: (connection) => _editConnection(connection),
      onContextMenu: (connection, screenPosition) {
        _showConnectionMenu(connection, screenPosition);
      },
      onConnectStart: (sourceNode, sourcePort) {
        print('Starting connection from ${sourceNode.id}:${sourcePort.id}');
      },
      onConnectEnd: (targetNode, targetPort, position) {
        if (targetNode != null) {
          print('Connected to ${targetNode.id}');
        } else {
          print('Connection cancelled at $position');
        }
      },
    ),
  ),
)
```

:::

::: tip Use `onBeforeComplete` for validation instead of removing connections
after creation. This provides better UX with visual feedback before the
connection is made. :::

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

The `ConnectionValidationResult` class is used to control connection creation:

```dart
// Allow connection
ConnectionValidationResult.allow()

// Deny with reason
ConnectionValidationResult.deny(
  reason: 'Cannot connect input to input',
  showMessage: true,  // Show visual feedback to user
)

// Custom result
ConnectionValidationResult(
  allowed: isValid,
  reason: validationMessage,
  showMessage: true,
)
```

### Validation Contexts

Two context objects provide information during validation:

```dart
// ConnectionStartContext - when starting a drag
class ConnectionStartContext<T> {
  final Node<T> sourceNode;
  final Port sourcePort;
  final List<String> existingConnections;

  bool get isOutputPort;
  bool get isInputPort;
}

// ConnectionCompleteContext - when completing a connection
class ConnectionCompleteContext<T> {
  final Node<T> sourceNode;
  final Port sourcePort;
  final Node<T> targetNode;
  final Port targetPort;
  final List<String> existingSourceConnections;
  final List<String> existingTargetConnections;

  bool get isOutputToInput;
  bool get isInputToOutput;
  bool get isSelfConnection;
  bool get isSamePort;
}
```

::: code-group

```dart [Prevent Self-Connections]
onBeforeComplete: (context) {
  if (context.isSelfConnection) {
    return ConnectionValidationResult.deny(
      reason: 'Cannot connect node to itself',
    );
  }
  return ConnectionValidationResult.allow();
}
```

```dart [Port Type Validation]
onBeforeComplete: (context) {
  // Only allow output-to-input connections
  if (!context.isOutputToInput) {
    return ConnectionValidationResult.deny(
      reason: 'Must connect output to input',
      showMessage: true,
    );
  }
  return ConnectionValidationResult.allow();
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

// Use built-in cycle detection
final hasCycles = controller.hasCycles();
final cycles = controller.getCycles();
```

:::

## Connection Labels

Labels use the `ConnectionLabel` class with anchor positioning:

::: code-group

```dart [Factory Constructors]
// Start label (anchor 0.0 - at source)
ConnectionLabel.start(text: 'Send')

// Center label (anchor 0.5 - at midpoint)
ConnectionLabel.center(text: 'Data Flow')

// End label (anchor 1.0 - at target)
ConnectionLabel.end(text: 'Receive')

// With perpendicular offset
ConnectionLabel.center(text: 'Flow', offset: 10.0)
```

```dart [Custom Anchor Position]
// Custom position (0.0 to 1.0)
ConnectionLabel(
  text: 'Custom',
  anchor: 0.25,  // 25% along the path
  offset: -5.0,  // Offset perpendicular to path
)
```

```dart [Updating Labels]
// Labels are reactive - changes trigger UI updates
connection.label = ConnectionLabel.center(text: 'Updated');
connection.startLabel = null;  // Remove label

// Or update existing label
connection.label?.updateText('New Text');
connection.label?.updateAnchor(0.75);
```

```dart [Label Theme]
theme: NodeFlowTheme.light.copyWith(
  labelTheme: LabelTheme(
    textStyle: TextStyle(
      fontSize: 12,
      color: Colors.black87,
      fontWeight: FontWeight.w500,
    ),
    backgroundColor: Colors.white,
    border: Border.all(color: Colors.grey.shade300),
    borderRadius: BorderRadius.circular(4),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    maxWidth: 150,    // Wrap text after 150px
    maxLines: 2,      // Maximum 2 lines
    offset: 0.0,      // Default perpendicular offset
    labelGap: 8.0,    // Minimum gap from endpoints
  ),
)
```

:::

## Connection Selection

```dart
// Select connection
controller.selectConnection('conn-1');

// Toggle selection
controller.selectConnection('conn-1', toggle: true);

// Clear connection selection
controller.clearConnectionSelection();

// Check if selected
final isSelected = controller.isConnectionSelected('conn-1');

// Get selected connection IDs
final selectedIds = controller.selectedConnectionIds;

// Select all connections
controller.selectAllConnections();
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
    onContextMenu: (connection, screenPosition) {
      _showMenu(connection, screenPosition);
    },
    onMouseEnter: (connection) => _highlightConnection(connection),
    onMouseLeave: (connection) => _unhighlightConnection(connection),
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
2. **Validation**: Use `onBeforeComplete` for validation to provide immediate
   feedback
3. **Cleanup**: Connections are automatically removed when nodes are deleted
4. **Visual Feedback**: Use different endpoint styles for different connection
   types
5. **Labels**: Use labels sparingly to avoid clutter
6. **Performance**: Limit the number of connections for smooth rendering
7. **Cycles**: Use `controller.hasCycles()` to detect cycles in your graph

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
    String? labelText,
  }) {
    return Connection(
      id: generateId(),
      sourceNodeId: sourceNodeId,
      sourcePortId: sourcePortId,
      targetNodeId: targetNodeId,
      targetPortId: targetPortId,
      label: labelText != null
          ? ConnectionLabel.center(text: labelText)
          : null,
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

```dart [Locked Connections]
// Create a connection that cannot be deleted
final connection = Connection(
  id: 'required-conn',
  sourceNodeId: 'node-1',
  sourcePortId: 'out',
  targetNodeId: 'node-2',
  targetPortId: 'in',
  locked: true,  // Prevents deletion
);
```

:::

## Next Steps

- Learn about [Event System](/docs/advanced/events) for connection validation
- Explore [Connection Styles](/docs/theming/connection-styles)
- See [Connection Effects](/docs/theming/connection-effects) for animations
