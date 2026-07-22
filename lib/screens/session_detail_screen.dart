import 'package:flutter/material.dart';

import '../models/running_workout.dart';
import '../models/training/dashboard_view.dart';
import '../models/training/imported_workout.dart';
import '../models/training/training_models.dart';
import '../services/dashboard_builder.dart';
import '../services/health_service.dart';
import '../services/run_matcher.dart';
import '../services/workout_link_repository.dart';
import '../theme/dashboard_colors.dart';
import '../utils/formatters.dart' as fmt;
import '../utils/session_format.dart';
import '../widgets/dashboard/hr_chart.dart';
import '../widgets/dashboard/route_map.dart';
import 'run_picker_screen.dart';

const _ink = DashboardColors.ink;
const _muted = DashboardColors.muted;
const _cardBorder = DashboardColors.cardBorder;

/// Per-session-type blurb for the hero card (the DB has no description field).
const _descriptions = <String, String>{
  'easy': 'Steady, conversational effort for the full distance — should feel easy throughout.',
  'tempo': 'A sustained tempo effort bracketed by an easy warm-up and cool-down.',
  'long_run': 'Steady long-run effort — settle in and hold an easy, sustainable pace.',
  'interval': 'Hard efforts at speed with short recoveries, bookended by an easy warm-up and cool-down.',
  'fartlek': 'Playful surges of speed mixed into an otherwise steady run.',
  'recovery': 'Very easy recovery jog to promote blood flow and shake out the legs.',
  'race': 'Race day — settle into goal pace early, stay controlled, and finish strong.',
  'other': 'Complete the session as planned.',
};

Color _sessionTypeColor(String type) => switch (type) {
      'easy' => const Color(0xFF4F8FE8),
      'tempo' => const Color(0xFFE8A23A),
      'long_run' => const Color(0xFF0E9F6E),
      'interval' => const Color(0xFF9B59D0),
      'fartlek' => const Color(0xFF9B59D0),
      'race' => const Color(0xFF0E9F6E),
      'recovery' => const Color(0xFF4F8FE8),
      _ => const Color(0xFF0E9F6E),
    };

Color _stepColor(String stepType, String sessionType) {
  if (stepType == 'warmup' || stepType == 'cooldown') return const Color(0xFF4F8FE8);
  if (stepType == 'recovery') return const Color(0xFF34B8A6);
  return _sessionTypeColor(sessionType);
}

({Color bg, Color fg, String label})? _statusPill(SessionState state) => switch (state) {
      SessionState.done => (bg: const Color(0xFFDFF5EA), fg: const Color(0xFF0A6B49), label: 'Completed'),
      SessionState.modified => (bg: const Color(0xFFFBEEDA), fg: const Color(0xFF8A5A07), label: 'Completed · Modified'),
      SessionState.skipped => (bg: const Color(0xFFFBE4E1), fg: const Color(0xFF96271B), label: 'Skipped'),
      SessionState.today => (bg: const Color(0xFFDFF5EA), fg: const Color(0xFF0A6B49), label: 'Today'),
      SessionState.upcoming => null,
    };

