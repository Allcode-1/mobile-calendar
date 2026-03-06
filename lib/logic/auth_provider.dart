import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../data/sources/api_client.dart';
import '../data/sources/database_service.dart';

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
    try {
      final userId = state.user?.id;
      if (!kIsWeb && userId != null && userId.isNotEmpty) {
        await DatabaseService().clearUserData(userId);
      }
      await _repository.logout();
      state = AuthState(user: null, isLoading: false);
    } catch (e, st) {
      AppLogger.warning(
        'Logout failed',
        error: e,
        stackTrace: st,
        scope: 'auth_provider',
      );
    }
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
