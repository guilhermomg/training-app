import 'package:flutter/material.dart';

import '../models/training/dashboard_view.dart';

/// Palette lifted from the Claude Design file `Running Dashboard.dc.html`.
class DashboardColors {
  const DashboardColors._();

  static const scaffold = Color(0xFFF6F8F7);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFEEF1EF);
  static const rowBorder = Color(0xFFF0F2F0);

  static const ink = Color(0xFF16211C);
  static const muted = Color(0xFF8A948E);
  static const faint = Color(0xFFB5BDB8);

  static const brand = Color(0xFF0E9F6E);
  static const brandDark = Color(0xFF0A6B49);
  static const goalGradientStart = Color(0xFF0EA579);
  static const goalGradientEnd = Color(0xFF0A6B4A);

  static const avatarBg = Color(0xFFEAEEEC);

  /// Dot color per session type, keyed by display name (design's TYPE_DOT).
  static const _typeDot = <String, Color>{
    'Easy Run': Color(0xFF4F8FE8),
    'Tempo Run': Color(0xFFE8A23A),
    'Long Run': Color(0xFF0E9F6E),
    'Interval Run': Color(0xFF9B59D0),
    'Shakeout Run': Color(0xFF4F8FE8),
    'Race Day': Color(0xFF0E9F6E),
  };

  static Color typeDot(String type) => _typeDot[type] ?? muted;

  static WeekStatusStyle weekStatus(WeekStatus s) => switch (s) {
        WeekStatus.completed => const WeekStatusStyle(
            label: 'Completed',
            bg: Color(0xFFDFF5EA),
            fg: Color(0xFF0A6B49),
            cardBorder: DashboardColors.cardBorder,
          ),
        WeekStatus.current => const WeekStatusStyle(
            label: 'In Progress',
            bg: Color(0xFF0E9F6E),
            fg: Color(0xFFFFFFFF),
            cardBorder: Color(0xFF0E9F6E),
          ),
        WeekStatus.upcoming => const WeekStatusStyle(
            label: 'Upcoming',
            bg: Color(0xFFEEF1EF),
            fg: Color(0xFF8A948E),
            cardBorder: DashboardColors.cardBorder,
          ),
      };

  static SessionStateStyle sessionState(SessionState s) => switch (s) {
        SessionState.done => const SessionStateStyle(
            iconBg: Color(0xFF0E9F6E),
            iconFg: Color(0xFFFFFFFF),
            iconBorder: Color(0xFF0E9F6E),
            label: 'Completed',
            labelColor: Color(0xFF0A6B49),
            targetColor: DashboardColors.ink,
            glyph: '✓',
          ),
        SessionState.modified => const SessionStateStyle(
            iconBg: Color(0xFFB8790A),
            iconFg: Color(0xFFFFFFFF),
            iconBorder: Color(0xFFB8790A),
            label: 'Completed · Modified',
            labelColor: Color(0xFF8A5A07),
            targetColor: DashboardColors.ink,
            glyph: '✓',
          ),
        SessionState.skipped => const SessionStateStyle(
            iconBg: Color(0xFFFBE4E1),
            iconFg: Color(0xFFC0392B),
            iconBorder: Color(0xFFF3BDB6),
            label: 'Skipped',
            labelColor: Color(0xFF96271B),
            targetColor: DashboardColors.muted,
            glyph: '✕',
          ),
        SessionState.today => const SessionStateStyle(
            iconBg: Color(0xFFDFF5EA),
            iconFg: Color(0xFF0E9F6E),
            iconBorder: Color(0xFF0E9F6E),
            label: 'Today',
            labelColor: Color(0xFF0A6B49),
            targetColor: DashboardColors.ink,
            innerDot: true,
          ),
        SessionState.upcoming => const SessionStateStyle(
            iconBg: Color(0xFFFFFFFF),
            iconFg: Color(0xFFC7CDC9),
            iconBorder: Color(0xFFD8DEDA),
            label: '',
            labelColor: DashboardColors.faint,
            targetColor: DashboardColors.muted,
          ),
      };
}

class WeekStatusStyle {
  final String label;
  final Color bg;
  final Color fg;
  final Color cardBorder;
  const WeekStatusStyle({
    required this.label,
    required this.bg,
    required this.fg,
    required this.cardBorder,
  });
}

class SessionStateStyle {
  final Color iconBg;
  final Color iconFg;
  final Color iconBorder;
  final String label;
  final Color labelColor;
  final Color targetColor;
  final String glyph;
  final bool innerDot;
  const SessionStateStyle({
    required this.iconBg,
    required this.iconFg,
    required this.iconBorder,
    required this.label,
    required this.labelColor,
    required this.targetColor,
    this.glyph = '',
    this.innerDot = false,
  });
}
