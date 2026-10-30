#!/usr/bin/env bash
# Test koşusunu sessiz çalıştırır: tam çıktı bir dosyaya, ekrana yalnızca kalanlar, betik hataları ve özet satırı.
# Yüz satırlık "✓ paket" listesi ve motorun çıkış uyarıları bağlama girmesin diye (CLAUDE.md, Çalışma düzeni).
#
#   tools/test_ozet.sh [günlük dosyası]        varsayılan: /tmp/wayborne_tests.log
set -u
cd "$(dirname "$0")/.."
LOG="${1:-/tmp/wayborne_tests.log}"
timeout 900 godot --headless --script res://tests/run_tests.gd >"$LOG" 2>&1
CODE=$?
grep -E "^  ✗ |^  ! |SCRIPT ERROR|Parse Error|Compile Error|Failed to load script|Failed to create an autoload" "$LOG" | head -40
grep -E "^── [0-9]+ geçti" "$LOG" || echo "özet satırı yok (koşu yarıda kesildi?), çıkış kodu $CODE"
echo "tam çıktı: $LOG"
exit $CODE
