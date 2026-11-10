#!/usr/bin/env python3
"""Fable 5.2 promptunu veriyle birlikte üretir.

`docs/fable_promptu_sablon.md` elle yazılmış prompttur; içindeki `{{VERI_n}}`
işaretlerinin yerine bu betik depodan çıkardığı gerçek veriyi koyar ve
`docs/fable_sistem_promptu.md`'yi yazar. Böylece oyun değiştikçe prompt
yeniden üretilir, elle güncellenmez.

Veri nereden geliyor:
  VERİ-1  oturum ve sefer durumu  <- game_session.gd, journey_controller.gd (sabit, kayıt alanı, API)
  VERİ-2  olay sistemi            <- fable_dump.gd (101 kart) + event_effect.gd + road_director.gd
  VERİ-3  insanlar                <- fable_dump.gd (huy/sınıf/görev/kültür) + character_data.gd
  VERİ-4  ekonomi ve dünya        <- fable_dump.gd (mal/yerleşim) + ekonomi sabitleri
  VERİ-5  lore                    <- docs/lore/SIDERIA.md (olduğu gibi)
  VERİ-6  ölçüm                   <- simulate_career / simulate_expert_review / simulate_journeys

    python3 -I tools/fable_paket.py            # ölçümleri de koşturur (~3 dk)
    python3 -I tools/fable_paket.py --hizli    # ölçüm koşturmaz, son günlükleri kullanır
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SABLON = ROOT / "docs" / "fable_promptu_sablon.md"
CIKTI = ROOT / "docs" / "fable_sistem_promptu.md"
OLCUM = ROOT / "build" / "fable_olcum"

SIM = [
    ("kariyer", "simulate_career.gd", "Kariyer yayı: 3 politika × 8 kervan × 40 sefer"),
    ("uzman", "simulate_expert_review.gd", "Uzman denetimi: tutundurma, sistem, zanaat"),
    ("sefer", "simulate_journeys.gd", "Tek sefer ekonomisi ve olay dağılımı"),
]

# Sabitleri ve kayıt alanlarını çıkaracağımız dosyalar.
SABIT_DOSYALARI = {
    "VERI_1": [
        ("scripts/autoload/game_session.gd", "GameSession - kervanın bütün kalıcı durumu"),
        ("scripts/travel/journey_controller.gd", "JourneyController - bir seferin durumu"),
        ("scripts/travel/caravan_state.gd", "CaravanState - vagon ve kapasite"),
        ("scripts/travel/journey_clock.gd", "JourneyClock - gün ve saat"),
    ],
    "VERI_2": [
        ("scripts/events/road_director.gd", "RoadDirector - kart çekilişinin ağırlıkları"),
        ("scripts/events/event_engine.gd", "EventEngine - günlük çekiliş"),
        ("scripts/events/skill_check.gd", "SkillCheck - beceri kontrolü"),
    ],
    "VERI_3": [
        ("scripts/character/character_data.gd", "CharacterData - kişi, stres, yorgunluk, kırgınlık"),
        ("scripts/character/character_stats.gd", "CharacterStats - yedi stat"),
        ("scripts/campaign/caravan_ledger.gd", "CaravanLedger - defter"),
    ],
    "VERI_4": [
        ("scripts/travel/scarcity.gd", "Scarcity - kıtlık sürüklenmesi"),
        ("scripts/economy/market_pricing.gd", "MarketPricing - fiyat"),
        ("scripts/economy/market_conditions.gd", "MarketConditions - şehrin hâli"),
        ("scripts/economy/debt.gd", "Debt - borç"),
        ("scripts/economy/debt_ledger.gd", "DebtLedger - borç defteri"),
        ("scripts/travel/plague_world.gd", "PlagueWorld - İllet dünya hâli"),
        ("scripts/travel/contract_board.gd", "ContractBoard - kontrat panosu"),
    ],
}

KAYIT_ALANI = re.compile(r'^\s*"([a-z_0-9]+)"\s*:', re.M)
SABIT = re.compile(r"^const ([A-Z][A-Z_0-9]*)(?:\s*:\s*[^=]+?)?\s*=\s*(.+?)\s*$", re.M)
FONKSIYON = re.compile(r"^func ([a-z][a-z_0-9]*)\(([^)]*)\)(?:\s*->\s*([^:]+))?:", re.M)


def oku(yol: str) -> str:
    p = ROOT / yol
    return p.read_text(encoding="utf-8") if p.is_file() else ""


def yorumlu_sabitler(metin: str, limit: int = 400) -> list[str]:
    """`const AD = deger` satırları, varsa üstündeki tek satırlık ## yorumuyla."""
    satirlar = metin.splitlines()
    out: list[str] = []
    for i, satir in enumerate(satirlar):
        m = SABIT.match(satir)
        if not m:
            continue
        ad, deger = m.group(1), m.group(2)
        if len(deger) > 120:
            deger = deger[:117] + "..."
        yorum = ""
        j = i - 1
        parcalar: list[str] = []
        while j >= 0 and satirlar[j].strip().startswith("##"):
            parcalar.insert(0, satirlar[j].strip().lstrip("#").strip())
            j -= 1
            if len(parcalar) >= 3:
                break
        if parcalar:
            yorum = " ".join(parcalar)
            if len(yorum) > 220:
                yorum = yorum[:217] + "..."
        out.append("%-34s = %s%s" % (ad, deger, ("   # " + yorum) if yorum else ""))
        if len(out) >= limit:
            break
    return out


