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
  String? _selectedCategoryId;
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
        _selectedCategoryId = categoryId;
      });
      _navState.selectExample(exampleId);
    }
  }

  void _onExampleSelected(Example example, String categoryId) {
    // Navigate using GoRouter which will update the URL
    context.go('/$categoryId/${example.id}');

    // Close drawer on mobile after selection
    if (Responsive.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: isMobile ? _buildMobileAppBar() : null,
      drawer: (isMobile || isTablet) ? _buildDrawer() : null,
      body: Row(
        children: [
          // Desktop: Show navigation sidebar
          if (!isMobile && !isTablet)
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

  PreferredSizeWidget _buildMobileAppBar() {
    final theme = Theme.of(context);

    return AppBar(
      title: _buildExampleDropdown(),
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

  Widget _buildExampleDropdown() {
    final theme = Theme.of(context);

    // Build a list that includes both category headers and examples
    final List<Map<String, dynamic>> allItems = [];

    for (final category in widget.categories) {
      // Add category header
      allItems.add({'type': 'category', 'category': category});

      // Add examples under this category
      for (final example in category.examples) {
        allItems.add({
          'type': 'example',
          'category': category,
          'example': example,
        });
      }
    }

    // Find current index based on selected example
    final currentIndex = allItems.indexWhere(
      (item) =>
          item['type'] == 'example' &&
          item['example'] == _selectedExample &&
          (item['category'] as ExampleCategory).id == _selectedCategoryId,
    );

    return DropdownButton<int>(
      value: currentIndex >= 0 ? currentIndex : null,
      isExpanded: true,
      underline: const SizedBox(),
      dropdownColor: theme.colorScheme.surfaceContainerHigh,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      items: allItems.asMap().entries.map((entry) {
        final item = entry.value;

        if (item['type'] == 'category') {
          // Category header - disabled
          final category = item['category'] as ExampleCategory;
          return DropdownMenuItem<int>(
            value: entry.key,
            enabled: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                category.title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        } else {
          // Regular example item
          final example = item['example'] as Example;
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  if (example.icon != null) ...[
                    Icon(example.icon, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      example.title,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }).toList(),
      onChanged: (index) {
        if (index != null) {
          final item = allItems[index];
          // Only handle example selections (categories are disabled)
          if (item['type'] == 'example') {
            final category = item['category'] as ExampleCategory;
            final example = item['example'] as Example;
            _onExampleSelected(example, category.id);
          }
        }
      },
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
