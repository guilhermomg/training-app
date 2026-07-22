import 'package:flutter/material.dart';

import '../../models/training/dashboard_view.dart';
import '../../theme/dashboard_colors.dart';
import 'session_row.dart';

/// A collapsible week card: header (Week N, summary, status pill, chevron)
/// that expands to reveal its session rows.
class WeekCard extends StatelessWidget {
  const WeekCard({
    super.key,
    required this.week,
    required this.expanded,
    required this.onToggle,
    this.onTapSession,
  });

  final WeekView week;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(int sessionId)? onTapSession;

  @override
  Widget build(BuildContext context) {
    final ws = DashboardColors.weekStatus(week.status);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: DashboardColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${week.number}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: DashboardColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          week.summary,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DashboardColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(label: ws.label, bg: ws.bg, fg: ws.fg),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: DashboardColors.faint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < week.sessions.length; i++)
                          SessionRow(
                            session: week.sessions[i],
                            isLast: i == week.sessions.length - 1,
                            onTap: onTapSession == null
                                ? null
                                : () => onTapSession!(week.sessions[i].sessionId),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
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
