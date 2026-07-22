import '../models/training/training_models.dart';

/// Distance/pace units for the session detail page.
enum PaceUnit { metric, imperial }

/// Unit-aware formatters for a session's steps, mirroring the web app's
/// SessionModal (packages/training/src/components/SessionModal.tsx).
class SessionFormat {
  const SessionFormat._();

  static String _mmss(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String distance(int meters, PaceUnit unit) {
    if (unit == PaceUnit.imperial) {
      final miles = meters / 1609.34;
      return miles % 1 == 0
          ? '${miles.toStringAsFixed(0)} mi'
          : '${miles.toStringAsFixed(1)} mi';
    }
    final km = meters / 1000;
    return km % 1 == 0
        ? '${km.toStringAsFixed(0)} km'
        : '${km.toStringAsFixed(1)} km';
  }

  /// Total distance for the hero card: sub-km shows metres, else 1 decimal km.
  static String heroDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    final r = (km * 10).round() / 10;
    return r == r.roundToDouble()
        ? '${r.toStringAsFixed(0)} km'
        : '${r.toStringAsFixed(1)} km';
  }

  /// Estimated duration for the hero card: "45 min" or "1:05" over an hour.
  static String estDuration(int secs) {
    final totalMin = (secs / 60).round();
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}' : '$m min';
  }

  static String duration(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static int _paceInUnit(int secsPerKm, PaceUnit unit) =>
      unit == PaceUnit.imperial ? (secsPerKm * 1.60934).round() : secsPerKm;

  static String? paceRange(int? min, int? max, PaceUnit unit) {
    if ((min == null || min == 0) && (max == null || max == 0)) return null;
    final label = unit == PaceUnit.imperial ? '/mi' : '/km';
    if (min != null && max != null && min != max) {
      return '${_mmss(_paceInUnit(min, unit))}–${_mmss(_paceInUnit(max, unit))}$label';
    }
    final v = (min != null && min != 0) ? min : max!;
    return '${_mmss(_paceInUnit(v, unit))}$label';
  }

  static double _speed(int secsPerKm, PaceUnit unit) {
    final kmh = 3600 / secsPerKm;
    return unit == PaceUnit.imperial ? kmh * 0.621371 : kmh;
  }

  static String _speedLabel(PaceUnit unit) =>
      unit == PaceUnit.imperial ? 'mph' : 'km/h';

  static String? speedRange(int? min, int? max, PaceUnit unit) {
    if (min == null || min == 0) return null;
    final lbl = _speedLabel(unit);
    if (max != null && max != 0 && max != min) {
      // min pace secs = fastest = highest speed; max pace = slowest = lowest.
      final lo = _speed(max, unit).toStringAsFixed(1);
      final hi = _speed(min, unit).toStringAsFixed(1);
      return '$lo–$hi $lbl';
    }
    return '${_speed(min, unit).toStringAsFixed(1)} $lbl';
  }

  static String actualPace(int secsPerKm, PaceUnit unit) {
    final label = unit == PaceUnit.imperial ? '/mi' : '/km';
    return '${_mmss(_paceInUnit(secsPerKm, unit))}$label';
  }

  static String actualSpeed(int secsPerKm, PaceUnit unit) =>
      '${_speed(secsPerKm, unit).toStringAsFixed(1)} ${_speedLabel(unit)}';

  static String actualDistance(double km, PaceUnit unit) {
    if (unit == PaceUnit.imperial) {
      return '${(km * 0.621371).toStringAsFixed(2)} mi';
    }
    return '${km.toStringAsFixed(2)} km';
  }

  static String? hrLabel(SessionStep step) {
    if (step.objectiveHrMinBpm != null && step.objectiveHrMaxBpm != null) {
      return '${step.objectiveHrMinBpm}–${step.objectiveHrMaxBpm} bpm';
    }
    return null;
  }

  /// Objective summary for a step: e.g. "2 km · 6:30/km · Z2".
  static String stepObjective(SessionStep step, PaceUnit unit) {
    if (step.objectiveType == 'open') return step.objectiveHrZone ?? '';
    final parts = <String>[];
    if (step.objectiveType == 'distance' && step.objectiveDistanceM != null) {
      parts.add(distance(step.objectiveDistanceM!, unit));
    } else if (step.objectiveType == 'duration' &&
        step.objectiveDurationSecs != null) {
      parts.add(duration(step.objectiveDurationSecs!));
    }
    final pace =
        paceRange(step.objectivePaceMinSecs, step.objectivePaceMaxSecs, unit);
    if (pace != null) parts.add(pace);
    final zone = step.objectiveHrZone;
    if (zone != null && zone.isNotEmpty) parts.add(zone);
    return parts.join(' · ');
  }

  static String? stepSpeed(SessionStep step, PaceUnit unit) {
    if (step.objectiveType == 'open') return null;
    return speedRange(
        step.objectivePaceMinSecs, step.objectivePaceMaxSecs, unit);
  }

  static const stepLabels = <String, String>{
    'warmup': 'Warm-up',
    'effort': 'Effort',
    'recovery': 'Recovery',
    'cooldown': 'Cool-down',
    'repeat': 'Repeat',
  };

  static String stepLabel(String stepType) => stepLabels[stepType] ?? stepType;
}
