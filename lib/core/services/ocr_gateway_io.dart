import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Where to get the receipt image from.
enum OcrSource { camera, gallery }

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
}

final OcrGateway ocrGateway = OcrGateway();
