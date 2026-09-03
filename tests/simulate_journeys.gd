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

	# Faz 6-7'nin kültür/görev/ekipman koşullu içeriğini hiçbir zaman
	# çalıştırmayan bir simülatör yanlış bir güven verir - olay ateşlenme
	# sıklığını burada topluca görmek için üç tehlike koşusunun sayaçları
	# birleştiriliyor (bkz. _report_event_frequency).
	var merged_event_counts: Dictionary = {}
	for danger in DANGER_LEVELS:
		var stats := _run_batch(danger)
		_report(danger, stats)
		var batch_counts: Dictionary = stats.event_counts
		for event_id in batch_counts:
			merged_event_counts[event_id] = int(merged_event_counts.get(event_id, 0)) + int(batch_counts[event_id])

	_report_event_frequency(merged_event_counts)

	print("── Savaş dengesi (parti büyüklüğüne göre kazanma oranı)")
	var party_sizes: Array[int] = [1, 2, 3, 4]
	for party_size in party_sizes:
		_report_combat(party_size)

	print("")
	print("── Seviye dengesi (4 kişilik parti, tehlike %50, düşman da seviyeye göre büyür)")
	print("   Hedef: seviye 1 ~%%40-55, seviye 15 ~%%75-88 kazanmalı - Sekban/Kırıkçı/Kalem")
	print("   Efendisi katılımıyla dört sınıf da dönüşümlü test ediliyor.")
	var levels_to_check: Array[int] = [1, 5, 10, 15]
	for level in levels_to_check:
		_report_combat_at_level(level)

	print("")
	print("── Ekipman etkisi (tehlike %50)")
	_report_equipment_impact()

	print("")
	print("── Görev sağlık kontrolü (Sıra Neferi, seviye 1 ve 10)")
	_report_duty_impact()

	quit(0)

func _run_batch(danger: float) -> Dictionary:
	var net_total := 0
	var morale_total := 0
	var provisions_out := 0
	var wagons_lost := 0
	var contracts_lost := 0
	var worst_net := 1 << 30
	var best_net := -(1 << 30)
	var stress_total := 0
	var breaks_total := 0
	var departures_total := 0
	var event_counts: Dictionary = {}

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
		stress_total += int(outcome.stress_before_rest)
		breaks_total += int(outcome.breaks)
		departures_total += int(outcome.departures)
		for event_id in (outcome.fired_events as Array):
			event_counts[event_id] = int(event_counts.get(event_id, 0)) + 1

	return {
		"net_avg": float(net_total) / float(RUN_COUNT),
		"morale_avg": float(morale_total) / float(RUN_COUNT),
		"starved_pct": 100.0 * float(provisions_out) / float(RUN_COUNT),
		"wagons_lost_avg": float(wagons_lost) / float(RUN_COUNT),
		"contracts_lost_avg": float(contracts_lost) / float(RUN_COUNT),
		"worst_net": worst_net,
		"best_net": best_net,
		"stress_avg": float(stress_total) / float(RUN_COUNT),
		"breaks_avg": float(breaks_total) / float(RUN_COUNT),
		"departures_total": departures_total,
		"event_counts": event_counts,
	}

