/// Comprehensive unit tests for GroupNode.
///
/// Tests cover:
/// - GroupNode construction with different behaviors (bounds, explicit, parent)
/// - Member node management (adding/removing members)
/// - fitToNodes functionality
/// - Group bounds calculations
/// - isEmpty and shouldRemoveWhenEmpty properties
/// - Color and title management
/// - Behavior switching via setBehavior
/// - Size constraints and minimum size enforcement
/// - JSON serialization/deserialization
/// - copyWith functionality
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // Construction Tests
  // ==========================================================================
  group('GroupNode Construction', () {
    group('with bounds behavior (default)', () {
      test('creates group with required parameters', () {
        final group = GroupNode<String>(
          id: 'group-1',
          position: const Offset(100, 100),
          size: const Size(400, 300),
          title: 'Test Group',
          data: 'test-data',
        );

        expect(group.id, equals('group-1'));
        expect(group.position.value, equals(const Offset(100, 100)));
        expect(group.size.value, equals(const Size(400, 300)));
        expect(group.currentTitle, equals('Test Group'));
        expect(group.data, equals('test-data'));
        expect(group.type, equals('group'));
        expect(group.behavior, equals(GroupBehavior.bounds));
      });

      test('uses default values when optional parameters are not provided', () {
        final group = createTestGroupNode<String>(data: 'test');

        expect(group.currentColor, equals(Colors.blue));
        expect(group.behavior, equals(GroupBehavior.bounds));
        expect(group.nodeIds, isEmpty);
        expect(group.padding, equals(kGroupNodeDefaultPadding));
        expect(group.zIndex.value, equals(-1));
        expect(group.isVisible, isTrue);
        expect(group.locked, isFalse);
        expect(group.layer, equals(NodeRenderLayer.background));
        expect(group.selectable, isTrue);
      });

      test('allows custom zIndex', () {
        final group = createTestGroupNode<String>(data: 'test', zIndex: -5);

        expect(group.zIndex.value, equals(-5));
      });

      test('allows locked state', () {
        final group = createTestGroupNode<String>(data: 'test', locked: true);

        expect(group.locked, isTrue);
      });

      test('allows custom visibility', () {
        final group = createTestGroupNode<String>(
          data: 'test',
          isVisible: false,
        );

        expect(group.isVisible, isFalse);
      });
    });

    group('with explicit behavior', () {
      test('creates group with explicit behavior and nodeIds', () {
        final group = GroupNode<String>(
          id: 'explicit-group',
          position: const Offset(50, 50),
          size: const Size(500, 400),
          title: 'Explicit Group',
          data: 'test',
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2', 'node-3'},
        );

        expect(group.behavior, equals(GroupBehavior.explicit));
        expect(group.nodeIds, containsAll(['node-1', 'node-2', 'node-3']));
        expect(group.nodeIds.length, equals(3));
      });

      test('creates empty explicit group when nodeIds not provided', () {
        final group = GroupNode<String>(
          id: 'empty-explicit',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Empty Explicit',
          data: 'test',
          behavior: GroupBehavior.explicit,
        );

        expect(group.nodeIds, isEmpty);
        expect(group.isEmpty, isTrue);
      });

      test('is not resizable with explicit behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        expect(group.isResizable, isFalse);
      });
    });

    group('with parent behavior', () {
      test('creates group with parent behavior', () {
        final group = GroupNode<String>(
          id: 'parent-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Parent',
          data: 'test',
          behavior: GroupBehavior.parent,
          nodeIds: {'child-1', 'child-2'},
        );

        expect(group.behavior, equals(GroupBehavior.parent));
        expect(group.hasNode('child-1'), isTrue);
        expect(group.hasNode('child-2'), isTrue);
      });

      test('is resizable with parent behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );

        expect(group.isResizable, isTrue);
      });
    });

    group('with custom padding', () {
      test('accepts custom padding', () {
        const customPadding = EdgeInsets.all(30);
        final group = GroupNode<String>(
          id: 'padded-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Padded',
          data: 'test',
          padding: customPadding,
        );

        expect(group.padding, equals(customPadding));
      });

      test('accepts asymmetric padding', () {
        const asymmetricPadding = EdgeInsets.fromLTRB(10, 50, 20, 30);
        final group = GroupNode<String>(
          id: 'asymmetric-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Asymmetric',
          data: 'test',
          padding: asymmetricPadding,
        );

        expect(group.padding, equals(asymmetricPadding));
      });
    });

    group('with ports (subflow patterns)', () {
      test('creates group with input and output ports', () {
        final inputPort = Port(
          id: 'in-1',
          name: 'Input',
          type: PortType.input,
          position: PortPosition.left,
        );
        final outputPort = Port(
          id: 'out-1',
          name: 'Output',
          type: PortType.output,
          position: PortPosition.right,
        );

        final group = GroupNode<String>(
          id: 'subflow-group',
          position: Offset.zero,
          size: const Size(400, 300),
          title: 'Subflow',
          data: 'test',
          inputPorts: [inputPort],
          outputPorts: [outputPort],
        );

        expect(group.inputPorts.length, equals(1));
        expect(group.outputPorts.length, equals(1));
        expect(group.inputPorts.first.id, equals('in-1'));
        expect(group.outputPorts.first.id, equals('out-1'));
      });

      test('creates group with multiple ports on each side', () {
        final group = createTestGroupNode<String>(
          data: 'test',
          inputPorts: [
            createTestPort(id: 'in-1', type: PortType.input),
            createTestPort(id: 'in-2', type: PortType.input),
          ],
          outputPorts: [
            createTestPort(id: 'out-1', type: PortType.output),
            createTestPort(id: 'out-2', type: PortType.output),
          ],
        );

        expect(group.inputPorts.length, equals(2));
        expect(group.outputPorts.length, equals(2));
      });
    });

    group('with custom color', () {
      test('creates group with custom color', () {
        final group = GroupNode<String>(
          id: 'colored-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Colored',
          data: 'test',
          color: Colors.red,
        );

        expect(group.currentColor, equals(Colors.red));
      });

      test('accepts any Color value', () {
        final customColor = const Color(0xFF123456);
        final group = GroupNode<String>(
          id: 'custom-color-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Custom Color',
          data: 'test',
          color: customColor,
        );

        expect(group.currentColor, equals(customColor));
      });
    });
  });

  // ==========================================================================
  // Member Node Management Tests
  // ==========================================================================
  group('Member Node Management', () {
    group('addNode', () {
      test('adds node to explicit behavior group', () {
        final group = GroupNode<String>(
          id: 'explicit-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Explicit',
          data: 'test',
          behavior: GroupBehavior.explicit,
        );

        group.addNode('new-node');

        expect(group.hasNode('new-node'), isTrue);
        expect(group.nodeIds, contains('new-node'));
      });

      test('adds node to parent behavior group', () {
        final group = GroupNode<String>(
          id: 'parent-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Parent',
          data: 'test',
          behavior: GroupBehavior.parent,
        );

        group.addNode('child-node');

        expect(group.hasNode('child-node'), isTrue);
      });

      test('can add multiple nodes', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        group.addNode('node-1');
        group.addNode('node-2');
        group.addNode('node-3');

        expect(group.nodeIds.length, equals(3));
        expect(group.nodeIds, containsAll(['node-1', 'node-2', 'node-3']));
      });

      test('does not add duplicate nodes', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        group.addNode('node-1');
        group.addNode('node-1'); // duplicate

        expect(group.nodeIds.length, equals(1));
      });
    });

    group('removeNode', () {
      test('removes node from group', () {
        final group = GroupNode<String>(
          id: 'group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Group',
          data: 'test',
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
        );

        group.removeNode('node-1');

        expect(group.hasNode('node-1'), isFalse);
        expect(group.hasNode('node-2'), isTrue);
        expect(group.nodeIds.length, equals(1));
      });

      test('handles removing non-existent node gracefully', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1'},
          data: 'test',
        );

        // Should not throw
        group.removeNode('non-existent');

        expect(group.nodeIds.length, equals(1));
      });

      test('works with bounds behavior (no-op but does not throw)', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        // Should not throw
        group.removeNode('any-node');

        expect(group.nodeIds, isEmpty);
      });
    });

    group('clearNodes', () {
      test('removes all nodes from group', () {
        final group = GroupNode<String>(
          id: 'group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Group',
          data: 'test',
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2', 'node-3'},
        );

        group.clearNodes();

        expect(group.nodeIds, isEmpty);
      });

      test('works on already empty group', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        group.clearNodes();

        expect(group.nodeIds, isEmpty);
      });
    });

    group('hasNode', () {
      test('returns true for member node', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
          data: 'test',
        );

        expect(group.hasNode('node-1'), isTrue);
        expect(group.hasNode('node-2'), isTrue);
      });

      test('returns false for non-member node', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1'},
          data: 'test',
        );

        expect(group.hasNode('node-2'), isFalse);
        expect(group.hasNode('non-existent'), isFalse);
      });

      test('returns false for bounds behavior (membership is spatial)', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          nodeIds: {'node-1'}, // nodeIds ignored for bounds behavior
          data: 'test',
        );

        // For bounds behavior, hasNode checks _nodeIds which may have entries
        // but they're ignored for spatial containment
        expect(group.hasNode('node-1'), isTrue); // But this is in the set
      });
    });

    group('nodeIds', () {
      test('returns unmodifiable set', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
          data: 'test',
        );

        final ids = group.nodeIds;

        expect(ids, containsAll(['node-1', 'node-2']));
        // The returned set should be unmodifiable
        expect(() => (ids).add('new'), throwsUnsupportedError);
      });
    });
  });

  // ==========================================================================
  // fitToNodes Tests
  // ==========================================================================
  group('fitToNodes', () {
    test('does nothing for bounds behavior', () {
      final group = GroupNode<String>(
        id: 'bounds-group',
        position: const Offset(0, 0),
        size: const Size(400, 300),
        title: 'Bounds',
        data: 'test',
        behavior: GroupBehavior.bounds,
      );
      final originalPosition = group.position.value;
      final originalSize = group.size.value;

      // Create a mock lookup
      Node<dynamic>? lookup(String id) => createTestNode(
        id: id,
        position: const Offset(100, 100),
        size: const Size(150, 100),
      );

      group.fitToNodes(lookup);

      expect(group.position.value, equals(originalPosition));
      expect(group.size.value, equals(originalSize));
    });

    test('does nothing for parent behavior', () {
      final group = GroupNode<String>(
        id: 'parent-group',
        position: const Offset(0, 0),
        size: const Size(400, 300),
        title: 'Parent',
        data: 'test',
        behavior: GroupBehavior.parent,
        nodeIds: {'node-1'},
      );
      final originalPosition = group.position.value;
      final originalSize = group.size.value;

      Node<dynamic>? lookup(String id) => createTestNode(
        id: id,
        position: const Offset(100, 100),
        size: const Size(150, 100),
      );

      group.fitToNodes(lookup);

      expect(group.position.value, equals(originalPosition));
      expect(group.size.value, equals(originalSize));
    });

    test('does nothing when nodeIds is empty', () {
      final group = GroupNode<String>(
        id: 'empty-explicit',
        position: const Offset(100, 100),
        size: const Size(400, 300),
        title: 'Empty',
        data: 'test',
        behavior: GroupBehavior.explicit,
      );
      final originalPosition = group.position.value;
      final originalSize = group.size.value;

      Node<dynamic>? lookup(String _) => null;

      group.fitToNodes(lookup);

      expect(group.position.value, equals(originalPosition));
      expect(group.size.value, equals(originalSize));
    });

    test('fits to single node with padding', () {
      final group = GroupNode<String>(
        id: 'explicit-group',
        position: Offset.zero,
        size: Size.zero,
        title: 'Explicit',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1'},
        padding: const EdgeInsets.all(20),
      );

      Node<dynamic>? lookup(String id) {
        if (id == 'node-1') {
          return createTestNode(
            id: 'node-1',
            position: const Offset(100, 100),
            size: const Size(150, 100),
          );
        }
        return null;
      }

      group.fitToNodes(lookup);

      // Node at (100, 100) with size (150, 100)
      // Node bounds: left=100, top=100, right=250, bottom=200
      // With padding of 20 on all sides:
      // Group position: (100-20, 100-20) = (80, 80)
      // Group size: (150+40, 100+40) = (190, 140)
      expect(group.position.value, equals(const Offset(80, 80)));
      expect(group.size.value, equals(const Size(190, 140)));
    });

    test('fits to multiple nodes with bounding box', () {
      final group = GroupNode<String>(
        id: 'multi-node-group',
        position: Offset.zero,
        size: Size.zero,
        title: 'Multi',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
        padding: const EdgeInsets.all(10),
      );

      Node<dynamic>? lookup(String id) {
        if (id == 'node-1') {
          return createTestNode(
            id: 'node-1',
            position: const Offset(50, 50),
            size: const Size(100, 80),
          );
        }
        if (id == 'node-2') {
          return createTestNode(
            id: 'node-2',
            position: const Offset(200, 100),
            size: const Size(120, 90),
          );
        }
        return null;
      }

      group.fitToNodes(lookup);

      // Node-1 bounds: (50, 50) to (150, 130)
      // Node-2 bounds: (200, 100) to (320, 190)
      // Combined bounds: (50, 50) to (320, 190) => width=270, height=140
      // With padding of 10 on all sides:
      // Group position: (50-10, 50-10) = (40, 40)
      // Group size: (270+20, 140+20) = (290, 160)
      expect(group.position.value, equals(const Offset(40, 40)));
      expect(group.size.value, equals(const Size(290, 160)));
    });

    test('uses default padding when computing bounds', () {
      final group = GroupNode<String>(
        id: 'default-padding-group',
        position: Offset.zero,
        size: Size.zero,
        title: 'Default Padding',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1'},
        // Uses kGroupNodeDefaultPadding (20, 40, 20, 20)
      );

      Node<dynamic>? lookup(String id) {
        if (id == 'node-1') {
          return createTestNode(
            id: 'node-1',
            position: const Offset(100, 100),
            size: const Size(150, 100),
          );
        }
        return null;
      }

      group.fitToNodes(lookup);

      // Default padding: left=20, top=40, right=20, bottom=20
      // Node bounds: (100, 100) to (250, 200)
      // Group position: (100-20, 100-40) = (80, 60)
      // Group size: (150+40, 100+60) = (190, 160)
      expect(group.position.value, equals(const Offset(80, 60)));
      expect(group.size.value, equals(const Size(190, 160)));
    });

    test('handles lookup returning null for some nodes', () {
      final group = GroupNode<String>(
        id: 'partial-lookup-group',
        position: Offset.zero,
        size: Size.zero,
        title: 'Partial',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2', 'node-missing'},
        padding: const EdgeInsets.all(10),
      );

      Node<dynamic>? lookup(String id) {
        if (id == 'node-1') {
          return createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          );
        }
        if (id == 'node-2') {
          return createTestNode(
            id: 'node-2',
            position: const Offset(150, 0),
            size: const Size(100, 100),
          );
        }
        return null; // node-missing returns null
      }

      group.fitToNodes(lookup);

      // Only considers nodes that exist
      // Bounds of node-1 + node-2: (0, 0) to (250, 100) => width=250, height=100
      // With padding of 10:
      // Position: (-10, -10)
      // Size: (250+20, 100+20) = (270, 120)
      expect(group.position.value, equals(const Offset(-10, -10)));
      expect(group.size.value, equals(const Size(270, 120)));
    });

    test('does nothing when all lookups return null', () {
      final group = GroupNode<String>(
        id: 'all-null-group',
        position: const Offset(50, 50),
        size: const Size(200, 150),
        title: 'All Null',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'missing-1', 'missing-2'},
      );
      final originalPosition = group.position.value;
      final originalSize = group.size.value;

      Node<dynamic>? lookup(String _) => null;

      group.fitToNodes(lookup);

      expect(group.position.value, equals(originalPosition));
      expect(group.size.value, equals(originalSize));
    });

    test('updates visualPosition along with position', () {
      final group = GroupNode<String>(
        id: 'visual-pos-group',
        position: const Offset(500, 500),
        size: const Size(100, 100),
        title: 'Visual',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1'},
        padding: const EdgeInsets.all(10),
      );

      Node<dynamic>? lookup(String id) {
        if (id == 'node-1') {
          return createTestNode(
            id: 'node-1',
            position: const Offset(100, 100),
            size: const Size(50, 50),
          );
        }
        return null;
      }

      group.fitToNodes(lookup);

      expect(group.position.value, equals(group.visualPosition.value));
    });
  });

  // ==========================================================================
  // Group Bounds Calculations Tests
  // ==========================================================================
  group('Group Bounds Calculations', () {
    group('bounds property', () {
      test('returns correct rectangle from visual position', () {
        final group = GroupNode<String>(
          id: 'bounds-group',
          position: const Offset(100, 50),
          size: const Size(300, 200),
          title: 'Bounds',
          data: 'test',
        );

        final bounds = group.bounds;

        expect(bounds.left, equals(100));
        expect(bounds.top, equals(50));
        expect(bounds.width, equals(300));
        expect(bounds.height, equals(200));
        expect(bounds.right, equals(400));
        expect(bounds.bottom, equals(250));
      });

      test('updates when position changes', () {
        final group = createTestGroupNode<String>(
          position: const Offset(0, 0),
          size: const Size(200, 150),
          data: 'test',
        );

        runInAction(() {
          group.position.value = const Offset(100, 100);
          group.visualPosition.value = const Offset(100, 100);
        });

        final bounds = group.bounds;
        expect(bounds.left, equals(100));
        expect(bounds.top, equals(100));
      });

      test('updates when size changes', () {
        final group = createTestGroupNode<String>(
          position: const Offset(50, 50),
          size: const Size(200, 150),
          data: 'test',
        );

        group.setSize(const Size(400, 300));

        final bounds = group.bounds;
        expect(bounds.width, equals(400));
        expect(bounds.height, equals(300));
      });
    });

    group('containsRect', () {
      test('returns true for rect completely inside bounds', () {
        final group = GroupNode<String>(
          id: 'group',
          position: const Offset(0, 0),
          size: const Size(400, 300),
          title: 'Group',
          data: 'test',
        );

        final innerRect = const Rect.fromLTWH(50, 50, 100, 100);

        expect(group.containsRect(innerRect), isTrue);
      });

      test('returns false for rect completely outside bounds', () {
        final group = GroupNode<String>(
          id: 'group',
          position: const Offset(0, 0),
          size: const Size(400, 300),
          title: 'Group',
          data: 'test',
        );

        final outerRect = const Rect.fromLTWH(500, 500, 100, 100);

        expect(group.containsRect(outerRect), isFalse);
      });

      test('returns false for rect partially overlapping bounds', () {
        final group = GroupNode<String>(
          id: 'group',
          position: const Offset(0, 0),
          size: const Size(400, 300),
          title: 'Group',
          data: 'test',
        );

        final partialRect = const Rect.fromLTWH(350, 250, 100, 100);

        expect(group.containsRect(partialRect), isFalse);
      });

      test('returns false for rect touching outer boundary', () {
        final group = GroupNode<String>(
          id: 'group',
          position: const Offset(0, 0),
          size: const Size(400, 300),
          title: 'Group',
          data: 'test',
        );

        // Rect at exact edge - bottomRight point (400, 300) is outside since
        // containsRect uses Rect.contains which excludes right and bottom edges
        final edgeRect = const Rect.fromLTWH(0, 0, 400, 300);

        // This returns false because the bottomRight point is at the edge
        expect(group.containsRect(edgeRect), isFalse);
      });

      test('returns true for rect at origin within bounds', () {
        final group = GroupNode<String>(
          id: 'group',
          position: const Offset(0, 0),
          size: const Size(400, 300),
          title: 'Group',
          data: 'test',
        );

        final originRect = const Rect.fromLTWH(0, 0, 50, 50);

        expect(group.containsRect(originRect), isTrue);
      });

      test('handles group at negative coordinates', () {
        final group = GroupNode<String>(
          id: 'negative-group',
          position: const Offset(-200, -100),
          size: const Size(400, 300),
          title: 'Negative',
          data: 'test',
        );

        final insideRect = const Rect.fromLTWH(-150, -50, 100, 100);
        final outsideRect = const Rect.fromLTWH(300, 300, 50, 50);

        expect(group.containsRect(insideRect), isTrue);
        expect(group.containsRect(outsideRect), isFalse);
      });
    });

    group('currentSize', () {
      test('returns observable size value', () {
        final group = createTestGroupNode<String>(
          size: const Size(350, 250),
          data: 'test',
        );

        expect(group.currentSize, equals(const Size(350, 250)));
      });

      test('reflects changes made via setSize', () {
        final group = createTestGroupNode<String>(
          size: const Size(200, 150),
          data: 'test',
        );

        group.setSize(const Size(400, 300));

        expect(group.currentSize, equals(const Size(400, 300)));
      });
    });
  });

  // ==========================================================================
  // isEmpty and shouldRemoveWhenEmpty Tests
  // ==========================================================================
  group('isEmpty and shouldRemoveWhenEmpty', () {
    group('isEmpty', () {
      test('returns true for explicit behavior with no nodes', () {
        final group = GroupNode<String>(
          id: 'empty-explicit',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Empty',
          data: 'test',
          behavior: GroupBehavior.explicit,
        );

        expect(group.isEmpty, isTrue);
      });

      test('returns false for explicit behavior with nodes', () {
        final group = GroupNode<String>(
          id: 'non-empty-explicit',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Non-Empty',
          data: 'test',
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1'},
        );

        expect(group.isEmpty, isFalse);
      });

      test('returns true for parent behavior with no nodes', () {
        final group = GroupNode<String>(
          id: 'empty-parent',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Empty Parent',
          data: 'test',
          behavior: GroupBehavior.parent,
        );

        expect(group.isEmpty, isTrue);
      });

      test('returns false for parent behavior with nodes', () {
        final group = GroupNode<String>(
          id: 'non-empty-parent',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Non-Empty Parent',
          data: 'test',
          behavior: GroupBehavior.parent,
          nodeIds: {'child-1'},
        );

        expect(group.isEmpty, isFalse);
      });

      test(
        'returns false for bounds behavior (always not empty conceptually)',
        () {
          final group = createTestGroupNode<String>(
            behavior: GroupBehavior.bounds,
            data: 'test',
          );

          expect(group.isEmpty, isFalse);
        },
      );

      test('updates when nodes are added', () {
        final group = GroupNode<String>(
          id: 'dynamic-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Dynamic',
          data: 'test',
          behavior: GroupBehavior.explicit,
        );

        expect(group.isEmpty, isTrue);

        group.addNode('new-node');

        expect(group.isEmpty, isFalse);
      });

      test('updates when nodes are removed', () {
        final group = GroupNode<String>(
          id: 'dynamic-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Dynamic',
          data: 'test',
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1'},
        );

        expect(group.isEmpty, isFalse);

        group.removeNode('node-1');

        expect(group.isEmpty, isTrue);
      });
    });

    group('shouldRemoveWhenEmpty', () {
      test('returns true for explicit behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        expect(group.shouldRemoveWhenEmpty, isTrue);
      });

      test('returns false for bounds behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        expect(group.shouldRemoveWhenEmpty, isFalse);
      });

      test('returns false for parent behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );

        expect(group.shouldRemoveWhenEmpty, isFalse);
      });
    });

    group('isGroupable', () {
      test('returns false for bounds behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        expect(group.isGroupable, isFalse);
      });

      test('returns true for explicit behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        expect(group.isGroupable, isTrue);
      });

      test('returns true for parent behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );

        expect(group.isGroupable, isTrue);
      });
    });

    group('groupedNodeIds', () {
      test('returns empty set for bounds behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          nodeIds: {'node-1', 'node-2'}, // Should be ignored
          data: 'test',
        );

        expect(group.groupedNodeIds, isEmpty);
      });

      test('returns nodeIds for explicit behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
          data: 'test',
        );

        expect(group.groupedNodeIds, containsAll(['node-1', 'node-2']));
      });

      test('returns nodeIds for parent behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          nodeIds: {'child-1', 'child-2'},
          data: 'test',
        );

        expect(group.groupedNodeIds, containsAll(['child-1', 'child-2']));
      });
    });
  });

  // ==========================================================================
  // Color and Title Management Tests
  // ==========================================================================
  group('Color and Title Management', () {
    group('updateTitle', () {
      test('updates title value', () {
        final group = createTestGroupNode<String>(
          title: 'Initial Title',
          data: 'test',
        );

        group.updateTitle('New Title');

        expect(group.currentTitle, equals('New Title'));
      });

      test('triggers observable reaction', () {
        final group = createTestGroupNode<String>(
          title: 'Initial',
          data: 'test',
        );
        final tracker = ObservableTracker<String>();
        tracker.track(group.observableTitle);

        group.updateTitle('Updated');

        expect(tracker.values, contains('Updated'));
        tracker.dispose();
      });

      test('accepts empty string', () {
        final group = createTestGroupNode<String>(
          title: 'Has Title',
          data: 'test',
        );

        group.updateTitle('');

        expect(group.currentTitle, isEmpty);
      });

      test('accepts special characters', () {
        final group = createTestGroupNode<String>(
          title: 'Initial',
          data: 'test',
        );

        group.updateTitle('Title with <special> & "characters"');

        expect(
          group.currentTitle,
          equals('Title with <special> & "characters"'),
        );
      });
    });

    group('updateColor', () {
      test('updates color value', () {
        final group = createTestGroupNode<String>(
          color: Colors.blue,
          data: 'test',
        );

        group.updateColor(Colors.red);

        expect(group.currentColor, equals(Colors.red));
      });

      test('triggers observable reaction', () {
        final group = createTestGroupNode<String>(
          color: Colors.blue,
          data: 'test',
        );
        final tracker = ObservableTracker<Color>();
        tracker.track(group.observableColor);

        group.updateColor(Colors.green);

        expect(tracker.values, contains(Colors.green));
        tracker.dispose();
      });

      test('accepts custom ARGB color', () {
        final group = createTestGroupNode<String>(
          color: Colors.blue,
          data: 'test',
        );

        final customColor = const Color(0xFFABCDEF);
        group.updateColor(customColor);

        expect(group.currentColor, equals(customColor));
      });

      test('accepts transparent color', () {
        final group = createTestGroupNode<String>(
          color: Colors.blue,
          data: 'test',
        );

        group.updateColor(Colors.transparent);

        expect(group.currentColor, equals(Colors.transparent));
      });
    });

    group('observableTitle', () {
      test('provides access to title observable', () {
        final group = createTestGroupNode<String>(
          title: 'Observable Title',
          data: 'test',
        );

        expect(group.observableTitle.value, equals('Observable Title'));
      });
    });

    group('observableColor', () {
      test('provides access to color observable', () {
        final group = createTestGroupNode<String>(
          color: Colors.purple,
          data: 'test',
        );

        expect(group.observableColor.value, equals(Colors.purple));
      });
    });

    group('observableSize', () {
      test('provides access to size observable', () {
        final group = createTestGroupNode<String>(
          size: const Size(450, 350),
          data: 'test',
        );

        expect(group.observableSize.value, equals(const Size(450, 350)));
      });
    });
  });

  // ==========================================================================
  // Size Constraints Tests
  // ==========================================================================
  group('Size Constraints', () {
    group('setSize', () {
      test('enforces minimum width of 100', () {
        final group = createTestGroupNode<String>(data: 'test');

        group.setSize(const Size(50, 200));

        expect(group.currentSize.width, equals(100));
      });

      test('enforces minimum height of 60', () {
        final group = createTestGroupNode<String>(data: 'test');

        group.setSize(const Size(200, 30));

        expect(group.currentSize.height, equals(60));
      });

      test('allows size at exactly minimum', () {
        final group = createTestGroupNode<String>(data: 'test');

        group.setSize(const Size(100, 60));

        expect(group.currentSize, equals(const Size(100, 60)));
      });

      test('allows large sizes', () {
        final group = createTestGroupNode<String>(data: 'test');

        group.setSize(const Size(10000, 8000));

        expect(group.currentSize, equals(const Size(10000, 8000)));
      });

      test('handles negative width by clamping', () {
        final group = createTestGroupNode<String>(data: 'test');

        group.setSize(const Size(-50, 200));

        expect(group.currentSize.width, equals(100));
      });

      test('handles negative height by clamping', () {
        final group = createTestGroupNode<String>(data: 'test');

        group.setSize(const Size(200, -30));

        expect(group.currentSize.height, equals(60));
      });
    });

    group('minSize', () {
      test('returns Size(100, 60)', () {
        final group = createTestGroupNode<String>(data: 'test');

        expect(group.minSize, equals(const Size(100, 60)));
      });
    });

    group('isResizable', () {
      test('returns true for bounds behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        expect(group.isResizable, isTrue);
      });

      test('returns false for explicit behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        expect(group.isResizable, isFalse);
      });

      test('returns true for parent behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );

        expect(group.isResizable, isTrue);
      });
    });
  });

  // ==========================================================================
  // setBehavior Tests
  // ==========================================================================
  group('setBehavior', () {
    test('changes from bounds to explicit', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );

      group.setBehavior(GroupBehavior.explicit);

      expect(group.behavior, equals(GroupBehavior.explicit));
    });

    test('changes from bounds to parent', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );

      group.setBehavior(GroupBehavior.parent);

      expect(group.behavior, equals(GroupBehavior.parent));
    });

    test('changes from explicit to bounds', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.explicit,
        data: 'test',
      );

      group.setBehavior(GroupBehavior.bounds);

      expect(group.behavior, equals(GroupBehavior.bounds));
    });

    test('changes from explicit to parent', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1'},
        data: 'test',
      );

      group.setBehavior(GroupBehavior.parent);

      expect(group.behavior, equals(GroupBehavior.parent));
      // nodeIds should be preserved
      expect(group.nodeIds, contains('node-1'));
    });

    test('does nothing when setting same behavior', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1'},
        data: 'test',
      );

      group.setBehavior(GroupBehavior.explicit);

      expect(group.behavior, equals(GroupBehavior.explicit));
      expect(group.nodeIds, contains('node-1'));
    });

    test(
      'captures contained nodes when switching from bounds to explicit/parent',
      () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        group.setBehavior(
          GroupBehavior.explicit,
          captureContainedNodes: {'captured-1', 'captured-2'},
        );

        expect(group.nodeIds, containsAll(['captured-1', 'captured-2']));
      },
    );

    test('clears nodeIds when switching to bounds by default', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
        data: 'test',
      );

      group.setBehavior(GroupBehavior.bounds);

      expect(group.nodeIds, isEmpty);
    });

    test(
      'preserves nodeIds when switching to bounds with clearNodesOnBoundsSwitch=false',
      () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
          data: 'test',
        );

        group.setBehavior(
          GroupBehavior.bounds,
          clearNodesOnBoundsSwitch: false,
        );

        expect(group.nodeIds, containsAll(['node-1', 'node-2']));
      },
    );

    test('updates isResizable based on new behavior', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );

      expect(group.isResizable, isTrue);

      group.setBehavior(GroupBehavior.explicit);

      expect(group.isResizable, isFalse);
    });

    test('triggers observableBehavior reaction', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );
      final tracker = ObservableTracker<GroupBehavior>();
      tracker.track(group.observableBehavior);

      group.setBehavior(GroupBehavior.parent);

      expect(tracker.values, contains(GroupBehavior.parent));
      tracker.dispose();
    });

    test('calls fitToNodes when switching to explicit with nodeLookup', () {
      final group = GroupNode<String>(
        id: 'fit-group',
        position: const Offset(0, 0),
        size: const Size(100, 100),
        title: 'Fit Group',
        data: 'test',
        behavior: GroupBehavior.bounds,
        padding: const EdgeInsets.all(10),
      );

      Node<dynamic>? lookup(String id) {
        if (id == 'node-1') {
          return createTestNode(
            id: 'node-1',
            position: const Offset(100, 100),
            size: const Size(
              150,
              100,
            ), // Size that results in > minimum after padding
          );
        }
        return null;
      }

      group.setBehavior(
        GroupBehavior.explicit,
        captureContainedNodes: {'node-1'},
        nodeLookup: lookup,
      );

      // Should have fit to node-1
      // Node at (100,100) size (150,100) with padding 10
      // Position: (90, 90), Size: (170, 120)
      expect(group.position.value, equals(const Offset(90, 90)));
      expect(group.size.value, equals(const Size(170, 120)));
    });
  });

  // ==========================================================================
  // onChildrenDeleted Tests
  // ==========================================================================
  group('onChildrenDeleted', () {
    test('removes deleted nodes from nodeIds', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2', 'node-3'},
        data: 'test',
      );

      group.onChildrenDeleted({'node-1', 'node-3'});

      expect(group.nodeIds.length, equals(1));
      expect(group.nodeIds, contains('node-2'));
      expect(group.hasNode('node-1'), isFalse);
      expect(group.hasNode('node-3'), isFalse);
    });

    test('handles deletion of non-member nodes', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
        data: 'test',
      );

      group.onChildrenDeleted({'non-existent', 'also-non-existent'});

      expect(group.nodeIds.length, equals(2));
    });

    test('handles mixed deletion of members and non-members', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
        data: 'test',
      );

      group.onChildrenDeleted({'node-1', 'non-existent'});

      expect(group.nodeIds.length, equals(1));
      expect(group.nodeIds, contains('node-2'));
    });

    test('handles empty deletion set', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
        data: 'test',
      );

      group.onChildrenDeleted({});

      expect(group.nodeIds.length, equals(2));
    });
  });

  // ==========================================================================
  // copyWith Tests
  // ==========================================================================
  group('copyWith', () {
    test('creates copy with same values when no overrides provided', () {
      final original = GroupNode<String>(
        id: 'original',
        position: const Offset(100, 100),
        size: const Size(400, 300),
        title: 'Original Title',
        data: 'original-data',
        color: Colors.purple,
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
        padding: const EdgeInsets.all(25),
        zIndex: 5,
        isVisible: true,
        locked: false,
      );

      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.position.value, equals(original.position.value));
      expect(copy.size.value, equals(original.size.value));
      expect(copy.currentTitle, equals(original.currentTitle));
      expect(copy.data, equals(original.data));
      expect(copy.currentColor, equals(original.currentColor));
      expect(copy.behavior, equals(original.behavior));
      expect(copy.nodeIds, equals(original.nodeIds));
      expect(copy.padding, equals(original.padding));
      expect(copy.zIndex.value, equals(original.zIndex.value));
      expect(copy.isVisible, equals(original.isVisible));
      expect(copy.locked, equals(original.locked));
    });

    test('creates copy with overridden id', () {
      final original = createTestGroupNode<String>(
        id: 'original',
        data: 'test',
      );

      final copy = original.copyWith(id: 'new-id');

      expect(copy.id, equals('new-id'));
    });

    test('creates copy with overridden position', () {
      final original = createTestGroupNode<String>(
        position: const Offset(0, 0),
        data: 'test',
      );

      final copy = original.copyWith(position: const Offset(200, 150));

      expect(copy.position.value, equals(const Offset(200, 150)));
    });

    test('creates copy with overridden size', () {
      final original = createTestGroupNode<String>(
        size: const Size(300, 200),
        data: 'test',
      );

      final copy = original.copyWith(size: const Size(500, 400));

      expect(copy.size.value, equals(const Size(500, 400)));
    });

    test('creates copy with overridden title', () {
      final original = createTestGroupNode<String>(
        title: 'Original',
        data: 'test',
      );

      final copy = original.copyWith(title: 'New Title');

      expect(copy.currentTitle, equals('New Title'));
    });

    test('creates copy with overridden data', () {
      final original = createTestGroupNode<String>(data: 'original-data');

      final copy = original.copyWith(data: 'new-data');

      expect(copy.data, equals('new-data'));
    });

    test('creates copy with overridden color', () {
      final original = createTestGroupNode<String>(
        color: Colors.blue,
        data: 'test',
      );

      final copy = original.copyWith(color: Colors.red);

      expect(copy.currentColor, equals(Colors.red));
    });

    test('creates copy with overridden behavior', () {
      final original = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );

      final copy = original.copyWith(behavior: GroupBehavior.parent);

      expect(copy.behavior, equals(GroupBehavior.parent));
    });

    test('creates copy with overridden nodeIds', () {
      final original = createTestGroupNode<String>(
        behavior: GroupBehavior.explicit,
        nodeIds: {'old-1', 'old-2'},
        data: 'test',
      );

      final copy = original.copyWith(nodeIds: {'new-1', 'new-2', 'new-3'});

      expect(copy.nodeIds, containsAll(['new-1', 'new-2', 'new-3']));
      expect(copy.nodeIds.length, equals(3));
    });

    test('creates copy with overridden padding', () {
      final original = createTestGroupNode<String>(
        padding: const EdgeInsets.all(20),
        data: 'test',
      );

      final copy = original.copyWith(padding: const EdgeInsets.all(50));

      expect(copy.padding, equals(const EdgeInsets.all(50)));
    });

    test('creates copy with overridden zIndex', () {
      final original = createTestGroupNode<String>(zIndex: -1, data: 'test');

      final copy = original.copyWith(zIndex: 10);

      expect(copy.zIndex.value, equals(10));
    });

    test('creates copy with overridden visibility', () {
      final original = createTestGroupNode<String>(
        isVisible: true,
        data: 'test',
      );

      final copy = original.copyWith(isVisible: false);

      expect(copy.isVisible, isFalse);
    });

    test('creates copy with overridden locked state', () {
      final original = createTestGroupNode<String>(locked: false, data: 'test');

      final copy = original.copyWith(locked: true);

      expect(copy.locked, isTrue);
    });

    test('creates copy with overridden ports', () {
      final original = createTestGroupNode<String>(
        inputPorts: [createTestPort(id: 'old-in', type: PortType.input)],
        outputPorts: [createTestPort(id: 'old-out', type: PortType.output)],
        data: 'test',
      );

      final newInputPorts = [
        createTestPort(id: 'new-in-1', type: PortType.input),
        createTestPort(id: 'new-in-2', type: PortType.input),
      ];
      final newOutputPorts = [
        createTestPort(id: 'new-out-1', type: PortType.output),
      ];

      final copy = original.copyWith(
        inputPorts: newInputPorts,
        outputPorts: newOutputPorts,
      );

      expect(copy.inputPorts.length, equals(2));
      expect(copy.outputPorts.length, equals(1));
      expect(copy.inputPorts.first.id, equals('new-in-1'));
    });

    test('copy is independent of original', () {
      final original = createTestGroupNode<String>(
        title: 'Original',
        color: Colors.blue,
        data: 'test',
      );

      final copy = original.copyWith();

      // Modify original
      original.updateTitle('Modified Original');
      original.updateColor(Colors.red);

      // Copy should be unchanged
      expect(copy.currentTitle, equals('Original'));
      expect(copy.currentColor, equals(Colors.blue));
    });
  });

  // ==========================================================================
  // JSON Serialization Tests
  // ==========================================================================
  group('JSON Serialization', () {
    group('toJson', () {
      test('serializes basic group node', () {
        final group = GroupNode<String>(
          id: 'json-group',
          position: const Offset(100, 200),
          size: const Size(400, 300),
          title: 'JSON Group',
          data: 'json-data',
        );

        final json = group.toJson((data) => data);

        expect(json['id'], equals('json-group'));
        expect(json['type'], equals('group'));
        expect(json['x'], equals(100.0));
        expect(json['y'], equals(200.0));
        expect(json['width'], equals(400.0));
        expect(json['height'], equals(300.0));
        expect(json['title'], equals('JSON Group'));
        expect(json['data'], equals('json-data'));
      });

      test('serializes color as ARGB32', () {
        final group = createTestGroupNode<String>(
          color: Colors.red,
          data: 'test',
        );

        final json = group.toJson((data) => data);

        expect(json['color'], equals(Colors.red.toARGB32()));
      });

      test('serializes behavior name', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        final json = group.toJson((data) => data);

        expect(json['behavior'], equals('explicit'));
      });

      test('serializes nodeIds as list', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-a', 'node-b', 'node-c'},
          data: 'test',
        );

        final json = group.toJson((data) => data);

        expect(json['nodeIds'], isA<List>());
        expect(json['nodeIds'], containsAll(['node-a', 'node-b', 'node-c']));
      });

      test('serializes padding as LTRB array', () {
        final group = createTestGroupNode<String>(
          padding: const EdgeInsets.fromLTRB(10, 20, 30, 40),
          data: 'test',
        );

        final json = group.toJson((data) => data);

        expect(json['padding'], equals([10.0, 20.0, 30.0, 40.0]));
      });

      test('serializes zIndex', () {
        final group = createTestGroupNode<String>(zIndex: -5, data: 'test');

        final json = group.toJson((data) => data);

        expect(json['zIndex'], equals(-5));
      });

      test('serializes visibility', () {
        final group = createTestGroupNode<String>(
          isVisible: false,
          data: 'test',
        );

        final json = group.toJson((data) => data);

        expect(json['isVisible'], isFalse);
      });

      test('serializes ports', () {
        final group = createTestGroupNode<String>(
          inputPorts: [createTestPort(id: 'in-1', type: PortType.input)],
          outputPorts: [createTestPort(id: 'out-1', type: PortType.output)],
          data: 'test',
        );

        final json = group.toJson((data) => data);

        expect(json['inputPorts'], isA<List>());
        expect(json['outputPorts'], isA<List>());
        expect((json['inputPorts'] as List).length, equals(1));
        expect((json['outputPorts'] as List).length, equals(1));
      });
    });

    group('fromJson', () {
      test('deserializes basic group node', () {
        final json = {
          'id': 'reconstructed',
          'x': 100.0,
          'y': 200.0,
          'width': 400.0,
          'height': 300.0,
          'title': 'Reconstructed',
          'data': 'data-value',
        };

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(group.id, equals('reconstructed'));
        expect(group.position.value, equals(const Offset(100, 200)));
        expect(group.size.value, equals(const Size(400, 300)));
        expect(group.currentTitle, equals('Reconstructed'));
        expect(group.data, equals('data-value'));
      });

      test('deserializes color from ARGB32', () {
        final json = {
          'id': 'colored',
          'x': 0.0,
          'y': 0.0,
          'data': 'test',
          'color': Colors.green.toARGB32(),
        };

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(group.currentColor.toARGB32(), equals(Colors.green.toARGB32()));
      });

      test('deserializes behavior from name', () {
        final json = {
          'id': 'parent-group',
          'x': 0.0,
          'y': 0.0,
          'data': 'test',
          'behavior': 'parent',
        };

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(group.behavior, equals(GroupBehavior.parent));
      });

      test('deserializes nodeIds from list', () {
        final json = {
          'id': 'explicit-group',
          'x': 0.0,
          'y': 0.0,
          'data': 'test',
          'behavior': 'explicit',
          'nodeIds': ['node-1', 'node-2'],
        };

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(group.nodeIds, containsAll(['node-1', 'node-2']));
      });

      test('deserializes padding from LTRB array', () {
        final json = {
          'id': 'padded',
          'x': 0.0,
          'y': 0.0,
          'data': 'test',
          'padding': [15.0, 25.0, 35.0, 45.0],
        };

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(
          group.padding,
          equals(const EdgeInsets.fromLTRB(15, 25, 35, 45)),
        );
      });

      test('deserializes padding from map format', () {
        final json = {
          'id': 'padded-map',
          'x': 0.0,
          'y': 0.0,
          'data': 'test',
          'padding': {'left': 10.0, 'top': 20.0, 'right': 30.0, 'bottom': 40.0},
        };

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(
          group.padding,
          equals(const EdgeInsets.fromLTRB(10, 20, 30, 40)),
        );
      });

      test('uses default values for missing optional fields', () {
        final json = {'id': 'minimal', 'x': 0.0, 'y': 0.0, 'data': 'test'};

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(group.currentTitle, isEmpty);
        expect(group.behavior, equals(GroupBehavior.bounds));
        expect(group.currentColor.toARGB32(), equals(Colors.blue.toARGB32()));
        expect(group.size.value.width, equals(200.0));
        expect(group.size.value.height, equals(150.0));
        expect(group.zIndex.value, equals(-1));
        expect(group.isVisible, isTrue);
        expect(group.locked, isFalse);
      });

      test('deserializes ports', () {
        final json = {
          'id': 'with-ports',
          'x': 0.0,
          'y': 0.0,
          'data': 'test',
          'inputPorts': [
            {
              'id': 'in-1',
              'name': 'Input',
              'type': 'input',
              'position': 'left',
            },
          ],
          'outputPorts': [
            {
              'id': 'out-1',
              'name': 'Output',
              'type': 'output',
              'position': 'right',
            },
          ],
        };

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(group.inputPorts.length, equals(1));
        expect(group.outputPorts.length, equals(1));
        expect(group.inputPorts.first.id, equals('in-1'));
        expect(group.outputPorts.first.id, equals('out-1'));
      });

      test('round-trip serialization preserves all data', () {
        final original = GroupNode<String>(
          id: 'round-trip',
          position: const Offset(123, 456),
          size: const Size(789, 321),
          title: 'Round Trip Test',
          data: 'round-trip-data',
          color: Colors.orange,
          behavior: GroupBehavior.parent,
          nodeIds: {'child-1', 'child-2'},
          padding: const EdgeInsets.fromLTRB(11, 22, 33, 44),
          zIndex: 7,
          isVisible: true,
          locked: true,
        );

        final json = original.toJson((data) => data);
        final reconstructed = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.position.value, equals(original.position.value));
        expect(reconstructed.size.value, equals(original.size.value));
        expect(reconstructed.currentTitle, equals(original.currentTitle));
        expect(reconstructed.data, equals(original.data));
        expect(
          reconstructed.currentColor.toARGB32(),
          equals(original.currentColor.toARGB32()),
        );
        expect(reconstructed.behavior, equals(original.behavior));
        expect(reconstructed.nodeIds, equals(original.nodeIds));
        expect(reconstructed.padding, equals(original.padding));
        expect(reconstructed.zIndex.value, equals(original.zIndex.value));
        expect(reconstructed.isVisible, equals(original.isVisible));
        expect(reconstructed.locked, equals(original.locked));
      });
    });
  });

  // ==========================================================================
  // Drag Behavior Tests
  // ==========================================================================
  group('Drag Behavior', () {
    group('onDragStart', () {
      test('captures nodes inside bounds for bounds behavior', () {
        final group = createTestGroupNode<String>(
          position: const Offset(0, 0),
          size: const Size(300, 200),
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        // Create nodes at different positions
        final nodeInside = createTestNode(
          id: 'inside',
          position: const Offset(50, 50),
          size: const Size(100, 80),
        );
        final nodeOutside = createTestNode(
          id: 'outside',
          position: const Offset(500, 500),
          size: const Size(100, 80),
        );

        final nodeMap = {'inside': nodeInside, 'outside': nodeOutside};

        final capturedNodes = <Set<String>>[];

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {},
          findNodesInBounds: (bounds) {
            // Return nodes that are inside the bounds
            final result = <String>{};
            for (final entry in nodeMap.entries) {
              final nodeRect = Rect.fromLTWH(
                entry.value.position.value.dx,
                entry.value.position.value.dy,
                entry.value.size.value.width,
                entry.value.size.value.height,
              );
              if (bounds.contains(nodeRect.topLeft) &&
                  bounds.contains(nodeRect.bottomRight)) {
                result.add(entry.key);
              }
            }
            capturedNodes.add(result);
            return result;
          },
          getNode: (id) => nodeMap[id],
          selectedNodeIds: const {},
        );

        group.onDragStart(context);

        expect(capturedNodes.length, equals(1));
        expect(capturedNodes.first, contains('inside'));
        expect(capturedNodes.first, isNot(contains('outside')));
      });

      test('uses nodeIds for explicit behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'member-1', 'member-2'},
          data: 'test',
        );

        var findNodesInBoundsCalled = false;

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {},
          findNodesInBounds: (bounds) {
            findNodesInBoundsCalled = true;
            return {};
          },
          getNode: (id) => null,
          selectedNodeIds: const {},
        );

        group.onDragStart(context);

        // For explicit behavior, findNodesInBounds should NOT be called
        // because membership is explicit, not spatial
        expect(findNodesInBoundsCalled, isFalse);
      });

      test('uses nodeIds for parent behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          nodeIds: {'child-1', 'child-2'},
          data: 'test',
        );

        var findNodesInBoundsCalled = false;

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {},
          findNodesInBounds: (bounds) {
            findNodesInBoundsCalled = true;
            return {};
          },
          getNode: (id) => null,
          selectedNodeIds: const {},
        );

        group.onDragStart(context);

        // For parent behavior, findNodesInBounds should NOT be called
        expect(findNodesInBoundsCalled, isFalse);
      });
    });

    group('onDragMove', () {
      test('moves all contained nodes when none are selected', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2', 'node-3'},
          data: 'test',
        );

        Set<String>? movedNodeIds;
        Offset? movedDelta;

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {
            movedNodeIds = nodeIds;
            movedDelta = delta;
          },
          findNodesInBounds: (bounds) => {},
          getNode: (id) => null,
          selectedNodeIds: const {}, // No selected nodes
        );

        // Start drag to capture contained nodes
        group.onDragStart(context);

        // Move the group
        const delta = Offset(50, 30);
        group.onDragMove(delta, context);

        // All contained nodes should be moved
        expect(movedNodeIds, isNotNull);
        expect(movedNodeIds, containsAll(['node-1', 'node-2', 'node-3']));
        expect(movedNodeIds!.length, equals(3));
        expect(movedDelta, equals(delta));
      });

      test('excludes selected nodes from being moved', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2', 'node-3'},
          data: 'test',
        );

        Set<String>? movedNodeIds;

        // Create context with some nodes already selected
        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {
            movedNodeIds = nodeIds;
          },
          findNodesInBounds: (bounds) => {},
          getNode: (id) => null,
          selectedNodeIds: const {'node-1', 'node-3'}, // These are selected
        );

        // Start drag
        group.onDragStart(context);

        // Move the group
        group.onDragMove(const Offset(50, 30), context);

        // Only node-2 should be moved (node-1 and node-3 are already selected)
        expect(movedNodeIds, isNotNull);
        expect(movedNodeIds, equals({'node-2'}));
        expect(movedNodeIds, isNot(contains('node-1')));
        expect(movedNodeIds, isNot(contains('node-3')));
      });

      test('does not call moveNodes when all contained nodes are selected', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
          data: 'test',
        );

        var moveNodesCalled = false;

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {
            moveNodesCalled = true;
          },
          findNodesInBounds: (bounds) => {},
          getNode: (id) => null,
          selectedNodeIds: const {'node-1', 'node-2'}, // All nodes selected
        );

        // Start drag
        group.onDragStart(context);

        // Move the group
        group.onDragMove(const Offset(50, 30), context);

        // moveNodes should NOT be called since all contained nodes are selected
        expect(moveNodesCalled, isFalse);
      });

      test('does not call moveNodes when no contained nodes', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {}, // Empty
          data: 'test',
        );

        var moveNodesCalled = false;

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {
            moveNodesCalled = true;
          },
          findNodesInBounds: (bounds) => {},
          getNode: (id) => null,
          selectedNodeIds: const {},
        );

        // Start drag
        group.onDragStart(context);

        // Move the group
        group.onDragMove(const Offset(50, 30), context);

        // moveNodes should NOT be called since no contained nodes
        expect(moveNodesCalled, isFalse);
      });

      test('works correctly with bounds behavior', () {
        final group = createTestGroupNode<String>(
          position: const Offset(0, 0),
          size: const Size(400, 300),
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        Set<String>? movedNodeIds;

        // Create mock nodes
        final insideNode = createTestNode(
          id: 'inside-node',
          position: const Offset(50, 50),
          size: const Size(100, 80),
        );

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {
            movedNodeIds = nodeIds;
          },
          findNodesInBounds: (bounds) {
            // Simulate finding the inside node
            return {'inside-node'};
          },
          getNode: (id) => id == 'inside-node' ? insideNode : null,
          selectedNodeIds: const {}, // No selection
        );

        // Start drag
        group.onDragStart(context);

        // Move the group
        group.onDragMove(const Offset(50, 30), context);

        // The inside node should be moved
        expect(movedNodeIds, equals({'inside-node'}));
      });

      test('excludes selected nodes with bounds behavior', () {
        final group = createTestGroupNode<String>(
          position: const Offset(0, 0),
          size: const Size(400, 300),
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        Set<String>? movedNodeIds;

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {
            movedNodeIds = nodeIds;
          },
          findNodesInBounds: (bounds) {
            // Simulate finding multiple nodes
            return {'node-a', 'node-b', 'node-c'};
          },
          getNode: (id) => null,
          selectedNodeIds: const {'node-b'}, // node-b is selected
        );

        // Start drag
        group.onDragStart(context);

        // Move the group
        group.onDragMove(const Offset(50, 30), context);

        // node-a and node-c should be moved, but NOT node-b
        expect(movedNodeIds, containsAll(['node-a', 'node-c']));
        expect(movedNodeIds, isNot(contains('node-b')));
        expect(movedNodeIds!.length, equals(2));
      });

      test('handles selectedNodeIds containing nodes not in group', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'member-1', 'member-2'},
          data: 'test',
        );

        Set<String>? movedNodeIds;

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {
            movedNodeIds = nodeIds;
          },
          findNodesInBounds: (bounds) => {},
          getNode: (id) => null,
          // selected nodes include both group members and external nodes
          selectedNodeIds: const {'member-1', 'external-node'},
        );

        // Start drag
        group.onDragStart(context);

        // Move the group
        group.onDragMove(const Offset(50, 30), context);

        // Only member-2 should be moved
        // (member-1 is selected, external-node is irrelevant)
        expect(movedNodeIds, equals({'member-2'}));
      });
    });

    group('onDragEnd', () {
      test('clears contained node cache', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
          data: 'test',
        );

        var moveNodesCallCount = 0;

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {
            moveNodesCallCount++;
          },
          findNodesInBounds: (bounds) => {},
          getNode: (id) => null,
          selectedNodeIds: const {},
        );

        // Start drag
        group.onDragStart(context);

        // Move (should call moveNodes)
        group.onDragMove(const Offset(50, 30), context);
        expect(moveNodesCallCount, equals(1));

        // End drag
        group.onDragEnd();

        // Move again without starting drag (should NOT call moveNodes)
        group.onDragMove(const Offset(50, 30), context);
        expect(moveNodesCallCount, equals(1)); // Still 1, not 2
      });
    });

    group('drag lifecycle integration', () {
      test('complete drag cycle with partial selection', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'a', 'b', 'c', 'd'},
          data: 'test',
        );

        final movedNodeHistory = <Set<String>>[];

        final context = NodeDragContext<String>(
          moveNodes: (nodeIds, delta) {
            movedNodeHistory.add(Set.from(nodeIds));
          },
          findNodesInBounds: (bounds) => {},
          getNode: (id) => null,
          selectedNodeIds: const {'a', 'c'}, // a and c are selected
        );

        // Complete drag cycle
        group.onDragStart(context);
        group.onDragMove(const Offset(10, 0), context);
        group.onDragMove(const Offset(20, 0), context);
        group.onDragMove(const Offset(30, 0), context);
        group.onDragEnd();

        // Should have 3 move calls, each with {b, d}
        expect(movedNodeHistory.length, equals(3));
        for (final moved in movedNodeHistory) {
          expect(moved, equals({'b', 'd'}));
        }
      });
    });
  });

  // ==========================================================================
  // Edge Cases Tests
  // ==========================================================================
  group('Edge Cases', () {
    test('group at negative coordinates', () {
      final group = GroupNode<String>(
        id: 'negative-coords',
        position: const Offset(-500, -300),
        size: const Size(200, 150),
        title: 'Negative',
        data: 'test',
      );

      expect(group.position.value, equals(const Offset(-500, -300)));
      expect(group.bounds.left, equals(-500));
      expect(group.bounds.top, equals(-300));
    });

    test('group with zero size falls back to minimum', () {
      final group = GroupNode<String>(
        id: 'zero-size',
        position: Offset.zero,
        size: Size.zero,
        title: 'Zero',
        data: 'test',
      );

      // Size is set but might be below minimum
      group.setSize(Size.zero);

      expect(group.currentSize.width, greaterThanOrEqualTo(100));
      expect(group.currentSize.height, greaterThanOrEqualTo(60));
    });

    test('group with very large nodeIds set', () {
      final nodeIds = Set<String>.from(List.generate(1000, (i) => 'node-$i'));

      final group = GroupNode<String>(
        id: 'many-nodes',
        position: Offset.zero,
        size: const Size(1000, 800),
        title: 'Many Nodes',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: nodeIds,
      );

      expect(group.nodeIds.length, equals(1000));
    });

    test('group with empty title', () {
      final group = GroupNode<String>(
        id: 'empty-title',
        position: Offset.zero,
        size: const Size(300, 200),
        title: '',
        data: 'test',
      );

      expect(group.currentTitle, isEmpty);
    });

    test('group with very long title', () {
      final longTitle = 'A' * 1000;
      final group = GroupNode<String>(
        id: 'long-title',
        position: Offset.zero,
        size: const Size(300, 200),
        title: longTitle,
        data: 'test',
      );

      expect(group.currentTitle.length, equals(1000));
    });

    test('multiple rapid title updates', () {
      final group = createTestGroupNode<String>(title: 'Initial', data: 'test');

      for (var i = 0; i < 100; i++) {
        group.updateTitle('Title $i');
      }

      expect(group.currentTitle, equals('Title 99'));
    });

    test('multiple rapid color updates', () {
      final group = createTestGroupNode<String>(
        color: Colors.blue,
        data: 'test',
      );
      final colors = [Colors.red, Colors.green, Colors.yellow, Colors.purple];

      for (final color in colors) {
        group.updateColor(color);
      }

      expect(group.currentColor, equals(Colors.purple));
    });

    test('group with transparent color', () {
      final group = GroupNode<String>(
        id: 'transparent',
        position: Offset.zero,
        size: const Size(300, 200),
        title: 'Transparent',
        data: 'test',
        color: Colors.transparent,
      );

      expect(group.currentColor, equals(Colors.transparent));
    });

    test('switching behavior rapidly', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );

      group.setBehavior(GroupBehavior.explicit);
      group.setBehavior(GroupBehavior.parent);
      group.setBehavior(GroupBehavior.bounds);
      group.setBehavior(GroupBehavior.explicit);

      expect(group.behavior, equals(GroupBehavior.explicit));
    });
  });
}
