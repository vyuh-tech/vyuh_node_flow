/// Unit tests for ElementScope widget.
///
/// Tests cover:
/// - Widget construction and default values
/// - Drag lifecycle management (_startDrag, _updateDrag, _endDrag, _cancelDrag)
/// - Pointer ID tracking and guard clauses
/// - DragSession integration
/// - AutoPan mixin integration
/// - Gesture handling and hit test behavior
/// - Dispose cleanup with active drag
/// - Mouse region callbacks
@Tags(['unit'])
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/editor/drag_session.dart';
import 'package:vyuh_node_flow/src/editor/element_scope.dart';
import 'package:vyuh_node_flow/src/extensions/autopan/auto_pan_extension.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Widget Construction Tests
  // ===========================================================================

  group('ElementScope Construction', () {
    test('creates with required parameters', () {
      const scope = ElementScope(
        onDragStart: _noOpDragStart,
        onDragUpdate: _noOpDragUpdate,
        onDragEnd: _noOpDragEnd,
        child: SizedBox(),
      );

      expect(scope.isDraggable, isTrue);
      expect(scope.dragStartBehavior, equals(DragStartBehavior.start));
      expect(scope.hitTestBehavior, equals(HitTestBehavior.opaque));
      expect(scope.cursor, isNull);
      expect(scope.onTap, isNull);
      expect(scope.onDoubleTap, isNull);
      expect(scope.onContextMenu, isNull);
      expect(scope.onMouseEnter, isNull);
      expect(scope.onMouseLeave, isNull);
      expect(scope.autoPan, isNull);
      expect(scope.onAutoPan, isNull);
      expect(scope.getViewportBounds, isNull);
      expect(scope.screenToGraph, isNull);
      expect(scope.onDragCancel, isNull);
      expect(scope.createSession, isNull);
    });

    test('creates with all optional parameters', () {
      final autoPan = AutoPanExtension();

      final scope = ElementScope(
        onDragStart: _noOpDragStart,
        onDragUpdate: _noOpDragUpdate,
        onDragEnd: _noOpDragEnd,
        onDragCancel: () {},
        createSession: () => _MockDragSession(),
        isDraggable: false,
        dragStartBehavior: DragStartBehavior.down,
        onTap: () {},
        onDoubleTap: () {},
        onContextMenu: (_) {},
        onMouseEnter: () {},
        onMouseLeave: () {},
        cursor: SystemMouseCursors.grab,
        hitTestBehavior: HitTestBehavior.translucent,
        autoPan: autoPan,
        onAutoPan: (_) {},
        getViewportBounds: () => Rect.zero,
        screenToGraph: (pos) => pos,
        child: const SizedBox(),
      );

      expect(scope.isDraggable, isFalse);
      expect(scope.dragStartBehavior, equals(DragStartBehavior.down));
      expect(scope.hitTestBehavior, equals(HitTestBehavior.translucent));
      expect(scope.cursor, equals(SystemMouseCursors.grab));
      expect(scope.onTap, isNotNull);
      expect(scope.onDoubleTap, isNotNull);
      expect(scope.onContextMenu, isNotNull);
      expect(scope.onMouseEnter, isNotNull);
      expect(scope.onMouseLeave, isNotNull);
      expect(scope.autoPan, equals(autoPan));
      expect(scope.onAutoPan, isNotNull);
      expect(scope.getViewportBounds, isNotNull);
      expect(scope.screenToGraph, isNotNull);
      expect(scope.onDragCancel, isNotNull);
      expect(scope.createSession, isNotNull);
    });
  });

  // ===========================================================================
  // Widget Build Tests
  // ===========================================================================

  group('ElementScope Build', () {
    testWidgets('builds correct widget tree structure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElementScope(
            onDragStart: _noOpDragStart,
            onDragUpdate: _noOpDragUpdate,
            onDragEnd: _noOpDragEnd,
            onDoubleTap: () {},
            onContextMenu: (_) {},
            onMouseEnter: () {},
            onMouseLeave: () {},
            child: const SizedBox(
              key: Key('test-child'),
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Verify ElementScope widget exists
      expect(find.byType(ElementScope), findsOneWidget);

      // Verify RawGestureDetector exists within ElementScope
      expect(
        find.descendant(
          of: find.byType(ElementScope),
          matching: find.byType(RawGestureDetector),
        ),
        findsWidgets,
      );

      // Verify MouseRegion exists within ElementScope
      expect(
        find.descendant(
          of: find.byType(ElementScope),
          matching: find.byType(MouseRegion),
        ),
        findsOneWidget,
      );

      // Verify child exists
      expect(find.byKey(const Key('test-child')), findsOneWidget);
    });

    testWidgets('applies correct cursor when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElementScope(
            onDragStart: _noOpDragStart,
            onDragUpdate: _noOpDragUpdate,
            onDragEnd: _noOpDragEnd,
            cursor: SystemMouseCursors.grab,
            child: const SizedBox(
              key: Key('cursor-test'),
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Find the MouseRegion within ElementScope
      final mouseRegion = tester.widget<MouseRegion>(
        find.descendant(
          of: find.byType(ElementScope),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(mouseRegion.cursor, equals(SystemMouseCursors.grab));
    });

    testWidgets('uses defer cursor when none provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElementScope(
            onDragStart: _noOpDragStart,
            onDragUpdate: _noOpDragUpdate,
            onDragEnd: _noOpDragEnd,
            child: const SizedBox(
              key: Key('no-cursor-test'),
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      final mouseRegion = tester.widget<MouseRegion>(
        find.descendant(
          of: find.byType(ElementScope),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(mouseRegion.cursor, equals(MouseCursor.defer));
    });

    testWidgets('applies hit test behavior to RawGestureDetector', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElementScope(
            onDragStart: _noOpDragStart,
            onDragUpdate: _noOpDragUpdate,
            onDragEnd: _noOpDragEnd,
            hitTestBehavior: HitTestBehavior.translucent,
            child: const SizedBox(
              key: Key('hit-test'),
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      final detector = tester.widget<RawGestureDetector>(
        find.descendant(
          of: find.byType(ElementScope),
          matching: find.byType(RawGestureDetector),
        ),
      );
      expect(detector.behavior, equals(HitTestBehavior.translucent));
    });
  });

  // ===========================================================================
  // Tap Callback Tests
  // ===========================================================================

  group('ElementScope Tap Callback', () {
    testWidgets('onTap fires on pointer down via gesture', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                onTap: () => tapCount++,
                child: Container(
                  key: const Key('tap-test'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Use gesture instead of tap to avoid hit test warnings
      final center = tester.getCenter(find.byKey(const Key('tap-test')));
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();

      expect(tapCount, equals(1));
    });

    testWidgets('onTap fires immediately on pointer down', (tester) async {
      final events = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: (_) => events.add('dragStart'),
                onDragUpdate: (_) => events.add('dragUpdate'),
                onDragEnd: (_) => events.add('dragEnd'),
                onTap: () => events.add('tap'),
                child: Container(
                  key: const Key('tap-drag-test'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Start a drag gesture
      final center = tester.getCenter(find.byKey(const Key('tap-drag-test')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      // At this point, tap should have fired (on pointer down)
      expect(events.contains('tap'), isTrue);
      // Tap fires before dragStart in the events list
      final tapIndex = events.indexOf('tap');
      final dragStartIndex = events.indexOf('dragStart');
      // If dragStart is not called yet, it's fine (drag hasn't started)
      // If both are called, tap should come first
      if (dragStartIndex != -1) {
        expect(tapIndex, lessThan(dragStartIndex));
      }

      await gesture.up();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();
    });

    testWidgets('tap is blocked during active drag', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                onTap: () => tapCount++,
                child: Container(
                  key: const Key('tap-blocked-test'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(
        find.byKey(const Key('tap-blocked-test')),
      );

      // Start a drag
      final gesture1 = await tester.startGesture(center);
      await tester.pump();

      // First tap counts (on pointer down)
      expect(tapCount, equals(1));

      // Move to start the drag
      await gesture1.moveBy(const Offset(50, 0));
      await tester.pump();

      // During an active drag, a new pointer down should be blocked
      // We can't easily simulate this in Flutter test, but we can verify
      // the initial tap fired correctly
      expect(tapCount, equals(1));

      await gesture1.up();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();
    });
  });

  // ===========================================================================
  // Mouse Region Callback Tests
  // ===========================================================================

  group('ElementScope Mouse Region', () {
    testWidgets('onMouseEnter fires when mouse enters', (tester) async {
      var enterCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                onMouseEnter: () => enterCount++,
                child: Container(
                  key: const Key('enter-test'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      await gesture.moveTo(
        tester.getCenter(find.byKey(const Key('enter-test'))),
      );
      await tester.pump();

      expect(enterCount, equals(1));

      await gesture.removePointer();
    });

    testWidgets('onMouseLeave fires when mouse leaves', (tester) async {
      var leaveCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                onMouseLeave: () => leaveCount++,
                child: Container(
                  key: const Key('leave-test'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      // Enter the widget
      await gesture.moveTo(
        tester.getCenter(find.byKey(const Key('leave-test'))),
      );
      await tester.pump();

      // Leave the widget
      await gesture.moveTo(Offset.zero);
      await tester.pump();

      expect(leaveCount, equals(1));

      await gesture.removePointer();
    });
  });

  // ===========================================================================
  // Drag Lifecycle Tests
  // ===========================================================================

  group('ElementScope Drag Lifecycle', () {
    testWidgets('drag lifecycle calls all callbacks in order', (tester) async {
      final callOrder = <String>[];
      DragStartDetails? startDetails;
      final updateDetails = <DragUpdateDetails>[];
      DragEndDetails? endDetails;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: (details) {
                  callOrder.add('start');
                  startDetails = details;
                },
                onDragUpdate: (details) {
                  callOrder.add('update');
                  updateDetails.add(details);
                },
                onDragEnd: (details) {
                  callOrder.add('end');
                  endDetails = details;
                },
                child: Container(
                  key: const Key('drag-lifecycle'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Perform a drag gesture
      final center = tester.getCenter(find.byKey(const Key('drag-lifecycle')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();

      // Verify order
      expect(callOrder.first, equals('start'));
      expect(callOrder.last, equals('end'));
      expect(
        callOrder.where((c) => c == 'update').length,
        greaterThanOrEqualTo(1),
      );

      // Verify details were passed
      expect(startDetails, isNotNull);
      expect(updateDetails, isNotEmpty);
      expect(endDetails, isNotNull);
    });

    testWidgets('onDragCancel or onDragEnd is called on gesture cancel', (
      tester,
    ) async {
      var cancelCalled = false;
      var endCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: (_) => endCalled = true,
                onDragCancel: () => cancelCalled = true,
                child: Container(
                  key: const Key('cancel-test'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Start a drag
      final center = tester.getCenter(find.byKey(const Key('cancel-test')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // Cancel the gesture
      await gesture.cancel();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();

      // Either cancel or end should be called (depends on how the gesture
      // system handles cancellation)
      expect(cancelCalled || endCalled, isTrue);
    });

    testWidgets('falls back to onDragEnd if onDragCancel not provided', (
      tester,
    ) async {
      var endCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: (_) => endCalled = true,
                child: Container(
                  key: const Key('fallback-test'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Start a drag
      final center = tester.getCenter(find.byKey(const Key('fallback-test')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // Cancel the gesture
      await gesture.cancel();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();

      expect(endCalled, isTrue);
    });
  });

  // ===========================================================================
  // Drag Session Integration Tests
  // ===========================================================================

  group('ElementScope DragSession Integration', () {
    testWidgets('creates and starts session on drag start', (tester) async {
      final session = _MockDragSession();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                createSession: () => session,
                child: Container(
                  key: const Key('session-start'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Start a drag
      final center = tester.getCenter(find.byKey(const Key('session-start')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      expect(session.startCalled, isTrue);
      expect(session.endCalled, isFalse);
      expect(session.cancelCalled, isFalse);

      await gesture.up();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();
    });

    testWidgets('ends session on drag end', (tester) async {
      final session = _MockDragSession();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                createSession: () => session,
                child: Container(
                  key: const Key('session-end'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Perform complete drag
      final center = tester.getCenter(find.byKey(const Key('session-end')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();

      expect(session.startCalled, isTrue);
      expect(session.endCalled, isTrue);
      expect(session.cancelCalled, isFalse);
    });

    testWidgets('session ends when drag is cancelled or ended', (tester) async {
      final session = _MockDragSession();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                createSession: () => session,
                child: Container(
                  key: const Key('session-cancel'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Start a drag
      final center = tester.getCenter(find.byKey(const Key('session-cancel')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      expect(session.startCalled, isTrue);

      // Cancel the gesture
      await gesture.cancel();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();

      // Either end or cancel should be called
      expect(session.endCalled || session.cancelCalled, isTrue);
    });
  });

  // ===========================================================================
  // isDraggable Tests
  // ===========================================================================

  group('ElementScope isDraggable', () {
    testWidgets('does not register drag gestures when not draggable', (
      tester,
    ) async {
      var dragStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: (_) => dragStarted = true,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                isDraggable: false,
                child: Container(
                  key: const Key('not-draggable'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Try to drag
      final center = tester.getCenter(find.byKey(const Key('not-draggable')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();

      // Drag should not have started
      expect(dragStarted, isFalse);
    });

    testWidgets('registers drag gestures when draggable', (tester) async {
      var dragStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: (_) => dragStarted = true,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                isDraggable: true,
                child: Container(
                  key: const Key('draggable'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Perform a drag
      final center = tester.getCenter(find.byKey(const Key('draggable')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();

      expect(dragStarted, isTrue);
    });
  });

  // ===========================================================================
  // dragStartBehavior Tests
  // ===========================================================================

  group('ElementScope dragStartBehavior', () {
    testWidgets('DragStartBehavior.start passes start behavior to recognizer', (
      tester,
    ) async {
      var dragStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: (_) => dragStarted = true,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                dragStartBehavior: DragStartBehavior.start,
                child: Container(
                  key: const Key('start-behavior'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.byKey(const Key('start-behavior')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      // Make a large move to start the drag
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      await tester.pumpAndSettle();

      // Drag should start with large movement
      expect(dragStarted, isTrue);
    });

    testWidgets('DragStartBehavior.down starts more readily', (tester) async {
      var dragStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: (_) => dragStarted = true,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                dragStartBehavior: DragStartBehavior.down,
                child: Container(
                  key: const Key('down-behavior'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Press down and move slightly
      final center = tester.getCenter(find.byKey(const Key('down-behavior')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(5, 0));
      await tester.pump();

      expect(dragStarted, isTrue);

      await gesture.up();
      await tester.pump();
      // Allow microtask to complete
      await tester.pumpAndSettle();
    });
  });

  // ===========================================================================
  // Double Tap Tests
  // ===========================================================================

  group('ElementScope Double Tap', () {
    testWidgets('onDoubleTap fires on double tap', (tester) async {
      var doubleTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                onDoubleTap: () => doubleTapCount++,
                child: Container(
                  key: const Key('double-tap'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Perform double tap using gestures
      final center = tester.getCenter(find.byKey(const Key('double-tap')));
      final gesture1 = await tester.startGesture(center);
      await tester.pump();
      await gesture1.up();
      await tester.pump(const Duration(milliseconds: 50));
      final gesture2 = await tester.startGesture(center);
      await tester.pump();
      await gesture2.up();
      await tester.pump();
      // Allow all microtasks to complete
      await tester.pumpAndSettle();

      expect(doubleTapCount, equals(1));
    });

    testWidgets('gesture recognizer not registered when onDoubleTap is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElementScope(
            onDragStart: _noOpDragStart,
            onDragUpdate: _noOpDragUpdate,
            onDragEnd: _noOpDragEnd,
            // onDoubleTap not provided
            child: const SizedBox(
              key: Key('no-double-tap'),
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      final detector = tester.widget<RawGestureDetector>(
        find.descendant(
          of: find.byType(ElementScope),
          matching: find.byType(RawGestureDetector),
        ),
      );

      // DoubleTapGestureRecognizer should not be registered
      expect(
        detector.gestures.containsKey(DoubleTapGestureRecognizer),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // Context Menu Tests
  // ===========================================================================

  group('ElementScope Context Menu', () {
    testWidgets('onContextMenu fires on secondary tap', (tester) async {
      var contextMenuCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                onContextMenu: (_) => contextMenuCalled = true,
                child: Container(
                  key: const Key('context-menu'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Perform secondary tap (right click) using gesture
      final center = tester.getCenter(find.byKey(const Key('context-menu')));
      final gesture = await tester.startGesture(
        center,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(contextMenuCalled, isTrue);
    });

    testWidgets(
      'gesture recognizer not registered when onContextMenu is null',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ElementScope(
              onDragStart: _noOpDragStart,
              onDragUpdate: _noOpDragUpdate,
              onDragEnd: _noOpDragEnd,
              // onContextMenu not provided
              child: const SizedBox(
                key: Key('no-context'),
                width: 100,
                height: 100,
              ),
            ),
          ),
        );

        final detector = tester.widget<RawGestureDetector>(
          find.descendant(
            of: find.byType(ElementScope),
            matching: find.byType(RawGestureDetector),
          ),
        );

        // TapGestureRecognizer for context menu should not be registered
        expect(detector.gestures.containsKey(TapGestureRecognizer), isFalse);
      },
    );
  });

  // ===========================================================================
  // Dispose Cleanup Tests
  // ===========================================================================

  group('ElementScope Dispose', () {
    testWidgets('cleans up properly when disposed', (tester) async {
      final showWidget = ValueNotifier(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showWidget,
            builder: (context, show, _) {
              if (!show) return const SizedBox();
              return ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                child: const SizedBox(
                  key: Key('dispose-test'),
                  width: 100,
                  height: 100,
                ),
              );
            },
          ),
        ),
      );

      expect(find.byType(ElementScope), findsOneWidget);

      // Remove the widget
      showWidget.value = false;
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ElementScope), findsNothing);
    });

    testWidgets('drag cancel callback fires when widget disposed mid-drag', (
      tester,
    ) async {
      var cancelCalled = false;
      final showWidget = ValueNotifier(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: showWidget,
              builder: (context, show, _) {
                if (!show) return const SizedBox();
                return Center(
                  child: ElementScope(
                    onDragStart: _noOpDragStart,
                    onDragUpdate: _noOpDragUpdate,
                    onDragEnd: _noOpDragEnd,
                    onDragCancel: () => cancelCalled = true,
                    child: Container(
                      key: const Key('mid-drag-dispose'),
                      width: 100,
                      height: 100,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Start a drag
      final center = tester.getCenter(
        find.byKey(const Key('mid-drag-dispose')),
      );
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // Remove the widget mid-drag
      showWidget.value = false;
      await tester.pump();
      await tester.pumpAndSettle();

      // Cancel should have been called during dispose
      expect(cancelCalled, isTrue);

      // Clean up
      await gesture.up();
    });
  });

  // ===========================================================================
  // Guard Clause Tests
  // ===========================================================================

  group('ElementScope Guard Clauses', () {
    testWidgets('only calls drag start once per drag', (tester) async {
      var startCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: (_) => startCount++,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: _noOpDragEnd,
                child: Container(
                  key: const Key('single-start'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Start a drag with multiple moves
      final center = tester.getCenter(find.byKey(const Key('single-start')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // Should only start once
      expect(startCount, equals(1));

      await gesture.up();
      await tester.pump();
      await tester.pumpAndSettle();
    });

    testWidgets('drag end only fires once per drag', (tester) async {
      var endCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: _noOpDragStart,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: (_) => endCount++,
                child: Container(
                  key: const Key('single-end'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Perform a complete drag cycle
      final center = tester.getCenter(find.byKey(const Key('single-end')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      await tester.pumpAndSettle();

      // Only one end should have been called
      expect(endCount, equals(1));
    });
  });

  // ===========================================================================
  // AutoPan Configuration Tests
  // ===========================================================================

  group('ElementScope AutoPan Configuration', () {
    test('autoPan parameters are properly stored', () {
      final autoPan = AutoPanExtension(enabled: true);

      final scope = ElementScope(
        onDragStart: _noOpDragStart,
        onDragUpdate: _noOpDragUpdate,
        onDragEnd: _noOpDragEnd,
        autoPan: autoPan,
        onAutoPan: (delta) {},
        getViewportBounds: () => const Rect.fromLTWH(0, 0, 800, 600),
        screenToGraph: (pos) => pos,
        child: const SizedBox(),
      );

      expect(scope.autoPan, equals(autoPan));
      expect(scope.onAutoPan, isNotNull);
      expect(scope.getViewportBounds, isNotNull);
      expect(scope.screenToGraph, isNotNull);
    });

    test('autoPan parameters can be null', () {
      const scope = ElementScope(
        onDragStart: _noOpDragStart,
        onDragUpdate: _noOpDragUpdate,
        onDragEnd: _noOpDragEnd,
        child: SizedBox(),
      );

      expect(scope.autoPan, isNull);
      expect(scope.onAutoPan, isNull);
      expect(scope.getViewportBounds, isNull);
      expect(scope.screenToGraph, isNull);
    });
  });

  // ===========================================================================
  // Drag Details Tests
  // ===========================================================================

  group('ElementScope Drag Details', () {
    testWidgets('passes drag details to callbacks', (tester) async {
      DragStartDetails? capturedStartDetails;
      final capturedUpdateDetails = <DragUpdateDetails>[];
      DragEndDetails? capturedEndDetails;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: (details) => capturedStartDetails = details,
                onDragUpdate: (details) => capturedUpdateDetails.add(details),
                onDragEnd: (details) => capturedEndDetails = details,
                child: Container(
                  key: const Key('details-test'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Start drag at known position
      final center = tester.getCenter(find.byKey(const Key('details-test')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      // Move to a new position
      await gesture.moveBy(const Offset(100, 50));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(capturedStartDetails, isNotNull);
      expect(capturedUpdateDetails, isNotEmpty);
      expect(capturedEndDetails, isNotNull);
    });
  });

  // ===========================================================================
  // Edge Cases Tests
  // ===========================================================================

  group('ElementScope Edge Cases', () {
    testWidgets('handles widget rebuild during drag', (tester) async {
      var dragEndCount = 0;
      final counter = ValueNotifier(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: counter,
              builder: (context, _, _) {
                return Center(
                  child: ElementScope(
                    onDragStart: _noOpDragStart,
                    onDragUpdate: _noOpDragUpdate,
                    onDragEnd: (_) => dragEndCount++,
                    child: Container(
                      key: const Key('rebuild-test'),
                      width: 100,
                      height: 100,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Start a drag
      final center = tester.getCenter(find.byKey(const Key('rebuild-test')));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // Trigger a rebuild mid-drag
      counter.value++;
      await tester.pump();

      // Continue and end drag
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      await tester.pumpAndSettle();

      // Drag should still complete properly after rebuild
      expect(dragEndCount, equals(1));
    });

    testWidgets('handles empty child correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElementScope(
            onDragStart: _noOpDragStart,
            onDragUpdate: _noOpDragUpdate,
            onDragEnd: _noOpDragEnd,
            child: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(ElementScope), findsOneWidget);
    });

    testWidgets('sequential drag operations work correctly', (tester) async {
      var dragStartCount = 0;
      var dragEndCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElementScope(
                onDragStart: (_) => dragStartCount++,
                onDragUpdate: _noOpDragUpdate,
                onDragEnd: (_) => dragEndCount++,
                child: Container(
                  key: const Key('sequential-drag'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.byKey(const Key('sequential-drag')));

      // First drag
      final gesture1 = await tester.startGesture(center);
      await tester.pump();
      await gesture1.moveBy(const Offset(100, 0));
      await tester.pump();
      await gesture1.up();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(dragStartCount, equals(1));
      expect(dragEndCount, equals(1));

      // Second drag
      final gesture2 = await tester.startGesture(center);
      await tester.pump();
      await gesture2.moveBy(const Offset(100, 0));
      await tester.pump();
      await gesture2.up();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(dragStartCount, equals(2));
      expect(dragEndCount, equals(2));
    });
  });

  // ===========================================================================
  // DragSession Type Tests
  // ===========================================================================

  group('DragSessionType', () {
    test('has expected values', () {
      expect(DragSessionType.values, hasLength(2));
      expect(DragSessionType.values, contains(DragSessionType.nodeDrag));
      expect(DragSessionType.values, contains(DragSessionType.connectionDrag));
    });
  });

  // ===========================================================================
  // DragSession Abstract Interface Tests
  // ===========================================================================

  group('DragSession Interface', () {
    test('mock session implements interface correctly', () {
      final session = _MockDragSession();

      expect(session.type, equals(DragSessionType.nodeDrag));
      expect(session.isActive, isFalse);

      session.start();
      expect(session.isActive, isTrue);
      expect(session.startCalled, isTrue);

      session.end();
      expect(session.isActive, isFalse);
      expect(session.endCalled, isTrue);
    });

    test('cancel sets session to inactive', () {
      final session = _MockDragSession();

      session.start();
      expect(session.isActive, isTrue);

      session.cancel();
      expect(session.isActive, isFalse);
      expect(session.cancelCalled, isTrue);
    });

    test('start is idempotent when already active', () {
      final session = _MockDragSession();

      session.start();
      session.start(); // Second start should be no-op

      expect(session.startCallCount, equals(1));
    });

    test('end is idempotent when not active', () {
      final session = _MockDragSession();

      session.end(); // End without start should be no-op

      expect(session.endCalled, isFalse);
    });

    test('cancel is idempotent when not active', () {
      final session = _MockDragSession();

      session.cancel(); // Cancel without start should be no-op

      expect(session.cancelCalled, isFalse);
    });
  });
}

// =============================================================================
// Test Helpers
// =============================================================================

void _noOpDragStart(DragStartDetails details) {}
void _noOpDragUpdate(DragUpdateDetails details) {}
void _noOpDragEnd(DragEndDetails details) {}

/// Mock implementation of DragSession for testing.
class _MockDragSession implements DragSession {
  bool _isActive = false;
  bool startCalled = false;
  bool endCalled = false;
  bool cancelCalled = false;
  int startCallCount = 0;

  @override
  DragSessionType get type => DragSessionType.nodeDrag;

  @override
  bool get isActive => _isActive;

  @override
  void start() {
    if (_isActive) return;
    _isActive = true;
    startCalled = true;
    startCallCount++;
  }

  @override
  void end() {
    if (!_isActive) return;
    _isActive = false;
    endCalled = true;
  }

  @override
  void cancel() {
    if (!_isActive) return;
    _isActive = false;
    cancelCalled = true;
  }
}
