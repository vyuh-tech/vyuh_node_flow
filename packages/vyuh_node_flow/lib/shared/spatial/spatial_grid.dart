import 'package:flutter/material.dart';

/// Generic spatial indexing interface for 2D objects
abstract class SpatialIndexable {
  String get id;

  Rect getBounds();
}

/// Ultra-fast spatial grid system using grid-based hashing.
/// This is the low-level implementation used by [SpatialIndex].
/// Optimized for large numbers of 2D objects with frequent position updates.
class SpatialGrid<T extends SpatialIndexable> {
  SpatialGrid({this.gridSize = 500.0, this.enableCaching = true})
    : _spatialGrid = <String, Set<String>>{},
      _spatialRects = <String, Rect>{},
      _objects = <String, T>{},
      _cachedVisibleObjects = <T>[],
      _lastQueryBounds = Rect.zero;

  final double gridSize;
  final bool enableCaching;

  // Core spatial data structures
  final Map<String, Set<String>> _spatialGrid;
  final Map<String, Rect> _spatialRects;
  final Map<String, T> _objects;

  // Ultra-fast rendering optimization fields
  List<T> _cachedVisibleObjects;
  Rect _lastQueryBounds;

  // Dragging state - spatial index rebuilt at drag end
  bool _isDragging = false;
  Set<String> _draggingObjectIds = <String>{};

  // Performance counters and batching
  DateTime _lastBatchUpdate = DateTime.now();
  final Set<String> _pendingUpdates = <String>{};
  static const int _batchDelayMs = 8; // ~120fps batching

  /// Add or update an object in the spatial index
  void addOrUpdate(T object) {
    _objects[object.id] = object;

    if (_isDragging && _draggingObjectIds.contains(object.id)) {
      // For dragging objects, update immediately
      _updateSpatialIndexForObject(object);
    } else {
      // For non-dragging objects, batch updates for better performance
      _pendingUpdates.add(object.id);
      _processPendingUpdatesIfNeeded();
    }
  }

  /// Remove an object from the spatial index
  void remove(String objectId) {
    final object = _objects.remove(objectId);
    if (object != null) {
      _removeFromSpatialGrid(object);
      _spatialRects.remove(objectId);
      _invalidateCache();
    }
  }

  /// Clear all objects from the spatial index
  void clear() {
    if (_objects.isEmpty) return;
    _objects.clear();
    _spatialGrid.clear();
    _spatialRects.clear();
    _invalidateCache();
  }

  /// Query objects near a specific point for hit testing.
  ///
  /// Returns objects in the cell containing the point plus neighboring cells
  /// to handle objects that span cell boundaries. Results are not cached
  /// since hit testing typically involves different points each time.
  List<T> queryPoint(Offset point, {double radius = 0}) {
    final result = <T>[];
    final checkedObjects = <String>{};

    // Calculate the cell range to check
    final minX = ((point.dx - radius) / gridSize).floor();
    final maxX = ((point.dx + radius) / gridSize).floor();
    final minY = ((point.dy - radius) / gridSize).floor();
    final maxY = ((point.dy + radius) / gridSize).floor();

    // Check all cells in range (typically just 1-4 cells for small radius)
    for (var x = minX; x <= maxX; x++) {
      for (var y = minY; y <= maxY; y++) {
        final cellKey = '${x}_$y';
        final objectIds = _spatialGrid[cellKey];

        if (objectIds != null) {
          for (final objectId in objectIds) {
            if (checkedObjects.add(objectId)) {
              final object = _objects[objectId];
              if (object != null) {
                final bounds = object.getBounds();
                // Check if point is within bounds (with optional radius expansion)
                if (radius > 0) {
                  if (bounds.inflate(radius).contains(point)) {
                    result.add(object);
                  }
                } else {
                  if (bounds.contains(point)) {
                    result.add(object);
                  }
                }
              }
            }
          }
        }
      }
    }

    return result;
  }

