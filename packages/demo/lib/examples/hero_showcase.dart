import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// Hero showcase example demonstrating a visual effects pipeline.
///
/// This example shows:
/// - Interactive widgets inside nodes (image selector, color picker, sliders)
/// - Data flow connections between nodes
/// - Real-time preview updates based on active connections
/// - Glowing animated connection lines
class HeroShowcaseExample extends StatefulWidget {
  const HeroShowcaseExample({super.key});

  @override
  State<HeroShowcaseExample> createState() => _HeroShowcaseExampleState();
}

class _HeroShowcaseExampleState extends State<HeroShowcaseExample>
    with ResettableExampleMixin {
  late final NodeFlowController<HeroNodeData, dynamic> _controller;

  // Observable state for the effect pipeline
  final _selectedImage = Observable(0);
  final _selectedColor = Observable(const Color(0xFF6366F1));
  final _blurRadius = Observable(2.0); // Low default for performance
  final _colorOpacity = Observable(0.4);
  final _saturation = Observable(1.0);

  // Available images - small 256x256 for performance
  static const _images = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=256&h=256&fit=crop&q=80',
    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=256&h=256&fit=crop&q=80',
    'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=256&h=256&fit=crop&q=80',
    'https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=256&h=256&fit=crop&q=80',
  ];

  // Available colors (saturated for color overlay swatches)
  static const _colors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Red
  ];

  // Custom lightweight modern theme
  late final NodeFlowTheme _theme;

  // Minimal port themes - subtle when disconnected, accent when connected
  static final _basePortTheme = PortTheme.light.copyWith(
    size: const Size(8, 8), // Smaller ports for cleaner look
    color: const Color(0xFFD1D5DB), // Light grey when disconnected
  );
  static final _imagePortTheme = _basePortTheme.copyWith(
    connectedColor: const Color(0xFF60A5FA), // Soft blue when connected
  );
  static final _colorPortTheme = _basePortTheme.copyWith(
    connectedColor: const Color(0xFFF472B6), // Soft pink when connected
  );
  static final _effectPortTheme = _basePortTheme.copyWith(
    connectedColor: const Color(0xFF34D399), // Soft green when connected
  );

  @override
  NodeFlowController get controller => _controller;

  @override
  void initState() {
    super.initState();

    // Create modern lightweight theme with minimal visual weight
    final baseTheme = NodeFlowTheme.light;
    _theme = baseTheme.copyWith(
      backgroundColor: Colors.transparent,
      gridTheme: GridTheme.light.copyWith(style: GridStyles.none),
      // Lightweight node styling - 1px borders, subtle colors
      nodeTheme: baseTheme.nodeTheme.copyWith(
        backgroundColor: Colors.white,
        selectedBackgroundColor: const Color(0xFFFAFAFA),
        highlightBackgroundColor: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFFCBD5E1), // Slate-300 for better visibility
        selectedBorderColor: const Color(0xFF818CF8), // Soft indigo selection
        highlightBorderColor: const Color(0xFFA5B4FC),
        borderWidth: 1.0, // Thin 1px border
        selectedBorderWidth: 1.0,
        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
      ),
      // Subtle connection lines with flowing animation
      connectionTheme: baseTheme.connectionTheme.copyWith(
        style: ConnectionStyles.bezier,
        color: const Color(0xFFD1D5DB), // Light grey
        selectedColor: const Color(0xFF818CF8), // Soft indigo
        strokeWidth: 1.5,
        selectedStrokeWidth: 2,
        animationEffect: FlowingDashEffect(
          dashLength: 6,
          gapLength: 4,
          speed: 2,
        ),
      ),
      // Temporary connection styling
      temporaryConnectionTheme: baseTheme.temporaryConnectionTheme.copyWith(
        style: ConnectionStyles.bezier,
        strokeWidth: 1.5,
        color: const Color(0xFFA5B4FC),
      ),
      // Smaller, subtler ports
      portTheme: baseTheme.portTheme.copyWith(
        size: const Size(8, 8),
        color: const Color(0xFFD1D5DB),
        connectedColor: const Color(0xFF9CA3AF),
      ),
    );

    _controller = NodeFlowController<HeroNodeData, dynamic>(
      config: NodeFlowConfig(),
    );
    initExample();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initExample() {
    // Reset observables with performance-friendly defaults
    _selectedImage.value = 0;
    _selectedColor.value = const Color(0xFF6366F1);
    _blurRadius.value = 2.0;
    _colorOpacity.value = 0.4;
    _saturation.value = 1.0;

    // Create nodes
    _controller.addNode(
      Node<HeroNodeData>(
        id: 'image',
        type: 'hero',
        position: const Offset(50, 50),
        data: ImageSourceData(
          title: 'Image Source',
          icon: Icons.image_outlined,
          color: const Color(0xFF60A5FA),
          selectedImage: _selectedImage,
          images: _images,
        ),
        size: const Size(220, 180),
        outputPorts: [
          Port(
            id: 'image_out',
            name: 'Image',
            position: PortPosition.right,
            offset: const Offset(2, 90),
            theme: _imagePortTheme,
          ),
        ],
      ),
    );

    _controller.addNode(
      Node<HeroNodeData>(
        id: 'color',
        type: 'hero',
        position: const Offset(50, 270),
        data: ColorOverlayData(
          title: 'Color Overlay',
          icon: Icons.palette_outlined,
          color: const Color(0xFFF472B6),
          selectedColor: _selectedColor,
          opacity: _colorOpacity,
          colors: _colors,
        ),
        size: const Size(220, 150),
        outputPorts: [
          Port(
            id: 'color_out',
            name: 'Color',
            position: PortPosition.right,
            offset: const Offset(2, 75),
            theme: _colorPortTheme,
          ),
        ],
      ),
    );

    _controller.addNode(
      Node<HeroNodeData>(
        id: 'effects',
        type: 'hero',
        position: const Offset(50, 460),
        data: EffectsData(
          title: 'Effects',
          icon: Icons.blur_on,
          color: const Color(0xFF34D399),
          blurRadius: _blurRadius,
          saturation: _saturation,
        ),
        size: const Size(220, 150),
        outputPorts: [
          Port(
            id: 'effect_out',
            name: 'Effect',
            position: PortPosition.right,
            offset: const Offset(2, 75),
            theme: _effectPortTheme,
          ),
        ],
      ),
    );

    _controller.addNode(
      Node<HeroNodeData>(
        id: 'output',
        type: 'hero',
        position: const Offset(380, 180),
        data: OutputData(
          title: 'Output',
          icon: Icons.auto_awesome,
          color: const Color(0xFF818CF8),
          controller: _controller,
          selectedImage: _selectedImage,
          selectedColor: _selectedColor,
          blurRadius: _blurRadius,
          colorOpacity: _colorOpacity,
          saturation: _saturation,
          images: _images,
        ),
        size: const Size(300, 300),
        inputPorts: [
          Port(
            id: 'image_in',
            name: 'Image',
            position: PortPosition.left,
            offset: const Offset(-2, 70),
            theme: _imagePortTheme,
          ),
          Port(
            id: 'color_in',
            name: 'Color',
            position: PortPosition.left,
            offset: const Offset(-2, 130),
            theme: _colorPortTheme,
          ),
          Port(
            id: 'effect_in',
            name: 'Effect',
            position: PortPosition.left,
            offset: const Offset(-2, 190),
            theme: _effectPortTheme,
          ),
        ],
      ),
    );

    // Create connections
    _controller.addConnection(
      Connection(
        id: 'conn_image',
        sourceNodeId: 'image',
        sourcePortId: 'image_out',
        targetNodeId: 'output',
        targetPortId: 'image_in',
      ),
    );

    _controller.addConnection(
      Connection(
        id: 'conn_color',
        sourceNodeId: 'color',
        sourcePortId: 'color_out',
        targetNodeId: 'output',
        targetPortId: 'color_in',
      ),
    );

    _controller.addConnection(
      Connection(
        id: 'conn_effect',
        sourceNodeId: 'effects',
        sourcePortId: 'effect_out',
        targetNodeId: 'output',
        targetPortId: 'effect_in',
      ),
    );
  }

  Widget _buildNode(BuildContext context, Node<HeroNodeData> node) {
    final data = node.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get border radius from theme
    final nodeTheme = _theme.nodeTheme;
    final outerRadius = nodeTheme.borderRadius;
    final borderWidth = node.isSelected
        ? nodeTheme.selectedBorderWidth
        : nodeTheme.borderWidth;

    // Inner radius = outer radius - border width
    final innerRadiusValue = (outerRadius.topLeft.x - borderWidth);

    // Theme-aware colors
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final headerColor = isDark
        ? data.color.withValues(alpha: 0.15)
        : data.color.withValues(alpha: 0.06);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(innerRadiusValue),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modern minimal header - just subtle tinted background
          Container(
            decoration: BoxDecoration(color: headerColor),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(data.icon, size: 13, color: data.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: data.color.withValues(alpha: 0.9),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content with refined padding
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _buildNodeContent(context, data),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeContent(BuildContext context, HeroNodeData data) {
    switch (data) {
      case ImageSourceData():
        return _ImageSelector(
          selectedIndex: data.selectedImage,
          images: data.images,
        );
      case ColorOverlayData():
        return _ColorSelector(
          selectedColor: data.selectedColor,
          opacity: data.opacity,
          colors: data.colors,
        );
      case EffectsData():
        return _EffectsPanel(
          blurRadius: data.blurRadius,
          saturation: data.saturation,
        );
      case OutputData():
        return _OutputPreview(data: data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: _controller,
      onReset: resetExample,
      children: [
        const SectionTitle('Visual Effects Pipeline'),
        const SectionContent(
          child: InfoCard(
            title: 'Interactive Demo',
            content:
                'Disconnect connections to disable effects. '
                'Delete connections with Backspace/Delete key.',
          ),
        ),
      ],
      child: NodeFlowEditor<HeroNodeData, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: _theme,
        events: NodeFlowEvents(
          onInit: () => _controller.fitToView(),
          // Prevent node deletion but allow connection deletion
          node: NodeEvents(onBeforeDelete: (_) async => false),
          // Validate port connections - only allow matching port types
          connection: ConnectionEvents(
            onBeforeComplete: (context) {
              final sourcePortId = context.sourcePort.id;
              final targetPortId = context.targetPort.id;

              // Define valid connections: source_out -> target_in
              const validConnections = {
                'image_out': 'image_in',
                'color_out': 'color_in',
                'effect_out': 'effect_in',
              };

              if (validConnections[sourcePortId] == targetPortId) {
                return const ConnectionValidationResult.allow();
              }
              return const ConnectionValidationResult.deny(
                reason: 'Invalid port connection',
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Data Models
// ============================================================

/// Base class for hero node data.
sealed class HeroNodeData {
  String get title;
  IconData get icon;
  Color get color;
}

/// Data for the image source node.
class ImageSourceData extends HeroNodeData {
  @override
  final String title;
  @override
  final IconData icon;
  @override
  final Color color;
  final Observable<int> selectedImage;
  final List<String> images;

  ImageSourceData({
    required this.title,
    required this.icon,
    required this.color,
    required this.selectedImage,
    required this.images,
  });
}

/// Data for the color overlay node.
class ColorOverlayData extends HeroNodeData {
  @override
  final String title;
  @override
  final IconData icon;
  @override
  final Color color;
  final Observable<Color> selectedColor;
  final Observable<double> opacity;
  final List<Color> colors;

  ColorOverlayData({
    required this.title,
    required this.icon,
    required this.color,
    required this.selectedColor,
    required this.opacity,
    required this.colors,
  });
}

/// Data for the effects node.
class EffectsData extends HeroNodeData {
  @override
  final String title;
  @override
  final IconData icon;
  @override
  final Color color;
  final Observable<double> blurRadius;
  final Observable<double> saturation;

  EffectsData({
    required this.title,
    required this.icon,
    required this.color,
    required this.blurRadius,
    required this.saturation,
  });
}

/// Data for the output node.
class OutputData extends HeroNodeData {
  @override
  final String title;
  @override
  final IconData icon;
  @override
  final Color color;
  final NodeFlowController controller;
  final Observable<int> selectedImage;
  final Observable<Color> selectedColor;
  final Observable<double> blurRadius;
  final Observable<double> colorOpacity;
  final Observable<double> saturation;
  final List<String> images;

  OutputData({
    required this.title,
    required this.icon,
    required this.color,
    required this.controller,
    required this.selectedImage,
    required this.selectedColor,
    required this.blurRadius,
    required this.colorOpacity,
    required this.saturation,
    required this.images,
  });

  /// Check if image connection is active
  bool get hasImageConnection =>
      controller.connections.any((c) => c.targetPortId == 'image_in');

  /// Check if color connection is active
  bool get hasColorConnection =>
      controller.connections.any((c) => c.targetPortId == 'color_in');

  /// Check if effect connection is active
  bool get hasEffectConnection =>
      controller.connections.any((c) => c.targetPortId == 'effect_in');
}

// ============================================================
// Node Content Widgets
// ============================================================

/// Image selector widget for the image source node.
class _ImageSelector extends StatelessWidget {
  final Observable<int> selectedIndex;
  final List<String> images;

  const _ImageSelector({required this.selectedIndex, required this.images});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview of selected image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                images[selectedIndex.value],
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, size: 32),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Image thumbnails
          SizedBox(
            height: 32,
            child: Row(
              children: List.generate(images.length, (index) {
                final isSelected = selectedIndex.value == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => runInAction(() => selectedIndex.value = index),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < images.length - 1 ? 4 : 0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) =>
                              Container(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Color selector widget for the color overlay node.
class _ColorSelector extends StatelessWidget {
  final Observable<Color> selectedColor;
  final Observable<double> opacity;
  final List<Color> colors;

  const _ColorSelector({
    required this.selectedColor,
    required this.opacity,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Observer(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Color swatches - checkmark for selection
          SizedBox(
            height: 24,
            child: Row(
              children: colors.map((color) {
                final isSelected = selectedColor.value == color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => runInAction(() => selectedColor.value = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Opacity slider with value on right
          Row(
            children: [
              Icon(
                Icons.opacity,
                size: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              const SizedBox(width: 4),
              Text(
                'Opacity',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: selectedColor.value.withValues(
                      alpha: 0.8,
                    ),
                    inactiveTrackColor: selectedColor.value.withValues(
                      alpha: 0.15,
                    ),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    thumbColor: selectedColor.value,
                  ),
                  child: Slider(
                    value: opacity.value,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (v) => runInAction(() => opacity.value = v),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(opacity.value * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'JetBrains Mono',
                    color: isDark ? Colors.white : Colors.black87,
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

/// Effects panel for blur and saturation controls.
class _EffectsPanel extends StatelessWidget {
  final Observable<double> blurRadius;
  final Observable<double> saturation;

  const _EffectsPanel({required this.blurRadius, required this.saturation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = TextStyle(
      fontSize: 11,
      color: isDark ? Colors.white54 : Colors.black45,
    );
    final valueStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      fontFamily: 'JetBrains Mono',
      color: isDark ? Colors.white : Colors.black87,
    );

    return Observer(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blur control
          Row(
            children: [
              Icon(
                Icons.blur_on,
                size: 13,
                color: isDark ? Colors.white54 : Colors.black38,
              ),
              const SizedBox(width: 4),
              Text('Blur', style: labelStyle),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: const Color(
                      0xFF34D399,
                    ).withValues(alpha: 0.8),
                    inactiveTrackColor: const Color(
                      0xFF34D399,
                    ).withValues(alpha: 0.15),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    thumbColor: const Color(0xFF34D399),
                  ),
                  child: Slider(
                    value: blurRadius.value,
                    min: 0,
                    max: 10,
                    onChanged: (v) => runInAction(() => blurRadius.value = v),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${blurRadius.value.toStringAsFixed(0)}px',
                  style: valueStyle,
                ),
              ),
            ],
          ),
          // Saturation control
          Row(
            children: [
              Icon(
                Icons.tune,
                size: 13,
                color: isDark ? Colors.white54 : Colors.black38,
              ),
              const SizedBox(width: 4),
              Text('Saturation', style: labelStyle),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: const Color(
                      0xFF34D399,
                    ).withValues(alpha: 0.8),
                    inactiveTrackColor: const Color(
                      0xFF34D399,
                    ).withValues(alpha: 0.15),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    thumbColor: const Color(0xFF34D399),
                  ),
                  child: Slider(
                    value: saturation.value,
                    min: 0,
                    max: 1,
                    onChanged: (v) => runInAction(() => saturation.value = v),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(saturation.value * 100).round()}%',
                  style: valueStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Output preview widget showing the final blended result.
/// Optimized for 60fps with RepaintBoundary and cached calculations.
class _OutputPreview extends StatelessWidget {
  final OutputData data;

  const _OutputPreview({required this.data});

  // Pre-computed saturation matrices for common values (0.0, 0.5, 1.0)
  // to avoid recalculation on every frame
  static final _saturationCache = <int, List<double>>{};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Observer(
        builder: (_) {
          final hasImage = data.hasImageConnection;
          final hasColor = data.hasColorConnection;
          final hasEffect = data.hasEffectConnection;

          final imageUrl = data.images[data.selectedImage.value];
          final color = data.selectedColor.value;
          final blur = hasEffect ? data.blurRadius.value : 0.0;
          final opacity = hasColor ? data.colorOpacity.value : 0.0;
          final sat = hasEffect ? data.saturation.value : 1.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main preview
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: hasColor
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Base image with saturation (only if connected)
                        if (hasImage)
                          RepaintBoundary(
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(
                                _getCachedSaturationMatrix(sat),
                              ),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                // Cache decoded image at specific size for performance
                                cacheWidth: 256,
                                cacheHeight: 256,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, error, stack) =>
                                    const _PlaceholderWidget(
                                      icon: Icons.image_not_supported,
                                      iconSize: 48,
                                    ),
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return const _PlaceholderWidget(
                                    icon: Icons.hourglass_empty,
                                    iconSize: 32,
                                    showProgress: true,
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          _NoImagePlaceholder(isDark: isDark),

                        // Color overlay (only if connected) - use simple Container
                        if (hasColor && opacity > 0)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withValues(alpha: opacity * 0.8),
                                  color.withValues(alpha: opacity * 0.4),
                                ],
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),

                        // Blur effect - EXPENSIVE, only apply when blur > threshold
                        // Use RepaintBoundary to isolate blur repaints
                        if (hasEffect && blur > 0.5)
                          RepaintBoundary(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: blur / 3,
                                sigmaY: blur / 3,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),

                        // Vignette effect - static, const gradient
                        if (hasImage) const _VignetteOverlay(),

                        // Status indicator
                        _StatusIndicator(hasImage: hasImage),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Gets cached saturation matrix or computes and caches it.
  /// Caches at 1% granularity to balance memory vs computation.
  List<double> _getCachedSaturationMatrix(double saturation) {
    final key = (saturation * 100).round();
    return _saturationCache.putIfAbsent(
      key,
      () => _computeSaturationMatrix(saturation),
    );
  }

  /// Computes a saturation color matrix.
  static List<double> _computeSaturationMatrix(double saturation) {
    final s = saturation;
    const lumR = 0.3086;
    const lumG = 0.6094;
    const lumB = 0.0820;

    return [
      lumR * (1 - s) + s,
      lumG * (1 - s),
      lumB * (1 - s),
      0,
      0,
      lumR * (1 - s),
      lumG * (1 - s) + s,
      lumB * (1 - s),
      0,
      0,
      lumR * (1 - s),
      lumG * (1 - s),
      lumB * (1 - s) + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

/// Placeholder widget for loading/error states - const for performance.
class _PlaceholderWidget extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final bool showProgress;

  const _PlaceholderWidget({
    required this.icon,
    required this.iconSize,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: showProgress
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Icon(icon, size: iconSize, color: Colors.white54),
      ),
    );
  }
}

/// No image placeholder - extracted for const optimization.
class _NoImagePlaceholder extends StatelessWidget {
  final bool isDark;

  const _NoImagePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 32,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 4),
            Text(
              'No image',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vignette overlay - const widget for maximum performance.
class _VignetteOverlay extends StatelessWidget {
  const _VignetteOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.transparent,
            Color(0x4D000000), // Colors.black with 0.3 alpha
          ],
          stops: [0.5, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

/// Status indicator badge - const where possible.
class _StatusIndicator extends StatelessWidget {
  final bool hasImage;

  const _StatusIndicator({required this.hasImage});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasImage ? Icons.auto_awesome : Icons.link_off,
              size: 10,
              color: Colors.white70,
            ),
            const SizedBox(width: 3),
            Text(
              hasImage ? 'LIVE' : 'DISCONNECTED',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
