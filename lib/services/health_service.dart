import 'package:health/health.dart';

import '../models/running_workout.dart';
import '../models/training/imported_workout.dart';

/// Full time-series detail for a single workout (HR curve + GPS route).
class WorkoutDetail {
  final List<HrSample> hrSeries;
  final List<RoutePoint> route;
  const WorkoutDetail({required this.hrSeries, required this.route});
}

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
    HealthDataType.WORKOUT_ROUTE,
  ];

  static const List<HealthDataAccess> _access = [
    HealthDataAccess.READ,
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

      final hr = await _heartRateStats(point.dateFrom, point.dateTo);
      final durationSecs = point.dateTo.difference(point.dateFrom).inSeconds;
      final steps = value.totalSteps;
      final cadence = (steps != null && steps > 0 && durationSecs > 0)
          ? (steps / (durationSecs / 60)).round()
          : null;

      workouts.add(RunningWorkout(
        id: point.uuid,
        start: point.dateFrom,
        end: point.dateTo,
        distanceKm: (value.totalDistance ?? 0) / 1000.0,
        activeEnergyKcal: value.totalEnergyBurned,
        avgHeartRateBpm: hr?.avg,
        maxHeartRateBpm: hr?.max,
        cadenceSpm: cadence,
        isTreadmill: type == HealthWorkoutActivityType.RUNNING_TREADMILL,
        sourceName: point.sourceName,
      ));
    }

    workouts.sort((a, b) => b.start.compareTo(a.start));
    return workouts;
  }

  /// Full HR curve + GPS route for a single workout (for the linked detail view).
  Future<WorkoutDetail> fetchWorkoutDetail(RunningWorkout w) async {
    await _ensureConfigured();

    final hrSeries = <HrSample>[];
    try {
      final samples = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: w.start,
        endTime: w.end,
      );
      for (final s in samples) {
        final v = s.value;
        if (v is NumericHealthValue) {
          hrSeries.add(HrSample(
            s.dateFrom.millisecondsSinceEpoch,
            v.numericValue.round(),
          ));
        }
      }
      hrSeries.sort((a, b) => a.tMs.compareTo(b.tMs));
    } catch (_) {/* best effort */}

    final route = <RoutePoint>[];
    try {
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WORKOUT_ROUTE],
        startTime: w.start,
        endTime: w.end,
      );
      for (final p in points) {
        final v = p.value;
        if (v is WorkoutRouteHealthValue) {
          for (final loc in v.locations) {
            route.add(RoutePoint(
              loc.timestamp.millisecondsSinceEpoch,
              loc.latitude,
              loc.longitude,
              alt: loc.altitude,
              spd: loc.speed,
              acc: loc.horizontalAccuracy,
            ));
          }
        }
      }
      route.sort((a, b) => a.tMs.compareTo(b.tMs));
    } catch (_) {/* treadmill / no GPS */}

    return WorkoutDetail(hrSeries: hrSeries, route: route);
  }

  Future<({int avg, int max})?> _heartRateStats(DateTime from, DateTime to) async {
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
      final max = values.reduce((a, b) => a > b ? a : b);
      return (avg: (sum / values.length).round(), max: max.round());
    } catch (_) {
      // HR is a best-effort enrichment; never fail the whole import over it.
      return null;
    }
  }
}
