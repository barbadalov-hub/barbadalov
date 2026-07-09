import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lifeos/core/config/firebase_config.dart';

/// Minimal Firebase client over the public REST APIs (Identity Toolkit for
/// anonymous auth + Firestore documents API). Pure Dart `http` — no FlutterFire
/// plugins, so every platform LifeOS builds for keeps working unchanged.
class FirebaseRestClient {
  final http.Client _http;

  /// Session persisted from a previous run (uid + long-lived refresh token) so
  /// this device keeps ONE cloud identity forever instead of minting a new
  /// anonymous user per launch.
  String? _refreshToken;
  final void Function(String uid, String refreshToken)? onSession;

  /// Called when the account gains/loses an email (link, sign-in, sign-out).
  final void Function(String? email)? onEmail;

  FirebaseRestClient({
    http.Client? client,
    String? savedUid,
    String? savedRefreshToken,
    String? savedEmail,
    this.onSession,
    this.onEmail,
  })  : _http = client ?? http.Client(),
        _uid = savedUid,
        _email = savedEmail,
        _refreshToken = savedRefreshToken;

  String? _idToken;
  String? _uid;
  String? _email;

  String? get uid => _uid;
  String? get email => _email;
  bool get isSignedIn => _idToken != null;

  /// Upgrade this device's anonymous account to email+password — **keeps the
  /// same uid**, so the whole cloud history stays attached. Returns null on
  /// success or a Firebase error code (EMAIL_EXISTS, WEAK_PASSWORD, ...).
  Future<String?> linkEmailPassword(String email, String password) async {
    if (!await ensureSignedIn()) return 'NO_CONNECTION';
    try {
      final res = await _http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:update'
              '?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': _idToken,
              'email': email,
              'password': password,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final code = _errorCode(body);
        // Some projects block changing an anonymous account's email until it is
        // verified — fall back to a fresh email account (a new uid, but the
        // local data is untouched and syncs from here on).
        if (code.startsWith('OPERATION_NOT_ALLOWED')) {
          return _signUpEmail(email, password);
        }
        return code;
      }
      _applySession(body, email: email);
      return null;
    } catch (_) {
      return 'NO_CONNECTION';
    }
  }

  Future<String?> _signUpEmail(String email, String password) async {
    try {
      final res = await _http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:signUp'
              '?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) return _errorCode(body);
      _applySession(body, email: email);
      return null;
    } catch (_) {
      return 'NO_CONNECTION';
    }
  }

  /// Sign in to an existing email account — switches this device to that
  /// cloud identity. Returns null on success or a Firebase error code.
  Future<String?> signInWithEmail(String email, String password) async {
    if (!FirebaseConfig.isConfigured) return 'NOT_CONFIGURED';
    try {
      final res = await _http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword'
              '?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) return _errorCode(body);
      _applySession(body, email: email);
      return null;
    } catch (_) {
      return 'NO_CONNECTION';
    }
  }

  /// Sign in with a Google ID token (obtained in the browser via Google
  /// Identity Services). Exchanges it for a Firebase session via the Identity
  /// Toolkit `signInWithIdp` endpoint. If this device is already signed in
  /// (e.g. anonymous), the current idToken is passed so Google is **linked to
  /// the same uid** and the local history stays attached. Returns null on
  /// success or a Firebase error code.
  Future<String?> signInWithGoogle(String googleIdToken) async {
    if (!FirebaseConfig.isConfigured) return 'NOT_CONFIGURED';
    // Best-effort: make sure we have a session to link onto (keeps the uid).
    await ensureSignedIn();
    try {
      final res = await _http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp'
              '?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (_idToken != null) 'idToken': _idToken,
              'postBody': 'id_token=$googleIdToken&providerId=google.com',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) return _errorCode(body);
      _applySession(body, email: body['email'] as String?);
      return null;
    } catch (_) {
      return 'NO_CONNECTION';
    }
  }

  /// Forget the device session; the next event will mint a fresh anonymous
  /// identity.
  void signOut() {
    _idToken = null;
    _refreshToken = null;
    _uid = null;
    _email = null;
    onEmail?.call(null);
  }

  void _applySession(Map<String, dynamic> body, {String? email}) {
    _idToken = (body['idToken'] as String?) ?? _idToken;
    _uid = (body['localId'] as String?) ?? _uid;
    final refresh = body['refreshToken'] as String?;
    if (refresh != null) {
      _refreshToken = refresh;
      if (_uid != null) onSession?.call(_uid!, refresh);
    }
    if (email != null) {
      _email = email;
      onEmail?.call(email);
    }
  }

  static String _errorCode(Map<String, dynamic> body) =>
      ((body['error'] as Map<String, dynamic>?)?['message'] as String?) ??
      'UNKNOWN';

  /// Make sure we hold a valid idToken: restore the saved session via the
  /// refresh token when possible, otherwise create a new anonymous user.
  Future<bool> ensureSignedIn() async {
    if (_idToken != null) return true;
    if (_refreshToken != null && await _refreshSession()) return true;
    return await signInAnonymously() != null;
  }

  Future<bool> _refreshSession() async {
    if (!FirebaseConfig.isConfigured) return false;
    try {
      final res = await _http
          .post(
            Uri.parse(
              'https://securetoken.googleapis.com/v1/token'
              '?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'grant_type=refresh_token'
                '&refresh_token=${Uri.encodeQueryComponent(_refreshToken!)}',
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        _refreshToken = null; // revoked/invalid → fall back to fresh sign-up
        return false;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _idToken = body['id_token'] as String?;
      _uid = (body['user_id'] as String?) ?? _uid;
      final newRefresh = body['refresh_token'] as String?;
      if (newRefresh != null) {
        _refreshToken = newRefresh;
        if (_uid != null) onSession?.call(_uid!, newRefresh);
      }
      return _idToken != null;
    } catch (_) {
      return false;
    }
  }

  /// Anonymous sign-in (requires the Anonymous provider to be enabled once in
  /// the Firebase console). Returns the uid, or null on failure/offline.
  Future<String?> signInAnonymously() async {
    if (!FirebaseConfig.isConfigured) return null;
    try {
      final res = await _http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:signUp'
              '?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'returnSecureToken': true}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _idToken = body['idToken'] as String?;
      _uid = body['localId'] as String?;
      _refreshToken = body['refreshToken'] as String?;
      if (_uid != null && _refreshToken != null) {
        onSession?.call(_uid!, _refreshToken!);
      }
      return _uid;
    } catch (_) {
      return null;
    }
  }

  /// Append a life-event envelope to `events/{uid}/log` in Firestore.
  /// Returns true when the cloud accepted it.
  Future<bool> appendEvent(Map<String, dynamic> envelope) async {
    final uid = _uid;
    if (uid == null || !FirebaseConfig.isConfigured) return false;
    try {
      final res = await _http
          .post(
            Uri.parse(
              'https://firestore.googleapis.com/v1/projects/'
              '${FirebaseConfig.projectId}/databases/(default)/documents/'
              'events/$uid/log?documentId=${envelope['id']}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_idToken',
            },
            body: jsonEncode({'fields': _toFirestoreFields(envelope)}),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Upload the whole local state (a JSON string of the key-value store) to
  /// `backups/{uid}` so it can be restored on another device. Returns true on
  /// success.
  Future<bool> uploadBackup(String jsonState) async {
    if (!await ensureSignedIn()) return false;
    try {
      final res = await _http
          .patch(
            Uri.parse(
              'https://firestore.googleapis.com/v1/projects/'
              '${FirebaseConfig.projectId}/databases/(default)/documents/'
              'backups/$_uid',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_idToken',
            },
            body: jsonEncode({
              'fields': {
                'data': {'stringValue': jsonState},
                'updatedAt': {
                  'stringValue': DateTime.now().toUtc().toIso8601String(),
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Download the cloud backup for the current account, or null if there is
  /// none / on error.
  Future<String?> downloadBackup() async {
    if (!await ensureSignedIn()) return null;
    try {
      final res = await _http.get(
        Uri.parse(
          'https://firestore.googleapis.com/v1/projects/'
          '${FirebaseConfig.projectId}/databases/(default)/documents/'
          'backups/$_uid',
        ),
        headers: {'Authorization': 'Bearer $_idToken'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final fields = body['fields'] as Map<String, dynamic>?;
      return (fields?['data'] as Map<String, dynamic>?)?['stringValue']
          as String?;
    } catch (_) {
      return null;
    }
  }

  /// Convert a JSON-ish map to Firestore's typed field encoding.
  static Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> map) {
    return {for (final e in map.entries) e.key: _toFirestoreValue(e.value)};
  }

  static Map<String, dynamic> _toFirestoreValue(Object? value) {
    return switch (value) {
      null => {'nullValue': null},
      final bool b => {'booleanValue': b},
      final int i => {'integerValue': '$i'},
      final double d => {'doubleValue': d},
      final String s => {'stringValue': s},
      final List<dynamic> l => {
          'arrayValue': {
            'values': [for (final v in l) _toFirestoreValue(v)],
          },
        },
      final Map<dynamic, dynamic> m => {
          'mapValue': {
            'fields': _toFirestoreFields(m.cast<String, dynamic>()),
          },
        },
      _ => {'stringValue': '$value'},
    };
  }
}
