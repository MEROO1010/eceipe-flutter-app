import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/recipe.dart';
import '../models/user.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthResult {
  final User user;
  final String token;

  const AuthResult(this.user, this.token);
}

class RecipePage {
  final List<Recipe> recipes;
  final int page;
  final int pages;
  final int total;

  const RecipePage({
    required this.recipes,
    required this.page,
    required this.pages,
    required this.total,
  });

  bool get hasNext => page < pages;
}

class ApiService {
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final encoded = body == null ? null : jsonEncode(body);

    try {
      final Future<http.Response> request;
      switch (method) {
        case 'POST':
          request = http.post(uri, headers: _headers, body: encoded);
          break;
        case 'PUT':
          request = http.put(uri, headers: _headers, body: encoded);
          break;
        case 'DELETE':
          request = http.delete(uri, headers: _headers);
          break;
        default:
          request = http.get(uri, headers: _headers);
      }
      final res = await request.timeout(const Duration(seconds: 20));

      Map<String, dynamic> json;
      try {
        json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException('Unexpected server response.',
            statusCode: res.statusCode);
      }

      if (res.statusCode >= 400 || json['success'] == false) {
        throw ApiException(
          (json['message'] ?? json['error'] ?? 'Request failed').toString(),
          statusCode: res.statusCode,
        );
      }
      return json['data'];
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } catch (_) {
      throw ApiException('Cannot reach the server. Check your connection.');
    }
  }

  // ---------- Auth ----------

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    final data = await _send('POST', '/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
    });
    return AuthResult(User.fromJson(data['user']), data['access_token']);
  }

  Future<AuthResult> login(String identifier, String password) async {
    final data = await _send('POST', '/auth/login',
        body: {'username': identifier, 'password': password});
    return AuthResult(User.fromJson(data['user']), data['access_token']);
  }

  Future<User> getProfile() async {
    final data = await _send('GET', '/auth/profile');
    return User.fromJson(data['user']);
  }

  // ---------- Recipes ----------

  Future<RecipePage> getRecipes({
    int page = 1,
    int perPage = 10,
    String search = '',
    String? category,
    String? cuisine,
    String? difficulty,
  }) async {
    final data = await _send('GET', '/recipes', query: {
      'page': '$page',
      'per_page': '$perPage',
      if (search.isNotEmpty) 'search': search,
      if (category != null) 'category': category,
      if (cuisine != null) 'cuisine': cuisine,
      if (difficulty != null) 'difficulty': difficulty,
    });
    final pagination = data['pagination'] as Map<String, dynamic>;
    return RecipePage(
      recipes: (data['recipes'] as List)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      pages: pagination['pages'] as int,
      total: pagination['total'] as int,
    );
  }

  Future<Recipe> getRecipe(int id) async {
    final data = await _send('GET', '/recipes/$id');
    return Recipe.fromJson(data['recipe']);
  }

  Future<Recipe> createRecipe(Map<String, dynamic> payload) async {
    final data = await _send('POST', '/recipes', body: payload);
    return Recipe.fromJson(data['recipe']);
  }

  Future<Recipe> updateRecipe(int id, Map<String, dynamic> payload) async {
    final data = await _send('PUT', '/recipes/$id', body: payload);
    return Recipe.fromJson(data['recipe']);
  }

  Future<void> deleteRecipe(int id) => _send('DELETE', '/recipes/$id');

  // ---------- Favorites ----------

  Future<List<Recipe>> getFavorites() async {
    final data = await _send('GET', '/favorites');
    return (data['recipes'] as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFavorite(int recipeId) =>
      _send('POST', '/favorites', body: {'recipe_id': recipeId});

  Future<void> removeFavorite(int recipeId) =>
      _send('DELETE', '/favorites/$recipeId');
}
