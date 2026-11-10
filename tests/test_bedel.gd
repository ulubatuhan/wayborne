extends RefCounted

## Bedel taşıyıcısı (Ahlak alt sistemi, tasarım notu §D-A2).
##
## Sınanan şey formül değil **söz**: kart açılırken yazan ad ile bedeli
## ödeyen kişinin aynı olması, aynı durumun aynı kişiyi vermesi, yeminlinin
## teslim edilmemesi ve aynı kişinin art arda ödememesi.

func suite_name() -> String:
	return "Bedel"

func run(t) -> void:
	_test_same_state_same_bearer(t)
	_test_preview_matches_apply(t)
	_test_sworn_is_not_handed_over(t)
	_test_recent_payer_steps_back(t)
	_test_grieved_rule_picks_the_grieved(t)
	_test_lone_leader_pays_it_himself(t)
	_test_bedel_never_kills(t)

func _session(extra: int = 2) -> GameSession:
	var session := GameSession.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	session.start_playthrough(
		CharacterData.create("Lider", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	for i in extra:
		session.add_to_party(CharacterData.create(
			"Yoldaş %d" % (i + 1), CultureCatalog.VALLEY, CharacterStats.new()))
	return session

func _fx(amount: int, text: String) -> EventEffect:
	return EventEffect.make(EventEffect.Type.BEDEL, amount, text)

func _test_same_state_same_bearer(t) -> void:
	var session := _session()
	var first: CharacterData = BedelSecici.pick(BedelSecici.RULE_WEAKEST, session)
	var second: CharacterData = BedelSecici.pick(BedelSecici.RULE_WEAKEST, session)
	t.ok(first != null, "bedel taşıyıcısı bulundu")
	t.eq(first.character_id, second.character_id, "aynı durum aynı kişiyi veriyor")
	t.not_ok(first.is_player, "bedel lidere düşmüyor (havuzda yoldaş varken)")

func _test_preview_matches_apply(t) -> void:
	var session := _session()
	var choice := EventChoice.new()
	choice.effects = [_fx(-8, "PARTY_HP|en_zayif")]
	var previewed: CharacterData = EventEffectApplier.get_choice_target(choice, session)
	t.ok(previewed != null, "önizleme bir ad veriyor")
	var before: int = previewed.current_hp
	EventEffectApplier.apply(choice.effects, session)
	t.eq(previewed.current_hp, before - 8, "bedeli önizlemede yazan kişi ödedi")
	t.eq(session.last_bearer_name, previewed.character_name, "{bedel} aynı adı doldurur")

func _test_sworn_is_not_handed_over(t) -> void:
	var session := _session()
	var party := session.get_party()
	for member in party:
		if not member.is_player:
			member.sworn = true
	# Hepsi yeminliyse teslim edilecek kimse yok: bedel kervana döner.
	t.ok(BedelSecici.pick(BedelSecici.RULE_UNSWORN, session) == null,
		"yeminli yoldaş teslim edilmiyor")
	party[1].sworn = false
	var picked: CharacterData = BedelSecici.pick(BedelSecici.RULE_UNSWORN, session)
	t.ok(picked != null and not picked.sworn, "yemini olmayan seçiliyor")

func _test_recent_payer_steps_back(t) -> void:
	var session := _session()
	session.total_days_elapsed = 50
	var first: CharacterData = BedelSecici.pick(BedelSecici.RULE_GRIEVED, session)
	first.last_price_day = 48
	var second: CharacterData = BedelSecici.pick(BedelSecici.RULE_GRIEVED, session)
	t.ne(second.character_id, first.character_id, "yeni ödeyen art arda ödemiyor")
	first.last_price_day = 50 - BedelSecici.RECENT_PRICE_DAYS - 1
	var third: CharacterData = BedelSecici.pick(BedelSecici.RULE_GRIEVED, session)
	t.ok(third != null, "ceza süresi geçince havuz yine dolu")

func _test_grieved_rule_picks_the_grieved(t) -> void:
	var session := _session()
	var party := session.get_party()
	party[2].add_grievance(CharacterData.GRIEVANCE_UNFED, 3)
	var picked: CharacterData = BedelSecici.pick(BedelSecici.RULE_GRIEVED, session)
	t.eq(picked.character_id, party[2].character_id, "en kırgın olan öne çıkıyor")

func _test_lone_leader_pays_it_himself(t) -> void:
	var session := _session(0)
	# start_playthrough kadroyu iki kişiyle açıyor; yalnız lideri sınamak için
	# yoldaşları çıkarıyoruz (kopyayı gez: dismiss parti dizisini kısaltıyor).
	var others: Array[CharacterData] = []
	for member in session.get_party():
		if not member.is_player:
			others.append(member)
	for member in others:
		session.dismiss(member)
	t.ok(BedelSecici.pick(BedelSecici.RULE_WEAKEST, session) == null,
		"yalnız liderin havuzu boş")
	var leader := session.get_player_character()
	var before: int = leader.stress
	EventEffectApplier.apply([_fx(6, "STRESS|gecmisi_uyan")], session)
	t.eq(leader.stress, before + 6, "taşıyacak kimse yoksa bedel kervanbaşına biner")

func _test_bedel_never_kills(t) -> void:
	var session := _session()
	var victim: CharacterData = BedelSecici.pick(BedelSecici.RULE_WEAKEST, session)
	victim.current_hp = 4
	EventEffectApplier.apply([_fx(-999, "PARTY_HP|en_zayif")], session)
	t.eq(victim.current_hp, 1, "olaylar öldürmez: can 1'de kenetlenir")
	t.ok(session.get_party().has(victim), "kenetlenen kişi kervanda kalıyor")
