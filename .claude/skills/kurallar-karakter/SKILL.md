---
name: kurallar-karakter
description: Wayborne kural kitabının "Karakter, parti, soy, stres ve gelişim" bölümü (CLAUDE.md'den taşındı). Şunlara dokunmadan, şunları tasarlamadan ya da şunlar hakkında karar vermeden önce yükle: scripts/character/, CharacterData, CharacterStats, kültür, sınıf, görev rolleri, huy, ekipman, işe alma, kırgınlık, açlıkla ölüm, soy ve varis, defter (CaravanLedger), stres, yorgunluk, seviye ve ekipman kapısı. Bozulmaması gerekenleri ve nedenlerini tutar.
---

# Karakter, parti, soy, stres ve gelişim

CLAUDE.md'nin bu bölümleri 2026-10-30'da kullanıcı kararıyla buraya taşındı; metin değişmedi, başlıklar aynı. Koddaki
"bkz. CLAUDE.md <başlık>" başvuruları buraya bakar. Kural becerilerinin listesi CLAUDE.md'de ("Kural becerileri").
Bölümler: scripts/character/, Character & Party Rules, Lineage Rules, Stress Rules, Progression Rules.

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
    buy price, combat damage, how easily tavern talk yields news). No perk may invent a new system.
  - `CharacterClass` / `ClassCatalog`: combat role. `class_name` is a
    reserved word, so the visible name lives in `display_name`. Four classes
    (Sıra Neferi/Sekban/Kırıkçı/Kalem Efendisi), each with a `stat_affinity`
    (used by auto-allocate) and a `duty_id` - its "ana" kervan görevi, which
    `DutyCatalog.get_duty_power()` rewards when a character actually holds
    that duty.
  - **Three roles, six effect channels (tasks Y-F09, Y-B04, Y-B12).** What a person is assigned is now one of
    three roles - vanguard (front: scout, guard, crier), middle (wagons: wagoner, quartermaster), rear (rear:
    herbalist) - and classes no longer multiply duty power. The six old duties below survive as effect channels:
    `get_duty_holder(old_id)` returns the holder of the role that covers it, and old saves migrate
    (`DutyCatalog.role_of`). A role holder can attend signals in their own zone while the leader is elsewhere
    (`RoadSignals.tick`'s `role_cover`). The vanguard pays `VANGUARD_DAILY_STRESS` per road day; at every camp
    `CampActionsPanel` sets tomorrow's formation and up to two evening actions. Design note:
    `docs/design_notes/gorev_rolleri.md`.
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
  - **Recruiting is hard and personal (task Y-C16).** A board holds one or two people (`RecruitCatalog.VENUE_COUNTS`;
    the guild one), one fewer while a war or plague is on; base prices rose 30%; levels lean to the low end of the
    venue's spread (`LEVEL_SKEW_POWER`), so a seasoned hire is rare. Every candidate carries a backstory - why they
    came - and the card says it with what they want.
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
  - **Thirty-six pieces, and most of the new ones are trinkets with a story (task Y-C06).** Six weapons, six
    armours, twelve rings, twelve amulets. Three new kinds of piece, each read by the same derived getters:
    *synergy* (`synergy_trait` + `synergy_bonuses`: the bonus counts only on someone who carries that huy, e.g. the
    lamellar coat on a nimble-footed wearer), *costly* (`daily_stress`: a strong piece that wears its wearer down
    every road day, `GameSession._apply_equipment_cost_day`) and *cursed* (`cursed`: cannot be taken off; the
    church lifts it for `CURSE_LIFT_PRICE` gold in a city, and the piece is destroyed - `lift_curse`). Locked
    unequips and equips show their reason (`UI_EQUIP_CURSED_LOCK`). Found pieces come from the loot tables and four
    event outcomes; their price is 0 (never sold), and `EquipmentCatalog.bonus_line` is the one line every screen
    prints. Icons are derived from the painted set by `tools/equipment_icons.py` (tint, bead, crack). Measured with
    `simulate_journeys`' piece sweep (one character, 50% danger): bare 63%, weapon tier 3 +17, the new pieces
    between +12 and -5, no cursed piece dominant.

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
- **The ledger can be shared as one page (task Y-E07).** The waybook's "save the page" button turns the left page into
  the lineage's summary (`LedgerPage.lines`: name, generation, day, journeys, who carried the name, who the road kept,
  graves) and saves the book as a PNG under `user://defter_sayfalari/`, then restores the ledger.
