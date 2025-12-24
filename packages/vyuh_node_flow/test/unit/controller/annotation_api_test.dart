/// Unit tests for the NodeFlowController Annotation API.
///
/// Tests cover:
/// - Annotation CRUD operations (add, remove, get)
/// - Factory methods (createStickyAnnotation, createGroupAnnotation, etc.)
/// - Selection operations (select, clear, toggle)
/// - Visibility operations (show, hide)
/// - Z-index management (bringToFront, sendToBack, etc.)
/// - Bulk operations (delete selected, move selected)
/// - Group containment (findIntersectingGroup, findContainedNodes)
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Annotation CRUD Operations
  // ===========================================================================

  group('Annotation CRUD Operations', () {
    test('addAnnotation adds annotation to controller', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');

      controller.annotations.addAnnotation(annotation);

      expect(controller.annotations.annotations, contains('sticky-1'));
      expect(controller.annotations.annotations.length, equals(1));
    });

    test('addAnnotation makes annotation accessible via getAnnotation', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');

      controller.annotations.addAnnotation(annotation);

      final retrieved = controller.annotations.getAnnotation('sticky-1');
      expect(retrieved, equals(annotation));
    });

    test('removeAnnotation removes annotation from controller', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');
      controller.annotations.addAnnotation(annotation);

      controller.annotations.removeAnnotation('sticky-1');

      expect(controller.annotations.annotations, isNot(contains('sticky-1')));
      expect(controller.annotations.getAnnotation('sticky-1'), isNull);
    });

    test('removeAnnotation removes annotation from selection', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');
      controller.annotations.addAnnotation(annotation);
      controller.annotations.selectAnnotation('sticky-1');

      controller.annotations.removeAnnotation('sticky-1');

      expect(controller.annotations.selectedAnnotationIds, isEmpty);
    });

    test('getAnnotation returns null for non-existent annotation', () {
      final controller = createTestController();

      expect(controller.annotations.getAnnotation('non-existent'), isNull);
    });

    test('updateAnnotation replaces annotation with same ID', () {
      final controller = createTestController();
      final original = createTestStickyAnnotation(
        id: 'sticky-1',
        text: 'Original',
      );
      final updated = createTestStickyAnnotation(
        id: 'sticky-1',
        text: 'Updated',
      );
      controller.annotations.addAnnotation(original);

      controller.annotations.updateAnnotation('sticky-1', updated);

      final retrieved =
          controller.annotations.getAnnotation('sticky-1') as StickyAnnotation;
      expect(retrieved.text, equals('Updated'));
    });
  });

  // ===========================================================================
  // Factory Methods
  // ===========================================================================

  group('Factory Methods', () {
    test('createStickyAnnotation creates sticky with correct properties', () {
      final controller = createTestController();

      final sticky = controller.annotations.createStickyAnnotation(
        id: 'sticky-1',
        position: const Offset(100, 100),
        text: 'Test note',
        width: 300,
        height: 150,
        color: Colors.orange,
      );

      expect(sticky.id, equals('sticky-1'));
      expect(sticky.position, equals(const Offset(100, 100)));
      expect(sticky.text, equals('Test note'));
      expect(sticky.size.width, equals(300));
      expect(sticky.size.height, equals(150));
      expect(sticky.color, equals(Colors.orange));
    });

    test('createGroupAnnotation creates group with correct properties', () {
      final controller = createTestController();

      final group = controller.annotations.createGroupAnnotation(
        id: 'group-1',
        title: 'Test Group',
        position: const Offset(50, 50),
        size: const Size(400, 300),
        color: Colors.green,
      );

      expect(group.id, equals('group-1'));
      expect(group.currentTitle, equals('Test Group'));
      expect(group.position, equals(const Offset(50, 50)));
      expect(group.size.width, equals(400));
      expect(group.size.height, equals(300));
      expect(group.currentColor, equals(Colors.green));
    });

    test('createGroupAnnotationAroundNodes encompasses nodes', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 80),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(300, 200),
        size: const Size(100, 80),
      );
      final controller = createTestController(nodes: [node1, node2]);

      final group = controller.annotations.createGroupAnnotationAroundNodes(
        id: 'group-1',
        title: 'Node Group',
        nodeIds: {'node-1', 'node-2'},
        padding: const EdgeInsets.all(20),
      );

      // Group should encompass nodes with padding
      expect(group.position.dx, equals(80)); // 100 - 20 padding
      expect(group.position.dy, equals(80)); // 100 - 20 padding
      // Width: 400 - 80 = 320 (from 100 to 400, which is 300 + 100)
      expect(group.size.width, equals(340)); // (300 + 100) - (100 - 20) + 20
    });

    test('createMarkerAnnotation creates marker with correct properties', () {
      final controller = createTestController();

      final marker = controller.annotations.createMarkerAnnotation(
        id: 'marker-1',
        position: const Offset(200, 200),
        markerType: MarkerType.warning,
        size: 32,
        color: Colors.amber,
        tooltip: 'Warning message',
      );

      expect(marker.id, equals('marker-1'));
      expect(marker.position, equals(const Offset(200, 200)));
      expect(marker.markerType, equals(MarkerType.warning));
      expect(marker.markerSize, equals(32));
      expect(marker.color, equals(Colors.amber));
      expect(marker.tooltip, equals('Warning message'));
    });
  });

  // ===========================================================================
  // Selection Operations
  // ===========================================================================

  group('Selection Operations', () {
    test('selectAnnotation selects annotation', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');
      controller.annotations.addAnnotation(annotation);

      controller.annotations.selectAnnotation('sticky-1');

      expect(controller.annotations.isAnnotationSelected('sticky-1'), isTrue);
      expect(
        controller.annotations.selectedAnnotationIds,
        contains('sticky-1'),
      );
    });

    test('selectAnnotation clears previous selection by default', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(id: 'sticky-1');
      final annotation2 = createTestStickyAnnotation(id: 'sticky-2');
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.selectAnnotation('sticky-1');

      controller.annotations.selectAnnotation('sticky-2');

      expect(controller.annotations.isAnnotationSelected('sticky-1'), isFalse);
      expect(controller.annotations.isAnnotationSelected('sticky-2'), isTrue);
    });

    test('selectAnnotation with toggle adds to selection', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(id: 'sticky-1');
      final annotation2 = createTestStickyAnnotation(id: 'sticky-2');
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.selectAnnotation('sticky-1');

      controller.annotations.selectAnnotation('sticky-2', toggle: true);

      expect(controller.annotations.isAnnotationSelected('sticky-1'), isTrue);
      expect(controller.annotations.isAnnotationSelected('sticky-2'), isTrue);
    });

    test('selectAnnotation with toggle removes if already selected', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');
      controller.annotations.addAnnotation(annotation);
      controller.annotations.selectAnnotation('sticky-1');

      controller.annotations.selectAnnotation('sticky-1', toggle: true);

      expect(controller.annotations.isAnnotationSelected('sticky-1'), isFalse);
    });

    test('clearAnnotationSelection clears all selections', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(id: 'sticky-1');
      final annotation2 = createTestStickyAnnotation(id: 'sticky-2');
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.selectAnnotation('sticky-1');
      controller.annotations.selectAnnotation('sticky-2', toggle: true);

      controller.annotations.clearAnnotationSelection();

      expect(controller.annotations.selectedAnnotationIds, isEmpty);
      expect(controller.annotations.hasAnnotationSelection, isFalse);
    });

    test('isAnnotationSelected returns false for unselected annotation', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');
      controller.annotations.addAnnotation(annotation);

      expect(controller.annotations.isAnnotationSelected('sticky-1'), isFalse);
    });

    test('selectedAnnotation returns single selected annotation', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');
      controller.annotations.addAnnotation(annotation);
      controller.annotations.selectAnnotation('sticky-1');

      expect(controller.annotations.selectedAnnotation, equals(annotation));
    });

    test('selectedAnnotation returns null when multiple selected', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(id: 'sticky-1');
      final annotation2 = createTestStickyAnnotation(id: 'sticky-2');
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.selectAnnotation('sticky-1');
      controller.annotations.selectAnnotation('sticky-2', toggle: true);

      expect(controller.annotations.selectedAnnotation, isNull);
    });

    test('hasAnnotationSelection reflects selection state', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');
      controller.annotations.addAnnotation(annotation);

      expect(controller.annotations.hasAnnotationSelection, isFalse);

      controller.annotations.selectAnnotation('sticky-1');
      expect(controller.annotations.hasAnnotationSelection, isTrue);

      controller.annotations.clearAnnotationSelection();
      expect(controller.annotations.hasAnnotationSelection, isFalse);
    });
  });

  // ===========================================================================
  // Visibility Operations
  // ===========================================================================

  group('Visibility Operations', () {
    test('setAnnotationVisibility hides annotation', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1');
      controller.annotations.addAnnotation(annotation);

      controller.annotations.setAnnotationVisibility('sticky-1', false);

      expect(annotation.isVisible, isFalse);
    });

    test('setAnnotationVisibility shows annotation', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(
        id: 'sticky-1',
        isVisible: false,
      );
      controller.annotations.addAnnotation(annotation);

      controller.annotations.setAnnotationVisibility('sticky-1', true);

      expect(annotation.isVisible, isTrue);
    });

    test('hideAllAnnotations hides all annotations', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(id: 'sticky-1');
      final annotation2 = createTestStickyAnnotation(id: 'sticky-2');
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);

      controller.annotations.hideAllAnnotations();

      expect(annotation1.isVisible, isFalse);
      expect(annotation2.isVisible, isFalse);
    });

    test('showAllAnnotations shows all annotations', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(
        id: 'sticky-1',
        isVisible: false,
      );
      final annotation2 = createTestStickyAnnotation(
        id: 'sticky-2',
        isVisible: false,
      );
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);

      controller.annotations.showAllAnnotations();

      expect(annotation1.isVisible, isTrue);
      expect(annotation2.isVisible, isTrue);
    });
  });

  // ===========================================================================
  // Z-Index Management
  // ===========================================================================

  group('Z-Index Management', () {
    test('addAnnotation auto-assigns incrementing z-index', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(
        id: 'sticky-1',
        zIndex: -1,
      );
      final annotation2 = createTestStickyAnnotation(
        id: 'sticky-2',
        zIndex: -1,
      );
      final annotation3 = createTestStickyAnnotation(
        id: 'sticky-3',
        zIndex: -1,
      );

      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.addAnnotation(annotation3);

      // First annotation gets 0, subsequent annotations increment
      expect(annotation1.zIndex, equals(0));
      expect(annotation2.zIndex, equals(1));
      expect(annotation3.zIndex, equals(2));
    });

    test('bringAnnotationToFront moves annotation to highest z-index', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(
        id: 'sticky-1',
        zIndex: -1,
      );
      final annotation2 = createTestStickyAnnotation(
        id: 'sticky-2',
        zIndex: -1,
      );
      final annotation3 = createTestStickyAnnotation(
        id: 'sticky-3',
        zIndex: -1,
      );
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.addAnnotation(annotation3);

      controller.annotations.bringAnnotationToFront('sticky-1');

      // sticky-1 should now be highest
      expect(annotation1.zIndex, greaterThan(annotation2.zIndex));
      expect(annotation1.zIndex, greaterThan(annotation3.zIndex));
    });

    test('sendAnnotationToBack moves annotation to lowest z-index', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(
        id: 'sticky-1',
        zIndex: -1,
      );
      final annotation2 = createTestStickyAnnotation(
        id: 'sticky-2',
        zIndex: -1,
      );
      final annotation3 = createTestStickyAnnotation(
        id: 'sticky-3',
        zIndex: -1,
      );
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.addAnnotation(annotation3);

      controller.annotations.sendAnnotationToBack('sticky-3');

      // sticky-3 should now be lowest
      expect(annotation3.zIndex, lessThan(annotation1.zIndex));
      expect(annotation3.zIndex, lessThan(annotation2.zIndex));
    });

    test('bringAnnotationForward swaps with next higher', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(
        id: 'sticky-1',
        zIndex: -1,
      );
      final annotation2 = createTestStickyAnnotation(
        id: 'sticky-2',
        zIndex: -1,
      );
      final annotation3 = createTestStickyAnnotation(
        id: 'sticky-3',
        zIndex: -1,
      );
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.addAnnotation(annotation3);
      // Order: sticky-1=0, sticky-2=1, sticky-3=2

      controller.annotations.bringAnnotationForward('sticky-1');

      // sticky-1 should swap with sticky-2
      expect(annotation1.zIndex, equals(1));
      expect(annotation2.zIndex, equals(0));
    });

    test('sendAnnotationBackward swaps with next lower', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(
        id: 'sticky-1',
        zIndex: -1,
      );
      final annotation2 = createTestStickyAnnotation(
        id: 'sticky-2',
        zIndex: -1,
      );
      final annotation3 = createTestStickyAnnotation(
        id: 'sticky-3',
        zIndex: -1,
      );
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.addAnnotation(annotation3);
      // Order: sticky-1=0, sticky-2=1, sticky-3=2

      controller.annotations.sendAnnotationBackward('sticky-3');

      // sticky-3 should swap with sticky-2
      expect(annotation3.zIndex, equals(1));
      expect(annotation2.zIndex, equals(2));
    });

    test('sortedAnnotations returns annotations ordered by z-index', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(
        id: 'sticky-1',
        zIndex: -1,
      );
      final annotation2 = createTestStickyAnnotation(
        id: 'sticky-2',
        zIndex: -1,
      );
      final annotation3 = createTestStickyAnnotation(
        id: 'sticky-3',
        zIndex: -1,
      );
      controller.annotations.addAnnotation(annotation3); // Will get z=0
      controller.annotations.addAnnotation(annotation1); // Will get z=1
      controller.annotations.addAnnotation(annotation2); // Will get z=2

      final sorted = controller.annotations.sortedAnnotations;

      // Should be in z-index order (ascending)
      expect(sorted[0].id, equals('sticky-3')); // z=0
      expect(sorted[1].id, equals('sticky-1')); // z=1
      expect(sorted[2].id, equals('sticky-2')); // z=2
    });
  });

  // ===========================================================================
  // Bulk Operations
  // ===========================================================================

  group('Bulk Operations', () {
    test('deleteSelectedAnnotations removes all selected', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(id: 'sticky-1');
      final annotation2 = createTestStickyAnnotation(id: 'sticky-2');
      final annotation3 = createTestStickyAnnotation(id: 'sticky-3');
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.addAnnotation(annotation3);
      controller.annotations.selectAnnotation('sticky-1');
      controller.annotations.selectAnnotation('sticky-2', toggle: true);

      controller.annotations.deleteSelectedAnnotations();

      expect(controller.annotations.annotations.length, equals(1));
      expect(controller.annotations.getAnnotation('sticky-1'), isNull);
      expect(controller.annotations.getAnnotation('sticky-2'), isNull);
      expect(controller.annotations.getAnnotation('sticky-3'), isNotNull);
    });

    test('moveSelectedAnnotations moves all selected by delta', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(
        id: 'sticky-1',
        position: const Offset(100, 100),
      );
      final annotation2 = createTestStickyAnnotation(
        id: 'sticky-2',
        position: const Offset(200, 200),
      );
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      controller.annotations.selectAnnotation('sticky-1');
      controller.annotations.selectAnnotation('sticky-2', toggle: true);

      controller.annotations.moveSelectedAnnotations(const Offset(50, 25));

      expect(annotation1.position, equals(const Offset(150, 125)));
      expect(annotation2.position, equals(const Offset(250, 225)));
    });
  });

  // ===========================================================================
  // Group Containment
  // ===========================================================================

  group('Group Containment', () {
    test('findContainedNodes finds nodes completely inside group', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(50, 50),
        size: const Size(100, 80),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(200, 200),
        size: const Size(100, 80),
      );
      final controller = createTestController(nodes: [node1, node2]);
      final group = createTestGroupAnnotation(
        id: 'group-1',
        position: const Offset(0, 0),
        size: const Size(400, 400),
      );
      controller.annotations.addAnnotation(group);

      final contained = controller.annotations.findContainedNodes(group);

      // Both nodes are within the 400x400 group
      expect(contained, contains('node-1'));
      expect(contained, contains('node-2'));
    });

    test('findContainedNodes excludes nodes outside group', () {
      final node1 = createTestNode(
        id: 'node-inside',
        position: const Offset(50, 50),
        size: const Size(100, 80),
      );
      final node2 = createTestNode(
        id: 'node-outside',
        position: const Offset(500, 500),
        size: const Size(100, 80),
      );
      final controller = createTestController(nodes: [node1, node2]);
      final group = createTestGroupAnnotation(
        id: 'group-1',
        position: const Offset(0, 0),
        size: const Size(200, 200),
      );
      controller.annotations.addAnnotation(group);

      final contained = controller.annotations.findContainedNodes(group);

      expect(contained, contains('node-inside'));
      expect(contained, isNot(contains('node-outside')));
    });

    test('findContainedNodes excludes nodes partially inside', () {
      final node = createTestNode(
        id: 'node-partial',
        position: const Offset(150, 150), // Extends past 200x200 group
        size: const Size(100, 80),
      );
      final controller = createTestController(nodes: [node]);
      final group = createTestGroupAnnotation(
        id: 'group-1',
        position: const Offset(0, 0),
        size: const Size(200, 200),
      );
      controller.annotations.addAnnotation(group);

      final contained = controller.annotations.findContainedNodes(group);

      // Node extends past the group boundary, so not contained
      expect(contained, isEmpty);
    });

    test('findIntersectingGroup finds overlapping group', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 80),
      );
      final controller = createTestController(nodes: [node]);
      final group = createTestGroupAnnotation(
        id: 'group-1',
        position: const Offset(50, 50),
        size: const Size(200, 200),
      );
      controller.annotations.addAnnotation(group);

      final intersecting = controller.annotations.findIntersectingGroup(
        'node-1',
      );

      expect(intersecting, isNotNull);
      expect(intersecting!.id, equals('group-1'));
    });

    test('findIntersectingGroup returns null when no overlap', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(500, 500),
        size: const Size(100, 80),
      );
      final controller = createTestController(nodes: [node]);
      final group = createTestGroupAnnotation(
        id: 'group-1',
        position: const Offset(0, 0),
        size: const Size(200, 200),
      );
      controller.annotations.addAnnotation(group);

      final intersecting = controller.annotations.findIntersectingGroup(
        'node-1',
      );

      expect(intersecting, isNull);
    });
  });

  // ===========================================================================
  // Editing State
  // ===========================================================================

  group('Editing State', () {
    test('clearAnnotationEditing exits edit mode for all annotations', () {
      final controller = createTestController();
      final annotation1 = createTestStickyAnnotation(id: 'sticky-1');
      final annotation2 = createTestStickyAnnotation(id: 'sticky-2');
      controller.annotations.addAnnotation(annotation1);
      controller.annotations.addAnnotation(annotation2);
      annotation1.isEditing = true;
      annotation2.isEditing = true;

      controller.annotations.clearAnnotationEditing();

      expect(annotation1.isEditing, isFalse);
      expect(annotation2.isEditing, isFalse);
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('operations on empty annotations controller do not throw', () {
      final controller = createTestController();

      // These should not throw
      expect(controller.annotations.annotations, isEmpty);
      expect(controller.annotations.selectedAnnotationIds, isEmpty);
      expect(controller.annotations.sortedAnnotations, isEmpty);
      expect(controller.annotations.getAnnotation('non-existent'), isNull);
      controller.annotations.clearAnnotationSelection();
      controller.annotations.hideAllAnnotations();
      controller.annotations.showAllAnnotations();
      controller.annotations.deleteSelectedAnnotations();
    });

    test('removeAnnotation on non-existent annotation does not throw', () {
      final controller = createTestController();

      // Should not throw
      controller.annotations.removeAnnotation('non-existent');
    });

    test('setAnnotationVisibility on non-existent annotation does nothing', () {
      final controller = createTestController();

      // Should not throw
      controller.annotations.setAnnotationVisibility('non-existent', false);
    });

    test('z-index operations on non-existent annotation do not throw', () {
      final controller = createTestController();

      // Should not throw
      controller.annotations.bringAnnotationToFront('non-existent');
      controller.annotations.sendAnnotationToBack('non-existent');
      controller.annotations.bringAnnotationForward('non-existent');
      controller.annotations.sendAnnotationBackward('non-existent');
    });

    test('selection operations on non-existent annotation', () {
      final controller = createTestController();

      // Select non-existent should add to selection set but not find annotation
      controller.annotations.selectAnnotation('non-existent');
      expect(
        controller.annotations.selectedAnnotationIds,
        contains('non-existent'),
      );
    });
  });

  // ===========================================================================
  // Preserve Z-Index on Load
  // ===========================================================================

  group('Preserve Z-Index on Load', () {
    test('addAnnotation preserves non-default z-index', () {
      final controller = createTestController();
      final annotation = createTestStickyAnnotation(id: 'sticky-1', zIndex: 5);

      controller.annotations.addAnnotation(annotation);

      // Should preserve the explicit z-index value
      expect(annotation.zIndex, equals(5));
    });

    test('addAnnotation auto-assigns only for default z-index (-1)', () {
      final controller = createTestController();
      final preserved = createTestStickyAnnotation(id: 'sticky-1', zIndex: 10);
      final autoAssigned = createTestStickyAnnotation(
        id: 'sticky-2',
        zIndex: -1,
      );

      controller.annotations.addAnnotation(preserved);
      controller.annotations.addAnnotation(autoAssigned);

      expect(preserved.zIndex, equals(10)); // Preserved
      expect(autoAssigned.zIndex, equals(11)); // Auto-assigned (max + 1)
    });
  });
}
