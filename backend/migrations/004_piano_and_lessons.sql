INSERT INTO instruments (id, name, family, frequency_range_min, frequency_range_max, note_range_low, note_range_high, tuning, techniques, config)
VALUES (
  'piano',
  'Piano',
  'keyboard',
  27,
  4186,
  'A0',
  'C8',
  '[]',
  '["sustain","staccato","legato","dynamics"]',
  '{"pitchToleranceCents": 30, "timingToleranceMs": 60}'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO musical_content (id, type, title, instrument_id, difficulty_level, bpm, key, expected_notes)
VALUES
  (
    '66666666-6666-6666-6666-666666666666',
    'lesson',
    'Middle C Scale',
    'piano',
    1,
    60,
    'C',
    '[
      {"note":"C4","startMs":0,"durationMs":500},
      {"note":"D4","startMs":600,"durationMs":500},
      {"note":"E4","startMs":1200,"durationMs":500},
      {"note":"F4","startMs":1800,"durationMs":500}
    ]'
  ),
  (
    '77777777-7777-7777-7777-777777777777',
    'lesson',
    'Twinkle Opening',
    'piano',
    1,
    80,
    'C',
    '[
      {"note":"C4","startMs":0,"durationMs":400},
      {"note":"C4","startMs":500,"durationMs":400},
      {"note":"G4","startMs":1000,"durationMs":400},
      {"note":"G4","startMs":1500,"durationMs":400}
    ]'
  ),
  (
    '88888888-8888-8888-8888-888888888888',
    'solo',
    'Simple Melody in G',
    'piano',
    2,
    90,
    'G',
    '[
      {"note":"G4","startMs":0,"durationMs":350},
      {"note":"A4","startMs":400,"durationMs":350},
      {"note":"B4","startMs":800,"durationMs":350},
      {"note":"G4","startMs":1200,"durationMs":700}
    ]'
  ),
  (
    '99999999-9999-9999-9999-999999999999',
    'lesson',
    'Hammer-On Basics',
    'guitar',
    2,
    85,
    'E',
    '[
      {"note":"E4","startMs":0,"durationMs":400},
      {"note":"G4","startMs":450,"durationMs":400},
      {"note":"A4","startMs":900,"durationMs":400}
    ]'
  )
ON CONFLICT (id) DO NOTHING;
