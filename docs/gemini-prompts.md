# Wayborne — Gemini Image Prompt List

The complete, categorized list of images the game still needs, written for
Gemini (works the same in any text-to-image model). Every entry has an
**ID** (the tag you keep the file under), a **seed**, the **aspect ratio and
target size**, the **target file** in the repo, and the **full prompt**.

Categories:

| # | Category | Count | Output |
|---|---|---|---|
| A | Event card illustrations | 21 | JPG, full bleed |
| B | Wardrobe part sheets (clothes, armour, weapons, charms, skin layer) | 21 | **PNG, background removed** |
| C | Icon families (one style for every icon) | 55 | **PNG, background removed** |
| D | Management screen backgrounds (1920 wide) | 10 | JPG, full bleed |
| E | Standalone props (seals, crepe, ribbon, map) | 6 | **PNG, background removed** |

The last section, **"PNG — background removal list"**, repeats every
entry whose background you have to remove yourself.

---

## 0. How to use this list

1. **Open one Gemini conversation per category** (A, B, C, D, E). Paste
   that category's **STYLE block** as the first message, then one entry per
   message. Staying in the same thread is what keeps a family consistent —
   Gemini has no real seed parameter.
2. **Seeds.** Each entry carries a seed (e.g. `seed 41207`). Gemini ignores
   numeric seeds, so there they are only a tracking tag: write the seed in
   the file name you save (`A-b_wolf_pack_s41207.jpg`) so a later re-roll
   can be told apart. If you use a tool that honours seeds (Imagen via
   Vertex, Midjourney `--seed`, SDXL), pass the number as is — same seed +
   same prompt = same picture.
3. **Reference images.** Where an entry says `REFERENCE:`, attach that file
   to the message. It matters most for B (the part sheet template decides
   where every garment piece sits).
4. **Aspect ratio.** Start the message with the ratio line
   (`Aspect ratio 1:1.` / `2:3` / `16:9`). Gemini honours it more reliably
   than a pixel size. The target size in each entry is what the file is cut
   and scaled to afterwards — you don't need to hit it exactly.
5. **Negative lines** (`AVOID:`) are part of the prompt — paste them too.
6. **Backgrounds.** Gemini only exports JPG. Everything in categories B, C
   and E is generated on a **flat, uniform mid-grey (RGB 140,140,140)**
   background so you can remove it cleanly; hand those back as PNG with
   transparency. A and D stay JPG.
7. **Repeat the style line in every single message, not just the first.**
   STYLE-X is pasted once at the top of the thread, but a model can quietly
   drop that instruction a few messages in — or even on the very first one.
   Every entry's prompt below already ends with its own short copy of
   `Painterly ink-and-wash illustration style, gritty and tactile.` for
   exactly this reason; keep that line when you paste, don't trim it as
   redundant.

### Shared tags

Every STYLE block already describes this in plain words — Gemini reads a
described colour ("warm ochre gold", "dried-blood red") far more reliably
than a hex code or a named game as a style anchor, both of which it tends
to quietly drop rather than follow (see the git history for this file: an
earlier version leaned on hex values and named two specific games as a
style reference, and the results came back photorealistic, ignoring the
style instruction entirely). The table below is only for matching a
finished piece back to the game's own `ArtPalette` afterward — never paste
hex codes or a game's name into a Gemini prompt itself.

| Prompt wording | `ArtPalette` hex |
|---|---|
| bone-ivory | `#E1D9C7` |
| deep ink-brown / ink (never pure black) | `#0E0D0F` |
| warm ochre gold (the one bright accent) | `#DCB357` |
| dried-blood red | `#A83029` |
| moss green | `#5E6B3A` |
| cold steel grey | `#6F7A82` |
| torch orange | `#D9822B` |

---

## A. Event card illustrations

The road event card now uses a **minimal, code-drawn frame** (flat panel,
thin gold border). The four chrome textures planned in
`docs/event-window-blueprint.md` (`E_Frame_Master`, `E_Header_Banner`,
`E_Choice_Row_Normal`, `E_Choice_Row_Hover`) are **no longer needed** —
leather/brass chrome was removed from the whole game. Only the
illustrations remain: one vignette per category, 21 in total.

- **Aspect ratio:** 1:1. **Generate at:** 1536×1536 (or Gemini's largest
  square). **Ships as:** `data/assets/ui/waybook/e6<letter>_<name>.jpg`,
  scaled down to 768×768.
- **Output:** JPG, full bleed. No background removal.
- Which events use which picture: `docs/event-window-blueprint.md` §6.1.

### STYLE-A (paste first, once per conversation)

```
You are painting a single event illustration for "Wayborne", a caravan
trading and survival game set on a dangerous medieval Anatolian trade road
— bandits, wolves, tax officials, storms, landslides, hunger, and the slow
wearing-down of the people who pull the caravan. The tone is not romantic:
tired, grounded, human. The subject is endurance, not wealth.

Each picture is one single moment, square in format, the subject sitting
centred or in the lower third, close to the camera — not a panorama. Depth
comes from soft haze on distant shapes; everything standing casts a soft
contact shadow, nothing floats. Where architecture appears it is plain
trade architecture only — walls, gates, warehouses, sheds — never a
mosque, church, cross or any real-world religious building. People read as
simple silhouettes in worn wool, linen and leather, never shiny, with only
minimal facial detail. The edges and especially the four corners darken
softly into the deep ink tone; the picture has no frame of its own, it
will sit inside the game's own card. No text, letters, numbers, symbols,
logos, UI, signatures or watermarks anywhere in the image. No photographic
realism, glossy highlights, lens flare, saturated colour or pure black.

Painterly ink-and-wash illustration style, gritty and tactile, with a firm
dark outline on every shape and flat colour fields under soft brushed
shading from a single light source — muted bone-ivory, deep near-black
ink-brown, warm ochre gold as the one bright accent, dried-blood red, moss
green and cold steel grey tones.
```

