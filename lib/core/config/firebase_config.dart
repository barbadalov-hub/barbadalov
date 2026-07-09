/// Firebase project identifiers for the **REST-based** cloud sync.
///
/// LifeOS deliberately talks to Firebase over its public REST APIs with the
/// plain `http` package instead of the FlutterFire plugins: no native plugin
/// code → the Windows build stays symlink/Developer-Mode-free and web/Android
/// work identically. A web API key is a public identifier (safety comes from
/// Firestore security rules), so committing it here is standard practice.
///
/// Filled in by `firebase apps:sdkconfig web` after the project is created.
/// While [isConfigured] is false the cloud-sync handler stays dormant and the
/// app is fully offline — exactly as before.
class FirebaseConfig {
  const FirebaseConfig._();

  static const String apiKey = 'AIzaSyBaT5c8GfbEqqKdcVVFwJVihkYMLqEbvXY';
  static const String projectId = 'lifeos-arkadiy';

  /// OAuth Web client id auto-created when the Google sign-in provider was
  /// enabled in the Firebase console. Public by design (used in the browser).
  /// Empty disables the "Continue with Google" button.
  static const String googleClientId =
      '559344608968-lch62lpe07n7n1be2ochdigi6d5bl48v.apps.googleusercontent.com';

  static bool get isConfigured => apiKey.isNotEmpty && projectId.isNotEmpty;
}
