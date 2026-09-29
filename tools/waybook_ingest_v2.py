#!/usr/bin/env python3
"""Second Waybook art pass: art_source/waybook_v2/*.png|.jpg -> data/assets/ui/waybook/*

The first pass (`waybook_assets.py`) reads raw grey-backdrop sheets named by
their *prompt id* (`B1_guild_bg.jpg`) and keys/crops/resizes them into the
final, *output*-named files the game loads. This second delivery arrived
already named by **output** filename (`b1_guild.jpg`, `p3_strength.png`, ...)
and, for every icon, already carrying a real alpha channel - the sender ran
their own background removal before handing the files over. So this script
does a narrower job than the first pass: crop the alpha to content, scale to
the size the sibling already committed under that name, and - only where the
delivered alpha still hides a leftover backdrop card - key that card out
too. It reuses `waybook_assets.py`'s own `crop_to_alpha`/`unpaper` rather
than reinventing them, same reasoning as `ArtDraw` being the one brush: a
crop function written twice is two crop functions.

Three real defects turned up in a full visual pass over the 91 delivered
files (see `docs/wayborne_gorsel_denetim.xlsx`'s "Durum" column for the
complete audit) and are handled explicitly below:

- `item_grain.png`, `k4a_bleed.png`: a flat, unsaturated card (not the
  keyed-away outer grey) survived around the subject. `unpaper()` already
  handles the classic case (a near-white card); `item_grain`'s card was a
  mid grey (~180) below `unpaper`'s `PAPER_MIN`, so it gets a second,
  colour-sampled flood fill (`_key_from_seed`) instead.
- `p4_witnessed_death.png`, `p3_endurance.png`: the same class of leftover
  card, but shaded/gradient rather than flat, so one sampled colour does not
  cover it - `_key_from_seed` is run from several points around the card.
  `p3_endurance` still carries a faint rim afterwards (an inked edge close
  in colour to the card itself resists a colour-distance key); shipped
  anyway since it is a large improvement over the fully opaque original and
  the leftover is a soft fringe, not a solid box.
- `p3_agility.png` and `p5_scout.png` are not processed at all: the
  delivered art does not match its own filename (agility's file is a
  near-duplicate of the strength fist-and-ring image; scout's is a person
  shielding their eyes, not "a hawk perched on a gloved fist" the prompt
  asked for, and it breaks the family's object-not-person convention besides).
  The already-committed originals stay untouched. A wrong picture that
  merely looks clean is worse than a visibly missing one - see this file's
  own audit spreadsheet for what to regenerate.

Run from the repository root:  python3 tools/waybook_ingest_v2.py
Requires: Pillow, numpy, scipy (same as waybook_assets.py).
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import waybook_assets as wa  # noqa: E402  (reuses crop_to_alpha/unpaper/key)

SRC = "art_source/waybook_v2"
OUT = "data/assets/ui/waybook"

# Icons already delivered with a clean alpha channel: crop to content and
# scale the longer side to this many px, matching the family's existing
# on-screen size (unchanged from waybook_assets.py's own icon() calls).
ICON_96 = [
    "item_bandage.png", "item_cloth.png", "item_fish.png", "item_furs.png",
    "item_honey.png", "item_jewelry.png", "item_potion.png",
    "item_provisions.png", "item_silk.png", "item_spice.png", "item_weapon.png",
    "item_wine.png",
    "k4b_blight.png", "k4c_stun.png", "k4d_stun_resist.png", "k4e_buff.png", "k4f_debuff.png",
    "k6a_guard.png", "k6b_hunter.png", "k6c_breaker.png", "k6d_clerk.png",
    "p3_charisma.png", "p3_faith.png", "p3_intellect.png", "p3_perception.png",
    "p3_strength.png", "p3_wisdom.png",
    "p4_benched.png", "p4_passed_over.png", "p4_unfed.png",
    "p5_guard.png", "p5_quartermaster.png", "p5_wagoner.png", "p5_crier.png", "p5_herbalist.png",
    # New family (Faz 22 audit): equipment - same "small icon, alpha already
    # clean" shape as the item_* family, so the same size.
    "eq_amulet_courage.png", "eq_amulet_ward.png", "eq_amulet_wolf_fang.png",
    "eq_armor_tier_1.png", "eq_armor_tier_2.png", "eq_armor_tier_3.png",
    "eq_ring_charmed.png", "eq_ring_gambler.png", "eq_ring_marksman.png",
    "eq_weapon_tier_1.png", "eq_weapon_tier_2.png", "eq_weapon_tier_3.png",
]

# Icons whose delivered alpha still hides a leftover backdrop card: colour
# sampled at `seeds` (row, col) in the *original* 1024-canvas, flood-filled
# out with a generous tolerance before the usual crop+scale.
CARD_FIX = {
    "item_grain.png": {"seeds": [(210, 210)], "tol": 16, "soft": 10, "size": 96},
    "k4a_bleed.png": {"unpaper": True, "size": 96},
    "p4_witnessed_death.png": {
        "seeds": [(110, 110), (110, 900), (900, 110), (900, 900), (500, 110)],
        "tol": 18, "soft": 14, "size": 96,
    },
    "p3_endurance.png": {
        "seeds": [(140, 140), (140, 850), (850, 140), (850, 850), (500, 140), (140, 500)],
        "tol": 20, "soft": 16, "size": 96,
    },
}

# c1/g9/g9b/l2/r9 kept their own historical target size (not the 96 family).
CUSTOM_SIZE = {
    "c1_crepe.png": 160,
    "g9_seal.png": 192,
    "g9b_seal_cracked.png": 192,
    "l2_ribbon.png": 480,
    "r9_strike.png": 480,
}

BACKGROUNDS = [
    "b1_guild.jpg", "b2_market.jpg", "b3_tavern.jpg", "b4_yard.jpg", "b5_church.jpg",
    "b7_planner.jpg", "b8_recruit.jpg", "b9_tent.jpg", "b10_city.jpg", "l1_ledger.jpg",
]

# Event card illustrations (Faz 22's new category A): full bleed, no
# background to remove ("PNG Gerekli mi?" = HAYIR in the prompt sheet) -
# only a consistent size and a lighter JPEG.
EVENT_CARDS_WIDTH = 900


def _load_rgba(name: str) -> np.ndarray:
    return np.asarray(Image.open(os.path.join(SRC, name)).convert("RGBA"))


def _key_from_seed(rgba: np.ndarray, seeds: list[tuple[int, int]], tol: float, soft: float) -> np.ndarray:
    rgb = rgba[..., :3].astype(np.float32)
    out = rgba.astype(np.float32).copy()
    structure = np.ones((3, 3))
    for seed in seeds:
        seed_colour = rgb[seed]
        dist = np.sqrt(((rgb - seed_colour) ** 2).sum(axis=2))
        candidate = dist < (tol + soft)
        labels, _ = ndimage.label(candidate, structure=structure)
        label = labels[seed]
        if label == 0:
            continue
        region = labels == label
        alpha_scale = np.clip((dist - tol) / soft, 0.0, 1.0)
        a = out[..., 3]
        out[..., 3] = np.where(region, np.minimum(a, a * alpha_scale), a)
    return out.astype(np.uint8)


def icon(name: str, size: int) -> None:
    rgba = _load_rgba(name)
    rgba = wa.crop_to_alpha(rgba)
    img = Image.fromarray(rgba, "RGBA")
    h, w = rgba.shape[:2]
    scale = size / max(h, w)
    img = img.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name), optimize=True)
    print(f"  {name:28s} {img.size[0]}x{img.size[1]}")


def fixed_icon(name: str, spec: dict) -> None:
    rgba = _load_rgba(name)
    if spec.get("unpaper"):
        rgba = wa.unpaper(rgba)
    else:
        rgba = _key_from_seed(rgba, spec["seeds"], spec["tol"], spec["soft"])
    rgba = wa.crop_to_alpha(rgba, pad=3)
    img = Image.fromarray(rgba, "RGBA")
    h, w = rgba.shape[:2]
    scale = spec["size"] / max(h, w)
    img = img.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name), optimize=True)
    print(f"  {name:28s} {img.size[0]}x{img.size[1]} (card removed)")


def split_p2_tokens() -> None:
    rgba = _load_rgba("p2_tokens.png")
    pieces = wa.split_components(rgba, 2)
    # Left = the clean gold disc (virtue), right = the corroded one
    # (affliction) - `split_components` already orders left to right.
    for piece, name in zip(pieces, ["p2_virtue.png", "p2_affliction.png"]):
        h, w = piece.shape[:2]
        scale = 96 / max(h, w)
        img = Image.fromarray(piece, "RGBA").resize(
            (max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS
        )
        os.makedirs(OUT, exist_ok=True)
        img.save(os.path.join(OUT, name), optimize=True)
        print(f"  {name:28s} {img.size[0]}x{img.size[1]}")


def background_jpg(name: str) -> None:
    rgb = np.asarray(Image.open(os.path.join(SRC, name)).convert("RGB"))
    img = Image.fromarray(rgb, "RGB")
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name), quality=88, optimize=True)
    print(f"  {name:28s} {img.size[0]}x{img.size[1]}")


def event_card(name: str) -> None:
    rgb = np.asarray(Image.open(os.path.join(SRC, name)).convert("RGB"))
    img = Image.fromarray(rgb, "RGB")
    if img.size[0] != EVENT_CARDS_WIDTH:
        h = round(img.size[1] * EVENT_CARDS_WIDTH / img.size[0])
        img = img.resize((EVENT_CARDS_WIDTH, h), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name), quality=88, optimize=True)
    print(f"  {name:28s} {img.size[0]}x{img.size[1]}")


def b6_map() -> None:
    rgba = _load_rgba("b6_map.png")
    rgba = wa.crop_to_alpha(rgba, pad=2)
    img = Image.fromarray(rgba, "RGBA")
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, "b6_map.png"), optimize=True)
    print(f"  b6_map.png                  {img.size[0]}x{img.size[1]}")


def main() -> None:
    if not os.path.isdir(SRC):
        sys.exit("run from the repository root, after populating " + SRC)

    print("Backgrounds")
    for name in BACKGROUNDS:
        background_jpg(name)

    print("Event card illustrations")
    for name in sorted(f for f in os.listdir(SRC) if f.startswith("e6") and f.endswith(".jpg")):
        event_card(name)

    print("Map")
    b6_map()

    print("Trait tokens (split)")
    split_p2_tokens()

    print("Custom-size icons")
    for name, size in CUSTOM_SIZE.items():
        icon(name, size)

    print("Cards needing their backdrop keyed")
    for name, spec in CARD_FIX.items():
        fixed_icon(name, spec)

    print("Clean-alpha icons (96px family)")
    for name in ICON_96:
        icon(name, 96)


if __name__ == "__main__":
    main()
