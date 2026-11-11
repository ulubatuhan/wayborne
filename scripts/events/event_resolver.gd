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
	RouteTerrain.STOP_MEZRA: "near_mezra",
	RouteTerrain.STOP_OUTPOST: "near_outpost",
	RouteTerrain.STOP_MINE: "near_mine",
	RouteTerrain.STOP_BRIDGE: "near_bridge",
	RouteTerrain.STOP_FORD: "near_ford",
	RouteTerrain.STOP_WELL: "near_well",
	RouteTerrain.STOP_SERAI: "near_serai",
}

static func stop_context(stop: String, state: String = "") -> Dictionary:
	var context := {}
	for stop_id in STOP_CONTEXT_KEYS:
		context[STOP_CONTEXT_KEYS[stop_id]] = 1.0 if stop == stop_id else 0.0
	# Yol kenarı kervansarayının hâli (Y-B14): açık, harabe, haydut elinde.
	for serai in [RouteTerrain.SERAI_OPEN, RouteTerrain.SERAI_RUIN, RouteTerrain.SERAI_BANDIT]:
		context["serai_" + serai] = 1.0 if stop == RouteTerrain.STOP_SERAI and state == serai else 0.0
	return context

## `stop_context`in aynı deseni, o günkü arazinin kendisi için - bkz.
## evt_hunting_trip: erkek geyik/geyik ormanda ve dağda yaşar, bir bozkır
## gününde avlanma girişiminin ağırlığı taban kalır.
const BIOME_CONTEXT_KEYS: Dictionary = {
	ArtPalette.BIOME_FOREST: "near_forest",
	ArtPalette.BIOME_MOUNTAIN: "near_mountain",
}

static func biome_context(biome: String) -> Dictionary:
	var context := {}
	for biome_id in BIOME_CONTEXT_KEYS:
		context[BIOME_CONTEXT_KEYS[biome_id]] = 1.0 if biome == biome_id else 0.0
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
	# Y-H02: ilk anlamlı karar bir olay kartındaki seçimdir.
	session.mark_first(GameSession.FIRST_DECISION)
	# Ö4 (profil çalışması): Tamamlayıcı profilinin eksik bulduğu şey
	# sayılabilirlikti - "kaç kart gördüm" sorusunun cevabı hiçbir yerde
	# yoktu. Tek kayıt yeri burası: hem yol ekranı hem simülatör bu
	# fonksiyondan geçiyor.
	session.note_event_seen(event.event_id)
	# Dövüş garantisi (2026-11-07): yolu kesen bir kartla yüzleşildi.
	session.note_raid_faced(event)
	# Yankı (§D-A4): aynı kartı ikinci kez cevaplarken **aynı** cevabın
	# bedeli ağırlaşır, ötekilerinki hafifler - dünya öteki cevabı bekliyor.
	# Oran kararın kendisine değil bedeline biniyor: hiçbir seçenek
	# kapanmıyor (A5).
	var echo_scale := _echo_scale(session, event, choice) * _hardship_scale(session)
	session.note_decision(event.event_id, choice.text_key)
	if not choice.effects.is_empty():
		resolution.choice_result = _apply(
			_scaled(choice.effects, echo_scale), session, apply_effects)

	# Check varsa zar burada atılıyor - koşulların gördüğü bağlam kopyası
	# "check_tier" taşıyor (bkz. EventEngine.resolve_check).
	var checked_context := engine.resolve_check(choice, session.build_event_context())
	if checked_context.has("check_tier"):
		resolution.check_tier = int(checked_context["check_tier"])
	resolution.outcome = engine.resolve_outcome(choice, checked_context)
	if resolution.outcome != null and not resolution.outcome.effects.is_empty():
		resolution.outcome_result = _apply(
			_scaled(resolution.outcome.effects, echo_scale), session, apply_effects)

	# Ruh (§D-R2): bedeli ödeyen belliydi, işe yarayıp yaramadığı ancak
	# burada belli olur - zarın sonucu tanıklığın türünü değiştiriyor.
	session.settle_price(resolution.check_tier)

	for result in resolution.get_results():
		for event_id in result.unlocked_event_ids:
			engine.unlock_event(event_id)

	if event != null and event.xp_value > 0:
		resolution.levels_gained = session.grant_party_xp(event.xp_value)
	return resolution

## --- Sertlik kapısı (§D-A3): kıtlık seçeneği kaldırmaz, pahalılaştırır ---
##
## Kıtlık bandı yükseldikçe seçeneklerin kaynak bedeli artar ve beceri
## kontrolünün tavanı iner ("kandıracak kadar tok adam kalmadı"). Hiçbir
## bantta hiçbir seçenek **silinmez** (A1, A5): kıtlık oyunu daraltmaz,
## ağırlaştırır.
const HARDSHIP_BANDS: Array[float] = [0.30, 0.50, 0.70]
const HARDSHIP_COST: Array[float] = [1.0, 1.25, 1.25, 1.3]

static func hardship_band(scarcity: float) -> int:
	var band := 0
	for threshold in HARDSHIP_BANDS:
		if scarcity >= threshold:
			band += 1
	return band

static func _hardship_scale(session: GameSession) -> float:
	var band := hardship_band(session.scarcity_here())
	return HARDSHIP_COST[clampi(band, 0, HARDSHIP_COST.size() - 1)]

## Bedeli ölçeklenen etki türleri: kaynak ve insan. Bayrak, zincir, kart
## açma ve savaş ölçeklenmez - onlar bir miktar değil bir olay.
const SCALABLE_EFFECTS: Array = [
	EventEffect.Type.GOLD, EventEffect.Type.PROVISIONS, EventEffect.Type.STRESS,
	EventEffect.Type.PARTY_HP, EventEffect.Type.MORALE, EventEffect.Type.BEDEL,
	EventEffect.Type.REPUTATION,
]

static func _echo_scale(session: GameSession, event: GameEvent, choice: EventChoice) -> float:
	if event == null or session.echo_count(event.event_id) < 1:
		return 1.0
	if session.echo_choice(event.event_id) == choice.text_key:
		return GameSession.ECHO_REPEAT_COST
	return GameSession.ECHO_OTHER_COST

static func _scaled(effects: Array[EventEffect], scale: float) -> Array[EventEffect]:
	if is_equal_approx(scale, 1.0):
		return effects
	var out: Array[EventEffect] = []
	for effect in effects:
		if not SCALABLE_EFFECTS.has(effect.type) or effect.amount == 0:
			out.append(effect)
			continue
		var amount := int(round(float(effect.amount) * scale))
		# Yuvarlama bir bedeli sıfıra indirmesin: bedel küçülür, kaybolmaz.
		if amount == 0:
			amount = 1 if effect.amount > 0 else -1
		out.append(EventEffect.make(effect.type, amount, effect.text_value))
	return out

static func _apply(
	effects: Array[EventEffect], session: GameSession, apply_effects: Callable
) -> EventEffectApplier.Result:
	if apply_effects.is_valid():
		return apply_effects.call(effects)
	return EventEffectApplier.apply(effects, session)
