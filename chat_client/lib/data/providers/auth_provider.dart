import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/websocket_service.dart';
import '../models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;
  final WebSocketService _webSocketService;

  AuthNotifier(this._apiService, this._storageService, this._webSocketService)
      : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    final token = _storageService.getAuthToken();
    final userData = _storageService.getUserData();

    if (token != null && userData != null) {
      _apiService.setAuthToken(token);
      try {
        final response = await _apiService.getProfile();
        final user = User.fromJson(response.data['user']);
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        _webSocketService.connect(token);
      } catch (e) {
        // Token might be expired, try refresh
        await _tryRefreshToken();
      }
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _tryRefreshToken() async {
    final refreshToken = _storageService.getRefreshToken();
    if (refreshToken != null) {
      try {
        final response = await _apiService.refreshToken(refreshToken);
        final newToken = response.data['token'];
        await _storageService.setAuthToken(newToken);
        _apiService.setAuthToken(newToken);

        final user = User.fromJson(response.data['user']);
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        _webSocketService.connect(newToken);
      } catch (e) {
        await _storageService.clearAuth();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } else {
      await _storageService.clearAuth();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _apiService.login(username, password);
      final token = response.data['token'];
      final refreshToken = response.data['refresh_token'];
      final user = User.fromJson(response.data['user']);

      await _storageService.setAuthToken(token);
      await _storageService.setRefreshToken(refreshToken);
      await _storageService.setUserId(user.id);
      _apiService.setAuthToken(token);

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      _webSocketService.connect(token);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Login failed. Please check your credentials.',
      );
    }
  }

  Future<void> register(String username, String password, {String? email}) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _apiService.register(username, password, email: email);
      final token = response.data['token'];
      final refreshToken = response.data['refresh_token'];
      final user = User.fromJson(response.data['user']);

      await _storageService.setAuthToken(token);
      await _storageService.setRefreshToken(refreshToken);
      await _storageService.setUserId(user.id);
      _apiService.setAuthToken(token);

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      _webSocketService.connect(token);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Registration failed. Username may already be taken.',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Ignore logout API errors
    }

    _webSocketService.disconnect();
    await _storageService.clearAuth();
    _apiService.setAuthToken(null);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(User user) {
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final webSocketService = ref.watch(webSocketServiceProvider);
  return AuthNotifier(apiService, storageService, webSocketService);
});
