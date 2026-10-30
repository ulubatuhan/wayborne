---
name: kurallar-olay
description: Wayborne kural kitabının "Olay kartları ve olay motoru" bölümü (CLAUDE.md'den taşındı). Şunlara dokunmadan, şunları tasarlamadan ya da şunlar hakkında karar vermeden önce yükle: scripts/events/, data/locale/events.csv, EventCatalog, EventEffect, EventResolver, EventEngine, RoadDirector'un kart çekişi, NpcDisposition, olay zincirleri, yeni kart yazmak. Bozulmaması gerekenleri ve nedenlerini tutar.
---

# Olay kartları ve olay motoru

CLAUDE.md'nin bu bölümleri 2026-10-30'da kullanıcı kararıyla buraya taşındı; metin değişmedi, başlıklar aynı. Koddaki
"bkz. CLAUDE.md <başlık>" başvuruları buraya bakar. Kural becerilerinin listesi CLAUDE.md'de ("Kural becerileri").
Bölümler: scripts/events/, Event Engine Rules, Event Character Rules.

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

### Event Character Rules

Who you are travelling with, and who you meet, changes what an event does.

- **People met on the road carry a hidden disposition** (`NpcDisposition`:
  loyal / desperate / thief / vengeful). `EventEffect.Type.ROLL_ENCOUNTER`
  rolls it into a flag and outcomes branch on that flag with
  `EventCondition.HAS_FLAG`. The player is not told which - a party member
  with strong Sezgi only gets a *hint*.
- **A merchant's temper shows on the road (task Y-F05).** The event context counts walking merchants per disposition
  (`merchant_thief`, `merchant_desperate`, `merchant_vengeful`, `merchant_loyal`; a delivery client is not on the road
  and does not count). Each has a card: the thief slips away at night, the desperate one wants to turn back when the
  road gets dangerous, the vengeful one starts a fight, the loyal one shares bread when stores run low. `MERCHANT_LEAVE`
  with a disposition as its text value removes a merchant of that temper, not the last in line.
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
- **A new card passes the quality list before it ships (task Y-E01).** `EventQuality.problems()` reads the card's own
  data: at least two choices (chain continuations exempt), a tempting-but-risky choice (a check or several weighted
  outcomes), a skill check, and at least one effect beyond gold/provisions/morale/stress/reputation. Cards are written
  region by region in batches of ten, each batch approved; `tests/report_event_quality.gd` lists failing cards and the
  drawable count against `TARGET_DRAWABLE` (120), and `simulate_career` prints the repeat rate up to the finale.
  Production order: `docs/design_notes/olay_uretim_duzeni.md`.
- **A long chain outlives the journey (task Y-E02).** `UNLOCK_EVENT` chains live in the journey's engine and end with
  it. A chain whose answer comes in another city or in the heir's era uses `CHAIN_ADVANCE` ("chain|stage|where", amount
  = minimum days): `GameSession.event_chains` (saved) holds the stage, where it started, the earliest day and the
  generation. The context carries `chain_<id>` (the stage) and `chain_<id>_ripe` (the stage only when the day has come
  and the place fits: `other_city` = on the road to a city other than where it began, `city:<id>` = on the road to
  that city, `heir` = a later generation). A stage of `CHAIN_DONE` (-1) closes it. The ten chains' content waits for
  the lore (Y-E06).
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
