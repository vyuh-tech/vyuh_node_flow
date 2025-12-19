/// A flexible, high-performance node-based flow editor for Flutter.
///
/// `vyuh_node_flow` is a comprehensive Flutter package for building interactive
/// node-based editors, visual programming interfaces, workflow editors, diagrams,
/// and data processing pipelines. Inspired by React Flow, it provides a rich set
/// of features for creating sophisticated visual programming experiences.
///
/// ## Features
///
/// - **Interactive Node Editor**: Drag, resize, and connect nodes with an intuitive
///   interface
/// - **Flexible Connections**: Support for multiple connection styles (bezier,
///   straight, step) with customizable endpoints and labels
/// - **Rich Theming**: Comprehensive theming system for nodes, ports, connections,
///   and annotations
/// - **Viewport Controls**: Pan, zoom, and minimap support for navigating large graphs
/// - **State Management**: Built on MobX for reactive, observable state management
/// - **Annotations Layer**: Add custom annotations and overlays to your flow diagrams
/// - **Validation**: Built-in connection validation and custom validation support
/// - **Keyboard Shortcuts**: Extensive keyboard shortcuts for productivity
/// - **Serialization**: JSON serialization support for saving and loading graphs
///
/// ## Core Components
///
/// ### Graph Components
/// - [NodeFlowEditor]: The main interactive editor widget
/// - [NodeFlowViewer]: A read-only viewer for displaying node graphs
/// - [NodeFlowController]: Controller for managing graph state and operations
/// - [NodeFlowConfig]: Configuration for editor behavior and appearance
/// - [Viewport]: Manages pan, zoom, and transformation of the canvas
/// - [NodeFlowMinimap]: Minimap widget for navigation
///
/// ### Nodes
/// - [Node]: The core node model representing graph nodes
/// - [NodeWidget]: Base widget for rendering nodes
/// - [NodeData]: Custom data interface for node content
/// - [InteractionState]: Tracks node interaction states (hover, selected, etc.)
///
/// ### Connections
/// - [Connection]: Model representing edges between nodes
/// - [ConnectionEndpoint]: Defines connection start and end points
/// - [ConnectionStyleBase]: Base class for connection rendering styles
/// - [ConnectionTheme]: Theming for connection appearance
/// - [ConnectionValidation]: Interface for validating connections
///
/// ### Ports
/// - [Port]: Model for node input/output ports
/// - [PortTheme]: Theming for port appearance
///
/// ### Annotations
/// - [Annotation]: Model for canvas annotations and overlays
/// - [AnnotationWidget]: Base widget for rendering annotations
/// - [AnnotationLayer]: Layer for managing and rendering annotations
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:vyuh_node_flow/vyuh_node_flow.dart';
/// import 'package:flutter/material.dart';
///
/// class MyNodeEditor extends StatefulWidget {
///   @override
///   State<MyNodeEditor> createState() => _MyNodeEditorState();
/// }
///
/// class _MyNodeEditorState extends State<MyNodeEditor> {
///   late NodeFlowController controller;
///
///   @override
///   void initState() {
///     super.initState();
///     controller = NodeFlowController(
///       graph: Graph(
///         nodes: [
///           Node(id: 'node-1', position: Offset(100, 100)),
///           Node(id: 'node-2', position: Offset(300, 100)),
///         ],
///         connections: [
///           Connection(
///             id: 'conn-1',
///             source: ConnectionEndpoint(nodeId: 'node-1'),
///             target: ConnectionEndpoint(nodeId: 'node-2'),
///           ),
///         ],
///       ),
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: NodeFlowEditor(
///         controller: controller,
///         config: NodeFlowConfig(),
///       ),
///     );
///   }
///
///   @override
///   void dispose() {
///     controller.dispose();
///     super.dispose();
///   }
/// }
/// ```
///
/// ## State Management
///
/// This library uses [MobX](https://pub.dev/packages/mobx) for reactive state
/// management. All core models are observable, enabling automatic UI updates
/// when the graph state changes.
///
library;

// Graph (Core editor, controller, config, viewport)
// Annotations
export 'annotations/annotation.dart';
export 'annotations/annotation_layer.dart';
export 'annotations/annotation_theme.dart';
export 'annotations/annotation_widget.dart';
export 'annotations/group_annotation.dart';
export 'annotations/group_annotation_widget.dart';
// Connections
export 'connections/connection.dart';
export 'connections/connection_anchor.dart';
export 'connections/connection_endpoint.dart';
export 'connections/connection_label.dart';
export 'connections/connection_painter.dart' show ConnectionPainter;
export 'connections/connection_style_overrides.dart';
export 'connections/connection_theme.dart';
export 'connections/connection_validation.dart';
export 'connections/connections_canvas.dart';
export 'connections/effects/effects.dart';
export 'connections/label_theme.dart';
export 'connections/styles/connection_style_base.dart';
export 'connections/styles/connection_styles.dart';
export 'connections/styles/editable_path_connection_style.dart';
export 'connections/styles/editable_smooth_step_connection_style.dart';
export 'connections/styles/endpoint_position_calculator.dart';
export 'connections/styles/label_calculator.dart';
export 'connections/styles/waypoint_builder.dart';
export 'connections/temporary_connection.dart';
export 'graph/coordinates.dart';
// Core
export 'graph/cursor_theme.dart';
export 'graph/graph.dart'; // Needed for examples and serialization
export 'graph/layers/connection_labels_layer.dart' show LabelBuilder;
export 'graph/layers/spatial_index_debug_layer.dart';
export 'graph/minimap_theme.dart';
export 'graph/node_flow_actions.dart';
export 'graph/node_flow_behavior.dart';
export 'graph/node_flow_config.dart';
export 'graph/node_flow_controller.dart';
export 'graph/node_flow_editor.dart';
export 'graph/node_flow_events.dart';
export 'graph/node_flow_minimap.dart';
export 'graph/node_flow_theme.dart';
export 'graph/node_flow_viewer.dart';
export 'graph/resizer_theme.dart';
export 'graph/selection_theme.dart';
export 'graph/viewport.dart';
export 'grid/grid_styles.dart';
export 'grid/grid_theme.dart';
export 'grid/spatial_index_debug_painter.dart';
export 'grid/styles/grid_style.dart';
// Nodes
export 'nodes/interaction_state.dart';
export 'nodes/node.dart'; // Needed for Node class in examples
// Models
export 'nodes/node_data.dart';
export 'nodes/node_shape.dart';
export 'nodes/node_shape_clipper.dart';
export 'nodes/node_shape_painter.dart';
export 'nodes/node_theme.dart';
export 'nodes/node_widget.dart';
// Node Shapes
export 'nodes/shapes/circle_shape.dart';
export 'nodes/shapes/diamond_shape.dart';
export 'nodes/shapes/hexagon_shape.dart';
// Ports
export 'ports/port.dart';
export 'ports/port_theme.dart';
export 'ports/port_widget.dart'; // Also exports PortBuilder typedef
// Shared Utilities
export 'shared/flutter_actions_integration.dart';
export 'shared/json_converters.dart';
export 'shared/resizer_widget.dart';
// Marker Shapes (for ports and connection endpoints)
export 'shared/shapes/marker_shape.dart';
export 'shared/shapes/marker_shapes.dart';
// Widgets
export 'shared/shortcuts_viewer_dialog.dart';
export 'shared/spatial/graph_spatial_index.dart'
    show GraphSpatialIndex, HitTestResult, HitTarget;
export 'shared/unbounded_widgets.dart';
