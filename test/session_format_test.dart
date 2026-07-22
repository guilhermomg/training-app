import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/training/training_models.dart';
import 'package:training_app/utils/session_format.dart';

SessionStep _step({
  required String type,
  required String objectiveType,
  int? distanceM,
  int? durationSecs,
  int? paceMin,
  int? paceMax,
  String? zone,
  int? hrMin,
  int? hrMax,
}) =>
    SessionStep(
      id: 1,
      sessionId: 1,
      parentStepId: null,
      stepType: type,
      repeatCount: null,
      objectiveType: objectiveType,
      objectiveDistanceM: distanceM,
      objectiveDurationSecs: durationSecs,
      objectivePaceMinSecs: paceMin,
      objectivePaceMaxSecs: paceMax,
      objectiveHrZone: zone,
      objectiveHrMinBpm: hrMin,
      objectiveHrMaxBpm: hrMax,
      sortOrder: 1,
    );

void main() {
  group('distance', () {
    test('metric km', () {
      expect(SessionFormat.distance(5000, PaceUnit.metric), '5 km');
      expect(SessionFormat.distance(5500, PaceUnit.metric), '5.5 km');
    });
    test('imperial miles', () {
      expect(SessionFormat.distance(1609, PaceUnit.imperial), '1.0 mi');
    });
  });

  group('paceRange', () {
    test('range metric', () {
      expect(SessionFormat.paceRange(322, 328, PaceUnit.metric), '5:22–5:28/km');
    });
    test('single when equal', () {
      expect(SessionFormat.paceRange(390, 390, PaceUnit.metric), '6:30/km');
    });
    test('null when unset', () {
      expect(SessionFormat.paceRange(null, null, PaceUnit.metric), isNull);
    });
    test('imperial converts', () {
      // 300 s/km * 1.60934 ≈ 483 s/mi → 8:03/mi
      expect(SessionFormat.paceRange(300, 300, PaceUnit.imperial), '8:03/mi');
    });
  });

  group('stepObjective', () {
    test('distance · pace · zone', () {
      final s = _step(
        type: 'effort',
        objectiveType: 'distance',
        distanceM: 2000,
        paceMin: 390,
        paceMax: 390,
        zone: 'Z2',
      );
      expect(SessionFormat.stepObjective(s, PaceUnit.metric), '2 km · 6:30/km · Z2');
    });
    test('duration objective', () {
      final s = _step(
        type: 'effort',
        objectiveType: 'duration',
        durationSecs: 300,
        zone: 'Z2',
      );
      expect(SessionFormat.stepObjective(s, PaceUnit.metric), '5:00 · Z2');
    });
    test('open shows just the zone', () {
      final s = _step(type: 'recovery', objectiveType: 'open', zone: 'Z1');
      expect(SessionFormat.stepObjective(s, PaceUnit.metric), 'Z1');
    });
  });

  group('hrLabel', () {
    test('range when both bpm set', () {
      final s = _step(
          type: 'effort', objectiveType: 'distance', hrMin: 148, hrMax: 154);
      expect(SessionFormat.hrLabel(s), '148–154 bpm');
    });
    test('null when unset', () {
      final s = _step(type: 'effort', objectiveType: 'distance');
      expect(SessionFormat.hrLabel(s), isNull);
    });
  });

  test('stepLabel maps types', () {
    expect(SessionFormat.stepLabel('warmup'), 'Warm-up');
    expect(SessionFormat.stepLabel('cooldown'), 'Cool-down');
  });
}
