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
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = "art_source/waybook"
OUT = "data/assets/ui/waybook"

# Distance (0-255 RGB, euclidean) from the backdrop colour that counts as
# backdrop, and the width of the soft ramp beyond it. The ramp keeps the
# ink edges anti-aliased instead of cut out with scissors.
KEY_HARD = 14.0
KEY_SOFT = 26.0
# Danger-edge sheets: how far in the torn paper border reaches, the paper's
# brightness, and how much darker than paper counts as full ink.
EDGE_INSET = 0.035
EDGE_PAPER_LUMA = 205.0
EDGE_INK_RANGE = 150.0
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
    # G1 (page surface) and G10 as a full-colour tile are not shipped: the
    # panels compose their ground from ArtPalette + the grain mask below, so
    # a baked-colour tile would be ~0.7 MB of Web download nothing reads.
    # Seam quality of the tiling itself is still reported.
    for src in ["G1_page_surface.jpg", "G10_grain_stain_overlay.jpg"]:
        tile = make_tile(_load(src), 512)
        print(f"  {src}: seam ratio before {seam_error(_load(src)):.2f}, after {seam_error(tile):.2f} (not shipped)")

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

    # G5 (kilit karalaması) yazılmıyor: oyuncu testinde kilitli düğmenin
    # üstündeki karalama güzel görünmedi, kilit artık yalnızca silik ton.

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

    edge_masks()


## Checkerboard keying: generators hand back "transparent" PNGs as JPGs with
## the editor's grey checkerboard baked in as pixels. The ink is white and
## the checkerboard never rises above ~95 luma, so the alpha is a ramp on
## brightness alone - no backdrop keying, no card to cut off.
CHECKER_LUMA_FLOOR = 110.0
CHECKER_LUMA_RANGE = 110.0
CHECKER_ALPHA_CUTOFF = 10.0


def checker_mask(src: str, name: str) -> None:
    rgb = _load(src).astype(np.float32)
    luma = rgb[..., :3].mean(axis=2)
    alpha = np.clip((luma - CHECKER_LUMA_FLOOR) / CHECKER_LUMA_RANGE, 0.0, 1.0) * 255.0
    # JPG ringing leaves the lighter checker squares a few levels of alpha:
    # stretched over the screen that faint grid reads as a pattern.
    alpha[alpha < CHECKER_ALPHA_CUTOFF] = 0.0
    mask = np.dstack([np.full_like(luma, 255.0)] * 3 + [alpha]).astype(np.uint8)
    save(mask, name)


