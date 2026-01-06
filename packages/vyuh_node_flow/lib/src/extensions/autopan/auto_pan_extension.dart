import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:mobx/mobx.dart';

import '../../editor/controller/node_flow_controller.dart';
import '../events/events.dart';
import '../node_flow_extension.dart';

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
///     AutoPanExtension(enabled: true),
///   ],
/// );
///
/// // Access via controller
/// controller.autoPan?.isEnabled;  // true
///
/// // Disable at runtime
/// controller.autoPan?.disable();
///
/// // Use presets
/// controller.autoPan?.useFast();
/// controller.autoPan?.usePrecise();
/// ```
///
/// ## Edge Detection Zones
///
/// ```
/// ┌─────────────────────────────────────────────┐
/// │░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│ ← edgePadding.top
/// │░░┌─────────────────────────────────────────┐░░│
/// │░░│                                         │░░│
/// │░░│         Safe area (no pan)              │░░│
/// │░░│                                         │░░│
/// │░░└─────────────────────────────────────────┘░░│
/// │░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│ ← edgePadding.bottom
/// └─────────────────────────────────────────────┘
///  ↑                                           ↑
///  edgePadding.left               edgePadding.right
/// ```
class AutoPanExtension extends NodeFlowExtension {
  /// Creates an autopan extension.
  ///
  /// When [enabled] is true, autopan is active with the given settings.
  /// Pass [enabled]: false to disable autopan completely.
  ///
  /// Parameters:
  /// - [enabled]: Whether autopan is enabled (default: true)
  /// - [edgePadding]: Distance from viewport edges where autopan triggers (default: 50px all sides)
  /// - [panAmount]: Base pan amount per tick in graph units (default: 10.0)
  /// - [panInterval]: Duration between pan ticks (default: 16ms)
  /// - [useProximityScaling]: Whether to scale pan speed based on proximity (default: false)
  /// - [speedCurve]: Curve for proximity-based speed scaling
  AutoPanExtension({
    bool enabled = true,
    EdgeInsets edgePadding = const EdgeInsets.all(50.0),
    double panAmount = 10.0,
    Duration panInterval = const Duration(milliseconds: 16),
    bool useProximityScaling = false,
    Curve? speedCurve,
  }) : _enabled = Observable(enabled),
       _edgePadding = Observable(edgePadding),
       _panAmount = Observable(panAmount),
       _panInterval = Observable(panInterval),
       _useProximityScaling = Observable(useProximityScaling),
       _speedCurve = Observable(speedCurve);

  // ═══════════════════════════════════════════════════════════════════════════
  // Observable State
  // ═══════════════════════════════════════════════════════════════════════════

  final Observable<bool> _enabled;
  final Observable<EdgeInsets> _edgePadding;
  final Observable<double> _panAmount;
  final Observable<Duration> _panInterval;
  final Observable<bool> _useProximityScaling;
  final Observable<Curve?> _speedCurve;

  @override
  String get id => 'auto-pan';

  // ═══════════════════════════════════════════════════════════════════════════
  // Enabled State
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether autopan is currently enabled.
  bool get isEnabled => _enabled.value && _isEffectivelyEnabled;

  /// Whether autopan settings would allow panning (non-zero padding and amount).
  bool get _isEffectivelyEnabled =>
      (_edgePadding.value.left > 0 ||
          _edgePadding.value.right > 0 ||
          _edgePadding.value.top > 0 ||
          _edgePadding.value.bottom > 0) &&
      _panAmount.value > 0;

  /// Enables autopan.
  void enable() => runInAction(() => _enabled.value = true);

  /// Disables autopan.
  void disable() => runInAction(() => _enabled.value = false);

  /// Toggles autopan enabled state.
  void toggle() => runInAction(() => _enabled.value = !_enabled.value);

  /// Sets the enabled state.
  void setEnabled(bool enabled) => runInAction(() => _enabled.value = enabled);

  // ═══════════════════════════════════════════════════════════════════════════
  // Configuration Properties
  // ═══════════════════════════════════════════════════════════════════════════

