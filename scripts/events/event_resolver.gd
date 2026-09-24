class_name EventResolver
extends RefCounted

## Bir olay kartında seçilen seçeneğin tek çözüm yolu: seçeneğin kendi
## etkileri → skill-check zarı → ağırlıklı sonuç → sonucun etkileri → olayın
## XP'si. Bu sıra eskiden yol ekranında (`road_journey.gd`) yaşıyordu ve üç
## ölçüm aracında (playthrough demosu, iki simülatör) elle kopyalanıyordu -
## Faz 17'nin `resolve_check()`'i gibi her değişiklik dört yere ayrı ayrı
## işlenmek zorundaydı. Şimdi tek yerde; ekran yalnızca sonucu çiziyor ve
## yan kanalları (savaş, pazarlık, yol tayfası) açıyor.
##
## Sahne ağacına dokunmuyor, yani doğrudan sınanabilir.

class Resolution extends RefCounted:
	## Seçeneğin kendi (zarsız) etkilerinin sonucu; etkisi yoksa null.
	var choice_result: EventEffectApplier.Result = null
	## Çekilen sonuç; seçeneğin sonuç listesi yoksa null.
	var outcome: EventOutcome = null
	var outcome_result: EventEffectApplier.Result = null
	## Zar atıldıysa check_tier (0/1/2), atılmadıysa -1.
	var check_tier: int = -1
	## grant_party_xp'nin dönüşü (isim -> atlanan seviye).
	var levels_gained: Dictionary = {}

	## Sırasıyla uygulanan etki sonuçları - yan kanallar bu sırayla açılır.
	func get_results() -> Array[EventEffectApplier.Result]:
		var results: Array[EventEffectApplier.Result] = []
		if choice_result != null:
			results.append(choice_result)
		if outcome_result != null:
			results.append(outcome_result)
		return results

## Yolun o günkü durağından olay bağlamına giren bayraklar. Her durak
## türünün bir bayrağı var; olaylar ağırlıklarını bunlara bağlıyor
## (bkz. evt_roadside_shrine, evt_leave_the_wounded, evt_mine_collapse...).
const STOP_CONTEXT_KEYS: Dictionary = {
	RouteTerrain.STOP_SHRINE: "near_shrine",
	RouteTerrain.STOP_PASS: "near_mountain_pass",
	RouteTerrain.STOP_HAMLET: "near_hamlet",
	RouteTerrain.STOP_OUTPOST: "near_outpost",
	RouteTerrain.STOP_MINE: "near_mine",
	RouteTerrain.STOP_BRIDGE: "near_bridge",
}

static func stop_context(stop: String) -> Dictionary:
	var context := {}
	for stop_id in STOP_CONTEXT_KEYS:
		context[STOP_CONTEXT_KEYS[stop_id]] = 1.0 if stop == stop_id else 0.0
	return context

## `apply_effects`: etkileri uygulayan kanca. Boşsa doğrudan
## `EventEffectApplier.apply()`; yol ekranı kendi sarmalayıcısını veriyor
## (TRAVEL_DAYS'in yolun uzunluğuna yazılması - bkz. road_journey.gd
## `_apply_effects`).
static func resolve_choice(
	session: GameSession, engine: EventEngine, event: GameEvent, choice: EventChoice,
	apply_effects: Callable = Callable()
) -> Resolution:
	var resolution := Resolution.new()
	if not choice.effects.is_empty():
		resolution.choice_result = _apply(choice.effects, session, apply_effects)

	# Check varsa zar burada atılıyor - koşulların gördüğü bağlam kopyası
	# "check_tier" taşıyor (bkz. EventEngine.resolve_check).
	var checked_context := engine.resolve_check(choice, session.build_event_context())
	if checked_context.has("check_tier"):
		resolution.check_tier = int(checked_context["check_tier"])
	resolution.outcome = engine.resolve_outcome(choice, checked_context)
	if resolution.outcome != null and not resolution.outcome.effects.is_empty():
		resolution.outcome_result = _apply(resolution.outcome.effects, session, apply_effects)

	for result in resolution.get_results():
		for event_id in result.unlocked_event_ids:
			engine.unlock_event(event_id)

	if event != null and event.xp_value > 0:
		resolution.levels_gained = session.grant_party_xp(event.xp_value)
	return resolution

static func _apply(
	effects: Array[EventEffect], session: GameSession, apply_effects: Callable
) -> EventEffectApplier.Result:
	if apply_effects.is_valid():
		return apply_effects.call(effects)
	return EventEffectApplier.apply(effects, session)
