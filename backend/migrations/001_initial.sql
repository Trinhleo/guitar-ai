CREATE TABLE IF NOT EXISTS instruments (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  family VARCHAR(100) NOT NULL,
  frequency_range_min INT,
  frequency_range_max INT,
  note_range_low VARCHAR(10),
  note_range_high VARCHAR(10),
  tuning JSONB DEFAULT '[]',
  techniques JSONB DEFAULT '[]',
  config JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS musical_content (
  id UUID PRIMARY KEY,
  type VARCHAR(20) NOT NULL CHECK (type IN ('lesson', 'solo', 'chord')),
  title VARCHAR(255) NOT NULL,
  instrument_id VARCHAR(50) REFERENCES instruments(id),
  difficulty_level INT NOT NULL CHECK (difficulty_level BETWEEN 1 AND 5),
  duration_seconds INT,
  bpm INT,
  key VARCHAR(10),
  expected_notes JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS practice_sessions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  content_id UUID REFERENCES musical_content(id),
  instrument_id VARCHAR(50) REFERENCES instruments(id),
  overall_score DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES practice_sessions(id) ON DELETE CASCADE,
  pitch_accuracy DECIMAL(5,2),
  timing_accuracy DECIMAL(5,2),
  technique_score DECIMAL(5,2),
  expression_score DECIMAL(5,2),
  consistency_score DECIMAL(5,2),
  instrument_specific_metrics JSONB DEFAULT '{}'
);

INSERT INTO instruments (id, name, family, frequency_range_min, frequency_range_max, note_range_low, note_range_high, tuning, techniques, config)
VALUES (
  'guitar',
  'Guitar',
  'stringed',
  82,
  1319,
  'E2',
  'E6',
  '["E2","A2","D3","G3","B3","E4"]',
  '["bend","vibrato","slide","hammer-on","pull-off"]',
  '{"pitchToleranceCents": 50, "timingToleranceMs": 80}'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO musical_content (id, type, title, instrument_id, difficulty_level, bpm, key, expected_notes)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'lesson',
  'Open String Exercise',
  'guitar',
  1,
  80,
  'E',
  '[
    {"note":"E4","startMs":0,"durationMs":500},
    {"note":"E4","startMs":600,"durationMs":500},
    {"note":"E4","startMs":1200,"durationMs":500}
  ]'
) ON CONFLICT (id) DO NOTHING;