### A entries

Each message: `Aspect ratio 1:1.` + the SCENE line + the AVOID line + the
style line (already included at the end of every block below).

**A-a · wildlife_ambush** · seed 41201 · file `e6a_wildlife.jpg`
```
SCENE: Dusk at the edge of a pine forest. Between the trunks, two or three
pairs of glowing animal eyes and the faint outline of a large body — which
animal is unclear, only the feeling that something is watching. The caravan
is not in frame; this is what it sees. Cold blue-green shadow, the last
warm light low on the left.
AVOID: text, frame, clearly identifiable animal, gore.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-b · wolf_pack** · seed 41202 · file `e6b_wolves.jpg`
```
SCENE: A snow-covered roadside at night. Three or four wolves with hunched
backs, teeth slightly bared, walking parallel to the road and looking
sideways toward the viewer as if tracking the caravan. Cold blue-grey
moonlight, their breath visible, paw prints in the snow in front.
AVOID: text, frame, cartoon wolves, gore.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-c · bandit_ambush** · seed 41203 · file `e6c_bandits.jpg`
```
SCENE: Two or three bandits blocking a rocky mountain road, close to the
camera, faces wrapped in dull cloth, holding a curved sword, a spear and a
short bow. Threatening, planted stance. Behind them a steep rocky gorge.
Late afternoon light from the left, long shadows toward the viewer.
AVOID: text, frame, heroic poses, shiny armour, gore.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-d · guard_checkpoint** · seed 41204 · file `e6d_guard.jpg`
```
SCENE: A city guard in a simple conical helmet and quilted coat, spear in
one hand, the other hand raised flat in a "halt" gesture. Behind him a
wooden road barrier and a plain pennant pole with an unmarked cloth
banner. A second guard in the background leaning on a post. Overcast
daylight.
AVOID: text, frame, heraldry, symbols on the banner, crosses, crescents.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-e · traveler_wanderer** · seed 41205 · file `e6e_traveler.jpg`
```
SCENE: A lone tired traveller standing at the side of a dirt road with a
heavy pack and a walking staff, turned toward the viewer, neither friendly
nor hostile — an uncertain, weighing posture. Open steppe behind, low
hills in haze, a single leafless tree.
AVOID: text, frame, detailed face.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-f · merchant_caravan** · seed 41206 · file `e6f_merchant.jpg`
```
SCENE: Another caravan approaching from the opposite direction on a wide
road: one or two ox carts with arched canvas covers, a few merchants on
foot, one raising a hand in greeting. The oxen have a visible shoulder hump
and are yoked to the cart by a draught pole. Warm midday haze.
AVOID: text, frame, horses pulling carts, camels.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-g · pilgrim** · seed 41207 · file `e6g_pilgrim.jpg`
```
SCENE: A lone pilgrim in a plain undyed wool robe, head slightly bowed,
holding a tall staff with a few knotted cords hanging from it, walking
along a ridge path. A sense of quiet devotion, not threat. Soft dawn light,
a distant snowy peak (the mountain folk's sacred summit) in haze.
AVOID: text, frame, crosses, prayer beads of a real religion, halos.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-h · roadside_shrine** · seed 41208 · file `e6h_shrine.jpg`
```
SCENE: A small, old stone wayside shrine at the road's edge: a waist-high
cairn-like pillar with a flat stone on top. Faded cloth ribbons tied to a
stick, a few worn coins and a burnt-out candle stub on the stone. No one
there, only the structure. Grass growing around its base, late evening.
AVOID: text, frame, carved symbols, crosses, crescents, statues of gods.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-i · mountain_pass** · seed 41209 · file `e6i_pass.jpg`
```
SCENE: A narrow mountain pass between two steep cliff walls; the road
climbs and bends upward out of sight. Loose scree on the slopes, a snowy
summit far behind in haze, a cold wind carrying snow off the ridge.
AVOID: text, frame, people, buildings.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-j · hamlet_wounded** · seed 41210 · file `e6j_hamlet.jpg`
```
SCENE: A tiny roadside hamlet of three low mud-brick and timber huts. In
front of one hut a wounded figure sits slumped on the ground against the
wall, a bloodied cloth around one leg, looking toward the road as if
waiting for help. Grey overcast light, smoke from one chimney.
AVOID: text, frame, gore, graphic wounds.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-k · frontier_outpost** · seed 41211 · file `e6k_outpost.jpg`
```
SCENE: A small frontier outpost surrounded by a sharpened log palisade: a
simple wooden watchtower, two or three tents, a faded plain flag on a
pole. A single sentry silhouette on the tower. Dry steppe around it,
evening light.
AVOID: text, frame, heraldry or symbols on the flag.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-l · mine_collapse** · seed 41212 · file `e6l_mine.jpg`
```
SCENE: A mine entrance cut into a hillside; its timber supports half
collapsed, dust and smoke still pouring out of the dark opening. An
abandoned pickaxe and an overturned ore cart near the entrance. Harsh
flat daylight, dust haze.
AVOID: text, frame, gore, bodies.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-m · failing_bridge** · seed 41213 · file `e6m_bridge.jpg`
```
SCENE: An old wooden plank bridge over a fast stream. One plank is broken
and hangs down; the whole bridge sags at an uneasy angle; white water
rushes below. Wet stones on the banks, alder bushes, overcast light.
AVOID: text, frame, people.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-n · storm_weather** · seed 41214 · file `e6n_storm.jpg`
```
SCENE: Dark, towering storm clouds gathering over an empty road across
open plains; a distant lightning strike; a few trees bent flat by the wind;
rain curtains in the distance. The caravan is not in frame — only the sky
waiting for it.
AVOID: text, frame, people.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-o · landslide** · seed 41215 · file `e6o_landslide.jpg`
```
SCENE: A fresh landslide of earth and boulders half blocking a mountain
road; a fallen pine lies across one lane; dust still hangs in the air.
Cracked slope above, loose stones mid-fall.
AVOID: text, frame, people.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-p · broken_wagon** · seed 41216 · file `e6p_wagon.jpg`
```
SCENE: An ox cart tipped on its side at the road's edge, one wooden wheel
broken with snapped spokes, its canvas cover torn, sacks and jars
scattered around it. The owner is nowhere to be seen. Late afternoon,
long shadows.
AVOID: text, frame, bodies.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-q · camp_night** · seed 41217 · file `e6q_camp.jpg`
```
SCENE: Night, a campfire, four or five caravan people sitting around it
wrapped in blankets and cloaks. The orange firelight lights their faces
from below; they sit a little apart from each other, faces closed,
tired or tense. A wagon silhouette behind them, dark sky with a few stars.
AVOID: text, frame, cheerful mood, detailed faces.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-r · wayside_grave** · seed 41218 · file `e6r_grave.jpg`
```
SCENE: A simple grave at the roadside: a low mound of earth with an upright
rough stone as a marker, a faded strip of cloth tied around the stone, a
few wilted wildflowers. Silent and abandoned, grey dawn light.
AVOID: text, frame, crosses, carved letters or symbols.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-s · creditor_rider** · seed 41219 · file `e6s_creditor.jpg`
```
SCENE: A mounted creditor's agent in a dark, well-kept official coat,
blocking the road on a grey horse, holding up a rolled document sealed
with red wax. Stern posture, looking down at the viewer. Two armed riders
blurred in the background. Cold morning light.
AVOID: text, frame, readable writing on the document.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-t · world_news** · seed 41220 · file `e6t_news.jpg`
```
SCENE: Close-up of a sealed notice nailed to a wooden post at a crossroads,
its paper curling, a red wax seal at the bottom; the writing is only
indistinct ink strokes. Behind it, the backs and silhouettes of three or
four curious travellers gathered to look.
AVOID: readable text, letters, numbers, frame.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**A-u · forgotten_cache** · seed 41221 · file `e6u_cache.jpg`
```
SCENE: An old rusted iron-bound chest half buried in the earth, partly
covered with moss and roots, the lid slightly ajar with a glint of pale
gold inside. It has clearly been there a long time. Forest floor, dappled
light.
AVOID: text, frame, piles of treasure.
Painterly ink-and-wash illustration style, gritty and tactile.
```