/// Full-screen breakdown of a planned session: a hero summary card plus the
/// structured steps. Implements the session view of `Running Dashboard.dc.html`.
class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.session,
    this.state = SessionState.upcoming,
    this.plan,
    this.healthService,
    this.linkRepository,
    this.onChanged,
    this.previewLinked,
    this.previewSuggestion,
  });

  final PlannedSession session;
  final SessionState state;

  /// Needed to compute the planned date (for suggestion/picker) and to link.
  final TrainingPlan? plan;

  final HealthService? healthService;
  final WorkoutLinkRepository? linkRepository;

  /// Called after a link/unlink actually changes data, so the caller can
  /// refresh — the dashboard only reloads when something changed.
  final VoidCallback? onChanged;

  /// Test seams: render the linked / suggestion states without HealthKit.
  final ImportedWorkout? previewLinked;
  final RunningWorkout? previewSuggestion;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  static const _builder = DashboardBuilder();
  static const _matcher = RunMatcher();

  late final HealthService _health = widget.healthService ?? HealthService();
  late final WorkoutLinkRepository _repo =
      widget.linkRepository ?? WorkoutLinkRepository();

  PaceUnit _unit = PaceUnit.metric;

  bool _linkLoading = true;
  bool _busy = false;
  bool _mapExpanded = false;
  ImportedWorkout? _linked;
  RunningWorkout? _suggestion;
  List<RunningWorkout>? _runs;

  /// Link zone shows for any session that's already logged or whose planned
  /// date is today-or-past (i.e. there could be a run to attach). Genuinely
  /// future sessions have nothing to link yet.
  bool get _showLinkZone {
    if (widget.plan == null) return false;
    if (widget.session.logged != null) return true;
    final pd = _plannedDate;
    if (pd == null) return false;
    final now = DateTime.now();
    return !pd.isAfter(DateTime(now.year, now.month, now.day));
  }

  DateTime? get _plannedDate =>
      widget.plan == null ? null : _builder.plannedDate(widget.plan!, widget.session);

  @override
  void initState() {
    super.initState();
    _loadLink();
  }

  Future<void> _loadLink() async {
    if (!_showLinkZone) {
      setState(() => _linkLoading = false);
      return;
    }
    // Preview injection for tests.
    if (widget.previewLinked != null || widget.previewSuggestion != null) {
      setState(() {
        _linked = widget.previewLinked;
        _suggestion = widget.previewSuggestion;
        _linkLoading = false;
      });
      return;
    }
    try {
      final workoutId = widget.session.logged?.importedWorkoutId;
      if (workoutId != null) {
        final w = await _repo.getImportedWorkout(workoutId);
        if (!mounted) return;
        setState(() {
          _linked = w;
          _linkLoading = false;
        });
        return;
      }
      // Not linked → look for a suggested run near the planned date.
      await _health.requestAuthorization();
      final runs = await _health.fetchRunningWorkouts();
      final suggestion =
          _plannedDate == null ? null : _matcher.suggestion(runs, _plannedDate!);
      if (!mounted) return;
      setState(() {
        _runs = runs;
        _suggestion = suggestion;
        _linkLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _linkLoading = false);
    }
  }

  Future<void> _link(RunningWorkout run) async {
    setState(() => _busy = true);
    try {
      final detail = await _health.fetchWorkoutDetail(run);
      await _repo.linkWorkout(
        session: widget.session,
        plan: widget.plan!,
        workout: run,
        detail: detail,
      );
      if (!mounted) return;
      setState(() {
        _linked = ImportedWorkout(
          externalId: run.id,
          sourceName: run.sourceName,
          workoutType: run.workoutType,
          start: run.start,
          end: run.end,
          durationSecs: run.duration.inSeconds,
          distanceM: run.distanceKm * 1000,
          avgPaceSecs: run.avgPaceSecs,
          avgHrBpm: run.avgHeartRateBpm,
          maxHrBpm: run.maxHeartRateBpm,
          avgCadenceSpm: run.cadenceSpm,
          activeEnergyKcal: run.activeEnergyKcal,
          hrSeries: detail.hrSeries,
          route: detail.route,
        );
        _suggestion = null;
        _busy = false;
      });
      widget.onChanged?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('Could not link the run. Please try again.');
    }
  }

  Future<void> _unlink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink this run?'),
        content: const Text(
            'This removes the run from this session. The session will no longer '
            'show as completed. The run stays in Apple Health.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC0392B)),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _repo.unlink(widget.session);
      if (!mounted) return;
      setState(() {
        _linked = null;
        _busy = false;
      });
      widget.onChanged?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('Could not unlink. Please try again.');
    }
  }

  Future<void> _openPicker() async {
    if (_plannedDate == null) return;
    final chosen = await Navigator.of(context).push<RunningWorkout>(
      MaterialPageRoute(
        builder: (_) => RunPickerScreen(
          plannedDate: _plannedDate!,
          healthService: widget.healthService,
          presetRuns: widget.previewSuggestion != null ? _runs : null,
        ),
      ),
    );
    if (chosen != null) await _link(chosen);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---- Link zone ----

  List<Widget> _buildLinkZone(double plannedMeters, int plannedSecs, SessionStep? main) {
    if (_linkLoading) {
      return const [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Center(
            child: SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ];
    }
    final plannedDistance = SessionFormat.heroDistance(plannedMeters / 1000);
    final plannedDuration = plannedSecs > 0 ? SessionFormat.estDuration(plannedSecs) : '—';
    final plannedPace = main == null
        ? '—'
        : (SessionFormat.paceRange(
                main.objectivePaceMinSecs, main.objectivePaceMaxSecs, _unit) ??
            '—');

    final Widget child;
    if (_linked != null) {
      child = _linkedCard(_linked!, plannedDistance, plannedDuration, plannedPace);
    } else if (_suggestion != null) {
      child = _suggestionCard(_suggestion!);
    } else {
      child = _linkButton();
    }
    return [Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 4), child: child)];
  }

  Widget _linkButton() {
    return InkWell(
      onTap: _busy ? null : _openPicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8DEDA), width: 1.5),
        ),
        child: const Center(
          child: Text('Link a run',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink)),
        ),
      ),
    );
  }

  Widget _suggestionCard(RunningWorkout run) {
    final hr = run.avgHeartRateBpm != null ? ' · ${run.avgHeartRateBpm} bpm avg HR' : '';
    final subtitle =
        '${fmt.formatDistanceKm(run.distanceKm)} km · ${fmt.formatDuration(run.duration)} · '
        '${fmt.formatPace(run.paceSecondsPerKm)}$hr';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Looks like you ran this',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 10),
          Text(fmt.formatWorkoutDate(run.start),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 14),
          _greenButton('Link this run', () => _link(run)),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: _busy ? null : _openPicker,
              child: const Text('Choose a different run',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF4F8FE8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _greenButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: DashboardColors.brand,
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: _busy
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _linkedCard(
    ImportedWorkout w,
    String plannedDistance,
    String plannedDuration,
    String plannedPace,
  ) {
    final actualDistance = SessionFormat.actualDistance((w.distanceM ?? 0) / 1000, _unit);
    final actualDuration = w.durationSecs != null ? SessionFormat.duration(w.durationSecs!) : '—';
    final actualPace =
        w.avgPaceSecs != null ? SessionFormat.actualPace(w.avgPaceSecs!, _unit) : '—';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTUALS',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                      letterSpacing: 0.6)),
              Row(children: [
                _textAction('Change run', const Color(0xFF4F8FE8), _openPicker),
                const SizedBox(width: 14),
                _textAction('Unlink', const Color(0xFFC0392B), _unlink),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _actualCell('Distance', actualDistance, 'plan $plannedDistance'),
              _actualCell('Duration', actualDuration, 'plan $plannedDuration'),
              _actualCell('Pace', actualPace, 'plan $plannedPace'),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            _chip('Avg HR', w.avgHrBpm != null ? '${w.avgHrBpm} bpm' : '—'),
            const SizedBox(width: 8),
            _chip('Max HR', w.maxHrBpm != null ? '${w.maxHrBpm} bpm' : '—'),
            const SizedBox(width: 8),
            _chip('Cadence', w.avgCadenceSpm != null ? '${w.avgCadenceSpm} spm' : '—'),
          ]),
          if (w.hasHr) ...[
            const SizedBox(height: 14),
            _sectionLabel('Heart Rate'),
            const SizedBox(height: 6),
            HrChart(samples: w.hrSeries),
          ],
          if (w.hasRoute) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => setState(() => _mapExpanded = !_mapExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionLabel('Route'),
                      Text(_mapExpanded ? 'Collapse' : 'Expand',
                          style: const TextStyle(fontSize: 11, color: _muted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: _mapExpanded ? 220 : 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RouteMap(points: w.route, interactive: _mapExpanded),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('Apple Health · ${w.sourceName ?? 'Apple Health'}',
              style: const TextStyle(fontSize: 11.5, color: _muted)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder),
        ),
        child: child,
      );

  Widget _textAction(String label, Color color, VoidCallback onTap) => GestureDetector(
        onTap: _busy ? null : onTap,
        child: Text(label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _actualCell(String label, String value, String plan) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.faint,
                    letterSpacing: 0.3)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 1),
            Text(plan, style: const TextStyle(fontSize: 11, color: _muted)),
          ],
        ),
      );

  Widget _chip(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: DashboardColors.scaffold,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                      letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink)),
            ],
          ),
        ),
      );

  Widget _sectionLabel(String label) => Text(label.toUpperCase(),
      style: const TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.4));

  List<SessionStep> get _topLevel => widget.session.steps
      .where((s) => s.parentStepId == null)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<SessionStep> _childrenOf(int parentId) => widget.session.steps
      .where((s) => s.parentStepId == parentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  SessionStep? get _mainEffort {
    for (final top in _topLevel) {
      if (top.stepType == 'effort') return top;
      if (top.stepType == 'repeat') {
        final kids = _childrenOf(top.id);
        for (final k in kids) {
          if (k.stepType == 'effort') return k;
        }
        return kids.isEmpty ? top : kids.first;
      }
    }
    return _topLevel.isEmpty ? null : _topLevel.first;
  }

  (double meters, int secs) _stepMetrics(SessionStep s) {
    final paceAvg = _avgPace(s);
    if (s.objectiveDistanceM != null) {
      final m = s.objectiveDistanceM!.toDouble();
      final secs = paceAvg != null ? (m / 1000 * paceAvg).round() : 0;
      return (m, secs);
    }
    if (s.objectiveDurationSecs != null) {
      final secs = s.objectiveDurationSecs!;
      final m = paceAvg != null ? (secs / paceAvg * 1000) : 0.0;
      return (m, secs);
    }
    return (0, 0);
  }

  int? _avgPace(SessionStep s) {
    final min = s.objectivePaceMinSecs;
    final max = s.objectivePaceMaxSecs;
    if (min != null && max != null && min != 0 && max != 0) return ((min + max) / 2).round();
    if (min != null && min != 0) return min;
    if (max != null && max != 0) return max;
    return null;
  }

  (double meters, int secs) _totals() {
    var meters = 0.0;
    var secs = 0;
    for (final top in _topLevel) {
      if (top.stepType == 'repeat') {
        final n = top.repeatCount ?? 1;
        for (final child in _childrenOf(top.id)) {
          final (m, s) = _stepMetrics(child);
          meters += m * n;
          secs += s * n;
        }
      } else {
        final (m, s) = _stepMetrics(top);
        meters += m;
        secs += s;
      }
    }
    return (meters, secs);
  }

  String? _noteLine() {
    final n = widget.session.logged?.notes?.trim();
    if (n == null || n.isEmpty) return null;
    return switch (widget.state) {
      SessionState.modified => 'Actual: $n',
      SessionState.skipped => 'Note: $n',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final main = _mainEffort;
    final (meters, secs) = _totals();
    final pill = _statusPill(widget.state);
    final note = _noteLine();

    return Scaffold(
      backgroundColor: DashboardColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEK ${session.weekNumber} · ${session.dayOfWeek}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        session.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (pill != null) _Pill(bg: pill.bg, fg: pill.fg, label: pill.label),
                    ],
                  ),
                  if (note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(note,
                          style: const TextStyle(fontSize: 13, color: _muted)),
                    ),
                ],
              ),
            ),
            _heroCard(
              description: _descriptions[session.sessionType] ?? _descriptions['other']!,
              distance: SessionFormat.heroDistance(meters / 1000),
              duration: secs > 0 ? SessionFormat.estDuration(secs) : '—',
              pace: main == null
                  ? '—'
                  : (SessionFormat.paceRange(
                          main.objectivePaceMinSecs, main.objectivePaceMaxSecs, _unit) ??
                      '—'),
              zone: main?.objectiveHrZone ?? '—',
            ),
            if (_showLinkZone) ..._buildLinkZone(meters, secs, main),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Text(
                'STEPS',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            ..._buildBlocks(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleButton(
            child: const Icon(Icons.arrow_back_ios_new, size: 15, color: _ink),
            onTap: () => Navigator.of(context).maybePop(),
          ),
          PopupMenuButton<PaceUnit>(
            tooltip: 'Options',
            onSelected: (u) => setState(() => _unit = u),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: PaceUnit.metric,
                checked: _unit == PaceUnit.metric,
                child: const Text('Kilometres'),
              ),
              CheckedPopupMenuItem(
                value: PaceUnit.imperial,
                checked: _unit == PaceUnit.imperial,
                child: const Text('Miles'),
              ),
            ],
            child: const _CircleButton(
              child: Icon(Icons.more_horiz, size: 18, color: Color(0xFF64726B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard({
    required String description,
    required String distance,
    required String duration,
    required String pace,
    required String zone,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DashboardColors.goalGradientStart, DashboardColors.goalGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.brand.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Divider(color: Colors.white.withValues(alpha: 0.22), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _HeroStat(value: distance, label: 'Distance')),
                Expanded(child: _HeroStat(value: duration, label: 'Est. Duration')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _HeroStat(value: pace, label: 'Target Pace')),
                Expanded(child: _HeroStat(value: zone, label: 'Effort Zone')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBlocks() {
    final top = _topLevel;
    final onlyBlock = top.length == 1;
    return [
      for (final step in top)
        if (step.stepType == 'repeat')
          _RepeatBlock(
            count: step.repeatCount ?? 1,
            children: _childrenOf(step.id),
            unit: _unit,
            sessionType: widget.session.sessionType,
          )
        else
          _SingleBlock(
            name: onlyBlock
                ? widget.session.name
                : SessionFormat.stepLabel(step.stepType),
            dist: _stepDistLabel(step),
            paceZone: _stepPaceZone(step),
            color: _stepColor(step.stepType, widget.session.sessionType),
          ),
    ];
  }

  String _stepDistLabel(SessionStep s) {
    if (s.objectiveDistanceM != null) {
      return SessionFormat.distance(s.objectiveDistanceM!, _unit);
    }
    if (s.objectiveDurationSecs != null) {
      return SessionFormat.duration(s.objectiveDurationSecs!);
    }
    return '';
  }

  String _stepPaceZone(SessionStep s) {
    final parts = <String>[];
    final pace =
        SessionFormat.paceRange(s.objectivePaceMinSecs, s.objectivePaceMaxSecs, _unit);
    if (pace != null) parts.add(pace);
    final zone = s.objectiveHrZone;
    if (zone != null && zone.isNotEmpty) parts.add(zone);
    return parts.join(' · ');
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10.5,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _SingleBlock extends StatelessWidget {
  const _SingleBlock({
    required this.name,
    required this.dist,
    required this.paceZone,
    required this.color,
  });

  final String name;
  final String dist;
  final String paceZone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          if (dist.isNotEmpty || paceZone.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (dist.isNotEmpty)
                  Text(dist,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                if (paceZone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(paceZone,
                        style: const TextStyle(fontSize: 11.5, color: _muted)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RepeatBlock extends StatelessWidget {
  const _RepeatBlock({
    required this.count,
    required this.children,
    required this.unit,
    required this.sessionType,
  });

  final int count;
  final List<SessionStep> children;
  final PaceUnit unit;
  final String sessionType;

  String _distLabel(SessionStep s) {
    if (s.objectiveDistanceM != null) return SessionFormat.distance(s.objectiveDistanceM!, unit);
    if (s.objectiveDurationSecs != null) return SessionFormat.duration(s.objectiveDurationSecs!);
    return '';
  }

  String _paceZone(SessionStep s) {
    final parts = <String>[];
    final pace = SessionFormat.paceRange(s.objectivePaceMinSecs, s.objectivePaceMaxSecs, unit);
    if (pace != null) parts.add(pace);
    final zone = s.objectiveHrZone;
    if (zone != null && zone.isNotEmpty) parts.add(zone);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'REPEAT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                    letterSpacing: 0.4,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1EF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '× $count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                for (final child in children)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                            color: _stepColor(child.stepType, sessionType), width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            SessionFormat.stepLabel(child.stepType),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_distLabel(child).isNotEmpty)
                              Text(_distLabel(child),
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _ink)),
                            if (_paceZone(child).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(_paceZone(child),
                                    style: const TextStyle(
                                        fontSize: 11, color: _muted)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.bg, required this.fg, required this.label});

  final Color bg;
  final Color fg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: fg,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: DashboardColors.avatarBg,
        shape: BoxShape.circle,
      ),
      child: child,
    );
    if (onTap == null) return circle;
    return InkResponse(onTap: onTap, radius: 24, child: circle);
  }
}