## Bir seferi baştan sona koşturur. Olay seçenekleri "ilk uygun seçenek"
## kuralıyla seçilir; oyuncu zekâsını taklit etmez ama alt sınırı verir.
func _run_single(danger: float, seed_value: int) -> Dictionary:
	var session := GameSession.new(STARTING_GOLD, STARTING_PROVISIONS, 2)
	session.danger_level = danger
	session.journey_destination_id = WorldMapData.START_LOCATION_ID
	session.journey_total_days = JOURNEY_DAYS
	session.journey_days_remaining = JOURNEY_DAYS

	# Kültürü ve görevi her koşuda döndürmek beş evt_culture_* olayının ve
	# İzci/Levazımcı/Otacı/Arabacı/Tellal/Muhafız'ın hepsini simülasyona
	# sokuyor - sabit varsayılan oyuncu bunların çoğunu hiç görmüyordu.
	var cultures := CultureCatalog.get_cultures()
	var player := CharacterData.create(
		"Simülasyon", cultures[seed_value % cultures.size()].culture_id, CharacterStats.new()
	)
	player.heal_full()
	session.set_player_character(player)

	var duties: Array[String] = [
		DutyCatalog.MUHAFIZ, DutyCatalog.IZCI, DutyCatalog.LEVAZIMCI,
		DutyCatalog.ARABACI, DutyCatalog.TELLAL, DutyCatalog.OTACI,
	]
	session.assign_duty(player, duties[seed_value % duties.size()])

	# Üçte bir oranında ekipmanlı - GRANT_EQUIPMENT'in doldurduğu depodan
	# takılmış gibi, equipment'in combat sonuçlarına gerçekten karıştığı
	# koşular da örneklemde olsun diye (bkz. _report_equipment_impact
	# ayrıca izole bir A/B karşılaştırması yapıyor).
	if seed_value % 3 == 0:
		session.add_equipment(EquipmentCatalog.WEAPON_TIER_2, 1)
		session.add_equipment(EquipmentCatalog.ARMOR_TIER_2, 1)
		session.equip_to_character(player, EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_2)
		session.equip_to_character(player, EquipmentCatalog.SLOT_ARMOR, EquipmentCatalog.ARMOR_TIER_2)

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
	var fired_events: Array[String] = []

	for day in range(1, JOURNEY_DAYS + 1):
		session.journey_days_remaining = maxi(0, session.journey_days_remaining - 1)

		var eaten := 1 + session.caravan.merchant_names.size()
		eaten = maxi(1, int(round(eaten * session.get_daily_provision_multiplier())))
		session.change_provisions(-eaten)
		if session.get_provisions() <= 0:
			starved = true
			session.caravan.change_morale(-10)
			session.change_stress(6)  # bkz. road_journey.gd FAMINE_STRESS

		var event := engine.roll_for_day(day, session.build_event_context())
		if event == null:
			continue

		engine.mark_fired(event, day)
		fired_events.append(event.event_id)
		if not event.immediate_effects.is_empty():
			_apply(event.immediate_effects, session, danger, rng, engine)
		_resolve_first_available_choice(event, engine, session, danger, rng)

	var wagons_before := session.caravan.wagon_count
	var stress_before_rest := session.party_stress
	var payout := session.finish_journey()
	# finish_journey() zaten resolve_stress_breaks() çağırıyor - burada
	# tekrar çağırmak aynı karakteri iki kez kırardı.
	var stress_breaks: Array = payout.get("stress_breaks", [])

	var departures := 0
	for entry in stress_breaks:
		if bool((entry as Dictionary).get("departed", false)):
			departures += 1

	return {
		"net": int(payout.net),
		"morale": session.caravan.morale,
		"wagons_lost": maxi(0, 4 - wagons_before),
		"contracts_lost": int(payout.get("lost_contracts", 0)),
		"ran_out_of_provisions": starved,
		"stress_before_rest": stress_before_rest,
		"breaks": stress_breaks.size(),
		"departures": departures,
		"fired_events": fired_events,
	}

func _resolve_first_available_choice(
	event: GameEvent, engine: EventEngine, session: GameSession,
	danger: float, rng: RandomNumberGenerator
) -> void:
	var context := session.build_event_context()
	for choice in event.choices:
		if not choice.is_available(context):
			continue
		_apply(choice.effects, session, danger, rng, engine)
		var outcome := engine.resolve_outcome(choice, session.build_event_context())
		if outcome != null:
			_apply(outcome.effects, session, danger, rng, engine)
		return

## Etkiler uygulanır; savaş isteği çıkarsa gerçek motor koşturulur ve
## sonucu road_journey ile aynı etkilere (stres dahil) çevrilir.
const SIM_COMBAT_STRESS_BASE: int = 8
const SIM_COMBAT_STRESS_PER_DOWN: int = 6
const SIM_COMBAT_VICTORY_STRESS_RELIEF: int = 4
const SIM_COMBAT_DEFEAT_STRESS: int = 15

