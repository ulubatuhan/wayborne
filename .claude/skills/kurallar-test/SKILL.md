---
name: kurallar-test
description: Wayborne kural kitabının "Testler, simülatörler, ekran görüntüsü araçları ve ölçüm" bölümü (CLAUDE.md'den taşındı). Şunlara dokunmadan, şunları tasarlamadan ya da şunlar hakkında karar vermeden önce yükle: tests/ altında test ya da simülatör yazmak, run_tests.gd, simulate_journeys, simulate_career, screenshot_*.gd, denge ölçümü, CI kapısı. Bozulmaması gerekenleri ve nedenlerini tutar.
---

# Testler, simülatörler, ekran görüntüsü araçları ve ölçüm

CLAUDE.md'nin bu bölümleri 2026-10-30'da kullanıcı kararıyla buraya taşındı; metin değişmedi, başlıklar aynı. Koddaki
"bkz. CLAUDE.md <başlık>" başvuruları buraya bakar. Kural becerilerinin listesi CLAUDE.md'de ("Kural becerileri").
Bölümler: Testing.

### Testing

Tests run headless with no addon - a plain GDScript `SceneTree` runner:

```bash
godot --headless --script res://tests/run_tests.gd      # exit 1 on failure
godot --headless --script res://tests/simulate_journeys.gd   # balance report
godot --headless --script res://tests/simulate_career.gd     # career arc report
```

- **No `class_name` in `tests/`.** Test scripts would otherwise land in the
  global class cache and ship with the game. `run_tests.gd` reaches suites with
  runtime `load()` for the same reason it avoids `class_name` itself: the
  autoload parse-order trap.
- A suite is a `RefCounted` script with `suite_name() -> String` and
  `run(t) -> void`; `t` is `tests/test_reporter.gd`. Register it in
  `run_tests.gd`'s `SUITE_PATHS`.
- Test the UI-free cores, which is why they were written UI-free:
  `CharacterStats`, `CombatEncounter`, `EventEngine`, `EventEffectApplier`,
  `GameSession`, `HagglingSession`. Never test engine internals or scene
  wiring.
- `test_memory.gd` (Faz 18) locks the save's integrity - atomic writes with
  a backup, no recruit cloned by a reload, market stock not refilled by one,
  every `GameSession` script variable either saved or on a commented
  transient list - plus character ids, ledger causes/places, the founder
  line, grievances, starvation deaths (and that a fed caravan never counts a
  hungry day), the chosen heir, named crew dying with their wagon,
  profiteering memory, `LEAVE_BEHIND`/`PARTY_HP`, the stop cards, the
  that a loss cannot be bought, `EventResolver`, `JourneyController`, and a
  mid-journey save round trip that replays **the same dice** after a reload.
- `test_motion.gd`, `test_combat_fx.gd` and `test_ui_feel.gd` (Faz 20) lock
  the motion layer's contracts rather than its look: every curve starts and
  ends at rest, a stop is a settle not a snap, wind only blows in bad
  weather, the engine emits the status moments, a live combat slot returns
  to neutral on its own, numbers are the real HP difference, a fall holds
  Continue, hover growth stays a few pixels on a wide row, and "near miss"
  means one numeric requirement just short (see Motion Rules).
- `test_route_terrain.gd` locks the road's geography and weather: both
  reproducible from a seed, segments covering the whole route with no gaps,
  biomes never jumping, stops never landing on the destination city, clear
  weather exactly neutral, every lever inside its range, the biome bias
  actually biasing (the overwhelming-margin pattern again), the visuals
  agreeing with the mechanics (the slowest weather is also the dimmest), and
  - the suite's most important claim - the provision promise surviving
  weather.
- `test_route_conditions.gd` locks the two properties the route layer would
  be dangerous without: natural states are reproducible (a save reload
  cannot re-roll a closed pass open) and no city is ever sealed off - the
  latter is a 300-day sweep over every city, and it caught a real lock-up
  on three days before the last-exit rule existed.
- **Where a system can be exploited, assert the exploit is closed rather
  than asserting the formula.** `test_haggling.gd` does not check that a
  particular offer yields a particular price - it exhaustively searches the
  offer range for the best price patient play can reach, and asserts that
  enraging the merchant lands strictly worse. A formula assertion would have
  passed happily on the old, broken design.
- `test_progression.gd` locks the XP curve, diminishing-returns stat math,
  auto-allocate and the multiclass unlock; `test_duties.gd` locks
  `DutyCatalog.get_duty_power()`'s class-match multipliers and the discount/
  flat-reduction formulas `GameSession` derives from it; `test_save_migration.gd`
  loads a save dict shaped like it predates a given field and asserts sane
  defaults - a reminder that every new `CharacterData`/`GameSession` field
  needs a `.get(key, default)` in `from_dict()`/`load_from_dict()`, never a
  bare index; `test_recruit_catalog.gd` locks the per-venue level spread and
  that granted levels actually get auto-spent; `test_traits.gd` locks the
  catalog shape, the fresh-window boundary and that `CharacterData`'s
  derived getters actually include trait bonuses - a statistically
  overwhelming-margin check (not an exact roll) on `roll_seed_trait`'s lean,
  same reasoning as `test_event_engine.gd`'s seed-reproducibility test;
  `test_stress.gd` locks stress clamping, resistance-scales-with-Dayanıklılık,
  `resolve_stress_breaks()` (polarity, the player never departing, calm
  parties never breaking), `make_camp()`, the `STRESS` effect, and - same
  overwhelming-margin pattern again - that a stressed `CombatUnit` sometimes
  refuses orders while a calm one deterministically never does.
- **`tests/screenshot_*.gd` are the visual checks, and they are not tests** -
  they never fail, they render PNGs (`screenshot_combat`, `screenshot_road`,
  `screenshot_city`, `screenshot_hub`, `screenshot_journey_screen`,
  `screenshot_road_encounter`, `screenshot_waybook` (ledger, succession,
  the closed book), `screenshot_screens` (every management screen with a
  live session; takes an optional `-- width height`, as does
  `screenshot_journey_screen`), `screenshot_menu` (the main menu was the
  only screen never drawn at all, four buttons on flat grey, and no
  assertion anywhere could say so), `screenshot_mannequin_walk` (one figure
  across eight gait phases, one row per body folder given as an argument —
  a body's defects are joints that open and girdles that swing, and a still
  frame shows neither)). They
  exist because a structural test
  verifies *layout* and never *appearance*, and this repository ships
  headless: an interface change went unseen for a long time. Run them with a
  virtual screen and the software rasteriser, since the environment has no
  Vulkan:

  ```bash
  godot --headless --import
  LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
    godot --path . --rendering-driver opengl3 --script res://tests/screenshot_road.gd
  ```

  Between them they have found: figures walking on top of trees, a rider
  floating twenty pixels above his horse, a headless ox, wagons overlapping
  each other, an ox inside the wagon in front, an invisible caravan
  (the anchor trap), a road indistinguishable from the ground it lay on, a
  vignette that drew vertical bars instead of a soft edge, a snow cap that
  painted the whole mountain white, a lake five-sixths hidden under the
  ground, and an empty strip below the road. **Not one of those is visible
  to any assertion in the suite.**
- **A screenshot tool can measure the wrong thing too.** The road tool's
  "forest" frame contained no forest: it checked the biome at day zero and
  then moved the camera to day 2.1, which had long since crossed into
  another segment. Fourth measurement bug in this file's history - suspect
  the harness before the game, including the harness you just wrote.
- **A screenshot tool must reproduce the game's own frame, or it is
  photographing a different game.** The road tool rendered a 1500×460 band
  where the game's is 1920×`BAND_HEIGHT` (320). Figures scale with the
  band's *height*, so the caravan came out 1.44× larger against the same
  width and the column ran off the left edge — **the tool had never once
  shown a wagon on the road**, and nobody noticed because the frames were
  full of landscape. It also called `add_child` instead of
  `add_actor_layer`, so it did not even reproduce the depth order the
  band's single door exists to guarantee. Fifth measurement bug here, and
  the first one where the harness hid a real defect in the game rather
  than inventing a fake one. The tool now sweeps wagon counts 1/4/6 as
  its own frames, and `tests/test_caravan_layout.gd` asserts the
  arithmetic that the picture only illustrates.
- **An assertion that switches itself off protects nothing.** The first
  draft of the caravan guard only checked "every wagon is on screen" when
  the column had *not* been scaled to its floor — so the mutation that
  pinned the anchor back to its old constant drove the scale to the floor,
  turned the assertion off, and passed. Same shape as the stun-resist
  assertion that measured itself against the constant it guarded. Both
  mutations fail now (15 and 12 assertions).
- Seed every RNG. A test that can flake is worse than no test.
- **Do not derive two independent things from the same seed.** The simulator
  picked the player's culture with `seed_value % 5` and seeded the event
  engine with the same `seed_value`, so culture and event draw were
  correlated: the report showed one culture event firing 24 times and
  another 2, with identical weights and conditions. Decorrelating the two
  reversed the ordering entirely - the "culture events are nearly
  invisible" finding was an artifact of the harness, not the catalog. This
  is the third measurement bug in this file's history (morale read after
  `finish_journey()`, provisions measured against a flat stock, culture
  coupled to the draw): **when a report is surprising, suspect the harness
  before the game.**