---

## B. Wardrobe part sheets (clothes, armour, weapons, charms)

This is the category the skeleton system reads. Every sheet is painted
**over the part sheet template**, and the tool slices it into the
per-bone pieces (`python3 tools/wardrobe_ingest.py sheet <file> <item_id>`).

- **REFERENCE (attach to every message):**
  `docs/wardrobe/part_sheet_template.png` — 768×1152, 3×3 cells of 256×384.
  Row 1: `head`, `torso`, `upper_arm`. Row 2: `forearm`, `hand`, `thigh`.
  Row 3: `shin`, `foot`, `weapon`. Each cell holds a grey mannequin piece
  with a **red dot** (the joint it hangs from) and a **blue dot** (the
  other end).
  Also useful once: `docs/wardrobe/rig_reference.png` (the assembled body).
- **Aspect ratio:** 2:3. **Generate at:** 1024×1536 (any 2:3 size works;
  the tool rescales to 768×1152).
- **Output:** **PNG with the background removed.** Also remove the grey
  mannequin, the red/blue dots and the cell lines — only the garment
  stays. Cells the item doesn't cover must end up fully transparent.
- **Ships as:** `data/assets/characters/wardrobe/<item_id>/<part>.png`.
- If one cell comes out wrong, you don't have to redo the sheet: paint that
  single part alone and send it with its part name
  (`wardrobe_ingest.py part <file> <item_id> <part>`).

### STYLE-B (paste first, together with the template)

