extends SceneTree

## Denge simülatörü. Oyunu oynayamadığımız için dengeye sayılarla
## yaklaşmanın tek dürüst yolu bu: N tohumla sefer koşturur ve sonuç
## dağılımını basar.
##
##   godot --headless --script res://tests/simulate_journeys.gd
##
## Test değil - hiçbir zaman kırmızı dönmez, yalnızca rapor verir.
## Kararı okuyan insan verir.

const RUN_COUNT: int = 200
const JOURNEY_DAYS: int = 8
const DANGER_LEVELS: Array[float] = [0.2, 0.4, 0.65]
const STARTING_GOLD: int = 250
const STARTING_PROVISIONS: int = 20
const ESCORT_MERCHANTS: int = 3
const ESCORT_PROFIT_EACH: int = 120

func _initialize() -> void:
	print("── Wayborne sefer simülasyonu (%d koşu × %d tehlike seviyesi)" % [
		RUN_COUNT, DANGER_LEVELS.size()
	])
	print("")

	for danger in DANGER_LEVELS:
		_report(danger, _run_batch(danger))

	print("── Savaş dengesi (parti büyüklüğüne göre kazanma oranı)")
	var party_sizes: Array[int] = [1, 2, 3, 4]
	for party_size in party_sizes:
		_report_combat(party_size)

	quit(0)

func _run_batch(danger: float) -> Dictionary:
	var net_total := 0
	var morale_total := 0
	var provisions_out := 0
	var wagons_lost := 0
	var contracts_lost := 0
	var worst_net := 1 << 30
	var best_net := -(1 << 30)

	for run_index in RUN_COUNT:
		var outcome := _run_single(danger, 1000 + run_index)
		net_total += int(outcome.net)
		morale_total += int(outcome.morale)
		wagons_lost += int(outcome.wagons_lost)
		contracts_lost += int(outcome.contracts_lost)
		if bool(outcome.ran_out_of_provisions):
			provisions_out += 1
		worst_net = mini(worst_net, int(outcome.net))
		best_net = maxi(best_net, int(outcome.net))

	return {
		"net_avg": float(net_total) / float(RUN_COUNT),
		"morale_avg": float(morale_total) / float(RUN_COUNT),
		"starved_pct": 100.0 * float(provisions_out) / float(RUN_COUNT),
		"wagons_lost_avg": float(wagons_lost) / float(RUN_COUNT),
		"contracts_lost_avg": float(contracts_lost) / float(RUN_COUNT),
		"worst_net": worst_net,
		"best_net": best_net,
	}

## Bir seferi baştan sona koşturur. Olay seçenekleri "ilk uygun seçenek"
## kuralıyla seçilir; oyuncu zekâsını taklit etmez ama alt sınırı verir.
func _run_single(danger: float, seed_value: int) -> Dictionary:
	var session := GameSession.new(STARTING_GOLD, STARTING_PROVISIONS, 2)
	session.danger_level = danger
	session.journey_destination_id = WorldMapData.START_LOCATION_ID
	session.journey_total_days = JOURNEY_DAYS
	session.journey_days_remaining = JOURNEY_DAYS

	session.caravan.wagon_count = 4
	session.caravan.wagons_at_start = 4
	session.caravan.player_wagon_count_at_start = 2
	session.caravan.documents = 4

	var merchants: Array[String] = []
	for index in ESCORT_MERCHANTS:
		var merchant_name: String = "Tüccar %d" % (index + 1)
		merchants.append(merchant_name)
		session.caravan.merchant_profit_by_name[merchant_name] = ESCORT_PROFIT_EACH
	session.caravan.merchant_names = merchants
	session.caravan.original_merchant_names = merchants.duplicate()

	var engine := EventEngine.new(EventCatalog.get_road_events(), seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var starved := false

	for day in range(1, JOURNEY_DAYS + 1):
		session.journey_days_remaining = maxi(0, session.journey_days_remaining - 1)

		var eaten := 1 + session.caravan.merchant_names.size()
		eaten = maxi(1, int(round(eaten * session.get_daily_provision_multiplier())))
		session.change_provisions(-eaten)
		if session.get_provisions() <= 0:
			starved = true
			session.caravan.change_morale(-10)

		var event := engine.roll_for_day(day, session.build_event_context())
		if event == null:
			continue

		engine.mark_fired(event, day)
		if not event.immediate_effects.is_empty():
			_apply(event.immediate_effects, session, danger, rng)
		_resolve_first_available_choice(event, engine, session, danger, rng)

	var wagons_before := session.caravan.wagon_count
	var payout := session.finish_journey()

	return {
		"net": int(payout.net),
		"morale": session.caravan.morale,
		"wagons_lost": maxi(0, 4 - wagons_before),
		"contracts_lost": int(payout.get("lost_contracts", 0)),
		"ran_out_of_provisions": starved,
	}

func _resolve_first_available_choice(
	event: GameEvent, engine: EventEngine, session: GameSession,
	danger: float, rng: RandomNumberGenerator
) -> void:
	var context := session.build_event_context()
	for choice in event.choices:
		if not choice.is_available(context):
			continue
		_apply(choice.effects, session, danger, rng)
		var outcome := engine.resolve_outcome(choice, session.build_event_context())
		if outcome != null:
			_apply(outcome.effects, session, danger, rng)
		return

## Etkiler uygulanır; savaş isteği çıkarsa gerçek motor koşturulur ve
## sonucu road_journey ile aynı etkilere çevrilir.
func _apply(
	effects: Array[EventEffect], session: GameSession,
	danger: float, rng: RandomNumberGenerator
) -> void:
	var result := EventEffectApplier.apply(effects, session)
	if result.combat_requests.is_empty():
		return

	var victory := _simulate_combat(session.get_party(), danger, rng)
	var aftermath: Array[EventEffect] = []
	if victory:
		aftermath.append(EventEffect.make(EventEffect.Type.GOLD, 25 + int(round(danger * 60.0))))
		aftermath.append(EventEffect.make(EventEffect.Type.MORALE, 12))
		aftermath.append(EventEffect.make(EventEffect.Type.REPUTATION, 4))
	else:
		aftermath.append(EventEffect.make(EventEffect.Type.GOLD, -40))
		aftermath.append(EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 2))
		aftermath.append(EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, 1))
		aftermath.append(EventEffect.make(EventEffect.Type.MORALE, -20))
	var _aftermath_result := EventEffectApplier.apply(aftermath, session)

