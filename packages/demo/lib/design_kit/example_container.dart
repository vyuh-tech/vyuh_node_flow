import 'package:flutter/material.dart';

import 'panels.dart';
import 'responsive.dart';
import 'stats_panel.dart';
import 'theme.dart';

/// A container that wraps each example with consistent styling.
///
/// Provides:
/// - A main content area for the graph editor
/// - A control panel on the right with example-specific controls
/// - Built-in graph statistics display
/// - Responsive layout (drawer on mobile, panel on desktop)
class ExampleContainer<TNode, TConnection> extends StatefulWidget {
  /// The title shown in the control panel header.
  final String title;

  /// Optional description shown below the title.
  final String? description;

  /// The main content widget (typically the NodeFlowEditor).
  final Widget child;

  /// Widgets to display in the control panel.
  final List<Widget> controls;

  /// Width of the control panel.
  final double panelWidth;

  /// Optional header actions for the control panel.
  final List<Widget>? headerActions;

  /// Whether to show the built-in stats panel.
  final bool showStats;

  /// Optional controller for stats display.
  final dynamic controller;

  /// Optional footer widget for the control panel.
  final Widget? footer;

  const ExampleContainer({
    super.key,
    required this.title,
    this.description,
    required this.child,
    required this.controls,
    this.panelWidth = 340,
    this.headerActions,
    this.showStats = true,
    this.controller,
    this.footer,
  });

  @override
  State<ExampleContainer<TNode, TConnection>> createState() =>
      _ExampleContainerState<TNode, TConnection>();
}

class _ExampleContainerState<TNode, TConnection>
    extends State<ExampleContainer<TNode, TConnection>> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = DemoResponsive.isMobile(context);

    // Build the control panel content
    final panelContent = _buildPanelContent(context);

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        body: widget.child,
        endDrawer: Drawer(width: widget.panelWidth, child: panelContent),
        floatingActionButton: _buildFab(context),
      );
    }

    // Desktop layout
    return Row(
      children: [
        // Main content
        Expanded(child: widget.child),
        // Control panel
        panelContent,
      ],
    );
  }

  Widget _buildPanelContent(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: widget.panelWidth,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(left: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(context, theme),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DemoTheme.spacing16),
              children: [
                // Description if provided
                if (widget.description != null) ...[
                  Text(
                    widget.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: DemoTheme.spacing20),
                ],
                // User controls
                ...widget.controls,
                // Stats panel
                if (widget.showStats && widget.controller != null) ...[
                  const SizedBox(height: DemoTheme.spacing24),
                  DemoStatsPanel(controller: widget.controller),
                ],
              ],
            ),
          ),
          // Footer
          if (widget.footer != null)
            Container(
              padding: const EdgeInsets.all(DemoTheme.spacing16),
              decoration: BoxDecoration(
                color: context.surfaceElevatedColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: widget.footer,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(DemoTheme.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 4,
            height: 24,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [DemoTheme.accent, DemoTheme.accentLight],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.headerActions != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.headerActions!,
            ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
      backgroundColor: DemoTheme.accent,
      foregroundColor: Colors.white,
      elevation: 2,
      child: const Icon(Icons.tune),
    );
  }
}

/// A simpler example wrapper without the control panel.
class SimpleExampleContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SimpleExampleContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      color: context.backgroundColor,
      child: child,
    );
  }
}

/// A section within the control panel with a header.
class ExampleSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const ExampleSection({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoSectionHeader(title: title, trailing: trailing),
        const SizedBox(height: DemoTheme.spacing12),
        ...children,
      ],
    );
  }
}

/// A control row with label and widget.
class ExampleControlRow extends StatelessWidget {
  final String label;
  final Widget child;
  final String? hint;

  const ExampleControlRow({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            child,
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.textTertiaryColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// A slider control with label and value display.
class ExampleSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double)? valueFormatter;
  final ValueChanged<double> onChanged;

  const ExampleSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.valueFormatter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue =
        valueFormatter?.call(value) ?? value.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.surfaceSubtleColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                displayValue,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// A dropdown control with label.
class ExampleDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const ExampleDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.surfaceSubtleColor,
            borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              style: theme.textTheme.bodySmall,
              dropdownColor: context.surfaceColor,
            ),
          ),
        ),
      ],
    );
  }
}
