class_name EventEffectApplier
extends RefCounted

## Etkileri oyun durumuna uygular ve oyuncuya gösterilecek özet satırlarını
## döner. Sınırlamalar tek tek olaylarda değil burada zorlanır: bir olay
## "10 vagon kaybet" derse bile kervan çekirdeği ayakta kalır.

## Bir seferde uygulanabilecek etkiler burada toplanır; TRIGGER_HAGGLING
## gibi UI'a devredilen istekler ayrıca bildirilir.
class Result extends RefCounted:
	var lines: Array[String] = []
	var haggling_requests: Array[int] = []
	## Savaşın tehlike seviyesi yüzde olarak; 0 ise yolun kendi tehlikesi
	## kullanılır (bkz. road_journey.gd _open_combat).
	var combat_requests: Array[int] = []
	## Yolda partiye katılma teklifi; değer istenen ücrettir.
	var recruit_requests: Array[int] = []
	var unlocked_event_ids: Array[String] = []

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
				result.lines.append("Erzak %+d" % changed)
		EventEffect.Type.ITEM_ADD:
			var item := ItemCatalog.get_item(effect.text_value)
			if item != null and session.inventory.add_item(item, effect.amount):
				result.lines.append("%s +%d" % [item.item_name, effect.amount])
		EventEffect.Type.ITEM_REMOVE:
			var removed := session.inventory.remove_item(effect.text_value, effect.amount)
			if removed:
				result.lines.append("%s -%d" % [effect.text_value, effect.amount])
		EventEffect.Type.WAGON_DAMAGE:
			# Arabacı elinden geldiğince hasarı azaltır ama tamamen sıfırlamaz.
			var reduced := maxi(0, effect.amount - session.get_duty_flat_reduction(DutyCatalog.ARABACI))
			var damaged := session.caravan.damage_wagons(reduced)
			if damaged > 0:
				result.lines.append("%d vagon hasar aldı" % damaged)
		EventEffect.Type.WAGON_LOSE:
			var lost := session.caravan.lose_wagons(effect.amount)
			if lost > 0:
				result.lines.append("%d vagon kaybedildi" % lost)
		EventEffect.Type.MERCHANT_LEAVE:
			var left := session.caravan.remove_merchants(effect.amount)
			for merchant_name in left:
				result.lines.append("%s kervandan ayrıldı" % merchant_name)
		EventEffect.Type.MORALE:
			session.caravan.change_morale(effect.amount)
			result.lines.append("Moral %+d (şimdi %d)" % [effect.amount, session.caravan.morale])
		EventEffect.Type.STRESS:
			session.change_stress(effect.amount)
			result.lines.append("Stres %+d (şimdi %d)" % [effect.amount, session.party_stress])
		EventEffect.Type.TRAVEL_DAYS:
			session.journey_days_remaining = maxi(0, session.journey_days_remaining + effect.amount)
			result.lines.append("Yol %+d gün" % effect.amount)
		EventEffect.Type.DANGER:
			session.danger_level = clampf(session.danger_level + (effect.amount / 100.0), 0.0, 1.0)
			result.lines.append("Tehlike %+d%%" % effect.amount)
		EventEffect.Type.REPUTATION:
			session.reputation += effect.amount
			result.lines.append("İtibar %+d" % effect.amount)
		EventEffect.Type.DOCUMENT_LOSE:
			var seized := session.caravan.lose_documents(effect.amount)
			if seized > 0:
				result.lines.append("%d evraka el konuldu" % seized)
		EventEffect.Type.SET_FLAG:
			session.set_flag(effect.text_value)
		EventEffect.Type.CLEAR_FLAG:
			session.clear_flag(effect.text_value)
		EventEffect.Type.UNLOCK_EVENT:
			result.unlocked_event_ids.append(effect.text_value)
		EventEffect.Type.TRIGGER_HAGGLING:
			result.haggling_requests.append(effect.amount)
			result.lines.append("Pazarlık başlıyor…")
		EventEffect.Type.TRIGGER_COMBAT:
			result.combat_requests.append(effect.amount)
			result.lines.append("Silahlara davranılıyor…")
		EventEffect.Type.TRIGGER_RECRUIT:
			result.recruit_requests.append(effect.amount)
		EventEffect.Type.GRANT_TRAIT:
			_apply_grant_trait(effect, session, result)

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
			result.lines.append("Yeni huy: %s" % trait_resource.display_name)

static func _apply_gold(effect: EventEffect, session: GameSession, result: Result) -> void:
	if effect.amount >= 0:
		session.wallet.earn(effect.amount)
		result.lines.append("Altın +%d" % effect.amount)
		return

	# Ödeyemediğinde borca girmez: kasada ne varsa o kadarı alınır.
	var demanded := -effect.amount
	var paid := mini(demanded, session.wallet.balance)
	if paid > 0:
		session.wallet.spend(paid)
	result.lines.append("Altın -%d" % paid)
