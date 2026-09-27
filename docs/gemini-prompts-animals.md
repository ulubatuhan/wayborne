# Wayborne — Gemini Image Prompts: Animals

Companion to `docs/gemini-prompts.md`. The five animals the game draws —
horse, ox, wolf, bear, boar — now stand on a skeleton (`BeastRig`), so each
one is painted **once, whole, in a fixed walking pose**, and
`tools/beast_cut.py` cuts that painting into the 16 bones. The same painting
is what you see on the road, in the hub, on the road-encounter marker and in
combat (mirrored when the animal faces left).

| # | Category | Count | Output |
|---|---|---|---|
| F | Whole animals in the rig pose | 5 | **PNG, background removed** |
| G | Part-sheet fallback (only if F fails for a species) | up to 5 | **PNG, background removed** |

---

## 0. How to use this list

1. **One Gemini conversation for all five animals.** Paste **STYLE-F** as the
   first message. Then send one animal per message, **with that species'
   pose reference attached** (`docs/beasts/<species>_pose_reference.jpg`).
   Staying in one thread keeps the five animals in the same hand.
2. **The pose is the contract.** The reference shows a grey mannequin walking
   right in mid-stride. Light grey legs are the **near** side (toward the
   viewer), dark grey legs the **far** side. The painting must keep the same
   four leg positions. Size and placement don't have to match, because the
   tool fits the painting onto the pose by its bounding box.
3. **Seeds** are tracking tags (Gemini ignores them). Keep them in the file
   name: `F-horse_s61101.png`. Pass them as they are to a tool that honours
   seeds.
4. **Aspect ratio 3:2**, generate at the largest 3:2 size offered (the
   reference is 1536×1024). Start each message with `Aspect ratio 3:2.`
5. **Background:** flat mid-grey (RGB 140,140,140). You remove it and hand
   back a PNG with transparency. Keep soft fur edges. Don't cut hard.
6. **Then:** `python3 tools/beast_cut.py whole <file>.png <species>`, then
   `godot --headless --import`. That is my step; send me the PNGs.

### Why horse and ox come with their tack

Every horse in the game carries a rider and every ox pulls a wagon, so the
saddle, bridle and yoke are painted **as part of the animal**, not as separate
layers. The rig still supports separate `horse_tack`/`ox_yoke` layers for
later, but nothing here asks for them.

---

## STYLE-F (paste first, once)

```
You are painting animal sprites for a 2D side-view computer game, "Wayborne" -
a caravan trading and survival game inspired by medieval Anatolia. The
animals are working animals and wild animals of the road: a riding horse,
a draught ox, a steppe wolf, a brown bear, a wild boar.

EVERY ANIMAL IN THIS CONVERSATION:
- Side view, exactly in profile, facing RIGHT. No three-quarter view, no
  turned head, no foreshortening.
- The pose is given by the attached reference image: a grey mannequin
  walking right in mid-stride. Copy its four leg positions exactly. LIGHT
  grey legs are the NEAR side legs (closest to the viewer), DARK grey legs
  are the FAR side legs (behind the body). The near hind leg is lifted and
  swinging forward, the far hind leg is planted behind it; the near foreleg
  is lifted and swinging back, the far foreleg is planted ahead of it. Paint
  all four legs fully and clearly separated. Don't hide any leg behind
  another, and don't merge legs together.
- Keep the head, neck and tail direction of the mannequin.
- Hooves and paws that touch the ground sit on one flat ground line. No
  ground, grass, shadow, dust or scenery at all.
- Background: one flat, uniform mid-grey (RGB 140,140,140) everywhere. No
  gradient, no texture, no vignette, no cast shadow. The background will be
  removed.
- Nothing else in the picture: no rider, no people, no second animal, no
  props.

STYLE:
- Flat illustrative painting with a firm dark ink contour (#0E0D0F, never
  pure black) around every shape, flat colour areas with one or two soft
  shade steps, single light source from the top-left. Fur and hair are
  suggested with a few ink strokes, not rendered strand by strand. Think
  Darkest Dungeon's ink weight with Kingdom Two Crowns' calm silhouettes.
- NOT photorealistic, NOT 3D, NOT pixel art, NOT anime, NOT cute.
- Muted, low-saturation palette: bone #E1D9C7, ink #0E0D0F, pale gold
  #DCB357 (sparingly), dried blood #A83029, moss #5E6B3A, cold steel
  #6F7A82, earth browns and ashen greys.
- Anatomy must read at small size: a clear silhouette, a visible eye,
  readable ears, legs thick enough to hold the body.
- No text, letters, numbers, logos, brands, symbols or watermarks.

AVOID: three-quarter view, front view, rearing, running gallop, sitting,
lying down, background scenery, ground shadow, rider, harness straps
crossing the legs, glossy highlights, photorealism, 3D render, cartoon eyes.
```

---

## F. Whole animals in the rig pose

- **Aspect ratio:** 3:2. **Generate at:** the largest 3:2 size (≥1536×1024).
- **REFERENCE:** attach the named `docs/beasts/<species>_pose_reference.jpg`.
- **Output:** PNG with the background removed, file name `<species>.png`.
- **Ships as:** `data/assets/characters/beasts/<species>/*.png`, cut by the
  tool (nothing to crop by hand).