  /// Ultra-fast query with surgical caching
  List<T> query(Rect bounds) {
    // Use surgical cache during dragging for ultra-fast updates
    if (_isDragging && _shouldUseSurgicalCache(bounds)) {
      return _applySurgicalUpdates(bounds);
    }

    if (_shouldUseCache(bounds)) {
      return _cachedVisibleObjects;
    }

    final result = <T>[];

    // Use spatial grid for large object counts
    if (_objects.length > 50 && _spatialGrid.isNotEmpty) {
      _queryWithSpatialGrid(bounds, result);
    } else if (_objects.length > 20 && _spatialRects.isNotEmpty) {
      _queryWithSpatialRects(bounds, result);
    } else {
      _queryDirectIteration(bounds, result);
    }

    // Cache result for next query
    if (enableCaching) {
      _lastQueryBounds = bounds;
      _cachedVisibleObjects = List.from(result);
    }

    return result;
  }

  /// Check if we can use surgical cache (faster than full recalculation)
  bool _shouldUseSurgicalCache(Rect bounds) {
    return _lastQueryBounds != Rect.zero &&
        _cachedVisibleObjects.isNotEmpty &&
        (bounds.left - _lastQueryBounds.left).abs() < 50 &&
        (bounds.top - _lastQueryBounds.top).abs() < 50 &&
        (bounds.width - _lastQueryBounds.width).abs() < 100 &&
        (bounds.height - _lastQueryBounds.height).abs() < 100;
  }

  /// Apply surgical updates to cached results for ultra-fast performance
  List<T> _applySurgicalUpdates(Rect bounds) {
    final result = List<T>.from(_cachedVisibleObjects);
    final boundsDelta = bounds.center - _lastQueryBounds.center;
    final isMinorPan = boundsDelta.distance < 100;

    if (isMinorPan) {
      // For minor panning, just validate existing objects are still visible
      result.removeWhere((object) => !bounds.overlaps(object.getBounds()));

      // Quick check for newly visible objects only at the edges
      final expandedBounds = bounds.inflate(25);
      final cachedIds = result.map((obj) => obj.id).toSet();

      for (final object in _objects.values) {
        if (!cachedIds.contains(object.id) &&
            expandedBounds.overlaps(object.getBounds())) {
          result.add(object);
        }
      }
    } else {
      // For larger movements, do a more thorough update
      result.removeWhere((object) => !bounds.overlaps(object.getBounds()));

      final cachedIds = result.map((obj) => obj.id).toSet();
      for (final object in _objects.values) {
        if (!cachedIds.contains(object.id) &&
            bounds.overlaps(object.getBounds())) {
          result.add(object);
        }
      }
    }

    // Update cache
    _lastQueryBounds = bounds;
    _cachedVisibleObjects = result;

    return result;
  }

  /// Start drag optimization mode for specified objects.
  /// During drag, spatial index is not updated. Call [endDragging] to rebuild.
  void startDragging(List<String> objectIds) {
    if (!_isDragging && objectIds.isNotEmpty) {
      _isDragging = true;
      _draggingObjectIds = objectIds.toSet();
    }
  }

  /// End drag optimization mode and rebuild spatial index for dragged objects
  void endDragging() {
    if (_isDragging) {
      _isDragging = false;

      // Rebuild spatial index for objects that were being dragged
      _rebuildSpatialIndexForDraggedObjects();

      _draggingObjectIds.clear();

      // Force cache invalidation after drag ends
      _invalidateCache();
    }
  }

  /// Track dragging objects without updating spatial index during drag.
  /// Spatial index will be rebuilt when drag ends via [endDragging].
  void updateDraggingObjects(List<T> objects) {
    if (!_isDragging) return;

    // Just update the object references - spatial index rebuild happens at drag end
    for (final object in objects) {
      if (_draggingObjectIds.contains(object.id)) {
        _objects[object.id] = object;
      }
    }
  }

  /// Get total number of objects in the index
  int get objectCount => _objects.length;

