# Ultra-Fast Spatial Indexing System

A generic, high-performance spatial indexing system optimized for 2D objects with frequent position updates.

## Features

- **Grid-based spatial hashing** for O(visible) performance with large object counts
- **Smart caching** with automatic invalidation
- **Drag optimization mode** for ultra-fast updates during object movement
- **Multi-tier performance strategy** that adapts based on object count
- **Generic interface** that can be adapted for any 2D objects

## Performance Characteristics

- **Small counts (≤20 objects)**: Direct iteration `O(n)`
- **Medium counts (20-50 objects)**: Rect-based spatial index `O(visible)`  
- **Large counts (50+ objects)**: Grid-based spatial hashing `O(visible)`

## Usage

### Basic Usage

```dart
import 'package:vyuh_node_flow/spatial/spatial.dart';

// Define your 2D object
class MyObject implements SpatialIndexable {
  MyObject(this.id, this.position, this.size);
  
  @override
  final String id;
  final Offset position;
  final Size size;
  
  @override
  Rect getBounds() => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

// Create and use the spatial index
final spatialIndex = SpatialIndex<MyObject>(
  gridSize: 500.0,  // 500px grid cells
  enableCaching: true,
);

// Add objects
spatialIndex.addOrUpdate(MyObject('obj1', Offset(100, 100), Size(50, 50)));
spatialIndex.addOrUpdate(MyObject('obj2', Offset(200, 200), Size(50, 50)));

// Query visible objects
final viewport = Rect.fromLTWH(0, 0, 800, 600);
final visibleObjects = spatialIndex.query(viewport);
```

### Drag Optimization

For ultra-fast performance during object dragging:

```dart
// Start drag mode
spatialIndex.startDragging(['obj1', 'obj2']);

// During drag - ultra-fast updates
for (final object in objectsBeingDragged) {
  object.position += dragDelta;
}
spatialIndex.updateDraggingObjects(objectsBeingDragged);

// End drag mode - rebuilds spatial index for dragged objects
spatialIndex.endDragging();
```

### Node-Specific Usage

For ObservableNode objects, use the specialized adapter:

```dart
import 'package:vyuh_node_flow/spatial/spatial.dart';

final nodeSpatialIndex = NodeSpatialIndex<MyNodeData>(
  gridSize: 500.0,
  enableCaching: true,
);

// Add nodes
nodeSpatialIndex.addOrUpdateNode(myObservableNode);

// Query visible nodes
final visibleNodes = nodeSpatialIndex.queryNodes(viewport);

// Drag optimization
nodeSpatialIndex.startNodeDragging(['node1', 'node2']);
nodeSpatialIndex.updateDraggingNodes(draggedNodes);
nodeSpatialIndex.endNodeDragging();
```

### Performance Monitoring

```dart
// Get performance statistics
final stats = spatialIndex.stats;
print('Objects: ${stats.objectCount}');
print('Grid cells: ${stats.gridCellCount}');
print('Is dragging: ${stats.isDragging}');
print('Cache size: ${stats.cacheSize}');
```

## Implementation Details

### Grid-Based Spatial Hashing

The system divides 2D space into a grid and maintains sets of object IDs for each grid cell. When querying for visible objects, it only checks grid cells that intersect with the query bounds.

### Smart Caching

Results are cached and reused when the query bounds haven't changed significantly. Cache is automatically invalidated when objects move or are added/removed.

### Drag Optimization

During drag operations:
1. Spatial index updates are minimized
2. Only dragged objects are tracked
3. Full spatial index rebuild happens only when dragging ends
4. Cache invalidation is smart (only when dragging bounds intersect viewport)

### Multi-Tier Strategy

The system automatically chooses the best algorithm based on object count:
- **Direct iteration** for small counts (fastest for ≤20 objects)
- **Rect-based index** for medium counts (good balance for 20-50 objects)
- **Grid-based hashing** for large counts (optimal for 50+ objects)

## Thread Safety

This implementation is **not thread-safe**. Use appropriate synchronization if accessing from multiple threads.

## Memory Usage

- Grid cells are automatically cleaned up when empty
- Cached results are cleared when invalidated
- Memory usage scales with the number of unique grid cells occupied by objects