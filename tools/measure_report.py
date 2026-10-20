# -*- coding: utf-8 -*-
"""Oyun ölçüm raporu (görev Y-K03): sefer süresi, kart sayısı, ölüm oranı, oturum uzunluğu.

    python -X utf8 tools/measure_report.py <simulate_career günlüğü> [beat dosyası] > rapor.md
    python -X utf8 tools/measure_report.py --self-test

İki kaynak, iki ayrı soru:
- Simülatör (tests/simulate_career.gd, `OLCUM {...}` satırları): politika başına
  sefer süresi (gün ve 1x gerçek dakika), sefer başına çekilen kart ve ölüm.
  CI'da (.github/workflows/olcum.yml) her çalıştırmada üretilir.
- Oyuncu tarafı (user://playtest_beats.jsonl): yalnızca oyuncu Ayarlar'dan izin
  verdiyse yazılır ve yalnızca o bilgisayarda kalır. Oturumlar `session`
  satırlarıyla ayrılır; oturum uzunluğu oturumun ilk ve son anı arasındaki
  gerçek oyun süresi.
"""
import json
import sys


def parse_measures(text):
    rows = []
    for line in text.splitlines():
        if line.startswith("OLCUM "):
            rows.append(json.loads(line[len("OLCUM "):]))
    return rows


def sessions(beat_rows):
    """Kervan başına oturum uzunlukları (saniye). Bir `session` satırı yeni
    oturumu açar; play_seconds kayıtla birlikte saklandığı için t oturumlar
    arasında kaldığı yerden sürer."""
    out = {}
    for caravan in sorted({r.get("caravan", "?") for r in beat_rows}):
        rows = [r for r in beat_rows if r.get("caravan", "?") == caravan]
        lengths, start, last = [], None, None
        for r in rows:
            t = float(r["t"])
            if r["kind"] == "session":
                if start is not None and last is not None:
                    lengths.append(max(0.0, last - start))
                start, last = t, t
                continue
            if start is None:
                start = t
            last = t
        if start is not None and last is not None:
            lengths.append(max(0.0, last - start))
        out[caravan] = lengths
    return out


def report(measures, beat_rows):
    lines = ["# Wayborne ölçüm raporu", "", "## Simülatör (8 kervan × 40 sefer, politika başına)", ""]
    if not measures:
        lines.append("Simülatör ölçüm satırı yok (`OLCUM`).")
    else:
        lines += ["| politika | sefer | gün/sefer | dk/sefer (1x) | kart/sefer | ölüm/sefer |",
                  "|---|---:|---:|---:|---:|---:|"]
        for m in measures:
            lines.append("| %s | %d | %.1f | %.1f | %.2f | %.3f |" % (
                m["policy"], m["legs"], m["days_per_leg"], m["minutes_per_leg"], m["cards_per_leg"],
                m["deaths_per_leg"]))
    lines += ["", "## Oyuncu oturumları (izinle, yerel)", ""]
    if not beat_rows:
        lines.append("Oyuncu kaydı yok: ölçüm izni kapalı ya da dosya verilmedi.")
    else:
        for caravan, lengths in sessions(beat_rows).items():
            if not lengths:
                continue
            mean = sum(lengths) / len(lengths)
            lines.append("- %s: %d oturum, ortalama %.1f dk, en uzun %.1f dk" % (
                caravan, len(lengths), mean / 60.0, max(lengths) / 60.0))
    return "\n".join(lines) + "\n"


def self_test():
    text = 'x\nOLCUM {"policy":"p","legs":10,"days_per_leg":15.0,"minutes_per_leg":11.25,' \
           '"cards_per_leg":5.5,"deaths_per_leg":0.1,"arcs":1}\n'
    m = parse_measures(text)
    assert len(m) == 1 and m[0]["legs"] == 10, m
    rows = [{"caravan": "A", "t": 0, "kind": "session"}, {"caravan": "A", "t": 30, "kind": "info"},
            {"caravan": "A", "t": 600, "kind": "decision"}, {"caravan": "A", "t": 600, "kind": "session"},
            {"caravan": "A", "t": 900, "kind": "info"}]
    s = sessions(rows)
    assert s["A"] == [600.0, 300.0], s
    out = report(m, rows)
    assert "| p | 10 | 15.0 | 11.2 | 5.50 | 0.100 |" in out or "| p | 10 | 15.0 | 11.3 | 5.50 | 0.100 |" in out, out
    assert "2 oturum" in out, out
    print("öz sınama tamam")


def main(argv):
    if argv and argv[0] == "--self-test":
        self_test()
        return 0
    if not argv:
        print(__doc__)
        return 1
    raw = open(argv[0], "rb").read()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        # Windows'ta Godot konsolu sistem kod sayfasıyla yazıyor (Türkçe: cp1254).
        text = raw.decode("cp1254", errors="replace")
    measures = parse_measures(text)
    beats = []
    if len(argv) > 1:
        for line in open(argv[1], encoding="utf-8"):
            if line.strip():
                beats.append(json.loads(line))
    sys.stdout.write(report(measures, beats))
    return 0 if measures else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
