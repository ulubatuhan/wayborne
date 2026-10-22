"""Yerleşim menüleri (görevler N12-N15): harita v3'ün 27 yerleşimine birer
kasaba sahnesi tanımı yazar (`towns.json`'a, kimliğiyle).

    python -X utf8 tools/ui_scenes/settlement_towns.py            # hepsi
    python -X utf8 tools/ui_scenes/settlement_towns.py vastrevar  # tek yer

Ardından her yer için `town_scene.py --city <kimlik>` (Blender) ve
`town_post.py <kimlik>`; resim `data/assets/ui/towns/<kimlik>/`'e düşer ve
`city_map.town_dir` onu okur.

Bir sahne beş şeyden türer, elle yerleştirme yok:
  - kültür (bölge): mimari dil, ışık, sis ve renk (Stil rehberi,
    docs/ui/STIL_REHBERI.md). Vadi bereketli ve sıcak, kuzey imparatorluğu
    koyu taş ve soğuk ışık, sınır ahşap çit, dağ kar ve kaya, güney sıcak
    kum ve tente, Ahit'in şehri büyük tapınak, göçebe çadır ve ateş;
  - haritadaki enlem: kuzeye doğru tepelerde kar, ışık soğur;
  - tür: şehir (sur, kapı, lonca, kale), kasaba (ahşap çit, lonca ve avlu
    yok, az ev), kervansaray (dört yanı duvarlı avlu, han, ahır, kilise
    yok) - mekânlar SettlementRules.FACILITIES ile aynı;
  - haritadaki alt tür (`map_kind`): liman (deniz ufku, fener, balık
    sandıkları), özgür şehir (kale yok, lonca kuleleri yüksek), maden
    kasabası (kaya, demirci), bataklık (sis, eğri ağaç), nehir (su
    değirmeni), pazar kasabası (çok tezgâh);
  - yerleşimin ürettiği mallar: fıçı (şarap, balık), saman ve değirmen
    (tahıl), çuval (kürk, ilaç), fener (mücevher), renkli tente (ipek,
    baharat).
Düzen kimlikten tohumlanır: aynı girdi aynı sahneyi verir.
"""
import json
import math
import os
import random
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SETTLEMENTS = os.path.join(ROOT, "data", "config", "settlements.json")
TOWNS = os.path.join(HERE, "towns.json")

# SettlementRules.FACILITIES ile aynı; mekân etiketi (towns.json "venue")
# ile tesis adı arasındaki eşleme CityFront.VENUES'ta.
VENUES_BY_TYPE = {
    "city": ["yard", "market", "guild", "tavern", "church", "tailor"],
    "town": ["market", "tavern", "church", "tailor"],
    "caravanserai": ["market", "tavern", "yard"],
}

# Kamera 2 m sağda: şehir ekranında sağdaki brifing sütunu ve kadro
# kartları resmin sağ üçte birini örter (CityFront); meydan, levhalarla
# brifing arasındaki görünür alanın ortasına düşsün.
# Görev 12.1: kamera bir tık geride - 24 mm yerine 20 mm (kadraj ~%20 geniş).
CAMERA = {"at": [2.0, -8.5, 2.0], "look": [2.0, 14.0, 6.2], "lens": 20}
PLAZA = [0.0, 6.0, 6.5]

