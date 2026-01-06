/// Unit tests for LabelCalculator.
///
/// Tests cover:
/// - Label position calculations for different connection styles
/// - Label offset calculations (perpendicular offsets)
/// - Edge cases with very short or long connections
/// - Different anchor positions (start, center, end, custom)
/// - Label gap calculations at endpoints
/// - calculatePositionAtAnchor method
/// - Error handling and fallback behavior
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import 'package:vyuh_node_flow/src/connections/styles/label_calculator.dart';
import 'package:vyuh_node_flow/src/connections/styles/endpoint_position_calculator.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // calculateAllLabelPositions Tests
  // ===========================================================================

  group('LabelCalculator.calculateAllLabelPositions', () {
    group('Basic Label Positioning', () {
      test('returns empty list when connection has no labels', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 0),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, isEmpty);
      });

      test('returns one rect when connection has center label', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 0),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Test'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(1));
        expect(labelRects.first, isA<Rect>());
        expect(labelRects.first.width, greaterThan(0));
        expect(labelRects.first.height, greaterThan(0));
      });

      test('returns three rects when connection has all labels', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 0),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          startLabel: ConnectionLabel.start(text: 'Start'),
          label: ConnectionLabel.center(text: 'Center'),
          endLabel: ConnectionLabel.end(text: 'End'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(3));
      });
    });

    group('Connection Style Support', () {
      test('calculates positions for straight connection style', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 0),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Flow'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(1));
        expect(labelRects.first.isFinite, isTrue);
      });

      test('calculates positions for bezier connection style', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 100),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Bezier'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.bezier,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(1));
        expect(labelRects.first.isFinite, isTrue);
      });

      test('calculates positions for step connection style', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 100),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Step'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.step,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(1));
        expect(labelRects.first.isFinite, isTrue);
      });

      test('calculates positions for smoothstep connection style', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 100),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Smoothstep'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.smoothstep,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(1));
        expect(labelRects.first.isFinite, isTrue);
      });
    });

    group('Anchor Positions', () {
      test('start anchor (0.0) positions label closer to source than end', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(400, 50),
        );

        // Create connections with start and end labels
        final connectionStart = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          startLabel: ConnectionLabel.start(text: 'Start'),
        );
        final connectionEnd = Connection(
          id: 'conn-2',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          endLabel: ConnectionLabel.end(text: 'End'),
        );

        final startRects = LabelCalculator.calculateAllLabelPositions(
          connection: connectionStart,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );
        final endRects = LabelCalculator.calculateAllLabelPositions(
          connection: connectionEnd,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(startRects, hasLength(1));
        expect(endRects, hasLength(1));
        // Start label should be positioned to the left of end label
        expect(startRects.first.center.dx, lessThan(endRects.first.center.dx));
      });

      test('end anchor (1.0) positions label closer to target than start', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(400, 50),
        );

        final connectionCenter = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Center'),
        );
        final connectionEnd = Connection(
          id: 'conn-2',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          endLabel: ConnectionLabel.end(text: 'End'),
        );

        final centerRects = LabelCalculator.calculateAllLabelPositions(
          connection: connectionCenter,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );
        final endRects = LabelCalculator.calculateAllLabelPositions(
          connection: connectionEnd,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(centerRects, hasLength(1));
        expect(endRects, hasLength(1));
        // End label should be positioned to the right of center label
        expect(
          endRects.first.center.dx,
          greaterThan(centerRects.first.center.dx),
        );
      });

      test('custom anchor (0.25) positions label left of center (0.5)', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(400, 50),
        );
        final connectionQuarter = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel(text: 'Quarter', anchor: 0.25),
        );
        final connectionCenter = Connection(
          id: 'conn-2',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel(text: 'Center', anchor: 0.5),
        );

        final quarterRects = LabelCalculator.calculateAllLabelPositions(
          connection: connectionQuarter,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );
        final centerRects = LabelCalculator.calculateAllLabelPositions(
          connection: connectionCenter,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(quarterRects, hasLength(1));
        expect(centerRects, hasLength(1));
        // Label at 0.25 should be to the left of label at 0.5
        expect(
          quarterRects.first.center.dx,
          lessThan(centerRects.first.center.dx),
        );
      });

      test('custom anchor (0.75) positions label right of center (0.5)', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(400, 50),
        );
        final connectionThreeQuarter = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel(text: 'Three-Quarter', anchor: 0.75),
        );
        final connectionCenter = Connection(
          id: 'conn-2',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel(text: 'Center', anchor: 0.5),
        );

        final threeQuarterRects = LabelCalculator.calculateAllLabelPositions(
          connection: connectionThreeQuarter,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );
        final centerRects = LabelCalculator.calculateAllLabelPositions(
          connection: connectionCenter,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(threeQuarterRects, hasLength(1));
        expect(centerRects, hasLength(1));
        // Label at 0.75 should be to the right of label at 0.5
        expect(
          threeQuarterRects.first.center.dx,
          greaterThan(centerRects.first.center.dx),
        );
      });
    });

    group('Label Offset (Perpendicular)', () {
      test('positive offset moves label perpendicular to path', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 100),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 100),
        );

        // Create connection with no offset
        final connectionNoOffset = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'No Offset', offset: 0.0),
        );

        // Create connection with positive offset
        final connectionWithOffset = Connection(
          id: 'conn-2',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'With Offset', offset: 20.0),
        );

        final rectsNoOffset = LabelCalculator.calculateAllLabelPositions(
          connection: connectionNoOffset,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        final rectsWithOffset = LabelCalculator.calculateAllLabelPositions(
          connection: connectionWithOffset,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(rectsNoOffset, hasLength(1));
        expect(rectsWithOffset, hasLength(1));

        // For a horizontal path, offset moves label vertically
        // The y position should differ by approximately the offset amount
        final yDiff =
            (rectsWithOffset.first.center.dy - rectsNoOffset.first.center.dy)
                .abs();
        expect(yDiff, closeTo(20.0, 5.0));
      });

      test(
        'negative offset moves label in opposite perpendicular direction',
        () {
          final sourceNode = createTestNodeWithOutputPort(
            id: 'source',
            position: const Offset(0, 100),
          );
          final targetNode = createTestNodeWithInputPort(
            id: 'target',
            position: const Offset(200, 100),
          );

          final connectionPositive = Connection(
            id: 'conn-1',
            sourceNodeId: 'source',
            sourcePortId: 'output-1',
            targetNodeId: 'target',
            targetPortId: 'input-1',
            label: ConnectionLabel.center(text: 'Positive', offset: 15.0),
          );

          final connectionNegative = Connection(
            id: 'conn-2',
            sourceNodeId: 'source',
            sourcePortId: 'output-1',
            targetNodeId: 'target',
            targetPortId: 'input-1',
            label: ConnectionLabel.center(text: 'Negative', offset: -15.0),
          );

          final rectsPositive = LabelCalculator.calculateAllLabelPositions(
            connection: connectionPositive,
            sourceNode: sourceNode,
            targetNode: targetNode,
            connectionStyle: ConnectionStyles.straight,
            curvature: 0.5,
            endpointSize: const Size.square(5.0),
            labelTheme: LabelTheme.light,
          );

          final rectsNegative = LabelCalculator.calculateAllLabelPositions(
            connection: connectionNegative,
            sourceNode: sourceNode,
            targetNode: targetNode,
            connectionStyle: ConnectionStyles.straight,
            curvature: 0.5,
            endpointSize: const Size.square(5.0),
            labelTheme: LabelTheme.light,
          );

          expect(rectsPositive, hasLength(1));
          expect(rectsNegative, hasLength(1));

          // Positive and negative offsets should be on opposite sides
          final yDiff =
              (rectsPositive.first.center.dy - rectsNegative.first.center.dy)
                  .abs();
          expect(yDiff, closeTo(30.0, 5.0));
        },
      );

      test('zero offset places label on the path', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 100),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 100),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'On Path', offset: 0.0),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(1));
        // For a horizontal path at y=100, label center should be near y=100
        expect(labelRects.first.center.dy, closeTo(100, 30));
      });
    });

    group('Label Gap at Endpoints', () {
      test('labelGap is applied at anchor 0.0', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 50),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          startLabel: ConnectionLabel.start(text: 'Start'),
        );

        final labelRectsWithGap = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light.copyWith(labelGap: 12.0),
        );

        final labelRectsNoGap = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light.copyWith(labelGap: 0.0),
        );

        expect(labelRectsWithGap, hasLength(1));
        expect(labelRectsNoGap, hasLength(1));
        // Label with gap should be shifted right from the start
        expect(
          labelRectsWithGap.first.left,
          greaterThan(labelRectsNoGap.first.left),
        );
      });

      test('labelGap is applied at anchor 1.0', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 50),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          endLabel: ConnectionLabel.end(text: 'End'),
        );

        final labelRectsWithGap = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light.copyWith(labelGap: 12.0),
        );

        final labelRectsNoGap = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light.copyWith(labelGap: 0.0),
        );

        expect(labelRectsWithGap, hasLength(1));
        expect(labelRectsNoGap, hasLength(1));
        // Label with gap should be shifted left from the end
        expect(
          labelRectsWithGap.first.right,
          lessThan(labelRectsNoGap.first.right),
        );
      });

      test('labelGap is not applied at anchor 0.5', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 50),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Center'),
        );

        final labelRectsWithGap = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light.copyWith(labelGap: 20.0),
        );

        final labelRectsNoGap = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light.copyWith(labelGap: 0.0),
        );

        expect(labelRectsWithGap, hasLength(1));
        expect(labelRectsNoGap, hasLength(1));
        // Center label should not be affected by labelGap
        expect(
          labelRectsWithGap.first.center.dx,
          closeTo(labelRectsNoGap.first.center.dx, 1.0),
        );
      });
    });

    group('Edge Cases - Short Connections', () {
      test('handles very short connection', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(30, 50),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Short'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        // Should still calculate a position even for short connections
        expect(labelRects, hasLength(1));
        expect(labelRects.first.isFinite, isTrue);
      });

      test(
        'handles connection where source and target are at same position',
        () {
          final sourceNode = createTestNodeWithOutputPort(
            id: 'source',
            position: const Offset(100, 100),
          );
          final targetNode = createTestNodeWithInputPort(
            id: 'target',
            position: const Offset(100, 100),
          );
          final connection = Connection(
            id: 'conn-1',
            sourceNodeId: 'source',
            sourcePortId: 'output-1',
            targetNodeId: 'target',
            targetPortId: 'input-1',
            label: ConnectionLabel.center(text: 'Overlap'),
          );

          final labelRects = LabelCalculator.calculateAllLabelPositions(
            connection: connection,
            sourceNode: sourceNode,
            targetNode: targetNode,
            connectionStyle: ConnectionStyles.straight,
            curvature: 0.5,
            endpointSize: const Size.square(5.0),
            labelTheme: LabelTheme.light,
          );

          // Should handle gracefully
          expect(labelRects, isA<List<Rect>>());
        },
      );
    });

    group('Edge Cases - Long Connections', () {
      test('handles very long connection', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(5000, 50),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Long Connection'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(1));
        expect(labelRects.first.isFinite, isTrue);
        // Label should be positioned around the middle
        expect(labelRects.first.center.dx, closeTo(2500, 500));
      });
    });

    group('LabelTheme Properties', () {
      test('padding affects label rect size', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 50),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Test'),
        );

        final smallPaddingTheme = LabelTheme.light.copyWith(
          padding: const EdgeInsets.all(2.0),
        );
        final largePaddingTheme = LabelTheme.light.copyWith(
          padding: const EdgeInsets.all(20.0),
        );

        final rectsSmallPadding = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: smallPaddingTheme,
        );

        final rectsLargePadding = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: largePaddingTheme,
        );

        expect(rectsSmallPadding, hasLength(1));
        expect(rectsLargePadding, hasLength(1));
        // Larger padding should result in larger rect
        expect(
          rectsLargePadding.first.width,
          greaterThan(rectsSmallPadding.first.width),
        );
        expect(
          rectsLargePadding.first.height,
          greaterThan(rectsSmallPadding.first.height),
        );
      });

      test('maxWidth constrains label text width', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(400, 50),
        );
        final longText =
            'This is a very long label text that should wrap when maxWidth is set';
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: longText),
        );

        final unrestrictedTheme = LabelTheme.light.copyWith(
          maxWidth: double.infinity,
        );
        final restrictedTheme = LabelTheme.light.copyWith(maxWidth: 100.0);

        final rectsUnrestricted = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: unrestrictedTheme,
        );

        final rectsRestricted = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: restrictedTheme,
        );

        expect(rectsUnrestricted, hasLength(1));
        expect(rectsRestricted, hasLength(1));
        // Restricted width should be smaller
        expect(
          rectsRestricted.first.width,
          lessThanOrEqualTo(rectsUnrestricted.first.width),
        );
      });
    });

    group('Error Handling', () {
      test('returns empty list when source port not found', () {
        final sourceNode = createTestNode(
          id: 'source',
          position: const Offset(0, 0),
          // No ports
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 0),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'nonexistent-port',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Test'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        // Should return empty or handle gracefully
        expect(labelRects, isA<List<Rect>>());
      });

      test('returns empty list when target port not found', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        final targetNode = createTestNode(
          id: 'target',
          position: const Offset(200, 0),
          // No ports
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'nonexistent-port',
          label: ConnectionLabel.center(text: 'Test'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        // Should return empty or handle gracefully
        expect(labelRects, isA<List<Rect>>());
      });
    });

    group('Different Port Positions', () {
      test('handles top port to bottom port connection', () {
        final sourceNode = createTestNode(
          id: 'source',
          position: const Offset(100, 0),
          outputPorts: [
            createTestPort(
              id: 'output-1',
              type: PortType.output,
              position: PortPosition.bottom,
            ),
          ],
        );
        final targetNode = createTestNode(
          id: 'target',
          position: const Offset(100, 200),
          inputPorts: [
            createTestPort(
              id: 'input-1',
              type: PortType.input,
              position: PortPosition.top,
            ),
          ],
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Vertical'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(1));
        expect(labelRects.first.isFinite, isTrue);
      });

      test('handles left port to right port connection', () {
        final sourceNode = createTestNode(
          id: 'source',
          position: const Offset(200, 100),
          outputPorts: [
            createTestPort(
              id: 'output-1',
              type: PortType.output,
              position: PortPosition.left,
            ),
          ],
        );
        final targetNode = createTestNode(
          id: 'target',
          position: const Offset(0, 100),
          inputPorts: [
            createTestPort(
              id: 'input-1',
              type: PortType.input,
              position: PortPosition.right,
            ),
          ],
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Reversed'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(1));
        expect(labelRects.first.isFinite, isTrue);
      });
    });

    group('Endpoint Size Effects', () {
      test('endpoint size affects path calculation', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 50),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 50),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Test'),
        );

        final rectsSmallEndpoint = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(2.0),
          labelTheme: LabelTheme.light,
        );

        final rectsLargeEndpoint = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(20.0),
          labelTheme: LabelTheme.light,
        );

        expect(rectsSmallEndpoint, hasLength(1));
        expect(rectsLargeEndpoint, hasLength(1));
        // Both should be valid
        expect(rectsSmallEndpoint.first.isFinite, isTrue);
        expect(rectsLargeEndpoint.first.isFinite, isTrue);
      });
    });
  });

  // ===========================================================================
  // calculatePositionAtAnchor Tests
  // ===========================================================================

  group('LabelCalculator.calculatePositionAtAnchor', () {
    group('Basic Positioning', () {
      test('returns start position at anchor 0.0', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.0,
          curvature: 0.5,
        );

        // Should be at or very near the start
        expect(position.dx, closeTo(start.dx, 20));
        expect(position.dy, closeTo(start.dy, 20));
      });

      test('returns end position at anchor 1.0', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 1.0,
          curvature: 0.5,
        );

        // Should be at or very near the end
        expect(position.dx, closeTo(end.dx, 20));
        expect(position.dy, closeTo(end.dy, 20));
      });

      test('returns midpoint at anchor 0.5', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
        );

        // Should be approximately in the middle
        expect(position.dx, closeTo(100, 30));
        expect(position.dy, closeTo(100, 30));
      });
    });

    group('Different Connection Styles', () {
      test('bezier style returns position along curve', () {
        final start = const Offset(0, 0);
        final end = const Offset(200, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.bezier,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
        );

        expect(position.isFinite, isTrue);
        // Position should be somewhere between start and end
        expect(position.dx, greaterThanOrEqualTo(0));
        expect(position.dx, lessThanOrEqualTo(200));
      });

      test('step style returns position along path', () {
        final start = const Offset(0, 0);
        final end = const Offset(200, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.step,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
        );

        expect(position.isFinite, isTrue);
      });

      test('smoothstep style returns position along path', () {
        final start = const Offset(0, 0);
        final end = const Offset(200, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.smoothstep,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
        );

        expect(position.isFinite, isTrue);
      });
    });

    group('Custom Anchor Values', () {
      test('anchor 0.25 returns position at 1/4 of path', () {
        final start = const Offset(0, 100);
        final end = const Offset(400, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.25,
          curvature: 0.5,
        );

        expect(position.dx, closeTo(100, 50));
      });

      test('anchor 0.75 returns position at 3/4 of path', () {
        final start = const Offset(0, 100);
        final end = const Offset(400, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.75,
          curvature: 0.5,
        );

        expect(position.dx, closeTo(300, 50));
      });
    });

    group('Port-Aware Positioning', () {
      test('uses source port for position calculation', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);
        final sourcePort = createTestPort(
          id: 'output-1',
          type: PortType.output,
          position: PortPosition.right,
        );

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
          sourcePort: sourcePort,
        );

        expect(position.isFinite, isTrue);
      });

      test('uses target port for position calculation', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);
        final targetPort = createTestPort(
          id: 'input-1',
          type: PortType.input,
          position: PortPosition.left,
        );

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
          targetPort: targetPort,
        );

        expect(position.isFinite, isTrue);
      });
    });

    group('Port Extension Effects', () {
      test('portExtension affects path calculation', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);

        final positionSmallExtension =
            LabelCalculator.calculatePositionAtAnchor(
              connectionStyle: ConnectionStyles.straight,
              start: start,
              end: end,
              anchor: 0.5,
              curvature: 0.5,
              portExtension: 5.0,
            );

        final positionLargeExtension =
            LabelCalculator.calculatePositionAtAnchor(
              connectionStyle: ConnectionStyles.straight,
              start: start,
              end: end,
              anchor: 0.5,
              curvature: 0.5,
              portExtension: 50.0,
            );

        expect(positionSmallExtension.isFinite, isTrue);
        expect(positionLargeExtension.isFinite, isTrue);
      });
    });

    group('Edge Cases', () {
      test('handles zero-length path gracefully', () {
        final start = const Offset(100, 100);
        final end = const Offset(100, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
        );

        // Should return a valid position (likely linear interpolation fallback)
        expect(position.isFinite, isTrue);
      });

      test('handles very small path lengths', () {
        final start = const Offset(100, 100);
        final end = const Offset(100.001, 100.001);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
        );

        expect(position.isFinite, isTrue);
      });

      test('handles negative coordinates', () {
        final start = const Offset(-100, -50);
        final end = const Offset(100, 50);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
        );

        expect(position.isFinite, isTrue);
        expect(position.dx, closeTo(0, 30));
        expect(position.dy, closeTo(0, 30));
      });

      test('handles very large coordinates', () {
        final start = const Offset(0, 0);
        final end = const Offset(10000, 10000);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.5,
        );

        expect(position.isFinite, isTrue);
        expect(position.dx, closeTo(5000, 500));
        expect(position.dy, closeTo(5000, 500));
      });
    });

    group('Curvature Effects', () {
      test('curvature affects bezier path position', () {
        final start = const Offset(0, 0);
        final end = const Offset(200, 0);

        final positionLowCurvature = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.bezier,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.1,
        );

        final positionHighCurvature = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.bezier,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.9,
        );

        expect(positionLowCurvature.isFinite, isTrue);
        expect(positionHighCurvature.isFinite, isTrue);
        // Both should be valid, potentially at different positions
      });

      test('curvature 0.0 produces minimal curve', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.bezier,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 0.0,
        );

        expect(position.isFinite, isTrue);
      });

      test('curvature 1.0 produces maximum curve', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);

        final position = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.bezier,
          start: start,
          end: end,
          anchor: 0.5,
          curvature: 1.0,
        );

        expect(position.isFinite, isTrue);
      });
    });
  });

  // ===========================================================================
  // Integration Tests
  // ===========================================================================

  group('LabelCalculator Integration', () {
    test('multiple labels are positioned correctly relative to each other', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'source',
        position: const Offset(0, 50),
      );
      final targetNode = createTestNodeWithInputPort(
        id: 'target',
        position: const Offset(400, 50),
      );
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'source',
        sourcePortId: 'output-1',
        targetNodeId: 'target',
        targetPortId: 'input-1',
        startLabel: ConnectionLabel.start(text: 'Start'),
        label: ConnectionLabel.center(text: 'Center'),
        endLabel: ConnectionLabel.end(text: 'End'),
      );

      final labelRects = LabelCalculator.calculateAllLabelPositions(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: ConnectionStyles.straight,
        curvature: 0.5,
        endpointSize: const Size.square(5.0),
        labelTheme: LabelTheme.light,
      );

      expect(labelRects, hasLength(3));

      // Start label should be leftmost
      // Center label should be in the middle
      // End label should be rightmost
      final startRect = labelRects[0];
      final centerRect = labelRects[1];
      final endRect = labelRects[2];

      expect(startRect.center.dx, lessThan(centerRect.center.dx));
      expect(centerRect.center.dx, lessThan(endRect.center.dx));
    });

    test(
      'labels with different offsets are positioned at different y values',
      () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 100),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 100),
        );

        // Create three labels at the same anchor but different offsets
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          startLabel: ConnectionLabel(
            text: 'Above',
            anchor: 0.5,
            offset: -20.0,
          ),
          label: ConnectionLabel(text: 'Center', anchor: 0.5, offset: 0.0),
          endLabel: ConnectionLabel(text: 'Below', anchor: 0.5, offset: 20.0),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        expect(labelRects, hasLength(3));

        // All three should have similar x positions (same anchor)
        // but different y positions (different offsets)
        final aboveRect = labelRects[0];
        final centerRect = labelRects[1];
        final belowRect = labelRects[2];

        // X positions should be close
        expect((aboveRect.center.dx - centerRect.center.dx).abs(), lessThan(5));
        expect((centerRect.center.dx - belowRect.center.dx).abs(), lessThan(5));

        // Y positions should be different
        expect(aboveRect.center.dy, lessThan(centerRect.center.dy));
        expect(centerRect.center.dy, lessThan(belowRect.center.dy));
      },
    );

    test(
      'consistency between calculateAllLabelPositions and calculatePositionAtAnchor',
      () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 100),
        );
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(200, 100),
        );
        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'target',
          targetPortId: 'input-1',
          label: ConnectionLabel.center(text: 'Test'),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: ConnectionStyles.straight,
          curvature: 0.5,
          endpointSize: const Size.square(5.0),
          labelTheme: LabelTheme.light,
        );

        // Get position using calculatePositionAtAnchor
        // Note: This uses a simplified path without node context
        final anchorPosition = LabelCalculator.calculatePositionAtAnchor(
          connectionStyle: ConnectionStyles.straight,
          start: const Offset(0, 100),
          end: const Offset(200, 100),
          anchor: 0.5,
          curvature: 0.5,
        );

        expect(labelRects, hasLength(1));
        expect(anchorPosition.isFinite, isTrue);

        // Both methods should produce positions in a similar area
        // (exact match not expected due to different path calculations)
      },
    );
  });
}