- **The fallen have their own page, and the evening its own line (tasks 9.11, Y-B08).** The waybook's "Düşenler"
  spread lists the founder and the dead (`CaravanLedger.fallen()`), each with a grave mark drawn by rank
  (`GraveMark`: founder ring and plinth, leader ring, companion notch, crew bare - no religious sign) and "role · cause,
  place (day)"; the dead person's class is written into the line (`role`). The right page holds the story lines: camp
  stories as a short summary (`STORY_*_LINE`), and the line of the day. That line is chosen at evening camp: the day's
  beats (`GameSession.note_beat`: death, lost wagon, fight, hunger, story, event card; saved, cleared at arrival) give
  their heaviest kind's three sentences (`DIARY_*`, literary, no numbers, names as `args`), and the player picks one or
  none (`DiaryPanel`). Writing it is choosing, not typing.
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
- **A lineage that ends leaves an inheritance (task Y-D03).** When nobody is left to carry the name, the run-over
  screen writes the lineage to `LineageArchive` (`user://lineage_archive.json`, outside the save slots, capped at
  `MAX_LINEAGES`): name, generations, days, reputation, its last ledger lines and its graves and cairns. A new game reads
  the latest one: the old graves return to the roads (drawn faint on the road and the world map, `map_graves`), a share
  of the old reputation (capped), an old seal as an heirloom, and a ledger line naming the old lineage. What was
  inherited is the saved `GameSession.legacy`.
- **Ended lineages open new starts, never new power (task Y-D05).** `StartOrigins` holds the father's caravan (always
  open) and five origins a finished lineage unlocks (exile, guild ward, salt runner, drovers, the widow's ledger). Each
  is a trade: no debt but a light purse, a known name but a doubled debt. Unlocks are kept in the archive file
  (`LineageArchive.unlocked_origins`), so they survive a lineage dropping off the archive's cap. Locked origins are
  shown on the new-game screen with their unlock condition; the chosen one is the saved `GameSession.origin_id` and
  rewrites the founder's ledger cause.
- **The finale's gold gate became `days_as_leader`.** A pure money gate
  closed the story with "you got rich enough". The measurement survives:
  with a leader who never dies, tenure equals elapsed days and the finale's
  median lands at journey 30 (~180 days), so 60 is comfortably cleared. The
  other two thresholds stay as measured — Campaign Rules already records
  that moving the *later* gate halved the finale.

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
- **Fatigue is the body, stamina is the caravan walking at its most tired
  member's pace (Y-F01).** `CharacterData.fatigue` (0-100, saved, old saves
  load at 0) is a person's physical state, kept apart from stress: stress is
  wear that accumulates across journeys, fatigue is mostly slept off. Fast
  pace (+8/day), unlit night walking (0.5/hour in chunks of 4), the vanguard
  role (+4/day), an early start (+4) and fighting (+8 per fighter) raise it,
  and a heavy body takes 25% more of every gain. The camp fire (-30), a city
  arrival (-60) and walking in the middle role (-4/day) lower it.
  `CaravanState.stamina` stays as the counter, but everything that *reads*
  stamina reads `GameSession.get_caravan_stamina()` = min(counter, 100 - the
  highest fatigue), and the UI names whoever binds it (`get_stamina_binder()`).
  **Fatigue never touches walking speed or the provision formula**: it only
  locks the voluntary fast pace (`can_push_pace()`), and the lock drops the
  caravan to steady, so "correct stocking never starves" holds -
  `test_fatigue.gd` asserts a fully exhausted party covers exactly the same
  ground at steady pace. In combat it is a small penalty through the same
  derived-getter wrapper as ailments (`_fatigue_bonus_sum`): -2 accuracy and
  dodge from 60, -4 from 85, so `CombatUnit.from_character` sees it without
  knowing it exists.

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
