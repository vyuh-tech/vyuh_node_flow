import 'package:flutter/material.dart';

import 'theme.dart';

/// A modern section header with optional action.
class DemoSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const DemoSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: DemoTheme.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A modern card with subtle styling.
class DemoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool hasBorder;
  final bool hasShadow;
  final VoidCallback? onTap;

  const DemoCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.hasBorder = true,
    this.hasShadow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(DemoTheme.spacing16),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.surfaceColor,
        borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
        border: hasBorder ? Border.all(color: context.borderColor) : null,
        boxShadow: hasShadow ? context.shadowSmall : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// An info card with title, description, and optional icon.
class DemoInfoCard extends StatelessWidget {
  final String? title;
  final String content;
  final IconData? icon;
  final Color? iconColor;
  final DemoInfoCardVariant variant;

  const DemoInfoCard({
    super.key,
    this.title,
    required this.content,
    this.icon,
    this.iconColor,
    this.variant = DemoInfoCardVariant.neutral,
  });

  const DemoInfoCard.info({super.key, this.title, required this.content})
    : icon = Icons.info_outline,
      iconColor = null,
      variant = DemoInfoCardVariant.info;

  const DemoInfoCard.success({super.key, this.title, required this.content})
    : icon = Icons.check_circle_outline,
      iconColor = null,
      variant = DemoInfoCardVariant.success;

  const DemoInfoCard.warning({super.key, this.title, required this.content})
    : icon = Icons.warning_amber_outlined,
      iconColor = null,
      variant = DemoInfoCardVariant.warning;

  const DemoInfoCard.error({super.key, this.title, required this.content})
    : icon = Icons.error_outline,
      iconColor = null,
      variant = DemoInfoCardVariant.error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (bgColor, borderColor, defaultIconColor) = switch (variant) {
      DemoInfoCardVariant.neutral => (
        context.surfaceSubtleColor,
        context.borderColor,
        context.textSecondaryColor,
      ),
      DemoInfoCardVariant.info => (
        DemoTheme.info.withValues(alpha: 0.08),
        DemoTheme.info.withValues(alpha: 0.3),
        DemoTheme.info,
      ),
      DemoInfoCardVariant.success => (
        DemoTheme.success.withValues(alpha: 0.08),
        DemoTheme.success.withValues(alpha: 0.3),
        DemoTheme.success,
      ),
      DemoInfoCardVariant.warning => (
        DemoTheme.warning.withValues(alpha: 0.08),
        DemoTheme.warning.withValues(alpha: 0.3),
        DemoTheme.warning,
      ),
      DemoInfoCardVariant.error => (
        DemoTheme.error.withValues(alpha: 0.08),
        DemoTheme.error.withValues(alpha: 0.3),
        DemoTheme.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(DemoTheme.spacing12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? defaultIconColor),
            const SizedBox(width: DemoTheme.spacing12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
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

enum DemoInfoCardVariant { neutral, info, success, warning, error }

/// The main control panel that appears on the side.
class DemoControlPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double width;
  final List<Widget>? headerActions;
  final Widget? footer;

  const DemoControlPanel({
    super.key,
    required this.title,
    required this.children,
    this.width = 320,
    this.headerActions,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(left: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(DemoTheme.spacing16),
            decoration: BoxDecoration(
              color: context.surfaceElevatedColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (headerActions != null)
                  Row(mainAxisSize: MainAxisSize.min, children: headerActions!),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DemoTheme.spacing16),
              children: _buildChildrenWithSpacing(children),
            ),
          ),
          // Footer
          if (footer != null) ...[
            Container(
              padding: const EdgeInsets.all(DemoTheme.spacing16),
              decoration: BoxDecoration(
                color: context.surfaceElevatedColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: footer,
            ),
          ],
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
        result.add(const SizedBox(height: DemoTheme.spacing16));
      }
    }
    return result;
  }
}

/// A collapsible section within a panel.
class DemoCollapsibleSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Widget? trailing;

  const DemoCollapsibleSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.trailing,
  });

  @override
  State<DemoCollapsibleSection> createState() => _DemoCollapsibleSectionState();
}

class _DemoCollapsibleSectionState extends State<DemoCollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _iconRotation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(DemoTheme.radiusSmall),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
        // Content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildChildrenWithSpacing(widget.children),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  List<Widget> _buildChildrenWithSpacing(List<Widget> widgets) {
    if (widgets.isEmpty) return widgets;

    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(const SizedBox(height: 8));
      }
    }
    return result;
  }
}

/// A key-value display row for stats.
class DemoStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool isMono;

  const DemoStatRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.isMono = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: context.textTertiaryColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: isMono ? 'JetBrains Mono' : null,
              color: valueColor ?? context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A badge/chip for displaying status or counts.
class DemoBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool isSmall;

  const DemoBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = color ?? DemoTheme.accent;
    final padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final fontSize = isSmall ? 10.0 : 11.0;
    final iconSize = isSmall ? 10.0 : 12.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DemoTheme.radiusSmall),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: bgColor),
            SizedBox(width: isSmall ? 3 : 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: bgColor,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// A horizontal divider with optional label.
class DemoDivider extends StatelessWidget {
  final String? label;
  final EdgeInsetsGeometry padding;

  const DemoDivider({
    super.key,
    this.label,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (label == null) {
      return Padding(
        padding: padding,
        child: Divider(height: 1, color: context.borderColor),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: context.borderColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.textTertiaryColor,
              ),
            ),
          ),
          Expanded(child: Divider(height: 1, color: context.borderColor)),
        ],
      ),
    );
  }
}
