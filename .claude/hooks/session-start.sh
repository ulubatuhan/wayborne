#!/bin/bash
# Wayborne bulut oturumu başlangıcı: Godot 4.2.2, LFS varlıkları, Python araç paketleri, ilk içe aktarma.
# Her adım zaten yapılmışsa atlanır (konteyner durumu kancadan sonra önbelleğe alınır). Yalnızca bulut oturumunda koşar.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"
LOG=/tmp/wayborne_session_start.log
: > "$LOG"

# 1. Godot 4.2.2 (CI ile aynı sürüm; testler ve ekran görüntüsü araçları bunu ister)
if ! command -v godot >/dev/null 2>&1 || ! godot --version 2>/dev/null | grep -q '^4\.2\.2'; then
  tmp=$(mktemp -d)
  curl -sSL -o "$tmp/godot.zip" \
    https://github.com/godotengine/godot/releases/download/4.2.2-stable/Godot_v4.2.2-stable_linux.x86_64.zip
  python3 -I -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$tmp/godot.zip" "$tmp"
  install -m 755 "$tmp/Godot_v4.2.2-stable_linux.x86_64" /usr/local/bin/godot
  rm -rf "$tmp"
fi

# 2. LFS varlıkları (harita karoları, atlas sayfaları); işaretçi dosyayla oyun açılmaz
if command -v git-lfs >/dev/null 2>&1; then
  git lfs install --local >>"$LOG" 2>&1 || true
  git lfs pull >>"$LOG" 2>&1 || echo "uyarı: git lfs pull başarısız (günlük: $LOG)"
fi

# 3. Araçların Python paketleri (soru defteri, codex, xlsx takip, görsel araçlar)
python3 -I -c "import PIL, openpyxl, reportlab" 2>/dev/null || \
  pip install --quiet --break-system-packages Pillow openpyxl reportlab >>"$LOG" 2>&1 || \
  echo "uyarı: Python paketleri kurulamadı (günlük: $LOG)"

# 4. İlk içe aktarma: .godot yoksa testler sınıf önbelleği olmadan koşamaz (CI gibi iki deneme)
if [ ! -f .godot/global_script_class_cache.cfg ]; then
  timeout 1200 godot --headless --import >>"$LOG" 2>&1 || \
    timeout 1200 godot --headless --import >>"$LOG" 2>&1 || \
    echo "uyarı: godot içe aktarma bitmedi (günlük: $LOG)"
fi

echo "Wayborne hazır: $(godot --version 2>/dev/null | head -1)"
