/// App configuration sourced from compile-time defines.
///
/// Values are injected with `--dart-define-from-file=env.json` (git-ignored).
/// See `env.example.json` for the expected shape. The Supabase anon/publishable
/// key is safe to ship in a client — row access is enforced by RLS — but is kept
/// out of the public repo regardless.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Deep-link scheme + redirect used by the Supabase Google OAuth flow.
  /// The scheme is registered in ios/Runner/Info.plist, and the full redirect
  /// URL must be allow-listed in Supabase → Auth → URL Configuration.
  static const String authRedirectUrl = 'com.gmg.training://login-callback';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
