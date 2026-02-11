import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../design_kit/theme.dart';
import '../embed_wrapper.dart';
import '../example_detail_view.dart';
import 'responsive.dart';

/// Reusable UI components for demo examples

/// Section title strip that spans full width
/// Can display text or custom content (like counts/badges)
class SectionTitle extends StatelessWidget {
  final String? title;
  final Widget? child;

  const SectionTitle(this.title, {super.key}) : child = null;

  const SectionTitle.custom({super.key, required this.child}) : title = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: DemoTheme.accent.withValues(alpha: isDark ? 0.08 : 0.05),
      ),
      child:
          child ??
          Text(
            title!.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: (isDark ? DemoTheme.accentLight : DemoTheme.accent)
                  .withValues(alpha: 0.7),
              letterSpacing: 0.8,
            ),
          ),
    );
  }
}

/// Wrapper for section content with padding on all sides
/// Use SectionTitle for headers and SectionContent for content items
class SectionContent extends StatelessWidget {
  final Widget child;

  const SectionContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: child);
  }
}

/// A faint divider for separating subsections within a SectionContent
/// Use between logical groups of controls within the same section
class SubsectionDivider extends StatelessWidget {
  const SubsectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
      ),
    );
  }
}

/// Styled chip button with better contrast for selection
class StyledChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  const StyledChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    final selectedBg = DemoTheme.accent.withValues(alpha: isDark ? 0.35 : 0.2);
    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final selectedFg = isDark ? DemoTheme.accentLight : DemoTheme.accent;
    final unselectedFg = context.textPrimaryColor;
    final borderColor = selected
        ? selectedFg.withValues(alpha: 0.4)
        : (isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.12));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected != null ? () => onSelected!(!selected) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 14, color: selectedFg),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 14, color: unselectedFg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? selectedFg : unselectedFg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
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
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? DemoTheme.info.withValues(alpha: 0.08)
            : DemoTheme.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DemoTheme.info.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: DemoTheme.info),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard control button with icon and label - improved contrast
class ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDestructive;

  const ControlButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final isEnabled = onPressed != null;

    // Use tonal style with stronger contrast
    final bgColor = isDestructive
        ? DemoTheme.error.withValues(alpha: isDark ? 0.25 : 0.15)
        : DemoTheme.accent.withValues(alpha: isDark ? 0.25 : 0.15);
    final fgColor = isEnabled
        ? (isDestructive
              ? (isDark ? DemoTheme.errorLight : DemoTheme.error)
              : (isDark ? DemoTheme.accentLight : DemoTheme.accent))
        : context.textTertiaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: bgColor.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid button for 2x2 layouts - improved contrast
class GridButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  const GridButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final isEnabled = onPressed != null;

    // Stronger contrast for better visibility
    final bgColor = isActive
        ? DemoTheme.accent.withValues(alpha: isDark ? 0.3 : 0.18)
        : context.surfaceSubtleColor;
    final fgColor = !isEnabled
        ? context.textTertiaryColor
        : isActive
        ? (isDark ? DemoTheme.accentLight : DemoTheme.accent)
        : context.textPrimaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: context.borderColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? (isDark ? DemoTheme.accentLight : DemoTheme.accent)
                        .withValues(alpha: 0.3)
                  : context.borderSubtleColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fgColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
      childAspectRatio: 3.0, // Horizontal buttons need wider aspect ratio
      children: buttons,
    );
  }
}

/// Reusable widget for selecting connection styles in the sidebar
class ConnectionStyleSelector extends StatelessWidget {
  final NodeFlowTheme theme;
  final ValueChanged<NodeFlowTheme> onThemeChanged;

