"""El çizimi programının tek envanteri.

Oyunda görünen ya da görünmesi gereken her görsel burada bir satır: kimlik,
ne çizileceği, oyunda nereye gittiği, bugünkü kaynağı, tuval, katmanlar,
öncelik ve tahmini süre. Şablon üretici (`sablon_uret.py`), Excel takip
dosyası (`takip_excel.py`) ve alım aracı (`al.py`) hep bu listeyi okur;
liste iki yerde tutulursa üçü birbirinden kayar.

Bilerek dışarıda kalanlar (kullanıcı kararı: "olması gerekmeyen, eski
çalışmaları, ek kaynak paketlerini dahil etme"):
  - eski kasaba yedekleri (demirkapi, ipekevi, karakonak, kurtbogazi, yesilova;
    her yerleşimin kendi resmi var, bunlar yalnızca düşüş yolu), towns/camp,
  - izometrik şehir haritasının iso_* eşyaları (harita silindi),
  - yalnızca taslak ekranlarda (GrimDrafts) okunan dokular: lantern_emblem,
    notice_card, tatter_mask, frost_overlay, grime_overlay,
  - b6_map (dünya haritası artık karo), saf gradyanlar (vignette, lantern_glow),
  - art_source/ altındaki ham paketler (Kenney, Quaternius, MakeHuman...).
Oyunda ne olduğu kodla birlikte değişir; bu dosya değişince şablonlar ve Excel
yeniden üretilir (`python3 tools/el_cizimi/sablon_uret.py`, `takip_excel.py`).

    python3 -I tools/el_cizimi/envanter.py        # özet sayıları basar
"""
from __future__ import annotations

import csv
import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
A = ROOT / "data" / "assets"

# --- sabitler -----------------------------------------------------------

FIG_LAYERS = ["arka_kol", "arka_bacak", "govde", "on_bacak", "on_kol"]
FIG_LAYERS_RENDER = ["back_arm", "back_leg", "torso_head", "front_leg", "front_arm"]
# Etek, elbise, cüppe: bacakların önünde tek parça (pilot: bacak katmanlarına bölünen etek adım açılınca yarılıyor).
SKIRT_ITEMS = {"long_skirt", "tiered_skirt", "shift_dress", "pinafore_dress", "pilgrim_robe", "scribe_robe", "mage_robe"}
FIG_LAYERS_SKIRT = ["arka_kol", "arka_bacak", "govde", "on_bacak", "etek", "on_kol"]
BEAST_LAYERS = ["uzak_bacaklar", "kuyruk", "govde"]
BEAST_LAYERS_RENDER = ["skin_far", "skin_tail", "skin_main"]

GRI = "Gri tonlarla (oyun rengi kendisi çarpar)"
RENK = "Tam renk"

KAYNAK_AI = "AI görsel (Gemini) - beyan gerektirir"
KAYNAK_RENDER = "3B render (CC0 model)"
KAYNAK_PROC = "Prosedürel (kodla çiziliyor)"
KAYNAK_CC0 = "CC0 paket"
KAYNAK_YOK = "Yok - yeni"

BODY_NAMES = {"male": "Erkek", "female": "Kadın"}
_G = {"male": "E", "female": "K"}

# --- yardımcılar ----------------------------------------------------------


def _row(**kw) -> dict:
    base = {
        "id": "", "kategori": "", "alt_grup": "", "ad": "", "ne_cizilecek": "",
        "hedef": "", "kaynak": "", "renk": RENK, "tuval": "", "katmanlar": [],
        "teslim": "PNG", "sablon": "", "oncelik": 3, "saat": 1.0,
        "bagimlilik": "", "not": "", "sablon_tip": "", "kaynak_dosya": "",
        "kod_gerekir": False,
    }
    base.update(kw)
    if not base["katmanlar"]:
        base["katmanlar"] = ["cizim"]
    base["teslim"] = "PSD (adlı katmanlar)" if len(base["katmanlar"]) > 1 else "PNG (saydam)"
    return base


def _size(path: Path) -> tuple[int, int]:
    from PIL import Image
    with Image.open(path) as im:
        return im.size


def _canvas_for(w: int, h: int, longest: int) -> str:
    k = longest / max(w, h)
    return "%dx%d" % (round(w * k / 16) * 16, round(h * k / 16) * 16)


def _tr_titles() -> dict:
    out = {}
    for name in ("events.csv", "game.csv", "ui.csv"):
        path = ROOT / "data" / "locale" / name
        with open(path, encoding="utf-8") as f:
            for r in csv.reader(f):
                if len(r) > 1:
                    out[r[0]] = r[1]
    return out


# --- kategoriler -----------------------------------------------------------


