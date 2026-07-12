#!/bin/bash
# SessionStart hook for Claude Code on the web.
#
# The remote container ships without Flutter, so every fresh session needs the
# SDK before `flutter analyze` / `flutter test` / `flutter build` can run. This
# installs Flutter once (cached across sessions in the same environment), wires
# it onto PATH for the rest of the session, and fetches package dependencies.
set -euo pipefail

# Only the remote (web/mobile) environment lacks Flutter — skip on local dev.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_VERSION="3.35.5"
FLUTTER_DIR="/opt/flutter"

# --- Install Flutter (idempotent) ------------------------------------------
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION}..."
  curl -fsSL -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  # The archive's top-level dir is `flutter/`, so this yields /opt/flutter.
  tar xf /tmp/flutter.tar.xz -C /opt
  rm -f /tmp/flutter.tar.xz
fi

# Flutter/Dart abort on a repo owned by another uid ("dubious ownership") — the
# container runs as root, so mark both trees safe.
git config --global --add safe.directory "$FLUTTER_DIR" || true
git config --global --add safe.directory "$CLAUDE_PROJECT_DIR" || true

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics >/dev/null 2>&1 || true

# --- Fetch dependencies so tooling works immediately -----------------------
cd "$CLAUDE_PROJECT_DIR"
flutter pub get

# --- Persist Flutter on PATH for the rest of the session -------------------
echo "export PATH=\"${FLUTTER_DIR}/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"

echo "Flutter $(flutter --version 2>/dev/null | head -1) ready."
