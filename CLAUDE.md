# Wayborne - Godot 4 Project Guide

## Stack

- **Engine**: Godot 4.2+
- **Language**: GDScript
- **Target**: Desktop/Web

## Folder Structure

```
wayborne/
├── project.godot           # Godot project configuration
├── CLAUDE.md              # This file
├── scenes/                # Game scenes (*.tscn files)
├── scripts/
│   ├── campaign/          # Story spine: chapters and their objectives
│   ├── economy/           # Economy & trade system scripts
│   ├── travel/            # Map, routes & caravan logistics scripts
│   ├── events/            # Event & dialogue system scripts
│   ├── character/         # Cultures, stats, classes & recruits
│   ├── combat/            # Combat & AI scripts
│   ├── world/             # Explorable 2D spaces & scene navigation
│   ├── ui/                # UI components & screens
│   └── autoload/          # Global singleton scripts
├── data/
│   ├── config/            # JSON/YAML configuration files
│   ├── locale/            # Translation CSV (keys, tr, en)
│   └── assets/            # Game assets (sprites, sounds, fonts)
└── tests/                 # Headless GDScript tests + balance simulator
```

### Folder Descriptions

- **scenes/**: Store all `.tscn` files here, organized by functionality
  - Use descriptive names: `main_menu.tscn`, `gameplay_hud.tscn`
  - Keep subscenes in subfolders for complex scenes

- **scripts/economy/**: Game economy logic
  - Trading systems
  - Currency management
  - Resource calculations

- **scripts/travel/**: Map & caravan logistics
  - Locations, routes and world map data
  - Caravan composition (wagon limits, documents, provisions)
  - Travel context shared between map and planner screens

- **scripts/events/**: Event & narrative systems
  - EU4-style road event cards: `GameEvent` → `EventChoice` → `EventOutcome`
  - `EventCondition` (triggers) and `EventWeightModifier` (MTTH-style weighting)
  - `EventEffect` is the *only* vocabulary an event may use to touch the world;
    `EventEffectApplier` applies it and enforces the never-total-loss clamps
  - `EventEngine`: eligibility filter, weighted draw, once/cooldown tracking,
    seedable RNG for reproducible runs

### Event Engine Rules

- Road events only. City interaction is deliberately **not** card-based.
- A caravan can be ruined but never wiped out - see **Caravan Ruin Rules**
  below for exactly how far "ruined" goes. The clamps live in
  `EventEffectApplier`/`CaravanState`, never in individual events.
- Locked choices are shown disabled *with their reason*, not hidden, so the
  player learns what to prepare for next time.
- **A choice that opens combat says so before it's picked, not after.**
  `road_journey.gd`'s `_choice_triggers_combat()` scans a choice's
  `effects` for `TRIGGER_COMBAT` and appends the road's current effective
  danger (`_weathered_danger()` - the same number the HUD's danger bar
  already shows) straight onto the button. A steep win-rate gap between
  road-danger tiers is a real difficulty curve, not a bug, but a fight the
  player couldn't see coming *is* a legibility bug - the fix is telling the
  player what they're gambling on, not softening the odds.
- All player-facing event text lives in `data/locale/wayborne_text.csv` as
  translation keys; scripts call `tr(key)`. Never hardcode event prose.
- New effects must be added to the `EventEffect.Type` enum **and** handled in
  `EventEffectApplier`, otherwise they silently do nothing.

- **scripts/character/**: Who the people in the caravan are
  - `CharacterStats`: the six base stats (Güç/Çeviklik/Dayanıklılık/Zeka/
    Sezgi/Karizma) plus every derived value (max HP, initiative, accuracy,
    dodge, crit, damage bonus). Derived formulas live **only** here - the
    character screen and the combat engine both read them from this class.
    Stats run 1-15 but only the first 10 points count at full value -
    `get_effective_value()` returns `min(stat,10)-5 + 0.5*max(0,stat-10)`,
    zero at the starting value of 5. Every derived formula is written as
    `baseline + coefficient * effective_value(stat)`, so a fresh character
    (all stats at 5) behaves exactly as before this system existed; only
    pushing a stat past 10 (via level-ups) triggers the slowdown, on purpose
    - a maxed stat should never dominate the game.
  - `Culture` / `CultureCatalog`: the five cultures (göçebe, vadi loncaları,
    dağ kabilesi, liman şehri, balıkçı kasabası). Each carries a stat lean, a
    name pool and exactly **one** mechanical perk, and every perk plugs into
    a system that already exists (daily provisions, provision price, market
    buy price, combat damage, rumor price). No perk may invent a new system.
  - `CharacterClass` / `ClassCatalog`: combat role. `class_name` is a
    reserved word, so the visible name lives in `display_name`. Four classes
    (Sıra Neferi/Sekban/Kırıkçı/Kalem Efendisi), each with a `stat_affinity`
    (used by auto-allocate) and a `duty_id` - its "ana" kervan görevi, which
    `DutyCatalog.get_duty_power()` rewards when a character actually holds
    that duty.
  - `Duty` / `DutyCatalog`: the six road/city jobs (Muhafız/İzci/Levazımcı/
    Arabacı/Tellal/Otacı), separate from combat class. `GameSession.assign_duty()`
    gives a duty to one party member at a time; `get_duty_multiplier()` /
    `get_duty_discount()` / `get_duty_flat_reduction()` turn that into the
    concrete number a system reads (buy price, repair cost, daily
    consumption, wagon damage, combat opening accuracy, camp stress relief).
    All six are wired to a live system - İzci (travel-day reduction in
    `caravan_planner.gd`, free danger reveal in `world_map.gd`, both via
    `get_duty_flat_reduction`/`get_duty_holder`) was the last, added in
    Faz 7 PR-C. A duty
    with no holder is neutral (multiplier 1.0), never a penalty.
  - `CharacterData`: identity + appearance (boy/ten rengi) + stats + class +
    current HP + level/XP/yetkinlik/second_class_id/duty_id, with
    `to_dict()`/`from_dict()`. Height is not flavour: tall means more HP and
    less dodge, short the reverse. `gain_xp()` levels up (curve: see
    `xp_required_for_level`), granting 1 stat point + 2 yetkinlik points per
    level; `auto_allocate` (default on, companions keep it on, the player can
    turn it off) spends those immediately toward the class's `stat_affinity`
    and its own skills. Multiclass (`set_second_class`) unlocks at
    `MULTICLASS_UNLOCK_LEVEL` (7) and merges both classes' skill lists.
  - `RecruitCatalog`: per-venue candidate pools (meydan cheap/green, taverna
    balanced, lonca expensive and reputation-gated). Candidates are rolled
    **once per city arrival** from a `location + day` seed, so reopening the
    screen cannot reroll them. Each candidate also gets a random class and a
    level scaled off the player's own (`get_venue_level_spread` - meydan
    always below the player, lonca always at or above), granted as real XP
    so `auto_allocate` spends it the same way a levelling companion would.
  - `Trait` / `TraitCatalog`: twelve Darkest-Dungeon-style huy, one virtue
    and one affliction per stat, each a small permanent modifier
    (`hp_bonus`/`dodge_bonus`/`accuracy_bonus`/`crit_bonus`/`damage_bonus`)
    read by `CharacterData.get_max_hp()/get_dodge()/get_accuracy()/
    get_crit_chance()/get_damage_bonus()` alongside the class/height bonus -
    **combat must read these `CharacterData` wrappers, never
    `character.stats.get_X()` directly**, or trait bonuses silently don't
    apply (bkz. `CombatUnit.from_character`). A character carries at most
    `CharacterData.MAX_TRAITS` (3). Seed traits are rolled by
    `TraitCatalog.roll_seed_trait(stats, rng)` - weighted by how far each
    stat sits from baseline, so a lopsided character leans toward matching
    huy without a hard guarantee - and granted explicitly by the two real
    creation flows (`character_creation.gd`, `RecruitCatalog`) with their
    own seeded RNG; `CharacterData.create()` itself never rolls one, so
    every existing test that calls `create()` stays deterministic. Later
    huys come from `EventEffect.Type.GRANT_TRAIT` (always targets the
    player character - bkz. `evt_troubled_night`). Only a "taze" huy -
    granted within `CharacterData.TRAIT_FRESH_WINDOW_DAYS` (5) days of
    `GameSession.total_days_elapsed` - can be removed, at the Tavern or the
    Church (`PurificationPanel`, shared by both, priced differently).
  - `Equipment` / `EquipmentCatalog`: four slots (`SLOT_WEAPON`/`SLOT_ARMOR`/
    `SLOT_RING`/`SLOT_AMULET`), twelve pieces total - Weapon/Armor are three
    permanent tiers each (positive bonus only, bought with gold at the
    Caravan Yard's "Demirci" section), Ring/Amulet are DD-trinket-style
    finds (one stat up, another down, `price` 0 - never sold, only granted
    by `EventEffect.Type.GRANT_EQUIPMENT`). Bonus fields
    (`hp_bonus`/`dodge_bonus`/`accuracy_bonus`/`crit_bonus`/`damage_bonus`)
    are named identically to `Trait`'s and read by the exact same
    `CharacterData` derived getters (`_equipment_bonus_sum` sits alongside
    `_trait_bonus_sum`), so combat sees equipped gear automatically through
    `CombatUnit.from_character` - same wrapper rule as traits. A piece is
    never handed straight to a character: it always lands in
    `GameSession.equipment_inventory` (id -> count, the equipment
    counterpart of `Inventory`'s item_id -> quantity) first, and
    `GameSession.equip_to_character()`/`unequip_from_character()` is the
    only path that moves a piece between that shared locker and a
    character's `equipped` dict - upgrading a slot automatically returns
    the old piece to the locker.

### Character & Party Rules

- **Crew size ≠ combat party.** Crew (chosen in character creation) drives the
  wagons and sets cargo capacity, up to 12 people / 6 wagons. The combat party
  is the named characters and only they fight. Never conflate the two.
- **Party capacity comes from wagons.** `GameSession.get_party_capacity()` is
  `owned_wagon_count * PEOPLE_PER_WAGON`, capped at `MAX_PARTY_SIZE` (4)
  because the battlefield has four ranks. So buying a wagon at the caravan
  yard also buys a party slot; never gate recruiting on `MAX_PARTY_SIZE`
  directly. Events read `party_slots_free` from the context dict, since
  `EventCondition` can only compare a key against a constant.
- The player starts alone. Companions are recruited in the city (`RecruitPanel`)
  or on the road (`evt_road_wanderer`), and every one of them is drawn walking
  behind the leader in `world_hub.gd` — height and skin tone included, so what
  character creation chose is visible in the world.
- **The player is identified by `CharacterData.is_player`, never by index.**
  Party order is combat rank order, so the player can move to the back; a guard
  that tested `index == 0` let them dismiss themselves, kept a companion
  undismissable, and handed the companion's culture perk to the whole caravan.
  `get_player_character()` and `dismiss()` read the flag.
- Party order **is** combat rank order (1 = front). `party.tscn` is where the
  player reads and reorders it (reachable from the road HUD and the city map).
- Characters heal to full on city arrival (`finish_journey()`); the road is
  where damage accumulates.

- **scripts/combat/**: Darkest Dungeon style turn-based combat
  - `CombatSkill` / `SkillCatalog`: position-gated skills. Every skill carries
    both `usable_positions` (where the user must stand) and `target_positions`
    (what it can reach). Numbers live in the catalog, never in the UI.
  - `EnemyTemplate` / `EnemyCatalog`: enemy stats plus three squad builders -
    `build_bandit_squad()`, `build_wildlife_squad()` (kurt/ayı/domuz, bkz.
    `evt_wild_animal`), `build_guard_squad()` (şehir muhafızı/çavuşu, bkz.
    `evt_guard_patrol`) - each scales with the road's danger **and** with
    party size, so a lone traveller never faces four bandits. `build_squad(
    enemy_kind, region_id, ...)` is the single dispatcher `combat_panel.gd`
    calls; `enemy_kind` ("bandit"/"wildlife"/"guard") comes from
    `EventEffect.Type.TRIGGER_COMBAT`'s `text_value` (empty = "bandit", so
    every pre-Faz-8 event definition keeps working unchanged) via
    `EventEffectApplier.Result.combat_kinds`. `build_bandit_squad()` also
    takes `region_id` (the journey's destination `location_id`) and reskins
    the melee/ranged bandit for two regions - Kurtboğazı gets heavier Dağ
    Haydutu, Demirkapı gets sharper Silahlı Eşkıya - same squad shape,
    different yöre teçhizatı. Winning against guards costs reputation
    instead of granting it (bkz. `road_journey.gd`'s
    `GUARD_VICTORY_REPUTATION`) - beating up the law isn't the same as
    beating bandits, even in victory. **Player-facing combat text reads
    `EnemyCatalog.get_kind_label(kind)`, never a hardcoded noun**:
    `CombatEncounter.enemy_label` (passed in by `CombatPanel`) is what the
    opening/victory/defeat log lines and the panel's enemy heading use.
    When wildlife and guards were added the strings still said "Haydutlar",
    so a bear ambush and a guard patrol were both announced as bandits.
    The label is always used sentence-initial and in the nominative, which
    is why one form per kind is enough.
  - `CombatUnit`: one fighter on the field. Wraps a `CharacterData` on the
    player side and writes HP back when the fight ends.
  - `CombatEncounter`: the engine itself - initiative order, accuracy vs
    dodge, crits, cooldowns, enemy AI (weakest reachable target), rank
    repacking when someone falls. UI-independent and directly testable.
  - `CombatPanel` (in `scripts/ui/`): builds itself in code and is embedded
    into the journey screen, so a mid-journey fight never changes scenes
    (bkz. `HagglingPanel` deseni).

### Combat Rules

- Four ranks per side, 1 = front. A skill the current position cannot use is
  shown **disabled with its reason**, never hidden - same rule as event choices.
- Losing a fight is not automatically death: `write_back_party()` stands a
  unit that merely fell (never reached Death's Door, or reached it and won
  the deathblow roll) back up at 1 HP. But death is real now - see Death's
  Door below, which any party member can reach, not only the leader. The
  caravan can be ruined, never wiped out; the *people* in it can die.
- Combat is entered only through `EventEffect.Type.TRIGGER_COMBAT`, bridged by
  `EventEffectApplier.Result.combat_requests` and applied in `road_journey.gd`
  `_on_combat_finished(victory, xp_awarded)`. The bandit ambush's "fight"
  choice no longer rolls dice - it opens the real panel.
- **Timed stat modifiers are the one sanctioned way a skill reaches beyond
  its own hit.** A `CombatSkill` can carry `modifier_stat` ("accuracy",
  "dodge" or "damage"), `modifier_amount` and `modifier_rounds`; landing the
  skill calls `CombatUnit.apply_modifier()` on the target, and
  `CombatEncounter` ticks every unit's modifiers down by one each time the
  round number advances. `get_effective_accuracy()/_dodge()/_damage_bonus()`
  are what combat resolution actually reads - never the raw fields directly
  once a skill might have buffed/debuffed them. A skill with no damage, no
  heal and a non-enemy target (SELF/ALLY) applies its modifier without an
  accuracy roll - see `CombatSkill.make_buff()`.
- **Status effects are the second sanctioned reach beyond a hit**, and they
  are a separate field group from timed modifiers because they are a
  different thing: a modifier bends a number, a status *acts on its own at
  the start of a turn*. `CombatSkill` carries `status_kind`
  (`bleed`/`blight`/`stun`), `status_amount`, `status_rounds` and
  `status_chance`; a kind the engine does not know silently does nothing,
  the same trap as an unhandled `EventEffect.Type`, so
  `test_combat_dd.gd` scans the whole catalogue for it.
  - **Damage-over-time goes through the one damage door** (`apply_damage`):
    PROT, Death's Door and the deathblow roll all live there. A second door
    would mean bleed does not know about armour, and could kill a character
    outright without ever giving them the deathblow save roll everyone else
    gets.
  - **A status ticks at the start of the affected unit's own turn.** At the
    end is not the same thing: a bleeding fighter would then strike before
    bleeding, and the damage would land a round late.
  - **Two exploits are closed by construction, not by numbers.** Stun cannot
    be chained (a unit that comes out of a stun carries
    `STUN_RECOVERY_RESIST` for two rounds - without it, stunning the same
    target every turn is the single correct strategy and the rest of combat
    disappears); and the same status does not stack, it *refreshes* (two
    bleeds doing double damage makes "do the same thing again" correct
    again). Bleed and blight *do* stack with each other - two systems, and
    opening both is a real tactic.
  - **Resistance never closes the system in either direction**
    (`MIN/MAX_STATUS_CHANCE`), the same rule as hit chance: a stat that can
    switch a whole system off deletes that system. The baseline resist is
    not zero either, or a fresh character bleeds on every hit and bleed
    stops being a choice and becomes a tax on every attack.

- **Level buys resistance, not stats** - `CharacterData.get_bleed_resist()`
  and its siblings add `RESIST_PER_LEVEL` per level on top of the
  Dayanıklılık-derived base, capped by `MAX_STATUS_RESIST`. This is not an
  invention: it is exactly what the Progression Rules research already found
  Darkest Dungeon does (a resolve level grants *only* resist growth), and
  measurement said it was needed - with resistance coming from Dayanıklılık
  alone, levelling bought nothing defensively for the classes that do not
  invest there. Combat reads the `CharacterData` wrapper, never
  `character.stats`, for the same reason trait and equipment bonuses do.

- **Area skills must never beat single-target skills on the same side.**
  `CombatSkill.Area` is `SINGLE` (default, so every pre-existing skill is
  untouched), `ADJACENT`, `ALL` or `RANDOM`. The damage difference is set in
  the **catalogue, not the engine**: a global "area skills do 60%" multiplier
  would mean a skill's number is read from two places. `test_combat_dd.gd`
  compares per side and caught the bear on the first run - it swiped two
  ranks for more than the strongest single-target skill. A bear is dangerous
  through *breadth* now, not through a bigger number.
  - Adjacency is computed from **rank**, not array order: the array and the
    ranks stop agreeing the moment a side is repacked.
  - `RANDOM` exists only where the fiction demands it (a bandit leader's wild
    swing). Given to the player it would be a skill that takes the decision
    away, which is a penalty, not a mechanic. It never wastes a turn: if a
    valid target exists it always hits one.
- **`shift_amount` pushes or pulls the target, and the side is always
  repacked afterwards.** Without the repack a pushed enemy climbs to rank 5,
  falls outside every skill's reach and the fight locks - the same danger
  `RouteConditions` closes with "no city can ever be sealed off". "Ayak
  Bağı" pulling the back-rank archer forward is a turn won without damage:
  the rank design used from the other side.

- **Yetkinlik (skill proficiency) lives on the character, never on the
  shared `CombatSkill` resource.** `CombatUnit.skill_proficiency` (0-100 per
  skill, invested via `CharacterData.invest_skill_point()`) scales that
  unit's damage/heal by up to +50% and shortens its cooldown - mutating the
  cached `CombatSkill`/`EnemyTemplate` singletons directly would leak across
  every other user of that skill/template, which is why enemy level scaling
  is a `power_scale` multiplier applied only to the freshly-built
  `CombatUnit`, not the `EnemyTemplate` itself.

### Lineage Rules

The game's own codex states the thesis — *"the subject is not the caravan
but the people pulling it, and their wearing down"* — and for a long time
the systems contradicted it: the win condition was `GOAL_GOLD = 5000`. A
game about attrition cannot be won by filling a purse, and a gold target
frames the whole thing as a trade sim. The target and its screen are gone.

What replaced it was already half-written in the code as an edge rule:
**the leader dies, the senior companion takes over, the caravan does not
disband.** That is now the spine. The player does not run a caravan; they
carry a caravan *name* down the road.

- **The name outlives the leader.** `caravan_name` comes from the founder
  and survives succession; `lineage_generation` counts how many times the
  name has changed hands, not how many times you restarted.
- **`leader_since_day` makes the era a thing the story can ask about.**
  Campaign objectives read `days_as_leader`, so a chapter can gate on
  *this* leader's tenure rather than the caravan's total age.
- **The only real ending is having nobody left to carry the name**
  (`RUN_OVER_FLAG`). Wealth ends nothing.
- **The one non-negotiable rule needs a scene, not a log line.** Succession
  used to be `UI_ROAD_NEW_LEADER` - one line among a dozen others in the
  road log, indistinguishable from a famine warning. `SuccessionPanel`
  (`OnboardingPanel`'s scene-less pattern) is a full-screen, unskippable
  moment `road_journey.gd` opens whenever `resolve_combat_deaths()` returns
  a new leader: the caravan's name, the generation number, who fell, who
  leads now. Deliberately **not** dismissible by Esc or a backdrop click
  like every other overlay in the game - the one rule the whole game is
  built around doesn't get the casual-dismiss treatment. It joins
  `_has_open_panel()` so time and arrival both wait for it, same as the
  in-game menu.
- **`CaravanLedger` never deletes a line.** Someone who leaves or dies
  stays in the book, struck through. The reason is not mechanical: a
  deleted name reads as never having existed, a struck one is the
  player's own past. The ledger is also the world's memory —
  `build_campaign_context()` exposes counts from it, so events and
  chapters can read history without a second "memory system" being
  invented. Same discipline as objectives being `EventCondition`s.
- **The finale's gold gate became `days_as_leader`.** A pure money gate
  closed the story with "you got rich enough". The measurement survives:
  with a leader who never dies, tenure equals elapsed days and the finale's
  median lands at journey 30 (~180 days), so 60 is comfortably cleared. The
  other two thresholds stay as measured — Campaign Rules already records
  that moving the *later* gate halved the finale.

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
  A/D still moves `_leader_offset` within the stationary column, the same
  arithmetic the detach command already used. If the leader was never
  explicitly detached, camp ending snaps the offset back to 0 - the
  "attached" march assumes the leader leads at the front, and camp is not
  a second way to leave that assumption unstated.
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
  motion, only a different target. The leader (on watch) and the oxen
  (still in harness) never join - the mechanic is about the *people*.
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

### Audio Rules

- **One place knows which screen plays what.** `AudioManager` maps screens
  to tracks; the menu and the road share one (both are "you are on the
  way"), the city has its own (arrival). Same reasoning as `ArtPalette`
  being the only colour source.
- **A transition is a crossfade, not a cut.** Two players, not one: the
  moment the road ends and the city begins is where the game most needs to
  say *we arrived*, and a hard cut breaks it.
- **`play_track` is idempotent**, so moving between city screens does not
  restart the music.
- **The loop flag is set in code, not in the import settings.** `.import`
  files are gitignored and CI regenerates them, so a flag set there would
  vanish in a clean clone.
- **The default volume has exactly one owner** (`UserSettings`), and
  `AudioManager` reads it lazily. A second default is a silently wrong
  opening volume the day the two drift — and laziness also removes the
  dependency on autoload ordering.
- **Ambience is a third layer, not a variant of music.** The title screen
  needed wind playing while there is deliberately no music yet, and the
  moment the player presses a key both have to move at once - wind fading
  out under the road track fading in. Forcing that through the two-player
  crossfade built for *music-to-music* transitions would have meant either
  ambience competing with music for the same two players, or one of the
  two cutting instead of fading. `_ambience_player` is a third, independent
  `AudioStreamPlayer` with its own fade (`play_ambience`/`stop_ambience`),
  so the two layers can move in opposite directions in the same moment
  without touching each other's state.
- **A one-shot sound never shares a player.** `play_sfx()` spins up a
  fresh `AudioStreamPlayer`, plays it, and frees it on `finished` - it does
  not reuse `_active`/`_standby`/`_ambience_player`. Those three are always
  mid-crossfade or mid-loop; a gate creak and a menu-transition thud can
  land in the same moment, and stealing a busy player to play one of them
  would cut off whatever it was already doing.
- **A sound effect asset that doesn't exist yet is still safe to call.**
  `play_sfx`/`play_ambience` check `ResourceLoader.exists()` exactly like
  `_load_stream` already did for music, and no-op quietly if the file is
  missing - calling code never needs to know whether the asset landed yet.
  The wind bed, the wooden thud and the gate creak currently shipped are
  themselves placeholders in that same sense: synthesized in pure Python
  (`wave` + sine/noise, no external tools) rather than recorded, the audio
  equivalent of a `ColorRect` before the hand-drawn pass (see Art Rules).
  `AudioManager` has no idea which kind it's playing - swapping a `.wav`
  for a real recording later touches no code.

### Title Screen Rules

The opening screen used to be the main menu itself, buttons and all, the
instant the game launched - "a simple technical step" rather than the
first beat of the game's own tone. It now opens on the same dusk vista
with nothing on it but a slowly pulsing invitation, and only turns into
the menu once the player does something.

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

### Art Rules

The game was drawn in `ColorRect`s: the road was two rectangles and
fourteen sliding lines, the city five buttons, the caravan a row of
coloured boxes. The complaint - *"it looks like we are making a game in
Excel"* - was correct, and the deeper half of it is that a rectangle
cannot lie about being still but lies immediately once it moves.

Everything is drawn in `_draw()`. There are no asset files yet; when
hand-drawn art arrives, `ArtPalette` stays and the drawing functions give
way to textures.

- **One palette, one set of brushes.** `ArtPalette` is the game's only
  colour source (four day phases, five biomes, each biome filling the same
  four roles so a biome change can be a `lerp` rather than a cut);
  `ArtDraw` is the only set of brushes (gradient band, silhouette ridge,
  tree, conifer, rock, shrub, water, light pool, vignette, inked fill,
  wagon). Every screen inventing its own colours is why the game did not
  look like one production.
- **A shape drawn in two places is two different shapes.** The wagon lives
  in `ArtDraw.wagon()` because the road band and the walking area both draw
  it; keeping a copy each meant the same caravan's wagon was two different
  objects on two screens. Same reasoning as
  `CaravanPlan.daily_consumption()`.
- **The UI's own small marks are drawn too, never dialed from a font.**
  Position pips, sort chevrons and the objective check were Unicode
  characters (`●○↑↓✓`) for a while, and every one of them rendered as an
  empty box: Godot's default font doesn't carry Geometric Shapes, Arrows
  or Dingbats. A playtest photographed the combat panel's position marks;
  the same failure was sitting in eleven other player-facing spots
  (`UiIcon.gd`'s header lists them) and no test could see any of them,
  because the text itself was correct and translated - it just couldn't be
  rendered. `UiIcon` (`scripts/ui/`) draws these through `ArtDraw.pip()`/
  `chevron()`/`check()` instead, the same reasoning as the wagon: a shape
  is drawn once, not dialed from a font that may not carry it. See
  Localization Rules for the guard that now catches a glyph the font can't
  show, in either a CSV cell or a screen literal.
- **Scenery is generated from world coordinates, never from a list.** Each
  layer's props come from `hash(cell index)`; cells enter as the view
  scrolls and are forgotten as they leave. A fixed array wraps around, the
  player sees the repeat, and the road becomes a treadmill.
- **Nothing tall below the road; nothing low-and-near above it.** Trees,
  conifers, boulders and mountains all sit on the far side; below the road
  there are only shrubs, grass, small stones, mud and (in rain) puddles.
  Perspective is the reason: below is the closest point to the camera, and
  a tree there hides both the scene and the caravan.
- **Whatever is in front of the caravan must be drawn after it.** A band's
  own `_draw()` runs *under* its children, so anything it draws is behind
  the caravan - which is why figures looked like they were walking on top
  of the trees. `TravelForeground` is a sibling added after the caravan
  (`TravelBand.add_actor_layer()` is the single door that keeps the order);
  `HubScenery` splits into `LAYER_BACK` and `LAYER_FRONT` on two `z_index`
  values.
- **Column layout is spacing, never fixed steps.** Every piece of the
  caravan consumes its own width and a gap follows it, so an overlap is
  arithmetically impossible. Fixed steps failed twice - two wagons on top of
  each other, then the rear wagon's ox inside the front wagon - because the
  step was unrelated to the real widths. At most two people walk abreast and
  the gap between them is *derived from the figure's width*: a constant 30
  put two eighty-pixel figures on top of each other. Party members are
  spread along the column rather than stacked behind the leader, and the
  walking crew go **ahead of** their own wagon: beside it overlapped the
  body, behind it produced exactly the nameless tail the design does not
  want.
- **Nothing stands between an ox and its wagon — that space is the
  hitch.** The wagon unit was `[ox] [crew] [wagon]`, because the walking
  crew member could not go beside the wagon (it overlapped the body) or
  behind it (that is the nameless tail the design rejects). Putting them
  in the only remaining place put them *inside the harness*: measured, the
  ox sat 128px from its wagon against a wagon 67px wide, with a man
  standing in the middle, so the ox read as a stray animal rather than the
  one pulling that wagon. The drover now walks at the ox's head, which is
  how an ox cart is actually driven, and `ArtDraw.draught_pole()` draws
  the pole and yoke — without it the ox is an animal *standing* in front
  of a wagon. `tests/test_caravan_layout.gd` asserts the clearance is
  neither negative (ox inside the wagon) nor more than 0.6 × the wagon's
  width; the old order fails it 48 times.
- **The caravan must fit the frame it stands in, because it grows.** The
  anchor was a constant 0.34 of the band's width, so only a third of the
  screen sat behind the caravan — measured, a two-wagon caravan had its
  second wagon at x = −264 and a six-wagon one showed nothing but the
  first. Buying wagons is what the campaign pushes the player toward, and
  it had no visible consequence at all: the same failure as the nameless
  crew being invisible before Faz 8 PR-C. The anchor now slides right with
  the column (`TravelBand.caravan_x_ratio()`, clamped) and, only if that
  is not enough, `RoadCaravan` scales the whole column down to
  `MIN_COLUMN_SCALE`. Everything up to `FULLY_VISIBLE_WAGONS` (4) is on
  screen; a longer train's tail leaving the frame is honest, since a long
  caravan is longer than the view.
- **Measuring the column and placing it are the same function.** They were
  two, and they disagreed: the measuring copy forgot the walking crew
  member and two tight gaps inside each wagon unit, so the column read 66px
  short per wagon and the tail overflowed a frame it was calculated to fit.
  `RoadCaravan._walk_column(scale, place)` walks the cursor once and either
  places or only measures — the same reasoning that already puts the wagon
  centres in the layout rather than in `_draw()`.
- **A body part is the silhouette, not a decal on it.** The ox's shoulder
  hump — the cue that separates it from the horse — was a pale, un-inked
  ellipse laid over the back, and it read as exactly that: a disc stuck on
  the animal's nape. It was also the only shape on the whole figure drawn
  without `ArtDraw.inked`, so it did not even belong to the same drawing
  language as the body, neck and head. The hump is now two vertices in the
  body outline, so the topline itself humps; the small light ellipse that
  remains sits *inside* the body as a volume cue, which is the one place
  an outline-free shape is right.
- **A figure that moves needs joints.** `WalkFigure` solves hip → knee →
  foot with two bones; swinging a single-piece leg reads as scissors. The
  foot stays put while it is on the ground, so the figure does not slide.
  Wheels and walk cycles advance with **distance, not time** - a stationary
  wagon whose wheels turn is the vehicle-shaped version of a sliding
  rectangle.
- **Palettes are shared with combat.** `WalkFigure` reads
  `CombatFigure.ARCHETYPES`: the guard you saw in the fight walks the road
  in the same colours. Skin tone comes from `CharacterData`, height scales
  the figure - what character creation chose has to be visible or the
  choice is only text.
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
- **Everything that stands on the ground gets a contact shadow.**
  `ArtDraw.wagon()` and `WalkFigure` had one from the first day, and
  `WalkFigure`'s comment already said why — *without it the figure really
  does look like it is floating*. The scenery never got the same
  treatment, and the complaint came back in exactly those words: *"the
  trees look like they are hanging in the air."* `ArtDraw.contact_shadow()`
  is now the one brush, used by every tree, conifer, rock, shrub, roadside
  stop and milestone. A shape whose body simply stops on a flat gradient
  has no ground; the ellipse is the ground.
- **A prop's size, haze and base all come from one `depth`, never
  independently.** The tree line used to place every tree on one flat line
  with a random height, so a small tree and a large one stood on the same
  spot and neither read as nearer than the other. One `depth` in 0..1 now
  drives base y, height and how far the colour fades into the haze — that
  is the whole of the perspective.
- **Anything standing on a ridge must read the ridge's *drawn* edge.**
  `ArtDraw.ridge()` samples its sine every `_ridge_step` and draws
  straight lines between the samples, so the real silhouette is that
  polyline, not the sine. A base computed from the continuous sine leaves
  the prop hanging at a crest and buried in a trough — half of the
  floating-trees bug. `ArtDraw.ridge_y()` reads the same polyline, and
  `ridge()`/`ridge_snow()` build their polygons through `ridge_points()`/
  `snow_runs()` precisely so `tests/test_art_geometry.gd` can assert the
  two agree; a polygon already drawn onto a canvas cannot be read back.
  Verified by mutation: computing `ridge_y` from the sine fails 590
  assertions.
- **Draw order below the horizon is depth order, and the road is last.**
  Sky → ridges → lake → distant cities → ground fill → tree line →
  roadside stops → near props → road. The tree line used to be drawn
  *before* the ground, so every trunk's foot was painted over by the
  ground gradient and the tree ended behind the grass rather than on it.
  The road going last is what makes a shrub at the verge disappear behind
  it correctly — which also means the near props' range has to stop above
  the verge, or that whole strip renders empty.
- **Snow is a region, not an outline.** Drawing the same ridge twice at
  slightly different amplitudes left a thin white line along the peaks —
  a pencil stroke, not snow. `ArtDraw.ridge_snow()` fills only the parts
  above a snow line, as separate polygons, so low hills stay bare and the
  high one really is capped; its lower hem carries a short-wavelength
  wobble because a dead-straight cut reads as a white triangle glued on.
- **Wavelength and amplitude are read together.** A 54px amplitude on a
  wavelength of 0.16 × width gave the city outskirts rows of grey
  molehills, and a ridge whose troughs fall below the ground line shows
  only its peaks — which is the same molehills by a different route. The
  trough has to clear the ground line for the silhouette to be continuous.
- **Godot's `_draw()` fails silently.** A degenerate polygon prints
  "Invalid polygon data, triangulation failed", skips that shape and carries
  on - invisible without a rendered frame. Do not append a base edge to a
  shape whose arc already closes on it.
- **The frame closes at the bottom, or the eye falls out of it.** The
  strip below the road used to be the road's own light tone, so the
  picture *opened* downward and the caravan never separated from the
  ground. `TravelForeground`'s apron is a near-black earth band, and it
  is a depth rule, not a fill: the nearest strip is the darkest one.
  Which flips the props on it — shrub, stone and mud are now chosen
  **lighter than the apron**, because a dark shrub on dark ground is no
  shrub at all.
- **Flat marks are ground; standing props stand on it.** Puddles and bare
  soil are painted *onto* the earth and may merge freely — two puddles
  running together is what puddles do. A shrub and a stone are volume:
  two in the same place read as one lump. So they are two passes, marks
  first, and the standing pass obeys the column rule — **each prop
  consumes its own width** (`RoadCaravan._walk_column`'s reasoning), the
  next one starts after it, and what does not fit is dropped. Mixed into
  one pass, a puddle got painted over a tuft of grass.
- **Size and density must come from the same measure.** The foreground's
  cell spacing was a fixed 130 world px while prop size was a ratio of
  the band's height. That agreed only at `BAND_HEIGHT`; when the road
  screen went full-frame the band became ~990px, props tripled and the
  spacing did not, so everything piled up. Spacing is derived from the
  prop ceiling now. Whenever one of a pair is a ratio and the other a
  constant, the pair is a bug waiting for a resolution change.
- **Gloom must not delete the hour.** Rain lerped the sky fully to grey,
  so every rainy hour was the same lead-coloured screen. The mix is
  partial and the *horizon* takes the least of it — the light under the
  cloud comes in there, and that warm strip is what holds the scene up.
- **The world's architecture is the world's, not a borrowed one.** The
  distant city was square towers under triangular caps, which is a north
  European keep. Domes and minarets were tried as the fix and
  **reverted**: Wayborne has no such institution, so a place of worship
  on the horizon states something from outside the game's own lore.
  Wayborne's cities grew out of trade — wall, gate, warehouse — and what
  makes the silhouette readable is those blocks being at *different
  heights*, not a symbol. `ArtDraw.city_silhouette` is one brush because
  the main menu's horizon shows the same city.
- **A silhouette is read by the gaps, not the mass.** In flat ink every
  cue that separated two shapes by tone is gone, so shapes that work in
  colour collapse. Measured on `MenuBackdrop` in one pass: a walker whose
  torso reached the ground had its legs drawn *inside* it and read as a
  skittle; a wagon whose canopy was as wide as its bed became a tunnel
  (the canopy is narrower now, so there is a shoulder); a horse's legs
  were a fixed ratio and hung below the contact line, so the rider read
  as a four-legged stool; and the yoked ox pair, at the *road's* own
  offsets, merged into one humped mass — a silhouette needs those
  offsets larger than a tinted drawing does.
- **Every screen stands somewhere, or it is a model on a table.** The
  city was an isometric slab on a flat two-colour gradient: no sky, no
  horizon, no ground, and no shadow under it. On its own it looked
  deliberate; beside a road and a menu that had all four it was plainly
  a different production. `CityView` now draws sky → ridges → field →
  countryside → the town's own contact shadow → the town, which is the
  road's depth order applied to a screen that is not the road. The
  lesson generalises: when one screen gets the treatment, the screens
  that did not are now *wrong*, not merely older — a shared visual
  language is only shared if every screen speaks it.
- **One wagon is drawn by one ox, and that reverses an earlier decision.**
  For a while it was a pair: a single animal reads as a horse's harness,
  not a yoke, and the far ox was pushed back by three marks at once -
  slightly ahead, slightly higher, slightly smaller - because any one or
  two of them alone read as a thick shadow of the near ox rather than a
  second animal. Asked for explicitly, it went back to one - same family
  as the mosque/minaret reversal in this section: a design tried,
  measured, and then undone on its own merits rather than because the
  first attempt was wrong. `RoadCaravan` no longer creates a second,
  shaded figure per wagon at all (`_oxen_far` and its `PAIR_LEAD`/`RISE`/
  `DEPTH`/`SHADE` offsets are gone, not merely hidden), and
  `menu_backdrop.gd`'s independent backlit-caravan silhouette - a second,
  separate implementation of the same pair, because a silhouette can't
  share a `WalkFigure` with the road - got the same edit for the same
  reason `ArtPalette`/`ArtDraw` exist: two places drawing the same
  caravan have to agree, or the game looks like two productions again.
  The column's measurements already came from the near ox only, so
  `get_ox_centres()` (one centre per wagon) needed no change at all.
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

**Structural tests verify layout; they never verify appearance.** That is
what the screenshot tools are for - see Testing.

### Route Terrain & Weather Rules

`WorldMapData` is the unchanging map and `RouteConditions` is this week's
state; `RouteTerrain` is the third layer, the road's *geography*, and
`RouteWeather` is the day's sky. Both are **computed from a seed, never
stored** - the same reasoning as `RouteConditions`' natural states: two
cities are always joined by the same terrain, and reloading a save cannot
re-roll the rain away.

- **Terrain is data before it is a picture.** Segments, their biomes, the
  roadside stops (hamlet, outpost, mine, pass, shrine, bridge) and the
  slope all come from `RouteTerrain`; the road screen draws them and the
  planner prints them in one line, so choosing a route is no longer blind.
  Biomes step at most two places along `BIOME_CHAIN`, because steppe
  straight into mountains does not read as geography.
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

### Stress Rules

- **Stress (`GameSession.party_stress`) and morale (`CaravanState.morale`)
  are deliberately separate stats.** Morale resets to full at the start of
  every journey (`CaravanState.from_plan`) - it's that journey's mood.
  Stress is party-wide and persistent across journeys; only a city arrival
  (`finish_journey()`, `-CITY_REST_STRESS_RELIEF`) or a road camp
  (`GameSession.make_camp()`, `-CAMP_STRESS_RELIEF`) brings it down. Both are
  shown on `world_hub.gd`'s HUD as `PulseBar`s - a bar that flashes to full
  opacity on change and fades back to idle, so the "ana ekran" reflects both
  without permanently cluttering it.
- **Resistance, not a global threshold, decides who breaks.**
  `CharacterData.get_stress_resistance()` scales with the character's own
  Dayanıklılık; `is_stressed(party_stress)` compares the party's current
  stress against that personal line. A high-resistance character can stay
  composed while a low-resistance one has already broken.
- **Breaking (`GameSession.resolve_stress_breaks`) happens once per city
  arrival**, for every currently-stressed character: mostly (85%) an
  affliction, rarely (15%) the DD-style inverse where hardship forges a
  virtue instead - both go through `TraitCatalog.roll_break_trait()`, which
  is `roll_seed_trait()`'s weighting with the polarity pre-decided. An
  afflicted companion (never the player) may also leave the caravan outright
  - **iterate a copy of the party** when a loop might call `dismiss()`, or
  removal mid-iteration silently skips the next character. `Array.duplicate()`
  doesn't carry its element type statically, so assign it to an explicitly
  typed `Array[CharacterData]` variable first (`resolve_stress_breaks()`
  does this) - otherwise the loop variable degrades to `Variant` and any
  `:=` call on it (`character.grant_trait(...)` here) fails to parse; see
  the `:=` / Variant trap under Autoload rule.
- **A broken character can refuse orders in combat.**
  `CombatUnit.is_stressed` (set from `CharacterData.is_stressed()` when the
  encounter is built) gives `CombatEncounter` a flat chance each time that
  unit's turn comes up to skip it entirely, logged and nothing else - never
  exposed as a choice to the player, unlike a locked skill.
- **`EventEffect.Type.STRESS` is the vocabulary events use to touch it**,
  same rule as every other effect: unhandled means silently inert. The
  `stress` key is available in `GameSession.build_event_context()`, so an
  event's own eligibility can key off it directly (`evt_stress_brawl`)
  instead of needing a bespoke weight modifier.
- **Stress accumulates across journeys; that is the whole point of it being
  the persistent stat.** It did not, for a long time: a journey brought
  ~25 and a city arrival wiped 35, so the number reset every loop and
  `evt_stress_brawl` never fired. Arrival relief is now
  `get_city_rest_relief()` - smaller than a journey's load, and *decaying
  with `total_days_elapsed`* down to a floor, so the same inn helps a
  weary company less ten journeys in. The gap is what accrues.
- **Every tap must be measured, not just the obvious one.** Lowering the
  arrival relief was not enough: `CAMP_STRESS_RELIEF` was 20, so one camp
  per journey still erased the accumulation entirely (measured: stress
  stayed under 20 across twelve journeys). Camp now *slows* accumulation
  rather than deleting it. When a stat refuses to move, enumerate
  everything that reduces it before touching what raises it.
- **Stress belongs to a person, not to the party.** `CharacterData.stress`
  is the owner; `GameSession.party_stress` is a **lens onto the average**,
  readable and writable because the HUD bar, departure morale, the event
  context and `evt_stress_brawl` all ask "what shape is the company in",
  and the answer to *that* is an average. But *who breaks* is not an
  average question, so the break roll and combat's order-refusal read the
  character's own stress (`is_stressed()` takes no argument). A single
  number made the durable one and the nearly-broken one the same number —
  which is the source of the whole genre's drama, deleted before it could
  happen. Two consequences, both correct: `change_stress` wears the whole
  party with **per-person clamping** (someone at the cap absorbs an
  increase, someone at the floor absorbs a decrease — exactly what one
  shared clamp hid), and a party with no members has stress zero, because
  there is nobody to carry it.
- **`_migrate_save` earned its keep here.** `SAVE_VERSION` 2 spreads a v1
  save's single average across every party member. Inventing who was worn
  down and by how much would be inventing information that never existed;
  the information *was* the average. This is the first case `.get`
  defaults could not cover, which is the hook's entire reason to exist.
- **`party_stress` is the party's average, not one person's counter.** So
  a newcomer dilutes it (`add_to_party` - the single door in, the
  counterpart of `dismiss`), and replacing a crew over time brings it down.
  A newcomer does not arrive at zero (`NEWCOMER_STRESS_SHARE`): someone
  joining a battered caravan hears the stories. Without that share,
  "dismiss one, hire another" would be a free button that halves stress
  every cycle.
- **The player needs a lever their purse can pull, and it must be rationed.**
  `throw_feast()` (in the tavern) is paid relief priced per head, **once per
  day** - which, since days only advance on the road, means once per city
  visit. Unrationed it was the exploit: five feasts took stress from 90 to 0
  for 225 gold, less than one journey's net income. You cannot sober a
  company five times in one evening, and a persistent stat that gold erases
  on the spot is not persistent. `last_feast_day` is saved, or reloading
  would reset the counter.
- **A stress lever that resets on reload is not a lever.** Same reasoning as
  `RouteConditions`' computed states: anything a player could re-roll by
  loading a save has to live in the save file.

Camp is the free-but-slow lever, the feast the paid-and-rationed one, and
stress-relieving events the lucky one. Measured over twelve consecutive
journeys (~25 stress each):

| play pattern | stress after 1 / 6 / 12 journeys | journeys at brawl threshold |
|---|---|---|
| no intervention | 11 / 69 / 88 (capped) | 84% |
| one camp per journey | 4 / 22 / 49 | 43% |
| one camp + feast | 4 / 22 / 28 (plateau) | 37%, ~43 gold |
| two camps per journey | 0 / 0 / 1 | 0% |

The last row is deliberate, not an oversight: a player who spends the nights,
food and daylight to camp twice a journey *should* hold stress down.

"Dismiss one, hire another" is not an exploit either, but only because it is
*dominated*: churning the crew takes stress from 90 to 6 over eight hires -
and eight hires cost far more than the feasts that do the same job, on top of
losing every companion's levels, traits and equipment.

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
- **`test_navigation.gd` guards that overlay by building it**, which is
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

### Campaign Rules

The game has a story with an ending, and trade that can run forever after
it. `scripts/campaign/` is that spine: `CampaignChapter` (one beat) and
`CampaignCatalog` (the ordered five).

- **A chapter objective is an `EventCondition`, not a new language.** Event
  triggers already read a flat context dictionary, cheaply and with tests
  behind them. Writing a second "quest condition" vocabulary would mean two
  ways to say the same thing, diverging from day one. Objectives are the
  same sentences.
- **But they read a different context.** `build_campaign_context()`
  describes the caravan's *career* — journeys completed, contracts
  delivered, cities seen, wagons owned; `build_event_context()` describes
  the journey happening *now*. A chapter objective reading the event context
  would complete and un-complete on every arrival, because `finish_journey()`
  resets the caravan. Add a career counter rather than reaching into the
  road's numbers.
- **A closed chapter never reopens.** Chapters advance by index and are
  never re-evaluated, so "amass 2500 gold" stays earned after the gold is
  spent. Progress that a purchase could undo is not progress.
- **The finale is a threshold, not a stop.** `is_finale` shows an epilogue;
  the purse, the roads and the market carry on exactly as before — the same
  shape as the `GOAL_GOLD` screen's "Devam Et". `tests/test_campaign.gd`
  asserts the game still works after the last chapter closes, because that
  is the promise most easily broken by accident.
- **Chapters close at arrival, and more than one may close at once.** The
  check runs at the *end* of `finish_journey()`, after the payout, the
  delivery count and the new city are recorded — otherwise a chapter would
  always close one journey late. A long journey that satisfies two chapters
  closes both; making the player sail back and forth for the bookkeeping
  would be a worse game.
- **Each chapter sets a flag on completion, and that is how the story
  reaches the road.** An event can gate itself on `HAS_FLAG` — the campaign
  plugs into the event pool that already exists instead of inventing a
  parallel one.
- **Campaign progress lives in the save.** Same reasoning as
  `last_feast_day` and `RouteConditions`' computed states: anything a reload
  could replay is not progress.

**The chapter thresholds are measured.** `tests/simulate_career.gd` is the
tool that was missing when they were first written: `simulate_journeys.gd`
measures *one journey* repeatedly, this measures *one caravan's life* —
forty journeys of market trading, contracts, wagons and hires, reporting
where the money, reputation and chapters actually land.

Measured over 8 caravans × 40 journeys, following the campaign (stay lean
while delivering, expand once the ledger is clean):

| chapter | closed | earliest | median | latest |
|---|---|---|---|---|
| İlk Yol | 8/8 | 1 | 1 | 1 |
| Bir Kadro | 7/8 | 5 | 11 | 20 |
| Ağ | 6/8 | 8 | 16 | 36 |
| Temiz Defter | 6/8 | 8 | 17 | 38 |
| Kendi Hanın | 5/8 | 22 | 30 | 40 |

So a full story runs roughly thirty journeys / 180 game days, and about a
quarter of caravans never finish it — acceptable in a game where the
caravan can be ruined, and worth revisiting if it ever feels punishing.

Three findings came out of the measurement, and each is worth more than the
numbers:

- **Reputation is the scarcest resource in the game** and the real gate on
  chapters 3 and 5 (average reputation is ~1 at journey 20, ~11 at 30). Any
  future chapter that gates on it is gating on the slowest-moving stat.
- **Buying wagons crowds out contracts.** `CaravanPlan.DEFAULT_MAX_WAGONS`
  is the caravan's *total* cap, so the player's own wagons eat the merchant
  slots: a caravan that buys five wagons has one escort slot left, and its
  `contracts_delivered` froze at 11 while a lean caravan reached 41. That
  is a real trade-off (haul your own goods, or escort others') rather than a
  bug — but it means the two middle chapters pull in opposite directions,
  and a player has to sequence them.
- **Two chapters that close together are one beat.** Chapters 3 and 4 both
  landed on journey 19. Dropping chapter 3's reputation bar from 8 to 5
  separated them. Raising chapter 4's contract bar from 8 to 12 was tried
  for the same purpose and **reverted**: it separated the beats but halved
  the finale (6/8 → 3/8), because delaying chapter 4 delays the expansion
  phase that chapter 5 needs. Tune the *earlier* gate, not the later one.

Two things the harness itself got wrong first, recorded because the next
person will hit them too (the third and fourth entries in this file's
history of measurement bugs):

1. **Running on contract income alone.** Most real income is market trading
   (see Provision Rules). Without it the caravan went broke by journey eight
   and every threshold looked unreachable.
2. **Accepting contracts bound for cities it then did not travel to.** Every
   undeliverable contract costs reputation; the probe cratered to -44 and
   `required_reputation` closed the whole board. **Pick the route first,
   then the contracts.**

And one clean negative result worth keeping: making the simulated player
expand one chapter earlier changed the outcome *not at all* (finale still
5/8, median still 30), so the finale's failure rate is real difficulty and
not an artifact of how the policy was written.

### City Hub Rules

The city is where the player decides; the road is where the decision is
paid for. A new game starts in a city (`character_creation.gd` →
`Nav.go_root(Nav.CITY_MAP)`), and so does every arrival and every
"Continue".

- **The brief leads with the story.** `CityBriefPanel`'s first block is the
  current chapter, its narration and its objectives with live counts (see
  Campaign Rules) — "where am I in this story" is the question a session
  opens with, before "what do I lack" and "where do I go".
- **The city answers two questions on one screen, or it answers neither.**
  It used to be five doors and an exit: to learn where you could even go,
  you had to walk tavern → world map → planner, and to learn what the
  caravan lacked you had to visit all five doors. `CityBriefPanel` answers
  *what does the caravan need* and *where can it go today* beside the map.
- **Every warning names the screen that fixes it, and pressing it goes
  there.** A warning that only worries the player is worse than no warning.
  `tests/test_city_commerce.gd` asserts every produced need points at a
  screen the city can actually open — a dead button here would drop the
  player back into exactly the stuck feeling the navigation stack was built
  to remove.
- **No need, no row.** A permanent checklist of green ticks is noise; when
  nothing is wrong the panel says so in one line.
- **Debt shows whenever it exists, not only when it is nearly due.** Showing
  it only inside the warning window meant a caravan 350 in the hole read as
  healthy until the last week. Urgency lives in the colour, not in whether
  the row appears at all.
- **The panel invents nothing.** Every line reads a value the session
  already publishes (`get_route_danger`, `get_daily_provision_consumption`,
  `get_accepted_offers_for_destination`, `party_stress`). It shows; it does
  not decide. Navigation is likewise not its job: it emits
  `screen_requested`/`planner_requested` and `city_map.gd` does the
  `Nav.open()`, because the screen that sends the player is always the one
  that pushes the stack.
- **Setting out from the brief is the same handoff the map uses**
  (`TravelContext.selected_destination_id` then the planner), so there is
  one path into a journey, not two.

### Caravan Ruin Rules

"The caravan is never wiped out" does **not** mean it is untouchable. It can
crawl: everything down to the leader, their own wagon and whoever stays loyal
can be lost.

- **Gold can go negative - the caravan can fall into debt.** Two spending
  paths enforce the difference: `Wallet.spend()` is optional purchase (a
  wagon, a hire, goods) and simply fails when you cannot afford it - the
  player never sinks himself. `Wallet.force_spend()` /
  `GameSession.spend_or_owe()` is money you *must* pay - tribute, a fine,
  customs, interest - and it pushes the purse below zero.
- **`DebtLedger` is the one place debt lives.** A debt carries a creditor, a
  principal and a due day (a month). Past due, every 10 days adds 15%
  interest and costs reputation; restructuring pushes the deadline out but
  adds a fee to the principal, and the fee rate grows each time - endlessly
  deferring must not be the cheap way out.
- **The negative balance and the ledger's overdraft entry are the same
  money.** `GameSession` syncs them on every `balance_changed`. Kept
  separately they drift: earn gold and the purse recovers while the ledger
  still shows the old debt, so the player is billed twice for it.
- Provisions still never go below zero, but zero means you cannot feed the
  caravan: hunger and morale losses follow.
- **Debt the player cannot see is indistinguishable from a bug.**
  `DebtPanel` (scene-less like `PurificationPanel`) is where debts are
  borrowed, read, paid and restructured; the total also rides on the city
  and road HUDs. The ledger shipped without any screen at all for a while -
  interest accrued and reputation drained entirely out of sight. It then
  spent a while as a section buried under the guild's contract list, which
  is barely better: it sits in its own **tab** of the guild now
  (`UI_GUILD_TAB_DEBTS`), so a growing board cannot push the caravan's debts
  below the fold.
- **A debt's urgency is a gradient, not a threshold.** Each row used to
  snap between three fixed colours - white, then yellow at exactly
  `DUE_SOON_DAYS`, then red the instant it crossed the due day - so a debt
  read identically at 8 days left and at 30, and a single day's passing
  could jump the colour straight from calm to alarmed. `DebtPanel.
  _severity_color()` lerps continuously within each band instead: white to
  `DUE_SOON_COLOR` as the due day approaches, then `OVERDUE_COLOR` toward a
  darker `OVERDUE_SEVERE_COLOR` as it slips further past - deliberately
  reaching full severity at `Debt.OVERDUE_PERIOD_DAYS`, the same day the
  first real interest period actually bites, not an arbitrary constant of
  its own. No new art: this is a colour interpolation on the label that
  was already there, the same vocabulary `PulseBar` uses to show change
  without a new widget.
- **The guild lends, and the credit line is what keeps that honest.**
  `spend_or_owe` is debt the world forces on you; `borrow_from_guild()` is
  the opposite — money taken on purpose, in a city, to stock up before
  setting out. Three rules stop it being a print button. The line scales
  with reputation (`get_credit_limit`), so an untrusted caravan gets little
  and `LOAN_MIN_REPUTATION` shuts the door on one that has burned the guild.
  **Every debt consumes the line, the overdraft included** — that is what
  closes the sharpest exploit here: the overdraft's due date is set at the
  first dip, so borrowing to clear it would be a free restructure, and
  restructuring costs a fee that grows each time. And an origination fee
  rides on the principal, so borrowing is never free even when repaid on
  time.
- **A locked purchase needs to name its own way out.** The caravan
  planner's "buy the shortfall" button just sat there disabled when the
  purse couldn't cover it, the same dead end as a hidden need on
  `CityBriefPanel` (see City Hub Rules) - the fix there was "every warning
  names the screen that fixes it", and it applies here too. A "Borç Al"
  button appears in exactly that state and sends the player straight to
  the guild's Debts tab (`Nav.guild_initial_tab`, consumed the moment
  `guild.gd` reads it - `Nav.city_gate_opening`'s pattern, or a later,
  unrelated visit to the guild would open on the wrong tab). `DebtPanel`
  itself was also missing the one number every decision there needs - how
  much gold is actually in the purse - so it's now the first line, same
  `UI_PURSE` key the planner already used.
- **Money the player sees must match the formula to the coin.** The
  origination fee was a float rate, and `200 * 0.1` is `20.000000000000004`,
  so a 200 loan wrote **221** into the ledger under a sign saying 10%. The
  percentage is an integer and the fee is integer arithmetic. A rounding
  artifact in a number the player is quoted is indistinguishable from
  cheating.
- **The origination fee is a band, not a flat rate, for the same reason the
  credit line already scaled with reputation.** A caravan the guild
  doesn't trust pays more to borrow at all - `get_loan_fee_percent()` runs
  from `LOAN_ORIGINATION_PERCENT_UNTRUSTED` (15%) at reputation 0 down to
  `LOAN_ORIGINATION_PERCENT_TRUSTED` (5%) at `LOAN_FEE_REPUTATION_CAP`
  reputation, and integer division keeps every point on that band as exact
  as the old flat rate was. The band was deliberately calibrated to cross
  10% - the old constant - at reputation 20, which is not a coincidence:
  three existing tests already borrowed at reputation 20 and asserted an
  exact 10% fee, and recalibrating the *band* instead of picking round
  numbers for its ends meant those tests kept passing unchanged instead of
  needing to be rewritten around the new mechanic. `get_loan_principal()`
  itself didn't need to change at all - it already read the fee percentage
  through a function call, never the constant directly, so plugging in a
  reputation-dependent answer under that call was the entire change.
- **A wagon can be sold, and resale never returns its cost.** Otherwise
  buy-then-sell is a free capacity toggle around every journey.
  `WAGON_RESALE_FACTOR` is the depreciation and a damaged wagon is worth
  less again — and the yard takes the damaged one first, so selling a wreck
  instead of repairing it is a real choice. It is only a choice because
  repair stays strictly cheaper than sell-and-rebuy, which
  `tests/test_city_commerce.gd` asserts rather than assuming.
- **A voluntary sale never strands the caravan.** Losing a wagon on the road
  may leave the roster over capacity (Ruin Rules: nobody is evicted), but a
  *button* that quietly does that reads as a bug. So the sale is shown
  **disabled with its reason** — last wagon, on the road, party would not
  fit, cargo would not fit — the same rule as locked event choices, locked
  skills and locked equipment. `get_wagon_sale_block_reason()` returns the
  translation key and the screen prints it.
- **`SAVE_VERSION` is read, not just written.** `_migrate_save()` is a real
  (currently empty) hook: every field is loaded with `.get(key, default)`,
  so added fields need no migration, but a field whose *meaning* changes
  does - and a version number nobody reads is a hook nobody remembers.

### Ruin Rules

"The caravan can be ruined but never wiped out" is only half a rule if
nothing can actually ruin it. Measured before this pass: average wagon loss
0.00 across 600 journeys, a party of three or four winning 100% of fights at
every danger level, and levelling that made the party *weaker*. The
vocabulary existed; the game never spoke it.

- **A dead effect type is worse than a missing one.**
  `EventEffect.Type.WAGON_LOSE` was handled by the applier and used by no
  event at all, so a wagon could never be lost. It now has two doors -
  `evt_landslide`'s "squeeze past" and `evt_storm`'s "press on" - both rare
  (measured ~1 wagon per 40 journeys), because a lost wagon should be a
  disaster you remember, not a recurring fee. `CaravanState.lose_wagons()`
  clamps at `MIN_WAGONS`, so the player's own wagon never goes.
- **Losing a wagon does not evict party members.** Capacity falls below the
  roster and recruiting is blocked until a wagon is re-bought; nobody is
  thrown out. Kicking a levelled companion off the roster because a wagon
  went over a cliff would break "never wiped out".
- **Two knobs, because one cannot shape both ends of the curve.**
  `POWER_SCALE_PER_LEVEL` answers "does levelling feel like progress" and
  `POWER_SCALE_PER_PARTY_MEMBER` answers "is a full caravan untouchable".
  Tuning enemy strength alone balanced the full party and drove the lone
  traveller to 0% - as broken as 100%, because no decision remains.
- **Level scaling must stay below the player's own growth.** At 8%/level
  enemies reached 2.12× and the measured curve *inverted* (level 1: 98%,
  level 15: 52%) - the player's HP only grows on ENDURANCE-affinity classes,
  about +25% averaged across a mixed party, against enemies gaining far
  more. At 2%/level the curve rises again.
- **When the squad is trimmed to party size, composition order decides what
  the player faces.** Trimming by rank position meant a lone traveller always
  drew two cutters and never the leader, so a calm road and a bandit-infested
  one were literally identical for them. The id list is now written in
  priority order (the leader is pushed to the front at high danger) and
  trimmed from the end. Trimming by raw threat was tried and flattened the
  encounter - it dropped the archer every time, leaving three melee and
  erasing the rank design.

Measured win rate (party size × road danger, level 1), **re-measured after
the Darkest Dungeon pass** (PROT, the per-round speed die, Death's Door,
status effects, area skills):

| party | 20% | 40% | 65% | 90% |
|---|---|---|---|---|
| 1 | 32% | 32% | 7% | 7% |
| 2 | 95% | 58% | 12% | 12% |
| 3 | 100% | 92% | 50% | 50% |
| 4 | 100% | 100% | 87% | 87% |

A lone traveller on a bandit-infested road is nearly hopeless, and that is
the intended message rather than an oversight: the game starts you with two
people, and party 1 only exists if you dismiss someone. Losing a fight used
to cost only attrition; since Faz 14 it can cost a real, permanent death to
anyone on the field, not only the leader (see the Faz 14 note below).

**The whole table moved down, and the cause is DD-1, not the content added
after it.** Enemy PROT and the re-rolled speed die were never re-measured
when they landed; DoT and area skills were added later and, when tempered,
moved these numbers **not at all** (the table's squad is bandits, whose only
new trick is a small cleaver bleed). The lesson is the one this file keeps
recording in other forms: *a mechanic that is not re-measured when it lands
is a balance change nobody has seen.*

The number worth revisiting is **party 2 at 65% danger: 23% → 12%**. Two is
the starting party, so that is the pair's odds on a road the tavern openly
calls dangerous. It is defensible - the player chooses the road and can pay
to learn its danger first - but it is the tightest square in the table.

**Re-measured after Faz 14 opened Death's Door to the whole party** (see
Combat Rules): the table moved up everywhere, not down, and the size of the
jump was not predicted going in.

| party | 20% | 40% | 65% | 90% |
|---|---|---|---|---|
| 1 | 53% | 55% | 23% | 23% |
| 2 | 100% | 93% | 60% | 60% |
| 3 | 100% | 100% | 88% | 88% |
| 4 | 100% | 100% | 100% | 100% |

**The cause is a kill-sponge effect, not a damage or accuracy change.** A
companion on Death's Door used to leave the fight the instant they hit 0
HP - one less body on the field, full stop. Now they stay on the field at
0 HP, still swinging (at the accuracy/damage penalty), and every subsequent
hit against them is a deathblow roll the attacker only wins `100 -
deathblow_resist` (33%) of the time. The enemy AI always targets the
weakest reachable unit, so a Death's Door companion becomes the enemy's
preferred target - and two hits in three land on someone who was already
"spent," instead of carrying over to a still-healthy ally. The party is
statistically tankier in aggregate *because* any one member is now
individually more fragile, which is exactly backwards from what the
raw feeling of "everyone can die now" would suggest.

**Faz 15 retuned it - and the guessed lever was wrong.** The Faz 14 note
above named `DEFAULT_DEATHBLOW_RESIST` as the most likely fix. Measured
instead of assumed: dropping it from 67 all the way to 33 (nearly a
coin-flip against permanent death on every Death's Door hit) left party 4
at **100% / 100% / 98% / 98%** - almost unchanged. The kill-sponge diagnosis
was correct, but the resist percentage was never the dial that mattered for
*this* symptom - a battle a full party wins in two or three rounds barely
exercises the deathblow roll at all, so hardening it does nothing to a fight
that was never close. Guessing the lever without re-measuring would have
shipped a much harsher permadeath for every party size to fix a problem
specific to party 4, which is exactly the mistake this file exists to catch.

The real cause was arithmetic, not the death mechanic: `_build_units()`
caps squad size at `MAX_SQUAD_SIZE` (4, the battlefield's own rank limit),
and a danger-appropriate bandit squad already reaches 4 templates (leader +
two melee + archer) at high danger. Party 3 and party 4 therefore already
face the *same* enemy count - party 4's fourth member is a free extra
attacker with no corresponding extra defender, which is the actual source
of the runaway win rate, independent of anything Death's Door changed.

`POWER_SCALE_PER_PARTY_MEMBER` is the knob that already exists for exactly
this ("kervan büyüdükçe onu durduranlar da güçlenir"), and it was under-set
at 0.10. Measured at three values (60 battles each, same seeds):

| `POWER_SCALE_PER_PARTY_MEMBER` | party | 20% | 40% | 65% | 90% |
|---|---|---|---|---|---|
| 0.10 (Faz 14) | 4 | 100% | 100% | 100% | 100% |
| 0.20 | 4 | 100% | 100% | 98% | 98% |
| 0.30 (shipped) | 4 | 100% | 100% | 92% | 92% |

0.30 is the value that ships. It breaks the specific violation - party 4 no
longer reads 100% at the two dangerous tiers, where "dokunulmaz olmasın"
actually matters - while leaving a calm road (20%/40%) trivially safe for a
full crew on purpose, the same design intent that already lets a lone
traveller walk an easy road unbothered. The full retuned table:

| party | 20% | 40% | 65% | 90% |
|---|---|---|---|---|
| 1 | 53% | 55% | 23% | 23% |
| 2 | 100% | 68% | 43% | 43% |
| 3 | 100% | 97% | 68% | 68% |
| 4 | 100% | 100% | 92% | 92% |

Party 1 is bit-for-bit unchanged (the multiplier is `1 + k*(party_size-1)`,
so a lone traveller was never touched by this dial - confirmed, not
assumed). Party 2 and 3 move down more than party 4 does in relative terms,
because the same linear dial that finally dents the capped-squad case also
bites everyone above party 1; party 2 at 65%/90% landing at 43% (down from
60%) is a bigger swing than the table's own history treats lightly (bkz.
the "tightest square" note above), but it moves *toward* the game's stated
goal - "eşkıya kaynayan yolda gerçekten kaybedebilsin" - not away from it,
and `DEFAULT_DEATHBLOW_RESIST` stays at 67, untouched, because it was never
the problem.

### Progression Rules

"Levelling should feel like progress" was the open question after the ruin
pass, and the answer came from looking at what comparable games actually do
rather than from instinct. The instinct - *give every stat a combat
derivation* - is **not** what the genre does:

- **Darkest Dungeon**, the game this one names as its model, gives a resolve
  level **no stat growth at all** - only +10% per level to trap disarm and
  the stun/blight/bleed/move/debuff resists. HP, damage, accuracy and dodge
  come from equipment bought at the Blacksmith and skill ranks bought at the
  Guild, both **gated by resolve level**. The level is the *key* to power,
  never the power.
- **Wartales** has our exact problem stat: Willpower does not rise on
  level-up for most classes, yet it is not dead - it buys crit (+1% per 5),
  decides how fast the Galvanized morale buff lands, and grants a death save
  at 15. It grows through traits, professions and knowledge instead.
- **Battle Brothers** does grow attributes (three per level, +1..+4 by
  talent stars, cap 11, then veteran levels at +1 and no perk point), but
  its own guidance is "never spend on a stat the brother will not use" - it
  accepts role-specific stats rather than making all six universal.
- **Darkest Dungeon 2** removed hero levelling outright, moving growth to
  meta-progression unlocks at the Altar of Hope.
- The **dump-stat literature** is blunt about Charisma: it became a dump
  stat *because* morale, reaction rolls and hirelings stopped mattering to
  how people played. The prescribed fix is to make the systems it feeds
  matter - not to bolt combat numbers onto the stat.

Wayborne already had the Darkest Dungeon equipment axis, and it measurably
works (bare 52% vs fully geared 70%). What it lacked was a link between the
level and that axis, and any combat consequence for Karizma at all.

- **`Equipment.required_level` is the level's job.** Tiers used to be gated
  by gold alone, so a level-1 party could wear tier 3 the moment it could
  pay - the level meant nothing on the strongest axis in the game. Tier 2
  needs level 3, tier 3 needs level 6. Trinkets (ring/amulet) stay
  ungated: they are found, not bought, and a DD curio you cannot use is a
  non-reward. The gate lives in `GameSession.can_equip()`, checked by
  `equip_to_character()`, and the character screen shows the locked piece
  **disabled with its reason** - the same rule as locked event choices and
  locked combat skills.
- **Karizma buys composure under fire.** `CharacterStats.get_composure()`
  subtracts from `CombatEncounter.STRESS_REFUSAL_CHANCE`, so a charismatic
  fighter who has broken still takes orders. Measured: with a calm party
  Karizma changes **nothing** (45% at 5, 10 and 15 alike - it is not a
  hidden universal bonus), while a broken party goes 33% → 38% → 45%. It
  never zeroes the refusal (`MIN_STRESS_REFUSAL_CHANCE`), for the same
  reason the haggling floor exists: a stat that switches a whole system off
  deletes that system.

The ladder a player actually climbs, measured at 65% danger with a pair:

| rung | win rate |
|---|---|
| level 1 + tier 1 gear | 33% |
| level 3 + tier 2 gear | 70% |
| level 6 + tier 3 gear | 88% |

**Measure the rungs together, not the level and the gear separately.**
Reporting them apart is what hid the problem for so long: the level report
said "flat" and the equipment report said "strong", and neither said that
the two were unconnected. The simulator's equipment A/B also has to level
the geared character to the tier requirement now - measuring a combination
the player cannot reach says nothing about balance.

### Provision Rules

Provisions are the Oregon Trail spine: the caravan eats every day whether
or not the day went well.

- **One formula, one place.** `CaravanPlan.daily_consumption()` is the only
  place a daily provision cost is computed; the planner reads it through
  `CaravanPlan.get_required_provisions()` and the road through
  `GameSession.get_daily_provision_consumption()`. There were three drifting
  copies (plan, road, simulator) - the plan counted only merchants, the road
  also subtracted the quartermaster, the simulator did a third thing. **The
  moment those diverge the planner lies and the player starves on a journey
  they provisioned correctly.**
- **Mouths are the real caravan**: named party members, `PEOPLE_PER_WAGON`
  crew per owned wagon, and each contracted merchant. Buying a wagon is no
  longer pure upside - it also brings two more mouths.
- **Famine means "we could not feed them today", not "the stores hit zero".**
  `change_provisions()` returns what actually moved; famine fires when that
  is less than the day's need. The old condition was
  `get_provisions() <= 0`, so buying *exactly* what the planner asked for
  landed on zero after the last meal and took the famine penalty (-10
  morale, +6 stress) on every single journey. Measured across 16
  day/party combinations: 16 of 16 starved. It is the reason arrival morale
  sat around 55 - a hidden per-journey tax that made morale look tuned when
  it was not.
- The culture perk (`daily_provision_multiplier`) and the Levazımcı's
  `get_duty_flat_reduction()` both go through the shared formula, so the
  planner shows the number the road will actually eat. Consumption never
  drops below 1 no matter how good the perks are.
- `tests/test_provisions.gd` locks all of it: plan and road agree across
  party/wagon/merchant combinations, correct stocking never starves at any
  journey length, an under-stocked caravan does starve (one unit short is
  already famine), each wagon adds exactly `PEOPLE_PER_WAGON` mouths, and
  the perks reach the planner.
- **Setting out under-stocked is a risk, not a wall.** The planner used to
  disable "Confirm" outright when the plan was short - a playtest read
  this correctly: *"can we settle for it anyway, but tell the player about
  the risk"*. A game whose whole point is attrition should let the player
  choose to gamble. `CaravanPlan.get_hungry_days()` computes the exact
  count the road will actually charge (same formula, so the number is a
  fact, not an estimate) and the confirm button arms in two presses - the
  first names the cost, the second commits - the same shape as a
  destructive confirm anywhere else in the UI, and consistent with no
  other screen in the game using a checkbox for this.

**The simulator's "net kazanç" is contract income only** - trading profit
(buy cheap, sell where it's demanded) is not in it, and in real play that is
where most of the money is: `playthrough_demo.gd` turns 98 gold of cloth
into 294. Reading that line as "the game barely breaks even" repeats the
morale measurement mistake. The demo now sells as well as buys; for a long
time it only bought, so its economy print showed the cost of trading and
none of the profit.

### Morale Rules

Morale was a dead stat for a long time: it started at 100 on every journey,
fell only through discrete event hits, and never reached `evt_mutiny`'s
threshold. Worse, nobody noticed, because the balance simulator read
`caravan.morale` *after* `finish_journey()` - which resets the caravan - so
the report said exactly 100.0 every run.

- **Morale is that journey's mood; stress is the caravan's permanent wear.**
  They stay separate stats (see Stress Rules). Stress *influences* the
  morale a journey starts with; it is never spent or converted.
- **The road itself wears you down.** `CaravanState.apply_daily_drift()`
  takes `MORALE_DRAIN_PER_DAY` every day on the road, so a long journey is
  genuinely more tiring than a short one. It stops at
  `MORALE_DRIFT_FLOOR` - walking alone must never be enough to trigger a
  mutiny; events have to go badly too.
- **That rule only became true when the floor moved above the threshold.**
  The floor was 35 and the mutiny threshold 40, so a long enough road made
  mutiny eligible with nothing happening at all - and `test_morale.gd`
  asserted the inverse (`threshold > floor`) with a message describing the
  opposite of what it checked. The floor is now 45, above the threshold, and
  the test asserts that drift alone can never reach mutiny while an event
  hit still can.
- **`ROAD_STRESS_PER_DAY` is the stress counterpart of the morale drain**,
  and it exists because fixing the famine bug (see Provision Rules) removed
  a hidden per-day stress tax that the whole stress-accumulation balance had
  been resting on. Arrival stress fell from ~25 to ~8 the moment famine
  stopped firing on correctly provisioned journeys, which quietly undid
  "stress accumulates across journeys". The road now charges it honestly.
- **Departure morale reflects the world, not a constant.**
  `GameSession.get_departure_morale()` composes it from systems that already
  exist rather than inventing a "war/plague" mechanic: hardship
  (`MarketConditions.get_hardship` - season, price shocks, inflation; famine,
  embargo and strikes are all already modelled as `MARKET_SHOCK`), party
  stress, overdue debt, and reputation as a small pride bonus. It never
  drops below `DEPARTURE_MORALE_FLOOR` - a caravan sets out weary, never
  hopeless.
- **The number is shown with its reasons.**
  `get_departure_morale_breakdown()` feeds the planner screen; an invisible
  penalty is indistinguishable from a bug to the player.
- **Eligibility is not enough - a crisis has to win the weighted draw.**
  Lowering the mutiny threshold to 40 made it eligible on 45 simulated days
  and it still fired zero times, losing every draw to ~25 rivals. It needed
  an `EventWeightModifier` (×8 below the threshold) before it appeared at
  all. When an event is "in the catalog but not in the game", check the
  draw, not just the condition.

### Economy Rules

- **Profit is not only the price gap between cities.** `MarketPricing` holds
  the base table (a city sells what it produces cheap, pays well for what it
  demands); `MarketConditions` layers inflation, season, supply-and-demand
  pressure and economic/political shocks on top and multiplies the base.
  Passing no conditions yields the old, purely positional behaviour.
- **Supply and demand is what stops a single route being farmed forever.**
  Buying pushes that good's price up in that city; selling pushes it down;
  the pressure decays back toward baseline over the following days. Any new
  trade path must go through `consume_stock`/`record_sale` or it silently
  bypasses this.
- `EventEffect.Type.MARKET_SHOCK` is how a strike, famine, embargo or good
  harvest moves prices for a while.
- **An effect that moves a number without showing why is indistinguishable
  from an unbalanced price table.** `add_shock()` always carried a
  `label_key` and `get_active_shocks()` always existed, but nothing ever
  called either - a shock changed the price a market screen displayed and
  said nothing about it. `MarketConditions.is_shocked()` is the one door
  `market.gd` reads to mark an affected row (`UI_MARKET_SHOCK_MARK`,
  refreshed alongside the price on every buy/sell/haggle), same rule as
  weather being shown because a hidden penalty is indistinguishable from a
  bug.
- **Weight binds, not just slots.** The limit lives in `Inventory.add_item`
  itself, so an event reward obeys it exactly like a market purchase - when
  only the market screen checked it, everything else leaked through.
  Provisions are exempt (they have their own journey formula and must not
  eat cargo space), and the ceiling tracks `owned_wagon_count`.
- Every number in these tables is a placeholder to be tuned.

### Kervan Envanteri Rules

The cargo hold used to be one shared `Inventory` for the whole caravan, with
a single weight ceiling that scaled with `owned_wagon_count`. Faz 15 split
it the way the game's own vocabulary already implied - a caravan is
*wagons*, plural - and added a small personal buffer and a workshop that
turns materials into other materials, per the #22 backlog note above.

- **Cargo lives per wagon, not in one pool.** `GameSession.wagon_inventories:
  Array[Inventory]` is `owned_wagon_count` long; `_sync_wagon_inventories()`
  keeps it in step with the fleet - buying a wagon appends a fresh, empty
  `Inventory` (weight limit `CARGO_PER_WAGON`, same as before), losing or
  selling one pops the last entry and tries to pour its cargo into the
  wagons that remain. Provisions stay exempt from weight in every wagon,
  the same rule as before, just applied per-wagon instead of once.
- **A stack does not have to fit one wagon, only the fleet.** `add_to_cargo()`
  plans how much each wagon can still take (`Inventory.get_max_addable`,
  which reads but does not mutate) before committing anything - a purchase
  that doesn't fit in any single wagon but fits split across two still
  succeeds. It is deliberately all-or-nothing: if the *total* doesn't fit,
  nothing is written to any wagon, because a partially-applied purchase
  would need to explain itself twice.
- **A character carries a small, limited bag of their own.**
  `CharacterData.personal_inventory` (`PERSONAL_BAG_CAPACITY`, a tenth of a
  wagon) is outside the wagon system entirely. Its one job is to catch a
  small windfall the wagons have no room for (`add_to_cargo_or_bag()`,
  read by event loot) so a good roll doesn't vanish for a reason the player
  never sees - the same "a hidden penalty is a bug" reasoning Economy Rules
  already states for market shocks. Market purchases and haggling
  deliberately do **not** call this - there, "kargo dolu" has to stay a
  visible message, not a silent slide into someone's pocket.
- **The city sees one number: the sum.** `get_total_quantity()`/
  `get_total_inventory_entries()` merge every wagon and every party
  member's bag into the single total the market screen, the road's cargo
  dump and the trading AI all read - "vagonlarımızın ve çantamızın
  toplamı," in the player's own words. Nothing reads a single wagon
  directly outside `GameSession` itself; `remove_from_cargo_or_bags()`
  drains the wagons first and only reaches into bags once they're empty,
  so a sale never surprises the player by emptying a companion's pocket
  while a wagon still has stock.
- **A wagon lost to the road can really lose its cargo; a wagon sold
  cannot.** `sell_wagon()` is already gated on the remaining fleet having
  room for everything (`get_wagon_sale_block_reason`), so redistribution on
  a sale always succeeds. A wagon lost in combat or an event carries no
  such guarantee - whatever doesn't fit in the wagons that survive is
  gone with it, the same "the caravan can be ruined" stakes Ruin Rules
  already applies to the wagon itself.
- **Atölye (Workshop) lives at the wagon, not in a city screen - and it
  reads only that wagon.** This was gotten wrong once and corrected: a
  first pass bolted a "Workshop" button onto `caravan_yard.gd` reading the
  caravan's aggregate total, which has nothing to do with what was asked
  for. The real design: every wagon is its own interaction spot in
  `world_hub.gd` (previously only wagon 0 was, back when cargo was one
  shared pool - see World Navigation Rules' own note on that stale
  comment), walked up to and clicked/E'd exactly like the city gate.
  Interacting opens `WagonPanel` (`MealDistributionPanel`'s scene-less
  `CanvasLayer` pattern, not a scene change - this is standing at a wagon,
  not navigating anywhere) showing **that wagon's own inventory** and a
  Rust-simple craft menu that reads and writes **only that wagon's**
  `Inventory`, never the caravan's total. `CraftingRecipe` (a resource:
  inputs, an output item *or* a wagon-repair effect) and the static
  `RecipeCatalog` are the whole vocabulary; three recipes ship
  (`craft_bandage`: cloth → bandage; `repair_wagon_canvas`: cloth → wagon
  damage -1, a material-priced alternative to the Kervan Avlusu's gold
  repair; `dismantle_to_bandage`: fur → two bandages, the "dismantle" verb
  the player asked for). `GameSession.craft_in_wagon(wagon_index, recipe_id)`
  consumes inputs from that one `wagon_inventories[wagon_index]` and writes
  its output back into it (falling back to `add_to_cargo_or_bag()` only if
  that exact wagon has no room for the output, so a craft never destroys
  what it just made) - this is the part of the #22 design note that
  actually matters: cloth left in the wrong wagon genuinely cannot be
  turned into a bandage at a different one, so which vagon carries what is
  now a real decision, not flavour text. A recipe that cannot be made yet
  is **disabled with its reason** (`get_craft_block_reason_in_wagon()`),
  the same rule as a locked event choice, a locked skill or a locked
  equipment tier - never hidden.
- **What #22's own design note asked for and did not get:** a read-only
  view into a *foreign* trader's wagon, and a dedicated "Kervan Yükü"
  screen for placing cargo wagon-by-wagon on purpose ahead of time (rather
  than discovering the split by walking up to each wagon). Neither exists
  yet. Either is a real follow-up, not a rejection.
- `tests/test_wagon_inventory.gd` locks the load-bearing claims: each wagon
  keeps its own weight ceiling, a stack splits across wagons when it must,
  an over-total request touches no wagon, selling a wagon never loses
  cargo while losing one can, the personal bag catches overflow but market
  purchases never route to it, removal drains wagons before bags, the
  save round-trip preserves the split and the bags, a pre-Faz-15 save's
  single flat `inventory` list still loads (poured through `add_to_cargo`),
  each of the three recipes with their block reasons, and - the point of
  the whole redesign - that a recipe craftable in one wagon is correctly
  *not* craftable in another wagon holding no materials at all.

### Haggling Rules

`HagglingSession` is the closest thing the game has to a money printer, and
the same trap was walked into twice, so the invariants matter more than the
numbers.

1. **First design:** the acceptance threshold slid toward the absolute
   minimum as patience fell, and the fastest way to burn patience was an
   insulting lowball - so enraging the merchant was *rewarded*.
2. **Second design:** the threshold never went below the floor and the floor
   hardened per rejection. The exploit was closed, but both the threshold
   and the floor were functions of **`rounds_used` alone** - so how you
   haggled did not matter, only how many times you were refused, and the two
   curves always met at the same number.

**Current design - the path is what matters.**

- **Offers are a countable resource** (`MAX_ROUNDS`, three), shown on screen.
  No hidden curve to reverse-engineer by trial and error.
- **The merchant concedes only after an offer he takes seriously**
  (`is_credible`, `concessions`). A lowball burns a round without moving him,
  which is precisely why "repeat the same bottom offer three times" cannot
  work. `get_acceptable_threshold()` interpolates on `concessions`, never on
  `rounds_used`.
- **Every rejection still hardens the floor** (`FLOOR_HARDEN_PER_ROUND`), so
  dragging it out costs you room even when your offers are credible.
- **Out of offers, the merchant issues an ultimatum: pay list price or
  leave.** `has_final_offer_perk` softens the ultimatum to his current floor
  rather than list price - valuable, but still worse than spending the three
  rounds well, which `tests/test_haggling.gd` asserts directly.
- **Walking out costs a little reputation** (`WALKOUT_REPUTATION_PENALTY`,
  1). Deliberately small: without any cost, "lowball until it breaks, then
  reopen" is a free retry loop, but a broken negotiation should be a price,
  not a disaster. The panel hands the penalty to whoever opened it
  (`HagglingPanel.haggling_failed`) and each screen decides: a city
  merchant's anger is heard around town (`market.gd`), a roadside bandit's is
  not (`road_journey.gd`, which charges the full toll instead - through
  `spend_or_owe`, so being broke is not an escape).
- **Skill is read from the party, not hardcoded.** Callers pass
  `get_best_effective_stat()` for Zeka and Karizma; those widen the floor.
  Passing literal zeros (as both screens once did) made the whole mini-game
  character-blind.

The resulting gradient on a 135 list price (base 100, greed 0.5, rep 0.3):
cautious play takes ~116 in round one, aiming play walks 116 → 99 → 83, and
greedy play hits the ultimatum and pays 135 or leaves. A master talker
(Zeka/Karizma maxed, trusted) pays 68 against a list of 100.

### Event Character Rules

Who you are travelling with, and who you meet, changes what an event does.

- **People met on the road carry a hidden disposition** (`NpcDisposition`:
  loyal / desperate / thief / vengeful). `EventEffect.Type.ROLL_ENCOUNTER`
  rolls it into a flag and outcomes branch on that flag with
  `EventCondition.HAS_FLAG`. The player is not told which - a party member
  with strong Sezgi only gets a *hint*.
- **The bill need not come due immediately.** Turning away a vengeful
  traveller sets a flag and unlocks a `triggered_only` chain event that
  fires days later (`evt_wanderer_revenge`). This is the pattern for any
  "that decision comes back to you" design.
  The balance simulator reports this event as never firing; that is a
  limitation of the simulator, not a bug. Its policy is "take the first
  available choice", so it always takes the traveller in and never opens the
  chain. `test_event_effects.gd` exercises the chain end to end instead -
  when a report says an event never fires, check whether anything in the
  harness could ever reach it before treating it as dead content.
- **Culture kinship is not one culture's privilege.** `ROLL_ENCOUNTER` also
  rolls the met group's culture and sets a `<prefix>_kin` flag when it
  matches the *leader's* culture, so meeting your own people works whichever
  culture you chose (`evt_kin_encounter`, which replaced the Nomad-only
  version).
- **Party capability gates choices.** All six duty holders plus
  `best_perception` / `best_charisma` are in the event context, so an
  outcome can ask "is there a quartermaster who would have caught this
  early?" or "is there anyone here who could talk them down?" - see
  `evt_spoiled_provisions` and `evt_mutiny`'s manipulate option.

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
screen read as broken — *"we're standing still, we have no control."*

- **The player walks the road; the clock only counts days.** A/D or the
  arrow keys drive `_days_covered` in `road_journey.gd`; standing still
  stops the *distance*, never the day. Provisions are still eaten,
  contracts still expire, the day's event still fires. Dawdling is paid for
  by the calendar — that is the whole Oregon Trail tension, and it did not
  exist while arrival was a timer.
- **Walking forward at full tempo reproduces the old behaviour exactly**
  (`WALK_FORWARD_RATE` 1.0), so the planner's provision promise — *correct
  stocking never starves* (see Provision Rules) — still holds for a player
  who simply walks. The only thing that broke is idling being free.
- **Going back is much slower than going forward** (`WALK_BACKWARD_RATE`
  0.25): turning a wagon train around on a narrow road costs real time.
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
within a save (there is no mid-journey save, so this opens no re-roll
door), different for every new journey. Check what a debug control feeds
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
- **A multi-line translation becomes one line in a bar.** `UI_ROAD_STATE`
  is three lines by design (the city screens want it that way); the road
  HUD joins them with " · " at display time rather than splitting the key.
- `tests/screenshot_journey_screen.gd` photographs **the real scene** with a
  live session, not a hand-built band - the other screenshot tools show the
  landscape but cannot show the layout, and the layout was the complaint.
- **The thin HUD is deliberate, but it means the kervanın detayı has to
  live somewhere.** A playtest asked for exactly that - *"a detailed 'My
  Caravan Status' tab"*, then *"status, map, inventory, contracts"*
  buttons. `CaravanStatusPanel` (`scripts/ui/`) is the one answer to
  both: a `Tab`-toggled layer over the road (fifth stacked layer,
  `StatusOverlay`, between `LogOverlay` and `Modal`) that reads the
  session and shows the kadro, wagons, provisions/gold/debt, cargo,
  carried contracts and the ledger's last lines - **never decides
  anything**, same rule as `CityBriefPanel`. It is scene-less
  (`.new()` + `setup()`), and `setup()` can be called before the road's
  real session exists (`_build_ui()` runs before `_init_journey()`
  assigns `_session`) - `set_session()` is the second call that actually
  fills it, once the session is real.

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

### Reputation Rules

Reputation had **six ways down and none that the player controlled**:
undelivered contracts, overdue debt, fighting the watch, being caught at
customs, walking out of a haggle, and events. The caravan's actual job -
delivering the contract it accepted - paid nothing. So the number only
ever fell, and the career simulation had already measured the result
(average reputation ~1 at journey 20) without anyone reading it as a bug.

- **Delivering pays.** `REPUTATION_PER_DELIVERED_CONTRACT` is granted in
  `finish_journey()`, per merchant actually delivered. With the loss per
  undelivered contract dropped to 3, a caravan that lands three of four is
  net positive - playing well now moves the stat that gates the game.
- **`change_reputation()` is the only door**, and the floor
  (`MIN_REPUTATION`) lives in it. The simulator once produced a caravan at
  -44: past that point every door is shut and the player holds no lever
  that opens one, which is a silent game over rather than a hard game.
- **The cheapest hiring venue never closes.** Meydan and taverna both asked
  for reputation 0, so a single bad journey locked *every* way to rebuild a
  crew at once. The people waiting in a market square are the ones without
  work; a caravan with a bad name loses the guild, not the square.
- **A reward nobody sees is a reward that doesn't feel like playing well.**
  Delivery pays reputation and happens automatically on arrival - there is
  deliberately no "deliver" button (see Event Engine Rules, City Hub
  Rules). But the arrival summary and the guild board never *said* either
  of those things, so a playtest asked where the delivery screen was and
  reported that arriving felt no different from failing. The arrival
  summary now names the delivered count and the reputation gained, and the
  guild's accepted-contracts list carries one line saying delivery happens
  the moment the caravan reaches the destination - the same rule as every
  other screen having to name the mechanic it's leaning on.

### Playthrough Start Rules

- **The opening is fixed and not offered as a choice**: two party members
  (the player plus one randomly rolled companion), one wagon, a random
  starting city - see `GameSession.start_playthrough()`. One wagon is
  exactly two party slots, so the roster starts full; a third member is
  only possible after buying a wagon.
- The companion comes from `RecruitCatalog.build_starting_companion()`,
  which reuses the normal candidate generator rather than duplicating the
  randomization.
- `tests/playthrough_demo.gd` runs the whole loop headless (market,
  contracts, travel with the real clock, events, arrival) and prints a
  readable log. Like `simulate_journeys.gd` it is **not** a test - it never
  fails, it shows whether the game actually loops. It mirrors the road
  screen's `_process` order deliberately, so what it verifies is what the
  screen does.

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
- **There is still no mid-journey save**, and the multi-slot system did not
  relax that: `to_save_dict()` never carried `journey_*` fields (see
  `SaveManager`'s own header comment), so writing to any slot while
  `is_journey_active()` is true would silently drop the journey. Every
  screen that can save passes `can_save` down instead of hiding the
  question - `SaveSlotsPanel` shows the reason
  (`UI_SAVES_CANT_SAVE_JOURNEY`) rather than just omitting the button, the
  same "disabled with its reason" rule as a locked event choice or a locked
  combat skill.
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
  against `ThemeDB.fallback_font.has_char()`. The one exemption is
  `UserSettings.SUPPORTED`'s language names (`user_settings.gd`): they
  must stay in their own script (see the exemption above) even where CJK
  isn't renderable yet, so `settings.gd` appends the locale code next to
  an unrenderable name instead of hiding the option - a language you
  can't read the name of should still be one you can find by its code.

- **scripts/ui/**: User interface scripts
  - Menu controllers
  - HUD management
  - Popup dialogs

- **scripts/autoload/**: Global singleton scripts (configured in project settings)
  - `GameState` (registered autoload): holds the persistent `GameSession`
  - `GameSession` (plain RefCounted): wallet, inventory, caravan, flags,
    reputation, journey — instantiable in tests without touching the autoload
  - There is deliberately **no signal bus.** `EventBus` was an autoload with
    four signals, five `emit()` sites and **zero listeners** — nothing ever
    connected to it, in script or in any `.tscn`. It could not have had a
    durable listener either: navigation is `change_scene_to_file()`, so every
    screen that might subscribe is freed on the next scene change, and the
    only long-lived objects are the autoloads themselves. Screens read
    `GameState.get_session()` directly. Don't reintroduce a bus without a
    subscriber that actually outlives a scene.
  - `DevPanel` (registered autoload): F1 geliştirici menüsü. `test_selector.tscn`'i
    çalışma anında `load()` ile kurup bir CanvasLayer'a gizli ekler; F1 açıp
    kapatır. Bir hedefe geçerken gezinme yığınına *o anki* sahneyi iter, o
    yüzden hedefin geri tuşu paneli açtığın yere döner, panele değil.
  - `SaveManager` (registered autoload): `GameSession.to_save_dict()` /
    `load_from_dict()` içeriği bilir, burada yalnızca `user://save.json`
    G/Ç'si var. Yalnızca şehir varışında (`finish_journey()` sonrası)
    çağrılır - sefer/kervan alanları o an her zaman sıfırlanmış olduğu
    için hiç serileştirilmez. `GameSession`'ı `load()` ile kurup normal
    örnek metodu çağırır, hiçbir yerde `class_name` ile anmaz.
  - `AudioManager` (registered autoload): music crossfade, ambience and
    one-shot SFX - see Audio Rules and Title Screen Rules.

**Autoload rule:** never reference a `class_name` inside an autoload script —
not in a type annotation, not in a body. Autoloads are parsed before the global
script class cache is ready, so `var x: GameSession` or `GameSession.new()`
fails with *"Could not find type"* and the autoload silently never instantiates
(the build still reports success — check the CI import log for
`Failed to create an autoload`).

`preload()` does **not** fix this: it resolves at compile time, so the failure
just moves down into the preloaded script's own `class_name` references. Use
runtime `load("res://…")` inside a function and construct lazily on first
access. Leave signal parameters untyped (their types are documentation only in
GDScript) and note the intended type in a comment.

**The `:=` / Variant trap.** Not just `load()` - any expression the static
checker can't type (a `for` loop over a plain `Array` returned by
`Array.duplicate()`, a value from `Dictionary.get()`, anything untyped)
makes `:=` fail to parse with `Cannot infer the type of "x" variable`. This
has broken a shipped-green build repeatedly (`city_map.gd`, `run_tests.gd`,
`simulate_journeys.gd`, `resolve_stress_breaks()`) because Godot's own
parser still prints `SCRIPT ERROR` and exits 0 - only the CI log grep
catches it. Fix by giving the *source* value an explicit type before the
loop/assignment (`var typed: Array[CharacterData] = untyped_result`), not by
chasing every downstream `:=` that happens to fail.

**Lambdas capture outer locals by value, not by reference.** A lambda
connected to a signal (`signal.connect(func(x): outer_flag = true)`)
reassigns its own private copy of `outer_flag`, not the enclosing
function's variable - reading `outer_flag` afterwards still sees the old
value. This silently made an early draft of `test_stress.gd`'s refusal test
pass/fail on a value that never actually changed. Capture a reference type
instead - a one-element `Array` used as a shared box (`var flag := [false]`,
mutate `flag[0]` inside the lambda) is the standard GDScript workaround.

- **data/config/**: Game configuration files
  - `game_config.json`: Game-wide settings
  - `enemy_data.json`: Enemy definitions
  - `quest_data.json`: Quest definitions

- **data/assets/**: Game assets
  - Sprite sheets
  - Audio files
  - Fonts
  - UI textures

## Coding Standards

### GDScript Style Guide

#### Naming Conventions
- **Classes**: `PascalCase` (e.g., `PlayerController`, `EnemySpawner`)
- **Functions**: `snake_case` (e.g., `take_damage()`, `calculate_loot()`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `MAX_HEALTH`, `SPAWN_RATE`)
- **Variables**: `snake_case` (e.g., `player_health`, `current_scene`)
- **Private members**: Prefix with `_` (e.g., `_internal_state`, `_update_visuals()`)

#### Class Structure
```gdscript
extends Node

# Constants at top
const DAMAGE_MULTIPLIER = 1.5
const MAX_ATTEMPTS = 3

# Properties/variables
var health: int = 100
var _is_alive: bool = true
var _animation_speed: float = 1.0

# Exported variables for editor
@export var base_damage: float = 10.0
@export var attack_range: float = 50.0

# Signals
signal health_changed(new_health)
signal died

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

# Public methods
func take_damage(amount: int) -> void:
	pass

# Private methods (leading underscore)
func _update_visuals() -> void:
	pass
```

#### Type Hints
- Always use type hints for clarity
- ✅ `func calculate_damage(base: float) -> float:`
- ❌ `func calculate_damage(base):`

#### Comments
- Only comment the "why", not the "what"
- Self-documenting code is preferred
- Avoid redundant comments

```gdscript
# ✅ Good - explains intent
func apply_knockback(direction: Vector2) -> void:
	# Knockback scales with impact force to feel more dynamic
	velocity = direction * impact_force * 2.0

# ❌ Avoid - restates code
func apply_knockback(direction: Vector2) -> void:
	# Set velocity to direction times impact force times 2
	velocity = direction * impact_force * 2.0
```

### Project Best Practices

#### Scene Management
- Keep scenes focused and modular
- Use inheritance for shared behavior
- Prefer composition over deep hierarchies

#### Script Organization
- One public class per file (match filename to class name)
- Keep functions < 30 lines
- Extract complex logic into helper functions

#### Signal Usage
- Define signals at script top after constants
- Use descriptive signal names: `health_changed`, `item_picked_up`
- Emit signals for state changes only

#### Resource Loading
- Use `preload()` for scenes/resources known at edit time
- Use `load()` for dynamic runtime loading
- Cache loaded resources when reused

```gdscript
# ✅ Preload at top
var enemy_scene = preload("res://scenes/enemy.tscn")

# ❌ Load every time
var enemy_scene = load("res://scenes/enemy.tscn")
```

#### Error Handling
- Check for null returns: `assert(resource != null, "Missing resource")`
- Validate input parameters
- Log meaningful error messages

```gdscript
func load_enemy_data(enemy_id: int) -> Dictionary:
	var data = _load_json("res://data/enemies.json")
	assert(data != null, "Failed to load enemy data")
	assert(enemy_id in data, "Unknown enemy: %d" % enemy_id)
	return data[enemy_id]
```

### Performance Tips

1. **Avoid dynamic typing** - Use type hints for better performance
2. **Cache references** - Store frequently accessed nodes/resources
3. **Use object pooling** - Reuse bullets, enemies, effects instead of creating/destroying
4. **Optimize physics** - Use AABB checks before expensive collision tests
5. **Profile before optimizing** - Use Godot's profiler to identify bottlenecks

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
- `test_route_terrain.gd` locks the road's geography and weather: both
  reproducible from a seed, segments covering the whole route with no gaps,
  biomes never jumping, stops never landing on the destination city, clear
  weather exactly neutral, every lever inside its range, the biome bias
  actually biasing (the overwhelming-margin pattern again), the visuals
  agreeing with the mechanics (the slowest weather is also the darkest), and
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
  `screenshot_road_encounter`, `screenshot_menu` — the last one exists
  because the main menu was the only screen never drawn at all, four
  buttons on flat grey, and no assertion anywhere could say so). They
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
  where gold, reputation, wagons and campaign chapters land (see Campaign
  Rules for the numbers). Anything about progression over time needs the
  second tool; the first cannot see it, which is exactly why the campaign
  thresholds shipped unmeasured the first time.
- **A balance report needs more than one policy, for the same reason ruin
  tuning needed two knobs.** `simulate_career.gd` runs three — expand
  aggressively, stay lean and haul contracts, and follow the campaign — and
  the first two disagree so sharply (11 contracts delivered vs 41) that
  either one alone would have given a confidently wrong answer.

**CI is the real gate.** Godot prints parse errors and still exits `0`, so a
broken script hid under a green build twice (`city_map.gd`,
`ClassCatalog.get_class`). `.github/workflows/deploy.yml` now tees every Godot
invocation to a log and fails the job on `SCRIPT ERROR`, `Parse Error`,
`Compile Error`, `Failed to load script` or `Failed to create an autoload`.
Never remove that step to make a build pass.

## CI/CD & Deployment

### GitHub Actions Workflow

The project uses GitHub Actions to automatically export and deploy the game:

- **Trigger**: Push to `main` branch
- **Actions**:
  1. Checkout code
  2. Setup Godot 4.2.2
  3. Import Godot project
  4. Export to HTML5 (Web)
  5. Deploy to GitHub Pages

### GitHub Pages Setup

To enable GitHub Pages deployment:

1. Go to **Settings** → **Pages**
2. Set **Source** to `GitHub Actions`
3. Workflow will automatically deploy on each `main` push

### Export Presets

Web export is configured in `export_presets.cfg`:
- Platform: HTML5/Web
- Output: `build/web/index.html`
- Features: WASM, streaming enabled, threading disabled

### Cross-Origin Isolation (GitHub Pages)

Godot's Web export requires `crossOriginIsolated`/`SharedArrayBuffer`
unconditionally (this check is baked into the export template itself,
regardless of the `web/enable_threading` setting). GitHub Pages cannot
send the `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy`
headers this needs, since it's static hosting with no custom header
support.

The deploy workflow (`.github/workflows/deploy.yml`) works around this by
copying `web/coi-serviceworker.js` into the export output and injecting a
`<script>` tag into `index.html`'s `<head>` after export. This service
worker intercepts same-origin fetches and injects the required headers
client-side, then triggers one page reload so the isolated context takes
effect. Do not remove this step unless GitHub Pages gains custom header
support or the game is hosted somewhere that can send these headers
directly.

### Local Testing

To export locally:
```bash
godot --headless --export-release Web build/web/index.html
```

Then serve with:
```bash
python -m http.server 8000 -d build/web
```

Visit `http://localhost:8000` in browser.

## Development Status

Faz 0-3 tamamlandı. Oyun bir tur dönüyor (kazanç ödeniyor, harita tam
bağlı, fiyat şehre göre değişiyor, kargo kapasitesi var), test iskelesi
oyuna çevrildi (`scenes/game/`, F1 dev paneli), ilerleme kalıcı
(`SaveManager`), şehrin dört lokasyonu artık gerçek ekranlar - kart
tabanlı değil, her biri kendi kararını taşıyor:

- **Pazar Meydanı** (`market.gd`): şehir başına stok sınırı
  (`Location.stock_per_item` / `GameSession.market_stock`, her varışta
  dolar), miktar seçili toptan alım, `HagglingPanel` üzerinden bulk
  pazarlık.
- **Tüccar Loncası** (`guild.gd`): kontrat panosu. Teklifler artık
  statik veri değil, `GameSession.accepted_contracts`'ta tutulan
  oturum durumu - kabul edilince panodan kalkar, sefere çıkılmadan
  süresi geçerse (`MerchantOffer.contract_deadline_days`, `advance_day()`)
  ya da yolda teslim edilemezse (`CaravanState.original_merchant_names`,
  `finish_journey()`) itibar cezası uygulanır. Büyük kontratlar itibar
  ister (`required_reputation`).
- **Taverna** (`tavern.gd`): rota dedikodusu. `GameSession.known_routes`
  öğrenilmedikçe dünya haritası tehlikeyi yalnızca kaba bir bant
  (düşük/orta/yüksek) gösterir, tam yüzde parayla öğrenilir.
- **Kervan Avlusu** (`caravan_yard.gd`): vagon onarımı ve alımı.
  Oyuncu artık kalıcı olarak vagon sahibi (`GameSession.owned_wagon_count`
  / `owned_wagon_damaged`, karakter oluşturmada tayfa sayısından
  hesaplanır);
  sefer sırasındaki kayıp/hasar escort vagonlarına öncelikli uygulanıp
  varışta sahipliğe taşınır (bkz. `_apply_wagon_losses_to_ownership`).

Faz 4 (karakter + combat) tamamlandı. Oyuna artık bir "sen" girdi:

- **Karakter oluşturma** (`character_creation.gd`, `Nav.CHARACTER_CREATION`):
  kültür, isim (kültür havuzundan rastgele ya da elle), boy, ten rengi,
  6 stata dağıtılan puan ve tayfa büyüklüğü. Ana menüdeki "Yeni Oyun"
  artık doğrudan oyunu başlatmıyor, buraya getiriyor; kayıt yalnızca
  bu ekran tamamlanınca siliniyor.
- **Combat** (`scripts/combat/`, `CombatPanel`): Darkest Dungeon tarzı,
  4 mevkilik iki saf, inisiyatif sırası, mevki kilitli yetenekler.
  Haydut pususunun "Direnç göster" seçeneği artık zar atmıyor, gerçek
  savaşı açıyor (`TRIGGER_COMBAT`). F1 panelindeki "combat" girişi de
  bağlandı (`scenes/game/combat.tscn`).
- **Tayfa toplama** (`RecruitCatalog`, `RecruitPanel`, `recruit.gd`):
  meydan/taverna/lonca aynı ekranı farklı havuz ve fiyatla açar
  (`Nav.recruit_venue`), lonca itibar ister. Yolda da bir aday çıkabilir
  (`evt_road_wanderer` → `TRIGGER_RECRUIT`).

Faz 5 (güvenlik ağı) tamamlandı: CI artık her push/PR'da testleri koşturup
Godot'un sessizce geçtiği ayrıştırma hatalarını yakalıyor (`tests.yml`),
314 doğrulamalık yedi paket ve `simulate_journeys.gd` denge simülatörü var.

Faz 6 ("Karakterin Yolculuğu") tamamlandı - dört PR'lık bir hat:

- **PR-A (veri katmanı)** stat tavanını 15'e çıkardı ve 10 üstünü
  yavaşlattı (`CharacterStats.get_effective_value`), XP/seviye eğrisini,
  dört sınıfı (Sıra Neferi/Sekban/Kırıkçı/Kalem Efendisi) ve on iki yeni
  yeteneği, süreli stat değiştiricileri (`CombatSkill.modifier_*`),
  yetkinlik (per-skill continuous investment) ve altı kervan görevini
  (`Duty`/`DutyCatalog`) getirdi - dördü (Muhafız/Levazımcı/Arabacı/Tellal)
  canlı sistemlere bağlandı, Otacı PR-D'nin kamp/stres sistemine bağlandı;
  İzci hâlâ katalogda hazır ama bağlanmadı (ev sistemi
  `caravan_planner.gd`/`world_map.gd`, henüz okunmadı).
- **PR-B (karakter ekranı)** bu veri katmanını ilk kez oynanabilir kıldı:
  yeni `Nav.CHARACTER` ekranı (stat/yetkinlik yatırımı, görev ataması,
  multiclass, Faz 7'ye kilitli ekipman yer tutucuları), karakter
  oluşturmada sınıf seçimi, seviyeli/sınıflı tayfa adayları.
- **PR-C (huylar + Kilise)** on iki huy (`Trait`/`TraitCatalog`, her stat
  için bir olumlu bir olumsuz), karakter kurulurken statlarla orantılı
  ağırlıklı seed huy (`roll_seed_trait`), `EventEffect.Type.GRANT_TRAIT`
  (ilk kullanımı `evt_troubled_night`) ve yalnızca beş gün içinde
  kazanılmış ("taze") huyları silen `PurificationPanel`'i getirdi -
  Taverna'da pahalı, yeni Kilise'de (`Nav.CHURCH`) ucuz.
- **PR-D (stres/moral döngüsü + kamp)** `GameSession.party_stress`'i
  (bkz. Stress Rules) getirdi: dayanıklılığa göre kişisel kırılma direnci,
  şehir varışında toplu kırılma zarı (`resolve_stress_breaks` - çoğunlukla
  huy, nadiren tam tersi, ağır kırılan bir yoldaş kervandan ayrılabilir),
  savaşta emir reddi (`CombatUnit.is_stressed`), yolda yeni bir "Kamp Kur"
  eylemi (`GameSession.make_camp`) ve yüksek stresin kendi olayını
  (`evt_stress_brawl`) açması. `world_hub.gd`'nin HUD'una moral ve stresi
  gösteren iki `PulseBar` eklendi.

Faz 7 ("Kervanın Donanımı") tamamlandı - dört PR'lık bir hat:

- **PR-A (equipment veri katmanı)** dört slotu (Silah/Zırh/Yüzük/Kolye,
  `EquipmentCatalog.SLOT_*`) ve on iki parçayı getirdi: Silah/Zırh üçer
  tier'lik kalıcı yükseltme (yalnızca pozitif bonus), Yüzük/Kolye üçer
  DD trinket'i tarzı ödünlü tılsım (bir stat artar, biri düşer). Bonus
  alanları `Trait`'inkiyle birebir aynı isimlerde - `CharacterData.
  get_max_hp()/get_dodge()/get_accuracy()/get_crit_chance()/
  get_damage_bonus()` huy bonusunun yanına `_equipment_bonus_sum`'ı da
  topluyor, `CombatUnit.from_character` hiç değişmeden bunu otomatik görür.
- **PR-B (equipment UI + edinim)** `character.gd`'nin dört kilitli
  placeholder slotunu gerçek bir equip paneline çevirdi. `GameSession.
  equipment_inventory` kimseye takılmamış parçaların ortak deposu
  (`Inventory`'nin item_id->miktar deseninin karşılığı);
  `equip_to_character()`/`unequip_from_character()` karakterle depo
  arasındaki transferi tek yerde topluyor. Kervan Avlusu'na "Demirci"
  bölümü eklendi (Silah/Zırh parayla satılıyor); `EventEffect.Type.
  GRANT_EQUIPMENT` bulunan parçayı - `GRANT_TRAIT`'in aksine - doğrudan
  bir karaktere değil depoya yazıyor, çünkü ekipman hangi karaktere
  takılacağı seçilene kadar nötr kalmalı.
- **PR-C (İzci + olay havuzu)** altı görevin son bağlanmayanını
  (`DutyCatalog.IZCI`) canlı sistemlere bağladı: `world_map.gd` İzci
  varsa rota tehlikesini ücretsiz tam gösteriyor, `caravan_planner.gd`
  sefer süresini İzci'nin `get_duty_flat_reduction`'ı kadar kısaltıyor.
  Olay havuzu 13'ten 22'ye çıktı - ekipman bulma/edinme (`evt_forgotten_
  cache`, `evt_traveling_tinker`), İzci (`evt_scouted_pass`), beş
  kültürün her birine bir sahne (`evt_culture_*` - kültürlerin mekanik
  perki dışında ilk kez olay tarafında da göründüğü yer) ve bir DD
  curio'su (`evt_roadside_shrine`). `GameSession.build_event_context()`'e
  `has_izci` ve beş `is_*_culture` bayrağı eklendi.
- **PR-D (placeholder → lore)** `item_catalog.gd`'deki `test_` önekli
  id'ler (kayıt uyumluluğu için sabit) artık gerçek isimler taşıyor
  (Buğday, Top Kumaş, Demirci Malı Silah, Otacı İksiri, İşlenmiş Kürk).
  `world_map_data.gd`'nin beş şehri de aynı şekilde gerçek isimlere
  kavuştu (Karakonak/Kurtboğazı/İpekevi/Demirkapı/Yeşilova -
  `location_id`'ler yine sabit), tüccar isimleri "Tüccar 12" gibi çıplak
  numaralar yerine kültürlerin kendi isim havuzlarından deterministik
  seçiliyor.

Faz 8 ("Vizyon ve Denge") sürüyor - rakip oyunların (Darkest Dungeon,
Oregon Trail tarzı kervan yönetimi) vizyonu doğrultusunda içerik/denge
boşluklarını dolduran bir hat:

- **PR-A (denge simülatörü)** `simulate_journeys.gd`'yi Faz 6-7 içeriğini
  gerçekten alıştıran bir araca çevirdi (bkz. Testing bölümü) - bulduğu
  `get_duty_flat_reduction()` asimetrisini düzeltti.
- **PR-B (düşman çeşitliliği)** yolda yalnızca haydut çıkma tekdüzeliğini
  kırdı: vahşi hayvan (Kurt/Ayı/Domuz), bölgeye göre haydut reskin'i
  (Kurtboğazı → Dağ Haydutu, Demirkapı → Silahlı Eşkıya), şehir muhafızı/
  çavuşu (zafer itibar *kaybettirir* - bkz. Combat Rules). Tek giriş
  noktası `EnemyCatalog.build_squad(enemy_kind, region_id, ...)`,
  `enemy_kind` `EventEffect.Type.TRIGGER_COMBAT`'in `text_value`'sundan
  `EventEffectApplier.Result.combat_kinds` üzerinden akıyor.
- **PR-C (tayfanın görünürlüğü)** `world_hub.gd`'de vagonları süren
  isimsiz tayfayı (`GameSession.PEOPLE_PER_WAGON`) ilk kez görünür kıldı.
- **PR-C2 (kervan formasyonu)** diziliş mantığını ikiye ayırdı: isimli
  parti üyeleri artık simetrik bir muhafız düzeninde - levazımcı görevini
  taşıyan kişi (yoksa en kıdemli) her zaman liderin hemen arkasında
  (bkz. `world_hub.gd`'nin `_order_escorts()`) - tayfaysa artık düzenli
  sıra tutmuyor, vagon başına asimetrik/dağınık bir konumda yürüyor
  (`_crew_offset()`).
- **PR-D (hedef ve zorluk eğrisi)** üç parça: `GameSession.
  get_effective_danger(base_danger)` rotanın ham `danger_level`'ını
  `total_days_elapsed`'e göre büyütüyor (`DANGER_GROWTH_PER_DAY`,
  `DANGER_GROWTH_CAP` tavanlı) - erken oyunun kolaylığı geç oyunda
  sürmesin diye; caravan_planner.gd/world_map.gd/tavern.gd artık rotanın
  ham değeri yerine bunu okuyor. Oyunun DD tarzı felsefesinde yenilgi
  yok, bu yüzden "hedef ekranı" bir game-over değil: kese `GameSession.
  GOAL_GOLD`'a ulaşınca (`has_reached_goal()`, bir kereye mahsus -
  `GOAL_FLAG`) şehre varışta `goal_reached.tscn` açılıyor, "Devam Et" ile
  oyun kaldığı yerden sürüyor. Ana menüye "Ayarlar" (dil seçici artık
  burada, `settings.tscn`) ve "Çıkış" eklendi.
- **PR-E (onboarding)** karakter oluşturmadan sonraki ilk şehir varışında
  bir kereye mahsus, atlanabilir bir ipucu katmanı (`OnboardingPanel`,
  `GameSession.ONBOARDING_FLAG`) stres/görev/huy/ekipman sistemlerini
  tanıtıyor - `PulseBar` gibi sahnesiz, `.new()` ile kurulan bir bileşen,
  `city_map.gd`'nin ilk `_ready()`'sinden tetikleniyor.

Faz 9 ("Derinleşen Dünya") tamamlandı - Codex incelemesinin açtığı yedi
başlık, hepsi aynı desende: sabit bir taban tablo + üstüne binen dinamik
bir katman, ve katmanın sömürülemeyeceğini kanıtlayan bir test paketi.

- **A (borç)** kese eksiye düşebiliyor; `DebtLedger` vade, faiz ve yapılandırma
  taşıyor, açık hesap kesenin eksi bakiyesinin *aynası* (iki kez sayılmasın diye).
- **B (ağırlık)** kargo sınırı artık `Inventory.add_item`'in içinde, yani olay
  ödülü de pazar alımıyla aynı kurala tabi. Erzak muaf.
- **C (ekonomi)** `MarketConditions`: enflasyon, mevsim, oyuncunun kendi
  ticaretinin yarattığı arz-talep baskısı ve `MARKET_SHOCK` olayları.
- **D-E (karakter-duyarlı olaylar)** `NpcDisposition` + `ROLL_ENCOUNTER`: yolda
  karşılaştığın kişinin gizli mizacı kararın sonucunu belirliyor, sezgisi
  kuvvetli biri okuyabiliyor, kinci biri günler sonra dönebiliyor.
- **F (pazarlık)** bkz. Haggling Rules - oyunun para basma noktası kapatıldı.
- **G (dinamik rotalar + yolda değişen plan)** bkz. Route Rules ve En-Route
  Plan Rules. `RouteConditions` sabit yedi kenarı her hafta başka bir ağa
  çeviriyor (`ROUTE_CHANGE` ile `evt_landslide`/`evt_road_patrol` de bu
  katmandan geçiyor), `divert_journey()`/`turn_back()` şehirde kurulan planı
  bir taahhüt olmaktan çıkarıyor.

- **H (çeviri)** ekran, savaş ve olay katmanlarındaki ~300 sabit Türkçe
  metni anahtara taşıdı; oyunun tamamı 11 dile açık. `test_localization.gd`
  üç yeni koruma kazandı (sabit metin taraması, tanımsız anahtar taraması,
  yer tutucu imzası) ve üçü de gerçek artık yakaladı - sonuncusu İngilizce
  bir savaş satırındaki argüman sırası hatasını.
- **I (moral)** bkz. Morale Rules. Moral ölü bir stattı; artık yol her gün
  yıpratıyor, çıkış morali dünyanın haline bağlı ve `evt_mutiny` ilk kez
  gerçekten ateşleniyor.
- **A-E denetimi** "tamamlandı" işaretli aşamalarda üç eksik buldu ve
  kapattı: borç defterinin hiçbir ekrana bağlı olmaması (`DebtPanel`),
  çeviri taramasının yalnızca ui/world'ü kapsaması, ve `SAVE_VERSION`'ın
  yazılıp hiç okunmaması.

Faz 10 ("Oyun bir şeye benzesin") tamamlandı - iki hat, biri savaşın
derinliği biri oyunun görüntüsü.

**Darkest Dungeon hattı (DD-1..DD-5).** Zırh (PROT), her round yeniden
atılan hız zarı ve Ölümün Kıyısı (yalnızca lider ölür, kıdemliye devir,
varis yoksa oyun biter); savaş alanı görünümü (liste değil saf düzeni);
durum efektleri (kanama/zehir/sersemletme, dirençler, zincirlenemeyen
sersemletme, üst üste binmeyen DoT); alan hedefleme ve mevki kaydırma.
Denge yeniden ölçüldü ve tablo düştü - sebebi hiç ölçülmemiş olan DD-1
çıktı (bkz. Ruin Rules).

**Sanat hattı (ART-A..ART-D).** Oyunun tamamı `ColorRect`'ten çizilmiş
görsele geçti: tek palet ve tek fırça seti (`ArtPalette`/`ArtDraw`),
katmanlı paralaks bir yol (arazi ve hava veriden geliyor, yağmur hem
görünüyor hem yolu yavaşlatıyor), eklemli yürüyen figürler ve atlı bir
lider, üstten bakışlı izometrik bir şehir (beş mekânın kendi mimarisi,
üstüne gelince ne yapabileceğini söyleyen balon). Kervan emirleri
(F2 + sayı) ve liderin kolondan ayrılıp gezebilmesi de bu hatta geldi.

Sırada: elle çizilmiş varlıklar (her şey hâlâ `_draw()` ile çiziliyor -
`ArtPalette` kalır, çizim fonksiyonları dokuya yerini bırakır) ve
Ruin Rules'un işaretlediği tek denge sorusu (iki kişilik parti %65
tehlikede %12).

Faz 11 ("Playtest 14.09.2026") - bir dış oyuncunun ilk elden bulduğu beş
gerçek eksik, hepsi küçük ama biri projeyi baştan sona kesiyordu:

- **Font kapsamı.** Savaşın mevki belirteçleri (`●○`) boş kutu olarak
  çıkıyordu - playtest bunu fotoğrafladı. Taradığında aynı hata on bir
  yerde daha çıktı (parti sıralama okları, brifingin tamamlandı tiki, yol
  kaydının ayırıcıları...). Hepsi `UiIcon`'a taşındı (bkz. Art Rules) ve
  `test_localization.gd` artık her CSV hücresini ve her ekran dizesini
  fontun kapsamına karşı sınıyor - bir daha aynı hata sessizce giremez.
- **Erzak kilidi risk oldu.** "Yetersiz erzak - yola çıkılamaz" oyunun
  kendi tezine (kervan ruined olabilir ama kararı oyuncu verir) aykırıydı.
  Artık iki basışlık bir onay: ilki kaç gün aç kalınacağını söylüyor,
  ikincisi kabul ediyor (bkz. Provision Rules).
- **Teslimat görünür oldu.** Kontrat teslimi varışta kendiliğinden oluyor
  ama hiçbir ekran bunu söylemiyordu - playtest "teslim et" ekranı aradı.
  Varış özeti artık teslim sayısını ve kazanılan itibarı yazıyor, lonca
  panosu kabul edilen kontratın yanına teslimatın nasıl işlediğini
  anlatan bir satır ekliyor (bkz. Reputation Rules).
- **Kervan dökümü.** "My Caravan Status" isteğine ve "status/map/
  inventory/contracts gibi düğmeler" fikrine tek cevap:
  `CaravanStatusPanel`, yol ekranında `Tab` ile açılan, kadro/vagon/erzak/
  kargo/kontrat/defter dökümü (bkz. Road Screen Layout Rules).
- **İsteğe bağlı yardım.** Sistem anlatımı (`OnboardingPanel`) bir kereye
  mahsus otomatik açılıyordu, bir daha bulunamıyordu. Şehirde ve yolda
  `F3` ya da bir "Yardım" tuşu artık aynı katmanı bayrağa dokunmadan
  yeniden açıyor.

**Bilerek uygulanmadı, not olarak duruyor:** playtest yürürken küçük
rastgele ödüller ya da mini-oyunlar önerdi, ama kendi sözleriyle *"erken
bir fikir olabilir, dursun bir köşede"* dedi ve oyunun text-tabanlı mı
olduğundan bile emin değildi. `RoadSignals` zaten üç olumsuz tür
taşıyor (bkz. Road Layer Rules) ve dördüncü, olumlu bir tür eklemek
mimari olarak ucuz - ama bu, playtest'in kendi hedefiyle çelişen bir
mekaniği inşa etmek olurdu. Fikir burada duruyor, bir görev değil.

Faz 12 ("Dışarıdan bakış") - oyunun kendi Codex'i beş farklı yapay zeka
modeline "bunu sıfırdan sen yapsaydın nasıl olurdu" diye soruldu; beşi de
birbirinden habersiz aynı iki şeye parmak bastı: dünya sahneleri (menü/yol/
şehir/savaş) ile yönetim ekranlarının (pazar/lonca/karakter...) iki ayrı
prodüksiyon gibi görünmesi, ve `RoadAttention`'ın taşıdığı karmaşıklığa
göre az iş yapması. İkincisi ciddiye alınmadı - oyunun kendi Road Layer
Rules'u bu mekaniği zaten playtest edilmiş, kasıtlı derinleştirilmiş bir
sistem olarak kaydediyor, kısa bir özetten görüp verilen bir oybirliği onu
sökmeye yetmez. Düşük riskli, kaynağı ne olursa olsun uygulanabilir üç
öneri alındı:

- **Tehlike artık seçilmeden önce görünüyor.** %12'lik bir kazanma oranı
  dengesizlik değildi, okunabilirlik sorunuydu - bkz. Event Engine Rules'un
  `_choice_triggers_combat()` maddesi.
- **Liderlik devri bir sahne oldu**, bir log satırı olmaktan çıktı - bkz.
  Lineage Rules'un `SuccessionPanel` maddesi.
- **Piyasa şoku artık görünür.** `add_shock()`'un hiç okunmayan
  `label_key`'i ve hiç çağrılmayan `get_active_shocks()`'u vardı - bkz.
  Economy Rules'un `is_shocked()` maddesi.

Geri kalan öneriler (stres/moral birleşmesi, rota/hava sadeleştirmesi, borç
sisteminin kapsamı, ekipmanın kargoya dönüşmesi, kampanya bölümlerinin
sadeleşmesi, ve en büyüğü - iki katmanlı "defter" sanat yönüne geçiş)
bilerek uygulanmadı: her biri oyunun zaten ölçülmüş ya da test edilmiş bir
sistemine dokunuyor ve iki taraf da modeller arasında gerçek savunucular
buldu. Karar oyuncuda, görev değil.

Faz 13 hazırlık notu (CLAUDE.md) - kervanla ilgili yıllar önce tutulmuş 26
notun triyajı. Her not mevcut sistemlere karşı üç kefeye ayrıldı:

**Zaten karşılanıyor, yeni iş gerekmiyor:** kervanın uzun süre yüksek
stresle dağılması (bkz. Stress Rules'un `resolve_stress_breaks`/
`evt_stress_brawl`/`evt_mutiny` üçlüsü), kararların gecikmeli sonuç
doğurması (bkz. Event Character Rules'un `evt_wanderer_revenge` zinciri -
mevcut bayrak/tetikleme vokabülerinin kendisi bu), Darkest Dungeon tarzı
kombat (bkz. Combat Rules/DD-1..DD-5), göç sırasında bölgeye göre değişen,
tükenmeyen arkaplan çeşitliliği (bkz. Art Rules'un `hash(cell index)`
maddesi ve Route Terrain & Weather Rules), karizmaya bağlı pazar fiyatı +
partideki ticaret gücünden faydalanma (bkz. Haggling Rules ve Tellal
görevinin `get_duty_discount`'u), eylem sırasında zamanın eyleme göre akması
(bkz. Journey Time Rules'un `consume_hours` maddesi), ve "gelişme başarma
hissi" (bkz. Progression Rules'un ölçülen merdiveni). Rota uzayıp da
teslimat deadline'ı içinde kalırsa yine başarılı sayılması da zaten
`TRAVEL_DAYS` + kontrat deadline mekaniğinin doğal sonucu.

**Mevcut, kasıtlı tasarlanmış bir sistemle çelişiyor:** "stres parti
genelinde, moral bireysel" notu bugünkü sistemin **tam tersi** -
Stress Rules'un kendi tarihi tam olarak bunun (tek paylaşılan bir stat)
iki kez denenip iki kez başarısız olduğunu, bugünkü ayrımın (stres kişide,
moral seferde) o başarısızlıklardan sonra kasıtlı seçildiğini kaydediyor.
Not eski bir fikir olarak kalıyor, uygulanmadı.

**Faz 13 - oyuncunun kendi rafine ettiği son karar, uygulandı** (görev
listesi #112-#119, hepsi tamamlandı):

- Rota değişince o yöne gitmeyecek tüccarların tepki vermesi
  (`evt_route_diversion`, `triggered_only` - `road_journey.gd`'nin
  `_apply_replan()`'ından doğrudan sunulur, havuzdan çekilmez) - En-Route
  Plan Rules'un zaten yaptığı kesintiyi hikâyeleştiriyor.
- Bölge/duty bilgisine bağlı toplama-av olayı (`evt_forage` - İzci varsa
  ağırlığı ×1.6) - yeni bir sistem değil, `EventEffect.Type.PROVISIONS` +
  mevcut `RouteTerrain`/`has_izci` bayrağı.
- Kervan hızına açlığın etkisi (`road_journey.gd`'nin `_hungry` bayrağı,
  `HUNGRY_PACE_MULTIPLIER`) - tempo zaten hava çarpanına bağlıydı (bkz.
  Road Layer Rules'un "Pace is a resource" maddesi), aynı kalıba erzak
  eklendi: `_advance_contracts_and_provisions()`'ın kendi açlık koşulu
  `_walk_at()`'ın hız formülüne giriyor.
- Kombatta kısa, sessiz yorum balonları (isabet/kritik/düşüş/emir reddi
  anında) - seslendirme değil, yalnızca metin. `CombatEncounter.unit_barked`
  sinyali `CombatPanel._bark_texts`'te gerçek zaman damgasıyla tutuluyor,
  çünkü `CombatUnitSlot`'lar her `_refresh()`'te yeniden kuruluyor - bir
  Tween'in üzerinde kalabileceği kalıcı bir düğüm yok.
- Karar önizlemesi: Zeka/Sezgi'ye göre sonuç ipucu (`EventChoice.
  hint_text_key`/`hint_stat`/`hint_threshold`) - Faz 12'nin tehlike
  etiketiyle aynı okunabilirlik ailesi: ipucu zarı değiştirmiyor, yalnızca
  oyuncuyu bilgilendiriyor (New Vegas'ın skill-check önizlemesi gibi).
  `evt_party_investigation`'ın suçlama seçeneği ilk kullanımı.
- Kervan-içi hırsızlık/cinayet soruşturma zinciri (`evt_party_theft` →
  `UNLOCK_EVENT` → `evt_party_investigation`) - `NpcDisposition` ve
  `evt_wanderer_revenge`'in zincir deseninin parti-içi versiyonu; suçlama
  %50 doğru %50 yanlış bir kumar, hint bunu değiştirmiyor.
- Yeni yol konvoyu türleri (`evt_military_convoy`, `evt_refugee_column`,
  `evt_merchant_caravan`) - mevcut `EVENT_ROAD_MARKER_KIND`'a "guard"/
  "traveler" kategorileriyle yeni girişler, yeni bir figür çizmiyor.
- Görev gücüne kişisel kondisyon etkisi (`DutyCatalog.
  get_condition_multiplier()`) - kırılmış (`CharacterData.is_stressed()`)
  ya da canının yarısının altındaki bir görevli göreve daha az katkı verir;
  sağlıklı/dinç varsayılan (tam can, sıfır stres) çarpanı 1.0'da tuttuğu
  için mevcut hiçbir ölçüm/test etkilenmedi.

**Aynı triyajın kervanla ilgili dört notu da uygulandı** (kullanıcının
kendi önceliklendirmesiyle):

- **Boya bağlı açlık (#2).** "1.90 boyunda bir erkek ile 1.60 boyunda bir
  kadının açlığı aynı olmamalı" - `CharacterData.get_provision_weight()`
  uzun/kısa boy için ±%15, `CaravanPlan.daily_consumption()`'ın altıncı
  (varsayılan 0) parametresi olarak eklendi; `test_provisions.gd`'nin düz
  tam sayı çağrıları hiç değişmeden geçiyor.
- **Kıyafet sistemi (#14) - şimdilik yalnızca sistem, kullanıcının kendi
  isteğiyle.** Altı slot (şapka/gömlek/ceket/eldiven/pantolon/ayakkabı),
  `OutfitCatalog`/`OutfitPiece`, `CharacterData.outfit` - tamamen kozmetik,
  hiçbir derived getter bunu okumuyor (Equipment'ın aksine). Karakter
  oluşturmada boydan bir önizleme penceresi (`OutfitPreview`, basit bir
  `_draw()` taslağı - gerçek sprite'lar Faz 12'nin büyük sanat kararına
  bağlı) ve her slot için sağa/sola kaydırma (`OutfitCatalog.cycle()`).
  Seçenekler kasıtlı az; "önce sistemi kur, seçenekleri sonra ekle" burada
  tam olarak budur.
- **Arkada yaşayan dünya (#15).** Adaylar her şehir varışında bir seed'den
  yeniden atıldığı için (bkz. RecruitCatalog'un kendi notu) kalıcı bir
  kimlikleri yok - büyüme, `RecruitCatalog.get_world_growth_levels(
  journeys_completed)` ile dünyanın kendi seviyesinin zamanla yükselmesi
  olarak modellendi: on sefer önce meydanda karşılaşılan biriyle bugün
  karşılaşılan eşdeğer aday artık biraz daha tecrübeli çıkıyor. Hem şehir
  (`GameSession._restock_recruits`) hem yol (`evt_road_wanderer`) aynı
  fonksiyonu okuyor.
- **Manipülasyon (#19/#20) bir huy olarak, yedinci stat değil.** Kullanıcı
  bunu açıkça bir `Trait` istedi ("zekası yüksek kişilerde çıkan bir huy").
  Yeni bir huy eklemek `test_traits.gd`'nin kilitlediği on iki parçalık
  katalog şeklini bozardı, o yüzden mevcut `PRUDENT` (Zeka huyu) davranışı
  genişletildi: `GameSession.get_effective_manipulation()` PRUDENT'lı bir
  parti için Karizma'ya `PRUDENT_MANIPULATION_BONUS` ekliyor
  (`evt_mutiny`'nin manipüle seçeneği artık bunu okuyor - düşük zekalıları
  ikna kolaylığı) ve `GameSession.apply_event_stress()` PRUDENT'lı
  karakterlerin olay kaynaklı stresini `PRUDENT_EVENT_STRESS_RESIST`
  kadar hafifletiyor (dıştan gelen ikna/motivasyon etkilerine direnç).
  Bu ikinci fonksiyon kasıtlı dar: yalnızca `EventEffectApplier`'ın
  `STRESS` dalı bunu çağırıyor, yol yıpranması/kamp/tempo hâlâ
  `change_stress()`'i doğrudan okuyor - Stress Rules'un ölçülmüş dengesi
  bu fonksiyona hiç dokunulmadan korunuyor.

**#22 (vagon-bazlı envanter + loot crafting) - tasarlandı burada, uygulandı
Faz 15'te (bkz. Development Status'un Faz 15 girişi ve CLAUDE.md Kervan
Envanteri Rules).** Kullanıcının notu ilk triyajdaki "paylaşılan tek
envanter" okumasını düzeltiyor: istenen, kervanın **kendi** vagonlarının
her birinin ayrı bir envanteri olması ve bunların bir crafting sistemine
girdi olması; başkasının (yabancı bir tüccarın) vagonu ise izin verilirse
salt-okunur görüntülenebilir, hiç kullanılamaz. Tasarım notu:

- `Inventory` bugün tek bir `item_id -> miktar` sözlüğü ve tek bir ağırlık
  tavanı (`owned_wagon_count`'a bağlı - bkz. Economy Rules'un "Weight
  binds" maddesi). Yeniden tasarım bunu `GameSession.wagon_inventories:
  Array[Inventory]` yapar - `owned_wagon_count` uzunluğunda, her biri
  kendi tavanına sahip. Pazar/kargo ekranlarının okuduğu "toplam" bir
  toplama fonksiyonundan gelir, tek envanterin yerini almaz; bu yüzden
  mevcut hiçbir ekran aynı anda kırılmaz - yalnızca yeni bir "Kervan Yükü"
  ekranı vagon vagon dağıtımı gösterir/değiştirir.
- Crafting: bir tarif belirli vagonlardaki belirli malzemeleri tüketip
  yeni bir eşya üretir (`RecipeCatalog` + `EventEffect`/ekran eylemi,
  Equipment'ın "parça asla doğrudan karaktere değil önce depoya" kuralıyla
  aynı aile - tarif sonucu önce ilgili vagona yazılır). Hangi vagonun
  girdiyi taşıdığı önemli, yani oyuncu yükünü vagonlar arasında bilerek
  dağıtmak zorunda kalır - "hangi vagonda ne var" ilk kez anlam kazanır.
- Yabancı vagonlar (diğer tüccarların) hiçbir zaman `wagon_inventories`'e
  girmez; ayrı, salt-okunur bir görünüm alır (bir olay ya da lonca
  etkileşimiyle "izin verilirse" açılan bir pencere) - yazma yolu hiç yok,
  yani ekonomiye sızma riski yok.
- **O zaman ertelenme sebebi, ilk PR'ında geçerliliğini korudu.** Bu, tek
  `Inventory`'nin kasıtlı sadeliğini bozan ve ağırlık/kargo testlerinin
  çoğunu yeniden yazan en büyük değişikliklerden biriydi - Faz 15
  `test_game_session.gd`'nin iki ağırlık testini gerçekten yeniden yazdı
  ve kendi PR'ını, kendi test paketini (`test_wagon_inventory.gd`) aldı,
  tam bu notun istediği gibi. Uygulanan şekliyle tek fark: "yabancı vagon
  salt-okunur görünümü" ve ayrı bir "Kervan Yükü" ekranı bu turda da
  kapsam dışı bırakıldı - kullanıcının asıl istediği (vagon başına
  envanter + kişisel çanta + şehirde toplam görünüm + basit bir craft
  menüsü) mevcut ekranların (pazar, Kervan Avlusu) üstüne bindirildi,
  yeni bir ekran icat edilmedi.

**Plana alınmadı, oyuncunun kendi isteğiyle bilerek beklemede (rejected
değil, backlog):** seslendirmeli anlatım ve kombat nidaları (#7, #11 -
gerçek ses kaydı; `AudioManager`'ın şu an sentezlenmiş placeholder'lardan
ibaret olduğu bir prodüksiyon/bütçe kararı - Faz 13 PR-D bunun **metin**
karşılığını zaten kurdu, seslendirme üstüne eklenecek bir katman); iki
dini yaratılış efsanesi + fragman (#12 - lore yönü, şehir mimarisinde din
motifinin bilerek reddedildiği Art Rules'daki cami/minare geri alımıyla
gerginlik taşıyor, fragman da bu kod tabanının işi değil). Üçü de
"sonra üstüne çalışacağız" notuyla plana geri dönebilir - kapatılmadı,
yalnızca beklemede.

Faz 14 ("This War of Mine hissi") - oyunun kendi "çok vanilya, dümdüz bir
kervan oyunu gibi" itirafından doğan bir hat: sanat olmadan da hissettirecek
beş sistemsel değişiklik, hepsi mevcut vokabüleri genişleterek, yeni bir
sistem icat etmeden.

- **A. Herkes ölebilir.** `CombatUnit.can_enter_deaths_door()` tersine
  çevrildi - artık `is_player_character and not is_dead` değil,
  `is_player_side and not is_dead`: Ölümün Kıyısı'na oyuncu tarafındaki
  **herkes** girer, `is_player_character` alanı tamamen kaldırıldı. Zar
  (`deathblow_resist`, varsayılan %67) hâlâ aynı - önce hayata tutunma
  şansı, tutmazsa kalıcı ölüm. `write_back_party()`/`get_dead_characters()`/
  `GameSession.resolve_combat_deaths()` hiç değişmedi, çünkü zaten
  genelciydi (yalnızca kimin lider olduğuna, "kim öldü"ye değil bakıyordu) -
  tek kilit `can_enter_deaths_door()`'daydı. Ölçüm sürpriz çıktı: bkz.
  Ruin Rules'un "kill-sponge" notu - tablo düşmedi, yükseldi, çünkü Kıyı'da
  duran biri artık sahadan çıkmıyor ve düşman AI'ının "en zayıfı vur"
  kuralı yüzünden sağlıklı yoldaşları koruyan bir süngere dönüşüyor.
- **B. İsimli açlık/stres.** `_apply_downed_marks()` artık kimi işaretlediğini
  kayda yazıyor ("X bu çarpışmadan sarsılmış çıktı"), sayı olarak değil.
  Asıl derinleşme C'de - açlığın artık isimle geldiği yer orası.
- **C. Akşam sofrası.** `_run_day()`'in sessizce uyguladığı tek bir
  `daily_consumption` artık bir karar: `MealDistributionPanel` her gün
  beş seçenek sunuyor (herkese/yalnızca ekibe/yalnızca kervana/belirli
  kişilere/yalnızca lidere dağıt), `GameSession.apply_meal_distribution()`
  toplamı (hâlâ `get_daily_provision_consumption()`'dan - formül tek yerde
  kuralı bozulmadı) gruplar arasında bölüştürüp aç kalanı **isimle**
  bildiriyor. Kamp ateşi kararın sahnesi: `RoadCaravan.set_camping()`'in
  görsel ateş+toplanma animasyonu ödünç alınıyor (mekanik "Kamp Kur" hâli
  dokunulmadan), panelin arka planı `SuccessionPanel`in tam siyahı değil
  yolun kendi `%55` alfalı perdesi - ateş arkada görünsün diye.
- **D. Savaş öncesi kadro.** `PreCombatPanel` her çarpışmadan önce kimin
  katılacağını ve bu çarpışmaya özel sırayı soruyor - `party.tscn`'nin
  genel marş sırasına dokunmuyor. Dışarıda kalan risk almaz, XP de
  almaz (`grant_party_xp()`'in artık isteğe bağlı `targets` parametresi);
  düşen izi de (B) yalnızca gerçekten savaşanlardan seçiliyor
  (`_current_combat_party`, tüm parti değil).
- **E. Defter artık kendiliğinden geliyor.** `CaravanLedger` hiçbir satırı
  silmiyordu ama pasifti - yalnızca yol ekranında `Tab`'la açılan
  `CaravanStatusPanel`de görünüyordu. `CityBriefPanel._build_memory()`
  en son üstü çizili satırı (öldü/ayrıldı) her şehir varışında hikâye
  bloğunun sonuna ekliyor - "no need, no row" burada da geçerli, hiç
  üstü çizili satır yoksa blok da yok.

**Bilerek bu turda yapılmayan:** A'nın açtığı denge sorusu (parti 4'ün her
tehlike seviyesinde %100 kazanması) ölçüldü ve kaydedildi ama retune
edilmedi - iki değişikliği aynı pasta ölçmeden üst üste bindirmek bu
dosyanın kendi kuralı. `DEFAULT_DEATHBLOW_RESIST`'i düşürmek en olası
yön, ama kendi ölçümünü ister.

Faz 15 ("Ölçüm ve vagonlar") - Faz 14'ün kendi açık uçlarından biri, ve
kullanıcının uzun süredir istediği en büyük backlog kalemi (#22), aynı
turda:

- **A. Kill-sponge retune - ama tahmin edilen kol değil.** Faz 14'ün notu
  `DEFAULT_DEATHBLOW_RESIST`'i en olası düzeltme diye işaretlemişti. Ölçüm
  bunu çürüttü: direnci 67'den 33'e (ölümcül vuruş zarının neredeyse
  yazı-tura olduğu bir sertliğe) indirmek parti 4'ü hiç kıpırdatmadı
  (%100/%100/%98/%98). Asıl sebep aritmetikti: `EnemyCatalog._build_units()`
  kadroyu `MAX_SQUAD_SIZE`'da (4) kırptığı için parti 3 ile parti 4 zaten
  aynı sayıda düşmanla dövüşüyordu - dördüncü kişi karşılıksız bir fazla
  vurucuydu. Gerçek kol `POWER_SCALE_PER_PARTY_MEMBER` (0.10 → 0.30) çıktı;
  tam ölçüm ve tablo Ruin Rules'ta. `DEFAULT_DEATHBLOW_RESIST` hiç
  değişmedi.
- **B. Kervan Envanteri + Atölye (#22'nin kendisi).** `GameSession.
  wagon_inventories` tek paylaşılan `Inventory`'nin yerini aldı,
  `CharacterData.personal_inventory` küçük bir kişisel taşkın alanı açtı,
  `get_total_quantity()`/`get_total_inventory_entries()` ikisini şehirde
  tek bir toplam olarak gösterdi - kullanıcının kendi tarifiyle "vagonlarımızın
  ve çantamızın toplamı." **İlk sürüm Atölye'yi yanlış yere koydu** - Kervan
  Avlusu'na bir düğme, kervanın toplamını okuyan bir panel - ve düzeltildi:
  craft menüsünün şehirle hiçbir ilgisi yok, oyuncu yolda ilgili vagona
  yürüyüp tıklıyor (`world_hub.gd`'nin artık her vagon için ayrı bir
  etkileşim noktası olması - eskiden yalnızca ilk vagondu, tek paylaşılan
  envanterin kalıntısı bir varsayımdı), açılan `WagonPanel` yalnızca **o
  vagonun** envanterini ve craft menüsünü gösteriyor - `GameSession.
  craft_in_wagon()` kervanın toplamından değil, tıklanan vagonun kendi
  `Inventory`'sinden okuyup yazıyor. Bu, #22'nin asıl istediği şeydi:
  malzeme yanlış vagondaysa orada craftlanamaz. Tam ölçüm, tasarım
  gerekçesi ve neyin bilerek kapsam dışı bırakıldığı (yabancı vagon
  görünümü, ayrı bir "Kervan Yükü" ekranı) Kervan Envanteri Rules'ta.
- **C. Ana menünün tıkla-geç açığı.** "Bir tuşa basın" evresinde düğmeler
  saydamdı ama `disabled` bir düğmenin varsayılan `mouse_filter`'ını
  (`STOP`) değiştirmiyor - fare tıklaması klavye basımının hiç görmediği
  bu yolu (GUI hit-testing) izlediği için, düğmelerin durduğu yere
  tıklamak sessizce yutuluyordu; boş bir alana tıklamak çalışıyordu. Evre
  boyunca düğmelerin `mouse_filter`'ı da `IGNORE`'a çevrilip menü açılırken
  geri alınıyor (bkz. `main_menu.gd`'nin `_set_buttons_mouse_ignore`).

### Çözülmüş: stres eşiği (kayıt için)

`evt_stress_brawl` stres ≥ 70 istiyordu, simülatörde varış stresi ~25'ti -
olay katalogda vardı, oyunda yoktu. Üç kolun üçü birden gerekti (bkz.
Stress Rules): eşik 40'a indi, varış rahatlaması 35'ten 14'e indi ve
günlerle eriyor, kamp rahatlaması 20'den 8'e indi. Üçüncüsü ölçmeden
görünmüyordu: ilk ikisi tek başına yetmiyordu çünkü her sefer kamp kuran
oyuncuda stres hâlâ hiç birikmiyordu.

Sonuç: `evt_stress_brawl` 600 koşuda 2 kez ateşleniyor, playthrough
demosunda dört bacak sonunda stres 18 (eskiden 0).

### Çözülmüş: isyan eşiği (kayıt için)

Bir süre "moral hiç düşmüyor" sanıldı; bu bir **ölçüm hatasıydı**.
`simulate_journeys.gd` morali `finish_journey()`'den *sonra* okuyordu, o
çağrı da kervanı sıfırlıyor (`CaravanState.new()`, moral yeniden 100) - yani
raporlanan sayı seferin morali değil, sıfırlanmış bir kervanınkiydi ve her
koşuda tam olarak 100.0 çıkıyordu. Düzeltildi; simülatör artık varış moralini
*ve* seferin dip noktasını ayrı ayrı basıyor.

Gerçek tablo (200 koşu × 3 tehlike seviyesi):

| tehlike | varış morali | seferin dibi | en kötü | isyan eşiğine (≤25) inen |
|---|---|---|---|---|
| %20 | 62.3 | 61.9 | 37 | %0 |
| %40 | 62.4 | 62.1 | 35 | %0 |
| %65 | 60.3 | 60.0 | 35 | %0 |

Yani moral gerçekten düşüyor (100 → ~60) ama `evt_mutiny` hiçbir koşulda
ateşlenmiyor: katalogda var, oyunda yok. Üç sebep birlikte çalışıyor -
moral her seferde 100'den başlıyor (tasarım gereği: moral o seferin ruh
hali, kalıcı olan stres), günlük bir aşınma yok (yalnızca kesikli olay
darbeleri), ve olay havuzunun moral bilançosu neredeyse başabaş
(+192 / -199).

**Uygulanan çözüm (2+1):** günlük moral aşınması + eşiğin 40'a inmesi.
Üçüncü bir adım da gerekti - eşik tek başına yetmedi, olay ağırlıklı çekimi
hiç kazanamıyordu (bkz. Morale Rules'un son maddesi). Sonuç: varış morali
~55, seferin dibi ~54 (en kötü 20), koşuların %7.5-10.5'i eşiğe iniyor ve
`evt_mutiny` 600 koşuda 6 kez ateşleniyor.

Faz 16 hazırlık notu (CLAUDE.md) - Faz 12'nin dışarıdan-bakış triyajından
kalan altı öneri ve Faz 15'in vagon envanteri tasarım notunun karşılanmayan
iki parçası, oyuncunun kendi elemesiyle karara bağlandı:

**Reddedildi:**
- **Stres/moral birleşmesi.** Zaten Faz 13'ün kendi triyajının kaydettiği
  gibi bugünkü sistemin tam tersi - iki kez denenip iki kez başarısız
  olduğu için kasıtlı ayrı tutuluyor (bkz. Stress Rules). Bir daha
  gündeme gelmeyecek.
- **Borç sisteminin kapsamının daraltılması.** Doğrudan reddedildi,
  gerekçe verilmedi.
- **Ekipmanın kargoya (envantere) dönüşmesi.** Doğrudan reddedildi, ve
  reddin kendi gerekçesi mevcut ayrımın *neden* doğru olduğunu netleştirdi:
  üstümüzde taşıdığımız (kılıç, zırh gibi) şeyler envanter kalemi değil -
  envantere konulabilir ama o zaman takılı olmazlar. Bu tam olarak
  `Equipment`'ın `equipment_inventory`'si (depoda, kimseye takılı değil)
  ile bir karakterin `equipped` sözlüğü (üstünde, takılı) arasında zaten
  çizdiği çizgi - Kervan Envanteri Rules'daki `wagon_inventories`'in
  Equipment'a hiç dokunmamasının sebebi de bu; iki sistem aynı isimde
  bonus alanları taşısa da (bkz. Equipment/Trait bölümü) birleşmiyorlar.

**Ertelendi (henüz erken):**
- **Kampanya bölümlerinin sadeleştirilmesi.** Sadeleştirilecek olan asıl
  hikâye/anlatı içeriği henüz yazılmadı - mevcut beş bölüm (bkz. Campaign
  Rules) şu an yalnızca eşik/bayrak mekaniğini taşıyor. İçerik yazılmadan
  yapı sadeleştirilemez; bu not içerik yazıldıktan sonra tekrar gündeme
  gelebilir.

**Ana hedeflere terfi etti (artık backlog değil, aktif yol haritasının
parçası):**
- **İki katmanlı "defter" sanat yönüne geçiş** - Faz 12'de "en büyüğü"
  diye işaretlenen öneri, mevcut prosedürel `_draw()` sanatından farklı
  bir görsel kimlik.
- **Gerçek seslendirme + savaş nidaları** (#7, #11) - `AudioManager`'ın
  bugünkü sentezlenmiş placeholder'larının yerini gerçek kayıt alacak;
  Faz 13 PR-D'nin kısa metin yorumları (`unit_barked`) bunun metin
  karşılığı olarak zaten kurulu.
- **İki dini yaratılış efsanesi + fragman/sinematik** (#12).

Üçünün de ne zaman ele alınacağı ayrı bir sıralama kararı - "oyun her an
inşa halinde" olduğu için artık "playtest sonrası" gibi bir eşiğe
bağlanmıyorlar (bkz. aşağıdaki not, aynı gerekçeyle #9'u da kapsıyor).

**"Playtest" diye ayrı bir dönem yok.** Faz 11'in "erken bir fikir olabilir,
dursun bir köşede" notuyla ertelediği yoldaki küçük olumlu sinyal fikri
(#9), oyunun sürekli inşa halinde olduğu gerekçesiyle o çerçeveden çıkarıldı
- ne zaman ele alınacağı hâlâ ayrı bir karar ama artık "bir playtest dönemi
gelince" diye bir ön koşulu yok. `RoadSignals`'ın üç türü (bkz. Road Layer
Rules) her biri bir dikkat bölgesine bağlı (`RoadAttention`: baş/vagonlar/
arka) ve ihmal edilince büyüyor; bir dördüncü, olumlu tür aynı mimariye
oturur ama ihmal edilince *büyümemeli*, yalnızca fırsat kaçmış olmalı -
"hiçbir olumlu şey cezaya dönüşmez" (negatif sinyallerin tersi). Değerlendirmeye
açık üç aday, üçü de mevcut vokabüleri kullanıyor, yeni bir sistem
icat etmiyor:
- **Baş bölgesi - "İz" sinyali.** Yakalanırsa küçük bir erzak bulma ya da
  bir sonraki durağın erken açığa çıkması (İzci'nin zaten yaptığı erken
  tehlike/duraklık gösteriminin bir günlük hali).
- **Vagonlar bölgesi - "Yardımcı el" sinyali.** Yakalanırsa küçük bir vagon
  hasarı iyileşmesi ya da o günkü erzak tüketiminde küçük bir tasarruf.
- **Arka bölgesi - "Sohbet" sinyali.** Yakalanırsa küçük bir stres/moral
  iyileşmesi - kampın "ücretsiz ama yavaş" kolunun günlük, küçük bir
  eşdeğeri.

**Kıyafet sisteminin kapsamı netleşti.** `OutfitCatalog`/`OutfitPiece`
bugün yalnızca `OutfitPreview`'da (karakter oluşturmadaki boydan önizleme)
okunuyor - `WalkFigure` (dünya) ve `CombatFigure` (savaş) hiçbir zaman
`CharacterData.outfit`'e bakmıyor, yani bir kıyafet seçimi şu an oyunun
geri kalanında **görünmüyor**, yalnızca o önizleme penceresinde. Elle
çizilmiş görsellerin (Faz 10'un işaretlediği, hâlâ tamamlanmamış "next")
ilk hedeflerinden biri bu boşluğu kapatmak olmalı - altı slot (şapka/
gömlek/ceket/eldiven/pantolon/ayakkabı) zaten parça parça ayrılmış durumda
(`OutfitCatalog.SLOT_*`, her biri kendi küçük havuzuyla), tek eksik olan bu
parçaların `WalkFigure`/`CombatFigure` üzerinde de okunup çizilmesi -
sistemin kendisi (Faz 13 PR'ının kasıtlı sırasıyla: "önce sistemi kur,
seçenekleri sonra ekle") zaten buna hazır kurulmuş durumda. `Equipment`
(kılıç/zırh gibi combat parçaları) tamamen ayrı bir sistem kalır - `outfit`
kozmetik, `equipped` savaşı etkiler; ikisi de karaktere görsel bir katman
eklerken birbirine karışmaz (yukarıdaki "reddedildi" maddesinin gerekçesi).

**Yabancı tüccarın vagonuna bakış artık bir diyalog mekaniği olarak
tasarlandı** (bkz. Kervan Envanteri Rules'un "#22'nin karşılanmayan"
notu). Kervana kabul edilmiş (yani eskort olarak taşınan) bir tüccarın
vagonuna tıklamak onunla bir sohbet açar: izin verirse envanteri
görüntülenir, vermezse oyuncu zorla bakmayı deneyebilir, tekrar ikna
etmeyi deneyebilir, ya da vazgeçebilir - salt bir "göster/gösterme"
anahtarı değil, `NpcDisposition`/ikna vokabülerinin (bkz. Event Character
Rules, `evt_mutiny`'nin manipüle seçeneği) vagon etkileşimine taşınmış
hâli. Henüz uygulanmadı, tasarım notu olarak duruyor.

**Genel bir "Kervan Yükü" ekranı artık daha geniş tanımlandı**: kervanın
sembolik bir görünümü, her vagonun altında o vagonun ağırlığı, ona bağlı
kişiler ve hesaplanan hızı; en sağda kervanın **teorik hızı** - en yavaş
vagonun hızı (bir kervan en yavaş tekerleğinden hızlı gidemez). Aynı
ekrandan kervandaki herkesin açlık/stres/moral durumu ve kervan hakkındaki
toplu "düşünceleri" görülebilmeli. `CaravanStatusPanel`'in (bkz. Road
Screen Layout Rules) salt-okunur dökümüyle akraba ama ondan geniş - o yol
ekranının bir Tab paneli, bu ayrı, kendi başına bir ekran/mekanik. Henüz
uygulanmadı, tasarım notu olarak duruyor.

## Quick Start

1. Open `project.godot` in Godot 4.2+
2. Create your first scene in `scenes/main.tscn`
3. Create scripts in appropriate `scripts/` subfolders
4. Reference scenes/scripts using `res://` paths
5. Push to `main` branch to trigger automatic Web export & deployment

## Codex

`docs/Wayborne-Codex.pdf` is the game's design document — 66 pages covering
every mechanic in prose, plus a one-page decision tree for each of the 27
road events (trigger, options, weighted outcomes, effects). It is
**generated**, not written: `docs/codex/` holds the reportlab source and
`python3 docs/codex/codex_main.py` rebuilds the PDF in place. This file
(CLAUDE.md) stays the rule book — what must never be broken and why; the
codex is the explanation, for a reader who has not read the code.

Its event chapter mirrors `scripts/events/event_catalog.gd` by hand, so a
new or retuned event needs a matching edit in `docs/codex/codex_events_data.py`
— see that folder's README for why it is not derived automatically.

## Useful Links

- [Godot 4 Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [HTML5 Export Guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