def api_yuzeyi(metin: str, limit: int = 220) -> list[str]:
    out = []
    for m in FONKSIYON.finditer(metin):
        ad, arg, don = m.group(1), m.group(2).strip(), (m.group(3) or "").strip()
        if ad.startswith("_"):
            continue
        imza = "%s(%s)" % (ad, arg)
        if don:
            imza += " -> " + don
        out.append(imza)
        if len(out) >= limit:
            break
    return out


def kayit_alanlari(metin: str) -> list[str]:
    """to_save_dict gövdesindeki anahtarlar: kalıcı durum."""
    bas = metin.find("func to_save_dict")
    if bas < 0:
        return []
    son = metin.find("\nfunc ", bas + 10)
    govde = metin[bas: son if son > 0 else len(metin)]
    return sorted(set(KAYIT_ALANI.findall(govde)))


def blok(baslik: str, govde: str, dil: str = "") -> str:
    return "**%s**\n\n```%s\n%s\n```\n" % (baslik, dil, govde.rstrip())


def dump() -> dict:
    print("  godot dökümü...", flush=True)
    sonuc = subprocess.run(
        ["godot", "--headless", "--script", "res://tools/fable_dump.gd"],
        cwd=ROOT, capture_output=True, text=True, timeout=300)
    for satir in sonuc.stdout.splitlines():
        if satir.startswith("FABLE_JSON "):
            return json.loads(satir[len("FABLE_JSON "):])
    raise SystemExit("fable_dump.gd veri basmadı:\n" + sonuc.stdout[-2000:] + sonuc.stderr[-2000:])


def olcumleri_al(hizli: bool) -> str:
    OLCUM.mkdir(parents=True, exist_ok=True)
    parcalar = []
    for ad, betik, aciklama in SIM:
        gunluk = OLCUM / (ad + ".log")
        if not hizli or not gunluk.is_file():
            print("  ölçüm: %s..." % ad, flush=True)
            sonuc = subprocess.run(["godot", "--headless", "--script", "res://tests/" + betik],
                                   cwd=ROOT, capture_output=True, text=True, timeout=1800)
            gunluk.write_text(sonuc.stdout, encoding="utf-8")
        satirlar = [s for s in gunluk.read_text(encoding="utf-8").splitlines()
                    if s.strip() and not s.startswith(("Godot Engine", "WARNING", "     at:"))]
        parcalar.append("### %s\n\n*%s*\n\n```\n%s\n```\n" % (ad.capitalize(), aciklama, "\n".join(satirlar)))
    return "\n".join(parcalar)


def veri_1(d: dict) -> str:
    gs = oku("scripts/autoload/game_session.gd")
    p = ["Oyunun bütün kalıcı durumu tek bir nesnede (`GameSession`, RefCounted) duruyor; ekranlar onu "
         "`GameState.get_session()` ile okur. Sinyal yolu (event bus) **yok**: dinleyicisi olmadığı için "
         "kaldırıldı.\n"]
    p.append(blok("Kayda yazılan alanlar (kalıcı durum — kaydetme yalnızca şehirde olur)",
                  "\n".join(", ".join(kayit_alanlari(gs)[i:i + 6]) for i in range(0, 600, 6)).strip()))
    for yol, baslik in SABIT_DOSYALARI["VERI_1"]:
        metin = oku(yol)
        if not metin:
            continue
        sabitler = yorumlu_sabitler(metin)
        if sabitler:
            p.append(blok("%s · ayar sabitleri (`%s`)" % (baslik, yol), "\n".join(sabitler)))
    p.append(blok("GameSession · genel API yüzeyi (sistemlerin dokunabildiği yer)",
                  "\n".join(api_yuzeyi(gs))))
    jc = oku("scripts/travel/journey_controller.gd")
    p.append(blok("JourneyController · genel API yüzeyi", "\n".join(api_yuzeyi(jc, 120))))
    return "\n".join(p)


