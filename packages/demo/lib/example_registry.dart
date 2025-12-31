import 'package:flutter/material.dart';

import 'example_model.dart';
// All examples - flat imports
import 'examples/alignment.dart';
import 'examples/animated_connections.dart';
import 'examples/annotations.dart';
import 'examples/autopan.dart';
import 'examples/callbacks.dart';
import 'examples/connection_labels.dart';
import 'examples/controlling_nodes.dart';
import 'examples/dynamic_ports.dart';
import 'examples/interactive_widgets.dart';
import 'examples/lod.dart';
import 'examples/minimap.dart';
import 'examples/node_shapes.dart';
import 'examples/port_labels.dart';
import 'examples/ports.dart';
import 'examples/serialization.dart';
import 'examples/shortcuts.dart';
import 'examples/simple.dart';
import 'examples/theming.dart';
import 'examples/validation.dart';
import 'examples/viewer.dart';
import 'examples/viewport_animations.dart';
import 'examples/visibility.dart';
import 'examples/workbench.dart';

class ExampleRegistry {
  static List<ExampleCategory> get all => [
    // 1. Getting Started
    ExampleCategory(
      id: 'getting-started',
      title: 'Getting Started',
      description: 'Learn the fundamentals with simple examples',
      icon: Icons.rocket_launch_outlined,
      examples: [
        Example(
          id: 'simple',
          title: 'Simple Graph',
          description: 'Add basic nodes to the canvas with a click',
          icon: Icons.add_circle_outline,
          builder: (_) => const SimpleNodeAdditionExample(),
        ),
        Example(
          id: 'callbacks',
          title: 'Event Callbacks',
          description:
              'Real-time event logging for all node, connection, and viewport lifecycle events',
          icon: Icons.monitor_heart_outlined,
          builder: (_) => const CallbacksExample(),
        ),
        Example(
          id: 'viewer',
          title: 'Read-only Viewer',
          description: 'Display graphs in read-only mode without editing',
          icon: Icons.visibility_outlined,
          builder: (_) => const ViewerExample(),
        ),
      ],
    ),

    // 2. Nodes
    ExampleCategory(
      id: 'nodes',
      title: 'Nodes',
      description: 'Node creation, shapes, and interactive content',
      icon: Icons.interests_outlined,
      examples: [
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
          icon: Icons.category_outlined,
          builder: (_) => const NodeShapesExample(),
        ),
        Example(
          id: 'interactive-widgets',
          title: 'Interactive Widgets',
          description:
              'Buttons, text fields, and sliders inside nodes - drag outside to verify gestures',
          icon: Icons.touch_app_outlined,
          builder: (_) => const InteractiveWidgetsExample(),
        ),
      ],
    ),

    // 3. Ports
    ExampleCategory(
      id: 'ports',
      title: 'Ports',
      description: 'Port positions, styles, labels, and dynamic creation',
      icon: Icons.electrical_services_outlined,
      examples: [
        Example(
          id: 'port-styles',
          title: 'Positions & Styles',
          description:
              'Explore all port positions and connection styles with live preview',
          icon: Icons.settings_ethernet,
          builder: (_) => const PortCombinationsDemo(),
        ),
        Example(
          id: 'port-labels',
          title: 'Port Labels',
          description:
              'Display and customize port names with intelligent positioning',
          icon: Icons.label_outline,
          builder: (_) => const PortLabelsExample(),
        ),
        Example(
          id: 'dynamic-ports',
          title: 'Dynamic Ports',
          description:
              'Add ports dynamically to nodes - nodes resize automatically',
          icon: Icons.add_link,
          builder: (_) => const DynamicPortsExample(),
        ),
      ],
    ),

