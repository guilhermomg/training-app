import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/running_workout.dart';
import '../models/training/imported_workout.dart';
import '../models/training/training_models.dart';
import 'health_service.dart';

/// Writes the link between an Apple Health run and a planned training session:
/// persists the workout into training.imported_workouts and creates the
/// logged_session that marks the planned session complete.
class WorkoutLinkRepository {
  WorkoutLinkRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseQuerySchema get _db => _client.schema('training');
  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  static String _dateOnly(DateTime d) {
    final l = d.toLocal();
    return '${l.year.toString().padLeft(4, '0')}-'
        '${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }

  /// Links [workout] (with its [detail]) to [session] under [plan]:
  ///   1. upsert the imported workout (idempotent on the HealthKit UUID),
  ///   2. replace any existing logged_session for the planned session with one
  ///      derived from the workout.
  Future<void> linkWorkout({
    required PlannedSession session,
    required TrainingPlan plan,
    required RunningWorkout workout,
    required WorkoutDetail detail,
  }) async {
    final imported = ImportedWorkout(
      externalId: workout.id,
      sourceName: workout.sourceName,
      workoutType: workout.workoutType,
      start: workout.start,
      end: workout.end,
      durationSecs: workout.duration.inSeconds,
      distanceM: workout.distanceKm * 1000,
      avgPaceSecs: workout.avgPaceSecs,
      avgHrBpm: workout.avgHeartRateBpm,
      maxHrBpm: workout.maxHeartRateBpm,
      avgCadenceSpm: workout.cadenceSpm,
      activeEnergyKcal: workout.activeEnergyKcal,
      hrSeries: detail.hrSeries,
      route: detail.route,
    );

    final row = await _db
        .from('imported_workouts')
        .upsert(imported.toInsert(_userId), onConflict: 'user_id,source,external_id')
        .select('id')
        .single();
    final workoutId = (row['id'] as num).toInt();

    // One logged_session per planned session: clear then insert.
    await _db
        .from('logged_sessions')
        .delete()
        .eq('session_id', session.id)
        .eq('user_id', _userId);

    await _db.from('logged_sessions').insert({
      'session_id': session.id,
      'plan_id': plan.id,
      'user_id': _userId,
      'session_date': _dateOnly(workout.start),
      'status': 'completed',
      'actual_distance_km': workout.distanceKm,
      'actual_duration_secs': workout.duration.inSeconds,
      'actual_pace_secs': workout.avgPaceSecs,
      'actual_hr_avg': workout.avgHeartRateBpm,
      'cadence_avg': workout.cadenceSpm,
      'imported_workout_id': workoutId,
    });
  }

  /// Removes the logged_session for [session] (the imported workout is kept).
  Future<void> unlink(PlannedSession session) async {
    await _db
        .from('logged_sessions')
        .delete()
        .eq('session_id', session.id)
        .eq('user_id', _userId);
  }

  Future<ImportedWorkout?> getImportedWorkout(int id) async {
    final rows = await _db.from('imported_workouts').select().eq('id', id).limit(1);
    if (rows.isEmpty) return null;
    return ImportedWorkout.fromMap(rows.first);
  }
}