def figures() -> list[dict]:
    """Bedenler, temel takım, giysiler, saçlar: tek çizim, oyun büker.

    Yalnızca orta kilolu beden çizilir; ince ve iri bedenler aynı çizimden
    3B ağırlıklarla türetilir. Her parça beş derinlik katmanında, rölanti
    pozunda (idle) çizilir; yürüyüş, saldırı ve düşüş karelerini oyun
    kemiklerle büker (bkz. docs/el_cizimi/SUREC.md, "Figürler").
    """
    rows = []
    for g in ("male", "female"):
        rows.append(_row(
            id="FIG-BEDEN-%s" % _G[g], kategori="Figür", alt_grup="Beden",
            ad="%s beden (orta kilo)" % BODY_NAMES[g],
            ne_cizilecek="Çıplak beden, yüzsüz değil: yüz, kulak, el, ayak. Rölanti pozu, yandan.",
            hedef="data/assets/characters/frames/body_%s_*" % g, kaynak=KAYNAK_RENDER, renk=GRI,
            tuval="2048x2048", katmanlar=FIG_LAYERS, oncelik=2, saat=8.0,
            sablon_tip="figure", kaynak_dosya="body_%s_average_hd" % g,
        ))
        rows[-1]["not"] = "İnce ve iri bedenler bu çizimden türetilir. Ten rengi oyunda çarpılır: gri çiz."
        for part, label, kind in (("ust", "Atlet" if g == "male" else "Büstiyer", 1), ("alt", "Şort", 2)):
            rows.append(_row(
                id="FIG-TEMEL-%s-%s" % (part.upper(), _G[g]), kategori="Figür", alt_grup="Temel takım",
                ad="%s (%s)" % (label, BODY_NAMES[g].lower()),
                ne_cizilecek="Bedenin altındaki temel giysi; kıyafet giyilmediğinde görünen.",
                hedef="data/assets/characters/frames/body_%s_*" % g, kaynak=KAYNAK_RENDER, renk=GRI,
                tuval="2048x2048", katmanlar=FIG_LAYERS, oncelik=2, saat=1.5,
                sablon_tip="figure", kaynak_dosya="body_%s_average_hd#%d" % (g, kind),
                bagimlilik="FIG-BEDEN-%s" % _G[g],
            ))
            rows[-1]["not"] = "Rengi kıyafet rengiyle çarpılır: gri çiz."
    titles = _tr_titles()
    frames = A / "characters" / "frames"
    items: dict[str, set] = {}
    for d in sorted(os.listdir(frames)):
        m = re.match(r"outfit_(.+)_(male|female)_average_hd$", d)
        if m:
            items.setdefault(m.group(1), set()).add(m.group(2))
    hair = sorted(i for i in items if i.startswith("hair_"))
    for item in sorted(items):
        is_hair = item in hair
        for g in sorted(items[item], reverse=True):
            key = ("HAIR_" + item.removeprefix("hair_").upper()) if is_hair else "OUTFIT_" + item.upper()
            name = titles.get(key, item.replace("_", " "))
            rows.append(_row(
                id="%s-%s-%s" % ("SAC" if is_hair else "KYF", item, _G[g]),
                kategori="Figür", alt_grup="Saç" if is_hair else "Giysi",
                ad="%s (%s)" % (name, BODY_NAMES[g].lower()),
                ne_cizilecek=("Saç, bedenin üstünde, rölanti pozunda." if is_hair else
                              "Giysi bedenin üstünde, rölanti pozunda; beden çizilmez, yalnızca giysi."),
                hedef="data/assets/characters/frames/outfit_%s_%s_*" % (item, g),
                kaynak=KAYNAK_RENDER, renk=GRI if is_hair else RENK, tuval="2048x2048",
                katmanlar=FIG_LAYERS_SKIRT if item in SKIRT_ITEMS else FIG_LAYERS,
                oncelik=2 if item in _COMMON_OUTFITS else 3,
                saat=1.5 if is_hair else 2.5, sablon_tip="figure",
                kaynak_dosya="outfit_%s_%s_average_hd" % (item, g),
                bagimlilik="FIG-BEDEN-%s" % _G[g],
            ))
            if is_hair:
                rows[-1]["not"] = "Saç rengi oyunda çarpılır: gri çiz. Şapka varken saç gizlenir."
    # Henüz olmayan ama gereken başlık ve sakal (CLAUDE.md: "No turban or beard yet").
    for rid, ad, g, slot in (
        ("KYF-sarik-E", "Sarık (erkek)", "male", "Giysi"),
        ("KYF-sarik-K", "Sarık / baş sargısı (kadın)", "female", "Giysi"),
        ("SAC-sakal_kisa-E", "Kısa sakal", "male", "Saç"),
        ("SAC-sakal_uzun-E", "Uzun sakal", "male", "Saç"),
        ("SAC-biyik-E", "Bıyık", "male", "Saç"),
    ):
        rows.append(_row(
            id=rid, kategori="Figür", alt_grup=slot, ad=ad,
            ne_cizilecek="Yeni parça: bedenin üstünde, rölanti pozunda.",
            hedef="(yeni) data/assets/characters/frames/outfit_*", kaynak=KAYNAK_YOK,
            renk=GRI if slot == "Saç" else RENK, tuval="2048x2048", katmanlar=FIG_LAYERS,
            oncelik=3, saat=2.0, sablon_tip="figure",
            kaynak_dosya="body_%s_average_hd" % g, bagimlilik="FIG-BEDEN-%s" % _G[g],
            kod_gerekir=True,
        ))
        rows[-1]["not"] = "Oyuna yeni bir parça olarak eklenecek (katalog + yuva)."
    return rows


