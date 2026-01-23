import 'package:mobx/mobx.dart';

import 'node_flow_plugin.dart';

/// Registry that manages plugin instances.
///
/// Plugins are passed pre-configured and attached lazily when accessed
/// through the controller.
///
/// ## Usage
///
/// ```dart
/// final registry = PluginRegistry([
///   MinimapPlugin(visible: true),
///   LodPlugin(),
///   StatsPlugin(),
/// ]);
///
/// // Get by type
/// final minimap = registry.get<MinimapPlugin>();
/// ```
class PluginRegistry {
  /// Creates a registry with the given plugins.
  PluginRegistry([List<NodeFlowPlugin>? plugins]) : _plugins = {} {
    if (plugins != null) {
      for (final plugin in plugins) {
        _plugins[plugin.id] = plugin;
      }
    }
  }

  final Map<String, NodeFlowPlugin> _plugins;

  /// Observable to trigger reactivity when plugins are added/removed.
  final Observable<int> _version = Observable(0);

  /// Registers a plugin.
  ///
  /// If a plugin with the same ID exists, it is replaced.
  void register(NodeFlowPlugin plugin) {
    _plugins[plugin.id] = plugin;
    runInAction(() => _version.value++);
  }

  /// Gets a plugin by type.
  E? get<E extends NodeFlowPlugin>() {
    for (final plugin in _plugins.values) {
      if (plugin is E) return plugin;
    }
    return null;
  }

  /// Gets a plugin by its ID.
  NodeFlowPlugin? getById(String id) => _plugins[id];

  /// Checks if a plugin is registered for the given ID.
  bool has(String id) => _plugins.containsKey(id);

  /// Gets all registered plugin IDs.
  Iterable<String> get ids => _plugins.keys;

  /// Gets all plugin instances.
  Iterable<NodeFlowPlugin> get all => _plugins.values;

  /// Removes a plugin by ID.
  void remove(String id) {
    _plugins.remove(id);
    runInAction(() => _version.value++);
  }

  /// Clears all plugins.
  void clear() {
    _plugins.clear();
    runInAction(() => _version.value++);
  }
}
