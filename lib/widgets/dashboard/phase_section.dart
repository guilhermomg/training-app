import 'package:flutter/material.dart';

import '../../models/training/dashboard_view.dart';
import '../../theme/dashboard_colors.dart';
import 'week_card.dart';

/// A phase heading followed by its collapsible week cards.
class PhaseSection extends StatelessWidget {
  const PhaseSection({
    super.key,
    required this.phase,
    required this.isExpanded,
    required this.onToggleWeek,
  });

  final PhaseView phase;
  final bool Function(int weekNumber) isExpanded;
  final void Function(int weekNumber) onToggleWeek;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Text(
            phase.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: DashboardColors.muted,
            ),
          ),
        ),
        for (final week in phase.weeks)
          WeekCard(
            week: week,
            expanded: isExpanded(week.number),
            onToggle: () => onToggleWeek(week.number),
          ),
      ],
    );
  }
}
