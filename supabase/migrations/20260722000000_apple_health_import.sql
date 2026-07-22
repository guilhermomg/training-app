-- Apple Health workout import
--
-- Adds storage for running workouts imported from Apple Health (HealthKit),
-- including the heart-rate time series and GPS route, plus a link from a logged
-- training session back to the imported workout it was created from.
--
-- Heart-rate and route are stored as jsonb arrays on the workout: they are
-- written once at import time and always read whole (to draw a chart / map),
-- so a single row per workout keeps the mobile import to one insert.
--
-- Schema: training. RLS-scoped to the owning user, matching the existing
-- plans / sessions / logged_sessions policies.

-- 1. The imported workout -------------------------------------------------

create table training.imported_workouts (
  id                bigint generated always as identity primary key,
  user_id           uuid not null references auth.users (id),

  -- Provenance. external_id is the HealthKit workout UUID; the unique
  -- constraint makes re-imports idempotent (upsert on conflict).
  source            varchar not null default 'apple_health',
  external_id       text not null,
  source_name       text,                 -- e.g. 'Apple Watch', third-party app
  workout_type      varchar,              -- 'running' | 'running_treadmill'

  -- Timing
  start_time        timestamptz not null,
  end_time          timestamptz not null,
  duration_secs     integer,              -- elapsed (end - start)
  moving_secs       integer,              -- active/moving time when available

  -- Summary metrics
  distance_m        numeric,
  avg_pace_secs     integer,              -- seconds per km
  avg_hr_bpm        integer,
  max_hr_bpm        integer,
  avg_cadence_spm   integer,              -- steps per minute
  active_energy_kcal integer,
  total_energy_kcal integer,
  elevation_gain_m  numeric,

  -- Time series, read whole when rendering.
  --   hr_series: [{ "t": <epoch ms>, "bpm": <int> }, ...]
  --   route:     [{ "t": <epoch ms>, "lat": <num>, "lng": <num>,
  --                 "alt": <num?>, "spd": <num?>, "acc": <num?> }, ...]
  hr_series         jsonb,
  route             jsonb,

  -- Anything else HealthKit reports (device, weather, HK metadata, …)
  metadata          jsonb,

  imported_at       timestamptz not null default now(),

  unique (user_id, source, external_id)
);

create index imported_workouts_user_start_idx
  on training.imported_workouts (user_id, start_time desc);

-- 2. Link a logged session to its source workout --------------------------

alter table training.logged_sessions
  add column imported_workout_id bigint
    references training.imported_workouts (id) on delete set null;

create index logged_sessions_imported_workout_idx
  on training.logged_sessions (imported_workout_id);

-- 3. Row-level security ---------------------------------------------------

alter table training.imported_workouts enable row level security;

create policy "Users manage their own imported workouts"
  on training.imported_workouts for all to public
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
