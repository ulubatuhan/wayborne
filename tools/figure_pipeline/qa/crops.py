"""Kural 3: gorsel denetim yerel cozunurlukte. Her eklem bolgesinden 2x buyutulmus,
en cok 512 px kirpinti; bir kontak sayfasinda etiketli.

    python3 -I crops.py <frame.png> <joints.json> <out.png> [--bg R,G,B]

joints.json: piksel eklem isaretleri (ayni karede basilan). Gerekli adlar:
neck, front_shoulder, back_shoulder, front_elbow, back_elbow, front_wrist,
back_wrist, front_hip, back_hip, front_knee, back_knee, front_ankle, back_ankle.
"""
import json
import sys

from PIL import Image, ImageDraw

REGIONS = [
    ("boyun", ["neck"]),
    ("omuz on", ["front_shoulder"]), ("omuz arka", ["back_shoulder"]),
    ("dirsek on", ["front_elbow"]), ("dirsek arka", ["back_elbow"]),
    ("bilek+el on", ["front_wrist", "front_fingertip"]), ("bilek+el arka", ["back_wrist", "back_fingertip"]),
    ("kalca on", ["front_hip"]), ("kalca arka", ["back_hip"]),
    ("diz on", ["front_knee"]), ("diz arka", ["back_knee"]),
    ("ayak bilegi on", ["front_ankle"]), ("ayak bilegi arka", ["back_ankle"]),
]
HALF = 64          # kaynakta 128x128 pencere
SCALE = 2          # -> 256 px (<= 512)


def crops(frame_path, joints, bg=(58, 54, 50), markers=False):
    src = Image.open(frame_path).convert("RGBA")
    # Tuval disina tasan pencere (ayak bilegi zemine yakin) bos alfa ile dolup beyaz
    # gorunuyordu; tuvali HALF kadar arka plan rengiyle genislet.
    base = Image.new("RGBA", (src.width + 2 * HALF, src.height + 2 * HALF), bg + (255,))
    base.alpha_composite(src, (HALF, HALF))
    joints = {k: ([v[0] + HALF, v[1] + HALF] if isinstance(v, list) else v) for k, v in joints.items()}
    tiles = []
    for label, names in REGIONS:
        pts = [joints[n] for n in names if n in joints]
        if not pts:
            continue
        cx = sum(p[0] for p in pts) / len(pts)
        cy = sum(p[1] for p in pts) / len(pts)
        box = (int(cx - HALF), int(cy - HALF), int(cx + HALF), int(cy + HALF))
        tile = base.crop(box).resize((HALF * 2 * SCALE, HALF * 2 * SCALE), Image.NEAREST)
        if markers:
            d = ImageDraw.Draw(tile)
            for p in pts:
                x, y = (p[0] - box[0]) * SCALE, (p[1] - box[1]) * SCALE
                d.ellipse([x - 3, y - 3, x + 3, y + 3], outline=(255, 60, 60, 255))
        tiles.append((label, tile))
    return tiles


def sheet(tiles, out_path, cols=5, title=""):
    tw = HALF * 2 * SCALE
    rows = (len(tiles) + cols - 1) // cols
    head = 26 if title else 0
    img = Image.new("RGBA", (cols * (tw + 6) + 6, head + rows * (tw + 26) + 6), (24, 22, 20, 255))
    d = ImageDraw.Draw(img)
    if title:
        d.text((8, 6), title, fill=(230, 220, 200, 255))
    for i, (label, t) in enumerate(tiles):
        x = 6 + (i % cols) * (tw + 6)
        y = head + 6 + (i // cols) * (tw + 26)
        d.text((x, y), label, fill=(230, 220, 200, 255))
        img.paste(t, (x, y + 18))
    img.save(out_path)
    return out_path


if __name__ == "__main__":
    frame, jpath, out = sys.argv[1:4]
    js = json.load(open(jpath))
    sheet(crops(frame, js, markers="--markers" in sys.argv), out, title=frame.split("/")[-1])
