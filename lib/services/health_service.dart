import 'package:health/health.dart';

import '../models/running_workout.dart';

/// Thin wrapper over the `health` plugin, scoped to reading running workouts
/// from Apple Health (HealthKit).
///
/// Note on iOS: HealthKit never discloses whether *read* access was granted,
/// so [hasPermissions] is unreliable for reads. The intended flow is to call
/// [requestAuthorization] (idempotent — the system sheet only appears the first
/// time) and then fetch; an empty result may mean "no data" or "denied", which
/// the UI surfaces as an empty state.
class HealthService {
  HealthService([Health? health]) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const List<HealthDataType> _types = [
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE,
  ];

  static const List<HealthDataAccess> _access = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Prompts for HealthKit read access. Returns false if the user declined the
  /// authorization request outright.
  Future<bool> requestAuthorization() async {
    await _ensureConfigured();
    return _health.requestAuthorization(_types, permissions: _access);
  }

  /// Fetches running workouts from the last [daysBack] days, most recent first,
  /// enriched with average heart rate where samples are available.
  Future<List<RunningWorkout>> fetchRunningWorkouts({int daysBack = 180}) async {
    await _ensureConfigured();

    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysBack));

    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WORKOUT],
      startTime: start,
      endTime: now,
    );

    final workouts = <RunningWorkout>[];
    for (final point in points) {
      final value = point.value;
      if (value is! WorkoutHealthValue) continue;
      final type = value.workoutActivityType;
      final isRun = type == HealthWorkoutActivityType.RUNNING ||
          type == HealthWorkoutActivityType.RUNNING_TREADMILL;
      if (!isRun) continue;

      final avgHr = await _averageHeartRate(point.dateFrom, point.dateTo);

      workouts.add(RunningWorkout(
        id: point.uuid,
        start: point.dateFrom,
        end: point.dateTo,
        distanceKm: (value.totalDistance ?? 0) / 1000.0,
        activeEnergyKcal: value.totalEnergyBurned,
        avgHeartRateBpm: avgHr,
        isTreadmill: type == HealthWorkoutActivityType.RUNNING_TREADMILL,
        sourceName: point.sourceName,
      ));
    }

    workouts.sort((a, b) => b.start.compareTo(a.start));
    return workouts;
  }

  Future<int?> _averageHeartRate(DateTime from, DateTime to) async {
    try {
      final samples = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: from,
        endTime: to,
      );
      final values = samples
          .map((s) => s.value)
          .whereType<NumericHealthValue>()
          .map((v) => v.numericValue)
          .toList();
      if (values.isEmpty) return null;
      final sum = values.reduce((a, b) => a + b);
      return (sum / values.length).round();
    } catch (_) {
      // HR is a best-effort enrichment; never fail the whole import over it.
      return null;
    }
  }
}
