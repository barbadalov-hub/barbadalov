#!/usr/bin/env python3
"""Regenerates assets/fonts/NotoColorEmoji.ttf as a subset that covers every
emoji actually used in UI string literals under lib/.

The offline web build (CanvasKit) only draws from bundled fonts, so any emoji
in code but absent from the bundled subset renders as a tofu box. Run this
after adding new emoji to the UI:

    python3 tool/build_emoji_subset.py path/to/full/NotoColorEmoji.ttf

The full source font is Google's Noto Color Emoji:
    https://raw.githubusercontent.com/googlefonts/noto-emoji/main/fonts/NotoColorEmoji.ttf

It keeps the previous subset's coverage (union) so nothing that used to render
can regress, and adds any newly-used emoji. Verify with tool/check_font_coverage.py.
"""
import glob
import re
import subprocess
import sys

from fontTools.ttLib import TTFont

OUT = "assets/fonts/NotoColorEmoji.ttf"
IGNORE = {0x200D, 0xFE0F}  # ZWJ / VS16 — combining, not standalone glyphs

literal = re.compile(r"'([^']*)'|\"([^\"]*)\"")


def used_codepoints():
    cps = set()
    for f in glob.glob("lib/**/*.dart", recursive=True):
        for line in open(f, encoding="utf-8"):
            s = line.lstrip()
            if s.startswith(("//", "*", "/*")):
                continue
            for a, b in literal.findall(line):
                for ch in a or b:
                    cp = ord(ch)
                    if cp >= 0x80 and cp not in IGNORE:
                        cps.add(cp)
    return cps


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: build_emoji_subset.py <full-NotoColorEmoji.ttf>")
    full = sys.argv[1]
    full_cmap = set(TTFont(full).getBestCmap().keys())
    prev = set(TTFont(OUT).getBestCmap().keys())  # keep old coverage
    wanted = (used_codepoints() | prev) & full_cmap
    unicodes = ",".join(f"U+{cp:04X}" for cp in sorted(wanted))
    subprocess.run(
        [
            "pyftsubset",
            full,
            f"--unicodes={unicodes}",
            f"--output-file={OUT}",
            "--no-hinting",
        ],
        check=True,
    )
    print(f"Wrote {OUT} covering {len(wanted)} glyphs.")


if __name__ == "__main__":
    main()