  const ConnectionStyleSelector({
    super.key,
    required this.theme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Connection Style'),
        SectionContent(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ConnectionStyles.all
                .where((style) => style != ConnectionStyles.customBezier)
                .map((style) {
                  final isSelected = theme.connectionTheme.style == style;
                  return StyledChip(
                    label: style.displayName,
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        final currentAnimationEffect =
                            theme.connectionTheme.animationEffect;
                        final currentTempAnimationEffect =
                            theme.temporaryConnectionTheme.animationEffect;
                        onThemeChanged(
                          theme.copyWith(
                            connectionTheme: theme.connectionTheme.copyWith(
                              style: style,
                              animationEffect: currentAnimationEffect,
                            ),
                            temporaryConnectionTheme: theme
                                .temporaryConnectionTheme
                                .copyWith(
                                  style: style,
                                  animationEffect: currentTempAnimationEffect,
                                ),
                          ),
                        );
                      }
                    },
                  );
                })
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// Control panel container (right-side panel) with optional header
class ControlPanel extends StatelessWidget {
  final List<Widget> children;
  final double width;
  final Widget? footer;

  /// Optional header with example metadata
  final String? headerTitle;
  final String? headerSubtitle;
  final IconData? headerIcon;

  const ControlPanel({
    super.key,
    required this.children,
    this.width = 300,
    this.footer,
    this.headerTitle,
    this.headerSubtitle,
    this.headerIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(left: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Example header
          if (headerTitle != null)
            _ExampleHeader(
              title: headerTitle!,
              subtitle: headerSubtitle,
              icon: headerIcon,
            ),
          // Scrollable controls area (no horizontal padding - sections handle it)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: _buildChildrenWithSpacing(children),
            ),
          ),
          // Fixed footer
          ?footer,
        ],
      ),
    );
  }

  List<Widget> _buildChildrenWithSpacing(List<Widget> widgets) {
    if (widgets.isEmpty) return widgets;
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(const SizedBox(height: 12));
      }
    }
    return result;
  }
}

class _ExampleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const _ExampleHeader({required this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DemoTheme.accent.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? DemoTheme.accentLight : DemoTheme.accent,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed footer for the control panel with comprehensive stats and reset button
class ControlPanelFooter extends StatelessWidget {
  final NodeFlowController? controller;
  final VoidCallback? onReset;

  const ControlPanelFooter({super.key, this.controller, this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Comprehensive stats section (uses StatsPlugin)
          if (controller?.stats != null)
            _ComprehensiveStats(stats: controller!.stats!),
          // Reset button
          if (onReset != null) _ResetExampleButton(onPressed: onReset!),
        ],
      ),
    );
  }
}

class _ComprehensiveStats extends StatelessWidget {
  final StatsPlugin stats;

  const _ComprehensiveStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 12,
                color: context.textTertiaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'STATS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  fontSize: 9,
                  color: context.textTertiaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Main stats - compact wrapping chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Observer(
                builder: (_) => _StatChip(
                  label: 'nodes',
                  value: stats.nodeCount.toString(),
                  icon: Icons.square_outlined,
                  color: DemoTheme.info,
                ),
              ),
              Observer(
                builder: (_) => _StatChip(
                  label: 'edges',
                  value: stats.connectionCount.toString(),
                  icon: Icons.timeline,
                  color: DemoTheme.success,
                ),
              ),
              Observer(
                builder: (_) => _StatChip(
                  label: 'selected',
                  value: stats.selectedNodeCount.toString(),
                  icon: Icons.check_circle_outline,
                  color: stats.hasSelection
                      ? (isDark ? DemoTheme.accentLight : DemoTheme.accent)
                      : context.textTertiaryColor,
                ),
              ),
              Observer(
                builder: (_) => _StatChip(
                  label: 'visible',
                  value: stats.nodesInViewport.toString(),
                  icon: Icons.visibility_outlined,
                  color: DemoTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Viewport info - compact inline
          _ViewportInfo(stats: stats),
        ],
      ),
    );
  }
}

/// Viewport info display showing zoom, pan, and bounds
/// Each reactive property is wrapped in its own Observer for granular updates.
class _ViewportInfo extends StatelessWidget {
  final StatsPlugin stats;