```
The attached image is a PART SHEET TEMPLATE for a 2D cut-out character
rig in a computer game. It is a 3x3 grid. Each cell contains one grey
mannequin body segment seen from the SIDE, the character facing RIGHT:
row 1 = head, torso, upper arm; row 2 = forearm, hand, thigh;
row 3 = shin, foot, weapon. The red dot in each cell is the joint the
piece hangs from; the blue dot is the joint at the other end.

YOUR TASK: I will name one garment or item. Paint that item ONTO the
mannequin segments it would cover, in the same cells, at exactly the same
position, scale and angle as the grey mannequin, so that each painted piece
lines up with its red and blue dots. Keep the image exactly the same size
and the grid exactly the same layout. Cells the item does not cover stay
EMPTY (flat grey, nothing painted).

RULES:
- Side view, facing right, for every piece. Light from the top-left.
- The garment must fully cover the mannequin under it and may extend a
  little beyond it (cloth has thickness, a cloak hangs), but must never
  leave its own cell.
- Joints overlap: paint each piece slightly longer than the bone at the
  red-dot end (about 10-15% extra) so no gap opens when the limb bends.
- Paint only the item — no skin, no body, no face (unless I say so). Where
  a sleeve or collar opens, leave that part empty; the body is drawn
  underneath by the game.
- Background: flat uniform mid-grey RGB 140,140,140 everywhere that is not
  the item. No gradient, no texture, no shadow on the background, no cast
  shadow on the ground.
- Remove the red and blue dots, the grey mannequin and the cell labels from
  your output; only the painted item remains on flat grey.

Painterly ink-and-wash illustration style, gritty and tactile, with a firm
dark outline on every shape, flat colour fields and one or two soft
brushed shade steps, light from the top-left. Materials are worn and
matte — wool, linen, felt, leather, iron, bronze — nothing shiny or new,
in muted, low-saturation bone-ivory, deep ink-brown, warm ochre gold,
dried-blood red, moss green, cold steel grey and earth-brown tones. The
setting is a medieval Anatolian-inspired caravan road: no fantasy glow, no
runes, no religious symbols, no text, letters, logos or watermarks.
```

### B entries

Each message: `Aspect ratio 2:3. Use the attached template.` + the ITEM
block (already ends with the style line) + the Cells line. "Cells" lists
what must be painted; everything else stays empty.

#### B0 — skin layer (optional)

