---
name: kurallar-savas
description: Wayborne kural kitabının "Savaş motoru ve yıkım dengesi" bölümü (CLAUDE.md'den taşındı). Şunlara dokunmadan, şunları tasarlamadan ya da şunlar hakkında karar vermeden önce yükle: scripts/combat/, CombatEncounter, CombatUnit, CombatSkill, SkillCatalog, EnemyCatalog, durum etkileri, alan becerileri, Ölümün Kıyısı, savaş ekranı, kazanma oranı tabloları, POWER_SCALE ayarları. Bozulmaması gerekenleri ve nedenlerini tutar.
---

# Savaş motoru ve yıkım dengesi

CLAUDE.md'nin bu bölümleri 2026-10-30'da kullanıcı kararıyla buraya taşındı; metin değişmedi, başlıklar aynı. Koddaki
"bkz. CLAUDE.md <başlık>" başvuruları buraya bakar. Kural becerilerinin listesi CLAUDE.md'de ("Kural becerileri").
Bölümler: scripts/combat/, Combat Rules, Ruin Rules.

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

- **The combat screen is the approved draft (9.8 + Y-G05, `y_98_savas.png`).** It takes the whole road screen (the HUD
  and control panel hide, `road_journey._set_combat_view`): a round medallion with the round in Roman numerals and this
  round's order under it, the stage, and two panels - the active person's skill cards (name, hit chance against the
  focused enemy from the engine's own formula, or the lock reason; launch/target pips underneath) with swap, consumables
  and retreat wrapping below, and the focused unit (hovered, else the selected skill's first target, else the enemy
  front): health, armour, statuses, temper (`BEHAVIOR_KEYS`), then the log. The draft's crit seal was left out on the
  user's word ("kanama, kritik vs efektler olmasın").
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
  ready and spawned by no ordinary squad builder - only by the rare, once-only `evt_rogue_mage`
  (`EnemyCatalog.KIND_MAGE`, task Y-F07T, the user's note: rare, never removed) (`test_combat_core`
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

- **Enemies have temperaments; the broken act, not glow; a hard-pressed caravan can fall back (tasks Y-C08,
  Y-D06, Y-C07).** `CombatEncounter.pick_target` reads `CombatUnit.behavior`: the bandit leader goes for the caravan's
  leader, wolves chase the lowest health share, guards do not finish anyone at Death's Door, and a taunting unit is
  everyone's target. A broken companion who "refuses" now acts by their break mode
  (`CharacterData.get_break_mode`, from their latest affliction): charges to the front, taunts (draws every blow),
  refuses, or lashes out at the nearest ally (never below 1 HP). No screen effect - the road has
  `evt_broken_outburst` too. When the company is down to `RETREAT_PRESSED_SHARE` health or someone is at the Door,
  the panel offers retreat: drop a third of the load, sacrifice a wagon (its wreck stays on the road), or leave the
  active fighter as rearguard (the enemy's front takes one swing each at them). Against beasts that do not chase
  (bear, boar) retreat is free. A retreat skips the defeat penalties and costs a little morale.
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
