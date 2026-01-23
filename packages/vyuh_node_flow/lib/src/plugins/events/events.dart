/// Graph events organized by category.
///
/// Events are emitted by [NodeFlowController] and received by plugins
/// via [NodeFlowPlugin.onEvent].
///
/// ## Event Categories
///
/// - **Node Events**: [NodeAdded], [NodeRemoved], [NodeMoved], [NodeResized],
///   [NodeDataChanged], [NodeVisibilityChanged], [NodeZIndexChanged],
///   [NodeLockChanged], [NodeGroupChanged]
///
/// - **Connection Events**: [ConnectionAdded], [ConnectionRemoved]
///
/// - **Selection Events**: [SelectionChanged]
///
/// - **Viewport Events**: [ViewportChanged]
///
/// - **Drag Events**: [NodeDragStarted], [NodeDragEnded],
///   [ConnectionDragStarted], [ConnectionDragEnded],
///   [ResizeStarted], [ResizeEnded]
///
/// - **Hover Events**: [NodeHoverChanged], [ConnectionHoverChanged],
///   [PortHoverChanged]
///
/// - **Lifecycle Events**: [GraphCleared], [GraphLoaded]
///
/// - **Batch Events**: [BatchStarted], [BatchEnded]
///
/// - **LOD Events**: [LODLevelChanged]
library;

// All events are defined in graph_event.dart and its part files
export 'graph_event.dart';
