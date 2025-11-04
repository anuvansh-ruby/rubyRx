enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  pinRequired,
  otpRequired,
  otpSent,
  pinReset,
}

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? message;

  AuthState({this.status = AuthStatus.initial, this.error, this.message});

  AuthState copyWith({AuthStatus? status, String? error, String? message}) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }
}
