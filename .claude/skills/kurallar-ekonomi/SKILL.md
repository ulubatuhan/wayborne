---
name: kurallar-ekonomi
description: Wayborne kural kitabının "Ekonomi, şehir, kampanya, erzak ve borç" bölümü (CLAUDE.md'den taşındı). Şunlara dokunmadan, şunları tasarlamadan ya da şunlar hakkında karar vermeden önce yükle: pazar ve fiyat katmanları, MarketConditions, pazarlık (HagglingSession), kontrat panosu, şehir özeti (CityBriefPanel), kampanya bölümleri, borç (DebtLedger), vagon alıp satma, vagon envanteri ve atölye, erzak formülü, moral, itibar, oyun başlangıcı, simulate_career. Bozulmaması gerekenleri ve nedenlerini tutar.
---

# Ekonomi, şehir, kampanya, erzak ve borç

CLAUDE.md'nin bu bölümleri 2026-10-30'da kullanıcı kararıyla buraya taşındı; metin değişmedi, başlıklar aynı. Koddaki
"bkz. CLAUDE.md <başlık>" başvuruları buraya bakar. Kural becerilerinin listesi CLAUDE.md'de ("Kural becerileri").
Bölümler: Campaign Rules, City Hub Rules, Caravan Ruin Rules, Provision Rules, Morale Rules, Economy Rules, Kervan Envanteri Rules, Haggling Rules, Reputation Rules, Playthrough Start Rules.

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

**The sixth to eighth harness mistakes, found re-measuring after the contract board (Y-C02) and the 27-settlement map.**
Chapters closed 4/8 and the finale 1/8 against a 6/8 baseline, and the debt (Y-C14) was blamed first - softening it
changed nothing. The cause was the policy again: it picked a road at random (a board of 4-7 notices over 27 places
rarely matches), filled the wagons with market goods *before* accepting contracts (consigned goods did not fit, were
"missing on arrival" and each cost reputation, `cargo_room` was never set) and never repaired a wagon. A real player
reads the board first, reserves the room and repairs. With the policy fixed the table is 8/8 for the expanding and
campaign policies and 5/8 for the contract policy (see `docs/design_notes/denge_baba_borcu.md`). One real finding came
with it, `MerchantOffer.is_open_to` (Reputation Rules). **When a report collapses after new content, fix the policy's
blindness to that content before touching the content's numbers.**

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
- **The contract board is new at every arrival (task Y-C02).** `ContractBoard.roll(city, day)` seeds four to seven
  notices: delivery (most common - the merchant stays home, our wagons carry his goods as `contract_goods`), escort
  (his wagon or donkeys), a wagonless merchant (he rides, his goods ride in ours, the fee carries wagon hire),
  passengers (mouths, no cargo) and a contraband load (unsealed salt - customs can seize it). A quarter are rush jobs:
  short deadline, higher pay, half pay if late. A notice's id carries its city and day, so `GameSession.find_offer`
  rebuilds an accepted contract after a reload; `_board_cache` only keeps object identity within a session. The guild's
  own wagon and freight commissions stay static. Consigned goods take real cargo room (`CaravanPlan.cargo_room`); a
  contract whose goods are short on arrival is undelivered and pays the usual penalty. Mouths come from each contract
  (`MerchantOffer.mouths`), so a delivery eats nothing and passengers eat as many as they are.
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
- **Every settlement has its own picture, generated, never hand-placed (P17).** `tools/ui_scenes/settlement_towns.py`
  writes one `towns.json` entry per settlement from its culture (architecture, light, colour), latitude (snow and cold
  light in the north), type (city: wall, gate, guild, castle; town: palisade, no guild or yard; caravanserai: walled
  courtyard, no guild or church), map kind (port, free city, mine, swamp, river, market town) and goods; Blender renders
  it (`town_scene.py`) and `town_post.py` inks it into `data/assets/ui/towns/<id>/`. A building is tagged with a venue
  only where `SettlementRules` gives that facility, so the click mask never offers a venue the place lacks. The camera
  sits 2 m right because the brief column covers the picture's right third. `test_settlements` fails if any settlement
  falls back to another's picture; the style rules are `docs/ui/STIL_REHBERI.md`.
- **A city wears its state, not only its hour (task 9.3).** On top of the phase pictures, `venue_highlight.gdshader`
  grades the picture by `CityFront.mood_for()`: crisis (`is_city_in_crisis` - plague, or a war on its road) desaturates
  it and raises a red horizon and three smoke columns; overcast/rain/fog/storm (the city's own seeded weather,
  `RouteWeather.at("city|<id>", day)`, never stored) turns it grey. Colour only, so the click mask stays aligned.
  `tests/screenshot_city_moods.gd` prints all three at noon and night.
- **A gate's wall runs behind its towers (user's decision A5).** The gate scenes (`settlement_gates.py`, `gates.json`)
  put a `TallWall` piece behind every watchtower (`WALL_BEHIND_DEPTH`), so the curtain wall meets the gate instead of
  stopping at an open tower base. The tower flags have their own cloth material (`FLAG_MATERIAL`), so the stone
  tint rule never reaches them.
