"""Builds the CJK fallback faces for the book font (EB Garamond has no Han or kana).

Noto Serif SC/JP (OFL) are 11.6 MB and 6.2 MB whole; the Web build downloads
every font, so each is cut to the characters the game can realistically show:

- SC: GB2312 level 1 (the 3755 most common hanzi) + CJK punctuation.
- JP: kana + JIS X 0208 level 1 kanji (2965) + CJK punctuation.
- Both: every CJK character already present in `data/locale/*.csv` and in
  `user_settings.gd` (language names), so a translation using a rarer
  character is covered the moment this tool is re-run.

Re-run after the zh_CN/ja columns are filled:
    python3 tools/cjk_font_subset.py
The whole fonts are downloaded into a cache outside the repository.
"""

import csv
import glob
import os
import urllib.request

from fontTools import subset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "data", "assets", "fonts")
CACHE = os.path.join(os.path.expanduser("~"), ".cache", "wayborne_cjk")
SOURCE_URL = "https://raw.githubusercontent.com/notofonts/noto-cjk/main/Serif/SubsetOTF/{lang}/NotoSerif{lang}-Regular.otf"
LICENSE_URL = "https://raw.githubusercontent.com/notofonts/noto-cjk/main/Serif/LICENSE"

# CJK Symbols and Punctuation, full-width forms: 、。「」（）！？ and friends.
PUNCTUATION = [range(0x3000, 0x3040), range(0xFF00, 0xFFF0)]
KANA = [range(0x3040, 0x30FF + 1)]


def _is_cjk(ch: str) -> bool:
    code = ord(ch)
    return (0x2E80 <= code <= 0x9FFF) or (0xF900 <= code <= 0xFAFF) or (0xFF00 <= code <= 0xFFEF)


def _decode_rows(codec: str, first_row: int, last_row: int) -> set:
    chars = set()
    for row in range(first_row, last_row + 1):
        for cell in range(0xA1, 0xFF):
            try:
                chars.add(bytes([row, cell]).decode(codec))
            except UnicodeDecodeError:
                pass
    return chars


def _game_text_chars() -> set:
    chars = set()
    for path in glob.glob(os.path.join(ROOT, "data", "locale", "*.csv")):
        with open(path, encoding="utf-8") as handle:
            for row in csv.reader(handle):
                for cell in row:
                    chars.update(ch for ch in cell if _is_cjk(ch))
    with open(os.path.join(ROOT, "scripts", "autoload", "user_settings.gd"), encoding="utf-8") as handle:
        chars.update(ch for ch in handle.read() if _is_cjk(ch))
    return chars


def _fetch(url: str, name: str) -> str:
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        urllib.request.urlretrieve(url, path)
    return path


def _subset(lang: str, chars: set) -> None:
    source = _fetch(SOURCE_URL.format(lang=lang), "NotoSerif%s-Regular.otf" % lang)
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    font = subset.load_font(source, options)
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=[ord(ch) for ch in chars])
    subsetter.subset(font)
    out = os.path.join(OUT_DIR, "NotoSerif%s-Subset.otf" % lang)
    subset.save_font(font, out, options)
    print("  %-28s %5d chars  %7.0f KB" % (os.path.basename(out), len(chars), os.path.getsize(out) / 1024))


def main() -> None:
    game = _game_text_chars()
    shared = set(chr(c) for block in PUNCTUATION for c in block) | game
    # GB2312 rows 16-55 are level 1 hanzi; EUC-JP rows 16-47 are JIS level 1 kanji.
    _subset("SC", _decode_rows("gb2312", 0xB0, 0xD7) | shared)
    _subset("JP", _decode_rows("euc_jp", 0xB0, 0xCF) | set(chr(c) for block in KANA for c in block) | shared)
    license_path = _fetch(LICENSE_URL, "LICENSE.txt")
    with open(license_path, encoding="utf-8") as src, open(os.path.join(OUT_DIR, "NotoSerifCJK-OFL.txt"), "w", encoding="utf-8") as dst:
        dst.write(src.read())


if __name__ == "__main__":
    main()
