import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/running_workout.dart';
import 'package:training_app/utils/formatters.dart';

void main() {
  group('formatPace', () {
    test('formats seconds/km as m:ss/km', () {
      expect(formatPace(315), '5:15/km');
      expect(formatPace(300), '5:00/km');
      expect(formatPace(65), '1:05/km');
    });

    test('returns em dash for null/invalid pace', () {
      expect(formatPace(null), '—');
      expect(formatPace(0), '—');
      expect(formatPace(double.infinity), '—');
      expect(formatPace(double.nan), '—');
    });
  });

  group('formatDistanceKm', () {
    test('whole numbers have no decimals', () {
      expect(formatDistanceKm(10), '10');
    });

    test('fractional distances use two decimals', () {
      expect(formatDistanceKm(5.25), '5.25');
      expect(formatDistanceKm(21.0975), '21.10');
    });
  });

  group('formatDuration', () {
    test('under an hour is m:ss', () {
      expect(formatDuration(const Duration(minutes: 8, seconds: 5)), '8:05');
    });

    test('over an hour is h:mm:ss', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  group('RunningWorkout.paceSecondsPerKm', () {
    RunningWorkout build({required double km, required Duration dur}) {
      final start = DateTime(2026, 7, 18, 7);
      return RunningWorkout(
        id: 'x',
        start: start,
        end: start.add(dur),
        distanceKm: km,
        activeEnergyKcal: null,
        avgHeartRateBpm: null,
        isTreadmill: false,
        sourceName: 'Test',
      );
    }

    test('computes pace from distance and duration', () {
      final w = build(km: 5, dur: const Duration(minutes: 25));
      expect(w.paceSecondsPerKm, 300); // 25:00 over 5km => 5:00/km
    });

    test('returns null when distance is zero', () {
      final w = build(km: 0, dur: const Duration(minutes: 25));
      expect(w.paceSecondsPerKm, isNull);
    });
  });
}