  /// Get object by ID
  T? getObject(String objectId) => _objects[objectId];

  /// Get all objects (for type-based filtering)
  Iterable<T> get objects => _objects.values;

  /// Count objects matching a predicate
  int countWhere(bool Function(T object) test) =>
      _objects.values.where(test).length;

  /// Check if spatial grid is being used
  bool get isUsingSpatialGrid =>
      _objects.length > 50 && _spatialGrid.isNotEmpty;

  /// Get performance statistics
  SpatialIndexStats get stats => SpatialIndexStats(
    objectCount: _objects.length,
    gridCellCount: _spatialGrid.length,
    isDragging: _isDragging,
    draggingObjectCount: _draggingObjectIds.length,
    cacheSize: _cachedVisibleObjects.length,
  );

  /// Diagnostic: Check consistency between _objects and _spatialGrid.
  ///
  /// Returns a record with:
  /// - objectsCount: items in _objects
  /// - spatialGridItemCount: unique IDs across all cells in _spatialGrid
  /// - pendingCount: items waiting to be processed
  /// - missingFromGrid: IDs in _objects but NOT in any _spatialGrid cell
  ({
    int objectsCount,
    int spatialGridItemCount,
    int pendingCount,
    List<String> missingFromGrid,
  })
  diagnoseConsistency() {
    // Collect all IDs from spatial grid cells
    final idsInGrid = <String>{};
    for (final cellObjects in _spatialGrid.values) {
      idsInGrid.addAll(cellObjects);
    }

    // Find objects missing from grid
    final missingFromGrid = <String>[];
    for (final id in _objects.keys) {
      if (!idsInGrid.contains(id)) {
        missingFromGrid.add(id);
      }
    }

    return (
      objectsCount: _objects.length,
      spatialGridItemCount: idsInGrid.length,
      pendingCount: _pendingUpdates.length,
      missingFromGrid: missingFromGrid,
    );
  }

  /// Gets all active grid cell keys for debug visualization.
  ///
  /// Returns an iterable of cell keys in the format "${x}_${y}".
  /// Use [parseCellKey] to convert these to coordinates.
  Iterable<String> get activeCellKeys => _spatialGrid.keys;

