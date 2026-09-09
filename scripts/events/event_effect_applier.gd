class_name EventEffectApplier
extends RefCounted

## Etkileri oyun durumuna uygular ve oyuncuya gösterilecek özet satırlarını
## döner. Sınırlamalar tek tek olaylarda değil burada zorlanır: bir olay
## "10 vagon kaybet" derse bile kervan çekirdeği ayakta kalır.
##
## Ayakta kalmak dokunulmazlık değil (bkz. CLAUDE.md Caravan Ruin Rules):
## lider, kendi vagonu ve ona sadık kalanlar dışında her şey kaybedilebilir,
## kese eksiye düşebilir ve kervan borca batabilir. Kenetlenen tek şey
## kervanın çekirdeği - para değil.

## Bir seferde uygulanabilecek etkiler burada toplanır; TRIGGER_HAGGLING
## gibi UI'a devredilen istekler ayrıca bildirilir.
class Result extends RefCounted:
	var lines: Array[String] = []
	var haggling_requests: Array[int] = []
	## Savaşın tehlike seviyesi yüzde olarak; 0 ise yolun kendi tehlikesi
	## kullanılır (bkz. road_journey.gd _open_combat).
	var combat_requests: Array[int] = []
	## combat_requests ile aynı sırada: EnemyCatalog.build_squad'ın kind
	## parametresi ("bandit"/"wildlife"/"guard"). Boş text_value "bandit"
	## sayılır - evt_bandit_ambush gibi eski tanımlar hiçbir şey değiştirmeden
	## çalışmaya devam eder.
	var combat_kinds: Array[String] = []
	## Yolda partiye katılma teklifi; değer istenen ücrettir.
	var recruit_requests: Array[int] = []

	## Yol ekranı bir olay çözümünde **tek** yan kanal açabilir (savaş,
	## pazarlık ya da tayfa - bkz. road_journey.gd _apply_side_channels):
	## panellerin hepsi aynı yeri kaplıyor ve zaman ikisi birden açıkken
	## akmıyor. Bugün hiçbir olay ikisini birden istemiyor; isteseydi
	## ikincisi sessizce düşerdi. Bu sayaç o sessizliği ölçülebilir kılıyor
	## (bkz. tests/test_event_effects.gd).
	var unlocked_event_ids: Array[String] = []

	func get_side_channel_count() -> int:
		return combat_requests.size() + recruit_requests.size() + haggling_requests.size()

## tr() bir Object örnek metodu, buradaki her şey static (bkz. CLAUDE.md
## Localization Rules) - o yüzden çeviriler TranslationServer'dan geçiyor.
static func _t(key: String) -> String:
	return String(TranslationServer.translate(key))

static func apply(effects: Array[EventEffect], session: GameSession) -> Result:
	var result := Result.new()
	for effect in effects:
		_apply_single(effect, session, result)
	return result

