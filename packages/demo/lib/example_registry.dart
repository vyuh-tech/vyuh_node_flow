import 'package:flutter/material.dart';

import 'example_model.dart';
// Layout examples
import 'examples/advanced/alignment.dart';
// Animated connections examples
import 'examples/advanced/animated_connections.dart';
// Annotations examples
import 'examples/advanced/annotations.dart';
// AutoPan example
import 'examples/advanced/autopan.dart';
// Connection labels examples
import 'examples/advanced/connection_labels.dart';
// // Editable connections examples
// import 'examples/advanced/editable_connections.dart';
// Advanced examples
import 'examples/advanced/serialization.dart';
import 'examples/advanced/shortcuts.dart';
import 'examples/advanced/theming.dart';
import 'examples/advanced/validation.dart';
import 'examples/advanced/viewer.dart';
import 'examples/advanced/viewport_animations.dart';
import 'examples/advanced/visibility.dart';
import 'examples/advanced/workbench.dart';
// Basics examples
import 'examples/basics/callbacks.dart';
import 'examples/basics/controlling_nodes.dart';
import 'examples/basics/dynamic_ports.dart';
// Connections examples
import 'examples/basics/interactive_widgets.dart';
import 'examples/basics/minimap.dart';
import 'examples/basics/node_shapes.dart';
import 'examples/basics/port_labels.dart';
import 'examples/basics/ports.dart';
import 'examples/basics/simple.dart';