# Kültür başına sahne dili. `post` town_post.py'nin boyası (0-255),
# `sky` Blender ortam ışığı. Değerler eski beş kasabanın onaylanmış
# ayarlarından türedi: kuzey Demirkapı'nın taşı ve Kurtboğazı'nın soğuğu,
# vadi İpekevi'nin altını ve Yeşilova'nın yeşili, sınır Karakonak.
CULTURES = {
    "imparatorluk": {
        "sky": {"horizon": [0.24, 0.16, 0.2], "zenith": [0.01, 0.01, 0.025], "height": 0.2, "strength": 1.0},
        "post": {"zenith": [10, 9, 16], "horizon": [86, 52, 58], "cloud": [32, 28, 38], "fog": [64, 56, 70],
                 "fog_amount": 0.4, "exposure": 1.65, "glow": 1.2, "shadow": [20, 16, 26]},
        "moon": 1.0, "moon_color": [0.62, 0.66, 0.92], "backlight": 1.6, "backlight_color": [0.9, 0.45, 0.3],
        "window": [1.0, 0.5, 0.18], "hill_tint": [0.55, 0.52, 0.56], "ground_tint": [0.58, 0.55, 0.56],
        "wall": "stone", "wall_value": 0.26, "dark_spires": True, "banners": ["ftk:banner-red"],
        "trees": ["ftk:tree-high", "ftk:tree-high-crooked"], "extra": ["Barrel", "Crate"],
    },
    "vadi": {
        "sky": {"horizon": [0.55, 0.36, 0.14], "zenith": [0.03, 0.02, 0.04], "height": 0.22, "strength": 1.1},
        "post": {"zenith": [16, 12, 22], "horizon": [138, 92, 46], "cloud": [60, 44, 42], "fog": [104, 84, 62],
                 "fog_amount": 0.34, "exposure": 1.75, "glow": 1.15, "shadow": [26, 20, 26]},
        "moon": 0.8, "backlight": 2.6, "backlight_color": [1.0, 0.58, 0.28],
        "window": [1.0, 0.56, 0.22], "hill_tint": [0.62, 0.78, 0.5], "ground_tint": None,
        "wall": "stone", "wall_value": 0.45, "dark_spires": False, "banners": ["ftk:banner-green", "ftk:banner-red"],
        # Kullanıcı (2026-10-22): vadinin kalesi ve yapıları daha yıpranmış.
        "weathered": 0.75,
        "trees": ["ftk:tree-high-round", "ftk:tree", "ftk:tree-high-crooked"],
        "extra": ["ftk:hedge-large", "ftk:hedge-large"],
    },
    "sinir": {
        "sky": {"horizon": [0.42, 0.2, 0.11], "zenith": [0.02, 0.012, 0.02], "height": 0.2, "strength": 1.0},
        "post": {"zenith": [12, 10, 18], "horizon": [92, 46, 30], "cloud": [38, 28, 34], "fog": [70, 52, 58],
                 "fog_amount": 0.36, "exposure": 1.6, "glow": 1.0, "shadow": [22, 16, 22]},
        "moon": 0.8, "backlight": 1.8, "backlight_color": [1.0, 0.5, 0.26],
        "window": [1.0, 0.5, 0.2], "hill_tint": [0.58, 0.6, 0.48], "ground_tint": [0.62, 0.56, 0.48],
        "wall": "wood", "wall_value": 0.35, "dark_spires": False, "banners": [],
        "trees": ["ftk:tree-high-crooked", "ftk:tree-crooked", "ftk:tree-high"], "extra": ["Bags", "ftk:fence"],
    },
    "dag": {
        "sky": {"horizon": [0.2, 0.24, 0.3], "zenith": [0.01, 0.012, 0.02], "height": 0.2, "strength": 1.0},
        "post": {"zenith": [8, 10, 18], "horizon": [64, 78, 96], "cloud": [36, 42, 54], "fog": [84, 94, 112],
                 "fog_amount": 0.42, "exposure": 1.6, "glow": 1.1, "shadow": [18, 22, 32]},
        "moon": 1.3, "moon_color": [0.62, 0.7, 0.95], "backlight": 1.4, "backlight_color": [0.9, 0.55, 0.35],
        "window": [1.0, 0.52, 0.2], "hill_tint": [0.75, 0.8, 0.9], "ground_tint": [0.6, 0.6, 0.64],
        "wall": "stone", "wall_value": 0.32, "dark_spires": True, "banners": [],
        "trees": ["ftk:tree-high", "ftk:tree-high"], "extra": ["ftk:rock-large", "ftk:rock-wide"],
        "mountain": True,
    },
    "guney": {
        "sky": {"horizon": [0.7, 0.3, 0.14], "zenith": [0.04, 0.015, 0.05], "height": 0.24, "strength": 1.2},
        "post": {"zenith": [22, 10, 30], "horizon": [168, 78, 46], "cloud": [74, 36, 52], "fog": [122, 70, 64],
                 "fog_amount": 0.3, "exposure": 1.75, "glow": 1.3, "shadow": [34, 18, 30]},
        "moon": 0.7, "backlight": 3.2, "backlight_color": [1.0, 0.5, 0.22],
        "window": [1.0, 0.58, 0.24], "hill_tint": [0.86, 0.72, 0.56], "ground_tint": [0.82, 0.7, 0.55],
        "wall": "stone", "wall_value": 0.55, "dark_spires": False, "banners": ["ftk:banner-red", "ftk:banner-green"],
        "trees": ["ftk:tree-high-round", "ftk:tree"], "extra": ["ftk:stall-red", "ftk:stall-green"],
        "flat_roofs": True,
    },
    "ahit": {
        "sky": {"horizon": [0.3, 0.3, 0.42], "zenith": [0.02, 0.02, 0.05], "height": 0.22, "strength": 1.1},
        "post": {"zenith": [12, 12, 26], "horizon": [104, 96, 128], "cloud": [46, 44, 62], "fog": [96, 92, 118],
                 "fog_amount": 0.38, "exposure": 1.7, "glow": 1.25, "shadow": [22, 20, 34]},
        "moon": 1.4, "moon_color": [0.7, 0.72, 0.95], "backlight": 1.8, "backlight_color": [1.0, 0.7, 0.42],
        "window": [1.0, 0.62, 0.3], "hill_tint": [0.72, 0.72, 0.8], "ground_tint": [0.72, 0.7, 0.72],
        "wall": "stone", "wall_value": 0.6, "dark_spires": False, "banners": ["ftk:banner-green"],
        "trees": ["ftk:tree-high-round", "ftk:tree-high"], "extra": ["ftk:lantern", "ftk:lantern"],
        "grand_church": True,
    },
    "gocebe": {
        "sky": {"horizon": [0.58, 0.34, 0.16], "zenith": [0.03, 0.02, 0.04], "height": 0.18, "strength": 1.1},
        "post": {"zenith": [14, 12, 22], "horizon": [146, 96, 54], "cloud": [62, 46, 44], "fog": [112, 88, 66],
                 "fog_amount": 0.3, "exposure": 1.7, "glow": 1.2, "shadow": [26, 20, 24]},
        "moon": 0.9, "backlight": 2.8, "backlight_color": [1.0, 0.55, 0.26],
        "window": [1.0, 0.55, 0.22], "hill_tint": [0.8, 0.74, 0.52], "ground_tint": [0.78, 0.7, 0.54],
        "wall": "stone", "wall_value": 0.5, "dark_spires": False, "banners": ["ftk:banner-red"],
        "trees": ["ftk:tree-crooked"], "extra": ["Bags", "Hay"], "tents": True,
    },
}
CULTURES["dag_maden"] = dict(CULTURES["dag"], extra=["ftk:rock-large", "ftk:rock-wide", "Cart"])

# Ürün -> meydana konan yük. Sahne ne sattığını söyler.
GOODS_PROPS = {
    "wine": ["Barrel", "Barrel"], "fish": ["Barrel", "Crate"], "test_grain": ["Hay", "Hay"],
    "test_furs": ["Bags"], "test_potion": ["Bags"], "honey": ["Crate"], "jewelry": ["ftk:lantern"],
    "silk": ["ftk:stall-red"], "spice": ["ftk:stall-green"], "test_cloth": ["MarketStand_2"],
    "test_weapon": ["Crate"],
}

