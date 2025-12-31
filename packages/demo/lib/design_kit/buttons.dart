import 'package:flutter/material.dart';

import 'theme.dart';

/// Button variants for the design system
enum DemoButtonVariant {
  /// Filled button with accent color background
  filled,

  /// Outlined button with border
  outlined,

  /// Ghost button with no background
  ghost,

  /// Subtle button with muted background
  subtle,

  /// Tonal button - softer accent background
  tonal,
}

/// Button sizes
enum DemoButtonSize { small, medium, large }

/// A modern button component with multiple variants and sizes.
class DemoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final DemoButtonVariant variant;
  final DemoButtonSize size;
  final bool isLoading;
  final bool fullWidth;

  const DemoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = DemoButtonVariant.filled,
    this.size = DemoButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  });

  const DemoButton.filled({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = DemoButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = DemoButtonVariant.filled;

  const DemoButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = DemoButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = DemoButtonVariant.outlined;

  const DemoButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = DemoButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = DemoButtonVariant.ghost;

  const DemoButton.subtle({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = DemoButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = DemoButtonVariant.subtle;

  const DemoButton.tonal({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = DemoButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = DemoButtonVariant.tonal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    // Size-based values
    final (padding, iconSize, fontSize) = switch (size) {
      DemoButtonSize.small => (
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        14.0,
        12.0,
      ),
      DemoButtonSize.medium => (
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        16.0,
        13.0,
      ),
      DemoButtonSize.large => (
        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        18.0,
        14.0,
      ),
    };

    // Variant-based colors - improved contrast
    final (bgColor, fgColor, borderColor) = switch (variant) {
      DemoButtonVariant.filled => (
        onPressed != null ? DemoTheme.accent : context.borderColor,
        onPressed != null ? Colors.white : context.textTertiaryColor,
        Colors.transparent,
      ),
      DemoButtonVariant.outlined => (
        Colors.transparent,
        onPressed != null
            ? (isDark ? DemoTheme.accentLight : DemoTheme.accent)
            : context.textTertiaryColor,
        onPressed != null
            ? (isDark ? DemoTheme.accentLight : DemoTheme.accent).withValues(
                alpha: 0.5,
              )
            : context.borderColor,
      ),
      DemoButtonVariant.ghost => (
        Colors.transparent,
        onPressed != null
            ? (isDark ? DemoTheme.accentLight : DemoTheme.accent)
            : context.textTertiaryColor,
        Colors.transparent,
      ),
      DemoButtonVariant.subtle => (
        context.surfaceSubtleColor,
        onPressed != null
            ? context.textPrimaryColor
            : context.textTertiaryColor,
        context.borderSubtleColor,
      ),
      DemoButtonVariant.tonal => (
        onPressed != null
            ? (isDark
                  ? DemoTheme.accent.withValues(alpha: 0.2)
                  : DemoTheme.accent.withValues(alpha: 0.12))
            : context.surfaceSubtleColor,
        onPressed != null
            ? (isDark ? DemoTheme.accentLight : DemoTheme.accentDark)
            : context.textTertiaryColor,
        Colors.transparent,
      ),
    };

    final hoverColor = switch (variant) {
      DemoButtonVariant.filled => DemoTheme.accentDark,
      DemoButtonVariant.outlined =>
        (isDark ? DemoTheme.accentLight : DemoTheme.accent).withValues(
          alpha: 0.1,
        ),
      DemoButtonVariant.ghost =>
        (isDark ? DemoTheme.accentLight : DemoTheme.accent).withValues(
          alpha: 0.1,
        ),
      DemoButtonVariant.subtle =>
        isDark ? DemoTheme.darkSurfaceElevated : DemoTheme.lightBorder,
      DemoButtonVariant.tonal =>
        isDark
            ? DemoTheme.accent.withValues(alpha: 0.3)
            : DemoTheme.accent.withValues(alpha: 0.2),
    };

    Widget child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(fgColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: fontSize,
            color: fgColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
        hoverColor: hoverColor,
        splashColor: hoverColor,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
            border: borderColor != Colors.transparent
                ? Border.all(color: borderColor)
                : null,
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: fgColor),
            child: IconTheme(
              data: IconThemeData(color: fgColor, size: iconSize),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact icon button with hover effects.
class DemoIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final DemoButtonSize size;
  final Color? color;
  final bool isActive;

  const DemoIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = DemoButtonSize.medium,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final (iconSize, padding) = switch (size) {
      DemoButtonSize.small => (14.0, 6.0),
      DemoButtonSize.medium => (18.0, 8.0),
      DemoButtonSize.large => (22.0, 10.0),
    };

    final activeColor = DemoTheme.accent;
    final iconColor =
        color ??
        (isActive
            ? activeColor
            : (onPressed != null
                  ? context.textSecondaryColor
                  : context.textTertiaryColor));

    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.1)
        : Colors.transparent;

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
        hoverColor: context.surfaceSubtleColor,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// A button designed for grids - shows icon above label.
class DemoGridButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  const DemoGridButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null;

    final bgColor = isActive
        ? DemoTheme.accent.withValues(alpha: 0.1)
        : context.surfaceSubtleColor;
    final fgColor = isDisabled
        ? context.textTertiaryColor
        : isActive
        ? DemoTheme.accent
        : context.textSecondaryColor;
    final borderColor = isActive ? DemoTheme.accent : context.borderSubtleColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
        hoverColor: context.borderColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fgColor),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fgColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 2-column grid layout for buttons.
class DemoButtonGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double aspectRatio;

  const DemoButtonGrid({
    super.key,
    required this.children,
    this.spacing = 8,
    this.aspectRatio = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: children,
    );
  }
}

/// A segmented control for switching between options.
class DemoSegmentedControl<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;
  final IconData Function(T)? iconBuilder;

  const DemoSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? DemoTheme.darkBackground.withValues(alpha: 0.5)
            : DemoTheme.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option == selected;
          final icon = iconBuilder?.call(option);

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? DemoTheme.darkSurface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DemoTheme.radiusSmall),
                  boxShadow: isSelected ? context.shadowSmall : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected
                            ? (isDark
                                  ? DemoTheme.accentLight
                                  : DemoTheme.accent)
                            : context.textTertiaryColor,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      labelBuilder(option),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? context.textPrimaryColor
                            : context.textTertiaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A theme toggle switch for switching between light and dark mode.
class DemoThemeToggle extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const DemoThemeToggle({
    super.key,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? DemoTheme.darkBackground.withValues(alpha: 0.5)
            : DemoTheme.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(DemoTheme.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOption(
            icon: Icons.light_mode_rounded,
            isSelected: !isDark,
            onTap: () => onChanged(false),
          ),
          _ThemeOption(
            icon: Icons.dark_mode_rounded,
            isSelected: isDark,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? DemoTheme.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DemoTheme.radiusRound),
          boxShadow: isSelected ? context.shadowSmall : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? (isDark ? DemoTheme.accentLight : DemoTheme.accent)
              : context.textTertiaryColor,
        ),
      ),
    );
  }
}
