/// A single running session imported from Apple Health.
class RunningWorkout {
  /// HealthKit sample UUID — stable identity for de-duping / future sync.
  final String id;
  final DateTime start;
  final DateTime end;
  final double distanceKm;

  /// Active energy burned, in kilocalories, when reported by HealthKit.
  final int? activeEnergyKcal;

  /// Average heart rate over the workout window, when HR samples exist.
  final int? avgHeartRateBpm;

  /// True for indoor/treadmill runs (HealthKit `RUNNING_TREADMILL`).
  final bool isTreadmill;

  /// The Health data source, e.g. "Apple Watch" or a third-party app.
  final String sourceName;

  const RunningWorkout({
    required this.id,
    required this.start,
    required this.end,
    required this.distanceKm,
    required this.activeEnergyKcal,
    required this.avgHeartRateBpm,
    required this.isTreadmill,
    required this.sourceName,
  });

  Duration get duration => end.difference(start);

  /// Pace in seconds per km; null when distance is missing/zero.
  double? get paceSecondsPerKm {
    if (distanceKm <= 0) return null;
    return duration.inSeconds / distanceKm;
  }
}
