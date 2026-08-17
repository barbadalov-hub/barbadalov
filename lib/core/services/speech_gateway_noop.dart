/// Web / desktop backend: no voice input, so the UI keeps typing.
///
/// Reporting `available == false` lets the mic button be absent rather than
/// present and dead — an offer the app cannot honour is worse than no offer.
class SpeechGateway {
  bool get available => false;
  bool get isListening => false;

  Future<bool> start({
    required void Function(String text) onText,
    required void Function() onDone,
    String? localeId,
  }) async =>
      false;

  Future<void> stop() async {}
}

final SpeechGateway speechGateway = SpeechGateway();
