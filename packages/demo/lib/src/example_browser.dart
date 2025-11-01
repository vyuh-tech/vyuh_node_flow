import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'example_detail_view.dart';
import 'example_model.dart';
import 'example_navigation.dart';
import 'example_registry.dart';

class ExampleBrowser extends StatefulWidget {
  final List<ExampleCategory> categories;
  final String categoryId;
  final String exampleId;

  const ExampleBrowser({
    super.key,
    required this.categories,
    required this.categoryId,
    required this.exampleId,
  });

  @override
  State<ExampleBrowser> createState() => _ExampleBrowserState();
}

class _ExampleBrowserState extends State<ExampleBrowser> {
  late final ExampleNavigationState _navState;
  Example? _selectedExample;

  @override
  void initState() {
    super.initState();
    _navState = ExampleNavigationState();
    _loadExample(widget.categoryId, widget.exampleId);
  }

  @override
  void didUpdateWidget(ExampleBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.exampleId != widget.exampleId) {
      _loadExample(widget.categoryId, widget.exampleId);
    }
  }

  void _loadExample(String categoryId, String exampleId) {
    final example = ExampleRegistry.findExample(categoryId, exampleId);
    if (example != null) {
      setState(() {
        _selectedExample = example;
      });
      _navState.selectExample(exampleId);
    }
  }

  void _onExampleSelected(Example example, String categoryId) {
    // Navigate using GoRouter which will update the URL
    context.go('/$categoryId/${example.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          ExampleNavigation(
            categories: widget.categories,
            state: _navState,
            onExampleSelected: _onExampleSelected,
          ),
          Expanded(child: ExampleDetailView(example: _selectedExample)),
        ],
      ),
    );
  }
}
