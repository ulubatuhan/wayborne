---
name: kurallar-figur
description: Wayborne kural kitabının "İnsan ve hayvan figürleri, giysi ve iskelet" bölümü (CLAUDE.md'den taşındı). Şunlara dokunmadan, şunları tasarlamadan ya da şunlar hakkında karar vermeden önce yükle: FigureRig, WalkFigure, BodyFrames, Wardrobe, OutfitCatalog, giysi render'ı (tools/figure_pipeline/), MPFB beden, saç, kıyafet uyumu, FigureActions klipleri, BeastRig, BeastSkin, hayvan render'ı, yürüyüş döngüsü. Bozulmaması gerekenleri ve nedenlerini tutar.
---

# İnsan ve hayvan figürleri, giysi ve iskelet

CLAUDE.md'nin bu bölümleri 2026-10-30'da kullanıcı kararıyla buraya taşındı; metin değişmedi, başlıklar aynı. Koddaki
"bkz. CLAUDE.md <başlık>" başvuruları buraya bakar. Kural becerilerinin listesi CLAUDE.md'de ("Kural becerileri").
Bölümler: Wardrobe & Rig Rules.

### Wardrobe & Rig Rules

People are drawn on a skeleton, and anything a person wears or carries is
a set of sprite parts hung on its bones. Clothes (`OutfitCatalog`), armour
and weapons (`EquipmentCatalog`) go through the same door, so a sword
bought at the Demirci is in the hand on the road, in the hub, in combat and
in every preview the moment it is equipped.

- **One skeleton, one pose solver: `FigureRig`.** Joints (hip, knee, ankle,
  toe, shoulder, elbow, hand, fingers, head, weapon tip) come from
  `FigureRig.pose()` - the walk math `WalkFigure` used to carry inline,
  moved out so the road figure, the combat figure and the previews cannot
  disagree about where an elbow is. Fifteen bones, drawn in
  `FigureRig.DRAW_ORDER` (back arm and back leg behind the torso, front arm
  in front of it, the held weapon under the front hand so the fingers
  close over the grip). A seated rider has no back leg.
- **The knee bends toward the walk.** `_solve_joint` was called with the
  bend sign reversed for human legs, so every walker had chicken legs - a
  stick leg hid it, a painted trouser leg would not. `test_wardrobe.gd`
  asserts the knee side for both facings. The thigh/shin share also came
  down 0.52 → 0.51, because the rest pose - the pose the art is painted
  in - read as a crouch.
- **A part is painted once, at a reference size, in its rest pose.** Each
  of the nine parts (`FigureRig.PARTS`: head, torso, upper_arm, forearm,
  hand, thigh, shin, foot, weapon) has a fixed canvas and a pivot pixel at
  `REF_H` (512) scale. `FigureRig.part_transform()` puts the pivot on the
  bone's first joint, turns the rest direction onto the bone's current
  direction and scales by `h / REF_H`; a left-facing figure mirrors the
  part. Uniform scale, not stretch: the art keeps its proportions and the
  joints meet because the art was painted on the same mannequin. The back
  limb reuses the front art darkened (`Wardrobe.BACK_SHADE`) unless a
  `<part>_back.png` exists.
- **The planted foot goes back, and the arm swings with the opposite leg.**
  The phase only ever increases (`WalkFigure.advance`) while the world
  scrolls under a figure that stays put, so the foot on the ground must
  travel backward against the hip. `_leg` used `cos(phase)` for x, which
  slid the planted foot *forward* - every person in the game moonwalked,
  and no test saw it because a gait only reads across time, never in one
  frame. It was found when the 3D figure pipeline printed frames side by
  side. The arm had a second bug of the same kind: it swung with
  `sin(phase)`, a quarter cycle off the legs, so the arms opened widest
  while the feet passed each other instead of at the step. Both are
  `-cos(phase)` now; `tests/test_gait.gd` asserts the direction for both
  facings and the arm/leg correlation, and failed 16 times on the old code.
  `paint_pose()` moved both phases to `PI` and its joints are identical to
  0.01 px, so `rig_spec.json` and every painted delivery stay valid.
  `BeastRig` and the procedural `_draw_quad_leg` had the same `cos` stride
  and moonwalked too; both are `-cos` now (`BeastRig.paint_pose()` keeps
  the old path through `classic`, the same contract reason), and
  `test_caravan_layout` asserts the ox's planted feet go back.
- **A walk is checked against a real walk cycle, not against itself.** The
  player put a rendered frame next to a reference walk sheet, and it read
  as a kneeling figure: the trailing foot lifted flat behind a bent knee.
  Measured on the stick figure (`FigureRig.pose`, twelve phases), four
  things were wrong, and they are four rules now:
  - **60% of a step is on the ground** (`STANCE_SHARE`, Winter's gait
    data). At 50% there was no double support, so the moment the front
    heel struck the rear foot was already in the air, and the rear knee
    folded on every step.
  - **The swing foot rises while it is still behind** (`SWING_PEAK`,
    `SWING_X_EASE`) and only then reaches forward low to the heel strike.
    It used to peak exactly under the hip, which lifted the knee to the
    chest. Early in the swing the toe stays down (`foot_pitch`); a foot
    that flattened as it left the ground was the "kneeling" frame.
  - **The hip is lowest in double support and highest in mid-stance**
    (`cos(2·phase)` about the double-support middle). It was `sin`, a
    quarter cycle off.
  - **A leg does not stretch.** The limb length is the rest leg
    (`HIP_RATIO`), not the frame's hip height, and the hip drops until the
    planted heels are within reach (`REACH_SHARE`) - the same rule as
    FigureActions' open stances. A foot already on its toes does not pull
    the hip down; its heel rises instead (`HEEL_FREE_PITCH`). Measured:
    stance knees 9°, swing peak 60°, toe-off ~30°, which is the textbook
    curve; the old cycle stood on knees bent 25-35°.
  The cadence followed: with 60% stance a cycle carries the body
  `2·stride/0.6` (`FigureRig.CYCLE_DISTANCE_RATIO`), not `4·stride` - and
  every cadence in the game is now derived from it per figure (see Road
  Movement Rules' "the ground and the step are one measure").
  `paint_pose()` keeps the old leg path (`classic`) because its joints are
  the painters' contract (`rig_spec.json`); `test_wardrobe` confirms they
  did not move. The gait test now skips the one sample that straddles
  toe-off: the foot is still pushing back there, which is correct.
- **The held weapon hangs straight at rest and moves a third as far as the
  forearm** (`WEAPON_SWING_SHARE`). At the full forearm swing the blade
  swept 60° every step and walking read as fencing (measured on a
  rendered sheet).
- **Art is found by path, never listed.**
  `data/assets/characters/wardrobe/<item_id>/<part>.png`, checked with
  `ResourceLoader.exists()` (works in the Web export, unlike a directory
  scan) and falling back to a raw file on disk for art not yet imported.
  `Wardrobe.loadout_of()` returns the worn items that have art, bottom to
  top by `Wardrobe.SLOT_LAYERS` (shirt < trousers < shoes < jacket < armour
  < gloves < amulet < hat < weapon). An item without art stays procedural
  (colour and head shape through OutfitCatalog's resolvers) - art can land
  one item at a time. `wardrobe/body/` is the optional skin layer, drawn
  under everything and tinted by the character's skin tone.
- **The procedural body is still drawn under the sprites, bone by bone.**
  `WalkFigure` walks `DRAW_ORDER` and, per bone, draws the procedural limb
  and then that bone's sprite layers, so depth comes from the skeleton: the
  back sleeve is behind the torso, the front sleeve in front of it. With
  no art at all the figure is the one it always was.
- **Combat switches to the rig only when there is art to show.**
  `CombatFigure.uses_rig()` is true for a humanoid with a non-empty
  loadout; it then hosts a standing `WalkFigure` child, driving its
  position (lunge, shake), rotation (the fall) and a multiplicative state
  tone (`_state_tone()`: depth, downed, Death's Door, dead). Enemies,
  beasts and a party with no art keep the silhouette; a unit lying fallen
  is the procedural pile either way. `CombatUnit` carries `loadout`, `skin`
  and `height_scale` from the character.
- **Clothes change after creation too.** The character screen's
  "Görünüm ve Kuşam" section is a `FigurePreview` (the same `WalkFigure`,
  standing) beside the six outfit slots; equipment changes below refresh it.
  Character creation uses the same preview; the block-drawn
  `OutfitPreview` is gone.
- **The artist's templates are generated from the rig, not drawn by hand.**
  `tests/export_rig_spec.gd` writes `docs/wardrobe/rig_spec.json`;
  `test_wardrobe` fails if the JSON falls behind the rig. The painting
  route that read it (`wardrobe_templates.py`, `wardrobe_ingest.py`, the
  templates and `docs/wardrobe/README.md`) was deleted once clothes moved to
  3D renders; `rig_spec.json` stays because the figure pipeline, the
  mannequin and `wardrobe_cut.py` still read it.
- **People are a mannequin until their clothes are painted.**
  `tools/wardrobe_mannequin.py` draws a jointed, faceless body per gender ×
  body weight (`wardrobe/body_<gender>_<weight>/`, `wardrobe/body/` for the
  crew and enemies) from `rig_spec.json`'s canvases and pivots, in light
  grey with the volume in the shading. `WalkFigure._body_tone()` multiplies
  each part by what that person wears (shirt on torso and arms, trousers on
  the legs, boots, gloves, skin on head), so the road, the hub and combat
  already show the new body; a painted item simply lands on top. Combat
  uses the rig as soon as the body has art (`CombatFigure.uses_rig()`), and
  a class's weapon is drawn in the hand (`_draw_held_weapon`) until the
  weapon itself is painted.
- **A named person is now a pre-rendered frame, not a rotated part.**
  Every part approach below (painted, mannequin, cut render) turned each
  bone's picture about its own pivot, and the player photographed what
  that costs: claw hands, wedge feet, a kink at every knee. No threshold
  fixes it, because a joint between two separately rotated pictures is a
  seam by construction. `tools/figure_pipeline/` (rules: its `RULES.md`,
  history: `POSTMORTEM.md`) poses the MPFB body in Blender with
  `FigureRig`'s own clips (exported by `godot/export_clips.gd`) and renders
  **whole frames** in five depth layers (back arm, back leg, torso+head,
  front leg, front arm); `BodyFrames` (`data/assets/characters/frames/
  body_<gender>_<weight>/frames.tres` + atlas pages) holds them and
  `WalkFigure._draw_person_frames` plays them. One command rebuilds it all,
  incrementally: `python3 -I tools/figure_pipeline/build.py --all`.
  - **The pure mannequin wears only the base kit**: a tank top (male) or a
    bra (female) and shorts, both recoloured by the outfit's colours. No
    helmet, no archetype clothes, **no hair or brows** - those are modules
    added later at character creation (`BodyFrames.KIND_HAIR` is the slot;
    `render_frames.py --hair` renders one). The kit is painted onto the
    body's own surface from rest-pose bone heights, with a signed-distance
    ramp so the hem is a true plane section, not a jagged vertex edge.
  - **Hair is a garment now (task Y-G03).** Seven MPFB hair proxies (`hair_short01/02/04`, `hair_long01`,
    `hair_ponytail01`, `hair_braid01`, `hair_bob01`) are fitted by `fit_mhclo` like clothes (source `mpfb_hair`,
    slot `hair`, draw order 95, alpha-cut cards) and rendered grey, one frame set per body; the colour is a tint
    (`OutfitCatalog.HAIR_COLORS`, saved per person as `hair_color`, multiplied in `WalkFigure` through
    `hair_tint`). A hat hides the hair slot. Style and colour are chosen at creation, rolled for recruits and crew
    from the name's own seed (`OutfitCatalog.roll_hair`, weighted by gender; never the candidate roll's RNG), and
    backfilled the same way for old saves. Enemy looks carry their own `hair` and `hair_tint`. No turban or beard
    yet: no CC0 source fits the body.
  - **Skin and height stay player choices.** The body is rendered grey and
    multiplied by the skin tone, like the mannequin's ALBEDO contract.
    Height is one uniform scale over the whole frame
    (`CharacterData.get_height_scale()`, 155-250 cm, user's call) - six
    screens used to clamp it to 0.86-1.14 each, so nothing over 200 cm
    showed. Random recruits stay under `NATURAL_MAX_HEIGHT_CM`.
  - Crew use `BodyFrames.CREW_BODY`. Human enemies wear rendered garments on a body frame set too
    (`EnemyCatalog.LOOKS`, also read by the road's encounter markers): left empty they fell back to the old
    part rig and stood like mannequins beside the party (user report). The MakeHuman pieces read pale in
    combat light, so the kits lean on the Quaternius peasant/ranger pieces and the metal armours; `test_outfit`
    checks every look's body and pieces are rendered. The rest of this item is history (open: `QUESTIONS.md` #13-15 - the
    nude body pokes past a garment's edge where MPFB's delete group would
    hide it in 3D; the MakeClothes-era `qa/garment_tests.py` that measured it was deleted with that route).
  - **Clothes are worn, not painted on: each garment is its own frame
    set, rendered on the same body in the same pose.** The CC0 Quaternius
    "Modular Character Outfits" (`art_source/models/clothes/
    quaternius_fantasy/`) are fitted to the MPFB body by
    `blender/fit_garment.py`: their skeleton is aligned bone by bone to the
    MPFB rest pose (`inherit_scale NONE`, or the parts explode), the
    pose is baked, the skin faces are dropped, every vertex is pushed at
    least `eps` outside the body (BVH, smoothed, with MPFB's helper masks
    *on* - otherwise the tights/skirt helpers inflate the pants), and the
    weights are transferred from the body so the garment follows the same
    rig. `render_outfits.py` renders each item alone per variant x clip x
    frame through `render_frames.pose_clip_frame` - the body's own pose
    and root, one function, so a garment cannot drift from its body. The
    body is invisible to the camera but casts the shadow.
    - **Each garment is fitted over everything that can be worn under
      it, not just over the body - and that was a reported bug, not a
      refinement.** The first version wrapped each item to the body alone
      (eps .004 pants < .009 shirt < .013 jacket) and assumed the eps order
      was the layering. It is not: Quaternius geometry already stands off
      the body by more than eps in places, so the pants' waistband came out
      *through* the shirt and the shirt through the jacket (measured: 36%
      of covered shirt points outside the jacket). The player saw it on the
      first pilot render. `render_outfits.fit_all()` now fits items in
      `draw_order`; each one gets every lower-order item of another slot,
      every variant, as `inner`, and `fit_garment.fit()` runs three more
      steps after the body wrap:
      - `layer_over`: each point stands `gap` above the highest inner point
        within one edge length of the body point beneath it (one point was
        not enough - the jacket mesh is coarser than the shirt's and shirt
        detail rose between jacket vertices);
      - `resolve_pokes`: the same rule the QA uses (going from an inner point
        toward the body, you must reach the body before the outer garment).
        The outer face that is hit is pushed out. Where that does not
        converge, the inner point is pulled under it, and an outer face
        trapped beneath an inner one that already hugs the body is deleted.
        That is the hood's neck lining, which sits under the jacket collar;
      - `inherit_weights`: an outer point within 4 cm of an inner one takes
        that point's bone weights. Weights transferred from the body diverge
        in curved places (shoulder, armpit), and the two garments bent
        apart. A removal-while-iterating bug left half the old weights in
        place the first time.
      `render_outfits.layer_weights_all` then lets an outer garment inherit
      the limb layers of what lies beneath it (channel-wise max). Otherwise
      a jacket shoulder in the front-arm layer is drawn over a hood hem in
      the torso layer.
    - **A garment must keep its shape, and a stylised source has a
      stylised head.** The ranger hood shipped standing almost a head's
      height above the skull. Every QA number was green, and the player
      caught it from a screenshot. Two causes:
      - `align_skeleton` stretched every bone to its MPFB twin's length.
        Quaternius's `head` bone is 8.3 cm and MPFB's 15.6, so the hood grew
        1.88× vertically. End bones (head, hands, toes) only mark where a
        bone is drawn, so `NO_STRETCH` rotates them without stretching.
      - The Quaternius characters have big, stylised heads. Even unstretched,
        the hood's head part measured 30×33×38 cm against MPFB's 17×22×23.
        `snug_head` scales whatever sits on the head down to our head plus a
        margin, each side of each axis separately (the excess is on top).
        Each point is scaled by the head weight of the body point beneath
        it, so the cape stays on the shoulders. It is a soft blend.
      Tried and reverted: moving the cape's arm weights onto `spine_03` so it
      would not droop with the T-to-A arm drop. That bone is the one
      shortened most (0.73×), so the cape dropped further (height ratio
      1.26 → 1.91).
      The QA now measures shape, not just overlap: every garment's height is
      checked against its source height scaled by body size (0.85-1.15),
      and nothing may rise more than 6 cm above the skull. Snugged items are
      judged by the second rule only. Re-enabling the stretch fails it (hood
      2.19×). A QA that only compares the game against the 3D scene cannot
      see a garment that is wrong in both: it was faithfully reproducing a
      ridiculous hood.
    - **Pants close at the waist, the body never shows through, seams stay
      shut - the player saw all three, looking at the model rather than the
      game.** Every one of these was invisible in the game composite,
      because a garment is drawn over the body. The model view, the one
      the player asked to see, showed them:
      - *The waist.* Quaternius pants are low-rise. On our body the top edge
        stopped at 1.04 m against a waist (`spine_02`) at 1.09, so the top of
        the hips stayed bare. Stretching the pants up was tried and dropped,
        twice:
        - scaling per angular slice turned the waistband into a crown of
          spikes;
        - the ranger pants' back is a tight band over a seat panel, and
          lifting the band tore a hole between the two.
        `waist_sleeve` instead lifts the body's own surface, from hip to
        waist plus 1 cm, as a strip at half the cloth distance, joined into
        the pants mesh. Where the pants exist the strip is under them; where
        they do not, it closes the waist. It takes one cloth UV per face,
        from the pants body rather than its edge details: per-corner UVs
        landed on seam and belt islands and left pale patches. Its top is
        levelled to the waist line.
      - *Pass-through.* `wrap` kept the garment's vertices outside the body,
        but a body curve (thigh, crotch, chest) came out through the middle
        of a sparse cloth face. `cover_body` looks outward from inside the
        body under every nearby point; cloth reached before the skin is
        pushed out. The push is smoothed like `wrap` and capped per vertex
        (`COVER_MAX_PUSH`). Uncapped, it pushed the ranger pants' folded
        waistband out round after round into a flap.
      - *Seams.* Quaternius splits vertices along UV seams. Every later
        displacement moved the two copies apart and opened a white line down
        the side of the leg. `weld_seams` merges them first; UVs live on
        loops, so the texture survives.
      The QA checks the waist too: rays outward from the body strip just
      below the waist must hit the pants (≥ 95%; 100% on all six bodies).
      Counting vertex heights per angle could not be used: the waist ring is
      sparse, and a slice that held only a lower vertex read as "low".
    - **A boot has a sole, and the sole was lost before anyone looked
      underneath.** Reported from the approval sheet as "bot gibi değil":
      the soles came out 0-3 mm thick. Three causes, found by looking from
      the side and from below, not from the game's one camera:
      - *The two feet disagree about the ground.* Quaternius' sole sits
        ~1.9 cm under its ball bone with the toe sprung up; MPFB's foot is
        flat and deeper. Aligned bone to bone, the shoe's sole landed inside
        the body. `wrap` then pushed it out to `eps`, so the sole hugged the
        foot like a sock. The forefoot sat 1-2 cm above the body's toes.
        `add_sole` (before `wrap`; `sole`/`heel` in `outfits.json`, boots
        only) moves the bottom under a flat ground plane, `sole` below it
        and `heel` more at the heel. It works station by station from heel
        to toe (`SOLE_STATION`). The drop shears: full at the ground, zero
        at the ankle. Nothing folds and the shaft stays put. Two simpler
        measures failed. With a single lowest vertex, a sagging rim made the
        middle read "low enough" and the toes broke through. With a single
        highest point, one spot drove the whole forefoot down into clown
        shoes. Bottoms are found by casting rays up from the footprint
        against faces: the sole's corners are more than 2 cm apart, so a
        vertex search measured air.
      - *`cover_body` looked from outside the body.* It starts 3 cm inside
        the skin. Toes are thinner than that, so the start point was below
        the sole, the first cloth it met was the sole, and it pushed the
        sole up into the foot. The depth is now capped at half the body's
        local thickness. Sole corners below the ground are never pushed up
        (`keep_below`): the toe cap's large faces carried them up as they
        were pushed over the toes.
      - *Big heels.* On heavy bodies the heel sits ~3 cm behind the
        source shoe's heel, beyond `COVER_MAX_PUSH`, so it came out of the
        back. The heel cup is stretched back to the body's heel first.
      The QA checks the sole too: from every point of the body's sole,
      looking down must hit the shoe at least 0.6 × `sole` lower (≥ 95%).
    - **Repacked atlas pages keep their names, so check the import, not just
      the PNG.** After a full re-render the game drew every garment as
      scattered fragments. The new region table was being read against the
      old page, because `.godot/imported` still held the first pack.
      `--headless --editor --quit` had exited before it rescanned changed
      files; `--quit-after 3000` reimports. A local cache only (`.import`
      is not in the repo, CI imports fresh), but the in-game screenshot is
      the step that caught it. The Python composite was right the whole
      time.
    - **Test the fit before rendering, against the real thing.**
      `qa/outfit_check.py` fits everything exactly as the render does
      (`render_outfits.setup`), poses a few frames per clip, and for each
      combination compares the game's composite (the packed body layers,
      then each garment's layer masks in draw order) with one
      true-occlusion render of the whole outfit. It reports three numbers:
      - pixels that differ, ≤ 2%;
      - garment-for-garment swaps in either direction, ≤ 2%. This includes
        3D pass-through, which is what the player saw. The worst case left
        is one frame (attack 3, arm fully raised) at 1.6%, where the jacket
        shoulder passes through the hood's cape;
      - "bleed", the game drawing an inner garment over an outer one, ≤ 0.3%.
      The 3D poke count is reported for information only. The old,
      unlayered fit fails: composite 9.1%, swaps 9.1%. All six bodies pass
      with the layered fit. The worst remaining case is the hood's cape
      over a fully raised arm, where the game draws the hood on top. The
      QA's own first versions measured the wrong thing twice: the body
      helpers (MPFB's tights/skirt masks) were visible in the QA but hidden
      in the fit, and the poke ray ran outward, so a sleeve on an arm swung
      close to the torso counted as "outside the jacket". Both now use the
      fit's own rule. `WAYBORNE_NO_LAYERING=1` reproduces the old fit, so
      the gate can be shown to fail on it.
    - **Colour is the texture's, shade is the body's tones.** Two passes
      per layer like the animals (shade + unlit albedo, multiplied and
      posterised in `mesh/pack_outfits.py`). Quaternius feeds Base Color
      through texture x colour attribute (MIX/MULTIPLY), not a bare
      texture; `render_beast.albedo_material` only read a bare texture and
      the first renders came out white - `render_outfits._copy_upstream`
      copies the whole upstream node tree.
    - **One frame set per item x body** (`outfit_<item>_<variant>`, same
      clip/frame/layer layout as the body, only `KIND_BODY`). `walk_boots`
      takes the non-leg layers from `walk` shifted by the body's
      `base_dy_px`, exactly as `pack_frames.py` does for the body.
      Packed at half resolution (`BodyFrames.texel_scale` 2): the figure
      is drawn ~5x smaller than rendered, and full resolution was ~55 MB
      across 42 sets against ~16 MB now.
    - **The game draws them inside the body's layer loop**
      (`WalkFigure._draw_person_frames`): per layer the body, then each worn
      garment by `OutfitPiece.draw_order` (`OutfitCatalog.worn_frames`).
      The base kit (tank/bra + shorts) stays its own colour - tinting it
      with the jacket's colour showed green through an open collar. A hat
      with frames suppresses its procedural headgear; boots
      (`OutfitPiece.boots`) switch the walk to `walk_boots`. A piece
      without frames for that body falls back to its `color`, as do the
      combat silhouette and the old part rig.
    - **A garment comes out of the locker and goes back into it.**
      `GameSession.outfit_inventory` is the clothes counterpart of
      `equipment_inventory`: `wear_outfit()` takes the piece from the
      locker and returns whatever was in that slot, `take_off_outfit()`
      puts it back, and the character screen's arrows walk only
      `get_outfit_choices()` - what that person wears plus what the locker
      holds for the slot, disabled with its reason when there is nothing
      else. Character creation picks the starting clothes from the
      `starter` pieces only (the peasant kit): better clothes cost money,
      and a free pick at creation would make the tailor pointless. Recruits
      arrive dressed from their own seed (`RecruitCatalog._dress`, never
      the candidate roll's RNG), each slot weighted by the inverse of the
      price, so a guild hire in silk is rare. Old colour ids migrate on
      load (`OutfitCatalog.LEGACY_IDS`).
    - **Clothes are a small combat axis, priced by what they give.**
      `OutfitPiece` carries the same five bonus fields as `Trait` and
      `Equipment`, read by the same `CharacterData` getters
      (`_outfit_bonus_sum` beside `_equipment_bonus_sum`), so combat sees
      them through `CombatUnit.from_character` with no new wiring.
      Bonuses stay small: a whole ranger kit (+5 HP, +4 dodge, +2 accuracy,
      +2 crit) sits near one armour tier, not above it. The price is one
      formula, `OutfitCatalog.price_for(base, bonuses)`: the cloth and
      work (`base`) plus `STAT_PRICE` per point. Damage costs most and HP
      least, because dodge and damage swing a fight more than HP does (Ruin
      Rules' body A/B). A negative stat lowers the price, never below half
      the base. Pieces without a render (`art_id` empty) are real items
      too; the figure carries them in their `color` until they are drawn.
    - **The tailor never has everything.** `GameSession.get_tailor_stock()`
      rolls the stall from `location + day`, the recruits' pattern. A piece
      is on it with chance `40 / (40 + price)`, so silk is rare and linen
      common, and a bare stall is topped up to `TAILOR_MIN_PIECES` from the
      cheapest. Purchases are `tailor_sold` (saved, cleared on arrival), so
      a reload cannot restock what was bought. The buy price runs through
      `get_buy_price_multiplier()`, the same culture and trait discount the
      market reads. The tailor buys back at `OUTFIT_RESALE_FACTOR` (40%),
      far below the buy price, so buy-and-sell is not a money printer. A
      locked purchase shows its reason (sold out, not enough gold, on the
      road).
    - **The wardrobe shows things, not just names, and it is the whole
      person.** Asked for after a screenshot: pictures in the inventory
      and weapons beside the clothes. A garment's picture is its own
      rendered idle frame (`OutfitIcon`, bodiless, fitted to the box) -
      a second, painted icon would drift from what is worn; a piece
      without a render is a swatch of its colour in its slot's shape.
      Weapon, armour, ring and amulet sit below the clothes, read the
      same `equipment_inventory` locker as the character screen
      (`equip_to_character`), and show the level gate as a reason, never
      hidden. Equipment is not sold here: the smith sells, trinkets are
      found.
    - **The wardrobe is a city screen, and dragging is a shortcut.**
      `wardrobe.tscn` (the city's "Kıyafet Dolabı" button) shows the chosen
      person standing beside the six slot boxes, with the caravan locker
      and the day's tailor stall next to them. Drag a locker card onto
      its slot box to wear it, a slot back onto the locker to take it off,
      a card onto the tailor to sell it. Each drop calls
      `set_drag_forwarding` and accepts only what fits (a shirt never lands
      on a shoe box). Every drag has a button (Wear / Take off / Sell / Buy),
      because a decision needs a visible control (Road Movement Rules).
    - **The second source is MakeHuman, and it is what made 48 garments
      possible.** Quaternius ships two free outfits; the MakeHuman community
      packs fit our body without alignment, because our body *is* an MPFB
      (MakeHuman) body. `fit_garment.fit_mhclo` loads a `.mhclo` proxy
      through MPFB, strips what MPFB added to the body, and runs the same
      wrap → cover → layer → poke → weights chain. Licences per item in
      `art_source/models/clothes/makehuman/LICENSES.md`; the CC-BY authors
      are credited in-game (Settings → Credits, `Credits`) and in CREDITS.md.
    - **A garment has a thickness shell, or ten of them stack into a
      balloon.** Each item is fitted over every lower item it could be worn
      over; with ~10 candidates under a coat the union envelope swelled the
      coat. `clamp_shell` pulls each inner garment to at most `shell` metres
      off the body (pants 3 cm, shirts 4.5, armour 4), so the outer one sits
      on a bounded layer.
    - **`hides` and `genders` are one list each, read by both sides.**
      A dress hides pants, a robe hides shirt and pants: the fit does not
      inflate over the hidden slot and `OutfitCatalog.worn_frames` does not
      draw it (its stats still count). A gendered item is rendered only for
      those bodies and `OutfitPiece.fits()` keeps it out of the other
      gender's choices, the tailor wear button (disabled with its reason),
      character creation and recruit dressing.
    - **Armour is fitted cloth, not a rigid model.** The approved Quaternius
      cuirasses were tried rigidly (scaled to the torso, then shelled) and
      came out as shells floating round the chest. Leather and plate are now
      the quilted tunic in dark leather and bright steel, mail the knit
      sweater in steel (the knit reads as rings). `CharacterData.
      get_appearance_outfit()` adds the equipped armour tier
      (`OutfitCatalog.ARMOR_ART`) at draw order 36 - figures read that, the
      saved outfit never contains it.
    - **The apron was cut.** Fitted over every skirt it could cover, it was
      pushed out to the widest flare and hung off the body as a ribbon; a
      broken garment is worse than a missing one.
    - **Leather is leather-coloured.** Tints are palette colour × texture
      luminance (`TINT_LUM`); the leather family sits at
      (0.52,0.30,0.14)…(0.36,0.20,0.10) after the first pass read pale.
    - **Frame first, item second.** The render loop used to pose the body
      per item per frame, and every pose re-evaluated all ~45 hidden
      garments - posing cost more than rendering. Posing once per frame and
      rendering each item under it is 2.5x faster; renders are at half
      resolution (`resolution_percentage` 50), which `pack_outfits.py`
      reads from the image width (coordinates ×2, no shrink).
    - Checked across the cycle, not in one pose: `tests/screenshot_outfits.gd`
      prints eight walk phases plus idle/attack/hit/dead per body x outfit;
      `test_outfit.gd` asserts every item has a frame set for all six
      bodies with the body's exact clip layout.
  - Atlas pages carry mipmaps from import: frames are drawn ~5x smaller than
    rendered. `.import` files are not in the repo, so the setting lives in
    `project.godot`'s `[importer_defaults]` (task 5.2), which CI applies to every
    texture; `TextureLoader.with_mipmaps` only builds a copy for a raw file not
    yet imported. An existing local `.import` keeps its old setting until its
    cache entry in `.godot/imported` is deleted.
  - **Atlas pages are packed tight, and a page's name carries its content (task 5.4).** Every packer ends with
    `mesh/repack_atlas.py`'s `repack_set`: identical pieces share one rectangle, the rest are skyline-packed tallest
    first, and page height rounds to 64 px rather than a power of two. Measured: 1139 pages / 473 Mpx became 295 / 182
    Mpx with the same `rects` contract. Pages are named `page_<k>_<md5>.png`, so a rewritten page never reuses a cached
    import; after a repack run `--headless --editor --quit-after 3000` (plain `--import` skipped the new files).
  - `tests/test_body_frames.gd` locks the contract: all six variants exist,
    entry counts agree, feet touch the ground line, garments stay inside
    the body. `tests/screenshot_body_range.gd` prints every variant across
    heights and skin tones; `tools/figure_pipeline/godot/perf_50.gd` times
    fifty walking figures.
- **What a person holds or wears bends the pose, so the pose comes from
  one library: `FigureActions`.** Walking is `FigureRig.pose()`; every
  other stance is a keyframed clip there (`stance_melee`, `stance_bow`,
  `aim_bow`, `attack_swing`/`_thrust`/`_bow`, `hit`, `defend`, `dead`,
  `downed`), and the 3D pipeline exports the same dictionaries
  (`godot/export_clips.gd`), so a stick-figure check
  (`tests/screenshot_poses.gd`, seconds) and the render (hours) cannot
  disagree. `clips_for_weapon()` picks a family's stance and attack; the
  frame set carries each frame's weapon angle and bowstring draw, so a
  sword turns through the swing and the string reaches the back hand at
  full draw.
  - **A leg does not stretch: an open stance lowers the hip.** The first
    library pulled an out-of-reach foot up to the hip instead, and the
    bow stances stood two pixels off the ground - `test_figure_actions`
    caught it, along with a dead body with one knee in the air and a
    propping hand below the ground.
  - **A lying pose is centred on its ground point**, or rotating about the
    hip puts the head half a body away and off the render canvas (it did;
    `qa/run_build.py`'s `inside_canvas` now fails on it).
  - **The ankle articulates, and a boot limits it.** `FigureRig.foot_pitch`
    rolls the foot through heel strike and toe-off; `ankle_range` scales it
    (bare 1.0, `BOOT_ANKLE_RANGE` 0.35 for `shoes_boots` - sandals walk
    barefoot). `walk_boots` renders only the leg layers and takes the rest
    from `walk`'s same-phase frame, rooted on that frame (`base`). A stiff
    ankle cannot reach as far down, so rooting on `walk` alone left the
    heel-strike feet up to 4 px in the air; the boot pose is lowered onto
    its own ground and the borrowed layers move by the same amount
    (`base_dy_px` in `joints.json`, applied at packing), so the hip drops
    with the legs instead of tearing away from them.
  - **Carried things sit on the back the render measured.** Two markers on
    the 3D back surface (`back_upper`/`back_lower`, at the spine bones'
    rest heights) travel with every frame; the slung bow, spear, sword and
    the pack are laid along that line (`WalkFigure.back_frame`/
    `slung_points`). The bow used to hang from a fixed offset off the
    shoulder and floated behind the back - reported from a screenshot,
    now `test_action_frames` measures that it touches the back.
  - **Combat plays clips, not just shoves.** `CombatPanel` stamps a role on
    the attacker (`attack`, `CombatFx.ATTACK_MSEC`) and the target (`hit`
    on a hit, `defend` on a miss); a fall plays `hit` and lands on the
    `dead`/`downed` frame instead of tipping the standing figure over and
    swapping to the procedural pile.
  - **The ground is the body, not the arm.** Rooting a frame on its lowest
    vertex lifted a propped-up figure onto its hand (the hip floated 43 px
    in `downed`); the arms are excluded from the support set.
- **Animals render through the same five layers.** `beasts/render_beast.py`
  poses each Quaternius model with its own `Walk`/`Idle`/`Attack*`/
  `Idle_HitReact1`/`Death` and renders far fore leg, far hind leg, body,
  near hind leg, near fore leg into the human slots - `BodyFrames` plays
  them unchanged (`beast_<species>`, `ref_share` = the species' withers
  ratio). Colour is the model's own: each layer is rendered as the human
  grey shade and as unlit albedo and the two are multiplied
  (`pack_beasts.py`), so an animal sits in the same four tone bands as a
  person. Bear and boar ship without animation; `synth_actions.py` keys
  sagittal bone rotations for them. Lying them on their side was tried and
  dropped - the side camera then shows the animal from above, a box.
- **The mannequin is gone from the shipped art: the body is a render of a
  real human now** (`tools/human_body_render.py` fits and poses it,
  `tools/human_body_parts.py` writes the parts). Seven rounds of asking an
  image model for the nine parts had already failed, and the answer was the
  one the animals reached first - stop prompting, render. The source is
  Blender Studio's CC0 "Human Base Meshes"; `GEO-body_male_realistic` and
  its female counterpart are fitted with `FigureRig`'s own skeleton, posed,
  and rendered.
- **A body is NOT cut, and that is the one decision this whole section turns
  on.** The first version went through `wardrobe_cut.py` exactly like a
  garment, "because to that tool a render and a painting are the same
  thing". It was rejected on sight, and the mannequin was put back before
  it reached `main`. The measurement that
  settled it was an A/B against the mannequin in the *rest* pose: every
  joint showed its cut. Pulling the ink inward turned the seam into a black
  notch, leaving it outward into a white one - two faces of the same thing,
  and no threshold closes it, because a piece cut in one pose and then
  turned about its own pivot stops meeting its neighbour the moment the
  pose changes. A garment has no choice: it arrives as one painting. A body
  does, because it has a 3D source. So **each part is its own closed mesh,
  rendered alone in its own canvas** - the parts simply overlap, exactly
  like the mannequin's tubes, but with a real body's silhouette.
  - **It is the same wall the animals hit** ("A walking animal is one skin,
    not nine parts"). They answered it with one continuous skin; a person
    cannot, because `Wardrobe` hangs removable garment layers on the same
    bones and so the body has to stay separate part canvases. Rendering
    each part on its own is the other answer, and it is the one the
    mannequin was already using.
  - **A part's two ends are different problems, and one weight threshold
    cannot answer both.** With a single 0.16 share, `upper_arm` ran to
    x=-0.084 against a shoulder joint at -0.171 - half the chest swung with
    the arm and read as a pauldron - and `thigh` carried the pelvis from
    0.619H down against a hip joint at 0.533H, so the seat split between two
    swinging legs and the hips read as nothing at all. Raising the share to
    0.45 fixed both and opened every joint instead: with no overlap left, a
    bent knee and elbow showed daylight. All three were one player report
    ("omzu kötü, boynu çok önde, kalçası zayıf") and one cause.
    `human_body_parts.py` therefore answers the ends separately: a part
    takes everything its own bones touch at all (`PART_MIN`) - the reach
    past the far joint, where the neighbour is the next limb and the overlap
    is wanted - and gives back whatever the girdle strongly owns
    (`GIRDLE_MAX`), the near end, where the neighbour is the torso. The
    torso claims the girdle at the same permissive share, so a limb's
    trimmed root always lands inside mass the torso already carries: the
    overlap is guaranteed by construction, not by a number. `DRAW_ORDER` is
    what makes it read - the torso is drawn over both thighs and under the
    front arm.
  - **The head's forward lean was the skeleton sitting outside the neck.**
    Every joint was pinned to Y=0, which is the *mesh's* origin and not the
    body's own centre line, and nobody had checked the difference. Measured,
    the chest sits +0.9 REF px off that origin and the hip +3.9, so pinning
    them there costs nothing - but the neck sits +9.8 and the skull +11.0
    (female: +17.4 and +13.0). A neck bone on Y=0 runs outside the neck it
    drives, and the retarget, which puts that bone on the figure's own
    vertical axis, carried the whole head forward by the difference: on the
    part itself the skull centred +16..+20 px forward of the shoulder pivot
    against the rig's own +6. `measure()` now gives the neck and the skull
    their own axis (`neck_base`, and `head`/`head_top` on the skull's
    centre, which is exactly what the rig's head joint means - the paint
    pose puts the crown `head_radius` above it); measured again, +7..+10.
    Nothing else moved, on purpose: the spine, the clavicles and the arms
    keep the chest's axis.
  - **The hand is closed in 2D, not posed in 3D.** The mesh's hand is an
    A-pose hand and at the 45 px figure the road draws, five separate
    fingers read as a claw - which is why the mannequin drew a mitten with a
    thumb in the first place ("hands grip, they do not wave"). A binary
    closing fuses them and the new pixels take the nearest painted one's
    tone, so the fill is the hand's own shading. Posing the fingers would
    mean inventing finger bones the rig does not have and cannot drive, for
    a shape three pixels wide on screen.
  - **An unrigged mesh is not a blocker, it is the bear again.** The bundle
    carries no armature at all (measured: zero `AR` datablocks), and
    `tools/beast_prep_blend.py` had already fitted a skeleton to an unrigged
    CC0 bear and bone-heat weighted it. Here it is easier, because the
    target skeleton is not guessed - `FigureRig` owns it and `rig_spec.json`
    exports it.
  - **The joints are measured off the mesh, and three measurements were
    wrong before they were right.** The crotch is the floor of the mesh's
    mid-sagittal strip, after two island-counting versions each returned the
    top of their own search range (the arms hang past the crotch in an
    A-pose, and the quad grid's ring spacing in the groin reads as a split).
    The shoulder is a ratio of height, because only the forearm and hand can
    be seen by a cross-section and two attempts to recover the joint from
    that stretch extrapolated 2.5x past their own data. The elbow and wrist
    are read off the arm's own measured centres, which is how the female
    model's bent A-pose arm stopped being forced onto a straight line.
    The fit it produces matches the rig it is retargeted to: hip 0.533H
    against the rig's 0.537, shoulder 0.832H against 0.841.
  - **A bone turns, it does not get a new roll.** Building a pose basis from
    scratch has to invent the bone's spin about its own axis, and inventing
    it rotated the torso far enough that the head rendered nearly front-on
    in what is supposed to be a side view - the bug hid for several rounds
    because the figure still looked like a figure. The rotation is the
    minimal one from the bone's rest direction to the target, applied to the
    bone's own rest matrix.
  - **The retarget stretches bones on purpose**, which `BeastRig` forbids
    for exactly the opposite reason: a stretched bone is wrong for an
    animation and right for one still frame that has to land on a fixed
    template. Every bone's head and tail go onto their `rig_spec` joint,
    length included, so a part's pivot and its bone end are the rig's own
    and not the model's - which is what lets a part hang on `FigureRig`
    with no fitting at all. (It is also what the cut route needed, back
    when the figure was divided by regions built from the mannequin; that
    reason is gone, this one is not.)
  - **Linear blend skinning, with a clavicle, beat the clever options.**
    Dual-quaternion (`use_deform_preserve_volume`) was tried for the
    shoulder's ~90 degree swing and measured worse on both counts -
    ballooned upper back, chest and waist torn into self-intersecting
    shards, clenched feet, region coverage 98.6% -> 95.9%. A clavicle bone
    catches the chest instead, so it stops following the arm.
  - **The sole is this rig's ankle.** The rig puts the ankle ON the ground
    and runs the foot bone flat along it, so the leg's whole length is knee
    to ground. Fitting the 3D ankle at its measured anatomical height
    (0.094H) and then retargeting it to the ground stretched the shin by a
    third and sank the sole 65 px below the ground line.
  - **Body weight is a front-to-back thickness, not an all-axis scale.**
    The camera looks along X, so widening X is invisible; only Y reads in a
    side view. Thickness is scaled about the body's own Y centreline per
    height, so the silhouette grows without the figure drifting off its
    feet, and it reuses the mannequin's own `WEIGHT_SCALE` so a body weight
    means the same thing before and after. Measured, lean -> heavy is
    124k -> 157k px (female) and 134k -> 170k (male).
  - **The body is rendered light neutral grey**, the mannequin's ALBEDO
    contract unchanged: `WalkFigure._body_tone` multiplies a colour into
    every part, so a body painted with a skin tone could never be re-tinted
    and the player's skin-tone choice would silently stop working.
  - **A rendered body writes no back limbs at all**, which is the opposite
    of what a garment does. `wardrobe_cut.py`'s `BACK_MIN_SHARE` exists
    because a far sleeve cut out of one painting can genuinely differ; two
    renders cannot, because both sides are posed to the same `rest_joints`
    (the spec stores one value for `elbow_front` and `elbow_back`) on a
    symmetric mesh. Measured on the full set: area ratio 1.00 and mean tone
    within 2/255 on every limb. Writing them is not merely redundant, it is
    a loss - `Wardrobe` *prefers* a `<part>_back.png` over its own
    `BACK_SHADE`, so the far limb would be drawn at full brightness and the
    only thing separating it from the near one would be gone. It shipped
    that way for one round, because `BACK_MIN_SHARE` was inherited from the
    cut route and never re-asked.
  - **The body carries no contour, and that is a reversal.** The first
    version inked every part's whole perimeter on the general rule that
    this is a flat-ink game. But a part is a closed shape, so its perimeter
    includes the end buried inside the body, and the ink landed there too:
    a hard arc over the deltoid (read as a pauldron), a line under the seat
    (read as shorts), a ring at the neck (read as a collar). The ends are
    the one place a line is wrong and also the only place the parts have to
    meet, so there is no width that fixes it - rejected by the player on
    sight, the same family as the leather chrome and the G5 scratch-out.
    `--ink` keeps the switch rather than the argument.
  - **A part is rendered alone, so the body's parts are checked by walking
    it, not by an IoU.** The cut route's own numbers (holes, spill, an
    `OVERLAP_PX` sweep) measured how faithfully a division reproduced a
    picture - a question that no longer exists. What can go wrong now is a
    joint that opens or a girdle that swings, and neither is visible in a
    still: `tests/screenshot_mannequin_walk.gd` prints one figure across
    eight gait phases, any number of body folders as rows, which is how all
    three of the reported defects were found and how each fix was checked.
  - **`wardrobe_mannequin.py` stays, and re-running it undoes all of this.**
    It is the only thing that can regenerate a body for a rig that changed
    shape, and the bone regions `wardrobe_cut.py` assigns a *garment* by are
    still built from it - but it writes to the same six folders.
- **A garment is painted whole, worn, then cut - the same lesson the animals
  already taught, finally applied to people.** The part-sheet route
  (`wardrobe_ingest.py sheet`: nine cells, each with a grey stand-in and
  joint markers) failed seven rounds running - hair, skin tone and the
  weapon cell leaking across boundaries, the style drifting, "match the
  forearm's detail to the upper arm" re-read as "merge the two cells". That
  is not seven bad prompts, it is this file's own sentence about beasts
  (*"Nine disjoint parts aligned to joint markers is not something an image
  model does reliably; one side view is"*) coming true a second time, for
  the same reason. So a garment is now painted **once, worn, on one side
  view**, and `tools/wardrobe_cut.py` gives every painted pixel to the bone
  whose body region it sits on and unrotates each piece into its part canvas
  - `beast_cut.py whole`, for humans.
  - **A human side view self-occludes far more than a quadruped's**, so the
    pose had to be built rather than picked. `FigureRig.paint_pose()` is
    deliberately **not** a walk frame: legs open with `cos(phase)` and arms
    with `sin(phase)`, so they are widest at *opposite* phases and no single
    frame opens both - the beast's one `PAINT_PHASE` compromise left the far
    limb half-buried. The pose takes the legs from their own widest phase
    and the arms from theirs and merges them; the two share a torso exactly,
    because the hip bob is `sin(phase*2)`, zero in both.
  - **Per-part recovery is the wrong thing to measure.** The cut thigh
    matches its mannequin original at IoU 0.43, which reads as a disaster
    until you notice `DRAW_ORDER` paints the torso *over* the thighs: the
    pixels the cut "lost" are the pixels nothing ever draws. The honest
    measurement is to rebuild the figure from its own cut parts and redraw
    it - **0.04%** of the silhouette lost in the pose it was painted in,
    **4.2%** in the rest pose, the furthest pose from it. `OVERLAP_PX` was
    then swept against that number rather than guessed (the table is in the
    tool), reading a hole as worse than an overlap: a hole shows background
    through cloth, an overlap only lays cloth on matching cloth.
  - **A back limb gets its own file only if the painting really showed it.**
    The far upper arm hides behind the torso in any side view and comes back
    a sliver (73 px against the front arm's 3447). Writing it would be worse
    than writing nothing, because `Wardrobe` *prefers* a `<part>_back.png`
    over its own `BACK_SHADE` fallback - so a scrap of sleeve would replace
    a correct darkened one. `BACK_MIN_SHARE` drops it.
  - **A cut piece has to be proven across the pose it will actually move
    through, not the one pose it was cut in - and this file already said
    so before it was ignored once.** The "per-part recovery" measurement two
    bullets up exists *because* a cut that looks perfect in `paint_pose()`
    can fail everywhere else - that is its entire point. A Quaternius-sourced
    garment delivery (Faz "ikinci sanat turu" follow-up) was checked only in
    a frozen standing pose, which is exactly `paint_pose()` again by another
    name, and called done. It shipped with a visible bare-skin gap at the
    elbow (the stock `OVERLAP_PX`, tuned against loose hand-painted cloth,
    wasn't enough for a tight-fitted 3D-sourced sleeve) and a `hand_back.png`
    that floated disconnected from its own arm through most of the gait -
    both invisible in the one pose checked, both obvious the moment a real
    `screenshot_mannequin_walk.gd`-style sweep ran across several phases.
    The fix was cheap (`--overlap 26` instead of the default 12, and
    dropping a `_back.png` that technically cleared `BACK_MIN_SHARE` but
    wasn't actually tracking its arm) - the mistake was never running that
    sweep before calling the work finished. Any new cut content, from
    anywhere, gets the gait sweep before it is shown as done, not after
    someone else finds the gap.
  - **The reference is the real mannequin, not a stand-in.**
    `tools/wardrobe_paint_reference.py` hangs the shipped body art on the
    paint pose through the very same transform `part_transform()` uses, so
    the body the painter dresses and the regions the cutter assigns by are
    the same shape by construction. Only the garment is painted on it, never
    the body under it: each item is its own layer in `SLOT_LAYERS`, and a
    jacket carrying a copy of the torso would paint over the shirt beneath.
  - **The pose is now part of the contract.** Changing it invalidates every
    delivery painted against it, because the cut assigns pixels by that
    pose's own bone regions. `rig_spec.json` carries it as `paint_joints`.
- **Animals have their own skeleton, and it is one skeleton for five
  species.** `BeastRig` (horse, ox, wolf, bear, boar) hangs sixteen bones -
  body, neck, head, tail, and upper/lower/foot for four legs - on the same
  solver as people (`FigureRig.solve_joint`, `part_transform` with the
  beast's own `REF_H`); only the `SPECIES` proportions differ, so the artist
  paints the same nine parts for every animal. The walk is the one
  `WalkFigure` always had (four beats, same stride and lift), and the
  forelimb's knee bends forward while the hind hock bends back - bending
  both forward is the four-legged version of the chicken-knee bug
  (`test_beast_rig` asserts both, for both facings).
- **A species switches to art only when its body has art.**
  `BeastRig.has_sprites()` reads `beasts/<species>/skin.tres` or
  `beasts/<species>/body.png`; without either the
  animal stays the procedural one (`WalkFigure._draw_quadruped`,
  `CombatFigure._draw_beast`), so art can land one species at a time and a
  head alone is never glued onto a procedural body. The rider still sits on
  the skeleton's own `saddle` joint, never on a guessed height. Layers drawn
  over a species (`horse_tack`, `ox_yoke`) are listed in `SPECIES.layers`
  and used only when they have art. A combat beast is fitted into its slot
  by the rest pose's `extent()` and scaled by the archetype's `bulk`, so a
  bear still fills the slot and a wolf does not; `CombatFigure` hands its
  frame's lunge/shake/fall transform in as `base`, so a sprite animal
  recoils and falls exactly like a procedural one.
- **An animal is painted whole, then cut.** Nine disjoint parts aligned to
  joint markers is not something an image model does reliably; one side
  view is. `BeastRig.PAINT_PHASE` is a mid-stride pose with all four legs
  apart (in the rest pose the far leg hides exactly behind the near one, so
  it could never be cut out), and `tools/beast_cut.py whole` (deleted -
  the skin route below replaced it) fitted a painting onto it by its
  bounding box, gives every pixel to the nearest bone's grown mannequin
  region (nearer bones win overlaps, the tail beats the rump), keeps
  `OVERLAP_PX` of each neighbour so a bent joint shows fur rather than a
  gap, and unrotates each piece into its part canvas - far legs as
  `<part>_far.png`. Only `docs/beasts/beast_rig_spec.json` survives, read
  by `tools/beast_skin.py` and `test_beast_rig`.
- **A walking animal is one skin, not nine parts.** Cut parts each turn
  about their own pivot, so a joint either opens a gap or piles two pieces
  on top of each other - measured both ways (bare parts gapped at every
  knee mid-stride; `OVERLAP_PX` margins then stacked fur on fur). Humans
  hide this under the procedural body; a beast has none. `BeastSkin`
  (`skin.tres`) is the Spine/DragonBones answer: one continuous picture per
  depth layer (`far` legs, `tail`, `main`) with a triangle grid over it,
  every vertex weighted to up to three bones, deformed by linear blend
  skinning (`BeastRig.skin_deform`) and drawn with
  `canvas_item_add_triangle_array`. A skin wins over parts in
  `draw_species`; `pose()`/`extent()`/`draw_sprites()` stay untouched.
  - **The pose is the art's, not the mannequin's.** `skin_pose` reads the
    joints the skin was painted on, so at `motion` 0 every vertex is exactly
    where it was painted (asserted < 0.1 px) - the same gait constants as
    `pose()`, other proportions.
  - **A bone only turns, it never stretches.** Knees are solved with the
    art's own bone lengths and bend side (`skin_bend`); a stride longer than
    the leg lifts the foot rather than stretching the shin, and the nod and
    tail sway rotate their tip (`_swung`) instead of sliding it.
    `test_beast_rig` asserts every bone length across the gait and that no
    opaque triangle flips (`MAX_FOLDED`, set just above measured).
  - **`tools/beast_skin.py` builds it from a rigged glTF**: the artist's own
    skin weights, mapped onto our sixteen bones, sampled per grid vertex,
    diffused so a joint bends over a band rather than a crease
    (`SMOOTH_ITERATIONS`, `HINGE_BAND`). Stored as a `.tres`, because the
    Web export ships resources only - a `.json` would be missing there.
    Restyling is repainting the three layer PNGs inside the same silhouette.
