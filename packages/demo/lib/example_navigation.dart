import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

import 'design_kit/theme.dart';
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
    final isInDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;

    return Container(
      width: isInDrawer ? null : 320,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: isInDrawer
            ? null
            : Border(right: BorderSide(color: context.borderColor, width: 1)),
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
          decoration: BoxDecoration(color: context.surfaceSubtleColor),
          child: Text(
            category.title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textTertiaryColor,
              letterSpacing: 0.8,
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
    final isDark = context.isDark;

    return Observer(
      builder: (_) {
        final isSelected = widget.state.selectedExampleId.value == example.id;
        final selectedBgColor = DemoTheme.accent.withValues(
          alpha: isDark ? 0.2 : 0.12,
        );
        final selectedFgColor = isDark
            ? DemoTheme.accentLight
            : DemoTheme.accent;

        return InkWell(
          onTap: () {
            widget.state.selectExample(example.id);
            widget.onExampleSelected(example, category.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? selectedBgColor : Colors.transparent,
            ),
            child: Row(
              children: [
                if (example.icon != null) ...[
                  Icon(
                    example.icon,
                    size: 16,
                    color: isSelected
                        ? selectedFgColor
                        : context.textSecondaryColor,
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
                          ? selectedFgColor
                          : context.textPrimaryColor,
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
        color: context.surfaceElevatedColor,
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Vyuh Node Flow',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
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
    final isDark = context.isDark;

    return IconButton(
      icon: FaIcon(icon, size: 16),
      color: isDark ? DemoTheme.accentLight : DemoTheme.accent,
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