func _apply(
	effects: Array[EventEffect], session: GameSession,
	danger: float, rng: RandomNumberGenerator, engine: EventEngine = null
) -> void:
	var result := EventEffectApplier.apply(effects, session)

	# road_journey.gd zincir olaylarını böyle açıyor (bkz.
	# EventEffect.Type.UNLOCK_EVENT) - burada da yapılmazsa triggered_only
	# zincir olayları (evt_stowaway_repay gibi) simülasyonda hiçbir zaman
	# ateşlenemez, kaynağı bulunan gerçek bir eksiklik değil sahte bir
	# "hiç çekilmiyor" alarmı verir (bkz. _report_event_frequency).
	if engine != null:
		for event_id in result.unlocked_event_ids:
			engine.unlock_event(event_id)

	if result.combat_requests.is_empty():
		return

	var combat_result := _simulate_combat(session.get_party(), danger, rng, 1, session.party_stress)
	var victory: bool = combat_result.victory
	var downed_count: int = combat_result.downed_count

	var stress_delta := SIM_COMBAT_STRESS_BASE + downed_count * SIM_COMBAT_STRESS_PER_DOWN
	stress_delta += -SIM_COMBAT_VICTORY_STRESS_RELIEF if victory else SIM_COMBAT_DEFEAT_STRESS
	session.change_stress(stress_delta)

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

func _simulate_combat(
	party: Array[CharacterData], danger: float, rng: RandomNumberGenerator,
	average_level: int = 1, party_stress: int = 0
) -> Dictionary:
	var units: Array[CombatUnit] = []
	var position := 1
	for character in party:
		if position > CombatEncounter.MAX_SIDE_SIZE:
			break
		units.append(CombatUnit.from_character(character, position, character.is_stressed(party_stress)))
		position += 1

	var enemies := EnemyCatalog.build_bandit_squad(danger, units.size(), rng, average_level)
	var encounter := CombatEncounter.new(units, enemies, rng)
	encounter.start()

	var guard := 0
	while not encounter.is_over() and guard < 400:
		if not _take_greedy_action(encounter):
			break
		guard += 1

	var downed_count := encounter.get_downed_count()
	encounter.write_back_party()
	return {"victory": encounter.state == CombatEncounter.State.VICTORY, "downed_count": downed_count}

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
	print("    varışta stres   ortalama %7.1f · kırılma %.2f/sefer · toplam ayrılık %d" % [
		stats.stress_avg, stats.breaks_avg, stats.departures_total
	])
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

		if bool(_simulate_combat(party, 0.5, rng).victory):
			wins += 1

	print("    %d kişilik parti: %%%d kazanıyor (%d/%d)" % [
		party_size, int(round(100.0 * float(wins) / float(battles))), wins, battles
	])

## Dört seviyeye kadar zorunlu XP toplayarak gerçekçi bir dağıtım kurar -
## auto_allocate açık olduğu için sınıfın yatkın olduğu statlara gider.
func _level_up(character: CharacterData, target_level: int) -> void:
	var total_xp := 0
	for level in range(1, target_level):
		total_xp += CharacterData.xp_required_for_level(level)
	if total_xp > 0:
		character.gain_xp(total_xp)

func _report_combat_at_level(level: int) -> void:
	var wins := 0
	var battles := 60
	var class_ids: Array[String] = [ClassCatalog.GUARD, ClassCatalog.HUNTER, ClassCatalog.BREAKER, ClassCatalog.CLERK]

	for index in battles:
		var rng := RandomNumberGenerator.new()
		rng.seed = 700 + index

		var party: Array[CharacterData] = []
		for slot in 4:
			var culture := CultureCatalog.get_cultures()[slot % CultureCatalog.get_cultures().size()]
			var character := CharacterData.create(
				"Yoldaş %d" % (slot + 1), culture.culture_id, CharacterStats.new(),
				CharacterData.DEFAULT_HEIGHT_CM, 1, class_ids[slot]
			)
			_level_up(character, level)
			party.append(character)

		if bool(_simulate_combat(party, 0.5, rng, level).victory):
			wins += 1

	print("    seviye %2d: %%%d kazanıyor (%d/%d)" % [
		level, int(round(100.0 * float(wins) / float(battles))), wins, battles
	])

