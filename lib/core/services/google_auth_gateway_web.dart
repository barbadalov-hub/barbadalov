// GIS config keys (client_id, auto_select, …) must match the JS API names.
// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'dart:js_interop';

import 'package:lifeos/core/config/firebase_config.dart';
import 'package:web/web.dart' as web;

/// `google.accounts.id.initialize(config)` from Google Identity Services.
@JS('google.accounts.id.initialize')
external void _idInitialize(_IdConfig config);

/// `google.accounts.id.prompt()` — shows the One Tap / sign-in prompt.
@JS('google.accounts.id.prompt')
external void _idPrompt();

extension type _IdConfig._(JSObject _) implements JSObject {
  external factory _IdConfig({
    required String client_id,
    required JSFunction callback,
    bool auto_select,
    bool use_fedcm_for_prompt,
  });
}

extension type _CredentialResponse._(JSObject _) implements JSObject {
  external String? get credential;
}

/// Web Google sign-in via Google Identity Services. Loads the GIS script on
/// demand, prompts the user, and returns the Google **ID token** (a JWT) which
/// the caller exchanges for a Firebase session over REST.
class GoogleAuthGateway {
  bool _loaded = false;

  bool get available => FirebaseConfig.googleClientId.isNotEmpty;

  Future<String?> getIdToken() async {
    if (!available) return null;
    try {
      await _ensureScript();
      final completer = Completer<String?>();
      void onCredential(_CredentialResponse response) {
        if (!completer.isCompleted) completer.complete(response.credential);
      }

      _idInitialize(_IdConfig(
        client_id: FirebaseConfig.googleClientId,
        callback: onCredential.toJS,
        auto_select: false,
        use_fedcm_for_prompt: true,
      ));
      _idPrompt();

      return await completer.future
          .timeout(const Duration(seconds: 120), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureScript() {
    if (_loaded) return Future.value();
    final completer = Completer<void>();
    final existing = web.document.querySelector('script[data-lifeos-gis]');
    if (existing != null) {
      _loaded = true;
      completer.complete();
      return completer.future;
    }
    final script = web.HTMLScriptElement()
      ..src = 'https://accounts.google.com/gsi/client'
      ..async = true
      ..defer = true
      ..setAttribute('data-lifeos-gis', '1');
    script.onload = (web.Event _) {
      _loaded = true;
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    script.onerror = (web.Event _) {
      if (!completer.isCompleted) completer.completeError('GIS load failed');
    }.toJS;
    web.document.head!.appendChild(script);
    return completer.future;
  }
}

final GoogleAuthGateway googleAuthGateway = GoogleAuthGateway();
