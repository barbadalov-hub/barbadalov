/// Native fallback: there is no browser download, so callers use the clipboard
/// path instead. Returns false so the UI can offer the right hint.
bool downloadTextFile(String filename, String content) => false;
