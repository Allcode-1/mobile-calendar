import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      final token = response.data['access_token'];
      await _prefs.setString('access_token', token);

      // get info about ourself after login
      return await getMe();
    } on DioException catch (e) {
      String message = "Network error";
      if (e.response?.statusCode == 401) {
        message = "Wrong email or password";
      }
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
        final detail = e.response?.data['detail'];
        if (detail is List && detail.isNotEmpty) {
          errorMsg = detail[0]['msg'];
        }
      } else if (e.response?.statusCode == 400) {
        errorMsg = "User with this email already exists";
      }
      return AuthResult(isSuccess: false, errorMessage: errorMsg);
    }
  }

  // 3. get info about current user
  Future<AuthResult> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      final user = UserModel.fromJson(response.data);
      return AuthResult(isSuccess: true, user: user);
    } catch (e) {
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
