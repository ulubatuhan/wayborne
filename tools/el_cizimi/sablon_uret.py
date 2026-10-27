"""Her envanter satırı için çizim şablonu üretir ve kategorilere göre zipler.

Bir şablon üç dosyadır, hepsi çizimin tuvaliyle aynı boyutta ve hizada:
  <ID>_ref.jpg     referans: bugünkü görsel + kılavuzlar (yer çizgisi, eklem
                   noktaları, tıklama alanı hatları, döşeme kenarları)
  <ID>_katman.png  çok katmanlı işlerde: hangi parça hangi katmana (renkli)
  <ID>.psd         çok katmanlı işlerde: katmanları adlı, boş, hazır tuval
                   (referans %35 opak en altta, katman haritası gizli)
Ayrıca `tools/el_cizimi/sablonlar.json`: alım aracının çizimi oyuna geri
taşıması için her şablonun ölçeği ve konumu. Bu dosya depoya girer; ziplenmiş
şablonlar girmez (büyük, her an yeniden üretilebilir).

    python3 -I tools/el_cizimi/sablon_uret.py <çıktı klasörü> [--only ID_ÖNEKİ ...] [--no-zip]
"""
from __future__ import annotations

import json
import math
import sys
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import envanter  # noqa: E402
from ortak import (A, GUIDE, LAYER_COLORS, ROOT, Frames, Skin, bbox_of, font, paste_placed,  # noqa: E402
                   props_sheet)

PAPER = (244, 240, 232)
META_PATH = Path(__file__).resolve().parent / "sablonlar.json"
REF_OPACITY = 89  # %35
FIG_CANVAS = 2048
FIG_GROUND = 1968
FIG_SCALE = 2.75  # HD karenin pikseli -> tuval pikseli; bütün figürler aynı ölçekte, giysi bedene oturur
FIG_CENTER_X = 1024

ZIP_GROUPS = {
    "Figür": "01_figur", "Hayvan": "02_hayvan", "Eşya": "03_esya", "Yerleşim": "04_yerlesim",
    "Yol": "05_yol", "Harita": "06_harita", "Arayüz": "07_arayuz", "Gösterge": "07_arayuz",
    "Olay": "08_olay", "Sahne": "09_sahne", "Gökyüzü": "09_sahne", "Efekt": "10_efekt",
}

JOINT_TR = {"shoulder": "omuz", "elbow_front": "dirsek", "hand_front": "el", "hip": "kalça", "neck": "boyun",
            "head_top": "tepe", "chin": "çene", "knee_front": "diz", "ankle_front": "bilek"}


def _paper(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), PAPER + (255,))