# Mekân yuvaları (sol yarı; ayna tohumdan). Kamera (0,-8.5) -> (0,14):
# meydan önde, han ve terzi sağda, lonca ve tapınak arkada, avlu solda.
SLOTS = {
    "market": [((-4.2, 4.6), 22, "MarketStand_1"), ((-6.2, 7.2), 30, "MarketStand_2"),
               ((-2.0, 5.0), -20, "MarketStand_1"), ((1.8, 4.2), -15, "MarketStand_1"),
               ((-0.2, 3.0), 5, "MarketStand_2")],
    "tavern": ((7.2, 10.5), -30, "Inn"),
    "tailor": ((11.0, 16.0), -40, "House_1"),
    "guild": ((-2.4, 15.5), 5, "House_2"),
    "church": ((9.0, 22.0), -20, "Bell_Tower"),
    "yard": [((-8.2, 11.0), 38, "Stable"), ((-12.0, 16.5), 30, "Blacksmith")],
}
# Mekânsız evler ve ağaçlar için yuvalar: her biri bir kez, tohumla seçilir.
HOUSE_SLOTS = [((13.5, 12.0), -65), ((-11.5, 3.0), 70), ((11.8, 3.5), -70), ((-6.0, 30.0), 10),
               ((9.0, 32.0), -15), ((-14.0, 21.0), 40), ((15.0, 20.0), -40), ((4.0, 27.0), -5),
               ((-9.5, 24.5), 15), ((16.5, 8.0), -80), ((-16.0, 9.0), 80), ((-17.0, 28.0), 30)]
TREE_SLOTS = [(-12.5, 0.5), (13.0, 4.0), (-14.0, 26.0), (15.0, 25.0), (0.0, 29.0), (-16.5, 14.0),
              (17.5, 14.5), (-18.5, 22.0), (19.0, 28.0)]
PROP_SLOTS = [(-6.5, 4.8), (3.5, 3.0), (4.8, 8.0), (-5.0, 9.5), (9.0, 8.0), (10.3, 9.2), (-9.5, 7.0),
              (6.0, 6.0), (-3.0, 9.0), (2.5, 9.5)]
LAMP_BASE = [[-3.0, 2.5, 2.0, 150], [3.2, 2.5, 2.0, 150], [0.0, 6.0, 1.4, 120], [0.0, 1.0, 3.5, 90]]


def _rng(place_id):
    return random.Random(zlib.crc32(place_id.encode("utf-8")))


def _jit(rng, v, amount):
    return round(v + rng.uniform(-amount, amount), 2)


def _mirror(at, rot, flip):
    return ([-at[0], at[1]], -rot) if flip else (list(at), rot)


def _shade(rgb, rng, amount=8):
    return [max(0, min(255, int(c + rng.uniform(-amount, amount)))) for c in rgb]


def _latitude(place, map_h):
    return place["pos"][1] / float(map_h)


def build(place, map_h):
    rng = _rng(place["id"])
    kind = place.get("map_kind", "")
    ptype = place["type"]
    style = CULTURES.get(place["culture"], CULTURES["sinir"])
    lat = _latitude(place, map_h)
    flip = rng.random() < 0.5
    venues = VENUES_BY_TYPE[ptype]
    cfg = {"seed": rng.randrange(1, 999), "plaza": list(PLAZA), "camera": dict(CAMERA),
           "sky": dict(style["sky"]), "moon": style["moon"], "backlight": style["backlight"],
           "window": style["window"], "buildings": [], "props": []}
    for key in ("moon_color", "backlight_color", "weathered"):
        if key in style:
            cfg[key] = style[key]
    post = dict(style["post"])
    for key in ("zenith", "horizon", "cloud", "fog", "shadow"):
        if key in post:
            post[key] = _shade(post[key], rng)
    post["moon"] = [round(rng.uniform(0.15, 0.85), 2), round(rng.uniform(0.11, 0.2), 2)]
    cfg["post"] = post
    if style.get("ground_tint"):
        cfg["ground_tint"] = style["ground_tint"]

    # Kuzey soğuk: enlem 0.3'ün kuzeyinde tepe karlı, ışık maviye kayar.
    snow = 0.0
    if lat < 0.32:
        snow = round(min(0.8, (0.32 - lat) * 4.0), 2)
    if style.get("mountain"):
        snow = max(snow, 0.55)
    hill = _hill(rng, style, kind, snow)
    if hill is not None:
        cfg["hill"] = hill
    if snow > 0.3:
        cfg["snow"] = round(snow * 0.35, 2)

    lamps = [list(l) for l in LAMP_BASE]
    nomad = place.get("culture") == "gocebe"
    if nomad:
        _nomad_camp(cfg, rng, venues, flip, lamps)
    else:
        _venue_buildings(cfg, rng, venues, ptype, kind, style, flip, lamps)
        _fortification(cfg, rng, ptype, kind, style, flip)
        _skyline(cfg, rng, ptype, kind, style, hill)
        _fill_houses(cfg, rng, ptype, kind, style, flip)
    _trees(cfg, rng, ptype, kind, style, flip)
    _goods(cfg, rng, place, style, flip)
    if style.get("tents"):
        _camp(cfg, rng, flip)
    _plaza(cfg, rng, ptype, kind, style, nomad)
    # Türün kendi yüzü (kullanıcı, 2026-10-22): liman, bataklık, nehir, maden.
    # Öteki yerleşimlerin sahnesi bayt bayt aynı kalsın diye bunlar en sonda
    # ve yalnızca kendi türlerinde tohum çekiyor.
    _waterfront(cfg, rng, kind, flip)
    if kind in WATER_KINDS:
        # Su ancak yukarıdan okunuyor: kamera bir kat yüksekte, rıhtıma bakan
        # bir yokuşun başında (alçak kamerada deniz tezgâhların ardında bir
        # çizgiydi, ölçüldü).
        cfg["camera"] = {"at": [CAMERA["at"][0], CAMERA["at"][1], 5.2], "look": [CAMERA["look"][0], CAMERA["look"][1], 4.2],
                         "lens": CAMERA["lens"]}
    if kind == "it_minetown" or place.get("culture") == "dag_maden":
        _mine(cfg, rng, flip, hill)
    cfg["lamps"] = lamps
    return cfg


