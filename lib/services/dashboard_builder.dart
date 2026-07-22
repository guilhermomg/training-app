import 'package:intl/intl.dart';

import '../models/training/dashboard_view.dart';
import '../models/training/training_models.dart';

/// Pure transformation of [TrainingData] into the dashboard's view models.
/// No I/O — unit-testable in isolation.
class DashboardBuilder {
  const DashboardBuilder();

  static const _dayOffset = {
    'MON': 0, 'TUE': 1, 'WED': 2, 'THU': 3, 'FRI': 4, 'SAT': 5, 'SUN': 6,
  };

  DashboardView build(TrainingData data, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final plan = data.plan;
    final current = currentWeek(plan, today);

    // Group sessions by week number.
    final byWeek = <int, List<PlannedSession>>{};
    for (final s in data.sessions) {
      (byWeek[s.weekNumber] ??= []).add(s);
    }
    for (final list in byWeek.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final phases = <PhaseView>[];
    final sortedPhases = [...data.phases]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final phase in sortedPhases) {
      final weeks = <WeekView>[];
      for (var w = phase.weekStart; w <= phase.weekEnd; w++) {
        final weekSessions = byWeek[w];
        if (weekSessions == null || weekSessions.isEmpty) continue;
        weeks.add(_buildWeek(w, weekSessions, plan, today, current));
      }
      if (weeks.isNotEmpty) {
        phases.add(PhaseView(name: phase.name, weeks: weeks));
      }
    }

    return DashboardView(
      goal: _buildGoal(data, today, current),
      phases: phases,
      initiallyExpanded: {current},
    );
  }

  // ---- Week / session ----

  WeekView _buildWeek(
    int number,
    List<PlannedSession> weekSessions,
    TrainingPlan plan,
    DateTime today,
    int current,
  ) {
    final views =
        weekSessions.map((s) => buildSession(s, plan, today)).toList();
    final status = weekStatus(number, current);
    return WeekView(
      number: number,
      status: status,
      summary: weekSummary(views, status),
      sessions: views,
    );
  }

  SessionView buildSession(PlannedSession s, TrainingPlan plan, DateTime today) {
    final state = sessionState(s, plan, today);
    return SessionView(
      type: s.name,
      day: prettyDay(s.dayOfWeek),
      target: targetLine(s),
      secondary: secondaryLine(s, state),
      state: state,
    );
  }

  SessionState sessionState(PlannedSession s, TrainingPlan plan, DateTime today) {
    final logged = s.logged;
    if (logged != null) {
      switch (logged.status) {
        case 'modified':
          return SessionState.modified;
        case 'skipped':
          return SessionState.skipped;
        default:
          return SessionState.done;
      }
    }
    final planned = plannedDate(plan, s);
    if (planned != null && planned == today) return SessionState.today;
    return SessionState.upcoming;
  }

  String weekSummary(List<SessionView> sessions, WeekStatus status) {
    if (status == WeekStatus.upcoming) {
      return '${sessions.length} sessions planned';
    }
    final done = sessions
        .where((s) =>
            s.state == SessionState.done || s.state == SessionState.modified)
        .length;
    return '$done/${sessions.length} sessions completed';
  }

  WeekStatus weekStatus(int weekNumber, int current) {
    if (weekNumber < current) return WeekStatus.completed;
    if (weekNumber == current) return WeekStatus.current;
    return WeekStatus.upcoming;
  }

  // ---- Formatting ----

  /// Target line: main step's pace range · HR zone (mirrors the web's
  /// `sessionPaceSummary`), falling back to the session type.
  String targetLine(PlannedSession s) {
    final main = s.mainStep;
    if (main != null) {
      final parts = <String>[];
      final pace =
          formatPaceRange(main.objectivePaceMinSecs, main.objectivePaceMaxSecs);
      if (pace != null) parts.add(pace);
      final zone = main.objectiveHrZone;
      if (zone != null && zone.isNotEmpty) parts.add(zone);
      if (parts.isNotEmpty) return parts.join(' · ');
    }
    return _prettyType(s.sessionType);
  }

  String? secondaryLine(PlannedSession s, SessionState state) {
    if (state == SessionState.modified || state == SessionState.skipped) {
      final notes = s.logged?.notes;
      if (notes != null && notes.trim().isNotEmpty) return notes.trim();
    }
    return null;
  }

  String prettyDay(String dow) {
    if (dow.length < 2) return dow;
    return dow[0].toUpperCase() + dow.substring(1).toLowerCase();
  }

  String _prettyType(String sessionType) {
    return sessionType
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Pace as `m:ss/km`, a range when min≠max, or null when no pace is set.
  static String? formatPaceRange(int? min, int? max) {
    String fmt(int secs) {
      final m = secs ~/ 60;
      final s = secs % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }

    if ((min == null || min == 0) && (max == null || max == 0)) return null;
    if (min != null && max != null && min != max) {
      return '${fmt(min)}–${fmt(max)}/km';
    }
    final v = min ?? max!;
    return '${fmt(v)}/km';
  }

  // ---- Goal ----

  GoalView _buildGoal(TrainingData data, DateTime today, int current) {
    final plan = data.plan;
    final race = plan.raceDate;
    final daysToGo = race == null
        ? 0
        : _dateOnly(race).difference(today).inDays.clamp(0, 100000);

    return GoalView(
      name: (plan.goal?.trim().isNotEmpty ?? false) ? plan.goal!.trim() : plan.name,
      dateLabel:
          race != null ? DateFormat('EEE, MMM d yyyy').format(race) : '—',
      sessionsPerWeek: plan.sessionsPerWeek,
      weekProgress: '$current / ${plan.totalWeeks}',
      daysToGo: daysToGo,
      adherencePercent: _adherence(data, plan, today),
    );
  }

  int _adherence(TrainingData data, TrainingPlan plan, DateTime today) {
    var due = 0;
    var kept = 0;
    for (final s in data.sessions) {
      final planned = plannedDate(plan, s);
      if (planned == null || planned.isAfter(today)) continue;
      due++;
      final st = s.logged?.status;
      if (st == 'completed' || st == 'modified') kept++;
    }
    if (due == 0) return 0;
    return (kept / due * 100).round();
  }

  // ---- Dates ----

  int currentWeek(TrainingPlan plan, DateTime today) {
    final start = plan.startDate;
    if (start == null) return 1;
    final days = _dateOnly(today).difference(_dateOnly(start)).inDays;
    final week = (days / 7).floor() + 1;
    return week.clamp(1, plan.totalWeeks == 0 ? week : plan.totalWeeks);
  }

  DateTime? plannedDate(TrainingPlan plan, PlannedSession s) {
    final start = plan.startDate;
    if (start == null) return null;
    final offset = _dayOffset[s.dayOfWeek] ?? 0;
    return _dateOnly(start).add(Duration(days: (s.weekNumber - 1) * 7 + offset));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
