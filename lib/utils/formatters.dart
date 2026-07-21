import 'package:intl/intl.dart';

/// Formatting helpers, mirroring the conventions used by the web training app
/// (see packages/training/src/lib/training-format.ts).

/// Pace as `m:ss/km`. Returns `—` when pace can't be computed.
String formatPace(double? secondsPerKm) {
  if (secondsPerKm == null ||
      secondsPerKm.isNaN ||
      secondsPerKm.isInfinite ||
      secondsPerKm <= 0) {
    return '—';
  }
  final total = secondsPerKm.round();
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}/km';
}

/// Distance in km. Whole numbers show no decimals, otherwise two.
String formatDistanceKm(double km) {
  if (km == km.roundToDouble()) return km.toStringAsFixed(0);
  return km.toStringAsFixed(2);
}

/// Elapsed time as `h:mm:ss` (or `m:ss` under an hour).
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$mm:$ss';
  return '$minutes:$ss';
}

/// A short header date, e.g. `Sat, Jul 18 · 7:04 AM`.
String formatWorkoutDate(DateTime date) {
  return DateFormat('EEE, MMM d · h:mm a').format(date);
}
