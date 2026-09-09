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
- Losing a fight is not death: `write_back_party()` stands downed characters
  back up at 1 HP. The caravan can be ruined, never wiped out.
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
- **Yetkinlik (skill proficiency) lives on the character, never on the
  shared `CombatSkill` resource.** `CombatUnit.skill_proficiency` (0-100 per
  skill, invested via `CharacterData.invest_skill_point()`) scales that
  unit's damage/heal by up to +50% and shortens its cooldown - mutating the
  cached `CombatSkill`/`EnemyTemplate` singletons directly would leak across
  every other user of that skill/template, which is why enemy level scaling
  is a `power_scale` multiplier applied only to the freshly-built
  `CombatUnit`, not the `EnemyTemplate` itself.

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
- **`party_stress` is the party's average, not one person's counter.** So
  a newcomer dilutes it (`add_to_party` - the single door in, the
  counterpart of `dismiss`), and replacing a crew over time brings it down.
  A newcomer does not arrive at zero (`NEWCOMER_STRESS_SHARE`): someone
  joining a battered caravan hears the stories. Without that share,
  "dismiss one, hire another" would be a free button that halves stress
  every cycle.
- **The player needs a lever their purse can pull.** `throw_feast()` (in
  the tavern) is paid relief priced per head. Camp is the free-but-slow
  lever, the feast the paid-and-strong one, and stress-relieving events the
  lucky one. Without a purchasable option an accumulating stat is just an
  unavoidable countdown.

Measured curve over twelve consecutive journeys (~25 stress each):

| play pattern | stress after 1 / 6 / 12 journeys | journeys at brawl threshold |
|---|---|---|
| no intervention | 11 / 69 / 88 (capped) | 84% |
| one camp per journey | 4 / 22 / 49 | 43% |
| one camp + feast when high | 4 / 22 / 32 (plateau) | 41% |
| two camps per journey | 0 / 0 / 1 | 0% |

The last row is deliberate, not an oversight: a player who spends the time
and provisions to camp twice a journey *should* hold stress down. It costs
nights, food and daylight.

- **scripts/world/**: Explorable 2D spaces the player physically moves through
  - `world_hub.gd`: side-scrolling road. The caravan leader walks left/right;
    the party then the wagons lerp-follow behind, one body per party member and
    one wagon per `owned_wagon_count`. The city gate and the first wagon are
    interaction spots: walk within `INTERACT_RANGE`, then click them or press E. No physics bodies — plain position arithmetic on a
    single ground line, so it stays cheap on Web export.
  - `city_map.gd`: placeholder city map. City interaction is deliberately
    **not** card-based (see Event Engine Rules): each location button opens its
    own screen (market → economy, guild → haggling, tavern → travel map).
  - `nav.gd`: every scene path lives here, plus `Nav.return_scene` — the screen
    a sub-screen's back button returns to. A spot sets it before changing
    scenes, so the same economy screen returns to the road or to the city
    depending on where it was entered from. `selector_return_scene` is the
    test selector's own back target, kept separate because sub-tests overwrite
    `return_scene` to point back at the selector; `character.gd` (opened only
    from `party.gd`) follows the same pattern by hardcoding its own back
    target to `Nav.PARTY` instead of touching `return_scene` at all, so the
    party screen's own return target (world hub or city map, whoever sent the
    player there) survives the detour. `character_target_index` carries which
    party member the character screen shows.
  - There is no SceneManager autoload: navigation is `change_scene_to_file()`
    plus these static vars.

### World Navigation Rules

- Never hardcode a `res://scenes/...` path in a screen script; use `Nav`.
- A screen's back button goes to `Nav.return_scene`, never to a fixed scene.
- Whoever sends the player somewhere is responsible for setting
  `Nav.return_scene` first.
- A screen whose content can grow past the viewport (market rows, the contract
  board, the party list) puts that content in a `ScrollContainer` and keeps the
  back button **outside** it. Otherwise the back button is pushed off-screen and
  the player is stranded - this actually happened on the market screen.

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
  `DebtPanel` (embedded in the Merchants' Guild, scene-less like
  `PurificationPanel`) is where debts are read, paid and restructured; the
  total also rides on the city and road HUDs. The ledger shipped without any
  screen at all for a while - interest accrued and reputation drained
  entirely out of sight.
- **`SAVE_VERSION` is read, not just written.** `_migrate_save()` is a real
  (currently empty) hook: every field is loaded with `.get(key, default)`,
  so added fields need no migration, but a field whose *meaning* changes
  does - and a version number nobody reads is a hook nobody remembers.

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
- **Weight binds, not just slots.** The limit lives in `Inventory.add_item`
  itself, so an event reward obeys it exactly like a market purchase - when
  only the market screen checked it, everything else leaked through.
  Provisions are exempt (they have their own journey formula and must not
  eat cargo space), and the ceiling tracks `owned_wagon_count`.
- Every number in these tables is a placeholder to be tuned.

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
- `TravelBand` (`scripts/ui/`) owns the visuals: sky/ground colors
  interpolate toward the *next* phase using `get_phase_progress()` so the
  scene never snaps, the world scrolls under a stationary caravan (moving
  the caravan would just hit the edge of the band), and the campfire adds a
  flickering warm light. Still ColorRect placeholders.

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

- **scripts/ui/**: User interface scripts
  - Menu controllers
  - HUD management
  - Popup dialogs

- **scripts/autoload/**: Global singleton scripts (configured in project settings)
  - `GameState` (registered autoload): holds the persistent `GameSession`
  - `GameSession` (plain RefCounted): wallet, inventory, caravan, flags,
    reputation, journey — instantiable in tests without touching the autoload
  - `EventBus` (registered autoload): cross-system signals only
  - `DevPanel` (registered autoload): F1 geliştirici menüsü. `test_selector.tscn`'i
    çalışma anında `load()` ile kurup bir CanvasLayer'a gizli ekler; F1 açıp
    kapatır. `Nav.return_scene`'e dokunmaz, bu yüzden bir hedefe geçince o
    ekranın geri tuşu paneli açtığın yere döner, panele değil.
  - `SaveManager` (registered autoload): `GameSession.to_save_dict()` /
    `load_from_dict()` içeriği bilir, burada yalnızca `user://save.json`
    G/Ç'si var. Yalnızca şehir varışında (`finish_journey()` sonrası)
    çağrılır - sefer/kervan alanları o an her zaman sıfırlanmış olduğu
    için hiç serileştirilmez. `GameSession`'ı `load()` ile kurup normal
    örnek metodu çağırır, hiçbir yerde `class_name` ile anmaz.
  - AudioManager (planned)

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
- Seed every RNG. A test that can flake is worse than no test.
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

Sırada: karakter portreleri/görsel varlıklar (ColorRect yer tutucuları hâlâ
duruyor). Moral ve stres dengesi çözüldü - aşağıdaki kayıtlara bakılabilir.

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

## Quick Start

1. Open `project.godot` in Godot 4.2+
2. Create your first scene in `scenes/main.tscn`
3. Create scripts in appropriate `scripts/` subfolders
4. Reference scenes/scripts using `res://` paths
5. Push to `main` branch to trigger automatic Web export & deployment

## Useful Links

- [Godot 4 Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [HTML5 Export Guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