**B-00 · body** · seed 52000 · item_id `body`
```
ITEM: The bare body itself, as a SKIN LAYER. Paint every cell except
"weapon": head (bald head, simple ear, neck, a plain profile face with only
a small nose and brow line, no hair), torso, upper arm, forearm, hand
(closed loosely, thumb forward), thigh, shin, foot (bare foot, sole on the
red-dot line).
Paint it in NEUTRAL LIGHT GREY tones only (#D8D8D8 base, #A8A8A8 shade,
dark ink contour) — the game tints it with each character's skin colour.
Cells: head, torso, upper_arm, forearm, hand, thigh, shin, foot.
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B1 — hats (slot: hat)

**B-01 · hat_felt** · seed 52101 · item_id `hat_felt` · "Felt Cap"
```
ITEM: A soft felt cap in faded brown (#6B5238), the kind worn by nomads
and drovers: rounded crown, a short upturned brim at the front, a stitched
seam along the side. It sits on top of the head down to the ears; the face
stays empty.
Cells: head only.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-02 · hat_hood** · seed 52102 · item_id `hat_hood` · "Travelling Hood"
```
ITEM: A grey-brown wool travelling hood (#4D4D57) pulled over the head,
drawn slightly forward over the brow, falling to the neck and the top of
the shoulders. The face opening stays empty. The hood's lower edge may
spill a little into the top of the torso cell as a short shoulder cape.
Cells: head (main), torso (only the short shoulder cape, top edge).
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B2 — shirts (slot: shirt, under everything)

**B-03 · shirt_linen** · seed 52103 · item_id `shirt_linen` · "Linen Shirt"
```
ITEM: A plain undyed linen shirt (#D1C7A8), loose and slightly creased,
collarless with a short slit at the neck, long sleeves ending just above
the wrist, hem tucked at the waist. Thin, soft fabric.
Cells: torso, upper_arm, forearm.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-04 · shirt_dyed** · seed 52104 · item_id `shirt_dyed` · "Dyed Shirt"
```
ITEM: A woad-dyed blue linen shirt (#5C7594), faded unevenly from sun and
washing, a narrow woven band along the collar and cuffs in pale gold
(#DCB357). Long sleeves to the wrist, belted at the waist with a thin
cord.
Cells: torso, upper_arm, forearm.
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B3 — jackets (slot: jacket, over shirt and armour)

**B-05 · jacket_wool** · seed 52105 · item_id `jacket_wool` · "Wool Coat"
```
ITEM: A heavy brown wool kaftan-style coat (#614733), wrapped across the
chest and tied at the side, reaching mid-thigh, long sleeves slightly
wider at the cuff, a darker felt trim along the front edge and hem. Worn
patches at the elbows.
Cells: torso (with the coat's skirt hanging below the hip), upper_arm,
forearm, thigh (only the coat's skirt over the upper thigh).
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-06 · jacket_leather** · seed 52106 · item_id `jacket_leather` · "Leather Jerkin"
```
ITEM: A dark oiled leather jerkin (#4D3324), sleeveless body with short
cap sleeves over the shoulder, laced up the front with leather thongs,
scuffed and creased, a broad belt with a simple iron buckle.
Cells: torso, upper_arm (cap sleeve only, top third).
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B4 — gloves (slot: gloves)

**B-07 · gloves_leather** · seed 52107 · item_id `gloves_leather` · "Leather Gloves"
```
ITEM: Brown work gloves of thick leather (#57402E) with a short flared
cuff that covers the lower forearm, stitched seams on the back of the hand.
Cells: hand, forearm (only the cuff, near the blue-dot end).
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B5 — trousers (slot: pants)

**B-08 · pants_wool** · seed 52108 · item_id `pants_wool` · "Wool Trousers"
```
ITEM: Dark grey-brown wool trousers (#47423D), loose at the thigh, wrapped
tight below the knee with cloth puttee bands up the shin.
Cells: thigh, shin.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-09 · pants_canvas** · seed 52109 · item_id `pants_canvas` · "Canvas Trousers"
```
ITEM: Light sand-coloured canvas trousers (#948A70), baggy in the Anatolian
şalvar cut — full at the thigh, gathered at the ankle — dusty at the hem,
a patched knee.
Cells: thigh, shin.
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B6 — footwear (slot: shoes)

**B-10 · shoes_boots** · seed 52110 · item_id `shoes_boots` · "Riding Boots"
```
ITEM: Tall soft leather riding boots (#382920), reaching just below the
knee, a slightly upturned toe, worn creases at the ankle, a thin sole.
The sole must sit exactly on the red dot's horizontal line in the foot
cell (that line is the ground).
Cells: shin (boot shaft), foot.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-11 · shoes_sandals** · seed 52111 · item_id `shoes_sandals` · "Sandals"
```
ITEM: Simple leather sandals (#80664D): a flat sole with straps across the
foot and two thin straps wrapping the lower ankle. The foot itself is NOT
painted — only the sole and straps (the body layer shows through between
the straps; leave those gaps empty).
Cells: foot, shin (only the ankle straps at the lower end).
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B7 — armour (slot: armor, over shirt, under jacket)

**B-12 · armor_tier_1** · seed 52112 · item_id `armor_tier_1` · "Leather Armor"
```
ITEM: Hardened boiled-leather armour: a thick quilted-and-leather cuirass
covering chest and back to the hip, overlapping leather strips hanging over
the upper thigh, small leather shoulder guards. Brown and dark tan
(#5A3F2A / #7A5A3C), stitched, scuffed, matte.
Cells: torso, upper_arm (shoulder guard, top third), thigh (hanging
strips, top third).
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-13 · armor_tier_2** · seed 52113 · item_id `armor_tier_2` · "Chain Shirt"
```
ITEM: A riveted iron mail shirt (cold steel #6F7A82, darker in the folds)
reaching mid-thigh, with elbow-length mail sleeves, worn over a quilted
under-coat whose padded edge shows at the neck and hem. The mail is shown
as a fine ring texture, not individual shiny rings; dull, slightly rusty.
Cells: torso, upper_arm, thigh (mail skirt, top half).
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-14 · armor_tier_3** · seed 52114 · item_id `armor_tier_3` · "Plate Armor"
```
ITEM: Lamellar and plate armour of a veteran caravan guard: a chest of
laced iron lamellae over mail, a rounded pauldron on the shoulder, a plate
vambrace on the forearm, lamellar tassets over the thigh, a riveted iron
gorget at the neck. Dull iron (#6F7A82) with dark leather lacing and a thin
pale-gold (#DCB357) edge on the pauldron — worn, dented, never polished.
Cells: torso, upper_arm, forearm, thigh.
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B8 — weapons (slot: weapon, held in the front hand)

The weapon cell's **red dot is the grip**: the hand closes there. The blade
points DOWN from the grip toward the blue dot, the pommel is just above the
red dot. (The rig rotates it; at rest the sword hangs point-down.)

**B-15 · weapon_tier_1** · seed 52115 · item_id `weapon_tier_1` · "Caravan Sword"
```
ITEM: A plain iron arming sword for caravan guards: straight single-edged
blade, simple cross guard, leather-wrapped grip, round iron pommel. Grey
steel, a few nicks on the edge. Grip on the red dot, pommel just above it,
blade pointing straight DOWN toward the blue dot and beyond.
Cells: weapon only.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-16 · weapon_tier_2** · seed 52116 · item_id `weapon_tier_2` · "Master's Sword"
```
ITEM: A well-made curved sabre (kılıç): a slightly curved single-edged
blade widening a little toward the tip, a short straight guard with
downturned ends, a grip wrapped in dark leather, a brass (#DCB357, dulled)
cap on the pommel. Grip on the red dot, blade pointing DOWN, the curve
bending toward the right.
Cells: weapon only.
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-17 · weapon_tier_3** · seed 52117 · item_id `weapon_tier_3` · "Falcon Sword"
```
ITEM: A fine old sabre of a master smith: a deeply curved blade with a
subtle wavy forging pattern in the steel, a pale-gold (#DCB357) guard whose
two ends are shaped like folded falcon wings, a grip bound in dark red
cord (#A83029), a falcon-head pommel. Still worn and matte, not glowing.
Grip on the red dot, blade pointing DOWN, curve bending toward the right.
Cells: weapon only.
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B9 — charms (slot: amulet, worn at the chest)

Rings are too small to show on the figure; they only get icons (section C).

**B-18 · amulet_ward** · seed 52118 · item_id `amulet_ward` · "Ward Charm"
```
ITEM: A small folded triangular cloth charm (muska) in faded red wool,
stitched shut, hanging from a dark cord around the neck; the cord runs up
toward the neck, the charm rests on the upper chest.
Cells: torso only (upper chest, near the red dot).
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-19 · amulet_wolf_fang** · seed 52119 · item_id `amulet_wolf_fang` · "Wolf Fang Pendant"
```
ITEM: A single large yellowed wolf fang bound with a leather thong, hung
on a braided cord around the neck, resting on the upper chest.
Cells: torso only (upper chest).
Painterly ink-and-wash illustration style, gritty and tactile.
```

**B-20 · amulet_courage** · seed 52120 · item_id `amulet_courage` · "Courage Charm"
```
ITEM: A flat bronze disc pendant (dull #B08A4A), its face hammered with a
simple radiating pattern (no letters, no religious sign), on a thin chain
around the neck, resting on the upper chest.
Cells: torso only (upper chest).
Painterly ink-and-wash illustration style, gritty and tactile.
```

#### B10 — optional back-limb variants

The back arm/leg reuses the front art, darkened. If a piece looks wrong from
behind (e.g. a boot's buckle that should be on the outer side), ask in the
same thread: *"Now paint the same item as seen on the FAR side of the body:
same cells, same positions, but show the inner side of the garment."* —
send the result as `<part>_back.png` with
`wardrobe_ingest.py part <file> <item_id> <part>_back`.

---

## C. Icon families — one style for every icon

The shipped icons came in mixed styles (some with sticker edges, some round
badges, some on square paper cards). This category regenerates **every
icon in one single style**: an ink-and-wash token on a transparent ground.

- **Aspect ratio:** 1:1. **Generate at:** 1024×1024. **Ships at:** 96×96
  (the pipeline downsizes). Keep the motif big and simple — it must read at
  48 px.
- **Output:** **PNG with the background removed.**
- **Ships as:** the file names below in `data/assets/ui/waybook/`.

### STYLE-C (paste first)

```
You are painting small UI icons for a computer game — one icon per
message, all in exactly the same hand so they read as one family. Each
icon is a single motif, centred, filling about three-quarters of the
square, painted as a small ink-and-wash token: a firm dark outline, flat
fills in a muted low-saturation palette — bone-ivory, deep ink-brown, warm
ochre gold used sparingly as the one bright accent, dried-blood red, moss
green, cold steel grey, earth browns — with one soft brushed shade step
under light from the top-left. No badge, no circle, no frame, no card, no
sticker outline, no drop shadow, no paper behind it — only the motif
itself, bold and simple enough to read clearly at a very small size, on a
flat uniform mid-grey background with no gradient, texture or shadow. No
text, letters, numbers, logos, watermarks or religious symbols.

Painterly ink-and-wash illustration style, gritty and tactile.
```

Each message: `Aspect ratio 1:1. ICON:` + the motif + `. Painterly
ink-and-wash illustration style, gritty and tactile.`

### C1 — stats (P3) · seeds 53101-53108

| ID | File | Motif |
|---|---|---|
| C-p3-strength | `p3_strength.png` | a clenched fist gripping a short iron bar |
| C-p3-agility | `p3_agility.png` | a leaping hare mid-stride |
| C-p3-endurance | `p3_endurance.png` | a heavy wooden ox yoke |
| C-p3-intellect | `p3_intellect.png` | an open ledger with a reed pen across it (no writing, only lines) |
| C-p3-perception | `p3_perception.png` | a single wide-open eye with a small hawk feather beside it |
| C-p3-charisma | `p3_charisma.png` | two hands clasped in a handshake |
| C-p3-wisdom | `p3_wisdom.png` | an old oil lamp with a small flame |
| C-p3-faith | `p3_faith.png` | a knotted cord tied around a small standing stone |

### C2 — duties (P5) · seeds 53201-53206

| ID | File | Motif |
|---|---|---|
| C-p5-guard | `p5_guard.png` | a round wooden shield with an iron boss, a spear behind it |
| C-p5-scout | `p5_scout.png` | a hawk perched on a gloved fist |
| C-p5-quartermaster | `p5_quartermaster.png` | a tied grain sack with a wooden scoop |
| C-p5-wagoner | `p5_wagoner.png` | a spoked wooden cart wheel with a driving whip |
| C-p5-crier | `p5_crier.png` | a brass hand bell |
| C-p5-herbalist | `p5_herbalist.png` | a mortar and pestle with a sprig of herbs |

### C3 — grievances (P4) · seeds 53301-53304

| ID | File | Motif |
|---|---|---|
| C-p4-unfed | `p4_unfed.png` | an empty wooden bowl tipped on its side, a spoon beside it |
| C-p4-benched | `p4_benched.png` | a sword lying unused on the ground beside a sheathed scabbard |
| C-p4-witnessed | `p4_witnessed_death.png` | a closed eye with a single dark tear |
| C-p4-passed-over | `p4_passed_over.png` | a leader's staff lying broken in two |

### C4 — classes (K6) · seeds 53401-53404

| ID | File | Motif |
|---|---|---|
| C-k6-guard | `k6a_guard.png` | a tall infantry shield planted upright |
| C-k6-hunter | `k6b_hunter.png` | a recurved short bow with one arrow nocked |
| C-k6-breaker | `k6c_breaker.png` | a heavy war hammer with a cracked iron plate |
| C-k6-clerk | `k6d_clerk.png` | a rolled document tied with a cord and a wax seal |

### C5 — traits and combat statuses (P2, K4) · seeds 53501-53508

| ID | File | Motif |
|---|---|---|
| C-p2-virtue | `p2_virtue.png` | a small upright flame in pale gold |
| C-p2-affliction | `p2_affliction.png` | a cracked clay jar leaking dark liquid |
| C-k4-bleed | `k4a_bleed.png` | three falling drops of dried-blood red |
| C-k4-blight | `k4b_blight.png` | a withered moss-green leaf with dark spots |
| C-k4-stun | `k4c_stun.png` | a small cluster of pale stars spinning around a dot |
| C-k4-stun-resist | `k4d_stun_resist.png` | an iron helmet with a small dent |
| C-k4-buff | `k4e_buff.png` | an arrow pointing up, pale gold |
| C-k4-debuff | `k4f_debuff.png` | an arrow pointing down, dried-blood red |

### C6 — goods (item icons) · seeds 53601-53613

| ID | File | Motif |
|---|---|---|
| C-item-provisions | `item_provisions.png` | a bundle of flatbread and dried meat tied in cloth |
| C-item-grain | `item_grain.png` | an open sack of wheat grain |
| C-item-cloth | `item_cloth.png` | a rolled bolt of woven cloth |
| C-item-iron | `item_weapon.png` | three rough iron ingots stacked (the good is "Iron") |
| C-item-potion | `item_potion.png` | a small corked clay flask with a herb tag |
| C-item-furs | `item_furs.png` | a folded stack of furs |
| C-item-bandage | `item_bandage.png` | a rolled linen bandage |
| C-item-spice | `item_spice.png` | a small cloth pouch spilling red-brown spice |
| C-item-honey | `item_honey.png` | a clay honey pot with a wooden dipper |
| C-item-silk | `item_silk.png` | a folded length of shining (but muted) silk |
| C-item-jewelry | `item_jewelry.png` | a small open wooden box with a bronze bracelet |
| C-item-fish | `item_fish.png` | two dried fish tied on a string |
| C-item-wine | `item_wine.png` | a small wooden wine cask |

### C7 — equipment icons (new) · seeds 53701-53712

For the character screen's equipment list. Weapons and armour match the
wardrobe items of section B so the icon and the figure agree. These are
new: the character screen starts reading them when they are delivered
(nothing painted ships before the game reads it).

| ID | File | Motif |
|---|---|---|
| C-eq-weapon-1 | `eq_weapon_tier_1.png` | plain iron arming sword, diagonal |
| C-eq-weapon-2 | `eq_weapon_tier_2.png` | curved sabre with brass pommel cap, diagonal |
| C-eq-weapon-3 | `eq_weapon_tier_3.png` | curved sabre with falcon-wing guard, diagonal |
| C-eq-armor-1 | `eq_armor_tier_1.png` | boiled-leather cuirass, front view |
| C-eq-armor-2 | `eq_armor_tier_2.png` | mail shirt, front view |
| C-eq-armor-3 | `eq_armor_tier_3.png` | lamellar cuirass with pauldrons, front view |
| C-eq-ring-marksman | `eq_ring_marksman.png` | an iron archer's thumb ring |
| C-eq-ring-gambler | `eq_ring_gambler.png` | a bronze ring set with a small bone die |
| C-eq-ring-charmed | `eq_ring_charmed.png` | a ring of twisted copper wire with a blue bead |
| C-eq-amulet-ward | `eq_amulet_ward.png` | a triangular red cloth charm on a cord |
| C-eq-amulet-fang | `eq_amulet_wolf_fang.png` | a wolf fang on a leather thong |
| C-eq-amulet-courage | `eq_amulet_courage.png` | a hammered bronze disc pendant |

---

## D. Management screen backgrounds (1920 wide)

The current desk scenes are 1376×768 and go soft at 1920. These are
regenerations of the same screens at the largest size Gemini gives; the
pipeline upscales to 1920×1080 with Lanczos (`tools/waybook_assets.py`,
`background(src, name, width)`).

- **Aspect ratio:** 16:9. **Generate at:** the largest 16:9 Gemini offers.
  **Ships as:** 1920×1080 JPG.
- **Output:** JPG, full bleed. No background removal.
- The **centre 65% of the width** must stay calm and dark (the game places
  its text column there, on a dark band). Props live at the left and right
  edges.

### STYLE-D (paste first)

```
You are painting a single, wide background illustration for the menu
screens of a computer game, "Wayborne" — a medieval Anatolian-inspired
caravan trading and survival game. Each scene is a view down onto a worn
wooden desk or workspace belonging to one place in a caravan city, as if
you are standing at it.

Style: hand-illustrated ink-and-wash painting, aged parchment tones, warm
sepia, burnished brown and deep burgundy palette, with visible paper grain
and subtle brush texture — like the weathered pages of an 18th-century
trade ledger. One warm light source, a candle or a window, from the left,
with a gentle vignette darkening softly toward the four corners.

Composition: seen from slightly above, 16:9 widescreen. The centre 65% of
the width stays a calm, dark, mostly empty surface — dark wood or dark
cloth, very little detail — because the game's own text is laid over it
afterward. All props sit at the left and right edges and along the bottom
edge, partly cut off by the frame, everything worn and used, nothing new
or shiny.

No text, no numbers, no readable symbols, no UI elements, no buttons, no
icons, no hands, no people, no faces, no logos, no watermarks, no frame or
border, no religious symbols — pure background environment art only, as
high resolution as possible.
```

### D entries

Each message: `Aspect ratio 16:9.` + the SCENE line + `Painterly
ink-and-wash illustration style, gritty and tactile.`

| ID | Seed | File | SCENE |
|---|---|---|---|
| D-b1 · guild | 54101 | `b1_guild.jpg` | A merchants' guild clerk's desk: open account ledger at the left edge, a candle, an inkwell with a reed pen, a red wax seal and a stick of sealing wax, a small stack of worn coins and a folded contract with a seal at the right edge. |
| D-b2 · market | 54102 | `b2_market.jpg` | A market stall counter: brass balance scales at the left edge, open sacks of grain and spice, a clay jar, a bolt of cloth and a basket of dried fish at the right edge, coins scattered on the bottom edge. |
| D-b3 · tavern | 54103 | `b3_tavern.jpg` | A tavern table at night: pewter mugs and a clay jug at the left edge, a torn hand-drawn route map (no writing) and a dagger stuck in the wood at the right edge, candle stubs, spilled drink rings. |
| D-b4 · caravan yard | 54104 | `b4_yard.jpg` | A wagon yard workbench: an iron horseshoe, a coil of rope and a mallet at the left edge, a spoked cart wheel leaning at the right edge, wood shavings, a pot of axle grease. |
| D-b5 · church | 54105 | `b5_church.jpg` | A quiet stone hall's lectern: a bowl of water with floating petals at the left edge, bundles of dried herbs and a tall candle at the right edge, knotted cords; no religious symbols. |
| D-b7 · planner | 54106 | `b7_planner.jpg` | A caravan master's planning table: a large rolled-out parchment map (no writing) under brass weights at the left edge, a compass-like sundial, a provision list of ink strokes, a lantern at the right edge. |
| D-b8 · recruitment | 54107 | `b8_recruit.jpg` | A hiring board in a square: a rough wooden table with a stack of worn tokens, a purse, a walking staff leaning at the right edge, the edge of a crowd's cloaks at the left edge. |
| D-b9 · tent | 54108 | `b9_tent.jpg` | Inside a road tent at night: a bedroll and a saddlebag at the left edge, an oil lamp and a small travel chest at the right edge, canvas walls in dark tan, the centre a dark rug. |
| D-b10 · city | 54109 | `b10_city.jpg` | A city notary's desk with the window open onto a walled trade town at dusk (walls, gate, warehouses, no religious buildings) at the left edge, keys and a seal at the right edge. |
| D-l1 · ledger | 54110 | `l1_ledger.jpg` | An open old account book seen from directly above, filling the frame: two yellowed ruled pages with indistinct ink strokes only, a ribbon marker, stains and a candle-wax drip. |

---

## E. Standalone props

- **Aspect ratio:** 1:1 unless noted. **Generate at:** 1024×1024.
- **Output:** **PNG with the background removed** (for E-b6 the torn page edge stays, only the surround goes).
- Style: paste **STYLE-C** first, but change its opening sentence to
  *"Each object is centred, filling about 80% of the square, painted with
  more detail than an icon since it will be shown large."*
- Each message: the Aspect line + the Prompt text + `Painterly ink-and-wash
  illustration style, gritty and tactile.`

| ID | Seed | File | Aspect | Prompt |
|---|---|---|---|---|
| E-g9 · seal | 55101 | `g9_seal.png` | 1:1 | A round dried-blood red wax seal pressed onto nothing, its face stamped with a simple caravan wheel (no letters), slightly uneven edge, a short cut ribbon under it. |
| E-g9b · cracked seal | 55102 | `g9b_seal_cracked.png` | 1:1 | The exact same wax seal as before, now cracked through the middle into two pieces with a chip missing. (Same thread as E-g9, say "the same seal".) |
| E-c1 · mourning crepe | 55103 | `c1_crepe.png` | 1:1 | A black mourning crepe ribbon tied in a simple bow, frayed tails hanging down. |
| E-l2 · ribbon | 55104 | `l2_ribbon.png` | 1:4 (tall) | A long faded dried-blood red silk bookmark ribbon hanging straight down, forked tail at the bottom. |
| E-r9 · strike | 55105 | `r9_strike.png` | 4:1 (wide) | A single horizontal stroke of dark ink made with a reed pen, thick in the middle and tapering at both ends, a few spatters. |
| E-b6 · map | 55106 | `b6_map.png` | 4:3 | A torn parchment page with a hand-drawn regional map: five small walled towns joined by roads, mountains, a forest, a river running to a coast — no writing, no labels, no compass letters. Torn, irregular edges. |

---

## PNG — background removal list

Everything below is generated on a flat grey (RGB 140,140,140) ground and
has to come back as **PNG with transparency**. Remove the grey, keep soft
edges (don't cut hard), and for section B also remove the mannequin, the
red/blue dots and the cell lines.

**B — wardrobe sheets (21):** `body`, `hat_felt`, `hat_hood`,
`shirt_linen`, `shirt_dyed`, `jacket_wool`, `jacket_leather`,
`gloves_leather`, `pants_wool`, `pants_canvas`, `shoes_boots`,
`shoes_sandals`, `armor_tier_1`, `armor_tier_2`, `armor_tier_3`,
`weapon_tier_1`, `weapon_tier_2`, `weapon_tier_3`, `amulet_ward`,
`amulet_wolf_fang`, `amulet_courage` (+ any `*_back` variants).
Send each as `<item_id>.png`; I slice it.

**C — icons (55):** eight `p3_*`, six `p5_*`, four `p4_*`, four
`k6*_*`, `p2_virtue`, `p2_affliction`, six `k4*_*`, thirteen `item_*`,
twelve `eq_*`.

**E — props (6):** `g9_seal`, `g9b_seal_cracked`, `c1_crepe`,
`l2_ribbon`, `r9_strike`, `b6_map` (keep the torn edge; the surround
becomes transparent).

**JPG, no removal needed:** all of A (21 event illustrations) and D (10
backgrounds).

**Tip for removal:** since the ground is one flat grey, a colour-select
(tolerance ~15-20) plus a 1 px feather is usually enough. If a piece has
grey in it (steel, mail), remove only the grey *connected to the edges*.
If you send a sheet with the grey still in it, I can key it
(`wardrobe_ingest.py ... --key`), but hand-removed edges look better.
