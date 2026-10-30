---
name: kurallar-arayuz
description: Wayborne kural kitabının "Arayüz, hareket, gezinme, kayıt ve çeviri" bölümü (CLAUDE.md'den taşındı). Şunlara dokunmadan, şunları tasarlamadan ya da şunlar hakkında karar vermeden önce yükle: Waybook teması, UiTheme, ekran ve panel yazmak, CombatFx ve hareket eğrileri, SceneInk, Nav ve gezinme yığını, ana menü ve başlık ekranı, kayıt yuvaları, InGameMenu, çeviri CSV'leri ve tr(), font ve glif. Bozulmaması gerekenleri ve nedenlerini tutar.
---

# Arayüz, hareket, gezinme, kayıt ve çeviri

CLAUDE.md'nin bu bölümleri 2026-10-30'da kullanıcı kararıyla buraya taşındı; metin değişmedi, başlıklar aynı. Koddaki
"bkz. CLAUDE.md <başlık>" başvuruları buraya bakar. Kural becerilerinin listesi CLAUDE.md'de ("Kural becerileri").
Bölümler: Title Screen Rules, Waybook UI Rules, Motion Rules, scripts/world/, World Navigation Rules, Save & Menu Rules, Localization Rules.

### Title Screen Rules

The opening screen used to be the main menu itself, buttons and all, the
instant the game launched - "a simple technical step" rather than the
first beat of the game's own tone. It now opens on a night camp (the
rendered `camp` scene, one fire, the town on the far hill) with nothing on
it but a slowly pulsing invitation, and only turns into the menu once the
player does something: a dark strip slides in from the right with the
title, the caravan's lineage line (name, generation, day - read from the
autosave summary) and the box-less `InkMenu`. The procedural dusk vista
(`MenuBackdrop`) and the leather book (M1/M2) it replaced are deleted; the
bullets below that name them are history.

- **It's a phase of `MainMenu`, not a separate scene.** The whole point was
  a transition that doesn't cut - "the screen must not go black and
  reload." A dedicated title-screen scene that `change_scene_to_file`s
  into the main menu would rebuild `MenuBackdrop` from scratch, restarting
  the caravan's walk-the-road loop at the exact moment it's supposed to
  read as continuous. `main_menu.gd` instead starts in a title phase
  (prompt visible, buttons transparent and disabled) and reveals the menu
  in place on the first qualifying input, in the same scene, the same
  backdrop, the same frame.
- **The buttons are transparent, not invisible, during the title phase -
  measured, not assumed.** The first version set the button box's
  `visible = false`. `VBoxContainer` only lays out its children while
  visible, and hiding it in the very frame it's created meant it never got
  a layout pass at all - a screenshot caught every button collapsed onto
  the same point, reading as one smeared label instead of a menu. Setting
  `modulate:a = 0` instead of `visible = false` keeps the container live
  for layout purposes the whole time; only its rendered alpha (and each
  button's `disabled` flag, so nothing is clickable through the fade) is
  what hides it.
- **The phase runs once per process, not once per visit.** Returning from
  Settings re-loads `main_menu.tscn` (every `Nav` transition is a scene
  change), which would replay the whole "press a key" ritual on every trip
  back to the root if nothing remembered it had already happened. A
  `static var` on the script itself - the same GDScript feature `Nav`
  already leans on for `recruit_venue` - survives exactly as long as the
  process does, which is exactly the lifetime this needs.
- **A city's gate opens once, and only for a real entrance.** Both ways
  into `city_map.tscn` that are actually "walking through a gate" -
  finishing a road journey, and crossing the gate spot in `world_hub` -
  set `Nav.city_gate_opening` before the scene change; `city_map.gd` reads
  it once and clears it immediately. It can't be a check like
  `is_journey_active()`, because leaving a sub-screen (market, guild) also
  reloads `city_map.tscn` and would replay the creak on every single trip
  back from browsing the stalls. Same pattern as `recruit_venue` and
  `character_target_index`: data one screen hands the next, not state
  either screen owns.
- **A full-screen `Control` that never sets its own `mouse_filter` still
  stops every click underneath it.** Reported as "can't skip the title
  screen by touching my phone" - measured, it wasn't touch-specific: a
  real mouse click didn't work either, only keyboard did. `MainMenu`'s
  root `Control` covers the whole viewport and never overrode its default
  `mouse_filter` (`STOP`), so it absorbed every pointer event before
  `_unhandled_input` ever saw it - the buttons, scrim and prompt label were
  already correctly set to `IGNORE` (see the note above), but the outermost
  node wrapping all of them wasn't. Keyboard input never goes through a
  Control's mouse filter at all, which is exactly why it kept working and
  hid the bug. Fixed in `main_menu.tscn` (`mouse_filter = 2`), not by
  chasing the input *type* - adding `InputEventScreenTouch` alongside
  `InputEventMouseButton` in `_unhandled_input`'s qualifying list is a
  reasonable belt-and-suspenders (touch-to-mouse emulation is a project
  setting, not a guarantee), but it doesn't fix anything on its own if the
  event never reaches that function to begin with.

### Waybook UI Rules

> **Faz 27'de oyuncu karanlık arayüzü onayladı** (`docs/ui/REDESIGN.md`):
> kontrollere malzeme dokusu (tahta şerit, taş levha, kumaş sancak, pas
> demir kenar - deri değil) ve üçüncü bir yüz (Grenze Gotisch, yalnızca
> vitrin) geliyor. Aşağıdaki "tek düz aile" ve "iki yüz" kuralları, ekranlar
> `scripts/ui/grim/`'e bağlandıkça bu tasarıma göre yeniden yazılacak;
> bağlanana kadar oyun hâlâ onları izliyor.

The management screens, overlays and HUD are dressed as one object: the
caravan's own account book (the "Waybook"). The world scenes (road, city,
combat, menu backdrop) stay procedural; the Waybook *frames* them.

