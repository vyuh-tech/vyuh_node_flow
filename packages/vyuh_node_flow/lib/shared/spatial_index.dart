import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Generic spatial indexing interface for 2D objects
abstract class SpatialIndexable {
  String get id;

  Rect getBounds();
}

/// Ultra-fast spatial indexing system using grid-based hashing
/// Optimized for large numbers of 2D objects with frequent position updates
class SpatialIndex<T extends SpatialIndexable> {
  SpatialIndex({this.gridSize = 500.0, this.enableCaching = true})
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

  // Surgical rendering state
  bool _isDragging = false;
  Set<String> _draggingObjectIds = <String>{};
  Rect _draggingBounds = Rect.zero;
  final Map<String, Rect> _draggingObjectBounds = <String, Rect>{};

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

  /// Start drag optimization mode for specified objects
  void startDragging(List<String> objectIds) {
    if (!_isDragging && objectIds.isNotEmpty) {
      _isDragging = true;
      _draggingObjectIds = objectIds.toSet();

      // Initialize dragging bounds tracking
      _draggingObjectBounds.clear();
      for (final objectId in objectIds) {
        final object = _objects[objectId];
        if (object != null) {
          _draggingObjectBounds[objectId] = object.getBounds();
        }
      }

      _computeDraggingBounds();
    }
  }

  /// End drag optimization mode and rebuild spatial index for dragged objects
  void endDragging() {
    if (_isDragging) {
      _isDragging = false;

      // Clean rebuild only for objects that actually moved
      _rebuildSpatialIndexForDraggedObjects();

      _draggingObjectIds.clear();
      _draggingObjectBounds.clear();
      _draggingBounds = Rect.zero;

      // Force cache invalidation after drag ends
      _invalidateCache();
    }
  }

  /// Ultra-fast surgical update only for dragging objects
  void updateDraggingObjects(List<T> objects) {
    if (!_isDragging) return;

    bool hasSignificantChange = false;

    // Track bounds changes for surgical updates
    for (final object in objects) {
      if (_draggingObjectIds.contains(object.id)) {
        final newBounds = object.getBounds();
        final oldBounds = _draggingObjectBounds[object.id];

        // Only update if bounds actually changed significantly
        if (oldBounds == null || !_boundsAreSimilar(oldBounds, newBounds)) {
          _spatialRects[object.id] = newBounds;
          _draggingObjectBounds[object.id] = newBounds;

          // Surgical grid update - only update this object's grid cells
          _updateSpatialGridSurgical(object, newBounds, oldBounds);
          hasSignificantChange = true;
        }
      }
    }

    // Only update derived data if there were significant changes
    if (hasSignificantChange) {
      _computeDraggingBounds();
      _invalidateCacheForDragging();
    }
  }

  /// Surgical spatial grid update for individual objects
  void _updateSpatialGridSurgical(T object, Rect newBounds, Rect? oldBounds) {
    // Remove from old grid cells if they exist
    if (oldBounds != null) {
      _removeFromGridCells(object.id, oldBounds);
    }

    // Add to new grid cells
    _addToGridCells(object.id, newBounds);
  }

  /// Check if bounds are similar enough to skip update
  bool _boundsAreSimilar(Rect a, Rect b) {
    return (a.left - b.left).abs() < 2 &&
        (a.top - b.top).abs() < 2 &&
        (a.width - b.width).abs() < 2 &&
        (a.height - b.height).abs() < 2;
  }

  /// Get total number of objects in the index
  int get objectCount => _objects.length;

  /// Get object by ID
  T? getObject(String objectId) => _objects[objectId];

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

  /// Remove object from grid cells based on bounds
  void _removeFromGridCells(String objectId, Rect bounds) {
    final startX = (bounds.left / gridSize).floor();
    final endX = (bounds.right / gridSize).floor();
    final startY = (bounds.top / gridSize).floor();
    final endY = (bounds.bottom / gridSize).floor();

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final cellKey = '${x}_$y';
        final cellSet = _spatialGrid[cellKey];
        if (cellSet != null) {
          cellSet.remove(objectId);
          if (cellSet.isEmpty) {
            _spatialGrid.remove(cellKey);
          }
        }
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

  void _computeDraggingBounds() {
    if (_draggingObjectIds.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final objectId in _draggingObjectIds) {
      final bounds = _spatialRects[objectId];
      if (bounds != null) {
        minX = math.min(minX, bounds.left);
        minY = math.min(minY, bounds.top);
        maxX = math.max(maxX, bounds.right);
        maxY = math.max(maxY, bounds.bottom);
      }
    }

    _draggingBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
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

  void _invalidateCacheForDragging() {
    if (enableCaching && _lastQueryBounds != Rect.zero) {
      // More conservative cache invalidation during dragging
      final expandedDraggingBounds = _draggingBounds.inflate(50);
      if (expandedDraggingBounds.overlaps(_lastQueryBounds)) {
        _cachedVisibleObjects.clear();
        _lastQueryBounds = Rect.zero;
      }
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

  /// Process all pending spatial index updates as a batch
  void _processPendingUpdates() {
    if (_pendingUpdates.isEmpty) return;

    for (final objectId in _pendingUpdates) {
      final object = _objects[objectId];
      if (object != null) {
        _updateSpatialIndexForObject(object);
      }
    }

    _pendingUpdates.clear();
    _lastBatchUpdate = DateTime.now();
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
