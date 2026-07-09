/// Non-web backend: no plugin-free Google flow, so the button stays hidden and
/// callers fall back to email / anonymous sign-in.
class GoogleAuthGateway {
  bool get available => false;

  Future<String?> getIdToken() async => null;
}

final GoogleAuthGateway googleAuthGateway = GoogleAuthGateway();
