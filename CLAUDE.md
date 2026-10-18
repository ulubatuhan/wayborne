# Wayborne - Godot 4 Project Guide

## Vaat ve Sütunlar

> **Durum: öneri, kullanıcı onayı bekliyor (görev Y-A01, Y-A02).** Cümleler yapılacaklar listesindeki kullanıcı notlarından
> alındı; onaylanınca bu kutu kalkar.

**Vaat.** Bir kervanı kuşaklar boyu yolda tut. Her karar yola bir iz, her ölüm deftere bir satır olur.

Her yeni özellik bu cümleye karşı sınanır: yola ya da deftere bir iz bırakmıyorsa gerekçesi sorulur.

**Dört sütun.** Yol yaşar · İnsanlar aşınır · Defter unutmaz · Ticaret bilgi oyunudur.

- Her yeni sistem ya da görev, hizmet ettiği sütunu (en az birini) adıyla belirtir.
- Sütunların üstünde kullanıcının ilkesi durur: **derinleşme, asla sadeleştirme.** Bir sistemi sadeleştirerek çözmek
  önerilmez; ölçülmüş ve korunan sistemler (beş kapasite yolu, merkez, kıyafet statları, haydut büyücü, beden statları)
  kesilmez.

## Stack

- **Engine**: Godot 4.2+
- **Language**: GDScript
- **Target**: PC (Windows). Web derlemesi yalnızca test ve CI içindir; Web performansı bir ölçüt değildir.

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
│   ├── util/              # Shared helpers (NodeUtil, TextureLoader)
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
  - `JourneyController`: the non-visual half of a journey (distance covered,
    calendar day, pace, camp, pending encounter, clock, event engine) -
    `road_journey.gd` keeps only presentation and input, reaching the state
    through property aliases. It is what makes the mid-journey autosave and
    headless tests of the walk/arrival rules possible.

