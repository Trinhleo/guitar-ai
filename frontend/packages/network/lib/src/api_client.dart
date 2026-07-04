import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_endpoints.dart';
import 'models.dart';

class ApiClient {
  ApiClient({String? baseUrl, List<String>? fallbackBaseUrls})
      : _endpoints = ApiEndpoints(
          primary: baseUrl,
          fallbacks: fallbackBaseUrls,
        );

  final ApiEndpoints _endpoints;

  /// Active API origin (may switch after [initialize] or failed requests).
  String get baseUrl => _endpoints.activeBaseUrl;

  List<String> get baseUrls => List.unmodifiable(_endpoints.candidates);

  String? _token;

  String? get token => _token;

  set token(String? value) => _token = value;

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  /// Probe `/health` on each candidate and pin the first healthy endpoint.
  Future<void> initialize({Duration timeout = const Duration(seconds: 5)}) async {
    for (final candidate in _endpoints.candidates) {
      try {
        final response = await http
            .get(_endpoints.healthUri(candidate))
            .timeout(timeout);
        if (response.statusCode == 200) {
          _endpoints.activeBaseUrl = candidate;
          return;
        }
      } on Object {
        // try next candidate
      }
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _post(
      '/api/auth/register',
      body: jsonEncode({
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      }),
      expectedStatus: 201,
    );
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
    final response = await _post(
      '/api/auth/login',
      body: jsonEncode({'email': email, 'password': password}),
    );
    final auth = AuthResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    token = auth.token;
    return auth;
  }

  Future<List<Instrument>> listInstruments() async {
    final response = await _get('/api/instruments');
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

    final response = await _get('/api/content', query: query);
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => MusicalContent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MusicalContent> getContent(String id) async {
    final response = await _get('/api/content/$id');
    return MusicalContent.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Recommendation>> getRecommendations({
    String instrument = 'guitar',
    int limit = 3,
  }) async {
    final response = await _get(
      '/api/content/recommendations',
      query: {'instrument': instrument, 'limit': '$limit'},
      auth: true,
    );
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
    final response = await _post(
      '/api/practice/start/$contentId',
      body: jsonEncode({'instrumentId': instrumentId}),
      expectedStatus: 201,
      auth: true,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['sessionId'] as String;
  }

  Future<EvaluationScores> evaluatePractice({
    required String sessionId,
    required List<PracticeNote> playedNotes,
  }) async {
    final response = await _post(
      '/api/practice/$sessionId/evaluate',
      body: jsonEncode({
        'playedNotes': playedNotes.map((note) => note.toJson()).toList(),
      }),
      auth: true,
    );
    return EvaluationScores.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PracticeResults> getResults(String sessionId) async {
    final response = await _get(
      '/api/practice/$sessionId/results',
      auth: true,
    );
    return PracticeResults.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PracticeHistoryResponse> listPracticeHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _get(
      '/api/practice/history',
      query: {'limit': '$limit', 'offset': '$offset'},
      auth: true,
    );
    return PracticeHistoryResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserProgress> getProgress() async {
    final response = await _get('/api/stats/progress', auth: true);
    return UserProgress.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Achievement>> getAchievements() async {
    final response = await _get('/api/stats/achievements', auth: true);
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
    final response = await _get(
      '/api/stats/leaderboard',
      query: query,
      auth: true,
    );
    return LeaderboardResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PracticeInsightsResponse> getPracticeInsights() async {
    final response = await _get('/api/stats/insights', auth: true);
    return PracticeInsightsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> uploadPracticeAudio({
    required String sessionId,
    required List<int> wavBytes,
    required String filename,
  }) async {
    return _executeJson((baseUrl) async {
      final request = http.MultipartRequest(
        'POST',
        _endpoints.apiUri(baseUrl, '/api/practice/$sessionId/upload'),
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

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      return http.Response.fromStream(streamed);
    });
  }

  Future<http.Response> _get(
    String path, {
    Map<String, String>? query,
    bool auth = false,
    int expectedStatus = 200,
  }) {
    return _execute((baseUrl) {
      final headers = auth ? _jsonHeaders : null;
      return http
          .get(_endpoints.apiUri(baseUrl, path, query: query), headers: headers)
          .timeout(const Duration(seconds: 15));
    }, expectedStatus: expectedStatus);
  }

  Future<http.Response> _post(
    String path, {
    required String body,
    bool auth = false,
    int expectedStatus = 200,
  }) {
    return _execute((baseUrl) {
      final headers = auth ? _jsonHeaders : _jsonHeaders;
      return http
          .post(
            _endpoints.apiUri(baseUrl, path),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));
    }, expectedStatus: expectedStatus);
  }

  Future<Map<String, dynamic>> _executeJson(
    Future<http.Response> Function(String baseUrl) action,
  ) async {
    final response = await _execute(action);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<http.Response> _execute(
    Future<http.Response> Function(String baseUrl) action, {
    int expectedStatus = 200,
  }) async {
    Object? lastError;

    for (final candidate in _endpoints.orderedForRetry()) {
      try {
        final response = await action(candidate);
        if (_endpoints.shouldFailoverForStatus(response.statusCode)) {
          lastError = ApiException(
            'Endpoint unavailable (${response.statusCode}): $candidate',
          );
          continue;
        }
        _ensureSuccess(response, expectedStatus: expectedStatus);
        _endpoints.activeBaseUrl = candidate;
        return response;
      } on ApiException catch (error) {
        lastError = error;
        if (candidate != _endpoints.candidates.last) {
          continue;
        }
        rethrow;
      } on Object catch (error) {
        lastError = error;
      }
    }

    throw ApiException(
      'All API endpoints failed (${_endpoints.candidates.join(', ')}): $lastError',
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
