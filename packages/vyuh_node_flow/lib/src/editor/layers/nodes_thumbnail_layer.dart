import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show ChangeNotifier, Listenable, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../nodes/node.dart';
import '../controller/node_flow_controller.dart';
import '../node_flow_editor.dart';
import '../scene/graph_scene.dart';
import '../unbounded_widgets.dart';

/// A layer that renders all nodes using retained pictures in one CustomPaint.
///
/// Used when zoomed out below the LOD minThreshold or when the visible-node
/// count exceeds the adaptive interaction budget. Node tap, selection, and
/// drag are handled by [NodeFlowEditor]'s root spatial hit-testing while this
/// layer is active. Port rendering and connection editing intentionally resume
/// only after the editor returns to full-widget mode.
class NodesThumbnailLayer<T> extends StatefulWidget {
  const NodesThumbnailLayer({
    super.key,
    required this.controller,
    required this.thumbnailBuilder,
    this.layerFilter,
    this.nodes,
  });

  final NodeFlowController<T, dynamic> controller;
  final ThumbnailBuilder<T>? thumbnailBuilder;
  final NodeRenderLayer? layerFilter;

  /// A prefiltered visible-node snapshot supplied by [NodesLayer].
  ///
  /// Direct users may omit this and let this layer read and filter the
  /// controller's visible nodes reactively.
  final List<Node<T>>? nodes;

  @override
  State<NodesThumbnailLayer<T>> createState() => _NodesThumbnailLayerState<T>();
}

class _NodesThumbnailLayerState<T> extends State<NodesThumbnailLayer<T>> {
  late _RetainedNodeScene<T> _scene;
  late _SceneConfigurationNotifier _configurationChanged;
  late _NodesThumbnailPainter<T> _painter;

  @override
  void initState() {
    super.initState();
    _createRetainedScene();
  }

  void _createRetainedScene() {
    _scene = _RetainedNodeScene<T>();
    _configurationChanged = _SceneConfigurationNotifier();
    _painter = _NodesThumbnailPainter<T>(
      projection: widget.controller.sceneProjection,
      scene: _scene,
      configurationChanged: _configurationChanged,
    );
  }

