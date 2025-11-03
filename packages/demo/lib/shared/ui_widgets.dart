import 'package:flutter/material.dart';

import 'responsive.dart';

/// Reusable UI components for demo examples

/// Section title text (grey, small, uppercase-style)
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Control panel header with title
class ControlPanelHeader extends StatelessWidget {
  final String title;

  const ControlPanelHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Info card with title and content
class InfoCard extends StatelessWidget {
  final String title;
  final String content;

  const InfoCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard control button with icon and label
class ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const ControlButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: theme.textTheme.labelLarge),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

/// Grid button for 2x2 layouts
class GridButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const GridButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Helper to create a 2-column grid of buttons
class Grid2Cols extends StatelessWidget {
  final List<Widget> buttons;

  const Grid2Cols({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: buttons,
    );
  }
}

/// Control panel container (right-side panel)
class ControlPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double width;
  final List<Widget>? actions;

  const ControlPanel({
    super.key,
    required this.title,
    required this.children,
    this.width = 280,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with optional actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive control panel that adapts to screen size
/// On mobile: Shows a FAB that opens a drawer from the right
/// On tablet/desktop: Shows the panel always visible on the right
class ResponsiveControlPanel extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final double width;
  final List<Widget>? actions;
  final Widget child;

  const ResponsiveControlPanel({
    super.key,
    required this.title,
    required this.children,
    required this.child,
    this.width = 320,
    this.actions,
  });

  @override
  State<ResponsiveControlPanel> createState() => _ResponsiveControlPanelState();
}

class _ResponsiveControlPanelState extends State<ResponsiveControlPanel> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        body: widget.child,
        endDrawer: Drawer(
          width: widget.width,
          child: ControlPanel(
            title: widget.title,
            width: widget.width,
            actions: widget.actions,
            children: widget.children,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          tooltip: 'Controls',
          child: const Icon(Icons.tune),
        ),
      );
    }

    // Tablet/Desktop: Always show panel on the right
    return Row(
      children: [
        // Main content
        Expanded(child: widget.child),

        // Always visible panel
        ControlPanel(
          title: widget.title,
          width: widget.width,
          actions: widget.actions,
          children: widget.children,
        ),
      ],
    );
  }
}
