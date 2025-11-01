import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

import 'example_model.dart';

class ExampleNavigationState {
  final selectedExampleId = Observable<String?>(null);

  void selectExample(String exampleId) {
    runInAction(() => selectedExampleId.value = exampleId);
  }
}

class ExampleNavigation extends StatefulWidget {
  final List<ExampleCategory> categories;
  final ExampleNavigationState state;
  final void Function(Example example, String categoryId) onExampleSelected;

  const ExampleNavigation({
    super.key,
    required this.categories,
    required this.state,
    required this.onExampleSelected,
  });

  @override
  State<ExampleNavigation> createState() => _ExampleNavigationState();
}

class _ExampleNavigationState extends State<ExampleNavigation> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: ListView.builder(
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                if (category.examples.isEmpty) return const SizedBox.shrink();

                return _buildCategorySection(theme, category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ThemeData theme, ExampleCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
          ),
          child: Text(
            category.title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...category.examples.map(
          (example) => _buildExampleItem(theme, category, example),
        ),
      ],
    );
  }

  Widget _buildExampleItem(
    ThemeData theme,
    ExampleCategory category,
    Example example,
  ) {
    return Observer(
      builder: (_) {
        final isSelected = widget.state.selectedExampleId.value == example.id;

        return InkWell(
          onTap: () {
            widget.state.selectExample(example.id);
            widget.onExampleSelected(example, category.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                if (example.icon != null) ...[
                  Icon(
                    example.icon,
                    size: 16,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    example.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Vyuh Node Flow',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          _buildIconButton(
            theme,
            icon: FontAwesomeIcons.github,
            tooltip: 'View on GitHub',
            url: 'https://github.com/vyuh-tech/vyuh_node_flow',
          ),
          const SizedBox(width: 4),
          _buildIconButton(
            theme,
            icon: FontAwesomeIcons.dartLang,
            tooltip: 'View on Pub.dev',
            url: 'https://pub.dev/packages/vyuh_node_flow',
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    ThemeData theme, {
    required IconData icon,
    required String tooltip,
    required String url,
  }) {
    return IconButton(
      icon: FaIcon(icon, size: 16),
      color: theme.colorScheme.primary,
      tooltip: tooltip,
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      iconSize: 16,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }
}
