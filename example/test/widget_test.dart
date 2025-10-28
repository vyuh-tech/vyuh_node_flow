// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  testWidgets('Node Flow basic test', (WidgetTester tester) async {
    // Create a basic controller
    final controller = NodeFlowController<String>();

    // Add a simple node
    controller.addNode(Node<String>(
      id: 'test-node',
      type: 'test',
      position: const Offset(100, 100),
      data: 'Test Node',
    ));

    // Verify node was added
    expect(controller.nodes.length, 1);
    expect(controller.getNode('test-node')?.data, 'Test Node');
  });
}