- **One theme, installed into the engine's default theme.**
  `WaybookTheme` (`scripts/ui/waybook_theme.gd`) builds every chrome style
  - panel (`PanelContainer`/`Panel`), the irreversible-decision panel
  (`SealPanel`), buttons, tabs, fields, cells, scrollbars, pinned-slip
  tooltip (`TooltipPanel`, `SlipPanel`), ink rule (`HSeparator`) - and the
  `UiTheme` autoload (first in the autoload list, runs in `_init`)
  merges it into `ThemeDB.get_default_theme()`. Not a project `.tres`: a
  `Control` under a `CanvasLayer` does not inherit its parent's theme, and
  almost every overlay here is a scene-less `CanvasLayer` panel; the
  default theme is the last link of every lookup, so it reaches them all.
  Headless screenshot tools that build UI before the first frame call
  `WaybookTheme.install()` themselves (idempotent).
- **A screen does not build its own panel.** Nine overlays each built the
  same `StyleBoxFlat` with their own `PANEL_BACKGROUND`/`PANEL_BORDER`
  constants; they now inherit the theme, and `test_waybook_theme.gd` fails
  if a `const PANEL_BACKGROUND`/`PANEL_BORDER` comes back. A screen that
  needs a different tier opts in with `theme_type_variation`
  (`WaybookTheme.SEAL_PANEL` for irreversible decisions - the road's event
  card and `SuccessionPanel`; `HUD_BAR` for the road's translucent strips;
  `SLIP_PANEL` for the market's receipt, now the same flat box; `PAGE_LABEL`/`PAGE_HEADING` for ink text on the
  painted ledger pages).
- **Controls are one flat family; leather is gone.** Every panel, the
  sealed panel, button, tab, text/number field, cargo cell and scrollbar
  is a `StyleBoxFlat` sharing `FRAME_RADIUS` and a thin palette-coloured
  line - the only difference between tiers is the line's weight and the
  fill's tone (`SealPanel`: a 2 px `UI_ACCENT` line and a wider pad, so an
  irreversible choice still reads heavier than a plain panel). The leather
  chrome (G2 binding, G3 sealed binding, G4 tab, the auto-assigned
  `RowButton`, `IconTab`, the G7 ribbon scrollbar, R1's studded strap under
  the HUD) was rejected by the player outright - "deri efektini
  kullandığın her yer" - after G4 had already been pulled from the default
  button once. `test_waybook_theme.gd` fails if any control goes back to a
  texture or if a leather sheet is read or shipped again. Painted material
  survives only where it is a *picture* (desk scenes, the menu's lineage
  book, seals, icons) and the ink rule.
- **Colour is still `ArtPalette`.** Every decision the UI makes - a
  panel's ground (`UI_PANEL_FILL`), text (`UI_TEXT`/`UI_TEXT_ON_PAGE`),
  hover/pressed/locked fill, the ink marks (`UI_INK_MARK`, `UI_RULE`) - is
  a palette role. Ink marks are recoloured, not modulated: multiplying dark
  ink can never lighten it.
- **A number in a box sits in the middle of the box.** The market's
  quantity field was left-aligned against its arrows. `SpinBox.alignment`
  is a node property, not a theme one, so `UiTheme` centres every SpinBox
  as it enters the tree - the `SceneInk` pattern, no screen remembers.
- **A locked button is faded, never hidden - and never scratched.** The
  disabled button is the same box with a paler fill and line; the reason
  stays live text beside it (Event Engine Rules). For a while the ledger's
  scratch-out (G5) was composed over it; the player rejected it in
  playtest ("güzel gözükmüyor, silik olması yeterli").
