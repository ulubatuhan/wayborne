# CLAUDE.md arşivi

Görev Y-F11 (2026-10-19): CLAUDE.md'den, artık var olmayan sınıfların tarihçesi metin değişmeden buraya taşındı. Dersleri
CLAUDE.md'de kısa birer maddeyle duruyor. Hiçbir geçerli kural silinmedi.

## Art Rules: CityView (sınıf görev 2.3'te silindi, şehir artık CityFront)

> **Not (görev 2.3):** `CityView` sınıfı silindi; şehir `CityFront`'a geçti. Aşağıdaki `CityView` maddeleri o sınıfın
> tarihidir, ama çıkardıkları ders (anchor-preset tuzağı, bayat boyut, kenar sızıntısı) `CityFront` için de geçerlidir.

- **The anchor-preset trap, four times.** `PRESET_FULL_RECT` hands the size
  down only when the parent *resizes*; a child added after the parent was
  already sized never gets that notification and stays (0,0). It has now hit
  `OnboardingPanel` (a `CanvasLayer` is not a `Control`), `RoadCaravan`
  (invisible figures, half-pixel wagons, silent triangulation failures),
  `TravelForeground` (an empty strip below the road) and `CityView` (its
  parent `MapPanel` is a plain `Panel`, not a `Container` - `city_map.gd`
  builds `CityView`, sets its anchors, *then* adds it as a child, by which
  point `MapPanel` has already reached its final size and never resizes
  again). The fourth case had its own symptom: a stale, wrongly-sized
  `CityView` left `MapPanel`'s own default theme box showing behind the
  drawn town as a plain grey frame - a playtest photographed exactly that.
  Components adopt `get_parent_control().size` explicitly instead of
  trusting the anchor, and `MapPanel` also carries an explicit
  `StyleBoxEmpty` now, so even a transient sizing miss shows nothing
  instead of the default theme's grey panel.
- **A one-shot `_adopt_parent_size()` call is still a snapshot - it can go
  stale a second time.** Fixed once, `CityView` still left two thin
  vertical bars flanking the picture, on the *screen itself*, not the
  theme's grey panel this time but the raw viewport `clear_color`
  (Godot's own default, `Color(0.3,0.3,0.3)` → `(77,77,77)` - confirmed
  by sampling the reported screenshot's own pixels at that exact value).
  `_build_spots()` grabs `MapPanel`'s size once, synchronously, but
  `_build_brief()` - which fills `BriefScroll` with the chapter/needs
  text - runs *after* it in the same `_ready()`; that content can change
  how much width `MainRow`'s `HBoxContainer` leaves `MapPanel`, and on
  the web export the browser's own adaptive canvas resize
  (`html/canvas_resize_policy=2`) can resize the whole window *after* the
  scene has already settled once, same trigger, same symptom. A single
  `_adopt_parent_size()` call at `_ready()`/`setup()` catches neither.
  `CityView` now also subscribes to `get_parent_control().resized`, so it
  re-syncs to `MapPanel`'s size every time it changes for the rest of the
  screen's life, not just once - closing the class of bug at its root
  (a stale cached size) instead of chasing each new trigger for it.
- **The town picture is a picture now, not a rectangle pasted onto the
  screen.** Asked for explicitly: a frame around the map inside the city
  menu. `CityView` no longer fills `MapPanel` edge to edge - `FRAME_INSET`
  (8px) pulls it in on all four sides, and `MapPanel`'s own stylebox
  (`StyleBoxFlat`, transparent fill, a `GOLD_DIM` border, rounded corners,
  a soft drop shadow) fills that gap. The border is drawn by the *panel*,
  not a second overlay node added after `CityView`, so it needed no new
  anchor-trap bookkeeping of its own - only `CityView`'s own inset had to
  track `_adopt_parent_size()`'s existing resize subscription, which it
  already does for free. `bg_color` stays fully transparent, keeping the
  same "a transient sizing miss shows nothing, not a filled box" guarantee
  the `StyleBoxEmpty` it replaced was there for.
- **Fixing the strip beside the picture is not the same claim as fixing
  every gray strip on the screen.** Two rounds of `CityView` sizing fixes
  (the two bullets above) both closed real bugs, and both times the report
  came back "still there, same spot" - because neither one had ever
  touched the screen's own outer frame. `city_map.tscn`'s root
  `MarginContainer` reserves 24px on every side for the whole screen, and
  nothing painted that margin: it showed Godot's raw, unthemed viewport
  `clear_color` (`Color(0.3,0.3,0.3)`, confirmed the same way as
  before - sampling the reporter's own screenshot found `(77,77,77)` along
  the entire left edge, not just beside `MapPanel`). A `BackgroundFill`
  `ColorRect` (`ArtPalette.INK`, `mouse_filter = 2`) as the scene's first
  child, behind `MarginContainer`, closes it. The lesson isn't the fix,
  it's the miss: two fixes had each been verified against a screenshot
  that still carried the very bug being reported, because verification
  glanced at the picture's own edge and never sampled the screen's outer
  edge - "fixed" was said twice before it was checked where the report
  actually pointed. A second, smaller issue turned up in the same pass:
  `city_map.gd` built `CityView` with `PRESET_FULL_RECT` anchors *and*
  `_adopt_parent_size()` writes `size`/`position` directly - the exact
  combination this file's own "anchor-preset trap" already warns against,
  confirmed by Godot's own runtime warning ("If you want to set size,
  change the anchors..."). It never produced a visible symptom here (the
  direct write still won at draw time), so it was not the source of the
  gray strip, but it is exactly the kind of latent fragility that has
  produced a visible bug elsewhere in this list - fixed by leaving
  `CityView` unanchored (the default), which is what `_adopt_parent_size()`
  already assumes.
