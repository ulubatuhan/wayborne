#!/usr/bin/env python3
"""Lore soru defteri (III): harita v3 üstüne kurulmuş, cevapları saklayan tek sayfa.

Defter I bölge sorularıyla, defter II onaylarla cevaplandı. Defter III'te soruların çoğunu Claude cevapladı
(kullanıcı isteği, 2026-10-30): yeni bağlar, 27 yerleşimin taslağı, kalan sorulara öneriler ve çelişkiler.
İçerik `lore_defter3_banka.py`'de; `--md` aynı içeriği `docs/lore/ONERILER_III.md`'ye de yazar.

Kullanıcının kalan lore ve tarihçeyi yazması için soruları haritadaki gerçek bölgelere,
27 yerleşime ve atlasın adı konmuş yerlerine bağlar. Harita karoları (zoom 1), şehir önü
resimleri (gündüz) ve `settlements.json` ile `places_v3.json` sayfaya gömülür; cevaplar
sayfanın `db` deposuna (`answers/<soru kimliği>`) yazılır, Claude oradan okur.

    python3 -I tools/lore_soru_sayfasi.py <çıktı.html> [--md]
"""
import base64
import io
import json
import math
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP_W = 16012.0
MAP_PX = 1700          # gömülen harita genişliği
THUMB = (360, 203)     # şehir önü küçük resmi

# places_v3 (4096 ölçeği) -> settlements.json (16012): en küçük karelerle ölçüldü, hata 0.
def place_to_map(x, y):
    return 4.0 * x - 186.0, 4.0 * y - 165.0

REGION_K = 1.04 * 2.048   # tools/worldmap/atlas/names/regions.py: ekran -> atlas

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lore_defter3_banka as B  # noqa: E402  (defterin içeriği; tek kaynak)

REGIONS = B.REGIONS
TYPE_LABEL = {"ic_city": "Şehir", "ic_freecity": "Serbest şehir", "ic_portcity": "Liman şehri",
              "it_town": "Kasaba", "it_swamptown": "Bataklık kasabası", "it_minetown": "Maden kasabası",
              "it_rivertown": "Nehir kasabası", "it_markettown": "Pazar kasabası",
              "ik_caravanserai": "Kervansaray"}
WALL_LABEL = {"stone": "taş sur", "wood": "kütük sur", "felt": "sur yok, keçe yurtlar"}
GOODS = {"test_grain": "buğday", "test_cloth": "kumaş", "test_weapon": "demir", "test_potion": "iksir",
         "test_furs": "kürk", "spice": "baharat", "honey": "bal", "silk": "ipek", "jewelry": "mücevher",
         "fish": "balık", "wine": "şarap"}
PLACE_KIND = {"ia_abbey": "Manastır", "ir_ruins": "Harabe", "is_stones": "Dikili taşlar", "ib_battle": "Savaş alanı",
              "ig_gallows": "Darağacı", "ig_graveyard": "Mezarlık", "iw_tower": "Gözcü kulesi",
              "ip_lighthouse": "Fener", "ix_wreck": "Batık", "ix_mountaintribe": "Dağ kabilesi",
              "in_yurtcamp": "Oba", "ie_deepmine": "Derin maden", "ie_saltmine": "Tuzla",
              "iv_fishvillage": "Balıkçı köyü", "iv_farm": "Çiftlik", "ih_mezra": "Mezra", "il_lumber": "Kereste kampı"}


def load_regions():
    src = open(os.path.join(ROOT, "tools/worldmap/atlas/names/regions.py"), encoding="utf-8").read()
    ns = {"math": math}
    exec(src.split("def inside")[0].replace("import json\nimport math\n", ""), ns)
    out = []
    for key, poly in ns["REG"].items():
        pts = []
        for sx, sy in poly:
            mx, my = place_to_map(sx * REGION_K, sy * REGION_K)
            pts.append([round(mx / MAP_W, 4), round(my / MAP_W, 4)])
        out.append({"key": B.POLY_REGION[key], "pts": pts})
    return out


def b64(img, fmt="JPEG", q=78):
    buf = io.BytesIO()
    img.save(buf, fmt, quality=q, optimize=True, progressive=True)
    return base64.b64encode(buf.getvalue()).decode()


def map_image():
    full = Image.new("RGB", (2048, 2048))
    for x in range(2):
        for y in range(2):
            full.paste(Image.open(os.path.join(ROOT, f"data/assets/map/tiles/1/{x}_{y}.jpg")), (x * 1024, y * 1024))
    side = round(2048 * MAP_W / 16384.0)
    return full.crop((0, 0, side, side)).resize((MAP_PX, MAP_PX), Image.LANCZOS)


