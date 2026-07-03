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

  group('AuthResponse', () {
    test('parses auth payload', () {
      final auth = AuthResponse.fromJson({
        'token': 'jwt-token',
        'userId': 'user-123',
        'email': 'student@example.com',
      });

      expect(auth.token, 'jwt-token');
      expect(auth.userId, 'user-123');
      expect(auth.email, 'student@example.com');
    });
  });

  group('ApiClient', () {
    test('stores bearer token for authenticated requests', () {
      final api = ApiClient();
      expect(api.token, isNull);

      api.token = 'abc123';
      expect(api.token, 'abc123');
    });
  });

  group('PracticeResults', () {
    test('parses session detail payload', () {
      final results = PracticeResults.fromJson({
        'contentTitle': 'Open String Exercise',
        'contentType': 'lesson',
        'session': {
          'overall_score': 95.0,
          'created_at': '2026-07-03T00:00:00Z',
        },
        'metrics': {
          'pitch_accuracy': 98.0,
          'timing_accuracy': 92.0,
          'technique_score': 90.0,
        },
        'expectedNotes': [
          {'note': 'E4', 'startMs': 0, 'durationMs': 500},
        ],
        'playedNotes': [
          {'note': 'E4', 'startMs': 0, 'durationMs': 500},
        ],
      });

      expect(results.contentTitle, 'Open String Exercise');
      expect(results.playedNotes.length, 1);
      expect(results.expectedNotes.length, 1);
    });
  });
}
