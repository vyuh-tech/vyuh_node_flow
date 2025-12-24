/// Utility functions and extensions for testing vyuh_node_flow.
///
/// These utilities provide common testing operations, assertions,
/// and helpers for working with MobX observables in tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

// =============================================================================
// Node Assertions
// =============================================================================

/// Verifies that a node is at the expected position.
void expectNodePosition(Node node, Offset expected, {double tolerance = 0.01}) {
  expect(
    node.position.value.dx,
    closeTo(expected.dx, tolerance),
    reason: 'Node ${node.id} x position',
  );
  expect(
    node.position.value.dy,
    closeTo(expected.dy, tolerance),
    reason: 'Node ${node.id} y position',
  );
}

/// Verifies that a node has the expected size.
void expectNodeSize(Node node, Size expected, {double tolerance = 0.01}) {
  expect(
    node.size.value.width,
    closeTo(expected.width, tolerance),
    reason: 'Node ${node.id} width',
  );
  expect(
    node.size.value.height,
    closeTo(expected.height, tolerance),
    reason: 'Node ${node.id} height',
  );
}

/// Verifies that a node has the expected selection state.
void expectNodeSelected(Node node, bool expected) {
  expect(node.isSelected, expected, reason: 'Node ${node.id} selection state');
}

/// Verifies that a node has the expected visibility state.
void expectNodeVisible(Node node, bool expected) {
  expect(node.isVisible, expected, reason: 'Node ${node.id} visibility state');
}

/// Verifies that a node has the expected dragging state.
void expectNodeDragging(Node node, bool expected) {
  expect(node.isDragging, expected, reason: 'Node ${node.id} dragging state');
}

// =============================================================================
// Connection Assertions
// =============================================================================

/// Verifies that a connection exists between two nodes.
void expectConnectionExists(
  NodeFlowController controller,
  String sourceNodeId,
  String targetNodeId,
) {
  final connection = controller.connections.firstWhere(
    (c) => c.sourceNodeId == sourceNodeId && c.targetNodeId == targetNodeId,
    orElse: () => throw TestFailure(
      'No connection found from $sourceNodeId to $targetNodeId',
    ),
  );
  expect(connection, isNotNull);
}

/// Verifies that no connection exists between two nodes.
void expectNoConnectionBetween(
  NodeFlowController controller,
  String sourceNodeId,
  String targetNodeId,
) {
  final hasConnection = controller.connections.any(
    (c) => c.sourceNodeId == sourceNodeId && c.targetNodeId == targetNodeId,
  );
  expect(
    hasConnection,
    isFalse,
    reason: 'Expected no connection from $sourceNodeId to $targetNodeId',
  );
}

/// Verifies that a connection has the expected selection state.
void expectConnectionSelected(Connection connection, bool expected) {
  expect(
    connection.selected,
    expected,
    reason: 'Connection ${connection.id} selection state',
  );
}

/// Verifies that a connection has the expected animated state.
void expectConnectionAnimated(Connection connection, bool expected) {
  expect(
    connection.animated,
    expected,
    reason: 'Connection ${connection.id} animated state',
  );
}

// =============================================================================
// Viewport Assertions
// =============================================================================

/// Verifies that a viewport has the expected pan values.
void expectViewportPan(
  GraphViewport viewport,
  double expectedX,
  double expectedY, {
  double tolerance = 0.01,
}) {
  expect(viewport.x, closeTo(expectedX, tolerance), reason: 'Viewport x pan');
  expect(viewport.y, closeTo(expectedY, tolerance), reason: 'Viewport y pan');
}

/// Verifies that a viewport has the expected zoom level.
void expectViewportZoom(
  GraphViewport viewport,
  double expected, {
  double tolerance = 0.01,
}) {
  expect(viewport.zoom, closeTo(expected, tolerance), reason: 'Viewport zoom');
}

// =============================================================================
// MobX Test Helpers
// =============================================================================

/// Tracks observable changes and returns the recorded values.
///
/// Example:
/// ```dart
/// final tracker = ObservableTracker<Offset>();
/// tracker.track(node.position);
/// node.position.value = Offset(100, 100);
/// expect(tracker.values, contains(Offset(100, 100)));
/// tracker.dispose();
/// ```
class ObservableTracker<T> {
  final List<T> values = [];
  ReactionDisposer? _disposer;

  /// Starts tracking an observable.
  void track(Observable<T> observable) {
    _disposer = reaction(
      (_) => observable.value,
      (value) => values.add(value),
      fireImmediately: true,
    );
  }

  /// Stops tracking and cleans up.
  void dispose() {
    _disposer?.call();
  }

  /// Clears recorded values.
  void clear() {
    values.clear();
  }
}

