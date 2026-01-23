import 'dart:ui';

import '../../connections/connection.dart';
import '../../graph/viewport.dart';
import '../../nodes/node.dart';
import '../lod/detail_visibility.dart';

// Part files for event categories
part 'batch_events.dart';
part 'connection_events.dart';
part 'drag_events.dart';
part 'hover_events.dart';
part 'lifecycle_events.dart';
part 'lod_events.dart';
part 'node_events.dart';
part 'selection_events.dart';
part 'viewport_events.dart';

/// Base class for all graph events emitted by [NodeFlowController].
///
/// Using a sealed class hierarchy enables exhaustive pattern matching:
/// ```dart
/// void onEvent(GraphEvent event) {
///   switch (event) {
///     case NodeAdded(:final node):
///       print('Node added: ${node.id}');
///     case NodeRemoved(:final node):
///       print('Node removed: ${node.id}');
///     // ... handle all cases
///   }
/// }
/// ```
sealed class GraphEvent {
  const GraphEvent();
}