- **Both ends of the road are the settlements' own gates, as part of the road (user's decisions, 2026-10-21/22).** The
  full-screen frontal gate picture shown on city entry (`GateArrival`) and its renders were removed: the gate lives in
  the world. `TravelBand.set_road_gates` takes one gate per end of the terrain - the origin's at day 0, the other city's
  at `terrain_days` (`road_journey._sync_arrival_gate`), so turning back finds the right gate at each end - day-anchored
  like a stop, behind the road's far edge, its opening centred on the head rider when the caravan stands there. The hub
  draws the same prop. `GateArt` is the one drawing: the town behind the wall (`town` layer, hazed, raised by
  `TOWN_RAISE` and shrunk - a side ortho camera would otherwise hide everything behind a wall), the dark passage, the
  leaf drawn in code (stone: an iron portcullis that lifts; wood: two leaves that swing in; felt: none - the nomad
  camp's entrance is two tug standards), the wall (`body`), and at night two torches (a fire for the camp). Scale comes
  from the wall alone (`GateArt.body_height_m`). The opening is measured from the render by `pack_some.door_pivots`
  (`door_l`/`door_r`/`door_top`); `test_settlements` asserts a wagon fits (>= 2 x 2.5 m) - at the pack's own scale the
  stone arch was 1.4 m wide, so the gatehouse is scaled up (`settlement_gates.ENTRANCE_SCALE`). Cutouts:
  `tools/ui_scenes/gate_cutout.py` (`render_props.py` builder `settlement_gate:<id>`), packed with
  `pack_some.py --prefix gate_`, which also runs `town_grade` so the cutout speaks the town pictures' palette.
- **A settlement looks like what it is (user's report, 2026-10-22: "yurt, maden, balık kasabalarına özel ekran ve
  giriş").** `settlement_towns.py` adds each kind's face after the shared skeleton, drawing seeds only for its own kind
  so every other town stays byte-identical: the nomad camp (`gocebe`) has no wall - felt yurts, the khan's big yurt as
  the inn, tugs, horse lines and horses, a wicker fence, a fire at the centre; mines get an adit at the hill's foot, rails
  and carts to the square, a headframe and ore heaps; ports a quay, piers, moored ships and boats, a lighthouse mole;
  swamps pools, stilt houses and reeds; river towns a river, a bridge and the mill on the bank. Water towns put the
  camera a storey higher (at eye level the water was a line behind the stalls - measured). The procedural pieces (yurt,
  tug, cart, rails, headframe, net rack, stilts, reeds) are `tools/ui_scenes/settlement_props.py`; ships, piers and boats
  are Kenney's Pirate Kit (CC0). Animal models are posed on their idle clip (`town_scene._settle_pose`): imported raw,
  the horse stood in its attack frame with its neck thrown back.
- **Every structure and every scene is grim (user's decision, 2026-10-22).** Town pictures get it from
  `town_post.grade`, gate cutouts from `pack_some.town_grade`, the road, combat and hub world from `GrimGrade`
  (`scripts/ui/grim/grim_grade.gdshader`, a screen pass under the HUD: desaturate except warm light, squeeze highlights,
  cool shadows). Measured before it: the noon road was more saturated (0.17-0.20) and brighter than the town pictures
  (0.15). Valley-culture buildings are weathered on top (`town_scene.weather_materials`: blots, rain streaks, earth
  and moss at the foot; Quaternius' separate Cycles output is rerouted, or Cycles never saw it). The rule and its
  numbers are in `docs/ui/STIL_REHBERI.md` ("Kasvet").
- **A settlement's wall is one fact, read by three places (user's decision, 2026-10-21).** `settlements.json` `wall`
  (`"wood"`/`"stone"`, `"felt"` for the nomad camp, `Location.wall`, written by `tools/worldmap/annotate_walls.py` from the town scene's own `wood`
  flag) says what the wall is made of: nine settlements (akavan, auderin, caramine, golcavar, kirsavel, liraven,
  samuran, selvicar, vorgat) have a log palisade - sharpened logs, timber towers - in the town front
  (`town_scene.palisade`), the gate scene (`settlement_gates._wood_gate`) and the hub's gate prop (`palisade_gate`,
  `WorldHub._gate_prop_id`, same px/m as the stone `city_gate`). `test_settlements::_test_wall_material` fails if the
  field and the town scene disagree, so a log-walled town cannot be entered through a stone gate.
- **The square is not empty, and it is staged, not crowded (task Y-G10T).** `TownsfolkLayer` places small scenes from
  the approved drafts: at night a watchman with a lantern, two people talking, one walking home; at dusk and by day a
  vendor, an old man on a crate, a couple and a second walker join. Each figure takes the light of the spot it stands
  on (the picture's local average, `ambient_at`), the watchman also his lantern's (`firelit.gdshader`, dusk and night
  only). Seeded from city and day; the draft's ground band is lifted above the bottom strip (`GAME_GROUND`).

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
- **Goods differ in kind (task Y-C19), each through an existing door.** Fish rots after `FISH_SHELF_DAYS` on the road
  (`spoil_perishables`, a quarter a day; a fresh purchase averages the age down, never resets it). Unsealed salt is
  contraband: bought only at a caravanserai, sold high elsewhere, and the customs card (weighted x3 while it is carried)
  confiscates it (`ITEM_REMOVE` with a negative amount = all of it) unless a hide check succeeds. The old seal is rare:
  never on a stall, sold only in a city. Buying 20+ at once is 6% cheaper. **Selling back what you bought in the same
  visit is capped at 90% of what you paid** (`capped_sell_price`), because your own purchase raises the market's price
  and selling into that raise was a money printer; every purchase path reaches it through `consume_stock`.
- **A stale stock sells cheaper (Ana Hedefler: eşya bozulması).** Rot eats the quantity; age eats the price.
  `MarketPricing.freshness_multiplier` keeps a perishable at full price for the first quarter of its shelf life, then
  slides it to `FRESHNESS_FLOOR` (60%) at the end; `GameSession.capped_sell_price` reads the stock's age
  (`perishable_days`) before the same-visit buyback cap, and the market row says "stale" with the share.
- **Every price layer shows itself (task Y-C11).** `MarketPricing.price_layers()` lists the seven factors (place,
  settlement type, inflation, season, supply pressure, event shock, world-event shock - the last told apart by its
  `WorldEvents` label); their product is the price, which the test checks. `PriceLayerText.marks()` puts a short tag on
  the market row for each layer more than 2% off neutral and a sentence per layer in its tooltip.
- **Seen prices are dated; rumours can lie (task Y-C10).** `GameSession.price_book` records a city's list prices on
  arrival; past `PRICE_STALE_DAYS` the entry is stale. In the tavern someone may tell you a neighbour's prices a few
  days old, and one rumour in four exaggerates (seeded by city, target and day, so a reload cannot hear the truth). The
  book only informs: the market always trades at today's price.
- **Gossip is not for sale (task N34, the user's rule).** Road danger and neighbour prices are learned by talking to
  people in the tavern (`DialoguePanel`): each person's chance depends on their role, a drink bought for them, the
  caravan's culture (`Culture.rumor_difficulty`, the port perk) and the crier (`GameSession.get_news_chance_bonus`).
  The rows that used to sell rumours only show what is known and how old it is.
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
- **An offer with no requirement never closes either.** `MerchantOffer.is_open_to(reputation)`: a requirement of 0 is
  open at any reputation (the board and the guild screen both read it). Gating it with `reputation < required` locked
  the whole board at -1, and a caravan that had fallen to -20 could never take a contract and so never climb back.
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

- **There is no tutorial and no help panel for now (user's decision, 2026-10-21; task Y-H01 closed).** The pinned paper
  hints (`FirstTimeHint`, 2026-10-20: "ugly") and then the four-topic help panel (`OnboardingPanel`, its Help buttons
  and the F3 key, `UI_ONBOARD_*`/`UI_HELP_*`) were removed; the user will add teaching back later, in a form of their
  own. `GameSession.ONBOARDING_FLAG` stays: it now only gates the one-time handover scene on the first city arrival.
  Old saves may still carry the `hint_*` flags; nothing reads them.
- **The opening is fixed and not offered as a choice**: two party members
  (the player plus one randomly rolled companion), one wagon, a random
  starting city - see `GameSession.start_playthrough()`. One wagon is
  exactly two party slots, so the roster starts full; a third member is
  only possible after buying a wagon.
- **The caravan was your father's, and it comes with his debt (task Y-C14).** `inherit_father_caravan()` runs after
  `start_playthrough()` in the real new-game flow: the founder ledger line becomes the father (`LEDGER_CAUSE_FATHER`)
  and a guild debt (`FATHER_DEBT_PRINCIPAL`, due on `FATHER_DEBT_TERM_DAYS`) opens the first period's clock.
  `InheritancePanel` shows the handover over the onboarding, closed only by its button. Tests that need a debt-free
  start simply do not call it; `simulate_career` does, and repays above its cash buffer. The amount and term are not
  yet measured.
- The companion comes from `RecruitCatalog.build_starting_companion()`,
  which reuses the normal candidate generator rather than duplicating the
  randomization.
- `tests/playthrough_demo.gd` runs the whole loop headless (market,
  contracts, travel with the real clock, events, arrival) and prints a
  readable log. Like `simulate_journeys.gd` it is **not** a test - it never
  fails, it shows whether the game actually loops. It mirrors the road
  screen's `_process` order deliberately, so what it verifies is what the
  screen does.
