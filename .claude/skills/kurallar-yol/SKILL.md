---
name: kurallar-yol
description: Wayborne kural kitabının "Yol katmanı, yolculuk, hava ve arazi" bölümü (CLAUDE.md'den taşındı). Şunlara dokunmadan, şunları tasarlamadan ya da şunlar hakkında karar vermeden önce yükle: road_journey.gd, JourneyController, JourneyClock, RoadAttention, RoadSignals, RoadCaravan yürüyüşü ve kamp, RouteTerrain, RouteWeather, Temperature, RouteConditions, sapma ve geri dönüş, tempo, karşılaşma işaretleri, yol ekranı düzeni. Bozulmaması gerekenleri ve nedenlerini tutar.
---

# Yol katmanı, yolculuk, hava ve arazi

CLAUDE.md'nin bu bölümleri 2026-10-30'da kullanıcı kararıyla buraya taşındı; metin değişmedi, başlıklar aynı. Koddaki
"bkz. CLAUDE.md <başlık>" başvuruları buraya bakar. Kural becerilerinin listesi CLAUDE.md'de ("Kural becerileri").
Bölümler: Road Layer Rules, Route Terrain & Weather Rules, Temperature Rules, Route Rules, En-Route Plan Rules, Road Movement Rules, Journey Time Rules, Road Encounter Rules, Road Screen Layout Rules, Encounter Timing Rules.

### Road Layer Rules

The road was "hold a key, a card opens at dawn". The only input was *are
you moving*, and the answer was always yes — so walking was never a
decision. The fix was not to shorten the road (the parallax landscape and
the walking figures are the game's strongest asset) but to deepen it.

- **Where you stand is what you notice.** `RoadAttention` splits the
  column into three zones and the leader can only be in one: the head
  (see an encounter early), the wagons (catch the axle before it breaks),
  the rear (gather the stragglers). Each zone's reward exists **only** in
  that zone; if one spot paid all three there would be no decision. The
  leader could already walk the column (`RoadCaravan.set_leader_offset`)
  — that movement was purely cosmetic and is now the mechanic.
- **Walking the column shouldn't stop just because the caravan itself
  did.** Camp froze `_advance_position()` entirely, so the leader was
  stuck wherever they stood the moment the fire was lit - reported back
  exactly that way, "stuck at the front, can't walk back". Camp now only
  skips `_walk_at()` (there is no distance to cover while making camp);
  A/D, a click or a tap still moves `_leader_offset` within the
  stationary column. Since the control redesign the leader is always free
  in the column (see Road Movement Rules), so camp ending leaves them
  where they stand. **Superseded for the leader at camp:** the leader now
  dismounts and walks to the fire too (below), and is not walkable while
  away from the horse (`RoadCaravan.is_leader_at_camp()`).
- **A speed lever has to move everything it looks like it's moving.**
  `JourneyClock`'s speed multiplier already scaled `_days_covered` (hence
  the background's `_world_x`) through `hours`, but `RoadCaravan`'s own
  leg-swing cadence (`_speed`) was pace-only and never touched by that
  multiplier - at 3x the scenery raced by while the walk cycle stayed at
  its 1x cadence, reading as the caravan sliding rather than running.
  `_caravan.set_speed()` now also multiplies by `_clock.get_speed()`; at
  the default 1x that's a no-op, so nothing about the un-sped-up game
  changed.
- **The gap between cards was the emptiness, not the cards.** A day's
  event fired once, at dawn, leaving 23 silent hours. `RoadSignals` fills
  them and is deliberately **non-modal**: no card, no paused clock, no
  forced choice. Attending one *is* walking to its zone, so no new input
  is invented either.
- **An ignored signal grows.** A creaking wheel is a snapped axle three
  days later. The cost is always paid in the game's existing vocabulary —
  wagon damage, stress, route danger applied to the headroom — never a
  new punishment system. A signal that could be ignored for free would be
  scenery.
- **The road remembers (tasks Y-B11, R2).** Whoever dies on the road leaves a grave there, a fallen leader a cairn,
  a lost wagon its wreck, a camp its ash (`GameSession.road_memorials`, capped per road - ash goes first, graves stay).
  Positions are stored as a share of the road from its key's first city, so the same spot is found from either
  direction. `TravelBand` draws them (no religious symbols); passing one writes a line - the name and cause only if
  the leader is at the front. `route_memory` counts trips and deaths per road; the road screen and the planner say it.
- **A signal's kind is not its answer (task Y-B03).** Every road signal draws a hidden truth when it appears
  (`RoadSignals.TRUTHS`: smoke may be a bandit camp, a farmstead burning or herders; a creak an axle, a loose load or
  nothing; a straggler tired, sick or a stranger; a raven at the rear a true or an empty omen). Walking to its zone
  reveals the truth and its small reward; ignoring it pays the truth's own price, and some truths cost nothing - but
  only looking tells you which. The truth is saved with the signal, so a reload cannot reroll it.
- **Pace is a resource, not a toggle.** The speed button was free,
  reversible and consequence-less. Pushing now burns `CaravanState.stamina`
  and an exhausted caravan drops back to steady on its own; camp is the
  way out. That is what makes hurrying a decision against the calendar
  (contract deadlines, debt, season) rather than a setting.
- **Combat frequency and avoidability ship together.** The game's deepest
  system was its rarest. Ambush weight went 1.4 → 3.2 with a shorter
  cooldown and a tiered danger multiplier; wildlife 1.0 → 2.2. Frequency
  *alone* would have made fights a tax — the counterweight is the
  attention layer, where a player at the head of the column sees the
  encounter half a day out and can prepare or turn back.
- **An invisible resource is not a resource.** Stamina got a bar and
  attention got a label. The label sits in the *bottom* bar next to the
  walk hint, because that is where the player's hands are and attention is
  changed by walking. Adding a fourth bar overflowed the top strip and
  clipped the caravan numbers, so `PulseBar` narrowed 150 → 122 — when a
  strip fills up, first ask what actually belongs there.
- **A trait must be visible outside combat.** Afflictions used to bend a
  combat number and nothing else; they now raise the signal rate, so a
  frayed company visibly fumbles more on the road.
- **Camp is a place, not a pause icon, and "vagon başına bir tane" is
  also a placement problem.** A single campfire could sit in the one
  patch of screen with no silhouette behind it - ahead of the whole
  column, in open ground (see the old `TravelBand._draw_campfire`, now
  gone). Multiplying it by wagon count removed that escape: every fire
  now belongs to `RoadCaravan`, not `TravelBand`, and sits at its own
  wagon's **trailing** side (`CAMPFIRE_TRAIL_RATIO`) - the front is
  already occupied by that wagon's own ox and crew, so the only open
  pocket is behind it, inside `GAP_WAGONS`. Moving the fire into
  `RoadCaravan` was not just a placement fix: `TravelBand` draws itself
  *under* its children, `RoadCaravan` *is* one of those children, so a
  fire drawn from `TravelBand` could never win against a wagon it
  overlapped - only moving the art into the same node as the wagons let
  later draw calls paint over them on purpose.
- **"Kervandakiler ateşe gelsin" is a walk, not a teleport, and it has to
  survive being interrupted.** `RoadCaravan._advance_gather` eases a
  shared `_gather_progress` between each figure's column "home" and its
  assigned fire (crew tied 1:1 to their own wagon's fire; party split
  round-robin across the fires) and drives the same `WalkFigure.advance()`
  the normal column walk uses, so gathering isn't a different kind of
  motion, only a different target. The oxen (still in harness) and the
  horse never join - the mechanic is about the *people*; since the
  dismount pass the leader does (see "Off the seat first" below).
  Two things this had to get right or the illusion breaks the moment
  anything else touches the scene: `_place()` (the formation layout that
  normally snaps every figure to its slot) redirects a gathering figure's
  call into just *updating its stored home*, never its on-screen
  position, or a mid-transition window resize teleports it there
  instantly; and the progress direction is read from `_camping` itself
  every frame rather than latched once, so reversing mid-return (camp
  struck, then re-lit before anyone got home - not reachable at `CAMP_HOURS`
  today, but the code must not assume it stays that way) can't strand a
  figure hanging between two points.
- **A gathering nobody can see is not a gathering.** The first version
  put exactly one walking crew figure at each fire and called it done -
  measured against a real screenshot, it read as a lone sentry, not a
  camp. Two fixes closed the gap, both playtest-driven:
  - **The driver joins too.** `ArtDraw.wagon()`'s seated silhouette is
    normally the *only* trace of that wagon's second crew member (bkz.
    `PEOPLE_PER_WAGON` - two people per wagon, one drives, one walks);
    it never left the bench. `RoadCaravan` now keeps a parallel,
    initially-invisible `_driver_figures` array, and when camp starts
    that figure becomes visible and gathers exactly like the walking
    one, while `wagon()`'s own `draw_driver` flag goes false so the seat
    isn't drawn twice. `ArtDraw.wagon_driver_seat()` is the one formula
    for where that seat is - `wagon()` reads it for the static silhouette,
    `RoadCaravan` reads it for the WalkFigure's departure point, because
    a seat computed in two places is two different seats.
  - **Shared fires need shared seats, not a shared point.** Every figure
    assigned to the same fire was targeting the *identical* coordinate -
    two or three people collapsing onto one pixel reads as one person.
    `CAMPFIRE_SEATS` fans them out around the flame by a few pixels each
    (`CAMPFIRE_SEAT_SPACING`), assigned in gathering order so the driver,
    the walking crew and any party members sharing a fire land on
    different seats. `test_camp_gathering.gd`'s stacking check is the
    general form of the same mistake the layout tests already guard
    against elsewhere in this file: two things placed by the same formula
    are the same thing unless something forces them apart.
  - One trap both fixes had to dodge: a figure's *target* y has to be
    the true ground line, always - not "wherever it currently stands."
    The walking crew and party already stood at ground level, so reading
    their current y was harmless, but the driver starts on the wagon's
    raised seat; reusing that as the fire-side height left them floating
    at bench-height the whole walk. The fire target now always resolves
    to `_ground_y - figure.size.y`, which is a no-op for anyone who
    started on the ground and a real descent for anyone who didn't -
    the same target drives the return trip, so climbing back onto the
    seat falls out of the same fix for free.
- **A row is not a ring.** The seat offsets above shipped `x`-only, so a
  fire with four or five people gathered still read as a line standing
  shoulder to shoulder on one side of the flame - "everyone stacked at
  the same spot" had been fixed, "everyone spread around the fire" had
  not. `CAMPFIRE_SEATS` is now `Array[Vector2]`: each seat also carries a
  `y` ratio, added straight onto `_ground_y` (never onto the fire's own
  drawn position, which already carries its own near-offset - stacking
  the two would give every seat a different notion of "ground"). The `x`
  ratios keep the exact values and the exact separation the stacking test
  already verified; only `y` is new, so a fix aimed at "surround the
  fire" could not quietly reopen "don't stand on top of each other."
- **A ring is not a heap either (task Y-G13).** The first seat ring stayed inside ±2.3 units (about 30 px), narrower
  than the fire's own logs, and six people at a lead-wagon fire stood on the wood and covered the flame - caught in
  the campfire showcase frame, invisible to the stacking test, which only asked that people stand apart from each
  other. Seats now sit on both sides of the fire (±2.9 to ±6.6 units, alternating, inside out) so the flame stays
  open; figures are drawn over the fire, so nobody may sit in front of or behind it. A figure that has arrived
  turns to face the fire (its seat can lie past the fire from where it walked in).

- **Off the seat first, then to the fire - and back on before anyone
  moves.** Reported as "önce vagondan inip sonra ateşe gitmeli; lider de
  attan inmeli": the driver used to slide straight from the bench to the
  fire on one shared progress value, and the leader stayed mounted.
  - **Each person has their own progress** (`_gather_walk`, and
    `_gather_trans` for those who sit). Going: transition first, then the
    walk; returning: the walk, then the transition reversed. A shared
    counter cannot express "the driver is still climbing down while the
    walker is already halfway". `set_camping(true)` mid-return no longer
    rebuilds the gathering: everyone turns round from where they are.
  - **Two clips, played both ways** (`FigureActions` `dismount`,
    `climb_down`; reversed they are mounting and climbing up). They are
    the only **hip-rooted** clips (`build.json` root `pelvis`,
    `WalkFigure.TRANSITION_CLIPS`): the figure hangs from its hip, which
    `RoadCaravan._transition_hip` moves from the saddle/bench to standing
    height. The clip is written against the real ground; the gap between
    its seated hip and this horse's saddle or this wagon's bench is added
    and fades out by the time the first foot lands (`SEAT_BLEND_U`).
  - **The horse stays; a second figure is the rider on foot.**
    `_leader_rider` is the player drawn as a person, hidden outside camp;
    while it is out the mounted figure is drawn `riderless` - one person
    is never on screen twice, the same rule as the driver's bench
    silhouette.
  - **The caravan waits until everyone is back.** The other half of the
    report ("kamp bitince oyun hızlanıyor, mankenler akıyor"): the column
    started walking the instant camp ended, so the returning people
    slid to their screen slots over a scrolling world. `is_breaking_camp()`
    now holds `_walk_at()` until the last person has walked back and
    climbed on; the clock still runs.
  - A clip not yet rendered for a garment someone wears falls back to the
    seated pose in the first half and standing in the second
    (`WalkFigure._draw_transition`) - never naked, never floating.
  - **On the road the bench holds the real figure too.** The driver used to
    be `ArtDraw.wagon()`'s flat silhouette (a disc and a quad) outside camp,
    and the player read it as the old mannequin. `RoadCaravan._seat_driver`
    keeps each driver figure visible on its bench in the first frame of
    `climb_down` (hip on the seat, facing the wagon), so the silhouette is
    never drawn while the caravan has its drivers.

- **Camp walking has a ceiling, and the camp clock starts when everyone is at the fire (task 12.2c).** Gathering used to
  last 30-60 real seconds (the farthest figure's brisk speed bound everyone; party members were dealt to fires in turn
  and walked twenty body-heights) and `CAMP_HOURS` started at the press, so the walk ate the camp. Now each figure walks
  its own way (`_figure_gather_seconds`), capped at `MAX_GATHER_SECONDS` (3 s at 1x) and at twice its brisk speed; party
  members go to the *nearest* fire. The game-speed multiplier scales the walk (`set_gather_time_scale`, never below 1x).
  A fire lights when its first figure arrives (`_update_fires`; wood only before). `JourneyController.camp_ends_at`
  starts the `CAMP_HOURS` counter when `is_camp_settled()`; while people walk (`is_camp_transitioning()`) the clock runs at
  normal speed, not the camp's 0.5x. The task text asked both for <= 3 s and for <= 0.5 game hours; those disagree
  (0.5 h is under one real second at 1x), the seconds were kept.
- **The world scale holds while the caravan is not walking (task 12.2b).** `pixels_per_day` was re-derived as ground speed
  over day rate; at camp the day rate fell toward zero and the scale blew up, so road stops flew out of frame. See
  `RoadJourney.world_scale_holds`.

### Route Terrain & Weather Rules

`WorldMapData` is the unchanging map and `RouteConditions` is this week's
state; `RouteTerrain` is the third layer, the road's *geography*, and
`RouteWeather` is the day's sky. Both are **computed from a seed, never
stored** - the same reasoning as `RouteConditions`' natural states: two
cities are always joined by the same terrain, and reloading a save cannot
re-roll the rain away.

- **Terrain is data before it is a picture.** Segments, their biomes, the
  roadside stops (mezra, outpost, mine, pass, shrine, bridge) and the
  slope all come from `RouteTerrain`; the road screen draws them and the
  planner prints them in one line, so choosing a route is no longer blind.
- **The map decides the terrain, not the route's name.** Every road of the
  map v3 carries its own biome sequence and stops, measured along the real
  path by `tools/worldmap/build_settlements.py`:
  - **Biomes:** mountain polygon or a mountain people's region, then
    within reach of a swamp town, then lake or sea shore, then forest
    (inside or at the edge), then meadow for the valley's open land (task
    N29: the Tyrell-like valley is green, not dry grass), otherwise steppe.
    The labels are smoothed and merged into parts of at least 1.2 days.
  - **Stops:** a pass entering mountains, a bridge entering water, else
    the nearest map point on the way (tower, abbey, mine, village...),
    spaced at least three days apart (six on the steppe, where yurts and
    villages otherwise stopped a 35-day road five times, task N30).

  It is written in the direction of `terrain_from`, and
  `RouteTerrain.build(key, days, from_id)` reads it backwards from the
  other end, slopes included. Every caller passes the journey's own origin;
  turning back and diverting keep it. Seeded only from the key, the valley
  road Belvanor-Ilsande had come out as a mountain road. Keys that are not
  on the map (tests, the synthetic journey) still use the seeded chain,
  where biomes step at most two places along `BIOME_CHAIN`.
  `test_route_terrain` checks every map road in both directions: coverage,
  the mirror, the geography and the provision promise.