_COMMON_OUTFITS = {
    "peasant_shirt", "peasant_pants", "peasant_shoes", "linen_tunic", "felt_shoes", "felt_hat",
    "knit_cap", "peasant_blouse", "long_skirt", "head_veil", "armor_leather", "armor_mail",
    "armor_plate", "guard_helmet", "wool_coat", "leather_boots",
}

_BEAST_TR = {
    "bear": "Ayı", "boar": "Yaban domuzu", "deer": "Geyik (dişi)", "donkey": "Eşek",
    "horse": "At", "horse_white": "Beyaz at", "husky": "Köpek", "ox": "Öküz",
    "stag": "Geyik (erkek)", "wolf": "Kurt",
}


def beasts() -> list[dict]:
    rows = []
    for sp in sorted(os.listdir(A / "characters" / "beasts")):
        if not (A / "characters" / "beasts" / sp / "skin.tres").exists():
            continue
        rows.append(_row(
            id="HAY-%s" % sp, kategori="Hayvan", alt_grup="Deri (BeastSkin)", ad=_BEAST_TR.get(sp, sp),
            ne_cizilecek="Yandan, adım ortasında; uzak bacaklar, kuyruk ve gövde ayrı katmanda. "
                         "Siluet şablondan taşmasın: oyun bu çizimi kemiklerle büküyor.",
            hedef="data/assets/characters/beasts/%s/skin_*.png" % sp, kaynak=KAYNAK_RENDER,
            tuval="2048 genişlik (şablonda)", katmanlar=BEAST_LAYERS,
            oncelik=2 if sp in ("ox", "horse", "wolf", "donkey", "husky") else 3, saat=5.0,
            sablon_tip="beast", kaynak_dosya=sp,
        ))
    rows.append(_row(
        id="HAY-harita_atli", kategori="Hayvan", alt_grup="Harita", ad="Haritadaki atlı (8 yön)",
        ne_cizilecek="Fenerli atlı, sekiz yöne bakan sekiz küçük çizim; şablonun sekiz kutusuna.",
        hedef="data/assets/map/rider/atli_*.png", kaynak=KAYNAK_RENDER, tuval="2048x1024",
        oncelik=3, saat=4.0, sablon_tip="rider",
    ))
    return rows


_PROP_TR = {
    "backpack": "Sırt çantası", "barrels_mv": "Fıçılar", "bonfire": "Kamp ateşi (odun yığını)",
    "city_gate": "Şehir kapısı (hub)", "covered_wagon": "Brandalı vagon", "crate": "Sandık",
    "crate_mv": "Küçük sandık", "half_cart": "Eşek arabası", "hay": "Saman", "house_1": "Ev 1",
    "house_2": "Ev 2", "market_cart": "Pazar arabası", "mill_wooden": "Su değirmeni",
    "mine": "Maden girişi", "outpost": "Karakol", "palisade_gate": "Kazık çit kapısı",
    "saddlebag": "Heybe", "sawmill": "Hızar", "signpost": "Yol tabelası", "tent": "Çadır",
    "torch": "Meşale", "weapon_axe_small": "Balta (satır)", "weapon_hammer": "Gürz",
    "weapon_shield_round": "Yuvarlak kalkan", "weapon_spear": "Mızrak",
    "weapon_sword_2": "Kılıç", "well": "Kuyu", "windmill": "Yel değirmeni",
}
_LAYER_TR = {"body": "govde", "gate": "kapi_kanadi", "canopy": "branda", "load": "yuk",
             "wheel": "teker_arka", "wheel_front": "teker_on", "blades": "kanatlar", "town": "kasaba"}


def _props_sheet() -> dict:
    text = (A / "props" / "props.tres").read_text(encoding="utf-8")
    m = re.search(r"props = (\{.*\})\s*$", text, re.S | re.M)
    return json.loads(m.group(1))


