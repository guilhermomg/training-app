// Data models for the `training` Supabase schema.
// Mirrors packages/training/src/types/training.ts from the web app.

int? _asInt(dynamic v) => v == null ? null : (v as num).toInt();
double? _asDouble(dynamic v) => v == null ? null : (v as num).toDouble();

class TrainingPlan {
  final int id;
  final String name;
  final String? goal;
  final int totalWeeks;
  final int sessionsPerWeek;
  final DateTime? startDate;
  final DateTime? raceDate;

  const TrainingPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.totalWeeks,
    required this.sessionsPerWeek,
    required this.startDate,
    required this.raceDate,
  });

  factory TrainingPlan.fromMap(Map<String, dynamic> m) => TrainingPlan(
        id: (m['id'] as num).toInt(),
        name: m['name'] as String? ?? '',
        goal: m['goal'] as String?,
        totalWeeks: (m['total_weeks'] as num?)?.toInt() ?? 0,
        sessionsPerWeek: (m['sessions_per_week'] as num?)?.toInt() ?? 0,
        startDate: DateTime.tryParse(m['start_date']?.toString() ?? ''),
        raceDate: DateTime.tryParse(m['race_date']?.toString() ?? ''),
      );
}

class Phase {
  final int id;
  final String name;
  final int weekStart;
  final int weekEnd;
  final int sortOrder;

  const Phase({
    required this.id,
    required this.name,
    required this.weekStart,
    required this.weekEnd,
    required this.sortOrder,
  });

  factory Phase.fromMap(Map<String, dynamic> m) => Phase(
        id: (m['id'] as num).toInt(),
        name: m['name'] as String? ?? '',
        weekStart: (m['week_start'] as num?)?.toInt() ?? 0,
        weekEnd: (m['week_end'] as num?)?.toInt() ?? 0,
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      );

  bool coversWeek(int week) => week >= weekStart && week <= weekEnd;
}

class SessionStep {
  final int id;
  final int sessionId;
  final int? parentStepId;
  final String stepType; // warmup | effort | recovery | cooldown | repeat
  final int? repeatCount;
  final String objectiveType; // open | distance | duration | pace | heart_rate | calories
  final int? objectiveDistanceM;
  final int? objectiveDurationSecs;
  final int? objectivePaceMinSecs;
  final int? objectivePaceMaxSecs;
  final String? objectiveHrZone;
  final int? objectiveHrMinBpm;
  final int? objectiveHrMaxBpm;
  final int sortOrder;

  const SessionStep({
    required this.id,
    required this.sessionId,
    required this.parentStepId,
    required this.stepType,
    required this.repeatCount,
    required this.objectiveType,
    required this.objectiveDistanceM,
    required this.objectiveDurationSecs,
    required this.objectivePaceMinSecs,
    required this.objectivePaceMaxSecs,
    required this.objectiveHrZone,
    required this.objectiveHrMinBpm,
    required this.objectiveHrMaxBpm,
    required this.sortOrder,
  });

  factory SessionStep.fromMap(Map<String, dynamic> m) => SessionStep(
        id: (m['id'] as num).toInt(),
        sessionId: (m['session_id'] as num).toInt(),
        parentStepId: _asInt(m['parent_step_id']),
        stepType: m['step_type'] as String? ?? 'effort',
        repeatCount: _asInt(m['repeat_count']),
        objectiveType: m['objective_type'] as String? ?? 'open',
        objectiveDistanceM: _asInt(m['objective_distance_m']),
        objectiveDurationSecs: _asInt(m['objective_duration_secs']),
        objectivePaceMinSecs: _asInt(m['objective_pace_min_secs']),
        objectivePaceMaxSecs: _asInt(m['objective_pace_max_secs']),
        objectiveHrZone: m['objective_hr_zone'] as String?,
        objectiveHrMinBpm: _asInt(m['objective_hr_min_bpm']),
        objectiveHrMaxBpm: _asInt(m['objective_hr_max_bpm']),
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class LoggedSession {
  final int id;
  final int? sessionId;
  final DateTime sessionDate;
  final String status; // completed | modified | skipped
  final double? actualDistanceKm;
  final int? actualDurationSecs;
  final int? actualPaceSecs;
  final int? actualHrAvg;
  final int? cadenceAvg;
  final int? effortRpe;
  final String? notes;

  const LoggedSession({
    required this.id,
    required this.sessionId,
    required this.sessionDate,
    required this.status,
    required this.actualDistanceKm,
    required this.actualDurationSecs,
    required this.actualPaceSecs,
    required this.actualHrAvg,
    required this.cadenceAvg,
    required this.effortRpe,
    required this.notes,
  });

  factory LoggedSession.fromMap(Map<String, dynamic> m) => LoggedSession(
        id: (m['id'] as num).toInt(),
        sessionId: _asInt(m['session_id']),
        sessionDate:
            DateTime.tryParse(m['session_date']?.toString() ?? '') ?? DateTime(1970),
        status: m['status'] as String? ?? 'completed',
        actualDistanceKm: _asDouble(m['actual_distance_km']),
        actualDurationSecs: _asInt(m['actual_duration_secs']),
        actualPaceSecs: _asInt(m['actual_pace_secs']),
        actualHrAvg: _asInt(m['actual_hr_avg']),
        cadenceAvg: _asInt(m['cadence_avg']),
        effortRpe: _asInt(m['effort_rpe']),
        notes: m['notes'] as String?,
      );
}

class PlannedSession {
  final int id;
  final int weekNumber;
  final String dayOfWeek; // MON..SUN
  final String sessionType; // easy | tempo | long_run | ...
  final String name;
  final int sortOrder;
  final List<SessionStep> steps;
  final LoggedSession? logged;

  const PlannedSession({
    required this.id,
    required this.weekNumber,
    required this.dayOfWeek,
    required this.sessionType,
    required this.name,
    required this.sortOrder,
    required this.steps,
    required this.logged,
  });

  factory PlannedSession.fromMap(
    Map<String, dynamic> m, {
    required List<SessionStep> steps,
    required LoggedSession? logged,
  }) =>
      PlannedSession(
        id: (m['id'] as num).toInt(),
        weekNumber: (m['week_number'] as num?)?.toInt() ?? 0,
        dayOfWeek: m['day_of_week'] as String? ?? 'MON',
        sessionType: m['session_type'] as String? ?? 'other',
        name: m['name'] as String? ?? 'Run',
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
        steps: steps,
        logged: logged,
      );

  /// The main step whose pace/zone summarizes the session (mirrors the web's
  /// `sessionPaceSummary`: first top-level effort or repeat step).
  SessionStep? get mainStep {
    for (final s in steps) {
      if (s.parentStepId == null &&
          (s.stepType == 'effort' || s.stepType == 'repeat')) {
        return s;
      }
    }
    return null;
  }
}

/// A plan assembled with its phases and sessions grouped by week.
class TrainingData {
  final TrainingPlan plan;
  final List<Phase> phases;
  final List<PlannedSession> sessions;

  const TrainingData({
    required this.plan,
    required this.phases,
    required this.sessions,
  });
}
