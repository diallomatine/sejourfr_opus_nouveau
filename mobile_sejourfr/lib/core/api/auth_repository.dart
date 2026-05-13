import 'package:dio/dio.dart';

import '../models/auth_models.dart';
import 'api_client.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<TokenResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
      options: _publicOptions(),
    );
    return TokenResponse.fromJson(res.data!);
  }

  Future<TokenResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      },
      options: _publicOptions(),
    );
    return TokenResponse.fromJson(res.data!);
  }

  Future<AuthUser> me() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/api/auth/me');
    return AuthUser.fromJson(res.data!);
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.dio.post(
      '/api/auth/forgot-password',
      data: {'email': email},
      options: _publicOptions(),
    );
  }

  Options _publicOptions() =>
      Options(extra: const {'skipAuth': true, 'skipRefresh': true});
}
