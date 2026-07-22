// View models for the dashboard, derived from TrainingData by dashboard_builder.

enum SessionState { done, modified, skipped, today, upcoming }

enum WeekStatus { completed, current, upcoming }

class GoalView {
  final String name;
  final String dateLabel;
  final int sessionsPerWeek;
  final String weekProgress; // e.g. "13 / 16"
  final int daysToGo;
  final int adherencePercent;

  const GoalView({
    required this.name,
    required this.dateLabel,
    required this.sessionsPerWeek,
    required this.weekProgress,
    required this.daysToGo,
    required this.adherencePercent,
  });
}

class SessionView {
  final String type; // e.g. "Tempo Run"
  final String day; // e.g. "Wed"
  final String target; // pace · zone, or session type
  final String? secondary; // notes / actuals for modified & skipped
  final SessionState state;

  const SessionView({
    required this.type,
    required this.day,
    required this.target,
    required this.secondary,
    required this.state,
  });
}

class WeekView {
  final int number;
  final WeekStatus status;
  final String summary;
  final List<SessionView> sessions;

  const WeekView({
    required this.number,
    required this.status,
    required this.summary,
    required this.sessions,
  });
}

class PhaseView {
  final String name;
  final List<WeekView> weeks;

  const PhaseView({required this.name, required this.weeks});
}

class DashboardView {
  final GoalView goal;
  final List<PhaseView> phases;

  /// Weeks that should start expanded (the current week).
  final Set<int> initiallyExpanded;

  const DashboardView({
    required this.goal,
    required this.phases,
    required this.initiallyExpanded,
  });
}
