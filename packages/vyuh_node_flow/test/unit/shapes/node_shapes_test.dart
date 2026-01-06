/// Comprehensive tests for node shapes.
///
/// Tests all node shapes: DiamondShape, HexagonShape, CircleShape, and the
/// base NodeShape functionality.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('DiamondShape', () {
    group('Construction', () {
      test('creates with default values', () {
        const shape = DiamondShape();
        expect(shape.fillColor, isNull);
        expect(shape.strokeColor, isNull);
        expect(shape.strokeWidth, isNull);
      });

      test('creates with custom colors', () {
        const shape = DiamondShape(
          fillColor: Colors.orange,
          strokeColor: Colors.deepOrange,
          strokeWidth: 2.0,
        );
        expect(shape.fillColor, equals(Colors.orange));
        expect(shape.strokeColor, equals(Colors.deepOrange));
        expect(shape.strokeWidth, equals(2.0));
      });
    });

    group('buildPath', () {
      test('creates diamond path for square size', () {
        const shape = DiamondShape();
        final path = shape.buildPath(const Size(100, 100));

        expect(path, isNotNull);
        expect(path.getBounds(), isNotNull);
      });

      test('creates diamond path for rectangular size', () {
        const shape = DiamondShape();
        final path = shape.buildPath(const Size(200, 100));

        final bounds = path.getBounds();
        expect(bounds.width, closeTo(200, 0.01));
        expect(bounds.height, closeTo(100, 0.01));
      });

      test('diamond path has correct vertices', () {
        const shape = DiamondShape();
        final path = shape.buildPath(const Size(100, 100));

        // Check that path contains the expected points
        // Top: (50, 0), Right: (100, 50), Bottom: (50, 100), Left: (0, 50)
        expect(path.contains(const Offset(50, 1)), isTrue); // Near top
        expect(path.contains(const Offset(99, 50)), isTrue); // Near right
        expect(path.contains(const Offset(50, 99)), isTrue); // Near bottom
        expect(path.contains(const Offset(1, 50)), isTrue); // Near left
      });
    });

    group('getPortAnchors', () {
      test('returns 4 port anchors', () {
        const shape = DiamondShape();
        final anchors = shape.getPortAnchors(const Size(100, 100));

        expect(anchors, hasLength(4));
      });

      test('port anchors have correct positions', () {
        const shape = DiamondShape();
        final anchors = shape.getPortAnchors(const Size(100, 100));

        // Find anchors by position
        final topAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.top,
        );
        final rightAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.right,
        );
        final bottomAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.bottom,
        );
        final leftAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.left,
        );

        expect(topAnchor.offset, equals(const Offset(50, 0)));
        expect(rightAnchor.offset, equals(const Offset(100, 50)));
        expect(bottomAnchor.offset, equals(const Offset(50, 100)));
        expect(leftAnchor.offset, equals(const Offset(0, 50)));
      });

      test('port anchors have correct normals', () {
        const shape = DiamondShape();
        final anchors = shape.getPortAnchors(const Size(100, 100));

        final topAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.top,
        );
        final rightAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.right,
        );
        final bottomAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.bottom,
        );
        final leftAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.left,
        );

        expect(topAnchor.normal, equals(const Offset(0, -1)));
        expect(rightAnchor.normal, equals(const Offset(1, 0)));
        expect(bottomAnchor.normal, equals(const Offset(0, 1)));
        expect(leftAnchor.normal, equals(const Offset(-1, 0)));
      });
    });

    group('containsPoint', () {
      test('center point is inside', () {
        const shape = DiamondShape();
        expect(
          shape.containsPoint(const Offset(50, 50), const Size(100, 100)),
          isTrue,
        );
      });

      test('corners are outside', () {
        const shape = DiamondShape();
        // Corner points of the bounding rectangle should be outside the diamond
        expect(
          shape.containsPoint(const Offset(0, 0), const Size(100, 100)),
          isFalse,
        );
        expect(
          shape.containsPoint(const Offset(100, 0), const Size(100, 100)),
          isFalse,
        );
        expect(
          shape.containsPoint(const Offset(100, 100), const Size(100, 100)),
          isFalse,
        );
        expect(
          shape.containsPoint(const Offset(0, 100), const Size(100, 100)),
          isFalse,
        );
      });

      test('vertex points are on boundary', () {
        const shape = DiamondShape();
        // Points exactly on the diamond edges
        expect(
          shape.containsPoint(const Offset(50, 0), const Size(100, 100)),
          isTrue,
        );
        expect(
          shape.containsPoint(const Offset(100, 50), const Size(100, 100)),
          isTrue,
        );
        expect(
          shape.containsPoint(const Offset(50, 100), const Size(100, 100)),
          isTrue,
        );
        expect(
          shape.containsPoint(const Offset(0, 50), const Size(100, 100)),
          isTrue,
        );
      });

      test('edge midpoints are inside', () {
        const shape = DiamondShape();
        // Midpoints of diamond edges
        expect(
          shape.containsPoint(const Offset(75, 25), const Size(100, 100)),
          isTrue,
        );
        expect(
          shape.containsPoint(const Offset(75, 75), const Size(100, 100)),
          isTrue,
        );
        expect(
          shape.containsPoint(const Offset(25, 75), const Size(100, 100)),
          isTrue,
        );
        expect(
          shape.containsPoint(const Offset(25, 25), const Size(100, 100)),
          isTrue,
        );
      });

      test('rectangular diamond containment', () {
        const shape = DiamondShape();
        final size = const Size(200, 100);

        // Center
        expect(shape.containsPoint(const Offset(100, 50), size), isTrue);
        // Vertices
        expect(shape.containsPoint(const Offset(100, 0), size), isTrue);
        expect(shape.containsPoint(const Offset(200, 50), size), isTrue);
        expect(shape.containsPoint(const Offset(100, 100), size), isTrue);
        expect(shape.containsPoint(const Offset(0, 50), size), isTrue);
      });
    });

    group('getBounds', () {
      test('returns correct bounds', () {
        const shape = DiamondShape();
        final bounds = shape.getBounds(const Size(100, 100));

        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.width, equals(100));
        expect(bounds.height, equals(100));
      });
    });
  });

  group('HexagonShape', () {
    group('Construction', () {
      test('creates with default values', () {
        const shape = HexagonShape();
        expect(shape.orientation, equals(HexagonOrientation.horizontal));
        expect(shape.sideRatio, equals(0.2));
        expect(shape.fillColor, isNull);
        expect(shape.strokeColor, isNull);
        expect(shape.strokeWidth, isNull);
      });

      test('creates with custom orientation', () {
        const shape = HexagonShape(orientation: HexagonOrientation.vertical);
        expect(shape.orientation, equals(HexagonOrientation.vertical));
      });

      test('creates with custom side ratio', () {
        const shape = HexagonShape(sideRatio: 0.3);
        expect(shape.sideRatio, equals(0.3));
      });

      test('creates with custom colors', () {
        const shape = HexagonShape(
          fillColor: Colors.purple,
          strokeColor: Colors.deepPurple,
          strokeWidth: 3.0,
        );
        expect(shape.fillColor, equals(Colors.purple));
        expect(shape.strokeColor, equals(Colors.deepPurple));
        expect(shape.strokeWidth, equals(3.0));
      });

      test('throws assertion for invalid side ratio', () {
        expect(() => HexagonShape(sideRatio: -0.1), throwsAssertionError);
        expect(() => HexagonShape(sideRatio: 0.6), throwsAssertionError);
      });

      test('accepts boundary side ratio values', () {
        expect(() => const HexagonShape(sideRatio: 0.0), returnsNormally);
        expect(() => const HexagonShape(sideRatio: 0.5), returnsNormally);
      });
    });

    group('buildPath - Horizontal', () {
      test('creates horizontal hexagon path', () {
        const shape = HexagonShape(orientation: HexagonOrientation.horizontal);
        final path = shape.buildPath(const Size(100, 50));

        expect(path, isNotNull);
        final bounds = path.getBounds();
        expect(bounds.width, closeTo(100, 0.01));
        expect(bounds.height, closeTo(50, 0.01));
      });

      test('horizontal hexagon has pointed sides', () {
        const shape = HexagonShape(
          orientation: HexagonOrientation.horizontal,
          sideRatio: 0.2,
        );
        final path = shape.buildPath(const Size(100, 50));

        // The left and right points should be at the center height
        expect(path.contains(const Offset(1, 25)), isTrue); // Near left point
        expect(path.contains(const Offset(99, 25)), isTrue); // Near right point
      });
    });

    group('buildPath - Vertical', () {
      test('creates vertical hexagon path', () {
        const shape = HexagonShape(orientation: HexagonOrientation.vertical);
        final path = shape.buildPath(const Size(50, 100));

        expect(path, isNotNull);
        final bounds = path.getBounds();
        expect(bounds.width, closeTo(50, 0.01));
        expect(bounds.height, closeTo(100, 0.01));
      });

      test('vertical hexagon has pointed top and bottom', () {
        const shape = HexagonShape(
          orientation: HexagonOrientation.vertical,
          sideRatio: 0.2,
        );
        final path = shape.buildPath(const Size(50, 100));

        // The top and bottom points should be at the center width
        expect(path.contains(const Offset(25, 1)), isTrue); // Near top point
        expect(
          path.contains(const Offset(25, 99)),
          isTrue,
        ); // Near bottom point
      });
    });

    group('getPortAnchors - Horizontal', () {
      test('returns 4 port anchors for horizontal hexagon', () {
        const shape = HexagonShape(orientation: HexagonOrientation.horizontal);
        final anchors = shape.getPortAnchors(const Size(100, 50));

        expect(anchors, hasLength(4));
      });

      test('horizontal hexagon has correct port positions', () {
        const shape = HexagonShape(orientation: HexagonOrientation.horizontal);
        final anchors = shape.getPortAnchors(const Size(100, 50));

        final topAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.top,
        );
        final rightAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.right,
        );
        final bottomAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.bottom,
        );
        final leftAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.left,
        );

        expect(topAnchor.offset.dx, equals(50)); // Center X
        expect(topAnchor.offset.dy, equals(0)); // Top
        expect(rightAnchor.offset.dx, equals(100)); // Right edge
        expect(rightAnchor.offset.dy, equals(25)); // Center Y
        expect(bottomAnchor.offset.dx, equals(50)); // Center X
        expect(bottomAnchor.offset.dy, equals(50)); // Bottom
        expect(leftAnchor.offset.dx, equals(0)); // Left edge
        expect(leftAnchor.offset.dy, equals(25)); // Center Y
      });
    });

    group('getPortAnchors - Vertical', () {
      test('returns 4 port anchors for vertical hexagon', () {
        const shape = HexagonShape(orientation: HexagonOrientation.vertical);
        final anchors = shape.getPortAnchors(const Size(50, 100));

        expect(anchors, hasLength(4));
      });

      test('vertical hexagon has correct port positions', () {
        const shape = HexagonShape(orientation: HexagonOrientation.vertical);
        final anchors = shape.getPortAnchors(const Size(50, 100));

        final topAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.top,
        );
        final rightAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.right,
        );
        final bottomAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.bottom,
        );
        final leftAnchor = anchors.firstWhere(
          (a) => a.position == PortPosition.left,
        );

        expect(topAnchor.offset.dx, equals(25)); // Center X
        expect(topAnchor.offset.dy, equals(0)); // Top point
        expect(rightAnchor.offset.dx, equals(50)); // Right edge
        expect(rightAnchor.offset.dy, equals(50)); // Center Y
        expect(bottomAnchor.offset.dx, equals(25)); // Center X
        expect(bottomAnchor.offset.dy, equals(100)); // Bottom point
        expect(leftAnchor.offset.dx, equals(0)); // Left edge
        expect(leftAnchor.offset.dy, equals(50)); // Center Y
      });
    });

    group('containsPoint', () {
      test('center point is inside horizontal hexagon', () {
        const shape = HexagonShape(orientation: HexagonOrientation.horizontal);
        expect(
          shape.containsPoint(const Offset(50, 25), const Size(100, 50)),
          isTrue,
        );
      });

      test('center point is inside vertical hexagon', () {
        const shape = HexagonShape(orientation: HexagonOrientation.vertical);
        expect(
          shape.containsPoint(const Offset(25, 50), const Size(50, 100)),
          isTrue,
        );
      });

      test('external points are outside', () {
        const shape = HexagonShape(orientation: HexagonOrientation.horizontal);
        expect(
          shape.containsPoint(const Offset(-10, 25), const Size(100, 50)),
          isFalse,
        );
        expect(
          shape.containsPoint(const Offset(110, 25), const Size(100, 50)),
          isFalse,
        );
      });
    });

    group('getBounds', () {
      test('returns correct bounds for horizontal hexagon', () {
        const shape = HexagonShape(orientation: HexagonOrientation.horizontal);
        final bounds = shape.getBounds(const Size(100, 50));

        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.width, equals(100));
        expect(bounds.height, equals(50));
      });

      test('returns correct bounds for vertical hexagon', () {
        const shape = HexagonShape(orientation: HexagonOrientation.vertical);
        final bounds = shape.getBounds(const Size(50, 100));

        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.width, equals(50));
        expect(bounds.height, equals(100));
      });
    });
  });

  group('HexagonOrientation', () {
    test('horizontal enum value', () {
      expect(HexagonOrientation.horizontal.index, equals(0));
      expect(HexagonOrientation.horizontal.name, equals('horizontal'));
    });

    test('vertical enum value', () {
      expect(HexagonOrientation.vertical.index, equals(1));
      expect(HexagonOrientation.vertical.name, equals('vertical'));
    });

    test('values list contains both orientations', () {
      expect(HexagonOrientation.values, hasLength(2));
      expect(
        HexagonOrientation.values,
        contains(HexagonOrientation.horizontal),
      );
      expect(HexagonOrientation.values, contains(HexagonOrientation.vertical));
    });
  });

  group('CircleShape', () {
    group('Construction', () {
      test('creates with default values', () {
        const shape = CircleShape();
        expect(shape.fillColor, isNull);
        expect(shape.strokeColor, isNull);
        expect(shape.strokeWidth, isNull);
      });

      test('creates with custom colors', () {
        const shape = CircleShape(
          fillColor: Colors.blue,
          strokeColor: Colors.blueAccent,
          strokeWidth: 2.0,
        );
        expect(shape.fillColor, equals(Colors.blue));
        expect(shape.strokeColor, equals(Colors.blueAccent));
        expect(shape.strokeWidth, equals(2.0));
      });
    });

    group('buildPath', () {
      test('creates circular path for square size', () {
        const shape = CircleShape();
        final path = shape.buildPath(const Size(100, 100));

        expect(path, isNotNull);
        final bounds = path.getBounds();
        expect(bounds.width, closeTo(100, 0.01));
        expect(bounds.height, closeTo(100, 0.01));
      });

      test('creates elliptical path for rectangular size', () {
        const shape = CircleShape();
        final path = shape.buildPath(const Size(200, 100));

        final bounds = path.getBounds();
        expect(bounds.width, closeTo(200, 0.01));
        expect(bounds.height, closeTo(100, 0.01));
      });
    });

    group('getPortAnchors', () {
      test('returns 4 port anchors', () {
        const shape = CircleShape();
        final anchors = shape.getPortAnchors(const Size(100, 100));

        expect(anchors, hasLength(4));
      });

      test('port anchors are at cardinal positions', () {
        const shape = CircleShape();
        final anchors = shape.getPortAnchors(const Size(100, 100));

        final positions = anchors.map((a) => a.position).toSet();
        expect(positions, contains(PortPosition.top));
        expect(positions, contains(PortPosition.right));
        expect(positions, contains(PortPosition.bottom));
        expect(positions, contains(PortPosition.left));
      });
    });

    group('containsPoint', () {
      test('center point is inside', () {
        const shape = CircleShape();
        expect(
          shape.containsPoint(const Offset(50, 50), const Size(100, 100)),
          isTrue,
        );
      });

      test('corner points are outside', () {
        const shape = CircleShape();
        expect(
          shape.containsPoint(const Offset(0, 0), const Size(100, 100)),
          isFalse,
        );
        expect(
          shape.containsPoint(const Offset(100, 0), const Size(100, 100)),
          isFalse,
        );
      });
    });
  });

  group('PortAnchor', () {
    test('creates with required values', () {
      final anchor = PortAnchor(
        position: PortPosition.right,
        offset: const Offset(100, 50),
        normal: const Offset(1, 0),
      );

      expect(anchor.position, equals(PortPosition.right));
      expect(anchor.offset, equals(const Offset(100, 50)));
      expect(anchor.normal, equals(const Offset(1, 0)));
    });

    test('different positions have different normals', () {
      final topAnchor = PortAnchor(
        position: PortPosition.top,
        offset: const Offset(50, 0),
        normal: const Offset(0, -1),
      );
      final bottomAnchor = PortAnchor(
        position: PortPosition.bottom,
        offset: const Offset(50, 100),
        normal: const Offset(0, 1),
      );

      expect(topAnchor.normal!.dy, equals(-1));
      expect(bottomAnchor.normal!.dy, equals(1));
    });
  });
}
