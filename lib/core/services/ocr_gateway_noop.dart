import 'dart:typed_data';

/// Where to get the receipt image from.
enum OcrSource { camera, gallery }

/// A photographed document: the picture plus whatever text was read off it.
class ScannedDoc {
  final Uint8List bytes;
  final String? text;
  const ScannedDoc({required this.bytes, this.text});
}

/// Web / desktop backend: no on-device OCR, so callers fall back to text paste.
class OcrGateway {
  bool get available => false;

  Future<String?> scan(OcrSource source) async => null;

  Future<ScannedDoc?> captureDocument(OcrSource source) async => null;
}

final OcrGateway ocrGateway = OcrGateway();