- `simulate_journeys.gd` is **not** a test - it never fails, it prints a
  distribution (net payout, morale, starvation rate, combat win rate by party
  size). It is the only honest way to tune balance without playing. Faz 8
  PR-A widened it past what it originally measured: the simulated player now
  rotates culture and a duty assignment across runs and occasionally equips
  gear, instead of always being the same unmodified default character - a
  fixed default silently never exercised any of Faz 6-7's culture-gated
  events, duty math, or equipment bonuses. Added reports: event-fire
  frequency across the full catalog (flags any event that never fires),
  and an equipped-vs-bare win-rate A/B (run at a party size below the
  existing win-rate ceiling, or the comparison shows no signal). This is
  how `GameSession.get_duty_flat_reduction()`'s missing floor was
  found - `get_duty_discount()` already clamped at 0.0 but its sibling
  didn't, so a duty holder whose culture leans negative on the relevant
  stat (e.g. Göçebe's INTELLECT -1 for Levazımcı) produced a worse result
  than leaving the duty unassigned, breaking the "a duty with no holder is
  never a penalty" rule for the *held*-but-mismatched case too.
- **`simulate_career.gd` is its long-arc sibling, and the two answer
  different questions.** `simulate_journeys.gd` runs one synthetic journey
  many times: is a journey profitable, is combat winnable, does morale move.
  `simulate_career.gd` runs one caravan's *life* through the real city loop
  — market, contract board, caravan yard — for forty journeys, and reports
  where gold, reputation, wagons and contracts land. Anything about
  progression over time needs the second tool; the first cannot see it.
- **A balance report needs more than one policy, for the same reason ruin
  tuning needed two knobs.** `simulate_career.gd` runs three — expand
  aggressively, stay lean and haul contracts, and stay lean for ten journeys
  before expanding — and
  the first two disagree so sharply (11 contracts delivered vs 41) that
  either one alone would have given a confidently wrong answer.

**Measurement runs in CI; the player is measured only with consent (task Y-K03).** `simulate_career.gd` prints one
`OLCUM {json}` line per policy (days and 1x real minutes per journey, cards and deaths per journey);
`tools/measure_report.py` turns it into a table, and `.github/workflows/olcum.yml` (manual and weekly) puts it in the job
summary. The game writes `playtest_times.json` and `playtest_beats.jsonl` only when Settings' play-measurement box is on
(`UserSettings.allow_play_log`, default off, `GameState.set_play_log`); a `session` beat opens each session so the report
can give session lengths. First report: `docs/olcum/OLCUM_2026-10-20.md`.

**A task is done when the screen shows it (görev Y-K01).** Work runs in two-week cycles; each cycle ends with a playable
build and a five-minute video of it. "Done" is said only after a screenshot of the real screen confirms it - a passing
test is not enough for anything the player sees, because the structural tests below never see appearance (see the
screenshot tools in this section). A claim of "fixed" that was never checked against the place the report pointed at has
been wrong twice in this file's history.

**The five showcase images are the game's own screens (task Y-G13).** `tests/screenshot_showcase.gd` builds the night
map with the lantern rider, the campfire panorama, the event card, the succession with its cracked seal and the
arrival at a gate from the real scenes (the road frames hide the HUD and give the sky back; the card keeps it) and
writes `docs/steam/vitrin/*.jpg`. No separate marketing painting: a store image that shows something the game does not
draw is a promise the game breaks. Shooting them found two real defects (people standing on the camp fire, the
map rider without a light), fixed in the game, not in the picture.

**CI is the real gate.** Godot prints parse errors and still exits `0`, so a
broken script hid under a green build twice (`city_map.gd`,
`ClassCatalog.get_class`). `.github/workflows/deploy.yml` now tees every Godot
invocation to a log and fails the job on `SCRIPT ERROR`, `Parse Error`,
`Compile Error`, `Failed to load script` or `Failed to create an autoload`.
Never remove that step to make a build pass.