## 22 olayın hepsi gerçekten çekiliyor mu, biri (kültür/İzci koşulu hiç
## sağlanmadığı için) asılı mı kalmış - tek tek elle kontrol etmek yerine
## topluca burada görülüyor. En az çekilenler üstte.
func _report_event_frequency(counts: Dictionary) -> void:
	print("── Olay ateşlenme sıklığı (%d koşu toplamı)" % (RUN_COUNT * DANGER_LEVELS.size()))

	var rows: Array[Dictionary] = []
	for event in EventCatalog.get_road_events():
		rows.append({"id": event.event_id, "count": int(counts.get(event.event_id, 0))})
	rows.sort_custom(func(a, b): return a.count < b.count)

	for row in rows:
		var marker := "  ⚠ hiç ateşlenmedi" if row.count == 0 else ""
		print("    %-28s %4d%s" % [row.id, row.count, marker])
	print("")

## Equipment'in savaşa gerçekten katkısı ne kadar - donanımsız/tam donanımlı
## aynı parti arasındaki kazanma oranı farkı (bkz. Faz 7 PR-A/B). 4 kişilik
## parti tehlike %50'de zaten %100 kazanıyor (bkz. Savaş dengesi raporu) -
## tavanda ölçüm yapmak hiçbir farkı göstermez, o yüzden burada tavana
## çarpmayan tek kişilik parti kullanılıyor (bare taban zaten %63).
const EQUIPMENT_TEST_PARTY_SIZE: int = 1

func _report_equipment_impact() -> void:
	var battles := 60
	var bare_wins := _battle_batch(battles, false)
	var geared_wins := _battle_batch(battles, true)
	print("    donanımsız %d kişi                      %%%d kazanıyor (%d/%d)" % [
		EQUIPMENT_TEST_PARTY_SIZE, int(round(100.0 * float(bare_wins) / float(battles))), bare_wins, battles
	])
	print("    tam donanımlı (T3+yüzük+kolye) %d kişi  %%%d kazanıyor (%d/%d)" % [
		EQUIPMENT_TEST_PARTY_SIZE, int(round(100.0 * float(geared_wins) / float(battles))), geared_wins, battles
	])

func _battle_batch(battles: int, geared: bool) -> int:
	var wins := 0
	for index in battles:
		var rng := RandomNumberGenerator.new()
		rng.seed = 900 + index

		var party: Array[CharacterData] = []
		for slot in EQUIPMENT_TEST_PARTY_SIZE:
			var culture := CultureCatalog.get_cultures()[slot % CultureCatalog.get_cultures().size()]
			var character := CharacterData.create(
				"Yoldaş %d" % (slot + 1), culture.culture_id, CharacterStats.new()
			)
			if geared:
				_equip_best_gear(character)
			party.append(character)

		if bool(_simulate_combat(party, 0.5, rng).victory):
			wins += 1
	return wins

func _equip_best_gear(character: CharacterData) -> void:
	var pieces: Array[String] = [
		EquipmentCatalog.WEAPON_TIER_3, EquipmentCatalog.ARMOR_TIER_3,
		EquipmentCatalog.RING_MARKSMAN, EquipmentCatalog.AMULET_WOLF_FANG,
	]
	for equipment_id in pieces:
		var equipment_resource := EquipmentCatalog.get_equipment(equipment_id)
		character.equip(equipment_resource.slot, equipment_id)

## Görev sayılarının kaba bir sağlık kontrolü - seviye ilerledikçe
## get_duty_flat_reduction/get_duty_discount anlamlı büyüyor mu, yoksa
## sürekli 0'da mı kalıyor (bkz. GameSession.get_duty_flat_reduction).
func _report_duty_impact() -> void:
	var duties: Array[String] = [
		DutyCatalog.MUHAFIZ, DutyCatalog.IZCI, DutyCatalog.LEVAZIMCI,
		DutyCatalog.ARABACI, DutyCatalog.TELLAL, DutyCatalog.OTACI,
	]
	for level in [1, 10]:
		var session := GameSession.new(100, 0, 1)
		var holder := session.get_player_character()
		holder.class_id = ClassCatalog.GUARD
		_level_up(holder, level)
		print("    seviye %d Sıra Neferi:" % level)
		for duty_id in duties:
			session.assign_duty(holder, duty_id)
			var duty := DutyCatalog.get_duty(duty_id)
			print("      %-12s çarpan %.2f · indirim %%%.0f · azaltma %d" % [
				duty.display_name,
				session.get_duty_multiplier(duty_id),
				session.get_duty_discount(duty_id) * 100.0,
				session.get_duty_flat_reduction(duty_id),
			])
