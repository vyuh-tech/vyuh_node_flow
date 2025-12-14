import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        final isMinimal = state.uri.queryParameters['minimal'] == 'true';
        final showHeader = state.uri.queryParameters['header'] != 'false';

        // Validate that the category and example exist
        final example = ExampleRegistry.findExample(categoryId, exampleId);
        if (example == null) {
          return ExampleNotFound(categoryId: categoryId, exampleId: exampleId);
        }

        // Embed mode: minimal wrapper for iframe embedding
        if (isEmbed) {
          if (isMinimal) {
            return EmbedWrapperMinimal(example: example);
          }
          return EmbedWrapper(
            example: example,
            showHeader: showHeader,
            onSourceTap: () {
              // Open source on GitHub
              // Could use url_launcher here
            },
          );
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
