import '../graph/viewport.dart';

/// Policy for throttling controller viewport synchronization during interaction.
///
/// InteractiveViewer already applies visual transforms every frame. This policy
/// limits how often those transforms are mirrored into MobX viewport state,
/// reducing reactive churn during panning while preserving correctness.
class ViewportSyncPolicy {
  const ViewportSyncPolicy({
    this.minSyncInterval = const Duration(milliseconds: 24),
    this.translationThreshold = 16.0,
    this.zoomThreshold = 0.005,
  });

  /// Minimum time between synced viewport updates during interaction.
  final Duration minSyncInterval;

  /// Minimum translation delta (in screen pixels) required for immediate sync.
  final double translationThreshold;

  /// Minimum zoom delta required for immediate sync.
  final double zoomThreshold;

  bool shouldSyncNow({
    required GraphViewport candidate,
    required GraphViewport lastSynced,
    required DateTime? lastSyncTime,
    required DateTime now,
  }) {
    final movedEnough =
        (candidate.x - lastSynced.x).abs() >= translationThreshold ||
        (candidate.y - lastSynced.y).abs() >= translationThreshold ||
        (candidate.zoom - lastSynced.zoom).abs() >= zoomThreshold;

    if (movedEnough) {
      return true;
    }

    if (lastSyncTime == null) {
      return true;
    }

    return now.difference(lastSyncTime) >= minSyncInterval;
  }
}
