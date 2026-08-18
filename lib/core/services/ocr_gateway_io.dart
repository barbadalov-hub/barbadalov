import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Where to get the receipt image from.
enum OcrSource { camera, gallery }

/// A photographed document: the picture itself plus whatever text was read off
/// it. The text is a bonus — the picture is the point, because a warranty claim
/// is made with an image of the receipt, not with a transcript of it.
class ScannedDoc {
  final Uint8List bytes;
  final String? text;
  const ScannedDoc({required this.bytes, this.text});
}

/// Native backend: pick a photo and run on-device ML Kit text recognition.
/// Only Android/iOS have the plugins; desktop (also `dart:io`) reports
/// unavailable so it never touches the mobile-only method channels.
class OcrGateway {
  bool get available => Platform.isAndroid || Platform.isIOS;

  /// Returns the recognized text of a picked receipt photo, or null if the user
  /// cancelled, nothing was recognized, or anything failed.
  Future<String?> scan(OcrSource source) async {
    if (!available) return null;
    TextRecognizer? recognizer;
    try {
      final file = await ImagePickerPlatform.instance.getImageFromSource(
        source: source == OcrSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (file == null) return null;

      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result =
          await recognizer.processImage(InputImage.fromFilePath(file.path));
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    } finally {
      await recognizer?.close();
    }
  }

  /// Photographs a barcode and returns its digits, or null if nothing was
  /// found. On-device, so it costs nothing and works without a network — the
  /// *lookup* that follows is what needs one.
  Future<String?> scanBarcode(OcrSource source) async {
    if (!available) return null;
    BarcodeScanner? scanner;
    try {
      final file = await ImagePickerPlatform.instance.getImageFromSource(
        source: source == OcrSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (file == null) return null;

      scanner = BarcodeScanner(formats: [
        // The formats actually printed on groceries. Narrowing the list makes
        // the scan quicker and stops it locking onto a QR code on the packet.
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upca,
        BarcodeFormat.upce,
      ]);
      final codes =
          await scanner.processImage(InputImage.fromFilePath(file.path));
      for (final code in codes) {
        final value = code.rawValue?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      await scanner?.close();
    }
  }

  /// Picks a photo and returns it **with** its recognized text.
  ///
  /// Downscaled and re-compressed by the picker itself: a modern phone camera
  /// produces several megabytes per shot, and a shelf of those would bloat the
  /// device for no gain — a receipt only has to stay readable.
  Future<ScannedDoc?> captureDocument(OcrSource source) async {
    if (!available) return null;
    TextRecognizer? recognizer;
    try {
      final file = await ImagePickerPlatform.instance.getImageFromSource(
        source: source == OcrSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        options: const ImagePickerOptions(
          maxWidth: 1600,
          imageQuality: 72,
        ),
      );
      if (file == null) return null;

      final bytes = await file.readAsBytes();

      String? text;
      try {
        recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final result =
            await recognizer.processImage(InputImage.fromFilePath(file.path));
        final recognized = result.text.trim();
        if (recognized.isNotEmpty) text = recognized;
      } catch (_) {
        // Unreadable text must not lose the photo — that is the valuable half.
      }

      return ScannedDoc(bytes: bytes, text: text);
    } catch (_) {
      return null;
    } finally {
      await recognizer?.close();
    }
  }
}

final OcrGateway ocrGateway = OcrGateway();
