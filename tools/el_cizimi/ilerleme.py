#!/usr/bin/env python3
"""El çizimi ilerlemesinin ölçümü: envanter + depodaki gerçek durum -> JSON.

Takip sayfasının (`docs/el_cizimi/takip_sayfasi.html`) okuduğu tek veri dosyası
buradan çıkar. Ölçüm depodan okunur, elle girilen bir listeden değil:

  art_source/el_cizimi/islenmis/<KİMLİK>/   -> "oyunda"   (al.py işledi)
  art_source/el_cizimi/gelen/<KİMLİK>.*     -> "yuklendi" (yüklendi, işlenmedi)
  ikisi de yoksa                            -> "bekliyor"

Excel'deki (`docs/el_cizimi/el_cizimi_takip.xlsx`) kullanıcı girdisi varsa
"excel" alanında ayrıca taşınır; depodaki durumu ezmez, yanında durur.

    python3 -I tools/el_cizimi/ilerleme.py                 # özeti basar
    python3 -I tools/el_cizimi/ilerleme.py --yaz           # docs/el_cizimi/ilerleme.json
    python3 -I tools/el_cizimi/ilerleme.py --sayfa <yol>   # takip sayfasını üretir

Takip sayfası `takip_sayfasi_sablon.html` + bu ölçümdür: şablondaki `__VERI__`
yerine ölçüm JSON'u gömülür, çıktı artifact olarak yayınlanır. Kullanıcı
"güncelle" dediğinde iki komut yeter: --yaz ve --sayfa, sonra aynı adrese
yeniden yayınla.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import envanter  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
GELEN = ROOT / "art_source" / "el_cizimi" / "gelen"
ISLENMIS = ROOT / "art_source" / "el_cizimi" / "islenmis"
ARSIV = ROOT / "art_source" / "el_cizimi" / "arsiv"
CIKTI = ROOT / "docs" / "el_cizimi" / "ilerleme.json"
SABLON = ROOT / "docs" / "el_cizimi" / "takip_sayfasi_sablon.html"
EXCEL = ROOT / "docs" / "el_cizimi" / "el_cizimi_takip.xlsx"

AI = "AI görsel"


def _git(*args: str) -> str:
    try:
        return subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True,
                              text=True, check=True).stdout.strip()
    except Exception:
        return ""


def _yuklenen_kimlikler() -> dict[str, list[str]]:
    """gelen/ klasöründeki dosya adlarından kimlik -> dosyalar."""
    bulunan: dict[str, list[str]] = {}
    if not GELEN.is_dir():
        return bulunan
    for yol in sorted(GELEN.iterdir()):
        if yol.is_dir() or yol.name.startswith(".") or yol.suffix.lower() in {".md", ".txt", ".xlsx"}:
            continue
        kimlik = yol.stem.split("__", 1)[0]
        bulunan.setdefault(kimlik, []).append(yol.name)
    return bulunan


def _islenen_kimlikler() -> set[str]:
    if not ISLENMIS.is_dir():
        return set()
    return {p.name for p in ISLENMIS.iterdir() if p.is_dir()}


def _excel_durumlari() -> dict[str, str]:
    """Kullanıcının kendi Excel'indeki Durum sütunu (varsa)."""
    if not EXCEL.is_file():
        return {}
    try:
        import openpyxl
    except Exception:
        return {}
    try:
        wb = openpyxl.load_workbook(EXCEL, data_only=True, read_only=True)
        ws = wb["Liste"]
        satirlar = ws.iter_rows(values_only=True)
        basliklar = list(next(satirlar))
        i_kimlik = basliklar.index("Kimlik")
        i_durum = basliklar.index("Durum")
    except Exception:
        return {}
    out: dict[str, str] = {}
    for satir in satirlar:
        kimlik = satir[i_kimlik] if i_kimlik < len(satir) else None
        durum = satir[i_durum] if i_durum < len(satir) else None
        if kimlik and durum and str(durum).strip() not in {"", "Başlanmadı"}:
            out[str(kimlik)] = str(durum).strip()
    return out


