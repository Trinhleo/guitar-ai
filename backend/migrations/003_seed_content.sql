INSERT INTO musical_content (id, type, title, instrument_id, difficulty_level, bpm, key, expected_notes)
VALUES
  (
    '22222222-2222-2222-2222-222222222222',
    'solo',
    'Blues Lick in A',
    'guitar',
    2,
    90,
    'A',
    '[
      {"note":"A4","startMs":0,"durationMs":400},
      {"note":"C5","startMs":450,"durationMs":400},
      {"note":"E5","startMs":900,"durationMs":500}
    ]'
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    'solo',
    'Pentatonic Run',
    'guitar',
    3,
    100,
    'E',
    '[
      {"note":"E4","startMs":0,"durationMs":250},
      {"note":"G4","startMs":300,"durationMs":250},
      {"note":"A4","startMs":600,"durationMs":250},
      {"note":"B4","startMs":900,"durationMs":250}
    ]'
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    'chord',
    'G-C-D Progression',
    'guitar',
    1,
    70,
    'G',
    '[
      {"note":"G3","startMs":0,"durationMs":800},
      {"note":"C4","startMs":900,"durationMs":800},
      {"note":"D4","startMs":1800,"durationMs":800}
    ]'
  ),
  (
    '55555555-5555-5555-5555-555555555555',
    'chord',
    'Am-F-C-G Progression',
    'guitar',
    2,
    75,
    'C',
    '[
      {"note":"A3","startMs":0,"durationMs":700},
      {"note":"F3","startMs":800,"durationMs":700},
      {"note":"C4","startMs":1600,"durationMs":700},
      {"note":"G3","startMs":2400,"durationMs":700}
    ]'
  )
ON CONFLICT (id) DO NOTHING;
