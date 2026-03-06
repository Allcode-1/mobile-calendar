import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';
import '../sources/api_client.dart';
import '../models/user_model.dart';

// operation_result
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserModel? user;

  AuthResult({required this.isSuccess, this.errorMessage, this.user});
}

class AuthRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  AuthRepository(this._apiClient, this._prefs);

  // 1. login
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final token = response.data is Map
          ? response.data['access_token']?.toString()
          : null;
      if (token == null || token.isEmpty) {
        return AuthResult(isSuccess: false, errorMessage: "Token is missing");
      }
      await _prefs.setString('access_token', token);

      // get info about ourself after login
      return await getMe();
    } on DioException catch (e) {
      String message = "Network error";
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        message = "Wrong email or password";
      }
      AppLogger.warning('Login failed', error: e, scope: 'auth_repo');
      return AuthResult(isSuccess: false, errorMessage: message);
    }
  }

  // 2. registration
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _apiClient.dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'full_name': fullName},
      );
      // login after registration
      return await login(email, password);
    } on DioException catch (e) {
      String errorMsg = "Registration failed";
      if (e.response?.statusCode == 422) {
        // password validation from fastapi backend
        final data = e.response?.data;
        final detail = data is Map ? data['detail'] : null;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            errorMsg = first['msg'].toString();
          }
        }
      } else if (e.response?.statusCode == 400) {
        errorMsg = "User with this email already exists";
      }
      AppLogger.warning('Registration failed', error: e, scope: 'auth_repo');
      return AuthResult(isSuccess: false, errorMessage: errorMsg);
    }
  }

  // 3. get info about current user
  Future<AuthResult> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        return AuthResult(
          isSuccess: false,
          errorMessage: "Invalid user payload",
        );
      }
      final user = UserModel.fromJson(raw);
      return AuthResult(isSuccess: true, user: user);
    } catch (e, st) {
      AppLogger.warning(
        'getMe failed',
        error: e,
        stackTrace: st,
        scope: 'auth_repo',
      );
      return AuthResult(isSuccess: false, errorMessage: "Session finished");
    }
  }

  // 4. check if user is logined
  bool isAuthenticated() {
    return _prefs.getString('access_token') != null;
  }

  // 5. logout
  Future<void> logout() async {
    await _prefs.remove('access_token');
  }
}