def town_thumb(sid):
    p = os.path.join(ROOT, "data/assets/ui/towns", sid, "background_day.jpg")
    if not os.path.exists(p):
        return None
    im = Image.open(p).convert("RGB")
    w, h = im.size
    tw, th = THUMB
    s = max(tw / w, th / h)
    im = im.resize((round(w * s), round(h * s)), Image.LANCZOS)
    left = (im.width - tw) // 2
    return b64(im.crop((left, (im.height - th) // 2, left + tw, (im.height - th) // 2 + th)), q=70)


# ---------------------------------------------------------------- defter III

ONAY = ["Onaylıyorum", "Düzeltilmeli", "Reddediyorum"]


def q(qid, text, hint="", choices=None, at=None, prio=False, draft="", draft_label=""):
    d = {"id": qid, "t": text}
    if hint:
        d["h"] = hint
    if choices:
        d["c"] = choices
    if at:
        d["at"] = at
    if prio:
        d["p"] = 1
    if draft:
        d["d"] = draft
    if draft_label:
        d["dl"] = draft_label
    return d


def place_at(places, name, zoom=3.2):
    for p in places:
        if p["d"] == name:
            mx, my = place_to_map(p["x"], p["y"])
            return [round(mx / MAP_W, 4), round(my / MAP_W, 4), zoom]
    return None


def settlement_region(s, polys):
    """Yerleşimin harita parçası: içindeyse o, değilse en yakını (regions.py region_of kuralı)."""
    x, y = s["pos"][0] / MAP_W, s["pos"][1] / MAP_W

    def inside(poly):
        c = False
        for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
            if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
                c = not c
        return c

    def dist(poly):
        best = 9.0
        for (ax, ay), (bx, by) in zip(poly, poly[1:] + poly[:1]):
            dx, dy = bx - ax, by - ay
            t = max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy + 1e-12)))
            best = min(best, math.hypot(x - ax - t * dx, y - ay - t * dy))
        return best

    hits = [p["key"] for p in polys if inside(p["pts"])]
    if hits:
        return hits[0]
    return min(polys, key=lambda p: dist(p["pts"]))["key"]


def _at(ref, places, regions):
    if not ref:
        return None
    kind, _, name = ref.partition(":")
    return place_at(places, name or kind, 3.0) if kind != "region" else None


def build_questions(settlements, places):
    secs = []

    items = []
    for key, title, rows in B.NEW_LINKS:
        qs = [q(f"onay.{no.lower()}", f"{no} · {t}", choices=ONAY, draft=d, draft_label="Önerim",
                at=_at(ref, places, None)) for no, t, d, ref in rows]
        items.append({"kind": "plain", "key": key, "title": title, "qs": qs})
    secs.append({"id": "onay", "title": "Yeni bağlar",
                 "lead": "Cevaplarından ve düzeltmelerinden sonra kurduğum yeni bağlar: bölge adları, mezhep düzeltmesinin sonuçları, haritadaki yerler. Onaylanan kanona geçer; düzeltme yazarsan ona göre değiştiririm.",
                 "items": items})

    con = [q(qid, t, choices=c, draft=d, draft_label="Durum ve önerim", prio=pr) for qid, t, d, c, *rest in B.CONFLICTS
           for pr in [bool(rest and rest[0])]]
    secs.append({"id": "celiskiler", "title": "Çelişkiler", "lead": "İki kaynağın tutmadığı yerler. Her birinde önerim var; seçenek işaretlemek yeter.",
                 "items": [{"kind": "plain", "key": "celiskiler", "title": "Karar bekleyenler", "qs": con}]})

    items = []
    for s in sorted(settlements, key=lambda s: (B.REGION_ORDER.index(s["lregion"]), s["pos"][1])):
        sid = s["id"]
        kimlik, tur, gelenek, kitlik = B.SETTLEMENTS[sid]
        draft = f"Kimlik: {kimlik}\n{tur}\nGelenek: {gelenek}\nKıtlık: {kitlik}"
        items.append({"kind": "settlement", "key": sid, "title": s["proper_name"],
                      "qs": [q(f"yer3.{sid}", "Bu yerleşim için yazdığım lore", choices=ONAY, draft=draft,
                               draft_label="Önerim (eldeki bilgiden)")]})
    secs.append({"id": "yerlesimler", "title": "Yerleşimler", "lead": "27 yerleşimin her biri için senin bölge cevaplarına, onaylı bağlara ve oyundaki verisine (tür, sur, ürettiği ve istediği mal) dayanarak yazdığım taslak. Onaylarsan LORE.md'ye geçer.", "items": items})

    for key, (title, rows) in B.ANSWERS.items():
        qs = []
        for row in rows:
            qid, t, d = row[0], row[1], row[2]
            c = row[3] if len(row) > 3 else None
            ref = row[4] if len(row) > 4 else None
            pr = len(row) > 5 and row[5]
            qs.append(q(qid, t, choices=ONAY if c in (None, "ONAY") else c, draft=d, draft_label="Önerim",
                        at=place_at(places, ref, 3.0) if ref else None, prio=pr))
        secs.append({"id": key, "title": title.split(":")[0], "lead": title,
                     "items": [{"kind": "plain", "key": key, "title": title, "qs": qs}]})
    return secs


