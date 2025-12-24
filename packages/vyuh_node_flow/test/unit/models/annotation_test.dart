/// Unit tests for the Annotation data models.
///
/// Tests cover:
/// - StickyAnnotation: Creation, properties, observables, resizing, JSON serialization
/// - GroupAnnotation: Creation, properties, node management, behaviors, JSON serialization
/// - MarkerAnnotation: Creation, properties, marker types, JSON serialization
/// - Base Annotation: Common properties and behaviors
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
  // Annotation Base Tests
  // ===========================================================================

  group('Annotation Base', () {
    test('AnnotationRenderLayer has correct values', () {
      expect(AnnotationRenderLayer.values.length, equals(2));
      expect(AnnotationRenderLayer.background.index, equals(0));
      expect(AnnotationRenderLayer.foreground.index, equals(1));
    });
  });

  // ===========================================================================
  // StickyAnnotation Tests
  // ===========================================================================

  group('StickyAnnotation Creation', () {
    test('creates sticky with required fields', () {
      final sticky = StickyAnnotation(
        id: 'sticky-1',
        position: const Offset(100, 200),
        text: 'My note',
      );

      expect(sticky.id, equals('sticky-1'));
      expect(sticky.position, equals(const Offset(100, 200)));
      expect(sticky.text, equals('My note'));
      expect(sticky.type, equals('sticky'));
    });

    test('creates sticky with default width of 200', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.width, equals(200.0));
    });

    test('creates sticky with default height of 100', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.height, equals(100.0));
    });

    test('creates sticky with default color of yellow', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.color, equals(Colors.yellow));
    });

    test('creates sticky with custom dimensions', () {
      final sticky = createTestStickyAnnotation(width: 300, height: 150);

      expect(sticky.width, equals(300.0));
      expect(sticky.height, equals(150.0));
    });

    test('creates sticky with custom color', () {
      final sticky = createTestStickyAnnotation(color: Colors.pink);

      expect(sticky.color, equals(Colors.pink));
    });

    test('creates sticky with default zIndex of 0', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.zIndex, equals(0));
    });

    test('creates sticky with default visibility of true', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.isVisible, isTrue);
    });

    test('creates sticky with default interactivity of true', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.isInteractive, isTrue);
    });

    test('sticky is in foreground layer', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.layer, equals(AnnotationRenderLayer.foreground));
    });

    test('sticky is resizable', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.isResizable, isTrue);
    });
  });

  group('StickyAnnotation Observable Properties', () {
    test('text is observable and updates correctly', () {
      final sticky = createTestStickyAnnotation(text: 'Original');

      expect(sticky.text, equals('Original'));

      sticky.text = 'Updated';

      expect(sticky.text, equals('Updated'));
    });

    test('width is observable and updates correctly', () {
      final sticky = createTestStickyAnnotation(width: 200);

      expect(sticky.width, equals(200));

      sticky.width = 250;

      expect(sticky.width, equals(250));
    });

    test('height is observable and updates correctly', () {
      final sticky = createTestStickyAnnotation(height: 100);

      expect(sticky.height, equals(100));

      sticky.height = 150;

      expect(sticky.height, equals(150));
    });

    test('position is observable and updates correctly', () {
      final sticky = createTestStickyAnnotation(position: const Offset(0, 0));

      expect(sticky.position, equals(const Offset(0, 0)));

      sticky.position = const Offset(100, 200);

      expect(sticky.position, equals(const Offset(100, 200)));
    });

    test('visualPosition is observable and updates correctly', () {
      final sticky = createTestStickyAnnotation();

      sticky.visualPosition = const Offset(50, 75);

      expect(sticky.visualPosition, equals(const Offset(50, 75)));
    });

    test('zIndex is observable and updates correctly', () {
      final sticky = createTestStickyAnnotation(zIndex: 0);

      expect(sticky.zIndex, equals(0));

      sticky.zIndex = 5;

      expect(sticky.zIndex, equals(5));
    });

    test('isVisible is observable and updates correctly', () {
      final sticky = createTestStickyAnnotation(isVisible: true);

      expect(sticky.isVisible, isTrue);

      sticky.isVisible = false;

      expect(sticky.isVisible, isFalse);
    });

    test('selected is observable and updates correctly', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.selected, isFalse);

      sticky.selected = true;

      expect(sticky.selected, isTrue);
    });

    test('isEditing is observable and updates correctly', () {
      final sticky = createTestStickyAnnotation();

      expect(sticky.isEditing, isFalse);

      sticky.isEditing = true;

      expect(sticky.isEditing, isTrue);
    });
  });

  group('StickyAnnotation Size', () {
    test('size returns correct dimensions', () {
      final sticky = createTestStickyAnnotation(width: 200, height: 100);

      expect(sticky.size, equals(const Size(200, 100)));
    });

    test('setSize updates dimensions', () {
      final sticky = createTestStickyAnnotation(width: 200, height: 100);

      sticky.setSize(const Size(300, 150));

      expect(sticky.width, equals(300));
      expect(sticky.height, equals(150));
    });

    test('setSize clamps to minimum width', () {
      final sticky = createTestStickyAnnotation();

      sticky.setSize(const Size(50, 100)); // Below minWidth

      expect(sticky.width, equals(StickyAnnotation.minWidth));
    });

    test('setSize clamps to minimum height', () {
      final sticky = createTestStickyAnnotation();

      sticky.setSize(const Size(200, 30)); // Below minHeight

      expect(sticky.height, equals(StickyAnnotation.minHeight));
    });

    test('setSize clamps to maximum width', () {
      final sticky = createTestStickyAnnotation();

      sticky.setSize(const Size(1000, 100)); // Above maxWidth

      expect(sticky.width, equals(StickyAnnotation.maxWidth));
    });

    test('setSize clamps to maximum height', () {
      final sticky = createTestStickyAnnotation();

      sticky.setSize(const Size(200, 500)); // Above maxHeight

      expect(sticky.height, equals(StickyAnnotation.maxHeight));
    });
  });

  group('StickyAnnotation Bounds', () {
    test('bounds returns correct rectangle', () {
      final sticky = createTestStickyAnnotation(
        position: const Offset(100, 200),
        width: 200,
        height: 100,
      );
      sticky.visualPosition = const Offset(100, 200);

      expect(sticky.bounds, equals(const Rect.fromLTWH(100, 200, 200, 100)));
    });

    test('containsPoint returns true for point inside', () {
      final sticky = createTestStickyAnnotation(
        position: const Offset(0, 0),
        width: 100,
        height: 100,
      );
      sticky.visualPosition = const Offset(0, 0);

      expect(sticky.containsPoint(const Offset(50, 50)), isTrue);
    });

    test('containsPoint returns false for point outside', () {
      final sticky = createTestStickyAnnotation(
        position: const Offset(0, 0),
        width: 100,
        height: 100,
      );
      sticky.visualPosition = const Offset(0, 0);

      expect(sticky.containsPoint(const Offset(150, 150)), isFalse);
    });
  });

  group('StickyAnnotation copyWith', () {
    test('copyWith creates copy with same values', () {
      final original = createTestStickyAnnotation(
        id: 'original',
        position: const Offset(100, 200),
        text: 'Original text',
        width: 250,
        height: 120,
        color: Colors.pink,
        zIndex: 5,
      );

      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.position, equals(original.position));
      expect(copy.text, equals(original.text));
      expect(copy.width, equals(original.width));
      expect(copy.height, equals(original.height));
      expect(copy.color, equals(original.color));
      expect(copy.zIndex, equals(original.zIndex));
    });

    test('copyWith changes specified properties', () {
      final original = createTestStickyAnnotation(text: 'Original');

      final modified = original.copyWith(text: 'Modified', width: 300);

      expect(modified.text, equals('Modified'));
      expect(modified.width, equals(300));
      expect(modified.height, equals(original.height)); // Unchanged
    });
  });

  group('StickyAnnotation JSON Serialization', () {
    test('toJson produces valid JSON', () {
      final sticky = createTestStickyAnnotation(
        id: 'sticky-json',
        position: const Offset(100, 200),
        text: 'JSON test',
        width: 250,
        height: 120,
        zIndex: 5,
      );

      final json = sticky.toJson();

      expect(json['id'], equals('sticky-json'));
      expect(json['type'], equals('sticky'));
      expect(json['x'], equals(100.0));
      expect(json['y'], equals(200.0));
      expect(json['text'], equals('JSON test'));
      expect(json['width'], equals(250.0));
      expect(json['height'], equals(120.0));
      expect(json['zIndex'], equals(5));
    });

    test('fromJsonMap reconstructs sticky correctly', () {
      final original = createTestStickyAnnotation(
        id: 'reconstructed',
        position: const Offset(50, 75),
        text: 'Restored text',
        width: 180,
        height: 90,
        zIndex: 3,
      );

      final json = original.toJson();
      final restored = StickyAnnotation.fromJsonMap(json);

      expect(restored.id, equals('reconstructed'));
      expect(restored.position.dx, equals(50.0));
      expect(restored.position.dy, equals(75.0));
      expect(restored.text, equals('Restored text'));
      expect(restored.width, equals(180));
      expect(restored.height, equals(90));
      expect(restored.zIndex, equals(3));
    });

    test('round-trip serialization preserves all properties', () {
      final original = createTestStickyAnnotation(
        id: 'round-trip',
        position: const Offset(150, 250),
        text: 'Round trip text',
        width: 220,
        height: 130,
        color: Colors.orange,
        zIndex: 7,
        isVisible: true,
      );

      final json = original.toJson();
      final restored = StickyAnnotation.fromJsonMap(json);

      expect(restored.id, equals(original.id));
      expect(restored.text, equals(original.text));
      expect(restored.width, equals(original.width));
      expect(restored.height, equals(original.height));
      expect(restored.color.toARGB32(), equals(original.color.toARGB32()));
      expect(restored.zIndex, equals(original.zIndex));
      expect(restored.isVisible, equals(original.isVisible));
    });
  });

  // ===========================================================================
  // GroupAnnotation Tests
  // ===========================================================================

  group('GroupAnnotation Creation', () {
    test('creates group with required fields', () {
      final group = GroupAnnotation(
        id: 'group-1',
        position: const Offset(100, 200),
        size: const Size(400, 300),
        title: 'My Group',
      );

      expect(group.id, equals('group-1'));
      expect(group.position, equals(const Offset(100, 200)));
      expect(group.size, equals(const Size(400, 300)));
      expect(group.currentTitle, equals('My Group'));
      expect(group.type, equals('group'));
    });

    test('creates group with default behavior of bounds', () {
      final group = createTestGroupAnnotation();

      expect(group.behavior, equals(GroupBehavior.bounds));
    });

    test('creates group with default color of blue', () {
      final group = createTestGroupAnnotation();

      expect(group.currentColor, equals(Colors.blue));
    });

    test('creates group with default zIndex of -1', () {
      final group = createTestGroupAnnotation();

      expect(group.zIndex, equals(-1));
    });

    test('creates group with explicit node IDs', () {
      final group = createTestGroupAnnotation(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
      );

      expect(group.nodeIds, contains('node-1'));
      expect(group.nodeIds, contains('node-2'));
    });

    test('group is in background layer', () {
      final group = createTestGroupAnnotation();

      expect(group.layer, equals(AnnotationRenderLayer.background));
    });

    test('group is resizable for bounds behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.bounds);

      expect(group.isResizable, isTrue);
    });

    test('group is resizable for parent behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.parent);

      expect(group.isResizable, isTrue);
    });

    test('group is not resizable for explicit behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.explicit);

      expect(group.isResizable, isFalse);
    });
  });

  group('GroupAnnotation Observable Properties', () {
    test('title is observable via updateTitle', () {
      final group = createTestGroupAnnotation(title: 'Original');

      expect(group.currentTitle, equals('Original'));

      group.updateTitle('Updated');

      expect(group.currentTitle, equals('Updated'));
    });

    test('color is observable via updateColor', () {
      final group = createTestGroupAnnotation(color: Colors.blue);

      expect(group.currentColor, equals(Colors.blue));

      group.updateColor(Colors.green);

      expect(group.currentColor, equals(Colors.green));
    });

    test('observableTitle can be accessed', () {
      final group = createTestGroupAnnotation(title: 'Observable test');

      expect(group.observableTitle.value, equals('Observable test'));
    });

    test('observableColor can be accessed', () {
      final group = createTestGroupAnnotation(color: Colors.red);

      expect(group.observableColor.value, equals(Colors.red));
    });

    test('observableSize can be accessed', () {
      final group = createTestGroupAnnotation(size: const Size(500, 400));

      expect(group.observableSize.value, equals(const Size(500, 400)));
    });
  });

  group('GroupAnnotation Node Management', () {
    test('addNode adds node to membership', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.explicit);

      group.addNode('node-1');

      expect(group.nodeIds, contains('node-1'));
    });

    test('removeNode removes node from membership', () {
      final group = createTestGroupAnnotation(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
      );

      group.removeNode('node-1');

      expect(group.nodeIds, isNot(contains('node-1')));
      expect(group.nodeIds, contains('node-2'));
    });

    test('clearNodes removes all nodes', () {
      final group = createTestGroupAnnotation(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2', 'node-3'},
      );

      group.clearNodes();

      expect(group.nodeIds, isEmpty);
    });

    test('hasNode returns true for member node', () {
      final group = createTestGroupAnnotation(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1'},
      );

      expect(group.hasNode('node-1'), isTrue);
      expect(group.hasNode('node-2'), isFalse);
    });

    test('isEmpty returns true when explicit group has no nodes', () {
      final group = createTestGroupAnnotation(
        behavior: GroupBehavior.explicit,
        nodeIds: {},
      );

      expect(group.isEmpty, isTrue);
    });

    test('isEmpty returns false when explicit group has nodes', () {
      final group = createTestGroupAnnotation(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1'},
      );

      expect(group.isEmpty, isFalse);
    });

    test('isEmpty returns false for bounds behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.bounds);

      expect(group.isEmpty, isFalse);
    });

    test('shouldRemoveWhenEmpty is true for explicit behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.explicit);

      expect(group.shouldRemoveWhenEmpty, isTrue);
    });

    test('shouldRemoveWhenEmpty is false for bounds behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.bounds);

      expect(group.shouldRemoveWhenEmpty, isFalse);
    });

    test('shouldRemoveWhenEmpty is false for parent behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.parent);

      expect(group.shouldRemoveWhenEmpty, isFalse);
    });
  });

  group('GroupAnnotation Behaviors', () {
    test('GroupBehavior has correct values', () {
      expect(GroupBehavior.values.length, equals(3));
      expect(GroupBehavior.bounds.index, equals(0));
      expect(GroupBehavior.explicit.index, equals(1));
      expect(GroupBehavior.parent.index, equals(2));
    });

    test('monitorNodes is false for bounds behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.bounds);

      expect(group.monitorNodes, isFalse);
    });

    test('monitorNodes is true for explicit behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.explicit);

      expect(group.monitorNodes, isTrue);
    });

    test('monitorNodes is true for parent behavior', () {
      final group = createTestGroupAnnotation(behavior: GroupBehavior.parent);

      expect(group.monitorNodes, isTrue);
    });

    test('monitoredNodeIds returns nodeIds for explicit behavior', () {
      final group = createTestGroupAnnotation(
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
      );

      expect(group.monitoredNodeIds, contains('node-1'));
      expect(group.monitoredNodeIds, contains('node-2'));
    });

    test('monitoredNodeIds returns empty for bounds behavior', () {
      final group = createTestGroupAnnotation(
        behavior: GroupBehavior.bounds,
        nodeIds: {'node-1'}, // This should be ignored
      );

      expect(group.monitoredNodeIds, isEmpty);
    });
  });

  group('GroupAnnotation Size', () {
    test('setSize updates dimensions', () {
      final group = createTestGroupAnnotation(size: const Size(400, 300));

      group.setSize(const Size(500, 400));

      expect(group.size, equals(const Size(500, 400)));
    });

    test('setSize enforces minimum width', () {
      final group = createTestGroupAnnotation();

      group.setSize(const Size(50, 200)); // Below minimum

      expect(group.size.width, greaterThanOrEqualTo(100));
    });

    test('setSize enforces minimum height', () {
      final group = createTestGroupAnnotation();

      group.setSize(const Size(200, 30)); // Below minimum

      expect(group.size.height, greaterThanOrEqualTo(60));
    });
  });

  group('GroupAnnotation Bounds and Hit Testing', () {
    test('bounds returns correct rectangle', () {
      final group = createTestGroupAnnotation(
        position: const Offset(100, 200),
        size: const Size(400, 300),
      );
      group.visualPosition = const Offset(100, 200);

      expect(group.bounds, equals(const Rect.fromLTWH(100, 200, 400, 300)));
    });

    test('containsRect returns true for rect inside bounds', () {
      final group = createTestGroupAnnotation(
        position: const Offset(0, 0),
        size: const Size(500, 400),
      );
      group.visualPosition = const Offset(0, 0);

      expect(group.containsRect(const Rect.fromLTWH(50, 50, 100, 100)), isTrue);
    });

    test('containsRect returns false for rect outside bounds', () {
      final group = createTestGroupAnnotation(
        position: const Offset(0, 0),
        size: const Size(500, 400),
      );
      group.visualPosition = const Offset(0, 0);

      expect(
        group.containsRect(const Rect.fromLTWH(600, 600, 100, 100)),
        isFalse,
      );
    });
  });

  group('GroupAnnotation copyWith', () {
    test('copyWith creates copy with same values', () {
      final original = createTestGroupAnnotation(
        id: 'original',
        position: const Offset(100, 200),
        size: const Size(400, 300),
        title: 'Original Title',
        color: Colors.green,
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1'},
      );

      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.position, equals(original.position));
      expect(copy.size, equals(original.size));
      expect(copy.currentTitle, equals(original.currentTitle));
      expect(copy.currentColor, equals(original.currentColor));
      expect(copy.behavior, equals(original.behavior));
      expect(copy.nodeIds, equals(original.nodeIds));
    });

    test('copyWith changes specified properties', () {
      final original = createTestGroupAnnotation(title: 'Original');

      final modified = original.copyWith(
        title: 'Modified',
        size: const Size(600, 500),
      );

      expect(modified.currentTitle, equals('Modified'));
      expect(modified.size, equals(const Size(600, 500)));
    });
  });

  group('GroupAnnotation JSON Serialization', () {
    test('toJson produces valid JSON', () {
      final group = createTestGroupAnnotation(
        id: 'group-json',
        position: const Offset(100, 200),
        size: const Size(400, 300),
        title: 'JSON Group',
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
        zIndex: -2,
      );

      final json = group.toJson();

      expect(json['id'], equals('group-json'));
      expect(json['type'], equals('group'));
      expect(json['x'], equals(100.0));
      expect(json['y'], equals(200.0));
      expect(json['width'], equals(400.0));
      expect(json['height'], equals(300.0));
      expect(json['title'], equals('JSON Group'));
      expect(json['behavior'], equals('explicit'));
      expect((json['nodeIds'] as List), containsAll(['node-1', 'node-2']));
      expect(json['zIndex'], equals(-2));
    });

    test('fromJsonMap reconstructs group correctly', () {
      final original = createTestGroupAnnotation(
        id: 'reconstructed',
        position: const Offset(50, 75),
        size: const Size(350, 250),
        title: 'Restored Group',
        behavior: GroupBehavior.parent,
        nodeIds: {'node-a'},
        zIndex: -3,
      );

      final json = original.toJson();
      final restored = GroupAnnotation.fromJsonMap(json);

      expect(restored.id, equals('reconstructed'));
      expect(restored.position.dx, equals(50.0));
      expect(restored.position.dy, equals(75.0));
      expect(restored.size.width, equals(350.0));
      expect(restored.size.height, equals(250.0));
      expect(restored.currentTitle, equals('Restored Group'));
      expect(restored.behavior, equals(GroupBehavior.parent));
      expect(restored.nodeIds, contains('node-a'));
      expect(restored.zIndex, equals(-3));
    });

    test('round-trip serialization preserves all properties', () {
      final original = createTestGroupAnnotation(
        id: 'round-trip',
        position: const Offset(150, 250),
        size: const Size(450, 350),
        title: 'Round Trip Group',
        color: Colors.purple,
        behavior: GroupBehavior.explicit,
        nodeIds: {'n1', 'n2', 'n3'},
        zIndex: -1,
        isVisible: true,
      );

      final json = original.toJson();
      final restored = GroupAnnotation.fromJsonMap(json);

      expect(restored.id, equals(original.id));
      expect(restored.currentTitle, equals(original.currentTitle));
      expect(restored.size, equals(original.size));
      expect(
        restored.currentColor.toARGB32(),
        equals(original.currentColor.toARGB32()),
      );
      expect(restored.behavior, equals(original.behavior));
      expect(restored.nodeIds.length, equals(original.nodeIds.length));
      expect(restored.zIndex, equals(original.zIndex));
    });
  });

  // ===========================================================================
  // MarkerAnnotation Tests
  // ===========================================================================

  group('MarkerAnnotation Creation', () {
    test('creates marker with required fields', () {
      final marker = MarkerAnnotation(
        id: 'marker-1',
        position: const Offset(100, 200),
      );

      expect(marker.id, equals('marker-1'));
      expect(marker.position, equals(const Offset(100, 200)));
      expect(marker.type, equals('marker'));
    });

    test('creates marker with default markerType of info', () {
      final marker = createTestMarkerAnnotation();

      expect(marker.markerType, equals(MarkerType.info));
    });

    test('creates marker with default size of 24', () {
      final marker = createTestMarkerAnnotation();

      expect(marker.markerSize, equals(24.0));
    });

    test('creates marker with default color of red', () {
      final marker = createTestMarkerAnnotation();

      expect(marker.color, equals(Colors.red));
    });

    test('creates marker with custom marker type', () {
      final marker = createTestMarkerAnnotation(markerType: MarkerType.error);

      expect(marker.markerType, equals(MarkerType.error));
    });

    test('creates marker with tooltip', () {
      final marker = createTestMarkerAnnotation(tooltip: 'Error occurred');

      expect(marker.tooltip, equals('Error occurred'));
    });

    test('creates marker with null tooltip by default', () {
      final marker = createTestMarkerAnnotation();

      expect(marker.tooltip, isNull);
    });

    test('marker is in foreground layer', () {
      final marker = createTestMarkerAnnotation();

      expect(marker.layer, equals(AnnotationRenderLayer.foreground));
    });

    test('marker is not resizable', () {
      final marker = createTestMarkerAnnotation();

      expect(marker.isResizable, isFalse);
    });
  });

  group('MarkerType Values', () {
    test('MarkerType has all expected values', () {
      expect(MarkerType.values.length, equals(14));
      expect(MarkerType.error.name, equals('error'));
      expect(MarkerType.warning.name, equals('warning'));
      expect(MarkerType.info.name, equals('info'));
      expect(MarkerType.timer.name, equals('timer'));
      expect(MarkerType.message.name, equals('message'));
      expect(MarkerType.user.name, equals('user'));
      expect(MarkerType.script.name, equals('script'));
      expect(MarkerType.service.name, equals('service'));
      expect(MarkerType.manual.name, equals('manual'));
      expect(MarkerType.decision.name, equals('decision'));
      expect(MarkerType.subprocess.name, equals('subprocess'));
      expect(MarkerType.milestone.name, equals('milestone'));
      expect(MarkerType.risk.name, equals('risk'));
      expect(MarkerType.compliance.name, equals('compliance'));
    });

    test('MarkerType has iconData', () {
      expect(MarkerType.error.iconData, isNotNull);
      expect(MarkerType.warning.iconData, isNotNull);
      expect(MarkerType.info.iconData, isNotNull);
    });

    test('MarkerType has labels', () {
      expect(MarkerType.error.label, equals('Error'));
      expect(MarkerType.warning.label, equals('Warning'));
      expect(MarkerType.info.label, equals('Information'));
      expect(MarkerType.milestone.label, equals('Milestone'));
    });
  });

  group('MarkerAnnotation Size and Bounds', () {
    test('size returns square based on markerSize', () {
      final marker = createTestMarkerAnnotation(markerSize: 32);

      expect(marker.size, equals(const Size(32, 32)));
    });

    test('bounds returns correct rectangle', () {
      final marker = createTestMarkerAnnotation(
        position: const Offset(100, 200),
        markerSize: 24,
      );
      marker.visualPosition = const Offset(100, 200);

      expect(marker.bounds, equals(const Rect.fromLTWH(100, 200, 24, 24)));
    });

    test('containsPoint returns true for point inside', () {
      final marker = createTestMarkerAnnotation(
        position: const Offset(0, 0),
        markerSize: 24,
      );
      marker.visualPosition = const Offset(0, 0);

      expect(marker.containsPoint(const Offset(12, 12)), isTrue);
    });

    test('containsPoint returns false for point outside', () {
      final marker = createTestMarkerAnnotation(
        position: const Offset(0, 0),
        markerSize: 24,
      );
      marker.visualPosition = const Offset(0, 0);

      expect(marker.containsPoint(const Offset(50, 50)), isFalse);
    });
  });

  group('MarkerAnnotation copyWith', () {
    test('copyWith creates copy with same values', () {
      final original = createTestMarkerAnnotation(
        id: 'original',
        position: const Offset(100, 200),
        markerType: MarkerType.error,
        markerSize: 32,
        color: Colors.orange,
        tooltip: 'Original tooltip',
      );

      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.position, equals(original.position));
      expect(copy.markerType, equals(original.markerType));
      expect(copy.markerSize, equals(original.markerSize));
      expect(copy.color, equals(original.color));
      expect(copy.tooltip, equals(original.tooltip));
    });

    test('copyWith changes specified properties', () {
      final original = createTestMarkerAnnotation(markerType: MarkerType.info);

      final modified = original.copyWith(
        markerType: MarkerType.warning,
        color: Colors.amber,
      );

      expect(modified.markerType, equals(MarkerType.warning));
      expect(modified.color, equals(Colors.amber));
    });
  });

  group('MarkerAnnotation JSON Serialization', () {
    test('toJson produces valid JSON', () {
      final marker = createTestMarkerAnnotation(
        id: 'marker-json',
        position: const Offset(100, 200),
        markerType: MarkerType.error,
        markerSize: 28,
        tooltip: 'Test tooltip',
        zIndex: 5,
      );

      final json = marker.toJson();

      expect(json['id'], equals('marker-json'));
      expect(json['type'], equals('marker'));
      expect(json['x'], equals(100.0));
      expect(json['y'], equals(200.0));
      expect(json['markerType'], equals('error'));
      expect(json['markerSize'], equals(28.0));
      expect(json['tooltip'], equals('Test tooltip'));
      expect(json['zIndex'], equals(5));
    });

    test('fromJsonMap reconstructs marker correctly', () {
      final original = createTestMarkerAnnotation(
        id: 'reconstructed',
        position: const Offset(50, 75),
        markerType: MarkerType.warning,
        markerSize: 30,
        tooltip: 'Restored tooltip',
        zIndex: 3,
      );

      final json = original.toJson();
      final restored = MarkerAnnotation.fromJsonMap(json);

      expect(restored.id, equals('reconstructed'));
      expect(restored.position.dx, equals(50.0));
      expect(restored.position.dy, equals(75.0));
      expect(restored.markerType, equals(MarkerType.warning));
      expect(restored.markerSize, equals(30));
      expect(restored.tooltip, equals('Restored tooltip'));
      expect(restored.zIndex, equals(3));
    });

    test('round-trip serialization preserves all properties', () {
      final original = createTestMarkerAnnotation(
        id: 'round-trip',
        position: const Offset(150, 250),
        markerType: MarkerType.milestone,
        markerSize: 36,
        color: Colors.teal,
        tooltip: 'Round trip test',
        zIndex: 7,
        isVisible: true,
      );

      final json = original.toJson();
      final restored = MarkerAnnotation.fromJsonMap(json);

      expect(restored.id, equals(original.id));
      expect(restored.markerType, equals(original.markerType));
      expect(restored.markerSize, equals(original.markerSize));
      expect(restored.color.toARGB32(), equals(original.color.toARGB32()));
      expect(restored.tooltip, equals(original.tooltip));
      expect(restored.zIndex, equals(original.zIndex));
      expect(restored.isVisible, equals(original.isVisible));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('sticky with empty text', () {
      final sticky = createTestStickyAnnotation(text: '');

      expect(sticky.text, isEmpty);
    });

    test('sticky with very long text', () {
      final longText = 'A' * 10000;
      final sticky = createTestStickyAnnotation(text: longText);

      expect(sticky.text.length, equals(10000));
    });

    test('group with many node IDs', () {
      final nodeIds = List.generate(100, (i) => 'node-$i').toSet();
      final group = createTestGroupAnnotation(
        behavior: GroupBehavior.explicit,
        nodeIds: nodeIds,
      );

      expect(group.nodeIds.length, equals(100));
    });

    test('marker at origin position', () {
      final marker = createTestMarkerAnnotation(position: Offset.zero);

      expect(marker.position, equals(Offset.zero));
    });

    test('marker at negative position', () {
      final marker = createTestMarkerAnnotation(
        position: const Offset(-100, -200),
      );

      expect(marker.position, equals(const Offset(-100, -200)));
    });

    test('group with custom padding', () {
      final group = createTestGroupAnnotation(
        padding: const EdgeInsets.all(50),
      );

      expect(group.padding, equals(const EdgeInsets.all(50)));
    });
  });
}
