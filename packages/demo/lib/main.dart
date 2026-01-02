import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'design_kit/theme.dart';
import 'embed_wrapper.dart';
import 'example_browser.dart';
import 'example_model.dart';
import 'example_not_found.dart';
import 'example_registry.dart';
import 'examples/hero_showcase.dart' deferred as hero_showcase;

void main() {
  runApp(const MyApp());
}

// Hero showcase examples (not in registry, accessed via direct routes)
final _heroExamples = {
  'image': Example(
    id: 'image',
    title: 'Image Effects Pipeline',
    description: 'Visual effects pipeline with image, color, and blur nodes',
    icon: Icons.auto_awesome,
    loader: () async {
      await hero_showcase.loadLibrary();
      return (_) => hero_showcase.HeroShowcaseExample();
    },
  ),
};

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
    // Direct route for hero showcase examples
    GoRoute(
      path: '/hero/:exampleId',
      builder: (context, state) {
        final exampleId = state.pathParameters['exampleId']!;
        final isEmbed = state.uri.queryParameters['embed'] == 'true';

        final example = _heroExamples[exampleId];
        if (example == null) {
          return ExampleNotFound(categoryId: 'hero', exampleId: exampleId);
        }

        // Hero examples are always shown in embed mode style (clean, no chrome)
        if (isEmbed) {
          return EmbedWrapper(example: example);
        }

        // Non-embed: wrap in scaffold with minimal chrome
        return Scaffold(
          body: EmbedContext(
            isEmbed: false,
            child: DeferredExampleLoader(example: example),
          ),
        );
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
