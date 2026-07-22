import 'package:flutter/material.dart';

import '../../models/training/dashboard_view.dart';
import '../../theme/dashboard_colors.dart';

/// The green gradient hero card summarizing the user's goal.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, this.showAdherence = true});

  final GoalView goal;
  final bool showAdherence;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
          const Text(
            'YOUR GOAL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            goal.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${goal.dateLabel} · ${goal.sessionsPerWeek} sessions / week',
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.2),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Divider(color: Colors.white.withValues(alpha: 0.22), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                _Stat(value: goal.weekProgress, label: 'Week'),
                _Stat(value: '${goal.daysToGo}', label: 'Days to go'),
                if (showAdherence)
                  _Stat(value: '${goal.adherencePercent}%', label: 'Adherence'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
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
      ),
    );
  }
}