- **The strip was never the margin fix's job to close, because it lived
  one layer further in than either previous fix ever looked.** Both the
  margin fix above and a follow-up "make the picture square" request
  still left a thin, symmetric gray-blue band running the full height of
  the picture, just inside the golden border, on both sides at once. The
  colour was a giveaway once actually sampled instead of eyeballed: not
  `(77,77,77)` (the raw `clear_color`, already ruled out) and not a plain
  darkening - it was the WALL/GROUND palette's own cool grey. The isometric
  town's real footprint, wall margin included, is `(GRID + 2) * TILE_W` =
  638px; `CityView` never clipped or scaled its own drawing, so on any
  frame narrower than that (the old 640px-wide rectangle happened to just
  clear it - not by design - and the square request's ~424px definitely
  didn't) the grid/walls/buildings kept drawing at full, unclipped size
  and the overflow painted straight over the golden border sitting right
  outside `CityView`'s own rect. Two earlier "fixes" had each been
  screenshotted and declared done without ever sampling *this* specific
  band, because it reads at a glance as terrain, not a leak.
  `_town_scale()` (`city_view.gd`) is `min(1, size.x / footprint)`;
  `_draw()` wraps only the town-specific calls (slab shadow, ground,
  walls, buildings - never the sky/ridge/countryside backdrop, which
  already fills `size` correctly) in `draw_set_transform()` at that
  scale, centred. Scaling only the *drawing* would have silently broken
  clicking - `_building_at()`'s stored `bounds` are computed in the same
  unscaled space `_tile()` always used, so `_building_at()` now runs the
  mouse position through `_to_town_space()` (the exact inverse transform)
  before testing it, or a visually-shrunk building would need a click well
  outside its own picture to register. `clip_contents = true` on
  `CityView` is the belt-and-suspenders on top: whatever the exact reason
  a future shape doesn't fit, it now cannot repaint the border beside it
  regardless.
- **The town picture is square now, asked for explicitly** ("bu kadar
  uzun bir dikdörtgen olmasın" - a tall/narrow viewport had been
  stretching `MapPanel`'s height with nothing capping it). `MapFrame`
  (`AspectRatioContainer`, `ratio = 1.0`) sits between `MainRow` and
  `MapPanel` in `city_map.tscn`; it takes whatever rect `MainRow` gives
  it and holds `MapPanel` to a real square inside it, so the picture can
  no longer grow taller than it is wide regardless of the viewport's own
  aspect ratio. `city_map.gd`'s `_map_panel` path grew one segment
  (`MainRow/MapFrame/MapPanel`) to match.
- **The brief briefly moved below the map, and moving it surfaced a real
  overflow.** For one round `MainRow` (the `HBoxContainer` that puts the
  map and `CityBriefPanel` side by side) was removed and `MapFrame`/
  `BriefScroll` became stacked children instead. That exposed a bug the
  side-by-side layout had been hiding: `TitleLabel`/`InfoLabel` never had
  `autowrap_mode` set, so their *unwrapped* text width was their minimum
  size, and on a narrow viewport that dragged the whole screen's minimum
  width past the viewport itself - with the root `Control`'s
  `grow_horizontal/vertical` both `GROW_BOTH`, the overflow split evenly
  off *both* edges, clipping the first and last few characters of every
  line at once (map included). Both labels now carry `autowrap_mode = 2`
  - this fix is real and stayed. `MapFrame`'s `custom_minimum_size` also
  came down from 440 to 320 in that round and stayed too; `_town_scale()`
  (see the bullet above) already exists precisely so the town keeps
  degrading gracefully at the smaller floor.
- **The stacked layout and the map's own hover hint were both asked to be
  undone, explicitly and by name: "harita solda, menü sağda", "haritanın
  üzerindeki yazıyı kaldır komple."** `MainRow` is back, wrapping
  `MapFrame` (still square, still 320 minimum) and `BriefScroll` side by
  side exactly as before Faz 16's square-map round; `city_map.gd`'s two
  node paths grew the `MainRow` segment back. The hover-hint `Label` -
  the thing the previous round had been *widening its reserved space
  for* - is deleted outright rather than resized again, per the explicit
  "kaldır komple": `UI_CITY_HOVER_HINT` was left as an unused CSV key at
  the time (it was deleted later, task 3.5).
  **Reverting to side-by-side surfaced the actual overflow bug**, and it
  was not in `city_map.tscn` at all - it was in `CityBriefPanel`, which
  this whole layout back-and-forth had never touched. Two of its `Label`s
  (the chapter-line heading and the shared `_heading()` helper used for
  "Hikâyenin Neresindesin?"/"Kervanın Durumu"/"Nereye Gidilir?") never had
  `autowrap_mode` set, the same class of bug as `TitleLabel`/`InfoLabel`
  above - and a need-row `Label` (`_build_need_row()`) carried a hardcoded
  `custom_minimum_size = Vector2(330, 0)`, which forces a container's
  minimum width regardless of autowrap. Any one of these forces the whole
  `BriefContainer`'s minimum width wide, and since a `VBoxContainer`
  gives every child the *same* resolved width, even the correctly
  autowrap-enabled siblings then get handed that same wide rect and never
  actually wrap - they just fit inside space that happens to be generous.
  This had been sitting in `CityBriefPanel` since it was written; it
  never showed because `BriefScroll` always had generous width until this
  session started testing narrower ones. Fixed by adding the missing
  `autowrap_mode` and dropping the hardcoded 330 minimum (the label
  already had `SIZE_EXPAND_FILL`, which grows it at wide widths without
  needing a floor). Verified at 700px: what used to be `"...ve bir yol
  ark"` / `"...önce birinin sar"` (mid-word clipping, not wrapping) is
  now full sentences wrapped cleanly at word boundaries. At an extreme
  420px phone width the map's fixed 320 minimum still leaves the brief
  column only ~55px wide - inherent to a literal side-by-side layout at
  that width, not a bug this fix could close, and not what was asked to
  be fixed this round.

## Art Rules: CityView'un kır dolgusu

- **A correct gradient can still read as an empty gray frame.**
  `CityView`'s field gradient technically covered every pixel outside the
  wall, but the countryside layer only ever put something *on* it near
  the horizon (trees, behind the town) — the whole strip in front of and
  beside the town stayed one flat, uninterrupted colour. On a tall
  (phone-ratio) window that strip is most of the screen, and it was
  reported back in exactly the words a real layout bug gets: "gray
  background frame." It wasn't a sizing bug (`_adopt_parent_size` already
  covers that, see above) — it was the same "flat marks are ground,
  standing props stand on it" gap `TravelForeground`'s apron closed for
  the road, never closed here. `CityView._draw_foreground` reuses that
  exact vocabulary (`ArtDraw.shrub`/`rock`/`ellipse`/`contact_shadow`,
  same "referenced off the ground colour, always lighter" rule) scattered
  across the whole surrounding countryside — not just a bottom strip,
  because an isometric top-down view has no single "front"; excluded is
  only the town's own outer-wall bounding rectangle, so nothing grows
  through a wall. A naive random scatter first clumped into a "mushroom
  farm" (three shrubs on the same spot read as one blob, the same
  stacking mistake `CAMPFIRE_SEATS` already caught elsewhere) — fixed
  with the same fix, a minimum gap checked against every already-placed
  prop before a candidate is accepted. Trees stay exactly where they were
  (only behind the town, only near the horizon): "nothing tall below/near
  the camera" is still the rule, this only fills in what was never
  allowed to be tall.

