import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/training/training_models.dart';
import 'package:training_app/screens/dashboard_screen.dart';
import 'package:training_app/services/dashboard_builder.dart';

PlannedSession _s(int id, int week, String day, String name, String? loggedStatus) =>
    PlannedSession(
      id: id,
      weekNumber: week,
      dayOfWeek: day,
      sessionType: 'tempo',
      name: name,
      sortOrder: id,
      steps: const [],
      logged: loggedStatus == null
          ? null
          : LoggedSession(
              id: id,
              sessionId: id,
              sessionDate: DateTime(2026, 4, 22),
              status: loggedStatus,
              actualDistanceKm: 5,
              actualDurationSecs: 1500,
              actualPaceSecs: 300,
              actualHrAvg: 150,
              cadenceAvg: null,
              effortRpe: null,
              notes: null,
            ),
    );

void main() {
  final data = TrainingData(
    plan: TrainingPlan(
      id: 1,
      name: 'MTL → SUB 1:55',
      goal: 'Sub 1:55 Half Marathon',
      totalWeeks: 16,
      sessionsPerWeek: 3,
      startDate: DateTime(2026, 4, 21),
      raceDate: DateTime(2026, 9, 13),
    ),
    phases: [
      const Phase(id: 1, name: 'Base Phase', weekStart: 1, weekEnd: 1, sortOrder: 0),
    ],
    sessions: [
      _s(1, 1, 'TUE', 'Easy Run', 'completed'),
      _s(2, 1, 'THU', 'Tempo Run', null),
    ],
  );

  // Week 1 is current on this date, so it renders expanded.
  final view = const DashboardBuilder().build(data, now: DateTime(2026, 4, 22));

  testWidgets('renders goal, phase and expanded current week sessions',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(previewView: view)));
    await tester.pump();

    expect(find.text('Sub 1:55 Half Marathon'), findsOneWidget);
    expect(find.text('BASE PHASE'), findsOneWidget);
    expect(find.text('Week 1'), findsOneWidget);
    // Current week starts expanded → session rows visible.
    expect(find.text('Easy Run'), findsOneWidget);
    expect(find.text('Tempo Run'), findsOneWidget);
  });

  testWidgets('tapping a week header collapses it', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(previewView: view)));
    await tester.pump();

    expect(find.text('Easy Run'), findsOneWidget);
    await tester.tap(find.text('Week 1'));
    await tester.pumpAndSettle();
    expect(find.text('Easy Run'), findsNothing);
  });
}