  /// Distance from each viewport edge where autopan activates.
  ///
  /// When the pointer enters any of these zones during a drag, autopan begins.
  EdgeInsets get edgePadding => _edgePadding.value;

  /// Sets the edge padding.
  void setEdgePadding(EdgeInsets padding) =>
      runInAction(() => _edgePadding.value = padding);

  /// Base pan amount per tick in graph units.
  double get panAmount => _panAmount.value;

  /// Sets the pan amount.
  void setPanAmount(double amount) =>
      runInAction(() => _panAmount.value = amount);

  /// Duration between pan ticks.
  Duration get panInterval => _panInterval.value;

  /// Sets the pan interval.
  void setPanInterval(Duration interval) =>
      runInAction(() => _panInterval.value = interval);

  /// Whether to scale pan speed based on proximity to the edge.
  bool get useProximityScaling => _useProximityScaling.value;

  /// Sets whether to use proximity scaling.
  void setUseProximityScaling(bool value) =>
      runInAction(() => _useProximityScaling.value = value);

  /// Curve for proximity-based speed scaling.
  Curve? get speedCurve => _speedCurve.value;

  /// Sets the speed curve.
  void setSpeedCurve(Curve? curve) =>
      runInAction(() => _speedCurve.value = curve);

  // ═══════════════════════════════════════════════════════════════════════════
  // Presets
  // ═══════════════════════════════════════════════════════════════════════════

  /// Applies normal autopan settings (balanced for most use cases).
  ///
  /// - Edge padding: 50px all sides
  /// - Pan amount: 10 graph units
  /// - Pan interval: 16ms
  void useNormal() {
    runInAction(() {
      _enabled.value = true;
      _edgePadding.value = const EdgeInsets.all(50.0);
      _panAmount.value = 10.0;
      _panInterval.value = const Duration(milliseconds: 16);
      _useProximityScaling.value = false;
      _speedCurve.value = null;
    });
  }

  /// Applies fast autopan settings (for large canvases).
  ///
  /// - Edge padding: 60px all sides
  /// - Pan amount: 20 graph units
  /// - Pan interval: 12ms
  void useFast() {
    runInAction(() {
      _enabled.value = true;
      _edgePadding.value = const EdgeInsets.all(60.0);
      _panAmount.value = 20.0;
      _panInterval.value = const Duration(milliseconds: 12);
      _useProximityScaling.value = false;
      _speedCurve.value = null;
    });
  }

  /// Applies precise autopan settings (for fine control).
  ///
  /// - Edge padding: 30px all sides
  /// - Pan amount: 5 graph units
  /// - Pan interval: 20ms
  void usePrecise() {
    runInAction(() {
      _enabled.value = true;
      _edgePadding.value = const EdgeInsets.all(30.0);
      _panAmount.value = 5.0;
      _panInterval.value = const Duration(milliseconds: 20);
      _useProximityScaling.value = false;
      _speedCurve.value = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Pan Amount Calculation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculates the scaled pan amount based on proximity to a specific edge.
  ///
  /// [proximity] is the distance from the edge zone boundary to the pointer,
  /// where 0 is at the boundary and the edge's padding is at the viewport edge.
  ///
  /// [edgePaddingValue] is the padding for the specific edge being checked
  /// (e.g., [edgePadding.left], [edgePadding.top], etc.).
  double calculatePanAmount(
    double proximity, {
    required double edgePaddingValue,
  }) {
    if (!_useProximityScaling.value || edgePaddingValue <= 0) {
      return _panAmount.value;
    }

    // Normalize proximity to 0-1 range (0 = at boundary, 1 = at edge)
    final normalizedProximity = (proximity / edgePaddingValue).clamp(0.0, 1.0);

    // Apply curve if provided, otherwise use linear scaling
    final scaleFactor =
        _speedCurve.value?.transform(normalizedProximity) ??
        normalizedProximity;

    // Scale from 0.3x to 1.5x the base amount
    return _panAmount.value * (0.3 + scaleFactor * 1.2);
  }

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