def _facing_camera(at):
    """Ön yüzü (-y) kameraya dönsün diye z dönüşü (derece)."""
    dx, dy = CAMERA["at"][0] - at[0], CAMERA["at"][1] - at[1]
    return round(math.degrees(math.atan2(dx, -dy)), 1)


# Göçebe yurdu: taş sur yok. Kervansarayın hanı hanın büyük yurdu, ahır at
# bağlama ipleri ve atlar, kapı iki tuğ arasında; çevre hasır çitle çevrili,
# yerleşim yurtlardan.
YURT_SLOTS = [((-8.5, 11.5), 2.6), ((8.5, 11.0), 2.4), ((-13.5, 16.5), 3.0), ((13.0, 15.5), 2.8),
              ((-8.0, 23.5), 2.5), ((8.0, 24.0), 2.7), ((-16.0, 26.0), 2.4), ((17.0, 26.5), 2.5),
              ((1.5, 29.0), 2.3)]
HORSE = "file:art_source/models/animals/quaternius_gltf/glTF/Horse.glb"


def _nomad_camp(cfg, rng, venues, flip, lamps):
    for venue in venues:
        if venue == "market":
            for (at, rot, model) in SLOTS["market"][:2]:
                pos, r = _mirror(at, rot, flip)
                cfg["buildings"].append({"venue": "market", "kind": model, "at": [_jit(rng, pos[0], 0.3), _jit(rng, pos[1], 0.3)],
                                         "rot": r + rng.randint(-6, 6), "scale": 1.6})
        elif venue == "tavern":
            at = [_jit(rng, 0.0, 1.0), 17.5]
            cfg["buildings"].append({"venue": "tavern", "kind": "builder:yurt:4.2", "at": at, "rot": _facing_camera(at)})
            for side in (-1, 1):
                cfg["props"].append({"kind": "builder:tug:5.2", "at": [at[0] + side * 5.0, at[1] - 3.2]})
            lamps.append([at[0], at[1] - 5.5, 2.4, 150])
        elif venue == "yard":
            for at, rot in (((-10.0, 8.0), 35), ((-12.5, 12.0), 40)):
                pos, r = _mirror(at, rot, flip)
                cfg["buildings"].append({"venue": "yard", "kind": "builder:horse_line:6", "at": pos, "rot": r})
            for at, rot in (((-9.0, 9.2), 125), ((-11.5, 13.2), 130), ((-13.5, 9.0), 70)):
                pos, r = _mirror(at, rot, flip)
                cfg["props"].append({"kind": HORSE, "at": pos, "rot": r, "scale": 0.5})
            pos, _ = _mirror((-15.0, 11.0), 0, flip)
            cfg["props"].append({"venue": "yard", "kind": "Hay", "at": pos, "scale": 1.3})
    slots = list(YURT_SLOTS)
    rng.shuffle(slots)
    for (at, radius) in slots[:8]:
        pos, _ = _mirror(at, 0, flip)
        pos = [_jit(rng, pos[0], 0.5), _jit(rng, pos[1], 0.5)]
        cfg["props"].append({"kind": "builder:yurt:%.1f" % (radius * rng.uniform(0.92, 1.08)), "at": pos,
                             "rot": _facing_camera(pos) + rng.randint(-20, 20)})
    # Çevre: hasır çit, kapıda iki tuğ (kapı mekânı) - sur değil, obanın ağzı.
    gx = 7.0 if not flip else -7.0
    y = 33.5
    x = -30.0
    while x < 30.0:
        if abs(x - gx) > 2.6:
            cfg["props"].append({"kind": "ftk:fence", "at": [x, y + 0.4 * math.sin(x * 0.3)], "rot": 90, "scale": 2.2})
        x += 2.2
    for side in (-1, 1):
        cfg["props"].append({"kind": "builder:tug:5.6", "at": [gx + side * 2.2, y], "venue": "gate"})
    pos, r = _mirror((10.5, 6.5), -70, flip)
    cfg["props"].append({"kind": HORSE, "at": pos, "rot": r, "scale": 0.5})
    pos, _ = _mirror((12.5, 5.5), 0, flip)
    cfg["props"].append({"kind": "builder:horse_line:4", "at": pos, "rot": rng.randint(-30, 30)})


def _place_venue(cfg, venue, at, rot, flip, **extra):
    pos, r = _mirror(at, rot, flip)
    for spec in cfg["buildings"]:
        if spec.get("venue") == venue:
            spec["at"], spec["rot"] = pos, r
            spec.update(extra)
            return spec
    return None


# Su kıyısı: liman şehrinde rıhtım, iskeleler, gemiler; bataklıkta göller ve
# kazıklı evler; nehir kasabasında meydanın hemen ardından akan ırmak, köprü ve
# su değirmeni. Alçak kamera suyu ancak yakındaysa görüyor (ölçüldü: 20 m
# ötedeki ırmak tezgâhların ardında bir çizgiye iniyordu), o yüzden su meydanın
# hemen arkasında. Suya düşen sıradan ev, ağaç ve yük sonradan ayıklanır.
WATER_KINDS = ("ic_portcity", "it_swamptown", "it_rivertown")


