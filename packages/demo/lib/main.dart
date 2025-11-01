import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'src/example_browser.dart';
import 'src/example_not_found.dart';
import 'src/example_registry.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        // Redirect to first example
        final (categoryId, exampleId) = ExampleRegistry.firstExample;
        if (categoryId != null && exampleId != null) {
          return '/$categoryId/$exampleId';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/:categoryId/:exampleId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        final exampleId = state.pathParameters['exampleId']!;

        // Validate that the category and example exist
        final example = ExampleRegistry.findExample(categoryId, exampleId);
        if (example == null) {
          return ExampleNotFound(categoryId: categoryId, exampleId: exampleId);
        }

        return ExampleBrowser(
          categories: ExampleRegistry.all,
          categoryId: categoryId,
          exampleId: exampleId,
        );
      },
    ),
  ],
  errorBuilder: (context, state) => const ExampleNotFound(),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vyuh Node Flow Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
