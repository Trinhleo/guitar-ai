import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = 'http://localhost:5000';

  final String baseUrl;

  Future<List<Instrument>> listInstruments() async {
    final response = await http.get(Uri.parse('$baseUrl/api/instruments'));
    _ensureSuccess(response);
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => Instrument.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MusicalContent>> listContent({
    String? type,
    String? instrument,
  }) async {
    final query = <String, String>{};
    if (type != null) query['type'] = type;
    if (instrument != null) query['instrument'] = instrument;

    final uri = Uri.parse('$baseUrl/api/content').replace(queryParameters: query);
    final response = await http.get(uri);
    _ensureSuccess(response);

    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => MusicalContent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MusicalContent> getContent(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/content/$id'));
    _ensureSuccess(response);
    return MusicalContent.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> startPractice({
    required String contentId,
    String instrumentId = 'guitar',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/practice/start/$contentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'instrumentId': instrumentId}),
    );
    _ensureSuccess(response, expectedStatus: 201);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['sessionId'] as String;
  }

  Future<EvaluationScores> evaluatePractice({
    required String sessionId,
    required List<PracticeNote> playedNotes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/practice/$sessionId/evaluate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'playedNotes': playedNotes.map((note) => note.toJson()).toList(),
      }),
    );
    _ensureSuccess(response);
    return EvaluationScores.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PracticeResults> getResults(String sessionId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/practice/$sessionId/results'));
    _ensureSuccess(response);
    return PracticeResults.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void _ensureSuccess(http.Response response, {int expectedStatus = 200}) {
    if (response.statusCode != expectedStatus) {
      throw ApiException(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