def props() -> list[dict]:
    sheet = _props_sheet()
    rows = []
    for pid in sorted(sheet):
        if pid.startswith("iso_") or not (A / "props" / pid).is_dir():
            continue
        layers = list(sheet[pid]["layers"])
        if pid.startswith("gate_"):
            continue
        weapon = pid.startswith("weapon_")
        rows.append(_row(
            id="ESY-%s" % pid, kategori="Eşya", alt_grup="Silah" if weapon else "Eşya / yapı",
            ad=_PROP_TR.get(pid, pid),
            ne_cizilecek=("Dik, sap altta (oyun sapın ucundan uca gerer)." if weapon else
                          "Yandan; hareket eden parça kendi katmanında (teker döner, branda salınır, kanat döner)."),
            hedef="data/assets/props/%s/*.png" % pid, kaynak=KAYNAK_RENDER,
            tuval="şablonda", katmanlar=[_LAYER_TR.get(l, l) for l in layers],
            oncelik=2 if pid in ("covered_wagon", "half_cart", "bonfire", "weapon_sword_2") else 3,
            saat=3.0 if len(layers) > 1 else 1.5, sablon_tip="prop", kaynak_dosya=pid,
        ))
    for rid, ad, note in (
        ("ESY-yay", "Yay (kirişli)", "Kiriş çekilebilir: yay gövdesi ve kiriş ayrı katman."),
        ("ESY-asa", "Asa", "Büyücü ve hacı asası."),
        ("ESY-hancer", "Hançer", "Kılıç yanında kısa bıçak; saplanan bıçak çizimi de bundan."),
        ("ESY-ok", "Ok (saplanan)", "Bedende saplı kalan ok: tüy ve şaft."),
        ("ESY-fener", "Fener (elde)", "Liderin feneri; ışık oyunda çiziliyor, yalnızca fener."),
    ):
        rows.append(_row(
            id=rid, kategori="Eşya", alt_grup="Silah" if rid != "ESY-fener" else "Eşya / yapı", ad=ad,
            ne_cizilecek=note, hedef="(yeni) data/assets/props/<kimlik>/body.png", kaynak=KAYNAK_PROC,
            tuval="1024x2048", katmanlar=["govde", "kiris"] if rid == "ESY-yay" else ["cizim"],
            oncelik=3, saat=1.5, sablon_tip="blank", kod_gerekir=True,
        ))
    for pid in sorted(sheet):
        if not pid.startswith("gate_") or not (A / "props" / pid).is_dir():
            continue
        sid = pid.removeprefix("gate_")
        rows.append(_row(
            id="KAP-%s" % sid, kategori="Yerleşim", alt_grup="Yol kapısı", ad="%s kapısı" % sid.capitalize(),
            ne_cizilecek="Yolun iki ucundaki kapı: sur (govde) ve arkasındaki kasaba (kasaba). "
                         "Kapı açıklığı şablondaki çerçevede kalmalı (vagon sığsın).",
            hedef="data/assets/props/%s/*.png" % pid, kaynak=KAYNAK_RENDER, tuval="şablonda",
            katmanlar=[_LAYER_TR.get(l, l) for l in sheet[pid]["layers"]], oncelik=3, saat=5.0,
            sablon_tip="prop", kaynak_dosya=pid,
        ))
    return rows


_PHASES = [("gunduz", "background_day.jpg", "Gündüz", 10.0, 2), ("sabah", "background_morning.jpg", "Sabah", 3.0, 3),
           ("aksam", "background_evening.jpg", "Akşam", 3.0, 3), ("gece", "background.jpg", "Gece", 3.0, 3)]


def towns() -> list[dict]:
    rows = []
    settle = json.loads((ROOT / "data" / "config" / "settlements.json").read_text(encoding="utf-8"))
    ids = sorted(s["id"] for s in (settle["settlements"] if isinstance(settle, dict) and "settlements" in settle else settle))
    for sid in ids:
        for key, fname, label, hours, prio in _PHASES:
            rows.append(_row(
                id="KSB-%s-%s" % (sid, key), kategori="Yerleşim", alt_grup="Kasaba resmi",
                ad="%s - %s" % (sid.capitalize(), label),
                ne_cizilecek=("Kasabanın önden resmi. Binaların dış hatları şablonda kalsın: "
                              "tıklama maskesi (pazar, han, lonca...) bu hatlara bağlı." if key == "gunduz" else
                              "Gündüz çiziminin çizgileri, bu saatin ışığıyla yeniden renk. "
                              "Çizilmezse gündüzden ışık ayarıyla türetilir."),
                hedef="data/assets/ui/towns/%s/%s" % (sid, fname), kaynak=KAYNAK_RENDER,
                tuval="3840x2160", katmanlar=["cizim"], oncelik=prio, saat=hours,
                sablon_tip="image", kaynak_dosya="ui/towns/%s/%s" % (sid, fname),
                bagimlilik="" if key == "gunduz" else "KSB-%s-gunduz" % sid,
            ))
    for rid, path, ad in (("KSB-han_ici", "ui/towns/tavern/background.jpg", "Han içi"),
                          ("KSB-mezarlik_sakin", "ui/towns/graveyard_calm/background.jpg", "Mezarlık (sakin)"),
                          ("KSB-mezarlik_nobet", "ui/towns/graveyard_vigil/background.jpg", "Mezarlık (nöbet)")):
        rows.append(_row(
            id=rid, kategori="Yerleşim", alt_grup="İç mekân", ad=ad,
            ne_cizilecek="Tam ekran sahne; tıklanan yerler şablondaki hatlarda kalsın.",
            hedef="data/assets/" + path, kaynak=KAYNAK_RENDER, tuval="3840x2160", oncelik=3,
            saat=8.0, sablon_tip="image", kaynak_dosya=path,
        ))
    return rows