static func _apply_single(effect: EventEffect, session: GameSession, result: Result) -> void:
	match effect.type:
		EventEffect.Type.GOLD:
			_apply_gold(effect, session, result)
		EventEffect.Type.PROVISIONS:
			var changed := session.change_provisions(effect.amount)
			if changed != 0:
				result.lines.append(_t("EFF_PROVISIONS") % changed)
		EventEffect.Type.ITEM_ADD:
			var item := ItemCatalog.get_item(effect.text_value)
			if item != null and session.inventory.add_item(item, effect.amount):
				result.lines.append(_t("EFF_ITEM_ADD") % [item.item_name, effect.amount])
		EventEffect.Type.ITEM_REMOVE:
			var removed := session.inventory.remove_item(effect.text_value, effect.amount)
			if removed:
				result.lines.append(_t("EFF_ITEM_REMOVE") % [effect.text_value, effect.amount])
		EventEffect.Type.WAGON_DAMAGE:
			# Arabacı elinden geldiğince hasarı azaltır ama tamamen sıfırlamaz.
			var reduced := maxi(0, effect.amount - session.get_duty_flat_reduction(DutyCatalog.ARABACI))
			var damaged := session.caravan.damage_wagons(reduced)
			if damaged > 0:
				result.lines.append(_t("EFF_WAGON_DAMAGE") % damaged)
		EventEffect.Type.WAGON_LOSE:
			var lost := session.caravan.lose_wagons(effect.amount)
			if lost > 0:
				result.lines.append(_t("EFF_WAGON_LOSE") % lost)
		EventEffect.Type.WAGON_REPAIR:
			var repaired := session.caravan.repair_wagons(effect.amount)
			if repaired > 0:
				result.lines.append(_t("EFF_WAGON_REPAIR") % repaired)
		EventEffect.Type.MERCHANT_LEAVE:
			var left := session.caravan.remove_merchants(effect.amount)
			for merchant_name in left:
				result.lines.append(_t("EFF_MERCHANT_LEAVE") % merchant_name)
		EventEffect.Type.MORALE:
			session.caravan.change_morale(effect.amount)
			result.lines.append(_t("EFF_MORALE") % [effect.amount, session.caravan.morale])
		EventEffect.Type.STRESS:
			session.change_stress(effect.amount)
			result.lines.append(_t("EFF_STRESS") % [effect.amount, session.party_stress])
		EventEffect.Type.TRAVEL_DAYS:
			session.journey_days_remaining = maxi(0, session.journey_days_remaining + effect.amount)
			result.lines.append(_t("EFF_TRAVEL_DAYS") % effect.amount)
		EventEffect.Type.DANGER:
			session.danger_level = clampf(session.danger_level + (effect.amount / 100.0), 0.0, 1.0)
			result.lines.append(_t("EFF_DANGER") % effect.amount)
		EventEffect.Type.REPUTATION:
			session.reputation += effect.amount
			result.lines.append(_t("EFF_REPUTATION") % effect.amount)
		EventEffect.Type.DOCUMENT_LOSE:
			var seized := session.caravan.lose_documents(effect.amount)
			if seized > 0:
				result.lines.append(_t("EFF_DOCUMENT_LOSE") % seized)
		EventEffect.Type.SET_FLAG:
			session.set_flag(effect.text_value)
		EventEffect.Type.CLEAR_FLAG:
			session.clear_flag(effect.text_value)
		EventEffect.Type.UNLOCK_EVENT:
			result.unlocked_event_ids.append(effect.text_value)
		EventEffect.Type.TRIGGER_HAGGLING:
			result.haggling_requests.append(effect.amount)
			result.lines.append(_t("EFF_HAGGLE_OPENING"))
		EventEffect.Type.TRIGGER_COMBAT:
			result.combat_requests.append(effect.amount)
			result.combat_kinds.append(effect.text_value if not effect.text_value.is_empty() else "bandit")
			result.lines.append(_t("EFF_COMBAT_OPENING"))
		EventEffect.Type.TRIGGER_RECRUIT:
			result.recruit_requests.append(effect.amount)
		EventEffect.Type.GRANT_TRAIT:
			_apply_grant_trait(effect, session, result)
		EventEffect.Type.GRANT_EQUIPMENT:
			_apply_grant_equipment(effect, session, result)
		EventEffect.Type.MARKET_SHOCK:
			_apply_market_shock(effect, session, result)
		EventEffect.Type.ROUTE_CHANGE:
			_apply_route_change(effect, session, result)
		EventEffect.Type.ROLL_ENCOUNTER:
			_apply_roll_encounter(effect, session, result)

## Huy her zaman oyuncunun kendi karakterine verilir - olayın kervanın
## lideri başına geldiği kabulüyle (bkz. GameEvent/RoadJourney tasarımı).
## text_value bir TraitCatalog kimliği taşımalı.
static func _apply_grant_trait(effect: EventEffect, session: GameSession, result: Result) -> void:
	var character := session.get_player_character()
	if character == null:
		return
	if character.grant_trait(effect.text_value, session.total_days_elapsed):
		var trait_resource := TraitCatalog.get_trait(effect.text_value)
		if trait_resource != null:
			result.lines.append(_t("EFF_TRAIT_GRANTED") % trait_resource.display_name)

## Bulunan tılsım/parça doğrudan takılmaz - kervanın ekipman deposuna
## düşer (bkz. GameSession.equipment_inventory), oyuncu karakter
## ekranından hangi karaktere takacağını seçer. text_value bir
## EquipmentCatalog kimliği taşımalı.
static func _apply_grant_equipment(effect: EventEffect, session: GameSession, result: Result) -> void:
	var equipment_resource := EquipmentCatalog.get_equipment(effect.text_value)
	if equipment_resource == null:
		return
	session.add_equipment(effect.text_value, maxi(1, effect.amount))
	result.lines.append(_t("EFF_EQUIPMENT_FOUND") % equipment_resource.display_name)

## Kervan borca batabilir: ödemek zorunda olduğun bedel kesende yoksa kese
## eksiye düşer ve fark açık hesaba yazılır (bkz. GameSession.spend_or_owe).
## Eskiden burada "kasada ne varsa o kadarı alınır" clamp'i vardı - haraç
## verecek parası olmayan kervan bedavaya kurtuluyordu. Kervanın yok
## olmaması onu dokunulmaz yapmıyor; sürünmesinin parasal karşılığı budur.
static func _apply_gold(effect: EventEffect, session: GameSession, result: Result) -> void:
	if effect.amount >= 0:
		session.wallet.earn(effect.amount)
		result.lines.append(_t("EFF_GOLD_GAIN") % effect.amount)
		return

	var demanded := -effect.amount
	var before := session.wallet.balance
	session.spend_or_owe(demanded)
	result.lines.append(_t("EFF_GOLD_LOSS") % demanded)
	if before >= 0 and session.wallet.balance < 0:
		result.lines.append(_t("EFF_WENT_INTO_DEBT"))