def _header(img: Image.Image, row: dict, extra: str = "", compact: bool = False) -> None:
    d = ImageDraw.Draw(img)
    size = max(18, img.width // 80)
    if compact:
        # Resmin üstüne yazı düşmesin: tek satır, sol alt köşe. Ayrıntı Excel'de ve OKU_BENI'de.
        size = max(14, min(img.width, img.height) // 50)
        text = "%s · %dx%d" % (row["id"], img.width, img.height)
        tw = int(d.textlength(text, font=font(size)))
        d.rectangle((0, img.height - int(size * 1.6), tw + size, img.height), fill=PAPER + (220,))
        d.text((size // 2, img.height - int(size * 1.45)), text, font=font(size), fill=(40, 60, 80))
        return
    lines = ["%s   %s" % (row["id"], row["ad"]), "Tuval %dx%d · %s" % (img.width, img.height, row["teslim"])]
    if len(row["katmanlar"]) > 1:
        lines.append("Katmanlar (alttan üste): " + ", ".join(row["katmanlar"]))
    if row["renk"] != envanter.RENK:
        lines.append(row["renk"])
    if extra:
        lines.append(extra)
    y = size // 2
    box_w = max(int(d.textlength(line, font=font(size))) for line in lines) + size
    d.rectangle((0, 0, box_w, y + int(size * 1.3) * len(lines) + size // 3), fill=PAPER + (230,))
    for line in lines:
        d.text((size // 2, y), line, font=font(size), fill=(40, 60, 80))
        y += int(size * 1.3)


def _legend(img: Image.Image, names: list[str]) -> None:
    d = ImageDraw.Draw(img)
    size = max(18, img.width // 70)
    x = img.width - size * 12
    y = size
    for i, n in enumerate(names):
        c = LAYER_COLORS[i % len(LAYER_COLORS)]
        d.rectangle((x, y, x + size, y + size), fill=c + (255,))
        d.text((x + int(size * 1.4), y - size // 6), "%d %s" % (i + 1, n), font=font(size), fill=(30, 30, 30, 255))
        y += int(size * 1.5)


def _save_set(out: Path, row: dict, ref: Image.Image, layer_map: Image.Image | None) -> None:
    out.mkdir(parents=True, exist_ok=True)
    ref.convert("RGB").save(out / ("%s_ref.jpg" % row["id"]), quality=82)
    if layer_map is not None:
        layer_map.save(out / ("%s_katman.png" % row["id"]), optimize=True)
        _psd(out / ("%s.psd" % row["id"]), row, ref, layer_map)


def _psd(path: Path, row: dict, ref: Image.Image, layer_map: Image.Image) -> None:
    from psd_tools import PSDImage
    from psd_tools.api.layers import PixelLayer
    from psd_tools.constants import Compression
    # Referans PSD'ye gömülmüyor: her PSD 20 MB oluyordu. Çizer _ref.jpg'yi
    # en alta kendisi içe aktarıyor (SUREC.md, adım 3).
    psd = PSDImage.new("RGBA", ref.size)
    m = PixelLayer.frompil(layer_map, psd, "katman_haritasi", compression=Compression.RLE)
    m.visible = False
    psd.append(m)
    empty = Image.new("RGBA", ref.size, (0, 0, 0, 0))
    for name in row["katmanlar"]:
        psd.append(PixelLayer.frompil(empty, psd, name, compression=Compression.RLE))
    psd.save(str(path))


# --- figürler ------------------------------------------------------------

def _fig_source(row: dict):
    src = row["kaynak_dosya"]
    kind = 0
    if "#" in src:
        src, k = src.split("#")
        kind = int(k)
    return Frames(src), kind


def figure(row: dict, out: Path, meta: dict) -> None:
    gender = "male" if row["id"].endswith("-E") else "female"
    body = Frames("body_%s_average_hd" % gender)
    origin = (FIG_CENTER_X - 40 * FIG_SCALE, FIG_GROUND)
    ref = _paper(FIG_CANVAS, FIG_CANVAS)
    body_kinds = (0, 1, 2)
    is_body = row["alt_grup"] in ("Beden", "Temel takım")
    is_new = row["kaynak"] == envanter.KAYNAK_YOK
    item_placed = None
    if row["alt_grup"] == "Beden":
        item_placed = body.compose("idle", 0, kinds=(0,))
        paste_placed(ref, body.compose("idle", 0, kinds=(1, 2)), origin, FIG_SCALE, alpha=0.18)
        paste_placed(ref, item_placed, origin, FIG_SCALE, tint=(150, 150, 150))
    elif row["alt_grup"] == "Temel takım":
        frames, kind = _fig_source(row)
        paste_placed(ref, body.compose("idle", 0, kinds=(0,)), origin, FIG_SCALE, alpha=0.25)
        item_placed = frames.compose("idle", 0, kinds=(kind,))
        paste_placed(ref, item_placed, origin, FIG_SCALE, tint=(150, 150, 150))
    else:
        paste_placed(ref, body.compose("idle", 0, kinds=body_kinds), origin, FIG_SCALE, alpha=0.25)
        if not is_new:
            frames, _ = _fig_source(row)
            kinds = (3,) if row["alt_grup"] == "Saç" else (0,)
            item_placed = frames.compose("idle", 0, kinds=kinds)
            if not any(item_placed.values()):
                item_placed = frames.compose("idle", 0, kinds=(0, 1, 2, 3))
            paste_placed(ref, item_placed, origin, FIG_SCALE,
                         tint=(150, 150, 150) if row["renk"] == envanter.GRI else None)
    _fig_guides(ref, body, origin)
    _header(ref, row, "Rölanti pozu. Ayak tabanı mavi çizgide; eklem noktaları kaymasın.")
    layer_map = Image.new("RGBA", ref.size, (0, 0, 0, 0))
    src_for_map = item_placed if item_placed else body.compose("idle", 0, kinds=(0,))
    alpha = 1.0 if item_placed else 0.35
    skirt = "etek" in row["katmanlar"]
    for li in range(5):
        if skirt and li in (1, 2, 3):
            continue
        k = row["katmanlar"].index(envanter.FIG_LAYERS[li])
        paste_placed(layer_map, src_for_map, origin, FIG_SCALE, tint=LAYER_COLORS[k], alpha=alpha, layers=[li])
    if skirt:
        # Eteğin bacak ve gövde katmanlarındaki parçaları tek "etek" katmanına; bel üstü gövdede kalır.
        k = row["katmanlar"].index("etek")
        paste_placed(layer_map, src_for_map, origin, FIG_SCALE, tint=LAYER_COLORS[k], alpha=alpha, layers=[1, 2, 3])
    _legend(layer_map, row["katmanlar"])
    _save_set(out, row, ref, layer_map)
    meta[row["id"]] = {"tip": "figure", "tuval": [FIG_CANVAS, FIG_CANVAS], "olcek": FIG_SCALE,
                       "koken": list(origin), "beden": "body_%s_average_hd" % gender,
                       "katmanlar": {n: ("skirt" if n == "etek" else Frames.LAYERS[envanter.FIG_LAYERS.index(n)])
                                     for n in row["katmanlar"]},
                       "dolu": _filled_layers(row, item_placed)}


def _filled_layers(row: dict, placed) -> list[str]:
    """Bu parçada gerçekten bir şey olan katmanlar: alım aracı yalnızca bunların eksikliğini söyler."""
    if not placed:
        return list(row["katmanlar"])
    names = []
    for n in row["katmanlar"]:
        lis = [1, 2, 3] if n == "etek" else [envanter.FIG_LAYERS.index(n)]
        if n != "etek" and "etek" in row["katmanlar"] and lis[0] in (1, 2, 3):
            continue
        if any(placed.get(li) for li in lis):
            names.append(n)
    return names


def _fig_guides(img: Image.Image, body: Frames, origin) -> None:
    d = ImageDraw.Draw(img)
    d.line((0, origin[1], img.width, origin[1]), fill=GUIDE + (255,), width=3)
    joints = body.frame_joints("idle", 0)
    f = font(22)
    for name, tr in JOINT_TR.items():
        x, y = joints[name]
        px, py = origin[0] + x * FIG_SCALE, origin[1] + y * FIG_SCALE
        d.ellipse((px - 7, py - 7, px + 7, py + 7), outline=GUIDE + (255,), width=3)
        d.text((px + 12, py - 14), tr, font=f, fill=GUIDE + (255,))


# --- hayvanlar ------------------------------------------------------------

def beast(row: dict, out: Path, meta: dict) -> None:
    skin = Skin(row["kaynak_dosya"])
    xs, ys, xe, ye = [], [], [], []
    for l in skin.layers:
        (x0, y0), (sx, sy) = l["origin"], l["px"]
        xs.append(x0); ys.append(y0); xe.append(x0 + l["img"].width * sx); ye.append(y0 + l["img"].height * sy)
    bx, by, bw, bh = min(xs), min(ys), max(xe) - min(xs), max(ye) - min(ys)
    k = 1800 / max(bw, bh)
    w, h = 2048, int(math.ceil((bh * k + 240) / 16) * 16)
    org = ((w - bw * k) / 2 - bx * k, 180 - by * k)
    ref = _paper(w, h)
    layer_map = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    layers_meta = {}
    for i, l in enumerate(skin.layers):
        (x0, y0), (sx, sy) = l["origin"], l["px"]
        s = sx * k
        im = l["img"].resize((round(l["img"].width * s), round(l["img"].height * sy * k)), Image.LANCZOS)
        pos = (round(org[0] + x0 * k), round(org[1] + y0 * k))
        ref.alpha_composite(im, pos)
        tinted = np.array(im)
        tinted[..., :3] = LAYER_COLORS[i]
        layer_map.alpha_composite(Image.fromarray(tinted, "RGBA"), pos)
        if i == 0:
            far_layer = (Image.fromarray(tinted, "RGBA"), pos)
        layers_meta[row["katmanlar"][i]] = {"doku": l["name"], "konum": list(pos), "boyut": list(im.size),
                                            "asil": list(l["img"].size)}
    # Uzak bacaklar gövdenin arkasında kalıyor: haritada ve referansta hatları görünsün.
    edge = np.array(far_layer[0])[..., 3] > 0
    ring = edge & ~np.array(Image.fromarray(edge.astype(np.uint8) * 255).filter(
        __import__("PIL.ImageFilter").ImageFilter.MinFilter(7))).astype(bool)
    outline = np.zeros(edge.shape + (4,), np.uint8)
    outline[ring] = LAYER_COLORS[0] + (255,)
    for target in (ref, layer_map):
        target.alpha_composite(Image.fromarray(outline, "RGBA"), far_layer[1])
    _header(ref, row, "Siluet şablondan taşmasın; oyun bu deriyi kemiklerle büküyor. Mavi hat: gövdenin arkasındaki uzak bacaklar.")
    _legend(layer_map, row["katmanlar"])
    _save_set(out, row, ref, layer_map)
    meta[row["id"]] = {"tip": "beast", "tuval": [w, h], "katmanlar": layers_meta}


def rider(row: dict, out: Path, meta: dict) -> None:
    order = ["atli_K", "atli_KD", "atli_D", "atli_GD", "atli_G", "atli_GB", "atli_B", "atli_KB"]
    tr = {"K": "kuzey", "D": "doğu", "G": "güney", "B": "batı"}
    ref = _paper(2048, 1024)
    d = ImageDraw.Draw(ref)
    cells = {}
    for i, name in enumerate(order):
        x, y = (i % 4) * 512, (i // 4) * 512
        im = Image.open(A / "map" / "rider" / (name + ".png")).convert("RGBA").resize((448, 448), Image.LANCZOS)
        ref.alpha_composite(im, (x + 32, y + 32))
        d.rectangle((x + 2, y + 2, x + 509, y + 509), outline=GUIDE + (255,), width=2)
        d.text((x + 12, y + 8), name + " (" + "-".join(tr[c] for c in name[5:]) + ")", font=font(22), fill=GUIDE + (255,))
        cells[name] = [x + 32, y + 32, 448, 448]
    _header(ref, row, compact=True)
    _save_set(out, row, ref, None)
    meta[row["id"]] = {"tip": "rider", "tuval": [2048, 1024], "kutular": cells, "asil": [128, 128]}


# --- eşyalar ---------------------------------------------------------------

def prop(row: dict, out: Path, meta: dict) -> None:
    pid = row["kaynak_dosya"]
    spec = props_sheet()[pid]
    imgs = {}
    for lname, (ox, oy) in spec["layers"].items():
        imgs[lname] = (Image.open(A / "props" / pid / (lname + ".png")).convert("RGBA"), (ox, oy))
    x0 = min(o[0] for _, o in imgs.values()); y0 = min(o[1] for _, o in imgs.values())
    x1 = max(o[0] + im.width for im, o in imgs.values()); y1 = max(o[1] + im.height for im, o in imgs.values())
    longest = 3780 if pid.startswith("gate_") or pid == "city_gate" else 1900
    k = min(4.0, longest / max(x1 - x0, y1 - y0))
    margin = 140
    w = int(math.ceil(((x1 - x0) * k + 2 * margin) / 16) * 16)
    h = int(math.ceil(((y1 - y0) * k + 2 * margin + 120) / 16) * 16)
    org = (margin - x0 * k, margin + 120 - y0 * k)
    ref = _paper(w, h)
    layer_map = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(ref)
    lm = {}
    order = ["town", "gate", "body", "load", "canopy", "wheel", "wheel_front", "blades"]
    names = sorted(imgs, key=lambda n: order.index(n) if n in order else 99)
    for i, lname in enumerate(names):
        im, (ox, oy) = imgs[lname]
        s = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
        pos = (round(org[0] + ox * k), round(org[1] + oy * k))
        ref.alpha_composite(s, pos)
        t = np.array(s)
        t[..., :3] = LAYER_COLORS[i]
        layer_map.alpha_composite(Image.fromarray(t, "RGBA"), pos)
        lm[envanter._LAYER_TR.get(lname, lname)] = {"dosya": lname + ".png", "konum": list(pos),
                                                     "boyut": list(s.size), "asil": list(im.size)}
    for i, lname in enumerate(names):
        rect = lm[envanter._LAYER_TR.get(lname, lname)]
        x, y = rect["konum"]; ww, hh = rect["boyut"]
        d.rectangle((x, y, x + ww, y + hh), outline=LAYER_COLORS[i] + (255,), width=2)
    d.line((0, org[1], w, org[1]), fill=GUIDE + (255,), width=3)
    for pname, (px, py) in spec.get("pivots", {}).items():
        cx, cy = org[0] + px * k, org[1] + py * k
        d.line((cx - 14, cy, cx + 14, cy), fill=(200, 40, 40, 255), width=3)
        d.line((cx, cy - 14, cx, cy + 14), fill=(200, 40, 40, 255), width=3)
        d.text((cx + 10, cy + 6), pname, font=font(20), fill=(200, 40, 40, 255))
    _header(ref, row, "Mavi çizgi yer. Kırmızı artı: dönme ve oturma noktaları, yerinde kalsın. Parça kendi çerçevesinde.")
    multi = len(names) > 1
    if multi:
        _legend(layer_map, [envanter._LAYER_TR.get(n, n) for n in names])
    row = dict(row)
    row["katmanlar"] = [envanter._LAYER_TR.get(n, n) for n in names]
    _save_set(out, row, ref, layer_map if multi else None)
    meta[row["id"]] = {"tip": "prop", "tuval": [w, h], "esya": pid, "katmanlar": lm}


# --- tek resimler -----------------------------------------------------------

def _canvas_size(row: dict, src: Image.Image) -> tuple[int, int]:
    t = row["tuval"]
    if "x" in t and t.split("x")[0].isdigit():
        w, h = (int(v) for v in t.split("x"))
        return w, h
    return src.size


def image(row: dict, out: Path, meta: dict) -> None:
    path = A / row["kaynak_dosya"]
    src = Image.open(path).convert("RGBA")
    w, h = _canvas_size(row, src)
    ref = _paper(w, h)
    ref.alpha_composite(src.resize((w, h), Image.LANCZOS))
    if "ui/towns/" in row["kaynak_dosya"]:
        mask = path.parent / "mask.png"
        if mask.exists():
            m = np.array(Image.open(mask).convert("L").resize((w, h), Image.NEAREST)).astype(np.int16)
            edge = (np.abs(np.diff(m, axis=0, prepend=m[:1])) > 0) | (np.abs(np.diff(m, axis=1, prepend=m[:, :1])) > 0)
            edge = np.array(Image.fromarray((edge * 255).astype(np.uint8)).filter(__import__("PIL.ImageFilter").ImageFilter.MaxFilter(5)))
            a = np.array(ref)
            a[edge > 0, :3] = GUIDE
            ref = Image.fromarray(a, "RGBA")
    d = ImageDraw.Draw(ref)
    d.rectangle((0, 0, w - 1, h - 1), outline=GUIDE + (255,), width=3)
    extra = "Mavi hatlar tıklama alanlarının sınırı: binaların dış hatları bu çizgilerde kalsın." if "ui/towns/" in row["kaynak_dosya"] else ""
    _header(ref, row, extra, compact=True)
    _save_set(out, row, ref, None)
    meta[row["id"]] = {"tip": "image", "tuval": [w, h], "hedef": "data/assets/" + row["kaynak_dosya"],
                       "asil": list(src.size), "saydam": path.suffix == ".png"}


def strip(row: dict, out: Path, meta: dict) -> None:
    image(row, out, meta)
    p = out / ("%s_ref.jpg" % row["id"])
    ref = Image.open(p).convert("RGBA")
    d = ImageDraw.Draw(ref)
    f = font(max(20, ref.height // 30))
    d.line((6, 0, 6, ref.height), fill=(200, 40, 40, 255), width=6)
    d.line((ref.width - 7, 0, ref.width - 7, ref.height), fill=(200, 40, 40, 255), width=6)
    d.text((20, ref.height // 2), "<- sağ kenara bağlanır", font=f, fill=(200, 40, 40, 255))
    d.text((ref.width - 20 - f.getlength("sol kenara bağlanır ->"), ref.height // 2),
           "sol kenara bağlanır ->", font=f, fill=(200, 40, 40, 255))
    ref.convert("RGB").save(p, quality=82)
    meta[row["id"]]["tip"] = "strip"


def world_map(row: dict, out: Path, meta: dict) -> None:
    r, c = (int(v) for v in row["kaynak_dosya"].split(","))
    ref = _paper(2048, 2048)
    for dy in range(2):
        for dx in range(2):
            tile = A / "map" / "tiles" / "3" / ("%d_%d.jpg" % (c * 2 + dx, r * 2 + dy))
            try:
                ref.paste(Image.open(tile).convert("RGBA"), (dx * 1024, dy * 1024))
            except Exception:
                pass
    d = ImageDraw.Draw(ref)
    d.rectangle((0, 0, 2047, 2047), outline=GUIDE + (255,), width=4)
    _header(ref, row, compact=True)
    _save_set(out, row, ref, None)
    meta[row["id"]] = {"tip": "map", "tuval": [2048, 2048], "satir": r, "sutun": c, "seviye": 3}


def blank(row: dict, out: Path, meta: dict) -> None:
    w, h = (int(v) for v in row["tuval"].split("x"))
    ref = _paper(w, h)
    d = ImageDraw.Draw(ref)
    names = row["katmanlar"]
    n = len(names)
    cols = min(n, 3 if w <= h else 4) if n > 1 else 1
    rows_ = math.ceil(n / cols)
    top = 160
    cw, ch = w // cols, (h - top) // rows_
    boxes = {}
    for i, name in enumerate(names):
        x, y = (i % cols) * cw, top + (i // cols) * ch
        d.rectangle((x + 8, y + 8, x + cw - 8, y + ch - 8), outline=LAYER_COLORS[i % 8] + (255,), width=3)
        d.line((x + 24, y + ch - 60, x + cw - 24, y + ch - 60), fill=GUIDE + (255,), width=2)
        if n > 1:
            d.text((x + 20, y + 14), "%d %s" % (i + 1, name), font=font(26), fill=LAYER_COLORS[i % 8] + (255,))
        boxes[name] = [x + 8, y + 8, cw - 16, ch - 16]
    _header(ref, row, "Referans yok, serbest çizim. " + row["ne_cizilecek"])
    _save_set(out, row, ref, None)
    if n > 1:
        _psd(out / ("%s.psd" % row["id"]), row, ref, Image.new("RGBA", ref.size, (0, 0, 0, 0)))
    meta[row["id"]] = {"tip": "blank", "tuval": [w, h], "kutular": boxes}


def _readmes(rows: list[dict], out_root: Path) -> None:
    by_group: dict[str, list[dict]] = {}
    for row in rows:
        by_group.setdefault(ZIP_GROUPS[row["kategori"]], []).append(row)
    for group, items in by_group.items():
        folder = out_root / group
        if not folder.exists():
            continue
        lines = ["Wayborne el çizimi şablonları - %s" % group, "",
                 "Süreç: docs/el_cizimi/SUREC.md. Takip: docs/el_cizimi/el_cizimi_takip.xlsx.",
                 "Teslim adı: <KİMLİK>.psd (çok katmanlı) ya da <KİMLİK>.png (tek katman), şablondaki kimlikle aynı.",
                 ""]
        for r in items:
            lines.append("%s  |  %s  |  tuval %s  |  %s" % (r["id"], r["ad"], r["tuval"], r["teslim"]))
            if len(r["katmanlar"]) > 1:
                lines.append("    katmanlar (alttan üste): " + ", ".join(r["katmanlar"]))
            lines.append("    " + r["ne_cizilecek"] + (("  " + r["renk"]) if r["renk"] != envanter.RENK else ""))
        (folder / "OKU_BENI.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


BUILDERS = {"figure": figure, "beast": beast, "rider": rider, "prop": prop, "image": image, "strip": strip,
            "map": world_map, "blank": blank, "blank_square": blank}


def main(argv: list[str]) -> None:
    out_root = Path(argv[0])
    only = []
    if "--only" in argv:
        only = argv[argv.index("--only") + 1:]
        only = [o for o in only if not o.startswith("--")]
    rows = envanter.all_rows()
    meta = json.loads(META_PATH.read_text(encoding="utf-8")) if META_PATH.exists() and only else {}
    for row in rows:
        if only and not any(row["id"].startswith(o) for o in only):
            continue
        group = ZIP_GROUPS[row["kategori"]]
        BUILDERS[row["sablon_tip"]](row, out_root / group, meta)
        row["sablon"] = "%s.zip / %s_ref.jpg" % (group, row["id"])
        print(row["id"], flush=True)
    META_PATH.write_text(json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    _readmes(rows, out_root)
    if "--no-zip" in argv:
        return
    for group in sorted(set(ZIP_GROUPS.values())):
        folder = out_root / group
        if not folder.exists():
            continue
        with zipfile.ZipFile(out_root / (group + ".zip"), "w", zipfile.ZIP_DEFLATED) as z:
            for f in sorted(folder.iterdir()):
                z.write(f, f.name)
        print("zip", group)


if __name__ == "__main__":
    main(sys.argv[1:])
