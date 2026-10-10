CREATE TABLE IF NOT EXISTS devices (
  id uuid PRIMARY KEY,
  apns_token text,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS device_teams (
  device_id uuid NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  team_name text NOT NULL,
  PRIMARY KEY (device_id, team_name)
);

CREATE TABLE IF NOT EXISTS games (
  game_pk integer PRIMARY KEY,
  game_date date NOT NULL,
  detailed_state text NOT NULL,
  home_team_id integer NOT NULL,
  away_team_id integer NOT NULL,
  home_name text NOT NULL,
  away_name text NOT NULL,
  home_score integer NOT NULL,
  away_score integer NOT NULL,
  inning integer,
  inning_state text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS lineups (
  game_pk integer NOT NULL,
  side text NOT NULL CHECK (side IN ('home', 'away')),
  batting_order integer NOT NULL,
  player_id integer NOT NULL,
  player_name text NOT NULL,
  position text NOT NULL DEFAULT '',
  PRIMARY KEY (game_pk, side, batting_order)
);

CREATE TABLE IF NOT EXISTS jobs (
  id bigserial PRIMARY KEY,
  kind text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  run_at timestamptz NOT NULL DEFAULT now(),
  locked_at timestamptz,
  locked_by text,
  attempts integer NOT NULL DEFAULT 0,
  last_error text,
  done_at timestamptz
);

CREATE INDEX IF NOT EXISTS jobs_ready_idx
  ON jobs (run_at, id)
  WHERE done_at IS NULL;

CREATE TABLE IF NOT EXISTS notifications (
  id bigserial PRIMARY KEY,
  device_id uuid NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  kind text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  dedupe_key text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  apns_sent_at timestamptz,
  UNIQUE (device_id, dedupe_key)
);
