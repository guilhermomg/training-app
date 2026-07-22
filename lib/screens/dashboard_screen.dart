import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/training/dashboard_view.dart';
import '../services/dashboard_builder.dart';
import '../services/training_repository.dart';
import '../theme/dashboard_colors.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/goal_card.dart';
import '../widgets/dashboard/phase_section.dart';
import 'workouts_screen.dart';

/// Home screen after login: the training dashboard (goal + phases/weeks/sessions).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.repository,
    this.previewView,
  });

  final TrainingRepository? repository;

  /// When provided, the screen renders this immediately and skips loading —
  /// used by tests and previews so no Supabase session is required.
  final DashboardView? previewView;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum _State { loading, ready, empty, error }

class _DashboardScreenState extends State<DashboardScreen> {
  static const _builder = DashboardBuilder();

  _State _state = _State.loading;
  DashboardView? _view;
  final Set<int> _expanded = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.previewView != null) {
      _applyView(widget.previewView!);
    } else {
      _load();
    }
  }

  void _applyView(DashboardView view) {
    _view = view;
    _expanded
      ..clear()
      ..addAll(view.initiallyExpanded);
    _state = _State.ready;
  }

  Future<void> _load() async {
    setState(() {
      _state = _State.loading;
      _error = null;
    });
    try {
      final repo = widget.repository ?? TrainingRepository();
      final data = await repo.fetchCurrentPlan();
      if (!mounted) return;
      setState(() {
        if (data == null) {
          _state = _State.empty;
        } else {
          _applyView(_builder.build(data));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _State.error;
        _error = e.toString();
      });
    }
  }

  void _toggleWeek(int weekNumber) {
    setState(() {
      if (!_expanded.remove(weekNumber)) _expanded.add(weekNumber);
    });
  }

  Future<void> _onMenu(DashboardMenuAction action) async {
    switch (action) {
      case DashboardMenuAction.appleHealth:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WorkoutsScreen()),
        );
      case DashboardMenuAction.signOut:
        await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardHeader(onSelect: _onMenu),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_state) {
      case _State.loading:
        return const Center(child: CircularProgressIndicator());
      case _State.error:
        return _Message(
          icon: Icons.error_outline,
          title: 'Couldn’t load your plan',
          detail: _error,
          onRetry: _load,
        );
      case _State.empty:
        return const _Message(
          icon: Icons.calendar_today_outlined,
          title: 'No training plan yet',
          detail: 'Create a plan in the web app and it will show up here.',
        );
      case _State.ready:
        final view = _view!;
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              GoalCard(goal: view.goal),
              for (final phase in view.phases)
                PhaseSection(
                  phase: phase,
                  isExpanded: _expanded.contains,
                  onToggleWeek: _toggleWeek,
                ),
            ],
          ),
        );
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.detail,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: DashboardColors.muted),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: DashboardColors.ink,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: DashboardColors.muted),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
