import 'package:flutter/material.dart';
import 'package:vyuh_node_flow_example/annotation_example.dart';
import 'package:vyuh_node_flow_example/connection_validation_example.dart';
import 'package:vyuh_node_flow_example/workbench_example.dart';
import 'viewer_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vyuh Node Flow Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const PortCombinationsDemo(),
      home: const WorkbenchExample(),
      // home: const AnnotationExample(),
      // home: const ConnectionValidationExample(),
      // home: const ViewerExample(),

      // home: const NodeFlowExample(), // Render object example from render_object_example.dart
    );
  }
}