def veri_2(d: dict) -> str:
    ee = oku("scripts/events/event_effect.gd")
    bas = ee.find("enum Type")
    son = ee.find("}", bas)
    p = ["Bir yol günü şöyle işliyor: `EventEngine` günlük şansı hesaplar → `RoadDirector` katalogu "
         "ağırlıklandırır (görülmemiş kartı kayırır, savaş borcunu gözetir, korunan yolda yağmayı kısar) "
         "→ kart çıkar → oyuncu seçer → `SkillCheck` (varsa) → ağırlıklı `EventOutcome` → "
         "`EventEffectApplier` etkileri uygular → `EventText` metindeki `{who}` ve `{town}` yerine "
         "gerçek kişi ve yer adını koyar.\n"]
    p.append(blok("EventEffect.Type — bir kartın dünyaya dokunabildiği her yer", ee[bas:son + 1], "gdscript"))
    for yol, baslik in SABIT_DOSYALARI["VERI_2"]:
        metin = oku(yol)
        sabitler = yorumlu_sabitler(metin)
        if sabitler:
            p.append(blok("%s (`%s`)" % (baslik, yol), "\n".join(sabitler)))

    satirlar = ["%-26s %-34s %3s %s" % ("id", "başlık", "ağr", "seçenekler (kontrol | etkiler)")]
    for e in d["olaylar"]:
        sec = []
        for s in e["secenekler"]:
            etki = "+".join(sorted(set(s["dogrudan_etki"] + s["sonuc_etkileri"]))) or "-"
            k = (" [%s]" % s["kontrol"]) if s["kontrol"] else ""
            sec.append("%s%s{%s}" % (s["metin"], k, etki))
        bayrak = []
        if e["tek_seferlik"]:
            bayrak.append("tek")
        if e["yalniz_tetikle"]:
            bayrak.append("zincir")
        if e["kosullar"]:
            bayrak.append("koşul:" + ";".join(e["kosullar"]))
        satirlar.append("%-26s %-34s %3.1f %s%s" % (
            e["id"], e["baslik"][:34], e["agirlik"], " / ".join(sec),
            ("  <%s>" % ",".join(bayrak)) if bayrak else ""))
    p.append(blok("Katalogun tamamı: %d yol kartı" % len(d["olaylar"]), "\n".join(satirlar)))
    return "\n".join(p)


def veri_3(d: dict) -> str:
    p = ["Tayfa ile parti ayrıdır: kervanda herkes yürür, savaşa dört kişi girer. Her kişi bir kültür, "
         "bir sınıf, bir görev, huylar ve ekipman taşır; stres, yorgunluk ve kırgınlık biriktirir.\n"]
    p.append(blok("Kültürler (oyuncu başlangıcı buradan seçilir)",
                  "\n".join("%-8s %-18s %-28s stat %s · erzak×%s alış×%s hasar×%s haber×%s"
                            % (c["id"], c["ad"], c["ayricalik"][:28], ",".join(c["stat"]),
                               c["erzak_carpani"], c["alis_carpani"], c["hasar_carpani"], c["haber_zorlugu"])
                            for c in d["kulturler"])))
    p.append(blok("Sınıflar ve görevler",
                  "\n".join("%-12s %-16s görev=%-10s can+%-3s beceri: %s"
                            % (c["id"], c["ad"], c["gorev"], c["can"], ", ".join(c["beceriler"]))
                            for c in d["siniflar"])
                  + "\n\n" + "\n".join("görev %-10s %-14s ana stat %s · %s"
                                       % (g["id"], g["ad"], g["stat"], g["metin"][:70])
                                       for g in d["gorevler"])))
    p.append(blok("Huylar (16) — tohum huyları ve kırılma huyları",
                  "\n".join("%-20s %-16s %s · %s" % (t["id"], t["ad"], "olumlu" if t["olumlu"] else "OLUMSUZ",
                                                     t["metin"][:80]) for t in d["huylar"])))
    for yol, baslik in SABIT_DOSYALARI["VERI_3"]:
        sabitler = yorumlu_sabitler(oku(yol))
        if sabitler:
            p.append(blok("%s (`%s`)" % (baslik, yol), "\n".join(sabitler)))
    p.append(blok("Savaş becerileri (%d)" % len(d["beceriler"]),
                  ", ".join("%s(%s)" % (s["id"], s["hasar"] or ("+%s" % s["sifa"] if s["sifa"] else "-"))
                            for s in d["beceriler"])))
    p.append(blok("Ekipman (%d)" % len(d["ekipman"]),
                  ", ".join("%s[%s]" % (e["id"], e["yuva"]) for e in d["ekipman"])))
    return "\n".join(p)


