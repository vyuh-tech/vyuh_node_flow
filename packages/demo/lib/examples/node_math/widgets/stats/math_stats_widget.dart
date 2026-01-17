library;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../../../design_kit/theme.dart';
import '../../presentation/state.dart';

class MathStatsWidget extends StatelessWidget {
  final MathState state;

  const MathStatsWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = state.controller.stats;
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return _MathStatsSection(stats: stats);
  }
}

class _MathStatsSection extends StatelessWidget {
  final StatsExtension stats;

  const _MathStatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: context.surfaceSubtleColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.zoom_in, size: 10, color: context.textTertiaryColor),
                const SizedBox(width: 4),
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
          ),
        ],
      ),
    );
  }
}

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
