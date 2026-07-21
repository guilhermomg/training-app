import 'package:flutter/material.dart';

import '../models/running_workout.dart';
import '../utils/formatters.dart';

/// A card summarizing one imported running session.
class WorkoutTile extends StatelessWidget {
  const WorkoutTile({super.key, required this.workout});

  final RunningWorkout workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  workout.isTreadmill
                      ? Icons.fitness_center
                      : Icons.directions_run,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatWorkoutDate(workout.start),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Metric(
                  label: 'Distance',
                  value: '${formatDistanceKm(workout.distanceKm)} km',
                ),
                _Metric(
                  label: 'Duration',
                  value: formatDuration(workout.duration),
                ),
                _Metric(
                  label: 'Pace',
                  value: formatPace(workout.paceSecondsPerKm),
                ),
                if (workout.avgHeartRateBpm != null)
                  _Metric(
                    label: 'Avg HR',
                    value: '${workout.avgHeartRateBpm} bpm',
                  ),
                if (workout.activeEnergyKcal != null)
                  _Metric(
                    label: 'Energy',
                    value: '${workout.activeEnergyKcal} kcal',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              workout.sourceName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
