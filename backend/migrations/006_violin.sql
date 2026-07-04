INSERT INTO instruments (id, name, family, frequency_range_min, frequency_range_max, note_range_low, note_range_high, tuning, techniques, config)
VALUES (
  'violin',
  'Violin',
  'stringed',
  196,
  3520,
  'G3',
  'A7',
  '["G3","D4","A4","E5"]',
  '["vibrato","legato","staccato","pizzicato"]',
  '{"pitchToleranceCents": 25, "timingToleranceMs": 70}'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO musical_content (id, type, title, instrument_id, difficulty_level, bpm, key, expected_notes)
VALUES
  (
    '01111111-1111-1111-1111-111111111111',
    'lesson',
    'Open G String',
    'violin',
    1,
    60,
    'G',
    '[
      {"note":"G3","startMs":0,"durationMs":600},
      {"note":"G3","startMs":700,"durationMs":600},
      {"note":"A3","startMs":1400,"durationMs":600}
    ]'
  ),
  (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'lesson',
    'D String Scale',
    'violin',
    2,
    70,
    'D',
    '[
      {"note":"D4","startMs":0,"durationMs":500},
      {"note":"E4","startMs":550,"durationMs":500},
      {"note":"F#4","startMs":1100,"durationMs":500}
    ]'
  ),
  (
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'solo',
    'Simple Folk Melody',
    'violin',
    2,
    85,
    'G',
    '[
      {"note":"G4","startMs":0,"durationMs":400},
      {"note":"B4","startMs":450,"durationMs":400},
      {"note":"D5","startMs":900,"durationMs":600}
    ]'
  )
ON CONFLICT (id) DO NOTHING;
