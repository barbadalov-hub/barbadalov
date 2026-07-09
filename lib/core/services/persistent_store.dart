// Platform-agnostic entry point for persistence. Resolves to the `dart:io`
// (file-based) implementation on desktop/mobile and the `localStorage`
// implementation on web — chosen at compile time, so neither pulls a plugin.
//
// `dart.library.io` is guaranteed true on native/VM and false on web, so the
// correct implementation is always selected.
//
// Usage (in `main`): `final store = await createPersistentStore();`
export 'persistent_store_web.dart'
    if (dart.library.io) 'persistent_store_io.dart';
