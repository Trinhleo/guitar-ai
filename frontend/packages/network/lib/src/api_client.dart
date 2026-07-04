import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'models.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  final String baseUrl;
  String? _token;

  String? get token => _token;

  set token(String? value) => _token = value;

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      }),
    );
    _ensureSuccess(response, expectedStatus: 201);
    final auth = AuthResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    token = auth.token;
    return auth;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    _ensureSuccess(response);
    final auth = AuthResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    token = auth.token;
    return auth;
  }

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

  Future<List<Recommendation>> getRecommendations({
    String instrument = 'guitar',
    int limit = 3,
  }) async {
    final uri = Uri.parse('$baseUrl/api/content/recommendations').replace(
      queryParameters: {
        'instrument': instrument,
        'limit': '$limit',
      },
    );
    final response = await http.get(uri, headers: _jsonHeaders);
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => Recommendation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> startPractice({
    required String contentId,
    String instrumentId = 'guitar',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/practice/start/$contentId'),
      headers: _jsonHeaders,
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
      headers: _jsonHeaders,
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
    final response = await http.get(
      Uri.parse('$baseUrl/api/practice/$sessionId/results'),
      headers: _jsonHeaders,
    );
    _ensureSuccess(response);
    return PracticeResults.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PracticeHistoryResponse> listPracticeHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/api/practice/history').replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final response = await http.get(uri, headers: _jsonHeaders);
    _ensureSuccess(response);
    return PracticeHistoryResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserProgress> getProgress() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/progress'),
      headers: _jsonHeaders,
    );
    _ensureSuccess(response);
    return UserProgress.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Achievement>> getAchievements() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/achievements'),
      headers: _jsonHeaders,
    );
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['achievements'] as List<dynamic>? ?? [];
    return items
        .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LeaderboardResponse> getLeaderboard({
    String? instrument,
    int limit = 10,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (instrument != null && instrument.isNotEmpty) {
      query['instrument'] = instrument;
    }
    final uri = Uri.parse('$baseUrl/api/stats/leaderboard').replace(
      queryParameters: query,
    );
    final response = await http.get(uri, headers: _jsonHeaders);
    _ensureSuccess(response);
    return LeaderboardResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PracticeInsightsResponse> getPracticeInsights() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/insights'),
      headers: _jsonHeaders,
    );
    _ensureSuccess(response);
    return PracticeInsightsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> uploadPracticeAudio({
    required String sessionId,
    required List<int> wavBytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/practice/$sessionId/upload'),
    );
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(http.MultipartFile.fromBytes(
      'audio',
      wavBytes,
      filename: filename,
      contentType: MediaType('audio', 'wav'),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
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
