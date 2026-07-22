// Model for training.imported_workouts (Apple Health import).
// hr_series / route are stored as jsonb arrays; see the migration
// supabase/migrations/20260722000000_apple_health_import.sql.

int? _asInt(dynamic v) => v == null ? null : (v as num).toInt();
double? _asDouble(dynamic v) => v == null ? null : (v as num).toDouble();

class HrSample {
  final int tMs; // epoch milliseconds
  final int bpm;
  const HrSample(this.tMs, this.bpm);

  Map<String, dynamic> toJson() => {'t': tMs, 'bpm': bpm};
  factory HrSample.fromJson(Map<String, dynamic> j) =>
      HrSample((j['t'] as num).toInt(), (j['bpm'] as num).toInt());
}

class RoutePoint {
  final int tMs;
  final double lat;
  final double lng;
  final double? alt;
  final double? spd;
  final double? acc;
  const RoutePoint(this.tMs, this.lat, this.lng, {this.alt, this.spd, this.acc});

  Map<String, dynamic> toJson() => {
        't': tMs,
        'lat': lat,
        'lng': lng,
        if (alt != null) 'alt': alt,
        if (spd != null) 'spd': spd,
        if (acc != null) 'acc': acc,
      };
  factory RoutePoint.fromJson(Map<String, dynamic> j) => RoutePoint(
        (j['t'] as num).toInt(),
        (j['lat'] as num).toDouble(),
        (j['lng'] as num).toDouble(),
        alt: _asDouble(j['alt']),
        spd: _asDouble(j['spd']),
        acc: _asDouble(j['acc']),
      );
}

class ImportedWorkout {
  final int? id;
  final String source; // 'apple_health'
  final String externalId; // HealthKit workout UUID
  final String? sourceName; // 'Apple Watch'
  final String? workoutType; // 'running' | 'running_treadmill'
  final DateTime start;
  final DateTime end;
  final int? durationSecs;
  final int? movingSecs;
  final double? distanceM;
  final int? avgPaceSecs;
  final int? avgHrBpm;
  final int? maxHrBpm;
  final int? avgCadenceSpm;
  final int? activeEnergyKcal;
  final int? totalEnergyKcal;
  final double? elevationGainM;
  final List<HrSample> hrSeries;
  final List<RoutePoint> route;

  const ImportedWorkout({
    this.id,
    this.source = 'apple_health',
    required this.externalId,
    this.sourceName,
    this.workoutType,
    required this.start,
    required this.end,
    this.durationSecs,
    this.movingSecs,
    this.distanceM,
    this.avgPaceSecs,
    this.avgHrBpm,
    this.maxHrBpm,
    this.avgCadenceSpm,
    this.activeEnergyKcal,
    this.totalEnergyKcal,
    this.elevationGainM,
    this.hrSeries = const [],
    this.route = const [],
  });

  bool get hasRoute => route.length >= 2;
  bool get hasHr => hrSeries.length >= 2;

  /// Row for inserting/upserting into training.imported_workouts.
  Map<String, dynamic> toInsert(String userId) => {
        'user_id': userId,
        'source': source,
        'external_id': externalId,
        'source_name': sourceName,
        'workout_type': workoutType,
        'start_time': start.toUtc().toIso8601String(),
        'end_time': end.toUtc().toIso8601String(),
        'duration_secs': durationSecs,
        'moving_secs': movingSecs,
        'distance_m': distanceM,
        'avg_pace_secs': avgPaceSecs,
        'avg_hr_bpm': avgHrBpm,
        'max_hr_bpm': maxHrBpm,
        'avg_cadence_spm': avgCadenceSpm,
        'active_energy_kcal': activeEnergyKcal,
        'total_energy_kcal': totalEnergyKcal,
        'elevation_gain_m': elevationGainM,
        'hr_series': hrSeries.map((s) => s.toJson()).toList(),
        'route': route.map((p) => p.toJson()).toList(),
      };

  factory ImportedWorkout.fromMap(Map<String, dynamic> m) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => f(e.cast<String, dynamic>()))
          .toList();
    }

    return ImportedWorkout(
      id: _asInt(m['id']),
      source: m['source'] as String? ?? 'apple_health',
      externalId: m['external_id'] as String? ?? '',
      sourceName: m['source_name'] as String?,
      workoutType: m['workout_type'] as String?,
      start: DateTime.tryParse(m['start_time']?.toString() ?? '')?.toLocal() ??
          DateTime(1970),
      end: DateTime.tryParse(m['end_time']?.toString() ?? '')?.toLocal() ??
          DateTime(1970),
      durationSecs: _asInt(m['duration_secs']),
      movingSecs: _asInt(m['moving_secs']),
      distanceM: _asDouble(m['distance_m']),
      avgPaceSecs: _asInt(m['avg_pace_secs']),
      avgHrBpm: _asInt(m['avg_hr_bpm']),
      maxHrBpm: _asInt(m['max_hr_bpm']),
      avgCadenceSpm: _asInt(m['avg_cadence_spm']),
      activeEnergyKcal: _asInt(m['active_energy_kcal']),
      totalEnergyKcal: _asInt(m['total_energy_kcal']),
      elevationGainM: _asDouble(m['elevation_gain_m']),
      hrSeries: parseList(m['hr_series'], HrSample.fromJson),
      route: parseList(m['route'], RoutePoint.fromJson),
    );
  }
}