func _simulate_combat(party: Array[CharacterData], danger: float, rng: RandomNumberGenerator) -> bool:
	var units: Array[CombatUnit] = []
	var position := 1
	for character in party:
		if position > CombatEncounter.MAX_SIDE_SIZE:
			break
		units.append(CombatUnit.from_character(character, position))
		position += 1

	var enemies := EnemyCatalog.build_bandit_squad(danger, units.size(), rng)
	var encounter := CombatEncounter.new(units, enemies, rng)
	encounter.start()

	var guard := 0
	while not encounter.is_over() and guard < 400:
		if not _take_greedy_action(encounter):
			break
		guard += 1

	encounter.write_back_party()
	return encounter.state == CombatEncounter.State.VICTORY

## En zayıf ulaşılabilir hedefe en sert vuran yeteneği seçer.
func _take_greedy_action(encounter: CombatEncounter) -> bool:
	if not encounter.is_player_turn():
		return false

	var unit := encounter.get_active_unit()
	var best_skill: CombatSkill = null
	var best_target: CombatUnit = null

	for skill in unit.skills:
		if skill.is_heal():
			continue
		var targets := encounter.get_valid_targets(unit, skill)
		if targets.is_empty():
			continue
		if best_skill == null or skill.base_damage > best_skill.base_damage:
			best_skill = skill
			best_target = targets[0]
			for candidate in targets:
				if candidate.current_hp < best_target.current_hp:
					best_target = candidate

	if best_skill != null:
		return encounter.use_skill(best_skill, best_target)

	var living: Array[CombatUnit] = []
	for candidate in encounter.player_units:
		if candidate.is_alive():
			living.append(candidate)
	if living.size() >= 2:
		return encounter.swap_player_positions(living[0], living[1])
	return false

func _report(danger: float, stats: Dictionary) -> void:
	print("  Tehlike %%%d" % int(danger * 100.0))
	print("    net kazanç      ortalama %7.1f GG   (en kötü %d, en iyi %d)" % [
		stats.net_avg, stats.worst_net, stats.best_net
	])
	print("    bitiş morali    ortalama %7.1f" % stats.morale_avg)
	print("    erzak tükendi   %%%.1f koşuda" % stats.starved_pct)
	print("    vagon kaybı     ortalama %7.2f" % stats.wagons_lost_avg)
	print("    teslim edilemeyen kontrat  %.2f" % stats.contracts_lost_avg)
	print("")

func _report_combat(party_size: int) -> void:
	var wins := 0
	var battles := 60

	for index in battles:
		var rng := RandomNumberGenerator.new()
		rng.seed = 500 + index

		var party: Array[CharacterData] = []
		for slot in party_size:
			party.append(CharacterData.create(
				"Yoldaş %d" % (slot + 1),
				CultureCatalog.get_cultures()[slot % CultureCatalog.get_cultures().size()].culture_id,
				CharacterStats.new()
			))

		if _simulate_combat(party, 0.5, rng):
			wins += 1

	print("    %d kişilik parti: %%%d kazanıyor (%d/%d)" % [
		party_size, int(round(100.0 * float(wins) / float(battles))), wins, battles
	])
