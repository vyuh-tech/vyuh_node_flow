import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// Example of a Figma-style layering panel.
///
/// Features:
/// - Overlapping cards so stacking order is visible
/// - Side panel lists nodes from front to back
/// - Bring to front, send to back, and step reorder
class LayeringPanelExample extends StatefulWidget {
  const LayeringPanelExample({super.key});

  @override
  State<LayeringPanelExample> createState() => _LayeringPanelExampleState();
}

class _LayeringPanelExampleState extends State<LayeringPanelExample> {
  late final NodeFlowController<Map<String, dynamic>, dynamic> controller;
  late final NodeFlowTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    controller = NodeFlowController<Map<String, dynamic>, dynamic>(
      config: NodeFlowConfig(),
    );
    _setupExampleGraph();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetViewport();
    });
  }

  void _setupExampleGraph() {
    controller
      ..addNode(_card('card-back', 'Back', 0, const Offset(160, 120)))
      ..addNode(_card('card-mid', 'Middle', 1, const Offset(210, 170)))
      ..addNode(_card('card-front', 'Front', 2, const Offset(260, 220)))
      ..addNode(_card('card-top', 'Top', 3, const Offset(310, 270)));
  }

  Node<Map<String, dynamic>> _card(
    String id,
    String title,
    int zIndex,
    Offset position,
  ) {
    return Node<Map<String, dynamic>>(
      id: id,
      type: 'card',
      position: position,
      size: const Size(180, 110),
      initialZIndex: zIndex,
      data: {'title': title},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: controller,
      onReset: () {
        controller.clearGraph();
        _setupExampleGraph();
      },
      child: Stack(
        children: [
          NodeFlowEditor<Map<String, dynamic>, dynamic>(
            controller: controller,
            theme: _theme,
            nodeBuilder: (context, node) =>
                _NodeWidget(node: node, nodeFlowTheme: _theme),
          ),
        ],
      ),
      children: [
        const SectionTitle('About'),
        const SectionContent(
          child: InfoCard(
            title: 'Instructions',
            content:
                'Cards overlap so stacking order is visible. The list is front '
                'to back. Use the buttons to bring a node forward or send it back.',
          ),
        ),
        const SectionTitle('Layers'),
        SectionContent(child: _LayerList(controller: controller)),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _NodeWidget extends StatelessWidget {
  const _NodeWidget({required this.node, required this.nodeFlowTheme});

  final Node<Map<String, dynamic>> node;
  final NodeFlowTheme nodeFlowTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tones = isDark
        ? const [
            Color(0xFF1B4D7A),
            Color(0xFF2D3E52),
            Color(0xFF3D5A40),
            Color(0xFF5A3D2D),
          ]
        : const [
            Color(0xFFD4E7F7),
            Color(0xFFE8D4F7),
            Color(0xFFD4F7E0),
            Color(0xFFF7E4D4),
          ];
    final textTones = isDark
        ? const [
            Color(0xFF88B8E6),
            Color(0xFFC4B0E6),
            Color(0xFFA8E6B8),
            Color(0xFFE6C4A8),
          ]
        : const [
            Color(0xFF1B4D7A),
            Color(0xFF4D1B7A),
            Color(0xFF1B7A4D),
            Color(0xFF7A4D1B),
          ];
    final tone = node.id.hashCode.abs() % tones.length;
    final nodeColor = tones[tone];
    final textColor = textTones[tone];

    final outerRadius = nodeFlowTheme.nodeTheme.borderRadius.topLeft.x;
    final borderWidth = nodeFlowTheme.nodeTheme.borderWidth;
    final innerRadius = (outerRadius - borderWidth).clamp(0.0, double.infinity);

    return Container(
      width: node.size.value.width,
      height: node.size.value.height,
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Center(
        child: Text(
          node.data['title'] as String? ?? node.id,
          style: theme.textTheme.titleSmall?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _LayerList extends StatelessWidget {
  const _LayerList({required this.controller});

  final NodeFlowController<Map<String, dynamic>, dynamic> controller;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final nodes = controller.nodes.values.toList()
          ..sort((a, b) => b.currentZIndex.compareTo(a.currentZIndex));

        if (nodes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No nodes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final node in nodes)
              _LayerTile(
                node: node,
                onSelect: () => controller.selectNode(node.id),
                onFront: () => controller.bringNodeToFront(node.id),
                onForward: () => controller.bringNodeForward(node.id),
                onBackward: () => controller.sendNodeBackward(node.id),
                onBack: () => controller.sendNodeToBack(node.id),
              ),
          ],
        );
      },
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    required this.node,
    required this.onSelect,
    required this.onFront,
    required this.onForward,
    required this.onBackward,
    required this.onBack,
  });

  final Node<Map<String, dynamic>> node;
  final VoidCallback onSelect;
  final VoidCallback onFront;
  final VoidCallback onForward;
  final VoidCallback onBackward;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = node.data['title'] as String? ?? node.id;
    final selected = node.isSelected;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'z ${node.currentZIndex}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_to_front, size: 18),
                  onPressed: onFront,
                  tooltip: 'Bring to front',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                  onPressed: onForward,
                  tooltip: 'Bring forward',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  onPressed: onBackward,
                  tooltip: 'Send backward',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_to_back, size: 18),
                  onPressed: onBack,
                  tooltip: 'Send to back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