def _waterfront(cfg, rng, kind, flip):
    m = -1.0 if flip else 1.0
    pools = []
    if kind == "ic_portcity":
        quay_y = 14.0
        pools = [[-140.0, quay_y + 0.3, 140.0, 220.0]]
        cfg["props"].append({"kind": "quay", "from": [-70.0, quay_y], "to": [70.0, quay_y], "height": 0.7, "wet": True})
        _place_venue(cfg, "guild", (-13.5, 10.5), 15, flip)
        _place_venue(cfg, "tavern", (8.0, 9.5), -30, flip)
        _place_venue(cfg, "tailor", (12.5, 11.5), -45, flip)
        _place_venue(cfg, "church", (18.0, 7.0), -55, flip)
        for spec in cfg["buildings"]:
            if spec.get("venue") == "yard" and spec.get("kind") == "Blacksmith":
                spec["at"], spec["rot"] = _mirror((-18.5, 5.0), 65, flip)
        lx = 21.0 * m
        cfg["props"].append({"kind": "quay", "from": [lx, quay_y], "to": [lx, 38.0], "height": 0.9, "wet": True})
        for spec in cfg["props"]:
            if spec.get("kind") == "spire" and spec.get("roof") == "roof-point":
                spec["at"] = [lx, 38.0]
                spec["wet"] = True
            if spec.get("kind") == "wallrow" and spec.get("venue") == "gate":
                spec["from"], spec["to"] = [-27.0 * m, quay_y - 1.6], [-19.0 * m, quay_y - 1.6]
        for px in (-4.0 * m, 5.0 * m):
            for i in range(4):
                cfg["props"].append({"kind": "kp:structure-platform-dock", "at": [px, quay_y + 2.3 + i * 4.0], "z": -0.45,
                                     "scale": 1.6, "wet": True})
        cfg["props"].append({"kind": "kp:ship-large", "at": [-12.0 * m, 24.0], "rot": 90 * m, "scale": 1.0, "wet": True})
        cfg["props"].append({"kind": "kp:ship-medium", "at": [12.5 * m, 29.0], "rot": -82 * m, "scale": 1.0, "wet": True})
        cfg["props"].append({"kind": "kp:ship-small", "at": [1.0 * m, 44.0], "rot": 98 * m, "scale": 1.0, "wet": True})
        for at, r in (((-1.5, 17.5), 20), ((8.0, 19.0), -35), ((-7.0, 18.5), 70)):
            cfg["props"].append({"kind": "kp:boat-row-large", "at": [at[0] * m, at[1]], "z": 0.05, "rot": r * m,
                                 "scale": 1.0, "wet": True})
        for at in ((-6.5, 12.8), (3.0, 13.0)):
            cfg["props"].append({"kind": "builder:net_rack:3.0", "at": [at[0] * m, at[1]], "rot": rng.randint(-10, 10)})
    elif kind == "it_swamptown":
        pools = [[-34.0, 10.0, -7.5, 50.0], [8.5, 12.0, 34.0, 50.0]]
        _place_venue(cfg, "church", (2.5, 22.0), -10, flip)
        tailor = _place_venue(cfg, "tailor", (14.0, 16.0), -50, flip, z=1.6)
        if tailor is not None:
            cfg["props"].append({"kind": "builder:stilts:1.6", "at": tailor["at"], "rot": tailor["rot"], "wet": True})
        for at, house in (((-14.5, 16.0), "House_1"), ((-23.0, 26.0), "House_3"), ((22.0, 28.0), "House_3")):
            pos = [at[0] * m, at[1]]
            r = _facing_camera(pos)
            cfg["props"].append({"kind": "builder:stilts:1.6", "at": pos, "rot": r, "wet": True})
            cfg["props"].append({"kind": house, "at": pos, "z": 1.6, "rot": r, "scale": 1.25, "wet": True})
        for at, w in (((-8.5, 13.0), 4.0), ((9.5, 15.0), 3.5), ((-28.0, 14.0), 5.0), ((26.0, 18.0), 4.5),
                      ((-11.0, 30.0), 3.0), ((13.0, 34.0), 4.0)):
            cfg["props"].append({"kind": "builder:reeds:%.1f" % w, "at": [at[0] * m, at[1]], "wet": True})
        for at, r in (((-10.5, 19.0), 30), ((11.5, 22.0), -40)):
            cfg["props"].append({"kind": "kp:boat-row-small", "at": [at[0] * m, at[1]], "z": 0.05, "rot": r * m,
                                 "scale": 1.0, "wet": True})
        for at in ((-6.0, 9.5), (7.0, 10.5)):
            cfg["props"].append({"kind": "builder:net_rack:3.0", "at": [at[0] * m, at[1]], "rot": rng.randint(-20, 20)})
    elif kind == "it_rivertown":
        pools = [[-140.0, 12.5, 140.0, 18.5]]
        cfg["props"].append({"kind": "file:art_source/models/props/quaternius_modular_medieval/Bridge.blend",
                             "at": [0.0, 15.5], "rot": 90, "scale": 2.6, "wet": True})
        _place_venue(cfg, "tailor", (13.5, 10.0), -50, flip)
        for spec in cfg["props"]:
            if spec.get("kind") == "ftk:watermill":
                spec["at"], spec["rot"] = _mirror((-11.0, 13.0), 0, flip)
                spec["wet"] = True
        cfg["props"].append({"kind": "kp:boat-row-large", "at": [6.5 * m, 15.0], "z": 0.05, "rot": 80 * m,
                             "scale": 1.0, "wet": True})
        cfg["props"].append({"kind": "builder:net_rack:3.0", "at": [5.5 * m, 11.0], "rot": rng.randint(-15, 15)})
        for at in ((17.0, 13.0), (-20.0, 17.5)):
            cfg["props"].append({"kind": "builder:reeds:4.0", "at": [at[0] * m, at[1]], "wet": True})
    murky = kind == "it_swamptown"
    for x0, y0, x1, y1 in pools:
        spec = {"kind": "water", "rect": [x0, y0, x1, y1], "z": 0.04, "wet": True}
        if murky:
            spec["color"] = [0.06, 0.08, 0.05]
        cfg["props"].append(spec)
    if pools:
        _clear_water(cfg, pools)


def _clear_water(cfg, pools):
    def wet(at):
        return any(x0 - 1.0 <= at[0] <= x1 + 1.0 and y0 - 1.0 <= at[1] <= y1 + 1.0 for x0, y0, x1, y1 in pools)
    for key in ("buildings", "props"):
        cfg[key] = [s for s in cfg[key] if s.get("wet") or s.get("venue") or "at" not in s or not wet(s["at"])]


