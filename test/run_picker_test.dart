import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/running_workout.dart';
import 'package:training_app/screens/run_picker_screen.dart';

RunningWorkout _run(String id, DateTime start, {bool treadmill = false}) =>
    RunningWorkout(
      id: id,
      start: start,
      end: start.add(const Duration(minutes: 40)),
      distanceKm: 7,
      activeEnergyKcal: 400,
      avgHeartRateBpm: 150,
      isTreadmill: treadmill,
      sourceName: 'Apple Watch',
    );

void main() {
  final planned = DateTime(2026, 7, 21);

  testWidgets('renders candidate rows with a best-match pill', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RunPickerScreen(
        plannedDate: planned,
        presetRuns: [
          _run('same', DateTime(2026, 7, 21, 6, 42)),
          _run('next', DateTime(2026, 7, 22, 7)),
        ],
      ),
    ));
    await tester.pump();

    expect(find.text('Choose a Run'), findsOneWidget);
    expect(find.text('BEST MATCH'), findsOneWidget);
    expect(find.textContaining('7 km'), findsWidgets);
  });

  testWidgets('empty state when no runs are near the date', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RunPickerScreen(
        plannedDate: planned,
        presetRuns: [_run('old', DateTime(2026, 1, 1))],
      ),
    ));
    await tester.pump();

    expect(find.textContaining('No runs found'), findsOneWidget);
  });

  testWidgets('tapping a run pops with the selection', (tester) async {
    RunningWorkout? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            picked = await Navigator.of(context).push<RunningWorkout>(
              MaterialPageRoute(
                builder: (_) => RunPickerScreen(
                  plannedDate: planned,
                  presetRuns: [_run('same', DateTime(2026, 7, 21, 6, 42))],
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('7 km').first);
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.id, 'same');
  });
}