## Art Rules: eski ana menü arka planı (MenuBackdrop, gece kampıyla değişti)

- **A memory that never moves is a photograph, not a memory.** The menu's
  caravan was a single static frame - `MenuBackdrop._draw_caravan` ran
  once per resize and just sat there. Asked for explicitly: a road, real
  motion, a longer and busier column.
- **The road and the caravan have to travel in the same direction, or
  neither one reads as a road.** The first attempt drew a *perspective*
  road - a trapezoid narrowing from a near edge up to a vanishing point at
  the horizon city - and slid the caravan from the near end toward that
  point, shrinking it as it went. It shipped, and it was wrong: the road
  ran steeply toward one corner of the screen while the caravan's own
  formation stayed flat and horizontal the whole time, so the two visibly
  disagreed about which way "forward" was - a road that read as vertical
  under a caravan that read as horizontal. Reported back in exactly those
  terms. The fix was not a smaller correction to the perspective version,
  it was dropping the premise: `_draw_road` is now a flat horizontal band
  at `ground_y`, the same height the caravan draws at, spanning the full
  width. `_draw_caravan` no longer scales or changes height at all - it
  only translates in `x` - so the caravan's baseline and the road's
  centre-line are *the same line* by construction, and "walking off the
  road" stops being a thing that can happen rather than a case that is
  checked for.