  /// Parses a cell key into its (x, y) coordinates.
  ///
  /// Cell keys are formatted as "${x}_${y}" where x and y are integer
  /// grid coordinates (not pixel positions).
  static (int x, int y) parseCellKey(String cellKey) {
    final parts = cellKey.split('_');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Converts grid coordinates to world bounds.
  ///
  /// Given grid cell coordinates (x, y), returns the bounding rectangle
  /// in world/pixel coordinates.
  Rect cellBounds(int cellX, int cellY) {
    return Rect.fromLTWH(
      cellX * gridSize,
      cellY * gridSize,
      gridSize,
      gridSize,
    );
  }

  /// Gets the object count for a specific cell.
  ///
  /// Returns 0 if the cell doesn't exist.
  int getObjectCountInCell(String cellKey) {
    return _spatialGrid[cellKey]?.length ?? 0;
  }

  /// Gets all cell bounds with their object counts for debug visualization.
  ///
  /// Returns a list of records containing the cell bounds and the number
  /// of objects in that cell, broken down by type.
  List<CellDebugInfo> getActiveCellsInfo() {
    return _spatialGrid.entries.map((entry) {
      final (cellX, cellY) = parseCellKey(entry.key);
      final objects = entry.value;

      // Count objects by type based on ID prefix
      int nodes = 0, ports = 0, connections = 0, annotations = 0;
      for (final id in objects) {
        if (id.startsWith('node_')) {
          nodes++;
        } else if (id.startsWith('port_')) {
          ports++;
        } else if (id.startsWith('conn_')) {
          connections++;
        } else if (id.startsWith('annot_')) {
          annotations++;
        }
      }

      return CellDebugInfo(
        bounds: cellBounds(cellX, cellY),
        cellX: cellX,
        cellY: cellY,
        nodeCount: nodes,
        portCount: ports,
        connectionCount: connections,
        annotationCount: annotations,
      );
    }).toList();
  }

  // Internal implementation methods

  void _updateSpatialIndexForObject(T object) {
    final bounds = object.getBounds();
    _spatialRects[object.id] = bounds;
    _updateSpatialGrid(object, bounds);
    // Always invalidate cache to ensure real-time updates
    _invalidateCache();
  }

  void _updateSpatialGrid(T object, Rect bounds) {
    // Remove from old grid cells
    _removeFromSpatialGrid(object);

    // Add to new grid cells
    _addToGridCells(object.id, bounds);
  }

  /// Add object to grid cells based on bounds
  void _addToGridCells(String objectId, Rect bounds) {
    final startX = (bounds.left / gridSize).floor();
    final endX = (bounds.right / gridSize).floor();
    final startY = (bounds.top / gridSize).floor();
    final endY = (bounds.bottom / gridSize).floor();

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final cellKey = '${x}_$y';
        _spatialGrid.putIfAbsent(cellKey, () => <String>{}).add(objectId);
      }
    }
  }

  void _removeFromSpatialGrid(T object) {
    _spatialGrid.removeWhere((key, objectSet) {
      objectSet.remove(object.id);
      return objectSet.isEmpty;
    });
  }

  void _queryWithSpatialGrid(Rect bounds, List<T> result) {
    final checkedObjects = <String>{};

    final startX = (bounds.left / gridSize).floor();
    final endX = (bounds.right / gridSize).floor();
    final startY = (bounds.top / gridSize).floor();
    final endY = (bounds.bottom / gridSize).floor();

    // Optimize for small query areas
    final cellCount = (endX - startX + 1) * (endY - startY + 1);
    if (cellCount <= 4) {
      // For small areas, use simpler iteration
      for (int x = startX; x <= endX; x++) {
        for (int y = startY; y <= endY; y++) {
          final cellKey = '${x}_$y';
          final objectIds = _spatialGrid[cellKey];

          if (objectIds != null) {
            for (final objectId in objectIds) {
              if (checkedObjects.add(objectId)) {
                final object = _objects[objectId];
                if (object != null && bounds.overlaps(object.getBounds())) {
                  result.add(object);
                }
              }
            }
          }
        }
      }
    } else {
      // For larger areas, collect all candidate objects first
      final candidates = <String>{};
      for (int x = startX; x <= endX; x++) {
        for (int y = startY; y <= endY; y++) {
          final cellKey = '${x}_$y';
          final objectIds = _spatialGrid[cellKey];
          if (objectIds != null) {
            candidates.addAll(objectIds);
          }
        }
      }

      // Then check bounds for all candidates
      for (final objectId in candidates) {
        final object = _objects[objectId];
        if (object != null && bounds.overlaps(object.getBounds())) {
          result.add(object);
        }
      }
    }
  }

  void _queryWithSpatialRects(Rect bounds, List<T> result) {
    for (final entry in _spatialRects.entries) {
      if (bounds.overlaps(entry.value)) {
        final object = _objects[entry.key];
        if (object != null) {
          result.add(object);
        }
      }
    }
  }

  void _queryDirectIteration(Rect bounds, List<T> result) {
    for (final object in _objects.values) {
      if (bounds.overlaps(object.getBounds())) {
        result.add(object);
      }
    }
  }

  bool _shouldUseCache(Rect bounds) {
    if (!enableCaching || _lastQueryBounds == Rect.zero) return false;

    // During dragging, use cache only for very similar bounds
    if (_isDragging) {
      return (bounds.left - _lastQueryBounds.left).abs() < 10 &&
          (bounds.top - _lastQueryBounds.top).abs() < 10 &&
          (bounds.width - _lastQueryBounds.width).abs() < 10 &&
          (bounds.height - _lastQueryBounds.height).abs() < 10;
    }

    return (bounds.left - _lastQueryBounds.left).abs() < 50 &&
        (bounds.top - _lastQueryBounds.top).abs() < 50 &&
        (bounds.width - _lastQueryBounds.width).abs() < 50 &&
        (bounds.height - _lastQueryBounds.height).abs() < 50;
  }

  void _rebuildSpatialIndexForDraggedObjects() {
    for (final objectId in _draggingObjectIds) {
      final object = _objects[objectId];
      if (object != null) {
        _updateSpatialIndexForObject(object);
      }
    }
  }

  void _invalidateCache() {
    if (enableCaching) {
      _cachedVisibleObjects.clear();
      _lastQueryBounds = Rect.zero;
    }
  }

  /// Process pending updates in batches for better performance
  void _processPendingUpdatesIfNeeded() {
    if (_pendingUpdates.isEmpty) return;

    final now = DateTime.now();
    final timeSinceLastBatch = now.difference(_lastBatchUpdate).inMilliseconds;

    // Process batch if enough time has passed or we have many pending updates
    if (timeSinceLastBatch >= _batchDelayMs || _pendingUpdates.length >= 10) {
      _processPendingUpdates();
    }
  }

  /// Process all pending spatial index updates as a batch.
  /// Cache is invalidated only once at the end, not per-item.
  void _processPendingUpdates() {
    if (_pendingUpdates.isEmpty) return;

    // Process all updates without invalidating cache per-item
    for (final objectId in _pendingUpdates) {
      final object = _objects[objectId];
      if (object != null) {
        _updateSpatialIndexForObjectWithoutCacheInvalidation(object);
      }
    }

    _pendingUpdates.clear();
    _lastBatchUpdate = DateTime.now();

    // Invalidate cache once at the end of batch
    _invalidateCache();
  }

  /// Updates spatial index for an object without invalidating cache.
  /// Used during batch processing to avoid redundant cache invalidations.
  void _updateSpatialIndexForObjectWithoutCacheInvalidation(T object) {
    final bounds = object.getBounds();
    _spatialRects[object.id] = bounds;
    _updateSpatialGrid(object, bounds);
  }

  /// Force process any pending updates immediately
  void flushPendingUpdates() {
    _processPendingUpdates();
  }
}