def olc() -> dict:
    satirlar = envanter.all_rows()
    yuklenen = _yuklenen_kimlikler()
    islenen = _islenen_kimlikler()
    excel = _excel_durumlari()

    kalemler = []
    for r in satirlar:
        kimlik = r["id"]
        if kimlik in islenen:
            durum = "oyunda"
        elif kimlik in yuklenen:
            durum = "yuklendi"
        else:
            durum = "bekliyor"
        kalem = {
            "id": kimlik,
            "kategori": r["kategori"],
            "grup": r["alt_grup"],
            "ad": r["ad"],
            "ne": r["ne_cizilecek"],
            "hedef": r["hedef"],
            "kaynak": r["kaynak"],
            "renk": r["renk"],
            "tuval": r["tuval"],
            "katmanlar": r["katmanlar"],
            "teslim": r["teslim"],
            "oncelik": r["oncelik"],
            "saat": r["saat"],
            "tip": r.get("sablon_tip", ""),
            "durum": durum,
        }
        for anahtar, hedef in (("bagimlilik", "once"), ("not", "not")):
            if r.get(anahtar):
                kalem[hedef] = r[anahtar]
        if r.get("kod_gerekir"):
            kalem["kod"] = True
        if kimlik in yuklenen:
            kalem["dosyalar"] = yuklenen[kimlik]
        if kimlik in excel:
            kalem["excel"] = excel[kimlik]
        kalemler.append(kalem)

    bilinmeyen = sorted(set(yuklenen) - {k["id"] for k in kalemler})

    def pay(secici) -> dict:
        alt = [k for k in kalemler if secici(k)]
        return {
            "toplam": len(alt),
            "saat": round(sum(k["saat"] for k in alt), 1),
            "oyunda": sum(1 for k in alt if k["durum"] == "oyunda"),
            "yuklendi": sum(1 for k in alt if k["durum"] == "yuklendi"),
            "bekliyor": sum(1 for k in alt if k["durum"] == "bekliyor"),
            "kalan_saat": round(sum(k["saat"] for k in alt if k["durum"] != "oyunda"), 1),
        }

    kategoriler = {}
    for k in kalemler:
        kategoriler.setdefault(k["kategori"], None)
    return {
        "olcum": {
            "tarih": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
            "commit": _git("rev-parse", "--short", "HEAD"),
            "dal": _git("rev-parse", "--abbrev-ref", "HEAD"),
            "nasil": "gelen/ ve islenmis/ klasörleri sayıldı; kaynak tools/el_cizimi/envanter.py",
            "arsiv": len([p for p in ARSIV.iterdir()]) if ARSIV.is_dir() else 0,
            "bilinmeyen_dosyalar": bilinmeyen,
        },
        "ozet": pay(lambda k: True)
        | {
            "ai_toplam": sum(1 for k in kalemler if k["kaynak"].startswith(AI)),
            "ai_kalan": sum(1 for k in kalemler if k["kaynak"].startswith(AI) and k["durum"] != "oyunda"),
        },
        "oncelikler": {str(o): pay(lambda k, o=o: k["oncelik"] == o) for o in (1, 2, 3)},
        "kategoriler": {ad: pay(lambda k, ad=ad: k["kategori"] == ad) for ad in kategoriler},
        "kalemler": kalemler,
    }


def main() -> None:
    veri = olc()
    o = veri["ozet"]
    print("ölçüm: %s  commit %s" % (veri["olcum"]["tarih"], veri["olcum"]["commit"] or "-"))
    print("%d kalem, %.0f saat tahmin" % (o["toplam"], o["saat"]))
    print("oyunda %d · yüklendi %d · bekliyor %d · kalan %.0f saat"
          % (o["oyunda"], o["yuklendi"], o["bekliyor"], o["kalan_saat"]))
    print("AI kaynaklı kalan: %d / %d" % (o["ai_kalan"], o["ai_toplam"]))
    for ad, p in veri["kategoriler"].items():
        print("  %-10s %3d kalem · oyunda %3d · %5.0f saat kaldı" % (ad, p["toplam"], p["oyunda"], p["kalan_saat"]))
    if veri["olcum"]["bilinmeyen_dosyalar"]:
        print("gelen/ içinde envanterde olmayan: %s" % ", ".join(veri["olcum"]["bilinmeyen_dosyalar"]))
    if "--sayfa" in sys.argv:
        i = sys.argv.index("--sayfa")
        hedef = Path(sys.argv[i + 1]) if len(sys.argv) > i + 1 else ROOT / "takip_sayfasi.html"
        sablon = SABLON.read_text(encoding="utf-8")
        if "__VERI__" not in sablon:
            raise SystemExit("şablonda __VERI__ yer tutucusu yok: %s" % SABLON)
        gomulu = json.dumps(veri, ensure_ascii=False, separators=(",", ":"))
        hedef.parent.mkdir(parents=True, exist_ok=True)
        hedef.write_text(sablon.replace("__VERI__", gomulu), encoding="utf-8")
        print("sayfa: %s (%.0f KB)" % (hedef, hedef.stat().st_size / 1024))
    if "--yaz" in sys.argv:
        CIKTI.parent.mkdir(parents=True, exist_ok=True)
        CIKTI.write_text(json.dumps(veri, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
        print("yazıldı: %s (%.0f KB)" % (CIKTI.relative_to(ROOT), CIKTI.stat().st_size / 1024))


if __name__ == "__main__":
    main()