TITLE = "Sideria Soru Defteri III"
LEDE = ("İkinci defterdeki onay ve düzeltmelerin işlendi; mezhepler senin anlattığın gibi düzeldi (Septisizm ve Yumruk). "
        "Haritadaki her parça artık kendi bölgesi. Bu defterde soruların çoğunu ben cevapladım: yeşil kutu önerim, "
        "Onaylıyorum, Düzeltilmeli ya da Reddediyorum de, düzeltmeni yaz. Kırmızı 'öncelikli' olanlar başka işlerin önünü açıyor.")


def write_markdown(settlements, out_md):
    """ONERILER_III.md: defterdeki bütün önerilerin repo içindeki kopyası (onaylananlar LORE.md'ye taşınır)."""
    L = ["# Defter III önerileri", "",
         "`tools/lore_defter3_banka.py`'den üretilir (`python3 -I tools/lore_soru_sayfasi.py <html> --md`); elle düzenleme.",
         "Hepsi **[Türetme]**, kullanıcı onayı bekliyor. Onaylanan LORE.md'ye [Yazar, onaylandı] olarak geçer.", ""]
    L += ["## Yeni bağlar", ""]
    for _, title, rows in B.NEW_LINKS:
        L += [f"### {title}", ""]
        for no, t, d, _ in rows:
            L += [f"- **{no} · {t}.** " + d.replace("\n", " "), ""]
    L += ["## Çelişkiler", ""]
    for qid, t, d, c, *_ in B.CONFLICTS:
        L += [f"- **{t}.** " + d.replace("\n", " ") + f" Seçenekler: {' / '.join(c)}.", ""]
    L += ["## Yerleşimler", ""]
    by_id = {s["id"]: s for s in settlements}
    for reg in B.REGION_ORDER:
        rows = [s for s in settlements if s["lregion"] == reg]
        if not rows:
            continue
        L += [f"### {B.REGIONS[reg]}", ""]
        for s in sorted(rows, key=lambda s: s["pos"][1]):
            k, t, g, ki = B.SETTLEMENTS[s["id"]]
            L += [f"**{s['proper_name']}.** {k}", "", f"- {t}", f"- Gelenek: {g}", f"- Kıtlık: {ki}", ""]
    for key, (title, rows) in B.ANSWERS.items():
        L += [f"## {title}", ""]
        for row in rows:
            L += [f"- **{row[1]}** (`{row[0]}`). " + row[2].replace("\n", " "), ""]
    open(out_md, "w", encoding="utf-8").write("\n".join(L))


def main(out):
    st = json.load(open(os.path.join(ROOT, "data/config/settlements.json"), encoding="utf-8"))
    settlements = st["settlements"]
    places = json.load(open(os.path.join(ROOT, "tools/worldmap/atlas/places_v3.json"), encoding="utf-8"))
    polys = load_regions()
    for s in settlements:
        s["lregion"] = settlement_region(s, polys)
    if "--md" in sys.argv:
        write_markdown(settlements, os.path.join(ROOT, "docs/lore/ONERILER_III.md"))
    data = {
        "regions": REGIONS,
        "polys": polys,
        "settlements": [{
            "id": s["id"], "name": s["proper_name"], "region": s["lregion"], "type": TYPE_LABEL[s["map_kind"]],
            "wall": WALL_LABEL.get(s.get("wall"), ""), "pos": [round(s["pos"][0] / MAP_W, 4), round(s["pos"][1] / MAP_W, 4)],
            "big": s["type"] == "city",
            "produces": [GOODS.get(g, g) for g in s["produces"]], "demands": [GOODS.get(g, g) for g in s["demands"]],
            "neighbours": len(s["neighbours"]),
        } for s in settlements],
        "places": [],
        "sections": build_questions(settlements, places),
        "summary": open(os.path.join(ROOT, "docs/lore/LORE_OZET.txt"), encoding="utf-8").read(),
    }
    for p in places:
        if p["k"] in PLACE_KIND and p["k"] not in ("it_town",):
            mx, my = place_to_map(p["x"], p["y"])
            data["places"].append({"n": p["d"], "k": PLACE_KIND[p["k"]], "pos": [round(mx / MAP_W, 4), round(my / MAP_W, 4)]})
    thumbs = {}
    for s in settlements:
        t = town_thumb(s["id"])
        if t:
            thumbs[s["id"]] = t
    tmpl = open(os.path.join(ROOT, "tools/lore_soru_sayfasi.html"), encoding="utf-8").read()
    html = (tmpl.replace("__TITLE__", TITLE).replace("__LEDE__", LEDE).replace("__MAP__", b64(map_image(), q=80))
            .replace("__DATA__", json.dumps(data, ensure_ascii=False))
            .replace("__THUMBS__", json.dumps(thumbs)))
    open(out, "w", encoding="utf-8").write(html)
    total = sum(len(i["qs"]) for sec in data["sections"] for i in sec["items"])
    print(out, f"{len(html) / 1e6:.2f} MB", total, "soru")


if __name__ == "__main__":
    main(sys.argv[1])
