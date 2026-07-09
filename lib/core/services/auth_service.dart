/// Identity seam. Phase 1–2 run under a stable local user so every module can
/// stamp events/records with a `userId` today. Phase 3 swaps in a
/// `FirebaseAuthService` (email + Google/Apple) behind this same interface —
/// nothing above the Data layer changes.
abstract class AuthService {
  /// The current signed-in user id (never null in local mode).
  String get currentUserId;

  /// Emits whenever the signed-in user changes.
  Stream<String> get userIdChanges;
}

/// Default offline implementation: a single persistent local user.
class LocalAuthService implements AuthService {
  const LocalAuthService();

  static const _localUserId = 'local-user';

  @override
  String get currentUserId => _localUserId;

  @override
  Stream<String> get userIdChanges => Stream<String>.value(_localUserId);
}
