import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/training/imported_workout.dart';

void main() {
  test('HrSample / RoutePoint json round-trip', () {
    final hr = HrSample.fromJson(const HrSample(1000, 152).toJson());
    expect(hr.tMs, 1000);
    expect(hr.bpm, 152);

    final rp = RoutePoint.fromJson(
        const RoutePoint(2000, 45.5, -73.6, alt: 30, spd: 3.2, acc: 5).toJson());
    expect(rp.lat, 45.5);
    expect(rp.lng, -73.6);
    expect(rp.alt, 30);
  });

  test('toInsert produces jsonb arrays and scalar columns', () {
    final w = ImportedWorkout(
      externalId: 'uuid-1',
      sourceName: 'Apple Watch',
      workoutType: 'running',
      start: DateTime.utc(2026, 7, 21, 10),
      end: DateTime.utc(2026, 7, 21, 10, 40),
      durationSecs: 2400,
      distanceM: 7100,
      avgPaceSecs: 338,
      avgHrBpm: 152,
      maxHrBpm: 168,
      avgCadenceSpm: 171,
      hrSeries: const [HrSample(0, 150), HrSample(1000, 154)],
      route: const [RoutePoint(0, 45.5, -73.6), RoutePoint(1000, 45.51, -73.61)],
    );

    final row = w.toInsert('user-123');
    expect(row['user_id'], 'user-123');
    expect(row['source'], 'apple_health');
    expect(row['external_id'], 'uuid-1');
    expect(row['distance_m'], 7100);
    expect((row['hr_series'] as List), hasLength(2));
    expect((row['route'] as List), hasLength(2));
    expect((row['hr_series'] as List).first, {'t': 0, 'bpm': 150});
  });

  test('fromMap parses a DB row incl. jsonb series', () {
    final w = ImportedWorkout.fromMap({
      'id': 9,
      'source': 'apple_health',
      'external_id': 'uuid-2',
      'source_name': 'Apple Watch',
      'workout_type': 'running',
      'start_time': '2026-07-21T10:00:00Z',
      'end_time': '2026-07-21T10:40:00Z',
      'duration_secs': 2400,
      'distance_m': 7100,
      'avg_pace_secs': 338,
      'avg_hr_bpm': 152,
      'max_hr_bpm': 168,
      'avg_cadence_spm': 171,
      'hr_series': [
        {'t': 0, 'bpm': 150},
        {'t': 1000, 'bpm': 154},
      ],
      'route': [
        {'t': 0, 'lat': 45.5, 'lng': -73.6},
        {'t': 1000, 'lat': 45.51, 'lng': -73.61},
      ],
    });

    expect(w.id, 9);
    expect(w.externalId, 'uuid-2');
    expect(w.distanceM, 7100);
    expect(w.hasHr, isTrue);
    expect(w.hasRoute, isTrue);
    expect(w.hrSeries, hasLength(2));
    expect(w.route.first.lat, 45.5);
  });
}
