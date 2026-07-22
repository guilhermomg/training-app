import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/running_workout.dart';
import '../services/health_service.dart';
import '../services/run_matcher.dart';
import '../theme/dashboard_colors.dart';
import '../utils/formatters.dart';

/// Full-screen picker: choose an Apple Health run to link to a session.
/// Pops with the selected [RunningWorkout] (or null if cancelled).
class RunPickerScreen extends StatefulWidget {
  const RunPickerScreen({
    super.key,
    required this.plannedDate,
    this.healthService,
    this.presetRuns,
  });

  final DateTime plannedDate;
  final HealthService? healthService;

  /// Test seam: skip HealthKit and use these runs directly.
  final List<RunningWorkout>? presetRuns;

  @override
  State<RunPickerScreen> createState() => _RunPickerScreenState();
}

class _RunPickerScreenState extends State<RunPickerScreen> {
  static const _matcher = RunMatcher();
  static const _narrowWindow = 3;
  static const _wideWindow = 45;

  late final HealthService _health = widget.healthService ?? HealthService();

  bool _loading = true;
  bool _widened = false;
  List<RunningWorkout> _all = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.presetRuns != null) {
      setState(() {
        _all = widget.presetRuns!;
        _loading = false;
      });
      return;
    }
    try {
      await _health.requestAuthorization();
      final runs = await _health.fetchRunningWorkouts();
      if (!mounted) return;
      setState(() {
        _all = runs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final window = _widened ? _wideWindow : _narrowWindow;
    final rows = _matcher.candidates(_all, widget.plannedDate, windowDays: window);
    final hasWider = !_widened &&
        _matcher.candidates(_all, widget.plannedDate, windowDays: _wideWindow).length >
            rows.length;
    final dateLabel = DateFormat('EEE, MMM d').format(widget.plannedDate);

    return Scaffold(
      backgroundColor: DashboardColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(dateLabel),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _list(rows, hasWider, dateLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String dateLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 4),
      child: Row(
        children: [
          InkResponse(
            onTap: () => Navigator.of(context).maybePop(),
            radius: 24,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: DashboardColors.avatarBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 15, color: DashboardColors.ink),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a Run',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.ink,
                  letterSpacing: -0.2,
                ),
              ),
              Text('Near $dateLabel',
                  style: const TextStyle(fontSize: 12.5, color: DashboardColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _list(List<RunningWorkout> rows, bool hasWider, String dateLabel) {
    if (rows.isEmpty) {
      return _EmptyState(
        dateLabel: dateLabel,
        onWiden: hasWider ? () => setState(() => _widened = true) : null,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        for (var i = 0; i < rows.length; i++)
          _RunRow(
            run: rows[i],
            isBest: i == 0,
            onTap: () => Navigator.of(context).pop(rows[i]),
          ),
        if (hasWider)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Center(
              child: TextButton(
                onPressed: () => setState(() => _widened = true),
                child: const Text('Show more runs'),
              ),
            ),
          ),
      ],
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run, required this.isBest, required this.onTap});

  final RunningWorkout run;
  final bool isBest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconBg = run.isTreadmill ? const Color(0xFFEAF1FB) : const Color(0xFFE3F6EC);
    final iconColor = run.isTreadmill ? const Color(0xFF4F8FE8) : const Color(0xFF0E9F6E);
    final hr = run.avgHeartRateBpm != null ? ' · ${run.avgHeartRateBpm} bpm avg HR' : '';
    final subtitle =
        '${formatDistanceKm(run.distanceKm)} km · ${formatDuration(run.duration)} · '
        '${formatPace(run.paceSecondsPerKm)}$hr';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isBest ? DashboardColors.brand : DashboardColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                run.isTreadmill ? Icons.fitness_center : Icons.place_outlined,
                size: 16,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('EEE, MMM d').format(run.start),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(DateFormat('h:mm a').format(run.start),
                          style: const TextStyle(fontSize: 12, color: DashboardColors.muted)),
                      if (isBest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFF5EA),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'BEST MATCH',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A6B49),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64726B))),
                  const SizedBox(height: 1),
                  Text(run.sourceName,
                      style: const TextStyle(fontSize: 11, color: DashboardColors.faint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.dateLabel, this.onWiden});

  final String dateLabel;
  final VoidCallback? onWiden;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No runs found around $dateLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DashboardColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try widening the date range to see more Apple Health runs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: DashboardColors.muted),
            ),
            if (onWiden != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onWiden,
                child: const Text('Widen date range'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
