import 'package:flutter/material.dart';

import '../../theme/dashboard_colors.dart';

enum DashboardMenuAction { appleHealth, signOut }

/// Top bar: "Training" title and a gear button with an overflow menu.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.onSelect});

  final void Function(DashboardMenuAction action) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Training',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: DashboardColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          PopupMenuButton<DashboardMenuAction>(
            tooltip: 'Menu',
            onSelected: onSelect,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: DashboardMenuAction.appleHealth,
                child: Row(children: [
                  Icon(Icons.directions_run, size: 18),
                  SizedBox(width: 10),
                  Text('Apple Health runs'),
                ]),
              ),
              PopupMenuItem(
                value: DashboardMenuAction.signOut,
                child: Row(children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 10),
                  Text('Sign out'),
                ]),
              ),
            ],
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: DashboardColors.avatarBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings, size: 17, color: Color(0xFF64726B)),
            ),
          ),
        ],
      ),
    );
  }
}
