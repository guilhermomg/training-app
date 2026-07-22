import 'package:flutter/material.dart';

import '../models/training/dashboard_view.dart';
import '../models/training/training_models.dart';
import '../theme/dashboard_colors.dart';
import '../utils/session_format.dart';

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
  });

  final PlannedSession session;
  final SessionState state;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  PaceUnit _unit = PaceUnit.metric;

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
