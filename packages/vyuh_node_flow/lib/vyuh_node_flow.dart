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
/// - **Rich Theming**: Comprehensive theming system for nodes, ports, and connections
/// - **Viewport Controls**: Pan, zoom, and minimap support for navigating large graphs
/// - **State Management**: Built on MobX for reactive, observable state management
/// - **Grouping & Comments**: GroupNode for visual grouping, CommentNode for floating text comments
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
/// - [GroupNode]: Special node for visually grouping other nodes
/// - [CommentNode]: Special node for floating text comments
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
/// ### Spatial Index
/// - [SpatialQueries]: Read-only interface for spatial queries and hit testing
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

// Public API organized by domain
export 'connections.dart';
export 'controller.dart';
export 'debug.dart';
export 'editor.dart';
export 'nodes.dart';
export 'plugins.dart';
export 'ports.dart';
export 'spatial.dart';
// Additional exports that need specific show clauses
export 'src/editor/layers/connection_labels_layer.dart' show LabelBuilder;
export 'themes.dart';
export 'utilities.dart';
export 'viewport.dart';
