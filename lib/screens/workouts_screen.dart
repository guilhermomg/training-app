import 'package:flutter/material.dart';

import '../models/running_workout.dart';
import '../services/health_service.dart';
import '../widgets/workout_tile.dart';

enum _ScreenState { loading, needsAuth, ready, error }

/// Home screen: imports and lists running workouts from Apple Health.
class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key, this.healthService});

  final HealthService? healthService;

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  late final HealthService _health = widget.healthService ?? HealthService();

  _ScreenState _state = _ScreenState.loading;
  List<RunningWorkout> _workouts = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = _ScreenState.loading;
      _errorMessage = null;
    });

    try {
      final granted = await _health.requestAuthorization();
      if (!granted) {
        if (!mounted) return;
        setState(() => _state = _ScreenState.needsAuth);
        return;
      }

      final workouts = await _health.fetchRunningWorkouts();
      if (!mounted) return;
      setState(() {
        _workouts = workouts;
        _state = _ScreenState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running'),
        actions: [
          if (_state == _ScreenState.ready)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _load,
            ),
        ],
      ),
      body: switch (_state) {
        _ScreenState.loading => const _Centered(child: CircularProgressIndicator()),
        _ScreenState.needsAuth => _NeedsAuth(onGrant: _load),
        _ScreenState.error => _ErrorView(message: _errorMessage, onRetry: _load),
        _ScreenState.ready => _WorkoutsList(workouts: _workouts, onRefresh: _load),
      },
    );
  }
}

class _WorkoutsList extends StatelessWidget {
  const _WorkoutsList({required this.workouts, required this.onRefresh});

  final List<RunningWorkout> workouts;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            _EmptyView(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: workouts.length,
        itemBuilder: (context, index) => WorkoutTile(workout: workouts[index]),
      ),
    );
  }
}

class _NeedsAuth extends StatelessWidget {
  const _NeedsAuth({required this.onGrant});

  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return _Centered(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.health_and_safety_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Connect Apple Health',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Grant read access so your running sessions can be imported.\n'
              'If you already declined, enable it in Settings › Health › '
              'Data Access & Devices › Training App.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGrant,
              icon: const Icon(Icons.link),
              label: const Text('Grant access'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return _Centered(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_run, size: 56),
            const SizedBox(height: 16),
            Text(
              'No running workouts found',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Runs from the last 6 months will appear here.\nPull down to refresh.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Centered(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Couldn’t load workouts',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}
