import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/running_workout.dart';
import 'package:training_app/models/training/dashboard_view.dart';
import 'package:training_app/models/training/imported_workout.dart';
import 'package:training_app/models/training/training_models.dart';
import 'package:training_app/screens/session_detail_screen.dart';

TrainingPlan _plan() => TrainingPlan(
      id: 1,
      name: 'Plan',
      goal: 'Sub 1:55 Half Marathon',
      totalWeeks: 16,
      sessionsPerWeek: 3,
      startDate: DateTime(2026, 4, 21),
      raceDate: DateTime(2026, 9, 13),
    );

PlannedSession _session() => PlannedSession(
      id: 5,
      weekNumber: 10,
      dayOfWeek: 'TUE',
      sessionType: 'easy',
      name: 'Easy Run',
      sortOrder: 1,
      steps: [
        SessionStep(
          id: 1,
          sessionId: 5,
          parentStepId: null,
          stepType: 'effort',
          repeatCount: null,
          objectiveType: 'distance',
          objectiveDistanceM: 7000,
          objectiveDurationSecs: null,
          objectivePaceMinSecs: 375,
          objectivePaceMaxSecs: 400,
          objectiveHrZone: 'Z2',
          objectiveHrMinBpm: null,
          objectiveHrMaxBpm: null,
          sortOrder: 1,
        ),
      ],
      logged: null,
    );

void main() {
  testWidgets('shows suggestion card when a run is suggested', (tester) async {
    final run = RunningWorkout(
      id: 'r1',
      start: DateTime(2026, 7, 21, 6, 42),
      end: DateTime(2026, 7, 21, 7, 22),
      distanceKm: 7.1,
      activeEnergyKcal: 420,
      avgHeartRateBpm: 152,
      isTreadmill: false,
      sourceName: 'Apple Watch',
    );

    await tester.pumpWidget(MaterialApp(
      home: SessionDetailScreen(
        session: _session(),
        state: SessionState.today,
        plan: _plan(),
        previewSuggestion: run,
      ),
    ));
    await tester.pump();

    expect(find.text('Looks like you ran this'), findsOneWidget);
    expect(find.text('Link this run'), findsOneWidget);
    expect(find.text('Choose a different run'), findsOneWidget);
  });

  testWidgets('shows Actuals card with chart + route when linked', (tester) async {
    final workout = ImportedWorkout(
      externalId: 'r1',
      sourceName: 'Apple Watch',
      workoutType: 'running',
      start: DateTime(2026, 7, 21, 6, 42),
      end: DateTime(2026, 7, 21, 7, 22),
      durationSecs: 2400,
      distanceM: 7100,
      avgPaceSecs: 338,
      avgHrBpm: 152,
      maxHrBpm: 168,
      avgCadenceSpm: 171,
      hrSeries: const [HrSample(0, 150), HrSample(60000, 158)],
      route: const [RoutePoint(0, 45.5, -73.6), RoutePoint(60000, 45.51, -73.61)],
    );

    await tester.pumpWidget(MaterialApp(
      home: SessionDetailScreen(
        session: _session(),
        state: SessionState.done,
        plan: _plan(),
        previewLinked: workout,
      ),
    ));
    await tester.pump();

    expect(find.text('ACTUALS'), findsOneWidget);
    expect(find.text('Unlink'), findsOneWidget);
    expect(find.text('Change run'), findsOneWidget);
    expect(find.text('152 bpm'), findsOneWidget); // avg HR chip
    expect(find.text('HEART RATE'), findsOneWidget);
    expect(find.text('ROUTE'), findsOneWidget);
  });

  testWidgets('Unlink asks for confirmation and Cancel keeps the link', (tester) async {
    final workout = ImportedWorkout(
      externalId: 'r1',
      sourceName: 'Apple Watch',
      workoutType: 'running',
      start: DateTime(2026, 7, 21, 6, 42),
      end: DateTime(2026, 7, 21, 7, 22),
      durationSecs: 2400,
      distanceM: 7100,
      avgPaceSecs: 338,
      avgHrBpm: 152,
      hrSeries: const [HrSample(0, 150), HrSample(60000, 158)],
    );

    await tester.pumpWidget(MaterialApp(
      home: SessionDetailScreen(
        session: _session(),
        state: SessionState.done,
        plan: _plan(),
        previewLinked: workout,
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Unlink'));
    await tester.pumpAndSettle();
    expect(find.text('Unlink this run?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Unlink this run?'), findsNothing);
    expect(find.text('ACTUALS'), findsOneWidget); // still linked
  });

  testWidgets('no link zone for a future session', (tester) async {
    // Plan starting tomorrow → every session's planned date is in the future.
    final futurePlan = TrainingPlan(
      id: 1,
      name: 'Plan',
      goal: 'Goal',
      totalWeeks: 16,
      sessionsPerWeek: 3,
      startDate: DateTime.now().add(const Duration(days: 1)),
      raceDate: DateTime.now().add(const Duration(days: 100)),
    );

    await tester.pumpWidget(MaterialApp(
      home: SessionDetailScreen(
        session: _session(),
        state: SessionState.upcoming,
        plan: futurePlan,
      ),
    ));
    await tester.pump();

    expect(find.text('Link a run'), findsNothing);
    expect(find.text('ACTUALS'), findsNothing);
  });
}
