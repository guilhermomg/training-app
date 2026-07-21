import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/running_workout.dart';
import 'package:training_app/screens/workouts_screen.dart';
import 'package:training_app/services/health_service.dart';
import 'package:flutter/material.dart';

/// Overrides the two device-dependent methods so the widget tree can be
/// exercised without a real HealthKit device.
class _FakeHealthService extends HealthService {
  _FakeHealthService({required this.granted, required this.workouts});

  final bool granted;
  final List<RunningWorkout> workouts;

  @override
  Future<bool> requestAuthorization() async => granted;

  @override
  Future<List<RunningWorkout>> fetchRunningWorkouts({int daysBack = 180}) async =>
      workouts;
}

RunningWorkout _sampleRun() {
  final start = DateTime(2026, 7, 18, 7);
  return RunningWorkout(
    id: 'run-1',
    start: start,
    end: start.add(const Duration(minutes: 25)),
    distanceKm: 5,
    activeEnergyKcal: 320,
    avgHeartRateBpm: 152,
    isTreadmill: false,
    sourceName: 'Apple Watch',
  );
}

void main() {
  testWidgets('renders imported runs when access is granted', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutsScreen(
        healthService:
            _FakeHealthService(granted: true, workouts: [_sampleRun()]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('5:00/km'), findsOneWidget);
    expect(find.text('152 bpm'), findsOneWidget);
  });

  testWidgets('shows the grant-access prompt when denied', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutsScreen(
        healthService: _FakeHealthService(granted: false, workouts: const []),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Connect Apple Health'), findsOneWidget);
    expect(find.text('Grant access'), findsOneWidget);
  });

  testWidgets('shows empty state when no runs found', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkoutsScreen(
        healthService: _FakeHealthService(granted: true, workouts: const []),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No running workouts found'), findsOneWidget);
  });
}