  @override
  void didUpdateWidget(covariant NodesThumbnailLayer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _configurationChanged.dispose();
      _scene.dispose();
      _createRetainedScene();
      return;
    }
    if (!identical(oldWidget.thumbnailBuilder, widget.thumbnailBuilder)) {
      _scene.clear();
    }
  }

  @override
  void dispose() {
    _configurationChanged.dispose();
    _scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        // Get visible nodes (already cached and sorted), unless NodesLayer has
        // already supplied the filtered subset.
        var visibleNodes = widget.nodes ?? widget.controller.visibleNodes;

        if (widget.nodes == null && widget.layerFilter != null) {
          visibleNodes = visibleNodes
              .where((node) => node.layer == widget.layerFilter)
              .toList();
        }

        if (visibleNodes.isEmpty) {
          _scene.retainOnly(const {});
          return const SizedBox.shrink();
        }

        // Get theme for default colors
        final theme = widget.controller.theme;
        final defaultColor = theme?.nodeTheme.backgroundColor ?? Colors.grey;
        final selectedBorderColor = theme?.nodeTheme.selectedBorderColor;
        _painter.updateConfiguration(
          nodeIds: visibleNodes.map((node) => node.id).toList(growable: false),
          defaultColor: defaultColor,
          selectedBorderColor: selectedBorderColor,
          thumbnailBuilder: widget.thumbnailBuilder,
        );

        return UnboundedPositioned.fill(
          child: UnboundedRepaintBoundary(
            child: CustomPaint(
              isComplex: true,
              willChange: false,
              painter: _painter,
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter that renders all nodes as thumbnails.
class _NodesThumbnailPainter<T> extends CustomPainter {
  _NodesThumbnailPainter({
    required this.projection,
    required this.scene,
    required this.configurationChanged,
  }) : super(
         repaint: Listenable.merge([
           projection.nodeDeltas,
           configurationChanged,
         ]),
       );

  final GraphSceneProjection<T, dynamic> projection;
  final _RetainedNodeScene<T> scene;
  final _SceneConfigurationNotifier configurationChanged;
  List<String> _nodeIds = const [];
  Color _defaultColor = Colors.grey;
  Color? _selectedBorderColor;
  ThumbnailBuilder<T>? _thumbnailBuilder;

  void updateConfiguration({
    required List<String> nodeIds,
    required Color defaultColor,
    required Color? selectedBorderColor,
    required ThumbnailBuilder<T>? thumbnailBuilder,
  }) {
    final idsChanged = !listEquals(_nodeIds, nodeIds);
    final colorsChanged =
        _defaultColor != defaultColor ||
        _selectedBorderColor != selectedBorderColor;
    final builderChanged = !identical(_thumbnailBuilder, thumbnailBuilder);
    if (!idsChanged && !colorsChanged && !builderChanged) return;

    _nodeIds = nodeIds;
    _defaultColor = defaultColor;
    _selectedBorderColor = selectedBorderColor;
    _thumbnailBuilder = thumbnailBuilder;
    configurationChanged.changed();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final retainedIds = <String>{};
    for (final id in _nodeIds) {
      final node = projection.nodeSnapshot(id);
      if (node == null || !node.isVisible) continue;
      retainedIds.add(node.id);
      final position = node.position;
      final nodeSize = node.size;
      final bounds = Rect.fromLTWH(
        position.dx,
        position.dy,
        nodeSize.width,
        nodeSize.height,
      );

      final picture = scene.pictureFor(
        node: node,
        bounds: bounds,
        defaultColor: _defaultColor,
        selectedBorderColor: _selectedBorderColor,
        thumbnailBuilder: _thumbnailBuilder,
      );
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.drawPicture(picture);
      canvas.restore();
    }
    scene.retainOnly(retainedIds);
  }

  @override
  bool shouldRepaint(covariant _NodesThumbnailPainter<T> oldDelegate) =>
      !identical(this, oldDelegate);
}

class _SceneConfigurationNotifier extends ChangeNotifier {
  void changed() => notifyListeners();
}

class _RetainedNodeScene<T> {
  final Map<String, _RetainedNodePicture> _pictures = {};

  ui.Picture pictureFor({
    required SceneNodeSnapshot<T> node,
    required Rect bounds,
    required Color defaultColor,
    required Color? selectedBorderColor,
    required ThumbnailBuilder<T>? thumbnailBuilder,
  }) {
    final key = _RetainedNodePictureKey(
      size: bounds.size,
      isSelected: node.isSelected,
      thumbnailCacheKey: node.thumbnailCacheKey,
      retainedVisualRevision: node.retainedVisualRevision,
      defaultColor: defaultColor,
      selectedBorderColor: selectedBorderColor,
    );
    final retained = _pictures[node.id];
    if (retained != null && retained.key == key) return retained.picture;

    retained?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..translate(-bounds.left, -bounds.top);

    final handled =
        thumbnailBuilder?.call(canvas, node.source, bounds, node.isSelected) ??
        false;
    if (!handled) {
      node.source.paintThumbnail(
        canvas,
        bounds,
        color: defaultColor,
        isSelected: node.isSelected,
        selectedBorderColor: selectedBorderColor,
      );
    }

    final picture = recorder.endRecording();
    _pictures[node.id] = _RetainedNodePicture(key: key, picture: picture);
    return picture;
  }

  void retainOnly(Set<String> retainedIds) {
    final removedIds = [
      for (final id in _pictures.keys)
        if (!retainedIds.contains(id)) id,
    ];
    for (final id in removedIds) {
      _pictures.remove(id)?.dispose();
    }
  }

  void clear() {
    for (final picture in _pictures.values) {
      picture.dispose();
    }
    _pictures.clear();
  }

  void dispose() => clear();
}

class _RetainedNodePicture {
  const _RetainedNodePicture({required this.key, required this.picture});

  final _RetainedNodePictureKey key;
  final ui.Picture picture;

  void dispose() => picture.dispose();
}

class _RetainedNodePictureKey {
  const _RetainedNodePictureKey({
    required this.size,
    required this.isSelected,
    required this.thumbnailCacheKey,
    required this.retainedVisualRevision,
    required this.defaultColor,
    required this.selectedBorderColor,
  });

  final Size size;
  final bool isSelected;
  final Object? thumbnailCacheKey;
  final int retainedVisualRevision;
  final Color defaultColor;
  final Color? selectedBorderColor;

  @override
  bool operator ==(Object other) =>
      other is _RetainedNodePictureKey &&
      other.size == size &&
      other.isSelected == isSelected &&
      other.thumbnailCacheKey == thumbnailCacheKey &&
      other.retainedVisualRevision == retainedVisualRevision &&
      other.defaultColor == defaultColor &&
      other.selectedBorderColor == selectedBorderColor;

  @override
  int get hashCode => Object.hash(
    size,
    isSelected,
    thumbnailCacheKey,
    retainedVisualRevision,
    defaultColor,
    selectedBorderColor,
  );
}
