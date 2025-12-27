import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'example_detail_view.dart';
import 'example_model.dart';
import 'example_navigation.dart';
import 'example_registry.dart';
import 'shared/responsive.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

    // Close drawer on mobile/tablet after selection
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final useDrawerNavigation = isMobile || isTablet;

    return Scaffold(
      key: _scaffoldKey,
      appBar: useDrawerNavigation ? _buildCompactAppBar() : null,
      drawer: useDrawerNavigation ? _buildDrawer() : null,
      body: Row(
        children: [
          // Desktop: Show navigation sidebar
          if (!useDrawerNavigation)
            ExampleNavigation(
              categories: widget.categories,
              state: _navState,
              onExampleSelected: _onExampleSelected,
            ),

          // Main content
          Expanded(child: ExampleDetailView(example: _selectedExample)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCompactAppBar() {
    final theme = Theme.of(context);

    return AppBar(
      title: _selectedExample != null
          ? Row(
              children: [
                if (_selectedExample!.icon != null) ...[
                  Icon(_selectedExample!.icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedExample!.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedExample!.description.isNotEmpty)
                        Text(
                          _selectedExample!.description,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            )
          : const Text('Examples'),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ExampleNavigation(
        categories: widget.categories,
        state: _navState,
        onExampleSelected: _onExampleSelected,
      ),
    );
  }
}
