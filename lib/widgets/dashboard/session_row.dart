import 'package:flutter/material.dart';

import '../../models/training/dashboard_view.dart';
import '../../theme/dashboard_colors.dart';

/// One session line inside an expanded week card.
class SessionRow extends StatelessWidget {
  const SessionRow({
    super.key,
    required this.session,
    this.isLast = false,
    this.onTap,
  });

  final SessionView session;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final st = DashboardColors.sessionState(session.state);
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: DashboardColors.rowBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StateIcon(style: st),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 7, top: 2),
                      decoration: BoxDecoration(
                        color: DashboardColors.typeDot(session.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        session.type,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      ' · ${session.day}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DashboardColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  session.target,
                  style: TextStyle(fontSize: 12.5, color: st.targetColor),
                ),
                if (session.secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.secondary!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: DashboardColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (st.label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                st.label.toUpperCase(),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: st.labelColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.style});

  final SessionStateStyle style;

  @override
  Widget build(BuildContext context) {
    Widget? inner;
    if (style.innerDot) {
      inner = Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: style.iconFg, shape: BoxShape.circle),
      );
    } else if (style.glyph.isNotEmpty) {
      inner = Text(
        style.glyph,
        style: TextStyle(
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w700,
          color: style.iconFg,
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(top: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.iconBg,
        shape: BoxShape.circle,
        border: Border.all(color: style.iconBorder, width: 1.5),
      ),
      child: inner,
    );
  }
}
