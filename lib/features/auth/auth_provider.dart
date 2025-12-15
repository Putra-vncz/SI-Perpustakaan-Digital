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

  MockDataService get _mockService => ref.read(mockDataServiceProvider);

  Future<bool> login(String identifier) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _mockService.login(identifier);

      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'User not found. Use a valid NIM or email.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred: $e',
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
final mockDataServiceProvider = Provider<MockDataService>((ref) {
  return MockDataService();
});

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
