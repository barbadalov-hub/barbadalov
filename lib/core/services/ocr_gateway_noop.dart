/// Where to get the receipt image from.
enum OcrSource { camera, gallery }

/// Web / desktop backend: no on-device OCR, so callers fall back to text paste.
class OcrGateway {
  bool get available => false;

  Future<String?> scan(OcrSource source) async => null;
}

final OcrGateway ocrGateway = OcrGateway();
