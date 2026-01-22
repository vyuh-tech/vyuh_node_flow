import 'package:flutter/widgets.dart';

/// Core layer positions in NodeFlowEditor.
///
/// These represent the fixed layers always rendered by the editor.
/// Extensions can inject custom layers relative to these positions
/// using the [before] and [after] getters.
///
/// Core layers are rendered in order from bottom to top:
/// 1. [grid] - Background grid pattern
/// 2. [backgroundNodes] - Background nodes (GroupNode)
/// 3. [connections] - Connection lines between nodes
/// 4. [connectionLabels] - Labels on connections
/// 5. [middleNodes] - Regular nodes
/// 6. [foregroundNodes] - Foreground nodes (CommentNode)
/// 7. [interaction] - Selection rectangles, drag previews
/// 8. [overlays] - UI overlays (minimap, attribution)
///
/// Example:
/// ```dart
/// // Position a layer after foreground nodes
/// LayerPosition get layerPosition => NodeFlowLayer.foregroundNodes.after;
///
/// // Position a layer before the interaction layer
/// LayerPosition get layerPosition => NodeFlowLayer.interaction.before;
/// ```
enum NodeFlowLayer {
  /// Background grid pattern.
  grid,

  /// Background nodes (e.g., GroupNode).
  backgroundNodes,

  /// Connection lines between nodes.
  connections,

  /// Labels displayed on connections.
  connectionLabels,

  /// Regular nodes (middle z-order).
  middleNodes,

  /// Foreground nodes (e.g., CommentNode).
  foregroundNodes,

  /// Interaction elements (selection marquee, drag preview).
  interaction,

  /// UI overlays (minimap, attribution).
  overlays;

  /// Position a layer immediately before this layer.
  LayerPosition get before => LayerPosition._(this, LayerRelation.before);

  /// Position a layer immediately after this layer.
  LayerPosition get after => LayerPosition._(this, LayerRelation.after);
}

/// Specifies where an extension layer should be rendered relative to
/// a known [NodeFlowLayer].
///
/// Create positions using the [NodeFlowLayer.before] and [NodeFlowLayer.after]
/// getters:
/// ```dart
/// NodeFlowLayer.foregroundNodes.after  // After foreground nodes
/// NodeFlowLayer.interaction.before     // Before interaction layer
/// ```
class LayerPosition {
  const LayerPosition._(this.anchor, this.relation);

  /// The anchor layer to position relative to.
  final NodeFlowLayer anchor;

  /// Whether to position before or after the anchor.
  final LayerRelation relation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LayerPosition &&
              runtimeType == other.runtimeType &&
              anchor == other.anchor &&
              relation == other.relation;

  @override
  int get hashCode => anchor.hashCode ^ relation.hashCode;

  @override
  String toString() => '${anchor.name}.${relation.name}';
}

/// Relation to the anchor layer.
enum LayerRelation {
  /// Position before the anchor layer.
  before,

  /// Position after the anchor layer.
  after,
}

/// Interface for extensions that want to inject custom layers into
/// the NodeFlowEditor rendering stack.
///
/// Implement this interface in your extension to provide a custom
/// widget layer that will be rendered at the specified position.
///
/// Example:
/// ```dart
/// class MyVisualizationExtension extends NodeFlowExtension
///     implements LayerProvider {
///   @override
///   LayerPosition get layerPosition =>
///       LayerPosition.after(NodeFlowLayer.foregroundNodes);
///
///   @override
///   Widget? buildLayer(BuildContext context) {
///     return CustomPaint(
///       painter: MyVisualizationPainter(),
///       size: Size.infinite,
///     );
///   }
/// }
/// ```
abstract interface class LayerProvider {
  /// The position where this layer should be rendered.
  ///
  /// Use [LayerPosition.before] or [LayerPosition.after] to specify
  /// the position relative to a known [NodeFlowLayer].
  LayerPosition get layerPosition;

  /// Builds the layer widget to render.
  ///
  /// Return `null` to skip rendering (e.g., when the layer is disabled).
  /// The widget is rendered in graph coordinate space (inside the
  /// transformed canvas).
  ///
  /// The [context] is the build context from the NodeFlowEditor.
  Widget? buildLayer(BuildContext context);
}
