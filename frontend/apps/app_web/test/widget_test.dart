import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  group('PracticeNote', () {
    test('serializes to json', () {
      final note = PracticeNote(note: 'E4', startMs: 0, durationMs: 500);
      expect(note.toJson(), {
        'note': 'E4',
        'startMs': 0,
        'durationMs': 500,
      });
    });
  });

  group('MusicalContent', () {
    test('parses expected notes from api payload', () {
      final content = MusicalContent.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'type': 'lesson',
        'title': 'Open String Exercise',
        'instrument_id': 'guitar',
        'difficulty_level': 1,
        'expected_notes': [
          {'note': 'E4', 'startMs': 0, 'durationMs': 500},
        ],
      });

      expect(content.expectedNotes.length, 1);
      expect(content.expectedNotes.first.note, 'E4');
    });
  });
}