# Maden: dağın eteğinde galeri ağzı, ağza meydandan giden ray ve arabalar,
# kuyu iskelesi, cevher yığınları. Kasabanın ne yaptığı meydandan görünsün.
# Galeri sol yarıda: sağ yarıda han, tapınak ve terzi duruyor.
MINE = "file:art_source/models/props/kaykit_medieval_hexagon/building_mine_red.gltf"


def _mine(cfg, rng, flip, hill):
    m = -1.0 if flip else 1.0
    river = any(p.get("kind") == "water" for p in cfg["props"])
    portal = [-7.5 * m, 27.0]
    start = [-3.5 * m, 9.0] if not river else [-6.0 * m, 20.0]
    cfg["props"].append({"kind": MINE, "at": portal, "rot": 0, "scale": 7.0})
    dx, dy = portal[0] - start[0], portal[1] - 2.5 - start[1]
    length = math.hypot(dx, dy)
    rot = round(math.degrees(math.atan2(-dx, dy)), 1)
    cfg["props"].append({"kind": "builder:rails:%.1f" % length, "at": start, "rot": rot})
    for t in (0.25, 0.7):
        cfg["props"].append({"kind": "builder:minecart", "at": [start[0] + dx * t, start[1] + dy * t], "rot": rot})
    cfg["props"].append({"kind": "builder:headframe:8", "at": [-16.5 * m, 21.0], "rot": rng.randint(-15, 15)})
    for at, size in (((-13.0, 27.0), 2.2), ((-1.5, 28.0), 1.5), ((4.5, 33.0), 1.8)):
        cfg["props"].append({"kind": "builder:ore_heap:%.1f" % size, "at": [at[0] * m, at[1]]})
    for at in ((-6.5, 7.5), (-10.0, 15.0)):
        cfg["props"].append({"kind": "kk:resource_stone", "at": [at[0] * m, at[1]], "rot": rng.randint(0, 359), "scale": 2.5})
    cfg["props"].append({"kind": "kk:wheelbarrow", "at": [-5.0 * m, 5.0], "rot": rng.randint(0, 359), "scale": 2.2})
    # Rayın ve galerinin üstüne düşen sıradan evler, ağaçlar kalkar.
    def blocked(at):
        t = ((at[0] - start[0]) * dx + (at[1] - start[1]) * dy) / max(length * length, 1.0)
        px, py = start[0] + dx * t, start[1] + dy * t
        return (-0.1 < t < 1.25 and math.hypot(at[0] - px, at[1] - py) < 4.5) or math.hypot(at[0] - portal[0], at[1] - portal[1]) < 7.0
    keep = ("builder:", MINE, "kk:")
    for key in ("buildings", "props"):
        cfg[key] = [s for s in cfg[key] if s.get("venue") or "at" not in s or str(s.get("kind", "")).startswith(keep)
                    or not blocked(s["at"])]


def _hill(rng, style, kind, snow):
    if kind == "ic_portcity":
        # Liman şehrinin arkası deniz: tepe yok, gök ufka kadar iner ve
        # town_post'un ufuk sisi onu düz bir su çizgisi gibi okutur.
        return None
    if style.get("mountain") or kind == "it_minetown":
        return {"at": [_jit(rng, 2.0, 10.0), _jit(rng, 46.0, 4.0), -2.0],
                "scale": [_jit(rng, 46.0, 6.0), 12.0, _jit(rng, 27.0, 3.0)], "snow": max(snow, 0.55),
                "tint": style["hill_tint"], "rough": 0.45, "rough_scale": 0.3}
    hill = {"at": [_jit(rng, 0.0, 12.0), _jit(rng, 58.0, 6.0), -8.0],
            "scale": [_jit(rng, 54.0, 8.0), 10.0, _jit(rng, 15.0, 3.0)], "tint": style["hill_tint"]}
    if snow > 0.0:
        hill["snow"] = snow
    if kind == "it_swamptown":
        hill["scale"][2] = 9.0
        hill["rough"] = 0.2
    return hill


def _venue_buildings(cfg, rng, venues, ptype, kind, style, flip, lamps):
    town = ptype != "city"
    for venue in venues:
        if venue == "market":
            stalls = SLOTS["market"][: (5 if kind == "it_markettown" or ptype == "city" else 3)]
            for (at, rot, model) in stalls:
                pos, r = _mirror(at, rot, flip)
                cfg["buildings"].append({"venue": "market", "kind": model, "at": [_jit(rng, pos[0], 0.3), _jit(rng, pos[1], 0.3)],
                                         "rot": r + rng.randint(-6, 6), "scale": 1.8 if not town else 1.6})
            continue
        if venue == "yard":
            slots = SLOTS["yard"] if ptype == "city" else SLOTS["yard"][:1]
            if ptype == "caravanserai":
                # Hanın ahırı avlunun içinde, meydana bakar.
                slots = [((-7.6, 10.0), 50, "Stable")]
            for (at, rot, model) in slots:
                pos, r = _mirror(at, rot, flip)
                cfg["buildings"].append({"venue": "yard", "kind": model, "at": pos, "rot": r, "scale": 1.5 if model == "Stable" else 1.2})
            pos, r = _mirror((-6.0, 8.6), 70, flip)
            cfg["props"].append({"venue": "yard", "kind": "Cart", "at": pos, "rot": r, "scale": 1.2})
            continue
        at, rot, model = SLOTS[venue]
        pos, r = _mirror(at, rot, flip)
        spec = {"venue": venue, "kind": model, "at": [_jit(rng, pos[0], 0.5), _jit(rng, pos[1], 0.5)],
                "rot": r + rng.randint(-8, 8), "scale": 1.5}
        if venue == "tavern" and ptype == "caravanserai":
            # Kervansarayın kendisi han: avlunun arka duvarına yaslanır, büyük.
            spec.update({"at": [_jit(rng, 0.0, 1.0), 15.0], "rot": rng.randint(-6, 6), "scale": 2.2})
        if venue == "guild":
            high = kind == "ic_freecity"
            spec.update({"scale": 2.1, "terrace": [8, 6, 3.0], "spires": [
                {"at": [3.6, 0.6, 0.0], "floors": 6 if high else 4, "size": 1.2, "wood": style["wall"] == "wood"},
                {"at": [-3.8, 0.6, 0.0], "floors": 5 if high else 3, "size": 1.2, "wood": style["wall"] == "wood"}]})
        if venue == "church":
            if style.get("grand_church"):
                spec.update({"at": [_jit(rng, pos[0] * 0.3, 0.5), 24.0], "scale": 2.8, "terrace": [7, 6, 5.5], "spires": [
                    {"at": [-3.4, 1.2, 0.0], "floors": 7, "size": 1.3}, {"at": [3.4, 1.2, 0.0], "floors": 7, "size": 1.3},
                    {"at": [-6.4, 2.6, 0.0], "floors": 4, "size": 1.1}, {"at": [6.4, 2.6, 0.0], "floors": 4, "size": 1.1}]})
            elif ptype == "city":
                spec.update({"scale": 2.2, "terrace": [5, 5, 4.5], "spires": [
                    {"at": [-2.6, 1.2, 0.0], "floors": rng.randint(3, 5), "size": 1.15},
                    {"at": [2.8, 1.2, 0.0], "floors": rng.randint(2, 4), "size": 1.0}]})
            else:
                spec.update({"scale": 1.7})
        if venue == "tailor" and town:
            spec["scale"] = 1.35
        cfg["buildings"].append(spec)
        lamps.append([spec["at"][0] * 0.8, spec["at"][1] - 2.0, 2.4, 150])
    if "tailor" in venues:
        pos, r = _mirror((4.6, 4.2), -35, flip)
        cfg["props"].append({"venue": "tailor", "kind": "MarketStand_2", "at": pos, "rot": r, "scale": 1.5})
    if "tavern" in venues:
        pos, _ = _mirror((4.8, 8.0), 0, flip)
        cfg["props"].append({"venue": "tavern", "kind": "Barrel", "at": pos, "scale": 1.3})


