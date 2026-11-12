import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  static const _tokenKey = 'auth_token';

  final ApiService _api;

  AuthStatus status = AuthStatus.initializing;
  User? user;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _api.token = saved;
    try {
      user = await _api.getProfile();
      status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      // Drop the token only if the server rejected it.
      if (e.statusCode == 401 || e.statusCode == 404) {
        await prefs.remove(_tokenKey);
      }
      _api.token = null;
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> login(String identifier, String password) async {
    try {
      await _startSession(await _api.login(identifier, password));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Returns an error message, or null on success.
  Future<String?> register({
    required String username,
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    try {
      final result = await _api.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      await _startSession(result);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _api.token = null;
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _startSession(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.token);
    _api.token = result.token;
    user = result.user;
    status = AuthStatus.authenticated;
    notifyListeners();
  }
}
