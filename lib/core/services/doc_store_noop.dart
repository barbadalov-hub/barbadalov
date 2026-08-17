import 'dart:typed_data';

/// Web backend: no document storage.
///
/// The camera path is native-only, so on web there is nothing to store in the
/// first place. Reporting `available == false` lets the UI hide the scan flow
/// instead of offering a button that silently does nothing.
class DocStore {
  bool get available => false;

  Future<String?> save(String id, Uint8List bytes) async => null;
  Future<Uint8List?> load(String id) async => null;
  Future<void> delete(String id) async {}
}

final DocStore docStore = DocStore();