def _fortification(cfg, rng, ptype, kind, style, flip):
    """Sur ve kapı: kapı kemeri `gate` mekânıdır (tıklanınca yola çıkılır)."""
    if ptype == "caravanserai":
        y = 19.0
        cfg["props"].append({"kind": "wallrow", "from": [-12.0, y], "to": [12.0, y], "size": 2.4, "floors": 2,
                             "towers": 5, "value": style["wall_value"]})
        for side in (-1, 1):
            cfg["props"].append({"kind": "wallrow", "from": [side * 12.5, 3.0], "to": [side * 12.5, y], "size": 2.4,
                                 "floors": 2, "value": style["wall_value"]})
        # Kapı önde değil yanda: kamerayı kapatmasın, avlu görünsün.
        gx = -12.5 if not flip else 12.5
        cfg["props"].append({"kind": "wallrow", "from": [gx, -1.0], "to": [gx, 3.0], "size": 2.4, "floors": 2,
                             "gate": 0.5, "venue": "gate", "value": style["wall_value"]})
        return
    if ptype == "city" and kind != "ic_portcity":
        # Sur meydanın arkasında, tapınağın da arkasında: önde dursa şehri
        # bir duvara çevirir (ilk denemede tapınağı ve kaleyi örttü).
        y = _jit(rng, 35.0, 1.0) if not style.get("grand_church") else 38.0
        cfg["props"].append({"kind": "wallrow", "from": [-30.0, y], "to": [30.0, y], "size": 2.6, "floors": 2,
                             "towers": 4, "gate": round(rng.uniform(0.42, 0.58), 2), "venue": "gate",
                             "value": style["wall_value"]})
        return
    if ptype == "city":
        # Liman şehri: sur yok, rıhtım; kapı yerine liman kemeri ve fener.
        cfg["props"].append({"kind": "wallrow", "from": [-8.0, 26.0], "to": [8.0, 26.0], "size": 2.4, "floors": 1,
                             "gate": 0.5, "venue": "gate", "value": style["wall_value"]})
        lx = 18.0 if not flip else -18.0
        cfg["props"].append({"kind": "spire", "at": [lx, 30.0], "floors": 8, "size": 1.7, "roof": "roof-point"})
        return
    wood = style["wall"] == "wood" or kind in ("it_swamptown", "it_town", "it_rivertown")
    y = _jit(rng, 30.0, 1.5)
    cfg["props"].append({"kind": "wallrow", "from": [-24.0, y], "to": [24.0, y], "size": 2.2, "floors": 1,
                         "towers": 6 if wood else 5, "gate": round(rng.uniform(0.4, 0.6), 2), "venue": "gate",
                         "wood": wood, "value": style["wall_value"]})


def _skyline(cfg, rng, ptype, kind, style, hill):
    """Arka sırt: şehirde kale (özgür şehirde yok), kasabada bir gözcü kulesi."""
    if kind == "ic_portcity" or ptype == "caravanserai" or hill is None:
        return
    top = hill["at"][2] + hill["scale"][2] * 0.78
    if ptype == "city" and kind != "ic_freecity":
        cx = hill["at"][0] + rng.uniform(-6.0, 6.0)
        cy = hill["at"][1] - hill["scale"][1] * 0.55
        z = max(4.0, top * 0.55)
        cfg["props"].append({"kind": "wallrow", "from": [cx - 10.0, cy], "to": [cx + 10.0, cy], "z": z, "size": 2.2,
                             "floors": 2, "towers": 3, "value": style["wall_value"]})
        for dx, floors in ((0.0, 6), (-7.5, 4), (7.5, 5)):
            cfg["props"].append({"kind": "spire", "at": [cx + dx, cy + 2.0], "z": z, "floors": floors + rng.randint(-1, 1),
                                 "size": 2.2, "dark": style["dark_spires"]})
        return
    if ptype == "town" and rng.random() < 0.6:
        cx = hill["at"][0] + rng.uniform(-14.0, 14.0)
        cfg["props"].append({"kind": "spire", "at": [cx, hill["at"][1] - 6.0], "z": max(2.0, top * 0.4),
                             "floors": rng.randint(3, 4), "size": 2.0, "wood": style["wall"] == "wood"})


