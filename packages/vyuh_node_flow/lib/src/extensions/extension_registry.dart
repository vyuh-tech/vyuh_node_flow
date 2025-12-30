import 'package:mobx/mobx.dart';

import 'node_flow_extension.dart';

/// Registry that manages extension instances.
///
/// Extensions are passed pre-configured and attached lazily when accessed
/// through the controller.
///
/// ## Usage
///
/// ```dart
/// final registry = ExtensionRegistry([
///   MinimapExtension(config: MinimapConfig(visible: false)),
///   LodExtension(config: LODConfig.disabled),
///   StatsExtension(),
/// ]);
///
/// // Get by type
/// final minimap = registry.get<MinimapExtension>();
/// ```
class ExtensionRegistry {
  /// Creates a registry with the given extensions.
  ExtensionRegistry([List<NodeFlowExtension<dynamic>>? extensions])
    : _extensions = {} {
    if (extensions != null) {
      for (final ext in extensions) {
        _extensions[ext.id] = ext;
      }
    }
  }

  final Map<String, NodeFlowExtension<dynamic>> _extensions;

  /// Observable to trigger reactivity when extensions are added/removed.
  final Observable<int> _version = Observable(0);

  /// Registers an extension.
  ///
  /// If an extension with the same ID exists, it is replaced.
  void register(NodeFlowExtension<dynamic> extension) {
    _extensions[extension.id] = extension;
    runInAction(() => _version.value++);
  }

  /// Gets an extension by type.
  E? get<E extends NodeFlowExtension<dynamic>>() {
    for (final ext in _extensions.values) {
      if (ext is E) return ext;
    }
    return null;
  }

  /// Gets an extension by its ID.
  NodeFlowExtension<dynamic>? getById(String id) => _extensions[id];

  /// Checks if an extension is registered for the given ID.
  bool has(String id) => _extensions.containsKey(id);

  /// Gets all registered extension IDs.
  Iterable<String> get ids => _extensions.keys;

  /// Gets all extension instances.
  Iterable<NodeFlowExtension<dynamic>> get all => _extensions.values;

  /// Removes an extension by ID.
  void remove(String id) {
    _extensions.remove(id);
    runInAction(() => _version.value++);
  }

  /// Clears all extensions.
  void clear() {
    _extensions.clear();
    runInAction(() => _version.value++);
  }
}
