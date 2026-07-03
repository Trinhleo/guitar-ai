import 'package:network/network.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  AuthStore(this.api);

  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';

  final ApiClient api;
  String? email;

  bool get isLoggedIn => api.token != null && api.token!.isNotEmpty;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    email = prefs.getString(_emailKey);
    api.token = token;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await api.login(email: email, password: password);
    await _persist(response.token, response.email);
    return response;
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await api.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    await _persist(response.token, response.email);
    return response;
  }

  Future<void> logout() async {
    api.token = null;
    email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }

  Future<void> _persist(String token, String userEmail) async {
    email = userEmail;
    api.token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, userEmail);
  }
}