def edge_masks() -> None:
    # Stress bleed and cold frost: square whole-frame sheets, stretched over
    # the screen as one picture (the player rejected the nine-slice).
    checker_mask("G11a_edge_bleed_v2.jpg", "g11_edge_bleed.png")
    checker_mask("G11b_edge_frost_v2.jpg", "g11_edge_frost.png")
    for src, name in [("G11c_danger_edge_scorch.jpg", "g11_edge_scorch.png")]:
        rgb = _load(src)
        h, w = rgb.shape[:2]
        rgba = crop_to_alpha(key(rgb, seeds=[(h // 2, w // 2)]), pad=0)
        # The sheets were painted on a torn paper card: its white border and
        # the pale wash under the ink are the card, not the stain. Cut the
        # border off so the stain reaches the screen edge, then keep only
        # the ink as a white mask - the game colours it from ArtPalette.
        ch, cw = rgba.shape[:2]
        inset_y, inset_x = round(ch * EDGE_INSET), round(cw * EDGE_INSET)
        rgba = rgba[inset_y:ch - inset_y, inset_x:cw - inset_x].astype(np.float32)
        luma = rgba[..., :3].mean(axis=2)
        ink = np.clip((EDGE_PAPER_LUMA - luma) / EDGE_INK_RANGE, 0.0, 1.0)
        alpha = ink * (rgba[..., 3] / 255.0) * 255.0
        mask = np.dstack([np.full_like(luma, 255.0)] * 3 + [alpha]).astype(np.uint8)
        save(mask, name, (1280, 720))


def disc(rgba: np.ndarray, paper_luma: float = 165.0) -> np.ndarray:
    """Cut a round stud out of the square of paper it was painted on.

    The K5 studs came on a bone-paper plate that keying cannot remove (it
    is not the grey backdrop), so every pip shipped as a beige square - the
    square read as a patch over the map and the skill cards. The stud's
    radius is where the pixels stop being darker than the paper along the
    centre row; outside it alpha falls to zero over a one-pixel edge.
    """
    h, w = rgba.shape[:2]
    cy, cx = h / 2.0, w / 2.0
    luma = rgba[..., :3].astype(np.float32).mean(axis=2)
    row = luma[int(cy)]
    dark = np.nonzero(row < paper_luma)[0]
    radius = (dark.max() - dark.min()) / 2.0 if dark.size else min(h, w) * 0.42
    yy, xx = np.mgrid[0:h, 0:w]
    dist = np.sqrt((yy + 0.5 - cy) ** 2 + (xx + 0.5 - cx) ** 2)
    edge = np.clip(radius + 0.5 - dist, 0.0, 1.0)
    out = rgba.copy().astype(np.float32)
    out[..., 3] = out[..., 3] * edge
    return crop_to_alpha(out.astype(np.uint8), pad=1)


def split_components(rgba: np.ndarray, count: int, min_area: int = 400, grow: int = 6) -> list[np.ndarray]:
    """Split a sheet holding several separate pieces into `count` crops,
    ordered left to right. Pieces are found as connected alpha regions; the
    largest `count` win, so specks of stray ink do not become a piece."""
    mask = rgba[..., 3] > 24
    labels, n = ndimage.label(ndimage.binary_dilation(mask, iterations=grow) if grow else mask)
    areas = ndimage.sum(mask, labels, range(1, n + 1))
    order = [i + 1 for i in np.argsort(areas)[::-1] if areas[i] >= min_area][:count]
    boxes = []
    for label in order:
        ys, xs = np.nonzero(labels == label)
        boxes.append((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    boxes.sort()
    out = []
    for (x0, y0, x1, y1) in boxes:
        out.append(crop_to_alpha(rgba[y0:y1, x0:x1].copy()))
    return out


# Pale, nearly unsaturated paper an icon was painted on (see unpaper).
PAPER_MIN = 196
PAPER_MAX_CHROMA = 28


def unpaper(rgba: np.ndarray) -> np.ndarray:
    """Remove the paper card an icon was painted on, when there is one.

    A few icons (K6 clerk, P3 strength, P4 witnessed death) came on an
    off-white card instead of the grey backdrop, so keying left a beige
    square behind them - a pasted-on look over leather and parchment.
    Only paper *connected to the outside* goes, the same rule as `key`, so a
    pale highlight inside the drawing survives. An icon without a card is
    returned unchanged.
    """
    rgb = rgba[..., :3].astype(np.int32)
    paper = (rgb.min(axis=2) >= PAPER_MIN) & ((rgb.max(axis=2) - rgb.min(axis=2)) <= PAPER_MAX_CHROMA)
    paper &= rgba[..., 3] > 0
    labels, _ = ndimage.label(paper)
    # The card usually sits inside the keyed grey, so "outside" means touching
    # the image border *or* already-transparent backdrop.
    outside = ndimage.binary_dilation(rgba[..., 3] == 0)
    outside[0, :] = outside[-1, :] = outside[:, 0] = outside[:, -1] = True
    border = set(np.unique(labels[outside & paper]))
    border.discard(0)
    if not border:
        return rgba
    mask = np.isin(labels, list(border))
    # Soften the cut by one pixel so the drawing's edge is not stair-stepped.
    soft = ndimage.binary_dilation(mask) & ~mask
    out = rgba.copy()
    out[..., 3] = np.where(mask, 0, np.where(soft, out[..., 3] // 2, out[..., 3]))
    return out


def icon(src: str, name: str, size: int = 128) -> None:
    rgba = crop_to_alpha(unpaper(key(_load(src))))
    h, w = rgba.shape[:2]
    scale = size / max(h, w)
    save(rgba, name, (max(1, round(w * scale)), max(1, round(h * scale))))


PAPER_FRAME_LUMA = 150.0
PAPER_FRAME_ROW = 0.3
PAPER_FRAME_MARGIN = 10


def crop_paper_frame(rgb: np.ndarray) -> np.ndarray:
    """Some desk scenes came framed in a cream paper border with a torn inner
    edge. Walk in from each side while the row/column is mostly paper, then
    take a margin more so the torn nibbles go with it. A scene without a
    frame (candle glow at the top edge is a minority of the row) is left
    untouched."""
    luma = rgb[..., :3].mean(axis=2)
    pale = luma > PAPER_FRAME_LUMA

    def inset(profile) -> int:
        n = 0
        while n < len(profile) // 4 and profile[n] > PAPER_FRAME_ROW:
            n += 1
        return n + PAPER_FRAME_MARGIN if n else 0

    top = inset(pale.mean(axis=1))
    bottom = inset(pale.mean(axis=1)[::-1])
    left = inset(pale.mean(axis=0))
    right = inset(pale.mean(axis=0)[::-1])
    h, w = luma.shape
    return rgb[top:h - bottom, left:w - right]


def background(src: str, name: str, width: int = 0) -> None:
    """A full-bleed scene. Some arrived as a torn page on a white sheet;
    the white outside the torn edge is filled with ink-dark so the page
    reads as lying on a dark desk instead of floating on a white card.

    `width`: the generator stops at ~1376 px, and the GPU's bilinear stretch
    to 1920 softens the ink lines. A Lanczos upscale with a light unsharp
    mask done here keeps them crisper; it adds no detail the source lacks."""
    rgb = crop_paper_frame(_load(src))
    white = rgb.min(axis=2) > 232
    labels, _ = ndimage.label(white)
    border = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    border.discard(0)
    outside = np.isin(labels, list(border))
    outside = ndimage.binary_dilation(outside, iterations=2)
    rgb[outside] = (14, 12, 11)
    img = Image.fromarray(rgb.astype(np.uint8), "RGB")
    if width > img.size[0]:
        height = round(img.size[1] * width / img.size[0])
        img = img.resize((width, height), Image.LANCZOS)
        img = img.filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name), quality=86, optimize=True)
    print(f"  {name:28s} {img.size[0]}x{img.size[1]} (outside filled: {int(outside.mean() * 100)}%)")


LOOSE_PAGE_DARK = 30


def loose_page(src: str, name: str, width: int) -> None:
    """A torn page laid *on* a screen rather than filling it (the world map).

    `background` fills the white outside the tear with desk-ink, right for a
    full-bleed scene; for a page placed on the desk that fill became a dark
    rectangle around the parchment. Here the outside goes transparent.
    """
    rgb = _load(src)
    # The B6 sheet has the page on a near-black desk, others on white: both
    # count as outside when they reach the sheet's edge.
    surround = (rgb.min(axis=2) > 232) | (rgb.max(axis=2) < LOOSE_PAGE_DARK)
    labels, _ = ndimage.label(surround)
    border = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    border.discard(0)
    outside = ndimage.binary_dilation(np.isin(labels, list(border)), iterations=2)
    alpha = np.where(outside, 0, 255).astype(np.uint8)
    rgba = crop_to_alpha(np.dstack([rgb.astype(np.uint8), alpha]))
    save(rgba, name, scale_to_width(rgba, width))


def phase2plus() -> None:
    print("Phase 2+ - moments, screens, HUD, combat, people, goods")
    # Book objects (menu, run over) and the ledger.
    icon("M1_waybook_cover_closed.jpg", "m1_cover.png", 560)
    icon("M2_waybook_open_spread.jpg", "m2_spread.png", 900)
    icon("M3_run_over_screen.jpg", "m3_closed.png", 560)
    background("L1_ledger_spread.jpg", "l1_ledger.jpg")
    rgba = crop_to_alpha(key(_load("L2_generation_divider.jpg")))
    save(rgba, "l2_ribbon.png", scale_to_width(rgba, 420))
    rgba = crop_to_alpha(key(_load("R9_name_strike_stroke.jpg")))
    save(rgba, "r9_strike.png", scale_to_width(rgba, 480))
    icon("C1_mourning_crepe.jpg", "c1_crepe.png", 160)
    icon("P1_portrait_cameo_frame.jpg", "p1_cameo.png", 220)

    # Backgrounds.
    for src, name in [("B1_guild_bg.jpg", "b1_guild.jpg"), ("B2_market_bg.jpg", "b2_market.jpg"),
                      ("B3_tavern_bg.jpg", "b3_tavern.jpg"), ("B4_caravan_yard_bg.jpg", "b4_yard.jpg"),
                      ("B5_church_bg.jpg", "b5_church.jpg"),
                      ("B7_caravan_planner_bg.jpg", "b7_planner.jpg"), ("B8_recruit_bg.jpg", "b8_recruit.jpg"),
                      ("B9_character_party_bg.jpg", "b9_tent.jpg")]:
        background(src, name)
    # The city's desk: props on both edges, an empty middle for the map and
    # the brief (the city was the one screen still on flat ink).
    background("B10_city_desk_bg.jpg", "b10_city.jpg", 1920)
    loose_page("B6_world_map_parchment.jpg", "b6_map.png", 1100)
    icon("B2b_profiteering_thumbprint.jpg", "b2b_thumb.png", 96)

    # Road HUD.
    # Only the top strap ships: the HUD draws one studded belt along each
    # bar's world-facing edge (text over the rivets did not read), and the
    # bottom strap's buckle has no place in a tiled belt.
    rgba = crop_to_alpha(key(_load("R1_hud_top_strap.jpg")))
    save(rgba, "r1_strap_top.png", scale_to_width(rgba, 640))
    dial, needle = split_components(crop_to_alpha(key(_load("R3_time_dial_face.jpg"))), 2)
    save(dial, "r3_dial.png", (96, round(dial.shape[0] * 96 / dial.shape[1])))
    save(needle, "r3_needle.png", (round(needle.shape[1] * 90 / needle.shape[0]), 90))
    rgba = crop_to_alpha(key(_load("R4_pulsebar_vial_frame.jpg")))
    save(rgba, "r4_vial.png", scale_to_width(rgba, 240))
    for src, name in [("R4a_pulsebar_icon_morale.jpg", "r4a_morale.png"), ("R4b_pulsebar_icon_stress.jpg", "r4b_stress.png"),
                      ("R4c_pulsebar_icon_danger.jpg", "r4c_danger.png"), ("R4d_pulsebar_icon_stamina.jpg", "r4d_stamina.png"),
                      ("R6a_attention_icon_front.jpg", "r6a_front.png"), ("R6b_attention_icon_wagons.jpg", "r6b_wagons.png"),
                      ("R6c_attention_icon_rear.jpg", "r6c_rear.png"), ("R7a_road_signal_wheel.jpg", "r7a_wheel.png"),
                      ("R7b_road_signal_straggler.jpg", "r7b_straggler.png"), ("R7c_road_signal_smoke.jpg", "r7c_smoke.png"),
                      ("R8a_meal_bowl_full.jpg", "r8a_bowl_full.png"), ("R8b_meal_bowl_empty.jpg", "r8b_bowl_empty.png")]:
        icon(src, name, 96)
    # R5 (event card parchment) is not shipped: the event card is the sealed
    # binding, dark ground, bone text - a light parchment card would need
    # every card line recoloured and fought the seal frame.

    # Combat.
    rgba = crop_to_alpha(key(_load("K1_combat_slot_frame.jpg"), seeds=[(728, 360)]))
    save(rgba, "k1_slot.png", scale_to_width(rgba, 150))
    rgba = crop_to_alpha(key(_load("K2_deaths_door_overlay.jpg"), seeds=[(728, 360)]))
    save(rgba, "k2_door.png", scale_to_width(rgba, 150))
    rgba = crop_to_alpha(key(_load("K3_hp_stress_bar_frame.jpg"), seeds=[(176, 1464)]))
    save(rgba, "k3_bar.png", scale_to_width(rgba, 240))
    for src, name in [("K4a_status_bleed.jpg", "k4a_bleed.png"), ("K4b_status_blight.jpg", "k4b_blight.png"),
                      ("K4c_status_stun.jpg", "k4c_stun.png"), ("K4d_status_stun_resist.jpg", "k4d_stun_resist.png"),
                      ("K4e_modifier_buff_rising.jpg", "k4e_buff.png"), ("K4f_modifier_debuff_falling.jpg", "k4f_debuff.png"),
                      ("K6a_class_guard.jpg", "k6a_guard.png"), ("K6b_class_hunter.jpg", "k6b_hunter.png"),
                      ("K6c_class_breaker.jpg", "k6c_breaker.png"), ("K6d_class_clerk.jpg", "k6d_clerk.png")]:
        icon(src, name, 96)
    # The two studs sit on one small plate, so they are one alpha region:
    # split the plate down its middle instead.
    plate = crop_to_alpha(key(_load("K5_rank_pips.jpg")))
    half = plate.shape[1] // 2
    filled, hollow = crop_to_alpha(plate[:, :half]), crop_to_alpha(plate[:, half:])
    save(disc(filled), "k5_pip_filled.png", (32, 32))
    save(disc(hollow), "k5_pip_hollow.png", (32, 32))
    for piece, name in zip(split_components(crop_to_alpha(key(_load("K7_area_shift_glyphs.jpg"))), 4),
                           ["k7_adjacent.png", "k7_all.png", "k7_push.png", "k7_pull.png"]):
        h, w = piece.shape[:2]
        save(piece, name, (round(w * 48 / h), 48))

    # People.
    virtue, affliction = split_components(crop_to_alpha(key(_load("P2_trait_tokens.jpg"))), 2)
    save(virtue, "p2_virtue.png", (48, 48))
    save(affliction, "p2_affliction.png", (48, 48))
    for src, name in [("P3a_stat_strength.jpg", "p3_strength.png"), ("P3b_stat_agility.jpg", "p3_agility.png"),
                      ("P3c_stat_endurance.jpg", "p3_endurance.png"), ("P3d_stat_intellect.jpg", "p3_intellect.png"),
                      ("P3e_stat_perception.jpg", "p3_perception.png"), ("P3f_stat_charisma.jpg", "p3_charisma.png"),
                      ("P3g_stat_wisdom.jpg", "p3_wisdom.png"), ("P3h_stat_faith.jpg", "p3_faith.png"),
                      ("P4a_grievance_unfed.jpg", "p4_unfed.png"), ("P4b_grievance_benched.jpg", "p4_benched.png"),
                      ("P4c_grievance_witnessed_death.jpg", "p4_witnessed_death.png"),
                      ("P4d_grievance_passed_over.jpg", "p4_passed_over.png"),
                      ("P5a_duty_guard.jpg", "p5_guard.png"), ("P5b_duty_scout.jpg", "p5_scout.png"),
                      ("P5c_duty_quartermaster.jpg", "p5_quartermaster.png"), ("P5d_duty_wagoner.jpg", "p5_wagoner.png"),
                      ("P5e_duty_crier.jpg", "p5_crier.png"), ("P5f_duty_herbalist.jpg", "p5_herbalist.png")]:
        icon(src, name, 96)
    rgba = crop_to_alpha(key(_load("P6_hunger_tally_stick.jpg")))
    save(rgba, "p6_tally.png", scale_to_width(rgba, 240))

    # Goods.
    for item in ["bandage", "cloth", "fish", "furs", "grain", "honey", "jewelry", "potion",
                 "provisions", "silk", "spice", "weapon", "wine"]:
        icon(f"item_{item}.jpg", f"item_{item}.png", 96)


if __name__ == "__main__":
    if not os.path.isdir(SRC):
        sys.exit("run from the repository root")
    phase1()
    phase2plus()
