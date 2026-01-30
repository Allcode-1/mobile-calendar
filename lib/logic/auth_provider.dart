import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../data/sources/api_client.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  AuthState({this.isLoading = false, this.user, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    if (_repository.isAuthenticated()) {
      state = AuthState(isLoading: true);
      final result = await _repository.getMe();
      if (result.isSuccess) {
        state = AuthState(user: result.user, isLoading: false);
      } else {
        state = AuthState(error: result.errorMessage, isLoading: false);
        await _repository.logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);
    final result = await _repository.login(email, password);

    if (result.isSuccess) {
      state = AuthState(user: result.user, isLoading: false);
      return true;
    } else {
      state = AuthState(error: result.errorMessage, isLoading: false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = AuthState(isLoading: true);
    final result = await _repository.register(
      email: email,
      password: password,
      fullName: fullName,
    );

    if (result.isSuccess) {
      state = AuthState(user: result.user, isLoading: false);
      return true;
    } else {
      state = AuthState(error: result.errorMessage, isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await _repository.logout();
    state = AuthState(user: null, isLoading: false);
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ApiClient(), ref.watch(sharedPrefsProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