def _fill_houses(cfg, rng, ptype, kind, style, flip):
    count = {"city": 9, "town": 5, "caravanserai": 2}[ptype]
    slots = list(HOUSE_SLOTS)
    if ptype == "caravanserai":
        slots = [s for s in slots if abs(s[0][0]) < 12 and s[0][1] < 18]
    rng.shuffle(slots)
    for (at, rot) in slots[:count]:
        pos, r = _mirror(at, rot, flip)
        model = rng.choice(["House_1", "House_2", "House_3", "House_3"])
        spec = {"kind": model, "at": [_jit(rng, pos[0], 0.6), _jit(rng, pos[1], 0.6)], "rot": r + rng.randint(-10, 10),
                "scale": round(rng.uniform(1.3, 1.6), 2)}
        if style.get("flat_roofs") and rng.random() < 0.5:
            # Güney: düz damlı taş ev - Kenney duvarından bir kat, düz çatı.
            spec = {"kind": "spire", "at": spec["at"], "floors": rng.randint(1, 2), "size": 2.0, "roof": "roof-flat"}
        cfg["props"].append(spec)
    if kind == "it_minetown":
        pos, r = _mirror((-13.0, 13.0), 30, flip)
        cfg["props"].append({"kind": "Blacksmith", "at": pos, "rot": r, "scale": 1.2})
    if kind == "it_rivertown":
        pos, r = _mirror((12.0, 13.0), -60, flip)
        cfg["props"].append({"kind": "ftk:watermill", "at": pos, "rot": r, "scale": 3.0})


def _trees(cfg, rng, ptype, kind, style, flip):
    count = {"city": 4, "town": 6, "caravanserai": 3}[ptype]
    if kind == "it_swamptown":
        count += 2
    slots = list(TREE_SLOTS)
    rng.shuffle(slots)
    trees = style["trees"] if kind != "it_swamptown" else ["ftk:tree-high-crooked", "ftk:tree-crooked"]
    for at in slots[:count]:
        pos, _ = _mirror(at, 0, flip)
        cfg["props"].append({"kind": rng.choice(trees), "at": pos, "rot": rng.randint(0, 359),
                             "scale": round(rng.uniform(2.6, 3.6), 2)})
    for extra in style.get("extra", []):
        at = rng.choice(TREE_SLOTS)
        pos, _ = _mirror((at[0] * 0.9, at[1] * 0.8), 0, flip)
        cfg["props"].append({"kind": extra, "at": pos, "rot": rng.randint(0, 359), "scale": 2.2 if extra.startswith("ftk:") else 1.3})


def _goods(cfg, rng, place, style, flip):
    slots = list(PROP_SLOTS)
    rng.shuffle(slots)
    goods = list(place.get("produces", []))
    i = 0
    for good in goods:
        for model in GOODS_PROPS.get(good, []):
            if i >= len(slots):
                return
            pos, _ = _mirror(slots[i], 0, flip)
            i += 1
            scale = 1.3
            if model.startswith("ftk:stall"):
                scale = 1.6
            cfg["props"].append({"kind": model, "at": pos, "rot": rng.randint(-40, 40), "scale": scale})
    if "test_grain" in goods and rng.random() < 0.7:
        pos, r = _mirror((-7.0, 30.0), 20, flip)
        cfg["props"].append({"kind": "ftk:windmill", "at": pos, "rot": r, "scale": 6.5, "terrace": [4, 4, 2.0]})
    for banner in style.get("banners", []):
        for side in (-1, 1):
            if rng.random() < 0.6:
                cfg["props"].append({"kind": banner, "at": [side * _jit(rng, 5.0, 1.0), _jit(rng, 9.0, 1.0)],
                                     "rot": rng.randint(-20, 20), "scale": 2.0})


def _camp(cfg, rng, flip):
    tent = "file:art_source/models/props/quaternius_survival/Tent.blend"
    fire = "file:art_source/models/props/quaternius_survival/Bonfire_Fire.blend"
    for at, rot in (((-7.5, 12.5), -15), ((7.0, 13.5), 20), ((-3.0, 16.0), 5)):
        pos, r = _mirror(at, rot, flip)
        cfg["props"].append({"kind": tent, "at": pos, "rot": r, "scale": 0.28})
    cfg["props"].append({"kind": fire, "at": [_jit(rng, 2.5, 0.4), 9.0], "scale": 0.42})


def _plaza(cfg, rng, ptype, kind, style, nomad=False):
    centre = "ftk:fountain-round" if ptype == "city" else "Well"
    if ptype == "caravanserai":
        centre = "ftk:fountain-square"
    if nomad:
        # Göçebe obasının ortası çeşme değil ocak.
        cfg["props"].append({"kind": "file:art_source/models/props/quaternius_survival/Bonfire_Fire.blend",
                             "at": [0.0, 6.0], "scale": 0.6})
        for x in (-3.0, 3.2):
            cfg["props"].append({"kind": "builder:tug:3.2", "at": [x, 2.5]})
        return
    cfg["props"].append({"kind": centre, "at": [0.0, 6.0], "scale": 1.6 if centre.startswith("ftk") else 1.4})
    for x in (-3.0, 3.2):
        cfg["props"].append({"kind": "ftk:lantern", "at": [x, 2.5], "scale": 1.4})


def main(argv):
    data = json.load(open(SETTLEMENTS, encoding="utf-8"))
    map_h = data["map_size"][1]
    towns = json.load(open(TOWNS, encoding="utf-8"))
    only = set(argv[1:])
    n = 0
    for place in data["settlements"]:
        if only and place["id"] not in only:
            continue
        towns[place["id"]] = build(place, map_h)
        n += 1
    with open(TOWNS, "w", encoding="utf-8", newline="\n") as f:
        json.dump(towns, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("yazildi:", n, "yer")


if __name__ == "__main__":
    main(sys.argv)
