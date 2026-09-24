#!/usr/bin/env python3
"""Waybook asset pipeline: art_source/waybook/*.jpg -> data/assets/ui/waybook/*.png

The generated art arrives as JPGs on a flat mid-grey backdrop (no alpha).
This script is the one place that turns a raw sheet into what the game
loads: background keyed out to alpha, cropped, and scaled so a nine-slice
border lands at a sensible on-screen thickness. Colour is never repainted
here - tinting belongs to ArtPalette at runtime.

Run from the repository root:  python3 tools/waybook_assets.py
Requires: Pillow, numpy, scipy.
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "art_source/waybook"
OUT = "data/assets/ui/waybook"

# Distance (0-255 RGB, euclidean) from the backdrop colour that counts as
# backdrop, and the width of the soft ramp beyond it. The ramp keeps the
# ink edges anti-aliased instead of cut out with scissors.
KEY_HARD = 14.0
KEY_SOFT = 26.0
# Backdrop is a neutral grey: anything noticeably saturated is art, even
# if its brightness happens to match.
KEY_MAX_CHROMA = 12.0


def _load(name: str) -> np.ndarray:
    return np.asarray(Image.open(os.path.join(SRC, name)).convert("RGB")).astype(np.float32)


def _backdrop_colour(rgb: np.ndarray) -> np.ndarray:
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    return np.median(border, axis=0)


def key(rgb: np.ndarray, seeds: list[tuple[int, int]] | None = None) -> np.ndarray:
    """Return RGBA with the grey backdrop removed.

    Only backdrop pixels *connected* to a seed are removed (the image
    border by default, plus any extra seeds such as a frame's hollow
    centre), so a grey that happens to sit inside the art survives.
    """
    bg = _backdrop_colour(rgb)
    dist = np.sqrt(((rgb - bg) ** 2).sum(axis=2))
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    candidate = (dist < KEY_HARD + KEY_SOFT) & (chroma < KEY_MAX_CHROMA)

    labels, _ = ndimage.label(candidate)
    keep = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    for (y, x) in seeds or []:
        keep.add(labels[y, x])
    keep.discard(0)
    connected = np.isin(labels, list(keep))

    alpha = np.clip((dist - KEY_HARD) / KEY_SOFT, 0.0, 1.0)
    alpha = np.where(connected, alpha, 1.0)
    # De-fringe: pull semi-transparent edge pixels away from the grey so a
    # dark ground behind them does not show a light halo.
    a = alpha[..., None]
    safe = np.maximum(a, 1e-3)
    unpremul = (rgb - bg * (1.0 - a)) / safe
    rgb_out = np.where(a < 1.0, np.clip(unpremul, 0, 255), rgb)
    return np.dstack([rgb_out, alpha * 255.0]).astype(np.uint8)


def crop_to_alpha(rgba: np.ndarray, pad: int = 2) -> np.ndarray:
    ys, xs = np.nonzero(rgba[..., 3] > 8)
    y0, y1 = max(0, ys.min() - pad), min(rgba.shape[0], ys.max() + pad + 1)
    x0, x1 = max(0, xs.min() - pad), min(rgba.shape[1], xs.max() + pad + 1)
    return rgba[y0:y1, x0:x1]


def save(rgba: np.ndarray, name: str, size: tuple[int, int] | None = None) -> None:
    img = Image.fromarray(rgba, "RGBA" if rgba.shape[2] == 4 else "RGB")
    if size is not None:
        img = img.resize(size, Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name), optimize=True)
    print(f"  {name:28s} {img.size[0]}x{img.size[1]}")


def scale_to_width(rgba: np.ndarray, width: int) -> tuple[int, int]:
    h, w = rgba.shape[:2]
    return width, max(1, round(h * width / w))


def make_tile(rgb: np.ndarray, size: int) -> np.ndarray:
    """Make a texture seamless by cross-fading it with its half-offset copy.

    The generated "tileable" sheets are not actually periodic; blending the
    image with a copy rolled by half its size, weighted towards the copy at
    the edges, puts the original seam in the middle of a smooth region.
    """
    h, w = rgb.shape[:2]
    rolled = np.roll(np.roll(rgb, h // 2, axis=0), w // 2, axis=1)
    yy = np.abs(np.linspace(-1.0, 1.0, h))[:, None]
    xx = np.abs(np.linspace(-1.0, 1.0, w))[None, :]
    weight = np.clip(np.maximum(yy, xx) ** 3, 0.0, 1.0)[..., None]
    out = rgb * (1.0 - weight) + rolled * weight
    img = Image.fromarray(out.astype(np.uint8), "RGB").resize((size, size), Image.LANCZOS)
    return np.asarray(img)


def declasp(rgba: np.ndarray, corner: int, plain: int) -> np.ndarray:
    """Rebuild the seal frame as corners + a mirrored plain strip per side.

    The seal frame was painted with a clasp in the middle of every side. A
    nine-slice edge is stretched or tiled, so a clasp there becomes either a
    smeared bar or a row of clasps; the brass corners carry the "sealed"
    read on their own. Each side's edge becomes a strip taken just past the
    corner plate followed by its mirror image, so the theme can tile it
    without a visible seam. The output is 2*corner + 2*plain square-ish.
    """
    h, w = rgba.shape[:2]
    def strip_x(block: np.ndarray) -> np.ndarray:
        s = block[:, corner:corner + plain]
        return np.concatenate([s, s[:, ::-1]], axis=1)
    def strip_y(block: np.ndarray) -> np.ndarray:
        s = block[corner:corner + plain]
        return np.concatenate([s, s[::-1]], axis=0)
    top = np.concatenate([rgba[:corner, :corner], strip_x(rgba[:corner]), rgba[:corner, w - corner:]], axis=1)
    bottom = np.concatenate([rgba[h - corner:, :corner], strip_x(rgba[h - corner:]), rgba[h - corner:, w - corner:]], axis=1)
    left = strip_y(rgba[:, :corner])
    right = strip_y(rgba[:, w - corner:])
    centre = np.zeros((plain * 2, plain * 2, 4), dtype=rgba.dtype)
    middle = np.concatenate([left, centre, right], axis=1)
    return np.concatenate([top, middle, bottom], axis=0)


def seam_error(rgb: np.ndarray) -> float:
    """Mean jump across the wrap edges, relative to the mean jump inside."""
    a = rgb.astype(np.float32)
    inner = np.abs(np.diff(a, axis=1)).mean() + np.abs(np.diff(a, axis=0)).mean()
    wrap = np.abs(a[:, 0] - a[:, -1]).mean() + np.abs(a[0] - a[-1]).mean()
    return float(wrap / max(inner, 1e-6))


def phase1() -> None:
    print("Phase 1 - global chrome")
    for src, name in [("G1_page_surface.jpg", "g1_page_tile.png"),
                      ("G10_grain_stain_overlay.jpg", "g10_grain_tile.png")]:
        tile = make_tile(_load(src), 512)
        print(f"  {src}: seam ratio before {seam_error(_load(src)):.2f}, after {seam_error(tile):.2f}")
        save(tile, name)

    # Grain as a *mask*, not a picture: black specks whose alpha is how
    # dark the stain sheet was. The game lays it over a panel fill whose
    # colour comes from ArtPalette, so the grain never decides a colour.
    grain = make_tile(_load("G10_grain_stain_overlay.jpg"), 256).astype(np.float32)
    luma = grain.mean(axis=2)
    alpha = np.clip((np.percentile(luma, 97) - luma) / 70.0, 0.0, 1.0) * 150.0
    mask = np.dstack([np.zeros_like(luma)] * 3 + [alpha]).astype(np.uint8)
    save(mask, "g10_grain_mask.png")

    # Frames: key the outside *and* the hollow centre.
    for src, name, width in [("G2_binding_frame.jpg", "g2_binding.png", 256),
                             ("G3_seal_frame.jpg", "g3_seal.png", 256)]:
        rgb = _load(src)
        h, w = rgb.shape[:2]
        rgba = crop_to_alpha(key(rgb, seeds=[(h // 2, w // 2)]))
        if name == "g3_seal.png":
            img = Image.fromarray(rgba, "RGBA").resize(scale_to_width(rgba, width), Image.LANCZOS)
            rgba = declasp(np.asarray(img).copy(), corner=78, plain=26)
            save(rgba, name)
        else:
            save(rgba, name, scale_to_width(rgba, width))

    rgba = crop_to_alpha(key(_load("G4_button_tab.jpg")))
    save(rgba, "g4_tab.png", scale_to_width(rgba, 240))

    rgba = crop_to_alpha(key(_load("G5_disabled_scratchout.jpg")))
    save(rgba, "g5_scratch.png", scale_to_width(rgba, 240))

    rgba = crop_to_alpha(key(_load("G6_ink_rule_separator.jpg")))
    save(rgba, "g6_rule.png", scale_to_width(rgba, 420))

    # The ribbon sheet holds both scrollbar parts side by side: the groove
    # (stitched leather strip) and the ribbon that hangs through it.
    rgba = crop_to_alpha(key(_load("G7_scrollbar_ribbon.jpg")))
    save(rgba, "g7_scroll.png", scale_to_width(rgba, 18))

    rgba = crop_to_alpha(key(_load("G8_tooltip_slip.jpg")))
    save(rgba, "g8_slip.png", scale_to_width(rgba, 200))

    for src, name in [("G9_wax_seal_intact.jpg", "g9_seal.png"),
                      ("G9b_wax_seal_cracked.jpg", "g9b_seal_cracked.png")]:
        rgba = crop_to_alpha(key(_load(src)))
        save(rgba, name, scale_to_width(rgba, 192))

    for src, name in [("G11b_danger_edge_frost.jpg", "g11_edge_bleed.png"),
                      ("G11c_danger_edge_scorch.jpg", "g11_edge_scorch.png")]:
        rgb = _load(src)
        h, w = rgb.shape[:2]
        rgba = key(rgb, seeds=[(h // 2, w // 2)])
        save(rgba, name, (1280, 720))


if __name__ == "__main__":
    if not os.path.isdir(SRC):
        sys.exit("run from the repository root")
    phase1()
