/// Ultra-fast spatial indexing system for 2D objects
///
/// This module provides unified spatial indexing for all graph elements:
/// nodes, ports, and connection segments.
///
/// Key features:
/// - Single unified index for all element types
/// - Type-based filtering for targeted queries
/// - Grid-based spatial hashing for O(1) performance
/// - Smart caching with automatic invalidation
library;

export 'graph_spatial_index.dart';
export 'spatial_grid.dart'
    show SpatialGrid, SpatialIndexable, SpatialIndexStats;
export 'spatial_item.dart';
