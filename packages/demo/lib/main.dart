import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'design_kit/theme.dart';
import 'embed_wrapper.dart';
import 'example_browser.dart';
import 'example_not_found.dart';
import 'example_registry.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        // Redirect to first example, preserving query params
        final (categoryId, exampleId) = ExampleRegistry.firstExample;
        if (categoryId != null && exampleId != null) {
          final queryString = state.uri.query.isNotEmpty
              ? '?${state.uri.query}'
              : '';
          return '/$categoryId/$exampleId$queryString';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/:categoryId/:exampleId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        final exampleId = state.pathParameters['exampleId']!;

        // Check for embed mode via query params
        final isEmbed = state.uri.queryParameters['embed'] == 'true';

        // Validate that the category and example exist
        final example = ExampleRegistry.findExample(categoryId, exampleId);
        if (example == null) {
          return ExampleNotFound(categoryId: categoryId, exampleId: exampleId);
        }

        // Embed mode: show just the example without navigation or control panel
        if (isEmbed) {
          return EmbedWrapper(example: example);
        }

        // Normal mode: full browser with navigation
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
      theme: DemoTheme.light,
      darkTheme: DemoTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
