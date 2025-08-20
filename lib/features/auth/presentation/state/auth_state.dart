import 'package:hop_eir/features/auth/domain/entities/user.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final String? errorMessage;
  final String? password;

  AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.password,
  });

  factory AuthState.initial() {
    return AuthState(
      isLoading: false,
      user: null,
      errorMessage: null,
      password: null,
    );
  }

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? errorMessage,
    String? password,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      password: password ?? this.password,
    );
  }
}
