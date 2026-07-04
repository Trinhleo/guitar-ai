-- Deduplicate performance_metrics (keep latest row per session)
DELETE FROM performance_metrics pm
WHERE pm.id NOT IN (
  SELECT DISTINCT ON (session_id) id
  FROM performance_metrics
  ORDER BY session_id, id DESC
);

CREATE UNIQUE INDEX IF NOT EXISTS performance_metrics_session_id_key ON performance_metrics(session_id);

-- Fix legacy violin content UUID that overlapped DemoUserID constant
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM musical_content WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  ) THEN
    DELETE FROM musical_content
    WHERE id = '01111111-1111-1111-1111-111111111111';

    UPDATE practice_sessions
    SET content_id = '01111111-1111-1111-1111-111111111111'
    WHERE content_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    UPDATE musical_content
    SET id = '01111111-1111-1111-1111-111111111111'
    WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  END IF;
END $$;

-- Remove orphan sessions before adding FK
DELETE FROM practice_sessions
WHERE user_id NOT IN (SELECT id FROM users);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'practice_sessions_user_id_fkey'
  ) THEN
    ALTER TABLE practice_sessions
      ADD CONSTRAINT practice_sessions_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_practice_sessions_user_id ON practice_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_practice_sessions_user_created ON practice_sessions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_musical_content_instrument ON musical_content(instrument_id);