- **The cursor is a brass arrowhead (user's reference, 2026-10-23).** `tools/cursor_art.py` draws the "Shaped" dart in
  two tones: `arrow.png` (dull) everywhere, `pointer.png` (bright) over anything clickable - `UiTheme` gives every
  `BaseButton` `CURSOR_POINTING_HAND`, and `ButtonFeedback` drops a locked button back to the dull arrow on hover. The
  arrow is also the project's `display/mouse_cursor/custom_image` (so it shows before the first frame) and the gamepad's
  virtual cursor (`GamepadCursorIcon`), so switching to a pad never changes the picture. Hotspot is the tip, (3, 2).
- **No pinned paper in the chrome (user's decision, 2026-10-20).** The pinned paper slip (G8) used to frame tooltips
  and the market receipt as a nine-slice; the user found the pinned notes ugly, and both are now the family's flat box
  with bone text. `g8_slip.png` is no longer shipped.
- **UI kit v2 (task 9.1, user's decision C1, 2026-10-21) is the one sanctioned texture family on controls.** Kenney
  CC0 shapes inked into the palette by `tools/ui_kit_ink.py` (`data/assets/ui/kit/`): `FRAMED_PANEL` (charcoal fill,
  rust frame - market side panels, the road's event card), `PRIMARY_BUTTON` (blood red, four states - the screen's
  one main action: market Buy, tavern Start a conversation, the event card's first available choice), the tooltip and
  the market receipt on the kit's parchment plate (`plate_panel`, ink text, `KIT_PLATE_TEXT`) - a worn plaque, not the
  pinned G8 slip - and the title strip under a panel heading (`title_strip`). Everything else stays the flat family.
- **Art arrives through one pipeline.** Raw generated sheets live in
  `art_source/waybook/` (a `.gdignore` keeps them out of import and
  export); `python3 tools/waybook_assets.py` keys the flat grey backdrop
  to alpha (only backdrop *connected* to the border or a named seed, so a
  grey inside the art survives), crops, scales to on-screen size and
  writes `data/assets/ui/waybook/`. The sheets came as JPGs with no alpha;
  never hand-edit an output PNG - change the pipeline and re-run it. Desk
  scenes that arrive framed in a cream paper border are cropped by
  `crop_paper_frame` (walk in while a row is mostly paper, then a margin
  for the torn edge) - `TextureRect`'s cover mode absorbs the small
  change of aspect. A second delivery (Faz 22) arrived already keyed to
  alpha and named by *output* filename rather than prompt id -
  `tools/waybook_ingest_v2.py` is the sibling tool for that shape: same
  `crop_to_alpha`/`unpaper`, no `key()` needed. Never guess which tool a
  new drop needs from its extension alone - check whether the file already
  carries real alpha (a corner pixel at alpha 0) before reaching for `key()`.
- **One book face for every language.** EB Garamond (OFL,
  `data/assets/fonts/`) with the engine's own font as its fallback, so
  nothing the old font could draw becomes a tofu box. Size 18, because the
  face has a smaller eye than the engine's sans. `test_localization.gd`
  now checks the game's real font chain, and separately that every
  non-CJK language's alphabet is in the book face *itself* - the ru/pl
  columns are still empty, so a CSV-only check would have tested nothing.
  CJK falls to Noto Serif SC/JP (OFL) - cut by
  `tools/cjk_font_subset.py` to GB2312 level 1 / kana + JIS level 1 plus
  every CJK character already in the CSVs (~1.4 + 1.5 MB instead of
  18 MB whole); re-run it when the zh_CN/ja columns are filled. Each face
  refuses the other's language (`set_language_support_override`), because
  the same Han character is drawn differently in Chinese and Japanese.
- **The book is the lineage, not a decoration of it.** The main menu
  names the caravan and its generation from the save (once a leather
  cover, M1/M2; now the lineage line on the camp screen); the run-over screen
  closes the book (M3). `WaybookPanel` (L to open, road and city) is the
  whole `CaravanLedger` as a two-page book, generations divided by a
  ribbon (L2), struck lines drawn with `StruckLine` - the ink stroke R9,
  animated only when a name is struck *now* (`SuccessionPanel`), static
  everywhere else. A struck name is a stroke through the name, never a
  grey label: the party screen's ledger uses the same line.
- **A face is the person's own figure, close up (task Y-G04).** `BustPortrait` frames the HD standing frame of the
  person's `WalkFigure` from its own joints (head top to shoulder = `BUST_SPAN` of the portrait, measured after the
  first draw, because a fixed ratio cut the head on tall people and under hats), inks it (`bust_ink.gdshader`:
  a pale wash, hatching only in real shadow) over the event cards' dusk wash (`bust_wash.gdshader`). It is on the
  character screen, the party header, every recruit candidate, inside the brass cameo (`PortraitCameo`: succession,
  caravan overview) and on the fallen page. The dead keep their face: `resolve_deaths` stores the person's look
  (`CharacterData.get_look_snapshot`: body, height, skin, hair colour, outfit) on the ledger line, and the fallen
  page draws it pale (`set_struck`); lines from before this have only the grave mark.
- **One icon table for people** (`WaybookIcons`): stat emblems (P3),
  duty emblems (P5), grievance marginalia (P4), class emblems (K6), trait
  tokens (P2), the hunger tally (P6). The character screen, party screen,
  caravan overview and the battlefield read this one table - the wagon
  rule again, for icons. Icons from it sit in a square box so a column
  beside them cannot drift with the emblem's aspect ratio. The tally
  stick was painted blank; the game cuts one ink notch per hungry night
  (`TallyStick`), so the picture *is* the count.
- **Goods have one door too** (`WaybookTheme.item_line`/`item_icon`):
  wagon, caravan load and the road's status list all go through it. An
  item without an icon gets a spacer, never a crash or a jagged row.
- **The road HUD is a dark band edged by a thin rule, never text on
  a texture.** The first pass put the HUD text *on* the R1/R2 straps -
  measured, the rivets ran through the letters and the vials vanished;
  the strap then sat beside the bars until the leather went. The bars stay
  `HUD_BAR` and `WaybookTheme.hud_rule()` (`HUD_RULE_HEIGHT`, a
  `GOLD_DIM` line) separates each bar from the world. The road's gauges
  left the top bar: the Durum tab holds four
  `SurvivalGauge` medallions and the warmth candle (user's decision 2026-10-22: no vials): an engraved picture per
  value band on an aged bronze coin - morale a torch, stress a bramble (tightest when high), danger ravens, stamina a
  horse - switching at the same thresholds as the words (`Wording.band`) with a short cross-fade; warmth shows the
  hour's weather on the same coin (`SurvivalGauge.weather_picture`: a moon on a clear night, snow and blizzard for rain
  and storm below 0 °C). Pictures and coin come from `tools/gauge_icons.py` (sources in `art_source/gauges/`). Only the
  name is written under a coin; the value, with its unit ("72/100", "%45", "−4 °C"), appears on a small plate when the
  pointer is over it (user's decision 2026-10-22: no numbers on the pictures). The hub still uses `PulseBar`; the clock has a `TimeDial`
  (R3, sun at noon, stars at midnight); attention and an open road signal
  show their R6/R7 icon, the signal flashing blood when it escalates and
  moss when it is caught.
- **Wear never shows at the edge of the world.** Stress (G11 bleed), cold (G11 frost) and finally hunger (G11
  scorch) each tinted the frame for a while; all three were removed on the player's decision (the last in task 2.5).
  Wear is told in words and on the gauges, and the screen's edge stays clean.
- **Words first, the number second (task Y-H03).** The user asked for prose, not "-10 morale". `Wording` turns a
  value into one of four band words (`WORD_*` in game.csv; stress and danger read high-is-bad) and the current causes
  into short sentences (hungry for N days, someone just buried, an overdue debt, someone about to break). The road
  gauges' tooltips lead with that sentence and put the number on the second line; morale and stress effect lines say
  direction and size in words with the number in parentheses. Guide: `docs/design_notes/dil_kilavuzu.md`.
- **HP gets a sifat next to the number, never in place of it.** Games like
  This War of Mine hide the raw number entirely ("Sick"/"Wounded" only) -
  this project keeps the number, because numeric transparency is a
  deliberate choice here (the same discipline Haggling Rules states against
  a hidden formula). `CharacterData.get_condition_label_key()` is a pure,
  four-band threshold (`UI_HP_BAND_HEALTHY`/`_WOUNDED`/`_BADLY_WOUNDED`/
  `_CRITICAL`, the last one reusing "Ölümün Kıyısı" rather than inventing a
  second name for the same idea) that `character.gd` and `party.gd` print
  as a small colored `Label` right beside the "Can %d/%d" text - a second
  reading of the same fact, not a replacement for it.
- **Who eats is one function** (`GameSession.get_meal_fed_party()`/
  `meal_feeds_crew()`): the supper panel's bowls (R8 full/empty, per
  person plus one for the nameless crew) and the distribution itself
  read it, so the picture shown before confirming is the meal served.
- **The battlefield is framed, not boxed.** Slots use K1 at half scale as
  a nine-slice (at full scale its 30 px border ate the 136 px slot); a
  unit on Death's Door swaps to the cracked K2. The active/target colour
  is a separate border drawn over the frame, because tinting dark wood
  did not read. Statuses are K4 icons with remaining rounds (stun
  recovery and timed buffs/debuffs included - `CombatUnit` exposes read-
  only summaries so the UI never touches its lists); pips are K5 brass
  studs; area/push/pull carry K7 glyphs beside their text note.
- **Scenes arrive out of ink** (`SceneInk` autoload): every scene change
  fades in from `ArtPalette.INK`, detected by the layer itself watching
  `current_scene` - no screen has to remember to call it. A city entrance
  holds the ink a moment longer (`hold_next`), the one "we arrived" beat.
  Since SENSORY-002 the change itself goes through the same door - see
  Motion Rules.
- **A recent death puts the caravan in mourning.** The city brief's memory
  carries the crepe (C1) when its line is a death within
  `CityBriefModel.MOURNING_DAYS` - read from the ledger's own day, not a
  new saved field, so a reload neither lengthens nor shortens it.
- **Passing over the senior cracks the seal before you confirm.**
  `SuccessionPanel` shows G9b instead of G9 the moment a non-senior heir
  is selected; confirming stamps the seal (the choice is emitted at once;
  the stamp is only the moment).
- **A stretched button is still the same button.** For a while a `Button`
  that filled its row wore `RowButton` (G2 scaled as a nine-slice), because
  the G4 tab stretched to 1000+ px turned its grain into horizontal bars.
  With textures gone there is no grain to stretch: a full-width button is
  the default flat box, and `UiTheme` no longer assigns a variation.
  Inputs (`LineEdit`, inside every `SpinBox`) are a darker ink well
  (`field_frame()`), cargo cells (`CELL_PANEL`) the same box a shade
  lighter - the engine's black box and the market's green `ColorRect` cells
  (`PlaceholderHelper`, deleted) were the last unskinned widgets.
- **Bone text always carries a dark halo.** `Label` has a `UI_TEXT_HALO`
  shadow, `Button`/`LineEdit` an outline (`TEXT_OUTLINE_SIZE`), because the
  scene backgrounds have pale patches. Paper
  variations (`PageLabel`, `PageHeading`, tooltips) switch it off - ink on
  paper needs none.
- **A map is written on, not stuck on.** City markers on the B6 parchment
  are `MapLabel` buttons - no box, ink text with a parchment-coloured halo,
  blood for "you are here", faded ink for a closed road (still shown, still
  with its reason) - over a K5 stud. The tab buttons (and the disabled
  tab) sat on the map as grey patches.
- **Paper an asset was painted on is not the asset.** Three icons (K6
  clerk, P3 strength, P4 witnessed death) came on an off-white card and the
  K5 studs on a bone plate; keying cannot see either (it removes the grey
  backdrop only). The pipeline's `unpaper` drops pale, unsaturated paper
  connected to the outside, `disc` cuts the studs round, and `loose_page`
  ships B6 as a torn page with a transparent surround instead of the
  desk-ink fill full-bleed scenes get. A square corner on an icon is a
  pipeline bug, not a styling choice.
- **A desk scene's props are the picture, not the margin.** Full-width rows
  ran across the candle, the scales and the tent canvas, and pale canvas
  under bone text lost its contrast. `WaybookTheme.fit_desk_workspace()`
  holds the text to a central column (at most `WORKSPACE_WIDTH_RATIO`, 65%)
  on a dark band, full width below `WORKSPACE_FULL_WIDTH_BELOW`; every desk
  screen calls it first in `_ready()`. The market is the one exception,
  on purpose: its stall row and cargo column side by side do not fit 65%,
  and squeezing them opened a horizontal scrollbar. The column never goes
  narrower than its scrolled content (`workspace_side_margin(w,
  content_min)`), and the band stays at every width - on a narrow screen
  pale canvas behind bone text is exactly where contrast was lost. The city
  map was a desk screen too for a while (B10, `b10_city.jpg`; the picture was deleted in task 3.4 when the city moved to
  `CityFront`).
- **The generator stops at ~1376 px; the pipeline can upscale.**
  `background(src, name, width)` resizes with Lanczos plus a light unsharp
  mask, which keeps ink lines crisper than the GPU's bilinear stretch but
  adds no detail. Only B10 uses it: the other eight backgrounds are no
  longer reproduced byte-for-byte by the pipeline (the shipped B7 is
  1376x768, the pipeline now crops it to 1311x705), so regenerating them
  would change art nobody asked to change. Reconcile that drift before
  re-running the whole pipeline.
- **Nothing painted ships unread.** The Web build downloads every
  texture, so a sheet the game never draws (G1 page tile, G10 grain, the
  G2/G3/G4/G7/R1 leather chrome, the G11 bleed and frost edges, R2, R5) is
  not written by the pipeline at all; the reason stays as a comment in
  `tools/waybook_assets.py`.

### Motion Rules

The world was drawn well and moved like a slideshow: a scene change was a
cut, a figure that stopped walking snapped its legs together in one frame,
a hit in combat was a colour that sat frozen until the next refresh and
then vanished, a button did nothing under the cursor. SENSORY-001..013
gave the game its motion, and every piece of it follows the same few rules.

- **Motion has one clock per system and it lives in a pure function.**
  `CombatFx` (recoil, flash, shake, fall, numbers), `WalkFigure.ease_motion`,
  `RoadCaravan.wind_lean_at`/`canopy_sway_at`, `JourneyClock.phase_for_hour`/
  `darkness_for_hour`, `ButtonFeedback.hover_scale` and
  `SceneInk.transition_kind` are all static and scene-free, so
  `test_motion.gd`/`test_combat_fx.gd`/`test_ui_feel.gd` read the same
  numbers the screen draws. A curve written inside a `_draw()` is a curve
  no test can see.
- **Every motion starts at rest and ends at rest, exactly.** Recoil is
  `sin(πu)·(1−0.35u)` (zero at both ends), a flash fades to
  `FX_FLASH_NEUTRAL` (u²), shake is exactly zero after 250 ms, a stopping
  figure's stride decays to zero over `REST_EASE_SECONDS`. The tests assert
  the endpoints, because a motion that ends *near* rest leaves a figure a
  pixel off forever.
- **Rebuilt nodes cannot own a tween; the owner drives them per frame.**
  `CombatPanel` rebuilds its slots on every `_refresh()`, so combat state
  is timestamped in the panel (`_flash_states`, `_lunge_states`,
  `_fall_states`, `_ring_states`, `_shake`) and `_animate(now)` stamps the
  current value onto the live slots each frame, turning its own
  processing off when nothing is moving. The first version applied the
  state only at `bind()`: a flash sat frozen until the next click and
  then vanished in one frame.
- **Numbers come from what changed, not from what was said.** Damage and
  heal numbers are the difference in `current_hp` between refreshes, so
  armour, Death's Door, bleed and the heal cap are all already in them -
  reading the engine's hit line would have shown damage armour absorbed.
- **The engine says *what kind* of moment it was; the screen decides how
  it looks.** Status application, bleed/blight ticks and stun skips are
  `unit_barked` kinds (`BARK_STATUS_*`, `BARK_*_TICK`, `BARK_STUN_SKIP`)
  with empty text - a moment, not a speech bubble. Never branch on the
  translated text (Localization Rules).
- **The last blow is seen before the result.** A kill or a downing starts
  a 300 ms fall around the figure's feet, and `CombatPanel.falls_pending()`
  keeps Continue disabled until every fall lands.
- **A crit is felt, a kill is seen (task Y-H05).** A crit zooms the stage toward its target for `CRIT_ZOOM_MSEC`
  (`CombatFx.crit_zoom`, at rest at both ends; skipped under Reduce Motion) and writes a narrator line to the log,
  chosen from round and rank (no dice). A killing blow holds `KILL_PAUSE_MSEC` before the body falls
  (`CombatFx.fall_start`). Hit, crit and kill each have a sound id (`AudioManager.SFX_HIT/CRIT/KILL`): five Kenney Impact Sounds
  variants each (CC0), one picked at random with the pitch jittered by `SFX_PITCH_JITTER` (a path with `%d` is a
  variant set). There is no ink splash: the engraved
  effects (Y-G06) were set aside by the user (2026-10-20, "eksik olsun şimdilik").
- **Only figures shake; text never does.** Shake (3/6/8 px for hit/crit/
  kill) moves figure drawings, never labels, bars or buttons - what is
  read must not tremble.
- **Scene changes have one door: `SceneInk.go(path)`.** It snapshots the
  outgoing frame, changes the scene at once (the new scene's `_ready` is
  never delayed), then animates the snapshot away: `Nav.open` slides the
  page left, `Nav.back` slides it right, a root change sinks into ink.
  The kind comes from `Nav.last_move`, so none of the call sites chooses.
  Two traps were measured: `change_scene_to_file` passes through a frame
  where `current_scene` is null (treating that frame as an arrival killed
  the slide), and a back move to a root empties the stack (so depth
  comparison called it a root change - hence `last_move`).
- **Accessibility and play settings live beside Reduce Motion (task Y-H07).** Text size has four steps
  (`UserSettings.TEXT_SCALES`) that scale the theme's base size (`WaybookTheme.apply_text_scale`; sizes set by hand
  stay fixed). With patterned stripes on, the combat choice's blood stripe is drawn in segments (`PatternStripe`) so it
  reads without colour. With auto-pause on, a road signal or an encounter marker holds time until a key or click
  (`_auto_paused`, part of `_can_time_flow`). All three are in `settings.cfg`, not the save.
- **Reduce Motion is honoured everywhere motion is decoration.**
  `UserSettings.reduce_motion` (saved, Settings screen) turns page slides
  into the ink fade, stops the combat shake and freezes button scale.
  Flashes, numbers and falls stay: they carry information.
- **Secondary motion belongs to the thing that is moving.** Canopy sway
  and the ox's nod are multiplied by the same motion weight as the walk,
  so a stopped caravan is completely still. Wind leans people only, in
  rain and storm, with a per-figure gust phase - a wagon that leans is a
  wagon that tips over.
- **The city keeps the road's hour.** `GameSession.last_clock_hour`
  (saved) is written on arrival; `CityView` and `HubScenery` read the sky
  from `TravelBand.sky_for_hour` - the road's own table - plus a night wash
  from `JourneyClock.darkness_for_hour`. The darkness is a curve of the
  hour, not of the palette: the night phase blends toward dawn for nine
  hours, so by 02:00 the palette is already bright (measured).
- **The world map keeps the hour too (tasks 8.10, 8.11, Y-G09).** `WorldMapView` multiplies the tiles by
  `map_tint_for_hour` (the same darkness curve; warm at dusk, blue-grey at night) and its test holds the map's ink at
  4.5:1 against its paper at every hour. Settlement lights (`settlements.json` `lights`, generated per kind by
  `build_settlements.py`, none on ruins) fade in at evening at a screen-constant size. Finished routes and camp sites
  stay as a thin ink trail (`GameSession.map_trail`/`journey_camps`, saved, capped).
- **The rider carries a lantern at night (task Y-G13).** As the map darkens (`light_strength_for_hour`), a warm
  pool (`RIDER_LANTERN_GLOW` rider heights, two `radial_glow` layers) and a small flickering core burn on the side
  the rider is heading (`rider_lantern_offset`), the map's echo of the road lantern.
- **A button under the cursor answers.** `ButtonFeedback` attaches itself
  to every button through `UiTheme`'s `node_added` (the `SceneInk`
  pattern): hover grows `1+min(3%, 6px/width)` - 3% of a 1000 px row is a
  jump -, press dips to 0.96, release overshoots to 1.02 and settles. It
  only touches `scale` (containers rewrite position, never scale), the
  tweens belong to the button, a locked button does not move, and it has
  no `class_name`: the autoload loads it, and a script that names itself
  could not compile there (measured).
- **A condition lives on the body, not around it.** The first pass drew
  burn, poison and frost as glows centred on the figure; the player
  rejected them with reference shots of a man actually on fire, ice
  crusting a body, a sick green skin. `condition.gdshader` now colours only
  the figure's own pixels (body and garments): charred patches with
  breathing embers, an ice crust with cracks, a sickly skin with lesions,
  blood running down from the wound. `StatusFx` adds only what leaves the
  body - flames, embers, green fog, ice shards, breath, drips - from points
  sampled along the bones (`body_points`), in two layers (normal and
  additive). The pattern and the wound are in canvas space: a frame
  texture's own space changes scale and mirror per frame, and the first
  wound landed off the body (measured).
- **A reaction clip is only chosen when every worn garment has it.**
  `WalkFigure.shared_clips()`: a clip rendered for the body before the
  clothes would show the figure naked for that moment; until then it
  falls back (`ACTION_FALLBACK`: reactions to `hit`, dodge to `defend`,
  cast to `attack_swing`).
- **A choice says what kind of risk it is before it is read.** Choices
  that can open combat carry a blood stripe (`UI_CHOICE_COMBAT`), checked
  choices the stat emblem of their roller, and a locked choice whose one
  numeric requirement is just short (`EventChoice.is_near_miss`, within a
  quarter or one unit) shows its reason in `UI_ACCENT` instead of the
  locked grey.

- **scripts/world/**: Explorable 2D spaces the player physically moves through
  - `world_hub.gd`: side-scrolling road. The caravan leader walks left/right;
    the party then the wagons lerp-follow behind, one body per party member and
    one wagon per `owned_wagon_count`. The city gate and **every** wagon are
    interaction spots: walk within `INTERACT_RANGE`, then click one or press E
    (only the first wagon carried a spot until Faz 15's wagon-based inventory -
    when cargo was one shared pool, which specific wagon you clicked didn't
    matter). Walking up to a wagon opens `WagonPanel` (scene-less, see Kervan
    Envanteri Rules) showing *that* wagon's own inventory and its Rust-simple
    craft menu - never a scene change, and nothing to do with the city's
    Kervan Avlusu. No physics bodies — plain position arithmetic on a
    single ground line, so it stays cheap on Web export.
  - `city_map.gd`: the city, and the game's decision hub. A new game starts
    here, not on the road. City interaction is deliberately **not** card-based
    (see Event Engine Rules): each location button opens its own screen.
    Beside the map sits `CityBriefPanel` (see City Hub Rules).
  - `nav.gd`: every scene path lives here, plus the **navigation stack** —
    `open(from, to)` pushes the sender, `back()` pops one, `go_root(scene)`
    clears it. `recruit_venue` and `character_target_index` are the only
    remaining statics, and neither is navigation: they are data a screen
    carries to the next one (which candidate pool, which party member).
  - There is no SceneManager autoload: navigation is `change_scene_to_file()`
    plus this stack.

### World Navigation Rules

Getting stuck in a menu was this project's most-repeated complaint, and it
was **architectural, not a run of separate bugs**. `Nav` used to hold a
single `return_scene` string, and one string can only remember *one* level
of history: the moment navigation went two deep (city → guild → recruit)
somebody had to overwrite that slot, and whoever overwrote it destroyed
another screen's only way out. Three ad-hoc patches had already been made
to the same hole — a second variable for the recruit screen, a hardcoded
target in `character.gd`, a `return` field carried in the road's spot table
— and every new screen would have wanted a fourth.

- **Navigation is a stack.** `Nav.open(from, to)` pushes `from`;
  `Nav.back()` pops. Back **always shrinks the stack**, so a loop cannot be
  built, and depth is bounded only by `MAX_DEPTH`, so no screen can overwrite
  another's exit. Never add a per-screen "where do I return to" variable
  again — that is the bug this replaced.
- Never hardcode a `res://scenes/...` path in a screen script; use `Nav`.
- **Never call `change_scene_to_file()` either; call `SceneInk.go(Nav.x(...))`.**
  `SceneInk` is the only script allowed to change scenes, and
  `test_navigation.gd` fails on any other caller (see Motion Rules for
  why the transition needs the door).
- A screen's back button goes to `Nav.back()` and is labelled
  `Nav.back_label()`, so the player reads where it leads before pressing it.
- **Roots are gone to, not returned to.** `Nav.ROOTS` (road, city, main menu)
  carry their own exits instead of a back button, and reaching one clears the
  stack — `go_root()` explicitly, and `open()` too when the destination is a
  root, so a screen that opens the city gate cannot leave a stale road on the
  stack. An empty stack still lands somewhere (`FALLBACK_ROOT`): a back button
  that goes nowhere is just another word for stuck.
- A screen whose content can grow past the viewport (market rows, the contract
  board, the party list) puts that content in a `ScrollContainer` and keeps the
  back button **outside** it. Otherwise the back button is pushed off-screen and
  the player is stranded - this actually happened on the market screen, and
  again on four screens that built their exit button in code straight into
  `_content` (character creation's "Başla" sat below six stat rows, on the
  first screen of a new game).
- **The road is left through the road's own actions.** On a live journey
  `road_journey.gd`'s exit goes to the main menu, never through the stack:
  it used to drop the player on the city map with `is_journey_active()`
  still true, and since nothing but the planner ever navigates to
  `Nav.JOURNEY`, the road could not be re-entered. Arriving, turning back
  and diverting are the exits (see En-Route Plan Rules).
- `tests/test_navigation.gd` locks all of this, and **derives the screen
  graph from the source** rather than from a hand-written table — a table
  drifts from the code and then certifies the wrong game. It scans every
  `Nav.open(Nav.A, Nav.B)` call; for the two screens that carry their
  destination in a table (`city_map`, `world_hub`) and therefore pass it as a
  variable, it treats every scene constant the script mentions as a
  destination, which is exactly how the city's five venues re-entered the
  graph after the migration. On that graph it asserts: every edge returns to
  its opener, every path from every root unwinds to a root with the stack
  shrinking at each step, back always leads somewhere, no screen opens
  itself, roots clear the stack, the stack cannot grow without bound, and no
  screen is orphaned. Control scenes cannot be instantiated headless, so the
  rest is checked against the files: every `Nav` scene constant resolves to a
  scene whose script has at least one exit, no back label renders blank, no
  exit button is added to `_content`, and — via `PackedScene.get_state()`,
  which reads a scene without building it — every `$A/B` node path in a
  screen script actually exists in its scene. That last one is the only cheap
  guard against a typo Godot reports only when the player opens the screen.
- **A full-screen overlay can trap the player too, and the scroll rule
  applies to it verbatim.** `OnboardingPanel` is the first thing a new game
  shows, and its four wrapped topics grew past the viewport with the
  dismiss button below the fold — the opening screen of the game had no
  exit. Three causes, all the same omission (nobody asked what happens when
  the content outgrows the screen): the content was in no
  `ScrollContainer`; the panel was centred with `PRESET_CENTER` plus a
  `position -= PANEL_SIZE * 0.5` nudge, i.e. against its *guessed* height
  rather than its real one, so growing pushed it off the bottom; and a
  `CanvasLayer` is not a `Control`, so an anchor preset on its direct child
  has no rect to anchor against and the backdrop never covered the screen.
  The layer's root is now a full-rect `Control`, a `CenterContainer` does
  the centring at whatever the real height is, the topics sit in a
  `ScrollContainer` with the dismiss button outside it, and the panel
  carries an explicit opaque `StyleBoxFlat` (the default theme let the city
  map read straight through the text). Dismissal is no longer one button
  either — the backdrop and Esc both close it, because a player's first
  reflex is to click outside.
- *(The panel and the test below were removed with the tutorial on 2026-10-21; the rule itself stands for every
  overlay: content that can outgrow the screen sits in a scroll, the exit outside it.)*
- **`test_navigation.gd` guarded that overlay by building it**, which is
  possible precisely because it is scene-less (`.new()` + an explicit
  `_ready()`, since suites run before the tree is live). What it asserts is
  structural — content in a scroll, dismiss button not inside it, more than
  one way out — and that is deliberate: **a wrapped `Label`'s minimum
  height is one line without a layout pass**, so a height assertion cannot
  see wrap-driven overflow at all. Verified by mutation: against the old
  panel three assertions fail and the height one does not.
- **A suite that cannot load must fail the run.** A parse error in a test
  file made `load(path).new()` abort `run_tests.gd` mid-loop, and since
  `_process()` still returned true the runner exited **0** — the navigation
  suite silently stopped running and the build stayed green. The runner now
  checks `can_instantiate()` and counts a broken suite as a failure. Same
  family as the CI log grep: Godot reports these and exits 0 anyway.

### Save & Menu Rules

A playtest found the save system was really just one autosave with no
front door, and that "return to menu" meant a silent, unconfirmed jump
straight to the main menu from two separate buttons (`world_hub.gd`'s
"Menü", `road_journey.gd`'s live-journey exit) - a single caravan lost to
Ruin Rules' own attrition had nowhere to go back to, and quitting mid-city
never asked first.

- **Slot 0 is the autosave; the rest are the player's.** `SaveManager`
  went from one file (`user://save.json`) to numbered slots
  (`user://saves/slot_N.json`, `SLOT_COUNT`). Every existing call site
  (`SaveManager.save_session(session)`, `.load_session()`, `.has_save()`,
  `.delete_save()`) defaults to `AUTOSAVE_SLOT` and keeps behaving exactly
  as before - city arrival still writes it silently, "Devam Et" still
  reads it directly, "New Game" still only clears it. The manual slots are
  strictly additive.
- **The journey autosaves; the player still cannot save by hand on the
  road.** The rule used to be "no mid-journey save", and its reason was
  architectural, not a design goal: journey state was scattered across
  `road_journey.gd`'s fields, so a save could not hold it - and on the Web
  target closing a tab lost the whole leg. `JourneyController` now owns that
  state and serializes it; `GameSession.to_save_dict()` writes a `journey`
  block (route, caravan via `CaravanState.to_dict()`, controller snapshot)
  only while a journey is active. `road_journey.gd`'s `_autosave_journey()`
  writes slot 0 at quiet moments only - after the day's decision resolves,
  never with a card, fight, haggle or panel open - and "Devam Et"/load go
  through `Nav.resume_scene()`, which lands on the road when the save has
  a journey. Manual saving stays disabled on the road (`can_save`,
  `UI_SAVES_CANT_SAVE_JOURNEY`, disabled with its reason): a hand save
  right before a card is a retry button.
- **A save never re-rolls or clones the world.** Two holes found by reading
  `load_from_dict()` against `_restock_current_location()`: market stock
  refilled on load (buy out, save, reload, buy again) and hired recruits
  reappeared (the board is re-rolled from its seed, so the same person could
  be hired twice). `market_stock` and `hired_recruit_indices` (generation
  indices of this arrival's hires) are saved now.
  `test_memory.gd`'s `_test_every_persistent_field_is_saved` walks
  `GameSession`'s script variables and fails on any that is neither saved
  nor on an explicit, commented transient list - a forgotten field is a
  test failure now, not a playtest discovery.
- **Writes are atomic.** `SaveManager.save_session()` writes `.tmp`, keeps
  the previous file as `.bak`, then renames; `_read_slot()` falls back to
  the backup when the main file is truncated or unparsable. A lineage's only
  autosave lost to an interrupted write is the worst bug a game about
  irreversible loss can have.
- **One list, two doors.** `SaveSlotsPanel` (scene-less, `DebtPanel`'s
  pattern) is the only save/load UI in the game; `saves.tscn` shows it
  alone for the main menu (load-only, no live session to save from) and
  `InGameMenu` embeds the same instance-type for the in-game case
  (`can_save = true` there). Two separate lists would have meant two
  numbering schemes drifting apart, the same reasoning as
  `CaravanPlan.daily_consumption()`.
- **`InGameMenu` (`OnboardingPanel`'s CanvasLayer/backdrop pattern) is what
  the two "return to menu" actions open now, instead of jumping.** Ana
  Menüye Dön is still there, just behind a confirmation instead of being
  the only thing the button could do. Esc reaches it from the road
  (`_input`, only when no card/panel is already up), the world hub and the
  city map (`_unhandled_input`) - the three screens the player is actually
  "in the game" on. Sub-screens reached through the `Nav` stack keep their
  own back buttons; they were never the ones jumping to the main menu
  without asking.
- **Settings is deliberately not in `InGameMenu`.** `Nav.open()` pushes the
  caller's scene onto the stack, but the road (`Nav.JOURNEY`) is never
  entered through that stack (see Road Movement Rules) - pushing it from a
  live journey to reach Settings would mean Settings' back button
  reloading `road_journey.tscn` from scratch, a path that has never been
  exercised and that the "no mid-journey save" rule above already warns is
  risky. `InGameMenu` never changes the underlying scene except on Kayıtlar
  (load, an explicit scene replacement to `Nav.CITY_MAP`) or Ana Menüye Dön
  - both of which discard the current scene entirely instead of asking to
  return to it.

- **Fate Mode and open difficulty (task Y-D01).** Chosen on the new-game screen and saved: Fate Mode keeps the
  autosave only - no manual save anywhere, city included (`GameSession.can_save_manually`). Three open dials, no
  hidden difficulty: deathblow resistance (`CombatUnit.deathblow_offset`, set before each fight), hunger damage
  (`get_hunger_damage`) and event harshness (`RoadDirector.heavy_scale`). Standard is exactly today's balance; the
  user asked for no extra penalty on the leader's death.

### Localization Rules

The game targets **11 languages** (tr, en, de, fr, es, it, pt_BR, ru, pl,
zh_CN, ja). Turkish is the source language; English is the fallback.

- **`UserSettings.SUPPORTED` (`scripts/autoload/user_settings.gd`) is the
  single source of truth for the language list.** It also persists the
  player's choice to `user://settings.cfg` (separate from the save file, so
  "New Game" never resets it) and picks the system language on first run.
  No screen may hardcode a locale list - `settings.gd` reads it.
- **Adding a language is three coordinated edits**: a row in
  `UserSettings.SUPPORTED`, a column in *each* `data/locale/*.csv`, and the
  three `.translation` paths in `project.godot`'s `locale/translations`.
  `tests/test_localization.gd` fails loudly if these drift apart - it also
  checks that `tr`/`en` are filled on every row and that no key is defined
  in two files.
- **An empty cell falls back to English, it does not render blank** (verified
  against Godot 4.2.2 with `locale/fallback="en"`). So a language can ship
  partially translated, and English must stay complete.
- Translation CSVs are split by domain so translators can work in parallel
  and prioritize: `ui.csv` (screens, buttons), `events.csv` (road event
  prose), `game.csv` (catalog content - duties, enemies, cities, items,
  traits, equipment, skills, classes, cultures).
- **Catalog resources store keys, not prose.** `Duty`, `Trait`, `Equipment`,
  `CombatSkill`, `Culture`, `CharacterClass`, `EnemyTemplate`, `Item` and
  `Location` each keep a `*_key` export and expose the visible text as a
  **computed property** (`var display_name: String: get: return
  tr(display_name_key)`). This is why the ~67 places that read
  `.display_name`/`.description` needed no change at all when the game
  became translatable - never reintroduce a plain stored `display_name`.
- **`tr()` is an `Object` instance method and cannot be called from a
  `static func`.** Static catalogs must use
  `TranslationServer.translate(key)` instead (see
  `EnemyCatalog.get_kind_label` and `Nav.label_for`).
- **`tr()` cannot appear in a `const` either** - a constant must be a
  constant expression. A const table of screen text therefore holds *keys*
  and resolves them when the widget is built (see
  `OnboardingPanel.TOPIC_KEYS`). Write the keys out in full rather than
  assembling them at runtime (`tr("%s_TITLE" % topic)`), or neither the
  undefined-key scan nor a translator searching the codebase can find them.
- **Every layer that can show text is keyed, and a test keeps it that way.**
  `test_localization.gd` scans *all* of `scripts/` for string literals
  containing Turkish-specific letters. It started at `scripts/ui` +
  `scripts/world` only, and that narrow scope hid a real gap: the combat log
  (`combat_encounter.gd`), the event-effect lines
  (`event_effect_applier.gd`), culture perk descriptions and equipment slot
  names are all player-facing and were still nailed to Turkish.
  Two exemption lists, both deliberate: the F1 developer scenes
  (`haggling.gd`, `combat_test.gd`, `test_selector.gd`) never reach a player,
  and `culture_catalog.gd`/`recruit_catalog.gd`/`user_settings.gd` hold
  proper nouns - name pools, and **language names, which must stay in their
  own language** or a player cannot find the one they read.
- **A `.tscn` is a text layer too, and the scan could not see it.** The
  prose scan covered `scripts/` only, so every static label baked into a
  scene file — the market's headings, the church's explanation, "Partiyi
  Görüntüle", the road's control hint — stayed Turkish in ten of the eleven
  languages. Twenty-two of them. Scene text is now always a **key**, the
  screen assigns the visible string from `tr()` in `_ready()`, and two
  checks keep it that way: no scene may contain a text literal with
  Turkish-specific letters, and every key-shaped scene literal must be
  defined in a CSV (the sole exception is `WAYBORNE`, the game's own name).
  Putting the key in the scene rather than blanking it is deliberate: if a
  screen ever forgets to assign, the player sees `UI_MARKET_SHOP` — loud —
  instead of silent Turkish.
- **A translation must carry the same format arguments, in the same order,
  as the source.** GDScript's `%` operator has no positional form
  (`%2$s`), so a reordered or dropped `%d` crashes the game the moment that
  line is printed - and only in that language, where nobody testing in
  Turkish would ever see it. `test_localization.gd` compares the
  placeholder signature of every cell against its Turkish source, and it
  caught exactly that: an English combat line that reordered `%s`/`%d`.
  A format argument is only counted when it ends in a real conversion
  character (`d s f x X o c`) - otherwise plain prose like "%30 az" or
  "10% discount" reads as a placeholder and the check fires on nothing.
- **`tests/run_tests.gd` pins the locale to Turkish.** Catalog text now
  resolves through the translation server, so without pinning, assertions on
  display names would pass or fail depending on the machine's language.
- **A correct, translated string is not the same claim as a *renderable*
  one.** Godot's default font doesn't carry Geometric Shapes, Arrows, Box
  Drawing or Dingbats, so `●○↑↓✓` and friends rendered as empty boxes
  everywhere the UI used them as icons - twelve player-facing spots, found
  by a playtest photographing only one of them. `_test_every_glyph_is_
  renderable` checks every CSV cell and every screen string literal
  against `ThemeDB.fallback_font.has_char()`. There is no exemption any
  more: `user_settings.gd`'s language names ("简体中文", "日本語") were
  exempt while no font carried CJK, and became renderable with the book
  face's CJK fallbacks. `settings.gd` still appends the locale code to a
  name it cannot draw (checking the whole fallback chain), so a future
  language without a face stays findable by its code.
