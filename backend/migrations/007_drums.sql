INSERT INTO instruments (id, name, family, frequency_range_min, frequency_range_max, note_range_low, note_range_high, tuning, techniques, config)
VALUES (
  'drums',
  'Drums',
  'percussion',
  50,
  500,
  'C2',
  'C3',
  '[]',
  '["ghost-note","fill","dynamics","paradiddle"]',
  '{"pitchToleranceCents": 100, "timingToleranceMs": 35}'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO musical_content (id, type, title, instrument_id, difficulty_level, bpm, key, expected_notes)
VALUES
  (
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    'lesson',
    'Basic Rock Beat',
    'drums',
    1,
    90,
    NULL,
    '[
      {"note":"C2","startMs":0,"durationMs":250},
      {"note":"F#2","startMs":250,"durationMs":250},
      {"note":"D2","startMs":500,"durationMs":250},
      {"note":"F#2","startMs":750,"durationMs":250}
    ]'
  ),
  (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'lesson',
    'Single Stroke Roll',
    'drums',
    2,
    100,
    NULL,
    '[
      {"note":"D2","startMs":0,"durationMs":150},
      {"note":"D2","startMs":200,"durationMs":150},
      {"note":"D2","startMs":400,"durationMs":150},
      {"note":"D2","startMs":600,"durationMs":150}
    ]'
  ),
  (
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'solo',
    'Simple Fill',
    'drums',
    2,
    110,
    NULL,
    '[
      {"note":"C2","startMs":0,"durationMs":200},
      {"note":"D2","startMs":250,"durationMs":200},
      {"note":"F#2","startMs":500,"durationMs":200},
      {"note":"D2","startMs":750,"durationMs":300}
    ]'
  )
ON CONFLICT (id) DO NOTHING;