_BIOME_TR = {"forest": "Orman", "lake": "Göl", "marsh": "Bataklık", "meadow": "Çayır",
             "mountain": "Dağ", "steppe": "Bozkır"}
_LOOK_TR = {"cold": "soğuk (kuzey)", "warm": "sıcak (güney)", "peaks": "ufukta dağ"}
_STRIP_TR = {"far": ("uzak", "Puslu uzak sırtlar"), "mid": ("orta", "Ağaç hattı, diz boyu ot"),
             "ground": ("zemin", "Yolun kendisi ve kenarı"), "fore": ("on", "Kameraya yakın koyu ot tarlası")}


def road() -> list[dict]:
    rows = []
    for look in sorted(os.listdir(A / "ui" / "road")):
        parts = look.split("_")
        name = _BIOME_TR[parts[0]] + "".join(" - " + _LOOK_TR[p] for p in parts[1:])
        for layer in ("far", "mid", "ground", "fore"):
            src = A / "ui" / "road" / look / ("%s.png" % layer)
            if not src.exists():
                continue
            w, h = _size(src)
            tr_layer, what = _STRIP_TR[layer]
            rows.append(_row(
                id="YOL-%s-%s" % (look, tr_layer), kategori="Yol", alt_grup=_BIOME_TR[parts[0]],
                ad="%s / %s" % (name, tr_layer), ne_cizilecek=what + ". Sol kenar sağ kenara bağlanır (döşenir).",
                hedef="data/assets/ui/road/%s/%s.png" % (look, layer), kaynak=KAYNAK_RENDER,
                tuval="%dx%d" % (w * 2, h * 2), oncelik=2 if len(parts) == 1 else 3,
                saat=4.0 if len(parts) == 1 else 2.5, sablon_tip="strip",
                kaynak_dosya="ui/road/%s/%s.png" % (look, layer),
                bagimlilik="" if len(parts) == 1 else "YOL-%s-%s" % (parts[0], tr_layer),
            ))
    return rows


def world_map() -> list[dict]:
    rows = []
    for r in range(4):
        for c in range(4):
            rows.append(_row(
                id="HRT-%d%d" % (r, c), kategori="Harita", alt_grup="Dünya haritası",
                ad="Harita paftası satır %d sütun %d" % (r + 1, c + 1),
                ne_cizilecek="Haritanın 16 paftasından biri. Kıyı, dağ, yol ve yerleşim yerleri şablondaki yerinde "
                             "kalsın; oyunun yol ağı bu koordinatlara bağlı. Kenarlar komşu paftayla birleşir.",
                hedef="data/assets/map/tiles/*", kaynak="Prosedürel harita hattı (tools/worldmap)",
                tuval="2048x2048", oncelik=3, saat=6.0, sablon_tip="map", kaynak_dosya="%d,%d" % (r, c),
            ))
    return rows


_WAYBOOK_GROUPS = [
    (r"^b\d", "Arka plan (ekran)", 2752, 6.0, 1),
    (r"^e6", "Olay illüstrasyonu", 1800, 5.0, 1),
    (r"^item_", "Mal ikonu", 1024, 0.75, 1),
    (r"^eq_", "Ekipman ikonu", 1024, 0.75, 1),
    (r"^p3_", "Stat ikonu", 1024, 0.75, 1),
    (r"^p5_", "Görev ikonu", 1024, 0.75, 1),
    (r"^k6", "Sınıf ikonu", 1024, 0.75, 1),
    (r"^k4", "Durum ikonu (savaş)", 1024, 0.5, 1),
    (r"^k7", "Alan ikonu (savaş)", 1024, 0.5, 1),
    (r"^p[24]", "Huy / yara ikonu", 1024, 0.75, 1),
    (r"^r[678]", "Yol ikonu", 1024, 0.5, 1),
    (r"", "Defter parçası", 0, 1.5, 1),
]


def waybook() -> list[dict]:
    rows = []
    titles = _tr_titles()
    skip = {"b6_map.png"}
    for f in sorted(os.listdir(A / "ui" / "waybook")):
        if f in skip or not f.endswith((".png", ".jpg")):
            continue
        stem = f.rsplit(".", 1)[0]
        for pat, group, longest, hours, prio in _WAYBOOK_GROUPS:
            if re.match(pat, stem):
                break
        w, h = _size(A / "ui" / "waybook" / f)
        if not longest:
            longest = max(1024, max(w, h) * 2) if max(w, h) <= 1024 else max(w, h) * 2
        name = _waybook_name(stem, titles)
        rows.append(_row(
            id="ARY-%s" % stem, kategori="Arayüz" if not stem.startswith("e6") else "Olay",
            alt_grup=group, ad=name,
            ne_cizilecek="Mevcut resmin kendi yorumun; boyut ve oran aynı. "
                         + ("Saydam zemin." if f.endswith(".png") else "Tam kare, zemin dahil."),
            hedef="data/assets/ui/waybook/" + f, kaynak=KAYNAK_AI, tuval=_canvas_for(w, h, longest),
            oncelik=prio, saat=hours, sablon_tip="image", kaynak_dosya="ui/waybook/" + f,
        ))
    return rows