/// Waits for an observable to reach a specific value.
///
/// Useful for testing asynchronous state changes.
Future<void> waitForObservable<T>(
  Observable<T> observable,
  T expected, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final stopwatch = Stopwatch()..start();
  while (observable.value != expected && stopwatch.elapsed < timeout) {
    await Future.delayed(const Duration(milliseconds: 10));
  }
  expect(observable.value, expected);
}

// =============================================================================
// Simulation Helpers
// =============================================================================

/// Simulates a node drag operation.
///
/// This updates the node position by the given delta,
/// simulating what happens during a drag gesture.
void simulateNodeDrag(Node node, Offset delta) {
  runInAction(() {
    node.position.value += delta;
    node.visualPosition.value += delta;
  });
}

/// Simulates a complete drag sequence (start -> move -> end).
void simulateDragSequence(
  NodeFlowController controller,
  String nodeId,
  List<Offset> deltas,
) {
  controller.startNodeDrag(nodeId);
  for (final delta in deltas) {
    controller.moveNodeDrag(delta);
  }
  controller.endNodeDrag();
}

/// Simulates a viewport pan operation.
void simulateViewportPan(NodeFlowController controller, ScreenOffset delta) {
  controller.panBy(delta);
}

/// Simulates a viewport zoom operation.
void simulateViewportZoom(NodeFlowController controller, double zoomDelta) {
  controller.zoomBy(zoomDelta);
}

// =============================================================================
// Event Tracking
// =============================================================================

/// Tracks callback invocations for testing.
class CallbackTracker<T> {
  final List<T> invocations = [];

  void call(T value) {
    invocations.add(value);
  }

  bool get wasCalled => invocations.isNotEmpty;
  int get callCount => invocations.length;
  T? get lastCall => invocations.isEmpty ? null : invocations.last;

  void clear() {
    invocations.clear();
  }
}

// =============================================================================
// Coordinate Helpers
// =============================================================================

/// Creates a screen position for testing.
ScreenPosition screenPos(double x, double y) => ScreenPosition.fromXY(x, y);

/// Creates a graph position for testing.
GraphPosition graphPos(double x, double y) => GraphPosition.fromXY(x, y);

/// Creates a screen offset for testing.
ScreenOffset screenOffset(double dx, double dy) => ScreenOffset.fromXY(dx, dy);

/// Creates a graph offset for testing.
GraphOffset graphOffset(double dx, double dy) => GraphOffset.fromXY(dx, dy);

// =============================================================================
// JSON Helpers
// =============================================================================

/// Round-trip a node through JSON serialization.
Node<String> roundTripNodeJson(Node<String> node) {
  final json = node.toJson((data) => data);
  return Node.fromJson(json, (json) => json as String);
}

/// Round-trip a connection through JSON serialization.
Connection roundTripConnectionJson(Connection connection) {
  final json = connection.toJson();
  return Connection.fromJson(json);
}

/// Round-trip a viewport through JSON serialization.
GraphViewport roundTripViewportJson(GraphViewport viewport) {
  final json = viewport.toJson();
  return GraphViewport.fromJson(json);
}

// =============================================================================
// Performance Helpers
// =============================================================================

/// Measures the execution time of an operation.
Duration measureOperation(void Function() operation) {
  final stopwatch = Stopwatch()..start();
  operation();
  stopwatch.stop();
  return stopwatch.elapsed;
}

/// Asserts that an operation completes within the specified duration.
void expectFastOperation(
  void Function() operation,
  Duration maxDuration, {
  String? reason,
}) {
  final duration = measureOperation(operation);
  expect(
    duration,
    lessThan(maxDuration),
    reason: reason ?? 'Operation took $duration, expected < $maxDuration',
  );
}

/// Runs an operation multiple times and returns statistics.
({Duration min, Duration max, Duration average}) benchmarkOperation(
  void Function() operation, {
  int iterations = 100,
}) {
  final durations = <Duration>[];

  for (var i = 0; i < iterations; i++) {
    durations.add(measureOperation(operation));
  }

  durations.sort();

  final totalMicroseconds = durations.fold<int>(
    0,
    (sum, d) => sum + d.inMicroseconds,
  );

  return (
    min: durations.first,
    max: durations.last,
    average: Duration(microseconds: totalMicroseconds ~/ iterations),
  );
}

// =============================================================================
// Test Tags
// =============================================================================

/// Tag for unit tests - fast, isolated tests of individual components.
const unitTag = 'unit';

/// Tag for behavior tests - tests of interactive behavior.
const behaviorTag = 'behavior';

/// Tag for integration tests - tests of multiple components working together.
const integrationTag = 'integration';

/// Tag for performance tests - tests measuring speed and efficiency.
const performanceTag = 'performance';

/// Tag for widget tests - tests of Flutter widgets.
const widgetTag = 'widget';

/// Tag for edge case tests - tests of boundary conditions and error handling.
const edgeCaseTag = 'edge_case';