- **scripts/events/**: Event & narrative systems
  - EU4-style road event cards: `GameEvent` → `EventChoice` → `EventOutcome`
  - `EventCondition` (triggers) and `EventWeightModifier` (MTTH-style weighting)
  - `EventEffect` is the *only* vocabulary an event may use to touch the world;
    `EventEffectApplier` applies it and enforces the never-total-loss clamps
  - `EventEngine`: eligibility filter, weighted draw, once/cooldown tracking,
    seedable RNG for reproducible runs

### Event Engine Rules

- Road events only. City interaction is deliberately **not** card-based.
- **A card should offer a tempting but risky option, wherever the story allows it.** At least one choice that pulls
  on the story (the greedy, the kind, the proud one) but costs something mechanically when it goes wrong. "As many as
  possible", not "every": a card that is only a loss (the wagon breaks) needs no bait. Cards written before this rule
  have not all been reviewed against it (task Y-E03).
- A caravan can be ruined but never wiped out - see **Caravan Ruin Rules**
  below for exactly how far "ruined" goes. The clamps live in
  `EventEffectApplier`/`CaravanState`, never in individual events.
- Locked choices are shown disabled *with their reason*, not hidden, so the
  player learns what to prepare for next time.
- **A choice that opens combat says so before it's picked, not after.**
  `road_journey.gd`'s `_choice_triggers_combat()` scans a choice's
  `effects` **and its outcomes' effects** for `TRIGGER_COMBAT` (a check
  whose failure turns into a fight - `evt_deserter_search` - is a choice
  that can open combat too) and appends the road's current effective
  danger (`_weathered_danger()` - the same number the HUD's danger bar
  already shows) straight onto the button. A steep win-rate gap between
  road-danger tiers is a real difficulty curve, not a bug, but a fight the
  player couldn't see coming *is* a legibility bug - the fix is telling the
  player what they're gambling on, not softening the odds.
- All player-facing event text lives in `data/locale/events.csv` (effect
  lines in `game.csv`) as translation keys; scripts call `tr(key)`. Never
  hardcode event prose.
- New effects must be added to the `EventEffect.Type` enum **and** handled in
  `EventEffectApplier`, otherwise they silently do nothing.
  `test_event_effects::_test_every_effect_type_is_handled` scans the
  applier's source for a `match` arm per enum value - a runtime probe could
  not see it, because an unhandled type returns an empty result and an
  empty result is the right answer for some types (`SET_FLAG`).
- **A choice that falls on a named person says who before it is picked.**
  `EventEffectApplier.get_choice_target()` reads the same selector the apply
  path uses (`LEAVE_BEHIND`, `PARTY_HP`), and the card appends that name to
  the button. "Leave someone behind" with the someone decided afterwards by
  an algorithm took the heaviest decision in the game out of the player's
  hands - the same legibility rule as the check preview naming its roller.
- **A chosen option resolves through exactly one path: `EventResolver`.**
  Effects → skill-check roll → weighted outcome → outcome effects → the
  event's XP used to live inside `road_journey.gd` and was hand-copied into
  `playthrough_demo.gd`, `simulate_journeys.gd` and `simulate_career.gd` -
  every change (Faz 17's `resolve_check()`) had to land in four places.
  `EventResolver.resolve_choice()` now owns the order; the screen only
  narrates the result and opens side channels, and each harness passes its
  own effect hook (`Callable`) when it needs one (the road's `TRAVEL_DAYS`
  wrapper, the simulator's inline combat). `EventResolver.stop_context()`
  is likewise the one place a road stop becomes a `near_*` flag.
- **Only `DEBT_SETTLE` pays a debt.** A negative `GOLD` goes through
  `spend_or_owe` and *adds* debt; `DEBT_SETTLE` credits `amount` against the
  debts in kind (overdue first, oldest due first) through
  `GameSession.settle_debts_in_kind()`. It never produces gold, discards
  anything beyond what is owed, and credits the overdraft's share to the
  purse - the overdraft is the purse's mirror, so clearing it only in the
  ledger would bring it back on the next balance change.
- **Events never kill.** `PARTY_HP` clamps at 1 HP; the doors to death are
  combat and starvation (see Character & Party Rules). `LEAVE_BEHIND` removes
  the weakest non-leader companion as a *departure* (struck, not dead) - the
  leader is never left, and a lone leader cannot leave anyone.

- **scripts/character/**: Who the people in the caravan are
  - `CharacterStats`: eight base stats - six combat (Güç/Çeviklik/
    Dayanıklılık/Zeka/Sezgi/Karizma) plus two civil (Bilgelik/İnanç, Faz 17)
    - plus every derived value (max HP, initiative, accuracy, dodge, crit,
    damage bonus). Derived formulas live **only** here - the character
    screen and the combat engine both read them from this class.
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
  - `Trait` / `TraitCatalog`: sixteen huy (Faz 17: one
    virtue and one affliction per stat, now eight stats), each a small
    permanent modifier (`hp_bonus`/`dodge_bonus`/`accuracy_bonus`/
    `crit_bonus`/`damage_bonus`) read by `CharacterData.get_max_hp()/
    get_dodge()/get_accuracy()/get_crit_chance()/get_damage_bonus()`
    alongside the class/height bonus - **combat must read these
    `CharacterData` wrappers, never `character.stats.get_X()` directly**, or
    trait bonuses silently don't apply (bkz. `CombatUnit.from_character`).
    Faz 17 also gave every trait a **behavioral layer** beyond combat -
    `check_bonus` (a small nudge to its own `affinity_stat`'s skill checks,
    read by `GameSession.get_best_effective_stat()`/
    `get_leader_effective_stat()`), `refusal_bonus` (only bites once a unit
    is already `is_stressed`, read by `CombatEncounter._try_refuse_order()`
    via `CombatUnit.refusal_bonus`), and three stat-specific bonuses that
    stack onto their matching stat-derived formula
    (`xp_gain_bonus_percent` onto `get_xp_bonus_percent()`,
    `deathblow_resist_bonus` onto `get_deathblow_resist_bonus()`,
    `stress_resistance_bonus` onto `get_stress_resistance()`) - see the
    Faz 17 PR-3 narrative (Development Status) for why each one was scoped
    this narrowly. A character carries at most
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
    Caravan Yard's "Demirci" section), Ring/Amulet are trinket-style
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

  - `FigureRig` / `Wardrobe`: the skeleton every person is drawn on and the
    sprite parts (clothes, armour, weapons) hung on its bones - see Wardrobe
    & Rig Rules.
  - `BeastRig`: the four-legged counterpart - horse, ox, wolf, bear, boar on
    one skeleton, their art found by path the same way.

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
- **A person has an id, not just a name.** Culture name pools hold sixteen
  names, so two companions called "Elif" are routine over a career, and a
  ledger keyed by name merged two dead people into one history.
  `CharacterData.character_id` is assigned by `GameSession.add_to_party()`/
  `set_player_character()` from a saved serial (`_next_character_serial`),
  written into every ledger line, and backfilled for old saves on load.
  `CaravanLedger.entries_for_id()` falls back to the name only for lines
  that predate ids.
- **A decision leaves a mark on the person it was made about.**
  `CharacterData.grievances` counts what was done *to* someone: left unfed
  by a deliberate meal choice (`GRIEVANCE_UNFED` - a genuine famine where
  everyone starves counts for nobody), kept out of a fight that was lost or
  cost a life (`BENCHED`), a death witnessed (`WITNESSED_DEATH`), passed over
  for the name (`PASSED_OVER`). Stress melts at the next inn; grievances do
  not. They only bite once someone has already broken:
  `get_break_departure_chance()` adds `GRIEVANCE_DEPARTURE_PER_POINT` per
  point on top of `BREAK_DEPARTURE_CHANCE`, capped at
  `MAX_BREAK_DEPARTURE_CHANCE`, so the measured break threshold in Stress
  Rules is untouched. `CaravanOverviewPanel.thought_for()` says the top
  grievance out loud, by name.
- **Hunger can kill - but only the hunger you chose, or a real famine.**
  `consecutive_hungry_days` counts nights without a meal and resets at the
  first one; from `STARVATION_HP_LOSS_START_DAY` (3) each hungry night costs
  `STARVATION_HP_LOSS_PER_DAY` HP, and a character who reaches 0 goes
  through `resolve_deaths(..., "LEDGER_CAUSE_STARVED")`. A caravan that feeds
  everyone never increments the counter, so Provision Rules' promise
  (correct stocking never starves) still holds - `test_memory.gd` asserts
  it. Without this, "who eats tonight" was a stress dial, not a choice.
- **The nameless go hungry too, and it adds up.** Leaving the crew unfed
  used to cost the same single morale hit as leaving one named person
  unfed - and since the crew are most of the mouths, "feed only the party"
  was always the cheapest mode. `crew_hungry_nights` counts consecutive
  unfed nights (saved; reset on a fed night and on city arrival), the
  morale penalty grows per night (`get_crew_hunger_morale_penalty`, capped),
  and from `STARVATION_HP_LOSS_START_DAY` one crew member dies each night,
  into the ledger by name (`LEDGER_CAUSE_STARVED`). The wagon is driven on
  by a new hand under a **new** name: crew names come from an ever-growing
  `_crew_name_serial`, because rolling by list index handed the dead
  person's exact name to their replacement.
- **The crew are nameless in combat, not in the ledger.** `crew_names`
  holds `PEOPLE_PER_WAGON` names per owned wagon, seeded from
  `caravan_name|serial` (a saved, ever-growing counter) and the leader's
  culture pool, so a reload never re-rolls them and a replacement never
  inherits a dead name. A wagon lost on the road (`_apply_wagon_losses_to_ownership`)
  records its two crew as dead (`LEDGER_CAUSE_WAGON_LOST`); a wagon *sold*
  does not - they are paid off, not lost. Crew still never fight (crew ≠
  combat party).
- Party order **is** combat rank order (1 = front). `party.tscn` is where the
  player reads and reorders it (reachable from the road HUD and the city map).
- **A body is three dials, not one, and none of them touches `stats`.**
  Height already bent HP and dodge; gender and body weight joined that
  same family rather than inventing a system. All three write into the
  five fields traits and equipment already use
  (`hp`/`dodge`/`accuracy`/`crit`/`damage`), so `CombatUnit.from_character`
  saw them with no new wiring. **The base stats stay clean**: a
  character's `stats` is the points the player spent plus the culture
  bonus, and nothing else - putting gender there would have silently
  moved the eight-point allocation economy and auto-allocate with it.
  - Direction is the player's own brief: a woman bends toward evasion and
    the critical hit, a man toward toughness and the heavy blow; heavy
    carries more and hits harder but is slow and **eats more**, lean the
    reverse. **The middle weight is exactly neutral** (every bonus zero,
    provision share 1.0), the same guarantee this file demands
    everywhere: a default character behaves as if the system did not
    exist.
  - **The "rogue" half is a check lean, not a combat number.**
    `get_body_check_modifier()` nudges only AGILITY/PERCEPTION/STRENGTH/
    ENDURANCE, at the same magnitude a trait's `check_bonus` uses, read
    by `GameSession.get_best_effective_stat()` beside it. The four stats
    that belong to the person rather than the body (Zeka/Karizma/
    Bilgelik/İnanç) are deliberately untouched - deriving a mind from a
    body would be both wrong and unnecessary.
  - **The first numbers were measured and cut.** At dodge ±3 / crit +2
    the whole win-rate table rose 2-7 points, because `create()`'s
    default is female and dodge is worth more than HP in this engine - a
    gender reading as plainly better would be an accident, not a design.
    See Ruin Rules' body A/B for what the numbers measure now, including
    the part combat cannot see: lean eats 22% less than heavy over a
    long road, which is a real counterweight in a game about attrition.
- Characters heal to full on city arrival (`finish_journey()`); the road is
  where damage accumulates.

- **scripts/combat/**: Turn-based combat
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
  its own hit.** A `CombatSkill` can carry `modifier_stat` (one of
  `CombatUnit.MODIFIER_STATS`: "accuracy", "dodge", "damage" or "prot"), `modifier_amount` and `modifier_rounds`; landing the
  skill calls `CombatUnit.apply_modifier()` on the target, and
  `CombatEncounter` ticks every unit's modifiers down by one each time the
  round number advances. `get_effective_accuracy()/_dodge()/_damage_bonus()`
  are what combat resolution actually reads - never the raw fields directly
  once a skill might have buffed/debuffed them. A skill with no damage, no
  heal and a non-enemy target (SELF/ALLY) applies its modifier without an
  accuracy roll - see `CombatSkill.make_buff()`. "prot" is read by the one
  damage door (`reduce_by_protection` → `get_effective_protection()`), so
  bleed and blight see broken armour too; `test_combat_core` fails on any
  modifier name outside the list, the same trap as an unknown status. Such a
  skill also applies its `shift_amount` to itself (a real "Step Back") -
  shifts used to run only on the attack path.
- **Each class owns one buff axis and one debuff axis, and only the Clerk
  heals.** Guard gives armour (`brace`), Hunter dodge (and steps back),
  Breaker damage and *breaks armour* (`shield_break`, −25 PROT), Clerk
  accuracy (`keep_ledger`) and the only heal (`rousing_speech`). Three
  classes had carried the same dodge buff and the Guard out-healed the
  healer. `test_combat_core::_test_each_class_owns_its_axes` locks it; the
  re-measured win-rate table and its one out-of-band cell are in Ruin Rules.
- **Status effects are the second sanctioned reach beyond a hit**, and they
  are a separate field group from timed modifiers because they are a
  different thing: a modifier bends a number, a status *acts on its own at
  the start of a turn*. `CombatSkill` carries `status_kind`
  (`bleed`/`blight`/`stun`), `status_amount`, `status_rounds` and
  `status_chance`; a kind the engine does not know silently does nothing,
  the same trap as an unhandled `EventEffect.Type`, so
  `test_combat_core.gd` scans the whole catalogue for it.
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

- **Magic is the existing vocabulary in a new colour.** Seven first-tier
  D&D spells (`SkillCatalog._build_spells`) each sit on a mechanic that
  already existed: Fire Bolt and Burning Hands (an `ADJACENT` area, weaker
  than the bolt - the area rule) apply **burn**, a DoT through the one
  damage door like bleed; Ray of Frost applies **chill**, which deals no
  damage - its `amount` is the dodge it takes away, plus
  `CHILL_ACCURACY_PENALTY`, and `NON_DAMAGING_STATUSES` keeps it out of
  `drain_status_damage`; Sleep is a stun; Arcane Shield a `prot` buff;
  Magic Missile a +40 accuracy hit (still capped by `MAX_HIT_CHANCE`).
  Burn and chill resist reuse the body's bleed and blight resist
  (`CharacterData.get_burn_resist`/`get_chill_resist`) - a new resist axis
  would have shifted the eight-stat budget. `EnemyCatalog.ROGUE_MAGE` is
  ready and **never spawned by any squad builder** (`test_combat_core`
  asserts it): which event opens a wizard is a lore decision (LORE.md
  §3.3: wizards are rare and unwelcome).
- **A skill says how it looks, not only what it does.** `CombatSkill.element`
  ("" or fire/frost/poison/arcane/sleep) and `delivery` (arrow, thrown,
  sling, flask, bolt, ray, missiles, spray, cone, aura; "" = melee, styled
  by the attacker's weapon) are read only by the screen.
  `CombatFx.hit_style()` turns them into the target's reaction
  (`reaction_clip`: pierce → `hit_pierce`, slash → `hit_slash`, fire →
  `react_burn`, frost → `react_freeze`, poison → `react_poison`; a miss is
  `defend` with a shield, `dodge` without) and `CombatFxLayer` flies the
  projectile and plays the impact. The engine exposes `last_skill`/
  `last_actor` and `skill_resolving`, because barks go to the target and
  carry no skill.
- **What hits stays.** An arrow or thrown blade that lands is added to
  `CombatUnit.stuck` (at most `MAX_STUCK`, placed in order - never with the
  encounter's RNG, which would change the fight) and drawn on the torso
  until the fight ends; it appears when the projectile arrives, not when
  it is loosed.

- **Level buys resistance, not stats** - `CharacterData.get_bleed_resist()`
  and its siblings add `RESIST_PER_LEVEL` per level on top of the
  Dayanıklılık-derived base, capped by `MAX_STATUS_RESIST`. This is not an
  invention: it is exactly what the Progression Rules research already found
  the genre's reference game does (a resolve level grants *only* resist growth), and
  measurement said it was needed - with resistance coming from Dayanıklılık
  alone, levelling bought nothing defensively for the classes that do not
  invest there. Combat reads the `CharacterData` wrapper, never
  `character.stats`, for the same reason trait and equipment bonuses do.

- **Area skills must never beat single-target skills on the same side.**
  `CombatSkill.Area` is `SINGLE` (default, so every pre-existing skill is
  untouched), `ADJACENT`, `ALL` or `RANDOM`. The damage difference is set in
  the **catalogue, not the engine**: a global "area skills do 60%" multiplier
  would mean a skill's number is read from two places. `test_combat_core.gd`
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
- **Death has one door: `resolve_deaths(dead, cause_key, location_id)`.**
  Combat and starvation both go through it; it writes the ledger line with
  its cause and place, marks every survivor with `GRIEVANCE_WITNESSED_DEATH`,
  and - if the leader died - returns `heir_candidates` (by seniority)
  instead of choosing. `resolve_combat_deaths()` survives only as the
  backward-compatible wrapper the harnesses use (it auto-appoints the
  senior).
- **The heir is chosen, not announced.** `SuccessionPanel` lists the
  survivors with the senior preselected; `appoint_heir()` performs the
  generation step. Picking someone else costs the senior a
  `GRIEVANCE_PASSED_OVER` and `PASSED_OVER_STRESS` - the mechanically best
  heir and the one the company would follow are allowed to be different
  people. The panel is still unskippable: confirming a choice is its only
  exit.
- **Seniority is time served, not level.** `_compare_seniority` reads the
  earliest `KIND_JOINED` day (`get_join_day`), then level, then XP. As a
  level sort, a late, high-level guild hire outranked a companion who had
  walked since the founder - the opposite of what *kıdem* means.
- **The ceremony testifies.** Each candidate line says how many days they
  served under the fallen leader and whether they were kept out of the
  fight that killed them - read from the ledger and the fight's roster, no
  new saved field. And grief is weighted by shared time: in
  `resolve_deaths`, a survivor who walked `SHARED_GRIEF_DAYS` with the dead
  takes `SHARED_GRIEF_STRESS` on top. The grievance stays equal for everyone
  - the weight lands on stress, which melts, not on grievance, which does
  not, so the measured departure cap is untouched.
- **A ledger line is a memory, not a statistic.** Entries carry `cause`
  (a translation key, `LEDGER_CAUSE_*`) and `location`;
  `CaravanLedger.describe()` is the one formatter every screen uses ("… fell
  to wild beasts, near Kurtboğazı (day 43)"). Lines without a cause (old
  saves, joins, successions) keep the old "name — kind" shape.
- **The ledger never starts empty.** `start_playthrough()` writes a
  `KIND_FOUNDER` line first: the name the player inherits was already
  someone's struck-through name. It is struck but counted by nothing -
  `companions_lost`/`companions_died` read `KIND_DIED`/`KIND_DEPARTED` only -
  because the founder is an inheritance, not a loss.
- **The event pool reads the ledger now, as this section always claimed.**
  `build_event_context()` exposes `companions_died`, `companions_departed`,
  `companions_lost`, `lineage_generation` and `days_as_leader`; for a long
  time only the campaign context had them and no event could ask.
- **A loss cannot be bought.** `companions_lost` (event and campaign
  contexts both read `get_companions_lost()`) excludes departures whose
  cause is `LEDGER_CAUSE_DISMISSED`. Counting every departure let two cheap
  market-square hires, dismissed in town, satisfy the finale's "two struck
  names" gate - the one gate that reads loss, bought with gold. Left behind,
  broken and gone, died, lost with a wagon: those still count.
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

### Art Rules

The game was drawn in `ColorRect`s: the road was two rectangles and
fourteen sliding lines, the city five buttons, the caravan a row of
coloured boxes. The complaint - *"it looks like we are making a game in
Excel"* - was correct, and the deeper half of it is that a rectangle
cannot lie about being still but lies immediately once it moves.

The world (road, city, combat, menu backdrop) is drawn in `_draw()`. The
UI chrome has started moving to textures - see Waybook UI Rules - and
`ArtPalette` stays the colour authority either way; drawing functions give
way to textures one screen at a time.

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
- **A figure that moves needs joints.** `FigureRig` (see Wardrobe & Rig
  Rules) solves hip → knee → foot with two bones; swinging a single-piece leg reads as scissors. The
  foot stays put while it is on the ground, so the figure does not slide.
  Wheels and walk cycles advance with **distance, not time** - a stationary
  wagon whose wheels turn is the vehicle-shaped version of a sliding
  rectangle.
- **Palettes are shared with combat.** `WalkFigure` reads
  `CombatFigure.ARCHETYPES`: the guard you saw in the fight walks the road
  in the same colours. Skin tone comes from `CharacterData`, height scales
  the figure - what character creation chose has to be visible or the
  choice is only text.
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
- **The brief now opens with where you are, not just what to do.**
  `CityBriefPanel._welcome_heading()` prints the city's own name (a
  proper noun, same exemption as the culture name pools - not run through
  `tr()`) as the panel's first line, with a generic, suffix-free
  `UI_BRIEF_WELCOME_LINE` ("Hoş geldiniz.") under it. Turkish's dative
  case ("İpekevi'ne", "Yeşilova'ya") needs a different buffer letter per
  city name depending on vowel harmony, which a `%s`-formatted key cannot
  get right for names not yet written - splitting the city name onto its
  own line sidesteps needing that logic at all, for this or any later
  city.
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
  is a depth rule, not a fill: the nearest strip is the blackest one.
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
  - **Skin and height stay player choices.** The body is rendered grey and
    multiplied by the skin tone, like the mannequin's ALBEDO contract.
    Height is one uniform scale over the whole frame
    (`CharacterData.get_height_scale()`, 155-250 cm, user's call) - six
    screens used to clamp it to 0.86-1.14 each, so nothing over 200 cm
    showed. Random recruits stay under `NATURAL_MAX_HEIGHT_CM`.
  - Crew use `BodyFrames.CREW_BODY`; enemies still draw on the old part
    rig until clothing modules exist (open: `QUESTIONS.md` #13-15 - the
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
  - Atlas pages get runtime mipmaps (`BodyFrames._with_mipmaps`): frames
    are drawn ~5x smaller than rendered, and `.import` files are not in the
    repo, so an import setting could not carry it.
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

### Rendered Road Rules

Yolun manzarası (Faz 27) kasabalarla aynı hattan render ediliyor ve düzeni
Oregon Trail'den (2021) uyarlandı, paleti kasvetli: alçak kamera, yol
ekranın ortasında (`TravelBand.RENDERED_ROAD_RATIO` 0.72), önde kameraya
yakın koyu ve bulanık bir ot tarlası, arkada diz boyu ot ve prosedürel
ağaçlar, uzakta puslu sırtlar. Ayrıntı ve görüntüler
`docs/ui/REDESIGN.md` §2b'de.

- **Dört katman, biyom başına, tek kapı: `RoadStrips`.** `far`/`mid`/
  `ground` `TravelBand`'de, `fore` `TravelForeground`'da çiziliyor;
  `tools/ui_scenes/road_scene.py` (Blender) + `road_post.py` üretiyor,
  çıktı `data/assets/ui/road/<biyom>/`. Bir biyomun dört katmanı yoksa
  şerit eski prosedürel çizime düşer (`RoadStrips.has_biome`) - yarım bir
  set prosedürelle karışırsa iki prodüksiyon görünür.
- **Dikişsiz olmak bir kural, bir sonuç değil.** Sahne x'te periyotlu,
  doku tekrarı şeride tam sayı kez sığıyor, kar gürültüsü x'i bir çembere
  sarıp okuyor, mürekkep türevi ve bulanıklık yatayda sarmalı. Kar
  gürültüsünün düz dünya koordinatından okunduğu ilk sürüm her döşemede
  dikey bir dikiş bıraktı; `test_grim_ui` zeminin iki kenarını
  karşılaştırıyor.
- **Bağlantı noktaları render'ın kendisinden.** `RoadStrips.SPEC` (alttan
  piksel) `road_scene.py`'nin `LAYERS`'ından türüyor ve test her biyomun
  `layout.json`'ıyla karşılaştırıyor; kırpma yalnızca üstten yapıldığı
  için alttan ölçü değişmez.
- **Resim nötr gün ışığında; saat ve hava sistemin kendisi.** Katmanlar
  `_light` ile çarpılıyor, kapalı hava griye çekiyor; pus (uzak sırt ve
  ağaç hattı) ve yolun tozu oyunda gökyüzünün ve ışığın renginden
  çiziliyor, resme gömülmüyor. Gökyüzü, güneş/ay, uzak şehirler ve yol
  durakları prosedürel kalıyor.
- **Mürekkep yalnızca kervanın düzleminde.** Uzak katman mürekkepsiz ve
  bulanık, ön tarla koyu ve bulanık: derinlik pustan ve alan
  derinliğinden geliyor, göz yola düşüyor.
- **Biyom geçişi rengin geçişiyle aynı oranda**
  (`RouteTerrain.biome_blend_at`); zemin opak olduğu için eskisi tam,
  yenisi üstünde beliriyor, saydam katmanlarda eskisi de sönüyor.

### Prop Rules

Vagon, kapı, değirmen, binalar, kamp, silahlar: dünyanın prosedürel çizilen
nesneleri artık figürlerle **aynı hattan** gelen render'lar - aynı güneş, aynı
dört ton, gölge × albedo. Kaynaklar CC0 paketler (Quaternius, Kenney,
KayKit; `art_source/models/props/LICENSES.md`).

- **Tek kapı: `PropArt`** (`scripts/ui/prop_art.gd`). Paket
  `data/assets/props/<id>/<katman>.png` + `props.tres` (`PropSheet`: ppm,
  katman konumları ve milleri, metre boyu). Konumlar eşyanın yere bastığı
  orta noktaya göre; ölçek çağıranın: `k = (oyun pikseli/metre) / ppm`. Bir
  eşyanın resmi yoksa `has()` yanlış döner ve çağıran prosedürel çizimine
  düşer - Wardrobe'un "sanat parça parça gelebilir" kuralı.
- **Döndürme ve eğme köşeleri hesaplanmış bir çokgenle, `draw_set_transform`
  ile değil.** RoadCaravan dönüş aynalaması için kendi dönüşümünü kuruyor ve
  tuvalin o anki dönüşümü okunamıyor; üstüne yazmak onu bozardı.
- **Hareket eden her parça kendi katmanı.** Tekerlek döner (`wheel`,
  `wheel_front` - ön tekerlek küçük, yarıçap oranıyla daha hızlı), branda
  salınır (`canopy`, tabanı sabit eğme), değirmen kanadı döner (`blades`),
  kapı kanadı lider yaklaşınca kalkar (`gate`, duvarın arkasında çizilir).
  Bir katman render edilirken diğerleri kameraya görünmez ama gölge düşürür.
- **Brandalı vagon sıfırdan kuruldu, `ArtDraw.wagon`'un oranlarıyla**
  (`tools/figure_pipeline/props/wagon_builder.py`): h = 1.6 m, tekerlek
  0.34h, tekerlekler ±0.30w, branda tepesi ~1.24h. Aynı `base`/`h` aynı
  kutuya düşüyor; kolon, koşum oku ve arabacı koltuğu hiçbir sayı
  değişmeden yerinde kaldı. `test_props.gd` kutuyu kilitliyor. Paketlerde
  hazır brandalı vagon yoktu; MegaKit'in arabası tek akslı ve gevşek
  parçalı. Yarım vagon (eşek arabası) aynı kurucudan.
- **Ölçek gerçek boy.** Model `size` (metre) ya da paketin kendi birimi ×
  katsayı (Medieval Village ×2.3, Modular ×2.9 - insan boyuna göre ölçüldü)
  ile oturtuluyor; yolda kişi ~0.094 × şerit / 1.73 m, hub'da ~36 px/m.
  Şehir haritasında **bütün binalar tek ölçekte** (bir karo `TILE_METRES`
  5 m): ilk sürüm her binayı ayak izinin genişliğine sığdırdı ve dar-uzun
  lonca kulesi devleşip pazarı örttü.
- **Silahlar dik render edildi, sap altta.** `PropArt.draw_between` resmi
  sap ucundan uca gerer; `WalkFigure.WEAPON_PROPS` aileyi silaha ve
  tutuşa (sapın payı) bağlıyor. Yay (kiriş çekiliyor) ve asa prosedürel.
- **Modüler paketin malzemeleri düğümsüz** (`diffuse_color` beyaz); taş/
  ahşap tonları `props.json`'daki `tints` kurallarıyla veriliyor. Kenney
  modelleri `Textures/colormap.png`'yi göreli yoldan arıyor - doku dosyası
  modelin yanında durmalı.
- **Kenney/Quaternius sahnesinde ibadet yeri yok** (Art Rules): kilise
  izometrik haritada bir çan kulesi.
- Ekran görüntüsü: `tests/screenshot_hub_scene.gd` gerçek `world_hub`'ı
  açıyor (kapı, yerleşim, araba); `screenshot_hub.gd` sahneyi elle kurduğu
  için bunları göstermez.

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
  `SLIP_PANEL` + `PAGE_LABEL`/`PAGE_HEADING` for paper with ink text).
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
  book, seals, icons), the ink rule and the paper slip.
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
- **Nine-slice geometry is measured, not guessed.** The one nine-slice
  left in the chrome is the paper slip (`SLIP_SLICE`); its margins must
  contain the pin and the torn corners whole, and must leave a centre to
  stretch (`test_waybook_theme.gd` checks it).
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
  left the top bar: a plate in the top-right of the world holds four
  `SurvivalGauge`s (vials for morale, stress and stamina, a blood stain for
  danger), each with its number and name written under it and liquid
  colours from `ArtPalette.UI_GAUGE_*` (the hub still uses `PulseBar`); the clock has a `TimeDial`
  (R3, sun at noon, stars at midnight); attention and an open road signal
  show their R6/R7 icon, the signal flashing blood when it escalates and
  moss when it is caught.
- **Wear shows at the edge of the world, never as a number - but only
  for hunger now.** Stress used to bleed ink in from the frame (G11
  bleed) past `EDGE_STRESS_FROM`, and a third edge (G11 frost,
  `cold_level()` - winter adds most, a mountain pass a little even out
  of season) shaded the world in the cold. Both were removed outright on
  direct player feedback - `road_journey.gd` no longer builds
  `_stress_edge`/`_cold_edge` at all, and `ArtPalette.UI_EDGE_STRESS`/
  `UI_EDGE_COLD` are gone with them. The hunger scorch (G11 scorch) is
  the one edge that survives: the longest hungry streak in the party
  still scorches the frame, coloured from `ArtPalette.UI_EDGE_HUNGER`.
  The source sheet was painted on a torn paper card; the pipeline cuts
  the card off and ships only the ink as a white mask - as shipped
  first, the card's white border and pale wash covered the scene. The
  mask is drawn **whole, stretched over
  the screen** (`STRETCH_SCALE`): for one round it was nine-sliced so
  the thickness would not depend on the aspect ratio, and the player
  rejected it - the mask is painted as a whole frame and slicing
  separated each corner from its sides.
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
  Biomes step at most two places along `BIOME_CHAIN`, because steppe
  straight into mountains does not read as geography.
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
  affliction, rarely (15%) the inverse where hardship forges a
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
- **The HUD's stress vial shows the average and marks the person.** The
  average is the right answer to "what shape is the company in", the wrong
  one to "who is about to break" - so when someone sits 5+ above it, the
  vial carries a notch at their value and the tooltip names them
  (`GameSession.get_max_stress_character()`, `set_marker()` on both
  `PulseBar` and the road's `SurvivalGauge`).
  The genre's reference game never shows a party-level bar at all; this keeps the bar
  and adds the person.
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

**Re-measured in Faz 17 PR-8 ("Sayı ve denge turu").** Faz 17's own PR-8
exists to re-run every simulator against the cumulative weight of Faz 10-17
and refresh whatever drifted — the same discipline this file has applied to
itself since the very first "measurement bug" entry. `simulate_career.gd`
against the current codebase, same three policies, same 8×40 shape:

| chapter | closed (kampanyacı) | earliest | median | latest |
|---|---|---|---|---|
| İlk Yol | 8/8 | 1 | 1 | 1 |
| Bir Kadro | 8/8 | 5 | 6 | 9 |
| Ağ | 8/8 | 5 | 6 | 9 |
| Temiz Defter | 8/8 | 5 | 6 | 9 |
| Kendi Hanın | 8/8 | 10 | 12 | 13 |

Every chapter now closes for every caravan, and the finale lands at median
journey 12 (~65 game days) instead of 30 (~180). **This is not a Faz 17
regression — it is the "reputation is the scarcest resource" finding above
finally catching up with a fix that predates it.** Reputation Rules (this
file, Faz 11) rewrote reputation from "six ways down and none the player
controls" to "delivering pays" specifically *because* an average of ~1 at
journey 20 meant playing well never moved the stat that gates the game.
That fix was correct and stays — but nobody re-ran `simulate_career.gd`
against it until now, so this table (measured on the pre-fix reputation
economy) kept citing scarcity that no longer exists: a delivery-focused
caravan now carries reputation into the 50s-90s by journey 20, not ~1, so
`reputation >= 15` on the finale is not a gate at all anymore — the finale
is now paced almost entirely by `days_as_leader >= 60`, which a caravan
whose leader survives crosses by journey ~11-12 regardless of anything the
player chose to prioritize.

**This was deliberately not "fixed" by raising the finale's reputation bar.**
Reputation growing with good play is the *intended* outcome of the Faz 11
fix, not a bug to suppress — a finale that arrives sooner for a caravan that
delivers well is consistent with "playing well moves the stat that gates
the game," the exact sentence Reputation Rules was written to make true.
Raising the bar back up would fight that fix rather than accept it, and
this file's own history (the chapter-3/chapter-4 threshold tuning above)
already shows finale thresholds are sensitive enough that they are not
touched without dedicated, multi-policy measurement of their own — a
separate, narrower question than "did the numbers in this table go stale."
Wealth-gate removal already established the design answer here too: the
finale is a threshold the player crosses, not a wall tuned to resist
crossing, and the epilogue's free-trade tail (now ~28 journeys instead of
~10) is exactly where the game already says the post-finale game lives.

One genuine bug **was** found and fixed in the same pass, unrelated to this
table's drift: `GameSession.fulfill_commission()` (Faz 17 PR-4's guild
commissions) carried no repeat guard at all. As long as a world event
stayed active (8-30 days) and the resource cost was affordable, the same
commission could be completed every single call — Ticaret Fuarı Sponsorluğu
alone nets +60 gold and +2 reputation per call for a flat 80-gold outlay,
with nothing to stop calling it in a loop. This is the same class of
exploit Haggling Rules closes for "repeat the same lowball three times" -
a system's own rules have to survive being pushed on repeatedly, not just
read correctly once. `_fulfilled_commission_starts` (keyed by the active
event's own `started_day`, the same identity `WorldEvents` itself uses) now
blocks a second completion of the *same* news instance
(`UI_COMMISSION_ALREADY_FULFILLED`, the same disabled-with-reason pattern
as every other locked action in the game) while still reopening the moment
a genuinely new instance of that kind starts. `simulate_career.gd` never
called `fulfill_commission()` at all, so this exploit is not what produced
the reputation numbers above — it is a real, separate finding the same
measurement pass turned up.

**Faz 18 touched the finale, and measured it the way this section demands.**
The finale now also asks for `companions_lost >= 2` (two struck names in the
ledger - dead or departed, crew lost with a wagon included, the founder
excluded). A threshold reached without losing anyone contradicts the
thesis; this is the one gate in the game that reads loss rather than
accumulation. Re-measured with `simulate_career.gd`, all three policies,
8×40:

| policy | finale closed | earliest | median | latest |
|---|---|---|---|---|
| kampanyacı (before) | 8/8 | 10 | 12 | 13 |
| kampanyacı (after) | 8/8 | 9 | 16 | 30 |
| genişleyen (after) | 8/8 | 9 | 16 | 30 |
| kontratçı (after) | 0/8 | — | — | — |

The finale no longer arrives on schedule: a caravan that loses people
early closes it by journey 9, one that keeps everyone waits until its
losses catch up. The contract policy's 0/8 is **not** this gate - that
policy's caravans stop at three wagons and never meet the finale's
existing `owned_wagons >= 4`, which is the "buying wagons crowds out
contracts" finding above, unchanged.

**Faz 24 closed the wagon/contract conflict, and the measurement is the
clearest this table has ever produced.** Growing now earns wagons (see
Caravan Ruin Rules), so the caravan no longer has to choose between
hauling its own goods and escorting someone else's. Re-measured,
`simulate_career.gd`, all three policies, 8×40:

| policy | finale | earliest | median | latest | wagons @40 | delivered @40 |
|---|---|---|---|---|---|---|
| kontratçı (before) | **0/8** | — | — | — | 3 | 41 |
| kontratçı (after) | **8/8** | 9 | 15 | 25 | 7 | 120 |
| genişleyen (after) | 8/8 | 9 | 13 | 22 | 10 | 61 |
| kampanyacı (after) | 8/8 | 9 | 13 | 22 | 10 | 60 |

The contract policy's 0/8 was never the loss gate - Faz 18 said so
explicitly: those caravans stopped at three wagons and never met
`owned_wagons >= 4`. Four earned wagons carry them to seven, and the
finale opens for every policy. Deliveries rise across the board
(41 → 120 for the contract policy, 11 → 61 for the expanding one)
because escort room no longer shrinks as the caravan grows - the
"buying wagons crowds out contracts" finding is the thing that was
fixed, not a number that drifted. **Every chapter now closes 8/8 under
every policy**, which is the same question Faz 17 PR-8 already answered
and deliberately did not suppress: a threshold the player crosses, not a
wall tuned to resist crossing.

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
- **A loan decision shows two numbers at once, not one.** `DebtPanel`
  used to show only the credit line's *current* state; the amount you were
  about to borrow and its effect on next time's line lived in two different
  places the player had to compute themselves. `get_available_credit_
  after_loan()`/`get_available_credit_after_repay()` (reads the same
  `get_loan_principal()`/`get_credit_limit()` formulas, invents nothing new)
  feed a two-column preview - immediate purse effect on the left, the
  credit line's permanent narrowing (or a repayment's opening) on the
  right - updated live as the amount spinner moves. Same principle as a
  choice showing its danger stripe before it's picked: the whole point is
  showing both consequences *before* the decision, not after.
- **Growing earns wagons; buying them still costs a contract slot.**
  Wagon ownership had exactly one door - gold, at a price that climbed
  with every purchase - and Campaign Rules had already measured where
  that led: a caravan that lives on contracts freezes at three wagons
  and can never pass the finale's `owned_wagons >= 4`, so one honest way
  of playing was simply locked out. `GameSession.grant_earned_wagons()`
  opens a second door: the leader's level and the caravan's reputation
  are two threshold lists (`WAGON_LEVEL_MILESTONES`,
  `WAGON_REPUTATION_MILESTONES`) and each threshold pays **+1 wagon,
  once in a lifetime**.
  - **The milestone is recorded, not compared against a target**
    (`_earned_wagon_milestones`, saved - `_delivered_wagon_quest_ids`'s
    pattern). That is what keeps Ruin Rules intact: a wagon lost on the
    road is really lost, and does not quietly return at the next
    threshold. A threshold grants a *new* wagon; it never tops ownership
    up to a number.
  - **The gift brings its own column slot.** `get_wagon_capacity()` is
    `DEFAULT_MAX_WAGONS + earned`, so escort room is `6 - bought`
    regardless of how much the caravan has grown. A *bought* wagon still
    eats a merchant slot - that trade-off is real and stays; what is
    gone is growth forcing it. Every screen reads the function now, and
    `load_from_dict` reads the milestones **before** it clamps
    `owned_wagon_count`, or a seven-wagon save would be clipped back to
    six on every load.
  - Not free either: each wagon is `PEOPLE_PER_WAGON` more mouths (see
    Provision Rules), so a grown caravan eats more. Measured results are
    in Campaign Rules.
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
- **`POWER_SCALE_PER_PARTY_MEMBER` now has a visual echo, not just a
  formula.** The world map's "you are here" pin (`world_map.gd`'s
  `SafeZoneRing`) carries a ring whose radius shrinks as `owned_wagon_count`
  grows (`safe_zone_ring_radius()`, linear from `SAFE_ZONE_RING_MAX_RADIUS`
  at one wagon down to `SAFE_ZONE_RING_MIN_RADIUS` at
  `SAFE_ZONE_RING_WAGONS_FOR_MIN` and clamped there after) - purely
  decorative, no new number. It's the same mechanical fact this section
  already states ("kervan büyüdükçe onu durduranlar da güçlenir") finally
  drawn: growing the caravan should read as *tightening*, not as safety,
  the inverse of a game whose growth mechanic reads as strength.
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
the combat-depth pass** (PROT, the per-round speed die, Death's Door,
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

**The whole table moved down, and the cause is CMB-1, not the content added
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

**The class-identity pass (T-04) re-measured the table, and one cell is
knowingly outside the target band.** Each class now owns one buff axis
and one debuff axis (Guard: armour given; Hunter: dodge; Breaker: damage
given, armour broken; Clerk: accuracy, and the only heal) - see Combat
Rules. Same seeds, same greedy policy:

| party | 20% | 40% | 65% | 90% |
|---|---|---|---|---|
| 1 | 53% | 55% | 23% | 23% |
| 2 | 100% | 70% | 52% | 52% |
| 3 | 100% | 97% | 70% | 70% |
| 4 | 100% | 100% | 92% | 92% |

Party 2 at 65%/90% is +9pp against a ±8pp target. It was traced, not
guessed: the matrix fields an all-Guard party (the default class), and
the greedy policy spent the rank-2 Guard's turn on an 8-point `rally` heal
whenever the front fell under half HP. Removing that heal returns the turn
to `spear_thrust`, which is worth more. Guard HP (6 → 4) and spear crit
(3 → 0) were each tried and left the cell at 52%; spear damage 9 → 8
brought it back but dropped the unarmed lone traveller 12pp and the
level curve 14pp, a larger distortion than the one it fixed. The cell
moves one battle in sixty beyond the band, in the direction the game
already wants for the starting pair. A policy that also casts buffs was
tried and **reverted**: casting whenever the cooldown ends halves the
attack rate and crashed every cell (party 4 at 65% → 52%) - it measured
its own rule, not the kits. The level table moved 45/62/70/75 →
42/53/68/70 (mixed pairs lost the Guard's heal) and the progression
ladder's first rung 57% → 70%.

**The body pass (gender and body weight) moved the table, and the cause
is the harness's default, not a balance change.** The matrix builds its
party with `CharacterData.create()`, whose default is female - and female
now carries dodge +3 / crit +2 against HP −2, so the table below is an
all-female company rather than a neutral one:

| parti | 20% | 40% | 65% | 90% |
|---|---|---|---|---|
| 1 | 57% | 57% | 25% | 25% |
| 2 | 100% | 67% | 53% | 53% |
| 3 | 100% | 100% | 77% | 77% |
| 4 | 100% | 100% | 92% | 92% |

Against the T-04 table that is +2/+4 on the lone traveller, −3/+1 on the
pair, and **+7 on party 3 at the two dangerous tiers**. Party 2 at
65%/90% - this file's long-standing tightest square - is unmoved at 53%.
The numbers were cut once already for this reason (see Character & Party
Rules); cutting them further until the *all-female* table reproduced the
old one would be tuning a design to preserve a harness artifact, so the
table is restated instead.

**The honest per-body measurement is its own A/B** (`_report_body_impact`,
the equipment A/B's skeleton: one character, 50% danger, 60 battles):

| beden | kazanma |
|---|---|
| kadın · orta | 55% |
| erkek · orta | 70% |
| kadın · ince | 47% |
| erkek · iri | 83% |

A male combat edge is the brief, not a bug ("erkekler daha dayanıklı ve
güçlü"), and a solo fight at 50% danger is the most exaggerated place to
read it - in a mixed party the whole table moved ~2pp. Two counterweights
sit outside this table by construction: the agility/perception check lean,
and provisions, where lean eats 0.9 against heavy's 1.15. **Neither is
measurable in a win rate**, which is exactly why the A/B is reported next
to them rather than instead of them. Male damage was already cut 2 → 1
when the first A/B read a 22pp gap at `orta`.

### Progression Rules

"Levelling should feel like progress" was the open question after the ruin
pass, and the answer came from looking at what comparable games actually do
rather than from instinct. The instinct - *give every stat a combat
derivation* - is **not** what the genre does:

- **The genre's reference game**, the one this game took as its model, gives a resolve
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
- **Its sequel** removed hero levelling outright, moving growth to
  meta-progression unlocks at the Altar of Hope.
- The **dump-stat literature** is blunt about Charisma: it became a dump
  stat *because* morale, reaction rolls and hirelings stopped mattering to
  how people played. The prescribed fix is to make the systems it feeds
  matter - not to bolt combat numbers onto the stat.

Wayborne already had that reference game's equipment axis, and it measurably
works (bare 52% vs fully geared 70%). What it lacked was a link between the
level and that axis, and any combat consequence for Karizma at all.

- **`Equipment.required_level` is the level's job.** Tiers used to be gated
  by gold alone, so a level-1 party could wear tier 3 the moment it could
  pay - the level meant nothing on the strongest axis in the game. Tier 2
  needs level 3, tier 3 needs level 6. Trinkets (ring/amulet) stay
  ungated: they are found, not bought, and a curio you cannot use is a
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
- **Buying the shortfall silently did nothing, because of signal order.**
  `caravan_planner.gd::_on_buy_provisions_pressed()` called
  `wallet.spend(cost)` *before* `change_provisions(shortfall)` - but
  `Wallet.spend()` emits `balance_changed` synchronously, which
  `_on_wallet_changed()` catches to call `_refresh()` immediately, one
  statement too early: the screen re-read `get_provisions()` while it was
  still the pre-purchase count, showed the shortfall as unresolved, and
  never refreshed again (`change_provisions()` fires no signal the planner
  listens for). The gold was spent and the provisions *were* added -
  invisibly - so both the "buy" and "confirm and set out" buttons read as
  permanently broken. Fixed by adding the provisions **first** (aborting
  before spending anything if the wagons have no room - `add_to_cargo` is
  all-or-nothing) and calling `_refresh()` explicitly afterward, instead
  of leaning on a signal's side effect to happen in the right order.

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
- **What #22's own design note asked for, and how much of it landed:** a
  read-only view into a *foreign* trader's wagon (Faz 16 - see
  `MerchantDialoguePanel` below), and a dedicated "Kervan Yükü" screen
  for placing cargo wagon-by-wagon on purpose ahead of time (rather than
  discovering the split by walking up to each wagon). The first shipped
  in Faz 16 as a dialogue that revealed only the trader's hidden
  *disposition* (`NpcDisposition`) - a later pass gave it a real cargo
  model too (bkz. `CaravanState.merchant_cargo_by_name`,
  `GameSession.get_merchant_cargo_entries`): a seeded, read-only
  `Inventory` per escorted merchant, 1-3 trade goods at 3-14 units each
  (never provisions), tohumlanmış from `merchant_name + journey_start_day`
  so the same look mid-journey shows the same wagon but a later journey
  can find a different one. It reads through the exact same
  permission/force/persuade gate as the disposition (`is_merchant_known`),
  so `MerchantDialoguePanel`'s "Vagonun yükü:" section is simply a second
  reveal behind the same door, not a second mechanic - and the "no write
  path" guarantee holds unchanged: this `Inventory` never enters
  `GameSession.wagon_inventories`.
- **The second piece - "Kervan Yükü" - shipped later, as `CaravanCargoPanel`.**
  Opened from the Kervan Avlusu, right beside "Kervan Dökümü" (same
  code-built sıra-düğmesi pattern, same scene-less `CanvasLayer` as
  `WagonPanel`/`CaravanOverviewPanel`). Each wagon gets its own column -
  its own load/capacity header, then its own cargo list, exactly what
  `WagonPanel` already shows for the single wagon the player is standing
  next to, just all of them side by side. Every item row carries chevron
  buttons (`UiIcon.CHEVRON_LEFT/RIGHT` - **drawn, not dialed from a font**,
  the same reasoning as every other UI mark since the tofu-box bug, bkz.
  Art Rules) that move that item to the *neighboring* wagon.
  - **A move is hep-ya-da-hiç, but "hepsi" is now a size the player picks.**
    The first version moved only the item's full stack, deliberately,
    because the screen had no quantity widget in its vocabulary yet. A
    later pass added one: each row carries a `SpinBox` (min 1, max the
    row's current quantity, defaulting to the full stack - so the
    original one-click "move everything" is still exactly one click) and
    `GameSession.move_cargo_between_wagons()` gained a `quantity`
    parameter (-1, the default, still means "everything," preserving
    every existing caller unchanged). The all-or-nothing rule itself
    didn't weaken - `add_to_cargo`'s reasoning still holds, just applied
    to whatever amount the player dialed in: that amount either moves in
    full or nothing moves. `get_cargo_move_block_reason()` is the same
    disabled-with-reason door as `get_wagon_sale_block_reason()`/
    `get_craft_block_reason_in_wagon()`, now reactive to the spinbox - a
    quantity too large for the destination flips the arrow disabled and
    the "reason" label visible the moment the spinbox value changes, not
    only at the row's initial build. The reason still can't live *as* the
    button's own text (a chevron icon has none), so it sits in a small
    label right next to the button, always visible, never only on hover -
    a hover-only tooltip would fail the same "not hidden" rule dressed up
    as a UX shortcut. One consequence worth naming: a smaller quantity can
    now fit a destination the *full* stack never would have - the
    constraint reads the requested amount, not a fixed "does it all fit"
    question, which is the entire point of giving the player the dial.
  - **This does not weaken craft's own constraint, it is the intended way
    to work around it on purpose.** "Cloth left in the wrong wagon cannot
    be turned into a bandage at a different one" (bkz. Atölye's own rule
    above) stays exactly as strict as it was - this screen does not add a
    second path for `craft_in_wagon()` to read across wagons. What it adds
    is a *deliberate* way to move the cloth to the right wagon **before**
    walking up to it, instead of discovering the mismatch only once
    already standing there. The city (planning) now has a lever for a
    constraint that previously only bit on the road (discovery).
  - `tests/test_wagon_inventory.gd` locks the three original claims (a
    default move carries the item's entire quantity to the neighbor and
    empties the source of it; a destination without room blocks the move
    and leaves the source untouched, `UI_CARGO_MOVE_NO_ROOM`; a malformed
    request - same wagon, an out-of-range index, an item the source
    doesn't actually carry - is rejected without touching anything,
    `UI_CARGO_MOVE_INVALID`) plus three more for partial quantity: an
    explicit amount moves exactly that much and leaves the rest in place;
    a quantity outside 1..available is rejected the same way an invalid
    request is; and a quantity too small to trip `UI_CARGO_MOVE_NO_ROOM`
    succeeds in a destination the full stack would have been blocked
    from.
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
- **The same news reads differently depending on who is listening.** The
  four `WorldEvents` "haber" cards (`evt_regional_war_news`,
  `evt_plague_outbreak_news`, `evt_trade_fair_news`,
  `evt_bandit_tribute_zone_news`) each carry five culture-framed body texts
  (`EventCatalog.NEWS_EVENT_CULTURE_TEXT_KEYS`, written out key by key -
  never assembled at runtime, or the undefined-key scan and a translator
  searching the codebase both go blind, the same trap `OnboardingPanel.
  TOPIC_KEYS` already warns about). A nomad hears a war as grazing land and
  herds lost; a valley trader hears it as ledgers in disarray; a highland
  traveler hears an old blood feud; a port merchant shrugs it off as trade
  routes shifting; a fisher reads it as a storm to be weathered - pure
  Lakoff-style framing (`road_journey.gd`'s `_framed_text_key()` swaps only
  which key `_render_card()` reads, keyed off the leader's own
  `culture_id`). **The mechanical effect never moves** - the same
  `WORLD_EVENT_START` danger delta or price shock fires regardless of which
  text was shown; only the title stays fixed and shared, since the event
  itself (and what it's called) is the same event no matter who's reading.
  Any event not in the table, or a culture with no variant, falls back to
  the base `event.text_key` untouched - old saves and any harness that
  doesn't build a full party never notice the table exists.

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
- **A standing order the planner does not know about is a starvation
  trap.** Camping every evening stops the column for `CAMP_HOURS` a day and
  burns `CAMP_PROVISIONS_COST` a night; `forecast_extra_days(...,
  walking_hours)` and `CaravanPlan.camp_provisions` put both into the
  planner's number, and `test_route_terrain.gd` asserts a caravan stocked
  that way still never runs out.
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
- `test_memory.gd` (Faz 18) locks the save's integrity - atomic writes with
  a backup, no recruit cloned by a reload, market stock not refilled by one,
  every `GameSession` script variable either saved or on a commented
  transient list - plus character ids, ledger causes/places, the founder
  line, grievances, starvation deaths (and that a fed caravan never counts a
  hungry day), the chosen heir, named crew dying with their wagon,
  profiteering memory, `LEAVE_BEHIND`/`PARTY_HP`, the stop cards, the
  finale's memory gate, `EventResolver`, `JourneyController`, and a
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
  where gold, reputation, wagons and campaign chapters land (see Campaign
  Rules for the numbers). Anything about progression over time needs the
  second tool; the first cannot see it, which is exactly why the campaign
  thresholds shipped unmeasured the first time.
- **A balance report needs more than one policy, for the same reason ruin
  tuning needed two knobs.** `simulate_career.gd` runs three — expand
  aggressively, stay lean and haul contracts, and follow the campaign — and
  the first two disagree so sharply (11 contracts delivered vs 41) that
  either one alone would have given a confidently wrong answer.

**A task is done when the screen shows it (görev Y-K01).** Work runs in two-week cycles; each cycle ends with a playable
build and a five-minute video of it. "Done" is said only after a screenshot of the real screen confirms it - a passing
test is not enough for anything the player sees, because the structural tests below never see appearance (see the
screenshot tools in this section). A claim of "fixed" that was never checked against the place the report pointed at has
been wrong twice in this file's history.

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

### Ana Hedefler

Oyunun aktif, henüz kapanmamış hedeflerinin tek listesi - **bundan sonra
yeni bir açık iş burada birikir, Development Status'un tarih akışı içine
dağılmış ayrı notlar olarak değil.** Bir madde kapandığında buradan
silinir; tarihçesi (nasıl karara bağlandığı, ölçümü) aşağıdaki Faz
anlatısında kalır - bu liste yalnızca "şu an açık olan ne" sorusuna cevap
verir.

- **Waybook'un kalan sanat borcu - Faz 22'de büyük ölçüde kapandı.**
  İkinci sanat turu (bkz. aşağıdaki Faz 22 anlatısı) yönetim ekranı
  arka planlarını, mal/durum/stat/görev/sınıf ikonlarını, haritayı ve
  mührü çok daha yüksek çözünürlükte yeniden gönderdi ve hepsi
  `data/assets/ui/waybook`'a işlendi. Gerçekten açık kalan: beş ikon
  (`p3_agility`, `p5_scout` - teslim edilen içerik kendi dosya adıyla
  uyuşmuyor; `p3_intellect`, `p4_passed_over` - prompt'tan sapan ama
  önceki turdan beri kabul edilmiş bir ikon dili; `eq_ring_charmed` - mavi
  boncuk detayı eksik) ve wardrobe'un kıyafet parça sayfaları (B kategorisi,
  artık istenmiyor, giysiler 3B render). Tam liste ve
  her satırın durumu `docs/wayborne_gorsel_denetim.xlsx`'te.
- **Gerçek seslendirme + savaş nidaları** (#7, #11). `AudioManager`'ın
  bugünkü sentezlenmiş placeholder'larının yerini gerçek kayıt alacak;
  Faz 13 PR-D'nin kısa metin yorumları (`unit_barked`) bunun metin
  karşılığı olarak zaten kurulu.
- **Codex'in olay bölümü canlı kataloğun gerisinde.** Faz 18 altı, Faz 19
  on bir yeni kart ekledi (üç zincir + borç krizi); codex bunları (ve Faz 17
  PR-9'un kaydettiği önceki açığı) henüz işlemedi - bilerek ertelendi.
- **Karanlık arayüzü ekranlara bağla (Faz 27'de onaylandı, yarısı bağlı).**
  Şehir artık render edilmiş, şehre özgü önden kasaba (`CityFront`:
  levhalar brifingin ihtiyaçlarını taşıyor, kadro kartları, alt şerit,
  yanında koyu brifing sütunu); ana menü gece kampı ve sağ şerit. Kalan:
  yol HUD'unun kalanı (göstergeler `SurvivalGauge`'a geçti; ikonlu alt
  şerit, `GrimNotice`),
  pazar/envanter, ve GrimTheme'in kalıcı parçalarının WaybookTheme'e
  taşınması. Sıra ve ayrıntı `docs/ui/REDESIGN.md` §7'de. Dosya ve sınıf
  adları oyuna özgü kalır (başka bir oyunun terimi değil).
- **Kıyafetler ganimete bağlanacak.** Terzi kuruldu (şehirde Kıyafet
  Dolabı ekranı, statlı ve statına göre fiyatlı 48 giysi, her ziyarette
  başka bir tezgâh - bkz. Wardrobe & Rig Rules). Kalan iş yolda bulma:
  `EventEffect`'e `GRANT_OUTFIT`, `GRANT_EQUIPMENT`'in deseniyle (parça
  önce dolaba düşer, kime giydirileceği sonra seçilir).
- **Evrenin lore'u ve tarihi tamamlanıyor.** `docs/lore/LORE.md` (evren) ve
  `docs/lore/TARIHCE.md` (zaman çizelgesi) oyunda bugün var olan her bilgiyi
  [Kanon]/[İma]/[Boş] diye işaretliyor; harita ve mekanikler bu iki belgenin
  [Boş] satırları dolunca somut zemine oturacak (dünyanın adı, beylikler,
  kültürlerin yurtları, deniz/liman, lonca ve kilisenin kökeni).
- **Eşya bozulması mekaniği.** `Item` bugün yalnızca fiyat ve ağırlık
  taşıyor; arayüz taslağının yıpranmış hücresi (ui-hud-redesign) çizebiliyor
  ama oyun hesaplamıyor. Hedef: bozulabilir mallar (balık, erzak, bal) yolda
  gün sayar ve tazeliği satış fiyatını düşürür, süresi dolan yığın çürür;
  kalıcı mallar yalnızca görsel kir/kırağı alır. Yeni bir sistem değil,
  `Inventory` yığınına bir yaş alanı ve `MarketPricing`'e bir çarpan.
- **Hastalık, doktor ve şehrin ilacı.** Karakterler hastalanabilir (yolda,
  açlıkta, soğukta, kirli suda); iyileşmek için şehirde bir doktor/hemşire
  bulmak, iğne yaptırmak, ilaç almak gerekir. Ama şehrin **ilaç stoğu**
  vardır: kıtlıkta doktor iğneyi yapamaz. Kıtlığın sebebi oyuncunun kendi
  geçmişi olabilir - o şehre zamanında üstlenilen ilaç sevkiyatını teslim
  etmemek (bkz. Veba İlacı görevi, `fulfill_commission`), ya da bir veba
  haberi. Yeni bir sistem değil: hastalık bir `Trait` benzeri süreli durum
  (stat cezası, kötüleşirse `resolve_deaths`'in kapısı), ilaç bir `Item`,
  şehrin stoğu `MarketConditions`'ın şehir başına bir sayacı, iğne
  Kilise/Taverna'nın `PurificationPanel` deseninde bir hizmet. Kıtlık
  hizmeti **sebebiyle kilitli** gösterir ("ilaç yok - X'e sevkiyat
  gelmedi"), gizlemez.
- **Yoldaş bulmak zor olmalı; iyi biri çok nadir.** Savaş zamanında kimse
  yollara düşmek istemez - kervana yalnızca **mecbur olanlar** katılır
  (borçlu, sürgün, dul, kaçak, aç). Bugün `RecruitCatalog` her varışta her
  mekânda dolu bir pano atıyor ve seviyeleri oyuncunun etrafına yayıyor
  (`get_venue_level_spread`); hedef: pano çoğu zaman boş ya da bir-iki kişi,
  yüksek seviyeli aday nadirin de nadiri (seviye arttıkça ağırlık hızla
  düşer), loncanın itibar kapısı daha sert. Dünyanın hali sayıya bağlı:
  bölgesel savaş/veba haberi (`WorldEvents`) panoyu daha da boşaltır,
  kıtlık ve borç ise çaresizleri çoğaltır. Her adayın **neden** geldiği bir
  satırla söylenir (mecburiyeti), ve bu sebep huyuna/sadakatine yansır -
  `NpcDisposition`'ın kervan içi karşılığı. Ölçü `simulate_career.gd` ile
  yeniden alınmalı: kadro bölümü (Bir Kadro) bugün 6. seferde kapanıyor.
- **Sıcaklık, Celsius derecesiyle.** Yol HUD'unun alev göstergesi gerçek bir
  sayıya bağlanacak: mevsim + biyom + saat + hava (+ kamp ateşi) bir °C
  üretir (`RouteWeather` gibi tohumdan hesaplanır, saklanmaz). Mekanik
  bağlantılar mevcut kollarla: soğukta günlük erzak payı ve stres artar,
  giysilerin bir ısı değeri olur; planlayıcı bunu erzak rezervine katmak
  zorunda (Provision Rules'un sözü bozulmasın). G11 kırağı kenarı oyuncunun
  isteğiyle kaldırılmıştı; sıcaklık kenarla değil sayı ve göstergeyle
  gösterilir.
- **Eski kuşam listesi (B-01..B-20) artık boyanmayacak.** Giysi 2B boyama
  yolu (parça sayfası, sonra `wardrobe_cut.py`) yerini 3B render'a bıraktı;
  `docs/gemini-prompts-wardrobe.md` ve şablonları silindi; yeni kalemler
  CC0 3B paketlerden giydirilip render ediliyor.

**Kapanmış fazların anlatıları `docs/history/FAZ_ANLATILARI.md`'de.** Faz 0-27'nin kapanış notları, denge ölçümleri ve
çözülmüş-sorun kayıtları oraya, metin değişmeden taşındı; bu dosya yalnızca geçerli kuralları ve açık hedefleri tutar. Koddaki
"bkz. CLAUDE.md Faz N" başvuruları o belgeye bakar.

## Quick Start

1. Open `project.godot` in Godot 4.2+
2. Create your first scene in `scenes/main.tscn`
3. Create scripts in appropriate `scripts/` subfolders
4. Reference scenes/scripts using `res://` paths
5. Push to `main` branch to trigger automatic Web export & deployment

## Codex

`docs/Wayborne-Codex.pdf` is the game's design document — covering
every mechanic in prose, plus a one-page decision tree for each road event it documents (29 of the live catalog's 41 at the
time of writing; the PDF has not been rebuilt since the naming cleanup, task 1.4) (trigger, options, weighted outcomes, effects). It is
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
