import 'package:flutter/material.dart';

import 'example_model.dart';

// Deferred imports - each example is loaded on-demand
// This reduces initial bundle size for web builds
import 'examples/alignment.dart' deferred as alignment;
import 'examples/hero_showcase.dart' deferred as hero_showcase;
import 'examples/animated_connections.dart' deferred as animated_connections;
import 'examples/annotations.dart' deferred as annotations;
import 'examples/autopan.dart' deferred as autopan;
import 'examples/callbacks.dart' deferred as callbacks;
import 'examples/connection_labels.dart' deferred as connection_labels;
import 'examples/controlling_nodes.dart' deferred as controlling_nodes;
import 'examples/dynamic_ports.dart' deferred as dynamic_ports;
import 'examples/interactive_widgets.dart' deferred as interactive_widgets;
import 'examples/lod.dart' deferred as lod;
import 'examples/minimap.dart' deferred as minimap;
import 'examples/node_shapes.dart' deferred as node_shapes;
import 'examples/port_labels.dart' deferred as port_labels;
import 'examples/ports.dart' deferred as ports;
import 'examples/serialization.dart' deferred as serialization;
import 'examples/shortcuts.dart' deferred as shortcuts;
import 'examples/simple.dart' deferred as simple;
import 'examples/theming.dart' deferred as theming;
import 'examples/validation.dart' deferred as validation;
import 'examples/viewer.dart' deferred as viewer;
import 'examples/viewport_animations.dart' deferred as viewport_animations;
import 'examples/visibility.dart' deferred as visibility;
import 'examples/workbench.dart' deferred as workbench;

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
          loader: () async {
            await simple.loadLibrary();
            return (_) => simple.SimpleNodeAdditionExample();
          },
        ),
        Example(
          id: 'callbacks',
          title: 'Event Callbacks',
          description:
              'Real-time event logging for all node, connection, and viewport lifecycle events',
          icon: Icons.monitor_heart_outlined,
          loader: () async {
            await callbacks.loadLibrary();
            return (_) => callbacks.CallbacksExample();
          },
        ),
        Example(
          id: 'viewer',
          title: 'Read-only Viewer',
          description: 'Display graphs in read-only mode without editing',
          icon: Icons.visibility_outlined,
          loader: () async {
            await viewer.loadLibrary();
            return (_) => viewer.ViewerExample();
          },
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
          loader: () async {
            await controlling_nodes.loadLibrary();
            return (_) => controlling_nodes.ControllingNodesExample();
          },
        ),
        Example(
          id: 'node-shapes',
          title: 'Node Shapes',
          description:
              'Explore different node shapes: Circle, Diamond, Hexagon, and Rectangle',
          icon: Icons.category_outlined,
          loader: () async {
            await node_shapes.loadLibrary();
            return (_) => node_shapes.NodeShapesExample();
          },
        ),
        Example(
          id: 'interactive-widgets',
          title: 'Interactive Widgets',
          description:
              'Buttons, text fields, and sliders inside nodes - drag outside to verify gestures',
          icon: Icons.touch_app_outlined,
          loader: () async {
            await interactive_widgets.loadLibrary();
            return (_) => interactive_widgets.InteractiveWidgetsExample();
          },
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
          loader: () async {
            await ports.loadLibrary();
            return (_) => ports.PortCombinationsDemo();
          },
        ),
        Example(
          id: 'port-labels',
          title: 'Port Labels',
          description:
              'Display and customize port names with intelligent positioning',
          icon: Icons.label_outline,
          loader: () async {
            await port_labels.loadLibrary();
            return (_) => port_labels.PortLabelsExample();
          },
        ),
        Example(
          id: 'dynamic-ports',
          title: 'Dynamic Ports',
          description:
              'Add ports dynamically to nodes - nodes resize automatically',
          icon: Icons.add_link,
          loader: () async {
            await dynamic_ports.loadLibrary();
            return (_) => dynamic_ports.DynamicPortsExample();
          },
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
          loader: () async {
            await animated_connections.loadLibrary();
            return (_) => animated_connections.AnimatedConnectionsExample();
          },
        ),
        Example(
          id: 'connection-labels',
          title: 'Connection Labels',
          description:
              'Add, edit, and position labels dynamically on connections',
          icon: Icons.label_important_outline,
          loader: () async {
            await connection_labels.loadLibrary();
            return (_) => connection_labels.ConnectionLabelsExample();
          },
        ),
        Example(
          id: 'validation',
          title: 'Connection Validation',
          description:
              'Custom validation rules, type checking, and connection limits',
          icon: Icons.verified_user_outlined,
          loader: () async {
            await validation.loadLibrary();
            return (_) => validation.ConnectionValidationExample();
          },
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
          loader: () async {
            await minimap.loadLibrary();
            return (_) => minimap.MinimapExample();
          },
        ),
        Example(
          id: 'viewport-animations',
          title: 'Viewport Animations',
          description:
              'Animated navigation to nodes, positions, bounds, and zoom levels',
          icon: Icons.animation,
          loader: () async {
            await viewport_animations.loadLibrary();
            return (_) => viewport_animations.ViewportAnimationsExample();
          },
        ),
        Example(
          id: 'autopan',
          title: 'AutoPan',
          description: 'Automatic viewport panning when dragging near edges',
          icon: Icons.pan_tool_alt_outlined,
          loader: () async {
            await autopan.loadLibrary();
            return (_) => autopan.AutoPanExample();
          },
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
          loader: () async {
            await theming.loadLibrary();
            return (_) => theming.ThemingExample();
          },
        ),
        Example(
          id: 'lod',
          title: 'Level of Detail',
          description:
              'Automatic visual simplification based on zoom level for performance',
          icon: Icons.layers_outlined,
          loader: () async {
            await lod.loadLibrary();
            return (_) => lod.LODExample();
          },
        ),
        Example(
          id: 'visibility',
          title: 'Visibility Toggling',
          description: 'Show/hide nodes and annotations with eye icon controls',
          icon: Icons.visibility_off_outlined,
          loader: () async {
            await visibility.loadLibrary();
            return (_) => visibility.VisibilityExample();
          },
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
          loader: () async {
            await serialization.loadLibrary();
            return (_) => serialization.SerializationExample();
          },
        ),
        Example(
          id: 'shortcuts',
          title: 'Keyboard Shortcuts',
          description:
              'Comprehensive showcase of all keyboard shortcuts and custom actions',
          icon: Icons.keyboard_outlined,
          loader: () async {
            await shortcuts.loadLibrary();
            return (_) => shortcuts.ShortcutsExample();
          },
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
          loader: () async {
            await annotations.loadLibrary();
            return (_) => annotations.AnnotationExample();
          },
        ),
        Example(
          id: 'alignment',
          title: 'Alignment & Distribution',
          description:
              'Align, distribute, and arrange nodes. Use Shift-Drag to select multiple',
          icon: Icons.align_horizontal_center,
          loader: () async {
            await alignment.loadLibrary();
            return (_) => alignment.AlignmentExample();
          },
        ),
        Example(
          id: 'workbench',
          title: 'Full Workbench',
          description:
              'Comprehensive demo with workflows, layouts, and interactive tools',
          icon: Icons.dashboard_outlined,
          loader: () async {
            await workbench.loadLibrary();
            return (_) => workbench.WorkbenchExample();
          },
        ),
      ],
    ),

    // 9. Showcase
    ExampleCategory(
      id: 'showcase',
      title: 'Showcase',
      description: 'Featured examples demonstrating real-world use cases',
      icon: Icons.auto_awesome,
      examples: [
        Example(
          id: 'hero-image',
          title: 'Image Effects Pipeline',
          description:
              'Visual effects pipeline with image, color, and blur nodes',
          icon: Icons.image_outlined,
          loader: () async {
            await hero_showcase.loadLibrary();
            return (_) => hero_showcase.HeroShowcaseExample();
          },
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
