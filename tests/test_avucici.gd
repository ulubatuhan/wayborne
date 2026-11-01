extends RefCounted

## Avuçiçi'nde inançsız (lore defter III, Ç14): kapı, aracı komisyonu, el kesme.

func suite_name() -> String:
	return "Avucici"

func run(t) -> void:
	_test_gate(t)
	_test_cut_hand(t)

func _session(creed: String) -> GameSession:
	var session := GameSession.new(500, 0, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var leader := CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new())
	leader.creed = creed
	session.start_playthrough(leader, rng)
	session.current_location_id = "orvahel"
	return session

func _test_gate(t) -> void:
	var believer := _session(CharacterData.CREED_SEPTISM)
	var outsider := _session(CharacterData.CREED_FIST)
	t.ok(not believer.is_shut_out(), "Septisist kervan Orvahel'e girer")
	t.ok(outsider.is_shut_out(), "inançsız kervan kapıda kalır")
	t.ok(outsider.get_buy_price_multiplier() > believer.get_buy_price_multiplier(), "aracı komisyonu alışı pahalılaştırır")
	t.ok(outsider.capped_sell_price("test_grain", 100) < believer.capped_sell_price("test_grain", 100), "aracı komisyonu satışı ucuzlatır")
	outsider.current_location_id = "ondrelle"
	t.ok(not outsider.is_shut_out(), "kapı yalnızca Avuçiçi'nde")

func _test_cut_hand(t) -> void:
	var session := _session(CharacterData.CREED_FIST)
	var target := session.unbelieving_companion()
	t.ok(target != null, "inançsız bir yoldaş bulunur")
	var effect := EventEffect.make(EventEffect.Type.CUT_HAND, 1)
	var effects: Array[EventEffect] = [effect]
	EventEffectApplier.apply(effects, session)
	t.ok(target.missing_hand, "el kesilir")
	var restored := CharacterData.from_dict(target.to_dict())
	t.ok(restored.missing_hand, "kesik el kayıtta kalır")
	var unit := CombatUnit.from_character(target, 1)
	t.ok(not unit.get_skill_block_reason(SkillCatalog.get_skill(SkillCatalog.ARROW_SHOT)).is_empty(), "tek elle yay çekilmez")
	t.ne(unit.get_skill_block_reason(SkillCatalog.get_skill(SkillCatalog.SPEAR_THRUST)), TranslationServer.translate("CBT_BLOCK_ONE_HAND"), "tek elli iş kapanmaz")