/// Performance statistics for the spatial index
class SpatialIndexStats {
  const SpatialIndexStats({
    required this.objectCount,
    required this.gridCellCount,
    required this.isDragging,
    required this.draggingObjectCount,
    required this.cacheSize,
  });

  final int objectCount;
  final int gridCellCount;
  final bool isDragging;
  final int draggingObjectCount;
  final int cacheSize;

  @override
  String toString() {
    return 'SpatialIndexStats('
        'objects: $objectCount, '
        'gridCells: $gridCellCount, '
        'dragging: $isDragging, '
        'draggingObjects: $draggingObjectCount, '
        'cacheSize: $cacheSize)';
  }
}

/// Debug information for a spatial grid cell.
///
/// Contains the cell coordinates, bounds, and a breakdown of object counts
/// by type (nodes, ports, connections, annotations).
class CellDebugInfo {
  const CellDebugInfo({
    required this.bounds,
    required this.cellX,
    required this.cellY,
    required this.nodeCount,
    required this.portCount,
    required this.connectionCount,
    required this.annotationCount,
  });

  final Rect bounds;
  final int cellX;
  final int cellY;
  final int nodeCount;
  final int portCount;
  final int connectionCount;
  final int annotationCount;

  int get totalCount =>
      nodeCount + portCount + connectionCount + annotationCount;

  bool get isEmpty => totalCount == 0;

  /// Returns a compact string like "n:2 p:4 c:1" showing only non-zero counts.
  String get typeBreakdown {
    final parts = <String>[];
    if (nodeCount > 0) parts.add('n:$nodeCount');
    if (portCount > 0) parts.add('p:$portCount');
    if (connectionCount > 0) parts.add('c:$connectionCount');
    if (annotationCount > 0) parts.add('a:$annotationCount');
    return parts.join(' ');
  }
}
