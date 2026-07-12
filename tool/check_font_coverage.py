#!/usr/bin/env python3
"""Fails if any glyph used in a UI string literal isn't in a bundled font.

The web build renders with CanvasKit, which has no system fonts — it draws text
only from the fonts bundled in assets/fonts/ (see AppTheme's web font stack). A
character used in code but absent from every bundled font shows up as a "tofu"
box offline. This guard keeps the "runs fully offline" promise honest.
"""
import glob
import re
import sys
import unicodedata as ud

from fontTools.ttLib import TTFont

FONTS = [
    "assets/fonts/Roboto-Regular.ttf",
    "assets/fonts/NotoSans.ttf",
    "assets/fonts/NotoColorEmoji.ttf",
    "assets/fonts/DejaVuSymbols.ttf",
]
# Zero-width joiners / variation selectors are combining, not standalone glyphs.
IGNORE = {0x200D, 0xFE0F}

covered = set()
for path in FONTS:
    covered |= set(TTFont(path).getBestCmap().keys())

literal = re.compile(r"'([^']*)'|\"([^\"]*)\"")
missing = {}
for f in glob.glob("lib/**/*.dart", recursive=True):
    for lineno, line in enumerate(open(f, encoding="utf-8"), 1):
        stripped = line.lstrip()
        if stripped.startswith(("//", "*", "/*")):
            continue
        for a, b in literal.findall(line):
            for ch in a or b:
                cp = ord(ch)
                if cp < 0x80 or cp in IGNORE or cp in covered:
                    continue
                missing.setdefault(cp, (ch, f"{f}:{lineno}"))

if missing:
    print("Glyphs used in UI strings but missing from every bundled font:")
    for cp in sorted(missing):
        ch, loc = missing[cp]
        try:
            name = ud.name(ch)
        except ValueError:
            name = "?"
        print(f"  U+{cp:04X} {ch!r} {name}  <- {loc}")
    print("\nAdd the glyph to a bundled font subset or use a covered character.")
    sys.exit(1)

print(f"OK — every UI string glyph is covered by {len(FONTS)} bundled fonts.")
