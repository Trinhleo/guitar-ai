/// Resolves primary + fallback API base URLs from compile-time defines.
class ApiEndpoints {
  final List<String> candidates;
  late String activeBaseUrl;

  ApiEndpoints({
    String? primary,
    List<String>? fallbacks,
  }) : candidates = _buildCandidates(
          primary ?? _primaryFromEnv,
          fallbacks ?? fallbacksFromEnvString(_fallbacksFromEnv),
        ) {
    activeBaseUrl = candidates.first;
  }

  static const _primaryFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  static const _fallbacksFromEnv = String.fromEnvironment(
    'API_FALLBACK_URLS',
    defaultValue: '',
  );

  static List<String> _buildCandidates(String primary, List<String> fallbacks) {
    final seen = <String>{};
    final ordered = <String>[];

    void add(String raw) {
      final normalized = normalizeBaseUrl(raw);
      if (normalized.isEmpty || seen.contains(normalized)) {
        return;
      }
      seen.add(normalized);
      ordered.add(normalized);
    }

    add(primary);
    for (final url in fallbacks) {
      add(url);
    }

    if (ordered.isEmpty) {
      ordered.add('');
    }
    return ordered;
  }

  static List<String> parseFallbackList(String raw) {
    if (raw.trim().isEmpty) {
      return [];
    }
    return raw.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
  }

  static List<String> fallbacksFromEnvString(String envValue) {
    return parseFallbackList(envValue);
  }

  static String normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  Uri healthUri(String baseUrl) {
    if (baseUrl.isEmpty) {
      return Uri.parse('/health');
    }
    return Uri.parse('$baseUrl/health');
  }

  Uri apiUri(String baseUrl, String path, {Map<String, String>? query}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    if (baseUrl.isEmpty) {
      return Uri.parse(normalizedPath).replace(queryParameters: query);
    }
    return Uri.parse('$baseUrl$normalizedPath').replace(queryParameters: query);
  }

  /// Ordered list with active endpoint first after initialization.
  List<String> orderedForRetry() {
    if (candidates.length <= 1) {
      return List<String>.from(candidates);
    }
    final rest = candidates.where((url) => url != activeBaseUrl).toList();
    return [activeBaseUrl, ...rest];
  }

  bool shouldFailoverForStatus(int statusCode) {
    return statusCode == 502 || statusCode == 503 || statusCode == 504;
  }
}
