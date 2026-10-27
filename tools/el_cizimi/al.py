"""Tabletten gelen el çizimlerini doğrular ve oyuna işler.

Çizer dosyayı GitHub'da `art_source/el_cizimi/gelen/` klasörüne yükler
(SUREC.md, "Yükleme"). Bu araç:
  1. her dosyanın adından kimliği okur (<KİMLİK>.psd, <KİMLİK>.png ya da
     <KİMLİK>__<katman>.png) ve envanterde arar,
  2. tuval oranını, katman adlarını ve saydamlığı şablonla karşılaştırır,
  3. çizimi şablonun tuvaline ölçekler ve `art_source/el_cizimi/islenmis/<KİMLİK>/`
     altına katman katman yazar (elde edilen el çiziminin kalıcı kaynağı),
  4. türüne göre oyunun dosyasına işler (resim, yol şeridi, eşya katmanları,
     hayvan derisi, harita karoları, atlı); figürler kemik hattına girer,
  5. aslını `art_source/el_cizimi/arsiv/` altına taşır ve Excel'de durumu
     "Oyunda" yapar.

    python3 -I tools/el_cizimi/al.py            # işle
    python3 -I tools/el_cizimi/al.py --dene     # yalnızca doğrula, hiçbir şeye yazma

Oyuna işlemek bir kontrolün yerini tutmaz: ardından ilgili ekranın görüntüsü
alınır (CLAUDE.md, "A task is done when the screen shows it").
"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import envanter  # noqa: E402
from ortak import A, ROOT  # noqa: E402

GELEN = ROOT / "art_source" / "el_cizimi" / "gelen"
ISLENMIS = ROOT / "art_source" / "el_cizimi" / "islenmis"
ARSIV = ROOT / "art_source" / "el_cizimi" / "arsiv"
META = json.loads((Path(__file__).resolve().parent / "sablonlar.json").read_text(encoding="utf-8"))
SKIP_LAYERS = {"referans", "katman_haritasi", "arka_plan", "arkaplan", "background", "kagit"}
RATIO_TOLERANCE = 0.01
MIN_SHARE = 0.5
SEAM_PX = 48


class Report:
    def __init__(self) -> None:
        self.lines: list[str] = []
        self.applied: list[str] = []

    def say(self, rid: str, level: str, text: str) -> None:
        self.lines.append("%-6s %-28s %s" % (level, rid, text))


# --- okuma -----------------------------------------------------------------

def _read_drawing(paths: list[Path], canvas: tuple[int, int], rep: Report, rid: str) -> dict[str, Image.Image] | None:
    """Katman adı -> şablon tuvali boyutunda RGBA resim."""
    layers: dict[str, Image.Image] = {}
    size = None
    for path in paths:
        if path.suffix.lower() == ".psd":
            from psd_tools import PSDImage
            psd = PSDImage.open(path)
            size = psd.size
            wanted = set(META.get(rid, {}).get("katmanlar", {})) | set(_row_layers(rid))
            for name, img in _psd_layers(psd, wanted):
                if name in layers:
                    layers[name].alpha_composite(img)
                else:
                    layers[name] = img
        else:
            img = Image.open(path).convert("RGBA")
            size = img.size
            name = path.stem.split("__", 1)[1].lower() if "__" in path.stem else "cizim"
            layers[name] = img
    if size is None:
        return None
    cw, ch = canvas
    if abs(size[0] / size[1] - cw / ch) > RATIO_TOLERANCE * cw / ch:
        rep.say(rid, "HATA", "tuval oranı şablonla aynı değil: %dx%d, beklenen %dx%d (ya da aynı oranda)" % (*size, cw, ch))
        return None
    if size[0] < cw * MIN_SHARE:
        rep.say(rid, "HATA", "tuval çok küçük: %dx%d, en az %dx%d" % (*size, int(cw * MIN_SHARE), int(ch * MIN_SHARE)))
        return None
    out = {}
    for name, img in layers.items():
        if img.size != (cw, ch):
            img = img.resize((cw, ch), Image.LANCZOS)
        if np.array(img)[..., 3].max() == 0:
            continue
        out[name] = img
    return out


def _row_layers(rid: str) -> list[str]:
    for r in envanter.all_rows():
        if r["id"] == rid:
            return r["katmanlar"]
    return []


def _psd_layers(psd, wanted: set):
    """(ad, resim) çiftleri. Adı istenen bir katman olan klasör (grup) tek
    katman sayılır: çizer bir parçanın çizgisini ve rengini o adlı bir
    klasörde ayrı katmanlarda tutabilir."""
    def walk(node):
        for layer in node:
            name = layer.name.strip().lower()
            if name in SKIP_LAYERS or not layer.is_visible():
                continue
            if layer.is_group() and name not in wanted:
                yield from walk(layer)
                continue
            img = layer.composite(viewport=(0, 0, psd.width, psd.height))
            if img is not None:
                yield name, img.convert("RGBA")
    yield from walk(psd)


def _group_files() -> dict[str, list[Path]]:
    groups: dict[str, list[Path]] = {}
    if not GELEN.exists():
        return groups
    for p in sorted(GELEN.iterdir()):
        if p.suffix.lower() not in (".psd", ".png") or p.name.startswith("."):
            continue
        rid = p.stem.split("__", 1)[0]
        groups.setdefault(rid, []).append(p)
    return groups


# --- oyuna işleme ------------------------------------------------------------

def _flatten(layers: dict[str, Image.Image], order: list[str]) -> Image.Image:
    names = [n for n in order if n in layers] + [n for n in layers if n not in order]
    base = Image.new("RGBA", next(iter(layers.values())).size, (0, 0, 0, 0))
    for n in names:
        base.alpha_composite(layers[n])
    return base


def _save_like(img: Image.Image, target: Path, transparent: bool) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.suffix.lower() == ".jpg":
        img.convert("RGB").save(target, quality=92)
    else:
        img.save(target, optimize=True)


def apply_image(rid, meta, layers, row, rep) -> bool:
    flat = _flatten(layers, row["katmanlar"])
    if meta.get("saydam"):
        a = np.array(flat)[..., 3]
        corners = [a[0, 0], a[0, -1], a[-1, 0], a[-1, -1]]
        if min(corners) == 255 and a.min() == 255:
            rep.say(rid, "UYARI", "saydam olması gereken resim tamamen opak (arka plan katmanı gizlenmemiş olabilir)")
    out = flat.resize(tuple(meta["asil"]), Image.LANCZOS)
    if meta["tip"] == "strip":
        out = _seamless(out)
    _save_like(out, ROOT / meta["hedef"], meta.get("saydam", False))
    return True


def _seamless(img: Image.Image) -> Image.Image:
    """Şeridin sol ve sağ kenarını birbirine karıştırır: döşendiğinde dikiş kalmasın."""
    a = np.array(img).astype(np.float32)
    n = min(SEAM_PX, a.shape[1] // 8)
    w = np.linspace(0.0, 1.0, n)[None, :, None]
    left, right = a[:, :n].copy(), a[:, -n:].copy()
    mid = (left + right) / 2
    a[:, :n] = left * w + mid * (1 - w)
    a[:, -n:] = right * (1 - w) + mid * w
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")


def apply_parts(rid, meta, layers, row, rep, folder: Path, file_key: str) -> bool:
    ok = True
    for lname, spec in meta["katmanlar"].items():
        if lname not in layers:
            rep.say(rid, "UYARI", "katman yok: %s (eski resim yerinde kalıyor)" % lname)
            ok = False
            continue
        x, y = spec["konum"]
        w, h = spec["boyut"]
        part = layers[lname].crop((x, y, x + w, y + h))
        outside = np.array(layers[lname])[..., 3].sum() - np.array(part)[..., 3].sum()
        if outside > 0.02 * max(1, np.array(layers[lname])[..., 3].sum()):
            rep.say(rid, "UYARI", "%s katmanının bir kısmı çerçevesinin dışında kaldı ve kesildi" % lname)
        part = part.resize(tuple(spec["asil"]), Image.LANCZOS)
        _save_like(part, folder / spec[file_key], True)
    return ok


def apply_rider(rid, meta, layers, row, rep) -> bool:
    flat = _flatten(layers, row["katmanlar"])
    for name, (x, y, w, h) in meta["kutular"].items():
        part = flat.crop((x, y, x + w, y + h)).resize(tuple(meta["asil"]), Image.LANCZOS)
        _save_like(part, A / "map" / "rider" / (name + ".png"), True)
    return True


def apply_map(rid, meta, layers, row, rep) -> bool:
    flat = _flatten(layers, row["katmanlar"]).convert("RGB")
    r, c = meta["satir"], meta["sutun"]
    tiles = A / "map" / "tiles"
    for dy in range(2):
        for dx in range(2):
            tile = flat.crop((dx * 1024, dy * 1024, dx * 1024 + 1024, dy * 1024 + 1024))
            tx, ty = c * 2 + dx, r * 2 + dy
            tile.save(tiles / "3" / ("%d_%d.jpg" % (tx, ty)), quality=90)
            big = tile.resize((2048, 2048), Image.LANCZOS)
            for sy in range(2):
                for sx in range(2):
                    big.crop((sx * 1024, sy * 1024, sx * 1024 + 1024, sy * 1024 + 1024)).save(
                        tiles / "4" / ("%d_%d.jpg" % (tx * 2 + sx, ty * 2 + sy)), quality=90)
    _rebuild_low_levels(tiles)
    return True


def _rebuild_low_levels(tiles: Path) -> None:
    mosaic = Image.new("RGB", (8192, 8192))
    for y in range(8):
        for x in range(8):
            p = tiles / "3" / ("%d_%d.jpg" % (x, y))
            if p.exists() and p.stat().st_size > 1000:
                mosaic.paste(Image.open(p).convert("RGB"), (x * 1024, y * 1024))
    for level in (2, 1, 0):
        n = 2 ** level
        scaled = mosaic.resize((n * 1024, n * 1024), Image.LANCZOS)
        for y in range(n):
            for x in range(n):
                scaled.crop((x * 1024, y * 1024, x * 1024 + 1024, y * 1024 + 1024)).save(
                    tiles / str(level) / ("%d_%d.jpg" % (x, y)), quality=90)


def apply_hold(rid, meta, layers, row, rep) -> bool:
    if meta["tip"] == "figure":
        rep.say(rid, "BEKLE", "figür: katmanlar islenmis/ altında; kemik hattı (figur_deri.py) bedenle birlikte kurulur")
    else:
        rep.say(rid, "BEKLE", "yeni parça: islenmis/ altında; oyuna bağlanması kod işi (Excel: Koda bağlantı gerekir)")
    return False


def process(dry: bool) -> Report:
    rep = Report()
    rows = {r["id"]: r for r in envanter.all_rows()}
    sheet = GELEN / "el_cizimi_takip.xlsx"
    if sheet.exists() and not dry:
        # Çizerin kendi güncel takip dosyası: onun girdileri esas, "Oyunda" işaretleri üstüne eklenir.
        shutil.move(str(sheet), envanter.ROOT / "docs" / "el_cizimi" / "el_cizimi_takip.xlsx")
        rep.say("takip", "TAMAM", "çizerin Excel dosyası alındı")
    for rid, paths in _group_files().items():
        if rid not in rows or rid not in META:
            rep.say(rid, "HATA", "bu kimlik envanterde yok; dosya adını şablondaki kimlikle aynı yap")
            continue
        row, meta = rows[rid], META[rid]
        layers = _read_drawing(paths, tuple(meta["tuval"]), rep, rid)
        if layers is None:
            continue
        if not layers:
            rep.say(rid, "HATA", "çizim boş (bütün katmanlar saydam)")
            continue
        expected = set(row["katmanlar"]) if len(row["katmanlar"]) > 1 else set()
        if meta["tip"] in ("prop", "beast"):
            expected = set(meta["katmanlar"])
        allowed = set(expected)
        if meta["tip"] == "figure":
            allowed = set(meta["katmanlar"])
            expected = set(meta.get("dolu", meta["katmanlar"]))
        missing = sorted(expected - set(layers))
        extra = sorted(set(layers) - allowed) if allowed else []
        if missing:
            rep.say(rid, "UYARI", "eksik katman: " + ", ".join(missing))
        if extra:
            rep.say(rid, "UYARI", "tanınmayan katman (yok sayıldı): " + ", ".join(extra))
            for e in extra:
                layers.pop(e)
        if dry:
            rep.say(rid, "TAMAM", "doğrulandı (%d katman)" % len(layers))
            continue
        store = ISLENMIS / rid
        store.mkdir(parents=True, exist_ok=True)
        for name, img in layers.items():
            img.save(store / (name + ".png"), optimize=True)
        tip = meta["tip"]
        if tip in ("image", "strip"):
            done = apply_image(rid, meta, layers, row, rep)
        elif tip == "prop":
            done = apply_parts(rid, meta, layers, row, rep, A / "props" / meta["esya"], "dosya")
        elif tip == "beast":
            done = apply_parts(rid, meta, layers, row, rep, A / "characters" / "beasts" / rid.removeprefix("HAY-"), "doku")
        elif tip == "rider":
            done = apply_rider(rid, meta, layers, row, rep)
        elif tip == "map":
            done = apply_map(rid, meta, layers, row, rep)
        else:
            done = apply_hold(rid, meta, layers, row, rep)
        ARSIV.mkdir(parents=True, exist_ok=True)
        for p in paths:
            shutil.move(str(p), ARSIV / p.name)
        if done:
            rep.applied.append(rid)
            rep.say(rid, "OYUNDA", row["hedef"])
    if rep.applied and not dry:
        subprocess.run([sys.executable, "-I", str(Path(__file__).resolve().parent / "takip_excel.py"), "--oyunda",
                        *rep.applied], check=False)
    return rep


if __name__ == "__main__":
    r = process("--dene" in sys.argv)
    print("\n".join(r.lines) if r.lines else "gelen/ klasöründe işlenecek dosya yok")