## Ekonomik/politik bir olayın fiyata süreli etkisi - grev, kıtlık, ambargo,
## bereketli hasat. text_value "location_id|item_id|gün" biçiminde; item_id
## boş bırakılırsa o şehirdeki tüm mallar etkilenir. Kâr yalnızca şehirler
## arası farktan gelmiyor, bu da bir kaynağı (bkz. MarketConditions).
static func _apply_market_shock(
	effect: EventEffect, session: GameSession, result: Result
) -> void:
	var parts := effect.text_value.split("|")
	if parts.is_empty() or String(parts[0]).is_empty():
		return
	var location_id := String(parts[0])
	var item_id := String(parts[1]) if parts.size() > 1 else ""
	var duration := int(String(parts[2])) if parts.size() > 2 else 14

	var multiplier := 1.0 + float(effect.amount) / 100.0
	session.market.add_shock(
		location_id, item_id, multiplier, session.total_days_elapsed + maxi(1, duration)
	)
	result.lines.append(_t("EFF_MARKET_SHOCK") % [effect.amount, duration])

## Yolun durumu bir süreliğine değişir - çığ, sel, eşkıya baskını ya da tam
## tersi, yolu temizleyen bir devriye. Rotanın kendi tablosuna dokunulmuyor
## (bkz. RouteConditions): coğrafya sabit kalır, üstündeki ağ oynar.
static func _apply_route_change(
	effect: EventEffect, session: GameSession, result: Result
) -> void:
	var parts := effect.text_value.split("|")
	if parts.size() < 2:
		return

	# "current|durum": kervanın o an üstünde olduğu yol. Yol olayları belirli
	# bir geçidin adını bilemez - hangi rotada oldukları çalışma anında
	# belli olur, o yüzden kısayol gerekiyor.
	var from_id := String(parts[0])
	var to_id := String(parts[1])
	var state_name := String(parts[2]) if parts.size() > 2 else ""
	if from_id == "current":
		from_id = session.journey_origin_id
		to_id = session.journey_destination_id
		state_name = String(parts[1])
	if WorldMapData.get_route(from_id, to_id) == null:
		return

	var state := RouteConditions.parse_state(state_name)
	var duration := maxi(1, effect.amount)
	session.route_conditions.add_override(
		from_id, to_id, state, session.total_days_elapsed + duration
	)

	var from_location := WorldMapData.get_location_by_id(from_id)
	var to_location := WorldMapData.get_location_by_id(to_id)
	result.lines.append(_t("EFF_ROUTE_CHANGE") % [
		from_location.location_name if from_location != null else from_id,
		to_location.location_name if to_location != null else to_id,
		RouteConditions.get_state_label(state),
		duration,
	])

## Karşılaşılan kişinin gizli mizacını ve kültür yakınlığını belirler.
## Bir yolcuyu almak tek başına iyi ya da kötü bir karar değil - kimi
## aldığına bağlı, ve bunu oyuncu peşinen bilmiyor.
##
## Yuvarlama gün + önek ile tohumlanıyor: aynı olay aynı gün aynı kişiyi
## çıkarır (ekranı kapatıp açmak mizacı yeniden atmaz), farklı günlerde
## farklı biri çıkar.
static func _apply_roll_encounter(
	effect: EventEffect, session: GameSession, result: Result
) -> void:
	var prefix := effect.text_value
	if prefix.is_empty():
		return

	# Önceki karşılaşmanın bayrakları temizlenmezse eski mizaç yenisine
	# karışır ve sonuçlar iki kişiyi birden dinler.
	for disposition in NpcDisposition.ALL:
		session.clear_flag(NpcDisposition.get_flag(prefix, disposition))
	session.clear_flag("%s_kin" % prefix)
	session.clear_flag("%s_read" % prefix)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|encounter" % [prefix, session.total_days_elapsed])

	var disposition := NpcDisposition.roll(rng)
	session.set_flag(NpcDisposition.get_flag(prefix, disposition))

	# Kültür yakınlığı: karşındaki seninle aynı boydansa kapı başka açılır.
	# Bu yalnızca göçebelere özgü değil - hangi kültürden olursan ol eşleşme
	# aynı ağırlıkta çalışır.
	var cultures := CultureCatalog.get_cultures()
	var met_culture: Culture = cultures[rng.randi_range(0, cultures.size() - 1)]
	if met_culture.culture_id == session.get_player_character().culture_id:
		session.set_flag("%s_kin" % prefix)

	# Sezgisi kuvvetli biri varsa parti karşısındakini okuyabilir; okuma
	# bayrağı olayın "içine bak" seçeneğini açar.
	if session.get_best_effective_stat(CharacterStats.Kind.PERCEPTION) >= NpcDisposition.READ_PERCEPTION_THRESHOLD:
		session.set_flag("%s_read" % prefix)
		result.lines.append(
			_t("EFF_DISPOSITION_HINT") % tr_disposition(disposition)
		)

static func tr_disposition(disposition: String) -> String:
	return String(TranslationServer.translate(NpcDisposition.get_label_key(disposition)))
