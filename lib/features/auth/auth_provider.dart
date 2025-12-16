import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => user != null;
  bool get isAdmin => user?.role == UserRole.admin;
  bool get isStudent => user?.role == UserRole.student;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  HiveDataService get _mockService => ref.read(mockDataServiceProvider);

  /// Login as student with NIM and password
  Future<bool> loginStudent(String nim, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _mockService.loginStudent(nim, password);

      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'NIM atau password salah.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan: $e',
      );
      return false;
    }
  }

  /// Login as admin with email and password
  Future<bool> loginAdmin(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _mockService.loginAdmin(email, password);

      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Email atau password salah.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan: $e',
      );
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? studentId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _mockService.registerUser(
        name: name,
        email: email,
        password: password,
        role: role,
        studentId: studentId,
      );

      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Email atau NIM sudah terdaftar.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan: $e',
      );
      return false;
    }
  }

  void logout() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final mockDataServiceProvider = Provider<HiveDataService>((ref) {
  return HiveDataService.instance;
});

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
