import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/running_workout.dart';
import 'package:training_app/services/run_matcher.dart';

RunningWorkout _run(String id, DateTime start) => RunningWorkout(
      id: id,
      start: start,
      end: start.add(const Duration(minutes: 40)),
      distanceKm: 7,
      activeEnergyKcal: 400,
      avgHeartRateBpm: 150,
      isTreadmill: false,
      sourceName: 'Apple Watch',
    );

void main() {
  const matcher = RunMatcher();
  final planned = DateTime(2026, 7, 21);

  final runs = [
    _run('far', DateTime(2026, 7, 13, 8)), // 8 days before
    _run('day-before', DateTime(2026, 7, 20, 6, 30)),
    _run('same-evening', DateTime(2026, 7, 21, 18)),
    _run('same-morning', DateTime(2026, 7, 21, 6, 42)),
    _run('two-after', DateTime(2026, 7, 23, 7)),
  ];

  test('candidates within window, closest first', () {
    final c = matcher.candidates(runs, planned, windowDays: 3);
    expect(c.map((r) => r.id), isNot(contains('far'))); // outside 3-day window
    // Same-day runs first (day diff 0), most recent of those first.
    expect(c.first.id, 'same-evening');
    expect(c[1].id, 'same-morning');
  });

  test('best is the closest run', () {
    expect(matcher.best(runs, planned, windowDays: 3)!.id, 'same-evening');
  });

  test('suggestion only within ±1 day', () {
    expect(matcher.suggestion(runs, planned)!.id, 'same-evening');
    // Nothing within 1 day of a far-off planned date → null.
    expect(matcher.suggestion(runs, DateTime(2026, 1, 1)), isNull);
  });

  test('widening the window surfaces more runs', () {
    final narrow = matcher.candidates(runs, planned, windowDays: 3);
    final wide = matcher.candidates(runs, planned, windowDays: 14);
    expect(wide.length, greaterThan(narrow.length));
    expect(wide.map((r) => r.id), contains('far'));
  });
}
