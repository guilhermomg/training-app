import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/training/dashboard_view.dart';
import 'package:training_app/models/training/training_models.dart';
import 'package:training_app/services/dashboard_builder.dart';

const _builder = DashboardBuilder();

TrainingPlan _plan() => TrainingPlan(
      id: 1,
      name: 'MTL → SUB 1:55',
      goal: 'Sub 1:55 Half Marathon',
      totalWeeks: 16,
      sessionsPerWeek: 3,
      startDate: DateTime(2026, 4, 21),
      raceDate: DateTime(2026, 9, 13),
    );

SessionStep _effort({int? min, int? max, String? zone}) => SessionStep(
      id: 1,
      sessionId: 1,
      parentStepId: null,
      stepType: 'effort',
      repeatCount: null,
      objectiveType: 'distance',
      objectiveDistanceM: 5000,
      objectiveDurationSecs: null,
      objectivePaceMinSecs: min,
      objectivePaceMaxSecs: max,
      objectiveHrZone: zone,
      objectiveHrMinBpm: null,
      objectiveHrMaxBpm: null,
      sortOrder: 1,
    );

PlannedSession _session({
  required int id,
  required int week,
  String day = 'TUE',
  String type = 'tempo',
  String name = 'Tempo Run',
  List<SessionStep> steps = const [],
  LoggedSession? logged,
}) =>
    PlannedSession(
      id: id,
      weekNumber: week,
      dayOfWeek: day,
      sessionType: type,
      name: name,
      sortOrder: id,
      steps: steps,
      logged: logged,
    );

LoggedSession _log({required int sessionId, required String status, String? notes}) =>
    LoggedSession(
      id: sessionId,
      sessionId: sessionId,
      sessionDate: DateTime(2026, 5, 1),
      status: status,
      actualDistanceKm: 5,
      actualDurationSecs: 1500,
      actualPaceSecs: 300,
      actualHrAvg: 150,
      cadenceAvg: null,
      effortRpe: null,
      notes: notes,
      importedWorkoutId: null,
    );

void main() {
  TrainingData buildData(List<PlannedSession> sessions) =>
      TrainingData(plan: _plan(), phases: const [], sessions: sessions);

  group('currentWeek (progress-based)', () {
    test('week 1 when nothing is logged', () {
      expect(
        _builder.currentWeek(buildData([_session(id: 1, week: 1)])),
        1,
      );
    });
    test('is the highest week with a logged session while incomplete', () {
      // Week 10 has one of two sessions logged → still current.
      final data = buildData([
        _session(id: 1, week: 9, logged: _log(sessionId: 1, status: 'completed')),
        _session(id: 2, week: 10, logged: _log(sessionId: 2, status: 'completed')),
        _session(id: 3, week: 10),
      ]);
      expect(_builder.currentWeek(data), 10);
    });
    test('advances to the next week once the logged week is complete', () {
      final data = buildData([
        _session(id: 1, week: 10, logged: _log(sessionId: 1, status: 'completed')),
        _session(id: 2, week: 10, logged: _log(sessionId: 2, status: 'skipped')),
      ]);
      expect(_builder.currentWeek(data), 11);
    });
    test('clamps to total weeks', () {
      final data = buildData([
        _session(id: 1, week: 16, logged: _log(sessionId: 1, status: 'completed')),
      ]);
      expect(_builder.currentWeek(data), 16);
    });
  });

  group('sessionState', () {
    final plan = _plan();
    test('logged completed -> done', () {
      final s = _session(id: 1, week: 2, logged: _log(sessionId: 1, status: 'completed'));
      expect(_builder.sessionState(s, plan, DateTime(2026, 7, 20)), SessionState.done);
    });
    test('logged modified -> modified', () {
      final s = _session(id: 1, week: 2, logged: _log(sessionId: 1, status: 'modified'));
      expect(_builder.sessionState(s, plan, DateTime(2026, 7, 20)), SessionState.modified);
    });
    test('logged skipped -> skipped', () {
      final s = _session(id: 1, week: 2, logged: _log(sessionId: 1, status: 'skipped'));
      expect(_builder.sessionState(s, plan, DateTime(2026, 7, 20)), SessionState.skipped);
    });
    test('unlogged, planned today -> today', () {
      // Week 1 TUE = start (Apr 21, a Tuesday) + 1 day = Apr 22.
      final s = _session(id: 1, week: 1, day: 'TUE');
      expect(_builder.sessionState(s, plan, DateTime(2026, 4, 22)), SessionState.today);
    });
    test('unlogged, other day -> upcoming', () {
      final s = _session(id: 1, week: 1, day: 'TUE');
      expect(_builder.sessionState(s, plan, DateTime(2026, 4, 25)), SessionState.upcoming);
    });
  });

  group('weekStatus', () {
    test('past/current/future', () {
      expect(_builder.weekStatus(2, 13), WeekStatus.completed);
      expect(_builder.weekStatus(13, 13), WeekStatus.current);
      expect(_builder.weekStatus(14, 13), WeekStatus.upcoming);
    });
  });

  group('targetLine', () {
    test('pace range + zone from main step', () {
      final s = _session(id: 1, week: 1, steps: [_effort(min: 345, max: 360, zone: 'Z3')]);
      expect(_builder.targetLine(s), '5:45–6:00/km · Z3');
    });
    test('single pace when min==max', () {
      final s = _session(id: 1, week: 1, steps: [_effort(min: 390, max: 390, zone: 'Z2')]);
      expect(_builder.targetLine(s), '6:30/km · Z2');
    });
    test('falls back to prettified type without steps', () {
      final s = _session(id: 1, week: 1, type: 'long_run', steps: const []);
      expect(_builder.targetLine(s), 'Long Run');
    });
  });

  group('build (integration)', () {
    test('groups weeks under phases, expands current week, computes goal', () {
      final data = TrainingData(
        plan: _plan(),
        phases: [
          const Phase(id: 1, name: 'Base', weekStart: 1, weekEnd: 2, sortOrder: 0),
        ],
        sessions: [
          _session(id: 1, week: 1, day: 'TUE', logged: _log(sessionId: 1, status: 'completed')),
          _session(id: 2, week: 1, day: 'THU', logged: _log(sessionId: 2, status: 'skipped')),
          _session(id: 3, week: 2, day: 'TUE'),
        ],
      );
      final view = _builder.build(data, now: DateTime(2026, 4, 28)); // week 2

      expect(view.phases, hasLength(1));
      expect(view.phases.first.weeks, hasLength(2));
      expect(view.initiallyExpanded, contains(2));
      expect(view.goal.name, 'Sub 1:55 Half Marathon');
      expect(view.goal.weekProgress, '2 / 16');
      // Week 1: 1 completed of 2 (skipped doesn't count as done).
      expect(view.phases.first.weeks.first.summary, '1/2 sessions completed');
    });
  });
}
