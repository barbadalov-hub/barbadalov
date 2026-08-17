import 'dart:io';
import 'dart:typed_data';

/// Native document storage: one file per document, next to the user's data.
///
/// Deliberately **not** the temp directory. A receipt kept for a warranty claim
/// has to still be there in eleven months; the system is free to empty temp
/// whenever it likes, which would quietly lose exactly the file the whole
/// feature exists to keep.
///
/// The base directory is resolved the same way the key-value store resolves
/// its own — no `path_provider`, so the plugin-free desktop build is untouched.
class DocStore {
  bool get available => true;

  Directory get _dir => Directory(
      '${_baseDir()}${Platform.pathSeparator}docs');

  static String _baseDir() {
    final env = Platform.environment;
    final base = env['APPDATA'] ??
        env['LOCALAPPDATA'] ??
        env['HOME'] ??
        Directory.systemTemp.path;
    return '$base${Platform.pathSeparator}Lumo';
  }

  String _pathFor(String id) =>
      '${_dir.path}${Platform.pathSeparator}$id.jpg';

  /// Writes [bytes] under [id] and returns the id on success, or null if the
  /// device would not take it. Never throws: failing to store a photo must not
  /// take the purchase down with it.
  Future<String?> save(String id, Uint8List bytes) async {
    try {
      await _dir.create(recursive: true);
      await File(_pathFor(id)).writeAsBytes(bytes, flush: true);
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> load(String id) async {
    try {
      final file = File(_pathFor(id));
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    try {
      final file = File(_pathFor(id));
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A leftover file is harmless; a crash while deleting is not.
    }
  }
}

final DocStore docStore = DocStore();