- **Some crossings have no bridge (task R4 #16).** A seeded third of the map's bridge stops are fords
  (`RouteTerrain.STOP_FORD`; seeded by route and boundary so both directions agree). The water level is read from the
  last three days' weather (`RouteFord`, low/moderate/high, marsh one step higher), never stored; the front of the
  column reads it on approach. `evt_river_ford` opens the right crossing for the level - wade when it is low, risk the
  flood when it is high, each locked with its reason otherwise - or lighten the load, or wait a day. Nobody dies and
  no wagon is lost there.
- **The same road differs by season and by choice (task Y-B13).** Two deterministic passes over the map's terrain,
  never stored: spring floods steppe or meadow beside water into marsh, summer dries an inland marsh to meadow, winter
  steepens mountains (slower). A shortcut (`RouteTerrain.shortcut_available`, roads of 5+ days) cuts 20% of the days
  and sends the middle third over mountain or forest, with danger raised on the headroom. The season is the
  departure day's (`GameSession.journey_start_day`, saved with the shortcut flag in the journey block); the planner and
  the road build with the same arguments, and `test_route_terrain` re-runs the provision promise for every season and
  shortcut. A diversion drops the shortcut.
- **A drawn stop that no event ever reads is scenery with a name on it,
  not a feature.** `evt_roadside_shrine` fired from the general pool with
  no idea whether a shrine stop was actually on screen that day - the
  card and the marker were two systems that had never been introduced.
  `road_journey.gd`'s `_run_day()` now reads `_terrain.segment_at(
  _days_covered).stop` and hands the event pool a `near_shrine` flag; the
  event's own base weight dropped low (an unmarked wayside shrine can
  still turn up, rarely) and an `EventWeightModifier` (×8, the same
  pattern as `evt_forage`'s İzci bonus) makes it fire reliably on the day
  the caravan actually passes one. Every stop kind has a card now, each on
  the same wiring (`EventResolver.stop_context()` → `near_<stop>` flag, low
  base weight, ×6-×8 modifier): pass → `evt_culture_highland_challenge`,
  mezra → `evt_leave_the_wounded`, outpost → `evt_frontier_outpost`
  (Zeka), mine → `evt_mine_collapse` (Dayanıklılık), bridge →
  `evt_failing_bridge` (Bilgelik). Each also carries one option whose cost
  lands on a *named* person (`PARTY_HP` on the best holder of a stat).
- **Weather invents no system.** All of it turns levers that already exist:
  walking pace, route danger (applied to the headroom, `base + delta *
  (1-base)`, the same rule as `RouteConditions`) and the daily morale drain.
  Clear weather - the most common - is exactly neutral, or weather stops
  being an event and becomes a hidden tax on every journey.
- **Weather slows the road, so the planner asks for the food it will
  cost.** This is the one place weather could have broken a promise:
  *correct stocking never starves* (see Provision Rules). Because weather
  comes from a seed, the planner can read the whole journey's weather in
  advance - `RouteWeather.forecast_extra_days()` walks the days and returns
  an **exact** reserve, not an estimate, and `CaravanPlan` adds it to the
  provisions required and shows it as its own line. `test_route_terrain.gd`
  runs 80 route/length/departure combinations and asserts a caravan stocked
  with the reserve never runs out before the road ends.
- **The day number is `total_days_elapsed + 1`, nothing else.** Adding the
  journey's own day counter on top double-counts (`advance_day()` already
  moves `total_days_elapsed`) and the weather sequence skips every other
  day - which would silently desynchronise it from the planner's forecast
  and bring the starvation back.

### Temperature Rules

`Temperature` (`scripts/travel/temperature.gd`) turns season, the map's climate (`cold`/`warm` per segment, Rendered
Road Rules), biome, hour and the day's weather into a Celsius degree. **Computed, never stored**, like `RouteWeather`:
the same road on the same day is the same cold, and a reload cannot warm it.

- **It turns existing levers only.** The night before each dawn costs every named person by their *cold band*
  (`cold_load` = `COMFORT_C` − night low − their clothes' warmth, `CAMPFIRE_WARMTH` more if the fire burned that
  night): stress and fatigue, and in the worst band a small fever chance. The crew (fixed `CREW_WARMTH`) costs morale.
  Clothing carries `OutfitPiece.warmth` (`OutfitCatalog.WARMTH`, slot defaults); body weight adds ±2, the middle weight
  exactly neutral. A peasant kit is ~4, a full winter kit ~19.
- **A freezing day eats more, and the planner asks for it first.** `ration_share` (0 / 0.25 / 0.5 below 0 and −12 °C)
  multiplies the daily provision formula on the road (`GameSession.get_daily_provision_consumption`, only while
  `road_sky` is set), and `CaravanPlan.cold_ration_shares` - filled by `Temperature.forecast_ration_shares`, the same
  day-by-day walk as `forecast_extra_days`, taking the coldest segment the caravan could reach that day - adds exactly
  that to the required provisions. `test_temperature` walks every map road in midwinter at steady and fast pace and
  asserts nobody starves; removing the share starves 107 of them.
- **The road writes the sky, the session reads it.** `road_journey._refresh_weather` calls `set_road_sky` every dawn
  and on load (transient, recomputed); the fire's night is the saved `last_fire_day`. The gauge is the hour's weather on a bronze coin in
  the Durum tab, its tooltip words-first (`Wording.warmth_tooltip`: the night's low and who will be cold without a fire).

### Route Rules

Geography is fixed; the network on top of it is not. `WorldMapData`'s edge
table stays the authored map - which city borders which, how far, how
dangerous at rest. `RouteConditions` is the layer that makes the same seven
edges behave like a different network every week: floods, landslides,
brigand country, and the events that cause them.

- **The split mirrors `MarketPricing`/`MarketConditions`**: a base table
  plus a live layer that multiplies it. A caller that knows nothing about
  the layer sees the old, static behaviour.
- **Natural conditions are computed, never stored.** Each route rolls once
  per `SPELL_DAYS` window from a `route_key + spell` seed, so reloading a
  save cannot re-roll a closed pass open, and only event-driven overrides
  (`add_override`, `EventEffect.Type.ROUTE_CHANGE`) live in the save file.
  The window is offset per route, or every road in the world would change
  on the same morning.
- **A route's state is undirected.** An avalanche does not fall in one
  direction; `route_key()` sorts the pair, and both directions read the
  same entry.
- **No city can ever be sealed off.** If a closure would leave a city with
  no open exit, `get_state()` downgrades it to `SLOW` - the road is barely
  passable rather than gone. Applying this in `get_state()` (not in
  `is_open()`) is deliberate: duration, danger, the on-screen label and the
  pathfinder all read `get_state()`, so a road the caravan is travelling
  never displays as "Geçit kapalı". `get_raw_state()` is what the dice
  actually said, for the rule itself and for tests.
- **A closed road is a detour, not a dead end.** `find_open_path()` BFS's
  the open network; the world map shows the alternative rather than just
  greying the city out.
- **Screens read the session, not the route.** `GameSession.get_route_
  travel_days()/get_route_danger()/is_route_open()/get_route_state()`
  compose all three layers (table, conditions, the caravan's own danger
  growth). Reading `route.travel_days` directly is how the screen and the
  road drift apart.
- **Danger deltas apply to the headroom, not the total** (`base + delta *
  (1 - base)`), so brigands make a quiet road genuinely risky without
  turning an already-deadly one into a 90% coin flip.

### En-Route Plan Rules

The plan made in the city is an intention, not a commitment.

- `GameSession.divert_journey()` / `turn_back()` are the only ways to change
  a journey in progress. The caravan is not somewhere on the map it can
  teleport from: a diversion is measured as *the days already walked* plus
  the route from the origin city, so backtracking is paid for.
- You may only divert to a city reachable **from the origin** whose route is
  open that day (`can_divert_to`).
- The new leg is a new journey: `journey_total_days` and
  `journey_days_remaining` are both reset, or the progress bar would stay
  full and the arrival check would fire immediately.
- Contracts written to the abandoned destination cannot be delivered; the
  bill is settled on arrival by `_apply_undelivered_contract_penalty()`.
  Nothing special is needed for this - it is the same path a failed
  delivery already takes.
- Deciding is free of time pressure (the panel counts as an open panel, so
  `_can_time_flow()` is false) but the decision itself costs hours: turning
  a caravan around is not instant.

### Road Movement Rules

The road used to run itself: the clock ticked, days fell off a counter and
the caravan arrived. The player's only input was a speed button, and the
screen read as broken — *"we're standing still, we have no control."* The
first fix handed the player the caravan's legs (hold D to walk), and that
was the wrong half: holding a key is continuous input with no decision in
it. The rule the control redesign settled on, and that every control on
the road now follows:

**Input is a decision. Input that carries no decision becomes automatic;
every decision has a visible control, and a key is only its shortcut.**

- **The caravan marches at the pace you ordered; you walk the leader.**
  The orders panel's pace buttons (Dur/Yavaş/Normal/Hızlı - `COMMANDS`,
  1-4 and F2 as shortcuts) set `_pace`, and `_advance_position()` walks the
  column at it every hour. A/D, the arrow keys, the triggers, a click or a
  tap move only the leader along the column (`_move_leader`,
  `RoadCaravan.leader_offset_for_x`) - the one body the player moves
  directly, which is also what `RoadAttention` reads. The gold mark over
  the leader is always drawn.
- **Halting is an order, not an absence of input.** "Dur" is a pace. The
  day still passes (provisions, contracts, the day's event): dawdling is
  paid for by the calendar, which is the Oregon Trail tension, and it no
  longer depends on the player letting go of a key.
- **Steady pace reproduces the old full-tempo walk exactly** (rate 1.0), so
  the planner's provision promise - *correct stocking never starves* -
  holds for a player who never touches the pace.
- **Backward walking and the detach command are gone, and what replaced
  them.** Walking the wagons backward at quarter speed was never a real
  choice - turning back is `turn_back()`/`divert_journey()` (En-Route Plan
  Rules), which already discards a pending marker. "Detach and walk the
  column" became the default: the leader is always free within the column.
- **Walking left is walking, not a moonwalk.** `WalkFigure.advance()` used
  to run the gait phase backwards for a negative speed while the skeleton
  was already mirrored by `facing` - a figure facing left played its walk
  in reverse. The phase now always runs forward; the sign only sets the
  facing. And the leader's facing comes from its **ground** velocity
  (`RoadCaravan.set_leader_motion`), not from the column's: going back
  through the column the leader turns round.
- **The leader rides at the same ground speed both ways, in real time.**
  The old step was a constant screen speed per game hour, so going back
  against the column the rider barely moved over the ground (≈4 px/s)
  and coming forward he ran. `road_journey.gd::leader_screen_speed()` asks
  for `LEADER_RIDE_SPEED`/`LEADER_WALK_SPEED` *over the ground* in the
  pressed direction and adds or subtracts the column's own flow;
  `LEADER_MIN_SCREEN_SHARE` keeps the pressed direction honoured even when
  3x flow outruns the horse.
- **Turning back turns the caravan, in place and in order.** `turn_back()`
  used to reset the leg to zero and keep walking right - the same road
  scrolled forward to the city behind you. Now `JourneyController`
  carries `heading` and `leg_origin_day`: the return leg walks **the same
  terrain** backwards (`terrain_day()`), so the stops, biomes and slope you
  passed come back in reverse. `RoadCaravan.begin_turn()` plays the turn
  over `TURN_SECONDS` (10): the leader wheels his horse, then rides to the
  new head, and the order runs down the column - each unit (escort pair,
  crew+ox+wagon, pack animal) turns about its **own centre** as the wave
  reaches it (a paper flip that lifts a little toward the far lane). The
  order of the column does not change: a real caravan does not re-form on
  the road, the rear wagon simply becomes the head. Time is stopped while
  it turns (`_can_time_flow`); the hours were already paid as
  `REPLAN_HOURS`, and the merchants' reaction card waits until the turn is
  done. Heading, the leg's place on the terrain and the terrain's own key
  are saved, because after turning back the session's origin and
  destination are the same city and the key cannot be re-derived.
- **The camera moves at once, the caravan never slides.** `TravelBand`
  anchors a reversed caravan on the right of the frame (the mirror of the
  forward anchor) over `CAMERA_TURN_SECONDS`, and every layer scrolls by
  `_scroll_x()` = world position minus anchor: moving the anchor is a
  camera pan, the ground under the wagons stays put. The column's scale
  is taken from the forward anchor (`ground_line_changed`'s third
  argument), or the figures would grow while the camera pans. A diverted
  journey is a different road: it rebuilds its own terrain and faces
  forward again. `tests/screenshot_turnaround.gd` photographs the turn.
- **The hub turns in order too, and it never had.** The wave above is the
  *road's*; `world_hub.gd` had nothing - `_chase` calls each figure's
  `advance()`, which takes facing from the sign of its velocity, so the
  instant the player reversed the whole caravan mirrored in one frame.
  Reported as exactly that ("anında herkes arkaya dönebiliyor"). The hub
  now runs its own wave (`_advance_column_turn`), and the delay comes from
  a figure's **place in the column**, not its index in an array - so the
  escorts, the crew, the oxen and the pack tail are ordered by where they
  actually stand, and nothing has to know what the tail is made of.
  - **Its clock is deliberately a tenth of the road's.** Turning on the
    road is an order: the caravan is stopped, the hours are already paid
    (`REPLAN_HOURS`), and the ceremony happens once, so ten seconds is
    right there. In the hub the player reverses constantly - a ten-second
    ceremony would paralyse the caravan on every A/D press. The wave is
    `TURN_WAVE_SECONDS` (0.85) and each figure takes `TURN_SECONDS` (0.40).
  - **The leader turns at once.** It gives the order; waiting for itself
    would read as lag, not as ceremony.
  - **The curve is a static function** (`WorldHub.turn_facing`), per Motion
    Rules: a curve written inside `_process` is a curve no test can see.
    `test_caravan_layout.gd` asserts the head leads the tail, that everyone
    lands exactly on the target, and - the actual bug - that nobody has
    finished turning on the first frame.
- **The walk cadence was six times the ground speed, and nobody had
  measured it.** `RoadCaravan.STEP_RATE` was 2.6 with a comment saying
  "the number itself is visual" - running legs under a walking caravan.
  It was measured down to 0.52, and that fixed number was still wrong,
  which is the next bullet.
- **The ground and the step are one measure, per figure, at every screen
  size.** A fixed cadence was measured on a 320 px band; the road is full
  frame now, and at 1080p a person is 119 px tall while `PIXELS_PER_DAY`
  (900) moved the ground 20 px/s - the legs covered 39 px/s, so every
  planted foot slid *backward* over the ground at twice its speed. That
  was the moonwalk the player kept feeling, and no test saw it because
  every test used the 320 band. The oxen, horse, donkey and dog shared the
  same cadence although their strides differ by half. The rule now:
  - **A figure's cadence is ground speed / its own cycle distance**
    (`WalkFigure.advance_ground`, `cycle_distance()`): a person's from
    `FigureRig.CYCLE_DISTANCE_RATIO`, an animal's from its render frames
    (`BodyFrames.BEAST_WALK_CYCLE`, **measured** by
    `tools/figure_pipeline/qa/beast_stride.py`, which reads 0.607 on the
    human frames against the rig's true 0.633). Wheels roll by the same
    ground speed over their radius (`ArtDraw.WAGON_WHEEL_RATIO`). A foot
    cannot slip by construction.
  - **The ground is scaled to the figure, not the screen.**
    `road_journey._update_world_scale` sets `TravelBand.set_pixels_per_day`
    so normal pace walks a person at `WalkFigure.WALK_CADENCE` (0.70
    cycles/s). Day-anchored things (stops, milestones, the encounter
    marker) are placed *relative to the caravan*
    (`TravelBand.screen_x_for_day`) and `_world_x` accumulates, because the
    scale is allowed to change.
  - **The caravan never runs.** Fast pace, 1.5x and 3x clocks still cover
    the real distance in days, but the scenery is clamped
    (`scenic_ground_speed`) between an amble and the brisk walk of the
    slowest walker in the column (`RoadCaravan.get_brisk_ground_speed`:
    person 0.95, ox 1.15, horse 1.25, donkey 1.35, dog 2.0 cycles/s). Legs
    speeding up would be running; scenery speeding up without the legs
    would be skating; shrinking the world's scale is neither. Measured in
    the live scene with oxen, dog and donkey: normal 1x ≈ person 0.57,
    fast 3x ≈ person 0.79 / ox at its 1.15 cap. The encounter marker is
    clamped to spawn inside the view (`ENCOUNTER_EDGE_MARGIN`), since a
    larger scale could push half a day off-screen.
  - **Everything else that walked on a constant follows the same rule.**
    The leader rides/walks at its figure's brisk speed (was 96/64 px, a
    gallop at 1080p); the camp gathering lasts long enough that the
    farthest walker's peak stays brisk (`gather_seconds`; 1.3 s made them
    sprint to the fire); turning in place steps at `WALK_CADENCE` (was
    1.6). The hub's 280 px/s was four body heights a second - it is now
    the column's slowest brisk walk (`WorldHub._walk_speed`), which makes
    crossing the hub slower, on purpose: the ox sets the pace.
  `test_caravan_layout`'s cadence test sweeps pace × clock × condition on
  both band sizes and fails if any figure exceeds its brisk cadence or
  its foot slips; `tests/screenshot_walk_cadence.gd` (now 1080p by
  default) prints a strip with red ticks fixed to the ground.
- **A figure fills about 86% of its box, and forgetting that sized two
  animals wrong.** The dog and donkey were reported as far too small
  against the caravan. The first correction computed their heights from
  `BeastRig.extent()` against the person's *box* - and landed both ~10%
  oversized, because `FigureRig` draws a person to only
  `HIP_RATIO + TORSO_RATIO + head` of that box. The numbers that ship were
  measured off a rendered frame with knee/waist/shoulder guides
  (`tests/screenshot_hub_motion.gd`), against the player's own spec: the
  donkey's ears at a human's shoulder (81% measured), the dog between knee
  and waist (45%). Calculation starts the job here; measurement ends it.
- **The ox was the same mistake one layer deeper, and `extent()` is why
  it hid.** Reported as "the ox looks shrunk - the tip of its horn should
  reach a human's shoulder", and measured at **57%** of a person on the
  road screen: a calf, not an ox. Two shrink factors stacked, and only
  the first was known - a person fills 86% of its box, and the ox's
  *painted skin* fills only **62%** of its own box. The second one is
  invisible to the obvious check: `BeastRig.extent()` (the part rig's
  rest-pose bounding box) says 76%, because the skin was painted on its
  own proportions, not the mannequin's - the same split Wardrobe & Rig
  Rules already states as "the pose is the art's, not the mannequin's".
  `extent()` is within 4% for the husky and the donkey and 23% out for
  the ox, so trusting it looks safe right up until it isn't.
  `RoadCaravan.OX_HEIGHT_RATIO` went 0.15 → 0.222 against a rendered,
  pixel-measured frame (84.6%, just above the donkey's 82.7%, because an
  ox is bigger than a donkey). `tests/test_caravan_layout.gd` therefore
  locks all three animals against **measured** drawn shares
  (`DRAWN_BEAST_SHARE`), never `extent()`. The hub's own ox was measured
  in the same pass and was already right (85.5%) - the constant was never
  shared between the two screens, only the mistake.
- **Days are taken one at a time** (`JourneyClock.take_one_day()`). The old
  loop took every completed day at once and dropped the ones it could not
  process behind an open card - and while an encounter marker was pending
  it processed none, so halting in front of a marker was a free wait with
  no provisions eaten. Now the days run; only a *new* event is not drawn
  while one is pending.
- **A decision made the same way every day is a standing order**
  (`GameSession`'s "Kalıcı emirler"). The meal policy is remembered and
  served without asking (`meal_needs_decision()`) - unless provisions run
  short, or the policy would push someone (or the crew) into the night
  where hunger starts costing HP: a standing order never kills anyone
  without the player seeing it first. "Camp at dusk" lights the fire by
  itself in the evening phase only (camp outlasts the evening, so it cannot
  relight the same night, even after a reload). The pre-combat roster and
  order are remembered, with Confirm focused. All three are saved.
- **The road feeds you too, at a price (task Y-B06).** A won fight against wildlife brings `HUNT_PROVISIONS`; a
  farmstead stop opens `evt_village_provisions` (dearer than town per unit, a Charisma haggle as the bait); gathering
  by the road (`evt_forage`) costs a travel day. None of these enter the planner's reserve - the promise is kept by
  the planner's own number, these are extras.
- **The table can offer more than rations (task Y-B07).** Provisions stay the counted ration the planner promises.
  Wine (morale), honey (stress) and fresh fish (stamina) can go on the table, eating one unit per few mouths
  (`GameSession.MEAL_EXTRAS`); they are offered only when the meal panel is open, never by the standing order. Even in
  plenty, every `FEAST_EVENING_INTERVAL` days a feast night opens the table if there is something to offer.
- **A standing order the planner does not know about is a starvation
  trap.** Camping every evening stops the column for `CAMP_HOURS` a day and
  burns `CAMP_PROVISIONS_COST` a night; `forecast_extra_days(...,
  walking_hours)` and `CaravanPlan.camp_provisions` put both into the
  planner's number, and `test_route_terrain.gd` asserts a caravan stocked
  that way still never runs out.
- **Walking beside someone is talking to them (tasks R0, R1 #1, Y-B01).** `RoadCaravan` knows which figure is which
  person (`get_character_of`, `companions_near`). When the leader stays beside a companion for `CHAT_DWELL_SECONDS` of
  real time, `RoadChatter.pick` chooses what they say - top grievance first, then stress, backstory, duty, culture,
  weather and night, then small talk - and `RoadBalloon` shows it over their head (never more than two, none at 1.5x and
  faster; the line always reaches the log). A topic rests `TOPIC_COOLDOWN_DAYS`; `rapport` (0-5) rises at most once a
  day. Every person has a `backstory_id` seeded from their id, so a reload never rerolls it; the first conversation
  says it. No click is needed: walking there is the decision, and it moves the leader into that attention zone.
- **Companions have bonds, moods and stories of their own (tasks R1 #2-#4, Y-C17).** `CompanionLife` keeps bonds
  between people (`GameSession.bonds`, -3..3; same culture starts at +1; surviving a fight together +1, a camp +0.5,
  being passed over for the name -2). Friends (+2) walk closer in the column and ease each other's stress daily;
  rivals (-2) walk apart and chafe. Only a troubled companion (stressed, two grievances, a bad trait) sometimes acts
  on their own - shares their ration, prays, sings, sulks - visible as a balloon and a log line, never deadly. At camp,
  someone whose bond with the leader opens the next chapter may tell their story (`CampStory`, three chapters per
  backstory gated at bond 1/3/5): listening writes a `KIND_STORY` ledger line, and the third chapter, the secret,
  lifts their heaviest grievance. Each backstory carries a personal goal, shown on the character screen once you
  know them.
- **Weather offers small calls; night walking has a price (tasks Y-B05, Y-C20).** Each weather shows one or two
  one-click choices in the orders panel (`WeatherCalls`): start early in clear weather, push before the rain, take
  the muddy shortcut, slow down or light a lamp in fog, shelter from or press through a storm. Each turns an existing
  lever (pace, stamina, stress, a seeded wagon-damage roll, danger); the slower ones are voluntary, so the planner's
  promise does not rest on them. The caravan walks at night as before; in the dark it pays stamina and a little danger
  unless a lantern (one oil a night) or torches (two a night, brighter, keep beasts back) are lit - a glow shows at
  the leader.
- **The road has a director (task Y-B02).** `RoadDirector` bends `EventEngine`'s daily chance and weights - it
  invents no event. Quiet days build tension (the chance rises from the second quiet day, capped); the day after a
  heavy card (combat, a lost wagon, someone left behind) is a relief (heavy cards rarer, the chance a little lower);
  a strained caravan (stress 60+, hunger, overdue debt) draws fewer heavy and more light cards. The director's state
  travels with the engine's save. Evenings and nights raise the signal rate by `NIGHT_SIGNAL_SCALE` unless there is a
  precaution: the camp fire, a watch set at camp, or a lit lantern/torch. `simulate_journeys` reports quiet triples
  and back-to-back heavy cards with the director on and off.
- **Bodies carry wounds and fevers; towns ration medicine (task Y-C05).** `CharacterData.ailments` are timed
  (injuries: broken arm, twisted ankle, deep wound; sicknesses: fever, plague) and bend the same derived getters as
  traits and gear; sicknesses add stress each road day. Someone left at 1 HP by a fight may be injured; hunger raises
  the daily fever chance; arriving in a plague city may infect and drains its medicine. The church's physician cures
  for gold and one unit of the town's medicine stock (`MarketConditions` per town, slow refill); potions the caravan
  sells there go into that stock - the user's note: what we supply changes what they can treat. No stock: locked with
  its reason.
- **The world hardens as the career goes on (task Y-C15).** `career_stage` (0 before `CAREER_MID_JOURNEYS`, 1, then
  2 from `CAREER_LATE_JOURNEYS`) is in the event context, and `EventCatalog.CAREER_THREATS` multiplies ambushes,
  world-crisis news, rival caravans and customs by stage. `simulate_career` counts those cards per stage.
- **Fights pay in kind, and kits are used (tasks Y-C03, Y-C04, Y-F03).** A won fight rolls its kind's table in
  `data/config/loot.json` (`LootTable`, seeded from the fight); the victory screen lists the spoils and the road loads
  them - goods into cargo (or a bag), clothes and gear into the lockers. Events can hand out clothes too
  (`GRANT_OUTFIT`). Bandages and potions carried by the caravan appear as combat actions (a bandage heals and stops
  bleeding, a potion heals and stiffens a Death's Door save) and are struck from the cargo at the end; at camp,
  dressing a wound burns a bandage for double care. Every workshop recipe now has a consumer
  (`RecipeCatalog.OUTPUT_USES`): bandage, canvas repair, a fur hat, fish oil for the lantern, cloth torches.
- **Every key has an on-screen control** (touch parity). The hub walks to
  a tapped point and opens a tapped gate or wagon on arrival;
  `tests/test_touch_parity.gd` scans every screen script for `KEY_*` and
  fails on one without its on-screen counterpart in the same script.
- **The road can be zoomed a little, never out past the frame.** Wheel,
  trackpad/two-finger pinch or the HUD's +/– buttons (touch parity) scale
  `TravelBand` between `ZOOM_MIN` (0.7) and `ZOOM_MAX` (1.6). Zooming out
  used to be impossible because the band's edge would show; the band now
  draws its landscape over whatever the screen sees (`set_view_rect`,
  `cover_rect()`), vignette at the screen's edge, not the band's -
  `test_ui_feel.gd` asserts the scaled band covers the frame,
  eased per frame. The pivot is the leader's head on the ground line
  (`RoadCaravan.get_ground_y()`), so the eye stays on the caravan and the
  ground never slides; `_world.clip_contents` keeps the scaled band under
  the HUD. Tap-to-walk needs nothing new - it already reads the
  caravan's canvas transform, which carries the scale. A pinch is checked
  before a tap, so two fingers never walk the leader.
- **Distance is measured in game hours, not frames.** The speed button
  scales the clock and the road by the same factor; driving movement off
  the raw frame delta would make days outrun the road at 3x and starve
  every fast-forwarding caravan.
- **`journey_days_remaining` is now derived, not counted.**
  `_sync_days_remaining()` computes it from the distance covered, so the
  HUD, the divert cost (`get_days_travelled`) and the arrival check all
  read one number. Arrival fires on distance, not on a day counter.
- **Therefore every event effect goes through `_apply_effects()`.**
  `EventEffect.Type.TRAVEL_DAYS` writes to `journey_days_remaining`, which
  the next frame would overwrite; the wrapper catches the delta and adds it
  to the route's *length* instead. So "the road got longer" means the
  caravan must actually walk the extra distance.
- **Events are never drawn by the player.** The "Olay Çek" button is gone
  from every mode. A card the player summons is a debug tool, not a road.
- **Dev controls do not ship in a live journey.** The seed box and reset
  button are hidden unless the journey is the F1 synthetic one.

**A dev default silently shipped as game behaviour.** The event engine was
seeded from the dev seed box (`1234`) on *every* live journey, so every
real road drew the same event sequence in the same order. A live journey
now seeds from origin + destination + `total_days_elapsed`: reproducible
within a save (the mid-journey autosave stores the engine's RNG *state*,
not its seed - see `EventEngine.to_dict()` - so reloading replays the same
dice and opens no re-roll door), different for every new journey. Check what a debug control feeds
before assuming it only affects debug.

### Journey Time Rules

The road used to advance one day per button press. It now runs on a
continuously flowing clock (`JourneyClock`, `scripts/travel/`), while the
day *mechanics* are unchanged.

- **The clock counts days; it does not replace them.** Provisions, contract
  deadlines and the event roll still happen once per day. `take_elapsed_days()`
  answers "how many whole days completed since I last asked" and the road
  screen runs the existing per-day logic that many times. It returns a count,
  not a bool: at 3x speed, or after a long event, more than one day can
  complete in a single frame. A day must never be processed twice and never
  skipped - both are locked by `tests/test_journey_clock.gd`.
- **The day rolls over at dawn (`START_HOUR`), not midnight.** With a
  midnight boundary every daily event fired at 00:00, so the player never
  saw one in daylight. Events now land around 07:30.
- **Events consume time.** Resolving a card, a fight, a haggle or a road
  recruit each spend hours (`consume_hours`), so the background moves while
  the caravan is stopped - that is the "events eat time" rule.
- **Time stops for decisions.** `_can_time_flow()` is false while an event
  card is open or a side-channel panel (combat/haggle/recruit) is up.
- **Camping is a state, not an instant.** Pressing camp lights the fire and
  lets time keep flowing until `CAMP_HOURS` pass; the benefit (provisions
  cost, stress relief) is applied when it ends. It is only offered when
  `is_camp_time()` - evening or night.
- **There is no fast-forward any more (task Y-B09, the user's decision).** `JourneyClock.SPEEDS` is `[0.5, 1.0]`:
  the road should be full enough that nobody wants to hurry it. `tests/simulate_road_beats.gd` measures decision and
  information beats per real minute at 1x (target: one every 60-90 s; a game day is `REAL_SECONDS_PER_DAY` = 45 s).
  Slowing down and the "Dur" pace stay. Bullets below that mention 1.5x/3x describe the code paths that still scale
  with the clock speed; they are kept because the multiplier itself remains.
- **The clock's own speed is one of its levers, and camp reaches for it.**
  `JourneyClock.SPEEDS` gained `0.5` - eight in-game hours at 1x is minutes
  of real time nobody wants to sit through *and* too fast to read the
  scene it exists to show. `_on_camp_pressed()` sets the speed to
  `camp_speed_index()` (found by value, not a hardcoded slot, so
  reordering `SPEEDS` can't silently break it) the moment camp is made -
  a default, not a lock, so the player can still push it back up.
- `TravelBand` (`scripts/ui/`) owns the landscape visuals: sky/ground
  colors interpolate toward the *next* phase using `get_phase_progress()`
  so the scene never snaps, and the world scrolls under a stationary
  caravan (moving the caravan would just hit the edge of the band).
  `_camping` still tints the light warm here, but the fire itself moved to
  `RoadCaravan` - see Road Layer Rules for why and what changed with it.

### Road Encounter Rules

A day's event used to become a card the instant the day rolled over - no
warning, and combat opened as a panel appended *below* the road view rather
than replacing it, so a fight read as a log entry, not a scene.

- **Combat happens where the road was, not underneath it.** `road_journey.gd`
  wraps `TravelBand` and `_combat_holder` in one `scene_stage`; `_open_combat()`
  hides the band and shows the holder, `_on_combat_finished()` reverses it.
  `CombatPanel` was already a real drawn battlefield (bkz. Combat Rules) - the
  fix is spatial, not visual: the same screen area shows the fight instead of
  the road, rather than a second block stacking under the walk hint, the
  conditions line and the state dump.
- **An event with a physical stand-in appears on the road before its card
  does.** `EVENT_ROAD_MARKER_KIND` maps an `event_id` to a `CombatFigure`
  archetype category (wildlife/bandit/guard/traveler) - deliberately only the
  events that *have* something to be seen (a wolf, a patrol demanding papers,
  a wanderer). An event with no physical presence (your own wagon breaking,
  weather, a party-internal matter) is not in the map and still opens
  instantly, which is correct, not a gap: there is nothing to place on the
  road for "the axle snapped."
- **The marker reuses combat's own figures, not a new drawing.** `RoadEncounter`
  hosts a bare `CombatFigure` - the same wolf/guard/bandit silhouette the
  player already meets in the fight itself, same reasoning as `WalkFigure`
  reading `CombatFigure.ARCHETYPES` for the party's own walk cycle ("the
  guard you saw in the fight walks the road in the same colours"). Building
  it in `_init()` rather than `_ready()` matters here specifically:
  `road_journey.gd` calls `setup()` before the node ever enters the tree
  (before `add_actor_layer()`), and `_ready()` would still be unset at
  that point - `_figure` would be `null` and `setup()` would fail every
  single time, not silently.
- **The day still rolls, the card just waits.** `_run_day()` rolls the event
  exactly as before and, for a mapped kind, stores it as `_pending_event`
  instead of presenting it immediately, placing the marker
  `ENCOUNTER_APPROACH_DAYS` ahead of the caravan's current position (in the
  same day-units `_days_covered` already uses). `_walk_at()` checks on every
  step whether the caravan has closed that gap; only then does
  `_present_event()` run. Walking away from the marker never triggers it -
  approaching is the whole point, and the same check on the next step of
  approach catches it again if the player turns back.
- **A pending marker freezes the calendar the same way an open card does.**
  `_process_elapsed_days()` and `_check_journey_end()` already skip forward
  while `_current_event != null`; `_pending_event != null` joins that same
  guard, or a second day's provisions/contracts would process - or the
  journey could even "arrive" - while the first day's wolf is still standing
  unresolved on the road. Time itself (`_can_time_flow()`) is *not* gated by
  it: the whole point is that the caravan keeps walking and the world keeps
  turning while the marker is approached.
- **A replan discards whatever was pending.** `_apply_replan()` (turning
  back or diverting) resets `_days_covered` to the new leg's zero - a marker
  positioned on the abandoned road would otherwise sit at a day-position
  that means nothing on the new one. Turning back is now also an honest way
  to avoid a wolf you can see coming.
- **`TravelBand.screen_position_for_day()`** is the one door a marker (or
  anything else that needs to sit at a fixed point along the route) reads to
  convert a day-position into screen space - the exact formula
  `_draw_stops()` already used inline for roadside stops, now public so it
  is not duplicated a third time.
- `tests/screenshot_road_encounter.gd` renders each marker kind and the
  combat stage once (bkz. Testing) - not a test, a picture, same reasoning
  as every other `screenshot_*.gd` tool: a structural pass cannot see that a
  figure is actually standing on the road.

### Road Screen Layout Rules

The road screen was a **scrolling column of text** for a long time: the
landscape band was one row of it, the event card another, the state dump
and the log filled the rest. The complaint - *"the game still looks like a
text-based RPG"* - was about the layout, not the art: the world was a small
box inside the text, so the text was the screen.

- **The world is the screen, and the HUD is its edge** (Kingdom Two Crowns
  layout). `road_journey.tscn` is four stacked full-rect layers - `World`,
  `Hud`, `LogOverlay`, `Modal` - and the landscape fills the first one
  completely. The HUD is two thin bars (time/state on top, walk hint, last
  log line and actions at the bottom) with the world visible between them.
- **A layer is a container, not an anchor preset.** `World` and
  `LogOverlay` are `MarginContainer`s and `Hud` is a `VBoxContainer`, all
  anchored *in the scene file*. That sidesteps the anchor-preset trap (see
  Art Rules) by construction: a container sizes its children, so nothing
  depends on a resize notification that may never arrive.
- **Decisions are one card in the middle of the screen** (EU4 layout). The
  event card, the haggle panel, the road recruit offer, the replan panel
  and the arrival summary all open inside the single framed card in
  `Modal/Center`, over a dimmed backdrop. Choices are **buttons inside the
  card**, styled explicitly (`_style_choice_button`) - the default theme box
  vanishes on the card's dark ground and the options read as plain text
  lines rather than something to click.
- **The card's visibility is read from its content, every frame**
  (`_refresh_modal`). Seven call sites fill and clear those holders; asking
  each of them to also toggle the layer means one of them eventually
  forgets and leaves the screen dimmed behind an empty card. An empty
  `VBoxContainer` still contributes separation, so empty holders are hidden
  too, or the card grows a visible gap under the choices.
- **The log is one line plus a button, never the whole ledger.** The bottom
  bar shows the last entry; `LogOverlay` holds the full list in a
  `ScrollContainer` with its close button outside it (same rule as every
  other screen). What a player needs while walking is what just happened,
  not the transcript.
- **A multi-line translation becomes one line in a bar.** The road
  state used to be one three-line key (`UI_ROAD_STATE`, deleted in task 3.5 when the HUD moved to `SurvivalGauge`); the
  rule stands: a bar joins lines at display time instead of splitting the key.
- `tests/screenshot_journey_screen.gd` photographs **the real scene** with a
  live session, not a hand-built band - the other screenshot tools show the
  landscape but cannot show the layout, and the layout was the complaint.
- **The thin HUD is deliberate, but the caravan's detail lives in the control panel.** A playtest asked for *"a
  detailed 'My Caravan Status' tab"*, then *"status, map, inventory, contracts"* buttons. The answer is the control
  panel below (next bullet): the bottom bar's "Durum" and `Tab` open its Durum tab (`Tab` again goes back to Kadro),
  contracts sit in Yük, the ledger in Defter. The old `CaravanStatusPanel` overlay (`StatusOverlay`) duplicated all of
  it and was removed (task N23). Panels that only read **never decide anything**, the `CityBriefPanel` rule.
- **The sky strip gave its height to a control panel (P18).** The road's top fifth was empty sky; `road_journey.gd`
  shifts `World` up by `SKY_CROP_SHARE` and `RoadControlPanel` fills the freed bottom (`CONTROL_PANEL_SHARE`) with five
  tabs - Kadro (person cards plus the caravan's pulse: morale, stamina, danger, provisions), Durum (the `SurvivalGauge`
  plate, the facts and the troubles in words), Yük, Harita (a small `WorldMapView`), Defter. It reads a state dictionary
  the road hands it (`_panel_state()`) and never decides anything. A `ScrollContainer`
  page stretches its child only when the child is `SIZE_EXPAND_FILL`; without it every autowrapped goods label shrank to
  one word per line (seen in the first screenshot, `RoadControlPanel._fill`). `M` or the bottom bar's "Harita" opens the
  full map (`MapPopup`), counted as an open panel so time stops.

### Encounter Timing Rules

- **An encounter begins when it touches the caravan's nose.** The trigger
  used to compare the marker against the band's anchor, but the anchor sits
  *behind* the leader (`RoadCaravan.get_front_offset()` is how far the front
  actually reaches), so the official walked past the player and the card
  only opened once he drew level with a wagon. The player was talking to
  someone he had already overtaken.
- **Arrival is checked where distance changes, not where days change.**
  `_walk_at()` calls `_check_journey_end()` directly. Before that, arrival
  was only tested when a day rolled over, so a caravan that closed the last
  stretch early hit a wall it could not cross and nothing happened until the
  calendar caught up - the "invisible wall" the road ended in.
