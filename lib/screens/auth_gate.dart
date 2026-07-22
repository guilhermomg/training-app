import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/dashboard_colors.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

/// Routes between the login screen and the dashboard based on the Supabase
/// auth session. Rebuilds automatically as the session changes (including the
/// OAuth deep-link callback).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        // onAuthStateChange emits the restored session on startup; until then,
        // fall back to any session the client already holds.
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session != null) {
          return const DashboardScreen();
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            auth.currentSession == null) {
          return const Scaffold(
            backgroundColor: DashboardColors.scaffold,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const LoginScreen();
      },
    );
  }
}
