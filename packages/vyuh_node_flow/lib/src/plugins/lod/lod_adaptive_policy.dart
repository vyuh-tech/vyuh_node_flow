import 'detail_visibility.dart';

/// Adaptive visibility policy used during interaction-heavy phases.
///
/// This policy keeps full fidelity while idle, then progressively reduces
/// expensive visual details as graph complexity grows during active interaction.
class LodAdaptivePolicy {
  const LodAdaptivePolicy({
    required this.complexityNodeThreshold,
    required this.complexityConnectionThreshold,
    required this.extremeNodeThreshold,
    required this.extremeConnectionThreshold,
  });

  /// Node count threshold above which interaction mode reduces more detail.
  final int complexityNodeThreshold;

  /// Connection count threshold above which interaction mode reduces more detail.
  final int complexityConnectionThreshold;

  /// Node count threshold for aggressive interaction-mode degradation.
  final int extremeNodeThreshold;

  /// Connection count threshold for aggressive interaction-mode degradation.
  final int extremeConnectionThreshold;

  bool isComplex({required int nodeCount, required int connectionCount}) {
    return nodeCount >= complexityNodeThreshold ||
        connectionCount >= complexityConnectionThreshold;
  }

  bool isExtreme({required int nodeCount, required int connectionCount}) {
    return nodeCount >= extremeNodeThreshold ||
        connectionCount >= extremeConnectionThreshold;
  }

  /// Applies adaptive visibility reduction to [baseVisibility].
  ///
  /// Returns [baseVisibility] unchanged when not interacting.
  DetailVisibility apply({
    required DetailVisibility baseVisibility,
    required bool isInteracting,
    required int nodeCount,
    required int connectionCount,
  }) {
    if (!isInteracting) return baseVisibility;

    if (isExtreme(nodeCount: nodeCount, connectionCount: connectionCount)) {
      // Extreme graphs need aggressive degradation to stay interactive.
      return baseVisibility.copyWith(
        showNodeContent: false,
        showPorts: false,
        showPortLabels: false,
        showConnectionLabels: false,
        showConnectionEndpoints: false,
        showResizeHandles: false,
      );
    }

    if (isComplex(nodeCount: nodeCount, connectionCount: connectionCount)) {
      // For complex graphs, avoid toggling port labels because mounting/unmounting
      // thousands of label widgets can cause a one-frame hitch at drag start.
      return baseVisibility.copyWith(
        showConnectionLabels: false,
        showConnectionEndpoints: false,
        showResizeHandles: false,
      );
    }

    // For normal graph sizes, keep full visual fidelity during interaction to
    // avoid global tree churn from visibility flips.
    return baseVisibility;
  }
}