  const _ViewportInfo({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: context.surfaceSubtleColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zoom and pan - each with granular Observer
          Row(
            children: [
              Icon(Icons.zoom_in, size: 10, color: context.textTertiaryColor),
              const SizedBox(width: 4),
              // Observer around zoomPercent
              Observer(
                builder: (_) => Text(
                  '${stats.zoomPercent}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? DemoTheme.accentLight : DemoTheme.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_with, size: 10, color: context.textTertiaryColor),
              const SizedBox(width: 4),
              // Observer around pan
              Observer(
                builder: (_) {
                  final pan = stats.pan;
                  return Text(
                    '${pan.dx.toInt()}, ${pan.dy.toInt()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: context.textTertiaryColor,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Bounds - with granular Observer
          Row(
            children: [
              Icon(Icons.crop_free, size: 10, color: context.textTertiaryColor),
              const SizedBox(width: 4),
              // Observer around boundsSummary
              Observer(
                builder: (_) => Text(
                  stats.boundsSummary,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: context.textTertiaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact inline stat chip for displaying count metrics.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: context.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetExampleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ResetExampleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.borderColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restart_alt_rounded,
                size: 14,
                color: context.textSecondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Reset Example',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive control panel that adapts to screen size
/// On mobile: Shows a FAB that opens a drawer from the right
/// On tablet/Desktop: Shows the panel always visible on the right
class ResponsiveControlPanel extends StatefulWidget {
  final List<Widget> children;
  final double width;
  final Widget child;

  /// The controller for stats display in footer (optional).
  /// Must have StatsPlugin attached to show graph statistics.
  final NodeFlowController? controller;

  /// Callback for reset button (optional - if provided, shows reset button)
  final VoidCallback? onReset;

  /// Optional header with example metadata (shown at top of panel)
  final String? headerTitle;
  final String? headerSubtitle;
  final IconData? headerIcon;

  // Legacy parameters (deprecated but kept for compatibility)
  @Deprecated('Use headerTitle instead. Will be removed in future.')
  final String? title;
  @Deprecated('Actions are no longer displayed. Will be removed in future.')
  final List<Widget>? actions;

  const ResponsiveControlPanel({
    super.key,
    required this.children,
    required this.child,
    this.width = 300,
    this.controller,
    this.onReset,
    this.headerTitle,
    this.headerSubtitle,
    this.headerIcon,
    @Deprecated('Use headerTitle instead') this.title,
    @Deprecated('Actions are no longer displayed') this.actions,
  });

  @override
  State<ResponsiveControlPanel> createState() => _ResponsiveControlPanelState();
}

class _ResponsiveControlPanelState extends State<ResponsiveControlPanel> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget? _buildFooter() {
    if (widget.controller == null && widget.onReset == null) {
      return null;
    }
    return ControlPanelFooter(
      controller: widget.controller,
      onReset: widget.onReset,
    );
  }

  @override
  Widget build(BuildContext context) {
    // In embed mode, just show the child without any chrome
    if (EmbedContext.of(context)) {
      return widget.child;
    }

    final isMobile = Responsive.isMobile(context);

    // Auto-read from ExampleContext if header params aren't provided
    final example = ExampleContext.maybeOf(context);
    final headerTitle = widget.headerTitle ?? example?.title;
    final headerSubtitle = widget.headerSubtitle ?? example?.description;
    final headerIcon = widget.headerIcon ?? example?.icon;

    if (isMobile) {
      // On mobile, the app bar already shows the example info,
      // so we don't show the header in the control panel drawer
      return Scaffold(
        key: _scaffoldKey,
        body: widget.child,
        endDrawer: Drawer(
          width: widget.width,
          child: SafeArea(
            child: ControlPanel(
              width: widget.width,
              footer: _buildFooter(),
              children: widget.children,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          tooltip: 'Controls',
          backgroundColor: context.surfaceElevatedColor,
          foregroundColor: context.textPrimaryColor,
          elevation: 2,
          child: const Icon(Icons.tune, size: 20),
        ),
      );
    }

    // Tablet/Desktop: Always show panel on the right
    return Row(
      children: [
        // Main content
        Expanded(child: widget.child),

        // Always visible panel with optional header
        ControlPanel(
          width: widget.width,
          footer: _buildFooter(),
          headerTitle: headerTitle,
          headerSubtitle: headerSubtitle,
          headerIcon: headerIcon,
          children: widget.children,
        ),
      ],
    );
  }
}

/// Mixin for examples that can be reset to their initial state.
///
/// Provides a consistent pattern for initialization and reset across all examples.
/// Override [initExample] to set up the initial graph state.
///
/// Usage:
/// ```dart
/// class _MyExampleState extends State<MyExample> with ResettableExampleMixin {
///   late final NodeFlowController _controller;
///
///   @override
///   NodeFlowController get controller => _controller;
///
///   @override
///   void initExample() {
///     controller.clearGraph();
///     // Add initial nodes and connections
///     controller.addNode(...);
///     controller.addConnection(...);
///   }
/// }
/// ```
mixin ResettableExampleMixin<T extends StatefulWidget> on State<T> {
  /// The controller for this example
  NodeFlowController get controller;

  /// Initialize (or reinitialize) the example to its initial state.
  ///
  /// This method is called:
  /// 1. On first build (via initState)
  /// 2. When the reset button is pressed
  ///
  /// Override this to set up your initial graph state.
  /// The controller will be cleared before this is called on reset.
  void initExample();

  /// Resets the example to its initial state.
  ///
  /// Clears the graph and calls [initExample] to restore initial state.
  void resetExample() {
    controller.clearGraph();
    initExample();
    controller.resetViewport();
  }
}
