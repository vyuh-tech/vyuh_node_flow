---
title: Serialization
description: Save and load your node flow graphs
---

# Serialization

::: details 🖼️ Serialization Overview
Diagram showing graph data flow: NodeFlowController → toJson() → JSON structure (nodes array, connections array, annotations array, viewport state) → File/Database/Cloud. Reverse arrow showing fromJson() loading back into controller.
:::

Vyuh Node Flow provides built-in support for serializing and deserializing graphs to/from JSON, making it easy to save and load workflows.

## Basic Serialization

::: code-group

```dart [Export to JSON]
// Export the graph
final graph = controller.exportGraph();

// Convert to JSON (provide a converter for your custom node data)
final json = graph.toJson((data) => data.toJson());

// Convert to JSON string
final jsonString = jsonEncode(json);

// Save to file, database, etc.
await saveToFile(jsonString);
```

```dart [Import from JSON]
// Load JSON string
final jsonString = await loadFromFile();

// Parse JSON
final json = jsonDecode(jsonString);

// Create graph from JSON (provide a converter for your custom node data)
final graph = NodeGraph.fromJson(json, (map) => MyNodeData.fromJson(map));

// Load into controller
controller.loadGraph(graph);
```

:::

## Complete Example

```dart
class FlowEditorWithSaveLoad extends StatefulWidget {
  @override
  State<FlowEditorWithSaveLoad> createState() =>
      _FlowEditorWithSaveLoadState();
}

class _FlowEditorWithSaveLoadState
    extends State<FlowEditorWithSaveLoad> {
  late final NodeFlowController<MyNodeData, dynamic> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<MyNodeData, dynamic>();
  }

  Future<void> _saveGraph() async {
    try {
      // Export and serialize graph
      final graph = controller.exportGraph();
      final json = graph.toJson((data) => data.toJson());
      final jsonString = jsonEncode(json);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_graph', jsonString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Graph saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving graph: $e')),
      );
    }
  }

  Future<void> _loadGraph() async {
    try {
      // Load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('saved_graph');

      if (jsonString == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No saved graph found')),
        );
        return;
      }

      // Deserialize and load
      final json = jsonDecode(jsonString);
      final graph = NodeGraph.fromJson(
        json,
        (map) => MyNodeData.fromJson(map),
      );
      controller.loadGraph(graph);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Graph loaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading graph: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flow Editor'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveGraph,
            tooltip: 'Save',
          ),
          IconButton(
            icon: Icon(Icons.folder_open),
            onPressed: _loadGraph,
            tooltip: 'Load',
          ),
        ],
      ),
      body: NodeFlowEditor<MyNodeData, dynamic>(
        controller: controller,
        nodeBuilder: (context, node) => MyNodeWidget(node: node),
        enablePanning: true,
        enableZooming: true,
      ),
    );
  }
}
```

## Custom Data Serialization

Your custom data class needs a `toJson()` method and a factory for deserialization:

```dart
class WorkflowNodeData {
  final String title;
  final String description;
  final Map<String, dynamic> config;

  WorkflowNodeData({
    required this.title,
    this.description = '',
    this.config = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'config': config,
    };
  }

  // Factory constructor for creating from JSON
  factory WorkflowNodeData.fromJson(Map<String, dynamic> json) {
    return WorkflowNodeData(
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }
}
```

## File-Based Serialization

::: code-group

```dart [Save to File]
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveGraphToFile(String filename) async {
  try {
    // Get documents directory
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.json');

    // Export and serialize graph
    final graph = controller.exportGraph();
    final json = graph.toJson((data) => data.toJson());
    final jsonString = jsonEncode(json);

    // Write to file
    await file.writeAsString(jsonString);
  } catch (e) {
    print('Error saving: $e');
  }
}
```

```dart [Load from File]
Future<void> loadGraphFromFile(String filename) async {
  try {
    // Get documents directory
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.json');

    // Check if file exists
    if (!await file.exists()) {
      throw Exception('File not found');
    }

    // Read from file
    final jsonString = await file.readAsString();

    // Deserialize and load
    final json = jsonDecode(jsonString);
    final graph = NodeGraph.fromJson(
      json,
      (map) => MyNodeData.fromJson(map),
    );
    controller.loadGraph(graph);
  } catch (e) {
    print('Error loading: $e');
  }
}
```

:::

## Export/Import with Metadata

Add metadata to your saved graphs:

```dart
class GraphDocument {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final Map<String, dynamic> graphData;
  final Map<String, dynamic> metadata;

  GraphDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.graphData,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'graphData': graphData,
      'metadata': metadata,
    };
  }

  factory GraphDocument.fromJson(Map<String, dynamic> json) {
    return GraphDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      graphData: json['graphData'] as Map<String, dynamic>,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

// Save with metadata
Future<void> saveDocument(String name) async {
  final graph = controller.exportGraph();
  final graphData = graph.toJson((data) => data.toJson());

  final document = GraphDocument(
    id: Uuid().v4(),
    name: name,
    createdAt: DateTime.now(),
    modifiedAt: DateTime.now(),
    graphData: graphData,
    metadata: {
      'version': '1.0',
      'author': 'user@example.com',
      'nodeCount': controller.nodes.length,
    },
  );

  final jsonString = jsonEncode(document.toJson());
  await saveToFile(jsonString);
}
```

## Cloud Storage Integration

### Firebase Example

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveToFirebase(String userId, String graphName) async {
  try {
    final graph = controller.exportGraph();
    final graphData = graph.toJson((data) => data.toJson());

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('graphs')
        .doc(graphName)
        .set({
      'data': graphData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error saving to Firebase: $e');
  }
}

Future<void> loadFromFirebase(String userId, String graphName) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('graphs')
        .doc(graphName)
        .get();

    if (doc.exists) {
      final graphData = doc.data()!['data'] as Map<String, dynamic>;
      final graph = NodeGraph.fromJson(
        graphData,
        (map) => MyNodeData.fromJson(map),
      );
      controller.loadGraph(graph);
    }
  } catch (e) {
    print('Error loading from Firebase: $e');
  }
}
```

## Versioning

Handle different graph versions:

```dart
class VersionedGraph {
  static const currentVersion = 2;

  final int version;
  final Map<String, dynamic> data;

  VersionedGraph({
    required this.version,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'data': data,
  };

  factory VersionedGraph.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    var data = json['data'] as Map<String, dynamic>;

    // Migrate from old versions
    if (version < currentVersion) {
      data = _migrateFromVersion(version, data);
    }

    return VersionedGraph(
      version: currentVersion,
      data: data,
    );
  }

  static Map<String, dynamic> _migrateFromVersion(
    int fromVersion,
    Map<String, dynamic> data,
  ) {
    var migratedData = Map<String, dynamic>.from(data);

    // Migrate v1 to v2
    if (fromVersion == 1) {
      // Add new fields, rename old ones, etc.
      migratedData = _migrateV1ToV2(migratedData);
    }

    return migratedData;
  }

  static Map<String, dynamic> _migrateV1ToV2(Map<String, dynamic> data) {
    // Migration logic
    return data;
  }
}
```

## Best Practices

1. **Version Your Data**: Include version numbers in serialized data
2. **Validate**: Validate loaded data before applying to graph
3. **Error Handling**: Wrap serialize/deserialize in try-catch
4. **Backup**: Keep backups before loading new data
5. **Compression**: Consider compressing large graphs
6. **Encryption**: Encrypt sensitive graph data
7. **Testing**: Test save/load with various graph configurations

## See Also

- [Graph API](/docs/concepts/controller)
- [Node Data](/docs/concepts/nodes)
- [Examples](/docs/examples/)
