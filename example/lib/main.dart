import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vyuh_node_flow_example/annotation_example.dart';
import 'package:vyuh_node_flow_example/connection_validation_example.dart';
import 'package:vyuh_node_flow_example/port_combinations_demo.dart';
import 'package:vyuh_node_flow_example/viewer_example.dart';
import 'package:vyuh_node_flow_example/workbench_example.dart';

import 'launch_page.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LaunchPage()),
    GoRoute(
      path: '/workbench',
      builder: (context, state) => const WorkbenchExample(),
    ),
    GoRoute(
      path: '/annotations',
      builder: (context, state) => const AnnotationExample(),
    ),
    GoRoute(
      path: '/validation',
      builder: (context, state) => const ConnectionValidationExample(),
    ),
    GoRoute(
      path: '/viewer',
      builder: (context, state) => const ViewerExample(),
    ),
    GoRoute(
      path: '/port-combinations',
      builder: (context, state) => const PortCombinationsDemo(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vyuh Node Flow Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
