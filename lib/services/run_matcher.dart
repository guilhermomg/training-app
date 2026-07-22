import '../models/running_workout.dart';

/// Pure matching of Apple Health runs to a planned session date.
class RunMatcher {
  const RunMatcher();

  static DateTime _dateOnly(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  int dayDiff(RunningWorkout w, DateTime plannedDate) =>
      _dateOnly(w.start).difference(_dateOnly(plannedDate)).inDays.abs();

  /// Runs within [windowDays] of [plannedDate], closest first (ties: most recent).
  List<RunningWorkout> candidates(
    List<RunningWorkout> all,
    DateTime plannedDate, {
    int windowDays = 3,
  }) {
    final within =
        all.where((w) => dayDiff(w, plannedDate) <= windowDays).toList();
    within.sort((a, b) {
      final da = dayDiff(a, plannedDate);
      final db = dayDiff(b, plannedDate);
      if (da != db) return da.compareTo(db);
      return b.start.compareTo(a.start);
    });
    return within;
  }

  /// The closest run within [windowDays], or null.
  RunningWorkout? best(
    List<RunningWorkout> all,
    DateTime plannedDate, {
    int windowDays = 3,
  }) {
    final c = candidates(all, plannedDate, windowDays: windowDays);
    return c.isEmpty ? null : c.first;
  }

  /// A confident auto-suggestion for the detail page: closest run within ±1 day.
  RunningWorkout? suggestion(List<RunningWorkout> all, DateTime plannedDate) =>
      best(all, plannedDate, windowDays: 1);
}
