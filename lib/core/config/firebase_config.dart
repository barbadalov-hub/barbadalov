/// Firebase project identifiers for the **REST-based** cloud sync.
///
/// LifeOS deliberately talks to Firebase over its public REST APIs with the
/// plain `http` package instead of the FlutterFire plugins: no native plugin
/// code → the Windows build stays symlink/Developer-Mode-free and web/Android
/// work identically. A web API key is a public identifier (safety comes from
/// Firestore security rules), so committing it here is standard practice.
///
/// Supplied at build time via `--dart-define` (or `--dart-define-from-file`) so
/// each person points the app at **their own** project without editing or
/// committing source:
///
/// ```bash
/// flutter build web --release \
///   --dart-define=FIREBASE_PROJECT_ID=your-project \
///   --dart-define=FIREBASE_API_KEY=AIza... \
///   --dart-define=FIREBASE_GOOGLE_CLIENT_ID=...apps.googleusercontent.com
/// ```
///
/// Left empty by default, so [isConfigured] is false, the cloud-sync handler
/// stays dormant and the app is fully offline until you provide a project. See
/// docs/FIREBASE.md.
class FirebaseConfig {
  const FirebaseConfig._();

  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  /// OAuth Web client id from the Google sign-in provider. Public by design
  /// (used in the browser). Empty disables the "Continue with Google" button.
  static const String googleClientId =
      String.fromEnvironment('FIREBASE_GOOGLE_CLIENT_ID');

  static bool get isConfigured => apiKey.isNotEmpty && projectId.isNotEmpty;
}
