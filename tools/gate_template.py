"""The template a city-gate illustration is painted over.

The gate is the last placeholder left in the walking area: `world_hub.gd`
draws it as a flat `ColorRect` (`GATE_COLOR`, a 150x230 box standing on the
ground line). An illustration can only replace it if it agrees with that
scene about three things, so the template states all three and nothing else:

* **the ground line** - the hub draws every figure standing on `GROUND_Y`,
  so a gate whose foot sits anywhere else floats or sinks;
* **human scale** - the gate reads as a gate only against the people who
  walk through it, so the template carries a real figure at the size the
  hub actually draws one (`CREW_BODY_HEIGHT`, of which `FigureRig` fills
  about 86%);
* **the doorway** - the player walks *to* the gate and presses E inside the
  interaction rect, so the opening has to sit over that rect rather than
  wherever the composition wants it.

    python3 tools/gate_template.py

Writes `docs/gate/gate_template.png` and `docs/gate/gate_palette.png`.
"""

import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "docs", "gate")

# The canvas handed to the painter. Wider and taller than the interaction
# rect on purpose: a city gate is a wall with a hole in it, and the wall has
# to run past the doorway or it reads as a free-standing arch.
CANVAS = (900, 700)
GROUND_Y = 620
# world_hub.gd's own numbers, so the picture and the scene agree by
# construction rather than by eye.
SPOT_W, SPOT_H = 150, 230
PERSON_BOX = 72
PERSON_DRAWN = 62

BACKDROP = (232, 229, 220, 255)
GUIDE = (176, 64, 48, 255)
SOFT = (196, 170, 120, 255)
LABEL = (74, 62, 52, 255)

# ArtPalette, so the painting lands in the game's own colours.
PALETTE = [
    ("INK", (14, 13, 15)),
    ("GOLD", (219, 179, 87)),
    ("GOLD_DIM", (133, 107, 56)),
    ("BLOOD", (168, 48, 43)),
    ("PANEL", (22, 19, 17)),
    ("BONE", (224, 217, 199)),
]


def person(draw, x, label):
    """A stick figure at exactly the height the hub draws one."""
    top = GROUND_Y - PERSON_DRAWN
    head_r = PERSON_DRAWN * 0.085
    cx = x
    draw.ellipse(
        [cx - head_r, top, cx + head_r, top + head_r * 2], outline=LABEL, width=2
    )
    draw.line([cx, top + head_r * 2, cx, GROUND_Y - PERSON_DRAWN * 0.38],
              fill=LABEL, width=2)
    draw.line([cx, GROUND_Y - PERSON_DRAWN * 0.38, cx - 7, GROUND_Y], fill=LABEL, width=2)
    draw.line([cx, GROUND_Y - PERSON_DRAWN * 0.38, cx + 7, GROUND_Y], fill=LABEL, width=2)
    draw.line([cx - 9, GROUND_Y - PERSON_DRAWN * 0.66, cx + 9, GROUND_Y - PERSON_DRAWN * 0.70],
              fill=LABEL, width=2)
    draw.text((cx - 24, GROUND_Y + 8), label, fill=LABEL)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    image = Image.new("RGBA", CANVAS, BACKDROP)
    draw = ImageDraw.Draw(image)

    # Ground line - everything in the hub stands on it.
    draw.line([(0, GROUND_Y), (CANVAS[0], GROUND_Y)], fill=GUIDE, width=3)
    draw.text((8, GROUND_Y + 8), "ZEMIN - kapinin ayagi bu cizgide", fill=GUIDE)

    # The interaction rect: where the player presses E. The doorway goes here.
    spot_x = CANVAS[0] // 2 - SPOT_W // 2
    draw.rectangle(
        [spot_x, GROUND_Y - SPOT_H, spot_x + SPOT_W, GROUND_Y],
        outline=GUIDE, width=2
    )
    draw.text((spot_x + 4, GROUND_Y - SPOT_H - 18), "KAPI ACIKLIGI (150x230)", fill=GUIDE)

    # Height guides, in people.
    for people in (2, 4, 6):
        y = GROUND_Y - PERSON_DRAWN * people
        if y < 10:
            continue
        draw.line([(0, y), (CANVAS[0], y)], fill=SOFT, width=1)
        draw.text((8, y - 14), "%d insan boyu" % people, fill=LABEL)

    person(draw, spot_x - 60, "insan")
    person(draw, spot_x + SPOT_W + 60, "insan")

    image.save(os.path.join(OUT_DIR, "gate_template.png"))
    print("  -> docs/gate/gate_template.png", CANVAS)

    swatch = Image.new("RGBA", (len(PALETTE) * 120, 90), BACKDROP)
    sd = ImageDraw.Draw(swatch)
    for index, (name, rgb) in enumerate(PALETTE):
        x = index * 120
        sd.rectangle([x + 8, 8, x + 112, 62], fill=rgb + (255,), outline=LABEL)
        sd.text((x + 10, 68), "%s #%02X%02X%02X" % ((name,) + rgb), fill=LABEL)
    swatch.save(os.path.join(OUT_DIR, "gate_palette.png"))
    print("  -> docs/gate/gate_palette.png", swatch.size)


if __name__ == "__main__":
    main()
