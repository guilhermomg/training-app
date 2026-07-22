import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/training/training_models.dart';

/// Reads the current training plan (with phases, sessions, steps and logs)
/// from the `training` Supabase schema. Mirrors the web app's getTrainingData()
/// (packages/training/src/lib/supabase/training.ts). RLS scopes every row to the
/// signed-in user, so this returns null when there is no plan for them.
class TrainingRepository {
  TrainingRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseQuerySchema get _db => _client.schema('training');

  Future<TrainingData?> fetchCurrentPlan() async {
    final planRows = await _db
        .from('plans')
        .select()
        .order('created_at', ascending: false)
        .limit(1);
    if (planRows.isEmpty) return null;
    final plan = TrainingPlan.fromMap(planRows.first);

    final results = await Future.wait([
      _db.from('phases').select().eq('plan_id', plan.id).order('sort_order'),
      _db
          .from('sessions')
          .select()
          .eq('plan_id', plan.id)
          .order('week_number')
          .order('sort_order'),
      _db
          .from('logged_sessions')
          .select()
          .eq('plan_id', plan.id)
          .order('session_date', ascending: false),
    ]);

    final phases = results[0].map(Phase.fromMap).toList();
    final sessionRows = results[1];
    final logged = results[2].map(LoggedSession.fromMap).toList();

    final sessionIds = sessionRows.map((m) => (m['id'] as num).toInt()).toList();

    final stepRows = sessionIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('session_steps')
            .select()
            .inFilter('session_id', sessionIds)
            .order('sort_order');
    final steps = stepRows.map(SessionStep.fromMap).toList();

    final logsBySession = <int, LoggedSession>{};
    for (final l in logged) {
      final sid = l.sessionId;
      if (sid != null && !logsBySession.containsKey(sid)) {
        logsBySession[sid] = l;
      }
    }

    final sessions = sessionRows.map((m) {
      final id = (m['id'] as num).toInt();
      return PlannedSession.fromMap(
        m,
        steps: steps.where((st) => st.sessionId == id).toList(),
        logged: logsBySession[id],
      );
    }).toList();

    return TrainingData(plan: plan, phases: phases, sessions: sessions);
  }
}
