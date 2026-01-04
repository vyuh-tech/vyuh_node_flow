import 'package:mobx/mobx.dart';

import '../../editor/auto_pan/auto_pan_config.dart';
import '../../editor/controller/node_flow_controller.dart';
import '../events/events.dart';
import '../node_flow_extension.dart';

// Re-export for convenience
export '../../editor/auto_pan/auto_pan_config.dart';

/// Extension for managing autopan behavior during drag operations.
///
/// Autopan automatically pans the viewport when dragging elements near
/// the viewport edges, allowing continued dragging beyond the visible area.
///
/// ## Usage
///
/// ```dart
/// // Configure via NodeFlowConfig
/// NodeFlowConfig(
///   extensions: [
///     AutoPanExtension(config: AutoPanConfig.fast),
///   ],
/// );
///
/// // Access via controller
/// controller.autoPan.isEnabled;     // true
/// controller.autoPan.currentConfig; // AutoPanConfig.fast
///
/// // Disable at runtime
/// controller.autoPan.disable();
///
/// // Change config at runtime
/// controller.autoPan.setConfig(AutoPanConfig.precise);
/// ```
class AutoPanExtension extends NodeFlowExtension {
  /// Creates an autopan extension.
  ///
  /// Pass `null` to disable autopan, or an [AutoPanConfig] to enable it.
  AutoPanExtension({AutoPanConfig? config = AutoPanConfig.normal})
    : _config = Observable(config);

  final Observable<AutoPanConfig?> _config;

  @override
  String get id => 'auto-pan';

  // ═══════════════════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether autopan is currently enabled.
  bool get isEnabled => _config.value?.isEnabled ?? false;

  /// Current autopan configuration, or null if disabled.
  AutoPanConfig? get currentConfig => _config.value;

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enables autopan with the given configuration.
  void enable([AutoPanConfig config = AutoPanConfig.normal]) {
    runInAction(() => _config.value = config);
  }

  /// Disables autopan.
  void disable() {
    runInAction(() => _config.value = null);
  }

  /// Toggles autopan on/off.
  ///
  /// When enabling, uses the provided [config] or defaults to [AutoPanConfig.normal].
  void toggle([AutoPanConfig config = AutoPanConfig.normal]) {
    runInAction(() {
      _config.value = _config.value == null ? config : null;
    });
  }

  /// Sets the autopan configuration.
  ///
  /// Pass `null` to disable autopan.
  void setConfig(AutoPanConfig? config) {
    runInAction(() => _config.value = config);
  }

  /// Sets autopan to fast mode (larger pan amounts, quicker intervals).
  void useFast() => setConfig(AutoPanConfig.fast);

  /// Sets autopan to normal mode (balanced settings).
  void useNormal() => setConfig(AutoPanConfig.normal);

  /// Sets autopan to precise mode (smaller pan amounts, finer control).
  void usePrecise() => setConfig(AutoPanConfig.precise);

  // ═══════════════════════════════════════════════════════════════════════════
  // NodeFlowExtension Implementation
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void attach(NodeFlowController controller) {
    // No-op - autopan behavior is implemented via AutoPanMixin in widgets
  }

  @override
  void detach() {
    // No-op
  }

  @override
  void onEvent(GraphEvent event) {
    // No event handling needed - autopan is driven by pointer position
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller Extension
// ═══════════════════════════════════════════════════════════════════════════

/// Dart extension providing access to the autopan extension.
extension AutoPanExtensionAccess<T> on NodeFlowController<T, dynamic> {
  /// Gets the autopan extension, or null if not configured.
  ///
  /// Returns null if the extension is not registered, which effectively
  /// disables autopan functionality. Use null-aware operators to safely
  /// access autopan features.
  AutoPanExtension? get autoPan => resolveExtension<AutoPanExtension>();
}