**F-horse · Riding horse (saddled)** · seed 61101 · REFERENCE
`horse_pose_reference.jpg`
```
Aspect ratio 3:2. Use the attached pose reference.
ANIMAL: A sturdy Anatolian steppe riding horse, bay brown coat (#5B3F2A)
with a darker mane and tail (#2A1E17), black lower legs, a small white star
on the forehead. Deep chest, strong short neck, head carried forward and
slightly down as in the reference. Tail hanging, slightly swaying.
TACK (part of the painting): a worn dark-leather saddle with a short
rolled blanket under it in faded dried-blood red (#A83029) with a thin
pale-gold edge, a simple leather bridle and headstall, reins resting on the
neck. The saddle sits on the middle of the back, above the ribs. No
stirrup leathers hanging across the near legs; the stirrup is tucked up
against the saddle. No saddlebags.
Matte, worn, travelled - mud on the lower legs.
```

**F-ox · Draught ox (yoked)** · seed 61102 · REFERENCE `ox_pose_reference.jpg`
```
Aspect ratio 3:2. Use the attached pose reference.
ANIMAL: A heavy grey-brown Anatolian draught ox (#6B5C4D, belly and legs
darker #4A3F35), a pronounced shoulder hump that rises above the withers
- the hump is part of the back line, not a lump stuck on top. Deep dewlap
under the neck, head carried LOW and forward as in the reference (the ox
leans into the yoke). Two wide, slightly upturned pale horns (#CFC4A8)
curving forward and up, one on each side of the head (both visible). Tail
long and thin with a dark tuft, hanging straight down.
TACK (part of the painting): a plain wooden neck yoke resting on top of
the neck just in front of the hump, with a padded leather collar strap
under the throat. No pole, no chains, no wagon - only the yoke on the
ox's neck.
Matte, dusty, tired working animal.
```

**F-wolf · Steppe wolf** · seed 61103 · REFERENCE `wolf_pose_reference.jpg`
```
Aspect ratio 3:2. Use the attached pose reference.
ANIMAL: A lean grey steppe wolf, stalking walk. Coat ashen grey (#6E6A66)
with a darker saddle along the back (#3E3A38) and pale bone-coloured
cheeks, throat and belly (#C9BFAE). Long legs, narrow chest, head held low
and level, ears upright and pointed, long muzzle with the lips slightly
drawn back (a hint of teeth, no gore). Bushy tail carried low and straight
back as in the reference. Pale amber eye.
Wild, hungry, dangerous - but not a monster: a real wolf.
```

**F-bear · Brown bear** · seed 61104 · REFERENCE `bear_pose_reference.jpg`
```
Aspect ratio 3:2. Use the attached pose reference.
ANIMAL: A massive brown bear walking on all fours. Dark brown coat
(#4A3526) with lighter tips on the shoulder hump and back (#6E5238), a
pronounced muscular hump over the shoulders, heavy round head carried low,
small rounded ears, short muzzle, small dark eye. Thick pillar-like legs,
broad paws with short dark claws visible on the ground. Tail almost
invisible (a short stub).
Heavy, slow, overwhelming weight - the biggest animal in the game.
```

**F-boar · Wild boar** · seed 61105 · REFERENCE `boar_pose_reference.jpg`
```
Aspect ratio 3:2. Use the attached pose reference.
ANIMAL: A wild boar, stocky and front-heavy. Coarse dark grey-brown
bristly coat (#3F3630) with a ridge of stiff longer bristles along the
spine (the mane), wedge-shaped head carried low, long snout with a flat
disc nose, two curved pale tusks (#E1D9C7) curling up from the lower jaw,
small eye, small pointed ears. Short thin legs with small cloven hooves,
short thin tail with a tuft.
Aggressive, compact, low to the ground.
```

---

## G. Part-sheet fallback (only if F fails)

If a species keeps coming back with merged or hidden legs, paint it as a part
sheet instead. This route is more precise, but it's harder for the model.

- **REFERENCE:** `docs/beasts/<species>_sheet_template.png` (1152×768, 3×3
  cells of 384×256). Row 1: body, neck, head. Row 2: tail, fore_upper,
  fore_lower. Row 3: hind_upper, hind_lower, foot. Red dot = the joint the
  piece hangs from, blue dot = the other end.
- **Aspect ratio:** 3:2. **Output:** PNG, background, mannequin and dots
  removed. Then `python3 tools/beast_cut.py sheet <file>.png <species>`.

**G-<species>** · seed 6120x (1 horse, 2 ox, 3 wolf, 4 bear, 5 boar)
```
Aspect ratio 3:2. Use the attached part sheet template.
The template is a 3x3 grid; each cell holds one grey mannequin body
segment of a four-legged animal, seen from the SIDE, facing RIGHT:
row 1 = body, neck, head; row 2 = tail, upper foreleg, lower foreleg;
row 3 = upper hind leg, lower hind leg, hoof/paw. The red dot is the joint
the piece hangs from, the blue dot the joint at its other end.
Paint the [SPECIES + the ANIMAL paragraph from section F] as separate
pieces: in each cell, paint that part of the animal exactly over the grey
mannequin, same position, scale and angle, lined up with its red and blue
dots, about 10-15% longer at the red-dot end so joints overlap. Keep the
image the same size and the grid the same layout. Flat mid-grey
(RGB 140,140,140) background, no dots, no mannequin, no cell lines in the
result. Style: [STYLE-F's STYLE section].
```

---

## PNG — background removal list

All of these come back as PNG with transparency (flat grey removed, soft fur
edges kept):

- **F:** `horse.png`, `ox.png`, `wolf.png`, `bear.png`, `boar.png`
- **G (only if used):** `<species>_sheet.png`

Tip: the grey is flat, so a colour select at tolerance ~15-20 plus a 1 px
feather works. Grey fur (wolf, ox) can sit close to the backdrop, so remove
only the grey **connected to the image edges**, not every grey pixel.
