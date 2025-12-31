import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'panels.dart';
import 'theme.dart';

/// A stats panel that displays graph statistics using the StatsExtension.
///
/// Shows node counts, connection counts, selection state, viewport info,
/// and other useful metrics from the `StatsExtension`.
class DemoStatsPanel extends StatelessWidget {
  /// The NodeFlowController to display stats for.
  final NodeFlowController controller;

  /// Whether to show in compact mode.
  final bool compact;

  const DemoStatsPanel({
    super.key,
    required this.controller,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    if (stats == null) {
      return DemoCollapsibleSection(
        title: 'Graph Statistics',
        initiallyExpanded: !compact,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Add StatsExtension to enable statistics',
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
            ),
          ),
        ],
      );
    }

    return DemoCollapsibleSection(
      title: 'Graph Statistics',
      initiallyExpanded: !compact,
      children: [_StatsContent(stats: stats, compact: compact)],
    );
  }
}

class _StatsContent extends StatelessWidget {
  final StatsExtension stats;
  final bool compact;

  const _StatsContent({required this.stats, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Observer(
      builder: (context) {
        // Access stats via StatsExtension - all reactive via observables
        final nodeCount = stats.nodeCount;
        final connectionCount = stats.connectionCount;
        final selectedCount = stats.selectedCount;
        final nodesByType = stats.nodesByType;
        final vp = stats.viewport.value;
        final currentZoom = vp.zoom;
        final currentPan = Offset(vp.x, vp.y);

        if (compact) {
          return _buildCompactStats(
            context,
            nodeCount: nodeCount,
            connectionCount: connectionCount,
            selectedCount: selectedCount,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main stats grid
            _buildStatsGrid(
              context,
              nodeCount: nodeCount,
              connectionCount: connectionCount,
              selectedCount: selectedCount,
            ),
            const SizedBox(height: DemoTheme.spacing16),

            // Viewport info
            DemoCard(
              padding: const EdgeInsets.all(DemoTheme.spacing12),
              backgroundColor: context.surfaceSubtleColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Viewport',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DemoStatRow(
                    label: 'Zoom',
                    value: '${(currentZoom * 100).toStringAsFixed(0)}%',
                    icon: Icons.zoom_in,
                  ),
                  DemoStatRow(
                    label: 'Pan X',
                    value: currentPan.dx.toStringAsFixed(0),
                    icon: Icons.swap_horiz,
                  ),
                  DemoStatRow(
                    label: 'Pan Y',
                    value: currentPan.dy.toStringAsFixed(0),
                    icon: Icons.swap_vert,
                  ),
                ],
              ),
            ),

            // Node types breakdown if multiple types exist
            if (nodesByType.length > 1) ...[
              const SizedBox(height: DemoTheme.spacing16),
              DemoCard(
                padding: const EdgeInsets.all(DemoTheme.spacing12),
                backgroundColor: context.surfaceSubtleColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Node Types',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...nodesByType.entries.map(
                      (entry) => DemoStatRow(
                        label: entry.key,
                        value: entry.value.toString(),
                        icon: _getIconForType(entry.key),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid(
    BuildContext context, {
    required int nodeCount,
    required int connectionCount,
    required int selectedCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Nodes',
            value: nodeCount.toString(),
            icon: Icons.circle_outlined,
            color: DemoTheme.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Edges',
            value: connectionCount.toString(),
            icon: Icons.timeline,
            color: DemoTheme.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Selected',
            value: selectedCount.toString(),
            icon: Icons.check_circle_outline,
            color: selectedCount > 0 ? DemoTheme.accent : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStats(
    BuildContext context, {
    required int nodeCount,
    required int connectionCount,
    required int selectedCount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CompactStat(
          icon: Icons.circle_outlined,
          value: nodeCount.toString(),
          label: 'nodes',
        ),
        _CompactStat(
          icon: Icons.timeline,
          value: connectionCount.toString(),
          label: 'edges',
        ),
        if (selectedCount > 0)
          _CompactStat(
            icon: Icons.check_circle,
            value: selectedCount.toString(),
            label: 'selected',
            color: DemoTheme.accent,
          ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('input') || lowerType.contains('source')) {
      return Icons.input;
    }
    if (lowerType.contains('output') || lowerType.contains('sink')) {
      return Icons.output;
    }
    if (lowerType.contains('process') || lowerType.contains('transform')) {
      return Icons.settings;
    }
    if (lowerType.contains('decision') || lowerType.contains('filter')) {
      return Icons.call_split;
    }
    if (lowerType.contains('group')) {
      return Icons.folder_outlined;
    }
    if (lowerType.contains('comment') || lowerType.contains('note')) {
      return Icons.sticky_note_2_outlined;
    }
    return Icons.circle_outlined;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? context.textSecondaryColor;

    return Container(
      padding: const EdgeInsets.all(DemoTheme.spacing12),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DemoTheme.radiusMedium),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: cardColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
              color: cardColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const _CompactStat({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statColor = color ?? context.textSecondaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: statColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'JetBrains Mono',
            color: statColor,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.textTertiaryColor,
          ),
        ),
      ],
    );
  }
}

/// A simple inline stats display for headers.
class DemoInlineStats extends StatelessWidget {
  final NodeFlowController controller;

  const DemoInlineStats({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    if (stats == null) return const SizedBox.shrink();

    return Observer(
      builder: (context) {
        final nodeCount = stats.nodeCount;
        final connectionCount = stats.connectionCount;
        final selectedCount = stats.selectedCount;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DemoBadge(
              label: '$nodeCount nodes',
              color: DemoTheme.info,
              isSmall: true,
            ),
            const SizedBox(width: 6),
            DemoBadge(
              label: '$connectionCount edges',
              color: DemoTheme.success,
              isSmall: true,
            ),
            if (selectedCount > 0) ...[
              const SizedBox(width: 6),
              DemoBadge(
                label: '$selectedCount selected',
                color: DemoTheme.accent,
                isSmall: true,
              ),
            ],
          ],
        );
      },
    );
  }
}
