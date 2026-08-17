import 'dart:io';

import 'package:flutter/services.dart';

/// Native voice input, talking to Android's own SpeechRecognizer through a
/// method channel the app implements itself (see `MainActivity.kt`).
///
/// Written by hand rather than taken off the shelf: every published speech
/// package either ships a Windows implementation — which would force the
/// desktop build to need Developer Mode, the one thing this project avoids —
/// or is old enough that its Gradle script still calls the long-removed
/// `jcenter()` and does not build at all. Neither trade was worth making for
/// eighty lines of Kotlin.
class SpeechGateway {
  static const _channel = MethodChannel('lumo/speech');

  void Function(String text)? _onText;
  void Function()? _onDone;
  bool _listening = false;
  bool _wired = false;

  /// Android only. iOS has no project in this repo yet, and the desktop and
  /// web builds have no channel behind them at all.
  bool get available => Platform.isAndroid;
  bool get isListening => _listening;

  void _wire() {
    if (_wired) return;
    _wired = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onText':
          final args = (call.arguments as Map?) ?? const {};
          final text = args['text'] as String?;
          if (text != null) _onText?.call(text);
        case 'onDone':
          _listening = false;
          _onDone?.call();
      }
      return null;
    });
  }

  Future<bool> start({
    required void Function(String text) onText,
    required void Function() onDone,
    String? localeId,
  }) async {
    if (!available) return false;
    _wire();
    _onText = onText;
    _onDone = onDone;
    try {
      final ok = await _channel
              .invokeMethod<bool>('start', {'locale': localeId}) ??
          false;
      _listening = ok;
      return ok;
    } on PlatformException {
      _listening = false;
      return false;
    } on MissingPluginException {
      // An older install of the app without the channel — never crash over it.
      _listening = false;
      return false;
    }
  }

  Future<void> stop() async {
    if (!available) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {
      // Best effort; the field keeps whatever was already recognised.
    }
    _listening = false;
  }
}

final SpeechGateway speechGateway = SpeechGateway();
