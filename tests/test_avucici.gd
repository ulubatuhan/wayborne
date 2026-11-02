extends RefCounted

## Avuçiçi'nde inançsız (lore defter III, Ç14): kapı, aracı komisyonu, el kesme.

func suite_name() -> String:
	return "Avucici"

func run(t) -> void:
	_test_gate(t)
	_test_cut_hand(t)
	_test_stump_in_every_pose(t)

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

## T16-05: duruşta iki el aynı yere düşer; arka kolun eli kesik elin yerinde
## görünüyordu. Eller üst üste olan her karede arka kol da kesilir, ayrık
## olanda (yürüyüşün kol salınımı) yalnız ön kol.
func _test_stump_in_every_pose(t) -> void:
	var frames := BodyFrames.for_body("body_male_average")
	t.ok(frames != null, "beden kareleri yüklenmeli")
	if frames == null:
		return
	var h := 300.0
	var scale := Transform2D(0.0, Vector2(h / 330.0, h / 330.0), 0.0, Vector2.ZERO)
	var idle := {}
	var raw := frames.frame_joints("idle", 0)
	for name in raw:
		idle[name] = scale * Vector2(raw[name])
	t.ok(WalkFigure.stump_layers(idle, h).has("back_arm"), "duruşta arka kolun eli de kesilmeli")
	var apart := 0
	for frame in frames.frame_count("walk"):
		var joints := {}
		var r := frames.frame_joints("walk", frame)
		for name in r:
			joints[name] = scale * Vector2(r[name])
		var layers := WalkFigure.stump_layers(joints, h)
		t.ok(layers.has("front_arm"), "her karede ön kol kesilir")
		if not layers.has("back_arm"):
			apart += 1
	t.ok(apart > 0, "yürüyüşte eller ayrıldığında arka kol olduğu gibi kalmalı")
