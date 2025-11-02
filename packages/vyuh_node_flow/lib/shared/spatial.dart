/// Ultra-fast spatial indexing system for 2D objects
///
/// This module provides generic spatial indexing capabilities optimized for
/// large numbers of objects with frequent position updates, such as nodes
/// in a graph editor.
///
/// Key features:
/// - Grid-based spatial hashing for O(visible) performance
/// - Smart caching with automatic invalidation
/// - Drag optimization mode for ultra-fast updates
/// - Multi-tier performance strategy based on object count
/// - Generic interface that can be adapted for any 2D objects

export 'node_spatial_adapter.dart';
export 'spatial_index.dart';
