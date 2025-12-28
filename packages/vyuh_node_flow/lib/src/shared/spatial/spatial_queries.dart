import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../connections/connection.dart';
import '../../editor/hit_test_result.dart';
import '../../nodes/node.dart';

export '../../editor/hit_test_result.dart';

/// Public interface for spatial index queries.
///
/// This interface exposes only read-only query methods for hit testing
/// and spatial lookups. Mutation methods (update, remove, rebuild) are
/// internal to the framework and not exposed through this interface.
///
/// ## Usage
///
/// Access via the controller:
/// ```dart
/// final result = controller.spatialIndex.hitTest(point);
/// final nodes = controller.spatialIndex.nodesAt(point);
/// ```
///
/// ## Reactivity
///
/// Use the [version] observable to react to spatial index changes:
/// ```dart
/// Observer(
///   builder: (_) {
///     controller.spatialIndex.version.value;
///     return MyWidget();
///   },
/// )
/// ```
abstract interface class SpatialQueries<T> {
  /// Performs hit testing at the given point in graph coordinates.
  ///
  /// Returns the topmost hit element (node, port, or connection) at the point,
  /// respecting the render order (z-order) of elements.
  HitTestResult hitTest(Offset point);

  /// Hit tests specifically for ports at the given point.
  ///
  /// Uses the port snap distance for expanded hit detection. Returns null
  /// if no port is within snap distance of the point.
  HitTestResult? hitTestPort(Offset point);

  /// Returns all nodes that contain or are near the given point.
  ///
  /// The optional [radius] expands the hit area for imprecise selection.
  List<Node<T>> nodesAt(Offset point, {double radius = 0});

  /// Returns all nodes that intersect with the given bounds.
  ///
  /// Useful for box selection and viewport culling.
  List<Node<T>> nodesIn(Rect bounds);

  /// Returns all connections that pass through or near the given point.
  ///
  /// The optional [radius] expands the hit area for easier connection selection.
  List<Connection> connectionsAt(Offset point, {double radius = 0});

  /// Retrieves a node by its ID.
  ///
  /// Returns null if no node with the given ID exists in the index.
  Node<T>? getNode(String id);

  /// Retrieves a connection by its ID.
  ///
  /// Returns null if no connection with the given ID exists in the index.
  Connection? getConnection(String id);

  /// The number of nodes currently indexed.
  int get nodeCount;

  /// The number of connections currently indexed.
  int get connectionCount;

  /// The number of ports currently indexed.
  int get portCount;

  /// Observable version counter for reactivity.
  ///
  /// This value increments on every spatial index change. Use it with
  /// MobX Observer widgets to trigger rebuilds when the index changes.
  /// The value itself is meaningless - only changes trigger reactivity.
  Observable<int> get version;
}
