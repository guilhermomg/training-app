import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/training/dashboard_view.dart';
import 'package:training_app/models/training/training_models.dart';
import 'package:training_app/screens/session_detail_screen.dart';

SessionStep _step(
  int id,
  String type,
  String objectiveType, {
  int? parent,
  int? distanceM,
  int? durationSecs,
  int? paceMin,
  int? paceMax,
  String? zone,
  int? repeatCount,
  int sort = 1,
}) =>
    SessionStep(
      id: id,
      sessionId: 1,
      parentStepId: parent,
      stepType: type,
      repeatCount: repeatCount,
      objectiveType: objectiveType,
      objectiveDistanceM: distanceM,
      objectiveDurationSecs: durationSecs,
      objectivePaceMinSecs: paceMin,
      objectivePaceMaxSecs: paceMax,
      objectiveHrZone: zone,
      objectiveHrMinBpm: null,
      objectiveHrMaxBpm: null,
      sortOrder: sort,
    );

PlannedSession _session(
  List<SessionStep> steps, {
  String name = 'Easy Run',
  String type = 'easy',
  LoggedSession? logged,
}) =>
    PlannedSession(
      id: 1,
      weekNumber: 4,
      dayOfWeek: 'MON',
      sessionType: type,
      name: name,
      sortOrder: 1,
      steps: steps,
      logged: logged,
    );

void main() {
  testWidgets('renders header, title, hero stats and single step', (tester) async {
    final session = _session(
      [_step(1, 'effort', 'distance', distanceM: 7000, paceMin: 375, paceMax: 400, zone: 'Z2')],
    );

    await tester.pumpWidget(MaterialApp(
      home: SessionDetailScreen(session: session, state: SessionState.done),
    ));
    await tester.pump();

    expect(find.text('WEEK 4 · MON'), findsOneWidget);
    expect(find.text('Easy Run'), findsWidgets); // title + single-step card
    expect(find.text('COMPLETED'), findsOneWidget); // status pill
    // Hero stat labels from the design.
    expect(find.text('DISTANCE'), findsOneWidget);
    expect(find.text('EST. DURATION'), findsOneWidget);
    expect(find.text('TARGET PACE'), findsOneWidget);
    expect(find.text('EFFORT ZONE'), findsOneWidget);
    expect(find.text('7 km'), findsWidgets);
  });

  testWidgets('overflow menu switches units to miles', (tester) async {
    final session = _session(
      [_step(1, 'effort', 'distance', distanceM: 1609, paceMin: 300, paceMax: 300, zone: 'Z3')],
    );

    await tester.pumpWidget(MaterialApp(
      home: SessionDetailScreen(session: session, state: SessionState.upcoming),
    ));
    await tester.pump();

    expect(find.text('1.6 km'), findsWidgets);
    await tester.tap(find.byTooltip('Options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Miles'));
    await tester.pumpAndSettle();
    expect(find.text('1.0 mi'), findsWidgets);
  });

  testWidgets('renders a Repeat block with children', (tester) async {
    final session = _session(
      [
        _step(1, 'warmup', 'distance', distanceM: 2000, paceMin: 390, paceMax: 390, zone: 'Z2', sort: 1),
        _step(2, 'repeat', 'open', repeatCount: 6, sort: 2),
        _step(3, 'effort', 'distance', parent: 2, distanceM: 400, paceMin: 300, paceMax: 300, zone: 'Z4', sort: 1),
        _step(4, 'recovery', 'duration', parent: 2, durationSecs: 60, zone: 'Z1', sort: 2),
      ],
      type: 'interval',
      name: 'Intervals',
    );

    await tester.pumpWidget(MaterialApp(
      home: SessionDetailScreen(session: session, state: SessionState.upcoming),
    ));
    await tester.pump();

    expect(find.text('REPEAT'), findsOneWidget);
    expect(find.text('× 6'), findsOneWidget);
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text('Effort'), findsOneWidget);
    expect(find.text('Recovery'), findsOneWidget);
  });
}