class ExampleRegistry {
  static List<ExampleCategory> get all => [
    // 1. Getting Started - Nodes, Ports, and Connections
    ExampleCategory(
      id: 'basics',
      title: 'Basics',
      description: 'Learn the fundamentals of nodes, ports, and connections',
      icon: Icons.play_circle_outline,
      examples: [
        Example(
          id: 'simple',
          title: 'Simple Node Addition',
          description: 'Add basic nodes to the canvas with a click',
          icon: Icons.add_circle_outline,
          builder: (_) => const SimpleNodeAdditionExample(),
        ),
        Example(
          id: 'controlling-nodes',
          title: 'Controlling Nodes',
          description:
              'Add different node types, select, move, and delete nodes',
          icon: Icons.control_camera,
          builder: (_) => const ControllingNodesExample(),
        ),
        Example(
          id: 'node-shapes',
          title: 'Node Shapes',
          description:
              'Explore different node shapes: Circle, Diamond, Hexagon, and Rectangle',
          icon: Icons.category,
          builder: (_) => const NodeShapesExample(),
        ),
        Example(
          id: 'dynamic-ports',
          title: 'Dynamic Ports',
          description:
              'Add ports dynamically to nodes - nodes resize automatically',
          icon: Icons.settings_input_component,
          builder: (_) => const DynamicPortsExample(),
        ),
        Example(
          id: 'port-styles',
          title: 'Port Positions & Styles',
          description:
              'Explore all port positions and connection styles with live preview',
          icon: Icons.settings_ethernet,
          builder: (_) => const PortCombinationsDemo(),
        ),
        Example(
          id: 'port-labels',
          title: 'Port Labels',
          description:
              'Display and customize port names with intelligent positioning and zoom-based visibility',
          icon: Icons.label_outline,
          builder: (_) => const PortLabelsExample(),
        ),
        Example(
          id: 'minimap',
          title: 'Minimap Navigation',
          description:
              'Interactive minimap for navigating large graphs with customizable position, size, and interactivity',
          icon: Icons.map,
          builder: (_) => const MinimapExample(),
        ),
        Example(
          id: 'callbacks',
          title: 'Event Callbacks',
          description:
              'Real-time event logging for all node, connection, and viewport lifecycle events',
          icon: Icons.monitor_heart,
          builder: (_) => const CallbacksExample(),
        ),
        Example(
          id: 'interactive-widgets',
          title: 'Interactive Node Widgets',
          description:
              'Test buttons, text fields, and sliders inside nodes - drag nodes outside bounds to verify gestures work',
          icon: Icons.touch_app,
          builder: (_) => const InteractiveWidgetsExample(),
        ),
      ],
    ),

    // 2. Advanced Features
    ExampleCategory(
      id: 'advanced',
      title: 'Advanced Features',
      description:
          'Advanced capabilities including layouts, annotations, themes, and more',
      icon: Icons.science,
      examples: [
        Example(
          id: 'shortcuts',
          title: 'Keyboard Shortcuts',
          description:
              'Comprehensive showcase of all keyboard shortcuts, custom actions, and the shortcuts viewer',
          icon: Icons.keyboard,
          builder: (_) => const ShortcutsExample(),
        ),
        Example(
          id: 'serialization',
          title: 'Save & Load (JSON)',
          description:
              'Export graphs to JSON, save workflows, and restore them with full state preservation',
          icon: Icons.save,
          builder: (_) => const SerializationExample(),
        ),
        Example(
          id: 'alignment',
          title: 'Alignment & Distribution',
          description:
              'Align, distribute, and arrange nodes of varying sizes. Use Shift-Drag to select multiple nodes',
          icon: Icons.align_horizontal_center,
          builder: (_) => const AlignmentExample(),
        ),
        Example(
          id: 'annotations',
          title: 'Comment & Group Nodes',
          description:
              'Comment nodes (formerly sticky notes) and group nodes for organizing your graph',
          icon: Icons.sticky_note_2,
          builder: (_) => const AnnotationExample(),
        ),
        Example(
          id: 'animated-connections',
          title: 'Animated Connections',
          description:
              'Interactive demo of all animation effects: flowing dashes, particles, gradients, and pulse',
          icon: Icons.animation,
          builder: (_) => const AnimatedConnectionsExample(),
        ),
        Example(
          id: 'connection-labels',
          title: 'Connection Labels',
          description:
              'Add, edit, and position labels dynamically on connections with anchor points and offsets',
          icon: Icons.label,
          builder: (_) => const ConnectionLabelsExample(),
        ),
        // Example(
        //   id: 'editable-connections',
        //   title: 'Editable Connections',
        //   description:
        //       'Interactive control points for customizing connection paths with drag-and-drop waypoint editing',
        //   icon: Icons.edit_road,
        //   builder: (_) => const EditableConnectionsExample(),
        // ),
        Example(
          id: 'theming',
          title: 'Theme Customization',
          description:
              'Customize colors, styles, and appearance of the node flow editor',
          icon: Icons.palette,
          builder: (_) => const ThemingExample(),
        ),
        Example(
          id: 'viewer',
          title: 'Read-only Viewer',
          description: 'Display graphs in read-only mode without editing',
          icon: Icons.visibility,
          builder: (_) => const ViewerExample(),
        ),
        Example(
          id: 'visibility',
          title: 'Visibility Toggling',
          description:
              'Show/hide nodes and annotations with eye icon controls in a side panel',
          icon: Icons.visibility_off,
          builder: (_) => const VisibilityExample(),
        ),
        Example(
          id: 'validation',
          title: 'Connection Validation',
          description:
              'Custom validation rules, type checking, and connection limits',
          icon: Icons.verified_user,
          builder: (_) => const ConnectionValidationExample(),
        ),
        Example(
          id: 'autopan',
          title: 'AutoPan',
          description:
              'Automatic viewport panning when dragging near edges with switchable presets',
          icon: Icons.pan_tool_alt,
          builder: (_) => const AutoPanExample(),
        ),
        Example(
          id: 'viewport-animations',
          title: 'Viewport Animations',
          description:
              'Animated navigation to nodes, positions, bounds, and zoom levels',
          icon: Icons.animation,
          builder: (_) => const ViewportAnimationsExample(),
        ),
        Example(
          id: 'workbench',
          title: 'Full Workbench',
          description:
              'Comprehensive demo with workflows, layouts, and interactive tools',
          icon: Icons.construction,
          builder: (_) => const WorkbenchExample(),
        ),
      ],
    ),
  ];

  // Helper methods to find examples
  static ExampleCategory? findCategory(String categoryId) {
    try {
      return all.firstWhere((cat) => cat.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  static Example? findExample(String categoryId, String exampleId) {
    final category = findCategory(categoryId);
    if (category == null) return null;

    try {
      return category.examples.firstWhere((ex) => ex.id == exampleId);
    } catch (_) {
      return null;
    }
  }

  static (String?, String?) get firstExample {
    if (all.isEmpty) return (null, null);
    final firstCat = all.first;
    if (firstCat.examples.isEmpty) return (null, null);
    return (firstCat.id, firstCat.examples.first.id);
  }
}