- **Measuring the column and placing it are the same function, here too**
  (bkz. `RoadCaravan._walk_column`'s original statement of the rule).
  `_walk_caravan(unit, ink, place)` is called once with `place = false` to
  get the formation's total width (for the loop math below) and once with
  `place = true` to actually draw - a second, separately-written measuring
  pass is exactly how the road screen's own column drifted from its
  drawing in the first place.
- **The leader draws at the *highest* local `x`, not `0`.** The formation
  moves in `+x` (the horse's neck in `_silhouette_rider` already points
  that way, from the very first version of this file), so whichever figure
  sits at the largest local `x` is the one that leads. Building the column
  rider-first, as the static version had, put the leader at the *smallest*
  `x` - correct for a motionless portrait, but the moment the formation
  starts sliding in `+x` that makes the wagons lead and the rider trail
  behind them. `_walk_caravan` places the wagons and walkers first and the
  rider last for exactly this reason - no figure's own drawing changed,
  only the order along the shared cursor.
- **Looping by wrapping off-screen beats looping by fading.** The
  perspective version had to fade `ink.a` to zero at both ends of its loop
  to hide the pop between "a speck at the vanishing point" and "full size
  at the near edge" - and still needed a special-cased starting `_time` so
  neither the game's opening frame nor `screenshot_menu.gd` caught the
  invisible instant. None of that exists in the flat version: `span` is
  the screen width plus the formation's own total width, and `start_x =
  fposmod(_time * speed, span) - total_width` sweeps continuously from
  fully off the left edge to fully off the right - the formation is
  always either fully visible or fully off-screen, so there is no
  transparent instant to land on and nothing to special-case at `_time =
  0`.
- The column itself grew from two wagons to `CARAVAN_WAGON_COUNT` (4) for
  the "kalabalık ve uzun" ask - the per-wagon walker/ox/wagon triplet was
  already the unit of length, so lengthening the caravan was raising one
  loop bound, not inventing a new pattern.