def _waybook_name(stem: str, titles: dict) -> str:
    if stem.startswith("item_"):
        return "Mal: " + titles.get("ITEM_" + stem[5:].upper(), stem[5:])
    if stem.startswith("eq_"):
        return "Ekipman: " + titles.get("EQUIP_" + stem[3:].upper(), stem[3:].replace("_", " "))
    return stem


def events() -> list[dict]:
    """Haritalanmamış her yol olayı için yeni bir illüstrasyon (kart boş kalmasın)."""
    titles = _tr_titles()
    src = (ROOT / "scripts" / "events" / "event_catalog.gd").read_text(encoding="utf-8")
    found = re.findall(r'_event\(\s*"(evt_[a-z0-9_]+)",\s*"([A-Z0-9_]+)"', src)
    journey = (ROOT / "scripts" / "ui" / "road_journey.gd").read_text(encoding="utf-8")
    block = journey.split("const EVENT_CARD_ART", 1)[1].split("}", 1)[0]
    mapped = set(re.findall(r'"(evt_[a-z0-9_]+)"', block))
    rows = []
    for eid, tkey in found:
        if eid in mapped or eid.startswith("evt_test"):
            continue
        rows.append(_row(
            id="OLY-%s" % eid.removeprefix("evt_"), kategori="Olay", alt_grup="Olay illüstrasyonu (yeni)",
            ad=titles.get(tkey, eid), ne_cizilecek="Olay kartının resmi: kartın başlığındaki anı.",
            hedef="(yeni) data/assets/ui/waybook/e7_%s.jpg" % eid.removeprefix("evt_"), kaynak=KAYNAK_YOK,
            tuval="1800x1800", oncelik=3, saat=5.0, sablon_tip="blank_square",
            kod_gerekir=True,
        ))
        rows[-1]["not"] = "Bugün bu kart resimsiz ya da başka kartın resmini kullanıyor."
    return rows


def small_art() -> list[dict]:
    rows = []
    groups = [
        ("ui/gauges", "Gösterge", "Durum sekmesi madalyonları", KAYNAK_AI, 1024, 1.0, 1),
        ("ui/kit", "Arayüz", "Arayüz kiti", KAYNAK_CC0, 0, 1.0, 3),
        ("ui/grim/kit", "Arayüz", "Şehir ekranı kiti", KAYNAK_AI, 0, 1.0, 1),
        ("ui/cursor", "Arayüz", "İmleç", KAYNAK_PROC, 512, 0.3, 3),
        ("ui/market_scale", "Arayüz", "Pazar terazisi", KAYNAK_RENDER, 0, 1.0, 3),
        ("fx", "Efekt", "Parçacık", KAYNAK_CC0, 512, 0.3, 3),
    ]
    for rel, cat, group, src, longest, hours, prio in groups:
        for f in sorted(os.listdir(A / rel)):
            if not f.endswith(".png"):
                continue
            w, h = _size(A / rel / f)
            big = longest or (1024 if max(w, h) <= 256 else max(w, h) * 2)
            stem = f[:-4]
            rows.append(_row(
                id="%s-%s" % ({"Gösterge": "GST", "Efekt": "EFX"}.get(cat, "ARY"), stem if rel != "ui/kit" else "kit_" + stem),
                kategori=cat, alt_grup=group, ad=stem.replace("_", " "),
                ne_cizilecek="Mevcut parçanın kendi yorumun; oran ve saydam kenarlar aynı.",
                hedef="data/assets/%s/%s" % (rel, f), kaynak=src, tuval=_canvas_for(w, h, big),
                oncelik=prio, saat=hours, sablon_tip="image", kaynak_dosya="%s/%s" % (rel, f),
            ))
    for f, ad in (("ash_flake.png", "Kül tanesi"), ("ink_blot.png", "Mürekkep lekesi (menü)")):
        w, h = _size(A / "ui" / "grim" / f)
        rows.append(_row(
            id="ARY-%s" % f[:-4], kategori="Arayüz", alt_grup="Şehir ekranı kiti", ad=ad,
            ne_cizilecek="Mevcut parçanın kendi yorumun.", hedef="data/assets/ui/grim/" + f,
            kaynak=KAYNAK_PROC, tuval=_canvas_for(w, h, max(512, max(w, h) * 2)), oncelik=3, saat=0.5,
            sablon_tip="image", kaynak_dosya="ui/grim/" + f,
        ))
    return rows