    // 4. Connections
    ExampleCategory(
      id: 'connections',
      title: 'Connections',
      description: 'Connection styles, animations, labels, and validation',
      icon: Icons.timeline_outlined,
      examples: [
        Example(
          id: 'animated-connections',
          title: 'Animated Effects',
          description:
              'Interactive demo of all animation effects: flowing dashes, particles, gradients',
          icon: Icons.animation,
          builder: (_) => const AnimatedConnectionsExample(),
        ),
        Example(
          id: 'connection-labels',
          title: 'Connection Labels',
          description:
              'Add, edit, and position labels dynamically on connections',
          icon: Icons.label_important_outline,
          builder: (_) => const ConnectionLabelsExample(),
        ),
        Example(
          id: 'validation',
          title: 'Connection Validation',
          description:
              'Custom validation rules, type checking, and connection limits',
          icon: Icons.verified_user_outlined,
          builder: (_) => const ConnectionValidationExample(),
        ),
      ],
    ),

    // 5. Navigation
    ExampleCategory(
      id: 'navigation',
      title: 'Navigation',
      description: 'Viewport control, minimap, and navigation features',
      icon: Icons.explore_outlined,
      examples: [
        Example(
          id: 'minimap',
          title: 'Minimap',
          description:
              'Interactive minimap for navigating large graphs with customizable options',
          icon: Icons.map_outlined,
          builder: (_) => const MinimapExample(),
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
          id: 'autopan',
          title: 'AutoPan',
          description: 'Automatic viewport panning when dragging near edges',
          icon: Icons.pan_tool_alt_outlined,
          builder: (_) => const AutoPanExample(),
        ),
      ],
    ),

    // 6. Appearance
    ExampleCategory(
      id: 'appearance',
      title: 'Appearance',
      description: 'Theming, level of detail, and visibility controls',
      icon: Icons.palette_outlined,
      examples: [
        Example(
          id: 'theming',
          title: 'Theme Customization',
          description:
              'Customize colors, styles, and appearance of the node flow editor',
          icon: Icons.color_lens_outlined,
          builder: (_) => const ThemingExample(),
        ),
        Example(
          id: 'lod',
          title: 'Level of Detail',
          description:
              'Automatic visual simplification based on zoom level for performance',
          icon: Icons.layers_outlined,
          builder: (_) => const LODExample(),
        ),
        Example(
          id: 'visibility',
          title: 'Visibility Toggling',
          description: 'Show/hide nodes and annotations with eye icon controls',
          icon: Icons.visibility_off_outlined,
          builder: (_) => const VisibilityExample(),
        ),
      ],
    ),

    // 7. Data & Workflow
    ExampleCategory(
      id: 'data',
      title: 'Data & Workflow',
      description: 'Serialization, shortcuts, and workflow management',
      icon: Icons.data_object_outlined,
      examples: [
        Example(
          id: 'serialization',
          title: 'Save & Load (JSON)',
          description:
              'Export graphs to JSON, save workflows, and restore them',
          icon: Icons.save_outlined,
          builder: (_) => const SerializationExample(),
        ),
        Example(
          id: 'shortcuts',
          title: 'Keyboard Shortcuts',
          description:
              'Comprehensive showcase of all keyboard shortcuts and custom actions',
          icon: Icons.keyboard_outlined,
          builder: (_) => const ShortcutsExample(),
        ),
      ],
    ),

    // 8. Tools & Organization
    ExampleCategory(
      id: 'tools',
      title: 'Tools & Organization',
      description: 'Annotations, alignment, and comprehensive workbench',
      icon: Icons.construction_outlined,
      examples: [
        Example(
          id: 'annotations',
          title: 'Comments & Groups',
          description:
              'Comment nodes and group nodes for organizing your graph',
          icon: Icons.sticky_note_2_outlined,
          builder: (_) => const AnnotationExample(),
        ),
        Example(
          id: 'alignment',
          title: 'Alignment & Distribution',
          description:
              'Align, distribute, and arrange nodes. Use Shift-Drag to select multiple',
          icon: Icons.align_horizontal_center,
          builder: (_) => const AlignmentExample(),
        ),
        Example(
          id: 'workbench',
          title: 'Full Workbench',
          description:
              'Comprehensive demo with workflows, layouts, and interactive tools',
          icon: Icons.dashboard_outlined,
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