def veri_4(d: dict) -> str:
    p = ["Kervan malı ucuza alıp pahalıya satar ama kıtlıkta asıl gelir **ulaştırmadır**: kontrat, "
         "teslimat ve şehrin hâli. Her şehrin ürettiği ve istediği mal, sur türü, bölgesi ve halkı var.\n"]
    p.append(blok("Ticaret malları (%d)" % len(d["mallar"]),
                  "\n".join("%-14s %-16s %4s GG · ağırlık %-4s raf %-4s %s"
                            % (m["id"], m["ad"], m["fiyat"], m["agirlik"], m["raf_gun"],
                               ("KAÇAK" if m["kacak"] else "") + (" NADİR" if m["nadir"] else ""))
                            for m in d["mallar"])))
    p.append(blok("Yerleşimler (%d) — bölge, tür, sur, üretim, talep, komşular" % len(d["yerlesimler"]),
                  "\n".join("%-16s %-12s %-10s %-6s sur=%-6s üretir:%-24s ister:%-24s -> %s"
                            % (y["id"], y["ad"], y["bolge"], y["tur"], y["sur"],
                               ",".join(y["uretir"]) or "-", ",".join(y["ister"]) or "-",
                               ",".join(y["komsular"]))
                            for y in d["yerlesimler"])))
    p.append(blok("Bölgesel haydut kimlikleri (yolu kesen, oranın kendi aç insanıdır)",
                  json.dumps(d["haydutlar"], ensure_ascii=False, indent=1), "json"))
    for yol, baslik in SABIT_DOSYALARI["VERI_4"]:
        sabitler = yorumlu_sabitler(oku(yol))
        if sabitler:
            p.append(blok("%s (`%s`)" % (baslik, yol), "\n".join(sabitler)))
    return "\n".join(p)


def main() -> None:
    hizli = "--hizli" in sys.argv
    d = dump()
    print("  ölçümler...", flush=True)
    olcum = olcumleri_al(hizli)
    lore = oku("docs/lore/SIDERIA.md")
    tam = SABLON.read_text(encoding="utf-8")
    # Çıktı yalnızca promptun kendisidir: şablonun kullanım notu ve üretim notu dışarıda kalır,
    # yoksa not içindeki `{{VERI_1}}` örnekleri de doldurulur ve veri ikinci kez yazılır.
    bas = tam.index("## PROMPT BAŞLANGICI")
    son = tam.index("## PROMPT SONU") + len("## PROMPT SONU")
    sablon = tam[bas:son]
    yerler = {
        "VERI_1": veri_1(d),
        "VERI_2": veri_2(d),
        "VERI_3": veri_3(d),
        "VERI_4": veri_4(d),
        # Lore kendi başlık ağacını taşıyor; promptun §A-§I yapısına karışmasın diye
        # çitle ayrılır (SIDERIA.md'de hiç çit yok, ~~~~ güvenli).
        "VERI_5": "~~~~markdown\n" + lore.rstrip() + "\n~~~~",
        "VERI_6": olcum,
    }
    eksik = [k for k in yerler if ("{{%s}}" % k) not in sablon]
    if eksik:
        raise SystemExit("şablonda yer tutucu yok: %s" % ", ".join(eksik))
    for anahtar, govde in yerler.items():
        sablon = sablon.replace("{{%s}}" % anahtar, govde)
    kalan = re.findall(r"\{\{[A-Z_0-9]+\}\}", sablon)
    if kalan:
        raise SystemExit("doldurulmamış yer tutucu kaldı: %s" % ", ".join(sorted(set(kalan))))
    bugun = subprocess.run(["date", "+%Y-%m-%d %H:%M"], capture_output=True, text=True).stdout.strip()
    commit = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--short", "HEAD"],
                            capture_output=True, text=True).stdout.strip()
    basli = (
        "<!-- ÜRETİLMİŞ DOSYA. Elle düzenleme: kaynak docs/fable_promptu_sablon.md,\n"
        "     üretici tools/fable_paket.py. Üretim: %s · depo %s -->\n\n"
        "> **Kullanım:** aşağıdaki metnin tamamını (bu satır dahil değil) Fable 5.2'ye yapıştır.\n"
        "> Oyunun bugünkü durumu, 101 kartın tamamı, kataloglar, dünya kitabı ve ölçüm raporları içinde\n"
        "> gömülü; Fable'ın ayrıca dosya istemesine gerek yok. Tek boş alan VERİ-7 (senin oyun notların).\n\n"
    ) % (bugun, commit or "?")
    sablon = basli + sablon
    CIKTI.write_text(sablon, encoding="utf-8")
    satir = sablon.count("\n") + 1
    print("yazıldı: %s · %d satır · %.0f KB · ~%d bin jeton"
          % (CIKTI.relative_to(ROOT), satir, CIKTI.stat().st_size / 1024,
             round(len(sablon) / 3.3 / 1000)))


if __name__ == "__main__":
    main()