# Kodla çizilen, ama elle çizilmiş bir parçası olması gereken her şey. Her
# satır teslim edildiğinde koda bağlanması gerekir (kod_gerekir).
_NEW = [
    ("SAH-agac_yaprakli", "Sahne", "Ağaç", "Yapraklı ağaç (3 çeşit)", "Üç farklı boy ve gövde; yer gölgesi oyunda.", "1024x2048", ["agac_1", "agac_2", "agac_3"], 4.0),
    ("SAH-agac_ladin", "Sahne", "Ağaç", "Ladin / iğne yapraklı (3 çeşit)", "Kuzey ve dağ için.", "1024x2048", ["agac_1", "agac_2", "agac_3"], 4.0),
    ("SAH-agac_kuru", "Sahne", "Ağaç", "Kuru / çıplak ağaç (2 çeşit)", "Kış ve bozkır için.", "1024x2048", ["agac_1", "agac_2"], 2.5),
    ("SAH-cali", "Sahne", "Bitki", "Çalı (4 çeşit)", "Yol kenarı ve ön plan.", "2048x1024", ["cali_1", "cali_2", "cali_3", "cali_4"], 3.0),
    ("SAH-ot_tutami", "Sahne", "Bitki", "Ot tutamı (6 çeşit)", "En küçük parça: yol kenarı otları, kuru ve yeşil.", "2048x1024", ["ot_1", "ot_2", "ot_3", "ot_4", "ot_5", "ot_6"], 2.0),
    ("SAH-cicek", "Sahne", "Bitki", "Kır çiçekleri (4 çeşit)", "Çayır ve yaz.", "2048x1024", ["cicek_1", "cicek_2", "cicek_3", "cicek_4"], 1.5),
    ("SAH-sazlik", "Sahne", "Bitki", "Sazlık", "Bataklık ve göl kıyısı.", "2048x1024", ["cizim"], 1.0),
    ("SAH-kaya", "Sahne", "Taş", "Kaya (4 çeşit)", "Büyük kayalar, uzak tarafta.", "2048x1024", ["kaya_1", "kaya_2", "kaya_3", "kaya_4"], 3.0),
    ("SAH-tas", "Sahne", "Taş", "Küçük taşlar (6 çeşit)", "Yolun altındaki ön plan taşları.", "2048x1024", ["tas_1", "tas_2", "tas_3", "tas_4", "tas_5", "tas_6"], 1.5),
    ("SAH-camur_su", "Sahne", "Zemin izi", "Çamur ve su birikintisi (4 çeşit)", "Zemine boyanan düz izler.", "2048x1024", ["camur_1", "camur_2", "su_1", "su_2"], 1.5),
    ("SAH-bulut", "Gökyüzü", "Gökyüzü", "Bulut (5 çeşit)", "Yumuşak kenarlı; ışığı oyun veriyor, gri çiz.", "2048x1024", ["bulut_1", "bulut_2", "bulut_3", "bulut_4", "bulut_5"], 2.5),
    ("SAH-gunes_ay", "Gökyüzü", "Gökyüzü", "Güneş, ay (evreleri), yıldız", "Hale oyunda; yalnızca disk ve ay yüzü.", "2048x1024", ["gunes", "ay_dolunay", "ay_yarim", "ay_hilal", "yildiz"], 2.0),
    ("SAH-yagmur_kar", "Gökyüzü", "Hava", "Yağmur damlası, kar tanesi, sis tülü", "Parçacık olarak tekrarlanır.", "1024x1024", ["yagmur", "kar", "sis"], 1.0),
    ("SAH-mezar", "Sahne", "Yol hafızası", "Mezar işaretleri (4 rütbe)", "Kurucu, lider, yoldaş, mürettebat; dini simge yok. Yolda ve Düşenler sayfasında.", "2048x1024", ["kurucu", "lider", "yoldas", "murettebat"], 3.0),
    ("SAH-hoyuk", "Sahne", "Yol hafızası", "Taş höyüğü (lider)", "Düşen liderin yolda kalan taş yığını.", "1024x1024", ["cizim"], 1.0),
    ("SAH-enkaz", "Sahne", "Yol hafızası", "Vagon enkazı", "Kaybedilen vagonun yolda kalanı.", "2048x1024", ["cizim"], 1.5),
    ("SAH-kul", "Sahne", "Yol hafızası", "Kamp külü", "Söndürülmüş ateş yeri.", "1024x512", ["cizim"], 0.5),
    ("SAH-mil_tasi", "Sahne", "Yol kenarı", "Kilometre taşı", "Yol boyunca gün işaretleri.", "512x1024", ["cizim"], 0.5),
    ("SAH-durak_mezra", "Sahne", "Yol durağı", "Mezra (yol kenarı köyü)", "Yol durağı uzakta görünür.", "2048x1024", ["cizim"], 2.5),
    ("SAH-durak_gecit", "Sahne", "Yol durağı", "Dağ geçidi", "", "2048x1024", ["cizim"], 2.5),
    ("SAH-durak_sunak", "Sahne", "Yol durağı", "Yol kenarı sunağı", "Dini simge yok: taş, bez, adak.", "1024x1024", ["cizim"], 1.5),
    ("SAH-durak_kopru", "Sahne", "Yol durağı", "Köprü", "", "2048x1024", ["cizim"], 2.5),
    ("SAH-durak_sig_gecit", "Sahne", "Yol durağı", "Sığ geçit (nehir)", "Su seviyesi oyunda.", "2048x1024", ["cizim"], 2.0),
    ("SAH-uzak_sehir", "Sahne", "Ufuk", "Uzak şehir silueti (3 çeşit)", "Sur, kapı, ambar; farklı yükseklikte bloklar. Kubbe ve minare yok.", "2048x1024", ["sehir_1", "sehir_2", "sehir_3"], 3.0),
    ("SAH-ates", "Efekt", "Ateş", "Kamp ateşi alevi (6 kare)", "Odun yığını ESY-bonfire; bu yalnızca alev.", "2048x1024", ["kare_1", "kare_2", "kare_3", "kare_4", "kare_5", "kare_6"], 3.0),
    ("SAH-tug", "Sahne", "Göçebe", "Tuğ sancağı", "Göçebe obasının girişi.", "512x2048", ["cizim"], 1.0),
    ("SAH-karsilasma_isaret", "Sahne", "Yol", "Yol karşılaşması işareti", "Uzaktan görünen yolcu/haydut/devriye siluetleri (4).", "2048x1024", ["yolcu", "haydut", "devriye", "hayvan"], 2.0),
    ("ARY-logo", "Arayüz", "Kimlik", "Oyun logosu (WAYBORNE)", "Başlık ekranı ve mağaza.", "2048x1024", ["cizim"], 4.0),
    ("ARY-isaretler", "Arayüz", "Küçük işaret", "Nokta, ok, onay, artı/eksi", "Bugün ArtDraw.pip/chevron/check; elle çizilmiş hâli.", "1024x1024", ["nokta_dolu", "nokta_bos", "ok", "onay", "arti", "eksi"], 1.0),
    ("ARY-mal_kontrabant_tuz", "Arayüz", "Mal ikonu", "Mal: Mühürsüz tuz", "", "1024x1024", ["cizim"], 0.75),
    ("ARY-mal_emanet", "Arayüz", "Mal ikonu", "Mal: Emanet yük (kontrat)", "", "1024x1024", ["cizim"], 0.75),
    ("ARY-mal_fener", "Arayüz", "Mal ikonu", "Mal: Fener", "", "1024x1024", ["cizim"], 0.75),
    ("ARY-mal_fener_yagi", "Arayüz", "Mal ikonu", "Mal: Fener yağı", "", "1024x1024", ["cizim"], 0.75),
    ("ARY-mal_mesale", "Arayüz", "Mal ikonu", "Mal: Meşale", "", "1024x1024", ["cizim"], 0.75),
    ("ARY-mal_eski_muhur", "Arayüz", "Mal ikonu", "Mal: Eski mühür", "", "1024x1024", ["cizim"], 0.75),
]


def new_art() -> list[dict]:
    rows = []
    for rid, cat, group, ad, note, canvas, layers, hours in _NEW:
        rows.append(_row(
            id=rid, kategori=cat, alt_grup=group, ad=ad, ne_cizilecek=note or "Yeni parça.",
            hedef="(yeni)", kaynak=KAYNAK_PROC if not rid.startswith("ARY-mal") else KAYNAK_YOK,
            renk=GRI if rid in ("SAH-bulut",) else RENK, tuval=canvas, katmanlar=layers, oncelik=3,
            saat=hours, sablon_tip="blank", kod_gerekir=True,
        ))
        if len(layers) > 1:
            rows[-1]["not"] = "Her çeşit kendi katmanında; şablondaki kutuya bir tane."
    return rows


def all_rows() -> list[dict]:
    rows = figures() + beasts() + props() + towns() + road() + world_map() + waybook() + events() + small_art() + new_art()
    seen = set()
    for r in rows:
        assert r["id"] not in seen, r["id"]
        seen.add(r["id"])
    return rows


ORDER = ["Figür", "Hayvan", "Eşya", "Yerleşim", "Yol", "Harita", "Arayüz", "Gösterge", "Olay", "Sahne",
         "Gökyüzü", "Efekt"]


if __name__ == "__main__":
    rows = all_rows()
    from collections import Counter
    c = Counter(r["kategori"] for r in rows)
    for k in ORDER:
        print("%-10s %4d" % (k, c.get(k, 0)))
    print("toplam", len(rows), "satır,", round(sum(r["saat"] for r in rows)), "saat (tahmin)")
    print("AI kaynaklı:", sum(1 for r in rows if r["kaynak"] == KAYNAK_AI))
